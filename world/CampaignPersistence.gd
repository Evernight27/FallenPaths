class_name CampaignPersistence
extends RefCounted

## D-persistence P2 — single-slot autosave on settlement continue and **`CompanyState.try_advance_day`** (day tick).
## Atomic write: user://fallen_paths_slot0.json.tmp → slot0.json
## Canonical: `save_slot` . `apply_save` . `normalize_marker_kind_for_restore` . `begin_harness_isolated_save` (headless
## harness).

const SAVE_PATH := "user://fallen_paths_slot0.json"
const SAVE_VERSION := 2
const WORLD_META_CONSUMED_CONTRACT_TILES := "consumed_contract_tiles"
const WORLD_META_CAMP_HEAL_HINT_SHOWN := "camp_heal_hint_shown"

## Headless harness: isolated slot so editor / parallel Godot do not lock production `user://` path.
static var _harness_save_path: String = ""

# Runtime preload — circular dependency (CompanyState preloads CampaignPersistence).
static var _company_state: Variant = null


static func active_save_path() -> String:
    return _harness_save_path if not _harness_save_path.is_empty() else SAVE_PATH


static func active_save_tmp_path() -> String:
    var path: String = active_save_path()
    if path.ends_with(".json"):
        return path.substr(0, path.length() - 5) + ".json.tmp"
    return path + ".tmp"


static func begin_harness_isolated_save() -> void:
    _harness_save_path = "user://fallen_paths_harness_%d.json" % Time.get_ticks_usec()
    clear_slot()


static func end_harness_isolated_save() -> void:
    clear_slot()
    _harness_save_path = ""


static func _get_company_state() -> GDScript:
    if CampaignPersistence._company_state == null:
        CampaignPersistence._company_state = load("res://world/CompanyState.gd")
    return CampaignPersistence._company_state


static func has_save() -> bool:
    return FileAccess.file_exists(active_save_path())


## Pre-`marker_kind` saves may still carry removed `practice` markers — map to tutorial or paid contract.
static func normalize_marker_kind_for_restore(marker_kind: String, encounter_config: Dictionary) -> String:
    var kind: String = marker_kind.strip_edges()
    if kind == "practice":
        if encounter_config.get("tutorial", false):
            return "tutorial"
        return "contract"
    return kind


static func clear_slot() -> void:
    var path: String = active_save_path()
    var tmp: String = active_save_tmp_path()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    if FileAccess.file_exists(tmp):
        DirAccess.remove_absolute(tmp)


static func save_slot(world: Node2D) -> bool:
    if world == null:
        return false
    var roster: Array = _serialize_roster(world)
    if roster.is_empty():
        push_warning("CampaignPersistence: refuse save with empty living roster")
        return false
    var payload: Dictionary = {
        "version": SAVE_VERSION,
        "company_state": _get_company_state().get_state(world).duplicate(true),
        "player_tile": _player_tile_array(world),
        "party_formation": _serialize_party_formation(world),
        "consumed_contract_tiles": get_consumed_contract_tiles(world),
        "remaining_encounters": _serialize_remaining_encounters(world),
        "roster": roster,
        "gladiator_schools": CompanySchool.state_to_save(world),
        "camp_heal_hint_shown": bool(world.get_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, false)),
    }
    var text: String = JSON.stringify(payload, "\t")
    if not _atomic_write(text):
        push_warning("CampaignPersistence: failed to write %s" % active_save_path())
        return false
    if OperationalLog.is_play_session_active():
        (
            OperationalLog
            . play_world(
                (
                    "campaign_autosave path=%s gold=%d day=%d living=%d"
                    % [
                        active_save_path(),
                        _get_company_state().get_gold(world),
                        _get_company_state().get_day_index(world),
                        _get_company_state().count_living_roster(world),
                    ]
                )
            )
        )
    return true


static func load_save() -> Dictionary:
    if not has_save():
        return {}
    var text: String = FileAccess.get_file_as_string(active_save_path())
    var parsed: Variant = JSON.parse_string(text)
    if parsed is Dictionary and is_valid_save(parsed):
        return parsed
    return {}


