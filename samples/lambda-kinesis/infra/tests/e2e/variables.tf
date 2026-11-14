variable "floci_endpoint" {
  type        = string
  description = "Endpoint of the local Floci emulator"

  validation {
    condition     = can(regex("^http://(localhost|127\\.0\\.0\\.1):[0-9]+$", var.floci_endpoint))
    error_message = "floci_endpoint must be a local endpoint such as http://localhost:4566."
  }
}

variable "stream_name" {
  type        = string
  description = "Kinesis stream of the sample under test"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,128}$", var.stream_name))
    error_message = "stream_name must be a valid Kinesis stream name."
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

variable "table_name" {
  type        = string
  description = "DynamoDB table of the sample under test"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.table_name))
    error_message = "table_name must be a valid DynamoDB table name."
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
