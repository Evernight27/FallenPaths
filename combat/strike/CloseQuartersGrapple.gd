class_name CloseQuartersGrapple
extends RefCounted

## Close-quarters grapple escalation (CQEE), extracted from **`AttackResolver`**.
## Tracks repeated low-damage exchanges between close-quarters combatants and escalates them to
## grappling/clinch (Fiore dagger-treatise basis). Pure functions over combatant dicts (state carried
## on the combatant via `DataKeys`). External deps are class_name only (no `preload`).


## Check if repeated low-damage exchanges between close-quarters combatants should escalate to grappling/clinch.
## Historical basis: Fiore's dagger treatises show that blade clashes at close range quickly transition to
## body grabs and throws — real fights don't sustain 50+ exchanges of minor cuts when fighters are within
## arm-reach of each other. This implements "close quarters engagement escalation" (CQEE).
static func check_close_quarters_grapple_escalation(
    manager: Node, attacker_id: int, target_id: int, strike_damage: float, outcome: String
) -> Dictionary:
    if outcome not in ["hit", "glancing"]:
        return {}
    var dmg_val: float = strike_damage if strike_damage > 0.0 else float(strike_damage)

    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var tgt: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, target_id)
    if atk.is_empty() or tgt.is_empty():
        return {}

    var atk_weapon_type: String = CombatantEntityAccess.weapon_type_id(atk)
    var grapple_max_dmg: float = CombatConstants.CLOSE_QUARTERS_GRAPPLE_MAX_DAMAGE_FOR_TRIGGER
    if atk_weapon_type == "DAGGER":
        grapple_max_dmg = 18.0
    if dmg_val >= grapple_max_dmg:
        return {}

    var band: String = CombatantEntityAccess.distance_to_opponent_band(atk, target_id)
    if band != CombatConstants.DISTANCE_CLOSE:
        return {}

    var now: float = CombatTiming.now_seconds()

    # Check cooldown — don't trigger grapple more than once per cooldown period.
    var atk_grap_cooldown: float = atk.get(DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN, -1.0)
    if atk_grap_cooldown > 0.0 and now < atk_grap_cooldown:
        return {}

    # Count recent exchanges between this pair (both directions).
    var exchange_count: int = _get_close_quarters_exchange_count(atk, tgt)
    var avg_damage: float = _get_close_quarters_avg_damage(atk, tgt)

    # Blade-bind escalation: if either combatant has "hard" bind pressure from parry binds, reduce strike threshold.
    var clk: float = now
    var atk_bind_state: String = CombatBindPressure.get_bind_state(atk, clk)
    var tgt_bind_state: String = CombatBindPressure.get_bind_state(tgt, clk)
    var bind_escalation: bool = atk_bind_state == "hard" or tgt_bind_state == "hard"

    if exchange_count >= CombatConstants.CLOSE_QUARTERS_GRAPPLE_TRIGGER_STRIKE_COUNT and avg_damage <= grapple_max_dmg:
        # Trigger grappling resolution — record the escalation.
        atk[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
        tgt[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
        return {
            "outcome": "close_quarters_grapple",
            "exchange_count": exchange_count,
            "avg_damage": avg_damage,
        }

    if bind_escalation and exchange_count >= 2 and avg_damage <= grapple_max_dmg:
        atk[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
        tgt[DataKeys.CLOSE_QUARTERS_GRAPPLE_COOLDOWN] = now + CombatConstants.CLOSE_QUARTERS_GRAPPLE_COOLDOWN_S
        return {
            "outcome": "close_quarters_grapple",
            "exchange_count": exchange_count,
            "avg_damage": avg_damage,
            "bind_escalation": true,
        }

    return {}


static func _get_close_quarters_exchange_count(atk: Dictionary, tgt: Dictionary) -> int:
    var pair_key: String = _make_pair_key(atk, tgt)
    var exchanges: Variant = atk.get(DataKeys.CLOSE_QUARTERS_EXCHANGES, {})
    if exchanges is Dictionary and exchanges.has(pair_key):
        return int(exchanges.get("count", 0))
    return 0


static func _get_close_quarters_avg_damage(atk: Dictionary, tgt: Dictionary) -> float:
    var pair_key: String = _make_pair_key(atk, tgt)
    var exchanges: Variant = atk.get(DataKeys.CLOSE_QUARTERS_EXCHANGES, {})
    if exchanges is Dictionary and exchanges.has(pair_key):
        var data: Variant = exchanges[pair_key]
        if data is Dictionary:
            return data.get("avg_damage", 99.0)
    return 99.0


static func _record_close_quarters_exchange(atk: Dictionary, tgt: Dictionary, damage: float) -> void:
    var pair_key: String = _make_pair_key(atk, tgt)
    if not atk.has(DataKeys.CLOSE_QUARTERS_EXCHANGES):
        atk[DataKeys.CLOSE_QUARTERS_EXCHANGES] = {}
    var exchanges: Dictionary = atk[DataKeys.CLOSE_QUARTERS_EXCHANGES]

    if not exchanges.has(pair_key):
        exchanges[pair_key] = {"count": 0, "total_damage": 0.0, "avg_damage": 99.0}
    var data: Dictionary = exchanges[pair_key]
    data["count"] = int(data.get("count", 0)) + 1
    data["total_damage"] = float(data.get("total_damage", 0.0)) + damage
    if data["count"] > 0:
        data["avg_damage"] = data["total_damage"] / data["count"]


static func _make_pair_key(atk: Dictionary, tgt: Dictionary) -> String:
    var id_a: int = CombatantEntityAccess.id_int(atk)
    var id_b: int = CombatantEntityAccess.id_int(tgt)
    if id_a < id_b:
        return "%d-%d" % [id_a, id_b]
    return "%d-%d" % [id_b, id_a]
