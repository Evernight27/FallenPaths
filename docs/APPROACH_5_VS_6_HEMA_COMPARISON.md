# Approach 5 vs 6: Optimal HEMA Simulation Comparison

## Summary

For **optimal HEMA simulation**, **Approach 6 (Hybrid)** is the better choice. Approach 5 (Probabilistic) gives softer aggregate outcomes but does not model the causal link between contact quality and blade position that HEMA sources describe.

---

## HEMA Principles (Reference)

From Liechtenauer / HEMA 101:

1. **Deterministic causation:** Good parry (strong-on-weak, decisive margin) → blade held (bind). Bad parry (poor contact, marginal) → blade sheds (deflect). The outcome follows from the conditions of the clash.

2. **Continuous deflection magnitude:** Light clash → blade moves less (e.g. 20–30°). Heavy clash → full displacement (45° or 90°). Angular displacement scales with impulse.

3. **Weapon position drives follow-up:** Where the blade ends determines riposte cost, next attack alignment, and defensive readiness. A “half-deflected” blade has worse alignment for some actions than a fully deflected one.

---

## Approach 5: Probabilistic Resolve

### How It Works

- Same discrete outcomes (bind / adjacent / opposite).
- Severity **weights the probability** of each outcome.
- One roll per parry; outcome is still binary.

### HEMA Alignment

| HEMA principle | Approach 5 | Assessment |
|----------------|------------|------------|
| **Causation** | Severity influences *chance*, not *certainty* | ✗ Two identical clashes can produce different results. HEMA implies outcome follows from physics, not dice. |
| **Magnitude** | No partial deflection; always 0°, 45°, or 90° | ✗ A marginal and a decisive parry of the same geometry can both yield bind (or deflect) by chance. |
| **Follow-up** | guard_line is discrete | ⚠ No softer alignment; next parry/attack uses same alignment whether outcome was “lucky bind” or “proper bind.” |
| **Determinism** | Randomness in outcome | ✗ Historical treatises treat bind/deflect as consequence of technique, not chance. |

### Strengths for HEMA

- Over many clashes, **distribution** of binds vs deflects is softer (closer to observed HEMA mix).
- No schema changes; easy to add.

### Weaknesses for HEMA

- **Causal disconnect:** Same margin/geometry can give bind or deflect purely from RNG.
- **No partial deflection:** No “blade 40% toward adjacent” — always full snap.
- **Per-event determinism violated:** HEMA describes outcome as result of contact quality, not randomness.

---

## Approach 6: Hybrid (Blend for Alignment)

### How It Works

- Discrete `guard_line` for path/zone.
- `guard_deflect_blend` (0–1) for how far the blade moved.
- Blended alignment: `lerp(align_at_attack, align_at_deflect, blend)`.
- Blend is **derived** from margin, control, severity — no per-outcome randomness.

### HEMA Alignment

| HEMA principle | Approach 6 | Assessment |
|----------------|------------|------------|
| **Causation** | Blend = f(margin, control, geometry). Same inputs → same blend | ✓ Outcome determined by clash conditions. |
| **Magnitude** | Blend 0.3 = ~30% toward deflect line (partial). Blend 1.0 = full | ✓ Models continuous angular displacement. |
| **Follow-up** | Blended alignment affects parry capacity, wind-up, intercept | ✓ “Half-deflected” blade has worse alignment for some actions. |
| **Determinism** | Deterministic from inputs | ✓ Aligns with technique-driven outcomes. |

### Strengths for HEMA

- **Causal:** High margin + good alignment → low blend (near bind). Low margin → high blend (full deflect).
- **Partial deflection:** Blend encodes “how far” the blade moved.
- **Downstream impact:** Next parry, riposte, and attack all see the correct alignment for that blade position.
- **Can incorporate parry_control:** Blend can be driven by parry_control (margin, alignment, readiness, late parry, off-balance).

### Weaknesses for HEMA

- **Path stays discrete:** Path lookup uses cardinal guard_line, not blended position. Acceptable: intercept is driven by alignment, which is blended.
- **One extra field:** `guard_deflect_blend` (and optionally `guard_deflect_from`). Moderate implementation cost.

---

## Side-by-Side Scenarios

### Scenario: Marginal parry, same line (Oberhau vs Oberhau)

| | HEMA | Approach 5 | Approach 6 |
|---|------|------------|------------|
| **Outcome** | Soft bind or slight deflect; blade not firmly held | 70% bind, 25% adjacent, 5% opposite (example weights) | guard_line = high (bind); blend = 0.3 (loose) |
| **Next attack from low** | Blade partly out of line; worse parry alignment | If bind: full alignment. If deflect: full deflect alignment | Blended alignment ≈ 0.85 (between bind and deflect) |
| **Match** | | ✗ Random; ignores soft bind | ✓ Continuous, causal |

### Scenario: Decisive parry, opposite geometry (high attack, low block)

| | HEMA | Approach 5 | Approach 6 |
|---|------|------------|------------|
| **Outcome** | Strong block; blade driven to low | 5% bind, 35% adjacent, 60% opposite | guard_line = low; blend = 1.0 (full) |
| **Consistency** | Same conditions → same result | Can still roll bind or adjacent | Same conditions → same result |
| **Match** | | ✗ | ✓ |

### Scenario: Light clash, opposite geometry (marginal block)

| | HEMA | Approach 5 | Approach 6 |
|---|------|------------|------------|
| **Outcome** | Partial deflect; blade ~45° (adjacent), not full 90° | Roll over bind/adjacent/opposite | guard_line = left or right (adjacent); blend = 0.6 |
| **Magnitude** | Less impulse → less displacement | Binary; no partial | Blend encodes partial |
| **Match** | | ✗ | ✓ |

---

## Conclusion: Optimal HEMA Simulation

**Approach 6 is better for HEMA simulation** because it:

1. Preserves **causal links** between contact quality and blade position.
2. Models **partial deflections** via blend.
3. Makes **follow-up actions** (parry, riposte, next attack) depend on real blade position through blended alignment.
4. Lets you plug in **parry_control** (margin, alignment, readiness, late parry, off-balance) to drive blend deterministically.

**Approach 5** is useful if:
- You want **no schema changes**.
- You accept **randomness** as a stand-in for unknowns.
- You care mainly about **aggregate** bind/deflect ratios over time, not per-clash physics.

**Recommendation:** Use **Approach 6** for HEMA-focused design. If implementation cost is a concern, start with Approach 5 as a stopgap and migrate to Approach 6 when adding parry_control and clash context.
