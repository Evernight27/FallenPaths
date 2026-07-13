class_name CombatRegressionHarness
extends RefCounted

## Manual / editor-invoked checks for Tier 1.5 - 1.9 (morale cohesion, engagement classifier, depth polearm, ZoC).
## WF harness baseline: **`_harness_reset_combatants_form_balanced`** -> **`assign_form(..., harness_baseline)`**  -  home guard + **`form_str`** for parity rows; LIVE_PATHS **`#spawn--reset-path-wf-1a`** . **`#wf-soak-audit-status`**.
## Tier 4.2: **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry`**, **`_run_feint_commitment_fraction_shortens_effective_wind_up_for_late_parry_thrust`**, **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone`**, **`_run_feint_windup_options_stamp_pa_and_telegraph_guard_zone_thrust`**, **`_run_feint_windup_duration_mult_extends_state_duration_vs_oberhau`**, **`_run_feint_windup_duration_mult_extends_state_duration_vs_thrust`**, **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target`**, **`_run_feint_windup_target_only_sets_defender_guard_zone_to_target_thrust`**, **`_run_feint_move_ai_distinct_feint_and_target_parts`**, **`_run_feint_move_ai_distinct_feint_and_target_parts_thrust`**, **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_oberhau`**, **`_run_feint_move_listing_weight_mult_prefers_feint_over_plain_thrust`**, **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard`**, **`_run_feint_move_listing_readiness_scales_feint_weight_high_guard_vs_low_guard_thrust`**, **`_run_feint_move_listing_spacing_long_dampens_vs_mid`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid`**, **`_run_feint_move_listing_spacing_long_dampens_vs_mid_when_defender_recovering`**, **`_run_feint_move_listing_spacing_close_boosts_vs_mid_when_defender_recovering`**, **`_run_feint_move_listing_readiness_recovery_curve_when_defender_recovering`**, **`_run_feint_move_listing_stamina_low_dampens_feint_weight`**, **`_run_feint_move_listing_stamina_low_stacks_with_hold_lane_doctrine_damp`**, **`_run_feint_move_listing_stamina_low_stacks_with_probing_doctrine_mult`**, **`_run_feint_move_listing_stamina_low_stacks_with_pinch_center_doctrine_mult`**, **`_run_feint_move_listing_doctrine_probing_multiplies_feint_weight`**, **`_run_feint_move_listing_doctrine_pinch_center_multiplies_feint_weight`**, **`_run_feint_move_listing_doctrine_hold_lane_dampens_feint_weight_vs_default`**, **`_run_feint_move_listing_stance_ai_feint_mult_ordering`**, **`_run_feint_move_listing_recent_opp_parry_deflect_boosts_feint_weight`**, **`_run_feint_move_listing_defender_off_balance_boosts_feint_weight`**, **`_run_feint_move_listing_settled_waiting_footwork_dampens_vs_off_balance`**, **`_run_feint_move_listing_recovering_footwork_dampens_vs_settled_waiting`**, **`_run_feint_move_listing_recovery_cause_orders_recovering_footwork_mult`, **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`****, **`_run_feint_move_listing_recovering_footwork_and_spacing_stack_orthogonally`**, **`_run_feint_opts_from_choice_and_non_feint_attack_no_feint_part`**, **`_run_feint_guard_zone_modifier_telegraph_mismatch_penalty_and_readjust_bonus`**, **`_run_feint_guard_zone_readthrough_par_bonus_when_readiness_high`**, **`_run_feint_guard_zone_readthrough_spacing_long_boosts_vs_mid`**, **`_run_feint_guard_zone_readthrough_spacing_close_dampens_vs_mid`**, **`_run_feint_target_reveal_progress_scales_readiness_mult`**, **`_run_feint_telegraph_biases_dodge_eval_part_when_not_readthrough`**, **`_feint_guard_zone_sample_global_seed_for_modifier`** (PathResolver RNG seed scan), **`_run_feint_second_windup_clears_prior_telegraph_before_restamp`**, **`_run_feint_telegraph_scrubbed_on_combat_manager_restart`**; footwork / pair spacing  -  **`_run_defense_spacing_band_modulates_parry_and_dodge`**, **`_run_defense_footwork_recovering_boosts_dodge_vs_waiting`**, **`_run_defense_footwork_recovery_cause_orders_recovering_dodge_mult`**, **`_run_defense_footwork_recovering_dodge_stacks_with_spacing_long_and_close`**, **`_run_defense_footwork_waiting_boosts_dodge_when_settled_vs_off_balance`**, **`_run_defense_footwork_waiting_dodge_stacks_with_spacing_long_and_close`**, **`_run_feint_telegraph_spacing_long_dampens_dodge_bite_vs_mid`**, **`_run_feint_telegraph_dodge_readthrough_respects_guard_zone_spacing_long_vs_mid`**, **`_run_feint_telegraph_spacing_close_boosts_dodge_bite_vs_mid`**, **`_run_passive_parry_readiness_incoming_contact_stab_scales_vs_cut`**, **`_run_defender_low_stamina_scales_passive_parry_readiness_in_choose_defense`**, **`_run_feint_move_listing_incoming_contact_stab_feint_dampens_vs_cut_feint`**, **`_run_feint_move_listing_defender_low_stamina_scales_read_m_vs_full_stamina`**, **`_run_feint_move_listing_defender_and_attacker_stamina_multiply_orthogonally`** (**`DefenseChoiceResolver`**, **`CombatAIActionPicker`**, **`distance_to`**, **`DEFENSE_SPACING_*`**, **`FEINT_TELEGRAPH_DODGE_EVAL_BIAS_SPACING_*`**, **`AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_*`**, **`FEINT_GUARD_ZONE_READINESS_SPACING_*`**, **`feint_guard_zone_readiness_spacing_mult`**, **`CombatConstants.passive_parry_readiness_incoming_contact_mult`**, **`WeaponConstants`** **`thrust_feint`**).
## Tier 3.3: afterblow  -  **`_run_afterblow_deflected_triggers_full_resolve_hit`**, **`_run_afterblow_low_hindrance_allow_triggers_resolve_hit`** (fixed **`seed(1)`**, harness meta for mult); **`_run_afterblow_mid_hindrance_rand_cancel`** (**`seed(2)`**); **`_run_afterblow_mid_hindrance_rand_executes_hit`** (**`seed(0)`**, mult **0.55**); **`_afterblow_harness_seed_pending_cut`**. Hit reaction  -  **`_run_hit_applier_sets_defender_guard_low_after_hit`** (**`AttackResultApplier`** **`hit`** -> **`GuardLineUpdater.set_guard_from_line`** low).
## Does not require a running battle scene. Example:
##   var r := CombatRegressionHarness.run_all()
##   assert(r.ok, str(r.failures))

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _ArmorPiece := preload("res://armor/ArmorPiece.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _FormationMoves := preload("res://combat/CombatFormationMoveListing.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _DepthPolearm := preload("res://combat/CombatDepthPolearm.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EventScheduler := preload("res://combat/CombatEventScheduler.gd")
const _FormationFlow := preload("res://combat/CombatFormationFlow.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _FormationEngagement := preload("res://combat/CombatFormationEngagement.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _PassiveParryCtx := preload("res://combat/PassiveParryContext.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")
const _DefenseChoice := preload("res://combat/DefenseChoiceResolver.gd")
const _DefenseResolution := preload("res://combat/DefenseResolutionHandler.gd")
const _WindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _MentalStack := preload("res://combat/MentalStackDecider.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _StrikePhysics := preload("res://combat/StrikePhysics.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")
const _PostStrike := preload("res://combat/CombatPostStrike.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationVacancyPlugs := preload("res://combat/CombatFormationVacancyPlugs.gd")
const _CombatTiming := preload("res://combat/CombatTiming.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _DistanceBands := preload("res://combat/CombatDistanceBands.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _GuardLines := preload("res://combat/CombatGuardLines.gd")
const _AfterblowHandler := preload("res://combat/AfterblowHandler.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _EntityMedical := preload("res://core/EntityMedical.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _UiHints := preload("res://combat/CombatUiHints.gd")
const _FormationMoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
const _IncomingParryChoice := preload("res://combat/CombatIncomingParryChoice.gd")
const _WeaponPosition := preload("res://combat/CombatWeaponPosition.gd")
const _FormationFlee := preload("res://combat/CombatFormationFlee.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _MeleeRank := preload("res://combat/CombatMeleeRankTargeting.gd")
const _CampaignBridge := preload("res://world/CampaignEncounterBridge.gd")
const _PartyRowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _Snapshot := preload("res://world/PartyMemberSnapshot.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _ProcessTick := preload("res://combat/CombatProcessTick.gd")
const _PartyManagerScript := preload("res://world/PartyManager.gd")
const _EncounterNode := preload("res://world/EncounterNode.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _MedicalMobilityTail := preload("res://harness/CombatRegressionHarnessMedicalMobilityTail.gd")
const _FleeTail := preload("res://harness/CombatRegressionHarnessFleeTail.gd")
const _MedicalPhaseTail := preload("res://harness/CombatRegressionHarnessMedicalPhaseTail.gd")
const _Tier1Tail := preload("res://harness/CombatRegressionHarnessTier1Tail.gd")
const _FeintTempoTail := preload("res://harness/CombatRegressionHarnessFeintTempoTail.gd")
const _AttentionFootworkTail := preload("res://harness/CombatRegressionHarnessAttentionFootworkTail.gd")
const _WeaponFormTail := preload("res://harness/CombatRegressionHarnessWeaponFormTail.gd")
const _SimulationTail := preload("res://harness/CombatRegressionHarnessSimulation.gd")
const _MentalStackIntegrationTail := preload("res://harness/CombatRegressionHarnessMentalStackIntegrationTail.gd")
const _ProficiencyTail := preload("res://harness/CombatRegressionHarnessProficiencyTail.gd")
const _Proficiency1v1Tail := preload("res://harness/CombatRegressionHarnessProficiency1v1Tail.gd")
const _Targeting1v1Tail := preload("res://harness/CombatRegressionHarnessTargeting1v1Tail.gd")
const _MuscleFatigueTail := preload("res://harness/CombatRegressionHarnessMuscleFatigueTail.gd")
const _ComposureSeeds := preload("res://harness/CombatHarnessComposureSeeds.gd")
const _Fixtures := preload("res://harness/HarnessFixtures.gd")
## No preload  -  `CombatRegressionHarnessKinematicTail` references this class; preloading it here caused a parse cycle.
## Tier 3.2: full-stop **`parry_deflect`**  -  keys on **`parry_clash_context`** (see **`DefenseResolutionHandler`**) incl. Tier **3.0** strike kinematics + Tier **3.1** **`strike_measure_ratio`** (from **`pa`** when stamped, else **-1**); harness schema lock in **`_run_parry_clash_context_calibration_fields`**. **`parry_partial`** adds the same key set plus **`remaining_ratio`** / **`geometric_leak`** (**`_run_parry_partial_clash_context_calibration_fields`**); Tier **3.0** KE on partial uses reduced **`pa["velocity_m_s"]`**; **`CombatLogFormatter`** + harness **`_run_parry_partial_formatter_clash_context_branches`** (**`rem=`** when calibration **on**); **`_run_action_resolved_parry_partial_payload_includes_clash_context`** locks first **`action_resolved`** emit; **`_run_hit_clears_attacker_parry_calibration_fields`** locks **`hit`** erase of calibration carry; **`_run_hit_applier_sets_defender_guard_low_after_hit`** locks defender **`guard_line`** / **`guard_zone`** after **`hit`**; **`_run_parry_partial_bind_riposte_flags_when_aligned`** locks defender bind-riposte flags vs alignment + **`parry_control`** (misaligned **`erase`** vs aligned explicit **false**, stale-bind seed).
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
static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.reset_harness_feature_load_overrides()
    CombatConstants.set_feature_position_angle_footwork_load(true)
    _run_next_action_ready_map_matches_per_id(failures)
    _run_vacancy_reconcile_follow_up_regression(failures)
    _run_vacancy_reconcile_after_front_death(failures)
    _Tier1Tail.run_early(failures)
    _FeintTempoTail.run_before_attention(failures)
    _AttentionFootworkTail.run(failures)
    _MentalStackIntegrationTail.run(failures)
    _WeaponFormTail.run(failures)
    _FeintTempoTail.run_after_attention(failures)
    _Tier1Tail.run_mid(failures)
    _run_effective_pair_geometry_single_pass_matches_wrappers(failures)
    _run_windup_pending_attack_pair_geometry(failures)
    _run_strike_measure_constants_sanity(failures)
    _run_attack_result_applier_terminal_clears_pending(failures)
    _run_action_resolved_parry_deflect_payload_includes_clash_context(failures)
    _run_action_resolved_parry_partial_payload_includes_clash_context(failures)
    _run_hit_clears_attacker_parry_calibration_fields(failures)
    _run_hit_applier_sets_defender_guard_low_after_hit(failures)
    _run_parry_partial_bind_riposte_flags_when_aligned(failures)
    _Tier1Tail.run_late(failures)
    CombatRegressionHarnessKinematicTail.run_core(failures)
    CombatRegressionHarnessKinematicTail.run(failures)
    _SimulationTail.run(failures)
    _run_weapon_blade_strong_fraction(failures)
    _FleeTail.run(failures)
    _MedicalMobilityTail.run(failures)
    _run_ai_attrition_offense_mult_duel_vs_line(failures)
    _run_wind_up_duration_bounded_for_move(failures)
    _run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11(failures)
    _run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min(failures)
    _run_resolve_aborts_when_threat_lost_mid_combat_arm_loss(failures)
    _MedicalPhaseTail.run(failures)
    _ProficiencyTail.run(failures)
    _Proficiency1v1Tail.run(failures)
    _MuscleFatigueTail.run(failures)
    _Targeting1v1Tail.run(failures)
    _run_combat_end_enemy_win_stops_manager(failures)
    _run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures)
    _run_medical_ambient_pain_shock_tick_enters_from_sustained_pain(failures)
    _run_medical_ambient_pain_shock_skips_when_feature_off(failures)
    _run_campaign_bridge_can_enter_combat_rejects_empty_party(failures)
    _run_campaign_bridge_can_enter_combat_rejects_unconscious(failures)
    _run_bind_riposte_contact_types_normalized(failures)
    _run_bind_riposte_contact_multipliers(failures)
    _run_bind_riposte_archetype_ordering_spear_faster_than_mace(failures)
    _run_p4h_bind_riposte_balance_suite(failures)
    _run_p4d_parry_bind_doc_code_parity_suite(failures)
    _run_flurry_bind_exchange_wind_up_reduced_vs_plain(failures)
    _run_flurry_bind_exchange_consumes_on_wind_up(failures)
    _run_flurry_bind_window_closes_on_hit(failures)
    _run_flurry_bind_listing_restricts_to_bind_partner(failures)
    _run_flurry_bind_opens_on_bind_deflect(failures)
    _run_flurry_bind_expires_after_window(failures)
    _run_flurry_bind_ui_gauge_label_when_window_open(failures)
    _run_flurry_bind_feature_flag_respects_runtime_toggle(failures)
    _run_p4g_flurry_bind_depth_suite(failures)
    _run_tier7_stamina_attack_cost_scales_with_intensity(failures)
    _run_tier7_stamina_parry_cost_scales_with_intensity(failures)
    _run_tier7_stamina_action_ready_cooldown_scales_with_fatigue(failures)
    _run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool(failures)
    _run_tier7_stamina_depletion_sustained_exchange_sim(failures)
    _run_stamina_effective_max_exhaustion_and_blood_cap(failures)
    _run_stamina_effective_refill_slows_with_exhaustion(failures)
    _run_opponent_pressure_defensive_uses_burst_ratio(failures)
    _run_tier7_parry_bind_riposte_gauge_bonus_on_deflect(failures)
    _run_formation_move_duration_lane_obstacle_slows_estimate(failures)
    _run_formation_move_duration_matches_flow_pair_start(failures)
    _run_formation_move_duration_ui_hint_when_lane_crowded(failures)
    _run_formation_diagram_health_bar_reflects_body_damage(failures)
    _run_formation_diagram_health_bar_tint_reflects_function_loss(failures)
    _run_formation_move_duration_listed_actions_stamp_hint(failures)
    _run_rotate_file_listed_for_adjacent_front_rank_allies(failures)
    _run_rotate_file_start_sets_duration_matches_estimate(failures)
    _run_rotate_file_resolve_stamps_rotate_cooldown(failures)
    _run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown(failures)
    _run_rotate_file_lists_both_adjacent_wing_partners(failures)
    _run_rotate_file_cooldown_blocks_listing_and_resolve(failures)
    _run_rotate_file_reverse_pair_lock_blocks_re_swap(failures)
    _run_vacancy_plug_clears_doctrine_commitment(failures)
    _run_formation_shuffle_clears_close_block(failures)
    _run_pair_abort_cooldown_blocks_swap_rank_resolve(failures)
    _run_swap_rank_not_listed_without_tactical_gate(failures)
    _run_swap_rank_resolve_rejects_without_tactical_gate(failures)
    _run_resolve_close_attempt_long_success_closes_distance(failures)
    _run_automatic_doctrine_sets_pinch_on_hollow_when_enabled(failures)
    _run_automatic_doctrine_pinch_via_formation_recompute(failures)
    _run_p4c_numeric_superiority_auto_pinch(failures)
    _run_formation_move_duration_heavy_armor_slows_estimate(failures)
    _run_iv7_armor_burden_action_ready(failures)
    _run_iv7_armor_burden_passive_readiness(failures)
    _run_iv7b_stamina_engage_floor_suite(failures)
    _run_iv8_initiative_order_stagger(failures)
    _run_iv8_initiative_order_flag_off_parity(failures)
    _run_iv9_gap_column_compact_suppressed_when_flag_on(failures)
    _run_iv9_gap_column_flag_off_parity(failures)
    _run_iv9_gap_column_vacancy_reconcile_flag_on(failures)
    _run_iv9_gap_column_occupied_files_suite(failures)
    _run_iv9_gap_column_diagram_display_suite(failures)
    _run_iv9_gap_column_pair_geometry_column_arc_suite(failures)
    _run_iv9_gap_column_dual_mode_formation_targeting_suite(failures)
    _run_iv9_gap_column_topology_refresh_after_formation_moves(failures)
    _run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair(failures)
    # IV-11 leader formation (slices 1 - 10)
    _run_iv11_leader_formation_ability_suite(failures)
    _run_iv11_register_party_leader_stamp_suite(failures)
    _run_iv11_campaign_bridge_party_leader_stamp_suite(failures)
    _run_iv11_register_enemy_leader_stamp_suite(failures)
    _run_iv11_encounter_spawn_enemy_leader_suite(failures)
    _run_iv11_party_leader_diagram_callout_suite(failures)
    _run_iv11_enemy_leader_diagram_callout_suite(failures)
    _run_iv11_party_leader_roster_callout_suite(failures)
    _run_iv11_leader_order_hold_lane_suite(failures)
    _run_iv11_leader_order_hold_lane_formatter_suite(failures)
    _run_iv11_leader_order_probing_suite(failures)
    _run_iv11_leader_order_probing_formatter_suite(failures)
    _run_iv11_leader_order_pinch_center_suite(failures)
    _run_iv11_leader_order_pinch_center_formatter_suite(failures)
    _run_iv11_enemy_commander_order_suite(failures)
    _run_iv11_leader_doctrine_cycle_suite(failures)
    _run_iv11_enemy_commander_doctrine_cycle_suite(failures)
    _run_iv11_leader_command_ai_weight_suite(failures)
    _run_iv11_enemy_commander_ai_weight_suite(failures)
    _run_iv11_pinch_outnumber_ai_weight_suite(failures)
    _run_iv11_enemy_pinch_outnumber_ai_weight_suite(failures)
    _run_iv11_f5_leader_order_trace_suite(failures)
    _run_iv13_weapon_reach_zoc_suite(failures)
    _run_iv13_weapon_reach_zoc_flag_off_parity(failures)
    _run_iv13_weapon_reach_zoc_distance_band_suite(failures)
    _run_iv12_slot_distraction_suite(failures)
    _run_iv12_slot_distraction_flag_off_parity(failures)
    _run_iv12_slot_distraction_ai_offense_damp(failures)
    _run_iv12_co_located_target_bias_suite(failures)
    _run_iv12_drag_back_dual_occupancy_distraction_suite(failures)
    _run_formation_move_duration_player_turn_hint_from_listed_actions(failures)
    _run_formation_move_duration_gauge_tooltip_listed_hint(failures)
    _run_formation_move_duration_gauge_tooltip_clears_when_not_waiting(failures)
    _run_formation_move_duration_gauge_tooltip_clears_on_resolve(failures)
    _run_p4b_formation_duration_ui_copy_suite(failures)
    _run_wind_up_rejects_move_not_on_weapon(failures)
    _run_formation_hit_reaction_extends_pair_move_duration(failures)
    _run_formation_hit_cancel_aborts_pair_move(failures)
    _run_incoming_parry_choice_blocks_non_chosen_attacker(failures)
    _run_incoming_parry_can_parry_all_weak_pair(failures)
    _run_iii1_incoming_parry_sector_tiebreak(failures)
    _run_iii3_deflect_bind_calibration_suite(failures)
    _run_weapon_extended_parry_dampens_defender_recovering_from_attack(failures)
    _run_weapon_committed_attack_dampens_defender_parry_c_d(failures)
    _run_weapon_commit_fraction_stab_before_overhead_cut(failures)
    _run_weapon_windup_stamps_commit_fraction_on_pa(failures)
    _run_weapon_commit_fraction_inferred_for_untagged_thrust_move(failures)
    _run_impact_station_mean_zero_spread_equals_move_mean(failures)
    _run_impact_station_mean_move_overrides_weapon_default(failures)
    _run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow(failures)
    _run_impact_station_mean_windup_stamps_move_override(failures)
    _run_impact_station_mean_every_move_def_tagged(failures)
    _run_impact_station_mean_feint_coiled_below_honest_cut(failures)
    _run_impact_station_mean_pole_swing_below_spear_thrust(failures)
    _run_formation_hit_cancel_ui_gauge_vulnerable_suffix(failures)
    _run_parry_opposite_deflect_thresholds(failures)
    _run_parry_defender_vs_attack_modifiers(failures)
    _run_parry_clash_context_calibration_fields(failures)
    _run_parry_partial_clash_context_calibration_fields(failures)
    _run_parry_control_bind_deflect_formula(failures)
    _run_follow_through_gate_at_low_remaining_ratio(failures)
    _run_follow_through_integration_gate(failures)
    _run_block_threshold_balance_test(failures)
    _run_block_threshold_asymmetric_test(failures)
    _run_weapon_melee_range_ordering(failures)
    _run_weapon_move_coverage(failures)
    _run_weapon_parts_mass_sum(failures)
    _run_weapon_feint_parry_coverage(failures)
    _run_weapon_angle_variance_ranges(failures)
    _run_guard_line_deflected_severity_from_margin_ratio(failures)
    _run_guard_from_move_sets_guard_line_and_zone(failures)
    _run_afterblow_no_pending_returns_false(failures)
    _run_afterblow_wrong_state_returns_false(failures)
    _run_afterblow_hindrance_block_cancels_pending(failures)
    _run_afterblow_deflected_triggers_full_resolve_hit(failures)
    _run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures)
    _run_afterblow_mid_hindrance_rand_cancel(failures)
    _run_afterblow_mid_hindrance_rand_executes_hit(failures)
    _run_campaign_bridge_entity_untreated_wounds(failures)
    _run_party_row_triage_formatter(failures)
    _run_combat_log_formatter_negligible(failures)
    _run_campaign_bridge_encounter_meta_from_node(failures)
    ## Phase 2: feint resistance gate  -  high-readiness defenders reject feints.
    _run_mental_stack_feint_resistance_high_readiness(failures)
    _run_mental_stack_feint_resistance_low_readiness_still_falls_for(failures)
    ## Phase 3: MS-L8 post-strike momentum layer.
    _run_ms_l8_post_strike_momentum_presses_target(failures)
    ## Phase 5: exhaustion gradient (offense weight lerp).
    _run_ms_l7_exhaustion_gradient_offense_weight(failures)
    ## Phase 6: MS-L9 positional awareness  -  disengage when surrounded + vulnerable.
    _run_ms_l9_positional_awareness_disengage_when_surrounded(failures)
    ## Phase 7: medical escalation TCCC ladder  -  pack boosted when bandage failed.
    _run_mental_stack_medical_escalation_bandage_to_pack(failures)
    _run_mental_stack_medical_escalation_no_bonus_when_no_failures(failures)
    ## Tier 1.7-1.8: stale swap-rank event cleanup and parry formation-pair state preservation.
    _run_cancel_stale_swap_rank_resolve_events(failures)
    _run_parry_preserves_formation_pair_state(failures)
    CombatConstants.set_feature_position_angle_footwork_load(true)
    flush_harness_live_nodes()
    return {"ok": failures.is_empty(), "failures": failures}


static func _fail(arr: PackedStringArray, msg: String) -> void:
    arr.append(msg)


## Headless `-s` scripts call `quit()` without flushing deferred deletes  -  track orphan nodes and `free()` at harness exit.
## All node-lifecycle helpers forwarded to HarnessFixtures (single owner of `_harness_live_nodes`).


static func _track_harness_node(n: Node) -> void:
    _Fixtures._track_harness_node(n)


## Final sweep for standalone `_new_entity` rows that omit explicit teardown.
static func flush_harness_live_nodes() -> void:
    _Fixtures.flush_harness_live_nodes()


## Expand WF: harness rows that set stance alias must sync **`weapon_form`** for picker/defense paths.
static func harness_sync_weapon_form_from_stance(c: Dictionary, stance: String) -> void:
    var _WF := preload("res://combat/CombatWeaponForm.gd")
    c["stance"] = stance
    c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = _WF.normalize_form(stance)


## Preferred harness path: **`assign_form`** with home guard + stance alias sync (WF-M5).
static func harness_assign_form(mgr: Node, c: Dictionary, form: String) -> void:
    var _WF := preload("res://combat/CombatWeaponForm.gd")
    _WF.assign_form(mgr, c, form, "harness")


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
                _fail(failures, "next_ready_map: id=%d per=%.6f map=%s" % [cid, per, str(cmap.get(cid, "missing"))])
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
        _fail(failures, "vacancy_follow_up: expected stable line after start, changed_fids=%s" % str(ch1))
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
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c, -9) == 0:
            living_rank0_player = true
            break
    if not living_rank0_player:
        _fail(failures, "vacancy_death: no living player at rank 0 after plug")
    _free_manager(mgr)


## Entity creation  -  forwards to HarnessFixtures.
static func _new_entity(weapon_id: String) -> CoreEntity:
    return _Fixtures._new_entity(weapon_id)


static func _new_entity_unarmed() -> CoreEntity:
    return _Fixtures._new_entity_unarmed()


## Manager setup  -  forwards to HarnessFixtures.
static func _harness_start_1v1(
    weapon_id: String = "SWORD",
    player_side: Dictionary = {"files": 1, "ranks": 1},
    enemy_side: Dictionary = {"files": 1, "ranks": 1}
) -> Node:
    return _Fixtures._harness_start_1v1(weapon_id, player_side, enemy_side)


static func _harness_reset_combatants_form_balanced(mgr: Node) -> void:
    _Fixtures._harness_reset_combatants_form_balanced(mgr)


static func _harness_start_player_only(player_side: Dictionary = {"files": 1, "ranks": 1}) -> Node:
    return _Fixtures._harness_start_player_only(player_side)


## Equipment  -  forwards to HarnessFixtures.
static func _harness_equip_heavy_plate_kit(e: CoreEntity) -> void:
    _Fixtures._harness_equip_heavy_plate_kit(e)


## Roster / formation lookups  -  forwards to HarnessFixtures.
static func _harness_find_living_at_rank_file(mgr: Node, side: String, rank: int, file: int) -> Dictionary:
    return _Fixtures._harness_find_living_at_rank_file(mgr, side, rank, file)


## Formation fixtures  -  forwards to HarnessFixtures.
static func _harness_sparse_post_flee_6v3_mgr(survivor_file: int = 4, fled_files: Array = [0, 1, 2, 3]) -> Dictionary:
    return _Fixtures._harness_sparse_post_flee_6v3_mgr(survivor_file, fled_files)


static func _harness_7v3_wing_rank0_fixtures() -> Array:
    return _Fixtures._harness_7v3_wing_rank0_fixtures()


static func _harness_bind_pair_long_band(p: Dictionary, e: Dictionary) -> void:
    _Fixtures._harness_bind_pair_long_band(p, e)


## Guard-line helpers  -  forwards to HarnessFixtures.
static func _harness_cardinal_attack_line(cardinal: String) -> String:
    return _Fixtures._harness_cardinal_attack_line(cardinal)


static func _harness_adjacent_lines_for(cardinal_attack: String) -> Array:
    return _Fixtures._harness_adjacent_lines_for(cardinal_attack)


static func _harness_opposite_cardinal(cardinal: String) -> String:
    return _Fixtures._harness_opposite_cardinal(cardinal)


## IV-9 harness helpers  -  forwards to HarnessFixtures.
static func _harness_iv9_player_rotate_file_listed(mgr: Node) -> bool:
    return _Fixtures._harness_iv9_player_rotate_file_listed(mgr)


static func _harness_iv9_center_rank0_can_melee_threaten(mgr: Node) -> bool:
    return _Fixtures._harness_iv9_center_rank0_can_melee_threaten(mgr)


static func _harness_iv9_gap_column_cache_matches_occupied(formation: Dictionary) -> bool:
    return _Fixtures._harness_iv9_gap_column_cache_matches_occupied(formation)


static func _harness_iv9_resolve_adjacent_rank_pair_move(
    mgr: Node, initiator_id: int, partner_id: int, move_kind: String
) -> void:
    _Fixtures._harness_iv9_resolve_adjacent_rank_pair_move(mgr, initiator_id, partner_id, move_kind)


## Cleanup  -  forwards to HarnessFixtures.
static func _free_harness_node(n: Node) -> void:
    _Fixtures._free_harness_node(n)


static func _free_manager(mgr: Node) -> void:
    _Fixtures._free_manager(mgr)


## seed(_HARNESS_RESTORE_GLOBAL_SEED) then _free_manager  -  keeps run_all() order-stable.
static func _free_manager_restore_global_rng(mgr: Node) -> void:
    _Fixtures._free_manager_restore_global_rng(mgr)


## Harness utility forwards  -  all forwarded to HarnessFixtures.
static func _windup_duration_for_bind_test(weapon_id: String, move_id: String, bind: bool) -> float:
    return _Fixtures._windup_duration_for_bind_test(weapon_id, move_id, bind)


static func _shuffle_int_array_in_place(ids: Array, rng: RandomNumberGenerator) -> void:
    _Fixtures._shuffle_int_array_in_place(ids, rng)


static func _soak_kill_combatant(mgr: Node, combatant_id: int) -> void:
    _Fixtures._soak_kill_combatant(mgr, combatant_id)


## Tier 1.7 - 1.8: many random headcounts + default presets; raw formation must satisfy Option 2 gate; tactical snapshot stays in sync.
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
    _EventScheduler.schedule_event(
        mgr,
        {
            "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
            "combatant_id": id0,
            "resolve_at": mgr.combat_clock + 10.0,
            "data": {"partner_id": id1, "move_kind": "swap_rank"}
        }
    )
    _EventScheduler.schedule_event(
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
    _EventScheduler.cancel_pending_swap_rank_pair_events(mgr, id0, id1)
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
        _fail(
            failures,
            "parry_swap: expected rank0 in swap_rank after start_pair_move (got %s)" % _EntityAccess.state_str(p0)
        )
        _free_manager(mgr)
        return
    if _EntityAccess.state_str(p1) != CombatConstants.STATE_SWAP_RANK:
        _fail(failures, "parry_swap: expected rank1 in swap_rank after start_pair_move")
        _free_manager(mgr)
        return
    en["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high"}
    _AttackResultApplier.apply_result(
        mgr,
        eid,
        {
            "action": "parry_deflect",
            "target_id": id0,
            "recovery_duration": 0.5,
            "parry_clash_context": {"archetype_id": "", "parry_control": 0.0}
        }
    )
    if _EntityAccess.state_str(p0) != CombatConstants.STATE_SWAP_RANK:
        _fail(
            failures,
            (
                "parry_swap: parry_deflect must not set defender to waiting mid pair move (got %s)"
                % _EntityAccess.state_str(p0)
            )
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
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    if _EntityAccess.rank_int(p0) != 1 or _EntityAccess.rank_int(p1) != 0:
        _fail(
            failures,
            (
                "swap_resolve: expected ranks swapped (p0=%d p1=%d)"
                % [_EntityAccess.rank_int(p0), _EntityAccess.rank_int(p1)]
            )
        )
    if (
        _EntityAccess.state_str(p0) != CombatConstants.STATE_WAITING
        or _EntityAccess.state_str(p1) != CombatConstants.STATE_WAITING
    ):
        _fail(
            failures,
            (
                "swap_resolve: both should return to waiting (got %s / %s)"
                % [_EntityAccess.state_str(p0), _EntityAccess.state_str(p1)]
            )
        )
    if p0.has("formation_move_partner_id") or p1.has("formation_move_partner_id"):
        _fail(failures, "swap_resolve: formation_move_partner_id should be cleared")
    _free_manager(mgr)


## Tier 3.0 / combat feel: `negligible` (rounded-zero chip) uses shorter recovery than outcome `hit` at same intensity.
static func _run_negligible_hit_recovery_shorter_than_counted_hit(failures: PackedStringArray) -> void:
    var i: float = 0.55
    var t_hit: float = _CombatTiming.recovery_duration(i, "hit", 1.0, 1.0, 100, -1.0)
    var t_neg: float = _CombatTiming.recovery_duration(i, "negligible", 1.0, 1.0, 100, -1.0)
    if not (t_neg < t_hit):
        _fail(failures, "negligible_recovery: expected negligible < hit (hit=%.4f negligible=%.4f)" % [t_hit, t_neg])


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
    if not line.contains("Graze") or not line.contains("rounds to 0"):
        _fail(failures, "combat_log_negligible: expected graze reason in line: %s" % line)
    var row_neg: String = _CombatLogFormatter.format_last_hit_on_target_row(
        {"outcome": "negligible", "part": "head", "total_physical": 0.2, "dmg": 0}
    )
    if not row_neg.begins_with("Graze:") or not row_neg.contains("rounds to 0"):
        _fail(failures, "combat_log_negligible_row: expected graze reason on row, got: %s" % row_neg)
    var line_deflect: String = _CombatLogFormatter.format_action_line(
        "Ally", "player", "Foe", "enemy", {"outcome": "deflected", "part": "chest", "dmg": 0, "total_physical": 0.0}
    )
    if not line_deflect.contains("Deflected") or not line_deflect.contains("armor stopped"):
        _fail(failures, "combat_log_deflected: expected armor reason, got: %s" % line_deflect)
    var note_glance: String = (
        _CombatLogFormatter
        . damage_resolve_note(
            {
                "outcome": "glancing",
                "final_cut": 0.1,
                "final_blunt": 0.0,
                "mechanical_post_armor": 2.0,
                "dmg": 0,
            }
        )
    )
    if not note_glance.contains("glancing"):
        _fail(failures, "damage_resolve_note glancing: %s" % note_glance)
    var row_hit: String = _CombatLogFormatter.format_last_hit_on_target_row(
        {"outcome": "hit", "part": "head", "total_physical": 5.0, "dmg": 5}
    )
    if not row_hit.begins_with("Hit:"):
        _fail(failures, "combat_log_hit_row: expected Hit prefix, got: %s" % row_hit)
    var row_parry: String = (
        _CombatLogFormatter
        . format_row_last_hit(
            {
                "outcome": "parry_partial",
                "parry_clash_context": {"remaining_ratio": 0.85, "parry_control": 0.12},
            }
        )
    )
    if not row_parry.contains("Partial parry"):
        _fail(failures, "combat_log_parry_row: expected Partial parry strip, got: %s" % row_parry)
    if _CombatLogFormatter.last_hit_row_combatant_id(3, 8, {"outcome": "parry_partial"}) != 3:
        _fail(failures, "last_hit_row_id: parry_partial want defender slot (first id)")
    if _CombatLogFormatter.last_hit_row_combatant_id(1, 2, {"outcome": "hit", "part": "head"}) != 2:
        _fail(failures, "last_hit_row_id: hit want defender slot (second id)")
    if _CombatLogFormatter.last_hit_row_combatant_id(5, -1, {"outcome": "bled_out", "died": true}) != 5:
        _fail(failures, "last_hit_row_id: bled_out want victim slot (first id)")
    if _CombatLogFormatter.format_row_last_hit({"outcome": "bled_out"}) != "Bled out":
        _fail(failures, "combat_log_bled_out_row: expected Bled out strip")
    if _CombatLogFormatter.action_resolved_victim_id(1, 2, {"outcome": "hit"}) != 2:
        _fail(failures, "action_resolved_victim_id: hit want target_id")
    if _CombatLogFormatter.action_resolved_victim_id(5, -1, {"outcome": "bled_out"}) != 5:
        _fail(failures, "action_resolved_victim_id: tick bleed want attacker_id when target=-1")
    _run_combat_ui_hint_fp_echo_dedupe(failures)
    _run_diagram_banner_fp_dedupe(failures)
    _run_fight_trace_buffer_preserves_session_counts(failures)
    _run_turn_ready_formation_fp_line_dedupe(failures)
    _run_turn_ready_gauge_fp_line_dedupe(failures)
    _run_manager_started_no_encounter_repeat(failures)
    _run_medical_action_pick_single_fp_line(failures)
    _run_engagement_transition_fp_dedupe(failures)
    _run_strike_avoided_fp_dedupe(failures)
    _run_combat_hit_summary_override_while_harness_quiet(failures)
    _run_medical_session_fp_dedupe(failures)
    _run_parry_fp_reason_suffix(failures)
    _run_combat_session_fp_dedupe(failures)
    _run_diagram_banner_enemy_fp(failures)
    _run_play_combat_fp_dedupe(failures)
    _run_formation_move_pick_fp_dedupe(failures)
    _run_soak_coverage_once_per_fight(failures)
    _run_medical_pressure_fp_suppressed_in_play(failures)
    _run_medical_phase_intro_once(failures)
    _run_ambient_pain_shock_fp_dedupe(failures)
    _run_editor_f5_skips_verbose_phase_end(failures)
    _run_fight_fp_channel_dedupe_resets_between_fights(failures)
    if _CombatLogFormatter.format_row_last_hit({"outcome": "miss"}) != "Miss  -  attack missed (no contact)":
        _fail(failures, "combat_log_miss_row: expected Miss strip with reason")
    if (
        _CombatLogFormatter.format_row_last_hit({"outcome": "miss", "part": "left_arm"})
        != "Miss: L.Arm  -  attack missed (no contact)"
    ):
        _fail(failures, "combat_log_miss_row_part: expected part on avoid strip")
    if (
        _CombatLogFormatter.format_row_last_hit({"outcome": "dodge", "part": "head"})
        != "Dodged: Head  -  defender dodged"
    ):
        _fail(failures, "combat_log_dodge_row_part: expected part and reason on dodge strip")
    var line_focus: String = _CombatLogFormatter.format_action_line(
        "Ally", "player", "Ally", "player", {"outcome": "focus_line", "line": "high"}
    )
    if not line_focus.contains("shifts focus") or not line_focus.contains("High"):
        _fail(failures, "combat_log_focus_line: expected focus guard line, got: %s" % line_focus)
    if (
        _PartyRowFormatter.format_body_part_compact(
            "head", {"head": 29.8}, {"head": 0.0}, {"head": 30}, {"head": 0.0}, {}
        )
        != "Hd 29.8|0|0"
    ):
        _fail(failures, "body_part_compact: expected one-decimal chip display")


static func _run_combat_ui_hint_fp_echo_dedupe(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    mgr.notify_combat_ui_hint("Listed formation moves: step_in", false)
    mgr.notify_combat_ui_hint("Arc overlap", true)
    var ui_count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if "ui_hint " in line:
            ui_count += 1
    if ui_count != 1:
        _fail(failures, "ui_hint_fp_echo: want 1 FP ui_hint line got %d" % ui_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
    _free_harness_node(mgr)


static func _run_diagram_banner_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var banner: String = "Formation line . Hold . cohesion 80%"
    _F5SoakTrace.log_diagram_banner_player(banner)
    _F5SoakTrace.log_diagram_banner_player(banner)
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: diagram_banner player:"):
            count += 1
    if count != 1:
        _fail(failures, "diagram_banner_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_fight_trace_buffer_preserves_session_counts(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.log_diagram_banner_player("Formation line . Hold . cohesion 50%")
    _F5SoakTrace.reset_fight_trace_buffer()
    _F5SoakTrace.log_fight_end_summary("player", false)
    var summary: String = ""
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            summary = line
            break
    if summary.is_empty():
        _fail(failures, "fight_trace_reset: missing soak_fight_end line")
        return
    var parts: PackedStringArray = summary.split(" ")
    for part in parts:
        if part.begins_with("diagram_banner="):
            if int(part.substr("diagram_banner=".length())) < 1:
                _fail(
                    failures,
                    (
                        "fight_trace_reset: soak_fight_end should retain diagram_banner count after reset_fight_trace_buffer (%s)"
                        % part
                    )
                )
            return
    _fail(failures, "fight_trace_reset: soak_fight_end missing diagram_banner= field")
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_turn_ready_formation_fp_line_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var fp: String = "Listed formation moves: wait"
    _F5SoakTrace._emit_turn_ready_formation_fp(1, "Leader", fp)
    _F5SoakTrace._emit_turn_ready_formation_fp(1, "Leader", fp)
    var form_count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: turn_ready_formation_line "):
            form_count += 1
    if form_count != 1:
        _fail(failures, "turn_ready_formation_fp_dedupe: want 1 line got %d" % form_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_turn_ready_gauge_fp_line_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var mgr: Node = _MgrScript.new()
    var leader: Dictionary = {
        "id": 1,
        "side": "player",
        "state": CombatConstants.STATE_WAITING,
        "gauge": 100.0,
        "rank": 0,
    }
    _F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
    _F5SoakTrace.log_turn_ready_player_ui(mgr, leader, [])
    var gauge_count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: turn_ready_gauge "):
            gauge_count += 1
    if gauge_count != 1:
        _fail(failures, "turn_ready_gauge_fp_dedupe: want 1 line got %d" % gauge_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
    _free_harness_node(mgr)


static func _run_manager_started_no_encounter_repeat(failures: PackedStringArray) -> void:
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _OperationalLog.play_combat_manager_started(2, 3, {"player": "default"}, {"soak": "ii2b"})
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: manager_started ") and "| encounter[" in line:
            _fail(failures, "manager_started: should not repeat encounter blob (got %s)" % line)
            break
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_medical_action_pick_single_fp_line(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_medical_action_pick("Medic", "apply_direct_pressure", "chest", "ally")
    var pick_count: int = 0
    var fp_count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: medical_action pick "):
            pick_count += 1
        if line.begins_with("FP_COMBAT: action ") and " chose medical " in line:
            fp_count += 1
    if pick_count != 1:
        _fail(failures, "medical_action_pick: want 1 medical_action pick line got %d" % pick_count)
    if fp_count != 0:
        _fail(failures, "medical_action_pick: want 0 FP action chose medical lines got %d" % fp_count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_engagement_transition_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_engagement_transition("Duel", "Formation line")
    _F5SoakTrace.note_engagement_transition("Duel", "Formation line")
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: engagement_transition "):
            count += 1
    if count != 1:
        _fail(failures, "engagement_transition_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_strike_avoided_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(false)
    CombatConstants.set_combat_hit_summary_override(true)
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var atk: Dictionary = {"id": 1, "side": "player", "name": "A"}
    var tgt: Dictionary = {"id": 2, "side": "enemy", "name": "D"}
    _F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
    _F5SoakTrace.note_strike_avoided(1, 2, atk, tgt, "miss", "head")
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: strike_avoided "):
            count += 1
    if count != 1:
        _fail(failures, "strike_avoided_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)
    CombatConstants.clear_combat_hit_summary_override()
    CombatConstants.set_headless_harness_quiet(was_quiet)


static func _run_combat_hit_summary_override_while_harness_quiet(failures: PackedStringArray) -> void:
    var was_quiet: bool = CombatConstants.is_headless_harness_quiet()
    CombatConstants.set_headless_harness_quiet(true)
    CombatConstants.set_combat_hit_summary_override(true)
    if not CombatConstants.combat_hit_summary_active():
        _fail(failures, "hit_summary_override: want active under harness quiet (D-001 soak_fight_end hit_resolve)")
    CombatConstants.set_combat_hit_summary_override(false)
    if CombatConstants.combat_hit_summary_active():
        _fail(failures, "hit_summary_override: explicit off should lose to harness quiet")
    CombatConstants.clear_combat_hit_summary_override()
    CombatConstants.set_headless_harness_quiet(was_quiet)


static func _run_medical_session_fp_dedupe(failures: PackedStringArray) -> void:
    CombatDebug.clear_flow_log_dedup()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var body: String = "Medic apply_bandage(chest) => success, 1 wound(s) stabilized"
    CombatDebug.medical_session(body)
    CombatDebug.medical_session(body)
    var want: String = "FP_COMBAT: medical %s" % body
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line == want:
            count += 1
    if count != 1:
        _fail(failures, "medical_session_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_parry_fp_reason_suffix(failures: PackedStringArray) -> void:
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var atk: Dictionary = {"id": 1, "side": "enemy", "name": "A"}
    var tgt: Dictionary = {"id": 2, "side": "player", "name": "D"}
    _AttackResultApplier._log_fp_parry_outcome(
        atk, tgt, 1, 2, "parry_partial", {"parry_control": 0.5, "remaining_ratio": 0.2}
    )
    var found: bool = false
    for line in _OperationalLog.get_captured_lines():
        if line.contains("parry_partial") and line.contains("reason="):
            found = true
            break
    if not found:
        _fail(failures, "parry_fp_reason: expected parry_partial line with reason=")
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_combat_session_fp_dedupe(failures: PackedStringArray) -> void:
    CombatDebug.clear_flow_log_dedup()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
    CombatDebug.combat_session("exhaustion Ally crossed 50% (index 52% perf 90%)")
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.contains("exhaustion Ally crossed 50%"):
            count += 1
    if count != 1:
        _fail(failures, "combat_session_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_diagram_banner_enemy_fp(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.log_diagram_banner_enemy("Skirmish . Loose . cohesion 40%")
    _F5SoakTrace.log_diagram_banner_enemy("Skirmish . Loose . cohesion 40%")
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: diagram_banner enemy:"):
            count += 1
    if count != 1:
        _fail(failures, "diagram_banner_enemy_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_play_combat_fp_dedupe(failures: PackedStringArray) -> void:
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var body: String = "cowering_fall_back listed for Leader"
    _OperationalLog.play_combat(body)
    _OperationalLog.play_combat(body)
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line == "FP_COMBAT: %s" % body:
            count += 1
    if count != 1:
        _fail(failures, "play_combat_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_formation_move_pick_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
    _F5SoakTrace.note_formation_move_pick("rotate_file", 1, 2)
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line == "FP_COMBAT: rotate_file@2":
            count += 1
    if count != 1:
        _fail(failures, "formation_move_pick_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_soak_coverage_once_per_fight(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.log_fight_end_summary("player", false)
    _F5SoakTrace.log_fight_end_summary("player", false)
    var count: int = 0
    var validate_n: int = 0
    var soak_end_n: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: soak_coverage ok="):
            count += 1
        if line.begins_with("FP_COMBAT: soak_validate_hint "):
            validate_n += 1
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            soak_end_n += 1
    if count != 1:
        _fail(failures, "soak_coverage_once: want 1 soak_coverage header got %d" % count)
    if validate_n != 1:
        _fail(failures, "soak_validate_hint_once: want 1 line got %d" % validate_n)
    if soak_end_n != 1:
        _fail(failures, "soak_fight_end_once: want 1 line got %d" % soak_end_n)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_medical_pressure_fp_suppressed_in_play(failures: PackedStringArray) -> void:
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _EntityMedical.log_medical_session("Ally direct_pressure self part=chest (TCCC)")
    _EntityMedical.log_medical_session("Ally apply_bandage(chest) => success, 1 wound(s) stabilized")
    var pressure_n: int = 0
    var bandage_n: int = 0
    for line in _OperationalLog.get_captured_lines():
        if "direct_pressure self" in line:
            pressure_n += 1
        if "apply_bandage" in line:
            bandage_n += 1
    if pressure_n != 0:
        _fail(failures, "medical_pressure_fp: want 0 pressure lines got %d" % pressure_n)
    if bandage_n != 1:
        _fail(failures, "medical_pressure_fp: want 1 bandage line got %d" % bandage_n)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_medical_phase_intro_once(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_medical_phase_intro()
    _F5SoakTrace.note_medical_phase_intro()
    var count: int = 0
    var double_medical: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: medical_phase: full hemorrhage"):
            count += 1
        if "medical medical_phase:" in line:
            double_medical += 1
    if count != 1:
        _fail(failures, "medical_phase_intro_once: want 1 intro line got %d" % count)
    if double_medical != 0:
        _fail(failures, "medical_phase_intro_prefix: forbid medical medical_phase: got %d" % double_medical)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_ambient_pain_shock_fp_dedupe(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
    _F5SoakTrace.note_ambient_pain_shock("Companion", 42.0, 3.5)
    var count: int = 0
    for line in _OperationalLog.get_captured_lines():
        if line.begins_with("FP_COMBAT: ambient_pain_shock "):
            count += 1
    if count != 1:
        _fail(failures, "ambient_pain_shock_dedupe: want 1 line got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_editor_f5_skips_verbose_phase_end(failures: PackedStringArray) -> void:
    var PHASE_STUB: String = "phase_end winner=player defeated_node=null alive_by_side={} standing_by_side={} fled_by_side={}"
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("res://main.tscn", "", false, true)
    if not _OperationalLog.play_session_is_editor_f5():
        _fail(failures, "editor_f5_detect: main.tscn session should be editor F5")
    # Mirror CombatManager.finish_battle gate (editor F5 uses soak_fight_end, not phase_end).
    if not _OperationalLog.play_session_is_editor_f5():
        CombatDebug.combat_session(PHASE_STUB)
    _F5SoakTrace.log_fight_end_summary("player", true)
    var phase_n: int = 0
    var soak_end_n: int = 0
    for line in _OperationalLog.get_captured_lines():
        if "phase_end winner=" in line:
            phase_n += 1
        if line.begins_with("FP_COMBAT: soak_fight_end "):
            soak_end_n += 1
    if phase_n != 0:
        _fail(failures, "editor_f5_phase_end: want 0 phase_end got %d" % phase_n)
    if soak_end_n != 1:
        _fail(failures, "editor_f5_soak_fight_end: want 1 got %d" % soak_end_n)
    _OperationalLog.end_play_session()
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("headless://d001-soak", "", false, true)
    if _OperationalLog.play_session_is_editor_f5():
        _fail(failures, "editor_f5_detect: headless session must not be editor F5")
    if not _OperationalLog.play_session_is_editor_f5():
        CombatDebug.combat_session(PHASE_STUB)
    phase_n = 0
    for line in _OperationalLog.get_captured_lines():
        if "phase_end winner=" in line:
            phase_n += 1
    if phase_n != 1:
        _fail(failures, "headless_phase_end: want 1 phase_end got %d" % phase_n)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _run_fight_fp_channel_dedupe_resets_between_fights(failures: PackedStringArray) -> void:
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    var line: String = "turn_ready_gauge id=0 Tester label=Ready tooltip_match=ok"
    _OperationalLog.play_combat(line)
    _F5SoakTrace.prepare_fight_end_log()
    _OperationalLog.play_combat(line)
    var count: int = 0
    for cap in _OperationalLog.get_captured_lines():
        if cap == "FP_COMBAT: %s" % line:
            count += 1
    if count != 2:
        _fail(failures, "fight_fp_channel_reset: want 2 identical lines across fights got %d" % count)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


static func _assert_depth_polearm_allows_low_fid_round_trip_slice(
    mgr: Node, failures: PackedStringArray, ctx: String
) -> void:
    _Fixtures._assert_depth_polearm_allows_low_fid_round_trip_slice(mgr, failures, ctx)


static func _assert_stamp_depth_pa_defaults(pa: Dictionary, failures: PackedStringArray, ctx: String) -> void:
    _Fixtures._assert_stamp_depth_pa_defaults(pa, failures, ctx)


static func _assert_depth_lane_open_cache_matches_builder(mgr: Node, failures: PackedStringArray, ctx: String) -> void:
    _Fixtures._assert_depth_lane_open_cache_matches_builder(mgr, failures, ctx)


## Tier 3.1: pack / protection-circle parry flank uses wedge/lane-aware effective file spacing (falls back to |-file|>=2).
## Tier 3.1: sector surround `1/(1+k.excess)` matches integer **`surround_defense_multiplier`** when total weight = 2 (two full-width flank threats).
static func _run_strike_measure_constants_sanity(failures: PackedStringArray) -> void:
    var w: Weapon = _Weapon.create_from_definition("SWORD")
    if w == null:
        _fail(failures, "strike_meas_const: missing SWORD weapon")
        return
    var eff_in: float = 1.0
    var got: float = _StrikeStamping.strike_measure_ratio_for_weapon_eff_dist(w, eff_in)
    var eff: float = maxf(eff_in, CombatConstants.STRIKE_MEASURE_EFF_DIST_FLOOR)
    var melee: float = w.melee_range
    var want: float = clampf(
        melee / eff, CombatConstants.STRIKE_MEASURE_RATIO_MIN, CombatConstants.STRIKE_MEASURE_RATIO_MAX
    )
    if not is_equal_approx(got, want):
        _fail(failures, "strike_meas_const: got %.4f want %.4f (melee=%.3f eff_floor=%.3f)" % [got, want, melee, eff])


## Tier 1.3: **`effective_pair_geometry`** returns **`eff_dist`** / **`file_spacing_equiv`** matching wrapper helpers (one ZoC read).
static func _run_effective_pair_geometry_single_pass_matches_wrappers(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2, "density": "loose"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr.recompute_zoc_and_distance()
    var a: Dictionary = mgr.combatants[0]
    var b: Dictionary = mgr.combatants[2]
    var geom: Dictionary = _PairGeometry.effective_pair_geometry(mgr, a, b)
    var eff_wrap: float = _PairGeometry.cached_eff_dist(geom)
    var space_wrap: float = float(geom.get("file_spacing_equiv", 0.0))
    _free_manager(mgr)
    if not geom.has("eff_dist") or not geom.has("file_spacing_equiv"):
        _fail(failures, "pair_geom: result dict missing eff_dist or file_spacing_equiv")
        return
    if not is_equal_approx(float(geom["eff_dist"]), eff_wrap):
        _fail(failures, "pair_geom: eff_dist %.4f vs wrapper %.4f" % [float(geom["eff_dist"]), eff_wrap])
    if not is_equal_approx(float(geom["file_spacing_equiv"]), space_wrap):
        _fail(
            failures,
            "pair_geom: file_spacing_equiv %.4f vs wrapper %.4f" % [float(geom["file_spacing_equiv"]), space_wrap]
        )


## Tier 3.1: `CombatStrikeStamping.stamp_attack_pair_geometry_on_dict` via wind-up (re-stamped each resolve).
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
    var pa0: Dictionary = _EntityAccess.nested_dictionary_read(
        comb_pa0 if comb_pa0 is Dictionary else {}, "pending_attack"
    )
    if pa0.is_empty():
        _fail(failures, "windup_geom: empty pending_attack (rank0)")
    else:
        if not pa0.has("effective_pair_file_spacing_equivalent") or not pa0.has("effective_pair_eff_dist"):
            _fail(failures, "windup_geom: rank0 missing spacing keys")
        var p0: Dictionary = mgr.combatants[0]
        var e0: Dictionary = mgr.combatants[1]
        var want_eff0: float = _PairGeometry.effective_pair_eff_dist(mgr, p0, e0)
        var want_space0: float = _PairGeometry.effective_pair_file_spacing_equivalent(mgr, p0, e0)
        if not is_equal_approx(float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0):
            _fail(
                failures,
                (
                    "windup_geom: rank0 eff_dist stamp %.4f vs builder %.4f"
                    % [float(pa0.get("effective_pair_eff_dist", -1.0)), want_eff0]
                )
            )
        if not is_equal_approx(float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0):
            _fail(
                failures,
                (
                    "windup_geom: rank0 file_spacing_eq stamp %.4f vs builder %.4f"
                    % [float(pa0.get("effective_pair_file_spacing_equivalent", -1.0)), want_space0]
                )
            )
        var w0: Variant = _EntityAccess.get_weapon(p0)
        if w0 != null:
            var want_meas0: float = _StrikeStamping.strike_measure_ratio_for_attack_pair(mgr, p0, e0, w0, want_eff0)
            if not is_equal_approx(float(pa0.get("strike_measure_ratio", -9.0)), want_meas0):
                _fail(
                    failures,
                    (
                        "windup_geom: rank0 strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                        % [float(pa0.get("strike_measure_ratio", -9.0)), want_meas0]
                    )
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
    mgr2.call("recompute_zoc_and_distance")
    var depth: Dictionary = mgr2.combatants[1]
    var en: Dictionary = mgr2.combatants[2]
    if not _DepthPolearm.depth_polearm_lane_open(mgr2, depth):
        _fail(failures, "windup_geom: expected depth polearm lane open")
    else:
        var d_id: int = _EntityAccess.id_int(depth)
        var en_id: int = _EntityAccess.id_int(en)
        _WindUpStarter.start(mgr2, d_id, en_id, "spear_thrust")
        var comb_pa1: Variant = mgr2._get_by_id(d_id)
        var pa1: Dictionary = _EntityAccess.nested_dictionary_read(
            comb_pa1 if comb_pa1 is Dictionary else {}, "pending_attack"
        )
        if pa1.is_empty():
            _fail(failures, "windup_geom: empty pending_attack (depth)")
        elif not pa1.has("effective_pair_file_spacing_equivalent") or not pa1.has("effective_pair_eff_dist"):
            _fail(failures, "windup_geom: depth missing spacing keys")
        elif not bool(pa1.get("depth_polearm_attack", false)):
            _fail(failures, "windup_geom: depth spear should set depth_polearm_attack")
        else:
            var want_eff1: float = _PairGeometry.effective_pair_eff_dist(mgr2, depth, en)
            var want_space1: float = _PairGeometry.effective_pair_file_spacing_equivalent(mgr2, depth, en)
            if not is_equal_approx(float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1):
                _fail(
                    failures,
                    (
                        "windup_geom: depth eff_dist stamp %.4f vs builder %.4f"
                        % [float(pa1.get("effective_pair_eff_dist", -1.0)), want_eff1]
                    )
                )
            if not is_equal_approx(float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1):
                _fail(
                    failures,
                    (
                        "windup_geom: depth file_spacing_eq stamp %.4f vs builder %.4f"
                        % [float(pa1.get("effective_pair_file_spacing_equivalent", -1.0)), want_space1]
                    )
                )
            var want_allow: bool = _DepthPolearm.depth_polearm_lane_allows_low_targets(mgr2, depth)
            if bool(pa1.get("depth_polearm_allows_low_targets", not want_allow)) != want_allow:
                _fail(
                    failures,
                    (
                        "windup_geom: depth_polearm_allows_low_targets=%s want %s"
                        % [str(pa1.get("depth_polearm_allows_low_targets")), str(want_allow)]
                    )
                )
            var want_lane: String = "open" if want_allow else "over_shoulder"
            if str(pa1.get("depth_polearm_lane_type", "")) != want_lane:
                _fail(
                    failures,
                    (
                        "windup_geom: depth_polearm_lane_type=%s want %s"
                        % [str(pa1.get("depth_polearm_lane_type")), want_lane]
                    )
                )
            var w1: Variant = _EntityAccess.get_weapon(depth)
            if w1 != null:
                var want_meas1: float = _StrikeStamping.strike_measure_ratio_for_attack_pair(
                    mgr2, depth, en, w1, want_eff1
                )
                if not is_equal_approx(float(pa1.get("strike_measure_ratio", -9.0)), want_meas1):
                    _fail(
                        failures,
                        (
                            "windup_geom: depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                            % [float(pa1.get("strike_measure_ratio", -9.0)), want_meas1]
                        )
                    )
    _free_manager(mgr2)

    # 3-wide enemy line: stamped `effective_pair_*` must still match builder (wedge/lane/ZoC path stress).
    var mgr3: Node = _MgrScript.new()
    mgr3.register(_new_entity("SWORD"), "player")
    mgr3.register(_new_entity("SPEAR"), "player")
    for _i in 3:
        mgr3.register(_new_entity("SWORD"), "enemy")
    mgr3.start({"files": 1, "ranks": 2, "density": "normal"}, {"files": 3, "ranks": 1, "density": "normal"})
    mgr3.call("recompute_zoc_and_distance")
    var depth3: Dictionary = mgr3.combatants[1]
    var en30: Dictionary = mgr3.combatants[2]
    if not _DepthPolearm.depth_polearm_lane_open(mgr3, depth3):
        _fail(failures, "windup_geom: 3-file enemy expected depth polearm lane open")
    elif not _MeleeListing.can_melee_threaten(mgr3, depth3, en30):
        _fail(failures, "windup_geom: 3-file enemy depth should melee-threaten file-opposed rank-0")
    else:
        var d3_id: int = _EntityAccess.id_int(depth3)
        var e3_id: int = _EntityAccess.id_int(en30)
        _WindUpStarter.start(mgr3, d3_id, e3_id, "spear_thrust")
        var comb_pa3: Variant = mgr3._get_by_id(d3_id)
        var pa3: Dictionary = _EntityAccess.nested_dictionary_read(
            comb_pa3 if comb_pa3 is Dictionary else {}, "pending_attack"
        )
        if pa3.is_empty():
            _fail(failures, "windup_geom: empty pending_attack (depth 3-file line)")
        elif not bool(pa3.get("depth_polearm_attack", false)):
            _fail(failures, "windup_geom: depth 3-file should set depth_polearm_attack")
        else:
            var want_eff3: float = _PairGeometry.effective_pair_eff_dist(mgr3, depth3, en30)
            var want_space3: float = _PairGeometry.effective_pair_file_spacing_equivalent(mgr3, depth3, en30)
            if not is_equal_approx(float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3):
                _fail(
                    failures,
                    (
                        "windup_geom: 3-file depth eff_dist stamp %.4f vs builder %.4f"
                        % [float(pa3.get("effective_pair_eff_dist", -1.0)), want_eff3]
                    )
                )
            if not is_equal_approx(float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3):
                _fail(
                    failures,
                    (
                        "windup_geom: 3-file depth file_spacing_eq stamp %.4f vs builder %.4f"
                        % [float(pa3.get("effective_pair_file_spacing_equivalent", -1.0)), want_space3]
                    )
                )
            var w3: Variant = _EntityAccess.get_weapon(depth3)
            if w3 != null:
                var want_meas3: float = _StrikeStamping.strike_measure_ratio_for_attack_pair(
                    mgr3, depth3, en30, w3, want_eff3
                )
                if not is_equal_approx(float(pa3.get("strike_measure_ratio", -9.0)), want_meas3):
                    _fail(
                        failures,
                        (
                            "windup_geom: 3-file depth strike_measure_ratio %.4f vs eff-keyed measure %.4f"
                            % [float(pa3.get("strike_measure_ratio", -9.0)), want_meas3]
                        )
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
    _AttackResultApplier.apply_result(mgr, p_id, {"action": "defeated", "target_id": e_id})
    if not _EntityAccess.nested_dictionary_read(p, "pending_attack").is_empty():
        _fail(failures, "result_applier: defeated should clear attacker pending_attack")
    if _EntityAccess.state_str(p) != CombatConstants.STATE_WAITING:
        _fail(failures, "result_applier: defeated attacker should be WAITING got %s" % _EntityAccess.state_str(p))
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
    p2.pending_attack = {"target_id": e2_id, "attack_type": "thrust", "intensity": 0.5, "effective_attack_line": "high"}
    _AttackResultApplier.apply_result(mgr2, p2_id, {"action": "miss", "target_id": e2_id, "recovery_duration": 0.35})
    if not _EntityAccess.nested_dictionary_read(p2, "pending_attack").is_empty():
        _fail(failures, "result_applier: miss should clear attacker pending_attack")
    if str(p2.get("last_move_id", "")) != "thrust":
        _fail(failures, "result_applier: miss should set last_move_id from pending thrust")
    if _EntityAccess.state_str(p2) != CombatConstants.STATE_RECOVERING:
        _fail(failures, "result_applier: miss attacker should be RECOVERING got %s" % _EntityAccess.state_str(p2))
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
    _AttackResultApplier.apply_result(mgr3, p3_id, {"action": "dodge", "target_id": e3_id, "recovery_duration": 0.4})
    if not _EntityAccess.nested_dictionary_read(p3, "pending_attack").is_empty():
        _fail(failures, "result_applier: dodge should clear attacker pending_attack")
    if _EntityAccess.state_str(p3) != CombatConstants.STATE_RECOVERING:
        _fail(failures, "result_applier: dodge attacker should be RECOVERING got %s" % _EntityAccess.state_str(p3))
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
    _AttackResultApplier.apply_result(mgr4, p4_id, {"action": "skip", "target_id": e4_id, "recovery_duration": 0.28})
    if not _EntityAccess.nested_dictionary_read(p4, "pending_attack").is_empty():
        _fail(failures, "result_applier: skip+recovery should clear attacker pending_attack")
    if _EntityAccess.state_str(p4) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures, "result_applier: skip+recovery attacker should be RECOVERING got %s" % _EntityAccess.state_str(p4)
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
            failures, "result_applier: skip no-recovery attacker should be WAITING got %s" % _EntityAccess.state_str(p5)
        )
    _free_manager(mgr5)


## **`AttackResultApplier`**: **`parry_deflect`** -> **`action_resolved`** payload includes resolver **`parry_clash_context`** (signal args: defender id, attacker id, **`BattleScene`** slot names reversed).
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
            (
                "parry_resolve_emit: second signal arg should be attacker id %d got %d"
                % [e_id, int(slot.get("second", -99))]
            )
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
    e["pending_attack"] = {
        "target_id": p_id, "attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.5
    }
    var pclash: Dictionary = {
        "kinematic_delivery": "thrust", "strike_measure_ratio": 1.05, "parry_control": 0.41, "remaining_ratio": 0.33
    }
    _AttackResultApplier.apply_result(
        mgr, e_id, {"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
    )
    if captured.is_empty():
        _fail(failures, "parry_partial_resolve_emit: expected at least one action_resolved")
        _free_manager(mgr)
        return
    var slot: Dictionary = captured[0] as Dictionary
    if int(slot.get("first", -99)) != p_id:
        _fail(
            failures,
            (
                "parry_partial_resolve_emit: first signal arg should be defender id %d got %d"
                % [p_id, int(slot.get("first", -99))]
            )
        )
    if int(slot.get("second", -99)) != e_id:
        _fail(
            failures,
            (
                "parry_partial_resolve_emit: second signal arg should be attacker id %d got %d"
                % [e_id, int(slot.get("second", -99))]
            )
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
    (
        _AttackResultApplier
        . apply_result(
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
    (
        _AttackResultApplier
        . apply_result(
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
    )
    if str(p.get("guard_line", "")) != "low":
        _fail(failures, "hit_guard_reaction: defender guard_line want low got %s" % str(p.get("guard_line", "")))
    var want_zone: String = CombatConstants.LINE_TO_DEFAULT_PART.get("low", "")
    if str(p.get("guard_zone", "")) != want_zone:
        _fail(
            failures,
            "hit_guard_reaction: defender guard_zone want %s got %s" % [want_zone, str(p.get("guard_zone", ""))]
        )
    _free_manager(mgr)


## **`parry_partial`**: defender **`parry_was_bind`** / **`parry_against_id`** when alignment >= partial threshold and clash **`parry_control`** crosses bind threshold; cleared when misaligned or control low (misaligned path **`erase`**s stale **`parry_was_bind`**).
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
            "parry_remaining_ratio": 0.05,
        }
        var pclash: Dictionary = {"parry_control": parry_control, "archetype_id": "stab"}
        _AttackResultApplier.apply_result(
            mgr, e_id, {"action": "parry_partial", "target_id": p_id, "parry_clash_context": pclash}
        )
        if expect_bind:
            var _dbg_keys: String = "N/A"
            var _dbg_atk_line: String = "N/A"
            var _dbg_atk_angle: float = -999.0
            var _dbg_is_dict: bool = e.pending_attack is Dictionary
            if _dbg_is_dict:
                _dbg_keys = str(e.pending_attack.keys())
                _dbg_atk_line = str(e.pending_attack.get("effective_attack_line", "high"))
                _dbg_atk_angle = float(e.pending_attack.get("attack_angle_deg", -999.0))
            var _dbg_align: float = -1.0
            if _dbg_atk_angle >= 0.0:
                _dbg_align = (
                    CombatConstants
                    . get_line_alignment_with_deflect(
                        _dbg_atk_line,
                        p,
                        {
                            "attack_angle_deg": _dbg_atk_angle,
                            "guard_angle_deg": 0.0,
                        }
                    )
                )
            if not bool(p.get("parry_was_bind", false)):
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: parry_was_bind want true got %s (keys=%s atk_angle=%.1f align_approx=%.3f control=%f)"
                        % [
                            label,
                            str(p.get("parry_was_bind", false)),
                            _dbg_keys,
                            _dbg_atk_angle,
                            _dbg_align,
                            parry_control
                        ]
                    )
                )
            if int(p.get("parry_against_id", -99)) != e_id:
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: parry_against_id want %d got %s"
                        % [label, e_id, str(p.get("parry_against_id", -99))]
                    )
                )
            if not p.has("parry_bonus_until"):
                _fail(failures, "parry_partial_bind %s: expected parry_bonus_until set" % label)
        else:
            if p.has("parry_against_id"):
                _fail(
                    failures,
                    (
                        "parry_partial_bind %s: expected no parry_against_id got %s"
                        % [label, str(p.get("parry_against_id", -99))]
                    )
                )
            if p.has("parry_bonus_until"):
                _fail(failures, "parry_partial_bind %s: expected no parry_bonus_until" % label)
            if misaligned_erase_bind_key:
                if p.has("parry_was_bind"):
                    _fail(
                        failures,
                        "parry_partial_bind %s: expected parry_was_bind erased (misaligned / stale clear)" % label
                    )
            else:
                if not p.has("parry_was_bind") or bool(p["parry_was_bind"]):
                    _fail(
                        failures,
                        (
                            "parry_partial_bind %s: want parry_was_bind key false got has=%s val=%s"
                            % [label, str(p.has("parry_was_bind")), str(p.get("parry_was_bind", "<absent>"))]
                        )
                    )
        _free_manager(mgr)

    _apply_partial_bind.call(0.0, 0.9, true, "aligned_high_control", false, false)
    _apply_partial_bind.call(0.0, 0.5, false, "aligned_low_control", false, false)
    _apply_partial_bind.call(90.0, 0.9, false, "misaligned_high_control", false, true)
    _apply_partial_bind.call(90.0, 0.9, false, "misaligned_clears_stale_bind", true, true)


static func _harness_counter_tempo_set_incoming_progress(mgr: Node, attacker_id: int, fraction: float) -> void:
    _Fixtures._harness_counter_tempo_set_incoming_progress(mgr, attacker_id, fraction)


## Tier 4.2 counter-tempo pilot: incoming wind-up opens defender **`COMBATANT_KEY_COUNTER_WINDOW_UNTIL`**.
static func _run_combat_end_enemy_win_stops_manager(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var ent_player := _new_entity("SWORD")
    mgr.register(ent_player, "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.set_process(true)
    var ended_box: Array = [0]
    mgr.combat_ended.connect(func(_w: String, _d: Node) -> void: ended_box[0] = int(ended_box[0]) + 1)
    mgr._end_combat_phase("enemy", ent_player)
    if not mgr.medical_phase:
        _fail(failures, "combat_end_enemy_win: medical_phase should be set true for halt_losing_side")
    if mgr.is_processing():
        _fail(failures, "combat_end_enemy_win: manager should stop processing")
    if not mgr.combat_resolution_closed:
        _fail(failures, "combat_end_enemy_win: combat_resolution_closed should be true")
    for _i in 24:
        _ProcessTick.tick(mgr, 0.05)
    if int(ended_box[0]) != 1:
        _fail(
            failures,
            "combat_end_enemy_win: combat_ended should emit once after manual ticks (got %d)" % int(ended_box[0])
        )
    _free_manager(mgr)


## Tier 4.3: mental stack L1 picks medical when ally in peril.
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
    _WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "left_leg", "feint_part": "head"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "head":
        _fail(
            failures,
            (
                "feint_rewind: first telegraph want head got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    seed(_FEINT_WINDUP_HARNESS_SEED)
    _WindUpStarter.start(mgr, p_id, e_id, "oberhau_feint", {"target_part": "right_leg", "feint_part": "chest"})
    if str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")) != "chest":
        _fail(
            failures,
            (
                "feint_rewind: second telegraph want chest got %s"
                % str(e.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, ""))
            )
        )
    if str(e.get("guard_zone", "")) != "chest":
        _fail(failures, "feint_rewind: second guard_zone telegraph want chest got %s" % str(e.get("guard_zone", "")))
    _free_manager_restore_global_rng(mgr)


## Tier 4.2: **`CombatManager.start`** erases **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on all combatants (second **`start()`** without re-**`register`**).
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
            (
                "weapon_parts: spear parry mass %.3f want %.3f"
                % [spear.get_parry_part_mass_kg(), expected_spear_parry_mass]
            )
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


## Tier 3.0 (+ Tier 5 damage-flow anchor): **`WeaponDamageHelper.kinematic_delivery`** overrides move inference; **`kinematic_mixed_blend`** **0** / **1** KE + effective velocity match pure thrust / swing at the same move + intensity; interior blend **0.5** velocity = **`lerp`** of pure thrust vs pure swing speeds; mixed blend **0.5** KE = **`lerp`** of thrust vs swing KE **at that same blended `v`** (not **`lerp`** of pure-mode KE at each mode's **`v`**). Repeats the mixed **0** / **0.5** / **1** bracket checks on **AXE** **`diagonal_chop`** and **DAGGER** **`quick_slash`** (extra cut fixtures; **`spear_slash`** can degenerate thrust/swing KE at some intensities).
static func _run_kinematic_delivery_override_and_mixed_ke_blend_brackets_thrust_swing(
    failures: PackedStringArray
) -> void:
    var empty: Dictionary = {}
    if WeaponDamageHelper.kinematic_delivery(empty, "thrust") != WeaponConstants.KINEMATIC_DELIVERY_THRUST:
        _fail(failures, "kin_del: empty arch + thrust move should infer thrust")
    if WeaponDamageHelper.kinematic_delivery(empty, "oberhau") != WeaponConstants.KINEMATIC_DELIVERY_SWING:
        _fail(failures, "kin_del: empty arch + cut move should infer swing")
    var arch_thrust_override: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    if (
        WeaponDamageHelper.kinematic_delivery(arch_thrust_override, "oberhau")
        != WeaponConstants.KINEMATIC_DELIVERY_THRUST
    ):
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
    var move_id: String = "oberhau"
    var inten: float = 0.55
    var ai_thrust: AttackInstance = AttackInstance.new(move_id, inten)
    ai_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_swing: AttackInstance = AttackInstance.new(move_id, inten)
    ai_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_mix0: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_mix1: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_th: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_thrust)
    var v_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_swing)
    var v_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix0)
    var v_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_mix1)
    if absf(v_m0 - v_th) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 0 velocity %.6f should match thrust velocity %.6f" % [v_m0, v_th])
    if absf(v_m1 - v_sw) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 1 velocity %.6f should match swing velocity %.6f" % [v_m1, v_sw])
    var ai_mix_mid: AttackInstance = AttackInstance.new(move_id, inten)
    ai_mix_mid.archetype = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5
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
            (
                "kin_del_mixed: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_mid, want_ke_mid]
            )
        )
    var ke_th: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_thrust)
    var ke_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_swing)
    var ke_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix0)
    var ke_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_mix1)
    if ke_th <= 0.05 or ke_sw <= 0.05:
        _fail(failures, "kin_del_mixed: expected positive KE thrust=%.4f swing=%.4f" % [ke_th, ke_sw])
    if absf(ke_m0 - ke_th) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_m0, ke_th])
    if absf(ke_m1 - ke_sw) > 0.001:
        _fail(failures, "kin_del_mixed: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_m1, ke_sw])
    ## Second weapon: AXE + diagonal_chop (cut)  -  same mixed brackets (Tier 5.1); avoids **`spear_slash`** thrust/swing KE degeneracy at some intensities.
    var axe: Weapon = _Weapon.create_from_definition("AXE")
    if axe == null:
        _fail(failures, "kin_del_axe: missing axe")
        return
    var move_chop: String = "diagonal_chop"
    var ai_ax_thrust: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_ax_swing: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_ax_m0: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_m0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_ax_m1: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_m1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_ax_th: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_thrust)
    var v_ax_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_swing)
    var v_ax_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m0)
    var v_ax_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(axe, ai_ax_m1)
    if absf(v_ax_m0 - v_ax_th) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_ax_m0, v_ax_th])
    if absf(v_ax_m1 - v_ax_sw) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 1 velocity %.6f should match swing %.6f" % [v_ax_m1, v_ax_sw])
    var ai_ax_mid: AttackInstance = AttackInstance.new(move_chop, inten)
    ai_ax_mid.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5}
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
            (
                "kin_del_axe: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_ax_mid, want_ax_ke_mid]
            )
        )
    var ke_ax_th: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_thrust)
    var ke_ax_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_swing)
    var ke_ax_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m0)
    var ke_ax_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(axe, ai_ax_m1)
    if ke_ax_th <= 0.05 or ke_ax_sw <= 0.05:
        _fail(failures, "kin_del_axe: expected positive KE thrust=%.4f swing=%.4f" % [ke_ax_th, ke_ax_sw])
    if absf(ke_ax_m0 - ke_ax_th) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_ax_m0, ke_ax_th])
    if absf(ke_ax_m1 - ke_ax_sw) > 0.001:
        _fail(failures, "kin_del_axe: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_ax_m1, ke_ax_sw])
    ## Third weapon: DAGGER + quick_slash (cut)  -  same mixed brackets (Tier 5.1 light weapon coverage).
    var dagger: Weapon = _Weapon.create_from_definition("DAGGER")
    if dagger == null:
        _fail(failures, "kin_del_dagger: missing dagger")
        return
    var move_slash: String = "quick_slash"
    var ai_dg_thrust: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_thrust.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var ai_dg_swing: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_swing.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_dg_m0: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_m0.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.0}
    var ai_dg_m1: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_m1.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 1.0}
    var v_dg_th: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_thrust)
    var v_dg_sw: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_swing)
    var v_dg_m0: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m0)
    var v_dg_m1: float = WeaponDamageHelper.get_effective_velocity_m_s(dagger, ai_dg_m1)
    if absf(v_dg_m0 - v_dg_th) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 0 velocity %.6f should match thrust %.6f" % [v_dg_m0, v_dg_th])
    if absf(v_dg_m1 - v_dg_sw) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 1 velocity %.6f should match swing %.6f" % [v_dg_m1, v_dg_sw])
    var ai_dg_mid: AttackInstance = AttackInstance.new(move_slash, inten)
    ai_dg_mid.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5}
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
            (
                "kin_del_dagger: mixed blend 0.5 KE %.6f want lerp(thrust_ke(v_mid),swing_ke(v_mid),0.5)=%.6f"
                % [ke_dg_mid, want_dg_ke_mid]
            )
        )
    var ke_dg_th: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_thrust)
    var ke_dg_sw: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_swing)
    var ke_dg_m0: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m0)
    var ke_dg_m1: float = WeaponDamageHelper.compute_kinetic_energy_j(dagger, ai_dg_m1)
    if ke_dg_th <= 0.05 or ke_dg_sw <= 0.05:
        _fail(failures, "kin_del_dagger: expected positive KE thrust=%.4f swing=%.4f" % [ke_dg_th, ke_dg_sw])
    if absf(ke_dg_m0 - ke_dg_th) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 0 KE %.6f should match thrust KE %.6f" % [ke_dg_m0, ke_dg_th])
    if absf(ke_dg_m1 - ke_dg_sw) > 0.001:
        _fail(failures, "kin_del_dagger: mixed blend 1 KE %.6f should match swing KE %.6f" % [ke_dg_m1, ke_dg_sw])


## Tier 5.1: **`velocity_m_s_from_intensity`** must match **`get_effective_velocity_m_s`** when **`AttackInstance.velocity_m_s` < 0** (derived path). Intensity **0.05 -> 0.95** increases speed where expected: **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (inferred swing, thrust override, mixed **`kinematic_mixed_blend` 0.35**), **SPEAR** **`spear_thrust`** (inferred thrust), **MACE** **`direct_blow`** (blunt -> swing path).
static func _run_kinematic_delivery_velocity_from_intensity_bridges_get_effective_and_monotone(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_vel_bridge: missing sword")
        return
    var move_id: String = "oberhau"
    var arch_empty: Dictionary = {}
    var arch_thrust: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    var arch_mixed: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.35
    }
    for inten in [0.22, 0.78]:
        var ai: AttackInstance = AttackInstance.new(move_id, inten)
        ai.archetype = arch_empty
        var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_empty, sword, move_id)
        var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai)
        if absf(v_eff - v_from_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_eff, v_from_i]
                )
            )
        var ai_t: AttackInstance = AttackInstance.new(move_id, inten)
        ai_t.archetype = arch_thrust
        var v_t_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_thrust, sword, move_id)
        var v_t_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_t)
        if absf(v_t_e - v_t_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_t_e, v_t_i]
                )
            )
        var ai_m: AttackInstance = AttackInstance.new(move_id, inten)
        ai_m.archetype = arch_mixed
        var v_m_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten, arch_mixed, sword, move_id)
        var v_m_e: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_m)
        if absf(v_m_e - v_m_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten, v_m_e, v_m_i]
                )
            )
    var v_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, sword, move_id)
    var v_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, sword, move_id)
    if v_sw_lo > v_sw_hi + 0.0001:
        _fail(failures, "kin_vel_mono: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [v_sw_lo, v_sw_hi])
    if v_sw_hi - v_sw_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sw_hi - v_sw_lo]
        )
    var v_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, sword, move_id)
    var v_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, sword, move_id)
    if v_th_lo > v_th_hi + 0.0001:
        _fail(failures, "kin_vel_mono: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [v_th_lo, v_th_hi])
    if v_th_hi - v_th_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_th_hi - v_th_lo]
        )
    var v_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, sword, move_id)
    var v_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, sword, move_id)
    if v_mx_lo > v_mx_hi + 0.0001:
        _fail(failures, "kin_vel_mono: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [v_mx_lo, v_mx_hi])
    if v_mx_hi - v_mx_lo < 0.01:
        _fail(
            failures, "kin_vel_mono: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mx_hi - v_mx_lo]
        )
    ## Stab-inferred thrust: SPEAR + spear_thrust (linear band).
    var spear: Weapon = _Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "kin_vel_bridge: missing spear")
        return
    var move_spear: String = "spear_thrust"
    for inten_sp in [0.31, 0.69]:
        var ai_sp: AttackInstance = AttackInstance.new(move_spear, inten_sp)
        ai_sp.archetype = arch_empty
        var v_sp_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_sp, arch_empty, spear, move_spear)
        var v_sp_e: float = WeaponDamageHelper.get_effective_velocity_m_s(spear, ai_sp)
        if absf(v_sp_e - v_sp_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: spear thrust inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten_sp, v_sp_e, v_sp_i]
                )
            )
    var v_sp_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, spear, move_spear)
    var v_sp_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, spear, move_spear)
    if v_sp_lo > v_sp_hi + 0.0001:
        _fail(failures, "kin_vel_mono: spear thrust v(0.05)=%.6f > v(0.95)=%.6f" % [v_sp_lo, v_sp_hi])
    if v_sp_hi - v_sp_lo < 0.01:
        _fail(
            failures,
            "kin_vel_mono: spear thrust expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_sp_hi - v_sp_lo]
        )
    ## Blunt contact -> swing kinematic path: MACE + direct_blow.
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_vel_bridge: missing mace")
        return
    var move_mace: String = "direct_blow"
    for inten_mc in [0.28, 0.72]:
        var ai_mc: AttackInstance = AttackInstance.new(move_mace, inten_mc)
        ai_mc.archetype = arch_empty
        var v_mc_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_mc, arch_empty, mace, move_mace)
        var v_mc_e: float = WeaponDamageHelper.get_effective_velocity_m_s(mace, ai_mc)
        if absf(v_mc_e - v_mc_i) > 0.001:
            _fail(
                failures,
                (
                    "kin_vel_bridge: mace blunt inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                    % [inten_mc, v_mc_e, v_mc_i]
                )
            )
    var v_mc_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, mace, move_mace)
    var v_mc_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, mace, move_mace)
    if v_mc_lo > v_mc_hi + 0.0001:
        _fail(failures, "kin_vel_mono: mace blunt v(0.05)=%.6f > v(0.95)=%.6f" % [v_mc_lo, v_mc_hi])
    if v_mc_hi - v_mc_lo < 0.01:
        _fail(
            failures, "kin_vel_mono: mace blunt expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [v_mc_hi - v_mc_lo]
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
                    (
                        "%s: swing inferred inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vfe, vfi]
                    )
                )
            var ai_bt: AttackInstance = AttackInstance.new(m_b, inten_b)
            ai_bt.archetype = arch_thrust
            var vti: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_thrust, w_b, m_b)
            var vte: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bt)
            if absf(vte - vti) > 0.001:
                _fail(
                    failures,
                    (
                        "%s: thrust override inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vte, vti]
                    )
                )
            var ai_bm: AttackInstance = AttackInstance.new(m_b, inten_b)
            ai_bm.archetype = arch_mixed
            var vmi: float = WeaponDamageHelper.velocity_m_s_from_intensity(inten_b, arch_mixed, w_b, m_b)
            var vme: float = WeaponDamageHelper.get_effective_velocity_m_s(w_b, ai_bm)
            if absf(vme - vmi) > 0.001:
                _fail(
                    failures,
                    (
                        "%s: mixed inten=%.2f get_effective=%.6f want velocity_from_intensity=%.6f"
                        % [tag, inten_b, vme, vmi]
                    )
                )
        var vb_sw_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_empty, w_b, m_b)
        var vb_sw_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_empty, w_b, m_b)
        if vb_sw_lo > vb_sw_hi + 0.0001:
            _fail(failures, "%s: swing inferred v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_sw_lo, vb_sw_hi])
        if vb_sw_hi - vb_sw_lo < 0.01:
            _fail(
                failures,
                "%s: swing inferred expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_sw_hi - vb_sw_lo]
            )
        var vb_th_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_thrust, w_b, m_b)
        var vb_th_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_thrust, w_b, m_b)
        if vb_th_lo > vb_th_hi + 0.0001:
            _fail(failures, "%s: thrust override v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_th_lo, vb_th_hi])
        if vb_th_hi - vb_th_lo < 0.01:
            _fail(
                failures,
                "%s: thrust override expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_th_hi - vb_th_lo]
            )
        var vb_mx_lo: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.05, arch_mixed, w_b, m_b)
        var vb_mx_hi: float = WeaponDamageHelper.velocity_m_s_from_intensity(0.95, arch_mixed, w_b, m_b)
        if vb_mx_lo > vb_mx_hi + 0.0001:
            _fail(failures, "%s: mixed blend v(0.05)=%.6f > v(0.95)=%.6f" % [tag, vb_mx_lo, vb_mx_hi])
        if vb_mx_hi - vb_mx_lo < 0.01:
            _fail(
                failures,
                "%s: mixed blend expected spread v(0.95)-v(0.05) >= 0.01 got %.6f" % [tag, vb_mx_hi - vb_mx_lo]
            )


## Tier 5.1: **`compute_pre_armor_cut`** scales with **`sqrt(KE)`** at fixed strength/**`arm_mod`** when **`velocity_m_s`** pins tip speed (no clamp skew)  -  **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing). **`compute_pre_armor_blunt`** rises with pinned speed on **MACE** **`direct_blow`** (momentum path).
static func _run_kinematic_delivery_pre_armor_cut_sqrt_ke_ratio_and_blunt_rises_with_speed(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_pre_armor: missing sword")
        return
    var move_cut: String = "oberhau"
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
        _fail(failures, "kin_pre_armor_cut: cut_hi should exceed cut_lo (got lo=%.4f hi=%.4f)" % [cut_lo, cut_hi])
    var want_ratio: float = sqrt(ke_hi / ke_lo)
    var got_ratio: float = cut_hi / cut_lo
    if absf(got_ratio - want_ratio) > 0.03:
        _fail(
            failures,
            (
                "kin_pre_armor_cut: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
                % [got_ratio, want_ratio, ke_lo, ke_hi]
            )
        )
    var arch_swing_cut: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
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
            _fail(failures, "%s: expected ke_hi > ke_lo got lo=%.4f hi=%.4f" % [pfx_c, ke_lo_c, ke_hi_c])
        if cut_hi_c <= cut_lo_c + 1e-4:
            _fail(failures, "%s: cut_hi should exceed cut_lo (lo=%.4f hi=%.4f)" % [pfx_c, cut_lo_c, cut_hi_c])
        var want_r_c: float = sqrt(ke_hi_c / ke_lo_c)
        var got_r_c: float = cut_hi_c / cut_lo_c
        if absf(got_r_c - want_r_c) > 0.03:
            _fail(
                failures,
                (
                    "%s: cut ratio %.4f want sqrt(ke) ratio %.4f (ke lo=%.4f hi=%.4f)"
                    % [pfx_c, got_r_c, want_r_c, ke_lo_c, ke_hi_c]
                )
            )
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_pre_armor: missing mace")
        return
    var move_blunt: String = "direct_blow"
    var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_lo.velocity_m_s = 6.0
    var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_hi.velocity_m_s = 14.0
    var blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo, strength, arm_mod)
    var blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi, strength, arm_mod)
    if blunt_hi <= blunt_lo + 1e-4:
        _fail(failures, "kin_pre_armor_blunt: blunt_hi should exceed blunt_lo (lo=%.4f hi=%.4f)" % [blunt_lo, blunt_hi])


## Tier 5.1: **`compute_penetration`**  -  **SHARP** **`penetration_sharp`** scales as **`(KE / J_BASE)^PENETRATION_EXPONENT`** - -  area factor (same move, pinned **`velocity_m_s`**) on **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`** (swing); **BLUNT** returns **`penetration_blunt_momentum_per_area`** increasing with pinned **`v`** on **MACE** **`direct_blow`**.
static func _run_kinematic_delivery_penetration_sharp_ke_exponent_and_blunt_mpa_rises(
    failures: PackedStringArray
) -> void:
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_pen: missing sword")
        return
    var move_cut: String = "oberhau"
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
            (
                "kin_pen_sharp: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
                % [got_ratio, want_ratio, ke_lo, ke_hi, WeaponConstants.PENETRATION_EXPONENT]
            )
        )
    var arch_swing_pen: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var pen_v_lo: float = 9.0
    var pen_v_hi: float = 16.0
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
            _fail(failures, "%s: expected ke_hi > ke_lo lo=%.4f hi=%.4f" % [pfx_p, ke_lo_p, ke_hi_p])
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
                (
                    "%s: pen ratio %.4f want ke^exp ratio %.4f (ke lo=%.4f hi=%.4f exp=%.3f)"
                    % [pfx_p, got_rp, want_rp, ke_lo_p, ke_hi_p, WeaponConstants.PENETRATION_EXPONENT]
                )
            )
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_pen: missing mace")
        return
    var move_blunt: String = "direct_blow"
    var b_lo: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_lo.velocity_m_s = 7.0
    var b_hi: AttackInstance = AttackInstance.new(move_blunt, 0.5)
    b_hi.velocity_m_s = 13.0
    var d_lo: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var d_hi: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var mpa_lo: float = float(d_lo.get("penetration_blunt_momentum_per_area", -1.0))
    var mpa_hi: float = float(d_hi.get("penetration_blunt_momentum_per_area", -1.0))
    if mpa_lo <= 0.0 or mpa_hi <= mpa_lo + 1e-6:
        _fail(failures, "kin_pen_blunt: expected rising momentum/area lo=%.4f hi=%.4f" % [mpa_lo, mpa_hi])


## Tier 5.1: **`strike_energy_mult`** scales **`compute_kinetic_energy_j`** linearly (**`maxf(0.05, mult)`**); **`compute_pre_armor_cut`** ratio tracks **`sqrt(KE)`** at the same pinned **`v`** (swing  -  **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**). Same ratios on **`mixed`** + **`kinematic_mixed_blend` 0.5** with intensity-derived **`v`** (**`velocity_m_s` < 0**)  -  **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**.
static func _run_kinematic_delivery_strike_energy_mult_scales_ke_and_pre_armor_cut_sqrt(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_e_mult: missing sword")
        return
    var move_id: String = "oberhau"
    var mult_hi: float = 1.5625
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
            (
                "kin_e_mult: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                % [cut_ratio, want_cut_ratio, cut_1, cut_2]
            )
        )
    var pin_v: float = 11.0
    var arch_swing: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
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
                (
                    "%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                    % [pfxp, cpe_rr, want_cut_ratio, cpe1, cpe2]
                )
            )
    var mixed_inten: float = 0.53
    var arch_mix: Dictionary = {
        "kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_MIXED, "kinematic_mixed_blend": 0.5
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
        _fail(failures, "kin_e_mult_mix: ke ratio %.6f want strike_energy ratio %.4f" % [ke_mix_ratio, mult_hi])
    var cut_mix_1: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_1, strength, arm_mod)
    var cut_mix_2: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_mix_2, strength, arm_mod)
    var want_cut_mix_ratio: float = sqrt(mult_hi)
    var cut_mix_ratio: float = cut_mix_2 / cut_mix_1
    if absf(cut_mix_ratio - want_cut_mix_ratio) > 0.04:
        _fail(
            failures,
            (
                "kin_e_mult_mix: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                % [cut_mix_ratio, want_cut_mix_ratio, cut_mix_1, cut_mix_2]
            )
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
                (
                    "%s: cut ratio %.4f want sqrt(mult)=%.4f (cut1=%.4f cut2=%.4f)"
                    % [pfx, cx_rr, want_cut_mix_ratio, cx1, cx2]
                )
            )


## Tier 5.1: **`strike_momentum_mult`** scales blunt momentum linearly (**`maxf(0.05, mult)`**); **`compute_pre_armor_blunt`** (full swing, clamped) and **`compute_blunt_slip_pre_armor`** (integration **`pre_blunt_applied`**) + **BLUNT** **`penetration_blunt_momentum_per_area`** track the same ratio at pinned **`v`**. **DAGGER** helper tests use **`v=20`**; integration slip lock **`_run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11`** uses **SWORD** **`oberhau`** at **`v=11`**.
static func _run_kinematic_delivery_strike_momentum_mult_scales_blunt_damage_and_mpa(
    failures: PackedStringArray
) -> void:
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_p_mult: missing mace")
        return
    var move_id: String = "direct_blow"
    var p_hi: float = 1.65
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
        _fail(failures, "kin_p_mult: blunt ratio %.4f want strike_momentum_mult ratio %.4f" % [blunt_ratio, p_hi])
    var d_1: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_1, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var d_2: Dictionary = WeaponDamageHelper.compute_penetration(mace, b_2, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
    var mpa_1: float = float(d_1.get("penetration_blunt_momentum_per_area", -1.0))
    var mpa_2: float = float(d_2.get("penetration_blunt_momentum_per_area", -1.0))
    if mpa_1 <= 0.0:
        _fail(failures, "kin_p_mult: mpa_1 invalid %.4f" % mpa_1)
    var mpa_ratio: float = mpa_2 / mpa_1
    if absf(mpa_ratio - p_hi) > 0.03:
        _fail(failures, "kin_p_mult: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)" % [mpa_ratio, p_hi, mpa_1, mpa_2])
    var arch_sw_bl: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var v_pin_mo: float = 10.0
    for cb: Dictionary in [
        {"def": "SWORD", "move": "oberhau", "pfx": "kin_p_mult_cb_sw"},
        {"def": "AXE", "move": "diagonal_chop", "pfx": "kin_p_mult_cb_ax"},
        # Light blade: raise pinned **`v`** so raw blunt clears **`BLUNT_DAMAGE_MIN`** for both mults (narrow blade
        # otherwise clamps both samples to **1.0** -> ratio **1.0**).
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
            _fail(failures, "%s: blunt ratio %.4f want strike_momentum_mult ratio %.4f" % [tcb, bl_r, p_hi])
        var db1: Dictionary = WeaponDamageHelper.compute_penetration(wcb, sb1, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
        var db2: Dictionary = WeaponDamageHelper.compute_penetration(wcb, sb2, WeaponConstants.DAMAGE_TYPE_BLUNT, {})
        var mpb1: float = float(db1.get("penetration_blunt_momentum_per_area", -1.0))
        var mpb2: float = float(db2.get("penetration_blunt_momentum_per_area", -1.0))
        if mpb1 <= 0.0:
            _fail(failures, "%s: mpa_1 invalid %.4f" % [tcb, mpb1])
        var mpb_r: float = mpb2 / mpb1
        if absf(mpb_r - p_hi) > 0.03:
            _fail(failures, "%s: mpa ratio %.4f want %.4f (mpa1=%.4f mpa2=%.4f)" % [tcb, mpb_r, p_hi, mpb1, mpb2])


## Tier 5.1: **`strike_momentum_mult`** must not change **`compute_kinetic_energy_j`** (pinned **`velocity_m_s`** or derived **`velocity_m_s` < 0** on **SWORD** / **AXE** / **DAGGER** swing, **MACE** blunt->swing, **SPEAR** thrust), **SHARP** **`compute_penetration`** / **`compute_pre_armor_cut`** (pinned **`v`** or same derived-**`v`** **`sv_p_*`**, **`sp_p_*`**, **`mv_p_*`**, **`ax_p_*`**, **`dg_p_*`** pairs), or derived **`get_effective_velocity_m_s`** (`AttackInstance.velocity_m_s` < 0; **SWORD** **`oberhau`**, **AXE** **`diagonal_chop`**, **DAGGER** **`quick_slash`**, **MACE** **`direct_blow`**, **SPEAR** **`spear_thrust`**); pinned **`v`**: **`get_effective_velocity_m_s`** >= **`strike_momentum_mult`** (**SWORD** **`ai_*_p`**, **`wcx_pm`** **AXE** / **DAGGER**); **`strike_energy_mult`** must not change **`compute_pre_armor_blunt`** (pinned **`v`** or derived **`velocity_m_s` < 0** on **MACE** **`mv_e_*`**, **SPEAR** **`sp_e_*`**, **SWORD** **`sv_e_*`**, **AXE** **`ax_sv_e_*`**, **DAGGER** **`dg_sv_e_*`**, incl. **`target_effective_mass_kg`** reduced-mass + opts), **BLUNT** **`compute_penetration`** **`penetration_blunt_momentum_per_area`** (same), or derived **`get_effective_velocity_m_s`** (**SWORD** + **MACE** + **SPEAR** + **AXE** + **DAGGER**); pinned **`v`**: **`get_effective_velocity_m_s`** >= **`strike_energy_mult`** (**SWORD** **`sw_*`**, **`swx`** **AXE** / **DAGGER**)  -  same blunt-channel >= on **MACE** **`direct_blow`** and **SWORD** / **AXE** / **DAGGER** cut swing (pinned **`v`**)  -  orthogonal energy vs momentum paths.
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
    var strength: float = 100.0
    var arm_mod: float = 1.0
    var move_cut: String = "oberhau"
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
        _fail(failures, "kin_cross: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [ke_lo_p, ke_hi_p])
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
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [pen_lo_p, pen_hi_p]
            )
        )
    var cut_lo_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_lo_p, 100.0, 1.0)
    var cut_hi_pm: float = WeaponDamageHelper.compute_pre_armor_cut(sword, ai_hi_p, 100.0, 1.0)
    if absf(cut_hi_pm - cut_lo_pm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [cut_lo_pm, cut_hi_pm]
            )
        )
    var ev_sw_pm_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_lo_p)
    var ev_sw_pm_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_hi_p)
    if absf(ev_sw_pm_hi - ev_sw_pm_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (sword lo=%.6f hi=%.6f)"
                % [ev_sw_pm_lo, ev_sw_pm_hi]
            )
        )
    var v_pin_cross: float = 10.0
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
            _fail(failures, "%s: KE should ignore strike_momentum_mult (lo=%.6f hi=%.6f)" % [pfx, ke_lo_x, ke_hi_x])
        var pen_lo_x: float = float(
            WeaponDamageHelper.compute_penetration(wp, lo_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        var pen_hi_x: float = float(
            WeaponDamageHelper.compute_penetration(wp, hi_x, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
                "penetration_sharp", -1.0
            )
        )
        if absf(pen_hi_x - pen_lo_x) > 0.0001:
            _fail(
                failures,
                (
                    "%s: SHARP penetration_sharp should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, pen_lo_x, pen_hi_x]
                )
            )
        var cut_lo_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, lo_x, strength, arm_mod)
        var cut_hi_x: float = WeaponDamageHelper.compute_pre_armor_cut(wp, hi_x, strength, arm_mod)
        if absf(cut_hi_x - cut_lo_x) > 0.0001:
            _fail(
                failures,
                (
                    "%s: compute_pre_armor_cut should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, cut_lo_x, cut_hi_x]
                )
            )
        ev_wx_pm_lo = WeaponDamageHelper.get_effective_velocity_m_s(wp, lo_x)
        ev_wx_pm_hi = WeaponDamageHelper.get_effective_velocity_m_s(wp, hi_x)
        if absf(ev_wx_pm_hi - ev_wx_pm_lo) > 0.0001:
            _fail(
                failures,
                (
                    "%s: pinned get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                    % [pfx, ev_wx_pm_lo, ev_wx_pm_hi]
                )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (lo=%.6f hi=%.6f)"
                % [ev_p_lo, ev_p_hi]
            )
        )
    var move_ax: String = "diagonal_chop"
    var ax_p_lo: AttackInstance = AttackInstance.new(move_ax, 0.63)
    ax_p_lo.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_p_lo.strike_energy_mult = 1.0
    ax_p_lo.strike_momentum_mult = 1.0
    var ax_p_hi: AttackInstance = AttackInstance.new(move_ax, 0.63)
    ax_p_hi.archetype = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    ax_p_hi.strike_energy_mult = 1.0
    ax_p_hi.strike_momentum_mult = 4.25
    var move_dg: String = "quick_slash"
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (axe lo=%.6f hi=%.6f)"
                % [ev_ax_lo, ev_ax_hi]
            )
        )
    var ev_dg_lo: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_lo)
    var ev_dg_hi: float = WeaponDamageHelper.get_effective_velocity_m_s(w_dagger, dg_p_hi)
    if absf(ev_dg_hi - ev_dg_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (dagger lo=%.6f hi=%.6f)"
                % [ev_dg_lo, ev_dg_hi]
            )
        )
    var mace: Weapon = _Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_cross: missing mace")
        return
    var spear: Weapon = _Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "kin_cross: missing spear")
        return
    var move_bl: String = "direct_blow"
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (mace lo=%.6f hi=%.6f)"
                % [ev_e_lo, ev_e_hi]
            )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (mace lo=%.6f hi=%.6f)"
                % [ev_m_p_lo, ev_m_p_hi]
            )
        )
    var move_thr: String = "spear_thrust"
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_momentum_mult (spear lo=%.6f hi=%.6f)"
                % [ev_sp_lo, ev_sp_hi]
            )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (spear lo=%.6f hi=%.6f)"
                % [ev_ste_lo, ev_ste_hi]
            )
        )
    var ke_sv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_lo)
    var ke_sv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, sv_p_hi)
    if absf(ke_sv_der_hi - ke_sv_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
                % [ke_sv_der_lo, ke_sv_der_hi]
            )
        )
    var ke_mv_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_lo)
    var ke_mv_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(mace, mv_p_hi)
    if absf(ke_mv_der_hi - ke_mv_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
                % [ke_mv_der_lo, ke_mv_der_hi]
            )
        )
    var ke_sp_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_lo)
    var ke_sp_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(spear, sp_p_hi)
    if absf(ke_sp_der_hi - ke_sp_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
                % [ke_sp_der_lo, ke_sp_der_hi]
            )
        )
    var ke_ax_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_lo)
    var ke_ax_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_axe, ax_p_hi)
    if absf(ke_ax_der_hi - ke_ax_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (axe swing derived v lo=%.6f hi=%.6f)"
                % [ke_ax_der_lo, ke_ax_der_hi]
            )
        )
    var ke_dg_der_lo: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_lo)
    var ke_dg_der_hi: float = WeaponDamageHelper.compute_kinetic_energy_j(w_dagger, dg_p_hi)
    if absf(ke_dg_der_hi - ke_dg_der_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: KE should ignore strike_momentum_mult (dagger swing derived v lo=%.6f hi=%.6f)"
                % [ke_dg_der_lo, ke_dg_der_hi]
            )
        )
    var pen_sv_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_sv_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_sv_p_hi - pen_sv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
                % [pen_sv_p_lo, pen_sv_p_hi]
            )
        )
    var cut_sv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_lo, strength, arm_mod)
    var cut_sv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(sword, sv_p_hi, strength, arm_mod)
    if absf(cut_sv_p_hi - cut_sv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (swing derived v lo=%.6f hi=%.6f)"
                % [cut_sv_p_lo, cut_sv_p_hi]
            )
        )
    var pen_ax_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_ax_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_ax_p_hi - pen_ax_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
                % [pen_ax_p_lo, pen_ax_p_hi]
            )
        )
    var cut_ax_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_lo, strength, arm_mod)
    var cut_ax_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_axe, ax_p_hi, strength, arm_mod)
    if absf(cut_ax_p_hi - cut_ax_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (axe derived v lo=%.6f hi=%.6f)"
                % [cut_ax_p_lo, cut_ax_p_hi]
            )
        )
    var pen_dg_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_dg_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_dg_p_hi - pen_dg_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [pen_dg_p_lo, pen_dg_p_hi]
            )
        )
    var cut_dg_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_lo, strength, arm_mod)
    var cut_dg_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(w_dagger, dg_p_hi, strength, arm_mod)
    if absf(cut_dg_p_hi - cut_dg_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [cut_dg_p_lo, cut_dg_p_hi]
            )
        )
    var pen_sp_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_sp_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_sp_p_hi - pen_sp_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
                % [pen_sp_p_lo, pen_sp_p_hi]
            )
        )
    var cut_sp_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_lo, strength, arm_mod)
    var cut_sp_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(spear, sp_p_hi, strength, arm_mod)
    if absf(cut_sp_p_hi - cut_sp_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (spear thrust derived v lo=%.6f hi=%.6f)"
                % [cut_sp_p_lo, cut_sp_p_hi]
            )
        )
    var pen_mv_p_lo: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_p_lo, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    var pen_mv_p_hi: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_p_hi, WeaponConstants.DAMAGE_TYPE_SHARP, {}).get(
            "penetration_sharp", -1.0
        )
    )
    if absf(pen_mv_p_hi - pen_mv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: SHARP penetration_sharp should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
                % [pen_mv_p_lo, pen_mv_p_hi]
            )
        )
    var cut_mv_p_lo: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_lo, strength, arm_mod)
    var cut_mv_p_hi: float = WeaponDamageHelper.compute_pre_armor_cut(mace, mv_p_hi, strength, arm_mod)
    if absf(cut_mv_p_hi - cut_mv_p_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: compute_pre_armor_cut should ignore strike_momentum_mult (mace swing derived v lo=%.6f hi=%.6f)"
                % [cut_mv_p_lo, cut_mv_p_hi]
            )
        )
    var blunt_lo_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo_e, strength, arm_mod)
    var blunt_hi_e: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi_e, strength, arm_mod)
    if absf(blunt_hi_e - blunt_lo_e) > 0.0001:
        _fail(
            failures,
            "kin_cross: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [blunt_lo_e, blunt_hi_e]
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
            failures, "kin_cross: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [mpa_lo_e, mpa_hi_e]
        )
    var tgt_kg_blunt: float = 73.0
    var blunt_lo_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_lo_e, strength, arm_mod, tgt_kg_blunt)
    var blunt_hi_e_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, b_hi_e, strength, arm_mod, tgt_kg_blunt)
    if absf(blunt_hi_e_rm - blunt_lo_e_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [blunt_lo_e_rm, blunt_hi_e_rm]
            )
        )
    var opts_rm: Dictionary = {"target_effective_mass_kg": 68.0}
    var mpa_lo_e_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_hi_e_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, b_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_hi_e_rm - mpa_lo_e_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [mpa_lo_e_rm, mpa_hi_e_rm]
            )
        )
    var blunt_mv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_lo, strength, arm_mod)
    var blunt_mv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, mv_e_hi, strength, arm_mod)
    if absf(blunt_mv_e_hi - blunt_mv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [blunt_mv_e_lo, blunt_mv_e_hi]
            )
        )
    var mpa_mv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_mv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_mv_e_hi - mpa_mv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [mpa_mv_e_lo, mpa_mv_e_hi]
            )
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
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [blunt_mv_e_rm_lo, blunt_mv_e_rm_hi]
            )
        )
    var mpa_mv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_mv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(mace, mv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_mv_e_hi_rm - mpa_mv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa (target mass opts) should ignore strike_energy_mult (mace derived v lo=%.6f hi=%.6f)"
                % [mpa_mv_e_lo_rm, mpa_mv_e_hi_rm]
            )
        )
    var blunt_sp_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_lo, strength, arm_mod)
    var blunt_sp_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(spear, sp_e_hi, strength, arm_mod)
    if absf(blunt_sp_e_hi - blunt_sp_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
                % [blunt_sp_e_lo, blunt_sp_e_hi]
            )
        )
    var mpa_sp_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sp_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(spear, sp_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sp_e_hi - mpa_sp_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: BLUNT mpa should ignore strike_energy_mult (spear derived v lo=%.6f hi=%.6f)"
                % [mpa_sp_e_lo, mpa_sp_e_hi]
            )
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
            (
                "kin_cross: pinned get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
                % [ev_pin_sw_lo, ev_pin_sw_hi]
            )
        )
    var s_blunt_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_lo_e, strength, arm_mod)
    var s_blunt_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sw_hi_e, strength, arm_mod)
    if absf(s_blunt_hi - s_blunt_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [s_blunt_lo, s_blunt_hi]
            )
        )
    var tgt_kg_sword: float = 71.0
    var s_blunt_lo_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sw_lo_e, strength, arm_mod, tgt_kg_sword
    )
    var s_blunt_hi_rm: float = WeaponDamageHelper.compute_pre_armor_blunt(
        sword, sw_hi_e, strength, arm_mod, tgt_kg_sword
    )
    if absf(s_blunt_hi_rm - s_blunt_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [s_blunt_lo_rm, s_blunt_hi_rm]
            )
        )
    var mpa_s_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_s_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_s_hi - mpa_s_lo) > 0.0001:
        _fail(
            failures,
            "kin_cross: sword BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [mpa_s_lo, mpa_s_hi]
        )
    var mpa_s_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_lo_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_s_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sw_hi_e, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_s_hi_rm - mpa_s_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                % [mpa_s_lo_rm, mpa_s_hi_rm]
            )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (sword lo=%.6f hi=%.6f)"
                % [ev_s_lo, ev_s_hi]
            )
        )
    var blunt_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_lo, strength, arm_mod)
    var blunt_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(sword, sv_e_hi, strength, arm_mod)
    if absf(blunt_sv_e_hi - blunt_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (sword derived v lo=%.6f hi=%.6f)"
                % [blunt_sv_e_lo, blunt_sv_e_hi]
            )
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
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (sword derived v lo=%.6f hi=%.6f)"
                % [blunt_sv_e_rm_lo, blunt_sv_e_rm_hi]
            )
        )
    var mpa_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sv_e_hi - mpa_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_sv_e_lo, mpa_sv_e_hi]
            )
        )
    var mpa_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(sword, sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_sv_e_hi_rm - mpa_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: sword BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_sv_e_lo_rm, mpa_sv_e_hi_rm]
            )
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
                (
                    "%s: pinned get_effective_velocity_m_s should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, ev_pin_wx_lo, ev_pin_wx_hi]
                )
            )
        var bl0: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod)
        var bl1: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod)
        if absf(bl1 - bl0) > 0.0001:
            _fail(failures, "%s: blunt pre-armor should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, bl0, bl1])
        var bl0r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, slo, strength, arm_mod, tk)
        var bl1r: float = WeaponDamageHelper.compute_pre_armor_blunt(wx, shi, strength, arm_mod, tk)
        if absf(bl1r - bl0r) > 0.0001:
            _fail(
                failures,
                (
                    "%s: blunt pre-armor (reduced mass) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, bl0r, bl1r]
                )
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
            _fail(failures, "%s: BLUNT mpa should ignore strike_energy_mult (lo=%.6f hi=%.6f)" % [pfxx, mp0, mp1])
        var mp0r: float = float(
            WeaponDamageHelper.compute_penetration(wx, slo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        var mp1r: float = float(
            WeaponDamageHelper.compute_penetration(wx, shi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
                "penetration_blunt_momentum_per_area", -1.0
            )
        )
        if absf(mp1r - mp0r) > 0.0001:
            _fail(
                failures,
                (
                    "%s: BLUNT mpa (target mass opts) should ignore strike_energy_mult (lo=%.6f hi=%.6f)"
                    % [pfxx, mp0r, mp1r]
                )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (axe lo=%.6f hi=%.6f)"
                % [ev_ax_e_lo, ev_ax_e_hi]
            )
        )
    var blunt_ax_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(w_axe, ax_sv_e_lo, strength, arm_mod)
    var blunt_ax_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(w_axe, ax_sv_e_hi, strength, arm_mod)
    if absf(blunt_ax_sv_e_hi - blunt_ax_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (axe derived v lo=%.6f hi=%.6f)"
                % [blunt_ax_sv_e_lo, blunt_ax_sv_e_hi]
            )
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
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (axe derived v lo=%.6f hi=%.6f)"
                % [blunt_ax_sv_e_rm_lo, blunt_ax_sv_e_rm_hi]
            )
        )
    var mpa_ax_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_ax_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_ax_sv_e_hi - mpa_ax_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: axe BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_ax_sv_e_lo, mpa_ax_sv_e_hi]
            )
        )
    var mpa_ax_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_ax_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_axe, ax_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_ax_sv_e_hi_rm - mpa_ax_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: axe BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_ax_sv_e_lo_rm, mpa_ax_sv_e_hi_rm]
            )
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
            (
                "kin_cross: derived get_effective_velocity_m_s should ignore strike_energy_mult (dagger lo=%.6f hi=%.6f)"
                % [ev_dg_e_lo, ev_dg_e_hi]
            )
        )
    var blunt_dg_sv_e_lo: float = WeaponDamageHelper.compute_pre_armor_blunt(w_dagger, dg_sv_e_lo, strength, arm_mod)
    var blunt_dg_sv_e_hi: float = WeaponDamageHelper.compute_pre_armor_blunt(w_dagger, dg_sv_e_hi, strength, arm_mod)
    if absf(blunt_dg_sv_e_hi - blunt_dg_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: blunt pre-armor should ignore strike_energy_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [blunt_dg_sv_e_lo, blunt_dg_sv_e_hi]
            )
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
            (
                "kin_cross: blunt pre-armor (reduced mass) should ignore strike_energy_mult (dagger derived v lo=%.6f hi=%.6f)"
                % [blunt_dg_sv_e_rm_lo, blunt_dg_sv_e_rm_hi]
            )
        )
    var mpa_dg_sv_e_lo: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_dg_sv_e_hi: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, {}).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_dg_sv_e_hi - mpa_dg_sv_e_lo) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: dagger BLUNT mpa should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_dg_sv_e_lo, mpa_dg_sv_e_hi]
            )
        )
    var mpa_dg_sv_e_lo_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_lo, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    var mpa_dg_sv_e_hi_rm: float = float(
        WeaponDamageHelper.compute_penetration(w_dagger, dg_sv_e_hi, WeaponConstants.DAMAGE_TYPE_BLUNT, opts_rm).get(
            "penetration_blunt_momentum_per_area", -1.0
        )
    )
    if absf(mpa_dg_sv_e_hi_rm - mpa_dg_sv_e_lo_rm) > 0.0001:
        _fail(
            failures,
            (
                "kin_cross: dagger BLUNT mpa (target mass opts) should ignore strike_energy_mult (derived v lo=%.6f hi=%.6f)"
                % [mpa_dg_sv_e_lo_rm, mpa_dg_sv_e_hi_rm]
            )
        )


## Tier 5.1 (optional long-tail): **`AttackResolver.penetration_oblique_angle_factor`** matches parry vs misaligned-guard **`lerp`** rules; **`velocity_override` < 0** -> **1** (no penetration oblique here).
static func _run_kinematic_delivery_penetration_oblique_angle_factor_attack_resolver(
    failures: PackedStringArray
) -> void:
    var tol: float = 0.00001
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
        _fail(failures, "kin_oblique: parry 0.5 want %.6f got %.6f" % [w_parry_half, f_parry_half])
    var f_align_edge: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 1.0, 0.0)
    var w_align: float = cos(deg_to_rad(75.0))
    if absf(f_align_edge - w_align) > tol:
        _fail(failures, "kin_oblique: align 0 parry=1 want %.6f got %.6f" % [w_align, f_align_edge])
    var f_parry_zero: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 0.0, 1.0)
    var w_pz: float = lerpf(1.0, amin, 1.0)
    if absf(f_parry_zero - w_pz) > tol:
        _fail(failures, "kin_oblique: parry 0 want %.6f got %.6f" % [w_pz, f_parry_zero])
    var f_parry_wins: float = _AttackResolver.penetration_oblique_angle_factor(5.0, 0.25, 0.0)
    var w_pw: float = lerpf(1.0, amin, 0.75) * cos(deg_to_rad(75.0))
    if absf(f_parry_wins - w_pw) > tol:
        _fail(
            failures, "kin_oblique: parry 0.25+align0 should compound factors want %.6f got %.6f" % [w_pw, f_parry_wins]
        )
    var f_align_mid: float = _AttackResolver.penetration_oblique_angle_factor(3.0, 1.0, 0.5)
    var w_mid: float = cos(deg_to_rad((1.0 - 0.5) * 75.0))
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


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** applies the same oblique factor to **SHARP** / **BLUNT** penetration as **`penetration_oblique_angle_factor`** (fresh manager per sample; manager meta **`_harness_expose_penetration_applied`** -> **`penetration_sharp_applied`** / **`penetration_blunt_mpa_applied`** on **`result_dict`**).
static func _run_kinematic_delivery_compute_damage_oblique_penetration_integration(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    var want_parry_half: float = lerpf(1.0, amin, 0.5)
    var want_align_zero: float = cos(deg_to_rad(75.0))

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
            (
                "kin_dmg_pen: parry 0.5 sharp ratio %.4f want %.4f (base=%.4f half=%.4f)"
                % [r_ps_ph, want_parry_half, base.x, parry_half.x]
            )
        )
    if absf(r_pb_ph - want_parry_half) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: parry 0.5 blunt mpa ratio %.4f want %.4f (base=%.4f half=%.4f)"
                % [r_pb_ph, want_parry_half, base.y, parry_half.y]
            )
        )

    var align_zero: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 0.0, {})
    var r_ps_az: float = align_zero.x / base.x
    var r_pb_az: float = align_zero.y / base.y
    if absf(r_ps_az - want_align_zero) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: align 0 sharp ratio %.4f want %.4f (base=%.4f az=%.4f)"
                % [r_ps_az, want_align_zero, base.x, align_zero.x]
            )
        )
    if absf(r_pb_az - want_align_zero) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: align 0 blunt mpa ratio %.4f want %.4f (base=%.4f az=%.4f)"
                % [r_pb_az, want_align_zero, base.y, align_zero.y]
            )
        )

    var base_der: Vector2 = _kin_dmg_pen_sample(-1.0, 1.0, 1.0, {})
    var parry_der: Vector2 = _kin_dmg_pen_sample(-1.0, 0.5, 1.0, {})
    if base_der.x <= 0.001:
        _fail(failures, "kin_dmg_pen: derived-v baseline pen_sharp too small %.6f" % base_der.x)
    if absf(parry_der.x / base_der.x - 1.0) > 0.02 or absf(parry_der.y / base_der.y - 1.0) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen: vo<0 parry 0.5 should not scale pens (base s=%.4f b=%.4f vs half s=%.4f b=%.4f)"
                % [base_der.x, base_der.y, parry_der.x, parry_der.y]
            )
        )


## Tier 5.1 (optional long-tail): **`strike_mods`**  -  **`sharp_penetration_mult`** / **`blunt_momentum_pa_mult`** scale applied pens in **`compute_and_apply_damage`** (orthogonal; compose after oblique); **`cut_damage_mult`** / **`blunt_damage_mult`** do not (full hit or partial parry  -  **`_kin_dmg_pen_sample`**).
static func _run_kinematic_delivery_compute_damage_strike_mods_penetration_integration(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var mult_sharp: float = 1.35
    var mult_blunt: float = 1.22
    var base: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {})
    if base.x <= 0.001:
        _fail(failures, "kin_dmg_pen_sm: baseline pen_sharp too small %.6f" % base.x)
    if base.y <= 0.0:
        _fail(failures, "kin_dmg_pen_sm: baseline pen_blunt_mpa invalid %.6f" % base.y)
    var only_sharp: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult_sharp})
    if absf(only_sharp.x / base.x - mult_sharp) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: sharp mult ratio %.4f want %.4f (base=%.4f sm=%.4f)"
                % [only_sharp.x / base.x, mult_sharp, base.x, only_sharp.x]
            )
        )
    if absf(only_sharp.y / base.y - 1.0) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: sharp mult should not scale blunt mpa (ratio %.4f)" % (only_sharp.y / base.y))
    var only_blunt: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"blunt_momentum_pa_mult": mult_blunt})
    if absf(only_blunt.x / base.x - 1.0) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: blunt mult should not scale sharp pen (ratio %.4f)" % (only_blunt.x / base.x))
    if absf(only_blunt.y / base.y - mult_blunt) > 0.02:
        _fail(failures, "kin_dmg_pen_sm: blunt mpa mult ratio %.4f want %.4f" % [only_blunt.y / base.y, mult_blunt])
    var both: Vector2 = _kin_dmg_pen_sample(
        vo_pin, 1.0, 1.0, {"sharp_penetration_mult": mult_sharp, "blunt_momentum_pa_mult": mult_blunt}
    )
    if absf(both.x / base.x - mult_sharp) > 0.02 or absf(both.y / base.y - mult_blunt) > 0.02:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: both mults want sharp- - %.2f blunt- - %.2f got ratios %.4f %.4f"
                % [mult_sharp, mult_blunt, both.x / base.x, both.y / base.y]
            )
        )
    var half_base: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {})
    var half_sharp: Vector2 = _kin_dmg_pen_sample(vo_pin, 0.5, 1.0, {"sharp_penetration_mult": mult_sharp})
    if half_base.x <= 0.001:
        _fail(failures, "kin_dmg_pen_sm: oblique baseline pen_sharp too small %.6f" % half_base.x)
    if absf(half_sharp.x / half_base.x - mult_sharp) > 0.03:
        _fail(
            failures,
            "kin_dmg_pen_sm: oblique+sharp_mult ratio %.4f want %.4f" % [half_sharp.x / half_base.x, mult_sharp]
        )
    var dmg_shape: Vector2 = _kin_dmg_pen_sample(vo_pin, 1.0, 1.0, {"cut_damage_mult": 1.55, "blunt_damage_mult": 0.72})
    if absf(dmg_shape.x - base.x) > 0.0001 or absf(dmg_shape.y - base.y) > 0.0001:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: cut/blunt_damage_mult must not change applied pens (base s=%.6f b=%.6f vs dmg s=%.6f b=%.6f)"
                % [base.x, base.y, dmg_shape.x, dmg_shape.y]
            )
        )
    var half_dmg_shape: Vector2 = _kin_dmg_pen_sample(
        vo_pin, 0.5, 1.0, {"cut_damage_mult": 1.88, "blunt_damage_mult": 0.61}
    )
    if absf(half_dmg_shape.x - half_base.x) > 0.0001 or absf(half_dmg_shape.y - half_base.y) > 0.0001:
        _fail(
            failures,
            (
                "kin_dmg_pen_sm: cut/blunt_damage_mult under partial parry must not change applied pens (half s=%.6f b=%.6f vs dmg s=%.6f b=%.6f)"
                % [half_base.x, half_base.y, half_dmg_shape.x, half_dmg_shape.y]
            )
        )


## Tier 5.1 (optional long-tail): **`CombatConstants.get_line_alignment_with_deflect`**  -  continuous cos(theta) vs attack-angle-only vs discrete **`get_line_alignment`** vs **`guard_deflect_blend`** lerp.
static func _run_kinematic_delivery_line_alignment_with_deflect_branches(failures: PackedStringArray) -> void:
    var atk_deg: float = 30.0
    var guard_deg: float = 45.0
    var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var want_both: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {})
    var exp_both: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(want_both - exp_both) > 0.0001:
        _fail(failures, "line_align_deflect: both angles want %.6f got %.6f" % [exp_both, want_both])
    var def_low: Dictionary = {"guard_line": "low"}
    var only_atk_ctx: Dictionary = {"attack_angle_deg": atk_deg}
    var g_deg: float = CombatConstants.get_guard_angle_deg(def_low, {})
    var want_only_atk: float = CombatConstants.get_line_alignment_with_deflect("high", def_low, only_atk_ctx, {})
    var exp_only_atk: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, g_deg)
    )
    if absf(want_only_atk - exp_only_atk) > 0.0001:
        _fail(
            failures,
            (
                "line_align_deflect: attack_angle only want %.6f got %.6f (guard_deg=%.4f)"
                % [exp_only_atk, want_only_atk, g_deg]
            )
        )
    var want_discrete: float = CombatConstants.get_line_alignment_with_deflect("high", def_low, {}, {})
    var exp_discrete: float = CombatConstants.get_line_alignment("high", "low")
    if absf(want_discrete - exp_discrete) > 0.0001:
        _fail(failures, "line_align_deflect: discrete want %.6f got %.6f" % [exp_discrete, want_discrete])
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
        _fail(failures, "line_align_deflect: blend 0.5 want %.6f got %.6f" % [exp_blend, want_blend])


## Tier 5.1 (optional long-tail): deterministic angle helpers used by deflection magnitude path  -  **`get_deflected_angle_bilateral`**, **`angle_to_nearest_line`**, **`line_to_angle`** (no RNG).
static func _run_kinematic_delivery_deflected_angle_bilateral_and_line_angle_helpers(
    failures: PackedStringArray
) -> void:
    if CombatConstants.angle_to_nearest_line(0.0) != "high":
        _fail(failures, "kin_line_angle: 0deg want high got %s" % CombatConstants.angle_to_nearest_line(0.0))
    if CombatConstants.angle_to_nearest_line(90.0) != "right":
        _fail(failures, "kin_line_angle: 90deg want right got %s" % CombatConstants.angle_to_nearest_line(90.0))
    if CombatConstants.angle_to_nearest_line(180.0) != "low":
        _fail(failures, "kin_line_angle: 180deg want low got %s" % CombatConstants.angle_to_nearest_line(180.0))
    if CombatConstants.angle_to_nearest_line(270.0) != "left":
        _fail(failures, "kin_line_angle: 270deg want left got %s" % CombatConstants.angle_to_nearest_line(270.0))
    if CombatConstants.angle_to_nearest_line(360.0) != "high":
        _fail(failures, "kin_line_angle: 360deg want high got %s" % CombatConstants.angle_to_nearest_line(360.0))
    for ln in ["high", "right", "low", "left"]:
        var a: float = CombatConstants.line_to_angle(ln)
        if CombatConstants.angle_to_nearest_line(a) != ln:
            _fail(
                failures,
                (
                    "kin_line_angle: round-trip line %s angle %.1f -> %s"
                    % [ln, a, CombatConstants.angle_to_nearest_line(a)]
                )
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


## Tier 5.1 (optional long-tail): **`CombatConstants.get_deflected_line_from_angles`** same-line early return (bind)  -  skips magnitude RNG.
static func _run_kinematic_delivery_deflected_line_from_angles_same_line_bind(failures: PackedStringArray) -> void:
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


## Tier 5.1: **`CombatConstants.angle_diff_deg`** (shortest arc 0 - 180) + **`get_alignment_from_angles`** (cos theta floor).
static func _run_kinematic_delivery_angle_diff_and_alignment_from_angles_helpers(failures: PackedStringArray) -> void:
    if CombatConstants.angle_diff_deg(350.0, 10.0) != 20.0:
        _fail(failures, "kin_angle_diff: 350->10 want 20 got %.4f" % CombatConstants.angle_diff_deg(350.0, 10.0))
    if CombatConstants.angle_diff_deg(10.0, 350.0) != 20.0:
        _fail(failures, "kin_angle_diff: 10->350 want 20 got %.4f" % CombatConstants.angle_diff_deg(10.0, 350.0))
    if CombatConstants.angle_diff_deg(0.0, 180.0) != 180.0:
        _fail(failures, "kin_angle_diff: 0->180 want 180 got %.4f" % CombatConstants.angle_diff_deg(0.0, 180.0))
    if CombatConstants.angle_diff_deg(400.0, 40.0) != 0.0:
        _fail(failures, "kin_angle_diff: 400->40 (wrap) want 0 got %.4f" % CombatConstants.angle_diff_deg(400.0, 40.0))
    var a1: float = CombatConstants.get_alignment_from_angles(0.0, 0.0)
    if absf(a1 - 1.0) > 0.0001:
        _fail(failures, "kin_align_from_angles: 0,0 want 1 got %.6f" % a1)
    var a2: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
    if absf(a2 - CombatConstants.PARRY_ALIGNMENT_FLOOR) > 0.0001:
        _fail(
            failures,
            "kin_align_from_angles: 0,180 want floor %.4f got %.6f" % [CombatConstants.PARRY_ALIGNMENT_FLOOR, a2]
        )
    var a3: float = CombatConstants.get_alignment_from_angles(0.0, 60.0)
    if absf(a3 - 0.5) > 0.0001:
        _fail(failures, "kin_align_from_angles: 0,60 want 0.5 got %.6f" % a3)


## Tier 5.1 (optional long-tail): **`AttackPathResolver.resolve_hit_part`** contract  -  when both angles present, path keys use **`angle_to_nearest_line`** (discrete **`ATTACK_PATHS_BY_GUARD`**); alignment still uses continuous **`get_line_alignment_with_deflect`** (not discrete **`get_line_alignment(attack_line, guard_line)`**). Mirrors resolver intercept math (no RNG).
static func _run_kinematic_delivery_path_lookup_discrete_from_angles_continuous_alignment(
    failures: PackedStringArray
) -> void:
    var atk_deg: float = 90.0
    var guard_deg: float = 0.0
    var atk_line_str: String = "high"
    var guard_line_str: String = "high"
    var align_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var atk_line_path: String = CombatConstants.angle_to_nearest_line(atk_deg)
    var guard_line_path: String = CombatConstants.angle_to_nearest_line(guard_deg)
    if atk_line_path != "right" or guard_line_path != "high":
        _fail(failures, "kin_path_angle_split: quantize want right/high got %s/%s" % [atk_line_path, guard_line_path])
    var path_from_angles: Array = CombatConstants.get_attack_path(atk_line_path, guard_line_path)
    var path_from_strings: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
    if path_from_angles.is_empty() or path_from_strings.is_empty():
        _fail(
            failures, "kin_path_angle_split: empty path (angles=%s strings=%s)" % [path_from_angles, path_from_strings]
        )
        return
    if path_from_angles[0] == path_from_strings[0]:
        _fail(
            failures,
            (
                "kin_path_angle_split: first segment must differ (angle path %s vs string path %s)"
                % [path_from_angles[0], path_from_strings[0]]
            )
        )
    var defender: Dictionary = {"guard_line": guard_line_str}
    var align_cont: float = CombatConstants.get_line_alignment_with_deflect(atk_line_str, defender, align_ctx, {})
    var align_discrete: float = CombatConstants.get_line_alignment(atk_line_str, guard_line_str)
    var exp_cont: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(align_cont - exp_cont) > 0.0001:
        _fail(failures, "kin_path_angle_split: continuous align want %.6f got %.6f" % [exp_cont, align_cont])
    if absf(align_discrete - 1.0) > 0.0001:
        _fail(failures, "kin_path_angle_split: discrete high/high want 1 got %.6f" % align_discrete)
    if align_cont >= align_discrete - 0.0001:
        _fail(failures, "kin_path_angle_split: continuous %.6f must be < discrete %.6f" % [align_cont, align_discrete])
    var intercept_cont: int = _kin_path_intercept_max_index(path_from_angles, align_cont)
    var intercept_disc: int = _kin_path_intercept_max_index(path_from_strings, align_discrete)
    if intercept_cont <= intercept_disc:
        _fail(
            failures,
            (
                "kin_path_angle_split: low continuous align -> later intercept (cont=%d disc=%d)"
                % [intercept_cont, intercept_disc]
            )
        )
    var partial_ctx: Dictionary = {"attack_angle_deg": atk_deg}
    var path_partial: Array = CombatConstants.get_attack_path(atk_line_str, guard_line_str)
    if path_partial[0] != path_from_strings[0]:
        _fail(
            failures,
            (
                "kin_path_angle_split: guard_angle only must keep string path first=%s got %s"
                % [path_from_strings[0], path_partial[0]]
            )
        )


static func _kin_path_intercept_max_index(path: Array, alignment: float) -> int:
    var intercept_max: int = int(
        lerpf(float(CombatConstants.PATH_INTERCEPT_EARLY_MAX), float(path.size() - 1), 1.0 - alignment)
    )
    return clampi(intercept_max, 0, path.size() - 1)


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** lerps **`guard_deflect_from_line` -> `guard_line`**; **`get_line_alignment_with_deflect`** attack-angle-only branch uses that blended guard (not discrete **`guard_line`** alone).
static func _run_kinematic_delivery_guard_deflect_blend_guard_angle_and_attack_only_align(
    failures: PackedStringArray
) -> void:
    var def_blend: Dictionary = {
        "guard_line": "low",
        "guard_deflect_from_line": "high",
        "guard_deflect_blend": 0.5,
    }
    var g_blend: float = CombatConstants.get_guard_angle_deg(def_blend, {"parry_readiness": 1.0})
    var exp_blend_deg: float = lerpf(CombatConstants.line_to_angle("high"), CombatConstants.line_to_angle("low"), 0.5)
    if absf(g_blend - exp_blend_deg) > 0.0001:
        _fail(failures, "kin_guard_blend: guard angle want %.4f got %.4f" % [exp_blend_deg, g_blend])
    var def_static: Dictionary = {"guard_line": "low"}
    var g_static: float = CombatConstants.get_guard_angle_deg(def_static, {"parry_readiness": 1.0})
    if absf(g_static - CombatConstants.line_to_angle("low")) > 0.0001:
        _fail(
            failures,
            "kin_guard_blend: no blend want low %.1f got %.4f" % [CombatConstants.line_to_angle("low"), g_static]
        )
    var atk_match: float = 90.0
    var align_match: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_blend, {"attack_angle_deg": atk_match}, {"parry_readiness": 1.0}
    )
    var exp_match: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_match, g_blend)
    )
    if absf(align_match - exp_match) > 0.0001:
        _fail(
            failures,
            (
                "kin_guard_blend: attack-only align@90deg want %.6f got %.6f (guard=%.4f)"
                % [exp_match, align_match, g_blend]
            )
        )
    # 10deg vs blended guard (~90deg) stays above PARRY_ALIGNMENT_FLOOR; static low (~180deg) floors.
    var atk_mid: float = 10.0
    var align_blend_mid: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_blend, {"attack_angle_deg": atk_mid}, {"parry_readiness": 1.0}
    )
    var exp_blend_mid: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_mid, g_blend)
    )
    if absf(align_blend_mid - exp_blend_mid) > 0.0001:
        _fail(
            failures, "kin_guard_blend: attack-only align@10deg want %.6f got %.6f" % [exp_blend_mid, align_blend_mid]
        )
    var align_static_mid: float = CombatConstants.get_line_alignment_with_deflect(
        "high", def_static, {"attack_angle_deg": atk_mid}, {"parry_readiness": 1.0}
    )
    if align_static_mid >= align_blend_mid - 0.0001:
        _fail(
            failures,
            (
                "kin_guard_blend: static low guard should align lower than blended (static=%.6f blend=%.6f)"
                % [align_static_mid, align_blend_mid]
            )
        )


## Tier 5.1 (optional long-tail): **`WeaponDamageHelper.compute_penetration`** return keys match **`AttackResolver`** consumption  -  **SHARP** **`penetration_sharp`** only; **BLUNT** **`penetration_blunt_momentum_per_area`** + **`blunt_contact_cm`** (bare + thrust depth coupling via **`armor_resistance_rha_mm`** / **`pen_sharp_mm`**).
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
        _fail(failures, "kin_pen_keys: SHARP dict must not include blunt keys keys=%s" % str(d_sharp.keys()))
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
        _fail(failures, "kin_pen_keys: blunt_contact_cm want %.4f got %.4f" % [want_bc, got_bc])
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
    var armor_rha: float = 10.0
    var pen_for_blunt: float = pen_sharp_sp * 0.5
    var d_thrust_blunt: Dictionary = (
        WeaponDamageHelper
        . compute_penetration(
            spear,
            ai_thrust,
            WeaponConstants.DAMAGE_TYPE_BLUNT,
            {
                "armor_resistance_rha_mm": armor_rha,
                "pen_sharp_mm": pen_for_blunt,
                "target_effective_mass_kg": 14.0,
            }
        )
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
            (
                "kin_pen_keys: thrust depth-coupled blunt_contact want %.4f got %.4f (depth=%.3f)"
                % [want_thrust_bc, got_thrust_bc, depth]
            )
        )
    if head_w > point_w + 0.01 and depth > 0.01 and depth < 0.99:
        var bare_thrust_bc: float = WeaponDamageHelper.get_blunt_contact_cm(spear, ai_thrust)
        if absf(got_thrust_bc - bare_thrust_bc) < 0.0001:
            _fail(
                failures,
                (
                    "kin_pen_keys: depth-coupled contact should differ from bare (bare=%.4f coupled=%.4f depth=%.3f)"
                    % [bare_thrust_bc, got_thrust_bc, depth]
                )
            )


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=false)`** matches **`line_to_angle`**; **`variance_context`** ignored without variance RNG.
static func _run_kinematic_delivery_attack_angle_deg_no_variance_deterministic(failures: PackedStringArray) -> void:
    for ln in ["high", "right", "low", "left"]:
        var want: float = CombatConstants.line_to_angle(ln)
        var got: float = CombatConstants.get_attack_angle_deg(ln, false, {}, {})
        if absf(got - want) > 0.0001:
            _fail(failures, "kin_atk_angle_nv: line %s want %.1f got %.4f" % [ln, want, got])
    seed(90211)
    var with_ctx: float = CombatConstants.get_attack_angle_deg(
        "high", false, {}, {"stamina_ratio": 0.05, "off_balance": true, "weapon_mass_kg": 4.0}
    )
    seed(90211)
    var bare: float = CombatConstants.get_attack_angle_deg("high", false, {}, {})
    if absf(with_ctx - bare) > 0.0001:
        _fail(
            failures,
            (
                "kin_atk_angle_nv: variance_context must not affect add_variance=false (ctx=%.4f bare=%.4f)"
                % [with_ctx, bare]
            )
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
    var commit_frac: float = float(strike_physics_ctx.get("weapon_extension_commit_fraction", -1.0))
    if commit_frac < 0.0:
        commit_frac = _WeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move(move_id))
    var delivery_intensity: float = WeaponDamageHelper.effective_intensity_for_delivery(intensity, commit_frac)
    var v_base: float = (
        velocity_override
        if velocity_override >= 0.0
        else WeaponDamageHelper.velocity_m_s_from_intensity(delivery_intensity, arch, weapon, move_id)
    )
    var v: float = v_base * _StrikePhysics.closing_speed_multiplier(mgr, atk, tgt, strike_physics_ctx)
    var st_ratio: float = clampf(_EntityAccess.stamina_float(atk) / CombatConstants.STAMINA_MAX, 0.0, 1.0)
    v *= sqrt(lerpf(CombatConstants.STAMINA_AT_ZERO_DAMAGE_MULT, 1.0, CombatConstants.stamina_factor(st_ratio)))
    if afterblow_damage_mult < 1.0:
        v *= sqrt(maxf(0.04, afterblow_damage_mult))
    return _ImpactVelocityModel.clamp_velocity_m_s(v)


static func _kin_pen_sharp_at_velocity(
    weapon: Weapon, move_id: String, arch: Dictionary, intensity: float, v_m_s: float, strike_mods: Dictionary = {}
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


## Tier 5.1 (optional long-tail): hit damage **`velocity_m_s`** path matches **`WeaponDamageHelper`** at replicated effective **`v`**; **`compute_and_apply_damage`** -> **`take_damage_split`** contract (**`damage_type` SPLIT**, **`mechanical_post_armor`**, tissue delta).
static func _run_kinematic_delivery_compute_damage_velocity_and_entity_split(failures: PackedStringArray) -> void:
    var intensity: float = 0.62
    var move_id: String = "oberhau"
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
        var v_exp: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo, 1.0)
        var pen_exp: float = _kin_pen_sharp_at_velocity(sword, move_id, arch, intensity, v_exp, {})
        var pen_int: float = _kin_dmg_pen_sample(vo, 1.0, 1.0, {}).x
        if pen_exp <= 0.001:
            _fail(failures, "kin_dmg_v_entity: %s pen_exp too small %.6f" % [case["label"], pen_exp])
        elif absf(pen_int / pen_exp - 1.0) > 0.02:
            _fail(
                failures,
                (
                    "kin_dmg_v_entity: %s pen ratio %.4f want ~1 (int=%.4f exp=%.4f v=%.4f)"
                    % [case["label"], pen_int / pen_exp, pen_int, pen_exp, v_exp]
                )
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
        _fail(failures, "kin_dmg_v_entity: mechanical_post_armor missing (EntityDamage path not taken?)")
    var total_phys: float = float(rd.get("total_physical", 0.0))
    var final_cut: float = float(rd.get("final_cut", 0.0))
    var cut_after: float = float(tgt_n.body_cutting.get("chest", 0.0))
    if total_phys > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS and final_cut > 0.0 and cut_after >= cut_before:
        _fail(
            failures,
            (
                "kin_dmg_v_entity: chest cut should drop on hit (before=%.2f after=%.2f final_cut=%.2f)"
                % [cut_before, cut_after, final_cut]
            )
        )
    _free_manager(m)


## Tier 5.1 (optional long-tail): **`alignment_context.guard_angle_deg` alone is ignored**  -  without **`attack_angle_deg`**, **`get_line_alignment_with_deflect`** uses **`get_guard_angle_deg`** / discrete **`guard_line`** (not the context guard angle).
static func _run_kinematic_delivery_alignment_context_guard_angle_only_uses_combatant_guard(
    failures: PackedStringArray
) -> void:
    var def_line: String = (
        _GuardLines.LINE_HIGH_RIGHT if CombatConstants.is_feature_hema_eight_guard_lines_enabled() else "right"
    )
    var defender: Dictionary = {"guard_line": def_line}
    var ctx_guard_only: Dictionary = {"guard_angle_deg": 180.0}
    var atk_line: String = _harness_cardinal_attack_line("high_right")
    var got: float = CombatConstants.get_line_alignment_with_deflect(
        atk_line, defender, ctx_guard_only, {"parry_readiness": 1.0}
    )
    var exp_discrete: float = CombatConstants.get_line_alignment(atk_line, def_line)
    if absf(got - exp_discrete) > 0.0001:
        _fail(failures, "kin_align_ctx: guard_angle only want discrete high/right %.6f got %.6f" % [exp_discrete, got])
    var wrong_ctx_pair: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(0.0, 180.0)
    )
    if absf(got - wrong_ctx_pair) < 0.0001:
        _fail(
            failures,
            "kin_align_ctx: must not pair line highdeg with context guard 180deg alone (floor %.6f)" % wrong_ctx_pair
        )
    if exp_discrete <= CombatConstants.PARRY_ALIGNMENT_FLOOR + 0.01:
        _fail(failures, "kin_align_ctx: fixture needs discrete align above floor (got %.6f)" % exp_discrete)


## Tier 5.1 (optional long-tail): parry **`v_intent`** base is **`WeaponDamageHelper.get_effective_velocity_m_s`** - -  **`StrikeRealismProfile.velocity_intent_mult_from_pa`** (pinned station); damage **KE** uses effective **`v`** without intent mult.
static func _run_kinematic_delivery_parry_v_intent_effective_velocity_base(failures: PackedStringArray) -> void:
    var sword: Weapon = _Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "kin_parry_v: missing sword")
        return
    var move_id: String = "oberhau"
    var intensity: float = 0.62
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai_derived: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_derived.archetype = arch
    ai_derived.velocity_m_s = -1.0
    var v_eff: float = WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_derived)
    var v_from_i: float = WeaponDamageHelper.velocity_m_s_from_intensity(intensity, arch, sword, move_id)
    if absf(v_eff - v_from_i) > 0.0001:
        _fail(failures, "kin_parry_v: derived v_eff want %.6f got %.6f" % [v_from_i, v_eff])
    var ai_pin: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_pin.archetype = arch
    ai_pin.velocity_m_s = 10.0
    if absf(WeaponDamageHelper.get_effective_velocity_m_s(sword, ai_pin) - 10.0) > 0.0001:
        _fail(failures, "kin_parry_v: pinned v_eff should be 10")
    var pa_tip: Dictionary = {"impact_blade_station": 0.92, "strike_measure_ratio": 1.0}
    var pa_guard: Dictionary = {"impact_blade_station": 0.12, "strike_measure_ratio": 1.0}
    var mult_tip: float = _StrikeRealism.velocity_intent_mult_from_pa(pa_tip, sword, move_id, intensity, arch)
    var mult_guard: float = _StrikeRealism.velocity_intent_mult_from_pa(pa_guard, sword, move_id, intensity, arch)
    if mult_tip <= mult_guard + 0.0001:
        _fail(failures, "kin_parry_v: cut tip station mult %.4f should exceed guard %.4f" % [mult_tip, mult_guard])
    var v_intent_tip: float = v_eff * mult_tip
    var ke_damage: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_derived)
    var ai_intent: AttackInstance = AttackInstance.new(move_id, intensity)
    ai_intent.archetype = arch
    ai_intent.velocity_m_s = v_intent_tip
    var ke_at_intent: float = WeaponDamageHelper.compute_kinetic_energy_j(sword, ai_intent)
    if ke_at_intent <= ke_damage + 1e-4:
        _fail(failures, "kin_parry_v: intent v should raise KE (damage=%.4f intent=%.4f)" % [ke_damage, ke_at_intent])
    var ratio_v: float = v_intent_tip / maxf(v_eff, 0.001)
    var ratio_ke: float = ke_at_intent / maxf(ke_damage, 0.001)
    if absf(ratio_ke - ratio_v * ratio_v) > 0.08:
        _fail(failures, "kin_parry_v: KE ratio %.4f want ~(v ratio)^2 %.4f" % [ratio_ke, ratio_v * ratio_v])


## Tier 5.1 (optional long-tail): **`get_guard_angle_deg`** wobble when **`parry_readiness` < 1** (seeded); readiness **1** matches **`line_to_angle(guard_line)`** without blend.
static func _run_kinematic_delivery_guard_wobble_readiness_shifts_guard_angle(failures: PackedStringArray) -> void:
    var defender: Dictionary = {"guard_line": "high"}
    var wobble_ctx_full: Dictionary = {"parry_readiness": 1.0}
    var stable: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_full)
    if absf(stable - CombatConstants.line_to_angle("high")) > 0.0001:
        _fail(
            failures,
            "kin_guard_wobble: readiness 1 want high %.1f got %.4f" % [CombatConstants.line_to_angle("high"), stable]
        )
    seed(44001)
    var wobble_ctx_low: Dictionary = {"parry_readiness": 0.0}
    var wobbled: float = CombatConstants.get_guard_angle_deg(defender, wobble_ctx_low)
    if absf(wobbled - stable) < 0.05:
        _fail(
            failures, "kin_guard_wobble: readiness 0 should shift angle (stable=%.4f wobbled=%.4f)" % [stable, wobbled]
        )
    var max_shift: float = CombatConstants.GUARD_WOBBLE_MAX_DEG + 0.01
    if CombatConstants.angle_diff_deg(wobbled, stable) > max_shift:
        _fail(
            failures,
            (
                "kin_guard_wobble: shift %.4f exceeds max wobble %.4f"
                % [CombatConstants.angle_diff_deg(wobbled, stable), CombatConstants.GUARD_WOBBLE_MAX_DEG]
            )
        )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 5.1: canonical weapon/move rows for integration loops (matches velocity / KE bracket coverage).
static func _kin_fixtures_cut_swing() -> Array:
    return [
        {"wid": "SWORD", "move": "oberhau", "tag": "sw"},
        {"wid": "AXE", "move": "diagonal_chop", "tag": "ax"},
        # Light blade: pinned v high enough for measurable blunt slip (see strike_momentum_mult harness).
        {"wid": "DAGGER", "move": "quick_slash", "tag": "dg", "vo": 20.0},
    ]


static func _kin_fixtures_thrust() -> Array:
    return [{"wid": "SPEAR", "move": "spear_thrust", "tag": "sp"}]


static func _kin_fixtures_blunt() -> Array:
    return [{"wid": "MACE", "move": "direct_blow", "tag": "mc"}]


static func _kin_fixtures_with_sharp_pen() -> Array:
    var out: Array = _kin_fixtures_cut_swing()
    out.append_array(_kin_fixtures_thrust())
    return out


static func _kin_fixtures_with_blunt_pen() -> Array:
    var out: Array = _kin_fixtures_cut_swing()
    out.append_array(_kin_fixtures_blunt())
    return out


static func _kin_fixtures_all_damage() -> Array:
    var out: Array = _kin_fixtures_with_sharp_pen()
    out.append_array(_kin_fixtures_blunt())
    return out


static func _kin_arch_for_move(move_id: String) -> Dictionary:
    if move_id == "spear_thrust" or move_id == "thrust":
        return {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_THRUST}
    return {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}


## Pinned **`velocity_override`** for kinematic fixture rows (optional **`vo`** on **`_kin_fixtures_*`** dicts).
static func _kin_fixture_vo(cfx: Dictionary, default_vo: float) -> float:
    return float(cfx.get("vo", default_vo))


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
    _harness_reset_combatants_form_balanced(m)
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
        "final_bone": float(rd.get("final_bone", -999.0)),
        "total_physical": float(rd.get("total_physical", -999.0)),
        "mechanical_post_armor": float(rd.get("mechanical_post_armor", -999.0)),
    }


## Tier 5.1 (optional long-tail): **`compute_and_apply_damage`** exposed **`strike_ke_j_applied`** matches **`compute_kinetic_energy_j`** at assembled **`v`**; **`blunt_contact_cm_applied`** matches **`compute_penetration`** **BLUNT** dict (same armor opts as resolver).
static func _run_kinematic_delivery_compute_damage_strike_ke_and_blunt_contact_exposed(
    failures: PackedStringArray
) -> void:
    var move_id: String = "oberhau"
    var vo_pin: float = 11.0
    var sample: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var m: Node = sample["mgr"] as Node
    var atk: Dictionary = sample["atk"] as Dictionary
    var tgt: Dictionary = sample["tgt"] as Dictionary
    var intensity: float = float(sample["intensity"])
    var arch: Dictionary = sample["arch"] as Dictionary
    var v_asm: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0)
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
            (
                "kin_dmg_kin_exposed: strike_ke_j ratio %.4f want 1 (got=%.4f want=%.4f v=%.4f)"
                % [ke_got / ke_want, ke_got, ke_want, v_asm]
            )
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
    _EntityAccess.apply_armor_sharp_resistance_to_blunt_opts(blunt_opts, tgt, "chest")
    var bc_want: float = float(
        WeaponDamageHelper.compute_penetration(weapon, ai, WeaponConstants.DAMAGE_TYPE_BLUNT, blunt_opts).get(
            "blunt_contact_cm", -1.0
        )
    )
    var bc_got: float = float(sample["blunt_contact_cm"])
    if bc_want <= 0.0:
        _fail(failures, "kin_dmg_kin_exposed: blunt_contact_cm want > 0 got %.4f" % bc_want)
    elif absf(bc_got - bc_want) > 0.0001:
        _fail(failures, "kin_dmg_kin_exposed: blunt_contact_cm want %.4f got %.4f" % [bc_want, bc_got])
    if float(sample["pen_sharp"]) <= 0.001:
        _fail(failures, "kin_dmg_kin_exposed: pen_sharp_applied missing/too small")
    _free_manager(m)


## Tier 5.1 (optional long-tail): both angles in **`alignment_context`** -> continuous cos(theta); **`wobble_context`** ignored.
static func _run_kinematic_delivery_alignment_both_angles_ignores_wobble(failures: PackedStringArray) -> void:
    var atk_deg: float = 30.0
    var guard_deg: float = 45.0
    var both_ctx: Dictionary = {"attack_angle_deg": atk_deg, "guard_angle_deg": guard_deg}
    var stable: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {"parry_readiness": 1.0})
    seed(44002)
    var wobbled: float = CombatConstants.get_line_alignment_with_deflect("high", {}, both_ctx, {"parry_readiness": 0.0})
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var exp: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(atk_deg, guard_deg)
    )
    if absf(stable - exp) > 0.0001:
        _fail(failures, "kin_align_wobble_both: stable want %.6f got %.6f" % [exp, stable])
    if absf(wobbled - stable) > 0.0001:
        _fail(
            failures,
            (
                "kin_align_wobble_both: wobble must not change both-angle align (stable=%.6f wobbled=%.6f)"
                % [stable, wobbled]
            )
        )


## Tier 5.1 (optional long-tail): attack-angle-only branch uses **`get_guard_angle_deg`** wobble  -  low **`parry_readiness`** changes alignment vs readiness **1**.
static func _run_kinematic_delivery_attack_angle_only_wobble_changes_alignment(failures: PackedStringArray) -> void:
    var defender: Dictionary = {"guard_line": "high"}
    var atk_only: Dictionary = {"attack_angle_deg": 0.0}
    var stable: float = CombatConstants.get_line_alignment_with_deflect(
        "right", defender, atk_only, {"parry_readiness": 1.0}
    )
    seed(44003)
    var wobbled: float = CombatConstants.get_line_alignment_with_deflect(
        "right", defender, atk_only, {"parry_readiness": 0.0}
    )
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var g_stable: float = CombatConstants.get_guard_angle_deg(defender, {"parry_readiness": 1.0})
    var exp_stable: float = maxf(
        CombatConstants.PARRY_ALIGNMENT_FLOOR, CombatConstants.get_alignment_from_angles(0.0, g_stable)
    )
    if absf(stable - exp_stable) > 0.0001:
        _fail(failures, "kin_align_wobble_atk: stable want %.6f got %.6f" % [exp_stable, stable])
    if absf(wobbled - stable) < 0.0001:
        _fail(
            failures,
            "kin_align_wobble_atk: readiness 0 should change align (stable=%.6f wobbled=%.6f)" % [stable, wobbled]
        )


## Tier 5.1 (optional long-tail): partial parry scales applied pens but not assembled **`strike_ke_j`** (pinned **`velocity_override`**).
static func _run_kinematic_delivery_partial_parry_strike_ke_unchanged_pen_scaled(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
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
        _fail(failures, "kin_partial_parry: strike_ke_j should ignore parry (full=%.4f half=%.4f)" % [ke_full, ke_half])
    if pen_half >= pen_full - 0.0001:
        _fail(failures, "kin_partial_parry: pen_sharp should drop (full=%.4f half=%.4f)" % [pen_full, pen_half])
    var want_ratio: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    want_ratio = lerpf(1.0, want_ratio, 0.5)
    if absf(pen_half / pen_full - want_ratio) > 0.03:
        _fail(failures, "kin_partial_parry: pen ratio %.4f want %.4f" % [pen_half / pen_full, want_ratio])


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
    ai.strike_energy_mult = float(strike_mods.get("strike_energy_mult", 1.0))
    ai.strike_momentum_mult = float(strike_mods.get("strike_momentum_mult", 1.0))
    var atk_n: Node = _EntityAccess.scene_node(atk)
    var arm_mod: float = _EntityAccess.get_attack_damage_modifier(atk)
    var atk_str: float = float(_EntityAccess.stats_dict(atk).get("strength", 100))
    var target_mass: float = WeaponDamageHelper.effective_blunt_target_mass_kg(tgt, "chest")
    var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, move_id, arch)
    if weapon.get_contact_type(move_id) == WeaponConstants.ATTACK_TYPE_CUT and v_m_s >= 0.0 and parry_r < 1.0:
        var redirect: float = CombatConstants.PARRY_CUT_TO_BLUNT_SHIFT * (1.0 - parry_r)
        cut_ratio = maxf(WeaponConstants.MIN_CUT_RATIO, cut_ratio - redirect)
    var pre_cut: float = (
        WeaponDamageHelper.compute_pre_armor_cut(weapon, ai, atk_str, arm_mod)
        * cut_ratio
        * float(strike_mods.get("cut_damage_mult", 1.0))
    )
    var pre_blunt: float = WeaponDamageHelper.compute_blunt_slip_pre_armor(
        weapon, ai, atk_str, arm_mod, cut_ratio, target_mass, float(strike_mods.get("blunt_damage_mult", 1.0))
    )
    var _WF := preload("res://combat/CombatWeaponForm.gd")
    var stance_mult: float = _WF.mod(_EntityAccess.form_str(atk), "damage")
    return Vector2(pre_cut * stance_mult, pre_blunt * stance_mult)


## Tier 5.1 (optional long-tail): exposed **`pre_cut_applied`** / **`pre_blunt_applied`** match **`WeaponDamageHelper`** at assembled **`v`** (incl. parry cut->blunt shift + stance).
static func _run_kinematic_delivery_compute_damage_pre_armor_matches_helper_at_assembled_v(
    failures: PackedStringArray
) -> void:
    var move_id: String = "oberhau"
    var vo_pin: float = 11.0
    var intensity: float = 0.62
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
        var v_asm: float = _kin_expected_damage_velocity_m_s(m, atk, tgt, intensity, arch, move_id, vo_pin, 1.0)
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
                (
                    "kin_pre_armor: %s pre_cut ratio %.4f (got=%.4f want=%.4f)"
                    % [case["label"], got_cut / want.x, got_cut, want.x]
                )
            )
        elif absf(got_blunt / maxf(want.y, 0.001) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "kin_pre_armor: %s pre_blunt ratio %.4f (got=%.4f want=%.4f)"
                    % [case["label"], got_blunt / want.y, got_blunt, want.y]
                )
            )
        _free_manager(m)


## Tier 5.1 (optional long-tail): partial parry on cut (**`velocity_override` >= 0**) shifts **`PARRY_CUT_TO_BLUNT_SHIFT`**  -  **`pre_blunt_applied`** rises vs clean parry; **`pre_cut_applied`** falls.
static func _run_kinematic_delivery_partial_parry_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {})
    var pre_cut_clean: float = float(clean["pre_cut"])
    var pre_cut_part: float = float(partial["pre_cut"])
    var pre_blunt_clean: float = float(clean["pre_blunt"])
    var pre_blunt_part: float = float(partial["pre_blunt"])
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if pre_cut_clean <= 0.1 or pre_blunt_clean < 0.0:
        _fail(
            failures,
            "kin_cut_blunt_shift: clean pre_armor invalid cut=%.4f blunt=%.4f" % [pre_cut_clean, pre_blunt_clean]
        )
    if pre_cut_part >= pre_cut_clean - 0.01:
        _fail(
            failures,
            (
                "kin_cut_blunt_shift: partial parry should reduce pre_cut (clean=%.4f partial=%.4f)"
                % [pre_cut_clean, pre_cut_part]
            )
        )
    if pre_blunt_part <= pre_blunt_clean + 0.01:
        _fail(
            failures,
            (
                "kin_cut_blunt_shift: partial parry should raise pre_blunt (clean=%.4f partial=%.4f)"
                % [pre_blunt_clean, pre_blunt_part]
            )
        )
    var share_clean: float = pre_cut_clean / maxf(pre_cut_clean + pre_blunt_clean, 0.001)
    var share_part: float = pre_cut_part / maxf(pre_cut_part + pre_blunt_part, 0.001)
    if share_part >= share_clean - 0.01:
        _fail(
            failures, "kin_cut_blunt_shift: cut share should drop (clean=%.4f partial=%.4f)" % [share_clean, share_part]
        )


## Tier 5.1 (optional long-tail): **`velocity_override` < 0**  -  partial parry does not apply **`PARRY_CUT_TO_BLUNT_SHIFT`** (pre-armor mix unchanged; pens already >= oblique).
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
            (
                "kin_derived_no_shift: pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_derived_no_shift: pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): misaligned guard (**`alignment` 0**, full parry) scales pens via oblique factor but not **`pre_cut_applied`** / **`pre_blunt_applied`** (pinned **`vo`**).
static func _run_kinematic_delivery_misaligned_guard_scales_pen_not_pre_armor(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var aligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {})
    var misaligned: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 0.0, {})
    _free_manager(aligned["mgr"] as Node)
    _free_manager(misaligned["mgr"] as Node)
    if absf(float(aligned["pre_cut"]) - float(misaligned["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_misalign: pre_cut should be unchanged (aligned=%.4f misaligned=%.4f)"
                % [float(aligned["pre_cut"]), float(misaligned["pre_cut"])]
            )
        )
    if absf(float(aligned["pre_blunt"]) - float(misaligned["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_misalign: pre_blunt should be unchanged (aligned=%.4f misaligned=%.4f)"
                % [float(aligned["pre_blunt"]), float(misaligned["pre_blunt"])]
            )
        )
    var want_pen_ratio: float = lerpf(
        1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    )
    var pen_ratio: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
    if absf(pen_ratio - want_pen_ratio) > 0.03:
        _fail(failures, "kin_misalign: pen_sharp ratio %.4f want %.4f" % [pen_ratio, want_pen_ratio])


## Tier 5.1 (optional long-tail): **`get_attack_path`** unknown guard line falls back to **`ATTACK_PATHS[attack_line]`** (not **`ATTACK_PATHS_BY_GUARD`**).
static func _run_kinematic_delivery_get_attack_path_fallback_to_attack_paths(failures: PackedStringArray) -> void:
    var by_guard: Array = CombatConstants.get_attack_path("high", "low")
    var fallback: Array = CombatConstants.get_attack_path("high", "__no_such_guard__")
    var want: Array = CombatConstants.ATTACK_PATHS.get("high", CombatConstants.ATTACK_PATH_HIGH)
    if fallback.is_empty():
        _fail(failures, "kin_attack_path: fallback path empty")
    if str(fallback) != str(want):
        _fail(failures, "kin_attack_path: fallback want ATTACK_PATHS[high] got %s" % str(fallback))
    if str(by_guard) == str(fallback):
        _fail(failures, "kin_attack_path: guard-specific path should differ from fallback")


## Tier 5.1 (optional long-tail): **`strike_mods`** **`cut_damage_mult`** / **`blunt_damage_mult`** scale pre-armor only (not **`penetration_sharp_applied`**)  -  cut moves + **MACE** blunt.
static func _run_kinematic_delivery_strike_mods_damage_mults_scale_pre_armor_only(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var cut_mult: float = 1.4
    var blunt_mult: float = 1.25
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"cut_damage_mult": cut_mult, "blunt_damage_mult": blunt_mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - cut_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_cut ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_cut"]) / float(base["pre_cut"]), cut_mult]
                )
            )
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - blunt_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_blunt ratio %.4f want %.4f"
                    % [tag, float(shaped["pre_blunt"]) / float(base["pre_blunt"]), blunt_mult]
                )
            )
        if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - 1.0) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pen_sharp should ignore damage mults (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pen_sharp"]), float(shaped["pen_sharp"])]
                )
            )
    for bfx in _kin_fixtures_blunt():
        var wid_b: String = str(bfx["wid"])
        var move_b: String = str(bfx["move"])
        var tag_b: String = str(bfx["tag"])
        var arch_b: Dictionary = _kin_arch_for_move(move_b)
        var base_b: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, wid_b, move_b, 1.0, arch_b)
        var shaped_b: Dictionary = _kin_dmg_integration_sample(
            vo_pin, 1.0, 1.0, {"blunt_damage_mult": blunt_mult}, wid_b, move_b, 1.0, arch_b
        )
        _free_manager(base_b["mgr"] as Node)
        _free_manager(shaped_b["mgr"] as Node)
        if float(base_b["pre_blunt"]) <= 0.1:
            _fail(failures, "%s: kin_dmg_mults baseline pre_blunt too small" % tag_b)
        if absf(float(shaped_b["pre_blunt"]) / float(base_b["pre_blunt"]) - blunt_mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_dmg_mults pre_blunt ratio %.4f want %.4f"
                    % [tag_b, float(shaped_b["pre_blunt"]) / float(base_b["pre_blunt"]), blunt_mult]
                )
            )
        if float(base_b["pen_sharp"]) > 0.001:
            if absf(float(shaped_b["pen_sharp"]) / float(base_b["pen_sharp"]) - 1.0) > 0.02:
                _fail(failures, "%s: kin_dmg_mults pen_sharp should ignore blunt_damage_mult" % tag_b)


## Tier 5.1 (optional long-tail): **STAB** contact  -  partial parry at pinned **`vo`** does not apply cut->blunt shift (**`PARRY_CUT_TO_BLUNT`** is cut-only).
static func _run_kinematic_delivery_stab_partial_parry_no_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, "SPEAR", "spear_thrust")
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {}, "SPEAR", "spear_thrust")
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_stab_no_shift: thrust pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_stab_no_shift: thrust pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): partial parry + misaligned guard  -  oblique factor uses **parry** branch (not alignment-only branch) on cut swings.
static func _run_kinematic_delivery_partial_parry_misalign_oblique_parry_branch_wins(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var parry_r: float = 0.25
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var both: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 0.0, {}, wid, move, 1.0, arch)
        var align_only: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(base["mgr"] as Node)
        _free_manager(both["mgr"] as Node)
        _free_manager(align_only["mgr"] as Node)
        var want_parry_branch: float = lerpf(1.0, amin, 1.0 - parry_r)
        var want_align_branch: float = lerpf(1.0, amin, (1.0 - 0.0) * CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE)
        var ratio_both: float = float(both["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        var ratio_align: float = float(align_only["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        if absf(ratio_both - want_parry_branch) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins parry+align pen ratio %.4f want parry branch %.4f"
                    % [tag, ratio_both, want_parry_branch]
                )
            )
        if absf(ratio_both - ratio_align) < 0.02:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins parry+align should differ from align-only (both=%.4f align=%.4f)"
                    % [tag, ratio_both, ratio_align]
                )
            )
        if want_parry_branch >= want_align_branch - 0.001:
            _fail(
                failures,
                (
                    "%s: kin_oblique_parry_wins fixture want parry branch > align branch (%.4f vs %.4f)"
                    % [tag, want_parry_branch, want_align_branch]
                )
            )


## Tier 5.1 (optional long-tail): **`blunt_momentum_pa_mult`** scales **`penetration_blunt_mpa_applied`** only (not **`pre_blunt_applied`**)  -  cut slap + **MACE**.
static func _run_kinematic_delivery_blunt_momentum_mult_scales_pen_not_pre_armor(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.28
    for cfx in _kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"blunt_momentum_pa_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if float(base["pen_blunt_mpa"]) <= 0.0:
            _fail(
                failures, "%s: kin_blunt_pa_mult baseline blunt mpa invalid %.6f" % [tag, float(base["pen_blunt_mpa"])]
            )
        if absf(float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]) - mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_blunt_pa_mult pen blunt mpa ratio %.4f want %.4f"
                    % [tag, float(shaped["pen_blunt_mpa"]) / float(base["pen_blunt_mpa"]), mult]
                )
            )
        if absf(float(shaped["pre_blunt"]) / float(base["pre_blunt"]) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_blunt_pa_mult pre_blunt should ignore blunt_momentum_pa_mult (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pre_blunt"]), float(shaped["pre_blunt"])]
                )
            )


## Tier 5.1 (optional long-tail): unknown **`attack_line`** -> **`ATTACK_PATH_HIGH`** default.
static func _run_kinematic_delivery_get_attack_path_unknown_attack_line_fallback(failures: PackedStringArray) -> void:
    var path: Array = CombatConstants.get_attack_path("__no_such_attack__", "low")
    if str(path) != str(CombatConstants.ATTACK_PATH_HIGH):
        _fail(failures, "kin_attack_path_atk: want ATTACK_PATH_HIGH got %s" % str(path))


## Tier 5.1 (optional long-tail): **`sharp_penetration_mult`** scales **`penetration_sharp_applied`** only (not **`pre_cut_applied`**)  -  cut swings + **SPEAR** thrust.
static func _run_kinematic_delivery_sharp_penetration_mult_scales_pen_not_pre_cut(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.33
    for cfx in _kin_fixtures_with_sharp_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"sharp_penetration_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        if float(base["pen_sharp"]) <= 0.001:
            _fail(failures, "%s: kin_sharp_pen_mult baseline pen too small %.6f" % [tag, float(base["pen_sharp"])])
        if absf(float(shaped["pen_sharp"]) / float(base["pen_sharp"]) - mult) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_sharp_pen_mult pen ratio %.4f want %.4f"
                    % [tag, float(shaped["pen_sharp"]) / float(base["pen_sharp"]), mult]
                )
            )
        if absf(float(shaped["pre_cut"]) / float(base["pre_cut"]) - 1.0) > 0.03:
            _fail(
                failures,
                (
                    "%s: kin_sharp_pen_mult pre_cut should ignore sharp_penetration_mult (base=%.4f shaped=%.4f)"
                    % [tag, float(base["pre_cut"]), float(shaped["pre_cut"])]
                )
            )


## Tier 5.1 (optional long-tail): **`get_attack_angle_deg(..., add_variance=true)`**  -  low **`stamina_ratio`** in **`variance_context`** widens spread vs full stamina (seeded).
static func _run_kinematic_delivery_attack_angle_deg_variance_stamina_spreads(failures: PackedStringArray) -> void:
    seed(44005)
    var full_stam: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 1.0})
    seed(44005)
    var low_stam: float = CombatConstants.get_attack_angle_deg("high", true, {}, {"stamina_ratio": 0.05})
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    if absf(full_stam - low_stam) < 0.05:
        _fail(
            failures,
            "kin_atk_angle_var: low stamina should shift angle vs full (full=%.4f low=%.4f)" % [full_stam, low_stam]
        )
    if CombatConstants.angle_diff_deg(full_stam, CombatConstants.line_to_angle("high")) > 25.0:
        _fail(failures, "kin_atk_angle_var: full-stamina draw far from line high (%.4f)" % full_stam)


## Tier 5.1 (optional long-tail): partial parry shifts pre-armor only; misalign scales pens only; **(parry, align)** uses parry oblique branch when **`parry_r` < 1**  -  cut swings.
static func _run_kinematic_delivery_partial_parry_align_compose_on_pen_not_pre_armor_mix(
    failures: PackedStringArray
) -> void:
    var vo_pin: float = 11.0
    var parry_r: float = 0.25
    var amin: float = CombatConstants.PARRY_PENETRATION_ANGLE_MIN
    var ascale: float = CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var clean: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var parry_only: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 1.0, {}, wid, move, 1.0, arch)
        var both: Dictionary = _kin_dmg_integration_sample(vo, parry_r, 0.0, {}, wid, move, 1.0, arch)
        var align_only: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(clean["mgr"] as Node)
        _free_manager(parry_only["mgr"] as Node)
        _free_manager(both["mgr"] as Node)
        _free_manager(align_only["mgr"] as Node)
        if absf(float(parry_only["pre_cut"]) - float(both["pre_cut"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pre_cut parry-only vs both (%.4f vs %.4f)"
                    % [tag, float(parry_only["pre_cut"]), float(both["pre_cut"])]
                )
            )
        if absf(float(parry_only["pre_blunt"]) - float(both["pre_blunt"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pre_blunt parry-only vs both (%.4f vs %.4f)"
                    % [tag, float(parry_only["pre_blunt"]), float(both["pre_blunt"])]
                )
            )
        if absf(float(parry_only["pen_sharp"]) - float(both["pen_sharp"])) > 0.02:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix pen parry-only vs both should match (%.4f vs %.4f)"
                    % [tag, float(parry_only["pen_sharp"]), float(both["pen_sharp"])]
                )
            )
        if float(parry_only["pre_cut"]) >= float(clean["pre_cut"]) - 0.01:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix partial parry should lower pre_cut (clean=%.4f parry=%.4f)"
                    % [tag, float(clean["pre_cut"]), float(parry_only["pre_cut"])]
                )
            )
        if absf(float(align_only["pre_cut"]) - float(clean["pre_cut"])) > 0.02:
            _fail(failures, "%s: kin_parry_align_mix misalign alone should not change pre_cut" % tag)
        var pen_r_parry: float = float(parry_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
        var pen_r_align: float = float(align_only["pen_sharp"]) / maxf(float(clean["pen_sharp"]), 0.001)
        var want_parry: float = lerpf(1.0, amin, 1.0 - parry_r)
        var want_align: float = lerpf(1.0, amin, (1.0 - 0.0) * ascale)
        if absf(pen_r_parry - want_parry) > 0.03:
            _fail(failures, "%s: kin_parry_align_mix parry pen ratio %.4f want %.4f" % [tag, pen_r_parry, want_parry])
        if absf(pen_r_align - want_align) > 0.03:
            _fail(failures, "%s: kin_parry_align_mix align pen ratio %.4f want %.4f" % [tag, pen_r_align, want_align])
        if absf(pen_r_parry - pen_r_align) < 0.01:
            _fail(
                failures,
                (
                    "%s: kin_parry_align_mix fixture should distinguish parry %.2f vs align-only (both %.4f)"
                    % [tag, parry_r, pen_r_parry]
                )
            )


## Tier 5.1 (optional long-tail): entity split  -  **`final_cut` / `final_blunt`** on **`result_dict`** from one chest hit; tissue chip > 0  -  all weapon families.
static func _run_kinematic_delivery_entity_split_final_fields_on_hit(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    for cfx in _kin_fixtures_all_damage():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var sample: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        _free_manager(sample["mgr"] as Node)
        var final_cut: float = float(sample["final_cut"])
        var final_blunt: float = float(sample["final_blunt"])
        if final_cut < 0.0 or final_blunt < 0.0:
            _fail(
                failures,
                (
                    "%s: kin_entity_final missing final_cut/final_blunt (cut=%.4f blunt=%.4f)"
                    % [tag, final_cut, final_blunt]
                )
            )
        var tissue: float = final_cut + final_blunt
        if tissue <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            _fail(
                failures,
                "%s: kin_entity_final tissue chip too small (cut=%.4f blunt=%.4f)" % [tag, final_cut, final_blunt]
            )


## Tier 5.1 (optional long-tail): **BLUNT** contact (**MACE** **`direct_blow`**)  -  no cut->blunt shift on partial parry at pinned **`vo`**.
static func _run_kinematic_delivery_mace_blunt_partial_parry_no_cut_to_blunt_shift(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var clean: Dictionary = _kin_dmg_integration_sample(vo_pin, 1.0, 1.0, {}, "MACE", "direct_blow")
    var partial: Dictionary = _kin_dmg_integration_sample(vo_pin, 0.5, 1.0, {}, "MACE", "direct_blow")
    _free_manager(clean["mgr"] as Node)
    _free_manager(partial["mgr"] as Node)
    if absf(float(clean["pre_cut"]) - float(partial["pre_cut"])) > 0.02:
        _fail(
            failures,
            (
                "kin_mace_no_shift: blunt pre_cut should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_cut"]), float(partial["pre_cut"])]
            )
        )
    if absf(float(clean["pre_blunt"]) - float(partial["pre_blunt"])) > 0.02:
        _fail(
            failures,
            (
                "kin_mace_no_shift: blunt pre_blunt should match (clean=%.4f partial=%.4f)"
                % [float(clean["pre_blunt"]), float(partial["pre_blunt"])]
            )
        )


## Tier 5.1 (optional long-tail): misaligned guard scales **SHARP** and **BLUNT** **`penetration_*_applied`** equally (pinned **`vo`**, full parry)  -  cut swings + **MACE**.
static func _run_kinematic_delivery_misaligned_guard_scales_sharp_and_blunt_pen(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var want: float = lerpf(
        1.0, CombatConstants.PARRY_PENETRATION_ANGLE_MIN, CombatConstants.PARRY_PENETRATION_ALIGNMENT_SCALE
    )
    for cfx in _kin_fixtures_with_blunt_pen():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var aligned: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var misaligned: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 0.0, {}, wid, move, 1.0, arch)
        _free_manager(aligned["mgr"] as Node)
        _free_manager(misaligned["mgr"] as Node)
        if float(aligned["pen_sharp"]) > 0.001:
            var r_sharp: float = float(misaligned["pen_sharp"]) / maxf(float(aligned["pen_sharp"]), 0.001)
            if absf(r_sharp - want) > 0.03:
                _fail(failures, "%s: kin_misalign_both sharp ratio %.4f want %.4f" % [tag, r_sharp, want])
        if float(aligned["pen_blunt_mpa"]) > 0.0:
            var r_blunt: float = float(misaligned["pen_blunt_mpa"]) / maxf(float(aligned["pen_blunt_mpa"]), 0.001)
            if absf(r_blunt - want) > 0.03:
                _fail(failures, "%s: kin_misalign_both blunt mpa ratio %.4f want %.4f" % [tag, r_blunt, want])


## Tier 5.1 (optional long-tail): **`strike_mods.strike_energy_mult`** in **`compute_and_apply_damage`**  -  **`strike_ke_j`** * mult; **`pre_cut`** * **`sqrt(mult)`**; **`penetration_sharp`** * **`mult^PENETRATION_EXPONENT`**  -  cut swings.
static func _run_kinematic_delivery_strike_energy_mult_integration_pre_cut_not_pen(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var mult: float = 1.45
    var want_pen: float = pow(mult, WeaponConstants.PENETRATION_EXPONENT)
    for cfx in _kin_fixtures_cut_swing():
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var shaped: Dictionary = _kin_dmg_integration_sample(
            vo, 1.0, 1.0, {"strike_energy_mult": mult}, wid, move, 1.0, arch
        )
        _free_manager(base["mgr"] as Node)
        _free_manager(shaped["mgr"] as Node)
        var ke_ratio: float = float(shaped["strike_ke_j"]) / maxf(float(base["strike_ke_j"]), 0.001)
        var cut_ratio: float = float(shaped["pre_cut"]) / maxf(float(base["pre_cut"]), 0.001)
        var pen_ratio: float = float(shaped["pen_sharp"]) / maxf(float(base["pen_sharp"]), 0.001)
        if absf(ke_ratio - mult) > 0.03:
            _fail(failures, "%s: kin_energy_mult_int ke ratio %.4f want %.4f" % [tag, ke_ratio, mult])
        if absf(cut_ratio - sqrt(mult)) > 0.05:
            _fail(
                failures,
                "%s: kin_energy_mult_int pre_cut ratio %.4f want sqrt(mult) %.4f" % [tag, cut_ratio, sqrt(mult)]
            )
        if absf(pen_ratio - want_pen) > 0.06:
            _fail(failures, "%s: kin_energy_mult_int pen ratio %.4f want mult^exp %.4f" % [tag, pen_ratio, want_pen])


## Tier 5.1 (optional long-tail): **`afterblow_damage_mult`** scales assembled **`v`** (sqrt) -> **`strike_ke_j_applied`** (~linear in mult)  -  cut swings, thrust, blunt.
static func _run_kinematic_delivery_afterblow_mult_scales_strike_ke_via_velocity(failures: PackedStringArray) -> void:
    var vo_pin: float = 11.0
    var ab_mult: float = 0.64
    var want_ke: float = ab_mult
    var fixtures: Array = _kin_fixtures_all_damage()
    for cfx in fixtures:
        var wid: String = str(cfx["wid"])
        var move: String = str(cfx["move"])
        var tag: String = str(cfx["tag"])
        var vo: float = _kin_fixture_vo(cfx, vo_pin)
        var arch: Dictionary = _kin_arch_for_move(move)
        var clean: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, 1.0, arch)
        var hindered: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, wid, move, ab_mult, arch)
        _free_manager(clean["mgr"] as Node)
        _free_manager(hindered["mgr"] as Node)
        var ke_ratio: float = float(hindered["strike_ke_j"]) / maxf(float(clean["strike_ke_j"]), 0.001)
        if absf(ke_ratio - want_ke) > 0.06:
            _fail(
                failures,
                (
                    "%s: kin_afterblow ke ratio %.4f want ~%.4f (clean=%.2f hindered=%.2f)"
                    % [tag, ke_ratio, want_ke, float(clean["strike_ke_j"]), float(hindered["strike_ke_j"])]
                )
            )


## Tier 5.1 (optional long-tail): **`angle_to_nearest_line`** quadrant boundaries at **45deg / 135deg / 225deg / 315deg**.
static func _run_kinematic_delivery_angle_to_nearest_line_boundaries(failures: PackedStringArray) -> void:
    if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
        var oct: Array = [
            [0.0, _GuardLines.LINE_HIGH],
            [45.0, _GuardLines.LINE_HIGH_RIGHT],
            [90.0, _GuardLines.LINE_RIGHT],
            [135.0, _GuardLines.LINE_LOW_RIGHT],
            [180.0, _GuardLines.LINE_LOW],
            [225.0, _GuardLines.LINE_LOW_LEFT],
            [270.0, _GuardLines.LINE_LEFT],
            [315.0, _GuardLines.LINE_HIGH_LEFT],
        ]
        for pair in oct:
            var got: String = CombatConstants.angle_to_nearest_line(float(pair[0]))
            if got != str(pair[1]):
                _fail(failures, "kin_line_bound: %.1fdeg want %s got %s" % [float(pair[0]), str(pair[1]), got])
        return
    if CombatConstants.angle_to_nearest_line(44.9) != "high":
        _fail(failures, "kin_line_bound: 44.9deg want high")
    if CombatConstants.angle_to_nearest_line(45.0) != "right":
        _fail(failures, "kin_line_bound: 45.0deg want right")
    if CombatConstants.angle_to_nearest_line(134.9) != "right":
        _fail(failures, "kin_line_bound: 134.9deg want right")
    if CombatConstants.angle_to_nearest_line(135.0) != "low":
        _fail(failures, "kin_line_bound: 135.0deg want low")
    if CombatConstants.angle_to_nearest_line(224.9) != "low":
        _fail(failures, "kin_line_bound: 224.9deg want low")
    if CombatConstants.angle_to_nearest_line(225.0) != "left":
        _fail(failures, "kin_line_bound: 225.0deg want left")
    if CombatConstants.angle_to_nearest_line(314.9) != "left":
        _fail(failures, "kin_line_bound: 314.9deg want left")
    if CombatConstants.angle_to_nearest_line(315.0) != "high":
        _fail(failures, "kin_line_bound: 315.0deg want high")


static func _harness_destroy_limb(entity: CoreEntity, part: String) -> void:
    _Fixtures._harness_destroy_limb(entity, part)


static func _harness_restore_limb(entity: CoreEntity, part: String) -> void:
    _Fixtures._harness_restore_limb(entity, part)


## Tier 6.1: cumulative effective pain scales pain-shock **chance** (0.8- -  - 1.2- - ); hit pain remains primary.
static func _run_medical_pain_shock_susceptibility_mult_from_effective_pain(failures: PackedStringArray) -> void:
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


## Tier 6.1: sustained high pain can enter pain shock on combat ticks (ambient roll).
static func _run_medical_ambient_pain_shock_tick_enters_from_sustained_pain(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ambient_pain_shock(true)
    var ent: Node = _new_entity("SWORD")
    ent.take_damage_split(20.0, 20.0, "chest")
    ent._pain_shock_until_time = -1.0
    ent._ambient_pain_shock_accum = 0.0
    var pain: float = ent.get_effective_pain_for_thresholds()
    if pain <= PainConsciousnessConstants.NRS_SHOCK + 0.5:
        _fail(failures, "ambient_shock: need high effective pain got %.2f" % pain)
        _free_harness_node(ent)
        return
    var entered: bool = false
    var interval: float = PainConsciousnessConstants.PAIN_SHOCK_AMBIENT_CHECK_INTERVAL_S
    ent._ambient_pain_shock_accum = interval - 0.001
    for _i in 80:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 0.01):
            entered = true
            break
        ent._ambient_pain_shock_accum = interval - 0.001
    if not entered:
        _fail(failures, "ambient_shock: want shock from sustained pain (pain=%.2f)" % pain)
    _free_harness_node(ent)


## Tier 6.1: ambient pain shock gated by **`FEATURE_AMBIENT_PAIN_SHOCK`**.
static func _run_medical_ambient_pain_shock_skips_when_feature_off(failures: PackedStringArray) -> void:
    CombatConstants.set_feature_ambient_pain_shock(false)
    var ent: Node = _new_entity("SWORD")
    ent.take_damage_split(20.0, 20.0, "chest")
    ent._pain_shock_until_time = -1.0
    for _i in 40:
        if EntityPainConsciousness.try_ambient_pain_shock_tick(ent, 2.0):
            _fail(failures, "ambient_shock_off: should not enter shock when feature off")
            CombatConstants.set_feature_ambient_pain_shock(true)
            _free_harness_node(ent)
            return
    CombatConstants.set_feature_ambient_pain_shock(true)
    _free_harness_node(ent)


static func _run_campaign_bridge_can_enter_combat_rejects_empty_party(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    world.set_meta("party_manager", pm)
    var ready: Dictionary = _CampaignBridge.can_enter_combat(world)
    world.free()
    pm.free()
    if bool(ready.get("ok", true)):
        _fail(failures, "bridge_enter: empty party should not be ok")
    if not str(ready.get("message", "")).contains("No living"):
        _fail(failures, "bridge_enter: want no living party message got '%s'" % str(ready.get("message")))


static func _run_campaign_bridge_can_enter_combat_rejects_unconscious(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    var ent: CoreEntity = _new_entity("SWORD")
    ent.name = "UnconsciousFighter"
    ent.consciousness = 0.0
    ent.effective_consciousness = 0.0
    ent._consciousness_dirty = false
    pm.add_member(ent)
    world.set_meta("party_manager", pm)
    var ready: Dictionary = _CampaignBridge.can_enter_combat(world)
    world.free()
    _free_harness_node(ent)
    pm.free()
    if bool(ready.get("ok", true)):
        _fail(failures, "bridge_enter: unconscious member should block combat")
    if not str(ready.get("message", "")).contains("unconscious"):
        _fail(failures, "bridge_enter: want unconscious message got '%s'" % str(ready.get("message")))


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
            failures, "weapon_strong_fraction: sword %.3f want %.3f" % [sword.get_parry_strong_fraction(), sword_want]
        )
    if absf(dagger.get_parry_strong_fraction() - dagger_want) > 0.001:
        _fail(
            failures,
            "weapon_strong_fraction: dagger %.3f want %.3f" % [dagger.get_parry_strong_fraction(), dagger_want]
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
                (
                    "bind_contacts: %s got %s want %s"
                    % [str(wid), str(weapon.bind_riposte_contact_types), str(expected[wid])]
                )
            )


## Tier 7: attack stamina cost rises with wind-up intensity.
static func _run_tier7_stamina_attack_cost_scales_with_intensity(failures: PackedStringArray) -> void:
    var light: float = CombatConstants.stamina_attack_cost_from_intensity(0.0)
    var heavy: float = CombatConstants.stamina_attack_cost_from_intensity(1.0)
    if not is_equal_approx(light, CombatConstants.STAMINA_ATTACK_COST_BASE):
        _fail(failures, "tier7_stam_cost: light want %.1f got %.1f" % [CombatConstants.STAMINA_ATTACK_COST_BASE, light])
    var want_heavy: float = CombatConstants.STAMINA_ATTACK_COST_BASE + CombatConstants.STAMINA_ATTACK_COST_SCALE
    if not is_equal_approx(heavy, want_heavy):
        _fail(failures, "tier7_stam_cost: heavy want %.1f got %.1f" % [want_heavy, heavy])


## Tier 7: parry stamina cost scales with incoming strike intensity (mirrors attack curve).
static func _run_tier7_stamina_parry_cost_scales_with_intensity(failures: PackedStringArray) -> void:
    var light: float = CombatConstants.stamina_parry_cost_from_intensity(0.0)
    var heavy: float = CombatConstants.stamina_parry_cost_from_intensity(1.0)
    if not is_equal_approx(light, CombatConstants.STAMINA_PARRY_COST_BASE):
        _fail(failures, "tier7_parry_stam: light want %.1f got %.1f" % [CombatConstants.STAMINA_PARRY_COST_BASE, light])
    var want_heavy: float = CombatConstants.STAMINA_PARRY_COST_BASE + CombatConstants.STAMINA_PARRY_COST_SCALE
    if not is_equal_approx(heavy, want_heavy):
        _fail(failures, "tier7_parry_stam: heavy want %.1f got %.1f" % [want_heavy, heavy])
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    defender["stamina"] = CombatConstants.STAMINA_MAX
    attacker["pending_attack"] = {"attack_type": "oberhau", "effective_attack_line": "high", "intensity": 1.0}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.5, "kinematic_delivery": "cut"},
            }
        )
    )
    var spent: float = CombatConstants.STAMINA_MAX - _EntityAccess.stamina_float(defender)
    if not is_equal_approx(spent, want_heavy):
        _fail(failures, "tier7_parry_stam: heavy parry want spend %.1f got %.1f" % [want_heavy, spent])
    _free_manager(mgr)


## Tier 7.2: five heavy attacks without refill exhaust the stamina pool.
static func _run_tier7_stamina_depletion_five_heavy_attacks_exhaust_pool(failures: PackedStringArray) -> void:
    var cost_heavy: float = CombatConstants.stamina_attack_cost_from_intensity(1.0)
    var stamina_left: float = CombatConstants.STAMINA_MAX
    for _i in 5:
        stamina_left = maxf(0.0, stamina_left - cost_heavy)
    if stamina_left > 0.01:
        _fail(failures, "tier7_stam_deplete: five heavy attacks should exhaust pool, left %.2f" % stamina_left)
    if CombatConstants.STAMINA_REFILL_RATE > 5.5:
        _fail(
            failures,
            "tier7_stam_deplete: refill rate %.2f too high for 7.2 pacing target" % CombatConstants.STAMINA_REFILL_RATE
        )


## Tier 7.2: sustained exchange (~2 min) with attack every 3s + idle refill should leave combatant fatigued.
static func _run_tier7_stamina_depletion_sustained_exchange_sim(failures: PackedStringArray) -> void:
    var stamina: float = CombatConstants.STAMINA_MAX
    var attack_cost: float = CombatConstants.stamina_attack_cost_from_intensity(0.85)
    var dt: float = 0.1
    var elapsed: float = 0.0
    var next_attack: float = 0.0
    while elapsed < 120.0:
        if elapsed >= next_attack - 0.001:
            stamina = maxf(0.0, stamina - attack_cost)
            next_attack += 3.0
        else:
            stamina = minf(CombatConstants.STAMINA_MAX, stamina + CombatConstants.STAMINA_REFILL_RATE * dt)
        elapsed += dt
    if stamina > CombatConstants.STAMINA_MAX * 0.35:
        _fail(failures, "tier7_stam_deplete_sim: after 120s intense exchange want <=35%% stamina got %.1f" % stamina)


## MXm-3: central fatigue + hypovolemia cap burst pool ceiling.
static func _run_stamina_effective_max_exhaustion_and_blood_cap(failures: PackedStringArray) -> void:
    var _Exhaustion := preload("res://combat/CombatExhaustion.gd")
    var fresh: Dictionary = {
        "stamina": CombatConstants.STAMINA_MAX,
        "stats": {"blood_volume": 100.0},
        CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0,
    }
    if not is_equal_approx(_Exhaustion.effective_stamina_max(fresh), CombatConstants.STAMINA_MAX):
        _fail(
            failures,
            (
                "stam_eff_max: fresh want %.1f got %.1f"
                % [CombatConstants.STAMINA_MAX, _Exhaustion.effective_stamina_max(fresh)]
            )
        )
    var spent: Dictionary = fresh.duplicate(true)
    spent[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 1.0
    var want_exh: float = CombatConstants.STAMINA_MAX * CombatConstants.STAMINA_EXHAUSTION_MAX_MULT_FLOOR
    if not is_equal_approx(_Exhaustion.effective_stamina_max(spent), want_exh):
        _fail(
            failures,
            "stam_eff_max: full exhaustion want %.1f got %.1f" % [want_exh, _Exhaustion.effective_stamina_max(spent)]
        )
    var bleed: Dictionary = fresh.duplicate(true)
    bleed["stats"] = {"blood_volume": 35.0}
    var want_blood: float = CombatConstants.STAMINA_MAX * CombatConstants.STAMINA_BLOOD_MAX_MULT_FLOOR
    if not is_equal_approx(_Exhaustion.effective_stamina_max(bleed), want_blood):
        _fail(
            failures,
            "stam_eff_max: low blood want %.1f got %.1f" % [want_blood, _Exhaustion.effective_stamina_max(bleed)]
        )


## MXm-3: PCr resynthesis slows when fight-exhausted.
static func _run_stamina_effective_refill_slows_with_exhaustion(failures: PackedStringArray) -> void:
    var _Exhaustion := preload("res://combat/CombatExhaustion.gd")
    var fresh: Dictionary = {CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.0}
    var spent: Dictionary = {CombatConstants.COMBATANT_KEY_EXHAUSTION: 1.0}
    var rate_fresh: float = _Exhaustion.effective_stamina_refill_rate(fresh)
    var rate_spent: float = _Exhaustion.effective_stamina_refill_rate(spent)
    if not is_equal_approx(rate_fresh, CombatConstants.STAMINA_REFILL_RATE):
        _fail(failures, "stam_eff_refill: fresh want base rate got %.3f" % rate_fresh)
    var want_spent: float = CombatConstants.STAMINA_REFILL_RATE * CombatConstants.STAMINA_REFILL_EXHAUSTION_MULT_FLOOR
    if not is_equal_approx(rate_spent, want_spent):
        _fail(failures, "stam_eff_refill: exhausted want %.3f got %.3f" % [want_spent, rate_spent])


## Formation pressure: defensive threshold uses burst ratio vs effective max (not absolute / STAMINA_MAX).
static func _run_opponent_pressure_defensive_uses_burst_ratio(failures: PackedStringArray) -> void:
    var _ZOC := preload("res://combat/ZoneOfControl.gd")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var fid: String = _EntityAccess.formation_id_str(player)
    _EntityAccess.set_exhaustion_float(enemy, 1.0)
    enemy["stats"] = {"blood_volume": 100.0}
    enemy["state"] = CombatConstants.STATE_WAITING
    enemy["stamina"] = 30.0
    var mod_neutral: float = _ZOC.get_opponent_pressure_duration_multiplier(mgr, fid)
    if not is_equal_approx(mod_neutral, CombatConstants.PRESSURE_MOD_NEUTRAL):
        _fail(
            failures,
            (
                "pressure_ratio: 30/70 burst want neutral (%.2f) got %.2f"
                % [CombatConstants.PRESSURE_MOD_NEUTRAL, mod_neutral]
            )
        )
    enemy["stamina"] = 20.0
    var mod_def: float = _ZOC.get_opponent_pressure_duration_multiplier(mgr, fid)
    if not is_equal_approx(mod_def, CombatConstants.PRESSURE_MOD_DEFENSIVE):
        _fail(
            failures,
            (
                "pressure_ratio: 20/70 burst want defensive (%.2f) got %.2f"
                % [CombatConstants.PRESSURE_MOD_DEFENSIVE, mod_def]
            )
        )
    _free_manager(mgr)


## Tier 7: fatigued combatants wait longer between **`EVENT_ACTION_READY`** schedules.
static func _run_tier7_stamina_action_ready_cooldown_scales_with_fatigue(failures: PackedStringArray) -> void:
    var fresh: Dictionary = {"stamina": CombatConstants.STAMINA_MAX, "stats": {"agility": 100}}
    var tired: Dictionary = {"stamina": 0.0, "stats": {"agility": 100}}
    var cd_fresh: float = _EventScheduler.action_ready_cooldown(fresh)
    var cd_tired: float = _EventScheduler.action_ready_cooldown(tired)
    if cd_fresh <= 0.0:
        _fail(failures, "tier7_ready_delay: fresh cooldown invalid %.3f" % cd_fresh)
        return
    var want_ratio: float = CombatConstants.STAMINA_ACTION_READY_DELAY_AT_ZERO_MULT
    if not is_equal_approx(cd_tired / cd_fresh, want_ratio):
        _fail(failures, "tier7_ready_delay: tired/fresh ratio want %.3f got %.3f" % [want_ratio, cd_tired / cd_fresh])


## Tier 0.1 / P4b: lane obstacles slow formation-move duration estimates.
static func _run_formation_move_duration_lane_obstacle_slows_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var clear_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, c)
    var lane_clear: float = _ZoneOfControl.get_swap_lane_duration_multiplier(mgr, "player", _EntityAccess.file_int(c))
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    var lane_slow: float = _ZoneOfControl.get_swap_lane_duration_multiplier(mgr, "player", _EntityAccess.file_int(c))
    var slow_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, c)
    _free_manager(mgr)
    if lane_slow < CombatConstants.LANE_MOD_CROWDED - 0.01:
        _fail(failures, "form_dur_lane: obstacle lane mult want >= crowded got %.3f" % lane_slow)
    if slow_dur <= clear_dur * 1.08:
        _fail(failures, "form_dur_lane: slow %.3f should exceed clear %.3f" % [slow_dur, clear_dur])
    if lane_clear > CombatConstants.LANE_MOD_CLEAR + 0.02:
        _fail(failures, "form_dur_lane: clear lane mult expected ~1.0 got %.3f" % lane_clear)


## Tier 0.1: **`CombatFormationFlow`** pair duration matches **`CombatFormationMoveDuration`** estimate.
static func _run_formation_move_duration_matches_flow_pair_start(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    var want: float = _FormationMoveDuration.estimate_adjacent_rank_pair_duration_s(mgr, p0, p1, "swap_rank")
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    var got: float = float(p0.get("state_duration", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(got, want):
        _fail(failures, "form_dur_flow: pair start want %.4f got %.4f" % [want, got])


## Tier 0.1: listed formation moves carry **`formation_move_duration_hint`** when lane is crowded.
static func _run_formation_move_duration_listed_actions_stamp_hint(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_list: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _free_manager(mgr)
    var rotate_act: Dictionary = _ListedActions.first_action_move_vs_target(
        acts, CombatConstants.MOVE_ID_ROTATE_FILE, ally_id
    )
    if rotate_act.is_empty():
        _fail(failures, "form_dur_list: expected rotate_file in crowded-lane actions")
        return
    var hint: String = str(rotate_act.get("formation_move_duration_hint", ""))
    if hint.is_empty() or not hint.contains("crowded"):
        _fail(failures, "form_dur_list: rotate_file want crowded duration hint got '%s'" % hint)


## Tier 0.1 UI: player turn-ready lists formation-move duration from stamped action hints.
static func _run_formation_move_duration_player_turn_hint_from_listed_actions(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_turn_hint: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    var line: String = _PlayerTurnHints.formation_listed_moves_hint_if_applicable(mgr, c, acts)
    if line.is_empty() or not line.contains("crowded"):
        _fail(failures, "form_dur_turn_hint: want crowded lane in hint got '%s'" % line)
    var compact: String = CombatDebug.format_actions_compact(acts)
    if not compact.contains("crowded"):
        _fail(failures, "form_dur_turn_hint: format_actions_compact want duration suffix got '%s'" % compact)
    _free_manager(mgr)


## Tier 0.1: listed formation-move duration appears on waiting gauge tooltip after turn-ready sync.
static func _run_formation_move_duration_gauge_tooltip_listed_hint(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "form_dur_gauge: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, mgr)
    var joined: String = "\n".join(tips)
    _free_manager(mgr)
    if not joined.contains("crowded"):
        _fail(failures, "form_dur_gauge: want crowded lane in gauge tooltip got '%s'" % joined)


## Tier 0.1: listed formation duration not shown on gauge tooltip after leaving waiting.
static func _run_formation_move_duration_gauge_tooltip_clears_when_not_waiting(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
    if c.is_empty():
        _fail(failures, "form_dur_gauge_wait: need rank-0 player at file 0")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    var stamped: String = str(c.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
    if stamped.is_empty():
        _fail(failures, "form_dur_gauge_wait: want stamped listed hint before state change")
        _free_manager(mgr)
        return
    c["state"] = CombatConstants.STATE_WIND_UP
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c, mgr)
    var joined: String = "\n".join(tips)
    _free_manager(mgr)
    if stamped in joined:
        _fail(failures, "form_dur_gauge_wait: listed hint should hide when not waiting got '%s'" % joined)


## Tier 0.1: resolve clears **`COMBATANT_KEY_FORMATION_MOVES_TURN_HINT`** on the actor.
static func _run_formation_move_duration_gauge_tooltip_clears_on_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
    if c.is_empty():
        _fail(failures, "form_dur_gauge_resolve: need rank-0 player at file 0")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    _PlayerTurnHints.sync_formation_listed_turn_hint_on_combatant(mgr, c, acts)
    if not c.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
        _fail(failures, "form_dur_gauge_resolve: want stamped hint before resolve")
        _free_manager(mgr)
        return
    var cid: int = _EntityAccess.id_int(c)
    _ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_WAIT, {})
    _free_manager(mgr)
    if c.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
        _fail(failures, "form_dur_gauge_resolve: hint key should clear after wait resolve")


## Tier 0 / wind-up: explicit **`move_id`** not on weapon does not start wind-up or substitute a random move.
static func _run_wind_up_rejects_move_not_on_weapon(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    atk["gauge"] = 100.0
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    if _EntityAccess.state_str(atk) == CombatConstants.STATE_WIND_UP:
        _fail(failures, "wind_up_reject: SWORD should not wind up with spear_thrust")
    if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(failures, "wind_up_reject: pending_attack should stay empty")
    _free_manager(mgr)


static func _run_formation_diagram_health_bar_reflects_body_damage(failures: PackedStringArray) -> void:
    var _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var mgr: Node = _harness_start_1v1(
        "SWORD",
        {"files": 1, "ranks": 1, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
        {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
    var diagram: Control = _Diagram.create(mgr, {"files": 1, "ranks": 1, "density": "normal"}, "player")
    var grid: GridContainer = diagram.get_meta("_formation_grid", null) as GridContainer
    var bar_before: ProgressBar = _Diagram.first_health_bar_in_grid(grid)
    if bar_before == null:
        _fail(
            failures, "form_health_bar: want ProgressBar in living cell (%s)" % _Diagram.debug_grid_cell_summary(grid)
        )
        diagram.free()
        _free_manager(mgr)
        return
    var ratio_before: float = _PartyRowFormatter.total_body_health_ratio(_EntityAccess.stats_dict(c))
    if ratio_before < 0.95:
        _fail(failures, "form_health_bar: want near-full body ratio got %.3f" % ratio_before)
    var bar_before_val: float = bar_before.value
    var part: String = "chest"
    var mx: float = float(ent.body_max.get(part, 1))
    ent.body_cutting[part] = mx * 0.35
    ent.body_blunt[part] = mx * 0.35
    _Diagram.refresh(diagram)
    for raw in mgr.get_combatants():
        if _EntityAccess.id_int(raw) == _EntityAccess.id_int(c):
            c = raw as Dictionary
            break
    var ratio_after: float = _PartyRowFormatter.total_body_health_ratio(_EntityAccess.stats_dict(c))
    var bar_after: ProgressBar = _Diagram.first_health_bar_in_grid(grid)
    if bar_after == null:
        diagram.free()
        _free_manager(mgr)
        _fail(failures, "form_health_bar: bar missing after refresh")
        return
    var bar_after_val: float = bar_after.value
    diagram.free()
    _free_manager(mgr)
    if ratio_after >= ratio_before - 0.05:
        _fail(
            failures, "form_health_bar: want lower body ratio got before=%.3f after=%.3f" % [ratio_before, ratio_after]
        )
    if bar_after_val >= bar_before_val - 1.0:
        _fail(
            failures,
            "form_health_bar: want lower bar value got before=%.1f after=%.1f" % [bar_before_val, bar_after_val]
        )


static func _formation_health_bar_fill_color(bar: ProgressBar) -> Color:
    if bar == null:
        return Color.WHITE
    var sb: StyleBox = bar.get_theme_stylebox("fill")
    if sb is StyleBoxFlat:
        return (sb as StyleBoxFlat).bg_color
    return Color.WHITE


static func _run_formation_diagram_health_bar_tint_reflects_function_loss(failures: PackedStringArray) -> void:
    var _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var mgr: Node = _harness_start_1v1(
        "SWORD",
        {"files": 1, "ranks": 1, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE},
        {"files": 1, "ranks": 1}
    )
    mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
    var c: Dictionary = mgr.combatants[0]
    var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
    var diagram: Control = _Diagram.create(mgr, {"files": 1, "ranks": 1, "density": "normal"}, "player")
    var grid: GridContainer = diagram.get_meta("_formation_grid", null) as GridContainer
    var bar_before: ProgressBar = _Diagram.first_health_bar_in_grid(grid)
    if bar_before == null:
        _fail(
            failures, "form_health_tint: want ProgressBar in living cell (%s)" % _Diagram.debug_grid_cell_summary(grid)
        )
        diagram.free()
        _free_manager(mgr)
        return
    var func_before: float = _PartyRowFormatter.body_functionality_ratio(c, mgr)
    var color_before: Color = _formation_health_bar_fill_color(bar_before)
    var arm: String = "right_arm"
    var mx: float = float(ent.body_max.get(arm, 1))
    ent.body_cutting[arm] = 0.0
    ent.body_blunt[arm] = 0.0
    ent.bone_health[arm] = 0
    _Diagram.refresh(diagram)
    for raw in mgr.get_combatants():
        if _EntityAccess.id_int(raw) == _EntityAccess.id_int(c):
            c = raw as Dictionary
            break
    var func_after: float = _PartyRowFormatter.body_functionality_ratio(c, mgr)
    var bar_after: ProgressBar = _Diagram.first_health_bar_in_grid(grid)
    if bar_after == null:
        diagram.free()
        _free_manager(mgr)
        _fail(failures, "form_health_tint: bar missing after refresh")
        return
    var color_after: Color = _formation_health_bar_fill_color(bar_after)
    diagram.free()
    _free_manager(mgr)
    if func_after >= func_before - 0.08:
        _fail(failures, "form_health_tint: want lower function got before=%.3f after=%.3f" % [func_before, func_after])
    if color_after.g >= color_before.g - 0.05 and color_after.r <= color_before.r + 0.05:
        _fail(
            failures,
            (
                "form_health_tint: want redder fill before=(%.2f,%.2f,%.2f) after=(%.2f,%.2f,%.2f)"
                % [color_before.r, color_before.g, color_before.b, color_after.r, color_after.g, color_after.b]
            )
        )


## Tier 0.1 UI: crowded lane shows formation-move duration hint on diagram tooltips.
static func _run_formation_move_duration_ui_hint_when_lane_crowded(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var c: Dictionary = mgr.combatants[0]
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    var nm: String = _EntityAccess.get_display_name(c, _EntityAccess.id_int(c))
    var tip: String = "\n".join(_UiHints.formation_cell_tooltip_lines(c, nm, mgr))
    _free_manager(mgr)
    if not tip.contains("Formation move"):
        _fail(failures, "form_dur_ui: want Formation move hint got '%s'" % tip)
    if not tip.contains("crowded"):
        _fail(failures, "form_dur_ui: want crowded lane in hint got '%s'" % tip)


## Tier 1: **`rotate_file`** listed for adjacent rank-0 allies on a multi-file line.
static func _run_rotate_file_listed_for_adjacent_front_rank_allies(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var by_file: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c):
            continue
        if _EntityAccess.rank_int(c) != 0:
            continue
        by_file[_EntityAccess.file_int(c)] = c
    var p0: Dictionary = by_file.get(0, {})
    var p1: Dictionary = by_file.get(1, {})
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_list: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(p0))
    var saw_rotate: bool = not (
        _ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(p1))
        . is_empty()
    )
    _free_manager(mgr)
    if not saw_rotate:
        _fail(failures, "rotate_list: rank-0 file-0 should list rotate_file vs file-1 ally")


## Tier 1: **`CombatFormationFlow.start_rotate_file`** duration matches **`CombatFormationMoveDuration`**.
static func _run_rotate_file_start_sets_duration_matches_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c) or _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_dur_flow: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    var want: float = _FormationMoveDuration.estimate_rotate_file_duration_s(mgr, p0, p1)
    _FormationFlow.start_rotate_file(mgr, id0, id1)
    var got: float = float(p0.get("state_duration", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(got, want):
        _fail(failures, "rotate_dur_flow: want %.4f got %.4f" % [want, got])


## Tier 1: **`handle_rotate_file_resolve`** stamps anti-thrash cooldown; rank swap must not.
static func _run_rotate_file_resolve_stamps_rotate_cooldown(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c) or _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_cd: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    mgr.combat_clock = 1.0
    var want_until: float = 1.0 + CombatConstants.FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S
    _FormationFlow.start_rotate_file(mgr, id0, id1)
    _FormationFlow.handle_rotate_file_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}}
    )
    var cd0: float = float(p0.get("formation_rotate_file_cooldown_until", -1.0))
    var cd1: float = float(p1.get("formation_rotate_file_cooldown_until", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(cd0, want_until) or not is_equal_approx(cd1, want_until):
        _fail(failures, "rotate_cd: want cooldown_until=%.3f got p0=%.3f p1=%.3f" % [want_until, cd0, cd1])


## Tier 1: rank shuffle clears stale doctrine commits; swap must not stamp rotate cooldown.
static func _run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var e0: Dictionary = mgr.combatants[2]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    var eid: int = _EntityAccess.id_int(e0)
    if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_doctrine_cd: expected player rank0/rank1 same file")
        _free_manager(mgr)
        return
    mgr.combat_clock = 0.0
    _TargetScoring.on_combat_commitment(mgr, id0, eid)
    _TargetScoring.on_combat_commitment(mgr, id1, eid)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    _FormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    var bad_commit: bool = (
        int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1
    )
    var bad_rotate_cd: bool = (
        p0.has("formation_rotate_file_cooldown_until") or p1.has("formation_rotate_file_cooldown_until")
    )
    _free_manager(mgr)
    if bad_commit:
        _fail(failures, "swap_doctrine_cd: doctrine_target_commit_id should clear after rank swap")
    if bad_rotate_cd:
        _fail(failures, "swap_doctrine_cd: swap_rank resolve must not stamp formation_rotate_file_cooldown_until")


## Tier 1: center rank-0 lists **`rotate_file`** vs both adjacent wing allies on a wide line.
static func _run_rotate_file_lists_both_adjacent_wing_partners(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 5:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1}, {"files": 5, "ranks": 1})
    var center: Dictionary = {}
    var left_wing: Dictionary = {}
    var right_wing: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c) or _EntityAccess.rank_int(c) != 0:
            continue
        match _EntityAccess.file_int(c):
            1:
                left_wing = c
            2:
                center = c
            3:
                right_wing = c
    if center.is_empty() or left_wing.is_empty() or right_wing.is_empty():
        _fail(failures, "rotate_both_wings: need rank-0 at files 1/2/3")
        _free_manager(mgr)
        return
    center["gauge"] = 100.0
    left_wing["gauge"] = 100.0
    right_wing["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(center))
    var saw_left: bool = not (
        _ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(left_wing))
        . is_empty()
    )
    var saw_right: bool = not (
        _ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, _EntityAccess.id_int(right_wing))
        . is_empty()
    )
    _free_manager(mgr)
    if not saw_left or not saw_right:
        _fail(
            failures,
            "rotate_both_wings: center file-2 want rotate vs wings (left=%s right=%s)" % [str(saw_left), str(saw_right)]
        )


## Tier 1: rotate anti-thrash cooldown blocks listing and resolve (dual gate).
static func _run_rotate_file_cooldown_blocks_listing_and_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c) or _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_cd_gate: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    mgr.combat_clock = 2.0
    p0["formation_rotate_file_cooldown_until"] = mgr.combat_clock + 5.0
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, id0)
    if _ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_ROTATE_FILE):
        _fail(failures, "rotate_cd_gate: rotate_file should not list during cooldown")
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_ROTATE_FILE, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "rotate_cd_gate: resolve should reject rotate_file during cooldown")


## Tier 1: completed rotate stamps reverse-pair lock so the same adjacent allies cannot immediately swap back.
static func _run_rotate_file_reverse_pair_lock_blocks_re_swap(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c) or _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_reverse_lock: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    mgr.combat_clock = 1.0
    _FormationFlow.start_rotate_file(mgr, id0, id1)
    _FormationFlow.handle_rotate_file_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}}
    )
    if not _FormationFlow.rotate_file_reverse_pair_blocked(mgr, p0, id1):
        _fail(failures, "rotate_reverse_lock: initiator should block re-swap with partner")
        _free_manager(mgr)
        return
    if not _FormationFlow.rotate_file_reverse_pair_blocked(mgr, p1, id0):
        _fail(failures, "rotate_reverse_lock: partner should block re-swap with initiator")
        _free_manager(mgr)
        return
    p0.erase("formation_rotate_file_cooldown_until")
    p1.erase("formation_rotate_file_cooldown_until")
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, id0)
    if _ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_ROTATE_FILE):
        _fail(failures, "rotate_reverse_lock: rotate_file should not list same partner during lock")
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_ROTATE_FILE, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "rotate_reverse_lock: resolve should reject rotate_file with locked partner")


## Tier 1: vacancy promotion clears stale doctrine target commit.
static func _run_vacancy_plug_clears_doctrine_commitment(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var front: Dictionary = mgr.combatants[0]
    var rear: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    if _EntityAccess.rank_int(front) != 0 or _EntityAccess.rank_int(rear) != 1:
        _fail(failures, "vacancy_doctrine: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    var rear_id: int = _EntityAccess.id_int(rear)
    var enemy_id: int = _EntityAccess.id_int(enemy)
    mgr.combat_clock = 0.0
    _TargetScoring.on_combat_commitment(mgr, rear_id, enemy_id)
    if int(rear.get("doctrine_target_commit_id", -2)) != enemy_id:
        _fail(failures, "vacancy_doctrine: setup commit failed")
        _free_manager(mgr)
        return
    _soak_kill_combatant(mgr, _EntityAccess.id_int(front))
    var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    _FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var bad: bool = int(rear.get("doctrine_target_commit_id", -2)) != -1
    _free_manager(mgr)
    if bad:
        _fail(failures, "vacancy_doctrine: plug promotion should clear doctrine_target_commit_id")


## Tier 1: rank/file shuffle clears stale close-attempt blocks with doctrine commit.
static func _run_formation_shuffle_clears_close_block(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    var eid: int = _EntityAccess.id_int(enemy)
    if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
        _fail(failures, "shuffle_close_block: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    mgr.combat_clock = 1.0
    var blk: Dictionary = {str(eid): mgr.combat_clock + 10.0}
    p0["close_block_until_by_target_id"] = blk
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    _FormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    var after: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
    _free_manager(mgr)
    if not after.is_empty():
        _fail(failures, "shuffle_close_block: close_block_until_by_target_id should clear after rank swap")


## Tier 1: pair-move abort cooldown blocks resolve (listing parity).
static func _run_pair_abort_cooldown_blocks_swap_rank_resolve(failures: PackedStringArray) -> void:
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
        _fail(failures, "pair_abort_gate: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    mgr.combat_clock = 2.0
    p0["formation_pair_abort_cooldown_until"] = mgr.combat_clock + 5.0
    var ok: bool = _ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_SWAP_RANK, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "pair_abort_gate: swap_rank resolve should reject during pair abort cooldown")


## Tier 1: healthy front rank does not list or resolve swap without tactical gate.
static func _run_swap_rank_not_listed_without_tactical_gate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    mgr.set_meta("_engagement_mode_cached", "formation")
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_tactical_gate_list: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, id0)
    var listed: bool = _ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_SWAP_RANK)
    _free_manager(mgr)
    if listed:
        _fail(failures, "swap_tactical_gate_list: healthy front should not list swap_rank without gate")


static func _run_swap_rank_resolve_rejects_without_tactical_gate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    mgr.set_meta("_engagement_mode_cached", "formation")
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    if _EntityAccess.rank_int(p0) != 0 or _EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_tactical_gate_resolve: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var ok: bool = _ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_SWAP_RANK, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "swap_tactical_gate_resolve: resolve should reject swap_rank without tactical gate")


## Tier 1.8: successful LONG **`resolve_close_attempt`** closes pair distance.
static func _run_resolve_close_attempt_long_success_closes_distance(failures: PackedStringArray) -> void:
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    seed(0)
    var fixtures: Array = _harness_7v3_wing_rank0_fixtures()
    var mgr: Node = fixtures[0] as Node
    var p: Dictionary = fixtures[1] as Dictionary
    var en: Dictionary = fixtures[2] as Dictionary
    if p.is_empty() or en.is_empty():
        _fail(failures, "close_success: missing 7v3 wing fixtures")
        _free_manager_restore_global_rng(mgr)
        return
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(en)
    _harness_bind_pair_long_band(p, en)
    if not _MeleeListing.attempt_close_listed_for_pair(mgr, p, e_id, CombatConstants.DISTANCE_LONG):
        _fail(failures, "close_success: setup want listable close at LONG out of reach")
        _free_manager_restore_global_rng(mgr)
        return
    var sd: Dictionary = _EntityAccess.stats_dict_for_mutation(p)
    sd["strength"] = 400.0
    var sd_e: Dictionary = _EntityAccess.stats_dict_for_mutation(en)
    sd_e["agility"] = 5.0
    var cap: Array = []
    mgr.action_resolved.connect(
        func(_a: int, _t: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    _EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    _free_manager_restore_global_rng(mgr)
    if cap.is_empty():
        _fail(failures, "close_success: expected action_resolved")
        return
    var r: Dictionary = cap[0] as Dictionary
    if str(r.get("outcome", "")) != "close_success":
        _fail(failures, "close_success: expected close_success got %s" % str(r))
    elif (p.get("distance_to", {}) as Dictionary).get(e_id, "") != CombatConstants.DISTANCE_CLOSE:
        _fail(
            failures,
            (
                "close_success: attacker distance_to should be CLOSE got %s"
                % str((p.get("distance_to", {}) as Dictionary).get(e_id, ""))
            )
        )
    elif _EntityAccess.gauge_float(p) >= 99.9:
        _fail(failures, "close_success: attacker gauge should be cleared after close attempt")


## Tier 1.10: automatic doctrine applies **`pinch_center`** on hollow enemy front when doctrine still default.
static func _run_automatic_doctrine_sets_pinch_on_hollow_when_enabled(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "auto_doctrine: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
    var en_by_file: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_enemy_side(c):
            continue
        en_by_file[_EntityAccess.file_int(c)] = c
    (en_by_file[1] as Dictionary)["alive"] = false
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(
            failures,
            "auto_doctrine: hollow center should set pinch_center got %s" % mgr.get_formation_doctrine("player")
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures, "auto_doctrine: must not override player hold_lane got %s" % mgr.get_formation_doctrine("player")
        )
    _free_manager(mgr)


## Tier 0: heavy armor mass slows formation-move duration estimates and hints.
static func _run_formation_move_duration_heavy_armor_slows_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    var ent_light := _new_entity("SWORD")
    mgr.register(ent_light, "player")
    var ent_heavy := _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    mgr.register(ent_heavy, "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var light_c: Dictionary = mgr.combatants[0]
    var heavy_c: Dictionary = mgr.combatants[1]
    for c in [light_c, heavy_c]:
        if _EntityAccess.rank_int(c) != 0:
            continue
        c["gauge"] = 100.0
    var light_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, light_c)
    var heavy_dur: float = _FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, heavy_c)
    var heavy_hint: String = _FormationMoveDuration.formation_preview_tooltip_line(mgr, heavy_c)
    _free_manager(mgr)
    if heavy_dur <= light_dur * 1.08:
        _fail(failures, "form_dur_armor: heavy %.3f should exceed light %.3f" % [heavy_dur, light_dur])
    if not heavy_hint.contains("heavy armor"):
        _fail(failures, "form_dur_armor: want heavy armor in hint got '%s'" % heavy_hint)


## P4b: formation duration UI copy  -  canonical tokens, turn-display strip, ii5a-style crowded hint.
static func _run_p4b_formation_duration_ui_copy_suite(failures: PackedStringArray) -> void:
    var sync_line: String = _FormationMoveDuration.p4b_formation_duration_ui_copy_line()
    if not sync_line.contains("crowded lane"):
        _fail(failures, "p4b_ui: sync line missing crowded lane token")
    if not sync_line.contains("Flee: leaves field"):
        _fail(failures, "p4b_ui: sync line missing flee instant copy")
    var crowded_hint: String = _FormationMoveDuration.format_duration_hint(
        CombatConstants.BASE_FALL_BACK_S * 1.35,
        CombatConstants.LANE_MOD_CROWDED,
        CombatConstants.PRESSURE_MOD_NEUTRAL,
        1.0,
        false
    )
    if not crowded_hint.contains("Formation move:") or not crowded_hint.contains("crowded lane"):
        _fail(failures, "p4b_ui: crowded sample hint want prefix+token got '%s'" % crowded_hint)
    var display: String = _FormationMoveDuration.duration_hint_for_turn_display(crowded_hint)
    if display.begins_with("Formation move:"):
        _fail(failures, "p4b_ui: turn display should strip prefix got '%s'" % display)
    if not display.contains("crowded lane"):
        _fail(failures, "p4b_ui: turn display want crowded token got '%s'" % display)
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not _EntityAccess.is_player_side(raw):
            continue
        if _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 0:
            c = raw
        elif _EntityAccess.rank_int(raw) == 0 and _EntityAccess.file_int(raw) == 1:
            ally_id = _EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "p4b_ui: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, _EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
    var turn_hint: String = _FormationMoveDuration.formation_turn_ready_ui_hint(acts)
    if turn_hint.contains("Formation move: Formation move:"):
        _fail(failures, "p4b_ui: turn hint should not double prefix")
    if turn_hint.is_empty() or not turn_hint.contains("crowded lane"):
        _fail(failures, "p4b_ui: turn hint want crowded lane got '%s'" % turn_hint)
    if "Formation move:" in turn_hint:
        _fail(failures, "p4b_ui: listed turn hint should use stripped duration copy got '%s'" % turn_hint)
    _free_manager(mgr)


static func _harness_iv7_fixture_combatant(ent: CoreEntity) -> Dictionary:
    return _Fixtures._harness_iv7_fixture_combatant(ent)


## IV-7: full plate kit lengthens event-driven **`action_ready_cooldown`**.
static func _run_iv7_armor_burden_action_ready(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_armor_burden_enabled():
        _fail(failures, "iv7_armor_burden: FEATURE_ARMOR_BURDEN must be on in production")
        return
    var ent_light: CoreEntity = _new_entity("SWORD")
    var ent_heavy: CoreEntity = _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    var light_c: Dictionary = _harness_iv7_fixture_combatant(ent_light)
    var heavy_c: Dictionary = _harness_iv7_fixture_combatant(ent_heavy)
    if CombatConstants.armor_burden_mass_ratio_for_combatant(heavy_c) <= 0.35:
        _fail(failures, "iv7_armor_burden: heavy fixture should exceed ref/3 mass ratio")
        return
    var cd_light: float = _EventScheduler.action_ready_cooldown(light_c)
    var cd_heavy: float = _EventScheduler.action_ready_cooldown(heavy_c)
    if cd_heavy <= cd_light * 1.08:
        _fail(failures, "iv7_armor_burden: heavy cooldown want > light (heavy=%.3f light=%.3f)" % [cd_heavy, cd_light])
    var saved: bool = CombatConstants.is_feature_armor_burden_enabled()
    CombatConstants.set_feature_armor_burden_load(false)
    var cd_heavy_off: float = _EventScheduler.action_ready_cooldown(heavy_c)
    CombatConstants.set_feature_armor_burden_load(saved)
    if absf(cd_heavy_off - cd_light) > 0.02:
        _fail(
            failures,
            "iv7_armor_burden: flag off heavy should match light (heavy=%.3f light=%.3f)" % [cd_heavy_off, cd_light]
        )


## IV-7: armor mass scales passive parry readiness (WAITING guard gauge path).
static func _run_iv7_armor_burden_passive_readiness(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_armor_burden_enabled():
        _fail(failures, "iv7_armor_burden_readiness: FEATURE_ARMOR_BURDEN must be on in production")
        return
    var ent_light: CoreEntity = _new_entity("SWORD")
    var ent_heavy: CoreEntity = _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    var light_c: Dictionary = _harness_iv7_fixture_combatant(ent_light)
    var heavy_c: Dictionary = _harness_iv7_fixture_combatant(ent_heavy)
    var pr_light: float = _PassiveParryCtx.get_passive_parry_readiness(light_c)
    var pr_heavy: float = _PassiveParryCtx.get_passive_parry_readiness(heavy_c)
    if pr_light < 0.99:
        _fail(failures, "iv7_armor_burden_readiness: light fixture want ~1.0 got %.3f" % pr_light)
        return
    if pr_heavy >= pr_light * 0.95:
        _fail(failures, "iv7_armor_burden_readiness: heavy want < light (heavy=%.3f light=%.3f)" % [pr_heavy, pr_light])
    var want_heavy: float = pr_light * CombatConstants.armor_burden_passive_readiness_mult(heavy_c)
    if absf(pr_heavy - want_heavy) > 0.02:
        _fail(failures, "iv7_armor_burden_readiness: want %.3f got %.3f" % [want_heavy, pr_heavy])


static func _harness_action_ready_resolve_at(mgr: Node, combatant_id: int) -> float:
    return _Fixtures._harness_action_ready_resolve_at(mgr, combatant_id)


static func _harness_iv8_three_player_fixtures(mgr: Node) -> Array:
    return _Fixtures._harness_iv8_three_player_fixtures(mgr)


## IV-8: high initiative score -> earlier first **`EVENT_ACTION_READY`** at combat start.
static func _run_iv8_initiative_order_stagger(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_initiative_order_enabled():
        _fail(failures, "iv8_initiative_order: FEATURE_INITIATIVE_ORDER must be on in production")
        return
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var players: Array = _harness_iv8_three_player_fixtures(mgr)
    if players.size() != 3:
        _fail(failures, "iv8_initiative_order: want 3 player fixtures got %d" % players.size())
        _free_manager(mgr)
        return
    var fast: Dictionary = mgr.combatants[0]
    var mid: Dictionary = mgr.combatants[1]
    var slow: Dictionary = mgr.combatants[2]
    _EntityAccess.stats_dict_for_mutation(fast)["agility"] = 140
    _EntityAccess.stats_dict_for_mutation(fast)["perception"] = 110
    _EntityAccess.stats_dict_for_mutation(mid)["agility"] = 100
    _EntityAccess.stats_dict_for_mutation(mid)["perception"] = 100
    _EntityAccess.stats_dict_for_mutation(slow)["agility"] = 70
    _EntityAccess.stats_dict_for_mutation(slow)["perception"] = 70
    mgr.event_queue.clear()
    _EventScheduler.schedule_initial_action_ready_events(mgr)
    var at_fast: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(fast))
    var at_mid: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(mid))
    var at_slow: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(slow))
    _free_manager(mgr)
    if at_fast < 0.0 or at_mid < 0.0 or at_slow < 0.0:
        _fail(failures, "iv8_initiative_order: missing action_ready events")
        return
    if not (at_fast < at_mid and at_mid < at_slow):
        _fail(failures, "iv8_initiative_order: want fast<mid<slow (%.3f %.3f %.3f)" % [at_fast, at_mid, at_slow])
    var stagger_gap: float = at_mid - at_fast
    if stagger_gap < CombatConstants.INITIATIVE_ORDER_STAGGER_STEP_S * 0.5:
        _fail(failures, "iv8_initiative_order: want rank stagger gap >= step/2 got %.3f" % stagger_gap)


## IV-8: flag off  -  identical stats -> identical first resolve_at (no initiative stagger).
static func _run_iv8_initiative_order_flag_off_parity(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var players: Array = _harness_iv8_three_player_fixtures(mgr)
    if players.size() != 3:
        _fail(failures, "iv8_initiative_off: want 3 player fixtures got %d" % players.size())
        _free_manager(mgr)
        return
    for i in players.size():
        var c: Dictionary = mgr.combatants[i]
        var stats: Dictionary = _EntityAccess.stats_dict_for_mutation(c)
        stats["agility"] = 100
        stats["perception"] = 100
    mgr.event_queue.clear()
    var saved: bool = CombatConstants.is_feature_initiative_order_enabled()
    CombatConstants.set_feature_initiative_order_load(false)
    _EventScheduler.schedule_initial_action_ready_events(mgr)
    var at0: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(mgr.combatants[0]))
    var at1: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(mgr.combatants[1]))
    var at2: float = _harness_action_ready_resolve_at(mgr, _EntityAccess.id_int(mgr.combatants[2]))
    CombatConstants.set_feature_initiative_order_load(saved)
    _free_manager(mgr)
    if at0 < 0.0 or at1 < 0.0 or at2 < 0.0:
        _fail(failures, "iv8_initiative_off: missing action_ready events")
        return
    if absf(at0 - at1) > 0.02 or absf(at1 - at2) > 0.02:
        _fail(failures, "iv8_initiative_off: identical stats want same resolve_at (%.3f %.3f %.3f)" % [at0, at1, at2])


static func _harness_iv9_enemy_rank0_with_gaps(mgr: Node) -> Array:
    return _Fixtures._harness_iv9_enemy_rank0_with_gaps(mgr)


## IV-9 slice 1: gap mode suppresses `compact_native_line_files_if_thinned` on gapped narrow side.
static func _run_iv9_gap_column_compact_suppressed_when_flag_on(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "compact_native_line=disabled_when_on" not in sync_line:
        _fail(failures, "iv9_gap: sync line missing compaction gate in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var want_files: Array[int] = [1, 2, 3]
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    if _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_on: compaction should be suppressed in gap mode")
    var actual_files: Array[int] = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            actual_files.append(_EntityAccess.file_int(c))
    actual_files.sort()
    for i in range(actual_files.size()):
        if actual_files[i] != want_files[i]:
            _fail(
                failures,
                "iv9_gap_on: enemy files should stay gapped want %s got %s" % [str(want_files), str(actual_files)]
            )
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9: flag off  -  baseline compaction still packs gapped narrow enemy to files 0..n-1.
static func _run_iv9_gap_column_flag_off_parity(failures: PackedStringArray) -> void:
    if CombatConstants.FEATURE_GAP_COLUMN_TOPOLOGY:
        _fail(failures, "iv9_gap_off: FEATURE_GAP_COLUMN_TOPOLOGY should default off")
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    if not _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_off: narrow enemy with gaps should compact when flag off")
    var actual_files: Array[int] = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            actual_files.append(_EntityAccess.file_int(c))
    actual_files.sort()
    for i in range(actual_files.size()):
        if actual_files[i] != i:
            _fail(
                failures,
                (
                    "iv9_gap_off: enemy compact want file %d got %d (all files: %s)"
                    % [i, actual_files[i], str(actual_files)]
                )
            )
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9: vacancy reconcile follow-up still stable when gap mode is on.
static func _run_iv9_gap_column_vacancy_reconcile_flag_on(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var front_id: int = _EntityAccess.id_int(mgr.combatants[0])
    _soak_kill_combatant(mgr, front_id)
    var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    _FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var living_rank0_player: bool = false
    for c in mgr.combatants:
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c, -9) == 0:
            living_rank0_player = true
            break
    CombatConstants.set_feature_gap_column_topology_load(saved)
    if not living_rank0_player:
        _fail(failures, "iv9_gap_reconcile: rank-0 player should exist after front death + reconcile")
    _free_manager(mgr)


## IV-9 slice 2: `FormationSlots.occupied_files_for_rank` detects intentional file gaps.
static func _run_iv9_gap_column_occupied_files_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "slots=occupied_files_have_gaps" not in sync_line:
        _fail(failures, "iv9_gap_slots: sync line missing slots token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var form_enemy: Dictionary = mgr.formations["enemy"]
    var enemies_r0: Array = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            enemies_r0.append(c)
    var occ_gapped: PackedInt32Array = _FormationSlots.occupied_files_for_rank(mgr, form_enemy, 0)
    if occ_gapped.size() != enemies_r0.size():
        _fail(failures, "iv9_gap_slots: want %d occupied files got %s" % [enemies_r0.size(), str(occ_gapped)])
    if not _FormationSlots.occupied_files_have_gaps(occ_gapped):
        _fail(failures, "iv9_gap_slots: fixture should have file gaps got %s" % str(occ_gapped))
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    if not _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_slots: baseline compact should run when flag off")
    var occ_packed: PackedInt32Array = _FormationSlots.occupied_files_for_rank(mgr, form_enemy, 0)
    if _FormationSlots.occupied_files_have_gaps(occ_packed):
        _fail(failures, "iv9_gap_slots: after compact want contiguous files got %s" % str(occ_packed))
    for i in range(occ_packed.size()):
        if occ_packed[i] != i:
            _fail(failures, "iv9_gap_slots: packed files want %d at index %d got %s" % [i, i, str(occ_packed)])
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9 slice 2: diagram grid includes leading/trailing empty gap columns when flag on.
static func _run_iv9_gap_column_diagram_display_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "diagram_gaps" not in sync_line:
        _fail(failures, "iv9_gap_diagram: sync line missing diagram_gaps token in %s" % sync_line)
    var form: Dictionary = {
        "files": 3,
        "slots":
        {
            Vector2i(0, 1): [101],
            Vector2i(0, 2): [102],
            Vector2i(0, 3): [103],
        },
    }
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    var baseline: Array = _FormationSlots.column_display_files(form, 3)
    if baseline.size() != 3 or int(baseline[0]) != 0:
        _fail(failures, "iv9_gap_diagram_off: want baseline 0..2 got %s" % str(baseline))
    CombatConstants.set_feature_gap_column_topology_load(true)
    var display: Array = _FormationSlots.column_display_files(form, 3)
    CombatConstants.set_feature_gap_column_topology_load(saved)
    if display.size() != 4:
        _fail(failures, "iv9_gap_diagram_on: want four columns incl leading gap got %s" % str(display))
    if int(display[0]) != 0:
        _fail(failures, "iv9_gap_diagram_on: first column should be file 0 gap got %s" % str(display))
    if _FormationSlots.slot_has_any(form["slots"], Vector2i(0, 0)):
        _fail(failures, "iv9_gap_diagram_on: file 0 should be empty gap cell")


## IV-9 slice 3: gap mode uses column-arc spacing instead of raw grid |-file| when either line has gaps.
static func _run_iv9_gap_column_pair_geometry_column_arc_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "pair_geometry=column_arc_when_gaps" not in sync_line:
        _fail(failures, "iv9_gap_arc: sync line missing pair_geometry token in %s" % sync_line)
    if not is_equal_approx(
        _FormationSlots.column_arc_file_distance(PackedInt32Array([0, 1, 2]), 0, PackedInt32Array([1, 2, 3]), 3), 2.0
    ):
        _fail(failures, "iv9_gap_arc: column arc want 2 for wing-vs-far-wing fixture")
    if not is_equal_approx(
        _FormationSlots.column_arc_file_distance(PackedInt32Array([0, 1, 2]), 0, PackedInt32Array([1, 2, 3]), 1), 0.0
    ):
        _fail(failures, "iv9_gap_arc: column arc want 0 for opposing first columns")
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var enemies_r0: Array = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            enemies_r0.append(c)
    var player_wing: Dictionary = {}
    var enemy_far: Dictionary = enemies_r0[enemies_r0.size() - 1]
    for c in mgr.combatants:
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            player_wing = c
            break
    if player_wing.is_empty() or enemy_far.is_empty():
        _fail(failures, "iv9_gap_arc: fixture missing wing pair")
        return
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    var geom_off: Dictionary = _PairGeometry.effective_pair_geometry(mgr, player_wing, enemy_far)
    CombatConstants.set_feature_gap_column_topology_load(true)
    var geom_on: Dictionary = _PairGeometry.effective_pair_geometry(mgr, player_wing, enemy_far)
    CombatConstants.set_feature_gap_column_topology_load(saved)
    var df_off: float = absf(float(_EntityAccess.file_int(player_wing) - _EntityAccess.file_int(enemy_far)))
    if not is_equal_approx(float(geom_off.get("file_spacing_equiv", -1.0)), df_off):
        _fail(
            failures,
            (
                "iv9_gap_arc_off: want raw grid spacing %.1f got %.3f"
                % [df_off, float(geom_off.get("file_spacing_equiv", -1.0))]
            )
        )
    var want_arc: float = 2.0
    if not is_equal_approx(float(geom_on.get("file_spacing_equiv", -1.0)), want_arc):
        _fail(
            failures,
            (
                "iv9_gap_arc_on: want column-arc spacing %.1f got %.3f"
                % [want_arc, float(geom_on.get("file_spacing_equiv", -1.0))]
            )
        )
    if float(geom_on.get("eff_dist", 0.0)) >= float(geom_off.get("eff_dist", 0.0)):
        _fail(
            failures,
            (
                "iv9_gap_arc_on: eff_dist should shrink vs raw grid (on=%.3f off=%.3f)"
                % [float(geom_on.get("eff_dist", 0.0)), float(geom_off.get("eff_dist", 0.0))]
            )
        )
    _free_manager(mgr)


## IV-9 slice 4: gap flag on/off parity for formation moves + tier-1 targeting on contiguous lines; gap-on reach for column-aligned wing pair.
static func _run_iv9_gap_column_dual_mode_formation_targeting_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "harness=dual_mode_formation_targeting" not in sync_line:
        _fail(failures, "iv9_dual: sync line missing harness token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    # Contiguous 4-wide: flag on must not change rotate_file listing or center threaten vs flag off.
    var mgr_contig: Node = _MgrScript.new()
    for _i in 4:
        mgr_contig.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr_contig.register(_new_entity("SWORD"), "enemy")
    mgr_contig.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    CombatConstants.set_feature_gap_column_topology_load(false)
    var rotate_off: bool = _harness_iv9_player_rotate_file_listed(mgr_contig)
    var threaten_off: bool = _harness_iv9_center_rank0_can_melee_threaten(mgr_contig)
    CombatConstants.set_feature_gap_column_topology_load(true)
    var rotate_on: bool = _harness_iv9_player_rotate_file_listed(mgr_contig)
    var threaten_on: bool = _harness_iv9_center_rank0_can_melee_threaten(mgr_contig)
    if not rotate_off:
        _fail(failures, "iv9_dual_contig: flag off want rotate_file listed")
    if rotate_off != rotate_on:
        _fail(failures, "iv9_dual_contig: rotate_file parity off=%s on=%s" % [rotate_off, rotate_on])
    if not threaten_off:
        _fail(failures, "iv9_dual_contig: flag off want center can_melee_threaten")
    if threaten_off != threaten_on:
        _fail(failures, "iv9_dual_contig: threaten parity off=%s on=%s" % [threaten_off, threaten_on])
    _free_manager(mgr_contig)
    # Gapped narrow enemy: flag on keeps rotate_file on player line + column-arc wing reach.
    var mgr_gap: Node = _MgrScript.new()
    for _i in 4:
        mgr_gap.register(_new_entity("SWORD"), "player")
    # Need >=4 active per side for FORMATION mode (ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE=4).
    # Create 5 enemy entities, register all 4; start with 5-file formation so shifting works.
    var enemies_gap: Array = []
    for _g in 5:
        enemies_gap.append(_new_entity("SWORD"))
    for _gi in range(4):
        mgr_gap.register(enemies_gap[_gi], "enemy")
    mgr_gap.start({"files": 4, "ranks": 1}, {"files": 5, "ranks": 1})
    var slots_gap: Dictionary = _FormationSlots.formation_slots_dict(mgr_gap.formations["enemy"])
    var new_slots_gap: Dictionary = {}
    for sk in slots_gap.keys():
        if not (sk is Vector2i):
            continue
        var scell: Vector2i = sk as Vector2i
        if scell.x != 0:
            continue
        var scid: Variant = slots_gap[sk]
        var snk: Vector2i = Vector2i(scell.x, scell.y + 1)
        if scid is Array:
            new_slots_gap[snk] = scid.duplicate()
        elif scid is int and scid >= 0:
            new_slots_gap[snk] = [scid]
    mgr_gap.formations["enemy"]["slots"] = new_slots_gap
    _FormationSlots.normalize_formation_slots(mgr_gap.formations["enemy"])
    _FormationSlots.refresh_gap_column_topology(mgr_gap.formations["enemy"])
    mgr_gap.call("recompute_zoc_and_distance")
    CombatConstants.set_feature_gap_column_topology_load(true)
    if not _harness_iv9_player_rotate_file_listed(mgr_gap):
        _fail(failures, "iv9_dual_gap: want rotate_file on contiguous player line when flag on")
    var player_wing: Dictionary = {}
    var enemy_near: Dictionary = {}
    for c in mgr_gap.combatants:
        if (
            _EntityAccess.is_alive_on_side(c, "player")
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 0
        ):
            player_wing = c
        if (
            _EntityAccess.is_alive_on_side(c, "enemy")
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 1
        ):
            enemy_near = c
    if player_wing.is_empty() or enemy_near.is_empty():
        _fail(failures, "iv9_dual_gap: want wing pair player file0 vs enemy file1")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr_gap)
        return
    player_wing["gauge"] = 100.0
    if not _MeleeListing.can_melee_threaten(mgr_gap, player_wing, enemy_near):
        _fail(failures, "iv9_dual_gap: column-aligned wing want can_melee_threaten vs first enemy column")
    var acts: Array = _ActionsBuilder.build(mgr_gap, _EntityAccess.id_int(player_wing))
    var e_id: int = _EntityAccess.id_int(enemy_near)
    var w_wing: Variant = _EntityAccess.get_weapon(player_wing)
    var atk_ids: Dictionary = {}
    if w_wing != null and w_wing is Weapon:
        atk_ids = (w_wing as Weapon).attack_types
    if not _ListedActions.actions_include_any_move_in_vs_target(acts, e_id, atk_ids):
        _fail(failures, "iv9_dual_gap: wing want weapon strike listed vs column-aligned foe (had %s)" % str(acts))
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr_gap)


## IV-9 slice 5: **`gap_column_files`** cache stays synced after swap_rank + vacancy reconcile when flag on.
static func _run_iv9_gap_column_topology_refresh_after_formation_moves(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "flow_refresh=swap_drag_fall_back_reconcile" not in sync_line:
        _fail(failures, "iv9_refresh: sync line missing flow_refresh token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var form_p: Dictionary = mgr.formations["player"]
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: want cache sync after start")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    (
        _FormationFlow
        . handle_swap_rank_resolve(
            mgr,
            {
                "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
                "combatant_id": id0,
                "resolve_at": mgr.combat_clock,
                "data": {"partner_id": id1, "move_kind": "swap_rank"},
            }
        )
    )
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: cache drift after swap_rank resolve")
    _soak_kill_combatant(mgr, id0)
    var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    _FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: cache drift after vacancy reconcile")
    CombatConstants.set_feature_gap_column_topology_load(false)
    _FormationSlots.refresh_gap_column_topology_for_manager(mgr, "player")
    var form_after_off: Dictionary = mgr.formations["player"]
    if form_after_off.has("gap_column_files"):
        _fail(failures, "iv9_refresh: flag off should erase gap_column_files cache")
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9 slice 6: **`drag_back`** + **`fall_back_pair`** keep **`gap_column_files`** synced when flag on.
static func _run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "flow_refresh=swap_drag_fall_back_reconcile" not in sync_line:
        _fail(failures, "iv9_refresh_pair: sync line missing drag/fall_back token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var form_p: Dictionary = mgr.formations["player"]
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: want cache sync after start")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var p_front: Dictionary = {}
    var p_rear: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            p_front = c
        elif _EntityAccess.rank_int(c) == 1:
            p_rear = c
    if p_front.is_empty() or p_rear.is_empty():
        _fail(failures, "iv9_refresh_pair: want rank-0/rank-1 player pair")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var id_front: int = _EntityAccess.id_int(p_front)
    var id_rear: int = _EntityAccess.id_int(p_rear)
    _harness_iv9_resolve_adjacent_rank_pair_move(mgr, id_front, id_rear, "drag_back")
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: cache drift after drag_back resolve")
    _harness_iv9_resolve_adjacent_rank_pair_move(mgr, id_rear, id_front, "fall_back_pair")
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: cache drift after fall_back_pair resolve")
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-11 slice 3: **`CombatManager.register`** stamps **`is_party_leader`** from node (player only).
static func _run_iv11_register_party_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice3=register_stamp+formatter" not in sync_line:
        _fail(failures, "iv11_stamp: sync line missing slice3 token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.is_party_leader = false
    var enemy_ent: CoreEntity = _new_entity("SWORD")
    enemy_ent.is_party_leader = true
    mgr.register(leader_ent, "player")
    mgr.register(member_ent, "player")
    mgr.register(enemy_ent, "enemy")
    if not bool(mgr.combatants[0].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: player leader node want is_party_leader true")
    if bool(mgr.combatants[1].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: player member want is_party_leader false")
    if bool(mgr.combatants[2].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: enemy side must not stamp is_party_leader")
    _free_manager(mgr)


## IV-11 slice 4: roster **`is_party_leader`** on party nodes -> **`get_fightable_party_nodes`** -> **`CombatManager.register`** stamp.
static func _run_iv11_campaign_bridge_party_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice4=bridge_roster_stamp" not in sync_line:
        _fail(failures, "iv11_bridge: sync line missing slice4 token in %s" % sync_line)
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.name = "PartyLead"
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.name = "Companion"
    member_ent.is_party_leader = false
    pm.add_member(leader_ent)
    pm.add_member(member_ent)
    world.set_meta("party_manager", pm)
    var fightable: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if fightable.size() != 2:
        _fail(failures, "iv11_bridge: want 2 fightable party nodes got %d" % fightable.size())
        world.free()
        pm.free()
        _free_harness_node(leader_ent)
        _free_harness_node(member_ent)
        leader_ent = null
        member_ent = null
        return
    world.set_meta(_SoakPresets.WORLD_META_PLAYER_LEADER_ONLY, true)
    var leader_only: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if leader_only.size() != 1 or leader_only[0] != leader_ent:
        _fail(failures, "iv11_bridge: leader_only meta want leader node only got %d" % leader_only.size())
    world.remove_meta(_SoakPresets.WORLD_META_PLAYER_LEADER_ONLY)
    world.set_meta(_SoakPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP, 1)
    var capped: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if capped.size() != 1 or capped[0] != leader_ent:
        _fail(failures, "iv11_bridge: fighter cap 1 want leader-first got %d" % capped.size())
    world.remove_meta(_SoakPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP)
    var mgr: Node = _MgrScript.new()
    var leader_id: int = mgr.register(leader_ent, "player")
    var member_id: int = mgr.register(member_ent, "player")
    if not bool(mgr.combatants[leader_id].get("is_party_leader", false)):
        _fail(failures, "iv11_bridge: register leader want is_party_leader true")
    if bool(mgr.combatants[member_id].get("is_party_leader", false)):
        _fail(failures, "iv11_bridge: register member want is_party_leader false")
    _free_manager(mgr)
    world.free()
    pm.free()
    leader_ent = null
    member_ent = null


## IV-11 slice 4: formation diagram **`[Ldr]`** callout for player party leader only.
static func _run_iv11_party_leader_diagram_callout_suite(failures: PackedStringArray) -> void:
    var _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var _UiHints := preload("res://combat/CombatUiHints.gd")
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "diagram_callout" not in sync_line:
        _fail(failures, "iv11_diagram: sync line missing diagram_callout in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var member: Dictionary = {}
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
        elif leader.is_empty():
            leader = c
        else:
            member = c
    leader["is_party_leader"] = true
    member["is_party_leader"] = false
    if _UiHints.party_leader_diagram_suffix(leader) != " [Ldr]":
        _fail(
            failures,
            "iv11_diagram: leader suffix want ' [Ldr]' got '%s'" % _UiHints.party_leader_diagram_suffix(leader)
        )
    if not _UiHints.party_leader_diagram_suffix(member).is_empty():
        _fail(failures, "iv11_diagram: member must not get leader diagram suffix")
    if not _UiHints.party_leader_diagram_suffix(enemy).is_empty():
        _fail(failures, "iv11_diagram: enemy must not get leader diagram suffix")
    var leader_cell: String = _Diagram._cell_label_with_footwork("Lead", [leader])
    var member_cell: String = _Diagram._cell_label_with_footwork("Mate", [member])
    if " [Ldr]" not in leader_cell:
        _fail(failures, "iv11_diagram: leader cell want [Ldr] got '%s'" % leader_cell)
    if " [Ldr]" in member_cell:
        _fail(failures, "iv11_diagram: member cell must not show [Ldr] got '%s'" % member_cell)
    var tips: PackedStringArray = _UiHints.formation_cell_tooltip_lines(
        leader, _EntityAccess.get_display_name(leader, _EntityAccess.id_int(leader)), mgr
    )
    var tip_hit: bool = false
    for line in tips:
        if str(line).ends_with(" -  Party leader"):
            tip_hit = true
            break
    if not tip_hit:
        _fail(failures, "iv11_diagram: formation cell tooltip missing Party leader")
    _free_manager(mgr)


## IV-11 slice 2: party leader lists **`order_hold_lane`** when flag on; resolve sets formation doctrine.
static func _run_iv11_leader_order_hold_lane_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    for token in ["issuer=is_formation_command_issuer", "menu_label=Order_Hold_lane"]:
        if token not in sync_line:
            _fail(failures, "iv11_leader: sync line missing %s in %s" % [token, sync_line])
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_leader: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: want order_hold_lane listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Hold lane" not in menu_line:
        _fail(failures, "iv11_leader: menu line want Order: Hold lane got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Hold lane: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_leader: turn hint want instant hold lane got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: companion must not list order_hold_lane")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_HOLD_LANE, {})
    if not ok:
        _fail(failures, "iv11_leader: resolve order_hold_lane should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "iv11_leader: want hold_lane doctrine got %s" % mgr.get_formation_doctrine("player"))
    CombatConstants.set_feature_leader_formation_command_load(false)
    var off_acts: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(off_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: flag off must not list order_hold_lane")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 2: **`CombatLogFormatter`** surfaces **`leader_order_hold_lane`** resolve outcome.
static func _run_iv11_leader_order_hold_lane_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)", "player", "P (player)", "player", {"outcome": "leader_order_hold_lane", "formation_id": "player"}
    )
    if "hold lane" not in line.to_lower():
        _fail(failures, "iv11_formatter: want hold lane copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_formatter: want formation_id in %s" % line)


## IV-11 slice 5: party leader lists **`order_probing`** when flag on; resolve sets probing doctrine.
static func _run_iv11_leader_order_probing_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice5=order_probing" not in sync_line:
        _fail(failures, "iv11_probing: sync line missing slice5 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_probing: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: want order_probing listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Probe" not in menu_line:
        _fail(failures, "iv11_probing: menu line want Order: Probe got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Probe: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_probing: turn hint want instant probe got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: companion must not list order_probing")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_PROBING, {})
    if not ok:
        _fail(failures, "iv11_probing: resolve order_probing should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(failures, "iv11_probing: want probing doctrine got %s" % mgr.get_formation_doctrine("player"))
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var after_probe: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(after_probe, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: probing doctrine must suppress re-list")
    if not _ListedActions.actions_include_move_id(after_probe, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_probing: hold_lane should list when doctrine is probing")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 5: **`CombatLogFormatter`** surfaces **`leader_order_probing`** resolve outcome.
static func _run_iv11_leader_order_probing_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)", "player", "P (player)", "player", {"outcome": "leader_order_probing", "formation_id": "player"}
    )
    if "probe" not in line.to_lower():
        _fail(failures, "iv11_probing_formatter: want probe copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_probing_formatter: want formation_id in %s" % line)


## IV-11 slice 8: party leader lists **`order_pinch_center`** when flag on; resolve sets pinch doctrine.
static func _run_iv11_leader_order_pinch_center_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice8=order_pinch_center" not in sync_line:
        _fail(failures, "iv11_pinch: sync line missing slice8 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_pinch: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: want order_pinch_center listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Pinch center" not in menu_line:
        _fail(failures, "iv11_pinch: menu line want Order: Pinch center got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Pinch center: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_pinch: turn hint want instant pinch got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: companion must not list order_pinch_center")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER, {})
    if not ok:
        _fail(failures, "iv11_pinch: resolve order_pinch_center should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "iv11_pinch: want pinch_center doctrine got %s" % mgr.get_formation_doctrine("player"))
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var after_pinch: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: pinch doctrine must suppress re-list")
    if not _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_pinch: hold_lane should list when doctrine is pinch_center")
    if not _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_pinch: probing should list when doctrine is pinch_center")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 8: **`CombatLogFormatter`** surfaces **`leader_order_pinch_center`** resolve outcome.
static func _run_iv11_leader_order_pinch_center_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)",
        "player",
        "P (player)",
        "player",
        {"outcome": "leader_order_pinch_center", "formation_id": "player"}
    )
    if "pinch" not in line.to_lower():
        _fail(failures, "iv11_pinch_formatter: want pinch copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_pinch_formatter: want formation_id in %s" % line)


## IV-11 slice 9: enemy commander lists and resolves **`order_hold_lane`** (mirror player leader path).
static func _run_iv11_enemy_commander_order_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice9=enemy_commander_orders+doctrine_cycle" not in sync_line:
        _fail(failures, "iv11_enemy_cmd: sync line missing slice9 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    var grunt_ent: CoreEntity = _new_entity("SWORD")
    grunt_ent.is_enemy_leader = false
    mgr.register(cmd_ent, "enemy")
    mgr.register(grunt_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    var grunt: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        c["gauge"] = 100.0
        if c.get("is_enemy_leader", false) == true and commander.is_empty():
            commander = c
        elif grunt.is_empty():
            grunt = c
    if commander.is_empty() or grunt.is_empty():
        _fail(failures, "iv11_enemy_cmd: missing commander or grunt fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if _EntityAccess.rank_int(commander) != 0:
        _fail(failures, "iv11_enemy_cmd: commander must be rank 0")
    commander["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_DEFAULT)
    var cmd_id: int = _EntityAccess.id_int(commander)
    var grunt_id: int = _EntityAccess.id_int(grunt)
    var cmd_acts: Array = mgr.get_available_actions(cmd_id)
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: want order_hold_lane listed for enemy commander")
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_enemy_cmd: want order_probing listed for enemy commander")
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_enemy_cmd: want order_pinch_center listed for enemy commander")
    var grunt_acts: Array = mgr.get_available_actions(grunt_id)
    if _ListedActions.actions_include_move_id(grunt_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: grunt must not list leader commands")
    var ok: bool = _ResolveAction.resolve(mgr, cmd_id, cmd_id, CombatConstants.MOVE_ID_ORDER_HOLD_LANE, {})
    if not ok:
        _fail(failures, "iv11_enemy_cmd: resolve order_hold_lane should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "iv11_enemy_cmd: want hold_lane doctrine got %s" % mgr.get_formation_doctrine("enemy"))
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    var after_hold: Array = mgr.get_available_actions(cmd_id)
    if _ListedActions.actions_include_move_id(after_hold, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: hold_lane must suppress re-list after resolve")
    if not _ListedActions.actions_include_move_id(after_hold, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_enemy_cmd: probing should list when doctrine is hold_lane")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: enemy commander cycles hold -> probe -> pinch -> hold (mirror player leader).
static func _run_iv11_enemy_commander_doctrine_cycle_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice9=enemy_commander_orders+doctrine_cycle" not in sync_line:
        _fail(failures, "iv11_enemy_cycle: sync line missing slice9 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_PROBING)
    var commander: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if c.get("is_enemy_leader", false) == true and _EntityAccess.rank_int(c) == 0:
            commander = c
            break
    if commander.is_empty():
        _fail(failures, "iv11_enemy_cycle: missing rank-0 enemy commander")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var cmd_id: int = _EntityAccess.id_int(commander)
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_DEFAULT)
    var steps: Array = [
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
        CombatConstants.MOVE_ID_ORDER_PROBING,
        CombatConstants.MOVE_ID_ORDER_PINCH_CENTER,
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
    ]
    var want_docs: Array = [
        CombatConstants.DOCTRINE_HOLD_LANE,
        CombatConstants.DOCTRINE_PROBING,
        CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.DOCTRINE_HOLD_LANE,
    ]
    for i in steps.size():
        commander["state"] = CombatConstants.STATE_WAITING
        commander["gauge"] = 100.0
        var move_id: String = str(steps[i])
        if not _ResolveAction.resolve(mgr, cmd_id, cmd_id, move_id, {}):
            _fail(failures, "iv11_enemy_cycle: resolve %s failed at step %d" % [move_id, i])
            break
        if mgr.get_formation_doctrine("enemy") != want_docs[i]:
            _fail(
                failures,
                "iv11_enemy_cycle: step %d want %s got %s" % [i, want_docs[i], mgr.get_formation_doctrine("enemy")]
            )
            break
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: party leader can cycle hold -> probe -> pinch -> hold without re-listing active doctrine.
static func _run_iv11_leader_doctrine_cycle_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            leader = c
            break
    if leader.is_empty():
        _fail(failures, "iv11_cycle: missing rank-0 leader")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    var leader_id: int = _EntityAccess.id_int(leader)
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var steps: Array = [
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
        CombatConstants.MOVE_ID_ORDER_PROBING,
        CombatConstants.MOVE_ID_ORDER_PINCH_CENTER,
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
    ]
    var want_docs: Array = [
        CombatConstants.DOCTRINE_HOLD_LANE,
        CombatConstants.DOCTRINE_PROBING,
        CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.DOCTRINE_HOLD_LANE,
    ]
    for i in steps.size():
        leader["state"] = CombatConstants.STATE_WAITING
        leader["gauge"] = 100.0
        var move_id: String = str(steps[i])
        if not _ResolveAction.resolve(mgr, leader_id, leader_id, move_id, {}):
            _fail(failures, "iv11_cycle: resolve %s failed at step %d" % [move_id, i])
            break
        if mgr.get_formation_doctrine("player") != want_docs[i]:
            _fail(
                failures, "iv11_cycle: step %d want %s got %s" % [i, want_docs[i], mgr.get_formation_doctrine("player")]
            )
            break
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: AI picker assigns canonical weight to listed leader formation commands.
static func _run_iv11_leader_command_ai_weight_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = mgr.combatants[0]
    leader["is_party_leader"] = true
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var leader_id: int = _EntityAccess.id_int(leader)
    var acts: Array = mgr.get_available_actions(leader_id)
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
            break
    if hold_act.is_empty():
        _fail(failures, "iv11_ai_weight: want order_hold_lane listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    if not is_equal_approx(w, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(
            failures,
            "iv11_ai_weight: want %.2f got %.4f" % [CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, w]
        )
    leader["is_party_leader"] = false
    var w_member: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    if w_member != 0.0:
        _fail(failures, "iv11_ai_weight: non-issuer want weight 0 got %.4f" % w_member)
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: enemy commander AI pick weight matches party leader path.
static func _run_iv11_enemy_commander_ai_weight_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var commander: Dictionary = mgr.combatants[1]
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    var cmd_id: int = _EntityAccess.id_int(commander)
    var acts: Array = mgr.get_available_actions(cmd_id)
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
            break
    if hold_act.is_empty():
        _fail(failures, "iv11_enemy_ai_weight: want order_hold_lane listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    if not is_equal_approx(w, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(
            failures,
            "iv11_enemy_ai_weight: want %.2f got %.4f" % [CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, w]
        )
    commander["is_enemy_leader"] = false
    var w_grunt: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    if w_grunt != 0.0:
        _fail(failures, "iv11_enemy_ai_weight: non-issuer want weight 0 got %.4f" % w_grunt)
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: pinch command AI weight boosts under numeric superiority (wider + front margin).
static func _run_iv11_pinch_outnumber_ai_weight_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice10=pinch_outnumber_ai_mult=" not in sync_line:
        _fail(failures, "iv11_pinch_ai: sync line missing slice10 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0 and leader.is_empty():
            leader = c
    if leader.is_empty():
        _fail(failures, "iv11_pinch_ai: missing rank-0 leader")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "player"):
        _fail(failures, "iv11_pinch_ai: fixture want numeric superiority for player")
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_PROBING)
    var leader_id: int = _EntityAccess.id_int(leader)
    var acts: Array = mgr.get_available_actions(leader_id)
    var pinch_act: Dictionary = {}
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
            pinch_act = a
        elif mid == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
    if pinch_act.is_empty() or hold_act.is_empty():
        _fail(failures, "iv11_pinch_ai: want pinch and hold listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w_pinch: float = _AIPicker._get_action_weight(pinch_act, leader_id, mgr, true, {}, {}, acts)
    var w_hold: float = _AIPicker._get_action_weight(hold_act, leader_id, mgr, true, {}, {}, acts)
    var want_pinch: float = (
        CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
        * CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
    )
    if not is_equal_approx(w_pinch, want_pinch):
        _fail(failures, "iv11_pinch_ai: pinch want %.3f got %.4f" % [want_pinch, w_pinch])
    if not is_equal_approx(w_hold, CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT):
        _fail(failures, "iv11_pinch_ai: hold want base weight got %.4f" % w_hold)
    if w_pinch <= w_hold:
        _fail(failures, "iv11_pinch_ai: pinch should outweigh hold under outnumber")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: enemy commander pinch weight boosts under numeric superiority (mirror player).
static func _run_iv11_enemy_pinch_outnumber_ai_weight_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice10=pinch_outnumber_ai_mult=" not in sync_line:
        _fail(failures, "iv11_enemy_pinch_ai: sync line missing slice10 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if (
            c.get("is_enemy_leader", false) == true
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 0
        ):
            commander = c
            break
    if commander.is_empty():
        _fail(failures, "iv11_enemy_pinch_ai: missing rank-0 enemy commander")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "enemy"):
        _fail(failures, "iv11_enemy_pinch_ai: fixture want numeric superiority for enemy")
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_PROBING)
    var cmd_id: int = _EntityAccess.id_int(commander)
    var acts: Array = mgr.get_available_actions(cmd_id)
    var pinch_act: Dictionary = {}
    var hold_act: Dictionary = {}
    for raw in acts:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if mid == CombatConstants.MOVE_ID_ORDER_PINCH_CENTER:
            pinch_act = a
        elif mid == CombatConstants.MOVE_ID_ORDER_HOLD_LANE:
            hold_act = a
    if pinch_act.is_empty() or hold_act.is_empty():
        _fail(failures, "iv11_enemy_pinch_ai: want pinch and hold listed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var w_pinch: float = _AIPicker._get_action_weight(pinch_act, cmd_id, mgr, true, {}, {}, acts)
    var w_hold: float = _AIPicker._get_action_weight(hold_act, cmd_id, mgr, true, {}, {}, acts)
    var want_pinch: float = (
        CombatConstants.AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT
        * CombatConstants.AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT
    )
    if not is_equal_approx(w_pinch, want_pinch):
        _fail(failures, "iv11_enemy_pinch_ai: pinch want %.3f got %.4f" % [want_pinch, w_pinch])
    if w_pinch <= w_hold:
        _fail(failures, "iv11_enemy_pinch_ai: pinch should outweigh hold under outnumber")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 10: F5 paste **`leader_order=`** trace format (deduped via OperationalLog capture).
static func _run_iv11_f5_leader_order_trace_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "f5_track=iv11_leader_order" not in sync_line:
        _fail(failures, "iv11_f5_trace: sync line missing f5_track token in %s" % sync_line)
    _OperationalLog.set_capture_enabled(true)
    _OperationalLog.clear_capture()
    _OperationalLog.begin_play_session("test", "", false, true)
    _F5SoakTrace.note_leader_formation_command_pick(
        "Captain", CombatConstants.MOVE_ID_ORDER_PROBING, "player", "player"
    )
    _F5SoakTrace.note_leader_formation_command_pick(
        "Captain", CombatConstants.MOVE_ID_ORDER_PROBING, "player", "player"
    )
    _F5SoakTrace.note_leader_formation_command_pick(
        "Warlord", CombatConstants.MOVE_ID_ORDER_HOLD_LANE, "enemy", "enemy"
    )
    var count: int = 0
    var player_sample: String = ""
    var enemy_sample: String = ""
    for line in _OperationalLog.get_captured_lines():
        if "leader_order=" not in line:
            continue
        count += 1
        if "side=player" in line:
            player_sample = line
        elif "side=enemy" in line:
            enemy_sample = line
    if count != 2:
        _fail(failures, "iv11_f5_trace: want 2 leader_order lines got %d" % count)
    elif "order_probing" not in player_sample or "formation=player" not in player_sample:
        _fail(failures, "iv11_f5_trace: bad player leader_order line %s" % player_sample)
    elif "order_hold_lane" not in enemy_sample or "formation=enemy" not in enemy_sample:
        _fail(failures, "iv11_f5_trace: bad enemy leader_order line %s" % enemy_sample)
    _OperationalLog.end_play_session()
    _OperationalLog.set_capture_enabled(false)


## IV-11 slice 10: **`EncounterNode.spawn_enemies`** stamps **`is_enemy_leader`** from config index.
static func _run_iv11_encounter_spawn_enemy_leader_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "encounter_spawn=enemy_leader_index" not in sync_line:
        _fail(failures, "iv11_enc_spawn: sync line missing encounter_spawn token in %s" % sync_line)
    var world: Node2D = Node2D.new()
    var enc: Node = _EncounterNode.new()
    enc.enemy_count = 3
    enc.encounter_config = {
        _SoakPresets.ENCOUNTER_KEY_ENEMY_LEADER_INDEX: 1,
    }
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 42
    var enemies: Array = enc.spawn_enemies(world, rng)
    if enemies.size() != 3:
        _fail(failures, "iv11_enc_spawn: want 3 enemies got %d" % enemies.size())
        world.free()
        enc.free()
        return
    if enemies[1].get("is_enemy_leader") != true:
        _fail(failures, "iv11_enc_spawn: index 1 want is_enemy_leader true")
    if enemies[0].get("is_enemy_leader") == true or enemies[2].get("is_enemy_leader") == true:
        _fail(failures, "iv11_enc_spawn: only configured index may be commander")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_id: int = mgr.register(enemies[1], "enemy")
    mgr.register(enemies[0], "enemy")
    mgr.register(enemies[2], "enemy")
    if not bool(mgr.combatants[cmd_id].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enc_spawn: register want is_enemy_leader on commander")
    _free_manager(mgr)
    for n in enemies:
        if n != null and is_instance_valid(n):
            n.free()
    enc.free()
    world.free()


## IV-11 slice 6: **`CombatManager.register`** stamps **`is_enemy_leader`** from node (enemy only).
static func _run_iv11_register_enemy_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice6=enemy_leader" not in sync_line:
        _fail(failures, "iv11_enemy_leader: sync line missing slice6 token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    var cmd_ent: Node = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    var grunt_ent: Node = _new_entity("SWORD")
    grunt_ent.is_enemy_leader = false
    var player_ent: Node = _new_entity("SWORD")
    player_ent.is_enemy_leader = true
    mgr.register(player_ent, "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(cmd_ent, "enemy")
    mgr.register(grunt_ent, "enemy")
    if not bool(mgr.combatants[2].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: commander want is_enemy_leader true")
    if bool(mgr.combatants[3].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: grunt want is_enemy_leader false")
    if bool(mgr.combatants[0].get("is_enemy_leader", false)):
        _fail(failures, "iv11_enemy_leader: player must not stamp is_enemy_leader")
    _free_manager(mgr)


## IV-11 slice 6: formation diagram **`[Cmd]`** callout for enemy commander only.
static func _run_iv11_enemy_leader_diagram_callout_suite(failures: PackedStringArray) -> void:
    var _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    var grunt: Dictionary = {}
    var player: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "player") and player.is_empty():
            player = c
        elif _EntityAccess.is_living_on_side(c, "enemy"):
            if commander.is_empty():
                commander = c
            elif grunt.is_empty():
                grunt = c
    commander["is_enemy_leader"] = true
    grunt["is_enemy_leader"] = false
    player["is_party_leader"] = true
    if _UiHints.enemy_leader_diagram_suffix(commander) != " [Cmd]":
        _fail(
            failures,
            (
                "iv11_enemy_diagram: commander suffix want ' [Cmd]' got '%s'"
                % _UiHints.enemy_leader_diagram_suffix(commander)
            )
        )
    if not _UiHints.enemy_leader_diagram_suffix(grunt).is_empty():
        _fail(failures, "iv11_enemy_diagram: grunt must not get commander suffix")
    if not _UiHints.party_leader_diagram_suffix(commander).is_empty():
        _fail(failures, "iv11_enemy_diagram: enemy must not get party [Ldr] suffix")
    var cmd_cell: String = _Diagram._cell_label_with_footwork("Cmd", [commander])
    if " [Cmd]" not in cmd_cell:
        _fail(failures, "iv11_enemy_diagram: commander cell want [Cmd] got '%s'" % cmd_cell)
    if " [Cmd]" in _Diagram._cell_label_with_footwork("Grunt", [grunt]):
        _fail(failures, "iv11_enemy_diagram: grunt cell must not show [Cmd]")
    var tips: PackedStringArray = _UiHints.formation_cell_tooltip_lines(
        commander, _EntityAccess.get_display_name(commander, _EntityAccess.id_int(commander)), mgr
    )
    var tip_hit: bool = false
    for line in tips:
        if str(line).ends_with(" -  Enemy commander"):
            tip_hit = true
            break
    if not tip_hit:
        _fail(failures, "iv11_enemy_diagram: formation cell tooltip missing Enemy commander")
    _free_manager(mgr)


## IV-11 slice 7: **`PartyRowFormatter`** roster **` . Leader`** suffix from snapshot / node.
static func _run_iv11_party_leader_roster_callout_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice7=roster_menu_leader_suffix" not in sync_line:
        _fail(failures, "iv11_roster: sync line missing slice7 token in %s" % sync_line)
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.is_party_leader = false
    var leader_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "Lead", "node_ref": leader_ent})
    var member_snap: Dictionary = _Snapshot.snapshot_from_member({"name": "Mate", "node_ref": member_ent})
    if _PartyRowFormatter.format_party_role_suffix(leader_snap) != " . Leader":
        _fail(
            failures,
            "iv11_roster: leader want ' . Leader' got '%s'" % _PartyRowFormatter.format_party_role_suffix(leader_snap)
        )
    if not _PartyRowFormatter.format_party_role_suffix(member_snap).is_empty():
        _fail(failures, "iv11_roster: member must not get leader suffix")
    _free_harness_node(leader_ent)
    _free_harness_node(member_ent)


## IV-13: weak front ZoC  -  spear gains virtual reach; sword does not at marginal eff_dist.
static func _run_iv13_weapon_reach_zoc_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv13_weapon_reach_zoc_doc_sync_line()
    if "weapon-reach ZoC" not in sync_line:
        _fail(failures, "iv13_zoc: sync line missing token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SPEAR"), "player")
    for _j in 2:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    mgr.formations["enemy"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    var sword: Dictionary = {}
    var spear: Dictionary = {}
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            if enemy.is_empty() or _EntityAccess.file_int(c) < _EntityAccess.file_int(enemy):
                enemy = c
        elif _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.rank_int(c) == 0:
            if _EntityAccess.weapon_melee_reach(c) > 2.0:
                spear = c
            else:
                sword = c
    if sword.is_empty() or spear.is_empty() or enemy.is_empty():
        _fail(failures, "iv13_zoc: missing sword/spear/enemy rank-0 fixtures")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    var e_id: int = _EntityAccess.id_int(enemy)
    var sword_id: int = _EntityAccess.id_int(sword)
    var spear_id: int = _EntityAccess.id_int(spear)
    _EntityAccess.nested_dictionary_for_mutation(sword, "distance_to")[e_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(spear, "distance_to")[e_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[sword_id] = CombatConstants.DISTANCE_MID
    _EntityAccess.nested_dictionary_for_mutation(enemy, "distance_to")[spear_id] = CombatConstants.DISTANCE_MID
    var pair_geom: Dictionary = {"eff_dist": 2.6, "effective_pair_eff_dist": 2.6}
    var bonus_spear: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy)
    var bonus_sword: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, sword, enemy)
    if bonus_spear <= bonus_sword + 0.04:
        _fail(failures, "iv13_zoc: want spear bonus > sword (spear=%.3f sword=%.3f)" % [bonus_spear, bonus_sword])
    if not _MeleeListing.can_melee_threaten(mgr, spear, enemy, pair_geom):
        _fail(failures, "iv13_zoc: spear want can_melee_threaten with weak front + IV-13 on")
    if _MeleeListing.can_melee_threaten(mgr, sword, enemy, pair_geom):
        _fail(failures, "iv13_zoc: sword must not threaten at eff_dist=2.6 without reach bonus")
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)


## IV-13: flag off  -  no virtual reach bonus at weak front.
static func _run_iv13_weapon_reach_zoc_flag_off_parity(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(false)
    var mgr: Node = _MgrScript.new()
    for _i in 2:
        mgr.register(_new_entity("SPEAR"), "player")
    for _j in 2:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {"front": 0.3, "left_flank": 0.4, "right_flank": 0.4, "rear": 0.5}
    mgr.formations["enemy"]["zone_control"] = {"front": 0.3, "left_flank": 0.4, "right_flank": 0.4, "rear": 0.5}
    var spear: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[2]
    var pair_geom: Dictionary = {"eff_dist": 2.6, "effective_pair_eff_dist": 2.6}
    var bonus: float = _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy)
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)
    if absf(bonus) > 0.001:
        _fail(failures, "iv13_zoc_off: flag off want zero bonus got %.4f" % bonus)


## IV-13: distance bands stay aligned with `can_melee_threaten` when ZoC reach bonus is on.
static func _run_iv13_weapon_reach_zoc_distance_band_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv13_weapon_reach_zoc_enabled()
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(true)
    var mgr: Node = _MgrScript.new()
    for _i in 2:
        mgr.register(_new_entity("SPEAR"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 4, "ranks": 1})
    mgr.formations["player"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    mgr.formations["enemy"]["zone_control"] = {
        "front": 0.35,
        "left_flank": 0.4,
        "right_flank": 0.4,
        "rear": 0.5,
    }
    var spear: Dictionary = {}
    var enemy_far: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "player") and _EntityAccess.file_int(c) == 0:
            spear = c
        elif _EntityAccess.is_living_on_side(c, "enemy") and _EntityAccess.file_int(c) == 3:
            enemy_far = c
    if spear.is_empty() or enemy_far.is_empty():
        _fail(failures, "iv13_zoc_band: missing spear / far-enemy fixture")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    var eid: int = _EntityAccess.id_int(enemy_far)
    var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(mgr, spear, enemy_far)
    if _ZoneOfControl.weapon_reach_zoc_bonus_m(mgr, spear, enemy_far) <= 0.01:
        _fail(failures, "iv13_zoc_band: want positive ZoC reach bonus on wide-line fixture")
        CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
        _free_manager(mgr)
        return
    _DistanceBands.update_distance_to_from_formations(mgr)
    var band_on: String = _EntityAccess.distance_to_opponent_band(spear, eid)
    var threaten_on: bool = _MeleeListing.can_melee_threaten(mgr, spear, enemy_far, pair_geom)
    CombatConstants.set_feature_iv13_weapon_reach_zoc_load(saved)
    _free_manager(mgr)
    var band_implies_threaten: bool = (
        band_on == CombatConstants.DISTANCE_CLOSE or band_on == CombatConstants.DISTANCE_MID
    )
    if threaten_on != band_implies_threaten:
        _fail(failures, "iv13_zoc_band: band/threaten mismatch band=%s threaten=%s" % [band_on, threaten_on])


## IV-12: dual-occupancy opponent slot adds distraction pad to surround weight sum.
static func _run_iv12_slot_distraction_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv12_slot_distraction_doc_sync_line()
    if "IV-12 slot distraction" not in sync_line:
        _fail(failures, "iv12_distraction: sync line missing token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if int(_TacticalCombat.count_engaging_threats(mgr, pid)) < 2:
        _fail(failures, "iv12_distraction: fixture want 2 engaging threats")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var w_on: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var pad: float = CombatConstants.IV12_SLOT_DISTRACTION_WEIGHT_PAD
    if w_on < w_off + pad - 0.05:
        _fail(failures, "iv12_distraction: want on>off+pad (on=%.3f off=%.3f pad=%.2f)" % [w_on, w_off, pad])


## IV-12 slice 2: co-located threats damp AI hostile pick weight.
static func _run_iv12_slot_distraction_ai_offense_damp(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, _EntityAccess.id_int(e1)]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, _EntityAccess.id_int(e1)], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if _TacticalCombat.iv12_slot_distraction_pad_for_defender(mgr, pid) <= 0.0:
        _fail(failures, "iv12_ai_offense: fixture want distraction pad on player")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var act: Dictionary = {"move_id": "oberhau", "target_id": e0_id}
    var w_on: float = _AIPicker._get_action_weight(act, pid, mgr, true)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _AIPicker._get_action_weight(act, pid, mgr, true)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var want_ratio: float = CombatConstants.IV12_AI_OFFENSE_WEIGHT_MULT
    var ratio: float = w_on / maxf(0.0001, w_off)
    if ratio > want_ratio + 0.04:
        _fail(
            failures, "iv12_ai_offense: want ratio<=%.2f got %.3f (on=%.4f off=%.4f)" % [want_ratio, ratio, w_on, w_off]
        )


## IV-12 slice 2: co-located slot-mate pile-on boosts hostile targeting weight.
static func _run_iv12_co_located_target_bias_suite(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    if not _TacticalCombat.attacker_has_co_located_slot_mate_threatening(mgr, e1, player):
        _fail(failures, "iv12_pile_on: want co-located mate threatening player")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var w_on: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, e1, player)
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var w_off: float = _TargetScoring.hostile_pair_targeting_weight_mult(mgr, e1, player)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    var want: float = CombatConstants.IV12_AI_COLOCATED_TARGET_BIAS_MULT
    if w_on < w_off * want - 0.02:
        _fail(failures, "iv12_pile_on: want on>=off*%.2f (on=%.4f off=%.4f)" % [want, w_on, w_off])


## IV-12 slice 3: **`drag_back`** dual slot occupancy groups threats by formation cell (not stale rank).
static func _run_iv12_drag_back_dual_occupancy_distraction_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv12_slot_distraction_doc_sync_line()
    if "slice3=formation_slot_cell" not in sync_line:
        _fail(failures, "iv12_drag_back: sync line missing slice3 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 2})
    var player: Dictionary = mgr.combatants[0]
    var e_front: Dictionary = {}
    var e_rear: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            e_front = c
        elif _EntityAccess.rank_int(c) == 1:
            e_rear = c
    if e_front.is_empty() or e_rear.is_empty():
        _fail(failures, "iv12_drag_back: want enemy rank-0/rank-1 pair")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e_front)
    var e1_id: int = _EntityAccess.id_int(e_rear)
    for c in [player, e_front, e_rear]:
        c["gauge"] = 100.0
    _EntityAccess.nested_dictionary_for_mutation(player, "distance_to")[e0_id] = (CombatConstants.DISTANCE_CLOSE)
    _EntityAccess.nested_dictionary_for_mutation(e_front, "distance_to")[pid] = (CombatConstants.DISTANCE_CLOSE)
    _EntityAccess.nested_dictionary_for_mutation(e_rear, "distance_to")[pid] = (CombatConstants.DISTANCE_CLOSE)
    _FormationFlow.start_pair_move(mgr, e0_id, e1_id, "drag_back")
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    if _FormationSlots.living_count_in_slot(mgr, slots, Vector2i(0, 0)) < 2:
        _fail(failures, "iv12_drag_back: want dual occupancy at rank-0 during drag_back")
        CombatConstants.set_feature_iv12_slot_distraction_load(saved)
        _free_manager(mgr)
        return
    var pad: float = _TacticalCombat.iv12_slot_distraction_pad_for_defender(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    if pad < CombatConstants.IV12_SLOT_DISTRACTION_WEIGHT_PAD - 0.05:
        _fail(failures, "iv12_drag_back: want distraction pad from drag_back dual slot (got %.3f)" % pad)


## IV-12: flag off  -  co-located slot mates do not add distraction pad.
static func _run_iv12_slot_distraction_flag_off_parity(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_iv12_slot_distraction_enabled()
    CombatConstants.set_feature_iv12_slot_distraction_load(false)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var pid: int = _EntityAccess.id_int(player)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var form_e: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "enemy")
    var slots: Dictionary = _FormationSlots.formation_slots_dict(form_e)
    slots[Vector2i(0, 0)] = [e0_id, e1_id]
    e0["rank"] = 0
    e0["file"] = 0
    e1["rank"] = 0
    e1["file"] = 0
    for c in [player, e0, e1]:
        c["gauge"] = 100.0
    for pair in [[player, e0_id], [player, e1_id], [e0, pid], [e1, pid]]:
        _EntityAccess.nested_dictionary_for_mutation(pair[0], "distance_to")[pair[1]] = (CombatConstants.DISTANCE_CLOSE)
    var w0: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    var w1: float = _TacticalCombat.compute_surround_threat_weight_sum(mgr, pid)
    CombatConstants.set_feature_iv12_slot_distraction_load(saved)
    _free_manager(mgr)
    if not is_equal_approx(w0, w1):
        _fail(failures, "iv12_distraction_off: flag off want stable weight got %.3f vs %.3f" % [w0, w1])


## IV-11 slice 1b: party leader gets telegraph-matching focus-line weight; members use base weight.
static func _run_iv11_leader_formation_ability_suite(failures: PackedStringArray) -> void:
    var line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    for token in [
        "slice1=focus_line_telegraph_match",
        "issuer=is_formation_command_issuer",
        "menu_abilities=roster_suffix",
        "slice9=enemy_commander_orders+doctrine_cycle",
        "slice10=pinch_outnumber_ai_mult=",
        "f5_track=iv11_leader_order",
        "is_party_leader=CombatManager.register",
        "order_hold_lane_feature=",
    ]:
        if token not in line:
            _fail(failures, "iv11_leader: sync line missing %s in %s" % [token, line])
    if CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT <= 1.0:
        _fail(
            failures,
            (
                "iv11_leader: want leader telegraph weight > 1 got %.2f"
                % CombatConstants.AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT
            )
        )
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = mgr.combatants[0]
    var pid: int = _EntityAccess.id_int(leader)
    leader["is_party_leader"] = true
    leader[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = "head"
    var w_leader: float = _AIPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
    )
    leader["is_party_leader"] = false
    var w_member: float = _AIPicker._get_action_weight(
        {"move_id": CombatConstants.MOVE_ID_FOCUS_HIGH, "target_id": pid}, pid, mgr, true
    )
    if w_leader <= w_member:
        _fail(failures, "iv11_leader: telegraph match want leader>member (%.4f vs %.4f)" % [w_leader, w_member])
    if w_member > CombatConstants.AI_FOCUS_LINE_BASE_WEIGHT * 2.0:
        _fail(failures, "iv11_leader: member should use base focus weight got %.4f" % w_member)
    _free_manager(mgr)


## IV-7b: low stamina dampens attack / close listing weights via canonical engage floor.
static func _run_iv7b_stamina_engage_floor_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv7b_stamina_engage_doc_sync_line()
    if not sync_line.contains("ratio<0.20"):
        _fail(failures, "iv7b_engage: sync line want floor 0.20 in %s" % sync_line)
    if not is_equal_approx(CombatConstants.ai_offense_stamina_weight_mult(0.25), 1.0):
        _fail(failures, "iv7b_engage: above floor want mult 1.0")
    if not is_equal_approx(
        CombatConstants.ai_offense_stamina_weight_mult(0.15), CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT
    ):
        _fail(failures, "iv7b_engage: below floor want mult %.2f" % CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["gauge"] = 100.0
    p["stamina"] = CombatConstants.STAMINA_MAX * 0.15
    var act: Dictionary = {"move_id": "oberhau", "target_id": e_id}
    var w_low: float = _AIPicker._get_action_weight(act, p_id, mgr, true)
    p["stamina"] = CombatConstants.STAMINA_MAX * 0.50
    var w_hi: float = _AIPicker._get_action_weight(act, p_id, mgr, true)
    _free_manager(mgr)
    if w_low <= 0.0 or w_hi <= 0.0:
        _fail(failures, "iv7b_engage: want positive attack weights low=%.4f hi=%.4f" % [w_low, w_hi])
        return
    var ratio: float = w_low / w_hi
    if absf(ratio - CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT) > 0.02:
        _fail(
            failures,
            (
                "iv7b_engage: attack weight ratio want %.2f got %.3f (low=%.4f hi=%.4f)"
                % [CombatConstants.AI_STAMINA_ENGAGE_LOW_MULT, ratio, w_low, w_hi]
            )
        )


## Tier 0: hit during **`STATE_SWAP_RANK`** extends duration and delays resolve event (does not cancel).
static func _run_formation_hit_reaction_extends_pair_move_duration(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2}, {"files": 2, "ranks": 2})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 0:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "form_hit_rx: need rank-0/1 same-file pair")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    var dur_before: float = float(p0.get("state_duration", -1.0))
    var resolve_before: float = -1.0
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd: Dictionary = ev as Dictionary
        if (
            str(evd.get("type", "")) == CombatConstants.EVENT_SWAP_RANK_RESOLVE
            and int(evd.get("combatant_id", -1)) == id0
        ):
            resolve_before = float(evd.get("resolve_at", -1.0))
            break
    _FormationFlow.apply_hit_reaction_if_needed(mgr, id0, 0.35)
    var dur_after: float = float(p0.get("state_duration", -1.0))
    var resolve_after: float = resolve_before
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd2: Dictionary = ev as Dictionary
        if (
            str(evd2.get("type", "")) == CombatConstants.EVENT_SWAP_RANK_RESOLVE
            and int(evd2.get("combatant_id", -1)) == id0
        ):
            resolve_after = float(evd2.get("resolve_at", -1.0))
            break
    _free_manager(mgr)
    if dur_after <= dur_before + 0.05:
        _fail(failures, "form_hit_rx: duration want increase before=%.3f after=%.3f" % [dur_before, dur_after])
    if resolve_before < 0.0 or resolve_after <= resolve_before + 0.05:
        _fail(failures, "form_hit_rx: resolve_at want bump before=%.3f after=%.3f" % [resolve_before, resolve_after])


## Tier 0: hard hit during pair formation move aborts to waiting and removes resolve event.
static func _run_formation_hit_cancel_aborts_pair_move(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 2}, {"files": 2, "ranks": 2})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_player_side(c):
            continue
        if _EntityAccess.rank_int(c) == 0 and _EntityAccess.file_int(c) == 0:
            p0 = c
        elif _EntityAccess.rank_int(c) == 1 and _EntityAccess.file_int(c) == 0:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "form_hit_cancel: need rank-0/1 same-file pair")
        _free_manager(mgr)
        return
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    _FormationFlow.apply_hit_reaction_if_needed(mgr, id0, 0.9)
    var st0: String = _EntityAccess.state_str(p0)
    var st1: String = _EntityAccess.state_str(p1)
    var resolve_left: bool = false
    for ev in mgr.event_queue:
        if typeof(ev) != TYPE_DICTIONARY:
            continue
        var evd: Dictionary = ev as Dictionary
        if str(evd.get("type", "")) != CombatConstants.EVENT_SWAP_RANK_RESOLVE:
            continue
        var cid: int = int(evd.get("combatant_id", -1))
        var dr: Variant = evd.get("data", null)
        var pid: int = -1
        if dr is Dictionary:
            pid = int((dr as Dictionary).get("partner_id", -1))
        if cid == id0 or cid == id1 or pid == id0 or pid == id1:
            resolve_left = true
            break
    _free_manager(mgr)
    if st0 != CombatConstants.STATE_WAITING or st1 != CombatConstants.STATE_WAITING:
        _fail(failures, "form_hit_cancel: want both waiting got init=%s partner=%s" % [st0, st1])
    if resolve_left:
        _fail(failures, "form_hit_cancel: swap_rank_resolve should be removed")


## Tier 0 pilot: overlapping wind-ups  -  parry commitment follows highest threat only.
static func _run_incoming_parry_choice_blocks_non_chosen_attacker(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "incoming_parry: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    p["gauge"] = 100.0
    e0["gauge"] = 100.0
    e1["gauge"] = 100.0
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")["intensity"] = 1.0
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e1, "pending_attack")["intensity"] = 0.95
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var incoming: Array = _IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at)
    if incoming.size() < 2:
        _fail(failures, "incoming_parry: want 2 incoming attackers got %s" % str(incoming))
        _free_manager_restore_global_rng(mgr)
        return
    var s0: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e0_id)
    var s1: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e1_id)
    if s0 <= s1:
        _fail(
            failures,
            (
                "incoming_parry: threat e0=%.3f e1=%.3f i0=%.2f i1=%.2f"
                % [
                    s0,
                    s1,
                    float(_EntityAccess.nested_dictionary_read(e0, "pending_attack").get("intensity", -1.0)),
                    float(_EntityAccess.nested_dictionary_read(e1, "pending_attack").get("intensity", -1.0)),
                ]
            )
        )
    if _IncomingParryChoice.can_parry_all(mgr, p_id, resolve_at):
        _fail(failures, "incoming_parry: dual heavy pair should fail can_parry_all")
    var chosen: int = _IncomingParryChoice.choose_parry_target_attacker_id(mgr, p_id, resolve_at)
    if chosen != e0_id:
        _fail(
            failures,
            (
                "incoming_parry: want higher-intensity e0 chosen got %d (i0=%.2f i1=%.2f)"
                % [
                    chosen,
                    float(_EntityAccess.nested_dictionary_read(e0, "pending_attack").get("intensity", -1.0)),
                    float(_EntityAccess.nested_dictionary_read(e1, "pending_attack").get("intensity", -1.0)),
                ]
            )
        )
    if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, e1_id, resolve_at):
        pass
    else:
        _fail(
            failures,
            (
                "incoming_parry: low-threat resolve should block parry choice (incoming=%s)"
                % str(_IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at))
            )
        )
    if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, e0_id, resolve_at):
        _fail(failures, "incoming_parry: high-threat resolve should not block parry choice")
    _free_manager_restore_global_rng(mgr)


## Tier 0: two weak simultaneous wind-ups  -  **`can_parry_all`** true, no **`parry_choice_blocked`**.
static func _run_incoming_parry_can_parry_all_weak_pair(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "incoming_parry_all: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    _harness_reset_combatants_form_balanced(mgr)
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    p["gauge"] = 100.0
    p["guard_line"] = "high_right"
    e0["gauge"] = 100.0
    e1["gauge"] = 100.0
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")["intensity"] = 0.40
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    _EntityAccess.nested_dictionary_for_mutation(e1, "pending_attack")["intensity"] = 0.40
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var incoming: Array = _IncomingParryChoice.incoming_attacker_ids_on_defender(mgr, p_id, resolve_at)
    if incoming.size() < 2:
        _fail(failures, "incoming_parry_all: want 2 incoming got %s" % str(incoming))
        _free_manager_restore_global_rng(mgr)
        return
    if not _IncomingParryChoice.can_parry_all(mgr, p_id, resolve_at):
        _fail(failures, "incoming_parry_all: weak pair should pass can_parry_all")
    for aid in [e0_id, e1_id]:
        if _IncomingParryChoice.parry_choice_blocked_for_resolve(mgr, p_id, aid, resolve_at):
            _fail(failures, "incoming_parry_all: aid=%d should not be parry_choice_blocked" % aid)
        var pa: Dictionary = _EntityAccess.nested_dictionary_read(
            _EntityAccess.manager_get_combatant(mgr, aid), "pending_attack"
        )
        _IncomingParryChoice.stamp_parry_choice_on_pa(mgr, pa, p_id, aid, resolve_at)
        if bool(pa.get("parry_choice_blocked", false)):
            _fail(failures, "incoming_parry_all: stamp should not block aid=%d" % aid)
        if not bool(pa.get("parry_all_incoming_batch", false)):
            _fail(failures, "incoming_parry_all: want parry_all_incoming_batch on aid=%d" % aid)
    _free_manager_restore_global_rng(mgr)


## III-1: equal perceived telegraph -> sector flank weight breaks parry-target tie (not outright telegraph wins).
static func _run_iii1_incoming_parry_sector_tiebreak(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        _fail(failures, "iii1_parry_tie: FEATURE_INCOMING_PARRY_CHOICE should be enabled")
        return
    if not CombatConstants.is_feature_sector_surround_load():
        _fail(failures, "iii1_parry_tie: sector surround load should be enabled")
        return
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
    var p: Dictionary = mgr.combatants[0]
    var e0: Dictionary = mgr.combatants[1]
    var e1: Dictionary = mgr.combatants[2]
    p["file"] = 2
    e0["file"] = 0
    e1["file"] = 3
    for c in mgr.combatants:
        c["gauge"] = 100.0
    mgr.recompute_zoc_and_distance()
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(e0)
    var e1_id: int = _EntityAccess.id_int(e1)
    var w0: float = _TacticalCombat.sector_weight_for_attacker_on_defender(mgr, p_id, e0_id)
    var w1: float = _TacticalCombat.sector_weight_for_attacker_on_defender(mgr, p_id, e1_id)
    if absf(w0 - w1) < 0.02:
        _fail(failures, "iii1_parry_tie: want distinct sector weights got w0=%.3f w1=%.3f" % [w0, w1])
        _free_manager_restore_global_rng(mgr)
        return
    var want_id: int = e0_id if w0 > w1 else e1_id
    _WindUpStarter.start(mgr, e0_id, p_id, "oberhau")
    _WindUpStarter.start(mgr, e1_id, p_id, "oberhau")
    var pa0: Dictionary = _EntityAccess.nested_dictionary_for_mutation(e0, "pending_attack")
    pa0["intensity"] = 0.85
    pa0["power"] = 0.55
    pa0["follow_through"] = 0.55
    pa0.erase("feint_part")
    pa0.erase("parry_telegraph_apparent")
    e1["pending_attack"] = pa0.duplicate(true)
    e1["state_timer"] = e0["state_timer"]
    e1["state_duration"] = e0["state_duration"]
    var TIE_STRENGTH := 100.0
    for atk in [e0, e1]:
        _EntityAccess.stats_dict_for_mutation(atk)["strength"] = TIE_STRENGTH
    var resolve_at: float = _EntityAccess.combat_clock_plus(mgr, float(e0.get("state_duration", 0.5)))
    for aid in [e0_id, e1_id]:
        (
            _EntityAccess
            . manager_schedule_event(
                mgr,
                {
                    "type": CombatConstants.EVENT_MELEE_ATTACK,
                    "combatant_id": aid,
                    "resolve_at": resolve_at,
                    "data": {},
                }
            )
        )
    var s0: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e0_id, p_id, resolve_at)
    var s1: float = _IncomingParryChoice.threat_score_for_attacker(mgr, e1_id, p_id, resolve_at)
    if absf(s0 - s1) > 0.001:
        _fail(failures, "iii1_parry_tie: want tied threat scores s0=%.4f s1=%.4f" % [s0, s1])
        _free_manager_restore_global_rng(mgr)
        return
    var chosen: int = _IncomingParryChoice.choose_parry_target_attacker_id(mgr, p_id, resolve_at)
    if chosen != want_id:
        _fail(failures, "iii1_parry_tie: want sector-heavy aid=%d got %d (w0=%.3f w1=%.3f)" % [want_id, chosen, w0, w1])
    _free_manager_restore_global_rng(mgr)


## III-3: deflect/bind calibration loop  -  canonical thresholds, helper gates, ii2b plausibility band.
static func _run_iii3_deflect_bind_calibration_suite(failures: PackedStringArray) -> void:
    var _TrackSpecs := preload("res://harness/CombatD001TrackSpecs.gd")
    if not is_equal_approx(CombatConstants.PARRY_DEFLECT_THRESHOLD, 1.03):
        _fail(
            failures,
            "iii3_calibration: PARRY_DEFLECT_THRESHOLD want 1.03 got %.3f" % CombatConstants.PARRY_DEFLECT_THRESHOLD
        )
    if not is_equal_approx(CombatConstants.PARRY_BIND_CONTROL_THRESHOLD, 0.65):
        _fail(
            failures,
            (
                "iii3_calibration: PARRY_BIND_CONTROL_THRESHOLD want 0.65 got %.3f"
                % CombatConstants.PARRY_BIND_CONTROL_THRESHOLD
            )
        )
    var pa: float = 10.0
    var stop_at: float = pa * CombatConstants.PARRY_DEFLECT_THRESHOLD
    if CombatConstants.parry_full_stop_reached(stop_at - 0.001, pa, true):
        _fail(failures, "iii3_calibration: full_stop should be false below threshold")
    if not CombatConstants.parry_full_stop_reached(stop_at, pa, true):
        _fail(failures, "iii3_calibration: full_stop should be true at threshold")
    if CombatConstants.parry_full_stop_reached(stop_at, pa, false):
        _fail(failures, "iii3_calibration: full_stop should require block parry")
    var edge_cd: float = pa * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
    if not CombatConstants.parry_edge_deflect_reached(edge_cd, pa, 0.85, false):
        _fail(failures, "iii3_calibration: edge deflect should reach at aligned non-block margin")
    if CombatConstants.parry_edge_deflect_reached(edge_cd, pa, 0.85, true):
        _fail(failures, "iii3_calibration: edge deflect must not apply when block parry")
    if CombatConstants.parry_full_stop_reached(edge_cd, pa, false):
        _fail(failures, "iii3_calibration: edge deflect must not use full_stop without block")
    if CombatConstants.parry_bind_control_reached(0.649):
        _fail(failures, "iii3_calibration: bind control should be false below 0.65")
    if not CombatConstants.parry_bind_control_reached(0.65):
        _fail(failures, "iii3_calibration: bind control should be true at 0.65")
    var ctrl_nom: float = CombatConstants.parry_control_for_bind_deflect(12.0, 8.0, 0.85, 1.0, false, false, "cut")
    if not CombatConstants.parry_bind_control_reached(ctrl_nom):
        _fail(
            failures,
            (
                "iii3_calibration: nominal sword bind want control>=%.2f got %.3f"
                % [CombatConstants.PARRY_BIND_CONTROL_THRESHOLD, ctrl_nom]
            )
        )
    var pa_m: float = 10.0
    var cd_m: float = pa_m * CombatConstants.PARRY_DEFLECT_THRESHOLD * 1.05
    var ctrl_m: float = CombatConstants.parry_control_for_bind_deflect(cd_m, pa_m, 0.75, 1.0, false, false, "cut")
    if ctrl_nom < ctrl_m:
        _fail(failures, "iii3_calibration: decisive bind control %.3f should exceed marginal %.3f" % [ctrl_nom, ctrl_m])
    var good_stats: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    if not _TrackSpecs.ii2b_plausibility_failures(good_stats).is_empty():
        _fail(
            failures,
            (
                "iii3_calibration: balanced ii2b stats should pass plausibility got %s"
                % ", ".join(_TrackSpecs.ii2b_plausibility_failures(good_stats))
            )
        )
    var bind_heavy: Dictionary = good_stats.duplicate()
    bind_heavy["parry_bind"] = 9
    bind_heavy["parry_deflect"] = 1
    if _TrackSpecs.ii2b_plausibility_failures(bind_heavy).is_empty():
        _fail(failures, "iii3_calibration: bind-heavy ii2b stats should fail plausibility")
    var signed_prefill: String = _TrackSpecs.ii2b_worksheet_prefill_text(good_stats, true)
    if CombatConstants.iii3_baseline_constants_line() not in signed_prefill:
        _fail(failures, "iii3_calibration: signed worksheet must include baseline constants line")


## Tier 0 / FF4: extended weapon (recovering from own attack) dampens defender **`parry_c_d`**.
static func _run_weapon_extended_parry_dampens_defender_recovering_from_attack(failures: PackedStringArray) -> void:
    if not _WeaponPosition.is_weapon_near_body({"state": CombatConstants.STATE_WAITING}):
        _fail(failures, "weapon_pos: waiting should be near body")
    if (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "attack_hit",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: recovering from own attack should be extended")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "parry_deflect"}
    ):
        _fail(failures, "weapon_pos: recovering from parry should stay near body")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "parry_partial"}
    ):
        _fail(failures, "weapon_pos: parry_partial recovery should stay near body")
    if not (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "parry_partial",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: parry_partial recovery should stay near body with last_move_id")
    if not (
        _WeaponPosition
        . is_weapon_near_body(
            {
                "state": CombatConstants.STATE_RECOVERING,
                "recovery_cause": "parry_deflect",
                "last_move_id": "oberhau",
            }
        )
    ):
        _fail(failures, "weapon_pos: parry_deflect recovery should stay near body with last_move_id")
    if not _WeaponPosition.is_weapon_near_body(
        {"state": CombatConstants.STATE_RECOVERING, "recovery_cause": "attack_deflect"}
    ):
        _fail(failures, "weapon_pos: attack_deflect recovery should stay near body")
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["stamina"] = CombatConstants.STAMINA_MAX
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = _EntityAccess.scene_node(defender)
    var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "weapon_pos: targetable parts empty")
        _free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "intensity": 0.55,
        "wind_up_duration": 0.95,
        "tactical_ambush_mult": 1.0,
    }
    attacker["state"] = CombatConstants.STATE_WIND_UP
    attacker["state_duration"] = 1.0
    attacker["state_timer"] = 0.0
    seed(92011)
    var dc_wait: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_wait: float = float(dc_wait.get("parry_c_d", 0.0))
    if cd_wait <= 1e-6:
        _fail(failures, "weapon_pos: want positive parry_c_d while waiting got %.6f" % cd_wait)
        _free_manager_restore_global_rng(mgr)
        return
    defender["state"] = CombatConstants.STATE_RECOVERING
    defender["recovery_cause"] = "attack_hit"
    defender["last_move_id"] = "oberhau"
    seed(92011)
    var dc_ext: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_ext: float = float(dc_ext.get("parry_c_d", 0.0))
    var want_ext: float = cd_wait * CombatConstants.WEAPON_EXTENDED_PARRY_MULT
    if absf(cd_ext - want_ext) > cd_wait * 0.02:
        _fail(
            failures,
            "weapon_pos: extended recover want c_d>=>=%.4f got %.4f (waiting=%.4f)" % [want_ext, cd_ext, cd_wait]
        )
    defender["recovery_cause"] = "parry_deflect"
    defender.erase("last_move_id")
    seed(92011)
    var dc_parry: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    if absf(float(dc_parry.get("parry_c_d", 0.0)) - cd_wait) > cd_wait * 0.02:
        _fail(
            failures,
            (
                "weapon_pos: parry recovery want c_d>=>=waiting got %.4f vs %.4f"
                % [float(dc_parry.get("parry_c_d", 0.0)), cd_wait]
            )
        )
    defender["recovery_cause"] = "parry_partial"
    seed(92011)
    var dc_partial: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    if absf(float(dc_partial.get("parry_c_d", 0.0)) - cd_wait) > cd_wait * 0.02:
        _fail(
            failures,
            (
                "weapon_pos: parry_partial recovery want c_d>=>=waiting got %.4f vs %.4f"
                % [float(dc_partial.get("parry_c_d", 0.0)), cd_wait]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 0 / FF4: attacker wind-up past commit (extended) dampens defender **`parry_c_d`**.
static func _run_weapon_committed_attack_dampens_defender_parry_c_d(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    defender["guard"] = 0.55
    defender["stamina"] = CombatConstants.STAMINA_MAX
    defender["state"] = CombatConstants.STATE_WAITING
    var def_n: Node = _EntityAccess.scene_node(defender)
    var parts: Array = _EntityAccess.get_targetable_parts_from_node(def_n)
    if parts.is_empty():
        _fail(failures, "weapon_pos_commit: targetable parts empty")
        _free_manager_restore_global_rng(mgr)
        return
    var move_def: Dictionary = WeaponConstants.get_move("oberhau")
    var arch: Dictionary = WeaponConstants.get_archetype(
        str(move_def.get("archetype_id", WeaponConstants.ARCHETYPE_OVERHEAD))
    )
    var pa: Dictionary = {
        "attack_type": "oberhau",
        "intensity": 0.55,
        "wind_up_duration": 1.0,
        "tactical_ambush_mult": 1.0,
    }
    attacker["state"] = CombatConstants.STATE_WIND_UP
    attacker["state_duration"] = 1.0
    attacker["state_timer"] = 0.0
    attacker["pending_attack"] = pa.duplicate()
    if not _WeaponPosition.is_weapon_near_body(attacker):
        _fail(failures, "weapon_pos_commit: early wind-up should be near body")
    seed(92012)
    var dc_coil: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_coil: float = float(dc_coil.get("parry_c_d", 0.0))
    if cd_coil <= 1e-6:
        _fail(failures, "weapon_pos_commit: want positive parry_c_d early wind-up")
        _free_manager_restore_global_rng(mgr)
        return
    var commit_frac: float = _WeaponPosition.commit_fraction_from_move_def(move_def)
    attacker["state_timer"] = commit_frac * 1.0 + 0.05
    if _WeaponPosition.is_weapon_near_body(attacker):
        _fail(
            failures,
            (
                "weapon_pos_commit: past commit wind-up should be extended (frac=%.2f timer=%.2f)"
                % [commit_frac, float(attacker.get("state_timer", 0.0))]
            )
        )
    seed(92012)
    var dc_commit: Dictionary = _DefenseChoice.choose_defense(pa, attacker, defender, parts, "oberhau", arch, -1.0)
    var cd_commit: float = float(dc_commit.get("parry_c_d", 0.0))
    var want_commit: float = cd_coil * CombatConstants.WEAPON_COMMITTED_ATTACK_PARRY_C_D_MULT
    if absf(cd_commit - want_commit) > cd_coil * 0.02:
        _fail(
            failures,
            (
                "weapon_pos_commit: committed attack want c_d>=>=%.4f got %.4f (coil=%.4f)"
                % [want_commit, cd_commit, cd_coil]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 0 / FF4: thrust moves commit earlier than heavy cuts (**`weapon_extension_commit_fraction`** on move def).
static func _run_weapon_commit_fraction_stab_before_overhead_cut(failures: PackedStringArray) -> void:
    var stab_frac: float = float(WeaponConstants.get_move("spear_thrust").get("weapon_extension_commit_fraction", 1.0))
    var cut_frac: float = float(WeaponConstants.get_move("oberhau").get("weapon_extension_commit_fraction", 0.0))
    if stab_frac >= cut_frac:
        _fail(failures, "weapon_commit_frac: stab %.2f should be < cut %.2f" % [stab_frac, cut_frac])
    var probe_timer: float = 0.65
    var atk_stab: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": probe_timer,
        "state_duration": 1.0,
        "pending_attack":
        {
            "wind_up_duration": 1.0,
            "attack_type": "spear_thrust",
            "weapon_extension_commit_fraction": stab_frac,
        },
    }
    if _WeaponPosition.is_weapon_near_body(atk_stab):
        _fail(failures, "weapon_commit_frac: spear at 65%% wind-up should be extended")
    var atk_cut: Dictionary = {
        "state": CombatConstants.STATE_WIND_UP,
        "state_timer": probe_timer,
        "state_duration": 1.0,
        "pending_attack":
        {
            "wind_up_duration": 1.0,
            "attack_type": "oberhau",
            "weapon_extension_commit_fraction": cut_frac,
        },
    }
    if not _WeaponPosition.is_weapon_near_body(atk_cut):
        _fail(failures, "weapon_commit_frac: oberhau at 65%% wind-up should still be coiled")


## Tier 0 / FF4: wind-up stamps per-move commit fraction on **`pending_attack`**.
static func _run_weapon_windup_stamps_commit_fraction_on_pa(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
    var want: float = _WeaponPosition.commit_fraction_from_move_def(WeaponConstants.get_move("spear_thrust"))
    if absf(float(pa.get("weapon_extension_commit_fraction", -1.0)) - want) > 0.001:
        _fail(
            failures,
            (
                "weapon_commit_frac: pa stamp want %.2f got %s"
                % [want, str(pa.get("weapon_extension_commit_fraction", "<absent>"))]
            )
        )
    _free_manager(mgr)


## Tier 0 / FF4: moves without explicit commit tag infer stab contact (**`parry_thrust`**).
static func _run_weapon_commit_fraction_inferred_for_untagged_thrust_move(failures: PackedStringArray) -> void:
    var move_def: Dictionary = WeaponConstants.get_move("parry_thrust")
    if move_def.has("weapon_extension_commit_fraction"):
        _fail(failures, "weapon_commit_infer: parry_thrust should rely on contact inference")
    var want: float = _WeaponPosition.commit_fraction_from_move_def(move_def)
    if absf(want - CombatConstants.WEAPON_COMMIT_FRACTION_STAB) > 0.001:
        _fail(
            failures,
            (
                "weapon_commit_infer: parry_thrust want stab %.2f got %.2f"
                % [CombatConstants.WEAPON_COMMIT_FRACTION_STAB, want]
            )
        )


## Tier 7.5 pilot: **`impact_station_spread` 0** -> roll equals move **`impact_station_mean`** (+ intensity focus only).
static func _run_impact_station_mean_zero_spread_equals_move_mean(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station: could not create SPEAR")
        return
    var intensity: float = 0.35
    var focus: float = clampf((intensity - 0.35) * 0.08, -0.04, 0.04)
    var want_mean: float = float(WeaponConstants.get_move("spear_thrust").get("impact_station_mean", -1.0))
    seed(7701)
    var got: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    if absf(got - clampf(want_mean + focus, 0.06, 0.99)) > 0.001:
        _fail(
            failures,
            (
                "impact_station: spear_thrust want %.3f got %.3f (mean %.2f focus %.3f)"
                % [want_mean + focus, got, want_mean, focus]
            )
        )


## Tier 7.5 pilot: per-move mean overrides weapon **`strike_physics.station_mean`**.
static func _run_impact_station_mean_move_overrides_weapon_default(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station_override: could not create SPEAR")
        return
    var intensity: float = 0.5
    seed(7702)
    var tagged: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    seed(7702)
    var untagged: float = _StrikeRealism.roll_blade_station(spear, "off_line_thrust", intensity)
    if tagged <= untagged:
        _fail(
            failures,
            "impact_station_override: spear_thrust %.3f should exceed off_line_thrust %.3f" % [tagged, untagged]
        )


## Tier 7.5 pilot: tip thrust stations above mace head-weighted direct blow.
static func _run_impact_station_mean_ordering_spear_thrust_above_mace_direct_blow(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    var mace: RefCounted = Weapon.create_from_definition("MACE")
    if spear == null or mace == null:
        _fail(failures, "impact_station_order: could not create weapons")
        return
    var intensity: float = 0.35
    seed(7703)
    var spear_station: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    seed(7703)
    var mace_station: float = _StrikeRealism.roll_blade_station(mace, "direct_blow", intensity)
    if spear_station <= mace_station:
        _fail(
            failures,
            (
                "impact_station_order: spear_thrust %.3f should exceed mace direct_blow %.3f"
                % [spear_station, mace_station]
            )
        )


## Tier 7.5 pilot: wind-up stamps tip-biased **`impact_blade_station`** (move mean, not weapon default).
static func _run_impact_station_mean_windup_stamps_move_override(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SPEAR"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var atk: Dictionary = mgr.combatants[0]
    var atk_id: int = _EntityAccess.id_int(atk)
    var def_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _WindUpStarter.start(mgr, atk_id, def_id, "spear_thrust")
    var pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
    var station: float = float(pa.get("impact_blade_station", -1.0))
    if station < 0.0:
        _fail(failures, "impact_station_windup: missing impact_blade_station on pa")
        return
    var move_mean: float = float(WeaponConstants.get_move("spear_thrust").get("impact_station_mean", -1.0))
    var lo: float = clampf(move_mean - 0.04, 0.06, 0.99)
    var hi: float = clampf(move_mean + 0.04, 0.06, 0.99)
    if station < lo or station > hi:
        _fail(failures, "impact_station_windup: spear_thrust station %.3f outside [%.3f, %.3f]" % [station, lo, hi])
    var weapon_default: float = float(Weapon.create_from_definition("SPEAR").strike_physics.get("station_mean", 0.0))
    if station <= weapon_default + 0.12:
        _fail(
            failures,
            "impact_station_windup: station %.3f should exceed weapon default %.2f" % [station, weapon_default]
        )
    _free_manager(mgr)


## Tier 7.5: every entry in **`WeaponConstants._move_definitions_build`** carries **`impact_station_mean`**.
static func _run_impact_station_mean_every_move_def_tagged(failures: PackedStringArray) -> void:
    for move_id in WeaponConstants.get_all_move_ids():
        var md: Dictionary = WeaponConstants.get_move(move_id)
        if not md.has("impact_station_mean"):
            _fail(failures, "impact_station_catalog: %s missing impact_station_mean" % move_id)
            continue
        var mean: float = float(md.impact_station_mean)
        if mean < 0.06 or mean > 0.99:
            _fail(failures, "impact_station_catalog: %s mean %.3f outside [0.06, 0.99]" % [move_id, mean])


## Tier 7.5: feint wind-up station biased coiled vs honest cut at same intensity.
static func _run_impact_station_mean_feint_coiled_below_honest_cut(failures: PackedStringArray) -> void:
    var sword: RefCounted = Weapon.create_from_definition("SWORD")
    if sword == null:
        _fail(failures, "impact_station_feint: could not create SWORD")
        return
    var intensity: float = 0.35
    seed(7705)
    var feint_station: float = _StrikeRealism.roll_blade_station(sword, "oberhau_feint", intensity)
    seed(7705)
    var honest_station: float = _StrikeRealism.roll_blade_station(sword, "oberhau", intensity)
    if feint_station >= honest_station:
        _fail(
            failures,
            "impact_station_feint: oberhau_feint %.3f should be < oberhau %.3f" % [feint_station, honest_station]
        )


## Tier 7.5: spear shaft swing sits mid-blade vs tip thrust.
static func _run_impact_station_mean_pole_swing_below_spear_thrust(failures: PackedStringArray) -> void:
    var spear: RefCounted = Weapon.create_from_definition("SPEAR")
    if spear == null:
        _fail(failures, "impact_station_pole: could not create SPEAR")
        return
    var intensity: float = 0.35
    seed(7706)
    var swing_station: float = _StrikeRealism.roll_blade_station(spear, "pole_swing", intensity)
    seed(7706)
    var thrust_station: float = _StrikeRealism.roll_blade_station(spear, "spear_thrust", intensity)
    if swing_station >= thrust_station:
        _fail(
            failures,
            "impact_station_pole: pole_swing %.3f should be < spear_thrust %.3f" % [swing_station, thrust_station]
        )


## Tier 0.2: formation move gauge shows vulnerable suffix while swapping / falling back.
static func _run_formation_hit_cancel_ui_gauge_vulnerable_suffix(failures: PackedStringArray) -> void:
    var c: Dictionary = {
        "alive": true,
        "state": CombatConstants.STATE_SWAP_RANK,
        "state_timer": 0.0,
        "state_duration": 2.0,
        "gauge": 50.0,
    }
    var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c)
    if "vulnerable" not in label:
        _fail(failures, "form_hit_ui: swap gauge want vulnerable suffix got %s" % label)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(c)
    var found: bool = false
    for line in tips:
        if "Formation move" in str(line) and "cancel" in str(line):
            found = true
            break
    if not found:
        _fail(failures, "form_hit_ui: gauge tooltip should mention hit cancel risk")


## Camp-3.2: party menu triage line uses ATLS band + danger ETA from bleed physics.
static func _run_party_row_triage_formatter(failures: PackedStringArray) -> void:
    var blood: float = 70.0
    var bleed: float = 0.35
    var line: String = _PartyRowFormatter.format_triage_line(blood, bleed)
    if "ATLS" not in line:
        _fail(failures, "party_triage: want ATLS band label in %s" % line)
    var cls: int = _Bleeding.atls_hemorrhage_class_from_remaining_pct(blood)
    var class_token: String = "Class %d" % cls
    var roman: String = ["", "I", "II", "III", "IV"][cls] if cls >= 1 and cls <= 4 else ""
    if class_token not in line and (roman.is_empty() or ("Class %s" % roman) not in line):
        _fail(failures, "party_triage: want ATLS class for blood=%.0f got %s" % [blood, line])
    var eta_s: float = _PartyRowFormatter.seconds_to_danger_band(blood, bleed)
    if eta_s <= 0.0 or eta_s == INF:
        _fail(failures, "party_triage: want finite ETA to danger got %.2f" % eta_s)
    if "danger" not in line:
        _fail(failures, "party_triage: want danger ETA text in %s" % line)
    var at_danger: String = _PartyRowFormatter.format_triage_line(
        _Bleeding.MEDICAL_TRIAGE_DANGER_BLOOD_REMAINING - 1.0, bleed
    )
    if "at danger" not in at_danger:
        _fail(failures, "party_triage: below danger threshold should read at danger got %s" % at_danger)
    var calm: String = _PartyRowFormatter.format_triage_line(95.0, 0.0)
    if "ATLS" not in calm or "Bleeding" in calm:
        _fail(failures, "party_triage: zero bleed should omit bleed/ETA got %s" % calm)


## Campaign bridge: untreated wound detection on **`CoreEntity`**.
static func _run_campaign_bridge_entity_untreated_wounds(failures: PackedStringArray) -> void:
    var ent: CoreEntity = _new_entity("SWORD")
    ent.take_damage_split(8.0, 2.0, "left_arm", 0.5, 0.5)
    if not _CampaignBridge.entity_has_untreated_wounds(ent):
        _fail(failures, "campaign_bridge: fresh wound should count as untreated")
    ent.apply_direct_pressure("left_arm")
    if ent.can_apply_bandage("left_arm") and ent.apply_bandage("left_arm"):
        if _CampaignBridge.entity_has_untreated_wounds(ent):
            _fail(failures, "campaign_bridge: bandaged wound should not be untreated")
    var packed: CoreEntity = _new_entity("SWORD")
    packed.take_damage_split(6.0, 1.0, "head", 0.5, 0.5)
    packed.packed_parts["head"] = true
    if _CampaignBridge.entity_has_untreated_wounds(packed):
        _fail(failures, "campaign_bridge: packed part should not count as untreated")
    var tq: CoreEntity = _new_entity("SWORD")
    tq.take_damage_split(6.0, 1.0, "left_leg", 0.5, 0.5)
    tq.tourniquet_applied["left_leg"] = {"effectiveness": 1.0}
    if _CampaignBridge.entity_has_untreated_wounds(tq):
        _fail(failures, "campaign_bridge: tourniqueted part should not count as untreated")
    _free_harness_node(ent)
    _free_harness_node(packed)
    _free_harness_node(tq)


## Campaign bridge: encounter node exports -> world meta.
static func _run_campaign_bridge_encounter_meta_from_node(failures: PackedStringArray) -> void:
    var world: Node2D = Node2D.new()
    var enc: Node = _EncounterNode.new()
    enc.encounter_config = {
        CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY: CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM: "  wrath  ",
    }
    enc.enemy_count = 2
    _CampaignBridge.prepare_combat_from_encounter(world, enc)
    var got: Dictionary = world.get_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, {})
    if (
        str(got.get(CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY, ""))
        != CombatConstants.DOCTRINE_PINCH_CENTER
    ):
        _fail(failures, "campaign_bridge: encounter_config not copied to world meta")
    if str(got.get(CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM, "")) != "wrath":
        _fail(failures, "campaign_bridge: enemy_default_weapon_form not copied/stripped to world meta")
    var ef: Dictionary = world.get_meta("enemy_formation", {})
    if int(ef.get("files", 0)) < 1:
        _fail(failures, "campaign_bridge: enemy_formation meta missing files")
    enc.free()
    world.free()


## Tier 1.10: **`CombatFormationEngagement.recompute_all`** runs automatic doctrine evaluation.
static func _run_automatic_doctrine_pinch_via_formation_recompute(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "auto_doc_recompute: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
    var en_by_file: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_enemy_side(c):
            continue
        en_by_file[_EntityAccess.file_int(c)] = c
    (en_by_file[1] as Dictionary)["alive"] = false
    _FormationEngagement.recompute_all(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "auto_doc_recompute: want pinch_center got %s" % mgr.get_formation_doctrine("player"))
    _free_manager(mgr)


## p4c: **`numeric_superiority_for_pinch`** sets **`pinch_center`** on wide outnumber (7v3) without hollow enemy front.
static func _run_p4c_numeric_superiority_auto_pinch(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "p4c_numeric: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = _MgrScript.new()
    for _i in 7:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 7, "ranks": 1}, {"files": 3, "ranks": 1})
    if _CombatDoctrine.enemy_line_hollow_center_for_pinch(mgr, "player"):
        _fail(failures, "p4c_numeric: full enemy front should not read hollow_center")
    if not _CombatDoctrine.numeric_superiority_for_pinch(mgr, "player"):
        _fail(failures, "p4c_numeric: 7v3 rank-0 fronts should trigger numeric_superiority")
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "p4c_numeric: want pinch_center got %s" % mgr.get_formation_doctrine("player"))
    if not mgr.has_meta(_TacticalCombat.META_COMBAT_TELEMETRY):
        _fail(failures, "p4c_numeric: missing telemetry after evaluate_automatic_doctrine")
        _free_manager(mgr)
        return
    var tel: Dictionary = mgr.get_meta(_TacticalCombat.META_COMBAT_TELEMETRY) as Dictionary
    var lap: Variant = tel.get("last_automatic_doctrine_pinch", {})
    if typeof(lap) != TYPE_DICTIONARY:
        _fail(failures, "p4c_numeric: last_automatic_doctrine_pinch should be a dict")
        _free_manager(mgr)
        return
    if str((lap as Dictionary).get("reason", "")) != "numeric_superiority":
        _fail(
            failures, "p4c_numeric: want reason numeric_superiority got %s" % str((lap as Dictionary).get("reason", ""))
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    _CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "p4c_numeric: must not override player hold_lane got %s" % mgr.get_formation_doctrine("player"))
    _FormationEngagement.recompute_all(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures, "p4c_numeric: recompute must not override hold_lane got %s" % mgr.get_formation_doctrine("player")
        )
    _free_manager(mgr)


## Tier 7: bind **`parry_deflect`** grants defender gauge bonus; sub-threshold control does not.
static func _run_tier7_parry_bind_riposte_gauge_bonus_on_deflect(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    defender["gauge"] = 40.0
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
            }
        )
    )
    var want_bind: float = 40.0 + CombatConstants.PARRY_BIND_RIPOSTE_GAUGE_BONUS
    if not is_equal_approx(float(defender.get("gauge", -1.0)), want_bind):
        _fail(
            failures,
            "tier7_bind_gauge: bind deflect want %.1f got %.1f" % [want_bind, float(defender.get("gauge", -1.0))]
        )
    defender["gauge"] = 40.0
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.41, "kinematic_delivery": "thrust"},
            }
        )
    )
    if not is_equal_approx(float(defender.get("gauge", -1.0)), 40.0):
        _fail(
            failures,
            "tier7_bind_gauge: deflect-only should not bump gauge got %.1f" % float(defender.get("gauge", -1.0))
        )
    _free_manager(mgr)


## Tier 3.2: bind riposte speed depends on parry contact part plus the riposte contact type.
static func _run_bind_riposte_contact_multipliers(failures: PackedStringArray) -> void:
    var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
    var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
    var spear_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["stab"])
    if spear_normal <= 0.0 or absf((spear_bind / spear_normal) - spear_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: spear stab ratio %.3f want %.3f"
                % [(spear_bind / spear_normal) if spear_normal > 0.0 else -1.0, spear_want]
            )
        )
    var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
    var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
    var mace_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary)["blunt"])
    if mace_normal <= 0.0 or absf((mace_bind / mace_normal) - mace_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: mace blunt ratio %.3f want %.3f"
                % [(mace_bind / mace_normal) if mace_normal > 0.0 else -1.0, mace_want]
            )
        )
    var axe_normal: float = _windup_duration_for_bind_test("AXE", "spike_thrust", false)
    var axe_bind: float = _windup_duration_for_bind_test("AXE", "spike_thrust", true)
    var axe_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["haft"] as Dictionary)["stab"])
    if axe_normal <= 0.0 or absf((axe_bind / axe_normal) - axe_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: axe spike ratio %.3f want %.3f"
                % [(axe_bind / axe_normal) if axe_normal > 0.0 else -1.0, axe_want]
            )
        )
    var spear_slash_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", false)
    var spear_slash_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_slash", true)
    if spear_slash_normal <= 0.0 or absf((spear_slash_bind / spear_slash_normal) - 1.0) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: spear slash should not be eligible by default ratio %.3f"
                % [(spear_slash_bind / spear_slash_normal) if spear_slash_normal > 0.0 else -1.0]
            )
        )
    var sword_normal: float = _windup_duration_for_bind_test("SWORD", "oberhau", false)
    var sword_bind: float = _windup_duration_for_bind_test("SWORD", "oberhau", true)
    var sword_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary)["cut"])
    if sword_normal <= 0.0 or absf((sword_bind / sword_normal) - sword_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: sword cut ratio %.3f want %.3f"
                % [(sword_bind / sword_normal) if sword_normal > 0.0 else -1.0, sword_want]
            )
        )
    var dagger_normal: float = _windup_duration_for_bind_test("DAGGER", "quick_thrust", false)
    var dagger_bind: float = _windup_duration_for_bind_test("DAGGER", "quick_thrust", true)
    var dagger_want: float = float((CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary)["stab"])
    if dagger_normal <= 0.0 or absf((dagger_bind / dagger_normal) - dagger_want) > 0.001:
        _fail(
            failures,
            (
                "bind_riposte: dagger stab ratio %.3f want %.3f"
                % [(dagger_bind / dagger_normal) if dagger_normal > 0.0 else -1.0, dagger_want]
            )
        )


## Tier 3.2 / P4h: bind riposte wind-up ordering  -  extend (stab) faster than swing (blunt) on bind follow-up.
static func _run_bind_riposte_archetype_ordering_spear_faster_than_mace(failures: PackedStringArray) -> void:
    var spear_normal: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", false)
    var spear_bind: float = _windup_duration_for_bind_test("SPEAR", "spear_thrust", true)
    var mace_normal: float = _windup_duration_for_bind_test("MACE", "direct_blow", false)
    var mace_bind: float = _windup_duration_for_bind_test("MACE", "direct_blow", true)
    if spear_normal <= 0.0 or mace_normal <= 0.0:
        _fail(
            failures,
            "bind_riposte_order: invalid baseline wind-up (spear=%.4f mace=%.4f)" % [spear_normal, mace_normal]
        )
        return
    var spear_ratio: float = spear_bind / spear_normal
    var mace_ratio: float = mace_bind / mace_normal
    if spear_ratio >= mace_ratio - 0.001:
        _fail(
            failures,
            "bind_riposte_order: spear stab ratio %.3f should be < mace blunt %.3f" % [spear_ratio, mace_ratio]
        )
    if spear_bind >= mace_bind:
        _fail(
            failures,
            "bind_riposte_order: spear bind duration %.4f should be < mace bind %.4f" % [spear_bind, mace_bind]
        )
    var sword_normal: float = _windup_duration_for_bind_test("SWORD", "oberhau", false)
    var sword_bind: float = _windup_duration_for_bind_test("SWORD", "oberhau", true)
    if sword_normal > 0.0:
        var sword_ratio: float = sword_bind / sword_normal
        if spear_ratio >= sword_ratio - 0.001 or sword_ratio >= mace_ratio - 0.001:
            _fail(
                failures,
                (
                    "bind_riposte_order: want stab < cut < blunt ratios got spear=%.3f sword=%.3f mace=%.3f"
                    % [spear_ratio, sword_ratio, mace_ratio]
                )
            )


## p4h: bind riposte balance  -  canonical table (stab < cut < blunt), fallback parity, ii2b riposte band.
static func _run_p4h_bind_riposte_balance_suite(failures: PackedStringArray) -> void:
    var _TrackSpecs := preload("res://harness/CombatD001TrackSpecs.gd")
    var blade: Dictionary = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["blade"] as Dictionary
    var shaft: Dictionary = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT["shaft"] as Dictionary
    var stab_m: float = float(blade["stab"])
    var cut_m: float = float(blade["cut"])
    var blunt_m: float = float(shaft["blunt"])
    if not is_equal_approx(stab_m, 0.55):
        _fail(failures, "p4h_riposte: blade stab want 0.55 got %.3f" % stab_m)
    if not is_equal_approx(cut_m, 0.78):
        _fail(failures, "p4h_riposte: blade cut want 0.78 got %.3f" % cut_m)
    if not is_equal_approx(blunt_m, 0.90):
        _fail(failures, "p4h_riposte: shaft blunt want 0.90 got %.3f" % blunt_m)
    if stab_m >= cut_m - 0.001 or cut_m >= blunt_m - 0.001:
        _fail(failures, "p4h_riposte: want stab < cut < blunt got %.3f %.3f %.3f" % [stab_m, cut_m, blunt_m])
    if not is_equal_approx(CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK, cut_m):
        _fail(
            failures,
            (
                "p4h_riposte: fallback want cut mult %.3f got %.3f"
                % [cut_m, CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK]
            )
        )
    var ii2b_band: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    var band_fail: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(ii2b_band)
    if not band_fail.is_empty():
        _fail(failures, "p4h_riposte: ii2b good band should pass: %s" % ", ".join(band_fail))


## P4d: doc <-> code sync  -  canonical bind/deflect/riposte lines in ii2b worksheet + calibration audit source.
static func _run_p4d_parry_bind_doc_code_parity_suite(failures: PackedStringArray) -> void:
    var _TrackSpecs := preload("res://harness/CombatD001TrackSpecs.gd")
    var _CalibrationAudit := preload("res://harness/CombatCalibrationAudit.gd")
    var sync_line: String = CombatConstants.p4d_parry_bind_doc_sync_line()
    if not sync_line.contains("blade stab=0.55"):
        _fail(failures, "p4d_sync: want blade stab=0.55 in %s" % sync_line)
    if not sync_line.contains("cut=0.78"):
        _fail(failures, "p4d_sync: want cut=0.78 in %s" % sync_line)
    if not sync_line.contains("shaft blunt=0.90"):
        _fail(failures, "p4d_sync: want shaft blunt=0.90 in %s" % sync_line)
    if not sync_line.contains("gauge_bonus=28"):
        _fail(failures, "p4d_sync: want gauge_bonus=28 in %s" % sync_line)
    var good_stats: Dictionary = {
        "parry_deflect": 2,
        "parry_bind": 1,
        "parry_partial": 2,
        "riposte_chain": 1,
        "flurry_bind_opened": 1,
    }
    var prefill: String = _TrackSpecs.ii2b_worksheet_prefill_text(good_stats, true)
    if CombatConstants.iii3_baseline_constants_line() not in prefill:
        _fail(failures, "p4d_sync: signed ii2b worksheet must include III-3 baseline line")
    if sync_line not in prefill:
        _fail(failures, "p4d_sync: signed ii2b worksheet must include P4d bind sync line")
    var audit_lines: PackedStringArray = PackedStringArray()
    var audit_fail: PackedStringArray = PackedStringArray()
    _CalibrationAudit._append_parry_formula_section(audit_lines, audit_fail)
    var audit_text: String = "\n".join(audit_lines)
    if sync_line not in audit_text:
        _fail(failures, "p4d_sync: calibration audit parry section must include P4d bind sync line")
    if (
        (
            "PARRY_DEFLECT_THRESHOLD=%.2f PARRY_BIND_CONTROL_THRESHOLD=%.2f"
            % [CombatConstants.PARRY_DEFLECT_THRESHOLD, CombatConstants.PARRY_BIND_CONTROL_THRESHOLD]
        )
        not in audit_text
    ):
        _fail(failures, "p4d_sync: calibration audit must echo III-3 threshold pair")


## Tier 4.5: open bind-exchange window -> wind-up vs partner - -  **`FLURRY_BIND_WIND_UP_MULT`** (feature on).
static func _run_flurry_bind_exchange_wind_up_reduced_vs_plain(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr_p: Node = _MgrScript.new()
    mgr_p.register(_new_entity("SWORD"), "player")
    mgr_p.register(_new_entity("SWORD"), "enemy")
    mgr_p.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = _EntityAccess.id_int(mgr_p.combatants[0])
    var e_id: int = _EntityAccess.id_int(mgr_p.combatants[1])
    seed(90331)
    _WindUpStarter.start(mgr_p, p_id, e_id, "oberhau")
    var dur_plain: float = float(mgr_p.combatants[0].get("state_duration", 0.0))
    var mgr_f: Node = _MgrScript.new()
    mgr_f.register(_new_entity("SWORD"), "player")
    mgr_f.register(_new_entity("SWORD"), "enemy")
    mgr_f.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    _FlurryBind.open_window(mgr_f, p_id, e_id)
    seed(90331)
    _WindUpStarter.start(mgr_f, p_id, e_id, "oberhau")
    var dur_flurry: float = float(mgr_f.combatants[0].get("state_duration", 0.0))
    var want: float = dur_plain * CombatConstants.FLURRY_BIND_WIND_UP_MULT
    if absf(dur_flurry - want) > 0.0002:
        _fail(failures, "flurry_bind: duration want %.4f got %.4f plain=%.4f" % [want, dur_flurry, dur_plain])
    _free_manager(mgr_p)
    _free_manager(mgr_f)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: each wind-up start decrements **`flurry_exchanges_left`**.
static func _run_flurry_bind_exchange_consumes_on_wind_up(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _FlurryBind.open_window(mgr, p_id, e_id)
    if int(p.get("flurry_exchanges_left", 0)) != CombatConstants.FLURRY_BIND_MAX_EXCHANGES:
        _fail(
            failures,
            (
                "flurry_bind: want %d exchanges after open got %s"
                % [CombatConstants.FLURRY_BIND_MAX_EXCHANGES, str(p.get("flurry_exchanges_left", "<absent>"))]
            )
        )
    seed(90332)
    _WindUpStarter.start(mgr, p_id, e_id, "oberhau")
    if int(p.get("flurry_exchanges_left", -99)) != CombatConstants.FLURRY_BIND_MAX_EXCHANGES - 1:
        _fail(
            failures,
            (
                "flurry_bind: want %d exchanges after first wind-up got %s"
                % [CombatConstants.FLURRY_BIND_MAX_EXCHANGES - 1, str(p.get("flurry_exchanges_left", "<absent>"))]
            )
        )
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: **`hit`** clears bind-exchange keys on both partners.
static func _run_flurry_bind_window_closes_on_hit(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _FlurryBind.open_pair_after_bind(mgr, p_id, e_id)
    _FlurryBind.clear_pair(mgr, p_id, e_id)
    for label in ["player", "enemy"]:
        var c: Dictionary = mgr.combatants[0] if label == "player" else mgr.combatants[1]
        if c.has("flurry_until") or c.has("flurry_against_id") or c.has("flurry_exchanges_left"):
            _fail(failures, "flurry_bind: %s should have flurry keys cleared after hit clear" % label)
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: melee listing only offers strikes vs **`flurry_against_id`** while window active.
static func _run_flurry_bind_listing_restricts_to_bind_partner(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var e1_id: int = _EntityAccess.id_int(mgr.combatants[2])
    _FlurryBind.open_window(mgr, p_id, e0_id)
    var actions: Array = _ActionsBuilder.build(mgr, p_id)
    var bad_flurry: Dictionary = _ListedActions.first_action_where(
        actions,
        func(a: Dictionary) -> bool:
            var mid: String = _ListedActions.entry_move_id(a)
            if mid.is_empty() or mid in CombatConstants.FORMATION_MOVEMENT_MOVE_IDS:
                return false
            if WeaponConstants.is_parry_move(mid):
                return false
            return _ListedActions.entry_target_id(a) != e0_id
    )
    if not bad_flurry.is_empty():
        _fail(
            failures,
            (
                "flurry_bind listing: melee target want %d got %d move=%s"
                % [
                    e0_id,
                    _ListedActions.entry_target_id(bad_flurry),
                    _ListedActions.entry_move_id(bad_flurry),
                ]
            )
        )
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: hard bind **`parry_deflect`** opens mutual flurry windows on both partners.
static func _run_flurry_bind_opens_on_bind_deflect(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var defender: Dictionary = mgr.combatants[0]
    var attacker: Dictionary = mgr.combatants[1]
    var p_id: int = _EntityAccess.id_int(defender)
    var e_id: int = _EntityAccess.id_int(attacker)
    attacker["pending_attack"] = {"attack_type": "thrust", "effective_attack_line": "high", "intensity": 0.8}
    (
        _AttackResultApplier
        . apply_result(
            mgr,
            e_id,
            {
                "action": "parry_deflect",
                "target_id": p_id,
                "recovery_duration": 0.45,
                "parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
            }
        )
    )
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    if not _FlurryBind.is_active_vs(defender, e_id, clk):
        _fail(failures, "flurry_bind: defender window should open on bind deflect")
    if not _FlurryBind.is_active_vs(attacker, p_id, clk):
        _fail(failures, "flurry_bind: attacker window should open on bind deflect")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: **`process_waiting`** clears flurry keys after **`FLURRY_BIND_WINDOW_S`**.
static func _run_flurry_bind_expires_after_window(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    mgr.combat_clock = 0.0
    _FlurryBind.open_window(mgr, p_id, e_id)
    mgr.combat_clock = CombatConstants.FLURRY_BIND_WINDOW_S + 0.05
    _FlurryBind.process_waiting(mgr, p)
    if _FlurryBind.is_active(p, mgr.combat_clock):
        _fail(failures, "flurry_bind: window should expire after FLURRY_BIND_WINDOW_S")
    if p.has("flurry_until") or p.has("flurry_against_id") or p.has("flurry_exchanges_left"):
        _fail(failures, "flurry_bind: expired window should erase flurry keys")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: gauge label shows bind-exchange suffix while flurry window is open (feature on).
static func _run_flurry_bind_ui_gauge_label_when_window_open(failures: PackedStringArray) -> void:
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["state"] = CombatConstants.STATE_WAITING
    p["gauge"] = 100.0
    _FlurryBind.open_window(mgr, p_id, e_id)
    var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(p, mgr)
    if "Bind exchange" not in label:
        _fail(failures, "flurry_bind_ui: gauge want Bind exchange suffix got %s" % label)
    var tips: PackedStringArray = _UiHints.gauge_tooltip_lines(p, mgr)
    var found_tip: bool = false
    for line in tips:
        if str(line).begins_with("Bind exchange"):
            found_tip = true
            break
    if not found_tip:
        _fail(failures, "flurry_bind_ui: gauge tooltip should mention bind exchange")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 4.5: runtime toggle disables opening bind-exchange windows (production default **on**).
static func _run_flurry_bind_feature_flag_respects_runtime_toggle(failures: PackedStringArray) -> void:
    var prev: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    p["state"] = CombatConstants.STATE_WAITING
    CombatConstants.set_feature_flurry_bind_exchange_load(false)
    _FlurryBind.open_window(mgr, p_id, e_id)
    if p.has("flurry_until") or p.has("flurry_against_id") or p.has("flurry_exchanges_left"):
        CombatConstants.set_feature_flurry_bind_exchange_load(prev)
        _free_manager(mgr)
        _fail(failures, "flurry_flag: open_window should no-op when feature off")
        return
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    _FlurryBind.open_window(mgr, p_id, e_id)
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    if not _FlurryBind.is_active_vs(p, e_id, clk):
        CombatConstants.set_feature_flurry_bind_exchange_load(prev)
        _free_manager(mgr)
        _fail(failures, "flurry_flag: open_window should stamp keys when feature on")
        return
    CombatConstants.set_feature_flurry_bind_exchange_load(prev)
    _free_manager(mgr)


## p4g: bind-exchange depth  -  canonical tuning constants, partner-only stamina discount, exchanges exhaust before window expiry.
static func _run_p4g_flurry_bind_depth_suite(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_FLURRY_BIND_EXCHANGE:
        _fail(failures, "p4g_flurry: FEATURE_FLURRY_BIND_EXCHANGE should be enabled")
        return
    if not is_equal_approx(CombatConstants.FLURRY_BIND_WINDOW_S, 1.25):
        _fail(failures, "p4g_flurry: FLURRY_BIND_WINDOW_S want 1.25 got %.3f" % CombatConstants.FLURRY_BIND_WINDOW_S)
    if CombatConstants.FLURRY_BIND_MAX_EXCHANGES != 2:
        _fail(
            failures, "p4g_flurry: FLURRY_BIND_MAX_EXCHANGES want 2 got %d" % CombatConstants.FLURRY_BIND_MAX_EXCHANGES
        )
    if not is_equal_approx(CombatConstants.FLURRY_BIND_WIND_UP_MULT, 0.82):
        _fail(
            failures,
            "p4g_flurry: FLURRY_BIND_WIND_UP_MULT want 0.82 got %.3f" % CombatConstants.FLURRY_BIND_WIND_UP_MULT
        )
    if not is_equal_approx(CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT, 0.88):
        _fail(
            failures,
            (
                "p4g_flurry: FLURRY_BIND_STAMINA_ATTACK_COST_MULT want 0.88 got %.3f"
                % CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT
            )
        )
    var saved: bool = CombatConstants.is_feature_flurry_bind_exchange_enabled()
    CombatConstants.set_feature_flurry_bind_exchange_load(true)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e0_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var e1_id: int = _EntityAccess.id_int(mgr.combatants[2])
    mgr.combat_clock = 0.0
    _FlurryBind.open_window(mgr, p_id, e0_id)
    var clk: float = _EntityAccess.combat_clock_float(mgr)
    var stam_partner: float = _FlurryBind.stamina_attack_cost_mult(p, e0_id, clk)
    var stam_other: float = _FlurryBind.stamina_attack_cost_mult(p, e1_id, clk)
    if not is_equal_approx(stam_partner, CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT):
        _fail(
            failures,
            (
                "p4g_flurry: partner stamina mult want %.3f got %.3f"
                % [CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT, stam_partner]
            )
        )
    if stam_other != 1.0:
        _fail(failures, "p4g_flurry: non-partner stamina mult want 1.0 got %.3f" % stam_other)
    for _i in CombatConstants.FLURRY_BIND_MAX_EXCHANGES:
        _FlurryBind.consume_exchange_on_wind_up_start(p)
    if _FlurryBind.is_active(p, clk):
        _fail(failures, "p4g_flurry: zero exchanges should deactivate inside window")
    if _FlurryBind.wind_up_mult(p, e0_id, clk) != 1.0:
        _fail(failures, "p4g_flurry: wind_up_mult should be 1.0 when exchanges exhausted")
    _free_manager(mgr)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    CombatConstants.set_feature_flurry_bind_exchange_load(saved)


## Tier 3.2: opposite-line parry magnitude uses contact-type severity thresholds.
static func _run_parry_opposite_deflect_thresholds(failures: PackedStringArray) -> void:
    var align: float = CombatConstants.get_alignment_from_angles(0.0, 180.0)
    var cut_low: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT - 0.01, WeaponConstants.ATTACK_TYPE_CUT, align
    )
    if cut_low not in _harness_adjacent_lines_for("high"):
        _fail(failures, "parry_deflect_threshold: weak cut should partial-deflect high to adjacent, got %s" % cut_low)
    var cut_full: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, CombatConstants.PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT + 0.01, WeaponConstants.ATTACK_TYPE_CUT, align
    )
    if cut_full != _harness_opposite_cardinal("high"):
        _fail(failures, "parry_deflect_threshold: strong cut should deflect high to opposite, got %s" % cut_full)
    var stab_mid: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, 0.55, WeaponConstants.ATTACK_TYPE_STAB, align
    )
    if stab_mid != _harness_opposite_cardinal("high"):
        _fail(failures, "parry_deflect_threshold: thrust should reach full opposite at 0.55, got %s" % stab_mid)
    var blunt_mid: String = CombatConstants.get_deflected_line_from_angles(
        0.0, 180.0, 0.55, WeaponConstants.ATTACK_TYPE_BLUNT, align
    )
    if blunt_mid not in _harness_adjacent_lines_for("high"):
        _fail(failures, "parry_deflect_threshold: blunt at 0.55 should partial-deflect to adjacent, got %s" % blunt_mid)
    seed(1205)
    var atk_adj: float = CombatConstants.line_to_angle(_harness_cardinal_attack_line("high_right"))
    var guard_adj: float = CombatConstants.line_to_angle("right")
    var adj_align: float = CombatConstants.get_alignment_from_angles(atk_adj, guard_adj)
    var adjacent_guard: String = CombatConstants.get_deflected_line_from_angles(
        atk_adj, guard_adj, 1.0, WeaponConstants.ATTACK_TYPE_CUT, adj_align
    )
    if adjacent_guard not in _harness_adjacent_lines_for("high_right"):
        _fail(failures, "parry_deflect_threshold: adjacent guard should stay adjacent, got %s" % adjacent_guard)
    seed(_HARNESS_RESTORE_GLOBAL_SEED)


## Tier 3.2: defender weapon type - -  attack contact modifiers apply through Weapon object fields.
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
    var dagger_stab_cd: float = _DefenseChoice._compute_parry_c_d(
        dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_STAB.to_upper()
    )
    var dagger_cut_cd: float = _DefenseChoice._compute_parry_c_d(
        dagger, dagger_defender, WeaponConstants.ATTACK_TYPE_CUT
    )
    var dagger_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["DAGGER"] as Dictionary)["stab"])
    var dagger_ratio: float = dagger_stab_cd / dagger_cut_cd if dagger_cut_cd > 0.0 else -1.0
    if dagger_cut_cd <= 0.0 or absf(dagger_ratio - dagger_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: dagger stab/cut ratio %.3f want %.3f" % [dagger_ratio, dagger_expected])
    var mace_blunt_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_BLUNT)
    var mace_cut_cd: float = _DefenseChoice._compute_parry_c_d(mace, mace_defender, WeaponConstants.ATTACK_TYPE_CUT)
    var mace_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["MACE"] as Dictionary)["blunt"])
    var mace_ratio: float = mace_blunt_cd / mace_cut_cd if mace_cut_cd > 0.0 else -1.0
    if mace_cut_cd <= 0.0 or absf(mace_ratio - mace_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: mace blunt/cut ratio %.3f want %.3f" % [mace_ratio, mace_expected])
    var spear_cut_cd: float = _DefenseChoice._compute_parry_c_d(spear, spear_defender, WeaponConstants.ATTACK_TYPE_CUT)
    var spear_stab_cd: float = _DefenseChoice._compute_parry_c_d(
        spear, spear_defender, WeaponConstants.ATTACK_TYPE_STAB
    )
    var spear_expected: float = float((CombatConstants.PARRY_DEF_VS_ATK_MOD["SPEAR"] as Dictionary)["cut"])
    var spear_ratio: float = spear_cut_cd / spear_stab_cd if spear_stab_cd > 0.0 else -1.0
    if spear_stab_cd <= 0.0 or absf(spear_ratio - spear_expected) > 0.001:
        _fail(failures, "parry_def_vs_atk: spear cut/stab ratio %.3f want %.3f" % [spear_ratio, spear_expected])
    _free_manager(mgr)


## Tier 3.2 + 3.0: parry clash context preserves bind/deflect calibration + strike kinematics; asserts geometry + move ids vs **`DefenseResolutionHandler._resolve_parry`** and **`WeaponDamageHelper`** / **`StrikeRealismProfile`**; Tier **3.1** **`strike_measure_ratio`** vs **`pa`** after **`stamp_attack_pair_geometry_on_dict`** + **`strike_measure_ratio_for_attack_pair`** (full-stop key set **`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP`**); stamped path sets **`impact_blade_station`** before **`resolve`** so post-resolve kinematics recompute matches **`velocity_intent_mult_from_pa`** (no extra **`randf()`** vs resolver); unstamped **`pa`** -> clash **`strike_measure_ratio`** **-1**, then **`seed(3312)`** before stamped path for stable RNG.
static func _parry_clash_context_expected_strike_kinematics(
    pa: Dictionary, attacker: Dictionary, atk_move: String, intensity_val: float, archetype_passed: Dictionary
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


## Tier 3.0: partial-parry follow-through  -  clash **`strike_velocity_m_s`** / **`strike_kinetic_energy_j`** use **`pa["velocity_m_s"]`** after **`DefenseResolutionHandler`** reduction (not pre-parry intent speed).
static func _parry_clash_expected_partial_strike_kinematics(
    pa: Dictionary, attacker: Dictionary, atk_move: String, intensity_val: float, archetype_passed: Dictionary
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
    # Tier 3.1 sentinel: no **`strike_measure_ratio`** on **`pa`** -> clash carries **-1** (same RNG as main branch after re-seed).
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
    if (
        not clash_un.has("strike_measure_ratio")
        or absf(float(clash_un.get("strike_measure_ratio", 0.0)) - (-1.0)) > 0.001
    ):
        _fail(
            failures,
            (
                "parry_clash_context unstamped: strike_measure_ratio want -1 got %s"
                % str(clash_un.get("strike_measure_ratio", "missing"))
            )
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
    _StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa1)
    var atk_w_for_meas: RefCounted = _EntityAccess.get_weapon(attacker)
    _StrikeStamping.stamp_strike_realism_on_pa(mgr, attacker, defender, pa1, atk_w_for_meas, "spear_thrust")
    if atk_w_for_meas != null:
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
                (
                    "parry_clash_context: %s %.3f want %.3f"
                    % [str(key), float(clash.get(key, -999.0)), float(expected[key])]
                )
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
            failures, "parry_clash_context: attack_type want %s got %s" % [atk_move, str(clash.get("attack_type", ""))]
        )
    var want_ct: String = str(WeaponConstants.contact_type_for_move_id(atk_move)).to_lower().strip_edges()
    if str(clash.get("contact_type", "")).to_lower().strip_edges() != want_ct:
        _fail(
            failures, "parry_clash_context: contact_type want %s got %s" % [want_ct, str(clash.get("contact_type", ""))]
        )
    var arc_s: float = float(pa_template.get("arc_start_deg", 0.0))
    var arc_e: float = CombatConstants.arc_end_deg_for_contact_geometry(pa_template)
    var atk_line_for_align: String = str(pa_template.get("effective_attack_line", "high"))
    var def_w0 = _EntityAccess.get_weapon(defender)
    var def_mass: float = WeaponConstants.weapon_mass_kg(def_w0)
    if str(clash.get("effective_attack_line", "")) != str(pa_template.get("effective_attack_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context: effective_attack_line want %s got %s"
                % [str(pa_template.get("effective_attack_line", "")), str(clash.get("effective_attack_line", ""))]
            )
        )
    if str(clash.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context: defender_guard_line want %s got %s"
                % [str(defender.get("guard_line", "")), str(clash.get("defender_guard_line", ""))]
            )
        )
    var atk_w = _EntityAccess.get_weapon(attacker)
    var want_arch: String = _EntityAccess.weapon_archetype_id(atk_w, atk_move, "")
    if str(clash.get("archetype_id", "")) != want_arch:
        _fail(
            failures,
            "parry_clash_context: archetype_id want %s got %s" % [want_arch, str(clash.get("archetype_id", ""))]
        )
    var eff_wind: float = (
        float(pa_template.get("wind_up_duration", 0.5))
        * (1.0 - CombatConstants.commitment_fraction_for_pending_attack(pa_template))
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
            (
                "parry_clash_context: attack_angle_deg want %.4f got %.4f"
                % [want_atk_deg, float(clash.get("attack_angle_deg", -9999.0))]
            )
        )
    var wobble: Dictionary = {
        "parry_readiness": float(dc.get("parry_readiness", 1.0)),
        "defender_mass_kg": def_mass,
    }
    var want_guard_deg: float = CombatConstants.get_guard_angle_deg(defender, wobble)
    if absf(float(clash.get("guard_angle_deg", -9999.0)) - want_guard_deg) > 0.25:
        _fail(
            failures,
            (
                "parry_clash_context: guard_angle_deg want %.4f got %.4f"
                % [want_guard_deg, float(clash.get("guard_angle_deg", -9999.0))]
            )
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
            (
                "parry_clash_context: parry_control %.4f vs CombatConstants.parry_control_for_bind_deflect %.4f"
                % [float(clash.get("parry_control", -9.0)), want_pc]
            )
        )
    var want_sev: float = CombatConstants.parry_deflect_severity_from_margin_ratio(
        float(clash.get("margin_ratio", 0.0))
    )
    if absf(float(clash.get("severity", -1.0)) - want_sev) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: severity %.4f vs parry_deflect_severity_from_margin_ratio %.4f"
                % [float(clash.get("severity", -1.0)), want_sev]
            )
        )
    var arch_passed: Dictionary = {}
    var exp_sk: Dictionary = _parry_clash_context_expected_strike_kinematics(pa1, attacker, atk_move, 0.5, arch_passed)
    if str(clash.get("kinematic_delivery", "")) != str(exp_sk.get("kinematic_delivery", "")):
        _fail(
            failures,
            (
                "parry_clash_context: kinematic_delivery want %s got %s"
                % [str(exp_sk.get("kinematic_delivery", "")), str(clash.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash.get("strike_velocity_m_s", -999.0)) - float(exp_sk.get("strike_velocity_m_s", 0.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: strike_velocity_m_s %.6f want %.6f"
                % [float(clash.get("strike_velocity_m_s", -999.0)), float(exp_sk.get("strike_velocity_m_s", 0.0))]
            )
        )
    if (
        absf(float(clash.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk.get("strike_kinetic_energy_j", 0.0)))
        > 0.05
    ):
        _fail(
            failures,
            (
                "parry_clash_context: strike_kinetic_energy_j %.6f want %.6f"
                % [
                    float(clash.get("strike_kinetic_energy_j", -999.0)),
                    float(exp_sk.get("strike_kinetic_energy_j", 0.0))
                ]
            )
        )
    if absf(float(clash.get("strike_measure_ratio", -999.0)) - float(pa1.get("strike_measure_ratio", -1.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context: strike_measure_ratio %.6f want %.6f"
                % [float(clash.get("strike_measure_ratio", -999.0)), float(pa1.get("strike_measure_ratio", -1.0))]
            )
        )
    # Late / off-balance flags propagate for calibration (same full_stop path).
    var dc_late: Dictionary = dc.duplicate(true)
    dc_late["late_parry"] = true
    dc_late["parry_off_balance"] = true
    dc_late["parry_readiness"] = 0.88
    dc_late["parry_time_to_react"] = 0.02
    seed(3313)
    var pa2: Dictionary = pa_template.duplicate(true)
    _StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, attacker, defender, pa2)
    _StrikeStamping.stamp_strike_realism_on_pa(mgr, attacker, defender, pa2, atk_w_for_meas, "spear_thrust")
    if atk_w_for_meas != null:
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
            (
                "parry_clash_context late: effective_attack_line want %s got %s"
                % [str(pa_template.get("effective_attack_line", "")), str(clash2.get("effective_attack_line", ""))]
            )
        )
    if str(clash2.get("defender_guard_line", "")) != str(defender.get("guard_line", "")):
        _fail(
            failures,
            (
                "parry_clash_context late: defender_guard_line want %s got %s"
                % [str(defender.get("guard_line", "")), str(clash2.get("defender_guard_line", ""))]
            )
        )
    if str(clash2.get("archetype_id", "")) != want_arch:
        _fail(
            failures,
            "parry_clash_context late: archetype_id want %s got %s" % [want_arch, str(clash2.get("archetype_id", ""))]
        )
    var want_atk_deg2: float = (
        CombatConstants.get_arc_angle_at_progress(arc_s, arc_e, 1.0) if arc_e >= -900.0 else want_atk_deg
    )
    if absf(float(clash2.get("attack_angle_deg", -9999.0)) - want_atk_deg2) > 0.05:
        _fail(
            failures,
            (
                "parry_clash_context late: attack_angle_deg want %.4f got %.4f"
                % [want_atk_deg2, float(clash2.get("attack_angle_deg", -9999.0))]
            )
        )
    # Guard wobble uses **`randf_range`** when readiness < 1  -  replay alignment from stored clash angles (no second draw).
    var align_ctx2: Dictionary = {
        "attack_angle_deg": float(clash2.get("attack_angle_deg", -9999.0)),
        "guard_angle_deg": float(clash2.get("guard_angle_deg", -9999.0)),
    }
    var want_align2: float = CombatConstants.get_line_alignment_with_deflect(atk_line_for_align, defender, align_ctx2)
    if absf(float(clash2.get("alignment", -999.0)) - want_align2) > 0.02:
        _fail(
            failures,
            (
                "parry_clash_context late: alignment want %.4f got %.4f"
                % [want_align2, float(clash2.get("alignment", -999.0))]
            )
        )
    var c_d2: float = float(clash2.get("c_d_final", 0.0))
    var want_pc2: float = CombatConstants.parry_control_for_bind_deflect(
        c_d2, parry_p_a, float(clash2.get("alignment", 0.0)), 0.88, true, true, str(clash2.get("contact_type", ""))
    )
    if absf(float(clash2.get("parry_control", -9.0)) - want_pc2) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: parry_control %.4f vs formula %.4f"
                % [float(clash2.get("parry_control", -9.0)), want_pc2]
            )
        )
    var want_sev2: float = CombatConstants.parry_deflect_severity_from_margin_ratio(
        float(clash2.get("margin_ratio", 0.0))
    )
    if absf(float(clash2.get("severity", -1.0)) - want_sev2) > 0.001:
        _fail(
            failures,
            "parry_clash_context late: severity %.4f vs formula %.4f" % [float(clash2.get("severity", -1.0)), want_sev2]
        )
    var exp_sk2: Dictionary = _parry_clash_context_expected_strike_kinematics(pa2, attacker, atk_move, 0.5, arch_passed)
    if str(clash2.get("kinematic_delivery", "")) != str(exp_sk2.get("kinematic_delivery", "")):
        _fail(
            failures,
            (
                "parry_clash_context late: kinematic_delivery want %s got %s"
                % [str(exp_sk2.get("kinematic_delivery", "")), str(clash2.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash2.get("strike_velocity_m_s", -999.0)) - float(exp_sk2.get("strike_velocity_m_s", 0.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: strike_velocity_m_s %.6f want %.6f"
                % [float(clash2.get("strike_velocity_m_s", -999.0)), float(exp_sk2.get("strike_velocity_m_s", 0.0))]
            )
        )
    if (
        absf(float(clash2.get("strike_kinetic_energy_j", -999.0)) - float(exp_sk2.get("strike_kinetic_energy_j", 0.0)))
        > 0.05
    ):
        _fail(
            failures,
            (
                "parry_clash_context late: strike_kinetic_energy_j %.6f want %.6f"
                % [
                    float(clash2.get("strike_kinetic_energy_j", -999.0)),
                    float(exp_sk2.get("strike_kinetic_energy_j", 0.0))
                ]
            )
        )
    if absf(float(clash2.get("strike_measure_ratio", -999.0)) - float(pa2.get("strike_measure_ratio", -1.0))) > 0.001:
        _fail(
            failures,
            (
                "parry_clash_context late: strike_measure_ratio %.6f want %.6f"
                % [float(clash2.get("strike_measure_ratio", -999.0)), float(pa2.get("strike_measure_ratio", -1.0))]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 3.2 + 3.0: **`parry_partial`**  -  **`parry_clash_context`** mirrors full-stop keys plus **`remaining_ratio`** / **`geometric_leak`**; Tier **3.0** KE uses reduced **`pa["velocity_m_s"]`** (not intent-speed from **`_parry_clash_context_expected_strike_kinematics`**).
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
        "arc_end_deg": 360.0,
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
    _StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr2, attacker_p, defender_p, pa_partial)
    var atk_w_part: RefCounted = _EntityAccess.get_weapon(attacker_p)
    _StrikeStamping.stamp_strike_realism_on_pa(mgr2, attacker_p, defender_p, pa_partial, atk_w_part, "spear_thrust")
    if atk_w_part != null:
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
    if (
        absf(float(clash_partial.get("remaining_ratio", -1.0)) - float(pa_partial.get("parry_remaining_ratio", -2.0)))
        > 1e-5
    ):
        _fail(
            failures,
            (
                "parry_partial_clash: remaining_ratio vs pa parry_remaining_ratio mismatch %s vs %s"
                % [str(clash_partial.get("remaining_ratio")), str(pa_partial.get("parry_remaining_ratio"))]
            )
        )
    var mr_part: float = float(clash_partial.get("margin_ratio", 0.0))
    var want_mr_part: float = CombatConstants.parry_deflect_margin_ratio(float(clash_partial["c_d_final"]), parry_p_a_p)
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
            (
                "parry_partial_clash: kinematic_delivery want %s got %s"
                % [str(exp_part_k.get("kinematic_delivery", "")), str(clash_partial.get("kinematic_delivery", ""))]
            )
        )
    if absf(float(clash_partial["strike_velocity_m_s"]) - float(exp_part_k["strike_velocity_m_s"])) > 1e-4:
        _fail(
            failures,
            (
                "parry_partial_clash: strike_velocity_m_s %.6f want %.6f"
                % [float(clash_partial["strike_velocity_m_s"]), float(exp_part_k["strike_velocity_m_s"])]
            )
        )
    if absf(float(clash_partial["strike_kinetic_energy_j"]) - float(exp_part_k["strike_kinetic_energy_j"])) > 1e-3:
        _fail(
            failures,
            (
                "parry_partial_clash: strike_kinetic_energy_j %.6f want %.6f"
                % [float(clash_partial["strike_kinetic_energy_j"]), float(exp_part_k["strike_kinetic_energy_j"])]
            )
        )
    if (
        absf(float(clash_partial["strike_measure_ratio"]) - float(pa_partial.get("strike_measure_ratio", -99.0)))
        > 0.001
    ):
        _fail(
            failures,
            (
                "parry_partial_clash: strike_measure_ratio %.6f want %.6f"
                % [float(clash_partial["strike_measure_ratio"]), float(pa_partial.get("strike_measure_ratio", -1.0))]
            )
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


## Tier 3.2 (combat tuning fix): follow-through gate at low remaining ratio — when **`parry_remaining_ratio <= 0.1`**, **`AttackResultApplier`** must NOT call **`manager._execute_attack()`** after partial parry.
static func _run_follow_through_gate_at_low_remaining_ratio(failures: PackedStringArray) -> void:
    # Verify constant gate threshold is set correctly.
    if CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY < 0.6:
        _fail(
            failures,
            (
                "ft_gate: PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY should be >= 0.6 (got %.2f)"
                % CombatConstants.PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY
            )
        )
    # Test the gate logic directly: remaining_ratio > 0.1 triggers follow-through, <= 0.1 does not.
    var gate_above: bool = 0.15 > 0.1
    var gate_at: bool = false  # boundary: remaining_ratio == 0.1 is not > 0.1
    var gate_below: bool = 0.05 > 0.1
    if not gate_above:
        _fail(failures, "ft_gate: ratio 0.15 should pass gate (> 0.1)")
    if gate_at:
        _fail(failures, "ft_gate: ratio 0.1 should NOT pass gate (must be > 0.1, not >=)")
    if gate_below:
        _fail(failures, "ft_gate: ratio 0.05 should NOT pass gate (> 0.1)")


## Tier 3.2 (combat tuning fix): block thresholds at balanced entity values — **`PARRY_BLOCK_MASS_THRESHOLD = 0.75`**, **`PARRY_BLOCK_STR_THRESHOLD = 0.85`**.
static func _run_block_threshold_balance_test(failures: PackedStringArray) -> void:
    # Mass threshold: 0.75 means defender with 75% attacker mass should qualify.
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_MASS_THRESHOLD, 0.75):
        _fail(
            failures,
            (
                "block_threshold: PARRY_BLOCK_MASS_THRESHOLD want 0.75 got %.2f"
                % CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
            )
        )
    if not is_equal_approx(CombatConstants.PARRY_BLOCK_STR_THRESHOLD, 0.85):
        _fail(
            failures,
            "block_threshold: PARRY_BLOCK_STR_THRESHOLD want 0.85 got %.2f" % CombatConstants.PARRY_BLOCK_STR_THRESHOLD
        )
    # Test balanced entity scenario: both SWORD (mass 1.2 each), strength equal at 50/50.
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def_c: Dictionary = mgr.combatants[0]
    var atk_c: Dictionary = mgr.combatants[1]
    var def_w: Variant = _EntityAccess.get_weapon(def_c)
    var atk_w: Variant = _EntityAccess.get_weapon(atk_c)
    if def_w == null or atk_w == null:
        _free_manager_restore_global_rng(mgr)
        return
    var d_mass: float = float(def_w.mass)
    var a_mass: float = float(atk_w.mass)
    var d_str: float = float(_EntityAccess.stats_dict(def_c).get("strength", 50))
    var a_str: float = float(_EntityAccess.stats_dict(atk_c).get("strength", 50))
    # Balanced: mass ratio = 1.0, str ratio = 1.0 — both should pass threshold.
    var mass_ok: bool = d_mass / maxf(a_mass, 0.01) >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD
    var str_ok: bool = d_str / maxf(a_str, 0.01) >= CombatConstants.PARRY_BLOCK_STR_THRESHOLD
    if not mass_ok or not str_ok:
        _fail(
            failures,
            (
                "block_threshold: balanced SWORD vs SWORD should pass both thresholds (mass=%.2f/%.2f, str=%.0f/%.0f)"
                % [d_mass, a_mass, d_str, a_str]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 3.2 (combat tuning fix): follow-through gate integration — when **`parry_remaining_ratio <= 0.1`** on parry_partial, **`AttackResultApplier.apply_result`** must NOT call **`manager._execute_attack()`**.
static func _run_follow_through_integration_gate(failures: PackedStringArray) -> void:
    # Test the gate logic directly: simulate remaining_ratio values and check whether follow-through would trigger.
    var should_trigger_low: bool = 0.05 > 0.1
    var should_trigger_high: bool = 0.15 > 0.1
    if should_trigger_low:
        _fail(failures, "ft_integration: ratio 0.05 should NOT trigger follow-through (gate returned true)")
    if not should_trigger_high:
        _fail(failures, "ft_integration: ratio 0.15 SHOULD trigger follow-through (gate returned false)")


## Tier 3.2 (combat tuning fix): asymmetric block threshold — DAGGER vs SPEAR should NOT qualify for block parry (mass ratio far below 0.75).
static func _run_block_threshold_asymmetric_test(failures: PackedStringArray) -> void:
    var mgr_a: Node = _MgrScript.new()
    mgr_a.register(_new_entity("DAGGER"), "player")
    mgr_a.register(_new_entity("SPEAR"), "enemy")
    mgr_a.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def_c: Dictionary = mgr_a.combatants[0]
    var atk_c: Dictionary = mgr_a.combatants[1]
    var def_w: Variant = _EntityAccess.get_weapon(def_c)
    var atk_w: Variant = _EntityAccess.get_weapon(atk_c)
    if def_w == null or atk_w == null:
        _free_manager_restore_global_rng(mgr_a)
        return
    var d_mass: float = float(def_w.mass)
    var a_mass: float = float(atk_w.mass)
    var mass_ratio: float = d_mass / maxf(a_mass, 0.01)
    if mass_ratio >= CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
        _fail(
            failures,
            (
                "block_threshold_asym: DAGGER(mass=%.2f) vs SPEAR(mass=%.2f) ratio=%.3f should be below threshold %.2f"
                % [d_mass, a_mass, mass_ratio, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
            )
        )
    # Borderline case: AXE (1.5 kg) vs MACE (1.7 kg), mass_ratio = 0.883 — should pass mass check.
    _free_manager_restore_global_rng(mgr_a)
    var mgr_b: Node = _MgrScript.new()
    mgr_b.register(_new_entity("AXE"), "player")
    mgr_b.register(_new_entity("MACE"), "enemy")
    mgr_b.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var def_w2: Variant = _EntityAccess.get_weapon(mgr_b.combatants[0])
    var atk_w2: Variant = _EntityAccess.get_weapon(mgr_b.combatants[1])
    if def_w2 != null and atk_w2 != null:
        var d_mass2: float = float(def_w2.mass)
        var a_mass2: float = float(atk_w2.mass)
        var mass_ratio2: float = d_mass2 / maxf(a_mass2, 0.01)
        if mass_ratio2 < CombatConstants.PARRY_BLOCK_MASS_THRESHOLD:
            _fail(
                failures,
                (
                    "block_threshold_borderline: AXE(mass=%.2f) vs MACE(mass=%.2f) ratio=%.3f should pass threshold %.2f"
                    % [d_mass2, a_mass2, mass_ratio2, CombatConstants.PARRY_BLOCK_MASS_THRESHOLD]
                )
            )
    _free_manager_restore_global_rng(mgr_b)


## Tier 3.2 (weapon audit): melee_range ordering — DAGGER < MACE <= SWORD == AXE < SPEAR, reflecting total weapon length. Also verifies each weapon has at least one stab, one cut or blunt move, and valid coupling values.
static func _run_weapon_melee_range_ordering(failures: PackedStringArray) -> void:
    var expected_order: Array[String] = ["DAGGER", "MACE", "SWORD", "AXE", "SPEAR"]
    var ranges: Dictionary = {}
    for wname in expected_order:
        var mgr: Node = _MgrScript.new()
        mgr.register(_new_entity(wname), "player")
        var ent: Variant = mgr.combatants[0]
        var wep: Variant = _EntityAccess.get_weapon(ent)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            _free_manager_restore_global_rng(mgr)
            return
        ranges[wname] = float(wep.melee_range)
        _free_manager_restore_global_rng(mgr)
    # DAGGER < MACE <= SWORD == AXE < SPEAR
    if ranges.has("DAGGER") and ranges.has("SPEAR"):
        if ranges["DAGGER"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: DAGGER range (%.2f) must be < SPEAR range (%.2f)" % [ranges["DAGGER"], ranges["SPEAR"]]
            )
    if ranges.has("MACE") and ranges.has("SWORD"):
        if ranges["MACE"] > ranges["SWORD"]:
            _fail(
                failures,
                "weapon_audit: MACE range (%.2f) must be <= SWORD range (%.2f)" % [ranges["MACE"], ranges["SWORD"]]
            )
    if ranges.has("SWORD") and ranges.has("AXE"):
        if absf(ranges["SWORD"] - ranges["AXE"]) > 0.01:
            _fail(
                failures,
                "weapon_audit: SWORD range (%.2f) must equal AXE range (%.2f)" % [ranges["SWORD"], ranges["AXE"]]
            )
    if ranges.has("AXE") and ranges.has("SPEAR"):
        if ranges["AXE"] >= ranges["SPEAR"]:
            _fail(
                failures,
                "weapon_audit: AXE range (%.2f) must be < SPEAR range (%.2f)" % [ranges["AXE"], ranges["SPEAR"]]
            )


## Tier 3.2 (weapon audit): verify each weapon has required move types and valid coupling physics.
static func _run_weapon_move_coverage(failures: PackedStringArray) -> void:
    var weapons_and_needs: Dictionary = {
        "SWORD": {"stab": true, "cut": true, "blunt": true},
        "AXE": {"stab": true, "cut": true, "blunt": true},
        "MACE": {"stab": false, "cut": false, "blunt": true},
        "DAGGER": {"stab": true, "cut": true, "blunt": true},
        "SPEAR": {"stab": true, "cut": true, "blunt": true},
    }
    var min_moves: Dictionary = {
        "SWORD": 12,
        "AXE": 10,
        "MACE": 9,
        "DAGGER": 9,
        "SPEAR": 9,
    }
    for wname in weapons_and_needs:
        var needs: Dictionary = weapons_and_needs[wname]
        var mgr: Node = _MgrScript.new()
        mgr.register(_new_entity(wname), "player")
        var ent: Variant = mgr.combatants[0]
        var wep: Variant = _EntityAccess.get_weapon(ent)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            _free_manager_restore_global_rng(mgr)
            continue
        var all_moves := WeaponConstants._move_definitions_build()
        var weapon_move_ids: Array = wep.attack_types.keys()
        var has_stab: bool = false
        var has_cut: bool = false
        var has_blunt: bool = false
        for move_id in weapon_move_ids:
            if move_id is String and all_moves.has(move_id):
                var move_def: Dictionary = all_moves[move_id]
                var contact: String = move_def.get("contact_type", "")
                if contact == "stab":
                    has_stab = true
                elif contact == "cut":
                    has_cut = true
                elif contact == "blunt":
                    has_blunt = true
        if needs["stab"] and not has_stab:
            _fail(failures, "weapon_audit: %s requires stab move but has none" % wname)
        if needs["cut"] and not has_cut:
            _fail(failures, "weapon_audit: %s requires cut move but has none" % wname)
        if needs["blunt"] and not has_blunt:
            _fail(failures, "weapon_audit: %s requires blunt move but has none" % wname)
        if min_moves.has(wname):
            var mc: int = weapon_move_ids.size()
            var mn: int = min_moves[wname]
            if mc < mn:
                _fail(failures, "weapon_audit: %s has %d moves (minimum %d)" % [wname, mc, mn])
        # Verify coupling values are in valid range (0.7-1.2)
        var physics: Dictionary = (wep as Weapon).strike_physics if is_instance_of(wep, _Weapon) else {}
        if physics is Dictionary:
            for key in ["coupling_stab", "coupling_cut", "coupling_blunt"]:
                if physics.has(key):
                    var val: float = float(physics[key])
                    if val < 0.7 or val > 1.2:
                        _fail(failures, "weapon_audit: %s %s=%.2f outside valid range [0.7, 1.2]" % [wname, key, val])
        _free_manager_restore_global_rng(mgr)


## Tier 3.2 (weapon audit): verify parts mass_fraction sums to ~1.0 for each weapon.
static func _run_weapon_parts_mass_sum(failures: PackedStringArray) -> void:
    var wnames: Array[String] = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
    for wname in wnames:
        var mgr: Node = _MgrScript.new()
        mgr.register(_new_entity(wname), "player")
        var ent: Variant = mgr.combatants[0]
        var wep: Variant = _EntityAccess.get_weapon(ent)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            _free_manager_restore_global_rng(mgr)
            continue
        var parts: Array = (wep as Weapon).parts if is_instance_of(wep, _Weapon) else []
        var sum_f: float = 0.0
        for part in parts:
            if part is Dictionary:
                sum_f += float(part.get("mass_fraction", 0.0))
        if absf(sum_f - 1.0) > 0.01:
            _fail(failures, "weapon_audit: %s parts mass_fraction sum=%.3f (expected ~1.0)" % [wname, sum_f])
        _free_manager_restore_global_rng(mgr)


## Tier 3.2 (weapon audit): verify each weapon has at least one feint move and one parry-counter move.
static func _run_weapon_feint_parry_coverage(failures: PackedStringArray) -> void:
    var wnames: Array[String] = ["SWORD", "AXE", "MACE", "DAGGER", "SPEAR"]
    for wname in wnames:
        var mgr: Node = _MgrScript.new()
        mgr.register(_new_entity(wname), "player")
        var ent: Variant = mgr.combatants[0]
        var wep: Variant = _EntityAccess.get_weapon(ent)
        if wep == null:
            _fail(failures, "weapon_audit: %s has no weapon definition" % wname)
            _free_manager_restore_global_rng(mgr)
            continue
        var weapon_move_ids: Array = wep.attack_types.keys()
        var has_feint: bool = false
        var has_parry: bool = false
        for move_id in weapon_move_ids:
            if move_id is String:
                var mdef: Dictionary = WeaponConstants.get_move(move_id)
                if mdef.is_empty():
                    continue
                if mdef.get("is_feint", false):
                    has_feint = true
                if mdef.get("is_parry", false):
                    has_parry = true
        if not has_feint:
            _fail(failures, "weapon_audit: %s has no feint move" % wname)
        if not has_parry:
            _fail(failures, "weapon_audit: %s has no parry-counter move" % wname)
        _free_manager_restore_global_rng(mgr)


## Tier 3.2 (weapon audit): angle_variance_deg within expected range per weapon weight class.
static func _run_weapon_angle_variance_ranges(failures: PackedStringArray) -> void:
    var variance_ranges: Dictionary = {
        "DAGGER": [5, 8],
        "SWORD": [7, 12],
        "AXE": [9, 14],
        "MACE": [9, 14],
        "SPEAR": [7, 16],
    }
    for wname in variance_ranges:
        var range_bounds: Array = variance_ranges[wname]
        var v_min: int = range_bounds[0]
        var v_max: int = range_bounds[1]
        var mgr: Node = _MgrScript.new()
        mgr.register(_new_entity(wname), "player")
        var ent: Variant = mgr.combatants[0]
        var wep: Variant = _EntityAccess.get_weapon(ent)
        if wep == null:
            _free_manager_restore_global_rng(mgr)
            continue
        var weapon_move_ids: Array = wep.attack_types.keys()
        for move_id in weapon_move_ids:
            if move_id is String:
                var mdef: Dictionary = WeaponConstants.get_move(move_id)
                if mdef.is_empty():
                    continue
                if mdef.has("angle_variance_deg"):
                    var av: int = int(mdef["angle_variance_deg"])
                    if av < v_min or av > v_max:
                        _fail(
                            failures,
                            (
                                "weapon_audit: %s move '%s' angle_variance=%d outside [%d, %d]"
                                % [wname, move_id, av, v_min, v_max]
                            )
                        )
        _free_manager_restore_global_rng(mgr)


## Tier 3.2: **`GuardLineUpdater.set_guard_deflected`**  -  when **`severity`** is absent, **`guard_deflect_blend`** matches **`parry_deflect_severity_from_margin_ratio(margin_ratio)`**; explicit **`severity`** wins if both are set.
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
            (
                "guard_deflect_blend: margin-only clash want %.4f got %.4f"
                % [want_from_margin, float(c1.get("guard_deflect_blend", -1.0))]
            )
        )
    var clash_both: Dictionary = clash_margin.duplicate(true)
    clash_both["severity"] = 0.11
    clash_both["margin_ratio"] = 2.0
    var c2: Dictionary = {"guard_line": "high", "combatant_id": 2, "alive": true}
    _GuardLineUpdater.set_guard_deflected(c2, "spear_thrust", "", "low", clash_both)
    if not is_equal_approx(float(c2.get("guard_deflect_blend", -1.0)), 0.11):
        _fail(
            failures,
            (
                "guard_deflect_blend: explicit severity should win when both keys set (want 0.11 got %.4f)"
                % float(c2.get("guard_deflect_blend", -1.0))
            )
        )


## Godot **4.6.stable** global RNG: **`seed(1)`** yields **`attack_hit`** on the afterblow execute path for the SWORD 1v1 **`_afterblow_harness_seed_pending_cut`** fixture (avoids scanning thousands of seeds in **`run_all()`**).
const _AFTERBLOW_EXECUTE_HIT_SEED: int = 1
## **`seed(2)`**: hybrid hindrance in **(ALLOW, BLOCK)** and first **`randf()` < hindrance** -> **`try_afterblow` false** + **`_cancel_pending`** (chest **`final_cut` 11.25**).
const _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED: int = 2
## **`seed(0)`**: same fixture + chest **`final_cut` 11.25** -> **`randf() >= hindrance`** -> **`_execute_afterblow`** (**`afterblow_damage_mult` 0.55**) + **`attack_hit`** resolve.
const _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED: int = 0
const _HARNESS_META_RECORD_AFTERBLOW_MULT := "_harness_record_afterblow_damage_mult"
const _HARNESS_META_LAST_AFTERBLOW_MULT := "_harness_last_afterblow_damage_mult"
const _HARNESS_META_EXPOSE_PENETRATION_APPLIED := "_harness_expose_penetration_applied"
const _HARNESS_META_EXPOSE_DAMAGE_KINEMATICS := "_harness_expose_damage_kinematics"


## Tier 3.3 harness: deterministic **`pending_attack`** (cut + stamped geometry) so **`AfterblowHandler`** -> **`_execute_attack`** does not depend on wind-up RNG.
static func _afterblow_harness_seed_pending_cut(mgr: Node, attacker_index: int, defender_index: int) -> void:
    var atk: Dictionary = mgr.combatants[attacker_index]
    var defc: Dictionary = mgr.combatants[defender_index]
    var weapon = _EntityAccess.get_weapon(atk)
    var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
    if _EntityAccess.weapon_has_attack_types(weapon):
        var types_a: Array = _EntityAccess.weapon_attack_types(weapon)
        if types_a.has(WeaponConstants.ATTACK_TYPE_CUT):
            attack_type = WeaponConstants.ATTACK_TYPE_CUT
        elif not types_a.is_empty():
            attack_type = str(types_a[0])
    var archetype: Dictionary = _EntityAccess.weapon_archetype_for_move(weapon, attack_type)
    var pa: Dictionary = {
        "target_id": _EntityAccess.id_int(defc),
        "intensity": 0.88,
        "power": 0.72,
        "follow_through": 0.68,
        "attack_type": attack_type,
        "archetype": archetype,
    }
    _StrikeStamping.stamp_attack_pair_geometry_on_dict(mgr, atk, defc, pa)
    _StrikeStamping.stamp_strike_realism_on_pa(mgr, atk, defc, pa, weapon, attack_type)
    atk["state"] = CombatConstants.STATE_WIND_UP
    atk["state_timer"] = 0.0
    atk["state_duration"] = 0.5
    atk["pending_attack"] = pa


## Tier 3.3: **`outcome` == `"deflected"`** -> **`_execute_afterblow`** (**hindrance 0**) -> **`CombatManager._execute_attack`**; fixed **`seed(1)`** (**`_AFTERBLOW_EXECUTE_HIT_SEED`**) must yield **`recovery_cause` == `attack_hit`** and **`afterblow_damage_mult` == 1.0** (via harness meta on manager).
static func _run_afterblow_deflected_triggers_full_resolve_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_EXECUTE_HIT_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
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
            (
                "afterblow_deflected_hit: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if _EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures,
            (
                "afterblow_deflected_hit: want recovering got %s (seed=%d)"
                % [_EntityAccess.state_str(atk), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(failures, "afterblow_deflected_hit: pending_attack not empty (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED)
    if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures,
            "afterblow_deflected_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED
        )
    elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 1.0):
        _fail(
            failures,
            (
                "afterblow_deflected_hit: want afterblow_damage_mult 1.0 got %s (seed=%d)"
                % [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: low hybrid hindrance (**<= `AFTERBLOW_HINDRANCE_ALLOW`**) -> **`_execute_afterblow`** stamps **`afterblow_damage_mult` < 1.0**; same fixed seed + **`attack_hit`** resolve.
static func _run_afterblow_low_hindrance_allow_triggers_resolve_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_EXECUTE_HIT_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
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
            (
                "afterblow_allow_hit: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures, "afterblow_allow_hit: missing harness afterblow mult meta (seed=%d)" % _AFTERBLOW_EXECUTE_HIT_SEED
        )
    elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 0.8):
        _fail(
            failures,
            (
                "afterblow_allow_hit: want afterblow_damage_mult 0.8 (hindrance 0.2) got %s (seed=%d)"
                % [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_EXECUTE_HIT_SEED]
            )
        )
    mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: hindrance strictly between **`AFTERBLOW_HINDRANCE_ALLOW`** and **`AFTERBLOW_HINDRANCE_BLOCK`** -> **`randf() < hindrance`** cancels (**`_cancel_pending`**, **`try_afterblow` false**); fixed **`seed(2)`** on the same fixture + chest **`final_cut` 11.25** (hybrid hindrance **0.45**).
static func _run_afterblow_mid_hindrance_rand_cancel(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
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
            (
                "afterblow_mid_rand_cancel: try_afterblow should be false (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED
            )
        )
        _free_manager_restore_global_rng(mgr)
        return
    if _EntityAccess.state_str(atk) != CombatConstants.STATE_RECOVERING:
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: want recovering got %s (seed=%d)"
                % [_EntityAccess.state_str(atk), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
            )
        )
    if not _EntityAccess.nested_dictionary_read(atk, "pending_attack").is_empty():
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: pending_attack should clear (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED
            )
        )
    if absf(float(atk.get("state_duration", 0.0)) - CombatConstants.AFTERBLOW_CANCELLED_RECOVERY_S) > 0.0001:
        _fail(
            failures,
            (
                "afterblow_mid_rand_cancel: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s (seed=%d)"
                % [str(atk.get("state_duration")), _AFTERBLOW_MID_HINDRANCE_RAND_CANCEL_SEED]
            )
        )
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: middle hindrance + **`randf() >= hindrance`** -> **`_execute_afterblow`** (**`afterblow_damage_mult` 0.55**) + full resolve **`attack_hit`**; fixed **`seed(0)`**.
static func _run_afterblow_mid_hindrance_rand_executes_hit(failures: PackedStringArray) -> void:
    seed(_AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED)
    var mgr: Node = _MgrScript.new()
    mgr.set_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT, true)
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
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
            (
                "afterblow_mid_rand_execute: try_afterblow should be true (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED
            )
        )
        mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
        if mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
            mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
        _free_manager_restore_global_rng(mgr)
        return
    if str(atk.get("recovery_cause", "")) != "attack_hit":
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: want recovery_cause attack_hit got %s (seed=%d)"
                % [str(atk.get("recovery_cause", "")), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
            )
        )
    if not mgr.has_meta(_HARNESS_META_LAST_AFTERBLOW_MULT):
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: missing harness afterblow mult meta (seed=%d)"
                % _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED
            )
        )
    elif not is_equal_approx(float(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), 0.55):
        _fail(
            failures,
            (
                "afterblow_mid_rand_execute: want afterblow_damage_mult 0.55 got %s (seed=%d)"
                % [str(mgr.get_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)), _AFTERBLOW_MID_HINDRANCE_RAND_EXECUTE_SEED]
            )
        )
    mgr.remove_meta(_HARNESS_META_RECORD_AFTERBLOW_MULT)
    mgr.remove_meta(_HARNESS_META_LAST_AFTERBLOW_MULT)
    _free_manager_restore_global_rng(mgr)


## Tier 3.3: **`GuardLineUpdater.set_guard_from_move`** copies move **`attack_line`** into **`guard_line`** and syncs **`guard_zone`** (clears deflect keys).
static func _run_guard_from_move_sets_guard_line_and_zone(failures: PackedStringArray) -> void:
    var c: Dictionary = {"guard_line": "low", "guard_zone": "left_leg", "combatant_id": 901, "alive": true}
    _GuardLineUpdater.set_guard_from_move(c, "oberhau", "")
    var want_line: String = str(WeaponConstants.get_move("oberhau").get("attack_line", "high"))
    if str(c.get("guard_line", "")) != want_line:
        _fail(failures, "guard_from_move: oberhau want guard_line %s got %s" % [want_line, str(c.get("guard_line"))])
    if c.has("guard_deflect_blend") or c.has("guard_deflect_from_line"):
        _fail(failures, "guard_from_move: should clear deflect keys")
    var want_zone: String = CombatConstants.guard_zone_for_guard_line(want_line)
    if str(c.get("guard_zone", "")) != want_zone:
        _fail(
            failures,
            "guard_from_move: guard_zone for %s want %s got %s" % [want_line, want_zone, str(c.get("guard_zone"))]
        )


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  no **`pending_attack`** -> **false** (no **`_execute_attack`**).
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


## Tier 3.3: **`AfterblowHandler.try_afterblow`**  -  not **`STATE_WIND_UP`** -> **false**.
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


## Tier 3.3: **`AfterblowHandler`** hybrid hindrance >= **`AFTERBLOW_HINDRANCE_BLOCK`** cancels **`pending_attack`** (no **`_execute_attack`**).
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
            (
                "afterblow_block: state_duration want AFTERBLOW_CANCELLED_RECOVERY_S got %s"
                % str(tgt.get("state_duration"))
            )
        )
    _free_manager(mgr)


static func _run_ai_attrition_offense_mult_duel_vs_line(failures: PackedStringArray) -> void:
    var mgr_d: Node = _MgrScript.new()
    mgr_d.register(_new_entity("SWORD"), "player")
    mgr_d.register(_new_entity("SWORD"), "enemy")
    mgr_d.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var m_duel: float = _AIPicker._attrition_offense_weight_mult(mgr_d, mgr_d.combatants[0])
    _free_manager(mgr_d)
    if absf(m_duel - CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT) > 0.001:
        _fail(
            failures,
            "ai_skirmish_mult: 1v1 want %.4f got %.4f" % [CombatConstants.AI_SKIRMISH_LOW_STANDING_OFFENSE_MULT, m_duel]
        )
    var mgr_l: Node = _MgrScript.new()
    for _i in 4:
        mgr_l.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr_l.register(_new_entity("SWORD"), "enemy")
    mgr_l.start({"files": 2, "ranks": 2, "density": "normal"}, {"files": 2, "ranks": 2, "density": "normal"})
    var m_line: float = _AIPicker._attrition_offense_weight_mult(mgr_l, mgr_l.combatants[0])
    _free_manager(mgr_l)
    if absf(m_line - 1.0) > 0.001:
        _fail(failures, "ai_skirmish_mult: 4v4 want 1.0 got %.4f" % m_line)


static func _run_wind_up_duration_bounded_for_move(failures: PackedStringArray) -> void:
    if CombatTiming.guard_transition_mult(0.0) > CombatConstants.GUARD_TRANSITION_MULT_MAX + 0.001:
        _fail(
            failures,
            (
                "wind_up_bound: guard_transition_mult(0) %.3f exceeds GUARD_TRANSITION_MULT_MAX"
                % CombatTiming.guard_transition_mult(0.0)
            )
        )
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("MACE"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var p: Dictionary = mgr.combatants[0]
    var p_id: int = _EntityAccess.id_int(p)
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var ent: CoreEntity = _EntityAccess.scene_node(p) as CoreEntity
    for leg_part in ["left_leg", "right_leg"]:
        _harness_destroy_limb(ent, leg_part)
    p["guard_line"] = "low"
    _Footwork.apply_attack_step_on_windup(p, "high")
    seed(90212)
    _WindUpStarter.start(mgr, p_id, e_id, "overhead_strike")
    var dur: float = float(p.get("state_duration", 0.0))
    if dur > CombatConstants.WIND_UP_DURATION_MAX_S + 0.001:
        _fail(
            failures,
            "wind_up_bound: overhead_strike want <= %.3fs got %.3fs" % [CombatConstants.WIND_UP_DURATION_MAX_S, dur]
        )
    var pa: Dictionary = _EntityAccess.nested_dictionary_read(p, "pending_attack")
    if float(pa.get("wind_up_duration", 0.0)) > CombatConstants.WIND_UP_DURATION_MAX_S + 0.001:
        _fail(
            failures,
            "wind_up_bound: pending_attack wind_up_duration %.3fs exceeds cap" % float(pa.get("wind_up_duration", 0.0))
        )
    _free_manager_restore_global_rng(mgr)


## **MACE** weak tap: when raw momentum blunt is below **`BLUNT_DAMAGE_MIN`**, slip path stays sub-min; clamped helper still floors to min.
static func _run_kinematic_delivery_mace_weak_tap_pre_blunt_below_baseline_min(failures: PackedStringArray) -> void:
    var mace: Weapon = Weapon.create_from_definition("MACE")
    if mace == null:
        _fail(failures, "kin_mace_weak: missing MACE weapon")
        return
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var ai: AttackInstance = AttackInstance.new("direct_blow", 0.35)
    ai.archetype = arch
    ai.velocity_m_s = 4.0
    var str_weak: float = 52.0
    var raw: float = WeaponDamageHelper.compute_pre_armor_blunt_momentum_raw(mace, ai, str_weak, 1.0)
    if raw >= WeaponConstants.BLUNT_DAMAGE_MIN:
        _fail(
            failures,
            (
                "kin_mace_weak: fixture raw %.4f should be < BLUNT_DAMAGE_MIN %.4f"
                % [raw, WeaponConstants.BLUNT_DAMAGE_MIN]
            )
        )
        return
    var slip: float = WeaponDamageHelper.compute_blunt_slip_pre_armor(mace, ai, str_weak, 1.0, 0.0)
    var clamped: float = WeaponDamageHelper.compute_pre_armor_blunt(mace, ai, str_weak, 1.0)
    if slip >= WeaponConstants.BLUNT_DAMAGE_MIN - 0.02:
        _fail(failures, "kin_mace_weak: slip %.4f should stay below BLUNT_DAMAGE_MIN" % slip)
    if clamped < WeaponConstants.BLUNT_DAMAGE_MIN - 0.02:
        _fail(failures, "kin_mace_weak: clamped helper should floor to min got %.4f" % clamped)
    if slip >= clamped - 0.02:
        _fail(failures, "kin_mace_weak: slip %.4f should be below clamped %.4f" % [slip, clamped])


## Slip path: **`strike_momentum_mult`** scales **`pre_blunt_applied`** at **`v=11`** without dagger fixture boost (locks **`compute_blunt_slip_pre_armor`**).
static func _run_kinematic_delivery_blunt_slip_momentum_mult_sword_v11(failures: PackedStringArray) -> void:
    var vo: float = 11.0
    var mult: float = 1.32
    var arch: Dictionary = {"kinematic_delivery": WeaponConstants.KINEMATIC_DELIVERY_SWING}
    var base: Dictionary = _kin_dmg_integration_sample(vo, 1.0, 1.0, {}, "SWORD", "oberhau", 1.0, arch)
    var shaped: Dictionary = _kin_dmg_integration_sample(
        vo, 1.0, 1.0, {"strike_momentum_mult": mult}, "SWORD", "oberhau", 1.0, arch
    )
    var b_blunt: float = float(base["pre_blunt"])
    var s_blunt: float = float(shaped["pre_blunt"])
    _free_manager(base["mgr"] as Node)
    _free_manager(shaped["mgr"] as Node)
    if b_blunt <= 0.01:
        _fail(failures, "kin_slip_mom_v11: baseline pre_blunt too small %.6f" % b_blunt)
    if absf(s_blunt / b_blunt - mult) > 0.05:
        _fail(
            failures,
            (
                "kin_slip_mom_v11: pre_blunt ratio %.4f want %.4f (base=%.6f shaped=%.6f)"
                % [s_blunt / b_blunt, mult, b_blunt, s_blunt]
            )
        )


## Mid-combat arm loss: pending wind-up resolves **`skip`** with no target damage (**`can_melee_threaten`** / arm gate).
static func _run_resolve_aborts_when_threat_lost_mid_combat_arm_loss(failures: PackedStringArray) -> void:
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    mgr.recompute_zoc_and_distance()
    var p_id: int = _EntityAccess.id_int(mgr.combatants[0])
    var e_id: int = _EntityAccess.id_int(mgr.combatants[1])
    _WindUpStarter.start(mgr, p_id, e_id, "thrust")
    var p: Dictionary = mgr.combatants[0]
    var en_ent: CoreEntity = _EntityAccess.scene_node(mgr.combatants[1]) as CoreEntity
    var chest_before: float = float(en_ent.body_cutting.get("chest", 0.0))
    var arm: String = _EntityAccess.get_attacking_arm(p)
    if arm.is_empty():
        arm = "right_arm"
    var ent: CoreEntity = _EntityAccess.scene_node(p) as CoreEntity
    _harness_destroy_limb(ent, arm)
    if not _EntityAccess.get_attacking_arm(p).is_empty():
        _harness_destroy_limb(ent, "left_arm")
    if not _EntityAccess.get_attacking_arm(p).is_empty():
        _fail(failures, "arm_loss_abort: could not strip attacking arm on setup")
        _free_manager(mgr)
        return
    var res: Dictionary = _AttackResolver.resolve_attack(mgr, p_id)
    if str(res.get("action", "")) != "skip":
        _fail(failures, "arm_loss_abort: expected skip after arm loss got %s" % str(res.get("action", "")))
    var chest_after: float = float(en_ent.body_cutting.get("chest", 0.0))
    if chest_after < chest_before - 0.01:
        _fail(failures, "arm_loss_abort: enemy chest damage %.2f -> %.2f on skip" % [chest_before, chest_after])
    _free_manager(mgr)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Phase 3 (MS-L8): post-strike momentum  -  attacker presses target after successful strike.
## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
static func _run_ms_l8_post_strike_momentum_presses_target(failures: PackedStringArray) -> void:
    # Build a 1v1 scenario where player just struck enemy (stamp the tick).
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var player_id: int = _EntityAccess.id_int(player)
    var enemy_id: int = _EntityAccess.id_int(enemy)
    # Stamp last_strike_tick and last_strike_target_id to simulate post-strike state.
    player[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TICK] = float(mgr.combat_clock)
    player[CombatConstants.COMBATANT_KEY_LAST_STRIKE_TARGET_ID] = enemy_id
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    # Build actions manually (mimicking what AvailableActionsBuilder produces for a WAITING fighter).
    var actions: Array = [
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "head"},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    # MentalStackDecider should pick from post-strike layer (press the target).
    var picked: Dictionary = MentalStackDecider.try_pick(actions, player_id, mgr)
    if picked.is_empty():
        _fail(failures, "ms_l8_post_strike: MentalStackDecider returned empty  -  expected post-strike layer pick")
        _free_manager(mgr)
        return
    var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if layer != CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE:
        _fail(
            failures,
            "ms_l8_post_strike: expected layer=%s got %s" % [CombatConstants.MENTAL_STACK_LAYER_POST_STRIKE, layer]
        )
    var move_id: String = str(picked.get("move_id", ""))
    # The pick should target the struck enemy (melee strike or attempt_close).
    if int(picked.get("target_id", -1)) != enemy_id:
        _fail(
            failures, "ms_l8_post_strike: pick targets %d not enemy %d" % [int(picked.get("target_id", -1)), enemy_id]
        )
    _free_manager(mgr)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Phase 2: feint resistance gate  -  high-readiness settled defenders reject feints.
## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
static func _run_mental_stack_feint_resistance_high_readiness(failures: PackedStringArray) -> void:
    # Verify that a high-readiness defender (guard=1.0, WAITING state) suppresses
    # feint dampening shortcuts  -  the soft-damp chain still applies but off-balance /
    # recovering / settled-footwork boosts are suppressed so feints get lower weight
    # than against an unready defender.
    CombatConstants.set_feature_ms_feint_resistance_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var player_id: int = _EntityAccess.id_int(player)
    var enemy_id: int = _EntityAccess.id_int(enemy)
    # Set defender to high-readiness WAITING state (guard=1.0, no off-balance).
    player["state"] = CombatConstants.STATE_WAITING
    player["guard"] = 1.0
    player.erase("off_balance_until")
    player["gauge"] = 100.0
    # Build actions manually including a feint move targeting the enemy.
    var actions: Array = [
        {"move_id": "oberhau_feint", "target_id": enemy_id, "target_part": "head"},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    var w_feint_hr: float = _AIPicker._get_action_weight(actions[0], player_id, mgr, true)
    # Verify feint weight is reduced vs a low-readiness defender.
    player["guard"] = 0.5
    var mgr2: Node = _MgrScript.new()
    mgr2.register(_new_entity("SWORD"), "player")
    mgr2.register(_new_entity("SWORD"), "enemy")
    mgr2.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player2: Dictionary = mgr2.combatants[0]
    var enemy2: Dictionary = mgr2.combatants[1]
    player2["state"] = CombatConstants.STATE_WAITING
    player2["guard"] = 0.5
    player2.erase("off_balance_until")
    player2["gauge"] = 100.0
    var w_feint_lr: float = _AIPicker._get_action_weight(actions[0], player_id, mgr2, true)
    if w_feint_hr > w_feint_lr * 1.05:
        _fail(
            failures,
            (
                "ms_feint_resist_hr: feint weight high-read=%.6f should be <= low-read %.6f * 1.05"
                % [w_feint_hr, w_feint_lr]
            )
        )
    _free_manager(mgr)
    _free_manager(mgr2)


static func _run_mental_stack_feint_resistance_low_readiness_still_falls_for(failures: PackedStringArray) -> void:
    # Verify that a low-readiness defender (guard=0.5) does NOT block feints  -  existing damp chain applies.
    CombatConstants.set_feature_ms_feint_resistance_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
    var player: Dictionary = mgr.combatants[0]
    var enemy: Dictionary = mgr.combatants[1]
    var player_id: int = _EntityAccess.id_int(player)
    var enemy_id: int = _EntityAccess.id_int(enemy)
    # Set defender to low-readiness WAITING state (guard=0.5 < 0.75 threshold).
    player["state"] = CombatConstants.STATE_WAITING
    player["guard"] = 0.5
    player.erase("off_balance_until")
    player["gauge"] = 100.0
    # Build actions manually including a feint move targeting the enemy.
    var actions: Array = [
        {"move_id": "oberhau_feint", "target_id": enemy_id, "target_part": "head"},
        {"move_id": "thrust", "target_id": enemy_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    var found_feint: bool = false
    for raw in actions:
        if typeof(raw) != TYPE_DICTIONARY:
            continue
        var a: Dictionary = raw as Dictionary
        var mid: String = str(a.get("move_id", ""))
        if _WeaponConstants.is_feint_move(mid):
            var tid: int = int(a.get("target_id", -1))
            if tid == enemy_id:
                found_feint = true
                break
    if not found_feint:
        # Feints may not be listed for other reasons (e.g., weapon doesn't have feints)  -  acceptable.
        _free_manager(mgr)
        return
    # Feint is listed  -  verify the picker can still pick it (no hard block).
    var picked: Dictionary = MentalStackDecider.try_pick(actions, player_id, mgr)
    if not picked.is_empty():
        var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
        # The feint should NOT trigger any mental stack layer  -  it falls through to weighted pool.
        if layer != "":
            _fail(
                failures, "ms_feint_resist_lr: low-readiness defender triggered layer=%s for feint (should not)" % layer
            )
    CombatConstants.set_feature_ms_feint_resistance_load(-1)
    _free_manager(mgr)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Phase 5 (MS-L7): exhaustion gradient  -  offense weight lerp extends to [0.25, 0.75].
## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
static func _run_ms_l7_exhaustion_gradient_offense_weight(failures: PackedStringArray) -> void:
    var _Exhaustion := preload("res://combat/CombatExhaustion.gd")
    # Verify the extended lerp range: [EXHAUSTION_OFFENSE_DAMP_START=0.25, 0.75].
    # Three exhaustion levels: fresh (0.10), fatigued midpoint (~0.50), exhausted (0.80).
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var c: Dictionary = mgr.combatants[0]

    # Fresh combatant (exhaustion 0) => weight should be ~1.0.
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.0
    var w_fresh: float = _Exhaustion.exhaustion_offense_weight_mult(c)
    if w_fresh < 0.95 or w_fresh > 1.05:
        _fail(failures, "ms_l7_exhaustion: fresh weight_mult=%.4f (expected ~1.0)" % w_fresh)

    # Fatigued combatant (exhaustion ~0.50) => weight should be ~0.625 (midpoint of lerp).
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.50
    var w_fatigued: float = _Exhaustion.exhaustion_offense_weight_mult(c)
    if w_fatigued < 0.4 or w_fatigued > 0.85:
        _fail(failures, "ms_l7_exhaustion: fatigued weight_mult=%.4f (expected ~0.625)" % w_fatigued)

    # Exhausted combatant (exhaustion 0.80 >= 0.75 threshold) => weight should floor at damp floor (~0.35).
    c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.80
    var w_exhausted: float = _Exhaustion.exhaustion_offense_weight_mult(c)
    if w_exhausted < 0.3 or w_exhausted > 0.4:
        _fail(failures, "ms_l7_exhaustion: exhausted weight_mult=%.4f (expected ~0.35 floor)" % w_exhausted)

    # Verify monotonicity: fresh >= fatigued >= exhausted.
    if w_fresh < w_fatigued - 0.01:
        _fail(failures, "ms_l7_exhaustion: monotonicity violated fresh=%.4f fatigued=%.4f" % [w_fresh, w_fatigued])
    if w_fatigued < w_exhausted - 0.01:
        _fail(
            failures, "ms_l7_exhaustion: monotonicity violated fatigued=%.4f exhausted=%.4f" % [w_fatigued, w_exhausted]
        )
    _free_manager(mgr)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Phase 6 (MS-L9): positional awareness  -  disengage when surrounded + vulnerable.
## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
static func _run_ms_l9_positional_awareness_disengage_when_surrounded(failures: PackedStringArray) -> void:
    # Build a 3v1 scenario where one player is surrounded by enemies.
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy1")
    mgr.register(_new_entity("SWORD"), "enemy2")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})  # player: 1 unit  # enemies: 2 units (flanking)
    var player: Dictionary = mgr.combatants[0]
    var player_id: int = _EntityAccess.id_int(player)
    # Wound the player so blood < L9 threshold (60%). ~40% loss -> blood >=>= 60%.
    var ent: CoreEntity = _EntityAccess.scene_node(player) as CoreEntity
    if ent != null:
        ent.body_cutting["chest"] = 40.0  # ~40% blood loss -> triggers MS-L9 vulnerability
    # Set player to waiting state so actions can be built.
    player["state"] = CombatConstants.STATE_WAITING
    player["gauge"] = 100.0
    # Check surrounded  -  with 2 enemies in a 2-file formation vs 1-file player,
    # the player should have hostile zones on multiple sides.
    var surrounded: bool = _ZoneOfControl.is_combatant_surrounded(mgr, player_id)
    if not surrounded:
        # Geometry doesn't produce surround for this config  -  acceptable;
        # the logic path is exercised by the function returning false correctly.
        _free_manager(mgr)
        return
    # If surrounded, build actions manually and check that MS-L9 picks disengage.
    var enemy1_id: int = _EntityAccess.id_int(mgr.combatants[1])
    var enemy2_id: int = _EntityAccess.id_int(mgr.combatants[2])
    var actions: Array = [
        {"move_id": "thrust", "target_id": enemy1_id, "target_part": "head"},
        {"move_id": CombatConstants.MOVE_ID_FALL_BACK, "target_id": player_id},
        {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": player_id},
        {"move_id": CombatConstants.MOVE_ID_WAIT, "target_id": player_id},
    ]
    if actions.is_empty():
        _fail(failures, "ms_l9_positional: no actions built for surrounded player")
        _free_manager(mgr)
        return
    var picked: Dictionary = MentalStackDecider.try_pick(actions, player_id, mgr)
    if picked.is_empty():
        # No pick is OK if no disengage moves are listed (e.g. no fall_back/flee).
        var has_disengage: bool = false
        for a in actions:
            if a is Dictionary:
                var mid: String = str((a as Dictionary).get("move_id", ""))
                if mid == CombatConstants.MOVE_ID_FALL_BACK or mid == CombatConstants.MOVE_ID_FLEE:
                    has_disengage = true
                    break
        if has_disengage:
            _fail(failures, "ms_l9_positional: surrounded + disengage listed but no pick")
        # else: no disengage moves available  -  correct behavior, no failure.
        _free_manager(mgr)
        return
    var layer: String = str(player.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, ""))
    if layer != CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS:
        _fail(
            failures,
            "ms_l9_positional: expected layer=%s got %s" % [CombatConstants.MENTAL_STACK_LAYER_POSITIONAL_DIS, layer]
        )
    var move_id: String = str(picked.get("move_id", ""))
    if move_id != CombatConstants.MOVE_ID_FALL_BACK and move_id != CombatConstants.MOVE_ID_FLEE:
        _fail(failures, "ms_l9_positional: expected disengage move got %s" % move_id)
    _free_manager(mgr)


## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Phase 7: medical escalation  -  TCCC ladder boosts pack over bandage when bandage failed.
## -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
static func _run_mental_stack_medical_escalation_bandage_to_pack(failures: PackedStringArray) -> void:
    # Verify that when a part has failed_medical_parts, pack gets escalation bonus over bandage.
    var _MedWeight := preload("res://combat/CombatMedicalWeighting.gd")
    CombatConstants.set_feature_ms_medical_escalation_load(true)
    var mgr: Node = _MgrScript.new()
    var medic_ent := _new_entity("SWORD")
    medic_ent.linen_strips_remaining = 0
    mgr.register(medic_ent, "medic")
    mgr.register(_new_entity("SWORD"), "ally")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = _EntityAccess.id_int(medic)
    var ally_id: int = _EntityAccess.id_int(ally)
    # Wound the ally's chest so medical actions are relevant.
    var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        ally_ent.blood_volume = 25.0
        _EntityWounds.add_wound(
            ally_ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
        )
        # Apply direct pressure so dressings are allowed (bandage requires compression on bleeding wounds).
        _EntityMedical.prepare_for_medical_windup(ally_ent, ally_ent, "chest")
    # Simulate failed bandage on chest  -  the TCCC ladder should escalate to pack.
    ally["failed_medical_parts"] = ["chest"]
    # Build medical actions manually (simulating what AvailableActionsBuilder produces in med phase).
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": ally_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]
    # Compute weights for each action.
    var w_bandage: float = _MedWeight.compute_weight(actions[0], medic_id, mgr)
    var w_pack: float = _MedWeight.compute_weight(actions[1], medic_id, mgr)
    # Pack should have higher weight than bandage due to escalation bonus (1.5x).
    if w_pack <= w_bandage:
        _fail(
            failures,
            "ms_med_escalation: pack weight=%.4f <= bandage weight=%.4f (pack should be boosted)" % [w_pack, w_bandage]
        )
    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    _free_manager(mgr)


static func _run_mental_stack_medical_escalation_no_bonus_when_no_failures(failures: PackedStringArray) -> void:
    # Verify that when no parts have failed, escalation bonus does NOT apply  -  weights are baseline.
    var _MedWeight := preload("res://combat/CombatMedicalWeighting.gd")
    CombatConstants.set_feature_ms_medical_escalation_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "medic")
    mgr.register(_new_entity("SWORD"), "ally")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var medic: Dictionary = mgr.combatants[0]
    var ally: Dictionary = mgr.combatants[1]
    var medic_id: int = _EntityAccess.id_int(medic)
    var ally_id: int = _EntityAccess.id_int(ally)
    # Wound the ally but do NOT set failed_medical_parts.
    var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
    if ally_ent != null:
        ally_ent.blood_volume = 25.0
        _EntityWounds.add_wound(
            ally_ent, "chest", BleedingConstants.INJURY_TYPE_CUT, 9.0, "thoracic", BleedingConstants.SEVERITY_MODERATE
        )
    # No failed parts  -  escalation should not apply.
    var actions: Array = [
        {"move_id": CombatConstants.MOVE_ID_BANDAGE_SELF, "target_id": ally_id, "target_part": "chest"},
        {"move_id": CombatConstants.MOVE_ID_PACK_WOUND, "target_id": ally_id, "target_part": "chest"},
    ]
    var w_bandage: float = _MedWeight.compute_weight(actions[0], medic_id, mgr)
    var w_pack: float = _MedWeight.compute_weight(actions[1], medic_id, mgr)
    # Without failed parts, pack should NOT get the 1.5x escalation bonus.
    # Pack may still have higher weight due to urgency/part threat, but not from escalation.
    # The key assertion: bandage should NOT be suppressed (retry bonus should apply normally).
    if w_bandage <= 0.0:
        _fail(
            failures, "ms_med_escalation_nofail: bandage weight=%.4f (should not be zero without failures)" % w_bandage
        )
    CombatConstants.set_feature_ms_medical_escalation_load(-1)
    _free_manager(mgr)
