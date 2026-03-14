# Part 3: Hard Bind Riposte — Implementation Investigation

## Purpose

Investigate **multiple implementation methods** for giving the defender a riposte advantage when they achieve a **hard bind** (parry_control ≥ threshold) vs a **deflect** (blades separate). HEMA: hard bind = blades in contact, defender controls = can thrust immediately; deflect = new action, full wind-up.

**Prerequisites:** Part 1 and 2 implemented. Defender has `parry_was_bind` and `parry_against_id` after parry_deflect.

---

## 1. Current State

| Data | Where | When Cleared |
|------|-------|--------------|
| `parry_was_bind` | tgt (defender) | AttackWindUpStarter.start (when defender acts) |
| `parry_against_id` | tgt | AttackWindUpStarter.start |

Defender state after parry_deflect:
- `state = WAITING`, gauge unchanged
- `guard_line` = attack line (contact point)
- Attacker: `state = RECOVERING`, gauge = 0

Implicit riposte priority: defender keeps gauge; attacker recovers from 0. Defender often reaches turn_ready first.

---

## 2. Method A: Bind Reduces Riposte Wind-Up

### Concept

When defender’s next action is an attack vs `parry_against_id` and `parry_was_bind` is true, apply a wind-up multiplier (e.g. 0.5× or 0.7×).

### Hook Point

**AttackWindUpStarter.start** — after computing `wind_up_s`, before applying `trans_mult`:

```gdscript
# After: wind_up_s *= trans_mult
# Add:
if tgt != null and tgt.get("parry_was_bind", false) and tgt.get("parry_against_id", -1) == target_id:
    wind_up_s *= CombatConstants.PARRY_BIND_RIPOSTE_WINDUP_MULT  # e.g. 0.6
```

### Files

- `AttackWindUpStarter.gd`
- `CombatConstants.gd` (new constant)

### Pros

- Mechanically clear: bind → faster riposte
- Fits HEMA “thrust from bind”
- Small code change

### Cons

- Reduces wind-up for any attack, not just thrust
- Need to pick multiplier (0.5 = half time; 0.7 = 30% reduction)
- If defender attacks someone else, no bonus (correct)

### Variant A1: Only for Thrust

Check `attack_type == ATTACK_TYPE_STAB` before applying. More HEMA-accurate (thrust from bind).

### Variant A2: Scale by parry_control

Store `parry_control` on defender; use `lerp(1.0, 0.5, (parry_control - threshold) / (1.0 - threshold))` for mult.

---

## 3. Method B: Gauge Bonus for Bind

### Concept

On parry_deflect with bind, set defender gauge to 100 (or add a fixed bonus). Defender goes turn_ready immediately; attacker still in recovery.

### Hook Point

**AttackResultApplier** (parry_deflect branch):

```gdscript
if tgt != null:
    ...
    if tgt.get("parry_was_bind", false):
        tgt.gauge = 100.0
        # Or: tgt.gauge = min(100, tgt.gauge + 50)
```

### Files

- `AttackResultApplier.gd`

### Pros

- Seamless: defender acts first
- No changes to wind-up logic
- Strongly rewards bind

### Cons

- Defender may get multiple turns in a row if attacker is slow
- Balance: bind could dominate exchanges
- Needs optional cooldown (e.g. can’t get bind bonus again for N seconds)

### Variant B1: Partial Gauge Bonus

`tgt.gauge = min(100, tgt.gauge + 40)` — softens double-turn risk.

### Variant B2: Gauge Bonus Only When Below Threshold

If `tgt.gauge >= 80`, no bonus. Prevents stacking with already-high gauge.

---

## 4. Method C: Separate “Riposte from Bind” Move

### Concept

Add `riposte_thrust` (or similar) to weapons, available only when defender has `parry_was_bind` and `parry_against_id == target_id`. Move has 0 or minimal wind-up.

### Hook Points

1. **AvailableActionsBuilder** — add riposte action when bind conditions met
2. **WeaponConstants** — add move definition with `is_riposte: true`, `wind_up_s: 0.1`
3. **AttackWindUpStarter** — treat riposte moves with reduced/minimal wind-up

### Files

