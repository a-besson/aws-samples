# ECS Service Stack

---

## Features

- **ECS Cluster**: Managed cluster using Fargate for serverless container execution.
- **Service Definition**: Pre-configured ECS service with task definitions and networking.
- **Fargate Capacity Providers**: Optimized for cost and performance.
- **CloudWatch Logging**: Automated log group creation and retention.

## Quick Start

```bash
# Initialize (needs TF_VAR_state_bucket in the root .env) and apply, from the repository root
task ecs-service:init
task ecs-service:apply

# Destroy
task ecs-service:destroy
```

---
## Tests

```bash
# terraform test on a throwaway Floci container (fake credentials, no AWS account), from the repository root
task ecs-service:test
```

The test applies the stack on the emulator (`infra/tests/floci.tftest.hcl`); the gaps of the emulator are mocked in the
test file with the reason as a comment. CI runs it on every pull request (`build-ecs-service`).

## Task commands

| Command | Description |
|---|---|
| `task ecs-service:init` | Initialize Terraform with the shared S3 state bucket |
| `task ecs-service:plan` | Plan the changes |
| `task ecs-service:apply` | Apply the changes |
| `task ecs-service:destroy` | Destroy the resources |
| `task ecs-service:test` | `terraform test` on Floci |
| `task ecs-service:docs` | Regenerate the Terraform documentation |

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 5.11.4 |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | 5.11.4 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
