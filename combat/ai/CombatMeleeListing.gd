class_name CombatMeleeListing
extends RefCounted

## Melee strike / attempt-close action listing and **`can_melee_threaten`** (reach + band + rank gates).
## Footing: lists strikes only — does **not** stamp PA or write **`guard_line`**. LIVE_PATHS **`#wf-pick-vs-strike`**.
## **Read order:** live rows |' threaten checks |' append listing (uses
## **`ZoneOfControl.opponent_formation_for_listing`**).


## Live **`CombatManager.combatants`** dicts (not UI snapshot from **`get_combatants()`**).
static func _live_combatant_rows(manager: Node) -> Array:
    if manager == null:
        return []
    var live: Variant = manager.get("combatants")
    if live is Array:
        return live as Array
    if manager.has_method("get_combatants"):
        return manager.get_combatants()
    return []


static func melee_weapon_reach(c: Dictionary) -> float:
    return CombatantEntityAccess.weapon_melee_reach(c, 0.0)


static func can_melee_threaten(
    manager: Node, attacker: Dictionary, defender: Dictionary, pair_geometry_cache: Variant = null
) -> bool:
    if not CombatantEntityAccess.are_living_hostiles(attacker, defender):
        return false
    if not CombatMeleeRankTargeting.melee_pair_rank_allowed(manager, attacker, defender):
        return false
    if CombatantEntityAccess.get_attacking_arm(attacker).is_empty():
        return false
    var weapon = CombatantEntityAccess.get_weapon(attacker)
    if not CombatantEntityAccess.weapon_has_attack_types(weapon):
        return false
    var melee_range: float = float(weapon.melee_range)
    var eff_dist: float = CombatPairGeometry.cached_eff_dist(pair_geometry_cache)
    if eff_dist < 0.0:
        eff_dist = CombatPairGeometry.cached_eff_dist(
            CombatPairGeometry.effective_pair_geometry(manager, attacker, defender)
        )
    var reach_for_threaten: float = melee_range + ZoneOfControl.weapon_reach_zoc_bonus_m(manager, attacker, defender)
    var dist: String = CombatantEntityAccess.distance_to_opponent_band(attacker, CombatantEntityAccess.id_int(defender))
    if envelop_mop_up_strike_at_band(manager, attacker, dist):
        return true
    if not CombatPairGeometry.melee_reach_covers_eff_dist(reach_for_threaten, eff_dist):
        return false
    return dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID


## III-4 **3e**: post-rout mop-up — CLOSE/MID band may lag geometric reach; finish with strikes.
static func envelop_mop_up_strike_at_band(manager: Node, attacker: Dictionary, band: String) -> bool:
    if band != CombatConstants.DISTANCE_CLOSE and band != CombatConstants.DISTANCE_MID:
        return false
    if manager == null or attacker.is_empty():
        return false
    return CombatDoctrine.envelop_mop_up_active(manager, CombatantEntityAccess.formation_id_str(attacker))


static func close_attempt_pair_blocked(manager: Node, attacker: Dictionary, defender_id: int) -> bool:
    var d: Dictionary = CombatantEntityAccess.nested_dictionary_read(attacker, "close_block_until_by_target_id")
    if d.is_empty():
        return false
    var until: Variant = d.get(defender_id, -1.0)
    return CombatantEntityAccess.timestamp_cooldown_active(manager, float(until), -1.0)


static func max_close_slots_for_defender(manager: Node, defender: Dictionary) -> int:
    if defender.is_empty():
        return CombatConstants.CLOSE_SLOTS_PER_TARGET
    var ctx: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, defender)
    var form_geom: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(ctx)
    var density: String = str(form_geom.get(DataKeys.FORMATION_DENSITY, "normal")) if not form_geom.is_empty() else "normal"
    return CombatConstants.max_close_slots_for_density(density)


