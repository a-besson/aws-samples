# VPC
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC id"
}
output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC cidr"
}
output "vpc_azs" {
  value       = module.vpc.azs
  description = "VPC AZs"
}

# Subnets
output "subnets_public_ids" {
  value       = module.vpc.public_subnets
  description = "Public subnets IDS"
}
output "subnets_public_cidr" {
  value       = module.vpc.public_subnets_cidr_blocks
  description = "Public subnets CIDR"
}

output "subnets_private_ids" {
  value       = module.vpc.private_subnets
  description = "Private subnets IDs"
}
output "subnets_private_cidr" {
  value       = module.vpc.private_subnets_cidr_blocks
  description = "Private subnets CIDR"
}

output "subnets_database_ids" {
  value       = module.vpc.database_subnets
  description = "Database subnets IDs"
}
output "subnets_database_cidr" {
  value       = module.vpc.database_subnets_cidr_blocks
  description = "Database subnets cidr"
}
output "subnets_database_subnet_group" {
  value       = module.vpc.database_subnet_group
  description = "Database subnets group name"
}

# VPCE
output "vpc_endpoint_sg_id" {
  value       = module.vpc_endpoints.security_group_id
  description = "VPC endpoint security group ID"
}