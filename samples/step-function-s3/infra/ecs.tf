# The job: copies the file named by the BUCKET and KEY variables of the state machine and fails if it is empty
# (an empty file is the business failure of the tests: the exit code makes the state machine retry the task).
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.12.1"

  cluster_name = local.name

  # FinOps: no Container Insights metrics for a lab cluster
  cluster_settings = [{
    name  = "containerInsights"
    value = "disabled"
  }]

  # log group of the cluster, encrypted with the shared key of the base stack
  cloudwatch_log_group_retention_in_days = 1
  cloudwatch_log_group_kms_key_id        = local.states.vpc.kms_key_arn
}

resource "aws_cloudwatch_log_group" "job" {
  name              = "/aws/ecs/${local.name}-job"
  retention_in_days = 1
  kms_key_id        = local.states.vpc.kms_key_arn
}

resource "aws_ecs_task_definition" "job" {
  family                   = "${local.name}-job"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.job_execution.arn
  task_role_arn            = aws_iam_role.job_task.arn

  runtime_platform {
    cpu_architecture        = var.job_cpu_architecture
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name       = "job"
      image      = local.job_image
      essential  = true
      entryPoint = ["/bin/sh", "-c"]
      command    = ["aws s3 cp \"s3://$BUCKET/$KEY\" /tmp/input && test -s /tmp/input && echo \"processed $KEY ($(wc -c < /tmp/input) bytes)\""]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.job.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "job"
        }
      }
    }
  ])
}

# No ingress at all. The job only calls AWS APIs over HTTPS: the interface endpoints of the VPC (ECR, logs) and the S3
# gateway endpoint (the image layers and the objects).
resource "aws_security_group" "job" {
  name        = "${local.name}-job"
  description = "ECS job of the step-function-s3 sample: no ingress, HTTPS to the VPC endpoints and to S3 only"
  vpc_id      = local.states.vpc.vpc_id

  egress {
    description = "HTTPS to the interface endpoints of the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.states.vpc.vpc_cidr]
  }

  egress {
    description     = "HTTPS to S3 through the gateway endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }
}

resource "aws_iam_role" "job_execution" {
  name = "${local.name}-job-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "job_execution" {
  role       = aws_iam_role.job_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The first pull of an image through the cache imports it, and creates its repository if it does not exist yet
resource "aws_iam_role_policy" "job_execution_pull_through_cache" {
  name = "${local.name}-pull-through-cache"
  role = aws_iam_role.job_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecr:BatchImportUpstreamImage", "ecr:CreateRepository"]
      Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.states.vpc.ecr_public_pull_through_prefix}/*"
    }]
  })
}

resource "aws_iam_role" "job_task" {
  name = "${local.name}-job-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Condition = { StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id } }
    }]
  })
}

# The job reads the jobs/ objects, which are encrypted with the shared key (Floci does not enforce IAM: this follows the
# AWS documentation)
resource "aws_iam_role_policy" "job_task" {
  name = "${local.name}-read-jobs"
  role = aws_iam_role.job_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${module.bucket.s3_bucket_arn}/jobs/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = local.states.vpc.kms_key_arn
      }
    ]
  })
}
