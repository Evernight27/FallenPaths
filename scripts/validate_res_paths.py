#!/usr/bin/env python3
"""Verify res:// paths in .gd/.tscn/.tres exist on disk (parse-time preload/load safety)."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PAT = re.compile(r"res://([^\s\"'#)]+)")
SCAN_EXT = {".gd", ".tscn", ".tres"}
SKIP_PARTS = {".git", ".godot"}

# Directories or runtime-generated assets (not required in repo)
ALLOW_MISSING = {
    "species",  # DirAccess.open(ResourcePaths.SPECIES_DIR)
    "tile_texture.png",  # TilesetSetup.generate_tile_texture_if_needed()
}


def is_valid(res_path: str) -> bool:
    if res_path in ALLOW_MISSING or res_path.rstrip("/") in ALLOW_MISSING:
        return True
    disk = ROOT / res_path
    if disk.is_file():
        return True
    if disk.with_suffix(".gd").is_file():
        return True
    return False


def collect_refs() -> dict[str, set[tuple[str, int]]]:
    refs: dict[str, set[tuple[str, int]]] = {}
    for fp in ROOT.rglob("*"):
        if fp.suffix not in SCAN_EXT:
            continue
        if any(p in SKIP_PARTS for p in fp.parts):
            continue
        text = fp.read_text(encoding="utf-8", errors="replace")
        rel = str(fp.relative_to(ROOT))
        for line_no, line in enumerate(text.splitlines(), 1):
            for m in PAT.finditer(line):
                p = m.group(1).rstrip(".,;:")
                refs.setdefault(p, set()).add((rel, line_no))
    return refs


def main() -> int:
    refs = collect_refs()
    missing: list[tuple[str, list[tuple[str, int]]]] = []
    for res_path in sorted(refs):
        if not is_valid(res_path):
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


if __name__ == "__main__":
    sys.exit(main())
