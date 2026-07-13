class_name CombatantIdentityAccess
extends CombatantManagerBridge

## Identity, side, rank, file, formation, and display accessors.


static func is_living_same_side(actor: Dictionary, other: Dictionary) -> bool:
    if not alive_bool(other):
        return false
    return side_str(other) == side_str(actor)


## Same-side partner still on the field for formation moves (not fled, not scene-dead).


## Same-side partner still on the field for formation moves (not fled, not scene-dead).
static func is_available_formation_partner(actor: Dictionary, other: Dictionary) -> bool:
    return is_living_same_side(actor, other) and is_alive_in_combat(other) and is_alive_in_combat(actor)


## Ally available for medical targeting (alive, same side, on field, not unconscious).


## Ally available for medical targeting (alive, same side, on field, not unconscious).
static func is_available_medical_ally(actor: Dictionary, other: Dictionary) -> bool:
    if not is_living_same_side(actor, other):
        return false
    if not is_alive_in_combat(other):
        return false
    if is_unconscious(other):
        return false
    return true


## Alive opponent on the opposite side (incapacitated opponents still count  -  distance bands, threat scans).


## Alive opponent on the opposite side (incapacitated opponents still count  -  distance bands, threat scans).
static func is_alive_opponent_of(actor: Dictionary, other: Dictionary) -> bool:
    if not alive_bool(other):
        return false
    return side_str(other) != side_str(actor)


## Living enemy of **`actor`** (alive, on field, opposite side, not incapacitated).


## Living enemy of **`actor`** (alive, on field, opposite side, not incapacitated).
static func is_living_hostile_to(actor: Dictionary, other: Dictionary) -> bool:
    if not is_alive_opponent_of(actor, other):
        return false
    if has_left_battlefield(other):
        return false
    if is_incapacitated(other):
        return false
    return true


## Alive fighter on **`side`** ( **`CombatConstantsMisc.SIDE_PLAYER`** / **`CombatConstantsMisc.SIDE_ENEMY`** ).


## Alive fighter on **`side`** ( **`CombatConstantsMisc.SIDE_PLAYER`** / **`CombatConstantsMisc.SIDE_ENEMY`** ).
static func is_alive_on_side(combatant: Dictionary, side: String) -> bool:
    return alive_bool(combatant) and side_str(combatant) == side


## Alive on **`side`**, not incapacitated.


## Alive on **`side`**, not incapacitated.
static func is_living_on_side(combatant: Dictionary, side: String) -> bool:
    return is_alive_on_side(combatant, side) and not is_incapacitated(combatant)


## Both alive on opposite sides (incapacitated opponents still count).


## Both alive on opposite sides (incapacitated opponents still count).
static func are_alive_opponents(a: Dictionary, b: Dictionary) -> bool:
    return is_alive_opponent_of(a, b) and is_alive_opponent_of(b, a)


## Both living hostiles (alive, opposite sides, neither incapacitated).


## Both living hostiles (alive, opposite sides, neither incapacitated).
static func are_living_hostiles(a: Dictionary, b: Dictionary) -> bool:
    return is_living_hostile_to(a, b) and is_living_hostile_to(b, a)


## Both combatants alive (any side; formation partners, dual-occupancy resolve).


## Both combatants alive (any side; formation partners, dual-occupancy resolve).
static func are_both_alive(a: Dictionary, b: Dictionary) -> bool:
    return alive_bool(a) and alive_bool(b)


## Alive and not incapacitated (winner / standing counts).


## Alive and not incapacitated (winner / standing counts).
static func is_standing_combatant(combatant: Dictionary) -> bool:
    if combatant.get("combat_absent", false):
        return false
    return alive_bool(combatant) and not is_incapacitated(combatant)


## Battle `side` string match only (no alive check).


## Battle `side` string match only (no alive check).
static func is_on_side(combatant: Dictionary, side: String) -> bool:
    return side_str(combatant) == side


static func is_player_side(combatant: Dictionary) -> bool:
    return is_on_side(combatant, CombatConstantsMisc.SIDE_PLAYER)


static func is_enemy_side(combatant: Dictionary) -> bool:
    return is_on_side(combatant, CombatConstantsMisc.SIDE_ENEMY)


## IV-11: stamp flags from register node (player leader / enemy commander only).


## IV-11: stamp flags from register node (player leader / enemy commander only).
static func leader_register_flags_from_node(node: Node, side: String) -> Dictionary:
    var party_leader := false
    var enemy_leader := false
    if node != null:
        if side == CombatConstantsMisc.SIDE_PLAYER and node.get("is_party_leader") == true:
            party_leader = true
        elif side == CombatConstantsMisc.SIDE_ENEMY and node.get("is_enemy_leader") == true:
            enemy_leader = true
    return {"is_party_leader": party_leader, "is_enemy_leader": enemy_leader}


## IV-11: player party leader or enemy commander  -  instant doctrine commands + telegraph focus.


## IV-11: player party leader or enemy commander  -  instant doctrine commands + telegraph focus.
static func is_formation_command_issuer(combatant: Dictionary) -> bool:
    if combatant.is_empty():
        return false
    if is_player_side(combatant) and combatant.get("is_party_leader", false):
        return true
    if is_enemy_side(combatant) and combatant.get("is_enemy_leader", false):
        return true
    return false


## IV-11: player party leader or enemy commander  -  telegraph-matching focus + diagram callouts.


## IV-11: player party leader or enemy commander  -  telegraph-matching focus + diagram callouts.
static func is_formation_telegraph_leader(combatant: Dictionary) -> bool:
    if combatant.is_empty():
        return false
    return combatant.get("is_party_leader", false) or combatant.get("is_enemy_leader", false)


