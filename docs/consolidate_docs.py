#!/usr/bin/env python3
"""Merge docs into canonical files; rewrite docs/ links in .gd only. Run: python3 docs/consolidate_docs.py"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent

MERGES: dict[str, list[str]] = {
    "COMBAT_ROADMAP_AND_STAMINA.md": [
        "IMPLEMENTATION_OUTLINE.md",
        "STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md",
        "STAMINA_CURVE_HEMA_COMBAT_PACING_INVESTIGATION.md",
        "STAMINA_VS_FITNESS_FORMATION_INTEGRATION_INVESTIGATION.md",
        "BACK_RANK_WAIT_EVENT_LISTENER_VS_FIXED_COOLDOWN_INVESTIGATION.md",
        "MODULARIZATION_POSSIBILITIES.md",
        "COMBAT_SYSTEM_ISSUES.md",
    ],
    "TACTICAL_FORMATIONS_FF4.md": [
        "FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md",
        "FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md",
    ],
    "TACTICAL_ZONES_BREACH_MOVEMENT.md": [
        "ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md",
        "FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md",
        "ENGAGEMENT_ANGLE_VS_ZOC_FLANKING_INVESTIGATION.md",
        "FORMATION_FILE_DENSITY_SURVIVABILITY_INVESTIGATION.md",
        "MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md",
        "INCURSION_BREACH_MIGRATION_PLAN.md",
    ],
    "PHYSICS_DAMAGE_AND_FLOW.md": [
        "PHYSICS_REALISM_DECISIONS_INVESTIGATION.md",
        "ANGLE_SYSTEM_INTEGRATION_STATUS.md",
        "PHYSICS_SYSTEMS_OPTIMAL_STRUCTURE_INVESTIGATION.md",
        "COMBAT_ATTACK_PARRY_DODGE_FLOW.md",
        "SYSTEM_INTEGRATION_STATUS.md",
        "COMBAT_ENTITY_INTERFACE.md",
        "SHARP_PENETRATION_BLUNT_TRANSMISSION_PLAN.md",
        "CONTACT_TYPE_MULTIPLIERS_INTEGRATION_INVESTIGATION.md",
        "SUBREGION_MULTIPLIER_AUDIT.md",
        "RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md",
        "COMBAT_NUMBERS_REALISM_AUDIT.md",
        "GOBLIN_STATS_REALISM.md",
    ],
    "PARRY_BIND_AND_WEAPON_GEOMETRY.md": [
        "WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md",
        "WEAPON_PART_MODEL_IMPLEMENTATION_PLAN.md",
        "BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION.md",
        "BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION.md",
        "PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md",
        "HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md",
    ],
    "PARRY_DEFLECT_AND_CALIBRATION.md": [
        "HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md",
        "DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md",
        "PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md",
        "PARRY_SYSTEM_OPTIONS.md",
        "STATE_MACHINE_PARRY_REALISM.md",
        "PARRY_REDIRECTION_IMPROVEMENTS.md",
        "COMBAT_PARRY_MISS_RESEARCH.md",
        "PARRY_RATE_ANALYSIS.md",
    ],
    "GUARDS_LINES_AFTERBLOW.md": [
        "LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md",
        "GUARD_LINE_DYNAMICS_INVESTIGATION.md",
        "GUARD_ANGLE_PHYSICS_INVESTIGATION.md",
        "GUARD_POSITION_WEAPON_BODY_INTERACTION_INVESTIGATION.md",
        "ZONE_SPECIFIC_GUARD_INVESTIGATION.md",
    ],
    "AI_ENGAGEMENT_STANCE_AND_FEINTS.md": [
        "FEINT_COUNTER_STAMINA_READINESS_DIAGONAL_INVESTIGATION.md",
        "COMBAT_STANCE_STATES_INVESTIGATION.md",
        "FOOTWORK_POSITIONING_INVESTIGATION.md",
        "MELEE_SIMULATION_AI_INVESTIGATION.md",
        "MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md",
        "MENTAL_STACK_IMPLEMENTATION_COMPARISON.md",
    ],
    "HEMA_ROADMAP_AND_SOURCES.md": [
        "HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md",
        "HEMA_FIDELITY_IMPROVEMENTS.md",
        "HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md",
        "HEMA_VS_KCD_SOURCE_ANALYSIS.md",
        "KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md",
    ],
    "MEDICAL_PAIN_INCAPACITATION.md": [
        "PAIN_SHOCK_INVESTIGATION.md",
        "PAIN_MEDICAL_RESEARCH_SYNTHESIS.md",
        "WOUND_PACKING_MEDIEVAL_RESEARCH.md",
        "INCAPACITATION_FLEE_FALLBACK_COWERING_INVESTIGATION.md",
    ],
}

OLD_TO_NEW: dict[str, str] = {}
for new_name, sources in MERGES.items():
    for s in sources:
        OLD_TO_NEW[s] = new_name

# Earlier repo cleanups — point to roadmap bundle
OLD_TO_NEW.update(
    {
        "STAMINA_ENGAGEMENT_GATE_AND_DISTANCE_OPTIONS.md": "COMBAT_ROADMAP_AND_STAMINA.md",
        "ENGAGEMENT_FLURRY_IMPLEMENTATION_OPTIONS.md": "COMBAT_ROADMAP_AND_STAMINA.md",
        "ENGAGEMENT_ALTERNATIVE_PARADIGMS_AND_REFERENCE_SYSTEMS.md": "COMBAT_ROADMAP_AND_STAMINA.md",
    }
)


def demote_markdown_headings(text: str, levels: int = 1) -> str:
    if levels <= 0:
        return text
    out: list[str] = []
    in_fence = False
    for line in text.splitlines(keepends=True):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            out.append(line)
            continue
        if not in_fence and re.match(r"^(#{1,6})\s", line):
            hashes = line.split()[0]
            rest = line[len(hashes) :]
            out.append("#" * levels + hashes + rest)
        else:
            out.append(line)
    return "".join(out)


def rewrite_doc_links(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        fname = m.group(1)
        return f"docs/{OLD_TO_NEW.get(fname, fname)}"

    return re.sub(r"docs/([A-Za-z0-9_.-]+\.md)", repl, text)


def build_merged(new_name: str, sources: list[str]) -> str:
    title = new_name.replace("_", " ").replace(".md", "").title()
    intro = (
        f"# {title}\n\n"
        "**Plan / code:** Sequencing + milestone **Status** → **`docs/IMPLEMENTATION_ORDER.md`** "
        "([plan inventory](IMPLEMENTATION_ORDER.md#plan-inventory-all-combat-markdown) names this bundle’s tier). "
        "This file is **merged investigations** — not a second execution order.\n\n"
        "Consolidated sections; each has **`Source:`** for provenance.\n\n"
        "## Contents\n\n"
    )
    toc_lines = []
    for i, src in enumerate(sources, start=1):
        slug = re.sub(r"[^a-z0-9]+", "-", src.lower().removesuffix(".md")).strip("-")
        toc_lines.append(f"{i}. [{src}](#{slug})")
    intro += "\n".join(toc_lines) + "\n\n---\n\n"
    parts: list[str] = [intro]

    for idx, src in enumerate(sources):
        path = ROOT / src
        if not path.is_file():
            print(f"MISSING: {src}", file=sys.stderr)
            sys.exit(1)
        raw = path.read_text(encoding="utf-8")
        raw = rewrite_doc_links(raw)
        slug = re.sub(r"[^a-z0-9]+", "-", src.lower().removesuffix(".md")).strip("-")
        banner = f'<a id="{slug}"></a>\n\n## Source: `{src}`\n\n'
        if idx > 0:
            raw = demote_markdown_headings(raw, 1)
        parts.append(banner + raw.rstrip() + "\n\n---\n\n")

    return "".join(parts).rstrip() + "\n"


def patch_gd_files() -> None:
    pattern = re.compile(
        r"docs/(" + "|".join(re.escape(k) for k in OLD_TO_NEW.keys()) + r")"
    )

    for p in REPO.rglob("*.gd"):
        if "addons" in p.parts:
            continue
        t = p.read_text(encoding="utf-8")
        nt = pattern.sub(lambda m: f"docs/{OLD_TO_NEW[m.group(1)]}", t)
        if nt != t:
            p.write_text(nt, encoding="utf-8")
            print("patched", p.relative_to(REPO))


def main() -> None:
    to_remove: list[Path] = []
    for new_name, sources in MERGES.items():
        out = build_merged(new_name, sources)
        (ROOT / new_name).write_text(out, encoding="utf-8")
        print(f"wrote {new_name} ({len(out.splitlines())} lines)")
        for s in sources:
            to_remove.append(ROOT / s)

    for p in to_remove:
        p.unlink(missing_ok=True)
        print(f"removed {p.name}")

    patch_gd_files()
    print("done. Re-add tier-specific **Plan / code** links in each bundle header if needed (see plan inventory).")


if __name__ == "__main__":
    main()
