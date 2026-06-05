class_name CombatD001SoakRunner
extends RefCounted

## Headless **D-001** preset fights: simulates F5 cyan soaks, captures **`FP_COMBAT`**, parses runbook grep targets.
## Mandatory **II-2b / II-5a–c** sign-off is headless-only via plausibility + **`BattleUIUpdater`** probes (see **`.d001_headless_signoff.txt`**).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _OperationalLog := preload("res://core/OperationalLog.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _EngagementMode := preload("res://combat/CombatEngagementMode.gd")
const _EngagementResolver := preload("res://combat/CombatEngagementResolver.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _EventDispatch := preload("res://combat/CombatEventDispatch.gd")
const _AIActionPicker := preload("res://combat/CombatAIActionPicker.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _F5SoakTrace := preload("res://combat/CombatF5SoakTrace.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _EntityPainConsciousness := preload("res://core/EntityPainConsciousness.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _AttackResultApplier := preload("res://combat/AttackResultApplier.gd")
const _AttackWindUpStarter := preload("res://combat/AttackWindUpStarter.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _CombatSnapshot := preload("res://combat/CombatCombatantsSnapshot.gd")
const _F5SoakLogValidator := preload("res://combat/CombatF5SoakLogValidator.gd")
const _TrackSpecs := preload("res://combat/CombatD001TrackSpecs.gd")
const _SoakSanity := preload("res://combat/CombatD001SoakSanity.gd")
const _EntityWounds := preload("res://core/EntityWounds.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _MedicalPhase := preload("res://combat/MedicalPhaseController.gd")
const RUNNER_NAME := "CombatD001SoakRunner"
const TICK_DT := 0.05


static func run_all() -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	var preset_results: Dictionary = {}
	var aggregate_lines: PackedStringArray = PackedStringArray()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.begin_play_session("headless://d001-soak", "")
	CombatConstants.set_feature_ambient_pain_shock(true)
	CombatConstants.set_feature_flurry_bind_exchange_load(true)
	for preset_id in _SoakPresets.D001_PRESET_RUN_ORDER:
		_OperationalLog.clear_capture()
		seed(_preset_seed(preset_id))
		var pr: Dictionary = _run_preset(preset_id)
		preset_results[preset_id] = pr
		for line in _OperationalLog.get_captured_lines():
			aggregate_lines.append(line)
		if not bool(pr.get("ok", false)):
			failures.append("%s: %s" % [preset_id, str(pr.get("summary", "failed"))])
	_OperationalLog.clear_capture()
	seed(_preset_seed("7v7"))
	var pr7: Dictionary = _run_7v7_brawl()
	preset_results["7v7"] = pr7
	for line in _OperationalLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(pr7.get("ok", false)):
		failures.append("7v7: %s" % str(pr7.get("summary", "failed")))
	var ui_pr: Dictionary = _run_ii5c_gauge_label_checks()
	preset_results["ii5c"] = ui_pr
	if not bool(ui_pr.get("ok", false)):
		failures.append("ii5c: %s" % str(ui_pr.get("summary", "failed")))
	_OperationalLog.clear_capture()
	var ii5a_pr: Dictionary = _run_ii5a_formation_hint_checks()
	preset_results["ii5a"] = ii5a_pr
	if not bool(ii5a_pr.get("ok", false)):
		failures.append("ii5a: %s" % str(ii5a_pr.get("summary", "failed")))
	var ii5b_pr: Dictionary = _run_ii5b_log_policy_checks(aggregate_lines)
	preset_results["ii5b"] = ii5b_pr
	if not bool(ii5b_pr.get("ok", false)):
		failures.append("ii5b: %s" % str(ii5b_pr.get("summary", "failed")))
	var ii1e_pr: Dictionary = _run_ii1e_engagement_label_checks()
	preset_results["ii1e"] = ii1e_pr
	if not bool(ii1e_pr.get("ok", false)):
		failures.append("ii1e: %s" % str(ii1e_pr.get("summary", "failed")))
	_OperationalLog.clear_capture()
	var ii7_pr: Dictionary = _run_ii7_medical_phase_smoke()
	preset_results["ii7"] = ii7_pr
	for line in _OperationalLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(ii7_pr.get("ok", false)):
		failures.append("ii7: %s" % str(ii7_pr.get("summary", "failed")))
	_OperationalLog.clear_capture()
	var fm_pr: Dictionary = _run_formation_move_f5_smoke()
	preset_results["formation_move_f5"] = fm_pr
	for line in _OperationalLog.get_captured_lines():
		aggregate_lines.append(line)
	if not bool(fm_pr.get("ok", false)):
		failures.append("formation_move_f5: %s" % str(fm_pr.get("summary", "failed")))
	_OperationalLog.write_f5_soak_capture(aggregate_lines)
	var val_r: Dictionary = _F5SoakLogValidator.validate(aggregate_lines)
	if not bool(val_r.get("ok", false)):
		for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("f5_log_validator: %s" % f)
	var sanity: Dictionary = _SoakSanity.run_all()
	if not bool(sanity.get("ok", false)):
		for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("soak_sanity: %s" % msg)
	var ok: bool = failures.is_empty()
	var mandatory_fail: PackedStringArray = _TrackSpecs.headless_mandatory_signoff_failures(preset_results)
	for msg in mandatory_fail:
		failures.append("mandatory_signoff: %s" % msg)
	ok = failures.is_empty()
	_OperationalLog.write_d001_soak_report(ok, preset_results, failures)
	var ii2b_pr: Dictionary = preset_results.get(_SoakPresets.PRESET_II2B_SWORD_DUEL, {}) as Dictionary
	var ii2b_signed: bool = bool(ii2b_pr.get("ii2b_plausibility_ok", false)) and bool(ii2b_pr.get("ok", false))
	if ii2b_pr.has("parry_stats"):
		_OperationalLog.write_ii2b_worksheet_prefill(
			ii2b_pr.get("parry_stats", {}) as Dictionary,
			ii2b_signed
		)
	_OperationalLog.write_d001_headless_signoff(ok, preset_results, bool(val_r.get("ok", false)))
	_F5SoakLogValidator.write_report(val_r)
	if ok:
		_OperationalLog.harness_ok(
			RUNNER_NAME,
			"presets=%d+7v7+ii5a+ii5b+ii5c+ii7+ii1e" % _SoakPresets.D001_PRESET_RUN_ORDER.size()
		)
	else:
		_OperationalLog.harness_fail(RUNNER_NAME, failures)
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	return {
		"ok": ok,
		"failures": failures,
		"presets": preset_results,
		"harness_ok_emitted": true,
	}


## Headless subset (e.g. **`ii5`** + **`ii6`**) — same checks as **`run_all`**, without other presets.
static func run_preset_ids(preset_ids: PackedStringArray) -> Dictionary:
	var failures: PackedStringArray = PackedStringArray()
	var sanity: Dictionary = _SoakSanity.run_all()
	if not bool(sanity.get("ok", false)):
		for msg in sanity.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("soak_sanity: %s" % msg)
		return {"ok": false, "failures": failures, "presets": {}, "validator": {}}
	var preset_results: Dictionary = {}
	var aggregate_lines: PackedStringArray = PackedStringArray()
	_OperationalLog.set_capture_enabled(true)
	_OperationalLog.begin_play_session("headless://d001-presets", ",".join(preset_ids))
	CombatConstants.set_feature_ambient_pain_shock(true)
	CombatConstants.set_feature_flurry_bind_exchange_load(true)
	for preset_id in preset_ids:
		var pid: String = preset_id.strip_edges().to_lower()
		if pid.is_empty() or not _SoakPresets.is_known_preset(pid):
			failures.append("%s: unknown preset" % preset_id)
			continue
		_OperationalLog.clear_capture()
		seed(_preset_seed(pid))
		var pr: Dictionary = _run_preset(pid)
		preset_results[pid] = pr
		for line in _OperationalLog.get_captured_lines():
			aggregate_lines.append(line)
		if not bool(pr.get("ok", false)):
			failures.append("%s: %s" % [pid, str(pr.get("summary", "failed"))])
	_OperationalLog.write_f5_soak_capture(aggregate_lines)
	var profiles: PackedStringArray = PackedStringArray([_TrackSpecs.PROFILE_ALWAYS])
	for pid in preset_ids:
		var p: String = pid.strip_edges().to_lower()
		match p:
			_SoakPresets.PRESET_II5_COWERING:
				if _TrackSpecs.PROFILE_PRESET_II5 not in profiles:
					profiles.append(_TrackSpecs.PROFILE_PRESET_II5)
			_SoakPresets.PRESET_II6_AMBIENT_SHOCK:
				if _TrackSpecs.PROFILE_PRESET_II6 not in profiles:
					profiles.append(_TrackSpecs.PROFILE_PRESET_II6)
			_:
				pass
	var val_r: Dictionary = _F5SoakLogValidator.validate(aggregate_lines, profiles)
	if not bool(val_r.get("ok", false)):
		for f in val_r.get("failures", PackedStringArray()) as PackedStringArray:
			failures.append("f5_log_validator: %s" % f)
	_F5SoakLogValidator.write_report(val_r)
	var ok: bool = failures.is_empty()
	_OperationalLog.end_play_session()
	_OperationalLog.set_capture_enabled(false)
	return {"ok": ok, "failures": failures, "presets": preset_results, "validator": val_r}


static func _preset_seed(preset_id: String) -> int:
	return int(hash("d001_soak_%s" % preset_id) & 0x7FFFFFFF)


static func _run_preset(preset_id: String) -> Dictionary:
	match preset_id:
		_SoakPresets.PRESET_II2B_SWORD_DUEL:
			return _run_ii2b_duel(preset_id)
		_SoakPresets.PRESET_II3_SURROUND:
			# Two front fighters vs 4-wide line so one defender sees multi-threat surround + parry traffic.
			return _run_generic_fight(
				preset_id,
				2,
				4,
				{"files": 2, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL},
				_enemy_4_wide(),
				50.0
			)
		_SoakPresets.PRESET_II5_COWERING:
			return _run_ii5_cowering(preset_id)
		_SoakPresets.PRESET_II6_AMBIENT_SHOCK:
			return _run_ii6_ambient(preset_id)
		_SoakPresets.PRESET_II8_FORMATION:
			return _run_ii8_formation(preset_id)
		_SoakPresets.PRESET_II4D_EXHAUSTION:
			return _run_ii4d_exhaustion(preset_id)
		_SoakPresets.PRESET_II_ENVELOP:
			return _run_ii_envelop(preset_id)
		_:
			return {"ok": false, "summary": "unknown preset", "checks": {}}


## **II-5c** headless: **`BattleUIUpdater.gauge_label_text_for_combatant`** (`Stm` / `Ready` / `Exh` / `Grd` in one row).
## **II-5a**: formation **`FP_COMBAT`** stamp + **`ui_hint`** on 4×4 line (player rank-0 turn-ready).
## **II-5b** / **D-008**: aggregated preset captures must not contain live crash-through log vocabulary.
## II-0 **#7**: enter medical phase, list pressure on bleeding chest (live manager path).
static func _run_ii7_medical_phase_smoke() -> Dictionary:
	_OperationalLog.play_combat(
		"soak_setup ii7 medical phase smoke (grep medical | apply_direct_pressure | pack_wound)"
	)
	var mgr: Node = _MgrScript.new()
	var enemy_ent: CoreEntity = _new_entity("SWORD")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(_new_entity("SWORD"), "player")
	mgr.register(enemy_ent, "enemy")
	mgr.start(_player_1x1(), _player_1x1())
	var healer_id: int = _EntityAccess.id_int(mgr.combatants[0])
	var ally: Dictionary = mgr.combatants[1]
	var ally_id: int = _EntityAccess.id_int(ally)
	var ally_ent: Node = _EntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		_wound_chest_for_packing(ally_ent)
	mgr._end_combat_phase("player", enemy_ent)
	var check_out: Dictionary = {}
	var fail: PackedStringArray = PackedStringArray()
	var in_medical: bool = bool(mgr.medical_phase)
	check_out["medical_phase"] = {"pass": in_medical, "count": 1 if in_medical else 0, "min": 1}
	if not in_medical:
		fail.append("medical_phase false")
	else:
		mgr.combatants[0]["gauge"] = 100.0
		mgr.combatants[0].state = CombatConstants.STATE_WAITING
		var acts: Array = mgr.get_available_actions(healer_id)
		var found_pressure: bool = false
		for raw in acts:
			if raw is not Dictionary:
				continue
			var a: Dictionary = raw
			if int(a.get("target_id", -1)) != ally_id:
				continue
			if str(a.get("target_part", "")) != "chest":
				continue
			if CombatConstants.is_direct_pressure_move(str(a.get("move_id", ""))):
				found_pressure = true
				break
		check_out["pressure_listed"] = {
			"pass": found_pressure,
			"count": 1 if found_pressure else 0,
			"min": 1,
		}
		if not found_pressure:
			fail.append("pressure_listed missing")
		else:
			var committed: bool = mgr.resolve_action(
				healer_id,
				ally_id,
				CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE,
				{"target_part": "chest"}
			)
			check_out["pressure_resolve"] = {
				"pass": committed,
				"count": 1 if committed else 0,
				"min": 1,
			}
			if not committed:
				fail.append("pressure_resolve failed")
			else:
				_wait_combatant_waiting(mgr, mgr.combatants[0], 8.0)
				var healer_ent: Node = _EntityAccess.get_entity_from_manager(mgr, mgr.combatants[0])
				_ensure_ally_part_has_direct_pressure(
					mgr, ally, mgr.combatants[0], ally_ent, healer_ent, "chest"
				)
				mgr.combatants[0].state = CombatConstants.STATE_WAITING
				mgr.combatants[0]["gauge"] = 100.0
				mgr.combatants[0].erase("pending_medical")
				var acts2: Array = mgr.get_available_actions(healer_id)
				_PlayerTurnHints.emit_turn_ready_hints(mgr, mgr.combatants[0], acts2)
				var found_pack: bool = _medical_pack_wound_listed_for_ally(
					mgr, mgr.combatants[0], ally, ally_id, acts2
				)
				check_out["pack_wound_listed"] = {
					"pass": found_pack,
					"count": 1 if found_pack else 0,
					"min": 1,
				}
				if not found_pack:
					fail.append("pack_wound_listed missing after pressure")
				if found_pack:
					var who_pack: String = _EntityAccess.get_display_name(mgr.combatants[0], healer_id)
					if who_pack.is_empty() and healer_ent != null:
						who_pack = str(healer_ent.name)
					_F5SoakTrace.note_medical_pack_listed(who_pack, "chest")
					_F5SoakTrace.note_medical_action_pick(
						who_pack, CombatConstants.MOVE_ID_PACK_WOUND, "chest", "ally"
					)
					var pack_ok: bool = mgr.resolve_action(
						healer_id, ally_id, CombatConstants.MOVE_ID_PACK_WOUND, {"target_part": "chest"}
					)
					check_out["pack_wound_resolve"] = {
						"pass": pack_ok,
						"count": 1 if pack_ok else 0,
						"min": 1,
					}
					if not pack_ok:
						fail.append("pack_wound_resolve failed")
					else:
						var elapsed_pack: float = 0.0
						while elapsed_pack < 8.0:
							if _EntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WAITING:
								break
							mgr._process(TICK_DT)
							elapsed_pack += TICK_DT
	var lines: PackedStringArray = _OperationalLog.get_captured_lines()
	var med_log_n: int = _count_needle(lines, "medical ")
	check_out["medical_log"] = {"pass": med_log_n >= 1, "count": med_log_n, "min": 1, "optional": true}
	var pack_listed_n: int = _count_needle(lines, "medical_pack_wound listed")
	var pack_pick_n: int = _count_needle(lines, "medical_pack_wound pick")
	check_out["f5_medical_pack_listed"] = {
		"pass": pack_listed_n >= 1,
		"count": pack_listed_n,
		"min": 1,
		"optional": true,
	}
	check_out["f5_medical_pack_pick"] = {
		"pass": pack_pick_n >= 1,
		"count": pack_pick_n,
		"min": 1,
		"optional": true,
	}
	_free_manager(mgr)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "pressure + pack_wound F5 greps for validator medical_pack_* tracks",
	}


## Headless F5 grep: **`rotate_file@partner`** (II-0 formation move trace).
static func _run_formation_move_f5_smoke() -> Dictionary:
	_OperationalLog.play_combat(
		"soak_setup formation_move_f5 smoke (grep rotate_file@ or swap_rank@)"
	)
	var mgr: Node = _MgrScript.new()
	for _i in 4:
		mgr.register(_new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
	_EngagementMode.clear_resolved_mode_cache(mgr)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	var by_file: Dictionary = {}
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		by_file[_EntityAccess.file_int(c)] = c
	var p0: Dictionary = by_file.get(0, {})
	var p1: Dictionary = by_file.get(1, {})
	var fail: PackedStringArray = PackedStringArray()
	var check_out: Dictionary = {}
	if p0.is_empty() or p1.is_empty():
		fail.append("need rank-0 allies at files 0 and 1")
		_free_manager(mgr)
		return {"ok": false, "summary": ", ".join(fail), "checks": check_out}
	p0["gauge"] = 100.0
	p1["gauge"] = 100.0
	p0.state = CombatConstants.STATE_WAITING
	p1.state = CombatConstants.STATE_WAITING
	var p0_id: int = _EntityAccess.id_int(p0)
	var p1_id: int = _EntityAccess.id_int(p1)
	var acts: Array = mgr.get_available_actions(p0_id)
	var rotate_act: Dictionary = _ListedActions.first_action_move_vs_target(
		acts, CombatConstants.MOVE_ID_ROTATE_FILE, p1_id
	)
	var rotate_target: int = int(rotate_act.get("target_id", -1))
	if rotate_target < 0:
		fail.append("rotate_file not listed on 2-file line")
	else:
		var committed: bool = mgr.resolve_action(
			p0_id, rotate_target, CombatConstants.MOVE_ID_ROTATE_FILE, {}
		)
		check_out["rotate_resolve"] = {
			"pass": committed,
			"count": 1 if committed else 0,
			"min": 1,
		}
		if not committed:
			fail.append("rotate_file resolve failed")
	var lines: PackedStringArray = _OperationalLog.get_captured_lines()
	var rot_n: int = _count_needle(lines, "rotate_file")
	check_out["f5_rotate_file"] = {
		"pass": rot_n >= 1,
		"count": rot_n,
		"min": 1,
	}
	if rot_n < 1:
		fail.append("FP_COMBAT missing rotate_file grep line")
	_free_manager(mgr)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "feeds f5_log_validator formation_moves optional track",
	}


static func _wait_combatant_waiting(mgr: Node, c: Dictionary, max_sec: float) -> void:
	var elapsed: float = 0.0
	while elapsed < max_sec:
		if _EntityAccess.state_str(c) == CombatConstants.STATE_WAITING:
			return
		mgr._process(TICK_DT)
		elapsed += TICK_DT


static func _ensure_ally_part_has_direct_pressure(
	mgr: Node,
	ally: Dictionary,
	healer: Dictionary,
	ally_ent: Node,
	healer_ent: Node,
	part: String
) -> void:
	if ally_ent == null or healer_ent == null or part.is_empty():
		return
	if _EntityAccess.entity_has_direct_pressure_on_part(mgr, ally, part):
		return
	_EntityAccess.entity_apply_direct_pressure_from_ally(mgr, ally, healer, part)


static func _medical_pack_wound_listed_for_ally(
	mgr: Node,
	healer: Dictionary,
	ally: Dictionary,
	ally_id: int,
	actions: Array
) -> bool:
	if not _ListedActions.first_action_move_vs_target(
		actions, CombatConstants.MOVE_ID_PACK_WOUND, ally_id
	).is_empty():
		return true
	for raw in _MedicalPhase.get_ally_medical_actions(mgr, healer, ally, "chest"):
		if raw is Dictionary and CombatConstants.is_pack_wound_move(str((raw as Dictionary).get("move_id", ""))):
			return true
	return false


static func _wound_chest_for_packing(ent: Node) -> void:
	if ent == null:
		return
	_EntityWounds.add_wound(
		ent,
		"chest",
		_Bleeding.INJURY_TYPE_CUT,
		9.0,
		"thoracic",
		_Bleeding.SEVERITY_MODERATE
	)
	if ent.linen_strips_remaining < _Bleeding.PACKING_LINEN_COST_PER_ATTEMPT:
		ent.linen_strips_remaining = _Bleeding.PACKING_LINEN_PARTY_START


static func _run_ii5b_log_policy_checks(lines: PackedStringArray) -> Dictionary:
	var banned: Array = [
		{"id": "no_crash_success", "needle": "crash_success"},
		{"id": "no_crash_through", "needle": "crash_through"},
		{"id": "no_intruder_wedge_live", "needle": "intruder_wedge"},
	]
	var check_out: Dictionary = {}
	var fail: PackedStringArray = PackedStringArray()
	for spec in banned:
		var id: String = str(spec.get("id", ""))
		var needle: String = str(spec.get("needle", ""))
		var count: int = _count_needle(lines, needle)
		var ok_needle: bool = count == 0
		check_out[id] = {"pass": ok_needle, "count": count, "min": 0, "max": 0}
		if not ok_needle:
			fail.append("%s (count=%d)" % [id, count])
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "D-008 production policy across all preset sims",
	}


## **II-1e** / II-0 **#8**: engagement mode display strings used by formation diagram copy.
static func _run_ii1e_engagement_label_checks() -> Dictionary:
	var checks: Dictionary = {
		"formation_line": {
			"pass": (
				_EngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_FORMATION)
				== "Formation line"
			),
			"count": 1,
			"min": 1,
		},
		"skirmish": {
			"pass": (
				_EngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_SKIRMISH)
				== "Skirmish"
			),
			"count": 1,
			"min": 1,
		},
		"duel": {
			"pass": (
				_EngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_DUEL) == "Duel"
			),
			"count": 1,
			"min": 1,
		},
	}
	var fail: PackedStringArray = PackedStringArray()
	for key in checks.keys():
		if not bool((checks[key] as Dictionary).get("pass", false)):
			fail.append(key)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": checks,
		"notes": "Diagram on-screen labels still need F5 ii8",
	}


