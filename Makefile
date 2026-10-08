# Shortcuts for working with the compose projects and for running the same checks as CI.
# Usage: make help

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

PROJECTS := $(sort $(patsubst %/compose.yaml,%,$(wildcard base/*/compose.yaml stacks/*/compose.yaml)))
P ?=

.PHONY: help list up up-bind down logs ps smoke smoke-bind config lint pins policy secrets scan-fs check

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Project targets take P=<dir>, for example: make up P=base/postgres"

list: ## List all projects
	@printf '%s\n' $(PROJECTS)

define need_project
	@test -n "$(P)" || { echo "set P=<project dir>, e.g. make $@ P=base/postgres"; exit 2; }
	@test -f "$(P)/compose.yaml" || { echo "$(P)/compose.yaml not found (see 'make list')"; exit 2; }
endef

up: ## Start a project (copies .env.example to .env if needed)
	$(need_project)
	@cd $(P) && { [ -f .env ] || [ ! -f .env.example ] || cp .env.example .env; } && docker compose up -d

up-bind: ## Start a project with data in host directories (compose.bind.yaml)
	$(need_project)
	@BIND=1 scripts/prepare-dirs.sh $(P) && cd $(P) && docker compose -f compose.yaml -f compose.bind.yaml up -d

down: ## Stop a project (keeps data); add V=1 to delete volumes
	$(need_project)
	@cd $(P) && docker compose down $(if $(V),-v,)

logs: ## Follow the logs of a project
	$(need_project)
	@cd $(P) && docker compose logs -f --tail=100

ps: ## Show the containers of a project
	$(need_project)
	@cd $(P) && docker compose ps -a

smoke: ## Start a project, wait until healthy, tear it down (what CI does)
	$(need_project)
	@scripts/smoke.sh $(P) $(or $(TIMEOUT),300)

smoke-bind: ## Same as smoke, with compose.bind.yaml
	$(need_project)
	@SMOKE_BIND=1 scripts/smoke.sh $(P) $(or $(TIMEOUT),300)

config: ## Validate every project (and its compose.bind.yaml) with 'docker compose config'
	@rc=0; for d in $(PROJECTS); do \
	  ( cd $$d && docker compose --env-file /dev/null --profile '*' config -q 2>/dev/null ) || { echo "FAIL $$d"; rc=1; }; \
	  if [ -f $$d/compose.bind.yaml ]; then \
	    ( cd $$d && docker compose --env-file /dev/null --profile '*' -f compose.yaml -f compose.bind.yaml config -q 2>/dev/null ) || { echo "FAIL $$d (compose.bind.yaml)"; rc=1; }; \
	  fi; \
	done; [ $$rc -eq 0 ] && echo "all $(words $(PROJECTS)) projects valid"; exit $$rc

lint: ## yamllint, JSON, ShellCheck, actionlint (those that are installed)
	@command -v yamllint >/dev/null && yamllint -c .yamllint.yml . || echo "skip yamllint (pip install yamllint)"
	@find . -name '*.json' -not -path './.git/*' -print0 | xargs -0 -n1 python3 -m json.tool >/dev/null
	@command -v shellcheck >/dev/null && shellcheck scripts/*.sh base/*/*.sh || echo "skip shellcheck"
	@command -v actionlint >/dev/null && actionlint .github/workflows/*.yml || echo "skip actionlint"

pins: ## Fail on floating image tags
	@scripts/check-pins.sh

policy: ## Compose security policy (privileged, docker.sock, host network, ...)
	@scripts/check-policy.py

secrets: ## gitleaks over the full history (installs a pinned gitleaks into ~/.local/bin if missing)
	@command -v gitleaks >/dev/null || scripts/install-tool.sh gitleaks
	@PATH="$$HOME/.local/bin:$$PATH" gitleaks detect --source . --config .gitleaks.toml --baseline-path .gitleaks-baseline.json --redact --no-banner

scan-fs: ## Trivy: secrets and Dockerfile misconfiguration
	@command -v trivy >/dev/null || scripts/install-tool.sh trivy
	@PATH="$$HOME/.local/bin:$$PATH" trivy fs --scanners secret,misconfig --severity HIGH,CRITICAL --skip-dirs .git --exit-code 1 --quiet .

check: lint config pins policy ## Fast checks that do not start containers
