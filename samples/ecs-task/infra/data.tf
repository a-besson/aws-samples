locals {
  states = {
    vpc = data.terraform_remote_state.vpc.outputs
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "states/aws-lab/base"
    region = var.aws_region
  }
}
