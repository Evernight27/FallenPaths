class_name CombatConstantsMethods
extends RefCounted

## Static method forwards for CombatConstants (consts live on CombatConstants.gd).

const TimingConstants := preload("res://combat/constants/CombatConstantsTiming.gd")
const Stamina := preload("res://combat/constants/CombatConstantsStamina.gd")
const AttackPath := preload("res://combat/constants/CombatConstantsAttackPath.gd")
const State := preload("res://combat/constants/CombatConstantsState.gd")
const DictKeys := preload("res://combat/constants/CombatConstantsDictKeys.gd")
const Damage := preload("res://combat/constants/CombatConstantsDamage.gd")
const GuardZone := preload("res://combat/constants/CombatConstantsGuardZone.gd")
const Distance := preload("res://combat/constants/CombatConstantsDistance.gd")
const EventQueue := preload("res://combat/constants/CombatConstantsEventQueue.gd")
const Debug := preload("res://combat/constants/CombatConstantsDebug.gd")
const ParryChoice := preload("res://combat/constants/CombatConstantsParryChoice.gd")
const FeatureFlags := preload("res://combat/constants/CombatConstantsFeatureFlags.gd")
const RecoveryCause := preload("res://combat/constants/CombatConstantsRecoveryCause.gd")
const MentalStack := preload("res://combat/constants/CombatConstantsMentalStack.gd")
const Parry := preload("res://combat/constants/CombatConstantsParry.gd")
const Footwork := preload("res://combat/constants/CombatConstantsFootwork.gd")
const FormationMove := preload("res://combat/constants/CombatConstantsFormationMove.gd")
const CloseSlots := preload("res://combat/constants/CombatConstantsCloseSlots.gd")
const Encounter := preload("res://combat/constants/CombatConstantsEncounter.gd")
const Misc := preload("res://combat/constants/CombatConstantsMisc.gd")
const Stance := preload("res://combat/constants/CombatConstantsStance.gd")
const MedicalTargets := preload("res://combat/constants/CombatConstantsMedicalTargets.gd")
const MuscleFatigue := preload("res://combat/constants/CombatConstantsMuscleFatigue.gd")
const Moves := preload("res://combat/constants/CombatConstantsMoves.gd")
const Tuning := preload("res://combat/constants/CombatConstantsTuning.gd")
const Formation := preload("res://combat/constants/CombatConstantsFormation.gd")
const Engagement := preload("res://combat/constants/CombatConstantsEngagement.gd")
const AITargeting := preload("res://combat/constants/CombatConstantsAITargeting.gd")
const AIWeights := preload("res://combat/constants/CombatConstantsAIWeights.gd")
const DepthPolearm := preload("res://combat/constants/CombatConstantsDepthPolearm.gd")
const Doctrine := preload("res://combat/constants/CombatConstantsDoctrine.gd")
const Bind := preload("res://combat/constants/CombatConstantsBind.gd")
const GuardLinesHelpers := preload("res://combat/constants/CombatConstantsGuardLinesHelpers.gd")
const FootworkPA := preload("res://combat/constants/CombatConstantsFootworkPA.gd")


static func is_feature_muscle_group_fatigue_enabled() -> bool:
	return MuscleFatigue.is_feature_muscle_group_fatigue_enabled()


static func set_feature_muscle_group_fatigue_load(enabled: bool) -> void:
	return MuscleFatigue.set_feature_muscle_group_fatigue_load(enabled)


static func guard_line_for_focus_move_id(move_id: String) -> String:
	return Moves.guard_line_for_focus_move_id(move_id)


static func is_direct_pressure_move(move_id: String) -> bool:
	return Moves.is_direct_pressure_move(move_id)


static func is_dressing_medical_move(move_id: String) -> bool:
	return Moves.is_dressing_medical_move(move_id)


static func is_execute_move(move_id: String) -> bool:
	return Moves.is_execute_move(move_id)


static func is_focus_line_move(move_id: String) -> bool:
	return Moves.is_focus_line_move(move_id)


static func is_medical_move(move_id: String) -> bool:
	return Moves.is_medical_move(move_id)


static func is_medical_target_method(target_method: String) -> bool:
	return Moves.is_medical_target_method(target_method)


static func is_pack_wound_move(move_id: String) -> bool:
	return Moves.is_pack_wound_move(move_id)


static func is_stabilize_wound_move(move_id: String) -> bool:
	return Moves.is_stabilize_wound_move(move_id)


static func is_tourniquet_move(move_id: String) -> bool:
	return Moves.is_tourniquet_move(move_id)


static func is_wind_up_medical_move(move_id: String) -> bool:
	return Moves.is_wind_up_medical_move(move_id)


