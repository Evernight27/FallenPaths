class_name DataKeys
extends RefCounted

## Canonical dictionary string keys used across armor, combat, entity state, and persistence.
## Eliminates bare-string dict key typos that silently return `.get()` defaults.
## Read order: combatant -> entity state -> armor layer -> attack data -> action/choice -> formation/event ->
## persistence.

# --- Combatant dict keys (combatant records on CombatManager) ---
const COMBATANT_NODE: String = "node"
const COMBATANT_STATS: String = "stats"
const COMBATANT_ID: String = "id"
const COMBATANT_ALIVE: String = "alive"
const COMBATANT_STATE: String = "state"
const COMBATANT_SIDE: String = "side"
const COMBATANT_RANK: String = "rank"
const COMBATANT_FILE: String = "file"
const COMBATANT_GAUGE: String = "gauge"
const COMBATANT_STAMINA: String = "stamina"
const COMBATANT_BREATH: String = "breath"

# --- Clash context keys (new additions) ---
const CLASH_MARGIN_RATIO: String = "margin_ratio"

# --- Parry choice outcome keys (new additions) ---
const PA_PARRY_PRIORITY_A: String = "parry_p_a"
const PA_PRIORITY_CD: String = "parry_c_d"
const PA_VIABLE: String = "viable"

# --- Medical sim state keys (new additions) ---
const SIM_STATE_SIM_SECONDS: String = "sim_seconds"
const SIM_STATE_STAGNANT_STEPS: String = "stagnant_steps"
const SIM_STATE_TOTAL_ITERATIONS: String = "total_iterations"

# --- Tactical combat telemetry keys (new additions) ---
const TACTICAL_MODE_KEY: String = "mode"
const TACTICAL_MODE_CODE_KEY: String = "mode_code"

# --- Resolve output keys (new additions) ---
const RESULT_TARGET_PART: String = "target_part"
const RESULT_AIM_REACHABLE: String = "aim_reachable"
const RESULT_HIT_ALIGNMENT: String = "hit_alignment"
const AIM_PROT_TIER: String = "aim_prof_tier"
const PROF_OCC_MULT: String = "occ_mult"

# --- Formation move weight keys (new additions) ---
const ENTRY_WEIGHT: String = "weight"

# --- Parry preview result keys (new additions) ---
const RESULT_PARRY_PREVIEW_ALIGNMENT: String = "parry_preview_alignment"

# --- Zone of control keys (new additions) ---
const ZONE_ID: String = "zone_id"
const ZONE_OCCUPIED_ID: String = "occupied_zone_id"
const FORMATION_ZONE_CONTROL: String = "zone_control"

# --- Zone result keys (new additions) ---
const ZONE_FRONT_COUNT: String = "front_count"
const ZONE_RATIO_SUM: String = "ratio_sum"
const ZONE_AGGRESSIVE: String = "aggressive"
const ZONE_ALL_DEFENSIVE: String = "all_defensive"
const ZONE_CONTROLLING_DISENGAGE_MULT: String = "controlling_disengage_mult"
const COMBATANT_STANCE: String = "stance"
const COMBATANT_FORMATION_ID: String = "formation_id"
const COMBATANT_COMBAT_ABSENT: String = "combat_absent"
const COMBATANT_YIELDED: String = "yielded"
const COMBATANT_RUTHLESSNESS: String = "ruthlessness"
const COMBATANT_DAMAGE_DEALT_BY_ID: String = "damage_dealt_by_id"
const COMBATANT_KEY_MUSCLE_FATIGUE: String = "muscle_fatigue"
const COMBATANT_DISTANCE_TO: String = "distance_to"

# --- Pair geometry dict keys (effective_pair_geometry, stamping) ---
const PAIR_FILE_SPACING_EQUIV: String = "file_spacing_equiv"
const EFFECTIVE_PAIR_FILE_SPACING_EQUIV: String = "effective_pair_file_spacing_equivalent"

# --- Bind pressure / control system keys ---
const BIND_PRESSURE_VALUE: String = "bind_pressure_value"
const BIND_PRESSURE_UNTIL: String = "bind_pressure_until"
const BIND_PARTNER_ID: String = "bind_partner_id"
const BIND_CONTROL_SIDE: String = "bind_control_side"
const BIND_SIDE_LEFT: String = "left"
const BIND_SIDE_RIGHT: String = "right"
const BIND_SIDE_CENTRE: String = "centre"
const BIND_WRESTLING_AVAILABLE: String = "bind_wrestling_available"

# --- Entity state (body stats, wounds, blood) ---
const BLOOD_VOLUME: String = "blood_volume"
const BONE_HEALTH: String = "bone_health"

# --- Armor layer properties (layer dicts in armor data) ---

