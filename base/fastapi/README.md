# FastAPI example app

Small [FastAPI](https://fastapi.tiangolo.com/) application built from a local `Dockerfile` and served with Uvicorn.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `fastapi` | built from `./Dockerfile` (`fastapi-example:latest`) | 8000 | API |

## Quick start

```sh
cp .env.example .env
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

- The container runs as an unprivileged user (uid `10001`). With `compose.bind.yaml`, the host log directory must be writable by that uid.
- Application code is in `app/` with pinned dependencies in `app/requirements.txt`.
- Replace `app/` with your own project to reuse the setup.

## Testing

`smoke-test.sh` (run by CI with `scripts/smoke.sh base/fastapi`) exercises `/health`, `/`, `/items/{id}` (including the 400 and 422 error cases), `POST /echo` and checks that the application writes its log file.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `fastapi_logs` | `fastapi_fastapi_logs` | `fastapi:/var/log/fastapi` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `fastapi`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p fastapi_logs
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