## Living opponents already at **DISTANCE_CLOSE** vs **defender_id** (optional **exclude_attacker_id**).
static func count_close_attackers_on_defender(manager: Node, defender_id: int, exclude_attacker_id: int = -1) -> int:
    if manager == null:
        return 0
    var defender: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    if defender.is_empty():
        return 0
    var n: int = 0
    for raw in _live_combatant_rows(manager):
        if raw is not Dictionary:
            continue
        var atk: Dictionary = raw as Dictionary
        var aid: int = CombatantEntityAccess.id_int(atk)
        if aid == defender_id or aid == exclude_attacker_id:
            continue
        if not CombatantEntityAccess.is_standing_combatant(atk):
            continue
        if not CombatantEntityAccess.are_living_hostiles(atk, defender):
            continue
        if CombatantEntityAccess.distance_to_opponent_band(atk, defender_id) == CombatConstants.DISTANCE_CLOSE:
            n += 1
    return n


static func defender_has_free_close_slot(manager: Node, defender: Dictionary, exclude_attacker_id: int = -1) -> bool:
    var cap: int = max_close_slots_for_defender(manager, defender)
    return count_close_attackers_on_defender(manager, CombatantEntityAccess.id_int(defender), exclude_attacker_id) < cap


## Fight-finish / sparse: drop redundant **`attempt_close`** at CLOSE/MID when melee is already listed.
static func strip_redundant_attempt_close_for_finish(manager: Node, c: Dictionary, actions: Array) -> void:
    if manager == null or c.is_empty() or actions.is_empty():
        return
    var cid: int = CombatantEntityAccess.id_int(c)
    if not CombatDoctrine.sparse_line_prefer_finish_over_shuffle(manager, c, actions, cid):
        return
    if not CombatListedActions.action_list_has_hostile_melee_strike(actions, cid):
        return
    var to_remove: Array = []
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if str(a.get(DataKeys.ACTION_MOVE_ID, "")) != CombatConstants.MOVE_ID_ATTEMPT_CLOSE:
            continue
        var tgt_id: int = a.get(DataKeys.ACTION_TARGET_ID, -1)
        if tgt_id < 0:
            continue
        var dist: String = CombatantEntityAccess.distance_to_opponent_band(c, tgt_id, "")
        if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID:
            to_remove.append(raw)
    for entry in to_remove:
        actions.erase(entry)


static func _append_attempt_close_action(actions: Array, opp: Dictionary) -> void:
    var entry: Dictionary = {
        "target_id": CombatantEntityAccess.id_int(opp),
        "move_id": CombatConstants.MOVE_ID_ATTEMPT_CLOSE,
    }
    var hint: String = CombatUiHints.close_attempt_list_hint_for_defender(opp)
    if not hint.is_empty():
        entry[CombatConstants.ACTION_KEY_CLOSE_LIST_HINT] = hint
    actions.append(entry)


static func attempt_close_listed_for_pair(manager: Node, attacker: Dictionary, defender_id: int, dist: String) -> bool:
    if dist != CombatConstants.DISTANCE_LONG:
        if dist != CombatConstants.DISTANCE_CLOSE and dist != CombatConstants.DISTANCE_MID:
            return false
        if not CombatDoctrine.envelop_close_allowed(manager, attacker, defender_id):
            return false
    else:
        var defender_long: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
        if not defender_long.is_empty():
            var reach: float = CombatantEntityAccess.weapon_melee_reach(attacker)
            var eff: float = CombatPairGeometry.effective_pair_eff_dist(manager, attacker, defender_long)
            if CombatPairGeometry.melee_reach_covers_eff_dist(reach, eff):
                return false
    if close_attempt_pair_blocked(manager, attacker, defender_id):
        return false
    var defender: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    if defender.is_empty():
        return false
    return defender_has_free_close_slot(manager, defender, CombatantEntityAccess.id_int(attacker))


