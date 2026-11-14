output "bucket_name" {
  value       = module.bucket.s3_bucket_id
  description = "Bucket to drop the JSON files into (incoming/) and to read the summaries from (processed/)"
}

output "function_name" {
  value       = module.reader.lambda_function_name
  description = "Name of the Lambda function triggered by the S3 notification"
}

output "dlq_url" {
  value       = module.dlq.queue_url
  description = "URL of the dead letter queue that receives the failed invocations"
}
