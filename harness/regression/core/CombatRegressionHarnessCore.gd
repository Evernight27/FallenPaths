class_name CombatRegressionHarnessCore
extends RefCounted
## Manual / editor-invoked checks for Tier 1.5 - 1.9 (morale cohesion, engagement classifier, depth polearm, ZoC).
## CombatWeaponForm harness baseline: **`_harness_reset_combatants_form_balanced`** -> **`assign_form(...,
## harness_baseline)`**  -  home guard + **`form_str`** for parity rows; LIVE_PATHS **`#spawn--reset-path-wf-1a`** .
## **`#wf-soak-audit-status`**.
## Tier 4.2: **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**,
## **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust`**,
## **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**,
## **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust`**,
## **`_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau`**,
## **`_run_feint_windup_duration_mult_extends_state_duration_vs_thrust`**,
## **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**,
## **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust`**,
## **`_run_feint_move_ai_distinct_feint_and_target_parts`**,
## **`_run_feint_move_ai_distinct_feint_and_target_parts_thrust`**,
## **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**,
## **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust`**,
## **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**,
## **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust`**,
## **`_run_feint_move_listing_spacing_long_dampens_vs_mid`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid`**,
## **`_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering`**,
## **`_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering`**,
## **`_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering`**,
## **`_run_feint_move_listing_stamina_low_dampens_feint_weight`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult`**,
## **`_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult`**,
## **`_run_feint_move_listing_doctrine_probing_multiplies_feint_weight`**,
## **`_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight`**,
## **`_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default`**,
## **`_run_feint_move_listing_stance_ai_feint_mult_ordering`**,
## **`_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight`**,
## **`_run_feint_move_listing_defender_off_balance_boosts_feint_weight`**,
## **`_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance`**,
## **`_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting`**,
## **`_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult`,
## **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`****,
## **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`**,
## **`_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part`**,
## **`_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus`**,
## **`_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high`**,
## **`_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid`**,
## **`_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid`**,
## **`_run_feint_target_reveal_progress_scales_readiness_mult`**,
## **`_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough`**,
## **`_feint_guard_zone_sample_global_seed_for_modifier`** (PathResolver RNG seed scan),
## **`_run_feint_second_windup_clears_prior_telegraph_before_restamp`**,
## **`_run_feint_telegraph_scrubbed_on_combat_manager_restart`**; footwork / pair spacing  -
## **`_run_defense_spacing_band_modulates_parry_and_dodge`**,
## **`_run_defense_footwork_recovering_boosts_dodge_vs_waiting`**,
## **`_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult`**,
## **`_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close`**,
## **`_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance`**,
## **`_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close`**,
## **`_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid`**,
## **`_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid`**,
## **`_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid`**,
## **`_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut`**,
## **`_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense`**,
## **`_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint`**,
## **`_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina`**,
## **`_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally`** (**`DefenseChoiceResolver`**,
## **`CombatAIActionPicker`**, **`distance_to`**, **`DEFENSE_SPACING_*`**,
## **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**, **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**,
## **`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**,
## **`CombatConstants.passive_parry_readiness_incoming_contact_mult`**, **`WeaponConstants`** **`thrust_feint`**).
## Tier 3.3: afterblow  -  **`_run_afterblow_deflected_triggers_full_resolve_hit`**,
## **`_run_afterblow_low_hindrance_allow_triggers_resolve_hit`** (fixed **`seed(1)`**, harness meta for mult);
## **`_run_afterblow_mid_hindrance_rand_cancel`** (**`seed(2)`**); **`_run_afterblow_mid_hindrance_rand_executes_hit`**
## (**`seed(0)`**, mult **0.55**); **`_afterblow_harness_seed_pending_cut`**. Hit reaction  -
## **`_run_hit_applier_sets_defender_guard_low_after_hit`** (**`AttackResultApplier`** **`hit`** ->
## **`GuardLineUpdater.set_guard_from_line`** low).
## Does not require a running battle scene. Example:
##   var r := CombatRegressionHarness.run_all()
##   assert(r.ok, str(r.failures))

