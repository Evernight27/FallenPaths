class_name CombatDoctrine
extends RefCounted

## Per-formation **intent** (doctrine): steers hybrid targeting weights + ordering via `CombatTargetScoring` /
## `CombatAIActionPicker`.
## Pincer roles (**`PINCER_ROLE_*`**) when **`DOCTRINE_PINCH_CENTER`** + wider files than opponent: center pins, flank
## wings close/flank.
## III-4 **3e** post-rout mop-up: `envelop_mop_up_active`, `envelop_close_allowed`, `hold_line_close_pick_eligible`,
## `fight_finish_tail_active`, `sparse_line_prefer_finish_over_shuffle`, `should_suppress_skirmish_rotate_file`.
## Orthogonal to engagement-mode / posture targeting weights on melee/close listing.

const PINCER_ROLE_NONE := ""
const PINCER_ROLE_CENTER := "center"
const PINCER_ROLE_FLANK_WING := "flank_wing"


static func normalize(doctrine: String) -> String:
    var d: String = doctrine.strip_edges().to_lower()
    if d.is_empty() or d == CombatConstants.DOCTRINE_DEFAULT:
        return CombatConstants.DOCTRINE_DEFAULT
    if d == CombatConstants.DOCTRINE_PINCH_CENTER or d == "pinch" or d == "pincer":
        return CombatConstants.DOCTRINE_PINCH_CENTER
    if d == CombatConstants.DOCTRINE_HOLD_LANE or d == "hold":
        return CombatConstants.DOCTRINE_HOLD_LANE
    if d == CombatConstants.DOCTRINE_PROBING or d == "probing":
        return CombatConstants.DOCTRINE_PROBING
    return CombatConstants.DOCTRINE_DEFAULT


static func doctrine_for_fid(manager: Node, formation_id: String) -> String:
    if manager == null:
        return CombatConstants.DOCTRINE_DEFAULT
    var fd: Variant = manager.get("formation_doctrine")
    if fd is not Dictionary:
        return CombatConstants.DOCTRINE_DEFAULT
    var d: Variant = fd.get(str(formation_id), CombatConstants.DOCTRINE_DEFAULT)
    return normalize(str(d))


static func clear_commitments_for_side(manager: Node, formation_id: String) -> void:
    if manager == null:
        return
    for c in manager.combatants:
        if CombatantEntityAccess.formation_id_str(c) != formation_id:
            continue
        clear_combatant_doctrine_commitment(c)
        c[DataKeys.CLOSE_BLOCK_UNTIL_BY_TARGET_ID] = {}


## Drop stale target commit after rank/file shuffle (rotate, swap, plug, flee) — mapped opposition may change.
static func clear_combatant_doctrine_commitment(c: Dictionary) -> void:
    if c.is_empty():
        return
    c[DataKeys.DOCTRINE_TARGET_COMMIT_ID] = -1
    c[DataKeys.DOCTRINE_COMMIT_UNTIL] = 0.0
    c[DataKeys.CLOSE_BLOCK_UNTIL_BY_TARGET_ID] = {}


## True when the **opposing** formation--'"'s front rank has a **hollow center**: middle file(s) empty with at least one
## living rank-0 on both wings (`files >= 3`). Rank-0 on **`combatant_on_zone_geometry_fid`**. Used for automatic pinch
## doctrine; exposed for harness.
static func enemy_line_hollow_center_for_pinch(manager: Node, our_formation_id: String) -> bool:
    if manager == null:
        return false
    var opp_fid: String = CombatantEntityAccess.opponent_side_label(str(our_formation_id))
    var fd: Dictionary = FormationSlots.formation_record_for_manager(manager, opp_fid)
    if fd.is_empty():
        return false
    var nfiles: int = maxi(1, int(fd.get(DataKeys.FORMATION_FILES, 1)))
    if nfiles < 3:
        return false
    var has_r0: Array = []
    has_r0.resize(nfiles)
    for i in nfiles:
        has_r0[i] = false
    for c in manager.combatants:
        if not CombatantEntityAccess.is_standing_combatant(c):
            continue
        if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, opp_fid):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        var fi: int = CombatantEntityAccess.file_int(c)
        if fi >= 0 and fi < nfiles:
            has_r0[fi] = true
    if (nfiles & 1) == 1:
        var center_idx: int = nfiles >> 1
        if bool(has_r0[center_idx]):
            return false
        var left: bool = false
        var right: bool = false
        for f in nfiles:
            if not bool(has_r0[f]):
                continue
            if f < center_idx:
                left = true
            elif f > center_idx:
                right = true
        return left and right
    var c0: int = (nfiles >> 1) - 1
    var c1: int = nfiles >> 1
    if bool(has_r0[c0]) or bool(has_r0[c1]):
        return false
    var left_even: bool = false
    var right_even: bool = false
    for f in nfiles:
        if not bool(has_r0[f]):
            continue
        if f < c0:
            left_even = true
        elif f > c1:
            right_even = true
    return left_even and right_even


