# Retry and failure handling of this sample, in one place: when the file lands, EventBridge runs the task. If it cannot
# (RunTask is refused: capacity, throttling), it retries the delivery 3 times (1 hour at most), then sends the event to the
# DLQ. A task that starts and exits with an error is NOT retried by EventBridge: see the README, and step-function-s3 for a
# retry at the level of the job.
module "events" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "3.17.1"

  create_bus          = false
  bus_name            = "default"
  append_rule_postfix = false

  # The role of the target can only run this task definition on this cluster, and only pass the two roles of the task
  create_role              = true
  role_name                = "${local.name}-events"
  attach_policy_statements = true
  policy_statements = {
    run_task = {
      effect    = "Allow"
      actions   = ["ecs:RunTask"]
      resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.name}-job:*"]
      condition = [{
        test     = "ArnEquals"
        variable = "ecs:cluster"
        values   = [module.ecs_cluster.arn]
      }]
    }
    pass_task_roles = {
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [aws_iam_role.job_execution.arn, aws_iam_role.job_task.arn]
      condition = [{
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }]
    }
  }

  rules = {
    (local.name) = {
      description = "A file dropped under incoming/ runs the ECS task"
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = { name = [module.bucket.s3_bucket_id] }
          object = { key = [{ prefix = "incoming/" }] }
        }
      })
    }
  }

  targets = {
    (local.name) = [{
      name            = "run-${local.name}"
      arn             = module.ecs_cluster.arn
      attach_role_arn = true

      ecs_target = {
        launch_type         = "FARGATE"
        task_count          = 1
        task_definition_arn = aws_ecs_task_definition.job.arn
        network_configuration = {
          subnets          = local.states.vpc.subnets_private_ids
          security_groups  = [aws_security_group.job.id]
          assign_public_ip = false
        }
      }

      # The bucket and the key of the file go to the container as environment variables
      input_transformer = {
        input_paths    = { bucket = "$.detail.bucket.name", key = "$.detail.object.key" }
        input_template = "{\"containerOverrides\":[{\"name\":\"job\",\"environment\":[{\"name\":\"BUCKET\",\"value\":<bucket>},{\"name\":\"KEY\",\"value\":<key>}]}]}"
      }

      dead_letter_arn = module.dlq.queue_arn
      retry_policy = {
        maximum_retry_attempts       = 3
        maximum_event_age_in_seconds = 3600
      }
    }]
  }
}
