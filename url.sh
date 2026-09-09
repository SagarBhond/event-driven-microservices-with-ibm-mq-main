#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/terraform"

alb_domain=$(terraform output -raw alb_dns_name)
alb_url="http://${alb_domain}"
mq_ip=$(terraform output -raw mq_public_ip)
pgadmin_ip=$(terraform output -raw pgadmin_public_ip)
rds_endpoint=$(terraform output -raw rds_endpoint)

printf '%s\n' '==========================================='
printf '%s\n' '   DYNAMIC SAGA PATTERN URLS'
printf '%s\n' '==========================================='
printf '\n%s\n' '1. PRODUCER SERVICE'
printf '%s\n' '-----------------------------------'
printf 'Health Check : %s/api/producer/health\n' "$alb_url"
printf 'Swagger UI   : %s/api/producer/swagger-ui/index.html\n' "$alb_url"

printf '\n%s\n' '2. INVENTORY SERVICE'
printf '%s\n' '-----------------------------------'
printf 'Health Check : %s/api/inventory/health\n' "$alb_url"
printf 'Swagger UI   : %s/api/inventory/swagger-ui/index.html\n' "$alb_url"

printf '\n%s\n' '3. PAYMENT SERVICE'
printf '%s\n' '-----------------------------------'
printf 'Health Check : %s/api/payment/health\n' "$alb_url"
printf 'Swagger UI   : %s/api/payment/swagger-ui/index.html\n' "$alb_url"

printf '\n%s\n' '4. NOTIFICATION SERVICE'
printf '%s\n' '-----------------------------------'
printf 'Health Check : %s/api/notification/health\n' "$alb_url"
printf 'Swagger UI   : %s/api/notification/swagger-ui/index.html\n' "$alb_url"

printf '\n%s\n' '==========================================='
printf '%s\n' '   INFRASTRUCTURE URLS'
printf '%s\n' '==========================================='
printf 'IBM MQ Console: https://%s:9443/ibmmq/console/\n' "$mq_ip"
printf 'IBM MQ Login  : admin / passw0rd (systems manager)\n' 
printf '\n%s\n' '==========================================='
printf '%s\n' '   DATABASE ACCESS (pgAdmin UI)'
printf '%s\n' '==========================================='
printf 'pgAdmin Web UI: http://%s:5050\n' "$pgadmin_ip"
printf 'Login Email   : admin@ordersaga.com\n'
printf 'Login Password: See /order-saga/POSTGRES_PASSWORD in SSM Parameter Store\n'
printf '\n%s\n' 'Database Hostname (single shared RDS instance)'
printf '%s\n' "- RDS Host        : ${rds_endpoint%:*}"
printf '%s\n' '- Port            : 5432'
printf '%s\n' '- Username        : postgres'
printf '%s\n' '- Password        : See /order-saga/POSTGRES_PASSWORD in SSM Parameter Store'
printf '\n%s\n' 'Database used by the deployed services:'
printf '%s\n' '  - order_db (Producer, Inventory, Payment, and Notification services)'
printf '%s\n' '==========================================='