## Living rank-0 fighters on **`formation_id`** zone geometry (standing, not incapacitated).
static func living_rank0_front_count(manager: Node, formation_id: String) -> int:
    if manager == null:
        return 0
    var fid: String = str(formation_id)
    var n: int = 0
    for c in manager.combatants:
        if not CombatantEntityAccess.is_standing_combatant(c):
            continue
        if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, c, fid):
            continue
        if CombatantEntityAccess.rank_int(c) != 0:
            continue
        n += 1
    return n


## p4c: wider formation + rank-0 count advantage |' auto envelopment pinch (doctrine still **default**).
static func numeric_superiority_for_pinch(manager: Node, our_formation_id: String) -> bool:
    if manager == null:
        return false
    var our_fid: String = str(our_formation_id)
    var opp_fid: String = CombatantEntityAccess.opponent_side_label(our_fid)
    var our_form: Dictionary = FormationSlots.formation_record_for_manager(manager, our_fid)
    var opp_form: Dictionary = FormationSlots.formation_record_for_manager(manager, opp_fid)
    if our_form.is_empty() or opp_form.is_empty():
        return false
    var our_files: int = maxi(1, int(our_form.get(DataKeys.FORMATION_FILES, 1)))
    var opp_files: int = maxi(1, int(opp_form.get(DataKeys.FORMATION_FILES, 1)))
    if our_files <= opp_files:
        return false
    var our_front: int = living_rank0_front_count(manager, our_fid)
    var opp_front: int = living_rank0_front_count(manager, opp_fid)
    return our_front >= opp_front + int(CombatConstants.AUTO_DOCTRINE_NUMERIC_SUPERIORITY_FRONT_MARGIN)


## Option 4 pilot (`CombatConstants.FEATURE_AUTOMATIC_DOCTRINE`): **default** doctrine |' **pinch_center** when hollow
## enemy front or numeric superiority (p4c). Does not override player-set **hold** / **pinch**; does not auto-revert.
## Single call site: `CombatFormationEngagement.recompute_all`.
static func evaluate_automatic_doctrine(manager: Node) -> void:
    if manager == null or not CombatConstants.FEATURE_AUTOMATIC_DOCTRINE:
        return
    for fid in ["player", "enemy"]:
        if doctrine_for_fid(manager, fid) != CombatConstants.DOCTRINE_DEFAULT:
            continue
        var reason: String = ""
        if enemy_line_hollow_center_for_pinch(manager, fid):
            reason = "hollow_center"
        elif numeric_superiority_for_pinch(manager, fid):
            reason = "numeric_superiority"
        if reason.is_empty():
            continue
        manager.set_formation_doctrine(fid, CombatConstants.DOCTRINE_PINCH_CENTER)
        TacticalCombat.record_automatic_doctrine_pinch(manager, fid, reason)


## True when **`DOCTRINE_PINCH_CENTER`** and our formation spans more files than the opponent (7v3 skirmish pincer).
static func pincer_outnumber_active(manager: Node, formation_id: String) -> bool:
    if manager == null:
        return false
    var our_fid: String = str(formation_id)
    if doctrine_for_fid(manager, our_fid) != CombatConstants.DOCTRINE_PINCH_CENTER:
        return false
    var opp_fid: String = CombatantEntityAccess.opponent_side_label(our_fid)
    var our_form: Dictionary = FormationSlots.formation_record_for_manager(manager, our_fid)
    var opp_form: Dictionary = FormationSlots.formation_record_for_manager(manager, opp_fid)
    if our_form.is_empty() or opp_form.is_empty():
        return false
    return int(our_form.get(DataKeys.FORMATION_FILES, 1)) > int(opp_form.get(DataKeys.FORMATION_FILES, 1))


