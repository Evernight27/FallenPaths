class_name CombatFormationMoveListing
extends RefCounted

## Formation movement actions: swap rank, drag/fall_back pair, solo fall_back, rotate file (line discipline).
## Footing: lists/resolves slot moves only  -  lane duration via **`CombatFormationMoveDuration`**; **not**
## **`guard_line`** / PA / **`weapon_form`**. LIVE_PATHS **`#wf-footing-terminology`**.

# Runtime preload '" circular dependency (CombatFormationFlee preloads CombatFormationMoveListing).
static var _flee_cache: Variant = null
static var _yield_cache: Variant = null


static func _get_flee() -> GDScript:
    if _flee_cache == null:
        _flee_cache = load("res://combat/CombatFormationFlee.gd")
    return _flee_cache


static func _get_yield() -> GDScript:
    if _yield_cache == null:
        _yield_cache = load("res://combat/CombatFormationYield.gd")
    return _yield_cache


static func _append_formation_action(manager: Node, initiator: Dictionary, actions: Array, entry: Dictionary) -> void:
    actions.append(entry)
    if manager != null and not initiator.is_empty():
        CombatFormationMoveDuration.stamp_listed_action_duration_hint(manager, initiator, entry)


static func _in_formation_move_cooldown(manager: Node, c: Dictionary, cooldown_key: String) -> bool:
    return CombatantEntityAccess.combatant_cooldown_active(manager, c, cooldown_key, -1.0)


static func in_rotate_file_cooldown(manager: Node, c: Dictionary) -> bool:
    return _in_formation_move_cooldown(manager, c, "formation_rotate_file_cooldown_until")


static func in_pair_abort_cooldown(manager: Node, c: Dictionary) -> bool:
    return _in_formation_move_cooldown(manager, c, "formation_pair_abort_cooldown_until")


static func _in_plug_forward_cooldown(manager: Node, c: Dictionary) -> bool:
    return _in_formation_move_cooldown(manager, c, "formation_plug_forward_cooldown_until")


static func pair_formation_move_abort_blocked(manager: Node, c: Dictionary, partner: Dictionary = {}) -> bool:
    if manager == null or c.is_empty():
        return true
    if in_pair_abort_cooldown(manager, c):
        return true
    if not partner.is_empty() and in_pair_abort_cooldown(manager, partner):
        return true
    return false


static func adjacent_rank_pair_move_legal(
    manager: Node, c: Dictionary, partner: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if manager == null or c.is_empty() or partner.is_empty():
        return false
    if pair_formation_move_abort_blocked(manager, c, partner):
        return false
    var ctx: Dictionary = zone_geometry_line_context_cache
    if ctx.is_empty():
        ctx = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx)
    if fid.is_empty():
        return false
    return _is_adjacent_rank_ally(
        manager, c, partner, fid, CombatantEntityAccess.rank_int(c), CombatantEntityAccess.file_int(c)
    )


static func _rank_pair_swap_context(manager: Node, c: Dictionary, partner: Dictionary, fid: String) -> Dictionary:
    var our_rank: int = CombatantEntityAccess.rank_int(c)
    var partner_rank: int = CombatantEntityAccess.rank_int(partner)
    var partner_incapacitated: bool = CombatantEntityAccess.is_incapacitated(partner)
    var we_are_front: bool = partner_rank > our_rank
    var we_plug_forward: bool = partner_rank < our_rank and partner_incapacitated
    var relief_swap: bool = (
        our_rank > partner_rank
        and not partner_incapacitated
        and CombatAIActionPicker.is_relief_swap_tactically_allowed(c, partner)
    )
    var line_plug_relief: bool = (
        our_rank > partner_rank
        and not partner_incapacitated
        and not relief_swap
        and CombatFormationFlow.formation_line_has_rank0_gap(manager, fid)
        and not CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid)
    )
    var eligible: bool = (
        (we_are_front and not partner_incapacitated) or we_plug_forward or relief_swap or line_plug_relief
    )
    var allow_swap: bool = false
    if we_plug_forward:
        allow_swap = true
    elif relief_swap or line_plug_relief:
        allow_swap = true
    elif we_are_front:
        allow_swap = CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, partner, manager)
    return {
        "eligible": eligible,
        "allow_swap": allow_swap,
        "we_are_front": we_are_front,
        "we_plug_forward": we_plug_forward,
        "line_plug_relief": line_plug_relief,
    }