# --- Attack/parry result dict keys (set by AttackResolver, read by resolver/applier) ---
const ATTACK_INTENSITY: String = "intensity"
const ATTACK_RECOVERY_DURATION: String = "recovery_duration"
const ATTACK_WAS_DEFLECTED: String = "was_deflected"
const ATTACK_PARTIAL_DODGE_PART: String = "partial_dodge_part"
const ATTACK_TARGET_PART: String = "target_part"
const ATTACK_FEINT_PART: String = "feint_part"
const ATTACK_ATTACK_TYPE: String = "attack_type"
const ATTACK_VELOCITY_M_S: String = "velocity_m_s"
const ATTACK_POWER: String = "power"
const ATTACK_FOLLOW_THROUGH: String = "follow_through"
const ATTACK_PARRY_REMAINING_RATIO: String = "parry_remaining_ratio"
const ATTACK_AFTERBLOW_DAMAGE_MULT: String = "afterblow_damage_mult"
const ATTACK_EFFECTIVE_ATTACK_LINE: String = "effective_attack_line"
const ATTACK_LINE_FAIL_MEMORY: String = "line_fail_memory"
const ATTACK_LINE_PARRY_MEMORY: String = "line_parry_memory"
const ATTACK_ATTACK_ANGLE_DEG: String = "attack_angle_deg"
const ATTACK_ARC_START_DEG: String = "arc_start_deg"
const ATTACK_RECOVERY_CAUSE: String = "recovery_cause"
const ATTACK_GUARD_LINE: String = "guard_line"

# --- Action/choice dict keys (action arrays, move choices) ---
const ACTION_MOVE_ID: String = "move_id"
const ACTION_TARGET_ID: String = "target_id"
const ACTION_TARGET_PART: String = "target_part"
const ACTION_FEINT_PART: String = "feint_part"
const ACTION_WEIGHT: String = "weight"
const ARC_OCCUPANCY_WEIGHT_SUM: String = "weight_sum"

# --- Attack path dict keys (pa set by AttackWindUpStarter, read by resolver/defense) ---
const PA_ATTACK_LINE: String = "attack_line"
const PA_ARCHETYPE_ID: String = "archetype_id"
const PA_STATE_DURATION: String = "state_duration"
const PA_STATE_TIMER: String = "state_timer"
const PA_PARRY_CLASH_CONTEXT: String = "parry_clash_context"
const PA_DEFENDER_GUARD_LINE_AT_PARRY: String = "defender_guard_line_at_parry"
const PA_PARRY_BONUS_UNTIL: String = "parry_bonus_until"
const PA_PARRY_BONUS_MULT: String = "parry_bonus_mult"
const PA_LAST_PARRY_CLOCK: String = "last_parry_clock"
const PA_WIND_UP_DURATION: String = "wind_up_duration"
const PA_ZONE_ENGAGEMENT_PARRY_MULT: String = "zone_engagement_parry_mult"
const PA_TACTICAL_AMBUSH_MULT: String = "tactical_ambush_mult"
const PA_LAST_MOVE_ID: String = "last_move_id"
const ATTACK_LAST_MOVE_ID: String = "attack_last_move_id"
const PA_PARRY_AGAINST_ID: String = "parry_against_id"
const PA_PARRY_WAS_BIND: String = "parry_was_bind"
const PA_OFF_BALANCE_UNTIL: String = "off_balance_until"
const PA_OFF_BALANCE_TOTAL: String = "off_balance_total"
## Persistent facing (Tier 3.1): a decaying window during which the defender is still "turned" from a
## flank/rear attack and has not re-braced on their new front. Mirrors the off-balance pair.
const PA_FACING_TURN_UNTIL: String = "facing_turn_until"
const PA_FACING_TURN_TOTAL: String = "facing_turn_total"
const PA_FEINT_OPEN_LINE: String = "feint_open_line"
const PA_FEINT_OPEN_LINE_UNTIL: String = "feint_open_line_until"
const PA_FEINT_OPEN_LINE_PARRY_MULT: String = "feint_open_line_parry_mult"
const PA_FEINT_OPEN_LINE_DURATION_S: String = "feint_open_line_duration_s"
const PA_PENDING_MEDICAL: String = "pending_medical"
const PA_RECEIVING_MEDICAL_COUNT: String = "receiving_medical_count"
const PA_RECEIVING_CARE_COOLDOWN: String = "receiving_care_action_cooldown"
const PA_RECEIVING_CARE_TURN_PENDING: String = "receiving_care_turn_pending"
const PA_ARC_SPAN_DEG: String = "arc_span_deg"
const PA_POSITION_ANGLE_OFFSET_DEG: String = "position_angle_offset_deg"
const PA_DEPTH_POLEARM_ATTACK: String = "depth_polearm_attack"
const PA_DEPTH_POLEARM_ALLOWS_LOW: String = "depth_polearm_allows_low_targets"
const PA_DEPTH_POLEARM_LANE: String = "depth_polearm_lane_type"
const PA_STRIKE_MEASURE_RATIO: String = "strike_measure_ratio"
const PA_EFFECTIVE_PAIR_EFF_DIST: String = "effective_pair_eff_dist"
const PA_MOVE_CONTACT_TYPE: String = "move_contact_type"
const PA_ENGAGEMENT_ANGLE: String = "engagement_angle"
const PA_WEAPON_EXTENSION_COMMIT: String = "weapon_extension_commit_fraction"
const STRIKE_CTX_ZONE_GEOMETRY_ATK_DENSITY: String = "zone_geometry_atk_density"
const PA_PARRY_TWIST_TIME_TO_REACT: String = "parry_twist_time_to_react"
const PA_PARRY_TWIST_READINESS: String = "parry_twist_readiness"
const COMBATANT_SLOT_KEY: String = "slot_key"

