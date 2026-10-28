# 2026-10-28 — Open WebUI: migrate Dokploy/Hetzner → k3s, upgrade 0.11.3 → 0.12.4

## Summary

`chat.mirekng.com` moved from a Dokploy compose on the Hetzner VM
(`ghcr.io/open-webui/open-webui:0.11.3`, Docker volume
`openwebui-openwebui-ee6dwe_open-webui`) to the k3s cluster on the Beelink,
with all data preserved and the app upgraded to `0.12.4`.

## Source (before)

- Dokploy project *OpenWebUI*, compose `open-webui` (`Ygryh19FXbXBwJE02VJFQ`)
- Traefik (Dokploy) with Let's Encrypt, HTTP→HTTPS redirect
- PocketID OIDC (`sso.mirekng.com`), OpenAI-compatible endpoint via env
- DNS: no explicit record; resolved through `*.mirekng.com → 195.201.18.24`
- Data: 1.3 GB (`webui.db` 90 MB + WAL, `uploads/` 127 MB, `vector_db/` 13 MB, `cache/` 1.1 GB)

## Procedure

1. Wrote `charts/open-webui`, `apps/open-webui.yml`, `volumes/open-webui.volume.yml`;
   validated with `helm lint`, `helm template` and `kubectl apply --dry-run=server`.
2. Applied PV/PVC; used a temporary alpine pod mounting the PVC as the copy
   target (no sudo on the node needed).
3. Live pre-copy of `cache/` (static models) via
   `ssh hetzner tar | kubectl exec -i … tar -x`.
4. Created `open-webui-secret` directly from the running container's env
   (piped, never written to disk/output).
5. **Downtime start** — stopped the compose through Dokploy (`compose-stop`,
   exit 0).
6. Backup on Hetzner:
   `/root/backups/open-webui-0.11.3-pre-k3s-migration-2026-10-28.tar.gz`
   (+ `.sha256`, mode 600).
7. Full re-copy of the stopped volume; verified identical `sha256` of
   `webui.db` and `webui.db-wal`, 139 files on both sides.
8. `PRAGMA integrity_check` → `ok`. Baseline: 1 user, 38 chats, 34 files,
   alembic `d4c1a8e37b62`.
9. Pushed, synced ArgoCD. First start ran 8 Alembic migrations
   (`d4c1a8e37b62 → 0bd252b206fb`). Post-migration: 1 user, 38 chats,
   34 files, integrity `ok`.
10. Verified via `--resolve` to the Beelink IP before DNS: `/health`,
    `/api/version` (0.12.4), wildcard cert valid, OIDC login 302 → PocketID
    with unchanged client id / redirect URI.
11. **DNS cutover** — Cloudflare A `chat.mirekng.com → 109.239.79.2`,
    unproxied, TTL auto (record id `c6a8e52c6f02fd44020aea38c8177be7`).
    Confirmed on Cloudflare authoritative NS, 1.1.1.1, 8.8.8.8, 9.9.9.9.
12. Verified WebSocket upgrade (`101`) and added a Traefik `redirectScheme`
    Middleware to restore the HTTP→HTTPS redirect Dokploy provided.

Downtime: ~5 minutes (stop → pod ready), plus client DNS cache (TTL 300 s).

## Decisions

- **`strategy: Recreate`, 1 replica** — SQLite on RWO hostPath; 0.12.x release
  notes state rolling updates are unsupported during migrations.
- **Startup probe up to 10 min** — first boot after an upgrade runs migrations.
- **Root UID kept, all capabilities dropped** — upstream image writes into
  `/app/backend` as root and data is root-owned; `allowPrivilegeEscalation:
  false`, `capabilities.drop: [ALL]`, seccomp `RuntimeDefault`.
- **Plain k8s Secret (not Infisical)** — chosen by the owner; documented
  recreation command in `docs/open-webui.md`. `OAUTH_CLIENT_SECRET` moved out
  of the compose file (it was plaintext there) into the Secret.
- **PV `type: DirectoryOrCreate`, `Retain`, `claimRef`** — explicit host dir
  creation and pinned PV↔PVC binding.
- **Explicit DNS record** rather than repointing the wildcard — other Hetzner
  services still rely on `*.mirekng.com`.
- Dropped `extra_hosts: host.docker.internal` — no local Ollama in k3s.

## Rollback

1. Delete Cloudflare record `chat.mirekng.com` (falls back to wildcard → Hetzner).
2. Start the Dokploy compose (`compose-start Ygryh19FXbXBwJE02VJFQ`) — it still
   has the original 0.11.3 data. Chats created after cutover would be lost
   (0.12 DB cannot be opened by 0.11).

## Side fix: Hetzner SSH key auth

`/root`, `/root/.ssh` and `authorized_keys` on Hetzner were owned by UID 1000,
so sshd (`StrictModes yes`) refused all public keys ("bad ownership or modes").
Chowned back to `root:root`; key auth works again.

## Follow-ups

- Delete the stopped Dokploy compose + volume and the backup tarball after a
  grace period.
- Consider a cluster-wide Traefik HTTP→HTTPS redirect (`HelmChartConfig` for
  the k3s Traefik `web` entrypoint) — currently no other app redirects.
