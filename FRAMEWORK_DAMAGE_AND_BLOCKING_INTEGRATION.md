# FallenFramework Damage, Force/Kinetic, and Armor Blocking — Integration Options

This document summarizes how **FallenFramework** (E:\FallenFramework\fallen-framework) handles weapon damage, force/kinetic energy, and armor/shield blocking, and compares ways to integrate those ideas into **fallen-paths** (your current project).

---

## 1. FallenFramework System Summary

### 1.1 Weapon damage (Combat Extended–style)

- **Weapon.gd**
  - Per attack type: `stab` / `cut` / `blunt` each have `damage`, `armor_penetration`, `cooldown`.
  - Physical properties: `mass` (kg), `blade_width`, `point_width`, `head_diameter` (cm) — used for “kinetic” modifier.
  - Stats come from **WeaponConstants.WEAPON_STATS** (e.g. SWORD, AXE, MACE, DAGGER).

- **DamageCalculator.calculate_pre_armor_damage()**
  - Base damage from weapon’s `get_damage(attack_type)`.
  - Modifiers:
    - Weapon durability (linear: 50% durability → 50% damage).
    - Strength: `(strength / 100) * 0.1` (STR damage modifier).
    - Quality (from QualityConstants).
    - Melee skill: 5% per skill level, max +50% at 100.
    - **Combat pressure penalty**: -0.1% per pressure point, max -10%.
    - **Physical modifier (mass + contact area)** — see below.
    - Weapon-arm functionality (injured arm reduces damage).

- **Force / “kinetic” in damage**
  - Implemented only as the **physical modifier** in `DamageCalculator._calculate_physical_modifier()`:
    - **Mass**: `sqrt(mass / 1.0)` — heavier weapons do more impact (diminishing returns).
    - **Contact area**: blade/point/head width vs 2 cm baseline; ±10% per cm difference.
    - Formula: `physical_modifier = mass_factor * contact_factor`.
  - There is no separate “kinetic energy” or velocity value; mass and contact area stand in for that.

### 1.2 Armor (layered, deflection, penetration)

- **Armor.gd** (extends Equipment)
  - Layers: OUTER → MIDDLE → INNER (e.g. plate → mail → gambeson).
  - Per layer: `sharp_resistance_rha_mm`, `blunt_resistance_mpa`, durability, weight.
  - **ArmorConstants**: DAMAGE_TYPE_SHARP, DAMAGE_TYPE_BLUNT; resistance in mm RHA (sharp) and MPa (blunt).

- **DamageCalculator._apply_layered_armor_protection()**
  - For each layer, compare **armor penetration** (from weapon + attack type) to **layer resistance**:
    - **Penetration &lt; resistance** → **Deflection**:
      - Halve damage.
      - Convert to BLUNT for remaining layers.
      - Compare blunt penetration (MPa) to blunt resistance; can reduce damage further (or to zero).
    - **Penetration ≥ resistance** → **Penetration**:
      - Damage reduced by a factor based on resistance/penetration (up to 50% reduction).
  - Durability loss on layers from absorbed damage.
  - Critical hits double armor penetration only (no extra damage).

### 1.3 Shield blocking

- **Blocking.gd**
  - **Block chance**: base from shield + agility scaling (0 AGI → 5%, 100 AGI → shield base, 200 AGI → 75% cap).
  - **roll_block(block_chance)** → if success, attack is “blocked”.
  - **check_block(attack, target)**:
    - If no shield or shield broken → false (no block).
    - Else roll; on success → **redirect attack to shield arm** (left/right from inventory).
  - Shield arm functionality (injured arm) reduces block chance; disabled arm → 0% block.

- **Shield.gd** (extends Armor)
  - Shield is an armor layer over the arm: same layer API (sharp/blunt resistance, durability).
  - When block succeeds, **CombatDefensiveActionHandler** sets `attack.target_body_part = shield_arm`; then normal damage pipeline runs: **shield layers + arm armor** are combined in **DamageCalculator** via **CombinedArmor** (shield first, then arm armor). So “blocking” = redirect to arm + armor calculation, not zero damage.

