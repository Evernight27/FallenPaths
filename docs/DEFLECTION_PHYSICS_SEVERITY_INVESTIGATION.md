# Deflection Physics and Clash Severity Investigation

## Goal

Make parry deflection positioning depend on **actual physics**—clash severity, force transfer, and angular displacement—instead of abstractly moving the blade to a fixed sector (opposite or geometry-only).

---

## Current State

### Data Available at Parry Deflect (AttackResolver)

When `parry_deflect` is returned, we only pass:
- `action`, `target_id`, `recovery_duration`

**Data computed but NOT passed downstream:**
| Variable | Meaning | Typical range |
|----------|---------|---------------|
| `parry_p_a` | Attacker momentum (m × v × curve) | ~3–15 |
| `parry_c_d` / `c_d_final` | Defender parry capacity (after variance) | ~2–20 |
| `alignment` | cos(θ) between attack and defender guard | 0.15–1.0 |
| `intensity` | Attacker commitment (0.2–1.0) | 0.2–1.0 |
| `is_block_parry` | Block (head-on) vs redirect (from side) | bool |
| `m_a_parry`, `m_d_parry` | Weapon masses (kg) | ~0.8–2.5 |
| `s_atk_parry`, `s_d_parry` | Strengths | ~50–150 |

**Current deflection logic (GuardLineUpdater):**
- Same line → bind (blade stays)
- Adjacent defender → lateral (45°)
- Opposite defender → strong block (90°)

*Clash severity is ignored.*

---

## Physics of Blade Deflection

### Angular Displacement vs Impulse

To deflect a blade through angle θ:
- **Impulse** J = ∫F dt (force × contact time)
- **Angular impulse** = τ·Δt = r⊥·F·Δt (moment arm × perpendicular force)
- Δω ∝ τ/I (change in angular velocity ∝ torque / moment of inertia)
- θ ∝ Δω·Δt ∝ (r⊥·F·Δt²)/I

**Factors that increase deflection:**
1. **Higher transferred force** — stronger clash → more impulse
2. **Better alignment** — cos(θ) ≈ 1 means force is more directly opposed; more can be transferred
3. **Longer contact** — more time for force to act (but contact is brief)
4. **Lighter attacker blade** — lower I → easier to rotate
5. **Perpendicular component** — deflection requires force *across* the path; alignment affects how much goes into deflection vs absorption

### Clash "Severity" as a Proxy for Transferred Impulse

At parry_deflect we have:
- **Decisiveness ratio:** `c_d_final / (parry_p_a * PARRY_DEFLECT_THRESHOLD)` 
  - If ratio = 1.08 → barely full stop (marginal)
  - If ratio = 1.5+ → defender had spare capacity (decisive block)
- **Interpretation:** Higher ratio → defender absorbed/redirected more decisively → more force available to deflect the blade

But wait: a *marginal* full stop (ratio ≈ 1.08) could mean:
- (A) Blade was barely stopped → minimal deflection (stays near bind)
- (B) Or: defender barely managed it → maximum effort → blade could be driven far

HEMA intuition: a clean, decisive parry (high c_d) often *holds* the blade (bind). A desperate, marginal parry might *shed* it (deflect) because the defender can't control the contact—they're just knocking it aside. So:
- **Marginal (ratio ≈ 1.0–1.2):** Less control → blade deflects more (or deflects unpredictably)
- **Decisive (ratio >> 1.2):** More control → more likely to bind or control deflection direction

Alternatively, from an *impulse* view:
- **Higher parry_p_a** (stronger attack) = more momentum to redirect → harder to deflect through large angle (needs more defender force)
- **Higher c_d** = defender had more capacity → more force available to deflect
- **Transferred impulse** ∝ min(parry_p_a, c_d) × alignment (effective contact)

### Force Required for Zone Change

With 4 discrete zones (high, low, left, right):
- **45° displacement** (adjacent): requires less impulse than 90°
- **90° displacement** (opposite): requires ~√2× more (roughly); or 2× angular work depending on model

