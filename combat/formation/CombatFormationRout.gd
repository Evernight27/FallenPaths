class_name CombatFormationRout
extends RefCounted

## Rout / abandon-field policy: ties **`flee`** to formation **`line_cohesion`** (morale, fill, lane stress) and side
## **casualty ratio**.
## **Read order:** standing baseline --'' stress/casualty queries --'' `abandonment_warranted` --'' AI/tooltip helpers.
const FORMATION_FLEE_LEADER_BLOOD_MIN := 27.5
const PERSONAL_CRISIS_COHESION_MULT: float = 0.55
const LEADER_COHESION_EXEMPTION_MULT: float = 1.5
## Per-entity morale variance — ±5% individual threshold offset for flee decisions.
## Models historical unit variation: veteran fighters hold longer, militia rout earlier.
const FLEE_MORALE_VARIANCE_RANGE: float = 0.05
## Leader-death contagion: when the party leader falls, surviving members' raw morale-cohesion takes a one-time
## multiplicative shock (loss of command). 0.85 = a 15% cohesion drop — a morale blow, not a rout trigger.
const LEADER_DEATH_MORALE_SHOCK_MULT: float = 0.85
## Healthy-unit rout: even an unharmed soldier breaks when the line is severely shattered. Cohesion must be below
## this fraction of the normal flee threshold (0.5 -> ~0.21) AND casualties above the normal floor + the pad below.
const HEALTHY_ROUT_COHESION_FRACTION: float = 0.5
## Healthy-unit rout casualty pad: casualties must exceed the normal flee floor by this much (0.30 + 0.20 = 0.50).
const HEALTHY_ROUT_CASUALTY_PAD: float = 0.20


static func is_party_leader_combatant(c: Dictionary) -> bool:
    return bool(c.get(DataKeys.SNAPSHOT_IS_PARTY_LEADER, false))


## Leader-death contagion (B5): when the party leader falls, the side's command structure is disrupted and its
## cohesion takes a one-time morale shock. Reduces each surviving member's raw morale-cohesion so line cohesion
## drops — a morale blow that makes rout more likely, not a rout trigger.
static func apply_leader_death_morale_shock(manager: Node, dead: Dictionary) -> void:
    if manager == null or dead.is_empty():
        return
    if not is_party_leader_combatant(dead):
        return
    var side: String = _get_entity_access().side_str(dead)
    for c in manager.combatants:
        if not _get_entity_access().is_living_on_side(c, side):
            continue
        var raw: float = float(c.get(DataKeys.MORALE_COHESION_FACTOR_RAW, 1.0))
        c[DataKeys.MORALE_COHESION_FACTOR_RAW] = raw * LEADER_DEATH_MORALE_SHOCK_MULT


## Canonical: **`CombatantEntityAccess.flee_abandonment_warranted`** delegates here.


static func _get_entity_access() -> GDScript:
    return CombatantEntityAccess


## True 1v1 engagement mode (see **`CombatEngagementMode.engagement_mode`**).
static func is_true_duel(manager: Node) -> bool:
    if manager == null:
        return false
    return CombatEngagementMode.engagement_mode(manager) == "duel"


## Armed duelists fight to the death; flee is blocked for MS-L5/L6/L9 pools.
static func duel_blocks_armed_flee(manager: Node, c: Dictionary) -> bool:
    if not is_true_duel(manager):
        return false
    return not _get_entity_access().get_attacking_arm(c).is_empty()


## Disarmed cowering menu in a duel: yield / wait preferred over flee.
static func duel_disarmed_retreat_menu(manager: Node, c: Dictionary) -> bool:
    return is_true_duel(manager) and _get_entity_access().get_attacking_arm(c).is_empty()


static func duel_flee_allowed_for_action(manager: Node, c: Dictionary, move_id: String) -> bool:
    if move_id != CombatConstants.MOVE_ID_FLEE:
        return true
    return not duel_blocks_armed_flee(manager, c)


