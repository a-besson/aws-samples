# Root-account administrator statement is the AWS-documented baseline for every KMS key
# policy (a key with no root grant can permanently lock the account out of its own key);
# kms:* is scoped to this account's root principal only, not a public/anonymous wildcard.
# kics-scan ignore-block
resource "aws_kms_key" "logs" {
  description         = "CMK for CloudWatch Logs encryption - ${local.name}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.logs_kms.json
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${local.name}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

data "aws_iam_policy_document" "logs_kms" {
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
    sid    = "AllowCloudWatchLogs"
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
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
