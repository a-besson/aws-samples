locals {
  name = "lab-${basename(path.cwd)}"

  tags = {
    Environment = "dev"
    Project     = "aws-samples/${local.name}"
    Stack       = basename(path.cwd)
    ManagedBy   = "Terraform"
  }
}

terraform {
  required_version = "1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
  backend "s3" {
    key     = "states/aws-lab/aurora-pg"
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
