# msk-akhq

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
| <a name="module_msk_cluster"></a> [msk\_cluster](#module\_msk\_cluster) | terraform-aws-modules/msk-kafka-cluster/aws | 2.13.1 |
| <a name="module_security_group"></a> [security\_group](#module\_security\_group) | terraform-aws-modules/security-group/aws | 5.3.1 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_alb.main](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/alb) | resource |
| [aws_alb_listener.front_end](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/alb_listener) | resource |
| [aws_alb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/alb_target_group) | resource |
| [aws_appautoscaling_policy.down](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_policy.up](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.target](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.ecs_log](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.app](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.ecs_service](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.ecs_task_app](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs_auto_scale_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role) | resource |
| [aws_iam_role.task_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_auto_scale_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/security_group) | resource |
| [aws_security_group.lb](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/security_group) | resource |
| [random_password.akhq_admin](https://registry.terraform.io/providers/hashicorp/random/3.9.1/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.ecs_auto_scale_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_msk_policy](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_task_policy](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/data-sources/iam_policy_document) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ARN of the ACM certificate of the HTTPS listener (set TF\_VAR\_acm\_certificate\_arn in .env) | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `"default"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS target region | `string` | `"eu-west-3"` | no |
| <a name="input_state_bucket"></a> [state\_bucket](#input\_state\_bucket) | S3 bucket holding the Terraform state of the base stack (set TF\_VAR\_state\_bucket in .env) | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_akhq_admin_password"></a> [akhq\_admin\_password](#output\_akhq\_admin\_password) | AKHQ admin password (terraform output -raw akhq\_admin\_password) |
| <a name="output_alb_hostname"></a> [alb\_hostname](#output\_alb\_hostname) | ALB hostname |
| <a name="output_msk_bootstrap"></a> [msk\_bootstrap](#output\_msk\_bootstrap) | MSK bootstrap brokers |
| <a name="output_msk_bootstrap_iam"></a> [msk\_bootstrap\_iam](#output\_msk\_bootstrap\_iam) | MSK bootstrap brokers SASL IAM |
<!-- END_TF_DOCS -->
