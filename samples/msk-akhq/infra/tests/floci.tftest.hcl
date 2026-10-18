# Applies this stack on the Floci emulator with fake credentials (never on a real account).
# Run with `task msk-akhq:test`; CI runs it in the `terraform` job of _build-sample.yml.
# It checks the wiring of the resources, not the IAM policies nor the containers.

variables {
  floci_endpoint      = "http://localhost:4566"
  state_bucket        = "floci-state"
  acm_certificate_arn = "arn:aws:acm:eu-west-3:000000000000:certificate/00000000-0000-0000-0000-000000000000"
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
    cloudwatchlogs = var.floci_endpoint
    ec2            = var.floci_endpoint
    ecs            = var.floci_endpoint
    elbv2          = var.floci_endpoint
    iam            = var.floci_endpoint
    kafka          = var.floci_endpoint
    sts            = var.floci_endpoint
  }
}

# The base stack lives in the real S3 backend: its outputs are replaced by the default network of Floci.
override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id               = "vpc-default-eu-west-3"
      subnets_private_ids  = ["subnet-default-eu-west-3-a", "subnet-default-eu-west-3-b", "subnet-default-eu-west-3-c"]
      subnets_private_cidr = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
      subnets_public_ids   = ["subnet-default-eu-west-3-a", "subnet-default-eu-west-3-b", "subnet-default-eu-west-3-c"]
    }
  }
}

# Floci starts a real container for every ECS service task and then cannot delete the cluster: the service is
# replaced by a mock, the cluster, task definition, load balancer, MSK cluster and IAM roles are still applied.
override_resource {
  target = aws_ecs_service.ecs_service
}

run "apply_on_floci" {
  command = apply

  assert {
    condition     = module.msk_cluster[0].arn != ""
    error_message = "The MSK cluster was not created"
  }

  assert {
    condition     = aws_ecs_task_definition.ecs_task_app.family == "lab-infra-container"
    error_message = "The AKHQ task definition was not registered"
  }
}
