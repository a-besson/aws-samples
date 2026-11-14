output "bucket_name" {
  value       = module.bucket.s3_bucket_id
  description = "Bucket to drop the manifests (manifests/), the files they list (data/) and the job inputs (jobs/) into"
}

output "lambda_map_state_machine_arn" {
  value       = module.lambda_map.state_machine_arn
  description = "State machine started by a manifest: a Lambda invocation per listed file, in parallel"
}

output "ecs_job_state_machine_arn" {
  value       = module.ecs_job.state_machine_arn
  description = "State machine started by a file under jobs/: an ECS Fargate job, awaited and retried"
}

output "cluster_arn" {
  value       = module.ecs_cluster.arn
  description = "ECS cluster that runs the jobs"
}

output "events_dlq_url" {
  value       = module.events_dlq.queue_url
  description = "URL of the dead letter queue of the two EventBridge rules"
}
