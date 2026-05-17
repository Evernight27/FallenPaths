# Combat documentation (consolidated)

**Start here:** [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) — [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary), [next coding step](IMPLEMENTATION_ORDER.md#next-coding-step), [Development gate](IMPLEMENTATION_ORDER.md#development-gate-line-crash--intrusions-temporary), [dependency chain](IMPLEMENTATION_ORDER.md#dependency-chain-execution-logic), [document map](IMPLEMENTATION_ORDER.md#document-map-read-order). No parallel status column in this index.

**Harness names (no Status):** [`REGRESSION_HARNESS_MAP_TIER19.md`](REGRESSION_HARNESS_MAP_TIER19.md) — exhaustive `_run_*` registry; grep `combat/CombatRegressionHarness.gd` when adding tests.

**Companion bundles:** skim **`Plan / code`** + **`Source:`** at the top of each linked file; long investigations are design depth, not sequencing.

### By task

| If you need… | Read… |
|--------------|--------|
| **Plan, gate, next coding step** | [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md) — [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary) · [next coding step](IMPLEMENTATION_ORDER.md#next-coding-step) · [Development gate](IMPLEMENTATION_ORDER.md#development-gate-line-crash--intrusions-temporary) (`FEATURE_LINE_CRASH_INTRUSION`, default **false**) |
| **Headless combat regression harness** | Command in [`AGENTS.md`](../AGENTS.md); VS Code / Cursor task **Run Combat Regression Harness (headless)** in [`.vscode/tasks.json`](../.vscode/tasks.json) (uses **`godotTools.editorPath.godot4`** in [`.vscode/settings.json`](../.vscode/settings.json)). |
| **Exhaustive `_run_*` harness names** | [`REGRESSION_HARNESS_MAP_TIER19.md`](REGRESSION_HARNESS_MAP_TIER19.md) (registry; plan §§ link here, not per-harness lists) |
| **Shipped-tier live paths** (modules + harness grep) | Tier **1.9:** [plan §1.9](IMPLEMENTATION_ORDER.md#tier-19--p10-depth-rank-polearm-reach--spear-lanes) · Tier **3:** [`PARRY_BIND`](PARRY_BIND_AND_WEAPON_GEOMETRY.md) [3.1](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-31-strike-measure-live-path) · [3.2](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-32-parry-bind-live-path) · [`GUARDS`](GUARDS_LINES_AFTERBLOW.md#tier-33-guard-line-afterblow-live-path) **3.3** · Tier **4:** [`AI_ENGAGEMENT`](AI_ENGAGEMENT_STANCE_AND_FEINTS.md) [4.1](AI_ENGAGEMENT_STANCE_AND_FEINTS.md#tier-41-posture--stance-weights-ai-listing-live-path)–[4.4](AI_ENGAGEMENT_STANCE_AND_FEINTS.md#tier-44-position-angle-footwork-live-path) · Tier **5.1:** [`PHYSICS`](PHYSICS_DAMAGE_AND_FLOW.md#tier-51-kinematic-audit) · Tier **6.1:** [`MEDICAL`](MEDICAL_PAIN_INCAPACITATION.md#tier-61-mobility-pain-shock-live-path) |
| **Tier 1 spec** (fields, plugs, tuning) | [`ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) — §4–§6 spec; §2 verification mirror (**not** harness names) |
| **Shipped baseline** (modules) | [Tier 0](IMPLEMENTATION_ORDER.md#tier-0--baseline-shipped--maintain) · behavior snapshot in [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) |
| **Historical phases + stamina / investigations** | [`COMBAT_ROADMAP_AND_STAMINA.md`](COMBAT_ROADMAP_AND_STAMINA.md) — long bundle; snapshot at top for “today.” |
| **ZoC / breach narrative** | [`TACTICAL_ZONES_BREACH_MOVEMENT.md`](TACTICAL_ZONES_BREACH_MOVEMENT.md) — Tier 2 sync in `IMPLEMENTATION_ORDER` after P3+. |
| **IDE / agent map** (not a status source) | [`AGENTS.md`](../AGENTS.md) and [`.cursor/rules/fallen-paths.mdc`](../.cursor/rules/fallen-paths.mdc) — both defer combat milestones to `IMPLEMENTATION_ORDER.md`. |

---

**13** markdown files in the table below (master plan + topic bundles + harness registry; order = [plan inventory](IMPLEMENTATION_ORDER.md#plan-inventory-all-combat-markdown)). Tier 1 checklist mirror → **`ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`** §2 / §2.5.

| File | Topics |
|------|--------|
| [**IMPLEMENTATION_ORDER.md**](IMPLEMENTATION_ORDER.md) | Plan — [document map](IMPLEMENTATION_ORDER.md#document-map-read-order) order |
| [REGRESSION_HARNESS_MAP_TIER19.md](REGRESSION_HARNESS_MAP_TIER19.md) | Exhaustive `_run_*` registry — not sequencing |
| [ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) | Tier 1 **spec** §4–§6; §2 mirrors plan **Status** |
| [COMBAT_ROADMAP_AND_STAMINA.md](COMBAT_ROADMAP_AND_STAMINA.md) | Stamina + historical phases; snapshot at top |
| [TACTICAL_ZONES_BREACH_MOVEMENT.md](TACTICAL_ZONES_BREACH_MOVEMENT.md) | ZoC / breach narrative — **Tier 2.1** |
| [TACTICAL_FORMATIONS_FF4.md](TACTICAL_FORMATIONS_FF4.md) | FF4 formation model — **Tier 2.2** |
| [PARRY_BIND_AND_WEAPON_GEOMETRY.md](PARRY_BIND_AND_WEAPON_GEOMETRY.md) | Tier **3.1–3.2** [live paths](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-31-strike-measure-live-path) |
| [PARRY_DEFLECT_AND_CALIBRATION.md](PARRY_DEFLECT_AND_CALIBRATION.md) | Deflect calibration depth → [3.2 live path](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-32-parry-bind-live-path) |
| [GUARDS_LINES_AFTERBLOW.md](GUARDS_LINES_AFTERBLOW.md) | Tier **3.3** [live path](GUARDS_LINES_AFTERBLOW.md#tier-33-guard-line-afterblow-live-path) |
| [PHYSICS_DAMAGE_AND_FLOW.md](PHYSICS_DAMAGE_AND_FLOW.md) | Tier **5.1** [kinematic audit](PHYSICS_DAMAGE_AND_FLOW.md#tier-51-kinematic-audit) |
| [AI_ENGAGEMENT_STANCE_AND_FEINTS.md](AI_ENGAGEMENT_STANCE_AND_FEINTS.md) | Tier **4** [live paths](AI_ENGAGEMENT_STANCE_AND_FEINTS.md#tier-41-posture--stance-weights-ai-listing-live-path) **4.1–4.4** |
| [MEDICAL_PAIN_INCAPACITATION.md](MEDICAL_PAIN_INCAPACITATION.md) | **Tier 6** [6.1 live path](MEDICAL_PAIN_INCAPACITATION.md#tier-61-mobility-pain-shock-live-path) |
| [HEMA_ROADMAP_AND_SOURCES.md](HEMA_ROADMAP_AND_SOURCES.md) | **Tier 7** (non-blocking) |

**Regenerate** (requires restoring individual sources from git history): `python3 docs/consolidate_docs.py`
