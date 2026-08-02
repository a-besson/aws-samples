#
# Simple ECS Cluster sample
#
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "7.5.0"

  name = "ecs-fargate-cluster"

  configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/ecs_cluster_log"
      }
    }
  }

  setting = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "7.5.0"

  name        = "ecs-fargate-service"
  cluster_arn = module.ecs_cluster.arn

  cpu    = 256
  memory = 512

  # Graviton (ARM64) Fargate tasks: ~20% cheaper per vCPU/GB-hour than X86_64 at equivalent
  # performance for this workload; public.ecr.aws/nginx/nginx publishes a multi-arch manifest
  # so no image change is required.
  runtime_platform = {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  enable_execute_command = true

  subnet_ids = local.states.vpc.subnets_private_ids
  security_group_ingress_rules = {
    nginx_port = {
      description = "Service port"
      cidr_ipv4   = local.states.vpc.vpc_cidr
      from_port   = local.container_port
      to_port     = local.container_port
      ip_protocol = "tcp"
    }
  }
  security_group_egress_rules = {
    all = {
      description = "Allow all outbound traffic"
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }

  tasks_iam_role_statements = [
    {
      sid    = "allowLog"
      effect = "Allow"
      actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  ]

  # Container definition(s)
  container_definitions = {
    (local.container_name) = {
      cpu                      = 256
      memory                   = 512
      essential                = true
      readonly_root_filesystem = false

      # Pinned to the current stable release (fixes CVE-2026-42945 and the HTTP/2 request
      # injection / buffer overflow issues addressed in 1.30.1-1.30.3); refresh during MCO
      # reviews against https://nginx.org/2026.html.
      image = "public.ecr.aws/nginx/nginx:1.30.3"
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
      cloudwatch_log_group_kms_key_id        = aws_kms_key.logs.arn

      log_configuration = {
        logDriver = "awslogs"
      }
    }
  }

  service_tags = local.tags
}
