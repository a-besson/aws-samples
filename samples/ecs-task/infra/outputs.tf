output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.batch.arn
  description = "ARN of the batch task definition run by `task run`"
}

output "ecs_cluster_arn" {
  value       = aws_ecs_cluster.batch.arn
  description = "ARN of the ECS cluster the batch task runs on"
}

output "vpc_id" {
  value       = local.states.vpc.vpc_id
  description = "VPC id"
}

output "subnets_private_ids" {
  value       = local.states.vpc.subnets_private_ids
  description = "Private subnets IDs (task run launches here - no public IP assigned)"
}

output "vpc_endpoint_sg_id" {
  value       = local.states.vpc.vpc_endpoint_sg_id
  description = "Security group allowing HTTPS to the VPC endpoints (ECR, logs, ...) used by `task run`"
}
