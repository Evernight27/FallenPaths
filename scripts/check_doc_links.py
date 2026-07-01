#!/usr/bin/env python3
"""Doc link + tombstone gate + optional res:// path audit.

Canonical implementation for check_doc_links.ps1 / .sh (Phase 0).
Standalone res-path audit: python3 scripts/check_doc_links.py --res-paths-only
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)#]+\.md)(?:#[^)]+)?\)")
REDIRECT_CELL = re.compile(r"\|\s*`([^`]+)`\s*\|")
CANONICAL_ON_DISK = {
    "AGENTS_ENTRY.md",
    "LIVE_PATHS.md",
    "PLANNING.md",
    "SHIP_PLAN.md",
    "CAMPAIGN_DECISION_GUIDE.md",
    "EXPANSION_PLAN.md",
}

RES_PATH_PATTERN = re.compile(r"res://([^\s\"'#)]+)")
RES_SCAN_EXT = {".gd", ".tscn", ".tres"}
RES_SKIP_PARTS = {".git", ".godot"}
RES_ALLOW_MISSING = {
    "species",  # DirAccess.open(ResourcePaths.SPECIES_DIR)
    "world/companion_%d.tscn",  # format string: RuntimeFormats.companion_scene()
    "tile_texture.png",  # TilesetSetup.generate_tile_texture_if_needed()
    ".q_track_audits.txt",  # CombatQTrackAudits output path (artifact, not resource)
    ".d001_soak_out.txt",  # CombatQTrackAudits input path (artifact, not resource)
    ".ii2b_worksheet_prefill.txt",  # CombatQTrackAudits worksheet path (artifact, not resource)
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


def check_doc_links() -> tuple[int, list[str]]:
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
            broken.append(
                f"tombstone file still on disk (delete or merge into LIVE_PATHS): docs/{name}"
            )

    md_count = len(list(DOCS.glob("*.md")))
    tomb_count = len(set(collect_tombstones()))
    if broken:
        print(f"DOC_LINKS: FAIL ({len(broken)} issues)")
        for line in sorted(set(broken)):
            print(f"  {line}")
        return 1, broken

    print(f"DOC_LINKS: PASS ({md_count} files, {tomb_count} tombstones checked)")
    return 0, broken


def _res_path_valid(res_path: str) -> bool:
    if res_path in RES_ALLOW_MISSING or res_path.rstrip("/") in RES_ALLOW_MISSING:
        return True
    disk = ROOT / res_path
    if disk.is_file():
        return True
    if disk.with_suffix(".gd").is_file():
        return True
    return False


def _collect_res_refs() -> dict[str, set[tuple[str, int]]]:
    refs: dict[str, set[tuple[str, int]]] = {}
    for fp in ROOT.rglob("*"):
        if fp.suffix not in RES_SCAN_EXT:
            continue
        if any(p in RES_SKIP_PARTS for p in fp.parts):
            continue
        text = fp.read_text(encoding="utf-8", errors="replace")
        rel = str(fp.relative_to(ROOT))
        for line_no, line in enumerate(text.splitlines(), 1):
            for m in RES_PATH_PATTERN.finditer(line):
                p = m.group(1).rstrip(".,;:")
                refs.setdefault(p, set()).add((rel, line_no))
    return refs


def check_res_paths() -> int:
    refs = _collect_res_refs()
    missing: list[tuple[str, list[tuple[str, int]]]] = []
    for res_path in sorted(refs):
        if not _res_path_valid(res_path):
            missing.append((res_path, sorted(refs[res_path])[:5]))

    if missing:
        print(f"RES_PATHS: FAIL ({len(missing)} missing of {len(refs)} unique paths)")
        for path, samples in missing:
            print(f"  res://{path}")
            for rel, ln in samples:
                print(f"    {rel}:{ln}")
        return 1

    print(f"RES_PATHS: PASS ({len(refs)} unique res:// paths)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Doc link + res:// path gate")
    parser.add_argument(
        "--skip-res-paths",
        action="store_true",
        help="Doc links + tombstones only (skip res:// audit)",
    )
    parser.add_argument(
        "--res-paths-only",
        action="store_true",
        help="res:// audit only",
    )
    args = parser.parse_args()

    run_docs = not args.res_paths_only
    run_res = args.res_paths_only or not args.skip_res_paths

    code = 0
    if run_docs:
        doc_code, _ = check_doc_links()
        code = max(code, doc_code)
    if run_res:
        code = max(code, check_res_paths())
    return code


if __name__ == "__main__":
    sys.exit(main())
