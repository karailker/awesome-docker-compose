# MongoDB with Mongo Express

MongoDB (authentication enabled) with an optional Mongo Express web UI. Based on the official MongoDB image documentation.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `mongo` | `mongo:latest` | 27017 | Database (`--auth`) |
| `mongo-express` | `mongo-express` | 8081 | Web UI (profile `mongo-express`) |

## Quick start

```sh
cp .env.example .env
mkdir -p mongodb_data   # bind-mounted data directories must exist
docker compose up -d
docker compose --profile mongo-express up -d
```

- MongoDB: `mongodb://root:example@localhost:27017/`
- Mongo Express: <http://localhost:8081>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `MONGO_INITDB_ROOT_USERNAME` | `root` | Root user |
| `MONGO_INITDB_ROOT_PASSWORD` | `example` | Root password |
| `ME_CONFIG_MONGODB_ADMINUSERNAME` / `ME_CONFIG_MONGODB_ADMINPASSWORD` | `root` / `example` | Credentials used by Mongo Express |
| `ME_CONFIG_MONGODB_URL` | `mongodb://root:example@mongo:27017/` | Connection string for Mongo Express |
| `ME_CONFIG_BASICAUTH` | `false` | Enable basic auth on the UI |

## Notes

- Keep the Mongo Express credentials in sync with the root credentials.
- Source: <https://hub.docker.com/_/mongo>

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
