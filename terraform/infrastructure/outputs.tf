output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.users.arn
}

output "subnet_id" {
  value = aws_default_subnet.default_az1.id
}

output "ecs_tasks_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
 
output "vpc_id" {
  value = aws_default_vpc.default.id
}

output "dynamodb_endpoint" {
    # TODO:
  value = "https://dynamodb.ap-northeast-1.amazonaws.com"
}