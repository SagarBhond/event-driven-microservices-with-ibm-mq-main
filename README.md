# IBM MQ Order Saga (Pure MQ - No Kafka/Debezium)

Four independent Spring Boot microservices, each with its own PostgreSQL
database, wired together purely through **IBM MQ**. There is no Kafka,
no Debezium, no CDC connector in this project anymore - every hop between
services is a real MQ queue you can watch fill up and drain in the
IBM MQ Web Console.

## Architecture

```text
Client
  |
  | POST /api/producer/send?product=Laptop&quantity=2
  v
+----------------------+
| Order Producer (8080)|  writes order -> outbox_events (Outbox Pattern)
+----------------------+  OutboxPoller relays it to MQ every 5s
  |
  |  MQ: DEV.ORDER.QUEUE
  v
+------------------------+
| Order Inventory (8081) |  checks real stock in inventory_items
+------------------------+
----------------------+
  |                                  \
----------------------+  OutboxPoller relays it to MQ every 5s
  | stock available                   \ stock unavailable / not found
  | MQ: DEV.PAYMENT.QUEUE               \ MQ: DEV.ORDER.FAILED.QUEUE
  v                                      v
------------------------+
+----------------------+          +--------------------------+
------------------------+
| Order Payment (8082)  |          | back to Order Producer   |
+----------------------+          | order marked CANCELLED   |
  |                    \          | reason: "Product         |
  | payment success      \        |  unavailable"            |
----------------------+          +--------------------------+
  | MQ: DEV.NOTIFICATION.  \      +--------------------------+
----------------------+          | order marked CANCELLED   |
  |     QUEUE                \
  v                            \ payment failed
+---------------------------+    \ MQ: DEV.ORDER.FAILED.QUEUE (-> Producer)
| Order Notification (8083)|       MQ: DEV.INVENTORY.COMPENSATE.QUEUE (-> Inventory releases stock)
+---------------------------+
---------------------------+    \ MQ: DEV.ORDER.FAILED.QUEUE (-> Producer)
  |
---------------------------+
  | MQ: DEV.ORDER.COMPLETED.QUEUE
  v
back to Order Producer -> order marked COMPLETED
```

Every arrow above is a real IBM MQ queue - open the IBM MQ Web Console
(`https://localhost:9443/ibmmq/console`) or `Docker Desktop -> ibm-mq ->
Terminal -> runmqsc QM1` and you'll see all of them:

| Queue | Purpose |
|---|---|
| `DEV.ORDER.QUEUE` | Producer -> Inventory (new order) |
| `DEV.PAYMENT.QUEUE` | Inventory -> Payment (stock confirmed) |
| `DEV.NOTIFICATION.QUEUE` | Payment -> Notification (payment confirmed) |
| `DEV.ORDER.FAILED.QUEUE` | Inventory/Payment -> Producer (order cancelled) |
| `DEV.ORDER.COMPLETED.QUEUE` | Notification -> Producer (order finished) |
| `DEV.INVENTORY.COMPENSATE.QUEUE` | Payment -> Inventory (release reserved stock) |
| `DEV.DEAD.LETTER.QUEUE` | Poison messages after max retries |

These are defined in `mq-config/20-queues.mqsc`, which is mounted into the
IBM MQ container and executed automatically on startup. **This file is
the fix for the "MQRC unknown object" errors** you were seeing - those
queues have to be explicitly defined somewhere, and the old file that did
that was deleted along with the Debezium setup.

## Why an order gets cancelled

Inventory now checks against a real product catalog (`inventory_items`,
seeded with ~20 products on first boot) instead of just checking
`quantity > 0`:

- Product doesn't exist in the catalog -> **cancelled**, "Product not found"
Two products are seeded intentionally scarce for demoing the failure path:
`Limited Edition GPU` (qty 2) and `Discontinued Printer` (qty 0).

## Databases (2 tables per service)

| Service | DB                       | Tables |
|---|--------------------------|---|
| order-producer-service | `order_db` (5432)        | `orders`, `outbox_events` |
| order-inventory-service | `inventory_db` (5432)    | `inventory_items` (catalog), `inventory_reservations` |
| order-payment-service | `payment_db` (5432)      | `payments`, `payment_events` |
| order-notification-service | `notification_db` (5432) | `notifications`, `notification_events` |

Tables are created automatically by Hibernate (`ddl-auto=update`) - you
don't need to create them by hand, just the four databases:

```sql
CREATE DATABASE order_db;
CREATE DATABASE inventory_db;
CREATE DATABASE payment_db;
CREATE DATABASE notification_db;
```

(Already handled for you by `docker-compose.yml` if you use it to start
the Postgres containers - each one comes up with its own `POSTGRES_DB`.)

## Running it

```bash
docker-compose up -d
```

This starts the four Postgres containers and IBM MQ with the queues
pre-created. Then run each Spring Boot service (in IntelliJ, or
`mvn spring-boot:run` in each folder) in this order:

1. `order-producer-service` -> port 8080
2. `order-inventory-service` -> port 8081
3. `order-payment-service` -> port 8082
4. `order-notification-service` -> port 8083

Health checks:
```http
GET /api/producer/health
GET /api/inventory/health
GET /api/payment/health
GET /api/notification/health
```

Swagger UI for the inventory service:
```text
http://localhost:8081/swagger-ui/index.html
```

The fragment `#/order-controller/create` is not an operation in the current
inventory controller. Do not open IBM MQ port `1414` as an HTTP page. Port
`1414` is the native IBM MQ client protocol and is healthy when MQ clients
connect to it. Use the browser-based IBM MQ Web Console on port `9443`:
```text
https://localhost:9443/ibmmq/console
```

Do not open PostgreSQL port `5432` in a browser. It is the native PostgreSQL
protocol, not HTTP. Connect with a PostgreSQL client instead:
```bash
psql -h localhost -p 5432 -U postgres -d producer_db
```

The local stack uses one PostgreSQL container on port `5432` with the
databases `producer_db`, `inventory_db`, `payment_db`, and `notification_db`.

## Try it

**Happy path:**
```http
POST http://localhost:8080/api/producer/send?product=Laptop&quantity=2
GET  http://localhost:8080/api/producer/status/{orderId}
```
Watch the order move: `PENDING -> INVENTORY_CONFIRMED -> PAYMENT_SUCCESS -> COMPLETED`

**Product unavailable:**
```http
POST http://localhost:8080/api/producer/send-unavailable
```
Orders a known out-of-stock item; Inventory rejects it immediately and the
order ends up `CANCELLED` with `failureReason = "Product unavailable..."`.

**Invalid order:**
```http
POST http://localhost:8080/api/producer/send-bad
```

**See the catalog / stock levels:**
```http
GET http://localhost:8081/api/inventory/catalog
```

**See reservation history (RESERVED / RELEASED / UNAVAILABLE):**
```http
GET http://localhost:8081/api/inventory/records
```

## Design Patterns Implemented

- **Outbox Pattern** - Producer writes to `outbox_events` instead of calling MQ inside the request transaction; a scheduled poller relays it
## Project Structure

```text
debezium/
 ├── docker-compose.yml          PostgreSQL + IBM MQ
 ├── postgres-init/               Four databases created on first startup
 ├── mq-config/20-queues.mqsc    Queue + auth definitions (auto-run by IBM MQ)
 ├── order-producer-service/       (port 8080)
 ├── order-inventory-service/      (port 8081)
 ├── order-payment-service/        (port 8082)
 └── order-notification-service/   (port 8083)
```

# event-driven-microservices-with-ibm-mq-main
