locals {
  app_port = 8080
}

# This is the internet-facing ALB for the AKHQ UI sample, so a public ingress on the HTTPS
# listener port is the explicit intent, not an oversight. Egress-all is standard for an ALB
# (it only proxies to the target group over HTTPS - see aws_alb_target_group.app).
# kics-scan ignore-block
resource "aws_security_group" "lb" {
  name        = "cb-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = local.states.vpc.vpc_id

  ingress {
    description = "Allow incoming HTTPS traffic (matches the ALB HTTPS listener on 443)"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

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
# Egress-all is required so the AKHQ task can reach the MSK brokers, the ECR/logs VPC
# endpoints and AWS STS (for SASL/IAM auth); ingress is already scoped to the ALB's own
# security group only, so the wider egress does not widen the task's attack surface.
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

  egress {
    description = "Outbound all"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
