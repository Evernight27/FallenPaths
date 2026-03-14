# HEMA System Changes: Implementation Roadmap

## Purpose

Identify **what parts of the system need to change** to more accurately reflect HEMA/Liechtenauer fencing, and provide **multiple implementation methods** for each change. Prioritized by HEMA alignment impact.

---

## Part 1: Bind vs Deflect Decision (Contact Quality)

**Gap:** System uses geometry only. HEMA: margin, alignment, late parry, off-balance affect bind vs deflect.

**Files:** DefenseResolutionHandler, AttackResultApplier, GuardLineUpdater, CombatStateHandlers

### Method A: Parry Control Score (Deterministic)

1. Compute `parry_control` in DefenseResolutionHandler from margin, alignment, readiness, late_parry, off_balance.
2. Pass `parry_clash_context` in parry_deflect return; store on attacker; pass to `set_guard_deflected`.
3. In GuardLineUpdater: if `parry_control >= BIND_THRESHOLD` (e.g. 0.65) → bind; else → deflect (use geometry).

**Pros:** Causal, deterministic, uses existing data. **Cons:** New data flow; constants to tune.

### Method B: Simple Margin Threshold

1. Pass only `margin_ratio = c_d / (p_a * threshold)` to deflection logic.
2. If margin_ratio > 1.3 → bind (decisive). Else → deflect.

**Pros:** Minimal; one number. **Cons:** Ignores alignment, late parry, off-balance.

### Method C: Probability Weight (Softer)

1. parry_control → probability of bind. Roll: if randf() < parry_control → bind else deflect.
2. Same data flow as A but outcome is random weighted by control.

**Pros:** Smooth distribution. **Cons:** Violates HEMA causality (same conditions → different outcomes).

**Data note:** `late_parry` and `parry_off_balance` exist in `dc` (DefenseChoiceResolver result) but are **not** currently passed to `_resolve_parry`. Add them to the `resolve()` → `_resolve_parry()` call.

**Recommendation:** **Method A** for optimal HEMA. B as minimal fallback.

---

## Part 2: Deflection Magnitude (Partial vs Full)

**Gap:** Always 45° or 90°. HEMA: light clash → partial; heavy → full.

**Files:** GuardLineUpdater, CombatConstants

### Method A: guard_deflect_blend (Approach 6 from soft-deflection doc)

1. Add `guard_deflect_blend` (0–1) to combatant. Set from clash severity when deflect.
2. Resolve discrete `guard_line` from geometry + severity (e.g. severity < 0.6 → adjacent; ≥ 0.6 → opposite for opposite-defender).
3. Blend affects `get_line_alignment`: `lerp(align_at_attack, align_at_deflect, blend)` when computing effective alignment for next parry/attack.
4. Path lookup stays discrete (guard_line).

**Pros:** Partial deflection; alignment becomes continuous. **Cons:** One extra field; consumers need blend param.

### Method B: Severity → Discrete Choice Only

1. No blend. Severity thresholds: low → bind or adjacent; high → opposite (for opposite geometry).
2. Still binary per outcome, but severity shifts which of the 3 outcomes (bind/adjacent/opposite) we get.

**Pros:** No schema change. **Cons:** No partial; still snaps to 0/45/90°.

### Method C: Eight Diagonal Lines

1. Add high_left, high_right, low_left, low_right. Severity maps to one of 8 positions.
2. E.g. severity 0.2 → high_left (between bind and adjacent). Full tables for paths, angles, parts.

**Pros:** Finer discrete steps. **Cons:** 2× lines; large table expansion.

**Recommendation:** **Method A** for optimal HEMA (matches prior Approach 6). B if minimal.

---

## Part 3: Hard vs Soft Bind (Riposte Advantage)

**Gap:** Bind and deflect both give defender same treatment. HEMA: hard bind = can thrust immediately; deflect = new action, full wind-up.

**Files:** AttackWindUpStarter, CombatConstants, AvailableActionsBuilder (optional)

### Method A: Bind Reduces Riposte Wind-Up

1. After parry_deflect, store `parry_was_bind` (bool) or `bind_hardness` (0–1) on defender.
2. When defender’s next action is attack vs the same attacker who they just parried: if bind, apply wind-up multiplier (e.g. 0.5× or 0.7×).
3. Reset on defender’s next attack or after N seconds.

**Pros:** Hard bind = faster riposte. **Cons:** Need to track “just parried X”; edge cases.

### Method B: Gauge Advantage for Bind

1. On parry_deflect bind: set defender `gauge = 100` immediately (or grant +50 gauge).
2. Defender goes turn_ready sooner than attacker. Deflect: defender keeps current gauge, no bonus.