# --- Formation dict keys (formation records) ---
const FORMATION_LINE_COHESION: String = "line_cohesion"
const FORMATION_ENGAGEMENT_POSTURE: String = "engagement_posture"
const FORMATION_INCURSION_PRESSURE: String = "incursion_pressure"
const FORMATION_SLOTS: String = "slots"
const FORMATION_LINE_DISCIPLINE: String = "line_discipline"
const FORMATION_LANE_STRESS_BY_FILE: String = "lane_stress_by_file"

# --- Event dispatch dict keys (CombatEventDispatch, CombatFormationFlow) ---
const EVENT_TYPE: String = "type"
const EVENT_COMBATANT_ID: String = "combatant_id"
const EVENT_DATA: String = "data"
const EVENT_PARTNER_ID: String = "partner_id"
const EVENT_MOVE_KIND: String = "move_kind"
const EVENT_RESOLVE_AT: String = "resolve_at"

# --- Defense/parry config dict keys ---

# --- Interpose dict keys ---
const INTERPOSE_ACTIVE: String = "active"
const INTERPOSE_ARM: String = "arm"

# --- Medical/wound sim dict keys ---
const INJURY_SEVERITY: String = "severity"

# --- Attack result dict keys (detailed resolve) ---
const RESULT_DMG: String = "dmg"
const RESULT_WOUND_SEVERITY: String = "wound_severity"
const RESULT_RESULT_DICT: String = "result_dict"
const RESULT_ACTION: String = "action"
const RESULT_DIED: String = "died"
const RESULT_ARM_INTERPOSE_BOOST: String = "arm_interpose_boost"
const RESULT_ARM_INTERPOSE_ARM: String = "arm_interpose_arm"
const RESULT_PARRY_CONTROL: String = "parry_control"
const RESULT_REMAINING_RATIO: String = "remaining_ratio"
const RESULT_HIT_SUB_REGION: String = "hit_sub_region"
const RESULT_HIT_SUB_REGION_SEED: String = "hit_sub_region_seed"
const RESULT_STRIKE_KE_J: String = "strike_ke_j"
const RESULT_TRANSMITTED_KE_FRACTION: String = "transmitted_ke_fraction"

# --- Armor result dict keys (armor apply_damage return) ---

# --- Attack archetype/strike modifier dict keys (sm.get() in AttackResolver) ---
const ATK_MOD_CUT_DAMAGE_MULT: String = "cut_damage_mult"
const ATK_MOD_SHARP_PENETRATION_MULT: String = "sharp_penetration_mult"
const ATK_MOD_RECOVERY_MULTIPLIER: String = "recovery_multiplier"

# --- Attack result dict keys (take_result from resolve) ---
const RESULT_FINAL_CUT: String = "final_cut"
const RESULT_FINAL_BLUNT: String = "final_blunt"
const RESULT_FINAL_BONE: String = "final_bone"
const RESULT_MECHANICAL_POST_ARMOR: String = "mechanical_post_armor"
const RESULT_PART: String = "part"
const RESULT_OUTCOME: String = "outcome"
const RESULT_MOVE_ID: String = "move_id"
const RESULT_POWER: String = "power"
const RESULT_FOLLOW_THROUGH: String = "follow_through"
const RESULT_ATTACK_LINE: String = "attack_line"
const RESULT_WEAPON_ID: String = "weapon_id"
const RESULT_KINEMATIC_DELIVERY: String = "kinematic_delivery"
const PA_WEAPON_FORM: String = "weapon_form"
const COMBATANT_FORM_STR: String = "_form_str"
const RESOLVE_GAUGE_DEF_PRE: String = "gauge_def_pre"

# --- Alignment context dict keys (alignment_context in AttackPathResolver / CombatConstants) ---
const ALIGNMENT_ATTACK_ANGLE_DEG: String = "attack_angle_deg"
const ALIGNMENT_GUARD_ANGLE_DEG: String = "guard_angle_deg"
# Shared line-based guard alignment stamped at resolve; consumed by DefenseChoiceResolver parry resolution.
const PA_GUARD_ALIGNMENT: String = "pa_guard_alignment"
const PA_PARRY_PARTIAL_FOLLOW_THROUGH: String = "pa_parry_partial_follow_through"

