class_name CombatConstantsFeatureFlags
extends RefCounted

const FEATURE_MS_POSITIONAL_AWARENESS := true
const FEATURE_MS_L6_ROUT := true
const FEATURE_MS_FEINT_RESISTANCE := true
const FEATURE_MS_MID_INFIGHT_MED := true
const FEATURE_MS_MEDICAL_ESCALATION := true
const FEATURE_MS_POST_STRIKE := true
const FEATURE_FLURRY_BIND_EXCHANGE := true
const SURROUND_SECTOR_LOAD_FREE := 1.0
## After free allowance: `mult = 1/(1 + k * excess)` before perception; `k=1` matches integer-only `1/n` when each
## threat weight is 1.
const SURROUND_SECTOR_LOAD_K := 1.0
## Minimum per threatening enemy weight = clamp(`effective_pair_file_spacing_equivalent` /
## `PARRY_FLANK_EFFECTIVE_FILES_MIN`, min, 1).
const SURROUND_SECTOR_WEIGHT_MIN := 0.35
const FEATURE_HEMA_EIGHT_GUARD_LINES := true
const FEATURE_ARM_INTERPOSE := true
const ARM_INTERPOSE_MIN_ANGLE_DEG := 45.0
const ARM_INTERPOSE_MIN_ALIGN := 0.15
const ARM_INTERPOSE_MAX_ALIGN := 0.72
const ARM_INTERPOSE_ALIGNMENT_BOOST := 0.22
const ARM_INTERPOSE_MAX_PATH_INDEX := 4
const ARM_INTERPOSE_HIT_WEIGHT_MULT := 1.55
const ARM_INTERPOSE_MULT := 0.55
const ARM_INTERPOSE_MULT_LIGHT_ARMOR := 0.70
const FEATURE_IV6_ATTACK_PATH_OCTANT := true
const FEATURE_SURROUND_ARC_OCCUPANCY := true
const SURROUND_ARC_HALF_WIDTH_DEG := 38.0
const SURROUND_ARC_OVERLAP_TOLERANCE_DEG := 6.0
const SURROUND_ARC_BLOCKED_THREAT_WEIGHT_MULT := 0.35
const FEATURE_AMBIENT_PAIN_SHOCK := true
const FEATURE_ARMOR_BURDEN := true
## IV-7: equipped armor mass. Full plate harness is 18-25 kg (Met Museum); 22 kg is representative average.
const FORMATION_ARMOR_MASS_REF_KG := 22.0
## Armor slows cooldown/readiness; 45% max penalty reflects historical reality of armored combat being exhausting work.
const FORMATION_ARMOR_MAX_SLOW_MULT := 1.45
const ARMOR_BURDEN_ACTION_READY_MAX_MULT := 1.28
const ARMOR_BURDEN_PASSIVE_READINESS_FLOOR := 0.78
const FEATURE_INITIATIVE_ORDER := true
const INITIATIVE_ORDER_STAGGER_STEP_S := 0.08
const FEATURE_GAP_COLUMN_TOPOLOGY := false
const FEATURE_SUBREGION_COMBAT_MULT := true
const FEATURE_LEADER_FORMATION_COMMAND := false
const AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT := 6.0
const AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT := 0.38
const AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT := 1.45
const AI_FOCUS_LINE_ALREADY_FOCUSED_WEIGHT := 0.02
const FEATURE_IV12_SLOT_DISTRACTION := false
const IV12_SLOT_DISTRACTION_WEIGHT_PAD := 0.35
const IV12_AI_COLOCATED_TARGET_BIAS_MULT := 1.12
const IV12_AI_OFFENSE_WEIGHT_MULT := 0.78
const FEATURE_IV13_WEAPON_REACH_ZOC := false
const IV13_WEAPON_REACH_ZOC_REF_M := 1.5
const IV13_WEAPON_REACH_ZOC_SPAN_M := 1.0
const IV13_WEAPON_REACH_ZOC_MAX_BONUS_M := 0.35
const IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX := 0.55
const FEATURE_T44_SPATIAL_BAND_PA := true
const T44_SPATIAL_BAND_PA_MULT_CLOSE := 1.12
const T44_SPATIAL_BAND_PA_MULT_MID := 1.0
const T44_SPATIAL_BAND_PA_MULT_LONG := 0.88
const FEATURE_T44_SPATIAL_FILE_DODGE_BIAS := true
const T44_SPATIAL_FILE_DODGE_WING_MULT := 1.1
const FEATURE_T44_SPATIAL_FLURRY_PA := true
const T44_SPATIAL_FLURRY_PA_MULT := 1.08
const FEATURE_AUTOMATIC_DOCTRINE := true
## S6 pilot: layer KE budget scales pre-armor damage (sqrt curve).
const FEATURE_JOULE_ARMOR_BUDGET := true
## Dev: re-equip back ranks with SPEAR after start for polearm debugging.
const DEBUG_BACK_RANK_DEPTH_POLEARM_LOADOUT := false
## Fight exhaustion index — exhaustion_performance_mult gates (Stamina sub-module).
const FEATURE_FIGHT_EXHAUSTION_INDEX := true
## Vitals-finish exploit: attackers press an already-damaged head/chest (targeting realism).
const FEATURE_WOUNDED_VITALS_EXPLOIT := true
## Doc-10 Issue 2 (plan_balance_tuning.md): arm sub-region + severity degrade weapon function (grip).
const FEATURE_ARM_WOUND_DEGRADATION := true
## Doc-9 (yomi_transitions): a partial-parry **bind** opens the defender counterstrike (riposte chain) window.
const FEATURE_PARRY_COUNTERSTRIKE_WINDOW := true
## Grip penalty per weighted wound unit: total loss% = sub_region_weight * severity_weight * 0.45. Derived so a
## severe wound (severity weight 1.0) lands in each plan_balance_tuning.md sub-region band (lines 541-544):
## hand 45% in [20-50], forearm 38.25% in [15-40], upper_arm 27% in [10-30], elbow 51.75% in [25-60].
const ARM_WOUND_GRIP_PENALTY_PER_UNIT := 0.45
## Floor on weapon-function grip mult (matches the 0.1 parry/attack floors elsewhere).
const ARM_WOUND_GRIP_FLOOR := 0.1
## Localized grip impact per arm sub-region, scaled so severe loss% hits the design table bands (lines 541-544):
## hand precision aim [20-50], forearm grip/power [15-40], upper_arm swing power [10-30], elbow combined [25-60].
const ARM_WOUND_GRIP_SUB_REGION_WEIGHT: Dictionary = {
    "hand": 1.0,
    "forearm": 0.85,
    "elbow": 1.15,
    "upper_arm": 0.6,
}
## Severity escalates grip loss against the ATLS clinical table (lines 522-525): minor hand 11.25% in [10-20]
## (superficial hand cut), severe hand 45% in [30-50] (tendon severance), critical hand/forearm 60.75%/51.6% in
## [50-70] (radial/ulnar artery+nerve). Critical upper_arm brachial severance (~80-100%) is the arterial/ischemia
## event handled by the bleeding system (ARTERIAL_CHANCE_BY_SEVERITY), not this tissue grip mult.
const ARM_WOUND_GRIP_SEVERITY_WEIGHT: Dictionary = {
    BleedingConstants.SEVERITY_MINOR: 0.25,
    BleedingConstants.SEVERITY_MODERATE: 0.55,
    BleedingConstants.SEVERITY_SEVERE: 1.0,
    BleedingConstants.SEVERITY_CRITICAL: 1.35,
}
## Parry-penalty ratio: plan_balance_tuning.md line 91 anchors "-15% attack / -10% parry" = 10/15. Parry mult =
## 1 - (1 - grip) * this, so parry capacity stays gentler than attack at the same wound (ratio < 1) while scaling
## with the same severity-scaled grip mult.
const ARM_WOUND_GRIP_PARRY_PENALTY_RATIO := 10.0 / 15.0

