extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)

var combatants := []

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine: waiting (gauge filling) -> wind_up (swing) -> recovering (after hit/deflect/miss)
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_RECOVERING := "recovering"

# Timing (seconds). Wind-up and recovery scale with intensity (bigger swing = longer wind-up and recovery).
const WIND_UP_BASE_S := 0.25
const WIND_UP_SCALE_S := 0.6
const RECOVERY_BASE_S := 0.2
const RECOVERY_COMMITMENT_SCALE_S := 0.5
const RECOVERY_EXTRA_HIT_S := 0.0
const RECOVERY_EXTRA_DEFLECTED_S := 0.25
const RECOVERY_EXTRA_MISS_S := 0.5

# Miss chance (0-1). Rolled before damage; miss = no contact, longest recovery.
const MISS_CHANCE_BASE := 0.06
# Deflected = contact but armor absorbed most; final_damage < pre_armor * this ratio.
const DEFLECTED_DAMAGE_RATIO := 0.25

# Intensity (0–1): how committed the swing is. Strength only; drives velocity, wind-up, recovery. Speed only affects gauge fill rate.
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 12.0
const INTENSITY_RANDOM_RANGE := 0.2

# Parry: only available when opponent is winding up on you. Physics: deflect success from defender's parry capacity vs attacker's momentum.
# Attacker momentum = mass * (wind_up_progress * intended_impact_speed). Parry capacity = defender_weapon_mass * typical_parry_speed * (strength/10).
const PARRY_MOMENTUM_FACTOR := 0.5  # deflect success when capacity >= attacker_momentum * this
const V_PARRY_TYPICAL_M_S := 8.0    # typical parry deflection speed (m/s) for capacity

func _read_stats_from(node: Node) -> Dictionary:
	var s := {
		"body_cutting": {},
		"body_blunt": {},
		"body_max": {},
		"bone_health": {},
		"bone_max": {},
		"strength": 1,
		"speed": 100
	}
	if node == null:
		return s
	if "body_cutting" in node:
		s.body_cutting = node.body_cutting.duplicate()
	if "body_blunt" in node:
		s.body_blunt = node.body_blunt.duplicate()
	if "body_max" in node:
		s.body_max = node.body_max.duplicate()
	if "bone_health" in node:
		s.bone_health = node.bone_health.duplicate()
	if "bone_max" in node:
		s.bone_max = node.bone_max.duplicate()
	if "strength" in node:
		s.strength = node.strength
	if "speed" in node:
		s.speed = node.speed
	return s

func register(node: Node, side: String) -> int:
	var id = combatants.size()
	var stats = _read_stats_from(node)
	combatants.append({
		"id": id,
		"node": node,
		"side": side,
		"stats": stats,
		"gauge": 0.0,
		"alive": true,
		"state": STATE_WAITING,
		"state_timer": 0.0,
		"state_duration": 0.0,
		"pending_attack": {}
	})
	return id

func start():
	set_process(true)

func stop():
	set_process(false)

func get_combatants() -> Array:
	var out := []
	for c in combatants:
		var stats = c.stats.duplicate()
		if c.node != null:
			if "body_cutting" in c.node:
				stats.body_cutting = c.node.body_cutting.duplicate()
			if "body_blunt" in c.node:
				stats.body_blunt = c.node.body_blunt.duplicate()
			if "bone_health" in c.node:
				stats.bone_health = c.node.bone_health.duplicate()
			if "bone_max" in c.node:
				stats.bone_max = c.node.bone_max.duplicate()
			if "blood_volume" in c.node:
				stats.blood_volume = c.node.blood_volume
			if c.node.has_method("get_total_bleeding_rate"):
				stats.total_bleeding_rate = c.node.get_total_bleeding_rate()
		if not stats.has("blood_volume"):
			stats.blood_volume = 100.0
		if not stats.has("total_bleeding_rate"):
			stats.total_bleeding_rate = 0.0
		out.append({
			"id": c.id,
			"node": c.node,
			"side": c.side,
			"stats": stats,
			"gauge": c.gauge,
			"alive": c.alive,
			"state": c.get("state", STATE_WAITING),
			"state_timer": c.get("state_timer", 0.0),
			"state_duration": c.get("state_duration", 0.0)
		})
	return out

