run "verify_ecs_task_family" {
  command = plan

  assert {
    condition     = aws_ecs_task_definition.batch.family == "lab-ecs-task-task"
    error_message = "ECS Task family name did not match"
  }
}
