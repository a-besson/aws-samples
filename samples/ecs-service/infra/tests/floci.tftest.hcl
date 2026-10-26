# Applies this stack on the Floci emulator with fake credentials (never on a real account).
# Run with `task ecs-service:test`; CI runs it in the `terraform` job of _build-sample.yml.
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
    appautoscaling = var.floci_endpoint
    ec2            = var.floci_endpoint
    ecs            = var.floci_endpoint
    iam            = var.floci_endpoint
    sts            = var.floci_endpoint
    cloudwatchlogs = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its outputs are replaced by the default network of Floci.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id              = "vpc-default-eu-west-3"
      vpc_cidr            = "172.31.0.0/16"
      subnets_private_ids = ["subnet-default-eu-west-3-a"]
    }
  }
}

# Floci starts a real container for every ECS service task and then cannot delete the cluster: the service is
# replaced by a mock, the cluster, task definition, security group and IAM roles are still applied.
override_resource {
  target = module.ecs_service.aws_ecs_service.this
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = module.ecs_cluster.name == "ecs-fargate-cluster"
    error_message = "ECS cluster name did not match"
  }
}
