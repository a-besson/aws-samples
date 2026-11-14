locals {
  states = {
    vpc = data.terraform_remote_state.vpc.outputs
  }

  # aws-cli v2, pinned by tag and digest (public.ecr.aws/aws-cli/aws-cli), pulled through the ECR Public pull through cache
  # of the base stack: the first pull of an image must be done from your workstation, see the README of the base stack
  job_image = coalesce(
    var.job_image,
    "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.states.vpc.ecr_public_pull_through_prefix}/aws-cli/aws-cli:2.39.6@sha256:eccdb3ec77e159d43ca6a750a70738c546883138be7f094498294a1477ec7e42",
  )
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

# The job reaches S3 through the gateway endpoint of the base stack
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}
