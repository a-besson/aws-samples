locals {
  app_port = 8080
}

# kics-scan ignore-block
resource "aws_security_group" "lb" {
  name        = "cb-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = local.states.vpc.vpc_id

  ingress {
    description = "Allow incoming HTTPS traffic"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # The sample pulls its image and reaches MSK and AWS APIs: egress is left open, ingress is what is restricted.
  #trivy:ignore:AWS-0104:exp:2027-01-31
  egress {
    description = "Outbound all"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#
# Traffic to the ECS cluster should only come from the LB
#
# kics-scan ignore-block
resource "aws_security_group" "ecs_tasks" {
  name        = "cb-ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = local.states.vpc.vpc_id

  ingress {
    description     = "Ingress from the ALB"
    protocol        = "tcp"
    from_port       = local.app_port
    to_port         = local.app_port
    security_groups = [aws_security_group.lb.id]
  }

  # The sample pulls its image and reaches MSK and AWS APIs: egress is left open, ingress is what is restricted.
  #trivy:ignore:AWS-0104:exp:2027-01-31
  egress {
    description = "Outbound all"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
