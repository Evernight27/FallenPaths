# Agent API reference (on-demand)

**Not always-on.** Open when adding cross-cutting APIs or tracing a concern. Entry: [`../AGENTS.md`](../AGENTS.md) · prompts: [`../tools/ci/agent_prompts/README.md`](../tools/ci/agent_prompts/README.md).

**Budget:** ≤1 doc section + ≤3 owning `.gd` files before first edit. Do **not** preload the module lookup table below.

<a id="canonical-apis"></a>

## Canonical APIs (combat / campaign)

Use these names in new code — avoid duplicating membership tests, manager private hooks, or raw move-id strings.

| Need | Use |
|------|-----|
| Advance day (wages, desertion, autosave) | `CompanyState.try_advance_day` — manual: `request_end_day` |
| Camp rest (heal + day tick) | `CompanyState.camp_heal_ready` · `try_camp_heal` · `apply_camp_rest_mood` · `format_camp_rest_button_label` · `format_camp_rest_tooltip` |
| Economy UX copy (Exp-3 maintain) | `format_end_day_button_label` · `format_wage_day_tick_suffix` · `format_provisions_day_tick_suffix` · `format_hud_economy_hint_lines` · `format_party_menu_footer` · `format_settlement_burial_debt_warning` · `ContractSpawner.format_settlement_deck_refresh_hint` · `format_hire_tooltip` |
| Daily provisions | `CompanyState.on_day_tick` · `get_food_supplies` · `set_food_supplies` · `read_stub_provisions_enabled` |
| Settlement burial costs | `CompanyState.apply_settlement_burial_costs` · `count_last_battle_deaths` · `BURIAL_GOLD_COST` |
| MS-CAMP mood → weapon form | `CompanyState.stance_preference_for_campaign_mood` · `CampaignEncounterBridge.apply_campaign_mood_stance_preferences` |
| Hire replacement at camp | `CompanyState.roster_has_hire_room` · `can_offer_hire` · `try_hire_rookie` · `PartySetup.spawn_hire_companion` |
| Rolling contract deck (post-tutorial) | `ContractSpawner.try_refresh_contract_deck` · `count_paid_contract_markers` · `CompanyState.get_contract_deck_index` |
| Post-victory afflictions | `CampaignAfflictions.apply_after_victory` · `format_scar_line` · `CompanyState.apply_post_victory_afflictions` |
| Tutorial contract (no pay / soft defeat) | `CompanyState.is_tutorial_contract` · `defeat_should_end_company_run` (paid R3 loss ends run) |
| Persistence gate (P2 shipped) | `CompanyState.read_stub_persistence_mode` — boot restores autosave (`load_campaign_autosave_for_boot`); `clear_slot` only on new company / invalid save |
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
| Map field care (post-fight) | `MapFieldCare.try_field_*` · `format_next_field_care_action` · `format_*_button_label` · `triage_med_budget` / `format_party_triage_gate_line` / `format_settlement_field_care_hint` · `format_party_button_label` in `CompanyState` — hemorrhage sim only; camp rest heals |
| Untreated wounds (entity) | `EntityWounds.entity_has_untreated_wounds` · `sorted_untreated_part_names` · campaign: `_CampaignBridge.entity_has_untreated_wounds` / `untreated_wound_part_names` · combat phase: `MedicalPhaseController.has_untreated_wounds` |
| Action menu build | `AvailableActionsBuilder.build` — `CombatMeleeListing` / `CombatFormationMoveListing` / `CombatMedicalActionListing` |
| AI turn pick | `MentalStackDecider.try_pick` — else `CombatAIActionPicker.pick_weighted` |
| Strike-time defense | `DefenseChoiceResolver.choose_defense` (not turn pick) |
| Medical wind-up | `MedicalActionStarter.start` — complete: `MedicalWindUpHandler.complete` |
| Flee / rout warranted | `CombatantEntityAccess.flee_abandonment_warranted` — `CombatFormationRout.abandonment_warranted` |
| Zone geometry context | `ZoneOfControl.zone_geometry_line_context` — `opponent_formation_for_listing` — `zone_geometry_for_pair` / `zone_geometry_*_from_pair_pack` |
| Combat milestone log | `CombatDebug.combat_session` — medical: `CombatDebug.medical_session` |
| Action resolve | `CombatResolveAction.resolve` |
| Formation diagram vitals | `PartyRowFormatter.total_body_health_ratio` — `body_functionality_ratio` — bars in `FormationDiagramBuilder` |
| Weapon form (**WF shipped** — maintain) | `CombatantEntityAccess.form_str` · `CombatWeaponForm.*` (see [`LIVE_PATHS#wf-implementation-status`](LIVE_PATHS.md#wf-implementation-status)) · spawn: **`CombatWeaponForm.seed_combatant_form`** — [`#spawn--reset-path-wf-1a`](LIVE_PATHS.md#spawn--reset-path-wf-1a) · switch: **`assign_form`** · UI: `CombatUiHints.weapon_form_*` · auto-switch: **`evaluate_automatic_form`** in **`CombatAIActionPicker.pick`** only |
| Footing / guard / form | [`LIVE_PATHS#wf-footing-doc-map`](LIVE_PATHS.md#wf-footing-doc-map) · PA [`#wf-tier-44-pa`](LIVE_PATHS.md#wf-tier-44-pa) · soak [`#wf-soak-audit-status`](LIVE_PATHS.md#wf-soak-audit-status) · UI: `CombatUiHints.active_line_for_ui` |
| Tier 4.4 PA lifecycle | **`CombatFootwork.guard_angle_deg`** at strike contact · **`clear_on_exchange_end`** · **`attack_eval_step_deg_for_attacker`** · **`attack_angle_deg_for_listing_preview`** (idle eval / wind-up stamp) · **`parry_eval_step_deg_for_defender`** · **`dodge_eval_step_deg_for_defender`** match stamp mults · spatial: **`FEATURE_T44_SPATIAL_*`** |
| Tier 4.2 / III-8 recovery cause | **`CombatConstants.normalize_recovery_cause`** · **`readiness_curve_for_cause`** · **`defense_footwork_recovering_dodge_mult_for_cause`** |
| L3 guard line for UI / parry step | `CombatUiHints.active_line_for_ui` · live **`guard_line`** on dict (writers per **`GuardLineUpdater`**) |
| Wait / focus form bias | `CombatWeaponForm.wait_action_weight_mult` · `preferred_guards` · `CombatConstants.AI_FOCUS_LINE_FORM_PREFERRED_MULT` |
| Composure (gauge) | `gauge` 0–100 (`DataKeys.COMBATANT_GAUGE`) — **event-driven**: `CombatEventDispatch.handle_action_ready` sets 100; wind-up / recovery / medical / form-switch set 0; cowering idle fills 0.5/s (`CombatStateHandlers.process_cowering_idle`); persist via `CampaignComposureSync` |
| Composure thresholds | counter-tempo ready ≥ `CombatConstants.COUNTER_TEMPO_GAUGE_THRESHOLD` (50) · AI/action-list gate `< GAUGE_FULL_THRESHOLD` (99) — **no** wind-up cost deduction, **no** quality/parry scaling |
| Parry lockout | `CombatConstantsParry.OFF_BALANCE_DURATION_S` (0.4s) — set on parry_deflect in `AttackResultApplier`, gated in `DefenseChoiceResolver` |
| Under attack check | `CombatIncomingParryChoice.incoming_attacker_ids_on_defender(manager, defender_id)` — scans WIND_UP combatants for `pending_attack` targeting this id |
| Two-handed weapon | `resources/weapons/Weapon.gd` `is_two_handed` flag · `WeaponConstants.weapon_is_two_handed(weapon)` helper |
| Breath / stamina | Keys `"breath"` + `"stamina"` · `stamina_factor()` (canonical) · `breath_factor()` alias · `CombatExhaustion.effective_breath_refill_rate` |
| Wait (no gauge reset) | `CombatResolveAction.resolve` → `manager.skip_turn(..., SKIP_TURN_LOG_WAIT)` — zeroes gauge, schedules action_ready at `READY_DELAY_SKIP_DEFAULT_S` (0.5s) |

Implementation hubs: `combat/access/CombatantEntityAccess.gd` · `combat/access/CombatantRegister.gd` · `combat/access/CombatantView.gd` · `combat/CombatConstants.gd` · `combat/medical/MedicalPhaseController.gd` · `world/CampaignEncounterBridge.gd`

Combatant dict fields: `combat/access/CombatantFieldRegistry.gd` · packages: [`../combat/README.md`](../combat/README.md) · layout: [`ARCHITECTURE`](ARCHITECTURE.md) · bridge: [`BRIDGE_CONTRACT`](BRIDGE_CONTRACT.md)

<a id="module-lookup"></a>

## Module lookup map (grep targets — do not preload)

Use when tracing a cross-cutting concern. Open **only** the owning file(s) for your task — do not read this list top-to-bottom.

| Order | File | Owns |
|------:|------|------|
| 1 | `combat/CombatConstants.gd` | states · timing · medical `MOVE_ID_*` · formation/focus moves · flags · skip/close |
| 2 | `combat/access/CombatantEntityAccess.gd` | dict · lookup · health · **identity** · wounds · weapon · side/alive · vitals · manager hooks; **`form_str`** (L2 id, not PA/guard) — [`#wf-assign-form-contract`](LIVE_PATHS.md#wf-assign-form-contract) |
| 3 | `combat/medical/MedicalPhaseController.gd` | gates · side · purge · halt · peril/danger · `can_end` · urgency · ally menu |
| 4 | `combat/medical/CombatMedicalCoordination.gd` | `medical_action_allowed` first; retry; overlap; listing filters |
| 5 | `world/CampaignEncounterBridge.gd` | Tiles, campaign health, party roster, encounter meta |
| 6 | `combat/flow/CombatResolveAction.gd` | Player/AI resolve dispatch |
| 7 | `combat/CombatDebug.gd` | All `[Combat*]` log tiers |
| 8 | `combat/CombatManager.gd` | Orchestration only · signals, turn loop, `_get_by_id` hook; **`seed_combatant_form`** on register — [`#spawn--reset-path-wf-1a`](LIVE_PATHS.md#spawn--reset-path-wf-1a) |
| 9 | `combat/ai/AvailableActionsBuilder.gd` | Turn menu orchestration · listing modules |
| 10 | `combat/formation/ZoneOfControl.gd` | Geometry packs · ZoC recompute · listing/targeting helpers |
| 11 | `combat/ai/MentalStackDecider.gd` · `combat/ai/CombatAIActionPicker.gd` | Turn pick pipeline |
| 11b | `combat/weapon_form/CombatWeaponForm.gd` *(WF **shipped** — maintain)* | Form defs, weights, yomi, counter, auto-switch — [`LIVE_PATHS#wf-implementation-status`](LIVE_PATHS.md#wf-implementation-status) |
| 12 | `combat/strike/DefenseChoiceResolver.gd` · `combat/strike/DefenseResolutionHandler.gd` | Strike-time parry/dodge |
| 12a | `combat/strike/AttackResolver.gd` · `combat/strike/AttackResultApplier.gd` · `combat/flow/CombatStateHandlers.gd` | Strike path PA + L3 guard — [`#wf-tier-44-pa`](LIVE_PATHS.md#wf-tier-44-pa) |
| 12b | `combat/weapon_form/CombatFootwork.gd` | PA owner — [`#wf-tier-44-pa`](LIVE_PATHS.md#wf-tier-44-pa) |
| 12c | `combat/weapon_form/GuardLineUpdater.gd` | Outcome **`guard_line`** drift — [`#wf-guard-writers`](LIVE_PATHS.md#wf-guard-writers) |
| 12d | `combat/weapon_form/CombatGuardLines.gd` | D-006 **`normalize_line`** + octant PA — [`#wf-form-guard-pa-matrix`](LIVE_PATHS.md#wf-form-guard-pa-matrix) |
| 12e | `combat/CombatUiHints.gd` · `ui/battle/BattleUIUpdater.gd` · `ui/battle/FormationDiagramBuilder.gd` · `ui/battle/TurnReadyHandler.gd` · `combat/soak/CombatF5SoakTrace.gd` | UI suffixes + F5 gauge — [`#battle-ui`](LIVE_PATHS.md#battle-ui) |
| 13 | `combat/strike/AttackWindUpStarter.gd` · `combat/strike/AttackResolver.gd` | Wind-up stamp · strike resolve |

**Cognition pipeline (shipped):** `AvailableActionsBuilder.build` → `MentalStackDecider.try_pick` → `CombatAIActionPicker.pick_weighted` → `CombatResolveAction.resolve` → defense via `DefenseChoiceResolver`.

<a id="anti-patterns"></a>

## Anti-patterns

| Do not | Do instead |
|--------|------------|
| `const X := SomeClass.Y` (non-preload class ref) | `const _X := preload("res://path/SomeClass.gd")` then `const X := _X.Y` — or create standalone module with literal consts |
| `manager._get_by_id` / new `CombatManager._*` query wrappers | `CombatantEntityAccess` · specialist modules |
| `move_id in MEDICAL_MOVE_IDS` or raw `"pack_wound"` in production | `CombatConstants.is_*` / `MOVE_ID_*` |
| `manager._is_in_immediate_peril` (removed) | `CombatantEntityAccess.is_in_immediate_peril` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` / `medical_session` / `flow_log` |
| Inline gate literals | `CompanyState.read_stub_*` / `gate_*()` |
| Local `_tile_coords` / tile math | `_CampaignBridge.overworld_tile_*` |
| Duplicate untreated-wound checks on entity | `CombatantEntityAccess.entity_has_untreated_wounds` |
| Duplicate zone geometry pack helpers at call sites | `ZoneOfControl.opponent_formation_for_listing` / `zone_geometry_for_pair` + `zone_geometry_*_from_pair_pack` |
| Conflate **weapon form** (WF) with **`guard_line`**, formation **doctrine**, or formation **`engagement_posture`** (LINE/OPEN/DUEL) | [`LIVE_PATHS#wf-footing-guards-stances`](LIVE_PATHS.md#wf-footing-guards-stances) |
| Conflate **`CombatFootwork`** (Tier 4.4 PA step) with tier-4.2 **`defense_footwork_*`** or formation **`rotate_file`** | [`LIVE_PATHS#wf-footing-guards-stances`](LIVE_PATHS.md#wf-footing-guards-stances) |
| Conflate **`ZoneOfControl.get_footing_duration_multiplier`** with WF / PA / **`guard_line`** | [`#wf-layer-labels`](LIVE_PATHS.md#wf-layer-labels) |
| Treat **`PassiveParryContext.guard_readiness_float`** as L3 **`guard_line`** | Blade posture is **`guard_line`** + PA via **`CombatFootwork.guard_angle_deg`** |
| Use **`CombatConstants.get_guard_angle_deg`** at strike contact when PA flag on | **`CombatFootwork.guard_angle_deg`** — [`#wf-tier-44-pa`](LIVE_PATHS.md#wf-tier-44-pa) |
| Wire PA lookup through **`CombatGuardLines`** octant table without harness octant suite | Octant delegate in **`CombatConstants.position_angle_offset_deg_for_attack_line`** when eight-guard flag on |
| **`get_stance_modifier`** at new production call sites | **`CombatWeaponForm.mod(_EntityAccess.form_str(c), effect)`** — delegate kept for harness only |
| Wire **`weapon_form`** → **`position_angle_offset_deg`** | Steps from **attack_line** / **guard_line** / dodge part only |
| Assume eight-line **`high_right`** etc. get L4 step offset | **`POSITION_ANGLE_OFFSET_DEG_BY_LINE`** is **`high`/`low`/`left`/`right`** only |
| Fold auto-switch into **`evaluate_automatic_doctrine`** or hook WF-3 on **`process_waiting`** **and** **`pick`** | **`evaluate_automatic_form`** in **`CombatAIActionPicker.pick`** only |
| New `FEATURE_*` · bleed retune · closed IV-1,3,5–13 | User must ask; Expand one row per PR per [§9c](SHIP_PLAN.md#combat-expand-registry) |
| Harness literal strings copied into production | Literals OK in harness `*Tail.gd` / fixtures; production uses constants |
| Read `c.stamina` without `c.breath` fallback | Both keys set — `"breath"` canonical in new code |
| New breath-only call sites | `stamina_factor()` / `breath_factor()` alias |

**Layers (do not conflate):** menu/resolver **move IDs** · CoreEntity **method names** (`apply_bandage`) · formation flow **`FORMATION_MOVE_KIND_*`** — see `CombatFormationFlow.gd` header.

Frozen harness/flags policy: [`PLANNING.md#harness-and-flags`](PLANNING.md#harness-and-flags).

Feature preservation checklist: [`FEATURE_PRESERVATION.md`](FEATURE_PRESERVATION.md).
