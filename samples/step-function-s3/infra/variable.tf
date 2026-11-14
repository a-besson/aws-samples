variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS target region"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like eu-west-3."
  }
}

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "AWS profile"

  validation {
    condition     = length(var.aws_profile) > 0
    error_message = "aws_profile must not be empty."
  }
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket holding the Terraform state of the base stack (set TF_VAR_state_bucket in .env)"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket))
    error_message = "state_bucket must be a valid S3 bucket name."
  }
}

variable "job_image" {
  type        = string
  default     = null
  description = "Image of the ECS job (default: the pinned aws-cli image, through the ECR Public pull through cache of the base stack)"

  validation {
    condition     = var.job_image == null || can(regex("^[a-z0-9][a-z0-9./:_-]*(@sha256:[a-f0-9]{64})?$", var.job_image))
    error_message = "job_image must be an image reference, pinned by digest if possible."
  }
}

variable "job_cpu_architecture" {
  type        = string
  default     = "ARM64"
  description = "CPU architecture of the ECS job (ARM64 is the cheapest on Fargate)"

  validation {
    condition     = contains(["ARM64", "X86_64"], var.job_cpu_architecture)
    error_message = "job_cpu_architecture must be ARM64 or X86_64."
  }
}
