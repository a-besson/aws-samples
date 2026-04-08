run "verify_ecs_cluster_name" {
  command = plan

  assert {
    condition     = module.ecs_cluster.name == "ecs-fargate-cluster"
    error_message = "ECS cluster name did not match"
  }
}