## Call from `CombatManager.start()` after fled-state reset, before first ZoC/cohesion recompute.
static func stamp_standing_counts_at_start(manager: Node) -> void:
    if manager == null or not manager.get("formations"):
        return
    for fid in [CombatConstants.SIDE_PLAYER, CombatConstants.SIDE_ENEMY]:
        var form: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if form.is_empty():
            continue
        var side: String = FormationSlots.formation_side_str(form, fid)
        form[CombatConstants.FORMATION_KEY_STANDING_AT_START] = standing_count_for_side(manager, side)


## Harness / edge path: stamp casualty baseline if `start()` was skipped or formation record was reset.
static func ensure_rout_baseline(manager: Node) -> void:
    if manager == null or not manager.get("formations"):
        return
    var need_stamp: bool = false
    for fid in [CombatConstants.SIDE_PLAYER, CombatConstants.SIDE_ENEMY]:
        var form: Dictionary = FormationSlots.formation_record_for_manager(manager, fid)
        if form.is_empty():
            continue
        if form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0) <= 0:
            need_stamp = true
            break
    if need_stamp:
        stamp_standing_counts_at_start(manager)


static func standing_count_for_side(manager: Node, side: String) -> int:
    if manager == null or side.is_empty():
        return 0
    var n: int = 0
    for c in manager.combatants:
        if _get_entity_access().side_str(c) == side and _get_entity_access().is_standing_combatant(c):
            n += 1
    return n


static func opponent_side_for_combatant(c: Dictionary) -> String:
    return _get_entity_access().opponent_side_label(_get_entity_access().side_str(c))


## True when this formation side still has a clear standing advantage (discourages formation-level rout).
static func side_holding_field(manager: Node, c: Dictionary) -> bool:
    if manager == null or c.is_empty():
        return false
    var side: String = _get_entity_access().side_str(c)
    var opp: String = opponent_side_for_combatant(c)
    var our_n: int = standing_count_for_side(manager, side)
    var opp_n: int = standing_count_for_side(manager, opp)
    if our_n <= 0:
        return false
    if opp_n <= 0:
        return false
    return float(our_n) >= float(opp_n) * CombatConstants.FORMATION_FLEE_WINNING_STANDING_RATIO


## Formation dict for combatant home roster **`formation_id`** (not host-line geometry fid).
static func formation_record_for_combatant(manager: Node, c: Dictionary) -> Dictionary:
    if manager == null or c.is_empty():
        return {}
    var fid: String = _get_entity_access().formation_id_str(c)
    if fid.is_empty():
        return {}
    return FormationSlots.formation_record_for_manager(manager, fid)


static func _threshold_float(
    manager: Node, c: Dictionary, threshold_key: String, default_v: float, clamp_lo: float, clamp_hi: float
) -> float:
    if manager == null or c.is_empty():
        return default_v
    var fid: String = _get_entity_access().formation_id_str(c)
    if fid.is_empty() or not manager.get("rout_thresholds_by_fid"):
        return default_v
    var side_t: Variant = manager.rout_thresholds_by_fid.get(fid)
    if side_t is not Dictionary:
        return default_v
    var raw: Variant = (side_t as Dictionary).get(threshold_key)
    if raw == null:
        return default_v
    return clampf(float(raw), clamp_lo, clamp_hi)


## Cached `line_cohesion` (0..1) from last `CombatFormationEngagement.recompute_all`.
static func line_cohesion_for_combatant(manager: Node, c: Dictionary) -> float:
    var form: Dictionary = formation_record_for_combatant(manager, c)
    if form.is_empty():
        return 1.0
    return clampf(form.get(DataKeys.FORMATION_LINE_COHESION, 1.0), 0.0, 1.0)


static func flee_line_cohesion_max(manager: Node, c: Dictionary) -> float:
    return _threshold_float(
        manager,
        c,
        CombatConstants.ROUT_THRESHOLD_KEY_FLEE_LINE_COHESION_MAX,
        CombatConstants.FORMATION_FLEE_LINE_COHESION_MAX,
        0.05,
        0.95
    )


