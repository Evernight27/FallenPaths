class_name RotateFileDoctrineTests
extends CombatRegressionHarnessCore


## Tier 1: **`rotate_file`** listed for adjacent rank-0 allies on a multi-file line.
static func _run_rotate_file_listed_for_adjacent_front_rank_allies(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var by_file: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c):
            continue
        if EntityAccess.rank_int(c) != 0:
            continue
        by_file[EntityAccess.file_int(c)] = c
    var p0: Dictionary = by_file.get(0, {})
    var p1: Dictionary = by_file.get(1, {})
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_list: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, EntityAccess.id_int(p0))
    var saw_rotate: bool = not (
        ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, EntityAccess.id_int(p1))
        . is_empty()
    )
    _free_manager(mgr)
    if not saw_rotate:
        _fail(failures, "rotate_list: rank-0 file-0 should list rotate_file vs file-1 ally")


## Tier 1: **`CombatFormationFlow.start_rotate_file`** duration matches **`CombatFormationMoveDuration`**.


## Tier 1: **`CombatFormationFlow.start_rotate_file`** duration matches **`CombatFormationMoveDuration`**.
static func _run_rotate_file_start_sets_duration_matches_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c) or EntityAccess.rank_int(c) != 0:
            continue
        if EntityAccess.file_int(c) == 0:
            p0 = c
        elif EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_dur_flow: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    var want: float = FormationMoveDuration.estimate_rotate_file_duration_s(mgr, p0, p1)
    FormationFlow.start_rotate_file(mgr, id0, id1)
    var got: float = float(p0.get("state_duration", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(got, want):
        _fail(failures, "rotate_dur_flow: want %.4f got %.4f" % [want, got])


## Tier 1: **`handle_rotate_file_resolve`** stamps anti-thrash cooldown; rank swap must not.


## Tier 1: **`handle_rotate_file_resolve`** stamps anti-thrash cooldown; rank swap must not.
static func _run_rotate_file_resolve_stamps_rotate_cooldown(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c) or EntityAccess.rank_int(c) != 0:
            continue
        if EntityAccess.file_int(c) == 0:
            p0 = c
        elif EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_cd: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    mgr.combat_clock = 1.0
    var want_until: float = 1.0 + CombatConstants.FORMATION_ROTATE_FILE_RETRY_COOLDOWN_S
    FormationFlow.start_rotate_file(mgr, id0, id1)
    FormationFlow.handle_rotate_file_resolve(mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}})
    var cd0: float = float(p0.get("formation_rotate_file_cooldown_until", -1.0))
    var cd1: float = float(p1.get("formation_rotate_file_cooldown_until", -1.0))
    _free_manager(mgr)
    if not is_equal_approx(cd0, want_until) or not is_equal_approx(cd1, want_until):
        _fail(failures, "rotate_cd: want cooldown_until=%.3f got p0=%.3f p1=%.3f" % [want_until, cd0, cd1])


## Tier 1: rank shuffle clears stale doctrine commits; swap must not stamp rotate cooldown.


