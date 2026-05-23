class_name CombatFormationRout
extends RefCounted

## Rout / abandon-field policy: ties **`flee`** to formation **`line_cohesion`** (morale, fill, lane stress) and side **casualty ratio**.
## Data flow: combatant `morale_cohesion` → `CombatMoraleCohesion` → `morale_cohesion_factor` → `CombatFormationEngagement._compute_line_cohesion`;
## casualties / fled / incap → `standing_at_start` vs current standing on formation side.

const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")


## Call from `CombatManager.start()` after fled-state reset, before first ZoC/cohesion recompute.
static func stamp_standing_counts_at_start(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	for fid in ["player", "enemy"]:
		var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if form.is_empty():
			continue
		var side: String = _FormationSlots.formation_side_str(form, fid)
		form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = standing_count_for_side(manager, side)


## Harness / edge path: stamp casualty baseline if `start()` was skipped or formation record was reset.
static func ensure_rout_baseline(manager: Node) -> void:
	if manager == null or not manager.get("formations"):
		return
	var need_stamp: bool = false
	for fid in ["player", "enemy"]:
		var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, fid)
		if form.is_empty():
			continue
		if int(form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0)) <= 0:
			need_stamp = true
			break
	if need_stamp:
		stamp_standing_counts_at_start(manager)


static func standing_count_for_side(manager: Node, side: String) -> int:
	if manager == null or side.is_empty():
		return 0
	var n: int = 0
	for c in manager.combatants:
		if _EntityAccess.side_str(c) == side and _EntityAccess.is_standing_combatant(c):
			n += 1
	return n


static func opponent_side_for_combatant(c: Dictionary) -> String:
	return _EntityAccess.opponent_side_label(_EntityAccess.side_str(c))


## True when this formation side still has a clear standing advantage (discourages formation-level rout).
static func side_holding_field(manager: Node, c: Dictionary) -> bool:
	if manager == null or c.is_empty():
		return false
	var side: String = _EntityAccess.side_str(c)
	var opp: String = opponent_side_for_combatant(c)
	var our_n: int = standing_count_for_side(manager, side)
	var opp_n: int = standing_count_for_side(manager, opp)
	if our_n <= 0:
		return false
	if opp_n <= 0:
		return false
	return float(our_n) >= float(opp_n) * CombatConstants.FORMATION_FLEE_WINNING_STANDING_RATIO


## Formation dict for combatant home roster **`formation_id`** (not host-line geometry fid).
static func formation_record_for_combatant(manager: Node, c: Dictionary) -> Dictionary:
	if manager == null or c.is_empty():
		return {}
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty():
		return {}
	return _FormationSlots.formation_record_for_manager(manager, fid)


static func _threshold_float(
	manager: Node,
	c: Dictionary,
	threshold_key: String,
	default_v: float,
	clamp_lo: float,
	clamp_hi: float
) -> float:
	if manager == null or c.is_empty():
		return default_v
	var fid: String = _EntityAccess.formation_id_str(c)
	if fid.is_empty() or not manager.get("rout_thresholds_by_fid"):
		return default_v
	var side_t: Variant = manager.rout_thresholds_by_fid.get(fid)
	if side_t is not Dictionary:
		return default_v
	var raw: Variant = (side_t as Dictionary).get(threshold_key)
	if raw == null:
		return default_v
	return clampf(float(raw), clamp_lo, clamp_hi)


## Cached `line_cohesion` (0..1) from last `CombatFormationEngagement.recompute_all`.
static func line_cohesion_for_combatant(manager: Node, c: Dictionary) -> float:
	var form: Dictionary = formation_record_for_combatant(manager, c)
	if form.is_empty():
		return 1.0
	return clampf(float(form.get("line_cohesion", 1.0)), 0.0, 1.0)


static func flee_line_cohesion_max(manager: Node, c: Dictionary) -> float:
	return _threshold_float(
		manager,
		c,
		CombatConstants.ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX,
		CombatConstants.FORMATION_FLEE_LINE_COHESION_MAX,
		0.05,
		0.95
	)


