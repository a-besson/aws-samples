# End-to-end checks of the sample, run by `terraform test` on Floci (see ../floci.tftest.hcl): it drops files, waits for
# the state machine executions the rules start, and reads back what the emulator stored. The aws CLI only goes through
# floci-aws.sh, which refuses any endpoint other than a local one.
terraform {
  required_version = "1.17.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.4.2"
    }
  }
}

locals {
  floci_aws = "${path.module}/floci-aws.sh"

  # arn:aws:states:<region>:<account>:stateMachine:<name>: the rules are named after the state machines they start
  lambda_map_name = split(":", var.lambda_map_state_machine_arn)[6]
  ecs_job_name    = split(":", var.ecs_job_state_machine_arn)[6]
}

# (A) Distributed Map: two files under data/, then the manifests that list them (the manifest comes last)
resource "aws_s3_object" "data_a" {
  bucket       = var.bucket_name
  key          = "data/a.json"
  content      = jsonencode({ id = "a", items = [1, 2, 3] })
  content_type = "application/json"
}

resource "aws_s3_object" "data_b" {
  bucket       = var.bucket_name
  key          = "data/b.json"
  content      = jsonencode({ id = "b" })
  content_type = "application/json"
}

resource "aws_s3_object" "manifest_ok" {
  bucket       = var.bucket_name
  key          = "manifests/batch-ok.json"
  content      = jsonencode([{ key = aws_s3_object.data_a.key }, { key = aws_s3_object.data_b.key }])
  content_type = "application/json"
}

# lists a file that never comes: every attempt fails, the Map run fails
resource "aws_s3_object" "manifest_missing" {
  bucket       = var.bucket_name
  key          = "manifests/batch-missing.json"
  content      = jsonencode([{ key = "data/missing.json" }])
  content_type = "application/json"
}

# (B) ECS job: a file the job can read, and an empty one (the exit code of the job is the business failure)
resource "aws_s3_object" "job_ok" {
  bucket  = var.bucket_name
  key     = "jobs/ok.txt"
  content = "hello"
}

resource "aws_s3_object" "job_empty" {
  bucket  = var.bucket_name
  key     = "jobs/empty.txt"
  content = ""
}

# Executions started by the EventBridge rules (only their delivery is native: nothing here starts a state machine)
data "external" "lambda_map_ok" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "stepfunctions", "list-executions", "--state-machine-arn", var.lambda_map_state_machine_arn,
    "--status-filter", "SUCCEEDED", "--query", "executions[0].executionArn",
  ]
  depends_on = [aws_s3_object.manifest_ok]
}

data "external" "lambda_map_ok_output" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "describe-execution", "--execution-arn", data.external.lambda_map_ok.result.output,
    "--query", "output",
  ]
}

data "external" "lambda_map_failed" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "stepfunctions", "list-executions", "--state-machine-arn", var.lambda_map_state_machine_arn,
    "--status-filter", "FAILED", "--query", "executions[0].executionArn",
  ]
  depends_on = [aws_s3_object.manifest_missing]
}

data "external" "lambda_map_failed_error" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "describe-execution", "--execution-arn", data.external.lambda_map_failed.result.output,
    "--query", "error",
  ]
}

data "external" "ecs_job_ok" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "stepfunctions", "list-executions", "--state-machine-arn", var.ecs_job_state_machine_arn,
    "--status-filter", "SUCCEEDED", "--query", "executions[0].executionArn",
  ]
  depends_on = [aws_s3_object.job_ok]
}

data "external" "ecs_job_ok_output" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "describe-execution", "--execution-arn", data.external.ecs_job_ok.result.output,
    "--query", "output",
  ]
}

data "external" "ecs_job_failed" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "stepfunctions", "list-executions", "--state-machine-arn", var.ecs_job_state_machine_arn,
    "--status-filter", "FAILED", "--query", "executions[0].executionArn",
  ]
  depends_on = [aws_s3_object.job_empty]
}

# 1 attempt + 2 retries: the task was submitted 3 times
data "external" "ecs_job_failed_submissions" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "get-execution-history", "--execution-arn", data.external.ecs_job_failed.result.output,
    "--query", "length(events[?type=='TaskSubmitted'])",
  ]
}

# Contract read back from the emulator: what was stored, not what was sent
data "external" "lambda_map_definition" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "describe-state-machine", "--state-machine-arn", var.lambda_map_state_machine_arn,
    "--query", "definition",
  ]
}

data "external" "ecs_job_definition" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "stepfunctions", "describe-state-machine", "--state-machine-arn", var.ecs_job_state_machine_arn,
    "--query", "definition",
  ]
}

data "external" "lambda_map_rule" {
  program = [local.floci_aws, var.floci_endpoint, "run", "events", "describe-rule", "--name", local.lambda_map_name, "--query", "EventPattern"]
}

data "external" "ecs_job_rule" {
  program = [local.floci_aws, var.floci_endpoint, "run", "events", "describe-rule", "--name", local.ecs_job_name, "--query", "EventPattern"]
}

data "external" "lambda_map_target" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "events", "list-targets-by-rule", "--rule", local.lambda_map_name,
    "--query", "Targets[0].[Arn,RetryPolicy.MaximumRetryAttempts,RetryPolicy.MaximumEventAgeInSeconds,DeadLetterConfig.Arn]",
  ]
}

data "external" "ecs_job_target" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "events", "list-targets-by-rule", "--rule", local.ecs_job_name,
    "--query", "Targets[0].[Arn,RetryPolicy.MaximumRetryAttempts,RetryPolicy.MaximumEventAgeInSeconds,DeadLetterConfig.Arn]",
  ]
}

data "external" "dlq" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "sqs", "get-queue-attributes", "--queue-url", var.events_dlq_url,
    "--attribute-names", "MessageRetentionPeriod", "KmsMasterKeyId", "--query", "Attributes.[MessageRetentionPeriod,KmsMasterKeyId]",
  ]
}

data "external" "bucket" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "s3api", "get-bucket-encryption", "--bucket", var.bucket_name,
    "--query", "ServerSideEncryptionConfiguration.Rules[0].[ApplyServerSideEncryptionByDefault.SSEAlgorithm,ApplyServerSideEncryptionByDefault.KMSMasterKeyID,BucketKeyEnabled]",
  ]
}
