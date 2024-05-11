
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service             = "s3"
      private_dns_enabled = true
      route_table_ids     = module.vpc.private_route_table_ids
      service_type        = "Gateway"
      tags                = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    ecs = {
      service    = "ecs"
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecs-vpc-endpoint" }
    },
    ecs_telemetry = {
      create     = false
      service    = "ecs-telemetry"
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecs-telemetry-vpc-endpoint" }
    },
    ecr_api = {
      service    = "ecr.api"
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecr-api-vpc-endpoint" }

    },
    ecr_dkr = {
      service    = "ecr.dkr"
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecr-dkr-vpc-endpoint" }
    },
    rds = {
      service            = "rds"
      subnet_ids         = module.vpc.private_subnets
      security_group_ids = [aws_security_group.rds.id]
      tags               = { Name = "rds-vpc-endpoint" }
    },
    logs = {
      service    = "logs"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "logs-vpc-endpoint" }
    },
  }

  tags = local.tags
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}

data "aws_iam_policy_document" "ecr_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpc"

      values = [module.vpc.vpc_id]
    }
  }
}
data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "vpc_endpoint_policy_default" {
  statement {
    actions = ["*"]
    effect  = "Allow"
    resources = [
      "*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = local.tags
}

resource "aws_security_group" "vpc_endpoints_ecr" {
  name_prefix = "ecr-vpc-endpoints"
  description = "Associated to ECR/s3 VPC Endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow Nodes to pull images from ECR via VPC endpoints"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.ecs_tasks.id] # to be replaced
  }

  tags = local.tags
}