static func medical_outcome_string(target_method: String, ok: bool) -> String:
	return Moves.medical_outcome_string(target_method, ok)


static func line_discipline_allows_solo_fall_back(discipline: String) -> bool:
	return Formation.line_discipline_allows_solo_fall_back(discipline)


static func line_discipline_posture_extra_deltas(discipline: String) -> Vector2:
	return Formation.line_discipline_posture_extra_deltas(discipline)


static func normalize_spear_lane_profile(raw: Variant) -> String:
	return Formation.normalize_spear_lane_profile(raw)


static func ai_offense_stamina_weight_mult(stamina_ratio: float) -> float:
	return AIWeights.ai_offense_stamina_weight_mult(stamina_ratio)


static func iv7b_stamina_engage_doc_sync_line() -> String:
	return AIWeights.iv7b_stamina_engage_doc_sync_line()


static func default_depth_polearm_ai_doctrine_mults_dict() -> Dictionary:
	return DepthPolearm.default_depth_polearm_ai_doctrine_mults_dict()


static func depth_polearm_ai_doctrine_mults_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	return DepthPolearm.depth_polearm_ai_doctrine_mults_for_encounter_and_preset(encounter, preset, formation_id)


static func merge_depth_polearm_ai_doctrine_mults(base: Dictionary, overlay: Variant) -> Dictionary:
	return DepthPolearm.merge_depth_polearm_ai_doctrine_mults(base, overlay)


static func encounter_formation_doctrine_string(encounter: Dictionary, primary_key: String, alt_key: String) -> String:
	return Doctrine.encounter_formation_doctrine_string(encounter, primary_key, alt_key)


static func formation_doctrine_string_from_dict(source: Dictionary, primary_key: String, alt_key: String) -> String:
	return Doctrine.formation_doctrine_string_from_dict(source, primary_key, alt_key)


static func rout_thresholds_for_encounter_and_preset(
	encounter: Dictionary, preset: Dictionary, formation_id: String
) -> Dictionary:
	return Doctrine.rout_thresholds_for_encounter_and_preset(encounter, preset, formation_id)


static func guard_line_for_body_part(part: String) -> String:
	return GuardLinesHelpers.guard_line_for_body_part(part)


static func guard_zone_for_guard_line(line: String) -> String:
	return GuardLinesHelpers.guard_zone_for_guard_line(line)


static func position_angle_defender_offset_deg_for_line(line: String, scale: float) -> float:
	return FootworkPA.position_angle_defender_offset_deg_for_line(line, scale)


static func position_angle_offset_deg_for_attack_line(line: String) -> float:
	return FootworkPA.position_angle_offset_deg_for_attack_line(line)


static func _get_entity_access() -> GDScript:
	return load("res://combat/access/CombatantEntityAccess.gd") as GDScript


static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool, contact_type: String = "") -> bool:
	return Parry.parry_full_stop_reached(c_d, parry_p_a, is_block_parry, contact_type)


static func parry_edge_deflect_reached(c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool, contact_type: String = "", attack_line: String = "", guard_line: String = "", is_wide_arc: bool = false) -> bool:
	return Parry.parry_edge_deflect_reached(c_d, parry_p_a, alignment, is_block_parry, contact_type, attack_line, guard_line, is_wide_arc)


static func parry_bind_control_reached(parry_control: float) -> bool:
	return Parry.parry_bind_control_reached(parry_control)


static func iii3_baseline_constants_line() -> String:
	return Parry.iii3_baseline_constants_line()

static func p4d_parry_bind_doc_sync_line() -> String:
	return Parry.p4d_parry_bind_doc_sync_line()


static func classify_parry_timing(parried_at_windup_frac: float, proactive_threshold: float = Parry.PARRY_PROACTIVE_WINDOW_FRAC) -> String:
	return Parry.classify_parry_timing(parried_at_windup_frac, proactive_threshold)


static func parry_timing_capacity_mult(timing_class: String) -> float:
	return Parry.parry_timing_capacity_mult(timing_class)


static func parry_timing_control_bonus(timing_class: String) -> float:
	return Parry.parry_timing_control_bonus(timing_class)


static func parry_thrust_recovery_mult(intensity: float) -> float:
	return Parry.parry_thrust_recovery_mult(intensity)


static func parry_deflect_recovery_mult(intensity: float) -> float:
	return Parry.parry_deflect_recovery_mult(intensity)


static func off_balance_deflect_duration(intensity: float) -> float:
	return Parry.off_balance_deflect_duration(intensity)


static func formation_settle_off_balance_duration(move_kind: String) -> float:
	return Parry.formation_settle_off_balance_duration(move_kind)


static func cower_replant_off_balance_duration(leg_functionality: float) -> float:
	return Parry.cower_replant_off_balance_duration(leg_functionality)


