#!/usr/bin/env bash
# Render-only assertions for the opt-in networkPolicy template (OPS-1470).
# Run from the chart root:  bash tests/render-networkpolicy.sh
set -euo pipefail

cd "$(dirname "$0")/.."

render() { helm template r . -f "tests/netpol-$1-values.yaml" "${@:2}"; }
fail() { echo "FAIL: $1"; exit 1; }

# Golden cases: the NetworkPolicy spec must match the expected file byte for byte.
for app in gto-brain-mcp dwh-mcp webapp-django; do
  diff <(render "$app" --show-only templates/networkpolicy.yaml | sed -n '/^spec:/,$p') \
       <(grep -v '^#' "tests/netpol-$app-expected.yaml") || fail "$app spec differs from expected"
  echo "ok: $app"
done

# Off by default: neither the chart defaults nor an explicit enabled=false render a policy.
! helm template r . --set httpRoute.enabled=true | grep -q '^kind: NetworkPolicy' || fail "default renders a policy"
! render dwh-mcp --set networkPolicy.enabled=false | grep -q '^kind: NetworkPolicy' || fail "enabled=false renders a policy"
echo "ok: disabled -> no NetworkPolicy"

# Break-glass: one allow-all rule.
out="$(render dwh-mcp --set networkPolicy.allowAll=true --show-only templates/networkpolicy.yaml)"
[[ "$(sed -n '/^  ingress:/,$p' <<<"$out")" == $'  ingress:\n    - {}' ]] || fail "allowAll is not ingress: [{}]"
echo "ok: allowAll -> ingress: [{}]"

# A target port name that matches no port must fail the render, not open a wrong port.
if err="$(render dwh-mcp --set service.targetPortName=htpp 2>&1)"; then fail "unresolvable port rendered"; fi
grep -q '"htpp" matches no container' <<<"$err" || fail "unexpected error: $err"
echo "ok: unresolvable targetPortName -> render fails"

echo "PASS: networkpolicy"
