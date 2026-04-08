
resource "aws_config_remediation_configuration" "remediation_sg" {
  config_rule_name           = aws_config_config_rule.restricted_incoming_traffic.name
  resource_type              = "AWS::EC2::SecurityGroup"
  target_type                = "SSM_DOCUMENT"
  target_id                  = "AWS-CloseSecurityGroup"
  automatic                  = true
  maximum_automatic_attempts = 2
  retry_attempt_seconds      = 60

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.ssm_role.arn
  }
  parameter {
    name           = "SecurityGroupId"
    resource_value = "RESOURCE_ID"
  }
}

# IAM role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for security group management
resource "aws_iam_role_policy" "security_group_policy" {
  name = "security-group-policy"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
      }
    ]
  })
}
