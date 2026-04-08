run "verify_msk_version" {
  command = plan

  assert {
    condition     = module.msk_cluster[0].kafka_version == "3.5.1"
    error_message = "MSK version did not match"
  }
}
