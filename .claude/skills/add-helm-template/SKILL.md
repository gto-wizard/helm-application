---
name: add-helm-template
description: Add a new template to the shared helm-application chart. Use when a new Kubernetes resource type needs to be supported by the universal chart (e.g., new CRD, new workload pattern, new supporting resource).
---

# Add Helm Template

Adds a new template file to the shared `helm-application` chart, which is consumed as an OCI dependency by all GTO Wizard services.

> **Impact:** Changes here affect every service that depends on this chart. Test thoroughly before releasing.

## Repository

**Path:** `repos/helm-application/`
**OCI registry:** `oci://ghcr.io/gto-wizard/helm-application/charts`
**Consumed by:** All apps in `k8s-resources/applications/*/` via `Chart.yaml` OCI dependency

## Architecture overview

The chart uses a **two-tier value system**:
- `common.*` — defaults inherited by all workload types
- Workload-specific sections (`application.*`, `cronjob.*`, job entries) — override common values

Templates use the helper `application.render` for dynamic values (Go template rendering inside values).

## Step 1: Add values to `values.yaml`

Define the new feature's values with:
- Sensible defaults (use `false` / `{}` / `[]` for opt-in features)
- `@param` annotations for README auto-generation
- Consistent structure with existing sections

```yaml
## @section My New Feature
## @param myFeature.enabled Enable my new feature
## @param myFeature.someField Description of this field
myFeature:
  enabled: false
  someField: ""
```

**Conventions:**
- Use `enabled: false` as the default for new opt-in features — never enable by default
- Follow the existing naming style: `camelCase` keys, flat where possible
- Document every field with `## @param` so README is auto-generated correctly

## Step 2: Add the template file

Create `templates/<feature-name>.yaml`. Follow the pattern of existing templates:

```yaml
{{- if .Values.myFeature.enabled }}
apiVersion: <group>/<version>
kind: <Kind>
metadata:
  name: {{ include "application.name" . }}
  labels: {{- include "application.labels" . | nindent 4 }}
spec:
  # ... resource spec ...
  # Reference values: .Values.myFeature.someField
{{- end }}
```

### Available helper templates (`_helpers.tpl`)

| Helper | Output |
|--------|--------|
| `application.name` | Release name (or `nameOverride`), max 63 chars |
| `application.labels` | Full label set (selector + version + component + chart + managedBy) |
| `application.selectorLabels` | Minimal labels for `matchLabels` |
| `application.image` | Resolved image reference (handles tag/digest/overrideTag precedence) |
| `application.render` | Recursively renders Go templates embedded in values |
| `application.extraEnv` | Merges `application.extraEnv` + `common.extraEnv` |
| `cronjob.extraEnv` | Merges `cronjob.extraEnv` + `common.extraEnv` |

### List-based resources (multiple instances)

For features that can have multiple instances (e.g., multiple jobs, ingresses):

```yaml
{{- range .Values.myFeature.items }}
---
apiVersion: <group>/<version>
kind: <Kind>
metadata:
  name: {{ include "application.name" $ }}-{{ .name }}
  labels: {{- include "application.labels" $ | nindent 4 }}
spec:
  # ... use . for item fields, $ for root ...
{{- end }}
```

## Step 3: Validate locally

```bash
cd repos/helm-application

# Lint the chart
helm lint .

# Template render with defaults (should produce no output for disabled features)
helm template my-release .

# Template render with feature enabled
helm template my-release . --set myFeature.enabled=true --set myFeature.someField=example

# Full CI test (requires chart-testing + kind)
ct lint --target-branch main
```

Fix any lint errors before opening a PR. The CI pipeline runs `ct lint` + `ct install` automatically.

## Step 4: Do NOT manually edit

- **`README.md`** — auto-generated from `@param` annotations in `values.yaml` by `chart-metadata.yml` CI workflow
- **`Chart.yaml` version field** — auto-bumped by `chart-metadata.yml` CI workflow
- **`Chart.lock`** — not applicable (this chart has no dependencies)

## Step 5: Open PR

```bash
git checkout -b feat/<scope>-<description>
git add templates/<feature>.yaml values.yaml
git commit -m "feat(<scope>): add <feature> template"
git push -u origin HEAD
gh pr create --title "feat(<scope>): add <feature> template"
```

CI will:
1. Lint and test the chart
2. Auto-update `Chart.yaml` version
3. Regenerate `README.md`
4. On merge: publish new chart version to GHCR

## Step 6: Update consuming charts (if needed)

After the chart is released, services consuming it via `k8s-resources` may need their `Chart.yaml` dependency version updated:

```yaml
# In k8s-resources/applications/<app>/<env>/Chart.yaml
dependencies:
  - name: application
    version: "15"  # bump to new major version
    repository: oci://ghcr.io/gto-wizard/helm-application/charts
    alias: <component>
```

Run `helm dependency build` in the affected env dir, then update `Chart.lock` in the PR.

## Existing template reference

| Template | Enabled by | Notes |
|----------|-----------|-------|
| `app-deployment.yaml` | `application.enabled` + `application.kind: Deployment` | Main workload |
| `app-statefulset.yaml` | `application.enabled` + `application.kind: StatefulSet` | Alternative to Deployment |
| `cronjob.yaml` | `cronjob.enabled` | Separate value section |
| `job.yaml` | `application.jobs[]` list | Multiple jobs supported |
| `service.yaml` | `service.enabled` | ClusterIP service (configurable type/ports) |
| `configmap.yaml` | `configmap.enabled` | ConfigMap |
| `ingress.yaml` | `ingress.enabled` | Single ingress |
| `ingresses.yaml` | `ingresses[]` list | Multiple ingresses |
| `httproute.yaml` | `httpRoute.enabled` | Gateway API HTTPRoute |
| `hpa-app.yaml` | `application.autoscaling.enabled` | CPU/memory HPA |
| `scaledobject.yaml` | `keda.enabled` | KEDA advanced scaling |
| `httpscaledobject.yaml` | `kedaHttp.enabled` | KEDA HTTP scaling |
| `externalsecret.yaml` | `externalSecrets.enabled` + `externalSecrets.secrets[]` list | External Secrets operator |
| `servicemonitor.yaml` | `serviceMonitor.enabled` | Prometheus scraping |
| `serviceaccount.yaml` | `serviceAccount.create` | ServiceAccount |
| `role.yaml` | `rbac.enabled` + `rbac.roles[]` list | RBAC Role (multiple via loop) |
| `rolebinding.yaml` | `rbac.enabled` + `rbac.roles[]` list | RBAC RoleBinding |
| `pvc.yaml` | `application.persistentVolumes[]` list | PersistentVolumeClaims |
| `poddisruptionbudget.yaml` | `application.podDisruptionBudget` object present | PDB |
| `extra-objects.yaml` | `extraObjects[]` | Arbitrary K8s manifests |

## Common pitfalls

- Not guarding with `{{- if .Values.feature.enabled }}` — always make features opt-in
- Forgetting to document with `## @param` — README won't include the new field
- Hardcoding names instead of using `application.name` helper
- Forgetting `$` vs `.` scope in `range` blocks
- Manually editing `README.md` or `Chart.yaml` version — CI overwrites these
