output "task_definition_arn" {
  value = aws_ecs_task_definition.batch.arn
}

output "vpc_id" {
  value = local.states.vpc.vpc_id
}

output "subnet_id" {
  value = local.states.vpc.subnets_public_ids[0]
}
