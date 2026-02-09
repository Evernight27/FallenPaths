extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)

var combatants := []

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine: waiting (gauge filling) -> wind_up (swing) | medical_wind_up (applying medical) -> recovering (after hit/deflect/miss/medical)
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_MEDICAL_WIND_UP := "medical_wind_up"
const STATE_RECOVERING := "recovering"

# Power and follow_through (0.2–1.0 each): rolled per attack; intensity = (0.5+0.5*power)*(0.5+0.5*follow_through) drives velocity, wind-up, and recovery.
const POWER_MIN := 0.2
const POWER_MAX := 1.0
const FOLLOW_THROUGH_MIN := 0.2
const FOLLOW_THROUGH_MAX := 1.0
const INTENSITY_MIN := 0.2  # floor so weak attacks still have some commitment

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

# Intensity (0–1): derived from power and follow_through per attack; drives velocity, wind-up, recovery. Strength can bias power/follow_through later; for now both rolled.
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 12.0
const INTENSITY_RANDOM_RANGE := 0.2
const RECOVERY_AFTER_MEDICAL_S := 0.5  # short recovery after applying bandage/tourniquet/direct pressure

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

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Parry moves only if someone is winding up on this combatant. Medical moves (bandage_self, apply_direct_pressure, apply_tourniquet) when self has wounds.
func get_available_actions(combatant_id: int) -> Array:
	var c = _get_by_id(combatant_id)
	if c == null or not c.alive or c.state != STATE_WAITING or c.gauge < 100.0:
		return []
	if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
		return []
	var actions: Array = []
	var weapon = c.node.get_weapon() if (c.node != null and c.node.has_method("get_weapon")) else null
	if weapon != null and weapon.has_method("get_available_attack_types"):
		var move_ids: Array = weapon.get_available_attack_types()
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
	# Medical actions (self only): bandage, direct pressure, tourniquet on wounded parts
	if c.node != null and c.node.has_method("get_wounded_parts"):
		var wounded: Array = c.node.get_wounded_parts()
		for part in wounded:
			if part.is_empty():
				continue
			actions.append({ "target_id": combatant_id, "move_id": "bandage_self", "target_part": part })
			if c.node.has_method("can_apply_direct_pressure") and c.node.can_apply_direct_pressure(part) and c.node.has_method("is_applying_direct_pressure") and not c.node.is_applying_direct_pressure():
				actions.append({ "target_id": combatant_id, "move_id": "apply_direct_pressure", "target_part": part })
			if c.node.has_method("can_apply_tourniquet") and c.node.can_apply_tourniquet(part):
				actions.append({ "target_id": combatant_id, "move_id": "apply_tourniquet", "target_part": part })
	var medical_count: int = 0
	for a in actions:
		var mid: String = a.get("move_id", "")
		if mid == "bandage_self" or mid == "apply_direct_pressure" or mid == "apply_tourniquet":
			medical_count += 1
	if medical_count > 0:
		print("[Combat] get_available_actions: combatant_id=%d => %d total (%d medical: bandage/direct_pressure/tourniquet)" % [combatant_id, actions.size(), medical_count])
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
	var winner: String = _check_for_winner()
	if not winner.is_empty():
		emit_signal("combat_ended", winner, null)
		stop()
		return
	for c in combatants:
		if not c.alive:
			continue
		if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
			continue  # incapacitated: no gauge fill, cannot act
		if c.state == STATE_WAITING:
			var spd: float = float(c.stats.speed)
			if c.node != null and c.node.has_method("get_effective_speed"):
				spd = float(c.node.get_effective_speed())
			var fill_rate: float = spd * delta * 0.5
			if c.node != null and c.node.has_method("get_performance_modifier"):
				fill_rate *= c.node.get_performance_modifier()
			c.gauge = min(100.0, c.gauge + fill_rate)
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
						var opts: Dictionary = {}
						if choice.get("target_part", "") != "":
							opts["target_part"] = choice.target_part
						resolve_action(c.id, choice.target_id, choice.get("move_id", ""), opts)
		elif c.state == STATE_WIND_UP:
			c.gauge = 0.0  # Action bar does not fill while swinging
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				_execute_attack(c.id)
		elif c.state == STATE_MEDICAL_WIND_UP:
			c.gauge = 0.0
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				var pm = c.get("pending_medical", {})
				c.pending_medical = {}
				var med_id: String = pm.get("medical_id", "")
				var part: String = pm.get("target_part", "")
				var tgt_cid: int = pm.get("target_combatant_id", c.id)
				var tgt_c = _get_by_id(tgt_cid)
				var who_m: String = c.node.name if c.node != null else "id:%d" % c.id
				if tgt_c != null and tgt_c.node != null and not part.is_empty():
					if med_id == "bandage_self" and tgt_c.node.has_method("apply_bandage"):
						tgt_c.node.apply_bandage(part)
						print("[Combat] Medical complete: %s bandaged %s => recovery %.1fs" % [who_m, part, RECOVERY_AFTER_MEDICAL_S])
						emit_signal("action_resolved", c.id, tgt_cid, {"outcome": "bandaged", "part": part, "dmg": 0, "died": false})
					elif med_id == "apply_tourniquet" and tgt_c.node.has_method("apply_tourniquet"):
						if tgt_c.node.apply_tourniquet(part):
							print("[Combat] Medical complete: %s applied tourniquet on %s => recovery %.1fs" % [who_m, part, RECOVERY_AFTER_MEDICAL_S])
							emit_signal("action_resolved", c.id, tgt_cid, {"outcome": "tourniquet_applied", "part": part, "dmg": 0, "died": false})
				c.state = STATE_RECOVERING
				c.state_timer = 0.0
				c.state_duration = RECOVERY_AFTER_MEDICAL_S
		elif c.state == STATE_RECOVERING:
			c.gauge = 0.0  # Action bar does not fill while recovering
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				c.state = STATE_WAITING
				c.gauge = 0.0
				c.state_timer = 0.0
				c.state_duration = 0.0
				c.pending_attack = {}

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null or atk.state != STATE_WAITING or atk.gauge < 100.0:
		return
	# Medical actions (target_id = combatant to apply on, usually self)
	if move_id == "bandage_self" or move_id == "apply_direct_pressure" or move_id == "apply_tourniquet":
		var part: String = str(options.get("target_part", ""))
		var who: String = atk.node.name if (atk.node != null) else "id:%d" % attacker_id
		print("[Combat] Action: %s chose medical %s on part=%s (target_combatant_id=%d)" % [who, move_id, part, target_id])
		_start_medical_action(attacker_id, target_id, move_id, part)
		return
	var tgt = _get_by_id(target_id)
	if tgt == null or not tgt.alive:
		return
	if move_id != "" and WeaponConstants.is_parry_move(move_id):
		if tgt.state == STATE_WIND_UP and tgt.get("pending_attack", {}).get("target_id") == attacker_id:
			if atk.node != null and atk.node.has_method("clear_direct_pressure"):
				atk.node.clear_direct_pressure()
			_resolve_parry(attacker_id, target_id, move_id)
			return
	# Normal attack: clear direct pressure (new action), then start attack
	if atk.node != null and atk.node.has_method("clear_direct_pressure"):
		if atk.node.has_method("is_applying_direct_pressure") and atk.node.is_applying_direct_pressure():
			print("[Combat] %s taking another action => clear_direct_pressure (was holding %s)" % [atk.node.name if atk.node else "id:%d" % attacker_id, atk.node.get_direct_pressure_part() if atk.node.has_method("get_direct_pressure_part") else "?"])
		atk.node.clear_direct_pressure()
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

