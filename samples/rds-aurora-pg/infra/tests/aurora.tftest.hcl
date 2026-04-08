run "verify_aurora_engine" {
  command = plan

  assert {
    condition     = module.aurora_master.cluster_engine == "aurora-postgresql"
    error_message = "Aurora engine type did not match"
  }
}
