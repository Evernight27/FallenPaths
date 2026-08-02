class_name D001PresetRunnerUITests
extends RefCounted
## Headless **D-001** preset UI tests: gauge labels, engagement mode strings, formation hints.


static func _run_ii7_medical_phase_smoke() -> Dictionary:
	OperationalLog.play_combat("soak_setup ii7 medical phase smoke (grep medical | apply_direct_pressure | pack_wound)")
	var mgr: Node = CombatManager.new()
	var enemy_ent: CoreEntity = D001RunnerHelpers._new_entity("SWORD")
	mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
	mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
	mgr.register(enemy_ent, "enemy")
	mgr.start(D001RunnerHelpers._player_1x1(), D001RunnerHelpers._player_1x1())
	var healer_id: int = CombatantEntityAccess.id_int(mgr.combatants[0])
	var ally: Dictionary = mgr.combatants[1]
	var ally_id: int = CombatantEntityAccess.id_int(ally)
	var ally_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, ally)
	if ally_ent != null:
		D001PresetRunnerTests._wound_chest_for_packing(ally_ent)
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
			if str(a.get("move_id", "")) == CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE:
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
				healer_id, ally_id, CombatConstants.MOVE_ID_APPLY_DIRECT_PRESSURE, {"target_part": "chest"}
			)
			check_out["pressure_resolve"] = {
				"pass": committed,
				"count": 1 if committed else 0,
				"min": 1,
			}
			if not committed:
				fail.append("pressure_resolve failed")
			else:
				D001PresetRunnerTests._wait_combatant_waiting(mgr, mgr.combatants[0], 8.0)
				var healer_ent: Node = CombatantEntityAccess.get_entity_from_manager(mgr, mgr.combatants[0])
				D001PresetRunnerTests._ensure_ally_part_has_direct_pressure(
					mgr, ally, mgr.combatants[0], ally_ent, healer_ent, "chest"
				)
				mgr.combatants[0].state = CombatConstants.STATE_WAITING
				mgr.combatants[0]["gauge"] = 100.0
				mgr.combatants[0].erase("pending_medical")
				var acts2: Array = mgr.get_available_actions(healer_id)
				CombatPlayerTurnHints.emit_turn_ready_hints(mgr, mgr.combatants[0], acts2)
				var found_pack: bool = D001PresetRunnerTests._medical_pack_wound_listed_for_ally(
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
					var who_pack: String = CombatantEntityAccess.get_display_name(mgr.combatants[0], healer_id)
					if who_pack.is_empty() and healer_ent != null:
						who_pack = str(healer_ent.name)
					CombatF5SoakTrace.note_medical_pack_listed(who_pack, "chest")
					CombatF5SoakTrace.note_medical_action_pick(
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
						while elapsed_pack < CombatConstants.PACK_WOUND_TIMEOUT_S:
							if CombatantEntityAccess.state_str(mgr.combatants[0]) == CombatConstants.STATE_WAITING:
								break
							mgr._process(D001PresetRunnerTests.TICK_DT)
							elapsed_pack += D001PresetRunnerTests.TICK_DT
	var lines: PackedStringArray = OperationalLog.get_captured_lines()
	var med_log_n: int = D001Ii5Ii6RunnerTests._count_needle(lines, "medical ")
	check_out["medical_log"] = {"pass": med_log_n >= 1, "count": med_log_n, "min": 1, "optional": true}
	var pack_listed_n: int = D001Ii5Ii6RunnerTests._count_needle(lines, "medical_pack_wound listed")
	var pack_pick_n: int = D001Ii5Ii6RunnerTests._count_needle(lines, "medical_pack_wound pick")
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
	D001RunnerHelpers._free_manager(mgr)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "pressure + pack_wound F5 greps for validator medical_pack_* tracks",
	}


static func _run_formation_move_f5_smoke() -> Dictionary:
	OperationalLog.play_combat("soak_setup formation_move_f5 smoke (grep rotate_file@ or swap_rank@)")
	var mgr: Node = CombatManager.new()
	for _i in 4:
		mgr.register(D001RunnerHelpers._new_entity("SWORD"), "player")
	for _j in 4:
		mgr.register(D001RunnerHelpers._new_entity("SWORD"), "enemy")
	mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
	CombatEngagementMode.clear_resolved_mode_cache(mgr)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	var by_file: Dictionary = {}
	for c in mgr.combatants:
		if not CombatantEntityAccess.is_player_side(c):
			continue
		if CombatantEntityAccess.rank_int(c) != 0:
			continue
		by_file[CombatantEntityAccess.file_int(c)] = c
	var p0: Dictionary = by_file.get(0, {})
	var p1: Dictionary = by_file.get(1, {})
	var fail: PackedStringArray = PackedStringArray()
	var check_out: Dictionary = {}
	if p0.is_empty() or p1.is_empty():
		fail.append("need rank-0 allies at files 0 and 1")
		D001RunnerHelpers._free_manager(mgr)
		return {"ok": false, "summary": ", ".join(fail), "checks": check_out}
	p0["gauge"] = 100.0
	p1["gauge"] = 100.0
	p0.state = CombatConstants.STATE_WAITING
	p1.state = CombatConstants.STATE_WAITING
	var p0_id: int = CombatantEntityAccess.id_int(p0)
	var p1_id: int = CombatantEntityAccess.id_int(p1)
	var acts: Array = mgr.get_available_actions(p0_id)
	var rotate_act: Dictionary = CombatListedActions.first_action_move_vs_target(
		acts, CombatConstants.MOVE_ID_ROTATE_FILE, p1_id
	)
	var rotate_target: int = int(rotate_act.get("target_id", -1))
	if rotate_target < 0:
		fail.append("rotate_file not listed on 2-file line")
	else:
		var committed: bool = mgr.resolve_action(p0_id, rotate_target, CombatConstants.MOVE_ID_ROTATE_FILE, {})
		check_out["rotate_resolve"] = {
			"pass": committed,
			"count": 1 if committed else 0,
			"min": 1,
		}
		if not committed:
			fail.append("rotate_file resolve failed")
	var lines: PackedStringArray = OperationalLog.get_captured_lines()
	var rot_n: int = D001Ii5Ii6RunnerTests._count_needle(lines, "rotate_file")
	check_out["f5_rotate_file"] = {
		"pass": rot_n >= 1,
		"count": rot_n,
		"min": 1,
	}
	if rot_n < 1:
		fail.append("FP_COMBAT missing rotate_file grep line")
	D001RunnerHelpers._free_manager(mgr)
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "feeds f5_log_validator formation_moves optional track",
	}


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
		var count: int = D001Ii5Ii6RunnerTests._count_needle(lines, needle)
		var ok_needle: bool = count == 0
		check_out[id] = {"pass": ok_needle, "count": count, "min": 0, "max": 0}
		if not ok_needle:
			fail.append("%s (count=%d)" % [id, count])
	var ok: bool = fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(fail),
		"checks": check_out,
		"notes": "stale crash/intrusion log vocabulary not present in preset sims",
	}


