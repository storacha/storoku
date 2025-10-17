output "id" {
  value = aws_globalaccelerator_accelerator.ga.id
}

output "dns_name" {
  value = aws_globalaccelerator_accelerator.ga.dns_name
}

output "hosted_zone_id" {
  value = aws_globalaccelerator_accelerator.ga.hosted_zone_id
}
