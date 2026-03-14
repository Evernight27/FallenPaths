# Footwork and Positioning: Implementation Approaches

## Purpose

Investigate ways to implement footwork and positioning in the abstract combat system, and how they could affect angle, reach, and outcome.

---

## 1. Design Constraints

- **No 3D body / skeletal** — abstract representation
- **Angle-driven** — existing 4-line / continuous angle system
- **Reach** — weapons have melee_range; distance could matter
- **User said**: reach/distance shouldn't impact angle for now; possibly add later for accuracy

---

## 2. What Footwork/Positioning Could Add

| Benefit | Description |
|---------|-------------|
| **Distance** | In/out of range; step back = out of reach, step in = close |
| **Angle** | Off-line step = attacker's angle changes relative to defender |
| **Stability** | Good stance = less variance; moving = more |
| **Recovery** | Footwork affects recovery (e.g. lunging = longer recovery) |
| **Feint** | Step can sell feint (commit to one side) |

---

## 3. Abstraction Levels

### 3.1 Minimal: Distance Band Only

**Model:** Each combatant has `distance_band`: "close" | "medium" | "far"

| Band | Effect |
|------|--------|
| Close | Full damage, full parry; maybe +alignment (blades easier to control) |
| Medium | Default; current behavior |
| Far | Reduced damage (glancing), harder to parry (extended arm) |

**Transition:** Attack or dodge moves band. Parry doesn't change band.

**Effort:** Low. Add 3-state; modifier tables per band.

### 3.2 Moderate: Distance + Stance

**Model:** `distance_band` + `stance`: "balanced" | "committed" | "retreating"

| Stance | Effect |
|--------|--------|
| Balanced | Default variance, default recovery |
| Committed | Lower angle variance (committed to line), longer recovery |
| Retreating | Higher variance (moving), shorter recovery? Or faster gauge (retreat = defensive) |

**Transition:** Stance chosen at attack/dodge/parry. Or derived from last action.

**Effort:** Medium. Interacts with recovery, variance.

### 3.3 Rich: Position Vector (Abstract)

**Model:** `position_angle` (0–360) + `distance` (0–1 normalized). Defines where combatant stands relative to opponent.

- Attacker at 0° (front), defender at 180° (front to attacker) = default.
- Attacker steps to 30° = off to the side; attack angle effectively +30°.
- Distance 0.8 = closer; 0.3 = farther.

**Effect on angle:** `effective_attack_angle = attack_angle + position_offset`. Step changes perspective.

**Effort:** High. New state; angle system must add position offset.

---

## 4. Implementation Options

### Option A: Distance Band (Phase 1)

```gdscript
const DISTANCE_CLOSE: float = 0.0   # melee_range * 0.6
const DISTANCE_MEDIUM: float = 1.0 # melee_range * 1.0
const DISTANCE_FAR: float = 1.4    # melee_range * 1.4

# combatant["distance"] = 0.0–1.0 normalized
# Band: close if < 0.4, far if > 1.2, else medium
# Attack: move to close. Dodge: move to far. Parry: no change.
# Modifier: close = parry_align_mult 1.1; far = 0.9
```

**Pros:** Simple. Clear physical meaning.  
**Cons:** Doesn't change angle; only modifiers.

### Option B: Step-on-Attack (Angle Offset)

**Model:** When attacker initiates attack, they "step" toward defender. Step direction = attack_line. Adds small `position_angle_offset` that persists for 1 exchange.

- Oberhau (high): step forward, offset 0°.
- Slash (left): step left, offset +20°.
- Effect: Defender's view of attack shifts. `effective_guard_angle += position_offset` when defender resolves parry.

**Pros:** Angle system gains position.  
**Cons:** Asymmetric (attacker moves; defender static?).

### Option C: Both Step (Symmetric)

**Model:** Attacker steps on attack; defender steps on dodge or parry (small step).

- Parry: defender steps slightly to improve angle (if they have time).
- Dodge: defender steps to "far" + angle changes (duck = low, etc.).

**Pros:** Symmetric.  
**Cons:** More state; more transitions.

### Option D: Stance Affects Variance Only

**Model:** No distance. Add `stance` from last action:

- After attack: "committed" for 0.5s → variance × 0.9.
- After parry: "recovering" (existing) → variance × 1.1.
- After dodge: "mobile" → variance × 1.05.

**Pros:** Minimal. Uses existing recovery_cause.  
**Cons:** No spatial representation.

---

## 5. Reach and Distance (Deferred)

User noted: reach/distance shouldn't impact angle for now. Possibly add later.

**When to add:**
- If parry success at "far" feels wrong (extended arm = weaker parry).
- If hit damage at "close" vs "far" needs differentiation.
- If weapon range (spear vs dagger) needs clearer in/out of range.

**Angle impact:** At far distance, attacker's blade arrives at a more oblique angle to defender's guard (geometry). Could reduce alignment. Defer until distance bands exist.

---

## 6. Recommended Phasing

| Phase | Content | Effort |
|-------|---------|--------|
| **1** | Distance band (close/medium/far) on combatant. Attack→close, dodge→far. Modifiers for parry/damage. | Low |
| **2** | Stance (balanced/committed/retreating) from last action. Affects variance. | Low |
| **3** | Position angle offset: step-on-attack adds offset. Effective attack/guard angle += offset. | Medium |
| **4** | Reach vs distance: at far, reduce parry alignment; at close, increase. | Low (after Phase 1) |

---

## 7. Integration with Angle System

- **Current:** attack_angle_deg, guard_angle_deg drive alignment, deflection, path.
- **With position:** effective_attack_angle = attack_angle_deg + attacker_position_offset. effective_guard_angle = guard_angle_deg + defender_position_offset.
- **With distance:** alignment *= distance_modifier(distance_band). Only when distance bands exist.

---

## References

- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- CombatConstants: GUARD_TRANSITION_COST_SCALE
- WeaponConstants: melee_range per weapon
