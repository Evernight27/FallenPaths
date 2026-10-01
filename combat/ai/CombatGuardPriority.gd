class_name CombatGuardPriority
extends RefCounted

## Tier 4.3.8 guard-priority subdomain extracted from CombatAttention (pure code-motion split).
## Computes the guard line a waiting combatant should position toward (live wind-up telegraph or
## the most threatening engaged attacker's habitual yomi line) and drifts guard_line toward it
## each waiting tick. Back-calls into CombatAttention use class_name (mutual class_name, no
## preload — same safe pattern as the other extracted subdomains).


## Tier 4.3.8: guard-priority score (0..1) — how strongly a waiting combatant should hold + position its
## blade toward the expected attack line instead of opening offense. Live wind-up telegraph scores
## highest; otherwise an engaged attacker's habitual yomi line builds score from observation count.
## Suppressed for exhausted / critical-stamina fighters (L5 exhaustion dominates their menu).
static func guard_priority_score(manager: Node, c: Dictionary) -> float:
    if not CombatAttention.enabled() or c == null or manager == null:
        return 0.0
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        return 0.0
    var cid: int = CombatantEntityAccess.id_int(c)
    if cid < 0:
        return 0.0
    if (
        CombatExhaustion.exhaustion_tunnel_active(c)
        or CombatantEntityAccess.stamina_ratio(c) < CombatConstants.AI_FLEE_CRITICAL_STAMINA_RATIO
    ):
        return 0.0
    if CombatAttention.is_being_wind_up_targeted(manager, cid):
        return CombatConstantsMentalStack.GUARD_PRIORITY_TELEGRAPH_SCORE * _incoming_wind_up_remaining(manager, cid)
    return clampf(float(_guard_priority_yomi_target(manager, c).get("score", 0.0)), 0.0, 1.0)


## Tier 4.3.8: the guard line this combatant should position toward — live telegraph line when
## wind-up targeted, else the most threatening engaged attacker's habitual line (band-weighted, so a
## CLOSE threat dominates a MID one with a similar read). Empty when no readable signal.
static func guard_priority_target_line(manager: Node, c: Dictionary) -> String:
    if not CombatAttention.enabled() or c == null or manager == null:
        return ""
    var cid: int = CombatantEntityAccess.id_int(c)
    if cid < 0:
        return ""
    var tele: String = str(c.get(CombatConstants.COMBATANT_KEY_INCOMING_ATTACK_TELEGRAPH_PART, "")).strip_edges()
    if not tele.is_empty():
        var tele_line: String = str(CombatConstants.PART_TO_LINE.get(tele, "")).strip_edges()
        if not tele_line.is_empty():
            return tele_line
    return str(_guard_priority_yomi_target(manager, c).get("line", ""))


## Tier 4.3.8: fraction of the incoming wind-up still remaining (1 = just started, 0 = landing).
## Readability decays with commitment: a strike past the readable window is too late to shift stance.
static func _incoming_wind_up_remaining(manager: Node, defender_id: int) -> float:
    if manager == null or defender_id < 0:
        return 1.0
    var atk_id: int = CombatAttention._counter_tempo().call("incoming_attacker_id", manager, defender_id)
    if atk_id < 0:
        return 1.0
    var progress: float = float(CombatAttention._counter_tempo().call("incoming_wind_up_progress", manager, atk_id))
    return clampf(1.0 - progress, 0.0, 1.0)


## Tier 4.3.8: readable-habit floor — one observation in a short engagement (duel), two in a longer
## fight, mirroring `apply_yomi_focus_drift`. Guards settle into a 1v1 read faster than a melee.
static func _guard_priority_min_line_count(manager: Node) -> int:
    if (
        manager != null
        and int(manager.get_combat_tick_index()) < CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_TICK_THRESHOLD
    ):
        return CombatConstants.YOMI_FOCUS_DRIFT_SHORT_ENGAGEMENT_LINE_COUNT
    return CombatConstantsMentalStack.GUARD_PRIORITY_MIN_LINE_COUNT


