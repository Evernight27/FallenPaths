class_name CombatWeaponForm
extends RefCounted
const FORM_OX := "ox"
const FORM_PLOW := "plow"
const FORM_WRATH := "wrath"
const FORM_FOOL := "fool"
const FORM_WALL := "wall"
const FORM_TEMPEST := "tempest"
const FORM_BALANCED := "balanced"

const FORM_AXE_DEMI := "demi_hache"
const FORM_AXE_BEC := "bec_point"
const FORM_AXE_QUEUE := "queue_bind"
const FORM_MACE_CROWN := "crown_guard"
const FORM_MACE_FLANK := "flank_guard"
const FORM_DAGGER_HIGH := "high_hut"
const FORM_DAGGER_LOW := "low_bind"
const FORM_DAGGER_REVERSE := "reverse_seize"
const FORM_SPEAR_IRON := "iron_gate"
const FORM_SPEAR_CROSS := "true_cross"
const FORM_SPEAR_PORT := "high_port"

## Per-fighter weapon form defs: temperament mods, move-family weights, pressure class, home guard, auto-switch.
## Read order: FORM_DEFS ÃƒÂ¢Ã¢Â€Â ' normalize ÃƒÂ¢Ã¢Â€Â ' seed ÃƒÂ¢Ã¢Â€Â ' mod/action_weight_mult ÃƒÂ¢Ã¢Â€Â ' pressure
## ÃƒÂ¢Ã¢Â€Â ' evaluate_automatic_form.
## Canonical: CombatantEntityAccess.form_str Â· mod Â· action_weight_mult Â· home_guard_line Â· evaluate_automatic_form.
## Footing: assign_form ÃƒÂ¢Ã¢Â€Â ' home guard_line only (LIVE_PATHS **`#wf-assign-form-contract`**); picker uses form
## weights only â€”" **`#wf-pick-vs-strike`**. Tier 4.4 PA: **`CombatFootwork`** â€”" hub **`#wf-tier-44-pa`**.
## **`#wf-footing-guards-stances`** Â· **`#wf-form-guard-pa-matrix`**.
## Manager requires: combatants, encounter, combat_clock (auto-switch cooldown only).

# Runtime preload — circular dependency (CombatAttention preloads CombatWeaponForm).
static var _attention_cache: Variant = null
static var _tactical_combat_cache: Variant = null

static var _form_defs_by_weapon: Dictionary = {}


static func _get_attention() -> GDScript:
	if _attention_cache == null:
		_attention_cache = load("res://combat/CombatAttention.gd")
	return _attention_cache


# Runtime preload — circular dependency (CombatConstants → CombatConstantsStance → CombatWeaponForm → TacticalCombat).


static func _get_tactical_combat() -> GDScript:
	if CombatWeaponForm._tactical_combat_cache == null:
		CombatWeaponForm._tactical_combat_cache = load("res://combat/TacticalCombat.gd")
	return CombatWeaponForm._tactical_combat_cache


static func _ensure_defs() -> void:
	if not _form_defs_by_weapon.is_empty():
		return
	_form_defs_by_weapon = CombatWeaponFormDefs.build_all()


static func _weapon_key(weapon: Variant) -> String:
	if weapon is String:
		var sid: String = str(weapon).strip_edges().to_upper()
		if not sid.is_empty():
			return sid
	var wid: String = WeaponConstants.weapon_type_id(weapon)
	if wid.is_empty():
		return "SWORD"
	return wid


static func _neutral_mod() -> Dictionary:
	return {
		"parry": 1.0,
		"evasion": 1.0,
		"damage": 1.0,
		"close_attempt": 1.0,
		"ai_melee_focus": 1.0,
		"feint_readthrough": 1.0,
		"ai_feint_listing": 1.0,
	}


static func _def(form: String, weapon: Variant = null) -> Dictionary:
	_ensure_defs()
	var fid: String = _normalize_form_id(raw_form(form, weapon), weapon)
	var wid: String = _weapon_key(weapon) if weapon != null else ""
	if wid.is_empty():
		for wkey in _form_defs_by_weapon.keys():
			var bucket: Variant = _form_defs_by_weapon[wkey]
			if bucket is Dictionary and (bucket as Dictionary).has(fid):
				return (bucket as Dictionary)[fid] as Dictionary
		wid = "SWORD"
	var bucket2: Variant = _form_defs_by_weapon.get(wid, null)
	if bucket2 is not Dictionary:
		return (_form_defs_by_weapon.get("SWORD", {}) as Dictionary).get(FORM_BALANCED, {}) as Dictionary
	var defs: Dictionary = bucket2 as Dictionary
	if defs.has(fid):
		return defs[fid] as Dictionary
	return defs.get(FORM_BALANCED, {}) as Dictionary


static func raw_form(raw: String, weapon: Variant = null) -> String:
	var s: String = str(raw).strip_edges().to_lower()
	if s.is_empty():
		return FORM_BALANCED
	if weapon != null:
		s = WeaponConstants.resolve_form_legacy_alias(weapon, s)
	match s:
		"defensive":
			return FORM_WALL
		"aggressive":
			if weapon != null:
				return WeaponConstants.resolve_form_legacy_alias(weapon, "wrath")
			return FORM_WRATH
		"controlling":
			if weapon != null:
				return WeaponConstants.resolve_form_legacy_alias(weapon, "fool")
			return FORM_FOOL
		_:
			return s


static func _normalize_form_id(s: String, weapon: Variant = null) -> String:
	if s.is_empty():
		return FORM_BALANCED
	if weapon != null:
		var allowed: Array = WeaponConstants.allowed_forms_for_weapon(weapon)
		if not allowed.is_empty() and s not in allowed:
			return raw_form(WeaponConstants.default_form_for_weapon(weapon), weapon)
	return s


static func normalize_form(raw: String, weapon: Variant = null) -> String:
	return _normalize_form_id(raw_form(raw, weapon), weapon)


static func form_allowed_for_weapon(form: String, weapon: Variant) -> bool:
	var fid: String = raw_form(form, weapon)
	var allowed: Array = WeaponConstants.allowed_forms_for_weapon(weapon)
	return allowed.is_empty() or fid in allowed


static func default_form_for_weapon(weapon: Variant) -> String:
	return normalize_form(WeaponConstants.default_form_for_weapon(weapon), weapon)


static func home_guard_line(form: String, weapon: Variant = null) -> String:
	var d: Dictionary = _def(form, weapon)
	return str(d.get("home_guard", CombatConstants.GUARD_DEFAULT))