So: **light clash** → maybe only 45° deflection (adjacent). **Heavy clash** → 90° (opposite) plausible.

---

## Implementation Approaches

### Approach 1: Severity-Scaled Deflection Magnitude

**Idea:** Use clash severity to decide *how far* the blade deflects.

**Severity metric:**
```
clash_severity = (c_d_final - parry_p_a * threshold) / max(parry_p_a * 0.2, 0.01)
```
Normalized excess capacity; >0 means how much "spare" defender had.

**Logic:**
- severity < 0.3 (marginal): blade stays near attack line → **bind** (or very slight deflect)
- 0.3 ≤ severity < 0.8: deflect to **adjacent** (45°)
- severity ≥ 0.8: deflect to **opposite** (90°)

**Pros:** Uses existing parry math; simple thresholds.
**Cons:** Severity interpretation is ambiguous (marginal vs decisive); needs tuning.

---

### Approach 2: Impulse-Based Angular Displacement

**Idea:** Model deflection angle from transferred impulse.

**Transferred impulse (arbitrary units):**
```
impulse ≈ min(parry_p_a, c_d_final) × alignment × (1 + 0.2 × is_block_parry)
```
Block parry = head-on = more force transferred.

**Thresholds (tune to taste):**
- impulse < K_bind: bind (0°)
- K_bind ≤ impulse < K_45: deflect to adjacent (45°)
- impulse ≥ K_45: deflect to opposite (90°) — or use K_90 for 90°

**Pros:** Physics-motivated; alignment and block/redirect matter.
**Cons:** Constants K_bind, K_45, K_90 need calibration; impulse scale is non-dimensional.

---

### Approach 3: Momentum Ratio + Alignment

**Idea:** Combine capacity ratio and alignment into a single "deflection strength" score.

```
deflection_strength = (c_d_final / (parry_p_a + 0.1)) × alignment
```
- High when defender had lots of capacity and good alignment.
- Low when marginal or misaligned.

**Logic:**
- strength < S_bind: bind (blade held)
- S_bind ≤ strength < S_adjacent: adjacent deflection
- strength ≥ S_adjacent: opposite deflection

**Pros:** Single composite; easy to pass and use.
**Cons:** Mixes ratio and alignment; semantics less clear than impulse.

---

### Approach 4: Mass- and Strength-Aware

**Idea:** Heavy weapons are harder to deflect through large angles.

**Resistance to deflection:**
```
resist = parry_p_a × (1 + 0.3 × (m_a - m_d) / max(m_a, 0.5))
```
Attacker heavier than defender → more resistance.

**Deflection capacity:**
```
deflect_capacity = c_d_final × alignment
```

**Effective deflection:** `deflect_capacity - resist` → if positive, can deflect; magnitude scales displacement.