static func append_melee_vs_enemy_line_rank(
    manager: Node,
    c: Dictionary,
    combatants: Array,
    actions: Array,
    move_ids: Array,
    melee_range: float,
    opp_rank_required: int,
    actor_zone_geometry_line_context: Dictionary = {},
    zone_geometry_by_combatant_id: Dictionary = {}
) -> void:
    var fc: Dictionary = ZoneOfControl.zone_geometry_formation_from_pack(actor_zone_geometry_line_context)
    if fc.is_empty():
        fc = ZoneOfControl.formation_for_combatant_cached(manager, c, null)
    var flurry_only_id: int = CombatFlurryBind.listing_restrict_opponent_id(c, manager)
    for opp in CombatTargetScoring.ordered_melee_opponents(
        manager, c, combatants, opp_rank_required, actor_zone_geometry_line_context
    ):
        var opp_id: int = CombatantEntityAccess.id_int(opp)
        if flurry_only_id >= 0 and opp_id != flurry_only_id:
            continue
        var fo: Dictionary = ZoneOfControl.opponent_formation_for_listing(
            manager, c, opp, zone_geometry_by_combatant_id, fc
        )
        var pair_geom: Dictionary = CombatPairGeometry.effective_pair_geometry(manager, c, opp, fc, fo)
        var eff_dist: float = CombatPairGeometry.cached_eff_dist(pair_geom)
        var reach_for_listing: float = melee_range + ZoneOfControl.weapon_reach_zoc_bonus_m(manager, c, opp)
        var in_swing_range: bool = CombatPairGeometry.melee_reach_covers_eff_dist(reach_for_listing, eff_dist)
        var dist: String = CombatantEntityAccess.distance_to_opponent_band(c, CombatantEntityAccess.id_int(opp))
        var mop_up_strike: bool = envelop_mop_up_strike_at_band(manager, c, dist)
        if in_swing_range or mop_up_strike:
            # Geometric reach covers even when band still says LONG (pre-recompute lag) — strike, don't close.
            if dist == CombatConstants.DISTANCE_CLOSE or dist == CombatConstants.DISTANCE_MID or in_swing_range:
                for move_id in move_ids:
                    if WeaponConstants.is_parry_move(move_id):
                        continue
                    if (move_id == CombatConstants.MOVE_ID_BIND_PRESS or move_id == CombatConstants.MOVE_ID_BIND_VOID or move_id == CombatConstants.MOVE_ID_BIND_WIND) and not CombatBindPressure.is_in_bind(c, CombatantEntityAccess.combat_clock_float(manager)):
                        continue
                    if move_id == CombatConstants.MOVE_ID_BIND_WRESTLE and (not CombatBindPressure.is_in_bind(c, CombatantEntityAccess.combat_clock_float(manager)) or not CombatBindPressure.has_wrestling_available(c)):
                        continue
                    actions.append({"target_id": CombatantEntityAccess.id_int(opp), "move_id": move_id})
            elif attempt_close_listed_for_pair(manager, c, CombatantEntityAccess.id_int(opp), dist):
                _append_attempt_close_action(actions, opp)
        else:
            if attempt_close_listed_for_pair(manager, c, CombatantEntityAccess.id_int(opp), dist):
                _append_attempt_close_action(actions, opp)


static func append_melee_actions_for_combatant(
    manager: Node,
    c: Dictionary,
    combatants: Array,
    actions: Array,
    formation_retreat_only: bool,
    zone_geometry_line_context_cache: Dictionary = {}
) -> void:
    if formation_retreat_only:
        return
    var ctx_self: Dictionary = zone_geometry_line_context_cache
    if ctx_self.is_empty():
        ctx_self = ZoneOfControl.zone_geometry_line_context(manager, c)
    var fid: String = ZoneOfControl.zone_geometry_fid_from_pack(ctx_self)
    var our_rank: int = CombatantEntityAccess.rank_int(c)
    var can_melee: bool = (
        (our_rank == 0 or CombatDepthPolearm.depth_polearm_lane_open(manager, c, fid))
        and not CombatantEntityAccess.get_attacking_arm(c).is_empty()
    )
    if not can_melee:
        return
    var weapon = CombatantEntityAccess.get_weapon(c)
    if not CombatantEntityAccess.weapon_has_attack_types(weapon):
        return
    var melee_range: float = float(weapon.melee_range)
    var move_ids: Array = CombatantEntityAccess.weapon_attack_types(weapon)
    var opp_zone: Dictionary = ZoneOfControl.zone_geometry_line_context_by_combatant_id(manager)
    append_melee_vs_enemy_line_rank(manager, c, combatants, actions, move_ids, melee_range, 0, ctx_self, opp_zone)
    if not CombatMeleeRankTargeting.any_living_enemy_rank0_target(manager, c, combatants):
        append_melee_vs_enemy_line_rank(manager, c, combatants, actions, move_ids, melee_range, 1, ctx_self, opp_zone)
    strip_redundant_attempt_close_for_finish(manager, c, actions)
    append_execute_actions_for_combatant(manager, c, combatants, actions)


