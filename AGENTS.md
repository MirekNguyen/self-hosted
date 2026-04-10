# AI Agent Context

Instructions and context for AI agents working on this repository.

## Repository overview

Self-hosted infrastructure running on a single-node k3s cluster (Beelink EQ14, Intel N150) managed by ArgoCD. The repo covers the full stack: Terraform for cloud VMs, Ansible for server provisioning, Helm charts for application deployment, and ArgoCD for GitOps.

- **Repo**: `https://github.com/MirekNguyen/self-hosted`
- **Branch**: `kubernetes`
- **Server**: Beelink EQ14 (Intel N150, Alder Lake-N)
- **Domain**: `*.mirekng.com`
- **User**: binh

## Deployment model

Everything is deployed via ArgoCD using an **app-of-apps** pattern. The root Application (`app-of-apps.yaml`) watches the `apps/` directory and creates child Applications from each YAML file.

**All changes must be committed and pushed to the `kubernetes` branch.** ArgoCD auto-syncs with `prune: true` and `selfHeal: true` — manual `kubectl apply` will be reverted.

### How to deploy a change

1. Edit files in `charts/` or `apps/`
2. Validate with `helm template <name> charts/<name> --set ...` (use inline `--set` flags since `apps/*.yml` are ArgoCD Application manifests, not raw values files)
3. Commit and push to `kubernetes` branch
4. ArgoCD picks it up automatically (or trigger a hard refresh: `kubectl patch application <name> -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'`)
5. If `apps/*.yml` changed, the app-of-apps must sync first before the child app sees updated values

## Directory structure

```
.
├── AGENTS.md                 # This file — AI agent context and repo conventions
├── app-of-apps.yaml          # Root ArgoCD Application, watches apps/
├── apps/                     # ArgoCD Application manifests (one per service)
│   ├── jellyfin.yml          # Custom chart (charts/jellyfin) with inline valuesObject
│   ├── sonarr.yml            # Custom chart (charts/sonarr)
│   ├── cert-manager.yml      # External Helm chart (charts.jetstack.io)
│   ├── external-secrets.yml  # External Helm chart (charts.external-secrets.io)
│   └── ...
├── charts/                   # Helm charts
│   ├── base/                 # Base chart templates (deployment, service, ingress)
│   ├── template/             # Scaffold for new charts with values.example.yaml
│   ├── jellyfin/             # Per-app chart with custom templates
│   ├── sonarr/
│   └── ...
├── docs/                     # Per-app documentation (findings, config, changelog)
│   ├── jellyfin.md
│   ├── sonarr.md
│   └── ...
├── volumes/                  # PV/PVC definitions (hostPath-based)
├── longhorn-volumes/         # Longhorn PV/PVC definitions (legacy/migrated)
├── secrets/                  # ExternalSecrets + ClusterSecretStore (Infisical)
├── terraform/                # Hetzner Cloud VMs (Dokploy server)
├── ansible/                  # Server provisioning (packages, Nix, dotfiles)
├── scripts/                  # Helper scripts (apply volumes, load env, create secrets)
├── archived/                 # Decommissioned app manifests
├── not-used/                 # Unused manifests (gitignored)
└── renovate.json             # Renovate bot config for automated dependency updates
```

## Application types

### Custom Helm charts (in `charts/`)

Most apps use a custom chart in `charts/<name>/` with templates for Deployment, Service, and Ingress. Values are passed inline via `spec.source.helm.valuesObject` in `apps/<name>.yml`.

Standard values shape (see `charts/template/values.example.yaml`):

```yaml
replicas: 1
namespace: default
appName: <name>
image:
  repository: <image>
  tag: <tag>
ports:
  containerPort: <port>
  servicePort: <port>
ingress:
  host: mirekng.com
  hostPrefix: <subdomain>
  sslSecretName: ssl-certificate
volumes:
  config:
    name: config-data
    pvc:
      mount: /config
      claimName: <name>-config-pvc
```

### External Helm charts

Some apps (cert-manager, external-secrets, argocd) reference external Helm repos directly in their `apps/*.yml` manifest with `repoURL` pointing to the upstream chart repository.

