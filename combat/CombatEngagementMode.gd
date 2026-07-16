class_name CombatEngagementMode
extends RefCounted

## Canonical engagement-mode classifier for transition-safe combat behavior.
## Modes:
## - formation: robust two-sided front line
## - skirmish: thinned/uneven line or one side missing front
## - duel: exactly one living fighter per side (`snapshot_is_true_duel`)

const _MODE_FORMATION := "formation"
const _MODE_SKIRMISH := "skirmish"
const _MODE_DUEL := "duel"
const _MODE_CACHE_META := "_engagement_mode_cached"


## Clear resolved-mode hysteresis on `CombatManager.start()` (or tests) so a new battle does not inherit prior
## `formation` stickiness.
static func clear_resolved_mode_cache(manager: Node) -> void:
    if manager != null and manager.has_meta(_MODE_CACHE_META):
        manager.remove_meta(_MODE_CACHE_META)


static func mode_code(mode_name: String) -> int:
    match mode_name:
        _MODE_FORMATION:
            return int(CombatConstants.ENGAGEMENT_MODE_CODE_FORMATION)
        _MODE_DUEL:
            return int(CombatConstants.ENGAGEMENT_MODE_CODE_DUEL)
        _:
            return int(CombatConstants.ENGAGEMENT_MODE_CODE_SKIRMISH)


## Human-readable engagement label for battle UI (resolved mode, not raw classifier).
static func mode_display_name(mode_name: String) -> String:
    match str(mode_name):
        _MODE_FORMATION:
            return "Formation line"
        _MODE_DUEL:
            return "Duel"
        _:
            return "Skirmish"


## Rank-0 **native** line for this formation: same `side` as the formation owner.
static func count_front_rank_alive(manager: Node, formation_key: String) -> int:
    var n: int = 0
    if manager == null:
        return 0
    var native_side: String = formation_key
    var form: Dictionary = FormationSlots.formation_record_for_manager(manager, formation_key)
    if not form.is_empty():
        native_side = FormationSlots.formation_side_str(form, formation_key)
    for c in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, native_side):
            continue
        if CombatantEntityAccess.formation_id_str(c) != formation_key:
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        n += 1
    return n


static func _front_files_for_side(manager: Node, side: String) -> int:
    if manager == null:
        return 1
    var form: Dictionary = FormationSlots.formation_record_for_manager(manager, side)
    if form.is_empty():
        return 1
    return maxi(1, int(form.get(DataKeys.FORMATION_FILES, 1)))


static func count_active_for_side(manager: Node, side: String) -> int:
    var n: int = 0
    if manager == null:
        return 0
    for c in manager.combatants:
        if not CombatantEntityAccess.is_living_on_side(c, side):
            continue
        n += 1
    return n


## True 1v1: exactly one living, non-incapacitated fighter per side (not 7v2 mop-up / 2v2).
static func snapshot_is_true_duel(snap: Dictionary) -> bool:
    return snap.get(DataKeys.SNAPSHOT_PLAYER_ACTIVE, 0) == 1 and snap.get(DataKeys.SNAPSHOT_ENEMY_ACTIVE, 0) == 1


## Doc-sync line for calibration audit / IV-3 worksheet.
static func iv3_doc_sync_line() -> String:
    return (
        "IV-3 true-duel: snapshot_is_true_duel=active_1v1_only "
        + "mop_up_excludes_duel skirmish_mopup_7v2=yes attrition_to_duel=yes"
    )


## Alias for harness rows that reference the longer name.
static func iv3_true_duel_doc_sync_line() -> String:
    return iv3_doc_sync_line()


static func snapshot(manager: Node) -> Dictionary:
    var p: int = count_front_rank_alive(manager, CombatConstants.SIDE_PLAYER)
    var e: int = count_front_rank_alive(manager, CombatConstants.SIDE_ENEMY)
    var p_active: int = count_active_for_side(manager, CombatConstants.SIDE_PLAYER)
    var e_active: int = count_active_for_side(manager, CombatConstants.SIDE_ENEMY)
    var pf: int = _front_files_for_side(manager, CombatConstants.SIDE_PLAYER)
    var ef: int = _front_files_for_side(manager, CombatConstants.SIDE_ENEMY)
    var p_fill: float = clampf(float(p) / float(pf), 0.0, 1.0)
    var e_fill: float = clampf(float(e) / float(ef), 0.0, 1.0)
    var raw_mode: String = _MODE_SKIRMISH
    if CombatConstants.SKIRMISH_WHEN_EITHER_SIDE_ZERO_FRONT and (p == 0 or e == 0):
        raw_mode = _MODE_SKIRMISH
    elif snapshot_is_true_duel(
        {
            "player_active": p_active,
            "enemy_active": e_active,
        }
    ):
        raw_mode = _MODE_DUEL
    elif (
        p_active >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
        and e_active >= int(CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE)
        and p >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
        and e >= int(CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE)
        and p_fill >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
        and e_fill >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
    ):
        raw_mode = _MODE_FORMATION
    return {
        "player_active": p_active,
        "enemy_active": e_active,
        "player_front": p,
        "enemy_front": e,
        "player_front_fill": p_fill,
        "enemy_front_fill": e_fill,
        "raw_mode": raw_mode,
        "raw_mode_code": mode_code(raw_mode),
    }


