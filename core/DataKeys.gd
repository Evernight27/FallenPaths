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
const BIND_SUSTAINED_UNTIL: String = "bind_sustained_until"

# --- Entity state (body stats, wounds, blood) ---
const BLOOD_VOLUME: String = "blood_volume"
const BONE_HEALTH: String = "bone_health"
const BONE_MAX: String = "bone_max"
const BODY_CUTTING: String = "body_cutting"
const BODY_BLUNT: String = "body_blunt"
const BODY_MAX: String = "body_max"
const WOUNDS: String = "wounds"
const BANDAGED_PARTS: String = "bandaged_parts"
const PACKED_PARTS: String = "packed_parts"
const TOURNIQUET_APPLIED: String = "tourniquet_applied"

# --- Armor layer properties (layer dicts in armor data) ---
const LAYER_DURABILITY: String = "durability"
const LAYER_MAX_DURABILITY: String = "max_durability"
const LAYER_SHARP_RESISTANCE_RHA_MM: String = "sharp_resistance_rha_mm"
const LAYER_BLUNT_CUSHION: String = "blunt_cushion"
const LAYER_RIGIDITY: String = "rigidity"
const LAYER_SHARP_DEFLECT_TRANSMISSION: String = "sharp_deflect_transmission"
const LAYER_DEFLECTION_TRANSMISSION: String = "deflection_transmission"
const LAYER_BLUNT_TRANSMISSION: String = "blunt_transmission"
const LAYER_BLUNT_BAT_TRANSMISSION: String = "blunt_bat_transmission"
const LAYER_DURABILITY_LOSS_RATE: String = "durability_loss_rate"
const LAYER_MASS_KG: String = "mass_kg"

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
const ATTACK_ATTACK_ANGLE_DEG: String = "attack_angle_deg"
const ATTACK_ARC_START_DEG: String = "arc_start_deg"
const ATTACK_PASSIVE_PARRY_ATTEMPTED: String = "passive_parry_attempted"
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
const PA_GUARD: String = "guard"
const PA_STATE_DURATION: String = "state_duration"
const PA_STATE_TIMER: String = "state_timer"
const PA_PARRY_CLASH_CONTEXT: String = "parry_clash_context"
const PA_DEFENDER_GUARD_LINE_AT_PARRY: String = "defender_guard_line_at_parry"
const PA_PARRY_BONUS_UNTIL: String = "parry_bonus_until"
const PA_WIND_UP_DURATION: String = "wind_up_duration"
const PA_ZONE_ENGAGEMENT_PARRY_MULT: String = "zone_engagement_parry_mult"
const PA_TACTICAL_AMBUSH_MULT: String = "tactical_ambush_mult"
const PA_LAST_MOVE_ID: String = "last_move_id"
const ATTACK_LAST_MOVE_ID: String = "attack_last_move_id"
const PA_PARRY_AGAINST_ID: String = "parry_against_id"
const PA_PARRY_WAS_BIND: String = "parry_was_bind"
const PA_OFF_BALANCE_UNTIL: String = "off_balance_until"
const KINEMATICS_STRIKE_VELOCITY_M_S: String = "strike_velocity_m_s"
const KINEMATICS_STRIKE_KINETIC_ENERGY_J: String = "strike_kinetic_energy_j"
const STRIKE_CTX_ANCHOR_J: String = "j_anchor"
const PA_STAMINA_MAX: String = "stamina_max"
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
const DEFENSE_BLOCK_MASS_THRESHOLD: String = "block_mass_threshold"
const DEFENSE_BLOCK_STR_THRESHOLD: String = "block_str_threshold"
const DEFENSE_GLANCING_EXPONENT: String = "glancing_exponent"
const DEFENSE_LATE_PARRY: String = "late_parry"
const DEFENSE_PARRY_OFF_BALANCE: String = "parry_off_balance"

# --- Interpose dict keys ---
const INTERPOSE_ACTIVE: String = "active"
const INTERPOSE_ARM: String = "arm"
const INTERPOSE_ALIGN_BOOST: String = "align_boost"

