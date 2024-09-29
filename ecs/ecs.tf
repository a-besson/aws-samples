#
# Simple ECS Cluster sample
#
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.11.4"

  cluster_name = "ecs-fargate-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/ecs_cluster_log"
      }
    }
  }

  cluster_settings = {
    name  = "containerInsights",
    value = "enabled"
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name        = "ecs-fargate-service"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  enable_execute_command = true

  subnet_ids = local.states.vpc.subnets_private_ids
  security_group_rules = {
    ingress_nginx_port = {
      type        = "ingress"
      from_port   = local.container_port
      to_port     = local.container_port
      protocol    = "tcp"
      description = "Service port"
      cidr_blocks = [local.states.vpc.vpc_cidr]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tasks_iam_role_statements = {
    allowLog = {
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      cpu                      = 256
      memory                   = 512
      essential                = true
      readonly_root_filesystem = false

      image = "public.ecr.aws/nginx/nginx:latest"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      health_check = {
        command = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/health || exit 1"]
      }

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/${local.name}/${local.container_name}"
      cloudwatch_log_group_retention_in_days = 1

      log_configuration = {
        logDriver = "awslogs"
      }
    }
  }

  service_tags = local.tags
}
