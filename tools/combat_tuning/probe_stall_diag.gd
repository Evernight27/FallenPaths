extends SceneTree
## Diagnostic: one SWORD-vs-SWORD duel (probe rep2 seed) with per-tick state dump so the
## "strikes stop but stamina stays 100%" stall can be root-caused.

const TICK_DT := 0.05
const MAX_SEC := 60.0

const _Helpers := preload("res://harness/d001/D001RunnerHelpers.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")
const _CombatRegressionHarness := preload("res://harness/regression/CombatRegressionHarness.gd")


func _init() -> void:
	for wid in ["DAGGER"]:
		seed(hash("probe_fight_%s_2" % wid) & 0x7FFFFFFF)
		var mgr: Node = _start_duel(wid)
		var elapsed := _drive_fight(mgr)
		print("STALL_DIAG wid=%s duration_s=%.1f medical=%s" % [wid, elapsed, bool(mgr.medical_phase)])
		_dump_end_state(mgr)
		HarnessFixtures._free_manager(mgr)
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


var _last_tick := -1


func _drive_fight(mgr: Node) -> float:
	mgr.set_meta("_fp_harness_diag", true)
	var elapsed := 0.0
	while elapsed < MAX_SEC and mgr.is_processing():
		_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
		mgr._process(TICK_DT)
		elapsed += TICK_DT
		if bool(mgr.medical_phase):
			break
		if int(mgr.combat_clock) > _last_tick:
			_last_tick = int(mgr.combat_clock)
			_dump_states(mgr, elapsed)
	_Helpers._auto_resolve_ready_combatants(mgr, "7v7")
	return elapsed


func _dump_states(mgr: Node, elapsed: float) -> void:
	var row := "STALL_DIAG t=%6.1f clock=%6.1f" % [elapsed, float(mgr.combat_clock)]
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		var node: Node = CombatantEntityAccess.scene_node(c)
		var sd: String = CombatantEntityAccess.side_str(c)
		var st: String = CombatantEntityAccess.state_str(c)
		var gauge: float = float(c.get(DataKeys.COMBATANT_GAUGE, 0.0))
		var sta: float = CombatantEntityAccess.stamina_ratio(c)
		var arm_part: String = CombatantEntityAccess.get_attacking_arm(c)
		var leg_func: float = CombatantEntityAccess.get_leg_functionality(c)
		var head_rem: float = -1.0
		if node != null:
			var head_max: float = float(node.body_max.get(BodyPartConstants.PART_HEAD, 1))
			var head_cut: float = float(node.body_cutting.get(BodyPartConstants.PART_HEAD, 0.0))
			var head_blunt: float = float(node.body_blunt.get(BodyPartConstants.PART_HEAD, 0.0))
			head_rem = (head_cut + head_blunt) / maxf(head_max * 2.0, 1.0)
		var blood: float = -1.0
		if node != null and "blood_volume" in node:
			blood = float(node.blood_volume)
		var cons: float = -1.0
		if node != null and "consciousness" in node:
			cons = float(node.consciousness)
		row += " | %s st=%-12s ga=%4.1f sta=%.2f arm=%-6s leg=%.2f hd=%.2f bl=%.1f cn=%.1f" % [
			sd, st, gauge, sta, arm_part, leg_func, head_rem, blood, cons,
		]
	var evs := ""
	for ev in mgr.event_queue:
		if ev is not Dictionary:
			continue
		var cid: int = int(ev.get(DataKeys.EVENT_COMBATANT_ID, -1))
		var who: String = "player" if cid == 0 else "enemy"
		var etype: String = str(ev.get(DataKeys.EVENT_TYPE, ""))
		evs += " [%s:%s@%.1f]" % [who, etype, float(ev.get(DataKeys.EVENT_RESOLVE_AT, 0.0))]
	row += " | Q:%s" % evs
	print(row)


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
		var wounds := ""
		for key in node.wounds:
			wounds += " %s:%s" % [str(key).left(10), str(node.wounds[key])]
		print("STALL_DIAG_END %s cons=%.1f blood=%.1f parts:%s wounds:%s" % [sd, cons, blood, parts, wounds])
