run "verify_vpc_cidr" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "172.16.0.0/16"
    error_message = "VPC CIDR block did not match expected value"
  }
}

run "verify_subnets" {
  command = plan

  assert {
    condition     = length(module.vpc.private_subnets) == 3
    error_message = "Expected 3 private subnets"
  }
}