## Rank-0 **center** vs **flank_wing** under pincer outnumber; empty when not applicable.
static func pincer_role_for_combatant(manager: Node, c: Dictionary) -> String:
    if manager == null or c.is_empty():
        return PINCER_ROLE_NONE
    if CombatantEntityAccess.rank_int(c) != 0:
        return PINCER_ROLE_NONE
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if not pincer_outnumber_active(manager, fid):
        return PINCER_ROLE_NONE
    var our_form: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    var opp_form: Dictionary = FormationSlots.formation_record_for_manager(
        manager, CombatantEntityAccess.opponent_side_label(fid)
    )
    if our_form.is_empty() or opp_form.is_empty():
        return PINCER_ROLE_NONE
    var our_files: int = maxi(1, int(our_form.get(DataKeys.FORMATION_FILES, 1)))
    var opp_files: int = maxi(1, int(opp_form.get(DataKeys.FORMATION_FILES, 1)))
    var our_file: int = CombatantEntityAccess.file_int(c)
    var edge_margin: int = maxi(1, int((our_files - opp_files) / 2.0))
    var dist_from_near_edge: int = mini(our_file, our_files - 1 - our_file)
    if dist_from_near_edge < edge_margin:
        return PINCER_ROLE_FLANK_WING
    return PINCER_ROLE_CENTER


static func pincer_flank_wing_should_close_at_long(manager: Node, c: Dictionary) -> bool:
    return pincer_role_for_combatant(manager, c) == PINCER_ROLE_FLANK_WING


static func pincer_center_should_pin(manager: Node, c: Dictionary) -> bool:
    return pincer_role_for_combatant(manager, c) == PINCER_ROLE_CENTER


## Living rank-0 enemy id on the outer flank file matching this wing (left wing |' min enemy file, right |' max).
static func preferred_pincer_flank_enemy_id(manager: Node, wing: Dictionary) -> int:
    if manager == null or wing.is_empty():
        return -1
    if pincer_role_for_combatant(manager, wing) != PINCER_ROLE_FLANK_WING:
        return -1
    var our_form: Dictionary = FormationSlots.formation_record_for_manager(
        manager, CombatantEntityAccess.formation_id_str(wing)
    )
    if our_form.is_empty():
        return -1
    var our_files: int = maxi(1, int(our_form.get(DataKeys.FORMATION_FILES, 1)))
    var our_file: int = CombatantEntityAccess.file_int(wing)
    var pick_min_file: bool = our_file <= (our_files - 1 - our_file)
    var best_id: int = -1
    var best_file: int = 999999 if pick_min_file else -999999
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var opp: Dictionary = raw as Dictionary
        if not CombatantEntityAccess.is_living_hostile_to(wing, opp):
            continue
        if CombatantEntityAccess.rank_int(opp) != 0:
            continue
        var ef: int = CombatantEntityAccess.file_int(opp)
        if pick_min_file:
            if ef < best_file:
                best_file = ef
                best_id = CombatantEntityAccess.id_int(opp)
        elif ef > best_file:
            best_file = ef
            best_id = CombatantEntityAccess.id_int(opp)
    return best_id


## III-4 **3e**: spread damp for pincer flank wings — penalizes targeting enemies far from preferred outer-file.
## Returns a multiplicative weight: `1.0` when not a wing or no preferred enemy; scales down with file distance.
static func pincer_close_arc_spread_mult(manager: Node, actor: Dictionary, opp: Dictionary) -> float:
    if manager == null or actor.is_empty() or opp.is_empty():
        return 1.0
    if pincer_role_for_combatant(manager, actor) != PINCER_ROLE_FLANK_WING:
        return 1.0
    var pref: int = preferred_pincer_flank_enemy_id(manager, actor)
    if pref < 0:
        return 1.0
    var opp_file: int = CombatantEntityAccess.file_int(opp)
    var our_form: Dictionary = FormationSlots.formation_record_for_manager(
        manager, CombatantEntityAccess.formation_id_str(actor)
    )
    if our_form.is_empty():
        return 1.0
    var pref_enemy: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, pref)
    if pref_enemy.is_empty():
        return 1.0
    var pref_file: int = CombatantEntityAccess.file_int(pref_enemy)
    var file_offset: int = absi(opp_file - pref_file)
    if file_offset <= 0:
        return 1.0
    var mult: float = pow(CombatConstants.DOCTRINE_PINCER_CLOSE_ARC_SPREAD_MULT, float(file_offset))
    return clampf(mult, 0.1, 1.0)


