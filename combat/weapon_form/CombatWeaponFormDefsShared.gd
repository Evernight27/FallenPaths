class_name CombatWeaponFormDefsShared
extends RefCounted

## Shared building blocks for the weapon form tables: the neutral modifier
## template and the pressure-class stamina cost curve.


static func _neutral_mod() -> Dictionary:
    return {
        "parry": 1.0,
        "evasion": 1.0,
        "damage": 1.0,
        "close_attempt": 1.0,
        "ai_melee_focus": 1.0,
        "feint_readthrough": 1.0,
        "meisterhau_readthrough": 1.0,
        "ai_feint_listing": 1.0,
    }


static func _stamina_cost_for_pressure(pressure_class: String) -> float:
    match pressure_class:
        "aggressive":
            return 1.25
        "controlling":
            return 1.12
        "defensive":
            return 0.88
        _:
            return 1.0