## MS-L5: true when this listed action plugs a rank-0 gap or steps over an incapacitated front partner.
static func listed_action_is_formation_plug_pick(
    manager: Node, c: Dictionary, action: Dictionary, all_actions: Array, combatant_id: int
) -> bool:
    if manager == null or c.is_empty() or action.is_empty():
        return false
    var mid: String = str(action.get("move_id", ""))
    var our_rank: int = CombatantEntityAccess.rank_int(c)
    var fid: String = CombatantEntityAccess.formation_id_str(c)
    var line_gap: bool = CombatFormationFlow.formation_line_has_rank0_gap(manager, fid)
    if mid == CombatConstants.MOVE_ID_SWAP_RANK:
        var partner_id: int = action.get("target_id", -1)
        var partner: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, partner_id)
        if partner.is_empty() or not swap_rank_action_legal(manager, c, partner):
            return false
        var pc: Dictionary = _rank_pair_swap_context(manager, c, partner, fid)
        if pc.get("we_plug_forward", false):
            return true
        return line_gap and our_rank > 0 and pc.get("line_plug_relief", false)
    if mid != CombatConstants.MOVE_ID_ROTATE_FILE or our_rank != 0 or not line_gap:
        return false
    if CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, all_actions):
        return false
    if CombatFormationFlow.skirmish_line_sparse_after_casualties(manager, fid):
        return false
    if (
        not all_actions.is_empty()
        and CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, all_actions, combatant_id)
    ):
        return false
    if not all_actions.is_empty() and CombatListedActions.action_list_has_hostile_strike(all_actions, combatant_id):
        return false
    if str(CombatEngagementMode.engagement_mode(manager)) != CombatConstants.ENGAGEMENT_MODE_SKIRMISH:
        return false
    var rot_partner_id: int = action.get("target_id", -1)
    var rot_partner: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, rot_partner_id)
    if rot_partner.is_empty():
        return false
    return rotate_file_action_legal(manager, c, rot_partner)


static func swap_rank_action_legal(
    manager: Node, c: Dictionary, partner: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if not adjacent_rank_pair_move_legal(manager, c, partner, zone_geometry_line_context_cache):
        return false
    var ctx: Dictionary = zone_geometry_line_context_cache
    if ctx.is_empty():
        ctx = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx)
    if fid.is_empty():
        return false
    var pc: Dictionary = _rank_pair_swap_context(manager, c, partner, fid)
    return pc.get("eligible", false) and pc.get("allow_swap", false)


## III-4 **3e**: depth fighter can plug forward into rank-0 during envelop mop-up.
static func plug_forward_action_legal(
    manager: Node, c: Dictionary, partner: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if manager == null or c.is_empty() or partner.is_empty():
        return false
    if _in_plug_forward_cooldown(manager, c):
        return false
    if not adjacent_rank_pair_move_legal(manager, c, partner, zone_geometry_line_context_cache):
        return false
    var ctx: Dictionary = zone_geometry_line_context_cache
    if ctx.is_empty():
        ctx = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx)
    if fid.is_empty():
        return false
    # Depth fighter (rank > 0) plugging into rank-0 partner.
    if CombatantEntityAccess.rank_int(c) <= CombatantEntityAccess.rank_int(partner):
        return false
    if CombatantEntityAccess.rank_int(partner) != 0:
        return false
    # Same file check  -  plug_forward requires same file, adjacent ranks.
    if CombatantEntityAccess.file_int(c) != CombatantEntityAccess.file_int(partner):
        return false
    # Only during envelop mop-up.
    if not CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.side_str(c)):
        return false
    # Target rank-0 slot must be empty or occupied by the partner.
    var formation: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
    if formation.is_empty():
        return false
    var slots: Dictionary = FormationSlots.formation_slots_dict(formation)
    var f: int = CombatantEntityAccess.file_int(c)
    var target_slot_id: int = FormationSlots.slot_primary_id(slots, Vector2i(0, f))
    if target_slot_id != -1 and target_slot_id != CombatantEntityAccess.id_int(partner):
        return false
    return true


