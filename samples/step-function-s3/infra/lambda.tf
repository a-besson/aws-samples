# One invocation per file listed in a manifest, started by the Distributed Map state. The code is packaged from
# ../app/lambdas/manifest_reader (tests excluded). boto3 comes with the runtime.
# No VPC: the function only calls S3, nothing private is joined.
# python3.13 is the newest runtime the pinned aws provider (5.100.0) accepts: python3.14 is rejected by its validation.
module "reader" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.21.1"

  function_name = "${local.name}-reader"
  description   = "Reads one JSON file listed in a manifest"
  handler       = "manifest_reader.handler"
  runtime       = "python3.13"
  architectures = ["arm64"]
  memory_size   = 256
  timeout       = 30

  source_path = [{
    path     = "${path.module}/../app/lambdas/manifest_reader"
    patterns = ["!tests/.*", "!__pycache__/.*"]
  }]

  logging_log_format                = "JSON"
  cloudwatch_logs_retention_in_days = 1
  cloudwatch_logs_kms_key_id        = local.states.vpc.kms_key_arn

  attach_policy_statements = true
  policy_statements = {
    read_data = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.bucket.s3_bucket_arn}/data/*"]
    }
    # The objects are encrypted with the shared key (Floci does not enforce IAM: this follows the AWS documentation)
    shared_key = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [local.states.vpc.kms_key_arn]
    }
  }
}
