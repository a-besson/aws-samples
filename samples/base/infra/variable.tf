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

variable "enable_interface_endpoints" {
  type        = bool
  default     = true
  description = "Create the interface endpoints (ECS, ECR, CloudWatch Logs) that the ECS samples need in the private subnets; false removes their hourly cost when no ECS sample is deployed"

  validation {
    condition     = var.enable_interface_endpoints != null
    error_message = "enable_interface_endpoints must be true or false."
  }
}
