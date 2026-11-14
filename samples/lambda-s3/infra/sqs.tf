# Dead letter queue: receives the failure record of the asynchronous invocations that exhausted their retries
module "dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.3.1"

  name                      = "${local.name}-dlq"
  kms_master_key_id         = local.states.vpc.kms_key_arn
  message_retention_seconds = 1209600 # 14 days, the maximum
}
