#!/bin/bash
# Bootstraps Docker Compose plus the Order Saga observability stack.
set -euo pipefail

dnf update -y
dnf install -y docker git amazon-cloudwatch-agent amazon-ssm-agent

systemctl enable --now docker
systemctl enable --now amazon-ssm-agent
usermod -aG docker ec2-user

# Docker Compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# Add swap file for memory safety
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Clone repo
mkdir -p /home/ec2-user/app
if [ ! -d /home/ec2-user/app/.git ]; then
  git clone https://github.com/SagarBhond/event-driven-microservices-with-ibm-mq-main.git /home/ec2-user/app
fi

cd /home/ec2-user/app
git fetch origin
git checkout main
git pull --ff-only origin main

sed -i "s/__ALB_DNS_NAME__/${alb_dns_name}/g" config/prometheus.yml
GRAFANA_ADMIN_PASSWORD=$(aws ssm get-parameter --name "/order-saga/MQ_ADMIN_PASSWORD" --with-decryption --region "${aws_region}" --query 'Parameter.Value' --output text)
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$GRAFANA_ADMIN_PASSWORD" > .env

chmod +x terraform/*.sh

# Start Monitoring Stack
/usr/local/bin/docker-compose -f docker-compose.monitoring.yml up -d

echo "Monitoring host bootstrap complete." > /var/log/bootstrap-done.log