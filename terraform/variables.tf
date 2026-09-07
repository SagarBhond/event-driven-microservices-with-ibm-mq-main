variable "aws_region" {
  description = "AWS region for the order-saga deployment"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "your_ip" {
  description = "CIDR allowed to reach admin endpoints such as SSH, MQ console, and pgAdmin"
  type        = string
  default     = "203.0.113.10/32"
}

variable "key_name" {
  description = "Existing EC2 key pair name for SSH access"
  type        = string
  default     = "order-saga-key"
}

variable "app_port_producer" {
  description = "Port for the order producer service"
  type        = number
  default     = 8080
}

variable "app_port_inventory" {
  description = "Port for the inventory service"
  type        = number
  default     = 8081
}

variable "app_port_payment" {
  description = "Port for the payment service"
  type        = number
  default     = 8082
}

variable "app_port_notification" {
  description = "Port for the notification service"
  type        = number
  default     = 8083
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Initial database password. Replace via SSM after apply if needed."
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}