static func _run_ii1e_engagement_label_checks() -> Dictionary:
	var checks: Dictionary = {
		"formation_line":
		{
			"pass":
			CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_FORMATION) == "Formation line",
			"count": 1,
			"min": 1,
		},
		"skirmish":
		{
			"pass": CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_SKIRMISH) == "Skirmish",
			"count": 1,
			"min": 1,
		},
		"duel":
		{
			"pass": CombatEngagementMode.mode_display_name(CombatConstants.ENGAGEMENT_MODE_DUEL) == "Duel",
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
	OperationalLog.play_combat("soak_setup ii5a 4x4 formation turn-ready hints (grep ui_hint Formation)")
	var mgr: Node = D001Ii5Ii6RunnerTests._start_manager(
		"ii5a", 4, 4, D001RunnerHelpers._player_4_wide(), D001RunnerHelpers._enemy_4_wide()
	)
	mgr.set_meta("_engagement_mode_cached", CombatConstants.ENGAGEMENT_MODE_FORMATION)
	var probe: Dictionary = D001Ii5Ii6RunnerTests._probe_formation_turn_hints(mgr)
	var check_out: Dictionary = {}
	var stamp: String = str(probe.get("formation_stamp", ""))
	var ui_n: int = int(probe.get("ui_hint_formation", 0))
	D001RunnerHelpers._free_manager(mgr)
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
		"notes": "II-5a log paths  -  F5 tooltip match still required",
	}


