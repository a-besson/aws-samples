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
    # Scoped to the private repository this sample copies the AKHQ image into (see README);
    # further restricted to requests coming from this VPC below.
    resources = ["arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/kafka/akhq"]
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [local.states.vpc.vpc_id]
    }
  }
  statement {
    sid    = "EcrAuthToken"
    effect = "Allow"
    # ecr:GetAuthorizationToken has no resource-level permissions support - "*" is the only
    # valid value per https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonelasticcontainerregistry.html
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "TaskLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.ecs_log.arn}:*"]
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

# AKHQ's UI needs broad Kafka Admin API access (browse/manage topics, consumer groups, ACLs,
# configs) so action-level wildcards are kept here; for a production deployment, scope this
# down to the specific kafka-cluster:* actions AKHQ's read/admin modes actually call (see
# https://akhq.io/docs/configuration/authorizations.html). Resources are already scoped to
# this cluster and its topics/groups/transactional-ids only, never account-wide.
# kics-scan ignore-block
# trivy:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "ecs_task_msk_policy" {
  statement {
    sid    = "AkhqClusterAdmin"
    effect = "Allow"
    actions = [
      "kafka-cluster:*",
      "kafka:*",
    ]
    resources = [
      module.msk_cluster[0].arn,
      "${replace(module.msk_cluster[0].arn, ":cluster/", ":topic/")}/*",
      "${replace(module.msk_cluster[0].arn, ":cluster/", ":group/")}/*",
      "${replace(module.msk_cluster[0].arn, ":cluster/", ":transactional-id/")}/*",
    ]
  }
}
