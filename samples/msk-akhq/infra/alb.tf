resource "aws_alb" "main" {
  name            = "lb"
  subnets         = local.states.vpc.subnets_public_ids
  security_groups = [aws_security_group.lb.id]

  # kics-scan ignore-line
  enable_deletion_protection = false

  # kics-scan ignore-line
  drop_invalid_header_fields = false

  tags = local.tags
}

resource "aws_alb_target_group" "app" {
  name        = "lb-target-group"
  port        = local.app_port
  protocol    = "HTTPS"
  vpc_id      = local.states.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
  tags = local.tags
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:eu-west-3:637423225169:certificate/dc9a9379-8e80-43c1-80c4-0bf83991091d"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
  tags = local.tags
}