# --- Medical/wound sim dict keys ---
const INJURY_SEVERITY: String = "severity"
const INJURY_IS_ARTERIAL: String = "is_arterial"
const INJURY_CURRENT_BLEEDING_RATE: String = "current_bleeding_rate"
const INJURY_BASE_BLEEDING_RATE: String = "base_bleeding_rate"
const INJURY_HEALING_DURATION_SECONDS: String = "healing_duration_seconds"
const INJURY_SUB_REGION: String = "sub_region"
const INJURY_IS_STUMP: String = "is_stump"
const INJURY_INJURY_TYPE: String = "injury_type"
const INJURY_CREATED_AT_GAME_TIME: String = "created_at_game_time"
const INJURY_STABILIZED_REMAINING_SECONDS: String = "stabilized_remaining_seconds"
const INJURY_IS_STABILIZED: String = "is_stabilized"

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
const RESULT_GEOMETRIC_LEAK: String = "geometric_leak"
const RESULT_HIT_SUB_REGION: String = "hit_sub_region"
const RESULT_HIT_SUB_REGION_SEED: String = "hit_sub_region_seed"
const RESULT_STRIKE_KE_J: String = "strike_ke_j"
const RESULT_TRANSMITTED_KE_FRACTION: String = "transmitted_ke_fraction"
const RESULT_ARMOR_KE_ABSORBED_J: String = "armor_ke_absorbed_j"
const RESULT_ARMOR_KE_REMAINING_J: String = "armor_ke_remaining_j"
const RESULT_LAYER_ABSORBED_MM: String = "layer_absorbed_mm"
const RESULT_PENETRATION_TO_BONE_MM: String = "penetration_to_bone_mm"
const RESULT_TO_CUT: String = "to_cut"
const RESULT_TO_BLUNT: String = "to_blunt"
const RESULT_TO_BONE: String = "to_bone"
const RESULT_TO_TISSUE_TOTAL: String = "to_tissue_total"
const RESULT_MECHANISM: String = "mechanism"
const RESULT_DAMAGE_TYPE: String = "damage_type"

# --- Armor result dict keys (armor apply_damage return) ---
const ARMOR_RESULT_DAMAGE: String = "damage"
const ARMOR_RESULT_DAMAGE_TYPE: String = "damage_type"
const ARMOR_RESULT_DEFLECTED: String = "deflected"
const ARMOR_RESULT_TRANSMITTED_BLUNT: String = "transmitted_blunt_amount"
const ARMOR_RESULT_DEFLECTED_BLUNT: String = "deflected_blunt_amount"

# --- Attack archetype/strike modifier dict keys (sm.get() in AttackResolver) ---
const ATK_MOD_STRIKE_ENERGY_MULT: String = "strike_energy_mult"
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
# Shared line-based guard alignment stamped at resolve; consumed by both guard_hit_mult (miss roll)
# and DefenseChoiceResolver parry so they never diverge.
const PA_GUARD_ALIGNMENT: String = "pa_guard_alignment"

# --- Weapon template data keys (def.get() in Weapon.from_dict) ---
const WEAPON_NAME: String = "name"
const WEAPON_BODY_PART: String = "body_part"
const WEAPON_LAYERS: String = "layers"
const WEAPON_MELEE_RANGE: String = "melee_range"
const WEAPON_MASS: String = "mass"
const WEAPON_BLADE_WIDTH: String = "blade_width"
const WEAPON_POINT_WIDTH: String = "point_width"

# --- UI/snapshot row dict keys (PartyMemberSnapshot, PartyRowFormatter, BattleUIUpdater) ---
const SNAPSHOT_NAME: String = "name"
const SNAPSHOT_TOTAL_BLEEDING_RATE: String = "total_bleeding_rate"
const SNAPSHOT_EFFECTIVE_CONSCIOUSNESS: String = "effective_consciousness"
const SNAPSHOT_PERFORMANCE_MODIFIER: String = "performance_modifier"
const SNAPSHOT_IS_UNCONSCIOUS: String = "is_unconscious"
const SNAPSHOT_HAS_UNTREATED_WOUNDS: String = "has_untreated_wounds"
const SNAPSHOT_IS_COUNTER_TEMPO_WIND_UP: String = "is_counter_tempo_wind_up"
const SNAPSHOT_PENDING_MEDICAL: String = "pending_medical"
const SNAPSHOT_UNTREATED_PARTS: String = "untreated_parts"
const SNAPSHOT_AFFLICTION_LABELS: String = "affliction_labels"
const SNAPSHOT_AFFLICTION_EFFECTS: String = "affliction_effects"
const SNAPSHOT_WOUNDED_PART_COUNT: String = "wounded_part_count"
const SNAPSHOT_CAN_FLEE_OR_FALL_BACK: String = "can_flee_or_fall_back"
const SNAPSHOT_IS_PARTY_LEADER: String = "is_party_leader"
const SNAPSHOT_IS_ENEMY_LEADER: String = "is_enemy_leader"

