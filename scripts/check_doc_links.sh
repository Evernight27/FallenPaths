#!/usr/bin/env bash
# Verify docs links + tombstones (delegates to check_doc_links.ps1 on Windows; bash link-only fallback).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if command -v pwsh >/dev/null 2>&1; then
	exec pwsh -NoProfile -File "$ROOT/scripts/check_doc_links.ps1"
fi
DOCS="$ROOT/docs"
broken=0
shopt -s nullglob
for f in "$DOCS"/*.md; do
	from="$(basename "$f")"
	while IFS= read -r target; do
		[[ "$target" =~ ^https?:// ]] && continue
		if [[ "$target" == ../* ]]; then
			resolved="$(cd "$(dirname "$f")" && realpath -m "$target" 2>/dev/null || echo "")"
		else
			resolved="$(realpath -m "$DOCS/$target" 2>/dev/null || echo "")"
		fi
		if [[ -z "$resolved" || ! -f "$resolved" ]]; then
			echo "  $from -> $target"
			broken=1
		fi
	done < <(grep -oP '\[[^\]]*\]\(\K[^)#]+\.md' "$f" || true)
done
count="$(find "$DOCS" -maxdepth 1 -name '*.md' | wc -l)"
if [[ $broken -eq 0 ]]; then
	echo "DOC_LINKS: PASS ($count files, tombstones: run check_doc_links.ps1)"
	exit 0
fi
echo "DOC_LINKS: FAIL"
exit 1