static func preferred_guards(form: String, weapon: Variant = null) -> PackedStringArray:
	var d: Dictionary = _def(form, weapon)
	var raw: Variant = d.get("preferred_guards", PackedStringArray())
	if raw is PackedStringArray:
		return raw
	return PackedStringArray()


## Stance limb bias for AI target pick (multiplies per-part weights; 1.0 = neutral).
static func target_part_weight_mult(
	form: String, part: String, form_prof_tier: float = -1.0, weapon: Variant = null
) -> float:
	var bias: Variant = _def(form, weapon).get("target_part_bias", {})
	var base: float = 1.0
	if bias is Dictionary:
		base = float((bias as Dictionary).get(part, 1.0))
	if base == 1.0:
		return 1.0
	if form_prof_tier < 0.0:
		return base
	return lerpf(1.0, base, 0.5 + clampf(form_prof_tier, 0.0, 1.0) * 0.5)


## Move-family limb bias (links Layer A occurrence posture to Layer B aim).
static func move_family_part_weight_mult(form: String, move_id: String, part: String, weapon: Variant = null) -> float:
	var family: String = _move_family_for_move_id(move_id)
	if family.is_empty():
		return 1.0
	var fam_bias: Variant = _def(form, weapon).get("move_family_part_bias", {})
	if fam_bias is not Dictionary:
		return 1.0
	var row: Variant = (fam_bias as Dictionary).get(family, null)
	if row is Dictionary:
		return float((row as Dictionary).get(part, 1.0))
	return 1.0


static func _form_ids_for_weapon(weapon: Variant) -> Array:
	_ensure_defs()
	var bucket: Variant = _form_defs_by_weapon.get(_weapon_key(weapon), null)
	if bucket is Dictionary:
		return (bucket as Dictionary).keys()
	return []


static func _defensive_form_for_weapon(weapon: Variant) -> String:
	if form_allowed_for_weapon(FORM_WALL, weapon):
		return FORM_WALL
	for fid in _form_ids_for_weapon(weapon):
		if pressure_class_is(str(fid), "defensive", weapon):
			return normalize_form(str(fid), weapon)
	return ""


static func _duel_offense_form_ids(weapon: Variant) -> PackedStringArray:
	_ensure_defs()
	var seen: Dictionary = {}
	var out: PackedStringArray = PackedStringArray()
	for fid in _form_ids_for_weapon(weapon):
		var row: Variant = _def(str(fid), weapon).get("duel_offense_forms", PackedStringArray())
		if row is PackedStringArray:
			for d in row:
				var s: String = str(d)
				if s.is_empty() or seen.has(s):
					continue
				seen[s] = true
				out.append(s)
	return out


static func mod(form: String, effect: String, weapon: Variant = null) -> float:
	var d: Dictionary = _def(form, weapon)
	var m: Dictionary = d.get("mod", {}) as Dictionary
	return m.get(effect, 1.0)


static func display_name(form: String, weapon: Variant = null) -> String:
	return str(_def(form, weapon).get("display_name", "Balanced"))


static func form_ai_targeting_mult(actor: Dictionary) -> float:
	if actor.is_empty():
		return 1.0
	return mod(CombatantEntityAccess.form_str(actor), "ai_melee_focus", CombatantEntityAccess.get_weapon(actor))


static func pressure_class(form: String, weapon: Variant = null) -> String:
	return str(_def(form, weapon).get("pressure_class", "neutral"))


static func pressure_class_is(form: String, class_id: String, weapon: Variant = null) -> bool:
	return pressure_class(form, weapon) == str(class_id).strip_edges().to_lower()