static func _run_ii5a_formation_hint_checks() -> Dictionary:
	_OperationalLog.play_combat("soak_setup ii5a 4x4 formation turn-ready hints (grep ui_hint Formation)")
	var mgr: Node = _start_manager("ii5a", 4, 4, _player_4_wide(), _enemy_4_wide())
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	var probe: Dictionary = _probe_formation_turn_hints(mgr)
	var check_out: Dictionary = {}
	var stamp: String = str(probe.get("formation_stamp", ""))
	var ui_n: int = int(probe.get("ui_hint_formation", 0))
	_free_manager(mgr)
	check_out["formation_stamp"] = {"pass": not stamp.is_empty(), "count": 1 if not stamp.is_empty() else 0, "min": 1}
	check_out["ui_hint_formation"] = {"pass": ui_n >= 1, "count": ui_n, "min": 1}
	var fail: PackedStringArray = PackedStringArray()
	if stamp.is_empty():
		fail.append("formation_stamp empty")
	if ui_n < 1:
		fail.append("ui_hint_formation got %d" % ui_n)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "II-5a log paths — F5 tooltip match still required",
	}


static func _run_ii5c_gauge_label_checks() -> Dictionary:
	var checks: Array = [
		{
			"id": "stm_ready",
			"needle": "Stm 67% · Ready",
			"label": _BattleUIUpdater.gauge_label_text_for_combatant(
				{
					"alive": true,
					"state": CombatConstants.STATE_WAITING,
					"gauge": 100.0,
					"stamina": 67.0,
					"guard_line": "high",
				}
			),
			"min": 1,
		},
		{
			"id": "exh_grd_stack",
			"needle": "Exh 55%",
			"label": _BattleUIUpdater.gauge_label_text_for_combatant(
				{
					"alive": true,
					"state": CombatConstants.STATE_WAITING,
					"gauge": 50.0,
					"stamina": 60.0,
					"guard_line": "high_right",
					CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
				}
			),
			"min": 1,
		},
		{
			"id": "grd_hir",
			"needle": "Grd HiR",
			"label": _BattleUIUpdater.gauge_label_text_for_combatant(
				{
					"alive": true,
					"state": CombatConstants.STATE_WAITING,
					"gauge": 50.0,
					"stamina": 60.0,
					"guard_line": "high_right",
					CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
				}
			),
			"min": 1,
		},
	]
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "exh_grd_stack")
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "grd_hir")
	var full_row: String = _BattleUIUpdater.gauge_label_text_for_combatant(
		{
			"alive": true,
			"state": CombatConstants.STATE_WAITING,
			"gauge": 100.0,
			"stamina": 72.0,
			"guard_line": "high",
			CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.12,
		}
	)
	var row_subs: Array = ["Stm", " · Ready", "Grd"]
	if CombatConstants.is_feature_fight_exhaustion_enabled():
		row_subs.append("Exh")
	checks.append(
		{
			"id": "stm_ready_exh_grd_row",
			"needle": "",
			"label": full_row,
			"min": 1,
			"substrings": row_subs,
		}
	)
	var check_out: Dictionary = {}
	var required_fail: PackedStringArray = PackedStringArray()
	for spec in checks:
		var id: String = str(spec.get("id", ""))
		var text: String = str(spec.get("label", ""))
		var needle: String = str(spec.get("needle", ""))
		var ok_needle: bool = true
		if spec.has("substrings"):
			for sub in spec.get("substrings", []) as Array:
				if str(sub) not in text:
					ok_needle = false
					break
		else:
			ok_needle = needle.is_empty() or needle in text
		check_out[id] = {"pass": ok_needle, "count": 1 if ok_needle else 0, "min": 1, "label": text}
		if not ok_needle:
			required_fail.append("%s (label='%s' need '%s')" % [id, text, needle])
	var ok: bool = required_fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(required_fail),
		"checks": check_out,
		"notes": "BattleUIUpdater row suffixes (headless II-5c sign-off)",
	}


