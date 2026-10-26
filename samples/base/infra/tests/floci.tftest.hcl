# Applies this stack on the Floci emulator with fake credentials (never on a real account).
# Run with `task base:test`; CI runs it in the `terraform` job of _build-sample.yml.
# It checks the wiring of the resources, not the IAM or AWS Config behaviour.

variables {
  floci_endpoint = "http://localhost:4566"
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
    ec2           = var.floci_endpoint
    iam           = var.floci_endpoint
    rds           = var.floci_endpoint
    s3            = var.floci_endpoint
    sts           = var.floci_endpoint
    configservice = var.floci_endpoint
  }
}

# Floci gaps, handled here rather than in the stack:
# - PutRemediationConfigurations is not implemented
# - the recorder is never stopped on destroy, which then blocks the deletion of the delivery channel
override_resource {
  target = aws_config_remediation_configuration.remediation_sg
}

override_resource {
  target = aws_config_configuration_recorder_status.config_recorder_status
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = module.vpc.vpc_cidr_block == "172.16.0.0/16"
    error_message = "VPC CIDR block did not match expected value"
  }

  assert {
    condition     = length(module.vpc.private_subnets) == 3
    error_message = "Expected 3 private subnets"
  }

  assert {
    condition     = length(module.vpc.database_subnets) == 3
    error_message = "Expected 3 database subnets"
  }

  assert {
    condition     = aws_config_delivery_channel.delivery.name == "delivery-channel"
    error_message = "Config delivery channel name did not match"
  }
}
