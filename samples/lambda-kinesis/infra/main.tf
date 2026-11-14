locals {
  name = "lab-lambda-kinesis"
  tags = {
    Environment = "dev"
    Project     = "aws-samples/lambda-kinesis"
    Stack       = "lambda-kinesis"
    ManagedBy   = "Terraform"
  }
}

terraform {
  required_version = "1.17.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    # used by the lambda module to build the package
    external = {
      source  = "hashicorp/external"
      version = "2.4.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.3.2"
    }
  }
  backend "s3" {
    key     = "states/aws-lab/samples/lambda-kinesis"
    region  = "eu-west-3"
    encrypt = true
    # lock file in the bucket (S3 native locking); the bucket comes from `-backend-config`, see `task <ns>:init`
    use_lockfile = true
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region

  default_tags {
    tags = local.tags
  }
}
