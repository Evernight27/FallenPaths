class_name CombatLogFormatter
extends RefCounted

## Formats combat action results as BBCode strings for the combat log.
## Footing: parry clash context may log **`defender_guard_line`**  -  diagnostic only; gauge **`Form`** / **`Grd`**
## suffixes are **`CombatUiHints`** / **`BattleUIUpdater`**. LIVE_PATHS **`#wf-guard-writers`** · **`#battle-ui`**.
## BattleScene calls format_action_line() and appends the result to RichTextLabel.
## **`parry_deflect`** / **`parry_partial`**: optional **`parry_clash_context`** on **`result`** (from
## **`action_resolved`** after **`AttackResultApplier`**)  -  play session + calibration show **`rem=`** (follow-through
## fraction, not blocked damage).


static func _eff_pct(result: Dictionary) -> int:
    return int(roundf(result.get("effectiveness", 1.0) * 100.0))


static func _fled_rout_context_suffix(result: Dictionary) -> String:
    var coh: float = result.get("line_cohesion", -1.0)
    if coh < 0.0:
        return ""
    var cas: float = result.get("casualty_ratio", -1.0)
    var bits: PackedStringArray = PackedStringArray(["line %d%% cohesion" % int(roundf(coh * 100.0))])
    if cas >= 0.0:
        bits.append("%d%% casualties" % int(roundf(cas * 100.0)))
    if result.get("formation_stressed", false):
        bits.append("formation breaking")
    if result.get("side_holding_field", false):
        bits.append("side still holds field")
    return " (%s)" % ", ".join(bits)


static func _medical_procedure_label(move_id: String, on_self: bool) -> String:
    var base: String = move_id.replace("_", " ")
    if on_self:
        return base
    match move_id:
        CombatConstants.MOVE_ID_BANDAGE_SELF:
            return "bandage (ally)"
        CombatConstants.MOVE_ID_PACK_WOUND:
            return "pack wound (ally)"
        CombatConstants.MOVE_ID_APPLY_TOURNIQUET:
            return "tourniquet (ally)"
        _:
            return "%s (ally)" % base


static func _medical_on_self(result: Dictionary, attacker_name: String, target_name: String) -> bool:
    if result.has("medical_target_is_self"):
        return result.get("medical_target_is_self", true)
    return attacker_name == target_name


static func _medical_procedure_log_line(
    success: bool,
    success_clause: String,
    fail_verb: String,
    fail_note: String,
    attacker_name: String,
    attacker_side: String,
    target_name: String,
    part_label: String,
    result: Dictionary,
    procedure_verb: String = ""
) -> String:
    var who: String = "%s (%s)" % [attacker_name, attacker_side]
    var eff: int = _eff_pct(result)
    var target_part: String = "%s's %s" % [target_name, part_label]
    if success:
        if not procedure_verb.is_empty():
            return (
                "[color=teal]%s %s %s's %s successfully (effectiveness: %d%%).[/color]"
                % [who, procedure_verb, target_name, part_label, eff]
            )
        return (
            "[color=teal]%s %s (effectiveness: %d%%).[/color]" % [who, success_clause % [target_name, part_label], eff]
        )
    return (
        "[color=orange]%s failed to properly %s %s (effectiveness: %d%%; %s).[/color]"
        % [who, fail_verb, target_part, eff, fail_note]
    )


## True when resolved hit carried meaningful physical damage (integer **`dmg`** or fractional **`total_physical`**).
static func has_resolved_physical_damage(result: Dictionary) -> bool:
    var dmg: int = result.get("dmg", 0)
    var phys_chip: float = result.get("total_physical", -1.0)
    return dmg > 0 or (phys_chip >= 0.0 and phys_chip > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS)


## Why a strike shows 0 counted HP  -  for combat log, row strip, and F5 **`hit_resolve`** / **`strike_avoided`**.
static func damage_resolve_note(result: Dictionary) -> String:
    var outcome: String = result.get("outcome", "").strip_edges()
    match outcome:
        "miss":
            return "attack missed (no contact)"
        "dodge":
            return "defender dodged"
        "parry_deflect":
            return "full parry (no follow-through)"
        "parry_partial":
            return "partial parry  -  see follow-through line"
        "deflected":
            return "armor stopped the strike (no tissue damage)"
        "glancing":
            var tissue: float = result.get("final_cut", 0.0) + result.get("final_blunt", 0.0)
            var total_phys: float = result.get("total_physical", 0.0)
            var thresh: float = maxf(total_phys * CombatConstants.GLANCING_DAMAGE_RATIO, CombatConstants.GLANCING_DAMAGE_ABSOLUTE_FLOOR)
            return "glancing  -  tissue %.2f below %.2f threshold (reduced recovery, minor wound)" % [tissue, thresh]
        "negligible":
            var phys: float = result.get("total_physical", 0.0)
            if result.get("rounded_zero_chip", false) or phys > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
                return "graze  -  %.3f physical, rounds to 0 counted HP" % phys
            return "negligible contact (no counted HP)"
        "hit":
            var dmg: int = result.get("dmg", 0)
            var phys_hit: float = result.get("total_physical", -1.0)
            if phys_hit < 0.0:
                phys_hit = float(dmg)
            if dmg > 0 or phys_hit > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
                return ""
            return "hit resolved with no counted damage"
        _:
            if outcome.is_empty():
                return "unknown outcome"
            return outcome.replace("_", " ")