static func facing_turn_window_s(angle: String) -> float:
	return Parry.facing_turn_window_s(angle)


static func close_advance_lead_leg_mult(leg: float) -> float:
	return Parry.close_advance_lead_leg_mult(leg)


static func hit_defender_off_balance_duration(intensity: float) -> float:
	return Parry.hit_defender_off_balance_duration(intensity)


static func hit_part_off_balance_mult(part: String) -> float:
	return Parry.hit_part_off_balance_mult(part)


static func hit_off_balance_outcome_mult(outcome: String) -> float:
	return Parry.hit_off_balance_outcome_mult(outcome)


static func hit_impulse_stagger_mult(ke_j: float) -> float:
	return Parry.hit_impulse_stagger_mult(ke_j)


static func hit_startle_min_s(part: String, outcome: String, ke_j: float) -> float:
	return Parry.hit_startle_min_s(part, outcome, ke_j)


static func hit_orientation_stagger_mult(angle: String) -> float:
	return Parry.hit_orientation_stagger_mult(angle)


static func hit_armor_inertia_mult(armor_ratio: float) -> float:
	return Parry.hit_armor_inertia_mult(armor_ratio)


static func whiff_armor_inertia_mult(armor_ratio: float) -> float:
	return Parry.whiff_armor_inertia_mult(armor_ratio)


static func off_balance_recovery_mult(leg: float, agi: float) -> float:
	return Parry.off_balance_recovery_mult(leg, agi)


## Leg-wound parry-brace: a compromised base weakens the platform that a parry braces into.
## 1.0 at full leg functionality → LEG_STANCE_PARRY_MULT_MIN at total leg loss. D001-neutral.
static func leg_stance_parry_mult(leg: float) -> float:
	return Parry.leg_stance_parry_mult(leg)


## Leg-wound off-balance susceptibility: a narrower support base tips more easily under an incoming
## impact (the threshold axis, distinct from re-rooting speed in off_balance_recovery_mult).
## 1.0 at full leg functionality → up to +HIT_OFF_BALANCE_LEG_SUSCEPTIBILITY_RANGE at total leg loss.
static func hit_off_balance_leg_susceptibility_mult(leg: float) -> float:
	return Parry.hit_off_balance_leg_susceptibility_mult(leg)


## Guard-transition off-balance multiplier: a staggered defender re-centers their blade more slowly.
## Multiplied onto the parry recovery guard-transition cost. D001-neutral at depth 0.
static func guard_transition_off_balance_mult(depth: float) -> float:
	return Parry.guard_transition_off_balance_mult(depth)


## Guard-transition fatigue multiplier: sustained muscle fatigue in the striking limb slows blade
## re-centering after a parry. Multiplied onto the parry recovery guard-transition cost alongside the
## off-balance term. D001-neutral at fatigue 0.
static func guard_transition_fatigue_mult(fatigue: float) -> float:
	return Parry.guard_transition_fatigue_mult(fatigue)


## Arm-wound wind-up slowdown: a compromised striking arm accelerates the blade more slowly.
## `grip` is the arm-wound function factor (1.0 healthy). Multiplier >= 1.0 extends wind-up. D001-neutral.
static func arm_wound_windup_slow_mult(grip: float) -> float:
	return Parry.arm_wound_windup_slow_mult(grip)


## Torso-wound parry-brace: a compromised core weakens the central brace a parry absorbs into.
## 1.0 at a healthy core → TORSO_STANCE_PARRY_MULT_MIN at full core loss. D001-neutral.
static func torso_stance_parry_mult(torso: float) -> float:
	return Parry.torso_stance_parry_mult(torso)


static func miss_off_balance_duration(intensity: float) -> float:
	return Parry.miss_off_balance_duration(intensity)


static func dodge_off_balance_duration(intensity: float) -> float:
	return Parry.dodge_off_balance_duration(intensity)


static func feint_commit_off_balance_extra_s() -> float:
	return Parry.FEINT_COMMIT_OFF_BALANCE_EXTRA_S


static func thrust_commit_off_balance_extra_s() -> float:
	return Parry.THRUST_COMMIT_OFF_BALANCE_EXTRA_S


static func parry_bonus_mult(parry_control: float) -> float:
	return Parry.parry_bonus_mult(parry_control)


static func parry_recoil_mass_scale(m_a: float, m_d: float) -> float:
	return Parry.parry_recoil_mass_scale(m_a, m_d)


static func parry_two_handed_recoil_mult(is_two_handed: bool) -> float:
	return Parry.parry_two_handed_recoil_mult(is_two_handed)


static func parry_two_handed_capacity_mult(is_two_handed: bool) -> float:
	return Parry.parry_two_handed_capacity_mult(is_two_handed)