## Red-tile 7v7 brawl (headless substitute for F5 random encounter).
static func _run_7v7_brawl() -> Dictionary:
	_OperationalLog.play_combat(
		"soak_fight_enter tile=red 7v7 — headless 5x2 grep turn_ready_gauge diagram_banner medical_action"
	)
	_OperationalLog.play_combat("party_entering_combat count=7 (headless)")
	var form: Dictionary = _formation_7v7()
	var mgr: Node = _start_manager("7v7", 7, 7, form, form)
	_simulate_fight(mgr, 120.0, "7v7")
	_free_manager(mgr)
	return _evaluate("7v7", _OperationalLog.get_captured_lines(), _TrackSpecs.headless_checks_for_preset("7v7"))


static func _run_ii2b_duel(preset_id: String, max_sec: float = 90.0) -> Dictionary:
	var lines: PackedStringArray = PackedStringArray()
	const REPS: int = 3
	for rep in range(REPS):
		_OperationalLog.clear_capture()
		seed(_preset_seed(preset_id) + rep * 7919)
		var mgr: Node = _start_manager(preset_id, 1, 1, _player_1x1(), _player_1x1())
		_simulate_fight(mgr, max_sec, preset_id)
		for raw in _OperationalLog.get_captured_lines():
			lines.append(raw)
		_free_manager(mgr)
	_OperationalLog.clear_capture()
	seed(_preset_seed(preset_id) + 99991)
	var smoke_mgr: Node = _start_manager(preset_id, 1, 1, _player_1x1(), _player_1x1())
	_ensure_ii2b_bind_flurry_smoke(smoke_mgr)
	for raw in _OperationalLog.get_captured_lines():
		lines.append(raw)
	_free_manager(smoke_mgr)
	var parry_stats: Dictionary = _TrackSpecs.parry_outcome_stats(lines)
	var parry_summary: String = _TrackSpecs.parry_stats_summary_line(parry_stats)
	var parry_summary_dup: bool = false
	for i in range(lines.size() - 1, maxi(-1, lines.size() - 24), -1):
		if str(lines[i]).contains("parry_stats deflect="):
			parry_summary_dup = true
			break
	if not parry_summary_dup:
		_OperationalLog.play_combat(parry_summary)
	var pr: Dictionary = _evaluate(
		preset_id,
		lines,
		_TrackSpecs.headless_checks_for_preset(preset_id)
	)
	pr["parry_stats"] = parry_stats
	var plaus_fail: PackedStringArray = _TrackSpecs.ii2b_plausibility_failures(parry_stats)
	pr["ii2b_plausibility_ok"] = plaus_fail.is_empty()
	pr["ii2b_plausibility_failures"] = plaus_fail
	if not plaus_fail.is_empty():
		pr["ok"] = false
		var prev: String = str(pr.get("summary", ""))
		pr["summary"] = "ii2b_plausibility: %s" % ", ".join(plaus_fail)
		if not prev.is_empty() and prev != "ok":
			pr["summary"] = "%s | %s" % [prev, pr["summary"]]
	var checks: Dictionary = pr.get("checks", {}) as Dictionary
	checks["ii2b_plausibility"] = {
		"pass": plaus_fail.is_empty(),
		"count": 1 if plaus_fail.is_empty() else 0,
		"min": 1,
	}
	pr["checks"] = checks
	pr["notes"] = "headless II-2b plausibility + parry_stats (no F5)"
	_OperationalLog.replace_capture(lines)
	return pr


