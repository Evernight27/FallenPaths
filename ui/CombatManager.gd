extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal combatant_health_changed(combatant_id)

var combatants := []

const _Bleeding := preload("res://core/BleedingConstants.gd")

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine: waiting (gauge filling) -> wind_up (swing until impact) | medical_wind_up -> recovering (follow-through after hit/deflect/miss/medical)
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_PARRY_WIND_UP := "parry_wind_up"
const STATE_MEDICAL_WIND_UP := "medical_wind_up"
const STATE_RECOVERING := "recovering"

# Power and follow_through (0.2–1.0 each): rolled per attack; intensity = (0.5+0.5*power)*(0.5+0.5*follow_through) drives velocity, wind-up, and recovery.
const POWER_MIN := 0.2
const POWER_MAX := 1.0
const FOLLOW_THROUGH_MIN := 0.2
const FOLLOW_THROUGH_MAX := 1.0
const INTENSITY_MIN := 0.2  # floor so weak attacks still have some commitment

# Timing (seconds). Wind-up = everything until moment of impact (blade hits target); recovery = follow-through after impact.
# Wind-up and recovery scale with intensity (bigger swing = longer wind-up and recovery).
const WIND_UP_BASE_S := 0.25
const WIND_UP_SCALE_S := 0.6
const RECOVERY_BASE_S := 0.2
const RECOVERY_COMMITMENT_SCALE_S := 0.5
const RECOVERY_EXTRA_HIT_S := 0.0
const RECOVERY_EXTRA_DEFLECTED_S := 0.25
const RECOVERY_EXTRA_MISS_S := 0.5

# Leg functionality scales attack wind-up only (positioning/footwork). Min clamp avoids divide-by-zero.
const WINDUP_LEG_MIN := 0.2

# Miss chance (0-1). Rolled before damage; miss = no contact, longest recovery.
const MISS_CHANCE_BASE := 0.06
# Deflected = contact but armor absorbed most; final_damage < pre_armor * this ratio.
const DEFLECTED_DAMAGE_RATIO := 0.25

# Intensity (0–1): derived from power and follow_through per attack; drives velocity, wind-up, recovery. Strength can bias power/follow_through later; for now both rolled.
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 12.0
const INTENSITY_RANDOM_RANGE := 0.2
const RECOVERY_AFTER_MEDICAL_S := 0.5  # short recovery after applying bandage/tourniquet/direct pressure

# Medical moves that can be applied to self or allies. Add new medical actions here; extend _get_ally_medical_actions, _start_medical_action, and wind-up completion.
const MEDICAL_MOVE_IDS: Array[String] = ["bandage_self", "apply_direct_pressure", "apply_tourniquet"]
# Config for wind-up medical actions: move_id -> {duration_method, target_method, outcome}. Instant actions (e.g. direct_pressure) are handled separately.
const _MEDICAL_WIND_UP_CONFIG: Dictionary = {
	"bandage_self": {"duration_method": "get_bandage_application_time_seconds", "target_method": "apply_bandage", "outcome": "bandaged"},
	"apply_tourniquet": {"duration_method": "get_tourniquet_application_time_seconds", "target_method": "apply_tourniquet", "outcome": "tourniquet_applied"}
}

# --- Parry: physics and timings (derived, not magic numbers) ---
# Impulse balance: p_a = m_a * v_current (kg·m/s); v_current from velocity curve (progress²), so early parries face less momentum. c_d = m_d * v_parry * (strength/PARRY_STRENGTH_NORM). Full deflect when c_d >= p_a * PARRY_DEFLECT_THRESHOLD; else partial (remaining p → impact v = remaining/m_a).
# Parry speed: defensive move is positioning, not full strike. Strike 17–24 m/s; parry ~40–60% of that. v_parry = VELOCITY_MAX_M_S * PARRY_V_FRACTION (same scale as attacks).
# Parry wind-up: reaction (fixed, cognitive) + blade movement (scaled by weapon mass and strength). Lighter weapon / stronger user = faster into parry position.
# Tuning: quadratic curve makes early parries easier (lower p_a). If full deflects feel too common, raise PARRY_DEFLECT_THRESHOLD (e.g. 1.1) or soften curve in _velocity_curve_factor (e.g. progress^1.5).
const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5   # parry speed = WeaponConstants.VELOCITY_MAX_M_S * this (~10 m/s)
const PARRY_STRENGTH_NORM := 10.0             # (strength/this) → 10 = normal human
const PARRY_DEFLECT_THRESHOLD := 1.0          # full deflect when c_d >= p_a * this (1.0 = impulse match)
const PARRY_TECHNIQUE_VARIANCE := 0.1         # ±fraction on capacity (timing/placement)
const PARRY_V_MIN_FRACTION := 0.2             # partial parry: impact v >= v_intent * this (residual glancing hit)
const PARRY_REACTION_S := 0.22                # reaction to initiate parry (s); same for all (cognitive)
const PARRY_BLADE_MOVEMENT_S := 0.13          # base time to move blade into intercept (s); scaled by mass/strength
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5 # movement mult clamp: light weapon / strong user (min = faster parry)
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0 # movement mult clamp: heavy weapon / weak user (max = slower parry)
# Pain/consciousness: scale durations and capacities; floor matches PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER
const PERF_MOD_MIN := 0.35

