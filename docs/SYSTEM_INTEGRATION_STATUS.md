# System Integration Status

Verification that aggressive realism and pain systems are properly integrated. Last updated after integration audit.

---

## Active Systems (Integrated)

| System | Source | Status |
|--------|--------|--------|
| **Damage (cut)** | WeaponConstants.DAMAGE_KE_SCALE 2.0, WeaponDamageHelper | ✓ Used by CombatManager |
| **Damage (blunt)** | WeaponConstants.DAMAGE_MOMENTUM_SCALE 0.42 | ✓ Used by CombatManager |
| **Severance** | CoreEntity.MIN_DAMAGE_TO_SEVER 10 | ✓ Used in take_damage_split |
| **Body parts** | SpeciesResource (human.tres, goblin.tres) | ✓ apply_species() populates body_max, bone_max |
| **Pain reference** | SpeciesResource.get_pain_reference (divisor 32) | ✓ CoreEntity.get_effective_pain_for_thresholds |
| **Combat flow** | BattleScene → CombatManager | ✓ Main battle uses take_damage_split, body parts |

---

## Data Flow

1. **Battle start:** main.gd → BattleScene.start(players, enemies)
2. **Entities:** Character has CombatBody (CoreEntity); Enemy is CoreEntity. Both get species (human.tres / goblin.tres) and call apply_species().
3. **Damage:** CombatManager computes pre_cut, pre_blunt from WeaponDamageHelper; calls take_damage_split(pre_cut, pre_blunt, part, ...).
4. **Pain:** CoreEntity.get_total_pain() sums wounds; get_effective_pain_for_thresholds() divides by species.get_pain_reference(body_max).

## Combat Phases

1. **Combat phase:** Fight to the death—attacks only, no medical actions. Bleeding and blood loss tick during combat.
2. **Medical phase (player wins):** When all enemies eliminated, CombatManager emits `enemies_eliminated`; battle continues. Winning side performs medical actions (bandage, direct pressure, tourniquet). Bleeding continues until wounded are stabilized. "End battle" appears when `can_end_medical_phase()` (no one in medical danger).
3. **Enemy wins:** Combat ends immediately; "End battle" shown right away.

---

## Legacy / Unused

| Item | Notes |
|------|-------|
| *(none)* | Legacy Combat.gd/Combat.tscn removed; BattleScene/CombatManager is the sole combat system. |

---

## Fallbacks

| Fallback | Value | When used |
|----------|-------|-----------|
| CoreEntity (no species) | body_max 12, bone_max 8 per part | Entity has species = null |
| body_max.get(part, 10) | 10 | Missing part key (edge case) |
| get_pain_reference fallback | 6.0 | body_max sum <= 0 |

---

## Species Files

| File | Tissue (head/chest/arm/leg) | Bone | Sum |
|------|----------------------------|------|-----|
| human.tres | 10/30/12/16 | 8/22/8/12 | 96 |
| goblin.tres | 8/14/5/8 | 5/10/3/4 | 48 |