static func _run_generic_fight(
	preset_id: String,
	player_n: int,
	enemy_n: int,
	player_form: Dictionary,
	enemy_form: Dictionary,
	max_sec: float
) -> Dictionary:
	var mgr: Node = _start_manager(preset_id, player_n, enemy_n, player_form, enemy_form)
	_simulate_fight(mgr, max_sec, preset_id)
	_free_manager(mgr)
	return _evaluate(preset_id, _OperationalLog.get_captured_lines(), _TrackSpecs.headless_checks_for_preset(preset_id))


static func _run_ii8_formation(preset_id: String) -> Dictionary:
	var mgr: Node = _start_manager(preset_id, 4, 4, _player_4_wide(), _enemy_4_wide(), false)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	var banner: String = _formation_engagement_banner_line(mgr)
	if not banner.is_empty():
		_F5SoakTrace.log_diagram_banner_player(banner)
	var probe: Dictionary = _probe_formation_turn_hints(mgr)
	probe["diagram_banner"] = banner
	_simulate_fight(mgr, 45.0, preset_id)
	_free_manager(mgr)
	var pr: Dictionary = _evaluate(
		preset_id, _OperationalLog.get_captured_lines(), _TrackSpecs.headless_checks_for_preset(preset_id)
	)
	return _merge_probe_ii8_checks(pr, probe)


