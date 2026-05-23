class_name CampaignEncounterBridge
extends RefCounted

## Overworld ↔ combat glue: encounter meta, living party gather, formation refresh, vitality on the map.

const _EntityTimeAdvance := preload("res://core/EntityTimeAdvance.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _FormationPreset := preload("res://combat/FormationPreset.gd")
const META_ENEMY_FORMATION := "enemy_formation"


## Apply encounter node config to world meta before **`CombatFlow.start_combat`**.
static func prepare_combat_from_encounter(world: Node2D, encounter: Node) -> void:
	if world == null or encounter == null:
		return
	if encounter.has_method("get_combat_encounter_dict"):
		var enc: Dictionary = encounter.get_combat_encounter_dict()
		if "soak_preset_id" in encounter:
			var soak_id: String = str(encounter.soak_preset_id).strip_edges()
			if not soak_id.is_empty():
				enc = enc.duplicate(true) if not enc.is_empty() else {}
				enc[SoakEncounterPresets.ENCOUNTER_KEY_SOAK_PRESET_ID] = soak_id
		if not enc.is_empty():
			world.set_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER, enc)
	if encounter.has_method("get_enemy_formation_dict"):
		var ef: Dictionary = encounter.get_enemy_formation_dict()
		if not ef.is_empty():
			world.set_meta(META_ENEMY_FORMATION, ef)
	var preset_id: String = ""
	if "soak_preset_id" in encounter:
		preset_id = str(encounter.soak_preset_id).strip_edges()
	if not preset_id.is_empty():
		SoakEncounterPresets.apply_world_post_setup(world, preset_id)
	else:
		# Random red tiles must not inherit **`dev_soak_encounter`** world meta from **`main._ready`**.
		SoakEncounterPresets.clear_world_soak_meta(world)
	refresh_party_formation_meta(world)
	SoakEncounterPresets.emit_f5_fight_enter_hint(encounter)


## Drop transient combat meta after battle (entity wounds persist on **`CoreEntity`** nodes).
static func clear_transient_combat_meta(world: Node2D) -> void:
	if world == null:
		return
	SoakEncounterPresets.clear_world_soak_meta(world)
	if world.has_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER):
		world.remove_meta(CombatConstants.WORLD_META_COMBAT_ENCOUNTER)
	if world.has_meta(META_ENEMY_FORMATION):
		world.remove_meta(META_ENEMY_FORMATION)


## After victory/defeat: refresh party formation count from living members.
static func on_return_from_combat(world: Node2D, winner: String) -> void:
	clear_transient_combat_meta(world)
	if world == null or winner != "player":
		return
	refresh_party_formation_meta(world)
	_log_party_vitality(world, "After battle")


static func can_enter_combat(world: Node2D) -> Dictionary:
	var out: Dictionary = {"ok": true, "message": ""}
	var nodes: Array = get_fightable_party_nodes(world)
	if nodes.is_empty():
		out.ok = false
		out.message = "No living party members can fight."
		return out
	var leader_ok: bool = false
	for n in nodes:
		if n != null and n.get("is_party_leader") == true:
			leader_ok = true
			break
	if not leader_ok and nodes.size() > 0:
		# Allow combat if any living member exists (solo companion edge case).
		leader_ok = true
	if not leader_ok:
		out.ok = false
		out.message = "Party leader is down."
		return out
	for n in nodes:
		if n == null:
			continue
		if n.has_method("is_unconscious") and n.is_unconscious():
			out.ok = false
			out.message = "%s is unconscious and cannot fight." % str(n.name)
			return out
	return out


static func get_fightable_party_nodes(world: Node2D) -> Array:
	var players: Array = []
	var pm = world.get_meta("party_manager", null) if world != null and world.has_meta("party_manager") else null
	if pm == null or not pm.has_method("get_members"):
		return players
	var leader_only: bool = (
		world != null
		and world.has_meta(SoakEncounterPresets.WORLD_META_PLAYER_LEADER_ONLY)
		and bool(world.get_meta(SoakEncounterPresets.WORLD_META_PLAYER_LEADER_ONLY))
	)
	for member in pm.get_members():
		var node_ref = member.get("node_ref") if member is Dictionary else null
		if not is_instance_valid(node_ref):
			continue
		if node_ref.has_method("is_dead") and (node_ref as Node).is_dead():
			continue
		if leader_only and node_ref.get("is_party_leader") != true:
			continue
		players.append(node_ref)
	if (
		world != null
		and world.has_meta(SoakEncounterPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP)
	):
		var cap: int = int(world.get_meta(SoakEncounterPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP))
		if cap > 0:
			players = _cap_fightable_party_leader_first(players, cap)
	return players


