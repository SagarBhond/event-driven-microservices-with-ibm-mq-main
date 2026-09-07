#!/bin/bash
set -euxo pipefail

yum update -y
amazon-linux-extras enable docker
yum install -y docker
systemctl enable docker
systemctl start docker

if [ ! -e /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

PGADMIN_EMAIL="admin@example.com"
PGADMIN_PASSWORD="$(aws ssm get-parameter --name "/order-saga/MQ_ADMIN_PASSWORD" --with-decryption --region "${aws_region}" --query 'Parameter.Value' --output text)"

docker run -d \
  --name pgadmin \
  --restart unless-stopped \
  -p 5050:80 \
  -e PGADMIN_DEFAULT_EMAIL="$PGADMIN_EMAIL" \
  -e PGADMIN_DEFAULT_PASSWORD="$PGADMIN_PASSWORD" \
  dpage/pgadmin4:latest