static func parry_recoil_alignment_mult(alignment: float) -> float:
	return Parry.parry_recoil_alignment_mult(alignment)


static func parry_recoil_flex_mult(flex_factor: float) -> float:
	return Parry.parry_recoil_flex_mult(flex_factor)


static func parry_recoil_progress_mult(parry_progress: float) -> float:
	return Parry.parry_recoil_progress_mult(parry_progress)


static func parry_recoil_body_mass_scale(body_mass_kg: float) -> float:
	return Parry.parry_recoil_body_mass_scale(body_mass_kg)


static func consecutive_parry_stamina_mult(consecutive: int) -> float:
	return Stamina.consecutive_parry_stamina_mult(consecutive)


static func parry_thrust_commitment_penalty() -> float:
	return Parry.PARRY_THRUST_LINEAR_COMMITMENT_PENALTY



static func is_feature_combat_attention_enabled() -> bool:
	return FeatureFlags.is_feature_combat_attention_enabled()


static func set_feature_combat_attention_load(enabled: bool) -> void:
	FeatureFlags.set_feature_combat_attention_load(enabled)


static func is_feature_mental_stack_ai_enabled() -> bool:
	return FeatureFlags.is_feature_mental_stack_ai_enabled()


static func set_feature_mental_stack_ai_load(enabled: bool) -> void:
	FeatureFlags.set_feature_mental_stack_ai_load(enabled)


static func is_feature_ms_positional_awareness_enabled() -> bool:
	return FeatureFlags.is_feature_ms_positional_awareness_enabled()


static func set_feature_ms_positional_awareness_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_positional_awareness_load(enabled)


static func is_feature_ms_l6_rout_enabled() -> bool:
	return FeatureFlags.is_feature_ms_l6_rout_enabled()


static func set_feature_ms_l6_rout_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_l6_rout_load(enabled)


static func is_feature_ms_feint_resistance_enabled() -> bool:
	return FeatureFlags.is_feature_ms_feint_resistance_enabled()


static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_feint_resistance_load(enabled)


static func is_feature_ms_mid_infight_med_enabled() -> bool:
	return FeatureFlags.is_feature_ms_mid_infight_med_enabled()


static func set_feature_ms_mid_infight_med_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_mid_infight_med_load(enabled)


static func is_feature_ms_medical_escalation_enabled() -> bool:
	return FeatureFlags.is_feature_ms_medical_escalation_enabled()


static func set_feature_ms_medical_escalation_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_medical_escalation_load(enabled)


static func is_feature_ms_post_strike_enabled() -> bool:
	return FeatureFlags.is_feature_ms_post_strike_enabled()


static func set_feature_ms_post_strike_load(enabled: bool) -> void:
	FeatureFlags.set_feature_ms_post_strike_load(enabled)


static func is_feature_counter_tempo_enabled() -> bool:
	return FeatureFlags.is_feature_counter_tempo_enabled()


static func set_feature_counter_tempo_load(enabled: bool) -> void:
	FeatureFlags.set_feature_counter_tempo_load(enabled)


static func is_feature_flurry_bind_exchange_enabled() -> bool:
	return FeatureFlags.is_feature_flurry_bind_exchange_enabled()


static func set_feature_flurry_bind_exchange_load(enabled: bool) -> void:
	FeatureFlags.set_feature_flurry_bind_exchange_load(enabled)


static func is_feature_position_angle_footwork_enabled() -> bool:
	return FeatureFlags.is_feature_position_angle_footwork_enabled()


static func set_feature_position_angle_footwork_load(enabled: bool) -> void:
	FeatureFlags.set_feature_position_angle_footwork_load(enabled)


static func is_feature_armor_burden_enabled() -> bool:
	return FeatureFlags.is_feature_armor_burden_enabled()


static func set_feature_armor_burden_load(enabled: bool) -> void:
	FeatureFlags.set_feature_armor_burden_load(enabled)


static func armor_burden_mass_ratio_for_combatant(combatant: Dictionary) -> float:
	return FeatureFlags.armor_burden_mass_ratio_for_combatant(combatant)


static func armor_burden_action_ready_mult(combatant: Dictionary) -> float:
	return FeatureFlags.armor_burden_action_ready_mult(combatant)


static func armor_burden_passive_readiness_mult(combatant: Dictionary) -> float:
	return FeatureFlags.armor_burden_passive_readiness_mult(combatant)


static func is_feature_initiative_order_enabled() -> bool:
	return FeatureFlags.is_feature_initiative_order_enabled()


static func set_feature_initiative_order_load(enabled: bool) -> void:
	FeatureFlags.set_feature_initiative_order_load(enabled)


