# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Universal Helm chart (`application`) used to deploy all GTO Wizard services to Kubernetes. Consumed as an OCI dependency from `oci://ghcr.io/gto-wizard/helm-application/charts`.

## Common Commands

```bash
# Lint the chart
helm lint .

# Template render (dry-run) with default values
helm template my-release .

# Template render with custom values
helm template my-release . -f custom-values.yaml

# Full CI lint+test (requires chart-testing CLI and kind)
ct lint --target-branch main
ct install --target-branch main
```

## CI/CD Workflows

- **`lint-and-test.yml`** — PRs touching `values.yaml` or `templates/**` trigger `ct lint` + `ct install` (spins up a kind cluster).
- **`chart-metadata.yml`** — PRs auto-update `Chart.yaml` version (via release-drafter) and regenerate `README.md` from `values.yaml` `@param` annotations using `@bitnami/readme-generator-for-helm`. These changes are committed automatically — do not manually edit `README.md` or the `version` field in `Chart.yaml`.
- **`release.yml`** — Merges to `main` publish a release and push the chart to GHCR with the major version as the chart version.
- **`release-dev.yml`** — Pushes to non-main branches publish a dev chart with a full semver from GitVersion.

## Architecture

### Value Inheritance Pattern

The chart uses a two-tier value system: `common.*` provides defaults inherited by all workload types, while workload-specific sections (`application.*`, `cronjob.*`, job entries) can override them. For fields like `nodeSelector`, `tolerations`, `affinity`, `podSecurityContext`, and `containerSecurityContext`, the template uses `workload-specific | default common` — so workload values take full precedence when set.

Environment variables follow a merge pattern: `common.env` is merged with workload-specific `env` via Helm's `merge`. Additionally, `common.extraEnv` (YAML list format) is appended separately via helper templates (`application.extraEnv`, `cronjob.extraEnv`).

### Template Helpers (`_helpers.tpl`)

- `application.name` — release name (or `nameOverride`), truncated to 63 chars
- `application.labels` — full label set (selector + version/component/partOf/managedBy/chart + extraLabels)
- `application.selectorLabels` — just name + instance for matchLabels
- `application.image` — resolves image reference with precedence: `overrideTag` > `shasum` (digest) > `tag`
- `application.render` — recursively renders values containing Go templates (used for parentRefs, hostnames, etc.)
- `application.extraEnv` / `cronjob.extraEnv` — merge extra env from workload + common

### Workload Types

| Template | Controlled by | Notes |
|----------|--------------|-------|
| `app-deployment.yaml` | `application.enabled` + `application.kind: Deployment` | Main workload |
| `app-statefulset.yaml` | `application.enabled` + `application.kind: StatefulSet` | Alternative to Deployment |
| `job.yaml` | `application.jobs[]` list | Iterates over job definitions; jobs inherit from `application.*` and `common.*` |
| `cronjob.yaml` | `cronjob.enabled` | Separate value section (`cronjob.*`), supports `nameSuffix` |

### Networking & Ingress

- `service.yaml` — ClusterIP service (configurable type/ports)
- `ingress.yaml` — single Ingress resource
- `ingresses.yaml` — multiple Ingress resources via `ingresses[]` list
- `httproute.yaml` — Gateway API HTTPRoute; rules use `application.render` so values can contain Go templates

### Scaling

- `hpa-app.yaml` — HPA when `application.autoscaling.enabled`
- `scaledobject.yaml` — KEDA ScaledObject when `keda.enabled`
- `httpscaledobject.yaml` — KEDA HTTPScaledObject when `keda.httpScaledObject.enabled`
- HPA and KEDA are mutually exclusive; both suppress the static `replicaCount`

### Supporting Resources

- `configmap.yaml` — from `configmap.data` when `configmap.enabled`
- `externalsecret.yaml` — ExternalSecrets operator integration via `externalSecrets.secrets[]`
- `serviceaccount.yaml`, `role.yaml`, `rolebinding.yaml` — RBAC
- `servicemonitor.yaml` — Prometheus ServiceMonitor
- `pvc.yaml` — PersistentVolumeClaim
- `poddisruptionbudget.yaml` — PDB
- `extra-objects.yaml` — escape hatch for arbitrary K8s manifests via `extraObjects[]`

## Skills

Claude Code skills in `.claude/skills/`:

- `add-helm-template` — add a new Kubernetes resource template to the chart
- `fix-helm-template` — diagnose and fix template bugs (nil pointer, type mismatch, wrong scope, missing labels)

## Conventions

- `README.md` is auto-generated — document parameters using `@param` / `@section` annotations in `values.yaml`
- Chart version uses major-only versioning (currently `"13"`)
- Commit messages follow conventional commits (e.g., `fix(httproute/template):`, `OPS-375(httproute):`)
