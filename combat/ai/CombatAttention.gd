class_name CombatAttention
extends RefCounted

## Tier 4.3: salience probes, attention load, combat focus (**`focus_part`**, **`focus_intensity`**), and per-attacker
## yomi memory.
## Footing: appends focus **listing** only  -  L3 **`guard_line`** write on focus resolve is **`CombatResolveAction`**.
## LIVE_PATHS **`#wf-pick-vs-strike`** . **`#wf-guard-writers`**.
## **Read order:** enable/clear -> salience refresh -> focus line listing append -> yomi read/write helpers.


const Yomi = preload("res://combat/yomi/YomiConstants.gd")


static func _counter_tempo() -> GDScript:
	return preload(CombatConstants.PATH_COUNTER_TEMPO)


static func enabled() -> bool:
	return CombatConstants.is_feature_combat_attention_enabled()


static func clear_focus_and_yomi(c: Dictionary) -> void:
	if c == null:
		return
	c.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	c.erase(CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY)
	c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_LOAD)
	c.erase(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER)
	c.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
	c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	c.erase(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER)
	c.erase(CombatConstants.COMBATANT_KEY_DECEPTION_STATE)
	c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)


static func get_focus_part(c: Dictionary) -> String:
	if c == null:
		return "head"
	var fp: String = c.get(CombatConstants.COMBATANT_KEY_FOCUS_PART, "").strip_edges()
	if not fp.is_empty():
		return fp
	return str(c.get(DataKeys.DEFENDER_GUARD_ZONE, "head"))


static func get_focus_intensity(c: Dictionary) -> float:
	if c == null:
		return CombatConstants.FOCUS_INTENSITY_DEFAULT
	return clampf(
		float(c.get(CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY, CombatConstants.FOCUS_INTENSITY_DEFAULT)), 0.0, 1.0
	)


static func set_focus(c: Dictionary, part: String, intensity: float = -1.0) -> void:
	if c == null:
		return
	var p: String = part.strip_edges()
	if p.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_FOCUS_PART)
	else:
		c[CombatConstants.COMBATANT_KEY_FOCUS_PART] = p
	if intensity >= 0.0:
		c[CombatConstants.COMBATANT_KEY_FOCUS_INTENSITY] = clampf(intensity, 0.0, 1.0)


## Wind-up telegraph: defender commits focus to the bait line at high intensity.
static func set_focus_from_incoming_telegraph(defender: Dictionary, telegraph_part: String) -> void:
	if not enabled() or defender == null:
		return
	var p: String = telegraph_part.strip_edges()
	if p.is_empty():
		return
	set_focus(defender, p, CombatConstants.FOCUS_INTENSITY_DEFAULT)


static func get_attention_load(c: Dictionary) -> float:
	if c == null:
		return 0.0
	return clampf(c.get(CombatConstants.COMBATANT_KEY_ATTENTION_LOAD, 0.0), 0.0, 1.0)


static func focus_effective(c: Dictionary) -> float:
	var fi: float = get_focus_intensity(c)
	if not enabled():
		return fi
	var attention_load: float = get_attention_load(c)
	return clampf(fi * (1.0 - CombatConstants.ATTENTION_LOAD_FOCUS_PENALTY * attention_load), 0.0, 1.0)


static func refresh_salience(manager: Node, combatant_id: int) -> void:
	if not enabled() or manager == null or combatant_id < 0:
		return
	var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
	if c.is_empty():
		return
	var attention_load: float = 0.0
	if is_being_wind_up_targeted(manager, combatant_id):
		attention_load += CombatConstants.ATTENTION_LOAD_TELEGRAPH_WEIGHT
	if ally_in_immediate_peril(manager, combatant_id):
		attention_load += CombatConstants.ATTENTION_LOAD_PERIL_WEIGHT
	if has_actionable_counter_tempo(manager, c):
		attention_load += CombatConstants.ATTENTION_LOAD_COUNTER_WEIGHT
	c[CombatConstants.COMBATANT_KEY_ATTENTION_LOAD] = clampf(attention_load, 0.0, 1.0)


## Row label fragment: telegraphed line, focus part + effective %, optional load %.
static func format_attention_ui_hint(c: Dictionary) -> String:
	if not enabled() or c.is_empty():
		return ""
	var tele: String = c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "").strip_edges()
	var attention_load: float = get_attention_load(c)
	var stack_layer: String = c.get(CombatConstants.COMBATANT_KEY_MENTAL_STACK_LAYER, "").strip_edges()
	if tele.is_empty() and attention_load < 0.05 and stack_layer.is_empty():
		return ""
	var chunks: PackedStringArray = []
	if not tele.is_empty():
		chunks.append("Tel %s" % tele)
	var fp: String = get_focus_part(c)
	var fe_pct: int = int(roundf(focus_effective(c) * 100.0))
	chunks.append("Focus %s %d%%" % [fp, fe_pct])
	if attention_load >= 0.08:
		chunks.append("Load %d%%" % int(roundf(attention_load * 100.0)))
	if not stack_layer.is_empty():
		chunks.append("Stack %s" % stack_layer)
	return " . ".join(chunks)


## UI snapshot: stamped row hint when present, else derive from live telegraph/focus/load (same frame as **`build`**).
static func snapshot_ui_hint(c: Dictionary) -> String:
	if not enabled() or c.is_empty():
		return ""
	var stamped: String = c.get(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT, "").strip_edges()
	if not stamped.is_empty():
		return stamped
	return format_attention_ui_hint(c)


