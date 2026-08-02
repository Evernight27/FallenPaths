class_name CombatMuscleFatigue
extends RefCounted

## Phase 2: per-limb exertion fatigue (local pools on combatant dict).
## Layers on whole-body breath + fight exhaustion — does NOT replace composure (`gauge`) or tissue J pools.
## Design: muscle group fatigue (`FEATURE_MUSCLE_GROUP_FATIGUE`). Production default on.

const COMBATANT_KEY_MUSCLE_FATIGUE := DataKeys.COMBATANT_KEY_MUSCLE_FATIGUE
const EXERTION_KIND_ATTACK := "attack"
const EXERTION_KIND_PARRY := "parry"
const EXERTION_KIND_FORMATION := "formation"


static func enabled() -> bool:
    return CombatConstants.is_feature_muscle_group_fatigue_enabled()


static func tracked_limb_parts() -> PackedStringArray:
    return PackedStringArray(
        [
            BodyPartConstants.PART_RIGHT_ARM,
            BodyPartConstants.PART_LEFT_ARM,
            BodyPartConstants.PART_RIGHT_LEG,
            BodyPartConstants.PART_LEFT_LEG,
        ]
    )


static func seed_combatant_if_enabled(c: Dictionary, entity: Node = null) -> void:
    if not enabled():
        return
    var existing: Variant = c.get(COMBATANT_KEY_MUSCLE_FATIGUE)
    if existing is Dictionary and not (existing as Dictionary).is_empty():
        return
    var pools: Dictionary = {}
    if entity != null and "muscle_fatigue" in entity and entity.muscle_fatigue is Dictionary:
        for part in tracked_limb_parts():
            pools[part] = clampf(float(entity.muscle_fatigue.get(part, 0.0)), 0.0, 1.0)
    else:
        for part in tracked_limb_parts():
            pools[part] = 0.0
    c[COMBATANT_KEY_MUSCLE_FATIGUE] = pools


static func limb_fatigue(c: Dictionary, part: String) -> float:
    if not enabled() or c.is_empty():
        return 0.0
    var raw: Variant = c.get(COMBATANT_KEY_MUSCLE_FATIGUE)
    if raw is not Dictionary:
        return 0.0
    return clampf(float((raw as Dictionary).get(part, 0.0)), 0.0, 1.0)


static func dominant_strike_limb(c: Dictionary, manager: Node = null) -> String:
    var hand: String = BodyPartConstants.PART_RIGHT_ARM
    if manager != null:
        var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
        if entity != null and "dominant_hand" in entity:
            hand = str(entity.dominant_hand)
    if hand == BodyPartConstants.PART_RIGHT_ARM or hand == "right_arm":
        return BodyPartConstants.PART_RIGHT_ARM
    if hand == BodyPartConstants.PART_LEFT_ARM or hand == "left_arm":
        return BodyPartConstants.PART_LEFT_ARM
    if hand.contains("left"):
        return BodyPartConstants.PART_LEFT_ARM
    return BodyPartConstants.PART_RIGHT_ARM


static func off_strike_limb(dominant_part: String) -> String:
    return (
        BodyPartConstants.PART_LEFT_ARM
        if dominant_part == BodyPartConstants.PART_RIGHT_ARM
        else BodyPartConstants.PART_RIGHT_ARM
    )


static func most_fatigued_limb(c: Dictionary) -> String:
    if not enabled() or c.is_empty():
        return BodyPartConstants.PART_RIGHT_ARM
    var best_part: String = BodyPartConstants.PART_RIGHT_ARM
    var best_f: float = -1.0
    for part in tracked_limb_parts():
        var f: float = limb_fatigue(c, part)
        if f > best_f:
            best_f = f
            best_part = part
    return best_part


## Max leg fatigue across both legs — extracted shared helper for all leg-based curves.
static func max_leg_fatigue(c: Dictionary) -> float:
    return maxf(
        limb_fatigue(c, BodyPartConstants.PART_RIGHT_LEG), limb_fatigue(c, BodyPartConstants.PART_LEFT_LEG)
    )


