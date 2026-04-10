# Sonarr

Server: `sonarr.mirekng.com`
Image: `linuxserver/sonarr`

## Configuration

- **API key**: stored in app config (`/config/config.xml`)
- **Branch**: main
- **Auth**: Forms (required)
- **Analytics**: disabled
- **Database**: SQLite

### Root folders

| Path | Purpose |
|------|---------|
| `/downloads/anime` | Anime series |
| `/downloads/tv-shows` | TV shows |

### Download client

- **qBittorrent** (id 4) — connected, enabled

### Indexers (via Prowlarr)

- The Pirate Bay — enabled
- Nyaa.si — enabled
- 1337x — disabled (IP banned by Cloudflare, see Prowlarr docs)

### Notifications

- **ntfy.sh** (id 1) — server: `ntfy.mirekng.com`, user: `binh`, topic: `sonarr`

### Media management

- `copyUsingHardlinks`: true — hardlinks work because `/downloads` is the same filesystem across all media apps
- `importExtraFiles`: true (`srt`)
- `downloadPropersAndRepacks`: preferAndUpgrade
- `createEmptySeriesFolders`: true
- `deleteEmptyFolders`: true
- `rescanAfterRefresh`: always

### Quality profiles in use

- Any, SD, HD-720p, HD-1080p (upgrades enabled, cutoff: Bluray-1080p), Ultra-HD, HD-720p/1080p

### Naming

- `renameEpisodes`: true
- `standardEpisodeFormat`: `{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Quality Full}]{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}`
- `animeEpisodeFormat`: includes `{absolute:000}` for absolute episode numbering
- `seriesFolderFormat`: `{Series TitleYear}`
- `seasonFolderFormat`: `Season {season:00}`

## Known issues

- **ntfy notifications failing (401)**: The password for user `binh` on `ntfy.mirekng.com` is wrong or expired. Needs manual reset in Sonarr Settings > Connect > ntfy.sh. Triggers are correctly configured (onGrab, onDownload, onImportComplete all enabled).

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Enabled hardlinks, enabled extra file import, removed dead Transmission client and Ruddarr webhook, image update 4.0.16 -> 4.0.17
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Enabled episode renaming, enabled quality upgrades for HD-1080p, fixed ntfy notification triggers
