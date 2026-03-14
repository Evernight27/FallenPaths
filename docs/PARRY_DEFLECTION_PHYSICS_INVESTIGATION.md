# Parry Deflection Physics Investigation

## Question

When a weapon is parried, what happens to the attacker's blade trajectory? The current system uses "deflected to the opposite line" (high→low, left→right). Is that physically accurate, and what would be best for implementation?

---

## Physics of Parrying (HEMA / Sword STEM)

### Two Fundamental Transformations

When a blade is parried, the defender's force can transform the attacker's velocity vector in two ways:

1. **Magnitude reduction (straight parry):** Stop the blade completely. Force is applied *directly against* the opponent's line of action. The blade decelerates to zero.

2. **Direction change (deflection parry):** Divert the blade to the side. Force is applied *across* the path of motion—perpendicular or at an angle—so the blade is redirected rather than stopped.

**In practice:** Most parries combine both. Pure magnitude or pure direction change requires perfect alignment, which is rare. A hanging parry "sheds the opponent's sword to the side" (direction) but still absorbs some force (magnitude).

*Source: Sword STEM, "Vector Transformations and the Wedge"*

### Thrust vs Cut

- **Thrust:** Defended almost always by *deflection*—the point is directed "offline" (to the side), not stopped. Rarely does a parry bring a thrust to a complete stop.

- **Cut:** Can be stopped (straight parry) or deflected. Liechtenauer's system: Oberhau parries Oberhau—blades meet and *bind* in the same line (Plough). The attacker's blade doesn't necessarily go to the "opposite" line; it's intercepted and held.

*Source: Sword STEM; HEMA 101, Liechtenauer Part 5*

### Deflection Direction

The direction a blade is deflected depends on:

1. **Defender's parry geometry** — Where is their blade? High, low, left, right?
2. **Contact point** — Strong vs weak of the blade (defender wants to catch attacker's weak on defender's strong).
3. **Parry type** — Straight parry (stop) vs deflection (redirect).

**Examples from sources:**

- **Thibault:** Countercuts on the top half of the opponent's blade, stepping out from the incoming sword—deflects it (often downward in the sequences).
- **HEMA 101 (sweeps):** A cut from the left can be deflected "towards our right" by cutting behind the incoming blade.
- **Liechtenauer:** Oberhau vs Oberhau → both end in Plough (same line). Unterhau vs Unterhau → both end in Ox. Same-line parries bind; the attacker's blade is *in the same line* as the parry, not necessarily "opposite."

### Is "Opposite Line" Accurate?

**Current mapping:** `DEFLECTED_GUARD_FROM_ATTACK = {high→low, low→high, left→right, right→left}`

**Assessment:**

| Attack Line | "Opposite" (current) | What sources suggest |
|-------------|---------------------|----------------------|
| High (Oberhau) | Low | **Sometimes yes:** A strong downward parry (e.g. striking down onto the blade) can drive it down. **Sometimes no:** Same-line parry (Oberhau vs Oberhau) → blades bind in Plough (high). Deflection "to the side" → left or right. |
| Low (Unterhau) | High | **Sometimes yes:** Parry from below can deflect upward. **Sometimes no:** Binds in Ox (low). |
| Left | Right | **Plausible:** Lateral deflection often goes to the other side. |
| Right | Left | **Plausible:** Same as above. |

**Conclusion:** "Opposite" is a simplification. It fits *some* parries (e.g. strong downward block on Oberhau → blade driven low) but not others (same-line bind → blade stays in same line; lateral deflection → blade goes to side, which for high/low could be left or right, not necessarily low/high).

---

## Implementation Options

### Option A: Keep "Opposite" (Current)

**Logic:** `deflected_line = opposite(attack_line)` (high↔low, left↔right).

**Pros:** Simple. One lookup. Clear outcome: parried blade ends "on the other side" of the body.

**Cons:** Doesn't match same-line binds (Liechtenauer). Doesn't capture lateral deflection for vertical attacks.

**When it fits:** Strong "blocking" parries where the defender's blade meets the attack head-on and drives it past center to the other side.

---

### Option B: Parry-Dependent (Defender's Guard)

**Logic:** `deflected_line = f(attack_line, defender_guard_line)`.

The defender's guard determines where their blade is. The deflection outcome depends on the geometry of the crossing.

