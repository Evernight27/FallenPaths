# Combat documentation (consolidated)

**Start here — full logical implementation plan:** [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) — baseline → Tier 1 (**P3 + P4 shipped**; **1.4** hysteresis + discipline tags **partial**; **morale 1.5** not wired) + optional **2.1** tactical doc prose sync → tiers 2–7.

## Streamlined reading order

| If you need… | Read… |
|--------------|--------|
| **Single plan before coding** | [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) — dependency chain; **Tier 1.3 P4 Done**; **Tier 1.4 P5 Partial** (hysteresis + deltas + `line_discipline`; richer tags **Todo**); **1.6 Partial** (crash AI vs posture). |
| **Tier 1 spec** (fields, plug taxonomy, tuning) | [`ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) — §4–§6; §2 is verification mirror (sequencing is in `IMPLEMENTATION_ORDER`). |
| **Shipped baseline** (modules per subsystem) | Tier 0 in `IMPLEMENTATION_ORDER.md` — overlaps [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) **Current architecture snapshot**. |
| **Historical phases + stamina / investigations** | [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) — long bundle; snapshot at top for “today.” |
| **ZoC / breach narrative** | [`TACTICAL_ZONES_BREACH_MOVEMENT.md`](TACTICAL_ZONES_BREACH_MOVEMENT.md) — Tier 2 sync in `IMPLEMENTATION_ORDER` after P3+. |

**Avoid:** A second “master sequence” in the engagement doc or roadmap Part 3 — **`IMPLEMENTATION_ORDER.md`** owns order and status.

---

**1 master order** (`IMPLEMENTATION_ORDER.md`) **+ 12** markdown files below (consolidated bundles and standalone plans). Consolidated bundles list original filenames under `## Source:` for provenance.

**Plan sync:** **2026-04-27** pass — milestones, morale deferral, `ZoneOfControl.formation_id_for_zone_geometry(manager, c)` single source for intruder host fid in ZoC + pair distance. See “Last verified” in `IMPLEMENTATION_ORDER.md` and `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`.

| File | Topics |
|------|--------|
| [**IMPLEMENTATION_ORDER.md**](IMPLEMENTATION_ORDER.md) | **Combat implementation plan** — logical sequence, Tier 1 expanded steps, gate before coding |
| [COMBAT_ROADMAP_AND_STAMINA.md](COMBAT_ROADMAP_AND_STAMINA.md) | Phases, locked decisions, stamina, event queue, modularization, issue notes |
| [TACTICAL_FORMATIONS_FF4.md](TACTICAL_FORMATIONS_FF4.md) | FF4 abstract model, distance, ambush, breakthrough |
| [ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) | Tier 1 **spec** — §4–§6 (plugs, fields, tuning); §2 mirrors milestone status from `IMPLEMENTATION_ORDER` |
| [TACTICAL_ZONES_BREACH_MOVEMENT.md](TACTICAL_ZONES_BREACH_MOVEMENT.md) | ZoC, surround, flanking, formation density/movement, incursion/breach plan |
| [PHYSICS_DAMAGE_AND_FLOW.md](PHYSICS_DAMAGE_AND_FLOW.md) | Physics status, angles, attack→damage flow, numbers audits, species stats |
| [PARRY_BIND_AND_WEAPON_GEOMETRY.md](PARRY_BIND_AND_WEAPON_GEOMETRY.md) | Weapon parts, bind/riposte vs HEMA |
| [PARRY_DEFLECT_AND_CALIBRATION.md](PARRY_DEFLECT_AND_CALIBRATION.md) | Deflection, parry options, state machine, calibration, parry research |
| [GUARDS_LINES_AFTERBLOW.md](GUARDS_LINES_AFTERBLOW.md) | Line guard, afterblow, guard dynamics |
| [AI_ENGAGEMENT_STANCE_AND_FEINTS.md](AI_ENGAGEMENT_STANCE_AND_FEINTS.md) | Stances, footwork, melee AI, mental stack, feint/stamina diagonal |
| [HEMA_ROADMAP_AND_SOURCES.md](HEMA_ROADMAP_AND_SOURCES.md) | HEMA roadmap, fidelity, zones/feints/flurries, KCD vs sources |
| [MEDICAL_PAIN_INCAPACITATION.md](MEDICAL_PAIN_INCAPACITATION.md) | Pain, wounds, incapacitation / flee |

**Regenerate** (requires restoring individual sources from git history): `python3 docs/consolidate_docs.py`

Typical size: ~1.1k–1.9k lines per bundle (manageable for editor/AI context).
