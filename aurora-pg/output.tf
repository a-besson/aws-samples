################################################################################
# DB Subnet Group
################################################################################

output "db_subnet_group_name" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.default
}

################################################################################
# Cluster
################################################################################

# output "cluster_arn" {
#   description = "Amazon Resource Name (ARN) of cluster"
#   value       = module.aurora_master.cluster_arn
# }

# output "cluster_id" {
#   description = "The RDS Cluster Identifier"
#   value       = module.aurora_master.cluster_id
# }


# output "cluster_endpoint" {
#   description = "Writer endpoint for the cluster"
#   value       = module.aurora_master.cluster_endpoint
# }

# output "cluster_reader_endpoint" {
#   description = "A read-only endpoint for the cluster, automatically load-balanced across replicas"
#   value       = module.aurora_master.cluster_reader_endpoint
# }