# --- Formation/dialogue context keys ---
const FRONT_COUNT: String = "front_count"
const FORMATION_DENSITY: String = "density"
const FORMATION_FILES: String = "files"
const FORMATION_RANKS: String = "ranks"
const DIALOGUE_STATE_DONE: String = "done"
const DIALOGUE_OK: String = "ok"
const DIALOGUE_MESSAGE: String = "message"

# --- Contract/encounter keys ---
const CONTRACT_TYPE: String = "contract_type"
const CONTRACT_PAY_GOLD: String = "pay_gold"
const CONTRACT_DIFFICULTY_RATING: String = "difficulty_rating"
const CONTRACT_MAP_BLEED_MULT: String = "map_bleed_mult"
const CONTRACT_ENEMY_COUNT: String = "enemy_count"
const CONTRACT_TUTORIAL: String = "tutorial"

# --- Company state keys (CompanyState internal dicts) ---
const COMPANY_MOOD: String = "company_mood"
const STANCE_PREFERENCE: String = "stance_preference"
const STATE_GOLD: String = "gold"
const STATE_MEDICAL_SUPPLIES: String = "medical_supplies"
const STATE_TOOL_SUPPLIES: String = "tool_supplies"
const STATE_FOOD_SUPPLIES: String = "food_supplies"
const STATE_DAY_INDEX: String = "day_index"

# --- Persistence/save dict keys ---
const SAVE_VERSION: String = "version"
const SAVE_COMPANY_STATE: String = "company_state"
const SAVE_ROSTER: String = "roster"
const SAVE_CONSUMED_CONTRACT_TILES: String = "consumed_contract_tiles"
const SAVE_CAMP_HEAL_HINT_SHOWN: String = "camp_heal_hint_shown"
const SAVE_PARTY_FORMATION: String = "party_formation"
const SAVE_REMAINING_ENCOUNTERS: String = "remaining_encounters"
const SAVE_PLAYER_TILE: String = "player_tile"
const SAVE_ENTITY: String = "entity"
const SAVE_WEAPON_ID: String = "weapon_id"
const SAVE_ARMOR_BY_PART: String = "armor_by_part"
const SAVE_CAMPAIGN_AFFLICTIONS: String = "campaign_afflictions"
const SAVE_PROFICIENCY_BONUS: String = "proficiency_bonus"
const SAVE_TRAINING_PENDING: String = "training_pending"
const SAVE_LAST_FIGHTED_DAY: String = "last_fought_day"
const SAVE_LAST_FIGHTED_IN_COMBAT: String = "last_fought_in_combat"
const SAVE_TILE: String = "tile"
const SAVE_ENCOUNTER_CONFIG: String = "encounter_config"
const SAVE_MARKER_KIND: String = "marker_kind"
const SAVE_CONTRACT_MARKER_LABEL: String = "contract_marker_label"

# --- Contract/encounter dict keys ---
const CONTRACT_TITLE: String = "contract_title"
const CONTRACT_ENEMY_MOOD_BIAS: String = "enemy_mood_bias"
const CONTRACT_ENEMY_SPECIES_POOL: String = "enemy_species_pool"
const CONTRACT_SOAK_PRESET_ID: String = "soak_preset_id"
const CONTRACT_AMBUSH_TYPE: String = "ambush_type"
const CONTRACT_AMBUSH_PENALTY: String = "ambush_penalty"

# --- Battle end/death dict keys ---
const DEATH_CAUSE: String = "cause"
const DEATH_WEAPON: String = "weapon"
const DEATH_KILLER: String = "killer"

