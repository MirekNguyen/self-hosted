# 2026-04-10 Indexer Overhaul

Overhauled indexer configuration across Prowlarr, Sonarr, and Radarr to fix missing content issues caused by overly aggressive seeder filters, missing indexers, broken release profiles, and missing Nyaa.si compatibility.

## Problems identified

1. **1337x minimum seeders = 50** — rejected most K-drama and older content (typically 5-20 seeders). Caused 0% download rate for Alchemy of Souls, Death's Game, Move to Heaven, etc.
2. **TPB minimum seeders = 30** — same problem.
3. **Nyaa.si sonarr/radarr compatibility disabled** — Sonarr couldn't properly parse Nyaa results with absolute episode numbering.
4. **Sonarr release profile broken** — "Subsplease | Erai" profile used `required: ["subsplease", "erai"]` which is AND logic (both must match). No release matches both, so it blocked everything.
5. **No EZTV indexer** — missing the best public indexer for western TV scene releases.
6. **No fallback indexers** — only 4 indexers total, no redundancy.
7. **Radarr RSS sync interval = 30min** — slower than Sonarr (15min), missing fresh well-seeded releases.

## Changes

### Prowlarr

- **1337x minimum seeders**: 50 -> 5
- **TPB minimum seeders**: 30 -> 5
- **Nyaa.si minimum seeders**: 0 -> 2
- **Nyaa.si sonarr_compatibility**: false -> true (proper episode parsing)
- **Nyaa.si radarr_compatibility**: false -> true
- **Added EZTV** (ID=7): priority 3, min seeders 5, FlareSolverr tag, base URL `eztvx.to`
- **Added LimeTorrents** (ID=8): priority 5, min seeders 5, fallback for season packs
- **TorrentGalaxy**: attempted but site is dead/redirecting, skipped

### Sonarr

- **Deleted broken release profile** "Subsplease | Erai" (required AND logic blocked all releases)
- **Created custom format "SubsPlease"**: regex `\bSubsPlease\b`, score +1000 in HD-1080p profile
- **Created custom format "Erai-raws"**: regex `\bErai-raws\b`, score +500 in HD-1080p profile
- **minFormatScore = 0**: prefer SubsPlease/Erai but don't reject other sources
- New indexers synced: EZTV, LimeTorrents

### Radarr

- **RSS sync interval**: 30min -> 15min
- Indexer min seeders synced from Prowlarr

## Seeder strategy

Minimum seeders set to sensible floors per indexer:
- **5** for general indexers (1337x, TPB, EZTV, LimeTorrents) — filters truly dead torrents while allowing niche K-drama/older content
- **2** for Nyaa.si — anime can have fewer seeders but still works (dedicated community)
- **1** for YTS — YTS always has good seeders for movies

Sonarr/Radarr's release selection algorithm already prefers higher quality + custom format score. For same-quality ties, indexer priority determines which source is tried first.

## Final indexer state

| Indexer | Priority | Min Seeders | Syncs to | FlareSolverr |
|---------|----------|-------------|----------|-------------|
| Nyaa.si | 1 | 2 | Sonarr, Radarr | No |
| 1337x | 2 | 5 | Sonarr, Radarr | Yes |
| EZTV | 3 | 5 | Sonarr only | Yes |
| The Pirate Bay | 3 | 5 | Sonarr, Radarr | No |
| YTS | 5 | 1 | Radarr only | No |
| LimeTorrents | 5 | 5 | Sonarr only | No |
