# e2e

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.17.2 |
| <a name="requirement_external"></a> [external](#requirement\_external) | 2.4.2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_external"></a> [external](#provider\_external) | 2.4.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [terraform_data.record_ok](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.record_poison](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [external_external.dead_letter](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.dlq](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.function](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.item](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.mapping](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.stream](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.table](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_dlq_url"></a> [dlq\_url](#input\_dlq\_url) | URL of the dead letter queue of the sample under test | `string` | n/a | yes |
| <a name="input_floci_endpoint"></a> [floci\_endpoint](#input\_floci\_endpoint) | Endpoint of the local Floci emulator | `string` | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Lambda function of the sample under test | `string` | n/a | yes |
| <a name="input_stream_name"></a> [stream\_name](#input\_stream\_name) | Kinesis stream of the sample under test | `string` | n/a | yes |
| <a name="input_table_name"></a> [table\_name](#input\_table\_name) | DynamoDB table of the sample under test | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dead_letter"></a> [dead\_letter](#output\_dead\_letter) | Failure record received by the DLQ for the invalid record |
| <a name="output_dlq"></a> [dlq](#output\_dlq) | Message retention (s) and KMS key of the DLQ |
| <a name="output_function"></a> [function](#output\_function) | Runtime, architecture, memory (MB) and timeout (s) of the function |
| <a name="output_item"></a> [item](#output\_item) | Id and payload of the event stored for evt-ok |
| <a name="output_mapping"></a> [mapping](#output\_mapping) | Event source mapping: starting position, batch size, batching window (s), retries, record age (s), bisect, response type and failure destination |
| <a name="output_stream"></a> [stream](#output\_stream) | Stream mode, shards, retention (hours), encryption type and KMS key |
| <a name="output_table"></a> [table](#output\_table) | Partition key, billing mode, encryption type and KMS key of the table |
<!-- END_TF_DOCS -->