static func controlling_pressure_active(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	var weapon = CombatantEntityAccess.get_weapon(c)
	var form: String = CombatantEntityAccess.form_str(c)
	if not pressure_class_is(form, "controlling", weapon):
		return false
	return CombatantEntityAccess.stamina_ratio(c) >= CombatConstants.STANCE_MIN_STAMINA_CONTROLLING_RATIO


## Live pressure tag for UI â€”" suppress **`controlling`** when the stamina gate is down.
static func pressure_class_label_for_ui(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var pressure: String = pressure_class(CombatantEntityAccess.form_str(c), CombatantEntityAccess.get_weapon(c))
	if pressure.is_empty() or pressure == "neutral":
		return ""
	if pressure == "controlling" and not controlling_pressure_active(c):
		return ""
	return pressure


static func opponent_close_evasion_divisor(form: String) -> float:
	if pressure_class_is(form, "controlling"):
		return CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	return 1.0


## Controlling pressure slows opponent formation disengage (fall_back / swap duration). LIVE_PATHS
## **`#wf-footing-improvement-backlog`** â€”" pairs with **`STANCE_MOD_OPPONENT_DISENGAGE`**.
static func opponent_disengage_pressure_mult(form: String) -> float:
	if pressure_class_is(form, "controlling"):
		return 1.0 / CombatConstants.STANCE_MOD_OPPONENT_DISENGAGE
	return 1.0


## AI **`attempt_close`** listing dampening vs controlling defender (mirrors resolve evasion divisor).
static func opponent_close_listing_weight_mult(form: String) -> float:
	if pressure_class_is(form, "controlling"):
		return CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	return 1.0


static func opponent_close_listing_weight_mult_for_defender(c: Dictionary) -> float:
	if not controlling_pressure_active(c):
		return 1.0
	return opponent_close_listing_weight_mult(CombatantEntityAccess.form_str(c))


static func min_stamina_ratio_for_form(form: String, weapon: Variant = null) -> float:
	return _def(form, weapon).get("min_stamina_ratio", 0.22)


static func wait_action_weight_mult(form: String, weapon: Variant = null) -> float:
	return _def(form, weapon).get("wait_weight_mult", 1.0)


static func _move_family_for_move_id(move_id: String) -> String:
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return "close"
	# Meisterhäue: Liechtenauer decisive counter-strikes share ARCHETYPE_OVERHEAD but form a distinct family.
	# schielhau is also a feint (is_feint=true) but must be classified as "meisterhau" for counter-intent scaling.
	var meisterhau_ids: PackedStringArray = ["zornhau", "scheitelhau", "krumphau", "schielhau"]
	if move_id in meisterhau_ids:
		return "meisterhau"
	if WeaponConstants.is_feint_move(move_id):
		return "feint"
	if WeaponConstants.is_parry_move(move_id):
		return "parry"
	var ct: String = WeaponConstants.contact_type_for_move_id(move_id)
	if ct == WeaponConstants.ATTACK_TYPE_STAB:
		return "thrust"
	var md: Dictionary = WeaponConstants.get_move(move_id)
	var arch: String = md.get(DataKeys.PA_ARCHETYPE_ID, "")
	var line: String = md.get(DataKeys.PA_ATTACK_LINE, "")
	if arch == WeaponConstants.ARCHETYPE_QUICK_SLASH or move_id == "slash" or move_id == "quick_slash":
		return "slash"
	if line.begins_with("low") or move_id == "unterhau":
		return "low_cut"
	if ct == WeaponConstants.ATTACK_TYPE_CUT or ct == WeaponConstants.ATTACK_TYPE_BLUNT:
		return "high_cut"
	return ""


static func action_weight_mult(form: String, move_id: String, weapon: Variant = null) -> float:
	var family: String = _move_family_for_move_id(move_id)
	if family.is_empty():
		return 1.0
	var d: Dictionary = _def(form, weapon)
	var fam: Dictionary = d.get("move_family_mult", {}) as Dictionary
	var base: float = fam.get(family, 1.0)
	var move_row: Variant = d.get("move_id_mult", {})
	if move_row is Dictionary:
		base *= float((move_row as Dictionary).get(move_id, 1.0))
	return base


static func wind_up_transition_mult(
	form: String, _move_id: String, guard_line: String, attack_line: String, weapon: Variant = null
) -> float:
	var home: String = home_guard_line(form, weapon)
	if home.is_empty() or attack_line.is_empty():
		return 1.0
	if guard_line == home and attack_line == home:
		return 0.88
	for pg in preferred_guards(form, weapon):
		if pg == attack_line and (guard_line == pg or guard_line == home):
			return 0.92
	return 1.0


static func _counter_spec_for_inferred(my_form: String, inferred_opp: String, weapon: Variant = null) -> Dictionary:
	var mine: String = normalize_form(my_form, weapon)
	var opp: String = str(inferred_opp).strip_edges().to_lower()
	if opp.is_empty():
		return {"mult": 1.0, "families": PackedStringArray()}
	var raw: Variant = (_def(mine, weapon).get("counters", {}) as Dictionary).get(opp, null)
	if raw is float or raw is int:
		return {"mult": float(raw), "families": PackedStringArray()}
	if raw is Dictionary:
		return {
			"mult": (raw as Dictionary).get("mult", 1.0),
			"families": _coerce_string_array((raw as Dictionary).get("families", [])),
		}
	return {"mult": 1.0, "families": PackedStringArray()}


static func _coerce_string_array(raw: Variant) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if raw is PackedStringArray:
		return raw as PackedStringArray
	if raw is Array:
		for item in raw:
			var s: String = str(item).strip_edges()
			if not s.is_empty():
				out.append(s)
	return out


## WF-2b: picker boost when **`my_form`** counters inferred opponent habit for this **`move_id`** family.
## A2 meisterhau: decisive counter-strikes scale counter bonus by yomi confidence — misread = weaker strike.
static func form_counter_mult(
	my_form: String, inferred_opp_form: String, move_id: String, weapon: Variant = null
) -> float:
	if inferred_opp_form.is_empty() or move_id.is_empty():
		return 1.0
	var spec: Dictionary = _counter_spec_for_inferred(my_form, inferred_opp_form, weapon)
	var mult: float = spec.get("mult", 1.0)
	if mult <= 1.0:
		return 1.0
	var families: PackedStringArray = _coerce_string_array(spec.get("families", []))
	if not families.is_empty():
		var _family: String = _move_family_for_move_id(move_id)
		if _family.is_empty() or _family not in families:
			return 1.0
	# A2: meisterhäue counter-intent scaling — bonus is reduced when yomi confidence is low.
	var family: String = _move_family_for_move_id(move_id)
	if family == "meisterhau":
		mult *= CombatConstants.A2_MEISTERHAU_CONFIDENCE_SCALE_FACTOR
	return minf(mult, CombatConstants.WF_FORM_COUNTER_MULT_CAP)


## WF-2b: optional defense bump when defender form counters inferred attacker form.
static func counter_readiness_nudge(my_form: String, inferred_opp_form: String, weapon: Variant = null) -> float:
	if inferred_opp_form.is_empty():
		return 0.0
	var mult: float = _counter_spec_for_inferred(my_form, inferred_opp_form, weapon).get("mult", 1.0)
	if mult <= 1.0:
		return 0.0
	var t: float = clampf((mult - 1.0) / maxf(0.001, CombatConstants.WF_FORM_COUNTER_MULT_CAP - 1.0), 0.0, 1.0)
	return lerpf(CombatConstants.WF_COUNTER_READINESS_NUDGE_MIN, CombatConstants.WF_COUNTER_READINESS_NUDGE_MAX, t)


## Phase 2: record whether a counter-read switch was correct or wrong (called by AttackResultApplier).
static func record_counter_read_outcome(c: Dictionary, opponent_id: int, success: bool, inferred_form: String) -> void:
	if c == null or opponent_id < 0:
		return
	var history_key: String = CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY
	var history: Variant = c.get(history_key, null)
	if history is not PackedStringArray:
		history = PackedStringArray()
	var entry: String = "opp=%d form=%s success=%s" % [opponent_id, inferred_form, str(success)]
	history.append(entry)
	var max_entries: int = CombatConstantsEncounter.COUNTER_READ_HISTORY_MAX_ENTRIES
	if history.size() > max_entries:
		c[history_key] = PackedStringArray(history.slice(history.size() - max_entries))
	else:
		c[history_key] = history
	if success:
		## Count consecutive correct reads for deception probe advancement.
		var consec_correct: int = 0
		var len2: int = history.size()
		for i in range(len2 - 1, -1, -1):
			if "success=true" in str(history[i]):
				consec_correct += 1
			else:
				break
		CombatAttention.try_advance_deception_probe(c, consec_correct)


## Phase 2: check if combatant is still in counter-read commitment window.
static func is_counter_read_committed(c: Dictionary, current_tick: float) -> bool:
	var until: Variant = c.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL, null)
	if until == null:
		return false
	return float(until) > current_tick


## Phase 2: get the number of recent wrong counter-reads (last 5 entries).
static func count_recent_wrong_readings(c: Dictionary) -> int:
	var history_key: String = CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_HISTORY
	var history: Variant = c.get(history_key, null)
	if history is not PackedStringArray:
		return 0
	var recent: PackedStringArray
	var _len: int = history.size()
	if _len <= 5:
		recent = history
	else:
		recent = PackedStringArray(history.slice(_len - 5))
	var wrong_count: int = 0
	for entry in recent:
		if "success=false" in str(entry):
			wrong_count += 1
	return wrong_count


## Phase 5: check whether deception state suggests the opponent is baiting a counter-read.
static func _should_bait_counter_read(manager: Node, c: Dictionary, opponent_id: int) -> bool:
	if manager == null or c == null or opponent_id < 0:
		return false
	var opp_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, opponent_id)
	if opp_c.is_empty():
		return false
	return CombatAttention.should_respect_bait(opp_c)


