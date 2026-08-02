#
# IAM Access Analyzer - detects resources shared with an external principal
# (S3 buckets, IAM roles, KMS keys, ...) across the account.
#
resource "aws_accessanalyzer_analyzer" "account" {
  analyzer_name = "${local.name}-analyzer"
  type          = "ACCOUNT"

  tags = local.tags
}