## Live UI: refresh salience probes, format hint (does not stamp **`COMBATANT_KEY_ATTENTION_UI_HINT`**).
static func live_ui_hint(manager: Node, c: Dictionary) -> String:
	if not enabled() or manager == null or c.is_empty():
		return ""
	var cid: int = CombatantEntityAccess.id_int(c)
	if cid < 0:
		return ""
	refresh_salience(manager, cid)
	return format_attention_ui_hint(c)


## Waiting-tick refresh: recompute load + stamp **`COMBATANT_KEY_ATTENTION_UI_HINT`** for **`BattleUIUpdater`**.
static func refresh_for_waiting_tick(manager: Node, c: Dictionary) -> void:
	if c.is_empty() or manager == null:
		return
	var cid: int = CombatantEntityAccess.id_int(c)
	if cid < 0:
		return
	var tick_idx: int = 0
	if manager != null:
		tick_idx = manager.get_combat_tick_index()
	refresh_salience(manager, cid)
	_apply_decay_to_all_entries(c, tick_idx)
	apply_yomi_focus_drift(manager, c)
	apply_guard_priority_drift(manager, c)
	CombatWeaponForm.refresh_inferred_forms_for_observer(manager, c)
	_update_attention_priority(manager, c)
	var hint: String = format_attention_ui_hint(c)
	if hint.is_empty():
		c.erase(CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT)
	else:
		c[CombatConstants.COMBATANT_KEY_ATTENTION_UI_HINT] = hint


static func is_being_wind_up_targeted(manager: Node, defender_id: int) -> bool:
	if manager == null or defender_id < 0:
		return false
	var def: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
	if def.is_empty():
		return false
	if not def.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "").is_empty():
		return true
	return _counter_tempo().call("incoming_attacker_id", manager, defender_id) >= 0


static func has_actionable_counter_tempo(manager: Node, c: Dictionary) -> bool:
	return _counter_tempo().call("can_act", manager, c)


static func ally_in_immediate_peril(manager: Node, combatant_id: int) -> bool:
	if manager == null or combatant_id < 0:
		return false
	var self_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
	if self_c.is_empty():
		return false
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var o: Dictionary = other
		if CombatantEntityAccess.id_int(o) == combatant_id:
			continue
		if not CombatantEntityAccess.is_living_same_side(self_c, o):
			continue
		if not CombatantEntityAccess.is_alive_in_combat(o):
			continue
		if CombatantEntityAccess.is_in_immediate_peril(manager, o):
			return true
	return false


## Feint-only line commitment: wrong-line focus on telegraph hurts read-through; focus on real line helps.
static func focus_line_mult_for_feint(defender: Dictionary, pa: Dictionary) -> float:
	if not enabled() or defender == null or pa.is_empty():
		return 1.0
	var fp: String = pa.get(DataKeys.ACTION_FEINT_PART, "").strip_edges()
	if fp.is_empty():
		return 1.0
	var tele: String = defender.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, fp).strip_edges()
	var real: String = pa.get(DataKeys.ACTION_TARGET_PART, "").strip_edges()
	var focus: String = get_focus_part(defender)
	if not tele.is_empty() and focus == tele and not real.is_empty() and real != tele:
		return CombatConstants.FOCUS_WRONG_LINE_READTHROUGH_MULT
	if not real.is_empty() and focus == real:
		return CombatConstants.FOCUS_CORRECT_LINE_READTHROUGH_MULT
	return 1.0


static func _yomi_root(defender: Dictionary) -> Dictionary:
	var raw: Variant = defender.get(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER, null)
	if raw is Dictionary:
		return raw as Dictionary
	return {}


static func _empty_yomi_entry() -> Dictionary:
	return {
		"line_counts": {},
		"move_id_counts": {},
		"contact_type_counts": {},
		"parry_deflect": 0,
		"feint_resolved": 0,
		"weighted_line_counts": {},
		"weighted_move_id_counts": {},
		"recent_line_counts": {},
		"recent_move_id_counts": {},
		"last_tick": -1,
		"recent_window_age": 0,
		"priority_rank": -1,
		"attention_weight": 1.0,
	}


static func _yomi_entry(defender: Dictionary, attacker_id: int) -> Dictionary:
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Variant = root.get(key, null)
	if entry is Dictionary and not (entry as Dictionary).is_empty():
		return entry as Dictionary
	return _empty_yomi_entry()


static func yomi_entry_for_attacker(defender: Dictionary, attacker_id: int) -> Dictionary:
	if defender == null or attacker_id < 0:
		return {}
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is Dictionary:
		return (entry as Dictionary).duplicate(true)
	return {}


static func yomi_observation_total(entry: Dictionary) -> int:
	if entry.is_empty():
		return 0
	var line_total: int = 0
	for raw in (entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}) as Dictionary).values():
		line_total += int(raw)
	var move_total: int = 0
	for raw in (entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}) as Dictionary).values():
		move_total += int(raw)
	var structural_total: int = max(line_total, move_total)
	return structural_total + entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0)


static func yomi_weighted_total(entry: Dictionary, alpha: float = CombatConstants.YOMI_POWER_LAW_ALPHA) -> float:
	if entry.is_empty():
		return 0.0
	var total: float = 0.0
	for counts_dict in [
		entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}),
		entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}),
		entry.get(DataKeys.ATTENTION_ENTRY_CONTACT_TYPE_COUNTS, {}),
	]:
		if counts_dict is not Dictionary:
			continue
		var d: Dictionary = counts_dict as Dictionary
		for raw in d.values():
			var n: float = float(raw)
			if n > 0.0:
				total += pow(n, alpha)
	total += float(entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0))
	total += float(entry.get(DataKeys.ATTENTION_PARRY_DEFLECT, 0)) * alpha
	return total