## Phase 5 (temporal windows): check whether the form inference for an opponent is stale.
static func _is_form_stale_for_opponent(manager: Node, c: Dictionary, opponent_id: int) -> bool:
	if manager == null or c == null or opponent_id < 0:
		return false
	var opp_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, opponent_id)
	if opp_c.is_empty():
		return false
	## Staleness detection compares recent observations against all-time history; returns true when
	## recent data points to a different form than historical data (phase 5 temporal windows).
	## Note: _detect_form_staleness accesses "recent_line_counts"/"recent_move_id_counts" directly
	## rather than via get_observation_view("recent") — the "recent" view type exists but is not used
	## by any caller; staleness detection bypasses it to avoid creating intermediate Dictionary objects.
	var entry: Dictionary = _get_attention().yomi_entry_for_attacker(c, opponent_id)
	if entry.is_empty():
		return false
	var weapon = CombatantEntityAccess.get_weapon(opp_c)
	return _detect_form_staleness(entry, weapon)


static func _prior_sum_for_weapon(weapon: Variant) -> float:
	var s: float = 0.0
	for fid in _form_ids_for_weapon(weapon):
		var pri: float = CombatConstants.WF_YOMI_FORM_PRIORS.get(str(fid), 1.0)
		s += pri
	if s <= 0.0:
		return 1.0
	return s


static func _per_signal_scores(form: String, entry: Dictionary, weapon: Variant = null) -> Dictionary:
	var sig: Dictionary = _def(form, weapon).get("signature", {}) as Dictionary
	if sig.is_empty() or entry.is_empty():
		return {"move_ids": 0.0, "contact_types": 0.0, "lines": 0.0, "feint": 0.0}
	var move_sig: Dictionary = sig.get("move_ids", {}) as Dictionary
	var move_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}) as Dictionary
	var moves_score: float = 0.0
	for mid in move_counts.keys():
		var w: float = move_sig.get(mid, 0.0)
		if w > 0.0:
			moves_score += float(move_counts[mid]) * w
	var ct_sig: Dictionary = sig.get("contact_types", {}) as Dictionary
	var ct_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_CONTACT_TYPE_COUNTS, {}) as Dictionary
	var ct_score: float = 0.0
	for ct in ct_counts.keys():
		var cw: float = ct_sig.get(ct, 0.0)
		if cw > 0.0:
			ct_score += float(ct_counts[ct]) * cw
	var line_sig: Dictionary = sig.get("lines", {}) as Dictionary
	var line_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}) as Dictionary
	var lines_score: float = 0.0
	for ln in line_counts.keys():
		var lw: float = line_sig.get(ln, 0.0)
		if lw > 0.0:
			lines_score += float(line_counts[ln]) * lw
	var feint_bias: float = sig.get("feint_bias", 0.0)
	var feint_n: int = entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0)
	var feint_score: float = 0.0
	if feint_bias > 0.0 and feint_n > 0:
		feint_score = float(feint_n) * feint_bias
	return {"move_ids": moves_score, "contact_types": ct_score, "lines": lines_score, "feint": feint_score}


static func _detect_form_staleness(entry: Dictionary, weapon: Variant = null) -> bool:
	if entry.is_empty():
		return false
	var recent_lc: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_RECENT_LINE_COUNTS, {}) as Dictionary
	var recent_mc: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_RECENT_MOVE_ID_COUNTS, {}) as Dictionary
	var _all_lc: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}) as Dictionary
	var _all_mc: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}) as Dictionary
	var recent_total: int = 0
	for v in recent_lc.values():
		recent_total += int(v)
	for v in recent_mc.values():
		recent_total += int(v)
	if recent_total < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
		return false
	var recent_best_form: String = ""
	var recent_best_score: float = -1.0
	var all_best_form: String = ""
	var all_best_score: float = -1.0
	## Pre-compute per-form scores once to avoid redundant _per_signal_scores calls.
	var form_recent_scores: Dictionary = {}
	for fid in _form_ids_for_weapon(weapon):
		var recent_lines_score: float = 0.0
		var sig_l: Dictionary = _def(fid, weapon).get("signature", {}).get("lines", {}) as Dictionary
		for ln in recent_lc.keys():
			var wl: float = sig_l.get(ln, 0.0)
			if wl > 0.0:
				recent_lines_score += int(recent_lc[ln]) * wl
		var recent_moves_score: float = 0.0
		var sig_m: Dictionary = _def(fid, weapon).get("signature", {}).get("move_ids", {}) as Dictionary
		for mid in recent_mc.keys():
			var wm: float = sig_m.get(mid, 0.0)
			if wm > 0.0:
				recent_moves_score += int(recent_mc[mid]) * wm
		form_recent_scores[fid] = recent_lines_score + recent_moves_score
		var all_s: float = _signature_score_for_entry(fid, entry, weapon)
		if all_s > all_best_score:
			all_best_score = all_s
			all_best_form = fid
	for fid in form_recent_scores.keys():
		var recent_s: float = form_recent_scores[fid]
		if recent_s > recent_best_score:
			recent_best_score = recent_s
			recent_best_form = fid
	if recent_best_form.is_empty() or all_best_form.is_empty():
		return false
	if recent_best_form == all_best_form:
		return false
	var recent_margin: float = 0.0
	var second_recent: float = -1.0
	for fid in form_recent_scores.keys():
		var s: float = form_recent_scores[fid]
		if s > recent_margin:
			second_recent = recent_margin
			recent_margin = s
	if second_recent < 0.0:
		second_recent = 0.0
	var margin_ratio: float = (recent_margin - second_recent) / maxf(recent_margin, 0.001)
	return margin_ratio >= CombatConstantsMentalStack.WF_FORM_STALENESS_MARGIN_RATIO_THRESHOLD


static func _signal_vote_count(candidate_form: String, entry: Dictionary, weapon: Variant = null) -> int:
	if candidate_form.is_empty() or entry.is_empty():
		return 0
	var vote_categories: Array[String] = ["move_ids", "contact_types", "lines", "feint"]
	var votes: int = 0
	for cat in vote_categories:
		var best_in_cat: String = ""
		var best_cat_score: float = -1.0
		for fid in _form_ids_for_weapon(weapon):
			var scores: Dictionary = _per_signal_scores(fid, entry, weapon)
			var cs: float = scores.get(cat, 0.0)
			if cs > best_cat_score:
				best_cat_score = cs
				best_in_cat = fid
		if best_in_cat == candidate_form and best_cat_score > 0.0:
			votes += 1
	return votes