## Tier 4.3 combat attention (default on; harness may toggle).
static var _feature_combat_attention_enabled: bool = true
static var _feature_mental_stack_ai_enabled: bool = true
static var _feature_ms_positional_awareness_load: int = -1
static var _feature_ms_l6_rout_load: int = -1
static var _feature_ms_feint_resistance_load: int = -1
static var _feature_ms_mid_infight_med_load: int = -1
static var _feature_ms_medical_escalation_load: int = -1
static var _feature_ms_post_strike_load: int = -1
static var _feature_counter_tempo_enabled: bool = true
static var _feature_flurry_bind_exchange_enabled: bool = FEATURE_FLURRY_BIND_EXCHANGE
static var _feature_position_angle_footwork_enabled: bool = true
static var _feature_sector_surround_load: bool = true
## First `SURROUND_SECTOR_LOAD_FREE` units of summed threat weight incur no surround split (one primary engagement
## axis).
static var _feature_hema_eight_guard_lines_load: int = -1
static var _feature_arm_interpose_load: int = -1
static var _feature_iv6_attack_path_octant_load: int = -1
static var _feature_ambient_pain_shock: bool = FEATURE_AMBIENT_PAIN_SHOCK
static var _feature_armor_burden_load: int = -1
static var _feature_initiative_order_load: int = -1
static var _feature_gap_column_topology_load: int = -1
static var _feature_subregion_combat_mult_load: int = -1
static var _feature_leader_formation_command_load: int = -1
static var _feature_iv12_slot_distraction_load: int = -1
static var _feature_iv13_weapon_reach_zoc_load: int = -1
static var _feature_t44_spatial_band_pa_load: int = -1
static var _feature_t44_spatial_file_dodge_bias_load: int = -1
static var _feature_t44_spatial_flurry_pa_load: int = -1
static var _feature_fight_exhaustion_index: bool = FEATURE_FIGHT_EXHAUSTION_INDEX
static var _feature_arm_wound_degradation_load: int = -1
static var _feature_parry_counterstrike_window_load: int = -1


