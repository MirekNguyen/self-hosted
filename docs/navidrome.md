# Navidrome

Server: `music.mirekng.com`
Image: `deluan/navidrome:0.64.2`

Music server with Subsonic/OpenSubsonic API. First visit to the UI creates the admin user.

## Architecture

```
Client -> Ingress (music.mirekng.com:443) -> Service (:4533) -> Navidrome (:4533)
```

Runs as uid/gid 1000 (official image, no PUID/PGID). Data and cache live on the config PVC; the library is the shared media volume.

## Storage

| Mount | PVC | Host path | Purpose |
|-------|-----|-----------|---------|
| `/data` | `navidrome-config-pvc` | `/storage/config/navidrome` | DB, cache, config |
| `/downloads` | `media-pvc` | `/ext-storage/media` | Shared media disk |
| `/downloads/music` | (same PVC) | `/ext-storage/media/music` | Music library (`ND_MUSICFOLDER`) |

## Notes

- Official image ignores `PUID`/`PGID`. Pod `securityContext` sets `runAsUser`/`runAsGroup`/`fsGroup` to 1000.
- Music folder must exist on the host before the first scan, or the library stays empty.
- Transcoding cache and artwork live under `/data`. Bump the config PVC if it grows past 1Gi.

## Changelog

- [2026-10-07](changelog/2026-10-07-navidrome.md) — Initial deploy
