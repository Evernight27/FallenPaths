#!/usr/bin/env bash
# Doc link + tombstone + res:// gate.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$HERE/check_doc_links.py" "$@"