static func is_feature_combat_attention_enabled() -> bool:
    return _feature_combat_attention_enabled


static func set_feature_combat_attention_load(enabled: bool) -> void:
    _feature_combat_attention_enabled = enabled


static func is_feature_mental_stack_ai_enabled() -> bool:
    return _feature_mental_stack_ai_enabled


static func set_feature_mental_stack_ai_load(enabled: bool) -> void:
    _feature_mental_stack_ai_enabled = enabled


static func is_feature_ms_positional_awareness_enabled() -> bool:
    if _feature_ms_positional_awareness_load >= 0:
        return _feature_ms_positional_awareness_load != 0
    return FEATURE_MS_POSITIONAL_AWARENESS


static func set_feature_ms_positional_awareness_load(enabled: bool) -> void:
    _feature_ms_positional_awareness_load = 1 if enabled else 0


static func is_feature_ms_l6_rout_enabled() -> bool:
    if _feature_ms_l6_rout_load >= 0:
        return _feature_ms_l6_rout_load != 0
    return FEATURE_MS_L6_ROUT


static func set_feature_ms_l6_rout_load(enabled: bool) -> void:
    _feature_ms_l6_rout_load = 1 if enabled else 0


static func is_feature_ms_feint_resistance_enabled() -> bool:
    if _feature_ms_feint_resistance_load >= 0:
        return _feature_ms_feint_resistance_load != 0
    return FEATURE_MS_FEINT_RESISTANCE


static func set_feature_ms_feint_resistance_load(enabled: bool) -> void:
    _feature_ms_feint_resistance_load = 1 if enabled else 0


static func is_feature_ms_mid_infight_med_enabled() -> bool:
    if _feature_ms_mid_infight_med_load >= 0:
        return _feature_ms_mid_infight_med_load != 0
    return FEATURE_MS_MID_INFIGHT_MED


static func set_feature_ms_mid_infight_med_load(enabled: bool) -> void:
    _feature_ms_mid_infight_med_load = 1 if enabled else 0


static func is_feature_ms_medical_escalation_enabled() -> bool:
    if _feature_ms_medical_escalation_load >= 0:
        return _feature_ms_medical_escalation_load != 0
    return FEATURE_MS_MEDICAL_ESCALATION


static func set_feature_ms_medical_escalation_load(enabled: bool) -> void:
    _feature_ms_medical_escalation_load = 1 if enabled else 0


