#!/usr/bin/env bash
# Local / CI lint gate: shellcheck + gdlint + gdformat --check.
# Install gdtoolkit: pip install 'gdtoolkit==4.*'  (or use a venv).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== shellcheck ==="
# Prefer auto-discovered scripts/.shellcheckrc (works on shellcheck 0.9+ in CI apt packages).
shellcheck -x scripts/*.sh

echo "=== gdlint ==="
if ! command -v gdlint >/dev/null 2>&1; then
	echo "gdlint not found; pip install 'gdtoolkit==4.*'" >&2
	exit 127
fi
gdlint .

echo "=== gdformat --check ==="
if ! command -v gdformat >/dev/null 2>&1; then
	echo "gdformat not found; pip install 'gdtoolkit==4.*'" >&2
	exit 127
fi
gdformat --check .

echo "=== LINT: PASS ==="
