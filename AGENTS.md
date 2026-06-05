# Fallen Paths

[`docs/PLANNING.md`](docs/PLANNING.md) · [`docs/CURSOR.md`](docs/CURSOR.md) · [`docs/SHIP_PLAN.md`](docs/SHIP_PLAN.md) · [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md) · [`docs/CAMPAIGN_DECISION_GUIDE.md`](docs/CAMPAIGN_DECISION_GUIDE.md)

**Cursor:** [`.cursor/rules/fallen-paths.mdc`](.cursor/rules/fallen-paths.mdc) (gate · scope · combat guardrails)

<a id="code-homes"></a>

## Code homes (folder map)

Flat folders by design — find modules by **name prefix**, not subfolder. Do not add `combat/harness/` or `ui/battle/` before Camp-5 unless moving files for another reason.

| Path | Contents |
|------|----------|
| `combat/` | Tactical combat (~86 scripts, flat). Harness colocated: `CombatRegressionHarness*`, `CombatD001*`, `CombatF5Soak*`, `CombatCalibrationAudit` — not production menu/resolver paths. |
| `core/` | Entity sim: wounds, medical, damage, `CoreEntity` |
| `world/` | Campaign: economy, map, encounters, bridge (`PartySetup`, `PlayerCompanionSetup`, `SoakEncounterPresets`, …) |
| `ui/` | Battle + company UI (`BattleScene`, `PartyMenu`, `SettlementPanel`, …) |
| `weapon/`, `armor/`, `species/` | Strike, armor, species data |
| Root | `main.gd`, `main.tscn`, `character.gd` (shared — one stream per PR), `PartyManager.gd` |
| `scripts/` | Phase 0, Q audits, campaign ship audit (not in-game sim) |
| `docs/` | Planning and agent entry |

**Playtest artifacts (repo root, gitignored):** `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*` — one agent at a time; see [`scripts/README.md`](scripts/README.md).

## When implementing (skip for explain-only)

