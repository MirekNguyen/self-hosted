# 2026-04-10 Media Stack Optimization

Full configuration optimization pass across all media stack services.

## Changes

### Jellyfin
- **RemoteClientBitrateLimit**: 1 Mbps -> 0 (unlimited). The 1 Mbps cap was forcing heavy transcoding for remote clients, degrading quality and increasing N150 CPU load unnecessarily. Clients adapt based on their own bandwidth.
- **LibraryMonitorDelay**: 60s -> 15s. Faster library refresh after Sonarr/Radarr imports.

### Jellyseerr (migrated to Seerr v3)
- **Image migration**: `fallenbagel/jellyseerr:2.7.3` -> `ghcr.io/seerr-team/seerr:v3.0.1`
  - Project renamed from Jellyseerr to Seerr (merged with Overseerr)
  - v3.0.1 includes security patches (CVE-2026-27707, CVE-2026-27793, CVE-2026-27792)
  - Container now runs as non-root (UID 1000)
- **Deployment template** updated: added `podSecurityContext`, `securityContext`, `initContainers` support
- **Init container**: chowns `/app/config` to 1000:1000 for the non-root user
- **enableSeasonFolders**: false -> true. Without this, episodes weren't organized into season folders.
- **externalHostname**: `jellyseerr.mirekng.com` -> `tv.mirekng.com`. Should point to Jellyfin, not Jellyseerr.

### Prowlarr
- **analyticsEnabled**: true -> false
- **YTS priority**: 25 -> 5. Was deprioritized too much for a movie indexer.

### Radarr
- **renameMovies**: enabled with TRaSH-style naming format
- **Quality upgrades**: enabled for HD-1080p profile (cutoff: Bluray-1080p)
- **Ruddarr webhook**: removed (all triggers were disabled — dead notification)

### Sonarr
- **renameEpisodes**: enabled with TRaSH-style naming format (includes absolute episode numbering for anime)
- **Quality upgrades**: enabled for HD-1080p profile (cutoff: Bluray-1080p)
- **ntfy triggers**: enabled onGrab, onDownload, onImportComplete (were all disabled, so no notifications on new downloads)
- Note: ntfy still fails with 401 — password needs manual reset

### Bazarr
- **only_monitored**: false -> true (both Sonarr and Radarr). Stops wasting provider quota searching subtitles for unmonitored content.

### qBittorrent
- **GlobalMaxSeedingMinutes**: confirmed fixed to 60 in config file (was still 1 in the config despite previous session's change)
- **Incomplete directory**: created `/downloads/incomplete/` (was configured as temp path but didn't exist)
- **Cleanup**: removed `.DS_Store` and `._.DS_Store` from `/downloads` root
- **VueTorrent WebUI**: enabled via `DOCKER_MODS=ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest`
  - qBittorrent v5.1.4's built-in alternative WebUI path setting is broken (HTTP 500 for any path)
  - The DOCKER_MODS approach installs VueTorrent during container init via linuxserver.io's mod system
  - Deployment template updated with `extraEnv` support for passing additional env vars from values

## Files changed (in git)
- `apps/jellyseerr.yml` — new image, security context, init container
- `apps/qbittorrent.yml` — added `extraEnv.DOCKER_MODS` for VueTorrent
- `charts/jellyseerr/templates/deployment.yml` — template supports securityContext, podSecurityContext, initContainers
- `charts/qbittorrent/templates/deployment.yml` — template supports `extraEnv` map for additional env vars

## Orphaned content noted
- `/downloads/James Bond Die Another Day (2002) [1080p]` (1.9GB) — sits in root of downloads, not managed by Radarr. Should be moved to `/downloads/movies/` or deleted.

## Cross-service integration verified
All connections tested and working:
- Sonarr -> qBittorrent
- Radarr -> qBittorrent
- Prowlarr -> Sonarr (full sync)
- Prowlarr -> Radarr (full sync)
- Bazarr -> Sonarr (v4.0.17)
- Bazarr -> Radarr (v6.1.1)
- Jellyseerr -> Jellyfin, Sonarr, Radarr
