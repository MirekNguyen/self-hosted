# Hermes Agent

Hosts:
- `hermes.mirekng.com` → web dashboard (port 9119, basic-auth login)
- `gateway.mirekng.com` → OpenAI-compatible API server (port 8642, bearer `API_SERVER_KEY`)

Chart: `charts/hermes` (custom), app manifest `apps/hermes.yml`
Image: `nousresearch/hermes-agent:v0.22.5` (latest **GitHub release**, not `main`/`latest`)

Migrated from Dokploy on Hetzner to k3s on 2026-10-28 — see
[changelog](changelog/2026-10-28-hermes.md).

## Architecture

| Resource | Name | Notes |
|----------|------|-------|
| Deployment | `hermes-deployment` | 1 replica, `strategy: Recreate`, args `gateway run` |
| Service | `hermes-service` | named ports `dashboard` (9119), `gateway` (8642) |
| Ingress | `hermes-ingress` | two hosts, TLS via wildcard `ssl-certificate` |
| Middleware | `hermes-redirect-https` | Traefik `redirectScheme` HTTP → HTTPS |
| PVC | `hermes-data-pvc` | `/storage/config/hermes/data` → `/opt/data` (`HERMES_HOME`) |
| PVC | `hermes-root-pvc` | `/storage/config/hermes/root` → `/root` (caches only) |
| Secret | `hermes-secret` | created out-of-band with kubectl, **not** in git |

DNS: explicit unproxied Cloudflare A records `hermes` and `gateway` →
`109.239.79.2` (override the `*.mirekng.com` wildcard).

### Process model

The image entrypoint (`entrypoint-dispatch.sh`) runs s6-overlay `/init` as
PID 1 (Kubernetes gives the container PID 1, so the full supervision tree is
used — do **not** enable `shareProcessNamespace` or wrap it in another init).
s6 starts as root, remaps/chowns the `hermes` user (uid/gid 10000) and drops
to it for:
- `main-hermes` → `hermes gateway run` (Telegram, API server, cron, kanban)
- `dashboard` → `hermes dashboard --host 0.0.0.0 --port 9119` when `HERMES_DASHBOARD=1`

Because of the root → hermes drop and headless browsers (camoufox/Chromium),
the container keeps Docker-equivalent defaults (RuntimeDefault seccomp, not
privileged, capabilities not dropped) and gets a 1 GiB memory-backed
`/dev/shm`.

### Why `Recreate` and a single replica

- `state.db` is single-writer SQLite.
- Telegram uses long polling — two instances with the same bot token fight
  over `getUpdates` (409 Conflict). The old pod must stop before the new one
  starts. The same applies to any other Hermes instance using this token.

## Data layout (`/storage/config/hermes`)

| Path | Content |
|------|---------|
| `data/state.db` | sessions + messages (FTS indexes), single-writer |
| `data/kanban.db`, `data/response_store.db` | kanban board, API response store |
| `data/config.yaml` | main config incl. `dashboard.basic_auth` (password hash) |
| `data/.env` | extra settings (Hindsight, Telegram home channel, browser opts) |
| `data/skills/`, `data/cron/`, `data/sessions/`, `data/home/` | skills, scheduled jobs, session artefacts, agent home |
| `data/backups/config/` | automatic config backups written by migrations |
| `data/.cache/`, `data/.venv/` | uv / HF caches, plugin venv |
| `root/.cache/` | uv cache (~0.9 GB) + camoufox browser (~1.4 GB) |

## Configuration

Non-secret env in `apps/hermes.yml`: `HERMES_DASHBOARD=1`,
`API_SERVER_ENABLED`, `API_SERVER_HOST=0.0.0.0`, `HINDSIGHT_API_URL`,
`VIKUNJA_URL`, `HERMES_SPOTIFY_CLIENT_ID`.

Most behaviour lives in `/opt/data/config.yaml` (edit via the dashboard or
`kubectl exec … hermes config set …`). Memory provider is **Hindsight**.

### Dashboard auth

Since the June 2026 hardening the dashboard **refuses to bind a non-loopback
address without an auth provider** (`HERMES_DASHBOARD_INSECURE` is ignored).
Here it is satisfied by `dashboard.basic_auth` (user `binh` + password hash)
in `config.yaml`. If that block is ever removed, set
`HERMES_DASHBOARD_BASIC_AUTH_USERNAME` / `_PASSWORD` (or
`HERMES_DASHBOARD_OAUTH_CLIENT_ID`) or the dashboard silently won't start.

### Secret `hermes-secret`

Keys: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_USERS`, `API_SERVER_KEY`,
`NOTION_API_KEY`, `HINDSIGHT_API_KEY`, `VIKUNJA_TOKEN`, `EXA_API_KEY`,
`DEEPSEEK_API_KEY`, `XIAOMI_API_KEY`. Injected with `envFrom`.

Read the gateway API key (e.g. to configure a client):

```sh
kubectl --context=k3s get secret hermes-secret -n default -o jsonpath='{.data.API_SERVER_KEY}' | base64 -d; echo
```

Update one key without touching the others:

```sh
kubectl --context=k3s patch secret hermes-secret -n default --type merge \
  -p "{\"stringData\":{\"EXA_API_KEY\":\"<new value>\"}}"
kubectl --context=k3s rollout restart deploy/hermes-deployment -n default
```

## Upgrading

1. Use the latest **GitHub release** tag (`gh release view` / releases API),
   not `latest`/`main`. Read the release notes for "Upgrade notes".
2. Back up `state.db` online (SQLite backup API, safe while running):
   ```sh
   P=$(kubectl --context=k3s get pod -n default -l app=hermes-selector -o name)
   kubectl --context=k3s exec -n default $P -- python3 -c "import sqlite3,datetime as d; s=sqlite3.connect('/opt/data/state.db'); t=sqlite3.connect(f'/opt/data/backups/state.db.{d.date.today()}'); s.backup(t); t.close()"
   ```
   Config migrations back up `config.yaml`/`.env` automatically into
   `/opt/data/backups/config/`.
3. Bump `image.tag` in `apps/hermes.yml`, commit, push, sync app-of-apps.

## Health checks

- `GET https://gateway.mirekng.com/health` → `{"status":"ok","version":…}` (probes use this on the pod)
- `GET https://hermes.mirekng.com/` → 302 `/login`; unauthenticated `/api/*` → 401
- Logs: `kubectl logs` (s6 + stage2) and `/opt/data/logs/{gateway,agent}.log`;
  look for `✓ telegram connected`.

## Known issues / notes

- Startup warning: *API server is network-accessible AND the terminal backend
  is 'local' (unsandboxed)*. This was already the case on Dokploy: anyone with
  `API_SERVER_KEY` can run commands inside the container. Mitigations: keep
  the key secret, or restrict `gateway.mirekng.com` (IP allow-list / forward
  auth) or switch `terminal.backend` to a sandbox.
- Old Hetzner deployment (Dokploy project *Hermes*, compose `hermes`) is
  **stopped, not deleted**; its volumes are intact. Backup of `/opt/data`:
  `/root/backups/hermes-v2026.6.5-data-pre-k3s-migration-2026-10-28.tar.gz`
  (+ `.sha256`). Do **not** start it while k3s Hermes runs (Telegram conflict).

## Changelog

- [2026-10-28](changelog/2026-10-28-hermes.md) — Migrated from Dokploy/Hetzner to k3s, upgraded v2026.6.5 → v0.22.5, rotated `API_SERVER_KEY`