- `AvailableActionsBuilder.gd`
- `WeaponConstants.gd`
- `AttackWindUpStarter.gd`
- UI (if riposte shows differently)

### Pros

- Clear distinction between normal attack and riposte
- Matches HEMA “thrust from bind” as a dedicated technique
- Tuning isolated to riposte move

### Cons

- New move, weapon config, and UI
- Must handle “no thrust weapon” (e.g. blunt-only) — fallback to cut or no riposte?
- More branching in action building

### Variant C1: Riposte Uses Existing Thrust

Don’t add a new move. When bind + target_id match + weapon has thrust, treat the chosen thrust move as having 0 wind-up. Implement via a flag in `options` passed to `resolve_action`.

---

## 5. Method D: Guard Transition Multiplier (Existing Logic + Bind)

### Concept

Guard transition cost = `1 + (1 - alignment) * GUARD_TRANSITION_COST_SCALE`. After bind, defender’s guard = attack line; thrust in same line has alignment 1 → minimal cost. The difference from deflect: after deflect, attacker’s blade is elsewhere; defender’s alignment to attacker’s guard is lower. So bind already gives better effective alignment.

**Tweak:** When bind + target match, apply extra `guard_transition_mult = 0.5` (or similar) so wind-up is halved for that transition.

### Hook Point

**AttackWindUpStarter** — when computing `trans_mult`:

```gdscript
var bind_bonus: float = 1.0
if tgt.get("parry_was_bind", false) and tgt.get("parry_against_id", -1) == target_id:
    bind_bonus = CombatConstants.PARRY_BIND_GUARD_TRANSITION_MULT  # 0.5
trans_mult = (1.0 + (1.0 - align) * CombatConstants.GUARD_TRANSITION_COST_SCALE) * bind_bonus
```

### Files

- `AttackWindUpStarter.gd`
- `CombatConstants.gd`

### Pros

- Uses existing alignment/transition model
- Small change
- Bind advantage is “you’re already in line”

### Cons

- Effect depends on alignment; if defender was already well-aligned, bonus is small
- Less obviously “riposte from bind” than Methods A/B

---

## 6. Method E: Turn Order Override

### Concept

After parry_deflect with bind, next `turn_ready` is forced to defender (if they have actions). Attacker’s turn_ready is skipped until defender acts or a timeout.

### Hook Points

1. **CombatStateHandlers** — `process_waiting` / `process_recovering` — queue or flag “defender acts next”
2. **CombatManager** / **BattleScene** — `turn_ready` handling — respect “riposte pending” before giving attacker a turn

### Files

- `CombatStateHandlers.gd`
- `CombatManager.gd` or `BattleScene.gd`
- Possibly `TurnReadyHandler.gd`

### Pros

- Guarantees defender acts first after bind
- Matches HEMA tempo strongly

### Cons

- Larger flow change
- Turn ordering logic more complex
- Need to handle “defender has no valid actions”

---

## 7. Comparison Table

| Method | Effort | HEMA Accuracy | Balance Risk | Clearest Mechanic |
|-------|--------|---------------|--------------|-------------------|
| A: Wind-up mult | Low | High | Low | Yes |
| B: Gauge bonus | Low | High | Medium | Yes |
| C: Riposte move | High | Very High | Low | Yes |
| D: Guard transition | Low | Medium | Low | Partial |
| E: Turn override | High | Very High | Medium | Yes |

---

## 8. Recommended Order

1. **Method A** — Minimal change, clear effect. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6`.
2. **Method A1** (thrust only) — If thrust-specific behavior is desired.
3. **Method B** (with variant B1) — If gauge-based advantage is preferred and double-turn is acceptable or mitigated.
4. **Method C** — If a dedicated riposte move is worth the extra complexity.

---

## 9. Implementation Checklist (Method A)

1. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6` to CombatConstants.
2. In AttackWindUpStarter.start, after `wind_up_s *= trans_mult`:
   - If `atk.get("parry_was_bind") and atk.get("parry_against_id") == target_id`: multiply wind_up_s by constant.
3. Confirm `parry_was_bind` and `parry_against_id` are set in AttackResultApplier (already done).
4. Confirm they are cleared when defender acts (already done in AttackWindUpStarter).

---

## References

- HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md (Part 3)
- HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md (riposte priority)