func _start_medical_action(combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String) -> void:
	var c = _get_by_id(combatant_id)
	var target_node = _get_by_id(target_combatant_id)
	if c == null or target_node == null or target_node.node == null:
		return
	var duration: float = 0.0
	var who_name: String = c.node.name if (c.node != null) else "id:%d" % combatant_id
	if medical_id == "apply_direct_pressure":
		# Instant: apply now, then short recovery
		if target_node.node.has_method("apply_direct_pressure") and target_node.node.apply_direct_pressure(target_part):
			print("[Combat] Medical: %s applied direct_pressure on %s (instant) => recovery %.1fs" % [who_name, target_part, RECOVERY_AFTER_MEDICAL_S])
			emit_signal("action_resolved", combatant_id, target_combatant_id, {"outcome": "direct_pressure", "part": target_part, "dmg": 0, "died": false})
		c.gauge = 0.0
		c.state = STATE_RECOVERING
		c.state_timer = 0.0
		c.state_duration = RECOVERY_AFTER_MEDICAL_S
		return
	if medical_id == "bandage_self":
		duration = target_node.node.get_bandage_application_time_seconds() if target_node.node.has_method("get_bandage_application_time_seconds") else 4.0
	elif medical_id == "apply_tourniquet":
		duration = target_node.node.get_tourniquet_application_time_seconds() if target_node.node.has_method("get_tourniquet_application_time_seconds") else 18.0
	print("[Combat] Medical: %s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration])
	c.gauge = 0.0
	c.state = STATE_MEDICAL_WIND_UP
	c.state_timer = 0.0
	c.state_duration = duration
	c.pending_medical = {"medical_id": medical_id, "target_part": target_part, "target_combatant_id": target_combatant_id}

func _begin_attack_with_target(attacker_id: int, target_id: int, move_id: String = "") -> void:
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	# Power and follow_through (0.2–1.0) per attack; intensity drives velocity, wind-up, and recovery
	var power: float = randf_range(POWER_MIN, POWER_MAX)
	var follow_through: float = randf_range(FOLLOW_THROUGH_MIN, FOLLOW_THROUGH_MAX)
	var intensity: float = (0.5 + 0.5 * power) * (0.5 + 0.5 * follow_through)
	intensity = clampf(intensity, INTENSITY_MIN, 1.0)
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
	var wind_up_s: float = _wind_up_duration(intensity, windup_mult)
	atk.gauge = 0.0
	atk.state = STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = wind_up_s
	atk.pending_attack = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype}
	var atk_name_log: String = atk.node.name if (atk.node != null) else "id:%d" % attacker_id
	print("[Combat] Power/commitment: %s | power=%.2f follow_through=%.2f => intensity=%.2f | windup_mult=%.2f => wind_up=%.2fs (recovery will use same intensity)" % [atk_name_log, power, follow_through, intensity, windup_mult, wind_up_s])

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
			var rec_dur_skip: float = _recovery_duration(intensity, "hit", recovery_mult_skip)
			print("[Combat] %s has no functional arm; skips attack. intensity=%.2f => recovery=%.2fs" % [atk_name, intensity, rec_dur_skip])
			emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "skip", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = rec_dur_skip
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

	# Roll miss before damage (pain/consciousness reduce hit chance; floor 35% performance)
	var outcome: String = "hit"
	var recovery_mult: float = float(archetype.get("recovery_multiplier", 1.0))
	var perf_mod: float = 1.0
	if atk.node != null and atk.node.has_method("get_performance_modifier"):
		perf_mod = atk.node.get_performance_modifier()
	var effective_hit_chance: float = (1.0 - MISS_CHANCE_BASE) * perf_mod
	var miss_chance: float = 1.0 - effective_hit_chance
	if randf() < miss_chance:
		outcome = "miss"
		var rec_dur: float = _recovery_duration(intensity, outcome, recovery_mult)
		print("[Combat] Recovery (miss): %s intensity=%.2f outcome=%s recovery_mult=%.2f => duration=%.2fs" % [atk_name, intensity, outcome, recovery_mult, rec_dur])
		emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": outcome, "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
		atk.state = STATE_RECOVERING
		atk.state_timer = 0.0
		atk.state_duration = rec_dur
		return

	# 1) Choose random body part (weighted by surface area/exposure). Sub-region is then chosen inside take_damage_split relative to this part.
	var part: String = BodyPartConstants.get_weighted_random_part(targetable)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
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
		# --- Damage equation: cut from KE + effective edge, blunt from momentum ---
		var v_m_s: float = WeaponDamageHelper.get_effective_velocity_m_s(weapon, attack_instance)
		var ke_j: float = WeaponDamageHelper.compute_kinetic_energy_j(weapon, attack_instance)
		var mass_kg: float = float(weapon.mass) if (weapon.get("mass") is float or weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
		var cut_ratio: float = WeaponDamageHelper.get_cut_ratio(weapon, attack_type, archetype)
		var pre_cut_raw: float = WeaponDamageHelper.compute_pre_armor_cut(weapon, attack_instance, atk.stats.strength, arm_mod)
		var pre_blunt_raw: float = WeaponDamageHelper.compute_pre_armor_blunt(weapon, attack_instance, atk.stats.strength, arm_mod)
		pre_cut = pre_cut_raw * cut_ratio
		pre_blunt = pre_blunt_raw * (1.0 - cut_ratio)
		pre_armor = pre_cut + pre_blunt
		var pen_sharp_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_SHARP)
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_BLUNT)
		pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
		pen_blunt = pen_blunt_dict.get("penetration_blunt", -1.0)
		pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
		var str_mod: float = maxf(0.1, float(atk.stats.strength) / 10.0)
		var pa_power: float = pa.get("power", -1.0)
		var pa_ft: float = pa.get("follow_through", -1.0)
		print("[Damage equation] %s -> %s | power=%.2f follow_through=%.2f intensity=%.2f (drives v, KE, wind-up, recovery) | physics: v=%.2f m/s mass=%.2f kg KE=%.1f J | modifiers: strength=%.2f arm=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | penetration: sharp=%.2f mm RHA blunt=%.1f MPa" % [atk_name, tgt_name, pa_power, pa_ft, intensity, v_m_s, mass_kg, ke_j, str_mod, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp, pen_blunt])
	else:
		var mod: float = 1.0
		if atk.node != null and atk.node.has_method("get_attack_damage_modifier"):
			mod = atk.node.get_attack_damage_modifier()
		pre_armor = float(atk.stats.strength * mod)
		pre_blunt = pre_armor
		pre_cut = 0.0
		print("[Damage equation] %s -> %s | fallback (unarmed): pre_armor=%.1f (cut=%.1f blunt=%.1f)" % [atk_name, tgt_name, pre_armor, pre_cut, pre_blunt])

	# Read pools before for reporting (cut, blunt, bone)
	var health_before_cut: int = tgt.node.body_cutting.get(part, 0)
	var health_before_blunt: int = tgt.node.body_blunt.get(part, 0)
	var health_before_bone: int = tgt.node.bone_health.get(part, 0) if tgt.node.get("bone_health") else 0

	var take_result: Dictionary = {}
	if tgt.node.has_method("take_damage_split"):
		take_result = tgt.node.take_damage_split(pre_cut, pre_blunt, part, pen_sharp, pen_blunt, pen_blunt_momentum_per_area)
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
	var final_bone: int = take_result.get("final_bone", 0)
	var actual_dmg: int = final_cut + final_blunt + final_bone
	if outcome == "hit" and pre_armor > 0 and float(final_cut + final_blunt) < pre_armor * DEFLECTED_DAMAGE_RATIO:
		outcome = "deflected"

	tgt.stats.body_cutting = tgt.node.body_cutting.duplicate()
	tgt.stats.body_blunt = tgt.node.body_blunt.duplicate()

	var health_after_cut: int = tgt.node.body_cutting.get(part, 0)
	var health_after_blunt: int = tgt.node.body_blunt.get(part, 0)
	var health_after_bone: int = tgt.node.bone_health.get(part, 0) if tgt.node.get("bone_health") else 0
	var part_max: int = tgt.node.body_max.get(part, 0)
	var part_bone_max: int = tgt.node.bone_max.get(part, 0) if tgt.node.get("bone_max") else 0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (tissue_dmg %.0f < pre_armor*%.2f=%.1f)" % [float(final_cut + final_blunt), DEFLECTED_DAMAGE_RATIO, pre_armor * DEFLECTED_DAMAGE_RATIO]
	print("[Combat] %s (%s) -> %s (%s) %s: applied cut=%d blunt=%d bone=%d (total %d) | part state: cut %d->%d blunt %d->%d bone %d->%d (max cut/blunt %d bone %d) | outcome: %s" % [atk_name, atk.side, tgt_name, tgt.side, part, final_cut, final_blunt, final_bone, actual_dmg, health_before_cut, health_after_cut, health_before_blunt, health_after_blunt, health_before_bone, health_after_bone, part_max, part_bone_max, outcome_note])

	var result_dict := {"dmg": actual_dmg, "died": false, "part": part, "damage_type": "SPLIT", "health_before_cut": health_before_cut, "health_after_cut": health_after_cut, "health_before_blunt": health_before_blunt, "health_after_blunt": health_after_blunt, "health_before_bone": health_before_bone, "health_after_bone": health_after_bone, "final_cut": final_cut, "final_blunt": final_blunt, "final_bone": final_bone, "outcome": outcome, "was_deflected": take_result.get("was_deflected", false)}
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
	var victor: String = _check_for_winner()
	if not victor.is_empty():
		if tgt.node.has_method("is_incapacitated") and tgt.node.is_incapacitated():
			print("[Combat] INCAPACITATED: %s (consciousness < 10%%)" % tgt_name)
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		emit_signal("combat_ended", victor, tgt.node)
		stop()
		return
	var rec_dur_final: float = _recovery_duration(intensity, outcome, recovery_mult)
	print("[Combat] Recovery (hit): %s intensity=%.2f outcome=%s recovery_mult=%.2f => duration=%.2fs" % [atk_name, intensity, outcome, recovery_mult, rec_dur_final])
	emit_signal("action_resolved", attacker_id, target_id, result_dict)
	atk.state = STATE_RECOVERING
	atk.state_timer = 0.0
	atk.state_duration = rec_dur_final
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
	var parry_intensity: float = pa.get("intensity", 0.5)
	var recovery_mult: float = float(pa.get("archetype", {}).get("recovery_multiplier", 1.0))
	var rec_dur_parry: float = _recovery_duration(parry_intensity, "miss", recovery_mult)
	attacker.pending_attack = {}
	attacker.state = STATE_RECOVERING
	attacker.state_timer = 0.0
	attacker.state_duration = rec_dur_parry
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	var atk_name: String = attacker.node.name if attacker.node != null else "id:%d" % attacker_id
	print("[Combat] Parry: %s parried %s (attacker momentum %.1f vs defender capacity %.1f). Attacker recovery: intensity=%.2f => %.2fs" % [def_name, atk_name, p_a, c_d, parry_intensity, rec_dur_parry])
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
		if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
			continue
		if c.side != side:
			return c
	return null

func _check_for_winner() -> String:
	# Standing = alive and not incapacitated. A side wins when the other has 0 standing.
	var standing: Dictionary = {}
	for c in combatants:
		if not c.alive:
			continue
		if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
			continue
		standing[c.side] = standing.get(c.side, 0) + 1
	var sides_list: Array = []
	for c in combatants:
		if c.side not in sides_list:
			sides_list.append(c.side)
	if sides_list.size() >= 2:
		var a: int = standing.get(sides_list[0], 0)
		var b: int = standing.get(sides_list[1], 0)
		if a == 0:
			return sides_list[1]
		if b == 0:
			return sides_list[0]
	return ""