**Logic:**
- deflect_capacity < resist × 0.5: bind (can't move it far)
- deflect_capacity 0.5–1.0× resist: adjacent
- deflect_capacity > resist: opposite

**Pros:** Captures mass disparity (Fiore: light blade deflects, heavy absorbs).
**Cons:** More parameters; mass ratio may already be implicit in parry_p_a.

---

### Approach 5: Probability Blend by Severity

**Idea:** Instead of deterministic outcome, use severity to weight outcomes.

**Example:**
- severity low: 60% bind, 30% adjacent, 10% opposite
- severity mid: 30% bind, 50% adjacent, 20% opposite  
- severity high: 10% bind, 40% adjacent, 50% opposite

**Pros:** Smooth variation; avoids hard thresholds.
**Cons:** Randomness may feel arbitrary; harder to tune.

---

### Approach 6: Continuous Deflection Angle (Future)

**Idea:** Move beyond 4 discrete lines; compute deflection angle θ_deflect ∈ [0, 90]°.

```
θ_deflect = f(severity, geometry)  // e.g. severity × 70° capped
```
Then snap to nearest of {0, 45, 90} or introduce "half lines" (e.g. high-left).

**Pros:** Most physically accurate; allows partial deflections.
**Cons:** Requires extending the 4-line model; more UI/design work.

---

## Data Flow Changes Required

To use any severity-based approach:

1. **AttackResolver** (parry_deflect branch): Include in return dict:
   - `parry_clash_ratio` = c_d_final / (parry_p_a * PARRY_DEFLECT_THRESHOLD)
   - `parry_alignment` = _alignment
   - `parry_intensity` = intensity (or from pa)
   - `parry_is_block` = is_block_parry
   - `parry_m_a`, `parry_m_d` (or mass ratio)
   - Or a single `parry_clash_context` dict

2. **AttackResultApplier** (parry_deflect): Store these on attacker (or in a temp dict) for recovery.

3. **CombatStateHandlers.process_recovering**: Pass `parry_clash_context` to `set_guard_deflected`.

4. **GuardLineUpdater.set_guard_deflected**: New signature:
   ```
   set_guard_deflected(c, move_id, effective_line_override, defender_guard_line, clash_context = {})
   ```
   Use clash_context to compute severity → deflection magnitude (bind vs adjacent vs opposite).

---

## Recommendation Summary

| Approach | Complexity | Physics fidelity | Tuning effort |
|----------|------------|------------------|---------------|
| 1. Severity-scaled | Low | Medium | Medium |
| 2. Impulse-based | Medium | High | High |
| 3. Momentum ratio + align | Low | Medium | Low |
| 4. Mass-aware | Medium | High | High |
| 5. Probability blend | Low | Medium | Medium |
| 6. Continuous angle | High | Highest | Highest |

**Pragmatic path:** Implement **Approach 2 (Impulse)** or **Approach 3 (Momentum ratio)** with the data flow changes. Both use values we already compute and avoid arbitrary "opposite line" jumps. Approach 2 is more physically grounded; Approach 3 is simpler to wire up.

**Key insight:** The current geometry-based model (same-line bind, adjacent lateral, opposite strong block) is sound for *direction*. Adding severity controls *magnitude*: light clash → bind or adjacent; heavy clash → adjacent or opposite. The two layers (geometry + severity) combine naturally.

---

## Additional Formula Considerations

### Other Factors to Keep in Mind

1. **Geometry defines *maximum* deflection, not guaranteed deflection**
   - Adjacent defender (45°): Force vector naturally pushes blade toward the *other* adjacent. Maximum plausible displacement from that geometry = 45°.
   - Opposite defender (90°): Head-on force can drive blade to opposite side. Max = 90°.
   - **Severity should scale *within* the geometry's max.** An adjacent parry with light clash → maybe 0–20° (bind/near). With heavy clash → full 45°. An opposite parry with light clash → maybe 0–45° (partial); heavy → full 90°.

2. **Non-linear relationship between impulse and angle**
   - Rotational work ∝ θ² for constant torque, or ∝ θ for constant angular impulse. The "cost" of going from 45°→90° is not the same as 0°→45°. You may want: light clash caps at ~45°, heavy required for 90°.

3. **Attack type modulation**
   - Thrust: easiest to redirect (point diverts with lateral force) — `PARRY_REDIRECT_THRUST_BONUS`. A thrust might deflect further for same severity.
   - Blunt: momentum-based, harder to redirect — `PARRY_REDIRECT_BLUNT_PENALTY`. May need higher severity to achieve 90°.

4. **Margin vs decisiveness (revisit)**
   - **Marginal (c_d ≈ p_a × 1.08):** Defender barely stopped it. Two interpretations:
     - (A) Minimal control → blade deflects unpredictably or stays near contact (bind).
     - (B) Maximum desperation → defender struck hard to stop it → blade driven far.
   - HEMA nuance: a *clean* parry (high margin) often *holds* (bind). A *sloppy* or *late* parry often *sheds* (deflect) because the defender can't control the contact.
   - Recommend: **higher margin → more bind, lower margin → more deflect.** Tune so marginal parries deflect more.

5. **Mass ratio**
   - Heavy attacker weapon vs light defender: defender may not have the mass to drive a 90° deflection. Consider: `max_deflection_cap *= clamp(m_d / m_a, 0.5, 1.5)` or similar.

6. **Diagonal moves**
   - `effective_attack_line` can be high/low/left/right. Diagonals (oberhau, etc.) snap to one of these. The actual angle to defender may be 22.5° or 67.5° in some cases — but with 4 discrete lines you're already approximating. No extra scaling needed unless you add finer angles.

7. **Recovery already encodes momentum**
   - `RECOVERY_EXTRA_DEFLECTED_BASE_S` + `RECOVERY_DEFLECT_MOMENTUM_SCALE_S * commitment` — deflected attacks get longer recovery. You could tie deflection *magnitude* to recovery (bigger deflect = longer recovery), but that's optional.

---

## Is 45° / 90° Appropriate? Scaling Adjustments

### Current Discrete Steps

Your model has three outcomes: **0° (bind), 45° (adjacent), 90° (opposite).**

**Physical reality:** Sword STEM / ARMA note that a full 90° displacement over ~0.3s is documented. So 90° in a single hard parry is plausible. 45° from a lateral shed is very plausible — "divert to the side" typically means tens of degrees, and 45° to the next zone is a reasonable step.

### When to Use Each Step

| Severity | Geometry | Suggested outcome | Rationale |
|----------|----------|-------------------|-----------|
| Light | Any | **Bind (0°)** | Insufficient impulse to displace blade meaningfully. |
| Medium | Adjacent | **Adjacent (45°)** | Geometry allows 45°; severity is enough. |
| Medium | Opposite | **Adjacent or bind** | 90° may need more force; cap at 45° for medium. |
| Heavy | Adjacent | **Adjacent (45°)** | Geometry max is 45°; can't exceed. |
| Heavy | Opposite | **Opposite (90°)** | Full head-on clash; enough impulse for 90°. |

### Scaling Adjustment: Geometry Caps the Max

**Key fix:** Don't let severity alone pick 90°. If defender was *adjacent*, the max deflection is 45° (to the other adjacent). So:

- **Adjacent defender:** Outcomes = bind OR adjacent. Never opposite.
- **Opposite defender:** Outcomes = bind, adjacent, OR opposite. Severity decides how far.

This matches physics: an attacker coming from high, parried by a defender in *left*, cannot be driven to *low* (90°) by that geometry — the force is from the side, not from below. The blade goes *right* (45°), not low.

### Threshold Tuning

If you use severity thresholds (e.g. Approach 1 or 3):

- **BIND_THRESHOLD:** Severity below this → bind. Try 0.2–0.4. Higher = more binds.
- **ADJACENT_THRESHOLD (when geometry allows):** Severity in [bind, adjacent] → 45°. For opposite defender, this is the "partial" band — blade gets to adjacent, not full opposite.
- **OPPOSITE_THRESHOLD (only when defender opposite):** Severity above this → 90°. Try 0.7–1.0. Requires heavy clash.

**Asymmetric thresholds:** You might want *lower* thresholds for adjacent deflect (easier to achieve 45°) and *higher* for opposite (90° is costly). Example:
- adjacent_deflect_severity_min = 0.25
- opposite_deflect_severity_min = 0.65

### Optional: Smooth Interpolation

Instead of hard thresholds, use:

```
deflection_fraction = clamp((severity - S_bind) / (S_max - S_bind), 0, 1)
```

Then: if geometry is adjacent, outcome = adjacent (we're already at the geometry max). If geometry is opposite, `deflection_fraction < 0.5 → adjacent`, `≥ 0.5 → opposite`. Tune S_bind, S_max to taste.
