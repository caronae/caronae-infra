variable "cluster_name" {
}

variable "region" {
}

variable "vpc_id" {
}

variable "subnet" {
}

variable "security_group" {
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "caronae-ecs-${var.cluster_name}"
  retention_in_days = "30"
  tags = {
    Workspace = terraform.workspace
  }
}

resource "aws_iam_role" "ecs-service-role" {
  name               = "ecs-service-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs-service-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role       = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

# Service discovery

resource "aws_service_discovery_private_dns_namespace" "default" {
  name = "caronae-ecs-${var.cluster_name}.local"
  vpc  = var.vpc_id
}

# Services

resource "aws_ecs_task_definition" "proxy" {
  family                = "proxy"
  container_definitions = <<DEFINITIONS
[
  {
    "name": "haproxy",
    "image": "caronae/haproxy:latest",
    "cpu": 1,
    "memory": 128,
    "essential": true,
    "environment" : [
      { "name": "BACKEND_SERVICE_DISCOVERY_NAME", "value": "backend.caronae-ecs-${var.cluster_name}.local" }
    ],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "networkMode": "bridge",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.default.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "proxy"
      }
    }
  }
]
DEFINITIONS

}

resource "aws_ecs_service" "proxy" {
  name = "proxy"
  cluster = var.cluster_name
  task_definition = aws_ecs_task_definition.proxy.arn
  desired_count = 1
}

resource "aws_ecs_task_definition" "backend" {
  family = "backend"
  network_mode = "awsvpc"
  container_definitions = <<DEFINITIONS
[
  {
    "name": "backend",
    "image": "nginx",
    "cpu": 1,
    "memory": 128,
    "essential": true,
    "environment" : [
    ],
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.default.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "backend"
      }
    }
  }
]
DEFINITIONS

}

resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  service_registries {
    registry_arn   = aws_service_discovery_service.backend.arn
    container_name = "backend"
  }

  network_configuration {
    subnets         = [var.subnet]
    security_groups = [var.security_group]
  }
}

resource "aws_service_discovery_service" "backend" {
  name = "backend"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.default.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}

