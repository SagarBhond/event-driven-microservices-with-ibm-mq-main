data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "mq" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "c7i-flex.large"

  # Deploy in public subnet for simple access and no NAT
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.mq.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_mq.name

  key_name = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = 10
    volume_type = "gp3"
    encrypted   = true
  }

  user_data = templatefile("${path.module}/scripts/IBM_MQ_user_data.sh", {
    aws_region   = var.aws_region
    mqsc_content = file("${path.module}/../mq-config/20-queues.mqsc")
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }

  tags = { Name = "order-saga-mq" }
}