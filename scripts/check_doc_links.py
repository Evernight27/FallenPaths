#!/usr/bin/env python3
"""Doc link + tombstone gate — canonical implementation for check_doc_links.ps1 / .sh."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)#]+\.md)(?:#[^)]+)?\)")
REDIRECT_CELL = re.compile(r"\|\s*`([^`]+)`\s*\|")
CANONICAL_ON_DISK = {
    "CURSOR.md",
    "LIVE_PATHS.md",
    "PLANNING.md",
    "SHIP_PLAN.md",
    "CAMPAIGN_DECISION_GUIDE.md",
}


def resolve_link(from_file: Path, target: str) -> Path:
    if target.startswith("http://") or target.startswith("https://"):
        return from_file  # skipped by caller
    if target.startswith("../") or target.startswith("./"):
        return (from_file.parent / target).resolve()
    return (DOCS / target).resolve()


def collect_tombstones() -> list[str]:
    live_paths = DOCS / "LIVE_PATHS.md"
    if not live_paths.is_file():
        return []
    text = live_paths.read_text(encoding="utf-8")
    start = text.find("## Redirects")
    section = text[start:] if start >= 0 else ""
    names: list[str] = []
    for raw in REDIRECT_CELL.findall(section):
        raw = raw.strip()
        if "*" in raw:
            prefix = raw.split("*", 1)[0]
            names.extend(p.name for p in DOCS.glob(prefix + "*.md"))
        else:
            if " (" in raw:
                raw = raw.split(" (", 1)[0].strip()
            names.append(raw)
    return names


def main() -> int:
    broken: list[str] = []
    for md in sorted(DOCS.glob("*.md")):
        text = md.read_text(encoding="utf-8")
        for m in LINK_PATTERN.finditer(text):
            target = m.group(1)
            if target.startswith("http://") or target.startswith("https://"):
                continue
            resolved = resolve_link(md, target)
            if not resolved.is_file():
                broken.append(f"broken link: {md.name} -> {target}")

    for name in sorted(set(collect_tombstones())):
        if name in CANONICAL_ON_DISK:
            continue
        path = DOCS / name
        if path.is_file():
            broken.append(f"tombstone file still on disk (delete or merge into LIVE_PATHS): docs/{name}")

    md_count = len(list(DOCS.glob("*.md")))
    tomb_count = len(set(collect_tombstones()))
    if broken:
        print(f"DOC_LINKS: FAIL ({len(broken)} issues)")
        for line in sorted(set(broken)):
            print(f"  {line}")
        return 1
    print(f"DOC_LINKS: PASS ({md_count} files, {tomb_count} tombstones checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
