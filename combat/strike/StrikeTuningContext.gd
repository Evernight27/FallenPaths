class_name StrikeTuningContext
extends RefCounted

## Strike tuning/telemetry payload enrichment extracted from AttackResultApplier (pure code-motion split).
## Stamps wind-up / guard / parry / follow-through context onto ction_resolved payloads when the
## manager exposes the tuning context. All functions static and stateless; delegates in
## AttackResultApplier keep existing call sites unchanged.


static func _tuning_follow_through_extras(atk: Dictionary) -> Dictionary:
    if atk.is_empty() or not atk.has(DataKeys.PA_TUNING_FT_PARENT_STRIKE):
        return {}
    return {
        "parent_exchange_index": int(atk[DataKeys.PA_TUNING_FT_PARENT_STRIKE]),
        "note": "follow_through_from_parry",
    }


static func _clear_tuning_follow_through_marker(atk: Dictionary) -> void:
    if not atk.is_empty():
        atk.erase(DataKeys.PA_TUNING_FT_PARENT_STRIKE)


static func _tuning_parry_parent_strike_index(manager: Node) -> int:
    if manager == null:
        return -1
    return int(manager.get_meta("tuning_strike_count", 0)) + 1


static func _hit_tuning_extras(
    atk: Dictionary, intensity: float, recovery_duration: float, ft_extras: Dictionary
) -> Dictionary:
    var extras: Dictionary = {
        "intensity": intensity,
        "recovery_s": recovery_duration,
        "move_id":
        atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, "")) if not atk.is_empty() else "",
        "attack_line": atk.get(DataKeys.ATTACK_EFFECTIVE_ATTACK_LINE, "") if not atk.is_empty() else "",
    }
    extras.merge(ft_extras)
    return extras


static func _tuning_context_enabled(manager: Node) -> bool:
    return manager != null and bool(manager.get_meta("tuning_expose_strike_context", false))


## Tuning scene: stamp wind-up / guard / parry context on `action_resolved` payloads.
static func _enrich_payload_for_tuning(
    manager: Node, payload: Dictionary, atk: Dictionary, tgt: Dictionary, pa: Dictionary, extras: Dictionary = {}
) -> void:
    if not _tuning_context_enabled(manager):
        return
    if not pa.is_empty():
        payload[DataKeys.RESULT_MOVE_ID] = str(pa.get(CombatConstants.PA_KEY_ATTACK_TYPE, ""))
        payload[DataKeys.ATTACK_INTENSITY] = float(pa.get(DataKeys.ATTACK_INTENSITY, 0.0))
        payload[DataKeys.RESULT_POWER] = float(pa.get(DataKeys.ATTACK_POWER, 0.0))
        payload[DataKeys.RESULT_FOLLOW_THROUGH] = float(pa.get(DataKeys.ATTACK_FOLLOW_THROUGH, 0.0))
        payload["wind_up_s"] = float(pa.get(DataKeys.PA_WIND_UP_DURATION, 0.0))
        payload[DataKeys.RESULT_ATTACK_LINE] = str(pa.get(CombatConstants.PA_KEY_EFFECTIVE_ATTACK_LINE, ""))
        if pa.has(DataKeys.PA_GAUGE_ATK_PRE):
            payload[DataKeys.PA_GAUGE_ATK_PRE] = float(pa[DataKeys.PA_GAUGE_ATK_PRE])
            payload["gauge_def_pre"] = float(pa.get(DataKeys.RESOLVE_GAUGE_DEF_PRE, -1.0))
    if not atk.is_empty():
        if str(payload.get(DataKeys.ACTION_MOVE_ID, "")).is_empty():
            payload[DataKeys.RESULT_MOVE_ID] = str(
                atk.get(DataKeys.PA_LAST_MOVE_ID, atk.get(DataKeys.ATTACK_LAST_MOVE_ID, ""))
            )
        if not payload.has(DataKeys.PA_GAUGE_ATK_PRE) and atk.has(DataKeys.PA_GAUGE_ATK_PRE):
            # Hit path: pending_attack was already cleared, but AttackResolver preserves the wind-up
            # gauge context on the combatant dict alongside last_move_id — read it from there.
            payload[DataKeys.PA_GAUGE_ATK_PRE] = float(atk[DataKeys.PA_GAUGE_ATK_PRE])
            payload["gauge_def_pre"] = float(atk.get(DataKeys.PA_GAUGE_DEF_PRE, -1.0))
        payload["atk_guard"] = str(atk.get(DataKeys.ATTACK_GUARD_LINE, ""))
        payload["atk_form"] = str(atk.get(DataKeys.PA_WEAPON_FORM, atk.get(DataKeys.COMBATANT_FORM_STR, "")))
        if CombatantEntityAccess.has_weapon(atk):
            var w = CombatantEntityAccess.get_weapon(atk)
            if w is Dictionary:
                payload[DataKeys.RESULT_WEAPON_ID] = str((w as Dictionary).get("id", ""))
            elif w != null and w.get("id") != null:
                payload[DataKeys.RESULT_WEAPON_ID] = str(w.id)
    if not tgt.is_empty():
        payload["def_guard"] = str(tgt.get(DataKeys.ATTACK_GUARD_LINE, ""))
    for k in extras:
        payload[k] = extras[k]
    if str(payload.get(DataKeys.WD_KINEMATIC_DELIVERY, "")).is_empty() and not pa.is_empty():
        var arch: Variant = pa.get(DataKeys.WD_ARCHETYPE, null)
        if arch is Dictionary:
            var arch_delivery: String = str((arch as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
            if not arch_delivery.is_empty():
                payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = arch_delivery
    var outcome: String = str(payload.get(DataKeys.RESULT_OUTCOME, ""))
    if outcome in ["parry_deflect", "parry_partial"]:
        var clash: Variant = payload.get(DataKeys.PA_PARRY_CLASH_CONTEXT, null)
        if clash is Dictionary:
            payload["parry_bind"] = bool(tgt.get(DataKeys.PA_PARRY_WAS_BIND, false)) if not tgt.is_empty() else false
            payload[DataKeys.RESULT_PARRY_CONTROL] = float(
                (clash as Dictionary).get(CombatConstants.CLASH_KEY_PARRY_CONTROL, 0.0)
            )
            if (clash as Dictionary).has(DataKeys.RESULT_REMAINING_RATIO):
                payload["follow_through_rem"] = float((clash as Dictionary)[DataKeys.RESULT_REMAINING_RATIO])
            var delivery: String = str((clash as Dictionary).get(DataKeys.WD_KINEMATIC_DELIVERY, ""))
            if not delivery.is_empty():
                payload[DataKeys.RESULT_KINEMATIC_DELIVERY] = delivery