static func can_enter_formation_from_snapshot(snap: Dictionary) -> bool:
    return (
        snap.get(DataKeys.SNAPSHOT_PLAYER_ACTIVE, 0) >= CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE
        and snap.get(DataKeys.SNAPSHOT_ENEMY_ACTIVE, 0) >= CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE
        and snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT, 0) >= CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE
        and snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT, 0) >= CombatConstants.FORMATION_MIN_FRONT_FIGHTERS_PER_SIDE
        and snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT_FILL, 0.0) >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
        and snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT_FILL, 0.0) >= float(CombatConstants.FORMATION_MIN_FRONT_FILL_RATIO)
    )


static func can_stay_formation_from_snapshot(snap: Dictionary) -> bool:
    var min_act: int = CombatConstants.ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE
    var p: int = snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT, 0)
    var e: int = snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT, 0)
    return (
        snap.get(DataKeys.SNAPSHOT_PLAYER_ACTIVE, 0) >= min_act
        and snap.get(DataKeys.SNAPSHOT_ENEMY_ACTIVE, 0) >= min_act
        and p >= CombatConstants.FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE
        and e >= CombatConstants.FORMATION_LEAVE_MIN_FRONT_FIGHTERS_PER_SIDE
        and snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT_FILL, 0.0) >= float(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FILL_RATIO)
        and snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT_FILL, 0.0) >= float(CombatConstants.FORMATION_LEAVE_MIN_FRONT_FILL_RATIO)
        and not snapshot_is_true_duel(snap)
    )


static func engagement_mode(manager: Node) -> String:
    var snap: Dictionary = snapshot(manager)
    var raw_mode: String = str(snap.get(DataKeys.SNAPSHOT_RAW_MODE, _MODE_SKIRMISH))
    if manager == null:
        return raw_mode
    var prev_mode: String = str(manager.get_meta(_MODE_CACHE_META, ""))
    # Hysteresis: once a cohesive formation exists, do not drop it immediately near threshold edges.
    if prev_mode == _MODE_FORMATION:
        var still_has_line: bool = can_stay_formation_from_snapshot(snap)
        if still_has_line:
            manager.set_meta(_MODE_CACHE_META, _MODE_FORMATION)
            return _MODE_FORMATION
    manager.set_meta(_MODE_CACHE_META, raw_mode)
    return raw_mode


## Canonical movement policy by resolved engagement mode.
static func movement_policy(manager: Node) -> Dictionary:
    var mode_now: String = engagement_mode(manager)
    var stable_line: bool = mode_now == _MODE_FORMATION
    var rotate_player: bool = allow_rotate_file_for_formation(manager, CombatConstants.SIDE_PLAYER)
    var rotate_enemy: bool = allow_rotate_file_for_formation(manager, CombatConstants.SIDE_ENEMY)
    return {
        "mode": mode_now,
        "mode_code": mode_code(mode_now),
        DataKeys.MOVE_POLICY_ALLOW_SWAP_RANK: stable_line,
        DataKeys.MOVE_POLICY_ALLOW_DRAG_BACK: stable_line,
        DataKeys.MOVE_POLICY_ALLOW_FALL_BACK: stable_line,
        "allow_rotate_file": rotate_player or rotate_enemy,
        "allow_rotate_file_player": rotate_player,
        "allow_rotate_file_enemy": rotate_enemy,
    }


## III-4 **3b**: per-side Skirmish outnumber exception for **`rotate_file`** only (listing + resolve).
static func allow_rotate_file_for_formation(manager: Node, formation_id: String) -> bool:
    if manager == null:
        return false
    var fid: String = str(formation_id)
    if fid.is_empty():
        return false
    var mode_now: String = engagement_mode(manager)
    if mode_now == _MODE_FORMATION:
        return true
    if mode_now != _MODE_SKIRMISH:
        return false
    var our_files: int = _front_files_for_side(manager, fid)
    var opp_fid: String = (
        CombatConstants.SIDE_ENEMY if fid == CombatConstants.SIDE_PLAYER else CombatConstants.SIDE_PLAYER
    )
    var opp_files: int = _front_files_for_side(manager, opp_fid)
    return our_files > opp_files + int(CombatConstants.SKIRMISH_ROTATE_OUTNUMBER_FILE_MARGIN)


## Shared compact debug line for logs/UI/harness.
static func mode_summary_line(manager: Node) -> String:
    var snap: Dictionary = snapshot(manager)
    var mode_now: String = engagement_mode(manager)
    var mode_now_code: int = mode_code(mode_now)
    return (
        "mode=%s(%d) raw=%s(%d) active[player=%d enemy=%d] front[player=%d enemy=%d] fill[player=%.2f enemy=%.2f]"
        % [
            mode_now,
            mode_now_code,
            str(snap.get(DataKeys.SNAPSHOT_RAW_MODE, _MODE_SKIRMISH)),
            snap.get(DataKeys.SNAPSHOT_RAW_MODE_CODE, mode_code(str(snap.get(DataKeys.SNAPSHOT_RAW_MODE, _MODE_SKIRMISH)))),
            snap.get(DataKeys.SNAPSHOT_PLAYER_ACTIVE, 0),
            snap.get(DataKeys.SNAPSHOT_ENEMY_ACTIVE, 0),
            snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT, 0),
            snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT, 0),
            snap.get(DataKeys.SNAPSHOT_PLAYER_FRONT_FILL, 0.0),
            snap.get(DataKeys.SNAPSHOT_ENEMY_FRONT_FILL, 0.0),
        ]
    )