static func is_valid_save(data: Dictionary) -> bool:
    if data.is_empty():
        return false
    if data.get("version", 0) != SAVE_VERSION:
        return false
    if not (data.get("company_state", {}) is Dictionary):
        return false
    var roster: Variant = data.get("roster", null)
    if roster is not Array or (roster as Array).is_empty():
        return false
    return true


static func apply_save(world: Node2D, data: Dictionary, _rng: RandomNumberGenerator, enemy_scene: PackedScene) -> void:
    if world == null or not is_valid_save(data):
        return
    var state: Variant = data.get("company_state", {})
    if state is Dictionary:
        world.set_meta(CampaignTypes.WORLD_META_COMPANY_STATE, state.duplicate(true))
    var consumed: Variant = data.get("consumed_contract_tiles", [])
    if consumed is Array:
        world.set_meta(WORLD_META_CONSUMED_CONTRACT_TILES, consumed.duplicate(true))
    world.set_meta(WORLD_META_CAMP_HEAL_HINT_SHOWN, data.get("camp_heal_hint_shown", false))
    _apply_roster(world, data.get("roster", []), _rng)
    var pf: Variant = data.get("party_formation", {})
    if pf is Dictionary and not pf.is_empty():
        world.set_meta("party_formation", pf.duplicate(true))
    _restore_remaining_encounters(world, data.get("remaining_encounters", []), enemy_scene)
    _restore_player_tile(world, data.get("player_tile", []))
    world.set_meta("camp_tile", CampaignTypes.DEFAULT_CAMP_TILE)
    CompanySchool.state_from_save(world, data.get("gladiator_schools", {}))
    _get_company_state().attach_to_world(world)
    _get_company_state().refresh_hud(world)


static func mark_consumed_contract_tile(world: Node, tile: Vector2i) -> void:
    if world == null:
        return
    var list: Array = get_consumed_contract_tiles(world)
    for entry in list:
        if entry is Array and entry.size() >= 2:
            if int(entry[0]) == tile.x and int(entry[1]) == tile.y:
                return
    list.append([tile.x, tile.y])
    world.set_meta(WORLD_META_CONSUMED_CONTRACT_TILES, list)


static func get_consumed_contract_tiles(world: Node) -> Array:
    if world == null or not world.has_meta(WORLD_META_CONSUMED_CONTRACT_TILES):
        return []
    var raw: Variant = world.get_meta(WORLD_META_CONSUMED_CONTRACT_TILES)
    return (raw as Array).duplicate(true) if raw is Array else []


static func _atomic_write(text: String) -> bool:
    var save_path: String = active_save_path()
    var tmp_path: String = active_save_tmp_path()
    var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(text)
    f.close()
    if FileAccess.file_exists(save_path):
        var removed: Error = DirAccess.remove_absolute(save_path)
        if removed != OK:
            DirAccess.remove_absolute(tmp_path)
            return false
    var renamed: Error = DirAccess.rename_absolute(tmp_path, save_path)
    if renamed != OK:
        DirAccess.remove_absolute(tmp_path)
        return false
    return true


static func _player_tile_array(world: Node2D) -> Array:
    var player: Node2D = CampaignEncounterBridge.get_player(world)
    if player == null:
        return [0, 0]
    var pos: Vector2 = player.position
    var tile: Vector2i = CampaignEncounterBridge.overworld_tile_from_position(pos)
    return [tile.x, tile.y]


static func _serialize_party_formation(world: Node2D) -> Dictionary:
    if world == null or not world.has_meta("party_formation"):
        return {}
    var raw: Variant = world.get_meta("party_formation")
    return (raw as Dictionary).duplicate(true) if raw is Dictionary else {}


