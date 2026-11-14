output "lambda_map_ok_output" {
  value       = data.external.lambda_map_ok_output.result.output
  description = "Output of the Distributed Map execution started by the valid manifest"
}

output "lambda_map_failed_error" {
  value       = data.external.lambda_map_failed_error.result.output
  description = "Error of the Distributed Map execution started by the manifest that lists a missing file"
}

output "ecs_job_ok_output" {
  value       = data.external.ecs_job_ok_output.result.output
  description = "Output of the ECS job execution started by the file the job can read: the task that ran"
}

output "ecs_job_failed_submissions" {
  value       = data.external.ecs_job_failed_submissions.result.output
  description = "Number of times the ECS task was submitted for the empty file"
}

output "lambda_map_definition" {
  value       = data.external.lambda_map_definition.result.output
  description = "Definition of the Distributed Map state machine, as stored"
}

output "ecs_job_definition" {
  value       = data.external.ecs_job_definition.result.output
  description = "Definition of the ECS job state machine, as stored"
}

output "lambda_map_rule" {
  value       = data.external.lambda_map_rule.result.output
  description = "Event pattern of the rule that starts the Distributed Map"
}

output "ecs_job_rule" {
  value       = data.external.ecs_job_rule.result.output
  description = "Event pattern of the rule that starts the ECS job"
}

output "lambda_map_target" {
  value       = split("\t", data.external.lambda_map_target.result.output)
  description = "Target of the manifests rule: ARN, delivery retries, maximum event age (s) and DLQ"
}

output "ecs_job_target" {
  value       = split("\t", data.external.ecs_job_target.result.output)
  description = "Target of the jobs rule: ARN, delivery retries, maximum event age (s) and DLQ"
}

output "dlq" {
  value       = split("\t", data.external.dlq.result.output)
  description = "Message retention (s) and KMS key of the DLQ"
}

output "bucket" {
  value       = split("\t", data.external.bucket.result.output)
  description = "Default encryption of the bucket: algorithm, KMS key and bucket key"
}
