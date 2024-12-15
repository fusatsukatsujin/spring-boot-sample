provider "aws" {
  region = "ap-northeast-1"
}

# ECRリポジトリ
resource "aws_ecr_repository" "app" {
  name = "spring-demo-app"
}

# DynamoDB
resource "aws_dynamodb_table" "users" {
  name           = "Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# デフォルトVPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "Default subnet for ap-northeast-1a"
  }
}

# ALB用のセキュリティグループ
resource "aws_security_group" "alb" {
  name        = "spring-demo-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Fargate用のセキュリティグループ
resource "aws_security_group" "ecs_tasks" {
  name        = "spring-demo-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
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