class_name CombatWeaponFormDefs
extends RefCounted

## Weapon-scoped form/posture tables for **`CombatWeaponForm`**.
## SWORD: Liechtenauer Vier Leger + Meyer secondaries. Other weapons: treatise-specific guards.
## Canonical: **`CombatWeaponForm._def(form, weapon)`** resolves here.


static func build_all() -> Dictionary:
    return {
        "SWORD": CombatWeaponFormDefsPartA._sword_forms(),
        "AXE": CombatWeaponFormDefsPartA._axe_forms(),
        "MACE": CombatWeaponFormDefsPartA._mace_forms(),
        "DAGGER": CombatWeaponFormDefsPartB._dagger_forms(),
        "SPEAR": CombatWeaponFormDefsPartB._spear_forms(),
    }
