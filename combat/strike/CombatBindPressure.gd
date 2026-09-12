## Bind pressure / control meter: continuous spectrum (none/light/medium/hard).
## Sets pressure after bind outcomes, decays over time, affects defense and contest power.
## A1: Phase 3 — full state derivation, partner tracking, control side.
class_name CombatBindPressure
extends RefCounted


## V5 HEMA realism: blade feel (Waffenfühlen) — Perception and Intelligence scale bind contest power.

static func blade_feel_atk_mult_full(perc: float, int_val: float) -> float:
    return 1.0 + CombatConstants.BLADE_FEEL_PERC_SCALE * ((perc / 100.0) + CombatConstants.BLADE_FEEL_INT_SCALE * (int_val / 100.0))


static func blade_feel_atk_mult(perc: float) -> float:
    return 1.0 + CombatConstants.BLADE_FEEL_PERC_SCALE * (perc / 100.0)


static func blade_feel_resist_mult(perc: float) -> float:
    return 1.0 + CombatConstants.BLADE_FEEL_RESIST_PERC_SCALE * (perc / 100.0)


## Derive bind state name from pressure value.
static func state_from_pressure(pressure: float) -> String:
    if pressure < CombatConstants.BIND_STATE_LIGHT_THRESHOLD:
        return "none"
    if pressure < CombatConstants.BIND_STATE_MEDIUM_THRESHOLD:
        return "light"
    if pressure < CombatConstants.BIND_STATE_HARD_THRESHOLD:
        return "medium"
    return "hard"


