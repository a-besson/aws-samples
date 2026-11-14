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
| [aws_s3_object.ok](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.poison](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [external_external.async_config](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.bucket](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.dead_letter](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.dlq](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.function](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.notification](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.summary](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket of the sample under test | `string` | n/a | yes |
| <a name="input_dlq_url"></a> [dlq\_url](#input\_dlq\_url) | URL of the dead letter queue of the sample under test | `string` | n/a | yes |
| <a name="input_floci_endpoint"></a> [floci\_endpoint](#input\_floci\_endpoint) | Endpoint of the local Floci emulator | `string` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Lambda function of the sample under test | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_async_config"></a> [async\_config](#output\_async\_config) | Retries, maximum event age (s) and failure destination of the asynchronous invocations |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | Default encryption of the bucket: algorithm, KMS key and bucket key |
| <a name="output_dead_letter"></a> [dead\_letter](#output\_dead\_letter) | Failure record received by the DLQ for incoming/poison.json |
| <a name="output_dlq"></a> [dlq](#output\_dlq) | Message retention (s) and KMS key of the DLQ |
| <a name="output_function"></a> [function](#output\_function) | Runtime, architecture, memory (MB) and timeout (s) of the function |
| <a name="output_notification"></a> [notification](#output\_notification) | Event, then the prefix and suffix filters of the S3 notification |
| <a name="output_summary"></a> [summary](#output\_summary) | Summary written by the function for incoming/ok.json |
<!-- END_TF_DOCS -->