# --- Weapon template data keys (def.get() in Weapon.from_dict) ---
const WEAPON_MASS: String = "mass"

# --- UI/snapshot row dict keys (PartyMemberSnapshot, PartyRowFormatter, BattleUIUpdater) ---
const SNAPSHOT_IS_COUNTER_TEMPO_WIND_UP: String = "is_counter_tempo_wind_up"
const SNAPSHOT_PENDING_MEDICAL: String = "pending_medical"
const SNAPSHOT_IS_PARTY_LEADER: String = "is_party_leader"

# --- Formation/dialogue context keys ---
const FRONT_COUNT: String = "front_count"
const FORMATION_DENSITY: String = "density"
const FORMATION_FILES: String = "files"
const FORMATION_RANKS: String = "ranks"

# --- Persistence/save dict keys ---
const SAVE_VERSION: String = "version"

# --- Zone geometry dict keys ---
const ZONE_FID_A: String = "fid_a"
const ZONE_FORMATION_A: String = "formation_a"
const ZONE_FORMATION_B: String = "formation_b"
const ZONE_FORMATION: String = "formation"
const ZONE_FID: String = "fid"

# --- Doctrine/commitment dict keys ---
const DOCTRINE_TARGET_COMMIT_ID: String = "doctrine_target_commit_id"
const DOCTRINE_COMMIT_UNTIL: String = "doctrine_commit_until"

# --- Member snapshot node ref (PartyMemberSnapshot, CampaignEncounterBridge, etc.) ---

# --- Combat layer tissue dict keys ---

# --- Telemetry/mode dict keys ---

# --- Weapon template data keys (def.get() in Weapon.from_dict) ---
const WEAPON_CONTACT_TYPE: String = "contact_type"
const WEAPON_WINDUP_MULTIPLIER: String = "windup_multiplier"
const WEAPON_FEINT_WINDUP_DURATION_MULT: String = "feint_windup_duration_mult"
const WEAPON_FEINT_TARGET_REVEAL_AT_PROGRESS: String = "feint_target_reveal_at_progress"

# --- Entity/core stat dict keys ---
const ENTITY_STRENGTH: String = "strength"
const ENTITY_AGILITY: String = "agility"
const ENTITY_INTELLIGENCE: String = "intelligence"
const ENTITY_ENDURANCE: String = "endurance"
const ENTITY_PERCEPTION: String = "perception"

# --- Member snapshot stat keys ---

# --- Attack resolver strike modifier dict keys (sm.get() in resolve) ---
const ATK_STRIKE_MOMENTUM_MULT: String = "strike_momentum_mult"
const ATK_BLUNT_DAMAGE_MULT: String = "blunt_damage_mult"
const ATK_BLUNT_MOMENTUM_PA_MULT: String = "blunt_momentum_pa_mult"
const ATK_PENETRATION_SHARP: String = "penetration_sharp"
const ATK_PENETRATION_BLUNT_MPA: String = "penetration_blunt_momentum_per_area"
const ATK_BLUNT_CONTACT_CM: String = "blunt_contact_cm"
const ATK_BLUNT_COUPLING_CONTACT_CM: String = "blunt_coupling_contact_cm"

# --- Combat attention dict keys ---
const ATTENTION_LINE_COUNTS: String = "line_counts"
const ATTENTION_MOVE_ID_COUNTS: String = "move_id_counts"
const ATTENTION_CONTACT_TYPE_COUNTS: String = "contact_type_counts"
const ATTENTION_FEINT_RESOLVED: String = "feint_resolved"
const ATTENTION_PARRY_DEFLECT: String = "parry_deflect"

# --- Formation move/vacancy dict keys ---
const FM_FORMATION_MOVE_PARTNER_ID: String = "formation_move_partner_id"
const FM_ROTATE_FILE_REVERSE_LOCK_UNTIL: String = "formation_rotate_file_reverse_lock_until"
const FM_ROTATE_FILE_REVERSE_PARTNER_ID: String = "formation_rotate_file_reverse_partner_id"
const FM_AUTOFILL_COOLDOWN_UNTIL: String = "formation_autofill_cooldown_until"
const FM_AUTOFILL_LAST_MOVE_CLOCK: String = "formation_autofill_last_move_clock"
const FM_VACANCY_LATERAL_REVERSE_LOCK_UNTIL: String = "formation_vacancy_lateral_reverse_lock_until"
const FM_VACANCY_LATERAL_LAST_FROM_FILE: String = "formation_vacancy_lateral_last_from_file"
const FM_VACANCY_LATERAL_LAST_TO_FILE: String = "formation_vacancy_lateral_last_to_file"

