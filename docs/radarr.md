# Radarr

Server: `radarr.mirekng.com`
Image: `linuxserver/radarr`

## Configuration

- **API key**: stored in app config (`/config/config.xml`)
- **Branch**: master
- **Auth**: Forms (required)
- **Analytics**: disabled
- **Database**: SQLite

### Root folders

| Path | Purpose |
|------|---------|
| `/downloads/movies` | Movies |

### Download client

- **qBittorrent** (id 4) — connected, enabled

### Indexers (via Prowlarr)

- The Pirate Bay — enabled
- Nyaa.si — enabled
- YTS — enabled
- 1337x — disabled (IP banned by Cloudflare, see Prowlarr docs)

### Media management

- `copyUsingHardlinks`: true — hardlinks work because `/downloads` is the same filesystem across all media apps
- `importExtraFiles`: true (`srt`)
- `downloadPropersAndRepacks`: preferAndUpgrade
- `createEmptyMovieFolders`: false
- `deleteEmptyFolders`: false
- `rescanAfterRefresh`: always

### Naming

- `renameMovies`: true
- `standardMovieFormat`: `{Movie CleanTitle} ({Release Year}) [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}`
- `movieFolderFormat`: `{Movie CleanTitle} ({Release Year})`
- `colonReplacementFormat`: dash

### Quality profiles in use

- Any, SD, HD-720p, HD-1080p (upgrades enabled, cutoff: Bluray-1080p), Ultra-HD, HD-720p/1080p

### Notifications

- **ntfy.sh** (id 1) — server: `ntfy.mirekng.com`, user: `binh`, topic: `radarr`

## Known issues

None currently.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Enabled extra file import (.srt), removed dead Transmission client, image update 6.0.4 -> 6.1.1
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Enabled movie renaming, enabled quality upgrades for HD-1080p, removed dead Ruddarr webhook
