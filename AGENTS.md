# Fallen Paths

[`docs/PLANNING.md`](docs/PLANNING.md) ? [`docs/CURSOR.md`](docs/CURSOR.md) ? [`docs/SHIP_PLAN.md`](docs/SHIP_PLAN.md) ? [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md) ? [`docs/CAMPAIGN_DECISION_GUIDE.md`](docs/CAMPAIGN_DECISION_GUIDE.md)

**Cursor:** [`.cursor/rules/fallen-paths.mdc`](.cursor/rules/fallen-paths.mdc) (gate ? scope ? combat guardrails) · **Agent prompts:** [`scripts/cursor/README.md`](scripts/cursor/README.md)

<a id="code-homes"></a>

## Code homes (folder map)

Flat folders by design ? find modules by **name prefix**, not subfolder. Do not add `combat/harness/` or `ui/battle/` subfolders unless reorganizing for another reason.

| Path | Contents |
|------|----------|
| `combat/` | Tactical combat (~86 scripts, flat). Harness colocated: `CombatRegressionHarness*`, `CombatD001*`, `CombatF5Soak*`, `CombatCalibrationAudit` ? not production menu/resolver paths. |
| `core/` | Entity sim: wounds, medical, damage, `CoreEntity` |
| `world/` | Campaign: economy, map, encounters, bridge (`PartySetup`, `PlayerCompanionSetup`, `SoakEncounterPresets`, ?) |
| `ui/` | Battle + company UI (`BattleScene`, `PartyMenu`, `SettlementPanel`, ?) |
| `weapon/`, `armor/`, `species/` | Strike, armor, species data |
| Root | `main.gd`, `main.tscn`, `character.gd` (shared ? one stream per PR), `PartyManager.gd` |
| `scripts/` | Phase 0, Q audits, campaign ship audit (not in-game sim) · copy-paste prompts in [`scripts/cursor/`](scripts/cursor/README.md) |
| `docs/` | Planning and agent entry |

**Playtest artifacts (repo root, gitignored):** `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*` ? one agent at a time; see [`scripts/README.md`](scripts/README.md).

## When implementing (skip for explain-only)

