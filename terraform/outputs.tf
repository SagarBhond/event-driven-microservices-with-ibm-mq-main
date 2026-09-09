output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "mq_public_ip" {
  description = "Public IP of the IBM MQ EC2 instance"
  value       = aws_instance.mq.public_ip
}

output "mq_private_ip" {
  description = "Private IP of the IBM MQ EC2 instance"
  value       = aws_instance.mq.private_ip
}

output "pgadmin_public_ip" {
  description = "Public IP of the pgAdmin EC2 instance"
  value       = aws_instance.pgadmin.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint for PostgreSQL"
  value       = aws_db_instance.main.address
}

output "health_urls" {
  description = "Application health URLs checked after deployment"
  value = {
    producer     = "http://${aws_lb.main.dns_name}/api/producer/health"
    inventory    = "http://${aws_lb.main.dns_name}/api/inventory/health"
    payment      = "http://${aws_lb.main.dns_name}/api/payment/health"
    notification = "http://${aws_lb.main.dns_name}/api/notification/health"
  }
}

output "inventory_swagger_url" {
  description = "Inventory service Swagger UI"
  value       = "http://${aws_lb.main.dns_name}/swagger-ui/index.html"
}

output "mq_console_url" {
  description = "IBM MQ Web Console"
  value       = "https://${aws_instance.mq.public_ip}:9443/ibmmq/console"
}

output "postgres_endpoint" {
  description = "PostgreSQL RDS endpoint and port"
  value       = "${aws_db_instance.main.address}:5432"
}
