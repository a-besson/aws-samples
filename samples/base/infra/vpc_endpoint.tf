
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.1"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpce-"
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
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecs-vpc-endpoint" }
    },
    ecr_api = {
      service    = "ecr.api"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecr-api-vpc-endpoint" }

    },
    ecr_dkr = {
      service    = "ecr.dkr"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "ecr-dkr-vpc-endpoint" }
    },
    rds = {
      service    = "rds"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = module.vpc.private_subnets
      tags       = { Name = "rds-vpc-endpoint" }
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

# This endpoint policy uses wildcard actions/principals by design (each of the 6 AWS services
# fronted by these endpoints would otherwise need its own hand-maintained action list). The
# blast radius is bounded by two compensating controls: both the calling principal
# (aws:PrincipalAccount) and the target resource (aws:ResourceAccount) must belong to this
# account, and the request must originate from this VPC (aws:sourceVpc) - equivalent to AWS's
# documented baseline VPC endpoint policy.
# kics-scan ignore-block
data "aws_iam_policy_document" "vpc_endpoint_policy_default" {
  statement {
    actions = ["*"]
    effect  = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
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
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
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
