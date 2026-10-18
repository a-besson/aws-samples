# Applies this stack on the Floci emulator with fake credentials (never on a real account).
# Run with `task rds-aurora-pg:test`; CI runs it in the `terraform` job of _build-sample.yml.
# It checks the wiring of the resources, not the database behaviour.

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
    ec2 = var.floci_endpoint
    iam = var.floci_endpoint
    rds = var.floci_endpoint
    sts = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its outputs are replaced by the default network of Floci.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id               = "vpc-default-eu-west-3"
      vpc_azs              = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
      subnets_database_ids = ["subnet-default-eu-west-3-a", "subnet-default-eu-west-3-b", "subnet-default-eu-west-3-c"]
      subnets_private_cidr = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
    }
  }
}

# Floci gaps, handled here rather than in the stack:
# - DescribeDBEngineVersions is not implemented
# - the DB subnet group and the Aurora cluster are not applied: Floci's RDS rejects the subnets of its own default
#   network and starts a real database container per cluster, so the module is mocked
override_data {
  target = data.aws_rds_engine_version.postgresql
  values = {
    version = "16.4"
  }
}

override_resource {
  target = aws_db_subnet_group.default
  values = {
    name = "lab-infra-rds-subnet-group"
  }
}

override_module {
  target = module.aurora_master
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = aws_db_subnet_group.default.name == "lab-infra-rds-subnet-group"
    error_message = "DB subnet group name did not match"
  }

  assert {
    condition     = length(random_password.master.result) == 20
    error_message = "The generated master password must have 20 characters"
  }
}