static func is_feature_ms_post_strike_enabled() -> bool:
    if _feature_ms_post_strike_load >= 0:
        return _feature_ms_post_strike_load != 0
    return FEATURE_MS_POST_STRIKE


static func set_feature_ms_post_strike_load(enabled: bool) -> void:
    _feature_ms_post_strike_load = 1 if enabled else 0


static func is_feature_counter_tempo_enabled() -> bool:
    return _feature_counter_tempo_enabled


static func set_feature_counter_tempo_load(enabled: bool) -> void:
    _feature_counter_tempo_enabled = enabled


## Tier 4.5: bind-exchange flurry pilot.


static func is_feature_flurry_bind_exchange_enabled() -> bool:
    return _feature_flurry_bind_exchange_enabled


static func set_feature_flurry_bind_exchange_load(enabled: bool) -> void:
    _feature_flurry_bind_exchange_enabled = enabled


static func is_feature_position_angle_footwork_enabled() -> bool:
    return _feature_position_angle_footwork_enabled


static func set_feature_position_angle_footwork_load(enabled: bool) -> void:
    _feature_position_angle_footwork_enabled = enabled


## Phase D: sector-weighted surround load vs integer-only threat count (Tier 3.1).
## Default **true** (sector `surround_threat_weight_sum` + `1/(1+k.excess)`).
## **`set_feature_sector_surround_load(false)`** for integer `surround_threat_count` regression / compare.


static func is_feature_sector_surround_load() -> bool:
    return _feature_sector_surround_load


static func set_feature_sector_surround_load(on: bool) -> void:
    _feature_sector_surround_load = on


static func is_feature_hema_eight_guard_lines_enabled() -> bool:
    if _feature_hema_eight_guard_lines_load >= 0:
        return _feature_hema_eight_guard_lines_load != 0
    return FEATURE_HEMA_EIGHT_GUARD_LINES


static func set_feature_hema_eight_guard_lines_load(enabled: bool) -> void:
    _feature_hema_eight_guard_lines_load = 1 if enabled else 0


static func is_feature_arm_interpose_enabled() -> bool:
    if _feature_arm_interpose_load >= 0:
        return _feature_arm_interpose_load != 0
    return FEATURE_ARM_INTERPOSE


static func set_feature_arm_interpose_load(enabled: bool) -> void:
    _feature_arm_interpose_load = 1 if enabled else 0


static func is_feature_iv6_attack_path_octant_enabled() -> bool:
    if _feature_iv6_attack_path_octant_load >= 0:
        return _feature_iv6_attack_path_octant_load != 0
    return FEATURE_IV6_ATTACK_PATH_OCTANT


static func set_feature_iv6_attack_path_octant_load(enabled: bool) -> void:
    _feature_iv6_attack_path_octant_load = 1 if enabled else 0


static func is_feature_surround_arc_occupancy_enabled() -> bool:
    return FEATURE_SURROUND_ARC_OCCUPANCY


## Tier 0 pilot: overlapping melee wind-ups on one defender — parry only the highest-threat attacker.
## Tier 6.1: sustained high pain rolls for pain shock during combat ticks (see
## **`EntityPainConsciousness.try_ambient_pain_shock_tick`**).


static func is_feature_ambient_pain_shock() -> bool:
    return _feature_ambient_pain_shock


static func set_feature_ambient_pain_shock(on: bool) -> void:
    _feature_ambient_pain_shock = on


## IV-7: equipped armor mass.


static func is_feature_armor_burden_enabled() -> bool:
    if _feature_armor_burden_load >= 0:
        return _feature_armor_burden_load != 0
    return FEATURE_ARMOR_BURDEN


static func set_feature_armor_burden_load(enabled: bool) -> void:
    _feature_armor_burden_load = 1 if enabled else 0


static func armor_burden_mass_ratio_for_combatant(combatant: Dictionary) -> float:
    if combatant.is_empty():
        return 0.0
    var node: Node = CombatantEntityAccess.scene_node(combatant)
    if node == null:
        return 0.0
    var mass_kg: float = CombatantEntityAccess.get_total_armor_mass_kg_from_node(node)
    return clampf(mass_kg / FORMATION_ARMOR_MASS_REF_KG, 0.0, 1.5)