static func get_observation_view(entry: Dictionary, view_type: String = "raw") -> Dictionary:
	if entry.is_empty():
		return {}
	match view_type:
		"weighted":
			var aw: float = _apply_attention_weight_to_mult(entry, entry.get(DataKeys.ATTENTION_ENTRY_ATTENTION_WEIGHT, 1.0))
			return {
				"line_counts": _scale_dict_by(entry.get(DataKeys.ATTENTION_ENTRY_WEIGHTED_LINE_COUNTS, {}), aw),
				"move_id_counts": _scale_dict_by(entry.get(DataKeys.ATTENTION_ENTRY_WEIGHTED_MOVE_ID_COUNTS, {}), aw),
				"contact_type_counts": _scale_dict_by(entry.get(DataKeys.ATTENTION_ENTRY_CONTACT_TYPE_COUNTS, {}), aw),
				"parry_deflect": entry.get(DataKeys.ATTENTION_PARRY_DEFLECT, 0) * aw,
				"feint_resolved": entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0) * aw,
			}
		"recent":
			return {
				"line_counts": entry.get(DataKeys.ATTENTION_ENTRY_RECENT_LINE_COUNTS, {}),
				"move_id_counts": entry.get(DataKeys.ATTENTION_ENTRY_RECENT_MOVE_ID_COUNTS, {}),
			}
		_:  # "raw" and default
			return {
				"line_counts": entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}),
				"move_id_counts": entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}),
				"contact_type_counts": entry.get(DataKeys.ATTENTION_ENTRY_CONTACT_TYPE_COUNTS, {}),
				"parry_deflect": entry.get(DataKeys.ATTENTION_PARRY_DEFLECT, 0),
				"feint_resolved": entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0),
			}


static func _apply_attention_weight_to_mult(_entry: Dictionary, base_weight: float) -> float:
	## The attention_weight stored on the entry is already set by _update_attention_priority
	## with rank-based degradation applied (budget_max=3 → ranks 4+ get ×0.5). This function
	## simply returns the stored weight unchanged; do not re-degrade here to avoid double-dip.
	return base_weight


static func _scale_dict_by(d: Dictionary, mult: float) -> Dictionary:
	var result: Dictionary = {}
	for k in d.keys():
		result[k] = float(d[k]) * mult
	return result


## Phase 0 / Phase 4: attention weight per attacker (0.25–1.0 based on engagement + priority rank).
static func get_attention_weight(defender: Dictionary, attacker_id: int) -> float:
	if defender == null or attacker_id < 0:
		return 0.25
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return 0.25
	return float(entry.get(DataKeys.ATTENTION_ENTRY_ATTENTION_WEIGHT, 1.0))


static func _update_attention_priority(manager: Node, defender: Dictionary) -> void:
	if defender == null or manager == null:
		return
	var root: Dictionary = _yomi_root(defender)
	if root.is_empty():
		return
	## Build list of (attacker_id, weighted_score) for ranking.
	var scored: Array = []
	for key in root.keys():
		var entry: Variant = root.get(key, null)
		if entry is not Dictionary:
			continue
		var etype: Dictionary = (entry as Dictionary)
		var score: float = yomi_weighted_total(etype)
		scored.append([int(key), score])
	## Sort descending by weighted score.
	scored.sort_custom(func(a, b): return a[1] > b[1])
	## Assign attention weight based on engagement + priority rank.
	var cid: int = CombatantEntityAccess.id_int(defender)
	for i in range(scored.size()):
		var atk_id: int = scored[i][0]
		var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, atk_id)
		if atk.is_empty():
			continue
		var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, cid, CombatConstants.DISTANCE_LONG)
		## Base weight from engagement distance.
		var base_weight: float = 1.0
		if band == CombatConstants.DISTANCE_MID:
			base_weight = 0.6
		elif band == CombatConstants.DISTANCE_LONG:
			base_weight = 0.25
		## Apply priority rank degradation for excess attention targets.
		var final_weight: float = base_weight
		if i >= CombatConstants.YOMI_ATTENTION_BUDGET_MAX:
			final_weight *= CombatConstants.YOMI_ATTENTION_PRIORITY_DEGRADE_MULT
		final_weight = clampf(final_weight, 0.25, 1.0)
		## Update the entry.
		var etype: Dictionary = root.get(str(atk_id), {}) as Dictionary
		etype[DataKeys.ATTENTION_PRIORITY_RANK] = i + 1
		etype[DataKeys.ATTENTION_WEIGHT] = final_weight
		root[str(atk_id)] = etype
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root




static func _apply_decay_to_entry(entry: Dictionary, current_tick: int) -> void:
	if entry.is_empty() or current_tick <= 0:
		return
	var last_tick: float = float(entry.get(DataKeys.ATTENTION_LAST_TICK, -1))
	if last_tick < 0:
		return
	var age: float = float(current_tick) - last_tick
	if age <= 0.0:
		return
	var decay: float = pow(CombatConstants.YOMI_DECAY_FACTOR_PER_TICK, age)
	if absf(decay - 1.0) < 0.001:
		return
	var wlc: Dictionary = entry.get(DataKeys.ATTENTION_WEIGHTED_LINE_COUNTS, {}) as Dictionary
	for key in wlc.keys():
		wlc[key] *= decay
	entry[DataKeys.ATTENTION_WEIGHTED_LINE_COUNTS] = wlc
	var wmc: Dictionary = entry.get(DataKeys.ATTENTION_WEIGHTED_MOVE_ID_COUNTS, {}) as Dictionary
	for key in wmc.keys():
		wmc[key] *= decay
	entry[DataKeys.ATTENTION_WEIGHTED_MOVE_ID_COUNTS] = wmc


