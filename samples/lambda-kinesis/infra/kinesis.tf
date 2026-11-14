# Provisioned mode with one shard: the cheapest at rest (a shard-hour is billed as soon as the stream exists), and
# plenty for a sample. Encrypted with the shared key of the base stack.
resource "aws_kinesis_stream" "events" {
  name             = local.name
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = local.states.vpc.kms_key_arn

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}