**Pros:** Simple; explicit riposte priority for bind. **Cons:** May feel strong; gauge burst.

### Method C: Separate “Riposte from Bind” Move

1. Add move_id `riposte_thrust` or similar, available only when defender just achieved bind vs target.
2. Riposte has 0 or minimal wind-up. Normal attack has full wind-up.
3. After using riposte or after timeout, fall back to normal attacks.

**Pros:** Clear mechanical distinction. **Cons:** New move; more UI/complexity.

### Method D: Wind-Up Cost from Guard Alignment (Existing + Bind Tuning)

1. Current: guard transition cost = f(alignment). After bind, defender’s guard = attack line → alignment to thrust in same line = 1 → minimal cost.
2. After deflect, defender’s guard = attack line (contact point). Attacker’s guard = deflected. So defender attacking: their alignment to attacker’s current guard could be good (they’re in line).
3. Difference: after bind, attacker’s blade is still in same line (defender can thrust straight). After deflect, attacker’s blade is elsewhere — defender’s alignment to that guard may vary.
4. Tweak: if bind, defender gets `guard_transition_mult = 0.5` for thrust in same line. If deflect, normal mult.

**Pros:** Uses existing alignment logic. **Cons:** Requires passing bind flag to wind-up.

**Recommendation:** **Method B** (gauge bonus for bind) or **Method A** (wind-up reduction). B is simplest and clearly rewards bind.

---

## Part 4: Attack Type (Thrust vs Blunt vs Cut)

**Gap:** Thrust deflects more easily; blunt deflects harder. Same logic for all.

**Files:** GuardLineUpdater, CombatConstants

### Method A: Per-Type Severity Thresholds

1. For opposite-defender 90° deflect: use `OPPOSITE_SEVERITY_THRESHOLD` by attack_type.
2. Thrust: 0.5 (easier to deflect to opposite). Cut: 0.65. Blunt: 0.8.
3. Below threshold → adjacent (45°); above → opposite (90°).

**Pros:** Matches physics. **Cons:** Need attack_type in clash context.

### Method B: Multiplier on Severity by Type

1. `effective_severity = severity * type_mult`. Thrust 1.2, blunt 0.8, cut 1.0.
2. Use effective_severity for magnitude logic.
3. Same thresholds; type shifts effective value.

**Pros:** Single threshold. **Cons:** Semantics less direct.

**Recommendation:** **Method A**.

---

## Part 5: Riposte Priority (Defender Acts First)

**Current:** Implicit — defender keeps gauge, attacker goes to recovery. Defender often fills first.
**HEMA:** Parry creates tempo to attack; defender should have initiative.

### Method A: Explicit Gauge Bonus for Defender (parry_deflect)

1. On parry_deflect: `tgt.gauge = min(100, tgt.gauge + PARRY_RIPOSTE_GAUGE_BONUS)` (e.g. +30).
2. Defender fills faster; more likely to get turn_ready before attacker finishes recovery.
3. Already have parry_bonus_until for parry_c_d; this is for gauge.

**Pros:** Simple; reinforces riposte. **Cons:** Can stack with existing implicit advantage.

### Method B: Defender Recovery = 0 (Already “Ready”)

1. On parry_deflect: defender went from possible RECOVERING or WAITING to WAITING with no recovery.
2. They don’t enter recovery; they’re immediately ready. Gauge unchanged.
3. Attacker has long recovery (full_stop). So defender already has implicit priority.
4. Option: set defender gauge = 100 if below 100, so they’re immediately turn_ready when possible.
5. Risk: double-turn (defender attacks twice before attacker can act). May need cooldown.

**Pros:** Strong riposte. **Cons:** Balance risk.

### Method C: Turn Order Override

1. After parry_deflect, next `turn_ready` is forced to defender (if they have actions).
2. Skip attacker’s turn_ready until defender has acted (or N seconds).
3. Requires turn-order queue or “riposte_pending” flag.

**Pros:** Guaranteed riposte. **Cons:** Bigger flow change.

**Recommendation:** **Method A** (modest gauge bonus) — current implicit priority is often enough; small bonus is sufficient.

---

## Part 6: Late Parry, Off-Balance, Readiness in Deflection

**Gap:** Not passed to deflection. HEMA: all reduce control → more deflect.

**Files:** DefenseResolutionHandler, AttackResultApplier

### Method A: Include in parry_clash_context (Part 1 Method A)

1. Already in parry_control: timing_factor (late), readiness_factor (off_balance).
2. Pass full context; GuardLineUpdater uses parry_control which incorporates these.

**Pros:** One implementation covers all. **Cons:** None if doing Part 1 Method A.