static func _party_short_label(part: String) -> String:
    match part:
        BodyPartConstants.PART_RIGHT_ARM:
            return "R arm"
        BodyPartConstants.PART_LEFT_ARM:
            return "L arm"
        BodyPartConstants.PART_RIGHT_LEG:
            return "R leg"
        BodyPartConstants.PART_LEFT_LEG:
            return "L leg"
        _:
            return part.replace("_", " ")


## Wind-up performance mult from dominant-limb fatigue (1.0 fresh → floor when limb spent).
static func strike_exertion_mult(c: Dictionary, move_id: String, manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var limb: String = dominant_strike_limb(c, manager)
    var fatigue: float = limb_fatigue(c, limb)
    if move_id == CombatConstants.MOVE_ID_HEAVY:
        fatigue = maxf(fatigue, limb_fatigue(c, off_strike_limb(limb)) * CombatConstants.MUSCLE_FATIGUE_HEAVY_OFF_ARM_PENALTY)
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_WIND_UP_PERF_FLOOR, fatigue)


static func apply_attacker_wind_up_mult(
    duration_s: float, attacker: Dictionary, move_id: String, manager: Node = null
) -> float:
    var perf: float = strike_exertion_mult(attacker, move_id, manager)
    if perf >= 0.999:
        return duration_s
    return duration_s / maxf(perf, CombatConstants.MUSCLE_FATIGUE_WIND_UP_PERF_FLOOR)


static func move_exertion_profile_mult(move_id: String) -> float:
    match move_id:
        CombatConstants.MOVE_ID_HEAVY:
            return 1.35
        CombatConstants.MOVE_ID_MEDIUM:
            return 1.0
        CombatConstants.MOVE_ID_QUICK:
            return 0.85
        CombatConstants.MOVE_ID_FEINT:
            return 0.55
        _:
            return 1.0


static func _limb_shares_for_exertion(c: Dictionary, _move_id: String, exertion_kind: String) -> Dictionary:
    var shares: Dictionary = {}
    if exertion_kind == EXERTION_KIND_FORMATION:
        shares[BodyPartConstants.PART_RIGHT_LEG] = 0.5
        shares[BodyPartConstants.PART_LEFT_LEG] = 0.5
        return shares
    var dominant: String = dominant_strike_limb(c)
    if exertion_kind == EXERTION_KIND_PARRY:
        shares[dominant] = 1.0
        return shares
    var weapon = CombatantEntityAccess.get_weapon(c)
    var off_share: float = 0.0
    if WeaponConstants.weapon_is_two_handed(weapon):
        off_share = CombatConstants.MUSCLE_FATIGUE_TWO_HANDED_OFF_ARM_SHARE
    shares[dominant] = 1.0 - off_share
    if off_share > 0.0:
        shares[off_strike_limb(dominant)] = off_share
    return shares


static func apply_exertion_after_breath_spend(
    manager: Node,
    c: Dictionary,
    breath_spent: float,
    move_id: String = "",
    exertion_kind: String = EXERTION_KIND_ATTACK
) -> void:
    if not enabled() or c.is_empty() or breath_spent <= 0.0:
        return
    var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c) if manager != null else null
    seed_combatant_if_enabled(c, entity)
    var pools: Dictionary = c.get(COMBATANT_KEY_MUSCLE_FATIGUE, {})
    if pools is not Dictionary:
        return
    var gain: float = (
        breath_spent * CombatConstants.MUSCLE_FATIGUE_EXERTION_PER_BREATH_POINT * move_exertion_profile_mult(move_id)
    )
    var shares: Dictionary = _limb_shares_for_exertion(c, move_id, exertion_kind)
    for part in shares:
        var cur: float = clampf(float(pools.get(part, 0.0)), 0.0, 1.0)
        pools[part] = clampf(cur + gain * float(shares[part]), 0.0, 1.0)
    c[COMBATANT_KEY_MUSCLE_FATIGUE] = pools


