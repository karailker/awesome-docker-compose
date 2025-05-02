source: https://airflow.apache.org/docs/apache-airflow/3.0.0/docker-compose.yaml

docker compose run airflow-cli airflow config list
docker compose up airflow-init
docker compose up -d
docker compose down

docker compose run airflow-cli airflow config list
docker compose up airflow-init
docker compose --profile flower up -d
docker compose --profile flower down