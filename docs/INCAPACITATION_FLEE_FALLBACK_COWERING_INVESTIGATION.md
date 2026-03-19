# Incapacitation: Flee, Fall Back, and Cowering

Investigation of when units can flee or fall back vs when they must cower, and how to model "too injured to move."

---

## Current Model (Codebase)

### Definitions

| Concept | Location | Logic |
|--------|----------|-------|
| `is_cowering()` | CoreEntity.gd | `get_attacking_arm().is_empty()` — no usable arms to fight |
| `is_incapacitated()` | CoreEntity.gd | `consciousness < 10` OR `is_cowering()` |
| `get_leg_functionality()` | BodyPartQuery.gd | Geometric mean of both legs; 0.08 if either destroyed |
| `get_effective_speed()` | CoreEntity.gd | `agility × leg_functionality` (for mobility) |

### State Flow

- **STATE_COWERING:** Unit has no functional arms (both severed/crushed or unusable). They can't attack or parry. They stand defensively until arms recover.
- When arm functionality returns → `process_incapacitation` sets `STATE_WAITING` and schedules `EVENT_ACTION_READY`.
- **consciousness < 10:** Unit is effectively unconscious; cannot act at all.

### What's Missing

- **Leg-based mobility:** `get_leg_functionality()` exists but is not used for incapacitation. A unit with destroyed legs but functional arms would still be "not cowering" — they can't move.
- **Flee / fall back:** These are formation actions (Phase 5). No check today for "can this unit move?" when deciding if flee/fall back is available.
- **Cowering semantics:** Currently cowering = "can't fight" (no arms). Not "can't move" (no legs). A unit with no arms but good legs is cowering in place — they *could* theoretically flee or fall back if formation actions existed.

---

## Design Question 1: Flee vs Fall Back vs Cowering

**Scenario A:** Unit has no arms (cowering) but functional legs.  
**Scenario B:** Unit has arms but no legs (cannot walk).  
**Scenario C:** Unit has low consciousness (e.g. 15) but can still stand and move.  
**Scenario D:** Unit has both arms and legs but consciousness < 10 (fully incapacitated).

### Desired Behavior

| Scenario | Can fight? | Can flee? | Can fall back? | State |
|----------|------------|----------|----------------|-------|
| A (no arms, good legs) | No | Yes | Yes | Cowering — but mobile |
| B (arms, no legs) | Yes (in place) | No | No | Not cowering; immobile |
| C (low consciousness, mobile) | Degraded | Yes (if above threshold) | Yes | Not incapacitated |
| D (consciousness < 10) | No | No | No | Incapacitated |

### Recommendation

1. **Cowering = can't fight (no arms).** Keep current definition. Cowering does *not* mean "can't move."
2. **Immovability = separate concept.** Add `can_move()` or `get_mobility_factor()` based on `get_leg_functionality()`. When legs are destroyed (0.08) or very low, unit cannot flee or fall back.
3. **Incapacitation (consciousness < 10)** = cannot act, cannot move. No flee, no fall back, no fight.
4. **Flee / fall back** (Phase 5 formation actions) require:
   - `consciousness >= INCAPACITATION_CONSCIOUSNESS_THRESHOLD`
   - `get_leg_functionality() >= MOBILITY_THRESHOLD` (e.g. 0.2 or 0.3)
   - Unit is not dead.

---

## Design Question 2: When Should Cowering Take Place?

**Current:** Cowering when `get_attacking_arm().is_empty()` — no usable arms.

**Proposed refinement:**
- **Cowering** = cannot fight (no arms). Already correct.
- **Cowering should NOT require** "too injured to move." A cowering unit *may* be mobile. If they have legs, they can flee or fall back when formation actions exist.
- **If too injured to move** (legs destroyed, consciousness < 10): unit is incapacitated or immobile. They don't "cower" — they collapse or are unable to act. Distinguish:
  - **Cowering (mobile):** No arms, can still walk. Allowed to flee/fall back.
  - **Cowering (immobile):** No arms, no legs. Cannot flee/fall back. Stays in place until healed or dies.
  - **Unconscious:** Consciousness < 10. Cannot do anything.

---

## Implementation Outline (Phase 5+)

When implementing formation actions (flee, fall back):

### 1. Mobility Check

```gdscript
# CoreEntity or helper
func can_flee_or_fall_back() -> bool:
    if consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
        return false
    var leg: float = get_leg_functionality()
    return leg >= MOBILITY_FLEE_THRESHOLD  # e.g. 0.2
```

### 2. Formation Action Availability

- **Flee:** Requires `can_flee_or_fall_back()`. Uses disengage + full retreat. Duration scales with leg functionality, armor burden, opponent pressure (see `MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md`).
- **Fall back:** Same requirement. Disengage + move to rear rank/zone.
- **Cowering units** (no arms) can flee/fall back if mobile. They are not forced to stay and die.

### 3. Constants

| Constant | Suggested | Rationale |
|----------|------------|-----------|
| `MOBILITY_FLEE_THRESHOLD` | 0.2 | Leg functionality below this = cannot walk effectively |
| `INCAPACITATION_CONSCIOUSNESS_THRESHOLD` | 10.0 | (existing) Below = unconscious |

---

## Summary

| Question | Answer |
|----------|--------|
| Can unit flee when cowering (no arms)? | **Yes**, if legs are functional. Cowering = can't fight, not can't move. |
| Can unit fall back when cowering? | **Yes**, same condition. |
| When should cowering take place? | When **no usable arms** (`get_attacking_arm().is_empty()`). Unchanged. |
| When is unit too injured to move? | When `get_leg_functionality() < MOBILITY_FLEE_THRESHOLD` or `consciousness < 10`. |
| Cowering only when too injured to move? | **No.** Cowering = no arms. Immobility is separate; use leg functionality for flee/fall back. |

---

## References

- `core/CoreEntity.gd` — `is_cowering()`, `is_incapacitated()`, `get_leg_functionality()`, `get_effective_speed()`
- `core/BodyPartQuery.gd` — `get_leg_functionality()` (both legs needed; geometric mean)
- `core/PainConsciousnessConstants.gd` — `INCAPACITATION_CONSCIOUSNESS_THRESHOLD`
- `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md` — Fall back mechanics, duration, opponent pressure
- `docs/FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md` — Phase 5: formation actions (fall back, flee)
