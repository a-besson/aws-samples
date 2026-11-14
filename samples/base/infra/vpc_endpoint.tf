# Interface endpoints are billed per hour and per AZ: on this lab they live in the first private subnet only, the
# other AZs reach them across the VPC. Gateway endpoints (S3, DynamoDB) are free.
locals {
  interface_endpoints = {
    ecs = {
      service    = "ecs"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)
      tags       = { Name = "ecs-vpc-endpoint" }
    },
    ecr_api = {
      service    = "ecr.api"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)
      tags       = { Name = "ecr-api-vpc-endpoint" }
    },
    ecr_dkr = {
      service    = "ecr.dkr"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)
      tags       = { Name = "ecr-dkr-vpc-endpoint" }
    },
    logs = {
      service    = "logs"
      policy     = data.aws_iam_policy_document.vpc_endpoint_policy_default.json
      subnet_ids = slice(module.vpc.private_subnets, 0, 1)
      tags       = { Name = "logs-vpc-endpoint" }
    },
  }
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0"

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

  endpoints = merge(
    {
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
    },
    var.enable_interface_endpoints ? local.interface_endpoints : {},
  )

  tags = local.tags
}

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
