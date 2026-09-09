output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "api_base_url" {
  description = "Base URL for the order saga APIs"
  value       = "http://${aws_lb.main.dns_name}"
}

output "producer_api_url" {
  value = "http://${aws_lb.main.dns_name}/api/producer"
}

output "inventory_api_url" {
  value = "http://${aws_lb.main.dns_name}/api/inventory"
}

output "payment_api_url" {
  value = "http://${aws_lb.main.dns_name}/api/payment"
}

output "notification_api_url" {
  value = "http://${aws_lb.main.dns_name}/api/notification"
}

output "producer_swagger_url" {
  value = "http://${aws_lb.main.dns_name}/api/producer/swagger-ui/index.html"
}

output "inventory_swagger_url" {
  value = "http://${aws_lb.main.dns_name}/api/inventory/swagger-ui/index.html"
}

output "payment_swagger_url" {
  value = "http://${aws_lb.main.dns_name}/api/payment/swagger-ui/index.html"
}

output "notification_swagger_url" {
  value = "http://${aws_lb.main.dns_name}/api/notification/swagger-ui/index.html"
}

output "producer_openapi_url" {
  value = "http://${aws_lb.main.dns_name}/api/producer/v3/api-docs"
}

output "inventory_openapi_url" {
  value = "http://${aws_lb.main.dns_name}/api/inventory/v3/api-docs"
}

output "payment_openapi_url" {
  value = "http://${aws_lb.main.dns_name}/api/payment/v3/api-docs"
}

output "notification_openapi_url" {
  value = "http://${aws_lb.main.dns_name}/api/notification/v3/api-docs"
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

output "instructions" {
  value = <<EOF
Terraform has provisioned the infrastructure.

Next steps:
1. Ensure your CI/CD pipeline builds the Docker images and pushes them to ECR.
2. Update the ECS Task Definitions via the pipeline with the correct ECR image URIs.
3. API base URL: http://${aws_lb.main.dns_name}
4. Producer API: http://${aws_lb.main.dns_name}/api/producer
5. Inventory API: http://${aws_lb.main.dns_name}/api/inventory
6. Payment API: http://${aws_lb.main.dns_name}/api/payment
7. Notification API: http://${aws_lb.main.dns_name}/api/notification
8. Producer Swagger: http://${aws_lb.main.dns_name}/api/producer/swagger-ui/index.html
9. Inventory Swagger: http://${aws_lb.main.dns_name}/api/inventory/swagger-ui/index.html
10. Payment Swagger: http://${aws_lb.main.dns_name}/api/payment/swagger-ui/index.html
11. Notification Swagger: http://${aws_lb.main.dns_name}/api/notification/swagger-ui/index.html
12. Producer OpenAPI JSON: http://${aws_lb.main.dns_name}/api/producer/v3/api-docs
13. Inventory OpenAPI JSON: http://${aws_lb.main.dns_name}/api/inventory/v3/api-docs
14. Payment OpenAPI JSON: http://${aws_lb.main.dns_name}/api/payment/v3/api-docs
15. Notification OpenAPI JSON: http://${aws_lb.main.dns_name}/api/notification/v3/api-docs
16. IBM MQ Admin Console: https://${aws_instance.mq.public_ip}:9443
17. pgAdmin Web UI: http://${aws_instance.pgadmin.public_ip}:5050
18. RDS endpoint: ${aws_db_instance.rds.endpoint}
EOF
}