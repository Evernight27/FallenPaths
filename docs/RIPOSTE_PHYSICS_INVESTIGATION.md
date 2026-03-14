# Riposte: Physics-Based Implementation Investigation

Investigation into implementing riposte (counter-attack after parry) **without abstract gamey systems**, maintaining a grounded physics basis. Contrasts with "gauge = 100" or "riposte_priority" flag approaches that feel arbitrary.

---

## 1. Physical Basis

### What Happens in Real Sword Combat

| Source | Insight |
|--------|---------|
| **Liechtenauer** | Parry with Zornhau ends in Plough; from Plough, thrust is the natural follow. The parry *is* the first half of a counter—blade is already moving. |
| **Dall'Agocchie** | "After parrying, then it's a tempo to attack." The defender has captured tempo; they are physically set to strike. |
| **HEMA 101** | Successful parry deflects the attack; defender's blade is in contact or near contact. The defender's body and blade are positioned to immediately redirect into a counter. |
| **Physics** | Blade-on-blade contact creates a bind. The defender who initiated the parry controls the line; they can thrust or cut from that position with minimal additional motion. |

### Key Physical Factors

1. **Blade position:** Parry deflect leaves defender's blade in a guard (attack line). Next action from that guard = low transition cost.
2. **Tempo:** Attacker is committed, in recovery, off-balance. Defender is not.
3. **Reaction vs. initiation:** Defender *chose* to parry (or reflexive parry succeeded). They were already planning a response or are now unopposed.
4. **No "free action":** The counter still takes time. But it starts from an advantageous position and the attacker can't defend well during recovery.

---

## 2. Abstract / Gamey Approaches (Avoid)

| Approach | Why It's Abstract | Problem |
|----------|-------------------|---------|
| **Gauge = 100** | Instantly grants "ready" status. | Ignores that the defender just acted (parried). No time cost. |
| **Riposte priority flag** | Binary "you go first" regardless of physics. | Doesn't model *why*—blade position, tempo. |
| **Free attack, no defense** | Guaranteed hit. | Unphysical: even a counter can be parried or dodged if the attacker recovers in time. |
| **Reduced gauge cost** | Arbitrary discount. | No clear physical correlate. |

---

## 3. Physics-Based Options

### Option A: Reduced Wind-Up from Guard Position (Already Implemented)

**Mechanic:** Transition cost scales wind-up. After parry_deflect, defender's `guard_line = attack_line` (blade met the attack). Parry-counter moves (parry_thrust, parry_cut) have `attack_line` that often matches. So defender's next attack has `alignment ≈ 1` → `trans_mult ≈ 1` → minimal extra wind-up.

**Physics:** Blade is already there. No angular movement needed. The "riposte" is simply the next logical action from the current weapon position.

**Implementation:** Already in place. Guard dynamics + transition cost. Defender who parried is in the right guard; parry-counter or same-line attack is fast.

**Pros:** No new systems. Pure physics.  
**Cons:** Riposte isn't explicit—it's emergent. Defender competes with others for gauge fill. No guarantee they act "next."

---

### Option B: Gauge Fill Bonus When Blade Is Ready

**Mechanic:** When defender has `parry_bonus_until` (already set on parry_deflect) and their `guard_line` matches a high-value attack line (e.g. thrust, parry_thrust), their gauge fill rate is multiplied (e.g. ×1.5) for that window.

**Physics:** Defender is "in the zone"—blade in position, mentally ready. They recover initiative faster. Not instant, but faster.

**Implementation:** In `process_waiting`, if `parry_bonus_until > now` and combatant has a weapon and guard matches preferred riposte line, `fill_rate *= 1.5`.

**Pros:** Grounded in "readiness." Still requires time (gauge fill).  
**Cons:** Extra constant (1.5). Slightly gamey.

---

### Option C: Attacker Recovery Delay (Tempo Capture)

**Mechanic:** On parry_deflect, attacker gets `off_balance_until` (already exists). During that window, attacker's gauge fill is reduced (e.g. ×0.5). Defender fills at normal rate. Net: defender reaches 100 first more often.

**Physics:** Attacker was committed, blade deflected, briefly disadvantaged. Defender was not. Attacker "loses tempo."

**Implementation:** In `process_waiting`, if `off_balance_until > now`, `fill_rate *= 0.5` for that combatant.

**Pros:** Models tempo directly. Attacker penalty, not defender bonus.  
**Cons:** We already have `off_balance_until` for parry capacity. Extending to gauge is consistent.

---

### Option D: Explicit Parry-Counter as Immediate Option (Bind State)

**Mechanic:** On parry_deflect, instead of defender going to WAITING, they enter a brief state (e.g. 0.3 s) where their only available action is a parry-counter move (parry_thrust, parry_cut). If they take it, wind-up is minimal (blade already there). If they don't, they revert to WAITING.

**Physics:** Models the "bind"—blades were in contact. From bind, historical sources describe thrust, wind, cut. The defender has a moment to choose.

**Implementation:** New state `STATE_RIPOSTE_READY` or similar. `get_available_actions` returns only parry moves when in this state. Wind-up for those moves is reduced when guard matches.

**Pros:** Explicit riposte. Historical.  
**Cons:** New state, UI for "choose riposte or not," more complexity.

---

### Option E: Combine A + C (Recommended)

**Mechanic:**
- **A (guard + transition):** Already done. Defender's guard = attack line. Parry-counter from that guard is fast.
- **C (attacker tempo penalty):** Attacker's gauge fill reduced during `off_balance_until`. Defender fills normally. Defender reaches 100 first more often without any "gauge = 100" trick.

**Implementation:** In `process_waiting`, before `c.gauge += fill_rate`:
```gdscript
if c.get("off_balance_until", -1.0) > Time.get_ticks_msec() / 1000.0:
    fill_rate *= 0.5  # Tempo penalty: recovering from parried attack
```

**Pros:** Pure physics. Attacker was committed and deflected; they're briefly disadvantaged. Defender gets to act first because they fill faster (relatively). No new states, no flags.  
**Cons:** Need to tune 0.5. May need `off_balance_until` set for parry_deflect (already done).

---

## 4. Summary

| Option | Physics | Complexity | Recommendation |
|--------|---------|------------|----------------|
| A: Guard + transition | ✓✓ Already in place | None | Use as base |
| B: Gauge fill bonus | △ Readiness | Low | Optional add-on |
| C: Attacker tempo penalty | ✓✓ Tempo capture | Low | **Implement** |
| D: Bind state | ✓✓ Explicit | High | Defer |
| E: A + C | ✓✓ Best balance | Low | **Recommend** |

**Action:** Implement Option C (attacker gauge fill penalty during off_balance). Combined with existing guard dynamics and transition cost, riposte emerges naturally: defender is in good guard, attacker is slow to recover, defender gets next action.

---

## References

- GUARD_LINE_DYNAMICS_INVESTIGATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- CombatStateHandlers.gd (process_waiting)
- CombatConstants.gd (OFF_BALANCE_DURATION_S)
