# Roadmap

Where the project stands, what is verified, what is blocked, and what we could add next.
Status is based on what CI actually ran (see [How things are verified](#how-things-are-verified)), not on what the compose files claim.

Legend: ✅ done and verified · 🟡 done, not verified end to end · 🚧 in progress · ⬜ not started · 🔄 postponed · ⛔ blocked / not feasible as a compose project

## How things are verified

| Level | What runs | When |
|-------|-----------|------|
| **Static** | yamllint, JSON, ShellCheck, actionlint, `docker compose config` (with `.env.example` and defaults), README link coverage, every image resolves in its registry | every PR |
| **Smoke** | `scripts/smoke.sh`: start the project, wait for health, fail on crashed/unhealthy containers | every PR (lightweight projects), weekly + on demand (heavy projects) |
| **S3 round trip** | create bucket, put, get, list, delete through the S3 API | every PR (RustFS, SeaweedFS, Garage) |

Run the same checks locally with `scripts/smoke.sh base/<name>` and `python3 scripts/s3-smoke.py <endpoint> <key> <secret>`.

## Current state of every project

| Project | State | Verified by | Notes |
|---------|-------|-------------|-------|
| `base/postgres`, `pgvector`, `mysql`, `mongodb`, `redis`, `valkey`, `rabbitmq`, `qdrant`, `kafka`, `grafana`, `influxdb`, `clickhouse`, `cockroachdb`, `fastapi` | ✅ | PR smoke | |
| `base/rustfs`, `seaweedfs`, `garage` | ✅ | PR smoke + S3 round trip | maintained S3 stores |
| `base/minio` | 🟡 legacy | PR smoke (starts) | MinIO Community Edition is unmaintained; Chainguard image is rebuilt from frozen source |
| `base/prefect`, `nexus`, `sonarqube`, `apache-airflow`, `feast` | ✅ | heavy smoke | |
| `stacks/mlflow-minio-postgres-pgadmin`, `mlflow-oidc-keycloak-minio-postgres-pgadmin` | ✅ | heavy smoke | start only; no tracking run or OIDC login is exercised |
| `stacks/wandb-minio-postgres` | ✅ starts | heavy smoke | UI answers; real use of W&B Local may need a license/account |
| `base/elasticsearch` | 🟡 | heavy smoke | cluster, Kibana and APM server become healthy; the smoke check used to fail on the one-shot `setup` job (fixed) |
| `base/milvus` | 🟡 | heavy smoke | see [Known issues](#known-issues) |
| `base/gitlab` | 🟡 | none yet | never run in CI; needs about 4 GB RAM |

## Roadmap items

### Done ✅
- SonarQube, Sonatype Nexus, FastAPI example, InfluxDB + Telegraf, ClickHouse + Tabix, CockroachDB
- RustFS, SeaweedFS, Garage (replacing unmaintained MinIO)
- Weights & Biases Local stack (starts and serves the UI)
- CI: static checks, smoke tests, S3 compatibility tests, weekly heavy tests
- README for every project

### In progress 🚧
- GitLab: compose exists but has hard-coded credentials, no CI coverage and an `external_url` that does not match the published port (`8090`)

### Not started ⬜
- Apache Superset: feasible (official image, needs a metadata DB, Redis and an init step)
- BentoML: feasible as a sample serving stack (build a Bento, serve it, put it behind a gateway)

### Postponed 🔄
- dbt Core: it is a CLI, so a compose project only makes sense together with a warehouse (Postgres/ClickHouse) and a scheduler (Airflow/Prefect)

### Blocked / not feasible ⛔
- **Nvidia Triton**: needs an NGC image of about 10 GB, models and ideally a GPU. Cannot be smoke tested on GitHub-hosted runners. A CPU-only example is possible but should be tagged as untested in CI.
- **Great Expectations**: a Python library, there is no server to run. The useful compose artifact is a job that runs checks against a database plus a Data Docs web server; this is a design decision, not just an image.
- **ElasticAPM end to end**: the APM server container is healthy, but ingestion is not tested, so the note in the README stays until a real trace round trip is added to CI.

## Known issues

Ordered by user impact.

1. ~~**Bind volumes need pre-created directories.**~~ Fixed: data now lives in named volumes (`<VOLUME_PREFIX>_<volume>`), and every project has a `compose.bind.yaml` override for host directories. CI validates the override for every project and runs a bind-mode smoke test for Postgres, MongoDB and Qdrant.
2. **Many images use `latest`.** Examples: `postgres:latest` caused a breakage when Postgres 18 shipped, `confluentinc/cp-kafka:latest` dropped Zookeeper. Pin versions and let a bot propose updates.
3. **MinIO is unmaintained.** `base/minio`, `base/milvus` and the three MLflow/W&B stacks still use the Chainguard MinIO build. Migrate to RustFS, SeaweedFS or Garage once those are exercised by the stacks.
4. **Chainguard images run as non-root (uid 65532).** Data directories must be owned by that uid; every MinIO project now has a one-shot `minio-init-perms` service that fixes ownership first (found by the heavy run: Milvus' MinIO crashed with `file access denied`).
5. **Insecure defaults.** Default passwords and tokens are documented everywhere, but nothing stops them from being published. CockroachDB runs `--insecure`.
6. **GitLab URL.** `external_url` is `http://gitlab.local` while the web UI is published on `8090`.
7. **Healthchecks.** Several images do not ship the tool the healthcheck needs (found: `wget` missing in CockroachDB, Nexus and FastAPI images). New healthchecks must be verified in CI, which `scripts/smoke.sh` now does.

## Proposals

Ideas for what to add next, grouped and roughly prioritized. Nothing here is committed to.

### Repository health (highest value)
1. ~~Decide the volume strategy~~ Done: named volumes plus `compose.bind.yaml` (see known issue 1).
2. **Pin image versions and add Renovate or Dependabot** (`docker-compose` ecosystem) so tags are updated by PRs that CI validates.
3. **Project template** (`templates/base/`): `compose.yaml`, `.env.example`, `.gitignore`, `README.md` skeleton, so new projects start consistent. Extend CI with a check that every project has the same README sections.
4. **Contributor checklist and PR template** that mirror what CI enforces (healthcheck present, versions pinned, README sections, listed in the root README).
5. **Security scanning**: Trivy (config and image scan) and gitleaks in CI; fail only on high severity and secrets.
6. **Helper entrypoint** (`Makefile` or `just`): `make up p=base/postgres`, `make smoke p=...`, `make test`, so the commands in the READMEs and CI are the same.
7. **Generated project index** in the root README (from a small metadata file per project) so the list cannot drift from the directory tree.
8. **Include-based stacks.** Compose `include:` lets stacks reuse `base/*` definitions instead of copying them (the MLflow stacks currently duplicate MinIO, Postgres and pgAdmin).

### New base services
| Area | Candidates | Notes |
|------|-----------|-------|
| Observability | Loki + Promtail, Tempo, Jaeger, OpenTelemetry Collector, Alertmanager | extend Grafana/Prometheus into an LGTM stack |
| Messaging / streaming | Redpanda, NATS, Apache Pulsar, Redpanda Console | Redpanda is a lighter Kafka-compatible option |
| Databases | MariaDB, Neo4j, TimescaleDB, ScyllaDB, SurrealDB, DuckDB (+ UI) | |
| Search / vector | Meilisearch, Typesense, OpenSearch + Dashboards, Weaviate, Chroma | OpenSearch is the natural Elasticsearch alternative |
| BI / data | Metabase, Apache Superset, Trino, Apache Spark (standalone), Dagster | Metabase is the easiest BI addition |
| Platform / DevOps | Traefik or Caddy (reverse proxy + TLS), Vault, Gitea or Forgejo, Woodpecker CI, Harbor, Authentik | reverse proxy is the most reusable building block |
| AI | Ollama + Open WebUI, Langfuse, LiteLLM proxy, ChromaDB | CPU-only examples are testable in CI with tiny models |

### New stacks
- **Observability (LGTM)**: Grafana + Loki + Tempo + Prometheus + OpenTelemetry Collector with a sample instrumented app.
- **Data platform**: Postgres or ClickHouse + dbt + Airflow/Prefect + Superset/Metabase (this is also where dbt Core fits).
- **RAG / LLM**: Ollama + Open WebUI + Qdrant or pgvector + Langfuse.
- **Streaming**: Kafka or Redpanda + Schema Registry + Kafka Connect + ClickHouse sink.
- **Dev platform**: Gitea/Forgejo + Woodpecker + Harbor + Traefik.
- **S3-backed stacks on the maintained stores**: MLflow and W&B variants using RustFS/SeaweedFS/Garage instead of MinIO.

### Testing improvements
- Functional checks beyond "container is healthy": log an MLflow run and read it back, produce/consume on Kafka (Kafka was done by hand), run a query on each database, ingest a trace into the APM server.
- A scheduled job that opens an issue when the weekly heavy run fails.
- Resource budget per project in metadata (RAM/CPU) so the heavy workflow can pick the right runner and timeout.

## How to propose or pick up an item

Open an issue using the feature request template, mention the project name and which verification level you expect (smoke, S3 round trip, functional). New projects must follow the checklist in [CONTRIBUTING.md](CONTRIBUTING.md).
