variable "aws_region" {
  type        = string
  default     = "eu-west-3"
  description = "AWS target region"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier, e.g. eu-west-3."
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
