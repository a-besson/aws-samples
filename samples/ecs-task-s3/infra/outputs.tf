output "bucket_name" {
  value       = module.bucket.s3_bucket_id
  description = "Bucket to drop the files into (incoming/)"
}

output "cluster_arn" {
  value       = module.ecs_cluster.arn
  description = "ECS cluster that runs the task"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.job.arn
  description = "Task definition run for each file"
}

output "dlq_url" {
  value       = module.dlq.queue_url
  description = "URL of the dead letter queue of the rule target"
}