## Tier 4.3.8: per-attacker yomi read score (0 = not engaged / not readable). Band-weighted so a CLOSE
## threat dominates a MID one with a similar read; shares the min-count rule with the score.
static func _guard_priority_read_score(manager: Node, c: Dictionary, attacker_id: int, min_count: int) -> float:
    var cid: int = CombatantEntityAccess.id_int(c)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    if atk.is_empty() or not CombatantEntityAccess.is_alive_in_combat(atk):
        return 0.0
    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, cid, "")
    if band == CombatConstants.DISTANCE_LONG:
        return 0.0
    var dom: String = CombatAttention.dominant_attack_line_toward_defender(c, attacker_id)
    if dom.is_empty():
        return 0.0
    var n: int = CombatAttention.line_count_toward_defender(c, attacker_id, dom)
    if n < min_count:
        return 0.0
    var s: float = minf(
        (
            CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_BASE
            + float(n - min_count) * CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_PER_LINE_COUNT
        ),
        CombatConstantsMentalStack.GUARD_PRIORITY_YOMI_CAP
    )
    if band == CombatConstants.DISTANCE_MID:
        s *= CombatConstantsMentalStack.GUARD_PRIORITY_MID_BAND_MULT
    return s


## Tier 4.3.8: single yomi source for score + target — returns `{score, line, attacker_id}` for the most
## threatening engaged attacker (band-weighted, so score and line selection always agree). `line` is empty
## when no readable habit; `score` is the band-weighted read strength (0 when unreadable).
static func _guard_priority_yomi_target(manager: Node, c: Dictionary) -> Dictionary:
    var min_count: int = _guard_priority_min_line_count(manager)
    var root: Dictionary = CombatAttention._yomi_root(c)
    var best_score: float = 0.0
    var best_line: String = ""
    var best_atk: int = -1
    for key in root.keys():
        var entry: Variant = root.get(key, null)
        if entry is not Dictionary:
            continue
        var etype: Dictionary = entry as Dictionary
        if float(etype.get(DataKeys.ATTENTION_WEIGHT, 1.0)) < 0.5:
            continue
        var atk_id: int = int(key)
        var s: float = _guard_priority_read_score(manager, c, atk_id, min_count)
        if s > best_score:
            best_score = s
            best_line = CombatAttention.dominant_attack_line_toward_defender(c, atk_id)
            best_atk = atk_id
    return {"score": best_score, "line": best_line, "attacker_id": best_atk}


## Tier 4.3.8: proactive guard positioning — each waiting tick (free, no action spent) drift **`guard_line`**
## toward the opponent's habitual yomi line so parry alignment is already high when their wind-up lands.
## Anticipation outside of wind-up: skipped while a telegraph is live (L4G spends the action to align on
## a live wind-up) and for formation telegraph leaders (explicit 6.0 leader telegraph-match path).
static func apply_guard_priority_drift(manager: Node, c: Dictionary) -> void:
    if not CombatAttention.enabled() or c == null or manager == null:
        return
    if CombatantEntityAccess.state_str(c) != CombatConstants.STATE_WAITING:
        return
    if CombatantEntityAccess.is_formation_telegraph_leader(c):
        return
    var cid: int = CombatantEntityAccess.id_int(c)
    if cid < 0:
        return
    if CombatAttention.is_being_wind_up_targeted(manager, cid):
        # Live wind-up: preserve the waiting-tick stamp so the weight path still gets a brace boost
        # during the telegraph window (L4G picks the brace action; the stamp lifts its focus-line
        # weight). Only erase when there is no existing stamp to drop through to.
        var old_target: String = (
            str(c.get(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE, "")).strip_edges()
        )
        if old_target.is_empty():
            c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
            c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
        return
    var tgt: Dictionary = _guard_priority_yomi_target(manager, c)
    var score: float = clampf(float(tgt.get("score", 0.0)), 0.0, 1.0)
    if score < CombatConstantsMentalStack.GUARD_PRIORITY_MIN_SCORE:
        c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
        c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
        return
    var line: String = str(tgt.get("line", ""))
    var atk_id: int = int(tgt.get("attacker_id", -1))
    if line.is_empty():
        c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY)
        c.erase(CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE)
        return
    c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY] = score
    c[CombatConstantsMentalStack.COMBATANT_KEY_GUARD_PRIORITY_TARGET_LINE] = line
    var cur: String = str(c.get(DataKeys.ATTACK_GUARD_LINE, CombatConstants.GUARD_DEFAULT)).strip_edges()
    if cur == line:
        return
    if atk_id < 0:
        return
    # Commitment: hold the current read until the new line is observed more toward the dominant
    # attacker (anti-flicker). A current guard the opponent hasn't attacked toward (count 0) yields.
    var cur_n: int = CombatAttention.line_count_toward_defender(c, atk_id, cur)
    var line_n: int = CombatAttention.line_count_toward_defender(c, atk_id, line)
    if line_n <= cur_n + CombatConstantsMentalStack.GUARD_PRIORITY_SWITCH_COUNT_MARGIN:
        return
    GuardLineUpdater.set_guard_from_line(c, line, false)
