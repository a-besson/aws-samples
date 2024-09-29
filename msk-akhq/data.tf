locals {
  states = {
    vpc = data.terraform_remote_state.vpc.outputs
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aws-lab-terraform-states"
    key    = "states/aws-lab/vpc"
    region = "eu-west-3"
  }
}