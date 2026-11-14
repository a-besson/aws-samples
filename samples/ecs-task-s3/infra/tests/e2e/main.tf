# End-to-end checks of the sample, run by `terraform test` on Floci (see ../floci.tftest.hcl): it drops files, waits for
# the ECS tasks the rule starts, and reads back what the emulator stored. The aws CLI only goes through floci-aws.sh,
# which refuses any endpoint other than a local one.
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

  # arn:aws:ecs:<region>:<account>:cluster/<name>: the rule is named after the cluster
  rule_name = split("/", var.cluster_arn)[1]
}

# A file the job can read, and an empty one (the exit code of the job is the business failure)
resource "aws_s3_object" "ok" {
  bucket  = var.bucket_name
  key     = "incoming/ok.txt"
  content = "hello"
}

resource "aws_s3_object" "empty" {
  bucket  = var.bucket_name
  key     = "incoming/empty.txt"
  content = ""
}

# Both tasks ran and stopped (the rule starts them, nothing here does): the query is empty until the second one stopped
data "external" "stopped_tasks" {
  program = [
    local.floci_aws, var.floci_endpoint, "wait", "300", "ecs", "list-tasks", "--cluster", var.cluster_arn,
    "--desired-status", "STOPPED", "--query", "taskArns[1] && taskArns",
  ]
  depends_on = [aws_s3_object.ok, aws_s3_object.empty]
}

# Per task: who started it, the BUCKET and KEY the rule passed, and the exit code of the job (one line per task)
data "external" "tasks" {
  program = concat(
    [local.floci_aws, var.floci_endpoint, "run", "ecs", "describe-tasks", "--cluster", var.cluster_arn, "--tasks"],
    split("\t", data.external.stopped_tasks.result.output),
    ["--query", "tasks[].[startedBy,overrides.containerOverrides[0].environment[0].value,overrides.containerOverrides[0].environment[1].value,containers[0].exitCode]"],
  )
}

# Contract read back from the emulator: what was stored, not what was sent
data "external" "rule" {
  program = [local.floci_aws, var.floci_endpoint, "run", "events", "describe-rule", "--name", local.rule_name, "--query", "EventPattern"]
}

data "external" "target" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "events", "list-targets-by-rule", "--rule", local.rule_name,
    "--query", "Targets[0].[Arn,RetryPolicy.MaximumRetryAttempts,RetryPolicy.MaximumEventAgeInSeconds,DeadLetterConfig.Arn,EcsParameters.LaunchType,EcsParameters.TaskDefinitionArn,InputTransformer.InputTemplate]",
  ]
}

data "external" "dlq" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "sqs", "get-queue-attributes", "--queue-url", var.dlq_url,
    "--attribute-names", "MessageRetentionPeriod", "KmsMasterKeyId", "--query", "Attributes.[MessageRetentionPeriod,KmsMasterKeyId]",
  ]
}

data "external" "bucket" {
  program = [
    local.floci_aws, var.floci_endpoint, "run", "s3api", "get-bucket-encryption", "--bucket", var.bucket_name,
    "--query", "ServerSideEncryptionConfiguration.Rules[0].[ApplyServerSideEncryptionByDefault.SSEAlgorithm,ApplyServerSideEncryptionByDefault.KMSMasterKeyID,BucketKeyEnabled]",
  ]
}