const MgrScript := preload("res://combat/CombatManager.gd")
const Weapon := preload("res://resources/weapons/Weapon.gd")
const WeaponConstants := preload("res://resources/weapons/WeaponConstants.gd")
const ArmorPiece := preload("res://resources/armor/ArmorPiece.gd")
const ActionsBuilder := preload("res://combat/ai/AvailableActionsBuilder.gd")
const FormationMoves := preload("res://combat/formation/CombatFormationMoveListing.gd")
const ListedActions := preload("res://combat/ai/CombatListedActions.gd")
const MobilityRetreat := preload("res://combat/formation/CombatMobilityRetreat.gd")
const DepthPolearm := preload("res://combat/flow/CombatDepthPolearm.gd")
const EngagementMode := preload("res://combat/engagement/CombatEngagementMode.gd")
const EntityAccess := preload("res://combat/access/CombatantEntityAccess.gd")
const EventScheduler := preload("res://combat/flow/CombatEventScheduler.gd")
const FormationFlow := preload("res://combat/formation/CombatFormationFlow.gd")
const EngagementResolver := preload("res://combat/engagement/CombatEngagementResolver.gd")
const TacticalCombat := preload("res://combat/TacticalCombat.gd")
const FormationEngagement := preload("res://combat/formation/CombatFormationEngagement.gd")
const AIPicker := preload("res://combat/ai/CombatAIActionPicker.gd")
const PassiveParryCtx := preload("res://combat/weapon_form/PassiveParryContext.gd")
const ZoneOfControl := preload("res://combat/formation/ZoneOfControl.gd")
const TargetScoring := preload("res://combat/ai/CombatTargetScoring.gd")
const DefenseChoice := preload("res://combat/strike/DefenseChoiceResolver.gd")
const DefenseResolution := preload("res://combat/strike/DefenseResolutionHandler.gd")
const WindUpStarter := preload("res://combat/strike/AttackWindUpStarter.gd")
const CounterTempo := preload("res://combat/strike/CounterTempo.gd")
const FlurryBind := preload("res://combat/strike/CombatFlurryBind.gd")
const Attention := preload("res://combat/ai/CombatAttention.gd")
const Footwork := preload("res://combat/weapon_form/CombatFootwork.gd")
const BattleUIUpdater := preload("res://ui/battle/BattleUIUpdater.gd")
const MentalStack := preload("res://combat/ai/MentalStackDecider.gd")
const StateHandlers := preload("res://combat/flow/CombatStateHandlers.gd")
const EventDispatch := preload("res://combat/flow/CombatEventDispatch.gd")
const ResolveAction := preload("res://combat/flow/CombatResolveAction.gd")
const StrikePhysics := preload("res://combat/strike/StrikePhysics.gd")
const AttackResultApplier := preload("res://combat/strike/AttackResultApplier.gd")
const CombatDoctrine := preload("res://combat/formation/CombatDoctrine.gd")
const PostStrike := preload("res://combat/strike/CombatPostStrike.gd")
const FormationSlots := preload("res://combat/formation/FormationSlots.gd")
const FormationVacancyPlugs := preload("res://combat/formation/CombatFormationVacancyPlugs.gd")
const CombatTiming := preload("res://combat/flow/CombatTiming.gd")
const CombatLogFormatter := preload("res://ui/battle/CombatLogFormatter.gd")
const AttackResolver := preload("res://combat/strike/AttackResolver.gd")
const ImpactVelocityModel := preload("res://resources/weapons/ImpactVelocityModel.gd")
const StrikeRealism := preload("res://resources/weapons/StrikeRealismProfile.gd")
const DistanceBands := preload("res://combat/formation/CombatDistanceBands.gd")
const GuardLineUpdater := preload("res://combat/weapon_form/GuardLineUpdater.gd")
const GuardLines := preload("res://combat/weapon_form/CombatGuardLines.gd")
const AfterblowHandler := preload("res://combat/strike/AfterblowHandler.gd")
const EntityWounds := preload("res://core/EntityWounds.gd")
const EntityMedical := preload("res://core/EntityMedical.gd")
const Bleeding := preload("res://core/BleedingConstants.gd")
const PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const UiHints := preload("res://combat/CombatUiHints.gd")
const FormationMoveDuration := preload("res://combat/formation/CombatFormationMoveDuration.gd")
const IncomingParryChoice := preload("res://combat/weapon_form/CombatIncomingParryChoice.gd")
const WeaponPosition := preload("res://combat/weapon_form/CombatWeaponPosition.gd")
const FormationFlee := preload("res://combat/formation/CombatFormationFlee.gd")
const StrikeStamping := preload("res://combat/strike/CombatStrikeStamping.gd")
const PairGeometry := preload("res://combat/engagement/CombatPairGeometry.gd")
const MeleeListing := preload("res://combat/ai/CombatMeleeListing.gd")
const MeleeRank := preload("res://combat/ai/CombatMeleeRankTargeting.gd")
const CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const PartyRowFormatter := preload("res://ui/company/PartyRowFormatter.gd")
const Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const F5SoakTrace := preload("res://combat/soak/CombatF5SoakTrace.gd")
const OperationalLog := preload("res://core/OperationalLog.gd")
const ProcessTick := preload("res://combat/flow/CombatProcessTick.gd")
const PartyManagerScript := preload("res://world/PartyManager.gd")
const EncounterNode := preload("res://world/EncounterNode.gd")
const SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const Fixtures := preload("res://harness/HarnessFixtures.gd")
## No preload — `CombatRegressionHarnessKinematicTail` references this class; preloading it here caused a parse cycle.
const HARNESS_META_RECORD_AFTERBLOW_MULT := "_harness_record_afterblow_damage_mult"
const HARNESS_META_LAST_AFTERBLOW_MULT := "_harness_last_afterblow_damage_mult"
const HARNESS_META_EXPOSE_PENETRATION_APPLIED := "_harness_expose_penetration_applied"
const HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"

