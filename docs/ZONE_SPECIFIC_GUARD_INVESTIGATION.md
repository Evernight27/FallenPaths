# Zone-Specific Guard: Investigation of Different Approaches

Investigation into ways to implement zone-specific (directional) guard—KCD-style "block in a direction"—for Fallen Paths. Complements the existing 4-line `guard_line` system.

---

## 1. Current System vs Zone-Specific Guard

| Aspect | Current (guard_line) | Zone-specific (guard_zone) |
|--------|----------------------|----------------------------|
| **Granularity** | 4 lines: high, low, left, right (blade path) | 6 parts: head, chest, left_arm, right_arm, left_leg, right_leg |
| **Purpose** | Parry alignment, path intercept, transition cost | Which body zone defender is actively blocking |
| **Effect** | Alignment affects parry capacity, path order | Attack to guarded zone = block/parry easier; unguarded = normal |

**Key distinction:** `guard_line` = where the blade *is* (weapon position). `guard_zone` = which zone the defender *chooses to protect* (defensive intent).

---

## 2. Approach A: Guard Zone as Single Part

**Mechanic:** Each combatant has `guard_zone: String` = one of the 6 body parts.

**When attacking part P:**
- If `defender.guard_zone == P` → parry/block chance × 1.5 (or mandatory block)
- Else → normal resolution

**Pros:**
- Minimal state: one string per combatant
- Clear KCD mapping: "I'm guarding my head"
- No 3D needed: text or 2D icon

**Cons:**
- Binary: either guarding that zone or not
- Only one zone protected; attacker can always target unguarded zones

**Implementation:** Add `guard_zone` to combatant; in AttackResolver, when resolving parry, if `target_part == tgt.guard_zone` multiply parry_c_d by GUARD_ZONE_BONUS (e.g. 1.5).

---

## 3. Approach B: Guard Coverage (Multiple Zones)

**Mechanic:** `guard_zones: Array` = list of zones currently defended (e.g. `["head", "chest"]` for high guard).

**When attacking part P:**
- If P in defender.guard_zones → block/parry easier
- Else → normal

**Pros:**
- More realistic: high guard covers head + chest
- Can map guard_line → guard_zones: high → [head, left_arm, right_arm]

**Cons:**
- More state; need to define coverage per guard_line or per explicit choice
- Overlap with guard_line: guard_line already implies coverage via path

---

## 4. Approach C: Guard Line + Zone Modifier (Unify with Existing)

**Mechanic:** Keep `guard_line`. Add `guard_zone: String` as optional modifier. When attacker targets part P:
- If P == defender.guard_zone → guard applies fully (parry bonus)
- Else → guard × 0.5 (partial) or use guard_line only

**Pros:**
- Minimal change; one extra field
- Reuses guard_line for path/alignment; guard_zone refines "I'm especially protecting X"

**Cons:**
- Two overlapping concepts (line vs zone)
- Need part→line mapping to avoid contradiction (e.g. guard_zone=head but guard_line=low)

---

## 5. Approach D: Derive Guard Zone from Guard Line

**Mechanic:** No new state. Map `guard_line` → primary protected part(s):
- high → head (and arms via path)
- low → legs
- left → left_arm, left_leg
- right → right_arm, right_leg

**When attacking part P:** Check if P is in the "primary coverage" of defender's guard_line. If yes, parry bonus.

**Pros:**
- No new combatant state
- guard_line already updated on parry/attack; coverage derived automatically

**Cons:**
- Less flexible; can't "guard head while in low guard" (e.g. blade low but body positioned to block head)
- May duplicate what path intercept already does (guard_line affects path order)

---

## 6. Approach E: Guard Zone as Explicit Choice (Player/AI)

**Mechanic:** Defender *chooses* guard_zone each turn or when idle. Mental stack layer: "Enemy winding up on me" → if we know target_part (telegraph), set guard_zone = that part.

**Pros:**
- Tactical: "I see him winding up for head → I guard head"
- Telegraph integration: attacker commits target at wind-up; defender reacts

**Cons:**
- Requires telegraph (target_part known before execute) or probabilistic inference
- AI decision: when to switch guard_zone

---

## 7. Approach F: Guard Zone Modulates Parry Capacity (Not Binary)

**Mechanic:** Instead of binary block/easier, use a continuous modifier:
- `zone_match = 1.0 if target_part in coverage(guard_zone) else 0.5`
- `parry_c_d *= zone_match`

So attacking unguarded zone doesn't make parry impossible—just harder.

**Pros:**
- Softer; no "mandatory block" gamey feel
- Works with existing parry capacity math

**Cons:**
- Tuning: 0.5 vs 0.7 vs 0.3 for unguarded

---

## 8. Recommendation Matrix

| Goal | Recommended Approach |
|------|----------------------|
| Minimal KCD feel | A (single guard_zone) |
| Realistic coverage | B (guard_zones array) |
| Least code change | D (derive from guard_line) |
| Tactical depth | E (explicit choice + telegraph) |
| Soft modifier | F (continuous zone_match) |

**Suggested path:** Start with **D** (derive from guard_line)—no new state, uses existing guard_line dynamics. If playtests show "attacker always targets unguarded zone and it feels wrong," add **A** (explicit guard_zone) with Approach **F** (continuous modifier).

---

## 9. Data Structures (If Implementing A or B)

```gdscript
# Approach A
combatant["guard_zone"] = "head"  # or "chest", "left_arm", etc.

# Approach B
combatant["guard_zones"] = ["head", "chest"]  # high guard coverage

# Part-to-line mapping (for Approach D)
const GUARD_LINE_PRIMARY_COVERAGE: Dictionary = {
	"high": ["head", "left_arm", "right_arm"],
	"low": ["left_leg", "right_leg"],
	"left": ["left_arm", "left_leg"],
	"right": ["right_arm", "right_leg"]
}
```

---

## References

- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- COMBAT_ISSUES_TODO_INVESTIGATION.md §6
- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md
- CombatConstants.gd (guard_line, ATTACK_PATHS_BY_GUARD)
