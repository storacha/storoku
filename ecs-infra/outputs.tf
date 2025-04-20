output "lb_blue_target_group" {
  value = aws_lb_target_group.blue_target_group
}
output "lb_green_target_group" {
  value = aws_lb_target_group.green_target_group
}

output "lb_listener" {
  value = aws_alb_listener.listener
}

output "lb" {
  value = aws_lb.alb
}

output "lb_security_group" {
  value = aws_security_group.lb
}

output "ecs_cluster" {
  value = aws_ecs_cluster.cluster
}

output "aws_cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.logs
}
