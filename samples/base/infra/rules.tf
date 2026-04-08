
# AWS Config Rule to check if access keys are rotated within specified timeframe
resource "aws_config_config_rule" "access_keys_rotated" {
  name = "access-keys-rotated"

  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }

  input_parameters = jsonencode({
    maxAccessKeyAge = "90"
  })

  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }
}

# AWS Config Rule to check if security group allows restricted incoming traffic
resource "aws_config_config_rule" "restricted_incoming_traffic" {
  name = "vpc-sg-open-only-to-authorized-ports"

  source {
    owner             = "AWS"
    source_identifier = "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  }

  input_parameters = jsonencode({
    authorizedTcpPorts = "443"
    authorizedUdpPorts = "443"
  })

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }
}