# --- Zone geometry dict keys ---
const ZONE_FID_A: String = "fid_a"
const ZONE_FID_B: String = "fid_b"
const ZONE_FORMATION_A: String = "formation_a"
const ZONE_FORMATION_B: String = "formation_b"
const ZONE_FORMATION: String = "formation"
const ZONE_FID: String = "fid"
const ZONE_GEOMETRY_FID: String = "zone_geometry_fid"

# --- Doctrine/commitment dict keys ---
const DOCTRINE_TARGET_COMMIT_ID: String = "doctrine_target_commit_id"
const DOCTRINE_COMMIT_UNTIL: String = "doctrine_commit_until"

# --- Member snapshot node ref (PartyMemberSnapshot, CampaignEncounterBridge, etc.) ---
const MEMBER_NODE_REF: String = "node_ref"

# --- Combat layer tissue dict keys ---
const LAYER_TISSUE_BUDGET_MM: String = "budget_mm"
const LAYER_TISSUE_YIELD_PEN_MM: String = "yield_pen_mm"
const LAYER_TISSUE_RUPTURE_PEN_MM: String = "rupture_pen_mm"
const LAYER_TISSUE_STATE: String = "state"
const LAYER_TISSUE_ACCUMULATED_PEN_MM: String = "accumulated_pen_mm"

# --- Telemetry/mode dict keys ---
const TELEMETRY_MODE: String = "mode"
const TELEMETRY_MODE_CODE: String = "mode_code"
const TELEMETRY_DATA: String = "telemetry"

# --- Weapon template data keys (def.get() in Weapon.from_dict) ---
const WEAPON_PARRY_SPEED_FACTOR: String = "parry_speed_factor"
const WEAPON_THRUST_HEAD_WIDTH: String = "thrust_head_width"
const WEAPON_HEAD_DIAMETER: String = "head_diameter"
const WEAPON_EDGE_WIDTH: String = "edge_width"
const WEAPON_DEPTH_MELEE_ELIGIBLE: String = "depth_melee_eligible"
const WEAPON_BLADE_CUT_RATIO: String = "blade_cut_ratio"
const WEAPON_STAB_CUT_RATIO: String = "stab_cut_ratio"
const WEAPON_SHARPNESS: String = "sharpness"
const WEAPON_PAR_PART_ID: String = "parry_part_id"
const WEAPON_BIND_RIPOSTE_CONTACTS: String = "bind_riposte_contact_types"
const WEAPON_IMPACT_VELOCITY_BANDS: String = "impact_velocity_bands"
const WEAPON_STRIKE_PHYSICS: String = "strike_physics"
const WEAPON_MOVES: String = "moves"
const WEAPON_PAR_ELIGIBLE: String = "parry_eligible"
const WEAPON_COOLDOWN: String = "cooldown"
const WEAPON_BASE_COOLDOWN: String = "base_cooldown"
const WEAPON_LENGTH_CM: String = "length_cm"
const WEAPON_MASS_FRACTION: String = "mass_fraction"
const WEAPON_STRIKING_FOR: String = "striking_for"
const WEAPON_TYPE: String = "weapon_type"
const WEAPON_IS_PARRY: String = "is_parry"
const WEAPON_IS_FEINT: String = "is_feint"
const WEAPON_CONTACT_TYPE: String = "contact_type"
const WEAPON_WINDUP_MULTIPLIER: String = "windup_multiplier"
const WEAPON_FEINT_WINDUP_DURATION_MULT: String = "feint_windup_duration_mult"
const WEAPON_FEINT_TARGET_REVEAL_AT_PROGRESS: String = "feint_target_reveal_at_progress"
const WEAPON_DEFAULT_FORM: String = "default_form"
const WEAPON_ALLOWED_FORMS: String = "allowed_forms"

# --- Entity/core stat dict keys ---
const ENTITY_STRENGTH: String = "strength"
const ENTITY_AGILITY: String = "agility"
const ENTITY_INTELLIGENCE: String = "intelligence"
const ENTITY_ENDURANCE: String = "endurance"
const ENTITY_PERCEPTION: String = "perception"
const ENTITY_SPEED: String = "speed"
const ENTITY_BLOOD_LOSS_DEATH_THRESHOLD: String = "blood_loss_death_threshold"
const ENTITY_BLOOD_LOSS_CRITICAL_THRESHOLD: String = "blood_loss_critical_threshold"

