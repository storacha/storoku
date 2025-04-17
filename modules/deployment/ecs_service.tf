resource "aws_ecs_service" "service" {
  name                 = "${var.environment}-${var.app}-service"
  cluster              = var.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.app.arn
  desired_count        = var.config.service_min
  force_new_deployment = true
  load_balancer {
    target_group_arn = var.lb_blue_target_group.arn
    container_name   = "first"
    container_port   = "8080" # Application Port
  }
  launch_type = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.container_sg.id]
    subnets          = var.vpc.subnet_ids.private
    assign_public_ip = false
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  lifecycle {
    ignore_changes = [load_balancer, task_definition, desired_count]
  }
}

resource "aws_security_group" "container_sg" {
  name        = "${var.environment}-${var.app}-container-sg"
  description = "allow inbound traffic to the containers"
  vpc_id      = var.vpc.id
  tags = {
    "Name" = "${var.environment}-${var.app}-container-sg"
  }

  egress {
    from_port         = 0
    to_port           = 65535
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    security_groups = [var.lb_security_group.id]
    from_port                = 8080
    to_port                  = 8080
    protocol                 = "tcp"
  }
}

resource "aws_appautoscaling_target" "dev_to_target" {
  max_capacity = var.config.service_max
  min_capacity = var.config.service_min
  resource_id = "service/${var.ecs_cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "dev_to_memory" {
  name               = "dev-to-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dev_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dev_to_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dev_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
  }
}

resource "aws_appautoscaling_policy" "dev_to_cpu" {
  name = "dev-to-cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.dev_to_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dev_to_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.dev_to_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
}