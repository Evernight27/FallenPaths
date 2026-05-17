class_name CombatRegressionHarness
extends RefCounted

## Manual / editor-invoked checks for Tier 1.5–1.9 (morale cohesion, engagement classifier, depth polearm, ZoC intruder zones).
## Tier 4.2: **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust`**, **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust`**, **`_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau`**, **`_run_feint_windup_duration_mult_extends_state_duration_vs_thrust`**, **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust`**, **`_run_feint_move_ai_distinct_feint_and_target_parts`**, **`_run_feint_move_ai_distinct_feint_and_target_parts_thrust`**, **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust`**, **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust`**, **`_run_feint_move_listing_spacing_long_dampens_vs_mid`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid`**, **`_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering`**, **`_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering`**, **`_run_feint_move_listing_stamina_low_dampens_feint_weight`**, **`_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp`**, **`_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult`**, **`_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult`**, **`_run_feint_move_listing_doctrine_probing_multiplies_feint_weight`**, **`_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight`**, **`_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default`**, **`_run_feint_move_listing_stance_ai_feint_mult_ordering`**, **`_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight`**, **`_run_feint_move_listing_defender_off_balance_boosts_feint_weight`**, **`_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance`**, **`_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting`**, **`_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult`, **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`****, **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`**, **`_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part`**, **`_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus`**, **`_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high`**, **`_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid`**, **`_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid`**, **`_run_feint_target_reveal_progress_scales_readiness_mult`**, **`_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough`**, **`_feint_guard_zone_sample_global_seed_for_modifier`** (PathResolver RNG seed scan), **`_run_feint_second_windup_clears_prior_telegraph_before_restamp`**, **`_run_feint_telegraph_scrubbed_on_combat_manager_restart`**; footwork / pair spacing — **`_run_defense_spacing_band_modulates_parry_and_dodge`**, **`_run_defense_footwork_recovering_boosts_dodge_vs_waiting`**, **`_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult`**, **`_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close`**, **`_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance`**, **`_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close`**, **`_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid`**, **`_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid`**, **`_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid`**, **`_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut`**, **`_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense`**, **`_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint`**, **`_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina`**, **`_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally`** (**`DefenseChoiceResolver`**, **`CombatAIActionPicker`**, **`distance_to`**, **`DEFENSE_SPACING_*`**, **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**, **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**, **`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**, **`CombatConstants.passive_parry_readiness_incoming_contact_mult`**, **`WeaponConstants`** **`thrust_feint`**).
## Tier 3.3: afterblow — **`_run_afterblow_deflected_triggers_full_resolve_hit`**, **`_run_afterblow_low_hindrance_allow_triggers_resolve_hit`** (fixed **`seed(1)`**, harness meta for mult); **`_run_afterblow_mid_hindrance_rand_cancel`** (**`seed(2)`**); **`_run_afterblow_mid_hindrance_rand_executes_hit`** (**`seed(0)`**, mult **0.55**); **`_afterblow_harness_seed_pending_cut`**. Hit reaction — **`_run_hit_applier_sets_defender_guard_low_after_hit`** (**`AttackResultApplier`** **`hit`** → **`GuardLineUpdater.set_guard_from_line`** low).
## `incursion_allowed` expectations respect `CombatConstants.FEATURE_LINE_CRASH_INTRUSION`.
## Does not require a running battle scene. Example:
##   var r := CombatRegressionHarness.run_all()
##   assert(r.ok, str(r.failures))

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")
const _IntrusionWedge := preload("res://combat/CombatIntrusionWedge.gd")
const _IntrusionGeometry := preload("res://combat/CombatIntrusionGeometry.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _PassiveParryCtx := preload("res://combat/PassiveParryContext.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _DefenseResolution := preload("res://combat/DefenseResolutionHandler.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _CombatSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _AfterblowHandler := preload("res://combat/AfterblowHandler.gd")
const _KinematicTail := preload("res://combat/CombatRegressionHarnessKinematicTail.gd")
## Tier 3.2: full-stop **`parry_deflect`** — keys on **`parry_clash_context`** (see **`DefenseResolutionHandler`**) incl. Tier **3.0** strike kinematics + Tier **3.1** **`strike_measure_ratio`** (from **`pa`** when stamped, else **-1**); harness schema lock in **`_run_parry_clash_context_calibration_fields`**. **`parry_partial`** adds the same key set plus **`remaining_ratio`** / **`geometric_leak`** (**`_run_parry_partial_clash_context_calibration_fields`**); Tier **3.0** KE on partial uses reduced **`pa["velocity_m_s"]`**; **`CombatLogFormatter`** + harness **`_run_parry_partial_formatter_clash_context_branches`** (**`rem=`** when calibration **on**); **`_run_action_resolved_parry_partial_payload_includes_clash_context`** locks first **`action_resolved`** emit; **`_run_hit_clears_attacker_parry_calibration_fields`** locks **`hit`** erase of calibration carry; **`_run_hit_applier_sets_defender_guard_low_after_hit`** locks defender **`guard_line`** / **`guard_zone`** after **`hit`**; **`_run_parry_partial_bind_riposte_flags_when_aligned`** locks defender bind-riposte flags vs alignment + **`parry_control`** (misaligned **`erase`** vs aligned explicit **false**, stale-bind seed).
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

## Tier 4.2: global **`seed`** for **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`** (wind-up rolls); refresh if Godot RNG drifts.
const _FEINT_WINDUP_HARNESS_SEED: int = 20260514
## Tier 4.2: global **`seed`** for **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`** (non-feint **`oberhau`** + **`target_part`** only).
const _FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED: int = 20260515
## After harnesses that call **`seed(...)`** for local control, restore global RNG so later **`run_all()`** entries stay order-stable (matches **`_windup_duration_for_bind_test`** post-**`AttackWindUpStarter.start`** restore).
const _HARNESS_RESTORE_GLOBAL_SEED: int = 90210


## Tier 4.2 harness helper: matches **`CombatAIActionPicker._get_action_weight`** feint-listing **`read_m`** (**`pr_def`** chain before stance / low-stamina / doctrine / deflect / off-balance terms).
static func _feint_listing_read_m_expect_for_move_on_target(
	tgt_enemy: Dictionary,
	combatant_id_for_spacing: int,
	feint_move_id: String
) -> float:
	var pr_def: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(tgt_enemy), 0.0, 1.0)
	var ct: String = str(
		WeaponConstants.get_move(feint_move_id).get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
	)
	pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct), 0.0, 1.0)
	pr_def = clampf(
		pr_def
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(tgt_enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	pr_def = clampf(
		pr_def
		* CombatConstants.ai_feint_listing_defender_readiness_spacing_mult(
			tgt_enemy, combatant_id_for_spacing
		),
		0.0,
		1.0
	)
	return lerpf(1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def)


## Defender footwork on feint listing (off-balance / recovering / settled waiting); **1** otherwise.
static func _feint_listing_defender_footwork_state_mult_for_target(tgt_enemy: Dictionary) -> float:
	if _PassiveParryCtx.is_off_balance(tgt_enemy):
		return 1.0
	var st: String = str(tgt_enemy.get("state", ""))
	if st == CombatConstants.STATE_RECOVERING:
		return CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause(
			str(tgt_enemy.get("recovery_cause", "skip"))
		)
	if st == CombatConstants.STATE_WAITING:
		return CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
	return 1.0


## Defender-side feint-listing mult: readiness lerp × footwork state mult (when applicable).
static func _feint_listing_target_readiness_and_footwork_mult(
	tgt_enemy: Dictionary,
	combatant_id_for_spacing: int,
	feint_move_id: String
) -> float:
	return (
		_feint_listing_read_m_expect_for_move_on_target(tgt_enemy, combatant_id_for_spacing, feint_move_id)
		* _feint_listing_defender_footwork_state_mult_for_target(tgt_enemy)
	)


static func run_all() -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_run_next_action_ready_map_matches_per_id(failures)
	_run_vacancy_reconcile_follow_up_regression(failures)
	_run_vacancy_reconcile_after_front_death(failures)
	_run_depth_polearm(failures)
	_run_depth_polearm_reciprocal_distance_bands(failures)
	_run_depth_polearm_only_file_opposed_line(failures)
	_run_depth_polearm_threatens_line_target_pure_guards(failures)
	_run_depth_polearm_valid_line_threat_false_when_lane_closed(failures)
	_run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(failures)
	_run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures)
	_run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(failures)
	_run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(failures)
	_run_depth_polearm_layout_fuzz(failures)
	_run_front_rank_pair_melee_listed(failures)
	_run_engagement_scenarios(failures)
	_run_posture_mirror_symmetric(failures)
	_run_morale_cohesion_affects_line_cohesion(failures)
	_run_crash_ai_cohesion_weight_monotone(failures)
	_run_crash_ai_posture_mult_with_cached_fd(failures)
	_run_engagement_classifier_multi_seed(failures)
	_run_engagement_active_count_gate_exhaustive(failures)
	_run_engagement_mode_cache_reset_on_second_start(failures)
	_run_engagement_attrition_monotone(failures)
	_run_telemetry_lock_multi_seed(failures)
	_run_depth_polearm_band_vs_actions_fuzz(failures)
	_run_no_crash_actions_when_intrusion_disabled(failures)
	_run_combat_telemetry_crash_blocked(failures)
	_run_telemetry_invalid_melee_resolve_blocked(failures)
	_run_telemetry_invalid_close_resolve_blocked(failures)
	_run_attempt_close_listed_only_at_long(failures)
	_run_attempt_close_ai_weight_zero_when_not_long(failures)
	_run_close_contest_failed_emits_reason(failures)
	_run_resolve_close_no_emit_when_target_incap(failures)
	_run_resolve_crash_no_emit_when_target_incap(failures)
	_run_crash_failed_formatter_reason_branches(failures)
	_run_parry_deflect_formatter_clash_context_branches(failures)
	_run_parry_partial_formatter_clash_context_branches(failures)
	_run_telemetry_automatic_doctrine_pinch_record(failures)
	_run_combatants_snapshot_formation_doctrine_field(failures)
	_run_parry_pack_flank_effective_spacing(failures)
	_run_intruder_zone_id_uses_host_grid(failures)
	_run_zoc_count_alive_includes_intruder_on_host(failures)
	_run_crash_neighbor_hold_uses_host_line_for_intruder(failures)
	_run_reschedule_back_rank_includes_intruder_on_host(failures)
	_run_surround_sector_load_formula(failures)
	_run_surround_threat_weight_sum_three_file_line(failures)
	_run_surround_defense_multiplier_from_pa_both_paths(failures)
	_run_surround_live_weight_sum_matches_from_pa_sector_path(failures)
	_run_surround_single_threat_int_and_sector_neutral(failures)
	_run_sector_surround_feature_flag_respects_runtime_toggle(failures)
	_run_ai_targeting_posture_cohesion_mult(failures)
	_run_hostile_pair_distributed_pressure_ally_commit(failures)
	_run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures)
	_run_targeting_hold_lane_off_file_mult(failures)
	_run_targeting_file_opposed_mult(failures)
	_run_targeting_pinch_center_inward_bonus(failures)
	_run_targeting_commitment_match_mult(failures)
	_run_targeting_soft_geometry_eff_dist_formula(failures)
	_run_targeting_prune_expired_doctrine_commitment(failures)
	_run_targeting_prune_commitment_when_target_dies(failures)
	_run_targeting_clear_all_state_for_dead_defender(failures)
	_run_ai_targeting_opponent_formation_mult(failures)
	_run_ai_targeting_breach_file_mult(failures)
	_run_targeting_formation_dict_cache_matches_live(failures)
	_run_ai_targeting_engagement_mode_mult(failures)
	_run_hostile_pair_cached_engagement_mode_matches_live(failures)
	_run_ai_targeting_stance_mult_ordering(failures)
	_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures)
	_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(failures)
	_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(failures)
	_run_feint_windup_duration_mult_extends_state_duration_vs_thrust(failures)
	_run_feint_windup_target_only_sets_defender_guard_zone_to_target(failures)
	_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(failures)
	_run_feint_move_ai_distinct_feint_and_target_parts(failures)
	_run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures)
	_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(failures)
	_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(failures)
	_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(failures)
	_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(failures)
	_run_feint_move_listing_spacing_long_dampens_vs_mid(failures)
	_run_feint_move_listing_spacing_close_boosts_vs_mid(failures)
	_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(failures)
	_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(failures)
	_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(failures)
	_run_feint_move_listing_stamina_low_dampens_feint_weight(failures)
	_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(failures)
	_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(failures)
	_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(failures)
	_run_feint_move_listing_doctrine_probing_multiplies_feint_weight(failures)
	_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(failures)
	_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(failures)
	_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(failures)
	_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(failures)
	_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(failures)
	_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(failures)
	_run_counter_tempo_window_opens_on_incoming_wind_up(failures)
	_run_counter_tempo_lists_melee_actions_when_window_open(failures)
	_run_counter_tempo_spend_gauge_subtracts_cost(failures)
	_run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(failures)
	_run_counter_tempo_abort_cancels_pending_incoming_melee(failures)
	_run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures)
	_run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(failures)
	_run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(failures)
	_run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(failures)
	_run_counter_tempo_ui_hint_winding_then_ready(failures)
	_run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(failures)
	_run_attention_being_wind_up_targeted_when_telegraph_set(failures)
	_run_attention_counter_tempo_salience_matches_can_act(failures)
	_run_attention_load_stacks_peril_and_incoming(failures)
	_run_focus_intensity_scales_feint_readthrough_and_guard_zone(failures)
	_run_attention_load_dampens_focus_effective_readiness(failures)
	_run_mental_stack_medical_overrides_attack(failures)
	_run_mental_stack_incoming_windup_prefers_defense(failures)
	_run_mental_stack_counter_over_plain_attack_when_window_open(failures)
	_run_mental_stack_attack_layer_matches_legacy_weights(failures)
	_run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures)
	_run_yomi_updates_on_parry_deflect_clears_on_hit(failures)
	_run_attention_ui_hint_formats_when_telegraph_set(failures)
	_run_attention_refresh_waiting_tick_stamps_ui_hint(failures)
	_run_yomi_focus_drift_sets_habitual_part_on_ai(failures)
	_run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(failures)
	_run_guard_from_move_syncs_focus_part_with_guard_line(failures)
	_run_mental_stack_stamps_layer_on_medical_pick(failures)
	_run_focus_line_actions_listed_when_attention_enabled(failures)
	_run_focus_line_resolve_sets_guard_and_focus(failures)
	_run_focus_line_party_leader_prefers_telegraph_match(failures)
	_run_yomi_parry_deflect_boosts_feint_listing_mult(failures)
	_run_yomi_defense_readiness_mult_boosts_after_parry_deflect(failures)
	_run_attention_ui_hint_includes_mental_stack_layer(failures)
	_run_footwork_attack_step_offset_stamped_on_windup(failures)
	_run_footwork_offset_shifts_attack_angle_deg(failures)
	_run_footwork_offset_scrubbed_on_combat_start(failures)
	_run_footwork_defender_parry_step_stamps_offset(failures)
	_run_footwork_defender_offset_shifts_guard_angle_deg(failures)
	_run_footwork_defender_dodge_step_stamps_offset(failures)
	_run_footwork_defender_offset_scrubbed_after_exchange(failures)
	_run_footwork_ui_hint_formats_offset(failures)
	_run_footwork_ui_hint_clears_on_clear_position_offset(failures)
	_run_footwork_ui_hint_clears_on_combat_start(failures)
	_run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures)
	_run_footwork_diagram_label_suffix_compact(failures)
	_run_footwork_snapshot_includes_position_hint_when_enabled(failures)
	_run_footwork_snapshot_ui_hint_from_unstamped_offset(failures)
	_run_footwork_snapshot_omits_position_when_disabled(failures)
	_run_combat_snapshot_exports_attention_ui_hint_when_stamped(failures)
	_run_combat_snapshot_exports_counter_tempo_ui_hint_when_stamped(failures)
	_run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures)
	_run_footwork_choose_defense_dodge_does_not_keep_parry_offset(failures)
	_run_footwork_arc_contact_applies_offset_once(failures)
	_run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(failures)
	_run_footwork_windup_arc_intended_includes_attacker_step(failures)
	_run_footwork_partial_follow_through_freezes_resolve_angles(failures)
	_run_footwork_disabled_skips_windup_stamp(failures)
	_run_feint_move_listing_stance_ai_feint_mult_ordering(failures)
	_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(failures)
	_run_feint_move_listing_defender_off_balance_boosts_feint_weight(failures)
	_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures)
	_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(failures)
	_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures)
	_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures)
	_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures)
	_run_feint_target_reveal_progress_scales_readiness_mult(failures)
	_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(failures)
	_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(failures)
	_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures)
	_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures)
	_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(failures)
	_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(failures)
	_run_defense_spacing_band_modulates_parry_and_dodge(failures)
	_run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures)
	_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures)
	_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(failures)
	_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(failures)
	_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(failures)
	_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures)
	_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(failures)
	_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(failures)
	_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(failures)
	_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(failures)
	_run_feint_telegraph_scrubbed_on_combat_manager_restart(failures)
	_run_ai_targeting_incap_hostile_mult(failures)
	_run_no_hostile_actions_listed_vs_incap_enemy(failures)
	_run_stalemate_melee_rank1_when_rank0_incap(failures)
	_run_ordered_melee_opponents_file_opposed_sort(failures)
	_run_ordered_melee_opponents_commitment_tiebreak(failures)
	_run_depth_spear_tight_lane_parry_mult_invariant(failures)
	_run_windup_pending_attack_pair_geometry(failures)
	_run_strike_measure_constants_sanity(failures)
	_run_attack_result_applier_terminal_clears_pending(failures)
	_run_action_resolved_parry_deflect_payload_includes_clash_context(failures)
	_run_action_resolved_parry_partial_payload_includes_clash_context(failures)
	_run_hit_clears_attacker_parry_calibration_fields(failures)
	_run_hit_applier_sets_defender_guard_low_after_hit(failures)
	_run_parry_partial_bind_riposte_flags_when_aligned(failures)
	_run_depth_spear_thrust_closing_factor_invariant(failures)
	_run_spear_lane_profile_preset_normalized(failures)
	_run_weapon_depth_melee_eligible_fixture(failures)
	_run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures)
	_run_depth_polearm_lane_open_false_when_intruded(failures)
	_run_depth_polearm_lane_open_false_at_rank_zero(failures)
	_run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures)
	_run_depth_polearm_lane_cache_matches_builder(failures)
	_run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures)
	_run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures)
	_run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures)
	_run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures)
	_run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures)
	_run_depth_polearm_parts_filter_tracks_allows_low(failures)
	_run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures)
	_run_depth_polearm_restricted_profile_requires_wedge_for_allows_low(failures)
	_run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures)
	_run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures)
	_run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures)
	_run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures)
	_run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures)
	_run_depth_polearm_auto_lane_discipline_posture(failures)
	_run_wing_lacks_depth_polearm(failures)
	_run_depth_polearm_doctrine_action_weights(failures)
	_run_depth_polearm_ai_doctrine_mults_encounter_preset(failures)
	_run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures)
	_run_doctrine_hollow_center_pinch_heuristic(failures)
	_run_doctrine_hollow_center_intruder_fills_center(failures)
	_run_doctrine_normalize_and_manager_roundtrip(failures)
	_run_encounter_formation_doctrine_on_start(failures)
	_run_encounter_formation_doctrine_string_helper(failures)
	_run_intruder_death_obstacle_on_host_formation(failures)
	_run_intruded_skips_start_pair_move(failures)
	_run_cancel_stale_swap_rank_resolve_events(failures)
	_run_parry_preserves_formation_pair_state(failures)
	_run_swap_rank_resolve_completes_rank_swap(failures)
	_run_negligible_hit_recovery_shorter_than_counted_hit(failures)
	_run_combat_log_formatter_negligible(failures)
	_run_weapon_part_mass_model_normalized(failures)
	_run_weapon_parry_part_selection_fallbacks(failures)
	_run_weapon_striking_part_mass_model(failures)
	_run_kinematic_delivery_override_and_mixed_ke_blend_brackets_thrust_swing(failures)
	_run_kinematic_delivery_velocity_from_intensity_bridges_get_effective_and_monotone(failures)
	_run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(failures)
	_run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(failures)
	_run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(failures)
	_run_kinematic_delivery_strike_momentum_mult_scales_blunt_damage_and_mpa(failures)
	_run_kinematic_delivery_strike_mult_cross_coupling_ke_vs_blunt_isolated(failures)
	_run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver(failures)
	_run_kinematic_delivery_compute_damage_oblique_penetration_integration(failures)
	_run_kinematic_delivery_compute_damage_strike_mods_penetration_integration(failures)
	_run_kinematic_delivery_line_alignment_with_deflect_branches(failures)
	_run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers(failures)
	_run_kinematic_delivery_deflected_line_from_angles_same_line_bind(failures)
	_run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers(failures)
	_run_kinematic_delivery_path_lookup_discrete_from_angles_continuous_alignment(failures)
	_run_kinematic_delivery_guard_deflect_blend_guard_angle_and_attack_only_align(failures)
	_run_kinematic_delivery_compute_penetration_return_keys_and_thrust_blunt_contact(failures)
	_run_kinematic_delivery_attack_angle_deg_no_variance_deterministic(failures)
	_run_kinematic_delivery_compute_damage_velocity_and_entity_split(failures)
	_run_kinematic_delivery_alignment_context_guard_angle_only_uses_combatant_guard(failures)
	_run_kinematic_delivery_parry_v_intent_effective_velocity_base(failures)
	_run_kinematic_delivery_guard_wobble_readiness_shifts_guard_angle(failures)
	_run_kinematic_delivery_compute_damage_strike_ke_and_blunt_contact_exposed(failures)
	_run_kinematic_delivery_alignment_both_angles_ignores_wobble(failures)
	_run_kinematic_delivery_attack_angle_only_wobble_changes_alignment(failures)
	_run_kinematic_delivery_partial_parry_strike_ke_unchanged_pen_scaled(failures)
	_run_kinematic_delivery_compute_damage_pre_armor_matches_helper_at_assembled_v(failures)
	_run_kinematic_delivery_partial_parry_cut_to_blunt_shift(failures)
	_run_kinematic_delivery_derived_velocity_no_cut_to_blunt_shift_on_partial_parry(failures)
	_run_kinematic_delivery_misaligned_guard_scales_pen_not_pre_armor(failures)
	_run_kinematic_delivery_get_attack_path_fallback_to_attack_paths(failures)
	_run_kinematic_delivery_strike_mods_damage_mults_scale_pre_armor_only(failures)
	_run_kinematic_delivery_stab_partial_parry_no_cut_to_blunt_shift(failures)
	_run_kinematic_delivery_partial_parry_misalign_oblique_parry_branch_wins(failures)
	_run_kinematic_delivery_blunt_momentum_mult_scales_pen_not_pre_armor(failures)
	_run_kinematic_delivery_get_attack_path_unknown_attack_line_fallback(failures)
	_run_kinematic_delivery_sharp_penetration_mult_scales_pen_not_pre_cut(failures)
	_run_kinematic_delivery_attack_angle_deg_variance_stamina_spreads(failures)
	_run_kinematic_delivery_partial_parry_align_compose_on_pen_not_pre_armor_mix(failures)
	_run_kinematic_delivery_entity_split_final_fields_on_hit(failures)
	_run_kinematic_delivery_mace_blunt_partial_parry_no_cut_to_blunt_shift(failures)
	_run_kinematic_delivery_misaligned_guard_scales_sharp_and_blunt_pen(failures)
	_run_kinematic_delivery_strike_energy_mult_integration_pre_cut_not_pen(failures)
	_run_kinematic_delivery_afterblow_mult_scales_strike_ke_via_velocity(failures)
	_run_kinematic_delivery_angle_to_nearest_line_boundaries(failures)
	_KinematicTail.run(failures)
	_run_weapon_blade_strong_fraction(failures)
	_run_medical_mobility_can_flee_leg_and_consciousness(failures)
	_run_medical_mobility_cowering_mobile_not_skipped_in_process_incap(failures)
	_run_medical_mobility_cowering_action_ready_fills_gauge_for_mobile(failures)
	_run_medical_mobility_cowering_mobile_solo_fall_back_legal(failures)
	_run_medical_mobility_cowering_lists_fall_back_in_formation_mode(failures)
	_run_medical_mobility_cowering_resolve_solo_fall_back_without_movement_policy(failures)
	_run_medical_mobility_cowering_depth_lists_wait_not_fall_back(failures)
	_run_medical_mobility_cowering_player_retreat_ui_hint(failures)
	_run_medical_mobility_cowering_ai_fall_back_weight_beats_wait(failures)
	_run_medical_mobility_cowering_ai_pick_favors_fall_back(failures)
	_run_medical_mobility_cowering_arm_recovery_clears_state(failures)
	_run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures)
	_run_bind_riposte_contact_types_normalized(failures)
	_run_bind_riposte_contact_multipliers(failures)
	_run_parry_opposite_deflect_thresholds(failures)
	_run_parry_defender_vs_attack_modifiers(failures)
	_run_parry_clash_context_calibration_fields(failures)
	_run_parry_partial_clash_context_calibration_fields(failures)
	_run_parry_control_bind_deflect_formula(failures)
	_run_guard_line_deflected_severity_from_margin_ratio(failures)
	_run_guard_from_move_sets_guard_line_and_zone(failures)
	_run_afterblow_no_pending_returns_false(failures)
	_run_afterblow_wrong_state_returns_false(failures)
	_run_afterblow_hindrance_block_cancels_pending(failures)
	_run_afterblow_deflected_triggers_full_resolve_hit(failures)
	_run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures)
	_run_afterblow_mid_hindrance_rand_cancel(failures)
	_run_afterblow_mid_hindrance_rand_executes_hit(failures)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	return {"ok": failures.is_empty(), "failures": failures}


static func _fail(arr: PackedStringArray, msg: String) -> void:
	arr.append(msg)


## `build_next_action_ready_times` must agree with per-id `get_next_action_ready_at` (UI snapshot correctness).
static func _run_next_action_ready_map_matches_per_id(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var cmap: Dictionary = _EventScheduler.build_next_action_ready_times(mgr)
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c, true):
			continue
		var cid: int = _EntityAccess.id_int(c)
		var per: float = _EventScheduler.get_next_action_ready_at(mgr, cid)
		if per < 0.0:
			if cmap.has(cid):
				_fail(failures, "next_ready_map: id=%d no pending event but map has %s" % [cid, str(cmap[cid])])
		else:
			if not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001:
				_fail(
					failures,
					"next_ready_map: id=%d per=%.6f map=%s" % [cid, per, str(cmap.get(cid, "missing"))]
				)
	_free_manager(mgr)


## Empty follow-up is a no-op; stable line reconcile does not thrash the event queue.
static func _run_vacancy_reconcile_follow_up_regression(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var clk0: float = float(mgr.combat_clock)
	var q0: int = mgr.event_queue.size()
	var snap0: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, [], snap0, true)
	if float(mgr.combat_clock) != clk0:
		_fail(failures, "vacancy_follow_up: empty changed_fids mutated combat_clock")
	if mgr.event_queue.size() != q0:
		_fail(failures, "vacancy_follow_up: empty changed_fids mutated event_queue size")
	var snap1: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	var ch1: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
	if not ch1.is_empty():
		_fail(
			failures,
			"vacancy_follow_up: expected stable line after start, changed_fids=%s" % str(ch1)
		)
	var q1: int = mgr.event_queue.size()
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch1, snap1, true)
	if mgr.event_queue.size() != q1:
		_fail(failures, "vacancy_follow_up: no-op reconcile follow-up mutated event_queue")
	var cmap: Dictionary = _EventScheduler.build_next_action_ready_times(mgr)
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c, true):
			continue
		var cid: int = _EntityAccess.id_int(c)
		var per: float = _EventScheduler.get_next_action_ready_at(mgr, cid)
		if per >= 0.0 and (not cmap.has(cid) or absf(float(cmap[cid]) - per) > 0.0001):
			_fail(failures, "vacancy_follow_up: map/per mismatch id=%d" % cid)
	_free_manager(mgr)


## Front-rank death + reconcile + shared follow-up promotes reserve without breaking invariants.
static func _run_vacancy_reconcile_after_front_death(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var front_id: int = _EntityAccess.id_int(mgr.combatants[0])
	_soak_kill_combatant(mgr, front_id)
	var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
	var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
	_FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
	var living_rank0_player: bool = false
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c) or _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.rank_int(c, -9) == 0:
			living_rank0_player = true
			break
	if not living_rank0_player:
		_fail(failures, "vacancy_death: no living player at rank 0 after plug")
	_free_manager(mgr)


static func _new_entity(weapon_id: String) -> CoreEntity:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	var w: Weapon = _Weapon.create_from_definition(weapon_id)
	if w != null:
		e.equip_weapon(w)
	return e


static func _new_entity_unarmed() -> CoreEntity:
	var e := CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	return e


static func _free_manager(mgr: Node) -> void:
	if mgr == null:
		return
	for c in mgr.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.queue_free()
	mgr.queue_free()


## **`seed(_HARNESS_RESTORE_GLOBAL_SEED)`** then **`_free_manager(mgr)`** — use after harness blocks that set **`seed(3312)`** / **`seed(3313)`** (parry clash calibration), **`seed(1205)`** (parry opposite deflect tail), **`seed(0)`** / **`seed(1)`** / **`seed(2)`** (afterblow fixtures), **`seed(_FEINT_WINDUP_HARNESS_SEED)`** (feint wind-up + duration-mult vs **`oberhau`**) / scan **`seed(0..4095)`**, or **`seed(90210)`** (**`_windup_duration_for_bind_test`**), so **`run_all()`** stays order-stable.
static func _free_manager_restore_global_rng(mgr: Node) -> void:
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	_free_manager(mgr)


static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity(weapon_id), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	if bind:
		p["parry_was_bind"] = true
		p["parry_against_id"] = e_id
	seed(90210)
	_WindUpStarter.start(mgr, p_id, e_id, move_id)
	var dur: float = float(p.get("state_duration", 0.0))
	_free_manager_restore_global_rng(mgr)
	return dur


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
	for i in range(ids.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = ids[i]
		ids[i] = ids[j]
		ids[j] = tmp


## Tier 1.8 (P9): `TacticalCombat.recompute_incursion_pressure` stores `_tactical_mode_snapshot`; keep it aligned with `CombatEngagementMode`.
static func _assert_tactical_snapshot_matches(
	failures: PackedStringArray,
	mgr: Node,
	ctx: String
) -> void:
	if mgr == null:
		return
	if not mgr.has_meta("_tactical_mode_snapshot"):
		_fail(failures, "%s: missing _tactical_mode_snapshot (run _recompute_zoc_and_distance?)" % ctx)
		return
	var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
	var resolved: String = _EngagementMode.engagement_mode(mgr)
	if str(ts.get("mode", "")) != resolved:
		_fail(failures, "%s: tactical mode=%s vs engagement_mode=%s" % [ctx, ts.get("mode"), resolved])
	var inc: bool = _EngagementMode.incursion_allowed(mgr)
	if bool(ts.get("incursion_allowed", false)) != inc:
		_fail(failures, "%s: tactical incursion_allowed vs CombatEngagementMode mismatch" % ctx)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
	if mgr == null or not mgr.has_method("_get_by_id"):
		return
	var c: Variant = mgr._get_by_id(combatant_id)
	if c == null or typeof(c) != TYPE_DICTIONARY:
		return
	if not _EntityAccess.alive_bool(c):
		return
	c["alive"] = false
	mgr._on_combatant_died(c)


## Tier 1.7–1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot stays in sync.
static func _run_engagement_classifier_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 64:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var snap: Dictionary = _EngagementMode.snapshot(mgr)
		var raw: String = str(snap.get("raw_mode", ""))
		if raw == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				_fail(
					failures,
					"classifier_fuzz seed=%d: raw formation but can_enter false snap=%s" % [scenario_seed, str(snap)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "classifier_fuzz seed=%d" % scenario_seed)
		var resolved: String = _EngagementMode.engagement_mode(mgr)
		var resolved_again: String = _EngagementMode.engagement_mode(mgr)
		if resolved_again != resolved:
			_fail(
				failures,
				"classifier_fuzz seed=%d: engagement_mode not idempotent %s vs %s"
				% [scenario_seed, resolved, resolved_again]
			)
		var inc_ok: bool = _EngagementMode.incursion_allowed(mgr)
		var inc_expect: bool = (
			CombatConstants.FEATURE_LINE_CRASH_INTRUSION
			and resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION
		)
		if inc_ok != inc_expect:
			_fail(failures, "classifier_fuzz seed=%d: incursion_allowed vs resolved mismatch" % scenario_seed)
		if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
			if not _EngagementMode.can_enter_formation_from_snapshot(snap):
				_fail(
					failures,
					"classifier_fuzz seed=%d: cold resolved formation but can_enter false snap=%s"
					% [scenario_seed, str(snap)]
				)
		_free_manager(mgr)


## Tier 1.7 (P8): Option 2 active-count floor — if either side has fewer actives than formation minimum, raw mode is never `formation`.
static func _run_engagement_active_count_gate_exhaustive(failures: PackedStringArray) -> void:
	var min_act: int = int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
	for pn in range(1, 8):
		for en in range(1, 8):
			if pn >= min_act and en >= min_act:
				continue
			var mgr: Node = _MgrScript.new()
			for _i in pn:
				mgr.register(_new_entity("SWORD"), "player")
			for _j in en:
				mgr.register(_new_entity("SWORD"), "enemy")
			mgr.start({}, {})
			var snap: Dictionary = _EngagementMode.snapshot(mgr)
			if str(snap.get("raw_mode", "")) == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				_fail(
					failures,
					"active_gate: raw formation with active below min pn=%d en=%d snap=%s" % [pn, en, str(snap)]
				)
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved == CombatConstants.ENGAGEMENT_MODE_FORMATION:
				_fail(
					failures,
					"active_gate: resolved formation with active below min pn=%d en=%d snap=%s"
					% [pn, en, str(snap)]
				)
			_free_manager(mgr)


## Tier 1.7 (P8): second `start()` on same manager must not keep prior `formation` hysteresis (regression guard for `clear_resolved_mode_cache`).
static func _run_engagement_mode_cache_reset_on_second_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var m0: String = _EngagementMode.engagement_mode(mgr)
	if m0 != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(failures, "mode_cache_reset: expected first start formation-line mode got %s" % m0)
	# Rebuild as tiny duel on the **same** manager node.
	for c in mgr.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.queue_free()
	mgr.combatants.clear()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var m1: String = _EngagementMode.engagement_mode(mgr)
	if m1 != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(
			failures,
			"mode_cache_reset: after 1v1 restart expected duel got %s (stale formation cache?)" % m1
		)
	_free_manager(mgr)


## Tier 1.8 soak: deaths-only path must not return to resolved formation after leaving it (hysteresis / classifier stability).
static func _run_engagement_attrition_monotone(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 32:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(4, 8)
		var en: int = rng.randi_range(4, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		var order: Array = []
		for c in mgr.combatants:
			order.append(_EntityAccess.id_int(c))
		_shuffle_int_array_in_place(order, rng)
		var left_formation: bool = false
		for cid in order:
			var cur: Variant = mgr._get_by_id(int(cid))
			if cur == null or not _EntityAccess.alive_bool(cur):
				continue
			_soak_kill_combatant(mgr, int(cid))
			var resolved: String = _EngagementMode.engagement_mode(mgr)
			if resolved != CombatConstants.ENGAGEMENT_MODE_FORMATION:
				left_formation = true
			elif left_formation:
				_fail(
					failures,
					"attrition_monotone seed=%d: re-entered formation after leaving (last_kill_id=%d)" % [scenario_seed, cid]
				)
				break
			_assert_tactical_snapshot_matches(
				failures,
				mgr,
				"attrition_monotone seed=%d after_kill=%d" % [scenario_seed, cid]
			)
			var pa: int = _EngagementMode.count_active_for_side(mgr, "player")
			var ea: int = _EngagementMode.count_active_for_side(mgr, "enemy")
			if pa <= 0 or ea <= 0:
				break
		_free_manager(mgr)


## Tier 1.8 (P9): telemetry meta + embedded snapshot agree with resolved mode; no spurious transitions on cold start.
static func _run_telemetry_lock_multi_seed(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pn: int = rng.randi_range(1, 8)
		var en: int = rng.randi_range(1, 8)
		var mgr: Node = _MgrScript.new()
		for _i in pn:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in en:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({}, {})
		if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
			_fail(failures, "telemetry_lock seed=%d: missing combat telemetry meta" % scenario_seed)
		else:
			var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
			var mode: String = _EngagementMode.engagement_mode(mgr)
			if str(tel.get("last_resolved_mode", "")) != mode:
				_fail(
					failures,
					"telemetry_lock seed=%d: tel.last_resolved_mode=%s vs engagement_mode=%s"
					% [scenario_seed, tel.get("last_resolved_mode"), mode]
				)
			if int(tel.get("engagement_mode_transitions", -1)) != 0:
				_fail(
					failures,
					"telemetry_lock seed=%d: expected 0 mode transitions on cold start got %s"
					% [scenario_seed, str(tel.get("engagement_mode_transitions"))]
				)
			if (
				not tel.has("invalid_melee_resolve_blocked")
				or not tel.has("invalid_crash_resolve_blocked")
				or not tel.has("invalid_close_resolve_blocked")
			):
				_fail(
					failures,
					"telemetry_lock seed=%d: tel missing invalid_* keys (got keys=%s)"
					% [scenario_seed, str(tel.keys())]
				)
			if (
				int(tel.get("invalid_melee_resolve_blocked", -1)) != 0
				or int(tel.get("invalid_crash_resolve_blocked", -1)) != 0
				or int(tel.get("invalid_close_resolve_blocked", -1)) != 0
			):
				_fail(
					failures,
					"telemetry_lock seed=%d: expected 0 invalid melee/crash/close on cold start tel=%s"
					% [scenario_seed, str(tel)]
				)
		_assert_tactical_snapshot_matches(failures, mgr, "telemetry_lock seed=%d" % scenario_seed)
		if mgr.has_meta("_tactical_mode_snapshot"):
			var ts: Dictionary = mgr.get_meta("_tactical_mode_snapshot") as Dictionary
			if not ts.has("telemetry"):
				_fail(failures, "telemetry_lock seed=%d: _tactical_mode_snapshot missing telemetry" % scenario_seed)
			else:
				var emb: Dictionary = ts["telemetry"] as Dictionary
				var mode2: String = _EngagementMode.engagement_mode(mgr)
				if str(emb.get("last_resolved_mode", "")) != mode2:
					_fail(
						failures,
						"telemetry_lock seed=%d: snapshot.telemetry last_resolved_mode mismatch" % scenario_seed
					)
				if (
					not emb.has("invalid_melee_resolve_blocked")
					or not emb.has("invalid_crash_resolve_blocked")
					or not emb.has("invalid_close_resolve_blocked")
				):
					_fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry missing invalid_* keys" % scenario_seed
					)
				if (
					int(emb.get("invalid_melee_resolve_blocked", -1)) != 0
					or int(emb.get("invalid_crash_resolve_blocked", -1)) != 0
					or int(emb.get("invalid_close_resolve_blocked", -1)) != 0
				):
					_fail(
						failures,
						"telemetry_lock seed=%d: embedded telemetry expected 0 invalid counters got %s"
						% [scenario_seed, str(emb)]
					)
		_free_manager(mgr)


## Tier 1.9 (P10) multi-seed: `can_melee_threaten` implies MID/CLOSE band and a listed weapon strike vs that rank-0 enemy.
static func _run_depth_polearm_band_vs_actions_fuzz(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pf: int = rng.randi_range(1, 4)
		var ef: int = rng.randi_range(1, 4)
		var mgr: Node = _MgrScript.new()
		for _i in pf:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in pf:
			mgr.register(_new_entity("SPEAR"), "player")
		for _k in ef:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start(
			{"files": pf, "ranks": 2, "density": "normal"},
			{"files": ef, "ranks": 1, "density": "normal"}
		)
		var fs: int = rng.randi_range(0, pf - 1)
		var depth_idx: int = pf + fs
		if depth_idx >= mgr.combatants.size():
			_fail(failures, "depth_polearm_band_acts seed=%d: bad depth idx" % scenario_seed)
			_free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
			_fail(failures, "depth_polearm_band_acts seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			_free_manager(mgr)
			continue
		depth["gauge"] = 100.0
		var w_depth: Variant = _EntityAccess.get_weapon(depth)
		var atk_ids: Dictionary = {}
		if w_depth != null and w_depth is Weapon:
			atk_ids = (w_depth as Weapon).attack_types
		for c in mgr.combatants:
			if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			if not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c):
				continue
			if not _ActionsBuilder.can_melee_threaten(mgr, depth, c):
				continue
			var dist: String = str(
				_EntityAccess.nested_dictionary_read(depth, "distance_to").get(_EntityAccess.id_int(c, -2), "")
			)
			if dist == CombatConstants.DISTANCE_LONG:
				_fail(
					failures,
					"depth_polearm_band_acts seed=%d: threaten true but distance LONG vs id=%s"
					% [scenario_seed, str(_EntityAccess.id_int(c))]
				)
				continue
			if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
				_fail(
					failures,
					"depth_polearm_band_acts seed=%d: expected CLOSE/MID vs id=%s got %s"
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist]
				)
				continue
			var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
			var has_melee_vs: bool = false
			for a in acts:
				if int(a.get("target_id", -9)) != _EntityAccess.id_int(c):
					continue
				var mid: String = str(a.get("move_id", ""))
				if atk_ids.has(mid):
					has_melee_vs = true
					break
			if not has_melee_vs:
				_fail(
					failures,
					(
						"depth_polearm_band_acts seed=%d: threaten true but no weapon strike vs id=%s dist=%s acts=%s"
					)
					% [scenario_seed, str(_EntityAccess.id_int(c)), dist, str(acts)]
				)
		_free_manager(mgr)


static func _run_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	# Rank-0 sword, rank-1 spear (same file); one enemy front.
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_polearm: expected open lane (rank-1 spear + rank-0 ally)")
	if _ActionsBuilder.can_melee_threaten(mgr, depth, enemy) != true:
		_fail(failures, "depth_polearm: can_melee_threaten should be true vs file-opposed rank-0")
	var dist: String = str(_EntityAccess.nested_dictionary_read(depth, "distance_to").get(_EntityAccess.id_int(enemy, -2), ""))
	if dist == CombatConstants.DISTANCE_LONG:
		_fail(failures, "depth_polearm: distance_to should not be LONG when lane open (got %s)" % dist)
	depth.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(depth))
	var w_depth: Variant = _EntityAccess.get_weapon(depth)
	var atk_ids: Dictionary = {}
	if w_depth != null and w_depth is Weapon:
		atk_ids = (w_depth as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != _EntityAccess.id_int(enemy):
			continue
		var mid: String = str(a.get("move_id", ""))
		if atk_ids.has(mid):
			has_melee_vs_enemy = true
			break
	if not has_melee_vs_enemy:
		_fail(failures, "depth_polearm: expected weapon strike vs enemy in available actions (had %s)" % str(acts))
	# Non-polearm depth: no extra reach to line.
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en2: Dictionary = mgr2.combatants[2]
	if _ActionsBuilder.can_melee_threaten(mgr2, depth_sw, en2):
		_fail(failures, "depth_polearm: rank-1 sword must not melee-threaten file-opposed rank-0")
	_free_manager(mgr2)
	# Tight density: over-shoulder filter drops legs when lane open (pin strict — duel/open posture alone opens lows per Tier 1.9).
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt_tight: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		_fail(failures, "depth_polearm: tight lane should filter leg targets (got %s)" % str(filt_tight))
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	var filt_wedge_gap: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_wedge_gap.has("left_leg") and not filt_wedge_gap.has("right_leg"):
		_fail(
			failures,
			"depth_polearm: intrusion wedge at file should open low targets in tight lane (got %s)" % str(filt_wedge_gap)
		)
	mgr.formations["player"]["density"] = "loose"
	var filt_loose: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_loose.has("left_leg"):
		_fail(failures, "depth_polearm: loose lane should keep leg targets available")
	# Optional `spear_lane_profile` on formation (Tier 1.9): open on tight without wedge; restricted on loose without wedge.
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var filt_prof_open: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_prof_open.has("left_leg"):
		_fail(
			failures,
			"depth_polearm: spear_lane_profile open + tight should allow leg targets (got %s)" % str(filt_prof_open)
		)
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	var filt_prof_rest: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_prof_rest.has("left_leg") or filt_prof_rest.has("right_leg"):
		_fail(
			failures,
			"depth_polearm: spear_lane_profile restricted + loose should filter legs without wedge (got %s)"
			% str(filt_prof_rest)
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	_free_manager(mgr)


## Tier 1.9: reciprocal bands — rank-0 defender is not stuck at LONG vs an enemy depth spear when spear→defender is MID/CLOSE.
static func _run_depth_polearm_reciprocal_distance_bands(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var player: Dictionary = mgr.combatants[0]
	var en_depth: Dictionary = mgr.combatants[2]
	var pid: int = _EntityAccess.id_int(player)
	var did: int = _EntityAccess.id_int(en_depth)
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, en_depth):
		_fail(failures, "depth_polearm_recip: expected enemy depth spear lane open")
	if not _ActionsBuilder.can_melee_threaten(mgr, en_depth, player):
		_fail(failures, "depth_polearm_recip: enemy spear should melee-threaten player rank-0")
	var d_depth_to_p: String = str(_EntityAccess.nested_dictionary_read(en_depth, "distance_to").get(pid, ""))
	var d_p_to_depth: String = str(_EntityAccess.nested_dictionary_read(player, "distance_to").get(did, ""))
	if d_depth_to_p == CombatConstants.DISTANCE_LONG:
		_fail(failures, "depth_polearm_recip: spear→player band unexpected LONG (got %s)" % d_depth_to_p)
	if d_p_to_depth == CombatConstants.DISTANCE_LONG:
		_fail(
			failures,
			"depth_polearm_recip: player→spear should not be LONG when spear threatens (player=%s spear=%s)"
			% [d_p_to_depth, d_depth_to_p]
		)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2, "density": "normal"})
	var pl2: Dictionary = mgr2.combatants[0]
	var en_deep_sword: Dictionary = mgr2.combatants[2]
	var eid2: int = _EntityAccess.id_int(en_deep_sword)
	if _ActionsBuilder.depth_polearm_lane_open(mgr2, en_deep_sword):
		_fail(failures, "depth_polearm_recip: rank-1 sword must not have open polearm lane")
	var band_r0_to_r1: String = str(_EntityAccess.nested_dictionary_read(pl2, "distance_to").get(eid2, ""))
	if band_r0_to_r1 != CombatConstants.DISTANCE_LONG:
		_fail(
			failures,
			"depth_polearm_recip: rank-1 non-polearm should stay LONG from rank-0 (got %s)" % band_r0_to_r1
		)
	_free_manager(mgr2)
	_free_manager(mgr)


## Tier 1.9: depth polearm may threaten opposed file + immediate neighbor files (lateral max); not beyond.
static func _run_depth_polearm_only_file_opposed_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 3, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var en_f0: Dictionary = mgr.combatants[2]
	var en_f1: Dictionary = mgr.combatants[3]
	var en_f2: Dictionary = mgr.combatants[4]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_polearm_file: expected open lane")
	if not _ActionsBuilder.can_melee_threaten(mgr, depth, en_f0):
		_fail(failures, "depth_polearm_file: should threaten file-opposed rank-0")
	if not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en_f1):
		_fail(failures, "depth_polearm_file: neighbor file should be in lateral thrust window")
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en_f2):
		_fail(failures, "depth_polearm_file: file+2 beyond DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES must not count as lane target")
	if _ActionsBuilder.can_melee_threaten(mgr, depth, en_f2):
		_fail(failures, "depth_polearm_file: must not melee-threaten rank-0 two files over")
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_threatens_line_target`** pure guards (no manager): empty ally/opp, rank≠0, same side, dead, **`abs(Δfile)`** vs **`DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES`**.
static func _run_depth_polearm_threatens_line_target_pure_guards(failures: PackedStringArray) -> void:
	var front: Dictionary = {"rank": 0, "file": 1, "side": "player", "alive": true}
	var opp_line: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target({}, opp_line):
		_fail(failures, "threatens_pure: empty front ally → false")
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, {}):
		_fail(failures, "threatens_pure: empty opp → false")
	var ally_same: Dictionary = {"rank": 0, "file": 2, "side": "player", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, ally_same):
		_fail(failures, "threatens_pure: same-side rank-0 → false")
	var opp_deep: Dictionary = {"rank": 1, "file": 1, "side": "enemy", "alive": true}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_deep):
		_fail(failures, "threatens_pure: enemy rank≠0 → false")
	var opp_dead: Dictionary = {"rank": 0, "file": 1, "side": "enemy", "alive": false}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_dead):
		_fail(failures, "threatens_pure: dead enemy → false")
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_line):
		_fail(failures, "threatens_pure: file-opposed same file → true")
	var opp_near: Dictionary = {"rank": 0, "file": 2, "side": "enemy", "alive": true}
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_near):
		_fail(failures, "threatens_pure: neighbor within lateral max → true")
	var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
	var opp_beyond: Dictionary = {
		"rank": 0,
		"file": 1 + max_lat + 1,
		"side": "enemy",
		"alive": true
	}
	if _ActionsBuilder.depth_polearm_threatens_line_target(front, opp_beyond):
		_fail(failures, "threatens_pure: beyond lateral max → false")


## Tier 1.9: **`depth_polearm_valid_line_threat`** is **false** when **`depth_polearm_lane_open`** is **false**, even if **`depth_polearm_threatens_line_target`** (same-file rank-0 vs enemy rank-0) is **true**.
static func _run_depth_polearm_valid_line_threat_false_when_lane_closed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	var en: Dictionary = mgr.combatants[2]
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "valid_lt_lane: rank-1 sword should not open depth polearm lane")
		_free_manager(mgr)
		return
	var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		_fail(failures, "valid_lt_lane: missing same-file rank-0 ally")
		_free_manager(mgr)
		return
	if not _ActionsBuilder.depth_polearm_threatens_line_target(front, en):
		_fail(failures, "valid_lt_lane: expected geometric line threat rank-0 vs rank-0 same column")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, en):
		_fail(failures, "valid_lt_lane: closed lane must force valid_line_threat false")
	_free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_valid_line_threat(manager, depth, opp)`** equals **`depth_polearm_threatens_line_target(same_file_living_rank0_ally, opp)`** ( **`depth_polearm_valid_line_threat`** implementation path).
static func _run_depth_polearm_valid_line_threat_agrees_with_threatens_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "valid_lt_agree: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
	if front.is_empty():
		_fail(failures, "valid_lt_agree: missing same-file rank-0 ally")
		_free_manager(mgr)
		return
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		var thr: bool = _ActionsBuilder.depth_polearm_threatens_line_target(front, c)
		if vlt != thr:
			_fail(
				failures,
				"valid_lt_agree: id=%d rank=%d valid=%s threatens=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(vlt), str(thr)]
			)
	_free_manager(mgr)


## Tier 1.9: **`_opp_matches_melee_rank_target(..., 0)`** (depth polearm branch in **`build`**) matches **`depth_polearm_valid_line_threat`** vs every living enemy on a **3-wide** opposing front (no host intruders — listing gate stays aligned with **`valid_line_threat`**).
static func _run_depth_polearm_opp_matches_rank0_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "opp_match_vlt: expected open depth polearm lane")
		_free_manager(mgr)
		return
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var om: bool = _ActionsBuilder._opp_matches_melee_rank_target(mgr, depth, c, 0)
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		if om != vlt:
			_fail(
				failures,
				"opp_match_vlt: id=%d rank=%d om=%s vlt=%s"
				% [_EntityAccess.id_int(c), _EntityAccess.rank_int(c), str(om), str(vlt)]
			)
	_free_manager(mgr)


## Tier 1.9: **`_melee_pair_rank_allowed`** home-depth vs enemy rank-0 uses **`depth_polearm_valid_line_threat`** — open **3-wide** + closed-lane **SWORD** depth fixtures match **`valid_line_threat`** per living enemy.
static func _run_depth_polearm_melee_pair_rank_allowed_agrees_with_valid_line_threat(failures: PackedStringArray) -> void:
	var mgr_open: Node = _MgrScript.new()
	mgr_open.register(_new_entity("SWORD"), "player")
	mgr_open.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_open.register(_new_entity("SWORD"), "enemy")
	mgr_open.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_open._recompute_zoc_and_distance()
	var depth_open: Dictionary = mgr_open.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_open, depth_open):
		_fail(failures, "mpra_vlt: open fixture expected depth polearm lane")
		_free_manager(mgr_open)
		return
	for c in mgr_open.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var pr: bool = _ActionsBuilder._melee_pair_rank_allowed(mgr_open, depth_open, c)
		var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr_open, depth_open, c)
		if pr != vlt:
			_fail(
				failures,
				"mpra_vlt open: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr), str(vlt)]
			)
	_free_manager(mgr_open)
	var mgr_closed: Node = _MgrScript.new()
	mgr_closed.register(_new_entity("SWORD"), "player")
	mgr_closed.register(_new_entity("SWORD"), "player")
	mgr_closed.register(_new_entity("SWORD"), "enemy")
	mgr_closed.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr_closed._recompute_zoc_and_distance()
	var depth_closed: Dictionary = mgr_closed.combatants[1]
	if _ActionsBuilder.depth_polearm_lane_open(mgr_closed, depth_closed):
		_fail(failures, "mpra_vlt: closed fixture expected lane closed")
		_free_manager(mgr_closed)
		return
	for c in mgr_closed.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		var pr2: bool = _ActionsBuilder._melee_pair_rank_allowed(mgr_closed, depth_closed, c)
		var vlt2: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr_closed, depth_closed, c)
		if pr2 != vlt2:
			_fail(
				failures,
				"mpra_vlt closed: id=%d pr=%s vlt=%s" % [_EntityAccess.id_int(c), str(pr2), str(vlt2)]
			)
	_free_manager(mgr_closed)


## Tier 1.9: **`can_melee_threaten`** never **true** vs a **home-line** enemy rank 0 unless **`depth_polearm_valid_line_threat`** (open **3-wide** + closed-lane control).
static func _run_depth_polearm_can_melee_threaten_respects_valid_line_for_home_depth(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "cm_vlt: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var host_fid: String = _EntityAccess.formation_id_str(depth)
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _ZoneOfControl.intruder_on_host_formation(c, host_fid):
			continue
		if (
			_ActionsBuilder.can_melee_threaten(mgr, depth, c)
			and not _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
		):
			_fail(failures, "cm_vlt: can_melee_threaten without valid_line id=%d" % _EntityAccess.id_int(c))
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr2._recompute_zoc_and_distance()
	var depth_sw: Dictionary = mgr2.combatants[1]
	var en: Dictionary = mgr2.combatants[2]
	if _ActionsBuilder.depth_polearm_valid_line_threat(mgr2, depth_sw, en):
		_fail(failures, "cm_vlt: closed lane expected valid_line false")
		_free_manager(mgr2)
		return
	if _ActionsBuilder.can_melee_threaten(mgr2, depth_sw, en):
		_fail(failures, "cm_vlt: closed lane rank-1 sword must not can_melee_threaten rank-0 enemy")
	_free_manager(mgr2)


## Tier 1.9 (P10) soak: random multi-file lines — `depth_polearm_valid_line_threat` tracks lateral window vs same-file rank-0 partner.
static func _run_depth_polearm_layout_fuzz(failures: PackedStringArray) -> void:
	var rng := RandomNumberGenerator.new()
	var max_lat: int = int(CombatConstants.DEPTH_POLEARM_MAX_THRUST_LATERAL_FILES)
	for scenario_seed in 48:
		rng.seed = scenario_seed
		var pf: int = rng.randi_range(1, 4)
		var ef: int = rng.randi_range(1, 4)
		var mgr: Node = _MgrScript.new()
		for _i in pf:
			mgr.register(_new_entity("SWORD"), "player")
		for _j in pf:
			mgr.register(_new_entity("SPEAR"), "player")
		for _k in ef:
			mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start(
			{"files": pf, "ranks": 2, "density": "normal"},
			{"files": ef, "ranks": 1, "density": "normal"}
		)
		var fs: int = rng.randi_range(0, pf - 1)
		var depth_idx: int = pf + fs
		if depth_idx >= mgr.combatants.size():
			_fail(failures, "depth_polearm_fuzz seed=%d: bad depth idx" % scenario_seed)
			_free_manager(mgr)
			continue
		var depth: Dictionary = mgr.combatants[depth_idx]
		var lane_open: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, depth)
		if not lane_open:
			_fail(failures, "depth_polearm_fuzz seed=%d: expected open lane pf=%d fs=%d" % [scenario_seed, pf, fs])
			_free_manager(mgr)
			continue
		var front: Dictionary = _ActionsBuilder.same_file_living_rank0_ally(mgr, depth)
		if front.is_empty():
			_fail(failures, "depth_polearm_fuzz seed=%d: missing front ally" % scenario_seed)
			_free_manager(mgr)
			continue
		var ff: int = _EntityAccess.file_int(front, -9)
		for c in mgr.combatants:
			if _EntityAccess.side_str(c) != "enemy" or not _EntityAccess.alive_bool(c):
				continue
			if _EntityAccess.rank_int(c, -1) != 0:
				continue
			var lat: int = absi(_EntityAccess.file_int(c) - ff)
			var geo_ok: bool = lat <= max_lat
			var vlt: bool = _ActionsBuilder.depth_polearm_valid_line_threat(mgr, depth, c)
			if vlt != geo_ok:
				_fail(
					failures,
					(
						"depth_polearm_fuzz seed=%d: valid_line_threat=%s vs geo_ok=%s "
						+ "pf=%d ef=%d depth_file=%d opp_file=%d lat=%d"
					)
					% [scenario_seed, vlt, geo_ok, pf, ef, _EntityAccess.file_int(depth, -1), _EntityAccess.file_int(c, -1), lat]
				)
		_free_manager(mgr)


## Front-rank sword vs sword: CLOSE or MID must list real strikes (MID uses geometric reach, not only REACH_MID_MIN).
static func _run_front_rank_pair_melee_listed(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var dist: String = str(_EntityAccess.nested_dictionary_read(p, "distance_to").get(_EntityAccess.id_int(e, -2), ""))
	if dist not in [CombatConstants.DISTANCE_CLOSE, CombatConstants.DISTANCE_MID]:
		_free_manager(mgr)
		return
	p.gauge = 100.0
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(p))
	var w_p: Variant = _EntityAccess.get_weapon(p)
	var atk_ids: Dictionary = {}
	if w_p != null and w_p is Weapon:
		atk_ids = (w_p as Weapon).attack_types
	var has_melee_vs_enemy: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) != _EntityAccess.id_int(e):
			continue
		var mid: String = str(a.get("move_id", ""))
		if atk_ids.has(mid):
			has_melee_vs_enemy = true
			break
	if not has_melee_vs_enemy:
		_fail(
			failures,
			"front_rank_pair: expected weapon strike vs enemy at band %s (acts=%s)" % [dist, str(acts)]
		)
	_free_manager(mgr)


static func _run_engagement_scenarios(failures: PackedStringArray) -> void:
	# Tier 1.8 (P9): small / medium / large representative headcounts — raw classifier + tactical snapshot stay aligned.
	# Small: 1v1 → duel classifier
	var d: Node = _MgrScript.new()
	d.register(_new_entity("SWORD"), "player")
	d.register(_new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var s1: Dictionary = _EngagementMode.snapshot(d)
	if str(s1.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(failures, "engagement: 1v1 expected raw duel, got %s" % str(s1.get("raw_mode", "")))
	if _EngagementMode.incursion_allowed(d):
		_fail(failures, "engagement: incursion must be disallowed in duel")
	if _EngagementMode.can_enter_formation_from_snapshot(s1):
		_fail(failures, "engagement: 1v1 snap must not claim formation-eligible")
	_assert_tactical_snapshot_matches(failures, d, "engagement small 1v1")
	_free_manager(d)
	# Medium: 3v3 wide front (active 3 < formation floor) → skirmish, not duel (multi-file front)
	var m: Node = _MgrScript.new()
	for _i in 3:
		m.register(_new_entity("SWORD"), "player")
	for _j in 3:
		m.register(_new_entity("SWORD"), "enemy")
	m.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var s3: Dictionary = _EngagementMode.snapshot(m)
	if str(s3.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		_fail(
			failures,
			"engagement: 3v3 three-wide expected raw skirmish, got %s snap=%s"
			% [str(s3.get("raw_mode", "")), str(s3)]
		)
	if _EngagementMode.can_enter_formation_from_snapshot(s3):
		_fail(failures, "engagement: 3v3 snap must not claim formation-eligible (below active floor)")
	_assert_tactical_snapshot_matches(failures, m, "engagement medium 3v3")
	_free_manager(m)
	# Large: 4v4 two-wide line → formation-classifier band (Option 2 minimums)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(_new_entity("SWORD"), "player")
	for _j in 4:
		f.register(_new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var s4: Dictionary = _EngagementMode.snapshot(f)
	if str(s4.get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(
			failures,
			"engagement: 4v4 two-file line expected raw formation, got %s snap=%s"
			% [str(s4.get("raw_mode", "")), str(s4)]
		)
	if not _EngagementMode.can_enter_formation_from_snapshot(s4):
		_fail(failures, "engagement: 4v4 formation snap must satisfy can_enter_formation_from_snapshot")
	var mode_f: String = _EngagementMode.engagement_mode(f)
	var inc_expect_f: bool = (
		CombatConstants.FEATURE_LINE_CRASH_INTRUSION
		and mode_f == CombatConstants.ENGAGEMENT_MODE_FORMATION
	)
	if _EngagementMode.incursion_allowed(f) != inc_expect_f:
		_fail(
			failures,
			"engagement: incursion_allowed=%s expected %s (FEATURE_LINE_CRASH_INTRUSION=%s mode=%s)"
			% [
				_EngagementMode.incursion_allowed(f),
				inc_expect_f,
				CombatConstants.FEATURE_LINE_CRASH_INTRUSION,
				mode_f
			]
		)
	_assert_tactical_snapshot_matches(failures, f, "engagement large 4v4")
	_free_manager(f)


## Tier 1.4: mirrored line → same cohesion → same `engagement_posture` (two-pass recompute + coupling neutral when equal).
static func _run_posture_mirror_symmetric(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var fp: String = str(mgr.formations["player"].get("engagement_posture", ""))
	var fe: String = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp.is_empty() or fe.is_empty():
		_fail(failures, "posture_mirror: missing posture player=%s enemy=%s" % [fp, fe])
	elif fp != fe:
		_fail(failures, "posture_mirror: symmetric presets expected same posture got %s vs %s" % [fp, fe])
	_FormationEngagement.recompute_all(mgr)
	fp = str(mgr.formations["player"].get("engagement_posture", ""))
	fe = str(mgr.formations["enemy"].get("engagement_posture", ""))
	if fp != fe:
		_fail(failures, "posture_mirror: after recompute_all expected same posture got %s vs %s" % [fp, fe])
	_free_manager(mgr)


## Tier 1.5: encounter `morale_cohesion_*` lowers `line_cohesion` vs default factor 1.0.
static func _run_morale_cohesion_affects_line_cohesion(failures: PackedStringArray) -> void:
	var m_base: Node = _MgrScript.new()
	m_base.register(_new_entity("SWORD"), "player")
	m_base.register(_new_entity("SWORD"), "enemy")
	m_base.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_base: float = float(m_base.formations["player"].get("line_cohesion", 1.0))
	var m_low: Node = _MgrScript.new()
	m_low.register(_new_entity("SWORD"), "player")
	m_low.register(_new_entity("SWORD"), "enemy")
	m_low.encounter[CombatConstants.ENCOUNTER_KEY_MORALE_COHESION_PLAYER] = 0.35
	m_low.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var coh_low: float = float(m_low.formations["player"].get("line_cohesion", 1.0))
	if coh_low >= coh_base - 0.001:
		_fail(
			failures,
			"morale_cohesion: expected lower player line_cohesion with low morale (base=%.4f low=%.4f)"
			% [coh_base, coh_low]
		)
	var m_agg: Node = _MgrScript.new()
	m_agg.register(_new_entity("SWORD"), "player")
	m_agg.register(_new_entity("SWORD"), "player")
	m_agg.register(_new_entity("SWORD"), "enemy")
	m_agg.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var coh_agg_hi: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	m_agg.combatants[0]["morale_cohesion"] = 0.2
	m_agg.combatants[1]["morale_cohesion"] = 0.2
	_FormationEngagement.recompute_all(m_agg)
	var coh_agg_lo: float = float(m_agg.formations["player"].get("line_cohesion", 1.0))
	if coh_agg_lo >= coh_agg_hi - 0.001:
		_fail(
			failures,
			"morale_cohesion: combatant mean should drop cohesion (hi=%.4f lo=%.4f)" % [coh_agg_hi, coh_agg_lo]
		)
	_free_manager(m_base)
	_free_manager(m_low)
	_free_manager(m_agg)


## Tier 1.6 (P7): crash AI multiplier increases with formation `line_cohesion` (same combatant, synthetic cohesion values).
static func _run_crash_ai_cohesion_weight_monotone(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var c: Dictionary = mgr.combatants[0]
	mgr.formations["player"]["line_cohesion"] = 0.12
	var w_lo: float = _AIPicker.crash_line_cohesion_weight_mult(mgr, c)
	mgr.formations["player"]["line_cohesion"] = 0.96
	var w_hi: float = _AIPicker.crash_line_cohesion_weight_mult(mgr, c)
	if w_lo + 0.0001 >= w_hi:
		_fail(
			failures,
			"crash_ai_cohesion: expected higher mult at high line_cohesion (lo=%.4f hi=%.4f)" % [w_lo, w_hi]
		)
	_free_manager(mgr)


## Tier 1.6 (P7): **`CombatAIActionPicker._crash_weight_posture_mult`** — cached **`formation_dict`** matches null overload; **LINE** / **OPEN** / **DUEL** match **`CRASH_AI_POSTURE_*`**; unknown posture → **1.0**.
static func _run_crash_ai_posture_mult_with_cached_fd(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	var c: Dictionary = mgr.combatants[0]
	var fd_live: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, c)
	var w_null: float = _AIPicker._crash_weight_posture_mult(mgr, c, null)
	var w_live: float = _AIPicker._crash_weight_posture_mult(mgr, c, fd_live)
	if not is_equal_approx(w_null, w_live):
		_fail(
			failures,
			"crash_ai_post: null fd_cache vs live formation_dict mismatch %.6f vs %.6f" % [w_null, w_live]
		)
	var fd_line: Dictionary = fd_live.duplicate(true)
	fd_line["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	var m_line: float = _AIPicker._crash_weight_posture_mult(mgr, c, fd_line)
	if not is_equal_approx(m_line, CombatConstants.CRASH_AI_POSTURE_LINE_EXTRA_MULT):
		_fail(
			failures,
			"crash_ai_post: LINE mult want %.4f got %.4f" % [CombatConstants.CRASH_AI_POSTURE_LINE_EXTRA_MULT, m_line]
		)
	var fd_open: Dictionary = fd_live.duplicate(true)
	fd_open["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var m_open: float = _AIPicker._crash_weight_posture_mult(mgr, c, fd_open)
	if not is_equal_approx(m_open, CombatConstants.CRASH_AI_POSTURE_OPEN_EXTRA_MULT):
		_fail(
			failures,
			"crash_ai_post: OPEN mult want %.4f got %.4f" % [CombatConstants.CRASH_AI_POSTURE_OPEN_EXTRA_MULT, m_open]
		)
	var fd_duel: Dictionary = fd_live.duplicate(true)
	fd_duel["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_DUEL
	var m_duel: float = _AIPicker._crash_weight_posture_mult(mgr, c, fd_duel)
	if not is_equal_approx(m_duel, CombatConstants.CRASH_AI_POSTURE_DUEL_EXTRA_MULT):
		_fail(
			failures,
			"crash_ai_post: DUEL mult want %.4f got %.4f" % [CombatConstants.CRASH_AI_POSTURE_DUEL_EXTRA_MULT, m_duel]
		)
	var fd_unk: Dictionary = fd_live.duplicate(true)
	fd_unk["engagement_posture"] = "unknown_posture_xyz"
	var m_unk: float = _AIPicker._crash_weight_posture_mult(mgr, c, fd_unk)
	if not is_equal_approx(m_unk, 1.0):
		_fail(failures, "crash_ai_post: unknown posture should return 1.0 got %.4f" % m_unk)
	_free_manager(mgr)


## Tier 1.8: no crash breach action in lists while `FEATURE_LINE_CRASH_INTRUSION` is false.
static func _run_no_crash_actions_when_intrusion_disabled(failures: PackedStringArray) -> void:
	if CombatConstants.FEATURE_LINE_CRASH_INTRUSION:
		return
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		c.gauge = 100.0
		var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(c))
		for a in acts:
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_CRASH:
				_fail(
					failures,
					"no_crash_when_disabled: crash listed for id=%d" % _EntityAccess.id_int(c)
				)
				break
	_free_manager(mgr)


## Tier 1.9 auto profile: `line_discipline` / `engagement_posture` steer over-shoulder vs open when `spear_lane_profile` is auto (**OPEN** and **DUEL** open lows under tight when not strict-only).
static func _run_depth_polearm_auto_lane_discipline_posture(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "tight"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_AUTO
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_strict.has("left_leg") or f_strict.has("right_leg"):
		_fail(failures, "depth_auto_lane: strict discipline + tight should filter legs (got %s)" % str(f_strict))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	var f_loose_disc: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_loose_disc.has("left_leg"):
		_fail(failures, "depth_auto_lane: loose discipline + tight should allow legs (got %s)" % str(f_loose_disc))
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	var f_loose_dens_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_loose_dens_strict.has("left_leg") or f_loose_dens_strict.has("right_leg"):
		_fail(
			failures,
			"depth_auto_lane: strict should override loose density for legs (got %s)" % str(f_loose_dens_strict)
		)
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var f_open_post: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_open_post.has("left_leg"):
		_fail(failures, "depth_auto_lane: OPEN posture + tight should allow legs (got %s)" % str(f_open_post))
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_DUEL
	var f_duel_post: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not f_duel_post.has("left_leg"):
		_fail(failures, "depth_auto_lane: DUEL posture + tight should allow legs (got %s)" % str(f_duel_post))
	# LINE posture + normal discipline + tight: auto profile stays over-shoulder (stamped `pa` agrees).
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_NORMAL
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	var f_line_norm: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_line_norm.has("left_leg") or f_line_norm.has("right_leg"):
		_fail(
			failures,
			"depth_auto_lane: LINE posture + normal discipline + tight should filter legs (got %s)"
			% str(f_line_norm)
		)
	var pa_ln: Dictionary = {}
	var en0: Dictionary = mgr.combatants[2]
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, en0, pa_ln)
	if bool(pa_ln.get("depth_polearm_allows_low_targets", true)):
		_fail(failures, "depth_auto_lane: stamped allows_low false for LINE+normal+tight depth attack")
	if str(pa_ln.get("depth_polearm_lane_type", "")) != CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER:
		_fail(
			failures,
			"depth_auto_lane: stamped lane_type over_shoulder got %s"
			% str(pa_ln.get("depth_polearm_lane_type"))
		)
	# Empty formation field falls back to encounter discipline (same as posture / fall-back policy).
	mgr.formations["player"]["line_discipline"] = ""
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"]["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_LINE_DISCIPLINE] = CombatConstants.LINE_DISCIPLINE_STRICT
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	var f_enc_strict: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if f_enc_strict.has("left_leg") or f_enc_strict.has("right_leg"):
		_fail(
			failures,
			"depth_auto_lane: encounter strict with empty formation discipline should filter legs (got %s)" % str(f_enc_strict)
		)
	_free_manager(mgr)


## Tier 1.6: pinch `wing_lacks_file_opposed` uses same-file rank-0 partner when depth spear lane is open.
static func _run_wing_lacks_depth_polearm(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 3:
		mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	var depth_spear: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		var w: Variant = _EntityAccess.get_weapon(c)
		if w != null and w is Weapon and _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 1:
			if (w as Weapon).depth_melee_eligible:
				depth_spear = c
		if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 1:
			front_f1 = c
	var front_f0: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player" and _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
			front_f0 = c
			break
	if depth_spear.is_empty() or front_f1.is_empty() or front_f0.is_empty():
		_fail(failures, "wing_depth: expected 2×2 player grid with spear at rank1 file1")
		return
	if not _TargetScoring.wing_lacks_file_opposed(mgr, front_f1):
		_fail(failures, "wing_depth: rank0 file1 should lack file-opposed enemy (single enemy file0)")
	if _TargetScoring.wing_lacks_file_opposed(mgr, front_f0):
		_fail(failures, "wing_depth: rank0 file0 should have file-opposed enemy")
	if not _TargetScoring.wing_lacks_file_opposed(mgr, depth_spear):
		_fail(failures, "wing_depth: depth spear file1 should match front wing (lack opposed)")
	_free_manager(mgr)


## Tier 1.9: depth rank spear listing weights vs formation doctrine (`CombatAIActionPicker._depth_polearm_action_weight_mult`).
static func _run_depth_polearm_doctrine_action_weights(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_doc_weights: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var w_base_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_base_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w_pinch_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_pinch_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var w_hold_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_hold_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	var w_probe_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_thrust")
	var w_probe_slash: float = _AIPicker._depth_polearm_action_weight_mult(mgr, depth, "spear_slash")
	if w_pinch_stab <= w_base_stab + 0.001:
		_fail(failures, "depth_doc_weights: pinch should raise stab vs default")
	if w_hold_stab >= w_base_stab - 0.001:
		_fail(failures, "depth_doc_weights: hold should lower stab vs default")
	if w_pinch_slash >= w_base_slash - 0.001:
		_fail(failures, "depth_doc_weights: pinch should lower non-stab vs default")
	if w_hold_slash <= w_base_slash + 0.001:
		_fail(failures, "depth_doc_weights: hold should raise non-stab vs default")
	if w_probe_stab <= w_hold_stab + 1e-5 or w_probe_stab >= w_pinch_stab - 1e-5:
		_fail(
			failures,
			"depth_doc_weights: probing stab should sit strictly between hold and pinch hold=%.6f probe=%.6f pinch=%.6f"
			% [w_hold_stab, w_probe_stab, w_pinch_stab]
		)
	if w_probe_slash <= w_pinch_slash + 1e-5 or w_probe_slash >= w_hold_slash - 1e-5:
		_fail(
			failures,
			"depth_doc_weights: probing non-stab should sit strictly between pinch and hold pinch=%.6f probe=%.6f hold=%.6f"
			% [w_pinch_slash, w_probe_slash, w_hold_slash]
		)
	_free_manager(mgr)


## Tier 1.9: optional encounter + preset **`depth_polearm_ai_doctrine_mults`** merged at **`CombatManager.start`** (preset wins; clamp **`DEPTH_POLEARM_AI_MULT_OVERRIDE_*`**).
static func _run_depth_polearm_ai_doctrine_mults_encounter_preset(failures: PackedStringArray) -> void:
	var pinch_k: String = CombatConstants.DEPTH_POLEARM_AI_MULT_KEY_PINCH_STAB
	var pinch_def: float = CombatConstants.DEPTH_POLEARM_AI_DOCTRINE_PINCH_STAB_MULT
	var merged_clamp: Dictionary = CombatConstants.merge_depth_polearm_ai_doctrine_mults(
		CombatConstants.default_depth_polearm_ai_doctrine_mults_dict(),
		{pinch_k: 9.0}
	)
	if not is_equal_approx(float(merged_clamp[pinch_k]), CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX):
		_fail(
			failures,
			"depth_ai_mults: clamp max want %.4f got %.4f"
			% [CombatConstants.DEPTH_POLEARM_AI_MULT_OVERRIDE_MAX, float(merged_clamp[pinch_k])]
		)
	var mgr0: Node = _MgrScript.new()
	mgr0.register(_new_entity("SWORD"), "player")
	mgr0.register(_new_entity("SPEAR"), "player")
	mgr0.register(_new_entity("SWORD"), "enemy")
	mgr0.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth0: Dictionary = mgr0.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr0, depth0):
		_fail(failures, "depth_ai_mults: expected open depth polearm lane (baseline)")
		_free_manager(mgr0)
		return
	mgr0.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w0: float = _AIPicker._depth_polearm_action_weight_mult(mgr0, depth0, "spear_thrust")
	if not is_equal_approx(w0, CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * pinch_def):
		_fail(failures, "depth_ai_mults: baseline pinch stab mult mismatch got %.6f" % w0)
	var mgr1: Node = _MgrScript.new()
	mgr1.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.26}
	mgr1.register(_new_entity("SWORD"), "player")
	mgr1.register(_new_entity("SPEAR"), "player")
	mgr1.register(_new_entity("SWORD"), "enemy")
	mgr1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth1: Dictionary = mgr1.combatants[1]
	mgr1.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w1: float = _AIPicker._depth_polearm_action_weight_mult(mgr1, depth1, "spear_thrust")
	var expect_enc: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.26
	if not is_equal_approx(w1, expect_enc):
		_fail(failures, "depth_ai_mults: encounter pinch override want %.6f got %.6f" % [expect_enc, w1])
	if not is_equal_approx(w1 / w0, 1.26 / pinch_def):
		_fail(failures, "depth_ai_mults: encounter ratio vs default pinch")
	var p_preset: Dictionary = {
		"files": 1,
		"ranks": 2,
		"density": "normal",
		CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS: {pinch_k: 1.44},
	}
	var mgr2: Node = _MgrScript.new()
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_PLAYER] = {pinch_k: 1.2}
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start(p_preset, {"files": 1, "ranks": 1, "density": "normal"})
	var depth2: Dictionary = mgr2.combatants[1]
	mgr2.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var w2: float = _AIPicker._depth_polearm_action_weight_mult(mgr2, depth2, "spear_thrust")
	var expect_preset: float = CombatConstants.DEPTH_POLEARM_AI_STAB_WEIGHT_MULT * 1.44
	if not is_equal_approx(w2, expect_preset):
		_fail(
			failures,
			"depth_ai_mults: preset should win over encounter want %.6f got %.6f" % [expect_preset, w2]
		)
	var mgr3: Node = _MgrScript.new()
	mgr3.encounter[CombatConstants.ENCOUNTER_KEY_DEPTH_POLEARM_AI_MULTS_ENEMY] = {pinch_k: 1.11}
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SPEAR"), "player")
	mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k), 1.11):
		_fail(
			failures,
			"depth_ai_mults: enemy encounter mult got %s"
			% str(mgr3.get_depth_polearm_ai_doctrine_mult("enemy", pinch_k))
		)
	if not is_equal_approx(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k), pinch_def):
		_fail(
			failures,
			"depth_ai_mults: player pinch should stay default got %s"
			% str(mgr3.get_depth_polearm_ai_doctrine_mult("player", pinch_k))
		)
	_free_manager(mgr0)
	_free_manager(mgr1)
	_free_manager(mgr2)
	_free_manager(mgr3)


## Tier 1.9: **`CombatAIActionPicker._depth_polearm_action_weight_mult`** stays neutral (**1.0**) when no **`depth_polearm_valid_line_threat`** to any hostile rank 0 (lane may still be open); boosts stab when **3-wide** yields ≥1 valid line.
static func _run_depth_polearm_ai_weight_mult_requires_valid_line_to_any_rank0(failures: PackedStringArray) -> void:
	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(_new_entity("SWORD"), "player")
	mgr_far.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(_new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_far, depth_far):
		_fail(failures, "ai_vlt_any: expected open lane")
		_free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	if _ActionsBuilder.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr_far, depth_far, mgr_far.combatants):
		_fail(failures, "ai_vlt_any: expected no valid-line rank-0 hostile after pushing files")
		_free_manager(mgr_far)
		return
	var w_neutral_stab: float = _AIPicker._depth_polearm_action_weight_mult(mgr_far, depth_far, "spear_thrust")
	var w_neutral_close: float = _AIPicker._depth_polearm_action_weight_mult(
		mgr_far, depth_far, CombatConstants.MOVE_ID_ATTEMPT_CLOSE
	)
	if absf(w_neutral_stab - 1.0) > 0.001 or absf(w_neutral_close - 1.0) > 0.001:
		_fail(
			failures,
			"ai_vlt_any: far-line AI mult should be 1.0 stab=%s close=%s" % [str(w_neutral_stab), str(w_neutral_close)]
		)
	_free_manager(mgr_far)
	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SPEAR"), "player")
	for _j in 3:
		mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr3._recompute_zoc_and_distance()
	var depth3: Dictionary = mgr3.combatants[1]
	if not _ActionsBuilder.depth_polearm_has_valid_line_threat_to_any_rank0_hostile(mgr3, depth3, mgr3.combatants):
		_fail(failures, "ai_vlt_any: standard 3-wide should have ≥1 valid-line rank-0 target")
		_free_manager(mgr3)
		return
	var w_boost: float = _AIPicker._depth_polearm_action_weight_mult(mgr3, depth3, "spear_thrust")
	if w_boost <= 1.001:
		_fail(failures, "ai_vlt_any: standard layout should boost stab mult got %s" % str(w_boost))
	_free_manager(mgr3)


## Option 4: `CombatDoctrine.enemy_line_hollow_center_for_pinch` (automatic pinch trigger when `FEATURE_AUTOMATIC_DOCTRINE` is enabled).
static func _run_doctrine_hollow_center_pinch_heuristic(failures: PackedStringArray) -> void:
	_CombatDoctrine.evaluate_automatic_doctrine(null)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var en_by_file: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		en_by_file[_EntityAccess.file_int(c)] = c
	if en_by_file.size() < 3:
		_fail(failures, "doctrine_hollow: expected 3 enemies")
		_free_manager(mgr)
		return
	(en_by_file[1] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: 3-file line with dead center should read as hollow for pinch")
	(en_by_file[1] as Dictionary)["alive"] = true
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: full enemy front should not be hollow")
	(en_by_file[1] as Dictionary)["alive"] = false
	(en_by_file[2] as Dictionary)["alive"] = false
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow: single-wing line should not qualify as hollow center")
	_free_manager(mgr)

	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	for _k in 4:
		mgr4.register(_new_entity("SWORD"), "enemy")
	mgr4.start({"files": 1, "ranks": 1}, {"files": 4, "ranks": 1})
	var en4: Dictionary = {}
	for c in mgr4.combatants:
		if _EntityAccess.side_str(c) == "enemy":
			en4[_EntityAccess.file_int(c)] = c
	for kill_i in [1, 2]:
		(en4[kill_i] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr4, "player"):
		_fail(failures, "doctrine_hollow: 4-file empty middle pair + living wings should be hollow")
	_free_manager(mgr4)


## `enemy_line_hollow_center_for_pinch`: rank-0 intruder on host center counts as **filled** (not hollow).
static func _run_doctrine_hollow_center_intruder_fills_center(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var en_by_file: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		en_by_file[_EntityAccess.file_int(c)] = c
	if not en_by_file.has(1):
		_fail(failures, "doctrine_hollow_intr: expected enemy at file 1")
		_free_manager(mgr)
		return
	(en_by_file[1] as Dictionary)["alive"] = false
	if not _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow_intr: expected hollow with dead native center")
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 1
	if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
		_fail(failures, "doctrine_hollow_intr: intruder rank0 at center should not read as hollow")
	_free_manager(mgr)


## Tier 1.9 / doctrine: **`CombatDoctrine.normalize`** aliases + **`CombatManager.set_formation_doctrine`** → **`get_formation_doctrine`** round-trip.
static func _run_doctrine_normalize_and_manager_roundtrip(failures: PackedStringArray) -> void:
	if _CombatDoctrine.normalize("") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: empty string should be default")
	if _CombatDoctrine.normalize("  \t ") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: whitespace-only should be default")
	if _CombatDoctrine.normalize("pinch") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: pinch alias")
	if _CombatDoctrine.normalize("PINCH_CENTER") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: canonical pinch_center")
	if _CombatDoctrine.normalize("pincer") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(failures, "doctrine_norm: pincer alias")
	if _CombatDoctrine.normalize("hold") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(failures, "doctrine_norm: hold alias")
	if _CombatDoctrine.normalize("probing") != CombatConstants.DOCTRINE_PROBING:
		_fail(failures, "doctrine_norm: probing alias")
	if _CombatDoctrine.normalize(CombatConstants.DOCTRINE_PROBING) != CombatConstants.DOCTRINE_PROBING:
		_fail(failures, "doctrine_norm: probing canonical")
	if _CombatDoctrine.normalize("not_a_real_doctrine_string") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_norm: unknown → default")
	if _CombatDoctrine.doctrine_for_fid(null, "player") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(failures, "doctrine_for_fid: null manager → default")
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.set_formation_doctrine("player", "  pincer  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(
			failures,
			"doctrine_roundtrip: player got %s want pinch_center"
			% mgr.get_formation_doctrine("player")
		)
	mgr.set_formation_doctrine("player", "  probing  ")
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"doctrine_rt: set probing expected %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	mgr.set_formation_doctrine("enemy", "bogus_doctrine_value")
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(
			failures,
			"doctrine_roundtrip: enemy unknown should store default got %s"
			% mgr.get_formation_doctrine("enemy")
		)
	_free_manager(mgr)


## Tier 1.9: **`encounter`** + optional **`start()`** preset dicts seed **`formation_doctrine`** (`ENCOUNTER_KEY_FORMATION_DOCTRINE_*`, else encounter alt keys, then preset **`FORMATION_PRESET_KEY_DOCTRINE`** or **`FORMATION_PRESET_KEY_DOCTRINE_ALT`**, via **`CombatConstants.formation_doctrine_string_from_dict`** for presets).
static func _run_encounter_formation_doctrine_on_start(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  probing  "
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = "hold"
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_start: player want %s got %s"
			% [CombatConstants.DOCTRINE_PROBING, mgr.get_formation_doctrine("player")]
		)
	if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"encounter_doctrine_start: enemy want %s got %s"
			% [CombatConstants.DOCTRINE_HOLD_LANE, mgr.get_formation_doctrine("enemy")]
		)
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "  \t  "
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr2.get_formation_doctrine("player") != CombatConstants.DOCTRINE_DEFAULT:
		_fail(
			failures,
			"encounter_doctrine_start: whitespace-only encounter value should keep default got %s"
			% mgr2.get_formation_doctrine("player")
		)
	_free_manager(mgr2)
	var mgr3: Node = _MgrScript.new()
	mgr3.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	var pdoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "hold_lane"
	}
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start(pdoc, {"files": 1, "ranks": 1})
	if mgr3.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"preset_doctrine_start: player preset should override encounter probing got %s"
			% mgr3.get_formation_doctrine("player")
		)
	_free_manager(mgr3)
	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	mgr4.register(_new_entity("SWORD"), "enemy")
	var edoc: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "pinch"
	}
	mgr4.start({"files": 1, "ranks": 1}, edoc)
	if mgr4.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_PINCH_CENTER:
		_fail(
			failures,
			"preset_doctrine_start: enemy preset pinch alias want pinch_center got %s"
			% mgr4.get_formation_doctrine("enemy")
		)
	_free_manager(mgr4)
	var mgr5: Node = _MgrScript.new()
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "probing"
	mgr5.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT] = "hold"
	mgr5.register(_new_entity("SWORD"), "player")
	mgr5.register(_new_entity("SWORD"), "enemy")
	mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr5.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_alt: player doctrine_player want probing got %s"
			% mgr5.get_formation_doctrine("player")
		)
	if mgr5.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"encounter_doctrine_alt: enemy doctrine_enemy want hold_lane got %s"
			% mgr5.get_formation_doctrine("enemy")
		)
	_free_manager(mgr5)
	var mgr6: Node = _MgrScript.new()
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = "probing"
	mgr6.encounter[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT] = "hold_lane"
	mgr6.register(_new_entity("SWORD"), "player")
	mgr6.register(_new_entity("SWORD"), "enemy")
	mgr6.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if mgr6.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"encounter_doctrine_alt: canonical formation_doctrine_player should win over doctrine_player got %s"
			% mgr6.get_formation_doctrine("player")
		)
	_free_manager(mgr6)
	var mgr7: Node = _MgrScript.new()
	mgr7.register(_new_entity("SWORD"), "player")
	mgr7.register(_new_entity("SWORD"), "enemy")
	var p7: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold",
	}
	mgr7.start(p7, {"files": 1, "ranks": 1})
	if mgr7.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
		_fail(
			failures,
			"preset_doctrine_alt: player preset `doctrine` only want hold_lane got %s"
			% mgr7.get_formation_doctrine("player")
		)
	_free_manager(mgr7)
	var mgr8: Node = _MgrScript.new()
	mgr8.register(_new_entity("SWORD"), "player")
	mgr8.register(_new_entity("SWORD"), "enemy")
	var p8: Dictionary = {
		"files": 1,
		"ranks": 1,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
	}
	mgr8.start(p8, {"files": 1, "ranks": 1})
	if mgr8.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
		_fail(
			failures,
			"preset_doctrine_alt: canonical formation_doctrine on preset should win over doctrine got %s"
			% mgr8.get_formation_doctrine("player")
		)
	_free_manager(mgr8)


## Tier 1.9: **`CombatConstants.encounter_formation_doctrine_string`** / **`formation_doctrine_string_from_dict`** match **`CombatManager.start()`** read order.
static func _run_encounter_formation_doctrine_string_helper(failures: PackedStringArray) -> void:
	var enc_alt: Dictionary = {
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "  hold  ",
	}
	var got_alt: String = CombatConstants.encounter_formation_doctrine_string(
		enc_alt,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if got_alt != "hold":
		_fail(failures, "encounter_doctrine_string: empty canonical should use alt got %s" % got_alt)
	var enc_canon: Dictionary = {
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "probing",
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT: "hold_lane",
	}
	var got_canon: String = CombatConstants.encounter_formation_doctrine_string(
		enc_canon,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if got_canon != "probing":
		_fail(failures, "encounter_doctrine_string: canonical should win over alt got %s" % got_canon)
	var enc_ws: Dictionary = {CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER: "  \t  "}
	var got_ws: String = CombatConstants.encounter_formation_doctrine_string(
		enc_ws,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
		CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT
	)
	if not got_ws.is_empty():
		_fail(failures, "encounter_doctrine_string: whitespace-only canonical should fall through to empty got %s" % got_ws)
	var preset_alt_only: Dictionary = {
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "  hold  ",
	}
	var got_preset_alt: String = CombatConstants.formation_doctrine_string_from_dict(
		preset_alt_only,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if got_preset_alt != "hold":
		_fail(failures, "formation_doctrine_string_from_dict: preset alt-only want hold got %s" % got_preset_alt)
	var preset_both: Dictionary = {
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE: "probing",
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT: "hold_lane",
	}
	var got_preset_canon: String = CombatConstants.formation_doctrine_string_from_dict(
		preset_both,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT
	)
	if got_preset_canon != "probing":
		_fail(
			failures,
			"formation_doctrine_string_from_dict: preset canonical should win got %s" % got_preset_canon
		)


## `on_combatant_died`: intruder corpse **`slot_obstacles`** on **host** formation at death `(rank,file)`.
static func _run_intruder_death_obstacle_on_host_formation(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 2
	var pid: int = _EntityAccess.id_int(p)
	p["alive"] = false
	_FormationFlow.on_combatant_died(mgr, p)
	var form_enemy: Dictionary = _FormationSlots.formation_record_read(mgr.formations, "enemy")
	var obst: Dictionary = _FormationSlots.formation_nested_dictionary_read(form_enemy, "slot_obstacles")
	var key := Vector2i(0, 2)
	if not obst.has(key):
		_fail(failures, "death_obst_intr: missing slot_obstacles on enemy formation at host cell")
	var arr: Variant = obst[key]
	if typeof(arr) != TYPE_ARRAY or not (arr as Array).has(pid):
		_fail(failures, "death_obst_intr: obstacle list missing dead intruder id %d (got %s)" % [pid, str(arr)])
	_free_manager(mgr)


## `start_pair_move` / `start_rotate_file` bail on intruders; slot mutations stay home-keyed and must not run for intruded initiators.
static func _run_intruded_skips_start_pair_move(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1 or _EntityAccess.file_int(p0) != _EntityAccess.file_int(p1):
		_fail(failures, "intr_pair_setup: expected same-file rank0/rank1 player column")
		_free_manager(mgr)
		return
	p0["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p0["intrusion_host_fid"] = "enemy"
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	for ev in mgr.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		if str(ev.get("type", "")) != CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			continue
		var cid: int = int(ev.get("combatant_id", -1))
		var evd: Variant = ev.get("data", null)
		var pid: int = int((evd as Dictionary).get("partner_id", -1)) if typeof(evd) == TYPE_DICTIONARY else -1
		if (cid == id0 and pid == id1) or (cid == id1 and pid == id0):
			_fail(failures, "intr_pair: swap_rank_resolve must not enqueue when initiator is intruded")
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var q0: Dictionary = mgr2.combatants[0]
	var q1: Dictionary = mgr2.combatants[1]
	var qid0: int = _EntityAccess.id_int(q0)
	var qid1: int = _EntityAccess.id_int(q1)
	if _EntityAccess.rank_int(q0) != 0 or _EntityAccess.rank_int(q1) != 0 or abs(_EntityAccess.file_int(q0) - _EntityAccess.file_int(q1)) != 1:
		_fail(failures, "intr_pair_setup2: expected adjacent-file rank-0 pair")
		_free_manager(mgr2)
		return
	q1["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	q1["intrusion_host_fid"] = "enemy"
	_FormationFlow.start_rotate_file(mgr2, qid0, qid1)
	for ev in mgr2.event_queue:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		if str(ev.get("type", "")) != CombatConstants.EVENT_ROTATE_FILE_RESOLVE:
			continue
		var cid2: int = int(ev.get("combatant_id", -1))
		var evd2: Variant = ev.get("data", null)
		var pid2: int = int((evd2 as Dictionary).get("partner_id", -1)) if typeof(evd2) == TYPE_DICTIONARY else -1
		if (cid2 == qid0 and pid2 == qid1) or (cid2 == qid1 and pid2 == qid0):
			_fail(failures, "intr_pair: rotate_file_resolve must not enqueue when partner is intruded")
	_free_manager(mgr2)


## Pair moves cancel any queued `swap_rank_resolve` touching either combatant before scheduling a fresh resolve.
static func _run_cancel_stale_swap_rank_resolve_events(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": id0,
		"resolve_at": mgr.combat_clock + 10.0,
		"data": {"partner_id": id1, "move_kind": "swap_rank"}
	})
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
		"combatant_id": id1,
		"resolve_at": mgr.combat_clock + 11.0,
		"data": {"partner_id": id0, "move_kind": "swap_rank"}
	})
	var swap_queued: int = 0
	for ev in mgr.event_queue:
		if typeof(ev) == TYPE_DICTIONARY and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			swap_queued += 1
	if swap_queued != 2:
		_fail(failures, "swap_cancel_setup: expected 2 stale swap_rank_resolve events, got %d" % swap_queued)
		_free_manager(mgr)
		return
	_EventScheduler.cancel_pending_swap_rank_pair_events(mgr, id0, id1)
	for ev in mgr.event_queue:
		if typeof(ev) == TYPE_DICTIONARY and (ev as Dictionary).get("type", "") == CombatConstants.EVENT_SWAP_RANK_RESOLVE:
			_fail(failures, "swap_cancel: stale swap_rank_resolve should be removed")
			_free_manager(mgr)
			return
	_free_manager(mgr)


## Parry deflect must not force a defender out of `swap_rank` / `falling_back` (pair resolve expects both in motion).
static func _run_parry_preserves_formation_pair_state(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var en: Dictionary = mgr.combatants[2]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	var eid: int = _EntityAccess.id_int(en)
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: expected rank0 in swap_rank after start_pair_move (got %s)" % _EntityAccess.state_str(p0))
		_free_manager(mgr)
		return
	if _EntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: expected rank1 in swap_rank after start_pair_move")
		_free_manager(mgr)
		return
	en["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high"}
	_AttackResultApplier.apply_result(mgr, eid, {
		"action": "parry_deflect",
		"target_id": id0,
		"recovery_duration": 0.5,
		"parry_clash_context": {"archetype_id": "", "parry_control": 0.0}
	})
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(
			failures,
			"parry_swap: parry_deflect must not set defender to waiting mid pair move (got %s)"
			% _EntityAccess.state_str(p0)
		)
	if _EntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "parry_swap: partner must stay swap_rank (got %s)" % _EntityAccess.state_str(p1))
	_free_manager(mgr)


## `handle_swap_rank_resolve` completes rank swap when both combatants remain in pair motion state.
static func _run_swap_rank_resolve_completes_rank_swap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var id0: int = _EntityAccess.id_int(p0)
	var id1: int = _EntityAccess.id_int(p1)
	if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
		_fail(failures, "swap_resolve_setup: expected player rank0/rank1 same file")
		_free_manager(mgr)
		return
	_FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
		_fail(failures, "swap_resolve: expected swap_rank state on initiator")
		_free_manager(mgr)
		return
	_FormationFlow.handle_swap_rank_resolve(
		mgr,
		{"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
	)
	if _EntityAccess.rank_int(p0) != 1 or _EntityAccess.rank_int(p1) != 0:
		_fail(
			failures,
			"swap_resolve: expected ranks swapped (p0=%d p1=%d)" % [_EntityAccess.rank_int(p0), _EntityAccess.rank_int(p1)]
		)
	if _EntityAccess.state_str(p0) != CombatConstants.STATE_WAITING or _EntityAccess.state_str(p1) != CombatConstants.STATE_WAITING:
		_fail(failures, "swap_resolve: both should return to waiting (got %s / %s)" % [_EntityAccess.state_str(p0), _EntityAccess.state_str(p1)])
	if p0.has("formation_move_partner_id") or p1.has("formation_move_partner_id"):
		_fail(failures, "swap_resolve: formation_move_partner_id should be cleared")
	_free_manager(mgr)


## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.
static func _run_negligible_hit_recovery_shorter_than_counted_hit(failures: PackedStringArray) -> void:
	var i: float = 0.55
	var t_hit: float = _CombatTiming.recovery_duration(i, "hit", 1.0, 1.0, 100, -1.0)
	var t_neg: float = _CombatTiming.recovery_duration(i, "negligible", 1.0, 1.0, 100, -1.0)
	if not (t_neg < t_hit):
		_fail(
			failures,
			"negligible_recovery: expected negligible < hit (hit=%.4f negligible=%.4f)" % [t_hit, t_neg]
		)


## UI: `CombatLogFormatter` labels `outcome=negligible` distinctly from a counted hit.
static func _run_combat_log_formatter_negligible(failures: PackedStringArray) -> void:
	var line: String = _CombatLogFormatter.format_action_line(
		"Ally",
		"player",
		"Foe",
		"enemy",
		{
			"outcome": "negligible",
			"part": "head",
			"dmg": 0,
			"died": false,
			"total_physical": 0.2,
			"final_cut": 0.0,
			"final_blunt": 0.2,
			"health_before": 10,
			"health_after": 10
		}
	)
	if not line.contains("negligible"):
		_fail(failures, "combat_log_negligible: expected 'negligible' in formatted line: %s" % line)
	var row_neg: String = _CombatLogFormatter.format_last_hit_on_target_row(
		{"outcome": "negligible", "part": "head", "total_physical": 0.2, "dmg": 0}
	)
	if not row_neg.begins_with("Graze:"):
		_fail(failures, "combat_log_negligible_row: expected Graze prefix, got: %s" % row_neg)
	var row_hit: String = _CombatLogFormatter.format_last_hit_on_target_row(
		{"outcome": "hit", "part": "head", "total_physical": 5.0, "dmg": 5}
	)
	if not row_hit.begins_with("Hit:"):
		_fail(failures, "combat_log_hit_row: expected Hit prefix, got: %s" % row_hit)


## Intruders: `assign_combatant_zones` uses host `files`/`ranks` (`formation_id_for_zone_geometry`), not home 1-wide line.
static func _run_intruder_zone_id_uses_host_grid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	for _j in 3:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_FRONT:
		_fail(
			failures,
			"intruder_zoc: non-intruded 1-file fighter expected zone %s got %s"
			% [_ZoneOfControl.ZONE_FRONT, str(p.get("zone_id", ""))]
		)
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 0
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_LEFT_FLANK:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=0 expected %s got %s"
			% [_ZoneOfControl.ZONE_LEFT_FLANK, str(p.get("zone_id", ""))]
		)
	p["file"] = 1
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_FRONT:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=1 (center) expected %s got %s"
			% [_ZoneOfControl.ZONE_FRONT, str(p.get("zone_id", ""))]
		)
	p["file"] = 2
	_ZoneOfControl.assign_combatant_zones(mgr)
	if str(p.get("zone_id", "")) != _ZoneOfControl.ZONE_RIGHT_FLANK:
		_fail(
			failures,
			"intruder_zoc: host 3-wide file=2 expected %s got %s"
			% [_ZoneOfControl.ZONE_RIGHT_FLANK, str(p.get("zone_id", ""))]
		)
	_free_manager(mgr)


## ZoC zone fill: intruders on host `rank`/`file` count toward **host** formation zone tallies (not only `formation_id_str`).
static func _run_zoc_count_alive_includes_intruder_on_host(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	e["rank"] = 0
	e["file"] = 2
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 0
	var n_left: int = _ZoneOfControl.count_alive_in_zone(mgr, "enemy", _ZoneOfControl.ZONE_LEFT_FLANK)
	var n_right: int = _ZoneOfControl.count_alive_in_zone(mgr, "enemy", _ZoneOfControl.ZONE_RIGHT_FLANK)
	if n_left != 1:
		_fail(failures, "zoc_count: enemy left_flank expected 1 (intruder) got %d" % n_left)
	if n_right != 1:
		_fail(failures, "zoc_count: enemy right_flank expected 1 (native) got %d" % n_right)
	if _ZoneOfControl.count_alive_in_zone(mgr, "player", _ZoneOfControl.ZONE_LEFT_FLANK) != 0:
		_fail(failures, "zoc_count: player formation should have no left_flank occupant in this setup")
	_free_manager(mgr)


## Crash neighbor hold: intruder defender uses **host** line neighbors (`formation_id_for_zone_geometry`), not home-roster `formation_id`.
static func _run_crash_neighbor_hold_uses_host_line_for_intruder(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	e0["rank"] = 0
	e0["file"] = 0
	e1["rank"] = 0
	e1["file"] = 2
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 0
	p["file"] = 1
	var form_b: Dictionary = mgr.formations["enemy"]
	var hold_n: float = _IntrusionGeometry.crash_neighbor_hold_support(mgr, p, form_b)
	if hold_n < CombatConstants.CRASH_NEIGHBOR_HOLD_BASE * 0.65:
		_fail(
			failures,
			"crash_neighbor_hold: intruder center file expected flank native bonus, got %.3f" % hold_n
		)
	_free_manager(mgr)


## `reschedule_back_rank_turns(host_fid)` must hit intruders lodged on that host grid (`rank`>0, waiting).
static func _run_reschedule_back_rank_includes_intruder_on_host(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var p: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(p)
	_EventScheduler.cancel_pending_action_ready(mgr, pid)
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 1
	p["file"] = 0
	p["state"] = CombatConstants.STATE_WAITING
	_EventScheduler.reschedule_back_rank_turns(mgr, "enemy")
	var ready: float = _EventScheduler.get_next_action_ready_at(mgr, pid)
	if ready < 0.0:
		_fail(
			failures,
			"event_reschedule_back_rank: intruder rank>0 on enemy host should schedule formation recheck"
		)
	_free_manager(mgr)


## Tier 1.9: `start()` formation preset copies `spear_lane_profile` into formation dict (normalized).
static func _run_spear_lane_profile_preset_normalized(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 1, "density": "normal", CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE: "full"},
		{"files": 1, "ranks": 1}
	)
	var sp: String = str(mgr.formations["player"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
	if sp != CombatConstants.SPEAR_LANE_PROFILE_OPEN:
		_fail(failures, "spear_lane_preset: expected open from alias 'full' got %s" % sp)
	var se: String = str(mgr.formations["enemy"].get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, ""))
	if se != CombatConstants.SPEAR_LANE_PROFILE_AUTO:
		_fail(failures, "spear_lane_preset: enemy default profile should be auto/empty got %s" % se)
	_free_manager(mgr)


## Tier 1.9: **`Weapon.depth_melee_eligible`** from **`WeaponConstants`** definitions — **SPEAR** **true**; **SWORD** default **false** ( **`AvailableActionsBuilder.depth_polearm_lane_open`** gate).
static func _run_weapon_depth_melee_eligible_fixture(failures: PackedStringArray) -> void:
	var w_spear: Weapon = _Weapon.create_from_definition("SPEAR")
	var w_sword: Weapon = _Weapon.create_from_definition("SWORD")
	if w_spear == null or w_sword == null:
		_fail(failures, "depth_melee_elig: missing weapon fixtures")
		return
	if not w_spear.depth_melee_eligible:
		_fail(failures, "depth_melee_elig: SPEAR should be depth_melee_eligible")
	if w_sword.depth_melee_eligible:
		_fail(failures, "depth_melee_elig: SWORD should not be depth_melee_eligible by default")


## Tier 1.9: rank>1 without **`depth_melee_eligible`** weapon → **`depth_polearm_lane_open`** **false** even with same-file living rank-0 ally (lane predicate, not only **`can_melee_threaten`**).
static func _run_depth_polearm_lane_open_false_for_non_eligible_weapon(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth_sw: Dictionary = mgr.combatants[1]
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth_sw):
		_fail(
			failures,
			"depth_lane_non_eligible: rank-1 sword must not open depth polearm lane (rank-0 ally present)"
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** for **`ENGAGEMENT_ROLE_INTRUDED`** combatants (depth lane is home-formation fiction; intruders use host grid / intrusion rules).
static func _run_depth_polearm_lane_open_false_when_intruded(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var p: Dictionary = mgr.combatants[0]
	p["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	p["intrusion_host_fid"] = "enemy"
	p["rank"] = 1
	p["file"] = 0
	if _ActionsBuilder.depth_polearm_lane_open(mgr, p):
		_fail(
			failures,
			"depth_lane_intruded: intruded rank-1 spear must not open home depth polearm lane"
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open`** is **false** at **`rank` ≤ 0** (lane is for **home** depth ranks only).
static func _run_depth_polearm_lane_open_false_at_rank_zero(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var front: Dictionary = mgr.combatants[0]
	if _EntityAccess.rank_int(front) != 0:
		_fail(failures, "depth_lane_r0: expected player spear at rank 0 got rank %s" % str(_EntityAccess.rank_int(front)))
	if _ActionsBuilder.depth_polearm_lane_open(mgr, front):
		_fail(failures, "depth_lane_r0: rank-0 spear must not open depth polearm lane")
	_free_manager(mgr)


## Tier 1.9: no **living** same-file rank-0 partner → **`depth_polearm_lane_open`** **false** (even with **`depth_melee_eligible`** weapon).
static func _run_depth_polearm_lane_open_false_without_living_same_file_rank0(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth_f1: Dictionary = {}
	var front_f1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) != 1:
			continue
		if _EntityAccess.rank_int(c) == 1:
			depth_f1 = c
		elif _EntityAccess.rank_int(c) == 0:
			front_f1 = c
	if depth_f1.is_empty() or front_f1.is_empty():
		_fail(failures, "depth_lane_no_r0: expected player rank-0 + rank-1 at file 1")
		_free_manager(mgr)
		return
	front_f1["alive"] = false
	mgr._recompute_zoc_and_distance()
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth_f1):
		_fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 1 must not open lane when same-file rank-0 is dead"
		)
	var depth_f0: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) == 0 and _EntityAccess.rank_int(c) == 1:
			depth_f0 = c
			break
	if depth_f0.is_empty():
		_fail(failures, "depth_lane_no_r0: expected player rank-1 at file 0")
	elif not _ActionsBuilder.depth_polearm_lane_open(mgr, depth_f0):
		_fail(
			failures,
			"depth_lane_no_r0: rank-1 spear file 0 should still open lane (living same-file rank-0 at file 0)"
		)
	_free_manager(mgr)


## Tier 1.9: **`CombatDistanceBands.depth_polearm_lane_open_by_combatant_id`** matches **`AvailableActionsBuilder.depth_polearm_lane_open`** ( **`formation_id_for_zone_geometry`** `fid` ).
static func _run_depth_polearm_lane_cache_matches_builder(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	mgr._recompute_zoc_and_distance()
	_assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:1file")
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 2, "ranks": 2, "density": "normal"}, e_preset)
	var front_f1: Dictionary = {}
	for c in mgr2.combatants:
		if _EntityAccess.side_str(c) != "player":
			continue
		if _EntityAccess.file_int(c) != 1 or _EntityAccess.rank_int(c) != 0:
			continue
		front_f1 = c
		break
	if front_f1.is_empty():
		_fail(failures, "depth_lane_cache:2wide expected rank-0 file 1")
		_free_manager(mgr2)
		return
	front_f1["alive"] = false
	mgr2._recompute_zoc_and_distance()
	_assert_depth_lane_open_cache_matches_builder(mgr2, failures, "depth_lane_cache:2wide_dead_r0f1")
	_free_manager(mgr2)


## Tier 1.9: same-file rank-0 partner **incapacitated** → **`depth_polearm_lane_open`** **false** (**`same_file_living_rank0_ally`** skips incap).
static func _run_depth_polearm_lane_open_false_when_same_file_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	var ent_r0: CoreEntity = _new_entity("SWORD")
	mgr.register(ent_r0, "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var front: Dictionary = mgr.combatants[0]
	var depth: Dictionary = mgr.combatants[1]
	ent_r0.consciousness = 5.0
	mgr._recompute_zoc_and_distance()
	if not _EntityAccess.is_incapacitated(front):
		_fail(failures, "depth_lane_r0_incap: rank-0 ally should read incapacitated")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(
			failures,
			"depth_lane_r0_incap: rank-1 spear must not open lane when same-file rank-0 is incapacitated"
		)
	_assert_depth_lane_open_cache_matches_builder(mgr, failures, "depth_lane_cache:r0_incap")
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_open(manager, c, "")`** matches **`depth_polearm_lane_open(manager, c, fid)`** when **`fid == formation_id_for_zone_geometry(manager, c)`** (explicit **`zone_geometry_fid`** contract). Covers **home** ranks and an **`ENGAGEMENT_ROLE_INTRUDED`** rank-1 **SPEAR** on the **host** grid.
static func _run_depth_polearm_lane_open_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
		var o_default: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, "")
		var o_explicit: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, fid)
		if o_default != o_explicit:
			_fail(
				failures,
				"depth_lane_fid_rt: id=%d default=%s explicit_fid=%s fid=%s"
				% [_EntityAccess.id_int(c), str(o_default), str(o_explicit), fid]
			)
	_free_manager(mgr)

	var mgr_i: Node = _MgrScript.new()
	mgr_i.register(_new_entity("SPEAR"), "player")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var pin: Dictionary = mgr_i.combatants[0]
	pin["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	pin["intrusion_host_fid"] = "enemy"
	pin["rank"] = 1
	pin["file"] = 0
	mgr_i._recompute_zoc_and_distance()
	for c in mgr_i.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		var fid_i: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr_i, c)
		var o_def_i: bool = _ActionsBuilder.depth_polearm_lane_open(mgr_i, c, "")
		var o_exp_i: bool = _ActionsBuilder.depth_polearm_lane_open(mgr_i, c, fid_i)
		if o_def_i != o_exp_i:
			_fail(
				failures,
				"depth_lane_fid_rt_intr: id=%d default=%s explicit_fid=%s fid=%s"
				% [_EntityAccess.id_int(c), str(o_def_i), str(o_exp_i), fid_i]
			)
	_free_manager(mgr_i)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — open depth lane + **strict** + **tight** + no wedge → **false** (over-shoulder); **`spear_lane_profile` open** on same geometry → **true**.
static func _run_depth_polearm_allows_low_targets_strict_tight_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_allows_low: expected open depth polearm lane for setup")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth):
		_fail(failures, "depth_allows_low: strict+tight+lane open+no wedge should not allow low targets")
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth):
		_fail(failures, "depth_allows_low: spear_lane_profile open should allow low targets on tight formation")
	_free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** **`pa`** depth keys match **`depth_polearm_lane_allows_low_targets`** ( **`assume_depth_lane_open` true** ) and **`DEPTH_POLEARM_LANE_TYPE_*`**.
static func _run_stamp_attack_pair_geometry_depth_lane_flags_consistent(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	var enemy: Dictionary = mgr.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "stamp_depth_geom: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var live_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa)
	if bool(pa.get("depth_polearm_attack", false)) != true:
		_fail(failures, "stamp_depth_geom: expected depth_polearm_attack true")
	var stamped_allow: bool = bool(pa.get("depth_polearm_allows_low_targets", true))
	if stamped_allow != live_tight:
		_fail(
			failures,
			"stamp_depth_geom: allows_low stamped=%s live=%s (strict tight)" % [str(stamped_allow), str(live_tight)]
		)
	var lt: String = str(pa.get("depth_polearm_lane_type", ""))
	var expect_lt: String = (
		CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
		if live_tight
		else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
	)
	if lt != expect_lt:
		_fail(failures, "stamp_depth_geom: lane_type=%s expected %s (strict tight)" % [lt, expect_lt])
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var live_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true)
	var pa2: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, depth, enemy, pa2)
	if bool(pa2.get("depth_polearm_allows_low_targets", false)) != live_open:
		_fail(
			failures,
			"stamp_depth_geom: allows_low stamped=%s live=%s (profile open)" % [str(pa2.get("depth_polearm_allows_low_targets")), str(live_open)]
		)
	var lt2: String = str(pa2.get("depth_polearm_lane_type", ""))
	var expect_lt2: String = (
		CombatConstants.DEPTH_POLEARM_LANE_TYPE_OPEN
		if live_open
		else CombatConstants.DEPTH_POLEARM_LANE_TYPE_OVER_SHOULDER
	)
	if lt2 != expect_lt2:
		_fail(failures, "stamp_depth_geom: lane_type=%s expected %s (profile open)" % [lt2, expect_lt2])
	_free_manager(mgr)


## Tier 1.9 / 3.1: **`stamp_attack_pair_geometry_on_dict`** leaves **`depth_polearm_*`** at non-depth defaults when attacker is rank **0** or rank **>0** with **`depth_polearm_lane_open`** **false**.
static func _run_stamp_attack_pair_geometry_depth_defaults_non_depth_attack(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(_new_entity("SPEAR"), "player")
	m0.register(_new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	var en0: Dictionary = m0.combatants[1]
	if _EntityAccess.rank_int(atk0) != 0:
		_fail(failures, "stamp_depth_def: expected rank-0 spear")
		_free_manager(m0)
		return
	var pa0: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(m0, atk0, en0, pa0)
	_assert_stamp_depth_pa_defaults(pa0, failures, "stamp_depth_def:rank0")
	_free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "enemy")
	var p1: Dictionary = {"files": 1, "ranks": 2, "density": "normal"}
	var e1: Dictionary = {"files": 1, "ranks": 1, "density": "normal"}
	m1.start(p1, e1)
	var atk1: Dictionary = m1.combatants[1]
	var en1: Dictionary = m1.combatants[2]
	if _EntityAccess.rank_int(atk1) <= 0:
		_fail(failures, "stamp_depth_def: expected rank-1 sword")
		_free_manager(m1)
		return
	if _ActionsBuilder.depth_polearm_lane_open(m1, atk1):
		_fail(failures, "stamp_depth_def: rank-1 sword should not open depth lane")
		_free_manager(m1)
		return
	var pa1: Dictionary = {}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(m1, atk1, en1, pa1)
	_assert_stamp_depth_pa_defaults(pa1, failures, "stamp_depth_def:rank1_no_lane")
	_free_manager(m1)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** drops legs iff **`depth_polearm_lane_allows_low_targets`** (**`assume_depth_lane_open` true**) is **false** (same strict/tight vs **`spear_lane_profile` open** flip as other depth harnesses).
static func _run_depth_polearm_parts_filter_tracks_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_parts_al: expected open depth polearm lane")
		_free_manager(mgr)
		return
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_al: strict+tight should not allow low targets before filter assert")
	var filt_tight: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_tight.has("left_leg") or filt_tight.has("right_leg"):
		_fail(failures, "depth_parts_al: filter should drop legs when allows_low false (got %s)" % str(filt_tight))
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_al: open profile should allow low targets before filter assert")
	var filt_open: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_open.has("left_leg") or not filt_open.has("right_leg"):
		_fail(failures, "depth_parts_al: filter should keep legs when allows_low true (got %s)" % str(filt_open))
	_free_manager(mgr)


## Tier 1.9: **`intrusion_wedge_by_file`** pressure at depth file opens lows under **strict**/**tight** (no **`spear_lane_profile` open**) — **`depth_polearm_lane_allows_low_targets`** + **`depth_polearm_targetable_parts_filter`**.
static func _run_depth_polearm_parts_filter_wedge_opens_legs_strict_tight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_parts_wedge: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_parts_wedge: intrusion wedge should open low targets under strict+tight")
	var parts_in: Array = ["head", "chest", "left_leg", "right_leg"]
	var filt: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt.has("left_leg") or not filt.has("right_leg"):
		_fail(failures, "depth_parts_wedge: filter should keep legs when wedge opens lane (got %s)" % str(filt))
	_free_manager(mgr)


## Tier 1.9: **`spear_lane_profile` restricted** — **`depth_polearm_lane_allows_low_targets`** is **false** without wedge pressure, **true** after **`upsert_from_intrusion`** ( **`depth_polearm_targetable_parts_filter`** follows).
static func _run_depth_polearm_restricted_profile_requires_wedge_for_allows_low(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_prof_rest: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["density"] = "loose"
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_LOOSE
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = (
		CombatConstants.SPEAR_LANE_PROFILE_RESTRICTED
	)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_prof_rest: restricted + loose should not allow lows without wedge")
	var parts_in: Array = ["head", "left_leg", "right_leg"]
	var filt_no_w: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if filt_no_w.has("left_leg") or filt_no_w.has("right_leg"):
		_fail(failures, "depth_prof_rest: filter should drop legs without wedge (got %s)" % str(filt_no_w))
	var df: int = _EntityAccess.file_int(depth, 0)
	_IntrusionWedge.upsert_from_intrusion(mgr.formations["player"], df, 999_999, 0.92, 2, 2)
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	if not _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd, true):
		_fail(failures, "depth_prof_rest: wedge should allow lows under restricted profile")
	var filt_w: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(mgr, depth, parts_in)
	if not filt_w.has("left_leg") or not filt_w.has("right_leg"):
		_fail(failures, "depth_prof_rest: filter should keep legs after wedge (got %s)" % str(filt_w))
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** with explicit **`formation_dict_cache`** (deep copy of live dict) matches **`null`** cache (same **`fid`**, **`assume_depth_lane_open` true**).
static func _run_depth_polearm_allows_low_formation_dict_cache_matches_null(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var p_preset := {"files": 1, "ranks": 2, "density": "normal"}
	var e_preset := {"files": 1, "ranks": 1, "density": "normal"}
	mgr.start(p_preset, e_preset)
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_fd_cache: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var fd: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	var fd_dup: Dictionary = fd.duplicate(true)
	var a_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_tight: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_tight != b_tight:
		_fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch strict+tight (null=%s cache=%s)" % [str(a_tight), str(b_tight)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	fd = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, depth, fid)
	fd_dup = fd.duplicate(true)
	var a_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	var b_open: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, fd_dup, true)
	if a_open != b_open:
		_fail(
			failures,
			"depth_al_fd_cache: null vs dict cache mismatch profile open (null=%s cache=%s)" % [str(a_open), str(b_open)]
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_targetable_parts_filter`** is a **pass-through** when **`depth_polearm_lane_open`** is **false** (rank-1 non-polearm) or attacker **`rank` ≤ 0** (no depth lane use).
static func _run_depth_polearm_parts_filter_pass_through_when_no_depth_lane_use(failures: PackedStringArray) -> void:
	var m0: Node = _MgrScript.new()
	m0.register(_new_entity("SPEAR"), "player")
	m0.register(_new_entity("SWORD"), "enemy")
	m0.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk0: Dictionary = m0.combatants[0]
	if _EntityAccess.rank_int(atk0) != 0:
		_fail(failures, "depth_parts_pass: expected rank-0 attacker")
		_free_manager(m0)
		return
	var parts0: Array = ["head", "left_leg", "right_leg"]
	var out0: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(m0, atk0, parts0)
	if out0 != parts0:
		_fail(failures, "depth_parts_pass: rank-0 should not filter parts (got %s)" % str(out0))
	_free_manager(m0)

	var m1: Node = _MgrScript.new()
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "player")
	m1.register(_new_entity("SWORD"), "enemy")
	m1.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var atk1: Dictionary = m1.combatants[1]
	if _EntityAccess.rank_int(atk1) <= 0:
		_fail(failures, "depth_parts_pass: expected rank-1 sword")
		_free_manager(m1)
		return
	if _ActionsBuilder.depth_polearm_lane_open(m1, atk1):
		_fail(failures, "depth_parts_pass: rank-1 sword should not open depth lane")
		_free_manager(m1)
		return
	var parts1: Array = ["head", "left_leg"]
	var out1: Array = _ActionsBuilder.depth_polearm_targetable_parts_filter(m1, atk1, parts1)
	if out1 != parts1:
		_fail(failures, "depth_parts_pass: lane closed should not filter parts (got %s)" % str(out1))
	_free_manager(m1)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets`** — **`assume_depth_lane_open` false** returns **true** when **`depth_polearm_lane_open`** is **false** (depth lane N/A); **`assume_depth_lane_open` true** skips that guard and runs wedge / **`spear_lane_profile`** / discipline (strict+tight → **false** without open profile).
static func _run_depth_polearm_allows_low_assume_skips_closed_lane_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if _EntityAccess.rank_int(depth) <= 0:
		_fail(failures, "depth_al_assume: expected rank-1 depth combatant")
		_free_manager(mgr)
		return
	if _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_assume: rank-1 sword must not open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var without_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if not without_assume:
		_fail(
			failures,
			"depth_al_assume: lane closed + assume false should return true (depth lane N/A)"
		)
	if with_assume:
		_fail(
			failures,
			"depth_al_assume: strict+tight + assume true should evaluate lane rules → false (no open profile)"
		)
	if without_assume == with_assume:
		_fail(failures, "depth_al_assume: assume flag must change result when lane closed vs strict+tight body")
	_free_manager(mgr)


## Tier 1.9: when **`depth_polearm_lane_open`** is **true**, **`depth_polearm_lane_allows_low_targets`** returns the same value whether **`assume_depth_lane_open`** is **false** or **true** (closed-lane early exit skipped in both cases once the lane is open).
static func _run_depth_polearm_allows_low_assume_agrees_when_lane_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var depth: Dictionary = mgr.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr, depth):
		_fail(failures, "depth_al_agree: expected open depth polearm lane")
		_free_manager(mgr)
		return
	_IntrusionWedge.clear_all_wedges_in_formation(mgr.formations["player"])
	mgr.formations["player"]["line_discipline"] = CombatConstants.LINE_DISCIPLINE_STRICT
	mgr.formations["player"]["density"] = "tight"
	mgr.formations["player"].erase(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE)
	var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, depth)
	var tight_no_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var tight_with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if tight_no_assume != tight_with_assume:
		_fail(
			failures,
			"depth_al_agree: strict+tight assume false vs true mismatch (%s vs %s)"
			% [str(tight_no_assume), str(tight_with_assume)]
		)
	mgr.formations["player"][CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE] = CombatConstants.SPEAR_LANE_PROFILE_OPEN
	var open_no_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, false)
	var open_with_assume: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, depth, fid, null, true)
	if open_no_assume != open_with_assume:
		_fail(
			failures,
			"depth_al_agree: profile open assume false vs true mismatch (%s vs %s)"
			% [str(open_no_assume), str(open_with_assume)]
		)
	_free_manager(mgr)


## Tier 1.9: **`depth_polearm_lane_allows_low_targets(manager, c, "", …)`** matches **`…(manager, c, fid, …)`** when **`fid == formation_id_for_zone_geometry(manager, c)`** — same **`zone_geometry_fid`** contract as **`depth_polearm_lane_open`** / **`formation_dict_for_zone_geometry`**. Covers **`assume_depth_lane_open` false + true** on **home** line + **`ENGAGEMENT_ROLE_INTRUDED`** rank-1 **SPEAR** on host grid.
static func _run_depth_polearm_allows_low_zone_geometry_fid_round_trip(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr._recompute_zoc_and_distance()
	_assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, "depth_al_fid_rt:home")
	_free_manager(mgr)

	var mgr_i: Node = _MgrScript.new()
	mgr_i.register(_new_entity("SPEAR"), "player")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.register(_new_entity("SWORD"), "enemy")
	mgr_i.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 2})
	var pin: Dictionary = mgr_i.combatants[0]
	pin["engagement_role"] = CombatConstants.ENGAGEMENT_ROLE_INTRUDED
	pin["intrusion_host_fid"] = "enemy"
	pin["rank"] = 1
	pin["file"] = 0
	mgr_i._recompute_zoc_and_distance()
	_assert_depth_polearm_allows_low_fid_round_trip_slice(mgr_i, failures, "depth_al_fid_rt:intr")
	_free_manager(mgr_i)


static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
	mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
	for assume_open in [false, true]:
		for c in mgr.combatants:
			if not _EntityAccess.alive_bool(c):
				continue
			var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
			var via_empty: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, c, "", null, assume_open)
			var via_fid: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr, c, fid, null, assume_open)
			if via_empty != via_fid:
				_fail(
					failures,
					"%s assume=%s id=%d empty=%s explicit=%s fid=%s"
					% [ctx, str(assume_open), _EntityAccess.id_int(c), str(via_empty), str(via_fid), fid]
				)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
	if bool(pa.get("depth_polearm_attack", true)):
		_fail(failures, "%s: depth_polearm_attack should be false" % ctx)
	if not bool(pa.get("depth_polearm_allows_low_targets", false)):
		_fail(failures, "%s: depth_polearm_allows_low_targets should stay default true" % ctx)
	if str(pa.get("depth_polearm_lane_type", "x")) != "":
		_fail(failures, "%s: depth_polearm_lane_type should be empty" % ctx)


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
	var by_id: Dictionary = _DistanceBands.depth_polearm_lane_open_by_combatant_id(mgr)
	for c in mgr.combatants:
		var cid: int = _EntityAccess.id_int(c)
		if not _EntityAccess.alive_bool(c):
			if by_id.has(cid):
				_fail(failures, "%s: dead id=%d should not be in lane cache" % [ctx, cid])
			continue
		if not by_id.has(cid):
			_fail(failures, "%s: alive id=%d missing from lane cache" % [ctx, cid])
			continue
		var fid: String = _ZoneOfControl.formation_id_for_zone_geometry(mgr, c)
		var live: bool = _ActionsBuilder.depth_polearm_lane_open(mgr, c, fid)
		if bool(by_id[cid]) != live:
			_fail(
				failures,
				"%s: lane cache id=%d cached=%s live=%s rank=%d"
				% [ctx, cid, str(by_id[cid]), str(live), _EntityAccess.rank_int(c)]
			)


## Tier 3.1: pack / protection-circle parry flank uses wedge/lane-aware effective file spacing (falls back to |Δfile|≥2).
## Tier 3.1: sector surround `1/(1+k·excess)` matches integer **`surround_defense_multiplier`** when total weight = 2 (two full-width flank threats).
static func _run_surround_sector_load_formula(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var m_int_two_threats: float = _TacticalCombat.surround_defense_multiplier(d, 2)
	var m_sector: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)
	if not is_equal_approx(m_int_two_threats, m_sector):
		_fail(
			failures,
			"surround_sector: int n=2 %.4f vs sector wsum=2 %.4f" % [m_int_two_threats, m_sector]
		)
	var m_mild: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 1.15)
	if m_mild <= m_int_two_threats + 0.01:
		_fail(
			failures,
			"surround_sector: compressed wsum=1.15 should be milder than int n=2 (%.4f vs %.4f)" % [m_mild, m_int_two_threats]
		)


## Tier 3.1: two adjacent-file enemies vs center defender — summed sector weight stays below two full flank weights.
static func _run_surround_threat_weight_sum_three_file_line(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def_id: int = _EntityAccess.id_int(mgr.combatants[0])
	if _TacticalCombat.count_engaging_threats(mgr, def_id) != 2:
		_fail(failures, "surround_weight_sum: expected two engaging threats")
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02:
		_fail(failures, "surround_weight_sum: adjacent pair should sum < 2 full weights, got %.4f" % wsum)
	if wsum < 0.9:
		_fail(failures, "surround_weight_sum: expected meaningful stacked weight, got %.4f" % wsum)
	_free_manager(mgr)


## Tier 3.1: **`surround_defense_multiplier_from_pa_with_sector`** — integer **`surround_threat_count`** vs sector **`surround_threat_weight_sum`** (explicit flag; production uses **`is_feature_sector_surround_load`**).
static func _run_surround_defense_multiplier_from_pa_both_paths(failures: PackedStringArray) -> void:
	var d: Dictionary = {"stats": {"perception": 100.0}}
	var pa_two: Dictionary = {"surround_threat_count": 2}
	var m_int_path: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, false)
	var m_sector_equiv: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_two, true)
	if not is_equal_approx(m_int_path, _TacticalCombat.surround_defense_multiplier(d, 2)):
		_fail(failures, "surround_from_pa: int path should match surround_defense_multiplier(n=2)")
	if not is_equal_approx(m_sector_equiv, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(d, 2.0)):
		_fail(failures, "surround_from_pa: sector path with count-only pa should match wsum=2")
	if not is_equal_approx(m_int_path, m_sector_equiv):
		_fail(
			failures,
			"surround_from_pa: n=2 int vs sector(count fallback) %.6f vs %.6f" % [m_int_path, m_sector_equiv]
		)
	var pa_mixed: Dictionary = {"surround_threat_count": 2, "surround_threat_weight_sum": 1.15}
	var m_split_two: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, false)
	var m_sector_mild: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(d, pa_mixed, true)
	if not is_equal_approx(m_split_two, m_int_path):
		_fail(failures, "surround_from_pa: mixed pa int path should still use count=2")
	if m_sector_mild <= m_split_two + 0.001:
		_fail(
			failures,
			"surround_from_pa: sector wsum=1.15 should beat int n=2 split (%.6f vs %.6f)" % [m_sector_mild, m_split_two]
		)


## Tier 3.1: live **`compute_surround_threat_weight_sum`** matches **`surround_defense_multiplier_from_pa_with_sector(..., true)`** with **`pa`** shaped like **`AttackResolver`** (count + weight sum).
static func _run_surround_live_weight_sum_matches_from_pa_sector_path(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	if n_threats != 2:
		_fail(failures, "surround_live_pa: expected two engaging threats got %d" % n_threats)
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum >= 2.0 - 0.02 or wsum < 0.9:
		_fail(failures, "surround_live_pa: unexpected wsum=%.4f (want compressed flank pair)" % wsum)
		_free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_sector: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	var m_ref: float = _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)
	if not is_equal_approx(m_sector, m_ref):
		_fail(
			failures,
			"surround_live_pa: sector from_pa %.6f vs harness wsum ref %.6f" % [m_sector, m_ref]
		)
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_int_ref: float = _TacticalCombat.surround_defense_multiplier(def, n_threats)
	if not is_equal_approx(m_int, m_int_ref):
		_fail(
			failures,
			"surround_live_pa: int from_pa %.6f vs surround_defense_multiplier %.6f" % [m_int, m_int_ref]
		)
	if m_sector <= m_int + 0.001:
		_fail(
			failures,
			"surround_live_pa: sector path should be milder than int n=2 (%.6f vs %.6f) wsum=%.4f"
			% [m_sector, m_int, wsum]
		)
	_free_manager(mgr)


## Tier 3.1: one engaging threat — integer **n≤1** and sector **`wsum`≤`SURROUND_SECTOR_LOAD_FREE`** both stay neutral (**1.0**).
static func _run_surround_single_threat_int_and_sector_neutral(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	if n_threats != 1:
		_fail(failures, "surround_single: expected one engaging threat got %d" % n_threats)
		_free_manager(mgr)
		return
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + 0.02:
		_fail(
			failures,
			"surround_single: wsum=%.4f should sit in free tier (≤%.3f)" % [wsum, CombatConstants.SURROUND_SECTOR_LOAD_FREE]
		)
		_free_manager(mgr)
		return
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	if not is_equal_approx(m_int, 1.0):
		_fail(failures, "surround_single: int path want 1.0 got %.6f" % m_int)
	if not is_equal_approx(m_sec, 1.0):
		_fail(failures, "surround_single: sector path want 1.0 got %.6f (wsum=%.4f)" % [m_sec, wsum])
	if not is_equal_approx(m_sec, _TacticalCombat.surround_multiplier_from_weight_sum_for_harness(def, wsum)):
		_fail(failures, "surround_single: sector from_pa vs harness ref mismatch")
	_free_manager(mgr)


## Tier 3.1: **`is_feature_sector_surround_load`** — `surround_defense_multiplier_from_pa` follows runtime toggle (int path off, sector path on).
static func _run_sector_surround_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
	var prev_flag: bool = CombatConstants.is_feature_sector_surround_load()
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr.combatants[0]["file"] = 1
	mgr.combatants[1]["file"] = 0
	mgr.combatants[2]["file"] = 2
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var def: Dictionary = mgr.combatants[0]
	var def_id: int = _EntityAccess.id_int(def)
	var n_threats: int = _TacticalCombat.count_engaging_threats(mgr, def_id)
	var wsum: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, def_id)
	var pa: Dictionary = {"surround_threat_count": n_threats, "surround_threat_weight_sum": wsum}
	if n_threats != 2 or wsum >= 2.0 - 0.02 or wsum < 0.9:
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(failures, "sector_flag_toggle: need compressed two-threat layout (n=%d wsum=%.4f)" % [n_threats, wsum])
		return
	var m_int: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, false)
	var m_sec: float = _TacticalCombat.surround_defense_multiplier_from_pa_with_sector(def, pa, true)
	CombatConstants.set_feature_sector_surround_load(false)
	var from_pa_off: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_off, m_int):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: flag off from_pa %.6f vs int ref %.6f" % [from_pa_off, m_int]
		)
		return
	CombatConstants.set_feature_sector_surround_load(true)
	var from_pa_on: float = _TacticalCombat.surround_defense_multiplier_from_pa(def, pa)
	if not is_equal_approx(from_pa_on, m_sec):
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: flag on from_pa %.6f vs sector ref %.6f" % [from_pa_on, m_sec]
		)
		return
	if from_pa_on <= from_pa_off + 0.001:
		CombatConstants.set_feature_sector_surround_load(prev_flag)
		_free_manager(mgr)
		_fail(
			failures,
			"sector_flag_toggle: sector-on %.6f should exceed int-off %.6f (milder surround)" % [from_pa_on, from_pa_off]
		)
		return
	CombatConstants.set_feature_sector_surround_load(prev_flag)
	_free_manager(mgr)


## Tier 1.6: `posture_cohesion_targeting_mult` rises with line cohesion in LINE posture; OPEN uses inverse (looser line → higher mult).
static func _run_ai_targeting_posture_cohesion_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var fd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, pfid)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	fd["line_cohesion"] = 0.0
	var m_line_lo: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 1.0
	var m_line_hi: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_line_hi < m_line_lo + 0.001:
		_fail(
			failures,
			"ai_targeting_posture: LINE mult should increase with cohesion (lo=%.4f hi=%.4f)" % [m_line_lo, m_line_hi]
		)
	fd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	fd["line_cohesion"] = 1.0
	var m_open_tight: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	fd["line_cohesion"] = 0.0
	var m_open_loose: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	if m_open_loose < m_open_tight + 0.001:
		_fail(
			failures,
			"ai_targeting_posture: OPEN mult should increase when cohesion drops (tight=%.4f loose=%.4f)"
			% [m_open_tight, m_open_loose]
		)
	_free_manager(mgr)


## Tier 1.6: **`distributed_pressure_mult`** — ally doctrine commit to the same defender lowers **`hostile_pair_targeting_weight_mult`** for a second attacker (cached engagement-mode mult so snapshot stays stable).
static func _run_hostile_pair_distributed_pressure_ally_commit(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr.combat_clock = 10.0
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var e0: Dictionary = mgr.combatants[2]
	if _EntityAccess.side_str(p0) != "player" or _EntityAccess.side_str(p1) != "player":
		_fail(failures, "dist_pressure: expected first two combatants on player side")
		_free_manager(mgr)
		return
	if _EntityAccess.side_str(e0) != "enemy":
		_fail(failures, "dist_pressure: expected third combatant enemy")
		_free_manager(mgr)
		return
	p0["doctrine_target_commit_id"] = -1
	p1["doctrine_target_commit_id"] = -1
	var p0id: int = _EntityAccess.id_int(p0)
	var p1id: int = _EntityAccess.id_int(p1)
	var e0id: int = _EntityAccess.id_int(e0)
	var m_mode: float = _TargetScoring.engagement_mode_targeting_mult(mgr)
	var dp_none: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	var w_before: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
	_TargetScoring.on_combat_commitment(mgr, p1id, e0id)
	var dp_ally: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	var w_after: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p0, e0, m_mode)
	if dp_ally >= dp_none - 1e-6:
		_fail(
			failures,
			"dist_pressure: distributed mult should drop when ally commits none=%.6f ally=%.6f" % [dp_none, dp_ally]
		)
	if w_after >= w_before - 1e-6:
		_fail(
			failures,
			"dist_pressure: hostile weight should drop before=%.6f after=%.6f" % [w_before, w_after]
		)
	var cnt: int = _TargetScoring.ally_pressure_count(mgr, e0id, "player", p0id)
	if cnt != 1:
		_fail(failures, "dist_pressure: expected ally_pressure_count=1 got %d" % cnt)
	p1["doctrine_target_commit_id"] = -1
	p1.erase("doctrine_commit_until")
	var dp_restored: float = _TargetScoring.distributed_pressure_mult(mgr, p0, e0id)
	if not is_equal_approx(dp_restored, dp_none):
		_fail(
			failures,
			"dist_pressure: clearing commit should restore pressure mult restored=%.6f none=%.6f"
			% [dp_restored, dp_none]
		)
	_free_manager(mgr)


## Tier 1.6 / 1.9: **`CombatTargetScoring.ally_pressure_count`** — committed rank>0 allies count only when **`AvailableActionsBuilder._melee_pair_rank_allowed`** to the committed defender ( **`depth_polearm_valid_line_threat`** for home depth vs rank-0; intruder paths unchanged).
static func _run_ally_pressure_count_depth_uses_melee_pair_to_defender(failures: PackedStringArray) -> void:
	var mgr_near: Node = _MgrScript.new()
	mgr_near.register(_new_entity("SWORD"), "player")
	mgr_near.register(_new_entity("SPEAR"), "player")
	mgr_near.register(_new_entity("SWORD"), "enemy")
	mgr_near.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	for c in mgr_near.combatants:
		c["gauge"] = 100.0
	mgr_near.combat_clock = 10.0
	mgr_near._recompute_zoc_and_distance()
	var p0n: Dictionary = mgr_near.combatants[0]
	var p1n: Dictionary = mgr_near.combatants[1]
	var e0n: Dictionary = mgr_near.combatants[2]
	var p0nid: int = _EntityAccess.id_int(p0n)
	var p1nid: int = _EntityAccess.id_int(p1n)
	var e0nid: int = _EntityAccess.id_int(e0n)
	if not _ActionsBuilder._melee_pair_rank_allowed(mgr_near, p1n, e0n):
		_fail(failures, "ally_press_dep: near layout expected _melee_pair_rank_allowed depth→e0")
		_free_manager(mgr_near)
		return
	_TargetScoring.on_combat_commitment(mgr_near, p1nid, e0nid)
	var cnt_near: int = _TargetScoring.ally_pressure_count(mgr_near, e0nid, "player", p0nid)
	if cnt_near != 1:
		_fail(failures, "ally_press_dep: near expected ally_pressure_count=1 got %d" % cnt_near)
	p1n["doctrine_target_commit_id"] = -1
	_free_manager(mgr_near)

	var mgr_far: Node = _MgrScript.new()
	mgr_far.register(_new_entity("SWORD"), "player")
	mgr_far.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr_far.register(_new_entity("SWORD"), "enemy")
	mgr_far.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c2 in mgr_far.combatants:
		c2["gauge"] = 100.0
	mgr_far.combat_clock = 10.0
	mgr_far._recompute_zoc_and_distance()
	var depth_far: Dictionary = mgr_far.combatants[1]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr_far, depth_far):
		_fail(failures, "ally_press_dep: far layout expected open depth lane")
		_free_manager(mgr_far)
		return
	for i in range(2, 5):
		(mgr_far.combatants[i] as Dictionary)["file"] = 7 + i
	mgr_far._recompute_zoc_and_distance()
	var e0_far: Dictionary = mgr_far.combatants[2]
	if _ActionsBuilder._melee_pair_rank_allowed(mgr_far, depth_far, e0_far):
		_fail(failures, "ally_press_dep: far enemies expected no _melee_pair_rank_allowed depth→e0")
		_free_manager(mgr_far)
		return
	var p0f: Dictionary = mgr_far.combatants[0]
	var p0fid: int = _EntityAccess.id_int(p0f)
	var e0fid: int = _EntityAccess.id_int(e0_far)
	var p1fid: int = _EntityAccess.id_int(depth_far)
	_TargetScoring.on_combat_commitment(mgr_far, p1fid, e0fid)
	var cnt_far: int = _TargetScoring.ally_pressure_count(mgr_far, e0fid, "player", p0fid)
	if cnt_far != 0:
		_fail(
			failures,
			"ally_press_dep: far-line committed depth should not count pressure got %d" % cnt_far
		)
	_free_manager(mgr_far)


## Tier 1.6: **`CombatTargetScoring.hold_lane_mult`** — **`hold_lane`** doctrine hedges listed weights vs **non**-file-opposed rank-0 pairs; file-opposed front returns **1.0**.
static func _run_targeting_hold_lane_off_file_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_off: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_off, CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT):
		_fail(
			failures,
			"hold_lane_mult: off-file expected %.4f got %.4f" % [CombatConstants.DOCTRINE_HOLD_LANE_OFF_FILE_MULT, m_off]
		)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_same: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_same, 1.0):
		_fail(failures, "hold_lane_mult: file-opposed front should be neutral got %.4f" % m_same)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	var m_pinch: float = _TargetScoring.hold_lane_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, 1.0):
		_fail(failures, "hold_lane_mult: pinch doctrine should not apply hold hedge got %.4f" % m_pinch)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.hold_lane_mult(mgr, p, e), 1.0):
		_fail(failures, "hold_lane_mult: default doctrine should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.file_opposed_mult`** — same-file rank-0 pair (or depth polearm using same-file rank-0 ally) applies **`DOCTRINE_FILE_OPPOSED_WEIGHT_MULT`**; off-file → **1.0**.
static func _run_targeting_file_opposed_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var m_off: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_off, 1.0):
		_fail(failures, "file_opposed_mult: off-file rank-0 expected 1.0 got %.4f" % m_off)
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_front: float = _TargetScoring.file_opposed_mult(mgr, p, e)
	if not is_equal_approx(m_front, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		_fail(
			failures,
			"file_opposed_mult: same-file rank-0 expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_front]
		)
	_free_manager(mgr)
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.register(_new_entity("SWORD"), "enemy")
	var p2_preset := {"files": 2, "ranks": 2, "density": "normal"}
	var e2_preset := {"files": 2, "ranks": 1, "density": "normal"}
	mgr2.start(p2_preset, e2_preset)
	for c in mgr2.combatants:
		c["gauge"] = 100.0
	var front: Dictionary = mgr2.combatants[0]
	var depth: Dictionary = mgr2.combatants[1]
	var en_same: Dictionary = mgr2.combatants[2]
	var en_off: Dictionary = mgr2.combatants[3]
	front["file"] = 0
	front["rank"] = 0
	depth["file"] = 0
	depth["rank"] = 1
	en_same["file"] = 0
	en_same["rank"] = 0
	en_off["file"] = 1
	en_off["rank"] = 0
	mgr2._recompute_zoc_and_distance()
	if not _ActionsBuilder.depth_polearm_lane_open(mgr2, depth):
		_fail(failures, "file_opposed_mult_depth: expected depth spear lane open")
		_free_manager(mgr2)
		return
	var m_depth_same: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_same)
	if not is_equal_approx(m_depth_same, CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT):
		_fail(
			failures,
			"file_opposed_mult_depth: front ally file-opposed expected %.4f got %.4f"
			% [CombatConstants.DOCTRINE_FILE_OPPOSED_WEIGHT_MULT, m_depth_same]
		)
	var m_depth_off: float = _TargetScoring.file_opposed_mult(mgr2, depth, en_off)
	if not is_equal_approx(m_depth_off, 1.0):
		_fail(failures, "file_opposed_mult_depth: off-file enemy expected 1.0 got %.4f" % m_depth_off)
	_free_manager(mgr2)


## Tier 1.6: **`CombatTargetScoring.pinch_score_mult`** — **`pinch_center`** + **`wing_lacks_file_opposed`** nudges weight toward enemies nearer the hostile line center ( **`DOCTRINE_PINCH_INWARD_BIAS_PER_FILE`** ).
static func _run_targeting_pinch_center_inward_bonus(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 2, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	p["file"] = 0
	e["file"] = 1
	p["rank"] = 0
	e["rank"] = 0
	mgr._recompute_zoc_and_distance()
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	if not _TargetScoring.wing_lacks_file_opposed(mgr, p):
		_fail(failures, "pinch_bonus: expected wing_lacks_file_opposed for off-file rank-0 pair")
		_free_manager(mgr)
		return
	var inward: float = absf(float(_EntityAccess.file_int(e)) - 1.0)
	var want: float = 1.0 + CombatConstants.DOCTRINE_PINCH_INWARD_BIAS_PER_FILE * maxf(0.0, 2.5 - inward)
	var m_pinch: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_pinch, want):
		_fail(failures, "pinch_bonus: expected %.6f got %.6f (inward=%.4f)" % [want, m_pinch, inward])
	e["file"] = 0
	mgr._recompute_zoc_and_distance()
	var m_opposed: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_opposed, 1.0):
		_fail(failures, "pinch_bonus: file-opposed front should suppress pinch got %.4f" % m_opposed)
	e["file"] = 1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var m_hold_doc: float = _TargetScoring.pinch_score_mult(mgr, p, e)
	if not is_equal_approx(m_hold_doc, 1.0):
		_fail(failures, "pinch_bonus: hold_lane doctrine should not apply pinch inward got %.4f" % m_hold_doc)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	if not is_equal_approx(_TargetScoring.pinch_score_mult(mgr, p, e), 1.0):
		_fail(failures, "pinch_bonus: default doctrine should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.commitment_match_mult`** after **`on_combat_commitment`** ( **`DOCTRINE_COMMIT_MATCH_WEIGHT_MULT`** ).
static func _run_targeting_commitment_match_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	p["doctrine_target_commit_id"] = -1
	var m_neutral: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_neutral, 1.0):
		_fail(failures, "commit_match: no commit should be 1.0 got %.4f" % m_neutral)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	var m_match: float = _TargetScoring.commitment_match_mult(p, eid)
	if not is_equal_approx(m_match, CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		_fail(
			failures,
			"commit_match: expected %.4f got %.4f" % [CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT, m_match]
		)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid + 9999), 1.0):
		_fail(failures, "commit_match: wrong target id should be neutral")
	_free_manager(mgr)


## Tier 1.6: **`CombatTargetScoring.soft_geometry_score`** = **`1/(1 + effective_pair_eff_dist × DOCTRINE_SOFT_DISTANCE_SCALE)`**; larger eff → lower score (monotone).
static func _run_targeting_soft_geometry_eff_dist_formula(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	for c in mgr.combatants:
		c["gauge"] = 100.0
	var p: Dictionary = mgr.combatants[0]
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	if _EntityAccess.side_str(p) != "player":
		_fail(failures, "soft_geom: expected combatants[0] player")
		_free_manager(mgr)
		return
	if _EntityAccess.side_str(e0) != "enemy" or _EntityAccess.side_str(e1) != "enemy":
		_fail(failures, "soft_geom: expected combatants[1–2] enemy")
		_free_manager(mgr)
		return
	p["file"] = 1
	p["rank"] = 0
	e0["file"] = 0
	e0["rank"] = 0
	e1["file"] = 2
	e1["rank"] = 0
	mgr._recompute_zoc_and_distance()
	var eff0: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p, e0)
	var eff1: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p, e1)
	var k: float = CombatConstants.DOCTRINE_SOFT_DISTANCE_SCALE
	var s0: float = _TargetScoring.soft_geometry_score(mgr, p, e0)
	var s1: float = _TargetScoring.soft_geometry_score(mgr, p, e1)
	var want0: float = 1.0 / (1.0 + eff0 * k)
	var want1: float = 1.0 / (1.0 + eff1 * k)
	if not is_equal_approx(s0, want0):
		_fail(failures, "soft_geom: pair0 formula want %.6f got %.6f eff=%.4f" % [want0, s0, eff0])
	if not is_equal_approx(s1, want1):
		_fail(failures, "soft_geom: pair1 formula want %.6f got %.6f eff=%.4f" % [want1, s1, eff1])
	if absf(eff0 - eff1) > 0.02:
		if eff0 < eff1 and not (s0 > s1 + 1e-5):
			_fail(
				failures,
				"soft_geom: lower eff should score higher eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
			)
		if eff0 > eff1 and not (s0 < s1 - 1e-5):
			_fail(
				failures,
				"soft_geom: higher eff should score lower eff0=%.4f eff1=%.4f s0=%.6f s1=%.6f" % [eff0, eff1, s0, s1]
			)
	_free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears stale **`doctrine_target_commit_id`** after **`doctrine_commit_until`** vs **`combat_clock`**.
static func _run_targeting_prune_expired_doctrine_commitment(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), CombatConstants.DOCTRINE_COMMIT_MATCH_WEIGHT_MULT):
		_fail(failures, "prune_commit: expected match mult after on_combat_commitment")
	mgr.combat_clock = float(p.get("doctrine_commit_until", 0.0)) + 0.25
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "prune_commit: expected doctrine_target_commit_id cleared after expiry")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		_fail(failures, "prune_commit: commitment_match_mult should be neutral after prune")
	_free_manager(mgr)


## Tier 1.6: **`prune_expired_commitments`** clears doctrine commit when the **committed target** is no longer alive (before clock expiry).
static func _run_targeting_prune_commitment_when_target_dies(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid, eid)
	if int(p.get("doctrine_target_commit_id", -2)) != eid:
		_fail(failures, "prune_dead_tgt: expected live commit before kill")
	e["alive"] = false
	_TargetScoring.prune_expired_commitments(mgr)
	if int(p.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "prune_dead_tgt: expected commit cleared when target dies")
	if not is_equal_approx(_TargetScoring.commitment_match_mult(p, eid), 1.0):
		_fail(failures, "prune_dead_tgt: commitment_match_mult should be neutral after dead-target prune")
	_free_manager(mgr)


## Tier 1.6: **`clear_all_targeting_state_for_dead_defender`** (death hook) clears **all** allies’ doctrine commits and **close_block** rows keyed to the dead defender.
static func _run_targeting_clear_all_state_for_dead_defender(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p0: Dictionary = mgr.combatants[0]
	var p1: Dictionary = mgr.combatants[1]
	var e0: Dictionary = mgr.combatants[2]
	var pid0: int = _EntityAccess.id_int(p0)
	var pid1: int = _EntityAccess.id_int(p1)
	var eid: int = _EntityAccess.id_int(e0)
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, pid0, eid)
	_TargetScoring.on_combat_commitment(mgr, pid1, eid)
	if int(p0.get("doctrine_target_commit_id", -2)) != eid or int(p1.get("doctrine_target_commit_id", -2)) != eid:
		_fail(failures, "clear_dead_def: expected both allies committed to dead target id")
	var blk0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	blk0[eid] = 999.0
	p0["close_block_until_by_target_id"] = blk0
	var blk1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	blk1[eid] = 888.0
	p1["close_block_until_by_target_id"] = blk1
	_TargetScoring.clear_all_targeting_state_for_dead_defender(mgr, eid)
	if int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1:
		_fail(failures, "clear_dead_def: expected doctrine_target_commit_id cleared for both allies")
	var b0: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
	var b1: Dictionary = p1.get("close_block_until_by_target_id", {}) as Dictionary
	if b0.has(eid) or b1.has(eid):
		_fail(failures, "clear_dead_def: expected close_block_until_by_target_id entries for dead id erased")
	_free_manager(mgr)


## Tier 1.6 breadth: `opponent_formation_targeting_mult` — solid enemy LINE hedges listed weights; ragged LINE presses; OPEN uses fixed nudge.
static func _run_ai_targeting_opponent_formation_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var opp: Dictionary = mgr.combatants[1]
	var efid: String = _EntityAccess.formation_id_str(opp)
	var efd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, efid)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	efd["line_cohesion"] = 1.0
	var m_solid: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	efd["line_cohesion"] = 0.0
	var m_ragged: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if m_solid >= m_ragged - 0.001:
		_fail(
			failures,
			"ai_targeting_opp_form: LINE solid should hedge vs ragged (solid=%.4f ragged=%.4f)" % [m_solid, m_ragged]
		)
	efd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_OPEN
	var m_open: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	if not is_equal_approx(m_open, CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT):
		_fail(
			failures,
			"ai_targeting_opp_form: OPEN expected %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_OPP_OPEN_DUEL_MULT, m_open]
		)
	_free_manager(mgr)


## Tier 1.6 breadth: `opponent_breach_file_targeting_mult` — higher listed weight vs enemies on a breached file column.
static func _run_ai_targeting_breach_file_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1, "density": "normal"})
	var e0: Dictionary = mgr.combatants[1]
	var e1: Dictionary = mgr.combatants[2]
	if _EntityAccess.file_int(e0) != 0 or _EntityAccess.file_int(e1) != 1:
		_fail(failures, "ai_targeting_breach: expected enemy files 0 and 1")
	var efid: String = _EntityAccess.formation_id_str(e0)
	var efd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, efid)
	efd["breached_files"] = {0: 1.0}
	var m_clean: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e1)
	var m_breach: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e0)
	if not is_equal_approx(m_clean, 1.0):
		_fail(
			failures,
			"ai_targeting_breach: unbreached file mult should be 1.0 got %.4f" % m_clean
		)
	if m_breach <= m_clean + 0.001:
		_fail(
			failures,
			"ai_targeting_breach: breached file should raise mult (breach=%.4f clean=%.4f)" % [m_breach, m_clean]
		)
	if not is_equal_approx(m_breach, CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX):
		_fail(
			failures,
			"ai_targeting_breach: full severity want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX, m_breach]
		)
	efd["breached_files"] = {0: 0.5}
	var m_half: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, e0)
	var want_half: float = lerpf(1.0, CombatConstants.AI_TARGETING_OPP_BREACH_FILE_MULT_MAX, 0.5)
	if not is_equal_approx(m_half, want_half):
		_fail(
			failures,
			"ai_targeting_breach: half severity want %.4f got %.4f" % [want_half, m_half]
		)
	_free_manager(mgr)


## Tier 1.6: **`formation_dict_cache`** on **`opponent_formation_targeting_mult`**, **`opponent_breach_file_targeting_mult`**, **`posture_cohesion_targeting_mult`** matches live **`ZoneOfControl.formation_dict_for_zone_geometry`**.
static func _run_targeting_formation_dict_cache_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "density": "normal"}, {"files": 1, "ranks": 1, "density": "normal"})
	var p: Dictionary = mgr.combatants[0]
	var opp: Dictionary = mgr.combatants[1]
	var pfid: String = _EntityAccess.formation_id_str(p)
	var pfd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, pfid)
	pfd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	pfd["line_cohesion"] = 0.42
	var ofid: String = _EntityAccess.formation_id_str(opp)
	var ofd: Dictionary = _FormationSlots.formation_record_read(mgr.formations, ofid)
	ofd["engagement_posture"] = CombatConstants.ENGAGEMENT_POSTURE_LINE
	ofd["line_cohesion"] = 0.61
	ofd["breached_files"] = {0: 0.75}
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var fd_p: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, p)
	var fd_o: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, opp)
	var m_pc_l: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p)
	var m_pc_c: float = _TargetScoring.posture_cohesion_targeting_mult(mgr, p, fd_p)
	if not is_equal_approx(m_pc_l, m_pc_c):
		_fail(
			failures,
			"tgt_fd_cache: posture_cohesion live %.6f vs cache %.6f" % [m_pc_l, m_pc_c]
		)
	var m_of_l: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp)
	var m_of_c: float = _TargetScoring.opponent_formation_targeting_mult(mgr, opp, fd_o)
	if not is_equal_approx(m_of_l, m_of_c):
		_fail(
			failures,
			"tgt_fd_cache: opponent_formation live %.6f vs cache %.6f" % [m_of_l, m_of_c]
		)
	var m_br_l: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, opp)
	var m_br_c: float = _TargetScoring.opponent_breach_file_targeting_mult(mgr, opp, fd_o)
	if not is_equal_approx(m_br_l, m_br_c):
		_fail(
			failures,
			"tgt_fd_cache: opponent_breach live %.6f vs cache %.6f" % [m_br_l, m_br_c]
		)
	_free_manager(mgr)


## Tier 1.6 / 1.7: `engagement_mode_targeting_mult` tracks resolved duel / skirmish / formation.
static func _run_ai_targeting_engagement_mode_mult(failures: PackedStringArray) -> void:
	var d: Node = _MgrScript.new()
	d.register(_new_entity("SWORD"), "player")
	d.register(_new_entity("SWORD"), "enemy")
	d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if _EngagementMode.engagement_mode(d) != CombatConstants.ENGAGEMENT_MODE_DUEL:
		_fail(
			failures,
			"ai_targeting_eng_mode: expected duel for 1v1 got %s" % _EngagementMode.engagement_mode(d)
		)
	var m_duel: float = _TargetScoring.engagement_mode_targeting_mult(d)
	if not is_equal_approx(m_duel, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: duel mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_DUEL_MULT, m_duel]
		)
	_free_manager(d)
	var s: Node = _MgrScript.new()
	for _i in 3:
		s.register(_new_entity("SWORD"), "player")
	for _j in 3:
		s.register(_new_entity("SWORD"), "enemy")
	s.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	if str(_EngagementMode.snapshot(s).get("raw_mode", "")) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
		_fail(
			failures,
			"ai_targeting_eng_mode: 3v3 expected raw skirmish got %s"
			% str(_EngagementMode.snapshot(s).get("raw_mode", ""))
		)
	var m_sk: float = _TargetScoring.engagement_mode_targeting_mult(s)
	if not is_equal_approx(m_sk, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: skirmish mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_SKIRMISH_MULT, m_sk]
		)
	_free_manager(s)
	var f: Node = _MgrScript.new()
	for _i in 4:
		f.register(_new_entity("SWORD"), "player")
	for _j in 4:
		f.register(_new_entity("SWORD"), "enemy")
	f.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
	if _EngagementMode.engagement_mode(f) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(
			failures,
			"ai_targeting_eng_mode: expected formation for 4v4 line got %s"
			% _EngagementMode.engagement_mode(f)
		)
	var m_form: float = _TargetScoring.engagement_mode_targeting_mult(f)
	if not is_equal_approx(m_form, CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT):
		_fail(
			failures,
			"ai_targeting_eng_mode: formation mult want %.4f got %.4f"
			% [CombatConstants.AI_TARGETING_ENGAGEMENT_MODE_FORMATION_MULT, m_form]
		)
	_free_manager(f)


## Tier 1.6: **`hostile_pair_targeting_weight_mult`** — passing **`engagement_mode_targeting_mult(manager)`** as **`cached_engagement_mode_targeting_mult`** matches the **null** overload (same snapshot).
static func _run_hostile_pair_cached_engagement_mode_matches_live(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var w_live: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e)
	var em: float = _TargetScoring.engagement_mode_targeting_mult(mgr)
	var w_cached: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e, em)
	if not is_equal_approx(w_live, w_cached):
		_fail(
			failures,
			"hostile_pair_em_cache: live %.8f vs cached-arg %.8f (em=%.8f)" % [w_live, w_cached, em]
		)
	_free_manager(mgr)


## Tier 3.1: depth spear lane parry mults in `DefenseChoiceResolver` (tight → `parry_c_d`; open + stab → `parry_p_a`).
static func _run_depth_spear_tight_lane_parry_mult_invariant(failures: PackedStringArray) -> void:
	var m0: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult({})
	var m_open: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{
			"depth_polearm_attack": true,
			"depth_polearm_allows_low_targets": true,
			"depth_polearm_lane_type": "open",
		}
	)
	var m_tight: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{
			"depth_polearm_attack": true,
			"depth_polearm_allows_low_targets": false,
			"depth_polearm_lane_type": "over_shoulder",
		}
	)
	var m_empty_allows: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{"depth_polearm_attack": true, "depth_polearm_allows_low_targets": true, "depth_polearm_lane_type": ""}
	)
	var m_empty_tight: float = _DefenseChoice.depth_spear_tight_lane_parry_c_d_mult(
		{"depth_polearm_attack": true, "depth_polearm_allows_low_targets": false, "depth_polearm_lane_type": ""}
	)
	if not is_equal_approx(m0, 1.0) or not is_equal_approx(m_open, 1.0):
		_fail(
			failures,
			"depth_spear_parry_mult: expected 1.0 for non-depth or open lane got m0=%.4f m_open=%.4f" % [m0, m_open]
		)
	if not is_equal_approx(m_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
		_fail(
			failures,
			"depth_spear_parry_mult: tight lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_tight]
		)
	if not is_equal_approx(m_empty_allows, 1.0):
		_fail(
			failures,
			"depth_spear_parry_mult: empty lane_type + allows_low should follow open got %.4f" % m_empty_allows
		)
	if not is_equal_approx(m_empty_tight, CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT):
		_fail(
			failures,
			"depth_spear_parry_mult: empty lane_type + tight allows_low want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_TIGHT_LANE_PARRY_C_D_MULT, m_empty_tight]
		)
	var pa_open: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": true,
		"depth_polearm_lane_type": "open",
	}
	var pa_tight: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": false,
		"depth_polearm_lane_type": "over_shoulder",
	}
	var a_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "thrust")
	var pa_legacy_lane: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": true,
		"depth_polearm_lane_type": "",
	}
	var a_legacy_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_legacy_lane, "thrust")
	var a_tight_stab: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_tight, "thrust")
	var a_slash: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(pa_open, "slash")
	var a0: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult({}, "thrust")
	if not is_equal_approx(a_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		_fail(
			failures,
			"depth_spear_parry_p_a: open+stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_stab]
		)
	if not is_equal_approx(a_legacy_stab, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		_fail(
			failures,
			"depth_spear_parry_p_a: empty lane_type + allows_low stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT, a_legacy_stab]
		)
	var pa_open_tight_bool: Dictionary = {
		"depth_polearm_attack": true,
		"depth_polearm_allows_low_targets": false,
		"depth_polearm_lane_type": "open",
	}
	var a_open_id_over_allows: float = _DefenseChoice.depth_spear_open_lane_stab_parry_p_a_mult(
		pa_open_tight_bool, "thrust"
	)
	if not is_equal_approx(a_open_id_over_allows, CombatConstants.DEPTH_SPEAR_OPEN_LANE_STAB_PARRY_P_A_MULT):
		_fail(
			failures,
			"depth_spear_parry_p_a: explicit open lane id should win over allows_low=false got %.4f"
			% a_open_id_over_allows
		)
	if not is_equal_approx(a_tight_stab, 1.0) or not is_equal_approx(a_slash, 1.0) or not is_equal_approx(a0, 1.0):
		_fail(
			failures,
			"depth_spear_parry_p_a: expected 1.0 for tight stab / open slash / non-depth got tight=%.4f slash=%.4f a0=%.4f"
			% [a_tight_stab, a_slash, a0]
		)


## Tier 3.1: **`CombatConstants.STRIKE_MEASURE_*`** drive **`strike_measure_ratio_for_weapon_eff_dist`** (formula lock).
static func _run_strike_measure_constants_sanity(failures: PackedStringArray) -> void:
	var w: Weapon = _Weapon.create_from_definition("SWORD")
	if w == null:
		_fail(failures, "strike_meas_const: missing SWORD weapon")
		return
	var eff_in: float = 1.0
	var got: float = _ActionsBuilder.strike_measure_ratio_for_weapon_eff_dist(w, eff_in)
	var eff: float = maxf(eff_in, CombatConstants.STRIKE_MEASURE_EFF_DIST_FLOOR)
	var melee: float = w.melee_range
	var want: float = clampf(
		melee / eff, CombatConstants.STRIKE_MEASURE_RATIO_MIN, CombatConstants.STRIKE_MEASURE_RATIO_MAX
	)
	if not is_equal_approx(got, want):
		_fail(
			failures,
			"strike_meas_const: got %.4f want %.4f (melee=%.3f eff_floor=%.3f)"
			% [got, want, melee, eff]
		)


## Tier 3.1: `AvailableActionsBuilder.stamp_attack_pair_geometry_on_dict` via wind-up (re-stamped each resolve).
## Covers rank-0, depth 1-file line, and depth vs 3-wide enemy frontage (stamp vs live builder).
static func _run_windup_pending_attack_pair_geometry(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p0_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_WindUpStarter.start(mgr, p0_id, e0_id, "thrust")
	var comb_pa0: Variant = mgr._get_by_id(p0_id)
	var pa0: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa0 if comb_pa0 is Dictionary else {}, "pending_attack")
	if pa0.is_empty():
		_fail(failures, "windup_geom: empty pending_attack (rank0)")
	else:
		if not pa0.has("effective_pair_file_spacing_equivalent") or not pa0.has("effective_pair_eff_dist"):
			_fail(failures, "windup_geom: rank0 missing spacing keys")
		var p0: Dictionary = mgr.combatants[0]
		var e0: Dictionary = mgr.combatants[1]
		var want_eff0: float = _ActionsBuilder.effective_pair_eff_dist(mgr, p0, e0)
		var want_space0: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e0)
		if not is_equal_approx(float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0):
			_fail(
				failures,
				"windup_geom: rank0 eff_dist stamp %.4f vs builder %.4f"
				% [float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0]
			)
		if not is_equal_approx(float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0):
			_fail(
				failures,
				"windup_geom: rank0 file_spacing_eq stamp %.4f vs builder %.4f"
				% [float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0]
			)
		var w0: Variant = _EntityAccess.get_weapon(p0)
		if w0 != null:
			var want_meas0: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr, p0, e0, w0, want_eff0)
			if not is_equal_approx(float(pa0.get("strike_measure_ratio", -9.0)), want_meas0):
				_fail(
					failures,
					"windup_geom: rank0 strike_measure_ratio %.4f vs eff-keyed measure %.4f"
					% [float(pa0.get("strike_measure_ratio", -9.0)), want_meas0]
				)
		if bool(pa0.get("depth_polearm_attack", true)):
			_fail(failures, "windup_geom: rank0 must not set depth_polearm_attack")
		if str(pa0.get("depth_polearm_lane_type", "")) != "":
			_fail(failures, "windup_geom: rank0 must not set depth_polearm_lane_type")
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 2, "density": "loose"}, {"files": 1, "ranks": 1, "density": "normal"})
	mgr2._recompute_zoc_and_distance()
	var depth: Dictionary = mgr2.combatants[1]
	var en: Dictionary = mgr2.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr2, depth):
		_fail(failures, "windup_geom: expected depth polearm lane open")
	else:
		var d_id: int = _EntityAccess.id_int(depth)
		var en_id: int = _EntityAccess.id_int(en)
		_WindUpStarter.start(mgr2, d_id, en_id, "spear_thrust")
		var comb_pa1: Variant = mgr2._get_by_id(d_id)
		var pa1: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa1 if comb_pa1 is Dictionary else {}, "pending_attack")
		if pa1.is_empty():
			_fail(failures, "windup_geom: empty pending_attack (depth)")
		elif not pa1.has("effective_pair_file_spacing_equivalent") or not pa1.has("effective_pair_eff_dist"):
			_fail(failures, "windup_geom: depth missing spacing keys")
		elif not bool(pa1.get("depth_polearm_attack", false)):
			_fail(failures, "windup_geom: depth spear should set depth_polearm_attack")
		else:
			var want_eff1: float = _ActionsBuilder.effective_pair_eff_dist(mgr2, depth, en)
			var want_space1: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr2, depth, en)
			if not is_equal_approx(float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1):
				_fail(
					failures,
					"windup_geom: depth eff_dist stamp %.4f vs builder %.4f"
					% [float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1]
				)
			if not is_equal_approx(float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1):
				_fail(
					failures,
					"windup_geom: depth file_spacing_eq stamp %.4f vs builder %.4f"
					% [float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1]
				)
			var want_allow: bool = _ActionsBuilder.depth_polearm_lane_allows_low_targets(mgr2, depth)
			if bool(pa1.get("depth_polearm_allows_low_targets", not want_allow)) != want_allow:
				_fail(
					failures,
					"windup_geom: depth_polearm_allows_low_targets=%s want %s"
					% [str(pa1.get("depth_polearm_allows_low_targets")), str(want_allow)]
				)
			var want_lane: String = "open" if want_allow else "over_shoulder"
			if str(pa1.get("depth_polearm_lane_type", "")) != want_lane:
				_fail(
					failures,
					"windup_geom: depth_polearm_lane_type=%s want %s"
					% [str(pa1.get("depth_polearm_lane_type")), want_lane]
				)
			var w1: Variant = _EntityAccess.get_weapon(depth)
			if w1 != null:
				var want_meas1: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr2, depth, en, w1, want_eff1)
				if not is_equal_approx(float(pa1.get("strike_measure_ratio", -9.0)), want_meas1):
					_fail(
						failures,
						"windup_geom: depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
						% [float(pa1.get("strike_measure_ratio", -9.0)), want_meas1]
					)
	_free_manager(mgr2)

	# 3-wide enemy line: stamped `effective_pair_*` must still match builder (wedge/lane/ZoC path stress).
	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SPEAR"), "player")
	for _i in 3:
		mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	mgr3._recompute_zoc_and_distance()
	var depth3: Dictionary = mgr3.combatants[1]
	var en30: Dictionary = mgr3.combatants[2]
	if not _ActionsBuilder.depth_polearm_lane_open(mgr3, depth3):
		_fail(failures, "windup_geom: 3-file enemy expected depth polearm lane open")
	elif not _ActionsBuilder.can_melee_threaten(mgr3, depth3, en30):
		_fail(failures, "windup_geom: 3-file enemy depth should melee-threaten file-opposed rank-0")
	else:
		var d3_id: int = _EntityAccess.id_int(depth3)
		var e3_id: int = _EntityAccess.id_int(en30)
		_WindUpStarter.start(mgr3, d3_id, e3_id, "spear_thrust")
		var comb_pa3: Variant = mgr3._get_by_id(d3_id)
		var pa3: Dictionary = _EntityAccess.nested_dictionary_read(comb_pa3 if comb_pa3 is Dictionary else {}, "pending_attack")
		if pa3.is_empty():
			_fail(failures, "windup_geom: empty pending_attack (depth 3-file line)")
		elif not bool(pa3.get("depth_polearm_attack", false)):
			_fail(failures, "windup_geom: depth 3-file should set depth_polearm_attack")
		else:
			var want_eff3: float = _ActionsBuilder.effective_pair_eff_dist(mgr3, depth3, en30)
			var want_space3: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr3, depth3, en30)
			if not is_equal_approx(float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3):
				_fail(
					failures,
					"windup_geom: 3-file depth eff_dist stamp %.4f vs builder %.4f"
					% [float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3]
				)
			if not is_equal_approx(float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3):
				_fail(
					failures,
					"windup_geom: 3-file depth file_spacing_eq stamp %.4f vs builder %.4f"
					% [
						float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)),
						want_space3
					]
				)
			var w3: Variant = _EntityAccess.get_weapon(depth3)
			if w3 != null:
				var want_meas3: float = _ActionsBuilder.strike_measure_ratio_for_attack_pair(mgr3, depth3, en30, w3, want_eff3)
				if not is_equal_approx(float(pa3.get("strike_measure_ratio", -9.0)), want_meas3):
					_fail(
						failures,
						"windup_geom: 3-file depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
						% [float(pa3.get("strike_measure_ratio", -9.0)), want_meas3]
					)
	_free_manager(mgr3)


## `AttackResultApplier`: terminal outcomes clear `pending_attack` (defeated / miss / dodge / skip).
static func _run_attack_result_applier_terminal_clears_pending(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	p.state = CombatConstants.STATE_WIND_UP
	p.pending_attack = {"target_id": e_id, "attack_type": "thrust", "intensity": 0.5}
	_AttackResultApplier.apply_result(
		mgr,
		p_id,
		{"action": "defeated", "target_id": e_id}
	)
	if not _EntityAccess.nested_dictionary_read(p, "pending_attack").is_empty():
		_fail(failures, "result_applier: defeated should clear attacker pending_attack")
	if _EntityAccess.state_str(p) != CombatConstants.STATE_WAITING:
		_fail(
			failures,
			"result_applier: defeated attacker should be WAITING got %s" % _EntityAccess.state_str(p)
		)
	_free_manager(mgr)

	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SWORD"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p2: Dictionary = mgr2.combatants[0]
	var e2: Dictionary = mgr2.combatants[1]
	var p2_id: int = _EntityAccess.id_int(p2)
	var e2_id: int = _EntityAccess.id_int(e2)
	p2.state = CombatConstants.STATE_WIND_UP
	p2.pending_attack = {
		"target_id": e2_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high"
	}
	_AttackResultApplier.apply_result(
		mgr2,
		p2_id,
		{"action": "miss", "target_id": e2_id, "recovery_duration": 0.35}
	)
	if not _EntityAccess.nested_dictionary_read(p2, "pending_attack").is_empty():
		_fail(failures, "result_applier: miss should clear attacker pending_attack")
	if str(p2.get("last_move_id", "")) != "thrust":
		_fail(failures, "result_applier: miss should set last_move_id from pending thrust")
	if _EntityAccess.state_str(p2) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: miss attacker should be RECOVERING got %s" % _EntityAccess.state_str(p2)
		)
	_free_manager(mgr2)

	var mgr3: Node = _MgrScript.new()
	mgr3.register(_new_entity("SWORD"), "player")
	mgr3.register(_new_entity("SWORD"), "enemy")
	mgr3.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p3: Dictionary = mgr3.combatants[0]
	var e3: Dictionary = mgr3.combatants[1]
	var p3_id: int = _EntityAccess.id_int(p3)
	var e3_id: int = _EntityAccess.id_int(e3)
	p3.state = CombatConstants.STATE_WIND_UP
	p3.pending_attack = {"target_id": e3_id, "attack_type": "slash", "intensity": 0.5, "effective_attack_line": "left"}
	_AttackResultApplier.apply_result(
		mgr3,
		p3_id,
		{"action": "dodge", "target_id": e3_id, "recovery_duration": 0.4}
	)
	if not _EntityAccess.nested_dictionary_read(p3, "pending_attack").is_empty():
		_fail(failures, "result_applier: dodge should clear attacker pending_attack")
	if _EntityAccess.state_str(p3) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: dodge attacker should be RECOVERING got %s" % _EntityAccess.state_str(p3)
		)
	_free_manager(mgr3)

	var mgr4: Node = _MgrScript.new()
	mgr4.register(_new_entity("SWORD"), "player")
	mgr4.register(_new_entity("SWORD"), "enemy")
	mgr4.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p4: Dictionary = mgr4.combatants[0]
	var e4: Dictionary = mgr4.combatants[1]
	var p4_id: int = _EntityAccess.id_int(p4)
	var e4_id: int = _EntityAccess.id_int(e4)
	p4.state = CombatConstants.STATE_WIND_UP
	p4.pending_attack = {"target_id": e4_id, "attack_type": "thrust", "intensity": 0.5}
	_AttackResultApplier.apply_result(
		mgr4,
		p4_id,
		{"action": "skip", "target_id": e4_id, "recovery_duration": 0.28}
	)
	if not _EntityAccess.nested_dictionary_read(p4, "pending_attack").is_empty():
		_fail(failures, "result_applier: skip+recovery should clear attacker pending_attack")
	if _EntityAccess.state_str(p4) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"result_applier: skip+recovery attacker should be RECOVERING got %s" % _EntityAccess.state_str(p4)
		)
	_free_manager(mgr4)

	var mgr5: Node = _MgrScript.new()
	mgr5.register(_new_entity("SWORD"), "player")
	mgr5.register(_new_entity("SWORD"), "enemy")
	mgr5.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p5: Dictionary = mgr5.combatants[0]
	var e5_id: int = _EntityAccess.id_int(mgr5.combatants[1])
	var p5_id: int = _EntityAccess.id_int(p5)
	p5.state = CombatConstants.STATE_WIND_UP
	p5.pending_attack = {"target_id": e5_id, "attack_type": "slash", "intensity": 0.5}
	_AttackResultApplier.apply_result(mgr5, p5_id, {"action": "skip", "target_id": e5_id, "recovery_duration": 0.0})
	if not _EntityAccess.nested_dictionary_read(p5, "pending_attack").is_empty():
		_fail(failures, "result_applier: skip no-recovery should clear attacker pending_attack")
	if _EntityAccess.state_str(p5) != CombatConstants.STATE_WAITING:
		_fail(
			failures,
			"result_applier: skip no-recovery attacker should be WAITING got %s" % _EntityAccess.state_str(p5)
		)
	_free_manager(mgr5)


## **`AttackResultApplier`**: **`parry_deflect`** → **`action_resolved`** payload includes resolver **`parry_clash_context`** (signal args: defender id, attacker id, **`BattleScene`** slot names reversed).
static func _run_action_resolved_parry_deflect_payload_includes_clash_context(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	var captured: Array = []
	mgr.action_resolved.connect(
		func(first_id: int, second_id: int, res: Dictionary) -> void:
			captured.clear()
			captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
	)
	e["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5}
	var pclash: Dictionary = {"kinematic_delivery": "thrust", "strike_measure_ratio": 1.05, "parry_control": 0.41}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{"action": "parry_deflect", "target_id": p_id, "recovery_duration": 0.45, "parry_clash_context": pclash}
	)
	if captured.is_empty():
		_fail(failures, "parry_resolve_emit: expected action_resolved")
		_free_manager(mgr)
		return
	var slot: Dictionary = captured[0] as Dictionary
	if int(slot.get("first", -99)) != p_id:
		_fail(
			failures,
			"parry_resolve_emit: first signal arg should be defender id %d got %d" % [p_id, int(slot.get("first", -99))]
		)
	if int(slot.get("second", -99)) != e_id:
		_fail(
			failures,
			"parry_resolve_emit: second signal arg should be attacker id %d got %d" % [e_id, int(slot.get("second", -99))]
		)
	var res: Dictionary = slot.get("res", {}) as Dictionary
	if str(res.get("outcome", "")) != "parry_deflect":
		_fail(failures, "parry_resolve_emit: outcome want parry_deflect got %s" % str(res.get("outcome", "")))
	var ctx: Variant = res.get("parry_clash_context", null)
	if not (ctx is Dictionary):
		_fail(failures, "parry_resolve_emit: missing parry_clash_context on resolved payload")
		_free_manager(mgr)
		return
	var cd: Dictionary = ctx as Dictionary
	if str(cd.get("kinematic_delivery", "")) != "thrust":
		_fail(failures, "parry_resolve_emit: clash kinematic_delivery mismatch")
	if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
		_fail(failures, "parry_resolve_emit: strike_measure_ratio mismatch")
	if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
		_fail(failures, "parry_resolve_emit: parry_control mismatch")
	_free_manager(mgr)


## **`AttackResultApplier`**: first **`action_resolved`** on **`parry_partial`** is defender, attacker, payload with **`parry_clash_context`** (nested **`_execute_attack`** may append further rows).
static func _run_action_resolved_parry_partial_payload_includes_clash_context(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	var captured: Array = []
	mgr.action_resolved.connect(
		func(first_id: int, second_id: int, res: Dictionary) -> void:
			captured.append({"first": first_id, "second": second_id, "res": res.duplicate(true)})
	)
	e["pending_attack"] = {"target_id": p_id, "attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5}
	var pclash: Dictionary = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.05,
		"parry_control": 0.41,
		"remaining_ratio": 0.33
	}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
	)
	if captured.is_empty():
		_fail(failures, "parry_partial_resolve_emit: expected at least one action_resolved")
		_free_manager(mgr)
		return
	var slot: Dictionary = captured[0] as Dictionary
	if int(slot.get("first", -99)) != p_id:
		_fail(
			failures,
			"parry_partial_resolve_emit: first signal arg should be defender id %d got %d" % [p_id, int(slot.get("first", -99))]
		)
	if int(slot.get("second", -99)) != e_id:
		_fail(
			failures,
			"parry_partial_resolve_emit: second signal arg should be attacker id %d got %d" % [e_id, int(slot.get("second", -99))]
		)
	var res: Dictionary = slot.get("res", {}) as Dictionary
	if str(res.get("outcome", "")) != "parry_partial":
		_fail(
			failures,
			"parry_partial_resolve_emit: first outcome want parry_partial got %s" % str(res.get("outcome", ""))
		)
	var ctx: Variant = res.get("parry_clash_context", null)
	if not (ctx is Dictionary):
		_fail(failures, "parry_partial_resolve_emit: missing parry_clash_context on first payload")
		_free_manager(mgr)
		return
	var cd: Dictionary = ctx as Dictionary
	if str(cd.get("kinematic_delivery", "")) != "thrust":
		_fail(failures, "parry_partial_resolve_emit: clash kinematic_delivery mismatch")
	if absf(float(cd.get("strike_measure_ratio", 0.0)) - 1.05) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: strike_measure_ratio mismatch")
	if absf(float(cd.get("parry_control", 0.0)) - 0.41) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: parry_control mismatch")
	if absf(float(cd.get("remaining_ratio", 0.0)) - 0.33) > 0.001:
		_fail(failures, "parry_partial_resolve_emit: remaining_ratio mismatch")
	_free_manager(mgr)


## **`AttackResultApplier`**: **`hit`** erases **`parry_clash_context`** / **`defender_guard_line_at_parry`** on the striker (stale calibration after **`parry_partial`** follow-through).
static func _run_hit_clears_attacker_parry_calibration_fields(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	p.state = CombatConstants.STATE_WAITING
	p.pending_attack = {}
	e.state = CombatConstants.STATE_WIND_UP
	e.pending_attack = {
		"target_id": p_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high",
	}
	e["parry_clash_context"] = {"kinematic_delivery": "thrust", "parry_control": 0.5}
	e["defender_guard_line_at_parry"] = "high"
	var rd: Dictionary = {
		"dmg": 2,
		"died": false,
		"part": "chest",
		"outcome": "hit",
		"damage_type": "cut",
		"health_before": 100,
		"health_after": 98,
		"final_cut": 1.0,
		"final_blunt": 1.0,
		"final_bone": 0.0,
		"total_physical": 2.0,
	}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{
			"action": "hit",
			"target_id": p_id,
			"intensity": 0.2,
			"recovery_duration": 0.45,
			"result_dict": rd,
		}
	)
	if e.has("parry_clash_context"):
		_fail(failures, "hit_clear_parry: attacker should not retain parry_clash_context after hit")
	if e.has("defender_guard_line_at_parry"):
		_fail(failures, "hit_clear_parry: attacker should not retain defender_guard_line_at_parry after hit")
	_free_manager(mgr)


## **`AttackResultApplier`**: **`hit`** sets defender **`guard_line`** low and syncs **`guard_zone`** via **`GuardLineUpdater.set_guard_from_line`** (stagger / dropped guard).
static func _run_hit_applier_sets_defender_guard_low_after_hit(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	p.state = CombatConstants.STATE_WAITING
	p.pending_attack = {}
	p["guard_line"] = "high"
	p["guard_zone"] = "head"
	e.state = CombatConstants.STATE_WIND_UP
	e.pending_attack = {
		"target_id": p_id,
		"attack_type": "thrust",
		"intensity": 0.5,
		"effective_attack_line": "high",
	}
	var rd: Dictionary = {
		"dmg": 2,
		"died": false,
		"part": "chest",
		"outcome": "hit",
		"damage_type": "cut",
		"health_before": 100,
		"health_after": 98,
		"final_cut": 1.0,
		"final_blunt": 1.0,
		"final_bone": 0.0,
		"total_physical": 2.0,
	}
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{
			"action": "hit",
			"target_id": p_id,
			"intensity": 0.2,
			"recovery_duration": 0.45,
			"result_dict": rd,
		}
	)
	if str(p.get("guard_line", "")) != "low":
		_fail(
			failures,
			"hit_guard_reaction: defender guard_line want low got %s" % str(p.get("guard_line", ""))
		)
	var want_zone: String = CombatConstants.LINE_TO_DEFAULT_PART.get("low", "")
	if str(p.get("guard_zone", "")) != want_zone:
		_fail(
			failures,
			"hit_guard_reaction: defender guard_zone want %s got %s" % [want_zone, str(p.get("guard_zone", ""))]
		)
	_free_manager(mgr)


## **`parry_partial`**: defender **`parry_was_bind`** / **`parry_against_id`** when alignment ≥ partial threshold and clash **`parry_control`** crosses bind threshold; cleared when misaligned or control low (misaligned path **`erase`**s stale **`parry_was_bind`**).
static func _run_parry_partial_bind_riposte_flags_when_aligned(failures: PackedStringArray) -> void:
	var _apply_partial_bind := func(
		attack_angle_deg: float,
		parry_control: float,
		expect_bind: bool,
		label: String,
		seed_stale_bind: bool = false,
		misaligned_erase_bind_key: bool = false
	) -> void:
		var mgr: Node = _MgrScript.new()
		mgr.register(_new_entity("SWORD"), "player")
		mgr.register(_new_entity("SWORD"), "enemy")
		mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
		var p: Dictionary = mgr.combatants[0]
		var e: Dictionary = mgr.combatants[1]
		var p_id: int = _EntityAccess.id_int(p)
		var e_id: int = _EntityAccess.id_int(e)
		p.state = CombatConstants.STATE_WAITING
		p["guard"] = 1.0
		p["guard_line"] = "high"
		p.pending_attack = {}
		if seed_stale_bind:
			p["parry_was_bind"] = true
			p["parry_against_id"] = e_id
			p["parry_bonus_until"] = 1.0e9
		e.state = CombatConstants.STATE_WIND_UP
		e.pending_attack = {
			"target_id": p_id,
			"attack_type": "thrust",
			"effective_attack_line": "high",
			"attack_angle_deg": attack_angle_deg,
			"intensity": 0.5,
		}
		var pclash: Dictionary = {"parry_control": parry_control, "archetype_id": "stab"}
		_AttackResultApplier.apply_result(
			mgr,
			e_id,
			{"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
		)
		if expect_bind:
			if not bool(p.get("parry_was_bind", false)):
				_fail(
					failures,
					"parry_partial_bind %s: parry_was_bind want true got %s"
					% [label, str(p.get("parry_was_bind", false))]
				)
			if int(p.get("parry_against_id", -99)) != e_id:
				_fail(
					failures,
					"parry_partial_bind %s: parry_against_id want %d got %s"
					% [label, e_id, str(p.get("parry_against_id", -99))]
				)
			if not p.has("parry_bonus_until"):
				_fail(failures, "parry_partial_bind %s: expected parry_bonus_until set" % label)
		else:
			if p.has("parry_against_id"):
				_fail(
					failures,
					"parry_partial_bind %s: expected no parry_against_id got %s"
					% [label, str(p.get("parry_against_id", -99))]
				)
			if p.has("parry_bonus_until"):
				_fail(failures, "parry_partial_bind %s: expected no parry_bonus_until" % label)
			if misaligned_erase_bind_key:
				if p.has("parry_was_bind"):
					_fail(
						failures,
						"parry_partial_bind %s: expected parry_was_bind erased (misaligned / stale clear)"
						% label
					)
			else:
				if not p.has("parry_was_bind") or bool(p["parry_was_bind"]):
					_fail(
						failures,
						"parry_partial_bind %s: want parry_was_bind key false got has=%s val=%s"
						% [label, str(p.has("parry_was_bind")), str(p.get("parry_was_bind", "<absent>"))]
					)
		_free_manager(mgr)

	_apply_partial_bind.call(0.0, 0.9, true, "aligned_high_control", false, false)
	_apply_partial_bind.call(0.0, 0.5, false, "aligned_low_control", false, false)
	_apply_partial_bind.call(90.0, 0.9, false, "misaligned_high_control", false, true)
	_apply_partial_bind.call(90.0, 0.9, false, "misaligned_clears_stale_bind", true, true)


## Tier 3.1: `StrikePhysics.depth_polearm_thrust_closing_factor` — depth lane + stab only.
static func _run_depth_spear_thrust_closing_factor_invariant(failures: PackedStringArray) -> void:
	var f0: float = _StrikePhysics.depth_polearm_thrust_closing_factor({})
	var f_cut: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{"depth_polearm_attack": true, "attack_type": "spear_slash"}
	)
	var f_stab: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{"depth_polearm_attack": true, "attack_type": "spear_thrust"}
	)
	var f_stab_open: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "open",
		}
	)
	var f_stab_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "over_shoulder",
		}
	)
	var f_stab_shoulder_overrides_allows: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "over_shoulder",
			"depth_polearm_allows_low_targets": true,
		}
	)
	var f_stab_empty_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "",
			"depth_polearm_allows_low_targets": false,
		}
	)
	var f_stab_garbage_tight: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "bogus",
			"depth_polearm_allows_low_targets": false,
		}
	)
	var f_stab_open_ignores_allows: float = _StrikePhysics.depth_polearm_thrust_closing_factor(
		{
			"depth_polearm_attack": true,
			"attack_type": "spear_thrust",
			"depth_polearm_lane_type": "open",
			"depth_polearm_allows_low_targets": false,
		}
	)
	if not is_equal_approx(f0, 1.0) or not is_equal_approx(f_cut, 1.0):
		_fail(
			failures,
			"depth_spear_closing: expected 1.0 for empty / non-stab got f0=%.4f f_cut=%.4f" % [f0, f_cut]
		)
	if not is_equal_approx(f_stab, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: stab want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab]
		)
	if not is_equal_approx(f_stab_open, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: stab+open lane want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open]
		)
	if not is_equal_approx(f_stab_tight, 1.0):
		_fail(failures, "depth_spear_closing: stab+tight lane want 1.0 got %.4f" % f_stab_tight)
	if not is_equal_approx(f_stab_shoulder_overrides_allows, 1.0):
		_fail(
			failures,
			"depth_spear_closing: over_shoulder lane id must override allows_low=true got %.4f"
			% f_stab_shoulder_overrides_allows
		)
	if not is_equal_approx(f_stab_empty_tight, 1.0):
		_fail(failures, "depth_spear_closing: empty lane + allows_low false want 1.0 got %.4f" % f_stab_empty_tight)
	if not is_equal_approx(f_stab_garbage_tight, 1.0):
		_fail(failures, "depth_spear_closing: unknown lane + allows_low false want 1.0 got %.4f" % f_stab_garbage_tight)
	if not is_equal_approx(f_stab_open_ignores_allows, CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT):
		_fail(
			failures,
			"depth_spear_closing: explicit open lane should ignore allows_low want %.4f got %.4f"
			% [CombatConstants.DEPTH_SPEAR_THRUST_CLOSING_SPEED_MULT, f_stab_open_ignores_allows]
		)


## Tier 1.6: **`ordered_melee_opponents`** — **`is_melee_file_opposed_priority`** sorts **before** **`hostile_pair_targeting_weight_mult`** (same-file rank-0 line pair ahead of lateral rank-0).
static func _run_ordered_melee_opponents_file_opposed_sort(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e_same: Dictionary = {}
	var e_off: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
			p = c
		elif e_same.is_empty():
			e_same = c
		else:
			e_off = c
	p["file"] = 0
	p["rank"] = 0
	e_same["file"] = 0
	e_same["rank"] = 0
	e_off["file"] = 2
	e_off["rank"] = 0
	for c in mgr.combatants:
		c["gauge"] = 100.0
	mgr._recompute_zoc_and_distance()
	var ordered: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
	if ordered.size() < 2:
		_fail(failures, "melee_order_fo: need >=2 rank0 opponents got %d" % ordered.size())
		_free_manager(mgr)
		return
	var want_id: int = _EntityAccess.id_int(e_same, -998)
	if _EntityAccess.id_int(ordered[0], -999) != want_id:
		var w_same: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_same)
		var w_off: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, e_off)
		var id_list: Array = []
		for x in ordered:
			id_list.append(_EntityAccess.id_int(x, -1))
		_fail(
			failures,
			"melee_order_fo: file-opposed enemy id=%d should sort first got order=%s w_same=%.4f w_off=%.4f"
			% [want_id, str(id_list), w_same, w_off]
		)
	_free_manager(mgr)


## Tier 1.6: `ordered_melee_opponents` tiebreak uses full hostile weight (committed doctrine target first when file-opposed ties).
static func _run_ordered_melee_opponents_commitment_tiebreak(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p: Dictionary = {}
	var e1: Dictionary = {}
	var e2: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
			p = c
		elif e1.is_empty():
			e1 = c
		else:
			e2 = c
	p["file"] = 1
	e1["file"] = 0
	e2["file"] = 2
	mgr._recompute_zoc_and_distance()
	var pid: int = _EntityAccess.id_int(p)
	var e1id: int = _EntityAccess.id_int(e1)
	_TargetScoring.on_combat_commitment(mgr, pid, e1id)
	var ordered: Array = _TargetScoring.ordered_melee_opponents(mgr, p, mgr.combatants, 0)
	if ordered.is_empty():
		_fail(failures, "melee_order_commit: ordered list empty")
	else:
		var first_id: int = _EntityAccess.id_int(ordered[0], -999)
		if first_id != e1id:
			var id_list: Array = []
			for x in ordered:
				id_list.append(_EntityAccess.id_int(x, -1))
			_fail(
				failures,
				"melee_order_commit: expected committed opponent first got first_id=%d want e1=%d order=%s"
				% [first_id, e1id, str(id_list)]
			)
	_free_manager(mgr)


## Tier 4.2: **`AttackWindUpStarter.start`** with **`feint_part`** / **`target_part`** options stamps **`pending_attack`** (incl. **`feint_target_reveal_at_progress`** when the move defines it), sets defender **`guard_zone`** to the telegraph (**`feint_part`** when present). Uses **`CombatRegressionHarness._FEINT_WINDUP_HARNESS_SEED`** for stable upstream wind-up rolls; restores **`_HARNESS_RESTORE_GLOBAL_SEED`** before teardown.
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "left_leg", "feint_part": "head"}
	)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		_fail(failures, "feint_windup: pending target_part want left_leg got %s" % str(pa.get("target_part", "")))
	if str(pa.get("feint_part", "")) != "head":
		_fail(failures, "feint_windup: pending feint_part want head got %s" % str(pa.get("feint_part", "")))
	if str(e.get("guard_zone", "")) != "head":
		_fail(
			failures,
			"feint_windup: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		_fail(
			failures,
			"feint_windup: defender incoming telegraph want head got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	var reveal_expect: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.0))
	if reveal_expect <= 0.0:
		_fail(failures, "feint_windup: oberhau_feint should define feint_target_reveal_at_progress > 0")
	if not pa.has("feint_target_reveal_at_progress"):
		_fail(failures, "feint_windup: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
		_fail(
			failures,
			"feint_windup: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, for stab **`thrust_feint`** on **SWORD** ( **`feint_windup_duration_mult`** stamp + telegraph keys).
static func _run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"thrust_feint",
		{"target_part": "chest", "feint_part": "head"}
	)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("attack_type", "")) != "thrust_feint":
		_fail(
			failures,
			"feint_windup_thrust: pending attack_type want thrust_feint got %s" % str(pa.get("attack_type", ""))
		)
	if str(pa.get("target_part", "")) != "chest":
		_fail(failures, "feint_windup_thrust: pending target_part want chest got %s" % str(pa.get("target_part", "")))
	if str(pa.get("feint_part", "")) != "head":
		_fail(failures, "feint_windup_thrust: pending feint_part want head got %s" % str(pa.get("feint_part", "")))
	if str(pa.get("move_contact_type", "")) != WeaponConstants.ATTACK_TYPE_STAB:
		_fail(
			failures,
			"feint_windup_thrust: move_contact_type want stab got %s" % str(pa.get("move_contact_type", ""))
		)
	if str(e.get("guard_zone", "")) != "head":
		_fail(
			failures,
			"feint_windup_thrust: defender guard_zone telegraph want head got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		_fail(
			failures,
			"feint_windup_thrust: defender incoming telegraph want head got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		_fail(failures, "feint_windup_thrust: thrust_feint should define feint_windup_duration_mult > 1")
	if not pa.has("feint_windup_duration_mult"):
		_fail(failures, "feint_windup_thrust: pending_attack should stamp feint_windup_duration_mult")
	if not is_equal_approx(float(pa.get("feint_windup_duration_mult", 0.0)), mult_expect):
		_fail(
			failures,
			"feint_windup_thrust: feint_windup_duration_mult want %s got %s"
			% [str(mult_expect), str(pa.get("feint_windup_duration_mult", ""))]
		)
	var reveal_expect: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_expect <= 0.0:
		_fail(failures, "feint_windup_thrust: thrust_feint should define feint_target_reveal_at_progress > 0")
	if not pa.has("feint_target_reveal_at_progress"):
		_fail(failures, "feint_windup_thrust: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa.get("feint_target_reveal_at_progress", -1.0)), reveal_expect):
		_fail(
			failures,
			"feint_windup_thrust: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_expect), str(pa.get("feint_target_reveal_at_progress", ""))]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`WeaponConstants`** move **`feint_windup_duration_mult`** on **`is_feint`** cuts extends **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs **`oberhau`** at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`pa["feint_target_reveal_at_progress"]`** when defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_oberhau(failures: PackedStringArray) -> void:
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		_fail(failures, "feint_windup_mult: oberhau_feint should define feint_windup_duration_mult > 1")
	var mgr_o: Node = _MgrScript.new()
	mgr_o.register(_new_entity("SWORD"), "player")
	mgr_o.register(_new_entity("SWORD"), "enemy")
	mgr_o.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var po: Dictionary = mgr_o.combatants[0]
	var eo: Dictionary = mgr_o.combatants[1]
	var po_id: int = _EntityAccess.id_int(po)
	var eo_id: int = _EntityAccess.id_int(eo)
	eo["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_o, po_id, eo_id, "oberhau", {"target_part": "chest"})
	var d_o: float = float(po.get("state_duration", 0.0))
	var mgr_f: Node = _MgrScript.new()
	mgr_f.register(_new_entity("SWORD"), "player")
	mgr_f.register(_new_entity("SWORD"), "enemy")
	mgr_f.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pf: Dictionary = mgr_f.combatants[0]
	var ef: Dictionary = mgr_f.combatants[1]
	var pf_id: int = _EntityAccess.id_int(pf)
	var ef_id: int = _EntityAccess.id_int(ef)
	ef["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_f, pf_id, ef_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	var d_f: float = float(pf.get("state_duration", 0.0))
	var pa_f: Dictionary = _EntityAccess.nested_dictionary_read(pf, "pending_attack")
	if not pa_f.has("feint_windup_duration_mult"):
		_fail(failures, "feint_windup_mult: pending_attack should stamp feint_windup_duration_mult")
	var reveal_f: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_f <= 0.0:
		_fail(failures, "feint_windup_mult: oberhau_feint should define feint_target_reveal_at_progress > 0")
	if not pa_f.has("feint_target_reveal_at_progress"):
		_fail(failures, "feint_windup_mult: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa_f.get("feint_target_reveal_at_progress", -1.0)), reveal_f):
		_fail(
			failures,
			"feint_windup_mult: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_f), str(pa_f.get("feint_target_reveal_at_progress", ""))]
		)
	if not is_equal_approx(float(pa_f.get("feint_windup_duration_mult", 0.0)), mult_expect):
		_fail(
			failures,
			"feint_windup_mult: pa feint_windup_duration_mult want %s got %s" % [str(mult_expect), str(pa_f.get("feint_windup_duration_mult", ""))]
		)
	if not is_equal_approx(float(pa_f.get("wind_up_duration", 0.0)), d_f):
		_fail(
			failures,
			"feint_windup_mult: wind_up_duration should match state_duration got pa=%s state=%s"
			% [str(pa_f.get("wind_up_duration", "")), str(d_f)]
		)
	var want_f: float = d_o * mult_expect
	if absf(d_f - want_f) > 0.0001:
		_fail(
			failures,
			"feint_windup_mult: feint state_duration want ~ d_oberhau*mult got d_f=%s d_o=%s mult=%s"
			% [str(d_f), str(d_o), str(mult_expect)]
		)
	_free_manager_restore_global_rng(mgr_o)
	_free_manager_restore_global_rng(mgr_f)


## Tier 4.2: **`WeaponConstants`** **`thrust_feint`** **`feint_windup_duration_mult`** extends **`AttackWindUpStarter.start`** **`state_duration`** / **`pending_attack.wind_up_duration`** vs honest **`thrust`** at the same global seed; stamps **`pa["feint_windup_duration_mult"]`** and **`feint_target_reveal_at_progress`** when defined.
static func _run_feint_windup_duration_mult_extends_state_duration_vs_thrust(failures: PackedStringArray) -> void:
	var mdef: Dictionary = WeaponConstants.get_move("thrust_feint")
	var mult_expect: float = float(mdef.get("feint_windup_duration_mult", 1.0))
	if mult_expect <= 1.0:
		_fail(failures, "feint_windup_mult_thrust: thrust_feint should define feint_windup_duration_mult > 1")
	var mgr_t: Node = _MgrScript.new()
	mgr_t.register(_new_entity("SWORD"), "player")
	mgr_t.register(_new_entity("SWORD"), "enemy")
	mgr_t.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pt: Dictionary = mgr_t.combatants[0]
	var et: Dictionary = mgr_t.combatants[1]
	var pt_id: int = _EntityAccess.id_int(pt)
	var et_id: int = _EntityAccess.id_int(et)
	et["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_t, pt_id, et_id, "thrust", {"target_part": "chest"})
	var d_t: float = float(pt.get("state_duration", 0.0))
	var mgr_tf: Node = _MgrScript.new()
	mgr_tf.register(_new_entity("SWORD"), "player")
	mgr_tf.register(_new_entity("SWORD"), "enemy")
	mgr_tf.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var ptf: Dictionary = mgr_tf.combatants[0]
	var etf: Dictionary = mgr_tf.combatants[1]
	var ptf_id: int = _EntityAccess.id_int(ptf)
	var etf_id: int = _EntityAccess.id_int(etf)
	etf["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_tf, ptf_id, etf_id, "thrust_feint", {"target_part": "chest", "feint_part": "head"})
	var d_tf: float = float(ptf.get("state_duration", 0.0))
	var pa_tf: Dictionary = _EntityAccess.nested_dictionary_read(ptf, "pending_attack")
	if not pa_tf.has("feint_windup_duration_mult"):
		_fail(failures, "feint_windup_mult_thrust: pending_attack should stamp feint_windup_duration_mult")
	var reveal_tf: float = float(mdef.get("feint_target_reveal_at_progress", 0.0))
	if reveal_tf <= 0.0:
		_fail(failures, "feint_windup_mult_thrust: thrust_feint should define feint_target_reveal_at_progress > 0")
	if not pa_tf.has("feint_target_reveal_at_progress"):
		_fail(failures, "feint_windup_mult_thrust: pending_attack should stamp feint_target_reveal_at_progress")
	if not is_equal_approx(float(pa_tf.get("feint_target_reveal_at_progress", -1.0)), reveal_tf):
		_fail(
			failures,
			"feint_windup_mult_thrust: feint_target_reveal_at_progress want %s got %s"
			% [str(reveal_tf), str(pa_tf.get("feint_target_reveal_at_progress", ""))]
		)
	if not is_equal_approx(float(pa_tf.get("feint_windup_duration_mult", 0.0)), mult_expect):
		_fail(
			failures,
			"feint_windup_mult_thrust: pa feint_windup_duration_mult want %s got %s"
			% [str(mult_expect), str(pa_tf.get("feint_windup_duration_mult", ""))]
		)
	if not is_equal_approx(float(pa_tf.get("wind_up_duration", 0.0)), d_tf):
		_fail(
			failures,
			"feint_windup_mult_thrust: wind_up_duration should match state_duration got pa=%s state=%s"
			% [str(pa_tf.get("wind_up_duration", "")), str(d_tf)]
		)
	var want_tf: float = d_t * mult_expect
	if absf(d_tf - want_tf) > 0.0001:
		_fail(
			failures,
			"feint_windup_mult_thrust: feint state_duration want ~ d_thrust*mult got d_tf=%s d_t=%s mult=%s"
			% [str(d_tf), str(d_t), str(mult_expect)]
		)
	_free_manager_restore_global_rng(mgr_t)
	_free_manager_restore_global_rng(mgr_tf)


## Tier 4.2: **`AttackWindUpStarter.start`** with **`target_part`** only (no **`feint_part`**) stamps **`pending_attack`** and sets defender **`guard_zone`** to **`target_part`** (non-feint **`oberhau`**). Uses **`_FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED`** for stable wind-up rolls.
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
	_WindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "left_leg"})
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
		)
	if pa.has("feint_part") and str(pa.get("feint_part", "")) != "":
		_fail(
			failures,
			"feint_windup_target_only: should not stamp non-empty feint_part got %s" % str(pa.get("feint_part", ""))
		)
	if pa.has("feint_target_reveal_at_progress"):
		_fail(
			failures,
			"feint_windup_target_only: plain oberhau should not stamp feint_target_reveal_at_progress"
		)
	if str(e.get("guard_zone", "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only: defender guard_zone telegraph want left_leg got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only: defender incoming telegraph want left_leg got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, for honest **`thrust`** (no **`feint_target_reveal_at_progress`** on **`pending_attack`**).
static func _run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_TARGET_ONLY_HARNESS_SEED)
	_WindUpStarter.start(mgr, p_id, e_id, "thrust", {"target_part": "left_leg"})
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
	if str(pa.get("target_part", "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only_thrust: pending target_part want left_leg got %s" % str(pa.get("target_part", ""))
		)
	if pa.has("feint_part") and str(pa.get("feint_part", "")) != "":
		_fail(
			failures,
			"feint_windup_target_only_thrust: should not stamp non-empty feint_part got %s" % str(pa.get("feint_part", ""))
		)
	if pa.has("feint_target_reveal_at_progress"):
		_fail(
			failures,
			"feint_windup_target_only_thrust: plain thrust should not stamp feint_target_reveal_at_progress"
		)
	if str(e.get("guard_zone", "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only_thrust: defender guard_zone telegraph want left_leg got %s" % str(e.get("guard_zone", ""))
		)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "left_leg":
		_fail(
			failures,
			"feint_windup_target_only_thrust: defender incoming telegraph want left_leg got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._add_attack_target_part`** for **`is_feint`** moves picks **`feint_part`** ≠ **`target_part`** when at least two targetable parts exist (bounded **`seed(0..4095)`** search on Godot **4.6.stable**). Restores **`_HARNESS_RESTORE_GLOBAL_SEED`** after the scan so **`run_all()`** order stays stable.
static func _run_feint_move_ai_distinct_feint_and_target_parts(failures: PackedStringArray) -> void:
	if not WeaponConstants.is_feint_move("oberhau_feint"):
		_fail(failures, "feint_ai: WeaponConstants.is_feint_move(oberhau_feint) should be true")
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	var found: bool = false
	for s in range(4096):
		seed(s)
		var choice: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
		_AIPicker._add_attack_target_part(choice, mgr, p_id)
		var tp: String = str(choice.get("target_part", ""))
		var fp: String = str(choice.get("feint_part", ""))
		if not tp.is_empty() and not fp.is_empty() and fp != tp:
			found = true
			break
	if not found:
		_fail(
			failures,
			"feint_ai: no seed in 0..4095 produced distinct non-empty feint_part and target_part for oberhau_feint"
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_ai_distinct_feint_and_target_parts`**, for **`thrust_feint`** on **SWORD**.
static func _run_feint_move_ai_distinct_feint_and_target_parts_thrust(failures: PackedStringArray) -> void:
	if not WeaponConstants.is_feint_move("thrust_feint"):
		_fail(failures, "feint_ai_thrust: WeaponConstants.is_feint_move(thrust_feint) should be true")
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	var found: bool = false
	for s in range(4096):
		seed(s)
		var choice: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
		_AIPicker._add_attack_target_part(choice, mgr, p_id)
		var tp: String = str(choice.get("target_part", ""))
		var fp: String = str(choice.get("feint_part", ""))
		if not tp.is_empty() and not fp.is_empty() and fp != tp:
			found = true
			break
	if not found:
		_fail(
			failures,
			"feint_ai_thrust: no seed in 0..4095 produced distinct non-empty feint_part and target_part for thrust_feint"
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — **`oberhau_feint`** vs same-target **`oberhau`** scales by **`CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** (SWORD 1v1 fixture).
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr._recompute_zoc_and_distance()
	## Pin defender readiness to **0** (WAITING **`guard`**); isolates base **`AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT`** vs readiness lerp harness.
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	var enemy: Dictionary = mgr.combatants[1]
	enemy["off_balance_until"] = -1.0
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var read_m: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_listing_w: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
			% [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, for **`thrust_feint`** vs **`thrust`**.
static func _run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr._recompute_zoc_and_distance()
	var enemy: Dictionary = mgr.combatants[1]
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	var read_m: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m * settled_m
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_listing_w_thrust: want feint weight %.6f (plain*mult) got %.6f plain=%.6f mult=%s"
			% [want, w_feint, w_plain, str(CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT)]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: feint listing mult × **`lerpf(1, AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, passive_readiness)`** vs low defender **`guard`** (SWORD 1v1).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.0
	enemy["off_balance_until"] = -1.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_lo: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m_lo: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var want_lo: float = (
		w_plain_lo * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * read_m_lo * settled_m_lo
	)
	if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
		_fail(
			failures,
			"feint_read_list lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
			% [want_lo, w_feint_lo, w_plain_lo]
		)
	enemy["guard"] = 1.0
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_hi: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var settled_m_hi: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var stance_m_hi: float = CombatConstants.get_stance_modifier(
		_EntityAccess.stance_str(mgr.combatants[0]), "ai_feint_listing"
	)
	var want_hi: float = (
		w_plain_hi
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_hi
		* settled_m_hi
		* stance_m_hi
	)
	if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
		_fail(
			failures,
			"feint_read_list hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f"
			% [want_hi, w_feint_hi, w_plain_hi, read_m_hi, stance_m_hi]
		)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		_fail(
			failures,
			"feint_read_list: plain oberhau weight should not depend on defender guard lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	if w_feint_hi <= w_feint_lo + 0.0001:
		_fail(
			failures,
			"feint_read_list: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: same as **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, for **`thrust`** / **`thrust_feint`** (stab **`contact_type`** on readiness lerp).
static func _run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.0
	enemy["off_balance_until"] = -1.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_lo_t: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m_lo_t: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var want_lo: float = (
		w_plain_lo
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_lo_t
		* settled_m_lo_t
	)
	if absf(w_feint_lo - want_lo) > 0.0001 * maxf(1.0, absf(w_plain_lo)):
		_fail(
			failures,
			"feint_read_list_thrust lo: want feint weight %.6f (plain*base) got %.6f plain=%.6f"
			% [want_lo, w_feint_lo, w_plain_lo]
		)
	enemy["guard"] = 1.0
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var read_m_hi_t: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "thrust_feint")
	var settled_m_hi_t: float = _feint_listing_defender_footwork_state_mult_for_target(enemy)
	var stance_m_hi_t: float = CombatConstants.get_stance_modifier(
		_EntityAccess.stance_str(mgr.combatants[0]), "ai_feint_listing"
	)
	var want_hi: float = (
		w_plain_hi
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* read_m_hi_t
		* settled_m_hi_t
		* stance_m_hi_t
	)
	if absf(w_feint_hi - want_hi) > 0.0001 * maxf(1.0, absf(w_plain_hi)):
		_fail(
			failures,
			"feint_read_list_thrust hi: want feint weight %.6f got %.6f plain=%.6f read_m=%.6f stance_m=%.6f"
			% [want_hi, w_feint_hi, w_plain_hi, read_m_hi_t, stance_m_hi_t]
		)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		_fail(
			failures,
			"feint_read_list_thrust: plain thrust weight should not depend on defender guard lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	if w_feint_hi <= w_feint_lo + 0.0001:
		_fail(
			failures,
			"feint_read_list_thrust: want feint_hi > feint_lo got lo=%.6f hi=%.6f" % [w_feint_lo, w_feint_hi]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — LONG **`distance_to[attacker]`** on defender damps readiness lerp vs MID (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG`**).
static func _run_feint_move_listing_spacing_long_dampens_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.55
	mgr._recompute_zoc_and_distance()
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var ct: String = str(mdef.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
	var pr_def: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(enemy), 0.0, 1.0)
	pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct), 0.0, 1.0)
	pr_def = clampf(
		pr_def
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var pr_long: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_l: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long
	)
	var want_ratio: float = read_l / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_l: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_l: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		_fail(
			failures,
			"feint_list_sp_long: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
			% [w_plain_m, w_plain_l]
		)
	elif w_feint_l >= w_feint_m - 1e-9:
		_fail(
			failures,
			"feint_list_sp_long: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
		)
	else:
		var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			_fail(
				failures,
				"feint_list_sp_long: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
			)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — CLOSE **`distance_to[attacker]`** on defender boosts readiness lerp vs MID (**`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE`**).
static func _run_feint_move_listing_spacing_close_boosts_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.55
	mgr._recompute_zoc_and_distance()
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var ct: String = str(mdef.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
	var pr_def: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(enemy), 0.0, 1.0)
	pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct), 0.0, 1.0)
	pr_def = clampf(
		pr_def
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var pr_close: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_c: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_close
	)
	var want_ratio: float = read_c / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_c) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		_fail(
			failures,
			"feint_list_sp_close: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
			% [w_plain_m, w_plain_c]
		)
	elif w_feint_c <= w_feint_m + 1e-9:
		_fail(
			failures,
			"feint_list_sp_close: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
		)
	else:
		var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			_fail(
				failures,
				"feint_list_sp_close: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
			)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — LONG damps vs MID when defender **`STATE_RECOVERING`** (**`READINESS_BY_CAUSE`**, not **`guard`**); same **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`** as WAITING.
static func _run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var ct: String = str(mdef.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
	var pr_def: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(enemy), 0.0, 1.0)
	pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct), 0.0, 1.0)
	pr_def = clampf(
		pr_def
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var pr_long: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_l: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_long
	)
	var want_ratio: float = read_l / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_l: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_l: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_l) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		_fail(
			failures,
			"feint_list_sp_long_recov: plain oberhau should ignore defender distance band m=%.6f l=%.6f"
			% [w_plain_m, w_plain_l]
		)
	elif w_feint_l >= w_feint_m - 1e-9:
		_fail(
			failures,
			"feint_list_sp_long_recov: want feint_LONG < feint_MID got m=%.6f l=%.6f" % [w_feint_m, w_feint_l]
		)
	else:
		var got_ratio: float = (w_feint_l / w_plain_l) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			_fail(
				failures,
				"feint_list_sp_long_recov: ratio want %.6f got %.6f (feint m=%.6f l=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_l, pr_def]
			)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: feint listing — CLOSE boosts vs MID when defender **`STATE_RECOVERING`**; same spacing mults as WAITING harness.
static func _run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var mdef: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var ct: String = str(mdef.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT))
	var pr_def: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(enemy), 0.0, 1.0)
	pr_def = clampf(pr_def * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct), 0.0, 1.0)
	pr_def = clampf(
		pr_def
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var pr_close: float = clampf(
		pr_def * CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var read_m: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_def
	)
	var read_c: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_close
	)
	var want_ratio: float = read_c / read_m
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_m: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_m: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_CLOSE
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_m - w_plain_c) > 0.0002 * maxf(1.0, absf(w_plain_m)):
		_fail(
			failures,
			"feint_list_sp_close_recov: plain oberhau should ignore defender distance band m=%.6f c=%.6f"
			% [w_plain_m, w_plain_c]
		)
	elif w_feint_c <= w_feint_m + 1e-9:
		_fail(
			failures,
			"feint_list_sp_close_recov: want feint_CLOSE > feint_MID got m=%.6f c=%.6f" % [w_feint_m, w_feint_c]
		)
	else:
		var got_ratio: float = (w_feint_c / w_plain_c) / (w_feint_m / w_plain_m)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			_fail(
				failures,
				"feint_list_sp_close_recov: ratio want %.6f got %.6f (feint m=%.6f c=%.6f pr_def=%.6f)"
				% [want_ratio, got_ratio, w_feint_m, w_feint_c, pr_def]
			)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`STATE_RECOVERING`** — feint listing uses **`PassiveParryContext.get_passive_parry_readiness`** × **`READINESS_BY_CAUSE`** (not **`guard`**).
static func _run_feint_move_listing_readiness_recovery_curve_when_defender_recovering(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(enemy)
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	mgr._recompute_zoc_and_distance()
	var pr: float = _PassiveParryCtx.get_passive_parry_readiness(enemy)
	var curve: Array = CombatConstants.READINESS_BY_CAUSE["attack_hit"]
	var want_pr: float = lerpf(curve[0], curve[1], 0.5)
	if not is_equal_approx(pr, want_pr):
		_fail(
			failures,
			"feint_list_recov: passive readiness want %.6f got %.6f" % [want_pr, pr]
		)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var stance_m: float = CombatConstants.get_stance_modifier(
		CombatConstants.STANCE_BALANCED, "ai_feint_listing"
	)
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_feint: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * stance_m
	)
	if absf(w_feint - want_feint) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_list_recov: want feint %.6f got %.6f plain=%.6f target_m=%.6f"
			% [want_feint, w_feint, w_plain, target_m]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: low attacker **`stamina`** dampens feint listing only (**`AI_FEINT_LISTING_STAMINA_*`**); defender **`guard`** **0**, **`balanced`**.
static func _run_feint_move_listing_stamina_low_dampens_feint_weight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * st_stamina
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_list_stam: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f"
			% [want, w_feint, w_plain, st_stamina]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`hold_lane`** doctrine (**`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_list_stam_hold: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f hold=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`probing`** (**`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_list_stam_probe: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f probe=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: low **`stamina`** feint damp (**`(qh)`**) stacks × **`pinch_center`** (**`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**).
static func _run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	mgr._recompute_zoc_and_distance()
	var stamina_ratio: float = clampf(
		_EntityAccess.stamina_float(player) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	var st_stamina: float = lerpf(
		CombatConstants.AI_FEINT_LISTING_STAMINA_LOW_MULT_AT_ZERO,
		1.0,
		stamina_ratio / CombatConstants.AI_FEINT_LISTING_STAMINA_GATE
	)
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want: float = (
		w_plain
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* st_stamina
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
	)
	if absf(w_feint - want) > 0.0001 * maxf(1.0, absf(w_plain)):
		_fail(
			failures,
			"feint_list_stam_pinch: want feint %.6f got %.6f plain=%.6f st_stamina=%.6f pinch=%s"
			% [
				want,
				w_feint,
				w_plain,
				st_stamina,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: short-horizon **`parry_deflect`** memory on **`attacker`** boosts feint-move listing vs that defender (**`(qo)`**).
static func _run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_before: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	_AIPicker.record_opp_parry_deflect_for_feint_listing(mgr, player, e_id)
	var w_after: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_boost: float = (
		w_before * CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT
	)
	if absf(w_after - want_boost) > 0.0001 * maxf(1.0, absf(w_before)):
		_fail(
			failures,
			"feint_list_parry_recent: want feint %.6f got %.6f before=%.6f top=%s"
			% [
				want_boost,
				w_after,
				w_before,
				str(CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_PRESSURE_TOP_MULT),
			]
		)
	var tick_now: int = mgr.get_combat_tick_index()
	player[CombatConstants.COMBATANT_KEY_AI_FEINT_OPP_LAST_PARRY_DEFLECT_TICK] = {
		str(e_id): tick_now - maxi(100, CombatConstants.AI_FEINT_LISTING_OPP_PARRY_DEFLECT_RECENCY_TICKS + 2)
	}
	var w_stale: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_stale - w_before) > 0.0001 * maxf(1.0, absf(w_before)):
		_fail(
			failures,
			"feint_list_parry_stale: want feint %.6f got %.6f before=%.6f"
			% [w_before, w_stale, w_before]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: defender **`off_balance_until`** ( **`PassiveParryContext.is_off_balance`** ) boosts feint-move listing vs that defender (**`(qp)`**).
static func _run_feint_move_listing_defender_off_balance_boosts_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_balanced: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	var w_off: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_off: float = (
		w_balanced
		* CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
		/ CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
	)
	if absf(w_off - want_off) > 0.0001 * maxf(1.0, absf(w_balanced)):
		_fail(
			failures,
			"feint_list_off_balance: want feint %.6f got %.6f settled_base=%.6f"
			% [want_off, w_off, w_balanced]
		)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() - 1.0
	var w_cleared: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_cleared - w_balanced) > 0.0001 * maxf(1.0, absf(w_balanced)):
		_fail(
			failures,
			"feint_list_off_balance_clear: want feint %.6f got %.6f base=%.6f"
			% [w_balanced, w_cleared, w_balanced]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: settled **`STATE_WAITING`** (not off-balance) dampens feint listing (**`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`**); off-balance uses **`AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT`** instead.
static func _run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["off_balance_until"] = -1.0
	var w_plain_settled: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_settled: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	var w_plain_off: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_off: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_settled - w_plain_off) > 0.0002 * maxf(1.0, absf(w_plain_settled)):
		_fail(
			failures,
			"feint_list_settled_fw: plain oberhau should ignore footwork m=%.6f off=%.6f"
			% [w_plain_settled, w_plain_off]
		)
	elif w_feint_settled >= w_feint_off - 1e-9:
		_fail(
			failures,
			"feint_list_settled_fw: want feint_settled < feint_off got settled=%.6f off=%.6f"
			% [w_feint_settled, w_feint_off]
		)
	else:
		var got_ratio: float = (w_feint_settled / w_plain_settled) / (w_feint_off / w_plain_off)
		var want_ratio: float = (
			CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
			/ CombatConstants.AI_FEINT_LISTING_DEFENDER_OFF_BALANCE_MULT
		)
		if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
			_fail(
				failures,
				"feint_list_settled_fw: ratio want %.6f got %.6f (settled=%.6f off=%.6f)"
				% [want_ratio, got_ratio, w_feint_settled, w_feint_off]
			)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`STATE_RECOVERING`** (not off-balance) dampens feint listing (**`AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT`**) vs settled **`STATE_WAITING`** at same **`guard`** (readiness lerp differs; ratio isolates footwork mults).
static func _run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["state"] = CombatConstants.STATE_WAITING
	var w_plain_wait: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_wait: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_duration"] = 2.0
	enemy["state_timer"] = 1.0
	var w_plain_rec: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_rec: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_wait - w_plain_rec) > 0.0002 * maxf(1.0, absf(w_plain_wait)):
		_fail(
			failures,
			"feint_list_recov_fw: plain oberhau should match wait=%.6f rec=%.6f"
			% [w_plain_wait, w_plain_rec]
		)
		_free_manager_restore_global_rng(mgr)
		return
	enemy["state"] = CombatConstants.STATE_WAITING
	var read_wait: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["recovery_cause"] = "attack_hit"
	enemy["state_timer"] = 1.0
	var read_rec: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var got_ratio: float = (w_feint_rec / w_plain_rec) / (w_feint_wait / w_plain_wait)
	var want_ratio: float = (
		(read_rec / read_wait)
		* (
			CombatConstants.AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT
			/ CombatConstants.AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT
		)
	)
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		_fail(
			failures,
			"feint_list_recov_fw: ratio want %.6f got %.6f (wait=%.6f rec=%.6f read_w=%.6f read_r=%.6f)"
			% [want_ratio, got_ratio, w_feint_wait, w_feint_rec, read_wait, read_rec]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`recovery_cause`** selects **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** (inverse of dodge **`defense_footwork_recovering_dodge_mult_for_cause`**); **`attack_miss`** damps listing more than **`attack_hit`** at shared **`guard`** / timer.
static func _run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["state_duration"] = 1.0
	enemy["state_timer"] = 0.25
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["recovery_cause"] = "attack_hit"
	var w_plain_hit: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hit: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["recovery_cause"] = "attack_miss"
	var w_plain_miss: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_miss: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_hit - w_plain_miss) > 0.0002 * maxf(1.0, absf(w_plain_hit)):
		_fail(
			failures,
			"feint_list_cause_fw: plain should match hit=%.6f miss=%.6f" % [w_plain_hit, w_plain_miss]
		)
		_free_manager_restore_global_rng(mgr)
		return
	enemy["recovery_cause"] = "attack_hit"
	var read_hit: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	enemy["recovery_cause"] = "attack_miss"
	var read_miss: float = _feint_listing_read_m_expect_for_move_on_target(enemy, p_id, "oberhau_feint")
	var foot_hit: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_hit")
	var foot_miss: float = CombatConstants.ai_feint_listing_defender_recovering_footwork_mult_for_cause("attack_miss")
	var got_ratio: float = (w_feint_miss / w_plain_miss) / (w_feint_hit / w_plain_hit)
	var want_ratio: float = (read_miss / read_hit) * (foot_miss / foot_hit)
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		_fail(
			failures,
			"feint_list_cause_fw: ratio want %.6f got %.6f foot_hit=%.6f foot_miss=%.6f"
			% [want_ratio, got_ratio, foot_hit, foot_miss]
		)
	elif foot_miss >= foot_hit - 1e-9:
		_fail(
			failures,
			"feint_list_cause_fw: want foot_miss < foot_hit got hit=%.6f miss=%.6f"
			% [foot_hit, foot_miss]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: on **`STATE_RECOVERING`**, feint-listing **`read_m`** (spacing in **`pr_def`**) × **`ai_feint_listing_defender_recovering_footwork_mult_for_cause`** stack orthogonally — **`attack_hit`** at MID vs **`attack_miss`** at LONG.
static func _run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.55
	enemy["off_balance_until"] = -1.0
	enemy["state"] = CombatConstants.STATE_RECOVERING
	enemy["state_duration"] = 1.0
	enemy["state_timer"] = 0.25
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["recovery_cause"] = "attack_hit"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var w_plain_hit_mid: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hit_mid: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["recovery_cause"] = "attack_miss"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var w_plain_miss_long: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_miss_long: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_hit_mid - w_plain_miss_long) > 0.0002 * maxf(1.0, absf(w_plain_hit_mid)):
		_fail(
			failures,
			"feint_list_recov_stack: plain should match hit_mid=%.6f miss_long=%.6f"
			% [w_plain_hit_mid, w_plain_miss_long]
		)
		_free_manager_restore_global_rng(mgr)
		return
	enemy["recovery_cause"] = "attack_hit"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_MID
	var target_hit_mid: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	enemy["recovery_cause"] = "attack_miss"
	_EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[p_id] = CombatConstants.DISTANCE_LONG
	var target_miss_long: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var got_ratio: float = (w_feint_miss_long / w_plain_miss_long) / (w_feint_hit_mid / w_plain_hit_mid)
	var want_ratio: float = target_miss_long / target_hit_mid
	if absf(got_ratio - want_ratio) > 0.0005 * maxf(1.0, absf(want_ratio)):
		_fail(
			failures,
			"feint_list_recov_stack: ratio want %.6f got %.6f t_hit_mid=%.6f t_miss_long=%.6f"
			% [want_ratio, got_ratio, target_hit_mid, target_miss_long]
		)
	_free_manager_restore_global_rng(mgr)


## Harness helper: set incoming attacker wind-up progress for **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** tests.
static func _harness_counter_tempo_set_incoming_progress(
	mgr: Node, attacker_id: int, fraction: float
) -> void:
	var atk: Dictionary = mgr._get_by_id(attacker_id)
	if atk == null:
		return
	var dur: float = float(atk.get("state_duration", 0.0))
	if dur <= 0.0:
		atk["state_duration"] = 1.0
		dur = 1.0
	atk["state_timer"] = clampf(fraction, 0.0, 1.0) * dur


## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.
static func _run_counter_tempo_window_opens_on_incoming_wind_up(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	mgr.combat_clock = 1.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau", {"target_part": "chest"})
	var until: float = float(def.get(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL, -1.0))
	var want_until: float = 1.0 + float(atk.get("state_duration", 0.0)) * CombatConstants.COUNTER_TEMPO_WINDOW_FRACTION
	if absf(until - want_until) > 0.0002:
		_fail(
			failures,
			"counter_tempo_window: until want %.4f got %.4f dur=%.4f"
			% [want_until, until, float(atk.get("state_duration", 0.0))]
		)
	if _CounterTempo.incoming_attacker_id(mgr, def_id) != atk_id:
		_fail(failures, "counter_tempo_window: incoming attacker id mismatch")
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 counter-tempo: **`AvailableActionsBuilder`** lists melee-only **`counter_tempo`** actions when window open.
static func _run_counter_tempo_lists_melee_actions_when_window_open(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + float(atk.get("state_duration", 0.0)),
		"data": {}
	})
	var actions: Array = _ActionsBuilder.build(mgr, def_id)
	if actions.is_empty():
		_fail(failures, "counter_tempo_list: expected counter actions")
		_free_manager_restore_global_rng(mgr)
		return
	var saw_counter: bool = false
	var saw_close: bool = false
	var saw_focus: bool = false
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if bool(a.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			saw_counter = true
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			saw_close = true
		if CombatConstants.is_focus_line_move(mid):
			saw_focus = true
	if not saw_counter:
		_fail(failures, "counter_tempo_list: no action flagged counter_tempo")
	if saw_close:
		_fail(failures, "counter_tempo_list: close should be filtered out")
	if saw_focus:
		_fail(failures, "counter_tempo_list: focus_line should be filtered out")
	_free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_spend_gauge_subtracts_cost(failures: PackedStringArray) -> void:
	var c: Dictionary = {"gauge": 60.0}
	_CounterTempo.spend_gauge(c)
	if absf(_EntityAccess.gauge_float(c) - 10.0) > 0.001:
		_fail(
			failures,
			"counter_tempo_spend: want gauge 10 got %.4f" % _EntityAccess.gauge_float(c)
		)


## Tier 4.2 counter-tempo: counter **`EVENT_MELEE_ATTACK`** resolves before deferred incoming melee.
static func _run_counter_tempo_defers_incoming_melee_until_after_counter_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	mgr.combat_clock = 0.0
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	var incoming_at: float = mgr.combat_clock + float(atk.get("state_duration", 0.0))
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": incoming_at,
		"data": {}
	})
	mgr.resolve_action(
		def_id,
		atk_id,
		"oberhau",
		{CombatConstants.ACTION_KEY_COUNTER_TEMPO: true, "target_part": "chest"}
	)
	var counter_at: float = _EventScheduler.get_pending_melee_attack_resolve_at(mgr, def_id)
	var incoming_at1: float = _EventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id)
	var counter_end: float = mgr.combat_clock + float(def.get("state_duration", 0.0))
	if counter_at < 0.0:
		_fail(failures, "counter_tempo_defer: counter melee not scheduled")
	if incoming_at1 < counter_end + CombatConstants.COUNTER_TEMPO_INCOMING_DEFER_AFTER_COUNTER_S - 0.0001:
		_fail(
			failures,
			"counter_tempo_defer: incoming %.4f should be >= %.4f counter_at=%.4f"
			% [incoming_at1, counter_end, counter_at]
		)
	if counter_at >= incoming_at1:
		_fail(
			failures,
			"counter_tempo_defer: counter should resolve before incoming got c=%.4f in=%.4f"
			% [counter_at, incoming_at1]
		)
	_free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_abort_cancels_pending_incoming_melee(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_EventScheduler.schedule_event(mgr, {
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + 1.0,
		"data": {}
	})
	_CounterTempo.abort_attacker_wind_up(mgr, atk_id)
	if _EventScheduler.get_pending_melee_attack_resolve_at(mgr, atk_id) >= 0.0:
		_fail(failures, "counter_tempo_abort: incoming melee should be cancelled")
	if _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP:
		_fail(failures, "counter_tempo_abort: attacker should not remain in wind_up")
	if def.has(CombatConstants.COMBATANT_KEY_COUNTER_WINDOW_UNTIL):
		_fail(failures, "counter_tempo_abort: defender window should clear")
	_free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_wind_up_stamps_pa_and_shortens_duration(failures: PackedStringArray) -> void:
	var mgr_n: Node = _MgrScript.new()
	mgr_n.register(_new_entity("SWORD"), "player")
	mgr_n.register(_new_entity("SWORD"), "enemy")
	mgr_n.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pn: Dictionary = mgr_n.combatants[0]
	var en: Dictionary = mgr_n.combatants[1]
	var pn_id: int = _EntityAccess.id_int(pn)
	var en_id: int = _EntityAccess.id_int(en)
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_n, pn_id, en_id, "oberhau", {"target_part": "chest"})
	var d_plain: float = float(pn.get("state_duration", 0.0))
	var mgr_c: Node = _MgrScript.new()
	mgr_c.register(_new_entity("SWORD"), "player")
	mgr_c.register(_new_entity("SWORD"), "enemy")
	mgr_c.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var pc: Dictionary = mgr_c.combatants[0]
	var ec: Dictionary = mgr_c.combatants[1]
	var pc_id: int = _EntityAccess.id_int(pc)
	var ec_id: int = _EntityAccess.id_int(ec)
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr_c,
		pc_id,
		ec_id,
		"oberhau",
		{"target_part": "chest", CombatConstants.ACTION_KEY_COUNTER_TEMPO: true}
	)
	var d_counter: float = float(pc.get("state_duration", 0.0))
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(pc, "pending_attack")
	if not pa.get(CombatConstants.PA_KEY_COUNTER_TEMPO, false):
		_fail(failures, "counter_tempo_windup: pa should stamp counter_tempo")
	var want_c: float = d_plain * CombatConstants.COUNTER_TEMPO_WINDUP_MULT
	if absf(d_counter - want_c) > 0.0002:
		_fail(
			failures,
			"counter_tempo_windup: duration want %.4f got %.4f plain=%.4f"
			% [want_c, d_counter, d_plain]
		)
	_free_manager_restore_global_rng(mgr_n)
	_free_manager_restore_global_rng(mgr_c)


## Tier 4.2 counter-tempo AI: flagged actions × **`AI_COUNTER_TEMPO_*`**; plain **>** feint on incoming target during window.
static func _run_counter_tempo_ai_listing_boosts_counter_and_prefers_plain_over_feint(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	var a_plain: Dictionary = {
		"move_id": "oberhau",
		"target_id": atk_id,
		CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
	}
	var a_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": atk_id,
		CombatConstants.ACTION_KEY_COUNTER_TEMPO: true,
	}
	var w_plain: float = _AIPicker._get_action_weight(a_plain, def_id, mgr, true)
	var w_feint: float = _AIPicker._get_action_weight(a_feint, def_id, mgr, true)
	var base_mult: float = (
		CombatConstants.AI_COUNTER_TEMPO_LISTING_WEIGHT_MULT
		* CombatConstants.AI_COUNTER_TEMPO_INCOMING_TARGET_MULT
	)
	if w_plain < w_feint:
		_fail(
			failures,
			"counter_tempo_ai: plain should beat feint got plain=%.6f feint=%.6f" % [w_plain, w_feint]
		)
	var a_no_flag: Dictionary = {"move_id": "oberhau", "target_id": atk_id}
	var w_no_flag: float = _AIPicker._get_action_weight(a_no_flag, def_id, mgr, true)
	if w_plain <= w_no_flag * base_mult * 0.99:
		_fail(
			failures,
			"counter_tempo_ai: counter flag should boost vs plain listing got counter=%.6f no_flag=%.6f want>%f"
			% [w_plain, w_no_flag, w_no_flag * base_mult * 0.99]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 Approach B: **`COUNTER_TEMPO_MIN_INCOMING_WINDUP_PROGRESS`** blocks **`can_act`** until incoming wind-up is far enough along.
static func _run_counter_tempo_progress_gate_blocks_can_act_until_half_wind_up(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	if _CounterTempo.can_act(mgr, def):
		_fail(failures, "counter_tempo_gate: can_act should be false at 20% wind-up")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.49)
	if _CounterTempo.can_act(mgr, def):
		_fail(failures, "counter_tempo_gate: can_act should be false at 49% wind-up")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.51)
	if not _CounterTempo.can_act(mgr, def):
		_fail(failures, "counter_tempo_gate: can_act should be true at 51% wind-up")
	if _ActionsBuilder.build(mgr, def_id).is_empty():
		_fail(failures, "counter_tempo_gate: build should list counter actions at 51%")
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CounterTempo.process_waiting`** schedules ready once progress gate opens (not at wind-up start).
static func _run_counter_tempo_process_waiting_schedules_ready_when_progress_gate_met(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.1)
	if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		_fail(failures, "counter_tempo_wait: should not signal ready at 10% wind-up")
	_CounterTempo.process_waiting(mgr, def)
	if bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		_fail(failures, "counter_tempo_wait: process_waiting should not signal at 10%")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	_CounterTempo.process_waiting(mgr, def)
	if not bool(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_READY_SIGNALED, false)):
		_fail(failures, "counter_tempo_wait: should signal ready after 55% wind-up")
	_free_manager_restore_global_rng(mgr)


static func _run_counter_tempo_ui_hint_winding_then_ready(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 60.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.2)
	_CounterTempo.process_waiting(mgr, def)
	if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_winding":
		_fail(
			failures,
			"counter_tempo_ui: want counter_winding got %s"
			% str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
		)
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.6)
	_CounterTempo.process_waiting(mgr, def)
	if str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, "")) != "counter_ready":
		_fail(
			failures,
			"counter_tempo_ui: want counter_ready got %s"
			% str(def.get(CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT, ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 riposte chain: **`grant_riposte_chain`** after deflect → next wind-up vs that attacker × **`RIPOSTE_CHAIN_WINDUP_MULT`**.
static func _run_riposte_chain_after_parry_deflect_shortens_wind_up_vs_plain(
	failures: PackedStringArray
) -> void:
	var mgr_p: Node = _MgrScript.new()
	mgr_p.register(_new_entity("SWORD"), "player")
	mgr_p.register(_new_entity("SWORD"), "enemy")
	mgr_p.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def_p: Dictionary = mgr_p.combatants[0]
	var atk_p: Dictionary = mgr_p.combatants[1]
	var def_p_id: int = _EntityAccess.id_int(def_p)
	var atk_p_id: int = _EntityAccess.id_int(atk_p)
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_p, def_p_id, atk_p_id, "oberhau", {"target_part": "chest"})
	var d_plain: float = float(def_p.get("state_duration", 0.0))
	var mgr_r: Node = _MgrScript.new()
	mgr_r.register(_new_entity("SWORD"), "player")
	mgr_r.register(_new_entity("SWORD"), "enemy")
	mgr_r.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def_r: Dictionary = mgr_r.combatants[0]
	var atk_r: Dictionary = mgr_r.combatants[1]
	var def_r_id: int = _EntityAccess.id_int(def_r)
	var atk_r_id: int = _EntityAccess.id_int(atk_r)
	_CounterTempo.grant_riposte_chain(mgr_r, def_r, atk_r_id)
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(mgr_r, def_r_id, atk_r_id, "oberhau", {"target_part": "chest"})
	var d_rip: float = float(def_r.get("state_duration", 0.0))
	var pa_r: Dictionary = _EntityAccess.nested_dictionary_read(def_r, "pending_attack")
	if not pa_r.get(CombatConstants.PA_KEY_RIPOSTE_CHAIN, false):
		_fail(failures, "riposte_chain: pending_attack should stamp riposte_chain")
	var want_r: float = d_plain * CombatConstants.RIPOSTE_CHAIN_WINDUP_MULT
	if absf(d_rip - want_r) > 0.0002:
		_fail(
			failures,
			"riposte_chain: duration want %.4f got %.4f plain=%.4f"
			% [want_r, d_rip, d_plain]
		)
	if def_r.has(CombatConstants.COMBATANT_KEY_RIPOSTE_CHAIN_UNTIL):
		_fail(failures, "riposte_chain: riposte window should be consumed after wind-up start")
	_free_manager_restore_global_rng(mgr_p)
	_free_manager_restore_global_rng(mgr_r)


## Tier 4.3: salience — telegraph part implies wind-up targeted.
static func _run_attention_being_wind_up_targeted_when_telegraph_set(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	if not _Attention.is_being_wind_up_targeted(mgr, def_id):
		_fail(failures, "attention_wind_up_targeted: expected true when telegraph set")
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: counter salience tracks **`CounterTempo.can_act`**.
static func _run_attention_counter_tempo_salience_matches_can_act(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(atk)
	var def_id: int = _EntityAccess.id_int(def)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	var can: bool = _CounterTempo.can_act(mgr, def)
	var sal: bool = _Attention.has_actionable_counter_tempo(mgr, def)
	if sal != can:
		_fail(failures, "attention_counter_salience: want %s got %s" % [str(can), str(sal)])
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: peril + incoming telegraph stack **`attention_load`**.
static func _run_attention_load_stacks_peril_and_incoming(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var atk: Dictionary = mgr.combatants[2]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var atk_id: int = _EntityAccess.id_int(atk)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
	_WindUpStarter.start(mgr, atk_id, medic_id, "oberhau")
	_Attention.refresh_salience(mgr, medic_id)
	var load: float = _Attention.get_attention_load(medic)
	var want_min: float = (
		CombatConstants.ATTENTION_LOAD_TELEGRAPH_WEIGHT
		+ CombatConstants.ATTENTION_LOAD_PERIL_WEIGHT
	) * 0.99
	if load < want_min:
		_fail(
			failures,
			"attention_load_stack: want load >= %.4f got %.4f" % [want_min, load]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: wrong-line focus dampens feint read-through line mult vs correct-line focus.
static func _run_focus_intensity_scales_feint_readthrough_and_guard_zone(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {
		"guard_zone": "head",
		"guard": 0.95,
		"stance": CombatConstants.STANCE_BALANCED,
		"state": CombatConstants.STATE_WAITING,
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
	}
	var pa: Dictionary = {"feint_part": "head", "target_part": "chest", "attack_type": "oberhau_feint"}
	var wrong_m: float = _Attention.focus_line_mult_for_feint(def, pa)
	_Attention.set_focus(def, "chest")
	var right_m: float = _Attention.focus_line_mult_for_feint(def, pa)
	if wrong_m >= right_m:
		_fail(
			failures,
			"focus_line_mult: wrong %.4f should be < correct %.4f" % [wrong_m, right_m]
		)
	if absf(wrong_m - CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT) > 0.0001:
		_fail(failures, "focus_line_mult wrong: want %.4f got %.4f" % [CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT, wrong_m])


## Tier 4.3: high **`attention_load`** reduces **`focus_effective`**.
static func _run_attention_load_dampens_focus_effective_readiness(failures: PackedStringArray) -> void:
	var c: Dictionary = {CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0}
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 0.0
	var fe_clear: float = _Attention.focus_effective(c)
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = 1.0
	var fe_load: float = _Attention.focus_effective(c)
	var want_load: float = 1.0 - CombatConstants.ATTENTION_LOAD_FOCUS_PENALTY
	if absf(fe_clear - 1.0) > 0.0001:
		_fail(failures, "focus_effective clear: want 1.0 got %.4f" % fe_clear)
	if absf(fe_load - want_load) > 0.0001:
		_fail(failures, "focus_effective load: want %.4f got %.4f" % [want_load, fe_load])


## Tier 4.3: mental stack L1 picks medical when ally in peril.
static func _run_mental_stack_medical_overrides_attack(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var actions: Array = [
		{"move_id": "oberhau", "target_id": _EntityAccess.id_int(mgr.combatants[2])},
		{
			"move_id": "apply_direct_pressure",
			"target_id": ally_id,
			"target_part": "chest",
		},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	if picked.is_empty():
		_fail(failures, "mental_stack_medical: expected stack pick")
		_free_manager_restore_global_rng(mgr)
		return
	if not mgr._is_medical_move(str(picked.get("move_id", ""))):
		_fail(
			failures,
			"mental_stack_medical: want medical move got %s" % str(picked.get("move_id", ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: incoming wind-up restricts picks to counter or melee vs attacker.
static func _run_mental_stack_incoming_windup_prefers_defense(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	var actions: Array = [
		{"move_id": "oberhau", "target_id": atk_id},
		{"move_id": "wait"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, def_id, mgr)
	if picked.is_empty():
		_fail(failures, "mental_stack_incoming: expected stack pick")
		_free_manager_restore_global_rng(mgr)
		return
	var tid: int = int(picked.get("target_id", -1))
	if bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
		pass
	elif tid != atk_id:
		_fail(
			failures,
			"mental_stack_incoming: pick should target incoming attacker %d got target %d move %s"
			% [atk_id, tid, str(picked.get("move_id", ""))]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: counter window open → stack prefers counter-tempo listing.
static func _run_mental_stack_counter_over_plain_attack_when_window_open(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var def: Dictionary = mgr.combatants[0]
	var atk: Dictionary = mgr.combatants[1]
	var def_id: int = _EntityAccess.id_int(def)
	var atk_id: int = _EntityAccess.id_int(atk)
	def["gauge"] = 55.0
	_WindUpStarter.start(mgr, atk_id, def_id, "oberhau")
	_harness_counter_tempo_set_incoming_progress(mgr, atk_id, 0.55)
	mgr._schedule_event({
		"type": CombatConstants.EVENT_MELEE_ATTACK,
		"combatant_id": atk_id,
		"resolve_at": mgr.combat_clock + float(atk.get("state_duration", 0.0)),
		"data": {},
	})
	var actions: Array = _ActionsBuilder.build(mgr, def_id)
	var saw_counter: bool = false
	for raw in actions:
		if typeof(raw) == TYPE_DICTIONARY and bool((raw as Dictionary).get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
			saw_counter = true
			break
	if not saw_counter:
		_fail(failures, "mental_stack_counter: expected counter_tempo in action list")
		_free_manager_restore_global_rng(mgr)
		return
	var picked: Dictionary = _MentalStack.try_pick(actions, def_id, mgr)
	if picked.is_empty():
		_fail(failures, "mental_stack_counter: expected stack pick")
		_free_manager_restore_global_rng(mgr)
		return
	if not bool(picked.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false)):
		_fail(
			failures,
			"mental_stack_counter: want counter_tempo action got %s" % str(picked.get("move_id", ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: no salience → **`try_pick`** empty; attack weights unchanged with stack off.
static func _run_mental_stack_attack_layer_matches_legacy_weights(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var a: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var actions: Array = [a]
	var stacked: Dictionary = _MentalStack.try_pick(actions, p_id, mgr)
	if not stacked.is_empty():
		_fail(failures, "mental_stack_legacy: try_pick should be empty without salience")
	var w: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(false)
	var stacked_off: Dictionary = _MentalStack.try_pick(actions, p_id, mgr)
	var w_off: float = _AIPicker._get_action_weight(a, p_id, mgr, true)
	CombatConstants.set_feature_mental_stack_ai_load(true)
	if not stacked_off.is_empty():
		_fail(failures, "mental_stack_legacy: try_pick off should stay empty")
	if absf(w - w_off) > 0.0001 * maxf(1.0, absf(w)):
		_fail(failures, "mental_stack_legacy: weight changed %.6f vs %.6f" % [w, w_off])
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: repeated high-line attacks raise yomi feint mult on that line.
static func _run_yomi_guard_tendency_boosts_feint_after_repeated_high(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 7
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	var m0: float = _Attention.yomi_feint_listing_mult(def, atk_id, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	var m1: float = _Attention.yomi_feint_listing_mult(def, atk_id, "head")
	if m1 <= m0 or m0 <= 1.0:
		_fail(
			failures,
			"yomi_feint: mult should rise above 1.0 got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.3 UI: **`format_attention_ui_hint`** includes telegraph + focus when incoming.
static func _run_attention_ui_hint_formats_when_telegraph_set(failures: PackedStringArray) -> void:
	var def: Dictionary = {
		"guard_zone": "head",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
		CombatConstants.COMBATANT_KEY_ATTENTION_LOAD: 0.2,
	}
	var hint: String = _Attention.format_attention_ui_hint(def)
	if not hint.contains("Tel head"):
		_fail(failures, "attention_ui_hint: want Tel head in '%s'" % hint)
	if not hint.contains("Focus head"):
		_fail(failures, "attention_ui_hint: want Focus head in '%s'" % hint)
	if not hint.contains("Load"):
		_fail(failures, "attention_ui_hint: want Load segment in '%s'" % hint)


## Tier 4.3 UI: **`refresh_for_waiting_tick`** stamps **`COMBATANT_KEY_ATTENTION_UI_HINT`**.
static func _run_attention_refresh_waiting_tick_stamps_ui_hint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	_WindUpStarter.start(mgr, _EntityAccess.id_int(atk), _EntityAccess.id_int(def), "oberhau_feint", {"target_part": "chest", "feint_part": "head"})
	_StateHandlers.process_waiting(mgr, def, 0.05)
	var hint: String = str(def.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, ""))
	if hint.is_empty():
		_fail(failures, "attention_ui_refresh: expected non-empty attention_ui_hint")
	_WindUpStarter.clear_incoming_attack_telegraph_from_pa(
		mgr, _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	)
	if def.has(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT):
		_fail(failures, "attention_ui_refresh: hint should clear when telegraph cleared")
	_free_manager_restore_global_rng(mgr)


## Tier 4.3: yomi habit line sets AI **`focus_part`** on drift.
static func _run_yomi_focus_drift_sets_habitual_part_on_ai(failures: PackedStringArray) -> void:
	var def: Dictionary = {"side": "enemy", "is_party_leader": false}
	var atk_id: int = 11
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.apply_yomi_focus_drift(null, def, atk_id)
	if _Attention.get_focus_part(def) != "head":
		_fail(
			failures,
			"yomi_focus_drift: want focus head got %s" % _Attention.get_focus_part(def)
		)


## Tier 4.3: mismatched feint telegraph line keeps habitual focus (not bait part).
static func _run_yomi_focus_drift_keeps_habit_when_telegraph_line_mismatches(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {
		"side": "enemy",
		"is_party_leader": false,
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "left_arm",
	}
	var atk_id: int = 12
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.record_attack_toward_defender(null, atk_id, def, "head")
	_Attention.apply_yomi_focus_drift(null, def, atk_id)
	if _Attention.get_focus_part(def) != "head":
		_fail(
			failures,
			"yomi_focus_drift_mismatch: want habit head got %s" % _Attention.get_focus_part(def)
		)


## Tier 4.3: explicit guard move updates **`focus_part`** with **`guard_zone`**.
static func _run_guard_from_move_syncs_focus_part_with_guard_line(failures: PackedStringArray) -> void:
	var c: Dictionary = {
		"guard_line": CombatConstants.GUARD_DEFAULT,
		"guard_zone": "head",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "chest",
	}
	_GuardLineUpdater.set_guard_from_line(c, "low")
	if str(c.get("guard_zone", "")) != "left_leg":
		_fail(failures, "guard_focus_sync: want guard_zone left_leg got %s" % str(c.get("guard_zone")))
	if _Attention.get_focus_part(c) != "left_leg":
		_fail(
			failures,
			"guard_focus_sync: want focus left_leg got %s" % _Attention.get_focus_part(c)
		)


## Tier 4.3: mental stack stamps **`COMBATANT_KEY_MENTAL_STACK_LAYER`** on layer pick.
static func _run_mental_stack_stamps_layer_on_medical_pick(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
	var medic: Dictionary = mgr.combatants[0]
	var ally: Dictionary = mgr.combatants[1]
	var medic_id: int = _EntityAccess.id_int(medic)
	var ally_id: int = _EntityAccess.id_int(ally)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		ally_ent.blood_volume = 30.0
	mgr.medical_phase = true
	mgr.medical_phase_winner = "player"
	var actions: Array = [
		{"move_id": "oberhau", "target_id": _EntityAccess.id_int(mgr.combatants[2])},
		{"move_id": "apply_direct_pressure", "target_id": ally_id, "target_part": "chest"},
	]
	var picked: Dictionary = _MentalStack.try_pick(actions, medic_id, mgr)
	if picked.is_empty():
		_fail(failures, "mental_stack_layer: expected stack pick")
		_free_manager_restore_global_rng(mgr)
		return
	if str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "")) != "medical":
		_fail(
			failures,
			"mental_stack_layer: want medical got %s"
			% str(medic.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3.7: focus-line moves listed when combat attention is on.
static func _run_focus_line_actions_listed_when_attention_enabled(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["state"] = CombatConstants.STATE_WAITING
	player["gauge"] = 100.0
	var actions: Array = _ActionsBuilder.build(mgr, pid)
	var found: int = 0
	for raw in actions:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if CombatConstants.is_focus_line_move(str(a.get("move_id", ""))):
			found += 1
	if found != CombatConstants.FOCUS_LINE_MOVE_IDS.size():
		_fail(failures, "focus_line_list: want %d focus moves got %d" % [CombatConstants.FOCUS_LINE_MOVE_IDS.size(), found])
	_free_manager_restore_global_rng(mgr)


## Tier 4.3.7: **`resolve_action`** on **`focus_high`** sets guard + focus.
static func _run_focus_line_resolve_sets_guard_and_focus(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["state"] = CombatConstants.STATE_WAITING
	player["gauge"] = 100.0
	player["guard_line"] = "low"
	player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
	mgr.resolve_action(pid, pid, CombatConstants.MOVE_ID_FOCUS_HIGH, {})
	if str(player.get("guard_line", "")) != "high":
		_fail(failures, "focus_line_resolve: want guard_line high got %s" % str(player.get("guard_line")))
	if _Attention.get_focus_part(player) != "head":
		_fail(
			failures,
			"focus_line_resolve: want focus head got %s" % _Attention.get_focus_part(player)
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3.7: party lead weights telegraph-matching focus line above other focus lines.
static func _run_focus_line_party_leader_prefers_telegraph_match(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var pid: int = _EntityAccess.id_int(player)
	player["is_party_leader"] = true
	player["guard_line"] = "low"
	player[CombatConstants.COMBATANT_KEY_FOCUS_PART] = "left_leg"
	player[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
	var w_match: float = _AIPicker._get_action_weight(
		{"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
	)
	var w_other: float = _AIPicker._get_action_weight(
		{"move_id": CombatConstants.MOVE_ID_FOCUS_LOW, "target_id": pid}, pid, mgr, true
	)
	if w_match <= w_other:
		_fail(
			failures,
			"focus_line_leader: telegraph match weight %.4f should exceed other line %.4f"
			% [w_match, w_other]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.3.8: yomi **`parry_deflect`** raises defender reported readiness vs that attacker.
static func _run_yomi_defense_readiness_mult_boosts_after_parry_deflect(
	failures: PackedStringArray
) -> void:
	var def: Dictionary = {}
	var atk_id: int = 14
	var m0: float = _Attention.yomi_defense_readiness_mult(def, atk_id)
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m1: float = _Attention.yomi_defense_readiness_mult(def, atk_id)
	if m1 <= m0 or m0 != 1.0:
		_fail(
			failures,
			"yomi_defense_readiness: want rise from 1.0 got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.4: wind-up stamps per-line **`position_angle_offset_deg`** on attacker.
static func _run_footwork_attack_step_offset_stamped_on_windup(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var off: float = float(atk.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(off - CombatConstants.position_angle_offset_deg_for_attack_line("left")) > 0.01:
		_fail(failures, "footwork_windup: want left-line offset got %.2f" % off)


## Tier 4.4: offset rotates reported attack angle for parry alignment.
static func _run_footwork_offset_shifts_attack_angle_deg(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("left")
		),
	}
	var base_deg: float = CombatConstants.line_to_angle("left")
	var shifted: float = _Footwork.apply_offset_to_angle_deg(base_deg, atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(
		base_deg + CombatConstants.position_angle_offset_deg_for_attack_line("left") + 360.0,
		360.0
	)
	if absf(shifted - want) > 0.05:
		_fail(failures, "footwork_angle: want %.2f got %.2f" % [want, shifted])


## Tier 4.4: **`CombatManager.start()`** scrubs position offset.
static func _run_footwork_offset_scrubbed_on_combat_start(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 12.0
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		_fail(failures, "footwork_scrub: offset should clear on start")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)


## Tier 4.4.2: committed parry stamps scaled defender offset from guard line.
static func _run_footwork_defender_parry_step_stamps_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {}
	_Footwork.apply_defender_step_on_parry(def, "left")
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
	)
	if absf(off - want) > 0.01:
		_fail(failures, "footwork_def_parry: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: defender offset rotates effective guard angle for alignment.
static func _run_footwork_defender_offset_shifts_guard_angle_deg(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {
		"guard_line": "left",
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_defender_offset_deg_for_line(
				"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
			)
		),
	}
	var base_deg: float = CombatConstants.get_guard_angle_deg(def, {})
	var shifted: float = _Footwork.guard_angle_deg(def, {})
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(
		base_deg
		+ CombatConstants.position_angle_defender_offset_deg_for_line(
			"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_PARRY
		)
		+ 360.0,
		360.0
	)
	if absf(shifted - want) > 0.05:
		_fail(failures, "footwork_def_guard: want %.2f got %.2f" % [want, shifted])


## Tier 4.4.2: dodge stamps larger scaled offset from eval part line.
static func _run_footwork_defender_dodge_step_stamps_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {}
	_Footwork.apply_defender_step_on_dodge(def, "left_arm")
	var off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	if absf(off - want) > 0.01:
		_fail(failures, "footwork_def_dodge: want %.2f got %.2f" % [want, off])


## Tier 4.4.2: exchange end clears defender offset (dodge applier path).
static func _run_footwork_defender_offset_scrubbed_after_exchange(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	var def: Dictionary = mgr.combatants[1]
	def[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 9.0
	_AttackResultApplier.apply_result(
		mgr,
		_EntityAccess.id_int(atk),
		{"action": "dodge", "target_id": _EntityAccess.id_int(def), "recovery_duration": 0.2},
	)
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		_fail(failures, "footwork_def_scrub: defender offset should clear after dodge")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)


## Tier 4.4.3: footwork UI hint shows signed step degrees.
static func _run_footwork_ui_hint_formats_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var hint: String = _Footwork.format_position_angle_ui_hint(atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	if hint != "Step +%.0f°" % want:
		_fail(failures, "footwork_ui_hint: want 'Step +%.0f°' got '%s'" % [want, hint])


## Tier 4.4.3: compact diagram suffix for single-occupant formation cells.
static func _run_footwork_diagram_label_suffix_compact(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(c, "left")
	var want: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	var sfx: String = _Footwork.get_diagram_label_suffix(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if sfx != " · +%.0f°" % want:
		_fail(failures, "footwork_diagram_suffix: want ' · +%.0f°' got '%s'" % [want, sfx])


## Tier 4.4.3: stale stamped hint yields live offset when they disagree.
static func _run_footwork_ui_hint_stale_stamp_prefers_live_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(c, "right")
	c[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT] = "Step +99°"
	var live: String = _Footwork.get_ui_hint(c)
	var want_live: String = _Footwork.format_position_angle_ui_hint(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if live != want_live:
		_fail(failures, "footwork_stale_stamp: want '%s' got '%s'" % [want_live, live])


## Tier 4.4.3: clearing offset clears stamped UI hint key.
static func _run_footwork_ui_hint_clears_on_clear_position_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var c: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(c, "right")
	_Footwork.clear_position_offset(c)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if c.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		_fail(failures, "footwork_ui_hint_clear: hint key should be erased")
	if _Footwork.format_position_angle_ui_hint(c) != "":
		_fail(failures, "footwork_ui_hint_clear: format should be empty")
	if _Footwork.get_ui_hint(c) != "":
		_fail(failures, "footwork_ui_hint_clear: get_ui_hint should be empty")


## Tier 4.4.3: combat start scrubs stamped footwork UI hint (via clear_position_offset).
static func _run_footwork_ui_hint_clears_on_combat_start(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	var atk: Dictionary = mgr.combatants[0]
	_Footwork.apply_attack_step_on_windup(atk, "left")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT):
		_fail(failures, "footwork_ui_hint_start: hint key should be erased on combat start")
	if _Footwork.get_ui_hint(atk) != "":
		_fail(failures, "footwork_ui_hint_start: get_ui_hint should be empty after start")


## Tier 4.4.3: combatant snapshot exposes offset + hint when footwork flag on.
static func _run_footwork_snapshot_includes_position_hint_when_enabled(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var atk: Dictionary = mgr.combatants[0]
	_Footwork.apply_attack_step_on_windup(atk, "left")
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		_fail(failures, "footwork_snapshot: expected one row")
		return
	var row: Dictionary = rows[0]
	if not row.has("position_angle_offset_deg"):
		_fail(failures, "footwork_snapshot: missing position_angle_offset_deg")
	var want_hint: String = _Footwork.get_ui_hint(atk)
	if str(row.get("position_angle_ui_hint", "")) != want_hint:
		_fail(
			failures,
			"footwork_snapshot: ui hint mismatch row='%s' want='%s'"
			% [row.get("position_angle_ui_hint", ""), want_hint]
		)


## Tier 4.4.3: snapshot derives UI hint from offset when stamp key missing.
static func _run_footwork_snapshot_ui_hint_from_unstamped_offset(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var atk: Dictionary = mgr.combatants[0]
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	atk[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = off
	atk.erase(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_UI_HINT)
	var rows: Array = _CombatSnapshot.build(mgr)
	var want_hint: String = _Footwork.get_ui_hint(atk)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		_fail(failures, "footwork_snapshot_unstamped: expected one row")
		return
	var row: Dictionary = rows[0]
	if str(row.get("position_angle_ui_hint", "")) != want_hint:
		_fail(
			failures,
			"footwork_snapshot_unstamped: want '%s' got '%s'" % [want_hint, row.get("position_angle_ui_hint", "")]
		)
	if absf(float(row.get("position_angle_offset_deg", 0.0)) - off) > 0.01:
		_fail(failures, "footwork_snapshot_unstamped: offset deg missing or wrong")


## Tier 4.4 UI soak: snapshot copies stamped attention hint for gauge/diagram consumers.
static func _run_combat_snapshot_exports_attention_ui_hint_when_stamped(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	var stamped: String = "Tel head · Focus head 80%"
	def[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = stamped
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_combat_attention_load(false)
	_free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		_fail(failures, "snapshot_attention: expected one row")
		return
	if str(rows[0].get("attention_ui_hint", "")) != stamped:
		_fail(
			failures,
			"snapshot_attention: row='%s' want='%s'"
			% [rows[0].get("attention_ui_hint", ""), stamped]
		)


## Tier 4.4 UI soak: snapshot copies stamped counter-tempo hint for gauge consumers.
static func _run_combat_snapshot_exports_counter_tempo_ui_hint_when_stamped(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_counter_tempo_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var def: Dictionary = mgr.combatants[0]
	var stamped: String = "counter_ready"
	def[CombatConstants.COMBATANT_KEY_COUNTER_TEMPO_UI_HINT] = stamped
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_counter_tempo_load(true)
	_free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		_fail(failures, "snapshot_counter_tempo: expected one row")
		return
	if str(rows[0].get("counter_tempo_ui_hint", "")) != stamped:
		_fail(
			failures,
			"snapshot_counter_tempo: row='%s' want='%s'"
			% [rows[0].get("counter_tempo_ui_hint", ""), stamped]
		)


## Tier 4.4.3: snapshot omits position-angle fields when footwork flag off.
static func _run_footwork_snapshot_omits_position_when_disabled(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var atk: Dictionary = mgr.combatants[0]
	_Footwork.apply_attack_step_on_windup(atk, "left")
	CombatConstants.set_feature_position_angle_footwork_load(false)
	var rows: Array = _CombatSnapshot.build(mgr)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)
	if rows.is_empty():
		_fail(failures, "footwork_snapshot_disabled: expected one row")
		return
	var row: Dictionary = rows[0]
	if row.has("position_angle_offset_deg") or row.has("position_angle_ui_hint"):
		_fail(
			failures,
			"footwork_snapshot_disabled: should omit position_angle keys when flag off"
		)


## Tier 4.4: body-part → guard line for dodge step direction.
static func _run_footwork_guard_line_for_body_part_maps_legs_and_chest(failures: PackedStringArray) -> void:
	if CombatConstants.guard_line_for_body_part("right_leg") != "low":
		_fail(failures, "footwork_part_line: right_leg want low")
	if CombatConstants.guard_line_for_body_part("chest") != "high":
		_fail(failures, "footwork_part_line: chest want high")


## Tier 4.4: parry-eval helpers do not stamp offset; dodge commit replaces parry stamp.
static func _run_footwork_choose_defense_dodge_does_not_keep_parry_offset(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var def: Dictionary = {"guard_line": "left"}
	var prov: float = _Footwork.parry_eval_step_deg_for_defender(def)
	if def.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		_fail(failures, "footwork_provisional: parry_eval must not stamp offset on combatant")
	if prov < 0.01:
		_fail(failures, "footwork_provisional: want non-zero eval step for left guard")
	_Footwork.apply_defender_step_on_parry(def, "left")
	var parry_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	_Footwork.clear_position_offset(def)
	_Footwork.apply_defender_step_on_dodge(def, "left_arm")
	var dodge_off: float = float(def.get(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0))
	var want_dodge: float = CombatConstants.position_angle_defender_offset_deg_for_line(
		"left", CombatConstants.POSITION_ANGLE_DEFENDER_OFFSET_SCALE_DODGE
	)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(parry_off - dodge_off) < 0.01:
		_fail(
			failures,
			"footwork_commit_dodge: dodge offset should differ from parry stamp got %.2f"
			% dodge_off
		)
	if absf(dodge_off - want_dodge) > 0.05:
		_fail(
			failures,
			"footwork_commit_dodge: want dodge offset %.2f got %.2f" % [want_dodge, dodge_off]
		)


## Tier 4.4: **`arc_end_deg_for_contact_geometry`** must not treat offset-bearing **`attack_angle_deg`** as arc end.
static func _run_footwork_arc_end_fallback_prefers_intended_over_attack_angle(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("left")
	var pa: Dictionary = {
		"arc_intended_deg": 90.0,
		"attack_angle_deg": fmod(90.0 + off + 360.0, 360.0),
	}
	var end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(end - 90.0) > 0.05:
		_fail(failures, "footwork_arc_end_fb: want intended 90 got %.2f" % end)
	var arc_start: float = float(pa.get("arc_start_deg", 0.0))
	var arc_end: float = CombatConstants.arc_end_deg_for_contact_geometry(pa)
	var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end, 1.0)
	var atk: Dictionary = {CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: off}
	at_contact = _Footwork.apply_offset_to_angle_deg(at_contact, atk)
	var doubled: float = _Footwork.apply_offset_to_angle_deg(90.0 + off, atk)
	if absf(at_contact - doubled) < 0.05:
		_fail(failures, "footwork_arc_end_fb: progress-1 should apply offset once got %.2f" % at_contact)


## Tier 4.4: **`parry_partial`** follow-through must not re-roll resolve angle geometry.
static func _run_footwork_partial_follow_through_freezes_resolve_angles(
	failures: PackedStringArray
) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("high")
		),
	}
	var pa: Dictionary = {
		"passive_parry_attempted": true,
		"attack_angle_deg": 201.0,
		"arc_end_deg": 187.0,
		"arc_span_deg": 42.0,
		"effective_attack_line": "left",
		"arc_start_deg": 0.0,
	}
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	_AttackResolver.stamp_resolve_angle_geometry_on_pa(pa, atk, "high", move_def, 0.0)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if absf(float(pa.get("attack_angle_deg", -1.0)) - 201.0) > 0.05:
		_fail(
			failures,
			"footwork_partial_freeze: attack_angle_deg changed to %.2f" % float(pa.get("attack_angle_deg", -1.0))
		)
	if absf(float(pa.get("arc_end_deg", -1.0)) - 187.0) > 0.05:
		_fail(
			failures,
			"footwork_partial_freeze: arc_end_deg changed to %.2f" % float(pa.get("arc_end_deg", -1.0))
		)
	if absf(float(pa.get("arc_span_deg", -1.0)) - 42.0) > 0.05:
		_fail(
			failures,
			"footwork_partial_freeze: arc_span_deg changed to %.2f" % float(pa.get("arc_span_deg", -1.0))
		)
	if str(pa.get("effective_attack_line", "")) != "left":
		_fail(
			failures,
			"footwork_partial_freeze: effective_attack_line changed to %s"
			% str(pa.get("effective_attack_line", ""))
		)


## Tier 4.4: wind-up **`arc_intended_deg`** includes attacker step (guard transition + arc query).
static func _run_footwork_windup_arc_intended_includes_attacker_step(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var mgr: Node = _MgrScript.new()
	var p_ent: Node = _new_entity("SWORD")
	var e_ent: Node = _new_entity("SWORD")
	mgr.register(p_ent, "player")
	mgr.register(e_ent, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	seed(42)
	_WindUpStarter.start(mgr, p_id, e_id, "oberhau", {"target_part": "chest"})
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	var atk: Dictionary = mgr._get_by_id(p_id)
	var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	var intended: float = float(pa.get("arc_intended_deg", -999.0))
	var off: float = CombatConstants.position_angle_offset_deg_for_attack_line("high")
	var want: float = fmod(CombatConstants.line_to_angle("high") + off + 360.0, 360.0)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	_free_manager_restore_global_rng(mgr)
	if intended < -900.0:
		_fail(failures, "footwork_windup_intended: missing arc_intended_deg")
		return
	if absf(intended - want) > 0.05:
		_fail(failures, "footwork_windup_intended: want %.2f got %.2f" % [want, intended])


## Tier 4.4: **`arc_end_deg`** stays pre-offset; parry contact applies footwork once (not twice at progress 1).
static func _run_footwork_arc_contact_applies_offset_once(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var atk: Dictionary = {
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG: (
			CombatConstants.position_angle_offset_deg_for_attack_line("left")
		),
	}
	var arc_start: float = 0.0
	var arc_end_base: float = 90.0
	var at_contact: float = CombatConstants.get_arc_angle_at_progress(arc_start, arc_end_base, 1.0)
	at_contact = _Footwork.apply_offset_to_angle_deg(at_contact, atk)
	var doubled: float = _Footwork.apply_offset_to_angle_deg(
		CombatConstants.get_arc_angle_at_progress(arc_start, arc_end_base + atk.get(
			CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0
		), 1.0),
		atk
	)
	CombatConstants.set_feature_position_angle_footwork_load(true)
	var want: float = fmod(arc_end_base + float(atk.get(
		CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG, 0.0
	)) + 360.0, 360.0)
	if absf(at_contact - want) > 0.05:
		_fail(failures, "footwork_arc_once: want %.2f got %.2f" % [want, at_contact])
	if absf(doubled - at_contact) < 0.05:
		_fail(
			failures,
			"footwork_arc_once: double-apply would match got %.2f (want distinct)" % at_contact
		)


## Tier 4.4: flag off — step-on-windup does not stamp offset (restore production default after).
static func _run_footwork_disabled_skips_windup_stamp(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_position_angle_footwork_load(false)
	var atk: Dictionary = {}
	_Footwork.apply_attack_step_on_windup(atk, "left")
	CombatConstants.set_feature_position_angle_footwork_load(true)
	if atk.has(CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG):
		_fail(failures, "footwork_disabled: offset must not stamp when flag off")


## Tier 4.3.8: attention UI hint shows last mental-stack layer stamp.
static func _run_attention_ui_hint_includes_mental_stack_layer(failures: PackedStringArray) -> void:
	CombatConstants.set_feature_combat_attention_load(true)
	var def: Dictionary = {
		CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER: "incoming",
		CombatConstants.COMBATANT_KEY_FOCUS_PART: "head",
		CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY: 1.0,
	}
	var hint: String = _Attention.format_attention_ui_hint(def)
	CombatConstants.set_feature_combat_attention_load(false)
	if not hint.contains("Stack incoming"):
		_fail(failures, "attention_ui_stack: want Stack incoming in '%s'" % hint)


## Tier 4.3.7: yomi **`parry_deflect`** count boosts feint listing mult.
static func _run_yomi_parry_deflect_boosts_feint_listing_mult(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 13
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m0: float = _Attention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var m1: float = _Attention.yomi_parry_deflect_feint_listing_mult(def, atk_id)
	if m1 <= m0 or m0 <= 1.0:
		_fail(
			failures,
			"yomi_parry_deflect_feint: mult should rise got m0=%.4f m1=%.4f" % [m0, m1]
		)


## Tier 4.3: **`parry_deflect`** increments yomi; **`hit`** clears attacker entry.
static func _run_yomi_updates_on_parry_deflect_clears_on_hit(failures: PackedStringArray) -> void:
	var def: Dictionary = {}
	var atk_id: int = 3
	_Attention.record_parry_deflect_on_attacker_memory(def, atk_id)
	var root: Dictionary = def.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, {}) as Dictionary
	var entry: Dictionary = root.get(str(atk_id), {}) as Dictionary
	if int(entry.get("parry_deflect", 0)) != 1:
		_fail(failures, "yomi_parry: want parry_deflect count 1")
	_Attention.clear_yomi_for_attacker(def, atk_id)
	if def.has(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER):
		_fail(failures, "yomi_clear: yomi root should be empty after clear")


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", probing)`** multiplies feint listing by **`AI_FEINT_LISTING_DOCTRINE_PROBING_MULT`**; then **`hold_lane`** applies **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no probing mult).
static func _run_feint_move_listing_doctrine_probing_multiplies_feint_weight(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
	mgr._recompute_zoc_and_distance()
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_p: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_p: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_p: float = (
		w_plain_p
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT
	)
	if absf(w_feint_p - want_p) > 0.0001 * maxf(1.0, absf(w_plain_p)):
		_fail(
			failures,
			"feint_list_probe: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [
				want_p,
				w_feint_p,
				w_plain_p,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PROBING_MULT),
			]
		)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_h: float = (
		w_plain_h
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
		_fail(
			failures,
			"feint_list_hold: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
			% [want_h, w_feint_h, w_plain_h]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.set_formation_doctrine("player", pinch_center)`** multiplies feint listing by **`AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT`**; then **`hold_lane`** applies **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** only (no pinch mult).
static func _run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var enemy: Dictionary = mgr.combatants[1]
	var e_id: int = _EntityAccess.id_int(enemy)
	enemy["guard"] = 0.0
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["off_balance_until"] = -1.0
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PINCH_CENTER)
	mgr._recompute_zoc_and_distance()
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_z: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_z: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_z: float = (
		w_plain_z
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT
	)
	if absf(w_feint_z - want_z) > 0.0001 * maxf(1.0, absf(w_plain_z)):
		_fail(
			failures,
			"feint_list_pinch: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [
				want_z,
				w_feint_z,
				w_plain_z,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_PINCH_CENTER_MULT),
			]
		)
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var want_h: float = (
		w_plain_h
		* CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT
		* target_m
		* CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	)
	if absf(w_feint_h - want_h) > 0.0001 * maxf(1.0, absf(w_plain_h)):
		_fail(
			failures,
			"feint_list_hold_after_pinch: want feint %.6f got %.6f plain=%.6f (hold_lane feint damp only)"
			% [want_h, w_feint_h, w_plain_h]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`hold_lane`** feint listing × **`AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT`** vs explicit **`default`** (ratio **`w_feint/w_plain`**).
static func _run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	player["stance"] = CombatConstants.STANCE_BALANCED
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var w_plain_d: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_d: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_d) < 1e-9:
		_fail(failures, "feint_hold_vs_def: plain weight near zero")
		_free_manager_restore_global_rng(mgr)
		return
	var ratio_def: float = w_feint_d / w_plain_d
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	mgr._recompute_zoc_and_distance()
	var w_plain_h: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_h: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if absf(w_plain_h) < 1e-9:
		_fail(failures, "feint_hold_vs_def: plain weight near zero (hold)")
		_free_manager_restore_global_rng(mgr)
		return
	var ratio_hold: float = w_feint_h / w_plain_h
	var want_ratio: float = ratio_def * CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT
	if absf(ratio_hold - want_ratio) > 0.0001 * maxf(1.0, absf(ratio_def)):
		_fail(
			failures,
			"feint_hold_vs_def: want ratio %.6f got %.6f ratio_def=%.6f mult=%s"
			% [
				want_ratio,
				ratio_hold,
				ratio_def,
				str(CombatConstants.AI_FEINT_LISTING_DOCTRINE_HOLD_LANE_MULT),
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: attacker **`stance`** × **`get_stance_modifier(..., "ai_feint_listing")`** on feint listing; settled WAITING × **`AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT`** + full **`read_m`** chain via **`_feint_listing_read_m_expect_for_move_on_target`**.
static func _run_feint_move_listing_stance_ai_feint_mult_ordering(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var player: Dictionary = mgr.combatants[0]
	var p_id: int = _EntityAccess.id_int(player)
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[1]["guard"] = 0.0
	mgr.combatants[1]["state"] = CombatConstants.STATE_WAITING
	mgr.combatants[1]["off_balance_until"] = -1.0
	mgr._recompute_zoc_and_distance()
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var enemy: Dictionary = mgr.combatants[1]
	var target_m: float = _feint_listing_target_readiness_and_footwork_mult(enemy, p_id, "oberhau_feint")
	player["stance"] = CombatConstants.STANCE_CONTROLLING
	var w_plain_c: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_c: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var mult_c: float = CombatConstants.get_stance_modifier(
		CombatConstants.STANCE_CONTROLLING, "ai_feint_listing"
	)
	var want_c: float = (
		w_plain_c * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * mult_c
	)
	if absf(w_feint_c - want_c) > 0.0001 * maxf(1.0, absf(w_plain_c)):
		_fail(
			failures,
			"feint_stance_list ctrl: want feint %.6f (plain*base*stance) got %.6f plain=%.6f mult=%s"
			% [want_c, w_feint_c, w_plain_c, str(mult_c)]
		)
	player["stance"] = CombatConstants.STANCE_DEFENSIVE
	var w_plain_d: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_d: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	var mult_d: float = CombatConstants.get_stance_modifier(
		CombatConstants.STANCE_DEFENSIVE, "ai_feint_listing"
	)
	var want_d: float = (
		w_plain_d * CombatConstants.AI_IS_FEINT_MOVE_LISTING_WEIGHT_MULT * target_m * mult_d
	)
	if absf(w_feint_d - want_d) > 0.0001 * maxf(1.0, absf(w_plain_d)):
		_fail(
			failures,
			"feint_stance_list def: want feint %.6f got %.6f plain=%.6f mult=%s"
			% [want_d, w_feint_d, w_plain_d, str(mult_d)]
		)
	var r_c: float = w_feint_c / w_plain_c
	var r_d: float = w_feint_d / w_plain_d
	if r_c <= r_d + 1e-6:
		_fail(
			failures,
			"feint_stance_list: want controlling feint/plain ratio > defensive got c=%.6f d=%.6f"
			% [r_c, r_d]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker.opts_from_choice`** omits empty **`feint_part`**; non-**`is_feint`** **`_add_attack_target_part`** does not introduce **`feint_part`** on the choice dict.
static func _run_feint_opts_from_choice_and_non_feint_attack_no_feint_part(failures: PackedStringArray) -> void:
	var c_target_only: Dictionary = {"move_id": "oberhau", "target_id": 1, "target_part": "chest"}
	var o_target: Dictionary = _AIPicker.opts_from_choice(c_target_only)
	if not o_target.has("target_part") or str(o_target.get("target_part", "")) != "chest":
		_fail(failures, "feint_opts: expected target_part chest in opts got %s" % str(o_target))
	if o_target.has("feint_part"):
		_fail(failures, "feint_opts: non-feint choice should omit feint_part got %s" % str(o_target))
	var c_with_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": "head"
	}
	var o_both: Dictionary = _AIPicker.opts_from_choice(c_with_feint)
	if str(o_both.get("feint_part", "")) != "head":
		_fail(failures, "feint_opts: should forward non-empty feint_part got %s" % str(o_both))
	var c_thrust_feint: Dictionary = {
		"move_id": "thrust_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": "head",
	}
	var o_thrust_feint: Dictionary = _AIPicker.opts_from_choice(c_thrust_feint)
	if str(o_thrust_feint.get("feint_part", "")) != "head":
		_fail(failures, "feint_opts: thrust_feint should forward non-empty feint_part got %s" % str(o_thrust_feint))
	var c_empty_feint: Dictionary = {
		"move_id": "oberhau_feint",
		"target_id": 1,
		"target_part": "chest",
		"feint_part": ""
	}
	var o_no_feint: Dictionary = _AIPicker.opts_from_choice(c_empty_feint)
	if o_no_feint.has("feint_part"):
		_fail(failures, "feint_opts: empty feint_part should be omitted got %s" % str(o_no_feint))
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(e)
	mgr._recompute_zoc_and_distance()
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	var choice: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	_AIPicker._add_attack_target_part(choice, mgr, p_id)
	if str(choice.get("target_part", "")).is_empty():
		_fail(failures, "feint_neg: expected oberhau target_part from _add_attack_target_part")
	if choice.has("feint_part") and str(choice.get("feint_part", "")) != "":
		_fail(
			failures,
			"feint_neg: non-feint oberhau must not set non-empty feint_part got %s" % str(choice.get("feint_part", ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 harness helper: **`AttackPathResolver`** uses **`randf`** in **`resolve_hit_part`** — find a global RNG seed in **0..16383** so **`DefenseChoiceResolver._guard_zone_modifier`** returns **`want_mult`**. Pass **`parry_readiness_for_feint` < 0** for the legacy 4-arg call. Pass **`atk_id_for_spacing` < 0** (default) unless the scan must use the optional spacing arg on **`_guard_zone_modifier`**.
static func _feint_guard_zone_sample_global_seed_for_modifier(
	pa: Dictionary,
	tgt: Dictionary,
	parts: Array,
	move_id: String,
	parry_readiness_for_feint: float,
	want_mult: float,
	atk_id_for_spacing: int = -1
) -> int:
	for s: int in range(16384):
		seed(s)
		var m: float
		if parry_readiness_for_feint < 0.0:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id)
		elif atk_id_for_spacing < 0:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id, parry_readiness_for_feint)
		else:
			m = _DefenseChoice._guard_zone_modifier(pa, tgt, parts, move_id, parry_readiness_for_feint, atk_id_for_spacing)
		if is_equal_approx(m, want_mult):
			return s
	return -1


## Tier 4.2: **`DefenseChoiceResolver._guard_zone_modifier`** — feint telegraph mismatch → **`GUARD_ZONE_UNGUARDED_PENALTY`**; defender **`guard_zone`** moved to real line → **`GUARD_ZONE_BONUS`**; non-feint unchanged. **`AttackPathResolver`** uses **`randf`** — scan stable seeds per fixture, then restore global RNG.
static func _run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var tgt_baited: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		_fail(failures, "feint_guard_zone: no PathResolver seed yields bait penalty in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(bait_seed)
	var m_pen: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
	if not is_equal_approx(m_pen, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(
			failures,
			"feint_guard_zone: baited want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_pen]
		)
	var tgt_readjust: Dictionary = {
		"guard_zone": "left_leg",
		"guard_line": "low",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var readjust_bonus_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_readjust,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_BONUS
	)
	if readjust_bonus_seed < 0:
		_fail(failures, "feint_guard_zone: no PathResolver seed yields readjust bonus in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(readjust_bonus_seed)
	var m_ok: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_readjust, parts, "oberhau_feint")
	if not is_equal_approx(m_ok, CombatConstants.GUARD_ZONE_BONUS):
		_fail(failures, "feint_guard_zone: readjust want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_ok])
	var pa_plain: Dictionary = {"target_part": "head", "attack_type": "oberhau"}
	var tgt_plain: Dictionary = {"guard_zone": "head", "guard_line": "high"}
	var plain_bonus_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_plain,
		tgt_plain,
		parts,
		"oberhau",
		-1.0,
		CombatConstants.GUARD_ZONE_BONUS
	)
	if plain_bonus_seed < 0:
		_fail(failures, "feint_guard_zone: no PathResolver seed yields non-feint bonus in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(plain_bonus_seed)
	var m_plain: float = _DefenseChoice._guard_zone_modifier(pa_plain, tgt_plain, parts, "oberhau")
	if not is_equal_approx(m_plain, CombatConstants.GUARD_ZONE_BONUS):
		_fail(failures, "feint_guard_zone: non-feint want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_plain])
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: high passive parry readiness + stance can read real line despite **`guard_zone`** still on telegraph (**`FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`** × **`get_stance_modifier(..., "feint_readthrough")`**). **`AttackPathResolver`** **`randf`** — scan a bait seed for telegraph mismatch, then **`seed(bait_seed)`** before each **`_guard_zone_modifier`** so **`expected_part`** matches across cases.
static func _run_feint_guard_zone_readthrough_par_bonus_when_readiness_high(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var tgt_baited: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		_fail(failures, "feint_readthrough: no PathResolver seed yields bait penalty in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	seed(bait_seed)
	var m_legacy: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint")
	if not is_equal_approx(m_legacy, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(
			failures,
			"feint_readthrough: legacy (no readiness arg) want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_legacy]
		)
	seed(bait_seed)
	var m_full: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 1.0)
	if not is_equal_approx(m_full, CombatConstants.GUARD_ZONE_BONUS):
		_fail(failures, "feint_readthrough: readiness 1 defensive want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_full])
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.86)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
		_fail(failures, "feint_readthrough: readiness 0.86 defensive want bonus got %.2f" % m_mid)
	seed(bait_seed)
	var m_low: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_baited, parts, "oberhau_feint", 0.82)
	if not is_equal_approx(m_low, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(failures, "feint_readthrough: readiness 0.82 defensive want penalty got %.2f" % m_low)
	var tgt_agg: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "aggressive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	seed(bait_seed)
	var m_agg: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_agg, parts, "oberhau_feint", 0.88)
	if not is_equal_approx(m_agg, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(failures, "feint_readthrough: aggressive 0.88 want penalty got %.2f" % m_agg)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` LONG** scales **`parry_readiness_for_feint`** before **`_feint_guard_reads_real_line`** in **`_guard_zone_modifier`** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_*`**); same base readiness at **MID** stays sub-threshold, **LONG** crosses (**defensive** × **`STANCE_MOD_FEINT_READTHROUGH`**).
static func _run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var atk_id: int = 42
	var tgt_baited_base: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
	tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
	var tgt_long: Dictionary = tgt_baited_base.duplicate(true)
	tgt_long["distance_to"] = {atk_id: CombatConstants.DISTANCE_LONG}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited_base,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		_fail(failures, "feint_gz_spacing: no PathResolver seed yields bait penalty in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	var pr_spacing: float = 0.845
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id)
	seed(bait_seed)
	var m_long: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_long, parts, "oberhau_feint", pr_spacing, atk_id)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(
			failures,
			"feint_gz_spacing: mid want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_mid]
		)
	if not is_equal_approx(m_long, CombatConstants.GUARD_ZONE_BONUS):
		_fail(failures, "feint_gz_spacing: long want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_long])
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2: **`defender_distance_to` CLOSE** scales **`parry_readiness_for_feint`** down before **`_feint_guard_reads_real_line`**; same base readiness at **MID** clears the gate, **CLOSE** falls below (**defensive** × **`STANCE_MOD_FEINT_READTHROUGH`**).
static func _run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid(failures: PackedStringArray) -> void:
	var parts: Array = ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"]
	var pa_feint: Dictionary = {
		"feint_part": "head",
		"target_part": "left_leg",
		"attack_type": "oberhau_feint",
	}
	var atk_id: int = 43
	var tgt_baited_base: Dictionary = {
		"guard_zone": "head",
		"guard_line": "high",
		"stance": "defensive",
		CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART: "head",
	}
	var tgt_mid: Dictionary = tgt_baited_base.duplicate(true)
	tgt_mid["distance_to"] = {atk_id: CombatConstants.DISTANCE_MID}
	var tgt_close: Dictionary = tgt_baited_base.duplicate(true)
	tgt_close["distance_to"] = {atk_id: CombatConstants.DISTANCE_CLOSE}
	var bait_seed: int = _feint_guard_zone_sample_global_seed_for_modifier(
		pa_feint,
		tgt_baited_base,
		parts,
		"oberhau_feint",
		-1.0,
		CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY
	)
	if bait_seed < 0:
		_fail(failures, "feint_gz_spacing_close: no PathResolver seed yields bait penalty in 0..16383")
		seed(_HARNESS_RESTORE_GLOBAL_SEED)
		return
	var pr_spacing: float = 0.855
	seed(bait_seed)
	var m_mid: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_mid, parts, "oberhau_feint", pr_spacing, atk_id)
	seed(bait_seed)
	var m_close: float = _DefenseChoice._guard_zone_modifier(pa_feint, tgt_close, parts, "oberhau_feint", pr_spacing, atk_id)
	if not is_equal_approx(m_mid, CombatConstants.GUARD_ZONE_BONUS):
		_fail(
			failures,
			"feint_gz_spacing_close: mid want bonus %.2f got %.2f" % [CombatConstants.GUARD_ZONE_BONUS, m_mid]
		)
	if not is_equal_approx(m_close, CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY):
		_fail(
			failures,
			"feint_gz_spacing_close: close want penalty %.2f got %.2f" % [CombatConstants.GUARD_ZONE_UNGUARDED_PENALTY, m_close]
		)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 4.2 telegraph delay: **`DefenseChoiceResolver._feint_readiness_reveal_mult`** — early wind-up damps toward **`FEINT_PRE_REVEAL_READINESS_MULT`** until progress ≥ **`feint_target_reveal_at_progress`** (**`WeaponConstants`** / **`pa`**); no feint / reveal **0** → **1.0**; **`choose_defense`** **`parry_readiness`** echoes the same mult when feint passive parry applies.
static func _run_feint_target_reveal_progress_scales_readiness_mult(failures: PackedStringArray) -> void:
	var pa: Dictionary = {"feint_part": "head", "attack_type": "oberhau_feint"}
	var atk0: Dictionary = {
		"state": CombatConstants.STATE_WIND_UP,
		"state_timer": 0.0,
		"state_duration": 1.0,
	}
	var reveal: float = float(WeaponConstants.get_move("oberhau_feint").get("feint_target_reveal_at_progress", 0.45))
	var m0: float = _DefenseChoice._feint_readiness_reveal_mult(pa, atk0)
	var want0: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.0)
	if not is_equal_approx(m0, want0):
		_fail(failures, "feint_reveal t=0 want %.6f got %.6f" % [want0, m0])
	var atk_half: Dictionary = atk0.duplicate()
	atk_half["state_timer"] = reveal * 0.5 * atk0["state_duration"]
	var m_h: float = _DefenseChoice._feint_readiness_reveal_mult(pa, atk_half)
	var want_h: float = lerpf(CombatConstants.FEINT_PRE_REVEAL_READINESS_MULT, 1.0, 0.5)
	if not is_equal_approx(m_h, want_h):
		_fail(failures, "feint_reveal half window want %.6f got %.6f" % [want_h, m_h])
	var atk_edge: Dictionary = atk0.duplicate()
	atk_edge["state_timer"] = reveal * atk0["state_duration"]
	if not is_equal_approx(_DefenseChoice._feint_readiness_reveal_mult(pa, atk_edge), 1.0):
		_fail(failures, "feint_reveal at reveal_at want 1.0")
	var atk_late: Dictionary = atk0.duplicate()
	atk_late["state_timer"] = 0.99
	if not is_equal_approx(_DefenseChoice._feint_readiness_reveal_mult(pa, atk_late), 1.0):
		_fail(failures, "feint_reveal late want 1.0")
	var pa_no_feint: Dictionary = {"feint_part": "", "attack_type": "oberhau"}
	if _DefenseChoice._feint_readiness_reveal_mult(pa_no_feint, atk0) != 1.0:
		_fail(failures, "feint_reveal empty feint_part want 1.0")
	var pa_off: Dictionary = {
		"feint_part": "head",
		"feint_target_reveal_at_progress": 0.0,
		"attack_type": "oberhau_feint",
	}
	if _DefenseChoice._feint_readiness_reveal_mult(pa_off, atk0) != 1.0:
		_fail(failures, "feint_reveal explicit zero want 1.0")
	var atk_rec: Dictionary = atk0.duplicate()
	atk_rec["state"] = CombatConstants.STATE_RECOVERING
	if _DefenseChoice._feint_readiness_reveal_mult(pa, atk_rec) != 1.0:
		_fail(failures, "feint_reveal non-wind_up attacker want 1.0")
	var pa_stab: Dictionary = {"feint_part": "chest", "attack_type": "thrust_feint"}
	var reveal_stab: float = float(WeaponConstants.get_move("thrust_feint").get("feint_target_reveal_at_progress", 0.4))
	if not is_equal_approx(reveal_stab, 0.4):
		_fail(failures, "feint_reveal thrust_feint move want reveal 0.4 got %.6f" % reveal_stab)
	var atk_stab_half: Dictionary = atk0.duplicate()
	atk_stab_half["state_timer"] = reveal_stab * 0.5 * atk0["state_duration"]
	var m_stab_h: float = _DefenseChoice._feint_readiness_reveal_mult(pa_stab, atk_stab_half)
	if not is_equal_approx(m_stab_h, want_h):
		_fail(
			failures,
			"feint_reveal thrust half window want %.6f got %.6f" % [want_h, m_stab_h]
		)
	# choose_defense: reported parry_readiness scales by same mult during feint wind-up early vs late.
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["stamina"] = CombatConstants.STAMINA_MAX
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n2: Node = _EntityAccess.scene_node(defender)
	var parts2: Array = (
		def_n2.get_targetable_parts()
		if def_n2 != null and def_n2.has_method("get_targetable_parts")
		else []
	)
	if parts2.is_empty():
		_fail(failures, "feint_reveal choose_def: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_fe: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch_fe: Dictionary = WeaponConstants.get_archetype(
		str(move_fe.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa_cd: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	attacker["state"] = CombatConstants.STATE_WIND_UP
	attacker["state_duration"] = 1.0
	attacker["state_timer"] = 0.0
	seed(92003)
	var dc_e: Dictionary = _DefenseChoice.choose_defense(pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0)
	attacker["state_timer"] = 0.99
	seed(92003)
	var dc_l2: Dictionary = _DefenseChoice.choose_defense(pa_cd, attacker, defender, parts2, "oberhau_feint", arch_fe, -1.0)
	var pr_e: float = float(dc_e.get("parry_readiness", -1.0))
	var pr_l2: float = float(dc_l2.get("parry_readiness", -1.0))
	if pr_e <= 1e-8 or pr_l2 <= 1e-8:
		_fail(
			failures,
			"feint_reveal choose_def: parry_readiness too small pr_e=%.6f pr_l=%.6f" % [pr_e, pr_l2]
		)
		_free_manager_restore_global_rng(mgr)
		return
	if not is_equal_approx(pr_e / pr_l2, want0):
		_fail(
			failures,
			"feint_reveal choose_def: early/late readiness ratio want %.6f got %.6f (pr_e=%.6f pr_l=%.6f)"
			% [want0, pr_e / pr_l2, pr_e, pr_l2]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`DefenseChoiceResolver.choose_defense`** — when **`feint_part`** is set and defender does not read through (**`guard` × stance `feint_readthrough` < `FEINT_GUARD_ZONE_READTHROUGH_THRESHOLD`**), **`dodge_eval_part`** can follow the telegraph; harness sets **`pa[CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS]`** to **1.0** for a deterministic assert.
static func _run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "feint_dodge_eval: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	if not parts.has("left_leg"):
		_fail(failures, "feint_dodge_eval: fixture needs left_leg in targetable")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
	}
	seed(1337)
	var dc: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	if str(dc.get("dodge_eval_part", "")) != "left_leg":
		_fail(
			failures,
			"feint_dodge_eval: want dodge_eval_part left_leg (telegraph bait) got %s" % str(dc.get("dodge_eval_part", ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`feint_guard_zone_readiness_spacing_mult`** on **`pr_rt`** for **`_feint_guard_reads_real_line`** in **`_apply_feint_telegraph_bias_to_dodge_eval_part`** — defensive **`guard`** × **`STANCE_MOD_FEINT_READTHROUGH`** fails at **MID** (**`DISTANCE_MID`**) but clears at **LONG** (**`FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG`**). Same global **`seed(s)`** before each **`choose_defense`**: **LONG** keeps the initial **`BodyPartConstants.get_weighted_random_part`** draw (scan for **≠** **`left_leg`**); **MID** with harness bias **1.0** always telegraphs **`dodge_eval_part`** to **`feint_part`**.
static func _run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "defensive"
	defender["guard"] = 0.83
	defender["state"] = CombatConstants.STATE_WAITING
	defender["stamina"] = CombatConstants.STAMINA_MAX
	var dm: Dictionary = _EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty() or not parts.has("left_leg"):
		_fail(failures, "feint_tele_dodge_gz_spacing: need left_leg in targetable")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 1.0,
	}
	var found_seed: int = -1
	var initial_part: String = ""
	for s in range(0, 65536):
		seed(s)
		dm[atk_id] = CombatConstants.DISTANCE_LONG
		var dc_l: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		var p_l: String = str(dc_l.get("dodge_eval_part", ""))
		if p_l == "left_leg":
			continue
		seed(s)
		dm[atk_id] = CombatConstants.DISTANCE_MID
		var dc_m: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		if str(dc_m.get("dodge_eval_part", "")) == "left_leg":
			found_seed = s
			initial_part = p_l
			break
	if found_seed < 0:
		_fail(failures, "feint_tele_dodge_gz_spacing: no seed in 0..65535 yields non-left_leg initial at LONG + telegraph left_leg at MID")
		_free_manager_restore_global_rng(mgr)
		return
	seed(found_seed)
	dm[atk_id] = CombatConstants.DISTANCE_LONG
	var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	seed(found_seed)
	dm[atk_id] = CombatConstants.DISTANCE_MID
	var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
	if str(dc_mid.get("dodge_eval_part", "")) != "left_leg":
		_fail(
			failures,
			"feint_tele_dodge_gz_spacing: mid want left_leg got %s (seed=%d)" % [str(dc_mid.get("dodge_eval_part", "")), found_seed]
		)
	if str(dc_long.get("dodge_eval_part", "")) != initial_part or initial_part == "left_leg":
		_fail(
			failures,
			"feint_tele_dodge_gz_spacing: long want initial %s got %s (seed=%d)"
			% [initial_part, str(dc_long.get("dodge_eval_part", "")), found_seed]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: LONG **`distance_to[attacker]`** scales feint dodge telegraph bias down vs MID (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG`**) so the same RNG draw can take telegraph bite at MID but not at LONG.
static func _run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty() or not parts.has("left_leg"):
		_fail(failures, "feint_telegraph_spacing: need left_leg in targetable")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
	}
	var eff_mid: float = 0.85
	var eff_long: float = 0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_LONG
	var de_mid: String = ""
	var de_long: String = ""
	var ok_spacing: bool = false
	for s in range(0, 65536):
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
		var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
		var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		de_mid = str(dc_mid.get("dodge_eval_part", ""))
		de_long = str(dc_long.get("dodge_eval_part", ""))
		if de_mid == "left_leg" and de_long != "left_leg":
			ok_spacing = true
			break
	if not ok_spacing:
		_fail(
			failures,
			"feint_telegraph_spacing: no seed in 0..65535 with mid=left_leg long!=left_leg (eff_mid=%.4f eff_long=%.4f last mid=%s long=%s)"
			% [eff_mid, eff_long, de_mid, de_long]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: CLOSE **`distance_to[attacker]`** scales feint dodge telegraph bias up vs MID (**`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE`**) so the same RNG draw can skip telegraph bite at MID but take it at CLOSE.
static func _run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty() or not parts.has("left_leg"):
		_fail(failures, "feint_telegraph_spacing_close: need left_leg in targetable")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "left_leg",
		"target_part": "chest",
		"intensity": 0.6,
		"wind_up_duration": 1.0,
		"tactical_ambush_mult": 1.0,
		CombatConstants.PA_KEY_HARNESS_FEINT_DODGE_EVAL_BIAS: 0.85,
	}
	var eff_mid: float = 0.85
	var eff_close: float = clampf(
		0.85 * CombatConstants.FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_MULT_CLOSE, 0.0, 1.0
	)
	var de_mid: String = ""
	var de_close: String = ""
	var ok_spacing: bool = false
	for s in range(0, 65536):
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
		var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		seed(s)
		_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
		var dc_close: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau_feint", arch, -1.0)
		de_mid = str(dc_mid.get("dodge_eval_part", ""))
		de_close = str(dc_close.get("dodge_eval_part", ""))
		if de_mid != "left_leg" and de_close == "left_leg":
			ok_spacing = true
			break
	if not ok_spacing:
		_fail(
			failures,
			"feint_telegraph_spacing_close: no seed in 0..65535 with mid!=left_leg close=left_leg (eff_mid=%.4f eff_close=%.4f last mid=%s close=%s)"
			% [eff_mid, eff_close, de_mid, de_close]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: non-empty **`feint_part`** → **`CombatConstants.COMMITMENT_FRACTION_FEINT`** — same **`wind_up_duration`** and defender **`reaction_time`** can yield on-time plain parry vs late feint parry (bracket duration between the two **`effective_wind_up`** thresholds).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "feint_commitment: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_plain: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_plain: Dictionary = WeaponConstants.get_archetype(
		str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var move_feint: Dictionary = WeaponConstants.get_move("oberhau_feint")
	var arch_feint: Dictionary = WeaponConstants.get_archetype(
		str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var r_time: float = def_n.get_passive_parry_reaction_time()
	var cf: float = CombatConstants.COMMITMENT_FRACTION
	var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
	var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
	var eff_plain: float = w_up * (1.0 - cf)
	var eff_feint: float = w_up * (1.0 - cff)
	if eff_plain <= r_time or eff_feint >= r_time:
		_fail(
			failures,
			"feint_commitment: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
			% [r_time, w_up, eff_plain, eff_feint]
		)
		_free_manager_restore_global_rng(mgr)
		return
	var pa_plain: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	var pa_feint: Dictionary = {
		"attack_type": "oberhau_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	seed(44002)
	var dc_plain: Dictionary = _DefenseChoice.choose_defense(
		pa_plain, attacker, defender, parts, "oberhau", arch_plain, -1.0
	)
	seed(44002)
	var dc_feint: Dictionary = _DefenseChoice.choose_defense(
		pa_feint, attacker, defender, parts, "oberhau_feint", arch_feint, -1.0
	)
	if bool(dc_plain.get("late_parry", false)):
		_fail(
			failures,
			"feint_commitment: plain oberhau want on-time parry late_parry=false got late=%s"
			% str(dc_plain.get("late_parry", false))
		)
	elif not bool(dc_feint.get("late_parry", false)):
		_fail(
			failures,
			"feint_commitment: feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 tempo: same bracket as **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, for **`thrust`** vs **`thrust_feint`** (**stab** archetypes).
static func _run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["stance"] = "balanced"
	defender["guard"] = 0.5
	defender["state"] = CombatConstants.STATE_WAITING
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "feint_commitment_thrust: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_plain: Dictionary = WeaponConstants.get_move("thrust")
	var arch_plain: Dictionary = WeaponConstants.get_archetype(
		str(move_plain.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var move_feint: Dictionary = WeaponConstants.get_move("thrust_feint")
	var arch_feint: Dictionary = WeaponConstants.get_archetype(
		str(move_feint.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var r_time: float = def_n.get_passive_parry_reaction_time()
	var cf: float = CombatConstants.COMMITMENT_FRACTION
	var cff: float = CombatConstants.COMMITMENT_FRACTION_FEINT
	var w_up: float = (r_time / maxf(1e-6, 1.0 - cf) + r_time / maxf(1e-6, 1.0 - cff)) * 0.5
	var eff_plain: float = w_up * (1.0 - cf)
	var eff_feint: float = w_up * (1.0 - cff)
	if eff_plain <= r_time or eff_feint >= r_time:
		_fail(
			failures,
			"feint_commitment_thrust: bracket r=%.4f w=%.4f eff_plain=%.4f eff_feint=%.4f want plain>r feint<r"
			% [r_time, w_up, eff_plain, eff_feint]
		)
		_free_manager_restore_global_rng(mgr)
		return
	var pa_plain: Dictionary = {
		"attack_type": "thrust",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	var pa_feint: Dictionary = {
		"attack_type": "thrust_feint",
		"feint_part": "head",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": w_up,
		"tactical_ambush_mult": 1.0,
	}
	seed(44002)
	var dc_plain: Dictionary = _DefenseChoice.choose_defense(
		pa_plain, attacker, defender, parts, "thrust", arch_plain, -1.0
	)
	seed(44002)
	var dc_feint: Dictionary = _DefenseChoice.choose_defense(
		pa_feint, attacker, defender, parts, "thrust_feint", arch_feint, -1.0
	)
	if bool(dc_plain.get("late_parry", false)):
		_fail(
			failures,
			"feint_commitment_thrust: plain thrust want on-time parry late_parry=false got late=%s"
			% str(dc_plain.get("late_parry", false))
		)
	elif not bool(dc_feint.get("late_parry", false)):
		_fail(
			failures,
			"feint_commitment_thrust: thrust_feint want late_parry=true got late=%s" % str(dc_feint.get("late_parry", false))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork: **`DefenseChoiceResolver.choose_defense`** — defender **`distance_to[attacker]`** scales **`parry_c_d`** (CLOSE / LONG vs MID) and **`dodge_chance`** at CLOSE / LONG (**`CombatConstants.DEFENSE_SPACING_*`**).
static func _run_defense_spacing_band_modulates_parry_and_dodge(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_spacing: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91001)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var dc_mid: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91001)
	var dc_long: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var cd_mid: float = float(dc_mid.get("parry_c_d", 0.0))
	var cd_long: float = float(dc_long.get("parry_c_d", 0.0))
	var dodge_mid: float = float(dc_mid.get("dodge_chance", 0.0))
	var dodge_long: float = float(dc_long.get("dodge_chance", 0.0))
	if cd_mid < 1.0:
		_fail(failures, "defense_spacing: mid parry_c_d too small %.3f" % cd_mid)
	elif not is_equal_approx(cd_long / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG):
		_fail(
			failures,
			"defense_spacing: parry_c_d long/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_PARRY_MULT_LONG, cd_long / cd_mid]
		)
	elif dodge_mid <= 1e-6:
		_fail(failures, "defense_spacing: mid dodge_chance too small")
	elif not is_equal_approx(dodge_long / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		_fail(
			failures,
			"defense_spacing: dodge long/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, dodge_long / dodge_mid]
		)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91001)
	var dc_close: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var cd_close: float = float(dc_close.get("parry_c_d", 0.0))
	var dodge_close: float = float(dc_close.get("dodge_chance", 0.0))
	if not is_equal_approx(cd_close / cd_mid, CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE):
		_fail(
			failures,
			"defense_spacing: parry_c_d close/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_PARRY_MULT_CLOSE, cd_close / cd_mid]
		)
	elif not is_equal_approx(dodge_close / dodge_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		_fail(
			failures,
			"defense_spacing: dodge close/mid want ratio %.3f got %.3f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, dodge_close / dodge_mid]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** defender gets recovering dodge mult vs off-balance **`STATE_WAITING`** baseline (no settled waiting-footwork mult).
static func _run_defense_footwork_recovering_boosts_dodge_vs_waiting(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_footwork_recovering: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91002)
	var dc_wait: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	seed(91002)
	var dc_rec: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
	var d_wait: float = float(dc_wait.get("dodge_chance", 0.0))
	var d_rec: float = float(dc_rec.get("dodge_chance", 0.0))
	if d_wait <= 1e-6:
		_fail(failures, "defense_footwork_recovering: waiting dodge_chance too small %.6f" % d_wait)
	elif not is_equal_approx(
		d_rec / d_wait, CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
	):
		_fail(
			failures,
			"defense_footwork_recovering: dodge rec/wait want ratio %.3f got %.3f"
			% [
				CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit"),
				d_rec / d_wait,
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`recovery_cause`** selects **`CombatConstants.defense_footwork_recovering_dodge_mult_for_cause`** (**`DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE`**) on reported **`dodge_chance`**; **`attack_miss`** > **`attack_hit`** at same **`distance_to`** / seed.
static func _run_defense_footwork_recovery_cause_orders_recovering_dodge_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_footwork_cause: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91003)
	var d_wait: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	seed(91003)
	var d_hit: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["state"] = CombatConstants.STATE_WAITING
	defender["recovery_cause"] = "skip"
	defender["state_duration"] = 0.0
	defender["state_timer"] = 0.0
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_miss"
	seed(91003)
	var d_miss: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	var m_hit: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_hit")
	var m_miss: float = CombatConstants.defense_footwork_recovering_dodge_mult_for_cause("attack_miss")
	if d_wait <= 1e-6:
		_fail(failures, "defense_footwork_cause: waiting dodge_chance too small %.6f" % d_wait)
	elif not is_equal_approx(d_hit / d_wait, m_hit):
		_fail(
			failures,
			"defense_footwork_cause: hit rec/wait want %.4f got %.4f" % [m_hit, d_hit / d_wait]
		)
	elif not is_equal_approx(d_miss / d_wait, m_miss):
		_fail(
			failures,
			"defense_footwork_cause: miss rec/wait want %.4f got %.4f" % [m_miss, d_miss / d_wait]
		)
	elif not is_equal_approx(d_miss / d_hit, m_miss / m_hit):
		_fail(
			failures,
			"defense_footwork_cause: miss/hit ratio want %.4f got %.4f" % [m_miss / m_hit, d_miss / d_hit]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: **`STATE_RECOVERING`** — pair **`distance_to`** spacing (**`DEFENSE_SPACING_DODGE_MULT_*`**) multiplies before **`defense_footwork_recovering_dodge_mult_for_cause`**; LONG/CLOSE vs MID ratios match WAITING spacing harness at fixed cause.
static func _run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_RECOVERING
	defender["state_duration"] = 1.0
	defender["state_timer"] = 0.25
	defender["recovery_cause"] = "attack_hit"
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_footwork_rec_spacing: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91004)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var d_mid: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91004)
	var d_long: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91004)
	var d_close: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_mid <= 1e-6:
		_fail(failures, "defense_footwork_rec_spacing: mid dodge_chance too small %.6f" % d_mid)
	elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		_fail(
			failures,
			"defense_footwork_rec_spacing: long/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
		)
	elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		_fail(
			failures,
			"defense_footwork_rec_spacing: close/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** (not off-balance) gets **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`** on reported **`dodge_chance`** after spacing.
static func _run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = -1.0
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_footwork_waiting: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91005)
	var d_settled: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	defender["off_balance_until"] = _CombatTiming.now_seconds() + 10.0
	seed(91005)
	var d_off: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_off <= 1e-6:
		_fail(failures, "defense_footwork_waiting: off-balance dodge_chance too small %.6f" % d_off)
	elif not is_equal_approx(d_settled / d_off, CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT):
		_fail(
			failures,
			"defense_footwork_waiting: settled/off want ratio %.4f got %.4f"
			% [CombatConstants.DEFENSE_FOOTWORK_WAITING_DODGE_MULT, d_settled / d_off]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: settled **`STATE_WAITING`** — pair **`distance_to`** spacing multiplies before **`DEFENSE_FOOTWORK_WAITING_DODGE_MULT`**.
static func _run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.4
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	defender["state"] = CombatConstants.STATE_WAITING
	defender["off_balance_until"] = -1.0
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "defense_footwork_wait_spacing: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_def: Dictionary = WeaponConstants.get_move("oberhau")
	var arch: Dictionary = WeaponConstants.get_archetype(
		str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"target_part": "chest",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(91006)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var d_mid: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_LONG
	seed(91006)
	var d_long: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_CLOSE
	seed(91006)
	var d_close: float = float(
		_DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0).get("dodge_chance", 0.0)
	)
	if d_mid <= 1e-6:
		_fail(failures, "defense_footwork_wait_spacing: mid dodge_chance too small %.6f" % d_mid)
	elif not is_equal_approx(d_long / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG):
		_fail(
			failures,
			"defense_footwork_wait_spacing: long/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_LONG, d_long / d_mid]
		)
	elif not is_equal_approx(d_close / d_mid, CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE):
		_fail(
			failures,
			"defense_footwork_wait_spacing: close/mid want %.4f got %.4f"
			% [CombatConstants.DEFENSE_SPACING_DODGE_MULT_CLOSE, d_close / d_mid]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: incoming stab **`contact_type`** scales passive **`parry_readiness`** after guard (**`PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT`** vs cut baseline) in **`DefenseChoiceResolver.choose_defense`**.
static func _run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "incoming_contact_readiness: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_ober: Dictionary = WeaponConstants.get_archetype(
		str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var move_spear: Dictionary = WeaponConstants.get_move("spear_thrust")
	var arch_spear: Dictionary = WeaponConstants.get_archetype(
		str(move_spear.get("archetype_id", WeaponConstants.ARCHETYPE_STAB))
	)
	var pa_base: Dictionary = {
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(92001)
	var pa_cut: Dictionary = pa_base.duplicate()
	pa_cut["attack_type"] = "oberhau"
	var dc_cut: Dictionary = _DefenseChoice.choose_defense(pa_cut, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	var pa_stab: Dictionary = pa_base.duplicate()
	pa_stab["attack_type"] = "spear_thrust"
	seed(92001)
	var dc_stab: Dictionary = _DefenseChoice.choose_defense(pa_stab, attacker, defender, parts, "spear_thrust", arch_spear, -1.0)
	var pr_c: float = float(dc_cut.get("parry_readiness", -1.0))
	var pr_s: float = float(dc_stab.get("parry_readiness", -1.0))
	if pr_c <= 1e-6:
		_fail(failures, "incoming_contact_readiness: cut parry_readiness too small %.4f" % pr_c)
	elif not is_equal_approx(pr_s / pr_c, CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT):
		_fail(
			failures,
			"incoming_contact_readiness: stab/cut readiness ratio want %.4f got %.4f (pr_cut=%.4f pr_stab=%.4f)"
			% [CombatConstants.PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT, pr_s / pr_c, pr_c, pr_s]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2 footwork / tempo: defender **`stamina`** scales **`choose_defense`** **`parry_readiness`** (feint read-through / guard-zone / dodge telegraph) via **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** (**`DefenseChoiceResolver._defender_passive_readiness_stamina_mult`**), not the **`pr_base`** term in **`parry_c_d *= parry_capacity_mult * pr_base`**.
static func _run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var atk_id: int = _EntityAccess.id_int(attacker)
	defender["stance"] = "balanced"
	defender["guard"] = 0.44
	defender["state"] = CombatConstants.STATE_WAITING
	defender["guard_zone"] = "chest"
	defender["guard_line"] = "high"
	_EntityAccess.nested_dictionary_for_mutation(defender, "distance_to")[atk_id] = CombatConstants.DISTANCE_MID
	var def_n: Node = _EntityAccess.scene_node(defender)
	var parts: Array = (
		def_n.get_targetable_parts()
		if def_n != null and def_n.has_method("get_targetable_parts")
		else []
	)
	if parts.is_empty():
		_fail(failures, "def_stam_readiness: targetable parts empty")
		_free_manager_restore_global_rng(mgr)
		return
	defender["stamina"] = CombatConstants.STAMINA_MAX
	var move_ober: Dictionary = WeaponConstants.get_move("oberhau")
	var arch_ober: Dictionary = WeaponConstants.get_archetype(
		str(move_ober.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
	)
	var pa: Dictionary = {
		"attack_type": "oberhau",
		"intensity": 0.55,
		"wind_up_duration": 0.95,
		"tactical_ambush_mult": 1.0,
	}
	seed(92002)
	var dc_hi: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	defender["stamina"] = 0.0
	seed(92002)
	var dc_lo: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch_ober, -1.0)
	var pr_hi: float = float(dc_hi.get("parry_readiness", -1.0))
	var pr_lo: float = float(dc_lo.get("parry_readiness", -1.0))
	var want: float = lerpf(
		CombatConstants.STAMINA_AT_ZERO_PARRY_MULT,
		1.0,
		CombatConstants.stamina_factor(0.0)
	) / lerpf(
		CombatConstants.STAMINA_AT_ZERO_PARRY_MULT,
		1.0,
		CombatConstants.stamina_factor(1.0)
	)
	if pr_hi <= 1e-6:
		_fail(failures, "def_stam_readiness: full-stamina parry_readiness too small %.4f" % pr_hi)
	elif not is_equal_approx(pr_lo / pr_hi, want):
		_fail(
			failures,
			"def_stam_readiness: low/full readiness ratio want %.4f got %.4f (pr_lo=%.4f pr_hi=%.4f)"
			% [want, pr_lo / pr_hi, pr_lo, pr_hi]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — feint listing applies **`passive_parry_readiness_incoming_contact_mult`** to defender readiness: stab feint (**`thrust_feint`**) vs cut feint (**`oberhau_feint`**) at defender **`guard`** **1.0** (**SWORD** 1v1).
static func _run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var enemy: Dictionary = mgr.combatants[1]
	mgr._recompute_zoc_and_distance()
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 1.0
	if not WeaponConstants.is_feint_move("thrust_feint"):
		_fail(failures, "feint_list_incoming_ct: thrust_feint should register as is_feint")
		_free_manager_restore_global_rng(mgr)
		return
	var a_plain_c: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint_c: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	var a_plain_s: Dictionary = {"move_id": "thrust", "target_id": e_id}
	var a_feint_s: Dictionary = {"move_id": "thrust_feint", "target_id": e_id}
	var wpc: float = _AIPicker._get_action_weight(a_plain_c, p_id, mgr, true)
	var wfc: float = _AIPicker._get_action_weight(a_feint_c, p_id, mgr, true)
	var wps: float = _AIPicker._get_action_weight(a_plain_s, p_id, mgr, true)
	var wfs: float = _AIPicker._get_action_weight(a_feint_s, p_id, mgr, true)
	if wpc <= 1e-8 or wps <= 1e-8:
		_fail(failures, "feint_list_incoming_ct: plain weights too small pc=%.8f ps=%.8f" % [wpc, wps])
		_free_manager_restore_global_rng(mgr)
		return
	var boost_c: float = wfc / wpc
	var boost_s: float = wfs / wps
	if boost_s >= boost_c - 1e-5:
		_fail(
			failures,
			"feint_list_incoming_ct: stab feint/thrust plain boost %.6f should be < cut feint/oberhau plain %.6f"
			% [boost_s, boost_c]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatAIActionPicker._get_action_weight`** — feint listing defender readiness matches **`CombatConstants.defender_passive_readiness_stamina_mult_from_ratio`** after passive × incoming **`contact_type`** ( **`w_feint_lo` / `w_feint_hi` == read_m ratio**; attacker stamina full).
static func _run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	player["stance"] = CombatConstants.STANCE_BALANCED
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.44
	mgr._recompute_zoc_and_distance()
	var ct_mv: String = str(
		WeaponConstants.get_move("oberhau_feint").get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
	)
	var pr_base: float = clampf(_PassiveParryCtx.get_passive_parry_readiness(enemy), 0.0, 1.0)
	pr_base = clampf(
		pr_base * CombatConstants.passive_parry_readiness_incoming_contact_mult(ct_mv), 0.0, 1.0
	)
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var pr_hi: float = clampf(
		pr_base
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var read_hi: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_hi
	)
	enemy["stamina"] = 0.0
	var pr_lo: float = clampf(
		pr_base
		* CombatConstants.defender_passive_readiness_stamina_mult_from_ratio(
			_EntityAccess.stamina_float(enemy) / CombatConstants.STAMINA_MAX
		),
		0.0,
		1.0
	)
	var read_lo: float = lerpf(
		1.0, CombatConstants.AI_FEINT_LISTING_DEFENDER_READINESS_TOP_MULT, pr_lo
	)
	var want: float = read_lo / read_hi
	var a_plain: Dictionary = {"move_id": "oberhau", "target_id": e_id}
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	var w_plain_hi: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_hi: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	enemy["stamina"] = 0.0
	var w_plain_lo: float = _AIPicker._get_action_weight(a_plain, p_id, mgr, true)
	var w_feint_lo: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if not is_equal_approx(w_plain_lo, w_plain_hi):
		_fail(
			failures,
			"feint_list_def_stam: plain weight should not depend on defender stamina lo=%.6f hi=%.6f"
			% [w_plain_lo, w_plain_hi]
		)
	elif w_feint_hi <= 1e-8:
		_fail(failures, "feint_list_def_stam: full-stamina feint weight too small %.8f" % w_feint_hi)
	elif not is_equal_approx(w_feint_lo / w_feint_hi, want):
		_fail(
			failures,
			"feint_list_def_stam: feint weight ratio want %.6f got %.6f (w_lo=%.6f w_hi=%.6f)"
			% [want, w_feint_lo / w_feint_hi, w_feint_lo, w_feint_hi]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: defender low stamina on feint **`read_m`** × attacker low stamina on **`AI_FEINT_LISTING_STAMINA_*`** multiply independently (**`w_ll/w_ml` == `w_lm/w_mm`** for **`oberhau_feint`**).
static func _run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var player: Dictionary = mgr.combatants[0]
	var enemy: Dictionary = mgr.combatants[1]
	player["stance"] = CombatConstants.STANCE_BALANCED
	enemy["stance"] = CombatConstants.STANCE_BALANCED
	enemy["state"] = CombatConstants.STATE_WAITING
	enemy["guard"] = 0.44
	var a_feint: Dictionary = {"move_id": "oberhau_feint", "target_id": e_id}
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	mgr._recompute_zoc_and_distance()
	var w_mm: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	enemy["stamina"] = CombatConstants.STAMINA_MAX
	mgr._recompute_zoc_and_distance()
	var w_ml: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX
	enemy["stamina"] = 0.0
	mgr._recompute_zoc_and_distance()
	var w_lm: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	player["stamina"] = CombatConstants.STAMINA_MAX * 0.1
	enemy["stamina"] = 0.0
	mgr._recompute_zoc_and_distance()
	var w_ll: float = _AIPicker._get_action_weight(a_feint, p_id, mgr, true)
	if w_mm <= 1e-8 or w_ml <= 1e-8:
		_fail(
			failures,
			"feint_list_stam_ortho: feint weights too small mm=%.8f ml=%.8f" % [w_mm, w_ml]
		)
		_free_manager_restore_global_rng(mgr)
		return
	var lhs: float = w_ll / w_ml
	var rhs: float = w_lm / w_mm
	if not is_equal_approx(lhs, rhs):
		_fail(
			failures,
			"feint_list_stam_ortho: w_ll/w_ml %.6f vs w_lm/w_mm %.6f (mm=%.6f ml=%.6f lm=%.6f ll=%.6f)"
			% [lhs, rhs, w_mm, w_ml, w_lm, w_ll]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: second **`AttackWindUpStarter.start`** without resolve clears prior defender **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** then restamps for the new wind-up.
static func _run_feint_second_windup_clears_prior_telegraph_before_restamp(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "left_leg", "feint_part": "head"}
	)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		_fail(
			failures,
			"feint_rewind: first telegraph want head got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "right_leg", "feint_part": "chest"}
	)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "chest":
		_fail(
			failures,
			"feint_rewind: second telegraph want chest got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	if str(e.get("guard_zone", "")) != "chest":
		_fail(failures, "feint_rewind: second guard_zone telegraph want chest got %s" % str(e.get("guard_zone", "")))
	_free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.start`** erases **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on all combatants (second **`start()`** without re-**`register`**).
static func _run_feint_telegraph_scrubbed_on_combat_manager_restart(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(p)
	var e_id: int = _EntityAccess.id_int(e)
	e["guard_zone"] = "chest"
	seed(_FEINT_WINDUP_HARNESS_SEED)
	_WindUpStarter.start(
		mgr,
		p_id,
		e_id,
		"oberhau_feint",
		{"target_part": "left_leg", "feint_part": "head"}
	)
	if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
		_fail(
			failures,
			"feint_restart: expected telegraph head before second start got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if e.has(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART):
		_fail(
			failures,
			"feint_restart: second start should scrub incoming telegraph key got %s"
			% str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
		)
	_free_manager_restore_global_rng(mgr)


## Tier 4.1: `stance_ai_targeting_mult` orders defensive < balanced < aggressive. Plan: `docs/IMPLEMENTATION_ORDER.md` Tier 4.1 exit criteria.
static func _run_ai_targeting_stance_mult_ordering(failures: PackedStringArray) -> void:
	var m_def: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_DEFENSIVE})
	var m_bal: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_BALANCED})
	var m_agg: float = _TargetScoring.stance_ai_targeting_mult({"stance": CombatConstants.STANCE_AGGRESSIVE})
	if not (m_def < m_bal + 0.001 and m_bal < m_agg + 0.001):
		_fail(
			failures,
			"ai_targeting_stance: expected def<bal<agg got %.4f %.4f %.4f" % [m_def, m_bal, m_agg]
		)


## Tier 1.6: `hostile_pair_targeting_weight_mult` × **`AI_TARGETING_INCAP_HOSTILE_MULT`** vs incapacitated opponent (`CoreEntity` consciousness below threshold; dirty flag off so value sticks).
## Rank-0 pair must **not** be file-opposed: incap clears `is_file_opposed_rank0_pair`, which would otherwise drop the file-opposed mult and invalidate “only × incap”.
static func _run_ai_targeting_incap_hostile_mult(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy = _new_entity("SWORD")
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
	var p: Dictionary = mgr.combatants[0]
	var opp: Dictionary = mgr.combatants[1]
	p["file"] = 0
	opp["file"] = 1
	mgr._recompute_zoc_and_distance()
	var w_up: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
	if w_up <= 0.0:
		_fail(failures, "ai_incap: baseline hostile weight should be > 0")
		_free_manager(mgr)
		return
	ent_enemy.consciousness = 5.0
	var w_down: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, p, opp)
	var raw_down: float = w_up * CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT
	var expected_w: float = clampf(
		raw_down,
		CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MIN,
		CombatConstants.DOCTRINE_AI_WEIGHT_MULT_MAX
	)
	if not is_equal_approx(w_down, expected_w):
		_fail(
			failures,
			"ai_incap: expected down=%.6f ≈ clamp(up*mult)=%.6f (up=%.6f raw=%.6f mult=%.4f)"
			% [w_down, expected_w, w_up, raw_down, CombatConstants.AI_TARGETING_INCAP_HOSTILE_MULT]
		)
	if not _EntityAccess.is_incapacitated(opp):
		_fail(failures, "ai_incap: test setup failed — opponent should read as incapacitated")
	_free_manager(mgr)


## Tier 1.6: `AvailableActionsBuilder` does not list melee / `attempt_close` / crash vs incapacitated enemies.
static func _run_no_hostile_actions_listed_vs_incap_enemy(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy = _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = mgr.combatants[0]
	var e: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(e):
		_fail(failures, "incap_acts: enemy should be incapacitated for test")
		_free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var eid: int = _EntityAccess.id_int(e)
	var acts: Array = mgr.get_available_actions(pid)
	for a in acts:
		if int(a.get("target_id", -9)) != eid:
			continue
		var mid: String = str(a.get("move_id", ""))
		_fail(
			failures,
			"incap_acts: unexpected action vs incap enemy move_id=%s full=%s" % [mid, str(a)]
		)
		_free_manager(mgr)
		return
	_free_manager(mgr)


## Tier 1.6 / stalemate: all rank-0 enemies incap → `any_enemy_rank0` false → rank-1 pass may list vs deeper hostiles (no soft-lock).
static func _run_stalemate_melee_rank1_when_rank0_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_e0 = _new_entity("SWORD")
	ent_e0.consciousness = 5.0
	mgr.register(ent_e0, "enemy")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
	mgr._recompute_zoc_and_distance()
	var p: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) == "player":
			p = c
			break
	if p.is_empty():
		_fail(failures, "stalemate_incap: no player combatant after start")
		_free_manager(mgr)
		return
	var e0: Dictionary = {}
	var e1: Dictionary = {}
	for c in mgr.combatants:
		if _EntityAccess.side_str(c) != "enemy":
			continue
		var rr: int = _EntityAccess.rank_int(c)
		if rr == 0:
			e0 = c
		elif rr == 1:
			e1 = c
	if e0.is_empty() or e1.is_empty():
		_fail(failures, "stalemate_incap: missing enemy rank0 or rank1 after start")
		_free_manager(mgr)
		return
	if not _EntityAccess.is_incapacitated(e0) or _EntityAccess.is_incapacitated(e1):
		_fail(failures, "stalemate_incap: e0 should be incap, e1 upright")
		_free_manager(mgr)
		return
	var any_r0: bool = false
	for oc in mgr.combatants:
		if _EntityAccess.side_str(oc) == "player":
			continue
		if _EntityAccess.rank_int(oc) != 0:
			continue
		if _ActionsBuilder._opp_matches_melee_rank_target(mgr, p, oc, 0):
			any_r0 = true
			break
	if any_r0:
		_fail(failures, "stalemate_incap: expected no _opp_matches rank0 after incap")
		_free_manager(mgr)
		return
	p["gauge"] = 100.0
	p["state"] = CombatConstants.STATE_WAITING
	var pid: int = _EntityAccess.id_int(p)
	var e0id: int = _EntityAccess.id_int(e0)
	var e1id: int = _EntityAccess.id_int(e1)
	var acts: Array = mgr.get_available_actions(pid)
	for a in acts:
		if int(a.get("target_id", -9)) == e0id:
			_fail(failures, "stalemate_incap: should not list actions vs incap rank0 got %s" % str(a))
			_free_manager(mgr)
			return
	var seen_e1: bool = false
	for a in acts:
		if int(a.get("target_id", -9)) == e1id:
			seen_e1 = true
			break
	if not seen_e1:
		_fail(failures, "stalemate_incap: expected at least one action vs rank1 enemy acts=%s" % str(acts))
	_free_manager(mgr)


## Tier 3.2: weapon part mass fractions must cover the whole weapon; parry contact uses the intended part.
static func _run_weapon_part_mass_model_normalized(failures: PackedStringArray) -> void:
	for wid in WeaponConstants.get_all_weapon_ids():
		var weapon: Weapon = _Weapon.create_from_definition(wid)
		if weapon == null:
			_fail(failures, "weapon_parts: could not create %s" % wid)
			continue
		if not weapon.has_parts():
			_fail(failures, "weapon_parts: %s should define part model data" % wid)
			continue
		var total_fraction: float = 0.0
		for part in weapon.parts:
			if part is Dictionary:
				total_fraction += float((part as Dictionary).get("mass_fraction", 0.0))
		if absf(total_fraction - 1.0) > 0.001:
			_fail(failures, "weapon_parts: %s mass fractions sum %.3f, want 1.000" % [wid, total_fraction])
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if spear == null:
		_fail(failures, "weapon_parts: missing spear")
		return
	if spear.get_parry_contact_type() != "shaft":
		_fail(failures, "weapon_parts: spear should parry with shaft, got %s" % spear.get_parry_contact_type())
	var expected_spear_parry_mass: float = spear.mass * 0.85
	if absf(spear.get_parry_part_mass_kg() - expected_spear_parry_mass) > 0.001:
		_fail(
			failures,
			"weapon_parts: spear parry mass %.3f want %.3f"
			% [spear.get_parry_part_mass_kg(), expected_spear_parry_mass]
		)


## Tier 3.2: parry part id selection follows documented fallback order.
static func _run_weapon_parry_part_selection_fallbacks(failures: PackedStringArray) -> void:
	var parts: Array = [
		{"id": "head", "length_cm": 10, "mass_fraction": 0.65, "parry_eligible": false},
		{"id": "shaft", "length_cm": 60, "mass_fraction": 0.35, "parry_eligible": true}
	]
	var selector := Callable(_Weapon, "parry_part_id_from_parts")
	var preferred: String = str(selector.call(parts, " Shaft "))
	if preferred != "shaft":
		_fail(failures, "weapon_parry_part: normalized preferred id got %s want shaft" % preferred)
	var invalid_preferred: String = str(selector.call(parts, "head"))
	if invalid_preferred != "shaft":
		_fail(failures, "weapon_parry_part: non-eligible preferred should fallback to shaft got %s" % invalid_preferred)
	var missing_preferred: String = str(selector.call(parts, "blade"))
	if missing_preferred != "shaft":
		_fail(failures, "weapon_parry_part: missing preferred should fallback to shaft got %s" % missing_preferred)
	var no_eligible: Array = [
		{"id": "light", "length_cm": 10, "mass_fraction": 0.25, "parry_eligible": false},
		{"id": "heavy", "length_cm": 30, "mass_fraction": 0.75, "parry_eligible": false}
	]
	var largest: String = str(selector.call(no_eligible, ""))
	if largest != "heavy":
		_fail(failures, "weapon_parry_part: no eligible should fallback to largest mass got %s" % largest)


## Tier 3.2: attack momentum / KE helpers use the intended striking part mass.
static func _run_weapon_striking_part_mass_model(failures: PackedStringArray) -> void:
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	var axe: Weapon = _Weapon.create_from_definition("AXE")
	if spear == null or mace == null or axe == null:
		_fail(failures, "weapon_striking_parts: missing spear/mace/axe")
		return
	var spear_stab: float = spear.get_striking_part_mass_kg(" STAB ")
	var spear_blunt: float = spear.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_BLUNT)
	var mace_blunt: float = mace.get_striking_part_mass_kg("BLUNT")
	var axe_stab: float = axe.get_striking_part_mass_kg(WeaponConstants.ATTACK_TYPE_STAB)
	if absf(spear_stab - spear.mass * 0.15) > 0.001:
		_fail(failures, "weapon_striking_parts: spear stab mass %.3f want %.3f" % [spear_stab, spear.mass * 0.15])
	if absf(spear_blunt - spear.mass * 0.85) > 0.001:
		_fail(failures, "weapon_striking_parts: spear blunt mass %.3f want %.3f" % [spear_blunt, spear.mass * 0.85])
	if absf(mace_blunt - mace.mass * 0.7) > 0.001:
		_fail(failures, "weapon_striking_parts: mace blunt mass %.3f want %.3f" % [mace_blunt, mace.mass * 0.7])
	if absf(axe_stab - axe.mass * 0.15) > 0.001:
		_fail(failures, "weapon_striking_parts: axe stab mass %.3f want %.3f" % [axe_stab, axe.mass * 0.15])


## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference; **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move + intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE = **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode’s **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER** **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).
static func _run_kinematic_delivery_override_and_mixed_ke_blend_brackets_thrust_swing(
	failures: PackedStringArray
) -> void:
	var empty: Dictionary = {}
	if WeaponDamageHelper.kinematic_delivery(empty, "thrust") != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
		_fail(failures, "kin_del: empty arch + thrust move should infer thrust")
	if WeaponDamageHelper.kinematic_delivery(empty, "oberhau") != WeaponConstants.KINEMATIC_DELIVERY_SWING:
		_fail(failures, "kin_del: empty arch + cut move should infer swing")
	var arch_thrust_override: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	if WeaponDamageHelper.kinematic_delivery(arch_thrust_override, "oberhau") != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
		_fail(failures, "kin_del: thrust archetype should override cut move to thrust")
	var arch_swing_override: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	if WeaponDamageHelper.kinematic_delivery(arch_swing_override, "thrust") != WeaponConstants.KINEMATIC_DELIVERY_SWING:
		_fail(failures, "kin_del: swing archetype should override stab move to swing")
	if (
		WeaponDamageHelper.kinematic_delivery({"kinematic_delivery": "mixed"}, "thrust")
		!= WeaponConstants.KINEMATIC_DELIVERY_MIXED
	):
		_fail(failures, "kin_del: mixed archetype should win over stab inference")
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_del_mixed: missing sword")
		return
	const move_id: String = "oberhau"
	const inten: float = 0.55
	var ai_thrust: AttackInstance = AttackInstance.new(move_id, inten)
	ai_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var ai_swing: AttackInstance = AttackInstance.new(move_id, inten)
	ai_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var ai_mix0: AttackInstance = AttackInstance.new(move_id, inten)
	ai_mix0.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.0
	}
	var ai_mix1: AttackInstance = AttackInstance.new(move_id, inten)
	ai_mix1.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 1.0
	}
	var v_th: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_thrust)
	var v_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_swing)
	var v_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix0)
	var v_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix1)
	if absf(v_m0 - v_th) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 0 velocity %.6f should match thrust velocity %.6f" % [v_m0, v_th]
		)
	if absf(v_m1 - v_sw) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 1 velocity %.6f should match swing velocity %.6f" % [v_m1, v_sw]
		)
	var ai_mix_mid: AttackInstance = AttackInstance.new(move_id, inten)
	ai_mix_mid.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.5
	}
	var v_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix_mid)
	var want_mid_v: float = lerpf(v_th, v_sw, 0.5)
	if absf(v_mid - want_mid_v) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_mid, want_mid_v]
		)
	var ke_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_mid)
	var ai_th_pin: AttackInstance = AttackInstance.new(move_id, inten)
	ai_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	ai_th_pin.velocity_m_s = v_mid
	var ai_sw_pin: AttackInstance = AttackInstance.new(move_id, inten)
	ai_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_sw_pin.velocity_m_s = v_mid
	var ke_th_at_mid_v: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_th_pin)
	var ke_sw_at_mid_v: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_sw_pin)
	var want_ke_mid: float = lerpf(ke_th_at_mid_v, ke_sw_at_mid_v, 0.5)
	if absf(ke_mid - want_ke_mid) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
			% [ke_mid, want_ke_mid]
		)
	var ke_th: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_thrust)
	var ke_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_swing)
	var ke_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix0)
	var ke_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix1)
	if ke_th <= 0.05 or ke_sw <= 0.05:
		_fail(failures, "kin_del_mixed: expected positive KE thrust=%.4f swing=%.4f" % [ke_th, ke_sw])
	if absf(ke_m0 - ke_th) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_m0, ke_th]
		)
	if absf(ke_m1 - ke_sw) > 0.001:
		_fail(
			failures,
			"kin_del_mixed: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_m1, ke_sw]
		)
	## Second weapon: AXE + diagonal_chop (cut) — same mixed brackets (Tier 5.1); avoids **`spear_slash`** thrust/swing KE degeneracy at some intensities.
	var axe: Weapon = _Weapon.create_from_definition("AXE")
	if axe == null:
		_fail(failures, "kin_del_axe: missing axe")
		return
	const move_chop: String = "diagonal_chop"
	var ai_ax_thrust: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var ai_ax_swing: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var ai_ax_m0: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_m0.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.0
	}
	var ai_ax_m1: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_m1.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 1.0
	}
	var v_ax_th: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_thrust)
	var v_ax_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_swing)
	var v_ax_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m0)
	var v_ax_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m1)
	if absf(v_ax_m0 - v_ax_th) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_ax_m0, v_ax_th]
		)
	if absf(v_ax_m1 - v_ax_sw) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 1 velocity %.6f should match swing %.6f" % [v_ax_m1, v_ax_sw]
		)
	var ai_ax_mid: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_mid.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.5
	}
	var v_ax_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_mid)
	var want_ax_mid_v: float = lerpf(v_ax_th, v_ax_sw, 0.5)
	if absf(v_ax_mid - want_ax_mid_v) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_ax_mid, want_ax_mid_v]
		)
	var ke_ax_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_mid)
	var ai_ax_th_pin: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	ai_ax_th_pin.velocity_m_s = v_ax_mid
	var ai_ax_sw_pin: AttackInstance = AttackInstance.new(move_chop, inten)
	ai_ax_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_ax_sw_pin.velocity_m_s = v_ax_mid
	var ke_ax_th_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_th_pin)
	var ke_ax_sw_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_sw_pin)
	var want_ax_ke_mid: float = lerpf(ke_ax_th_at_mid, ke_ax_sw_at_mid, 0.5)
	if absf(ke_ax_mid - want_ax_ke_mid) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
			% [ke_ax_mid, want_ax_ke_mid]
		)
	var ke_ax_th: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_thrust)
	var ke_ax_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_swing)
	var ke_ax_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m0)
	var ke_ax_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m1)
	if ke_ax_th <= 0.05 or ke_ax_sw <= 0.05:
		_fail(failures, "kin_del_axe: expected positive KE thrust=%.4f swing=%.4f" % [ke_ax_th, ke_ax_sw])
	if absf(ke_ax_m0 - ke_ax_th) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_ax_m0, ke_ax_th]
		)
	if absf(ke_ax_m1 - ke_ax_sw) > 0.001:
		_fail(
			failures,
			"kin_del_axe: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_ax_m1, ke_ax_sw]
		)
	## Third weapon: DAGGER + quick_slash (cut) — same mixed brackets (Tier 5.1 light weapon coverage).
	var dagger: Weapon = _Weapon.create_from_definition("DAGGER")
	if dagger == null:
		_fail(failures, "kin_del_dagger: missing dagger")
		return
	const move_slash: String = "quick_slash"
	var ai_dg_thrust: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var ai_dg_swing: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var ai_dg_m0: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_m0.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.0
	}
	var ai_dg_m1: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_m1.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 1.0
	}
	var v_dg_th: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_thrust)
	var v_dg_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_swing)
	var v_dg_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m0)
	var v_dg_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m1)
	if absf(v_dg_m0 - v_dg_th) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_dg_m0, v_dg_th]
		)
	if absf(v_dg_m1 - v_dg_sw) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 1 velocity %.6f should match swing %.6f" % [v_dg_m1, v_dg_sw]
		)
	var ai_dg_mid: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_mid.archetype = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.5
	}
	var v_dg_mid: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_mid)
	var want_dg_mid_v: float = lerpf(v_dg_th, v_dg_sw, 0.5)
	if absf(v_dg_mid - want_dg_mid_v) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 0.5 velocity %.6f want lerp(thrust,swing,0.5)=%.6f" % [v_dg_mid, want_dg_mid_v]
		)
	var ke_dg_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_mid)
	var ai_dg_th_pin: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_th_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	ai_dg_th_pin.velocity_m_s = v_dg_mid
	var ai_dg_sw_pin: AttackInstance = AttackInstance.new(move_slash, inten)
	ai_dg_sw_pin.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_dg_sw_pin.velocity_m_s = v_dg_mid
	var ke_dg_th_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_th_pin)
	var ke_dg_sw_at_mid: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_sw_pin)
	var want_dg_ke_mid: float = lerpf(ke_dg_th_at_mid, ke_dg_sw_at_mid, 0.5)
	if absf(ke_dg_mid - want_dg_ke_mid) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
			% [ke_dg_mid, want_dg_ke_mid]
		)
	var ke_dg_th: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_thrust)
	var ke_dg_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_swing)
	var ke_dg_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m0)
	var ke_dg_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m1)
	if ke_dg_th <= 0.05 or ke_dg_sw <= 0.05:
		_fail(failures, "kin_del_dagger: expected positive KE thrust=%.4f swing=%.4f" % [ke_dg_th, ke_dg_sw])
	if absf(ke_dg_m0 - ke_dg_th) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_dg_m0, ke_dg_th]
		)
	if absf(ke_dg_m1 - ke_dg_sw) > 0.001:
		_fail(
			failures,
			"kin_del_dagger: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_dg_m1, ke_dg_sw]
		)


## Tier 5.1: **`velocity_m_s_from_intensity`** must match **`get_effective_velocity_m_s`** when **`AttackInstance.velocity_m_s` < 0** (derived path). Intensity **0.05 → 0.95** increases speed where expected: **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (inferred swing, thrust override, mixed **`kinematic_mixed_blend` 0.35**), **SPEAR** **`spear_thrust`** (inferred thrust), **MACE** **`direct_blow`** (blunt → swing path).
static func _run_kinematic_delivery_velocity_from_intensity_bridges_get_effective_and_monotone(
	failures: PackedStringArray
) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_vel_bridge: missing sword")
		return
	const move_id: String = "oberhau"
	const arch_empty: Dictionary = {}
	const arch_thrust: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	const arch_mixed: Dictionary = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.35
	}
	for inten in [0.22, 0.78]:
		var ai: AttackInstance = AttackInstance.new(move_id, inten)
		ai.archetype = arch_empty
		var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_empty, sword, move_id)
		var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai)
		if absf(v_eff - v_from_i) > 0.001:
			_fail(
				failures,
				"kin_vel_bridge: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
				% [inten, v_eff, v_from_i]
			)
		var ai_t: AttackInstance = AttackInstance.new(move_id, inten)
		ai_t.archetype = arch_thrust
		var v_t_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_thrust, sword, move_id)
		var v_t_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_t)
		if absf(v_t_e - v_t_i) > 0.001:
			_fail(
				failures,
				"kin_vel_bridge: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
				% [inten, v_t_e, v_t_i]
			)
		var ai_m: AttackInstance = AttackInstance.new(move_id, inten)
		ai_m.archetype = arch_mixed
		var v_m_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_mixed, sword, move_id)
		var v_m_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_m)
		if absf(v_m_e - v_m_i) > 0.001:
			_fail(
				failures,
				"kin_vel_bridge: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
				% [inten, v_m_e, v_m_i]
			)
	var v_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, sword, move_id)
	var v_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, sword, move_id)
	if v_sw_lo > v_sw_hi + 0.0001:
		_fail(
			failures,
			"kin_vel_mono: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [v_sw_lo, v_sw_hi]
		)
	if v_sw_hi - v_sw_lo < 0.01:
		_fail(
			failures,
			"kin_vel_mono: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sw_hi - v_sw_lo]
		)
	var v_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, sword, move_id)
	var v_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, sword, move_id)
	if v_th_lo > v_th_hi + 0.0001:
		_fail(
			failures,
			"kin_vel_mono: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [v_th_lo, v_th_hi]
		)
	if v_th_hi - v_th_lo < 0.01:
		_fail(
			failures,
			"kin_vel_mono: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_th_hi - v_th_lo]
		)
	var v_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, sword, move_id)
	var v_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, sword, move_id)
	if v_mx_lo > v_mx_hi + 0.0001:
		_fail(
			failures,
			"kin_vel_mono: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [v_mx_lo, v_mx_hi]
		)
	if v_mx_hi - v_mx_lo < 0.01:
		_fail(
			failures,
			"kin_vel_mono: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mx_hi - v_mx_lo]
		)
	## Stab-inferred thrust: SPEAR + spear_thrust (linear band).
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if spear == null:
		_fail(failures, "kin_vel_bridge: missing spear")
		return
	const move_spear: String = "spear_thrust"
	for inten_sp in [0.31, 0.69]:
		var ai_sp: AttackInstance = AttackInstance.new(move_spear, inten_sp)
		ai_sp.archetype = arch_empty
		var v_sp_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_sp, arch_empty, spear, move_spear)
		var v_sp_e: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, ai_sp)
		if absf(v_sp_e - v_sp_i) > 0.001:
			_fail(
				failures,
				"kin_vel_bridge: spear thrust inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
				% [inten_sp, v_sp_e, v_sp_i]
			)
	var v_sp_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, spear, move_spear)
	var v_sp_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, spear, move_spear)
	if v_sp_lo > v_sp_hi + 0.0001:
		_fail(
			failures,
			"kin_vel_mono: spear thrust v(0.05)=%.6f > v(0.95)=%.6f" % [v_sp_lo, v_sp_hi]
		)
	if v_sp_hi - v_sp_lo < 0.01:
		_fail(
			failures,
			"kin_vel_mono: spear thrust expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sp_hi - v_sp_lo]
		)
	## Blunt contact → swing kinematic path: MACE + direct_blow.
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	if mace == null:
		_fail(failures, "kin_vel_bridge: missing mace")
		return
	const move_mace: String = "direct_blow"
	for inten_mc in [0.28, 0.72]:
		var ai_mc: AttackInstance = AttackInstance.new(move_mace, inten_mc)
		ai_mc.archetype = arch_empty
		var v_mc_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_mc, arch_empty, mace, move_mace)
		var v_mc_e: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, ai_mc)
		if absf(v_mc_e - v_mc_i) > 0.001:
			_fail(
				failures,
				"kin_vel_bridge: mace blunt inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
				% [inten_mc, v_mc_e, v_mc_i]
			)
	var v_mc_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, mace, move_mace)
	var v_mc_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, mace, move_mace)
	if v_mc_lo > v_mc_hi + 0.0001:
		_fail(
			failures,
			"kin_vel_mono: mace blunt v(0.05)=%.6f > v(0.95)=%.6f" % [v_mc_lo, v_mc_hi]
		)
	if v_mc_hi - v_mc_lo < 0.01:
		_fail(
			failures,
			"kin_vel_mono: mace blunt expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mc_hi - v_mc_lo]
		)
	for blade_spec: Dictionary in [
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_vel_ax"},
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_vel_dg"},
	]:
		var w_b: Weapon = _Weapon.create_from_definition(str(blade_spec["def"]))
		if w_b == null:
			_fail(failures, "%s: missing %s" % [str(blade_spec["pfx"]), str(blade_spec["def"])])
			return
		var m_b: String = str(blade_spec["move"])
		var tag: String = str(blade_spec["pfx"])
		for inten_b in [0.22, 0.78]:
			var ai_b: AttackInstance = AttackInstance.new(m_b, inten_b)
			ai_b.archetype = arch_empty
			var vfi: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_empty, w_b, m_b)
			var vfe: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_b)
			if absf(vfe - vfi) > 0.001:
				_fail(
					failures,
					"%s: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
					% [tag, inten_b, vfe, vfi]
				)
			var ai_bt: AttackInstance = AttackInstance.new(m_b, inten_b)
			ai_bt.archetype = arch_thrust
			var vti: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_thrust, w_b, m_b)
			var vte: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bt)
			if absf(vte - vti) > 0.001:
				_fail(
					failures,
					"%s: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
					% [tag, inten_b, vte, vti]
				)
			var ai_bm: AttackInstance = AttackInstance.new(m_b, inten_b)
			ai_bm.archetype = arch_mixed
			var vmi: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_mixed, w_b, m_b)
			var vme: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bm)
			if absf(vme - vmi) > 0.001:
				_fail(
					failures,
					"%s: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
					% [tag, inten_b, vme, vmi]
				)
		var vb_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, w_b, m_b)
		var vb_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, w_b, m_b)
		if vb_sw_lo > vb_sw_hi + 0.0001:
			_fail(
				failures,
				"%s: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_sw_lo, vb_sw_hi]
			)
		if vb_sw_hi - vb_sw_lo < 0.01:
			_fail(
				failures,
				"%s: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_sw_hi - vb_sw_lo]
			)
		var vb_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, w_b, m_b)
		var vb_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, w_b, m_b)
		if vb_th_lo > vb_th_hi + 0.0001:
			_fail(
				failures,
				"%s: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_th_lo, vb_th_hi]
			)
		if vb_th_hi - vb_th_lo < 0.01:
			_fail(
				failures,
				"%s: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_th_hi - vb_th_lo]
			)
		var vb_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, w_b, m_b)
		var vb_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, w_b, m_b)
		if vb_mx_lo > vb_mx_hi + 0.0001:
			_fail(
				failures,
				"%s: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_mx_lo, vb_mx_hi]
			)
		if vb_mx_hi - vb_mx_lo < 0.01:
			_fail(
				failures,
				"%s: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_mx_hi - vb_mx_lo]
			)


## Tier 5.1: **`compute_pre_armor_cut`** scales with **`sqrt(KE)`** at fixed strength/**`arm_mod`** when **`velocity_m_s`** pins tip speed (no clamp skew) — **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing). **`compute_pre_armor_blunt`** rises with pinned speed on **MACE** **`direct_blow`** (momentum path).
static func _run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(
	failures: PackedStringArray
) -> void:
	const strength: float = 100.0
	const arm_mod: float = 1.0
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_pre_armor: missing sword")
		return
	const move_cut: String = "oberhau"
	var ai_lo: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_lo.velocity_m_s = 8.0
	var ai_hi: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_hi.velocity_m_s = 15.0
	var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
	var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
	var cut_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo, strength, arm_mod)
	var cut_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi, strength, arm_mod)
	if ke_hi <= ke_lo + 1e-4:
		_fail(failures, "kin_pre_armor_cut: expected ke_hi > ke_lo got lo=%.4f hi=%.4f" % [ke_lo, ke_hi])
	if cut_hi <= cut_lo + 1e-4:
		_fail(
			failures,
			"kin_pre_armor_cut: cut_hi should exceed cut_lo (got lo=%.4f hi=%.4f)" % [cut_lo, cut_hi]
		)
	var want_ratio: float = sqrt(ke_hi / ke_lo)
	var got_ratio: float = cut_hi / cut_lo
	if absf(got_ratio - want_ratio) > 0.03:
		_fail(
			failures,
			"kin_pre_armor_cut: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
			% [got_ratio, want_ratio, ke_lo, ke_hi]
		)
	const arch_swing_cut: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	for cfx: Dictionary in [
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_pre_armor_cut_ax", "v_lo": 8.0, "v_hi": 15.0},
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_pre_armor_cut_dg", "v_lo": 8.0, "v_hi": 15.0},
	]:
		var w_c: Weapon = _Weapon.create_from_definition(str(cfx["def"]))
		if w_c == null:
			_fail(failures, "%s: missing %s" % [str(cfx["pfx"]), str(cfx["def"])])
			return
		var m_c: String = str(cfx["move"])
		var pfx_c: String = str(cfx["pfx"])
		var v_lo_c: float = float(cfx["v_lo"])
		var v_hi_c: float = float(cfx["v_hi"])
		var c_lo: AttackInstance = AttackInstance.new(m_c, 0.5)
		c_lo.archetype = arch_swing_cut
		c_lo.velocity_m_s = v_lo_c
		var c_hi: AttackInstance = AttackInstance.new(m_c, 0.5)
		c_hi.archetype = arch_swing_cut
		c_hi.velocity_m_s = v_hi_c
		var ke_lo_c: float = WeaponDamageHelper.compute_kinetic_energy_j(w_c, c_lo)
		var ke_hi_c: float = WeaponDamageHelper.compute_kinetic_energy_j(w_c, c_hi)
		var cut_lo_c: float = WeaponDamageHelper.compute_pre_armor_cut(w_c, c_lo, strength, arm_mod)
		var cut_hi_c: float = WeaponDamageHelper.compute_pre_armor_cut(w_c, c_hi, strength, arm_mod)
		if ke_hi_c <= ke_lo_c + 1e-4:
			_fail(
				failures,
				"%s: expected ke_hi > ke_lo got lo=%.4f hi=%.4f" % [pfx_c, ke_lo_c, ke_hi_c]
			)
		if cut_hi_c <= cut_lo_c + 1e-4:
			_fail(
				failures,
				"%s: cut_hi should exceed cut_lo (lo=%.4f hi=%.4f)" % [pfx_c, cut_lo_c, cut_hi_c]
			)
		var want_r_c: float = sqrt(ke_hi_c / ke_lo_c)
		var got_r_c: float = cut_hi_c / cut_lo_c
		if absf(got_r_c - want_r_c) > 0.03:
			_fail(
				failures,
				"%s: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
				% [pfx_c, got_r_c, want_r_c, ke_lo_c, ke_hi_c]
			)
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	if mace == null:
		_fail(failures, "kin_pre_armor: missing mace")
		return
	const move_blunt: String = "direct_blow"
	var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
	b_lo.velocity_m_s = 6.0
	var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
	b_hi.velocity_m_s = 14.0
	var blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo, strength, arm_mod)
	var blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi, strength, arm_mod)
	if blunt_hi <= blunt_lo + 1e-4:
		_fail(
			failures,
			"kin_pre_armor_blunt: blunt_hi should exceed blunt_lo (lo=%.4f hi=%.4f)" % [blunt_lo, blunt_hi]
		)


## Tier 5.1: **`compute_penetration`** — **SHARP** **`penetration_sharp`** scales as **`(KE / J_BASE)^PENETRATION_EXPONENT`** × area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.
static func _run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(
	failures: PackedStringArray
) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_pen: missing sword")
		return
	const move_cut: String = "oberhau"
	var ai_lo: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_lo.velocity_m_s = 9.0
	var ai_hi: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_hi.velocity_m_s = 16.0
	var ke_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo)
	var ke_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi)
	if ke_lo < 0.5:
		_fail(failures, "kin_pen_sharp: ke_lo unexpectedly small %.4f" % ke_lo)
	if ke_hi <= ke_lo + 1e-4:
		_fail(failures, "kin_pen_sharp: expected ke_hi > ke_lo lo=%.4f hi=%.4f" % [ke_lo, ke_hi])
	var pen_lo: float = float(
		WeaponDamageHelper.compute_penetration(sword, ai_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	var pen_hi: float = float(
		WeaponDamageHelper.compute_penetration(sword, ai_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	if pen_lo <= 0.0 or pen_hi <= pen_lo + 1e-6:
		_fail(failures, "kin_pen_sharp: expected rising pen lo=%.6f hi=%.6f" % [pen_lo, pen_hi])
	var want_ratio: float = pow(ke_hi / ke_lo, WeaponConstants.PENETRATION_EXPONENT)
	var got_ratio: float = pen_hi / pen_lo
	if absf(got_ratio - want_ratio) > 0.05:
		_fail(
			failures,
			"kin_pen_sharp: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
			% [got_ratio, want_ratio, ke_lo, ke_hi, WeaponConstants.PENETRATION_EXPONENT]
		)
	const arch_swing_pen: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	const pen_v_lo: float = 9.0
	const pen_v_hi: float = 16.0
	for pfx_row: Dictionary in [
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_pen_sharp_ax"},
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_pen_sharp_dg"},
	]:
		var w_p: Weapon = _Weapon.create_from_definition(str(pfx_row["def"]))
		if w_p == null:
			_fail(failures, "%s: missing %s" % [str(pfx_row["pfx"]), str(pfx_row["def"])])
			return
		var m_p: String = str(pfx_row["move"])
		var pfx_p: String = str(pfx_row["pfx"])
		var p_lo: AttackInstance = AttackInstance.new(m_p, 0.5)
		p_lo.archetype = arch_swing_pen
		p_lo.velocity_m_s = pen_v_lo
		var p_hi: AttackInstance = AttackInstance.new(m_p, 0.5)
		p_hi.archetype = arch_swing_pen
		p_hi.velocity_m_s = pen_v_hi
		var ke_lo_p: float = WeaponDamageHelper.compute_kinetic_energy_j(w_p, p_lo)
		var ke_hi_p: float = WeaponDamageHelper.compute_kinetic_energy_j(w_p, p_hi)
		if ke_lo_p < 0.05:
			_fail(failures, "%s: ke_lo unexpectedly small %.4f" % [pfx_p, ke_lo_p])
		if ke_hi_p <= ke_lo_p + 1e-4:
			_fail(
				failures,
				"%s: expected ke_hi > ke_lo lo=%.4f hi=%.4f" % [pfx_p, ke_lo_p, ke_hi_p]
			)
		var pen_lo_p: float = float(
			WeaponDamageHelper.compute_penetration(w_p, p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
				"penetration_sharp", -1.0
			)
		)
		var pen_hi_p: float = float(
			WeaponDamageHelper.compute_penetration(w_p, p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
				"penetration_sharp", -1.0
			)
		)
		if pen_lo_p <= 0.0 or pen_hi_p <= pen_lo_p + 1e-6:
			_fail(failures, "%s: expected rising pen lo=%.6f hi=%.6f" % [pfx_p, pen_lo_p, pen_hi_p])
		var want_rp: float = pow(ke_hi_p / ke_lo_p, WeaponConstants.PENETRATION_EXPONENT)
		var got_rp: float = pen_hi_p / pen_lo_p
		if absf(got_rp - want_rp) > 0.05:
			_fail(
				failures,
				"%s: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
				% [pfx_p, got_rp, want_rp, ke_lo_p, ke_hi_p, WeaponConstants.PENETRATION_EXPONENT]
			)
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	if mace == null:
		_fail(failures, "kin_pen: missing mace")
		return
	const move_blunt: String = "direct_blow"
	var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
	b_lo.velocity_m_s = 7.0
	var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
	b_hi.velocity_m_s = 13.0
	var d_lo: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
	var d_hi: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
	var mpa_lo: float = float(d_lo.get("penetration_blunt_momentum_per_area", -1.0))
	var mpa_hi: float = float(d_hi.get("penetration_blunt_momentum_per_area", -1.0))
	if mpa_lo <= 0.0 or mpa_hi <= mpa_lo + 1e-6:
		_fail(
			failures,
			"kin_pen_blunt: expected rising momentum/area lo=%.4f hi=%.4f" % [mpa_lo, mpa_hi]
		)


## Tier 5.1: **`strike_energy_mult`** scales **`compute_kinetic_energy_j`** linearly (**`maxf(0.05, mult)`**); **`compute_pre_armor_cut`** ratio tracks **`sqrt(KE)`** at the same pinned **`v`** (swing — **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**). Same ratios on **`mixed`** + **`kinematic_mixed_blend` 0.5** with intensity-derived **`v`** (**`velocity_m_s` < 0**) — **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**.
static func _run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(
	failures: PackedStringArray
) -> void:
	const strength: float = 100.0
	const arm_mod: float = 1.0
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_e_mult: missing sword")
		return
	const move_id: String = "oberhau"
	const mult_hi: float = 1.5625
	var ai_1: AttackInstance = AttackInstance.new(move_id, 0.5)
	ai_1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_1.velocity_m_s = 11.0
	ai_1.strike_energy_mult = 1.0
	var ai_2: AttackInstance = AttackInstance.new(move_id, 0.5)
	ai_2.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_2.velocity_m_s = 11.0
	ai_2.strike_energy_mult = mult_hi
	var ke_1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_1)
	var ke_2: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_2)
	if ke_1 <= 0.01:
		_fail(failures, "kin_e_mult: ke_1 too small %.6f" % ke_1)
	var ke_ratio: float = ke_2 / ke_1
	if absf(ke_ratio - mult_hi) > 0.02:
		_fail(failures, "kin_e_mult: ke ratio %.6f want strike_energy ratio %.4f" % [ke_ratio, mult_hi])
	var cut_1: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_1, strength, arm_mod)
	var cut_2: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_2, strength, arm_mod)
	var want_cut_ratio: float = sqrt(mult_hi)
	var cut_ratio: float = cut_2 / cut_1
	if absf(cut_ratio - want_cut_ratio) > 0.04:
		_fail(
			failures,
			"kin_e_mult: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
			% [cut_ratio, want_cut_ratio, cut_1, cut_2]
		)
	const pin_v: float = 11.0
	const arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	for pin_fx: Dictionary in [
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_pin_ax"},
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_pin_dg"},
	]:
		var wp: Weapon = _Weapon.create_from_definition(str(pin_fx["def"]))
		if wp == null:
			_fail(failures, "%s: missing %s" % [str(pin_fx["pfx"]), str(pin_fx["def"])])
			return
		var mp: String = str(pin_fx["move"])
		var pfxp: String = str(pin_fx["pfx"])
		var pi1: AttackInstance = AttackInstance.new(mp, 0.5)
		pi1.archetype = arch_swing
		pi1.velocity_m_s = pin_v
		pi1.strike_energy_mult = 1.0
		var pi2: AttackInstance = AttackInstance.new(mp, 0.5)
		pi2.archetype = arch_swing
		pi2.velocity_m_s = pin_v
		pi2.strike_energy_mult = mult_hi
		var kpe1: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, pi1)
		var kpe2: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, pi2)
		if kpe1 <= 0.01:
			_fail(failures, "%s: ke_1 too small %.6f" % [pfxp, kpe1])
		var kpe_r: float = kpe2 / kpe1
		if absf(kpe_r - mult_hi) > 0.02:
			_fail(failures, "%s: ke ratio %.6f want %.4f" % [pfxp, kpe_r, mult_hi])
		var cpe1: float = WeaponDamageHelper.compute_pre_armor_cut(wp, pi1, strength, arm_mod)
		var cpe2: float = WeaponDamageHelper.compute_pre_armor_cut(wp, pi2, strength, arm_mod)
		var cpe_rr: float = cpe2 / cpe1
		if absf(cpe_rr - want_cut_ratio) > 0.04:
			_fail(
				failures,
				"%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
				% [pfxp, cpe_rr, want_cut_ratio, cpe1, cpe2]
			)
	const mixed_inten: float = 0.53
	const arch_mix: Dictionary = {
		"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED,
		"kinematic_mixed_blend": 0.5
	}
	var ai_mix_1: AttackInstance = AttackInstance.new(move_id, mixed_inten, -1.0)
	ai_mix_1.archetype = arch_mix
	ai_mix_1.strike_energy_mult = 1.0
	var ai_mix_2: AttackInstance = AttackInstance.new(move_id, mixed_inten, -1.0)
	ai_mix_2.archetype = arch_mix
	ai_mix_2.strike_energy_mult = mult_hi
	var ke_mix_1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_1)
	var ke_mix_2: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix_2)
	if ke_mix_1 <= 0.01:
		_fail(failures, "kin_e_mult_mix: ke_mix_1 too small %.6f" % ke_mix_1)
	var ke_mix_ratio: float = ke_mix_2 / ke_mix_1
	if absf(ke_mix_ratio - mult_hi) > 0.02:
		_fail(
			failures,
			"kin_e_mult_mix: ke ratio %.6f want strike_energy ratio %.4f" % [ke_mix_ratio, mult_hi]
		)
	var cut_mix_1: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_1, strength, arm_mod)
	var cut_mix_2: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_2, strength, arm_mod)
	var want_cut_mix_ratio: float = sqrt(mult_hi)
	var cut_mix_ratio: float = cut_mix_2 / cut_mix_1
	if absf(cut_mix_ratio - want_cut_mix_ratio) > 0.04:
		_fail(
			failures,
			"kin_e_mult_mix: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
			% [cut_mix_ratio, want_cut_mix_ratio, cut_mix_1, cut_mix_2]
		)
	for fx: Dictionary in [
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_e_mult_mix_ax"},
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_e_mult_mix_dg"},
	]:
		var w_ex: Weapon = _Weapon.create_from_definition(str(fx["def"]))
		if w_ex == null:
			_fail(failures, "%s: missing %s" % [str(fx["pfx"]), str(fx["def"])])
			return
		var m_ex: String = str(fx["move"])
		var pfx: String = str(fx["pfx"])
		var wx1: AttackInstance = AttackInstance.new(m_ex, mixed_inten, -1.0)
		wx1.archetype = arch_mix
		wx1.strike_energy_mult = 1.0
		var wx2: AttackInstance = AttackInstance.new(m_ex, mixed_inten, -1.0)
		wx2.archetype = arch_mix
		wx2.strike_energy_mult = mult_hi
		var kx1: float = WeaponDamageHelper.compute_kinetic_energy_j(w_ex, wx1)
		var kx2: float = WeaponDamageHelper.compute_kinetic_energy_j(w_ex, wx2)
		if kx1 <= 0.01:
			_fail(failures, "%s: ke_1 too small %.6f" % [pfx, kx1])
		var kx_r: float = kx2 / kx1
		if absf(kx_r - mult_hi) > 0.02:
			_fail(failures, "%s: ke ratio %.6f want %.4f" % [pfx, kx_r, mult_hi])
		var cx1: float = WeaponDamageHelper.compute_pre_armor_cut(w_ex, wx1, strength, arm_mod)
		var cx2: float = WeaponDamageHelper.compute_pre_armor_cut(w_ex, wx2, strength, arm_mod)
		var cx_rr: float = cx2 / cx1
		if absf(cx_rr - want_cut_mix_ratio) > 0.04:
			_fail(
				failures,
				"%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
				% [pfx, cx_rr, want_cut_mix_ratio, cx1, cx2]
			)


## Tier 5.1: **`strike_momentum_mult`** scales blunt momentum linearly (**`maxf(0.05, mult)`**); **`compute_pre_armor_blunt`** and **`compute_penetration`** **BLUNT** **`penetration_blunt_momentum_per_area`** track the same ratio at pinned **`v`** (**MACE** **`direct_blow`**, plus cut swing **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** — **DAGGER** uses a higher pinned **`v`** than **10** m/s so blunt clears **`WeaponConstants.BLUNT_DAMAGE_MIN`** for both mults; **SWORD** / **AXE** stay at **10** m/s).
static func _run_kinematic_delivery_strike_momentum_mult_scales_blunt_damage_and_mpa(
	failures: PackedStringArray
) -> void:
	const strength: float = 100.0
	const arm_mod: float = 1.0
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	if mace == null:
		_fail(failures, "kin_p_mult: missing mace")
		return
	const move_id: String = "direct_blow"
	const p_hi: float = 1.65
	var b_1: AttackInstance = AttackInstance.new(move_id, 0.5)
	b_1.velocity_m_s = 10.0
	b_1.strike_momentum_mult = 1.0
	var b_2: AttackInstance = AttackInstance.new(move_id, 0.5)
	b_2.velocity_m_s = 10.0
	b_2.strike_momentum_mult = p_hi
	var blunt_1: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_1, strength, arm_mod)
	var blunt_2: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_2, strength, arm_mod)
	if blunt_1 <= 0.01:
		_fail(failures, "kin_p_mult: blunt_1 too small %.4f" % blunt_1)
	var blunt_ratio: float = blunt_2 / blunt_1
	if absf(blunt_ratio - p_hi) > 0.03:
		_fail(
			failures,
			"kin_p_mult: blunt ratio %.4f want strike_momentum_mult ratio %.4f"
			% [blunt_ratio, p_hi]
		)
	var d_1: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_1, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
	var d_2: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_2, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
	var mpa_1: float = float(d_1.get("penetration_blunt_momentum_per_area", -1.0))
	var mpa_2: float = float(d_2.get("penetration_blunt_momentum_per_area", -1.0))
	if mpa_1 <= 0.0:
		_fail(failures, "kin_p_mult: mpa_1 invalid %.4f" % mpa_1)
	var mpa_ratio: float = mpa_2 / mpa_1
	if absf(mpa_ratio - p_hi) > 0.03:
		_fail(
			failures,
			"kin_p_mult: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)"
			% [mpa_ratio, p_hi, mpa_1, mpa_2]
		)
	const arch_sw_bl: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	const v_pin_mo: float = 10.0
	for cb: Dictionary in [
		{"def": "SWORD", "move": "oberhau", "pfx": "kin_p_mult_cb_sw"},
		{"def": "AXE", "move": "diagonal_chop", "pfx": "kin_p_mult_cb_ax"},
		# Light blade: raise pinned **`v`** so raw blunt clears **`BLUNT_DAMAGE_MIN`** for both mults (narrow blade
		# otherwise clamps both samples to **1.0** → ratio **1.0**).
		{"def": "DAGGER", "move": "quick_slash", "pfx": "kin_p_mult_cb_dg", "v": 20.0},
	]:
		var wcb: Weapon = _Weapon.create_from_definition(str(cb["def"]))
		if wcb == null:
			_fail(failures, "%s: missing %s" % [str(cb["pfx"]), str(cb["def"])])
			return
		var mvb: String = str(cb["move"])
		var tcb: String = str(cb["pfx"])
		var v_this: float = float(cb.get("v", v_pin_mo))
		var str_this: float = float(cb.get("strength", strength))
		var sb1: AttackInstance = AttackInstance.new(mvb, 0.5)
		sb1.archetype = arch_sw_bl
		sb1.velocity_m_s = v_this
		sb1.strike_momentum_mult = 1.0
		var sb2: AttackInstance = AttackInstance.new(mvb, 0.5)
		sb2.archetype = arch_sw_bl
		sb2.velocity_m_s = v_this
		sb2.strike_momentum_mult = p_hi
		var bl1: float = WeaponDamageHelper.compute_pre_armor_blunt(wcb, sb1, str_this, arm_mod)
		var bl2: float = WeaponDamageHelper.compute_pre_armor_blunt(wcb, sb2, str_this, arm_mod)
		if bl1 <= 0.001:
			_fail(failures, "%s: blunt_1 too small %.4f" % [tcb, bl1])
		var bl_r: float = bl2 / bl1
		if absf(bl_r - p_hi) > 0.03:
			_fail(
				failures,
				"%s: blunt ratio %.4f want strike_momentum_mult ratio %.4f"
				% [tcb, bl_r, p_hi]
			)
		var db1: Dictionary = WeaponDamageHelper.compute_penetration(
			wcb, sb1, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		)
		var db2: Dictionary = WeaponDamageHelper.compute_penetration(
			wcb, sb2, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		)
		var mpb1: float = float(db1.get("penetration_blunt_momentum_per_area", -1.0))
		var mpb2: float = float(db2.get("penetration_blunt_momentum_per_area", -1.0))
		if mpb1 <= 0.0:
			_fail(failures, "%s: mpa_1 invalid %.4f" % [tcb, mpb1])
		var mpb_r: float = mpb2 / mpb1
		if absf(mpb_r - p_hi) > 0.03:
			_fail(
				failures,
				"%s: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)" % [tcb, mpb_r, p_hi, mpb1, mpb2]
			)


## Tier 5.1: **`strike_momentum_mult`** must not change **`compute_kinetic_energy_j`** (pinned **`velocity_m_s`** or derived **`velocity_m_s` < 0** on **SWORD** / **AXE** / **DAGGER** swing, **MACE** blunt→swing, **SPEAR** thrust), **SHARP** **`compute_penetration`** / **`compute_pre_armor_cut`** (pinned **`v`** or same derived-**`v`** **`sv_p_*`**, **`sp_p_*`**, **`mv_p_*`**, **`ax_p_*`**, **`dg_p_*`** pairs), or derived **`get_effective_velocity_m_s`** (`AttackInstance.velocity_m_s` < 0; **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**, **MACE** **`direct_blow`**, **SPEAR** **`spear_thrust`**); pinned **`v`**: **`get_effective_velocity_m_s`** ⊥ **`strike_momentum_mult`** (**SWORD** **`ai_*_p`**, **`wcx_pm`** **AXE** / **DAGGER**); **`strike_energy_mult`** must not change **`compute_pre_armor_blunt`** (pinned **`v`** or derived **`velocity_m_s` < 0** on **MACE** **`mv_e_*`**, **SPEAR** **`sp_e_*`**, **SWORD** **`sv_e_*`**, **AXE** **`ax_sv_e_*`**, **DAGGER** **`dg_sv_e_*`**, incl. **`target_effective_mass_kg`** reduced-mass + opts), **BLUNT** **`compute_penetration`** **`penetration_blunt_momentum_per_area`** (same), or derived **`get_effective_velocity_m_s`** (**SWORD** + **MACE** + **SPEAR** + **AXE** + **DAGGER**); pinned **`v`**: **`get_effective_velocity_m_s`** ⊥ **`strike_energy_mult`** (**SWORD** **`sw_*`**, **`swx`** **AXE** / **DAGGER**) — same blunt-channel ⊥ on **MACE** **`direct_blow`** and **SWORD** / **AXE** / **DAGGER** cut swing (pinned **`v`**) — orthogonal energy vs momentum paths.
static func _run_kinematic_delivery_strike_mult_cross_coupling_ke_vs_blunt_isolated(
	failures: PackedStringArray
) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_cross: missing sword")
		return
	var w_axe: Weapon = _Weapon.create_from_definition("AXE")
	var w_dagger: Weapon = _Weapon.create_from_definition("DAGGER")
	if w_axe == null or w_dagger == null:
		_fail(failures, "kin_cross: missing axe or dagger")
		return
	const strength: float = 100.0
	const arm_mod: float = 1.0
	const move_cut: String = "oberhau"
	var ai_lo_p: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_lo_p.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_lo_p.velocity_m_s = 10.0
	ai_lo_p.strike_energy_mult = 1.0
	ai_lo_p.strike_momentum_mult = 1.0
	var ai_hi_p: AttackInstance = AttackInstance.new(move_cut, 0.5)
	ai_hi_p.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ai_hi_p.velocity_m_s = 10.0
	ai_hi_p.strike_energy_mult = 1.0
	ai_hi_p.strike_momentum_mult = 4.25
	var ke_lo_p: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_lo_p)
	var ke_hi_p: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_hi_p)
	if absf(ke_hi_p - ke_lo_p) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [ke_lo_p, ke_hi_p]
		)
	var pen_lo_p: float = float(
		WeaponDamageHelper.compute_penetration(sword, ai_lo_p, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	var pen_hi_p: float = float(
		WeaponDamageHelper.compute_penetration(sword, ai_hi_p, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	if absf(pen_hi_p - pen_lo_p) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
			% [pen_lo_p, pen_hi_p]
		)
	var cut_lo_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo_p, 100.0, 1.0)
	var cut_hi_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi_p, 100.0, 1.0)
	if absf(cut_hi_pm - cut_lo_pm) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
			% [cut_lo_pm, cut_hi_pm]
		)
	var ev_sw_pm_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_lo_p)
	var ev_sw_pm_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_hi_p)
	if absf(ev_sw_pm_hi - ev_sw_pm_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (sword lo=%.6f hi=%.6f)"
			% [ev_sw_pm_lo, ev_sw_pm_hi]
		)
	const v_pin_cross: float = 10.0
	var ev_wx_pm_lo: float
	var ev_wx_pm_hi: float
	for wcx_pm: Dictionary in [
		{"w": w_axe, "move": "diagonal_chop", "pfx": "kin_cross_ax_pm"},
		{"w": w_dagger, "move": "quick_slash", "pfx": "kin_cross_dg_pm"},
	]:
		var wp: Weapon = wcx_pm["w"] as Weapon
		var mv: String = str(wcx_pm["move"])
		var pfx: String = str(wcx_pm["pfx"])
		var lo_x: AttackInstance = AttackInstance.new(mv, 0.5)
		lo_x.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
		lo_x.velocity_m_s = v_pin_cross
		lo_x.strike_energy_mult = 1.0
		lo_x.strike_momentum_mult = 1.0
		var hi_x: AttackInstance = AttackInstance.new(mv, 0.5)
		hi_x.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
		hi_x.velocity_m_s = v_pin_cross
		hi_x.strike_energy_mult = 1.0
		hi_x.strike_momentum_mult = 4.25
		var ke_lo_x: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, lo_x)
		var ke_hi_x: float = WeaponDamageHelper.compute_kinetic_energy_j(wp, hi_x)
		if absf(ke_hi_x - ke_lo_x) > 0.0001:
			_fail(
				failures,
				"%s: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [pfx, ke_lo_x, ke_hi_x]
			)
		var pen_lo_x: float = float(
			WeaponDamageHelper.compute_penetration(
				wp, lo_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}
			).get("penetration_sharp", -1.0)
		)
		var pen_hi_x: float = float(
			WeaponDamageHelper.compute_penetration(
				wp, hi_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}
			).get("penetration_sharp", -1.0)
		)
		if absf(pen_hi_x - pen_lo_x) > 0.0001:
			_fail(
				failures,
				"%s: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
				% [pfx, pen_lo_x, pen_hi_x]
			)
		var cut_lo_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, lo_x, strength, arm_mod)
		var cut_hi_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, hi_x, strength, arm_mod)
		if absf(cut_hi_x - cut_lo_x) > 0.0001:
			_fail(
				failures,
				"%s: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
				% [pfx, cut_lo_x, cut_hi_x]
			)
		ev_wx_pm_lo = WeaponDamageHelper.get_effective_velocity_m_s(wp, lo_x)
		ev_wx_pm_hi = WeaponDamageHelper.get_effective_velocity_m_s(wp, hi_x)
		if absf(ev_wx_pm_hi - ev_wx_pm_lo) > 0.0001:
			_fail(
				failures,
				"%s: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
				% [pfx, ev_wx_pm_lo, ev_wx_pm_hi]
			)
	var sv_p_lo: AttackInstance = AttackInstance.new(move_cut, 0.63)
	sv_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sv_p_lo.strike_energy_mult = 1.0
	sv_p_lo.strike_momentum_mult = 1.0
	var sv_p_hi: AttackInstance = AttackInstance.new(move_cut, 0.63)
	sv_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sv_p_hi.strike_energy_mult = 1.0
	sv_p_hi.strike_momentum_mult = 4.25
	var ev_p_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_p_lo)
	var ev_p_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_p_hi)
	if absf(ev_p_hi - ev_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
			% [ev_p_lo, ev_p_hi]
		)
	const move_ax: String = "diagonal_chop"
	var ax_p_lo: AttackInstance = AttackInstance.new(move_ax, 0.63)
	ax_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ax_p_lo.strike_energy_mult = 1.0
	ax_p_lo.strike_momentum_mult = 1.0
	var ax_p_hi: AttackInstance = AttackInstance.new(move_ax, 0.63)
	ax_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ax_p_hi.strike_energy_mult = 1.0
	ax_p_hi.strike_momentum_mult = 4.25
	const move_dg: String = "quick_slash"
	var dg_p_lo: AttackInstance = AttackInstance.new(move_dg, 0.63)
	dg_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	dg_p_lo.strike_energy_mult = 1.0
	dg_p_lo.strike_momentum_mult = 1.0
	var dg_p_hi: AttackInstance = AttackInstance.new(move_dg, 0.63)
	dg_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	dg_p_hi.strike_energy_mult = 1.0
	dg_p_hi.strike_momentum_mult = 4.25
	var ev_ax_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_p_lo)
	var ev_ax_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_p_hi)
	if absf(ev_ax_hi - ev_ax_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (axe lo=%.6f hi=%.6f)"
			% [ev_ax_lo, ev_ax_hi]
		)
	var ev_dg_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_lo)
	var ev_dg_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_hi)
	if absf(ev_dg_hi - ev_dg_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (dagger lo=%.6f hi=%.6f)"
			% [ev_dg_lo, ev_dg_hi]
		)
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	if mace == null:
		_fail(failures, "kin_cross: missing mace")
		return
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if spear == null:
		_fail(failures, "kin_cross: missing spear")
		return
	const move_bl: String = "direct_blow"
	var b_lo_e: AttackInstance = AttackInstance.new(move_bl, 0.5)
	b_lo_e.velocity_m_s = 10.0
	b_lo_e.strike_energy_mult = 1.0
	b_lo_e.strike_momentum_mult = 1.0
	var b_hi_e: AttackInstance = AttackInstance.new(move_bl, 0.5)
	b_hi_e.velocity_m_s = 10.0
	b_hi_e.strike_energy_mult = 3.1
	b_hi_e.strike_momentum_mult = 1.0
	var mv_e_lo: AttackInstance = AttackInstance.new(move_bl, 0.58)
	mv_e_lo.strike_energy_mult = 1.0
	mv_e_lo.strike_momentum_mult = 1.0
	var mv_e_hi: AttackInstance = AttackInstance.new(move_bl, 0.58)
	mv_e_hi.strike_energy_mult = 3.1
	mv_e_hi.strike_momentum_mult = 1.0
	var ev_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_e_lo)
	var ev_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_e_hi)
	if absf(ev_e_hi - ev_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (mace lo=%.6f hi=%.6f)"
			% [ev_e_lo, ev_e_hi]
		)
	var mv_p_lo: AttackInstance = AttackInstance.new(move_bl, 0.57)
	mv_p_lo.strike_energy_mult = 1.0
	mv_p_lo.strike_momentum_mult = 1.0
	var mv_p_hi: AttackInstance = AttackInstance.new(move_bl, 0.57)
	mv_p_hi.strike_energy_mult = 1.0
	mv_p_hi.strike_momentum_mult = 2.85
	var ev_m_p_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_p_lo)
	var ev_m_p_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, mv_p_hi)
	if absf(ev_m_p_hi - ev_m_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (mace lo=%.6f hi=%.6f)"
			% [ev_m_p_lo, ev_m_p_hi]
		)
	const move_thr: String = "spear_thrust"
	var sp_p_lo: AttackInstance = AttackInstance.new(move_thr, 0.56)
	sp_p_lo.strike_energy_mult = 1.0
	sp_p_lo.strike_momentum_mult = 1.0
	var sp_p_hi: AttackInstance = AttackInstance.new(move_thr, 0.56)
	sp_p_hi.strike_energy_mult = 1.0
	sp_p_hi.strike_momentum_mult = 3.5
	var ev_sp_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_p_lo)
	var ev_sp_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_p_hi)
	if absf(ev_sp_hi - ev_sp_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (spear lo=%.6f hi=%.6f)"
			% [ev_sp_lo, ev_sp_hi]
		)
	var sp_e_lo: AttackInstance = AttackInstance.new(move_thr, 0.54)
	sp_e_lo.strike_energy_mult = 1.0
	sp_e_lo.strike_momentum_mult = 1.0
	var sp_e_hi: AttackInstance = AttackInstance.new(move_thr, 0.54)
	sp_e_hi.strike_energy_mult = 2.7
	sp_e_hi.strike_momentum_mult = 1.0
	var ev_ste_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_e_lo)
	var ev_ste_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, sp_e_hi)
	if absf(ev_ste_hi - ev_ste_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (spear lo=%.6f hi=%.6f)"
			% [ev_ste_lo, ev_ste_hi]
		)
	var ke_sv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_lo)
	var ke_sv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_hi)
	if absf(ke_sv_der_hi - ke_sv_der_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
			% [ke_sv_der_lo, ke_sv_der_hi]
		)
	var ke_mv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_lo)
	var ke_mv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_hi)
	if absf(ke_mv_der_hi - ke_mv_der_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
			% [ke_mv_der_lo, ke_mv_der_hi]
		)
	var ke_sp_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_lo)
	var ke_sp_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_hi)
	if absf(ke_sp_der_hi - ke_sp_der_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
			% [ke_sp_der_lo, ke_sp_der_hi]
		)
	var ke_ax_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_lo)
	var ke_ax_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_hi)
	if absf(ke_ax_der_hi - ke_ax_der_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (axe swing derived v lo=%.6f hi=%.6f)"
			% [ke_ax_der_lo, ke_ax_der_hi]
		)
	var ke_dg_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_lo)
	var ke_dg_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_hi)
	if absf(ke_dg_der_hi - ke_dg_der_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: KE should ignore strike_momentum_mult (dagger swing derived v lo=%.6f hi=%.6f)"
			% [ke_dg_der_lo, ke_dg_der_hi]
		)
	var pen_sv_p_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	var pen_sv_p_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	if absf(pen_sv_p_hi - pen_sv_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
			% [pen_sv_p_lo, pen_sv_p_hi]
		)
	var cut_sv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_lo, strength, arm_mod)
	var cut_sv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_hi, strength, arm_mod)
	if absf(cut_sv_p_hi - cut_sv_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
			% [cut_sv_p_lo, cut_sv_p_hi]
		)
	var pen_ax_p_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	var pen_ax_p_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	if absf(pen_ax_p_hi - pen_ax_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
			% [pen_ax_p_lo, pen_ax_p_hi]
		)
	var cut_ax_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_lo, strength, arm_mod)
	var cut_ax_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_hi, strength, arm_mod)
	if absf(cut_ax_p_hi - cut_ax_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
			% [cut_ax_p_lo, cut_ax_p_hi]
		)
	var pen_dg_p_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	var pen_dg_p_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	if absf(pen_dg_p_hi - pen_dg_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6f)"
			% [pen_dg_p_lo, pen_dg_p_hi]
		)
	var cut_dg_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_lo, strength, arm_mod)
	var cut_dg_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_hi, strength, arm_mod)
	if absf(cut_dg_p_hi - cut_dg_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6f)"
			% [cut_dg_p_lo, cut_dg_p_hi]
		)
	var pen_sp_p_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			spear, sp_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	var pen_sp_p_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			spear, sp_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	if absf(pen_sp_p_hi - pen_sp_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
			% [pen_sp_p_lo, pen_sp_p_hi]
		)
	var cut_sp_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_lo, strength, arm_mod)
	var cut_sp_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_hi, strength, arm_mod)
	if absf(cut_sp_p_hi - cut_sp_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
			% [cut_sp_p_lo, cut_sp_p_hi]
		)
	var pen_mv_p_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	var pen_mv_p_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}
		).get("penetration_sharp", -1.0)
	)
	if absf(pen_mv_p_hi - pen_mv_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
			% [pen_mv_p_lo, pen_mv_p_hi]
		)
	var cut_mv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_lo, strength, arm_mod)
	var cut_mv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_hi, strength, arm_mod)
	if absf(cut_mv_p_hi - cut_mv_p_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
			% [cut_mv_p_lo, cut_mv_p_hi]
		)
	var blunt_lo_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo_e, strength, arm_mod)
	var blunt_hi_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi_e, strength, arm_mod)
	if absf(blunt_hi_e - blunt_lo_e) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [blunt_lo_e, blunt_hi_e]
		)
	var mpa_lo_e: float = float(
		WeaponDamageHelper.compute_penetration(mace, b_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
			"penetration_blunt_momentum_per_area", -1.0
		)
	)
	var mpa_hi_e: float = float(
		WeaponDamageHelper.compute_penetration(mace, b_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
			"penetration_blunt_momentum_per_area", -1.0
		)
	)
	if absf(mpa_hi_e - mpa_lo_e) > 0.0001:
		_fail(
			failures,
			"kin_cross: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [mpa_lo_e, mpa_hi_e]
		)
	const tgt_kg_blunt: float = 73.0
	var blunt_lo_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
		mace, b_lo_e, strength, arm_mod, tgt_kg_blunt
	)
	var blunt_hi_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
		mace, b_hi_e, strength, arm_mod, tgt_kg_blunt
	)
	if absf(blunt_hi_e_rm - blunt_lo_e_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [blunt_lo_e_rm, blunt_hi_e_rm]
		)
	var opts_rm: Dictionary = {"target_effective_mass_kg": 68.0}
	var mpa_lo_e_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, b_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_hi_e_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, b_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_hi_e_rm - mpa_lo_e_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [mpa_lo_e_rm, mpa_hi_e_rm]
		)
	var blunt_mv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_lo, strength, arm_mod)
	var blunt_mv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_hi, strength, arm_mod)
	if absf(blunt_mv_e_hi - blunt_mv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
			% [blunt_mv_e_lo, blunt_mv_e_hi]
		)
	var mpa_mv_e_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_mv_e_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_mv_e_hi - mpa_mv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: BLUNT mpa should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
			% [mpa_mv_e_lo, mpa_mv_e_hi]
		)
	var blunt_mv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		mace, mv_e_lo, strength, arm_mod, tgt_kg_blunt
	)
	var blunt_mv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		mace, mv_e_hi, strength, arm_mod, tgt_kg_blunt
	)
	if absf(blunt_mv_e_rm_hi - blunt_mv_e_rm_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
			% [blunt_mv_e_rm_lo, blunt_mv_e_rm_hi]
		)
	var mpa_mv_e_lo_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_mv_e_hi_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_mv_e_hi_rm - mpa_mv_e_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
			% [mpa_mv_e_lo_rm, mpa_mv_e_hi_rm]
		)
	var blunt_sp_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_lo, strength, arm_mod)
	var blunt_sp_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_hi, strength, arm_mod)
	if absf(blunt_sp_e_hi - blunt_sp_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
			% [blunt_sp_e_lo, blunt_sp_e_hi]
		)
	var mpa_sp_e_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			spear, sp_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_sp_e_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			spear, sp_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_sp_e_hi - mpa_sp_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: BLUNT mpa should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
			% [mpa_sp_e_lo, mpa_sp_e_hi]
		)
	var sw_lo_e: AttackInstance = AttackInstance.new(move_cut, 0.5)
	sw_lo_e.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sw_lo_e.velocity_m_s = 10.0
	sw_lo_e.strike_energy_mult = 1.0
	sw_lo_e.strike_momentum_mult = 1.0
	var sw_hi_e: AttackInstance = AttackInstance.new(move_cut, 0.5)
	sw_hi_e.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sw_hi_e.velocity_m_s = 10.0
	sw_hi_e.strike_energy_mult = 3.1
	sw_hi_e.strike_momentum_mult = 1.0
	var ev_pin_sw_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sw_lo_e)
	var ev_pin_sw_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sw_hi_e)
	if absf(ev_pin_sw_hi - ev_pin_sw_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: pinned get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
			% [ev_pin_sw_lo, ev_pin_sw_hi]
		)
	var s_blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_lo_e, strength, arm_mod)
	var s_blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_hi_e, strength, arm_mod)
	if absf(s_blunt_hi - s_blunt_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [s_blunt_lo, s_blunt_hi]
		)
	const tgt_kg_sword: float = 71.0
	var s_blunt_lo_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
		sword, sw_lo_e, strength, arm_mod, tgt_kg_sword
	)
	var s_blunt_hi_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
		sword, sw_hi_e, strength, arm_mod, tgt_kg_sword
	)
	if absf(s_blunt_hi_rm - s_blunt_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [s_blunt_lo_rm, s_blunt_hi_rm]
		)
	var mpa_s_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_s_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_s_hi - mpa_s_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [mpa_s_lo, mpa_s_hi]
		)
	var mpa_s_lo_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_s_hi_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_s_hi_rm - mpa_s_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
			% [mpa_s_lo_rm, mpa_s_hi_rm]
		)
	var sv_e_lo: AttackInstance = AttackInstance.new(move_cut, 0.61)
	sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sv_e_lo.strike_energy_mult = 1.0
	sv_e_lo.strike_momentum_mult = 1.0
	var sv_e_hi: AttackInstance = AttackInstance.new(move_cut, 0.61)
	sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	sv_e_hi.strike_energy_mult = 3.1
	sv_e_hi.strike_momentum_mult = 1.0
	var ev_s_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_e_lo)
	var ev_s_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, sv_e_hi)
	if absf(ev_s_hi - ev_s_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
			% [ev_s_lo, ev_s_hi]
		)
	var blunt_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_lo, strength, arm_mod)
	var blunt_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_hi, strength, arm_mod)
	if absf(blunt_sv_e_hi - blunt_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (sword derived v lo=%.6f hi=%.6f)"
			% [blunt_sv_e_lo, blunt_sv_e_hi]
		)
	var blunt_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		sword, sv_e_lo, strength, arm_mod, tgt_kg_sword
	)
	var blunt_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		sword, sv_e_hi, strength, arm_mod, tgt_kg_sword
	)
	if absf(blunt_sv_e_rm_hi - blunt_sv_e_rm_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (sword derived v lo=%.6f hi=%.6f)"
			% [blunt_sv_e_rm_lo, blunt_sv_e_rm_hi]
		)
	var mpa_sv_e_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_sv_e_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_sv_e_hi - mpa_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_sv_e_lo, mpa_sv_e_hi]
		)
	var mpa_sv_e_lo_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_sv_e_hi_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_sv_e_hi_rm - mpa_sv_e_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_sv_e_lo_rm, mpa_sv_e_hi_rm]
		)
	for swx: Dictionary in [
		{
			"w": w_axe,
			"move": "diagonal_chop",
			"v": 10.0,
			"pfx": "kin_cross_ax_sw_e",
			"tgt_kg": 71.0,
		},
		{
			"w": w_dagger,
			"move": "quick_slash",
			"v": 20.0,
			"pfx": "kin_cross_dg_sw_e",
			"tgt_kg": 71.0,
		},
	]:
		var wx: Weapon = swx["w"] as Weapon
		var mvx: String = str(swx["move"])
		var pfxx: String = str(swx["pfx"])
		var vx: float = float(swx["v"])
		var tk: float = float(swx["tgt_kg"])
		var slo: AttackInstance = AttackInstance.new(mvx, 0.5)
		slo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
		slo.velocity_m_s = vx
		slo.strike_energy_mult = 1.0
		slo.strike_momentum_mult = 1.0
		var shi: AttackInstance = AttackInstance.new(mvx, 0.5)
		shi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
		shi.velocity_m_s = vx
		shi.strike_energy_mult = 3.1
		shi.strike_momentum_mult = 1.0
		var ev_pin_wx_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(wx, slo)
		var ev_pin_wx_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(wx, shi)
		if absf(ev_pin_wx_hi - ev_pin_wx_lo) > 0.0001:
			_fail(
				failures,
				"%s: pinned get_effective_velocity_m_s should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
				% [pfxx, ev_pin_wx_lo, ev_pin_wx_hi]
			)
		var bl0: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod)
		var bl1: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod)
		if absf(bl1 - bl0) > 0.0001:
			_fail(
				failures,
				"%s: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, bl0, bl1]
			)
		var bl0r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod, tk)
		var bl1r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod, tk)
		if absf(bl1r - bl0r) > 0.0001:
			_fail(
				failures,
				"%s: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
				% [pfxx, bl0r, bl1r]
			)
		var mp0: float = float(
			WeaponDamageHelper.compute_penetration(wx, slo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
				"penetration_blunt_momentum_per_area", -1.0
			)
		)
		var mp1: float = float(
			WeaponDamageHelper.compute_penetration(wx, shi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
				"penetration_blunt_momentum_per_area", -1.0
			)
		)
		if absf(mp1 - mp0) > 0.0001:
			_fail(
				failures,
				"%s: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, mp0, mp1]
			)
		var mp0r: float = float(
			WeaponDamageHelper.compute_penetration(
				wx, slo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
			).get("penetration_blunt_momentum_per_area", -1.0)
		)
		var mp1r: float = float(
			WeaponDamageHelper.compute_penetration(
				wx, shi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
			).get("penetration_blunt_momentum_per_area", -1.0)
		)
		if absf(mp1r - mp0r) > 0.0001:
			_fail(
				failures,
				"%s: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
				% [pfxx, mp0r, mp1r]
			)
	var ax_sv_e_lo: AttackInstance = AttackInstance.new(move_ax, 0.61)
	ax_sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ax_sv_e_lo.strike_energy_mult = 1.0
	ax_sv_e_lo.strike_momentum_mult = 1.0
	var ax_sv_e_hi: AttackInstance = AttackInstance.new(move_ax, 0.61)
	ax_sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	ax_sv_e_hi.strike_energy_mult = 3.1
	ax_sv_e_hi.strike_momentum_mult = 1.0
	var ev_ax_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_sv_e_lo)
	var ev_ax_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_axe, ax_sv_e_hi)
	if absf(ev_ax_e_hi - ev_ax_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (axe lo=%.6f hi=%.6f)"
			% [ev_ax_e_lo, ev_ax_e_hi]
		)
	var blunt_ax_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_axe, ax_sv_e_lo, strength, arm_mod
	)
	var blunt_ax_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_axe, ax_sv_e_hi, strength, arm_mod
	)
	if absf(blunt_ax_sv_e_hi - blunt_ax_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (axe derived v lo=%.6f hi=%.6f)"
			% [blunt_ax_sv_e_lo, blunt_ax_sv_e_hi]
		)
	var blunt_ax_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_axe, ax_sv_e_lo, strength, arm_mod, 71.0
	)
	var blunt_ax_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_axe, ax_sv_e_hi, strength, arm_mod, 71.0
	)
	if absf(blunt_ax_sv_e_rm_hi - blunt_ax_sv_e_rm_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (axe derived v lo=%.6f hi=%.6f)"
			% [blunt_ax_sv_e_rm_lo, blunt_ax_sv_e_rm_hi]
		)
	var mpa_ax_sv_e_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_ax_sv_e_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_ax_sv_e_hi - mpa_ax_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: axe BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_ax_sv_e_lo, mpa_ax_sv_e_hi]
		)
	var mpa_ax_sv_e_lo_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_ax_sv_e_hi_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_ax_sv_e_hi_rm - mpa_ax_sv_e_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: axe BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_ax_sv_e_lo_rm, mpa_ax_sv_e_hi_rm]
		)
	var dg_sv_e_lo: AttackInstance = AttackInstance.new(move_dg, 0.61)
	dg_sv_e_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	dg_sv_e_lo.strike_energy_mult = 1.0
	dg_sv_e_lo.strike_momentum_mult = 1.0
	var dg_sv_e_hi: AttackInstance = AttackInstance.new(move_dg, 0.61)
	dg_sv_e_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	dg_sv_e_hi.strike_energy_mult = 3.1
	dg_sv_e_hi.strike_momentum_mult = 1.0
	var ev_dg_e_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_sv_e_lo)
	var ev_dg_e_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_sv_e_hi)
	if absf(ev_dg_e_hi - ev_dg_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (dagger lo=%.6f hi=%.6f)"
			% [ev_dg_e_lo, ev_dg_e_hi]
		)
	var blunt_dg_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_dagger, dg_sv_e_lo, strength, arm_mod
	)
	var blunt_dg_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_dagger, dg_sv_e_hi, strength, arm_mod
	)
	if absf(blunt_dg_sv_e_hi - blunt_dg_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor should ignore strike_energy_mult (dagger derived v lo=%.6f hi=%.6f)"
			% [blunt_dg_sv_e_lo, blunt_dg_sv_e_hi]
		)
	var blunt_dg_sv_e_rm_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_dagger, dg_sv_e_lo, strength, arm_mod, 71.0
	)
	var blunt_dg_sv_e_rm_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(
		w_dagger, dg_sv_e_hi, strength, arm_mod, 71.0
	)
	if absf(blunt_dg_sv_e_rm_hi - blunt_dg_sv_e_rm_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (dagger derived v lo=%.6f hi=%.6f)"
			% [blunt_dg_sv_e_rm_lo, blunt_dg_sv_e_rm_hi]
		)
	var mpa_dg_sv_e_lo: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_dg_sv_e_hi: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_dg_sv_e_hi - mpa_dg_sv_e_lo) > 0.0001:
		_fail(
			failures,
			"kin_cross: dagger BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_dg_sv_e_lo, mpa_dg_sv_e_hi]
		)
	var mpa_dg_sv_e_lo_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	var mpa_dg_sv_e_hi_rm: float = float(
		WeaponDamageHelper.compute_penetration(
			w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm
		).get("penetration_blunt_momentum_per_area", -1.0)
	)
	if absf(mpa_dg_sv_e_hi_rm - mpa_dg_sv_e_lo_rm) > 0.0001:
		_fail(
			failures,
			"kin_cross: dagger BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
			% [mpa_dg_sv_e_lo_rm, mpa_dg_sv_e_hi_rm]
		)


## Tier 5.1 (optional long-tail): **`AttackResolver.penetration_oblique_angle_factor`** matches parry vs misaligned-guard **`lerp`** rules; **`velocity_override` < 0** ⇒ **1** (no penetration oblique here).
static func _run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver(
	failures: PackedStringArray
) -> void:
	const tol: float = 0.00001
	var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	var f_neg: float = _AttackResolver.penetration_oblique_angle_factor(-1.0, 0.0, 0.0)
	if absf(f_neg - 1.0) > tol:
		_fail(failures, "kin_oblique: vo<0 should be 1 got %.6f" % f_neg)
	var f_clean: float = _AttackResolver.penetration_oblique_angle_factor(10.0, 1.0, 1.0)
	if absf(f_clean - 1.0) > tol:
		_fail(failures, "kin_oblique: full parry+align should be 1 got %.6f" % f_clean)
	var f_parry_half: float = _AttackResolver.penetration_oblique_angle_factor(0.0, 0.5, 1.0)
	var w_parry_half: float = lerpf(1.0, amin, 0.5)
	if absf(f_parry_half - w_parry_half) > tol:
		_fail(
			failures,
			"kin_oblique: parry 0.5 want %.6f got %.6f" % [w_parry_half, f_parry_half]
		)
	var f_align_edge: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 1.0, 0.0)
	var t_align: float = (1.0 - 0.0) * ascale
	var w_align: float = lerpf(1.0, amin, t_align)
	if absf(f_align_edge - w_align) > tol:
		_fail(
			failures,
			"kin_oblique: align 0 parry=1 want %.6f got %.6f" % [w_align, f_align_edge]
		)
	var f_parry_zero: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 0.0, 1.0)
	var w_pz: float = lerpf(1.0, amin, 1.0)
	if absf(f_parry_zero - w_pz) > tol:
		_fail(failures, "kin_oblique: parry 0 want %.6f got %.6f" % [w_pz, f_parry_zero])
	var f_parry_wins: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 0.25, 0.0)
	var w_pw: float = lerpf(1.0, amin, 0.75)
	if absf(f_parry_wins - w_pw) > tol:
		_fail(
			failures,
			"kin_oblique: parry 0.25+align0 should use parry branch want %.6f got %.6f"
			% [w_pw, f_parry_wins]
		)
	var f_align_mid: float = _AttackResolver.penetration_oblique_angle_factor(3.0, 1.0, 0.5)
	var t_mid: float = (1.0 - 0.5) * ascale
	var w_mid: float = lerpf(1.0, amin, t_mid)
	if absf(f_align_mid - w_mid) > tol:
		_fail(failures, "kin_oblique: align 0.5 want %.6f got %.6f" % [w_mid, f_align_mid])


## Shared Tier **5.1** harness helper: one **`compute_and_apply_damage`** hit with meta-exposed pens (fresh manager each call).
static func _kin_dmg_pen_sample(vo: float, parry_r: float, align: float, strike_mods: Dictionary) -> Vector2:
	var intensity: float = 0.62
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
	m.register(_new_entity("SWORD"), "player")
	m.register(_new_entity("SWORD"), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	var aid: int = _EntityAccess.id_int(atk)
	var tid: int = _EntityAccess.id_int(tgt)
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		aid,
		tid,
		atk,
		tgt,
		"chest",
		intensity,
		"oberhau",
		arch,
		vo,
		1.0,
		1.0,
		-1.0,
		-1.0,
		parry_r,
		1.0,
		align,
		strike_mods,
		{}
	)
	var rd: Dictionary = res.get("result_dict", {}) as Dictionary
	var ps: float = float(rd.get("penetration_sharp_applied", -999.0))
	var pb: float = float(rd.get("penetration_blunt_mpa_applied", -999.0))
	_free_manager(m)
	return Vector2(ps, pb)


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** applies the same oblique factor to **SHARP** / **BLUNT** penetration as **`penetration_oblique_angle_factor`** (fresh manager per sample; manager meta **`_harness_expose_penetration_applied`** → **`penetration_sharp_applied`** / **`penetration_blunt_mpa_applied`** on **`result_dict`**).
static func _run_kinematic_delivery_compute_damage_oblique_penetration_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	var want_parry_half: float = lerpf(1.0, amin, 0.5)
	var want_align_zero: float = lerpf(1.0, amin, ascale)

	var base: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {})
	if base.x <= 0.001:
		_fail(failures, "kin_dmg_pen: baseline pen_sharp too small %.6f" % base.x)
	if base.y <= 0.0:
		_fail(failures, "kin_dmg_pen: baseline pen_blunt_mpa invalid %.6f" % base.y)

	var parry_half: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {})
	var r_ps_ph: float = parry_half.x / base.x
	var r_pb_ph: float = parry_half.y / base.y
	if absf(r_ps_ph - want_parry_half) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen: parry 0.5 sharp ratio %.4f want %.4f (base=%.4f half=%.4f)"
			% [r_ps_ph, want_parry_half, base.x, parry_half.x]
		)
	if absf(r_pb_ph - want_parry_half) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen: parry 0.5 blunt mpa ratio %.4f want %.4f (base=%.4f half=%.4f)"
			% [r_pb_ph, want_parry_half, base.y, parry_half.y]
		)

	var align_zero: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 0.0, {})
	var r_ps_az: float = align_zero.x / base.x
	var r_pb_az: float = align_zero.y / base.y
	if absf(r_ps_az - want_align_zero) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen: align 0 sharp ratio %.4f want %.4f (base=%.4f az=%.4f)"
			% [r_ps_az, want_align_zero, base.x, align_zero.x]
		)
	if absf(r_pb_az - want_align_zero) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen: align 0 blunt mpa ratio %.4f want %.4f (base=%.4f az=%.4f)"
			% [r_pb_az, want_align_zero, base.y, align_zero.y]
		)

	var base_der: Vector2 = _kin_dmg_pen_sample(-1.0, 1.0, 1.0, {})
	var parry_der: Vector2 = _kin_dmg_pen_sample(-1.0, 0.5, 1.0, {})
	if base_der.x <= 0.001:
		_fail(failures, "kin_dmg_pen: derived-v baseline pen_sharp too small %.6f" % base_der.x)
	if absf(parry_der.x / base_der.x - 1.0) > 0.02 or absf(parry_der.y / base_der.y - 1.0) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen: vo<0 parry 0.5 should not scale pens (base s=%.4f b=%.4f vs half s=%.4f b=%.4f)"
			% [base_der.x, base_der.y, parry_der.x, parry_der.y]
		)


## Tier 5.1 (optional long-tail): **`strike_mods`** — **`sharp_penetration_mult`** / **`blunt_momentum_pa_mult`** scale applied pens in **`compute_and_apply_damage`** (orthogonal; compose after oblique); **`cut_damage_mult`** / **`blunt_damage_mult`** do not (full hit or partial parry — **`_kin_dmg_pen_sample`**).
static func _run_kinematic_delivery_compute_damage_strike_mods_penetration_integration(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult_sharp: float = 1.35
	const mult_blunt: float = 1.22
	var base: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {})
	if base.x <= 0.001:
		_fail(failures, "kin_dmg_pen_sm: baseline pen_sharp too small %.6f" % base.x)
	if base.y <= 0.0:
		_fail(failures, "kin_dmg_pen_sm: baseline pen_blunt_mpa invalid %.6f" % base.y)
	var only_sharp: Vector2 = _kin_dmg_pen_sample(
		vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult_sharp}
	)
	if absf(only_sharp.x / base.x - mult_sharp) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen_sm: sharp mult ratio %.4f want %.4f (base=%.4f sm=%.4f)"
			% [only_sharp.x / base.x, mult_sharp, base.x, only_sharp.x]
		)
	if absf(only_sharp.y / base.y - 1.0) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen_sm: sharp mult should not scale blunt mpa (ratio %.4f)"
			% (only_sharp.y / base.y)
		)
	var only_blunt: Vector2 = _kin_dmg_pen_sample(
		vo_pin, 1.0, 1.0, {"blunt_momentum_pa_mult": mult_blunt}
	)
	if absf(only_blunt.x / base.x - 1.0) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen_sm: blunt mult should not scale sharp pen (ratio %.4f)"
			% (only_blunt.x / base.x)
		)
	if absf(only_blunt.y / base.y - mult_blunt) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen_sm: blunt mpa mult ratio %.4f want %.4f"
			% [only_blunt.y / base.y, mult_blunt]
		)
	var both: Vector2 = _kin_dmg_pen_sample(
		vo_pin,
		1.0,
		1.0,
		{"sharp_penetration_mult": mult_sharp, "blunt_momentum_pa_mult": mult_blunt}
	)
	if absf(both.x / base.x - mult_sharp) > 0.02 or absf(both.y / base.y - mult_blunt) > 0.02:
		_fail(
			failures,
			"kin_dmg_pen_sm: both mults want sharp×%.2f blunt×%.2f got ratios %.4f %.4f"
			% [mult_sharp, mult_blunt, both.x / base.x, both.y / base.y]
		)
	var half_base: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {})
	var half_sharp: Vector2 = _kin_dmg_pen_sample(
		vo_pin, 0.5, 1.0, {"sharp_penetration_mult": mult_sharp}
	)
	if half_base.x <= 0.001:
		_fail(failures, "kin_dmg_pen_sm: oblique baseline pen_sharp too small %.6f" % half_base.x)
	if absf(half_sharp.x / half_base.x - mult_sharp) > 0.03:
		_fail(
			failures,
			"kin_dmg_pen_sm: oblique+sharp_mult ratio %.4f want %.4f"
			% [half_sharp.x / half_base.x, mult_sharp]
		)
	var dmg_shape: Vector2 = _kin_dmg_pen_sample(
		vo_pin,
		1.0,
		1.0,
		{"cut_damage_mult": 1.55, "blunt_damage_mult": 0.72}
	)
	if absf(dmg_shape.x - base.x) > 0.0001 or absf(dmg_shape.y - base.y) > 0.0001:
		_fail(
			failures,
			"kin_dmg_pen_sm: cut/blunt_damage_mult must not change applied pens (base s=%.6f b=%.6f vs dmg s=%.6f b=%.6f)"
			% [base.x, base.y, dmg_shape.x, dmg_shape.y]
		)
	var half_dmg_shape: Vector2 = _kin_dmg_pen_sample(
		vo_pin,
		0.5,
		1.0,
		{"cut_damage_mult": 1.88, "blunt_damage_mult": 0.61}
	)
	if absf(half_dmg_shape.x - half_base.x) > 0.0001 or absf(half_dmg_shape.y - half_base.y) > 0.0001:
		_fail(
			failures,
			"kin_dmg_pen_sm: cut/blunt_damage_mult under partial parry must not change applied pens (half s=%.6f b=%.6f vs dmg s=%.6f b=%.6f)"
			% [half_base.x, half_base.y, half_dmg_shape.x, half_dmg_shape.y]
		)


## Tier 5.1 (optional long-tail): **`CombatConstants.get_line_alignment_with_deflect`** — continuous cos(θ) vs attack-angle-only vs discrete **`get_line_alignment`** vs **`guard_deflect_blend`** lerp.
static func _run_kinematic_delivery_line_alignment_with_deflect_branches(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 30.0
	const guard_deg: float = 45.0
	var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
	var want_both: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		{},
		both_ctx,
		{}
	)
	var exp_both: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
	)
	if absf(want_both - exp_both) > 0.0001:
		_fail(
			failures,
			"line_align_deflect: both angles want %.6f got %.6f" % [exp_both, want_both]
		)
	var def_low: Dictionary = {"guard_line": "low"}
	var only_atk_ctx: Dictionary = {"attack_angle_deg": atk_deg}
	var g_deg: float = CombatConstants.get_guard_angle_deg(def_low, {})
	var want_only_atk: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		def_low,
		only_atk_ctx,
		{}
	)
	var exp_only_atk: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_deg, g_deg)
	)
	if absf(want_only_atk - exp_only_atk) > 0.0001:
		_fail(
			failures,
			"line_align_deflect: attack_angle only want %.6f got %.6f (guard_deg=%.4f)"
			% [exp_only_atk, want_only_atk, g_deg]
		)
	var want_discrete: float = CombatConstants.get_line_alignment_with_deflect("high", def_low, {}, {})
	var exp_discrete: float = CombatConstants.get_line_alignment("high", "low")
	if absf(want_discrete - exp_discrete) > 0.0001:
		_fail(
			failures,
			"line_align_deflect: discrete want %.6f got %.6f" % [exp_discrete, want_discrete]
		)
	var def_blend: Dictionary = {
		"guard_line": "low",
		"guard_deflect_from_line": "high",
		"guard_deflect_blend": 0.5,
	}
	var want_blend: float = CombatConstants.get_line_alignment_with_deflect("high", def_blend, {}, {})
	var a_from: float = CombatConstants.get_line_alignment("high", "high")
	var a_to: float = CombatConstants.get_line_alignment("high", "low")
	var exp_blend: float = lerpf(a_from, a_to, 0.5)
	if absf(want_blend - exp_blend) > 0.0001:
		_fail(
			failures,
			"line_align_deflect: blend 0.5 want %.6f got %.6f" % [exp_blend, want_blend]
		)


## Tier 5.1 (optional long-tail): deterministic angle helpers used by deflection magnitude path — **`get_deflected_angle_bilateral`**, **`angle_to_nearest_line`**, **`line_to_angle`** (no RNG).
static func _run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers(
	failures: PackedStringArray
) -> void:
	if CombatConstants.angle_to_nearest_line(0.0) != "high":
		_fail(failures, "kin_line_angle: 0° want high got %s" % CombatConstants.angle_to_nearest_line(0.0))
	if CombatConstants.angle_to_nearest_line(90.0) != "right":
		_fail(failures, "kin_line_angle: 90° want right got %s" % CombatConstants.angle_to_nearest_line(90.0))
	if CombatConstants.angle_to_nearest_line(180.0) != "low":
		_fail(failures, "kin_line_angle: 180° want low got %s" % CombatConstants.angle_to_nearest_line(180.0))
	if CombatConstants.angle_to_nearest_line(270.0) != "left":
		_fail(failures, "kin_line_angle: 270° want left got %s" % CombatConstants.angle_to_nearest_line(270.0))
	if CombatConstants.angle_to_nearest_line(360.0) != "high":
		_fail(failures, "kin_line_angle: 360° want high got %s" % CombatConstants.angle_to_nearest_line(360.0))
	for ln in ["high", "right", "low", "left"]:
		var a: float = CombatConstants.line_to_angle(ln)
		if CombatConstants.angle_to_nearest_line(a) != ln:
			_fail(
				failures,
				"kin_line_angle: round-trip line %s angle %.1f → %s"
				% [ln, a, CombatConstants.angle_to_nearest_line(a)]
			)
	var b1: float = CombatConstants.get_deflected_angle_bilateral(0.0, 270.0, 10.0)
	if absf(b1 - 10.0) > 0.0001:
		_fail(failures, "kin_bilateral: (0,270,10) want 10 got %.4f" % b1)
	var b2: float = CombatConstants.get_deflected_angle_bilateral(200.0, 0.0, 15.0)
	if absf(b2 - fmod(200.0 - 15.0 + 360.0, 360.0)) > 0.0001:
		_fail(failures, "kin_bilateral: (200,0,15) want ccw 185 got %.4f" % b2)
	var b3: float = CombatConstants.get_deflected_angle_bilateral(0.0, 200.0, 5.0)
	if absf(b3 - 5.0) > 0.0001:
		_fail(failures, "kin_bilateral: (0,200,5) want cw 5 got %.4f" % b3)


## Tier 5.1 (optional long-tail): **`CombatConstants.get_deflected_line_from_angles`** same-line early return (bind) — skips magnitude RNG.
static func _run_kinematic_delivery_deflected_line_from_angles_same_line_bind(
	failures: PackedStringArray
) -> void:
	var hi: String = CombatConstants.get_deflected_line_from_angles(10.0, 350.0, 1.0, "cut", 0.5)
	if hi != "high":
		_fail(failures, "kin_deflect_same: high bind want high got %s" % hi)
	var rt: String = CombatConstants.get_deflected_line_from_angles(100.0, 110.0, 0.0, "stab", 0.2)
	if rt != "right":
		_fail(failures, "kin_deflect_same: right bind want right got %s" % rt)
	var lo: String = CombatConstants.get_deflected_line_from_angles(200.0, 190.0, 0.7, "blunt", 0.9)
	if lo != "low":
		_fail(failures, "kin_deflect_same: low bind want low got %s" % lo)
	var lf: String = CombatConstants.get_deflected_line_from_angles(270.0, 280.0, 0.3, "cut", 1.0)
	if lf != "left":
		_fail(failures, "kin_deflect_same: left bind want left got %s" % lf)


## Tier 5.1: **`CombatConstants.angle_diff_deg`** (shortest arc 0–180) + **`get_alignment_from_angles`** (cos θ floor).
static func _run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers(
	failures: PackedStringArray
) -> void:
	if CombatConstants.angle_diff_deg(350.0, 10.0) != 20.0:
		_fail(
			failures,
			"kin_angle_diff: 350→10 want 20 got %.4f" % CombatConstants.angle_diff_deg(350.0, 10.0)
		)
	if CombatConstants.angle_diff_deg(10.0, 350.0) != 20.0:
		_fail(
			failures,
			"kin_angle_diff: 10→350 want 20 got %.4f" % CombatConstants.angle_diff_deg(10.0, 350.0)
		)
	if CombatConstants.angle_diff_deg(0.0, 180.0) != 180.0:
		_fail(
			failures,
			"kin_angle_diff: 0→180 want 180 got %.4f" % CombatConstants.angle_diff_deg(0.0, 180.0)
		)
	if CombatConstants.angle_diff_deg(400.0, 40.0) != 0.0:
		_fail(
			failures,
			"kin_angle_diff: 400→40 (wrap) want 0 got %.4f" % CombatConstants.angle_diff_deg(400.0, 40.0)
		)
	var a1: float = CombatConstants.get_alignment_from_angles(0.0, 0.0)
	if absf(a1 - 1.0) > 0.0001:
		_fail(failures, "kin_align_from_angles: 0,0 want 1 got %.6f" % a1)
	var a2: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
	if absf(a2 - CombatConstants.PARRY_ALIGNMENT_FLOOR) > 0.0001:
		_fail(failures, "kin_align_from_angles: 0,180 want floor %.4f got %.6f" % [CombatConstants.PARRY_ALIGNMENT_FLOOR, a2])
	var a3: float = CombatConstants.get_alignment_from_angles(0.0, 60.0)
	if absf(a3 - 0.5) > 0.0001:
		_fail(failures, "kin_align_from_angles: 0,60 want 0.5 got %.6f" % a3)


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`** contract — when both angles present, path keys use **`angle_to_nearest_line`** (discrete **`ATTACK_PATHS_BY_GUARD`**); alignment still uses continuous **`get_line_alignment_with_deflect`** (not discrete **`get_line_alignment(attack_line, guard_line)`**). Mirrors resolver intercept math (no RNG).
static func _run_kinematic_delivery_path_lookup_discrete_from_angles_continuous_alignment(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 90.0
	const guard_deg: float = 0.0
	const atk_line_str: String = "high"
	const guard_line_str: String = "high"
	var align_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
	var atk_line_path: String = CombatConstants.angle_to_nearest_line(atk_deg)
	var guard_line_path: String = CombatConstants.angle_to_nearest_line(guard_deg)
	if atk_line_path != "right" or guard_line_path != "high":
		_fail(
			failures,
			"kin_path_angle_split: quantize want right/high got %s/%s"
			% [atk_line_path, guard_line_path]
		)
	var path_from_angles: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
	var path_from_strings: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
	if path_from_angles.is_empty() or path_from_strings.is_empty():
		_fail(failures, "kin_path_angle_split: empty path (angles=%s strings=%s)" % [path_from_angles, path_from_strings])
		return
	if path_from_angles[0] == path_from_strings[0]:
		_fail(
			failures,
			"kin_path_angle_split: first segment must differ (angle path %s vs string path %s)"
			% [path_from_angles[0], path_from_strings[0]]
		)
	var defender: Dictionary = {"guard_line": guard_line_str}
	var align_cont: float = CombatConstants.get_line_alignment_with_deflect(
		atk_line_str,
		defender,
		align_ctx,
		{}
	)
	var align_discrete: float = CombatConstants.get_line_alignment(atk_line_str, guard_line_str)
	var exp_cont: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
	)
	if absf(align_cont - exp_cont) > 0.0001:
		_fail(
			failures,
			"kin_path_angle_split: continuous align want %.6f got %.6f" % [exp_cont, align_cont]
		)
	if absf(align_discrete - 1.0) > 0.0001:
		_fail(
			failures,
			"kin_path_angle_split: discrete high/high want 1 got %.6f" % align_discrete
		)
	if align_cont >= align_discrete - 0.0001:
		_fail(
			failures,
			"kin_path_angle_split: continuous %.6f must be < discrete %.6f" % [align_cont, align_discrete]
		)
	var intercept_cont: int = _kin_path_intercept_max_index(path_from_angles, align_cont)
	var intercept_disc: int = _kin_path_intercept_max_index(path_from_strings, align_discrete)
	if intercept_cont <= intercept_disc:
		_fail(
			failures,
			"kin_path_angle_split: low continuous align ⇒ later intercept (cont=%d disc=%d)"
			% [intercept_cont, intercept_disc]
		)
	var partial_ctx: Dictionary = {"attack_angle_deg": atk_deg}
	var path_partial: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
	if path_partial[0] != path_from_strings[0]:
		_fail(
			failures,
			"kin_path_angle_split: guard_angle only must keep string path first=%s got %s"
			% [path_from_strings[0], path_partial[0]]
		)


static func _kin_path_intercept_max_index(path: Array, alignment: float) -> int:
	var intercept_max: int = int(
		lerpf(
			float(CombatConstants.PATH_INTERCEPT_EARLY_MAX),
			float(path.size() - 1),
			1.0 - alignment
		)
	)
	return clampi(intercept_max, 0, path.size() - 1)


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** lerps **`guard_deflect_from_line` → `guard_line`**; **`get_line_alignment_with_deflect`** attack-angle-only branch uses that blended guard (not discrete **`guard_line`** alone).
static func _run_kinematic_delivery_guard_deflect_blend_guard_angle_and_attack_only_align(
	failures: PackedStringArray
) -> void:
	var def_blend: Dictionary = {
		"guard_line": "low",
		"guard_deflect_from_line": "high",
		"guard_deflect_blend": 0.5,
	}
	var g_blend: float = CombatConstants.get_guard_angle_deg(def_blend, {"parry_readiness": 1.0})
	var exp_blend_deg: float = lerpf(
		CombatConstants.line_to_angle("high"),
		CombatConstants.line_to_angle("low"),
		0.5
	)
	if absf(g_blend - exp_blend_deg) > 0.0001:
		_fail(
			failures,
			"kin_guard_blend: guard angle want %.4f got %.4f" % [exp_blend_deg, g_blend]
		)
	var def_static: Dictionary = {"guard_line": "low"}
	var g_static: float = CombatConstants.get_guard_angle_deg(def_static, {"parry_readiness": 1.0})
	if absf(g_static - CombatConstants.line_to_angle("low")) > 0.0001:
		_fail(
			failures,
			"kin_guard_blend: no blend want low %.1f got %.4f" % [CombatConstants.line_to_angle("low"), g_static]
		)
	var atk_match: float = 90.0
	var align_match: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		def_blend,
		{"attack_angle_deg": atk_match},
		{"parry_readiness": 1.0}
	)
	var exp_match: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_match, g_blend)
	)
	if absf(align_match - exp_match) > 0.0001:
		_fail(
			failures,
			"kin_guard_blend: attack-only align@90° want %.6f got %.6f (guard=%.4f)"
			% [exp_match, align_match, g_blend]
		)
	# 10° vs blended guard (~90°) stays above PARRY_ALIGNMENT_FLOOR; static low (~180°) floors.
	const atk_mid: float = 10.0
	var align_blend_mid: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		def_blend,
		{"attack_angle_deg": atk_mid},
		{"parry_readiness": 1.0}
	)
	var exp_blend_mid: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_mid, g_blend)
	)
	if absf(align_blend_mid - exp_blend_mid) > 0.0001:
		_fail(
			failures,
			"kin_guard_blend: attack-only align@10° want %.6f got %.6f" % [exp_blend_mid, align_blend_mid]
		)
	var align_static_mid: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		def_static,
		{"attack_angle_deg": atk_mid},
		{"parry_readiness": 1.0}
	)
	if align_static_mid >= align_blend_mid - 0.0001:
		_fail(
			failures,
			"kin_guard_blend: static low guard should align lower than blended (static=%.6f blend=%.6f)"
			% [align_static_mid, align_blend_mid]
		)


## Tier 5.1 (optional long-tail): **`WeaponDamageHelper.compute_penetration`** return keys match **`AttackResolver`** consumption — **SHARP** **`penetration_sharp`** only; **BLUNT** **`penetration_blunt_momentum_per_area`** + **`blunt_contact_cm`** (bare + thrust depth coupling via **`armor_resistance_rha_mm`** / **`pen_sharp_mm`**).
static func _run_kinematic_delivery_compute_penetration_return_keys_and_thrust_blunt_contact(
	failures: PackedStringArray
) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	var mace: Weapon = _Weapon.create_from_definition("MACE")
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if sword == null or mace == null or spear == null:
		_fail(failures, "kin_pen_keys: missing sword/mace/spear")
		return
	var ai_cut: AttackInstance = AttackInstance.new("oberhau", 0.55)
	ai_cut.velocity_m_s = 11.0
	var d_sharp: Dictionary = WeaponDamageHelper.compute_penetration(
		sword, ai_cut, WeaponConstants.DAMAGE_TYPE_SHARP, {}
	)
	if not d_sharp.has("penetration_sharp"):
		_fail(failures, "kin_pen_keys: SHARP dict missing penetration_sharp keys=%s" % str(d_sharp.keys()))
	if d_sharp.has("penetration_blunt_momentum_per_area") or d_sharp.has("blunt_contact_cm"):
		_fail(
			failures,
			"kin_pen_keys: SHARP dict must not include blunt keys keys=%s" % str(d_sharp.keys())
		)
	var ai_blunt: AttackInstance = AttackInstance.new("direct_blow", 0.5)
	ai_blunt.velocity_m_s = 10.0
	var d_blunt: Dictionary = WeaponDamageHelper.compute_penetration(
		mace, ai_blunt, WeaponConstants.DAMAGE_TYPE_BLUNT, {}
	)
	if not d_blunt.has("penetration_blunt_momentum_per_area"):
		_fail(failures, "kin_pen_keys: BLUNT dict missing penetration_blunt_momentum_per_area")
	if not d_blunt.has("blunt_contact_cm"):
		_fail(failures, "kin_pen_keys: BLUNT dict missing blunt_contact_cm")
	var want_bc: float = WeaponDamageHelper.get_blunt_contact_cm(mace, ai_blunt)
	var got_bc: float = float(d_blunt.get("blunt_contact_cm", -1.0))
	if got_bc <= 0.0:
		_fail(failures, "kin_pen_keys: blunt_contact_cm must be > 0 got %.4f" % got_bc)
	if absf(got_bc - want_bc) > 0.0001:
		_fail(
			failures,
			"kin_pen_keys: blunt_contact_cm want %.4f got %.4f" % [want_bc, got_bc]
		)
	var pen_mpa: float = float(d_blunt.get("penetration_blunt_momentum_per_area", -1.0))
	if pen_mpa <= 0.0:
		_fail(failures, "kin_pen_keys: penetration_blunt_momentum_per_area must be > 0 got %.6f" % pen_mpa)
	var ai_thrust: AttackInstance = AttackInstance.new("spear_thrust", 0.6)
	ai_thrust.velocity_m_s = 12.0
	ai_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
	var pen_sharp_sp: float = float(
		WeaponDamageHelper.compute_penetration(spear, ai_thrust, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	if pen_sharp_sp <= 0.001:
		_fail(failures, "kin_pen_keys: spear thrust pen_sharp too small %.6f" % pen_sharp_sp)
	const armor_rha: float = 10.0
	var pen_for_blunt: float = pen_sharp_sp * 0.5
	var d_thrust_blunt: Dictionary = WeaponDamageHelper.compute_penetration(
		spear,
		ai_thrust,
		WeaponConstants.DAMAGE_TYPE_BLUNT,
		{
			"armor_resistance_rha_mm": armor_rha,
			"pen_sharp_mm": pen_for_blunt,
			"target_effective_mass_kg": 14.0,
		}
	)
	var point_w: float = maxf(float(spear.point_width), WeaponConstants.MIN_CONTACT_WIDTH_CM)
	var head_w: float = float(spear.thrust_head_width)
	if head_w <= 0.0:
		head_w = point_w
	var depth: float = clampf(pen_for_blunt / armor_rha, 0.0, 1.0)
	var want_thrust_bc: float = point_w + (head_w - point_w) * depth
	var got_thrust_bc: float = float(d_thrust_blunt.get("blunt_contact_cm", -1.0))
	if absf(got_thrust_bc - want_thrust_bc) > 0.0001:
		_fail(
			failures,
			"kin_pen_keys: thrust depth-coupled blunt_contact want %.4f got %.4f (depth=%.3f)"
			% [want_thrust_bc, got_thrust_bc, depth]
		)
	if head_w > point_w + 0.01 and depth > 0.01 and depth < 0.99:
		var bare_thrust_bc: float = WeaponDamageHelper.get_blunt_contact_cm(spear, ai_thrust)
		if absf(got_thrust_bc - bare_thrust_bc) < 0.0001:
			_fail(
				failures,
				"kin_pen_keys: depth-coupled contact should differ from bare (bare=%.4f coupled=%.4f depth=%.3f)"
				% [bare_thrust_bc, got_thrust_bc, depth]
		 )


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=false)`** matches **`line_to_angle`**; **`variance_context`** ignored without variance RNG.
static func _run_kinematic_delivery_attack_angle_deg_no_variance_deterministic(
	failures: PackedStringArray
) -> void:
	for ln in ["high", "right", "low", "left"]:
		var want: float = CombatConstants.line_to_angle(ln)
		var got: float = CombatConstants.get_attack_angle_deg(ln, false, {}, {})
		if absf(got - want) > 0.0001:
			_fail(
				failures,
				"kin_atk_angle_nv: line %s want %.1f got %.4f" % [ln, want, got]
			)
	seed(90211)
	var with_ctx: float = CombatConstants.get_attack_angle_deg(
		"high",
		false,
		{},
		{"stamina_ratio": 0.05, "off_balance": true, "weapon_mass_kg": 4.0}
	)
	seed(90211)
	var bare: float = CombatConstants.get_attack_angle_deg("high", false, {}, {})
	if absf(with_ctx - bare) > 0.0001:
		_fail(
			failures,
			"kin_atk_angle_nv: variance_context must not affect add_variance=false (ctx=%.4f bare=%.4f)"
			% [with_ctx, bare]
		)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Replicate **`AttackResolver.compute_and_apply_damage`** velocity assembly (not parry **`v_intent`**).
static func _kin_expected_damage_velocity_m_s(
	mgr: Node,
	atk: Dictionary,
	tgt: Dictionary,
	intensity: float,
	arch: Dictionary,
	move_id: String,
	velocity_override: float,
	afterblow_damage_mult: float,
	strike_physics_ctx: Dictionary = {}
) -> float:
	var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
	if weapon == null:
		return -1.0
	var v_base: float = (
		velocity_override
		if velocity_override >= 0.0
		else WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, weapon, move_id)
	)
	var v: float = v_base * _StrikePhysics.closing_speed_multiplier(mgr, atk, tgt, strike_physics_ctx)
	var st_ratio: float = clampf(
		_EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0
	)
	v *= sqrt(
		lerpf(
			CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT,
			1.0,
			CombatConstants.stamina_factor(st_ratio)
		)
	)
	if afterblow_damage_mult < 1.0:
		v *= sqrt(maxf(0.04, afterblow_damage_mult))
	return clampf(v, _ImpactVelocityModel.ABS_VELOCITY_MIN_M_S, _ImpactVelocityModel.ABS_VELOCITY_MAX_M_S)


static func _kin_pen_sharp_at_velocity(
	weapon: Weapon,
	move_id: String,
	arch: Dictionary,
	intensity: float,
	v_m_s: float,
	strike_mods: Dictionary = {}
) -> float:
	var ai: AttackInstance = AttackInstance.new(move_id, intensity)
	ai.archetype = arch
	ai.velocity_m_s = v_m_s
	ai.strike_energy_mult = float(strike_mods.get("strike_energy_mult", 1.0))
	ai.strike_momentum_mult = float(strike_mods.get("strike_momentum_mult", 1.0))
	return float(
		WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)


## Tier 5.1 (optional long-tail): hit damage **`velocity_m_s`** path matches **`WeaponDamageHelper`** at replicated effective **`v`**; **`compute_and_apply_damage`** → **`take_damage_split`** contract (**`damage_type` SPLIT**, **`mechanical_post_armor`**, tissue delta).
static func _run_kinematic_delivery_compute_damage_velocity_and_entity_split(
	failures: PackedStringArray
) -> void:
	const intensity: float = 0.62
	const move_id: String = "oberhau"
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_dmg_v_entity: missing sword")
		return
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
	m.register(_new_entity("SWORD"), "player")
	m.register(_new_entity("SWORD"), "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	var tgt_n: Node = _EntityAccess.scene_node(tgt)
	if tgt_n == null:
		_fail(failures, "kin_dmg_v_entity: missing target node")
		_free_manager(m)
		return
	var cut_before: float = float(tgt_n.body_cutting.get("chest", 0.0))
	for case in [
		{"vo": -1.0, "label": "derived"},
		{"vo": 11.0, "label": "pinned"},
	]:
		var vo: float = float(case["vo"])
		var v_exp: float = _kin_expected_damage_velocity_m_s(
			m, atk, tgt, intensity, arch, move_id, vo, 1.0
		)
		var pen_exp: float = _kin_pen_sharp_at_velocity(sword, move_id, arch, intensity, v_exp, {})
		var pen_int: float = _kin_dmg_pen_sample(vo, 1.0, 1.0, {}).x
		if pen_exp <= 0.001:
			_fail(failures, "kin_dmg_v_entity: %s pen_exp too small %.6f" % [case["label"], pen_exp])
		elif absf(pen_int / pen_exp - 1.0) > 0.02:
			_fail(
				failures,
				"kin_dmg_v_entity: %s pen ratio %.4f want ~1 (int=%.4f exp=%.4f v=%.4f)"
				% [case["label"], pen_int / pen_exp, pen_int, pen_exp, v_exp]
			)
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		intensity,
		move_id,
		arch,
		11.0,
		1.0,
		1.0,
		-1.0,
		-1.0,
		1.0,
		1.0,
		1.0,
		{},
		{}
	)
	var rd: Dictionary = res.get("result_dict", {}) as Dictionary
	if str(rd.get("damage_type", "")) != "SPLIT":
		_fail(failures, "kin_dmg_v_entity: damage_type want SPLIT got %s" % str(rd.get("damage_type")))
	if float(rd.get("mechanical_post_armor", -1.0)) < 0.0:
		_fail(
			failures,
			"kin_dmg_v_entity: mechanical_post_armor missing (EntityDamage path not taken?)"
		)
	var total_phys: float = float(rd.get("total_physical", 0.0))
	var final_cut: float = float(rd.get("final_cut", 0.0))
	var cut_after: float = float(tgt_n.body_cutting.get("chest", 0.0))
	if total_phys > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS and final_cut > 0.0 and cut_after >= cut_before:
		_fail(
			failures,
			"kin_dmg_v_entity: chest cut should drop on hit (before=%.2f after=%.2f final_cut=%.2f)"
			% [cut_before, cut_after, final_cut]
		)
	_free_manager(m)


## Tier 5.1 (optional long-tail): **`alignment_context.guard_angle_deg` alone is ignored** — without **`attack_angle_deg`**, **`get_line_alignment_with_deflect`** uses **`get_guard_angle_deg`** / discrete **`guard_line`** (not the context guard angle).
static func _run_kinematic_delivery_alignment_context_guard_angle_only_uses_combatant_guard(
	failures: PackedStringArray
) -> void:
	var defender: Dictionary = {"guard_line": "right"}
	var ctx_guard_only: Dictionary = {"guard_angle_deg": 180.0}
	var got: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		defender,
		ctx_guard_only,
		{"parry_readiness": 1.0}
	)
	var exp_discrete: float = CombatConstants.get_line_alignment("high", "right")
	if absf(got - exp_discrete) > 0.0001:
		_fail(
			failures,
			"kin_align_ctx: guard_angle only want discrete high/right %.6f got %.6f"
			% [exp_discrete, got]
		)
	var wrong_ctx_pair: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(0.0, 180.0)
	)
	if absf(got - wrong_ctx_pair) < 0.0001:
		_fail(
			failures,
			"kin_align_ctx: must not pair line high° with context guard 180° alone (floor %.6f)"
			% wrong_ctx_pair
		)
	if exp_discrete <= CombatConstants.PARRY_ALIGNMENT_FLOOR + 0.01:
		_fail(
			failures,
			"kin_align_ctx: fixture needs discrete align above floor (got %.6f)" % exp_discrete
		)


## Tier 5.1 (optional long-tail): parry **`v_intent`** base is **`WeaponDamageHelper.get_effective_velocity_m_s`** × **`StrikeRealismProfile.velocity_intent_mult_from_pa`** (pinned station); damage **KE** uses effective **`v`** without intent mult.
static func _run_kinematic_delivery_parry_v_intent_effective_velocity_base(
	failures: PackedStringArray
) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	if sword == null:
		_fail(failures, "kin_parry_v: missing sword")
		return
	const move_id: String = "oberhau"
	const intensity: float = 0.62
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	var ai_derived: AttackInstance = AttackInstance.new(move_id, intensity)
	ai_derived.archetype = arch
	ai_derived.velocity_m_s = -1.0
	var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_derived)
	var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, sword, move_id)
	if absf(v_eff - v_from_i) > 0.0001:
		_fail(
			failures,
			"kin_parry_v: derived v_eff want %.6f got %.6f" % [v_from_i, v_eff]
		)
	var ai_pin: AttackInstance = AttackInstance.new(move_id, intensity)
	ai_pin.archetype = arch
	ai_pin.velocity_m_s = 10.0
	if absf(WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_pin) - 10.0) > 0.0001:
		_fail(failures, "kin_parry_v: pinned v_eff should be 10")
	var pa_tip: Dictionary = {"impact_blade_station": 0.92, "strike_measure_ratio": 1.0}
	var pa_guard: Dictionary = {"impact_blade_station": 0.12, "strike_measure_ratio": 1.0}
	var mult_tip: float = _StrikeRealism.velocity_intent_mult_from_pa(
		pa_tip, sword, move_id, intensity, arch
	)
	var mult_guard: float = _StrikeRealism.velocity_intent_mult_from_pa(
		pa_guard, sword, move_id, intensity, arch
	)
	if mult_tip <= mult_guard + 0.0001:
		_fail(
			failures,
			"kin_parry_v: cut tip station mult %.4f should exceed guard %.4f" % [mult_tip, mult_guard]
		)
	var v_intent_tip: float = v_eff * mult_tip
	var ke_damage: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_derived)
	var ai_intent: AttackInstance = AttackInstance.new(move_id, intensity)
	ai_intent.archetype = arch
	ai_intent.velocity_m_s = v_intent_tip
	var ke_at_intent: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_intent)
	if ke_at_intent <= ke_damage + 1e-4:
		_fail(
			failures,
			"kin_parry_v: intent v should raise KE (damage=%.4f intent=%.4f)" % [ke_damage, ke_at_intent]
		)
	var ratio_v: float = v_intent_tip / maxf(v_eff, 0.001)
	var ratio_ke: float = ke_at_intent / maxf(ke_damage, 0.001)
	if absf(ratio_ke - ratio_v * ratio_v) > 0.08:
		_fail(
			failures,
			"kin_parry_v: KE ratio %.4f want ~(v ratio)^2 %.4f" % [ratio_ke, ratio_v * ratio_v]
		)


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** wobble when **`parry_readiness` < 1** (seeded); readiness **1** matches **`line_to_angle(guard_line)`** without blend.
static func _run_kinematic_delivery_guard_wobble_readiness_shifts_guard_angle(
	failures: PackedStringArray
) -> void:
	var defender: Dictionary = {"guard_line": "high"}
	var wobble_ctx_full: Dictionary = {"parry_readiness": 1.0}
	var stable: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_full)
	if absf(stable - CombatConstants.line_to_angle("high")) > 0.0001:
		_fail(
			failures,
			"kin_guard_wobble: readiness 1 want high %.1f got %.4f"
			% [CombatConstants.line_to_angle("high"), stable]
		)
	seed(44001)
	var wobble_ctx_low: Dictionary = {"parry_readiness": 0.0}
	var wobbled: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_low)
	if absf(wobbled - stable) < 0.05:
		_fail(
			failures,
			"kin_guard_wobble: readiness 0 should shift angle (stable=%.4f wobbled=%.4f)"
			% [stable, wobbled]
		)
	var max_shift: float = CombatConstants.GUARD_WOBBLE_MAX_DEG + 0.01
	if CombatConstants.angle_diff_deg(wobbled, stable) > max_shift:
		_fail(
			failures,
			"kin_guard_wobble: shift %.4f exceeds max wobble %.4f"
			% [CombatConstants.angle_diff_deg(wobbled, stable), CombatConstants.GUARD_WOBBLE_MAX_DEG]
		)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## One **`compute_and_apply_damage`** sample with harness meta exposing pens + **`strike_ke_j`** + **`blunt_contact_cm`** (+ pre-armor when kinematics meta set).
static func _kin_dmg_integration_sample(
	vo: float,
	parry_r: float,
	align: float,
	strike_mods: Dictionary,
	weapon_id: String = "SWORD",
	move_id: String = "oberhau",
	afterblow_mult: float = 1.0,
	arch_override: Dictionary = {},
	tgt_overrides: Dictionary = {},
	tgt_chest_armor_id: String = "",
	strike_physics_ctx: Dictionary = {}
) -> Dictionary:
	var intensity: float = 0.62
	var arch: Dictionary = arch_override
	if arch.is_empty():
		arch = (
			{"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
			if move_id == "spear_thrust"
			else {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
		)
	var m: Node = _MgrScript.new()
	m.set_meta(_HARNESS_META_EXPOSE_PENETRATION_APPLIED, true)
	m.set_meta(_HARNESS_META_EXPOSE_DAMAGE_KINEMATICS, true)
	m.register(_new_entity(weapon_id), "player")
	var tgt_ent: CoreEntity = _new_entity(weapon_id)
	if not tgt_chest_armor_id.is_empty():
		var ap: Variant = _ArmorPiece.create_from_definition(tgt_chest_armor_id)
		if ap != null:
			tgt_ent.equip_armor("chest", ap)
	m.register(tgt_ent, "enemy")
	m.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var atk: Dictionary = m.combatants[0]
	var tgt: Dictionary = m.combatants[1]
	for ok in tgt_overrides:
		tgt[ok] = tgt_overrides[ok]
	var res: Dictionary = _AttackResolver.compute_and_apply_damage(
		m,
		_EntityAccess.id_int(atk),
		_EntityAccess.id_int(tgt),
		atk,
		tgt,
		"chest",
		intensity,
		move_id,
		arch,
		vo,
		1.0,
		1.0,
		-1.0,
		-1.0,
		parry_r,
		afterblow_mult,
		align,
		strike_mods,
		strike_physics_ctx
	)
	var rd: Dictionary = res.get("result_dict", {}) as Dictionary
	return {
		"mgr": m,
		"atk": atk,
		"tgt": tgt,
		"intensity": intensity,
		"arch": arch,
		"move_id": move_id,
		"weapon_id": weapon_id,
		"afterblow_mult": afterblow_mult,
		"strike_physics_ctx": strike_physics_ctx,
		"pen_sharp": float(rd.get("penetration_sharp_applied", -999.0)),
		"pen_blunt_mpa": float(rd.get("penetration_blunt_mpa_applied", -999.0)),
		"strike_ke_j": float(rd.get("strike_ke_j_applied", -999.0)),
		"blunt_contact_cm": float(rd.get("blunt_contact_cm_applied", -999.0)),
		"pre_cut": float(rd.get("pre_cut_applied", -999.0)),
		"pre_blunt": float(rd.get("pre_blunt_applied", -999.0)),
		"final_cut": float(rd.get("final_cut", -999.0)),
		"final_blunt": float(rd.get("final_blunt", -999.0)),
		"mechanical_post_armor": float(rd.get("mechanical_post_armor", -999.0)),
		"total_physical": float(rd.get("total_physical", -999.0)),
	}


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** exposed **`strike_ke_j_applied`** matches **`compute_kinetic_energy_j`** at assembled **`v`**; **`blunt_contact_cm_applied`** matches **`compute_penetration`** **BLUNT** dict (same armor opts as resolver).
static func _run_kinematic_delivery_compute_damage_strike_ke_and_blunt_contact_exposed(
	failures: PackedStringArray
) -> void:
	const move_id: String = "oberhau"
	const vo_pin: float = 11.0
	var sample: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var m: Node = sample["mgr"] as Node
	var atk: Dictionary = sample["atk"] as Dictionary
	var tgt: Dictionary = sample["tgt"] as Dictionary
	var intensity: float = float(sample["intensity"])
	var arch: Dictionary = sample["arch"] as Dictionary
	var v_asm: float = _kin_expected_damage_velocity_m_s(
		m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0
	)
	var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
	if weapon == null:
		_fail(failures, "kin_dmg_kin_exposed: missing weapon")
		_free_manager(m)
		return
	var ai: AttackInstance = AttackInstance.new(move_id, intensity)
	ai.archetype = arch
	ai.velocity_m_s = v_asm
	var ke_want: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, ai)
	var ke_got: float = float(sample["strike_ke_j"])
	if ke_want <= 0.5:
		_fail(failures, "kin_dmg_kin_exposed: ke_want too small %.4f" % ke_want)
	elif absf(ke_got / ke_want - 1.0) > 0.02:
		_fail(
			failures,
			"kin_dmg_kin_exposed: strike_ke_j ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
			% [ke_got / ke_want, ke_got, ke_want, v_asm]
		)
	var pen_sharp_raw: float = float(
		WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
			"penetration_sharp", -1.0
		)
	)
	var blunt_opts: Dictionary = {
		"pen_sharp_mm": pen_sharp_raw,
		"target_effective_mass_kg": WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest"),
	}
	var tgt_n: Node = _EntityAccess.scene_node(tgt)
	if tgt_n != null and tgt_n.has_method("get_armor_sharp_resistance_for_part"):
		blunt_opts["armor_resistance_rha_mm"] = tgt_n.get_armor_sharp_resistance_for_part("chest")
	var bc_want: float = float(
		WeaponDamageHelper.compute_penetration(
			weapon, ai, WeaponConstants.DAMAGE_TYPE_BLUNT, blunt_opts
		).get("blunt_contact_cm", -1.0)
	)
	var bc_got: float = float(sample["blunt_contact_cm"])
	if bc_want <= 0.0:
		_fail(failures, "kin_dmg_kin_exposed: blunt_contact_cm want > 0 got %.4f" % bc_want)
	elif absf(bc_got - bc_want) > 0.0001:
		_fail(
			failures,
			"kin_dmg_kin_exposed: blunt_contact_cm want %.4f got %.4f" % [bc_want, bc_got]
		)
	if float(sample["pen_sharp"]) <= 0.001:
		_fail(failures, "kin_dmg_kin_exposed: pen_sharp_applied missing/too small")
	_free_manager(m)


## Tier 5.1 (optional long-tail): both angles in **`alignment_context`** ⇒ continuous cos(θ); **`wobble_context`** ignored.
static func _run_kinematic_delivery_alignment_both_angles_ignores_wobble(
	failures: PackedStringArray
) -> void:
	const atk_deg: float = 30.0
	const guard_deg: float = 45.0
	var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
	var stable: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		{},
		both_ctx,
		{"parry_readiness": 1.0}
	)
	seed(44002)
	var wobbled: float = CombatConstants.get_line_alignment_with_deflect(
		"high",
		{},
		both_ctx,
		{"parry_readiness": 0.0}
	)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	var exp: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
	)
	if absf(stable - exp) > 0.0001:
		_fail(failures, "kin_align_wobble_both: stable want %.6f got %.6f" % [exp, stable])
	if absf(wobbled - stable) > 0.0001:
		_fail(
			failures,
			"kin_align_wobble_both: wobble must not change both-angle align (stable=%.6f wobbled=%.6f)"
			% [stable, wobbled]
		)


## Tier 5.1 (optional long-tail): attack-angle-only branch uses **`get_guard_angle_deg`** wobble — low **`parry_readiness`** changes alignment vs readiness **1**.
static func _run_kinematic_delivery_attack_angle_only_wobble_changes_alignment(
	failures: PackedStringArray
) -> void:
	var defender: Dictionary = {"guard_line": "high"}
	var atk_only: Dictionary = {"attack_angle_deg": 0.0}
	var stable: float = CombatConstants.get_line_alignment_with_deflect(
		"right",
		defender,
		atk_only,
		{"parry_readiness": 1.0}
	)
	seed(44003)
	var wobbled: float = CombatConstants.get_line_alignment_with_deflect(
		"right",
		defender,
		atk_only,
		{"parry_readiness": 0.0}
	)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	var g_stable: float = CombatConstants.get_guard_angle_deg(defender, {"parry_readiness": 1.0})
	var exp_stable: float = maxf(
		CombatConstants.PARRY_ALIGNMENT_FLOOR,
		CombatConstants.get_alignment_from_angles(0.0, g_stable)
	)
	if absf(stable - exp_stable) > 0.0001:
		_fail(
			failures,
			"kin_align_wobble_atk: stable want %.6f got %.6f" % [exp_stable, stable]
		)
	if absf(wobbled - stable) < 0.0001:
		_fail(
			failures,
			"kin_align_wobble_atk: readiness 0 should change align (stable=%.6f wobbled=%.6f)"
			% [stable, wobbled]
		)


## Tier 5.1 (optional long-tail): partial parry scales applied pens but not assembled **`strike_ke_j`** (pinned **`velocity_override`**).
static func _run_kinematic_delivery_partial_parry_strike_ke_unchanged_pen_scaled(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var full: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var half: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {})
	var ke_full: float = float(full["strike_ke_j"])
	var ke_half: float = float(half["strike_ke_j"])
	var pen_full: float = float(full["pen_sharp"])
	var pen_half: float = float(half["pen_sharp"])
	_free_manager(full["mgr"] as Node)
	_free_manager(half["mgr"] as Node)
	if ke_full <= 0.5:
		_fail(failures, "kin_partial_parry: ke_full too small %.4f" % ke_full)
	if absf(ke_half / ke_full - 1.0) > 0.02:
		_fail(
			failures,
			"kin_partial_parry: strike_ke_j should ignore parry (full=%.4f half=%.4f)"
			% [ke_full, ke_half]
		)
	if pen_half >= pen_full - 0.0001:
		_fail(
			failures,
			"kin_partial_parry: pen_sharp should drop (full=%.4f half=%.4f)" % [pen_full, pen_half]
		)
	var want_ratio: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	want_ratio = lerpf(1.0, want_ratio, 0.5)
	if absf(pen_half / pen_full - want_ratio) > 0.03:
		_fail(
			failures,
			"kin_partial_parry: pen ratio %.4f want %.4f" % [pen_half / pen_full, want_ratio]
		)


static func _kin_expected_pre_armor_cut_blunt(
	weapon: Weapon,
	atk: Dictionary,
	tgt: Dictionary,
	move_id: String,
	intensity: float,
	arch: Dictionary,
	v_m_s: float,
	parry_r: float,
	strike_mods: Dictionary
) -> Vector2:
	var ai: AttackInstance = AttackInstance.new(move_id, intensity)
	ai.archetype = arch
	ai.velocity_m_s = v_m_s
	var atk_n: Node = _EntityAccess.scene_node(atk)
	var arm_mod: float = (
		atk_n.get_attack_damage_modifier()
		if atk_n != null and atk_n.has_method("get_attack_damage_modifier")
		else 1.0
	)
	var atk_str: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
	var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest")
	var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, move_id, arch)
	if (
		weapon.get_contact_type(move_id) == WeaponConstants.ATTACK_TYPE_CUT
		and v_m_s >= 0.0
		and parry_r < 1.0
	):
		var redirect: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_r)
		cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect)
	var pre_cut: float = (
		WeaponDamageHelper.compute_pre_armor_cut(weapon, ai, atk_str, arm_mod)
		* cut_ratio
		* float(strike_mods.get("cut_damage_mult", 1.0))
	)
	var pre_blunt: float = (
		WeaponDamageHelper.compute_pre_armor_blunt(weapon, ai, atk_str, arm_mod, target_mass)
		* (1.0 - cut_ratio)
		* float(strike_mods.get("blunt_damage_mult", 1.0))
	)
	var stance_mult: float = CombatConstants.get_stance_modifier(_EntityAccess.stance_str(atk), "damage")
	return Vector2(pre_cut * stance_mult, pre_blunt * stance_mult)


## Tier 5.1 (optional long-tail): exposed **`pre_cut_applied`** / **`pre_blunt_applied`** match **`WeaponDamageHelper`** at assembled **`v`** (incl. parry cut→blunt shift + stance).
static func _run_kinematic_delivery_compute_damage_pre_armor_matches_helper_at_assembled_v(
	failures: PackedStringArray
) -> void:
	const move_id: String = "oberhau"
	const vo_pin: float = 11.0
	const intensity: float = 0.62
	var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
	for case in [
		{"parry_r": 1.0, "label": "clean"},
		{"parry_r": 0.5, "label": "partial_parry"},
	]:
		var sample: Dictionary = _kin_dmg_integration_sample(vo_pin, float(case["parry_r"]), 1.0, {})
		var m: Node = sample["mgr"] as Node
		var atk: Dictionary = sample["atk"] as Dictionary
		var tgt: Dictionary = sample["tgt"] as Dictionary
		var weapon: Weapon = _EntityAccess.get_weapon(atk) as Weapon
		if weapon == null:
			_fail(failures, "kin_pre_armor: missing weapon (%s)" % case["label"])
			_free_manager(m)
			return
		var v_asm: float = _kin_expected_damage_velocity_m_s(
			m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0
		)
		var want: Vector2 = _kin_expected_pre_armor_cut_blunt(
			weapon, atk, tgt, move_id, intensity, arch, v_asm, float(case["parry_r"]), {}
		)
		var got_cut: float = float(sample["pre_cut"])
		var got_blunt: float = float(sample["pre_blunt"])
		if got_cut < 0.0 or got_blunt < 0.0:
			_fail(failures, "kin_pre_armor: missing pre_armor meta (%s)" % case["label"])
		elif absf(got_cut / maxf(want.x, 0.001) - 1.0) > 0.03:
			_fail(
				failures,
				"kin_pre_armor: %s pre_cut ratio %.4f (got=%.4f want=%.4f)"
				% [case["label"], got_cut / want.x, got_cut, want.x]
			)
		elif absf(got_blunt / maxf(want.y, 0.001) - 1.0) > 0.03:
			_fail(
				failures,
				"kin_pre_armor: %s pre_blunt ratio %.4f (got=%.4f want=%.4f)"
				% [case["label"], got_blunt / want.y, got_blunt, want.y]
			)
		_free_manager(m)


## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` ≥ 0**) shifts **`PARRY_CUT_TO_BLUNT_SHIFT`** — **`pre_blunt_applied`** rises vs clean parry; **`pre_cut_applied`** falls.
static func _run_kinematic_delivery_partial_parry_cut_to_blunt_shift(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {})
	var pre_cut_clean: float = float(clean["pre_cut"])
	var pre_cut_part: float = float(partial["pre_cut"])
	var pre_blunt_clean: float = float(clean["pre_blunt"])
	var pre_blunt_part: float = float(partial["pre_blunt"])
	_free_manager(clean["mgr"] as Node)
	_free_manager(partial["mgr"] as Node)
	if pre_cut_clean <= 0.1 or pre_blunt_clean < 0.0:
		_fail(failures, "kin_cut_blunt_shift: clean pre_armor invalid cut=%.4f blunt=%.4f" % [pre_cut_clean, pre_blunt_clean])
	if pre_cut_part >= pre_cut_clean - 0.01:
		_fail(
			failures,
			"kin_cut_blunt_shift: partial parry should reduce pre_cut (clean=%.4f partial=%.4f)"
			% [pre_cut_clean, pre_cut_part]
		)
	if pre_blunt_part <= pre_blunt_clean + 0.01:
		_fail(
			failures,
			"kin_cut_blunt_shift: partial parry should raise pre_blunt (clean=%.4f partial=%.4f)"
			% [pre_blunt_clean, pre_blunt_part]
		)
	var share_clean: float = pre_cut_clean / maxf(pre_cut_clean + pre_blunt_clean, 0.001)
	var share_part: float = pre_cut_part / maxf(pre_cut_part + pre_blunt_part, 0.001)
	if share_part >= share_clean - 0.01:
		_fail(
			failures,
			"kin_cut_blunt_shift: cut share should drop (clean=%.4f partial=%.4f)"
			% [share_clean, share_part]
		)


## Tier 5.1 (optional long-tail): **`velocity_override` < 0** — partial parry does not apply **`PARRY_CUT_TO_BLUNT_SHIFT`** (pre-armor mix unchanged; pens already ⊥ oblique).
static func _run_kinematic_delivery_derived_velocity_no_cut_to_blunt_shift_on_partial_parry(
	failures: PackedStringArray
) -> void:
	var clean: Dictionary = _kin_dmg_integration_sample(-1.0, 1.0, 1.0, {})
	var partial: Dictionary = _kin_dmg_integration_sample(-1.0, 0.5, 1.0, {})
	_free_manager(clean["mgr"] as Node)
	_free_manager(partial["mgr"] as Node)
	if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_derived_no_shift: pre_cut should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_cut"]), float(partial["pre_cut"])]
		)
	if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
		_fail(
			failures,
			"kin_derived_no_shift: pre_blunt should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
		)


## Tier 5.1 (optional long-tail): misaligned guard (**`alignment` 0**, full parry) scales pens via oblique factor but not **`pre_cut_applied`** / **`pre_blunt_applied`** (pinned **`vo`**).
static func _run_kinematic_delivery_misaligned_guard_scales_pen_not_pre_armor(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var aligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var misaligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
	_free_manager(aligned["mgr"] as Node)
	_free_manager(misaligned["mgr"] as Node)
	if absf(float(aligned["pre_cut"]) - float(misaligned["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_misalign: pre_cut should be unchanged (aligned=%.4f misaligned=%.4f)"
			% [float(aligned["pre_cut"]), float(misaligned["pre_cut"])]
		)
	if absf(float(aligned["pre_blunt"]) - float(misaligned["pre_blunt"])) > 0.02:
		_fail(
			failures,
			"kin_misalign: pre_blunt should be unchanged (aligned=%.4f misaligned=%.4f)"
			% [float(aligned["pre_blunt"]), float(misaligned["pre_blunt"])]
		)
	var want_pen_ratio: float = lerpf(
		1.0,
		CombatConstants.PARRY_PENETRATION_ANGLE_MIN,
		CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	)
	var pen_ratio: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
	if absf(pen_ratio - want_pen_ratio) > 0.03:
		_fail(
			failures,
			"kin_misalign: pen_sharp ratio %.4f want %.4f" % [pen_ratio, want_pen_ratio]
		)


## Tier 5.1 (optional long-tail): **`get_attack_path`** unknown guard line falls back to **`ATTACK_PATHS[attack_line]`** (not **`ATTACK_PATHS_BY_GUARD`**).
static func _run_kinematic_delivery_get_attack_path_fallback_to_attack_paths(
	failures: PackedStringArray
) -> void:
	var by_guard: Array = CombatConstants.get_attack_path("high", "low")
	var fallback: Array = CombatConstants.get_attack_path("high", "__no_such_guard__")
	var want: Array = CombatConstants.ATTACK_PATHS.get("high", CombatConstants.ATTACK_PATH_HIGH)
	if fallback.is_empty():
		_fail(failures, "kin_attack_path: fallback path empty")
	if str(fallback) != str(want):
		_fail(
			failures,
			"kin_attack_path: fallback want ATTACK_PATHS[high] got %s" % str(fallback)
		)
	if str(by_guard) == str(fallback):
		_fail(failures, "kin_attack_path: guard-specific path should differ from fallback")


## Tier 5.1 (optional long-tail): **`strike_mods`** **`cut_damage_mult`** / **`blunt_damage_mult`** scale pre-armor only (not **`penetration_sharp_applied`**).
static func _run_kinematic_delivery_strike_mods_damage_mults_scale_pre_armor_only(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const cut_mult: float = 1.4
	const blunt_mult: float = 1.25
	var base: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = _kin_dmg_integration_sample(
		vo_pin,
		1.0,
		1.0,
		{"cut_damage_mult": cut_mult, "blunt_damage_mult": blunt_mult}
	)
	_free_manager(base["mgr"] as Node)
	_free_manager(shaped["mgr"] as Node)
	if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - cut_mult) > 0.03:
		_fail(
			failures,
			"kin_dmg_mults: pre_cut ratio %.4f want %.4f"
			% [float(shaped["pre_cut"]) / float(base["pre_cut"]), cut_mult]
		)
	if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - blunt_mult) > 0.03:
		_fail(
			failures,
			"kin_dmg_mults: pre_blunt ratio %.4f want %.4f"
			% [float(shaped["pre_blunt"]) / float(base["pre_blunt"]), blunt_mult]
		)
	if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
		_fail(
			failures,
			"kin_dmg_mults: pen_sharp should ignore damage mults (base=%.4f shaped=%.4f)"
			% [float(base["pen_sharp"]), float(shaped["pen_sharp"])]
		)


## Tier 5.1 (optional long-tail): **STAB** contact — partial parry at pinned **`vo`** does not apply cut→blunt shift (**`PARRY_CUT_TO_BLUNT`** is cut-only).
static func _run_kinematic_delivery_stab_partial_parry_no_cut_to_blunt_shift(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var clean: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SPEAR", "spear_thrust"
	)
	var partial: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 0.5, 1.0, {}, "SPEAR", "spear_thrust"
	)
	_free_manager(clean["mgr"] as Node)
	_free_manager(partial["mgr"] as Node)
	if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_stab_no_shift: thrust pre_cut should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_cut"]), float(partial["pre_cut"])]
		)
	if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
		_fail(
			failures,
			"kin_stab_no_shift: thrust pre_blunt should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
		)


## Tier 5.1 (optional long-tail): partial parry + misaligned guard — oblique factor uses **parry** branch (not alignment-only branch).
static func _run_kinematic_delivery_partial_parry_misalign_oblique_parry_branch_wins(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const parry_r: float = 0.25
	const amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	var base: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var both: Dictionary = _kin_dmg_integration_sample(vo_pin, parry_r, 0.0, {})
	var align_only: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
	_free_manager(base["mgr"] as Node)
	_free_manager(both["mgr"] as Node)
	_free_manager(align_only["mgr"] as Node)
	var want_parry_branch: float = lerpf(1.0, amin, 1.0 - parry_r)
	var want_align_branch: float = lerpf(
		1.0,
		amin,
		(1.0 - 0.0) * CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	)
	var ratio_both: float = float(both["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
	var ratio_align: float = float(align_only["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
	if absf(ratio_both - want_parry_branch) > 0.03:
		_fail(
			failures,
			"kin_oblique_parry_wins: parry+align pen ratio %.4f want parry branch %.4f"
			% [ratio_both, want_parry_branch]
		)
	if absf(ratio_both - ratio_align) < 0.02:
		_fail(
			failures,
			"kin_oblique_parry_wins: parry+align should differ from align-only (both=%.4f align=%.4f)"
			% [ratio_both, ratio_align]
		)
	if want_parry_branch >= want_align_branch - 0.001:
		_fail(
			failures,
			"kin_oblique_parry_wins: fixture want parry branch > align branch (%.4f vs %.4f)"
			% [want_parry_branch, want_align_branch]
		)


## Tier 5.1 (optional long-tail): **`blunt_momentum_pa_mult`** scales **`penetration_blunt_mpa_applied`** only (not **`pre_blunt_applied`**).
static func _run_kinematic_delivery_blunt_momentum_mult_scales_pen_not_pre_armor(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.28
	var base: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {"blunt_momentum_pa_mult": mult}
	)
	_free_manager(base["mgr"] as Node)
	_free_manager(shaped["mgr"] as Node)
	if float(base["pen_blunt_mpa"]) <= 0.0:
		_fail(failures, "kin_blunt_pa_mult: baseline blunt mpa invalid %.6f" % float(base["pen_blunt_mpa"]))
	if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.03:
		_fail(
			failures,
			"kin_blunt_pa_mult: pen blunt mpa ratio %.4f want %.4f"
			% [float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
		)
	if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - 1.0) > 0.03:
		_fail(
			failures,
			"kin_blunt_pa_mult: pre_blunt should ignore blunt_momentum_pa_mult (base=%.4f shaped=%.4f)"
			% [float(base["pre_blunt"]), float(shaped["pre_blunt"])]
		)


## Tier 5.1 (optional long-tail): unknown **`attack_line`** → **`ATTACK_PATH_HIGH`** default.
static func _run_kinematic_delivery_get_attack_path_unknown_attack_line_fallback(
	failures: PackedStringArray
) -> void:
	var path: Array = CombatConstants.get_attack_path("__no_such_attack__", "low")
	if str(path) != str(CombatConstants.ATTACK_PATH_HIGH):
		_fail(
			failures,
			"kin_attack_path_atk: want ATTACK_PATH_HIGH got %s" % str(path)
		)


## Tier 5.1 (optional long-tail): **`sharp_penetration_mult`** scales **`penetration_sharp_applied`** only (not **`pre_cut_applied`**).
static func _run_kinematic_delivery_sharp_penetration_mult_scales_pen_not_pre_cut(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.33
	var base: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult}
	)
	_free_manager(base["mgr"] as Node)
	_free_manager(shaped["mgr"] as Node)
	if float(base["pen_sharp"]) <= 0.001:
		_fail(failures, "kin_sharp_pen_mult: baseline pen too small %.6f" % float(base["pen_sharp"]))
	if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - mult) > 0.03:
		_fail(
			failures,
			"kin_sharp_pen_mult: pen ratio %.4f want %.4f"
			% [float(shaped["pen_sharp"]) / float(base["pen_sharp"]), mult]
		)
	if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
		_fail(
			failures,
			"kin_sharp_pen_mult: pre_cut should ignore sharp_penetration_mult (base=%.4f shaped=%.4f)"
			% [float(base["pre_cut"]), float(shaped["pre_cut"])]
		)


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=true)`** — low **`stamina_ratio`** in **`variance_context`** widens spread vs full stamina (seeded).
static func _run_kinematic_delivery_attack_angle_deg_variance_stamina_spreads(
	failures: PackedStringArray
) -> void:
	seed(44005)
	var full_stam: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 1.0}
	)
	seed(44005)
	var low_stam: float = CombatConstants.get_attack_angle_deg(
		"high", true, {}, {"stamina_ratio": 0.05}
	)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)
	if absf(full_stam - low_stam) < 0.05:
		_fail(
			failures,
			"kin_atk_angle_var: low stamina should shift angle vs full (full=%.4f low=%.4f)"
			% [full_stam, low_stam]
		)
	if CombatConstants.angle_diff_deg(full_stam, CombatConstants.line_to_angle("high")) > 25.0:
		_fail(
			failures,
			"kin_atk_angle_var: full-stamina draw far from line high (%.4f)" % full_stam
		)


## Tier 5.1 (optional long-tail): partial parry shifts pre-armor only; misalign scales pens only; **(parry, align)** uses parry oblique branch when **`parry_r` < 1** (align does not change pen when parry branch already set).
static func _run_kinematic_delivery_partial_parry_align_compose_on_pen_not_pre_armor_mix(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const parry_r: float = 0.25
	const amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
	const ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var parry_only: Dictionary = _kin_dmg_integration_sample(vo_pin, parry_r, 1.0, {})
	var both: Dictionary = _kin_dmg_integration_sample(vo_pin, parry_r, 0.0, {})
	var align_only: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
	_free_manager(clean["mgr"] as Node)
	_free_manager(parry_only["mgr"] as Node)
	_free_manager(both["mgr"] as Node)
	_free_manager(align_only["mgr"] as Node)
	if absf(float(parry_only["pre_cut"]) - float(both["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_parry_align_mix: pre_cut parry-only vs both (%.4f vs %.4f)"
			% [float(parry_only["pre_cut"]), float(both["pre_cut"])]
		)
	if absf(float(parry_only["pre_blunt"]) - float(both["pre_blunt"])) > 0.02:
		_fail(
			failures,
			"kin_parry_align_mix: pre_blunt parry-only vs both (%.4f vs %.4f)"
			% [float(parry_only["pre_blunt"]), float(both["pre_blunt"])]
		)
	if absf(float(parry_only["pen_sharp"]) - float(both["pen_sharp"])) > 0.02:
		_fail(
			failures,
			"kin_parry_align_mix: pen parry-only vs both should match (%.4f vs %.4f)"
			% [float(parry_only["pen_sharp"]), float(both["pen_sharp"])]
		)
	if float(parry_only["pre_cut"]) >= float(clean["pre_cut"]) - 0.01:
		_fail(
			failures,
			"kin_parry_align_mix: partial parry should lower pre_cut (clean=%.4f parry=%.4f)"
			% [float(clean["pre_cut"]), float(parry_only["pre_cut"])]
		)
	if absf(float(align_only["pre_cut"]) - float(clean["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_parry_align_mix: misalign alone should not change pre_cut"
		)
	var pen_r_parry: float = float(parry_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
	var pen_r_align: float = float(align_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
	var want_parry: float = lerpf(1.0, amin, 1.0 - parry_r)
	var want_align: float = lerpf(1.0, amin, (1.0 - 0.0) * ascale)
	if absf(pen_r_parry - want_parry) > 0.03:
		_fail(
			failures,
			"kin_parry_align_mix: parry pen ratio %.4f want %.4f" % [pen_r_parry, want_parry]
		)
	if absf(pen_r_align - want_align) > 0.03:
		_fail(
			failures,
			"kin_parry_align_mix: align pen ratio %.4f want %.4f" % [pen_r_align, want_align]
		)
	if absf(pen_r_parry - pen_r_align) < 0.01:
		_fail(
			failures,
			"kin_parry_align_mix: fixture should distinguish parry %.2f vs align-only (both %.4f)"
			% [parry_r, pen_r_parry]
		)


## Tier 5.1 (optional long-tail): entity split — **`final_cut` / `final_blunt`** on **`result_dict`** from one chest hit; tissue chip > 0.
static func _run_kinematic_delivery_entity_split_final_fields_on_hit(
	failures: PackedStringArray
) -> void:
	var sample: Dictionary = _kin_dmg_integration_sample(11.0, 1.0, 1.0, {})
	_free_manager(sample["mgr"] as Node)
	var final_cut: float = float(sample["final_cut"])
	var final_blunt: float = float(sample["final_blunt"])
	if final_cut < 0.0 or final_blunt < 0.0:
		_fail(
			failures,
			"kin_entity_final: missing final_cut/final_blunt (cut=%.4f blunt=%.4f)"
			% [final_cut, final_blunt]
		)
	var tissue: float = final_cut + final_blunt
	if tissue <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
		_fail(
			failures,
			"kin_entity_final: tissue chip too small (cut=%.4f blunt=%.4f)" % [final_cut, final_blunt]
		)


## Tier 5.1 (optional long-tail): **BLUNT** contact (**MACE** **`direct_blow`**) — no cut→blunt shift on partial parry at pinned **`vo`**.
static func _run_kinematic_delivery_mace_blunt_partial_parry_no_cut_to_blunt_shift(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var clean: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "MACE", "direct_blow"
	)
	var partial: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 0.5, 1.0, {}, "MACE", "direct_blow"
	)
	_free_manager(clean["mgr"] as Node)
	_free_manager(partial["mgr"] as Node)
	if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
		_fail(
			failures,
			"kin_mace_no_shift: blunt pre_cut should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_cut"]), float(partial["pre_cut"])]
		)
	if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
		_fail(
			failures,
			"kin_mace_no_shift: blunt pre_blunt should match (clean=%.4f partial=%.4f)"
			% [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
		)


## Tier 5.1 (optional long-tail): misaligned guard scales **SHARP** and **BLUNT** **`penetration_*_applied`** equally (pinned **`vo`**, full parry).
static func _run_kinematic_delivery_misaligned_guard_scales_sharp_and_blunt_pen(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	var aligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var misaligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
	_free_manager(aligned["mgr"] as Node)
	_free_manager(misaligned["mgr"] as Node)
	var want: float = lerpf(
		1.0,
		CombatConstants.PARRY_PENETRATION_ANGLE_MIN,
		CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
	)
	var r_sharp: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
	var r_blunt: float = float(misaligned["pen_blunt_mpa"]) / maxf(float(aligned["pen_blunt_mpa"]), 0.001)
	if absf(r_sharp - want) > 0.03:
		_fail(failures, "kin_misalign_both: sharp ratio %.4f want %.4f" % [r_sharp, want])
	if absf(r_blunt - want) > 0.03:
		_fail(failures, "kin_misalign_both: blunt mpa ratio %.4f want %.4f" % [r_blunt, want])


## Tier 5.1 (optional long-tail): **`strike_mods.strike_energy_mult`** in **`compute_and_apply_damage`** — **`strike_ke_j`** ∝ mult; **`pre_cut`** ∝ **`sqrt(mult)`**; **`penetration_sharp`** ∝ **`mult^PENETRATION_EXPONENT`** (via KE).
static func _run_kinematic_delivery_strike_energy_mult_integration_pre_cut_not_pen(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const mult: float = 1.45
	var base: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
	var shaped: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {"strike_energy_mult": mult}
	)
	_free_manager(base["mgr"] as Node)
	_free_manager(shaped["mgr"] as Node)
	var ke_ratio: float = float(shaped["strike_ke_j"]) / maxf(float(base["strike_ke_j"]), 0.001)
	var cut_ratio: float = float(shaped["pre_cut"]) / maxf(float(base["pre_cut"]), 0.001)
	var pen_ratio: float = float(shaped["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
	if absf(ke_ratio - mult) > 0.03:
		_fail(
			failures,
			"kin_energy_mult_int: ke ratio %.4f want %.4f" % [ke_ratio, mult]
		)
	if absf(cut_ratio - sqrt(mult)) > 0.05:
		_fail(
			failures,
			"kin_energy_mult_int: pre_cut ratio %.4f want sqrt(mult) %.4f"
			% [cut_ratio, sqrt(mult)]
		)
	var want_pen: float = pow(mult, WeaponConstants.PENETRATION_EXPONENT)
	if absf(pen_ratio - want_pen) > 0.06:
		_fail(
			failures,
			"kin_energy_mult_int: pen ratio %.4f want mult^exp %.4f"
			% [pen_ratio, want_pen]
		)


## Tier 5.1 (optional long-tail): **`afterblow_damage_mult`** scales assembled **`v`** (sqrt) → **`strike_ke_j_applied`** (~linear in mult).
static func _run_kinematic_delivery_afterblow_mult_scales_strike_ke_via_velocity(
	failures: PackedStringArray
) -> void:
	const vo_pin: float = 11.0
	const ab_mult: float = 0.64
	var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0)
	var hindered: Dictionary = _kin_dmg_integration_sample(
		vo_pin, 1.0, 1.0, {}, "SWORD", "oberhau", ab_mult
	)
	_free_manager(clean["mgr"] as Node)
	_free_manager(hindered["mgr"] as Node)
	var ke_ratio: float = float(hindered["strike_ke_j"]) / maxf(float(clean["strike_ke_j"]), 0.001)
	var want_ke: float = ab_mult
	if absf(ke_ratio - want_ke) > 0.06:
		_fail(
			failures,
			"kin_afterblow: ke ratio %.4f want ~%.4f (clean=%.2f hindered=%.2f)"
			% [ke_ratio, want_ke, float(clean["strike_ke_j"]), float(hindered["strike_ke_j"])]
		)


## Tier 5.1 (optional long-tail): **`angle_to_nearest_line`** quadrant boundaries at **45° / 135° / 225° / 315°**.
static func _run_kinematic_delivery_angle_to_nearest_line_boundaries(
	failures: PackedStringArray
) -> void:
	if CombatConstants.angle_to_nearest_line(44.9) != "high":
		_fail(failures, "kin_line_bound: 44.9° want high")
	if CombatConstants.angle_to_nearest_line(45.0) != "right":
		_fail(failures, "kin_line_bound: 45.0° want right")
	if CombatConstants.angle_to_nearest_line(134.9) != "right":
		_fail(failures, "kin_line_bound: 134.9° want right")
	if CombatConstants.angle_to_nearest_line(135.0) != "low":
		_fail(failures, "kin_line_bound: 135.0° want low")
	if CombatConstants.angle_to_nearest_line(224.9) != "low":
		_fail(failures, "kin_line_bound: 224.9° want low")
	if CombatConstants.angle_to_nearest_line(225.0) != "left":
		_fail(failures, "kin_line_bound: 225.0° want left")
	if CombatConstants.angle_to_nearest_line(314.9) != "left":
		_fail(failures, "kin_line_bound: 314.9° want left")
	if CombatConstants.angle_to_nearest_line(315.0) != "high":
		_fail(failures, "kin_line_bound: 315.0° want high")


static func _harness_destroy_limb(entity: CoreEntity, part: String) -> void:
	entity.body_cutting[part] = 0.0
	entity.body_blunt[part] = 0.0
	if entity.bone_health.has(part):
		entity.bone_health[part] = 0.0


static func _harness_restore_limb(entity: CoreEntity, part: String) -> void:
	if not entity.body_max.has(part):
		return
	var mx: float = float(entity.body_max[part])
	entity.body_cutting[part] = mx
	entity.body_blunt[part] = mx
	if entity.bone_health.has(part) and entity.bone_max.has(part):
		entity.bone_health[part] = float(entity.bone_max[part])


## Tier 6.1: **`can_flee_or_fall_back`** — leg **`MOBILITY_FLEE_THRESHOLD`** and unconscious gate.
static func _run_medical_mobility_can_flee_leg_and_consciousness(failures: PackedStringArray) -> void:
	var mobile: CoreEntity = _new_entity("SWORD")
	if not mobile.can_flee_or_fall_back():
		_fail(failures, "med_mobility: healthy entity should flee")
	mobile.consciousness = 5.0
	mobile._consciousness_dirty = false
	if mobile.can_flee_or_fall_back():
		_fail(failures, "med_mobility: unconscious should not flee")
	var immobile: CoreEntity = _new_entity("SWORD")
	_harness_destroy_limb(immobile, "left_leg")
	_harness_destroy_limb(immobile, "right_leg")
	if immobile.get_leg_functionality() >= PainConsciousnessConstants.MOBILITY_FLEE_THRESHOLD:
		_fail(
			failures,
			"med_mobility: destroyed legs want leg < %.2f got %.3f"
			% [PainConsciousnessConstants.MOBILITY_FLEE_THRESHOLD, immobile.get_leg_functionality()]
		)
	if immobile.can_flee_or_fall_back():
		_fail(failures, "med_mobility: leg-destroyed should not flee")


## Tier 6.1: mobile cowering (no arms, legs ok) is not skipped by **`process_incapacitation`**.
static func _run_medical_mobility_cowering_mobile_not_skipped_in_process_incap(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	if _StateHandlers.process_incapacitation(mgr, c):
		_fail(failures, "med_mobility: mobile cowering should not skip tick")
	_harness_destroy_limb(ent, "left_leg")
	_harness_destroy_limb(ent, "right_leg")
	if not _StateHandlers.process_incapacitation(mgr, c):
		_fail(failures, "med_mobility: immobile cowering should skip tick")
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: mobile cowering receives gauge on **`EVENT_ACTION_READY`** (formation retreat listing).
static func _run_medical_mobility_cowering_action_ready_fills_gauge_for_mobile(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 0.0
	if not ent.is_cowering():
		_fail(failures, "med_mobility_ready: expected cowering after arm loss")
		return
	_EventDispatch.handle_action_ready(mgr, c)
	if _EntityAccess.gauge_float(c) < 100.0:
		_fail(failures, "med_mobility_ready: mobile cowering should reach gauge 100 on ACTION_READY")
	_harness_destroy_limb(ent, "left_leg")
	_harness_destroy_limb(ent, "right_leg")
	c.gauge = 0.0
	_EventDispatch.handle_action_ready(mgr, c)
	if _EntityAccess.gauge_float(c) >= 100.0:
		_fail(failures, "med_mobility_ready: immobile cowering must not get ACTION_READY gauge")
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering rank-0 with legs may list solo **`fall_back`** when line discipline is loose.
static func _run_medical_mobility_cowering_mobile_solo_fall_back_legal(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not ent.is_cowering():
		_fail(failures, "med_mobility_fb: expected cowering after arm loss")
	if not _ActionsBuilder.solo_fall_back_action_legal(mgr, c):
		_fail(failures, "med_mobility_fb: solo fall_back should be legal for mobile cowering")
	_harness_destroy_limb(ent, "left_leg")
	_harness_destroy_limb(ent, "right_leg")
	if _ActionsBuilder.solo_fall_back_action_legal(mgr, c):
		_fail(failures, "med_mobility_fb: immobile cowering must not allow solo fall_back")
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: formation engagement — mobile cowering rank-0 lists **`fall_back`** in **`AvailableActionsBuilder.build`**.
static func _run_medical_mobility_cowering_lists_fall_back_in_formation_mode(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 5:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	# Five players on 2×3 — kill rank-2 file-0 before rank-1 file-0 so vacancy plug does not refill solo fall_back slot.
	mgr.start(
		{
			"files": 2,
			"ranks": 3,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 2, "ranks": 2, "density": "normal"}
	)
	var fid: String = "player"
	var _med_list_id_at := func(rank: int, file: int) -> int:
		for c in mgr.combatants:
			if (
				_EntityAccess.side_str(c) == "player"
				and _EntityAccess.rank_int(c) == rank
				and _EntityAccess.file_int(c) == file
			):
				return _EntityAccess.id_int(c)
		return -1
	var deep_id: int = _med_list_id_at.call(2, 0)
	if deep_id >= 0:
		_soak_kill_combatant(mgr, deep_id)
	var rear_victim_id: int = _med_list_id_at.call(1, 0)
	if rear_victim_id < 0:
		_fail(failures, "med_mobility_list: setup missing rank-1 file-0 player")
		return
	_soak_kill_combatant(mgr, rear_victim_id)
	var slots: Dictionary = _FormationSlots.formation_slots_dict(
		_FormationSlots.formation_record_read(mgr.formations, fid)
	)
	if _FormationSlots.slot_has_any_living_occupant(mgr, slots, Vector2i(1, 0)):
		_fail(failures, "med_mobility_list: rank-1 file-0 must be vacant for solo fall_back")
		return
	if mgr.has_method("notify_formation_changed"):
		mgr.notify_formation_changed("player")
	if _EngagementMode.engagement_mode(mgr) != CombatConstants.ENGAGEMENT_MODE_FORMATION:
		_fail(
			failures,
			"med_mobility_list: want formation mode after casualty got %s"
			% _EngagementMode.engagement_mode(mgr)
		)
	var front_c: Dictionary = {}
	for c in mgr.combatants:
		if (
			_EntityAccess.side_str(c) == "player"
			and _EntityAccess.rank_int(c) == 0
			and _EntityAccess.file_int(c) == 0
		):
			front_c = c
			break
	if front_c.is_empty():
		_fail(failures, "med_mobility_list: missing living player rank-0 file-0")
		return
	var policy: Dictionary = _EngagementMode.movement_policy(mgr)
	if not bool(policy.get("allow_fall_back", false)):
		_fail(failures, "med_mobility_list: formation policy must allow fall_back")
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX - 5.0
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	front_c.state = CombatConstants.STATE_COWERING
	front_c.gauge = 100.0
	if not ent.is_cowering():
		_fail(failures, "med_mobility_list: expected cowering on rank-0")
	var form: Dictionary = _FormationSlots.formation_record_read(mgr.formations, fid)
	var our_file: int = _EntityAccess.file_int(front_c)
	if _FormationFlow.formation_has_frontline_fill_opportunity_at_file(mgr, fid, our_file):
		_fail(
			failures,
			"med_mobility_list: unexpected rank-0 plug at file %d blocks solo fall_back"
			% our_file
		)
	if not _ActionsBuilder.solo_fall_back_action_legal(mgr, front_c):
		_fail(
			failures,
			"med_mobility_list: solo fall_back illegal (rank=%d file=%d disc=%s)"
			% [
				_EntityAccess.rank_int(front_c),
				_EntityAccess.file_int(front_c),
				CombatFormationEngagement.effective_line_discipline(mgr, form),
			]
		)
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(front_c))
	var has_fb: bool = false
	for a in acts:
		if a.get("move_id", "") == CombatConstants.MOVE_ID_FALL_BACK:
			has_fb = true
			break
	if not has_fb:
		var c_b: Dictionary = mgr._get_by_id(_EntityAccess.id_int(front_c))
		var zf: Dictionary = _ZoneOfControl.formation_dict_for_zone_geometry(mgr, c_b)
		var mp: Dictionary = _EngagementMode.movement_policy(mgr)
		_fail(
			failures,
			(
				"med_mobility_list: expected fall_back in build (acts=%s legal=%s g=%.0f"
				+ " zf_empty=%s ranks=%d allow_fb=%s mode=%s)"
			)
			% [
				str(acts),
				_ActionsBuilder.solo_fall_back_action_legal(mgr, front_c),
				_EntityAccess.gauge_float(c_b),
				zf.is_empty(),
				int(zf.get("ranks", 1)),
				bool(mp.get("allow_fall_back", false)),
				str(mp.get("mode", "")),
			]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering solo **`fall_back`** resolves when movement policy blocks routine line retreat.
static func _run_medical_mobility_cowering_resolve_solo_fall_back_without_movement_policy(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_SKIRMISH)
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	ent.blood_volume = CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX - 5.0
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not _ActionsBuilder.solo_fall_back_action_legal(mgr, c):
		_fail(failures, "med_resolve_fb: setup solo fall_back should be legal")
		return
	if bool(_EngagementMode.movement_policy(mgr).get("allow_fall_back", false)):
		_fail(failures, "med_resolve_fb: want skirmish policy to block routine fall_back")
		return
	var cid: int = _EntityAccess.id_int(c)
	mgr.resolve_action(cid, cid, CombatConstants.MOVE_ID_FALL_BACK, {})
	if _EntityAccess.state_str(c) != CombatConstants.STATE_FALLING_BACK:
		_fail(
			failures,
			"med_resolve_fb: cowering solo fall_back should start (state=%s)"
			% _EntityAccess.state_str(c)
		)
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: rank-1 mobile cowering lists **wait** only (no solo **fall_back**); avoids empty action soft-lock.
static func _run_medical_mobility_cowering_depth_lists_wait_not_fall_back(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	var players: Array = []
	for row in mgr.combatants:
		if _EntityAccess.side_str(row) == "player":
			players.append(row)
	if players.size() < 2:
		_fail(failures, "med_mobility_depth: need 2 players got %d" % players.size())
		return
	var c: Dictionary = players[1]
	if _EntityAccess.rank_int(c) != 1:
		_fail(
			failures,
			"med_mobility_depth: second player want rank 1 got rank=%d"
			% _EntityAccess.rank_int(c)
		)
		return
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	if not ent.can_flee_or_fall_back():
		_fail(failures, "med_mobility_depth: want mobile cowering legs ok")
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	var has_wait: bool = false
	var has_fb: bool = false
	for a in acts:
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_WAIT:
			has_wait = true
		if mid == CombatConstants.MOVE_ID_FALL_BACK:
			has_fb = true
	if not has_wait:
		_fail(failures, "med_mobility_depth: rank-1 cowering want wait in build (acts=%s)" % str(acts))
	if has_fb:
		_fail(failures, "med_mobility_depth: rank-1 cowering must not solo fall_back")
	var depth_hint: String = _ActionsBuilder.player_cowering_retreat_hint_if_applicable(mgr, c, acts)
	if depth_hint.is_empty() or not depth_hint.contains("holding position"):
		_fail(
			failures,
			"med_mobility_depth: wait-only cowering want holding-position hint got '%s'"
			% depth_hint
		)
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: player UI hint when cowering with mobile legs (mirrors crash-absence hint path).
static func _run_medical_mobility_cowering_player_retreat_ui_hint(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	for _i in 5:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{
			"files": 2,
			"ranks": 3,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": "normal",
		},
		{"files": 2, "ranks": 2, "density": "normal"}
	)
	var _hint_id_at := func(rank: int, file: int) -> int:
		for row in mgr.combatants:
			if (
				_EntityAccess.side_str(row) == "player"
				and _EntityAccess.rank_int(row) == rank
				and _EntityAccess.file_int(row) == file
			):
				return _EntityAccess.id_int(row)
		return -1
	var deep_id: int = _hint_id_at.call(2, 0)
	if deep_id >= 0:
		_soak_kill_combatant(mgr, deep_id)
	var rear_id: int = _hint_id_at.call(1, 0)
	if rear_id < 0:
		_fail(failures, "med_mobility_hint: setup missing rank-1 file-0")
		return
	_soak_kill_combatant(mgr, rear_id)
	if mgr.has_method("notify_formation_changed"):
		mgr.notify_formation_changed("player")
	var front_c: Dictionary = {}
	for row in mgr.combatants:
		if (
			_EntityAccess.side_str(row) == "player"
			and _EntityAccess.rank_int(row) == 0
			and _EntityAccess.file_int(row) == 0
		):
			front_c = row
			break
	if front_c.is_empty():
		_fail(failures, "med_mobility_hint: missing rank-0 file-0")
		return
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	front_c.state = CombatConstants.STATE_COWERING
	front_c.gauge = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(front_c))
	var fb_hint: String = _ActionsBuilder.player_cowering_retreat_hint_if_applicable(mgr, front_c, acts)
	if fb_hint.is_empty() or not fb_hint.contains("fall back"):
		_fail(failures, "med_mobility_hint: fall_back listed want retreat hint got '%s'" % fb_hint)
	var enemy_c: Dictionary = {}
	for row in mgr.combatants:
		if _EntityAccess.side_str(row) == "enemy":
			enemy_c = row
			break
	var enemy_hint: String = _ActionsBuilder.player_cowering_retreat_hint_if_applicable(
		mgr, enemy_c, acts
	)
	if not enemy_hint.is_empty():
		_fail(failures, "med_mobility_hint: enemy must not get player retreat hint")
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: cowering solo **fall_back** AI weight exceeds **wait** so mobile no-arms units retreat when legal.
static func _run_medical_mobility_cowering_ai_fall_back_weight_beats_wait(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var cid: int = _EntityAccess.id_int(c)
	var acts: Array = _ActionsBuilder.build(mgr, cid)
	var fb_act: Dictionary = {}
	var wait_act: Dictionary = {}
	for a in acts:
		var mid: String = str(a.get("move_id", ""))
		if mid == CombatConstants.MOVE_ID_FALL_BACK:
			fb_act = a
		elif mid == CombatConstants.MOVE_ID_WAIT:
			wait_act = a
	if fb_act.is_empty() or wait_act.is_empty():
		_fail(
			failures,
			"med_mobility_ai_w: want fall_back+wait in build got %s" % str(acts)
		)
		return
	var w_fb: float = _AIPicker._get_action_weight(fb_act, cid, mgr, true)
	var w_wait: float = _AIPicker._get_action_weight(wait_act, cid, mgr, true)
	if w_fb <= w_wait:
		_fail(
			failures,
			"med_mobility_ai_w: cowering fall_back want > wait got fb=%.3f wait=%.3f"
			% [w_fb, w_wait]
		)
	if absf(w_fb - CombatConstants.COWERING_SOLO_FALL_BACK_AI_WEIGHT) > 0.001:
		_fail(
			failures,
			"med_mobility_ai_w: want COWERING_SOLO_FALL_BACK_AI_WEIGHT got %.3f"
			% w_fb
		)
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: weighted **`pick_weighted`** favors solo **fall_back** over **wait** for mobile cowering.
static func _run_medical_mobility_cowering_ai_pick_favors_fall_back(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var cid: int = _EntityAccess.id_int(c)
	var acts: Array = _ActionsBuilder.build(mgr, cid)
	seed(90211)
	var fall_back_picks: int = 0
	const TRIALS: int = 200
	for _t in TRIALS:
		var choice: Dictionary = _AIPicker.pick_weighted(acts, cid, mgr)
		if str(choice.get("move_id", "")) == CombatConstants.MOVE_ID_FALL_BACK:
			fall_back_picks += 1
	# P(fb) = 1.5 / 2.5 = 0.6 — allow slack for RNG.
	if fall_back_picks < 90:
		_fail(
			failures,
			"med_mobility_ai_pick: want fall_back majority got %d/%d"
			% [fall_back_picks, TRIALS]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: arm functionality return clears **STATE_COWERING** via **`process_incapacitation`**.
static func _run_medical_mobility_cowering_arm_recovery_clears_state(
	failures: PackedStringArray
) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	_harness_destroy_limb(ent, "right_arm")
	_harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 50.0
	if not ent.is_cowering():
		_fail(failures, "med_mobility_recover: setup want cowering")
		return
	_harness_restore_limb(ent, "right_arm")
	if ent.is_cowering():
		_fail(failures, "med_mobility_recover: one arm restored should end cowering")
		return
	if _StateHandlers.process_incapacitation(mgr, c):
		_fail(failures, "med_mobility_recover: recovered arms should not skip tick")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		_fail(
			failures,
			"med_mobility_recover: want STATE_WAITING got %s"
			% _EntityAccess.state_str(c)
		)
	if _EntityAccess.gauge_float(c) != 0.0:
		_fail(failures, "med_mobility_recover: gauge should reset on arm recovery")
	_free_manager_restore_global_rng(mgr)


## Tier 6.1: cumulative effective pain scales pain-shock **chance** (0.8×–1.2×); hit pain remains primary.
static func _run_medical_pain_shock_susceptibility_mult_from_effective_pain(
	failures: PackedStringArray
) -> void:
	var low: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(3.0)
	var at_first: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(
		PainConsciousnessConstants.NRS_FIRST_EFFECT
	)
	var mid: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(6.0)
	var high: float = PainConsciousnessConstants.get_pain_shock_susceptibility_mult(9.0)
	if absf(low - 0.8) > 0.0001 or absf(at_first - 0.8) > 0.0001:
		_fail(failures, "med_shock_sus: low pain want 0.8 got low=%.3f first=%.3f" % [low, at_first])
	if absf(high - 1.2) > 0.0001:
		_fail(failures, "med_shock_sus: high pain want 1.2 got %.3f" % high)
	if mid <= 0.8 or mid >= 1.2:
		_fail(failures, "med_shock_sus: mid pain want between 0.8 and 1.2 got %.3f" % mid)


static func _run_weapon_blade_strong_fraction(failures: PackedStringArray) -> void:
	var sword: Weapon = _Weapon.create_from_definition("SWORD")
	var dagger: Weapon = _Weapon.create_from_definition("DAGGER")
	var spear: Weapon = _Weapon.create_from_definition("SPEAR")
	if sword == null or dagger == null or spear == null:
		_fail(failures, "weapon_strong_fraction: missing sword/dagger/spear")
		return
	var sword_want: float = 30.0 / 120.0
	var dagger_want: float = 12.0 / 32.0
	if absf(sword.get_parry_strong_fraction() - sword_want) > 0.001:
		_fail(
			failures,
			"weapon_strong_fraction: sword %.3f want %.3f"
			% [sword.get_parry_strong_fraction(), sword_want]
		)
	if absf(dagger.get_parry_strong_fraction() - dagger_want) > 0.001:
		_fail(
			failures,
			"weapon_strong_fraction: dagger %.3f want %.3f"
			% [dagger.get_parry_strong_fraction(), dagger_want]
		)
	if absf(spear.get_parry_strong_fraction() - 0.25) > 0.001:
		_fail(failures, "weapon_strong_fraction: non-blade spear should use neutral 0.25")


## Tier 3.2: bind-riposte contact sets are normalized, deduped, and data-driven per weapon.
static func _run_bind_riposte_contact_types_normalized(failures: PackedStringArray) -> void:
	var valid: Dictionary = {
		WeaponConstants.ATTACK_TYPE_STAB: true,
		WeaponConstants.ATTACK_TYPE_CUT: true,
		WeaponConstants.ATTACK_TYPE_BLUNT: true
	}
	var expected: Dictionary = {
		"SWORD": [WeaponConstants.ATTACK_TYPE_STAB, WeaponConstants.ATTACK_TYPE_CUT],
		"AXE": [WeaponConstants.ATTACK_TYPE_CUT, WeaponConstants.ATTACK_TYPE_STAB],
		"MACE": [WeaponConstants.ATTACK_TYPE_BLUNT],
		"DAGGER": [WeaponConstants.ATTACK_TYPE_STAB],
		"SPEAR": [WeaponConstants.ATTACK_TYPE_STAB]
	}
	for wid in expected.keys():
		var weapon: Weapon = _Weapon.create_from_definition(str(wid))
		if weapon == null:
			_fail(failures, "bind_contacts: missing weapon %s" % str(wid))
			continue
		var seen: Dictionary = {}
		for raw_ct in weapon.bind_riposte_contact_types:
			var ct: String = str(raw_ct)
			if not valid.get(ct, false):
				_fail(failures, "bind_contacts: %s invalid contact %s" % [str(wid), ct])
			if seen.get(ct, false):
				_fail(failures, "bind_contacts: %s duplicate contact %s" % [str(wid), ct])
			seen[ct] = true
		if weapon.bind_riposte_contact_types != expected[wid]:
			_fail(
				failures,
				"bind_contacts: %s got %s want %s"
				% [str(wid), str(weapon.bind_riposte_contact_types), str(expected[wid])]
			)


## Tier 3.2: bind riposte speed depends on parry contact part plus the riposte contact type.
static func _run_bind_riposte_contact_multipliers(failures: PackedStringArray) -> void:
	var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
	var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
	var spear_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["stab"])
	if spear_normal <= 0.0 or absf((spear_bind / spear_normal) - spear_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: spear stab ratio %.3f want %.3f"
			% [(spear_bind / spear_normal) if spear_normal > 0.0 else -1.0, spear_want]
		)
	var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
	var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
	var mace_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["blunt"])
	if mace_normal <= 0.0 or absf((mace_bind / mace_normal) - mace_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: mace blunt ratio %.3f want %.3f"
			% [(mace_bind / mace_normal) if mace_normal > 0.0 else -1.0, mace_want]
		)
	var axe_normal: float = _windup_duration_for_bind_test("AXE", "spike_thrust", false)
	var axe_bind: float = _windup_duration_for_bind_test("AXE", "spike_thrust", true)
	var axe_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["haft"] as Dictionary)["stab"])
	if axe_normal <= 0.0 or absf((axe_bind / axe_normal) - axe_want) > 0.001:
		_fail(
			failures,
			"bind_riposte: axe spike ratio %.3f want %.3f"
			% [(axe_bind / axe_normal) if axe_normal > 0.0 else -1.0, axe_want]
		)
	var spear_slash_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", false)
	var spear_slash_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", true)
	if spear_slash_normal <= 0.0 or absf((spear_slash_bind / spear_slash_normal) - 1.0) > 0.001:
		_fail(
			failures,
			"bind_riposte: spear slash should not be eligible by default ratio %.3f"
			% [(spear_slash_bind / spear_slash_normal) if spear_slash_normal > 0.0 else -1.0]
		)


## Tier 3.2: opposite-line parry magnitude uses contact-type severity thresholds.
static func _run_parry_opposite_deflect_thresholds(failures: PackedStringArray) -> void:
	var align: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
	var cut_low: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.01,
		WeaponConstants.ATTACK_TYPE_CUT,
		align
	)
	if cut_low not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: weak cut should partial-deflect high to adjacent, got %s" % cut_low)
	var cut_full: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT + 0.01,
		WeaponConstants.ATTACK_TYPE_CUT,
		align
	)
	if cut_full != "low":
		_fail(failures, "parry_deflect_threshold: strong cut should deflect high to low, got %s" % cut_full)
	var stab_mid: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		0.55,
		WeaponConstants.ATTACK_TYPE_STAB,
		align
	)
	if stab_mid != "low":
		_fail(failures, "parry_deflect_threshold: thrust should reach full opposite at 0.55, got %s" % stab_mid)
	var blunt_mid: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		180.0,
		0.55,
		WeaponConstants.ATTACK_TYPE_BLUNT,
		align
	)
	if blunt_mid not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: blunt at 0.55 should partial-deflect to adjacent, got %s" % blunt_mid)
	seed(1205)
	var adj_align: float = CombatConstants.get_alignment_from_angles(0.0, 90.0)
	var adjacent_guard: String = CombatConstants.get_deflected_line_from_angles(
		0.0,
		90.0,
		1.0,
		WeaponConstants.ATTACK_TYPE_CUT,
		adj_align
	)
	if adjacent_guard not in CombatConstants.LINE_ADJACENTS["high"]:
		_fail(failures, "parry_deflect_threshold: adjacent guard should stay adjacent, got %s" % adjacent_guard)
	seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 3.2: defender weapon type × attack contact modifiers apply through Weapon object fields.
static func _run_parry_defender_vs_attack_modifiers(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("DAGGER"), "player")
	mgr.register(_new_entity("MACE"), "player")
	mgr.register(_new_entity("SPEAR"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
	var dagger_defender: Dictionary = mgr.combatants[0]
	var mace_defender: Dictionary = mgr.combatants[1]
	var spear_defender: Dictionary = mgr.combatants[2]
	var dagger: Weapon = _EntityAccess.get_weapon(dagger_defender)
	var mace: Weapon = _EntityAccess.get_weapon(mace_defender)
	var spear: Weapon = _EntityAccess.get_weapon(spear_defender)
	if dagger == null:
		_fail(failures, "parry_def_vs_atk: missing dagger weapon")
		_free_manager(mgr)
		return
	if mace == null:
		_fail(failures, "parry_def_vs_atk: missing mace weapon")
		_free_manager(mgr)
		return
	if spear == null:
		_fail(failures, "parry_def_vs_atk: missing spear weapon")
		_free_manager(mgr)
		return
	var dagger_stab_cd: float = _DefenseChoice._compute_parry_c_d(dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_STAB.to_upper())
	var dagger_cut_cd: float = _DefenseChoice._compute_parry_c_d(dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var dagger_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["DAGGER"] as Dictionary)["stab"])
	var dagger_ratio: float = dagger_stab_cd / dagger_cut_cd if dagger_cut_cd > 0.0 else -1.0
	if dagger_cut_cd <= 0.0 or absf(dagger_ratio - dagger_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: dagger stab/cut ratio %.3f want %.3f"
			% [dagger_ratio, dagger_expected]
		)
	var mace_blunt_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_BLUNT)
	var mace_cut_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var mace_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["MACE"] as Dictionary)["blunt"])
	var mace_ratio: float = mace_blunt_cd / mace_cut_cd if mace_cut_cd > 0.0 else -1.0
	if mace_cut_cd <= 0.0 or absf(mace_ratio - mace_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: mace blunt/cut ratio %.3f want %.3f"
			% [mace_ratio, mace_expected]
		)
	var spear_cut_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_CUT)
	var spear_stab_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_STAB)
	var spear_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["SPEAR"] as Dictionary)["cut"])
	var spear_ratio: float = spear_cut_cd / spear_stab_cd if spear_stab_cd > 0.0 else -1.0
	if spear_stab_cd <= 0.0 or absf(spear_ratio - spear_expected) > 0.001:
		_fail(
			failures,
			"parry_def_vs_atk: spear cut/stab ratio %.3f want %.3f"
			% [spear_ratio, spear_expected]
		)
	_free_manager(mgr)


## Tier 3.2 + 3.0: parry clash context preserves bind/deflect calibration + strike kinematics; asserts geometry + move ids vs **`DefenseResolutionHandler._resolve_parry`** and **`WeaponDamageHelper`** / **`StrikeRealismProfile`**; Tier **3.1** **`strike_measure_ratio`** vs **`pa`** after **`stamp_attack_pair_geometry_on_dict`** + **`strike_measure_ratio_for_attack_pair`** (full-stop key set **`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP`**); stamped path sets **`impact_blade_station`** before **`resolve`** so post-resolve kinematics recompute matches **`velocity_intent_mult_from_pa`** (no extra **`randf()`** vs resolver); unstamped **`pa`** → clash **`strike_measure_ratio`** **-1**, then **`seed(3312)`** before stamped path for stable RNG.
static func _parry_clash_context_expected_strike_kinematics(
	pa: Dictionary,
	attacker: Dictionary,
	atk_move: String,
	intensity_val: float,
	archetype_passed: Dictionary
) -> Dictionary:
	var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
	var ai := AttackInstance.new(atk_move, intensity_val)
	ai.archetype = archetype_passed
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_sv: float = -1.0
	var want_ke: float = 0.0
	if atk_w != null:
		want_sv = WeaponDamageHelper.get_effective_velocity_m_s(atk_w, ai)
		want_sv *= StrikeRealismProfile.velocity_intent_mult_from_pa(
			pa, atk_w, atk_move, float(pa.get("intensity", intensity_val)), archetype_passed
		)
		ai.velocity_m_s = want_sv
		want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
	return {
		"kinematic_delivery": want_kdel,
		"strike_velocity_m_s": want_sv,
		"strike_kinetic_energy_j": want_ke,
	}


## Tier 3.0: partial-parry follow-through — clash **`strike_velocity_m_s`** / **`strike_kinetic_energy_j`** use **`pa["velocity_m_s"]`** after **`DefenseResolutionHandler`** reduction (not pre-parry intent speed).
static func _parry_clash_expected_partial_strike_kinematics(
	pa: Dictionary,
	attacker: Dictionary,
	atk_move: String,
	intensity_val: float,
	archetype_passed: Dictionary
) -> Dictionary:
	var want_kdel: String = WeaponDamageHelper.kinematic_delivery(archetype_passed, atk_move)
	var ai := AttackInstance.new(atk_move, intensity_val)
	ai.archetype = archetype_passed
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_sv: float = float(pa.get("velocity_m_s", -1.0))
	ai.velocity_m_s = want_sv
	var want_ke: float = 0.0
	if atk_w != null:
		want_ke = WeaponDamageHelper.compute_kinetic_energy_j(atk_w, ai)
	return {
		"kinematic_delivery": want_kdel,
		"strike_velocity_m_s": want_sv,
		"strike_kinetic_energy_j": want_ke,
	}


static func _run_parry_clash_context_calibration_fields(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SPEAR"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	defender["guard_line"] = "low"
	var pa_template: Dictionary = {
		"attack_type": "spear_thrust",
		"effective_attack_line": "high",
		"intensity": 0.5,
		"wind_up_duration": 1.0,
		"arc_start_deg": 0.0,
		"arc_end_deg": 180.0,
		"attack_angle_deg": 180.0
	}
	var parry_p_a: float = 5.0
	var parry_c_d: float = 100.0
	var m_a_parry: float = 1.25
	var m_d_parry: float = 2.5
	var m_a_velocity: float = 0.45
	var dc: Dictionary = {
		"defense": "parry",
		"can_parry_in_time": true,
		"parry_p_a": parry_p_a,
		"parry_c_d": parry_c_d,
		"parry_time_to_react": 0.1,
		"parry_readiness": 1.0,
		"is_block_parry": true,
		"m_a_parry": m_a_parry,
		"m_d_parry": m_d_parry,
		"m_a_velocity": m_a_velocity,
		"dodge_chance": 0.0,
		"dodge_eval_part": "",
		"effective_redirect": 1.0,
		"late_parry": false,
		"parry_off_balance": false
	}
	# Tier 3.1 sentinel: no **`strike_measure_ratio`** on **`pa`** → clash carries **-1** (same RNG as main branch after re-seed).
	seed(3312)
	var pa_unstamped: Dictionary = pa_template.duplicate(true)
	var res_unstamped: Variant = _DefenseResolution.resolve(
		pa_unstamped,
		attacker,
		defender,
		dc,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (res_unstamped is Dictionary) or res_unstamped.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context unstamped: expected parry_deflect result")
		_free_manager_restore_global_rng(mgr)
		return
	var clash_un: Dictionary = res_unstamped.get("parry_clash_context", {})
	if not clash_un.has("strike_measure_ratio") or absf(float(clash_un.get("strike_measure_ratio", 0.0)) - (-1.0)) > 0.001:
		_fail(
			failures,
			"parry_clash_context unstamped: strike_measure_ratio want -1 got %s"
			% str(clash_un.get("strike_measure_ratio", "missing"))
		)
		_free_manager_restore_global_rng(mgr)
		return
	for _sk_un: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash_un.has(_sk_un):
			_fail(failures, "parry_clash_context unstamped: missing key %s" % _sk_un)
			_free_manager_restore_global_rng(mgr)
			return
	seed(3312)
	var pa1: Dictionary = pa_template.duplicate(true)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa1)
	var atk_w_for_meas: RefCounted = _EntityAccess.get_weapon(attacker)
	if atk_w_for_meas != null:
		pa1["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr, attacker, defender, atk_w_for_meas, float(pa1.get("effective_pair_eff_dist", -1.0))
		)
		# Match wind-up: fixed blade station so **`velocity_intent_mult_from_pa`** does not draw a second RNG stream vs post-resolve recompute.
		pa1["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa1, atk_w_for_meas, "spear_thrust", 0.5
		)
	var result = _DefenseResolution.resolve(
		pa1,
		attacker,
		defender,
		dc,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (result is Dictionary) or result.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context: expected parry_deflect result")
		_free_manager_restore_global_rng(mgr)
		return
	var clash: Dictionary = result.get("parry_clash_context", {})
	if clash.is_empty():
		_fail(failures, "parry_clash_context: missing context")
		_free_manager_restore_global_rng(mgr)
		return
	for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash.has(_sk):
			_fail(failures, "parry_clash_context: missing key %s" % _sk)
			_free_manager_restore_global_rng(mgr)
			return
	var expected: Dictionary = {
		"parry_p_a": parry_p_a,
		"parry_c_d": parry_c_d,
		"m_a_parry": m_a_parry,
		"m_d_parry": m_d_parry,
		"m_a_velocity": m_a_velocity,
		"parry_time_to_react": float(dc.get("parry_time_to_react", -1.0)),
		"parry_readiness": float(dc.get("parry_readiness", -1.0))
	}
	for key in expected.keys():
		if absf(float(clash.get(key, -999.0)) - float(expected[key])) > 0.001:
			_fail(
				failures,
				"parry_clash_context: %s %.3f want %.3f"
				% [str(key), float(clash.get(key, -999.0)), float(expected[key])]
			)
	if bool(clash.get("late_parry", false)) != bool(dc.get("late_parry", false)):
		_fail(failures, "parry_clash_context: late_parry should match defense choice")
	if bool(clash.get("parry_off_balance", false)) != bool(dc.get("parry_off_balance", false)):
		_fail(failures, "parry_clash_context: parry_off_balance should match defense choice")
	if bool(clash.get("is_block_parry", false)) != bool(dc.get("is_block_parry", false)):
		_fail(failures, "parry_clash_context: is_block_parry should match defense choice")
	var atk_move: String = "spear_thrust"
	if str(clash.get("attack_type", "")) != atk_move:
		_fail(
			failures,
			"parry_clash_context: attack_type want %s got %s" % [atk_move, str(clash.get("attack_type", ""))]
		)
	var want_ct: String = str(WeaponConstants.contact_type_for_move_id(atk_move)).to_lower().strip_edges()
	if str(clash.get("contact_type", "")).to_lower().strip_edges() != want_ct:
		_fail(
			failures,
			"parry_clash_context: contact_type want %s got %s" % [want_ct, str(clash.get("contact_type", ""))]
		)
	var arc_s: float = float(pa_template.get("arc_start_deg", 0.0))
	var arc_e: float = CombatConstants.arc_end_deg_for_contact_geometry(pa_template)
	var atk_line_for_align: String = str(pa_template.get("effective_attack_line", "high"))
	var def_w0 = _EntityAccess.get_weapon(defender)
	var def_mass: float = (
		float(def_w0.mass)
		if def_w0 != null and (def_w0.get("mass") is float or def_w0.get("mass") is int)
		else WeaponConstants.BASELINE_MASS_KG
	)
	if str(clash.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
		_fail(
			failures,
			"parry_clash_context: effective_attack_line want %s got %s"
			% [str(pa_template.get("effective_attack_line", "")), str(clash.get("effective_attack_line", ""))]
		)
	if str(clash.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
		_fail(
			failures,
			"parry_clash_context: defender_guard_line want %s got %s"
			% [str(defender.get("guard_line", "")), str(clash.get("defender_guard_line", ""))]
		)
	var atk_w = _EntityAccess.get_weapon(attacker)
	var want_arch: String = (
		atk_w.get_archetype_id(atk_move) if atk_w != null and atk_w.has_method("get_archetype_id") else ""
	)
	if str(clash.get("archetype_id", "")) != want_arch:
		_fail(
			failures,
			"parry_clash_context: archetype_id want %s got %s" % [want_arch, str(clash.get("archetype_id", ""))]
		)
	var eff_wind: float = float(pa_template.get("wind_up_duration", 0.5)) * (
		1.0 - CombatConstants.commitment_fraction_for_pending_attack(pa_template)
	)
	var parry_prog: float = 1.0
	if not bool(dc.get("late_parry", false)):
		parry_prog = 1.0 - clampf(float(dc.get("parry_time_to_react", 0.0)) / maxf(0.001, eff_wind), 0.0, 1.0)
	var want_atk_deg: float = (
		CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, parry_prog)
		if arc_e >= -900.0
		else CombatConstants.line_to_angle(str(pa_template.get("effective_attack_line", "high")))
	)
	if absf(float(clash.get("attack_angle_deg", -9999.0)) - want_atk_deg) > 0.05:
		_fail(
			failures,
			"parry_clash_context: attack_angle_deg want %.4f got %.4f" % [want_atk_deg, float(clash.get("attack_angle_deg", -9999.0))]
		)
	var wobble: Dictionary = {
		"parry_readiness": float(dc.get("parry_readiness", 1.0)),
		"defender_mass_kg": def_mass,
	}
	var want_guard_deg: float = CombatConstants.get_guard_angle_deg(defender, wobble)
	if absf(float(clash.get("guard_angle_deg", -9999.0)) - want_guard_deg) > 0.25:
		_fail(
			failures,
			"parry_clash_context: guard_angle_deg want %.4f got %.4f"
			% [want_guard_deg, float(clash.get("guard_angle_deg", -9999.0))]
		)
	var align_ctx1: Dictionary = {"attack_angle_deg": want_atk_deg, "guard_angle_deg": want_guard_deg}
	var want_align: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx1)
	if absf(float(clash.get("alignment", -999.0)) - want_align) > 0.02:
		_fail(
			failures,
			"parry_clash_context: alignment want %.4f got %.4f" % [want_align, float(clash.get("alignment", -999.0))]
		)
	var c_d_final: float = float(clash.get("c_d_final", 0.0))
	if c_d_final <= 0.0:
		_fail(failures, "parry_clash_context: c_d_final should be positive")
	var expected_margin: float = CombatConstants.parry_deflect_margin_ratio(c_d_final, parry_p_a)
	if absf(float(clash.get("margin_ratio", -1.0)) - expected_margin) > 0.001:
		_fail(failures, "parry_clash_context: margin_ratio does not match c_d_final/parry_p_a")
	var want_pc: float = CombatConstants.parry_control_for_bind_deflect(
		c_d_final,
		parry_p_a,
		float(clash.get("alignment", 0.0)),
		float(dc.get("parry_readiness", 1.0)),
		bool(dc.get("parry_off_balance", false)),
		bool(dc.get("late_parry", false)),
		str(clash.get("contact_type", ""))
	)
	if absf(float(clash.get("parry_control", -9.0)) - want_pc) > 0.001:
		_fail(
			failures,
			"parry_clash_context: parry_control %.4f vs CombatConstants.parry_control_for_bind_deflect %.4f"
			% [float(clash.get("parry_control", -9.0)), want_pc]
		)
	var want_sev: float = CombatConstants.parry_deflect_severity_from_margin_ratio(float(clash.get("margin_ratio", 0.0)))
	if absf(float(clash.get("severity", -1.0)) - want_sev) > 0.001:
		_fail(
			failures,
			"parry_clash_context: severity %.4f vs parry_deflect_severity_from_margin_ratio %.4f"
			% [float(clash.get("severity", -1.0)), want_sev]
		)
	var arch_passed: Dictionary = {}
	var exp_sk: Dictionary = _parry_clash_context_expected_strike_kinematics(
		pa1, attacker, atk_move, 0.5, arch_passed
	)
	if str(clash.get("kinematic_delivery", "")) != str(exp_sk.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_clash_context: kinematic_delivery want %s got %s"
			% [str(exp_sk.get("kinematic_delivery", "")), str(clash.get("kinematic_delivery", ""))]
		)
	if absf(float(clash.get("strike_velocity_m_s", -999.0)) - float(exp_sk.get("strike_velocity_m_s", 0.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context: strike_velocity_m_s %.6f want %.6f"
			% [float(clash.get("strike_velocity_m_s", -999.0)), float(exp_sk.get("strike_velocity_m_s", 0.0))]
		)
	if absf(float(clash.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk.get("strike_kinetic_energy_j", 0.0))) > 0.05:
		_fail(
			failures,
			"parry_clash_context: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash.get("strike_kinetic_energy_j", -999.0)), float(exp_sk.get("strike_kinetic_energy_j", 0.0))]
		)
	if absf(float(clash.get("strike_measure_ratio", -999.0)) - float(pa1.get("strike_measure_ratio", -1.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context: strike_measure_ratio %.6f want %.6f"
			% [float(clash.get("strike_measure_ratio", -999.0)), float(pa1.get("strike_measure_ratio", -1.0))]
		)
	# Late / off-balance flags propagate for calibration (same full_stop path).
	var dc_late: Dictionary = dc.duplicate(true)
	dc_late["late_parry"] = true
	dc_late["parry_off_balance"] = true
	dc_late["parry_readiness"] = 0.88
	dc_late["parry_time_to_react"] = 0.02
	seed(3313)
	var pa2: Dictionary = pa_template.duplicate(true)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa2)
	if atk_w_for_meas != null:
		pa2["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr, attacker, defender, atk_w_for_meas, float(pa2.get("effective_pair_eff_dist", -1.0))
		)
		pa2["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa2, atk_w_for_meas, "spear_thrust", 0.5
		)
	var result2 = _DefenseResolution.resolve(
		pa2,
		attacker,
		defender,
		dc_late,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender),
		_EntityAccess.get_display_name(attacker),
		_EntityAccess.get_display_name(defender)
	)
	if not (result2 is Dictionary) or result2.get("action", "") != "parry_deflect":
		_fail(failures, "parry_clash_context late: expected parry_deflect result")
		_free_manager_restore_global_rng(mgr)
		return
	var clash2: Dictionary = result2.get("parry_clash_context", {})
	if clash2.is_empty():
		_fail(failures, "parry_clash_context late: missing context")
		_free_manager_restore_global_rng(mgr)
		return
	for _sk: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash2.has(_sk):
			_fail(failures, "parry_clash_context late: missing key %s" % _sk)
			_free_manager_restore_global_rng(mgr)
			return
	if not bool(clash2.get("late_parry", false)) or not bool(clash2.get("parry_off_balance", false)):
		_fail(failures, "parry_clash_context: late/off_balance should be true on second fixture")
	if absf(float(clash2.get("parry_readiness", 0.0)) - 0.88) > 0.001:
		_fail(failures, "parry_clash_context: parry_readiness should echo defense choice (late branch)")
	if absf(float(clash2.get("parry_time_to_react", -1.0)) - 0.02) > 0.001:
		_fail(failures, "parry_clash_context: parry_time_to_react should echo defense choice (late branch)")
	if str(clash2.get("attack_type", "")) != atk_move:
		_fail(
			failures,
			"parry_clash_context late: attack_type want %s got %s" % [atk_move, str(clash2.get("attack_type", ""))]
		)
	if str(clash2.get("contact_type", "")).to_lower().strip_edges() != want_ct:
		_fail(
			failures,
			"parry_clash_context late: contact_type want %s got %s" % [want_ct, str(clash2.get("contact_type", ""))]
		)
	if str(clash2.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
		_fail(
			failures,
			"parry_clash_context late: effective_attack_line want %s got %s"
			% [str(pa_template.get("effective_attack_line", "")), str(clash2.get("effective_attack_line", ""))]
		)
	if str(clash2.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
		_fail(
			failures,
			"parry_clash_context late: defender_guard_line want %s got %s"
			% [str(defender.get("guard_line", "")), str(clash2.get("defender_guard_line", ""))]
		)
	if str(clash2.get("archetype_id", "")) != want_arch:
		_fail(
			failures,
			"parry_clash_context late: archetype_id want %s got %s" % [want_arch, str(clash2.get("archetype_id", ""))]
		)
	var want_atk_deg2: float = CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, 1.0) if arc_e >= -900.0 else want_atk_deg
	if absf(float(clash2.get("attack_angle_deg", -9999.0)) - want_atk_deg2) > 0.05:
		_fail(
			failures,
			"parry_clash_context late: attack_angle_deg want %.4f got %.4f"
			% [want_atk_deg2, float(clash2.get("attack_angle_deg", -9999.0))]
		)
	# Guard wobble uses **`randf_range`** when readiness < 1 — replay alignment from stored clash angles (no second draw).
	var align_ctx2: Dictionary = {
		"attack_angle_deg": float(clash2.get("attack_angle_deg", -9999.0)),
		"guard_angle_deg": float(clash2.get("guard_angle_deg", -9999.0)),
	}
	var want_align2: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx2)
	if absf(float(clash2.get("alignment", -999.0)) - want_align2) > 0.02:
		_fail(
			failures,
			"parry_clash_context late: alignment want %.4f got %.4f" % [want_align2, float(clash2.get("alignment", -999.0))]
		)
	var c_d2: float = float(clash2.get("c_d_final", 0.0))
	var want_pc2: float = CombatConstants.parry_control_for_bind_deflect(
		c_d2,
		parry_p_a,
		float(clash2.get("alignment", 0.0)),
		0.88,
		true,
		true,
		str(clash2.get("contact_type", ""))
	)
	if absf(float(clash2.get("parry_control", -9.0)) - want_pc2) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: parry_control %.4f vs formula %.4f"
			% [float(clash2.get("parry_control", -9.0)), want_pc2]
		)
	var want_sev2: float = CombatConstants.parry_deflect_severity_from_margin_ratio(float(clash2.get("margin_ratio", 0.0)))
	if absf(float(clash2.get("severity", -1.0)) - want_sev2) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: severity %.4f vs formula %.4f"
			% [float(clash2.get("severity", -1.0)), want_sev2]
		)
	var exp_sk2: Dictionary = _parry_clash_context_expected_strike_kinematics(
		pa2, attacker, atk_move, 0.5, arch_passed
	)
	if str(clash2.get("kinematic_delivery", "")) != str(exp_sk2.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_clash_context late: kinematic_delivery want %s got %s"
			% [str(exp_sk2.get("kinematic_delivery", "")), str(clash2.get("kinematic_delivery", ""))]
		)
	if absf(float(clash2.get("strike_velocity_m_s", -999.0)) - float(exp_sk2.get("strike_velocity_m_s", 0.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: strike_velocity_m_s %.6f want %.6f"
			% [float(clash2.get("strike_velocity_m_s", -999.0)), float(exp_sk2.get("strike_velocity_m_s", 0.0))]
		)
	if absf(float(clash2.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk2.get("strike_kinetic_energy_j", 0.0))) > 0.05:
		_fail(
			failures,
			"parry_clash_context late: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash2.get("strike_kinetic_energy_j", -999.0)), float(exp_sk2.get("strike_kinetic_energy_j", 0.0))]
		)
	if absf(float(clash2.get("strike_measure_ratio", -999.0)) - float(pa2.get("strike_measure_ratio", -1.0))) > 0.001:
		_fail(
			failures,
			"parry_clash_context late: strike_measure_ratio %.6f want %.6f"
			% [float(clash2.get("strike_measure_ratio", -999.0)), float(pa2.get("strike_measure_ratio", -1.0))]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 3.2 + 3.0: **`parry_partial`** — **`parry_clash_context`** mirrors full-stop keys plus **`remaining_ratio`** / **`geometric_leak`**; Tier **3.0** KE uses reduced **`pa["velocity_m_s"]`** (not intent-speed from **`_parry_clash_context_expected_strike_kinematics`**).
static func _run_parry_partial_clash_context_calibration_fields(failures: PackedStringArray) -> void:
	var mgr2: Node = _MgrScript.new()
	mgr2.register(_new_entity("SWORD"), "player")
	mgr2.register(_new_entity("SPEAR"), "enemy")
	mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var defender_p: Dictionary = mgr2.combatants[0]
	var attacker_p: Dictionary = mgr2.combatants[1]
	defender_p["guard_line"] = "low"
	var pa_partial: Dictionary = {
		"attack_type": "spear_thrust",
		"effective_attack_line": "high",
		"intensity": 0.5,
		"wind_up_duration": 1.0,
		"arc_start_deg": 0.0,
		"arc_end_deg": 180.0,
		"attack_angle_deg": 180.0,
	}
	var parry_p_a_p: float = 5.0
	var parry_c_d_p: float = 100.0
	var dc_partial: Dictionary = {
		"defense": "parry",
		"can_parry_in_time": true,
		"parry_p_a": parry_p_a_p,
		"parry_c_d": parry_c_d_p,
		"parry_time_to_react": 0.1,
		"parry_readiness": 1.0,
		"is_block_parry": false,
		"m_a_parry": 1.25,
		"m_d_parry": 2.5,
		"m_a_velocity": 0.45,
		"dodge_chance": 0.0,
		"dodge_eval_part": "",
		"effective_redirect": 1.0,
		"late_parry": false,
		"parry_off_balance": false,
	}
	seed(3312)
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr2, attacker_p, defender_p, pa_partial)
	var atk_w_part: RefCounted = _EntityAccess.get_weapon(attacker_p)
	if atk_w_part != null:
		pa_partial["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr2, attacker_p, defender_p, atk_w_part, float(pa_partial.get("effective_pair_eff_dist", -1.0))
		)
		pa_partial["impact_blade_station"] = StrikeRealismProfile.blade_station_from_pa(
			pa_partial, atk_w_part, "spear_thrust", 0.5
		)
	var res_partial: Variant = _DefenseResolution.resolve(
		pa_partial,
		attacker_p,
		defender_p,
		dc_partial,
		[],
		"spear_thrust",
		0.5,
		{},
		-1.0,
		1.0,
		1.0,
		_EntityAccess.id_int(defender_p),
		_EntityAccess.get_display_name(attacker_p),
		_EntityAccess.get_display_name(defender_p)
	)
	if not (res_partial is Dictionary) or str((res_partial as Dictionary).get("action", "")) != "parry_partial":
		_fail(failures, "parry_partial_clash: expected parry_partial result")
		_free_manager_restore_global_rng(mgr2)
		return
	var clash_partial: Dictionary = (res_partial as Dictionary).get("parry_clash_context", {}) as Dictionary
	if clash_partial.is_empty():
		_fail(failures, "parry_partial_clash: missing parry_clash_context")
		_free_manager_restore_global_rng(mgr2)
		return
	for _sk_part: String in PARRY_CLASH_CONTEXT_KEYS_FULL_STOP:
		if not clash_partial.has(_sk_part):
			_fail(failures, "parry_partial_clash: missing key %s" % _sk_part)
			_free_manager_restore_global_rng(mgr2)
			return
	if not clash_partial.has("remaining_ratio") or not clash_partial.has("geometric_leak"):
		_fail(failures, "parry_partial_clash: missing remaining_ratio or geometric_leak")
		_free_manager_restore_global_rng(mgr2)
		return
	if absf(float(clash_partial.get("remaining_ratio", -1.0)) - float(pa_partial.get("parry_remaining_ratio", -2.0))) > 1e-5:
		_fail(
			failures,
			"parry_partial_clash: remaining_ratio vs pa parry_remaining_ratio mismatch %s vs %s"
			% [str(clash_partial.get("remaining_ratio")), str(pa_partial.get("parry_remaining_ratio"))]
		)
	var mr_part: float = float(clash_partial.get("margin_ratio", 0.0))
	var want_mr_part: float = CombatConstants.parry_deflect_margin_ratio(
		float(clash_partial["c_d_final"]), parry_p_a_p
	)
	if absf(mr_part - want_mr_part) > 1e-4:
		_fail(failures, "parry_partial_clash: margin_ratio mismatch")
	var pc_part: float = float(clash_partial.get("parry_control", 0.0))
	var want_pc_part: float = CombatConstants.parry_control_for_bind_deflect(
		float(clash_partial["c_d_final"]),
		parry_p_a_p,
		float(clash_partial["alignment"]),
		float(clash_partial.get("parry_readiness", 0.0)),
		bool(clash_partial.get("parry_off_balance", false)),
		bool(clash_partial.get("late_parry", false)),
		str(clash_partial.get("contact_type", ""))
	)
	if absf(pc_part - want_pc_part) > 0.002:
		_fail(failures, "parry_partial_clash: parry_control vs formula mismatch")
	var sev_part: float = float(clash_partial.get("severity", -1.0))
	var want_sev_part: float = CombatConstants.parry_deflect_severity_from_margin_ratio(mr_part)
	if absf(sev_part - want_sev_part) > 0.002:
		_fail(failures, "parry_partial_clash: severity vs formula mismatch")
	var exp_part_k: Dictionary = _parry_clash_expected_partial_strike_kinematics(
		pa_partial, attacker_p, "spear_thrust", 0.5, {}
	)
	if str(clash_partial.get("kinematic_delivery", "")) != str(exp_part_k.get("kinematic_delivery", "")):
		_fail(
			failures,
			"parry_partial_clash: kinematic_delivery want %s got %s"
			% [str(exp_part_k.get("kinematic_delivery", "")), str(clash_partial.get("kinematic_delivery", ""))]
		)
	if absf(float(clash_partial["strike_velocity_m_s"]) - float(exp_part_k["strike_velocity_m_s"])) > 1e-4:
		_fail(
			failures,
			"parry_partial_clash: strike_velocity_m_s %.6f want %.6f"
			% [float(clash_partial["strike_velocity_m_s"]), float(exp_part_k["strike_velocity_m_s"])]
		)
	if absf(float(clash_partial["strike_kinetic_energy_j"]) - float(exp_part_k["strike_kinetic_energy_j"])) > 1e-3:
		_fail(
			failures,
			"parry_partial_clash: strike_kinetic_energy_j %.6f want %.6f"
			% [float(clash_partial["strike_kinetic_energy_j"]), float(exp_part_k["strike_kinetic_energy_j"])]
		)
	if absf(float(clash_partial["strike_measure_ratio"]) - float(pa_partial.get("strike_measure_ratio", -99.0))) > 0.001:
		_fail(
			failures,
			"parry_partial_clash: strike_measure_ratio %.6f want %.6f"
			% [float(clash_partial["strike_measure_ratio"]), float(pa_partial.get("strike_measure_ratio", -1.0))]
		)
	_free_manager_restore_global_rng(mgr2)


## Tier 3.2: **`CombatConstants.parry_control_for_bind_deflect`** pure formula corner cases.
static func _run_parry_control_bind_deflect_formula(failures: PackedStringArray) -> void:
	var hi_cd: float = 100.0
	var pa_m: float = 5.0
	var al: float = 0.9
	var cut_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "cut")
	if not is_equal_approx(cut_hi, 1.0):
		_fail(failures, "parry_ctrl_formula: high-margin cut want 1.0 got %.4f" % cut_hi)
	var stab_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "stab")
	if not is_equal_approx(stab_hi, 0.85):
		_fail(failures, "parry_ctrl_formula: high-margin stab want 0.85 got %.4f" % stab_hi)
	var blunt_hi: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, al, 1.0, false, false, "BLUNT")
	if not is_equal_approx(blunt_hi, cut_hi):
		_fail(failures, "parry_ctrl_formula: blunt should match cut for thrust mult got %.4f" % blunt_hi)
	var low_cd: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 0.25
	var cut_low: float = CombatConstants.parry_control_for_bind_deflect(low_cd, pa_m, 1.0, 1.0, false, false, "cut")
	if not is_equal_approx(cut_low, 0.5):
		_fail(failures, "parry_ctrl_formula: low-margin cut want 0.5 got %.4f" % cut_low)
	var late_mid: float = CombatConstants.parry_control_for_bind_deflect(hi_cd, pa_m, 0.65, 1.0, false, true, "cut")
	if not is_equal_approx(late_mid, 0.78):
		_fail(failures, "parry_ctrl_formula: late+align 0.65 cut want 0.78 got %.4f" % late_mid)
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(2.0), 1.0):
		_fail(failures, "parry_severity: margin 2.0 want 1.0")
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(0.5), 0.0):
		_fail(failures, "parry_severity: margin 0.5 want 0.0")
	if not is_equal_approx(CombatConstants.parry_deflect_severity_from_margin_ratio(1.25), 0.25):
		_fail(failures, "parry_severity: margin 1.25 want 0.25")
	if not is_equal_approx(
		CombatConstants.parry_deflect_margin_ratio(hi_cd, pa_m),
		hi_cd / maxf(pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD, 0.01)
	):
		_fail(failures, "parry_margin_ratio: helper should match explicit formula")


## Tier 3.2: **`GuardLineUpdater.set_guard_deflected`** — when **`severity`** is absent, **`guard_deflect_blend`** matches **`parry_deflect_severity_from_margin_ratio(margin_ratio)`**; explicit **`severity`** wins if both are set.
static func _run_guard_line_deflected_severity_from_margin_ratio(failures: PackedStringArray) -> void:
	var c1: Dictionary = {"guard_line": "high", "combatant_id": 1, "alive": true}
	var clash_margin: Dictionary = {
		"parry_control": 0.3,
		"margin_ratio": 1.5,
		"defender_guard_line": "low",
		"contact_type": "stab",
		"alignment": 0.9,
	}
	_GuardLineUpdater.set_guard_deflected(c1, "spear_thrust", "", "low", clash_margin)
	var want_from_margin: float = CombatConstants.parry_deflect_severity_from_margin_ratio(1.5)
	if not is_equal_approx(float(c1.get("guard_deflect_blend", -1.0)), want_from_margin):
		_fail(
			failures,
			"guard_deflect_blend: margin-only clash want %.4f got %.4f" % [want_from_margin, float(c1.get("guard_deflect_blend", -1.0))]
		)
	var clash_both: Dictionary = clash_margin.duplicate(true)
	clash_both["severity"] = 0.11
	clash_both["margin_ratio"] = 2.0
	var c2: Dictionary = {"guard_line": "high", "combatant_id": 2, "alive": true}
	_GuardLineUpdater.set_guard_deflected(c2, "spear_thrust", "", "low", clash_both)
	if not is_equal_approx(float(c2.get("guard_deflect_blend", -1.0)), 0.11):
		_fail(
			failures,
			"guard_deflect_blend: explicit severity should win when both keys set (want 0.11 got %.4f)" % float(c2.get("guard_deflect_blend", -1.0))
		)


## Godot **4.6.stable** global RNG: **`seed(1)`** yields **`attack_hit`** on the afterblow execute path for the SWORD 1v1 **`_afterblow_harness_seed_pending_cut`** fixture (avoids scanning thousands of seeds in **`run_all()`**).
const _AFTERBLOW_EXECUTE_HIT_SEED: int = 1
## **`seed(2)`**: hybrid hindrance in **(ALLOW, BLOCK)** and first **`randf()` < hindrance** → **`try_afterblow` false** + **`_cancel_pending`** (chest **`final_cut` 11.25**).
const _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED: int = 2
## **`seed(0)`**: same fixture + chest **`final_cut` 11.25** → **`randf() ≥ hindrance`** → **`_execute_afterblow`** (**`afterblow_damage_mult` 0.55**) + **`attack_hit`** resolve.
const _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED: int = 0
const _HARNESS_META_RECORD_AFTERBLOW_MULT := "_harness_record_afterblow_damage_mult"
const _HARNESS_META_LAST_AFTERBLOW_MULT := "_harness_last_afterblow_damage_mult"
const _HARNESS_META_EXPOSE_PENETRATION_APPLIED := "_harness_expose_penetration_applied"
const _HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"


## Tier 3.3 harness: deterministic **`pending_attack`** (cut + stamped geometry) so **`AfterblowHandler`** → **`_execute_attack`** does not depend on wind-up RNG.
static func _afterblow_harness_seed_pending_cut(mgr: Node, attacker_index: int, defender_index: int) -> void:
	var atk: Dictionary = mgr.combatants[attacker_index]
	var defc: Dictionary = mgr.combatants[defender_index]
	var weapon = _EntityAccess.get_weapon(atk)
	var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
	if weapon != null and weapon.has_method("get_available_attack_types"):
		var types_a: Array = weapon.get_available_attack_types()
		if types_a.has(WeaponConstants.ATTACK_TYPE_CUT):
			attack_type = WeaponConstants.ATTACK_TYPE_CUT
		elif not types_a.is_empty():
			attack_type = str(types_a[0])
	var archetype: Dictionary = WeaponConstants.get_archetype(WeaponConstants.ARCHETYPE_SLASH)
	if weapon != null and weapon.has_method("get_archetype_id"):
		archetype = WeaponConstants.get_archetype(weapon.get_archetype_id(attack_type))
	var pa: Dictionary = {
		"target_id": _EntityAccess.id_int(defc),
		"intensity": 0.88,
		"power": 0.72,
		"follow_through": 0.68,
		"attack_type": attack_type,
		"archetype": archetype,
	}
	_ActionsBuilder.stamp_attack_pair_geometry_on_dict(mgr, atk, defc, pa)
	if weapon != null:
		pa["strike_measure_ratio"] = _ActionsBuilder.strike_measure_ratio_for_attack_pair(
			mgr, atk, defc, weapon, float(pa.get("effective_pair_eff_dist", -1.0))
		)
		pa["move_contact_type"] = WeaponConstants.contact_type_for_move_id(attack_type)
	else:
		pa["strike_measure_ratio"] = 1.0
	atk["state"] = CombatConstants.STATE_WIND_UP
	atk["state_timer"] = 0.0
	atk["state_duration"] = 0.5
	atk["pending_attack"] = pa


## Tier 3.3: **`outcome` == `"deflected"`** → **`_execute_afterblow`** (**hindrance 0**) → **`CombatManager._execute_attack`**; fixed **`seed(1)`** (**`_AFTERBLOW_EXECUTE_HIT_SEED`**) must yield **`recovery_cause` == `attack_hit`** and **`afterblow_damage_mult` == 1.0** (via harness meta on manager).
static func _run_afterblow_deflected_triggers_full_resolve_hit(failures: PackedStringArray) -> void:
	seed(_AFTERBLOW_EXECUTE_HIT_SEED)
	var mgr: Node = _MgrScript.new()
	mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	_afterblow_harness_seed_pending_cut(mgr, 1, 0)
	var atk: Dictionary = mgr.combatants[1]
	var tid: int = _EntityAccess.id_int(atk)
	var rd: Dictionary = {
		"part": "chest",
		"outcome": "deflected",
		"final_cut": 0.0,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if not _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		_fail(failures, "afterblow_deflected_hit: try_afterblow false (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
		mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
		if mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
			mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
		_free_manager_restore_global_rng(mgr)
		return
	if str(atk.get("recovery_cause", "")) != "attack_hit":
		_fail(
			failures,
			"afterblow_deflected_hit: want recovery_cause attack_hit got %s (seed=%d)"
			% [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
		)
	if _EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"afterblow_deflected_hit: want recovering got %s (seed=%d)"
			% [_EntityAccess.state_str(atk), _AFTERBLOW_EXECUTE_HIT_SEED]
		)
	if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
		_fail(failures, "afterblow_deflected_hit: pending_attack not empty (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
	if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
		_fail(failures, "afterblow_deflected_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
	elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 1.0):
		_fail(
			failures,
			"afterblow_deflected_hit: want afterblow_damage_mult 1.0 got %s (seed=%d)"
			% [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
		)
	mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
	mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
	_free_manager_restore_global_rng(mgr)


## Tier 3.3: low hybrid hindrance (**≤ `AFTERBLOW_HINDRANCE_ALLOW`**) → **`_execute_afterblow`** stamps **`afterblow_damage_mult` < 1.0**; same fixed seed + **`attack_hit`** resolve.
static func _run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures: PackedStringArray) -> void:
	seed(_AFTERBLOW_EXECUTE_HIT_SEED)
	var mgr: Node = _MgrScript.new()
	mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	_afterblow_harness_seed_pending_cut(mgr, 1, 0)
	var atk: Dictionary = mgr.combatants[1]
	var tid: int = _EntityAccess.id_int(atk)
	var rd: Dictionary = {
		"part": "chest",
		"outcome": "hit",
		"final_cut": 5.0,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if not _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		_fail(failures, "afterblow_allow_hit: try_afterblow false (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
		mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
		if mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
			mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
		_free_manager_restore_global_rng(mgr)
		return
	if str(atk.get("recovery_cause", "")) != "attack_hit":
		_fail(
			failures,
			"afterblow_allow_hit: want recovery_cause attack_hit got %s (seed=%d)"
			% [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
		)
	if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
		_fail(failures, "afterblow_allow_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
	elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 0.8):
		_fail(
			failures,
			"afterblow_allow_hit: want afterblow_damage_mult 0.8 (hindrance 0.2) got %s (seed=%d)"
			% [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
		)
	mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
	mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
	_free_manager_restore_global_rng(mgr)


## Tier 3.3: hindrance strictly between **`AFTERBLOW_HINDRANCE_ALLOW`** and **`AFTERBLOW_HINDRANCE_BLOCK`** → **`randf() < hindrance`** cancels (**`_cancel_pending`**, **`try_afterblow` false**); fixed **`seed(2)`** on the same fixture + chest **`final_cut` 11.25** (hybrid hindrance **0.45**).
static func _run_afterblow_mid_hindrance_rand_cancel(failures: PackedStringArray) -> void:
	seed(_AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED)
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	_afterblow_harness_seed_pending_cut(mgr, 1, 0)
	var atk: Dictionary = mgr.combatants[1]
	var tid: int = _EntityAccess.id_int(atk)
	var rd: Dictionary = {
		"part": "chest",
		"outcome": "hit",
		"final_cut": 11.25,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		_fail(
			failures,
			"afterblow_mid_rand_cancel: try_afterblow should be false (seed=%d)"
			% _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED
		)
		_free_manager_restore_global_rng(mgr)
		return
	if _EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
		_fail(
			failures,
			"afterblow_mid_rand_cancel: want recovering got %s (seed=%d)"
			% [_EntityAccess.state_str(atk), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
		)
	if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
		_fail(failures, "afterblow_mid_rand_cancel: pending_attack should clear (seed=%d)" % _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED)
	if absf(float(atk.get("state_duration", 0.0)) - CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S) > 0.0001:
		_fail(
			failures,
			"afterblow_mid_rand_cancel: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s (seed=%d)"
			% [str(atk.get("state_duration")), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
		)
	_free_manager_restore_global_rng(mgr)


## Tier 3.3: middle hindrance + **`randf() ≥ hindrance`** → **`_execute_afterblow`** (**`afterblow_damage_mult` 0.55**) + full resolve **`attack_hit`**; fixed **`seed(0)`**.
static func _run_afterblow_mid_hindrance_rand_executes_hit(failures: PackedStringArray) -> void:
	seed(_AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED)
	var mgr: Node = _MgrScript.new()
	mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	_afterblow_harness_seed_pending_cut(mgr, 1, 0)
	var atk: Dictionary = mgr.combatants[1]
	var tid: int = _EntityAccess.id_int(atk)
	var rd: Dictionary = {
		"part": "chest",
		"outcome": "hit",
		"final_cut": 11.25,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if not _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		_fail(
			failures,
			"afterblow_mid_rand_execute: try_afterblow should be true (seed=%d)"
			% _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED
		)
		mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
		if mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
			mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
		_free_manager_restore_global_rng(mgr)
		return
	if str(atk.get("recovery_cause", "")) != "attack_hit":
		_fail(
			failures,
			"afterblow_mid_rand_execute: want recovery_cause attack_hit got %s (seed=%d)"
			% [str(atk.get("recovery_cause", "")), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
		)
	if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
		_fail(failures, "afterblow_mid_rand_execute: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED)
	elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 0.55):
		_fail(
			failures,
			"afterblow_mid_rand_execute: want afterblow_damage_mult 0.55 got %s (seed=%d)"
			% [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
		)
	mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
	mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
	_free_manager_restore_global_rng(mgr)


## Tier 3.3: **`GuardLineUpdater.set_guard_from_move`** copies move **`attack_line`** into **`guard_line`** and syncs **`guard_zone`** (clears deflect keys).
static func _run_guard_from_move_sets_guard_line_and_zone(failures: PackedStringArray) -> void:
	var c: Dictionary = {"guard_line": "low", "guard_zone": "left_leg", "combatant_id": 901, "alive": true}
	_GuardLineUpdater.set_guard_from_move(c, "oberhau", "")
	if str(c.get("guard_line", "")) != "high":
		_fail(failures, "guard_from_move: oberhau want guard_line high got %s" % str(c.get("guard_line")))
	if c.has("guard_deflect_blend") or c.has("guard_deflect_from_line"):
		_fail(failures, "guard_from_move: should clear deflect keys")
	if str(c.get("guard_zone", "")) != "head":
		_fail(failures, "guard_from_move: LINE_TO_DEFAULT_PART high -> head want head got %s" % str(c.get("guard_zone")))


## Tier 3.3: **`AfterblowHandler.try_afterblow`** — no **`pending_attack`** → **false** (no **`_execute_attack`**).
static func _run_afterblow_no_pending_returns_false(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var tgt: Dictionary = mgr.combatants[1]
	tgt["pending_attack"] = {}
	tgt["state"] = CombatConstants.STATE_WIND_UP
	var tid: int = _EntityAccess.id_int(tgt)
	if _AfterblowHandler.try_afterblow(mgr, 0, tid, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 1.0):
		_fail(failures, "afterblow_no_pending: expected false")
	_free_manager(mgr)


## Tier 3.3: **`AfterblowHandler.try_afterblow`** — not **`STATE_WIND_UP`** → **false**.
static func _run_afterblow_wrong_state_returns_false(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var tgt: Dictionary = mgr.combatants[1]
	tgt["pending_attack"] = {"target_id": 0, "attack_type": "thrust"}
	tgt["state"] = CombatConstants.STATE_WAITING
	var tid: int = _EntityAccess.id_int(tgt)
	if _AfterblowHandler.try_afterblow(mgr, 0, tid, {"part": "chest", "outcome": "hit", "final_cut": 1.0}, 1.0):
		_fail(failures, "afterblow_wrong_state: expected false")
	_free_manager(mgr)


## Tier 3.3: **`AfterblowHandler`** hybrid hindrance ≥ **`AFTERBLOW_HINDRANCE_BLOCK`** cancels **`pending_attack`** (no **`_execute_attack`**).
static func _run_afterblow_hindrance_block_cancels_pending(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var tgt: Dictionary = mgr.combatants[1]
	tgt["state"] = CombatConstants.STATE_WIND_UP
	tgt["pending_attack"] = {"target_id": 0, "attack_type": "thrust"}
	var tid: int = _EntityAccess.id_int(tgt)
	var rd: Dictionary = {
		"part": "right_arm",
		"outcome": "hit",
		"final_cut": 40.0,
		"final_blunt": 0.0,
		"final_bone": 0.0,
	}
	if _AfterblowHandler.try_afterblow(mgr, 0, tid, rd, 1.0):
		_fail(failures, "afterblow_block: expected false (hindered cancel)")
	if _EntityAccess.state_str(tgt) != CombatConstants.STATE_RECOVERING:
		_fail(failures, "afterblow_block: want recovering got %s" % str(tgt.get("state")))
	if not _EntityAccess.nested_dictionary_read(tgt, "pending_attack").is_empty():
		_fail(failures, "afterblow_block: pending_attack should clear")
	if absf(float(tgt.get("state_duration", 0.0)) - CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S) > 0.0001:
		_fail(
			failures,
			"afterblow_block: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s"
			% str(tgt.get("state_duration"))
		)
	_free_manager(mgr)


static func _run_parry_pack_flank_effective_spacing(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE] = true
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 3, "ranks": 1, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	mgr.combatants[0]["file"] = 0
	mgr.combatants[1]["file"] = 1
	mgr._recompute_zoc_and_distance()
	var p0: Dictionary = mgr.combatants[0]
	var e_adj: Dictionary = mgr.combatants[1]
	var eff_adj: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e_adj)
	if eff_adj + 1e-4 >= float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		_fail(
			failures,
			"parry_pack_flank: adjacent files expected eff spacing < PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_adj
		)
	var m_adj: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if is_equal_approx(m_adj, CombatConstants.FLANK_PARRY_MOD):
		_fail(failures, "parry_pack_flank: adjacent files should not apply flank mod (got %.4f)" % m_adj)
	mgr.combatants[1]["file"] = 2
	mgr._recompute_zoc_and_distance()
	var e_far: Dictionary = mgr.combatants[1]
	var eff_far: float = _ActionsBuilder.effective_pair_file_spacing_equivalent(mgr, p0, e_far)
	if eff_far + 1e-4 < float(CombatConstants.PARRY_FLANK_EFFECTIVE_FILES_MIN):
		_fail(
			failures,
			"parry_pack_flank: |Δfile|==2 expected eff spacing >= PARRY_FLANK_EFFECTIVE_FILES_MIN got %.4f"
			% eff_far
		)
	var m_far: float = _ZoneOfControl.get_engagement_parry_multiplier(mgr, p_id, e_id)
	if not is_equal_approx(m_far, CombatConstants.FLANK_PARRY_MOD):
		_fail(
			failures,
			"parry_pack_flank: |Δfile|==2 with protection circle should apply flank mod (got %.4f want %.4f)"
			% [m_far, CombatConstants.FLANK_PARRY_MOD]
		)
	_free_manager(mgr)


## Tier 1.8 telemetry: illegal crash resolve increments counter (intrusion disabled or wrong mode).
static func _run_combat_telemetry_crash_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_EngagementResolver.resolve_crash_attempt(mgr, p_id, e_id)
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_crash: missing telemetry meta after blocked crash")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_crash_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_crash: expected invalid_crash_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Tier 1.8: weapon wind-up that resolves when `can_melee_threaten` is false (e.g. band drift) aborts + telemetry.
static func _run_telemetry_invalid_melee_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	_WindUpStarter.start(mgr, p_id, e_id, "thrust")
	var p: Dictionary = mgr.combatants[0]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	var res: Dictionary = _AttackResolver.resolve_attack(mgr, p_id)
	if str(res.get("action", "")) != "skip":
		_fail(failures, "telemetry_melee_geom: expected skip when LONG+threaten false got %s" % str(res))
	if float(res.get("recovery_duration", 0.0)) <= 0.0:
		_fail(failures, "telemetry_melee_geom: expected positive recovery on abort")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_melee_geom: missing telemetry meta")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_melee_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_melee_geom: expected invalid_melee_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Tier 1.8: `attempt_close` is not listed when pair band is MID/CLOSE (matches `resolve_close_attempt` LONG-only).
static func _run_attempt_close_listed_only_at_long(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	p["gauge"] = 100.0
	en["gauge"] = 100.0
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
	var acts_mid: Array = _ActionsBuilder.build(mgr, p_id)
	for raw in acts_mid:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
			if int(a.get("target_id", -1)) == e_id:
				_fail(
					failures,
					"attempt_close_list: must not list close vs MID opponent (target %d)" % e_id
				)
				_free_manager(mgr)
				return
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var acts_long: Array = _ActionsBuilder.build(mgr, p_id)
	var saw_close: bool = false
	for raw in acts_long:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var a: Dictionary = raw as Dictionary
		if (
			str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ATTEMPT_CLOSE
			and int(a.get("target_id", -1)) == e_id
		):
			saw_close = true
			break
	if not saw_close:
		_fail(failures, "attempt_close_list: expected attempt_close vs LONG opponent")
	_free_manager(mgr)


## Tier 1.8: `CombatAIActionPicker` must not weight stale `attempt_close` at MID/CLOSE (defense in depth vs listing).
static func _run_attempt_close_ai_weight_zero_when_not_long(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	p["gauge"] = 100.0
	en["gauge"] = 100.0
	var a_close: Dictionary = {
		"target_id": e_id,
		"move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
	}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
	if _AIPicker._get_action_weight(a_close, p_id, mgr, true) > 0.001:
		_fail(
			failures,
			"attempt_close_weight: MID band should zero weight got %.6f"
			% _AIPicker._get_action_weight(a_close, p_id, mgr, true)
		)
		_free_manager(mgr)
		return
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var w_long: float = _AIPicker._get_action_weight(a_close, p_id, mgr, true)
	if w_long <= 0.001:
		_fail(failures, "attempt_close_weight: LONG band should allow positive weight got %.6f" % w_long)
	_free_manager(mgr)


## Tier 1.8: `resolve_close_attempt` when pair band is not LONG (stale vs `attempt_close` listing) increments telemetry.
static func _run_telemetry_invalid_close_resolve_blocked(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_MID
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_MID
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_close: missing telemetry meta after blocked close")
	else:
		var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
		if int(tel.get("invalid_close_resolve_blocked", 0)) < 1:
			_fail(failures, "telemetry_close: expected invalid_close_resolve_blocked >= 1 got %s" % str(tel))
	_free_manager(mgr)


## Failed pressure-vs-evasion close emits `reason: contest_failed` for UI / tooling (not only generic `close_failed`).
static func _run_close_contest_failed_emits_reason(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var p: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var sd: Dictionary = _EntityAccess.stats_dict_for_mutation(p)
	sd["strength"] = 0.0
	var cap: Array = []
	mgr.action_resolved.connect(
		func(_aid: int, _tid: int, result: Dictionary) -> void:
			cap.clear()
			cap.append(result)
	)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if cap.is_empty():
		_fail(failures, "close_contest: expected action_resolved payload")
		_free_manager(mgr)
		return
	var r: Dictionary = cap[0] as Dictionary
	if str(r.get("outcome", "")) != "close_failed":
		_fail(failures, "close_contest: expected close_failed got %s" % str(r))
	elif str(r.get("reason", "")) != "contest_failed":
		_fail(failures, "close_contest: expected reason contest_failed got %s" % str(r.get("reason", "")))
	var line: String = _CombatLogFormatter.format_action_line(
		"P", "player", "E", "enemy", r
	)
	if not line.contains("measure"):
		_fail(failures, "close_contest: formatter should mention defender measure got %s" % line)
	_free_manager(mgr)


## `resolve_close_attempt` must not run the contest vs an incapacitated defender (stale UI / AI only).
static func _run_resolve_close_no_emit_when_target_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy := _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(en):
		_fail(failures, "close_skip_incap: enemy should be incap for test")
		_free_manager(mgr)
		return
	var p: Dictionary = mgr.combatants[0]
	if typeof(p.get("distance_to", null)) != TYPE_DICTIONARY:
		p["distance_to"] = {}
	if typeof(en.get("distance_to", null)) != TYPE_DICTIONARY:
		en["distance_to"] = {}
	(p["distance_to"] as Dictionary)[e_id] = CombatConstants.DISTANCE_LONG
	(en["distance_to"] as Dictionary)[p_id] = CombatConstants.DISTANCE_LONG
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	_EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
	if int(fired_box[0]) != 0:
		_fail(failures, "close_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0]))
	_free_manager(mgr)


## `resolve_crash_attempt` must not run breach logic vs an incapacitated defender (even if intrusion flag toggles later).
static func _run_resolve_crash_no_emit_when_target_incap(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	var ent_enemy := _new_entity("SWORD")
	ent_enemy.consciousness = 5.0
	mgr.register(ent_enemy, "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr._recompute_zoc_and_distance()
	var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
	var en: Dictionary = mgr.combatants[1]
	if not _EntityAccess.is_incapacitated(en):
		_fail(failures, "crash_skip_incap: enemy should be incap for test")
		_free_manager(mgr)
		return
	var fired_box: Array = [0]
	mgr.action_resolved.connect(
		func(_a: int, _t: int, _r: Dictionary) -> void:
			fired_box[0] = int(fired_box[0]) + 1
	)
	_EngagementResolver.resolve_crash_attempt(mgr, p_id, e_id)
	if int(fired_box[0]) != 0:
		_fail(failures, "crash_skip_incap: expected no action_resolved got fired=%d" % int(fired_box[0]))
	_free_manager(mgr)


## `CombatLogFormatter` — **`parry_deflect`**: non-empty **`parry_clash_context`** does not change the line unless **`COMBAT_DEBUG_CALIBRATION`** (default **false**).
static func _run_parry_deflect_formatter_clash_context_branches(failures: PackedStringArray) -> void:
	var base_r: Dictionary = {
		"outcome": "parry_deflect",
		"dmg": 0,
		"died": false,
		"part": "",
		"health_before": -1,
		"health_after": -1
	}
	var line0: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_r)
	if line0.contains("meas=") or line0.contains("[size=10]"):
		_fail(failures, "parry_fmt: baseline should not include clash suffix got %s" % line0)
	var with_ctx: Dictionary = base_r.duplicate(true)
	with_ctx["parry_clash_context"] = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.2,
		"parry_control": 0.75
	}
	var line_ctx: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_ctx)
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		if not line_ctx.contains("thrust") or not line_ctx.contains("meas=") or not line_ctx.contains("bind="):
			_fail(
				failures,
				"parry_fmt: calibration on expected thrust/meas/bind in %s" % line_ctx
			)
	else:
		if line_ctx != line0:
			_fail(
				failures,
				"parry_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_ctx, line0]
			)
	var empty_ctx: Dictionary = base_r.duplicate(true)
	empty_ctx["parry_clash_context"] = {}
	var line_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_ctx)
	if line_empty != line0:
		_fail(
			failures,
			"parry_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_empty, line0]
		)


## `CombatLogFormatter` — **`parry_partial`**: non-empty **`parry_clash_context`** unchanged unless **`COMBAT_DEBUG_CALIBRATION`**; suffix includes **`rem=`** (**`remaining_ratio`**).
static func _run_parry_partial_formatter_clash_context_branches(failures: PackedStringArray) -> void:
	var base_pp: Dictionary = {
		"outcome": "parry_partial",
		"dmg": 0,
		"died": false,
		"part": "",
		"health_before": -1,
		"health_after": -1
	}
	var line_pp0: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", base_pp)
	if line_pp0.contains("meas=") or line_pp0.contains("[size=10]"):
		_fail(failures, "parry_partial_fmt: baseline should not include clash suffix got %s" % line_pp0)
	if not line_pp0.contains("partially parried"):
		_fail(failures, "parry_partial_fmt: baseline should say partially parried got %s" % line_pp0)
	var with_pp: Dictionary = base_pp.duplicate(true)
	with_pp["parry_clash_context"] = {
		"kinematic_delivery": "thrust",
		"strike_measure_ratio": 1.2,
		"parry_control": 0.75,
		"remaining_ratio": 0.11
	}
	var line_pp_ctx: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", with_pp)
	if CombatConstants.COMBAT_DEBUG_CALIBRATION:
		if (
			not line_pp_ctx.contains("thrust")
			or not line_pp_ctx.contains("meas=")
			or not line_pp_ctx.contains("bind=")
			or not line_pp_ctx.contains("rem=")
		):
			_fail(
				failures,
				"parry_partial_fmt: calibration on expected thrust/meas/bind/rem in %s" % line_pp_ctx
			)
	else:
		if line_pp_ctx != line_pp0:
			_fail(
				failures,
				"parry_partial_fmt: calibration off expected identical lines got\n%s\nvs\n%s" % [line_pp_ctx, line_pp0]
			)
	var empty_pp: Dictionary = base_pp.duplicate(true)
	empty_pp["parry_clash_context"] = {}
	var line_pp_empty: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", empty_pp)
	if line_pp_empty != line_pp0:
		_fail(
			failures,
			"parry_partial_fmt: empty parry_clash_context should match baseline got %s vs %s" % [line_pp_empty, line_pp0]
		)


## Log contract for `crash_failed` + `reason` (contest `repelled`, intrusion pre-checks, engagement mode) — no live breach harness required.
static func _run_crash_failed_formatter_reason_branches(failures: PackedStringArray) -> void:
	var base: Dictionary = {"outcome": "crash_failed", "dmg": 0, "died": false}
	var cases: Array = [
		["repelled", "line held"],
		["engagement_mode_skirmish", "cannot breach"],
		["light_armor", "not heavy enough"],
		["low_breach_power", "not ready to drive"],
		["intruder_cap", "too many fighters"],
	]
	for row in cases:
		var reason: String = str(row[0])
		var needle: String = str(row[1])
		var r: Dictionary = base.duplicate()
		r["reason"] = reason
		var line: String = _CombatLogFormatter.format_action_line("A", "player", "D", "enemy", r)
		if not line.contains(needle):
			_fail(
				failures,
				"crash_fmt: reason=%s expected substring %s in %s" % [reason, needle, line]
			)


## Tier 1.8: automatic doctrine pinch increments telemetry (Option 4 pilot).
static func _run_telemetry_automatic_doctrine_pinch_record(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	_TacticalCombat.record_automatic_doctrine_pinch(mgr, "enemy")
	if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
		_fail(failures, "telemetry_auto_doc: missing meta after record")
		_free_manager(mgr)
		return
	var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
	if int(tel.get("automatic_doctrine_pinch_count", 0)) != 1:
		_fail(
			failures,
			"telemetry_auto_doc: expected automatic_doctrine_pinch_count 1 got %s" % str(tel.get("automatic_doctrine_pinch_count", -1))
		)
		_free_manager(mgr)
		return
	var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
	if typeof(lap) != TYPE_DICTIONARY:
		_fail(failures, "telemetry_auto_doc: last_automatic_doctrine_pinch should be a dict")
		_free_manager(mgr)
		return
	if str((lap as Dictionary).get("formation_id", "")) != "enemy":
		_fail(failures, "telemetry_auto_doc: last pinch formation_id mismatch")
	_free_manager(mgr)


## Snapshot rows carry `formation_doctrine` aligned with `CombatManager.get_formation_doctrine`.
static func _run_combatants_snapshot_formation_doctrine_field(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
	var rows: Array = mgr.get_combatants()
	var ok_player: bool = false
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var rd: Dictionary = row as Dictionary
		if str(rd.get("formation_id", "")) != "player":
			continue
		ok_player = true
		if str(rd.get("formation_doctrine", "")) != CombatConstants.DOCTRINE_HOLD_LANE:
			_fail(
				failures,
				"snapshot_doctrine: player row got %s want hold_lane" % str(rd.get("formation_doctrine", ""))
			)
		break
	if not ok_player:
		_fail(failures, "snapshot_doctrine: no player row in get_combatants")
	_free_manager(mgr)