static func flee_casualty_ratio_min(manager: Node, c: Dictionary) -> float:
    return _threshold_float(
        manager,
        c,
        CombatConstants.ROUT_THRESHOLD_KEY_FLEE_CASUALTY_RATIO_MIN,
        CombatConstants.FORMATION_FLEE_CASUALTY_RATIO_MIN,
        0.05,
        0.90
    )


## Fraction of this formation **side** no longer standing (dead, fled, unconscious, cowering incapacitated).
static func casualty_ratio_for_combatant(manager: Node, c: Dictionary) -> float:
    var form: Dictionary = formation_record_for_combatant(manager, c)
    if form.is_empty():
        return 0.0
    var start_n: int = form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0)
    if start_n <= 0:
        return 0.0
    var fid: String = _get_entity_access().formation_id_str(c)
    var side: String = FormationSlots.formation_side_str(form, fid)
    var now_n: int = standing_count_for_side(manager, side)
    return clampf(1.0 - float(now_n) / float(start_n), 0.0, 1.0)


## Per-entity morale offset for flee threshold — ±5% variance based on entity ID hash.
static func _morale_offset_for_combatant(c: Dictionary) -> float:
    if c.is_empty():
        return 0.0
    # Deterministic uniform offset in [-RANGE, +RANGE) per entity ID (the old fmod(..., RANGE*100)/100 form only
    # spanned ±RANGE/2, half the documented ±5%).
    var u: float = fmod(hash(str(c.id)), 1000.0) / 1000.0
    var raw: float = (u - 0.5) * 2.0 * FLEE_MORALE_VARIANCE_RANGE
    return clampf(raw, -FLEE_MORALE_VARIANCE_RANGE, FLEE_MORALE_VARIANCE_RANGE)


## True when the unit's formation is tactically breaking (ragged line or heavy losses).
static func formation_stressed_for_rout(manager: Node, c: Dictionary) -> bool:
    ensure_rout_baseline(manager)
    if line_cohesion_for_combatant(manager, c) < flee_line_cohesion_max(manager, c):
        return true
    # Per-entity morale offset — veterans hold longer, militia rout earlier.
    var casualty_ratio: float = casualty_ratio_for_combatant(manager, c)
    var base_threshold: float = flee_casualty_ratio_min(manager, c)
    var entity_offset: float = _morale_offset_for_combatant(c)
    if casualty_ratio >= base_threshold + entity_offset:
        return true
    return false


## Wounded + breaking formation only (not no-arms / Class III / immediate peril).
static func formation_stress_abandonment_path(manager: Node, c: Dictionary) -> bool:
    if c.is_empty() or manager == null:
        return false
    if is_true_duel(manager):
        return false
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return false
    var node: Variant = _get_entity_access().node_variant(c)
    if node == null:
        return false
    var bv: float = _get_entity_access().get_blood_volume_from_node(node as Node)
    if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
        return false
    if _get_entity_access().is_in_immediate_peril(manager, c):
        return false
    return bv < CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX and formation_stressed_for_rout(manager, c)


## Healthy-unit rout (B4): even an unharmed soldier breaks when the line is severely shattered — very low cohesion
## AND heavy casualties. Stricter than the wounded path (which covers low blood), so this only fires in near-total
## collapse ("the line broke" contagion). Not for duels / disarmed / immediate-peril (those have their own paths).
static func healthy_unit_rout_warranted(manager: Node, c: Dictionary) -> bool:
    if c.is_empty() or manager == null:
        return false
    if is_true_duel(manager):
        return false
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return false
    var node: Variant = _get_entity_access().node_variant(c)
    if node == null:
        return false
    var bv: float = _get_entity_access().get_blood_volume_from_node(node as Node)
    # Only healthy units — the wounded path already covers low blood volume.
    if bv < CombatConstants.FORMATION_RETREAT_BLOOD_VOLUME_MAX:
        return false
    # Severe collapse: cohesion well below the normal flee threshold AND casualties well above the normal floor.
    if line_cohesion_for_combatant(manager, c) >= flee_line_cohesion_max(manager, c) * HEALTHY_ROUT_COHESION_FRACTION:
        return false
    if casualty_ratio_for_combatant(manager, c) < flee_casualty_ratio_min(manager, c) + HEALTHY_ROUT_CASUALTY_PAD:
        return false
    return true


