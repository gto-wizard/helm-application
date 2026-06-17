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
```

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