static func _serialize_remaining_encounters(world: Node2D) -> Array:
    var out: Array = []
    if world == null:
        return out
    for child in world.get_children():
        if child.get_script() != EncounterNode:
            continue
        var enc: Node = child
        var tile: Vector2i = CampaignEncounterBridge.overworld_tile_from_position(enc.position)
        (
            out
            . append(
                {
                    "tile": [tile.x, tile.y],
                    "encounter_config": enc.encounter_config.duplicate(true) if "encounter_config" in enc else {},
                    "enemy_count": int(enc.enemy_count) if "enemy_count" in enc else 1,
                    "enemy_formation": enc.enemy_formation.duplicate(true) if "enemy_formation" in enc else {},
                    "contract_marker_label": str(enc.contract_marker_label) if "contract_marker_label" in enc else "",
                    "marker_kind": str(enc.marker_kind) if "marker_kind" in enc else "",
                }
            )
        )
    return out


static func _serialize_roster(world: Node2D) -> Array:
    var out: Array = []
    var pm: Variant = world.get_meta("party_manager") if world != null and world.has_meta("party_manager") else null
    if pm == null or not ("members" in pm):
        return out
    for member in pm.members:
        if member is not Dictionary:
            continue
        var node_ref: Variant = member.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        var node: Node = node_ref as Node
        if node.has_method("is_dead") and node.is_dead():
            continue
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(node)
        (
            out
            . append(
                {
                    "name": str(member.get("name", node.name)),
                    "company_mood": float(member.get("company_mood", CampaignTypes.MOOD_DEFAULT)),
                    "entity": _serialize_entity(entity),
                }
            )
        )
    return out