1. [File ownership](docs/PLANNING.md#file-ownership) ? gate per `.cursor/rules/fallen-paths.mdc`
2. New **cross-cutting** API ? one row below; trivial fixes need not update this file

## Agent task prompts (copy/paste)

**Index:** [`scripts/cursor/README.md`](scripts/cursor/README.md) — **Combat → Playtest → Campaign** · **Expand** only if user reopens §9c · **Medical bundle:** [Hygiene → Audit → Medical Physics](scripts/cursor/README.md#parallel-medical-quality-bundle).

| Stream | Copy-paste from | Gate |
|--------|-----------------|------|
| **Maintain** *(session default)* | [`agent_maintain.md`](scripts/cursor/agent_maintain.md) → stream `agent_*.md` | `PHASE0: PASS` |
| **Combat** | [`agent_combat.md`](scripts/cursor/agent_combat.md) (incl. [3e](scripts/cursor/agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](scripts/cursor/agent_combat.md#specialty-iii-6-line-plug)) | `PHASE0: PASS` |
| **Enhance** *(user-named row)* | [`agent_enhance.md`](scripts/cursor/agent_enhance.md) · Expand: [`README#expand-reopen`](scripts/cursor/README.md#expand-reopen) | `PHASE0: PASS` |
| **Playtest** | [`agent_playtest.md`](scripts/cursor/agent_playtest.md) · tools: [`scripts/README.md`](scripts/README.md) | one agent on `.f5_soak_in.txt` |
| **Campaign** | [`agent_campaign.md`](scripts/cursor/agent_campaign.md) | `CompanyStateChecks` **406** or Phase 0 + ship audit |
| **Hygiene · Audit** | [`agent_hygiene.md`](scripts/cursor/agent_hygiene.md) · [`agent_audit.md`](scripts/cursor/agent_audit.md) · bundle: [`README#project-health-bundle`](scripts/cursor/README.md#project-health-bundle) | Hygiene: no production `.gd`; hand off Audit for Phase 0 |
| **Medical** | [`README#medical-physics`](scripts/cursor/README.md#medical-physics) | `PHASE0: PASS` |

## Canonical APIs (combat / campaign)

Use these names in new code ? avoid duplicating membership tests, manager private hooks, or raw move-id strings.

| Need | Use |
|------|-----|
| Advance day (wages, desertion, autosave) | `CompanyState.try_advance_day` ? manual: `request_end_day` |
| Camp rest (heal + day tick) | `CompanyState.camp_heal_ready` · `try_camp_heal` · `apply_camp_rest_mood` · `format_camp_rest_button_label` · `format_camp_rest_tooltip` |
| Economy UX copy (Exp-3 maintain) | `format_end_day_button_label` · `format_wage_day_tick_suffix` · `format_provisions_day_tick_suffix` · `format_hud_economy_hint_lines` · `format_party_menu_footer` · `format_settlement_burial_debt_warning` · `ContractSpawner.format_settlement_deck_refresh_hint` · `format_hire_tooltip` |
| Daily provisions | `CompanyState.on_day_tick` · `get_food_supplies` · `set_food_supplies` · `read_stub_provisions_enabled` |
| Settlement burial costs | `CompanyState.apply_settlement_burial_costs` · `count_last_battle_deaths` · `BURIAL_GOLD_COST` |
| MS-CAMP mood → weapon form | `CompanyState.stance_preference_for_campaign_mood` · `CampaignEncounterBridge.apply_campaign_mood_stance_preferences` |
| Hire replacement at camp | `CompanyState.roster_has_hire_room` · `can_offer_hire` · `try_hire_rookie` · `PartySetup.spawn_hire_companion` |
| Rolling contract deck (post-tutorial) | `ContractSpawner.try_refresh_contract_deck` · `count_paid_contract_markers` · `CompanyState.get_contract_deck_index` |
| Post-victory afflictions | `CampaignAfflictions.apply_after_victory` · `format_scar_line` · `CompanyState.apply_post_victory_afflictions` |
| Tutorial contract (no pay / soft defeat) | `CompanyState.is_tutorial_contract` · `defeat_should_end_company_run` (paid R3 loss ends run) |
| Persistence gate (EA P1) | `CompanyState.read_stub_persistence_mode` ? `CampaignPersistence.clear_slot` on campaign boot / run-end reload |
| P2 save restore (harness / post-EA) | `CampaignPersistence.normalize_marker_kind_for_restore` · `apply_save` · `save_slot` · harness: `begin_harness_isolated_save` |
| Overworld tile | `CampaignEncounterBridge.overworld_tile_from_position` / `overworld_tile_center` |
| Overworld grid (XCamp-3.2) | `OverworldMap.MAP_TILES` · `map_tiles_for_world` · `is_tile_in_bounds` · `tile_coords_from_pos` · `tile_center` |
| Campaign bridge preload | `_CampaignBridge` |
| Combatant by id | `CombatantEntityAccess.manager_get_combatant` |
| Health entity (combat) | `get_health_entity_from_node` / `get_entity_from_manager` |
| Health entity (campaign map) | `CampaignEncounterBridge.health_entity_from_character` |
| Skip turn | `CombatantEntityAccess.manager_skip_turn` + `CombatConstants.SKIP_TURN_LOG_*` |
| Medical danger / peril | `CombatantEntityAccess.is_in_medical_danger` / `is_in_immediate_peril` / `has_left_immediate_peril_permanently` |
| Medical coordination | `CombatMedicalCoordination.medical_action_allowed` · `track_failure_and_maybe_retry` |
| Ally medical menu | `MedicalPhaseController.get_ally_medical_actions` |
| Move ID strings | `CombatConstants.MOVE_ID_*` |
| Move membership | `CombatConstants.is_medical_move` · `is_formation_movement_move` (incl. flee) · `is_formation_reposition_move` (excl. flee) · `is_focus_line_move` · `is_leader_formation_command_move` |
| Leader formation command (IV-11) | `FEATURE_LEADER_FORMATION_COMMAND` · `CombatLeaderFormationCommand` · `MOVE_ID_ORDER_*` · `CombatantEntityAccess.is_formation_command_issuer` · `AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT` · `AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT` · `is_party_leader` / `is_enemy_leader` · `CombatantEntityAccess.is_formation_telegraph_leader` |
| Weapon-reach ZoC (IV-13) | `FEATURE_IV13_WEAPON_REACH_ZOC` · `ZoneOfControl.weapon_reach_zoc_bonus_m` |
| Slot distraction (IV-12) | `FEATURE_IV12_SLOT_DISTRACTION` · `FormationSlots.slot_key_for_combatant_id` · `TacticalCombat._iv12_threat_cell_key` · `iv12_offense_weight_mult` · `attacker_has_co_located_slot_mate_threatening` |
| Clear doctrine commit after slot shuffle | `CombatDoctrine.clear_combatant_doctrine_commitment` · **`CombatFormationFlow`** (rotate/swap) · **`CombatFormationVacancyPlugs._apply_plug_move`** |
| Pincer role (center pin / flank wing) | `CombatDoctrine.pincer_role_for_combatant` · `pincer_flank_wing_should_close_at_long` · `propagate_pincer_wing_commitments_from_center` · `CombatTargetScoring.pincer_preferred_flank_target_mult` · `CombatDoctrine.pincer_close_arc_spread_mult` |
| Post-rout envelop mop-up (**3e**) | `CombatDoctrine.envelop_mop_up_active` · `envelop_close_allowed` · `hold_line_close_pick_eligible` · `fight_finish_tail_active` · `sparse_line_prefer_finish_over_shuffle` · `should_suppress_skirmish_rotate_file` · `CombatListedActions.action_list_has_hostile_melee_strike` |
| Map field care (post-fight) | `MapFieldCare.try_field_*` · `format_next_field_care_action` · `format_*_button_label` · `triage_med_budget` / `format_party_triage_gate_line` / `format_settlement_field_care_hint` / `format_party_button_label` in `CompanyState` — hemorrhage sim only; camp rest heals |
| Untreated wounds (entity) | `EntityWounds.entity_has_untreated_wounds` · `sorted_untreated_part_names` · campaign: `_CampaignBridge.entity_has_untreated_wounds` / `untreated_wound_part_names` · combat phase: `MedicalPhaseController.has_untreated_wounds` |
| Action menu build | `AvailableActionsBuilder.build` ? `CombatMeleeListing` / `CombatFormationMoveListing` / `CombatMedicalActionListing` |
| AI turn pick | `MentalStackDecider.try_pick` ? else `CombatAIActionPicker.pick_weighted` |
| Strike-time defense | `DefenseChoiceResolver.choose_defense` (not turn pick) |
| Medical wind-up | `MedicalActionStarter.start` ? complete: `MedicalWindUpHandler.complete` |
| Flee / rout warranted | `CombatantEntityAccess.flee_abandonment_warranted` ? `CombatFormationRout.abandonment_warranted` |
| Zone geometry context | `ZoneOfControl.zone_geometry_line_context` ? `opponent_formation_for_listing` ? `pair_formations_for_targeting` |
| Combat milestone log | `CombatDebug.combat_session` ? medical: `CombatDebug.medical_session` |
| Action resolve | `CombatResolveAction.resolve` |
| Formation diagram vitals | `PartyRowFormatter.total_body_health_ratio` ? `body_functionality_ratio` ? bars in `FormationDiagramBuilder` |
| Weapon form (**WF shipped** — maintain) | `CombatantEntityAccess.form_str` · `CombatWeaponForm.*` (see [`LIVE_PATHS#wf-implementation-status`](docs/LIVE_PATHS.md#wf-implementation-status)) · spawn: **`CombatWeaponForm.seed_combatant_form`** — [`#spawn--reset-path-wf-1a`](docs/LIVE_PATHS.md#spawn--reset-path-wf-1a) · switch: **`assign_form`** · UI: `CombatUiHints.weapon_form_*` · auto-switch: **`evaluate_automatic_form`** in **`CombatAIActionPicker.pick`** only |
| Footing / guard / form attachment | Doc map [`#wf-footing-doc-map`](docs/LIVE_PATHS.md#wf-footing-doc-map) · maintain backlog [`#wf-footing-improvement-backlog`](docs/LIVE_PATHS.md#wf-footing-improvement-backlog) · Tier 4.4 PA hub [`#wf-tier-44-pa`](docs/LIVE_PATHS.md#wf-tier-44-pa) · **`assign_form`** [`#wf-assign-form-contract`](docs/LIVE_PATHS.md#wf-assign-form-contract) · **`guard_line`** writers [`#wf-guard-writers`](docs/LIVE_PATHS.md#wf-guard-writers) · pick vs strike [`#wf-pick-vs-strike`](docs/LIVE_PATHS.md#wf-pick-vs-strike) · soak **ii5c/ii8** [`#wf-soak-audit-status`](docs/LIVE_PATHS.md#wf-soak-audit-status) · F5 paste **WF-M3:** `validate_f5_soak_log.ps1` / `run_q_feel.ps1 -Track Camp` → **`wf_m3_*`** tracks · UI: `CombatUiHints.active_line_for_ui` · gauge order Step → `guard_line_gauge_suffix` → `weapon_form_gauge_suffix` |
| Tier 4.4 PA lifecycle | **`CombatFootwork.guard_angle_deg`** at strike contact · **`clear_on_exchange_end`** · **`attack_eval_step_deg_for_attacker`** · **`attack_angle_deg_for_listing_preview`** (idle eval / wind-up stamp) · **`parry_eval_step_deg_for_defender`** · **`dodge_eval_step_deg_for_defender`** match stamp mults · spatial: **`FEATURE_T44_SPATIAL_*`** |
| Tier 4.2 / III-8 recovery cause | **`CombatConstants.normalize_recovery_cause`** · **`readiness_curve_for_cause`** · **`defense_footwork_recovering_dodge_mult_for_cause`** |
| L3 guard line for UI / parry step | `CombatUiHints.active_line_for_ui` · live **`guard_line`** on dict (writers per **`GuardLineUpdater`**) |
| Wait / focus form bias | `CombatWeaponForm.wait_action_weight_mult` · `preferred_guards` · `CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT` |

Implementation: `combat/CombatantEntityAccess.gd` ? `combat/CombatConstants.gd` ? `combat/MedicalPhaseController.gd` ? `world/CampaignEncounterBridge.gd`

## Agent read order (canonical modules)

Read in this order when tracing a cross-cutting concern:

| Order | File | Owns |
|------:|------|------|
| 1 | `combat/CombatConstants.gd` | states ? timing ? medical `MOVE_ID_*` ? formation/focus moves ? flags ? skip/close |
| 2 | `combat/CombatantEntityAccess.gd` | dict ? lookup ? health ? **identity** ? wounds ? weapon ? side/alive ? vitals ? manager hooks; **`form_str`** (L2 id, not PA/guard) — [`#wf-assign-form-contract`](docs/LIVE_PATHS.md#wf-assign-form-contract) |
| 3 | `combat/MedicalPhaseController.gd` | gates ? side ? purge ? halt ? peril/danger ? `can_end` ? urgency ? ally menu |
| 4 | `combat/CombatMedicalCoordination.gd` | `medical_action_allowed` first; retry; overlap; listing filters |
| 5 | `world/CampaignEncounterBridge.gd` | Tiles, campaign health, party roster, encounter meta (?1??8 in file) |
| 6 | `combat/CombatResolveAction.gd` | Player/AI resolve dispatch |
| 7 | `combat/CombatDebug.gd` | All `[Combat*]` log tiers |
| 8 | `combat/CombatManager.gd` | Orchestration only ? signals, turn loop, `_get_by_id` hook; **`seed_combatant_form`** on register — [`#spawn--reset-path-wf-1a`](docs/LIVE_PATHS.md#spawn--reset-path-wf-1a) |
| 9 | `combat/AvailableActionsBuilder.gd` | Turn menu orchestration ? listing modules |
| 10 | `combat/ZoneOfControl.gd` | Geometry packs ? ZoC recompute ? listing/targeting helpers |
| 11 | `combat/MentalStackDecider.gd` ? `combat/CombatAIActionPicker.gd` | Turn pick pipeline (list ? stack layers ? weighted pick) |
| 11b | `combat/CombatWeaponForm.gd` *(WF **shipped** — maintain)* | Per-fighter form defs, move weights, yomi inference, counter mult, auto-switch — [`LIVE_PATHS#wf-implementation-status`](docs/LIVE_PATHS.md#wf-implementation-status) |
| 12 | `combat/DefenseChoiceResolver.gd` ? `combat/DefenseResolutionHandler.gd` | Strike-time parry/dodge choice ? outcome resolution |
| 12a | `combat/AttackResolver.gd` ? `combat/AttackResultApplier.gd` ? `combat/CombatStateHandlers.gd` | Strike path PA stamp/clear + L3 guard drift — [`#wf-tier-44-pa`](docs/LIVE_PATHS.md#wf-tier-44-pa) · grep [`#wf-production-call-sites`](docs/LIVE_PATHS.md#wf-production-call-sites) |
| 12b | `combat/CombatFootwork.gd` *(Tier 4.4 pilot)* | PA owner — [`#wf-tier-44-pa`](docs/LIVE_PATHS.md#wf-tier-44-pa) |
| 12c | `combat/GuardLineUpdater.gd` | Outcome **`guard_line`** drift; form **`assign_form`** sets home only — [`#wf-guard-writers`](docs/LIVE_PATHS.md#wf-guard-writers) |
| 12d | `combat/CombatGuardLines.gd` | D-006 **`normalize_line`** + octant PA step table — [`#wf-tier-44-pa`](docs/LIVE_PATHS.md#wf-tier-44-pa) · [`#wf-form-guard-pa-matrix`](docs/LIVE_PATHS.md#wf-form-guard-pa-matrix) |
| 12e | `combat/CombatUiHints.gd` · `ui/BattleUIUpdater.gd` · `ui/FormationDiagramBuilder.gd` · `ui/TurnReadyHandler.gd` · `combat/CombatF5SoakTrace.gd` | Suffix helpers + gauge compose + F5 **`turn_ready_gauge`** — [`#battle-ui`](docs/LIVE_PATHS.md#battle-ui) · [`#wf-1c--ui-surfacing`](docs/LIVE_PATHS.md#wf-1c--ui-surfacing) · soak [`#wf-soak-audit-status`](docs/LIVE_PATHS.md#wf-soak-audit-status) |
| 13 | `combat/AttackWindUpStarter.gd` ? `combat/AttackResolver.gd` | Wind-up stamp ? strike resolve pipeline |

**Cognition pipeline (shipped):** `AvailableActionsBuilder.build` ? `MentalStackDecider.try_pick` ? `CombatAIActionPicker.pick_weighted` ? resolve via `CombatResolveAction.resolve` ? defense at strike via `DefenseChoiceResolver`.

## Anti-patterns

| Do not | Do instead |
|--------|------------|
| `const X := SomeClass.Y` (non-preload class ref) | `const _X := preload("res://path/SomeClass.gd")` then `const X := _X.Y` — or create standalone module with literal consts |
| `manager._get_by_id` / new `CombatManager._*` query wrappers | `CombatantEntityAccess` ? specialist modules |
| `move_id in MEDICAL_MOVE_IDS` or raw `"pack_wound"` in production | `CombatConstants.is_*` / `MOVE_ID_*` |
| `manager._is_in_immediate_peril` (removed) | `CombatantEntityAccess.is_in_immediate_peril` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` / `medical_session` / `flow_log` |
| Inline gate literals / `read_stub_*` | `CompanyState.gate_*()` |
| Local `_tile_coords` / tile math | `_CampaignBridge.overworld_tile_*` |
| Duplicate untreated-wound checks on entity | `CombatantEntityAccess.entity_has_untreated_wounds` |
| Duplicate zone geometry pack helpers at call sites | `ZoneOfControl.opponent_formation_for_listing` / `pair_formations_for_targeting` |
| Conflate **weapon form** (WF) with **`guard_line`**, formation **doctrine**, or formation **`engagement_posture`** (LINE/OPEN/DUEL) | [`LIVE_PATHS#wf-footing-guards-stances`](docs/LIVE_PATHS.md#wf-footing-guards-stances) · four-layer table |
| Conflate **`CombatFootwork`** (Tier 4.4 PA step) with tier-4.2 **`defense_footwork_*`** (spacing/state) or formation **`rotate_file`** | [`LIVE_PATHS#wf-footing-guards-stances`](docs/LIVE_PATHS.md#wf-footing-guards-stances) terminology table |
| Conflate **`ZoneOfControl.get_footing_duration_multiplier`** (lane step-over duration) with WF / PA / **`guard_line`** | Formation lane footing row — [`#wf-layer-labels`](docs/LIVE_PATHS.md#wf-layer-labels) |
| Treat **`PassiveParryContext.guard_readiness_float`** as L3 **`guard_line`** | Readiness gauge 0..1 — blade posture is **`guard_line`** + PA via **`CombatFootwork.guard_angle_deg`** | [`#wf-layer-labels`](docs/LIVE_PATHS.md#wf-layer-labels) |
| Use **`CombatConstants.get_guard_angle_deg`** at strike contact when PA flag on | Offset ignored — parry/path drift | **`CombatFootwork.guard_angle_deg`** — [`#wf-tier-44-pa`](docs/LIVE_PATHS.md#wf-tier-44-pa) (geometry) |
| Wire PA lookup through **`CombatGuardLines`** octant table without **`_run_footwork_wf_t1_octant_suite`** (or its sub-rows) | Octant delegate lives in **`CombatConstants.position_angle_offset_deg_for_attack_line`** when eight-guard flag on — [`#wf-form-guard-pa-matrix`](docs/LIVE_PATHS.md#wf-form-guard-pa-matrix) |
| **`get_stance_modifier`** at new production call sites | **`CombatWeaponForm.mod(_EntityAccess.form_str(c), effect)`** — delegate kept for harness only ([#wf-footing-improvement-backlog](docs/LIVE_PATHS.md#wf-footing-improvement-backlog) WF-M5) |
| Wire **`weapon_form`** → **`position_angle_offset_deg`** | Steps from **attack_line** / **guard_line** / dodge part only — form sets home guard, not offset |
| Assume eight-line **`high_right`** etc. get L4 step offset | **`POSITION_ANGLE_OFFSET_DEG_BY_LINE`** is **`high`/`low`/`left`/`right`** only — extend table + harness first |
| Fold auto-switch into **`evaluate_automatic_doctrine`** or hook WF-3 on **`process_waiting`** **and** **`pick`** | **`evaluate_automatic_form`** in **`CombatAIActionPicker.pick`** only — see [`LIVE_PATHS#wf-implementation-pitfalls`](docs/LIVE_PATHS.md#wf-implementation-pitfalls) |
| New `FEATURE_*` ? bleed retune ? closed IV-1,3,5–13 | User must ask; Expand one row per PR per [§9c](docs/SHIP_PLAN.md#combat-expand-registry) |
| Harness literal strings copied into production | Literals OK in `*Tail.gd` / fixtures; production uses constants |

**Layers (do not conflate):** menu/resolver **move IDs** ? CoreEntity **method names** (`apply_bandage`) ? formation flow **`FORMATION_MOVE_KIND_*`** (`fall_back` menu vs `FORMATION_MOVE_KIND_FALL_BACK_PAIR` flow) ? see `CombatFormationFlow.gd` header.

## Before adding code (light checklist)

- [ ] Owner in [PLANNING](docs/PLANNING.md#file-ownership)? Smallest existing module extended?
- [ ] Gate per [fallen-paths.mdc](.cursor/rules/fallen-paths.mdc) when shipping
- [ ] New cross-cutting API ? row above (optional for one-liners)

## Module header template (combat / campaign modules)

```gdscript
## <One line: what this file owns.>
## Read order: <optional section outline for multi-section files>.
## Canonical: <API names or link AGENTS.md>.
## Manager requires: <only if methods called on manager Node>.
```

## File ownership

Full table: [`docs/PLANNING.md#file-ownership`](docs/PLANNING.md#file-ownership) ? shared bridge: [`#bridge-rows-camp-2`](docs/PLANNING.md#bridge-rows-camp-2)

| Stream | Primary paths |
|--------|----------------|
| **Campaign** | `world/*`, `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `ui/CompanyHud.gd`, `world/CompanyState.gd` ? setup: `world/PartySetup.gd`, `world/PlayerCompanionSetup.gd` |
| **Combat** | `combat/*` (flat; harness `*Tail.gd` / `CombatD001*` / `CombatF5Soak*` same folder), `ui/BattleUIUpdater`, battle formatters in `ui/` |
| **Shared (one agent)** | `world/CampaignEncounterBridge.gd`, `world/CombatFlow.gd` |
