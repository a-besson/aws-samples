# kics-scan ignore-block
resource "random_password" "master" {
  length  = 20
  special = true
}

resource "aws_db_subnet_group" "default" {
  name       = "${local.name}-rds-subnet-group"
  subnet_ids = local.states.vpc.subnets_database_ids
}

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "16.4"
}

module "aurora_master" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.11.0"

  name              = "${local.name}-postgresql"
  engine            = "aurora-postgresql"
  engine_mode       = "provisioned"
  engine_version    = data.aws_rds_engine_version.postgresql.version
  storage_encrypted = true

  database_name               = "demo"
  master_username             = "adminpg"
  manage_master_user_password = true
  iam_database_authentication_enabled = true
  
  vpc_id               = local.states.vpc.vpc_id
  db_subnet_group_name = aws_db_subnet_group.default.name
  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = local.states.vpc.subnets_private_cidr
    }
  }

  monitoring_interval = 60

  apply_immediately = true
  serverlessv2_scaling_configuration = {
    min_capacity             = 0
    max_capacity             = 2
    seconds_until_auto_pause = 360
  }

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false


  instance_class = "db.serverless"
  instances = {
    one = {}
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
