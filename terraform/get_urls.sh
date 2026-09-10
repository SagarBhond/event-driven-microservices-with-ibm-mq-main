#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

for name in alb_dns_name mq_public_ip mq_private_ip pgadmin_public_ip rds_endpoint; do
  terraform output -raw "$name" >/dev/null
done

alb_dns_name=$(terraform output -raw alb_dns_name)
mq_public_ip=$(terraform output -raw mq_public_ip)
mq_private_ip=$(terraform output -raw mq_private_ip)
pgadmin_public_ip=$(terraform output -raw pgadmin_public_ip)
rds_endpoint=$(terraform output -raw rds_endpoint)

printf '\n=== Order Saga URLs ===\n'
printf 'Producer health: http://%s/api/producer/health\n' "$alb_dns_name"
printf 'Inventory health: http://%s/api/inventory/health\n' "$alb_dns_name"
printf 'Payment health: http://%s/api/payment/health\n' "$alb_dns_name"
printf 'Notification health: http://%s/api/notification/health\n' "$alb_dns_name"
printf '\nSwagger docs (via ALB):\n'
printf 'Producer: http://%s/api/producer/swagger-ui/index.html\n' "$alb_dns_name"
printf 'Inventory: http://%s/api/inventory/swagger-ui/index.html\n' "$alb_dns_name"
printf 'Payment: http://%s/api/payment/swagger-ui/index.html\n' "$alb_dns_name"
printf 'Notification: http://%s/api/notification/swagger-ui/index.html\n' "$alb_dns_name"
printf '\nIBM MQ Console: https://%s:9443/ibmmq/console\n' "$mq_public_ip"
printf 'IBM MQ private IP: %s\n' "$mq_private_ip"
printf 'pgAdmin: http://%s:5050\n' "$pgadmin_public_ip"
printf '\nRDS endpoint: %s\n' "$rds_endpoint"
printf 'RDS JDBC URL: jdbc:postgresql://%s:5432/order_db\n\n' "$rds_endpoint"