# --- Combatant snapshot keys (CombatCombatantsSnapshot) ---
const SNAPSHOT_COMBAT_ABSENT: String = "combat_absent"

# --- Map field care / triage dict keys ---

# --- Attack path resolver dict keys (tap/attack_path) ---
const ARC_OCCUPANCY_BLOCKED: String = "arc_occupancy_blocked"
const SURROUND_THREAT_COUNT: String = "surround_threat_count"
const SURROUND_THREAT_WEIGHT_SUM: String = "surround_threat_weight_sum"

# --- Entity damage extras/force dict keys ---

# --- Medical phase dict keys (windup/action) ---
const MEDICAL_ID: String = "medical_id"
const MEDICAL_TARGET_COMBATANT_ID: String = "target_combatant_id"
const MEDICAL_CONTINUE_LOOP: String = "continue_loop"
const MEDICAL_BREAK_REASON: String = "break_reason"

# --- Weapon damage helper dict keys ---
const WD_KINEMATIC_DELIVERY: String = "kinematic_delivery"
const WD_ARCHETYPE: String = "archetype"

# --- Strike realism profile dict keys ---

# --- Parry config dict keys (PassiveParryContext) ---
const PARRY_STRONG_CONTACT_BY_ARCH: String = "strong_contact_by_arch"

# --- Attack path / wind-up dict keys (pa/atd dicts in AttackWindUpStarter, AttackResolver) ---
const PA_PENDING_ATTACK: String = "pending_attack"
const PA_GUARD_AFTER_ATTACK: String = "guard"
const DEFENDER_GUARD_ZONE: String = "guard_zone"
const PA_ARC_INTENDED_DEG: String = "arc_intended_deg"
const PA_IMPACT_BLADE_STATION: String = "impact_blade_station"
const PA_FEINT_WINDUP_DURATION_MULT: String = "feint_windup_duration_mult"
const PA_FEINT_TARGET_REVEAL_AT_PROGRESS: String = "feint_target_reveal_at_progress"
const PA_GAUGE_ATK_PRE: String = "gauge_atk_pre"
const PA_GAUGE_DEF_PRE: String = "gauge_def_pre"
const PA_TUNING_FT_PARENT_STRIKE: String = "tuning_ft_parent_strike"
const PA_DEFENDER_FORM_AT_PARRY: String = "defender_form_at_parry"
const PA_OVERCOMMIT_PARRY_MULT: String = "overcommit_parry_mult"
const PA_GUARD_DEFLECT_BLEND: String = "guard_deflect_blend"
const PA_GUARD_DEFLECT_FROM_LINE: String = "guard_deflect_from_line"
const PA_PENDING_RETRY: String = "pending_retry"
const PA_VELOCITY_M_S: String = "velocity_m_s"
const PA_PARTIAL_DODGE_PART: String = "partial_dodge_part"
const PA_PASSIVE_PARRY_ATTEMPTED: String = "passive_parry_attempted"

# --- Combatant dict keys (combatant.get()/set()) ---
const BIND_ACTION_COOLDOWN_UNTIL: String = "bind_action_cooldown_until"
const ACTION_COOLDOWN_UNTIL: String = "action_cooldown_until"

# --- Attention/awareness entry dict keys (CombatAttention) ---
const ATTENTION_PRIORITY_RANK: String = "priority_rank"
const ATTENTION_WEIGHT: String = "attention_weight"
const ATTENTION_RECENT_WINDOW_AGE: String = "recent_window_age"
const ATTENTION_LAST_TICK: String = "last_tick"
const ATTENTION_RECENT_LINE_COUNTS: String = "recent_line_counts"
const ATTENTION_RECENT_MOVE_ID_COUNTS: String = "recent_move_id_counts"
const ATTENTION_LINE_OBS_TICKS: String = "line_obs_ticks"
const ATTENTION_MOVE_OBS_TICKS: String = "move_obs_ticks"

# --- Deception/Yomi entry dict keys (CombatAttention) ---
const DECEPTION_PHASE: String = "phase"
const DECEPTION_RESISTANCE: String = "resistance"
const DECEPTION_EXPLOIT_COUNTER: String = "exploit_counter"
const DECEPTION_ESTABLISH_SUCCESS_COUNT: String = "establish_success_count"
const DECEPTION_ESTABLISHED: String = "established"

# --- Entity node property keys (entity.get() on CoreEntity/Node) ---

# --- Injury dict keys (injury dicts in entity.wounds) ---

# --- Entity damage result dict keys (EntityDamage.take_result) ---
const RESULT_PENETRATION_TO_TISSUE_MM: String = "penetration_to_tissue_mm"

