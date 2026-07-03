# Immich

Server: `photos.mirekng.com`
Chart: `oci://ghcr.io/immich-app/immich-charts/immich` (external Helm chart)

## Architecture

Immich is deployed via the upstream `immich-charts` OCI Helm chart, with values passed inline through `apps/immich.yml`. It runs three workloads:

| Component | Image | Purpose |
|-----------|-------|---------|
| Server | `ghcr.io/immich-app/immich-server:v3.0.1` | API + web + microservices |
| Machine learning | `ghcr.io/immich-app/immich-machine-learning:v3.0.1` | CLIP search, face detection |
| Valkey | `docker.io/valkey/valkey:9.1-alpine` | Redis-compatible queue/cache (chart-managed) |

The PostgreSQL database is deployed separately (see below), not by the Immich chart.

## Database

Immich uses a dedicated PostgreSQL instance with the VectorChord extension, managed by a custom chart:

- App manifest: `apps/immich-db.yml`
- Chart: `charts/immich-db`
- Image: `ghcr.io/tensorchord/cloudnative-vectorchord:16.9-0.4.3`
- Service: `immich-postgres-service:5432` (namespace `immich`)
- Postgres starts with `shared_preload_libraries=vchord.so`, `--data-checksums`, `PGDATA=/var/lib/postgresql/data/pgdata`
- Storage: `immich-db-pvc` (5Gi, `local-storage`, hostPath `/storage/config/immich-db`) — see `volumes/immich-db.volume.yml`

Immich `v3` requires VectorChord (pgvecto.rs support was dropped). This deployment already uses VectorChord, so no extension migration is needed.

## Configuration

Connection env (set in `apps/immich.yml`):

| Var | Value |
|-----|-------|
| `DB_HOSTNAME` | `immich-postgres-service` |
| `DB_PORT` | `5432` |
| `DB_DATABASE_NAME` | `immich` |
| `DB_USERNAME` | `immich` |
| `DB_PASSWORD` | `immich` |
| `REDIS_HOSTNAME` | `immich-valkey` |

Storage:

- Photo library: `photos-pvc` (`immich.persistence.library.existingClaim`)

Ingress:

- Host `photos.mirekng.com`, TLS secret `ssl-certificate`
- `nginx.ingress.kubernetes.io/proxy-body-size: "0"` (unlimited upload size)

Namespace: `immich` (created by ArgoCD via `CreateNamespace=true`).

## Known issues

None currently.

## Changelog

- [2026-07-03](changelog/2026-07-03-immich.md) — Upgraded to v3.0.1 (chart 0.13.1); confirmed VectorChord migration already in place