static func _pincer_wing_has_active_commitment(manager: Node, c: Dictionary) -> bool:
    var tid: int = c.get(DataKeys.DOCTRINE_TARGET_COMMIT_ID, -1)
    if tid < 0:
        return false
    if manager == null:
        return true
    var clock: float = CombatantEntityAccess.combat_clock_float(manager)
    if clock > c.get(DataKeys.DOCTRINE_COMMIT_UNTIL, 0.0):
        return false
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, tid)
    return not tgt.is_empty() and CombatantEntityAccess.is_standing_combatant(tgt)


## When a **center** fighter commits, stamp matching **flank_wing** allies toward outer enemy files (pincer mop-up).
static func propagate_pincer_wing_commitments_from_center(
    manager: Node, center_id: int, _center_target_id: int
) -> void:
    if manager == null or center_id < 0:
        return
    var center: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, center_id)
    if center.is_empty():
        return
    if pincer_role_for_combatant(manager, center) != PINCER_ROLE_CENTER:
        return
    var fid: String = CombatantEntityAccess.formation_id_str(center)
    var until: float = (
        CombatantEntityAccess.combat_clock_float(manager) + CombatConstants.DOCTRINE_COMMITMENT_DURATION_S
    )
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var wing := raw as Dictionary
        if CombatantEntityAccess.formation_id_str(wing) != fid:
            continue
        if CombatantEntityAccess.rank_int(wing) != 0:
            continue
        if pincer_role_for_combatant(manager, wing) != PINCER_ROLE_FLANK_WING:
            continue
        if _pincer_wing_has_active_commitment(manager, wing):
            continue
        var wing_tgt: int = preferred_pincer_flank_enemy_id(manager, wing)
        if wing_tgt < 0:
            continue
        wing[DataKeys.DOCTRINE_TARGET_COMMIT_ID] = wing_tgt
        wing[DataKeys.DOCTRINE_COMMIT_UNTIL] = until


## III-4 **3e**: few enemies left, our side still has standing advantage (4v1 mop-up tail).
static func envelop_mop_up_active(manager: Node, formation_id: String) -> bool:
    if manager == null:
        return false
    var our_fid: String = formation_id.strip_edges()
    if our_fid.is_empty():
        return false
    var opp_fid: String = CombatantEntityAccess.opponent_side_label(our_fid)
    var our_active: int = _standing_active_count_for_side(manager, our_fid)
    var opp_active: int = _standing_active_count_for_side(manager, opp_fid)
    if opp_active > int(CombatConstants.ENVELOP_MOP_UP_MAX_ENEMY_ACTIVE):
        return false
    if our_active < int(CombatConstants.ENVELOP_MOP_UP_MIN_OUR_ACTIVE):
        return false
    return our_active > opp_active


## Mental stack L4b / trusted close: sparse rank-0, envelop mop-up (any rank), or last-enemy underdog with listed
## offense.
static func fight_finish_tail_active(manager: Node, c: Dictionary, actions: Array, combatant_id: int) -> bool:
    if manager == null or c.is_empty() or combatant_id < 0:
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    # Mop-up fighters don't need listed strikes — mop-up status itself is sufficient trigger.
    if envelop_mop_up_active(manager, fid):
        return true
    if not CombatListedActions.action_list_has_hostile_strike(actions, combatant_id):
        return false
    return (
        (
            CombatantEntityAccess.rank_int(c) == 0
            and CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
        )
        or mop_up_underdog_active(manager, c)
    )


