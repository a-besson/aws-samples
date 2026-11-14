# Applies this stack on the Floci emulator with fake credentials (never on a real account), then runs the end-to-end
# checks of tests/e2e against it. Run with `task step-function-s3:test`; CI runs it in the `terraform-test` job of
# _build-sample.yml.
#
# Floci 2.4.0, probed before writing this file:
# - S3 events reach EventBridge natively, and the rules start the state machines and the ECS tasks natively
# - Step Functions: Distributed Map (ItemReader s3:getObject, JSON), ecs:runTask.sync, Retry and the execution history
# - the Lambda function and the ECS task run in containers started by Floci, which injects the endpoint and fake
#   credentials. A task for the cpuArchitecture it names: ARM64 would need emulation on an amd64 runner, so the test
#   asks for X86_64 (the stack defaults to ARM64, the cheapest on Fargate)
# - the Retry delays and the Wait states are capped at 30 s (the executions stay short), a Task without TimeoutSeconds
#   waits 300 s (the ECS job sets TimeoutSeconds)
# - the DLQ path of the rules is not reproducible here: it needs a delivery that fails
# It checks the wiring and the behaviour of the code and of the state machines, not the IAM policies (Floci does not
# enforce them).

variables {
  floci_endpoint = "http://localhost:4566"
  state_bucket   = "floci-state"
  # the pull through cache of the base stack does not exist in the emulator: the public image, same tag and digest
  job_image            = "public.ecr.aws/aws-cli/aws-cli:2.39.6@sha256:eccdb3ec77e159d43ca6a750a70738c546883138be7f094498294a1477ec7e42"
  job_cpu_architecture = "X86_64"
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
    sfn            = var.floci_endpoint
    events         = var.floci_endpoint
    ecs            = var.floci_endpoint
    ec2            = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its outputs are replaced by the default network of the emulator.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id                         = "vpc-default-eu-west-3"
      vpc_cidr                       = "172.31.0.0/16"
      subnets_private_ids            = ["subnet-default-eu-west-3-a", "subnet-default-eu-west-3-b"]
      kms_key_arn                    = "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
      ecr_public_pull_through_prefix = "ecr-public"
    }
  }
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = output.bucket_name == "lab-step-function-s3-000000000000"
    error_message = "The bucket must be named after the sample and the account"
  }

  assert {
    condition     = endswith(output.lambda_map_state_machine_arn, ":stateMachine:lab-step-function-s3-lambda-map") && endswith(output.ecs_job_state_machine_arn, ":stateMachine:lab-step-function-s3-ecs-job")
    error_message = "The state machines did not have the expected names"
  }

  assert {
    condition     = endswith(output.cluster_arn, ":cluster/lab-step-function-s3")
    error_message = "The cluster name did not match"
  }

  assert {
    condition     = aws_ecs_task_definition.job.family == "lab-step-function-s3-job" && aws_ecs_task_definition.job.cpu == "256" && aws_ecs_task_definition.job.memory == "512"
    error_message = "The job task definition did not match"
  }

  assert {
    condition     = aws_cloudwatch_log_group.job.retention_in_days == 1 && aws_cloudwatch_log_group.job.kms_key_id == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The job log group must keep logs one day and be encrypted with the shared key"
  }

  assert {
    condition     = length(aws_security_group.job.ingress) == 0
    error_message = "The job security group must not allow any ingress"
  }
}