static func _signature_score_for_entry(form: String, entry: Dictionary, weapon: Variant = null) -> float:
	var sig: Dictionary = _def(form, weapon).get("signature", {}) as Dictionary
	if sig.is_empty() or entry.is_empty():
		return 0.0
	var score: float = 0.0
	var move_sig: Dictionary = sig.get("move_ids", {}) as Dictionary
	var move_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_MOVE_ID_COUNTS, {}) as Dictionary
	for mid in move_counts.keys():
		var w: float = move_sig.get(mid, 0.0)
		if w > 0.0:
			score += float(move_counts[mid]) * w
	var ct_sig: Dictionary = sig.get("contact_types", {}) as Dictionary
	var ct_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_CONTACT_TYPE_COUNTS, {}) as Dictionary
	for ct in ct_counts.keys():
		var cw: float = ct_sig.get(ct, 0.0)
		if cw > 0.0:
			score += float(ct_counts[ct]) * cw
	var line_sig: Dictionary = sig.get("lines", {}) as Dictionary
	var line_counts: Dictionary = entry.get(DataKeys.ATTENTION_ENTRY_LINE_COUNTS, {}) as Dictionary
	for ln in line_counts.keys():
		var lw: float = line_sig.get(ln, 0.0)
		if lw > 0.0:
			score += float(line_counts[ln]) * lw
	var feint_bias: float = sig.get("feint_bias", 0.0)
	var feint_n: int = entry.get(DataKeys.ATTENTION_ENTRY_FEINT_RESOLVED, 0)
	if feint_bias > 0.0 and feint_n > 0:
		score += float(feint_n) * feint_bias
	return score


static func infer_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
	if observer == null or observer.is_empty() or opponent_id < 0:
		return ""
	if not _get_attention().enabled():
		return ""
	var entry: Dictionary = _get_attention().yomi_entry_for_attacker(observer, opponent_id)
	var total_obs: int = _get_attention().yomi_observation_total(entry)
	if total_obs < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
		return ""
	## Phase 0: also require weighted (decay-adjusted) observation threshold to prevent stale inference.
	var total_weighted: float = _get_attention().yomi_weighted_total(entry)
	if total_weighted < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
		return ""
	var opp_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, opponent_id)
	var opp_weapon: Variant = CombatantEntityAccess.get_weapon(opp_c) if not opp_c.is_empty() else null

	_ensure_defs()
	var prior_sum: float = _prior_sum_for_weapon(opp_weapon)
	var best_form: String = ""
	var best_score: float = -1.0
	var second_score: float = -1.0
	for entry_raw_form in _form_ids_for_weapon(opp_weapon):
		var fid: String = str(entry_raw_form)
		var s: float = _signature_score_for_entry(fid, entry, opp_weapon)
		if prior_sum > 0.0 and total_obs > 0:
			s += (CombatConstants.WF_YOMI_FORM_PRIORS.get(fid, 1.0) / prior_sum) * total_obs * 0.3
		if s > best_score:
			second_score = best_score
			best_score = s
			best_form = fid
		elif s > second_score:
			second_score = s
	if best_form.is_empty() or best_score <= 0.0:
		return ""
	if second_score < 0.0:
		second_score = 0.0
	if (best_score - second_score) < CombatConstants.WF_YOMI_FORM_INFERENCE_MARGIN:
		return ""
	var votes: int = _signal_vote_count(best_form, entry, opp_weapon)
	if votes < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_SIGNAL_AGREEMENT:
		return ""
	if _detect_form_staleness(entry, opp_weapon):
		return ""
	return normalize_form(best_form, opp_weapon)


static func get_form_inference_confidence(observer: Dictionary, opponent_id: int, weapon_hint: Variant = null) -> float:
	if observer == null or observer.is_empty() or opponent_id < 0:
		return 0.0
	var entry: Dictionary = _get_attention().yomi_entry_for_attacker(observer, opponent_id)
	var total_obs: int = _get_attention().yomi_observation_total(entry)
	if total_obs == 0:
		return 0.0
	var opp_weapon: Variant = weapon_hint if weapon_hint != null else null
	var obs_score: float = 0.0
	for fid in _form_ids_for_weapon(opp_weapon):
		var s: float = _signature_score_for_entry(fid, entry, opp_weapon)
		if s > obs_score:
			obs_score = s
	var base_confidence: float
	if total_obs <= CombatConstantsEncounter.WF_YOMI_OBS_LOW_THRESHOLD:
		base_confidence = CombatConstantsEncounter.WF_YOMI_OBS_LOW_CONFIDENCE
	elif total_obs <= CombatConstantsEncounter.WF_YOMI_OBS_MED_THRESHOLD:
		base_confidence = CombatConstantsEncounter.WF_YOMI_OBS_MED_CONFIDENCE
	else:
		base_confidence = CombatConstantsEncounter.WF_YOMI_OBS_HIGH_CONFIDENCE
	var margin: float = 0.0
	var second_score: float = -1.0
	var best_score: float = 0.0
	for fid in _form_ids_for_weapon(opp_weapon):
		var s: float = _signature_score_for_entry(fid, entry, opp_weapon)
		if s > best_score:
			second_score = best_score
			best_score = s
		elif s > second_score:
			second_score = s
	if second_score >= 0.0:
		margin = (best_score - second_score) / maxf(best_score, 0.001)
	var margin_boost: float = margin * 0.3
	return clampf(base_confidence + margin_boost, 0.0, 1.0)