static func strike_avoided_reason(outcome: String) -> String:
    return damage_resolve_note({"outcome": outcome.strip_edges().to_lower()})


## Participant clause shared by strike log lines.
static func _strike_participant_clause(
    attacker_name: String, attacker_side: String, target_name: String, target_side: String, part_label: String
) -> String:
    return "%s (%s) → %s (%s) %s" % [attacker_name, attacker_side, target_name, target_side, part_label]


static func _tissue_breakdown_suffix(result: Dictionary) -> String:
    if not (result.has("final_cut") and result.has("final_blunt")):
        return ""
    return (
        " (cut %.2f blunt %.2f bone %.2f)"
        % [
            result.get("final_cut", 0.0),
            result.get("final_blunt", 0.0),
            result.get("final_bone", 0.0),
        ]
    )


## Human-readable damage from `action_resolved` hit payloads: prefers **`total_physical`** (cut+blunt+bone); falls back
## to **`dmg`**.
static func format_resolved_damage(result: Dictionary) -> String:
    var tp: Variant = result.get("total_physical", null)
    if tp != null:
        var t: float = float(tp)
        if t <= CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            return "0"
        var as_int: int = int(roundf(t))
        # Integer "dmg" can be 0 while fractional tissue/bone still chipped (display precisely).
        if as_int == 0 and t > CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            return "~0 (%.2f)" % t
        if absf(t - roundf(t)) < CombatConstants.PHYSICAL_DAMAGE_ZERO_EPS:
            return str(as_int)
        return "%.1f" % t
    return str(result.get("dmg", 0))


## Compact one-line strip on the target row (`BattleScene` `last_hit_label`): outcome-appropriate prefix + part +
## damage.
static func format_last_hit_on_target_row(result: Dictionary) -> String:
    var part: String = result.get("part", "")
    if part.is_empty():
        return ""
    var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part)
    var outcome: String = result.get("outcome", "hit")
    var prefix: String = "Hit"
    match outcome:
        "negligible":
            prefix = "Graze"
        "glancing":
            prefix = "Glancing"
        "deflected":
            prefix = "Deflected"
        _:
            prefix = "Hit"
    var reason: String = damage_resolve_note(result)
    if outcome in ["negligible", "deflected", "glancing"]:
        return "%s: %s  -  %s" % [prefix, part_label, reason]
    if has_resolved_physical_damage(result):
        return "%s: %s -%s" % [prefix, part_label, format_resolved_damage(result)]
    if not reason.is_empty():
        return "%s: %s  -  %s" % [prefix, part_label, reason]
    return "%s: %s" % [prefix, part_label]


static func _format_avoid_row_label(prefix: String, part: String, outcome_key: String = "") -> String:
    var oc: String = outcome_key.strip_edges().to_lower()
    if oc.is_empty():
        oc = "miss" if prefix == "Miss" else "dodge"
    var reason: String = strike_avoided_reason(oc)
    if part.is_empty():
        return "%s  -  %s" % [prefix, reason]
    var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part)
    return "%s: %s  -  %s" % [prefix, part_label, reason]


## Target-row strip after **`parry_partial`** (before follow-through damage line).
static func format_parry_partial_last_hit(result: Dictionary) -> String:
    var rem: float = -1.0
    var ctx: Variant = result.get("parry_clash_context", null)
    if ctx is Dictionary:
        rem = (ctx as Dictionary).get("remaining_ratio", -1.0)
    var rem_s: String = ""
    if rem >= 0.0:
        rem_s = " · %.0f%% thru" % (rem * 100.0)
    return "Partial parry%s  -  follow-through pending" % rem_s


