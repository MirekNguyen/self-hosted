# Bazarr

Server: `bazarr.mirekng.com`
Image: `linuxserver/bazarr`

## Configuration

- **API key**: stored in app config (`/config/config/config.yaml`)
- **Branch**: master
- **Analytics**: disabled
- **Database**: SQLite (can use PostgreSQL, currently disabled)

### Connections

- **Sonarr**: `sonarr-service.default.svc.cluster.local:8989` (via SignalR)
- **Radarr**: `radarr-service.default.svc.cluster.local:7878` (via SignalR)

### Subtitle providers

| Provider | Status |
|----------|--------|
| opensubtitlescom | Active (free account, rate-limited with 10-min backoff on 426 errors) |
| supersubtitles | Active |
| gestdown | Active |
| embeddedsubtitles | Active (extracts from video files via ffprobe) |

### Settings

- `minimum_score`: 90 (series), 70 (movies)
- `upgrade_subs`: true (upgrade frequency: 12h)
- `use_embedded_subs`: true
- `embedded_subtitles_parser`: ffprobe
- `adaptive_searching`: true (delay: 3w, delta: 1w)
- `wanted_search_frequency`: 6h (both series and movies)
- `multithreading`: true
- `utf8_encode`: true
- `only_monitored`: true (both Sonarr and Radarr — only search subs for monitored content)

## Known issues

- **OpenSubtitles.com throttling**: Free accounts get rate-limited (HTTP 426). Bazarr handles this automatically with 10-minute backoff cycles. Not an error — expected behavior.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Disabled analytics
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Set only_monitored to true for Sonarr and Radarr