static func armor_burden_action_ready_mult(combatant: Dictionary) -> float:
    if not is_feature_armor_burden_enabled():
        return 1.0
    var t: float = clampf(armor_burden_mass_ratio_for_combatant(combatant), 0.0, 1.0)
    return lerpf(1.0, ARMOR_BURDEN_ACTION_READY_MAX_MULT, t)


static func armor_burden_passive_readiness_mult(combatant: Dictionary) -> float:
    if not is_feature_armor_burden_enabled():
        return 1.0
    var t: float = clampf(armor_burden_mass_ratio_for_combatant(combatant), 0.0, 1.0)
    return lerpf(1.0, ARMOR_BURDEN_PASSIVE_READINESS_FLOOR, t)


## IV-8: combat-start initiative order.


static func is_feature_initiative_order_enabled() -> bool:
    if _feature_initiative_order_load >= 0:
        return _feature_initiative_order_load != 0
    return FEATURE_INITIATIVE_ORDER


static func set_feature_initiative_order_load(enabled: bool) -> void:
    _feature_initiative_order_load = 1 if enabled else 0


static func initiative_score_for_combatant(combatant: Dictionary) -> float:
    if combatant.is_empty():
        return 0.0
    var stats: Dictionary = CombatantEntityAccess.stats_dict(combatant)
    var agi: float = stats.get(
        DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE
    )
    var perc: float = stats.get(
        DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE
    )
    var rank_factor: float = maxf(0.65, 1.2 - float(CombatantEntityAccess.rank_int(combatant)) * 0.18)
    var armor_factor: float = 1.0 / maxf(0.01, armor_burden_action_ready_mult(combatant))
    return CombatConstantsParry.stats_factor_agi_perc(agi, perc) * rank_factor * armor_factor


static func compare_combatants_for_initiative_order(a: Dictionary, b: Dictionary) -> bool:
    var sa: float = initiative_score_for_combatant(a)
    var sb: float = initiative_score_for_combatant(b)
    if sa != sb:
        return sa > sb
    var agi_a: int = int(CombatantEntityAccess.stats_dict(a).get(
        DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE
    ))
    var agi_b: int = int(CombatantEntityAccess.stats_dict(b).get(
        DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE
    ))
    if agi_a != agi_b:
        return agi_a > agi_b
    return CombatantEntityAccess.id_int(a) < CombatantEntityAccess.id_int(b)


## IV-9: gap-column slot topology.


static func is_feature_gap_column_topology_enabled() -> bool:
    if _feature_gap_column_topology_load >= 0:
        return _feature_gap_column_topology_load != 0
    return FEATURE_GAP_COLUMN_TOPOLOGY


static func set_feature_gap_column_topology_load(enabled: bool) -> void:
    _feature_gap_column_topology_load = 1 if enabled else 0


static func iv9_gap_column_doc_sync_line() -> String:
    return (
        (
            "IV-9 gap-column: default_flag=%s compact_native_line=disabled_when_on "
            + "slots=occupied_files_have_gaps slice2=column_graph_file_distance+diagram_gaps "
            + "pair_geometry=column_arc_when_gaps harness=dual_mode_formation_targeting "
            + "flow_refresh=swap_drag_fall_back_reconcile"
        )
        % ("on" if FEATURE_GAP_COLUMN_TOPOLOGY else "off")
    )


## IV-10: sub-region combat mult.


static func is_feature_subregion_combat_mult_enabled() -> bool:
    if _feature_subregion_combat_mult_load >= 0:
        return _feature_subregion_combat_mult_load != 0
    return FEATURE_SUBREGION_COMBAT_MULT


static func set_feature_subregion_combat_mult_load(enabled: bool) -> void:
    _feature_subregion_combat_mult_load = 1 if enabled else 0


## IV-11: leader formation command.


static func is_feature_leader_formation_command_enabled() -> bool:
    if _feature_leader_formation_command_load >= 0:
        return _feature_leader_formation_command_load != 0
    return FEATURE_LEADER_FORMATION_COMMAND