static func _run_ii5c_gauge_label_checks() -> Dictionary:
	var checks: Array = [
		{
			"id": "stm_ready",
			"needle": "Stm 67% . Ready",
			"label":
			(
				BattleUIUpdater
				.gauge_label_text_for_combatant(
					{
						"alive": true,
						"state": CombatConstants.STATE_WAITING,
						"gauge": 100.0,
						"stamina": 67.0,
						"guard_line": "high",
					}
				)
			),
			"min": 1,
		},
		{
			"id": "exh_grd_stack",
			"needle": "Exh 55%",
			"label":
			(
				BattleUIUpdater
				.gauge_label_text_for_combatant(
					{
						"alive": true,
						"state": CombatConstants.STATE_WAITING,
						"gauge": 50.0,
						"stamina": 60.0,
						"guard_line": "high_right",
						CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
					}
				)
			),
			"min": 1,
		},
		{
			"id": "grd_hir",
			"needle": "Grd HiR",
			"label":
			(
				BattleUIUpdater
				.gauge_label_text_for_combatant(
					{
						"alive": true,
						"state": CombatConstants.STATE_WAITING,
						"gauge": 50.0,
						"stamina": 60.0,
						"guard_line": "high_right",
						CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.55,
					}
				)
			),
			"min": 1,
		},
	]
	if not CombatConstants.is_feature_fight_exhaustion_enabled():
		checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "exh_grd_stack")
	if not CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		checks = checks.filter(func(spec: Dictionary) -> bool: return spec.id != "grd_hir")
	var form_row: Dictionary = {
		"alive": true,
		"state": CombatConstants.STATE_WAITING,
		"gauge": 100.0,
		"stamina": 67.0,
		"guard_line": "high",
		CombatConstants.COMBATANT_KEY_WEAPON_FORM: CombatWeaponForm.FORM_OX,
	}
	var form_label: String = BattleUIUpdater.gauge_label_text_for_combatant(form_row)
	(
		checks
		.append(
			{
				"id": "form_ox_gauge",
				"needle": " . Form Ox",
				"label": form_label,
				"min": 1,
			}
		)
	)
	(
		checks
		.append(
			{
				"id": "suffix_order_grd_form",
				"needle": "",
				"label": form_label,
				"min": 1,
				"ordered_substrings": ["Grd", " . Form Ox"],
			}
		)
	)
	if CombatConstants.is_feature_hema_eight_guard_lines_enabled():
		var wrath_row: Dictionary = {
			"alive": true,
			"state": CombatConstants.STATE_WAITING,
			"gauge": 100.0,
			"stamina": 67.0,
			"guard_line": "high_left",
			CombatConstants.COMBATANT_KEY_WEAPON_FORM: CombatWeaponForm.FORM_WRATH,
		}
		var wrath_label: String = BattleUIUpdater.gauge_label_text_for_combatant(wrath_row)
		(
			checks
			.append(
				{
					"id": "form_wrath_grd_hil",
					"needle": "Grd HiL",
					"label": wrath_label,
					"min": 1,
				}
			)
		)
		(
			checks
			.append(
				{
					"id": "form_wrath_gauge",
					"needle": " . Form Wrath",
					"label": wrath_label,
					"min": 1,
				}
			)
		)
		(
			checks
			.append(
				{
					"id": "form_wrath_suffix_order",
					"needle": "",
					"label": wrath_label,
					"min": 1,
					"ordered_substrings": ["Grd HiL", " . Form Wrath"],
				}
			)
		)
		var wrath_cell: String = FormationDiagramBuilder._cell_label_with_footwork("P0", [wrath_row])
		(
			checks
			.append(
				{
					"id": "form_wrath_diagram",
					"needle": "",
					"label": wrath_cell,
					"min": 1,
					"ordered_substrings": ["[HiL]", "[Wrath]"],
				}
			)
		)
		var step_grd_form_row: Dictionary = form_row.duplicate()
		step_grd_form_row["state"] = CombatConstants.STATE_WIND_UP
		step_grd_form_row["state_timer"] = 0.0
		step_grd_form_row["state_duration"] = 1.0
		step_grd_form_row[CombatConstants.COMBATANT_KEY_POSITION_ANGLE_OFFSET_DEG] = 14.0
		step_grd_form_row["pending_attack"] = {"attack_line": "high_right", "move_id": "oberhau"}
		var step_label: String = BattleUIUpdater.gauge_label_text_for_combatant(step_grd_form_row)
		(
			checks
			.append(
				{
					"id": "suffix_order_step_atk_form",
					"needle": "",
					"label": step_label,
					"min": 1,
					"ordered_substrings": ["Step", "Atk", " . Form Ox"],
				}
			)
		)
	var full_row: String = (
		BattleUIUpdater
		.gauge_label_text_for_combatant(
			{
				"alive": true,
				"state": CombatConstants.STATE_WAITING,
				"gauge": 100.0,
				"stamina": 72.0,
				"guard_line": "high",
				CombatConstants.COMBATANT_KEY_EXHAUSTION: 0.12,
			}
		)
	)
	var row_subs: Array = ["Stm", " . Ready", "Grd"]
	if CombatConstants.is_feature_fight_exhaustion_enabled():
		row_subs.append("Exh")
	(
		checks
		.append(
			{
				"id": "stm_ready_exh_grd_row",
				"needle": "",
				"label": full_row,
				"min": 1,
				"substrings": row_subs,
			}
		)
	)
	var check_out: Dictionary = {}
	var required_fail: PackedStringArray = PackedStringArray()
	for spec in checks:
		var id: String = str(spec.get("id", ""))
		var text: String = str(spec.get("label", ""))
		var needle: String = str(spec.get("needle", ""))
		var ok_needle: bool = true
		if spec.has("ordered_substrings"):
			var ordered: PackedStringArray = PackedStringArray()
			for sub in spec.get("ordered_substrings", []) as Array:
				ordered.append(str(sub))
			ok_needle = D001PresetRunnerTests._label_tokens_in_order(text, ordered)
		elif spec.has("substrings"):
			for sub in spec.get("substrings", []) as Array:
				if str(sub) not in text:
					ok_needle = false
					break
		else:
			ok_needle = needle.is_empty() or needle in text
		check_out[id] = {"pass": ok_needle, "count": 1 if ok_needle else 0, "min": 1, "label": text}
		if not ok_needle:
			var need_s: String = needle
			if spec.has("ordered_substrings"):
				need_s = "order %s" % str(spec.get("ordered_substrings", []))
			required_fail.append("%s (label='%s' need '%s')" % [id, text, need_s])
	var ok: bool = required_fail.is_empty()
	return {
		"ok": ok,
		"summary": "ok" if ok else ", ".join(required_fail),
		"checks": check_out,
		"notes": "BattleUIUpdater row suffixes + WF form suffix (headless II-5c sign-off)",
	}


static func _label_tokens_in_order(label: String, tokens: PackedStringArray) -> bool:
	var pos: int = 0
	for tok in tokens:
		var needle: String = str(tok)
		if needle.is_empty():
			continue
		var idx: int = label.find(needle, pos)
		if idx < 0:
			return false
		pos = idx + needle.length()
	return true
