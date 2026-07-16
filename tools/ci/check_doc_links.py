#!/usr/bin/env python3
"""Doc link + tombstone gate + optional res:// path audit.

Canonical implementation for check_doc_links.ps1 / .sh (Phase 0).
Standalone res-path audit: python3 tools/ci/check_doc_links.py --res-paths-only

Scans: docs/*.md, AGENTS.md, README.md, tools/ci/**/*.md.
Optional anchor check for a small allowlist of agent-critical ids.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

def _repo_root() -> Path:
    here = Path(__file__).resolve().parent
    for candidate in (here.parent.parent, here.parent, here):
        if (candidate / "project.godot").is_file():
            return candidate
    return here.parent.parent


ROOT = _repo_root()
DOCS = ROOT / "docs"
LINK_PATTERN = re.compile(r"\[[^\]]*\]\(([^)#]+\.md)(?:#([^)]+))?\)")
ANCHOR_ID_PATTERN = re.compile(r'<a\s+id="([^"]+)"\s*>', re.IGNORECASE)
REDIRECT_CELL = re.compile(r"\|\s*`([^`]+)`\s*\|")
CANONICAL_ON_DISK = {
    "AGENTS_ENTRY.md",
    "LIVE_PATHS.md",
    "PLANNING.md",
    "SHIP_PLAN.md",
    "CAMPAIGN_DECISION_GUIDE.md",
    "EXPANSION_PLAN.md",
    "COMPOSURE_PLAN.md",
    "FEATURE_PRESERVATION.md",
    "AGENTS_API.md",
}

# Agent-critical anchors — fail if linked but missing <a id=>
CRITICAL_ANCHORS = {
    "godot-entry",
    "what-to-do-next",
    "checklist",
    "code-homes",
    "file-ownership",
    "work-streams",
    "anti-patterns",
    "canonical-apis",
    "phase-0-gate",
    "harness-and-flags",
    "muscle-fatigue-phase-2",
    "3c--cost-deduction-at-wind-up-start",
    "combat-expand-registry",
    "camp-playtest-acceptance",
    "wf-footing-guards-stances",
    "project-health-bundle",
    "expand-reopen",
}

RES_PATH_PATTERN = re.compile(r"res://([^\s\"'#)]+)")
RES_SCAN_EXT = {".gd", ".tscn", ".tres"}
RES_SKIP_PARTS = {".git", ".godot"}
RES_ALLOW_MISSING = {
    "species",
    "world/companion_%d.tscn",
    "assets/tiles/tile_texture.png",
    ".q_track_audits.txt",
    ".d001_soak_out.txt",
    ".ii2b_worksheet_prefill.txt",
}


def resolve_link(from_file: Path, target: str) -> Path:
    if target.startswith("http://") or target.startswith("https://"):
        return from_file
    if target.startswith("../") or target.startswith("./") or "/" in target:
        return (from_file.parent / target).resolve()
    if from_file.is_relative_to(DOCS):
        return (DOCS / target).resolve()
    return (from_file.parent / target).resolve()


def markdown_files_to_scan() -> list[Path]:
    files: list[Path] = []
    files.extend(sorted(DOCS.glob("*.md")))
    for name in ("AGENTS.md", "README.md"):
        p = ROOT / name
        if p.is_file():
            files.append(p)
    for rel in ("tools/ci", "combat", "harness", "scenes", "resources", "assets", "ui", "addons"):
        folder = ROOT / rel
        if folder.is_dir():
            files.extend(sorted(folder.rglob("*.md")))
    seen: set[Path] = set()
    out: list[Path] = []
    for f in files:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def collect_explicit_anchors(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    text = path.read_text(encoding="utf-8", errors="replace")
    return set(ANCHOR_ID_PATTERN.findall(text))


def _tombstone_names_from_text(section: str) -> list[str]:
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


def collect_tombstones() -> list[str]:
    """Tombstones from LIVE_PATHS redirects section."""
    live_paths = DOCS / "LIVE_PATHS.md"
    if not live_paths.is_file():
        return []
    text = live_paths.read_text(encoding="utf-8")
    start = text.find("## Redirects")
    if start < 0:
        return []
    return _tombstone_names_from_text(text[start:])


def check_doc_links() -> tuple[int, list[str]]:
    broken: list[str] = []
    anchor_cache: dict[Path, set[str]] = {}
    scanned = markdown_files_to_scan()

    for md in scanned:
        text = md.read_text(encoding="utf-8", errors="replace")
        rel_from = str(md.relative_to(ROOT))
        for m in LINK_PATTERN.finditer(text):
            target = m.group(1)
            frag = m.group(2)
            if target.startswith("http://") or target.startswith("https://"):
                continue
            resolved = resolve_link(md, target)
            if not resolved.is_file():
                broken.append(f"broken link: {rel_from} -> {target}")
                continue
            if frag and frag in CRITICAL_ANCHORS:
                if resolved not in anchor_cache:
                    anchor_cache[resolved] = collect_explicit_anchors(resolved)
                if frag not in anchor_cache[resolved]:
                    broken.append(f"broken anchor: {rel_from} -> {target}#{frag}")

    for name in sorted(set(collect_tombstones())):
        if name in CANONICAL_ON_DISK:
            continue
        path = DOCS / name
        if path.is_file():
            broken.append(
                f"tombstone file still on disk (delete or merge into LIVE_PATHS): docs/{name}"
            )

    md_count = len(scanned)
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
    disk = ROOT / res_path.rstrip("/")
    if disk.is_file():
        return True
    if disk.is_dir():
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