static func _apply_decay_to_all_entries(defender: Dictionary, current_tick: int) -> void:
	if defender.is_empty() or current_tick <= 0:
		return
	var root: Dictionary = _yomi_root(defender)
	for key in root.keys():
		var entry: Variant = root.get(key, null)
		if entry is not Dictionary:
			continue
		_apply_decay_to_entry(entry as Dictionary, current_tick)
		_age_recent_counts(entry as Dictionary, current_tick)


static func _age_recent_counts(entry: Dictionary, current_tick: int) -> void:
	var last_tick: float = float(entry.get(DataKeys.ATTENTION_LAST_TICK, -1))
	if last_tick < 0.0 or current_tick <= 0:
		return
	var age: float = float(current_tick) - last_tick
	if age <= 0.0:
		return
	var window: int = CombatConstants.WF_YOMI_STALENESS_RECENT_WINDOW
	var elapsed_since_recent: float = float(entry.get(DataKeys.ATTENTION_RECENT_WINDOW_AGE, 0)) + age
	while elapsed_since_recent >= float(window):
		elapsed_since_recent -= float(window)
		_drain_one_recent_bucket(entry, DataKeys.ATTENTION_RECENT_LINE_COUNTS)
		_drain_one_recent_bucket(entry, DataKeys.ATTENTION_RECENT_MOVE_ID_COUNTS)
	entry[DataKeys.ATTENTION_RECENT_WINDOW_AGE] = int(elapsed_since_recent)


static func _drain_one_recent_bucket(entry: Dictionary, bucket_key: String) -> void:
	var bucket: Dictionary = entry.get(bucket_key, {}) as Dictionary
	if bucket.is_empty():
		return
	var drained: Dictionary = {}
	for k in bucket.keys():
		var v: int = int(bucket[k])
		if v > 1:
			drained[k] = v - 1
		## count reaches 0 → removed (bucket evicted)
	entry[bucket_key] = drained


static func _yomi_observation_threat_weight(
	manager: Node, attacker_id: int, defender: Dictionary, _target_part: String
) -> float:
	## Returns 0.25 (non-engaged / long distance) to ~1.3 (engaged + high strength).
	if manager == null or defender == null or attacker_id < 0:
		return 1.0
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty():
		return 1.0
	var dist_band: String = CombatantEntityAccess.distance_to_opponent_band(atk, CombatantEntityAccess.id_int(defender), "")
	var engagement_mult: float = 1.0
	if dist_band == CombatConstants.DISTANCE_LONG:
		engagement_mult = CombatConstants.YOMI_NON_ENGAGED_WEIGHT
	elif dist_band == CombatConstants.DISTANCE_MID:
		engagement_mult = 0.6
	var stats: Dictionary = CombatantEntityAccess.stats_dict(atk)
	var str_val: float = stats.get(DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE)
	var threat_factor: float = 1.0 + log(1.0 + str_val / 25.0) * 0.3
	return engagement_mult * threat_factor


static func record_attack_toward_defender(
	_manager: Node, attacker_id: int, defender: Dictionary, target_part: String, move_id: String = ""
) -> void:
	if not enabled() or defender == null or attacker_id < 0:
		return
	var part: String = target_part.strip_edges()
	var mid: String = move_id.strip_edges()
	if part.is_empty() and mid.is_empty():
		return
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Dictionary = _yomi_entry(defender, attacker_id)
	## Store timestamp for decay computation (manager may be null in harness / resolved-strike paths).
	var tick: int = -1
	if _manager != null:
		tick = _manager.get_combat_tick_index()
		entry[DataKeys.ATTENTION_LAST_TICK] = tick
	if not part.is_empty():
		var line: String = CombatConstants.PART_TO_LINE.get(part, "high")
		## Raw count (existing behavior).
		var counts: Dictionary = entry.get(DataKeys.ATTENTION_LINE_COUNTS, {}) as Dictionary
		counts[line] = counts.get(line, 0) + 1
		entry[DataKeys.ATTENTION_LINE_COUNTS] = counts
		## Weighted count — threat × engagement factor from distance band.
		var w_counts: Dictionary = entry.get(DataKeys.ATTENTION_WEIGHTED_LINE_COUNTS, {}) as Dictionary
		var tw: float = _yomi_observation_threat_weight(_manager, attacker_id, defender, part)
		w_counts[line] = w_counts.get(line, 0.0) + tw
		entry[DataKeys.ATTENTION_WEIGHTED_LINE_COUNTS] = w_counts
		## Recent count for staleness detection (fades after WF_YOMI_STALENESS_RECENT_WINDOW ticks).
		var rlc: Dictionary = entry.get(DataKeys.ATTENTION_RECENT_LINE_COUNTS, {}) as Dictionary
		rlc[line] = rlc.get(line, 0) + 1
		entry[DataKeys.ATTENTION_RECENT_LINE_COUNTS] = rlc
		## Per-line observation tick for staleness gate (read-only).
		var line_ticks: Dictionary = entry.get(DataKeys.ATTENTION_LINE_OBS_TICKS, {}) as Dictionary
		line_ticks[line] = tick
		entry[DataKeys.ATTENTION_LINE_OBS_TICKS] = line_ticks
	if not mid.is_empty():
		## Raw count (existing behavior).
		var move_counts: Dictionary = entry.get(DataKeys.ATTENTION_MOVE_ID_COUNTS, {}) as Dictionary
		move_counts[mid] = move_counts.get(mid, 0) + 1
		entry[DataKeys.ATTENTION_MOVE_ID_COUNTS] = move_counts
		var ct: String = WeaponConstants.contact_type_for_move_id(mid)
		var ct_counts: Dictionary = entry.get(DataKeys.ATTENTION_CONTACT_TYPE_COUNTS, {}) as Dictionary
		ct_counts[ct] = ct_counts.get(ct, 0) + 1
		entry[DataKeys.ATTENTION_CONTACT_TYPE_COUNTS] = ct_counts
		## Weighted count.
		var wmc: Dictionary = entry.get(DataKeys.ATTENTION_WEIGHTED_MOVE_ID_COUNTS, {}) as Dictionary
		var tw_m: float = _yomi_observation_threat_weight(_manager, attacker_id, defender, part)
		wmc[mid] = wmc.get(mid, 0.0) + tw_m
		entry[DataKeys.ATTENTION_WEIGHTED_MOVE_ID_COUNTS] = wmc
		## Recent move id count for staleness detection.
		var rmc: Dictionary = entry.get(DataKeys.ATTENTION_RECENT_MOVE_ID_COUNTS, {}) as Dictionary
		rmc[mid] = rmc.get(mid, 0) + 1
		entry[DataKeys.ATTENTION_RECENT_MOVE_ID_COUNTS] = rmc
		## Per-move observation tick for staleness gate (read-only).
		var move_ticks: Dictionary = entry.get(DataKeys.ATTENTION_MOVE_OBS_TICKS, {}) as Dictionary
		move_ticks[mid] = tick
		entry[DataKeys.ATTENTION_MOVE_OBS_TICKS] = move_ticks
	root[key] = entry
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


