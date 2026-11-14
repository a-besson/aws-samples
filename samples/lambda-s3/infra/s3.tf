# Bucket of the sample: the objects dropped under incoming/ trigger the function, which writes under processed/
# False positive: the bucket is encrypted with the customer managed key of the base stack, but Trivy cannot resolve a
# remote state output through the module (the e2e test reads the default encryption back from the emulator).
#trivy:ignore:AWS-0132:exp:2027-01-31
module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket        = "${local.name}-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # lab bucket; also what lets the tests clean up

  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  attach_deny_insecure_transport_policy = true

  # Shared key of the samples; the bucket key keeps the KMS requests (and their cost) low
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = local.states.vpc.kms_key_arn
      }
      bucket_key_enabled = true
    }
  }

  # FinOps: a lab bucket keeps nothing for long
  lifecycle_rule = [{
    id                                     = "expire-after-7-days"
    enabled                                = true
    expiration                             = { days = 7 }
    abort_incomplete_multipart_upload_days = 1
  }]
}

# One notification per bucket: it replaces the whole notification configuration of the bucket. The submodule also
# creates the permission of S3 to invoke the function, and the notification waits for it.
module "notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "4.11.0"

  bucket = module.bucket.s3_bucket_id

  lambda_notifications = {
    reader = {
      function_arn   = module.reader.lambda_function_arn
      function_name  = module.reader.lambda_function_name
      events         = ["s3:ObjectCreated:*"]
      filter_prefix  = "incoming/"
      filter_suffix  = ".json"
      source_account = data.aws_caller_identity.current.account_id # confused deputy: only this account's bucket
    }
  }
}
