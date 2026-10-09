#!/usr/bin/env bash
# Functional test: the online feature server, the registry REST API and the UI answer.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="feast smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env

retry 180 "online feature server /health" curl -fsS "http://localhost:${ONLINE_PORT:-6566}/health"
retry 180 "registry REST API (/docs)" curl -fsS "http://localhost:${REGISTRY_REST_PORT:-6572}/docs"
retry 180 "UI answers" curl -fsS "http://localhost:${FEAST_UI_PORT:-8888}/"
echo "Feast functional smoke test passed"
