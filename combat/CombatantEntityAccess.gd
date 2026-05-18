class_name CombatantEntityAccess
extends RefCounted

const _Bleeding := preload("res://core/BleedingConstants.gd")

## Centralized access to combatant node/entity for weapon, armor, performance, etc.
## Reduces repeated node.has_method("get_weapon") patterns across AttackResolver, DefenseChoiceResolver, etc.

## Scene `node` on the combatant dict (e.g. Character); null if missing.
static func node_variant(combatant: Dictionary) -> Variant:
	return combatant.get("node", null)


## Typed scene node (`node_variant` as `Node`). Null if missing or not a `Node`.
static func scene_node(combatant: Dictionary) -> Node:
	return node_variant(combatant) as Node


## `_get_by_id` (or test doubles) may return null or a non-dict. Use before `Dictionary` ops / `stats_dict` on lookups.
static func combatant_dict_or_empty(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v as Dictionary
	return {}


## CombatManager (or harness stub) lookup by id; `{}` when missing or unavailable.
static func manager_get_combatant(manager: Node, combatant_id: int) -> Dictionary:
	if manager == null or combatant_id < 0 or not manager.has_method("_get_by_id"):
		return {}
	return combatant_dict_or_empty(manager._get_by_id(combatant_id))


## Same as **`manager_get_combatant`**; returns `{}` when **`combatant_id < 0`**.
static func manager_get_combatant_optional(manager: Node, combatant_id: int) -> Dictionary:
	return manager_get_combatant(manager, combatant_id)


static func manager_notify_turn_ready(manager: Node, combatant_id: int) -> void:
	if manager != null and manager.has_method("notify_turn_ready"):
		manager.notify_turn_ready(combatant_id)


static func manager_notify_formation_changed(manager: Node, fid: String) -> void:
	if manager != null and manager.has_method("notify_formation_changed"):
		manager.notify_formation_changed(fid)


static func manager_notify_engagement_state_changed(
	manager: Node, fid: String, cohesion: float, posture: String
) -> void:
	if manager != null and manager.has_method("notify_engagement_state_changed"):
		manager.notify_engagement_state_changed(fid, cohesion, posture)


## Live `stats` sub-dictionary for mutation (e.g. `sync_from_entity`). Creates `combatant["stats"]` if missing or wrong type.
static func stats_dict_for_mutation(combatant: Dictionary) -> Dictionary:
	var s: Variant = combatant.get("stats", null)
	if s is Dictionary:
		return s as Dictionary
	var d: Dictionary = {}
	combatant["stats"] = d
	return d


## Nested `Dictionary` on a combatant record (e.g. `distance_to`, `close_block_until_by_target_id`).
## Avoids mutating a throwaway `{}` from `Dictionary.get(key, {})` when the field is missing or wrong-typed.
static func nested_dictionary_for_mutation(combatant: Dictionary, key: String) -> Dictionary:
	var v: Variant = combatant.get(key, null)
	if v is Dictionary:
		return v as Dictionary
	var d: Dictionary = {}
	combatant[key] = d
	return d


## Read-only nested dict: returns stored dict or `{}` without assigning `combatant[key]` (safe for pure reads when key missing / wrong-typed).
static func nested_dictionary_read(combatant: Dictionary, key: String) -> Dictionary:
	var v: Variant = combatant.get(key, null)
	if v is Dictionary:
		return v as Dictionary
	return {}


## Nested `Array` field (e.g. `failed_medical_parts`).
static func nested_array_for_mutation(combatant: Dictionary, key: String) -> Array:
	var v: Variant = combatant.get(key, null)
	if v is Array:
		return v as Array
	var a: Array = []
	combatant[key] = a
	return a


## Weapon exposes melee move ids (empty when weapon null or lacks attack list).
static func weapon_attack_types(weapon: Variant) -> Array:
	if weapon == null or not weapon.has_method("get_available_attack_types"):
		return []
	return weapon.get_available_attack_types()


static func weapon_has_attack_types(weapon: Variant) -> bool:
	return weapon != null and weapon.has_method("get_available_attack_types")


static func weapon_contact_type(
	weapon: Variant, move_id: String, default_contact: String = WeaponConstants.ATTACK_TYPE_CUT
) -> String:
	if weapon == null or not weapon.has_method("get_contact_type"):
		return default_contact
	return str(weapon.get_contact_type(move_id))


## Delegates to **`WeaponConstants.weapon_mass_kg`** (combat call sites).
static func weapon_mass_kg(weapon: Variant) -> float:
	return WeaponConstants.weapon_mass_kg(weapon)


static func parry_wobble_context(defender_weapon: Variant, parry_readiness: float) -> Dictionary:
	return {"parry_readiness": parry_readiness, "defender_mass_kg": weapon_mass_kg(defender_weapon)}


static func parry_wobble_context_for_combatant(combatant: Dictionary, parry_readiness: float) -> Dictionary:
	return parry_wobble_context(get_weapon(combatant), parry_readiness)


static func weapon_archetype_id(
	weapon: Variant, move_id: String, default_id: String = WeaponConstants.ARCHETYPE_SLASH
) -> String:
	if weapon == null or not weapon.has_method("get_archetype_id"):
		return default_id
	return str(weapon.get_archetype_id(move_id))


static func weapon_archetype_for_move(
	weapon: Variant,
	move_id: String,
	default_archetype_id: String = WeaponConstants.ARCHETYPE_SLASH
) -> Dictionary:
	return WeaponConstants.get_archetype(weapon_archetype_id(weapon, move_id, default_archetype_id))


static func weapon_has_parts(weapon: Variant) -> bool:
	return weapon != null and weapon.has_method("has_parts") and weapon.has_parts()


static func weapon_parry_strong_fraction(weapon: Variant, default_frac: float = 0.25) -> float:
	if weapon == null or not weapon.has_method("get_parry_strong_fraction"):
		return default_frac
	return float(weapon.get_parry_strong_fraction())


static func weapon_parry_part_length_cm(weapon: Variant, default_len: float = 0.0) -> float:
	if weapon == null or not weapon.has_method("get_parry_part_length_cm"):
		return default_len
	return float(weapon.get_parry_part_length_cm())


## Striking-segment mass for parry/block; falls back to total weapon mass or baseline.
static func weapon_striking_mass_kg(weapon: Variant, contact_type: String = "") -> float:
	if weapon_has_parts(weapon):
		return float(weapon.get_striking_part_mass_kg(contact_type))
	return weapon_mass_kg(weapon)


static func weapon_parry_part_mass_kg(weapon: Variant) -> float:
	if weapon_has_parts(weapon) and weapon.has_method("get_parry_part_mass_kg"):
		return float(weapon.get_parry_part_mass_kg())
	return weapon_mass_kg(weapon)


static func weapon_parry_contact_type(weapon: Variant, default_pct: String = "blade") -> String:
	if weapon == null or not weapon.has_method("get_parry_contact_type"):
		return default_pct
	return str(weapon.get_parry_contact_type())


## Cut vs blunt band for parry-speed reference (shaft/haft → blunt).
static func weapon_parry_ref_contact_type(weapon: Variant) -> String:
	var pct: String = weapon_parry_contact_type(weapon)
	if pct == "shaft" or pct == "haft":
		return WeaponConstants.ATTACK_TYPE_BLUNT
	return WeaponConstants.ATTACK_TYPE_CUT


static func weapon_impact_velocity_band_max(weapon: Variant, contact_type: String) -> float:
	const _ImpactVelocityModel := preload("res://weapon/ImpactVelocityModel.gd")
	if weapon != null and weapon.has_method("get_impact_velocity_band_m_s"):
		return float(weapon.get_impact_velocity_band_m_s(contact_type).y)
	return float(_ImpactVelocityModel.unarmed_velocity_band_m_s().y)


## Scene node lists wound parts for medical UI (Character → CoreEntity).
static func get_wounded_parts(combatant: Dictionary) -> Array:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_wounded_parts"):
		return []
	return node.get_wounded_parts()


static func scene_has_wounded_parts_listing(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	return node != null and node.has_method("get_wounded_parts")


## Scene node supports self direct-pressure while receiving care (wound list + can_apply API).
static func scene_supports_medical_pressure_listing(combatant: Dictionary) -> bool:
	return (
		scene_has_wounded_parts_listing(combatant)
		and scene_can_apply_direct_pressure_api(combatant)
	)


static func scene_can_apply_direct_pressure_api(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	return node != null and node.has_method("can_apply_direct_pressure")


## Health entity (CoreEntity) direct-pressure on `part`; false when entity or method missing.
static func entity_can_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("can_apply_direct_pressure"):
		return false
	return entity.can_apply_direct_pressure(part)


static func entity_has_direct_pressure_on_part(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("has_direct_pressure_on_part"):
		return false
	return entity.has_direct_pressure_on_part(part)


static func entity_has_wound_part(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("get_wounds"):
		return false
	return entity.get_wounds().has(part)


static func entity_get_wounded_parts(manager: Node, combatant: Dictionary) -> Array:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("get_wounded_parts"):
		return []
	return entity.get_wounded_parts()


static func entity_bleeding_rate_for_part(
	manager: Node, combatant: Dictionary, part: String
) -> float:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("get_bleeding_rate_for_part"):
		return 0.0
	return float(entity.get_bleeding_rate_for_part(part))


static func entity_can_apply_bandage(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("can_apply_bandage"):
		return false
	return entity.can_apply_bandage(part)


static func entity_can_apply_packing(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("can_apply_packing"):
		return false
	return entity.can_apply_packing(part)


static func entity_can_apply_tourniquet(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("can_apply_tourniquet"):
		return false
	return entity.can_apply_tourniquet(part)


static func entity_is_tourniquet_indicated_for_part(
	manager: Node, combatant: Dictionary, part: String
) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("is_tourniquet_indicated_for_part"):
		return false
	return entity.is_tourniquet_indicated_for_part(part)


static func entity_blood_loss_death_threshold(entity: Node) -> float:
	if entity != null and entity.has_method("_get_blood_loss_death_threshold"):
		return float(entity._get_blood_loss_death_threshold())
	return _Bleeding.BLOOD_LOSS_DEATH_THRESHOLD


static func scene_can_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("can_apply_direct_pressure"):
		return false
	return node.can_apply_direct_pressure(part)


## Wind-up completion: `apply_bandage` / `apply_packing` / `apply_tourniquet` pass `effectiveness`; other methods get `part` only.
static func entity_invoke_medical_method(
	entity: Node, method: String, part: String, effectiveness: float = 1.0
) -> Variant:
	if entity == null or method.is_empty() or not entity.has_method(method):
		return null
	match method:
		"apply_bandage", "apply_packing", "apply_tourniquet":
			return entity.call(method, part, effectiveness)
		_:
			return entity.call(method, part)


static func entity_apply_direct_pressure(manager: Node, combatant: Dictionary, part: String) -> bool:
	var entity: Node = get_entity_from_manager(manager, combatant)
	if entity == null or not entity.has_method("apply_direct_pressure"):
		return false
	return entity.apply_direct_pressure(part)


static func entity_apply_direct_pressure_from_ally(
	manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
	var tgt_entity: Node = get_entity_from_manager(manager, target)
	var performer_entity: Node = get_entity_from_manager(manager, performer)
	if tgt_entity == null or not tgt_entity.has_method("apply_direct_pressure_from_ally"):
		return false
	return tgt_entity.apply_direct_pressure_from_ally(part, performer_entity)


static func entity_stack_assist_pressure_during_ally_treatment(
	manager: Node, target: Dictionary, performer: Dictionary, part: String
) -> bool:
	var tgt_entity: Node = get_entity_from_manager(manager, target)
	var performer_entity: Node = get_entity_from_manager(manager, performer)
	if tgt_entity == null or not tgt_entity.has_method("stack_assist_pressure_during_ally_treatment"):
		return false
	return tgt_entity.stack_assist_pressure_during_ally_treatment(part, performer_entity)


static func scene_apply_direct_pressure(combatant: Dictionary, part: String) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("apply_direct_pressure"):
		return false
	return node.apply_direct_pressure(part)


static func link_performer_direct_pressure_on_ally(
	manager: Node, performer: Dictionary, tgt_entity: Node, part: String
) -> void:
	var performer_entity: Node = get_entity_from_manager(manager, performer)
	if performer_entity != null and "direct_pressure_on_ally" in performer_entity:
		performer_entity.direct_pressure_on_ally = {"node": tgt_entity, "part": part}


static func is_applying_direct_pressure_scene(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("is_applying_direct_pressure"):
		return false
	return node.is_applying_direct_pressure()


static func get_direct_pressure_part_scene(combatant: Dictionary) -> String:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_direct_pressure_part"):
		return ""
	return str(node.get_direct_pressure_part())


static func clear_direct_pressure_scene(combatant: Dictionary) -> void:
	var node = node_variant(combatant)
	if node != null and node.has_method("clear_direct_pressure"):
		node.clear_direct_pressure()


## Returns weapon from combatant's node, or null if node lacks get_weapon or is null.
static func get_weapon(combatant: Dictionary) -> Variant:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_weapon"):
		return null
	return node.get_weapon()


## Abstract weapon reach in meters; **`default_reach`** when no weapon (listing uses **0**, contests often **1.5**).
static func weapon_melee_reach(combatant: Dictionary, default_reach: float = 1.5) -> float:
	var weapon: Variant = get_weapon(combatant)
	if weapon == null:
		return default_reach
	return float(weapon.melee_range)


## Living ally on **`actor`**'s side (alive, same side).
static func is_living_same_side(actor: Dictionary, other: Dictionary) -> bool:
	if not alive_bool(other):
		return false
	return side_str(other) == side_str(actor)


## Alive opponent on the opposite side (incapacitated opponents still count — distance bands, intruder scans).
static func is_alive_opponent_of(actor: Dictionary, other: Dictionary) -> bool:
	if not alive_bool(other):
		return false
	return side_str(other) != side_str(actor)


## Living enemy of **`actor`** (alive, opposite side, not incapacitated).
static func is_living_hostile_to(actor: Dictionary, other: Dictionary) -> bool:
	if not is_alive_opponent_of(actor, other):
		return false
	if is_incapacitated(other):
		return false
	return true


## Alive fighter on **`side`** ( **`"player"`** / **`"enemy"`** ).
static func is_alive_on_side(combatant: Dictionary, side: String) -> bool:
	return alive_bool(combatant) and side_str(combatant) == side


## Alive on **`side`**, not incapacitated.
static func is_living_on_side(combatant: Dictionary, side: String) -> bool:
	return is_alive_on_side(combatant, side) and not is_incapacitated(combatant)


## Both alive on opposite sides (incapacitated opponents still count).
static func are_alive_opponents(a: Dictionary, b: Dictionary) -> bool:
	return is_alive_opponent_of(a, b) and is_alive_opponent_of(b, a)


## Both living hostiles (alive, opposite sides, neither incapacitated).
static func are_living_hostiles(a: Dictionary, b: Dictionary) -> bool:
	return is_living_hostile_to(a, b) and is_living_hostile_to(b, a)


## Both combatants alive (any side; formation partners, dual-occupancy resolve).
static func are_both_alive(a: Dictionary, b: Dictionary) -> bool:
	return alive_bool(a) and alive_bool(b)


## Alive and not incapacitated (winner / standing counts).
static func is_standing_combatant(combatant: Dictionary) -> bool:
	if bool(combatant.get("combat_absent", false)):
		return false
	return alive_bool(combatant) and not is_incapacitated(combatant)


## Battle `side` string match only (no alive check).
static func is_on_side(combatant: Dictionary, side: String) -> bool:
	return side_str(combatant) == side


static func is_player_side(combatant: Dictionary) -> bool:
	return is_on_side(combatant, "player")


static func is_enemy_side(combatant: Dictionary) -> bool:
	return is_on_side(combatant, "enemy")


## Opponent side label for **`actor`** (`player` → `enemy`, else `player`).
static func opponent_side_for(actor: Dictionary) -> String:
	return opponent_side_label(side_str(actor))


## `player` ↔ `enemy` roster / formation id flip (same strings as **`side_str`**).
static func opponent_side_label(side: String) -> String:
	return "enemy" if str(side) == "player" else "player"

## Resolves the health/wounds holder for a combat scene node (e.g. Character → CoreEntity). Prefers **`manager.get_health_entity(node)`** (see **`CombatManager`**).
static func get_health_entity_from_node(manager: Node, node: Node) -> Node:
	if node == null:
		return null
	if manager != null and manager.has_method("get_health_entity"):
		return manager.get_health_entity(node)
	# Test doubles / stubs without get_health_entity: prefer implementing get_health_entity on the manager.
	if manager != null and manager.has_method("_get_entity"):
		return manager._get_entity(node)
	return node


## Returns entity from combatant dict (same resolution as get_health_entity_from_node on combatant.node).
static func get_entity_from_manager(manager: Node, combatant: Dictionary) -> Node:
	return get_health_entity_from_node(manager, scene_node(combatant))


## Home roster `formation_id` as string (empty if unset). Tactical host line: `ZoneOfControl.zone_geometry_fid_str`.
static func formation_id_str(combatant: Dictionary) -> String:
	return str(combatant.get("formation_id", ""))


## Battle `side` string (e.g. `player` / `enemy`); empty if unset.
static func side_str(combatant: Dictionary) -> String:
	return str(combatant.get("side", ""))


## Formation `rank` index; uses `default_rank` when the key is missing.
static func rank_int(combatant: Dictionary, default_rank: int = 0) -> int:
	return int(combatant.get("rank", default_rank))


## Formation `file` index; uses `default_file` when the key is missing.
static func file_int(combatant: Dictionary, default_file: int = 0) -> int:
	return int(combatant.get("file", default_file))


## Lateral offset within the file column; clamped to **`CombatConstants.LANE_OFFSET_ABS_MAX`**.
static func lane_offset_float(combatant: Dictionary) -> float:
	return clampf(
		float(combatant.get("lane_offset", CombatConstants.LANE_OFFSET_DEFAULT)),
		-CombatConstants.LANE_OFFSET_ABS_MAX,
		CombatConstants.LANE_OFFSET_ABS_MAX
	)


## Monotonic combat clock on the manager (`0` when missing).
static func combat_clock_float(manager: Node) -> float:
	if manager == null:
		return 0.0
	var cc: Variant = manager.get("combat_clock")
	if cc == null:
		return 0.0
	return float(cc)


## **`combat_clock_float(manager) + offset_s`** for event `resolve_at` and cooldown stamps.
static func combat_clock_plus(manager: Node, offset_s: float) -> float:
	return combat_clock_float(manager) + offset_s


## True while combat clock is before `until`. Values below `inactive_below` are treated as off.
static func timestamp_cooldown_active(
	manager: Node, until: float, inactive_below: float = 0.0
) -> bool:
	if manager == null:
		return false
	if until < inactive_below:
		return false
	return combat_clock_float(manager) < until


## True while combat clock is before the combatant's `cooldown_key` timestamp.
## Timestamps below `inactive_below` are treated as off (e.g. `-1` for formation CDs, `0` for crash).
static func combatant_cooldown_active(
	manager: Node, combatant: Dictionary, cooldown_key: String, inactive_below: float = 0.0
) -> bool:
	if combatant.is_empty():
		return false
	return timestamp_cooldown_active(
		manager, float(combatant.get(cooldown_key, inactive_below)), inactive_below
	)


## Seconds until `until`; `0` when inactive or elapsed (for UI status lines).
static func cooldown_remaining_s(
	manager: Node, until: float, inactive_below: float = 0.0
) -> float:
	if not timestamp_cooldown_active(manager, until, inactive_below):
		return 0.0
	return until - combat_clock_float(manager)


## Opponent band from actor `distance_to` (default **LONG** when unset).
static func distance_to_opponent_band(
	actor: Dictionary, opponent_id: int, default_band: String = CombatConstants.DISTANCE_LONG
) -> String:
	return str(nested_dictionary_read(actor, "distance_to").get(opponent_id, default_band))


## Combatant `id`; uses `default_id` when missing (common default: -1).
static func id_int(combatant: Dictionary, default_id: int = -1) -> int:
	return int(combatant.get("id", default_id))


## `alive` flag; uses `default_alive` when missing (`false` for combat rules; `true` when absent should count as living).
static func alive_bool(combatant: Dictionary, default_alive: bool = false) -> bool:
	return bool(combatant.get("alive", default_alive))


## `state` string; uses `default_state` when missing.
static func state_str(combatant: Dictionary, default_state: String = "") -> String:
	return str(combatant.get("state", default_state))


## `tactical_penetration_depth` (0 if unset).
static func tactical_penetration_depth_int(combatant: Dictionary) -> int:
	return int(combatant.get("tactical_penetration_depth", 0))


## Stored `intrusion_anchor_file` (-1 when unset).
static func intrusion_anchor_file_raw_int(combatant: Dictionary) -> int:
	return int(combatant.get("intrusion_anchor_file", -1))


## Intruder lane anchor for geometry; falls back to formation `file`.
static func intrusion_anchor_or_file_int(combatant: Dictionary) -> int:
	return int(combatant.get("intrusion_anchor_file", file_int(combatant)))


## `stats` sub-dictionary (strength, agility, …). Empty if missing or wrong type.
## May alias `combatant["stats"]` — do not replace the combatant's stats reference from call sites.
static func stats_dict(combatant: Dictionary) -> Dictionary:
	var s: Variant = combatant.get("stats", null)
	if s is Dictionary:
		return s as Dictionary
	return {}


## Turn / action gauge (readiness), typically 0–100.
static func gauge_float(combatant: Dictionary, default_gauge: float = 0.0) -> float:
	return float(combatant.get("gauge", default_gauge))


## Stamina (0–`STAMINA_MAX` when key missing uses `default_if_missing`; use `0.0` when “missing = zero” for cost checks).
static func stamina_float(combatant: Dictionary, default_if_missing: float = CombatConstants.STAMINA_MAX) -> float:
	return float(combatant.get("stamina", default_if_missing))


## Combat `stance` string. Pass `default_stance` when absent key should read as empty (e.g. controlling check).
static func stance_str(combatant: Dictionary, default_stance: String = CombatConstants.STANCE_BALANCED) -> String:
	return str(combatant.get("stance", default_stance))


## Returns display name for logging/debug: node.name if available, else "id:{id}". Pass fallback_id when combatant may be null.
static func get_display_name(combatant: Variant, fallback_id: int = -1) -> String:
	if combatant == null or not (combatant is Dictionary):
		return "id:%d" % fallback_id
	var node = node_variant(combatant)
	if node != null:
		return str(node.name)
	return "id:%d" % id_int(combatant, fallback_id)

## Returns true if combatant's node has a weapon.
static func has_weapon(combatant: Dictionary) -> bool:
	return get_weapon(combatant) != null

## Returns weapon from node directly. Use when caller has node (not combatant dict).
static func get_weapon_from_node(node: Node) -> Variant:
	if node == null or not node.has_method("get_weapon"):
		return null
	return node.get_weapon()

## Returns armor slots from node. Use when caller has node (not combatant dict).
static func get_armor_slots_from_node(node: Node) -> Dictionary:
	if node == null or not node.has_method("get_armor_slots"):
		return {}
	return node.get_armor_slots()

## Returns weapon display name for UI. Empty if no weapon or node unavailable.
static func get_weapon_display_name_from_node(node: Node) -> String:
	var w = get_weapon_from_node(node)
	if w == null:
		return ""
	if "display_name" in w and w.display_name:
		return str(w.display_name)
	if "weapon_type" in w:
		return str(w.weapon_type)
	return "?"

## Returns armor piece display names for UI (e.g. ["Cuirass", "Gambeson"]).
static func get_armor_summary_from_node(node: Node) -> Array:
	var slots: Dictionary = get_armor_slots_from_node(node)
	var names: Array = []
	for part in slots.keys():
		var piece = slots[part]
		if piece != null and "display_name" in piece and piece.display_name:
			names.append(piece.display_name)
	return names


## Sum of equipped ArmorPiece.get_total_mass_kg() — formation moves, encumbrance tuning.
static func get_total_armor_mass_kg_from_node(node: Node) -> float:
	if node == null or not node.has_method("get_armor_slots"):
		return 0.0
	var slots: Dictionary = node.get_armor_slots()
	var total: float = 0.0
	for part in slots.keys():
		var piece = slots[part]
		if piece != null and piece.has_method("get_total_mass_kg"):
			total += piece.get_total_mass_kg()
	return total

## Returns performance modifier (pain/consciousness) from combatant's node. Default 1.0 if unavailable.
static func get_performance_modifier(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_performance_modifier"):
		return 1.0
	return node.get_performance_modifier()

## Returns hit-chance-specific performance modifier. Falls back to get_performance_modifier if unavailable.
static func get_hit_chance_performance_modifier(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null:
		return 1.0
	if node.has_method("get_hit_chance_performance_modifier"):
		return node.get_hit_chance_performance_modifier()
	if node.has_method("get_performance_modifier"):
		return node.get_performance_modifier()
	return 1.0

## Action-bar / gauge fill performance. Falls back to get_performance_modifier when unavailable.
static func get_action_bar_performance_modifier(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null:
		return 1.0
	if node.has_method("get_action_bar_performance_modifier"):
		return node.get_action_bar_performance_modifier()
	if node.has_method("get_performance_modifier"):
		return node.get_performance_modifier()
	return 1.0

## True when the scene node reports dead (bleed-out, fatal wound, etc.).
static func is_dead(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("is_dead"):
		return false
	return node.is_dead()


## `alive` combatant flag and not `is_dead` on the scene node.
static func is_alive_in_combat(combatant: Dictionary) -> bool:
	if bool(combatant.get("combat_absent", false)):
		return false
	return alive_bool(combatant) and not is_dead(combatant)


## Death log string from node; empty when unavailable.
static func get_death_reason(combatant: Dictionary) -> String:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_death_reason"):
		return ""
	return str(node.get_death_reason())


## Arm functionality / injury damage scale for strikes and parry capacity. Default 1.0.
static func get_attack_damage_modifier(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_attack_damage_modifier"):
		return 1.0
	return float(node.get_attack_damage_modifier())


static func has_passive_parry_reaction_time(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	return node != null and node.has_method("get_passive_parry_reaction_time")


## Passive parry reaction window (seconds). Default 0.0 when node lacks the method.
static func get_passive_parry_reaction_time(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_passive_parry_reaction_time"):
		return 0.0
	return float(node.get_passive_parry_reaction_time())


## Sets `blunt_opts["armor_resistance_rha_mm"]` when the defender node exposes armor RHA for `part`.
static func apply_armor_sharp_resistance_to_blunt_opts(
	blunt_opts: Dictionary, defender: Dictionary, part: String
) -> void:
	var node: Node = scene_node(defender)
	if node != null and node.has_method("get_armor_sharp_resistance_for_part"):
		blunt_opts["armor_resistance_rha_mm"] = node.get_armor_sharp_resistance_for_part(part)


## Returns attacking arm (e.g. "right_arm") or "" if none. Empty = no functional arm.
static func get_attacking_arm(combatant: Dictionary) -> String:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_attacking_arm"):
		return ""
	return node.get_attacking_arm()


## True when formation **retreat** (disengage swap, drag/fall_back pair, solo fall_back) is justified by injury or peril — not fatigue-only composite fitness.
static func retreat_formation_body_damage_warranted(c: Dictionary, manager: Node) -> bool:
	if c.is_empty():
		return false
	if get_attacking_arm(c).is_empty():
		return true
	var node: Variant = node_variant(c)
	if node == null:
		return false
	if get_blood_volume_from_node(node as Node) < CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX:
		return true
	if manager != null and manager.has_method("_is_in_immediate_peril") and manager._is_in_immediate_peril(c):
		return true
	return false


## Returns leg functionality 0–1. Default 1.0 if unavailable.
static func get_leg_functionality(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_leg_functionality"):
		return 1.0
	return node.get_leg_functionality()

## Returns targetable body parts array. Empty if unavailable.
static func get_targetable_parts(combatant: Dictionary) -> Array:
	return get_targetable_parts_from_node(scene_node(combatant))


static func get_targetable_parts_from_node(node: Node) -> Array:
	if node == null or not node.has_method("get_targetable_parts"):
		return []
	return node.get_targetable_parts()

## Returns true if combatant's node is incapacitated (consciousness/cowering).
static func is_incapacitated(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("is_incapacitated"):
		return false
	return node.is_incapacitated()

## True when consciousness is below incapacitation floor (unconscious; cannot act or move).
static func is_unconscious(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("is_unconscious"):
		return false
	return node.is_unconscious()

## Tier 6.1: arm loss during combat — sync cowering, cancel stale turns, abort wind-up (see **`CombatMobilityRetreat`**).
static func react_attacking_arm_lost_if_needed(manager: Node, combatant: Dictionary) -> void:
	const _MobilityRetreat := preload("res://combat/CombatMobilityRetreat.gd")
	_MobilityRetreat.react_attacking_arm_lost_if_needed(manager, combatant)


## True when unit has no functional attacking arm (cowering posture on entity).
static func is_cowering(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("is_cowering"):
		return false
	return node.is_cowering()

## True when unit can disengage via formation retreat (leg mobility + not unconscious). Cowering may qualify.
static func can_flee_or_fall_back(combatant: Dictionary) -> bool:
	var node = node_variant(combatant)
	if node == null or not node.has_method("can_flee_or_fall_back"):
		return false
	return node.can_flee_or_fall_back()

## Returns part-specific dodge modifier. Default 1.0 if unavailable.
static func get_part_dodge_modifier(combatant: Dictionary, part: String) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_part_dodge_modifier"):
		return 1.0
	return node.get_part_dodge_modifier(part)

## Returns dodge chance 0–1. Default 0.0 if unavailable.
static func get_dodge_chance(combatant: Dictionary) -> float:
	var node = node_variant(combatant)
	if node == null or not node.has_method("get_dodge_chance"):
		return 0.0
	return node.get_dodge_chance()

## Returns blood volume 0–100 from node. Default 100.0 if unavailable.
static func get_blood_volume_from_node(node: Node) -> float:
	if node == null:
		return 100.0
	if node.has_method("get_blood_volume"):
		return node.get_blood_volume()
	if "blood_volume" in node:
		return float(node.blood_volume)
	return 100.0

## Returns total bleeding rate from node. Default 0.0 if unavailable.
static func get_total_bleeding_rate_from_node(node: Node) -> float:
	if node == null:
		return 0.0
	if node.has_method("get_total_bleeding_rate"):
		return node.get_total_bleeding_rate()
	return 0.0

## Returns medical effectiveness 0–1.5 from node. Default 1.0 if unavailable.
static func get_medical_effectiveness_from_node(node: Node) -> float:
	if node == null:
		return 1.0
	if node.has_method("get_medical_effectiveness"):
		return node.get_medical_effectiveness()
	return 1.0


static func manager_schedule_event(manager: Node, ev: Dictionary) -> void:
	if manager != null and manager.has_method("_schedule_event"):
		manager._schedule_event(ev)


static func manager_skip_turn(
	manager: Node, combatant_id: int, reason: String, detail: String = ""
) -> void:
	if manager != null and manager.has_method("skip_turn"):
		manager.skip_turn(combatant_id, reason, detail)


static func manager_apply_formation_hit_reaction_if_needed(
	manager: Node, combatant_id: int, intensity: float = 0.5
) -> void:
	if manager != null and manager.has_method("apply_formation_hit_reaction_if_needed"):
		manager.apply_formation_hit_reaction_if_needed(combatant_id, intensity)

## Returns permanent bleeding rate from node. Default fallback if unavailable.
static func get_permanent_bleeding_rate_from_node(node: Node, fallback: float = 0.0) -> float:
	if node == null:
		return fallback
	if node.has_method("get_permanent_bleeding_rate"):
		return node.get_permanent_bleeding_rate()
	return fallback
