locals {
  name = "lab-ecs-task-s3"
  tags = {
    Environment = "dev"
    Project     = "aws-samples/ecs-task-s3"
    Stack       = "ecs-task-s3"
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
  }
  backend "s3" {
    key     = "states/aws-lab/samples/ecs-task-s3"
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
