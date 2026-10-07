# 2026-10-07 — Navidrome: initial deploy

## Summary

Added Navidrome (`deluan/navidrome:0.64.2`) at `music.mirekng.com`, same Helm/ArgoCD/volume layout as Jellyfin and the *arr stack.

## Why this image

Official `deluan/navidrome` is the documented image and includes ffmpeg for transcoding. linuxserver's `PUID`/`PGID` env vars do not apply here, so the pod runs as uid/gid 1000 via `securityContext`.

## Storage

- Config PV/PVC (`volumes/navidrome.volume.yml`) uses the Jellyfin model: `local-storage`, `ReadWriteMany`, label selector, hostPath `/storage/config/navidrome`.
- Music uses the existing `media-pvc` (`/ext-storage/media`), mounted at `/downloads`. `ND_MUSICFOLDER=/downloads/music` so the library sits next to movies/tv/anime on the same disk.

## Files changed

- `charts/navidrome/` — Deployment, Service, Ingress
- `apps/navidrome.yml` — ArgoCD Application, `music.mirekng.com`
- `volumes/navidrome.volume.yml` — config PV/PVC
- `docs/navidrome.md`
- `AGENTS.md` — active services table
