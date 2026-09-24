# Render tests

`helm template`-only assertion harness — these fixtures are **not** chart-testing `ci/` install fixtures.

CI's `lint-and-test.yml` runs `ct install` on a real kind cluster, which deploys any
`ci/*-values.yaml` fixture it discovers. The fixtures here carry a placeholder image, so an
installed Job would sit in `ImagePullBackOff` — the exact hang the `activeDeadlineSeconds`
passthrough exists to bound. So these cases are verified by rendering, never by installing, and
live under `tests/` (not `ci/`) so `ct install` never picks them up.

## Run

```bash
bash tests/render-job-timeout.sh
bash tests/render-keda-replicas.sh
bash tests/render-networkpolicy.sh
```

CI (`lint-and-test.yml`) runs every `tests/render-*.sh`.

## Coverage

`render-job-timeout.sh` asserts the optional Job `activeDeadlineSeconds` / `backoffLimit`
passthrough across three cases:

| Fixture | Case | Expected |
|---------|------|----------|
| `job-timeout-unset-values.yaml` | neither set | both lines absent (no regression) |
| `job-timeout-zero-values.yaml` | literal `0` | both lines emitted as `0` (pins the nil-aware guard) |
| `job-timeout-set-values.yaml` | positive | `activeDeadlineSeconds: 600` / `backoffLimit: 3` |

The zero case exists to permanently pin the fix: a `{{- with }}` guard silently drops `0` and lets
K8s fall back to its default `backoffLimit: 6` — the opposite of the `backoffLimit: 0`
("fail immediately") convention used by gtowiz-dwh prod jobs in `k8s-resources`.

`render-keda-replicas.sh` asserts the optional `keda.initialReplicas` Deployment `.spec.replicas`
passthrough (OPS-919) across three cases, all with `keda.enabled: true`:

| Fixture | Case | Expected |
|---------|------|----------|
| `keda-replicas-unset-values.yaml` | `initialReplicas` unset | `replicas` line absent (byte-identical to today — KEDA owns it) |
| `keda-replicas-zero-values.yaml` | literal `0` | `replicas: 0` emitted (pins the nil-aware guard; scale-to-zero-from-cold) |
| `keda-replicas-set-values.yaml` | positive | `replicas: 3` emitted |

The zero case exists to permanently pin the behavior: a `{{- with }}` guard silently drops `0` and
lets the Deployment default to 1 on a cold namespace — an unschedulable pod / first-sync Degraded
flap in ephemeral preview envs, the exact footgun this opt-in exists to remove.

`render-networkpolicy.sh` asserts the opt-in `networkPolicy` template (OPS-1470). For each
`netpol-<app>-values.yaml` fixture, the rendered spec must equal `netpol-<app>-expected.yaml`.
The gto-brain-mcp and dwh-mcp expected files are the two policies of k8s-resources #15385.
The webapp-django case proves that a sidecar target port (8080) is resolved to its number.
It also checks: off by default, `allowAll`, and a render failure for an unknown target port name.
