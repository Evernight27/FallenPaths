class_name Iv9GapColumnTests
extends CombatRegressionHarnessCore
## IV-9 slice 2: `FormationSlots.occupied_files_for_rank` detects intentional file gaps.
static func _run_iv9_gap_column_occupied_files_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "slots=occupied_files_have_gaps" not in sync_line:
        _fail(failures, "iv9_gap_slots: sync line missing slots token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var form_enemy: Dictionary = mgr.formations["enemy"]
    var enemies_r0: Array = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            enemies_r0.append(c)
    var occ_gapped: PackedInt32Array = _FormationSlots.occupied_files_for_rank(mgr, form_enemy, 0)
    if occ_gapped.size() != enemies_r0.size():
        _fail(failures, "iv9_gap_slots: want %d occupied files got %s" % [enemies_r0.size(), str(occ_gapped)])
    if not _FormationSlots.occupied_files_have_gaps(occ_gapped):
        _fail(failures, "iv9_gap_slots: fixture should have file gaps got %s" % str(occ_gapped))
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    if not _FormationVacancyPlugs.compact_native_line_files_if_thinned(mgr, "enemy"):
        _fail(failures, "iv9_gap_slots: baseline compact should run when flag off")
    var occ_packed: PackedInt32Array = _FormationSlots.occupied_files_for_rank(mgr, form_enemy, 0)
    if _FormationSlots.occupied_files_have_gaps(occ_packed):
        _fail(failures, "iv9_gap_slots: after compact want contiguous files got %s" % str(occ_packed))
    for i in range(occ_packed.size()):
        if occ_packed[i] != i:
            _fail(failures, "iv9_gap_slots: packed files want %d at index %d got %s" % [i, i, str(occ_packed)])
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9 slice 2: diagram grid includes leading/trailing empty gap columns when flag on.


## IV-9 slice 2: diagram grid includes leading/trailing empty gap columns when flag on.
static func _run_iv9_gap_column_diagram_display_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "diagram_gaps" not in sync_line:
        _fail(failures, "iv9_gap_diagram: sync line missing diagram_gaps token in %s" % sync_line)
    var form: Dictionary = {
        "files": 3,
        "slots":
        {
            Vector2i(0, 1): [101],
            Vector2i(0, 2): [102],
            Vector2i(0, 3): [103],
        },
    }
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    var baseline: Array = _FormationSlots.column_display_files(form, 3)
    if baseline.size() != 3 or int(baseline[0]) != 0:
        _fail(failures, "iv9_gap_diagram_off: want baseline 0..2 got %s" % str(baseline))
    CombatConstants.set_feature_gap_column_topology_load(true)
    var display: Array = _FormationSlots.column_display_files(form, 3)
    CombatConstants.set_feature_gap_column_topology_load(saved)
    if display.size() != 4:
        _fail(failures, "iv9_gap_diagram_on: want four columns incl leading gap got %s" % str(display))
    if int(display[0]) != 0:
        _fail(failures, "iv9_gap_diagram_on: first column should be file 0 gap got %s" % str(display))
    if _FormationSlots.slot_has_any(form["slots"], Vector2i(0, 0)):
        _fail(failures, "iv9_gap_diagram_on: file 0 should be empty gap cell")


## IV-9 slice 3: gap mode uses column-arc spacing instead of raw grid |-file| when either line has gaps.


## IV-9 slice 3: gap mode uses column-arc spacing instead of raw grid |-file| when either line has gaps.
static func _run_iv9_gap_column_pair_geometry_column_arc_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "pair_geometry=column_arc_when_gaps" not in sync_line:
        _fail(failures, "iv9_gap_arc: sync line missing pair_geometry token in %s" % sync_line)
    if not is_equal_approx(
        _FormationSlots.column_arc_file_distance(PackedInt32Array([0, 1, 2]), 0, PackedInt32Array([1, 2, 3]), 3), 2.0
    ):
        _fail(failures, "iv9_gap_arc: column arc want 2 for wing-vs-far-wing fixture")
    if not is_equal_approx(
        _FormationSlots.column_arc_file_distance(PackedInt32Array([0, 1, 2]), 0, PackedInt32Array([1, 2, 3]), 1), 0.0
    ):
        _fail(failures, "iv9_gap_arc: column arc want 0 for opposing first columns")
    var mgr: Node = _MgrScript.new()
    for _i in 3:
        mgr.register(_new_entity("SWORD"), "player")
    _harness_iv9_enemy_rank0_with_gaps(mgr)
    var enemies_r0: Array = []
    for c in mgr.combatants:
        if _EntityAccess.is_alive_on_side(c, "enemy") and _EntityAccess.rank_int(c) == 0:
            enemies_r0.append(c)
    var player_wing: Dictionary = {}
    var enemy_far: Dictionary = enemies_r0[enemies_r0.size() - 1]
    for c in mgr.combatants:
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) != 0:
            continue
        if _EntityAccess.file_int(c) == 0:
            player_wing = c
            break
    if player_wing.is_empty() or enemy_far.is_empty():
        _fail(failures, "iv9_gap_arc: fixture missing wing pair")
        return
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(false)
    var geom_off: Dictionary = _PairGeometry.effective_pair_geometry(mgr, player_wing, enemy_far)
    CombatConstants.set_feature_gap_column_topology_load(true)
    var geom_on: Dictionary = _PairGeometry.effective_pair_geometry(mgr, player_wing, enemy_far)
    CombatConstants.set_feature_gap_column_topology_load(saved)
    var df_off: float = absf(float(_EntityAccess.file_int(player_wing) - _EntityAccess.file_int(enemy_far)))
    if not is_equal_approx(float(geom_off.get("file_spacing_equiv", -1.0)), df_off):
        _fail(
            failures,
            (
                "iv9_gap_arc_off: want raw grid spacing %.1f got %.3f"
                % [df_off, float(geom_off.get("file_spacing_equiv", -1.0))]
            )
        )
    var want_arc: float = 2.0
    if not is_equal_approx(float(geom_on.get("file_spacing_equiv", -1.0)), want_arc):
        _fail(
            failures,
            (
                "iv9_gap_arc_on: want column-arc spacing %.1f got %.3f"
                % [want_arc, float(geom_on.get("file_spacing_equiv", -1.0))]
            )
        )
    if float(geom_on.get("eff_dist", 0.0)) >= float(geom_off.get("eff_dist", 0.0)):
        _fail(
            failures,
            (
                "iv9_gap_arc_on: eff_dist should shrink vs raw grid (on=%.3f off=%.3f)"
                % [float(geom_on.get("eff_dist", 0.0)), float(geom_off.get("eff_dist", 0.0))]
            )
        )
    _free_manager(mgr)


