"""Render-only assertions for templates/networkpolicy.yaml (OPS-1470).

Each case runs `helm template` with a tests/netpol-*-values.yaml fixture and checks the
NetworkPolicy structure. A failed render fails the harness, except in the one case that
expects a failure.
"""

import copy
import os
import subprocess
import sys

import yaml

CHART = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TESTS = os.path.join(CHART, "tests")
ENVOY = {
    "namespaceSelector": {"matchLabels": {"kubernetes.io/metadata.name": "envoy-gateway-system"}},
    "podSelector": {"matchLabels": {"app.kubernetes.io/name": "envoy", "app.kubernetes.io/component": "proxy"}},
}
ALLOY = {
    "namespaceSelector": {"matchLabels": {"kubernetes.io/metadata.name": "alloy"}},
    "podSelector": {"matchLabels": {"app.kubernetes.io/name": "alloy-general"}},
}
SAME_NS = {"from": [{"podSelector": {}}]}


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def helm(fixture, *extra, expect_fail=False):
    cmd = ["helm", "template", "r", CHART, "-f", os.path.join(TESTS, fixture), *extra]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if expect_fail:
        return res
    if res.returncode != 0:
        fail(f"{fixture}: helm template failed:\n{res.stderr}")
    return [d for d in yaml.safe_load_all(res.stdout) if d]


def policies(docs):
    return [d for d in docs if d.get("kind") == "NetworkPolicy"]


def one_policy(fixture, *extra):
    docs = helm(fixture, *extra)
    found = policies(docs)
    if len(found) != 1:
        fail(f"{fixture}: expected 1 NetworkPolicy, got {len(found)}")
    return found[0], docs


def ports(rule):
    return [p["port"] for p in rule.get("ports", [])]


def rule_from(policy, peer):
    return [r for r in policy["spec"]["ingress"] if r.get("from") == [peer]]


def all_ports(policy):
    return [p for r in policy["spec"]["ingress"] for p in ports(r)]


def golden(name):
    with open(os.path.join(TESTS, name)) as f:
        return yaml.safe_load(f)


def check(cond, msg):
    if not cond:
        fail(msg)


# 1. Default off: the chart defaults, and every fixture with networkPolicy.enabled=false,
#    render no NetworkPolicy. So a consumer that only bumps the chart gets no policy.
res = subprocess.run(["helm", "template", "r", CHART, "--set", "httpRoute.enabled=true"], capture_output=True, text=True)
check(res.returncode == 0, f"default render failed:\n{res.stderr}")
check(not policies([d for d in yaml.safe_load_all(res.stdout) if d]), "chart defaults render a NetworkPolicy")
enabled_fixtures = sorted(
    f for f in os.listdir(TESTS)
    if f.startswith("netpol-") and f.endswith("-values.yaml") and "unresolvable" not in f
)
check(len(enabled_fixtures) >= 6, "fixture discovery found too few netpol fixtures")
for fx in enabled_fixtures:
    check(not policies(helm(fx, "--set", "networkPolicy.enabled=false")), f"{fx}: policy rendered while disabled")
check(not policies(helm("netpol-worker-values.yaml", "--set", "application.enabled=false")),
      "policy rendered while application.enabled=false")
print(f"ok: disabled -> no NetworkPolicy ({len(enabled_fixtures)} fixtures + application.enabled=false)")

# 2. gto-brain-mcp: same ingress as #15385, with two intended differences:
#    - the Alloy peer also requires the alloy-general pod label (#15385 admits the whole
#      alloy namespace), so the chart admits a subset of what #15385 admits;
#    - the pod selector is the chart's (name + instance); #15385 uses name + part-of.
#      Both select the same Deployment pods.
pol, docs = one_policy("netpol-gto-brain-mcp-values.yaml")
gold = golden("netpol-golden-gto-brain-mcp.yaml")
alloy = rule_from(pol, ALLOY)
check(len(alloy) == 1, "gto-brain-mcp: the Alloy peer is not narrowed to alloy-general")
widened = copy.deepcopy(pol["spec"]["ingress"])
for rule in widened:
    if rule["from"] == [ALLOY]:
        del rule["from"][0]["podSelector"]
check(widened == gold["spec"]["ingress"],
      f"gto-brain-mcp ingress != golden:\n{yaml.safe_dump(pol['spec']['ingress'])}")
check(pol["spec"]["policyTypes"] == gold["spec"]["policyTypes"], "gto-brain-mcp policyTypes != golden")
check(pol["spec"]["podSelector"]["matchLabels"] == {"app.kubernetes.io/name": "mcp", "app.kubernetes.io/instance": "mcp"},
      "gto-brain-mcp podSelector is not the chart selector labels")
dep = next(d for d in docs if d.get("kind") == "Deployment")
pod_labels = dep["spec"]["template"]["metadata"]["labels"]
for sel in (pol["spec"]["podSelector"]["matchLabels"], gold["spec"]["podSelector"]["matchLabels"]):
    check(all(pod_labels.get(k) == v for k, v in sel.items()), f"selector {sel} does not match the pod labels")
print("ok: gto-brain-mcp -> equals #15385 gto-brain-mcp-ingress (Envoy 8090, alloy 9090)")

