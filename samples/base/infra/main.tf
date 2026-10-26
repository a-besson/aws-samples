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
  required_version = ">= 1.11.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket  = "aws-lab-tf-states"
    key     = "states/aws-lab/base"
    region  = "eu-west-3"
    encrypt = "true"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
