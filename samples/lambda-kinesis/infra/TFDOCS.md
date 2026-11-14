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
| <a name="module_consumer"></a> [consumer](#module\_consumer) | terraform-aws-modules/lambda/aws | 7.21.1 |
| <a name="module_dlq"></a> [dlq](#module\_dlq) | terraform-aws-modules/sqs/aws | 4.3.1 |
| <a name="module_events_table"></a> [events\_table](#module\_events\_table) | terraform-aws-modules/dynamodb-table/aws | 4.4.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_kinesis_stream.events](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/kinesis_stream) | resource |
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
| <a name="output_dlq_url"></a> [dlq\_url](#output\_dlq\_url) | URL of the dead letter queue that receives the metadata of the failed batches |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Name of the Lambda function that consumes the stream |
| <a name="output_stream_name"></a> [stream\_name](#output\_stream\_name) | Kinesis stream to put the events into |
| <a name="output_table_name"></a> [table\_name](#output\_table\_name) | DynamoDB table holding the processed events (partition key pk = the id of the event) |
<!-- END_TF_DOCS -->
