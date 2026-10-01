class_name CombatIncomingParryChoice
extends RefCounted

## Tier 0: overlapping melee wind-ups on one defender — run **`can_parry_all`** first (split capacity via
## **`choose_defense`**); if false, commit passive parry to highest **perceived telegraph** only.
## III-1 tie-break: equal threat scores |' highest sector flank weight
## (**`TacticalCombat.sector_weight_for_attacker_on_defender`**).
## **`can_parry_all`** surround estimate uses **`TacticalCombat.stamp_surround_threat_on_pa`** (live scan — matches
## **`AttackResolver`**).
## **`parry_telegraph`** on **`pa`** (stamped at wind-up): commitment + contact type; feints inflate apparent telegraph
## until reveal.


static func incoming_attacker_ids_on_defender(manager: Node, defender_id: int, anchor_time: float = -1.0) -> Array:
    var out: Array = []
    if manager == null or defender_id < 0:
        return out
    var now: float = anchor_time if anchor_time >= 0.0 else CombatantEntityAccess.combat_clock_float(manager)
    var window: float = CombatConstants.INCOMING_MELEE_PARRY_WINDOW_S
    for c in manager.combatants:
        if c is not Dictionary:
            continue
        if not CombatantEntityAccess.alive_bool(c):
            continue
        if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WIND_UP:
            continue
        var aid: int = CombatantEntityAccess.id_int(c)
        var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(c, "pending_attack")
        if pa.get(DataKeys.ACTION_TARGET_ID, -1) != defender_id:
            continue
        var resolve_at: float = CombatEventScheduler.get_pending_melee_attack_resolve_at(manager, aid)
        if resolve_at < 0.0:
            continue
        if absf(resolve_at - now) <= window:
            out.append(aid)
    return out


## Base telegraph 0—1 from commitment rolls + contact type; optional move **`parry_telegraph`** override.
static func compute_base_parry_telegraph(pa: Dictionary, move_def: Dictionary) -> float:
    var move_override: float = move_def.get("parry_telegraph", -1.0)
    if move_override >= 0.0:
        return clampf(move_override, 0.0, 1.0)
    var intensity: float = clampf(
        pa.get(CombatConstants.PA_KEY_INTENSITY, CombatConstants.PA_DEFAULT_INTENSITY), 0.0, 1.0
    )
    var power: float = clampf(pa.get(DataKeys.ATTACK_POWER, 0.5), 0.0, 1.0)
    var follow: float = clampf(pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, 0.5), 0.0, 1.0)
    var commit: float = intensity * (0.55 + 0.45 * power) * (0.72 + 0.28 * follow)
    var contact: String = str(move_def.get(DataKeys.WEAPON_CONTACT_TYPE, WeaponConstants.ATTACK_TYPE_CUT))
    return clampf(commit * CombatConstants.parry_telegraph_contact_mult(contact), 0.0, 1.0)


## Stamp **`parry_telegraph`** + feint **`parry_telegraph_apparent`** on **`pa`** at wind-up start.
static func stamp_parry_telegraph_on_pa(pa: Dictionary, move_def: Dictionary) -> void:
    if pa.is_empty():
        return
    var base: float = compute_base_parry_telegraph(pa, move_def)
    pa[DataKeys.PA_PARRY_TELEGRAPH] = base
    if (
        not pa.get(DataKeys.ACTION_FEINT_PART, "").is_empty()
        or move_def.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false)
    ):
        var inflate: float = float(
            move_def.get("feint_parry_telegraph_mult", CombatConstants.PARRY_TELEGRAPH_FEINT_APPARENT_MULT)
        )
        pa[DataKeys.PA_PARRY_TELEGRAPH_APPARENT] = clampf(base * maxf(inflate, 1.0), 0.0, 1.15)
    else:
        pa.erase(DataKeys.PA_PARRY_TELEGRAPH_APPARENT)


static func _attacker_wind_up_progress(atk: Dictionary) -> float:
    var dur: float = atk.get(DataKeys.PA_STATE_DURATION, 0.0)
    if dur <= 0.0001:
        return 1.0
    return clampf(atk.get(DataKeys.PA_STATE_TIMER, 0.0) / dur, 0.0, 1.0)


