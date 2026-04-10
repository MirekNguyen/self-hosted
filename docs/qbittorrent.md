# qBittorrent

Server: `qbittorrent.mirekng.com`
Image: `linuxserver/qbittorrent`

## Configuration

- **WebUI user**: binh
- **WebUI alternative UI**: VueTorrent (installed via `DOCKER_MODS=ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest`)
- **CSRF protection**: disabled (required for reverse proxy access)
- **Clickjacking protection**: disabled (required for reverse proxy access)

### Download settings

| Setting | Value |
|---------|-------|
| Default save path | `/downloads/` |
| Temp/incomplete path | `/downloads/incomplete/` |
| Download speed limit | 5000 KB/s |
| Upload speed limit | unlimited (0) |
| Max active downloads | 5 |
| Max active uploads | 5 |
| Queueing | enabled |
| Add torrent stopped | false (starts immediately) |

### Seeding settings

| Setting | Value |
|---------|-------|
| Max seeding time | 60 minutes |
| Max inactive seeding time | unlimited (-1) |
| Share limit action | Stop |

### Network

| Setting | Value |
|---------|-------|
| Listening port | 6881 |
| UPnP | disabled (correct for k8s) |
| DHT | enabled (via Preferences) |
| PEX | enabled (via proxy profiles) |
| Port forwarding | enabled |

### Logging

- File logging enabled, max 65KB, 1 day age, auto-delete old logs, backup enabled

## VueTorrent

Installed via linuxserver.io `DOCKER_MODS` mechanism, not the qBittorrent "Alternative WebUI" config setting. The mod (`ghcr.io/vuetorrent/vuetorrent-lsio-mod:latest`) installs VueTorrent during container init and configures qBittorrent to use it automatically.

**Why not the built-in Alternative WebUI setting?** qBittorrent v5.1.4 returns HTTP 500 "Unacceptable file type, only regular file is allowed" when setting `alternative_webui_path` via either the config file or the API. This appears to be a v5 bug or security restriction that blocks all alternative WebUI paths regardless of content.

## Known issues

None currently.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Seeding time changed from 1 minute to 60 minutes
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Fixed seeding time in config file, created incomplete directory, cleaned up .DS_Store files, added VueTorrent via DOCKER_MODS