# 3. dwh-mcp: same podSelector, policyTypes and ingress as #15385.
pol, _ = one_policy("netpol-dwh-mcp-values.yaml")
gold = golden("netpol-golden-dwh-mcp.yaml")
check(pol["spec"] == gold["spec"], f"dwh-mcp spec != golden:\n{yaml.safe_dump(pol['spec'])}")
print("ok: dwh-mcp -> equals #15385 mcp-ingress (Envoy 8001 only)")

# 4. Sidecar target port: the Service targets the nginx sidecar `http` (8080), never 8000.
pol, _ = one_policy("netpol-webapp-django-values.yaml")
ing = pol["spec"]["ingress"]
check(ing[0] == SAME_NS, "webapp: first rule is not the same-namespace rule (sameNamespace default true)")
gw = rule_from(pol, ENVOY)
check(len(gw) == 1 and ports(gw[0]) == [8080], f"webapp: gateway ports {[ports(r) for r in gw]} != [8080]")
alloy = rule_from(pol, ALLOY)
check(len(alloy) == 1 and ports(alloy[0]) == [9090], f"webapp: alloy ports {[ports(r) for r in alloy]} != [9090]")
check(8000 not in all_ports(pol), "webapp: main container port 8000 must not be opened")
check(all(isinstance(p, int) for p in all_ports(pol)), "webapp: a port is not a number")
print("ok: webapp sidecar -> gateway 8080, alloy 9090 (alloy-general), 8000 nowhere")

# 5. Named -> numeric through extraContainerPorts, allowFrom, and ServiceMonitor port.
pol, _ = one_policy("netpol-allowfrom-values.yaml")
check(not rule_from(pol, ENVOY), "allowfrom: gateway rule rendered with httpRoute disabled")
alloy = rule_from(pol, ALLOY)
check(len(alloy) == 1 and ports(alloy[0]) == [5001], "allowfrom: alloy must scrape the ServiceMonitor port 5001")
ns = lambda n: {"matchLabels": {"kubernetes.io/metadata.name": n}}
cases = [
    ({"namespaceSelector": ns("webapp")}, [5001]),
    ({"namespaceSelector": ns("webapp-custom"), "podSelector": {"matchLabels": {"app.kubernetes.io/name": "dramatiq-hands"}}}, [5001]),
    ({"namespaceSelector": {}, "podSelector": {"matchLabels": {"app.kubernetes.io/part-of": "webapp"}}}, [5001]),
    ({"namespaceSelector": ns("ai-engine")}, [4369, 8080]),
]
for peer, want in cases:
    got = rule_from(pol, peer)
    check(len(got) == 1 and ports(got[0]) == want, f"allowfrom: peer {peer} ports {[ports(r) for r in got]} != {want}")
check(8000 not in all_ports(pol), "allowfrom: main port 8000 must not be opened")
print("ok: allowFrom -> resolved port 5001 by name; explicit ports kept; alloy on the ServiceMonitor port")

# 6. Worker without a Service or port: same-namespace rule only.
pol, _ = one_policy("netpol-worker-values.yaml")
check(pol["spec"]["ingress"] == [SAME_NS], f"worker: ingress {pol['spec']['ingress']} != [same-namespace]")
pol, _ = one_policy("netpol-worker-values.yaml", "--set", "networkPolicy.sameNamespace=false")
check(pol["spec"]["ingress"] == [], "worker + sameNamespace=false: expected deny-all `ingress: []`")
print("ok: worker -> same-namespace only; with sameNamespace=false -> ingress: []")

# 7. Break-glass: allow all, and never fail the render.
pol, _ = one_policy("netpol-allowall-values.yaml")
check(pol["spec"]["ingress"] == [{}], f"allowAll: ingress {pol['spec']['ingress']} != [{{}}]")
check(pol["spec"]["policyTypes"] == ["Ingress"], "allowAll: policyTypes != [Ingress]")
print("ok: allowAll -> ingress: [{}]")

# 8. Unresolvable targetPortName with the gateway on: the render fails loudly.
res = helm("netpol-unresolvable-values.yaml", expect_fail=True)
check(res.returncode != 0, "unresolvable: render succeeded, expected a failure")
check('"htpp" matches no container' in res.stderr, f"unresolvable: unexpected error:\n{res.stderr}")
res = helm("netpol-unresolvable-values.yaml", "--set", "networkPolicy.gateway.enabled=false")
check(policies(res) and not rule_from(policies(res)[0], ENVOY), "unresolvable + gateway.enabled=false: expected no gateway rule")
print("ok: unresolvable targetPortName + gateway -> render fails; gateway.enabled=false -> renders")

# 9. allowFrom validation.
res = helm("netpol-worker-values.yaml", "--set", "networkPolicy.allowFrom[0].anyNamespace=true", expect_fail=True)
check(res.returncode != 0 and "anyNamespace requires podLabels" in res.stderr, "anyNamespace without podLabels must fail")
res = helm("netpol-worker-values.yaml", "--set", "networkPolicy.allowFrom[0].namespace=webapp", expect_fail=True)
check(res.returncode != 0 and "no ports" in res.stderr, "allowFrom without a resolvable port must fail")
print("ok: allowFrom -> anyNamespace without podLabels fails; no port fails")

print("PASS: all networkpolicy cases")
