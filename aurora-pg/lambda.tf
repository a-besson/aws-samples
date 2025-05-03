#
# Lambda python IAM auth sample
#

/* module "lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "sample-rds-iam-auth"
  description   = "Sample rds iam auth lambda"
  handler       = "index.lambda_handler"
  runtime       = "python3.13"

  source_path = "${path.module}/lambdas/sample-rds-iam-auth"

  vpc_subnet_ids                     = local.states.vpc.subnets_database_ids
  vpc_security_group_ids             = [aws_security_group.lambda.id]
  attach_network_policy              = true
  replace_security_groups_on_destroy = true
  replacement_security_group_ids     = [aws_security_group.lambda.id]

  layers = [
    aws_lambda_layer_version.lambda_layer.arn
  ]
}

resource "aws_security_group" "lambda" {
  description = "Allow access to Aurora"
  vpc_id      = local.states.vpc.vpc_id
  
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} */