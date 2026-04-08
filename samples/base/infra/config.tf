
# AWS Config Recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  name     = "config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }

  recording_mode {
    recording_frequency = "CONTINUOUS"
  }
}

# Enable Config Recorder
resource "aws_config_configuration_recorder_status" "config_recorder_status" {
  name       = aws_config_configuration_recorder.config_recorder.name
  is_enabled = true
  depends_on = [aws_config_configuration_recorder.config_recorder]
}

resource "aws_config_delivery_channel" "delivery" {
  name           = "delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
  s3_key_prefix  = "config"
  depends_on     = [aws_config_configuration_recorder_status.config_recorder_status]
}

# IAM role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for Config
resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}
