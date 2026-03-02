extends Node

signal turn_ready(combatant_id)
signal action_resolved(attacker_id, target_id, result)
signal combat_ended(winner_side, defeated_node)
signal enemies_eliminated(winner_side)
signal combatant_health_changed(combatant_id)

var combatants := []
var medical_phase: bool = false
var medical_phase_winner: String = ""

const _Bleeding := preload("res://core/BleedingConstants.gd")
const _AttackResolver := preload("res://combat/AttackResolver.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine: waiting (gauge filling) -> wind_up (swing until impact) | medical_wind_up -> recovering (follow-through after hit/deflect/miss/medical). Parry is passive (A4v3) only.
# receiving_medical_attention: target of ally's medical action; gauge stays full (readied), cannot act until care finishes.
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_MEDICAL_WIND_UP := "medical_wind_up"
const STATE_RECOVERING := "recovering"
const STATE_RECEIVING_MEDICAL_ATTENTION := "receiving_medical_attention"
const STATE_COWERING := "cowering"  # no functional arms; counts as incapacitated until arms restored
const STATE_DEAD := "dead"

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
const RECOVERY_EXTRA_DEFLECTED_S := 0.15   # full deflect: no damage, short recovery
const RECOVERY_EXTRA_GLANCING_S := 0.25    # glancing: some damage got through
const RECOVERY_EXTRA_MISS_S := 0.5

# Leg functionality scales attack wind-up only (positioning/footwork). Min clamp avoids divide-by-zero.
const WINDUP_LEG_MIN := 0.2

# Miss chance (0-1). Rolled before damage; miss = no contact, longest recovery.
const MISS_CHANCE_BASE := 0.06
# Attacker perception: 100 = 1.0; 50 = 0.8, 150 = 1.2 (aim/focus).
const HIT_CHANCE_PERCEPTION_MIN := 0.8
const HIT_CHANCE_PERCEPTION_MAX := 1.2
# Deflected = all damage avoided (armor/angle); no tissue damage applied.
# Glancing = armor absorbed most but some got through; tissue_dmg < pre_armor * this ratio.
const GLANCING_DAMAGE_RATIO := 0.25

# Intensity (0–1): derived from power and follow_through per attack; drives velocity, wind-up, recovery. Strength biases toward higher commitment.
const INTENSITY_STRENGTH_SCALE := 0.5
const INTENSITY_STRENGTH_NORM := 100.0        # 100 = average (same scale as other stats)
const INTENSITY_STRENGTH_BIAS := 0.35         # blend: lerp(rolled, strength_based, this)
const INTENSITY_RANDOM_RANGE := 0.2
const RECOVERY_AFTER_MEDICAL_S := 0.5  # short recovery after applying bandage/tourniquet/direct pressure

# Medical moves that can be applied to self or allies. Add new medical actions here; extend _get_ally_medical_actions, _start_medical_action, and wind-up completion.
const MEDICAL_MOVE_IDS: Array[String] = ["bandage_self", "pack_wound", "apply_direct_pressure", "apply_tourniquet"]
# Config for wind-up medical actions: move_id -> {duration_method, duration_takes_part, target_method, outcome}. Instant actions (e.g. direct_pressure) are handled separately.
const _MEDICAL_WIND_UP_CONFIG: Dictionary = {
	"bandage_self": {"duration_method": "get_bandage_application_time_seconds_for_part", "duration_takes_part": true, "target_method": "apply_bandage", "outcome": "bandaged"},
	"pack_wound": {"duration_method": "get_packing_application_time_seconds_for_part", "duration_takes_part": true, "target_method": "apply_packing", "outcome": "packed"},
	"apply_tourniquet": {"duration_method": "get_tourniquet_application_time_seconds", "duration_takes_part": false, "target_method": "apply_tourniquet", "outcome": "tourniquet_applied"}
}

# --- Parry: physics and timings (derived, not magic numbers) ---
# Impulse balance: p_a = m_a * v_current (kg·m/s); v_current from velocity curve (progress²), so early parries face less momentum. c_d = m_d * v_parry * (strength/PARRY_STRENGTH_NORM). Full deflect when c_d >= p_a * PARRY_DEFLECT_THRESHOLD; else partial (remaining p → impact v = remaining/m_a).
# Parry speed: defensive move is positioning, not full strike. Strike 17–24 m/s; parry ~40–60% of that. v_parry = VELOCITY_MAX_M_S * PARRY_V_FRACTION (same scale as attacks).
# Parry wind-up: reaction (fixed, cognitive) + blade movement (scaled by weapon mass and strength). Lighter weapon / stronger user = faster into parry position.
# Tuning: quadratic curve makes early parries easier (lower p_a). If full deflects feel too common, raise PARRY_DEFLECT_THRESHOLD (e.g. 1.1) or soften curve in _velocity_curve_factor (e.g. progress^1.5).
const PARRY_V_FRACTION_OF_MAX_STRIKE := 0.5   # parry speed = WeaponConstants.VELOCITY_MAX_M_S * this (~10 m/s)
const PARRY_STRENGTH_NORM := 100.0            # (strength/this) → 100 = average (same scale as other stats: 50–150)
const PARRY_DEFLECT_THRESHOLD := 1.0          # full deflect when c_d >= p_a * this (1.0 = impulse match)
const PARRY_TECHNIQUE_VARIANCE := 0.1         # ±fraction on capacity (timing/placement)
const PARRY_V_MIN_FRACTION := 0.2             # partial parry: impact v >= v_intent * this (residual glancing hit)
const PARRY_V_MIN_NEAR_DEFLECT := 0.1         # when c_d almost matched p_a, residual velocity floor (softer partial)
# A4v3 passive parry: time_to_react (s) needed for 100% parry capacity; less time = scale capacity down.
const PASSIVE_PARRY_MIN_TIME_FOR_FULL_S := 0.25
const PARRY_REACTION_S := 0.22                # reaction to initiate parry (s); same for all (cognitive)
const PARRY_BLADE_MOVEMENT_S := 0.13          # base time to move blade into intercept (s); scaled by mass/strength
const PARRY_MOVEMENT_MASS_STRENGTH_MIN := 0.5 # movement mult clamp: light weapon / strong user (min = faster parry)
const PARRY_MOVEMENT_MASS_STRENGTH_MAX := 2.0 # movement mult clamp: heavy weapon / weak user (max = slower parry)
# Pain/consciousness: scale durations and capacities; floor matches PainConsciousnessConstants.MIN_PERFORMANCE_MODIFIER
const PERF_MOD_MIN := 0.35

# 3.2/3.3/3.4/3.5: Recovery phases, commitment window, state-dependent parry, off balance.
# Commitment (3.3): defender's reaction window = wind_up * (1 - this); first fraction is "telegraph" before attack counts.
const COMMITMENT_FRACTION := 0.2
# Readiness (3.2/3.4): in RECOVERING, parry capacity scaled by lerp(early, late) over recovery progress. WAITING = 1.0.
const RECOVERY_READINESS_EARLY := 0.5
const RECOVERY_READINESS_LATE := 0.85
# Off balance (3.5): after miss or full parry deflect, attacker is off balance for this many seconds; parry capacity mult while defender.
const OFF_BALANCE_DURATION_S := 0.4
const OFF_BALANCE_PARRY_CAPACITY_MULT := 0.7
# Post-deflect bonus: defender gets this many seconds of +10% parry capacity after a full deflect.
const PARRY_BONUS_AFTER_DEFLECT_S := 2.0
# Defender chooses dodge OR parry (not both). Parry if noticed in time and opponent not much stronger; else dodge.
# If p_a > c_d * this, prefer dodge (opponent much stronger → dodging more efficient than attempting parry).
const PARRY_DODGE_STRENGTH_RATIO := 1.4

## Returns the node that holds health/wounds (CoreEntity for enemies; CombatBody for Character). Use for all health reads.
func _get_entity(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e = node.get_medical_entity()
		return e if e != null else node
	return node

## 3.2/3.4: Readiness multiplier for passive parry (no guard variable). WAITING = 1.0; RECOVERING = lerp(early, late) by progress.
func _get_passive_parry_readiness(c: Dictionary) -> float:
	if c.state == STATE_WAITING:
		return 1.0
	if c.state == STATE_RECOVERING:
		var dur: float = c.get("state_duration", 0.001)
		var t: float = c.get("state_timer", 0.0)
		var progress: float = clampf(t / dur, 0.0, 1.0)
		return lerpf(RECOVERY_READINESS_EARLY, RECOVERY_READINESS_LATE, progress)
	return 0.0

## 3.5: True if combatant is still in "off balance" window (after miss or parry deflect).
func _is_off_balance(c: Dictionary) -> bool:
	var until: float = c.get("off_balance_until", -1.0)
	return until > 0.0 and Time.get_ticks_msec() / 1000.0 < until

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
	# Keep combat-relevant attributes in sync (parry capacity uses strength; reaction time read live from node).
	if "strength" in entity:
		c.stats.strength = entity.strength
	if "agility" in entity:
		c.stats.agility = entity.agility
	if "perception" in entity:
		c.stats.perception = entity.perception

func _read_stats_from(node: Node) -> Dictionary:
	# Core stats: 50–150, 100 = average (SpeciesResource). Use stat/100.0 for multipliers.
	var s := {
		"body_cutting": {},
		"body_blunt": {},
		"body_max": {},
		"bone_health": {},
		"bone_max": {},
		"strength": 100,
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
		"pending_attack": {},
		"receiving_medical_count": 0
	})
	# Connect health_changed so UI can refresh when consciousness/pain/blood changes
	if entity != null and entity.has_signal("health_changed"):
		entity.health_changed.connect(_on_entity_health_changed.bind(id))
	return id

func _on_entity_health_changed(combatant_id: int) -> void:
	emit_signal("combatant_health_changed", combatant_id)

func start():
	medical_phase = false
	medical_phase_winner = ""
	set_process(true)

func stop():
	set_process(false)

## True when no one on the winning side is in medical danger AND all wounds are comprehensively treated (bandaged, packed, or tourniqueted). Used to gate "End battle" during medical phase.
func can_end_medical_phase() -> bool:
	return _MedicalPhase.can_end_medical_phase(self)

## True if combatant has any wounded part that is not comprehensively treated (bandaged, packed, or tourniqueted). Direct pressure alone does not count.
func _has_untreated_wounds(c: Dictionary) -> bool:
	return _MedicalPhase.has_untreated_wounds(self, c)

## Called when player clicks "End battle" during medical phase. Emits combat_ended and stops.
func finish_battle() -> void:
	emit_signal("combat_ended", medical_phase_winner, null)
	stop()

## Resets a combatant's gauge so they can "skip" when they have no available actions (e.g. medical phase with no wounded allies).
func skip_turn(combatant_id: int) -> void:
	var c = _get_by_id(combatant_id)
	if c != null and c.state == STATE_WAITING:
		c.gauge = 0.0

## When player wins: enter medical phase, emit enemies_eliminated, keep battle running. When enemy wins: end immediately.
func _end_combat_phase(winner: String, defeated_node: Node) -> void:
	if winner == "enemy":
		emit_signal("combat_ended", winner, defeated_node)
		stop()
	else:
		medical_phase = true
		medical_phase_winner = winner
		emit_signal("enemies_eliminated", winner)

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

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Attack moves (non-parry) and medical when in danger. Parry is passive only (A4v3).
func _is_in_medical_danger(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_medical_danger(self, c)

## Stricter than _is_in_medical_danger: about to bleed out. Must self-treat; cannot help others.
func _is_in_immediate_peril(c: Dictionary) -> bool:
	return _MedicalPhase.is_in_immediate_peril(self, c)

## True when entity has permanently left immediate peril (permanent bleeding rate low enough to recover).
func _has_left_immediate_peril_permanently(c: Dictionary) -> bool:
	return _MedicalPhase.has_left_immediate_peril_permanently(self, c)

func _get_medical_urgency(c: Dictionary) -> float:
	return _MedicalPhase.get_medical_urgency(self, c)

static func _is_medical_move(move_id: String) -> bool:
	return move_id in MEDICAL_MOVE_IDS

## When bandage/pack/tourniquet fails: track failed part on target; if no one else can help, set pending_retry so performer retries.
func _track_medical_failure_and_maybe_retry(performer: Dictionary, target: Dictionary, part: String, target_cid: int) -> void:
	if target == null:
		return
	var failed: Array = target.get("failed_medical_parts", [])
	if part not in failed:
		failed.append(part)
	target.failed_medical_parts = failed
	var others: int = _count_others_who_can_perform_medical_on_target(performer.id, target_cid)
	if others <= 0:
		performer.pending_retry = {"target_id": target_cid, "part": part}

## Count other combatants (excluding exclude_id) who can perform medical on target_id. Used to decide if performer should retry after failure.
func _count_others_who_can_perform_medical_on_target(exclude_id: int, target_id: int) -> int:
	var count: int = 0
	for other in combatants:
		if other.id == exclude_id or not other.alive or other.side != medical_phase_winner or other.node == null:
			continue
		if other.node.has_method("is_incapacitated") and other.node.is_incapacitated():
			continue
		var acts: Array = get_available_actions(other.id)
		for a in acts:
			if a.get("target_id", -1) == target_id:
				count += 1
				break
	return count

## Parts currently being treated on combatant_id by allies (bandage/tourniquet wind-up). Used so patient can hold pressure on other wounds.
func _get_parts_being_treated_on(combatant_id: int) -> Array:
	var out: Array = []
	for other in combatants:
		if other.state != STATE_MEDICAL_WIND_UP:
			continue
		var pm = other.get("pending_medical", {})
		if pm.get("target_combatant_id", -1) == combatant_id:
			var part: String = pm.get("target_part", "")
			if not part.is_empty() and part not in out:
				out.append(part)
	return out

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	return _MedicalPhase.get_ally_medical_actions(self, performer, ally, part)

func get_available_actions(combatant_id: int) -> Array:
	var c = _get_by_id(combatant_id)
	if c == null or not c.alive or c.gauge < 100.0:
		return []
	if c.state != STATE_WAITING and c.state != STATE_RECEIVING_MEDICAL_ATTENTION:
		return []
	if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
		return []
	var actions: Array = []
	# Receiving medical care: can hold/switch direct pressure on wounds NOT being treated by ally and NOT already having pressure
	if c.state == STATE_RECEIVING_MEDICAL_ATTENTION and medical_phase and c.side == medical_phase_winner:
		if c.node != null and c.node.has_method("can_apply_direct_pressure") and c.node.has_method("get_wounded_parts"):
			var parts_being_treated: Array = _get_parts_being_treated_on(combatant_id)
			var entity = _get_entity(c.node)
			for part in c.node.get_wounded_parts():
				if part.is_empty() or part in parts_being_treated:
					continue
				if entity != null and entity.has_method("has_direct_pressure_on_part") and entity.has_direct_pressure_on_part(part):
					continue  # already holding pressure on this part
				if entity != null and entity.has_method("can_apply_direct_pressure") and entity.can_apply_direct_pressure(part):
					actions.append({ "target_id": combatant_id, "move_id": "apply_direct_pressure", "target_part": part })
		return actions
	# Combat phase: attacks only (fight to the death, no medical during combat).
	# Medical phase: medical only for winning side (no enemies left to attack).
	if not medical_phase:
		# No attack options if combatant has no functional arm (avoids wind-up then skip at execute).
		var can_attack: bool = true
		if c.node != null and c.node.has_method("get_attacking_arm"):
			can_attack = not c.node.get_attacking_arm().is_empty()
		if can_attack:
			var weapon = c.node.get_weapon() if (c.node != null and c.node.has_method("get_weapon")) else null
			if weapon != null and weapon.has_method("get_available_attack_types"):
				var move_ids: Array = weapon.get_available_attack_types()
				for move_id in move_ids:
					if WeaponConstants.is_parry_move(move_id):
						continue
					for opp in combatants:
						if not opp.alive or opp.side == c.side:
							continue
						actions.append({ "target_id": opp.id, "move_id": move_id })
	else:
		# Medical phase: immediate peril = self-treat only. Injured-but-stable = can help others, prioritize critical allies.
		if c.side == medical_phase_winner and c.node != null and c.node.has_method("can_apply_direct_pressure"):
			var immediate_peril: bool = _is_in_immediate_peril(c)
			# Clear failed_medical_parts when ally has permanently left peril (bleeding slowed by bandage/pack/tourniquet; direct pressure doesn't count)
			for ally in combatants:
				if not ally.alive or ally.side != c.side:
					continue
				if _has_left_immediate_peril_permanently(ally) and ally.get("failed_medical_parts", []).size() > 0:
					ally.failed_medical_parts = []
					# Clear pending_retry on anyone who was going to retry this target
					for other in combatants:
						var pr = other.get("pending_retry", {})
						if not pr.is_empty() and pr.get("target_id", -1) == ally.id:
							other.pending_retry = {}
			for ally in combatants:
				if not ally.alive or ally.side != c.side or ally.node == null:
					continue
				if ally.side != medical_phase_winner:
					continue
				if not ally.node.has_method("get_wounded_parts"):
					continue
				# Immediate peril: must self-treat first. Injured-but-stable: can treat any ally (prioritize critical via pick_weighted_action).
				if immediate_peril and ally.id != c.id:
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
		print("[Combat] get_available_actions: combatant_id=%d => %d total (%d medical: bandage/pack/direct_pressure/tourniquet)" % [combatant_id, actions.size(), medical_count])
	return actions

# Pick one action from the list. Medical: weight by TARGET's urgency (prioritize treating most critical ally). Attacks: 1.
# For receiving care self direct pressure: weight by part's bleeding rate (prioritize most serious wound).
# When pending_retry: performer is the only one who can help; strongly prefer retrying the failed part.
func pick_weighted_action(actions: Array, combatant_id: int = -1) -> Dictionary:
	if actions.is_empty():
		return {}
	var total: float = 0.0
	for a in actions:
		var mid: String = a.get("move_id", "")
		if _is_medical_move(mid):
			var tgt = _get_by_id(a.get("target_id", -1))
			var urgency: float = _get_medical_urgency(tgt) if tgt != null else 0.0
			var w: float = 1.0 + urgency * (_MedicalPhase.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
			# Self direct pressure while receiving care: prioritize part with highest bleeding
			if mid == "apply_direct_pressure" and a.get("target_id") == combatant_id and tgt != null:
				var part: String = a.get("target_part", "")
				if not part.is_empty() and tgt.node != null:
					var entity = _get_entity(tgt.node)
					if entity != null and entity.has_method("get_bleeding_rate_for_part"):
						var rate: float = entity.get_bleeding_rate_for_part(part)
						w += rate * 2.0
			# Pending retry: only one who can help; strongly prefer retrying the failed part.
			var pr = _get_by_id(combatant_id)
			var pending = pr.get("pending_retry", {}) if pr != null else {}
			if not pending.is_empty() and pending.get("target_id", -1) == a.get("target_id", -1) and pending.get("part", "") == a.get("target_part", ""):
				if tgt != null and _is_in_immediate_peril(tgt):
					w *= 20.0  # Strongly prefer retry when target is still in peril
			total += w
		else:
			total += 1.0
	var r: float = randf() * total
	for a in actions:
		var mid: String = a.get("move_id", "")
		var w: float
		if _is_medical_move(mid):
			var tgt = _get_by_id(a.get("target_id", -1))
			var urgency: float = _get_medical_urgency(tgt) if tgt != null else 0.0
			w = 1.0 + urgency * (_MedicalPhase.MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
			if mid == "apply_direct_pressure" and a.get("target_id") == combatant_id and tgt != null:
				var part: String = a.get("target_part", "")
				if not part.is_empty() and tgt.node != null:
					var entity = _get_entity(tgt.node)
					if entity != null and entity.has_method("get_bleeding_rate_for_part"):
						var rate: float = entity.get_bleeding_rate_for_part(part)
						w += rate * 2.0
			var pr = _get_by_id(combatant_id)
			var pending = pr.get("pending_retry", {}) if pr != null else {}
			if not pending.is_empty() and pending.get("target_id", -1) == a.get("target_id", -1) and pending.get("part", "") == a.get("target_part", ""):
				if tgt != null and _is_in_immediate_peril(tgt):
					w *= 20.0
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
			c.state = STATE_DEAD
			var death_reason: String = ""
			if c.node.has_method("get_death_reason"):
				death_reason = c.node.get_death_reason()
			print("[Combat] DEATH (tick): %s — %s" % [c.node.name if c.node else "id:%d" % c.id, death_reason])
			emit_signal("action_resolved", c.id, -1, {"dmg": 0, "died": true, "part": "", "damage_type": "", "outcome": "bled_out", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
			victor = _check_for_winner()
			if not victor.is_empty():
				_end_combat_phase(victor, c.node)
			return
	victor = _check_for_winner()
	if not victor.is_empty():
		# Already in medical phase: don't re-emit enemies_eliminated (would spam combat log every frame)
		if not (medical_phase and victor == medical_phase_winner):
			_end_combat_phase(victor, null)
			return
	for c in combatants:
		if not c.alive:
			continue
		if c.node != null and c.node.has_method("is_incapacitated") and c.node.is_incapacitated():
			# Cowering: when arm functionality returns (e.g. after medical/healing), leave cowering state
			if c.state == STATE_COWERING and c.node.has_method("is_cowering") and not c.node.is_cowering():
				c.state = STATE_WAITING
				c.gauge = 0.0
				var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
				print("[Combat] %s no longer cowering (arm functionality returned)." % who_name)
			else:
				continue  # incapacitated: no gauge fill, cannot act
		# Medical wind-up: cancel if target (ally) died during wind-up
		if c.state == STATE_MEDICAL_WIND_UP:
			var pm_check = c.get("pending_medical", {})
			var tgt_cid_check: int = pm_check.get("target_combatant_id", c.id)
			if tgt_cid_check != c.id:
				var tgt_check = _get_by_id(tgt_cid_check)
				if tgt_check == null or not tgt_check.alive or (tgt_check.node != null and tgt_check.node.has_method("is_dead") and tgt_check.node.is_dead()):
					if tgt_check != null:
						tgt_check.receiving_medical_count = max(0, tgt_check.get("receiving_medical_count", 0) - 1)
					c.pending_medical = {}
					c.state = STATE_WAITING
					c.state_timer = 0.0
					c.state_duration = 0.0
					var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
					print("[Combat] Medical cancelled: %s (target died during wind-up)" % who_name)
					continue
		if c.state == STATE_RECEIVING_MEDICAL_ATTENTION:
			c.gauge = 100.0  # Keep readied; can hold/switch direct pressure on other wounds
			if c.side == "player":
				# Throttle: don't re-emit until previous turn was resolved (prevents log spam); then pace with RECOVERY_AFTER_MEDICAL_S
				var cooldown: float = c.get("receiving_care_action_cooldown", 0.0) - delta
				c.receiving_care_action_cooldown = cooldown
				var pending: bool = c.get("receiving_care_turn_pending", false)
				if cooldown <= 0.0 and not pending:
					var recv_actions: Array = get_available_actions(c.id)
					if not recv_actions.is_empty():
						emit_signal("turn_ready", c.id)
						c.receiving_care_turn_pending = true
						c.receiving_care_action_cooldown = RECOVERY_AFTER_MEDICAL_S
			else:
				# AI: throttle so they don't spam switch every frame
				var cooldown: float = c.get("receiving_care_action_cooldown", 0.0) - delta
				c.receiving_care_action_cooldown = cooldown
				if cooldown <= 0.0:
					var actions: Array = get_available_actions(c.id)
					if not actions.is_empty():
						var choice = pick_weighted_action(actions, c.id)
						var opts: Dictionary = {}
						if choice.get("target_part", "") != "":
							opts["target_part"] = choice.target_part
						resolve_action(c.id, c.id, choice.get("move_id", ""), opts)
						c.receiving_care_action_cooldown = RECOVERY_AFTER_MEDICAL_S
		elif c.state == STATE_WAITING:
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
							# No actions can mean no weapon or no functional arm; don't wind-up just to skip at execute.
							var can_attack: bool = true
							if c.node != null and c.node.has_method("get_attacking_arm"):
								can_attack = not c.node.get_attacking_arm().is_empty()
							if can_attack:
								_begin_attack_with_target(c.id, tgt.id)
							else:
								var who_skip: String = c.node.name if (c.node != null) else "id:%d" % c.id
								print("[Combat] %s has no functional arm; skip turn (short recovery)." % who_skip)
								c.state = STATE_RECOVERING
								c.state_timer = 0.0
								c.state_duration = 0.8
								c.gauge = 0.0
								c.pending_attack = {}
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
							var perf_entity = _get_entity(c.node)
							var eff: float = perf_entity.get_medical_effectiveness() if (perf_entity != null and perf_entity.has_method("get_medical_effectiveness")) else 1.0
							var result = null
							if target_method == "apply_bandage":
								result = tgt_entity.call(target_method, part, eff)
							elif target_method == "apply_packing":
								result = tgt_entity.call(target_method, part, eff)
							elif target_method == "apply_tourniquet":
								result = tgt_entity.call(target_method, part, eff)
							else:
								result = tgt_entity.call(target_method, part)
							var outcome: String
							if target_method == "apply_bandage":
								outcome = "bandaged" if result == true else "bandage_failed"
								print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
								emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
								if result != true:
									_track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
								else:
									c.pending_retry = {}
							elif target_method == "apply_packing":
								outcome = "packed" if result == true else "packing_failed"
								print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
								emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
								if result != true:
									_track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
								else:
									c.pending_retry = {}
							elif target_method == "apply_tourniquet":
								outcome = "tourniquet_applied" if result == true else "tourniquet_failed"
								print("[Combat] Medical complete: %s %s on %s => %s, recovery %.1fs" % [who_m, med_id, part, outcome, med_rec_dur])
								emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false, "effectiveness": eff})
								if result != true:
									_track_medical_failure_and_maybe_retry(c, tgt_c, part, tgt_cid)
								else:
									c.pending_retry = {}
							elif result != false:
								outcome = wind_up_cfg.get("outcome", med_id)
								print("[Combat] Medical complete: %s %s on %s => recovery %.1fs" % [who_m, med_id, part, med_rec_dur])
								emit_signal("action_resolved", c.id, tgt_cid, {"outcome": outcome, "part": part, "dmg": 0, "died": false})
				# Target finishes receiving care: ready to act immediately
				if tgt_c != null and tgt_cid != c.id:
					tgt_c.receiving_medical_count = max(0, tgt_c.get("receiving_medical_count", 0) - 1)
					if tgt_c.receiving_medical_count <= 0:
						tgt_c.state = STATE_WAITING
						tgt_c.gauge = 100.0
						if tgt_c.side == "player":
							emit_signal("turn_ready", tgt_cid)
				c.state = STATE_RECOVERING
				c.state_timer = 0.0
				c.state_duration = med_rec_dur
		elif c.state == STATE_RECOVERING:
			c.gauge = 0.0  # Action bar does not fill while recovering
			c.state_timer += delta
			if c.state_timer >= c.state_duration:
				c.gauge = 0.0
				c.state_timer = 0.0
				c.state_duration = 0.0
				c.pending_attack = {}
				# No functional arms -> cowering (counts as incapacitated until arms restored)
				if c.node != null and c.node.has_method("get_attacking_arm") and c.node.get_attacking_arm().is_empty():
					c.state = STATE_COWERING
					var who_name: String = c.node.name if c.node != null else "id:%d" % c.id
					print("[Combat] %s is cowering (no functional arms)." % who_name)
				else:
					c.state = STATE_WAITING

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null or atk.gauge < 100.0:
		return
	# Receiving care: can hold/switch direct pressure on other wounds (no state change, no gauge drain)
	if atk.state == STATE_RECEIVING_MEDICAL_ATTENTION and move_id == "apply_direct_pressure" and target_id == attacker_id:
		atk.receiving_care_turn_pending = false  # Consumed this turn (success or fail); allow next turn_ready after cooldown
		atk.receiving_care_action_cooldown = RECOVERY_AFTER_MEDICAL_S  # Pace next opportunity
		var part: String = str(options.get("target_part", ""))
		if part.is_empty():
			return
		var parts_being_treated: Array = _get_parts_being_treated_on(attacker_id)
		if part in parts_being_treated:
			return
		var entity = _get_entity(atk.node)
		if entity != null and entity.has_method("apply_direct_pressure") and entity.apply_direct_pressure(part):
			var who: String = atk.node.name if atk.node != null else "id:%d" % attacker_id
			print("[Combat] %s (receiving care) holding direct pressure on %s" % [who, part])
			emit_signal("action_resolved", attacker_id, attacker_id, {"outcome": "direct_pressure", "part": part, "dmg": 0, "died": false})
		return
	if atk.state != STATE_WAITING:
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
	# Normal attack: clear direct pressure (new action), then start attack
	if atk.node != null and atk.node.has_method("clear_direct_pressure"):
		if atk.node.has_method("is_applying_direct_pressure") and atk.node.is_applying_direct_pressure():
			print("[Combat] %s taking another action => clear_direct_pressure (was holding %s)" % [atk.node.name if atk.node else "id:%d" % attacker_id, atk.node.get_direct_pressure_part() if atk.node.has_method("get_direct_pressure_part") else "?"])
		atk.node.clear_direct_pressure()
	_begin_attack_with_target(attacker_id, target_id, move_id)

func _intensity_from_stats(c: Dictionary) -> float:
	var str_val: float = float(c.stats.get("strength", 100))
	var base: float = 0.2 + INTENSITY_STRENGTH_SCALE * (str_val / INTENSITY_STRENGTH_NORM)
	return clampf(base + randf_range(-INTENSITY_RANDOM_RANGE, INTENSITY_RANDOM_RANGE), 0.1, 1.0)

func _wind_up_duration(intensity: float, windup_multiplier: float = 1.0) -> float:
	return (WIND_UP_BASE_S + WIND_UP_SCALE_S * intensity) * maxf(0.5, windup_multiplier)

# Velocity curve over wind-up progress (0 = swing start, 1 = impact). Peak at 1.0 so impact uses full velocity.
# Quadratic (p²): blade accelerates into impact; early parry meets less momentum than linear.
static func _velocity_curve_factor(progress: float) -> float:
	var p: float = clampf(progress, 0.0, 1.0)
	return p * p

# Agility shortens recovery (higher = faster back to ready). agility 100 = 1.0; 50 = 0.7, 150 = 1.3.
const RECOVERY_AGILITY_MIN := 0.7
const RECOVERY_AGILITY_MAX := 1.3
func _recovery_duration(intensity: float, outcome: String, recovery_multiplier: float = 1.0, perf_mod: float = 1.0, agility: int = 100) -> float:
	var commitment: float = intensity
	var extra: float = RECOVERY_EXTRA_HIT_S
	if outcome == "deflected":
		extra = RECOVERY_EXTRA_DEFLECTED_S
	elif outcome == "glancing":
		extra = RECOVERY_EXTRA_GLANCING_S
	elif outcome == "miss" or outcome == "dodge":
		extra = RECOVERY_EXTRA_MISS_S
	var base: float = (RECOVERY_BASE_S + RECOVERY_COMMITMENT_SCALE_S * commitment + extra) * maxf(0.5, recovery_multiplier)
	# Pain/consciousness: wounded entities recover slower
	if perf_mod > 0.0:
		base /= maxf(PERF_MOD_MIN, perf_mod)
	# Agility: higher agility shortens recovery
	base /= clampf(float(agility) / 100.0, RECOVERY_AGILITY_MIN, RECOVERY_AGILITY_MAX)
	return base

func _start_medical_action(combatant_id: int, target_combatant_id: int, medical_id: String, target_part: String) -> void:
	var c = _get_by_id(combatant_id)
	var target_node = _get_by_id(target_combatant_id)
	if c == null or target_node == null or target_node.node == null:
		return
	# Clear pending_retry when starting a different action (e.g. helping another ally)
	var pr = c.get("pending_retry", {})
	if not pr.is_empty() and (pr.get("target_id", -1) != target_combatant_id or pr.get("part", "") != target_part):
		c.pending_retry = {}
	var who_name: String = c.node.name if (c.node != null) else "id:%d" % combatant_id
	# Bandage/tourniquet: performer stops holding direct pressure on anyone (new action)
	if medical_id == "bandage_self" or medical_id == "pack_wound" or medical_id == "apply_tourniquet":
		if c.node != null and c.node.has_method("clear_direct_pressure"):
			c.node.clear_direct_pressure()
		# Apply direct pressure to the part being bandaged/tourniqueted during wind-up (reduces bleeding while preparing)
		if not target_part.is_empty():
			var tgt_entity = _get_entity(target_node.node)
			var performer_entity = _get_entity(c.node)
			if tgt_entity != null and tgt_entity.has_method("get_wounds") and tgt_entity.get_wounds().has(target_part):
				if target_combatant_id == combatant_id:
					if tgt_entity.has_method("apply_direct_pressure") and tgt_entity.apply_direct_pressure(target_part):
						print("[Combat] Medical: %s applying direct pressure on %s during %s wind-up" % [who_name, target_part, medical_id])
				else:
					if tgt_entity.has_method("apply_direct_pressure_from_ally") and tgt_entity.apply_direct_pressure_from_ally(target_part, performer_entity):
						if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
							performer_entity.direct_pressure_on_ally = {"node": tgt_entity, "part": target_part}
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
			var tgt_ent = _get_entity(target_node.node)
			var performer_entity = _get_entity(c.node)
			if tgt_ent != null and tgt_ent.has_method("apply_direct_pressure_from_ally") and tgt_ent.apply_direct_pressure_from_ally(target_part, performer_entity):
				applied = true
				if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
					performer_entity.direct_pressure_on_ally = {"node": tgt_ent, "part": target_part}
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
	var dur_takes_part: bool = wind_up_cfg.get("duration_takes_part", false)
	var target_entity = _get_entity(target_node.node)
	if not dur_method.is_empty() and target_entity != null and target_entity.has_method(dur_method):
		if dur_takes_part and not target_part.is_empty():
			duration = target_entity.call(dur_method, target_part)
		else:
			duration = target_entity.call(dur_method)
	if duration <= 0.0 and not wind_up_cfg.is_empty():
		duration = 4.0  # fallback for custom entities
	# Pain/consciousness: wounded entities take longer to apply medical actions
	var perf_mod: float = 1.0
	if c.node != null and c.node.has_method("get_performance_modifier"):
		perf_mod = c.node.get_performance_modifier()
	if perf_mod > 0.0:
		duration /= maxf(PERF_MOD_MIN, perf_mod)
	# Intelligence (medical effectiveness): higher INT shortens medical wind-up
	var perf_entity = _get_entity(c.node)
	var med_eff: float = perf_entity.get_medical_effectiveness() if (perf_entity != null and perf_entity.has_method("get_medical_effectiveness")) else 1.0
	if med_eff > 0.0:
		duration /= maxf(0.5, med_eff)
	print("[Combat] Medical: %s starting %s on part=%s => wind_up=%.1fs" % [who_name, medical_id, target_part, duration])
	c.gauge = 0.0
	c.state = STATE_MEDICAL_WIND_UP
	c.state_timer = 0.0
	c.state_duration = duration
	c.pending_medical = {"medical_id": medical_id, "target_part": target_part, "target_combatant_id": target_combatant_id}
	# Target (ally) enters receiving_medical_attention: gauge full, cannot act until care finishes
	if target_combatant_id != combatant_id:
		target_node.receiving_medical_count = target_node.get("receiving_medical_count", 0) + 1
		target_node.state = STATE_RECEIVING_MEDICAL_ATTENTION
		target_node.gauge = 100.0

func _begin_attack_with_target(attacker_id: int, target_id: int, move_id: String = "") -> void:
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id)
	if atk == null or tgt == null or not tgt.alive:
		return
	if atk.node != null and atk.node.has_method("get_attacking_arm") and atk.node.get_attacking_arm().is_empty():
		var atk_name_skip: String = atk.node.name if atk.node != null else "id:%d" % attacker_id
		print("[Combat] %s has no functional arm; skip attack (short recovery)." % atk_name_skip)
		atk.state = STATE_RECOVERING
		atk.state_timer = 0.0
		atk.state_duration = 0.8
		atk.gauge = 0.0
		atk.pending_attack = {}
		return
	# Power and follow_through (0.2–1.0) per attack; intensity drives velocity, wind-up, and recovery. Strength biases toward higher commitment.
	var power: float = randf_range(POWER_MIN, POWER_MAX)
	var follow_through: float = randf_range(FOLLOW_THROUGH_MIN, FOLLOW_THROUGH_MAX)
	var rolled_intensity: float = (0.5 + 0.5 * power) * (0.5 + 0.5 * follow_through)
	var strength_intensity: float = _intensity_from_stats(atk)
	var intensity: float = clampf(lerpf(rolled_intensity, strength_intensity, INTENSITY_STRENGTH_BIAS), INTENSITY_MIN, 1.0)
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
	# Agility: higher agility shortens wind-up (faster into position)
	var atk_agi: int = atk.stats.get("agility", 100)
	wind_up_s /= clampf(float(atk_agi) / 100.0, 0.7, 1.3)
	atk.gauge = 0.0
	atk.state = STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = wind_up_s
	atk.pending_attack = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype, "wind_up_duration": wind_up_s}
	var atk_name_log: String = atk.node.name if (atk.node != null) else "id:%d" % attacker_id
	print("[Combat] Power/commitment: %s | power=%.2f follow_through=%.2f => intensity=%.2f | windup_mult=%.2f => wind_up=%.2fs (recovery will use same intensity)" % [atk_name_log, power, follow_through, intensity, windup_mult, wind_up_s])

func _execute_attack(attacker_id: int) -> void:
	var _empty_result: Dictionary = {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0}
	var result: Dictionary = _AttackResolver.resolve_attack(self, attacker_id)
	var action: String = result.get("action", "skip")
	var target_id: int = result.get("target_id", -1)
	var atk = _get_by_id(attacker_id)
	var tgt = _get_by_id(target_id) if target_id >= 0 else null

	if action == "skip":
		if atk != null:
			if result.get("recovery_duration", 0.0) > 0.0:
				_empty_result["outcome"] = "skip"
				emit_signal("action_resolved", attacker_id, target_id, _empty_result)
				atk.state = STATE_RECOVERING
				atk.state_timer = 0.0
				atk.state_duration = result.recovery_duration
			else:
				atk.state = STATE_WAITING
				atk.gauge = 0.0
		return
	if action == "defeated":
		if tgt != null:
			tgt.alive = false
			tgt.state = STATE_DEAD
		_empty_result["outcome"] = "defeated"
		_empty_result["died"] = true
		emit_signal("action_resolved", attacker_id, target_id, _empty_result)
		var winner: String = _check_for_winner()
		if not winner.is_empty():
			_end_combat_phase(winner, tgt.node if tgt != null else null)
		return
	if action == "miss":
		_empty_result["outcome"] = "miss"
		emit_signal("action_resolved", attacker_id, target_id, _empty_result)
		if atk != null:
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + OFF_BALANCE_DURATION_S
		return
	if action == "dodge":
		_empty_result["outcome"] = "dodge"
		emit_signal("action_resolved", attacker_id, target_id, _empty_result)
		if atk != null:
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		return
	if action == "parry_deflect":
		if atk != null:
			atk.pending_attack = {}
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
			atk["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + OFF_BALANCE_DURATION_S
		if tgt != null:
			tgt["parry_bonus_until"] = Time.get_ticks_msec() / 1000.0 + PARRY_BONUS_AFTER_DEFLECT_S
			tgt.state = STATE_WAITING
			tgt.state_timer = 0.0
			tgt.state_duration = 0.0
		_empty_result["outcome"] = "parry_deflect"
		emit_signal("action_resolved", target_id, attacker_id, _empty_result)
		return
	if action == "parry_partial":
		if tgt != null:
			tgt.state = STATE_WAITING
			tgt.state_timer = 0.0
			tgt.state_duration = 0.0
		_execute_attack(attacker_id)
		return
	if action == "hit":
		var result_dict: Dictionary = result.get("result_dict", {})
		var winner: String = ""
		if result_dict.get("died", false):
			emit_signal("action_resolved", attacker_id, target_id, result_dict)
			winner = _check_for_winner()
			if not winner.is_empty():
				_end_combat_phase(winner, tgt.node if tgt != null else null)
			return
		winner = _check_for_winner()
		if not winner.is_empty():
			if tgt != null and tgt.node != null and tgt.node.has_method("is_incapacitated") and tgt.node.is_incapacitated():
				var reason: String = "consciousness < 10%%"
				if tgt.node.has_method("is_cowering") and tgt.node.is_cowering():
					reason = "cowering (no functional arms)"
				print("[Combat] INCAPACITATED: %s (%s)" % [tgt.node.name if tgt.node != null else target_id, reason])
			emit_signal("action_resolved", attacker_id, target_id, result_dict)
			_end_combat_phase(winner, tgt.node if tgt != null else null)
			return
		print("[Combat] Recovery (hit): %s outcome=%s => duration=%.2fs" % [atk.node.name if atk != null and atk.node != null else attacker_id, result.get("outcome", "hit"), result.recovery_duration])
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		if atk != null:
			atk.state = STATE_RECOVERING
			atk.state_timer = 0.0
			atk.state_duration = result.recovery_duration
		return

# Parry speed (m/s) from same scale as strike velocity; defensive move ~40–60% of max strike (research).
# Optional def_weapon: if it has parry_speed_factor, scale base speed (e.g. dagger 1.2, mace 0.9).
func _get_parry_speed_m_s(def_weapon = null) -> float:
	var base_speed: float = WeaponConstants.VELOCITY_MAX_M_S * PARRY_V_FRACTION_OF_MAX_STRIKE
	if def_weapon != null and (def_weapon.get("parry_speed_factor") is float or def_weapon.get("parry_speed_factor") is int):
		base_speed *= clampf(float(def_weapon.parry_speed_factor), 0.5, 1.5)
	return base_speed

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