## WF-2a: resolved strike move id only (line habit recorded separately at wind-up).
static func record_resolved_strike_toward_defender(defender: Dictionary, attacker_id: int, move_id: String) -> void:
	record_attack_toward_defender(null, attacker_id, defender, "", move_id)


## WF-2a: return the last observed tick for a specific line from an attacker. Returns -1 if never observed.
static func yomi_last_observed_line(entry: Dictionary, line: String) -> int:
	return int(entry.get(DataKeys.ATTENTION_LINE_OBS_TICKS, {}).get(line, -1))


## WF-2a: return the last observed tick for a specific move_id from an attacker. Returns -1 if never observed.
static func yomi_last_observed_move(entry: Dictionary, move_id: String) -> int:
	return int(entry.get(DataKeys.ATTENTION_MOVE_OBS_TICKS, {}).get(move_id, -1))


static func record_feint_resolved_toward_defender(defender: Dictionary, attacker_id: int) -> void:
	if not enabled() or defender == null or attacker_id < 0:
		return
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Dictionary = _yomi_entry(defender, attacker_id)
	entry[DataKeys.ATTENTION_FEINT_RESOLVED] = entry.get(DataKeys.ATTENTION_FEINT_RESOLVED, 0) + 1
	root[key] = entry
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func record_parry_deflect_on_attacker_memory(defender: Dictionary, attacker_id: int) -> void:
	if not enabled() or defender == null or attacker_id < 0:
		return
	var root: Dictionary = _yomi_root(defender)
	var key: String = str(attacker_id)
	var entry: Dictionary = _yomi_entry(defender, attacker_id)
	entry[DataKeys.ATTENTION_PARRY_DEFLECT] = entry.get(DataKeys.ATTENTION_PARRY_DEFLECT, 0) + 1
	root[key] = entry
	defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func clear_yomi_for_attacker(defender: Dictionary, attacker_id: int) -> void:
	if defender == null or attacker_id < 0:
		return
	var root: Dictionary = _yomi_root(defender)
	root.erase(str(attacker_id))
	if root.is_empty():
		defender.erase(CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER)
	else:
		defender[CombatConstants.COMBATANT_KEY_YOMI_BY_ATTACKER] = root


static func dominant_attack_line_toward_defender(defender: Dictionary, attacker_id: int) -> String:
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return ""
	var counts: Dictionary = (entry as Dictionary).get(DataKeys.ATTENTION_LINE_COUNTS, {}) as Dictionary
	var best_line: String = ""
	var best_n: int = 0
	for line_key in counts.keys():
		var n: int = int(counts[line_key])
		if n > best_n:
			best_n = n
			best_line = str(line_key)
	return best_line


static func line_count_toward_defender(defender: Dictionary, attacker_id: int, line: String) -> int:
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary or line.is_empty():
		return 0
	var counts: Dictionary = (entry as Dictionary).get(DataKeys.ATTENTION_LINE_COUNTS, {}) as Dictionary
	return counts.get(line, 0)