## Secrets management

Secrets are managed via **Infisical** through the **External Secrets Operator**:

1. `secrets/infisical-store.yml` — ClusterSecretStore connecting to Infisical
2. Apps reference ExternalSecret resources that pull from Infisical
3. Bootstrap secrets (Cloudflare API key, Infisical auth credentials) must be created manually with `kubectl create secret` (see `secrets/README.md`)

## Storage

- **Volumes**: hostPath-based PV/PVCs defined in `volumes/`. Data lives on the Beelink's local disk under `/storage/`.
- **Longhorn volumes**: Legacy PV/PVCs in `longhorn-volumes/` from when Longhorn was in use.
- **Filesystem layout**:
  - `/downloads` -> `/dev/sda1` (1.9TB HDD) — shared by qBittorrent, Sonarr, Radarr, Bazarr, Jellyfin
  - `/config` -> `/dev/nvme0n1p2` (468GB NVMe) — per-app config PVCs
  - Hardlinks work across all media apps because they share the same `/downloads` mount

## Key tools and paths

| Tool | Path |
|------|------|
| kubectl | `/run/current-system/sw/bin/kubectl` |
| helm | `/opt/homebrew/bin/helm` |
| User shell | fish (`/opt/homebrew/bin/fish`) |

## Active services

| Service | Subdomain | Chart | Purpose | Docs |
|---------|-----------|-------|---------|------|
| Jellyfin | tv.mirekng.com | custom | Media server (with subtitle proxy sidecar) | `docs/jellyfin.md` |
| Sonarr | sonarr.mirekng.com | custom | TV show management | `docs/sonarr.md` |
| Radarr | radarr.mirekng.com | custom | Movie management | `docs/radarr.md` |
| Bazarr | bazarr.mirekng.com | custom | Subtitle management | `docs/bazarr.md` |
| Prowlarr | prowlarr.mirekng.com | custom | Indexer management | `docs/prowlarr.md` |
| qBittorrent | qbittorrent.mirekng.com | custom | Torrent client | `docs/qbittorrent.md` |
| FlareSolverr | — | custom | Cloudflare challenge solver | `docs/flaresolverr.md` |
| Jellyseerr | jellyseerr.mirekng.com | custom | Media request management (Seerr v3) | `docs/jellyseerr.md` |
| Home Assistant | home.mirekng.com | custom | Home automation | — |
| ArgoCD | argocd.mirekng.com | external | GitOps deployment | — |
| cert-manager | — | external | TLS certificate automation (Let's Encrypt + Cloudflare DNS) | — |
| External Secrets | — | external | Secrets sync from Infisical | — |

## Conventions

- **Image tags**: Pinned to specific versions, updated by Renovate bot
- **Namespaces**: Most apps run in `default`, infrastructure in dedicated namespaces (argocd, cert-manager, external-secrets)
- **TLS**: Wildcard cert for `*.mirekng.com` via cert-manager with Cloudflare DNS-01 challenge
- **Sync policy**: All apps use `automated` sync with `prune: true` and `selfHeal: true`
- **Commit style**: Conventional commits (`feat`, `fix`, `build`, `chore`)

## Documentation structure

```
docs/
├── jellyfin.md                        # Per-app: current state, findings, known issues
├── sonarr.md
├── ...
└── changelog/
    ├── 2026-04-10-jellyfin.md         # Detailed changelog: what changed, why, decisions
    └── 2026-04-10-media-stack.md
```

### Per-app docs (`docs/<app>.md`)

Current truth about an application: architecture, configuration, connections, known issues. Updated in place when the state changes. Links to related changelog entries at the bottom.

### Changelog entries (`docs/changelog/YYYY-MM-DD-<app>.md`)

Append-only detailed log of changes. One file per day per topic. Contains:

- Problem statement and investigation findings
- Solution implemented with files changed
- Decisions and tradeoffs made
- Hardware/software references discovered

Future agent instances should:
1. Read `AGENTS.md` (this file) for repo-wide context
2. Read `docs/<app>.md` for the specific app being worked on
3. Create new changelog entries in `docs/changelog/` for any significant changes made
