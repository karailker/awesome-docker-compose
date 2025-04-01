Refactored version of official MongoDB Docker Compose file
source: [https://hub.docker.com/_/mongo](https://hub.docker.com/_/mongo)

docker compose up -d
docker compose down

docker compose --profile mongo-express up -d
docker compose --profile mongo-express down