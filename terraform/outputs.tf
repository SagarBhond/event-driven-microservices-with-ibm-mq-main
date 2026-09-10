locals {
  alb_http_url = "http://${aws_lb.main.dns_name}"

  service_urls = {
    producer = {
      api     = "${local.alb_http_url}/api/producer"
      swagger = "${local.alb_http_url}/api/producer/swagger-ui/index.html"
      openapi = "${local.alb_http_url}/api/producer/v3/api-docs"
    }
    inventory = {
      api     = "${local.alb_http_url}/api/inventory"
      swagger = "${local.alb_http_url}/api/inventory/swagger-ui/index.html"
      openapi = "${local.alb_http_url}/api/inventory/v3/api-docs"
    }
    payment = {
      api     = "${local.alb_http_url}/api/payment"
      swagger = "${local.alb_http_url}/api/payment/swagger-ui/index.html"
      openapi = "${local.alb_http_url}/api/payment/v3/api-docs"
    }
    notification = {
      api     = "${local.alb_http_url}/api/notification"
      swagger = "${local.alb_http_url}/api/notification/swagger-ui/index.html"
      openapi = "${local.alb_http_url}/api/notification/v3/api-docs"
    }
  }
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "api_base_url" {
  description = "Base URL for the order saga APIs"
  value       = local.alb_http_url
}

output "producer_api_url" {
  value = local.service_urls.producer.api
}

output "inventory_api_url" {
  value = local.service_urls.inventory.api
}

output "payment_api_url" {
  value = local.service_urls.payment.api
}

output "notification_api_url" {
  value = local.service_urls.notification.api
}

output "producer_swagger_url" {
  value = local.service_urls.producer.swagger
}

output "inventory_swagger_url" {
  value = local.service_urls.inventory.swagger
}

output "payment_swagger_url" {
  value = local.service_urls.payment.swagger
}

output "notification_swagger_url" {
  value = local.service_urls.notification.swagger
}

output "producer_openapi_url" {
  value = local.service_urls.producer.openapi
}

output "inventory_openapi_url" {
  value = local.service_urls.inventory.openapi
}

output "payment_openapi_url" {
  value = local.service_urls.payment.openapi
}

output "notification_openapi_url" {
  value = local.service_urls.notification.openapi
}

output "mq_private_ip" {
  description = "The internal IP address of the IBM MQ instance"
  value       = aws_instance.mq.private_ip
}

output "mq_public_ip" {
  description = "The public IP address of the IBM MQ instance (for Admin Console access)"
  value       = aws_instance.mq.public_ip
}

output "mq_admin_url" {
  description = "IBM MQ Admin Console URL"
  value       = "https://${aws_instance.mq.public_ip}:9443"
}

output "pgadmin_public_ip" {
  description = "The public IP address of the pgAdmin instance"
  value       = aws_instance.pgadmin.public_ip
}

output "pgadmin_url" {
  description = "pgAdmin Web UI URL"
  value       = "http://${aws_instance.pgadmin.public_ip}:5050"
}

output "rds_endpoint" {
  description = "Endpoint for the shared RDS instance"
  value       = aws_db_instance.rds.endpoint
}

output "monitoring_public_ip" {
  description = "Public IP address of the Grafana, Prometheus, and Loki host"
  value       = aws_instance.pgadmin.public_ip
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${aws_instance.pgadmin.public_ip}:3000"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = "http://${aws_instance.pgadmin.public_ip}:9090"
}

output "loki_url" {
  description = "Loki URL"
  value       = "http://${aws_instance.pgadmin.public_ip}:3100"
}

output "instructions" {
  value = <<EOF
Terraform has provisioned the infrastructure.

Next steps:
1. Ensure your CI/CD pipeline builds the Docker images and pushes them to ECR.
2. Update the ECS Task Definitions via the pipeline with the correct ECR image URIs.
3. API base URL: ${local.alb_http_url}
4. Producer API: ${local.service_urls.producer.api}
5. Inventory API: ${local.service_urls.inventory.api}
6. Payment API: ${local.service_urls.payment.api}
7. Notification API: ${local.service_urls.notification.api}
8. Producer Swagger: ${local.service_urls.producer.swagger}
9. Inventory Swagger: ${local.service_urls.inventory.swagger}
10. Payment Swagger: ${local.service_urls.payment.swagger}
11. Notification Swagger: ${local.service_urls.notification.swagger}
12. Producer OpenAPI JSON: ${local.service_urls.producer.openapi}
13. Inventory OpenAPI JSON: ${local.service_urls.inventory.openapi}
14. Payment OpenAPI JSON: ${local.service_urls.payment.openapi}
15. Notification OpenAPI JSON: ${local.service_urls.notification.openapi}
16. IBM MQ Admin Console: https://${aws_instance.mq.public_ip}:9443
17. pgAdmin Web UI: http://${aws_instance.pgadmin.public_ip}:5050
18. RDS endpoint: ${aws_db_instance.rds.endpoint}
19. Grafana: http://${aws_instance.pgadmin.public_ip}:3000
20. Prometheus: http://${aws_instance.pgadmin.public_ip}:9090
21. Loki: http://${aws_instance.pgadmin.public_ip}:3100
EOF
}