## Opponent has mop-up advantage — this fighter's side is the last-enemy tail (underdog finish).
static func mop_up_underdog_active(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if fid.is_empty():
        return false
    return envelop_mop_up_active(manager, CombatantEntityAccess.opponent_side_label(fid))


## Close listing/resolve when band/reach disagree (MID/CLOSE band, out of swing range) during envelop.
## Pincer flank closes from **LONG** only — already CLOSE/MID without mop-up must not re-list close (F5 stall).
static func envelop_close_allowed(manager: Node, attacker: Dictionary, defender_id: int) -> bool:
    if manager == null or attacker.is_empty() or defender_id < 0:
        return false
    var fid: String = CombatantEntityAccess.formation_id_str(attacker)
    if envelop_mop_up_active(manager, fid):
        return true
    var band: String = CombatantEntityAccess.distance_to_opponent_band(attacker, defender_id)
    if band != CombatConstants.DISTANCE_LONG:
        return false
    if not pincer_flank_wing_should_close_at_long(manager, attacker):
        return false
    var pref: int = preferred_pincer_flank_enemy_id(manager, attacker)
    return pref < 0 or pref == defender_id


## L4 / mental-stack: wing lacks map, pincer flank role, or envelop mop-up.
static func hold_line_close_pick_eligible(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    if EngagementOpposition.wing_lacks_mapped_opposition(manager, c):
        return true
    if pincer_flank_wing_should_close_at_long(manager, c):
        return true
    if EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
        return true
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if (
        CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
        and CombatantEntityAccess.rank_int(c) == 0
    ):
        return true
    return envelop_mop_up_active(manager, fid)


## Sparse / fight-finish: prefer close/strike over formation shuffle (hints, focus damp, swap damp).
static func sparse_line_prefer_finish_over_shuffle(
    manager: Node, c: Dictionary, actions: Array, combatant_id: int = -1
) -> bool:
    if manager == null or c.is_empty():
        return false
    var cid: int = combatant_id if combatant_id >= 0 else CombatantEntityAccess.id_int(c)
    if fight_finish_tail_active(manager, c, actions, cid):
        return true
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if not CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        return false
    if CombatListedActions.action_list_has_hostile_melee_strike(actions, cid):
        return true
    if CombatantEntityAccess.rank_int(c) == 0 and _sparse_rank0_opponent_in_close_or_mid_band(manager, c):
        return true
    return false


## Skirmish rotate shuffle — skip when mop-up and menu has no listed melee (close-only still suppresses).
## Also skip on sparse post-flee lines when strikes/close are listed (distant holes — adjacent rotate cannot help).
## Rank-0 sparse + CLOSE/MID opposed band: finish engagement — line-plug rotate cannot help distant holes.
static func should_suppress_skirmish_rotate_file(manager: Node, c: Dictionary, actions: Array) -> bool:
    if manager == null or c.is_empty():
        return false
    var cid: int = CombatantEntityAccess.id_int(c)
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    if envelop_mop_up_active(manager, fid):
        return not CombatListedActions.action_list_has_hostile_melee_strike(actions, cid)
    if (
        CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
        and CombatListedActions.action_list_has_hostile_strike(actions, cid)
    ):
        return true
    if (
        CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
        and CombatantEntityAccess.rank_int(c) == 0
        and _sparse_rank0_opponent_in_close_or_mid_band(manager, c)
    ):
        return true
    if EngagementOpposition.rank0_needs_bind_close_at_long(manager, c):
        return true
    return false


static func _sparse_rank0_opponent_in_close_or_mid_band(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var opp_side: String = CombatantEntityAccess.opponent_side_for(c)
    if opp_side.is_empty():
        return false
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var opp := raw as Dictionary
        if not CombatantEntityAccess.is_living_on_side(opp, opp_side):
            continue
        var band: String = CombatantEntityAccess.distance_to_opponent_band(c, CombatantEntityAccess.id_int(opp))
        if band == CombatConstants.DISTANCE_CLOSE or band == CombatConstants.DISTANCE_MID:
            return true
    return false


static func _standing_active_count_for_side(manager: Node, side: String) -> int:
    if manager == null:
        return 0
    var fid: String = side.strip_edges()
    if fid.is_empty():
        return 0
    var n: int = 0
    for raw in manager.combatants:
        if raw is not Dictionary:
            continue
        var c := raw as Dictionary
        if not CombatantEntityAccess.is_standing_combatant(c):
            continue
        if CombatantEntityAccess.formation_id_str(c) != fid:
            continue
        n += 1
    return n