static func set_feature_leader_formation_command_load(enabled: bool) -> void:
    _feature_leader_formation_command_load = 1 if enabled else 0


static func iv11_leader_formation_doc_sync_line() -> String:
    var feat: String = "on" if FEATURE_LEADER_FORMATION_COMMAND else "off"
    return (
        "IV-11 leader formation: slice1=focus_line_telegraph_match "
        + "slice3=register_stamp+formatter "
        + "slice4=bridge_roster_stamp+diagram_callout "
        + "is_party_leader=CombatManager.register "
        + "weight="
        + str(snappedf(AI_FOCUS_LINE_PARTY_LEADER_TELEGRAPH_MATCH_WEIGHT, 0.1))
        + " menu_abilities=roster_suffix "
        + "order_hold_lane_feature="
        + feat
        + " issuer=is_formation_command_issuer menu_label=Order_Hold_lane "
        + "slice5=order_probing menu_label_probing=Order_Probe "
        + "slice6=enemy_leader diagram_cmd=[Cmd] "
        + "slice7=roster_menu_leader_suffix "
        + "slice8=order_pinch_center menu_label_pinch=Order_Pinch_center "
        + "slice9=enemy_commander_orders+doctrine_cycle ai_pick="
        + str(snappedf(AI_LEADER_FORMATION_COMMAND_PICK_WEIGHT, 0.01))
        + " slice10=pinch_outnumber_ai_mult="
        + str(snappedf(AI_LEADER_FORMATION_COMMAND_PINCH_OUTNUMBER_MULT, 0.01))
        + " f5_track=iv11_leader_order encounter_spawn=enemy_leader_index"
    )


## IV-12: slot distraction.


static func is_feature_iv12_slot_distraction_enabled() -> bool:
    if _feature_iv12_slot_distraction_load >= 0:
        return _feature_iv12_slot_distraction_load != 0
    return FEATURE_IV12_SLOT_DISTRACTION


static func set_feature_iv12_slot_distraction_load(enabled: bool) -> void:
    _feature_iv12_slot_distraction_load = 1 if enabled else 0


static func iv12_slot_distraction_doc_sync_line() -> String:
    var feat: String = "on" if FEATURE_IV12_SLOT_DISTRACTION else "off"
    return (
        "IV-12 slot distraction: feature="
        + feat
        + " pad="
        + str(snappedf(IV12_SLOT_DISTRACTION_WEIGHT_PAD, 0.01))
        + " ai_offense="
        + str(snappedf(IV12_AI_OFFENSE_WEIGHT_MULT, 0.01))
        + " ai_pile_on="
        + str(snappedf(IV12_AI_COLOCATED_TARGET_BIAS_MULT, 0.01))
        + " slice3=formation_slot_cell drag_back_dual_occ"
    )


## IV-13: weapon reach ZoC.


static func is_feature_iv13_weapon_reach_zoc_enabled() -> bool:
    if _feature_iv13_weapon_reach_zoc_load >= 0:
        return _feature_iv13_weapon_reach_zoc_load != 0
    return FEATURE_IV13_WEAPON_REACH_ZOC


static func set_feature_iv13_weapon_reach_zoc_load(enabled: bool) -> void:
    _feature_iv13_weapon_reach_zoc_load = 1 if enabled else 0


static func iv13_weapon_reach_zoc_doc_sync_line() -> String:
    return (
        "IV-13 weapon-reach ZoC: feature=%s weak_front<%.2f max_bonus=%.2fm ref=%.1fm"
        % [
            "on" if FEATURE_IV13_WEAPON_REACH_ZOC else "off",
            IV13_WEAPON_REACH_ZOC_WEAK_FRONT_MAX,
            IV13_WEAPON_REACH_ZOC_MAX_BONUS_M,
            IV13_WEAPON_REACH_ZOC_REF_M,
        ]
    )


## Tier 4.4 spatial slice 1: engagement band PA step.


static func is_feature_t44_spatial_band_pa_enabled() -> bool:
    if _feature_t44_spatial_band_pa_load >= 0:
        return _feature_t44_spatial_band_pa_load != 0
    return FEATURE_T44_SPATIAL_BAND_PA


