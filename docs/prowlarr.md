# Prowlarr

Server: `prowlarr.mirekng.com`
Image: `linuxserver/prowlarr`

## Configuration

- **API key**: stored in app config (`/config/config.xml`)
- **Branch**: master
- **Auth**: Forms (required)
- **Database**: SQLite

### Indexers

| ID | Name | Protocol | Enabled | Notes |
|----|------|----------|---------|-------|
| 2 | 1337x | torrent | **No** | IP banned by Cloudflare (403 / error 1006). Tagged with FlareSolverr but Cloudflare blocks the server IP outright. |
| 3 | The Pirate Bay | torrent | Yes | Working |
| 4 | Nyaa.si | torrent | Yes | Working — anime/Asian content |
| 5 | YTS | torrent | Yes | Working — movies only |

### Indexer proxies

- **FlareSolverr** (id 1) — `http://flaresolverr-service.default.svc.cluster.local:8191`, tag: `flaresolverr` (id 1), timeout: 60s

### Indexer priorities

| Indexer | Priority | Rationale |
|---------|----------|-----------|
| Nyaa.si | 1 | Best for anime |
| 1337x | 2 | Disabled (IP banned) |
| The Pirate Bay | 3 | General purpose |
| YTS | 5 | Movies only, smaller files |

### Settings

- **Analytics**: disabled

### Sync targets

Prowlarr syncs indexers to Sonarr and Radarr automatically. Any indexer changes in Prowlarr propagate to both.

## Known issues

- **1337x IP banned**: The Beelink's public IP is blocked by Cloudflare for 1337x.to. FlareSolverr cannot bypass this (it's an IP-level block, not a challenge). Re-enabling requires routing through a VPN/proxy or waiting for the ban to lift.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Disabled 1337x indexer (IP banned), image update 2.3.0 -> 2.3.5
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Disabled analytics, fixed YTS priority (25 -> 5)