### 1.4 Combat flow (melee)

1. Build **Attack** (attacker, target, weapon, attack_type, target_body_part).
2. **Defensive actions** (CombatDefensiveActionHandler): **Dodge → Block → Parry**.
   - Block: `Blocking.check_block()`; if true, redirect to shield arm.
3. **CombatMeleeHitHandler.process_melee_hit()**:
   - Critical hit check; set `attack.armor_penetration`.
   - `DamageCalculator.calculate_pre_armor_damage(attack, pressure)`.
   - Apply style/pattern modifiers.
   - For each body part in swing path: `DamageCalculator.calculate_damage_for_part(pre_armor_damage, attack, part, part_armor)` → applies body part size + layered armor (including CombinedArmor for shield arm).
   - Apply damage to target’s health (and organs/brain if applicable).

So: **weapon damage** and **force (physical modifier)** are in DamageCalculator; **armor** is layered deflection/penetration; **blocking** is redirect + same armor pipeline on shield arm.

---

## 2. Your Current System (fallen-paths)

- **CombatManager.gd**
  - Turn-based: combatants have gauge; on 100, resolve_action(attacker_id, target_id).
  - Damage: `dmg = int(atk.stats.strength * mod)` with `get_attack_damage_modifier()` (arm functionality).
  - Damage types: SHARP / BLUNT; target part from `get_targetable_parts()`; applied to `body_cutting` or `body_blunt`.
  - No weapons, no armor, no shields, no blocking.

- **CoreEntity.gd** / **character.gd**
  - Body parts with `body_cutting`, `body_blunt`, `body_max`; `take_damage(amount, part, damage_type)`.
  - No equipment/inventory, no armor layers.

---

## 3. Integration Options (compared)

### Option A — Minimal: Add weapon base damage + simple block chance

**Idea:** Keep your current resolution (strength × mod, one part, SHARP/BLUNT). Add:
- A small **Weapon** (or weapon stats) that provides base damage and optionally damage type.
- A simple **block chance** (e.g. from a “shield” flag or stat); if roll succeeds, either:
  - Redirect hit to a “shield arm” part and apply damage there, or
  - Treat as “blocked” and apply reduced or zero damage.

**Pros:** Small code surface, fits current CombatManager and CoreEntity.  
**Cons:** No framework-style armor layers, no mass/contact “force” modifier, no parry/dodge.

**Good for:** Getting “weapon damage” and “block” into the game quickly without adopting the full framework.

---

### Option B — Adopt framework damage formula (no full armor layers)

**Idea:** In fallen-paths, add:
- **Weapon** (or equivalent) with per–attack-type damage, armor_penetration, and physical stats (mass, blade_width, point_width, head_diameter).
- **DamageCalculator**-style **pre-armor formula** in your own script (e.g. `DamageCalculatorLight.gd`):
  - Base damage from weapon.
  - Strength modifier, quality (if you add it), skill (if you add it).
  - **Physical modifier** = mass factor × contact factor (copy framework’s logic) so “force/kinetic” is represented.
  - Optionally combat-pressure penalty (if you add a simple pressure stat).
- Keep your current **body part + SHARP/BLUNT** application; optionally one **flat armor reduction** per part (e.g. “armor reduces damage by X%”) instead of full layered deflection/penetration.

**Pros:** Same “feel” as framework damage and force (mass/contact), without full Armor/Shield classes.  
**Cons:** You reimplement a slice of DamageCalculator and weapon constants; no layered armor.

**Good for:** Matching framework damage and “kinetic” feel while keeping your combat simple.

---

### Option C — Copy framework modules (DamageCalculator + Blocking + Shield)

**Idea:** Reuse or copy from FallenFramework:
- **DamageCalculator** (and dependencies: DamageConstants, BodyPartSizeConstants, ArmorConstants, etc.).
- **Weapon** (and WeaponConstants), **Armor**, **Shield**, **Blocking** (and BlockingConstants).
- **Attack** class; **CombatDefensiveActionHandler** (dodge/block/parry).

