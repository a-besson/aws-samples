# Applies this stack on the Floci emulator with fake credentials (never on a real account), then runs the end-to-end
# checks of tests/e2e against it. Run with `task lambda-kinesis:test`; CI runs it in the `terraform-test` job of
# _build-sample.yml.
#
# Floci 2.4.0, probed before writing this file:
# - the Kinesis event source mapping is emulated: partial batch response, exponential backoff between the retries,
#   then the metadata of the batch goes to the failure destination (KinesisBatchInfo, no payload)
# - a fictitious KMS key ARN is accepted by Kinesis, DynamoDB, SQS and CloudWatch Logs
# - the function runs in a container started by Floci, which injects the endpoint and fake credentials
# - Floci gap: the mapping does not return ParallelizationFactor (reproduced with the aws CLI alone), so it is not asserted
# It checks the wiring and the behaviour of the code, not the IAM policies (Floci does not enforce them).

variables {
  floci_endpoint = "http://localhost:4566"
  state_bucket   = "floci-state"
}

# Overrides the provider of main.tf: every call goes to the emulator.
provider "aws" {
  region                      = "eu-west-3"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    kinesis        = var.floci_endpoint
    dynamodb       = var.floci_endpoint
    lambda         = var.floci_endpoint
    sqs            = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    cloudwatchlogs = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its output is replaced by a fixture.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      kms_key_arn = "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    }
  }
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = output.stream_name == "lab-lambda-kinesis" && output.function_name == "lab-lambda-kinesis-consumer" && output.table_name == "lab-lambda-kinesis-events"
    error_message = "The names of the stream, the function and the table did not match"
  }

  assert {
    condition     = module.dlq.queue_name == "lab-lambda-kinesis-dlq"
    error_message = "The DLQ name did not match"
  }

  assert {
    condition     = aws_kinesis_stream.events.stream_mode_details[0].stream_mode == "PROVISIONED" && aws_kinesis_stream.events.shard_count == 1 && aws_kinesis_stream.events.retention_period == 24
    error_message = "The stream must be provisioned with one shard and keep records 24 hours"
  }

  assert {
    condition     = aws_kinesis_stream.events.encryption_type == "KMS" && aws_kinesis_stream.events.kms_key_id == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The stream must be encrypted with the shared key of the base stack"
  }

  assert {
    condition     = module.consumer.lambda_cloudwatch_log_group_name == "/aws/lambda/lab-lambda-kinesis-consumer"
    error_message = "The function must log in its own log group"
  }
}

run "e2e" {
  command = apply

  module {
    source = "./tests/e2e"
  }

  variables {
    floci_endpoint = var.floci_endpoint
    stream_name    = run.apply_on_floci.stream_name
    function_name  = run.apply_on_floci.function_name
    table_name     = run.apply_on_floci.table_name
    dlq_url        = run.apply_on_floci.dlq_url
  }

  # Contract, read back from the emulator
  assert {
    condition     = output.function[0] == "python3.13" && output.function[1] == "arm64"
    error_message = "The function must run on python3.13 and arm64"
  }

  assert {
    condition     = output.mapping[0] == "TRIM_HORIZON" && output.mapping[1] == "10" && output.mapping[2] == "1"
    error_message = "The mapping must read from TRIM_HORIZON, 10 records at a time, within 1 second"
  }

  assert {
    condition     = output.mapping[3] == "2" && output.mapping[4] == "3600" && lower(output.mapping[5]) == "true" && output.mapping[6] == "ReportBatchItemFailures"
    error_message = "The mapping must retry twice within one hour, split the failing batches and accept partial batch responses"
  }

  assert {
    condition     = endswith(output.mapping[7], ":lab-lambda-kinesis-dlq")
    error_message = "The batches that exhausted their retries must go to the DLQ"
  }

  assert {
    condition     = output.stream[0] == "PROVISIONED" && output.stream[1] == "1" && output.stream[2] == "24" && output.stream[3] == "KMS"
    error_message = "The stream must be provisioned with one shard, keep records 24 hours and be encrypted with KMS"
  }

  assert {
    condition     = output.table[0] == "pk" && output.table[2] == "KMS" && output.table[3] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The table must have the partition key pk and be encrypted with the shared key"
  }

  assert {
    condition     = output.dlq[0] == "1209600" && output.dlq[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The DLQ must keep messages 14 days and be encrypted with the shared key"
  }

  # Nominal path
  assert {
    condition     = output.item[0] == "evt-ok" && jsondecode(output.item[1]).value == 42
    error_message = "The event evt-ok was not stored in the table"
  }

  # Failure path: the invalid record is retried (1 call + 2 retries), then the metadata of its batch goes to the DLQ
  assert {
    condition     = can(jsondecode(output.dead_letter).KinesisBatchInfo.shardId)
    error_message = "The DLQ must hold the metadata of the failed batch"
  }

  assert {
    condition     = endswith(jsondecode(output.dead_letter).KinesisBatchInfo.streamArn, ":stream/lab-lambda-kinesis")
    error_message = "The failure record must name the stream"
  }

  assert {
    condition     = jsondecode(output.dead_letter).requestContext.condition == "RetryAttemptsExhausted"
    error_message = "The failure must be reported as RetryAttemptsExhausted"
  }
}