# --- Member snapshot stat keys ---
const SNAPSHOT_STRENGTH: String = "strength"
const SNAPSHOT_AGILITY: String = "agility"
const SNAPSHOT_INTELLIGENCE: String = "intelligence"
const SNAPSHOT_ENDURANCE: String = "endurance"
const SNAPSHOT_PERCEPTION: String = "perception"

# --- Attack resolver strike modifier dict keys (sm.get() in resolve) ---
const ATK_STRIKE_MOMENTUM_MULT: String = "strike_momentum_mult"
const ATK_BLUNT_DAMAGE_MULT: String = "blunt_damage_mult"
const ATK_BLUNT_MOMENTUM_PA_MULT: String = "blunt_momentum_pa_mult"
const ATK_PENETRATION_SHARP: String = "penetration_sharp"
const ATK_PENETRATION_BLUNT_MPA: String = "penetration_blunt_momentum_per_area"
const ATK_BLUNT_CONTACT_CM: String = "blunt_contact_cm"

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
const FM_FROM_RANK: String = "from_rank"
const FM_FROM_FILE: String = "from_file"
const FM_PROX: String = "prox"
const FM_RK: String = "rk"
const FM_SRC_F: String = "src_f"
const FM_DST_F: String = "dst_f"

# --- Combatant snapshot keys (CombatCombatantsSnapshot) ---
const SNAPSHOT_COMBAT_ABSENT: String = "combat_absent"
const SNAPSHOT_PENDING_ATTACK: String = "pending_attack"

# --- Map field care / triage dict keys ---
const MAP_TRIAGE_LINE: String = "triage_line"
const MAP_MED_COUNT: String = "med_count"
const MAP_SUPPLY_FACTOR: String = "supply_factor"

# --- Attack path resolver dict keys (tap/attack_path) ---
const ARC_OCCUPANCY_BLOCKED: String = "arc_occupancy_blocked"
const SURROUND_THREAT_COUNT: String = "surround_threat_count"
const SURROUND_THREAT_WEIGHT_SUM: String = "surround_threat_weight_sum"

# --- Entity damage extras/force dict keys ---
const DAMAGE_FORCE_JOULE_ARMOR_BUDGET: String = "force_joule_armor_budget"
const DAMAGE_DISABLE_JOULE_ARMOR_BUDGET: String = "disable_joule_armor_budget"
const DAMAGE_FORCE_LAYER_TISSUE: String = "force_layer_tissue"
const DAMAGE_FORCE_LAYER_TISSUE_CURVES: String = "force_layer_tissue_curves"
const DAMAGE_DISABLE_LAYER_TISSUE: String = "disable_layer_tissue"
const DAMAGE_DISABLE_LAYER_TISSUE_CURVES: String = "disable_layer_tissue_curves"
const DAMAGE_FORCE_MATERIAL_CURVES: String = "force_material_curves"
const DAMAGE_MATERIAL_CURVE_BLEND_WEIGHT: String = "material_curve_blend_weight"
const DAMAGE_FORCE_TISSUE_ENERGY_POOL: String = "force_tissue_energy_pool"
const DAMAGE_DISABLE_TISSUE_ENERGY_POOL: String = "disable_tissue_energy_pool"

# --- Direct pressure dict keys (entity meta-props) ---
const DIRECT_PRESSURE_ASSIST_HELD_BY: String = "direct_pressure_assist_held_by"
const DIRECT_PRESSURE_ON_ALLY: String = "direct_pressure_on_ally"
const DIRECT_PRESSURE_PART: String = "direct_pressure_part"