static func compare_combatants_for_initiative_order(a: Dictionary, b: Dictionary) -> bool:
	return FeatureFlags.compare_combatants_for_initiative_order(a, b)


static func is_feature_gap_column_topology_enabled() -> bool:
	return FeatureFlags.is_feature_gap_column_topology_enabled()


static func set_feature_gap_column_topology_load(enabled: bool) -> void:
	FeatureFlags.set_feature_gap_column_topology_load(enabled)


static func iv9_gap_column_doc_sync_line() -> String:
	return FeatureFlags.iv9_gap_column_doc_sync_line()


static func is_feature_subregion_combat_mult_enabled() -> bool:
	return FeatureFlags.is_feature_subregion_combat_mult_enabled()


static func set_feature_subregion_combat_mult_load(enabled: bool) -> void:
	FeatureFlags.set_feature_subregion_combat_mult_load(enabled)


static func is_feature_leader_formation_command_enabled() -> bool:
	return FeatureFlags.is_feature_leader_formation_command_enabled()


static func set_feature_leader_formation_command_load(enabled: bool) -> void:
	FeatureFlags.set_feature_leader_formation_command_load(enabled)


static func iv11_leader_formation_doc_sync_line() -> String:
	return FeatureFlags.iv11_leader_formation_doc_sync_line()


static func is_feature_iv12_slot_distraction_enabled() -> bool:
	return FeatureFlags.is_feature_iv12_slot_distraction_enabled()


static func set_feature_iv12_slot_distraction_load(enabled: bool) -> void:
	FeatureFlags.set_feature_iv12_slot_distraction_load(enabled)


static func iv12_slot_distraction_doc_sync_line() -> String:
	return FeatureFlags.iv12_slot_distraction_doc_sync_line()


static func is_feature_iv13_weapon_reach_zoc_enabled() -> bool:
	return FeatureFlags.is_feature_iv13_weapon_reach_zoc_enabled()


static func set_feature_iv13_weapon_reach_zoc_load(enabled: bool) -> void:
	FeatureFlags.set_feature_iv13_weapon_reach_zoc_load(enabled)


static func iv13_weapon_reach_zoc_doc_sync_line() -> String:
	return FeatureFlags.iv13_weapon_reach_zoc_doc_sync_line()


static func is_feature_t44_spatial_band_pa_enabled() -> bool:
	return FeatureFlags.is_feature_t44_spatial_band_pa_enabled()


static func set_feature_t44_spatial_band_pa_load(enabled: bool) -> void:
	FeatureFlags.set_feature_t44_spatial_band_pa_load(enabled)


static func t44_spatial_band_pa_magnitude_mult(band: String) -> float:
	return FeatureFlags.t44_spatial_band_pa_magnitude_mult(band)


static func is_feature_t44_spatial_file_dodge_bias_enabled() -> bool:
	return FeatureFlags.is_feature_t44_spatial_file_dodge_bias_enabled()


static func set_feature_t44_spatial_file_dodge_bias_load(enabled: bool) -> void:
	FeatureFlags.set_feature_t44_spatial_file_dodge_bias_load(enabled)


static func t44_spatial_file_dodge_wing_mult(file_index: int, formation_files: int) -> float:
	return FeatureFlags.t44_spatial_file_dodge_wing_mult(file_index, formation_files)


static func is_feature_t44_spatial_flurry_pa_enabled() -> bool:
	return FeatureFlags.is_feature_t44_spatial_flurry_pa_enabled()


static func set_feature_t44_spatial_flurry_pa_load(enabled: bool) -> void:
	FeatureFlags.set_feature_t44_spatial_flurry_pa_load(enabled)


static func t44_spatial_band_pa_doc_sync_line() -> String:
	return FeatureFlags.t44_spatial_band_pa_doc_sync_line()


static func t44_spatial_file_dodge_doc_sync_line() -> String:
	return FeatureFlags.t44_spatial_file_dodge_doc_sync_line()


static func t44_spatial_flurry_pa_doc_sync_line() -> String:
	return FeatureFlags.t44_spatial_flurry_pa_doc_sync_line()


static func is_feature_hema_eight_guard_lines_enabled() -> bool:
	return FeatureFlags.is_feature_hema_eight_guard_lines_enabled()


static func set_feature_hema_eight_guard_lines_load(enabled: bool) -> void:
	FeatureFlags.set_feature_hema_eight_guard_lines_load(enabled)


static func is_feature_arm_interpose_enabled() -> bool:
	return FeatureFlags.is_feature_arm_interpose_enabled()


static func set_feature_arm_interpose_load(enabled: bool) -> void:
	FeatureFlags.set_feature_arm_interpose_load(enabled)


static func is_feature_iv6_attack_path_octant_enabled() -> bool:
	return FeatureFlags.is_feature_iv6_attack_path_octant_enabled()