## Tier 3.2: full-stop **`parry_deflect`**  -  keys on **`parry_clash_context`** (see **`DefenseResolutionHandler`**)
## incl. Tier **3.0** strike kinematics + Tier **3.1** **`strike_measure_ratio`** (from **`pa`** when stamped, else
## **-1**); harness schema lock in **`_run_parry_clash_context_calibration_fields`**. **`parry_partial`** adds the same
## key set plus **`remaining_ratio`** / **`geometric_leak`**
## (**`_run_parry_partial_clash_context_calibration_fields`**); Tier **3.0** KE on partial uses reduced
## **`pa["velocity_m_s"]`**; **`CombatLogFormatter`** + harness
## **`_run_parry_partial_formatter_clash_context_branches`** (**`rem=`** when calibration **on**);
## **`_run_action_resolved_parry_partial_payload_includes_clash_context`** locks first **`action_resolved`** emit;
## **`_run_hit_clears_attacker_parry_calibration_fields`** locks **`hit`** erase of calibration carry;
## **`_run_hit_applier_sets_defender_guard_low_after_hit`** locks defender **`guard_line`** / **`guard_zone`** after
## **`hit`**; **`_run_parry_partial_bind_riposte_flags_when_aligned`** locks defender bind-riposte flags vs alignment +
## **`parry_control`** (misaligned **`erase`** vs aligned explicit **false**, stale-bind seed).
const PARRY_CLASH_CONTEXT_KEYS_FULL_STOP: Array[String] = [
    "archetype_id",
    "parry_control",
    "parry_p_a",
    "parry_c_d",
    "c_d_final",
    "m_a_parry",
    "m_d_parry",
    "m_a_velocity",
    "margin_ratio",
    "alignment",
    "defender_guard_line",
    "guard_angle_deg",
    "parry_time_to_react",
    "parry_readiness",
    "late_parry",
    "parry_off_balance",
    "is_block_parry",
    "attack_type",
    "contact_type",
    "effective_attack_line",
    "severity",
    "attack_angle_deg",
    "kinematic_delivery",
    "strike_velocity_m_s",
    "strike_kinetic_energy_j",
    "strike_measure_ratio",
]

