class_name CombatExhaustion
extends RefCounted

## MXm: cumulative fight exhaustion (0–1) on combatant dict; gain on stamina spend; recovery in WAITING.
## MXm-2: **`performance_mult_for_combatant`** → parry readiness, wind-up, surround awareness.
## MXm-3: **`effective_stamina_max`** / **`effective_stamina_refill_rate`** — central fatigue + blood cap burst pool.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _PainConscious := preload("res://core/PainConsciousnessConstants.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")

const _FP_COMBAT_BANDS: Array[float] = [0.25, 0.5, 0.75]


static func apply_exertion_from_stamina_spend(
	manager: Node,
	combatant: Dictionary,
	stamina_spent: float
) -> void:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return
	if combatant.is_empty() or stamina_spent <= 0.0:
		return
	var exertion: float = stamina_spent * CombatConstants.EXHAUSTION_EXERTION_PER_STAMINA_POINT
	var stats: Dictionary = _EntityAccess.stats_dict(combatant)
	var end_stat: float = float(stats.get("endurance", 100))
	var end_ratio: float = clampf(end_stat / 100.0, 0.0, 1.0)
	var relief: float = end_ratio * CombatConstants.EXHAUSTION_ENDURANCE_MAX_RELIEF
	exertion *= 1.0 - relief
	exertion *= _medical_exertion_gain_mult(manager, combatant)
	var cur: float = _EntityAccess.exhaustion_float(combatant)
	var prev: float = cur
	var next: float = clampf(cur + exertion, 0.0, CombatConstants.EXHAUSTION_MAX)
	_EntityAccess.set_exhaustion_float(combatant, next)
	_maybe_log_exhaustion_band_crossing(combatant, prev, next)
	clamp_stamina_to_effective_max(combatant)


## Hypovolemia reduces peak burst power (O₂ delivery to working muscle).
static func blood_stamina_cap_mult(combatant: Dictionary) -> float:
	if combatant.is_empty():
		return 1.0
	var blood: float = float(_EntityAccess.stats_dict(combatant).get("blood_volume", 100.0))
	var start_t: float = _PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD
	var floor_t: float = _PainConscious.BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD
	if blood >= start_t:
		return 1.0
	if blood <= floor_t:
		return CombatConstants.STAMINA_BLOOD_MAX_MULT_FLOOR
	var t: float = (blood - floor_t) / maxf(0.001, start_t - floor_t)
	return lerpf(CombatConstants.STAMINA_BLOOD_MAX_MULT_FLOOR, 1.0, t)


## Current burst ceiling (exhaustion + blood); nominal **`STAMINA_MAX`** when fresh and uninjured.
static func effective_stamina_max(combatant: Dictionary) -> float:
	var base: float = CombatConstants.STAMINA_MAX
	var blood_m: float = blood_stamina_cap_mult(combatant)
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return base * blood_m
	var ex: float = _EntityAccess.exhaustion_float(combatant)
	var exh_m: float = lerpf(1.0, CombatConstants.STAMINA_EXHAUSTION_MAX_MULT_FLOOR, ex)
	var camp_m: float = clampf(float(combatant.get("campaign_stamina_mult", 1.0)), 0.5, 1.0)
	return base * exh_m * blood_m * camp_m


## PCr resynthesis rate while **`STATE_WAITING`** (slows with fight exhaustion).
static func effective_stamina_refill_rate(combatant: Dictionary) -> float:
	var rate: float = CombatConstants.STAMINA_REFILL_RATE
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return rate
	var ex: float = _EntityAccess.exhaustion_float(combatant)
	return rate * lerpf(
		CombatConstants.STAMINA_REFILL_EXHAUSTION_MULT_FLOOR, 1.0, 1.0 - ex
	)


## Stamina / **`effective_stamina_max`** — use for ratios, UI %, and turn-delay curves.
static func stamina_ratio(combatant: Dictionary) -> float:
	var cap: float = effective_stamina_max(combatant)
	if cap <= 0.001:
		return 0.0
	return clampf(_EntityAccess.stamina_float(combatant, 0.0) / cap, 0.0, 1.0)


static func clamp_stamina_to_effective_max(combatant: Dictionary) -> void:
	if combatant.is_empty():
		return
	var cap: float = effective_stamina_max(combatant)
	combatant["stamina"] = minf(_EntityAccess.stamina_float(combatant, 0.0), cap)


## MS-L7: mental stack tunnel — prefer wait / disengage over new offense.
static func exhaustion_tunnel_active(combatant: Dictionary) -> bool:
	if not CombatConstants.is_feature_fight_exhaustion_enabled() or combatant.is_empty():
		return false
	return (
		_EntityAccess.exhaustion_float(combatant)
		>= CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
	)


## Gradual offense damp (below tunnel threshold); stacks with salience damp in **`CombatAIActionPicker`**.
static func exhaustion_offense_weight_mult(combatant: Dictionary) -> float:
	if not CombatConstants.is_feature_fight_exhaustion_enabled() or combatant.is_empty():
		return 1.0
	var ex: float = _EntityAccess.exhaustion_float(combatant)
	var tunnel: float = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD
	if ex >= tunnel:
		return CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR
	if ex < CombatConstants.EXHAUSTION_OFFENSE_DAMP_START:
		return 1.0
	var span: float = maxf(0.001, tunnel - CombatConstants.EXHAUSTION_OFFENSE_DAMP_START)
	var t: float = (ex - CombatConstants.EXHAUSTION_OFFENSE_DAMP_START) / span
	return lerpf(1.0, CombatConstants.EXHAUSTION_OFFENSE_DAMP_FLOOR, clampf(t, 0.0, 1.0))