static func _serialize_entity(entity: Node) -> Dictionary:
    if entity == null:
        return {}
    var out: Dictionary = {
        "blood_volume": float(entity.blood_volume) if "blood_volume" in entity else 100.0,
        "wounds": _deep_dup(entity.wounds) if "wounds" in entity else {},
        "bandaged_parts": _deep_dup(entity.bandaged_parts) if "bandaged_parts" in entity else {},
        "packed_parts": _deep_dup(entity.packed_parts) if "packed_parts" in entity else {},
        "tourniquet_applied": _deep_dup(entity.tourniquet_applied) if "tourniquet_applied" in entity else {},
        "campaign_afflictions": _deep_dup(entity.campaign_afflictions) if "campaign_afflictions" in entity else [],
        "body_cutting": _deep_dup(entity.body_cutting) if "body_cutting" in entity else {},
        "body_blunt": _deep_dup(entity.body_blunt) if "body_blunt" in entity else {},
        "bone_health": _deep_dup(entity.bone_health) if "bone_health" in entity else {},
        # XCamp-4: proficiency data.
        "proficiency_bonus":
        _deep_dup(entity.get("_proficiency_bonus")) if entity.get("_proficiency_bonus") is Dictionary else {},
        "weapon_proficiency":
        _deep_dup(entity.get("_weapon_proficiency")) if entity.get("_weapon_proficiency") is Dictionary else {},
        "form_proficiency":
        _deep_dup(entity.get("_form_proficiency")) if entity.get("_form_proficiency") is Dictionary else {},
        "combat_skill_trained":
        bool(entity.get("_combat_skill_trained")) if "_combat_skill_trained" in entity else false,
        "training_pending": _deep_dup(entity.training_pending) if "training_pending" in entity else {},
        # XCamp-6: queued form/weapon camp drills (applied at next camp rest); round-trip so a save
        # between drill and rest does not lose the pending gain.
        "form_training_pending": _deep_dup(entity._form_training_pending) if "_form_training_pending" in entity else {},
        "weapon_training_pending":
        _deep_dup(entity._weapon_training_pending) if "_weapon_training_pending" in entity else {},
        "last_fought_day": int(entity.last_fought_day) if "last_fought_day" in entity else 0,
        "last_decay_day": int(entity.last_decay_day) if "last_decay_day" in entity else 0,
        "last_fought_in_combat": bool(entity.last_fought_in_combat) if "last_fought_in_combat" in entity else false,
        # XCamp-4b: persisted gladiator name so a fighter keeps their name across save/load.
        "fighter_name": str(entity.fighter_name) if "fighter_name" in entity else "",
        # XSurgeon: persisted medical-staff role tag ("", or "surgeon") survives save/load.
        "fighter_role": str(entity.fighter_role) if "fighter_role" in entity else "",
        # XCamp-5f: persisted per-fighter fame (career arc) survives save/load.
        "fame": int(entity.fame) if "fame" in entity else 0,
        "campaign_fatigue": float(entity.campaign_fatigue) if "campaign_fatigue" in entity else 0.0,
        "weapon_edge_wear": float(entity.weapon_edge_wear) if "weapon_edge_wear" in entity else 0.0,
        # Health-system clock + systemic infection state (CAMP-INF-1 / Phase A+). _game_time_seconds
        # drives all age-based wound resolution; without it, every saved wound resets to "fresh"
        # (negative age) after a load, delaying resolution (and scar minting) a full healing-duration.
        # Sepsis/tetanus are entity-level and survive the seeding wound resolving, so they must round-trip.
        "game_time_seconds": float(entity.get("_game_time_seconds")) if "_game_time_seconds" in entity else 0.0,
        "is_septic": bool(entity.get("is_septic")) if "is_septic" in entity else false,
        "sepsis_resolve_progress":
        float(entity.get("sepsis_resolve_progress")) if "sepsis_resolve_progress" in entity else 0.0,
        "sepsis_recovered": bool(entity.get("sepsis_recovered")) if "sepsis_recovered" in entity else false,
        "_sepsis_dead": bool(entity.get("_sepsis_dead")) if "_sepsis_dead" in entity else false,
        "is_tetanus": bool(entity.get("is_tetanus")) if "is_tetanus" in entity else false,
        "tetanus_incubation_days":
        float(entity.get("tetanus_incubation_days")) if "tetanus_incubation_days" in entity else -1.0,
        "tetanus_resolve_progress":
        float(entity.get("tetanus_resolve_progress")) if "tetanus_resolve_progress" in entity else 0.0,
        "_tetanus_dead": bool(entity.get("_tetanus_dead")) if "_tetanus_dead" in entity else false,
        "weapon_id": EncounterSpawner.weapon_id_from_entity(entity),
        "armor_by_part": EncounterSpawner.armor_ids_from_entity(entity),
        "armor_durability_by_part": EncounterSpawner.armor_durability_from_entity(entity),
        # XCamp-4: individual stat variance. Base stats are re-applied from species on load,
        # so the rolled per-member values must be saved to survive reload.
        "base_stats":
        {
            "strength": int(entity.strength) if "strength" in entity else 100,
            "agility": int(entity.agility) if "agility" in entity else 100,
            "intelligence": int(entity.intelligence) if "intelligence" in entity else 100,
            "endurance": int(entity.endurance) if "endurance" in entity else 100,
            "perception": int(entity.perception) if "perception" in entity else 100,
        },
    }
    if "blood_volume_ml" in entity:
        out["blood_volume_ml"] = float(entity.blood_volume_ml)
    if "blood_volume_ml_max" in entity:
        out["blood_volume_ml_max"] = float(entity.blood_volume_ml_max)
    return out


