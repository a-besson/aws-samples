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
| [aws_s3_object.data_a](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.data_b](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.job_empty](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.job_ok](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.manifest_missing](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [aws_s3_object.manifest_ok](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/s3_object) | resource |
| [external_external.bucket](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.dlq](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_definition](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_failed](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_failed_submissions](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_ok](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_ok_output](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_rule](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.ecs_job_target](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_definition](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_failed](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_failed_error](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_ok](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_ok_output](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_rule](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |
| [external_external.lambda_map_target](https://registry.terraform.io/providers/hashicorp/external/2.4.2/docs/data-sources/external) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket of the sample under test | `string` | n/a | yes |
| <a name="input_ecs_job_state_machine_arn"></a> [ecs\_job\_state\_machine\_arn](#input\_ecs\_job\_state\_machine\_arn) | State machine of the ECS job, started by a file under jobs/ | `string` | n/a | yes |
| <a name="input_events_dlq_url"></a> [events\_dlq\_url](#input\_events\_dlq\_url) | URL of the dead letter queue of the EventBridge rules | `string` | n/a | yes |
| <a name="input_floci_endpoint"></a> [floci\_endpoint](#input\_floci\_endpoint) | Endpoint of the local Floci emulator | `string` | n/a | yes |
| <a name="input_lambda_map_state_machine_arn"></a> [lambda\_map\_state\_machine\_arn](#input\_lambda\_map\_state\_machine\_arn) | State machine of the Distributed Map, started by a manifest | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket"></a> [bucket](#output\_bucket) | Default encryption of the bucket: algorithm, KMS key and bucket key |
| <a name="output_dlq"></a> [dlq](#output\_dlq) | Message retention (s) and KMS key of the DLQ |
| <a name="output_ecs_job_definition"></a> [ecs\_job\_definition](#output\_ecs\_job\_definition) | Definition of the ECS job state machine, as stored |
| <a name="output_ecs_job_failed_submissions"></a> [ecs\_job\_failed\_submissions](#output\_ecs\_job\_failed\_submissions) | Number of times the ECS task was submitted for the empty file |
| <a name="output_ecs_job_ok_output"></a> [ecs\_job\_ok\_output](#output\_ecs\_job\_ok\_output) | Output of the ECS job execution started by the file the job can read: the task that ran |
| <a name="output_ecs_job_rule"></a> [ecs\_job\_rule](#output\_ecs\_job\_rule) | Event pattern of the rule that starts the ECS job |
| <a name="output_ecs_job_target"></a> [ecs\_job\_target](#output\_ecs\_job\_target) | Target of the jobs rule: ARN, delivery retries, maximum event age (s) and DLQ |
| <a name="output_lambda_map_definition"></a> [lambda\_map\_definition](#output\_lambda\_map\_definition) | Definition of the Distributed Map state machine, as stored |
| <a name="output_lambda_map_failed_error"></a> [lambda\_map\_failed\_error](#output\_lambda\_map\_failed\_error) | Error of the Distributed Map execution started by the manifest that lists a missing file |
| <a name="output_lambda_map_ok_output"></a> [lambda\_map\_ok\_output](#output\_lambda\_map\_ok\_output) | Output of the Distributed Map execution started by the valid manifest |
| <a name="output_lambda_map_rule"></a> [lambda\_map\_rule](#output\_lambda\_map\_rule) | Event pattern of the rule that starts the Distributed Map |
| <a name="output_lambda_map_target"></a> [lambda\_map\_target](#output\_lambda\_map\_target) | Target of the manifests rule: ARN, delivery retries, maximum event age (s) and DLQ |
<!-- END_TF_DOCS -->
