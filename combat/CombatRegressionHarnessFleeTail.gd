class_name CombatRegressionHarnessFleeTail
extends RefCounted

## Tier 6.2 flee / rout tests split from CombatRegressionHarness (compile size).

const _MgrScript := preload("res://combat/CombatManager.gd")
const _ActionsBuilder := preload("res://combat/AvailableActionsBuilder.gd")
const _ListedActions := preload("res://combat/CombatListedActions.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")
const _FormationFlee := preload("res://combat/CombatFormationFlee.gd")
const _ResolveAction := preload("res://combat/CombatResolveAction.gd")
const _BattleUIUpdater := preload("res://ui/BattleUIUpdater.gd")
const _CombatLogFormatter := preload("res://ui/CombatLogFormatter.gd")
const _AIPicker := preload("res://combat/CombatAIActionPicker.gd")
const _Exhaustion := preload("res://combat/CombatExhaustion.gd")
const _PlayerTurnHints := preload("res://combat/CombatPlayerTurnHints.gd")
const _TargetScoring := preload("res://combat/CombatTargetScoring.gd")

## Tier 6.2: immobile cowering does not list **`flee`**.
static func _run_flee_not_listed_when_immobile(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "left_leg")
	CombatRegressionHarness._harness_destroy_limb(ent, "right_leg")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	if _ListedActions.actions_include_self_target_move(
		acts, _EntityAccess.id_int(c), CombatConstants.MOVE_ID_FLEE
	):
		CombatRegressionHarness._fail(failures, "flee_immobile: must not list flee")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: Class I blood loss on a firm line must not warrant abandon-field flee.