## Opponent side label for **`actor`** (`player` ->''f''s'f''s' -> `enemy`, else `player`).


## Opponent side label for **`actor`** (`player` ->''f''s'f''s' -> `enemy`, else `player`).
static func opponent_side_for(actor: Dictionary) -> String:
    return opponent_side_label(side_str(actor))


## `player` ->''f''s'f''s'? `enemy` roster / formation id flip (same strings as **`side_str`**).


## `player` ->''f''s'f''s'? `enemy` roster / formation id flip (same strings as **`side_str`**).
static func opponent_side_label(side: String) -> String:
    return (
        CombatConstantsMisc.SIDE_ENEMY if side == CombatConstantsMisc.SIDE_PLAYER else CombatConstantsMisc.SIDE_PLAYER
    )


## Resolves the health/wounds holder for a combat scene node (e.g. Character ->''f''s'f''s' -> CoreEntity). Prefers
## **`manager.get_health_entity(node)`** (see **`CombatManager`**).


## Resolves the health/wounds holder for a combat scene node (e.g. Character ->''f''s'f''s' -> CoreEntity). Prefers
## **`manager.get_health_entity(node)`** (see **`CombatManager`**).
static func formation_id_str(combatant: Dictionary) -> String:
    return combatant.get("formation_id", "")


## Battle `side` string (e.g. `player` / `enemy`); empty if unset.


## Battle `side` string (e.g. `player` / `enemy`); empty if unset.
static func side_str(combatant: Dictionary) -> String:
    return combatant.get("side", "")


## Formation `rank` index; uses `default_rank` when the key is missing.


## Formation `rank` index; uses `default_rank` when the key is missing.
static func rank_int(combatant: Dictionary, default_rank: int = 0) -> int:
    return int(combatant.get("rank", default_rank))


## Formation `file` index; uses `default_file` when the key is missing.


## Formation `file` index; uses `default_file` when the key is missing.
static func file_int(combatant: Dictionary, default_file: int = 0) -> int:
    return int(combatant.get("file", default_file))


## Lateral offset within the file column; clamped to **`CombatConstantsFormation.LANE_OFFSET_ABS_MAX`**.


## Lateral offset within the file column; clamped to **`CombatConstantsFormation.LANE_OFFSET_ABS_MAX`**.
static func lane_offset_float(combatant: Dictionary) -> float:
    return clampf(
        float(combatant.get("lane_offset", CombatConstantsFormation.LANE_OFFSET_DEFAULT)),
        -CombatConstantsFormation.LANE_OFFSET_ABS_MAX,
        CombatConstantsFormation.LANE_OFFSET_ABS_MAX
    )


## Monotonic combat clock on the manager (`0` when missing).


## Monotonic combat clock on the manager (`0` when missing).
static func distance_to_opponent_band(
    actor: Dictionary, opponent_id: int, default_band: String = CombatConstantsDistance.DISTANCE_LONG
) -> String:
    return str(nested_dictionary_read(actor, "distance_to").get(opponent_id, default_band))


## Combatant `id`; uses `default_id` when missing (common default: -1).


## Combatant `id`; uses `default_id` when missing (common default: -1).
static func id_int(combatant: Dictionary, default_id: int = -1) -> int:
    return int(combatant.get("id", default_id))


## `alive` flag; uses `default_alive` when missing (`false` for combat rules; `true` when absent should count as
## living).


## `alive` flag; uses `default_alive` when missing (`false` for combat rules; `true` when absent should count as
## living).
static func tactical_penetration_depth_int(combatant: Dictionary) -> int:
    return combatant.get("tactical_penetration_depth", 0)


## `stats` sub-dictionary (strength, agility, ...). Empty if missing or wrong type.
## May alias `combatant["stats"]`  -  do not replace the combatant's stats reference from call sites.


## `stats` sub-dictionary (strength, agility, ...). Empty if missing or wrong type.
## May alias `combatant["stats"]`  -  do not replace the combatant's stats reference from call sites.
static func stats_dict(combatant: Dictionary) -> Dictionary:
    var s: Variant = combatant.get("stats", null)
    if s is Dictionary:
        return s
    return {}


## Turn / action gauge (readiness), typically 0 - 100.


## Turn / action gauge (readiness), typically 0 - 100.
static func get_display_name(combatant: Variant, fallback_id: int = -1) -> String:
    if combatant == null or not (combatant is Dictionary):
        return "id:%d" % fallback_id
    var node = node_variant(combatant)
    if node != null:
        return str(node.name)
    return "id:%d" % id_int(combatant, fallback_id)


## Returns true if combatant's node has a weapon.


## Returns true if combatant's node has a weapon.
static func sync_close_distance_pair(atk: Dictionary, tgt: Dictionary, attacker_id: int, target_id: int) -> void:
    nested_dictionary_for_mutation(atk, "distance_to")[target_id] = CombatConstantsDistance.DISTANCE_CLOSE
    nested_dictionary_for_mutation(tgt, "distance_to")[attacker_id] = CombatConstantsDistance.DISTANCE_CLOSE


static func formation_morale_cohesion_factor(manager: Node, c: Dictionary) -> float:
    if manager == null or not manager.get("formations"):
        return 1.0
    var fid: String = formation_id_str(c)
    if fid.is_empty():
        return 1.0
    var form: Dictionary = _get_formation_slots().formation_record_for_manager(manager, fid)
    return clampf(form.get("morale_cohesion_factor", 1.0), CombatConstantsEngagement.MORALE_COHESION_FACTOR_MIN, 1.0)

## Returns leg functionality 0 - 1. Default 1.0 if unavailable.

## Returns leg functionality 0 - 1. Default 1.0 if unavailable.
