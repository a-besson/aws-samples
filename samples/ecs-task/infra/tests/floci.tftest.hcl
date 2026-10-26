# Applies this stack on the Floci emulator with fake credentials (never on a real account).
# Run with `task ecs-task:test`; CI runs it in the `terraform` job of _build-sample.yml.
# It checks the wiring of the resources, not the IAM policies nor the container.

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
    ecs            = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    cloudwatchlogs = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its outputs are replaced by fixtures.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id             = "vpc-00000000"
      subnets_public_ids = ["subnet-00000000"]
    }
  }
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = aws_ecs_task_definition.batch.family == "lab-infra-task"
    error_message = "ECS task family name did not match"
  }

  assert {
    condition     = aws_cloudwatch_log_group.batch.retention_in_days == 1
    error_message = "The batch log group must keep logs one day"
  }

  assert {
    condition     = output.task_definition_arn != ""
    error_message = "The task definition was not registered"
  }
}