## Returns the node that holds health/wounds (CoreEntity for enemies; CombatBody for Character). Use for all health reads.
func _get_entity(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e = node.get_medical_entity()
		return e if e != null else node
	return node

func _refresh_combatant_stats(c: Dictionary) -> void:
	"""Keep combatant stats in sync with node (pain, consciousness, blood, etc.) for UI and gauge fill.
	Uses _get_entity for unified health access (party Character -> CombatBody, enemies -> self)."""
	if c.node == null:
		return
	var entity = _get_entity(c.node)
	if entity == null:
		return
	if entity.has_method("ensure_consciousness_current"):
		entity.ensure_consciousness_current()
	if "body_cutting" in entity:
		c.stats.body_cutting = entity.body_cutting.duplicate()
	if "body_blunt" in entity:
		c.stats.body_blunt = entity.body_blunt.duplicate()
	if "bone_health" in entity:
		c.stats.bone_health = entity.bone_health.duplicate()
	if "bone_max" in entity:
		c.stats.bone_max = entity.bone_max.duplicate()
	if entity.has_method("get_blood_volume"):
		c.stats.blood_volume = entity.get_blood_volume()
	elif "blood_volume" in entity:
		c.stats.blood_volume = entity.blood_volume
	if entity.has_method("get_total_bleeding_rate"):
		c.stats.total_bleeding_rate = entity.get_total_bleeding_rate()
	if entity.has_method("get_total_pain"):
		c.stats.total_pain = entity.get_total_pain()
	if entity.has_method("get_effective_consciousness"):
		c.stats.effective_consciousness = entity.get_effective_consciousness()
	if entity.has_method("get_performance_modifier"):
		c.stats.performance_modifier = entity.get_performance_modifier()

func _read_stats_from(node: Node) -> Dictionary:
	var s := {
		"body_cutting": {},
		"body_blunt": {},
		"body_max": {},
		"bone_health": {},
		"bone_max": {},
		"strength": 1,
		"agility": 100,
		"intelligence": 100,
		"endurance": 100,
		"perception": 100
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
	if "agility" in node:
		s.agility = node.agility
	elif "speed" in node:
		s.agility = node.speed
	if "intelligence" in node:
		s.intelligence = node.intelligence
	if "endurance" in node:
		s.endurance = node.endurance
	if "perception" in node:
		s.perception = node.perception
	return s

func register(node: Node, side: String) -> int:
	var id = combatants.size()
	var entity = _get_entity(node)
	var stats = _read_stats_from(entity if entity != null else node)
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
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

func start():
	set_process(true)

func stop():
	set_process(false)

func get_combatants() -> Array:
	var out := []
	for c in combatants:
		var stats = c.stats.duplicate()
		if c.node != null:
			var entity = _get_entity(c.node)
			if entity != null:
				if entity.has_method("ensure_consciousness_current"):
					entity.ensure_consciousness_current()
				if "body_cutting" in entity:
					stats.body_cutting = entity.body_cutting.duplicate()
				if "body_blunt" in entity:
					stats.body_blunt = entity.body_blunt.duplicate()
				if "bone_health" in entity:
					stats.bone_health = entity.bone_health.duplicate()
				if "bone_max" in entity:
					stats.bone_max = entity.bone_max.duplicate()
				if entity.has_method("get_blood_volume"):
					stats.blood_volume = entity.get_blood_volume()
				elif "blood_volume" in entity:
					stats.blood_volume = entity.blood_volume
				if entity.has_method("get_total_bleeding_rate"):
					stats.total_bleeding_rate = entity.get_total_bleeding_rate()
				if entity.has_method("get_effective_consciousness"):
					stats.effective_consciousness = entity.get_effective_consciousness()
				if entity.has_method("get_performance_modifier"):
					stats.performance_modifier = entity.get_performance_modifier()
				if entity.has_method("get_total_pain"):
					stats.total_pain = entity.get_total_pain()
		if not stats.has("blood_volume"):
			stats.blood_volume = 100.0
		if not stats.has("total_bleeding_rate"):
			stats.total_bleeding_rate = 0.0
		if not stats.has("effective_consciousness"):
			stats.effective_consciousness = 100.0
		if not stats.has("performance_modifier"):
			stats.performance_modifier = 1.0
		if not stats.has("total_pain"):
			stats.total_pain = 0.0
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

# When choosing an action, parry moves get this weight vs 1 for others (so parry is chosen most of the time when available, not guaranteed).
const PARRY_CHOICE_WEIGHT := 5.0

# AI only considers medical actions when in danger of dying soon (low blood or high bleeding rate).
const MEDICAL_DANGER_BLOOD_THRESHOLD := 55.0   # consider medical when blood volume <= this %
const MEDICAL_DANGER_SECONDS := 90.0           # or when estimated time to blood-loss death <= this many seconds
# When medical is available, weight scales from 1 to this as urgency (how close to death) increases; randomness applied so not guaranteed.
const MEDICAL_URGENCY_WEIGHT_MAX := 6.0
const MEDICAL_URGENCY_RANDOM_MIN := 0.8        # urgency multiplied by randf_range(MIN, MAX) for variance
const MEDICAL_URGENCY_RANDOM_MAX := 1.2

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Parry moves only if someone is winding up on this combatant. Medical moves only when in medical danger.
func _is_in_medical_danger(c: Dictionary) -> bool:
	var entity = _get_entity(c.node) if c.node != null else null
	if entity == null:
		return false
	var bv: float = 100.0
	if entity.has_method("get_blood_volume"):
		bv = entity.get_blood_volume()
	elif "blood_volume" in entity:
		bv = float(entity.blood_volume)
	if bv <= MEDICAL_DANGER_BLOOD_THRESHOLD:
		return true
	var rate: float = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	if rate <= 0.0:
		return false
	var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return false
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
	return time_to_death <= MEDICAL_DANGER_SECONDS

# 0..1: higher when more hurt (lower blood, shorter time to death). Only meaningful when in medical danger. Includes randomness.
func _get_medical_urgency(c: Dictionary) -> float:
	var entity = _get_entity(c.node) if (c != null and c.node != null) else null
	if entity == null:
		return 0.0
	var bv: float = 100.0
	if entity.has_method("get_blood_volume"):
		bv = entity.get_blood_volume()
	elif "blood_volume" in entity:
		bv = float(entity.blood_volume)
	var death_thresh: float = _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD
	# Urgency from blood: 1 at/below death threshold, 0 at MEDICAL_DANGER_BLOOD_THRESHOLD (55%)
	var range_bv: float = MEDICAL_DANGER_BLOOD_THRESHOLD - death_thresh
	var urgency_blood: float = 1.0 if bv <= death_thresh else clampf((MEDICAL_DANGER_BLOOD_THRESHOLD - bv) / maxf(0.01, range_bv), 0.0, 1.0)
	# Urgency from time to death: 1 when <= 0 sec, 0 when >= MEDICAL_DANGER_SECONDS
	var urgency_time: float = 0.0
	var rate: float = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	if rate > 0.0:
		var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
		if loss_per_sec > 0.0:
			var time_to_death: float = (bv - death_thresh) / loss_per_sec
			urgency_time = 1.0 if time_to_death <= 0.0 else clampf(1.0 - time_to_death / MEDICAL_DANGER_SECONDS, 0.0, 1.0)
	var raw: float = maxf(urgency_blood, urgency_time)
	raw *= randf_range(MEDICAL_URGENCY_RANDOM_MIN, MEDICAL_URGENCY_RANDOM_MAX)
	return clampf(raw, 0.0, 1.0)

static func _is_medical_move(move_id: String) -> bool:
	return move_id in MEDICAL_MOVE_IDS

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part. Extend this when adding new medical moves.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	var out: Array = []
	var performer_has_arm: bool = performer.node.can_apply_direct_pressure("") if performer.node != null else false
	out.append({ "move_id": "bandage_self", "target_part": part })
	if performer_has_arm and performer.node.has_method("is_applying_direct_pressure") and not performer.node.is_applying_direct_pressure():
		out.append({ "move_id": "apply_direct_pressure", "target_part": part })
	if ally.node.has_method("can_apply_tourniquet") and ally.node.can_apply_tourniquet(part):
		out.append({ "move_id": "apply_tourniquet", "target_part": part })
	return out

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
	# Medical actions (self and allies): when any ally is in danger of dying soon (low blood or bleeding will kill in MEDICAL_DANGER_SECONDS).
	# To add new medical actions: add move_id to MEDICAL_MOVE_IDS, add availability in _get_ally_medical_actions, add duration/handler in _start_medical_action and wind-up completion.
	if c.node != null and c.node.has_method("can_apply_direct_pressure"):
		for ally in combatants:
			if not ally.alive or ally.side != c.side or ally.node == null:
				continue
			if not _is_in_medical_danger(ally):
				continue
			if not ally.node.has_method("get_wounded_parts"):
				continue
			var wounded: Array = ally.node.get_wounded_parts()
			for part in wounded:
				if part.is_empty():
					continue
				var tgt_id: int = ally.id
				for act in _get_ally_medical_actions(c, ally, part):
					actions.append({ "target_id": tgt_id, "move_id": act.move_id, "target_part": act.target_part })
	var medical_count: int = 0
	for a in actions:
		var mid: String = a.get("move_id", "")
		if _is_medical_move(mid):
			medical_count += 1
	if medical_count > 0:
		print("[Combat] get_available_actions: combatant_id=%d => %d total (%d medical: bandage/direct_pressure/tourniquet)" % [combatant_id, actions.size(), medical_count])
	return actions

# Pick one action from the list. Parry: PARRY_CHOICE_WEIGHT. Medical: 1..MEDICAL_URGENCY_WEIGHT_MAX by how hurt the combatant is (plus randomness). Others: 1.
# combatant_id required for medical weighting; if -1, medical gets weight 1.
func pick_weighted_action(actions: Array, combatant_id: int = -1) -> Dictionary:
	if actions.is_empty():
		return {}
	var c = _get_by_id(combatant_id) if combatant_id >= 0 else null
	var medical_urgency: float = _get_medical_urgency(c) if c != null else 0.0
	var medical_weight_base: float = 1.0 + medical_urgency * (MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
	var total: float = 0.0
	for a in actions:
		var mid: String = a.get("move_id", "")
		if WeaponConstants.is_parry_move(mid):
			total += PARRY_CHOICE_WEIGHT
		elif _is_medical_move(mid):
			total += medical_weight_base
		else:
			total += 1.0
	var r: float = randf() * total
	for a in actions:
		var mid: String = a.get("move_id", "")
		var w: float
		if WeaponConstants.is_parry_move(mid):
			w = PARRY_CHOICE_WEIGHT
		elif _is_medical_move(mid):
			w = medical_weight_base
		else:
			w = 1.0
		if r < w:
			return a
		r -= w
	return actions[0]

func _process(delta: float) -> void:
	var victor: String = ""
	# Bleeding and blood loss tick during combat here. Outside combat, they also advance on time (e.g. 1 min per move in main._advance_time_one_minute) for medical realism.
	for c in combatants:
		if not c.alive or c.node == null:
			continue
		if c.node.has_method("process_bleeding"):
			c.node.process_bleeding(delta)
		if c.node.has_method("process_blood_loss"):
			c.node.process_blood_loss(delta)
		# Refresh pain/consciousness/blood after tick so UI and gauge fill use current values.
		_refresh_combatant_stats(c)
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
			victor = _check_for_winner()
			if not victor.is_empty():
				emit_signal("combat_ended", victor, c.node)
				stop()
			return
	victor = _check_for_winner()
	if not victor.is_empty():
		emit_signal("combat_ended", victor, null)
		stop()
		return
	for c in combatants:
		if not c.alive:
			continue
		if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
			continue  # incapacitated: no gauge fill, cannot act
		# Medical wind-up: cancel if target (ally) died during wind-up
		if c.state == STATE_MEDICAL_WIND_UP:
			var pm_check = c.get("pending_medical", {})
			var tgt_cid_check: int = pm_check.get("target_combatant_id", c.id)
			if tgt_cid_check != c.id:
				var tgt_check = _get_by_id(tgt_cid_check)
				if tgt_check == null or not tgt_check.alive or (tgt_check.node != null and tgt_check.node.has_method("is_dead") and tgt_check.node.is_dead()):
					c.pending_medical = {}
					c.state = STATE_WAITING
					c.state_timer = 0.0
					c.state_duration = 0.0
					var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
					print("[Combat] Medical cancelled: %s (target died during wind-up)" % who_name)
					continue
		if c.state == STATE_WAITING:
			# Gauge fill: base speed × performance. Use action bar modifier (chest pain) when available.
			var spd: float = float(c.stats.get("agility", 100))
			var fill_rate: float = spd * delta * 0.5
			if c.node != null:
				if c.node.has_method("get_action_bar_performance_modifier"):
					fill_rate *= c.node.get_action_bar_performance_modifier()
				elif c.node.has_method("get_performance_modifier"):
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
						var choice = pick_weighted_action(actions, c.id)
						var opts: Dictionary = {}
						if choice.get("target_part", "") != "":
							opts["target_part"] = choice.target_part
						resolve_action(c.id, choice.target_id, choice.get("move_id", ""), opts)
		elif c.state == STATE_WIND_UP:
			c.gauge = 0.0  # Action bar does not fill while swinging
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				var tgt = _get_by_id(c.pending_attack.get("target_id", -1))
				if tgt != null and tgt.state == STATE_PARRY_WIND_UP and tgt.get("pending_parry", {}).get("attacker_id") == c.id:
					_resolve_parry_at_impact(c.id, tgt.id)
				else:
					_execute_attack(c.id)
		elif c.state == STATE_PARRY_WIND_UP:
			c.gauge = 0.0
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				var pp: Dictionary = c.get("pending_parry", {})
				var attack_id: int = pp.get("attacker_id", -1)
				var move_id: String = pp.get("move_id", "")
				c.pending_parry = {}
				if attack_id >= 0:
					_resolve_parry_parry_ready_first(c.id, attack_id, move_id)
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
				# Recovery after medical (scaled by pain/consciousness)
				var med_rec_dur: float = RECOVERY_AFTER_MEDICAL_S
				var med_perf: float = 1.0
				if c.node != null and c.node.has_method("get_performance_modifier"):
					med_perf = c.node.get_performance_modifier()
				if med_perf > 0.0:
					med_rec_dur /= maxf(PERF_MOD_MIN, med_perf)
				# Only apply if target is still alive (may have died during wind-up)
				var tgt_alive: bool = tgt_c.alive and (not tgt_c.node.has_method("is_dead") or not tgt_c.node.is_dead())
				if tgt_c != null and tgt_c.node != null and tgt_alive and not part.is_empty():
					var wind_up_cfg = _MEDICAL_WIND_UP_CONFIG.get(med_id, {})
					var target_method: String = wind_up_cfg.get("target_method", "")
					if not target_method.is_empty():
						var tgt_entity = _get_entity(tgt_c.node)
						if tgt_entity != null and tgt_entity.has_method(target_method):
							var result = null
							if target_method == "apply_bandage":
								var perf_entity = _get_entity(c.node)
								var eff: float = perf_entity.get_medical_effectiveness() if (perf_entity != null and perf_entity.has_method("get_medical_effectiveness")) else 1.0
								tgt_entity.call(target_method, part, eff)
								result = true
							else:
								result = tgt_entity.call(target_method, part)
							if result != false:  # apply_tourniquet returns bool; apply_bandage returns void
								var outcome: String = wind_up_cfg.get("outcome", med_id)
								print("[Combat] Medical complete: %s %s on %s => recovery %.1fs" % [who_m, med_id, part, med_rec_dur])
								emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false})
				c.state = STATE_RECOVERING
				c.state_timer = 0.0
				c.state_duration = med_rec_dur
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
	# Medical actions (target_id = combatant to apply on, self or ally)
	if _is_medical_move(move_id):
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
			_begin_parry(attacker_id, target_id, move_id)
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

# Velocity curve over wind-up progress (0 = swing start, 1 = impact). Peak at 1.0 so impact uses full velocity.
# Quadratic (p²): blade accelerates into impact; early parry meets less momentum than linear.
static func _velocity_curve_factor(progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	return p * p

func _recovery_duration(intensity: float, outcome: String, recovery_multiplier: float = 1.0, perf_mod: float = 1.0) -> float:
	var commitment: float = intensity
	var extra: float = RECOVERY_EXTRA_HIT_S
	if outcome == "deflected":
		extra = RECOVERY_EXTRA_DEFLECTED_S
	elif outcome == "miss" or outcome == "dodge":
		extra = RECOVERY_EXTRA_MISS_S
	var base: float = (RECOVERY_BASE_S + RECOVERY_COMMITMENT_SCALE_S * commitment + extra) * maxf(0.5, recovery_multiplier)
	# Pain/consciousness: wounded entities recover slower
	if perf_mod > 0.0:
		base /= maxf(PERF_MOD_MIN, perf_mod)
	return base

func _start_medical_action(combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String) -> void:
	var c = _get_by_id(combatant_id)
	var target_node = _get_by_id(target_combatant_id)
	if c == null or target_node == null or target_node.node == null:
		return
	var who_name: String = c.node.name if (c.node != null) else "id:%d" % combatant_id
	# Bandage/tourniquet: performer stops holding direct pressure on anyone (new action)
	if medical_id == "bandage_self" or medical_id == "apply_tourniquet":
		if c.node != null and c.node.has_method("clear_direct_pressure"):
			c.node.clear_direct_pressure()
		# Apply direct pressure to the part being bandaged/tourniqueted during wind-up (reduces bleeding while preparing)
		if not target_part.is_empty():
			var target_entity = _get_entity(target_node.node)
			var performer_entity = _get_entity(c.node)
			if target_entity != null and target_entity.has_method("get_wounds") and target_entity.get_wounds().has(target_part):
				if target_combatant_id == combatant_id:
					if target_entity.has_method("apply_direct_pressure") and target_entity.apply_direct_pressure(target_part):
						print("[Combat] Medical: %s applying direct pressure on %s during %s wind-up" % [who_name, target_part, medical_id])
				else:
					if target_entity.has_method("apply_direct_pressure_from_ally") and target_entity.apply_direct_pressure_from_ally(target_part, performer_entity):
						if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
							performer_entity.direct_pressure_on_ally = {"node": target_entity, "part": target_part}
						print("[Combat] Medical: %s applying direct pressure on ally's %s during %s wind-up" % [who_name, target_part, medical_id])
	var duration: float = 0.0
	if medical_id == "apply_direct_pressure":
		# Instant: apply now, then short recovery (scaled by pain/consciousness)
		var med_rec_dur: float = RECOVERY_AFTER_MEDICAL_S
		var med_perf: float = 1.0
		if c.node != null and c.node.has_method("get_performance_modifier"):
			med_perf = c.node.get_performance_modifier()
		if med_perf > 0.0:
			med_rec_dur /= maxf(PERF_MOD_MIN, med_perf)
		var applied: bool = false
		if target_combatant_id == combatant_id:
			# Self
			if target_node.node.has_method("apply_direct_pressure") and target_node.node.apply_direct_pressure(target_part):
				applied = true
		else:
			# Ally: performer applies to target
			var target_entity = _get_entity(target_node.node)
			var performer_entity = _get_entity(c.node)
			if target_entity != null and target_entity.has_method("apply_direct_pressure_from_ally") and target_entity.apply_direct_pressure_from_ally(target_part, performer_entity):
				applied = true
				if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
					performer_entity.direct_pressure_on_ally = {"node": target_entity, "part": target_part}
		if applied:
			print("[Combat] Medical: %s applied direct_pressure on %s (instant) => recovery %.1fs" % [who_name, target_part, med_rec_dur])
			emit_signal("action_resolved", combatant_id, target_combatant_id, {"outcome": "direct_pressure", "part": target_part, "dmg": 0, "died": false})
		c.gauge = 0.0
		c.state = STATE_RECOVERING
		c.state_timer = 0.0
		c.state_duration = med_rec_dur
		return
	var wind_up_cfg = _MEDICAL_WIND_UP_CONFIG.get(medical_id, {})
	var dur_method: String = wind_up_cfg.get("duration_method", "")
	if not dur_method.is_empty() and target_node.node.has_method(dur_method):
		duration = target_node.node.call(dur_method)
	if duration <= 0.0 and not wind_up_cfg.is_empty():
		duration = 4.0  # fallback for custom entities
	# Pain/consciousness: wounded entities take longer to apply medical actions
	var perf_mod: float = 1.0
	if c.node != null and c.node.has_method("get_performance_modifier"):
		perf_mod = c.node.get_performance_modifier()
	if perf_mod > 0.0:
		duration /= maxf(PERF_MOD_MIN, perf_mod)
	print("[Combat] Medical: %s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration])
	c.gauge = 0.0
	c.state = STATE_MEDICAL_WIND_UP
	c.state_timer = 0.0
	c.state_duration = duration
	c.pending_medical = {"medical_id": medical_id, "target_part": target_part, "target_combatant_id": target_combatant_id}

# Parry wind-up duration (s): reaction (fixed) + blade movement scaled by weapon mass and strength. Dagger faster than axe/hammer.
func _get_parry_wind_up_duration(defender: Dictionary) -> float:
	var reaction_s: float = PARRY_REACTION_S
	var m_d: float = WeaponConstants.BASELINE_MASS_KG
	if defender.node != null and defender.node.has_method("get_weapon"):
		var w = defender.node.get_weapon()
		if w != null and (w.get("mass") is float or w.get("mass") is int):
			m_d = float(w.mass)
	var str_val: float = float(defender.stats.get("strength", 10))
	var mult: float = (m_d / WeaponConstants.BASELINE_MASS_KG) * (PARRY_STRENGTH_NORM / maxf(1.0, str_val))
	mult = clampf(mult, PARRY_MOVEMENT_MASS_STRENGTH_MIN, PARRY_MOVEMENT_MASS_STRENGTH_MAX)
	var base: float = reaction_s + PARRY_BLADE_MOVEMENT_S * mult
	# Pain/consciousness: wounded defenders react slower to parry
	var perf_mod: float = 1.0
	if defender.node != null and defender.node.has_method("get_performance_modifier"):
		perf_mod = defender.node.get_performance_modifier()
	if perf_mod > 0.0:
		base /= maxf(PERF_MOD_MIN, perf_mod)
	return base

# Parry has its own wind-up; resolution happens when parry completes (use attack momentum at that moment) or when attack lands first (use parry capacity scaled by parry progress).
func _begin_parry(defender_id: int, attacker_id: int, move_id: String) -> void:
	var defender = _get_by_id(defender_id)
	var attacker = _get_by_id(attacker_id)
	if defender == null or attacker == null or attacker.pending_attack.is_empty():
		return
	var wind_up_s: float = _get_parry_wind_up_duration(defender)
	defender.gauge = 0.0
	defender.state = STATE_PARRY_WIND_UP
	defender.state_timer = 0.0
	defender.state_duration = wind_up_s
	defender.pending_parry = {"attacker_id": attacker_id, "move_id": move_id}
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	var atk_name: String = attacker.node.name if attacker.node != null else "id:%d" % attacker_id
	print("[Combat] Parry wind-up: %s getting blade in place vs %s (%.2fs)" % [def_name, atk_name, wind_up_s])

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
	# Leg functionality: longer wind-up when legs injured (harder to get into position to attack).
	if atk.node != null and atk.node.has_method("get_leg_functionality"):
		var leg: float = clampf(atk.node.get_leg_functionality(), WINDUP_LEG_MIN, 1.0)
		wind_up_s /= leg
	# Pain/consciousness: wounded attackers swing slower
	var atk_perf_mod: float = 1.0
	if atk.node != null and atk.node.has_method("get_performance_modifier"):
		atk_perf_mod = atk.node.get_performance_modifier()
	if atk_perf_mod > 0.0:
		wind_up_s /= maxf(PERF_MOD_MIN, atk_perf_mod)
	atk.gauge = 0.0
	atk.state = STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = wind_up_s
	atk.pending_attack = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype}
	var atk_name_log: String = atk.node.name if (atk.node != null) else "id:%d" % attacker_id
	print("[Combat] Power/commitment: %s | power=%.2f follow_through=%.2f => intensity=%.2f | windup_mult=%.2f => wind_up=%.2fs (recovery will use same intensity)" % [atk_name_log, power, follow_through, intensity, windup_mult, wind_up_s])

func _execute_attack(attacker_id: int) -> void:
	var w: String = ""
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
	var atk_perf_mod: float = 1.0
	if atk.node != null and atk.node.has_method("get_performance_modifier"):
		atk_perf_mod = atk.node.get_performance_modifier()
	if atk.node != null and atk.node.has_method("get_attacking_arm"):
		if atk.node.get_attacking_arm().is_empty():
			var rec_dur_skip: float = _recovery_duration(intensity, "hit", recovery_mult_skip, atk_perf_mod)
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
		w = _check_for_winner()
		if not w.is_empty():
			emit_signal("combat_ended", w, tgt.node)
			stop()
		return

	# Roll miss before damage (pain/consciousness reduce hit chance; head pain adds regional penalty)
	var outcome: String = "hit"
	var recovery_mult: float = float(archetype.get("recovery_multiplier", 1.0))
	var perf_mod: float = 1.0
	if atk.node != null:
		if atk.node.has_method("get_hit_chance_performance_modifier"):
			perf_mod = atk.node.get_hit_chance_performance_modifier()
		elif atk.node.has_method("get_performance_modifier"):
			perf_mod = atk.node.get_performance_modifier()
	var effective_hit_chance: float = (1.0 - MISS_CHANCE_BASE) * perf_mod
	var miss_chance: float = 1.0 - effective_hit_chance
	if randf() < miss_chance:
		outcome = "miss"
		var rec_dur: float = _recovery_duration(intensity, outcome, recovery_mult, perf_mod)
		print("[Combat] Recovery (miss): %s intensity=%.2f outcome=%s recovery_mult=%.2f => duration=%.2fs" % [atk_name, intensity, outcome, recovery_mult, rec_dur])
		emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": outcome, "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
		atk.state = STATE_RECOVERING
		atk.state_timer = 0.0
		atk.state_duration = rec_dur
		return

	# Passive dodge: defender rolls dodge chance (speed, legs, pain/consciousness).
	if tgt.node != null and tgt.node.has_method("get_dodge_chance"):
		var dodge_chance: float = tgt.node.get_dodge_chance()
		if dodge_chance > 0.0 and randf() < dodge_chance:
			outcome = "dodge"
			var rec_dur: float = _recovery_duration(intensity, outcome, recovery_mult, perf_mod)
			print("[Combat] Recovery (dodge): %s intensity=%.2f outcome=%s recovery_mult=%.2f => duration=%.2fs" % [atk_name, intensity, outcome, recovery_mult, rec_dur])
			emit_signal("action_resolved", attacker_id, target_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": outcome, "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = rec_dur
			return

	# 1) Choose random body part (weighted by surface area/exposure). Sub-region is then chosen inside take_damage_split relative to this part.
	var part: String = BodyPartConstants.get_weighted_random_part(targetable)
	var pre_armor: float = 0.0
	var pen_sharp: float = -1.0
	var pen_blunt_momentum_per_area: float = -1.0
	var blunt_contact_cm: float = -1.0
	var pre_cut: float = 0.0
	var pre_blunt: float = 0.0

	var weapon = null
	if atk.node != null and atk.node.has_method("get_weapon"):
		weapon = atk.node.get_weapon()

	if weapon != null and weapon.has_method("get_available_attack_types"):
		var attack_instance = AttackInstance.new(attack_type, intensity)
		attack_instance.archetype = archetype
		attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else WeaponDamageHelper.velocity_m_s_from_intensity(intensity, archetype)
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
		pen_sharp = pen_sharp_dict.get("penetration_sharp", -1.0)
		var blunt_opts: Dictionary = {}
		if tgt.node != null and tgt.node.has_method("get_armor_sharp_resistance_for_part"):
			blunt_opts["armor_resistance_rha_mm"] = tgt.node.get_armor_sharp_resistance_for_part(part)
		blunt_opts["pen_sharp_mm"] = pen_sharp
		var pen_blunt_dict: Dictionary = WeaponDamageHelper.compute_penetration(weapon, attack_instance, DAMAGE_TYPE_BLUNT, blunt_opts)
		pen_blunt_momentum_per_area = pen_blunt_dict.get("penetration_blunt_momentum_per_area", -1.0)
		blunt_contact_cm = pen_blunt_dict.get("blunt_contact_cm", -1.0)
		var str_mod: float = maxf(0.1, float(atk.stats.strength) / 10.0)
		var pa_power: float = pa.get("power", -1.0)
		var pa_ft: float = pa.get("follow_through", -1.0)
		print("[Damage equation] %s -> %s | power=%.2f follow_through=%.2f intensity=%.2f (drives v, KE, wind-up, recovery) | physics: v=%.2f m/s mass=%.2f kg KE=%.1f J | modifiers: strength=%.2f arm=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | pen_sharp=%.2f mm RHA | blunt: transmission only (momentum/A=%.0f)" % [atk_name, tgt_name, pa_power, pa_ft, intensity, v_m_s, mass_kg, ke_j, str_mod, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp, pen_blunt_momentum_per_area])
	else:
		var mod: float = 1.0
		if atk.node != null and atk.node.has_method("get_attack_damage_modifier"):
			mod = atk.node.get_attack_damage_modifier()
		pre_armor = float(atk.stats.strength * mod)
		pre_blunt = pre_armor
		pre_cut = 0.0
		print("[Damage equation] %s -> %s | fallback (unarmed): pre_armor=%.1f (cut=%.1f blunt=%.1f)" % [atk_name, tgt_name, pre_armor, pre_cut, pre_blunt])

	# Read pools before for reporting (cut, blunt, bone)
	var health_before_cut: float = tgt.node.body_cutting.get(part, 0.0)
	var health_before_blunt: float = tgt.node.body_blunt.get(part, 0.0)
	var health_before_bone: float = tgt.node.bone_health.get(part, 0.0) if tgt.node.get("bone_health") else 0.0

	var take_result: Dictionary = {}
	if tgt.node.has_method("take_damage_split"):
		take_result = tgt.node.take_damage_split(pre_cut, pre_blunt, part, pen_sharp, pen_blunt_momentum_per_area, blunt_contact_cm)
	else:
		# Fallback: single stream (pre_cut or pre_blunt by ratio). Pass momentum for cushion when blunt.
		if pre_cut >= pre_blunt and tgt.node.has_method("take_damage"):
			take_result = tgt.node.take_damage(pre_cut, part, DAMAGE_TYPE_SHARP, pen_sharp, -1.0)
			take_result["final_cut"] = take_result.get("final_amount", 0.0)
			take_result["final_blunt"] = 0.0
		else:
			take_result = tgt.node.take_damage(pre_blunt, part, DAMAGE_TYPE_BLUNT, -1.0, pen_blunt_momentum_per_area)
			take_result["final_cut"] = 0.0
			take_result["final_blunt"] = take_result.get("final_amount", 0.0)

	var final_cut: float = take_result.get("final_cut", 0.0)
	var final_blunt: float = take_result.get("final_blunt", 0.0)
	var final_bone: float = take_result.get("final_bone", 0.0)
	var actual_dmg: int = int(roundf(final_cut + final_blunt + final_bone))
	if outcome == "hit" and pre_armor > 0 and float(final_cut + final_blunt) < pre_armor * DEFLECTED_DAMAGE_RATIO:
		outcome = "deflected"

	var tgt_entity = _get_entity(tgt.node)
	if tgt_entity == null:
		tgt_entity = tgt.node
	tgt.stats.body_cutting = tgt_entity.body_cutting.duplicate()
	tgt.stats.body_blunt = tgt_entity.body_blunt.duplicate()
	# Keep pain/consciousness/performance in sync so UI (and any direct stats reads) stays current for all combatants.
	if tgt_entity.has_method("get_total_pain"):
		tgt.stats.total_pain = tgt_entity.get_total_pain()
	if tgt_entity.has_method("get_effective_consciousness"):
		tgt.stats.effective_consciousness = tgt_entity.get_effective_consciousness()
	if tgt_entity.has_method("get_performance_modifier"):
		tgt.stats.performance_modifier = tgt_entity.get_performance_modifier()
	if tgt_entity.has_method("get_blood_volume"):
		tgt.stats.blood_volume = tgt_entity.get_blood_volume()
	elif "blood_volume" in tgt_entity:
		tgt.stats.blood_volume = tgt_entity.blood_volume
	if tgt_entity.has_method("get_total_bleeding_rate"):
		tgt.stats.total_bleeding_rate = tgt_entity.get_total_bleeding_rate()

	var health_after_cut: float = tgt_entity.body_cutting.get(part, 0.0)
	var health_after_blunt: float = tgt_entity.body_blunt.get(part, 0.0)
	var health_after_bone: float = tgt_entity.bone_health.get(part, 0.0) if tgt_entity.get("bone_health") else 0.0
	var part_max: int = tgt_entity.body_max.get(part, 0)
	var part_bone_max: int = tgt_entity.bone_max.get(part, 0) if tgt_entity.get("bone_max") else 0
	var outcome_note: String = outcome
	if outcome == "deflected":
		outcome_note = "deflected (tissue_dmg %.2f < pre_armor*%.2f=%.1f)" % [final_cut + final_blunt, DEFLECTED_DAMAGE_RATIO, pre_armor * DEFLECTED_DAMAGE_RATIO]
	print("[Combat] %s (%s) -> %s (%s) %s: applied cut=%.2f blunt=%.2f bone=%.2f (total %d) | part state: cut %.2f->%.2f blunt %.2f->%.2f bone %.2f->%.2f (max cut/blunt %d bone %d) | outcome: %s" % [atk_name, atk.side, tgt_name, tgt.side, part, final_cut, final_blunt, final_bone, actual_dmg, health_before_cut, health_after_cut, health_before_blunt, health_after_blunt, health_before_bone, health_after_bone, part_max, part_bone_max, outcome_note])

	var result_dict := {"dmg": actual_dmg, "died": false, "part": part, "damage_type": "SPLIT", "health_before_cut": health_before_cut, "health_after_cut": health_after_cut, "health_before_blunt": health_before_blunt, "health_after_blunt": health_after_blunt, "health_before_bone": health_before_bone, "health_after_bone": health_after_bone, "final_cut": final_cut, "final_blunt": final_blunt, "final_bone": final_bone, "outcome": outcome, "was_deflected": take_result.get("was_deflected", false)}
	# Legacy keys for UI that expects single pool
	result_dict["health_before"] = int(roundf(health_before_cut + health_before_blunt))
	result_dict["health_after"] = int(roundf(health_after_cut + health_after_blunt))
	if tgt.node.has_method("is_dead") and tgt.node.is_dead():
		tgt.alive = false
		result_dict.died = true
		var death_reason: String = ""
		if tgt.node.has_method("get_death_reason"):
			death_reason = tgt.node.get_death_reason()
		print("[Combat] DEATH: %s — %s" % [tgt_name, death_reason])
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		w = _check_for_winner()
		if not w.is_empty():
			emit_signal("combat_ended", w, tgt.node)
			stop()
		return
	w = _check_for_winner()
	if not w.is_empty():
		if tgt.node.has_method("is_incapacitated") and tgt.node.is_incapacitated():
			print("[Combat] INCAPACITATED: %s (consciousness < 10%%)" % tgt_name)
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		emit_signal("combat_ended", w, tgt.node)
		stop()
		return
	var rec_dur_final: float = _recovery_duration(intensity, outcome, recovery_mult, perf_mod)
	print("[Combat] Recovery (hit): %s intensity=%.2f outcome=%s recovery_mult=%.2f => duration=%.2fs" % [atk_name, intensity, outcome, recovery_mult, rec_dur_final])
	emit_signal("action_resolved", attacker_id, target_id, result_dict)
	atk.state = STATE_RECOVERING
	atk.state_timer = 0.0
	atk.state_duration = rec_dur_final
	return

# Parry speed (m/s) from same scale as strike velocity; defensive move ~40–60% of max strike (research).
func _get_parry_speed_m_s() -> float:
	return WeaponConstants.VELOCITY_MAX_M_S * PARRY_V_FRACTION_OF_MAX_STRIKE

# Resolve parry using precomputed momentum and capacity (parry wind-up vs attack wind-up timing already applied by caller).
func _resolve_parry_with_momentum(defender_id: int, attacker_id: int, move_id: String, p_a: float, c_d: float) -> void:
	var defender = _get_by_id(defender_id)
	var attacker = _get_by_id(attacker_id)
	if defender == null or attacker == null or attacker.pending_attack.is_empty():
		return
	defender.pending_parry = {}
	var pa = attacker.pending_attack
	var attacker_weapon = attacker.node.get_weapon() if (attacker.node != null and attacker.node.has_method("get_weapon")) else null
	if attacker_weapon == null:
		defender.state = STATE_WAITING
		defender.state_timer = 0.0
		defender.state_duration = 0.0
		_begin_attack_with_target(defender_id, attacker_id, move_id)
		return
	var m_a: float = float(attacker_weapon.mass)
	var attack_instance = AttackInstance.new(pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT), pa.get("intensity", 0.5))
	attack_instance.archetype = pa.get("archetype", {})
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
	var deflected: bool = c_d >= (p_a * PARRY_DEFLECT_THRESHOLD)
	if not deflected:
		var remaining_momentum: float = maxf(0.0, p_a - c_d)
		var v_reduced: float = remaining_momentum / m_a
		var v_min: float = v_intent * PARRY_V_MIN_FRACTION
		attacker.pending_attack["velocity_m_s"] = maxf(v_reduced, v_min)
		defender.state = STATE_WAITING
		defender.state_timer = 0.0
		defender.state_duration = 0.0
		_execute_attack(attacker_id)
		return
	var parry_intensity: float = pa.get("intensity", 0.5)
	var recovery_mult: float = float(pa.get("archetype", {}).get("recovery_multiplier", 1.0))
	var atk_perf: float = 1.0
	if attacker.node != null and attacker.node.has_method("get_performance_modifier"):
		atk_perf = attacker.node.get_performance_modifier()
	var rec_dur_parry: float = _recovery_duration(parry_intensity, "miss", recovery_mult, atk_perf)
	attacker.pending_attack = {}
	attacker.state = STATE_RECOVERING
	attacker.state_timer = 0.0
	attacker.state_duration = rec_dur_parry
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	var atk_name: String = attacker.node.name if attacker.node != null else "id:%d" % attacker_id
	print("[Combat] Parry: %s parried %s (attacker momentum %.1f vs defender capacity %.1f). Attacker recovery: intensity=%.2f => %.2fs" % [def_name, atk_name, p_a, c_d, parry_intensity, rec_dur_parry])
	emit_signal("action_resolved", defender_id, attacker_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "parry_deflect", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	_begin_attack_with_target(defender_id, attacker_id, move_id)

# Parry wind-up completed first: compare full parry capacity vs attack momentum at this moment (attack still building).
func _resolve_parry_parry_ready_first(defender_id: int, attacker_id: int, move_id: String) -> void:
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
		defender.state = STATE_WAITING
		defender.state_timer = 0.0
		defender.state_duration = 0.0
		_begin_attack_with_target(defender_id, attacker_id, move_id)
		return
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
	var v_current: float = v_intent * _velocity_curve_factor(progress)
	var m_a: float = float(attacker_weapon.mass)
	var p_a: float = m_a * v_current
	var defender_weapon = defender.node.get_weapon() if (defender.node != null and defender.node.has_method("get_weapon")) else null
	var m_d: float = float(defender_weapon.mass) if defender_weapon else WeaponConstants.BASELINE_MASS_KG
	var s_d: float = float(defender.stats.get("strength", 10))
	var c_d: float = m_d * _get_parry_speed_m_s() * (s_d / PARRY_STRENGTH_NORM)
	# Pain/consciousness: wounded defenders parry less effectively
	var def_perf_mod: float = 1.0
	if defender.node != null and defender.node.has_method("get_performance_modifier"):
		def_perf_mod = defender.node.get_performance_modifier()
	c_d *= maxf(PERF_MOD_MIN, def_perf_mod)
	if PARRY_TECHNIQUE_VARIANCE > 0.0:
		c_d *= randf_range(1.0 - PARRY_TECHNIQUE_VARIANCE, 1.0 + PARRY_TECHNIQUE_VARIANCE)
	_resolve_parry_with_momentum(defender_id, attacker_id, move_id, p_a, c_d)

# Attack wind-up completed first (attack lands): compare parry capacity scaled by how much of parry wind-up finished vs full attack momentum.
func _resolve_parry_at_impact(attacker_id: int, defender_id: int) -> void:
	var defender = _get_by_id(defender_id)
	var attacker = _get_by_id(attacker_id)
	if defender == null or attacker == null or attacker.pending_attack.is_empty():
		_execute_attack(attacker_id)
		return
	var pp: Dictionary = defender.get("pending_parry", {})
	var move_id: String = pp.get("move_id", "")
	defender.pending_parry = {}
	var parry_progress: float = clampf(defender.state_timer / maxf(0.001, defender.state_duration), 0.0, 1.0)
	var pa = attacker.pending_attack
	var attack_instance = AttackInstance.new(pa.get("attack_type", WeaponConstants.ATTACK_TYPE_CUT), pa.get("intensity", 0.5))
	attack_instance.archetype = pa.get("archetype", {})
	var attacker_weapon = attacker.node.get_weapon() if (attacker.node != null and attacker.node.has_method("get_weapon")) else null
	if attacker_weapon == null:
		defender.state = STATE_WAITING
		defender.state_timer = 0.0
		defender.state_duration = 0.0
		_begin_attack_with_target(defender_id, attacker_id, move_id)
		return
	var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(attacker_weapon, attack_instance)
	var m_a: float = float(attacker_weapon.mass)
	var p_a: float = m_a * v_intent
	var defender_weapon = defender.node.get_weapon() if (defender.node != null and defender.node.has_method("get_weapon")) else null
	var m_d: float = float(defender_weapon.mass) if defender_weapon else WeaponConstants.BASELINE_MASS_KG
	var s_d: float = float(defender.stats.get("strength", 10))
	var c_d_full: float = m_d * _get_parry_speed_m_s() * (s_d / PARRY_STRENGTH_NORM)
	# Pain/consciousness: wounded defenders parry less effectively
	var def_perf_mod: float = 1.0
	if defender.node != null and defender.node.has_method("get_performance_modifier"):
		def_perf_mod = defender.node.get_performance_modifier()
	c_d_full *= maxf(PERF_MOD_MIN, def_perf_mod)
	if PARRY_TECHNIQUE_VARIANCE > 0.0:
		c_d_full *= randf_range(1.0 - PARRY_TECHNIQUE_VARIANCE, 1.0 + PARRY_TECHNIQUE_VARIANCE)
	var c_d: float = c_d_full * parry_progress
	defender.state = STATE_WAITING
	defender.state_timer = 0.0
	defender.state_duration = 0.0
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	print("[Combat] Parry at impact: %s parry was %.0f%% in place (capacity %.1f vs momentum %.1f)" % [def_name, parry_progress * 100.0, c_d, p_a])
	_resolve_parry_with_momentum(defender_id, attacker_id, move_id, p_a, c_d)

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
