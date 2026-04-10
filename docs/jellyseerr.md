# Jellyseerr (Seerr)

Server: `jellyseerr.mirekng.com`
Image: `ghcr.io/seerr-team/seerr` (migrated from `fallenbagel/jellyseerr`)

## Migration to Seerr v3

Jellyseerr was renamed to Seerr in v3.0.0. The project merged Overseerr and Jellyseerr into a single codebase under `seerr-team/seerr`. Key migration changes:

- **Image**: `fallenbagel/jellyseerr:2.7.3` -> `ghcr.io/seerr-team/seerr:v3.0.1`
- **Runs as non-root**: UID 1000 (`node` user) — init container chowns config on first start
- **Security context**: drops all capabilities, no privilege escalation, seccomp profile
- **Auto-migration**: data migrates automatically on first start with the new image

### Files changed

- `apps/jellyseerr.yml` — new image, securityContext, podSecurityContext, initContainers
- `charts/jellyseerr/templates/deployment.yml` — added support for securityContext, podSecurityContext, initContainers

## Configuration

- **Media server**: Jellyfin (`jellyfin-service.default.svc.cluster.local:8096`)
- **External hostname**: `https://tv.mirekng.com` (links back to Jellyfin, not Jellyseerr itself)
- **Radarr**: `radarr-service.default.svc.cluster.local:7878`, profile: HD-1080p, root: `/downloads/movies`
- **Sonarr**: `sonarr-service.default.svc.cluster.local:8989`, profile: HD-1080p
  - TV root: `/downloads/tv-shows`
  - Anime root: `/downloads/anime`
  - `enableSeasonFolders`: true

### Jellyfin libraries

| ID | Name | Type |
|----|------|------|
| `0c41907140d802bb58430fed7e2cd79e` | Anime | show |
| `f137a2dd21bbc1b99aa5c0f6bf02a805` | Movies | movie |
| `767bffe4f11c93ef34b805451a696a4e` | TV Shows | show |

### Jobs

| Job | Schedule |
|-----|----------|
| jellyfin-recently-added-scan | Every 5 min |
| jellyfin-full-scan | 3:00 AM daily |
| radarr-scan | 4:00 AM daily |
| sonarr-scan | 4:30 AM daily |
| availability-sync | 5:00 AM daily |
| download-sync | Every minute |

## Known issues

None currently.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Migrated to Seerr v3.0.1, fixed enableSeasonFolders, fixed externalHostname
