# Open WebUI

Server: `chat.mirekng.com`
Chart: `charts/open-webui` (custom), app manifest `apps/open-webui.yml`
Image: `ghcr.io/open-webui/open-webui:0.12.4`

Migrated from Dokploy on Hetzner to k3s on 2026-10-28 — see
[changelog](changelog/2026-10-28-open-webui.md).

## Architecture

| Resource | Name | Notes |
|----------|------|-------|
| Deployment | `open-webui-deployment` | 1 replica, `strategy: Recreate` |
| Service | `open-webui-service` | port 8080 |
| Ingress | `open-webui-ingress` | Traefik, TLS via wildcard `ssl-certificate` |
| Middleware | `open-webui-redirect-https` | Traefik `redirectScheme` (HTTP → HTTPS, permanent: 301 GET / 308 other) |
| PVC | `open-webui-data-pvc` | hostPath `/storage/config/open-webui` (NVMe), mounted at `/app/backend/data` |
| Secret | `open-webui-secret` | created out-of-band with kubectl, **not** in git |

Namespace: `default` (so it can use the shared `ssl-certificate` wildcard secret).

DNS: explicit Cloudflare A record `chat.mirekng.com → 109.239.79.2`, unproxied
(overrides the `*.mirekng.com` wildcard, which still points to Hetzner).

### Why `Recreate` and a single replica

Data lives in SQLite (`webui.db`) on a RWO hostPath volume, and Open WebUI's
DB migrations explicitly do not support rolling updates. Two pods must never
run against the same database — keep `replicas: 1` and `Recreate`.

### Security context

The upstream image runs as root and writes into `/app/backend` at startup, and
the migrated data is root-owned. The container keeps UID 0 but drops **all**
capabilities, disallows privilege escalation and uses the `RuntimeDefault`
seccomp profile.

## Data layout (`/storage/config/open-webui`)

| Path | Content |
|------|---------|
| `webui.db` | SQLite: users, chats, settings, files metadata |
| `uploads/` | uploaded files |
| `vector_db/` | Chroma vector store (RAG) |
| `cache/` | embedding / whisper / tiktoken models (re-downloadable, ~1 GB) |

## Configuration

Non-secret env vars live in `apps/open-webui.yml` (`env:` list): PocketID OIDC
(`sso.mirekng.com`), `ENABLE_OAUTH_SIGNUP`, `OAUTH_MERGE_ACCOUNTS_BY_EMAIL`,
telemetry opt-outs.

Most Open WebUI settings (OpenAI connections, models, etc.) are *persistent
config* stored in `webui.db`, so changing the matching env var does not
override what is already saved — change them in Admin Settings instead.

### Secret `open-webui-secret`

Keys: `WEBUI_SECRET_KEY`, `OAUTH_CLIENT_SECRET`, `OPENAI_API_KEY`,
`OPENAI_API_ENDPOINT`. Injected with `envFrom`.

`WEBUI_SECRET_KEY` must never change — it signs sessions and encrypts stored
tokens. Recreate/rotate other keys with:

```sh
kubectl create secret generic open-webui-secret -n default \
  --from-literal=WEBUI_SECRET_KEY='<existing value>' \
  --from-literal=OAUTH_CLIENT_SECRET='<PocketID client secret>' \
  --from-literal=OPENAI_API_KEY='<key>' \
  --from-literal=OPENAI_API_ENDPOINT='<endpoint>' \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deploy/open-webui-deployment -n default
```

## Upgrading

1. Read the release notes — most minor releases carry DB migrations.
2. Back up first — consistent online SQLite snapshot via the backup API
   (safe while the app runs), written next to the live DB on the PVC:
   ```sh
   P=$(kubectl get pod -n default -l app=open-webui-selector -o name)
   kubectl exec -n default $P -- python3 -c "import sqlite3,datetime as d; s=sqlite3.connect('/app/backend/data/webui.db'); t=sqlite3.connect(f'/app/backend/data/webui.db.bak-{d.date.today()}'); s.backup(t); t.close()"
   ```
   `uploads/` and `vector_db/` are on the same hostPath
   (`/storage/config/open-webui`) if a full file-level copy is wanted.
3. Bump `image.tag` in `apps/open-webui.yml`, commit, push. The startup probe
   allows up to 10 minutes for migrations.

## Health checks

- `GET /health` → `{"status":true}` (startup/liveness/readiness probes)
- `GET /api/version`
- WebSocket: `/ws/socket.io/?EIO=4&transport=websocket` must return `101`
  (polling transport is intentionally rejected with "Invalid transport").

## Known issues / notes

- Traefik in this cluster has no global HTTP→HTTPS redirect; this chart adds
  its own Middleware. Other apps currently serve plain HTTP on port 80.
- Old Hetzner deployment (Dokploy project *OpenWebUI*, compose `open-webui`)
  is **stopped, not deleted**, with its volume intact, plus backup
  `/root/backups/open-webui-0.11.3-pre-k3s-migration-2026-10-28.tar.gz`
  (sha256 in `.sha256` next to it). Remove once the new setup is trusted.

## Changelog

- [2026-10-28](changelog/2026-10-28-open-webui.md) — Migrated from Dokploy/Hetzner to k3s, upgraded 0.11.3 → 0.12.4
