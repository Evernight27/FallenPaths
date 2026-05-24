class_name MapBleedPolicy
extends RefCounted

## Camp-2.1 map bleed policy (D-bleed B + tutorial block until first win).
## Uses `PartyRowFormatter` / `BleedingConstants` triage bands — do not retune bleed constants here.

const _Bridge := preload("res://world/CampaignEncounterBridge.gd")
const _RowFormatter := preload("res://ui/PartyRowFormatter.gd")
const _Bleeding := preload("res://core/BleedingConstants.gd")
const _EntityAccess := preload("res://combat/CombatantEntityAccess.gd")
const _CombatDebug := preload("res://combat/CombatDebug.gd")
const _CompanyState := preload("res://world/CompanyState.gd")

const POLICY_WARN_ETA := "warn_eta"
const POLICY_BLOCK := "block"
const WORLD_META_BLEED_WARN := "map_bleed_last_warn"


static func effective_policy(world: Node2D) -> String:
	if world == null:
		return POLICY_WARN_ETA
	if not _CompanyState.is_tutorial_completed(world):
		return POLICY_BLOCK
	return _CompanyState.read_stub_map_bleed_policy()


static func should_block_map_move(world: Node2D) -> bool:
	if world == null:
		return false
	if effective_policy(world) != POLICY_BLOCK:
		return false
	return _Bridge.party_has_untreated_wounds(world) or _party_has_active_bleed(world)


static func should_block_entering_combat(world: Node2D) -> bool:
	return should_block_map_move(world)


static func party_has_map_bleed_risk(world: Node2D) -> bool:
	if world == null:
		return false
	if _Bridge.party_has_untreated_wounds(world):
		return true
	return _party_has_active_bleed(world)


static func _party_has_active_bleed(world: Node2D) -> bool:
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity == null:
			continue
		if _EntityAccess.get_total_bleeding_rate_from_node(entity) > 0.0:
			return true
	return false


static func worst_triage_summary(world: Node2D) -> Dictionary:
	var worst_eta: float = INF
	var worst_name: String = ""
	var worst_bv: float = 100.0
	var worst_bleed: float = 0.0
	for n in _Bridge.get_fightable_party_nodes(world):
		var entity: Node = _Bridge.health_entity_from_character(n)
		if entity == null:
			continue
		var bv: float = _EntityAccess.get_blood_volume_from_node(entity)
		var bleed: float = _EntityAccess.get_total_bleeding_rate_from_node(entity)
		if bleed <= 0.0 and not _Bridge.entity_has_untreated_wounds(entity):
			continue
		var eta: float = _RowFormatter.seconds_to_danger_band(bv, bleed)
		if eta < worst_eta:
			worst_eta = eta
			worst_name = str(n.name)
			worst_bv = bv
			worst_bleed = bleed
	if worst_name.is_empty():
		return {}
	return {
		"name": worst_name,
		"blood_volume": worst_bv,
		"bleed_rate": worst_bleed,
		"eta_s": worst_eta,
		"triage_line": _RowFormatter.format_triage_line(worst_bv, worst_bleed),
	}


static func on_overworld_step(world: Node2D) -> void:
	if world == null or not party_has_map_bleed_risk(world):
		if world != null and world.has_meta(WORLD_META_BLEED_WARN):
			world.remove_meta(WORLD_META_BLEED_WARN)
		return
	var summary: Dictionary = worst_triage_summary(world)
	if summary.is_empty():
		return
	var line: String = str(summary.get("triage_line", ""))
	var msg: String = "Bleeding on map — %s: %s. Open Party for field care or finish treatment." % [
		str(summary.get("name", "ally")),
		line,
	]
	if world.has_meta(WORLD_META_BLEED_WARN) and str(world.get_meta(WORLD_META_BLEED_WARN)) == msg:
		return
	world.set_meta(WORLD_META_BLEED_WARN, msg)
	_CombatDebug.world_session(msg)


static func map_move_blocked_message(world: Node2D) -> String:
	var summary: Dictionary = worst_triage_summary(world)
	if summary.is_empty():
		return "Stabilize bleeding in Party before moving on the map."
	return "Stabilize first — %s: %s (Party → field care or camp)." % [
		str(summary.get("name", "ally")),
		str(summary.get("triage_line", "")),
	]


static func hud_bleed_hint(world: Node2D) -> String:
	if not party_has_map_bleed_risk(world):
		return ""
	var summary: Dictionary = worst_triage_summary(world)
	if summary.is_empty():
		return "Bleeding — open Party"
	return "Bleeding — %s" % str(summary.get("triage_line", "open Party"))
