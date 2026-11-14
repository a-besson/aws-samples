# End-to-end checks of the sample, run by `terraform test` on Floci (see ../floci.tftest.hcl): it puts records in the
# stream, waits for the results and reads back what the emulator stored. The aws CLI only goes through floci-aws.sh,
# which refuses any endpoint other than a local one.
terraform {
  required_version = "1.17.2"
  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "2.4.2"
    }
  }
}

locals {
  floci_aws = "${path.module}/floci-aws.sh"
}

# Inputs: a valid event, then one the function cannot store (it must end in the DLQ). A stream is not a Terraform
# resource: the records are put once, when the resource is created.
resource "terraform_data" "record_ok" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "\"$FLOCI_AWS\" \"$ENDPOINT\" run kinesis put-record --stream-name \"$STREAM\" --partition-key e2e --cli-binary-format raw-in-base64-out --data \"$DATA\" --query SequenceNumber"
    environment = {
      FLOCI_AWS = local.floci_aws
      ENDPOINT  = var.floci_endpoint
      STREAM    = var.stream_name
      DATA      = jsonencode({ id = "evt-ok", value = 42 })
    }
  }
}

resource "terraform_data" "record_poison" {
  depends_on = [terraform_data.record_ok]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "\"$FLOCI_AWS\" \"$ENDPOINT\" run kinesis put-record --stream-name \"$STREAM\" --partition-key e2e --cli-binary-format raw-in-base64-out --data \"$DATA\" --query SequenceNumber"
    environment = {
      FLOCI_AWS = local.floci_aws
      ENDPOINT  = var.floci_endpoint
      STREAM    = var.stream_name
      DATA      = "not-json"
    }
  }
}

# Nominal path: the event shows up in the table
data "external" "item" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "180", "dynamodb", "get-item", "--table-name", var.table_name,
    "--key", jsonencode({ pk = { S = "evt-ok" } }), "--query", "Item.[pk.S,payload.S]",
  ]
  depends_on = [terraform_data.record_ok]
}

# Failure path: the invalid record fails every attempt, the metadata of its batch lands in the DLQ (the message stays)
data "external" "dead_letter" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "sqs", "receive-message", "--queue-url", var.dlq_url,
    "--visibility-timeout", "0", "--wait-time-seconds", "5", "--query", "Messages[0].Body",
  ]
  depends_on = [terraform_data.record_poison]
}

# Contract read back from the emulator: what was stored, not what was sent
data "external" "function" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "lambda", "get-function-configuration", "--function-name", var.function_name,
    "--query", "[Runtime,Architectures[0],MemorySize,Timeout]",
  ]
}

# Floci gap (2.4.0): the mapping does not return ParallelizationFactor, reproduced with the aws CLI alone (the value, 1, is set
# in ../../lambda.tf)
data "external" "mapping" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "lambda", "list-event-source-mappings", "--function-name", var.function_name,
    "--query", "EventSourceMappings[0].[StartingPosition,BatchSize,MaximumBatchingWindowInSeconds,MaximumRetryAttempts,MaximumRecordAgeInSeconds,BisectBatchOnFunctionError,FunctionResponseTypes[0],DestinationConfig.OnFailure.Destination]",
  ]
}

data "external" "stream" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "kinesis", "describe-stream-summary", "--stream-name", var.stream_name,
    "--query", "StreamDescriptionSummary.[StreamModeDetails.StreamMode,OpenShardCount,RetentionPeriodHours,EncryptionType,KeyId]",
  ]
}

data "external" "table" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "dynamodb", "describe-table", "--table-name", var.table_name,
    "--query", "Table.[KeySchema[0].AttributeName,BillingModeSummary.BillingMode,SSEDescription.SSEType,SSEDescription.KMSMasterKeyArn]",
  ]
}

data "external" "dlq" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "sqs", "get-queue-attributes", "--queue-url", var.dlq_url,
    "--attribute-names", "MessageRetentionPeriod", "KmsMasterKeyId", "--query", "Attributes.[MessageRetentionPeriod,KmsMasterKeyId]",
  ]
}
