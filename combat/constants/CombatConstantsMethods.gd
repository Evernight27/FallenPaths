class_name CombatConstantsMethods
extends RefCounted

## Static method forwards for CombatConstants (consts live on CombatConstants.gd).

const AfterblowConstants := preload("res://combat/constants/CombatAfterblowConstants.gd")
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
const _CounterTempo := preload("res://combat/constants/CombatConstantsCounterTempo.gd")
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


static func parry_full_stop_reached(c_d: float, parry_p_a: float, is_block_parry: bool) -> bool:
	return Parry.parry_full_stop_reached(c_d, parry_p_a, is_block_parry)


static func parry_edge_deflect_reached(c_d: float, parry_p_a: float, alignment: float, is_block_parry: bool) -> bool:
	return Parry.parry_edge_deflect_reached(c_d, parry_p_a, alignment, is_block_parry)


static func parry_bind_control_reached(parry_control: float) -> bool:
	return Parry.parry_bind_control_reached(parry_control)


static func iii3_baseline_constants_line() -> String:
	return Parry.iii3_baseline_constants_line()


static func p4d_parry_bind_doc_sync_line() -> String:
	return Parry.p4d_parry_bind_doc_sync_line()


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


static func action_ready_stamina_delay_mult(stamina_ratio: float) -> float:
	return Stamina.action_ready_stamina_delay_mult(stamina_ratio)


static func is_feature_fight_exhaustion_enabled() -> bool:
	return FeatureFlags.is_feature_fight_exhaustion_enabled()


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
	FeatureFlags.set_feature_fight_exhaustion_index_load(on)


static func exhaustion_performance_mult(exhaustion: float) -> float:
	return Stamina.exhaustion_performance_mult(exhaustion)


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
	contact_type: String
) -> float:
	return Parry.parry_control_for_bind_deflect(
		c_d_final, parry_p_a, alignment, parry_readiness, parry_off_balance, late_parry, contact_type
	)


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


static func clamp_prob(v: float) -> float:
	return Misc.clamp_prob(v)


static func companion_path(index: int) -> String:
	return Misc.companion_path(index)