## AI (non party-lead): nudge **`focus_part`** toward attacker's habitual line; mismatched feint telegraph keeps habit.
static func apply_yomi_focus_drift(manager: Node, c: Dictionary, forced_incoming_attacker_id: int = -1) -> void:
	if not enabled() or c == null or CombatantEntityAccess.is_formation_telegraph_leader(c):
		return
	var atk_id: int = forced_incoming_attacker_id
	if atk_id < 0 and manager != null:
		atk_id = _counter_tempo().call("incoming_attacker_id", manager, CombatantEntityAccess.id_int(c))
	if atk_id < 0:
		return
	var dom: String = dominant_attack_line_toward_defender(c, atk_id)
	if dom.is_empty():
		return
	# Short engagement shortcut: after fewer total ticks, one observation suffices.
	var line_count: int = line_count_toward_defender(c, atk_id, dom)
	var tick_idx: int = 0
	if manager != null:
		tick_idx = manager.get_combat_tick_index()
	var min_lines: int = CombatConstants.YOMI_FOCUS_DRIFT_MIN_LINE_COUNT
	if tick_idx < CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD:
		min_lines = CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT
	# V5 HEMA realism: high-perception fighters detect patterns faster (fewer observations needed).
	var c_stats := CombatantEntityAccess.stats_dict(c)
	var perception: float = float(c_stats.get(DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE))
	min_lines = int(ceilf(float(min_lines) * (1.0 - CombatConstantsMentalStack.YOMI_PERCEPTION_LINE_SCALE * (perception / 100.0))))
	if line_count < min_lines:
		return
	var habit_part: String = CombatConstants.LINE_TO_DEFAULT_PART.get(dom, "")
	if habit_part.is_empty():
		return
	var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
	var focus_part: String = habit_part
	if not tele.is_empty():
		var tele_line: String = CombatConstants.PART_TO_LINE.get(tele, "")
		if tele_line == dom:
			focus_part = tele
		elif tele_line != dom:
			focus_part = habit_part
		else:
			focus_part = tele
	var next_intensity: float = maxf(get_focus_intensity(c), CombatConstants.YOMI_FOCUS_DRIFT_INTENSITY)
	set_focus(c, focus_part, next_intensity)


## Tier 4.3.8: guard-priority score (0..1) — how strongly a waiting combatant should hold + position its
## blade toward the expected attack line instead of opening offense. Live wind-up telegraph scores
## highest; otherwise an engaged attacker's habitual yomi line builds score from observation count.
## Suppressed for exhausted / critical-stamina fighters (L5 exhaustion dominates their menu).
static func guard_priority_score(manager: Node, c: Dictionary) -> float:
	if not enabled() or c == null or manager == null:
		return 0.0
	if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return 0.0
	var cid: int = CombatantEntityAccess.id_int(c)
	if cid < 0:
		return 0.0
	if (
		CombatExhaustion.exhaustion_tunnel_active(c)
		or CombatantEntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
	):
		return 0.0
	if is_being_wind_up_targeted(manager, cid):
		return CombatConstantsMentalStack.GUARD_PRIORITY_TELEGRAPH_SCORE * _incoming_wind_up_remaining(manager, cid)
	return clampf(float(_guard_priority_yomi_target(manager, c).get("score", 0.0)), 0.0, 1.0)


## Tier 4.3.8: the guard line this combatant should position toward — live telegraph line when
## wind-up targeted, else the most threatening engaged attacker's habitual line (band-weighted, so a
## CLOSE threat dominates a MID one with a similar read). Empty when no readable signal.
static func guard_priority_target_line(manager: Node, c: Dictionary) -> String:
	if not enabled() or c == null or manager == null:
		return ""
	var cid: int = CombatantEntityAccess.id_int(c)
	if cid < 0:
		return ""
	var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
	if not tele.is_empty():
		var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
		if not tele_line.is_empty():
			return tele_line
	return str(_guard_priority_yomi_target(manager, c).get("line", ""))


## Tier 4.3.8: fraction of the incoming wind-up still remaining (1 = just started, 0 = landing).
## Readability decays with commitment: a strike past the readable window is too late to shift stance.
static func _incoming_wind_up_remaining(manager: Node, defender_id: int) -> float:
	if manager == null or defender_id < 0:
		return 1.0
	var atk_id: int = _counter_tempo().call("incoming_attacker_id", manager, defender_id)
	if atk_id < 0:
		return 1.0
	var progress: float = float(_counter_tempo().call("incoming_wind_up_progress", manager, atk_id))
	return clampf(1.0 - progress, 0.0, 1.0)


## Tier 4.3.8: readable-habit floor — one observation in a short engagement (duel), two in a longer
## fight, mirroring `apply_yomi_focus_drift`. Guards settle into a 1v1 read faster than a melee.
static func _guard_priority_min_line_count(manager: Node) -> int:
	if (
		manager != null
		and int(manager.get_combat_tick_index()) < CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD
	):
		return CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT
	return CombatConstantsMentalStack.GUARD_PRIORITY_MIN_LINE_COUNT


## Tier 4.3.8: per-attacker yomi read score (0 = not engaged / not readable). Band-weighted so a CLOSE
## threat dominates a MID one with a similar read; shares the min-count rule with the score.
static func _guard_priority_read_score(manager: Node, c: Dictionary, attacker_id: int, min_count: int) -> float:
	var cid: int = CombatantEntityAccess.id_int(c)
	var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
	if atk.is_empty() or not CombatantEntityAccess.is_alive_in_combat(atk):
		return 0.0
	var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, cid, "")
	if band == CombatConstants.DISTANCE_LONG:
		return 0.0
	var dom: String = dominant_attack_line_toward_defender(c, attacker_id)
	if dom.is_empty():
		return 0.0
	var n: int = line_count_toward_defender(c, attacker_id, dom)
	if n < min_count:
		return 0.0
	var s: float = minf(
		CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_BASE
			+ float(n - min_count) * CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_PER_LINE_COUNT,
		CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_CAP
	)
	if band == CombatConstants.DISTANCE_MID:
		s *= CombatConstantsMentalStack.GUARD_PRIORITY_MID_BAND_MULT
	return s


