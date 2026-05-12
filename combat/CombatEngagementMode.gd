class_name CombatEngagementMode
extends RefCounted

## Canonical engagement-mode classifier for transition-safe combat behavior.
## Modes:
## - formation: robust two-sided front line
## - skirmish: thinned/uneven line or one side missing front
## - duel: tiny 1v1 front contact

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _ZoneOfControl := preload("res://combat/ZoneOfControl.gd")
const _MODE_FORMATION := "formation"
const _MODE_SKIRMISH := "skirmish"
const _MODE_DUEL := "duel"
const _MODE_CACHE_META := "_engagement_mode_cached"


## Clear resolved-mode hysteresis on `CombatManager.start()` (or tests) so a new battle does not inherit prior `formation` stickiness.
static func clear_resolved_mode_cache(manager: Node) -> void:
	if manager != null and manager.has_meta(_MODE_CACHE_META):
		manager.remove_meta(_MODE_CACHE_META)


static func mode_code(mode_name: String) -> int:
	match mode_name:
		_MODE_FORMATION:
			return int(CombatConstants.ENGAGEMENT_MODE_CODE_FORMATION)
		_MODE_DUEL:
			return int(CombatConstants.ENGAGEMENT_MODE_CODE_DUEL)
		_:
			return int(CombatConstants.ENGAGEMENT_MODE_CODE_SKIRMISH)


## Human-readable engagement label for battle UI (resolved mode, not raw classifier).
static func mode_display_name(mode_name: String) -> String:
	match str(mode_name):
		_MODE_FORMATION:
			return "Formation line"
		_MODE_DUEL:
			return "Duel"
		_:
			return "Skirmish"


## Rank-0 **native** line for this formation: same `side` as the formation owner (excludes enemy intruders on host files).
static func count_front_rank_alive(manager: Node, formation_key: String) -> int:
	var n: int = 0
	if manager == null:
		return 0
	var native_side: String = formation_key
	var fm: Variant = manager.get("formations")
	if fm != null and typeof(fm) == TYPE_DICTIONARY:
		var form: Dictionary = _FormationSlots.formation_record_read(fm, formation_key)
		if not form.is_empty():
			native_side = _FormationSlots.formation_side_str(form, formation_key)
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.formation_id_str(c) != formation_key:
			continue
		if _EntityAccess.side_str(c) != native_side:
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		n += 1
	return n


static func _front_files_for_side(manager: Node, side: String) -> int:
	if manager == null:
		return 1
	var form: Dictionary = _FormationSlots.formation_record_read(manager.formations, side)
	if form.is_empty():
		return 1
	return maxi(1, int(form.get("files", 1)))


static func count_active_for_side(manager: Node, side: String) -> int:
	var n: int = 0
	if manager == null:
		return 0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.side_str(c) != side:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		n += 1
	return n


static func snapshot(manager: Node) -> Dictionary:
	var p: int = count_front_rank_alive(manager, "player")
	var e: int = count_front_rank_alive(manager, "enemy")
	var p_active: int = count_active_for_side(manager, "player")
	var e_active: int = count_active_for_side(manager, "enemy")
	var pf: int = _front_files_for_side(manager, "player")
	var ef: int = _front_files_for_side(manager, "enemy")
	var p_fill: float = clampf(float(p) / float(pf), 0.0, 1.0)
	var e_fill: float = clampf(float(e) / float(ef), 0.0, 1.0)
	var active_intrusions: int = active_intrusions_count(manager)
	var raw_mode: String = _MODE_SKIRMISH
	if CombatConstants.SKIRMISH_WHEN_EITHER_SIDE_ZERO_FRONT and (p == 0 or e == 0):
		raw_mode = _MODE_SKIRMISH
	elif (
		p_active <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
		or e_active <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
	):
		raw_mode = _MODE_DUEL
	elif (
		p <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
		and e <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
	):
		raw_mode = _MODE_DUEL
	elif (
		p_active >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
		and e_active >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
		and p >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
		and e >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
		and p_fill >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
		and e_fill >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
	):
		raw_mode = _MODE_FORMATION
	return {
		"player_active": p_active,
		"enemy_active": e_active,
		"player_front": p,
		"enemy_front": e,
		"player_front_fill": p_fill,
		"enemy_front_fill": e_fill,
		"active_intrusions": active_intrusions,
		"raw_mode": raw_mode,
		"raw_mode_code": mode_code(raw_mode),
	}


