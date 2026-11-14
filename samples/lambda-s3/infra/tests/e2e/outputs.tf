output "summary" {
  value       = data.external.summary.result.output
  description = "Summary written by the function for incoming/ok.json"
}

output "dead_letter" {
  value       = data.external.dead_letter.result.output
  description = "Failure record received by the DLQ for incoming/poison.json"
}

output "function" {
  value       = split("\t", data.external.function.result.output)
  description = "Runtime, architecture, memory (MB) and timeout (s) of the function"
}

output "async_config" {
  value       = split("\t", data.external.async_config.result.output)
  description = "Retries, maximum event age (s) and failure destination of the asynchronous invocations"
}

output "notification" {
  value       = split("\t", data.external.notification.result.output)
  description = "Event, then the prefix and suffix filters of the S3 notification"
}

output "dlq" {
  value       = split("\t", data.external.dlq.result.output)
  description = "Message retention (s) and KMS key of the DLQ"
}

output "bucket" {
  value       = split("\t", data.external.bucket.result.output)
  description = "Default encryption of the bucket: algorithm, KMS key and bucket key"
}
