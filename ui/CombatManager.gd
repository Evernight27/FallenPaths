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

const DAMAGE_TYPE_SHARP := "SHARP"
const DAMAGE_TYPE_BLUNT := "BLUNT"

# Attack state machine: waiting (gauge filling) -> wind_up (swing until impact) | medical_wind_up -> recovering (follow-through after hit/deflect/miss/medical). Parry is passive (A4v3) only.
# receiving_medical_attention: target of ally's medical action; gauge stays full (readied), cannot act until care finishes.
const STATE_WAITING := "waiting"
const STATE_WIND_UP := "wind_up"
const STATE_MEDICAL_WIND_UP := "medical_wind_up"
const STATE_RECOVERING := "recovering"
const STATE_RECEIVING_MEDICAL_ATTENTION := "receiving_medical_attention"

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
const INTENSITY_STRENGTH_NORM := 100.0        # 100 = average (same scale as other stats)
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
	if not medical_phase:
		return false
	for c in combatants:
		if not c.alive or c.side != medical_phase_winner or c.node == null:
			continue
		if _is_in_medical_danger(c):
			return false
		if _has_untreated_wounds(c):
			return false
	return true

## True if combatant has any wounded part that is not comprehensively treated (bandaged, packed, or tourniqueted). Direct pressure alone does not count.
func _has_untreated_wounds(c: Dictionary) -> bool:
	var entity = _get_entity(c.node) if c.node != null else null
	if entity == null:
		return false
	if not entity.has_method("get_wounded_parts"):
		return false
	var wounded: Array = entity.get_wounded_parts()
	if wounded.is_empty():
		return false
	var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
	var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
	var tourniqueted: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
	for part in wounded:
		if bandaged.get(part, false) or packed.get(part, false) or tourniqueted.has(part):
			continue
		return true  # This wounded part has no comprehensive treatment
	return false

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

# AI only considers medical actions when in danger of dying soon (low blood or high bleeding rate).
const MEDICAL_DANGER_BLOOD_THRESHOLD := 55.0   # consider medical when blood volume <= this %
const MEDICAL_DANGER_SECONDS := 90.0           # or when estimated time to blood-loss death <= this many seconds
# Immediate peril: must self-treat first (about to bleed out). Injured-but-stable can still help others.
const IMMEDIATE_PERIL_BLOOD_THRESHOLD := 42.0  # blood <= this = immediate peril
const IMMEDIATE_PERIL_SECONDS := 45.0          # time to death <= this = immediate peril
# When medical is available, weight scales from 1 to this as urgency (how close to death) increases; randomness applied so not guaranteed.
const MEDICAL_URGENCY_WEIGHT_MAX := 6.0
const MEDICAL_URGENCY_RANDOM_MIN := 0.8        # urgency multiplied by randf_range(MIN, MAX) for variance
const MEDICAL_URGENCY_RANDOM_MAX := 1.2

# Available actions: array of { "target_id": int, "move_id": String, optional "target_part": String }.
# Attack moves (non-parry) and medical when in danger. Parry is passive only (A4v3).
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

## Stricter than _is_in_medical_danger: about to bleed out. Must self-treat; cannot help others.
func _is_in_immediate_peril(c: Dictionary) -> bool:
	var entity = _get_entity(c.node) if c.node != null else null
	if entity == null:
		return false
	var bv: float = 100.0
	if entity.has_method("get_blood_volume"):
		bv = entity.get_blood_volume()
	elif "blood_volume" in entity:
		bv = float(entity.blood_volume)
	if bv <= IMMEDIATE_PERIL_BLOOD_THRESHOLD:
		return true
	var rate: float = entity.get_total_bleeding_rate() if entity.has_method("get_total_bleeding_rate") else 0.0
	if rate <= 0.0:
		return false
	var loss_per_sec: float = rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return false
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
	return time_to_death <= IMMEDIATE_PERIL_SECONDS