static func _apply_roster(world: Node2D, roster: Variant, rng: RandomNumberGenerator) -> void:
    if world == null or roster is not Array:
        return
    var pm: Variant = world.get_meta("party_manager") if world.has_meta("party_manager") else null
    if pm == null or not ("members" in pm):
        return
    var saved_by_name: Dictionary = {}
    for entry in roster:
        if entry is Dictionary:
            saved_by_name[entry.get("name", "")] = entry
    # XSurgeon: the dedicated Surgeon node is not added by setup_party, so a saved surgeon must be
    # re-spawned and re-registered before the per-member apply loop below.
    var saved_surgeon: Variant = saved_by_name.get("Surgeon", null)
    if saved_surgeon is Dictionary:
        var surgeon_node: Node = world.get_node_or_null("Character/Surgeon")
        if surgeon_node != null and is_instance_valid(surgeon_node):
            var already_registered: bool = false
            for m in pm.members:
                if m is Dictionary and m.get("node_ref") == surgeon_node:
                    already_registered = true
                    break
            if not already_registered:
                PlayerCompanionSetup.setup_surgeon_member(
                    surgeon_node, rng, 0, PlayerCompanionSetup.gather_living_fighter_names(world)
                )
                pm.add_member(surgeon_node)
    var to_remove: Array = []
    for member in pm.members:
        if member is not Dictionary:
            continue
        var name_s: String = member.get("name", "")
        if not saved_by_name.has(name_s):
            to_remove.append(name_s)
    for name_s in to_remove:
        if pm.has_method("remove_member_by_name"):
            pm.remove_member_by_name(name_s)
        var node: Node = world.get_node_or_null("Character/%s" % name_s)
        if node == null and name_s == "Character":
            node = world.get_node_or_null("Character")
        if name_s != "Character" and is_instance_valid(node):
            node.queue_free()
    for member in pm.members:
        if member is not Dictionary:
            continue
        var name_s: String = member.get("name", "")
        if not saved_by_name.has(name_s):
            continue
        var saved: Dictionary = saved_by_name[name_s]
        (member as Dictionary)["company_mood"] = float(saved.get("company_mood", CampaignTypes.MOOD_DEFAULT))
        var node_ref: Variant = member.get("node_ref")
        if not is_instance_valid(node_ref):
            continue
        var entity_data: Variant = saved.get("entity", {})
        if entity_data is not Dictionary:
            continue
        var entity: Node = CampaignEncounterBridge.health_entity_from_character(node_ref as Node)
        if entity != null:
            _apply_entity(entity, entity_data as Dictionary)
        _apply_equipment(node_ref as Node, entity_data as Dictionary)


static func _apply_equipment(character: Node, data: Dictionary) -> void:
    if character == null or data.is_empty():
        return
    var weapon_id: String = data.get("weapon_id", "").strip_edges()
    var armor: Variant = data.get("armor_by_part", {})
    var armor_dict: Dictionary = (armor as Dictionary).duplicate(true) if armor is Dictionary else {}
    var dur: Variant = data.get("armor_durability_by_part", {})
    var dur_dict: Dictionary = (dur as Dictionary).duplicate(true) if dur is Dictionary else {}
    EncounterSpawner.apply_equipment_snapshot(character, weapon_id, armor_dict, dur_dict)