## Return numeric pressure level 0..3 (none=0, light=1, medium=2, hard=3).
static func get_pressure_level(c: Dictionary, clock: float) -> int:
    if c.is_empty():
        return 0
    var until: float = float(c.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return 0
    var val: float = float(c.get(DataKeys.BIND_PRESSURE_VALUE, 0.0))
    match state_from_pressure(val):
        "light":
            return 1
        "medium":
            return 2
        "hard":
            return 3
    return 0


## HEMA: the stronger the live bind, the more the binder controls the follow-through strike.
## Consumes get_pressure_level so a hard bind pays out a bigger edge than a light one.
## Returns 1.0 when there is no active bind; otherwise interpolates between
## BIND_FOLLOW_THROUGH_DMG_MIN_MULT (light) and BIND_FOLLOW_THROUGH_DMG_MULT (hard).
static func follow_through_dmg_mult(c: Dictionary, clock: float) -> float:
    var level: int = get_pressure_level(c, clock)
    if level <= 0:
        return 1.0
    return lerpf(
        CombatConstants.BIND_FOLLOW_THROUGH_DMG_MIN_MULT,
        CombatConstants.BIND_FOLLOW_THROUGH_DMG_MULT,
        (level - 1) / CombatConstants.BIND_FOLLOW_THROUGH_LEVEL_SPAN
    )


## Get current bind state string for a combatant.
static func get_bind_state(c: Dictionary, clock: float) -> String:
    if c.is_empty():
        return "none"
    var until: float = float(c.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return "none"
    var val: float = float(c.get(DataKeys.BIND_PRESSURE_VALUE, 0.0))
    return state_from_pressure(val)


## Check if combatant has an active bind partner.
static func is_in_bind(c: Dictionary, clock: float) -> bool:
    var until: float = float(c.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return false
    var pid: int = int(c.get(DataKeys.BIND_PARTNER_ID, -1))
    return pid >= 0


## Get bind partner id (-1 if none).
static func get_bind_partner_id(c: Dictionary) -> int:
    return int(c.get(DataKeys.BIND_PARTNER_ID, -1))


## HEMA: true if a bind-to-wrestle transition is currently available — sustained hard bind pressure
## has fatigued the opponent's blade control enough that a body grab can land. Set/cleared in
## apply_decay; consumed by resolve_bind_wrestle.
static func has_wrestling_available(c: Dictionary) -> bool:
    if c.is_empty():
        return false
    return c.has(DataKeys.BIND_WRESTLING_AVAILABLE)


## Set pressure after a parry-to-bind (passive path from AttackResultApplier).
## control is the clash control value 0..1.
static func set_after_parry_bind(target: Dictionary, manager: Node, attacker_id: int, control: float) -> void:
    if target.is_empty() or manager == null:
        return
    var pressure: float = clampf((control - CombatConstants.PARRY_BIND_CONTROL_THRESHOLD) / (1.0 - CombatConstants.PARRY_BIND_CONTROL_THRESHOLD), 0.2, 0.8)
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    target[DataKeys.BIND_PRESSURE_VALUE] = pressure
    target[DataKeys.BIND_PRESSURE_UNTIL] = clock + CombatConstants.BIND_PRESSURE_DURATION_S
    target[DataKeys.BIND_PARTNER_ID] = attacker_id
    ## A1: control side — winner of parry bind takes inside line.
    var guard_line: String = str(target.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
    match guard_line:
        "high_left", "low_left":
            target[DataKeys.BIND_CONTROL_SIDE] = DataKeys.BIND_SIDE_LEFT
        "high_right", "low_right":
            target[DataKeys.BIND_CONTROL_SIDE] = DataKeys.BIND_SIDE_RIGHT
        _:
            target[DataKeys.BIND_CONTROL_SIDE] = DataKeys.BIND_SIDE_CENTRE


## Apply decay during waiting state processing. Reduces pressure over time.
## Also clears bind when partner is no longer at CLOSE distance (formation shuffle, death, flee).
## Progressive leverage degradation: prolonged binds cause blade fatigue — pressure decays faster after grace period.
static func apply_decay(combatant: Dictionary, manager: Node, delta: float) -> void:
    if combatant.is_empty():
        return
    var until: float = float(combatant.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or manager == null:
        return
    var now: float = CombatantEntityAccess.combat_clock_float(manager)
    if now >= until:
        _clear_bind_state(combatant)
        return
    var pid: int = get_bind_partner_id(combatant)
    if pid >= 0 and manager != null:
        var partner: Dictionary = CombatantEntityAccess.manager_get_combatant_optional(manager, pid)
        if partner.is_empty() or not CombatantEntityAccess.alive_bool(partner):
            _clear_bind_state(combatant)
            return
        var band: String = CombatantEntityAccess.distance_to_opponent_band(combatant, pid)
        if band != CombatConstants.DISTANCE_CLOSE:
            _clear_bind_state(combatant)
            return
    var val: float = float(combatant.get(DataKeys.BIND_PRESSURE_VALUE, 0.0))
    # Progressive leverage degradation: after grace period of sustained bind, blade fatigue accelerates decay.
    var base_decay: float = CombatConstants.BIND_PRESSURE_DECAY_RATE * delta
    var bind_start: float = until - CombatConstants.BIND_PRESSURE_DURATION_S
    var elapsed_sustained: float = (now - bind_start) - CombatConstants.BIND_LEVERAGE_GRACE_PERIOD_S
    if elapsed_sustained > 0.0 and val >= CombatConstants.BIND_STATE_MEDIUM_THRESHOLD:
        # Accelerated decay from leverage loss — pressure drops faster as muscles fatigue.
        var accelerated_decay: float = base_decay * CombatConstants.BIND_PROGRESSIVE_LEVERAGE_DECAY_MULT
        val -= accelerated_decay
    else:
        val -= base_decay
    # Check for wrestling transition opportunity — high sustained pressure means blade is locked but opponent is tiring.
    if val >= CombatConstants.BIND_WRESTLING_TRANSITION_THRESHOLD and not combatant.has(DataKeys.BIND_WRESTLING_AVAILABLE):
        combatant[DataKeys.BIND_WRESTLING_AVAILABLE] = true
    # Clear wrestling flag if pressure dropped below threshold.
    if val < CombatConstants.BIND_STATE_HARD_THRESHOLD:
        combatant.erase(DataKeys.BIND_WRESTLING_AVAILABLE)
    if val <= 0.0:
        _clear_bind_state(combatant)
    else:
        combatant[DataKeys.BIND_PRESSURE_VALUE] = val


## NOTE: `defender_parry_cap_mult` / `defender_dodge_chance_mult` were removed (dead + inverted). Bind pressure is
## stored on the WINNER of the bind, so reading a combatant's own pressure to reduce THEIR defense was backwards —
## it would have penalized the binder for their own control. A correct "pressed-defender" penalty needs the
## opponent's pressure value, which these signatures did not have.


## HEMA bind pressure (Waffenfühlen): a pressed defender's parry capacity degrades — the opponent's blade
## pressure reduces the defender's ability to maintain guard position and react. Reads the OPPONENT's pressure,
## not the defender's (the original was inverted and removed). Linear map from 1.0 (no pressure) to
## BIND_PRESSURE_DEFENDER_PARRY_CAP_FLOOR (maximum pressure).
static func defender_parry_cap_mult(opponent: Dictionary, clock: float) -> float:
    if opponent.is_empty():
        return 1.0
    var until: float = float(opponent.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return 1.0
    var val: float = float(opponent.get(DataKeys.BIND_PRESSURE_VALUE, 0.0))
    return lerpf(1.0, CombatConstantsParry.BIND_PRESSURE_DEFENDER_PARRY_CAP_FLOOR, val)


## Contest power multiplier: existing pressure improves bind contest odds.
static func contest_power_mult(combatant: Dictionary, clock: float) -> float:
    if combatant.is_empty():
        return 1.0
    var until: float = float(combatant.get(DataKeys.BIND_PRESSURE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return 1.0
    var val: float = float(combatant.get(DataKeys.BIND_PRESSURE_VALUE, 0.0))
    match state_from_pressure(val):
        "light":
            return 1.05
        "medium":
            return 1.15
        "hard":
            return 1.3
    return 1.0


## Resolve bind_press: contested attempt to maintain/increase pressure.
static func resolve_bind_press(manager: Node, attacker_id: int, target_id: int) -> void:
    if manager == null:
        return
    if MedicalPhaseController.combat_resolution_blocked(manager):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_failed", "dmg": 0, "died": false, "reason": "medical_blocked"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty() or not CombatantEntityAccess.are_alive_opponents(atk, tgt):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_failed", "dmg": 0, "died": false, "reason": "target_invalid"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if band != CombatConstants.DISTANCE_CLOSE:
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_failed", "dmg": 0, "died": false, "reason": "not_close"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if not is_in_bind(atk, clock):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_failed", "dmg": 0, "died": false, "reason": "no_active_bind"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_skill: float = float(atk_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var atk_str: float = float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_skill: float = float(tgt_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_str: float = float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var atk_power: float = atk_skill * 2.0 + atk_str
    var tgt_power: float = tgt_skill * 2.0 + tgt_str
    # V5 HEMA realism: Perception and Intelligence scale blade feel (Waffenfühlen) in bind contests.
    var atk_perc_bp: float = float(atk_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var atk_int_bp: float = float(atk_stats.get(DataKeys.ENTITY_INTELLIGENCE, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_perc_bp: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var atk_blade_feel_mult: float = blade_feel_atk_mult_full(atk_perc_bp, atk_int_bp)
    var tgt_resist_mult: float = blade_feel_resist_mult(tgt_perc_bp)
    atk_power *= atk_blade_feel_mult
    tgt_power *= tgt_resist_mult
    atk_power *= contest_power_mult(atk, clock)
    var roll: float = randf()
    var atk_chance: float = atk_power / maxf(1.0, atk_power + tgt_power)
    var breath: float = CombatantEntityAccess.breath_float(atk)
    atk[DataKeys.COMBATANT_BREATH] = maxf(0.0, breath - CombatConstants.BREATH_BIND_PRESS_COST)
    atk[DataKeys.COMBATANT_STAMINA] = atk[DataKeys.COMBATANT_BREATH]
    if roll < atk_chance:
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) + 0.15, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        atk[DataKeys.BIND_PRESSURE_UNTIL] = clock + CombatConstants.BIND_PRESSURE_DURATION_S
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_success", "dmg": 0, "died": false, "pressure": val}
        )
    else:
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) - 0.1, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        if val < CombatConstants.BIND_STATE_LIGHT_THRESHOLD:
            _clear_bind_state(atk)
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_press_failed", "dmg": 0, "died": false, "pressure": val}
        )
    atk[DataKeys.BIND_ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.BIND_ACTION_COOLDOWN_S
    atk[DataKeys.ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
    _schedule_ready(manager, attacker_id)


## Resolve bind_void: slip offline to create opening, clear bind, gain angular advantage.
static func resolve_bind_void(manager: Node, attacker_id: int, target_id: int) -> void:
    if manager == null:
        return
    if MedicalPhaseController.combat_resolution_blocked(manager):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_void_failed", "dmg": 0, "died": false, "reason": "medical_blocked"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty() or not CombatantEntityAccess.are_alive_opponents(atk, tgt):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_void_failed", "dmg": 0, "died": false, "reason": "target_invalid"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if band != CombatConstants.DISTANCE_CLOSE:
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_void_failed", "dmg": 0, "died": false, "reason": "not_close"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if not is_in_bind(atk, clock):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_void_failed", "dmg": 0, "died": false, "reason": "no_active_bind"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_agi: float = float(atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_skill: float = float(tgt_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var void_power: float = atk_agi * 2.0 + float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var hold_power: float = tgt_skill * 2.0 + float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    # V5 HEMA realism: Perception scales blade feel (Waffenfühlen) in bind contests.
    var atk_perc_v: float = float(atk_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_perc_v: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    void_power *= blade_feel_atk_mult(atk_perc_v)
    hold_power *= blade_feel_resist_mult(tgt_perc_v)
    var void_chance: float = void_power / maxf(1.0, void_power + hold_power)
    var breath: float = CombatantEntityAccess.breath_float(atk)
    atk[DataKeys.COMBATANT_BREATH] = maxf(0.0, breath - CombatConstants.BREATH_BIND_VOID_COST)
    atk[DataKeys.COMBATANT_STAMINA] = atk[DataKeys.COMBATANT_BREATH]
    if randf() < void_chance:
        _clear_bind_state(atk)
        var loa: float = atk.get(DataKeys.BIND_LANE_OFFSET, 0.0)
        var side: String = str(atk.get(DataKeys.BIND_CONTROL_SIDE, DataKeys.BIND_SIDE_CENTRE))
        if side == DataKeys.BIND_SIDE_RIGHT:
            loa -= CombatConstants.LATERAL_STEP_DELTA
        else:
            loa += CombatConstants.LATERAL_STEP_DELTA
        atk[DataKeys.BIND_LANE_OFFSET] = clampf(loa, -CombatConstants.LANE_OFFSET_ABS_MAX, CombatConstants.LANE_OFFSET_ABS_MAX)
        ## B3: angular advantage from void — stepping outside closes opponent's strong side.
        atk[DataKeys.BIND_ANGULAR_ADVANTAGE_UNTIL] = clock + CombatConstants.ANGULAR_ADVANTAGE_DURATION_S
        atk[DataKeys.BIND_ANGULAR_ADVANTAGE_TARGET_ID] = target_id
        manager.emit_signal(
            "action_resolved", attacker_id, target_id, {"outcome": "bind_void_success", "dmg": 0, "died": false}
        )
    else:
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) - 0.15, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        if val < CombatConstants.BIND_STATE_LIGHT_THRESHOLD:
            _clear_bind_state(atk)
        manager.emit_signal(
            "action_resolved", attacker_id, target_id, {"outcome": "bind_void_failed", "dmg": 0, "died": false}
        )
    atk[DataKeys.BIND_ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.BIND_ACTION_COOLDOWN_S
    atk[DataKeys.ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
    _schedule_ready(manager, attacker_id)


## Resolve bind_wind: rotate to take inside/outside of opponent's blade. Contested.
static func resolve_bind_wind(manager: Node, attacker_id: int, target_id: int) -> void:
    if manager == null:
        return
    if MedicalPhaseController.combat_resolution_blocked(manager):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_wind_failed", "dmg": 0, "died": false, "reason": "medical_blocked"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty() or not CombatantEntityAccess.are_alive_opponents(atk, tgt):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_wind_failed", "dmg": 0, "died": false, "reason": "target_invalid"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if band != CombatConstants.DISTANCE_CLOSE:
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_wind_failed", "dmg": 0, "died": false, "reason": "not_close"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if not is_in_bind(atk, clock):
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_wind_failed", "dmg": 0, "died": false, "reason": "no_active_bind"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_skill: float = float(atk_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_skill: float = float(tgt_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var wind_power: float = atk_skill * 3.0 + float(atk_stats.get(DataKeys.ENTITY_AGILITY, CombatConstants.DEFAULT_STAT_VALUE))
    var hold_power: float = tgt_skill * 3.0 + float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    # V5 HEMA realism: Perception scales blade feel (Waffenfühlen) in bind contests.
    var atk_perc_w: float = float(atk_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_perc_w: float = float(tgt_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
    wind_power *= blade_feel_atk_mult(atk_perc_w)
    hold_power *= blade_feel_resist_mult(tgt_perc_w)
    var wind_chance: float = wind_power / maxf(1.0, wind_power + hold_power)
    var breath: float = CombatantEntityAccess.breath_float(atk)
    atk[DataKeys.COMBATANT_BREATH] = maxf(0.0, breath - CombatConstants.BREATH_BIND_WIND_COST)
    atk[DataKeys.COMBATANT_STAMINA] = atk[DataKeys.COMBATANT_BREATH]
    if randf() < wind_chance:
        var cur_side: String = str(atk.get(DataKeys.BIND_CONTROL_SIDE, DataKeys.BIND_SIDE_CENTRE))
        var new_side: String = DataKeys.BIND_SIDE_RIGHT if cur_side == DataKeys.BIND_SIDE_LEFT else DataKeys.BIND_SIDE_LEFT
        atk[DataKeys.BIND_CONTROL_SIDE] = new_side
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) + 0.1, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        atk[DataKeys.BIND_PRESSURE_UNTIL] = clock + CombatConstants.BIND_PRESSURE_DURATION_S
        manager.emit_signal(
            "action_resolved",
            attacker_id,
            target_id,
            {"outcome": "bind_wind_success", "dmg": 0, "died": false, "control_side": new_side}
        )
    else:
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) - 0.2, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        if val < CombatConstants.BIND_STATE_LIGHT_THRESHOLD:
            _clear_bind_state(atk)
        manager.emit_signal(
            "action_resolved", attacker_id, target_id, {"outcome": "bind_wind_failed", "dmg": 0, "died": false}
        )
    atk[DataKeys.BIND_ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.BIND_ACTION_COOLDOWN_S
    atk[DataKeys.ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
    _schedule_ready(manager, attacker_id)


## Resolve bind_wrestle: the bind-to-wrestling transition. Only available when sustained hard bind
## pressure has fatigued the opponent's blade control (BIND_WRESTLING_AVAILABLE). Contested grab:
## on success the target is unbalanced (strong off-balance window) and the binder's bind ends
## (control achieved); on failure the binder loses pressure and the bind may break.
static func resolve_bind_wrestle(manager: Node, attacker_id: int, target_id: int) -> void:
    if manager == null:
        return
    if MedicalPhaseController.combat_resolution_blocked(manager):
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_failed", "dmg": 0, "died": false, "reason": "medical_blocked"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty() or not CombatantEntityAccess.are_alive_opponents(atk, tgt):
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_failed", "dmg": 0, "died": false, "reason": "target_invalid"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if band != CombatConstants.DISTANCE_CLOSE:
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_failed", "dmg": 0, "died": false, "reason": "not_close"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if not is_in_bind(atk, clock) or not has_wrestling_available(atk):
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_failed", "dmg": 0, "died": false, "reason": "no_wrestling_available"}
        )
        _schedule_ready(manager, attacker_id)
        return
    var atk_stats := CombatantEntityAccess.stats_dict(atk)
    var tgt_stats := CombatantEntityAccess.stats_dict(tgt)
    var atk_skill: float = float(atk_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var atk_str: float = float(atk_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_skill: float = float(tgt_stats.get(DataKeys.ENTITY_MELEE_SKILL, CombatConstants.DEFAULT_STAT_VALUE))
    var tgt_str: float = float(tgt_stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE))
    # Contested grab: the binder's strength + skill vs the target's skill + strength.
    # Sustained pressure gives the binder a leverage edge (they've been working the bind).
    var atk_power: float = atk_skill * 2.0 + atk_str
    var tgt_power: float = tgt_skill * 2.0 + tgt_str
    atk_power *= contest_power_mult(atk, clock)
    var grab_chance: float = atk_power / maxf(1.0, atk_power + tgt_power)
    var breath: float = CombatantEntityAccess.breath_float(atk)
    atk[DataKeys.COMBATANT_BREATH] = maxf(0.0, breath - CombatConstants.BREATH_BIND_PRESS_COST)
    atk[DataKeys.COMBATANT_STAMINA] = atk[DataKeys.COMBATANT_BREATH]
    if randf() < grab_chance:
        # Success: the grab lands. The target is unbalanced (strong off-balance window) and the
        # binder's bind ends — control has been achieved, the blade bind is over.
        tgt[DataKeys.PA_OFF_BALANCE_UNTIL] = clock + CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S
        _clear_bind_state(atk)
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_success", "dmg": 0, "died": false, "off_balance_s": CombatConstants.BIND_WRESTLE_TARGET_OFF_BALANCE_S}
        )
    else:
        # Failure: the grab slips. The binder loses pressure and the bind may break.
        var val: float = clampf(float(atk.get(DataKeys.BIND_PRESSURE_VALUE, 0.3)) - 0.2, 0.0, 1.0)
        atk[DataKeys.BIND_PRESSURE_VALUE] = val
        if val < CombatConstants.BIND_STATE_LIGHT_THRESHOLD:
            _clear_bind_state(atk)
        manager.emit_signal(
            "action_resolved", attacker_id, target_id,
            {"outcome": "bind_wrestle_failed", "dmg": 0, "died": false, "pressure": val}
        )
    atk[DataKeys.BIND_ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.BIND_ACTION_COOLDOWN_S
    atk[DataKeys.ACTION_COOLDOWN_UNTIL] = clock + CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S
    _schedule_ready(manager, attacker_id)


## HEMA B3: true if the voider still holds an active angular advantage over a specific target.
## The advantage is only valid against the opponent they voided from — voiding outside the right
## shoulder does not give the same positional bonus against a third combatant on the other side.
static func has_angular_advantage_over(c: Dictionary, target_id: int, clock: float) -> bool:
    if c.is_empty() or target_id < 0:
        return false
    var until: float = float(c.get(DataKeys.BIND_ANGULAR_ADVANTAGE_UNTIL, -1.0))
    if until < 0.0 or clock >= until:
        return false
    var tid: int = int(c.get(DataKeys.BIND_ANGULAR_ADVANTAGE_TARGET_ID, -1))
    return tid == target_id


static func _clear_bind_state(c: Dictionary) -> void:
    c[DataKeys.BIND_PRESSURE_VALUE] = 0.0
    c[DataKeys.BIND_PRESSURE_UNTIL] = -1.0
    c[DataKeys.BIND_PARTNER_ID] = -1
    c[DataKeys.BIND_CONTROL_SIDE] = DataKeys.BIND_SIDE_CENTRE
    c.erase(DataKeys.BIND_WRESTLING_AVAILABLE)


static func _schedule_ready(manager: Node, combatant_id: int) -> void:
    CombatEventScheduler.schedule_action_ready(manager, combatant_id, CombatConstants.READY_DELAY_CLOSE_ATTEMPT_S)