1. [File ownership](docs/PLANNING.md#file-ownership) · gate per `.cursor/rules/fallen-paths.mdc`
2. New **cross-cutting** API → one row below; trivial fixes need not update this file

## Agent task prompts (copy/paste)

**Combat fix**

> Stream: **Combat**. Smallest `combat/*.gd` owner per PLANNING. Use AGENTS canonical APIs. Prefer not to edit `world/*` unless bridge work. Gate before done: `PHASE0: PASS`.

**Campaign / EA**

> Stream: **Campaign**. `_CampaignBridge` + `CompanyState.gate_*()`. Lead on bridge files. Prefer not to edit `combat/*` unless cross-cutting. Gate: `PHASE0: PASS` + `CAMPAIGN_SHIP_AUDIT: PASS (headless)`.

**Playtest**

> Stream: **Playtest**. Phase 0 / F5 §8 / Q scripts per `scripts/README.md`. One agent at a time on `.f5_soak_in.txt`.

## Canonical APIs (combat / campaign)

Use these names in new code — avoid duplicating membership tests, manager private hooks, or raw move-id strings.

| Need | Use |
|------|-----|
| Advance day (wages, desertion, autosave) | `CompanyState.try_advance_day` · manual: `request_end_day` |
| Camp rest (heal + day tick) | `CompanyState.try_camp_heal` · `format_camp_rest_button_label` |
| Overworld tile | `CampaignEncounterBridge.overworld_tile_from_position` / `overworld_tile_center` |
| Campaign bridge preload | `_CampaignBridge` |
| Combatant by id | `CombatantEntityAccess.manager_get_combatant` |
| Health entity (combat) | `get_health_entity_from_node` / `get_entity_from_manager` |
| Health entity (campaign map) | `CampaignEncounterBridge.health_entity_from_character` |
| Skip turn | `CombatantEntityAccess.manager_skip_turn` + `CombatConstants.SKIP_TURN_LOG_*` |
| Medical danger / peril | `CombatantEntityAccess.is_in_medical_danger` / `is_in_immediate_peril` / `has_left_immediate_peril_permanently` |
| Medical coordination | `CombatMedicalCoordination.medical_action_allowed` · `track_failure_and_maybe_retry` |
| Ally medical menu | `MedicalPhaseController.get_ally_medical_actions` |
| Move ID strings | `CombatConstants.MOVE_ID_*` |
| Move membership | `CombatConstants.is_medical_move` · `is_formation_movement_move` (incl. flee) · `is_formation_reposition_move` (excl. flee) · `is_focus_line_move` |
| Clear doctrine commit after slot shuffle | `CombatDoctrine.clear_combatant_doctrine_commitment` · **`CombatFormationFlow`** (rotate/swap) · **`CombatFormationVacancyPlugs._apply_plug_move`** |
| Pincer role (center pin / flank wing) | `CombatDoctrine.pincer_role_for_combatant` · `pincer_flank_wing_should_close_at_long` · `propagate_pincer_wing_commitments_from_center` · `CombatTargetScoring.pincer_preferred_flank_target_mult` · `pincer_close_arc_spread_mult` |
| Untreated wounds (entity) | `CombatantEntityAccess.entity_has_untreated_wounds` · `entity_untreated_wound_part_names` — combat: `MedicalPhaseController.has_untreated_wounds` · campaign: `_CampaignBridge.entity_has_untreated_wounds` / `untreated_wound_part_names` |
| Action menu build | `AvailableActionsBuilder.build` → `CombatMeleeListing` / `CombatFormationMoveListing` / `CombatMedicalActionListing` |
| AI turn pick | `MentalStackDecider.try_pick` → else `CombatAIActionPicker.pick_weighted` |
| Strike-time defense | `DefenseChoiceResolver.choose_defense` (not turn pick) |
| Medical wind-up | `MedicalActionStarter.start` · complete: `MedicalWindUpHandler.complete` |
| Flee / rout warranted | `CombatantEntityAccess.flee_abandonment_warranted` → `CombatFormationRout.abandonment_warranted` |
| Zone geometry context | `ZoneOfControl.zone_geometry_line_context` · `opponent_formation_for_listing` · `pair_formations_for_targeting` |
| Combat milestone log | `CombatDebug.combat_session` · medical: `CombatDebug.medical_session` |
| Action resolve | `CombatResolveAction.resolve` |
| Formation diagram vitals | `PartyRowFormatter.total_body_health_ratio` · `body_functionality_ratio` — bars in `FormationDiagramBuilder` |

Implementation: `combat/CombatantEntityAccess.gd` · `combat/CombatConstants.gd` · `combat/MedicalPhaseController.gd` · `world/CampaignEncounterBridge.gd`

## Agent read order (canonical modules)

Read in this order when tracing a cross-cutting concern:

| Order | File | Owns |
|------:|------|------|
| 1 | `combat/CombatConstants.gd` | states → timing → medical `MOVE_ID_*` → formation/focus moves → flags → skip/close |
| 2 | `combat/CombatantEntityAccess.gd` | dict → lookup → health → **identity** → wounds → weapon → side/alive → vitals → manager hooks |
| 3 | `combat/MedicalPhaseController.gd` | gates → side → purge → halt → peril/danger → `can_end` → urgency → ally menu |
| 4 | `combat/CombatMedicalCoordination.gd` | `medical_action_allowed` first; retry; overlap; listing filters |
| 5 | `world/CampaignEncounterBridge.gd` | Tiles, campaign health, party roster, encounter meta (§1–§8 in file) |
| 6 | `combat/CombatResolveAction.gd` | Player/AI resolve dispatch |
| 7 | `combat/CombatDebug.gd` | All `[Combat*]` log tiers |
| 8 | `combat/CombatManager.gd` | Orchestration only — signals, turn loop, `_get_by_id` hook |
| 9 | `combat/AvailableActionsBuilder.gd` | Turn menu orchestration → listing modules |
| 10 | `combat/ZoneOfControl.gd` | Geometry packs → ZoC recompute → listing/targeting helpers |
| 11 | `combat/MentalStackDecider.gd` → `combat/CombatAIActionPicker.gd` | Turn pick pipeline (list → stack layers → weighted pick) |
| 12 | `combat/DefenseChoiceResolver.gd` → `combat/DefenseResolutionHandler.gd` | Strike-time parry/dodge choice → outcome resolution |
| 13 | `combat/AttackWindUpStarter.gd` → `combat/AttackResolver.gd` | Wind-up stamp → strike resolve pipeline |

**Cognition pipeline (shipped):** `AvailableActionsBuilder.build` → `MentalStackDecider.try_pick` → `CombatAIActionPicker.pick_weighted` → resolve via `CombatResolveAction.resolve` → defense at strike via `DefenseChoiceResolver`.

## Anti-patterns

| Do not | Do instead |
|--------|------------|
| `manager._get_by_id` / new `CombatManager._*` query wrappers | `CombatantEntityAccess` · specialist modules |
| `move_id in MEDICAL_MOVE_IDS` or raw `"pack_wound"` in production | `CombatConstants.is_*` / `MOVE_ID_*` |
| `manager._is_in_immediate_peril` (removed) | `CombatantEntityAccess.is_in_immediate_peril` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` / `medical_session` / `flow_log` |
| Inline gate literals / `read_stub_*` | `CompanyState.gate_*()` |
| Local `_tile_coords` / tile math | `_CampaignBridge.overworld_tile_*` |
| Duplicate untreated-wound checks on entity | `CombatantEntityAccess.entity_has_untreated_wounds` |
| Duplicate zone geometry pack helpers at call sites | `ZoneOfControl.opponent_formation_for_listing` / `pair_formations_for_targeting` |
| New `FEATURE_*` · bleed retune · Expand tiers | User must ask; frozen until Camp-5 per PLANNING |
| Harness literal strings copied into production | Literals OK in `*Tail.gd` / fixtures; production uses constants |

**Layers (do not conflate):** menu/resolver **move IDs** · CoreEntity **method names** (`apply_bandage`) · formation flow **`FORMATION_MOVE_KIND_*`** (`fall_back` menu vs `FORMATION_MOVE_KIND_FALL_BACK_PAIR` flow) — see `CombatFormationFlow.gd` header.

## Before adding code (light checklist)

- [ ] Owner in [PLANNING](docs/PLANNING.md#file-ownership)? Smallest existing module extended?
- [ ] Gate per [fallen-paths.mdc](.cursor/rules/fallen-paths.mdc) when shipping
- [ ] New cross-cutting API → row above (optional for one-liners)

## Module header template (combat / campaign modules)

```gdscript
## <One line: what this file owns.>
## Read order: <optional section outline for multi-section files>.
## Canonical: <API names or link AGENTS.md>.
## Manager requires: <only if methods called on manager Node>.
```

## File ownership

Full table: [`docs/PLANNING.md#file-ownership`](docs/PLANNING.md#file-ownership) · shared bridge: [`#bridge-rows-camp-2`](docs/PLANNING.md#bridge-rows-camp-2)

| Stream | Primary paths |
|--------|----------------|
| **Campaign** | `world/*`, `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `ui/CompanyHud.gd`, `world/CompanyState.gd` — setup: `world/PartySetup.gd`, `world/PlayerCompanionSetup.gd` |
| **Combat** | `combat/*` (flat; harness `*Tail.gd` / `CombatD001*` / `CombatF5Soak*` same folder), `ui/BattleUIUpdater`, battle formatters in `ui/` |
| **Shared (one agent)** | `world/CampaignEncounterBridge.gd`, `world/CombatFlow.gd` |
