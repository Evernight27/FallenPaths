extends SceneTree
## Per-side hit breakdown for a seeded 1v1 duel (DAGGER by default). Captures every `hit_resolve`
## line and tallies strikes/hits/damage by attacker side, then dumps the final body state.

const TICK_DT := 0.05
const MAX_SEC := 120.0

const _OpsLog := preload("res://core/OperationalLog.gd")
const _Helpers := preload("res://harness/d001/D001RunnerHelpers.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")


func _init() -> void:
	_OpsLog.set_capture_enabled(true)
	_OpsLog.begin_play_session("headless://probe_hitsplit", "")
	CombatConstants.set_combat_dev_verbose_override(true)
	var wid: String = "DAGGER"
	for rep in range(2):
		_OpsLog.clear_capture()
		seed(hash("probe_fight_%s_%d" % [wid, rep]) & 0x7FFFFFFF)
		var mgr: Node = _start_duel(wid)
		var elapsed := _drive_fight(mgr)
		_OpsLog.play_combat("HITSPLIT wid=%s rep=%d duration_s=%.1f medical=%s" % [wid, rep, elapsed, "yes" if bool(mgr.medical_phase) else "no"])
		_print_split(wid, rep, _OpsLog.get_captured_lines())
		_dump_end_state(mgr)
		_CombatRegressionHarness._free_manager(mgr)
	_OpsLog.end_play_session()
	_OpsLog.set_capture_enabled(false)
	quit(0)


func _start_duel(wid: String) -> Node:
	var mgr: Node = CombatManager.new()
	mgr.encounter = {
		_SoakPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: "7v7",
		"mood_bias_player": 50.0,
		"mood_bias_enemy": 50.0,
	}
	mgr.register(_Helpers._new_entity(wid), "player")
	mgr.register(_Helpers._new_entity(wid), "enemy")
	mgr.start(_Helpers._player_1x1(), _Helpers._player_1x1())
	return mgr


func _drive_fight(mgr: Node) -> float:
	mgr.set_meta("_fp_harness_diag", true)
	var elapsed := 0.0
	while elapsed < MAX_SEC and mgr.is_processing():
		_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
		mgr._process(TICK_DT)
		elapsed += TICK_DT
		if bool(mgr.medical_phase):
			break
	_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
	return elapsed


func _print_split(wid: String, rep: int, lines: PackedStringArray) -> void:
	var sides := {
		"player": {"strikes": 0, "hits": 0, "dmg": 0.0, "phys": 0.0},
		"enemy": {"strikes": 0, "hits": 0, "dmg": 0.0, "phys": 0.0},
	}
	for raw in lines:
		var l: String = str(raw)
		if "hit_resolve" not in l:
			continue
		var arrow := l.find("->")
		if arrow < 0:
			continue
		var atk: String = _side_of(l.substr(0, arrow))
		var tail := l.substr(arrow + 2)
		var space := tail.find(" ")
		var tgt: String = _side_of(tail.substr(0, space if space >= 0 else tail.length()))
		var agg: Dictionary = sides.get(atk)
		if agg == null:
			continue
		agg["strikes"] = int(agg["strikes"]) + 1
		if "outcome=hit" in l:
			agg["hits"] = int(agg["hits"]) + 1
		agg["dmg"] = float(agg["dmg"]) + _extract_int(l, "dmg_int=")
		agg["phys"] = float(agg["phys"]) + _extract_float(l, "phys=")
	print(
		"HITSPLIT wid=%s rep=%d player_strikes=%d player_hits=%d player_dmg=%.0f player_phys=%.1f | enemy_strikes=%d enemy_hits=%d enemy_dmg=%.0f enemy_phys=%.1f"
		% [
			wid,
			rep,
			int(sides["player"]["strikes"]),
			int(sides["player"]["hits"]),
			float(sides["player"]["dmg"]),
			float(sides["player"]["phys"]),
			int(sides["enemy"]["strikes"]),
			int(sides["enemy"]["hits"]),
			float(sides["enemy"]["dmg"]),
			float(sides["enemy"]["phys"]),
		]
	)


func _side_of(part: String) -> String:
	var p: String = part.strip_edges()
	if p.is_empty():
		return "?"
	var ch: String = p.left(1)
	if ch == "P" or ch == "p":
		return "player"
	if ch == "E" or ch == "e":
		return "enemy"
	return "?"


func _dump_end_state(mgr: Node) -> void:
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		var node: Node = CombatantEntityAccess.scene_node(c)
		if node == null:
			continue
		var sd: String = CombatantEntityAccess.side_str(c)
		var cons: float = float(node.get("consciousness")) if "consciousness" in node else -1.0
		var blood: float = float(node.get("blood_volume")) if "blood_volume" in node else -1.0
		var parts := ""
		for part in [BodyPartConstants.PART_HEAD, BodyPartConstants.PART_CHEST,
				BodyPartConstants.PART_LEFT_ARM, BodyPartConstants.PART_RIGHT_ARM,
				BodyPartConstants.PART_LEFT_LEG, BodyPartConstants.PART_RIGHT_LEG]:
			var rem: float = 0.0
			if part in node.body_cutting:
				rem += float(node.body_cutting[part])
			if part in node.body_blunt:
				rem += float(node.body_blunt[part])
			var max_hp: float = float(node.body_max.get(part, 1.0))
			parts += " %s=%.2f(%.2f)" % [str(part).left(2), rem, max_hp]
		print("HITSPLIT_END %s cons=%.1f blood=%.1f parts:%s" % [sd, cons, blood, parts])


func _extract_float(line: String, key: String) -> float:
	var idx := line.find(key)
	if idx < 0:
		return 0.0
	var rest := line.substr(idx + key.length())
	var val := ""
	for ch in rest:
		if ch.is_valid_int() or ch == "." or ch == "-":
			val += ch
		else:
			break
	return float(val) if not val.is_empty() else 0.0


func _extract_int(line: String, key: String) -> int:
	var idx := line.find(key)
	if idx < 0:
		return 0
	var rest := line.substr(idx + key.length())
	var val := ""
	for ch in rest:
		if ch.is_valid_int() or ch == "-":
			val += ch
		else:
			break
	return int(val) if not val.is_empty() else 0
