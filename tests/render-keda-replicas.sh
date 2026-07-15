#!/usr/bin/env bash
# Render-only assertion harness for the optional keda.initialReplicas Deployment `.spec.replicas`
# passthrough (OPS-919).
#
# Why `helm template`, not a chart-testing `ci/` fixture: CI's lint-and-test.yml runs `ct install`
# on a real kind cluster, which would actually deploy any `ci/*-values.yaml` fixture. These fixtures
# carry a placeholder image, so an installed Deployment would sit in ImagePullBackOff. So these
# cases are asserted by rendering, never by installing (mirrors tests/render-job-timeout.sh).
#
# Run from the chart root:  bash tests/render-keda-replicas.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# No 2>&1 capture: a non-zero `helm template` exit must propagate so `set -e` kills the harness
# loudly. Capturing stderr would let a broken render flow into the assertions and pass vacuously.
render() { helm template r . -f "tests/$1" --show-only templates/app-deployment.yaml; }

fail() { echo "FAIL: $1"; exit 1; }
# Proves the render actually produced a Deployment, so assert_absent can't pass on non-Deployment output.
assert_rendered() {
  if ! echo "$2" | grep -qE "^kind: Deployment[[:space:]]*$"; then fail "$1 (render produced no Deployment)"; fi
}
assert_absent() {
  if echo "$2" | grep -qE "^[[:space:]]*$1:"; then fail "$3 (expected '$1' absent)"; fi
}
assert_value() {
  if ! echo "$2" | grep -qE "^[[:space:]]*$1: $3[[:space:]]*$"; then fail "$4 (expected '$1: $3')"; fi
}

# Case 1: keda.enabled, initialReplicas unset -> no replicas line (byte-identical to today; KEDA owns it)
out="$(render keda-replicas-unset-values.yaml)"
assert_rendered "unset" "$out"
assert_absent "replicas" "$out" "unset"
echo "ok: keda + unset -> replicas line absent (existing consumers unchanged)"

# Case 2: initialReplicas: 0 -> replicas: 0 emitted (nil-aware guard honors 0; `with` would drop it)
out="$(render keda-replicas-zero-values.yaml)"
assert_rendered "zero" "$out"
assert_value "replicas" "$out" "0" "zero"
echo "ok: keda + 0 -> replicas: 0 emitted (scale-to-zero-from-cold)"

# Case 3: positive initialReplicas -> replicas: 3 emitted
out="$(render keda-replicas-set-values.yaml)"
assert_rendered "positive" "$out"
assert_value "replicas" "$out" "3" "positive"
echo "ok: keda + 3 -> replicas: 3 emitted"

echo "PASS: all 3 cases (unset / zero / positive)"
