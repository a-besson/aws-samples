locals {
  lambda_map_name = "${local.name}-lambda-map"
  ecs_job_name    = "${local.name}-ecs-job"

  # The ARNs are built from the names: the role of the Distributed Map has to start its own child executions, and the
  # attribute of the state machine would make a cycle with the role the state machine needs
  states_arn = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}"
}

# (A) A manifest dropped under manifests/ lists files; a Distributed Map reads them in parallel, one Lambda per file
module "lambda_map" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "4.2.1"

  name = local.lambda_map_name
  type = "STANDARD"
  definition = templatefile("${path.module}/asl/lambda-map.asl.json", {
    reader_function_arn = module.reader.lambda_function_arn
  })

  logging_configuration                  = { level = "ERROR", include_execution_data = "false" }
  cloudwatch_log_group_retention_in_days = 1
  cloudwatch_log_group_kms_key_id        = local.states.vpc.kms_key_arn

  attach_policy_statements = true
  policy_statements = {
    read_manifest = {
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["${module.bucket.s3_bucket_arn}/manifests/*"]
    }
    invoke_reader = {
      effect    = "Allow"
      actions   = ["lambda:InvokeFunction"]
      resources = [module.reader.lambda_function_arn, "${module.reader.lambda_function_arn}:*"]
    }
    start_child_executions = {
      effect    = "Allow"
      actions   = ["states:StartExecution"]
      resources = ["${local.states_arn}:stateMachine:${local.lambda_map_name}"]
    }
    describe_child_executions = {
      effect    = "Allow"
      actions   = ["states:DescribeExecution"]
      resources = ["${local.states_arn}:execution:${local.lambda_map_name}:*"]
    }
    # The manifest is encrypted with the shared key (Floci does not enforce IAM: this follows the AWS documentation)
    shared_key = {
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [local.states.vpc.kms_key_arn]
    }
  }
}

# (B) A file dropped under jobs/ starts an ECS Fargate job; the state machine waits for it and retries it
module "ecs_job" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "4.2.1"

  name = local.ecs_job_name
  type = "STANDARD"
  definition = templatefile("${path.module}/asl/ecs-job.asl.json", {
    cluster_arn         = module.ecs_cluster.arn
    task_definition_arn = aws_ecs_task_definition.job.arn
    subnet_ids          = jsonencode(local.states.vpc.subnets_private_ids)
    security_group_id   = aws_security_group.job.id
  })

  logging_configuration                  = { level = "ERROR", include_execution_data = "false" }
  cloudwatch_log_group_retention_in_days = 1
  cloudwatch_log_group_kms_key_id        = local.states.vpc.kms_key_arn

  attach_policy_statements = true
  policy_statements = {
    run_task = {
      effect    = "Allow"
      actions   = ["ecs:RunTask"]
      resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.name}-job:*"]
    }
    manage_task = {
      effect    = "Allow"
      actions   = ["ecs:StopTask", "ecs:DescribeTasks"]
      resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${local.name}/*"]
    }
    # `.sync` waits for the task through the managed rule that ECS events are routed with
    wait_for_task = {
      effect    = "Allow"
      actions   = ["events:PutTargets", "events:PutRule", "events:DescribeRule"]
      resources = ["arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"]
    }
    pass_task_roles = {
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [aws_iam_role.job_execution.arn, aws_iam_role.job_task.arn]
      condition = [{
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }]
    }
  }
}