# Returns who (if any) is in wind_up targeting this defender. Parry moves are only valid when this is non-null.
func _find_attacker_winding_up_on(defender_id: int):
	for c in combatants:
		if not c.alive:
			continue
		if c.state != STATE_WIND_UP:
			continue
		var pa = c.get("pending_attack", {})
		if pa.get("target_id") == defender_id:
			return c
	return null

# Available actions: array of { "target_id": int, "move_id": String }. Parry moves only if someone is winding up on this combatant.
func get_available_actions(combatant_id: int) -> Array:
	var c = _get_by_id(combatant_id)
	if c == null or not c.alive or c.state != STATE_WAITING or c.gauge < 100.0:
		return []
	var weapon = c.node.get_weapon() if (c.node != null and c.node.has_method("get_weapon")) else null
	if weapon == null or not weapon.has_method("get_available_attack_types"):
		return []
	var move_ids: Array = weapon.get_available_attack_types()
	var actions: Array = []
	var attacker_winding_up = _find_attacker_winding_up_on(combatant_id)
	for move_id in move_ids:
		if WeaponConstants.is_parry_move(move_id):
			if attacker_winding_up != null:
				actions.append({ "target_id": attacker_winding_up.id, "move_id": move_id })
		else:
			for opp in combatants:
				if not opp.alive or opp.side == c.side:
					continue
				actions.append({ "target_id": opp.id, "move_id": move_id })
	return actions

