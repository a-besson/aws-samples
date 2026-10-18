locals {
  name = "lab-${basename(path.cwd)}"

  container_name = "ecs-sample"
  container_port = 8080

  tags = {
    Environment = "dev"
    Project     = "aws-samples/${local.name}"
    Stack       = basename(path.cwd)
    ManagedBy   = "Terraform"
  }
}

data "aws_caller_identity" "current" {}

terraform {
  required_version = "1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }
  backend "s3" {
    key     = "states/aws-lab/ecs"
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