static func set_feature_t44_spatial_band_pa_load(enabled: bool) -> void:
    _feature_t44_spatial_band_pa_load = 1 if enabled else 0


static func t44_spatial_band_pa_magnitude_mult(band: String) -> float:
    match str(band):
        CombatConstantsDistance.DISTANCE_CLOSE:
            return T44_SPATIAL_BAND_PA_MULT_CLOSE
        CombatConstantsDistance.DISTANCE_LONG:
            return T44_SPATIAL_BAND_PA_MULT_LONG
        _:
            return T44_SPATIAL_BAND_PA_MULT_MID


static func t44_spatial_band_pa_doc_sync_line() -> String:
    return (
        "T44 spatial band PA: feature=%s close=%.2f mid=%.2f long=%.2f slice1=engagement_band_step_magnitude"
        % [
            "on" if FEATURE_T44_SPATIAL_BAND_PA else "off",
            T44_SPATIAL_BAND_PA_MULT_CLOSE,
            T44_SPATIAL_BAND_PA_MULT_MID,
            T44_SPATIAL_BAND_PA_MULT_LONG,
        ]
    )


## Tier 4.4 spatial slice 2: wing file dodge PA bias.


static func is_feature_t44_spatial_file_dodge_bias_enabled() -> bool:
    if _feature_t44_spatial_file_dodge_bias_load >= 0:
        return _feature_t44_spatial_file_dodge_bias_load != 0
    return FEATURE_T44_SPATIAL_FILE_DODGE_BIAS


static func set_feature_t44_spatial_file_dodge_bias_load(enabled: bool) -> void:
    _feature_t44_spatial_file_dodge_bias_load = 1 if enabled else 0


static func t44_spatial_file_dodge_wing_mult(file_index: int, formation_files: int) -> float:
    if not is_feature_t44_spatial_file_dodge_bias_enabled():
        return 1.0
    var files: int = maxi(1, formation_files)
    if files < 2:
        return 1.0
    var fi: int = maxi(0, file_index)
    if fi <= 0 or fi >= files - 1:
        return T44_SPATIAL_FILE_DODGE_WING_MULT
    return 1.0


static func t44_spatial_file_dodge_doc_sync_line() -> String:
    return (
        "T44 spatial file dodge: feature=%s wing_mult=%.2f slice2=wing_file_dodge_step_bias"
        % [
            "on" if FEATURE_T44_SPATIAL_FILE_DODGE_BIAS else "off",
            T44_SPATIAL_FILE_DODGE_WING_MULT,
        ]
    )


## Tier 4.4 spatial slice 3: flurry PA step.


static func is_feature_t44_spatial_flurry_pa_enabled() -> bool:
    if _feature_t44_spatial_flurry_pa_load >= 0:
        return _feature_t44_spatial_flurry_pa_load != 0
    return FEATURE_T44_SPATIAL_FLURRY_PA


static func set_feature_t44_spatial_flurry_pa_load(enabled: bool) -> void:
    _feature_t44_spatial_flurry_pa_load = 1 if enabled else 0


static func t44_spatial_flurry_pa_doc_sync_line() -> String:
    return (
        "T44 spatial flurry PA: feature=%s mult=%.2f slice3=flurry_bind_pa_boost"
        % [
            "on" if FEATURE_T44_SPATIAL_FLURRY_PA else "off",
            T44_SPATIAL_FLURRY_PA_MULT,
        ]
    )


## Option 4 pilot: automatic doctrine switch (pinch_center from hollow front / numeric superiority).


static func is_feature_fight_exhaustion_enabled() -> bool:
    return _feature_fight_exhaustion_index


static func set_feature_fight_exhaustion_index_load(on: bool) -> void:
    _feature_fight_exhaustion_index = on


## Arm wound degradation (plan_balance_tuning.md Issue 2): sub-region + severity -> weapon function grip mult.


static func is_feature_arm_wound_degradation_enabled() -> bool:
    if _feature_arm_wound_degradation_load >= 0:
        return _feature_arm_wound_degradation_load != 0
    return FEATURE_ARM_WOUND_DEGRADATION