## Tier 4.3.8: single yomi source for score + target — returns `{score, line, attacker_id}` for the most
## threatening engaged attacker (band-weighted, so score and line selection always agree). `line` is empty
## when no readable habit; `score` is the band-weighted read strength (0 when unreadable).
static func _guard_priority_yomi_target(manager: Node, c: Dictionary) -> Dictionary:
	var min_count: int = _guard_priority_min_line_count(manager)
	var root: Dictionary = _yomi_root(c)
	var best_score: float = 0.0
	var best_line: String = ""
	var best_atk: int = -1
	for key in root.keys():
		var entry: Variant = root.get(key, null)
		if entry is not Dictionary:
			continue
		var etype: Dictionary = entry as Dictionary
		if float(etype.get(DataKeys.ATTENTION_WEIGHT, 1.0)) < 0.5:
			continue
		var atk_id: int = int(key)
		var s: float = _guard_priority_read_score(manager, c, atk_id, min_count)
		if s > best_score:
			best_score = s
			best_line = dominant_attack_line_toward_defender(c, atk_id)
			best_atk = atk_id
	return {"score": best_score, "line": best_line, "attacker_id": best_atk}


## Tier 4.3.8: proactive guard positioning — each waiting tick (free, no action spent) drift **`guard_line`**
## toward the opponent's habitual yomi line so parry alignment is already high when their wind-up lands.
## Anticipation outside of wind-up: skipped while a telegraph is live (L4G spends the action to align on
## a live wind-up) and for formation telegraph leaders (explicit 6.0 leader telegraph-match path).
static func apply_guard_priority_drift(manager: Node, c: Dictionary) -> void:
	if not enabled() or c == null or manager == null:
		return
	if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
		return
	if CombatantEntityAccess.is_formation_telegraph_leader(c):
		return
	var cid: int = CombatantEntityAccess.id_int(c)
	if cid < 0:
		return
	if is_being_wind_up_targeted(manager, cid):
		# Live wind-up: preserve the waiting-tick stamp so the weight path still gets a brace boost
		# during the telegraph window (L4G picks the brace action; the stamp lifts its focus-line
		# weight). Only erase when there is no existing stamp to drop through to.
		var old_target: String = str(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE, "")).strip_edges()
		if old_target.is_empty():
			c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
			c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
		return
	var tgt: Dictionary = _guard_priority_yomi_target(manager, c)
	var score: float = clampf(float(tgt.get("score", 0.0)), 0.0, 1.0)
	if score < CombatConstantsMentalStack.GUARD_PRIORITY_MIN_SCORE:
		c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
		c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
		return
	var line: String = str(tgt.get("line", ""))
	var atk_id: int = int(tgt.get("attacker_id", -1))
	if line.is_empty():
		c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
		c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
		return
	c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY] = score
	c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE] = line
	var cur: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
	if cur == line:
		return
	if atk_id < 0:
		return
	# Commitment: hold the current read until the new line is observed more toward the dominant
	# attacker (anti-flicker). A current guard the opponent hasn't attacked toward (count 0) yields.
	var cur_n: int = line_count_toward_defender(c, atk_id, cur)
	var line_n: int = line_count_toward_defender(c, atk_id, line)
	if line_n <= cur_n + CombatConstantsMentalStack.GUARD_PRIORITY_SWITCH_COUNT_MARGIN:
		return
	GuardLineUpdater.set_guard_from_line(c, line, false)


## Feint listing: boost when feint telegraph line matches attacker's habitual target line.
static func yomi_feint_listing_mult(defender: Dictionary, attacker_id: int, feint_part: String) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var fp: String = feint_part.strip_edges()
	if fp.is_empty():
		return 1.0
	var dom: String = dominant_attack_line_toward_defender(defender, attacker_id)
	if dom.is_empty():
		return 1.0
	var feint_line: String = CombatConstants.PART_TO_LINE.get(fp, "")
	if feint_line != dom:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Dictionary = root.get(str(attacker_id), {}) as Dictionary
	var counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}) as Dictionary
	var n: int = counts.get(dom, 0)
	if n < CombatConstants.YOMI_FEINT_LISTING_MIN_LINE_COUNT:
		return 1.0
	var boost: float = (
		1.0
		+ (
			float(n - CombatConstants.YOMI_FEINT_LISTING_MIN_LINE_COUNT + 1)
			* CombatConstants.YOMI_FEINT_LISTING_MULT_PER_LINE_COUNT
		)
	)
	return minf(boost, CombatConstants.YOMI_FEINT_LISTING_MULT_CAP)


## Feint listing: recent **`parry_deflect`** vs this attacker makes feints more attractive.
static func yomi_parry_deflect_feint_listing_mult(defender: Dictionary, attacker_id: int) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return 1.0
	var n: int = (entry as Dictionary).get(DataKeys.ATTENTION_PARRY_DEFLECT, 0)
	if n <= 0:
		return 1.0
	var boost: float = 1.0 + float(n) * CombatConstants.YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_PER
	return minf(boost, CombatConstants.YOMI_PARRY_DEFLECT_FEINT_LISTING_MULT_CAP)


## Defender passive readiness: prior **`parry_deflect`** vs this attacker raises confidence.
static func yomi_defense_readiness_mult(defender: Dictionary, attacker_id: int) -> float:
	if not enabled() or defender == null or attacker_id < 0:
		return 1.0
	var root: Dictionary = _yomi_root(defender)
	var entry: Variant = root.get(str(attacker_id), null)
	if entry is not Dictionary:
		return 1.0
	var n: int = (entry as Dictionary).get(DataKeys.ATTENTION_PARRY_DEFLECT, 0)
	if n <= 0:
		return 1.0
	var boost: float = 1.0 + float(n) * CombatConstants.YOMI_DEFENSE_READINESS_MULT_PER_PARRY_DEFLECT
	return minf(boost, CombatConstants.YOMI_DEFENSE_READINESS_MULT_CAP)


