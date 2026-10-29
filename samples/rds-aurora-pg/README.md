# Aurora PostgreSQL Stack

---

## Features

- **Aurora Serverless v2**: Automatic scaling based on application demand.
- **High Availability**: Multi-AZ deployment within the VPC database subnets.
- **Security**: Data encrypted at rest, IAM database authentication enabled.
- **Integration**: Pre-configured security groups for VPC-native access.

## Quick Start

```bash
# Initialize (needs TF_VAR_state_bucket in the root .env) and apply, from the repository root
task rds-aurora-pg:init
task rds-aurora-pg:apply

# Destroy
task rds-aurora-pg:destroy
```

---
The sample Lambda in `app/lambdas/sample-rds-iam-auth` reads the cluster endpoint from the `DB_HOSTNAME` environment
variable; set it from the `cluster_endpoint` of your own deployment.

## Tests

```bash
# terraform test on a throwaway Floci container (fake credentials, no AWS account), from the repository root
task rds-aurora-pg:test
```

The test applies the stack on the emulator (`infra/tests/floci.tftest.hcl`); the gaps of the emulator are mocked in the
test file with the reason as a comment. CI runs it on every pull request (`build-rds-aurora-pg`).

## Task commands

| Command | Description |
|---|---|
| `task rds-aurora-pg:init` | Initialize Terraform with the shared S3 state bucket |
| `task rds-aurora-pg:plan` | Plan the changes |
| `task rds-aurora-pg:apply` | Apply the changes |
| `task rds-aurora-pg:destroy` | Destroy the resources |
| `task rds-aurora-pg:test` | `terraform test` on Floci |
| `task rds-aurora-pg:docs` | Regenerate the Terraform documentation |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.4 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.82.2 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aurora_master"></a> [aurora\_master](#module\_aurora\_master) | terraform-aws-modules/rds-aurora/aws | 9.11.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_rds_engine_version.postgresql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_engine_version) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | The db subnet group name |
<!-- END_TF_DOCS -->
