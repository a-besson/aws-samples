output "item" {
  value       = split("\t", data.external.item.result.output)
  description = "Id and payload of the event stored for evt-ok"
}

output "dead_letter" {
  value       = data.external.dead_letter.result.output
  description = "Failure record received by the DLQ for the invalid record"
}

output "function" {
  value       = split("\t", data.external.function.result.output)
  description = "Runtime, architecture, memory (MB) and timeout (s) of the function"
}

output "mapping" {
  value       = split("\t", data.external.mapping.result.output)
  description = "Event source mapping: starting position, batch size, batching window (s), retries, record age (s), bisect, response type and failure destination"
}

output "stream" {
  value       = split("\t", data.external.stream.result.output)
  description = "Stream mode, shards, retention (hours), encryption type and KMS key"
}

output "table" {
  value       = split("\t", data.external.table.result.output)
  description = "Partition key, billing mode, encryption type and KMS key of the table"
}

output "dlq" {
  value       = split("\t", data.external.dlq.result.output)
  description = "Message retention (s) and KMS key of the DLQ"
}
