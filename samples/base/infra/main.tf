locals {
  name = "lab-base"

  tags = {
    Environment = "dev"
    Project     = "aws-samples/base"
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

terraform {
  required_version = "1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }
  backend "s3" {
    key     = "states/aws-lab/base"
    region  = "eu-west-3"
    encrypt = true
    # lock file in the bucket (S3 native locking); the bucket comes from `-backend-config`, see `task <ns>:init`
    use_lockfile = true
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
