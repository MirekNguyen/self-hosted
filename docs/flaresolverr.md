# FlareSolverr

Internal service (no public subdomain)
Image: `ghcr.io/flaresolverr/flaresolverr`

## Configuration

- **Port**: 8191
- **Service DNS**: `flaresolverr-service.default.svc.cluster.local:8191`
- **Browser**: Chromium 142 (bundled)
- **Platform**: Linux x86_64

## Purpose

Solves Cloudflare challenges for Prowlarr indexers. Prowlarr routes requests through FlareSolverr via indexer proxy tags.

## Current status

Working correctly. Responds to Prowlarr health pings in ~1s. However, currently idle since its only consumer (1337x) is disabled due to an IP ban.

## Known issues

- **Exposed via ingress**: `apps/flaresolverr.yml` has an ingress definition (`flaresolverr.mirekng.com`). FlareSolverr is an internal service with no auth — exposing it publicly is a security risk. Consider removing the ingress or restricting access.

## Changelog

- [2026-04-10](changelog/2026-04-10-media-stack.md) — Audited, no changes needed. 1337x (only consumer) disabled.
