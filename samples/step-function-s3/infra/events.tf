# Both rules sit on the default bus. Each target retries the delivery 3 times (1 hour at most), then the event goes to the DLQ.
# Only the delivery is retried here: what the state machines do with the event is retried by the state machines.
module "events" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "3.17.1"

  create_bus          = false
  bus_name            = "default"
  append_rule_postfix = false

  # The role of the targets can only start the two state machines
  create_role       = true
  role_name         = "${local.name}-events"
  attach_sfn_policy = true
  sfn_target_arns   = [module.lambda_map.state_machine_arn, module.ecs_job.state_machine_arn]

  rules = {
    (local.lambda_map_name) = {
      description = "A manifest dropped under manifests/ starts the Distributed Map"
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = { name = [module.bucket.s3_bucket_id] }
          object = { key = [{ prefix = "manifests/" }] }
        }
      })
    }
    (local.ecs_job_name) = {
      description = "A file dropped under jobs/ starts the ECS job"
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          bucket = { name = [module.bucket.s3_bucket_id] }
          object = { key = [{ prefix = "jobs/" }] }
        }
      })
    }
  }

  targets = {
    (local.lambda_map_name) = [{
      name            = "start-${local.lambda_map_name}"
      arn             = module.lambda_map.state_machine_arn
      attach_role_arn = true
      dead_letter_arn = module.events_dlq.queue_arn
      retry_policy = {
        maximum_retry_attempts       = 3
        maximum_event_age_in_seconds = 3600
      }
    }]
    (local.ecs_job_name) = [{
      name            = "start-${local.ecs_job_name}"
      arn             = module.ecs_job.state_machine_arn
      attach_role_arn = true
      dead_letter_arn = module.events_dlq.queue_arn
      retry_policy = {
        maximum_retry_attempts       = 3
        maximum_event_age_in_seconds = 3600
      }
    }]
  }
}
