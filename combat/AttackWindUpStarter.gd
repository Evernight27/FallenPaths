class_name AttackWindUpStarter
extends RefCounted

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _StrikeRealism := preload("res://weapon/StrikeRealismProfile.gd")
const _StrikeStamping := preload("res://combat/CombatStrikeStamping.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _CounterTempo := preload("res://combat/CounterTempo.gd")
const _Attention := preload("res://combat/CombatAttention.gd")
const _Footwork := preload("res://combat/CombatFootwork.gd")
const _StateHandlers := preload("res://combat/CombatStateHandlers.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const _FlurryBind := preload("res://combat/CombatFlurryBind.gd")
const _WeaponPosition := preload("res://combat/CombatWeaponPosition.gd")
const _IncomingParryChoice := preload("res://combat/CombatIncomingParryChoice.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")

static var _last_fp_tempo_wind_up_line: String = ""


static func reset_fp_session_dedup() -> void:
	_last_fp_tempo_wind_up_line = ""


## F5 soak (**II-2b**): grep `riposte_chain` / `counter_tempo` / `flurry_bind` without **`COMBAT_DEBUG`**.
static func _log_fp_tempo_wind_up(
	atk_name: String,
	tgt_name: String,
	wind_up_s: float,
	counter_tempo: bool,
	riposte_chain: bool,
	flurry_bind: bool
) -> void:
	if not _OperationalLog.is_play_session_active():
		return
	var lines: PackedStringArray = PackedStringArray()
	if riposte_chain:
		lines.append("riposte_chain %s vs %s wind_up=%.2fs" % [atk_name, tgt_name, wind_up_s])
	elif counter_tempo:
		lines.append("counter_tempo %s vs %s wind_up=%.2fs" % [atk_name, tgt_name, wind_up_s])
	if flurry_bind:
		lines.append("flurry_bind %s vs %s wind_up=%.2fs" % [atk_name, tgt_name, wind_up_s])
	for line in lines:
		if line == _last_fp_tempo_wind_up_line:
			continue
		_last_fp_tempo_wind_up_line = line
		_CombatDebug.combat_session(line)


## Starts an attack wind-up: power/follow-through roll, intensity, weapon selection, wind-up duration.
## Replaces **`atk.pending_attack`**: clears the prior wind-up’s defender **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** (if any) before assigning the new **`pa`**.
## **`is_feint`** moves may apply **`feint_windup_duration_mult`** from **`WeaponConstants.get_move`** (extra **`state_duration`** / **`pa.wind_up_duration`** vs honest cut at same rolls) and optional **`feint_target_reveal_at_progress`** (stamped on **`pa`** for **`DefenseChoiceResolver._feint_readiness_reveal_mult`**).
## Manager must have: _get_by_id; health reads go through CombatantEntityAccess + manager.get_health_entity.
## Mutates attacker combatant in place.

static func start(manager: Node, attacker_id: int, target_id: int, move_id: String = "", options: Dictionary = {}) -> void:
	var atk = manager._get_by_id(attacker_id)
	var tgt = manager._get_by_id(target_id)
	var atk_d: Dictionary = _EntityAccess.combatant_dict_or_empty(atk)
	var tgt_d: Dictionary = _EntityAccess.combatant_dict_or_empty(tgt)
	if atk_d.is_empty() or tgt_d.is_empty() or not _EntityAccess.are_living_hostiles(atk_d, tgt_d):
		return
	if _MedicalPhase.combat_resolution_blocked(manager):
		return
	if _MobilityRetreat.cannot_commit_melee(atk):
		var atk_name_skip: String = _EntityAccess.get_display_name(atk, attacker_id)
		print("[Combat] %s has no functional arm; skip attack (short recovery)." % atk_name_skip)
		_MobilityRetreat.sync_cowering_state_if_no_functional_arm(atk)
		_StateHandlers.enter_short_recovery(atk, manager)
		if manager != null and atk.state_duration > 0.0:
			manager._schedule_event({
				"type": CombatConstants.EVENT_RECOVERY_END,
				"combatant_id": attacker_id,
				"resolve_at": _EntityAccess.combat_clock_plus(manager, atk.state_duration),
				"data": {},
			})
		return
	# Power and follow_through (0.2–1.0) per attack; intensity drives velocity, wind-up, and recovery. Strength biases toward higher commitment.
	var power: float = randf_range(CombatConstants.POWER_MIN, CombatConstants.POWER_MAX)
	var follow_through: float = randf_range(CombatConstants.FOLLOW_THROUGH_MIN, CombatConstants.FOLLOW_THROUGH_MAX)
	var rolled_intensity: float = (0.5 + 0.5 * power) * (0.5 + 0.5 * follow_through)
	var strength_intensity: float = CombatTiming.intensity_from_stats(atk)
	var intensity: float = clampf(lerpf(rolled_intensity, strength_intensity, CombatConstants.INTENSITY_STRENGTH_BIAS), CombatConstants.INTENSITY_MIN, 1.0)
	var weapon = _EntityAccess.get_weapon(atk)
	var requested_move: String = str(move_id).strip_edges()
	var attack_type: String = WeaponConstants.ATTACK_TYPE_CUT
	var archetype: Dictionary = WeaponConstants.get_archetype(WeaponConstants.ARCHETYPE_SLASH)
	if _EntityAccess.weapon_has_attack_types(weapon):
		var types_arr: Array = _EntityAccess.weapon_attack_types(weapon)
		if requested_move != "" and not types_arr.has(requested_move):
			CombatDebug.log(
				"wind_up rejected: move_id=%s not on weapon for combatant %d"
				% [requested_move, attacker_id]
			)
			return
		if requested_move != "":
			attack_type = requested_move
		else:
			var non_parry: Array = []
			for mid in types_arr:
				if not WeaponConstants.is_parry_move(mid):
					non_parry.append(mid)
			if non_parry.is_empty():
				non_parry = types_arr
			if not non_parry.is_empty():
				attack_type = non_parry[randi() % non_parry.size()]
		archetype = _EntityAccess.weapon_archetype_for_move(weapon, attack_type)
	var windup_mult: float = float(archetype.get("windup_multiplier", 1.0))
	var wind_up_s: float = CombatTiming.wind_up_duration(intensity, windup_mult)
	# Guard transition: blade must move from current guard to attack line. Physics: angular distance (angle-based).
	var move_def: Dictionary = WeaponConstants.get_move(attack_type)
	var attack_line: String = move_def.get("attack_line", "high")
	_Footwork.apply_attack_step_on_windup(atk, attack_line)
	var arc_start_deg: float = CombatConstants.get_guard_angle_deg(atk)
	var intended_attack_deg: float = _Footwork.apply_offset_to_angle_deg(
		CombatConstants.line_to_angle(attack_line), atk
	)
	var align_ctx: Dictionary = {
		"attack_angle_deg": intended_attack_deg,
		"guard_angle_deg": arc_start_deg
	}
	var align: float = CombatConstants.get_line_alignment_with_deflect(attack_line, atk, align_ctx)
	var trans_mult: float = CombatTiming.guard_transition_mult(align)
	wind_up_s *= trans_mult
	# Bind riposte: parry_part × contact_type. Extend=fast, wind=moderate, swing=slow.
	if weapon != null and atk.get("parry_was_bind", false) and atk.get("parry_against_id", -1) == target_id:
		var contact_type: String = _EntityAccess.weapon_contact_type(weapon, attack_type, "")
		var eligible: Array = weapon.bind_riposte_contact_types if weapon.get("bind_riposte_contact_types") is Array else []
		if contact_type in eligible:
			var parry_part: String = _EntityAccess.weapon_parry_contact_type(weapon)
			var part_row: Variant = CombatConstants.PARRY_BIND_RIPOSTE_BY_PART_CONTACT.get(parry_part, {})
			var mult: float = float(part_row.get(contact_type, -1.0)) if part_row is Dictionary else -1.0
			if mult < 0.0:
				mult = CombatConstants.PARRY_BIND_RIPOSTE_MULT_FALLBACK
			wind_up_s *= mult
	# Leg functionality: longer wind-up when legs injured (harder to get into position to attack).
	var leg: float = clampf(_EntityAccess.get_leg_functionality(atk), CombatConstants.WINDUP_LEG_MIN, 1.0)
	wind_up_s /= leg
	# Pain/consciousness: wounded attackers swing slower
	var atk_perf_mod: float = _EntityAccess.get_performance_modifier(atk)
	if atk_perf_mod > 0.0:
		wind_up_s /= maxf(CombatConstants.PERF_MOD_MIN, atk_perf_mod)
	# Agility: higher agility shortens wind-up (faster into position)
	var atk_agi: float = float(_EntityAccess.stats_dict(atk).get("agility", 100))
	wind_up_s /= clampf(atk_agi / 100.0, 0.7, 1.3)
	var feint_windup_mult: float = 1.0
	if move_def.get("is_feint", false):
		feint_windup_mult = float(move_def.get("feint_windup_duration_mult", 1.0))
		if feint_windup_mult > 0.0:
			wind_up_s *= feint_windup_mult
	var counter_tempo: bool = bool(options.get(CombatConstants.ACTION_KEY_COUNTER_TEMPO, false))
	if counter_tempo:
		wind_up_s *= CombatConstants.COUNTER_TEMPO_WINDUP_MULT
	var riposte_m: float = _CounterTempo.riposte_chain_windup_mult(manager, atk, target_id)
	if riposte_m < 1.0:
		wind_up_s *= riposte_m
	var clk: float = _EntityAccess.combat_clock_float(manager)
	var flurry_m: float = _FlurryBind.wind_up_mult(atk, target_id, clk)
	if flurry_m < 1.0:
		wind_up_s *= flurry_m
		_FlurryBind.consume_exchange_on_wind_up_start(atk)
	wind_up_s = _Exhaustion.apply_attacker_wind_up_exhaustion_mult(wind_up_s, atk)
	wind_up_s = minf(wind_up_s, CombatConstants.WIND_UP_DURATION_MAX_S)
	atk.gauge = 0.0
	atk["guard"] = CombatConstants.GUARD_AFTER_ATTACK
	atk.erase("guard_deflect_blend")
	atk.erase("guard_deflect_from_line")
	atk.erase("parry_was_bind")
	atk.erase("parry_against_id")
	atk.state = CombatConstants.STATE_WIND_UP
	atk.state_timer = 0.0
	atk.state_duration = wind_up_s
	# arc_intended_deg: intended target angle (no variance) — lets systems query blade position during wind-up.
	var arc_intended_deg: float = align_ctx["attack_angle_deg"]
	var pa: Dictionary = {"target_id": target_id, "intensity": intensity, "power": power, "follow_through": follow_through, "attack_type": attack_type, "archetype": archetype, "wind_up_duration": wind_up_s, "arc_start_deg": arc_start_deg, "arc_intended_deg": arc_intended_deg}
	pa["weapon_extension_commit_fraction"] = _WeaponPosition.commit_fraction_from_move_def(move_def)
	if weapon != null:
		pa["impact_blade_station"] = _StrikeRealism.roll_blade_station(weapon, attack_type, intensity)
	var target_part: String = str(options.get("target_part", ""))
	var feint_part: String = str(options.get("feint_part", ""))
	if not target_part.is_empty():
		pa["target_part"] = target_part
	if not feint_part.is_empty():
		pa["feint_part"] = feint_part
	# Tier 3.1: pair geometry + depth lane flags (`CombatStrikeStamping`; re-stamped each resolve).
	_StrikeStamping.stamp_attack_pair_and_strike_realism(manager, atk, tgt, pa, weapon, attack_type)
	if move_def.get("is_feint", false):
		pa["feint_windup_duration_mult"] = feint_windup_mult
		var reveal_at: float = float(move_def.get("feint_target_reveal_at_progress", 0.0))
		if reveal_at > 0.0:
			pa["feint_target_reveal_at_progress"] = clampf(reveal_at, 0.0, 1.0)
	_IncomingParryChoice.stamp_parry_telegraph_on_pa(pa, move_def)
	if counter_tempo:
		pa[CombatConstants.PA_KEY_COUNTER_TEMPO] = true
	if riposte_m < 1.0:
		pa[CombatConstants.PA_KEY_RIPOSTE_CHAIN] = true
		_CounterTempo.clear_riposte_chain(atk)
	var prev_pa: Dictionary = _EntityAccess.nested_dictionary_read(atk, "pending_attack")
	if not prev_pa.is_empty():
		clear_incoming_attack_telegraph_from_pa(manager, prev_pa)
	atk.pending_attack = pa
	# Feint D: defender reacts to telegraph at wind-up start. If feint, they guard feint_part; else they guard target_part.
	var telegraph_part: String = str(pa.get("feint_part", pa.get("target_part", "head")))
	tgt["guard_zone"] = telegraph_part
	tgt[CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART] = telegraph_part
	_Attention.set_focus_from_incoming_telegraph(tgt, telegraph_part)
	var hit_part_log: String = str(pa.get("target_part", "")).strip_edges()
	if not hit_part_log.is_empty():
		_Attention.record_attack_toward_defender(manager, attacker_id, tgt, hit_part_log)
	_CounterTempo.on_attacker_wind_up_started(manager, attacker_id, tgt, wind_up_s)
	var atk_name_log: String = _EntityAccess.get_display_name(atk, attacker_id)
	var tgt_name_log: String = _EntityAccess.get_display_name(tgt, target_id)
	_log_fp_tempo_wind_up(
		atk_name_log,
		tgt_name_log,
		wind_up_s,
		counter_tempo,
		riposte_m < 1.0,
		flurry_m < 1.0
	)
	if CombatConstants.combat_debug_active():
		var angle_info: String = " [atk=%.0f° guard=%.0f°]" % [align_ctx["attack_angle_deg"], align_ctx["guard_angle_deg"]]
		CombatDebug.log("%s | guard=%s atk_line=%s align=%.2f trans=%.2f%s | wind_up=%.2fs" % [atk_name_log, atk.get("guard_line", CombatConstants.GUARD_DEFAULT), attack_line, align, trans_mult, angle_info, wind_up_s])


## Clears Tier 4.2 **`COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART`** on the defender targeted by **`pa`** when that attack's `pending_attack` is consumed.
static func clear_incoming_attack_telegraph_from_pa(manager: Node, pa: Dictionary) -> void:
	if manager == null or pa.is_empty():
		return
	var tid: int = int(pa.get("target_id", -1))
	if tid < 0 or not manager.has_method("_get_by_id"):
		return
	var t: Variant = manager._get_by_id(tid)
	if t != null and t is Dictionary:
		var def_d: Dictionary = t as Dictionary
		def_d.erase(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART)
		def_d.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
