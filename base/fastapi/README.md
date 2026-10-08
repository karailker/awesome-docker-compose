# FastAPI example app

Small [FastAPI](https://fastapi.tiangolo.com/) application built from a local `Dockerfile` and served with Uvicorn.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `fastapi` | built from `./Dockerfile` (`fastapi-example:latest`) | 8000 | API |

## Quick start

```sh
cp .env.example .env
mkdir -p fastapi_logs   # bind-mounted data directories must exist
docker compose up -d --build
```

- API: <http://localhost:8000>
- Interactive docs: <http://localhost:8000/docs>
- Endpoints: `GET /`, `GET /health`, `GET /items/{item_id}`, `POST /echo`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `FASTAPI_PORT` | `8000` | Host port |
| `FASTAPI_IMAGE` | `fastapi-example:latest` | Image name for the build |
| `APP_NAME` | `FastAPI Example` | Application title |
| `APP_ENV` | `production` | Environment label |
| `UVICORN_WORKERS` | `2` | Worker processes |
| `UVICORN_LOG_LEVEL` | `info` | Log level |

## Notes

- Application code is in `app/` with pinned dependencies in `app/requirements.txt`.
- Replace `app/` with your own project to reuse the setup.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