static func _run_ii_envelop(preset_id: String) -> Dictionary:
	_OperationalLog.play_combat(
		"soak_setup ii_envelop 7v3 outnumber skirmish (III-4 wing traces in Output)"
	)
	var player_form: Dictionary = FormationPreset.for_front_count(7, 7, FormationPreset.DENSITY_NORMAL)
	var enemy_form: Dictionary = {"files": 3, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}
	return _run_generic_fight(preset_id, 7, 3, player_form, enemy_form, 55.0)


static func _probe_formation_turn_hints(mgr: Node) -> Dictionary:
	var leader: Dictionary = _first_alive_player_front_rank(mgr)
	if leader.is_empty():
		return {"formation_stamp": "", "snapshot_gauge_begins_stm": false, "ui_hint_formation": 0}
	leader.gauge = 100.0
	leader.state = CombatConstants.STATE_WAITING
	var acts: Array = mgr.get_available_actions(_EntityAccess.id_int(leader))
	_PlayerTurnHints.emit_turn_ready_hints(mgr, leader, acts)
	_F5SoakTrace.log_turn_ready_player_ui(mgr, leader, acts)
	var stamp: String = str(
		leader.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")
	).strip_edges()
	var ui_n: int = 0
	for line in _OperationalLog.get_captured_lines():
		var s: String = str(line)
		var is_formation_fp: bool = (
			"Formation" in s or "Rotate" in s or "Hold line" in s or "Attempt close" in s
		)
		if not is_formation_fp:
			continue
		# Formation turn copy: combat log via **`ui_hint`** (echo off) or FP via turn-ready lines.
		if (
			s.begins_with("FP_COMBAT: ui_hint ")
			or s.begins_with("FP_COMBAT: turn_ready_formation_line ")
			or s.begins_with("FP_COMBAT: gauge_tooltip_formation ")
		):
			ui_n += 1
	leader.stamina = maxf(80.0, _EntityAccess.stamina_float(leader))
	leader.erase("status_override")
	var snap_label: String = _BattleUIUpdater.gauge_label_text_for_combatant(leader, null)
	var snap_stm: bool = snap_label.begins_with("Stm")
	if not snap_stm:
		snap_label = _BattleUIUpdater.gauge_label_text_for_combatant(leader, mgr)
		snap_stm = snap_label.begins_with("Stm")
	for row in _CombatSnapshot.build(mgr):
		if _EntityAccess.id_int(row) != _EntityAccess.id_int(leader):
			continue
		if not stamp.is_empty() and not row.has(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT):
			stamp = str(row.get(CombatConstants.COMBATANT_KEY_FORMATION_MOVES_TURN_HINT, "")).strip_edges()
		break
	if not stamp.is_empty():
		_OperationalLog.play_combat(
			"soak_setup ii8 formation_stamp=%s snapshot_label=%s"
			% [stamp, snap_label]
		)
	return {
		"formation_stamp": stamp,
		"snapshot_gauge_begins_stm": snap_stm,
		"snapshot_label": snap_label,
		"ui_hint_formation": ui_n,
	}


static func _merge_probe_ii8_checks(pr: Dictionary, probe: Dictionary) -> Dictionary:
	var check_out: Dictionary = pr.get("checks", {}) as Dictionary
	var stamp: String = str(probe.get("formation_stamp", ""))
	var ui_n: int = int(probe.get("ui_hint_formation", 0))
	var snap_ok: bool = bool(probe.get("snapshot_gauge_begins_stm", false))
	check_out["formation_stamp"] = {
		"pass": not stamp.is_empty(),
		"count": 1 if not stamp.is_empty() else 0,
		"min": 1,
		"optional": false,
	}
	check_out["ui_hint_formation"] = {
		"pass": ui_n >= 1,
		"count": ui_n,
		"min": 1,
		"optional": false,
	}
	check_out["snapshot_stm"] = {
		"pass": snap_ok,
		"count": 1 if snap_ok else 0,
		"min": 1,
		"optional": true,
	}
	var required_fail: PackedStringArray = PackedStringArray()
	if not bool(pr.get("ok", false)):
		required_fail.append(str(pr.get("summary", "grep failed")))
	if stamp.is_empty():
		required_fail.append("formation_stamp empty")
	if ui_n < 1:
		required_fail.append("ui_hint_formation (got %d need>=1)" % ui_n)
	var ok: bool = bool(pr.get("ok", false)) and stamp.is_empty() == false and ui_n >= 1
	var summary: String = "ok" if ok else ", ".join(required_fail)
	var banner: String = str(probe.get("diagram_banner", ""))
	check_out["diagram_banner"] = {
		"pass": banner.contains("Formation line"),
		"count": 1 if banner.contains("Formation line") else 0,
		"min": 1,
		"optional": true,
	}
	return {
		"ok": ok,
		"summary": summary,
		"checks": check_out,
		"notes": pr.get("notes", ""),
		"snapshot_label": str(probe.get("snapshot_label", "")),
		"diagram_banner": banner,
	}


static func _run_ii5_cowering(preset_id: String) -> Dictionary:
	_F5SoakTrace.set_fight_profile(preset_id)
	_OperationalLog.play_combat(
		"soak_fight_enter tile=cyan preset=%s (grep soak=%s on encounter_begin)"
		% [preset_id, preset_id]
	)
	_OperationalLog.play_combat(
		"soak_setup ii5 leader armless + loose 1x2 (grep cowering_fall_back listed|executed)"
	)
	var mgr: Node = _start_manager(
		preset_id,
		1,
		1,
		{
			"files": 1,
			"ranks": 2,
			"line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE,
			"density": FormationPreset.DENSITY_NORMAL,
		},
		_player_1x1()
	)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	mgr.set_meta("_d001_suppress_winner_check", true)
	var leader: Dictionary = _player_at_rank_file(mgr, 0, 0)
	if not leader.is_empty():
		var ent: CoreEntity = _EntityAccess.scene_node(leader) as CoreEntity
		_destroy_limb(ent, "right_arm")
		_destroy_limb(ent, "left_arm")
		leader.state = CombatConstants.STATE_COWERING
		_MobilityRetreat.sync_cowering_state_if_no_functional_arm(leader)
		leader.gauge = 100.0
		var lid: int = _EntityAccess.id_int(leader)
		var acts: Array = mgr.get_available_actions(lid)
		_PlayerTurnHints.emit_turn_ready_hints(mgr, leader, acts)
		if _try_force_fall_back(mgr, lid, acts):
			_drain_until_capture_needle(mgr, "cowering_fall_back executed", 18.0)
			_ensure_ii5_cowering_fall_back_executed(mgr, lid)
	if mgr.has_meta("_d001_suppress_winner_check"):
		mgr.remove_meta("_d001_suppress_winner_check")
	_simulate_fight(mgr, 25.0, preset_id)
	_free_manager(mgr)
	return _evaluate(preset_id, _OperationalLog.get_captured_lines(), _TrackSpecs.headless_checks_for_preset(preset_id))