static func set_feature_iv6_attack_path_octant_load(enabled: bool) -> void:
	FeatureFlags.set_feature_iv6_attack_path_octant_load(enabled)


static func is_feature_sector_surround_load() -> bool:
	return FeatureFlags.is_feature_sector_surround_load()


static func set_feature_sector_surround_load(on: bool) -> void:
	FeatureFlags.set_feature_sector_surround_load(on)


static func is_feature_surround_arc_occupancy_enabled() -> bool:
	return FeatureFlags.is_feature_surround_arc_occupancy_enabled()


static func reset_harness_feature_load_overrides() -> void:
	FeatureFlags.reset_harness_feature_load_overrides()


static func _iv6_diagonal_attack_path(
	flank_path: Array, vert_path: Array, guard_oct: String, zone_part: String
) -> Array:
	return AttackPath._iv6_diagonal_attack_path(flank_path, vert_path, guard_oct, zone_part)


static func set_headless_harness_quiet(on: bool) -> void:
	Debug.set_headless_harness_quiet(on)


static func is_headless_harness_quiet() -> bool:
	return Debug.is_headless_harness_quiet()


static func set_play_session_diagnostic(on: bool) -> void:
	Debug.set_play_session_diagnostic(on)


static func play_session_diagnostic_active() -> bool:
	return Debug.play_session_diagnostic_active()


static func set_combat_hit_summary_override(on: bool) -> void:
	Debug.set_combat_hit_summary_override(on)


static func clear_combat_hit_summary_override() -> void:
	Debug.clear_combat_hit_summary_override()


static func combat_hit_summary_active() -> bool:
	return Debug.combat_hit_summary_active()


static func set_combat_dev_verbose_override(on: bool) -> void:
	Debug.set_combat_dev_verbose_override(on)


static func clear_combat_dev_verbose_override() -> void:
	Debug.clear_combat_dev_verbose_override()


static func combat_dev_verbose_active() -> bool:
	return Debug.combat_dev_verbose_active()


static func combat_debug_active() -> bool:
	return Debug.combat_debug_active()


static func combat_event_debug_active() -> bool:
	return Debug.combat_event_debug_active()


static func combat_event_debug_verbose_active() -> bool:
	return Debug.combat_event_debug_verbose_active()


static func stamina_factor(ratio: float) -> float:
	return Stamina.stamina_factor(ratio)


static func breath_factor(ratio: float) -> float:
	return Stamina.breath_factor(ratio)


static func stamina_attack_cost_from_intensity(intensity: float) -> float:
	return Stamina.stamina_attack_cost_from_intensity(intensity)


static func stamina_parry_cost_from_intensity(intensity: float) -> float:
	return Stamina.stamina_parry_cost_from_intensity(intensity)

static func partial_parry_stamina_mult(absorption: float) -> float:
	return Stamina.partial_parry_stamina_mult(absorption)

static func stamina_dodge_cost_from_intensity(intensity: float) -> float:
	return Stamina.stamina_dodge_cost_from_intensity(intensity)


static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
	return Stamina.action_ready_stamina_delay_mult(stamina_ratio)


static func is_feature_fight_exhaustion_enabled() -> bool:
	return FeatureFlags.is_feature_fight_exhaustion_enabled()


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
	FeatureFlags.set_feature_fight_exhaustion_index_load(on)


static func is_feature_arm_wound_degradation_enabled() -> bool:
	return FeatureFlags.is_feature_arm_wound_degradation_enabled()


static func set_feature_arm_wound_degradation_load(enabled: bool) -> void:
	FeatureFlags.set_feature_arm_wound_degradation_load(enabled)


static func is_feature_wounded_defender_caution_enabled() -> bool:
	return FeatureFlags.is_feature_wounded_defender_caution_enabled()


static func set_feature_wounded_defender_caution_load(enabled: bool) -> void:
	FeatureFlags.set_feature_wounded_defender_caution_load(enabled)


static func arm_wound_degradation_doc_sync_line() -> String:
	return FeatureFlags.arm_wound_degradation_doc_sync_line()


static func is_feature_parry_counterstrike_window_enabled() -> bool:
	return FeatureFlags.is_feature_parry_counterstrike_window_enabled()


static func set_feature_parry_counterstrike_window_load(enabled: bool) -> void:
	FeatureFlags.set_feature_parry_counterstrike_window_load(enabled)


static func is_feature_hit_continuation_window_enabled() -> bool:
	return FeatureFlags.is_feature_hit_continuation_window_enabled()


static func set_feature_hit_continuation_window_load(enabled: bool) -> void:
	FeatureFlags.set_feature_hit_continuation_window_load(enabled)


