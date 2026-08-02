extends SceneTree
## Diagnostic: DAGGER-vs-DAGGER duels (same seeds as probe_fight reps) printing every
## `[Combat.Debug] dmg` chain line (ke_j / wuf / v_final / v_base / pre_armor / cut / blunt / pen)
## plus `[Combat.Harness] hit_resolve` so the per-hit damage collapse can be root-caused.

const TICK_DT := 0.05
const MAX_SEC := 90.0

const _Helpers := preload("res://harness/d001/D001RunnerHelpers.gd")
const _SoakPresets := preload("res://world/SoakEncounterPresets.gd")


func _init() -> void:
	CombatConstants.set_combat_dev_verbose_override(true)
	for rep in [0, 1, 2]:
		seed(hash("probe_fight_DAGGER_%d" % rep) & 0x7FFFFFFF)
		var mgr: Node = _start_duel()
		var elapsed := _drive_fight(mgr)
		print(
			"DAGGER_CHAIN rep=%d duration_s=%.1f medical=%s"
			% [rep, elapsed, "yes" if bool(mgr.medical_phase) else "no"]
		)
		_dump_end_state(mgr)
		CombatRegressionHarness._free_manager(mgr)
	CombatConstants.clear_combat_dev_verbose_override()
	quit(0)


func _start_duel() -> Node:
	var mgr: Node = CombatManager.new()
	mgr.encounter = {
		_SoakPresets.ENCOUNTER_KEY_SOAK_PRESET_ID: "7v7",
		"mood_bias_player": 50.0,
		"mood_bias_enemy": 50.0,
	}
	mgr.register(_Helpers._new_entity("DAGGER"), "player")
	mgr.register(_Helpers._new_entity("DAGGER"), "enemy")
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


func _dump_end_state(mgr: Node) -> void:
	for c in mgr.combatants:
		if c is not Dictionary:
			continue
		var node: Node = CombatantEntityAccess.scene_node(c)
		if node == null:
			continue
		var sd: String = CombatantEntityAccess.side_str(c)
		var blood: float = float(node.get("blood_volume")) if "blood_volume" in node else -1.0
		var cons: float = float(node.get("consciousness")) if "consciousness" in node else -1.0
		var parts := ""
		for part in [BodyPartConstants.PART_HEAD, BodyPartConstants.PART_CHEST,
				BodyPartConstants.PART_LEFT_ARM, BodyPartConstants.PART_RIGHT_ARM]:
			var cut: float = float(node.body_cutting.get(part, -1.0))
			var blunt: float = float(node.body_blunt.get(part, -1.0))
			var bone: float = float(node.bone_health.get(part, -1.0))
			var bmax: float = float(node.body_max.get(part, -1.0))
			var bmx: float = float(node.bone_max.get(part, -1.0))
			parts += " %s=cut%.1f/blunt%.1f/bone%.1f(max%.0f/bmax%.0f)" % [
				str(part).left(2), cut, blunt, bone, bmax, bmx,
			]
		var wounds := ""
		for key in node.wounds:
			wounds += " %s:%s" % [str(key).left(12), str(node.wounds[key])]
		print("DAGGER_END %s blood=%.1f cons=%.1f parts:%s wounds:%s" % [sd, blood, cons, parts, wounds])