## Row **`last_hit_label`**: strikes, grazes, deflects, and partial-parry staging.
static func format_row_last_hit(result: Dictionary) -> String:
    var outcome: String = result.get("outcome", "")
    if outcome == "parry_partial":
        return format_parry_partial_last_hit(result)
    if outcome == "parry_deflect":
        return "Deflected (full stop)"
    if outcome == "bled_out":
        return "Bled out"
    if outcome == "miss":
        return _format_avoid_row_label("Miss", result.get("part", ""), "miss")
    if outcome == "dodge":
        return _format_avoid_row_label("Dodged", result.get("part", ""), "dodge")
    var part: String = result.get("part", "")
    if part.is_empty():
        return ""
    if has_resolved_physical_damage(result):
        return format_last_hit_on_target_row(result)
    if outcome in ["hit", "glancing", "negligible", "deflected"]:
        return format_last_hit_on_target_row(result)
    return ""


## **`action_resolved`** slot order: parry emits defender then attacker; hits emit attacker then defender.
static func last_hit_row_combatant_id(first_id: int, second_id: int, result: Dictionary) -> int:
    var outcome: String = result.get("outcome", "")
    if outcome in ["parry_deflect", "parry_partial", "bled_out"]:
        return first_id
    # Tick bleed-out: `CombatStateHandlers` emits victim as first id, `target_id=-1`.
    if result.get(CombatConstants.RESULT_KEY_DIED, false) and second_id < 0 and first_id >= 0:
        return first_id
    return second_id


## Victim combatant id from **`action_resolved`** slot order (campaign / row updates).
static func action_resolved_victim_id(attacker_id: int, target_id: int, _result: Dictionary) -> int:
    if target_id >= 0:
        return target_id
    if attacker_id >= 0:
        return attacker_id
    return -1


static func _leader_doctrine_order_log_line(
    attacker_name: String, attacker_side: String, result: Dictionary, verb: String
) -> String:
    var fid: String = str(result.get("formation_id", "player")).strip_edges()
    return "[color=gray]%s (%s) orders the line  -  %s (%s).[/color]" % [attacker_name, attacker_side, verb, fid]


