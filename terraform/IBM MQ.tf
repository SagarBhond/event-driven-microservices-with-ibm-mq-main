data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  mqsc_content = file("${path.module}/../mq-config/20-queues.mqsc")
}

resource "aws_security_group" "mq" {
  name        = "order-saga-mq-sg"
  description = "Allow IBM MQ access"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 1414
    to_port     = 1414
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  ingress {
    from_port   = 9443
    to_port     = 9443
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

resource "aws_ebs_volume" "mq" {
  availability_zone = aws_subnet.public[0].availability_zone
  size              = 20
  type              = "gp3"

  tags = {
    Name = "order-saga-mq-data"
  }
}

resource "aws_instance" "mq" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mq.id]

  user_data = templatefile("${path.module}/scripts/IBM_MQ_user_data.sh", {
    aws_region    = var.aws_region,
    mqsc_content  = local.mqsc_content,
    mq_password   = aws_ssm_parameter.mq_password.value,
    mq_admin_user = "admin"
  })

  tags = {
    Name = "order-saga-mq"
  }
}

resource "aws_volume_attachment" "mq" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mq.id
  instance_id = aws_instance.mq.id
}
