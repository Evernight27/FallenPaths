# Weapon Part Model (Level 4) Implementation Plan

Full integration plan for the weapon part length and mass distribution system. Use this document as the starting prompt for a fresh agent to implement Option 4 / Level 4 from `WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md`.

---

## Prompt for Fresh Agent

**Instructions:** Implement the full weapon part model (Level 4) as described in this plan. Read `docs/WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md` first for context. Then follow the phases in order (§4). Key files: `weapon/Weapon.gd`, `weapon/WeaponConstants.gd`, `combat/DefenseChoiceResolver.gd`, `combat/DefenseResolutionHandler.gd`, `combat/CombatConstants.gd`. Preserve backward compatibility: weapons without `parts` must behave exactly as today. Test with legacy mode (no parts) and with parts enabled.

---

## 1. Context and Goal

**Current state:** Weapons have flat properties (mass, parry_speed_factor, blade_width, etc.). Parry capacity uses whole-weapon mass; attack momentum uses whole-weapon mass. Spear, mace, and axe are incorrectly treated as blade-parrying weapons.

**Goal:** Implement the **full part model (Level 4)** with:
- Per-part length, mass fraction, parry eligibility
- Parry capacity from parrying part mass + leverage
- Attack momentum from striking part mass (for blunt/head-heavy attacks)
- Defender×attack-type modifiers for physically distinct interactions
- Extensible schema for future weapons (pollaxe, halberd, falchion, etc.)

**Reference doc:** `docs/WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md` — read §4 (weapon-specific parry contact), §5 (attacker contact part), §6 Option C, §9 (interaction matrix), §10 (differentiation levels).

---

## 2. Schema Definition

### 2.1 Part Structure

Each weapon can have an optional `parts` array. If absent, weapon uses **legacy mode** (current behavior: whole-weapon mass for parry and attack).

```gdscript
# Single part: id, length_cm, mass_fraction (0–1, must sum to 1.0 across parts), parry_eligible (bool)
# striking_for: optional Array of contact_type ("stab"|"cut"|"blunt") — if set, this part is the striking part for those moves
"parts": [
    {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
    {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
],
"parry_part_id": "blade"  # Which part is used for parrying. Must match a part with parry_eligible true.
```

### 2.2 Move → Striking Part Mapping

Each move has a `contact_type` (stab/cut/blunt). The striking part is resolved by:
1. Find part with `striking_for` containing that contact_type; else
2. Use part with matching id: stab→point/blade, cut→blade, blunt→head; else
3. Use first part (or whole weapon in legacy mode).

For simplicity, **infer from contact_type** unless a part explicitly has `striking_for`. Convention:
- **stab** → point or blade (spear: point part; sword: blade)
- **cut** → blade
- **blunt** → head (mace, poll, pommel) or shaft (pole_swing)

### 2.3 Backward Compatibility

- If weapon has no `parts`: use `mass` for parry and attack (current behavior).
- If weapon has `parts` but no `parry_part_id`: infer from first `parry_eligible` part, or fall back to legacy.
- All existing weapon consumers (WeaponDamageHelper, AttackResolver) must continue to work; add new getters that use part model when available.

---

## 3. Weapon Data Migration (WeaponConstants.gd)

### 3.1 Part Definitions per Weapon

**SWORD:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
    {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
],
"parry_part_id": "blade"
```

**DAGGER:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 20, "mass_fraction": 0.55, "parry_eligible": true},
    {"id": "handle", "length_cm": 12, "mass_fraction": 0.45, "parry_eligible": false}
],
"parry_part_id": "blade"
```

**SPEAR:**
```gdscript
"parts": [
    {"id": "head", "length_cm": 25, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab", "cut"]},
    {"id": "shaft", "length_cm": 200, "mass_fraction": 0.85, "parry_eligible": true, "striking_for": ["blunt"]}
],
"parry_part_id": "shaft"
```

**MACE:**
```gdscript
"parts": [
    {"id": "head", "length_cm": 15, "mass_fraction": 0.7, "parry_eligible": false, "striking_for": ["blunt"]},
    {"id": "shaft", "length_cm": 55, "mass_fraction": 0.3, "parry_eligible": true}
],
"parry_part_id": "shaft"
```