## Tier 4.2: global **`seed`** for **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`** (wind-up rolls);
## refresh if Godot RNG drifts.
const _FEINT_WINDUP_HARNESS_SEED: int = 20260514
## Tier 4.2: global **`seed`** for **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`** (non-feint
## **`oberhau`** + **`target_part`** only).
const _FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED: int = 20260515
## After harnesses that call **`seed(...)`** for local control, restore global RNG so later **`run_all()`** entries stay
## order-stable (matches **`_windup_duration_for_bind_test`** post-**`AttackWindUpStarter.start`** restore).
const _HARNESS_RESTORE_GLOBAL_SEED: int = 90210


## Tier 4.2 harness helper: matches **`CombatAIActionPicker._get_action_weight`** feint-listing **`read_m`**
## (**`pr_def`** chain before stance / low-stamina / doctrine / deflect / off-balance terms).
static func _fail(arr: PackedStringArray, msg: String) -> void:
    arr.append(msg)


## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness
## exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).


static func _track_harness_node(n: Node) -> void:
    HarnessFixtures._track_harness_node(n)


## Final sweep for standalone `_new_entity` rows that omit explicit teardown.


static func flush_harness_live_nodes() -> void:
    HarnessFixtures.flush_harness_live_nodes()


## Expand CombatWeaponForm: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.


static func harness_sync_weapon_form_from_stance(c: Dictionary, stance: String) -> void:
    c["stance"] = stance
    c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = CombatWeaponForm.normalize_form(stance)


## Preferred harness path: **`assign_form`** with home guard + stance alias sync (CombatWeaponForm-M5).


static func harness_assign_form(mgr: Node, c: Dictionary, form: String) -> void:
    CombatWeaponForm.assign_form(mgr, c, form, "harness")


## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).


static func _run_next_action_ready_map_matches_per_id(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var cmap: Dictionary = CombatEventScheduler.build_next_action_ready_times(mgr)
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c, true):
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var per: float = CombatEventScheduler.get_next_action_ready_at(mgr, cid)
        if per < 0.0:
            if cmap.has(cid):
                _fail(failures, "next_ready_map: id=%d no pending event but map has %s" % [cid, str(cmap[cid])])
        else:
            if not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001:
                _fail(failures, "next_ready_map: id=%d per=%.6f map=%s" % [cid, per, str(cmap.get(cid, "missing"))])
    _free_manager(mgr)


## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.


static func _run_vacancy_reconcile_follow_up_regression(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    for _i in 2:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
    var clk0: float = float(mgr.combat_clock)
    var q0: int = mgr.event_queue.size()
    var snap0: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, [], snap0, true)
    if float(mgr.combat_clock) != clk0:
        _fail(failures, "vacancy_follow_up: empty changed_fids mutated combat_clock")
    if mgr.event_queue.size() != q0:
        _fail(failures, "vacancy_follow_up: empty changed_fids mutated event_queue size")
    var snap1: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    var ch1: Array = CombatFormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    if not ch1.is_empty():
        _fail(failures, "vacancy_follow_up: expected stable line after start, changed_fids=%s" % str(ch1))
    var q1: int = mgr.event_queue.size()
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch1, snap1, true)
    if mgr.event_queue.size() != q1:
        _fail(failures, "vacancy_follow_up: no-op reconcile follow-up mutated event_queue")
    var cmap: Dictionary = CombatEventScheduler.build_next_action_ready_times(mgr)
    for c in mgr.combatants:
        if not CombatantEntityAccess.alive_bool(c, true):
            continue
        var cid: int = CombatantEntityAccess.id_int(c)
        var per: float = CombatEventScheduler.get_next_action_ready_at(mgr, cid)
        if per >= 0.0 and (not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001):
            _fail(failures, "vacancy_follow_up: map/per mismatch id=%d" % cid)
    _free_manager(mgr)


## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.