## Abandon-field (`flee`) warranted '"" personal catastrophe, helpless, or wounded under a breaking formation.
static func abandonment_warranted(manager: Node, c: Dictionary) -> bool:
    ensure_rout_baseline(manager)
    if c.is_empty():
        return false
    if is_true_duel(manager):
        if _get_entity_access().get_attacking_arm(c).is_empty():
            return false
        if _get_entity_access().is_in_immediate_peril(manager, c):
            return true
        var duel_node: Variant = _get_entity_access().node_variant(c)
        if duel_node == null:
            return false
        var duel_bv: float = _get_entity_access().get_blood_volume_from_node(duel_node as Node)
        return duel_bv < CombatConstants.FORMATION_FLEE_DUEL_ARMED_BLOOD_MAX
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return true
    var node: Variant = _get_entity_access().node_variant(c)
    if node == null:
        return false
    var bv: float = _get_entity_access().get_blood_volume_from_node(node as Node)
    ## Immediate peril always allows flee (personal survival overrides formation state).
    if _get_entity_access().is_in_immediate_peril(manager, c):
        return true
    if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
        if is_party_leader_combatant(c):
            if bv >= FORMATION_FLEE_LEADER_BLOOD_MIN:
                if not formation_stressed_for_rout(manager, c):
                    return false
            else:
                return true
        else:
            return true
    if formation_stress_abandonment_path(manager, c):
        if is_party_leader_combatant(c):
            if side_holding_field(manager, c):
                return false
            if line_cohesion_for_combatant(manager, c) > flee_line_cohesion_max(manager, c) * LEADER_COHESION_EXEMPTION_MULT:
                return false
        if side_holding_field(manager, c):
            return false
        return true
    # Healthy-unit rout (B4): an unharmed soldier breaks when the line is severely shattered.
    if healthy_unit_rout_warranted(manager, c):
        if side_holding_field(manager, c):
            return false
        return true
    return false


## AI pick multiplier from formation stress (not raw combatant `morale_cohesion` '"" that already feeds
## `line_cohesion`).
static func flee_ai_pick_mult(manager: Node, c: Dictionary) -> float:
    var coh: float = line_cohesion_for_combatant(manager, c)
    var cas: float = casualty_ratio_for_combatant(manager, c)
    var coh_m: float = lerpf(CombatConstants.AI_FLEE_LOW_COHESION_MULT, CombatConstants.AI_FLEE_HIGH_COHESION_MULT, coh)
    var cas_min: float = flee_casualty_ratio_min(manager, c)
    var cas_t: float = clampf(cas / maxf(cas_min, 0.01), 0.0, 1.0)
    var cas_m: float = lerpf(1.0, CombatConstants.AI_FLEE_HIGH_CASUALTY_MULT, cas_t)
    var mult: float = coh_m * cas_m
    if formation_stressed_for_rout(manager, c) and not side_holding_field(manager, c):
        mult *= CombatConstants.AI_FLEE_LOSING_SIDE_MULT
    # Disciplined wounded stay when the side is winning: a personal-crisis unit in a holding, cohesive formation
    # has its flee weight DAMPENED (x0.55) — cohesion holds them in the line despite their injuries.
    if side_holding_field(manager, c) and formation_stress_abandonment_path(manager, c):
        mult *= PERSONAL_CRISIS_COHESION_MULT
    return mult


static func rout_context_snapshot(manager: Node, c: Dictionary) -> Dictionary:
    return {
        "line_cohesion": line_cohesion_for_combatant(manager, c),
        "casualty_ratio": casualty_ratio_for_combatant(manager, c),
        "formation_stressed": formation_stressed_for_rout(manager, c),
        "side_holding_field": side_holding_field(manager, c),
        "flee_line_cohesion_max": flee_line_cohesion_max(manager, c),
        "flee_casualty_ratio_min": flee_casualty_ratio_min(manager, c),
    }