static func flee_casualty_ratio_min(manager: Node, c: Dictionary) -> float:
	return _threshold_float(
		manager,
		c,
		CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN,
		CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN,
		0.05,
		0.90
	)


## Fraction of this formation **side** no longer standing (dead, fled, unconscious, cowering incapacitated).
static func casualty_ratio_for_combatant(manager: Node, c: Dictionary) -> float:
	var form: Dictionary = formation_record_for_combatant(manager, c)
	if form.is_empty():
		return 0.0
	var start_n: int = int(form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0))
	if start_n <= 0:
		return 0.0
	var fid: String = _EntityAccess.formation_id_str(c)
	var side: String = _FormationSlots.formation_side_str(form, fid)
	var now_n: int = standing_count_for_side(manager, side)
	return clampf(1.0 - float(now_n) / float(start_n), 0.0, 1.0)


## True when the unit's formation is tactically breaking (ragged line or heavy losses).
static func formation_stressed_for_rout(manager: Node, c: Dictionary) -> bool:
	ensure_rout_baseline(manager)
	if line_cohesion_for_combatant(manager, c) < flee_line_cohesion_max(manager, c):
		return true
	if casualty_ratio_for_combatant(manager, c) >= flee_casualty_ratio_min(manager, c):
		return true
	return false


## Wounded + breaking formation only (not no-arms / Class III / immediate peril).
static func formation_stress_abandonment_path(manager: Node, c: Dictionary) -> bool:
	if c.is_empty() or manager == null:
		return false
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return false
	var node: Variant = _EntityAccess.node_variant(c)
	if node == null:
		return false
	var bv: float = _EntityAccess.get_blood_volume_from_node(node as Node)
	if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
		return false
	if manager.has_method("_is_in_immediate_peril") and manager._is_in_immediate_peril(c):
		return false
	return (
		bv < CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX
		and formation_stressed_for_rout(manager, c)
	)


## Abandon-field (`flee`) warranted — personal catastrophe, helpless, or wounded under a breaking formation.
static func abandonment_warranted(manager: Node, c: Dictionary) -> bool:
	ensure_rout_baseline(manager)
	if c.is_empty():
		return false
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return true
	var node: Variant = _EntityAccess.node_variant(c)
	if node == null:
		return false
	var bv: float = _EntityAccess.get_blood_volume_from_node(node as Node)
	if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
		return true
	if manager != null and manager.has_method("_is_in_immediate_peril") and manager._is_in_immediate_peril(c):
		return true
	if formation_stress_abandonment_path(manager, c):
		if side_holding_field(manager, c):
			return false
		return true
	return false


## AI pick multiplier from formation stress (not raw combatant `morale_cohesion` — that already feeds `line_cohesion`).
static func flee_ai_pick_mult(manager: Node, c: Dictionary) -> float:
	var coh: float = line_cohesion_for_combatant(manager, c)
	var cas: float = casualty_ratio_for_combatant(manager, c)
	var coh_m: float = lerpf(
		CombatConstants.AI_FLEE_LOW_COHESION_MULT,
		CombatConstants.AI_FLEE_HIGH_COHESION_MULT,
		coh
	)
	var cas_min: float = flee_casualty_ratio_min(manager, c)
	var cas_t: float = clampf(cas / maxf(cas_min, 0.01), 0.0, 1.0)
	var cas_m: float = lerpf(1.0, CombatConstants.AI_FLEE_HIGH_CASUALTY_MULT, cas_t)
	var mult: float = coh_m * cas_m
	# Personal crisis flee stays urgent even when the side still has numbers.
	if side_holding_field(manager, c) and formation_stress_abandonment_path(manager, c):
		mult *= 0.55
	return mult


