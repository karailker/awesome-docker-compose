## What does this change?

<!-- New or changed project, CI change, docs... -->

## Checklist

- [ ] Project has `compose.yaml`, `.env.example`, `.gitignore`, `README.md` and is linked in the root README
- [ ] Image tags are pinned and every long-running service has a working healthcheck
- [ ] `docker compose config -q` passes; I ran `scripts/smoke.sh <dir>` locally
- [ ] Added to the right CI matrix (`smoke` for light projects, `heavy-smoke.yml` for heavy ones)
- [ ] Defaults are development-only; no real secrets committed

## How was it tested?

<!-- Commands you ran and what you saw -->
