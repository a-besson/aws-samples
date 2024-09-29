# VPC Stack

#### Use state in another stack
```hcl
locals {
  vpc = data.terraform_remote_state.vpc.outputs.vpc_id
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aws-lab-terraform-states"
    key    = "states/aws-lab/vpc"
    region = "eu-west-3"
  }
}
```

#### VPC & Subnet CIDRs
```bash
vpc_cidr = "172.16.0.0/16"
subnets_public_cidr = tolist([
  "172.16.0.0/24",
  "172.16.1.0/24",
  "172.16.2.0/24",
])
subnets_private_cidr = tolist([
  "172.16.64.0/20",
  "172.16.80.0/20",
  "172.16.96.0/20",
])
subnets_database_cidr = tolist([
  "172.16.8.0/24",
  "172.16.9.0/24",
  "172.16.10.0/24",
])
```