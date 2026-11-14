# End-to-end checks of the sample, run by `terraform test` on Floci (see ../floci.tftest.hcl): it drops files, waits for
# the results and reads back what the emulator stored. The aws CLI only goes through floci-aws.sh, which refuses any
# endpoint other than a local one.
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
}

# Inputs: one file the function can summarize, one it cannot (it must end in the DLQ)
resource "aws_s3_object" "ok" {
  bucket       = var.bucket_name
  key          = "incoming/ok.json"
  content      = jsonencode({ id = "ok", items = [1, 2, 3] })
  content_type = "application/json"
}

resource "aws_s3_object" "poison" {
  bucket       = var.bucket_name
  key          = "incoming/poison.json"
  content      = "not-json"
  content_type = "application/json"
}

# Nominal path: the summary of ok.json shows up under processed/
data "external" "summary" {
  program    = [local.floci_aws, var.floci_endpoint, "wait", "180", "s3", "cp", "s3://${var.bucket_name}/processed/ok.json", "-"]
  depends_on = [aws_s3_object.ok]
}

# Failure path: poison.json fails every attempt, the failure record lands in the DLQ (the message stays in the queue)
data "external" "dead_letter" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "sqs", "receive-message", "--queue-url", var.dlq_url,
    "--visibility-timeout", "0", "--wait-time-seconds", "5", "--query", "Messages[0].Body",
  ]
  depends_on = [aws_s3_object.poison]
}

# Contract read back from the emulator: what was stored, not what was sent
data "external" "function" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "lambda", "get-function-configuration", "--function-name", var.function_name,
    "--query", "[Runtime,Architectures[0],MemorySize,Timeout]",
  ]
}

data "external" "async_config" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "lambda", "get-function-event-invoke-config", "--function-name", var.function_name,
    "--query", "[MaximumRetryAttempts,MaximumEventAgeInSeconds,DestinationConfig.OnFailure.Destination]",
  ]
}

data "external" "notification" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "s3api", "get-bucket-notification-configuration", "--bucket", var.bucket_name,
    "--query", "LambdaFunctionConfigurations[0].[Events[0],Filter.Key.FilterRules[0].Value,Filter.Key.FilterRules[1].Value]",
  ]
}

data "external" "bucket" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "s3api", "get-bucket-encryption", "--bucket", var.bucket_name,
    "--query", "ServerSideEncryptionConfiguration.Rules[0].[ApplyServerSideEncryptionByDefault.SSEAlgorithm,ApplyServerSideEncryptionByDefault.KMSMasterKeyID,BucketKeyEnabled]",
  ]
}

data "external" "dlq" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "sqs", "get-queue-attributes", "--queue-url", var.dlq_url,
    "--attribute-names", "MessageRetentionPeriod", "KmsMasterKeyId", "--query", "Attributes.[MessageRetentionPeriod,KmsMasterKeyId]",
  ]
}