## Formation composure resolve: leg load without breath spend (small fixed tick).
static func apply_formation_exertion(c: Dictionary, move_id: String) -> void:
    if not enabled() or c.is_empty():
        return
    var proxy_breath: float = 8.0
    if move_id == CombatConstants.MOVE_ID_ROTATE_FILE:
        proxy_breath = 10.0
    elif CombatConstants.is_formation_pair_move_kind(move_id):
        proxy_breath = 12.0
    apply_exertion_after_breath_spend(null, c, proxy_breath, move_id, EXERTION_KIND_FORMATION)


static func process_waiting_recovery(c: Dictionary, delta: float) -> void:
    _process_limb_recovery(c, delta, 1.0)


static func process_recovering_recovery(c: Dictionary, delta: float) -> void:
    _process_limb_recovery(c, delta, CombatConstants.MUSCLE_FATIGUE_RECOVERING_RATE_MULT)


static func _process_limb_recovery(c: Dictionary, delta: float, rate_mult: float) -> void:
    if not enabled() or c.is_empty() or delta <= 0.0 or rate_mult <= 0.0:
        return
    var pools: Variant = c.get(COMBATANT_KEY_MUSCLE_FATIGUE)
    if pools is not Dictionary:
        return
    var any: bool = false
    var step: float = CombatConstants.MUSCLE_FATIGUE_RECOVERY_RATE * delta * rate_mult
    for part in tracked_limb_parts():
        var cur: float = clampf(float((pools as Dictionary).get(part, 0.0)), 0.0, 1.0)
        if cur <= 0.0:
            continue
        any = true
        (pools as Dictionary)[part] = maxf(0.0, cur - step)
    if not any:
        return
    c[COMBATANT_KEY_MUSCLE_FATIGUE] = pools


## Step speed mult from leg fatigue (curved power curve with directional asymmetry).
static func step_speed_mult(c: Dictionary, direction: String = "forward") -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f: float = max_leg_fatigue(c)
    var base: float = lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_FORWARD_SPEED_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
    if direction == "retreat":
        return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_RETREAT_SPEED_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))
    if direction == "lateral":
        return base * CombatConstants.MUSCLE_FATIGUE_LATERAL_SPEED_PENALTY
    return base

## Balance / stability mult from leg fatigue.
static func balance_stability_mult(c: Dictionary) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f: float = max_leg_fatigue(c)
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_BALANCE_STABILITY_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))

## Step precision mult from leg fatigue (affects formation alignment).
static func step_precision_mult(c: Dictionary) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f: float = max_leg_fatigue(c)
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_STEP_PRECISION_FLOOR_AT_MAX, pow(leg_f, CombatConstants.MUSCLE_FATIGUE_STEP_SPEED_CURVE_POWER))

## AI / listing: damp strikes when dominant limb is fatigued; heavy moves damp more than quick.
static func offense_weight_mult(c: Dictionary, move_id: String, manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    if (
        move_id == CombatConstants.MOVE_ID_WAIT
        or CombatConstants.is_medical_move(move_id)
        or CombatConstants.is_formation_movement_move(move_id)
    ):
        return 1.0
    var fatigue: float = limb_fatigue(c, dominant_strike_limb(c, manager))
    var effective: float = clampf(fatigue * move_exertion_profile_mult(move_id), 0.0, 1.0)
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_OFFENSE_DAMP_FLOOR, effective)


## AI wait pick: prefer recovery when dominant strike limb is spent.
static func wait_recovery_weight_mult(c: Dictionary, manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var fatigue: float = limb_fatigue(c, dominant_strike_limb(c, manager))
    if fatigue < CombatConstants.MUSCLE_FATIGUE_UI_SHOW_THRESHOLD:
        return 1.0
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_WAIT_RECOVERY_BOOST_TOP, fatigue)