run "e2e" {
  command = apply

  module {
    source = "./tests/e2e"
  }

  variables {
    floci_endpoint               = var.floci_endpoint
    bucket_name                  = run.apply_on_floci.bucket_name
    lambda_map_state_machine_arn = run.apply_on_floci.lambda_map_state_machine_arn
    ecs_job_state_machine_arn    = run.apply_on_floci.ecs_job_state_machine_arn
    events_dlq_url               = run.apply_on_floci.events_dlq_url
  }

  # Contract, read back from the emulator: the Distributed Map
  assert {
    condition     = jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.ProcessorConfig.Mode == "DISTRIBUTED" && jsondecode(output.lambda_map_definition).States.ReadFiles.MaxConcurrency == 10
    error_message = "The Map state must be distributed, with a concurrency of 10"
  }

  assert {
    condition     = jsondecode(output.lambda_map_definition).States.ReadFiles.ToleratedFailurePercentage == 0
    error_message = "The Map state must not tolerate any failed file"
  }

  assert {
    condition = (
      jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.States.ReadFile.Retry[1].ErrorEquals[0] == "ObjectNotReadyError" &&
      jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.States.ReadFile.Retry[1].MaxAttempts == 3 &&
      jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.States.ReadFile.Retry[1].IntervalSeconds == 2
    )
    error_message = "A file that is not there yet must be retried 3 times, from 2 seconds"
  }

  assert {
    condition = (
      contains(jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.States.ReadFile.Retry[0].ErrorEquals, "Lambda.TooManyRequestsException") &&
      jsondecode(output.lambda_map_definition).States.ReadFiles.ItemProcessor.States.ReadFile.Retry[0].MaxAttempts == 3
    )
    error_message = "The transient Lambda errors must be retried 3 times"
  }

  # The ECS job
  assert {
    condition = (
      jsondecode(output.ecs_job_definition).States.RunJob.TimeoutSeconds == 900 &&
      jsondecode(output.ecs_job_definition).States.RunJob.Retry[0].ErrorEquals[0] == "States.TaskFailed" &&
      jsondecode(output.ecs_job_definition).States.RunJob.Retry[0].MaxAttempts == 2 &&
      jsondecode(output.ecs_job_definition).States.RunJob.Retry[0].IntervalSeconds == 10
    )
    error_message = "The job must time out after 15 minutes and be retried twice, from 10 seconds, when the task fails"
  }

  # The rules and their targets
  assert {
    condition     = jsondecode(output.lambda_map_rule).detail.object.key[0].prefix == "manifests/" && jsondecode(output.ecs_job_rule).detail.object.key[0].prefix == "jobs/"
    error_message = "The rules must select the manifests/ and jobs/ prefixes"
  }

  assert {
    condition     = output.lambda_map_target[1] == "3" && output.lambda_map_target[2] == "3600" && output.ecs_job_target[1] == "3" && output.ecs_job_target[2] == "3600"
    error_message = "The targets must retry the delivery 3 times, within one hour"
  }

  assert {
    condition     = endswith(output.lambda_map_target[3], ":lab-step-function-s3-events-dlq") && endswith(output.ecs_job_target[3], ":lab-step-function-s3-events-dlq")
    error_message = "The events that could not be delivered must go to the DLQ"
  }

  assert {
    condition     = output.dlq[0] == "1209600" && output.dlq[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The DLQ must keep messages 14 days and be encrypted with the shared key"
  }

  assert {
    condition     = output.bucket[0] == "aws:kms" && output.bucket[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000" && lower(output.bucket[2]) == "true"
    error_message = "The bucket must be encrypted with the shared key, with a bucket key"
  }

  # (A) The valid manifest: one Lambda invocation per listed file; the one that lists a missing file fails
  assert {
    condition     = length(jsondecode(output.lambda_map_ok_output)) == 2
    error_message = "The Distributed Map must return one result per listed file"
  }

  assert {
    condition     = toset([for r in jsondecode(output.lambda_map_ok_output) : r.key]) == toset(["data/a.json", "data/b.json"])
    error_message = "The results must name the listed files"
  }

  assert {
    condition     = output.lambda_map_failed_error == "States.ExceedToleratedFailureThreshold"
    error_message = "A manifest that lists a missing file must fail the Map run"
  }

  # (B) The file is processed: the execution ends with the task that ran, stopped; the empty one fails the job on each of its 3 attempts (1 + 2 retries)
  assert {
    condition     = jsondecode(output.ecs_job_ok_output).LastStatus == "STOPPED"
    error_message = "The job of the readable file must have run to completion"
  }

  assert {
    condition     = output.ecs_job_failed_submissions == "3"
    error_message = "The task of the empty file must have been submitted 3 times"
  }
}
