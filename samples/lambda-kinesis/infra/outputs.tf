output "stream_name" {
  value       = aws_kinesis_stream.events.name
  description = "Kinesis stream to put the events into"
}

output "function_name" {
  value       = module.consumer.lambda_function_name
  description = "Name of the Lambda function that consumes the stream"
}

output "table_name" {
  value       = module.events_table.dynamodb_table_id
  description = "DynamoDB table holding the processed events (partition key pk = the id of the event)"
}

output "dlq_url" {
  value       = module.dlq.queue_url
  description = "URL of the dead letter queue that receives the metadata of the failed batches"
}