## Formation reposition (rotate/swap): damp when legs are spent.
## Delegates to step_speed_mult + step_precision_mult for graded degradation.
static func formation_movement_weight_mult(c: Dictionary, move_id: String, _manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    if not CombatConstants.is_formation_reposition_move(move_id):
        return 1.0
    return step_speed_mult(c) * step_precision_mult(c)


## Defender parry capacity from dominant-arm fatigue (layers on breath/exhaustion).
static func parry_capacity_mult(c: Dictionary, manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var fatigue: float = limb_fatigue(c, dominant_strike_limb(c, manager))
    return lerpf(1.0, CombatConstants.MUSCLE_FATIGUE_PARRY_CAPACITY_FLOOR, fatigue)


## Defender dodge from leg fatigue (footwork / weight transfer).
## Uses balance_stability_mult() as the graded degradation curve; smooth collapse between 85–100%.
static func dodge_chance_mult(c: Dictionary, _manager: Node = null) -> float:
    if not enabled() or c.is_empty():
        return 1.0
    var leg_f: float = max_leg_fatigue(c)
    var stability: float = balance_stability_mult(c)
    # Smooth collapse transition from 85% → 100% fatigue (no cliff-edge jump).
    if leg_f >= CombatConstants.MUSCLE_FATIGUE_DODGE_COLLAPSE_START:
        var t: float = (leg_f - CombatConstants.MUSCLE_FATIGUE_DODGE_COLLAPSE_START) / (1.0 - CombatConstants.MUSCLE_FATIGUE_DODGE_COLLAPSE_START)
        return lerpf(stability, CombatConstants.MUSCLE_FATIGUE_DODGE_FLAT_FLOOR_AT_MAX, t)
    return stability


static func gauge_suffix_for_limb(c: Dictionary, part: String) -> String:
    if not enabled():
        return ""
    var fatigue: float = limb_fatigue(c, part)
    if fatigue < CombatConstants.MUSCLE_FATIGUE_UI_SHOW_THRESHOLD:
        return ""
    var short: String = part.replace("_", " ")
    return "Msc %s %d%%" % [short, int(roundf(fatigue * 100.0))]


static func gauge_hint_suffix(c: Dictionary, _manager: Node = null) -> String:
    if not enabled() or c.is_empty():
        return ""
    var part: String = most_fatigued_limb(c)
    var line: String = gauge_suffix_for_limb(c, part)
    return (" . " + line) if not line.is_empty() else ""


static func gauge_tooltip_line(c: Dictionary, _manager: Node = null) -> String:
    if not enabled() or c.is_empty():
        return ""
    var part: String = most_fatigued_limb(c)
    var fatigue: float = limb_fatigue(c, part)
    if fatigue < CombatConstants.MUSCLE_FATIGUE_UI_SHOW_THRESHOLD:
        return ""
    return (
        "Muscle fatigue (%s) %d%% — local limb exertion; recovers while waiting."
        % [_party_short_label(part).to_lower(), int(roundf(fatigue * 100.0))]
    )


## Party menu: show persisted worst limb fatigue from last fight (flag-independent read).
static func format_party_limb_fatigue_line(pools: Variant) -> String:
    if pools is not Dictionary:
        return ""
    var max_f: float = 0.0
    var max_part: String = ""
    for part in tracked_limb_parts():
        var f: float = clampf(float((pools as Dictionary).get(part, 0.0)), 0.0, 1.0)
        if f > max_f:
            max_f = f
            max_part = part
    if max_f < CombatConstants.MUSCLE_FATIGUE_UI_SHOW_THRESHOLD:
        return ""
    return "Msc %s %d%%" % [_party_short_label(max_part), int(roundf(max_f * 100.0))]


static func sync_to_entities_from_manager(manager: Node) -> void:
    if not enabled() or manager == null or not ("combatants" in manager):
        return
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var c: Dictionary = raw as Dictionary
        if CombatantEntityAccess.side_str(c) != CombatConstants.SIDE_PLAYER:
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        var entity: Node = CombatantEntityAccess.get_entity_from_manager(manager, c)
        if entity == null or not ("muscle_fatigue" in entity):
            continue
        var pools: Variant = c.get(COMBATANT_KEY_MUSCLE_FATIGUE)
        if pools is Dictionary:
            entity.muscle_fatigue = (pools as Dictionary).duplicate(true)