func _process(delta: float) -> void:
	# Bleeding and blood loss tick during combat here. Outside combat, they also advance on time (e.g. 1 min per move in main._advance_time_one_minute) for medical realism.
	for c in combatants:
		if not c.alive or c.node == null:
			continue
		if c.node.has_method("process_bleeding"):
			c.node.process_bleeding(delta)
		if c.node.has_method("process_blood_loss"):
			c.node.process_blood_loss(delta)
	for c in combatants:
		if not c.alive or c.node == null:
			continue
		if c.node.has_method("is_dead") and c.node.is_dead():
			c.alive = false
			var death_reason: String = ""
			if c.node.has_method("get_death_reason"):
				death_reason = c.node.get_death_reason()
			print("[Combat] DEATH (tick): %s — %s" % [c.node.name if c.node else "id:%d" % c.id, death_reason])
			emit_signal("action_resolved", c.id, -1, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "bled_out", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
			emit_signal("combat_ended", _check_for_winner(), c.node)
			stop()
			return
	for c in combatants:
		if not c.alive:
			continue
		if c.state == STATE_WAITING:
			var spd: float = float(c.stats.speed)
			if c.node != null and c.node.has_method("get_effective_speed"):
				spd = float(c.node.get_effective_speed())
			c.gauge = min(100.0, c.gauge + spd * delta * 0.5)
			if c.gauge >= 100.0:
				if c.side == "player":
					emit_signal("turn_ready", c.id)
				else:
					var actions: Array = get_available_actions(c.id)
					if actions.is_empty():
						var tgt = _find_first_opponent(c.side)
						if tgt != null:
							_begin_attack_with_target(c.id, tgt.id)
					else:
						var choice = actions[randi() % actions.size()]
						resolve_action(c.id, choice.target_id, choice.get("move_id", ""))
		elif c.state == STATE_WIND_UP:
			c.gauge = 0.0  # Action bar does not fill while swinging
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				_execute_attack(c.id)
		elif c.state == STATE_RECOVERING:
			c.gauge = 0.0  # Action bar does not fill while recovering
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				c.state = STATE_WAITING
				c.gauge = 0.0
				c.state_timer = 0.0
				c.state_duration = 0.0
				c.pending_attack = {}

# Called when player or AI chooses action. move_id optional; if parry move and target is winding up on us, resolve parry; else start attack.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "") -> void:
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	if atk.state != STATE_WAITING or atk.gauge < 100.0:
		return
	if move_id != "" and WeaponConstants.is_parry_move(move_id):
		# Parry: we (attacker_id) are the defender; target_id must be the one winding up on us.
		if tgt.state == STATE_WIND_UP and tgt.get("pending_attack", {}).get("target_id") == attacker_id:
			_resolve_parry(attacker_id, target_id, move_id)
			return
	# Normal attack (or invalid parry — treat as attack with random move)
	_begin_attack_with_target(attacker_id, target_id, move_id)

func _intensity_from_stats(c: Dictionary) -> float:
	var str_val: float = float(c.stats.get("strength", 10))
	var base: float = 0.2 + INTENSITY_STRENGTH_SCALE * (str_val / INTENSITY_STRENGTH_NORM)
	return clampf(base + randf_range(-INTENSITY_RANDOM_RANGE, INTENSITY_RANDOM_RANGE), 0.1, 1.0)

func _wind_up_duration(intensity: float, windup_multiplier: float = 1.0) -> float:
	return (WIND_UP_BASE_S + WIND_UP_SCALE_S * intensity) * maxf(0.5, windup_multiplier)

func _recovery_duration(intensity: float, outcome: String, recovery_multiplier: float = 1.0) -> float:
	var commitment: float = intensity
	var extra: float = RECOVERY_EXTRA_HIT_S
	if outcome == "deflected":
		extra = RECOVERY_EXTRA_DEFLECTED_S
	elif outcome == "miss":
		extra = RECOVERY_EXTRA_MISS_S
	return (RECOVERY_BASE_S + RECOVERY_COMMITMENT_SCALE_S * commitment + extra) * maxf(0.5, recovery_multiplier)

func _begin_attack_with_target(attacker_id: int, target_id: int, move_id: String = "") -> void:
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	var intensity: float = _intensity_from_stats(atk)
	var weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
	var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
	var archetype: Dictionary = WeaponConstants.get_archetype(WeaponConstants.ARCHETYPE_SLASH)
	if weapon != null and weapon.has_method("get_available_attack_types"):
		if move_id != "" and weapon.get_available_attack_types().has(move_id):
			attack_type = move_id
		else:
			var types_arr: Array = weapon.get_available_attack_types()
			var non_parry: Array = []
			for mid in types_arr:
				if not WeaponConstants.is_parry_move(mid):
					non_parry.append(mid)
			if non_parry.is_empty():
				non_parry = types_arr
			if not non_parry.is_empty():
				attack_type = non_parry[randi() % non_parry.size()]
		if weapon.has_method("get_archetype_id"):
			archetype = WeaponConstants.get_archetype(weapon.get_archetype_id(attack_type))
	var windup_mult: float = float(archetype.get("windup_multiplier", 1.0))
	atk.gauge = 0.0
	atk.state = STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = _wind_up_duration(intensity, windup_mult)
	atk.pending_attack = {"target_id": target_id, "intensity": intensity, "attack_type": attack_type, "archetype": archetype}

func _execute_attack(attacker_id: int) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null:
		return
	var pa = atk.pending_attack
	if pa.is_empty():
		atk.state = STATE_WAITING
		atk.gauge = 0.0
		return
	var target_id: int = pa.target_id
	var intensity: float = pa.intensity
	var attack_type: String = pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT)
	var archetype: Dictionary = pa.get("archetype", {})
	var velocity_override: float = pa.get("velocity_m_s", -1.0)
	atk.pending_attack = {}

	var tgt = _get_by_id(target_id)
	if tgt == null or not tgt.alive:
		atk.state = STATE_WAITING
		atk.gauge = 0.0
		return

	var atk_name = atk.node.name if atk.node != null else "id:%d" % attacker_id
	var tgt_name = tgt.node.name if tgt.node != null else "id:%d" % target_id

	# No functional arm -> skip hit, go to recovery
	var recovery_mult_skip: float = float(archetype.get("recovery_multiplier", 1.0))
	if atk.node != null and atk.node.has_method("get_attacking_arm"):
		if atk.node.get_attacking_arm().is_empty():
			print("[Combat] %s has no functional arm; skips attack." % atk_name)
			emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "skip", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = _recovery_duration(intensity, "hit", recovery_mult_skip)
			return

	var targetable: Array = []
	if tgt.node != null and tgt.node.has_method("get_targetable_parts"):
		targetable = tgt.node.get_targetable_parts()
	if targetable.is_empty():
		tgt.alive = false
		emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "defeated", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
		emit_signal("combat_ended", _check_for_winner(), tgt.node)
		stop()
		return

	# Roll miss before damage
	var outcome: String = "hit"
	var recovery_mult: float = float(archetype.get("recovery_multiplier", 1.0))
	if randf() < MISS_CHANCE_BASE:
		outcome = "miss"
		emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": outcome, "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
		atk.state = STATE_RECOVERING
		atk.state_timer = 0.0
		atk.state_duration = _recovery_duration(intensity, outcome, recovery_mult)
		return

	# 1) Choose random body part (weighted by surface area/exposure). Sub-region is then chosen inside take_damage_split relative to this part.
	var part: String = BodyPartConstants.get_weighted_random_part(targetable)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0

	var weapon = null
	if atk.node != null and atk.node.has_method("get_weapon"):
		weapon = atk.node.get_weapon()

	if weapon != null and weapon.has_method("get_available_attack_types"):
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		if velocity_override >= 0.0:
			attack_instance.velocity_m_s = velocity_override
		var arm_mod: float = 1.0
		if atk.node.has_method("get_attack_damage_modifier"):
			arm_mod = atk.node.get_attack_damage_modifier()
		# --- Damage equation (medical/physics debugging) ---
		var v_m_s: float = WeaponDamageHelper.get_effective_velocity_m_s(weapon, attack_instance)
		var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		var mass_kg: float = float(weapon.mass) if (weapon.get("mass") is float or weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
		pre_armor = WeaponDamageHelper.compute_pre_armor_damage(weapon, attack_instance, atk.stats.strength, arm_mod)
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		pre_cut = pre_armor * cut_ratio
		pre_blunt = pre_armor * (1.0 - cut_ratio)
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_SHARP)
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_BLUNT)
		pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
		pen_blunt = pen_blunt_dict.get("penetration_blunt", -1.0)
		var str_mod: float = maxf(0.1, float(atk.stats.strength) / 10.0)
		print("[Damage equation] %s -> %s | v=%.2f m/s, mass=%.2f kg, KE=%.1f J | strength_mod=%.2f arm_mod=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | pen_sharp=%.2f mm RHA pen_blunt=%.2f MPa" % [atk_name, tgt_name, v_m_s, mass_kg, ke_j, str_mod, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp, pen_blunt])
	else:
		var mod: float = 1.0
		if atk.node != null and atk.node.has_method("get_attack_damage_modifier"):
			mod = atk.node.get_attack_damage_modifier()
		pre_armor = float(atk.stats.strength * mod)
		pre_blunt = pre_armor
		pre_cut = 0.0

	# Read both pools before for reporting
	var health_before_cut: int = tgt.node.body_cutting.get(part, 0)
	var health_before_blunt: int = tgt.node.body_blunt.get(part, 0)

	var take_result: Dictionary = {}
	if tgt.node.has_method("take_damage_split"):
		take_result = tgt.node.take_damage_split(pre_cut, pre_blunt, part, pen_sharp, pen_blunt)
	else:
		# Fallback: single stream (pre_cut or pre_blunt by ratio)
		if pre_cut >= pre_blunt and tgt.node.has_method("take_damage"):
			take_result = tgt.node.take_damage(int(roundf(pre_cut)), part, DAMAGE_TYPE_SHARP, pen_sharp, pen_blunt)
			take_result["final_cut"] = take_result.get("final_amount", 0)
			take_result["final_blunt"] = 0
		else:
			take_result = tgt.node.take_damage(int(roundf(pre_blunt)), part, DAMAGE_TYPE_BLUNT, -1.0, pen_blunt)
			take_result["final_cut"] = 0
			take_result["final_blunt"] = take_result.get("final_amount", 0)

	var final_cut: int = take_result.get("final_cut", 0)
	var final_blunt: int = take_result.get("final_blunt", 0)
	var actual_dmg: int = final_cut + final_blunt
	if outcome == "hit" and pre_armor > 0 and float(actual_dmg) < pre_armor * DEFLECTED_DAMAGE_RATIO:
		outcome = "deflected"

	tgt.stats.body_cutting = tgt.node.body_cutting.duplicate()
	tgt.stats.body_blunt = tgt.node.body_blunt.duplicate()

	var health_after_cut: int = tgt.node.body_cutting.get(part, 0)
	var health_after_blunt: int = tgt.node.body_blunt.get(part, 0)
	var part_max: int = tgt.node.body_max.get(part, 0)
	print("[Combat] %s (%s) -> %s (%s) %s: applied cut %d blunt %d (total %d) | part %s: cut %d->%d blunt %d->%d (max %d) [%s]" % [atk_name, atk.side, tgt_name, tgt.side, part, final_cut, final_blunt, actual_dmg, part, health_before_cut, health_after_cut, health_before_blunt, health_after_blunt, part_max, outcome])

	var result_dict := {"dmg": actual_dmg, "died": false, "part": part, "damage_type": "SPLIT", "health_before_cut": health_before_cut, "health_after_cut": health_after_cut, "health_before_blunt": health_before_blunt, "health_after_blunt": health_after_blunt, "final_cut": final_cut, "final_blunt": final_blunt, "outcome": outcome}
	# Legacy keys for UI that expects single pool
	result_dict["health_before"] = health_before_cut + health_before_blunt
	result_dict["health_after"] = health_after_cut + health_after_blunt
	if tgt.node.has_method("is_dead") and tgt.node.is_dead():
		tgt.alive = false
		result_dict.died = true
		var death_reason: String = ""
		if tgt.node.has_method("get_death_reason"):
			death_reason = tgt.node.get_death_reason()
		print("[Combat] DEATH: %s — %s" % [tgt_name, death_reason])
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		emit_signal("combat_ended", _check_for_winner(), tgt.node)
		stop()
		return
	emit_signal("action_resolved", attacker_id, target_id, result_dict)
	atk.state = STATE_RECOVERING
	atk.state_timer = 0.0
	atk.state_duration = _recovery_duration(intensity, outcome, recovery_mult)
	return

