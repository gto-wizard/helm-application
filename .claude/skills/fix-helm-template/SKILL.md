---
name: fix-helm-template
description: Diagnose and fix a bug in a helm-application template. Use when a template produces invalid YAML, a nil pointer error, wrong types, missing labels/annotations, or incorrect rendering.
---

# Fix Helm Template Bug

Diagnoses and fixes template bugs in the shared `helm-application` chart. Covers the most common failure patterns seen in this repo's history.

## Step 1: Reproduce the error locally

```bash
cd repos/helm-application

# Render with defaults — surfaces nil pointer and structural errors
helm template my-release . 2>&1

# Render with the feature enabled
helm template my-release . --set <feature>.enabled=true 2>&1

# Add --debug for full template output including partial renders
helm template my-release . --set <feature>.enabled=true --debug 2>&1

# Lint — catches type errors, required field violations, YAML structure issues
helm lint .

# Render with a custom values file (closest to real usage)
helm template my-release . -f /path/to/values.yaml 2>&1
```

The error message usually names the template file and line number. Go there first.

---

## Common bug patterns

### 1. Nil pointer: `nil pointer evaluating interface {}.field`

**Cause:** Accessing a nested field without checking the parent object exists.

```yaml
# BAD — crashes if image is nil
imagePullSecrets: {{ .Values.application.image.pullSecrets }}

# GOOD — guard with `with`
{{- with $.Values.image.pullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
```

**Real example (PR #9):** Job template accessed `.image.pullSecrets` at the wrong path. The correct path is `$.Values.image.pullSecrets` (top-level `image`, not inside `application`).

**Fix pattern:** Check `_helpers.tpl` and `values.yaml` for the exact key path. Use `with` to guard optional nested access.

---

### 2. Wrong `$` vs `.` scope inside `range`

**Cause:** Inside a `range` block, `.` becomes the current iteration item. Using `.` to access chart-level values (like `.Values`, `.Release`, `.Chart`) returns nil or the item's fields instead.

```yaml
# BAD — inside range, .Values is nil
{{- range .Values.application.jobs }}
  labels:
    {{- include "application.labels" . | nindent 8 }}  # WRONG: . is the job item
{{- end }}

# GOOD — use $ for chart root, . for current item
{{- range .Values.application.jobs }}
  labels:
    {{- include "application.labels" $ | nindent 8 }}  # $ always refers to chart root
  {{- with .labels }}{{- toYaml . | nindent 4 }}{{- end }}  # . is the job item
{{- end }}
```

**Real example (PR #12):** Job pods were missing standard labels and annotations because `include "application.labels" .` passed the job item instead of the chart root. Fixed by using `$`.

**Rule:** In any `range` or `with` block, always use `$` for helpers and `.Values.*` access. Use `.` only for the current item's own fields.

---

### 3. Type mismatch: integer rendered as string

**Cause:** YAML values that must be integers (port numbers, replica counts) are sometimes rendered as strings by Helm's template engine when pulled from values.

```yaml
# BAD — port comes out as "8080" (string) which is invalid for port fields
port: {{ .Values.service.port }}

# GOOD — force integer type
port: {{ .Values.service.port | int }}
```

**Real example (PR #15):** HTTPRoute `backendRefs` port number was rendered as a string. Fixed by piping through `| int`.

**When this matters:** Kubernetes strictly validates `port`, `replicas`, `minReplicas`, `maxReplicas`, `targetPort`, and similar integer fields. Always use `| int` for these.

---

### 4. Wrong selector helper name

**Cause:** Using a helper that doesn't exist or returns more labels than expected for `matchLabels` / `selector`.

```yaml
# BAD — .app suffix doesn't exist on this helper
selector:
  matchLabels:
    {{- include "application.selectorLabels.app" . | nindent 4 }}

# GOOD — use the actual helper name
selector:
  matchLabels:
    {{- include "application.selectorLabels" . | nindent 4 }}
```

**Real example (PR #7):** PodDisruptionBudget selector used `application.selectorLabels.app` which doesn't exist. The correct helper is `application.selectorLabels`.

**Available helpers** (see `templates/_helpers.tpl`):

| Helper | Returns |
|--------|---------|
| `application.name` | Release name (or `nameOverride`), max 63 chars |
| `application.labels` | Full label set — use in `metadata.labels` |
| `application.selectorLabels` | Minimal labels (`name` + `instance`) — use in `selector.matchLabels` |
| `application.image` | Resolved image ref (handles tag/digest/overrideTag precedence) |
| `application.render` | Renders Go templates embedded in values |
| `application.extraEnv` | Merges `application.extraEnv` + `common.extraEnv` (nindent 12) |
| `cronjob.extraEnv` | Merges `cronjob.extraEnv` + `common.extraEnv` (nindent 14) |
| `application.serviceAccountName` | Resolved service account name |

---

### 5. `application.render` needed for dynamic values

**Cause:** Values that contain Go template expressions (e.g., `{{ .Release.Name }}`) are not expanded by Helm automatically when passed through `toYaml`. They need `application.render`.

```yaml
# BAD — Go templates inside values are rendered as literal strings
hostnames: {{- toYaml .Values.httpRoute.hostnames | nindent 4 }}

# GOOD — application.render evaluates Go templates inside the value
hostnames: {{- include "application.render" (dict "value" .Values.httpRoute.hostnames "context" $) | nindent 4 }}
```

**When to use:** Any value that consumers might set to a Go template expression (hostnames, parentRefs, backendRefs, resource names referencing `.Release.Name`).

---

### 6. Missing `---` separator between multi-resource templates

**Cause:** Templates that emit multiple resources (e.g., `job.yaml` loops over `application.jobs[]`) need `---` between each document.

```yaml
# GOOD pattern — separator at end of each iteration
{{- range .Values.application.jobs }}
apiVersion: batch/v1
kind: Job
# ...
---
{{- end -}}
```

Without `---`, multiple documents merge into invalid YAML.

---

## Step 2: Verify the fix

```bash
# Confirm the template renders without errors
helm template my-release . --set <feature>.enabled=true

# Confirm lint passes
helm lint .

# For type issues, check the specific field renders correctly
helm template my-release . --set <feature>.enabled=true | grep -A2 "port:"
```

## Step 3: Open a fix PR

```bash
git checkout -b fix(<scope>): <short description>
git add templates/<file>.yaml
git commit -m "fix(<scope>): <description of what was wrong and what was fixed>"
git push -u origin HEAD
gh pr create --title "fix(<scope>): <description>"
```

CI (`ct lint` + `ct install`) runs automatically. Chart version is auto-bumped on merge.

## Quick reference: which template owns what

| Symptom | Template to check |
|---------|-------------------|
| Nil pointer on pod labels/annotations | `job.yaml`, `cronjob.yaml`, `app-deployment.yaml` |
| Wrong selector on HPA/PDB | `hpa-app.yaml`, `poddisruptionbudget.yaml` |
| Port rendered as string | `service.yaml`, `httproute.yaml`, `ingress.yaml` |
| Dynamic hostname/parentRef not resolving | `httproute.yaml` — needs `application.render` |
| ExternalSecret not mounting | `externalsecret.yaml` — check `externalSecrets.enabled` + `secrets[]` |
| imagePullSecrets missing on Jobs | `job.yaml` — use `$.Values.image.pullSecrets`, not `application.image.*` |