## Side casualty percent (0'""100) for battle UI; 0 when `standing_at_start` unset.
static func casualty_percent_for_formation(manager: Node, formation_id: String) -> int:
    if manager == null or formation_id.is_empty():
        return 0
    ensure_rout_baseline(manager)
    var form: Dictionary = FormationSlots.formation_record_for_manager(manager, formation_id)
    if form.is_empty():
        return 0
    var start_n: int = form.get(CombatConstants.FORMATION_KEY_STANDING_AT_START, 0)
    if start_n <= 0:
        return 0
    var side: String = FormationSlots.formation_side_str(form, formation_id)
    var now_n: int = standing_count_for_side(manager, side)
    return int(round(clampf(1.0 - float(now_n) / float(start_n), 0.0, 1.0) * 100.0))


## Personal crisis or helpless '"" rout tooltip relevant even when the side still has numbers.
static func personal_rout_pressure(manager: Node, c: Dictionary) -> bool:
    if c.is_empty():
        return false
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return true
    var node: Variant = _get_entity_access().node_variant(c)
    if node == null:
        return false
    var bv: float = _get_entity_access().get_blood_volume_from_node(node as Node)
    if bv < CombatConstants.FORMATION_FLEE_BLOOD_VOLUME_MAX:
        return true
    if _get_entity_access().is_in_immediate_peril(manager, c):
        return true
    return false


## Gauge tooltip when the formation is under rout pressure (cohesion + casualties).
static func rout_pressure_tooltip_line(manager: Node, c: Dictionary) -> String:
    if manager == null or c.is_empty():
        return ""
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return ""
    if not formation_stressed_for_rout(manager, c):
        return ""
    if side_holding_field(manager, c) and not personal_rout_pressure(manager, c):
        return ""
    var coh_pct: int = int(round(line_cohesion_for_combatant(manager, c) * 100.0))
    var cas_pct: int = int(round(casualty_ratio_for_combatant(manager, c) * 100.0))
    var hold_note: String = ""
    if side_holding_field(manager, c):
        hold_note = " Your side still holds the field, so rout is less likely."
    return (
        (
            "Formation under pressure (line cohesion %d%%, side casualties %d%%) — rout may be offered."
            % [coh_pct, cas_pct]
        )
        + hold_note
    )


## Player turn-ready when **`flee`** is listed for an armed fighter.
static func rout_hint_when_flee_listed(manager: Node, c: Dictionary, actions: Array) -> String:
    if manager == null or c.is_empty() or actions.is_empty():
        return ""
    if _get_entity_access().get_attacking_arm(c).is_empty():
        return ""
    var cid: int = _get_entity_access().id_int(c)
    if not CombatListedActions.actions_include_self_target_move(actions, cid, CombatConstants.MOVE_ID_FLEE):
        return ""
    var coh_pct: int = int(round(line_cohesion_for_combatant(manager, c) * 100.0))
    var cas_pct: int = int(round(casualty_ratio_for_combatant(manager, c) * 100.0))
    if formation_stressed_for_rout(manager, c):
        if side_holding_field(manager, c):
            return "Flee leaves the field (cohesion %d%%, casualties %d%%) - your side still has numbers; fall back when listed." % [coh_pct, cas_pct]
        return "Flee leaves the field (cohesion %d%%, casualties %d%%) - fall back stays in formation when listed." % [coh_pct, cas_pct]
    return "Flee leaves the field - you are badly hurt or bleeding out."


## MS-L6: fight-finish / sparse-finish / mop-up offense defer rout to L4b or salience utility pick.
static func rout_layer_blocked(manager: Node, c: Dictionary, actions: Array, combatant_id: int) -> bool:
    return CombatFormationVacancyPlugs.formation_plug_layer_blocked(manager, c, actions, combatant_id)