### Method B: Separate Modifiers

1. `deflect_bias = 1.0`. If late_parry: += 0.3. If off_balance: += 0.2. If readiness < 0.5: += 0.2.
2. Use deflect_bias to shift outcome toward deflect (e.g. lower bind threshold when bias high).

**Pros:** Transparent. **Cons:** More knobs.

**Recommendation:** **Method A** (part of parry_control).

---

## Part 7: Thrust Preferentially Deflects

**Gap:** Thrust parried → same as cut. HEMA: thrust usually deflects (point offline), rarely full stop/bind.

### Method A: Thrust Bias to Deflect in Bind/Deflect Decision

1. When attack_type == stab: `parry_control *= 0.8` (or similar) — harder to achieve bind.
2. Thrust needs higher margin/alignment to bind.
3. Most thrust parries → deflect.

**Pros:** Simple. **Cons:** One more modifier.

### Method B: Thrust Cannot Full-Stop (parry_deflect) Unless Block + Very High c_d

1. For stab, require `c_d >= p_a * 1.3` (stricter) for full_stop. Or: stab always goes parry_partial (redirect) never parry_deflect.
2. That would change DefenseResolutionHandler — stabs rarely or never full stop.

**Pros:** Strong HEMA alignment. **Cons:** Big change; stabs might always “get through” partially.

**Recommendation:** **Method A** — keep parry_deflect possible for thrust, but bias control downward so bind is rarer.

---

## Part 8: Soft vs Hard Bind for Attacker

**Gap:** Attacker in recovery doesn’t “feel” whether they’re soft or hard. HEMA: soft bind = attacker disadvantaged, can work (Wind) or leave; hard = opponent can thrust.

**Note:** We don’t track “who is hard” — both blades in same line. The defender is the one who parried, so they typically have strong-on-weak. Attacker is soft. So attacker’s recovery and next actions could reflect “I was dominated in the bind.”

### Method A: Attacker Recovery Modifier by Bind

1. If bind (guard_line == attack_line): attacker’s recovery `attack_deflect` curve could be slightly longer (blades were in contact, more “stuck”).
2. Or: bind gives attacker worse READINESS early (more stunned from firm contact).
3. Already have READINESS_BY_CAUSE["attack_deflect"]. Could split to attack_deflect_bind vs attack_deflect_deflect.
4. Bind: [0.4, 0.8] (more stunned). Deflect: [0.5, 0.85] (blade knocked away, less control shock).

**Pros:** Attacker feels bind vs deflect. **Cons:** Subtle; may need separate recovery cause.

### Method B: Defer

1. Leave attacker recovery identical for bind and deflect.
2. Focus on defender-side (riposte advantage) first.

**Recommendation:** **Method B** (defer) — defender bind advantage is higher impact. Attacker bind penalty is secondary.

---

## Summary: Implementation Order

| Priority | Part | Methods | Effort |
|----------|------|---------|--------|
| 1 | Bind vs Deflect (contact quality) | A (parry_control), B (margin only) | Medium |
| 2 | Deflection magnitude (partial) | A (blend), B (severity thresholds) | Medium |
| 3 | Hard bind riposte advantage | B (gauge), A (wind-up) | Low–Medium |
| 4 | Attack type modulation | A (thresholds) | Low |
| 5 | Late/off-balance/readiness | A (in parry_control) | Low (if doing 1A) |
| 6 | Riposte priority | A (gauge bonus) | Low |
| 7 | Thrust deflect bias | A (control modifier) | Low |
| 8 | Attacker bind penalty | Defer | — |

---

## Data Flow Summary (Method A for Parts 1–2)

```
DefenseResolutionHandler._resolve_parry (parry_deflect):
  - Compute parry_control, margin_ratio, etc.
  - return { action, target_id, recovery_duration, parry_clash_context }

AttackResultApplier (parry_deflect):
  - Store parry_clash_context on attacker (or merge with defender_guard_line_at_parry)
  - Store parry_was_bind on defender (from parry_control >= threshold) for riposte

CombatStateHandlers.process_recovering:
  - Pass parry_clash_context to set_guard_deflected
  - Erase after use

GuardLineUpdater.set_guard_deflected:
  - Accept clash_context
  - Use parry_control for bind vs deflect
  - Use severity for blend (Part 2) and magnitude (adjacent vs opposite)
  - Set guard_deflect_blend when deflect
  - Set guard_line (discrete)
```

---

## References

- HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md
- HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md
- SOFT_DEFLECTION_WEAPON_POSITION_INVESTIGATION.md
- APPROACH_5_VS_6_HEMA_COMPARISON.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