## IV-9 slice 4: gap flag on/off parity for formation moves + tier-1 targeting on contiguous lines; gap-on reach for
## column-aligned wing pair.


## IV-9 slice 4: gap flag on/off parity for formation moves + tier-1 targeting on contiguous lines; gap-on reach for
## column-aligned wing pair.
static func _run_iv9_gap_column_dual_mode_formation_targeting_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "harness=dual_mode_formation_targeting" not in sync_line:
        _fail(failures, "iv9_dual: sync line missing harness token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    # Contiguous 4-wide: flag on must not change rotate_file listing or center threaten vs flag off.
    var mgr_contig: Node = _MgrScript.new()
    for _i in 4:
        mgr_contig.register(_new_entity("SWORD"), "player")
    for _j in 4:
        mgr_contig.register(_new_entity("SWORD"), "enemy")
    mgr_contig.start({"files": 4, "ranks": 1}, {"files": 4, "ranks": 1})
    CombatConstants.set_feature_gap_column_topology_load(false)
    var rotate_off: bool = _harness_iv9_player_rotate_file_listed(mgr_contig)
    var threaten_off: bool = _harness_iv9_center_rank0_can_melee_threaten(mgr_contig)
    CombatConstants.set_feature_gap_column_topology_load(true)
    var rotate_on: bool = _harness_iv9_player_rotate_file_listed(mgr_contig)
    var threaten_on: bool = _harness_iv9_center_rank0_can_melee_threaten(mgr_contig)
    if not rotate_off:
        _fail(failures, "iv9_dual_contig: flag off want rotate_file listed")
    if rotate_off != rotate_on:
        _fail(failures, "iv9_dual_contig: rotate_file parity off=%s on=%s" % [rotate_off, rotate_on])
    if not threaten_off:
        _fail(failures, "iv9_dual_contig: flag off want center can_melee_threaten")
    if threaten_off != threaten_on:
        _fail(failures, "iv9_dual_contig: threaten parity off=%s on=%s" % [threaten_off, threaten_on])
    _free_manager(mgr_contig)
    # Gapped narrow enemy: flag on keeps rotate_file on player line + column-arc wing reach.
    var mgr_gap: Node = _MgrScript.new()
    for _i in 4:
        mgr_gap.register(_new_entity("SWORD"), "player")
    # Need >=4 active per side for FORMATION mode (ENGAGEMENT_FORMATION_MIN_ACTIVE_PER_SIDE=4).
    # Create 5 enemy entities, register all 4; start with 5-file formation so shifting works.
    var enemies_gap: Array = []
    for _g in 5:
        enemies_gap.append(_new_entity("SWORD"))
    for _gi in range(4):
        mgr_gap.register(enemies_gap[_gi], "enemy")
    mgr_gap.start({"files": 4, "ranks": 1}, {"files": 5, "ranks": 1})
    var slots_gap: Dictionary = _FormationSlots.formation_slots_dict(mgr_gap.formations["enemy"])
    var new_slots_gap: Dictionary = {}
    for sk in slots_gap.keys():
        if not (sk is Vector2i):
            continue
        var scell: Vector2i = sk as Vector2i
        if scell.x != 0:
            continue
        var scid: Variant = slots_gap[sk]
        var snk: Vector2i = Vector2i(scell.x, scell.y + 1)
        if scid is Array:
            new_slots_gap[snk] = scid.duplicate()
        elif scid is int and scid >= 0:
            new_slots_gap[snk] = [scid]
    mgr_gap.formations["enemy"]["slots"] = new_slots_gap
    _FormationSlots.normalize_formation_slots(mgr_gap.formations["enemy"])
    _FormationSlots.refresh_gap_column_topology(mgr_gap.formations["enemy"])
    mgr_gap.call("recompute_zoc_and_distance")
    CombatConstants.set_feature_gap_column_topology_load(true)
    if not _harness_iv9_player_rotate_file_listed(mgr_gap):
        _fail(failures, "iv9_dual_gap: want rotate_file on contiguous player line when flag on")
    var player_wing: Dictionary = {}
    var enemy_near: Dictionary = {}
    for c in mgr_gap.combatants:
        if (
            _EntityAccess.is_alive_on_side(c, "player")
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 0
        ):
            player_wing = c
        if (
            _EntityAccess.is_alive_on_side(c, "enemy")
            and _EntityAccess.rank_int(c) == 0
            and _EntityAccess.file_int(c) == 1
        ):
            enemy_near = c
    if player_wing.is_empty() or enemy_near.is_empty():
        _fail(failures, "iv9_dual_gap: want wing pair player file0 vs enemy file1")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr_gap)
        return
    player_wing["gauge"] = 100.0
    if not _MeleeListing.can_melee_threaten(mgr_gap, player_wing, enemy_near):
        _fail(failures, "iv9_dual_gap: column-aligned wing want can_melee_threaten vs first enemy column")
    var acts: Array = _ActionsBuilder.build(mgr_gap, _EntityAccess.id_int(player_wing))
    var e_id: int = _EntityAccess.id_int(enemy_near)
    var w_wing: Variant = _EntityAccess.get_weapon(player_wing)
    var atk_ids: Dictionary = {}
    if w_wing != null and w_wing is Weapon:
        atk_ids = (w_wing as Weapon).attack_types
    if not _ListedActions.actions_include_any_move_in_vs_target(acts, e_id, atk_ids):
        _fail(failures, "iv9_dual_gap: wing want weapon strike listed vs column-aligned foe (had %s)" % str(acts))
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr_gap)


