# Applies this stack on the Floci emulator with fake credentials (never on a real account), then runs the end-to-end
# checks of tests/e2e against it. Run with `task ecs-task-s3:test`; CI runs it in the `terraform-test` job of
# _build-sample.yml.
#
# Floci 2.4.0, probed before writing this file:
# - S3 events reach EventBridge natively, and the rule starts the ECS task natively (EcsParameters, input transformer,
#   retry policy). The task definition ARN of the target must carry its revision, which the Terraform ARN does
# - the ECS task runs in a container started by Floci, which injects the endpoint and fake credentials. A task for the
#   cpuArchitecture it names: ARM64 would need emulation on an amd64 runner, so the test asks for X86_64 (the stack
#   defaults to ARM64, the cheapest on Fargate)
# - the DLQ path is not reproducible here: it needs a RunTask that EventBridge cannot deliver (no capacity, throttling)
# It checks the wiring and the behaviour of the job, not the IAM policies (Floci does not enforce them).

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
    sqs            = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    cloudwatchlogs = var.floci_endpoint
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
    condition     = output.bucket_name == "lab-ecs-task-s3-000000000000"
    error_message = "The bucket must be named after the sample and the account"
  }

  assert {
    condition     = endswith(output.cluster_arn, ":cluster/lab-ecs-task-s3")
    error_message = "The cluster name did not match"
  }

  assert {
    condition     = aws_ecs_task_definition.job.family == "lab-ecs-task-s3-job" && aws_ecs_task_definition.job.cpu == "256" && aws_ecs_task_definition.job.memory == "512"
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
    floci_endpoint = var.floci_endpoint
    bucket_name    = run.apply_on_floci.bucket_name
    cluster_arn    = run.apply_on_floci.cluster_arn
    dlq_url        = run.apply_on_floci.dlq_url
  }

  # Contract, read back from the emulator
  assert {
    condition     = jsondecode(output.rule).detail.object.key[0].prefix == "incoming/"
    error_message = "The rule must select the incoming/ prefix"
  }

  assert {
    condition     = output.target[4] == "FARGATE" && endswith(output.target[5], run.apply_on_floci.task_definition_arn)
    error_message = "The target must run the job task definition, with its revision, on Fargate"
  }

  assert {
    condition     = output.target[1] == "3" && output.target[2] == "3600"
    error_message = "The target must retry the delivery 3 times, within one hour"
  }

  assert {
    condition     = endswith(output.target[3], ":lab-ecs-task-s3-dlq")
    error_message = "The events that could not be delivered must go to the DLQ"
  }

  assert {
    condition     = strcontains(output.target[6], "containerOverrides") && strcontains(output.target[6], "<bucket>") && strcontains(output.target[6], "<key>")
    error_message = "The input template must override the BUCKET and KEY variables of the container"
  }

  assert {
    condition     = output.dlq[0] == "1209600" && output.dlq[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000"
    error_message = "The DLQ must keep messages 14 days and be encrypted with the shared key"
  }

  assert {
    condition     = output.bucket[0] == "aws:kms" && output.bucket[1] == "arn:aws:kms:eu-west-3:000000000000:key/00000000-0000-0000-0000-000000000000" && lower(output.bucket[2]) == "true"
    error_message = "The bucket must be encrypted with the shared key, with a bucket key"
  }

  # Behaviour: the rule started one task per file, with the file passed in the environment. The job succeeded on the
  # readable file and exited with an error on the empty one, which EventBridge does not retry (2 tasks in all)
  assert {
    condition     = length(output.tasks) == 2
    error_message = "One task per file, and no retry of the task that failed"
  }

  assert {
    condition     = contains(output.tasks, "eventbridge\t${run.apply_on_floci.bucket_name}\tincoming/ok.txt\t0")
    error_message = "The readable file must have been processed by a task started by the rule (exit code 0)"
  }

  assert {
    condition     = contains(output.tasks, "eventbridge\t${run.apply_on_floci.bucket_name}\tincoming/empty.txt\t1")
    error_message = "The empty file must have made its task exit with an error (exit code 1)"
  }
}
