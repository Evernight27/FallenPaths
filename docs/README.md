# Combat documentation (consolidated)

**Start here for build order:** [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) — canonical tier list (engagement → tactical sync → parry → AI → physics → medical).

**1 master order** (`IMPLEMENTATION_ORDER.md`) **+ 12** markdown files below (consolidated bundles and standalone plans). Consolidated bundles list original filenames under `## Source:` for provenance.

**Plan sync:** Engagement + tier order were checked against the repo **2026-04-07**; see “Last verified” in `IMPLEMENTATION_ORDER.md` and `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`.

| File | Topics |
|------|--------|
| [**IMPLEMENTATION_ORDER.md**](IMPLEMENTATION_ORDER.md) | **Master tier order** — what to implement next across all plans |
| [COMBAT_ROADMAP_AND_STAMINA.md](COMBAT_ROADMAP_AND_STAMINA.md) | Phases, locked decisions, stamina, event queue, modularization, issue notes |
| [TACTICAL_FORMATIONS_FF4.md](TACTICAL_FORMATIONS_FF4.md) | FF4 abstract model, distance, ambush, breakthrough |
| [ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) | Line cohesion, posture, intrusion slots/distance (Tier 1 detail) |
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