static func _cap_fightable_party_leader_first(nodes: Array, cap: int) -> Array:
	if nodes.size() <= cap:
		return nodes
	var leader: Node = null
	var rest: Array = []
	for n in nodes:
		if n == null:
			continue
		if n.get("is_party_leader") == true:
			leader = n
		else:
			rest.append(n)
	var out: Array = []
	if leader != null:
		out.append(leader)
	for n in rest:
		if out.size() >= cap:
			break
		out.append(n)
	if out.is_empty():
		return nodes.slice(0, cap)
	return out


static func refresh_party_formation_meta(world: Node2D) -> void:
	if world == null:
		return
	if (
		world.has_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION)
		and bool(world.get_meta(SoakEncounterPresets.WORLD_META_LOCK_PARTY_FORMATION))
	):
		return
	var n: int = get_fightable_party_nodes(world).size()
	if n <= 0:
		return
	var prior: Dictionary = (
		world.get_meta("party_formation", {}) if world.has_meta("party_formation") else {}
	)
	var preset: Dictionary = _FormationPreset.default_for_count(n)
	if prior.has("density"):
		preset["density"] = prior["density"]
	for key in [
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
		CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT,
		CombatConstants.FORMATION_PRESET_KEY_DEPTH_POLEARM_AI_MULTS,
		CombatConstants.FORMATION_PRESET_KEY_FLEE_LINE_COHESION_MAX,
		CombatConstants.FORMATION_PRESET_KEY_FLEE_CASUALTY_RATIO_MIN,
	]:
		if prior.has(key):
			preset[key] = prior[key]
	world.set_meta("party_formation", preset)


static func advance_party_overworld_minute(world: Node2D) -> void:
	const SECONDS_PER_MOVE: float = 60.0
	if world == null:
		return
	var to_process: Array = []
	if world.has_node("Character"):
		to_process.append(world.get_node("Character"))
	var pm = world.get_meta("party_manager", null) if world.has_meta("party_manager") else null
	if pm != null and pm.has_method("get_members"):
		for member in pm.get_members():
			var node_ref = member.get("node_ref") if member is Dictionary else null
			if (
				is_instance_valid(node_ref)
				and node_ref != world.get_node_or_null("Character")
			):
				to_process.append(node_ref)
	for entity in to_process:
		if not is_instance_valid(entity):
			continue
		_EntityTimeAdvance.advance(entity, SECONDS_PER_MOVE, true)
		if entity.has_method("ensure_consciousness_current"):
			entity.ensure_consciousness_current()


static func entity_has_untreated_wounds(entity: Node) -> bool:
	if entity == null:
		return false
	var wounded: Array = []
	if entity.has_method("get_wounded_parts"):
		wounded = entity.get_wounded_parts()
	if wounded.is_empty():
		return false
	var bandaged: Dictionary = entity.bandaged_parts if "bandaged_parts" in entity else {}
	var packed: Dictionary = entity.packed_parts if "packed_parts" in entity else {}
	var tourniqueted: Dictionary = entity.tourniquet_applied if "tourniquet_applied" in entity else {}
	for part in wounded:
		if bandaged.get(part, false) or packed.get(part, false) or tourniqueted.has(part):
			continue
		return true
	return false


static func party_has_untreated_wounds(world: Node2D) -> bool:
	for n in get_fightable_party_nodes(world):
		var entity: Node = health_entity_from_character(n)
		if entity_has_untreated_wounds(entity):
			return true
	return false


static func health_entity_from_character(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("get_medical_entity"):
		var e: Variant = node.get_medical_entity()
		return e as Node if e is Node else null
	return node


static func _log_party_vitality(world: Node2D, prefix: String) -> void:
	for n in get_fightable_party_nodes(world):
		var entity: Node = health_entity_from_character(n)
		if entity == null:
			continue
		var bleed: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
		var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
		var wounded_n: int = 0
		if entity.has_method("get_wounded_parts"):
			wounded_n = entity.get_wounded_parts().size()
		var untreated: bool = entity_has_untreated_wounds(entity)
		print(
			"[World] %s %s: blood=%d%% bleed=%.1f/s wounds=%d untreated=%s"
			% [prefix, n.name, int(bv), bleed, wounded_n, str(untreated)]
		)
