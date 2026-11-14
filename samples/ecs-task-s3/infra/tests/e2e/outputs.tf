output "tasks" {
  value       = split("\n", data.external.tasks.result.output)
  description = "One entry per stopped task: starter, BUCKET, KEY and exit code, tab separated"
}

output "rule" {
  value       = data.external.rule.result.output
  description = "Event pattern of the rule that runs the task"
}

output "target" {
  value       = split("\t", data.external.target.result.output)
  description = "Target of the rule: cluster, delivery retries, maximum event age (s), DLQ, launch type, task definition and input template"
}

output "dlq" {
  value       = split("\t", data.external.dlq.result.output)
  description = "Message retention (s) and KMS key of the DLQ"
}

output "bucket" {
  value       = split("\t", data.external.bucket.result.output)
  description = "Default encryption of the bucket: algorithm, KMS key and bucket key"
}
