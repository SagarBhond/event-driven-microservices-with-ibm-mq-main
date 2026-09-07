data "aws_ami" "amazon_linux_2023_pgadmin" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "pgadmin" {
  name        = "order-saga-pgadmin-sg"
  description = "Allow pgAdmin access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "pgadmin" {
  ami                    = data.aws_ami.amazon_linux_2023_pgadmin.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[1].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.pgadmin.id]

  user_data = file("${path.module}/scripts/pgadmin_user_data.sh")

  tags = {
    Name = "order-saga-pgadmin"
  }
}
