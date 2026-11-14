# The code is packaged from ../app/lambdas/kinesis_consumer (tests excluded). boto3 comes with the runtime.
# No VPC: the function only calls DynamoDB, SQS and the stream, nothing private is joined.
# python3.13 is the newest runtime the pinned aws provider (5.100.0) accepts: python3.14 is rejected by its validation.
module "consumer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${local.name}-consumer"
  description   = "Stores the events of the stream once in DynamoDB and reports the invalid records"
  handler       = "kinesis_consumer.handler"
  runtime       = "python3.13"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 30

  source_path = [{
    path     = "${path.module}/../app/lambdas/kinesis_consumer"
    patterns = ["!tests/.*", "!__pycache__/.*"]
  }]

  environment_variables = {
    TABLE_NAME = module.events_table.dynamodb_table_id
  }

  logging_log_format                = "JSON"
  cloudwatch_logs_retention_in_days = 1
  cloudwatch_logs_kms_key_id        = local.states.vpc.kms_key_arn

  # TRIM_HORIZON: the records written before the poller starts are not lost. A failed record is reported by the function
  # (partial batch response); the batch is split to isolate it, retried twice, then its metadata goes to the DLQ.
  event_source_mapping = {
    events = {
      event_source_arn                   = aws_kinesis_stream.events.arn
      starting_position                  = "TRIM_HORIZON"
      batch_size                         = 10
      maximum_batching_window_in_seconds = 1
      parallelization_factor             = 1
      function_response_types            = ["ReportBatchItemFailures"]
      maximum_retry_attempts             = 2
      maximum_record_age_in_seconds      = 3600
      bisect_batch_on_function_error     = true
      destination_arn_on_failure         = module.dlq.queue_arn
    }
  }

  attach_policy_statements = true
  policy_statements = {
    read_stream = {
      effect    = "Allow"
      actions   = ["kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:ListShards"]
      resources = [aws_kinesis_stream.events.arn]
    }
    write_events = {
      effect    = "Allow"
      actions   = ["dynamodb:PutItem"]
      resources = [module.events_table.dynamodb_table_arn]
    }
    dead_letter = {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [module.dlq.queue_arn]
    }
    # The stream, the table and the queue are encrypted with the shared key: Decrypt to read the stream, GenerateDataKey
    # to write the queue and the table, DescribeKey for DynamoDB (Floci does not enforce IAM: this follows the AWS
    # documentation of Kinesis, SQS and DynamoDB, and is checked by the smoke test on a real account only)
    shared_key = {
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
      resources = [local.states.vpc.kms_key_arn]
    }
  }
}
