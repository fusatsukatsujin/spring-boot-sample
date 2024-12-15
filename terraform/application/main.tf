provider "aws" {
  region = "ap-northeast-1"
}

data "terraform_remote_state" "infrastructure" {
  backend = "local"
  config = {
    path = "../infrastructure/terraform.tfstate"
  }
}

# ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "spring-demo-cluster"
}

# ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "spring-demo-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 各種IAMポリシー
resource "aws_iam_role_policy" "policies" {
  name = "ecs-task-policies"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Resource = data.terraform_remote_state.infrastructure.outputs.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECSタスク定義とサービス
resource "aws_ecs_task_definition" "app" {
  family                   = "spring-demo-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "app"
      image = "${data.terraform_remote_state.infrastructure.outputs.ecr_repository_url}:latest"
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "prod"
        },
        {
          name  = "DYNAMODB_ENDPOINT"
          value = data.terraform_remote_state.infrastructure.outputs.dynamodb_endpoint
        }
      ]
    }
  ])
}

# ECSサービスを更新
resource "aws_ecs_service" "app" {
  name            = "spring-demo-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.terraform_remote_state.infrastructure.outputs.subnet_id]
    security_groups  = [data.terraform_remote_state.infrastructure.outputs.ecs_tasks_security_group_id]
    assign_public_ip = true
  }
} 