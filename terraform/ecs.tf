# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

# FRONTEND
resource "aws_ecs_task_definition" "frontend_taskdef" {
  family                   = "frontend"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role_frontend.arn

  container_definitions = <<EOT
[
  {
    "name": "frontend",
    "image": "${aws_ecr_repository.frontend_repo.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
    "environment": [
      { "name": "NODE_ENV", "value": "production" }
    ],
    "healthCheck": {
      "test": ["CMD-SHELL", "curl -f http://localhost:3000/healthz || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 10
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend_logs.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "frontend"
      }
    },
    "essential": true
  }
]
EOT
}

resource "aws_ecs_service" "frontend_svc" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend_taskdef.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Distribute tasks across AZs
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  # ALB LB config
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  # Deployment config
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_target_group.frontend_tg,
    aws_lb_listener.http_listener
  ]
}

# SERVICE A (gRPC)
resource "aws_ecs_service" "service_a_svc" {
  name            = "service-a-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_a_taskdef.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # Distribute tasks across AZs
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  # ALB LB config
  load_balancer {
    target_group_arn = aws_lb_target_group.service_a_tg.arn
    container_name   = "service_a"
    container_port   = 50051
  }

  # Deployment config
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_target_group.service_a_tg,
    aws_lb_listener.http_listener
  ]
}

resource "aws_ecs_task_definition" "service_a_taskdef" {
  family                   = "service-a"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role_service_a.arn

  container_definitions = <<EOT
[
  {
    "name": "service-a",
    "image": "${aws_ecr_repository.service_a_repo.repository_url}:latest",
    "portMappings": [
      {
        "containerPort": 50051,
        "hostPort": 50051
      }
    ],
    "secrets": [
      {
        "name": "MONGO_URI",
        "valueFrom": "${aws_ssm_parameter.mongodb_uri.arn}"
      }
    ],
    "environment": [
      { "name": "SQS_QUEUE_URL", "value": "${aws_sqs_queue.main_queue.id}" }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.service_a_logs.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "service-a"
      }
    },
    "essential": true
  }
]
EOT
}

# SERVICE B (SQS consumer, no ALB)
resource "aws_ecs_task_definition" "service_b_taskdef" {
  family                   = "service-b"
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role_service_b.arn

  container_definitions = <<EOT
[
  {
    "name": "service-b",
    "image": "${aws_ecr_repository.service_b_repo.repository_url}:latest",
    "secrets": [
      {
        "name": "MONGO_URI",
        "valueFrom": "${aws_ssm_parameter.mongodb_uri.arn}"
      }
    ],
    "environment": [
      { "name": "SQS_QUEUE_URL", "value": "${aws_sqs_queue.main_queue.id}" }
    ],
    "healthCheck": {
      "test": [
        "CMD-SHELL",
        "curl -f http://localhost:8080/healthz || exit 1"
      ],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 10
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.service_b_logs.name}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "service-b"
      }
    },
    "essential": true
  }
]
EOT
}

resource "aws_ecs_service" "service_b_svc" {
  name            = "service-b-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service_b_taskdef.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  # No load_balancer block, as it's purely an SQS consumer
}