## WF-2a: cache inferred opponent forms on observer (waiting-tick refresh).
static func refresh_inferred_forms_for_observer(manager: Node, observer: Dictionary) -> void:
	if observer == null or observer.is_empty() or manager == null:
		return
	if not _get_attention().enabled():
		observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
		return
	var self_side: String = CombatantEntityAccess.side_str(observer)
	var cache: Dictionary = {}
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var oc: Dictionary = other
		if not CombatantEntityAccess.is_alive_in_combat(oc):
			continue
		if CombatantEntityAccess.side_str(oc) == self_side:
			continue
		var oid: int = CombatantEntityAccess.id_int(oc)
		if oid < 0:
			continue
		var inferred: String = infer_opponent_form(manager, observer, oid)
		if not inferred.is_empty():
			cache[str(oid)] = inferred
	if cache.is_empty():
		observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
	else:
		observer[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = cache


## Stance ÃƒÂ¢Ã¢Â€Â ' pressure_class alias (harness compatibility). Production uses **`form_str`** +
## **`CombatWeaponForm.mod`**.
static func _stance_alias_from_pressure(form: String, weapon: Variant = null) -> String:
	match pressure_class(form, weapon):
		"defensive":
			return CombatConstants.STANCE_DEFENSIVE
		"aggressive":
			return CombatConstants.STANCE_AGGRESSIVE
		"controlling":
			return CombatConstants.STANCE_CONTROLLING
		_:
			return CombatConstants.STANCE_BALANCED


static func _side_encounter_default_form(manager: Node, c: Dictionary) -> String:
	if manager == null or not ("encounter" in manager):
		return ""
	var enc: Dictionary = manager.encounter if manager.encounter is Dictionary else {}
	var side: String = CombatantEntityAccess.side_str(c)
	var key: String = (
		CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM
		if side == CombatConstants.SIDE_PLAYER
		else CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM
	)
	return str(enc.get(key, "")).strip_edges()


## L2 ÃƒÂ¢Ã¢Â€Â ' L3 home write site: sets **`weapon_form`**, stance alias (harness compatibility), home
## **`guard_line`** â€”" does **not** stamp/clear PA. Contract: LIVE_PATHS **`#wf-assign-form-contract`**.
static func assign_form(manager: Node, c: Dictionary, form: String, reason: String = "") -> void:
	var weapon = CombatantEntityAccess.get_weapon(c)
	var resolved: String = normalize_form(form, weapon)
	if not form_allowed_for_weapon(resolved, weapon):
		resolved = default_form_for_weapon(weapon)
	var old_form: String = CombatantEntityAccess.form_str(c)
	c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = resolved
	c[DataKeys.COMBATANT_STANCE] = _stance_alias_from_pressure(resolved, weapon)
	if old_form != resolved and reason not in ["spawn", "harness_baseline"]:
		c[CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON] = reason
	GuardLineUpdater.set_guard_from_line(c, home_guard_line(resolved, weapon))
	if manager != null and not reason.is_empty() and CombatConstants.combat_event_debug_active():
		CombatDebug.flow_log(
			"form_switch id=%d form=%s reason=%s" % [CombatantEntityAccess.id_int(c), resolved, reason]
		)
	if (
		old_form != resolved
		and reason not in ["spawn", "harness_baseline"]
		and CombatConstants.WF_FORM_SWITCH_STAMINA_COST > 0.0
	):
		c[DataKeys.COMBATANT_STAMINA] = maxf(0.0, CombatantEntityAccess.stamina_float(c) - CombatConstants.WF_FORM_SWITCH_STAMINA_COST)
	if manager != null and old_form != resolved and reason not in ["spawn", "harness_baseline"]:
		if OperationalLog.is_play_session_active():
			(
				OperationalLog
				. play_combat(
					(
                        "form_switch id=%d %s %sÃƒÂ¢Ã¢Â€Â '%s reason=%s"
						% [
							CombatantEntityAccess.id_int(c),
							CombatantEntityAccess.get_display_name(c, CombatantEntityAccess.id_int(c)),
							old_form,
							resolved,
							reason,
						]
					)
				)
			)


## Spawn path entry: resolve form from overlay ÃƒÂ¢Ã¢Â€Â ' encounter ÃƒÂ¢Ã¢Â€Â ' **`stance_preference`** ÃƒÂ¢Ã¢Â€Â '
## weapon default ÃƒÂ¢Ã¢Â€Â ' **`assign_form(..., "spawn")`**. LIVE_PATHS **`#spawn--reset-path-wf-1a`**.
static func seed_combatant_form(manager: Node, c: Dictionary, spawn_overlay: Dictionary = {}) -> void:
	var weapon = CombatantEntityAccess.get_weapon(c)
	var raw: String = spawn_overlay.get(DataKeys.PA_WEAPON_FORM, "").strip_edges()
	if raw.is_empty():
		raw = _side_encounter_default_form(manager, c)
	if raw.is_empty():
		raw = c.get(DataKeys.STANCE_PREFERENCE, "").strip_edges()
	var form: String
	if raw.is_empty():
		form = default_form_for_weapon(weapon)
	else:
		form = normalize_form(raw, weapon)
		if not form_allowed_for_weapon(form, weapon):
			form = default_form_for_weapon(weapon)
	assign_form(manager, c, form, "spawn")


static func _stamp_form_switch_cooldown(c: Dictionary, clk: float) -> void:
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL] = (clk + CombatConstants.WF_FORM_SWITCH_COOLDOWN_S)


static func _inferred_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
	if opponent_id < 0:
		return ""
	var cache_raw: Variant = observer.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
	if cache_raw is Dictionary:
		var cached: String = (cache_raw as Dictionary).get(str(opponent_id), "").strip_edges()
		if not cached.is_empty():
			return cached
	return infer_opponent_form(manager, observer, opponent_id)


static func _primary_melee_threat_id(manager: Node, c: Dictionary) -> int:
	if manager == null or c.is_empty():
		return -1
	var engaged: int = c.get(DataKeys.COMBATANT_ENGAGED_WITH_ID, -1)
	if engaged >= 0:
		var engaged_c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, engaged)
		if not engaged_c.is_empty() and CombatantEntityAccess.is_living_hostile_to(c, engaged_c):
			return engaged
	var sole_id: int = -1
	var count: int = 0
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var oc: Dictionary = other
		if not CombatantEntityAccess.is_living_hostile_to(c, oc):
			continue
		var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, oc, c)
		if not CombatMeleeListing.can_melee_threaten(manager, oc, c, pair_geom):
			continue
		count += 1
		sole_id = CombatantEntityAccess.id_int(oc)
	if count == 1:
		return sole_id
	return -1


