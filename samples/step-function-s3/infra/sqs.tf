# Dead letter queue of the two rules: the events that could not start a state machine after their retries
module "events_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.3.1"

  name                      = "${local.name}-events-dlq"
  kms_master_key_id         = local.states.vpc.kms_key_arn
  message_retention_seconds = 1209600 # 14 days, the maximum

  # EventBridge sends with its own principal: only from the two rules of this sample. It also needs the key policy of the
  # base stack to allow events.amazonaws.com (statement EventBridgeDeadLetter)
  create_queue_policy = true
  queue_policy_statements = {
    eventbridge = {
      sid     = "EventBridgeDeadLetter"
      actions = ["sqs:SendMessage"]
      principals = [{
        type        = "Service"
        identifiers = ["events.amazonaws.com"]
      }]
      conditions = [{
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = values(module.events.eventbridge_rule_arns)
      }]
    }
  }
}
