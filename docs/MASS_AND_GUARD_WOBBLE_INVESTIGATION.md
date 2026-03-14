# Mass and Guard Wobble Implementation Audit

**Date:** March 2025  
**Status:** Implemented defender mass in guard wobble; verified all mass integration points.

## 1. Weapon Mass Integration Points (Verified Correct)

| Location | Usage | Formula / Logic |
|----------|-------|-----------------|
| **AttackResolver** | Variance context for attack angle | `var_ctx["weapon_mass_kg"]` from attacker weapon → `get_attack_angle_deg()` applies `mass_mult = 1.0 + (mass_kg - 1.0) * 0.1` to angle variance. Heavier weapon → harder to control → ±more degrees. |
| **CombatConstants** | Angle variance | `ANGLE_VARIANCE_MASS_REFERENCE_KG = 1.0`, `ANGLE_VARIANCE_MASS_SCALE = 0.1`. |
| **DefenseChoiceResolver** | Parry momentum p_a | `parry_p_a = m_a * v_intent * velocity_curve_factor`. Attacker mass. |
| **DefenseChoiceResolver** | Parry capacity c_d | `c_d_full = m_d * parry_speed * (s_d/PARRY_STRENGTH_NORM)`. Defender mass. |
| **DefenseChoiceResolver** | Blade movement time | `blade_movement_s = PARRY_BLADE_MOVEMENT_S * clamp(m_d * PARRY_STRENGTH_NORM/s_d, MIN, MAX)`. Heavy weapon + weak user = slower into position. |
| **DefenseChoiceResolver** | Block vs redirect | `is_block_parry = m_d >= m_a * 0.9`. Mass threshold. |
| **DefenseChoiceResolver** | Mass disparity redirect bonus | Light defender vs heavy attacker: `redirect_mult *= 1 + 0.18 * (1 - m_d/m_a)`. |
| **DefenseResolutionHandler** | Mass disparity redirect | Same bonus when redirecting. |
| **DefenseResolutionHandler** | Partial parry velocity | `v_reduced = (parry_p_a * glancing) / m_a`. Mass for velocity from remaining momentum. |
| **WeaponDamageHelper** | KE for cut damage | `KE = ½ * mass * velocity²`. |
| **WeaponDamageHelper** | Momentum for blunt | `momentum = mass * velocity`. |
| **WeaponDamageHelper** | Blunt momentum/area | `momentum / contact_area`. |
| **WeaponConstants** | Weapon definitions | SWORD 1.2, AXE 1.5, MACE 1.7, DAGGER 0.3, SPEAR 1.8 kg. |

## 2. Guard Wobble (Before vs After)

### Before
- `wobble = GUARD_WOBBLE_MAX_DEG * (1.0 - readiness * GUARD_WOBBLE_READINESS_SCALE)`
- **Gap:** Defender weapon mass not in wobble. Heavier defender blade = more inertia = harder to stabilize when reacting. Only readiness affected wobble.

### After (Implemented)
- New constants: `GUARD_WOBBLE_MASS_REFERENCE_KG = 1.0`, `GUARD_WOBBLE_MASS_SCALE = 0.08`
- `wobble_mult = 1.0 + (defender_mass_kg - 1.0) * 0.08` when `defender_mass_kg` present in wobble_context
- `wobble *= max(0.7, wobble_mult)` — heavier blade adds up to ~6.4% more wobble (1.8 kg spear)
- **Call sites updated** to pass `defender_mass_kg` in wobble_context:
  - DefenseChoiceResolver (normal parry, late parry)
  - DefenseResolutionHandler (parry alignment, calibration)
  - AttackResolver (hit resolution when passive_parry_attempted)
  - AttackResultApplier (parry_partial guard update)

## 3. Other Mass-Driven Attack Data (Considered, Not Implemented)

| Improvement | Description | Priority |
|-------------|-------------|----------|
| **Mass in deflection magnitude** | Heavy attacker blade harder to deflect; light defender easier to deflect. `get_deflection_magnitude_deg` could scale by mass ratio. | Low – parry_p_a/parry_c_d already encode mass. |
| **Mass in bind chance** | parry_control already factors alignment, readiness; mass ratio could modestly affect bind vs deflect. | Low |
| **Readiness in attacker variance** | Attacker in recovery has lower readiness; could pass to variance_context for attack angle. | Medium (separate fatigue/readiness scope) |
| **Arc span → deflection** | Large arc = more momentum; harder to redirect. Could scale deflection magnitude by arc_span. | Low |

## 4. File Summary

| File | Changes |
|------|---------|
| `combat/CombatConstants.gd` | Added GUARD_WOBBLE_MASS_* constants; `get_guard_angle_deg` scales wobble by `defender_mass_kg` when present. |
| `combat/DefenseChoiceResolver.gd` | Pass `defender_mass_kg` in wobble for normal and late parry alignment. |
| `combat/DefenseResolutionHandler.gd` | Pass `defender_mass_kg` in wobble for parry alignment and calibration. |
| `combat/AttackResolver.gd` | Pass `defender_mass_kg` in wobble_hit when resolving hit after passive parry. |
| `combat/AttackResultApplier.gd` | Add _EntityAccess; pass `defender_mass_kg` in wobble for parry_partial guard update. |