static func rout_context_snapshot(manager: Node, c: Dictionary) -> Dictionary:
	return {
		"line_cohesion": line_cohesion_for_combatant(manager, c),
		"casualty_ratio": casualty_ratio_for_combatant(manager, c),
		"formation_stressed": formation_stressed_for_rout(manager, c),
		"side_holding_field": side_holding_field(manager, c),
		"flee_line_cohesion_max": flee_line_cohesion_max(manager, c),
		"flee_casualty_ratio_min": flee_casualty_ratio_min(manager, c),
	}


## Side casualty percent (0–100) for battle UI; 0 when `standing_at_start` unset.
static func casualty_percent_for_formation(manager: Node, formation_id: String) -> int:
	if manager == null or formation_id.is_empty():
		return 0
	ensure_rout_baseline(manager)
	var form: Dictionary = _FormationSlots.formation_record_for_manager(manager, formation_id)
	if form.is_empty():
		return 0
	var start_n: int = int(form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0))
	if start_n <= 0:
		return 0
	var side: String = _FormationSlots.formation_side_str(form, formation_id)
	var now_n: int = standing_count_for_side(manager, side)
	return int(round(clampf(1.0 - float(now_n) / float(start_n), 0.0, 1.0) * 100.0))


## Personal crisis or helpless — rout tooltip relevant even when the side still has numbers.
static func personal_rout_pressure(manager: Node, c: Dictionary) -> bool:
	if c.is_empty():
		return false
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return true
	var node: Variant = _EntityAccess.node_variant(c)
	if node == null:
		return false
	var bv: float = _EntityAccess.get_blood_volume_from_node(node as Node)
	if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
		return true
	if manager != null and manager.has_method("_is_in_immediate_peril") and manager._is_in_immediate_peril(c):
		return true
	return false


## Gauge tooltip when the formation is under rout pressure (cohesion + casualties).
static func rout_pressure_tooltip_line(manager: Node, c: Dictionary) -> String:
	if manager == null or c.is_empty():
		return ""
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return ""
	if not formation_stressed_for_rout(manager, c):
		return ""
	if side_holding_field(manager, c) and not personal_rout_pressure(manager, c):
		return ""
	var coh_pct: int = int(round(line_cohesion_for_combatant(manager, c) * 100.0))
	var cas_pct: int = int(round(casualty_ratio_for_combatant(manager, c) * 100.0))
	var hold_note: String = ""
	if side_holding_field(manager, c):
		hold_note = " Your side still holds the field — rout is less likely."
	return (
		(
			"Formation under pressure (line cohesion %d%%, side casualties %d%%) — rout may be offered."
			% [coh_pct, cas_pct]
		)
		+ hold_note
	)


## Player turn-ready when **`flee`** is listed for an armed fighter.
static func rout_hint_when_flee_listed(manager: Node, c: Dictionary, actions: Array) -> String:
	if manager == null or c.is_empty() or actions.is_empty():
		return ""
	if _EntityAccess.get_attacking_arm(c).is_empty():
		return ""
	const _ListedActions := preload("res://combat/CombatListedActions.gd")
	var cid: int = _EntityAccess.id_int(c)
	if not _ListedActions.actions_include_self_target_move(
		actions, cid, CombatConstants.MOVE_ID_FLEE
	):
		return ""
	var coh_pct: int = int(round(line_cohesion_for_combatant(manager, c) * 100.0))
	var cas_pct: int = int(round(casualty_ratio_for_combatant(manager, c) * 100.0))
	if formation_stressed_for_rout(manager, c):
		if side_holding_field(manager, c):
			return (
				(
					"Flee leaves the field (cohesion %d%%, casualties %d%%) — your side still has numbers; fall back when listed."
					% [coh_pct, cas_pct]
				)
			)
		return (
			"Flee leaves the field (cohesion %d%%, casualties %d%%) — fall back stays in formation when listed."
			% [coh_pct, cas_pct]
		)
	return "Flee leaves the field — you are badly hurt or bleeding out."