## 1.0 when feature off or exhaustion 0; floors at **`EXHAUSTION_FLOOR_MULT`** when fully spent.
static func performance_mult_for_combatant(combatant: Dictionary) -> float:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return 1.0
	return CombatConstants.exhaustion_performance_mult(_EntityAccess.exhaustion_float(combatant))


## Longer wind-up when exhausted (divide duration by performance mult).
static func apply_attacker_wind_up_exhaustion_mult(duration_s: float, attacker: Dictionary) -> float:
	var perf: float = performance_mult_for_combatant(attacker)
	if perf >= 0.999:
		return duration_s
	return duration_s / maxf(perf, CombatConstants.EXHAUSTION_FLOOR_MULT)


static func process_waiting_recovery(combatant: Dictionary, delta: float) -> void:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return
	if combatant.is_empty() or delta <= 0.0:
		return
	var cur: float = _EntityAccess.exhaustion_float(combatant)
	if cur <= 0.0:
		return
	_EntityAccess.set_exhaustion_float(
		combatant,
		maxf(0.0, cur - CombatConstants.EXHAUSTION_RECOVERY_RATE * delta)
	)


## UI gauge suffix text (empty when below **`EXHAUSTION_UI_SHOW_THRESHOLD`** or feature off).
static func gauge_suffix_text(combatant: Dictionary) -> String:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return ""
	var ex: float = _EntityAccess.exhaustion_float(combatant)
	if ex < CombatConstants.EXHAUSTION_UI_SHOW_THRESHOLD:
		return ""
	return "Exh %d%%" % int(roundf(ex * 100.0))


static func gauge_hint_suffix(combatant: Dictionary) -> String:
	var text: String = gauge_suffix_text(combatant)
	return (" · " + text) if not text.is_empty() else ""


static func stamina_cap_tooltip_line(combatant: Dictionary) -> String:
	var cap: float = effective_stamina_max(combatant)
	if cap >= CombatConstants.STAMINA_MAX - 0.5:
		return ""
	var cap_pct: int = int(roundf(cap))
	return (
		"Burst max %d — central fatigue and/or blood loss cap stamina (bar max shrinks)."
		% cap_pct
	)


static func gauge_tooltip_line(combatant: Dictionary) -> String:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return ""
	var ex: float = _EntityAccess.exhaustion_float(combatant)
	if ex < CombatConstants.EXHAUSTION_UI_SHOW_THRESHOLD:
		return ""
	var perf_pct: int = int(roundf(performance_mult_for_combatant(combatant) * 100.0))
	return (
		"Fight exhaustion %d%% — performance %d%% (slower wind-up, duller parries; rest in WAITING recovers)."
		% [int(roundf(ex * 100.0)), perf_pct]
	)


## Index into **`_FP_COMBAT_BANDS`** for **`exhaustion`**, or **-1** if below first band.
static func exhaustion_fp_combat_band_index(exhaustion: float) -> int:
	var ex: float = clampf(exhaustion, 0.0, CombatConstants.EXHAUSTION_MAX)
	for i in range(_FP_COMBAT_BANDS.size() - 1, -1, -1):
		if ex + 0.0001 >= _FP_COMBAT_BANDS[i]:
			return i
	return -1


static func _maybe_log_exhaustion_band_crossing(
	combatant: Dictionary,
	prev_ex: float,
	new_ex: float
) -> void:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return
	var new_band: int = exhaustion_fp_combat_band_index(new_ex)
	if new_band < 0:
		return
	var logged: int = int(combatant.get(CombatConstants.COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED, -1))
	if new_band <= logged:
		return
	if exhaustion_fp_combat_band_index(prev_ex) >= new_band:
		return
	combatant[CombatConstants.COMBATANT_KEY_EXHAUSTION_FP_BAND_LOGGED] = new_band
	var band_pct: int = int(roundf(_FP_COMBAT_BANDS[new_band] * 100.0))
	var perf_pct: int = int(roundf(performance_mult_for_combatant(combatant) * 100.0))
	var who: String = _EntityAccess.get_display_name(combatant)
	if _OperationalLog.play_session_is_editor_f5():
		_F5SoakTrace.note_exhaustion_crossing(who, band_pct, new_ex * 100.0, perf_pct)
	else:
		_CombatDebug.combat_session(
			"exhaustion %s crossed %d%% (index %.0f%% perf %d%%)"
			% [who, band_pct, new_ex * 100.0, perf_pct]
		)


static func _medical_exertion_gain_mult(manager: Node, combatant: Dictionary) -> float:
	var mult: float = 1.0
	var entity: Node = null
	if manager != null:
		entity = _EntityAccess.get_health_entity_from_node(manager, _EntityAccess.scene_node(combatant))
	else:
		entity = _EntityAccess.scene_node(combatant)
	if entity == null:
		return mult
	if "blood_volume" in entity:
		var blood: float = float(entity.blood_volume)
		if blood < _PainConscious.BLOOD_CONSCIOUSNESS_START_THRESHOLD:
			mult *= CombatConstants.EXHAUSTION_GAIN_BLOOD_LOSS_MULT
	if "_pain_shock_until_time" in entity:
		var now: float = Time.get_ticks_msec() / 1000.0
		var until: float = float(entity._pain_shock_until_time)
		if until >= 0.0 and now < until:
			mult *= CombatConstants.EXHAUSTION_GAIN_PAIN_SHOCK_MULT
	return mult
