# e2e

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.17.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.100.0 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.4.2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_object.empty](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.ok](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [external_external.bucket](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.dlq](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.rule](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.stopped_tasks](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.target](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.tasks](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket of the sample under test | `string` | n/a | yes |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ECS cluster of the sample under test | `string` | n/a | yes |
| <a name="input_dlq_url"></a> [dlq\_url](#input\_dlq\_url) | URL of the dead letter queue of the sample under test | `string` | n/a | yes |
| <a name="input_floci_endpoint"></a> [floci\_endpoint](#input\_floci\_endpoint) | Endpoint of the local Floci emulator | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | Default encryption of the bucket: algorithm, KMS key and bucket key |
| <a name="output_dlq"></a> [dlq](#output\_dlq) | Message retention (s) and KMS key of the DLQ |
| <a name="output_rule"></a> [rule](#output\_rule) | Event pattern of the rule that runs the task |
| <a name="output_target"></a> [target](#output\_target) | Target of the rule: cluster, delivery retries, maximum event age (s), DLQ, launch type, task definition and input template |
| <a name="output_tasks"></a> [tasks](#output\_tasks) | One entry per stopped task: starter, BUCKET, KEY and exit code, tab separated |
<!-- END_TF_DOCS -->