## Tier 4.3.7: self-target guard-line / focus retarget while waiting (`get_available_actions`).
static func append_focus_line_listing_actions(c: Dictionary, combatant_id: int, actions: Array) -> void:
	if not enabled() or c.is_empty():
		return
	for move_id in CombatConstants.FOCUS_LINE_MOVE_IDS:
		actions.append({"target_id": combatant_id, "move_id": move_id})

## Phase 5: get or create the deception_state sub-dict on a combatant.
static func _get_deception_state(c: Dictionary) -> Dictionary:
	var raw: Variant = c.get(CombatConstants.COMBATANT_KEY_DECEPTION_STATE, null)
	if raw is not Dictionary:
		raw = {
			DataKeys.DECEPTION_PHASE: Yomi.DECEPTION_PHASE_ESTABLISH,
			DataKeys.DECEPTION_RESISTANCE: 0.0,
			DataKeys.DECEPTION_EXPLOIT_COUNTER: 0,
		}
		c[CombatConstants.COMBATANT_KEY_DECEPTION_STATE] = raw
	return raw as Dictionary


## Phase 5: update deception state after a counter-read outcome (called from AttackResultApplier).
static func record_deception_outcome(c: Dictionary, opponent_id: int, success: bool) -> void:
	if c == null or opponent_id < 0:
		return
	var ds: Dictionary = _get_deception_state(c)
	var phase: String = ds.get(DataKeys.DECEPTION_PHASE, Yomi.DECEPTION_PHASE_ESTABLISH)
	var resistance: float = ds.get(DataKeys.DECEPTION_RESISTANCE, 0.0)
	var exploit_counter: int = ds.get(DataKeys.DECEPTION_EXPLOIT_COUNTER, 0)
	if success:
		if phase == Yomi.DECEPTION_PHASE_PROBE:
			ds[DataKeys.DECEPTION_PHASE] = Yomi.DECEPTION_PHASE_EXPLOIT
			exploit_counter = 0
		elif phase == Yomi.DECEPTION_PHASE_EXPLOIT:
			exploit_counter += 1
		elif phase == Yomi.DECEPTION_PHASE_ESTABLISH:
			resistance += Yomi.DECEPTION_RESISTANCE_ESTABLISH_SUCCESS_BOOST
			resistance = clampf(resistance, 0.0, 1.0)
	else:
		if phase == Yomi.DECEPTION_PHASE_EXPLOIT:
			ds[DataKeys.DECEPTION_PHASE] = Yomi.DECEPTION_PHASE_ESTABLISH
			resistance = minf(resistance + Yomi.DECEPTION_RESISTANCE_EXPLOIT_FAILURE_BOOST, 1.0)
		elif phase == Yomi.DECEPTION_PHASE_PROBE:
			ds[DataKeys.DECEPTION_PHASE] = Yomi.DECEPTION_PHASE_ESTABLISH
		else:
			## Establish failure — resistance grows faster.
			resistance += Yomi.DECEPTION_RESISTANCE_ESTABLISH_FAILURE_BOOST
			resistance = clampf(resistance, 0.0, 1.0)
	ds[DataKeys.DECEPTION_RESISTANCE] = resistance
	ds[DataKeys.DECEPTION_EXPLOIT_COUNTER] = exploit_counter


## Phase 5: return true when the opponent's deception state suggests they are baiting a counter-read.
static func should_respect_bait(c: Dictionary, rng: RandomNumberGenerator = null) -> bool:
	if c == null:
		return false
	var raw: Variant = c.get(CombatConstants.COMBATANT_KEY_DECEPTION_STATE, null)
	if raw is not Dictionary:
		return false
	var ds: Dictionary = raw as Dictionary
	var phase: String = ds.get(DataKeys.DECEPTION_PHASE, Yomi.DECEPTION_PHASE_ESTABLISH)
	if phase != Yomi.DECEPTION_PHASE_EXPLOIT:
		return false
	var exploit_counter: int = ds.get(DataKeys.DECEPTION_EXPLOIT_COUNTER, 0)
	if exploit_counter >= 3:
		## After repeated exploitation, the deception has been "seen through."
		return false
	var resistance: float = ds.get(DataKeys.DECEPTION_RESISTANCE, 0.0)
	if resistance > CombatConstants.DECEPTION_ESTABLISH_PROB:
		return false
	var max_bait_prob: float = CombatConstants.DECEPTION_EXPLOIT_BAIT_PROB_MAX
	var t: float = float(exploit_counter) / 3.0
	var bait_prob: float = lerpf(0.1, max_bait_prob, t)
	if rng != null:
		return rng.randf() < bait_prob
	return randf() < bait_prob


## Phase 5: advance deception state probe threshold — called after consecutive correct reads.
static func try_advance_deception_probe(c: Dictionary, correct_count: int) -> void:
	if c == null or correct_count < CombatConstants.DECEPTION_PROBE_THRESHOLD:
		return
	var ds: Dictionary = _get_deception_state(c)
	if ds.get(DataKeys.DECEPTION_PHASE, Yomi.DECEPTION_PHASE_ESTABLISH) != Yomi.DECEPTION_PHASE_ESTABLISH:
		return
	ds[DataKeys.DECEPTION_PHASE] = Yomi.DECEPTION_PHASE_PROBE