static func _run_flee_not_legal_light_blood_loss_only(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.88
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	ent.blood_volume = 88.0
	if _FormationFlee.flee_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_light_blood: flee must not be legal at bv=88 on firm line")
	if _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_light_blood: flee abandonment must not be warranted at bv=88 on firm line")
	ent.blood_volume = 52.0
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_light_blood: flee abandonment should be warranted at bv=52 (Class III+)")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: moderate wound + firm line → hold; same wound + low cohesion or casualties → rout allowed.
static func _run_flee_cohesion_casualty_wounded_not_firm_line(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	ent.blood_volume = 82.0
	form["line_cohesion"] = 0.88
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_cohesion: bv=82 firm line should not warrant rout")
	if _FormationFlee.flee_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_cohesion: flee must not be legal at bv=82 on firm line")
	form["line_cohesion"] = 0.38
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_cohesion: bv=82 low line_cohesion should warrant rout")
	if not _FormationFlee.flee_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_cohesion: flee should be legal when line wavers and rear path blocked")
	if not _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_cohesion: want formation_stressed when cohesion low")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: casualty ratio on formation side gates rout (independent of cohesion read).
static func _run_flee_casualty_ratio_triggers_stress(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.9
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	var rear_id: int = _EntityAccess.id_int(mgr.combatants[1])
	CombatRegressionHarness._soak_kill_combatant(mgr, rear_id)
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = 82.0
	var cas: float = _Rout.casualty_ratio_for_combatant(mgr, front_c)
	if cas < CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN - 0.01:
		CombatRegressionHarness._fail(failures, "flee_casualty: want ratio >= min got %.3f" % cas)
	if not _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_casualty: 50%% side casualties should stress formation")
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_casualty: wounded + heavy casualties should warrant rout")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: winning side with standing advantage should not rout from formation stress alone.
static func _run_flee_winning_side_holds_wounded_stressed(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.35
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = 82.0
	if not _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: want formation_stressed when cohesion low")
	if not _Rout.side_holding_field(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: player 2v1 should hold the field")
	if _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: wounded+stressed must not warrant rout while winning")
	if _FormationFlee.flee_action_legal(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: flee must not list when winning with numbers")
	CombatRegressionHarness._soak_kill_combatant(mgr, _EntityAccess.id_int(mgr.combatants[2]))
	if _Rout.side_holding_field(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: no enemy standing — holding_field dampener must be off")
	# Death notify may recompute `line_cohesion`; re-apply wavering line for rout policy check.
	form["line_cohesion"] = 0.35
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_winning_hold: wounded+stressed should warrant rout when no longer outnumbering foe")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: encounter `flee_casualty_ratio_min_*` overrides default rout gate.
static func _run_flee_encounter_casualty_threshold(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER] = 0.50
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 3, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.9
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 3
	CombatRegressionHarness._soak_kill_combatant(mgr, _EntityAccess.id_int(mgr.combatants[2]))
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = 82.0
	var cas: float = _Rout.casualty_ratio_for_combatant(mgr, front_c)
	if absf(cas - 1.0 / 3.0) > 0.02:
		CombatRegressionHarness._fail(failures, "flee_encounter_thresh: want ~33%% casualties got %.3f" % cas)
	if _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_encounter_thresh: 33%% should be below encounter min 50%%")
	if _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_encounter_thresh: wounded must not rout below encounter casualty gate")
	CombatRegressionHarness._soak_kill_combatant(mgr, _EntityAccess.id_int(mgr.combatants[1]))
	if not _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_encounter_thresh: 66%% casualties should stress at min 50%%")
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_encounter_thresh: wounded + 66%% casualties should warrant rout")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: encounter `flee_line_cohesion_max_*` tightens rout when cohesion is middling.
static func _run_flee_encounter_line_cohesion_max(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FLEE_LINE_COHESION_MAX_PLAYER] = 0.50
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var front_c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(front_c) as CoreEntity
	ent.blood_volume = 82.0
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.52
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_encounter_coh: cohesion 0.52 should be firm at max 0.50")
	if _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_encounter_coh: should not warrant rout above encounter cohesion max")
	form["line_cohesion"] = 0.44
	if not _Rout.formation_stressed_for_rout(mgr, front_c):
		CombatRegressionHarness._fail(failures, "flee_encounter_coh: cohesion 0.44 should stress at max 0.50")
	if not _EntityAccess.flee_abandonment_warranted(front_c, mgr):
		CombatRegressionHarness._fail(failures, "flee_encounter_coh: wounded + low cohesion should warrant rout")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: preset **`FORMATION_PRESET_KEY_FLEE_*`** wins over encounter at **`start()`** (`rout_thresholds_by_fid`).
static func _run_flee_preset_rout_threshold_overrides_encounter(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.encounter[CombatConstants.ENCOUNTER_KEY_FLEE_CASUALTY_RATIO_MIN_PLAYER] = 0.30
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start(
		{
			"files": 1,
			"ranks": 2,
			CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN: 0.55,
		},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var thresholds: Dictionary = mgr.rout_thresholds_by_fid.get("player", {})
	var cas_min: float = float(
		thresholds.get(CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN, -1.0)
	)
	if absf(cas_min - 0.55) > 0.001:
		CombatRegressionHarness._fail(failures, "flee_preset_rout: want preset casualty min 0.55 got %.3f" % cas_min)
	var front_c: Dictionary = mgr.combatants[0]
	if absf(_Rout.flee_casualty_ratio_min(mgr, front_c) - 0.55) > 0.001:
		CombatRegressionHarness._fail(failures, "flee_preset_rout: CombatFormationRout should read merged threshold")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: **`CombatManager.get_rout_threshold`** returns merged preset or default.
static func _run_flee_manager_get_rout_threshold(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.start(
		{CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN: 0.48},
		{"files": 1, "ranks": 1}
	)
	var v: float = mgr.get_rout_threshold(
		"player", CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN
	)
	if absf(v - 0.48) > 0.001:
		CombatRegressionHarness._fail(failures, "flee_get_rout_threshold: want preset 0.48 got %.3f" % v)
	var default_v: float = mgr.get_rout_threshold(
		"enemy", CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN
	)
	if absf(default_v - CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN) > 0.001:
		CombatRegressionHarness._fail(
			failures,
			"flee_get_rout_threshold: enemy default want %.2f got %.3f"
			% [CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN, default_v]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: listed **`flee`** duration hint marks instant resolve (not fall_back seconds).
static func _run_flee_listed_duration_hint_instant(failures: PackedStringArray) -> void:
	const _MoveDuration := preload("res://combat/CombatFormationMoveDuration.gd")
	var mgr: Node = CombatRegressionHarness._harness_start_player_only()
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	var flee_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": cid}
	_MoveDuration.stamp_listed_action_duration_hint(mgr, c, flee_act)
	var hint: String = str(flee_act.get("formation_move_duration_hint", ""))
	if hint.find("instant") < 0:
		CombatRegressionHarness._fail(failures, "flee_duration_hint: want instant hint got '%s'" % hint)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## MS-L7 / critical stamina: flee AI weight must beat rotate_file when both are listed.
static func _run_flee_ai_exhaustion_tunnel_beats_rotate_file(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 2, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD + 0.05
	if not _Exhaustion.exhaustion_tunnel_active(c):
		CombatRegressionHarness._fail(failures, "flee_ai_tunnel: exhaustion tunnel should be active")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	var flee_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": cid}
	var rot_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": cid}
	var w_flee: float = _AIPicker._get_action_weight(flee_act, cid, mgr, true)
	var w_rot: float = _AIPicker._get_action_weight(rot_act, cid, mgr, true)
	if w_flee <= w_rot:
		CombatRegressionHarness._fail(
			failures,
			"flee_ai_tunnel: flee weight %.3f should exceed rotate_file %.3f"
			% [w_flee, w_rot]
		)
	c["stamina"] = 0.05 * float(c.get("stamina_max", 100.0))
	if _EntityAccess.stamina_ratio(c) >= CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO:
		CombatRegressionHarness._fail(failures, "flee_ai_tunnel: stamina setup should be critical")
	w_flee = _AIPicker._get_action_weight(flee_act, cid, mgr, true)
	if w_flee < CombatConstants.AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT - 0.01:
		CombatRegressionHarness._fail(
			failures,
			"flee_ai_tunnel: critical stamina flee weight %.3f want >= %.3f"
			% [w_flee, CombatConstants.AI_FLEE_EXHAUSTION_TUNNEL_WEIGHT]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Critical stamina (below MS-L7 tunnel): utility pick weight still favors flee over rotate_file.
static func _run_flee_ai_critical_stamina_beats_rotate_file(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 2, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = CombatConstants.MENTAL_STACK_EXHAUSTION_TUNNEL_THRESHOLD - 0.15
	c["stamina"] = 0.05 * float(c.get("stamina_max", 100.0))
	if _EntityAccess.stamina_ratio(c) >= CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO:
		CombatRegressionHarness._fail(failures, "flee_ai_critical: stamina setup should be below critical ratio")
	var flee_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": cid}
	var rot_act: Dictionary = {"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": cid}
	var w_flee: float = _AIPicker._get_action_weight(flee_act, cid, mgr, true)
	var w_rot: float = _AIPicker._get_action_weight(rot_act, cid, mgr, true)
	if w_flee <= w_rot:
		CombatRegressionHarness._fail(
			failures,
			"flee_ai_critical: flee weight %.3f should exceed rotate_file %.3f"
			% [w_flee, w_rot]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## End-to-end pick (mental stack L5 + weights): flee vs rotate at critical stamina never picks rotate.
static func _run_flee_ai_pick_critical_stamina_never_rotate(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 2, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 2, "ranks": 2}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	c[CombatConstants.COMBATANT_KEY_EXHAUSTION] = 0.0
	c["stamina"] = 0.05 * float(c.get("stamina_max", 100.0))
	var acts: Array = [
		{"move_id": CombatConstants.MOVE_ID_FLEE, "target_id": cid},
		{"move_id": CombatConstants.MOVE_ID_ROTATE_FILE, "target_id": cid},
	]
	for seed_i in range(8):
		seed(seed_i)
		var choice: Dictionary = _AIPicker.pick(acts, cid, mgr)
		if str(choice.get("move_id", "")) != CombatConstants.MOVE_ID_FLEE:
			CombatRegressionHarness._fail(
				failures,
				"flee_pick_critical: seed=%d want flee got %s"
				% [seed_i, str(choice.get("move_id", ""))]
			)
			break
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: AI flee weight stays high for personal crisis even when side holds the field.
static func _run_flee_ai_pick_not_dampened_personal_crisis(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	ent.blood_volume = 50.0
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.35
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if not _Rout.side_holding_field(mgr, c):
		CombatRegressionHarness._fail(failures, "flee_ai_personal: want holding field 2v1")
	var coh: float = _Rout.line_cohesion_for_combatant(mgr, c)
	var coh_m: float = lerpf(
		CombatConstants.AI_FLEE_LOW_COHESION_MULT,
		CombatConstants.AI_FLEE_HIGH_COHESION_MULT,
		coh
	)
	var mult: float = _Rout.flee_ai_pick_mult(mgr, c)
	if mult < coh_m * 0.98:
		CombatRegressionHarness._fail(
			failures,
			"flee_ai_personal: holding-field dampener must not apply at bv=50 (mult=%.3f coh_m=%.3f)"
			% [mult, coh_m]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## p4f: losing side under formation stress gets extra flee pick weight.
static func _run_flee_ai_losing_side_mult_boost(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var c: Dictionary = mgr.combatants[0]
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.35
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if _Rout.side_holding_field(mgr, c):
		CombatRegressionHarness._fail(failures, "flee_losing_side: want player outnumbered on field")
	if not _Rout.formation_stressed_for_rout(mgr, c):
		CombatRegressionHarness._fail(failures, "flee_losing_side: want formation_stressed")
	var coh: float = _Rout.line_cohesion_for_combatant(mgr, c)
	var coh_m: float = lerpf(
		CombatConstants.AI_FLEE_LOW_COHESION_MULT,
		CombatConstants.AI_FLEE_HIGH_COHESION_MULT,
		coh
	)
	var cas: float = _Rout.casualty_ratio_for_combatant(mgr, c)
	var cas_min: float = _Rout.flee_casualty_ratio_min(mgr, c)
	var cas_t: float = clampf(cas / maxf(cas_min, 0.01), 0.0, 1.0)
	var cas_m: float = lerpf(1.0, CombatConstants.AI_FLEE_HIGH_CASUALTY_MULT, cas_t)
	var base: float = coh_m * cas_m
	var mult: float = _Rout.flee_ai_pick_mult(mgr, c)
	if mult < base * CombatConstants.AI_FLEE_LOSING_SIDE_MULT * 0.98:
		CombatRegressionHarness._fail(
			failures,
			"flee_losing_side: want mult >= base*%.2f (base=%.3f mult=%.3f)"
			% [CombatConstants.AI_FLEE_LOSING_SIDE_MULT, base, mult]
		)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## p4f UX: early rout hint when line wavers but **`flee`** is not listed yet.
static func _run_rout_pressure_early_hint_when_losing_stressed(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	for _i in 2:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	for _j in 5:
		mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 5, "ranks": 1, "density": "normal"}, {"files": 5, "ranks": 1, "density": "normal"})
	var c: Dictionary = mgr.combatants[0]
	c["gauge"] = 100.0
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.35
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if _Rout.side_holding_field(mgr, c):
		CombatRegressionHarness._fail(failures, "rout_early_hint: want player outnumbered on field")
	if not _Rout.formation_stressed_for_rout(mgr, c):
		CombatRegressionHarness._fail(failures, "rout_early_hint: want formation_stressed")
	if _EntityAccess.flee_abandonment_warranted(c, mgr):
		CombatRegressionHarness._fail(failures, "rout_early_hint: want flee not warranted yet (healthy line stress)")
	var acts: Array = _ActionsBuilder.build(mgr, _EntityAccess.id_int(c))
	var hint: String = _PlayerTurnHints.rout_pressure_early_hint(mgr, c, acts)
	if "Line wavering" not in hint:
		CombatRegressionHarness._fail(failures, "rout_early_hint: want early wavering copy got %s" % hint)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: gauge rout tooltip hidden when formation stress is blocked by holding the field.
static func _run_flee_rout_tooltip_suppressed_when_holding(failures: PackedStringArray) -> void:
	const _Rout := preload("res://combat/CombatFormationRout.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start(
		{"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_STRICT},
		{"files": 1, "ranks": 1}
	)
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	ent.blood_volume = 82.0
	var form: Dictionary = _FormationSlots.formation_record_for_manager(mgr, "player")
	form["line_cohesion"] = 0.35
	form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = 2
	if not _Rout.formation_stressed_for_rout(mgr, c):
		CombatRegressionHarness._fail(failures, "flee_rout_tooltip: want formation_stressed")
	var tip: String = _Rout.rout_pressure_tooltip_line(mgr, c)
	if not tip.is_empty():
		CombatRegressionHarness._fail(failures, "flee_rout_tooltip: should suppress tooltip when holding field at bv=82")
	ent.blood_volume = 50.0
	if _Rout.rout_pressure_tooltip_line(mgr, c).is_empty():
		CombatRegressionHarness._fail(failures, "flee_rout_tooltip: personal crisis should still show rout pressure tooltip")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: **`apply_flee`** marks **`combat_absent`**, clears formation slot, ends standing count.
static func _run_flee_resolve_marks_combat_absent_and_clears_slot(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var fid: String = "player"
	var slots_before: Dictionary = _FormationSlots.formation_slots_dict(
		_FormationSlots.formation_record_for_manager(mgr, fid)
	)
	if not _FormationSlots.slot_has_any_living_occupant(mgr, slots_before, Vector2i(0, 0)):
		CombatRegressionHarness._fail(failures, "flee_resolve: setup want rank-0 occupant")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
	if not bool(c.get("combat_absent", false)):
		CombatRegressionHarness._fail(failures, "flee_resolve: want combat_absent after flee")
	if _EntityAccess.state_str(c) != CombatConstants.STATE_FLED:
		CombatRegressionHarness._fail(failures, "flee_resolve: want state fled got %s" % _EntityAccess.state_str(c))
	if _EntityAccess.is_standing_combatant(c):
		CombatRegressionHarness._fail(failures, "flee_resolve: fled unit should not count as standing")
	var slots_after: Dictionary = _FormationSlots.formation_slots_dict(
		_FormationSlots.formation_record_for_manager(mgr, fid)
	)
	if _FormationSlots.slot_has_any_living_occupant(mgr, slots_after, Vector2i(0, 0)):
		CombatRegressionHarness._fail(failures, "flee_resolve: rank-0 slot should be empty after flee")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: **`apply_flee`** clears stale doctrine target commit.
static func _run_flee_clears_doctrine_commitment(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var en: Dictionary = mgr.combatants[1]
	var cid: int = _EntityAccess.id_int(c)
	var eid: int = _EntityAccess.id_int(en)
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	mgr.combat_clock = 0.0
	_TargetScoring.on_combat_commitment(mgr, cid, eid)
	if int(c.get("doctrine_target_commit_id", -2)) != eid:
		CombatRegressionHarness._fail(failures, "flee_doctrine: setup commit failed")
		CombatRegressionHarness._free_manager_restore_global_rng(mgr)
		return
	_ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
	if int(c.get("doctrine_target_commit_id", -2)) != -1:
		CombatRegressionHarness._fail(failures, "flee_doctrine: flee should clear doctrine_target_commit_id")
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: formation diagram omits fled unit from rank/file cells; lists under **Fled:** line.
static func _run_flee_formation_diagram_omits_fled_from_grid(failures: PackedStringArray) -> void:
	const _Diagram := preload("res://ui/FormationDiagramBuilder.gd")
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 1, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	ent.name = "FleeTest"
	var who: String = _EntityAccess.get_display_name(c, cid)
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	var diagram: Control = _Diagram.create(mgr, {"files": 1, "ranks": 1, "density": "normal"}, "player")
	_ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
	_Diagram.refresh(diagram)
	var fled_line: Label = diagram.get_meta("_fled_line", null) as Label
	if fled_line == null or not fled_line.visible or who not in fled_line.text:
		CombatRegressionHarness._fail(
			failures, "flee_diagram: want Fled line listing %s got '%s'" % [who, str(fled_line.text if fled_line else "")]
		)
	var grid: GridContainer = diagram.get_meta("_formation_grid", null) as GridContainer
	if grid != null:
		for child in grid.get_children():
			if child is Label:
				continue
			for lbl in _Diagram.labels_under_cell(child):
				var cell_text: String = str((lbl as Label).text)
				if who.is_empty():
					continue
				if cell_text == who or cell_text.begins_with(who + " "):
					CombatRegressionHarness._fail(
						failures,
						"flee_diagram: fled unit still in grid cell '%s'" % cell_text
					)
	diagram.free()
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: fled unit shows **Fled** on the gauge row (still **`alive`**).
static func _run_flee_ui_gauge_label_fled(failures: PackedStringArray) -> void:
	var mgr: Node = _MgrScript.new()
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "player")
	mgr.register(CombatRegressionHarness._new_entity("SWORD"), "enemy")
	mgr.start({"files": 1, "ranks": 2, "line_discipline": CombatConstants.LINE_DISCIPLINE_LOOSE}, {"files": 1, "ranks": 1})
	mgr.set_meta("_engagement_mode_cached", "formation")
	var c: Dictionary = mgr.combatants[0]
	var cid: int = _EntityAccess.id_int(c)
	var ent: CoreEntity = _EntityAccess.scene_node(c) as CoreEntity
	CombatRegressionHarness._harness_destroy_limb(ent, "right_arm")
	CombatRegressionHarness._harness_destroy_limb(ent, "left_arm")
	c.state = CombatConstants.STATE_COWERING
	c.gauge = 100.0
	_ResolveAction.resolve(mgr, cid, cid, CombatConstants.MOVE_ID_FLEE, {})
	var label: String = _BattleUIUpdater.gauge_label_text_for_combatant(c, mgr)
	if label != "Fled":
		CombatRegressionHarness._fail(failures, "flee_ui: gauge want Fled got %s" % label)
	CombatRegressionHarness._free_manager_restore_global_rng(mgr)


## Tier 6.2: **`CombatManager.start()`** clears **`combat_absent`** / **`STATE_FLED`** on reused dicts.
static func _run_flee_combat_start_clears_absent_state(failures: PackedStringArray) -> void:
	var mgr: Node = CombatRegressionHarness._harness_start_1v1()
	var c: Dictionary = mgr.combatants[0]
	c["combat_absent"] = true
	c.state = CombatConstants.STATE_FLED
	mgr.start({"files": 1, "ranks": 1}, {"files": 1, "ranks": 1})
	if bool(c.get("combat_absent", false)):
		CombatRegressionHarness._fail(failures, "flee_start: combat_absent should clear on start()")
	if _EntityAccess.state_str(c) == CombatConstants.STATE_FLED:
		CombatRegressionHarness._fail(failures, "flee_start: STATE_FLED should reset to waiting on start()")
	CombatRegressionHarness._free_manager(mgr)
## Tier 6.2: combat log **`fled`** outcome line.
static func _run_combat_log_formatter_fled_outcome(failures: PackedStringArray) -> void:
	var line: String = _CombatLogFormatter.format_action_line(
		"Alaric", "player", "Alaric", "player", {"outcome": "fled", "dmg": 0, "died": false}
	)
	if "fled the field" not in line:
		CombatRegressionHarness._fail(failures, "combat_log_fled: want fled the field got %s" % line)

static func run(failures: PackedStringArray) -> void:
	_run_flee_not_listed_when_immobile(failures)
	_run_flee_not_legal_light_blood_loss_only(failures)
	_run_flee_cohesion_casualty_wounded_not_firm_line(failures)
	_run_flee_casualty_ratio_triggers_stress(failures)
	_run_flee_winning_side_holds_wounded_stressed(failures)
	_run_flee_encounter_casualty_threshold(failures)
	_run_flee_encounter_line_cohesion_max(failures)
	_run_flee_preset_rout_threshold_overrides_encounter(failures)
	_run_flee_manager_get_rout_threshold(failures)
	_run_flee_listed_duration_hint_instant(failures)
	_run_flee_ai_exhaustion_tunnel_beats_rotate_file(failures)
	_run_flee_ai_critical_stamina_beats_rotate_file(failures)
	_run_flee_ai_pick_critical_stamina_never_rotate(failures)
	_run_flee_ai_pick_not_dampened_personal_crisis(failures)
	_run_flee_ai_losing_side_mult_boost(failures)
	_run_rout_pressure_early_hint_when_losing_stressed(failures)
	_run_flee_rout_tooltip_suppressed_when_holding(failures)
	_run_flee_resolve_marks_combat_absent_and_clears_slot(failures)
	_run_flee_clears_doctrine_commitment(failures)
	_run_flee_formation_diagram_omits_fled_from_grid(failures)
	_run_flee_ui_gauge_label_fled(failures)
	_run_flee_combat_start_clears_absent_state(failures)
	_run_combat_log_formatter_fled_outcome(failures)
