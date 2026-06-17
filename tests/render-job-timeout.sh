#!/usr/bin/env bash
# Render-only assertion harness for the optional Job activeDeadlineSeconds/backoffLimit passthrough.
#
# Why `helm template`, not a chart-testing `ci/` fixture: CI's lint-and-test.yml runs `ct install`
# on a real kind cluster, which would actually deploy any `ci/*-values.yaml` fixture. These fixtures
# carry a placeholder image, so an installed Job would sit in ImagePullBackOff — the exact hang this
# whole change exists to bound. So these cases are asserted by rendering, never by installing.
#
# Run from the chart root:  bash tests/render-job-timeout.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# No 2>&1 capture: a non-zero `helm template` exit must propagate so `set -e` kills the
# harness loudly. Capturing stderr would let a broken render flow into the assertions and
# pass vacuously (assert_absent matching the error string instead of real output).
render() { helm template r . -f "tests/$1" --show-only templates/job.yaml; }

fail() { echo "FAIL: $1"; exit 1; }
# Proves the render actually produced a Job, so assert_absent can't pass on non-Job output.
assert_rendered() {
  if ! echo "$2" | grep -qE "^kind: Job[[:space:]]*$"; then fail "$1 (render produced no Job)"; fi
}
assert_absent() {
  if echo "$2" | grep -qE "^[[:space:]]*$1:"; then fail "$3 (expected '$1' absent)"; fi
}
assert_value() {
  if ! echo "$2" | grep -qE "^[[:space:]]*$1: $3[[:space:]]*$"; then fail "$4 (expected '$1: $3')"; fi
}

# Case 1: unset -> neither line rendered (no regression for existing consumers)
out="$(render job-timeout-unset-values.yaml)"
assert_rendered "unset" "$out"
assert_absent "activeDeadlineSeconds" "$out" "unset"
assert_absent "backoffLimit"          "$out" "unset"
echo "ok: unset -> both lines absent"

# Case 2: literal 0 -> both lines emitted as 0 (nil-aware guard honors 0; `with` would drop it)
out="$(render job-timeout-zero-values.yaml)"
assert_rendered "zero" "$out"
assert_value "activeDeadlineSeconds" "$out" "0" "zero"
assert_value "backoffLimit"          "$out" "0" "zero"
echo "ok: zero -> activeDeadlineSeconds: 0 / backoffLimit: 0 emitted"

# Case 3: positive -> both lines emitted with the set values
out="$(render job-timeout-set-values.yaml)"
assert_rendered "positive" "$out"
assert_value "activeDeadlineSeconds" "$out" "600" "positive"
assert_value "backoffLimit"          "$out" "3"   "positive"
echo "ok: positive -> activeDeadlineSeconds: 600 / backoffLimit: 3 emitted"

echo "PASS: all 3 cases (unset / zero / positive)"
