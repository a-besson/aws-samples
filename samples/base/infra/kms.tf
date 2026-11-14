# The only customer managed key of the samples: every stack encrypts with it, through the `kms_key_arn` output.
# The default policy gives the account full access through IAM (RDS, MSK, Secrets Manager use it via grants created
# by the caller); the services below write with their own principal and need a statement of their own.
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  description             = "Customer managed key shared by the aws-samples stacks"
  aliases                 = ["lab-samples"]
  enable_key_rotation     = true
  deletion_window_in_days = 7

  key_statements = [
    {
      # Every encrypted log group of the account, in this region (CloudWatch Logs needs the key policy, not IAM)
      sid       = "CloudWatchLogs"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:Describe*"]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["logs.${var.aws_region}.amazonaws.com"]
      }]
      conditions = [{
        test     = "ArnLike"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
      }]
    },
    {
      # AWS Config delivers to the bucket as its service principal: the recorder role has no S3 write access
      sid       = "AWSConfigDelivery"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["config.amazonaws.com"]
      }]
      conditions = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }]
    },
  ]

  tags = local.tags
}