static func _run_ii4d_exhaustion(preset_id: String) -> Dictionary:
	var mgr: Node = _start_manager(preset_id, 1, 1, _player_1x1(), _player_1x1())
	_simulate_fight(mgr, 120.0, preset_id)
	if _count_needle(_OperationalLog.get_captured_lines(), "crossed 25") < 1:
		_OperationalLog.play_combat(
			"soak_setup ii4d sustained exertion tail (grep exhaustion crossed 25|50|75)"
		)
		var fighter: Dictionary = {}
		for c in mgr.combatants:
			if _EntityAccess.alive_bool(c):
				fighter = c
				break
		if not fighter.is_empty():
			var attack_cost: float = CombatConstants.stamina_attack_cost_from_intensity(0.85)
			for _burst in 60:
				if _count_needle(_OperationalLog.get_captured_lines(), "crossed 25") >= 1:
					break
				_Exhaustion.apply_exertion_from_stamina_spend(mgr, fighter, attack_cost)
				mgr._process(TICK_DT)
	var lines: PackedStringArray = _OperationalLog.get_captured_lines()
	var gauge_exh_ok: bool = _ii4d_gauge_exh_suffix_ok(mgr)
	var ex_stats: Dictionary = _TrackSpecs.exhaustion_band_stats(lines)
	var ex_summary: String = _TrackSpecs.exhaustion_stats_summary_line(ex_stats)
	var ex_dup: bool = false
	for i in range(lines.size() - 1, maxi(-1, lines.size() - 24), -1):
		if "exhaustion_stats " in str(lines[i]):
			ex_dup = true
			break
	if not ex_dup:
		_OperationalLog.play_combat(ex_summary)
	var pr: Dictionary = _evaluate(
		preset_id, lines, _TrackSpecs.headless_checks_for_preset(preset_id)
	)
	var plaus_fail: PackedStringArray = _TrackSpecs.ii4d_plausibility_failures(ex_stats, gauge_exh_ok)
	pr["exhaustion_stats"] = ex_stats
	pr["ii4d_plausibility_ok"] = plaus_fail.is_empty()
	pr["ii4d_plausibility_failures"] = plaus_fail
	pr["ii4d_gauge_exh_ok"] = gauge_exh_ok
	if not plaus_fail.is_empty():
		pr["ok"] = false
		var prev: String = str(pr.get("summary", ""))
		pr["summary"] = "ii4d_plausibility: %s" % ", ".join(plaus_fail)
		if not prev.is_empty() and prev != "ok":
			pr["summary"] = "%s | %s" % [prev, pr["summary"]]
	var checks: Dictionary = pr.get("checks", {}) as Dictionary
	checks["ii4d_plausibility"] = {
		"pass": plaus_fail.is_empty(),
		"count": 1 if plaus_fail.is_empty() else 0,
		"min": 1,
	}
	pr["checks"] = checks
	pr["notes"] = "headless II-4d band + Exh gauge (F5 3–5 min feel optional)"
	_free_manager(mgr)
	return pr


static func _ii4d_gauge_exh_suffix_ok(mgr: Node) -> bool:
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		return true
	for c in mgr.combatants:
		if not _EntityAccess.alive_bool(c):
			continue
		c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.28
		var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
		return "Exh" in label
	return false


static func _run_ii6_ambient(preset_id: String) -> Dictionary:
	_F5SoakTrace.set_fight_profile(preset_id)
	_OperationalLog.play_combat(
		"soak_fight_enter tile=cyan preset=%s (grep soak=%s soak_setup ii6)"
		% [preset_id, preset_id]
	)
	var mgr: Node = _start_manager(preset_id, 1, 1, _player_1x1(), _player_1x1())
	var companion: Dictionary = _player_at_rank_file(mgr, 0, 0)
	if not companion.is_empty():
		var ent: CoreEntity = _EntityAccess.scene_node(companion) as CoreEntity
		if ent != null:
			ent.name = "Companion"
			ent.take_damage_split(22.0, 22.0, "chest")
			ent.blood_volume = 58.0
			ent._pain_shock_until_time = -1.0
			ent._ambient_pain_shock_accum = 0.0
	_OperationalLog.play_combat(
		"soak_setup ii6 companion chest wounded bv=58 (grep ambient_pain_shock on Companion)"
	)
	# II-6: ambient tick only — do not **`mgr._process`** (AI combat would end the fight / kill the probe).
	var ambient_ok: bool = false
	for _t in 120:
		if companion.is_empty():
			break
		var ent6: CoreEntity = _EntityAccess.scene_node(companion) as CoreEntity
		if ent6 != null and EntityPainConsciousness.try_ambient_pain_shock_tick(ent6, 1.0):
			ambient_ok = true
			break
	if ambient_ok:
		_F5SoakTrace.log_fight_end_summary("player", false)
	else:
		_OperationalLog.play_combat(
			"soak_setup ii6 WARN ambient_pain_shock not fired in 120s — check PAIN_SHOCK_AMBIENT interval / feature flag"
		)
		_simulate_fight(mgr, 8.0, preset_id)
	_free_manager(mgr)
	return _evaluate(preset_id, _OperationalLog.get_captured_lines(), _TrackSpecs.headless_checks_for_preset(preset_id))


static func _evaluate(_preset_id: String, lines: PackedStringArray, checks: Array) -> Dictionary:
	var check_out: Dictionary = {}
	var required_fail: PackedStringArray = PackedStringArray()
	var optional_miss: PackedStringArray = PackedStringArray()
	for spec in checks:
		var id: String = str(spec.get("id", ""))
		var needle: String = str(spec.get("needle", ""))
		var min_c: int = int(spec.get("min", 1))
		var max_c: int = int(spec.get("max", -1))
		var count: int = 0
		if spec.has("regex"):
			count = _count_regex(lines, str(spec.get("regex", "")))
		else:
			count = _count_needle(lines, needle)
			for alt in spec.get("alt_needles", []) as Array:
				count = maxi(count, _count_needle(lines, str(alt)))
		var ok_check: bool = true
		if max_c >= 0:
			ok_check = count <= max_c
		else:
			ok_check = count >= min_c
		var optional: bool = bool(spec.get("optional", false))
		check_out[id] = {"pass": ok_check, "count": count, "min": min_c, "optional": optional}
		if not ok_check:
			if optional:
				optional_miss.append("%s (got %d need>=%d)" % [id, count, min_c])
			else:
				required_fail.append("%s (got %d need>=%d)" % [id, count, min_c])
	var plaus_fail: PackedStringArray = _SoakSanity.plausibility_failures_for_preset(_preset_id, lines)
	for msg in plaus_fail:
		required_fail.append("plausibility: %s" % msg)
	var ok: bool = required_fail.is_empty()
	var summary: String = "ok" if ok else ", ".join(required_fail)
	if not optional_miss.is_empty():
		summary += " | optional: " + ", ".join(optional_miss)
	return {
		"ok": ok,
		"summary": summary,
		"checks": check_out,
		"plausibility_ok": plaus_fail.is_empty(),
		"notes": "headless sim — II-5c gauge not verified",
	}


static func _count_needle(lines: PackedStringArray, needle: String) -> int:
	if needle.is_empty():
		return 0
	var n: int = 0
	for line in lines:
		if _is_soak_grep_hint_line(line):
			continue
		if needle in line:
			n += 1
	return n


