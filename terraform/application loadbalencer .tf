resource "aws_security_group" "alb" {
  name        = "order-saga-alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_lb" "main" {
  name               = "order-saga-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "order-saga-alb"
  }
}

resource "aws_lb_target_group" "producer" {
  name        = "order-saga-producer-tg"
  port        = var.app_port_producer
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/api/producer/health"
    matcher  = "200"
    port     = var.app_port_producer
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "inventory" {
  name        = "order-saga-inventory-tg"
  port        = var.app_port_inventory
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/api/inventory/health"
    matcher  = "200"
    port     = var.app_port_inventory
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "payment" {
  name        = "order-saga-payment-tg"
  port        = var.app_port_payment
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/api/payment/health"
    matcher  = "200"
    port     = var.app_port_payment
    protocol = "HTTP"
  }
}

resource "aws_lb_target_group" "notification" {
  name        = "order-saga-notification-tg"
  port        = var.app_port_notification
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled  = true
    path     = "/api/notification/health"
    matcher  = "200"
    port     = var.app_port_notification
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "producer" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer.arn
  }

  condition {
    path_pattern {
      values = ["/api/producer/*"]
    }
  }
}

resource "aws_lb_listener_rule" "inventory" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory.arn
  }

  condition {
    path_pattern {
      values = ["/api/inventory/*"]
    }
  }
}

resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }

  condition {
    path_pattern {
      values = ["/api/payment/*"]
    }
  }
}

resource "aws_lb_listener_rule" "notification" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 130

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.notification.arn
  }

  condition {
    path_pattern {
      values = ["/api/notification/*"]
    }
  }
}

resource "aws_lb_listener_rule" "inventory_swagger" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory.arn
  }

  condition {
    path_pattern {
      values = ["/swagger-ui/*"]
    }
  }
}

resource "aws_lb_listener_rule" "inventory_openapi" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 210

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory.arn
  }

  condition {
    path_pattern {
      values = ["/v3/api-docs", "/v3/api-docs/*"]
    }
  }
}
