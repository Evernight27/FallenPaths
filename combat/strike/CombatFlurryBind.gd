class_name CombatFlurryBind
extends RefCounted

## Tier 4.5 bind-exchange pilot: bounded faster wind-ups vs the bind partner after hard bind deflect.
## Keys: **`flurry_until`**, **`flurry_against_id`**, **`flurry_exchanges_left`**. Gated by
## **`is_feature_flurry_bind_exchange_enabled`** (production default **on**).

const KEY_UNTIL := "flurry_until"
const KEY_AGAINST := "flurry_against_id"
const KEY_EXCHANGES := "flurry_exchanges_left"


static func enabled() -> bool:
    return CombatConstants.is_feature_flurry_bind_exchange_enabled()


static func clear(c: Dictionary) -> void:
    if c == null:
        return
    c.erase(KEY_UNTIL)
    c.erase(KEY_AGAINST)
    c.erase(KEY_EXCHANGES)


static func is_active(c: Dictionary, combat_clock: float) -> bool:
    if not enabled() or c == null or c.is_empty():
        return false
    var left: int = c.get(KEY_EXCHANGES, 0)
    if left <= 0:
        return false
    var until: float = c.get(KEY_UNTIL, -1.0)
    if until < 0.0:
        return false
    if combat_clock >= until:
        clear(c)
        return false
    return true


static func is_active_vs(c: Dictionary, opponent_id: int, combat_clock: float) -> bool:
    if not is_active(c, combat_clock):
        return false
    return c.get(KEY_AGAINST, -1) == opponent_id


static func listing_restrict_opponent_id(c: Dictionary, manager: Node) -> int:
    if manager == null or c == null:
        return -1
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    if not is_active(c, clk):
        return -1
    return c.get(KEY_AGAINST, -1)


static func open_window(manager: Node, combatant_id: int, against_id: int) -> void:
    if not enabled() or manager == null or combatant_id < 0 or against_id < 0:
        return
    var c: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, combatant_id)
    if c.is_empty() or not CombatantEntityAccess.is_standing_combatant(c):
        return
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    c[KEY_UNTIL] = clk + CombatConstants.FLURRY_BIND_WINDOW_S
    c[KEY_AGAINST] = against_id
    c[KEY_EXCHANGES] = CombatConstants.FLURRY_BIND_MAX_EXCHANGES


static func open_pair_after_bind(manager: Node, defender_id: int, attacker_id: int) -> void:
    open_window(manager, defender_id, attacker_id)
    open_window(manager, attacker_id, defender_id)
    if not OperationalLog.is_play_session_active() or manager == null:
        return
    var def: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, defender_id)
    var atk: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, attacker_id)
    var def_n: String = CombatantEntityAccess.get_display_name(def, defender_id)
    var atk_n: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
    CombatDebug.combat_session(
        "flurry_bind opened %s vs %s exchanges=%d" % [def_n, atk_n, CombatConstants.FLURRY_BIND_MAX_EXCHANGES]
    )


static func wind_up_mult(c: Dictionary, target_id: int, combat_clock: float) -> float:
    if is_active_vs(c, target_id, combat_clock):
        return CombatConstants.FLURRY_BIND_WIND_UP_MULT
    return 1.0


## Expire stale windows during **`CombatStateHandlers.process_waiting`** (same cadence as counter-tempo).
static func process_waiting(manager: Node, c: Dictionary) -> void:
    if not enabled() or manager == null or c == null or c.is_empty():
        return
    if not c.has(KEY_UNTIL):
        return
    var clk: float = CombatantEntityAccess.combat_clock_float(manager)
    is_active(c, clk)


static func consume_exchange_on_wind_up_start(c: Dictionary) -> void:
    if not enabled() or c == null or not c.has(KEY_EXCHANGES):
        return
    var left: int = c.get(KEY_EXCHANGES, 0) - 1
    c[KEY_EXCHANGES] = left


static func stamina_attack_cost_mult(c: Dictionary, target_id: int, combat_clock: float) -> float:
    if is_active_vs(c, target_id, combat_clock):
        return CombatConstants.FLURRY_BIND_STAMINA_ATTACK_COST_MULT
    return 1.0


static func clear_pair(manager: Node, id_a: int, id_b: int) -> void:
    if manager == null:
        return
    if id_a >= 0:
        var a: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, id_a)
        if not a.is_empty():
            clear(a)
    if id_b >= 0:
        var b: Dictionary = CombatantEntityAccess.manager_get_combatant(manager, id_b)
        if not b.is_empty():
            clear(b)
