# kics-scan ignore-block
resource "random_password" "master" {
  length  = 20
  special = true
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.9.1"

  name              = "${local.name}-postgresqlv2"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  storage_encrypted = true
  master_username   = "useradmin"

  vpc_id               = local.states.vpc.vpc_id
  db_subnet_group_name = local.states.vpc.database_subnet_group_name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = local.states.vpc.subnets_private_cidr
    }
  }

  monitoring_interval = 60

  apply_immediately   = true
  skip_final_snapshot = true

  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 4
  }

  manage_master_user_password = false
  master_password             = random_password.master.result

  instance_class = "db.serverless"
  instances = {
    one = {}
    two = {}
  }

  #enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group = false

  # Multi-AZ
  availability_zones = local.states.vpc.vpc_azs

  create_db_cluster_activity_stream = false
  #db_cluster_activity_stream_kms_key_id = module.kms.key_id
  #db_cluster_activity_stream_mode       = "async"
}

/* 
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  deletion_window_in_days = 7
  description             = "KMS key for ${local.name} cluster activity stream."
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = [local.name]

  tags = local.tags
} 
*/
