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

variable "lambda_map_state_machine_arn" {
  type        = string
  description = "State machine of the Distributed Map, started by a manifest"

  validation {
    condition     = can(regex("^arn:aws:states:[a-z0-9-]+:[0-9]{12}:stateMachine:.+$", var.lambda_map_state_machine_arn))
    error_message = "lambda_map_state_machine_arn must be a state machine ARN."
  }
}

variable "ecs_job_state_machine_arn" {
  type        = string
  description = "State machine of the ECS job, started by a file under jobs/"

  validation {
    condition     = can(regex("^arn:aws:states:[a-z0-9-]+:[0-9]{12}:stateMachine:.+$", var.ecs_job_state_machine_arn))
    error_message = "ecs_job_state_machine_arn must be a state machine ARN."
  }
}

variable "events_dlq_url" {
  type        = string
  description = "URL of the dead letter queue of the EventBridge rules"

  validation {
    condition     = can(regex("^http://(localhost|127\\.0\\.0\\.1):[0-9]+/[0-9]+/.+$", var.events_dlq_url))
    error_message = "events_dlq_url must be a queue URL of the local Floci emulator."
  }
}
