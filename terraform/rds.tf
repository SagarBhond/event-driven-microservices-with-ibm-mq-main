resource "aws_db_subnet_group" "main" {
  name       = "order-saga-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "order-saga-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "order-saga-rds-sg"
  description = "Allow database access from the application and MQ"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
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

resource "aws_db_instance" "main" {
  identifier              = "order-saga-postgres"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "order_db"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0
  deletion_protection     = false

  tags = {
    Name = "order-saga-rds"
  }
}
