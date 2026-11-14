# acm

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.17.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.100.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.4.2 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.4.2 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/5.100.0/docs/resources/acm_certificate) | resource |
| [tls_private_key.this](https://registry.terraform.io/providers/hashicorp/tls/4.4.2/docs/resources/private_key) | resource |
| [tls_self_signed_cert.this](https://registry.terraform.io/providers/hashicorp/tls/4.4.2/docs/resources/self_signed_cert) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the imported certificate |
<!-- END_TF_DOCS -->