**Example table (attack_line × defender_guard → deflected_line):**

| Attack \ Defender | high | low | left | right |
|-------------------|------|-----|------|-------|
| high | low (struck down) or high (bind) | high (driven up) | left/right (shed) | left/right (shed) |
| low | low (bind) | high (driven up) | left/right | left/right |
| left | left (bind) or right (shed) | left (bind) or right | right (opposite) | left (opposite) |
| right | right (bind) or left (shed) | right (bind) or left | right (opposite) | left (opposite) |

**Pros:** More physically grounded. Same-line parries (attack_line == defender_guard) can result in bind (same line) or deflection depending on implementation.

**Cons:** Larger table. More tuning. Need to decide bind vs deflect for same-line.

---

### Option C: Adjacent Deflection (Lateral Bias)

**Logic:** Deflection goes to an *adjacent* line (e.g. high→left or high→right) rather than opposite. Matches "divert to the side."

**4-line adjacency:** high↔left, high↔right, low↔left, low↔right (vertical lines connect to horizontal). "Opposite" would be high↔low, left↔right.

**Implementation:** `deflected_line = random choice of adjacent lines` or `adjacent in direction of defender's guard`.

**Pros:** Aligns with "force applied across the path" — lateral deflection.

**Cons:** May feel random. Doesn't capture downward drive (Oberhau struck down).

---

### Option D: Hybrid — Same-Line Bind vs Opposite Deflection

**Logic:**
- If `attack_line == defender_guard_line` (good alignment): **bind** → attacker's blade ends in *same* line (or very close). Defender's blade is there too.
- If `attack_line != defender_guard_line` (defender met from different angle): **deflection** → attacker's blade driven to opposite or adjacent line.

**Pros:** Captures Liechtenauer (same-line parries bind). Captures strong blocks (misaligned parry → blade knocked aside).

**Cons:** Need to pass defender_guard_line into the deflection logic. Slightly more branching.

---

## Recommendation for Your System

**Option D (Hybrid)** fits your existing structure best:

1. You already have `defender_guard_line` at parry resolution.
2. You already distinguish parry_deflect (full stop) from parry_partial (some gets through).
3. For parry_deflect, the defender's blade *met* the attack—alignment was sufficient for a clean deflect. That often implies same-line or near-same-line contact.

**Concrete implementation:**

- **When `attack_line == defender_guard_line`:** Attacker's blade ends in **same line** (bind). `deflected_line = attack_line`.
- **When `attack_line != defender_guard_line`:** Attacker's blade is **deflected** to the opposite line (current behavior). `deflected_line = DEFLECTED_GUARD_FROM_ATTACK[attack_line]`.

This requires passing `defender_guard_line` into `set_guard_deflected` (or the equivalent) and branching on alignment. The attacker already has `effective_attack_line`; the defender's `guard_line` is available in the apply_result context.

**Alternative (simpler):** Keep "opposite" as the default. It's a reasonable abstraction for "blade was knocked aside" and is easy to reason about. The physical nuance (same-line binds, lateral deflection) can be deferred if you prefer simplicity.

---

## Summary

| Concept | Physics | Implemented |
|---------|---------|-------------|
| Deflection direction | Depends on parry geometry; same (bind), adjacent (lateral shed), or opposite (strong block) | Geometry-based: `get_deflected_line_from_geometry(attack_line, defender_guard)` |
| Same-line parry | Blades bind in same line | Bind → attacker blade stays in attack line |
| Adjacent defender (45°) | Lateral shed — deflect to other adjacent | 45° angular displacement (plausible) |
| Opposite defender (90°) | Strong block drives blade through | 90° to opposite line |
| Straight parry | Stop blade (magnitude→0) | parry_deflect | ✓ |

---

## References

- Sword STEM: "Vector Transformations and the Wedge" — magnitude vs direction transformation; perpendicular force for deflection.
- HEMA 101: "Liechtenauer's longsword 101 - part 5: Parries" — Oberhau vs Oberhau ends in Plough; same-line parries.
- The Armoury: "Thibault's Advice for the Longsword, Part A: Distance and Deflection" — countercut deflects blade; never parry directly.
- ARMA: "On The Edge Of Knowledge - Parrying With A Cutting Sword" — flat parries; edge contact damages blades.
