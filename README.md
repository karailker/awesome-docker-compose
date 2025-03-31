# Awesome Docker Compose

This repository contains a collection of Docker Compose configurations for various services.

## Available Configurations

- **Postgres with pgAdmin**: A setup for PostgreSQL database with pgAdmin for database management.
- **Postgres-pgVector with pgAdmin**: A setup for PostgreSQL with pgVector extension and pgAdmin for database management.
- **Kafka with Kafka UI**: A setup for Kafka message broker with Kafka UI for management.
- **MinIO**: A setup for MinIO object storage service.
- **Redis with RedisInsight**: A setup for Redis in-memory data structure store with RedisInsight for management.
- **RabbitMQ**: A setup for RabbitMQ message broker to enable reliable messaging between distributed systems.
- **Qdrant Vector DB**: A setup for Qdrant, a vector database optimized for storing and searching high-dimensional vectors, commonly used in machine learning and AI applications.
- **Milvus Vector DB**: A setup for Milvus, an open-source vector database designed for similarity search and AI-powered applications.
- **ElasticSearch with Kibana**: A setup for ElasticSearch, a distributed search and analytics engine, paired with Kibana for visualization and exploration of data. Note: ElasticAPM integration is currently under development and does not work properly yet. I am actively working on resolving the issues.
- **Grafana with Prometheus**: A setup for Grafana, a powerful visualization and monitoring tool, paired with Prometheus, a robust time-series database and monitoring system. This configuration enables efficient metric collection, storage, and visualization for system and application monitoring.

## What next?
- [ ] **MLOps Stack**

## Usage

To use any of the configurations, navigate to the respective directory and run:

```sh
docker-compose up
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.