# RabbitMQ

RabbitMQ message broker with the management UI.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `rabbitmq` | `rabbitmq:4-management` | 5672 (AMQP), 15672 (UI) | Message broker |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Management UI: <http://localhost:15672> (`RABBITMQ_DEFAULT_USER` / `RABBITMQ_DEFAULT_PASS`)
- AMQP URL: `amqp://user:password@localhost:5672/`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `RABBITMQ_DEFAULT_USER` | `user` | Default user |
| `RABBITMQ_DEFAULT_PASS` | `password` | Default password |

## Notes

- Change the default credentials before exposing the ports.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