static func front_rank_paired_retreat_action_legal(
    manager: Node, c: Dictionary, partner: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if not adjacent_rank_pair_move_legal(manager, c, partner, zone_geometry_line_context_cache):
        return false
    var ctx: Dictionary = zone_geometry_line_context_cache
    if ctx.is_empty():
        ctx = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx)
    if fid.is_empty():
        return false
    var pc: Dictionary = _rank_pair_swap_context(manager, c, partner, fid)
    if pc.get("we_are_front", false) != true or pc.get("we_plug_forward", false):
        return false
    return CombatAIActionPicker.is_disengage_swap_tactically_allowed(c, partner, manager)


static func solo_fall_back_action_legal(
    manager: Node, atk: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if manager == null or atk.is_empty():
        return false
    if not CombatantEntityAccess.can_flee_or_fall_back(atk):
        return false
    if CombatantEntityAccess.rank_int(atk) != 0:
        return false
    if in_pair_abort_cooldown(manager, atk):
        return false
    var ctx_atk: Dictionary = zone_geometry_line_context_cache
    if ctx_atk.is_empty():
        ctx_atk = ZoneOfControl.zone_geometry_line_context(manager, atk)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_atk)
    var our_formation: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_atk)
    if our_formation.is_empty():
        return false
    if int(our_formation.get("ranks", 1)) <= 1:
        return false
    var disc: String = CombatFormationEngagement.effective_line_discipline(manager, our_formation)
    if not CombatConstants.line_discipline_allows_solo_fall_back(disc):
        return false
    var our_file: int = CombatantEntityAccess.file_int(atk)
    var slots_check: Dictionary = FormationSlots.formation_slots_dict(our_formation)
    if FormationSlots.slot_has_any_living_occupant(manager, slots_check, Vector2i(1, our_file)):
        return false
    if CombatFormationFlow.formation_has_frontline_fill_opportunity_at_file(manager, fid, our_file):
        return false
    return CombatantEntityAccess.retreat_formation_body_damage_warranted(atk, manager)


static func _is_adjacent_rank_ally(
    manager: Node, c: Dictionary, ally: Dictionary, fid: String, our_rank: int, our_file: int
) -> bool:
    if not CombatantEntityAccess.is_available_formation_partner(c, ally):
        return false
    if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, ally, fid):
        return false
    if (
        CombatantEntityAccess.state_str(ally)
        in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
    ):
        return false
    var partner_rank: int = CombatantEntityAccess.rank_int(ally)
    var partner_file: int = CombatantEntityAccess.file_int(ally)
    return partner_file == our_file and abs(partner_rank - our_rank) == 1


static func _is_adjacent_file_same_rank_ally(
    manager: Node, c: Dictionary, ally: Dictionary, fid: String, our_rank: int, our_file: int
) -> bool:
    if not CombatantEntityAccess.is_available_formation_partner(c, ally):
        return false
    if not ZoneOfControl.combatant_on_zone_geometry_fid(manager, ally, fid):
        return false
    if (
        CombatantEntityAccess.state_str(ally)
        in [CombatConstants.STATE_SWAP_RANK, CombatConstants.STATE_FALLING_BACK, CombatConstants.STATE_PLUG_FORWARD]
    ):
        return false
    var partner_rank: int = CombatantEntityAccess.rank_int(ally)
    var partner_file: int = CombatantEntityAccess.file_int(ally)
    return partner_rank == our_rank and abs(partner_file - our_file) == 1


static func rotate_file_action_legal(
    manager: Node, c: Dictionary, ally: Dictionary, zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if manager == null or c.is_empty() or ally.is_empty():
        return false
    if CombatantEntityAccess.rank_int(c) != 0:
        return false
    if in_pair_abort_cooldown(manager, c) or in_rotate_file_cooldown(manager, c):
        return false
    if in_rotate_file_cooldown(manager, ally):
        return false
    if CombatFormationFlow.rotate_file_reverse_pair_blocked(manager, c, CombatantEntityAccess.id_int(ally)):
        return false
    var ctx: Dictionary = zone_geometry_line_context_cache
    if ctx.is_empty():
        ctx = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx)
    if fid.is_empty():
        return false
    if int(ZoneOfControl.zone_geometry_formation_from_pack(ctx).get("files", 1)) < 2:
        return false
    return _is_adjacent_file_same_rank_ally(
        manager, c, ally, fid, CombatantEntityAccess.rank_int(c), CombatantEntityAccess.file_int(c)
    )


