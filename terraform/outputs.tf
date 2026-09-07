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