static func _is_isolated_duel(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var scan: Dictionary = CombatWeaponForm._get_tactical_combat().surround_threat_scan_for_defender(manager, c)
	if scan.get(DataKeys.SCAN_COUNT, 0) != 1:
		return false
	var wsum: float = scan.get("weight_sum", 0.0)
	if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD:
		return false
	if scan.get("arc_occupancy_blocked", 0) > 0:
		return false
	return _primary_melee_threat_id(manager, c) >= 0


static func _surround_pressure_high(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var scan: Dictionary = CombatWeaponForm._get_tactical_combat().surround_threat_scan_for_defender(manager, c)
	if scan.get(DataKeys.SCAN_COUNT, 0) >= 2:
		return true
	var wsum: float = scan.get("weight_sum", 0.0)
	return wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD


static func _surround_form_for_weapon(weapon: Variant) -> String:
	var wall: String = _defensive_form_for_weapon(weapon)
	if not wall.is_empty():
		return wall
	if form_allowed_for_weapon(FORM_TEMPEST, weapon):
		return FORM_TEMPEST
	for fid in _form_ids_for_weapon(weapon):
		if pressure_class_is(str(fid), "controlling", weapon):
			return normalize_form(str(fid), weapon)
	return ""


static func _preferred_aggressive_duel_form(weapon: Variant) -> String:
	var ids: PackedStringArray = _duel_offense_form_ids(weapon)
	for fid in ids:
		if pressure_class_is(fid, "aggressive", weapon):
			return normalize_form(fid, weapon)
	if ids.size() > 0:
		return normalize_form(ids[0], weapon)
	return ""


static func _duel_demote_form(weapon: Variant, cur: String) -> String:
	for fid in _duel_offense_form_ids(weapon):
		if fid == cur:
			continue
		if not pressure_class_is(fid, "aggressive", weapon):
			return normalize_form(fid, weapon)
	return ""


static func _duel_form_from_yomi_and_stamina(
	cur: String, inferred: String, stamina_ratio: float, min_stamina: float, weapon: Variant = null
) -> String:
	var def_form: String = _defensive_form_for_weapon(weapon)
	var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
	var promote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD
	var demote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD
	if not def_form.is_empty() and cur == def_form and stamina_ratio < min_stamina + offense_pad:
		return ""
	if not inferred.is_empty():
		var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
		if not counter.is_empty() and counter != cur:
			return counter
	var agg: String = _preferred_aggressive_duel_form(weapon)
	if (
		not agg.is_empty()
		and stamina_ratio >= min_stamina + promote_pad
		and cur != agg
		and not pressure_class_is(cur, "aggressive", weapon)
	):
		return agg
	if pressure_class_is(cur, "aggressive", weapon) and stamina_ratio < min_stamina + demote_pad:
		var demote: String = _duel_demote_form(weapon, cur)
		if not demote.is_empty() and demote != cur:
			return demote
	return ""


static func _counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
	if inferred_opp.is_empty():
		return ""
	_ensure_defs()
	var best_form: String = ""
	var best_mult: float = 1.0
	for entry_raw_form in _form_ids_for_weapon(weapon):
		var fid: String = normalize_form(str(entry_raw_form), weapon)
		if not form_allowed_for_weapon(fid, weapon):
			continue
		var mult: float = _counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
		if mult > best_mult:
			best_mult = mult
			best_form = fid
	if best_mult <= 1.0 or best_form.is_empty():
		return ""
	return best_form


## Isolated duel: counter-read only among offensive duel forms (not wall/tempest).
static func _duel_counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
	if inferred_opp.is_empty():
		return ""
	var best_form: String = ""
	var best_mult: float = 1.0
	for fid_raw in _duel_offense_form_ids(weapon):
		var fid: String = normalize_form(fid_raw, weapon)
		if not form_allowed_for_weapon(fid, weapon):
			continue
		var mult: float = _counter_spec_for_inferred(fid, inferred_opp, weapon).get("mult", 1.0)
		if mult > best_mult:
			best_mult = mult
			best_form = fid
	if best_mult <= 1.0 or best_form.is_empty():
		return ""
	return best_form


static func _try_assign_auto_switch(
	manager: Node, c: Dictionary, next_form: String, reason: String, clk: float, confidence: float = 1.0
) -> bool:
	var next: String = next_form.strip_edges()
	if next.is_empty() or next == CombatantEntityAccess.form_str(c):
		return false
	if reason in ["counter_read", "duel_read"] and confidence < 0.35:
		return false
	var weapon = CombatantEntityAccess.get_weapon(c)
	if not form_allowed_for_weapon(next, weapon):
		return false
	## Phase 2: pressure-distance confidence gating for counter-read / duel-read switches.
	var is_yomi_gated: bool = reason in ["counter_read", "duel_read"]
	if is_yomi_gated:
		var my_pc: String = pressure_class(CombatantEntityAccess.form_str(c), weapon)
		var next_pc: String = pressure_class(next, weapon)
		if my_pc != next_pc:
			var min_conf: float = 1.0
			if my_pc == "neutral" and next_pc == "aggressive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_AGGRESSIVE_MIN_CONFIDENCE
			elif my_pc == "aggressive" and next_pc == "defensive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_DEFENSIVE_MIN_CONFIDENCE
			elif my_pc == "neutral" and next_pc == "defensive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_DEFENSIVE_MIN_CONFIDENCE
			elif my_pc == "neutral" and next_pc == "controlling":
				min_conf = CombatConstantsEncounter.COUNTER_READ_NEUTRAL_TO_CONTROLLING_MIN_CONFIDENCE
			elif my_pc == "aggressive" and next_pc == "controlling":
				min_conf = CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_CONTROLLING_MIN_CONFIDENCE
			elif my_pc == "controlling" and next_pc == "aggressive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_AGGRESSIVE_MIN_CONFIDENCE
			elif my_pc == "controlling" and next_pc == "defensive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_DEFENSIVE_MIN_CONFIDENCE
			elif my_pc == "controlling" and next_pc == "neutral":
				min_conf = CombatConstantsEncounter.COUNTER_READ_CONTROLLING_TO_NEUTRAL_MIN_CONFIDENCE
			elif my_pc == "defensive" and next_pc == "aggressive":
				min_conf = CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_AGGRESSIVE_MIN_CONFIDENCE
			elif my_pc == "defensive" and next_pc == "controlling":
				min_conf = CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_CONTROLLING_MIN_CONFIDENCE
			elif my_pc == "defensive" and next_pc == "neutral":
				min_conf = CombatConstantsEncounter.COUNTER_READ_DEFENSIVE_TO_NEUTRAL_MIN_CONFIDENCE
			elif my_pc == "aggressive" and next_pc == "neutral":
				min_conf = CombatConstantsEncounter.COUNTER_READ_AGGRESSIVE_TO_NEUTRAL_MIN_CONFIDENCE
			if confidence < min_conf:
				return false
		## Phase 2 penalty hard-gate: deny counter-read switches when overcommitted (2+ wrong reads in last 5).
		var recent_wrong: int = count_recent_wrong_readings(c)
		if reason == "counter_read" and recent_wrong >= 2:
			return false
	## C3: Route through form switch wind-up instead of instant assign.
	var switched: bool = CombatFormSwitch.start(manager, c, next, reason)
	if not switched:
		return false
	_stamp_form_switch_cooldown(c, clk)
	## Phase 2: stamp counter-read commitment on successful defensive/counter switch.
	if reason in ["counter_read", "duel_read"]:
		var my_pc2: String = pressure_class(CombatantEntityAccess.form_str(c), weapon)
		var next_pc2: String = pressure_class(next, weapon)
		if my_pc2 != next_pc2 and next_pc2 == "defensive":
			c[CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL] = clk + \
				CombatConstantsEncounter.COUNTER_READ_COMMITMENT_DURATION_TICKS
	return true


## D3: Check if armor doctrine form (half_sword/mordhau) should be activated based on opponent armor tier.
static func _try_doctrine_auto_switch(manager: Node, c: Dictionary, clk: float) -> bool:
	var threat_id: int = _primary_melee_threat_id(manager, c)
	if threat_id < 0:
		return false
	var weapon = CombatantEntityAccess.get_weapon(c)
	var cur_form: String = CombatantEntityAccess.form_str(c)
	if CombatArmorDoctrine.is_doctrine_form(cur_form):
		return false
	var threat: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, threat_id)
	if threat.is_empty():
		return false
	var opp_tier: String = CombatArmorDoctrine.classify_tier(threat)
	if opp_tier not in [CombatArmorDoctrine.TIER_MEDIUM, CombatArmorDoctrine.TIER_HEAVY]:
		return false
	var doctr_form: String = CombatArmorDoctrine.recommended_form_for_tier(opp_tier)
	if doctr_form.is_empty() or not form_allowed_for_weapon(doctr_form, weapon):
		return false
	var cur_pc: String = pressure_class(cur_form, weapon)
	if cur_pc == "defensive":
		return false
	var ratio: float = CombatantEntityAccess.stamina_ratio(c)
	if ratio < min_stamina_ratio_for_form(cur_form, weapon):
		return false
	return _try_assign_auto_switch(manager, c, doctr_form, "armor_doctrine", clk)


## WF-3 auto-switch hook â€" calls **`assign_form`** only; does **not** stamp/clear PA. Caller:
## **`CombatAIActionPicker.pick`** after mental-stack miss. LIVE_PATHS **`#wf-pick-vs-strike`** Â·
## **`#wf-assign-form-contract`**.
static func evaluate_automatic_form(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var clk: float = CombatantEntityAccess.combat_clock_float(manager)
	var until: float = float(c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL, 0.0))
	if until > clk:
		return false
	## Phase 2: honor counter-read commitment window — no auto-switch during defensive lock.
	var commit_until: Variant = c.get(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL, null)
	if commit_until != null and float(commit_until) > clk:
		return false
	elif commit_until != null:
		c.erase(CombatConstantsEncounter.COMBATANT_KEY_COUNTER_READ_COMMITTED_UNTIL)
		c.erase(DataKeys.PA_OVERCOMMIT_PARRY_MULT)
	var cur: String = CombatantEntityAccess.form_str(c)
	var ratio: float = CombatantEntityAccess.stamina_ratio(c)
	var weapon = CombatantEntityAccess.get_weapon(c)
	var min_r: float = min_stamina_ratio_for_form(cur, weapon)
	var def_form: String = _defensive_form_for_weapon(weapon)
	var envelop: bool = CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(c))
	if ratio < min_r and not def_form.is_empty() and cur != def_form and not envelop:
		return _try_assign_auto_switch(manager, c, def_form, "low_stamina", clk)
	if not envelop:
		if _surround_pressure_high(manager, c):
			var sur_form: String = _surround_form_for_weapon(weapon)
			if _try_assign_auto_switch(manager, c, sur_form, "surround_pressure", clk):
				return true
	if CombatMobilityRetreat.cannot_commit_melee(c):
		return false
	if _is_isolated_duel(manager, c):
		var duel_id: int = _primary_melee_threat_id(manager, c)
		if duel_id >= 0:
			var inferred: String = _inferred_opponent_form(manager, c, duel_id)
			var confidence: float = get_form_inference_confidence(c, duel_id, weapon)
			var cache_raw: Variant = c.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
			if inferred != "" and cache_raw is Dictionary:
				var cached_val: String = str(cache_raw.get(str(duel_id), "")).strip_edges()
				if not cached_val.is_empty():
					var entry: Dictionary = _get_attention().yomi_entry_for_attacker(c, duel_id)
					if _get_attention().yomi_observation_total(entry) == 0:
						confidence = minf(confidence, CombatConstantsEncounter.COUNTER_READ_MIN_CONFIDENCE_NO_OBSERVATIONS)
			var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
			var can_offense: bool = not (not def_form.is_empty() and cur == def_form and ratio < min_r + offense_pad)
			if can_offense and not _is_form_stale_for_opponent(manager, c, duel_id):
				var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
				if not counter.is_empty() and not _should_bait_counter_read(manager, c, duel_id):
					if _try_assign_auto_switch(manager, c, counter, "counter_read", clk, confidence):
						return true
			var duel_next: String = _duel_form_from_yomi_and_stamina(cur, inferred, ratio, min_r, weapon)
			if not duel_next.is_empty() and not _is_form_stale_for_opponent(manager, c, duel_id):
				var is_counter_via_duel: bool = not inferred.is_empty() and \
					_duel_counter_form_vs_inferred(weapon, inferred) == duel_next
				if is_counter_via_duel:
					if _try_assign_auto_switch(manager, c, duel_next, "counter_read", clk, confidence):
						return true
				else:
					if _try_assign_auto_switch(manager, c, duel_next, "duel_read_stamina", clk):
						return true
	var threat_id: int = _primary_melee_threat_id(manager, c)
	if threat_id >= 0 and not _is_form_stale_for_opponent(manager, c, threat_id):
		var offense_pad_fb: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
		if not (not def_form.is_empty() and cur == def_form and ratio < min_r + offense_pad_fb):
			var inferred_opp: String = _inferred_opponent_form(manager, c, threat_id)
			var counter: String = _counter_form_vs_inferred(weapon, inferred_opp)
			var confidence: float = get_form_inference_confidence(c, threat_id, weapon)
			var cache_raw2: Variant = c.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
			if inferred_opp != "" and cache_raw2 is Dictionary:
				var cached_val2: String = str(cache_raw2.get(str(threat_id), "")).strip_edges()
				if not cached_val2.is_empty():
					var entry2: Dictionary = _get_attention().yomi_entry_for_attacker(c, threat_id)
					if _get_attention().yomi_observation_total(entry2) == 0:
						confidence = minf(confidence, CombatConstantsEncounter.COUNTER_READ_MIN_CONFIDENCE_NO_OBSERVATIONS)
			if not counter.is_empty() and not _should_bait_counter_read(manager, c, threat_id):
				if _try_assign_auto_switch(manager, c, counter, "counter_read", clk, confidence):
					return true
	# D3: Armor doctrine auto-switch — recommend half_sword/mordhau vs heavily armored opponents.
	var did_doctr_switch: bool = _try_doctrine_auto_switch(manager, c, clk)
	if did_doctr_switch:
		return true
	return false
