# Roadmap

Where the project stands, what is verified, what is blocked, and what we could add next.
Status is based on what CI actually ran (see [How things are verified](#how-things-are-verified)), not on what the compose files claim.

Legend: ✅ done and verified · 🟡 done, not verified end to end · 🚧 in progress · ⬜ not started · 🔄 postponed · ⛔ blocked / not feasible as a compose project

## How things are verified

| Level | What runs | When |
|-------|-----------|------|
| **Static** | yamllint, JSON, ShellCheck, actionlint, `docker compose config` (with `.env.example` and defaults), README link coverage, every image resolves in its registry | every PR |
| **Smoke** | `scripts/smoke.sh`: start the project, wait for health, fail on crashed/unhealthy/restarting containers (one-shot jobs that exit 0 are fine) | every PR (lightweight projects), weekly + on demand (heavy projects) |
| **Bind mode** | same smoke test with `compose.bind.yaml` (host directories) | every PR (Postgres, MongoDB, Qdrant) |
| **S3 round trip** | create bucket, put, get, list, delete through the S3 API | every PR (RustFS, SeaweedFS, Garage) |
| **Functional** | a project's own `smoke-test.sh` runs after startup (real requests through the stack) | every PR (LGTM stack), weekly + on demand (RAG stack) |
| **Security** | gitleaks (full history), Trivy (secrets, Dockerfiles), compose policy; weekly image vulnerability report | every PR / weekly |

Run the same checks locally with `scripts/smoke.sh base/<name>` and `python3 scripts/s3-smoke.py <endpoint> <key> <secret>`.

## Current state of every project

| Project | State | Verified by | Notes |
|---------|-------|-------------|-------|
| `base/postgres`, `pgvector`, `mysql`, `mongodb`, `redis`, `valkey`, `rabbitmq`, `qdrant`, `kafka`, `grafana`, `influxdb`, `clickhouse`, `cockroachdb`, `fastapi` | ✅ | PR smoke | |
| `base/rustfs`, `seaweedfs`, `garage` | ✅ | PR smoke + S3 round trip | maintained S3 stores |
| `base/minio` | 🟡 legacy | PR smoke (starts) | MinIO Community Edition is unmaintained; Chainguard image is rebuilt from frozen source |
| `base/prefect`, `nexus`, `sonarqube`, `apache-airflow`, `feast` | ✅ | heavy smoke | Prefect now really uses PostgreSQL (the old setting name was ignored) |
| `stacks/mlflow-minio-postgres-pgadmin` | ✅ | heavy smoke x3 object stores + functional test | RustFS (default), SeaweedFS, Garage; logs a run with an artifact and reads it back |
| `stacks/mlflow-oidc-keycloak-minio-postgres-pgadmin` | ✅ | heavy smoke x3 object stores + functional test | bucket write/read/delete; the OIDC login itself is not exercised |
| `stacks/rag-ollama-openwebui-qdrant` | ✅ | heavy smoke + functional test | models download, embeddings, generation, Qdrant similarity search and an Open WebUI upload that lands in Qdrant; the GPU override is untested (no GPU runners) |
| `stacks/lgtm-observability` | ✅ | PR smoke + functional test | trace, metric and log round trip through the collector; Grafana provisioning checked; demo profile exercised in CI |
| `stacks/wandb-minio-postgres` | ✅ starts | heavy smoke x3 object stores + functional test | UI answers and the bucket is writable; real use of W&B Local may need a license/account |
| `base/elasticsearch` | ✅ | heavy smoke | 3-node cluster, Kibana and APM server become healthy; ingestion is not tested |
| `base/milvus` | ✅ | heavy smoke x3 object stores + functional test | collection, insert and similarity search via REST |
| `base/gitlab` | ✅ starts | heavy smoke | needs about 4 GB RAM; credentials are hard-coded and `external_url` does not match the published port |

## Roadmap items

### Done ✅
- SonarQube, Sonatype Nexus, FastAPI example, InfluxDB + Telegraf, ClickHouse + Tabix, CockroachDB
- RustFS, SeaweedFS, Garage (replacing unmaintained MinIO); Milvus, both MLflow stacks and W&B migrated, each with RustFS (default), SeaweedFS and Garage variants (`compose.<variant>.yaml`)
- Weights & Biases Local stack (starts and serves the UI)
- LGTM observability stack (Loki, Grafana, Tempo, Prometheus, OpenTelemetry Collector) with a functional round-trip test
- Local RAG stack (Ollama, Open WebUI, Qdrant) with a functional test from model download to a document landing in Qdrant
- Named volumes with `compose.bind.yaml`, pinned image versions with Renovate, security scans, Makefile, contributor checklist and PR template
- CI: static checks, smoke tests, S3 compatibility tests, weekly heavy tests
- README for every project

### In progress 🚧
- GitLab: starts and is covered by the heavy workflow; still has hard-coded credentials and an `external_url` that does not match the published port (`8090`)

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
2. ~~**Many images use `latest`.**~~ Fixed: every image is pinned to the version `latest` resolved to (MySQL to the 8.4 LTS), `scripts/check-pins.sh` enforces it in CI, and `renovate.json` proposes updates (the Renovate GitHub app must be enabled for the repository). Remaining floating tags are listed with a reason in `scripts/pin-exceptions.txt`: Chainguard's free tier only publishes `:latest`, and the Tabix image only has `:latest`.
3. ~~**MinIO is unmaintained.**~~ Migrated: Milvus, both MLflow stacks and W&B run on RustFS, SeaweedFS or Garage (see `shared/s3/`). Only the clearly marked legacy `base/minio` still uses the Chainguard MinIO build.
4. **Chainguard images run as non-root (uid 65532).** Only `base/minio` is left on one; its `minio-init-perms` service fixes the volume ownership (found by the heavy run: Milvus' MinIO crashed with `file access denied`).
5. **Insecure defaults.** (partly addressed: see the security checks below) Default passwords and tokens are documented everywhere, but nothing stops them from being published. CockroachDB runs `--insecure`.
6. **GitLab URL.** `external_url` is `http://gitlab.local` while the web UI is published on `8090`.
7. **Healthchecks and start order.** Several images do not ship the tool the healthcheck needs (found: `wget` missing in CockroachDB, Nexus and FastAPI images). New healthchecks must be verified in CI, which `scripts/smoke.sh` now does. The same check found services that crash when started before their dependency is ready (Prefect worker), so dependencies should use `condition: service_healthy`.

## Security findings fixed

8. **Airflow shipped shared secrets.** `base/apache-airflow/config/airflow.cfg` contained generated `jwt_secret`, `secret_key`, `internal_api_secret_key` and `fernet_key` values that every clone of the repository shared. They are now read from `AIRFLOW_JWT_SECRET`, `AIRFLOW_SECRET_KEY` and `AIRFLOW_FERNET_KEY` (development placeholders when unset). The old values stay in the git history, so treat them as public; `.gitleaks-baseline.json` records them so that only new leaks fail CI.
9. **FastAPI example ran as root.** The Dockerfile now creates and uses an unprivileged user (uid 10001). Host directories used with `compose.bind.yaml` must be writable by that uid.

## Proposals

Ideas for what to add next, grouped and roughly prioritized. Nothing here is committed to.

### Repository health (highest value)
1. ~~Decide the volume strategy~~ Done: named volumes plus `compose.bind.yaml` (see known issue 1).
2. ~~Pin image versions and add Renovate~~ Done (see known issue 2); needs the Renovate app enabled on the repository.
3. **Project template** (`templates/base/`): `compose.yaml`, `.env.example`, `.gitignore`, `README.md` skeleton, so new projects start consistent. Extend CI with a check that every project has the same README sections.
4. ~~Contributor checklist and PR template~~ Done (`CONTRIBUTING.md`, `.github/pull_request_template.md`). Not enforced yet: README section layout (see item 3).
5. ~~Security scanning~~ Done: gitleaks (full history, baseline for old findings), Trivy for secrets and Dockerfile misconfiguration, a compose policy check, and a weekly image/dependency vulnerability report. The scans already found two real problems (see known issues 8 and 9).
6. ~~Helper entrypoint~~ Done: `Makefile` (`make help`).
7. **Generated project index** in the root README (from a small metadata file per project) so the list cannot drift from the directory tree.
8. **Include-based stacks.** Compose `include:` lets stacks reuse `base/*` definitions instead of copying them (the MLflow stacks currently duplicate MinIO, Postgres and pgAdmin).

### New base services
| Area | Candidates | Notes |
|------|-----------|-------|
| Observability | Jaeger, Alertmanager, Grafana Alloy (container logs) | Loki, Tempo and the OpenTelemetry Collector already ship in `stacks/lgtm-observability` |
| Messaging / streaming | Redpanda, NATS, Apache Pulsar, Redpanda Console | Redpanda is a lighter Kafka-compatible option |
| Databases | MariaDB, Neo4j, TimescaleDB, ScyllaDB, SurrealDB, DuckDB (+ UI) | |
| Search / vector | Meilisearch, Typesense, OpenSearch + Dashboards, Weaviate, Chroma | OpenSearch is the natural Elasticsearch alternative |
| BI / data | Metabase, Apache Superset, Trino, Apache Spark (standalone), Dagster | Metabase is the easiest BI addition |
| Platform / DevOps | Traefik or Caddy (reverse proxy + TLS), Vault, Gitea or Forgejo, Woodpecker CI, Harbor, Authentik | reverse proxy is the most reusable building block |
| AI | Langfuse, LiteLLM proxy, ChromaDB | Ollama + Open WebUI + Qdrant already ship in `stacks/rag-ollama-openwebui-qdrant`; CPU-only examples are testable in CI with small models |

### New stacks
- ~~Observability (LGTM)~~ Done (`stacks/lgtm-observability`). Follow-ups: Tempo span-metrics and service graph (metrics generator), Alertmanager with sample alert rules, container log collection (Grafana Alloy), a sample instrumented app.
- **Data platform**: Postgres or ClickHouse + dbt + Airflow/Prefect + Superset/Metabase (this is also where dbt Core fits).
- ~~RAG / LLM~~ Ollama + Open WebUI + Qdrant added (`stacks/rag-ollama-openwebui-qdrant`). Follow-ups: Langfuse for tracing, a pgvector variant, LiteLLM proxy in front of Ollama, a GPU CI runner.
- **Streaming**: Kafka or Redpanda + Schema Registry + Kafka Connect + ClickHouse sink.
- **Dev platform**: Gitea/Forgejo + Woodpecker + Harbor + Traefik.

### Testing improvements
- Projects can ship a `smoke-test.sh` that `scripts/smoke.sh` runs after the stack is up (done for the LGTM and RAG stacks). Next candidates: log an MLflow run and read it back, produce/consume on Kafka (Kafka was done by hand), run a query on each database, ingest a trace into the APM server.
- A scheduled job that opens an issue when the weekly heavy run fails.
- Resource budget per project in metadata (RAM/CPU) so the heavy workflow can pick the right runner and timeout.

## Suggested next steps

In rough order of value for effort:

1. ~~**Move the MinIO users to a maintained store**~~ Done. Follow-up: decide when to delete `base/minio`, and use `include:` to share the `s3`/`create-bucket` definition instead of copying it into four projects.
2. **GitLab**: generate the root password from `.env`, fix `external_url` / the published port, add a functional check (sign in through the API).
3. **Functional tests for the heavy stacks**: MLflow (log a run and read it back), Kafka (produce/consume), Airflow (trigger an example DAG), Elasticsearch (index and search). Each one is a `smoke-test.sh`.
4. **Project template and README section check** (proposal 3), so new projects start consistent.
5. **Apache Superset or Metabase** (in progress) as a BI service, then the data platform stack (database + dbt + scheduler + BI).
6. **Alertmanager and span-metrics for the LGTM stack**, and Langfuse / a pgvector variant for the RAG stack.

## How to propose or pick up an item

Open an issue using the feature request template, mention the project name and which verification level you expect (smoke, S3 round trip, functional). New projects must follow the checklist in [CONTRIBUTING.md](CONTRIBUTING.md).