# --- Attack resolver strike result dict keys (detailed harness telemetry) ---
const RESULT_STRIKE_KE_J_APPLIED: String = "strike_ke_j_applied"
const RESULT_BLUNT_CONTACT_CM_APPLIED: String = "blunt_contact_cm_applied"
const RESULT_PRE_CUT_APPLIED: String = "pre_cut_applied"
const RESULT_PRE_BLUNT_APPLIED: String = "pre_blunt_applied"
const RESULT_PENETRATION_SHARP_APPLIED: String = "penetration_sharp_applied"
const RESULT_PENETRATION_BLUNT_MPA_APPLIED: String = "penetration_blunt_mpa_applied"
const RESULT_DAMAGE_RESOLVE_NOTE: String = "damage_resolve_note"
const RESULT_HEALTH_BEFORE: String = "health_before"
const RESULT_HEALTH_AFTER: String = "health_after"

# --- Combat combatants snapshot dict keys (CombatCombatantsSnapshot) ---
const SNAPSHOT_GUARD_ANGLE_DEG: String = "guard_angle_deg"
const SNAPSHOT_COUNTER_TEMPO_WIND_UP: String = "is_counter_tempo_wind_up"
const SNAPSHOT_STATUS_OVERRIDE: String = "status_override"

# --- Battle UI control dict keys (ctrl dicts in BattleUIUpdater) ---

# --- Company state internal dict keys ---

# --- Member snapshot / roster dict keys ---

# --- World/meta property keys (WorldNode.get()) ---

# --- Part weight resolver keys (AttackPathResolver) ---

# --- Blunt penetration options keys ---
const BLUNT_OPT_PEN_SHARP_MM: String = "pen_sharp_mm"
const BLUNT_OPT_TARGET_EFFECTIVE_MASS_KG: String = "target_effective_mass_kg"
const BLUNT_OPT_ARMOR_RESISTANCE_RHA_MM: String = "armor_resistance_rha_mm"

# --- Strike physics context keys ---
const STRIKE_CTX_HIT_SUB_REGION: String = "hit_sub_region"
const STRIKE_CTX_HIT_SUB_REGION_SEED: String = "hit_sub_region_seed"

# --- Variable context keys (AttackResolver var_ctx) ---
const VAR_CTX_STAMINA_RATIO: String = "stamina_ratio"
const VAR_CTX_OFF_BALANCE: String = "off_balance"
const VAR_CTX_WEAPON_MASS_KG: String = "weapon_mass_kg"

# --- Attack archetype dict sub-keys (archetype.get()) ---
const ARCHETYPE_WEAPON_EXTENSION_COMMIT_FRACTION: String = "weapon_extension_commit_fraction"

# --- Entity stat dict keys (combatant stats_dict) ---
const ENTITY_MELEE_SKILL: String = "melee_skill"

# --- Movement policy dict keys (CombatEngagementMode.movement_policy → CombatResolveAction/CombatFormationMoveListing)
# ---
const MOVE_POLICY_ALLOW_SWAP_RANK: String = "allow_swap_rank"
const MOVE_POLICY_ALLOW_DRAG_BACK: String = "allow_drag_back"
const MOVE_POLICY_ALLOW_FALL_BACK: String = "allow_fall_back"

# --- UI/result display keys (CombatLogFormatter, BattleScene) ---
const RESULT_TOTAL_PHYSICAL: String = "total_physical"
const SOAK_TRACE_PASS: String = "pass"
const SCAN_COUNT: String = "count"

# --- Attack path angle keys (pending_attack pa dict) ---
const PA_ARC_END_DEG: String = "arc_end_deg"

# --- Formation dict keys (new additions) ---
const FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL: String = "formation_plug_forward_cooldown_until"
# (FM_VACANCY_LATERAL_LAST_FROM_FILE declared at line 446, FM_VACANCY_LATERAL_LAST_TO_FILE at 447,
# FM_VACANCY_LATERAL_REVERSE_LOCK_UNTIL at 445)
const FM_GAP_COLUMN_FILES: String = "gap_column_files"

# --- Parry/attack keys (new additions) ---
const PA_PARRY_TELEGRAPH: String = "parry_telegraph"
const PA_PARRY_ALL_INCOMING_BATCH: String = "parry_all_incoming_batch"
const PA_PARRY_COMMITMENT_ATTACKER_ID: String = "parry_commitment_attacker_id"
const PA_PARRY_TELEGRAPH_APPARENT: String = "parry_telegraph_apparent"

# --- Medical wind-up config keys ---
const MEDICAL_OUTCOME: String = "outcome"

# --- Bind/afterblow/formation keys (new additions) ---
const PA_AFTERBLOW_DAMAGE_MULT: String = "afterblow_damage_mult"
const BIND_LANE_OFFSET: String = "lane_offset"
const BIND_ANGULAR_ADVANTAGE_UNTIL: String = "angular_advantage_until"
const BIND_ANGULAR_ADVANTAGE_TARGET_ID: String = "angular_advantage_target_id"