## True when entity has permanently left immediate peril: permanent bleeding rate (excluding direct pressure) is low enough to recover before death.
## Direct pressure does not count—it is temporary; bandage/packing/tourniquet are permanent.
func _has_left_immediate_peril_permanently(c: Dictionary) -> bool:
	var entity = _get_entity(c.node) if c.node != null else null
	if entity == null:
		return false
	var perm_rate: float = entity.get_permanent_bleeding_rate() if entity.has_method("get_permanent_bleeding_rate") else 0.0
	if perm_rate <= _Bleeding.BLEEDING_RATE_EPSILON:
		return true  # No permanent bleeding; will recover
	var bv: float = 100.0
	if entity.has_method("get_blood_volume"):
		bv = entity.get_blood_volume()
	elif "blood_volume" in entity:
		bv = float(entity.blood_volume)
	var loss_per_sec: float = perm_rate * _Bleeding.BLOOD_LOSS_RATE_MULTIPLIER
	if loss_per_sec <= 0.0:
		return true
	var time_to_death: float = (bv - _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD) / loss_per_sec
	# Recover before death = time to clot/stop bleeding is less than time to death. Conservative: need significant buffer.
	return time_to_death > IMMEDIATE_PERIL_SECONDS * 2.0

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

## Returns list of {move_id, target_part} for medical actions the performer can apply to the ally's part. Extend this when adding new medical moves.
## When target is not in immediate peril and part was recently failed (bandage/pack/tourniquet), exclude redress actions so they don't retry.
func _get_ally_medical_actions(performer: Dictionary, ally: Dictionary, part: String) -> Array:
	var out: Array = []
	var target_entity = _get_entity(ally.node) if ally.node != null else null
	var performer_has_arm: bool = performer.node.can_apply_direct_pressure("") if performer.node != null else false
	var failed_parts: Array = ally.get("failed_medical_parts", [])
	# Only skip redress when permanently safe (bleeding slowed by bandage/pack/tourniquet; direct pressure doesn't count)
	var skip_redress: bool = _has_left_immediate_peril_permanently(ally) and part in failed_parts
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_bandage") and target_entity.can_apply_bandage(part):
		out.append({ "move_id": "bandage_self", "target_part": part })
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_packing") and target_entity.can_apply_packing(part):
		out.append({ "move_id": "pack_wound", "target_part": part })
	# Don't offer apply_direct_pressure if target already has pressure on this part (self or ally)
	if target_entity != null and target_entity.has_method("has_direct_pressure_on_part") and target_entity.has_direct_pressure_on_part(part):
		pass  # skip direct pressure for this part
	elif performer_has_arm and performer.node.has_method("is_applying_direct_pressure") and not performer.node.is_applying_direct_pressure():
		# Self-application: can't use same arm (left can't press left, right can't press right)
		if performer.id == ally.id and target_entity != null and not target_entity.can_apply_direct_pressure(part):
			pass  # skip this part
		else:
			out.append({ "move_id": "apply_direct_pressure", "target_part": part })
	# Tourniquet only when indicated: severe bleeding, severed limb, or heavily damaged. Bandage is default per TCCC.
	if not skip_redress and target_entity != null and target_entity.has_method("can_apply_tourniquet") and target_entity.can_apply_tourniquet(part):
		if target_entity.has_method("is_tourniquet_indicated_for_part") and target_entity.is_tourniquet_indicated_for_part(part):
			out.append({ "move_id": "apply_tourniquet", "target_part": part })
	return out

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
			var w: float = 1.0 + urgency * (MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
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
			w = 1.0 + urgency * (MEDICAL_URGENCY_WEIGHT_MAX - 1.0)
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
				# Throttle: same cooldown as AI so we don't spam turn_ready every frame
				var cooldown: float = c.get("receiving_care_action_cooldown", 0.0) - delta
				c.receiving_care_action_cooldown = cooldown
				if cooldown <= 0.0:
					var recv_actions: Array = get_available_actions(c.id)
					if not recv_actions.is_empty():
						emit_signal("turn_ready", c.id)
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
						c.receiving_care_action_cooldown = 0.5
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
				c.state = STATE_WAITING
				c.gauge = 0.0
				c.state_timer = 0.0
				c.state_duration = 0.0
				c.pending_attack = {}

# Called when player or AI chooses action. move_id optional; options can include "target_part" for medical actions.
func resolve_action(attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = _get_by_id(attacker_id)
	if atk == null or atk.gauge < 100.0:
		return
	# Receiving care: can hold/switch direct pressure on other wounds (no state change, no gauge drain)
	if atk.state == STATE_RECEIVING_MEDICAL_ATTENTION and move_id == "apply_direct_pressure" and target_id == attacker_id:
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
			atk.receiving_care_action_cooldown = 0.5  # Throttle next turn_ready; _process will re-emit when cooldown expires
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
	atk.pending_attack = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype, "wind_up_duration": wind_up_s}
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
			_end_combat_phase(w, tgt.node)
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
		atk["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + OFF_BALANCE_DURATION_S
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

	# A4v3 passive parry: perception/state → reaction time; if noticed in time, parry attempt with effectiveness scaled by time_to_react.
	# 3.3 commitment window: effective reaction window = wind_up * (1 - COMMITMENT_FRACTION). 3.2/3.4 readiness by state. 3.5 off balance penalty.
	if not pa.get("passive_parry_attempted", false):
		if tgt.state != STATE_WIND_UP and tgt.state != STATE_MEDICAL_WIND_UP:
			var wind_up_duration: float = pa.get("wind_up_duration", 0.5)
			var effective_wind_up: float = wind_up_duration * (1.0 - COMMITMENT_FRACTION)
			if tgt.node != null and tgt.node.has_method("get_passive_parry_reaction_time") and tgt.node.has_method("get_weapon"):
				var def_weapon = tgt.node.get_weapon()
				if def_weapon != null and effective_wind_up > 0.0:
					var reaction_time: float = tgt.node.get_passive_parry_reaction_time()
					if reaction_time < effective_wind_up:
						var time_to_react: float = effective_wind_up - reaction_time
						var atk_weapon = atk.node.get_weapon() if (atk.node != null and atk.node.has_method("get_weapon")) else null
						if atk_weapon != null:
							var attack_instance = AttackInstance.new(attack_type, intensity)
							attack_instance.archetype = archetype
							attack_instance.velocity_m_s = velocity_override if velocity_override >= 0.0 else -1.0
							var v_intent: float = WeaponDamageHelper.get_effective_velocity_m_s(atk_weapon, attack_instance)
							var m_a: float = float(atk_weapon.mass)
							var p_a: float = m_a * v_intent
							var m_d: float = float(def_weapon.mass) if (def_weapon.get("mass") is float or def_weapon.get("mass") is int) else WeaponConstants.BASELINE_MASS_KG
							var s_d: float = float(tgt.stats.get("strength", 100))
							var c_d_full: float = m_d * _get_parry_speed_m_s() * (s_d / PARRY_STRENGTH_NORM)
							var def_perf: float = 1.0
							if tgt.node.has_method("get_performance_modifier"):
								def_perf = tgt.node.get_performance_modifier()
							c_d_full *= maxf(PERF_MOD_MIN, def_perf)
							if PARRY_TECHNIQUE_VARIANCE > 0.0:
								c_d_full *= randf_range(1.0 - PARRY_TECHNIQUE_VARIANCE, 1.0 + PARRY_TECHNIQUE_VARIANCE)
							var capacity_mult: float = clampf(time_to_react / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0.0, 1.0)
							var c_d: float = c_d_full * capacity_mult
							var readiness: float = _get_passive_parry_readiness(tgt)
							c_d *= readiness
							var off_balance: bool = _is_off_balance(tgt)
							if off_balance:
								c_d *= OFF_BALANCE_PARRY_CAPACITY_MULT
							pa["passive_parry_attempted"] = true
							var def_name: String = tgt.node.name if tgt.node != null else "id:%d" % target_id
							var ob: String = " off_balance" if off_balance else ""
							print("[Combat] Passive parry (A4v3): %s noticed in time (reaction %.2fs < effective_wind_up %.2fs) => time_to_react=%.2fs capacity_mult=%.2f readiness=%.2f%s => c_d=%.1f vs p_a=%.1f" % [def_name, reaction_time, effective_wind_up, time_to_react, capacity_mult, readiness, ob, c_d, p_a])
							_resolve_parry_with_momentum(target_id, attacker_id, "", p_a, c_d, true)
							return

	# Proceeding to damage: clear so re-entry from partial parry doesn't re-use stale pending_attack.
	atk.pending_attack = {}

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
		var str_mod: float = maxf(0.1, float(atk.stats.strength) / 100.0)
		var pa_power: float = pa.get("power", -1.0)
		var pa_ft: float = pa.get("follow_through", -1.0)
		print("[Damage equation] %s -> %s | power=%.2f follow_through=%.2f intensity=%.2f (drives v, KE, wind-up, recovery) | physics: v=%.2f m/s mass=%.2f kg KE=%.1f J | modifiers: strength=%.2f arm=%.2f cut_ratio=%.2f => pre_armor=%.1f (cut=%.1f blunt=%.1f) | pen_sharp=%.2f mm RHA | blunt: transmission only (momentum/A=%.0f)" % [atk_name, tgt_name, pa_power, pa_ft, intensity, v_m_s, mass_kg, ke_j, str_mod, arm_mod, cut_ratio, pre_armor, pre_cut, pre_blunt, pen_sharp, pen_blunt_momentum_per_area])
	else:
		var mod: float = 1.0
		if atk.node != null and atk.node.has_method("get_attack_damage_modifier"):
			mod = atk.node.get_attack_damage_modifier()
		# Unarmed: strength/100 = multiplier; scale so average (100) gives reasonable base (e.g. 8).
		pre_armor = (float(atk.stats.strength) / 100.0) * 8.0 * mod
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
			_end_combat_phase(w, tgt.node)
		return
	w = _check_for_winner()
	if not w.is_empty():
		if tgt.node.has_method("is_incapacitated") and tgt.node.is_incapacitated():
			print("[Combat] INCAPACITATED: %s (consciousness < 10%%)" % tgt_name)
		emit_signal("action_resolved", attacker_id, target_id, result_dict)
		_end_combat_phase(w, tgt.node)
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

# Resolve parry using precomputed momentum and capacity. Called only from passive parry (A4v3); defender returns to waiting (no counter-attack).
func _resolve_parry_with_momentum(defender_id: int, attacker_id: int, _move_id: String, p_a: float, c_d: float, _skip_counter_attack: bool = true) -> void:
	var defender = _get_by_id(defender_id)
	var attacker = _get_by_id(attacker_id)
	if defender == null or attacker == null or attacker.pending_attack.is_empty():
		return
	var pa = attacker.pending_attack
	var attacker_weapon = attacker.node.get_weapon() if (attacker.node != null and attacker.node.has_method("get_weapon")) else null
	if attacker_weapon == null:
		defender.state = STATE_WAITING
		defender.state_timer = 0.0
		defender.state_duration = 0.0
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
	attacker["off_balance_until"] = Time.get_ticks_msec() / 1000.0 + OFF_BALANCE_DURATION_S
	var def_name: String = defender.node.name if defender.node != null else "id:%d" % defender_id
	var atk_name: String = attacker.node.name if attacker.node != null else "id:%d" % attacker_id
	print("[Combat] Parry: %s parried %s (attacker momentum %.1f vs defender capacity %.1f). Attacker recovery: intensity=%.2f => %.2fs" % [def_name, atk_name, p_a, c_d, parry_intensity, rec_dur_parry])
	emit_signal("action_resolved", defender_id, attacker_id, {"dmg": 0, "died": false, "part": "", "damage_type": "", "outcome": "parry_deflect", "health_before": 0, "health_after": 0, "final_cut": 0, "final_blunt": 0})
	defender.state = STATE_WAITING
	defender.state_timer = 0.0
	defender.state_duration = 0.0

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
