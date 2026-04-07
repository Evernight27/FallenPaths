class_name CombatFormationSetup
extends RefCounted

## Build side formations from presets and assign rank/file from spawn order.

const _FormationPreset := preload("res://combat/FormationPreset.gd")
const _FormationSlots := preload("res://combat/FormationSlots.gd")


static func build_formations_and_assign_slots(manager: Node, player_formation: Dictionary, enemy_formation: Dictionary) -> void:
	var player_count: int = 0
	var enemy_count: int = 0
	for c in manager.combatants:
		if c.side == "player":
			player_count += 1
		else:
			enemy_count += 1
	var p_preset: Dictionary = player_formation
	var e_preset: Dictionary = enemy_formation
	if p_preset.is_empty():
		p_preset = _FormationPreset.default_for_count(player_count)
	if e_preset.is_empty():
		e_preset = _FormationPreset.default_for_count(enemy_count)
	var p_files: int = p_preset.get("front_count", p_preset.get("files", 1))
	var p_ranks: int = p_preset.get("ranks", 1)
	var e_files: int = e_preset.get("front_count", e_preset.get("files", 1))
	var e_ranks: int = e_preset.get("ranks", 1)
	if p_preset.has("front_count") or not p_preset.has("ranks"):
		p_ranks = int(ceilf(float(maxi(1, player_count)) / float(maxi(1, p_files))))
	if e_preset.has("front_count") or not e_preset.has("ranks"):
		e_ranks = int(ceilf(float(maxi(1, enemy_count)) / float(maxi(1, e_files))))
	manager.formations["player"] = {"files": p_files, "ranks": p_ranks, "density": p_preset.get("density", "normal"), "side": "player", "slots": {}, "slot_obstacles": {}, "zone_control": {}, "breached_files": {}}
	manager.formations["enemy"] = {"files": e_files, "ranks": e_ranks, "density": e_preset.get("density", "normal"), "side": "enemy", "slots": {}, "slot_obstacles": {}, "zone_control": {}, "breached_files": {}}
	var pi: int = 0
	var ei: int = 0
	for c in manager.combatants:
		if c.side == "player":
			var r: int = int(floorf(pi / float(p_files)))
			var f: int = pi % p_files
			c.rank = r
			c.file = f
			c.formation_id = "player"
			_FormationSlots.slot_set_single(manager.formations["player"].slots, Vector2i(r, f), c.id)
			pi += 1
		else:
			var r2: int = int(floorf(ei / float(e_files)))
			var f2: int = ei % e_files
			c.rank = r2
			c.file = f2
			c.formation_id = "enemy"
			_FormationSlots.slot_set_single(manager.formations["enemy"].slots, Vector2i(r2, f2), c.id)
			ei += 1
	_FormationSlots.normalize_formation_slots(manager.formations["player"])
	_FormationSlots.normalize_formation_slots(manager.formations["enemy"])
	manager._recompute_zoc_and_distance()
