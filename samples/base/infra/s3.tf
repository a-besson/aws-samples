#
# AWS Config bucket
#

# Server access logging is intentionally not enabled here: it needs a second bucket to
# receive the logs (S3 access-log delivery only supports SSE-S3, not the SSE-KMS this bucket
# uses for its own objects), and this bucket already only stores AWS Config snapshots - an
# audit trail in its own right. Tracked as a follow-up hardening item, not added silently.
# kics-scan ignore-block
# Create S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "aws-config-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block every public access vector on the Config bucket (referentiel_cybersecurite: S3
# public access block is a systematic control).
resource "aws_s3_bucket_public_access_block" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt at rest with a customer-managed key instead of the SSE-S3 default.
resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# Root-account administrator statement is the AWS-documented baseline for every KMS key
# policy (a key with no root grant can permanently lock the account out of its own key);
# kms:* is scoped to this account's root principal only, not a public/anonymous wildcard.
# kics-scan ignore-block
resource "aws_kms_key" "s3" {
  description         = "CMK for S3 bucket encryption - ${local.name}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_kms.json
  tags                = local.tags
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# Root-account administrator statement is the AWS-documented baseline for every KMS key
# policy (a key with no root grant can permanently lock the account out of its own key);
# kms:* is scoped to this account's root principal only, not a public/anonymous wildcard.
# kics-scan ignore-block
data "aws_iam_policy_document" "s3_kms" {
  statement {
    sid       = "AllowRootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

# S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
