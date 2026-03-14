# Transition Cost & Weapon Positioning: Implementation Investigation

Investigation into how transition costs (wind-up penalty when blade must move from current guard) integrate with the new weapon positioning system to ensure physical accuracy.

---

## 1. Current Implementation

### 1.1 Weapon Position (guard_line) Updates

| Event | guard_line Update | Location |
|-------|-------------------|----------|
| **Attack recovery complete** | `guard_line = attack_line` of move used | CombatStateHandlers.process_recovering |
| **Parry deflect** | Defender: `guard_line = attack_line` (met attack) | AttackResultApplier |
| **Parry partial** | Defender: `guard_line = attack_line` | AttackResultApplier |

### 1.2 Transition Cost

| Location | Formula | Constant |
|----------|---------|----------|
| CombatManager._begin_attack_with_target | `wind_up_s *= 1 + (1 - alignment) * GUARD_TRANSITION_COST_SCALE` | GUARD_TRANSITION_COST_SCALE = 0.4 |
| CombatConstants | Alignment from `get_line_alignment(attack_line, guard_line)` | LINE_ANGLE_DEG |

**Alignment** = cos(θ) between guard and attack line. Same line = 1.0; opposite = 0.15 (floor).

---

## 2. Accuracy Check: Order of Operations

**Correct flow:**
1. Attacker begins wind-up. At that moment, attacker's `guard_line` is their current position (from last action or default "high").
2. Transition cost is applied: `wind_up_s *= trans_mult` where `trans_mult` depends on `alignment(attack_line, guard_line)`.
3. Attack executes. Attacker goes to RECOVERING. `last_move_id` is set.
4. Recovery completes. Attacker's `guard_line` is updated to `attack_line` of that move.
5. Attacker's next action uses this new `guard_line` for transition cost.

**Potential issue:** When does `guard_line` get read for transition cost? At `_begin_attack_with_target`. At that moment, the combatant's `guard_line` should reflect their state at the *start* of the attack. For the first attack of the exchange, we use default "high" or whatever was set. For subsequent attacks, we use the guard from the last completed action. ✓ Correct.

---

## 3. Edge Cases

### 3.1 Parry-Deflect Defender

Defender parried. Their `guard_line = attack_line` (they met the attack). Defender is in WAITING, gauge filling. When defender acts next:
- They choose a move. That move has `attack_line`.
- Defender's `guard_line` = attack line of the attack they parried.
- If defender chooses a parry-counter (parry_thrust, parry_cut), the `attack_line` often matches the line they parried. So alignment ≈ 1. ✓ Fast riposte.

### 3.2 Parry-Partial Defender

Defender partially parried. Their `guard_line = attack_line`. Same logic. Defender's blade ended in that line when they redirected the attack. ✓ Correct.

### 3.3 Attacker After Miss/Dodge

Attacker missed or target dodged. Attacker goes to RECOVERING. When recovery completes, `guard_line = attack_line` of the move they used. Their blade travelled that path and ended there. ✓ Correct.

### 3.4 Attacker After Parry-Deflect

Attacker was parried. Their blade was deflected. Arguably, their blade did *not* end in the natural attack_line—it was knocked aside. Current implementation: we still set `guard_line = attack_line` when they recover (from `last_move_id`). Approximation: the attacker's intended cut was that line; even deflected, they "reset" to that guard as they recover. Acceptable abstraction.

**Alternative:** On parry_deflect, don't update attacker's guard (leave it as prev, or use a "disrupted" guard). More complex. Defer.

### 3.5 Medical / Non-Weapon Actions

Medical actions don't use the weapon. No `guard_line` update. Combatant keeps current guard. ✓ Correct.

### 3.6 Skip Turn (No Functional Arm)

Combatant skips due to no functional arm. They didn't attack. No `guard_line` update. ✓ Correct.

---

## 4. Calibration: Transition Cost Scale

**Current:** `GUARD_TRANSITION_COST_SCALE = 0.4` → at alignment 0, wind-up × 1.4 (+40%).

**Physics basis:** Moving blade 90° (high→low) takes roughly 40–50% longer than no movement (same line). Meyer: "next from Plough is faster" when attack suits Plough. The 0.4 scale is reasonable.

**Tuning:** If same-line attacks feel too fast or cross-line too slow, adjust. Range 0.3–0.5 typical.

---

## 5. Integration Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Guard update on attack recovery | ✓ Done | process_recovering + GuardLineUpdater |
| Guard update on parry deflect | ✓ Done | AttackResultApplier |
| Guard update on parry partial | ✓ Done | AttackResultApplier |
| Transition cost in wind-up | ✓ Done | CombatManager._begin_attack_with_target |
| last_move_id for parry_deflect | ✓ Done | Set before clearing pending_attack |
| Alignment floor (0.15) | ✓ Exists | Avoids zero parry; lucky intercept |

**Conclusion:** Transition cost and weapon positioning are correctly integrated. Guard is updated on all weapon-use events. Wind-up applies transition cost from current guard to attack line. No further changes needed for accuracy.

---

## References

- GUARD_LINE_DYNAMICS_INVESTIGATION.md
- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md
- CombatManager.gd, CombatStateHandlers.gd, AttackResultApplier.gd
- GuardLineUpdater.gd
- CombatConstants.gd (GUARD_TRANSITION_COST_SCALE)