# --- Formation engine keys (new additions) ---
const FM_ROTATE_FILE_COOLDOWN_UNTIL: String = "formation_rotate_file_cooldown_until"
# (FM_ROTATE_FILE_REVERSE_LOCK_UNTIL declared at line 441, FM_ROTATE_FILE_REVERSE_PARTNER_ID at 442)
const FM_PAIR_ABORT_COOLDOWN_UNTIL: String = "formation_pair_abort_cooldown_until"
const FM_SLOT_OBSTACLES: String = "slot_obstacles"

# --- Combat depth/polearm keys (new additions) ---
const PA_DEPTH_POLEARM_LANE_TYPE: String = "depth_polearm_lane_type"
const PA_ZONE_GEOMETRY_ATK_DENSITY: String = "zone_geometry_atk_density"

# --- Combat doctrine keys (new additions) ---
const CLOSE_BLOCK_UNTIL_BY_TARGET_ID: String = "close_block_until_by_target_id"

# --- Event/resolve keys (new additions) ---
# (EVENT_RESOLVE_AT declared at line 185)

# --- Zone of control / duration keys (new additions) ---
const ZONE_FID_DURATION: String = "zone_fid"
const COWERING_EARLY_EXIT: String = "cowering_early_exit"

# --- Formation move duration keys (new additions) ---
const DURATION_LANE_FOOT: String = "lane_foot"
const DURATION_PRESSURE_MOD: String = "pressure_mod"
const DURATION_CONTROLLING_FRONT: String = "controlling_front"
const DURATION_ARMOR_MULT: String = "armor_mult"
const DURATION_VALUE_S: String = "duration_s"

# --- Formation move hint keys (new additions) ---
const FORMATION_MOVE_DURATION_HINT: String = "formation_move_duration_hint"

# --- Close contest / resolve keys (new additions) ---
const CLOSE_CONTEST_NOTE: String = "close_contest_note"

# --- UI hint keys (new additions) ---
const POSITION_ANGLE_UI_HINT: String = "position_angle_ui_hint"
const ATTENTION_UI_HINT: String = "attention_ui_hint"
const COUNTER_TEMPO_UI_HINT: String = "counter_tempo_ui_hint"

# --- Morale cohesion keys (new additions) ---
const FORMATION_MORALE_COHESION_FACTOR: String = "morale_cohesion_factor"

# --- Engagement role keys (new additions) ---
const ENGAGEMENT_ROLE: String = "engagement_role"

# --- Campaign/attack path config keys (new additions) ---
const CAMPAIGN_STAMINA_MULT: String = "campaign_stamina_mult"
const MOVE_DEF_ANGLE_OFFSET_DEG: String = "angle_offset_deg"
const MOVE_DEF_ANGLE_VARIANCE_DEG: String = "angle_variance_deg"
const MOVE_DEF_ID: String = "id"
const MOVE_DEF_PREFERRED_PARTS: String = "preferred_parts"
const WOBBLE_CONTEXT_PARRY_READINESS: String = "parry_readiness"
const WOBBLE_CONTEXT_DEFENDER_MASS_KG: String = "defender_mass_kg"

# --- Engagement snapshot keys (new additions) ---
const SNAPSHOT_PLAYER_FRONT_FILL: String = "player_front_fill"
const SNAPSHOT_ENEMY_FRONT_FILL: String = "enemy_front_fill"

# --- Formation discipline keys (new additions) ---
const FORMATION_DISCIPLINE_POSTURE_ENTER_DELTA: String = "discipline_posture_enter_delta"
const FORMATION_DISCIPLINE_POSTURE_LEAVE_DELTA: String = "discipline_posture_leave_delta"

# --- Formation flee context keys (new additions) ---
const FLEE_CTX_CASUALTY_RATIO: String = "casualty_ratio"
const FLEE_CTX_FORMATION_STRESSED: String = "formation_stressed"
const FLEE_CTX_SIDE_HOLDING_FIELD: String = "side_holding_field"

# --- Telemetry keys (new additions) ---
const TEL_ENGAGEMENT_MODE_TRANSITIONS: String = "engagement_mode_transitions"
const TEL_LAST_MODE_TRANSITION: String = "last_mode_transition"

# --- Attack result payload keys (new additions) ---

# --- Attention entry keys (new additions) ---
const ATTENTION_ENTRY_LINE_COUNTS: String = "line_counts"
const ATTENTION_ENTRY_MOVE_ID_COUNTS: String = "move_id_counts"
const ATTENTION_ENTRY_FEINT_RESOLVED: String = "feint_resolved"
const ATTENTION_ENTRY_ATTENTION_WEIGHT: String = "attention_weight"
const ATTENTION_ENTRY_WEIGHTED_LINE_COUNTS: String = "weighted_line_counts"
const ATTENTION_WEIGHTED_LINE_COUNTS: String = "weighted_line_counts"
const ATTENTION_ENTRY_WEIGHTED_MOVE_ID_COUNTS: String = "weighted_move_id_counts"
const ATTENTION_WEIGHTED_MOVE_ID_COUNTS: String = "weighted_move_id_counts"
const ATTENTION_ENTRY_CONTACT_TYPE_COUNTS: String = "contact_type_counts"
const ATTENTION_ENTRY_RECENT_LINE_COUNTS: String = "recent_line_counts"
const ATTENTION_ENTRY_RECENT_MOVE_ID_COUNTS: String = "recent_move_id_counts"

