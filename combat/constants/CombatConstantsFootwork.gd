class_name CombatConstantsFootwork
extends RefCounted

const DEFENSE_SPACING_PARRY_MULT_CLOSE := 1.04
const DEFENSE_SPACING_PARRY_MULT_LONG := 0.92
const DEFENSE_SPACING_DODGE_MULT_CLOSE := 0.94
const DEFENSE_SPACING_DODGE_MULT_LONG := 1.06
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT := 0.50
const DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE: Dictionary = {
    "attack_hit": 0.50,
    "attack_miss": 0.25,
    "attack_deflect": 0.40,
    "skip": 0.60,
    "medical": 0.45,
}
const DEFENSE_FOOTWORK_WAITING_DODGE_MULT := 1.02
const AI_FEINT_LISTING_DEFENDER_SETTLED_FOOTWORK_MULT := 0.98
const AI_FEINT_LISTING_DEFENDER_RECOVERING_FOOTWORK_MULT := 1.0 / DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE := 1.05
const AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG := 0.94
const PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT := 1.0
const PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT := 0.88
const PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT := 1.0
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE := 0.98
const FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG := 1.04


static func normalize_recovery_cause(cause: String) -> String:
    var k: String = str(cause).strip_edges()
    if k.is_empty():
        return "skip"
    if k == "parry_deflect" or k == "parry_partial":
        return "attack_deflect"
    return k


static func readiness_curve_for_cause(cause: String) -> Array:
    var k: String = normalize_recovery_cause(cause)
    return CombatConstantsRecoveryCause.READINESS_BY_CAUSE.get(
        k, CombatConstantsRecoveryCause.READINESS_BY_CAUSE.get("medical", [0.5, 0.85])
    )


static func defense_footwork_recovering_dodge_mult_for_cause(cause: String) -> float:
    var k: String = normalize_recovery_cause(cause)
    var v: Variant = DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT_BY_CAUSE.get(k, DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT)
    if v is float or v is int:
        return float(v)
    return DEFENSE_FOOTWORK_RECOVERING_DODGE_MULT


static func ai_feint_listing_defender_recovering_footwork_mult_for_cause(cause: String) -> float:
    var dodge_mult: float = defense_footwork_recovering_dodge_mult_for_cause(cause)
    if dodge_mult <= 0.001:
        return 1.0
    return 1.0 / dodge_mult


static func passive_parry_readiness_incoming_contact_mult(contact_type: String) -> float:
    match str(contact_type).to_lower().strip_edges():
        "stab":
            return PASSIVE_PARRY_READINESS_INCOMING_STAB_MULT
        "blunt":
            return PASSIVE_PARRY_READINESS_INCOMING_BLUNT_MULT
        _:
            return PASSIVE_PARRY_READINESS_INCOMING_CUT_MULT


static func defender_distance_band_to_attacker_id(defender: Dictionary, attacker_id: int) -> String:
    if attacker_id < 0:
        return "mid"
    var d: Variant = defender.get(DataKeys.COMBATANT_DISTANCE_TO, {})
    if typeof(d) != TYPE_DICTIONARY:
        return "mid"
    var s: String = str(d.get(attacker_id, "mid"))
    if s != "close" and s != "mid" and s != "long":
        return "mid"
    return s


static func ai_feint_listing_defender_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
    var band: String = defender_distance_band_to_attacker_id(defender, attacker_id)
    match band:
        "close":
            return AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_CLOSE
        "long":
            return AI_FEINT_LISTING_DEFENDER_READINESS_SPACING_MULT_LONG
        _:
            return 1.0


## CLOSE slightly harder to read feints (mult < 1), LONG slightly easier (mult > 1).


static func feint_guard_zone_readiness_spacing_mult(defender: Dictionary, attacker_id: int) -> float:
    var band: String = defender_distance_band_to_attacker_id(defender, attacker_id)
    match band:
        "close":
            return FEINT_GUARD_ZONE_READINESS_SPACING_MULT_CLOSE
        "long":
            return FEINT_GUARD_ZONE_READINESS_SPACING_MULT_LONG
        _:
            return 1.0