**AXE:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 25, "mass_fraction": 0.4, "parry_eligible": true, "striking_for": ["cut"]},
    {"id": "spike", "length_cm": 8, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab"]},
    {"id": "haft", "length_cm": 90, "mass_fraction": 0.45, "parry_eligible": true, "striking_for": ["blunt"]}
],
"parry_part_id": "haft"  # Le Jeu: haft parries common
```

### 3.2 Retention of Existing Fields

Keep `mass`, `parry_speed_factor`, `blade_width`, etc. `mass` = total mass; used for damage and as fallback when parts absent. Parts add detail for parry/attack momentum only.

---

## 4. Implementation Phases

### Phase 1: Schema and Weapon.gd Extensions

**Files:** `weapon/Weapon.gd`, `weapon/WeaponConstants.gd`

1. Add to Weapon class:
   - `parts: Array` (array of dicts: id, length_cm, mass_fraction, parry_eligible, striking_for)
   - `parry_part_id: String` (default "")
   - `parry_contact_part: String` (derived: "blade"|"shaft"|"haft" from parry_part_id for modifier lookup)

2. In `create_from_definition`, load `parts` and `parry_part_id` from def. If def has no parts, leave parts empty and parry_part_id empty (legacy).

3. Add getters:
   - `get_parry_part_mass_kg() -> float` — mass of parry_part_id; else total mass
   - `get_parry_part_length_cm() -> float` — length of parry part; else 0
   - `get_striking_part_mass_kg(contact_type: String) -> float` — mass of part used for that contact_type; else total mass
   - `has_parts() -> bool`
   - `get_parry_contact_type() -> String` — "blade"|"shaft"|"haft" for modifier lookup; default "blade" if legacy or unknown

4. Add `PARRY_CONTACT_TYPE_BY_PART_ID` in WeaponConstants or CombatConstants: `{"blade"=>"blade", "handle"=>"blade", "shaft"=>"shaft", "haft"=>"haft", "head"=>""}` (head never parries).

---

### Phase 2: Parry Capacity (Defender) — DefenseChoiceResolver

**Files:** `combat/DefenseChoiceResolver.gd`, `combat/CombatConstants.gd`

1. In `_compute_parry_c_d(def_weapon, tgt)`:
   - Replace `m_d = def_weapon.mass` with:
     ```gdscript
     var m_d: float = def_weapon.get_parry_part_mass_kg() if def_weapon.has_parts() else float(def_weapon.mass)
     ```
   - After base `c_d_full`, multiply by parry contact modifier:
     ```gdscript
     var contact_type: String = def_weapon.get_parry_contact_type() if def_weapon.has_parts() else "blade"
     c_d_full *= CombatConstants.PARRY_CONTACT_MODIFIERS.get(contact_type, 1.0)
     ```

2. Add to CombatConstants:
   ```gdscript
   const PARRY_CONTACT_MODIFIERS: Dictionary = {
       "blade": 1.0,
       "shaft": 0.88,
       "haft": 0.92
   }
   ```

3. Optional leverage factor for shaft/haft: `c_d_full *= leverage_factor(parry_part_length_cm)` — e.g. `min(1.1, 0.95 + sqrt(length_cm) / 100)` or similar. Defer to calibration.

4. Defender×attack_type modifiers (selective Level 2):
   - Add `PARRY_DEFENDER_VS_ATTACK_MODIFIERS: Dictionary` keyed by `defender_weapon_type + "_vs_" + attack_type` or nested dict.
   - Example keys: `DAGGER_vs_stab: 0.9`, `MACE_vs_blunt: 1.05`
   - Apply after contact modifier: `c_d_full *= get_defender_vs_attack_mod(def_weapon.weapon_type, attack_type)`

---

### Phase 3: Attack Momentum (parry_p_a) — DefenseChoiceResolver and DefenseResolutionHandler

**Files:** `combat/DefenseChoiceResolver.gd`, `combat/DefenseResolutionHandler.gd`

1. **parry_p_a computation** (DefenseChoiceResolver):
   - Use striking part mass when weapon has parts and move contact_type is BLUNT (head-heavy attacks):
     ```gdscript
     var m_a_striking: float = atk_weapon.get_striking_part_mass_kg(contact_type) if atk_weapon.has_parts() else float(atk_weapon.mass)
     parry_p_a = m_a_striking * v_intent * CombatTiming.velocity_curve_factor(parry_progress)
     ```
   - For thrust/cut, keep `m_a = atk_weapon.mass` (whole weapon moves together; striking part = blade/point, mass fraction already in total).
   - **Simpler option:** Use striking part mass for ALL attack types when parts exist. Thrust uses point/blade mass; cut uses blade; blunt uses head. Consistent treatment.

2. **Block check** (`m_a_parry`, `m_d_parry`):
   - Keep as **total mass** for both. Block = "can you physically stop the weapon" — total vs total.
   - No change to how these are set.

3. **Partial parry velocity** (DefenseResolutionHandler):
   - Current: `v_reduced = (parry_p_a * glancing_factor) / m_a`
   - When `parry_p_a` uses striking mass, remaining momentum = parry_p_a - c_d is "striking part momentum." For rigid weapon, v_striking = v_whole. So `v_reduced = remaining_momentum / m_striking`.
   - **Change:** Pass `m_a_velocity` in the defense choice result: use striking mass when weapon has parts and parry_p_a used striking mass; else total mass.
   - In DefenseResolutionHandler, use `m_a_velocity` (not m_a_parry) for the v_reduced denominator when computing partial parry.
   - Add to choose_defense result: `m_a_velocity: float` = `atk_weapon.get_striking_part_mass_kg(contact_type)` when parts else `atk_weapon.mass`.
   - DefenseResolutionHandler receives dc and uses `dc.m_a_velocity` for v_reduced when present; else `dc.m_a_parry` (backward compat).

**Summary:** parry_p_a and v_reduced both use striking mass when weapon has parts; block check uses total mass.

---

### Phase 4: Weapon.get_striking_part_mass_kg Logic

**File:** `weapon/Weapon.gd`

Implement `get_striking_part_mass_kg(contact_type: String)`:
1. If no parts, return `mass`.
2. Find part with `striking_for` containing contact_type.
3. Else infer: contact_type "stab" → part id "point" or "blade" or "spike"; "cut" → "blade"; "blunt" → "head" or "haft".
4. Return that part's `mass_fraction * mass`.
5. If no matching part, return `mass`.

Add `get_parry_part_mass_kg()`: return part with parry_part_id; else mass.

---

### Phase 5: Defender×Attack Modifiers (Selective)

**File:** `combat/CombatConstants.gd` or `combat/DefenseChoiceResolver.gd`

Add lookup:
```gdscript
# def_weapon_type, attack_type -> multiplier
const PARRY_DEF_VS_ATK_MOD: Dictionary = {
    "DAGGER": {"stab": 0.9},
    "MACE": {"blunt": 1.05},
    "SPEAR": {"cut": 0.95}
}
```

In DefenseChoiceResolver, after computing parry_c_d, multiply by `PARRY_DEF_VS_ATK_MOD.get(def_weapon.weapon_type, {}).get(attack_type, 1.0)`.

---

### Phase 6: Strong/Weak (Blade Weapons) — Optional Enhancement

For blade parrying parts, strong_fraction = handle_length / total_length. When attacker archetype is OVERHEAD (exposes weak), multiply parry_c_d by `(1 + STRONG_CONTACT_BONUS)` — replace or augment PARRY_STRONG_CONTACT_BY_ARCH. Defer to calibration; can be Phase 7.

---

## 5. Defense Choice Result Additions

Add to the dict returned by `DefenseChoiceResolver.choose_defense`:
- `m_a_velocity: float` — mass to use for v_reduced in partial parry. When atk_weapon has parts: `get_striking_part_mass_kg(contact_type)`. Else: `atk_weapon.mass`. Same as m_a_parry when no parts.

---

## 6. File Change Summary

| File | Changes |
|------|---------|
| `weapon/Weapon.gd` | Load parts, parry_part_id; add get_parry_part_mass_kg, get_striking_part_mass_kg, get_parry_contact_type, has_parts, get_parry_part_length_cm |
| `weapon/WeaponConstants.gd` | Add parts and parry_part_id to each weapon definition (§3.1) |
| `combat/CombatConstants.gd` | PARRY_CONTACT_MODIFIERS, PARRY_DEF_VS_ATK_MOD |
| `combat/DefenseChoiceResolver.gd` | _compute_parry_c_d uses parry part mass + contact mod; parry_p_a uses striking part mass; def_vs_atk mod |
| `combat/DefenseResolutionHandler.gd` | Use dc.m_a_velocity (striking mass) for v_reduced when partial parry; fallback to m_a_parry |
| `combat/PassiveParryContext.gd` | No structural change; get_parry_speed_m_s unchanged |
| `combat/CombatantEntityAccess.gd` | Verify get_weapon returns Weapon with new getters |

---

## 7. Move contact_type Resolution

DefenseChoiceResolver receives `attack_type` (move_id). Resolve contact_type via:
```gdscript
var move_def = WeaponConstants.get_move(attack_type)
var contact_type = move_def.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
```

Use `contact_type` for get_striking_part_mass_kg and for PARRY_DEF_VS_ATK_MOD lookup.

---

## 8. Testing and Validation

1. **Legacy mode:** Disable parts (comment out in weapon defs) — parry and attack behavior should match current.
2. **Sword vs sword:** Parry capacity similar; blade part used.
3. **Spear defender:** Parry capacity uses shaft mass (~0.85 * 1.8 = 1.53 kg); ×0.88 contact mod.
4. **Mace defender vs blunt:** Parry capacity uses shaft mass; ×1.05 def_vs_atk for MACE+blunt.
5. **Mace attacker (overhead):** parry_p_a uses head mass (0.7 * 1.7 = 1.19 kg × v) — lower than current 1.7×v; tune if needed.
6. **Calibration:** Run combat logs; compare parry rate to HEMA 57–80% blade-blade. Adjust PARRY_CONTACT_MODIFIERS and PARRY_DEF_VS_ATK_MOD.

---

## 9. Order of Execution for Agent

1. Read `WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md` (full doc).
2. Phase 1: Extend Weapon.gd and WeaponConstants.gd (schema + data).
3. Phase 2: Parry capacity in DefenseChoiceResolver + CombatConstants.
4. Phase 3: Attack momentum (parry_p_a) in DefenseChoiceResolver.
5. Phase 4: Implement get_striking_part_mass_kg and get_parry_part_mass_kg in Weapon.gd.
6. Phase 5: Defender×attack modifiers.
7. Phase 6 (optional): Strong/weak.
8. Test and calibrate.

---

## 10. Edge Cases

- **Weapon without parts:** All getters return total mass / default values.
- **Part mass_fraction not summing to 1.0:** Normalize or warn; document.
- **parry_part_id missing but parts present:** Use first parry_eligible part.
- **No parry_eligible part:** Fall back to largest mass part or legacy.
- **New weapons:** Add parts array and parry_part_id; follow same schema.
