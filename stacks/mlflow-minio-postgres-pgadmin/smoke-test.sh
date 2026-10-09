#!/usr/bin/env bash
# Functional test: the MLflow server answers and an artifact survives a round trip through the
# S3 object store (RustFS / SeaweedFS / Garage, whichever variant is running).
# Run by scripts/smoke.sh after the stack is up (working directory: this directory).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
fail() { echo "::error::mlflow smoke test: $*"; exit 1; }

deadline=$((SECONDS + 300))
until curl -fsS http://localhost:5000/health >/dev/null 2>&1; do
  [ $SECONDS -ge $deadline ] && fail "MLflow did not become healthy"
  sleep 5
done
echo "ok: MLflow is healthy"

docker compose exec -T mlflow python - <<'PY' || fail "artifact round trip failed"
import mlflow, tempfile, pathlib
mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("smoke")
with mlflow.start_run() as run:
    mlflow.log_param("hello", "world")
    mlflow.log_text("artifact through the object store", "note.txt")
    run_id = run.info.run_id
with tempfile.TemporaryDirectory() as d:
    path = mlflow.artifacts.download_artifacts(run_id=run_id, artifact_path="note.txt", dst_path=d)
    assert pathlib.Path(path).read_text() == "artifact through the object store"
print("artifact stored in", mlflow.get_run(run_id).info.artifact_uri, "and read back")
PY
echo "ok: artifact round trip through the object store"
echo "MLflow functional smoke test passed"
