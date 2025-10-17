
#
# AWS Global Accelerator
#

resource "aws_globalaccelerator_accelerator" "ga" {
  name            = "ga"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "ga" {
  accelerator_arn = aws_globalaccelerator_accelerator.ga.id
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "ga" {
  listener_arn                  = aws_globalaccelerator_listener.ga.id
  health_check_interval_seconds = 30
  health_check_port             = 443
  health_check_protocol         = "TCP"
  threshold_count               = 3
  traffic_dial_percentage       = 100

  endpoint_configuration {
    endpoint_id = var.target_arn
    weight      = 100
  }
}
