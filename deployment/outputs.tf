output "task_definition" {
  value = aws_ecs_task_definition.app
}

output "task_role" {
  value = aws_iam_role.ecs_task_role
}

output "service" {
  value = aws_ecs_service.service
}