# --- Engagement snapshot keys (active/front counts, not fill) ---
const SNAPSHOT_PLAYER_ACTIVE: String = "player_active"
const SNAPSHOT_ENEMY_ACTIVE: String = "enemy_active"
const SNAPSHOT_PLAYER_FRONT: String = "player_front"
const SNAPSHOT_ENEMY_FRONT: String = "enemy_front"
const SNAPSHOT_RAW_MODE: String = "raw_mode"
const SNAPSHOT_RAW_MODE_CODE: String = "raw_mode_code"

# --- Sim cap key (used in fast-forward drive) ---
const SIM_CAP: String = "sim_cap"

# --- Telemetry resolved mode key ---
const TEL_LAST_RESOLVED_MODE: String = "last_resolved_mode"

# --- Tactical combat formation keys ---
# (FORMATION_INCURSION_PRESSURE declared at line 176, FORMATION_LANE_STRESS_BY_FILE at 177)

# --- Combatant identity/flag keys ---
const COMBATANT_IS_PARTY_LEADER: String = "is_party_leader"
const COMBATANT_IS_ENEMY_LEADER: String = "is_enemy_leader"
const COMBATANT_TACTICAL_PENETRATION_DEPTH: String = "tactical_penetration_depth"
const COMBATANT_PENDING_RETRY: String = "pending_retry"
const COMBATANT_FAILED_MEDICAL_PARTS: String = "failed_medical_parts"

# --- Action dict keys ---
const ACTION_PART: String = "part"

# --- Clash context keys (GuardLineUpdater) ---
const CLASH_DEFENDER_GUARD_LINE: String = "defender_guard_line"
const CLASH_GUARD_ANGLE_DEG: String = "guard_angle_deg"
const CLASH_ALIGNMENT: String = "alignment"

# --- Parry config / defense choice keys ---
const PARRY_CHOICE_CAN_PARRY_IN_TIME: String = "can_parry_in_time"

# --- Combatant state keys ---
const COMBATANT_BANNER_CARRIER: String = "banner_carrier"

# --- Morale cohesion keys ---
const MORALE_COHESION_FACTOR_RAW: String = "morale_cohesion"

# --- Rank pair context keys (swap/plug-forward) ---
const RANK_PAIR_WE_PLUG_FORWARD: String = "we_plug_forward"
const RANK_PAIR_LINE_PLUG_RELIEF: String = "line_plug_relief"
const RANK_PAIR_ELIGIBLE: String = "eligible"
const RANK_PAIR_ALLOW_SWAP: String = "allow_swap"
const RANK_PAIR_WE_ARE_FRONT: String = "we_are_front"

# --- Surround arc threat entry keys ---
const THREAT_ARC_CENTER_DEG: String = "arc_center_deg"

# --- Parry choice / defense config keys ---
const PA_PARRY_CHOICE_BLOCKED: String = "parry_choice_blocked"
const PCFG_REDIRECT_ATTEMPT_RATIO: String = "redirect_attempt_ratio"
const PCFG_REDIRECT_ATTEMPT_AGILITY_SCALE: String = "redirect_attempt_agility_scale"
const PCFG_REDIRECT_BONUS: String = "redirect_bonus"
const PCFG_REDIRECT_SKILL_SCALE: String = "redirect_skill_scale"
const PCFG_REDIRECT_THRUST_BONUS: String = "redirect_thrust_bonus"
const PCFG_REDIRECT_BLUNT_PENALTY: String = "redirect_blunt_penalty"
const PCFG_MASS_DISPARITY_BONUS: String = "mass_disparity_bonus"

# --- GuardLineUpdater clash context keys ---
const RESULT_CLASH_SEVERITY: String = "severity"
const RESULT_ATTACK_TYPE: String = "attack_type"
const ATTACK_ANGLE_DEG: String = "attack_angle_deg"
const COMBATANT_GUARD_ZONE: String = "guard_zone"
const COMBATANT_GUARD: String = "guard"

# --- Attack result / aim override keys ---
const AIM_PART_OVERRIDE: String = "_AIM_PART_OVERRIDE"

# --- Close-quarters engagement escalation keys (CQEE) ---
const CLOSE_QUARTERS_EXCHANGES: String = "close_quarters_exchanges"
const CLOSE_QUARTERS_GRAPPLE_COOLDOWN: String = "close_quarters_grapple_cooldown"
