locals {
  name = "lab-${basename(path.cwd)}"
}

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
    key     = "states/aws-lab/samples/ecs-task"
    region  = "eu-west-3"
    encrypt = "true"
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}
