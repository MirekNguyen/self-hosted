# Prowlarr

Server: `prowlarr.mirekng.com`
Image: `linuxserver/prowlarr`

## Configuration

- **API key**: stored in app config (`/config/config.xml`)
- **Branch**: master
- **Auth**: Forms (required)
- **Database**: SQLite

### Indexers

| ID | Name | Protocol | Enabled | Priority | Min Seeders | Notes |
|----|------|----------|---------|----------|-------------|-------|
| 2 | 1337x | torrent | Yes | 2 | 5 | General TV/movies, uses FlareSolverr, mirror: `www.1337xx.to` |
| 3 | The Pirate Bay | torrent | Yes | 3 | 5 | General purpose |
| 4 | Nyaa.si | torrent | Yes | 1 | 2 | Anime/Asian content, sonarr/radarr compatibility enabled |
| 5 | YTS | torrent | Yes | 5 | - | Movies only, small files |
| 7 | EZTV | torrent | Yes | 3 | 5 | TV-only (scene releases), uses FlareSolverr, URL: `eztvx.to` |
| 8 | LimeTorrents | torrent | Yes | 5 | 5 | TV/movies fallback |

### Indexer proxies

- **FlareSolverr** (id 1) — `http://flaresolverr-service.default.svc.cluster.local:8191`, tag: `flaresolverr` (id 1), timeout: 60s
- Used by: 1337x, EZTV

### Indexer priorities

| Indexer | Priority | Rationale |
|---------|----------|-----------|
| Nyaa.si | 1 | Best for anime (SubsPlease, Erai-raws) |
| 1337x | 2 | Good general coverage |
| EZTV | 3 | Scene releases for western TV |
| The Pirate Bay | 3 | General fallback |
| YTS | 5 | Movies only, smaller files |
| LimeTorrents | 5 | Fallback for season packs |

### Settings

- **Analytics**: disabled

### Sync targets

Prowlarr syncs indexers to Sonarr and Radarr automatically. Any indexer changes in Prowlarr propagate to both.

## Known issues

None currently.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Disabled 1337x indexer (IP banned), image update 2.3.0 -> 2.3.5
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Disabled analytics, fixed YTS priority (25 -> 5)
- [2026-04-10](changelog/2026-04-10-indexer-overhaul.md) — Added EZTV and LimeTorrents, fixed min seeders, enabled Nyaa.si compatibility
