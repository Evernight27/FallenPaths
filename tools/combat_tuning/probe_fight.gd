extends SceneTree
## Headless duel probe: real CombatManager SWORD-vs-SWORD (and other weapons) driven through the
## D001 harness loop, with a play session active so per-hit `hit_resolve` lines (phys / dmg_int) and
## `soak_fight_end` strike counts are emitted. Prints per-rep duration, strike count, and per-hit damage.

const TICK_DT := 0.05
const MAX_SEC := 240.0
const REPS := 3

const _OpsLog := preload("res://core/OperationalLog.gd")
const _Helpers := preload("res://harness/d001/D001RunnerHelpers.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")


func _init() -> void:
	_OpsLog.set_capture_enabled(true)
	_OpsLog.begin_play_session("headless://probe_fight", "")
	CombatConstants.set_combat_dev_verbose_override(true)
	for wid in ["SWORD", "SPEAR", "AXE", "MACE", "DAGGER"]:
		for rep in range(REPS):
			_OpsLog.clear_capture()
			seed(hash("probe_fight_%s_%d" % [wid, rep]) & 0x7FFFFFFF)
			var mgr: Node = _start_duel(wid)
			var elapsed := _drive_fight(mgr)
			_OpsLog.play_combat(
				"probe_fight rep wid=%s rep=%d duration_s=%.1f medical=%s"
				% [wid, rep, elapsed, "yes" if bool(mgr.medical_phase) else "no"]
			)
			var winner: String = _Helpers._infer_soak_fight_winner(mgr)
			var end_line: String = _soak_end_line(winner, bool(mgr.medical_phase))
			_OpsLog.play_combat(end_line)
			_print_rep_stats(wid, rep, elapsed, _OpsLog.get_captured_lines())
			HarnessFixtures._free_manager(mgr)
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


var _samples: Array = []


func _drive_fight(mgr: Node) -> float:
	mgr.set_meta("_fp_harness_diag", true)
	var elapsed := 0.0
	while elapsed < MAX_SEC and mgr.is_processing():
		_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
		mgr._process(TICK_DT)
		_sample_strike_params(mgr)
		elapsed += TICK_DT
		if bool(mgr.medical_phase):
			break
	_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
	return elapsed


func _sample_strike_params(mgr: Node) -> void:
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		var st: String = CombatantEntityAccess.state_str(c)
		if st != CombatConstants.STATE_WIND_UP:
			continue
		var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
		var intens: float = float(pa.get("intensity", -1.0))
		if intens < 0.0:
			continue
		_samples.append(
			{
				"intensity": intens,
				"stamina": CombatantEntityAccess.stamina_ratio(c),
				"exhaustion": CombatantEntityAccess.exhaustion_float(c),
				"wind_up": float(pa.get("wind_up_duration", -1.0)),
				"attack_type": str(pa.get("attack_type", "")),
			}
		)


func _soak_end_line(winner: String, medical: bool) -> String:
	return "soak_fight_end winner=%s medical_phase=%s fight_profile=7v7 probe=duel" % [
		winner.strip_edges(),
		"true" if medical else "false",
	]


var _fp_warn_count := 0
var _resolve_rejected_count := 0
var _empty_pick_count := 0


func _print_rep_stats(wid: String, rep: int, elapsed: float, lines: PackedStringArray) -> void:
	var strikes := 0
	var hits := 0
	var total_phys := 0.0
	var total_dmg := 0.0
	var max_phys := 0.0
	var max_dmg := 0
	for raw in lines:
		var l: String = str(raw)
		if "resolve_rejected" in l:
			_resolve_rejected_count += 1
		if "FP_WARN" in l and "resolve_rejected" in l:
			_fp_warn_count += 1
		if "pick produced no actionable choice" in l:
			_empty_pick_count += 1
		if "hit_resolve" in l:
			strikes += 1
			if "outcome=hit" in l:
				hits += 1
			var phys := _extract_float(l, "phys=")
			var dmg := _extract_int(l, "dmg_int=")
			total_phys += phys
			total_dmg += float(dmg)
			max_phys = maxf(max_phys, phys)
			max_dmg = maxi(max_dmg, dmg)
	print(
		"PROBE_FIGHT %s rep%d duration=%.1fs strikes=%d hits=%d avg_phys=%.2f avg_dmg=%.2f max_phys=%.2f max_dmg=%d"
		% [wid, rep, elapsed, strikes, hits, total_phys / maxf(float(strikes), 1.0), total_dmg / maxf(float(strikes), 1.0), max_phys, max_dmg]
	)
	print(
		"PROBE_FIGHT_PARAMS %s rep%d samples=%d intensity=[%.2f..%.2f] stamina=[%.2f..%.2f] exhaustion=[%.2f..%.2f] wind_up=[%.2f..%.2f]"
		% [
			wid,
			rep,
			_samples.size(),
			_param_min("intensity"),
			_param_max("intensity"),
			_param_min("stamina"),
			_param_max("stamina"),
			_param_min("exhaustion"),
			_param_max("exhaustion"),
			_param_min("wind_up"),
			_param_max("wind_up"),
		]
	)
	print(
		"PROBE_FIGHT_FP_WARN %s rep%d fp_warn=%d resolve_rejected=%d empty_pick=%d"
		% [wid, rep, _fp_warn_count, _resolve_rejected_count, _empty_pick_count]
	)
	_samples.clear()


func _param_min(key: String) -> float:
	var best := 1e9
	for s in _samples:
		best = minf(best, float(s.get(key, 1e9)))
	return best if _samples.size() > 0 else 0.0


func _param_max(key: String) -> float:
	var best := -1e9
	for s in _samples:
		best = maxf(best, float(s.get(key, -1e9)))
	return best if _samples.size() > 0 else 0.0


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
