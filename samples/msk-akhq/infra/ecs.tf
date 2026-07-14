resource "random_password" "akhq_admin" {
  length  = 24
  special = false
}

locals {
  image_name = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/kafka/akhq:latest"

  akhq_config = <<-EOT
    micronaut:
      security:
        enabled: true
    akhq:
      security:
        default-group: no-roles
        basic-auth:
          - username: admin
            password: "${sha256(random_password.akhq_admin.result)}"
            groups:
              - admin
      connections:
        msk-cluster:
          properties:
            bootstrap.servers: ${module.msk_cluster[0].bootstrap_brokers_sasl_iam}
            security.protocol: SASL_SSL
            sasl.mechanism: AWS_MSK_IAM
            sasl.jaas.config: software.amazon.msk.auth.iam.IAMLoginModule required awsDebugCreds=true;
            sasl.client.callback.handler.class: software.amazon.msk.auth.iam.IAMClientCallbackHandler
    EOT
}

# Container Insights disabled to minimize CloudWatch cost on this lab cluster; set
# `cluster_settings` (containerInsights = enabled) for production use.
# kics-scan ignore-block
resource "aws_ecs_cluster" "app" {
  name = "app-ecs-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${local.name}-ecs-service"
  task_definition = aws_ecs_task_definition.ecs_task_app.arn
  cluster         = aws_ecs_cluster.app.id

  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = local.states.vpc.subnets_private_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "${local.name}-container"
    container_port   = local.app_port
  }
}

resource "aws_ecs_task_definition" "ecs_task_app" {
  family             = "${local.name}-container"
  execution_role_arn = aws_iam_role.task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  container_definitions = jsonencode([
    {
      name  = "${local.name}-container",
      image = local.image_name,
      portMappings = [
        {
          containerPort = local.app_port,
          hostPort      = local.app_port,
        }
      ],
      environment = [
        { name = "AKHQ_CONFIGURATION", value = local.akhq_config },
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_log.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = local.tags
}

resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.ecs_auto_scale_role.arn
  min_capacity       = 1
  max_capacity       = 3
  tags               = local.tags
}

data "aws_iam_policy_document" "ecs_auto_scale_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

# ECS auto scale role
resource "aws_iam_role" "ecs_auto_scale_role" {
  name               = "${local.name}-ecs-auto-scale-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_auto_scale_role.json
  tags               = local.tags
}

# ECS auto scale role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  role       = aws_iam_role.ecs_auto_scale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

# Automatically scale capacity up by one
resource "aws_appautoscaling_policy" "up" {
  name               = "cb_scale_up"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
  depends_on = [aws_appautoscaling_target.target]
}

# Automatically scale capacity down by one
resource "aws_appautoscaling_policy" "down" {
  name               = "cb_scale_down"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_cloudwatch_log_group" "ecs_log" {
  name              = "/ecs/${local.name}-container-log"
  retention_in_days = 1
  kms_key_id        = aws_kms_key.logs.arn

  tags = local.tags
}

# Root-account administrator statement is the AWS-documented baseline for every KMS key
# policy (a key with no root grant can permanently lock the account out of its own key);
# kms:* is scoped to this account's root principal only, not a public/anonymous wildcard.
# kics-scan ignore-block
resource "aws_kms_key" "logs" {
  description         = "CMK for CloudWatch Logs encryption - ${local.name}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logs_kms.json
  tags                = local.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${local.name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

data "aws_iam_policy_document" "logs_kms" {
  statement {
    sid       = "AllowRootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
