# Where the consumer stores the events. The conditional put on `pk` makes the processing idempotent: a record delivered
# twice (a retry of its batch) is stored once.
module "events_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.4.0"

  name         = "${local.name}-events"
  hash_key     = "pk"
  billing_mode = "PAY_PER_REQUEST" # nothing is billed at rest

  attributes = [{
    name = "pk"
    type = "S"
  }]

  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = local.states.vpc.kms_key_arn
}
