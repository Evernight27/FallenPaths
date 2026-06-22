class_name CombatWeaponForm
extends RefCounted

## Per-fighter weapon form defs: temperament mods, move-family weights, pressure class, home guard, auto-switch.
## Read order: FORM_DEFS → normalize → seed → mod/action_weight_mult → pressure → evaluate_automatic_form.
## Canonical: CombatantEntityAccess.form_str · mod · action_weight_mult · home_guard_line · evaluate_automatic_form.
## Footing: assign_form → home guard_line only (LIVE_PATHS **`#wf-assign-form-contract`**); picker uses form weights only — **`#wf-pick-vs-strike`**. Tier 4.4 PA: **`CombatFootwork`** — hub **`#wf-tier-44-pa`**. **`#wf-footing-guards-stances`** · **`#wf-form-guard-pa-matrix`**.
## Manager requires: combatants, encounter, combat_clock (auto-switch cooldown only).

const _Attention := preload("res://combat/CombatAttention.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _GuardLineUpdater := preload("res://combat/GuardLineUpdater.gd")
const _MeleeListing := preload("res://combat/CombatMeleeListing.gd")
const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
const _PairGeometry := preload("res://combat/CombatPairGeometry.gd")
const _TacticalCombat := preload("res://combat/TacticalCombat.gd")
const _WeaponConstants := preload("res://weapon/WeaponConstants.gd")
const _CombatDoctrine := preload("res://combat/CombatDoctrine.gd")

const FORM_OX := "ox"
const FORM_PLOW := "plow"
const FORM_WRATH := "wrath"
const FORM_FOOL := "fool"
const FORM_WALL := "wall"
const FORM_TEMPEST := "tempest"
const FORM_BALANCED := "balanced"

const _MOD_EFFECTS: Array[String] = [
	"parry",
	"evasion",
	"damage",
	"close_attempt",
	"ai_melee_focus",
	"feint_readthrough",
	"ai_feint_listing",
]

static var _FORM_DEFS: Dictionary = {}


static func _ensure_defs() -> void:
	if not _FORM_DEFS.is_empty():
		return
	_FORM_DEFS = {
		FORM_WALL: {
			"display_name": "Wall",
			"home_guard": "high",
			"preferred_guards": PackedStringArray(["high", "high_right", "high_left"]),
			"pressure_class": "defensive",
			"min_stamina_ratio": 0.18,
			"wait_weight_mult": 1.35,
			"mod": {
				"parry": 1.2,
				"evasion": 1.15,
				"damage": 0.85,
				"close_attempt": 0.9,
				"ai_melee_focus": 0.92,
				"feint_readthrough": 1.06,
				"ai_feint_listing": 0.94,
			},
			"move_family_mult": {
				"thrust": 1.0,
				"high_cut": 0.88,
				"low_cut": 0.9,
				"slash": 0.75,
				"feint": 0.8,
				"parry": 1.15,
				"close": 0.85,
			},
			"signature": {
				"move_ids": {"thrust": 0.85, "oberhau": 0.7},
				"contact_types": {"stab": 0.9, "cut": 0.75},
				"lines": {"high": 1.0, "high_right": 0.85},
				"feint_bias": 0.35,
			},
			"counters": {
				FORM_WRATH: {"mult": 1.1, "families": ["parry", "feint"]},
				FORM_TEMPEST: {"mult": 1.08, "families": ["parry"]},
			},
		},
		FORM_BALANCED: {
			"display_name": "Balanced",
			"home_guard": "high",
			"preferred_guards": PackedStringArray(["high"]),
			"pressure_class": "neutral",
			"min_stamina_ratio": 0.22,
			"wait_weight_mult": 1.0,
			"mod": _neutral_mod(),
			"move_family_mult": {},
			"signature": {
				"move_ids": {},
				"contact_types": {},
				"lines": {"high": 0.35},
				"feint_bias": 0.1,
			},
		},
		FORM_WRATH: {
			"display_name": "Wrath",
			"home_guard": "high_left",
			"preferred_guards": PackedStringArray(["high_left", "high_right"]),
			"pressure_class": "aggressive",
			"min_stamina_ratio": 0.28,
			"wait_weight_mult": 0.85,
			"mod": {
				"parry": 0.8,
				"evasion": 0.85,
				"damage": 1.2,
				"close_attempt": 1.1,
				"ai_melee_focus": 1.1,
				"feint_readthrough": 0.95,
				"ai_feint_listing": 1.02,
			},
			"move_family_mult": {
				"thrust": 0.9,
				"high_cut": 1.18,
				"low_cut": 1.05,
				"slash": 1.08,
				"feint": 1.0,
				"parry": 0.92,
				"close": 1.1,
			},
			"signature": {
				"move_ids": {"oberhau": 1.2, "slash": 1.0, "unterhau": 0.85, "quick_slash": 0.9},
				"contact_types": {"cut": 1.0},
				"lines": {"high": 0.9, "high_left": 0.75, "high_right": 0.7},
				"feint_bias": 0.12,
			},
			"counters": {
				FORM_PLOW: {"mult": 1.1, "families": ["high_cut", "slash"]},
				FORM_FOOL: {"mult": 1.06, "families": ["high_cut"]},
			},
		},
		FORM_FOOL: {
			"display_name": "Fool",
			"home_guard": "low_left",
			"preferred_guards": PackedStringArray(["low_left", "low"]),
			"pressure_class": "controlling",
			"min_stamina_ratio": 0.24,
			"wait_weight_mult": 0.95,
			"mod": {
				"parry": 1.0,
				"evasion": 1.0,
				"damage": 0.95,
				"close_attempt": 1.0,
				"ai_melee_focus": 0.98,
				"feint_readthrough": 1.04,
				"ai_feint_listing": 1.06,
			},
			"move_family_mult": {
				"thrust": 0.95,
				"high_cut": 0.92,
				"low_cut": 1.1,
				"slash": 0.95,
				"feint": 1.25,
				"parry": 1.02,
				"close": 1.0,
			},
			"signature": {
				"move_ids": {"oberhau_feint": 1.25, "thrust_feint": 1.2, "unterhau_feint": 1.1},
				"contact_types": {"cut": 0.55},
				"lines": {"low": 0.75, "low_left": 0.85},
				"feint_bias": 1.45,
			},
			"counters": {
				FORM_OX: {"mult": 1.12, "families": ["feint", "thrust", "low_cut"]},
				FORM_WRATH: {"mult": 1.06, "families": ["feint"]},
			},
		},
		FORM_OX: {
			"display_name": "Ox",
			"home_guard": "high_right",
			"preferred_guards": PackedStringArray(["high_right", "high"]),
			"pressure_class": "neutral",
			"min_stamina_ratio": 0.2,
			"wait_weight_mult": 1.0,
			"mod": {
				"parry": 1.08,
				"evasion": 1.04,
				"damage": 1.04,
				"close_attempt": 1.0,
				"ai_melee_focus": 1.02,
				"feint_readthrough": 1.02,
				"ai_feint_listing": 0.98,
			},
			"move_family_mult": {
				"thrust": 1.15,
				"high_cut": 0.95,
				"low_cut": 0.85,
				"slash": 0.95,
				"feint": 0.95,
				"parry": 1.08,
				"close": 1.0,
			},
			"signature": {
				"move_ids": {"thrust": 1.25, "spear_thrust": 1.15, "oberhau": 0.65},
				"contact_types": {"stab": 1.2, "cut": 0.55},
				"lines": {"high_right": 0.85, "high": 0.65},
				"feint_bias": 0.08,
			},
			"counters": {
				FORM_FOOL: {"mult": 1.1, "families": ["thrust"]},
				FORM_TEMPEST: {"mult": 1.08, "families": ["thrust", "parry"]},
			},
		},
		FORM_PLOW: {
			"display_name": "Plow",
			"home_guard": "low",
			"preferred_guards": PackedStringArray(["low", "high"]),
			"pressure_class": "neutral",
			"min_stamina_ratio": 0.22,
			"wait_weight_mult": 1.0,
			"mod": {
				"parry": 1.14,
				"evasion": 1.06,
				"damage": 0.96,
				"close_attempt": 0.94,
				"ai_melee_focus": 0.94,
				"feint_readthrough": 1.04,
				"ai_feint_listing": 0.96,
			},
			"move_family_mult": {
				"thrust": 1.2,
				"high_cut": 0.88,
				"low_cut": 0.95,
				"slash": 0.9,
				"feint": 0.92,
				"parry": 1.1,
				"close": 0.95,
			},
			"signature": {
				"move_ids": {"thrust": 1.3, "spear_thrust": 1.2},
				"contact_types": {"stab": 1.25},
				"lines": {"low": 0.8, "high": 0.55},
				"feint_bias": 0.06,
			},
			"counters": {
				FORM_WRATH: {"mult": 1.08, "families": ["thrust", "high_cut"]},
			},
		},
		FORM_TEMPEST: {
			"display_name": "Tempest",
			"home_guard": "left",
			"preferred_guards": PackedStringArray(["left", "right"]),
			"pressure_class": "aggressive",
			"min_stamina_ratio": 0.26,
			"wait_weight_mult": 0.9,
			"mod": {
				"parry": 0.84,
				"evasion": 0.88,
				"damage": 1.18,
				"close_attempt": 1.08,
				"ai_melee_focus": 1.08,
				"feint_readthrough": 0.94,
				"ai_feint_listing": 1.04,
			},
			"move_family_mult": {
				"thrust": 0.92,
				"high_cut": 1.12,
				"low_cut": 1.0,
				"slash": 1.2,
				"feint": 1.05,
				"parry": 0.9,
				"close": 1.05,
			},
			"signature": {
				"move_ids": {"slash": 1.2, "quick_slash": 1.15, "oberhau": 0.95},
				"contact_types": {"cut": 1.05},
				"lines": {"left": 0.85, "right": 0.85, "high": 0.6},
				"feint_bias": 0.18,
			},
			"counters": {
				FORM_WALL: {"mult": 1.1, "families": ["slash", "high_cut"]},
				FORM_OX: {"mult": 1.06, "families": ["slash"]},
			},
		},
	}


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


static func _def(form: String) -> Dictionary:
	_ensure_defs()
	return _FORM_DEFS.get(normalize_form(form), _FORM_DEFS[FORM_BALANCED]) as Dictionary


static func normalize_form(raw: String) -> String:
	var s: String = str(raw).strip_edges().to_lower()
	match s:
		"defensive", FORM_WALL:
			return FORM_WALL
		"aggressive", FORM_WRATH:
			return FORM_WRATH
		"controlling", FORM_FOOL:
			return FORM_FOOL
		FORM_OX, FORM_PLOW, FORM_TEMPEST, FORM_BALANCED:
			return s
		_:
			return FORM_BALANCED


static func form_allowed_for_weapon(form: String, weapon: Variant) -> bool:
	var fid: String = normalize_form(form)
	var allowed: Array = _WeaponConstants.allowed_forms_for_weapon(weapon)
	return allowed.is_empty() or fid in allowed


static func default_form_for_weapon(weapon: Variant) -> String:
	return normalize_form(_WeaponConstants.default_form_for_weapon(weapon))


static func home_guard_line(form: String) -> String:
	var d: Dictionary = _def(form)
	return str(d.get("home_guard", CombatConstants.GUARD_DEFAULT))


static func preferred_guards(form: String) -> PackedStringArray:
	var d: Dictionary = _def(form)
	var raw: Variant = d.get("preferred_guards", PackedStringArray())
	if raw is PackedStringArray:
		return raw
	return PackedStringArray()


static func mod(form: String, effect: String) -> float:
	var d: Dictionary = _def(form)
	var m: Dictionary = d.get("mod", {}) as Dictionary
	return float(m.get(effect, 1.0))


static func display_name(form: String) -> String:
	return str(_def(form).get("display_name", "Balanced"))


static func form_ai_targeting_mult(actor: Dictionary) -> float:
	if actor.is_empty():
		return 1.0
	return mod(_EntityAccess.form_str(actor), "ai_melee_focus")


static func pressure_class(form: String) -> String:
	return str(_def(form).get("pressure_class", "neutral"))


static func pressure_class_is(form: String, class_id: String) -> bool:
	return pressure_class(form) == str(class_id).strip_edges().to_lower()


static func controlling_pressure_active(c: Dictionary) -> bool:
	if c.is_empty():
		return false
	var form: String = _EntityAccess.form_str(c)
	if not pressure_class_is(form, "controlling"):
		return false
	return (
		_EntityAccess.stamina_ratio(c)
		>= CombatConstants.STANCE_MIN_STAMINA_CONTROLLING_RATIO
	)


## Live pressure tag for UI — suppress **`controlling`** when the stamina gate is down.
static func pressure_class_label_for_ui(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	var pressure: String = pressure_class(_EntityAccess.form_str(c))
	if pressure.is_empty() or pressure == "neutral":
		return ""
	if pressure == "controlling" and not controlling_pressure_active(c):
		return ""
	return pressure


static func opponent_close_evasion_divisor(form: String) -> float:
	if pressure_class_is(form, "controlling"):
		return CombatConstants.STANCE_MOD_OPPONENT_CLOSE
	return 1.0


## Controlling pressure slows opponent formation disengage (fall_back / swap duration). LIVE_PATHS **`#wf-footing-improvement-backlog`** — pairs with **`STANCE_MOD_OPPONENT_DISENGAGE`**.
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
	return opponent_close_listing_weight_mult(_EntityAccess.form_str(c))


static func min_stamina_ratio_for_form(form: String) -> float:
	return float(_def(form).get("min_stamina_ratio", 0.22))


static func wait_action_weight_mult(form: String) -> float:
	return float(_def(form).get("wait_weight_mult", 1.0))


static func _move_family_for_move_id(move_id: String) -> String:
	if move_id == CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
		return "close"
	if _WeaponConstants.is_feint_move(move_id):
		return "feint"
	if _WeaponConstants.is_parry_move(move_id):
		return "parry"
	var ct: String = _WeaponConstants.contact_type_for_move_id(move_id)
	if ct == _WeaponConstants.ATTACK_TYPE_STAB:
		return "thrust"
	var md: Dictionary = _WeaponConstants.get_move(move_id)
	var arch: String = str(md.get("archetype_id", ""))
	var line: String = str(md.get("attack_line", ""))
	if arch == _WeaponConstants.ARCHETYPE_QUICK_SLASH or move_id == "slash" or move_id == "quick_slash":
		return "slash"
	if line.begins_with("low") or move_id == "unterhau":
		return "low_cut"
	if ct == _WeaponConstants.ATTACK_TYPE_CUT or ct == _WeaponConstants.ATTACK_TYPE_BLUNT:
		return "high_cut"
	return ""


static func action_weight_mult(form: String, move_id: String) -> float:
	var family: String = _move_family_for_move_id(move_id)
	if family.is_empty():
		return 1.0
	var d: Dictionary = _def(form)
	var fam: Dictionary = d.get("move_family_mult", {}) as Dictionary
	return float(fam.get(family, 1.0))


static func wind_up_transition_mult(
	form: String, _move_id: String, guard_line: String, attack_line: String
) -> float:
	var home: String = home_guard_line(form)
	if home.is_empty() or attack_line.is_empty():
		return 1.0
	if guard_line == home and attack_line == home:
		return 0.88
	for pg in preferred_guards(form):
		if pg == attack_line and (guard_line == pg or guard_line == home):
			return 0.92
	return 1.0


static func _counter_spec_for_inferred(my_form: String, inferred_opp: String) -> Dictionary:
	var opp: String = normalize_form(inferred_opp)
	if opp.is_empty():
		return {"mult": 1.0, "families": PackedStringArray()}
	var raw: Variant = (_def(my_form).get("counters", {}) as Dictionary).get(opp, null)
	if raw is float or raw is int:
		return {"mult": float(raw), "families": PackedStringArray()}
	if raw is Dictionary:
		return {
			"mult": float((raw as Dictionary).get("mult", 1.0)),
			"families": _coerce_string_array((raw as Dictionary).get("families", [])),
		}
	return {"mult": 1.0, "families": PackedStringArray()}


static func _coerce_string_array(raw: Variant) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if raw is PackedStringArray:
		return raw as PackedStringArray
	if raw is Array:
		for item in raw as Array:
			var s: String = str(item).strip_edges()
			if not s.is_empty():
				out.append(s)
	return out


## WF-2b: picker boost when **`my_form`** counters inferred opponent habit for this **`move_id`** family.
static func form_counter_mult(my_form: String, inferred_opp_form: String, move_id: String) -> float:
	if inferred_opp_form.is_empty() or move_id.is_empty():
		return 1.0
	var spec: Dictionary = _counter_spec_for_inferred(normalize_form(my_form), inferred_opp_form)
	var mult: float = float(spec.get("mult", 1.0))
	if mult <= 1.0:
		return 1.0
	var families: PackedStringArray = _coerce_string_array(spec.get("families", []))
	if not families.is_empty():
		var family: String = _move_family_for_move_id(move_id)
		if family.is_empty() or family not in families:
			return 1.0
	return minf(mult, CombatConstants.WF_FORM_COUNTER_MULT_CAP)


## WF-2b: optional defense bump when defender form counters inferred attacker form.
static func counter_readiness_nudge(my_form: String, inferred_opp_form: String) -> float:
	if inferred_opp_form.is_empty():
		return 0.0
	var mult: float = float(_counter_spec_for_inferred(normalize_form(my_form), inferred_opp_form).get("mult", 1.0))
	if mult <= 1.0:
		return 0.0
	var t: float = clampf(
		(mult - 1.0) / maxf(0.001, CombatConstants.WF_FORM_COUNTER_MULT_CAP - 1.0),
		0.0,
		1.0
	)
	return lerpf(
		CombatConstants.WF_COUNTER_READINESS_NUDGE_MIN,
		CombatConstants.WF_COUNTER_READINESS_NUDGE_MAX,
		t
	)


static func _signature_score_for_entry(form: String, entry: Dictionary) -> float:
	var sig: Dictionary = _def(form).get("signature", {}) as Dictionary
	if sig.is_empty() or entry.is_empty():
		return 0.0
	var score: float = 0.0
	var move_sig: Dictionary = sig.get("move_ids", {}) as Dictionary
	var move_counts: Dictionary = entry.get("move_id_counts", {}) as Dictionary
	for mid in move_counts.keys():
		var w: float = float(move_sig.get(mid, 0.0))
		if w > 0.0:
			score += float(move_counts[mid]) * w
	var ct_sig: Dictionary = sig.get("contact_types", {}) as Dictionary
	var ct_counts: Dictionary = entry.get("contact_type_counts", {}) as Dictionary
	for ct in ct_counts.keys():
		var cw: float = float(ct_sig.get(ct, 0.0))
		if cw > 0.0:
			score += float(ct_counts[ct]) * cw
	var line_sig: Dictionary = sig.get("lines", {}) as Dictionary
	var line_counts: Dictionary = entry.get("line_counts", {}) as Dictionary
	for ln in line_counts.keys():
		var lw: float = float(line_sig.get(ln, 0.0))
		if lw > 0.0:
			score += float(line_counts[ln]) * lw
	var feint_bias: float = float(sig.get("feint_bias", 0.0))
	var feint_n: int = int(entry.get("feint_resolved", 0))
	if feint_bias > 0.0 and feint_n > 0:
		score += float(feint_n) * feint_bias
	return score


static func infer_opponent_form(_manager: Node, observer: Dictionary, opponent_id: int) -> String:
	if observer == null or observer.is_empty() or opponent_id < 0:
		return ""
	if not _Attention.enabled():
		return ""
	var entry: Dictionary = _Attention.yomi_entry_for_attacker(observer, opponent_id)
	var total_obs: int = _Attention.yomi_observation_total(entry)
	if total_obs < CombatConstants.WF_YOMI_FORM_INFERENCE_MIN_OBS:
		return ""
	_ensure_defs()
	var best_form: String = ""
	var best_score: float = -1.0
	var second_score: float = -1.0
	for raw_form in _FORM_DEFS.keys():
		var fid: String = str(raw_form)
		var s: float = _signature_score_for_entry(fid, entry)
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
	return normalize_form(best_form)


## WF-2a: cache inferred opponent forms on observer (waiting-tick refresh).
static func refresh_inferred_forms_for_observer(manager: Node, observer: Dictionary) -> void:
	if observer == null or observer.is_empty() or manager == null:
		return
	if not _Attention.enabled():
		observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
		return
	var self_side: String = _EntityAccess.side_str(observer)
	var cache: Dictionary = {}
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var oc: Dictionary = other as Dictionary
		if not _EntityAccess.is_alive_in_combat(oc):
			continue
		if _EntityAccess.side_str(oc) == self_side:
			continue
		var oid: int = _EntityAccess.id_int(oc)
		if oid < 0:
			continue
		var inferred: String = infer_opponent_form(manager, observer, oid)
		if not inferred.is_empty():
			cache[str(oid)] = inferred
	if cache.is_empty():
		observer.erase(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID)
	else:
		observer[CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID] = cache


## Stance → pressure_class alias (harness compatibility). Production uses **`form_str`** + **`CombatWeaponForm.mod`**.
static func _stance_alias_from_pressure(form: String) -> String:
	match pressure_class(form):
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
	var side: String = _EntityAccess.side_str(c)
	var key: String = (
		CombatConstants.ENCOUNTER_KEY_PLAYER_DEFAULT_WEAPON_FORM
		if side == "player"
		else CombatConstants.ENCOUNTER_KEY_ENEMY_DEFAULT_WEAPON_FORM
	)
	return str(enc.get(key, "")).strip_edges()


## L2 → L3 home write site: sets **`weapon_form`**, stance alias (harness compatibility), home **`guard_line`** — does **not** stamp/clear PA. Contract: LIVE_PATHS **`#wf-assign-form-contract`**.
static func assign_form(
	manager: Node, c: Dictionary, form: String, reason: String = ""
) -> void:
	var weapon = _EntityAccess.get_weapon(c)
	var resolved: String = normalize_form(form)
	if not form_allowed_for_weapon(resolved, weapon):
		resolved = default_form_for_weapon(weapon)
	var old_form: String = _EntityAccess.form_str(c)
	c[CombatConstants.COMBATANT_KEY_WEAPON_FORM] = resolved
	c["stance"] = _stance_alias_from_pressure(resolved)
	if old_form != resolved and reason not in ["spawn", "harness_baseline"]:
		c[CombatConstants.COMBATANT_KEY_LAST_FORM_SWITCH_REASON] = reason
	_GuardLineUpdater.set_guard_from_line(c, home_guard_line(resolved))
	if manager != null and not reason.is_empty() and CombatConstants.combat_event_debug_active():
		const _CombatDebug := preload("res://combat/CombatDebug.gd")
		_CombatDebug.flow_log(
			"form_switch id=%d form=%s reason=%s"
			% [_EntityAccess.id_int(c), resolved, reason]
		)
	if (
		old_form != resolved
		and reason not in ["spawn", "harness_baseline"]
		and CombatConstants.WF_FORM_SWITCH_STAMINA_COST > 0.0
	):
		c["stamina"] = maxf(
			0.0, _EntityAccess.stamina_float(c) - CombatConstants.WF_FORM_SWITCH_STAMINA_COST
		)
	if (
		manager != null
		and old_form != resolved
		and reason not in ["spawn", "harness_baseline"]
	):
		const _OperationalLog := preload("res://core/OperationalLog.gd")
		if _OperationalLog.is_play_session_active():
			_OperationalLog.play_combat(
				"form_switch id=%d %s %s→%s reason=%s"
				% [
					_EntityAccess.id_int(c),
					_EntityAccess.get_display_name(c, _EntityAccess.id_int(c)),
					old_form,
					resolved,
					reason,
				]
			)


## Spawn path entry: resolve form from overlay → encounter → **`stance_preference`** → weapon default → **`assign_form(..., "spawn")`**. LIVE_PATHS **`#spawn--reset-path-wf-1a`**.
static func seed_combatant_form(
	manager: Node, c: Dictionary, spawn_overlay: Dictionary = {}
) -> void:
	var weapon = _EntityAccess.get_weapon(c)
	var raw: String = str(spawn_overlay.get("weapon_form", "")).strip_edges()
	if raw.is_empty():
		raw = _side_encounter_default_form(manager, c)
	if raw.is_empty():
		raw = str(c.get("stance_preference", "")).strip_edges()
	var form: String
	if raw.is_empty():
		form = default_form_for_weapon(weapon)
	else:
		form = normalize_form(raw)
		if not form_allowed_for_weapon(form, weapon):
			form = default_form_for_weapon(weapon)
	assign_form(manager, c, form, "spawn")


static func _stamp_form_switch_cooldown(c: Dictionary, clk: float) -> void:
	c[CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL] = (
		clk + CombatConstants.WF_FORM_SWITCH_COOLDOWN_S
	)


static func _inferred_opponent_form(manager: Node, observer: Dictionary, opponent_id: int) -> String:
	if opponent_id < 0:
		return ""
	var cache_raw: Variant = observer.get(CombatConstants.COMBATANT_KEY_INFERRED_OPP_FORM_BY_ID, null)
	if cache_raw is Dictionary:
		var cached: String = str((cache_raw as Dictionary).get(str(opponent_id), "")).strip_edges()
		if not cached.is_empty():
			return cached
	return infer_opponent_form(manager, observer, opponent_id)


static func _primary_melee_threat_id(manager: Node, c: Dictionary) -> int:
	if manager == null or c.is_empty():
		return -1
	var engaged: int = int(c.get("engaged_with_id", -1))
	if engaged >= 0:
		var engaged_c: Dictionary = _EntityAccess.manager_get_combatant(manager, engaged)
		if (
			not engaged_c.is_empty()
			and _EntityAccess.is_living_hostile_to(c, engaged_c)
		):
			return engaged
	var sole_id: int = -1
	var count: int = 0
	for other in manager.combatants:
		if other == null or other is not Dictionary:
			continue
		var oc: Dictionary = other as Dictionary
		if not _EntityAccess.is_living_hostile_to(c, oc):
			continue
		var pair_geom: Dictionary = _PairGeometry.effective_pair_geometry(manager, oc, c)
		if not _MeleeListing.can_melee_threaten(manager, oc, c, pair_geom):
			continue
		count += 1
		sole_id = _EntityAccess.id_int(oc)
	if count == 1:
		return sole_id
	return -1


static func _is_isolated_duel(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var scan: Dictionary = _TacticalCombat.surround_threat_scan_for_defender(manager, c)
	if int(scan.get("count", 0)) != 1:
		return false
	var wsum: float = float(scan.get("weight_sum", 0.0))
	if wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_ISOLATED_DUEL_WEIGHT_PAD:
		return false
	if int(scan.get("arc_occupancy_blocked", 0)) > 0:
		return false
	return _primary_melee_threat_id(manager, c) >= 0


static func _surround_pressure_high(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var scan: Dictionary = _TacticalCombat.surround_threat_scan_for_defender(manager, c)
	if int(scan.get("count", 0)) >= 2:
		return true
	var wsum: float = float(scan.get("weight_sum", 0.0))
	return wsum > CombatConstants.SURROUND_SECTOR_LOAD_FREE + CombatConstants.WF_AUTO_SWITCH_SURROUND_WEIGHT_PAD


static func _surround_form_for_weapon(weapon: Variant) -> String:
	if form_allowed_for_weapon(FORM_WALL, weapon):
		return FORM_WALL
	if form_allowed_for_weapon(FORM_TEMPEST, weapon):
		return FORM_TEMPEST
	return ""


static func _duel_form_from_yomi_and_stamina(
	cur: String,
	inferred: String,
	stamina_ratio: float,
	min_stamina: float,
	weapon: Variant = null
) -> String:
	var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
	var promote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_PROMOTE_PAD
	var demote_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_WRATH_DEMOTE_PAD
	if cur == FORM_WALL and stamina_ratio < min_stamina + offense_pad:
		return ""
	if not inferred.is_empty():
		if inferred == FORM_WRATH and cur != FORM_FOOL:
			return FORM_FOOL
		if inferred == FORM_FOOL and cur != FORM_WRATH:
			return FORM_WRATH
		if inferred == FORM_OX and stamina_ratio >= min_stamina + offense_pad:
			if cur != FORM_FOOL and form_allowed_for_weapon(FORM_FOOL, weapon):
				return FORM_FOOL
			if cur != FORM_WRATH and form_allowed_for_weapon(FORM_WRATH, weapon):
				return FORM_WRATH
	if stamina_ratio >= min_stamina + promote_pad and cur != FORM_WRATH:
		if form_allowed_for_weapon(FORM_WRATH, weapon):
			return FORM_WRATH
	if cur == FORM_WRATH and stamina_ratio < min_stamina + demote_pad:
		if form_allowed_for_weapon(FORM_FOOL, weapon):
			return FORM_FOOL
	return ""


static func _counter_form_vs_inferred(weapon: Variant, inferred_opp: String) -> String:
	if inferred_opp.is_empty():
		return ""
	_ensure_defs()
	var best_form: String = ""
	var best_mult: float = 1.0
	for raw_form in _FORM_DEFS.keys():
		var fid: String = normalize_form(str(raw_form))
		if not form_allowed_for_weapon(fid, weapon):
			continue
		var mult: float = float(_counter_spec_for_inferred(fid, inferred_opp).get("mult", 1.0))
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
	for fid_raw in [FORM_FOOL, FORM_WRATH, FORM_OX]:
		var fid: String = normalize_form(fid_raw)
		if not form_allowed_for_weapon(fid, weapon):
			continue
		var mult: float = float(_counter_spec_for_inferred(fid, inferred_opp).get("mult", 1.0))
		if mult > best_mult:
			best_mult = mult
			best_form = fid
	if best_mult <= 1.0 or best_form.is_empty():
		return ""
	return best_form


static func _try_assign_auto_switch(
	manager: Node, c: Dictionary, next_form: String, reason: String, clk: float
) -> bool:
	var next: String = str(next_form).strip_edges()
	if next.is_empty() or next == _EntityAccess.form_str(c):
		return false
	var weapon = _EntityAccess.get_weapon(c)
	if not form_allowed_for_weapon(next, weapon):
		return false
	assign_form(manager, c, next, reason)
	_stamp_form_switch_cooldown(c, clk)
	return true


## WF-3 auto-switch hook — calls **`assign_form`** only; does **not** stamp/clear PA. Caller: **`CombatAIActionPicker.pick`** after mental-stack miss. LIVE_PATHS **`#wf-pick-vs-strike`** · **`#wf-assign-form-contract`**.
static func evaluate_automatic_form(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var clk: float = _EntityAccess.combat_clock_float(manager)
	var until: float = float(
		c.get(CombatConstants.COMBATANT_KEY_FORM_SWITCH_COOLDOWN_UNTIL, 0.0)
	)
	if until > clk:
		return false
	var cur: String = _EntityAccess.form_str(c)
	var ratio: float = _EntityAccess.stamina_ratio(c)
	var min_r: float = min_stamina_ratio_for_form(cur)
	var weapon = _EntityAccess.get_weapon(c)
	var envelop: bool = _CombatDoctrine.envelop_mop_up_active(
		manager, _EntityAccess.formation_id_str(c)
	)
	if (
		ratio < min_r
		and cur != FORM_WALL
		and form_allowed_for_weapon(FORM_WALL, weapon)
		and not envelop
	):
		return _try_assign_auto_switch(manager, c, FORM_WALL, "low_stamina", clk)
	if not envelop:
		if _surround_pressure_high(manager, c):
			var sur_form: String = _surround_form_for_weapon(weapon)
			if _try_assign_auto_switch(manager, c, sur_form, "surround_pressure", clk):
				return true
	if _MobilityRetreat.cannot_commit_melee(c):
		return false
	if _is_isolated_duel(manager, c):
		var duel_id: int = _primary_melee_threat_id(manager, c)
		if duel_id >= 0:
			var inferred: String = _inferred_opponent_form(manager, c, duel_id)
			var offense_pad: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
			var can_offense: bool = not (
				cur == FORM_WALL and ratio < min_r + offense_pad
			)
			if can_offense:
				var counter: String = _duel_counter_form_vs_inferred(weapon, inferred)
				if _try_assign_auto_switch(manager, c, counter, "counter_read", clk):
					return true
			var duel_next: String = _duel_form_from_yomi_and_stamina(
				cur, inferred, ratio, min_r, weapon
			)
			if _try_assign_auto_switch(manager, c, duel_next, "duel_read", clk):
				return true
	var threat_id: int = _primary_melee_threat_id(manager, c)
	if threat_id >= 0:
		var offense_pad_fb: float = CombatConstants.WF_AUTO_SWITCH_DUEL_OFFENSE_STAMINA_PAD
		if not (cur == FORM_WALL and ratio < min_r + offense_pad_fb):
			var inferred_opp: String = _inferred_opponent_form(manager, c, threat_id)
			var counter: String = _counter_form_vs_inferred(weapon, inferred_opp)
			if _try_assign_auto_switch(manager, c, counter, "counter_read", clk):
				return true
	return false
