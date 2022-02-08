output "external_id" {
  value = random_uuid.external_id.result
}

output "role_arn" {
  value = aws_iam_role.optix.arn
}

output "role_name" {
  value = aws_iam_role.optix.name
}