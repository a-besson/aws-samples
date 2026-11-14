# The code is packaged from ../app/lambdas/s3_reader (tests excluded). boto3 comes with the runtime.
# No VPC: the function only calls S3 and SQS, nothing private is joined.
# python3.13 is the newest runtime the pinned aws provider (5.100.0) accepts: python3.14 is rejected by its validation.
module "reader" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${local.name}-reader"
  description   = "Summarizes the JSON objects dropped under incoming/ into processed/"
  handler       = "s3_reader.handler"
  runtime       = "python3.13"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 30

  source_path = [{
    path     = "${path.module}/../app/lambdas/s3_reader"
    patterns = ["!tests/.*", "!__pycache__/.*"]
  }]

  logging_log_format                = "JSON"
  cloudwatch_logs_retention_in_days = 1
  cloudwatch_logs_kms_key_id        = local.states.vpc.kms_key_arn

  # S3 invokes the function asynchronously: 2 retries (the maximum), then the failure record goes to the DLQ
  create_async_event_config                 = true
  create_current_version_async_event_config = false # not published: one configuration, on the unqualified function
  maximum_retry_attempts                    = 2
  maximum_event_age_in_seconds              = 3600
  destination_on_failure                    = module.dlq.queue_arn

  attach_policy_statements = true
  policy_statements = {
    read_input = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.bucket.s3_bucket_arn}/incoming/*"]
    }
    write_output = {
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${module.bucket.s3_bucket_arn}/processed/*"]
    }
    dead_letter = {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [module.dlq.queue_arn]
    }
    # Objects, summaries and queue messages are encrypted with the shared key: reading needs Decrypt, writing needs
    # GenerateDataKey (Floci does not enforce IAM: this is checked by the AWS documentation only)
    shared_key = {
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [local.states.vpc.kms_key_arn]
    }
  }
}