Your CombatManager would:
1. Build an **Attack** (you’d need a thin adapter from your combatant/node to Creature if you don’t use Creature).
2. Call defensive action handler; if block, set target_body_part to shield arm.
3. Call DamageCalculator for pre-armor damage and then per-part damage with armor (and CombinedArmor when shield arm is targeted).
4. Apply result to CoreEntity’s body_cutting/body_blunt (or extend CoreEntity to match Creature’s health API).

**Pros:** Full framework behavior: weapon damage, force modifier, layered armor, deflection, shield blocking as redirect + armor.  
**Cons:** Heavy dependency (Creature, inventory, BodyPartType, many constants); your nodes must satisfy the expected APIs (Creature, health, inventory).

**Good for:** Maximum consistency with FallenFramework and full realism.

---

### Option D — Hybrid: Framework-style damage + blocking in your structure

**Idea:** Keep CombatManager and CoreEntity as the source of truth, but:
- Add **weapon stats** (and optionally a small **Weapon** class) with damage, armor_penetration, mass, contact widths.
- Add a **DamageCalculator**-like static class in your project that only needs:
  - Attacker (strength, arm functionality, optional skill/pressure).
  - Weapon (damage, armor_penetration, mass, contact width for attack type).
  - Returns pre-armor damage and armor penetration.
- Add **armor** as “per-body-part resistance” (single layer or two layers) and a small **apply_armor()** that does penetration vs resistance and deflection (sharp→blunt, halve) so it feels like the framework without full Armor.gd.
- Add **Blocking**: shield + block chance; on success redirect to shield arm; that arm uses “shield + arm armor” in the armor step (you can do CombinedArmor in miniature: one shield layer + one arm layer).

**Pros:** Framework’s damage, force, armor, and blocking semantics with minimal dependency on Creature/inventory/Health.  
**Cons:** You still implement or adapt a fair amount of logic (damage formula, armor, block redirect).

**Good for:** Best balance of “same as framework” behavior and “fits fallen-paths” structure.

---

## 4. Recommendation summary

| Goal | Option |
|------|--------|
| Quick weapon damage + simple block | **A** |
| Framework-like damage and “force” (mass/contact), keep simple armor | **B** |
| Full framework behavior, same codebase/APIs | **C** |
| Framework behavior with your own structure and minimal framework types | **D** |

Suggested path: implement **Option B** first (weapon stats + pre-armor formula with physical modifier in your project); then add a simple **block chance + redirect to shield arm** (Option A–style) and a single-layer or two-layer **armor** (Option D–style) so you get weapon damage, force/kinetic feel, armor blocking, and shield blocking without depending on the full FallenFramework stack.

---

## 5. Key files in FallenFramework (for reference)

| System | Files |
|--------|--------|
| Weapon damage + physical modifier | `Combat/DamageCalculator.gd`, `Equipment/Weapon.gd`, `Equipment/constants/weapon_constants.gd`, `Combat/constants/damage_constants.gd` |
| Layered armor / deflection | `Combat/DamageCalculator.gd` (_apply_layered_armor_protection, CombinedArmor), `Equipment/Armor.gd`, `Equipment/constants/armor_constants.gd` |
| Shield blocking | `Equipment/Blocking.gd`, `Equipment/Shield.gd`, `Equipment/constants/blocking_constants.gd`, `Equipment/constants/shield_constants.gd` |
| Defensive order (dodge → block → parry) | `Combat/utilities/CombatDefensiveActionHandler.gd` |
| Attack + melee resolution | `Combat/Attack.gd`, `Combat/utilities/CombatMeleeHitHandler.gd` |

If you tell me which option you want (A, B, C, or D), I can outline concrete steps and code changes in fallen-paths next (e.g. new scripts, changes to CombatManager and CoreEntity).
