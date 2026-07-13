#!/usr/bin/env bash
# Doc link + tombstone + res:// gate.
set -euo pipefail
exec python3 "$(cd "$(dirname "$0")/.." && pwd)/scripts/check_doc_links.py"