static func _append_rotate_file_partner_actions(
    manager: Node,
    c: Dictionary,
    combatants: Array,
    fid: String,
    our_rank: int,
    our_file: int,
    actions: Array,
    zone_geometry_line_context_cache: Dictionary = {}
) -> void:
    for ally in combatants:
        if not _is_adjacent_file_same_rank_ally(manager, c, ally, fid, our_rank, our_file):
            continue
        if not rotate_file_action_legal(manager, c, ally, zone_geometry_line_context_cache):
            continue
        var ally_id: int = CombatantEntityAccess.id_int(ally)
        if CombatListedActions.actions_include_move_vs_target(actions, ally_id, CombatConstants.MOVE_ID_ROTATE_FILE):
            continue
        _append_formation_action(
            manager, c, actions, {"target_id": ally_id, "move_id": CombatConstants.MOVE_ID_ROTATE_FILE}
        )


static func _append_adjacent_rank_partner_actions(
    manager: Node,
    c: Dictionary,
    combatants: Array,
    fid: String,
    our_rank: int,
    our_file: int,
    actions: Array,
    can_drag_back: bool,
    zone_geometry_line_context_cache: Dictionary = {}
) -> void:
    for ally in combatants:
        if not _is_adjacent_rank_ally(manager, c, ally, fid, our_rank, our_file):
            continue
        if not swap_rank_action_legal(manager, c, ally, zone_geometry_line_context_cache):
            continue
        var pc: Dictionary = _rank_pair_swap_context(manager, c, ally, fid)
        _append_formation_action(
            manager,
            c,
            actions,
            {"target_id": CombatantEntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_SWAP_RANK}
        )
        if pc.get("we_are_front", false) and pc.get("we_plug_forward", false) != true and can_drag_back:
            if front_rank_paired_retreat_action_legal(manager, c, ally, zone_geometry_line_context_cache):
                _append_formation_action(
                    manager,
                    c,
                    actions,
                    {"target_id": CombatantEntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_DRAG_BACK}
                )
                _append_formation_action(
                    manager,
                    c,
                    actions,
                    {"target_id": CombatantEntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_FALL_BACK}
                )
        break


static func _solo_fall_back_listing_eligible(
    manager: Node,
    c: Dictionary,
    formation_ranks: int,
    our_rank: int,
    pair_abort_blocked: bool,
    zone_geometry_line_context_cache: Dictionary = {}
) -> bool:
    if formation_ranks <= 1 or our_rank != 0:
        return false
    if pair_abort_blocked:
        return false
    if not CombatantEntityAccess.can_flee_or_fall_back(c):
        return false
    return solo_fall_back_action_legal(manager, c, zone_geometry_line_context_cache)


