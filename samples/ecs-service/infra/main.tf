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
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
  backend "s3" {
    bucket  = "aws-lab-tf-states"
    key     = "states/aws-lab/ecs"
    region  = "eu-west-3"
    encrypt = "true"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