## Defender-facing telegraph: feints look heavier early; perception reads through toward true commitment.
static func perceived_parry_telegraph(
    manager: Node, defender_id: int, attacker_id: int, _anchor_time: float = -1.0
) -> float:
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return 0.0
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
    if pa.is_empty():
        return 0.0
    var attack_type: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
    var move_def: Dictionary = WeaponConstants.get_move(attack_type) if not attack_type.is_empty() else {}
    # Always derive from current commitment rolls (harness may override intensity after wind-up).
    var base: float = compute_base_parry_telegraph(pa, move_def)
    var feint_part: String = str(pa.get(DataKeys.ACTION_FEINT_PART, "")).strip_edges()
    if feint_part.is_empty() and not move_def.get(CombatConstants.MOVE_DEF_KEY_IS_FEINT, false):
        return base
    var inflate: float = float(
        move_def.get("feint_parry_telegraph_mult", CombatConstants.PARRY_TELEGRAPH_FEINT_APPARENT_MULT)
    )
    var apparent: float = clampf(base * maxf(inflate, 1.0), 0.0, 1.15)
    var reveal: float = pa.get(DataKeys.PA_FEINT_TARGET_REVEAL_AT_PROGRESS, 0.0)
    if reveal <= 0.0:
        reveal = move_def.get(DataKeys.WEAPON_FEINT_TARGET_REVEAL_AT_PROGRESS, 0.45)
    var progress: float = _attacker_wind_up_progress(atk)
    var t: float = clampf(progress / maxf(reveal, 0.05), 0.0, 1.0)
    var perc: float = 0.5
    if defender_id >= 0:
        var def: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
        if not def.is_empty():
            perc = clampf(
                (
                    CombatantEntityAccess.stats_dict(def).get(
                        DataKeys.ENTITY_PERCEPTION, CombatConstants.DEFAULT_STAT_VALUE
                    )
                    / 100.0
                ),
                0.0,
                1.0
            )
    var read_through: float = lerpf(t, 1.0, perc * CombatConstants.PARRY_TELEGRAPH_PERCEPTION_READ_BONUS)
    return lerpf(apparent, base, read_through)


static func threat_score_for_attacker(
    manager: Node, attacker_id: int, defender_id: int = -1, anchor_time: float = -1.0
) -> float:
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return 0.0
    var pa: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
    var attack_type: String = pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, "").strip_edges()
    var move_def: Dictionary = WeaponConstants.get_move(attack_type) if not attack_type.is_empty() else {}
    var tele: float = (
        perceived_parry_telegraph(manager, defender_id, attacker_id, anchor_time)
        if defender_id >= 0
        else compute_base_parry_telegraph(pa, move_def)
    )
    var str_val: float = CombatantEntityAccess.stats_dict(atk).get(
        DataKeys.ENTITY_STRENGTH, CombatConstants.DEFAULT_STAT_VALUE
    )
    return tele * (0.5 + str_val / 200.0)


static func choose_parry_target_attacker_id(manager: Node, defender_id: int, anchor_time: float = -1.0) -> int:
    var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor_time)
    if incoming.is_empty():
        return -1
    if incoming.size() == 1:
        return int(incoming[0])
    var best_id: int = -1
    var best_score: float = -1.0
    var scores_by_id: Dictionary = {}
    for raw in incoming:
        var aid: int = int(raw)
        var score: float = threat_score_for_attacker(manager, aid, defender_id, anchor_time)
        scores_by_id[aid] = score
        if score > best_score:
            best_score = score
            best_id = aid
    # III-1: sector flank weight breaks ties only — intensity / telegraph still wins outright.
    if CombatConstants.is_feature_sector_surround_load() and incoming.size() > 1:
        var tie_eps := 0.001
        var tied_ids: Array[int] = []
        for raw in incoming:
            var aid: int = int(raw)
            if scores_by_id.get(aid, 0.0) >= best_score - tie_eps:
                tied_ids.append(aid)
        if tied_ids.size() > 1:
            var sector_best_id: int = tied_ids[0]
            var sector_best_w: float = TacticalCombat.sector_weight_for_attacker_on_defender(
                manager, defender_id, sector_best_id
            )
            for aid in tied_ids.slice(1):
                var sector_w: float = TacticalCombat.sector_weight_for_attacker_on_defender(manager, defender_id, aid)
                if sector_w > sector_best_w:
                    sector_best_w = sector_w
                    sector_best_id = aid
            return sector_best_id
    return best_id


## True when defender can parry every overlapping wind-up in the window (split surround capacity + reaction time).
static func can_parry_all(manager: Node, defender_id: int, anchor_time: float = -1.0) -> bool:
    if manager == null or defender_id < 0 or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        return false
    var anchor: float = anchor_time
    if anchor < 0.0:
        anchor = CombatantEntityAccess.combat_clock_float(manager)
    var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
    if incoming.size() <= 1:
        return true
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    if tgt.is_empty() or not CombatantEntityAccess.has_weapon(tgt):
        return false
    if not CombatantEntityAccess.has_passive_parry_reaction_time(tgt):
        return false
    var total_p_a: float = 0.0
    var min_c_d: float = 1.0e12
    for raw in incoming:
        var aid: int = int(raw)
        var est: Dictionary = _incoming_parry_estimate(manager, tgt, aid)
        if est.get(DataKeys.PA_VIABLE, false) != true:
            return false
        total_p_a += est.get(DataKeys.PA_PARRY_PRIORITY_A, 0.0)
        min_c_d = minf(min_c_d, est.get(DataKeys.PA_PRIORITY_CD, 0.0))
    if min_c_d >= 1.0e11:
        return false
    var budget: float = min_c_d * CombatConstants.INCOMING_PARRY_ALL_COMBINED_P_A_BUDGET_MULT
    if incoming.size() > 1:
        var pa_sur: Dictionary = {}
        TacticalCombat.stamp_surround_threat_on_pa(manager, tgt, pa_sur)
        budget *= TacticalCombat.surround_defense_multiplier_from_pa(tgt, pa_sur)
    return total_p_a <= budget + 0.001


