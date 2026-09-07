resource "aws_ecs_cluster" "main" {
  name = "order-saga-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

locals {
  service_configs = {
    producer = {
      repository_name = "order-saga-producer"
      image_tag       = "latest"
      port            = var.app_port_producer
      target_group    = aws_lb_target_group.producer.arn
      cpu             = 256
      memory          = 512
      env = {
        DB_HOST = aws_db_instance.main.address
        DB_PORT = "5432"
        DB_NAME = "order_db"
        MQ_HOST = "${aws_instance.mq.private_ip}"
        MQ_PORT = "1414"
      }
    }
    inventory = {
      repository_name = "order-saga-inventory"
      image_tag       = "latest"
      port            = var.app_port_inventory
      target_group    = aws_lb_target_group.inventory.arn
      cpu             = 256
      memory          = 512
      env = {
        DB_HOST = aws_db_instance.main.address
        DB_PORT = "5432"
        DB_NAME = "inventory_db"
        MQ_HOST = "${aws_instance.mq.private_ip}"
        MQ_PORT = "1414"
      }
    }
    payment = {
      repository_name = "order-saga-payment"
      image_tag       = "latest"
      port            = var.app_port_payment
      target_group    = aws_lb_target_group.payment.arn
      cpu             = 256
      memory          = 512
      env = {
        DB_HOST = aws_db_instance.main.address
        DB_PORT = "5432"
        DB_NAME = "payment_db"
        MQ_HOST = "${aws_instance.mq.private_ip}"
        MQ_PORT = "1414"
      }
    }
    notification = {
      repository_name = "order-saga-notification"
      image_tag       = "latest"
      port            = var.app_port_notification
      target_group    = aws_lb_target_group.notification.arn
      cpu             = 256
      memory          = 512
      env = {
        DB_HOST = aws_db_instance.main.address
        DB_PORT = "5432"
        DB_NAME = "notification_db"
        MQ_HOST = "${aws_instance.mq.private_ip}"
        MQ_PORT = "1414"
      }
    }
  }
}

resource "aws_ecs_task_definition" "service" {
  for_each = local.service_configs

  family                   = "order-saga-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(each.value.cpu)
  memory                   = tostring(each.value.memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${each.value.repository_name}:${each.value.image_tag}"
      essential = true
      portMappings = [{
        containerPort = each.value.port
        hostPort      = each.value.port
        protocol      = "tcp"
      }]
      environment = [
        for k, v in each.value.env : {
          name  = k
          value = v
        }
      ]
      secrets = [
        {
          name      = "DB_USERNAME"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/order-saga/POSTGRES_USER"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/order-saga/POSTGRES_PASSWORD"
        },
        {
          name      = "MQ_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/order-saga/MQ_PASSWORD"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/order-saga-${each.key}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "services" {
  for_each = local.service_configs

  name              = "/ecs/order-saga-${each.key}"
  retention_in_days = 7
}

resource "aws_security_group" "ecs_tasks" {
  name        = "order-saga-ecs-task-sg"
  description = "Allow ECS tasks to receive traffic from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "service" {
  for_each = local.service_configs

  name            = "order-saga-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.service[each.key].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = each.value.target_group
    container_name   = "app"
    container_port   = each.value.port
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    ignore_changes = [desired_count]
  }
}