static func is_feature_measure_damage_commit_enabled() -> bool:
	return FeatureFlags.is_feature_measure_damage_commit_enabled()


static func set_feature_measure_damage_commit_load(enabled: bool) -> void:
	FeatureFlags.set_feature_measure_damage_commit_load(enabled)


static func is_feature_persistent_facing_enabled() -> bool:
	return FeatureFlags.is_feature_persistent_facing_enabled()


static func set_feature_persistent_facing_load(enabled: bool) -> void:
	FeatureFlags.set_feature_persistent_facing_load(enabled)


static func measure_damage_commit_doc_sync_line() -> String:
	return FeatureFlags.measure_damage_commit_doc_sync_line()


static func parry_counterstrike_doc_sync_line() -> String:
	return FeatureFlags.parry_counterstrike_doc_sync_line()


static func exhaustion_performance_mult(exhaustion: float) -> float:
	return Stamina.exhaustion_performance_mult(exhaustion)


static func exhaustion_timing_mult(exhaustion: float) -> float:
	return Stamina.exhaustion_timing_mult(exhaustion)


static func exhaustion_power_mult(exhaustion: float) -> float:
	return Stamina.exhaustion_power_mult(exhaustion)


static func defender_passive_readiness_exhaustion_mult(combatant: Dictionary) -> float:
	return Stamina.defender_passive_readiness_exhaustion_mult(combatant)


static func apply_parry_bind_riposte_gauge_bonus(defender: Dictionary) -> void:
	Stamina.apply_parry_bind_riposte_gauge_bonus(defender)


static func defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio: float) -> float:
	return Stamina.defender_passive_readiness_stamina_mult_from_ratio(stamina_ratio)


static func commitment_fraction_for_pending_attack(pa: Dictionary) -> float:
	return Parry.commitment_fraction_for_pending_attack(pa)


static func stats_factor_agi_perc(agi: float, perc: float) -> float:
	return Parry.stats_factor_agi_perc(agi, perc)


static func glancing_factor(ratio: float, exponent: float = Parry.PARRY_GLANCING_EXPONENT) -> float:
	return Parry.glancing_factor(ratio, exponent)


static func compute_parry_redirect_mult(
	pcfg: Dictionary, agi: float, perc: float, contact_type: String, is_block_parry: bool, m_a: float, m_d: float
) -> float:
	return Parry.compute_parry_redirect_mult(pcfg, agi, perc, contact_type, is_block_parry, m_a, m_d)


static func parry_deflect_margin_ratio(c_d_final: float, parry_p_a: float) -> float:
	return Parry.parry_deflect_margin_ratio(c_d_final, parry_p_a)


static func parry_deflect_severity_from_margin_ratio(margin_ratio: float) -> float:
	return Parry.parry_deflect_severity_from_margin_ratio(margin_ratio)


static func parry_control_for_bind_deflect(
	c_d_final: float,
	parry_p_a: float,
	alignment: float,
	parry_readiness: float,
	parry_off_balance: bool,
	late_parry: bool,
	contact_type: String,
	bind_friction_mult: float = 1.0
) -> float:
	return Parry.parry_control_for_bind_deflect(
		c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_type, bind_friction_mult
	)


static func bind_friction_mult_for_weapon(def_weapon: Variant) -> float:
	return Parry.bind_friction_mult_for_weapon(def_weapon)


static func parry_telegraph_contact_mult(contact_type: String) -> float:
	return ParryChoice.parry_telegraph_contact_mult(contact_type)


static func is_feature_ambient_pain_shock() -> bool:
	return FeatureFlags.is_feature_ambient_pain_shock()


static func set_feature_ambient_pain_shock(on: bool) -> void:
	FeatureFlags.set_feature_ambient_pain_shock(on)


static func is_formation_movement_move(move_id: String) -> bool:
	return FormationMove.is_formation_movement_move(move_id)


static func is_leader_formation_command_move(move_id: String) -> bool:
	return FormationMove.is_leader_formation_command_move(move_id)


static func is_formation_reposition_move(move_id: String) -> bool:
	return FormationMove.is_formation_reposition_move(move_id)


static func is_partner_formation_move(move_id: String) -> bool:
	return FormationMove.is_partner_formation_move(move_id)


static func is_plug_forward_move(move_id: String) -> bool:
	return FormationMove.is_plug_forward_move(move_id)


static func is_formation_pair_move_kind(move_kind: String) -> bool:
	return FormationMove.is_formation_pair_move_kind(move_kind)


static func formation_pair_move_kind_for_menu_move(move_id: String) -> String:
	return FormationMove.formation_pair_move_kind_for_menu_move(move_id)


static func is_joule_armor_budget_active() -> bool:
	return FeatureFlags.FEATURE_JOULE_ARMOR_BUDGET