static func _incoming_parry_estimate(manager: Node, tgt: Dictionary, attacker_id: int) -> Dictionary:
    var out: Dictionary = {"viable": false, "parry_p_a": 0.0, "parry_c_d": 0.0}
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty():
        return out
    var pa_src: Dictionary = CombatantEntityAccess.nested_dictionary_read(atk, "pending_attack")
    if pa_src.is_empty():
        return out
    var attack_type: String = str(pa_src.get(CombatConstants.PA_KEY_ATTACK_TYPE, "")).strip_edges()
    if attack_type.is_empty():
        return out
    var pa: Dictionary = pa_src.duplicate()
    TacticalCombat.stamp_surround_threat_on_pa(manager, tgt, pa)
    var def_n: Node = CombatantEntityAccess.scene_node(tgt)
    var targetable: Array = CombatantEntityAccess.get_targetable_parts_from_node(def_n)
    if targetable.is_empty():
        return out
    var atk_w: Variant = CombatantEntityAccess.get_weapon(atk)
    var archetype: Dictionary = {}
    if atk_w != null:
        var move_def: Dictionary = WeaponConstants.get_move(attack_type)
        archetype = WeaponConstants.get_archetype(
            str(move_def.get(DataKeys.PA_ARCHETYPE_ID, WeaponConstants.ARCHETYPE_OVERHEAD))
        )
    var dc: Dictionary = DefenseChoiceResolver.choose_defense(
        pa, atk, tgt, targetable, attack_type, archetype, -1.0, manager
    )
    var p_a: float = dc.get(DataKeys.PA_PARRY_PRIORITY_A, 0.0)
    var c_d: float = dc.get(DataKeys.PA_PRIORITY_CD, 0.0)
    out[DataKeys.PA_PARRY_PRIORITY_A] = p_a
    out[DataKeys.PA_PRIORITY_CD] = c_d
    if dc.get(DataKeys.PARRY_CHOICE_CAN_PARRY_IN_TIME, false) != true:
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    "parry_est_nocan def=%s atk_id=%d type=%s p_a=%.1f c_d=%.1f can_in_time=%s"
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        attacker_id,
                        attack_type,
                        p_a,
                        c_d,
                        dc.get(DataKeys.PARRY_CHOICE_CAN_PARRY_IN_TIME, false)
                    ]
                )
            )
        return out
    var threshold: float = c_d * CombatConstants.PARRY_DODGE_STRENGTH_RATIO
    if p_a <= threshold:
        out[DataKeys.PA_VIABLE] = true
    else:
        if CombatDebug.dc_trace_active():
            CombatDebug.combat_session(
                (
                    "parry_est_nonviable def=%s atk_id=%d type=%s p_a=%.1f c_d=%.1f threshold=%.1f ratio=%.2f"
                    % [
                        CombatantEntityAccess.get_display_name(tgt, -1),
                        attacker_id,
                        attack_type,
                        p_a,
                        c_d,
                        threshold,
                        p_a / maxf(c_d, 0.01)
                    ]
                )
            )
    return out


## Stamps **`pa`** when this resolve is not the committed parry target among overlapping wind-ups.
static func stamp_parry_choice_on_pa(
    manager: Node, pa: Dictionary, defender_id: int, attacker_id: int, anchor_time: float = -1.0
) -> void:
    if manager == null or pa.is_empty() or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        return
    var anchor: float = anchor_time
    if anchor < 0.0:
        anchor = CombatEventScheduler.get_pending_melee_attack_resolve_at(manager, attacker_id)
    if anchor < 0.0:
        anchor = CombatantEntityAccess.combat_clock_float(manager)
    var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
    if incoming.size() <= 1:
        return
    if can_parry_all(manager, defender_id, anchor):
        pa[DataKeys.PA_PARRY_ALL_INCOMING_BATCH] = true
        return
    var chosen: int = choose_parry_target_attacker_id(manager, defender_id, anchor)
    if chosen < 0:
        return
    pa[DataKeys.PA_PARRY_COMMITMENT_ATTACKER_ID] = chosen
    if attacker_id != chosen:
        pa[DataKeys.PA_PARRY_CHOICE_BLOCKED] = true


## True when **`choose_defense`** should skip parry capacity for this resolve (non-chosen overlapping wind-up).
static func parry_choice_blocked_for_resolve(
    manager: Node, defender_id: int, attacker_id: int, anchor_time: float = -1.0
) -> bool:
    if manager == null or not CombatConstants.FEATURE_INCOMING_PARRY_CHOICE:
        return false
    var anchor: float = anchor_time
    if anchor < 0.0:
        anchor = CombatEventScheduler.get_pending_melee_attack_resolve_at(manager, attacker_id)
    if anchor < 0.0:
        anchor = CombatantEntityAccess.combat_clock_float(manager)
    var incoming: Array = incoming_attacker_ids_on_defender(manager, defender_id, anchor)
    if incoming.size() <= 1:
        return false
    if can_parry_all(manager, defender_id, anchor):
        return false
    return attacker_id != choose_parry_target_attacker_id(manager, defender_id, anchor)