static func active_intrusions_count(manager: Node) -> int:
	if manager == null:
		return 0
	var n: int = 0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if not _ZoneOfControl.is_intruded(c):
			continue
		n += 1
	return n


## Alive intruders from this **attacking** side (home `side`; `engagement_role` intruded on host formation).
static func active_intruder_count_for_side(manager: Node, side: String) -> int:
	var n: int = 0
	if manager == null or side.is_empty():
		return 0
	for c in manager.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.side_str(c) != side:
			continue
		if _EntityAccess.is_incapacitated(c):
			continue
		if not _ZoneOfControl.is_intruded(c):
			continue
		n += 1
	return n


## Empty if this unit may attempt crash intrusion; otherwise a short reason for logs / debug.
static func crash_intrusion_attacker_block_reason(manager: Node, attacker: Dictionary) -> String:
	if not CombatConstants.FEATURE_LINE_CRASH_INTRUSION:
		return "intrusion_disabled"
	if attacker.is_empty():
		return "no_attacker"
	var side: String = _EntityAccess.side_str(attacker)
	if side.is_empty():
		return "no_side"
	if active_intruder_count_for_side(manager, side) >= int(CombatConstants.MAX_INTRUDERS_PER_SIDE):
		return "intruder_cap"
	var n: Node = _EntityAccess.scene_node(attacker)
	var mass: float = _EntityAccess.get_total_armor_mass_kg_from_node(n)
	if mass + 0.001 < float(CombatConstants.CRASH_INTRUSION_MIN_ARMOR_MASS_KG):
		return "light_armor"
	if CombatConstants.crash_breach_viability(attacker) + 0.0001 < float(CombatConstants.CRASH_BREACH_VIABILITY_MIN):
		return "low_breach_power"
	return ""


static func crash_intrusion_attacker_allowed(manager: Node, attacker: Dictionary) -> bool:
	return crash_intrusion_attacker_block_reason(manager, attacker).is_empty()


static func can_enter_formation_from_snapshot(snap: Dictionary) -> bool:
	return (
		int(snap.get("player_active", 0)) >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
		and int(snap.get("enemy_active", 0)) >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
		and int(snap.get("player_front", 0)) >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
		and int(snap.get("enemy_front", 0)) >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
		and float(snap.get("player_front_fill", 0.0)) >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
		and float(snap.get("enemy_front_fill", 0.0)) >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
	)


static func can_stay_formation_from_snapshot(snap: Dictionary) -> bool:
	var p: int = int(snap.get("player_front", 0))
	var e: int = int(snap.get("enemy_front", 0))
	return (
		p >= int(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE)
		and e >= int(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE)
		and float(snap.get("player_front_fill", 0.0)) >= float(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FILL_RATIO)
		and float(snap.get("enemy_front_fill", 0.0)) >= float(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FILL_RATIO)
		and not (
			int(snap.get("player_active", 0)) <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
			or int(snap.get("enemy_active", 0)) <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
		)
		and not (
			p <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
			and e <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
		)
	)


