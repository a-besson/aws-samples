# Three trade-offs accepted for this lab/demo ALB, not production defaults:
# - enable_deletion_protection = false: must stay destroyable via `task destroy` without a
#   manual protection-removal step first.
# - No access logging and no WAF: both need extra resources (an access-log S3 bucket, a
#   aws_wafv2_web_acl + association) and WAF has an ongoing cost; tracked as follow-up
#   hardening rather than added silently - see the run report for the cost/security trade-off.
# kics-scan ignore-block
resource "aws_alb" "main" {
  name            = "lb"
  subnets         = local.states.vpc.subnets_public_ids
  security_groups = [aws_security_group.lb.id]

  enable_deletion_protection = false
  drop_invalid_header_fields = true

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
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
  tags = local.tags
}
