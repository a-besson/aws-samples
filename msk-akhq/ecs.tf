locals {
  image_name  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-3.amazonaws.com/kafka/akhq:latest"
  akhq_config = <<-EOT
    micronaut:
      security:
        enabled: true
    akhq:
      security:
        default-group: no-roles
        basic-auth:
          - username: admin
            password: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8" # echo -n "password" | sha256sum
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
    subnets          = module.vpc.private_subnets
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

  cpu                      = 1024
  memory                   = 2048
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
  tags              = local.tags
}
