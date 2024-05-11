resource "aws_iam_role" "task_execution_role" {
  name               = "${local.name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  inline_policy {
    name   = "EcsTaskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_policy.json
  }
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

# Normally we'd prefer not to hardcode an ARN in our Terraform, but since this is
# an AWS-managed policy, it's okay.
data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid    = "EcsTaskPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpce"
      values   = [module.vpc_endpoints.endpoints["ecr_dkr"].id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "task_role" {
  name = "${local.name}-task-role"

  inline_policy {
    name   = "EcsTaskMskExecutionPolicy"
    policy = data.aws_iam_policy_document.ecs_task_msk_policy.json
  }
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Attach the above policy to the execution role.
resource "aws_iam_role_policy_attachment" "ecs_task_role" {
  role       = aws_iam_role.task_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

data "aws_iam_policy_document" "ecs_task_msk_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kafka-cluster:*",
      "kafka:*",
    ]
    resources = ["*"]
  }
}

