# Angle-Based System Integration Status

## Overview

The combat system now uses continuous angles for trajectory, deflection, alignment, and damage. This document lists what was updated and what uses the new system.

---

## Components Updated for Angle System

### Core combat (already implemented)

| Component | Angle integration |
|-----------|-------------------|
| **CombatConstants** | Continuous angles; fatigue/readiness/off-balance/mass variance; guard wobble; arc late-parry penalty |
| **AttackResolver** | `variance_context` (stamina, off_balance, mass) for attack angle; `arc_start/end/span`; guard wobble on hit |
| **AttackWindUpStarter** | `arc_start_deg` stored in pending_attack |
| **DefenseChoiceResolver** | Guard wobble via parry_readiness; arc_span penalty for late parry |
| **DefenseResolutionHandler** | Guard wobble in parry alignment |
| **AttackPathResolver** | Path from angle_to_nearest_line; alignment from continuous angles |
| **AttackResultApplier** | Guard wobble for parry_partial guard update |

---

## Debug Logging (updated)

| Log location | Change |
|--------------|--------|
| **AttackPathResolver** | When angle-based: `(atk=47° guard=90°)` appended to path log |
| **GuardLineUpdater** | When deflect with angles: `[atk=47° guard=90°]` appended |
| **DefenseResolutionHandler** (calibration) | `atk_deg=47 guard_deg=90` appended when available |
| **DefenseChoiceResolver** (calibration) | `atk_deg=47 guard_deg=90` appended when `align_ctx` has angles |
| **AttackWindUpStarter** | `[atk=0° guard=45°]` always shown (wind-up uses angle context) |

**Flags:** Set `CombatConstants.COMBAT_DEBUG := true` and/or `COMBAT_DEBUG_CALIBRATION := true` to enable.

---

## Combat UI (updated)

| Component | Status |
|-----------|--------|
| **CombatManager.get_combatants()** | When `COMBAT_DEBUG`: includes `guard_line` and `guard_angle_deg` in output |
| **BattleUIUpdater** | When `COMBAT_DEBUG`: gauge label shows guard angle (e.g. `Ready! 45°`) for waiting combatants |
| **CombatLogFormatter** | No change — uses result dict (dmg, part, outcome); angle system feeds resolution, not formatting |
| **BattleScene** | No change — passes result to formatter; resolution already uses angles |

The combat log displays outcomes (hit, miss, parry, glancing) from the result dict. Damage and parts are computed using angles; the UI only shows the final outcome.

---

## Continuous angle system

`get_line_alignment_with_deflect` uses continuous `get_alignment_from_angles` (cos θ) when `attack_angle_deg` and `guard_angle_deg` are present. No 4-line quantization for alignment — angles drive alignment directly. Path lookup still uses `angle_to_nearest_line` for ATTACK_PATHS_BY_GUARD table keys. Deflection uses bilateral angle-based `get_deflected_angle_bilateral`. Fatigue, readiness, off-balance, weapon mass, and guard wobble all modify angle variance/placement.

## Backward compatibility

- **guard_line** and **effective_attack_line** are still used. Angles are computed alongside them.
- If `alignment_context` is empty or lacks angles, behavior falls back to line-based alignment.
- Path lookup uses `angle_to_nearest_line()` for 4-line quantization; ATTACK_PATHS_BY_GUARD remains unchanged.

---

## Enabling debug output

In `combat/CombatConstants.gd`:

```gdscript
const COMBAT_DEBUG := true           # General combat logs (path, guard, wind-up)
const COMBAT_DEBUG_CALIBRATION := true  # Parry calibration (alignment, c_d, angles)
```

When both are true, you will see:
- Path resolution with angles
- Guard deflection with atk/guard angles
- Wind-up with angle-based alignment
- Parry capacity with angles
- Gauge label with guard angle (e.g. `Ready! 90°`)
