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

## Testing

`smoke-test.sh` (run by CI with `scripts/smoke.sh base/rabbitmq`) declares a queue, publishes a message and reads it back through the management API, and checks that a wrong password gets HTTP 401.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `rabbitmq_data` | `rabbitmq_rabbitmq_data` | `rabbitmq:/var/lib/rabbitmq` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `rabbitmq`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p rabbitmq_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
