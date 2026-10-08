# MySQL with Adminer and phpMyAdmin

MySQL with two optional admin UIs: Adminer and phpMyAdmin.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `mysql` | `mysql:latest` | 3306, 3307 | Database |
| `adminer` | `adminer` | 8080 | Lightweight DB UI (profile `adminer`) |
| `phpmyadmin` | `phpmyadmin/phpmyadmin` | 8081 | DB UI (profile `phpmyadmin`) |

## Quick start

```sh
cp .env.example .env
mkdir -p mysql_data   # bind-mounted data directories must exist
docker compose up -d
docker compose --profile adminer up -d
docker compose --profile phpmyadmin up -d
```

- Adminer: <http://localhost:8080> (server `mysql`)
- phpMyAdmin: <http://localhost:8081>
- Client: `mysql -h 127.0.0.1 -P 3306 -u user -p`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `MYSQL_USER` | `user` | Application user |
| `MYSQL_PASSWORD` | `password` | Application user password |
| `MYSQL_DATABASE` | `mydb` (in `.env.example`) | Database created on first start |
| `MYSQL_ROOT_PASSWORD` | `example` | Root password |
| `ADMINER_DEFAULT_SERVER` | `mysql` | Preselected Adminer server |
| `PMA_HOST` / `PMA_USER` / `PMA_PASSWORD` | `mysql` / `user` / `password` | phpMyAdmin login |

## Notes

- The image tag is `latest`; pin a version (for example `mysql:8.4`) for reproducible setups.
- Data lives in the `mysql_data` volume (bind-mounted to `./mysql_data`).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
