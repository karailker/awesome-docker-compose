docker compose up -d
docker compose down

## Host requirements

SonarQube's embedded Elasticsearch needs `vm.max_map_count >= 262144` and at least 65535 open file descriptors on the Docker host:

```sh
sudo sysctl -w vm.max_map_count=262144
```
