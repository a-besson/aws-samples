# Applies this stack on the Floci emulator with fake credentials (never on a real account), then runs the end-to-end
# checks of tests/e2e against it. Run with `task lambda-s3:test`; CI runs it in the `terraform-test` job of
# _build-sample.yml.
#
# Floci 2.4.0, probed before writing this file:
# - S3 notification to Lambda, asynchronous retries with the failure destination and the DLQ are emulated; the retries run
#   back to back (FLOCI_SERVICES_LAMBDA_ASYNC_RETRY_DELAY_SECONDS=0 in tf-floci-test), AWS waits 1 then 2 minutes
# - a fictitious KMS key ARN is accepted by S3, SQS and CloudWatch Logs
# - the function runs in a container started by Floci, which injects the endpoint and fake credentials
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
    s3             = var.floci_endpoint
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
    condition     = output.bucket_name == "lab-lambda-s3-000000000000"
    error_message = "The bucket must be named after the sample and the account"
  }

  assert {
    condition     = output.function_name == "lab-lambda-s3-reader"
    error_message = "The function name did not match"
  }

  assert {
    condition     = module.dlq.queue_name == "lab-lambda-s3-dlq"
    error_message = "The DLQ name did not match"
  }

  assert {
    condition     = module.reader.lambda_cloudwatch_log_group_name == "/aws/lambda/lab-lambda-s3-reader"
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
    bucket_name    = run.apply_on_floci.bucket_name
    function_name  = run.apply_on_floci.function_name
    dlq_url        = run.apply_on_floci.dlq_url
  }

  # Contract, read back from the emulator
  assert {
    condition     = output.function[0] == "python3.13" && output.function[1] == "arm64"
    error_message = "The function must run on python3.13 and arm64"
  }

  assert {
    condition     = output.async_config[0] == "2" && output.async_config[1] == "3600"
    error_message = "The asynchronous invocations must retry twice, within one hour"
  }

  assert {
    condition     = endswith(output.async_config[2], ":lab-lambda-s3-dlq")
    error_message = "The failed invocations must go to the DLQ"
  }

  assert {
    condition     = output.notification[0] == "s3:ObjectCreated:*" && contains(output.notification, "incoming/") && contains(output.notification, ".json")
    error_message = "The notification must filter the .json objects created under incoming/"
  }

  assert {
    condition     = output.bucket[0] == "aws:kms" && output.bucket[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000" && lower(output.bucket[2]) == "true"
    error_message = "The bucket must be encrypted with the shared key, with a bucket key"
  }

  assert {
    condition     = output.dlq[0] == "1209600" && output.dlq[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The DLQ must keep messages 14 days and be encrypted with the shared key"
  }

  # Nominal path
  assert {
    condition     = jsondecode(output.summary).source_key == "incoming/ok.json"
    error_message = "The summary of ok.json was not written under processed/"
  }

  assert {
    condition     = jsondecode(output.summary).top_level_type == "object" && jsondecode(output.summary).item_count == 2
    error_message = "The summary of ok.json did not describe the document"
  }

  # Failure path: the record of the exhausted invocation (1 call + 2 retries)
  assert {
    condition     = jsondecode(output.dead_letter).requestPayload.Records[0].s3.object.key == "incoming/poison.json"
    error_message = "The DLQ must hold the event of poison.json"
  }

  assert {
    condition     = jsondecode(output.dead_letter).requestContext.condition == "RetriesExhausted"
    error_message = "The failure must be reported as RetriesExhausted"
  }

  assert {
    condition     = jsondecode(output.dead_letter).requestContext.approximateInvokeCount == 3
    error_message = "The function must have been invoked 3 times (1 call + 2 retries)"
  }
}