# --- Medical phase dict keys (windup/action) ---
const MEDICAL_ID: String = "medical_id"
const MEDICAL_TARGET_COMBATANT_ID: String = "target_combatant_id"
const MEDICAL_PERFORMER_ID: String = "performer_id"
const MEDICAL_URGENCY: String = "urgency"
const MEDICAL_DURATION_METHOD: String = "duration_method"
const MEDICAL_DURATION_TAKES_PART: String = "duration_takes_part"
const MEDICAL_TARGET_METHOD: String = "target_method"
const MEDICAL_SUCCESS: String = "success"
const MEDICAL_CONTINUE_LOOP: String = "continue_loop"
const MEDICAL_BREAK_REASON: String = "break_reason"
const MEDICAL_TOTAL_ITERATIONS: String = "total_iterations"
const MEDICAL_SIM_SECONDS: String = "sim_seconds"
const MEDICAL_STAGNANT_STEPS: String = "stagnant_steps"

# --- Weapon damage helper dict keys ---
const WD_REFERENCE_BODY_MASS_KG: String = "reference_body_mass_kg"
const WD_EFFECTIVE_BLUNT_TARGET_MASS_KG: String = "effective_blunt_target_mass_kg"
const WD_KINEMATIC_DELIVERY: String = "kinematic_delivery"
const WD_KINEMATIC_MIXED_BLEND: String = "kinematic_mixed_blend"
const WD_DELIVERY_COMMIT_FRACTION: String = "delivery_commit_fraction"
const WD_ARCHETYPE: String = "archetype"
const WD_CONTACT_OVERRIDE_CM: String = "contact_override_cm"

# --- Strike realism profile dict keys ---
const SRP_STATION_MEAN: String = "station_mean"
const SRP_STATION_SPREAD: String = "station_spread"
const SRP_IMPACT_STATION_MEAN: String = "impact_station_mean"
const SRP_IMPACT_STATION_SPREAD: String = "impact_station_spread"
const SRP_IMPACT_BLADE_STATION: String = "impact_blade_station"
const SRP_STATION_CUT_VEL_GUARD: String = "station_cut_vel_guard"
const SRP_STATION_CUT_VEL_TIP: String = "station_cut_vel_tip"
const SRP_BLUNT_PRESSURE: String = "blunt_pressure"
const SRP_BLUNT_HEAD_REF_CM: String = "blunt_head_ref_cm"

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
const PA_COUNTER_TEMPO: String = "counter_tempo"
const PA_RIPOSTE_CHAIN: String = "riposte_chain"
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

# --- Entity node property keys (entity.get() on CoreEntity/Node) ---
const ENTITY_DOMINANT_HAND: String = "dominant_hand"
const ENTITY_BLOOD_VOLUME_ML: String = "blood_volume_ml"
const ENTITY_BLOOD_VOLUME_ML_MAX: String = "blood_volume_ml_max"
const SNAPSHOT_BLOOD_VOLUME: String = "blood_volume"
const ENTITY_LINEN_STRIPS_REMAINING: String = "linen_strips_remaining"
const ENTITY_DURING_COMBAT: String = "during_combat"

# --- Injury dict keys (injury dicts in entity.wounds) ---
const INJURY_DAMAGE: String = "damage"

# --- Entity damage result dict keys (EntityDamage.take_result) ---
const RESULT_PENETRATION_TO_TISSUE_MM: String = "penetration_to_tissue_mm"
const RESULT_LAYER_STATES: String = "layer_states"
const RESULT_TISSUE_ENERGY_REMAINING_J: String = "tissue_energy_remaining_j"
const RESULT_TISSUE_ENERGY_CAPACITY_J: String = "tissue_energy_capacity_j"
const RESULT_MFB_CUT: String = "mfb_cut"
const RESULT_MFB_BLUNT: String = "mfb_blunt"
const RESULT_MFB_BONE: String = "mfb_bone"
const RESULT_CURVE_CUT: String = "curve_cut"
const RESULT_CURVE_BLUNT: String = "curve_blunt"
const RESULT_CURVE_BONE: String = "curve_bone"

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
const CTRL_GAUGE_LABEL: String = "gauge_label"
const CTRL_BLOOD_LABEL: String = "blood_label"
const CTRL_BLOOD_BAR: String = "blood_bar"
const CTRL_BLEEDING_LABEL: String = "bleeding_label"
const CTRL_CONSCIOUSNESS_LABEL: String = "consciousness_label"
const CTRL_ROW: String = "row"
const CTRL_LAST_HIT_LABEL: String = "last_hit_label"

