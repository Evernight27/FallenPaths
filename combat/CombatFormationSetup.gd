class_name CombatFormationSetup
extends RefCounted

## Build side formations from presets and assign rank/file from spawn order.


static func build_formations_and_assign_slots(
    manager: Node, player_formation: Dictionary, enemy_formation: Dictionary
) -> void:
    var player_count: int = 0
    var enemy_count: int = 0
    for c in manager.combatants:
        if CombatantEntityAccess.is_player_side(c):
            player_count += 1
        else:
            enemy_count += 1
    var p_preset: Dictionary = player_formation
    var e_preset: Dictionary = enemy_formation
    if p_preset.is_empty():
        p_preset = FormationPreset.default_for_count(player_count)
    if e_preset.is_empty():
        e_preset = FormationPreset.default_for_count(enemy_count)
    var p_files: int = p_preset.get(DataKeys.FRONT_COUNT, p_preset.get(DataKeys.FORMATION_FILES, 1))
    var p_ranks: int = p_preset.get(DataKeys.FORMATION_RANKS, 1)
    var e_files: int = e_preset.get(DataKeys.FRONT_COUNT, e_preset.get(DataKeys.FORMATION_FILES, 1))
    var e_ranks: int = e_preset.get(DataKeys.FORMATION_RANKS, 1)
    if p_preset.has("front_count") or not p_preset.has("ranks"):
        p_ranks = int(ceilf(float(maxi(1, player_count)) / float(maxi(1, p_files))))
    if e_preset.has("front_count") or not e_preset.has("ranks"):
        e_ranks = int(ceilf(float(maxi(1, enemy_count)) / float(maxi(1, e_files))))
    manager.formations[CombatConstants.SIDE_PLAYER] = {
        DataKeys.FORMATION_FILES: p_files,
        DataKeys.FORMATION_RANKS: p_ranks,
        DataKeys.FORMATION_DENSITY: p_preset.get(DataKeys.FORMATION_DENSITY, "normal"),
        "side": CombatConstants.SIDE_PLAYER,
        "slots": {},
        "slot_obstacles": {},
        "zone_control": {},
        DataKeys.FORMATION_LINE_COHESION: 1.0,
        DataKeys.FORMATION_ENGAGEMENT_POSTURE: CombatConstants.ENGAGEMENT_POSTURE_LINE,
        DataKeys.FORMATION_MORALE_COHESION_FACTOR: 1.0,
        CombatConstants.FORMATION_KEY_STANDING_AT_START: 0,
        DataKeys.FORMATION_DISCIPLINE_POSTURE_ENTER_DELTA: p_preset.get(DataKeys.FORMATION_DISCIPLINE_POSTURE_ENTER_DELTA, 0.0),
        DataKeys.FORMATION_DISCIPLINE_POSTURE_LEAVE_DELTA: p_preset.get(DataKeys.FORMATION_DISCIPLINE_POSTURE_LEAVE_DELTA, 0.0),
        DataKeys.FORMATION_LINE_DISCIPLINE: str(p_preset.get(DataKeys.FORMATION_LINE_DISCIPLINE, "")),
        CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE:
        CombatConstants.normalize_spear_lane_profile(
            p_preset.get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, "")
        ),
    }
    manager.formations[CombatConstants.SIDE_ENEMY] = {
        DataKeys.FORMATION_FILES: e_files,
        DataKeys.FORMATION_RANKS: e_ranks,
        DataKeys.FORMATION_DENSITY: e_preset.get(DataKeys.FORMATION_DENSITY, "normal"),
        "side": CombatConstants.SIDE_ENEMY,
        "slots": {},
        "slot_obstacles": {},
        "zone_control": {},
        DataKeys.FORMATION_LINE_COHESION: 1.0,
        DataKeys.FORMATION_ENGAGEMENT_POSTURE: CombatConstants.ENGAGEMENT_POSTURE_LINE,
        DataKeys.FORMATION_MORALE_COHESION_FACTOR: 1.0,
        CombatConstants.FORMATION_KEY_STANDING_AT_START: 0,
        DataKeys.FORMATION_DISCIPLINE_POSTURE_ENTER_DELTA: e_preset.get(DataKeys.FORMATION_DISCIPLINE_POSTURE_ENTER_DELTA, 0.0),
        DataKeys.FORMATION_DISCIPLINE_POSTURE_LEAVE_DELTA: e_preset.get(DataKeys.FORMATION_DISCIPLINE_POSTURE_LEAVE_DELTA, 0.0),
        DataKeys.FORMATION_LINE_DISCIPLINE: str(e_preset.get(DataKeys.FORMATION_LINE_DISCIPLINE, "")),
        CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE:
        CombatConstants.normalize_spear_lane_profile(
            e_preset.get(CombatConstants.FORMATION_KEY_SPEAR_LANE_PROFILE, "")
        ),
    }
    var form_player: Dictionary = manager.formations[CombatConstants.SIDE_PLAYER]
    var form_enemy: Dictionary = manager.formations[CombatConstants.SIDE_ENEMY]
    var pi: int = 0
    var ei: int = 0
    for c in manager.combatants:
        if CombatantEntityAccess.is_player_side(c):
            var r: int = int(floorf(pi / float(p_files)))
            var f: int = pi % p_files
            c.rank = r
            c.file = f
            c.formation_id = CombatConstants.SIDE_PLAYER
            FormationSlots.slot_set_single(
                FormationSlots.formation_slots_dict(form_player), Vector2i(r, f), CombatantEntityAccess.id_int(c)
            )
            pi += 1
        else:
            var r2: int = int(floorf(ei / float(e_files)))
            var f2: int = ei % e_files
            c.rank = r2
            c.file = f2
            c.formation_id = CombatConstants.SIDE_ENEMY
            FormationSlots.slot_set_single(
                FormationSlots.formation_slots_dict(form_enemy), Vector2i(r2, f2), CombatantEntityAccess.id_int(c)
            )
            ei += 1
    FormationSlots.normalize_formation_slots(form_player)
    FormationSlots.normalize_formation_slots(form_enemy)
    FormationSlots.refresh_gap_column_topology(form_player)
    FormationSlots.refresh_gap_column_topology(form_enemy)
    # ZoC/bands: `CombatManager.start()` runs opposition seed + vacancy reconcile + one-shot recompute (III-4 PR2).


