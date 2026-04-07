# Combat documentation (consolidated)

Ten markdown bundles replace the previous per-topic files. Each bundle lists its original filenames under `## Source:` for provenance.

| File | Topics |
|------|--------|
| [COMBAT_ROADMAP_AND_STAMINA.md](COMBAT_ROADMAP_AND_STAMINA.md) | Phases, locked decisions, stamina, event queue, modularization, issue notes |
| [TACTICAL_FORMATIONS_FF4.md](TACTICAL_FORMATIONS_FF4.md) | FF4 abstract model, distance, ambush, breakthrough |
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