static func should_stick_formation_for_active_intrusions(snap: Dictionary) -> bool:
	var p: int = int(snap.get("player_front", 0))
	var e: int = int(snap.get("enemy_front", 0))
	var intrusions: int = int(snap.get("active_intrusions", 0))
	if intrusions <= 0:
		return false
	# Graceful downgrade: keep formation behavior while any intrusion is still active,
	# unless a side has no front line or the fight has clearly collapsed into a duel.
	if CombatConstants.SKIRMISH_WHEN_EITHER_SIDE_ZERO_FRONT and (p == 0 or e == 0):
		return false
	if (
		int(snap.get("player_active", 0)) <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
		or int(snap.get("enemy_active", 0)) <= int(CombatConstants.ENGAGEMENT_DUEL_MAX_ACTIVE_PER_SIDE)
	):
		return false
	if (
		p <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
		and e <= int(CombatConstants.DUEL_MAX_FRONT_FIGHTERS_PER_SIDE)
	):
		return false
	return true


static func engagement_mode(manager: Node) -> String:
	var snap: Dictionary = snapshot(manager)
	var raw_mode: String = str(snap.get("raw_mode", _MODE_SKIRMISH))
	if manager == null:
		return raw_mode
	var prev_mode: String = str(manager.get_meta(_MODE_CACHE_META, ""))
	# Hysteresis: once a cohesive formation exists, do not drop it immediately near threshold edges.
	if prev_mode == _MODE_FORMATION:
		var still_has_line: bool = can_stay_formation_from_snapshot(snap)
		if still_has_line:
			manager.set_meta(_MODE_CACHE_META, _MODE_FORMATION)
			return _MODE_FORMATION
		if should_stick_formation_for_active_intrusions(snap):
			manager.set_meta(_MODE_CACHE_META, _MODE_FORMATION)
			return _MODE_FORMATION
	manager.set_meta(_MODE_CACHE_META, raw_mode)
	return raw_mode


static func incursion_allowed(manager: Node) -> bool:
	if not CombatConstants.FEATURE_LINE_CRASH_INTRUSION:
		return false
	return engagement_mode(manager) == _MODE_FORMATION


## Canonical movement policy by resolved engagement mode.
## Keeps "which moves are legal" attached to mode thresholds/hysteresis in one place.
static func movement_policy(manager: Node) -> Dictionary:
	var snap: Dictionary = snapshot(manager)
	var mode_now: String = engagement_mode(manager)
	var intrusions: int = int(snap.get("active_intrusions", 0))
	var stable_line: bool = mode_now == _MODE_FORMATION and intrusions == 0
	var allow_line_maneuvers: bool = stable_line
	return {
		"mode": mode_now,
		"mode_code": mode_code(mode_now),
		"active_intrusions": intrusions,
		"allow_crash": mode_now == _MODE_FORMATION and CombatConstants.FEATURE_LINE_CRASH_INTRUSION,
		"allow_swap_rank": allow_line_maneuvers,
		"allow_drag_back": allow_line_maneuvers,
		"allow_fall_back": allow_line_maneuvers,
		"allow_rotate_file": allow_line_maneuvers,
	}


## Shared compact debug line for logs/UI/harness.
static func mode_summary_line(manager: Node) -> String:
	var snap: Dictionary = snapshot(manager)
	var mode_now: String = engagement_mode(manager)
	var mode_now_code: int = mode_code(mode_now)
	return (
		"mode=%s(%d) raw=%s(%d) intrusions=%d active[player=%d enemy=%d] front[player=%d enemy=%d] fill[player=%.2f enemy=%.2f]"
		% [
			mode_now,
			mode_now_code,
			str(snap.get("raw_mode", _MODE_SKIRMISH)),
			int(snap.get("raw_mode_code", mode_code(str(snap.get("raw_mode", _MODE_SKIRMISH))))),
			int(snap.get("active_intrusions", 0)),
			int(snap.get("player_active", 0)),
			int(snap.get("enemy_active", 0)),
			int(snap.get("player_front", 0)),
			int(snap.get("enemy_front", 0)),
			float(snap.get("player_front_fill", 0.0)),
			float(snap.get("enemy_front_fill", 0.0)),
		]
	)
