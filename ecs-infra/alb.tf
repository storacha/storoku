resource "aws_lb" "alb" {
  #checkov:skip=CKV_AWS_91: Access logging is disabled since this is non-prod.
  #checkov:skip=CKV2_AWS_20: This is disabled since this is non-prod.
  #checkov:skip=CKV2_AWS_28: This is disabled since this is non-prod.
  name                       = "${var.environment}-${var.app}-alb"
  load_balancer_type         = "application"
  subnets                    = var.vpc.subnet_ids.public
  idle_timeout               = 60
  security_groups            = [aws_security_group.lb.id]
  internal                   = false
  enable_deletion_protection = true
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "blue_target_group" {
  name        = "${var.environment}-${var.app}-blue"
  port        = var.httpport
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc.id
  health_check {
    matcher = "200,301,302,404"
    path    = "/healthcheck"
  }
}

resource "aws_lb_target_group" "green_target_group" {
  name        = "${var.environment}-${var.app}-green"
  port        = var.httpport
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc.id
  health_check {
    matcher = "200,301,302,404"
    path    = "/healthcheck"
  }
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_target_group.arn
  }
  lifecycle {
    ignore_changes = [default_action]
  }
}

resource "aws_lb_listener" "redirect_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol = "HTTPS"
      port     = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "lb" {
  name        = "${var.environment}-${var.app}-lb-sg"
  description = "allow inbound traffic"
  vpc_id      = var.vpc.id
  tags = {
    "Name" = "${var.environment}-${var.app}-lb-sg"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}