static func set_feature_arm_wound_degradation_load(enabled: bool) -> void:
    _feature_arm_wound_degradation_load = 1 if enabled else 0


static func arm_wound_degradation_doc_sync_line() -> String:
    return (
        "arm wound degradation: feature=%s penalty_per_unit=%.2f floor=%.2f "
        + "sub=hand%.2f/forearm%.2f/elbow%.2f/upper_arm%.2f "
        + "sev=minor%.2f/moderate%.2f/severe%.2f/critical%.2f "
        + "parry_ratio=%.2f "
        + "slice1=get_arm_wound_function_mult"
    ) % [
        "on" if FEATURE_ARM_WOUND_DEGRADATION else "off",
        ARM_WOUND_GRIP_PENALTY_PER_UNIT,
        ARM_WOUND_GRIP_FLOOR,
        float(ARM_WOUND_GRIP_SUB_REGION_WEIGHT["hand"]),
        float(ARM_WOUND_GRIP_SUB_REGION_WEIGHT["forearm"]),
        float(ARM_WOUND_GRIP_SUB_REGION_WEIGHT["elbow"]),
        float(ARM_WOUND_GRIP_SUB_REGION_WEIGHT["upper_arm"]),
        float(ARM_WOUND_GRIP_SEVERITY_WEIGHT[BleedingConstants.SEVERITY_MINOR]),
        float(ARM_WOUND_GRIP_SEVERITY_WEIGHT[BleedingConstants.SEVERITY_MODERATE]),
        float(ARM_WOUND_GRIP_SEVERITY_WEIGHT[BleedingConstants.SEVERITY_SEVERE]),
        float(ARM_WOUND_GRIP_SEVERITY_WEIGHT[BleedingConstants.SEVERITY_CRITICAL]),
        ARM_WOUND_GRIP_PARRY_PENALTY_RATIO,
    ]


## Parry counterstrike window: partial-parry **bind** grants the riposte chain (counterstrike) window.


static func is_feature_parry_counterstrike_window_enabled() -> bool:
    if _feature_parry_counterstrike_window_load >= 0:
        return _feature_parry_counterstrike_window_load != 0
    return FEATURE_PARRY_COUNTERSTRIKE_WINDOW


static func set_feature_parry_counterstrike_window_load(enabled: bool) -> void:
    _feature_parry_counterstrike_window_load = 1 if enabled else 0


static func parry_counterstrike_doc_sync_line() -> String:
    return (
        "parry counterstrike window: feature=%s slice1=bind_grants_riposte_chain_until "
        + "window=riposte_chain_window_s windup_mult=riposte_chain_windup_mult"
    ) % ("on" if FEATURE_PARRY_COUNTERSTRIKE_WINDOW else "off")


## Headless harness: clear all set_feature_*_load overrides.
static func reset_harness_feature_load_overrides() -> void:
    _feature_ambient_pain_shock = FEATURE_AMBIENT_PAIN_SHOCK
    _feature_fight_exhaustion_index = FEATURE_FIGHT_EXHAUSTION_INDEX
    _feature_arm_wound_degradation_load = -1
    _feature_parry_counterstrike_window_load = -1
    _feature_ms_feint_resistance_load = -1
    _feature_ms_post_strike_load = -1
    _feature_ms_positional_awareness_load = -1
    _feature_ms_l6_rout_load = -1
    _feature_ms_mid_infight_med_load = -1
    _feature_armor_burden_load = -1
    _feature_initiative_order_load = -1
    _feature_gap_column_topology_load = -1
    _feature_subregion_combat_mult_load = -1
    _feature_leader_formation_command_load = -1
    _feature_iv12_slot_distraction_load = -1
    _feature_iv13_weapon_reach_zoc_load = -1
    _feature_t44_spatial_band_pa_load = -1
    _feature_t44_spatial_file_dodge_bias_load = -1
    _feature_t44_spatial_flurry_pa_load = -1
    _feature_hema_eight_guard_lines_load = -1
    _feature_arm_interpose_load = -1
    _feature_iv6_attack_path_octant_load = -1