## Tier 1: rank shuffle clears stale doctrine commits; swap must not stamp rotate cooldown.
static func _run_swap_rank_resolve_clears_doctrine_without_rotate_cooldown(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var e0: Dictionary = mgr.combatants[2]
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    var eid: int = EntityAccess.id_int(e0)
    if EntityAccess.rank_int(p0) != 0 or EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_doctrine_cd: expected player rank0/rank1 same file")
        _free_manager(mgr)
        return
    mgr.combat_clock = 0.0
    TargetScoring.on_combat_commitment(mgr, id0, eid)
    TargetScoring.on_combat_commitment(mgr, id1, eid)
    FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    FormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    var bad_commit: bool = (
        int(p0.get("doctrine_target_commit_id", -2)) != -1 or int(p1.get("doctrine_target_commit_id", -2)) != -1
    )
    var bad_rotate_cd: bool = (
        p0.has("formation_rotate_file_cooldown_until") or p1.has("formation_rotate_file_cooldown_until")
    )
    _free_manager(mgr)
    if bad_commit:
        _fail(failures, "swap_doctrine_cd: doctrine_target_commit_id should clear after rank swap")
    if bad_rotate_cd:
        _fail(failures, "swap_doctrine_cd: swap_rank resolve must not stamp formation_rotate_file_cooldown_until")


## Tier 1: center rank-0 lists **`rotate_file`** vs both adjacent wing allies on a wide line.


## Tier 1: center rank-0 lists **`rotate_file`** vs both adjacent wing allies on a wide line.
static func _run_rotate_file_lists_both_adjacent_wing_partners(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 5:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 5:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 5, "ranks": 1}, {"files": 5, "ranks": 1})
    var center: Dictionary = {}
    var left_wing: Dictionary = {}
    var right_wing: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c) or EntityAccess.rank_int(c) != 0:
            continue
        match EntityAccess.file_int(c):
            1:
                left_wing = c
            2:
                center = c
            3:
                right_wing = c
    if center.is_empty() or left_wing.is_empty() or right_wing.is_empty():
        _fail(failures, "rotate_both_wings: need rank-0 at files 1/2/3")
        _free_manager(mgr)
        return
    center["gauge"] = 100.0
    left_wing["gauge"] = 100.0
    right_wing["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, EntityAccess.id_int(center))
    var saw_left: bool = not (
        ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, EntityAccess.id_int(left_wing))
        . is_empty()
    )
    var saw_right: bool = not (
        ListedActions
        . first_action_move_vs_target(acts, CombatConstants.MOVE_ID_ROTATE_FILE, EntityAccess.id_int(right_wing))
        . is_empty()
    )
    _free_manager(mgr)
    if not saw_left or not saw_right:
        _fail(
            failures,
            "rotate_both_wings: center file-2 want rotate vs wings (left=%s right=%s)" % [str(saw_left), str(saw_right)]
        )


## Tier 1: rotate anti-thrash cooldown blocks listing and resolve (dual gate).


## Tier 1: rotate anti-thrash cooldown blocks listing and resolve (dual gate).
static func _run_rotate_file_cooldown_blocks_listing_and_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c) or EntityAccess.rank_int(c) != 0:
            continue
        if EntityAccess.file_int(c) == 0:
            p0 = c
        elif EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_cd_gate: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    mgr.combat_clock = 2.0
    p0["formation_rotate_file_cooldown_until"] = mgr.combat_clock + 5.0
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, id0)
    if ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_ROTATE_FILE):
        _fail(failures, "rotate_cd_gate: rotate_file should not list during cooldown")
        _free_manager(mgr)
        return
    var ok: bool = ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_ROTATE_FILE, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "rotate_cd_gate: resolve should reject rotate_file during cooldown")


## Tier 1: completed rotate stamps reverse-pair lock so the same adjacent allies cannot immediately swap back.


## Tier 1: completed rotate stamps reverse-pair lock so the same adjacent allies cannot immediately swap back.
static func _run_rotate_file_reverse_pair_lock_blocks_re_swap(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var p0: Dictionary = {}
    var p1: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_player_side(c) or EntityAccess.rank_int(c) != 0:
            continue
        if EntityAccess.file_int(c) == 0:
            p0 = c
        elif EntityAccess.file_int(c) == 1:
            p1 = c
    if p0.is_empty() or p1.is_empty():
        _fail(failures, "rotate_reverse_lock: need rank-0 files 0 and 1")
        _free_manager(mgr)
        return
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    mgr.combat_clock = 1.0
    FormationFlow.start_rotate_file(mgr, id0, id1)
    FormationFlow.handle_rotate_file_resolve(mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1}})
    if not FormationFlow.rotate_file_reverse_pair_blocked(mgr, p0, id1):
        _fail(failures, "rotate_reverse_lock: initiator should block re-swap with partner")
        _free_manager(mgr)
        return
    if not FormationFlow.rotate_file_reverse_pair_blocked(mgr, p1, id0):
        _fail(failures, "rotate_reverse_lock: partner should block re-swap with initiator")
        _free_manager(mgr)
        return
    p0.erase("formation_rotate_file_cooldown_until")
    p1.erase("formation_rotate_file_cooldown_until")
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, id0)
    if ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_ROTATE_FILE):
        _fail(failures, "rotate_reverse_lock: rotate_file should not list same partner during lock")
        _free_manager(mgr)
        return
    var ok: bool = ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_ROTATE_FILE, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "rotate_reverse_lock: resolve should reject rotate_file with locked partner")