## Appends swap / paired retreat / solo fall_back. Returns context for flow logs; **`cowering_early_exit`** when build
## should return after wait.
static func append_formation_move_actions(
    manager: Node,
    c: Dictionary,
    combatant_id: int,
    combatants: Array,
    actions: Array,
    formation_retreat_only: bool,
    zone_geometry_line_context_cache: Dictionary = {}
) -> Dictionary:
    var out: Dictionary = {"zone_fid": "", "cowering_early_exit": false}
    if manager == null or c.is_empty():
        return out
    var ctx_c: Dictionary = zone_geometry_line_context_cache
    if ctx_c.is_empty():
        ctx_c = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_c)
    var our_formation: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx_c)
    var our_rank: int = CombatantEntityAccess.rank_int(c)
    var our_file: int = CombatantEntityAccess.file_int(c)
    out["zone_fid"] = fid
    var formation_ranks: int = int(our_formation.get("ranks", 1))
    var pair_abort_blocked: bool = in_pair_abort_cooldown(manager, c)
    var move_policy: Dictionary = CombatEngagementMode.movement_policy(manager)
    var can_swap_rank: bool = move_policy.get("allow_swap_rank", false)
    var can_drag_back: bool = move_policy.get("allow_drag_back", false)
    var can_fall_back: bool = move_policy.get("allow_fall_back", false)
    var home_fid: String = CombatantEntityAccess.formation_id_str(c)
    var can_rotate_file: bool = CombatEngagementMode.allow_rotate_file_for_formation(manager, home_fid)
    if (
        not formation_retreat_only
        and not our_formation.is_empty()
        and formation_ranks > 1
        and not pair_abort_blocked
        and CombatantEntityAccess.can_flee_or_fall_back(c)
        and (can_swap_rank or can_drag_back)
    ):
        _append_adjacent_rank_partner_actions(
            manager, c, combatants, fid, our_rank, our_file, actions, can_drag_back, ctx_c
        )
    if (
        not formation_retreat_only
        and not our_formation.is_empty()
        and int(our_formation.get("files", 1)) >= 2
        and our_rank == 0
        and not pair_abort_blocked
        and can_rotate_file
        and not CombatDoctrine.should_suppress_skirmish_rotate_file(manager, c, actions)
    ):
        _append_rotate_file_partner_actions(manager, c, combatants, fid, our_rank, our_file, actions, ctx_c)
    # III-4 **3e**: depth fighter plug_forward listing (independent of swap_rank gate  -  fires during envelop mop-up).
    if (
        CombatConstants.ENVELOP_MOP_UP_PLUG_FORWARD_ENABLED
        and not formation_retreat_only
        and not our_formation.is_empty()
        and formation_ranks > 1
        and not pair_abort_blocked
        and CombatantEntityAccess.can_flee_or_fall_back(c)
        and our_rank > 0
    ):
        for ally in combatants:
            if not _is_adjacent_rank_ally(manager, c, ally, fid, our_rank, our_file):
                continue
            if CombatListedActions.actions_include_move_vs_target(
                actions, CombatantEntityAccess.id_int(ally), CombatConstants.MOVE_ID_PLUG_FORWARD
            ):
                continue
            if plug_forward_action_legal(manager, c, ally, ctx_c):
                _append_formation_action(
                    manager,
                    c,
                    actions,
                    {"target_id": CombatantEntityAccess.id_int(ally), "move_id": CombatConstants.MOVE_ID_PLUG_FORWARD}
                )
                break
    var solo_fb_ok: bool = _solo_fall_back_listing_eligible(
        manager, c, formation_ranks, our_rank, pair_abort_blocked, ctx_c
    )
    if solo_fb_ok and (formation_retreat_only or can_fall_back):
        _append_formation_action(
            manager, c, actions, {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FALL_BACK}
        )
    CombatFormationRout.ensure_rout_baseline(manager)
    if _get_yield().yield_action_legal(manager, c):
        _append_formation_action(
            manager, c, actions, {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_YIELD}
        )
    if _get_flee().flee_action_legal(manager, c):
        _get_flee().log_flee_listed_if_verbose(manager, c)
        _append_formation_action(
            manager, c, actions, {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_FLEE}
        )
    CombatLeaderFormationCommand.append_leader_formation_commands(manager, c, combatant_id, actions)
    if formation_retreat_only:
        out["cowering_early_exit"] = true
    return out


## When no combat actions exist, only formation moves remain, or only guard focus lines (no melee), offer **wait**.
## Without the hold-line branch, back rank gets focus-only menus -> AI cycles focus every turn (log/UI spam).
## Accepts manager/c to stamp a dampened weight when outnumbered/recovering.
## 2-arg harness variant: `append_combat_wait_if_needed(actions, combatant_id)`.
static func append_combat_wait_if_needed(manager: Node, c: Dictionary, actions: Array, combatant_id: int) -> void:
    if CombatListedActions.actions_include_move_id(actions, CombatConstants.MOVE_ID_WAIT):
        return
    var dampened: bool = false
    if manager != null and not c.is_empty():
        dampened = _is_wait_dampened(manager, c)
    if actions.is_empty():
        var entry: Dictionary = {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT}
        if dampened:
            entry["weight"] = 0.01
        actions.append(entry)
        return
    if CombatListedActions.action_list_is_reserve_posture_only(actions):
        var entry2: Dictionary = {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT}
        if dampened:
            entry2["weight"] = 0.01
        actions.append(entry2)
        return
    for a in actions:
        var mid: String = str(a.get("move_id", ""))
        if not CombatConstants.is_formation_movement_move(mid) and mid != CombatConstants.MOVE_ID_YIELD:
            return
    var entry3: Dictionary = {"target_id": combatant_id, "move_id": CombatConstants.MOVE_ID_WAIT}
    if dampened:
        entry3["weight"] = 0.01
    actions.append(entry3)


static func _is_wait_dampened(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var st: String = CombatantEntityAccess.state_str(c)
    if st == CombatConstants.STATE_RECOVERING:
        return true
    return not CombatFormationRout.side_holding_field(manager, c)