static func preset_for_formation_id(
    formation_id: String, player_preset: Dictionary, enemy_preset: Dictionary
) -> Dictionary:
    return player_preset if formation_id == CombatConstants.SIDE_PLAYER else enemy_preset


## Encounter doctrine first, then preset per side (preset wins). Calls **`CombatManager.set_formation_doctrine`**.
static func seed_formation_doctrine_from_encounter_and_presets(
    manager: Node, encounter: Dictionary, player_preset: Dictionary, enemy_preset: Dictionary
) -> void:
    if manager == null:
        return
    var sides: Array = [
        [
            CombatConstants.SIDE_PLAYER,
            CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER,
            CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_PLAYER_ALT,
        ],
        [
            CombatConstants.SIDE_ENEMY,
            CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY,
            CombatConstants.ENCOUNTER_KEY_FORMATION_DOCTRINE_ENEMY_ALT,
        ],
    ]
    for row in sides:
        var fid: String = str(row[0])
        var doc_enc: String = CombatConstants.encounter_formation_doctrine_string(encounter, str(row[1]), str(row[2]))
        if not doc_enc.is_empty():
            manager.set_formation_doctrine(fid, doc_enc)
        var preset: Dictionary = preset_for_formation_id(fid, player_preset, enemy_preset)
        var doc_preset: String = (
            CombatConstants
            . formation_doctrine_string_from_dict(
                preset,
                CombatConstants.FORMATION_PRESET_KEY_DOCTRINE,
                CombatConstants.FORMATION_PRESET_KEY_DOCTRINE_ALT,
            )
        )
        if not doc_preset.is_empty():
            manager.set_formation_doctrine(fid, doc_preset)


## Per **`manager.formations`** key: depth-spear AI mults + rout thresholds (encounter then preset).
static func seed_encounter_overlays_by_formation(
    manager: Node, encounter: Dictionary, player_preset: Dictionary, enemy_preset: Dictionary
) -> void:
    if manager == null or not manager.formations is Dictionary:
        return
    manager.depth_polearm_ai_doctrine_mults_by_fid.clear()
    manager.rout_thresholds_by_fid.clear()
    for fk in manager.formations.keys():
        var fid: String = str(fk)
        var preset: Dictionary = preset_for_formation_id(fid, player_preset, enemy_preset)
        manager.depth_polearm_ai_doctrine_mults_by_fid[fid] = (
            CombatConstants.depth_polearm_ai_doctrine_mults_for_encounter_and_preset(encounter, preset, fid)
        )
        manager.rout_thresholds_by_fid[fid] = (CombatConstants.rout_thresholds_for_encounter_and_preset(
            encounter, preset, fid
        ))
