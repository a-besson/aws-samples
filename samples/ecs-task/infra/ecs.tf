# ECS Task Definition only (Batch style)
resource "aws_ecs_task_definition" "batch" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "batch-job"
      # public.ecr.aws/amazonlinux/amazonlinux through the ECR Public pull through cache of the base stack
      image     = "${local.ecr_public_cache}/amazonlinux/amazonlinux:2023.12.20261102.0@sha256:381352c430f36d8aa6b8b670de06e7e4e5642fe0cb9dbd463bb8d1e79aefc0c7"
      essential = true
      command   = ["echo", "Hello from ECS Task!"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.batch.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "batch"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "batch" {
  name              = "/aws/ecs/${local.name}"
  retention_in_days = 1
  kms_key_id        = local.states.vpc.kms_key_arn
}

# IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The first pull of an image through the cache imports it, and creates its repository if it does not exist yet
resource "aws_iam_role_policy" "ecs_task_execution_pull_through_cache" {
  name = "${local.name}-pull-through-cache"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecr:BatchImportUpstreamImage", "ecr:CreateRepository"]
      Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.states.vpc.ecr_public_pull_through_prefix}/*"
    }]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}
