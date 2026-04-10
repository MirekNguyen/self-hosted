# Jellyfin

Server: `tv.mirekng.com`
Hardware: Beelink EQ14 (Intel N150, Alder Lake-N / Twin Lake, Gen12.2 GPU)

## Architecture

Traffic flows through an OpenResty sidecar proxy before reaching Jellyfin:

```
Client -> Ingress (tv.mirekng.com:443) -> Service (:8096) -> subtitle-proxy (:8097) -> Jellyfin (:8096)
```

### Subtitle burn-in proxy

Neither Streamyfin nor Fladder sends the `AlwaysBurnInSubtitleWhenTranscoding` flag in their PlaybackInfo requests. Without it, Jellyfin strips subtitle streams during transcoding (`-map -0:s`) and never applies a burn-in filter.

The sidecar proxy (`openresty/openresty:alpine`) intercepts `POST /Items/*/PlaybackInfo` requests and injects `"AlwaysBurnInSubtitleWhenTranscoding":true` into the JSON body. This only affects transcoded playback — direct play is unaffected since the server doesn't touch the stream.

**Files:**
- `charts/jellyfin/templates/subtitle-proxy-configmap.yml` — OpenResty/nginx config with Lua injection script
- `charts/jellyfin/templates/deployment.yml` — sidecar container definition
- `charts/jellyfin/templates/service.yml` — `targetPort` routes to proxy (8097) instead of Jellyfin (8096)
- `apps/jellyfin.yml` — `subtitleProxy` values (image, port)

## Hardware encoding (Intel N150 / QSV)

### Supported codecs

| Codec | HW Decode | HW Encode | HW Encode LP |
|-------|-----------|-----------|--------------|
| H.264 | Yes | Yes | Yes |
| HEVC 8-bit | Yes | Yes | Yes |
| HEVC 10-bit | Yes | Yes | Yes |
| HEVC 12-bit | Yes | Yes | No |
| VP8 | Yes | No | No |
| VP9 (all profiles) | Yes | No | Yes (LP only) |
| AV1 | Decode only | No | No |
| MPEG2 | Yes | Yes | No |
| VC1 | Yes | No | No |

### encoding.xml settings

Key settings and rationale for the N150:

| Setting | Value | Reason |
|---------|-------|--------|
| `HardwareAccelerationType` | `qsv` | Intel Quick Sync Video |
| `QsvDevice` | `/dev/dri/renderD128` | GPU render node |
| `EnableHardwareEncoding` | `true` | Use GPU for encoding |
| `EnableIntelLowPowerH264HwEncoder` | `true` | N150 supports LP H.264 encode |
| `EnableIntelLowPowerHevcHwEncoder` | `true` | N150 supports LP HEVC encode |
| `AllowHevcEncoding` | `true` | Preferred output codec, smaller files |
| `AllowAv1Encoding` | `false` | N150 has no AV1 encode hardware |
| `EnableVppTonemapping` | `true` | QSV VPP for HDR-to-SDR tonemapping (hardware) |
| `EnableTonemapping` | `false` | Software tonemapping off, VPP handles it |
| `PreferSystemNativeHwDecoder` | `true` | Prefer native Intel QSV/VA-API decode path |
| `EnableEnhancedNvdecDecoder` | `false` | NVIDIA-only, irrelevant for Intel |
| `EnableThrottling` | `false` | Disabled for low-latency seeking and playback |
| `EnableAudioVbr` | `true` | Better audio quality at same bitrate |
| `EnableSegmentDeletion` | `true` | Clean up old HLS segments to reduce disk I/O |
| `EnableSubtitleExtraction` | `true` | Extract subs to avoid full remux |
| `EnableFallbackFont` | `true` | Fallback font for ASS/SSA subtitle rendering |
| `EnableDecodingColorDepth10Hevc` | `true` | 10-bit HEVC decode supported |
| `EnableDecodingColorDepth10Vp9` | `true` | 10-bit VP9 decode supported |
| `EnableDecodingColorDepth10HevcRext` | `true` | HEVC RExt 10-bit decode supported |
| `EnableDecodingColorDepth12HevcRext` | `true` | HEVC RExt 12-bit decode supported |

### system.xml settings

| Setting | Value | Reason |
|---------|-------|--------|
| `RemoteClientBitrateLimit` | `0` | Unlimited — no artificial cap on remote streaming quality |
| `LibraryMonitorDelay` | `15` | Faster library refresh after Sonarr/Radarr imports (default 60) |

### User settings

- Subtitle mode set to "Always" via API to ensure subtitles are selected for every playback session.

## Useful commands

```bash
# Check VA-API capabilities
kubectl exec -n default deployment/jellyfin-deployment -c jellyfin -- \
  /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128

# Check QSV initialization
kubectl exec -n default deployment/jellyfin-deployment -c jellyfin -- \
  /usr/lib/jellyfin-ffmpeg/ffmpeg -v verbose -init_hw_device qsv=hw \
  -filter_hw_device hw -f lavfi -i nullsrc -t 0.1 -an -f null -

# Check active transcode commands
kubectl exec -n default deployment/jellyfin-deployment -c jellyfin -- \
  ps aux | grep ffmpeg
```

## Notes

- The `encoding.xml` is stored on the Jellyfin config PVC (`/storage/config/jellyfin` on the host, mounted at `/config` in the container). Changes persist across pod restarts but are NOT managed by git — apply via `kubectl exec`.
- The deployment requires `privileged: true` and `/dev/dri` host path mount for GPU access.
- The pod runs with `supplementalGroups: [44]` (video group) for render node permissions.

## Changelog

- [2026-04-10](changelog/2026-04-10-jellyfin.md) — Subtitle burn-in proxy, encoding optimization for N150
- [2026-04-10](changelog/2026-04-10-media-stack-optimization.md) — Removed 1 Mbps remote bitrate cap, reduced library monitor delay
