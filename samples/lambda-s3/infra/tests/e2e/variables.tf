variable "floci_endpoint" {
  type        = string
  description = "Endpoint of the local Floci emulator"

  validation {
    condition     = can(regex("^http://(localhost|127\\.0\\.0\\.1):[0-9]+$", var.floci_endpoint))
    error_message = "floci_endpoint must be a local endpoint such as http://localhost:4566."
  }
}

variable "bucket_name" {
  type        = string
  description = "Bucket of the sample under test"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be a valid S3 bucket name."
  }
}

variable "function_name" {
  type        = string
  description = "Lambda function of the sample under test"

  validation {
    condition     = length(var.function_name) > 0
    error_message = "function_name must not be empty."
  }
}

variable "dlq_url" {
  type        = string
  description = "URL of the dead letter queue of the sample under test"

  validation {
    condition     = can(regex("^http://(localhost|127\\.0\\.0\\.1):[0-9]+/[0-9]+/.+$", var.dlq_url))
    error_message = "dlq_url must be a queue URL of the local Floci emulator."
  }
}
