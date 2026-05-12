extends SceneTree

const _MgrScript := preload("res://combat/CombatManager.gd")
const _Weapon := preload("res://weapon/Weapon.gd")
const _CoreEntity := preload("res://core/CoreEntity.gd")
const _TurnReadyHandler := preload("res://ui/TurnReadyHandler.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")

const DT := 0.05
const MAX_SIM_TIME_S := 120.0

func _init() -> void:
	var configs: Array = [
		{"name": "duel_1v1", "player_n": 1, "enemy_n": 1, "files": 1, "ranks": 1, "seeds": 12},
		{"name": "line_3v3", "player_n": 3, "enemy_n": 3, "files": 2, "ranks": 2, "seeds": 12},
		{"name": "line_5v5", "player_n": 5, "enemy_n": 5, "files": 3, "ranks": 2, "seeds": 12}
	]
	print("[Calib] START stamina calibration sweeps")
	for cfg in configs:
		_run_config(cfg)
	print("[Calib] DONE")
	quit()


func _run_config(cfg: Dictionary) -> void:
	var n: int = int(cfg.get("seeds", 20))
	var elapsed_sum: float = 0.0
	var ended_count: int = 0
	var min_stam_global: float = 9999.0
	var t_any_below_35_sum: float = 0.0
	var t_any_below_20_sum: float = 0.0
	var t_any_below_10_sum: float = 0.0
	var below_20_never_count: int = 0
	var avg_alive_stam_time_weighted_sum: float = 0.0
	var avg_alive_stam_time_weighted_den: float = 0.0
	for s in range(n):
		var sim: Dictionary = _run_single_sim(
			int(cfg.get("player_n", 1)),
			int(cfg.get("enemy_n", 1)),
			int(cfg.get("files", 1)),
			int(cfg.get("ranks", 1)),
			s + 1000
		)
		elapsed_sum += float(sim.get("elapsed_s", 0.0))
		if bool(sim.get("ended", false)):
			ended_count += 1
		min_stam_global = minf(min_stam_global, float(sim.get("min_stamina", 100.0)))
		var t35: float = float(sim.get("t_any_below_35", -1.0))
		var t20: float = float(sim.get("t_any_below_20", -1.0))
		var t10: float = float(sim.get("t_any_below_10", -1.0))
		t_any_below_35_sum += t35 if t35 >= 0.0 else MAX_SIM_TIME_S
		t_any_below_20_sum += t20 if t20 >= 0.0 else MAX_SIM_TIME_S
		t_any_below_10_sum += t10 if t10 >= 0.0 else MAX_SIM_TIME_S
		if t20 < 0.0:
			below_20_never_count += 1
		avg_alive_stam_time_weighted_sum += float(sim.get("avg_alive_stam_integral", 0.0))
		avg_alive_stam_time_weighted_den += float(sim.get("avg_alive_stam_integral_den", 0.0))
	var mean_elapsed: float = elapsed_sum / maxf(1.0, float(n))
	var mean_t35: float = t_any_below_35_sum / maxf(1.0, float(n))
	var mean_t20: float = t_any_below_20_sum / maxf(1.0, float(n))
	var mean_t10: float = t_any_below_10_sum / maxf(1.0, float(n))
	var avg_alive_stam: float = avg_alive_stam_time_weighted_sum / maxf(0.001, avg_alive_stam_time_weighted_den)
	print(
		"[Calib] %s seeds=%d ended=%d mean_elapsed=%.1fs min_stam=%.1f mean_t<35=%.1fs mean_t<20=%.1fs mean_t<10=%.1fs below20_never=%d avg_alive_stam=%.1f"
		% [
			str(cfg.get("name", "?")),
			n,
			ended_count,
			mean_elapsed,
			min_stam_global,
			mean_t35,
			mean_t20,
			mean_t10,
			below_20_never_count,
			avg_alive_stam
		]
	)


func _run_single_sim(player_n: int, enemy_n: int, files: int, ranks: int, seed_value: int) -> Dictionary:
	seed(seed_value)
	var mgr: Node = _MgrScript.new()
	var ready_cb := func(combatant_id: int) -> void:
		_TurnReadyHandler.handle(mgr, combatant_id)
	mgr.turn_ready.connect(ready_cb)
	for _i in range(player_n):
		mgr.register(_new_entity("SWORD"), "player")
	for _j in range(enemy_n):
		mgr.register(_new_entity("SWORD"), "enemy")
	mgr.start({"files": files, "ranks": ranks, "density": "normal"}, {"files": files, "ranks": ranks, "density": "normal"})
	var t: float = 0.0
	var min_stamina: float = 100.0
	var t_any_below_35: float = -1.0
	var t_any_below_20: float = -1.0
	var t_any_below_10: float = -1.0
	var avg_alive_stam_integral: float = 0.0
	var avg_alive_stam_integral_den: float = 0.0
	var ended: bool = false
	while t < MAX_SIM_TIME_S:
		mgr._process(DT)
		t += DT
		var winner: String = str(mgr._check_for_winner())
		var alive_count: int = 0
		var stam_sum: float = 0.0
		var any_below_35: bool = false
		var any_below_20: bool = false
		var any_below_10: bool = false
		for c in mgr.combatants:
			if not _EntityAccess.alive_bool(c):
				continue
			var s: float = _EntityAccess.stamina_float(c)
			min_stamina = minf(min_stamina, s)
			stam_sum += s
			alive_count += 1
			if s < 35.0:
				any_below_35 = true
			if s < 20.0:
				any_below_20 = true
			if s < 10.0:
				any_below_10 = true
		if alive_count > 0:
			avg_alive_stam_integral += (stam_sum / float(alive_count)) * DT
			avg_alive_stam_integral_den += DT
		if any_below_35 and t_any_below_35 < 0.0:
			t_any_below_35 = t
		if any_below_20 and t_any_below_20 < 0.0:
			t_any_below_20 = t
		if any_below_10 and t_any_below_10 < 0.0:
			t_any_below_10 = t
		if not winner.is_empty():
			ended = true
			break
	_free_manager(mgr)
	return {
		"ended": ended,
		"elapsed_s": t,
		"min_stamina": min_stamina,
		"t_any_below_35": t_any_below_35,
		"t_any_below_20": t_any_below_20,
		"t_any_below_10": t_any_below_10,
		"avg_alive_stam_integral": avg_alive_stam_integral,
		"avg_alive_stam_integral_den": avg_alive_stam_integral_den
	}


func _new_entity(weapon_id: String) -> Node:
	var e = _CoreEntity.new()
	e.apply_species()
	e.dominant_hand = "right_arm"
	e.offhand_functionality = 1.0
	var w = _Weapon.create_from_definition(weapon_id)
	if w != null:
		e.equip_weapon(w)
	return e


func _free_manager(mgr: Node) -> void:
	if mgr == null:
		return
	for c in mgr.combatants:
		var n: Node = _EntityAccess.scene_node(c)
		if n != null:
			n.queue_free()
	mgr.queue_free()
