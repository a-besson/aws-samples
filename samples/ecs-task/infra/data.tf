locals {
  states = {
    vpc = data.terraform_remote_state.vpc.outputs
  }

  ecr_public_cache = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.states.vpc.ecr_public_pull_through_prefix}"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "states/aws-lab/base"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}
