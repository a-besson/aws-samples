locals {
  vpc_cidr = "172.16.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

# kics-scan ignore-block
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "vpc-aws-lab"
  cidr = "172.16.0.0/16"

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 8)]

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway  = true
  single_nat_gateway  = true
  reuse_nat_ips       = false

  tags = local.tags
}