static func normalize_recovery_cause(cause: String) -> String:
	return Footwork.normalize_recovery_cause(cause)


static func readiness_curve_for_cause(cause: String) -> Array:
	return Footwork.readiness_curve_for_cause(cause)


static func defense_footwork_recovering_dodge_mult_for_cause(cause: String) -> float:
	return Footwork.defense_footwork_recovering_dodge_mult_for_cause(cause)


static func ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause: String) -> float:
	return Footwork.ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause)


static func passive_parry_readiness_incoming_contact_mult(contact_type: String) -> float:
	return Footwork.passive_parry_readiness_incoming_contact_mult(contact_type)


static func defender_distance_band_to_attacker_id(defender: Dictionary, attacker_id: int) -> String:
	return Footwork.defender_distance_band_to_attacker_id(defender, attacker_id)


static func ai_feint_listing_defender_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	return Footwork.ai_feint_listing_defender_readiness_spacing_mult(defender, attacker_id)


static func feint_guard_zone_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
	return Footwork.feint_guard_zone_readiness_spacing_mult(defender, attacker_id)


static func max_close_slots_for_density(density: String) -> int:
	return CloseSlots.max_close_slots_for_density(density)


static func get_stance_modifier(stance: String, effect: String) -> float:
	return Stance.get_stance_modifier(stance, effect)


static func get_density_close_mod(density: String) -> float:
	return Stance.get_density_close_mod(density)


static func get_spacing_from_density(density: String) -> float:
	return Stance.get_spacing_from_density(density)


static func get_attack_path(attack_line: String, guard_line: String) -> Array:
	return AttackPath.get_attack_path(attack_line, guard_line)


static func get_arc_angle_at_progress(arc_start_deg: float, arc_end_deg: float, progress: float) -> float:
	return AttackPath.get_arc_angle_at_progress(arc_start_deg, arc_end_deg, progress)


static func arc_end_deg_for_contact_geometry(pa: Dictionary) -> float:
	return AttackPath.arc_end_deg_for_contact_geometry(pa)


static func get_attack_angle_at_progress(pa: Dictionary, progress: float) -> float:
	return AttackPath.get_attack_angle_at_progress(pa, progress)


static func angle_diff_deg(a_deg: float, b_deg: float) -> float:
	return AttackPath.angle_diff_deg(a_deg, b_deg)


static func line_to_angle(line: String) -> float:
	return AttackPath.line_to_angle(line)


static func angle_to_nearest_line(angle_deg: float) -> String:
	return AttackPath.angle_to_nearest_line(angle_deg)


static func get_alignment_from_angles(attack_angle_deg: float, guard_angle_deg: float) -> float:
	return AttackPath.get_alignment_from_angles(attack_angle_deg, guard_angle_deg)


static func get_deflected_angle_bilateral(
	attack_angle_deg: float, guard_angle_deg: float, magnitude_deg: float
) -> float:
	return AttackPath.get_deflected_angle_bilateral(attack_angle_deg, guard_angle_deg, magnitude_deg)


static func get_deflection_magnitude_deg(alignment: float, severity: float, contact_type: String) -> float:
	return AttackPath.get_deflection_magnitude_deg(alignment, severity, contact_type)


static func get_line_alignment(attack_line: String, guard_line: String) -> float:
	return AttackPath.get_line_alignment(attack_line, guard_line)


static func get_attack_angle_deg(
	attack_line: String, add_variance: bool = true, move_def: Dictionary = {}, variance_context: Dictionary = {}
) -> float:
	return AttackPath.get_attack_angle_deg(attack_line, add_variance, move_def, variance_context)


static func get_guard_angle_deg(combatant: Dictionary, wobble_context: Dictionary = {}) -> float:
	return AttackPath.get_guard_angle_deg(combatant, wobble_context)


static func get_deflected_line_from_angles(
	attack_angle_deg: float, guard_angle_deg: float, severity: float, contact_type: String, alignment: float
) -> String:
	return AttackPath.get_deflected_line_from_angles(
		attack_angle_deg, guard_angle_deg, severity, contact_type, alignment
	)


static func get_line_alignment_with_deflect(
	attack_line: String, combatant: Dictionary, alignment_context: Dictionary = {}, wobble_context: Dictionary = {}
) -> float:
	return AttackPath.get_line_alignment_with_deflect(attack_line, combatant, alignment_context, wobble_context)


static func flex_factor_for_slenderness(slenderness: float) -> float:
	return AttackPath.flex_factor_for_slenderness(slenderness)


static func clamp_prob(v: float) -> float:
	return Misc.clamp_prob(v)


static func companion_path(index: int) -> String:
	return Misc.companion_path(index)
