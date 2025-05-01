output "task_definition" {
  value = aws_ecs_task_definition.app
}

output "service" {
  value = aws_ecs_service.service
}