static func _apply_entity(entity: Node, data: Dictionary) -> void:
    if entity == null or data.is_empty():
        return
    if data.has("blood_volume"):
        entity.blood_volume = data.get("blood_volume", 100.0)
    if data.has("blood_volume_ml"):
        entity.blood_volume_ml = data.get("blood_volume_ml", -1.0)
    if data.has("blood_volume_ml_max"):
        entity.blood_volume_ml_max = data.get("blood_volume_ml_max", -1.0)
    if data.has("wounds"):
        entity.wounds = _deep_dup(data.get("wounds", {}))
    if data.has("bandaged_parts"):
        entity.bandaged_parts = _deep_dup(data.get("bandaged_parts", {}))
    if data.has("packed_parts"):
        entity.packed_parts = _deep_dup(data.get("packed_parts", {}))
    if data.has("tourniquet_applied"):
        entity.tourniquet_applied = _deep_dup(data.get("tourniquet_applied", {}))
    if data.has("campaign_afflictions"):
        var aff: Array[Dictionary] = []
        for entry in data.get("campaign_afflictions", []) as Array:
            if entry is Dictionary:
                aff.append(entry.duplicate(true))
        entity.set("campaign_afflictions", aff)
    if data.has("body_cutting"):
        entity.body_cutting = _deep_dup(data.get("body_cutting", {}))
    if data.has("body_blunt"):
        entity.body_blunt = _deep_dup(data.get("body_blunt", {}))
    if data.has("bone_health"):
        entity.bone_health = _deep_dup(data.get("bone_health", {}))
    # XCamp-4: restore proficiency data.
    if data.has("proficiency_bonus"):
        var saved_prof: Dictionary = data.get("proficiency_bonus", {})
        var prof_raw: Variant = entity.get("_proficiency_bonus")
        if prof_raw is Dictionary:
            var prof_dict: Dictionary = prof_raw as Dictionary
            var prof_keys := EntityStatsUtil.PROFICIENCY_STATS
            for key in prof_keys:
                prof_dict[key] = float(saved_prof.get(key, 0.0))
    if data.has("weapon_proficiency"):
        var saved_wp: Dictionary = data.get("weapon_proficiency", {})
        var wp_raw: Variant = entity.get("_weapon_proficiency")
        if wp_raw is Dictionary:
            var wp_dict: Dictionary = wp_raw as Dictionary
            wp_dict.clear()
            for key in saved_wp:
                wp_dict[key] = float(saved_wp[key])
    if data.has("form_proficiency"):
        var saved_fp: Dictionary = data.get("form_proficiency", {})
        var fp_raw: Variant = entity.get("_form_proficiency")
        if fp_raw is Dictionary:
            var fp_dict: Dictionary = fp_raw as Dictionary
            fp_dict.clear()
            for key in saved_fp:
                fp_dict[key] = float(saved_fp[key])
    if data.has("combat_skill_trained") and "_combat_skill_trained" in entity:
        entity._combat_skill_trained = bool(data.get("combat_skill_trained", false))
    if data.has("training_pending"):
        var saved_train: Dictionary = data.get("training_pending", {})
        var train_raw: Variant = entity.get("training_pending")
        if train_raw is Dictionary:
            var train_dict: Dictionary = train_raw as Dictionary
            var prof_keys_p := EntityStatsUtil.PROFICIENCY_STATS
            for key in prof_keys_p:
                train_dict[key] = float(saved_train.get(key, 0.0))
    # XCamp-6: restore queued form/weapon drills (keyed by form/weapon id, so deep-dup without key filtering).
    if data.has("form_training_pending") and "_form_training_pending" in entity:
        entity._form_training_pending = (data.get("form_training_pending", {}) as Dictionary).duplicate(true)
    if data.has("weapon_training_pending") and "_weapon_training_pending" in entity:
        entity._weapon_training_pending = (data.get("weapon_training_pending", {}) as Dictionary).duplicate(true)
    if data.has("last_fought_day"):
        entity.last_fought_day = data.get("last_fought_day", 0)
    if data.has("last_decay_day") and "last_decay_day" in entity:
        entity.last_decay_day = int(data.get("last_decay_day", 0))
    if data.has("last_fought_in_combat"):
        entity.last_fought_in_combat = data.get("last_fought_in_combat", false)
    # XCamp-4b: restore the persisted gladiator name (stays on the fighter across save/load).
    if data.has("fighter_name") and "fighter_name" in entity:
        entity.fighter_name = str(data.get("fighter_name", ""))
    # XSurgeon: restore the persisted medical-staff role tag ("", or "surgeon").
    if data.has("fighter_role") and "fighter_role" in entity:
        entity.fighter_role = str(data.get("fighter_role", ""))
    # XCamp-5f: restore the persisted per-fighter fame (career arc).
    if data.has("fame") and "fame" in entity:
        entity.fame = int(data.get("fame", 0))
    if data.has("campaign_fatigue"):
        entity.campaign_fatigue = clampf(float(data.get("campaign_fatigue", 0.0)), 0.0, 1.0)
    if data.has("weapon_edge_wear"):
        entity.weapon_edge_wear = clampf(float(data.get("weapon_edge_wear", 0.0)), 0.0, 1.0)
    # Health-system clock + systemic infection state (CAMP-INF-1 / Phase A+). Restoring the
    # clock keeps saved wounds at their true age (otherwise _get_wound_healing_progress reads
    # a negative age and the wound behaves as freshly made).
    if data.has("game_time_seconds") and "_game_time_seconds" in entity:
        entity._game_time_seconds = maxf(0.0, float(data.get("game_time_seconds", 0.0)))
    if data.has("is_septic") and "is_septic" in entity:
        entity.is_septic = bool(data.get("is_septic", false))
    if data.has("sepsis_resolve_progress") and "sepsis_resolve_progress" in entity:
        entity.sepsis_resolve_progress = clampf(float(data.get("sepsis_resolve_progress", 0.0)), 0.0, 1.0)
    if data.has("sepsis_recovered") and "sepsis_recovered" in entity:
        entity.sepsis_recovered = bool(data.get("sepsis_recovered", false))
    if data.has("_sepsis_dead") and "_sepsis_dead" in entity:
        entity._sepsis_dead = bool(data.get("_sepsis_dead", false))
    if data.has("is_tetanus") and "is_tetanus" in entity:
        entity.is_tetanus = bool(data.get("is_tetanus", false))
    if data.has("tetanus_incubation_days") and "tetanus_incubation_days" in entity:
        entity.tetanus_incubation_days = float(data.get("tetanus_incubation_days", -1.0))
    if data.has("tetanus_resolve_progress") and "tetanus_resolve_progress" in entity:
        entity.tetanus_resolve_progress = clampf(float(data.get("tetanus_resolve_progress", 0.0)), 0.0, 1.0)
    if data.has("_tetanus_dead") and "_tetanus_dead" in entity:
        entity._tetanus_dead = bool(data.get("_tetanus_dead", false))
    # XCamp-4: restore individual stat variance (per-member base stats rolled at creation).
    # Species base was just re-applied in _ready(); overwrite with the saved varied values.
    if data.has("base_stats"):
        var bs: Dictionary = data.get("base_stats", {})
        for stat in EntityStatsUtil.PROFICIENCY_STATS:
            if stat in bs and (stat in entity):
                entity.set(stat, int(bs[stat]))
    _sync_entity_vitals(entity)


