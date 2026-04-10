# 2026-04-10 — Media stack audit and optimization

Audited Sonarr, Radarr, Prowlarr, Bazarr, FlareSolverr, and qBittorrent.

## Issues found and fixed

### HIGH: 1337x indexer IP banned by Cloudflare

- **Problem**: 1337x in Prowlarr was returning 403 Forbidden on every request. FlareSolverr (linked via tag) confirmed: `"Cloudflare has blocked this request. Probably your IP is banned."` Error code 1006 — the Beelink's public IP is blocked at the Cloudflare level.
- **Fix**: Disabled 1337x indexer in Prowlarr via API. Remaining indexers: The Pirate Bay, Nyaa.si, YTS.
- **Note**: Re-enabling requires a different public IP (VPN/proxy) or waiting for the ban to lift.

### HIGH: Sonarr not using hardlinks

- **Problem**: `copyUsingHardlinks: false` in Sonarr media management. Files were being **copied** instead of hardlinked during import. Since qBittorrent, Sonarr, and Radarr all share the same `/downloads` filesystem (`/dev/sda1`), hardlinks work and save disk space + I/O.
- **Fix**: Enabled via API (`PUT /api/v3/config/mediamanagement/1`). Radarr already had this correct.

### HIGH: Sonarr ntfy notifications failing (401 Unauthorized)

- **Problem**: Health check: "All notifications are unavailable due to failures." The ntfy.sh server (`ntfy.mirekng.com`) is reachable but returns HTTP 401 when Sonarr tries to authenticate as user `binh`. The password stored in Sonarr is wrong or the ntfy user credentials have changed.
- **Action needed**: User must verify/reset the ntfy password for user `binh` on `ntfy.mirekng.com`, then update it in Sonarr Settings > Connect > ntfy.sh.

### MEDIUM: Radarr not importing subtitle files

- **Problem**: `importExtraFiles: false`. Subtitle files (.srt) next to movie files were not being imported during Radarr import. Sonarr already had this enabled.
- **Fix**: Enabled `importExtraFiles: true` with `extraFileExtensions: "srt"` via API.

### MEDIUM: qBittorrent seeding time too aggressive

- **Problem**: `GlobalMaxSeedingMinutes=1`. Torrents stopped seeding after just 1 minute. This can cause poor ratios and bans from trackers that require minimum seeding.
- **Fix**: Changed to `GlobalMaxSeedingMinutes=60` (1 hour) via config file edit. Pod restarted to apply.

### LOW: Dead download client and notification configs

- **Problem**: Both Sonarr and Radarr had a disabled Transmission download client (id 3) left over from migration. Sonarr also had a "Ruddarr" webhook notification (id 2) with all events disabled.
- **Fix**: Deleted via API (`DELETE /api/v3/downloadclient/3`, `DELETE /api/v3/notification/2`).

### LOW: Bazarr analytics enabled

- **Problem**: `analytics.enabled: true` was sending usage telemetry.
- **Fix**: Set to `false` in `/config/config/config.yaml`. Pod restarted to apply.

## Image updates

Updated via ArgoCD app manifests (`apps/*.yml`):

| Service | Before | After |
|---------|--------|-------|
| Sonarr | 4.0.16 | 4.0.17 |
| Radarr | 6.0.4 | 6.1.1 |
| Prowlarr | 2.3.0 | 2.3.5 |

## Observations (no action needed)

### FlareSolverr

- Working correctly. Responding to Prowlarr pings in ~1s. Chrome 142 on the pod.
- Only used for 1337x (now disabled). If all remaining indexers work without Cloudflare challenges, FlareSolverr is idle but harmless to keep running.

### Bazarr OpenSubtitles.com throttling

- Getting `426` errors from opensubtitlescom, cycling with 10-minute backoff. This is normal for free OpenSubtitles accounts — rate limiting. Bazarr handles it automatically.

### Bazarr provider config

- Active providers: opensubtitlescom, supersubtitles, gestdown, embeddedsubtitles
- Connected to Sonarr (`sonarr-service.default.svc.cluster.local:8989`) and Radarr (`radarr-service.default.svc.cluster.local:7878`) via SignalR
- Using in-cluster service DNS names — correct for k8s.

### qBittorrent

- Download speed limit: 5000 KB/s (configurable via WebUI)
- Max active downloads: 5, max active uploads: 5
- DHT/PEX enabled, UPnP disabled (correct for k8s)
- Incomplete downloads in `/downloads/incomplete/`, completed in `/downloads/`

### Filesystem layout

All media containers share the same volumes:
- `/downloads` → `/dev/sda1` (1.9TB, 86% used, 267GB free)
- `/config` → `/dev/nvme0n1p2` (468GB, 25% used)

Hardlinks work across Sonarr/Radarr/qBittorrent because `/downloads` is the same mount.

## Files changed (git)

- `apps/sonarr.yml` — image tag 4.0.16 -> 4.0.17
- `apps/radarr.yml` — image tag 6.0.4 -> 6.1.1
- `apps/prowlarr.yml` — image tag 2.3.0 -> 2.3.5

## Config changes (applied to running pods via API/config files)

These persist on PVCs but are not managed by git:

- Prowlarr: 1337x indexer disabled
- Sonarr: `copyUsingHardlinks` enabled, `importExtraFiles` enabled
- Radarr: `importExtraFiles` enabled
- Sonarr: Transmission download client removed, Ruddarr webhook removed
- Radarr: Transmission download client removed
- qBittorrent: `GlobalMaxSeedingMinutes` 1 -> 60
- Bazarr: `analytics.enabled` false

## Manual action required

- **ntfy notifications**: Verify/reset password for user `binh` on `ntfy.mirekng.com` and update in Sonarr Settings > Connect > ntfy.sh
- **Commit and push** the image tag changes to `kubernetes` branch for ArgoCD deployment