# --- Company state internal dict keys ---
const COMPANY_STATE_TUTORIAL_COMPLETED: String = "tutorial_completed"
const COMPANY_STATE_BANKRUPT: String = "bankrupt"
const COMPANY_STATE_OVERWORLD_STEP_COUNT: String = "overworld_step_count"
const COMPANY_STATE_CONTRACT_DECK_INDEX: String = "contract_deck_index"

# --- Member snapshot / roster dict keys ---
const MEMBER_STANCE_PREFERENCE: String = "stance_preference"

# --- World/meta property keys (WorldNode.get()) ---
const WORLD_META_RNG: String = "rng"
const WORLD_META_ENEMY_SCENE: String = "enemy_scene"

# --- Part weight resolver keys (AttackPathResolver) ---
const PART_WEIGHTS_CHEST: String = BodyPartConstants.PART_CHEST

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
const ARCHETYPE_KINEMATIC_MIXED_BLEND: String = "kinematic_mixed_blend"

# --- Entity stat dict keys (combatant stats_dict) ---
const ENTITY_MELEE_SKILL: String = "melee_skill"

# --- Movement policy dict keys (CombatEngagementMode.movement_policy → CombatResolveAction/CombatFormationMoveListing) ---
const MOVE_POLICY_ALLOW_SWAP_RANK: String = "allow_swap_rank"
const MOVE_POLICY_ALLOW_DRAG_BACK: String = "allow_drag_back"
const MOVE_POLICY_ALLOW_FALL_BACK: String = "allow_fall_back"

# --- UI/result display keys (CombatLogFormatter, BattleScene) ---
const RESULT_TOTAL_PHYSICAL: String = "total_physical"
const RESULT_PRE_ARMOR: String = "pre_armor"
const SOAK_TRACE_PASS: String = "pass"
const SCAN_COUNT: String = "count"

# --- Attack path angle keys (pending_attack pa dict) ---
const PA_ARC_END_DEG: String = "arc_end_deg"

# --- Formation dict keys (new additions) ---
const FM_FORMATION_PLUG_FORWARD_COOLDOWN_UNTIL: String = "formation_plug_forward_cooldown_until"
# (FM_VACANCY_LATERAL_LAST_FROM_FILE declared at line 446, FM_VACANCY_LATERAL_LAST_TO_FILE at 447, FM_VACANCY_LATERAL_REVERSE_LOCK_UNTIL at 445)
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
const BIND_ANGULAR_ADVANTAGE_SIDE: String = "angular_advantage_side"

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

# --- Form switch keys (new additions) ---
const FORM_SWITCH_COOLDOWN_UNTIL: String = "form_switch_cooldown_until"

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
const PAYLOAD_WIND_UP_S: String = "wind_up_s"
const PAYLOAD_GAUGE_DEF_PRE: String = "gauge_def_pre"
const PAYLOAD_ATK_GUARD: String = "atk_guard"
const PAYLOAD_ATK_FORM: String = "atk_form"
const PAYLOAD_DEF_GUARD: String = "def_guard"
const PAYLOAD_PARRY_BIND: String = "parry_bind"
const PAYLOAD_FOLLOW_THROUGH_REM: String = "follow_through_rem"

# --- Attention entry keys (new additions) ---
const ATTENTION_ENTRY_LINE_COUNTS: String = "line_counts"
const ATTENTION_ENTRY_MOVE_ID_COUNTS: String = "move_id_counts"
const ATTENTION_ENTRY_FEINT_RESOLVED: String = "feint_resolved"
const ATTENTION_ENTRY_PARRY_DEFLECT: String = "parry_deflect"
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
const DEF_CHOICE_M_A_VELOCITY: String = "m_a_velocity"

# --- Combatant state keys ---
const COMBATANT_ENGAGED_WITH_ID: String = "engaged_with_id"
const COMBATANT_FLURRY_EXCHANGES_LEFT: String = "flurry_exchanges_left"
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
const COMBATANT_GUARD_LINE: String = "guard_line"

# --- Attack result / aim override keys ---
const AIM_PART_OVERRIDE: String = "_AIM_PART_OVERRIDE"

