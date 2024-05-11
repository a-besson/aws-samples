
module "msk_cluster" {
  count  = 1
  source = "terraform-aws-modules/msk-kafka-cluster/aws"

  name = local.name

  kafka_version = "3.5.1"

  number_of_broker_nodes = 3

  broker_node_instance_type  = "kafka.t3.small"
  broker_node_client_subnets = module.vpc.private_subnets
  broker_node_storage_info = {
    ebs_storage_info = { volume_size = 20 }
  }

  client_authentication = {
    sasl = { iam = true }
  }
  broker_node_security_groups = [module.security_group.security_group_id]

  create_connect_worker_configuration = false

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Security group for ${local.name}"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = module.vpc.private_subnets_cidr_blocks
  ingress_rules = [
    "kafka-broker-tcp",
    "kafka-broker-sasl-iam-tcp",
    "kafka-broker-tls-tcp"
  ]

  tags = local.tags
}