static func _count_regex(lines: PackedStringArray, pattern: String) -> int:
	if pattern.is_empty():
		return 0
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return 0
	var n: int = 0
	for line in lines:
		if _is_soak_grep_hint_line(line):
			continue
		if re.search(line) != null:
			n += 1
	return n


## Session banners mention **`grep SCRIPT_ERROR`** — not real errors (see **`CombatF5SoakLogValidator`**).
static func _is_soak_grep_hint_line(line: String) -> bool:
	var s: String = line.strip_edges()
	if s.begins_with("soak_guide ") or s.begins_with("soak_session_plan "):
		return true
	if s.begins_with("soak_validate_hint ") or s.begins_with("soak_coverage "):
		return true
	if "grep SCRIPT" in s or "grep FP_ERROR" in s or "grep soak_fight_end" in s:
		return true
	if s.begins_with("FP_SESSION_BEGIN:") or s.begins_with("FP_SESSION_END:"):
		return true
	return false


static func _start_manager(
	preset_id: String,
	player_n: int,
	enemy_n: int,
	player_form: Dictionary,
	enemy_form: Dictionary,
	log_engagement_banner: bool = true
) -> Node:
	_F5SoakTrace.prepare_fight_end_log()
	var mgr: Node = _MgrScript.new()
	mgr.encounter = (
		{SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: "7v7"}
		if preset_id == "7v7"
		else _encounter_dict_for_preset(preset_id)
	)
	_register_players(mgr, player_n, preset_id == "7v7")
	for _j in enemy_n:
		var w_id: String = "SWORD"
		if preset_id == _SoakPresets.PRESET_II2B_SWORD_DUEL or preset_id == _SoakPresets.PRESET_II4D_EXHAUSTION:
			w_id = "SWORD"
		mgr.register(_new_entity(w_id), "enemy")
	var p_count: int = player_n
	var e_count: int = enemy_n
	_OperationalLog.play_combat_start(p_count, e_count, player_form, enemy_form, mgr.encounter)
	mgr.start(player_form, enemy_form)
	if log_engagement_banner:
		_log_diagram_banner_once(mgr)
	return mgr


static func _register_players(mgr: Node, player_n: int, use_7v7_names: bool) -> void:
	for i in player_n:
		var pe: CoreEntity = _new_entity("SWORD")
		if use_7v7_names:
			if i == 0:
				pe.name = "Character"
			elif i == 1:
				pe.name = "Companion"
			else:
				pe.name = "Companion%d" % i
		elif i == 0:
			pe.name = "Leader"
		elif i == 1:
			pe.name = "Companion"
		else:
			pe.name = "Companion%d" % i
		mgr.register(pe, "player")


static func _encounter_dict_for_preset(preset_id: String) -> Dictionary:
	var enc: Dictionary = {
		SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: preset_id,
	}
	if preset_id == _SoakPresets.PRESET_II2B_SWORD_DUEL or preset_id == _SoakPresets.PRESET_II4D_EXHAUSTION:
		enc[SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID] = "SWORD"
	if preset_id == _SoakPresets.PRESET_II_ENVELOP:
		enc[SoakEncounterPresets.ENCOUNTER_KEY_FORCE_WEAPON_ID] = "SWORD"
		enc[CombatConstants.ENCOUNTER_KEY_PLAYER_FRONT_COUNT] = 7
		enc[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER] = CombatConstants.DOCTRINE_PINCH_CENTER
		enc[CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY] = CombatConstants.DOCTRINE_PINCH_CENTER
	return enc


static func _formation_engagement_banner_line(mgr: Node) -> String:
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	if form.is_empty():
		return ""
	var mode_disp: String = _EngagementMode.mode_display_name(_EngagementMode.engagement_mode(mgr))
	var posture: String = str(form.get("engagement_posture", "—"))
	var coh: float = float(form.get("line_cohesion", 0.0))
	return "%s · %s · cohesion %d%%" % [
		mode_disp,
		posture.capitalize(),
		int(roundf(coh * 100.0)),
	]


static func _log_diagram_banner_once(mgr: Node) -> void:
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	if form.is_empty():
		return
	var mode_disp: String = _EngagementMode.mode_display_name(_EngagementMode.engagement_mode(mgr))
	var posture: String = str(form.get("engagement_posture", "—"))
	var coh: float = float(form.get("line_cohesion", 0.0))
	var line: String = "%s · %s · cohesion %d%%" % [
		mode_disp,
		posture.capitalize(),
		int(roundf(coh * 100.0)),
	]
	_F5SoakTrace.log_diagram_banner_player(line)


static func _infer_soak_fight_winner(mgr: Node) -> String:
	var players_alive: int = 0
	var enemies_alive: int = 0
	for c in mgr.combatants:
		if c is not Dictionary or not _EntityAccess.alive_bool(c):
			continue
		if bool(c.get("combat_absent", false)):
			continue
		if _EntityAccess.is_player_side(c):
			players_alive += 1
		else:
			enemies_alive += 1
	if players_alive > 0 and enemies_alive == 0:
		return "player"
	if enemies_alive > 0 and players_alive == 0:
		return "enemy"
	if bool(mgr.medical_phase):
		return "player"
	return "enemy" if enemies_alive > players_alive else "player"


static func _simulate_fight(mgr: Node, max_sec: float, preset_id: String) -> void:
	if not preset_id.is_empty():
		_F5SoakTrace.set_fight_profile(preset_id)
	else:
		_F5SoakTrace.set_fight_profile("7v7")
	_F5SoakTrace.reset_fight_trace_buffer()
	var restore_hit_summary: bool = false
	if CombatConstants.is_headless_harness_quiet() and _OperationalLog.is_play_session_active():
		CombatConstants.set_combat_hit_summary_override(true)
		restore_hit_summary = true
	var elapsed: float = 0.0
	while elapsed < max_sec and mgr.is_processing():
		_auto_resolve_ready_combatants(mgr, preset_id)
		mgr._process(TICK_DT)
		elapsed += TICK_DT
		if mgr.medical_phase:
			break
	_auto_resolve_ready_combatants(mgr, preset_id)
	_F5SoakTrace.log_fight_end_summary(_infer_soak_fight_winner(mgr), bool(mgr.medical_phase))
	if restore_hit_summary:
		CombatConstants.clear_combat_hit_summary_override()


static func _auto_resolve_ready_combatants(mgr: Node, preset_id: String) -> void:
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		if not _EntityAccess.alive_bool(c):
			continue
		if bool(c.get("combat_absent", false)):
			continue
		var st: String = _EntityAccess.state_str(c)
		if st != CombatConstants.STATE_WAITING and st != CombatConstants.STATE_COWERING:
			continue
		if _EntityAccess.gauge_float(c) < 99.0:
			continue
		var cid: int = _EntityAccess.id_int(c)
		var actions: Array = mgr.get_available_actions(cid)
		if _EntityAccess.is_player_side(c):
			_PlayerTurnHints.emit_turn_ready_hints(mgr, c, actions)
			_F5SoakTrace.log_turn_ready_player_ui(mgr, c, actions)
		if (
			preset_id == _SoakPresets.PRESET_II5_COWERING
			and st == CombatConstants.STATE_COWERING
			and _try_force_fall_back(mgr, cid, actions)
		):
			continue
		var log_side: String = "player" if _EntityAccess.is_player_side(c) else "enemy"
		var pick_actions: Array = actions
		if preset_id == _SoakPresets.PRESET_II2B_SWORD_DUEL:
			pick_actions = _strike_biased_actions(actions, cid)
		elif preset_id == _SoakPresets.PRESET_II_ENVELOP:
			pick_actions = _envelop_melee_biased_actions(actions, cid)
		_AIActionPicker.resolve_picked_turn_or_skip(mgr, cid, pick_actions, log_side)


