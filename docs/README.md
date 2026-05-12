# Combat documentation (consolidated)

**Start here — authoritative sequence + status:** [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md). Use its [Document map](IMPLEMENTATION_ORDER.md#document-map-read-order) for **section order inside the plan** (dependency chain → Tier 0 → Tier 1 → …). This README is a **topic index** only.

## Streamlined reading order

Rows are **by task** (not the same order as sections inside `IMPLEMENTATION_ORDER.md` — use the [Document map](IMPLEMENTATION_ORDER.md#document-map-read-order) for that).

| If you need… | Read… |
|--------------|--------|
| **How to read the plan file** | [Document map](IMPLEMENTATION_ORDER.md#document-map-read-order) in `IMPLEMENTATION_ORDER.md` |
| **Line-crash intrusions gate** (`FEATURE_LINE_CRASH_INTRUSION`, default **false**) | [Development gate](IMPLEMENTATION_ORDER.md#development-gate-line-crash--intrusions-temporary) in `IMPLEMENTATION_ORDER.md` only |
| **Single plan before coding** | [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) only — full milestone column in that file (includes **Tier 3.0** vs **3.1–3.3**). |
| **Headless combat regression harness** | Command in [`AGENTS.md`](../AGENTS.md); VS Code / Cursor task **Run Combat Regression Harness (headless)** in [`.vscode/tasks.json`](../.vscode/tasks.json) (uses **`godotTools.editorPath.godot4`** in [`.vscode/settings.json`](../.vscode/settings.json)). |
| **Tier 1 spec** (fields, plug taxonomy, tuning) | [`ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) — §4–§6; §2 is verification mirror (sequencing is in `IMPLEMENTATION_ORDER`). |
| **Shipped baseline** (modules per subsystem) | Tier 0 in `IMPLEMENTATION_ORDER.md` — overlaps [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) **Current architecture snapshot**. |
| **Historical phases + stamina / investigations** | [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) — long bundle; snapshot at top for “today.” |
| **ZoC / breach narrative** | [`TACTICAL_ZONES_BREACH_MOVEMENT.md`](TACTICAL_ZONES_BREACH_MOVEMENT.md) — Tier 2 sync in `IMPLEMENTATION_ORDER` after P3+. |
| **IDE / agent map** (not a status source) | [`AGENTS.md`](../AGENTS.md) and [`.cursor/rules/fallen-paths.mdc`](../.cursor/rules/fallen-paths.mdc) — both defer combat milestones to `IMPLEMENTATION_ORDER.md`. |

---

**1** master plan (`IMPLEMENTATION_ORDER.md`) **+ 12** companion markdown files. Order below matches [plan inventory](IMPLEMENTATION_ORDER.md#plan-inventory-all-combat-markdown) (tier flow, not alphabetical). Consolidated bundles list original filenames under `## Source:` for provenance.

**Index sync:** **2026-05-11** — roles align with plan inventory; factual “last verified” claims → **`IMPLEMENTATION_ORDER`** header. **`CombatRegressionHarness.run_all()`** + VS Code task → streamlined table row + **`AGENTS.md`**. Tier **1.9** headless regression coverage (incl. **`_run_doctrine_normalize_and_manager_roundtrip`**, **`_run_ai_targeting_incap_hostile_mult`**, **`_run_surround_defense_multiplier_from_pa_both_paths`**, **`_run_surround_live_weight_sum_matches_from_pa_sector_path`**, **`_run_surround_single_threat_int_and_sector_neutral`**, **`_run_hostile_pair_distributed_pressure_ally_commit`**, **`_run_targeting_hold_lane_off_file_mult`**, **`_run_targeting_pinch_center_inward_bonus`**, **`_run_targeting_commitment_match_mult`**, **`_run_targeting_soft_geometry_eff_dist_formula`**, **`_run_targeting_prune_expired_doctrine_commitment`**, **`_run_targeting_prune_commitment_when_target_dies`**, **`_run_targeting_clear_all_state_for_dead_defender`**) → **`IMPLEMENTATION_ORDER`** **Harness map** under §Tier 1.9 exit criteria (not duplicated here). Tier 1 checklist mirror → **`ENGAGEMENT_*`** §2 / §2.5 only. AI targeting stack (`CombatTargetScoring` incl. **`opponent_breach_file_targeting_mult`**, `CombatAIActionPicker`, intruder **`formation_id_for_zone_geometry`**, shared **`ZoneOfControl.formation_dict_for_zone_geometry`**) → **`AGENTS.md`** + **`.cursor/rules/fallen-paths.mdc`**.

| File | Topics |
|------|--------|
| [**IMPLEMENTATION_ORDER.md**](IMPLEMENTATION_ORDER.md) | **Combat implementation plan** — logical sequence, Tier 1 expanded steps, gate before coding |
| [ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) | Tier 1 **spec** — §4–§6; **Plan / code** + §2 **mirrors** plan milestone **Status** |
| [COMBAT_ROADMAP_AND_STAMINA.md](COMBAT_ROADMAP_AND_STAMINA.md) | Phases, stamina, snapshot; **Plan / code** — plan overrides Part 3 checklists |
| [TACTICAL_ZONES_BREACH_MOVEMENT.md](TACTICAL_ZONES_BREACH_MOVEMENT.md) | ZoC, surround, flanking, breach narrative; **Tier 2.1** |
| [TACTICAL_FORMATIONS_FF4.md](TACTICAL_FORMATIONS_FF4.md) | FF4 abstract model, distance, ambush; **Tier 2.2** |
| [AI_ENGAGEMENT_STANCE_AND_FEINTS.md](AI_ENGAGEMENT_STANCE_AND_FEINTS.md) | Stances, footwork, melee AI, feint/stamina; **Tier 4** |
| [PARRY_BIND_AND_WEAPON_GEOMETRY.md](PARRY_BIND_AND_WEAPON_GEOMETRY.md) | Weapon parts, bind/riposte vs HEMA; **Tier 3.0** / **3.1** |
| [PARRY_DEFLECT_AND_CALIBRATION.md](PARRY_DEFLECT_AND_CALIBRATION.md) | Deflection, parry options, calibration; **Tier 3.0** / **3.2** |
| [GUARDS_LINES_AFTERBLOW.md](GUARDS_LINES_AFTERBLOW.md) | Line guard, afterblow; **Tier 3.3** |
| [PHYSICS_DAMAGE_AND_FLOW.md](PHYSICS_DAMAGE_AND_FLOW.md) | Attack→damage flow, audits; **Tier 5** + **3.0** in pipeline |
| [MEDICAL_PAIN_INCAPACITATION.md](MEDICAL_PAIN_INCAPACITATION.md) | Pain, wounds, flee; **Tier 6** |
| [HEMA_ROADMAP_AND_SOURCES.md](HEMA_ROADMAP_AND_SOURCES.md) | HEMA roadmap, sources; **Tier 7** (non-blocking) |

**Regenerate** (requires restoring individual sources from git history): `python3 docs/consolidate_docs.py`

Typical size: ~1.1k–1.9k lines per bundle (manageable for editor/AI context).
