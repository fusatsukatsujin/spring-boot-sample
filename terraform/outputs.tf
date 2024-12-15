output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.users.name
} 