# Parry physics: attacker's momentum (mass * velocity at current wind-up progress) vs defender's parry capacity (weapon mass * parry speed * strength). Deflect success = capacity >= momentum * factor.
func _resolve_parry(defender_id: int, attacker_id: int, move_id: String) -> void:
	var defender = _get_by_id(defender_id)
	var attacker = _get_by_id(attacker_id)
	if defender == null or attacker == null or attacker.pending_attack.is_empty():
		return
	var pa = attacker.pending_attack
	var progress: float = clampf(attacker.state_timer / maxf(0.001, attacker.state_duration), 0.0, 1.0)
	var attack_instance = AttackInstance.new(pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT), pa.get("intensity", 0.5))
	attack_instance.archetype = pa.get("archetype", {})
	var attacker_weapon = attacker.node.get_weapon() if (attacker.node != null and attacker.node.has_method("get_weapon")) else null
	if attacker_weapon == null:
		_begin_attack_with_target(defender_id, attacker_id, move_id)
		return
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
	var v_current: float = v_intent * progress
	var m_a: float = float(attacker_weapon.mass)
	var p_a: float = m_a * v_current
	var defender_weapon = defender.node.get_weapon() if (defender.node != null and defender.node.has_method("get_weapon")) else null
	var m_d: float = float(defender_weapon.mass) if defender_weapon else WeaponConstants.BASELINE_MASS_KG
	var s_d: float = float(defender.stats.get("strength", 10))
	var c_d: float = m_d * V_PARRY_TYPICAL_M_S * (s_d / 10.0)
	var success_chance: float = clampf(c_d / (p_a * PARRY_MOMENTUM_FACTOR + 0.001), 0.0, 1.0)
	var deflected: bool = randf() < success_chance
	if not deflected:
		# Opponent's attack still executes, but velocity reduced by how much the parry opposed it (momentum C_d absorbed).
		var v_reduced: float = v_intent - (c_d / m_a)
		var v_min: float = v_intent * 0.2
		attacker.pending_attack["velocity_m_s"] = maxf(v_reduced, v_min)
		_execute_attack(attacker_id)
		return
	var recovery_mult: float = float(pa.get("archetype", {}).get("recovery_multiplier", 1.0))
	attacker.pending_attack = {}
	attacker.state = STATE_RECOVERING
	attacker.state_timer = 0.0
	attacker.state_duration = _recovery_duration(pa.get("intensity", 0.5), "miss", recovery_mult)
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	var atk_name: String = attacker.node.name if attacker.node != null else "id:%d" % attacker_id
	print("[Combat] %s parried %s's attack (momentum %.1f vs capacity %.1f)." % [def_name, atk_name, p_a, c_d])
	emit_signal("action_resolved", defender_id, attacker_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "parry_deflect", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	_begin_attack_with_target(defender_id, attacker_id, move_id)

func _get_by_id(id: int):
	for c in combatants:
		if c.id == id:
			return c
	return null

func _find_first_opponent(side: String):
	for c in combatants:
		if not c.alive:
			continue
		if c.side != side:
			return c
	return null

func _check_for_winner() -> String:
	var sides := {}
	for c in combatants:
		if c.alive:
			sides[c.side] = true
	if sides.size() == 1:
		for k in sides.keys():
			return k
	return ""
