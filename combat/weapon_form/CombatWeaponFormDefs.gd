class_name CombatWeaponFormDefs
extends RefCounted

## Weapon-scoped form/posture tables for **`CombatWeaponForm`**.
## SWORD: Liechtenauer Vier Leger + Meyer secondaries. Other weapons: treatise-specific guards.
## Canonical: **`CombatWeaponForm._def(form, weapon)`** resolves here.


static func build_all() -> Dictionary:
    return {
        "SWORD": CombatWeaponFormDefsSword._sword_forms(),
        "AXE": CombatWeaponFormDefsAxeMace._axe_forms(),
        "MACE": CombatWeaponFormDefsAxeMace._mace_forms(),
        "DAGGER": CombatWeaponFormDefsDaggerSpear._dagger_forms(),
        "SPEAR": CombatWeaponFormDefsDaggerSpear._spear_forms(),
    }