static func _sync_entity_vitals(entity: Node) -> void:
    if entity == null:
        return
    if entity.has_method("_mark_consciousness_dirty"):
        entity.call("_mark_consciousness_dirty")
    elif "_consciousness_dirty" in entity:
        entity.set("_consciousness_dirty", true)
    if entity.has_method("ensure_consciousness_current"):
        entity.ensure_consciousness_current()


static func _restore_remaining_encounters(world: Node2D, entries: Variant, enemy_scene: PackedScene) -> void:
    if world == null or entries is not Array:
        return
    for child in world.get_children():
        if child.get_script() == EncounterNode:
            child.queue_free()
    for entry in entries:
        if entry is not Dictionary:
            continue
        var tile_raw: Variant = entry.get("tile", [])
        if not (tile_raw is Array) or tile_raw.size() < 2:
            continue
        var tile := Vector2i(int(tile_raw[0]), int(tile_raw[1]))
        if not OverworldMap.is_tile_in_bounds(tile, world):
            continue
        var cfg: Dictionary = entry.get("encounter_config", {})
        var marker_kind: String = normalize_marker_kind_for_restore(entry.get("marker_kind", ""), cfg)
        (
            ContractSpawner
            . spawn_saved_encounter_at_tile(
                world,
                tile,
                cfg,
                int(entry.get("enemy_count", cfg.get("enemy_count", 1))),
                entry.get("enemy_formation", {}) as Dictionary,
                entry.get("contract_marker_label", ""),
                marker_kind,
                enemy_scene,
            )
        )


static func _restore_player_tile(world: Node2D, tile_raw: Variant) -> void:
    if world == null or tile_raw is not Array or (tile_raw as Array).size() < 2:
        return
    var tile := Vector2i(int(tile_raw[0]), int(tile_raw[1]))
    if not OverworldMap.is_tile_in_bounds(tile, world):
        return
    CampaignEncounterBridge.place_player_on_overworld_tile(world, tile)


static func _deep_dup(value: Variant) -> Variant:
    if value is Dictionary:
        return value.duplicate(true)
    if value is Array:
        return (value as Array).duplicate(true)
    return value
