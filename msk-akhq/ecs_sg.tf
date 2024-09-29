locals {
  app_port = 8080
}

# kics-scan ignore-block
resource "aws_security_group" "lb" {
  name        = "cb-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = local.states.vpc.vpc_id

  ingress {
    description = "Allow incoming HTTP traffic"
    protocol    = "tcp"
    from_port   = local.app_port
    to_port     = local.app_port
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
