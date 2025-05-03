# VPC Stack

#### Use state in another stack
```hcl
locals {
  vpc = data.terraform_remote_state.vpc.outputs.vpc_id
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aws-lab-tf-states"
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
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.68.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 5.13.0 |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 5.13.0 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.dynamodb_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_endpoint_policy_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |
| <a name="input_terraform_states_bucket"></a> [terraform\_states\_bucket](#input\_terraform\_states\_bucket) | Terraform states bucket | `string` | `"aws-lab-tf-states"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subnets_database_cidr"></a> [subnets\_database\_cidr](#output\_subnets\_database\_cidr) | Database subnets cidr |
| <a name="output_subnets_database_ids"></a> [subnets\_database\_ids](#output\_subnets\_database\_ids) | Database subnets IDs |
| <a name="output_subnets_database_subnet_group"></a> [subnets\_database\_subnet\_group](#output\_subnets\_database\_subnet\_group) | Database subnets group name |
| <a name="output_subnets_private_cidr"></a> [subnets\_private\_cidr](#output\_subnets\_private\_cidr) | Private subnets CIDR |
| <a name="output_subnets_private_ids"></a> [subnets\_private\_ids](#output\_subnets\_private\_ids) | Private subnets IDs |
| <a name="output_subnets_public_cidr"></a> [subnets\_public\_cidr](#output\_subnets\_public\_cidr) | Public subnets CIDR |
| <a name="output_subnets_public_ids"></a> [subnets\_public\_ids](#output\_subnets\_public\_ids) | Public subnets IDS |
| <a name="output_vpc_azs"></a> [vpc\_azs](#output\_vpc\_azs) | VPC AZs |
| <a name="output_vpc_cidr"></a> [vpc\_cidr](#output\_vpc\_cidr) | VPC cidr |
| <a name="output_vpc_endpoint_sg_id"></a> [vpc\_endpoint\_sg\_id](#output\_vpc\_endpoint\_sg\_id) | VPC endpoint security group ID |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC id |
<!-- END_TF_DOCS -->