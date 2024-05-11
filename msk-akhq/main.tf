locals {
  name = "lab-${basename(path.cwd)}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "aws-samples"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.4"
    }
  }
  backend "s3" {
    bucket  = "aws-lab-terraform-states"
    key     = "states/aws-lab/lab01"
    region  = "eu-west-3"
    encrypt = "true"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}