static func format_action_line(
    attacker_name: String, attacker_side: String, target_name: String, target_side: String, result: Dictionary
) -> String:
    var part: String = result.get("part", "")
    var died: bool = result.get(CombatConstants.RESULT_KEY_DIED, false)
    var outcome: String = result.get("outcome", "hit")
    var health_before: int = result.get("health_before", -1)
    var health_after: int = result.get("health_after", -1)
    var part_label: String = BodyPartConstants.BODY_LABELS.get(part, part) if part else " - "
    match outcome:
        "bled_out":
            if died and not has_resolved_physical_damage(result):
                return "[color=red]%s (%s) bled out.[/color]" % [attacker_name, attacker_side]
        "defeated":
            if died and not has_resolved_physical_damage(result):
                return (
                    "[color=red]%s (%s)  -  %s (%s) is defeated.[/color]"
                    % [attacker_name, attacker_side, target_name, target_side]
                )
        _:
            if died and not has_resolved_physical_damage(result):
                return (
                    "[color=gray]%s (%s)  -  %s had no targetable parts.[/color]"
                    % [attacker_name, attacker_side, target_name]
                )

    match outcome:
        "miss":
            var miss_aim: String = (" at %s" % part_label) if part else ""
            return (
                "[color=gray]%s (%s) → %s (%s)%s: [b]Miss![/b]  -  %s[/color]"
                % [
                    attacker_name,
                    attacker_side,
                    target_name,
                    target_side,
                    miss_aim,
                    strike_avoided_reason("miss"),
                ]
            )
        "dodge":
            var dodge_aim: String = (" (%s)" % part_label) if part else ""
            return (
                "[color=green]%s (%s) → %s (%s): [b]Dodge![/b]%s  -  %s[/color]"
                % [
                    attacker_name,
                    attacker_side,
                    target_name,
                    target_side,
                    dodge_aim,
                    strike_avoided_reason("dodge"),
                ]
            )
        "focus_line":
            var guard_line: String = result.get("line", "").strip_edges()
            var guard_disp: String = guard_line.capitalize() if not guard_line.is_empty() else "guard"
            return "[color=gray]%s (%s) shifts focus  -  %s line.[/color]" % [attacker_name, attacker_side, guard_disp]
        "leader_order_hold_lane":
            return _leader_doctrine_order_log_line(attacker_name, attacker_side, result, "hold lane")
        "leader_order_probing":
            return _leader_doctrine_order_log_line(attacker_name, attacker_side, result, "probe")
        "leader_order_pinch_center":
            return _leader_doctrine_order_log_line(attacker_name, attacker_side, result, "pinch center")
        "skip":
            return "[color=gray]%s (%s)  -  no functional arm; skips attack.[/color]" % [attacker_name, attacker_side]
        "wait":
            return "[color=gray]%s (%s) waits.[/color]" % [attacker_name, attacker_side]
        "pass":
            var rank: int = result.get("rank", 0)
            if rank > 0:
                return (
                    "[color=gray]%s (%s) holds in reserve (no action available).[/color]"
                    % [attacker_name, attacker_side]
                )
            return "[color=gray]%s (%s) passes (no action available).[/color]" % [attacker_name, attacker_side]
        "swap_rank_complete":
            return (
                "[color=gray]%s (%s) and %s (%s) swapped ranks.[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "drag_back_complete":
            return (
                "[color=gray]%s (%s) and %s (%s) dragged back (formation).[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "fall_back_complete":
            return (
                "[color=gray]%s (%s) and %s (%s) fell back together.[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "fall_back_solo_complete":
            return "[color=gray]%s (%s) fell back to the second rank.[/color]" % [attacker_name, attacker_side]
        "rotate_file_complete":
            return (
                "[color=gray]%s (%s) and %s (%s) rotated files (front rank).[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "fled":
            var fled_ctx: String = _fled_rout_context_suffix(result)
            return "[color=gray]%s (%s) fled the field%s.[/color]" % [attacker_name, attacker_side, fled_ctx]
        "parry_deflect":
            var line_pd: String = (
                "[color=cyan]%s (%s) parried %s (%s)'s attack.[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
            if CombatConstants.COMBAT_DEBUG_CALIBRATION:
                var ctx_pd: Variant = result.get("parry_clash_context", null)
                if ctx_pd is Dictionary:
                    var dpd: Dictionary = ctx_pd
                    if not dpd.is_empty():
                        var kdel: String = dpd.get("kinematic_delivery", "")
                        var sm: float = dpd.get("strike_measure_ratio", -1.0)
                        var pc: float = dpd.get("parry_control", 0.0)
                        line_pd += " [size=10][color=gray](%s meas=%.2f bind=%.2f)[/color][/size]" % [kdel, sm, pc]
            return line_pd
        "parry_partial":
            var line_pp: String = "[color=cyan]%s (%s) partially parried %s (%s)'s attack  -  follow-through may still land (see next hit line).[/color]" % [attacker_name, attacker_side, target_name, target_side]
            var ctx_pp: Variant = result.get("parry_clash_context", null)
            if ctx_pp is Dictionary:
                var dpp: Dictionary = ctx_pp
                if not dpp.is_empty():
                    var pc_p: float = dpp.get("parry_control", 0.0)
                    var rem_p: float = dpp.get("remaining_ratio", -1.0)
                    if CombatConstants.play_session_diagnostic_active() or CombatConstants.COMBAT_DEBUG_CALIBRATION:
                        line_pp += " [size=10][color=gray](ctrl=%.2f rem=%.2f thru)[/color][/size]" % [pc_p, rem_p]
                    if CombatConstants.COMBAT_DEBUG_CALIBRATION:
                        var kdel_p: String = dpp.get("kinematic_delivery", "")
                        var sm_p: float = dpp.get("strike_measure_ratio", -1.0)
                        line_pp += " [size=10][color=gray]%s meas=%.2f[/color][/size]" % [kdel_p, sm_p]
            return line_pp
        "direct_pressure":
            return (
                "[color=teal]%s (%s) applied direct pressure on %s's %s.[/color]"
                % [attacker_name, attacker_side, target_name, part_label]
            )
        "bandaged":
            var on_self_b: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_b: String = result.get("medical_move_id", CombatConstants.MOVE_ID_BANDAGE_SELF)
            var bandage_verb: String = "bandaged" if on_self_b else _medical_procedure_label(med_id_b, false)
            return _medical_procedure_log_line(
                true,
                "",
                "bandage",
                "partial effect; another can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result,
                bandage_verb
            )
        "bandage_failed":
            var on_self_bf: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_bf: String = result.get("medical_move_id", CombatConstants.MOVE_ID_BANDAGE_SELF)
            return _medical_procedure_log_line(
                false,
                "",
                _medical_procedure_label(med_id_bf, on_self_bf),
                "partial effect; another can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result
            )
        "packed":
            var on_self_p: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_p: String = result.get("medical_move_id", CombatConstants.MOVE_ID_PACK_WOUND)
            var pack_verb: String = "packed with linen" if on_self_p else _medical_procedure_label(med_id_p, false)
            return _medical_procedure_log_line(
                true,
                "",
                "pack",
                "partial effect; another can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result,
                pack_verb
            )
        "packing_failed":
            var on_self_pf: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_pf: String = result.get("medical_move_id", CombatConstants.MOVE_ID_PACK_WOUND)
            return _medical_procedure_log_line(
                false,
                "",
                _medical_procedure_label(med_id_pf, on_self_pf),
                "partial effect; another can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result
            )
        "tourniquet_applied":
            var on_self_t: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_t: String = result.get("medical_move_id", CombatConstants.MOVE_ID_APPLY_TOURNIQUET)
            var tq_verb: String = "applied tourniquet to" if on_self_t else _medical_procedure_label(med_id_t, false)
            return _medical_procedure_log_line(
                true,
                "",
                "apply tourniquet to",
                "not tight enough; can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result,
                tq_verb
            )
        "tourniquet_failed":
            var on_self_tf: bool = _medical_on_self(result, attacker_name, target_name)
            var med_id_tf: String = result.get("medical_move_id", CombatConstants.MOVE_ID_APPLY_TOURNIQUET)
            return _medical_procedure_log_line(
                false,
                "",
                _medical_procedure_label(med_id_tf, on_self_tf),
                "not tight enough; can retry",
                attacker_name,
                attacker_side,
                target_name,
                part_label,
                result
            )
        "close_success":
            return (
                "[color=teal]%s (%s) closed the distance on %s (%s).[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "close_failed":
            var rsn_close: String = result.get("reason", "")
            if rsn_close == "not_long":
                return (
                    "[color=gray]%s (%s) could not close on %s (%s)  -  already in melee range.[/color]"
                    % [attacker_name, attacker_side, target_name, target_side]
                )
            if rsn_close == "contest_failed":
                var form_note: String = result.get("close_contest_note", "").strip_edges()
                if not form_note.is_empty():
                    return (
                        (
                            "[color=gray]%s (%s) tried to close on %s (%s)  -  the defender held their measure (%s)."
                            + "[/color]"
                        )
                        % [attacker_name, attacker_side, target_name, target_side, form_note]
                    )
                return (
                    "[color=gray]%s (%s) tried to close on %s (%s)  -  the defender held their measure.[/color]"
                    % [attacker_name, attacker_side, target_name, target_side]
                )
            return (
                "[color=gray]%s (%s) failed to close on %s (%s).[/color]"
                % [attacker_name, attacker_side, target_name, target_side]
            )
        "deflected":
            var strike_d: String = _strike_participant_clause(
                attacker_name, attacker_side, target_name, target_side, part_label
            )
            return (
                "[color=green]%s: [b]Deflected[/b]  -  %s%s[/color]"
                % [strike_d, damage_resolve_note(result), _tissue_breakdown_suffix(result)]
            )
        "glancing":
            var strike_g: String = _strike_participant_clause(
                attacker_name, attacker_side, target_name, target_side, part_label
            )
            var dmg_g: String = ""
            if has_resolved_physical_damage(result):
                dmg_g = " · %s counted" % format_resolved_damage(result)
            var line_g: String = (
                "[color=orange]%s: [b]Glancing[/b]%s  -  %s%s[/color]"
                % [strike_g, dmg_g, damage_resolve_note(result), _tissue_breakdown_suffix(result)]
            )
            if health_before >= 0 and health_after >= 0:
                line_g += " [size=10][color=gray](%d→%d HP)[/color][/size]" % [health_before, health_after]
            return line_g
        "negligible":
            var strike_n: String = _strike_participant_clause(
                attacker_name, attacker_side, target_name, target_side, part_label
            )
            var line_n: String = (
                "[color=gray]%s: [b]Graze[/b]  -  %s%s[/color]"
                % [strike_n, damage_resolve_note(result), _tissue_breakdown_suffix(result)]
            )
            if health_before >= 0 and health_after >= 0:
                line_n += " [size=10][color=gray](%d→%d HP)[/color][/size]" % [health_before, health_after]
            return line_n
        _:
            var strike_h: String = _strike_participant_clause(
                attacker_name, attacker_side, target_name, target_side, part_label
            )
            var reason_h: String = damage_resolve_note(result)
            var line_h: String = ""
            if has_resolved_physical_damage(result):
                line_h = "%s: [b]%s[/b] damage" % [strike_h, format_resolved_damage(result)]
            elif not reason_h.is_empty():
                line_h = "%s: [b]no counted damage[/b]  -  %s" % [strike_h, reason_h]
            else:
                line_h = "%s: [b]no damage[/b]" % strike_h
            line_h += _tissue_breakdown_suffix(result)
            if health_before >= 0 and health_after >= 0:
                line_h += " (%d→%d)" % [health_before, health_after]
            if died:
                line_h += " [color=red](defeated)[/color]"
            return line_h