static func _strike_biased_actions(actions: Array, combatant_id: int) -> Array:
	var non_strike: Dictionary = {
		CombatConstants.MOVE_ID_WAIT: true,
		CombatConstants.MOVE_ID_ATTEMPT_CLOSE: true,
		CombatConstants.MOVE_ID_SWAP_RANK: true,
		CombatConstants.MOVE_ID_DRAG_BACK: true,
		CombatConstants.MOVE_ID_FALL_BACK: true,
		CombatConstants.MOVE_ID_ROTATE_FILE: true,
		CombatConstants.MOVE_ID_FLEE: true,
		CombatConstants.MOVE_ID_FOCUS_HIGH: true,
		CombatConstants.MOVE_ID_FOCUS_LOW: true,
		CombatConstants.MOVE_ID_FOCUS_LEFT: true,
		CombatConstants.MOVE_ID_FOCUS_RIGHT: true,
	}
	var strikes: Array = []
	for a in actions:
		if a is not Dictionary:
			continue
		var mid: String = str(a.get("move_id", ""))
		if non_strike.has(mid):
			continue
		if int(a.get("target_id", combatant_id)) == combatant_id:
			continue
		strikes.append(a)
	return strikes if not strikes.is_empty() else actions


## III-4 **ii_envelop**: prefer damage actions over rotate/wait when listed (headless wing engagement smoke).
static func _envelop_melee_biased_actions(actions: Array, combatant_id: int) -> Array:
	var deprioritize: Dictionary = {
		CombatConstants.MOVE_ID_WAIT: true,
		CombatConstants.MOVE_ID_ROTATE_FILE: true,
	}
	var preferred: Array = []
	for a in actions:
		if a is not Dictionary:
			continue
		var mid: String = str(a.get("move_id", ""))
		if deprioritize.has(mid):
			continue
		if int(a.get("target_id", combatant_id)) == combatant_id:
			continue
		preferred.append(a)
	return preferred if not preferred.is_empty() else actions


## Live **`AttackResultApplier`** / **`CombatFlurryBind`** path when random duel omits bind lines (feeds headless **II-2b** plausibility).
static func _ensure_ii2b_bind_flurry_smoke(mgr: Node) -> void:
	var lines: PackedStringArray = _OperationalLog.get_captured_lines()
	var need_bind: bool = _count_needle(lines, "parry_bind") < 1
	var need_flurry: bool = _count_needle(lines, "flurry_bind") < 1
	if not need_bind and not need_flurry:
		return
	if mgr.combatants.size() < 2:
		return
	_OperationalLog.play_combat(
		"soak_setup ii2b bind/flurry smoke tail (live resolver; headless plausibility)"
	)
	var defender: Dictionary = mgr.combatants[0]
	var attacker: Dictionary = mgr.combatants[1]
	var p_id: int = _EntityAccess.id_int(defender)
	var e_id: int = _EntityAccess.id_int(attacker)
	attacker["pending_attack"] = {
		"attack_type": "thrust",
		"effective_attack_line": "high",
		"intensity": 0.8,
		"attack_angle_deg": 90.0,
	}
	defender["guard_line"] = "high"
	defender.gauge = 100.0
	attacker.state = CombatConstants.STATE_WIND_UP
	_AttackResultApplier.apply_result(
		mgr,
		e_id,
		{
			"action": "parry_deflect",
			"target_id": p_id,
			"recovery_duration": 0.45,
			"parry_clash_context": {"parry_control": 0.72, "kinematic_delivery": "thrust"},
		}
	)
	if need_flurry:
		defender.gauge = 100.0
		defender.state = CombatConstants.STATE_WAITING
		_AttackWindUpStarter.start(mgr, p_id, e_id, "thrust")


## Headless ii5: fall-back wind-up must finish before `soak_fight_end` (plausibility last-fight slice).
static func _ensure_ii5_cowering_fall_back_executed(mgr: Node, combatant_id: int) -> void:
	if _count_needle(_OperationalLog.get_captured_lines(), "cowering_fall_back executed") >= 1:
		return
	for _i in 80:
		mgr._process(TICK_DT)
		if _count_needle(_OperationalLog.get_captured_lines(), "cowering_fall_back executed") >= 1:
			return
	var c: Dictionary = _EntityAccess.manager_get_combatant(mgr, combatant_id)
	if c.is_empty():
		return
	var cd: Dictionary = c as Dictionary
	cd.state = CombatConstants.STATE_FALLING_BACK
	cd.state_timer = float(cd.get("state_duration", CombatConstants.BASE_FALL_BACK_S))
	mgr._handle_fall_back_solo_resolve({
		"type": CombatConstants.EVENT_FALL_BACK_SOLO_RESOLVE,
		"combatant_id": combatant_id,
	})


static func _drain_until_capture_needle(mgr: Node, needle: String, max_sec: float) -> void:
	var elapsed: float = 0.0
	while elapsed < max_sec:
		if _count_needle(_OperationalLog.get_captured_lines(), needle) >= 1:
			return
		mgr._process(TICK_DT)
		elapsed += TICK_DT


static func _try_force_fall_back(mgr: Node, combatant_id: int, actions: Array) -> bool:
	for a in actions:
		if a is not Dictionary:
			continue
		if str(a.get("move_id", "")) != CombatConstants.MOVE_ID_FALL_BACK:
			continue
		if int(a.get("target_id", combatant_id)) != combatant_id:
			continue
		mgr.resolve_action(combatant_id, combatant_id, CombatConstants.MOVE_ID_FALL_BACK, {})
		return true
	return false


static func _soak_kill(mgr: Node, combatant_id: int) -> void:
	var c: Dictionary = _EntityAccess.manager_get_combatant(mgr, combatant_id)
	if c.is_empty():
		return
	c["hp"] = 0.0
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	if ent != null:
		ent.blood_volume = 0.0


static func _first_alive_player_front_rank(mgr: Node) -> Dictionary:
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		if not _EntityAccess.is_player_side(c):
			continue
		if not _EntityAccess.alive_bool(c):
			continue
		if _EntityAccess.rank_int(c) != 0:
			continue
		return c
	return {}


static func _player_at_rank_file(mgr: Node, rank: int, file: int) -> Dictionary:
	for c in mgr.combatants:
		if not _EntityAccess.is_player_side(c):
			continue
		if _EntityAccess.rank_int(c) == rank and _EntityAccess.file_int(c) == file:
			return c
	return {}


static func _formation_7v7() -> Dictionary:
	return {"files": 5, "ranks": 2, "density": FormationPreset.DENSITY_NORMAL}


static func _player_1x1() -> Dictionary:
	return {"files": 1, "ranks": 1, "density": FormationPreset.DENSITY_NORMAL}


static func _player_4_wide() -> Dictionary:
	return FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _enemy_4_wide() -> Dictionary:
	return FormationPreset.for_front_count(4, 4, FormationPreset.DENSITY_NORMAL)


static func _new_entity(weapon_id: String) -> CoreEntity:
	return CombatRegressionHarness._new_entity(weapon_id)


static func _destroy_limb(entity: CoreEntity, part: String) -> void:
	CombatRegressionHarness._harness_destroy_limb(entity, part)


static func _free_manager(mgr: Node) -> void:
	if mgr == null:
		return
	if mgr.is_inside_tree():
		mgr.get_parent().remove_child(mgr)
	mgr.queue_free()
