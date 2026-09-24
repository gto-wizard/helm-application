#!/usr/bin/env bash
# Render-only assertions for templates/networkpolicy.yaml (OPS-1470). The cases live in
# render-networkpolicy.py, because they compare YAML structure, not lines. Needs PyYAML.
# Run from anywhere:  bash tests/render-networkpolicy.sh
set -euo pipefail
exec python3 "$(dirname "$0")/render-networkpolicy.py"