## Mercy execute listing: one entry per downed opponent in reach — bypasses living-hostile
## and rank gates (the target has already been beaten down; only reach + attacking arm apply).
static func append_execute_actions_for_combatant(
    manager: Node,
    c: Dictionary,
    combatants: Array,
    actions: Array
) -> void:
    if not CombatConstantsFeatureFlags.is_feature_mercy_execute_enabled():
        return
    if manager == null or c.is_empty() or combatants.is_empty() or actions == null:
        return
    if CombatantEntityAccess.get_attacking_arm(c).is_empty():
        return
    var weapon = CombatantEntityAccess.get_weapon(c)
    if not CombatantEntityAccess.weapon_has_attack_types(weapon):
        return
    var melee_range: float = float(weapon.melee_range)
    for raw in combatants:
        if raw is not Dictionary:
            continue
        var opp: Dictionary = raw as Dictionary
        if not CombatExecute.is_downed_opponent_of(manager, c, opp):
            continue
        if not execute_target_in_reach(manager, c, opp, melee_range):
            continue
        var opp_id: int = CombatantEntityAccess.id_int(opp)
        var already: bool = false
        for existing in actions:
            if existing is not Dictionary:
                continue
            if str(existing.get("move_id", "")) == CombatConstants.MOVE_ID_EXECUTE and int(existing.get("target_id", -1)) == opp_id:
                already = true
                break
        if already:
            continue
        actions.append({
            "target_id": opp_id,
            "move_id": CombatConstants.MOVE_ID_EXECUTE,
        })


## Whether any downed opponent is in execute reach. Used by the action-build counter-tempo gate to keep the
## mercy/execute option listed even at sub-100 gauge (coup de gràce on a lone beaten-down target).
static func downed_opponent_in_reach(manager: Node, c: Dictionary, combatants: Array) -> bool:
    if manager == null or c.is_empty() or combatants.is_empty():
        return false
    if CombatantEntityAccess.get_attacking_arm(c).is_empty():
        return false
    var weapon = CombatantEntityAccess.get_weapon(c)
    if weapon == null or not CombatantEntityAccess.weapon_has_attack_types(weapon):
        return false
    var melee_range: float = float(weapon.melee_range)
    for raw in combatants:
        if raw is not Dictionary:
            continue
        var opp: Dictionary = raw as Dictionary
        if not CombatExecute.is_downed_opponent_of(manager, c, opp):
            continue
        if execute_target_in_reach(manager, c, opp, melee_range):
            return true
    return false


## Reach check for an execute (downed target): mop-up band or geometric reach covering eff dist.
static func execute_target_in_reach(manager: Node, attacker: Dictionary, defender: Dictionary, melee_range: float) -> bool:
    if manager == null or attacker.is_empty() or defender.is_empty():
        return false
    var dist: String = CombatantEntityAccess.distance_to_opponent_band(attacker, CombatantEntityAccess.id_int(defender))
    if envelop_mop_up_strike_at_band(manager, attacker, dist):
        return true
    if dist != CombatConstants.DISTANCE_CLOSE and dist != CombatConstants.DISTANCE_MID:
        return false
    var eff_dist: float = CombatPairGeometry.effective_pair_eff_dist(manager, attacker, defender)
    var reach_for_threaten: float = melee_range + ZoneOfControl.weapon_reach_zoc_bonus_m(manager, attacker, defender)
    return CombatPairGeometry.melee_reach_covers_eff_dist(reach_for_threaten, eff_dist)
