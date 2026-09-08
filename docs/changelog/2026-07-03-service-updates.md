# 2026-07-03 — Service version updates (batch)

Audited all ArgoCD apps against upstream registries/charts and updated those with newer releases. Each change was validated by rendering the affected chart with `helm template` before committing.

## Updated

| Service | From | To | Type | Notes |
|---------|------|-----|------|-------|
| radarr | `6.1.1` | `6.2.1` | minor | linuxserver image |
| sonarr | `4.0.17` | `4.0.19` | patch | linuxserver image |
| prowlarr | `2.3.5` | `2.4.0` | minor | linuxserver image |
| bazarr | `1.5.3` | `1.5.6` | patch | linuxserver image |
| qbittorrent | `5.2.0` | `5.2.2` | patch | linuxserver image |
| flaresolverr | `v3.4.6` | `v3.5.0` | minor | GHCR image |
| cert-manager | `v1.20.2` | `v1.20.3` | patch | jetstack chart |
| home-assistant | `2025.12.4` | `2026.7.0` | major | linuxserver image, ~7-month jump |
| external-secrets | `0.20.4` | `2.7.0` | major | ESO chart/app v0.20.4 -> v2.7.0 |

## Already up to date (no change)

- jellyfin `10.11.11`
- jellyseerr / seerr `v3.3.0`
- immich `v3.0.1` (see `2026-07-03-immich.md`)
- immich-db vectorchord `16.9-0.4.3`

## Skipped

- paperclip — pinned to `latest`, no explicit version to bump.
- argocd — the custom `charts/argocd` chart is only an ingress/config wrapper; ArgoCD itself is bootstrapped out-of-band.

## Major-version assessments

### external-secrets 0.20.4 -> 2.7.0

The version number jump is large, but the chart version now tracks the app version (chart `2.7.0` = ESO `v2.7.0`). Reviewed the release notes across the range:

- **v1.0.0**: API stabilization milestone. CRDs graduated from `v1alpha1` to `v1` (already served as `v1` in 0.20.x). No listed breaking changes.
- **v2.0.0**: BREAKING — removed the unmaintained **Alibaba** and **Device42** providers. This deployment uses **Infisical** (`secrets/infisical-store.yml`), so it is unaffected.

The `installCRDs=true` helm parameter still exists in chart 2.7.0 and was verified to render 24 CRDs. `helm template` produces the full controller + webhook + cert-controller manifest set with image `external-secrets:v2.7.0`, exit 0.

### home-assistant 2025.12.4 -> 2026.7.0

~7 months of monthly releases in one jump. HA frequently ships breaking changes to integrations/automations. Chart renders fine (it is only an image tag bump), but **watch the container logs and repair flow after rollout** for any deprecated/removed integrations. Config lives on `home-assistant-config-pvc` and is not managed by git.

## Validation method

For custom charts, rendered with the app's real values (via `--set` overrides matching each `apps/*.yml` valuesObject). For external charts (cert-manager, external-secrets), rendered directly from the upstream repo at the new version. All renders exited 0 with the expected new image tags / chart versions.

## Files changed

- `apps/radarr.yml`, `apps/sonarr.yml`, `apps/prowlarr.yml`, `apps/bazarr.yml`, `apps/qbittorrent.yml`, `apps/flaresolverr.yml`, `apps/cert-manager.yml`, `apps/home-assistant.yml`, `apps/external-secrets.yml`