## Tier 1: vacancy promotion clears stale doctrine target commit.


## Tier 1: vacancy promotion clears stale doctrine target commit.
static func _run_vacancy_plug_clears_doctrine_commitment(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var front: Dictionary = mgr.combatants[0]
    var rear: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    if EntityAccess.rank_int(front) != 0 or EntityAccess.rank_int(rear) != 1:
        _fail(failures, "vacancy_doctrine: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    var rear_id: int = EntityAccess.id_int(rear)
    var enemy_id: int = EntityAccess.id_int(enemy)
    mgr.combat_clock = 0.0
    TargetScoring.on_combat_commitment(mgr, rear_id, enemy_id)
    if int(rear.get("doctrine_target_commit_id", -2)) != enemy_id:
        _fail(failures, "vacancy_doctrine: setup commit failed")
        _free_manager(mgr)
        return
    _soak_kill_combatant(mgr, EntityAccess.id_int(front))
    var snap: Dictionary = EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var bad: bool = int(rear.get("doctrine_target_commit_id", -2)) != -1
    _free_manager(mgr)
    if bad:
        _fail(failures, "vacancy_doctrine: plug promotion should clear doctrine_target_commit_id")


## Tier 1: rank/file shuffle clears stale close-attempt blocks with doctrine commit.


## Tier 1: rank/file shuffle clears stale close-attempt blocks with doctrine commit.
static func _run_formation_shuffle_clears_close_block(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var enemy: Dictionary = mgr.combatants[2]
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    var eid: int = EntityAccess.id_int(enemy)
    if EntityAccess.rank_int(p0) != 0 or EntityAccess.rank_int(p1) != 1:
        _fail(failures, "shuffle_close_block: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    mgr.combat_clock = 1.0
    var blk: Dictionary = {str(eid): mgr.combat_clock + 10.0}
    p0["close_block_until_by_target_id"] = blk
    FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    FormationFlow.handle_swap_rank_resolve(
        mgr, {"combatant_id": id0, "resolve_at": 0.0, "data": {"partner_id": id1, "move_kind": "swap_rank"}}
    )
    var after: Dictionary = p0.get("close_block_until_by_target_id", {}) as Dictionary
    _free_manager(mgr)
    if not after.is_empty():
        _fail(failures, "shuffle_close_block: close_block_until_by_target_id should clear after rank swap")


## Tier 1: pair-move abort cooldown blocks resolve (listing parity).


## Tier 1: pair-move abort cooldown blocks resolve (listing parity).
static func _run_pair_abort_cooldown_blocks_swap_rank_resolve(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    if EntityAccess.rank_int(p0) != 0 or EntityAccess.rank_int(p1) != 1:
        _fail(failures, "pair_abort_gate: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    mgr.combat_clock = 2.0
    p0["formation_pair_abort_cooldown_until"] = mgr.combat_clock + 5.0
    var ok: bool = ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_SWAP_RANK, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "pair_abort_gate: swap_rank resolve should reject during pair abort cooldown")


## Tier 1: healthy front rank does not list or resolve swap without tactical gate.


## Tier 1: healthy front rank does not list or resolve swap without tactical gate.
static func _run_swap_rank_not_listed_without_tactical_gate(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    mgr.set_meta("_engagement_mode_cached", "formation")
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    if EntityAccess.rank_int(p0) != 0 or EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_tactical_gate_list: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, id0)
    var listed: bool = ListedActions.actions_include_move_vs_target(acts, id1, CombatConstants.MOVE_ID_SWAP_RANK)
    _free_manager(mgr)
    if listed:
        _fail(failures, "swap_tactical_gate_list: healthy front should not list swap_rank without gate")


static func _run_swap_rank_resolve_rejects_without_tactical_gate(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    mgr.set_meta("_engagement_mode_cached", "formation")
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = EntityAccess.id_int(p0)
    var id1: int = EntityAccess.id_int(p1)
    if EntityAccess.rank_int(p0) != 0 or EntityAccess.rank_int(p1) != 1:
        _fail(failures, "swap_tactical_gate_resolve: expected rank0/rank1 player pair")
        _free_manager(mgr)
        return
    p0["gauge"] = 100.0
    p1["gauge"] = 100.0
    var ok: bool = ResolveAction.resolve(mgr, id0, id1, CombatConstants.MOVE_ID_SWAP_RANK, {})
    _free_manager(mgr)
    if ok:
        _fail(failures, "swap_tactical_gate_resolve: resolve should reject swap_rank without tactical gate")


## Tier 1.8: successful LONG **`resolve_close_attempt`** closes pair distance.


## Tier 1.8: successful LONG **`resolve_close_attempt`** closes pair distance.
static func _run_resolve_close_attempt_long_success_closes_distance(failures: PackedStringArray) -> void:
    seed(_HARNESS_RESTORE_GLOBAL_SEED)
    seed(0)
    var fixtures: Array = _harness_7v3_wing_rank0_fixtures()
    var mgr: Node = fixtures[0] as Node
    var p: Dictionary = fixtures[1] as Dictionary
    var en: Dictionary = fixtures[2] as Dictionary
    if p.is_empty() or en.is_empty():
        _fail(failures, "close_success: missing 7v3 wing fixtures")
        _free_manager_restore_global_rng(mgr)
        return
    var p_id: int = EntityAccess.id_int(p)
    var e_id: int = EntityAccess.id_int(en)
    _harness_bind_pair_long_band(p, en)
    if not MeleeListing.attempt_close_listed_for_pair(mgr, p, e_id, CombatConstants.DISTANCE_LONG):
        _fail(failures, "close_success: setup want listable close at LONG out of reach")
        _free_manager_restore_global_rng(mgr)
        return
    var sd: Dictionary = EntityAccess.stats_dict_for_mutation(p)
    sd["strength"] = 400.0
    var sd_e: Dictionary = EntityAccess.stats_dict_for_mutation(en)
    sd_e["agility"] = 5.0
    var cap: Array = []
    mgr.action_resolved.connect(
        func(_a: int, _t: int, result: Dictionary) -> void:
            cap.clear()
            cap.append(result)
    )
    EngagementResolver.resolve_close_attempt(mgr, p_id, e_id)
    _free_manager_restore_global_rng(mgr)
    if cap.is_empty():
        _fail(failures, "close_success: expected action_resolved")
        return
    var r: Dictionary = cap[0] as Dictionary
    if str(r.get("outcome", "")) != "close_success":
        _fail(failures, "close_success: expected close_success got %s" % str(r))
    elif (p.get("distance_to", {}) as Dictionary).get(e_id, "") != CombatConstants.DISTANCE_CLOSE:
        _fail(
            failures,
            (
                "close_success: attacker distance_to should be CLOSE got %s"
                % str((p.get("distance_to", {}) as Dictionary).get(e_id, ""))
            )
        )
    elif EntityAccess.gauge_float(p) >= 99.9:
        _fail(failures, "close_success: attacker gauge should be cleared after close attempt")


## Tier 1.10: automatic doctrine applies **`pinch_center`** on hollow enemy front when doctrine still default.


## Tier 1.10: automatic doctrine applies **`pinch_center`** on hollow enemy front when doctrine still default.
static func _run_automatic_doctrine_sets_pinch_on_hollow_when_enabled(failures: PackedStringArray) -> void:
    if not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        _fail(failures, "auto_doctrine: FEATURE_AUTOMATIC_DOCTRINE should be enabled")
        return
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    for _j in 3:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 3, "ranks": 1})
    var en_by_file: Dictionary = {}
    for c in mgr.combatants:
        if not EntityAccess.is_enemy_side(c):
            continue
        en_by_file[EntityAccess.file_int(c)] = c
    (en_by_file[1] as Dictionary)["alive"] = false
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(
            failures,
            "auto_doctrine: hollow center should set pinch_center got %s" % mgr.get_formation_doctrine("player")
        )
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_HOLD_LANE)
    CombatDoctrine.evaluate_automatic_doctrine(mgr)
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(
            failures, "auto_doctrine: must not override player hold_lane got %s" % mgr.get_formation_doctrine("player")
        )
    _free_manager(mgr)


## Tier 0: heavy armor mass slows formation-move duration estimates and hints.


## Tier 0: heavy armor mass slows formation-move duration estimates and hints.
static func _run_formation_move_duration_heavy_armor_slows_estimate(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    var ent_light := _new_entity("SWORD")
    mgr.register(ent_light, "player")
    var ent_heavy := _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    mgr.register(ent_heavy, "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var light_c: Dictionary = mgr.combatants[0]
    var heavy_c: Dictionary = mgr.combatants[1]
    for c in [light_c, heavy_c]:
        if EntityAccess.rank_int(c) != 0:
            continue
        c["gauge"] = 100.0
    var light_dur: float = FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, light_c)
    var heavy_dur: float = FormationMoveDuration.estimate_solo_fall_back_duration_s(mgr, heavy_c)
    var heavy_hint: String = FormationMoveDuration.formation_preview_tooltip_line(mgr, heavy_c)
    _free_manager(mgr)
    if heavy_dur <= light_dur * 1.08:
        _fail(failures, "form_dur_armor: heavy %.3f should exceed light %.3f" % [heavy_dur, light_dur])
    if not heavy_hint.contains("heavy armor"):
        _fail(failures, "form_dur_armor: want heavy armor in hint got '%s'" % heavy_hint)


## P4b: formation duration UI copy  -  canonical tokens, turn-display strip, ii5a-style crowded hint.


## P4b: formation duration UI copy  -  canonical tokens, turn-display strip, ii5a-style crowded hint.
static func _run_p4b_formation_duration_ui_copy_suite(failures: PackedStringArray) -> void:
    var sync_line: String = FormationMoveDuration.p4b_formation_duration_ui_copy_line()
    if not sync_line.contains("crowded lane"):
        _fail(failures, "p4b_ui: sync line missing crowded lane token")
    if not sync_line.contains("Flee: leaves field"):
        _fail(failures, "p4b_ui: sync line missing flee instant copy")
    var crowded_hint: String = FormationMoveDuration.format_duration_hint(
        CombatConstants.BASE_FALL_BACK_S * 1.35,
        CombatConstants.LANE_MOD_CROWDED,
        CombatConstants.PRESSURE_MOD_NEUTRAL,
        1.0,
        false
    )
    if not crowded_hint.contains("Formation move:") or not crowded_hint.contains("crowded lane"):
        _fail(failures, "p4b_ui: crowded sample hint want prefix+token got '%s'" % crowded_hint)
    var display: String = FormationMoveDuration.duration_hint_for_turn_display(crowded_hint)
    if display.begins_with("Formation move:"):
        _fail(failures, "p4b_ui: turn display should strip prefix got '%s'" % display)
    if not display.contains("crowded lane"):
        _fail(failures, "p4b_ui: turn display want crowded token got '%s'" % display)
    var mgr: Node = MgrScript.new()
    for _i in 4:
        mgr.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    var c: Dictionary = {}
    var ally_id: int = -1
    for raw in mgr.combatants:
        if not EntityAccess.is_player_side(raw):
            continue
        if EntityAccess.rank_int(raw) == 0 and EntityAccess.file_int(raw) == 0:
            c = raw
        elif EntityAccess.rank_int(raw) == 0 and EntityAccess.file_int(raw) == 1:
            ally_id = EntityAccess.id_int(raw)
    if c.is_empty() or ally_id < 0:
        _fail(failures, "p4b_ui: need rank-0 allies at files 0 and 1")
        _free_manager(mgr)
        return
    var form_p: Dictionary = FormationSlots.formation_record_for_manager(mgr, "player")
    form_p["slot_obstacles"] = {Vector2i(0, EntityAccess.file_int(c)): [999]}
    c["gauge"] = 100.0
    var acts: Array = ActionsBuilder.build(mgr, EntityAccess.id_int(c))
    var turn_hint: String = FormationMoveDuration.formation_turn_ready_ui_hint(acts)
    if turn_hint.contains("Formation move: Formation move:"):
        _fail(failures, "p4b_ui: turn hint should not double prefix")
    if turn_hint.is_empty() or not turn_hint.contains("crowded lane"):
        _fail(failures, "p4b_ui: turn hint want crowded lane got '%s'" % turn_hint)
    if "Formation move:" in turn_hint:
        _fail(failures, "p4b_ui: listed turn hint should use stripped duration copy got '%s'" % turn_hint)
    _free_manager(mgr)


static func _harness_iv7_fixture_combatant(ent: CoreEntity) -> Dictionary:
    return Fixtures._harness_iv7_fixture_combatant(ent)


## IV-7: full plate kit lengthens event-driven **`action_ready_cooldown`**.


## IV-7: full plate kit lengthens event-driven **`action_ready_cooldown`**.
static func _run_iv7_armor_burden_action_ready(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_armor_burden_enabled():
        _fail(failures, "iv7_armor_burden: FEATURE_ARMOR_BURDEN must be on in production")
        return
    var ent_light: CoreEntity = _new_entity("SWORD")
    var ent_heavy: CoreEntity = _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    var light_c: Dictionary = _harness_iv7_fixture_combatant(ent_light)
    var heavy_c: Dictionary = _harness_iv7_fixture_combatant(ent_heavy)
    if CombatConstants.armor_burden_mass_ratio_for_combatant(heavy_c) <= 0.35:
        _fail(failures, "iv7_armor_burden: heavy fixture should exceed ref/3 mass ratio")
        return
    var cd_light: float = EventScheduler.action_ready_cooldown(light_c)
    var cd_heavy: float = EventScheduler.action_ready_cooldown(heavy_c)
    if cd_heavy <= cd_light * 1.08:
        _fail(failures, "iv7_armor_burden: heavy cooldown want > light (heavy=%.3f light=%.3f)" % [cd_heavy, cd_light])
    var saved: bool = CombatConstants.is_feature_armor_burden_enabled()
    CombatConstants.set_feature_armor_burden_load(false)
    var cd_heavy_off: float = EventScheduler.action_ready_cooldown(heavy_c)
    CombatConstants.set_feature_armor_burden_load(saved)
    if absf(cd_heavy_off - cd_light) > 0.02:
        _fail(
            failures,
            "iv7_armor_burden: flag off heavy should match light (heavy=%.3f light=%.3f)" % [cd_heavy_off, cd_light]
        )


## IV-7: armor mass scales passive parry readiness (WAITING guard gauge path).


## IV-7: armor mass scales passive parry readiness (WAITING guard gauge path).
static func _run_iv7_armor_burden_passive_readiness(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_armor_burden_enabled():
        _fail(failures, "iv7_armor_burden_readiness: FEATURE_ARMOR_BURDEN must be on in production")
        return
    var ent_light: CoreEntity = _new_entity("SWORD")
    var ent_heavy: CoreEntity = _new_entity("SWORD")
    _harness_equip_heavy_plate_kit(ent_heavy)
    var light_c: Dictionary = _harness_iv7_fixture_combatant(ent_light)
    var heavy_c: Dictionary = _harness_iv7_fixture_combatant(ent_heavy)
    var pr_light: float = PassiveParryCtx.get_passive_parry_readiness(light_c)
    var pr_heavy: float = PassiveParryCtx.get_passive_parry_readiness(heavy_c)
    if pr_light < 0.99:
        _fail(failures, "iv7_armor_burden_readiness: light fixture want ~1.0 got %.3f" % pr_light)
        return
    if pr_heavy >= pr_light * 0.95:
        _fail(failures, "iv7_armor_burden_readiness: heavy want < light (heavy=%.3f light=%.3f)" % [pr_heavy, pr_light])
    var want_heavy: float = pr_light * CombatConstants.armor_burden_passive_readiness_mult(heavy_c)
    if absf(pr_heavy - want_heavy) > 0.02:
        _fail(failures, "iv7_armor_burden_readiness: want %.3f got %.3f" % [want_heavy, pr_heavy])


static func _harness_action_ready_resolve_at(mgr: Node, combatant_id: int) -> float:
    return Fixtures._harness_action_ready_resolve_at(mgr, combatant_id)


static func _harness_iv8_three_player_fixtures(mgr: Node) -> Array:
    return Fixtures._harness_iv8_three_player_fixtures(mgr)


## IV-8: high initiative score -> earlier first **`EVENT_ACTION_READY`** at combat start.


## IV-8: high initiative score -> earlier first **`EVENT_ACTION_READY`** at combat start.
static func _run_iv8_initiative_order_stagger(failures: PackedStringArray) -> void:
    if not CombatConstants.is_feature_initiative_order_enabled():
        _fail(failures, "iv8_initiative_order: FEATURE_INITIATIVE_ORDER must be on in production")
        return
    var mgr: Node = MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var players: Array = _harness_iv8_three_player_fixtures(mgr)
    if players.size() != 3:
        _fail(failures, "iv8_initiative_order: want 3 player fixtures got %d" % players.size())
        _free_manager(mgr)
        return
    var fast: Dictionary = mgr.combatants[0]
    var mid: Dictionary = mgr.combatants[1]
    var slow: Dictionary = mgr.combatants[2]
    EntityAccess.stats_dict_for_mutation(fast)["agility"] = 140
    EntityAccess.stats_dict_for_mutation(fast)["perception"] = 110
    EntityAccess.stats_dict_for_mutation(mid)["agility"] = 100
    EntityAccess.stats_dict_for_mutation(mid)["perception"] = 100
    EntityAccess.stats_dict_for_mutation(slow)["agility"] = 70
    EntityAccess.stats_dict_for_mutation(slow)["perception"] = 70
    mgr.event_queue.clear()
    EventScheduler.schedule_initial_action_ready_events(mgr)
    var at_fast: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(fast))
    var at_mid: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(mid))
    var at_slow: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(slow))
    _free_manager(mgr)
    if at_fast < 0.0 or at_mid < 0.0 or at_slow < 0.0:
        _fail(failures, "iv8_initiative_order: missing action_ready events")
        return
    if not (at_fast < at_mid and at_mid < at_slow):
        _fail(failures, "iv8_initiative_order: want fast<mid<slow (%.3f %.3f %.3f)" % [at_fast, at_mid, at_slow])
    var stagger_gap: float = at_mid - at_fast
    if stagger_gap < CombatConstants.INITIATIVE_ORDER_STAGGER_STEP_S * 0.5:
        _fail(failures, "iv8_initiative_order: want rank stagger gap >= step/2 got %.3f" % stagger_gap)


## IV-8: flag off  -  identical stats -> identical first resolve_at (no initiative stagger).


## IV-8: flag off  -  identical stats -> identical first resolve_at (no initiative stagger).
static func _run_iv8_initiative_order_flag_off_parity(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 3, "ranks": 1}, {"files": 1, "ranks": 1})
    var players: Array = _harness_iv8_three_player_fixtures(mgr)
    if players.size() != 3:
        _fail(failures, "iv8_initiative_off: want 3 player fixtures got %d" % players.size())
        _free_manager(mgr)
        return
    for i in players.size():
        var c: Dictionary = mgr.combatants[i]
        var stats: Dictionary = EntityAccess.stats_dict_for_mutation(c)
        stats["agility"] = 100
        stats["perception"] = 100
    mgr.event_queue.clear()
    var saved: bool = CombatConstants.is_feature_initiative_order_enabled()
    CombatConstants.set_feature_initiative_order_load(false)
    EventScheduler.schedule_initial_action_ready_events(mgr)
    var at0: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(mgr.combatants[0]))
    var at1: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(mgr.combatants[1]))
    var at2: float = _harness_action_ready_resolve_at(mgr, EntityAccess.id_int(mgr.combatants[2]))
    CombatConstants.set_feature_initiative_order_load(saved)
    _free_manager(mgr)
    if at0 < 0.0 or at1 < 0.0 or at2 < 0.0:
        _fail(failures, "iv8_initiative_off: missing action_ready events")
        return
    if absf(at0 - at1) > 0.02 or absf(at1 - at2) > 0.02:
        _fail(failures, "iv8_initiative_off: identical stats want same resolve_at (%.3f %.3f %.3f)" % [at0, at1, at2])


