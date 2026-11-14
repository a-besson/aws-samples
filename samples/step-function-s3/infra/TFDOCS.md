# infra

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.17.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.100.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.4.2 |
| <a name="requirement_local"></a> [local](#requirement\_local) | 2.9.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.3.2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.11.0 |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 5.12.1 |
| <a name="module_ecs_job"></a> [ecs\_job](#module\_ecs\_job) | terraform-aws-modules/step-functions/aws | 4.2.1 |
| <a name="module_events"></a> [events](#module\_events) | terraform-aws-modules/eventbridge/aws | 3.17.1 |
| <a name="module_events_dlq"></a> [events\_dlq](#module\_events\_dlq) | terraform-aws-modules/sqs/aws | 4.3.1 |
| <a name="module_lambda_map"></a> [lambda\_map](#module\_lambda\_map) | terraform-aws-modules/step-functions/aws | 4.2.1 |
| <a name="module_notification"></a> [notification](#module\_notification) | terraform-aws-modules/s3-bucket/aws//modules/notification | 4.11.0 |
| <a name="module_reader"></a> [reader](#module\_reader) | terraform-aws-modules/lambda/aws | 7.21.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.job](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_task_definition.job](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.job_execution](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role) | resource |
| [aws_iam_role.job_task](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.job_execution_pull_through_cache](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.job_task](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.job_execution](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.job](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/caller_identity) | data source |
| [aws_prefix_list.s3](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/prefix_list) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |
| <a name="input_job_cpu_architecture"></a> [job\_cpu\_architecture](#input\_job\_cpu\_architecture) | CPU architecture of the ECS job (ARM64 is the cheapest on Fargate) | `string` | `"ARM64"` | no |
| <a name="input_job_image"></a> [job\_image](#input\_job\_image) | Image of the ECS job (default: the pinned aws-cli image, through the ECR Public pull through cache of the base stack) | `string` | `null` | no |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | S3 bucket holding the Terraform state of the base stack (set TF\_VAR\_state\_bucket in .env) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Bucket to drop the manifests (manifests/), the files they list (data/) and the job inputs (jobs/) into |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ECS cluster that runs the jobs |
| <a name="output_ecs_job_state_machine_arn"></a> [ecs\_job\_state\_machine\_arn](#output\_ecs\_job\_state\_machine\_arn) | State machine started by a file under jobs/: an ECS Fargate job, awaited and retried |
| <a name="output_events_dlq_url"></a> [events\_dlq\_url](#output\_events\_dlq\_url) | URL of the dead letter queue of the two EventBridge rules |
| <a name="output_lambda_map_state_machine_arn"></a> [lambda\_map\_state\_machine\_arn](#output\_lambda\_map\_state\_machine\_arn) | State machine started by a manifest: a Lambda invocation per listed file, in parallel |
<!-- END_TF_DOCS -->
