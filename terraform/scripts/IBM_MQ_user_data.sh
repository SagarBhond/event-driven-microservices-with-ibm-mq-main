#!/bin/bash
set -euxo pipefail

yum update -y
dnf install -y docker jq
systemctl enable docker
systemctl start docker

if [ ! -e /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

data_device=$(lsblk -ndo NAME,TYPE | awk '$2 == "disk" && $1 != "nvme0n1" { print "/dev/" $1; exit }')
if [ -n "$data_device" ] && ! blkid "$data_device" >/dev/null 2>&1; then
  mkfs -t ext4 "$data_device"
fi
mkdir -p /mnt/mqm
if [ -n "$data_device" ]; then
  mount "$data_device" /mnt/mqm || true
fi
if [ -n "$data_device" ] && ! grep -q '/mnt/mqm' /etc/fstab; then
  echo "$data_device /mnt/mqm ext4 defaults,nofail 0 2" >> /etc/fstab
fi
chown 1001:1001 /mnt/mqm
chmod 755 /mnt/mqm

mkdir -p /tmp/mqm
cat > /tmp/mqm/queues.mqsc <<'EOF'
${mqsc_content}
EOF

aws ssm get-parameter --name "/order-saga/MQ_PASSWORD" --with-decryption --region "${aws_region}" --query 'Parameter.Value' --output text > /tmp/mq_app_password
aws ssm get-parameter --name "/order-saga/MQ_ADMIN_PASSWORD" --with-decryption --region "${aws_region}" --query 'Parameter.Value' --output text > /tmp/mq_admin_password

for i in $(seq 1 30); do
  docker rm -f ibm-mq >/dev/null 2>&1 || true
  docker run -d \
    --name ibm-mq \
    --restart unless-stopped \
    -e LICENSE=accept \
    -e MQ_QMGR_NAME=QM1 \
    -e MQ_APP_PASSWORD="$(cat /tmp/mq_app_password)" \
    -e MQ_ADMIN_PASSWORD="$(cat /tmp/mq_admin_password)" \
    -p 1414:1414 \
    -p 9443:9443 \
    -v /mnt/mqm:/mnt/mqm \
    icr.io/ibm-messaging/mq:latest

  if docker exec ibm-mq dspmq 2>/dev/null | grep -q 'status(running)'; then
    break
  fi
  sleep 20
done

sleep 30
docker exec -i ibm-mq runmqsc QM1 < /tmp/mqm/queues.mqsc
