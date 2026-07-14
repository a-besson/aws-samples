
module "msk_cluster" {
  count   = 1
  source  = "terraform-aws-modules/msk-kafka-cluster/aws"
  version = "3.3.0"

  name = local.name

  # Recommended MSK version (last to support both ZooKeeper and KRaft, extended support for
  # a minimum of 2 years): https://docs.aws.amazon.com/msk/latest/developerguide/supported-kafka-versions.html
  kafka_version = "3.9.x"

  number_of_broker_nodes = 3

  broker_node_instance_type  = "kafka.t3.small"
  broker_node_client_subnets = local.states.vpc.subnets_private_ids
  broker_node_storage_info = {
    ebs_storage_info = { volume_size = 20 }
  }

  client_authentication = {
    sasl = { iam = true }
  }
  broker_node_security_groups = [module.security_group.id]

  create_connect_worker_configuration = false
}

locals {
  # Port numbers for the MSK broker listeners this sample's clients need
  # (source: terraform-aws-modules/security-group named-rule catalog).
  msk_broker_ports = {
    plaintext = 9092
    tls       = 9094
    sasl_iam  = 9098
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"

  name            = local.name
  use_name_prefix = false
  description     = "Security group for ${local.name}"
  vpc_id          = local.states.vpc.vpc_id

  ingress_rules = merge([
    for rule_name, port in local.msk_broker_ports : {
      for idx, cidr in local.states.vpc.subnets_private_cidr :
      "${rule_name}_${idx}" => {
        description = "Kafka ${rule_name} broker access from private subnets"
        cidr_ipv4   = cidr
        from_port   = port
        to_port     = port
        ip_protocol = "tcp"
      }
    }
  ]...)
}