## IV-9 slice 5: **`gap_column_files`** cache stays synced after swap_rank + vacancy reconcile when flag on.


## IV-9 slice 5: **`gap_column_files`** cache stays synced after swap_rank + vacancy reconcile when flag on.
static func _run_iv9_gap_column_topology_refresh_after_formation_moves(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "flow_refresh=swap_drag_fall_back_reconcile" not in sync_line:
        _fail(failures, "iv9_refresh: sync line missing flow_refresh token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var form_p: Dictionary = mgr.formations["player"]
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: want cache sync after start")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var p0: Dictionary = mgr.combatants[0]
    var p1: Dictionary = mgr.combatants[1]
    var id0: int = _EntityAccess.id_int(p0)
    var id1: int = _EntityAccess.id_int(p1)
    _FormationFlow.start_pair_move(mgr, id0, id1, "swap_rank")
    (
        _FormationFlow
        . handle_swap_rank_resolve(
            mgr,
            {
                "type": CombatConstants.EVENT_SWAP_RANK_RESOLVE,
                "combatant_id": id0,
                "resolve_at": mgr.combat_clock,
                "data": {"partner_id": id1, "move_kind": "swap_rank"},
            }
        )
    )
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: cache drift after swap_rank resolve")
    _soak_kill_combatant(mgr, id0)
    var snap: Dictionary = _EventScheduler.snapshot_rank_file_placements(mgr)
    var ch: Array = _FormationFlow.reconcile_vacancy_plugs_track_changed_fids(mgr)
    _FormationFlow.finish_vacancy_reconcile_follow_up(mgr, ch, snap, true)
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh: cache drift after vacancy reconcile")
    CombatConstants.set_feature_gap_column_topology_load(false)
    _FormationSlots.refresh_gap_column_topology_for_manager(mgr, "player")
    var form_after_off: Dictionary = mgr.formations["player"]
    if form_after_off.has("gap_column_files"):
        _fail(failures, "iv9_refresh: flag off should erase gap_column_files cache")
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-9 slice 6: **`drag_back`** + **`fall_back_pair`** keep **`gap_column_files`** synced when flag on.


## IV-9 slice 6: **`drag_back`** + **`fall_back_pair`** keep **`gap_column_files`** synced when flag on.
static func _run_iv9_gap_column_topology_refresh_drag_back_fall_back_pair(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv9_gap_column_doc_sync_line()
    if "flow_refresh=swap_drag_fall_back_reconcile" not in sync_line:
        _fail(failures, "iv9_refresh_pair: sync line missing drag/fall_back token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_gap_column_topology_enabled()
    CombatConstants.set_feature_gap_column_topology_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 2}, {"files": 1, "ranks": 1})
    var form_p: Dictionary = mgr.formations["player"]
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: want cache sync after start")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var p_front: Dictionary = {}
    var p_rear: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_alive_on_side(c, "player"):
            continue
        if _EntityAccess.rank_int(c) == 0:
            p_front = c
        elif _EntityAccess.rank_int(c) == 1:
            p_rear = c
    if p_front.is_empty() or p_rear.is_empty():
        _fail(failures, "iv9_refresh_pair: want rank-0/rank-1 player pair")
        CombatConstants.set_feature_gap_column_topology_load(saved)
        _free_manager(mgr)
        return
    var id_front: int = _EntityAccess.id_int(p_front)
    var id_rear: int = _EntityAccess.id_int(p_rear)
    _harness_iv9_resolve_adjacent_rank_pair_move(mgr, id_front, id_rear, "drag_back")
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: cache drift after drag_back resolve")
    _harness_iv9_resolve_adjacent_rank_pair_move(mgr, id_rear, id_front, "fall_back_pair")
    if not _harness_iv9_gap_column_cache_matches_occupied(form_p):
        _fail(failures, "iv9_refresh_pair: cache drift after fall_back_pair resolve")
    CombatConstants.set_feature_gap_column_topology_load(saved)
    _free_manager(mgr)


## IV-11 slice 3: **`CombatManager.register`** stamps **`is_party_leader`** from node (player only).


## IV-11 slice 3: **`CombatManager.register`** stamps **`is_party_leader`** from node (player only).
static func _run_iv11_register_party_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice3=register_stamp+formatter" not in sync_line:
        _fail(failures, "iv11_stamp: sync line missing slice3 token in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.is_party_leader = false
    var enemy_ent: CoreEntity = _new_entity("SWORD")
    enemy_ent.is_party_leader = true
    mgr.register(leader_ent, "player")
    mgr.register(member_ent, "player")
    mgr.register(enemy_ent, "enemy")
    if not bool(mgr.combatants[0].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: player leader node want is_party_leader true")
    if bool(mgr.combatants[1].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: player member want is_party_leader false")
    if bool(mgr.combatants[2].get("is_party_leader", false)):
        _fail(failures, "iv11_stamp: enemy side must not stamp is_party_leader")
    _free_manager(mgr)


## IV-11 slice 4: roster **`is_party_leader`** on party nodes -> **`get_fightable_party_nodes`** ->
## **`CombatManager.register`** stamp.


## IV-11 slice 4: roster **`is_party_leader`** on party nodes -> **`get_fightable_party_nodes`** ->
## **`CombatManager.register`** stamp.
static func _run_iv11_campaign_bridge_party_leader_stamp_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice4=bridge_roster_stamp" not in sync_line:
        _fail(failures, "iv11_bridge: sync line missing slice4 token in %s" % sync_line)
    var world: Node2D = Node2D.new()
    var pm: Node = _PartyManagerScript.new()
    var leader_ent: CoreEntity = _new_entity("SWORD")
    leader_ent.name = "PartyLead"
    leader_ent.is_party_leader = true
    var member_ent: CoreEntity = _new_entity("SWORD")
    member_ent.name = "Companion"
    member_ent.is_party_leader = false
    pm.add_member(leader_ent)
    pm.add_member(member_ent)
    world.set_meta("party_manager", pm)
    var fightable: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if fightable.size() != 2:
        _fail(failures, "iv11_bridge: want 2 fightable party nodes got %d" % fightable.size())
        world.free()
        pm.free()
        _free_harness_node(leader_ent)
        _free_harness_node(member_ent)
        leader_ent = null
        member_ent = null
        return
    world.set_meta(_SoakPresets.WORLD_META_PLAYER_LEADER_ONLY, true)
    var leader_only: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if leader_only.size() != 1 or leader_only[0] != leader_ent:
        _fail(failures, "iv11_bridge: leader_only meta want leader node only got %d" % leader_only.size())
    world.remove_meta(_SoakPresets.WORLD_META_PLAYER_LEADER_ONLY)
    world.set_meta(_SoakPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP, 1)
    var capped: Array = _CampaignBridge.get_fightable_party_nodes(world)
    if capped.size() != 1 or capped[0] != leader_ent:
        _fail(failures, "iv11_bridge: fighter cap 1 want leader-first got %d" % capped.size())
    world.remove_meta(_SoakPresets.WORLD_META_SOAK_PARTY_FIGHTER_CAP)
    var mgr: Node = _MgrScript.new()
    var leader_id: int = mgr.register(leader_ent, "player")
    var member_id: int = mgr.register(member_ent, "player")
    if not bool(mgr.combatants[leader_id].get("is_party_leader", false)):
        _fail(failures, "iv11_bridge: register leader want is_party_leader true")
    if bool(mgr.combatants[member_id].get("is_party_leader", false)):
        _fail(failures, "iv11_bridge: register member want is_party_leader false")
    _free_manager(mgr)
    world.free()
    pm.free()
    leader_ent = null
    member_ent = null


## IV-11 slice 4: formation diagram **`[Ldr]`** callout for player party leader only.


## IV-11 slice 4: formation diagram **`[Ldr]`** callout for player party leader only.
static func _run_iv11_party_leader_diagram_callout_suite(failures: PackedStringArray) -> void:
    var Diagram := preload("res://ui/FormationDiagramBuilder.gd")
    var UiHints := preload("res://combat/CombatUiHints.gd")
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "diagram_callout" not in sync_line:
        _fail(failures, "iv11_diagram: sync line missing diagram_callout in %s" % sync_line)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var member: Dictionary = {}
    var enemy: Dictionary = {}
    for c in mgr.combatants:
        if _EntityAccess.is_living_on_side(c, "enemy"):
            enemy = c
        elif leader.is_empty():
            leader = c
        else:
            member = c
    leader["is_party_leader"] = true
    member["is_party_leader"] = false
    if UiHints.party_leader_diagram_suffix(leader) != " [Ldr]":
        _fail(
            failures, "iv11_diagram: leader suffix want ' [Ldr]' got '%s'" % UiHints.party_leader_diagram_suffix(leader)
        )
    if not UiHints.party_leader_diagram_suffix(member).is_empty():
        _fail(failures, "iv11_diagram: member must not get leader diagram suffix")
    if not UiHints.party_leader_diagram_suffix(enemy).is_empty():
        _fail(failures, "iv11_diagram: enemy must not get leader diagram suffix")
    var leader_cell: String = Diagram._cell_label_with_footwork("Lead", [leader])
    var member_cell: String = Diagram._cell_label_with_footwork("Mate", [member])
    if " [Ldr]" not in leader_cell:
        _fail(failures, "iv11_diagram: leader cell want [Ldr] got '%s'" % leader_cell)
    if " [Ldr]" in member_cell:
        _fail(failures, "iv11_diagram: member cell must not show [Ldr] got '%s'" % member_cell)
    var tips: PackedStringArray = UiHints.formation_cell_tooltip_lines(
        leader, _EntityAccess.get_display_name(leader, _EntityAccess.id_int(leader)), mgr
    )
    var tip_hit: bool = false
    for line in tips:
        if str(line).ends_with(" -  Party leader"):
            tip_hit = true
            break
    if not tip_hit:
        _fail(failures, "iv11_diagram: formation cell tooltip missing Party leader")
    _free_manager(mgr)


## IV-11 slice 2: party leader lists **`order_hold_lane`** when flag on; resolve sets formation doctrine.


## IV-11 slice 2: party leader lists **`order_hold_lane`** when flag on; resolve sets formation doctrine.
static func _run_iv11_leader_order_hold_lane_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    for token in ["issuer=is_formation_command_issuer", "menu_label=Order_Hold_lane"]:
        if token not in sync_line:
            _fail(failures, "iv11_leader: sync line missing %s in %s" % [token, sync_line])
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_leader: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: want order_hold_lane listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Hold lane" not in menu_line:
        _fail(failures, "iv11_leader: menu line want Order: Hold lane got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Hold lane: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_leader: turn hint want instant hold lane got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: companion must not list order_hold_lane")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_HOLD_LANE, {})
    if not ok:
        _fail(failures, "iv11_leader: resolve order_hold_lane should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "iv11_leader: want hold_lane doctrine got %s" % mgr.get_formation_doctrine("player"))
    CombatConstants.set_feature_leader_formation_command_load(false)
    var off_acts: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(off_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_leader: flag off must not list order_hold_lane")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 2: **`CombatLogFormatter`** surfaces **`leader_order_hold_lane`** resolve outcome.


## IV-11 slice 2: **`CombatLogFormatter`** surfaces **`leader_order_hold_lane`** resolve outcome.
static func _run_iv11_leader_order_hold_lane_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)", "player", "P (player)", "player", {"outcome": "leader_order_hold_lane", "formation_id": "player"}
    )
    if "hold lane" not in line.to_lower():
        _fail(failures, "iv11_formatter: want hold lane copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_formatter: want formation_id in %s" % line)


## IV-11 slice 5: party leader lists **`order_probing`** when flag on; resolve sets probing doctrine.


## IV-11 slice 5: party leader lists **`order_probing`** when flag on; resolve sets probing doctrine.
static func _run_iv11_leader_order_probing_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice5=order_probing" not in sync_line:
        _fail(failures, "iv11_probing: sync line missing slice5 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_probing: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: want order_probing listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Probe" not in menu_line:
        _fail(failures, "iv11_probing: menu line want Order: Probe got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Probe: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_probing: turn hint want instant probe got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: companion must not list order_probing")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_PROBING, {})
    if not ok:
        _fail(failures, "iv11_probing: resolve order_probing should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PROBING:
        _fail(failures, "iv11_probing: want probing doctrine got %s" % mgr.get_formation_doctrine("player"))
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var after_probe: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(after_probe, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_probing: probing doctrine must suppress re-list")
    if not _ListedActions.actions_include_move_id(after_probe, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_probing: hold_lane should list when doctrine is probing")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 5: **`CombatLogFormatter`** surfaces **`leader_order_probing`** resolve outcome.


## IV-11 slice 5: **`CombatLogFormatter`** surfaces **`leader_order_probing`** resolve outcome.
static func _run_iv11_leader_order_probing_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)", "player", "P (player)", "player", {"outcome": "leader_order_probing", "formation_id": "player"}
    )
    if "probe" not in line.to_lower():
        _fail(failures, "iv11_probing_formatter: want probe copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_probing_formatter: want formation_id in %s" % line)


## IV-11 slice 8: party leader lists **`order_pinch_center`** when flag on; resolve sets pinch doctrine.


## IV-11 slice 8: party leader lists **`order_pinch_center`** when flag on; resolve sets pinch doctrine.
static func _run_iv11_leader_order_pinch_center_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice8=order_pinch_center" not in sync_line:
        _fail(failures, "iv11_pinch: sync line missing slice8 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "player")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 2, "ranks": 1}, {"files": 1, "ranks": 1})
    var leader: Dictionary = {}
    var companion: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "player"):
            continue
        c["gauge"] = 100.0
        if _EntityAccess.rank_int(c) == 0 and leader.is_empty():
            leader = c
        elif companion.is_empty():
            companion = c
    if leader.is_empty() or companion.is_empty():
        _fail(failures, "iv11_pinch: missing rank-0 leader or companion fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    leader["is_party_leader"] = true
    companion["is_party_leader"] = false
    leader["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("player", CombatConstants.DOCTRINE_DEFAULT)
    var leader_id: int = _EntityAccess.id_int(leader)
    var companion_id: int = _EntityAccess.id_int(companion)
    var leader_acts: Array = mgr.get_available_actions(leader_id)
    if not _ListedActions.actions_include_move_id(leader_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: want order_pinch_center listed for party leader")
    var menu_line: String = _FormationMoveDuration.formation_listed_moves_menu_line(leader_acts)
    if "Order: Pinch center" not in menu_line:
        _fail(failures, "iv11_pinch: menu line want Order: Pinch center got '%s'" % menu_line)
    var turn_hint: String = _FormationMoveDuration.formation_listed_moves_turn_hint(leader_acts)
    if "Pinch center: doctrine (instant)" not in turn_hint:
        _fail(failures, "iv11_pinch: turn hint want instant pinch got '%s'" % turn_hint)
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var companion_acts: Array = mgr.get_available_actions(companion_id)
    if _ListedActions.actions_include_move_id(companion_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: companion must not list order_pinch_center")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var ok: bool = _ResolveAction.resolve(mgr, leader_id, leader_id, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER, {})
    if not ok:
        _fail(failures, "iv11_pinch: resolve order_pinch_center should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("player") != CombatConstants.DOCTRINE_PINCH_CENTER:
        _fail(failures, "iv11_pinch: want pinch_center doctrine got %s" % mgr.get_formation_doctrine("player"))
    leader["state"] = CombatConstants.STATE_WAITING
    leader["gauge"] = 100.0
    var after_pinch: Array = mgr.get_available_actions(leader_id)
    if _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_pinch: pinch doctrine must suppress re-list")
    if not _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_pinch: hold_lane should list when doctrine is pinch_center")
    if not _ListedActions.actions_include_move_id(after_pinch, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_pinch: probing should list when doctrine is pinch_center")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 8: **`CombatLogFormatter`** surfaces **`leader_order_pinch_center`** resolve outcome.


## IV-11 slice 8: **`CombatLogFormatter`** surfaces **`leader_order_pinch_center`** resolve outcome.
static func _run_iv11_leader_order_pinch_center_formatter_suite(failures: PackedStringArray) -> void:
    var line: String = _CombatLogFormatter.format_action_line(
        "P (player)",
        "player",
        "P (player)",
        "player",
        {"outcome": "leader_order_pinch_center", "formation_id": "player"}
    )
    if "pinch" not in line.to_lower():
        _fail(failures, "iv11_pinch_formatter: want pinch copy in %s" % line)
    if "player" not in line:
        _fail(failures, "iv11_pinch_formatter: want formation_id in %s" % line)


## IV-11 slice 9: enemy commander lists and resolves **`order_hold_lane`** (mirror player leader path).


## IV-11 slice 9: enemy commander lists and resolves **`order_hold_lane`** (mirror player leader path).
static func _run_iv11_enemy_commander_order_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice9=enemy_commander_orders+doctrine_cycle" not in sync_line:
        _fail(failures, "iv11_enemy_cmd: sync line missing slice9 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    var grunt_ent: CoreEntity = _new_entity("SWORD")
    grunt_ent.is_enemy_leader = false
    mgr.register(cmd_ent, "enemy")
    mgr.register(grunt_ent, "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    var commander: Dictionary = {}
    var grunt: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        c["gauge"] = 100.0
        if c.get("is_enemy_leader", false) == true and commander.is_empty():
            commander = c
        elif grunt.is_empty():
            grunt = c
    if commander.is_empty() or grunt.is_empty():
        _fail(failures, "iv11_enemy_cmd: missing commander or grunt fixture")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if _EntityAccess.rank_int(commander) != 0:
        _fail(failures, "iv11_enemy_cmd: commander must be rank 0")
    commander["state"] = CombatConstants.STATE_WAITING
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_DEFAULT)
    var cmd_id: int = _EntityAccess.id_int(commander)
    var grunt_id: int = _EntityAccess.id_int(grunt)
    var cmd_acts: Array = mgr.get_available_actions(cmd_id)
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: want order_hold_lane listed for enemy commander")
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_enemy_cmd: want order_probing listed for enemy commander")
    if not _ListedActions.actions_include_move_id(cmd_acts, CombatConstants.MOVE_ID_ORDER_PINCH_CENTER):
        _fail(failures, "iv11_enemy_cmd: want order_pinch_center listed for enemy commander")
    var grunt_acts: Array = mgr.get_available_actions(grunt_id)
    if _ListedActions.actions_include_move_id(grunt_acts, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: grunt must not list leader commands")
    var ok: bool = _ResolveAction.resolve(mgr, cmd_id, cmd_id, CombatConstants.MOVE_ID_ORDER_HOLD_LANE, {})
    if not ok:
        _fail(failures, "iv11_enemy_cmd: resolve order_hold_lane should succeed")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    if mgr.get_formation_doctrine("enemy") != CombatConstants.DOCTRINE_HOLD_LANE:
        _fail(failures, "iv11_enemy_cmd: want hold_lane doctrine got %s" % mgr.get_formation_doctrine("enemy"))
    commander["state"] = CombatConstants.STATE_WAITING
    commander["gauge"] = 100.0
    var after_hold: Array = mgr.get_available_actions(cmd_id)
    if _ListedActions.actions_include_move_id(after_hold, CombatConstants.MOVE_ID_ORDER_HOLD_LANE):
        _fail(failures, "iv11_enemy_cmd: hold_lane must suppress re-list after resolve")
    if not _ListedActions.actions_include_move_id(after_hold, CombatConstants.MOVE_ID_ORDER_PROBING):
        _fail(failures, "iv11_enemy_cmd: probing should list when doctrine is hold_lane")
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)


## IV-11 slice 9: enemy commander cycles hold -> probe -> pinch -> hold (mirror player leader).


## IV-11 slice 9: enemy commander cycles hold -> probe -> pinch -> hold (mirror player leader).
static func _run_iv11_enemy_commander_doctrine_cycle_suite(failures: PackedStringArray) -> void:
    var sync_line: String = CombatConstants.iv11_leader_formation_doc_sync_line()
    if "slice9=enemy_commander_orders+doctrine_cycle" not in sync_line:
        _fail(failures, "iv11_enemy_cycle: sync line missing slice9 token in %s" % sync_line)
    var saved: bool = CombatConstants.is_feature_leader_formation_command_enabled()
    CombatConstants.set_feature_leader_formation_command_load(true)
    var mgr: Node = _MgrScript.new()
    mgr.register(_new_entity("SWORD"), "player")
    var cmd_ent: CoreEntity = _new_entity("SWORD")
    cmd_ent.is_enemy_leader = true
    mgr.register(cmd_ent, "enemy")
    mgr.register(_new_entity("SWORD"), "enemy")
    mgr.start({"files": 1, "ranks": 1}, {"files": 2, "ranks": 1})
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_PROBING)
    var commander: Dictionary = {}
    for c in mgr.combatants:
        if not _EntityAccess.is_living_on_side(c, "enemy"):
            continue
        if c.get("is_enemy_leader", false) == true and _EntityAccess.rank_int(c) == 0:
            commander = c
            break
    if commander.is_empty():
        _fail(failures, "iv11_enemy_cycle: missing rank-0 enemy commander")
        CombatConstants.set_feature_leader_formation_command_load(saved)
        _free_manager(mgr)
        return
    var cmd_id: int = _EntityAccess.id_int(commander)
    mgr.set_formation_doctrine("enemy", CombatConstants.DOCTRINE_DEFAULT)
    var steps: Array = [
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
        CombatConstants.MOVE_ID_ORDER_PROBING,
        CombatConstants.MOVE_ID_ORDER_PINCH_CENTER,
        CombatConstants.MOVE_ID_ORDER_HOLD_LANE,
    ]
    var want_docs: Array = [
        CombatConstants.DOCTRINE_HOLD_LANE,
        CombatConstants.DOCTRINE_PROBING,
        CombatConstants.DOCTRINE_PINCH_CENTER,
        CombatConstants.DOCTRINE_HOLD_LANE,
    ]
    for i in steps.size():
        commander["state"] = CombatConstants.STATE_WAITING
        commander["gauge"] = 100.0
        var move_id: String = str(steps[i])
        if not _ResolveAction.resolve(mgr, cmd_id, cmd_id, move_id, {}):
            _fail(failures, "iv11_enemy_cycle: resolve %s failed at step %d" % [move_id, i])
            break
        if mgr.get_formation_doctrine("enemy") != want_docs[i]:
            _fail(
                failures,
                "iv11_enemy_cycle: step %d want %s got %s" % [i, want_docs[i], mgr.get_formation_doctrine("enemy")]
            )
            break
    CombatConstants.set_feature_leader_formation_command_load(saved)
    _free_manager(mgr)

## IV-11 slice 9: party leader can cycle hold -> probe -> pinch -> hold without re-listing active doctrine.