## MS-L6: formation stress on a losing side, or personal abandon-field crisis.
static func rout_cognition_pressure(manager: Node, c: Dictionary) -> bool:
    if c.is_empty() or manager == null:
        return false
    var cid: int = CombatantEntityAccess.id_int(c)
    ## Phase 3: morale check gates rout behavior when the side is still holding together.
    if not CombatMoraleCohesion.morale_check_during_rout(cid, manager):
        return false
    ## Phase 3: guard break threshold — repeated failures with no ally support push toward rout.
    var gb_count: int = int(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_BREAK_COUNT, 0))
    if gb_count >= CombatConstantsMentalStack.MENTAL_STACK_LOST_COHESION_ROUT_THRESHOLD:
        var my_zg: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, c)
        var allies_nearby: bool = false
        for other in manager.combatants:
            if other is not Dictionary:
                continue
            var o: Dictionary = other
            if CombatantEntityAccess.side_str(o) != CombatantEntityAccess.side_str(c):
                continue
            if CombatantEntityAccess.id_int(o) == cid:
                continue
            if not CombatantEntityAccess.alive_bool(o):
                continue
            var other_zg: Dictionary = ZoneOfControl.zone_geometry_line_context(manager, o)
            var my_fid: String = ZoneOfControl.zone_geometry_fid_from_pack(my_zg)
            var other_fid: String = ZoneOfControl.zone_geometry_fid_from_pack(other_zg)
            if my_fid == other_fid and not my_zg.is_empty():
                var my_slots: Dictionary = my_zg.get(DataKeys.ZONE_FORMATION, {})
                var other_slots: Dictionary = other_zg.get(DataKeys.ZONE_FORMATION, {})
                var self_key: Variant = FormationSlots.slot_key_for_combatant_id(manager, {"slots": my_slots}, cid)
                var other_key: Variant = FormationSlots.slot_key_for_combatant_id(manager, {"slots": other_slots}, CombatantEntityAccess.id_int(o))
                if self_key == null or other_key == null:
                    continue
                if self_key != other_key:
                    allies_nearby = true
                    break
        if not allies_nearby:
            return true
    if is_true_duel(manager):
        if _get_entity_access().get_attacking_arm(c).is_empty():
            return false
        return _get_entity_access().flee_abandonment_warranted(c, manager)
    if _get_entity_access().flee_abandonment_warranted(c, manager):
        return true
    if formation_stressed_for_rout(manager, c) and not side_holding_field(manager, c):
        return true
    return false


## MS-L6: listed self-target **`flee`** / **`fall_back`** for mental-stack rout layer.
static func filter_rout_disengage_actions(manager: Node, c: Dictionary, combatant_id: int, actions: Array) -> Array:
    var out: Array = []
    if manager == null or c.is_empty() or actions.is_empty() or combatant_id < 0:
        return out
    for raw in actions:
        if raw is not Dictionary:
            continue
        var a: Dictionary = raw
        if a.get(DataKeys.ACTION_TARGET_ID, -1) != combatant_id:
            continue
        var mid: String = str(a.get(DataKeys.ACTION_MOVE_ID, ""))
        if not duel_flee_allowed_for_action(manager, c, mid):
            continue
        if mid == CombatConstants.MOVE_ID_FLEE and CombatFormationFlee.flee_action_legal(manager, c):
            out.append(a)
        elif (
            mid == CombatConstants.MOVE_ID_FALL_BACK
            and CombatFormationMoveListing.solo_fall_back_action_legal(manager, c)
        ):
            out.append(a)
    return out


## MS-L6: true when rout cognition should run (not blocked, under pressure, rout moves listed).
static func rout_layer_eligible(manager: Node, c: Dictionary, combatant_id: int, actions: Array) -> bool:
    if not CombatConstants.is_feature_ms_l6_rout_enabled():
        return false
    if rout_layer_blocked(manager, c, actions, combatant_id):
        return false
    if not rout_cognition_pressure(manager, c):
        return false
    return not filter_rout_disengage_actions(manager, c, combatant_id, actions).is_empty()
