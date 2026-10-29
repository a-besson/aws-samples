# aurora-pg

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.16.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.100.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.9.1 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_aurora_master"></a> [aurora\_master](#module\_aurora\_master) | terraform-aws-modules/rds-aurora/aws | 9.16.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/db_subnet_group) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/3.9.1/docs/resources/password) | resource |
| [aws_rds_engine_version.postgresql](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/rds_engine_version) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | S3 bucket holding the Terraform state of the base stack (set TF\_VAR\_state\_bucket in .env) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | The db subnet group name |
<!-- END_TF_DOCS -->
