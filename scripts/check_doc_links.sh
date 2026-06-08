#!/usr/bin/env bash
# Doc link + tombstone + res:// path gate — delegates to check_doc_links.py (single implementation).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/check_doc_links.py"