static func _run_vacancy_reconcile_after_front_death(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var front_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
    _soak_kill_combatant(mgr, front_id)
    var snap: Dictionary = CombatEventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = CombatFormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    CombatFormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var living_rank0_player: bool = false
    for c in mgr.combatants:
        if not CombatantEntityAccess.is_alive_on_side(c, "player"):
            continue
        if CombatantEntityAccess.rank_int(c, -9) == 0:
            living_rank0_player = true
            break
    if not living_rank0_player:
        _fail(failures, "vacancy_death: no living player at rank 0 after plug")
    _free_manager(mgr)


## Entity creation  -  forwards to HarnessFixtures.


static func _new_entity(weapon_id: String) -> CoreEntity:
    return HarnessFixtures._new_entity(weapon_id)


static func _new_entity_unarmed() -> CoreEntity:
    return HarnessFixtures._new_entity_unarmed()


## Manager setup  -  forwards to HarnessFixtures.


static func _harness_start_1v1(
    weapon_id: String = "SWORD",
    player_side: Dictionary = {"files": 1, "ranks": 1},
    enemy_side: Dictionary = {"files": 1, "ranks": 1}
) -> Node:
    return HarnessFixtures._harness_start_1v1(weapon_id, player_side, enemy_side)


static func _harness_reset_combatants_form_balanced(mgr: Node) -> void:
    HarnessFixtures._harness_reset_combatants_form_balanced(mgr)


static func _harness_start_player_only(player_side: Dictionary = {"files": 1, "ranks": 1}) -> Node:
    return HarnessFixtures._harness_start_player_only(player_side)


## Equipment  -  forwards to HarnessFixtures.


static func _harness_equip_heavy_plate_kit(e: CoreEntity) -> void:
    HarnessFixtures._harness_equip_heavy_plate_kit(e)


## Roster / formation lookups  -  forwards to HarnessFixtures.


static func _harness_find_living_at_rank_file(mgr: Node, side: String, rank: int, file: int) -> Dictionary:
    return HarnessFixtures._harness_find_living_at_rank_file(mgr, side, rank, file)


## Formation fixtures  -  forwards to HarnessFixtures.


static func _harness_sparse_post_flee_6v3_mgr(survivor_file: int = 4, fled_files: Array = [0, 1, 2, 3]) -> Dictionary:
    return HarnessFixtures._harness_sparse_post_flee_6v3_mgr(survivor_file, fled_files)


static func _harness_7v3_wing_rank0_fixtures() -> Array:
    return HarnessFixtures._harness_7v3_wing_rank0_fixtures()


static func _harness_bind_pair_long_band(p: Dictionary, e: Dictionary) -> void:
    HarnessFixtures._harness_bind_pair_long_band(p, e)


## Guard-line helpers  -  forwards to HarnessFixtures.


static func _harness_cardinal_attack_line(cardinal: String) -> String:
    return HarnessFixtures._harness_cardinal_attack_line(cardinal)


static func _harness_adjacent_lines_for(cardinal_attack: String) -> Array:
    return HarnessFixtures._harness_adjacent_lines_for(cardinal_attack)


static func _harness_opposite_cardinal(cardinal: String) -> String:
    return HarnessFixtures._harness_opposite_cardinal(cardinal)


## IV-9 harness helpers  -  forwards to HarnessFixtures.


static func _harness_iv9_player_rotate_file_listed(mgr: Node) -> bool:
    return HarnessFixtures._harness_iv9_player_rotate_file_listed(mgr)


static func _harness_iv9_center_rank0_can_melee_threaten(mgr: Node) -> bool:
    return HarnessFixtures._harness_iv9_center_rank0_can_melee_threaten(mgr)


static func _harness_iv9_gap_column_cache_matches_occupied(formation: Dictionary) -> bool:
    return HarnessFixtures._harness_iv9_gap_column_cache_matches_occupied(formation)


static func _harness_iv9_resolve_adjacent_rank_pair_move(
    mgr: Node, initiator_id: int, partner_id: int, move_kind: String
) -> void:
    HarnessFixtures._harness_iv9_resolve_adjacent_rank_pair_move(mgr, initiator_id, partner_id, move_kind)


## Cleanup  -  forwards to HarnessFixtures.


static func _free_harness_node(n: Node) -> void:
    HarnessFixtures._free_harness_node(n)


static func _free_manager(mgr: Node) -> void:
    HarnessFixtures._free_manager(mgr)


## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.


static func _free_manager_restore_global_rng(mgr: Node) -> void:
    HarnessFixtures._free_manager_restore_global_rng(mgr)


## Harness utility forwards  -  all forwarded to HarnessFixtures.


static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
    return HarnessFixtures._windup_duration_for_bind_test(weapon_id, move_id, bind)


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
    HarnessFixtures._shuffle_int_array_in_place(ids, rng)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
    HarnessFixtures._soak_kill_combatant(mgr, combatant_id)


static func _harness_counter_tempo_set_incoming_progress(mgr: Node, attacker_id: int, fraction: float) -> void:
    HarnessFixtures._harness_counter_tempo_set_incoming_progress(mgr, attacker_id, fraction)


static func _harness_destroy_limb(entity: CoreEntity, part: String) -> void:
    HarnessFixtures._harness_destroy_limb(entity, part)


static func _harness_restore_limb(entity: CoreEntity, part: String) -> void:
    HarnessFixtures._harness_restore_limb(entity, part)


static func _harness_iv9_enemy_rank0_with_gaps(mgr: Node) -> Array:
    return HarnessFixtures._harness_iv9_enemy_rank0_with_gaps(mgr)


## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot
## stays in sync.


static func _run_cancel_stale_swap_rank_resolve_events(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = CombatantEntityAccess.id_int(p0)
    var id1: int = CombatantEntityAccess.id_int(p1)
    CombatEventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": id0,
            "resolve_at": mgr.combat_clock + 10.0,
            "data": {"partner_id": id1, "move_kind": "swap_rank"}
        }
    )
    CombatEventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": id1,
            "resolve_at": mgr.combat_clock + 11.0,
            "data": {"partner_id": id0, "move_kind": "swap_rank"}
        }
    )
    var swap_queued: int = 0
    for ev in mgr.event_queue:
        if (
            typeof(ev) == TYPE_DICTIONARY
            and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE
        ):
            swap_queued += 1
    if swap_queued != 2:
        _fail(failures, "swap_cancel_setup: expected 2 stale swap_rank_resolve events, got %d" % swap_queued)
        _free_manager(mgr)
        return
    CombatEventScheduler.cancel_pending_swap_rank_pair_events(mgr, id0, id1)
    for ev in mgr.event_queue:
        if (
            typeof(ev) == TYPE_DICTIONARY
            and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE
        ):
            _fail(failures, "swap_cancel: stale swap_rank_resolve should be removed")
            _free_manager(mgr)
            return
    _free_manager(mgr)


## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).


static func _run_parry_preserves_formation_pair_state(failures: PackedStringArray) -> void:
    var mgr: Node = CombatManager.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var en: Dictionary = mgr.combatants[2]
    var id0: int = CombatantEntityAccess.id_int(p0)
    var id1: int = CombatantEntityAccess.id_int(p1)
    var eid: int = CombatantEntityAccess.id_int(en)
    CombatFormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    if CombatantEntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(
            failures,
            (
                "parry_swap: expected rank0 in swap_rank after start_pair_move (got %s)"
                % CombatantEntityAccess.state_str(p0)
            )
        )
        _free_manager(mgr)
        return
    if CombatantEntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "parry_swap: expected rank1 in swap_rank after start_pair_move")
        _free_manager(mgr)
        return
    en["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high"}
    AttackResultApplier.apply_result(
        mgr,
        eid,
        {
            "action": "parry_deflect",
            "target_id": id0,
            "recovery_duration": 0.5,
            "parry_clash_context": {"archetype_id": "", "parry_control": 0.0}
        }
    )
    if CombatantEntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(
            failures,
            (
                "parry_swap: parry_deflect must not set defender to waiting mid pair move (got %s)"
                % CombatantEntityAccess.state_str(p0)
            )
        )
    if CombatantEntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "parry_swap: partner must stay swap_rank (got %s)" % CombatantEntityAccess.state_str(p1))
    _free_manager(mgr)


## Depth-polearm assertion helpers — forwards to HarnessFixtures.


static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
    mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
    HarnessFixtures._assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, ctx)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
    HarnessFixtures._assert_stamp_depth_pa_defaults(pa, failures, ctx)


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
    HarnessFixtures._assert_depth_lane_open_cache_matches_builder(mgr, failures, ctx)

## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.