static func _harness_iv9_enemy_rank0_with_gaps(mgr: Node) -> Array:
    return Fixtures._harness_iv9_enemy_rank0_with_gaps(mgr)


## IV-9 slice 1: gap mode suppresses `compact_native_line_files_if_thinned` on gapped narrow side.


## IV-9 slice 1: gap mode suppresses `compact_native_line_files_if_thinned` on gapped narrow side.
static func _run_iv9_gap_column_compact_suppressed_when_flag_on(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "compact_native_line=disabled_when_on" not in sync_line:
        _fail(failures, "iv9_gap: sync line missing compaction gate in %s" % sync_line)
    var mgr: Node = MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var want_files: Array[int] = [1, 2, 3]
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    if FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_on: compaction should be suppressed in gap mode")
    var actual_files: Array[int] = []
    for c in mgr.combatants:
        if EntityAccess.is_alive_on_side(c, "enemy") and EntityAccess.rank_int(c) == 0:
            actual_files.append(EntityAccess.file_int(c))
    actual_files.sort()
    for i in range(actual_files.size()):
        if actual_files[i] != want_files[i]:
            _fail(
                failures,
                "iv9_gap_on: enemy files should stay gapped want %s got %s" % [str(want_files), str(actual_files)]
            )
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9: flag off  -  baseline compaction still packs gapped narrow enemy to files 0..n-1.


## IV-9: flag off  -  baseline compaction still packs gapped narrow enemy to files 0..n-1.
static func _run_iv9_gap_column_flag_off_parity(failures: PackedStringArray) -> void:
    if CombatConstants.FEATURE_GAP_COLUMN_TOPOLOGY:
        _fail(failures, "iv9_gap_off: FEATURE_GAP_COLUMN_TOPOLOGY should default off")
    var mgr: Node = MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    if not FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_off: narrow enemy with gaps should compact when flag off")
    var actual_files: Array[int] = []
    for c in mgr.combatants:
        if EntityAccess.is_alive_on_side(c, "enemy") and EntityAccess.rank_int(c) == 0:
            actual_files.append(EntityAccess.file_int(c))
    actual_files.sort()
    for i in range(actual_files.size()):
        if actual_files[i] != i:
            _fail(
                failures,
                (
                    "iv9_gap_off: enemy compact want file %d got %d (all files: %s)"
                    % [i, actual_files[i], str(actual_files)]
                )
            )
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9: vacancy reconcile follow-up still stable when gap mode is on.


## IV-9: vacancy reconcile follow-up still stable when gap mode is on.
static func _run_iv9_gap_column_vacancy_reconcile_flag_on(failures: PackedStringArray) -> void:
    var mgr: Node = MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var front_id: int = EntityAccess.id_int(mgr.combatants[0])
    _soak_kill_combatant(mgr, front_id)
    var snap: Dictionary = EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    var living_rank0_player: bool = false
    for c in mgr.combatants:
        if not EntityAccess.is_alive_on_side(c, "player"):
            continue
        if EntityAccess.rank_int(c, -9) == 0:
            living_rank0_player = true
            break
    CombatConstants.set_feature_gap_column_topology_load(saved)
    if not living_rank0_player:
        _fail(failures, "iv9_gap_reconcile: rank-0 player should exist after front death + reconcile")
    _free_manager(mgr)

## IV-9 slice 2: `FormationSlots.occupied_files_for_rank` detects intentional file gaps.
