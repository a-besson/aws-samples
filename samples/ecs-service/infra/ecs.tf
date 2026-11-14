#
# Simple ECS Cluster sample
#
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.12.1"

  cluster_name = "ecs-fargate-cluster"

  # log group of the cluster, encrypted with the shared key of the base stack
  cloudwatch_log_group_kms_key_id = local.states.vpc.kms_key_arn

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

# The task pulls its image and reaches AWS APIs through the VPC: egress is left open, ingress is what is restricted.
#trivy:ignore:AWS-0104:exp:2027-01-31
module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.12.1"

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
      description = "Allow all outbound traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # The first pull of an image through the cache imports it, and creates its repository if it does not exist yet
  task_exec_iam_statements = {
    pullThroughCache = {
      actions   = ["ecr:BatchImportUpstreamImage", "ecr:CreateRepository"]
      resources = ["arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.states.vpc.ecr_public_pull_through_prefix}/*"]
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

      # public.ecr.aws/nginx/nginx through the ECR Public pull through cache of the base stack (no NAT gateway)
      image = "${local.ecr_public_cache}/nginx/nginx:1.30.6@sha256:2e92d5fff8ca7a6a1d64aa6853d96ef739acec5bbb5f3731200163865ceb3679"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      health_check = {
        command = ["CMD-SHELL", "curl -f http://localhost:${local.container_port}/ || exit 1"]
      }

      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/${local.name}/${local.container_name}"
      cloudwatch_log_group_retention_in_days = 1
      cloudwatch_log_group_kms_key_id        = local.states.vpc.kms_key_arn

      log_configuration = {
        logDriver = "awslogs"
      }
    }
  }

  service_tags = local.tags
}
