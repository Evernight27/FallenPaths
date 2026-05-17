# Parry Deflect And Calibration

**Plan / code:** Deflect / calibration **investigations** only — module map is [Tier 3.2 live path](PARRY_BIND_AND_WEAPON_GEOMETRY.md#tier-32-parry-bind-live-path) (shared with [`PARRY_BIND_AND_WEAPON_GEOMETRY.md`](PARRY_BIND_AND_WEAPON_GEOMETRY.md)). **Status** → plan [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary).

Consolidated sections; each has **`Source:`** for provenance.

## Contents

1. [HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md](#hema-deflection-implementation-investigation)
2. [DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md](#deflection-physics-severity-investigation)
3. [PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md](#parry-deflection-physics-investigation)
4. [PARRY_SYSTEM_OPTIONS.md](#parry-system-options)
5. [STATE_MACHINE_PARRY_REALISM.md](#state-machine-parry-realism)
6. [PARRY_REDIRECTION_IMPROVEMENTS.md](#parry-redirection-improvements)
7. [COMBAT_PARRY_MISS_RESEARCH.md](#combat-parry-miss-research)
8. [PARRY_RATE_ANALYSIS.md](#parry-rate-analysis)

---

<a id="hema-deflection-implementation-investigation"></a>

## Source: `HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md`

# HEMA-Accurate Deflection Implementation Investigation

## Goal

Implement margin vs decisiveness, bind/deflect logic, and related factors so parry deflection matches **how HEMA engagements actually occur** — based on Liechtenauer, HEMA 101, and source analysis.

---

## HEMA Concepts: Bind vs Deflect

### From HEMA 101 (Liechtenauer Part 5 & Part 9: Binds and Winds)

**Parry outcome depends on contact quality:**

1. **Good parry (Vier Versetzen, proper parry):**
   - Same cut parries same cut: Oberhau parries Oberhau → both end in Plough. Unterhau parries Unterhau → both end in Ox.
   - Defender catches attacker's **weak** (mid-blade) on defender's **strong** (near hilt).
   - Result: **Hard bind** — Overbind, pressure on opponent's sword, defender in control.
   - Blade stays in the line of contact (same line).

2. **Bad parry:**
   - "Orange made a bad parry, and both fencers ended up with their blade **dead centre**" — neutral bind (both soft).
   - Or: defender couldn't establish control → blade **deflects** (shed) because they're just knocking it aside.
   - Result: **Soft bind** or **deflection** — no control, blade goes where physics pushes it.

3. **Blocking parries (Liechtenauer discourages):**
   - Point held high or out to the side. "Straight parry" — point offline, overbind but point not threatening.
   - Can form strong contact but geometry is less ideal than Vier Versetzen.

4. **Fencing from the sweeps (lateral deflect):**
   - Cut "behind" the incoming blade → deflect towards one side. Geometry-dependent lateral shed.

### Margin vs Decisiveness Mapping

| HEMA term | Condition | Result |
|-----------|-----------|--------|
| **Decisive parry** | Defender had plenty of capacity; good alignment; proper setup | **Hard bind** — blade controlled, stays in line |
| **Marginal parry** | Defender barely stopped it; late or poorly positioned | **Soft bind / deflect** — blade deflects, defender can't hold it |
| **Bad parry** | Blades meet poorly; dead centre or misaligned | **Deflection** — defender just knocks it aside |

**Implementation rule:** Higher margin + better conditions → **bind**. Lower margin + worse conditions → **deflect**.

---

## Available Data (What We Have)

### From DefenseChoiceResolver / DefenseResolutionHandler

| Variable | Meaning | HEMA interpretation |
|----------|---------|---------------------|
| `parry_p_a` | Attacker momentum | Attack strength |
| `parry_c_d` / `c_d_final` | Defender capacity (after variance) | How much defender could absorb |
| `_alignment` | cos(θ) attack vs guard | **Strong-on-weak proxy** — good alignment ≈ proper contact geometry |
| `parry_readiness` | Defender readiness (0–1) | Was defender "in guard" and prepared? |
| `parry_off_balance` | Defender off-balance | Poor positioning → bad parry |
| `late_parry` | Parry was reflexive (too late for full setup) | **Less time to position** → worse parry |
| `is_block_parry` | Block (mass/str) vs redirect | Block = head-on; redirect = from side. Block can be "blocking parry" (point offline) — LL discourages but can still bind |
| `parry_time_to_react` | Time defender had | More time = better setup |
| `m_a_parry`, `m_d_parry` | Weapon masses | Mass disparity affects control |
| `_attack_line`, `_guard_line` | Lines | Geometry (same-line → bind likely) |
| `pa["effective_attack_line"]` | Resolved line (diagonal) | Actual contact line |
| `intensity` | Attacker commitment | Stronger attack = harder to control |

### Not yet passed to deflection logic

- `parry_readiness`
- `parry_off_balance`
- `late_parry`
- `parry_time_to_react`
- `c_d_final` / `parry_p_a` (margin ratio)
- `_alignment`
- `is_block_parry`
- `attack_type` (thrust/cut/blunt)

---

## Proposed: Parry Control Score

A single **parry_control** score (0–1) that predicts bind vs deflect:

```
parry_control = base × margin_factor × alignment × readiness_factor × timing_factor × block_mod
```

### Components

1. **base** = 0.5 (neutral)

2. **margin_factor** = clamp(c_d_final / (parry_p_a * PARRY_DEFLECT_THRESHOLD), 0.5, 2.0)
   - Ratio 1.08 (marginal) → ~1.0
   - Ratio 1.5+ (decisive) → higher, caps at 2.0
   - **HEMA:** Decisive = more control → bind. Marginal = less control → deflect.

3. **alignment** = _alignment (already 0.15–1.0)
   - **HEMA:** Good alignment ≈ strong-on-weak contact. Misaligned = poor contact = deflect.

4. **readiness_factor** = parry_readiness × (0.7 if parry_off_balance else 1.0)
   - **HEMA:** Off-balance = bad positioning = deflect.

5. **timing_factor** = 1.0 if not late_parry else 0.6
   - **HEMA:** Late parry = reflexive, no setup = worse contact.

6. **block_mod** = 1.0 (or 0.9 if is_block_parry for "blocking parry" penalty — optional)
   - **HEMA:** Block parry can still bind; Vier Versetzen is preferred. Slight penalty or neutral.

**Final:**
```
parry_control = clamp(
  margin_factor * alignment * readiness_factor * timing_factor,
  0.0, 1.0
)
```

**Thresholds:**
- `parry_control >= BIND_THRESHOLD` (e.g. 0.65): **Bind** — blade stays in line
- `parry_control < BIND_THRESHOLD`: **Deflect** — use geometry + severity for magnitude (adjacent vs opposite)

---

## Geometry Cap (From Prior Investigation)

**Rule:** Geometry defines *maximum* deflection. Severity/control defines *whether* we achieve it.

- **Same line** (attack == defender guard): Always bind when control high. When control low, still bind (geometry forces contact in same line).
- **Adjacent defender:** Max deflection = 45° (other adjacent). Never opposite.
- **Opposite defender:** Max deflection = 90°. Control/severity decides bind vs adjacent vs opposite.

### Integrated Logic

```
if attack_line == defender_guard_line:
  # Same-line. HEMA: Oberhau vs Oberhau → Plough. Typically bind.
  return attack_line  # bind

# Different line. Control decides magnitude.
if parry_control >= BIND_THRESHOLD:
  # High control: defender "holds" the contact. Blade stays near attack line.
  # For adjacent defender, "hold" could mean slight deflect to adjacent (controlled shed).
  # For opposite, "hold" = bind in attack line (defender met it but didn't drive through).
  return attack_line  # bind (defender controlled the contact)
else:
  # Low control: deflect. Geometry limits direction; severity limits magnitude.
  if defender_guard in adjacents:
    return other_adjacent  # 45° max
  else:
    # Opposite. Severity determines: adjacent (partial) or opposite (full).
    if severity >= OPPOSITE_THRESHOLD:
      return opposite
    else:
      return adjacent  # partial deflect
```

**Refinement:** For "low control" with same line, HEMA 101 says bad parry → blades dead centre = soft bind. So blade still ends in same line, but it's a *soft* bind (both fencers can act). We don't distinguish soft vs hard bind in guard_line — both = same line. So same-line can always return attack_line.

---

## Attack Type Modulation

From PassiveParryContext / existing constants:
- **Thrust:** Easier to redirect (`PARRY_REDIRECT_THRUST_BONUS`). Point diverts with lateral force. May deflect further for same control.
- **Blunt:** Harder to redirect (`PARRY_REDIRECT_BLUNT_PENALTY`). Momentum-based. May need higher severity for 90°.

**Suggested:** When computing deflection magnitude (adjacent vs opposite for opposite-defender case):
- Thrust: lower `OPPOSITE_THRESHOLD` (e.g. 0.5) — thrust deflects more easily
- Blunt: higher `OPPOSITE_THRESHOLD` (e.g. 0.8) — blunt needs more to get 90°
- Cut: default (e.g. 0.65)

---

## Mass and Strength (Optional Layer)

HEMA/Fiore: Light weapon deflects by angle; heavy weapon absorbs.

- `m_a > m_d`: Attacker heavier. Defender may not drive 90° deflection. Cap opposite deflect when mass ratio favors attacker.
- `m_d >= m_a`: Normal.

```
mass_deflect_cap = clamp(m_d / m_a, 0.5, 1.5)
# If mass_deflect_cap < 0.8, may restrict opposite deflect
```

Can be deferred; parry_p_a and parry_c_d already encode mass through velocity and capacity.

---

## Data Flow Changes

### 1. DefenseResolutionHandler (`_resolve_parry`, parry_deflect branch)

Compute and include in return dict:

```gdscript
var margin_ratio := c_d_final / maxf(parry_p_a * CombatConstants.PARRY_DEFLECT_THRESHOLD, 0.01)
var late_parry := dc.get("late_parry", false)
var parry_readiness := parry_readiness
var parry_off_balance := dc.get("parry_off_balance", false)

# Parry control for bind vs deflect
var margin_factor := clampf(margin_ratio, 0.5, 2.0)
var readiness_factor := parry_readiness * (0.7 if parry_off_balance else 1.0)
var timing_factor := 0.6 if late_parry else 1.0
var parry_control := clampf(margin_factor * _alignment * readiness_factor * timing_factor, 0.0, 1.0)

return {
  "action": "parry_deflect",
  "target_id": target_id,
  "recovery_duration": rec_dur,
  "parry_clash_context": {
    "parry_control": parry_control,
    "margin_ratio": margin_ratio,
    "alignment": _alignment,
    "defender_guard_line": _guard_line,
    "late_parry": late_parry,
    "parry_off_balance": parry_off_balance,
    "is_block_parry": is_block_parry,
    "attack_type": attack_type,
    "effective_attack_line": pa.get("effective_attack_line", _attack_line)
  }
}
```

### 2. AttackResultApplier (parry_deflect)

Store `parry_clash_context` on attacker (in addition to `defender_guard_line_at_parry` for backwards compat). Or merge: store full context, use for both.

### 3. GuardLineUpdater.set_guard_deflected

New signature: `set_guard_deflected(c, move_id, effective_line_override, defender_guard_line, clash_context = {})`

Logic:
1. Use `defender_guard_line` and `effective_attack_line` (from clash_context or override) for geometry.
2. Use `parry_control` from clash_context. If absent, fall back to geometry-only (current behavior).
3. Apply thresholds: BIND_THRESHOLD, OPPOSITE_THRESHOLD (by attack_type).
4. Geometry cap: adjacent defender never → opposite.

### 4. CombatStateHandlers.process_recovering

Pass `c.get("parry_clash_context", {})` to `set_guard_deflected`. Erase after use.

---

## Constants to Add (CombatConstants.gd)

```gdscript
# HEMA bind vs deflect: parry_control above this → bind (blade stays).
const PARRY_BIND_CONTROL_THRESHOLD := 0.65
# For opposite-defender geometry: severity above this → 90° deflect. Below → 45°.
const PARRY_OPPOSITE_DEFLECT_SEVERITY_CUT := 0.65
const PARRY_OPPOSITE_DEFLECT_SEVERITY_THRUST := 0.5   # Thrust deflects easier
const PARRY_OPPOSITE_DEFLECT_SEVERITY_BLUNT := 0.8    # Blunt needs more
# Late parry: control penalty (less time to set up proper parry).
const PARRY_LATE_CONTROL_FACTOR := 0.6
# Off-balance: control penalty.
const PARRY_OFF_BALANCE_CONTROL_FACTOR := 0.7
```

---

## Summary: HEMA-Accurate Flow

| Factor | HEMA meaning | Implementation |
|--------|--------------|----------------|
| Margin (c_d / p_a) | Decisive vs marginal parry | margin_factor; high → bind |
| Alignment | Strong-on-weak contact | alignment; good → bind |
| Readiness | Defender in guard | readiness_factor |
| Off-balance | Poor positioning | 0.7× penalty |
| Late parry | No setup time | 0.6× penalty |
| Same-line | Oberhau vs Oberhau → Plough | Always bind |
| Adjacent defender | Lateral shed | Max 45°; never opposite |
| Opposite defender | Head-on block | Severity → 45° or 90° |
| Attack type | Thrust/Blunt differ | Thresholds by type |
| Block vs redirect | Block = point held | Optional slight penalty |

---

## References

- HEMA 101: Liechtenauer Part 5 (Parries), Part 9 (Binds and Winds)
- HEMA 101: "Orange made a bad parry, and both fencers ended up with their blade dead centre"
- HEMA 101: Oberhau parries Oberhau, end in Plough; strong-on-weak; Overbind = hard bind = control
- Sword STEM: Vector transformations (magnitude vs direction)
- Project: HEMA_VS_KCD_SOURCE_ANALYSIS.md, DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md

---

<a id="deflection-physics-severity-investigation"></a>

## Source: `DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md`

## Deflection Physics and Clash Severity Investigation

### Goal

Make parry deflection positioning depend on **actual physics**—clash severity, force transfer, and angular displacement—instead of abstractly moving the blade to a fixed sector (opposite or geometry-only).

---

### Current State

#### Data Available at Parry Deflect (AttackResolver)

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

### Physics of Blade Deflection

#### Angular Displacement vs Impulse

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

#### Clash "Severity" as a Proxy for Transferred Impulse

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

#### Force Required for Zone Change

With 4 discrete zones (high, low, left, right):
- **45° displacement** (adjacent): requires less impulse than 90°
- **90° displacement** (opposite): requires ~√2× more (roughly); or 2× angular work depending on model

So: **light clash** → maybe only 45° deflection (adjacent). **Heavy clash** → 90° (opposite) plausible.

---

### Implementation Approaches

#### Approach 1: Severity-Scaled Deflection Magnitude

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

#### Approach 2: Impulse-Based Angular Displacement

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

#### Approach 3: Momentum Ratio + Alignment

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

#### Approach 4: Mass- and Strength-Aware

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

#### Approach 5: Probability Blend by Severity

**Idea:** Instead of deterministic outcome, use severity to weight outcomes.

**Example:**
- severity low: 60% bind, 30% adjacent, 10% opposite
- severity mid: 30% bind, 50% adjacent, 20% opposite  
- severity high: 10% bind, 40% adjacent, 50% opposite

**Pros:** Smooth variation; avoids hard thresholds.
**Cons:** Randomness may feel arbitrary; harder to tune.

---

#### Approach 6: Continuous Deflection Angle (Future)

**Idea:** Move beyond 4 discrete lines; compute deflection angle θ_deflect ∈ [0, 90]°.

```
θ_deflect = f(severity, geometry)  // e.g. severity × 70° capped
```
Then snap to nearest of {0, 45, 90} or introduce "half lines" (e.g. high-left).

**Pros:** Most physically accurate; allows partial deflections.
**Cons:** Requires extending the 4-line model; more UI/design work.

---

### Data Flow Changes Required

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

### Recommendation Summary

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

### Additional Formula Considerations

#### Other Factors to Keep in Mind

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

### Is 45° / 90° Appropriate? Scaling Adjustments

#### Current Discrete Steps

Your model has three outcomes: **0° (bind), 45° (adjacent), 90° (opposite).**

**Physical reality:** Sword STEM / ARMA note that a full 90° displacement over ~0.3s is documented. So 90° in a single hard parry is plausible. 45° from a lateral shed is very plausible — "divert to the side" typically means tens of degrees, and 45° to the next zone is a reasonable step.

#### When to Use Each Step

| Severity | Geometry | Suggested outcome | Rationale |
|----------|----------|-------------------|-----------|
| Light | Any | **Bind (0°)** | Insufficient impulse to displace blade meaningfully. |
| Medium | Adjacent | **Adjacent (45°)** | Geometry allows 45°; severity is enough. |
| Medium | Opposite | **Adjacent or bind** | 90° may need more force; cap at 45° for medium. |
| Heavy | Adjacent | **Adjacent (45°)** | Geometry max is 45°; can't exceed. |
| Heavy | Opposite | **Opposite (90°)** | Full head-on clash; enough impulse for 90°. |

#### Scaling Adjustment: Geometry Caps the Max

**Key fix:** Don't let severity alone pick 90°. If defender was *adjacent*, the max deflection is 45° (to the other adjacent). So:

- **Adjacent defender:** Outcomes = bind OR adjacent. Never opposite.
- **Opposite defender:** Outcomes = bind, adjacent, OR opposite. Severity decides how far.

This matches physics: an attacker coming from high, parried by a defender in *left*, cannot be driven to *low* (90°) by that geometry — the force is from the side, not from below. The blade goes *right* (45°), not low.

#### Threshold Tuning

If you use severity thresholds (e.g. Approach 1 or 3):

- **BIND_THRESHOLD:** Severity below this → bind. Try 0.2–0.4. Higher = more binds.
- **ADJACENT_THRESHOLD (when geometry allows):** Severity in [bind, adjacent] → 45°. For opposite defender, this is the "partial" band — blade gets to adjacent, not full opposite.
- **OPPOSITE_THRESHOLD (only when defender opposite):** Severity above this → 90°. Try 0.7–1.0. Requires heavy clash.

**Asymmetric thresholds:** You might want *lower* thresholds for adjacent deflect (easier to achieve 45°) and *higher* for opposite (90° is costly). Example:
- adjacent_deflect_severity_min = 0.25
- opposite_deflect_severity_min = 0.65

#### Optional: Smooth Interpolation

Instead of hard thresholds, use:

```
deflection_fraction = clamp((severity - S_bind) / (S_max - S_bind), 0, 1)
```

Then: if geometry is adjacent, outcome = adjacent (we're already at the geometry max). If geometry is opposite, `deflection_fraction < 0.5 → adjacent`, `≥ 0.5 → opposite`. Tune S_bind, S_max to taste.

---

<a id="parry-deflection-physics-investigation"></a>

## Source: `PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md`

## Parry Deflection Physics Investigation

### Question

When a weapon is parried, what happens to the attacker's blade trajectory? The current system uses "deflected to the opposite line" (high→low, left→right). Is that physically accurate, and what would be best for implementation?

---

### Physics of Parrying (HEMA / Sword STEM)

#### Two Fundamental Transformations

When a blade is parried, the defender's force can transform the attacker's velocity vector in two ways:

1. **Magnitude reduction (straight parry):** Stop the blade completely. Force is applied *directly against* the opponent's line of action. The blade decelerates to zero.

2. **Direction change (deflection parry):** Divert the blade to the side. Force is applied *across* the path of motion—perpendicular or at an angle—so the blade is redirected rather than stopped.

**In practice:** Most parries combine both. Pure magnitude or pure direction change requires perfect alignment, which is rare. A hanging parry "sheds the opponent's sword to the side" (direction) but still absorbs some force (magnitude).

*Source: Sword STEM, "Vector Transformations and the Wedge"*

#### Thrust vs Cut

- **Thrust:** Defended almost always by *deflection*—the point is directed "offline" (to the side), not stopped. Rarely does a parry bring a thrust to a complete stop.

- **Cut:** Can be stopped (straight parry) or deflected. Liechtenauer's system: Oberhau parries Oberhau—blades meet and *bind* in the same line (Plough). The attacker's blade doesn't necessarily go to the "opposite" line; it's intercepted and held.

*Source: Sword STEM; HEMA 101, Liechtenauer Part 5*

#### Deflection Direction

The direction a blade is deflected depends on:

1. **Defender's parry geometry** — Where is their blade? High, low, left, right?
2. **Contact point** — Strong vs weak of the blade (defender wants to catch attacker's weak on defender's strong).
3. **Parry type** — Straight parry (stop) vs deflection (redirect).

**Examples from sources:**

- **Thibault:** Countercuts on the top half of the opponent's blade, stepping out from the incoming sword—deflects it (often downward in the sequences).
- **HEMA 101 (sweeps):** A cut from the left can be deflected "towards our right" by cutting behind the incoming blade.
- **Liechtenauer:** Oberhau vs Oberhau → both end in Plough (same line). Unterhau vs Unterhau → both end in Ox. Same-line parries bind; the attacker's blade is *in the same line* as the parry, not necessarily "opposite."

#### Is "Opposite Line" Accurate?

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

### Implementation Options

#### Option A: Keep "Opposite" (Current)

**Logic:** `deflected_line = opposite(attack_line)` (high↔low, left↔right).

**Pros:** Simple. One lookup. Clear outcome: parried blade ends "on the other side" of the body.

**Cons:** Doesn't match same-line binds (Liechtenauer). Doesn't capture lateral deflection for vertical attacks.

**When it fits:** Strong "blocking" parries where the defender's blade meets the attack head-on and drives it past center to the other side.

---

#### Option B: Parry-Dependent (Defender's Guard)

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

#### Option C: Adjacent Deflection (Lateral Bias)

**Logic:** Deflection goes to an *adjacent* line (e.g. high→left or high→right) rather than opposite. Matches "divert to the side."

**4-line adjacency:** high↔left, high↔right, low↔left, low↔right (vertical lines connect to horizontal). "Opposite" would be high↔low, left↔right.

**Implementation:** `deflected_line = random choice of adjacent lines` or `adjacent in direction of defender's guard`.

**Pros:** Aligns with "force applied across the path" — lateral deflection.

**Cons:** May feel random. Doesn't capture downward drive (Oberhau struck down).

---

#### Option D: Hybrid — Same-Line Bind vs Opposite Deflection

**Logic:**
- If `attack_line == defender_guard_line` (good alignment): **bind** → attacker's blade ends in *same* line (or very close). Defender's blade is there too.
- If `attack_line != defender_guard_line` (defender met from different angle): **deflection** → attacker's blade driven to opposite or adjacent line.

**Pros:** Captures Liechtenauer (same-line parries bind). Captures strong blocks (misaligned parry → blade knocked aside).

**Cons:** Need to pass defender_guard_line into the deflection logic. Slightly more branching.

---

### Recommendation for Your System

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

### Summary

| Concept | Physics | Implemented |
|---------|---------|-------------|
| Deflection direction | Depends on parry geometry; same (bind), adjacent (lateral shed), or opposite (strong block) | Angle-based: `CombatConstants.get_deflected_line_from_angles(...)` (discrete geometry helpers removed from code) |
| Same-line parry | Blades bind in same line | Bind → attacker blade stays in attack line |
| Adjacent defender (45°) | Lateral shed — deflect to other adjacent | 45° angular displacement (plausible) |
| Opposite defender (90°) | Strong block drives blade through | 90° to opposite line |
| Straight parry | Stop blade (magnitude→0) | parry_deflect | ✓ |

---

### References

- Sword STEM: "Vector Transformations and the Wedge" — magnitude vs direction transformation; perpendicular force for deflection.
- HEMA 101: "Liechtenauer's longsword 101 - part 5: Parries" — Oberhau vs Oberhau ends in Plough; same-line parries.
- The Armoury: "Thibault's Advice for the Longsword, Part A: Distance and Deflection" — countercut deflects blade; never parry directly.
- ARMA: "On The Edge Of Knowledge - Parrying With A Cutting Sword" — flat parries; edge contact damages blades.

---

<a id="parry-system-options"></a>

## Source: `PARRY_SYSTEM_OPTIONS.md`

## Parry System: Design Paradigms, Speed Options, and Tweaks

Consolidated reference for parry design options, improvement options, and balance tweaks (Goblin parry, dodge floor).

---

### Part 1: Design Paradigms (Active vs Passive)

**Current system:** Active parry — defender in STATE_WAITING chooses parry when someone winds up. Wind-up race; capacity vs momentum. Costs turn.

#### Option A: Full Passive Parry
Remove parry as action. Roll parry chance = f(perception, readiness, weapon, pain) at impact. **Pros:** Emergent, HEMA rate without constant choice. **Cons:** No "commit to defend" choice.

#### Option B: Hybrid — Active + Passive Reactive Block
Keep active parry. Add passive roll when defender did NOT choose parry (attacked, medical) — weaker effect (partial/deflect cap). **Pros:** Best of both. **Cons:** Two layers.

#### Option C: Reactive Parry (Choice Stays, Resolution Perception/State)
Parry remains option but success = perception/state roll at impact, no wind-up race. **Pros:** Perception drives success. **Cons:** Lose race tension.

#### Option D: Passive Only When Ready
Passive parry only in STATE_WAITING or early recovery; not when WIND_UP or MEDICAL_WIND_UP. **Pros:** Clear rule. **Cons:** Overlaps with active parry case.

#### Option E: Keep Active, Tune Toward "Parry Often"
Increase parry weight, shorten wind-up, boost success. No redesign. **Pros:** Easiest. **Cons:** No perception-based reaction.

**Recommendation:** **B (hybrid)** for tactical + reactive. Or **E** for minimal change.

#### Passive Implementation (A1–A6)
- **A1:** Single roll at impact, state-gated.
- **A2:** Add readiness modifier by state.
- **A3:** Opposed roll (attacker vs defender).
- **A4:** Perception gates "reactable" — notice roll, then parry.
- **A4v1–v5:** Reaction time vs wind-up variants for A4.
- **A5:** Parry = damage reduction only (no full deflect).
- **A6:** Reuse dodge formula for second roll.

---

### Part 2: Parry Speed and Improvement Options

**Current:** `c_d = m_d * v_parry * (strength/100) * perf * ...`. `v_parry` global. Attacker `p_a = m_a * v_intent`.

#### 2.1 Per-Weapon Parry Speed Factor (recommended)
Defender weapon scales parry speed. Dagger 1.2×, mace 0.85×. **Touchpoints:** WeaponConstants parry_speed_factor, Weapon.gd, CombatManager `_get_parry_speed_m_s()`.

#### 2.2 Agility Scaling
`v_parry_effective = v_parry_base * clamp(agility/100, 0.7, 1.3)`. **Pros:** One stat. **Cons:** Agility already strong.

#### 2.3 Blade Movement Time (implement existing design)
Use `PARRY_BLADE_MOVEMENT_S`, `PARRY_MOVEMENT_MASS_STRENGTH_MIN/MAX`. `effective_time_to_parry = time_to_react - blade_time`. **Pros:** Matches design. **Cons:** Heavy/weak penalized.

#### 2.4 Species Parry Speed Mult
SpeciesResource `parry_speed_mult`. Per-species tuning.

#### 2.5 Time-of-Intercept Momentum
Early parry meets less p_a — `v_intent * velocity_curve_factor(progress)`. **Pros:** Rewards fast reaction.

#### 2.6 Softer Partial Parry
Near-deflect (c_d close to p_a) → smaller residual velocity. **Pros:** Graduated feel.

#### 2.7 Relax PARRY_DODGE_STRENGTH_RATIO
Raise (e.g. 1.8) or per-species grit so weak defenders attempt parry more.

#### 2.8 Post-Deflect Bonus
Short parry capacity bonus after full deflect. **Touchpoints:** parry_bonus_until_time.

#### 2.9 Agility vs Technique Variance
Scale PARRY_TECHNIQUE_VARIANCE down for high agility.

**Recommended order:** 1.1 (per-weapon) + 2.3 (blade movement) + 2.5 (time-of-intercept).

---

### Part 3: Tweak Options (Goblin Parry, Dodge Floor)

#### 3.1 Parry: Let Goblins Parry Sometimes

**Context:** Goblins perception 80 → reaction ~0.35 s. Effective wind-up 0.36 s → edge case. Also: `p_a <= c_d * 2.2` for choice — Goblins vs 150-str party rarely choose parry.

| Option | Touchpoint | Notes |
|--------|------------|-------|
| **A: Raise perception** | goblin.tres → perception 90–95 | No code. Recommended. |
| **A2: Species parry_reaction_mult** | SpeciesResource, CoreEntity | Parry-only, &lt;1 = faster |
| **B: Lower base reaction** | CoreEntity PASSIVE_PARRY_BASE_REACTION_S | Buffs all |
| **C: Commitment window** | Decrease COMMITMENT_FRACTION | More telegraph |
| **D: Guarantee weapon** | _equip_random_equipment fallback | Robustness |

**Recommendation:** **A** (raise perception 90–95). **D** as robustness fix.

#### 3.2 Dodge: Add Small Floor

| Option | Touchpoint | Notes |
|--------|------------|-------|
| **A: Constant floor** | CoreEntity DODGE_CHANCE_FLOOR 0.01; clamp min | 1% for all |
| **B: Floor when injured** | Apply floor only when leg/perf &lt; 1 | More realistic |
| **C: Species dodge_floor** | SpeciesResource, e.g. goblin 0.02 | Per-species |

**Recommendation:** **A** (constant 1%) or **B** (injured only).

---

### Summary Table

| Area | Option | Effort |
|------|--------|--------|
| Design | B (hybrid) or E (tune active) | — |
| Speed | 2.1 Per-weapon factor | Low |
| Speed | 2.3 Blade movement time | Low |
| Other | 2.5 Time-of-intercept p_a | Low |
| Other | 2.7 Relax ratio / grit | Trivial |
| Tweak | Parry A (raise perception) | None |
| Tweak | Dodge A (floor 0.01) | Trivial |

---

<a id="state-machine-parry-realism"></a>

## Source: `STATE_MACHINE_PARRY_REALISM.md`

## State Machines and Parry: Ways to Make Combat More Realistic

Investigation of how the current combat state machine and parry interact, and different ways to use states (and new states) for more realistic behavior.

---

### 1. Current state machine (summary)

```
                    ┌─────────────────────────────────────────────────────────┐
                    │  STATE_WAITING                                           │
                    │  - Gauge fills (agility × performance)                   │
                    │  - Can act only when gauge >= 100                        │
                    │  - Actions: attack, parry (if someone winding up on me), │
                    │            medical (if ally in danger)                   │
                    └─────────────────────────────────────────────────────────┘
                       │                    │                    │
         attack        │ parry              │ medical            │
         chosen        │ chosen             │ chosen             │
                       ▼                    ▼                    ▼
    ┌──────────────┐  ┌──────────────────┐  ┌─────────────────────┐
    │ STATE_WIND_UP│  │ STATE_PARRY_      │  │ STATE_MEDICAL_       │
    │ (attack)     │  │ WIND_UP           │  │ WIND_UP              │
    │ - Timer to   │  │ - Timer to get    │  │ - Timer for bandage  │
    │   impact     │  │   blade in place  │  │   / tourniquet       │
    │ - No gauge   │  │ - No gauge fill   │  │ - No gauge fill      │
    └──────────────┘  └──────────────────┘  └─────────────────────┘
           │                     │                      │
           │ impact              │ parry ready first    │ done
           │ or parry at impact  │ or attack lands      │
           ▼                     ▼                      ▼
    ┌──────────────────────────────────────────────────────────────┐
    │  STATE_RECOVERING                                            │
    │  - Follow-through after hit/deflect/miss/parry/medical        │
    │  - Duration depends on outcome (miss longest, deflect extra) │
    │  - No gauge fill                                             │
    └──────────────────────────────────────────────────────────────┘
           │
           │ timer done
           ▼
    back to STATE_WAITING (gauge 0)
```

**Current realism-related behavior:**

- **Waiting:** Binary “can act / can’t act” (gauge 100). No notion of “guard” or “readiness.”
- **Wind-up:** Committed; no abort. Resolution is either “attack lands” or “parry race” (if defender chose parry).
- **Recovering:** Flat duration; no early/late phase. Defender can be attacked during recovery and gets **passive parry** (A4v3) if they notice in time.
- **Parry:** Active (choose parry → parry_wind_up → resolve) plus passive (reaction time vs wind-up, capacity scaled by time_to_react). Passive parry is **disabled** when defender is in WIND_UP or MEDICAL_WIND_UP; **enabled** when WAITING or RECOVERING.

---

### 2. Gaps for realism

| Gap | Why it matters |
|-----|----------------|
| **No guard / readiness** | In real fencing, “on guard” vs “blade down” changes how fast you can parry. Right now WAITING is the same whether you’re “ready” or not. |
| **Recovery is flat** | Right after a big miss or heavy hit you’re more vulnerable (off balance, slow to react). Late recovery you’re almost back to ready. State doesn’t distinguish. |
| **No commitment phase** | Once you start wind-up you’re 100% committed. Realistically there’s a short “telegraph” before full commitment. |
| **Parry only “available when attacked”** | Active parry exists only when someone is winding up on you. No “I’m in a defensive stance so I’m harder to hit even when I don’t choose parry.” |
| **No “off balance” after whiff** | Missing or being deflected could leave you more exposed for a moment; we only model longer recovery time. |
| **Gauge is only “when can I act”** | Gauge doesn’t represent posture (e.g. “I’m 80% ready to act and 50% ready to defend”). |

---

### 3. Ways to use state machines and parry for more realism

Below are concrete options. Each can be implemented alone or combined.

---

#### 3.1 Guard / readiness state (sub-state or modifier in WAITING)

**Idea:** While in `STATE_WAITING`, the combatant has a **guard level** or **readiness** that affects passive parry and possibly dodge.

- **How:** Add a field, e.g. `guard: float` (0–1) or an enum `READY_LOW / READY_HIGH / NOT_READY`. It only matters in WAITING (and maybe early RECOVERING).
- **Effect:**  
  - **Passive parry:** Multiply parry capacity or “time to react” by a function of guard (e.g. high guard → faster reaction or higher capacity).  
  - **Dodge:** Optionally same (high guard = more balanced = better dodge).  
  - **Gauge fill:** Optionally slightly slower when “high guard” (you’re prioritizing defense over stepping in to attack).
- **Realism:** Matches “blade in guard = quicker block”; “blade down” = slower to get into parry.
- **Implementation:** No new top-level state; extend the WAITING (and optionally RECOVERING) data with guard. When they choose “attack,” guard could drop or reset; when they choose “parry” or do nothing, guard could rise over time (or stay high if they didn’t attack last).

---

#### 3.2 Recovery phases (early vs late recovery)

**Idea:** Split `STATE_RECOVERING` into **early** and **late** (or use a 0–1 progress) and tie it to defense and/or interruptibility.

- **How:**  
  - Keep one `STATE_RECOVERING` but add `recovery_phase: String` ("early" / "late") or use `state_timer / state_duration` (e.g. &lt; 0.5 = early).  
  - Or add `STATE_RECOVERING_EARLY` and `STATE_RECOVERING_LATE` and transition when timer crosses a threshold.
- **Effect:**  
  - **Passive parry:** In early recovery, apply a penalty: e.g. reaction_time × 1.5, or capacity_mult × 0.6. In late recovery, no penalty (or small bonus as “getting set again”).  
  - **Optional:** Being hit in early recovery could cause “off balance” (extra recovery or worse next parry).
- **Realism:** Right after a whiff or heavy block you’re more vulnerable; as you recover posture you’re readier to parry again.
- **Implementation:** In `_execute_attack`, when resolving passive parry for a defender in RECOVERING, read their `state_timer` and `state_duration` and apply a recovery-phase modifier to reaction time or parry capacity.

---

#### 3.3 Commitment window during attack wind-up

**Idea:** The first fraction of attack wind-up is “telegraph / commitment”; after that, the attacker is fully committed and the defender’s reaction matters more.

- **How:**  
  - Store `wind_up_duration` (already done). Define `COMMITMENT_FRACTION` (e.g. 0.2). For the first 20% of wind-up, the attack could be treated as “not yet committed” (e.g. defender’s passive parry uses full wind_up_duration for time_to_react, or attacker could “abort” in some designs).  
  - Or: only after commitment fraction does the attack “count” as a real strike for the defender’s reaction (so reaction_time is compared to `wind_up_duration * (1 - COMMITMENT_FRACTION)`).
- **Effect:**  
  - Slightly more time for defender to “see it coming” (effective wind-up for reaction is shorter), or a small window where the attacker could cancel (if you add that mechanic).  
- **Realism:** Matches “telegraph” before full commitment; fast attacks are still hard to react to because total time is short.
- **Implementation:** When computing passive parry, use `effective_wind_up = wind_up_duration * (1.0 - COMMITMENT_FRACTION)` for the reaction_time comparison, or scale time_to_react by that.

---

#### 3.4 State-dependent passive parry (readiness multiplier)

**Idea:** Passive parry effectiveness depends on **current state** and optionally **recovery progress**, not only on perception and time_to_react.

- **How:** Define a **readiness multiplier** per state (and optionally per recovery phase):  
  - `STATE_WAITING`: 1.0 (or 1.0 × guard if you add guard).  
  - `STATE_RECOVERING`: 0.5 in early half, 0.85 in late half (example).  
  - `STATE_WIND_UP`, `STATE_MEDICAL_WIND_UP`: 0 (already done).  
  - `STATE_PARRY_WIND_UP`: N/A (active parry in progress).  
  Multiply parry capacity (or reaction_time, or notice chance) by this readiness.
- **Effect:** Same A4v3 formula, but “in recovery” or “early recovery” makes passive parry weaker without adding new states.
- **Realism:** You’re worse at reacting when you’re mid-swing or just finished one; better when you’re standing ready.
- **Implementation:** In the passive parry block, compute `readiness = _get_passive_parry_readiness(tgt)` and multiply `c_d` or scale `reaction_time` (e.g. reaction_time /= readiness so low readiness = slower reaction).

---

#### 3.5 “Off balance” after miss or heavy deflect

**Idea:** After a **miss** or a **full parry (deflect)**, the attacker is “off balance” for a short time: longer or worse recovery, and/or worse passive parry if they’re attacked before they recover.

- **How:**  
  - When the attacker goes to RECOVERING after a **miss** or **parry_deflect**, set a flag or timer, e.g. `off_balance_until: float` (game time) or `off_balance_duration_s: float`.  
  - While `off_balance` is true, if they are attacked, their **own** passive parry (if they’re the defender) is penalized (e.g. reaction time × 1.3, or capacity × 0.7).  
  - Or: extend their next recovery by a small amount.
- **Effect:** Whiffing or being fully parried leaves you briefly more vulnerable; encourages commitment and accuracy.
- **Realism:** Matches “recovering from a big miss” or “having your blow deflected” leaving you open.
- **Implementation:** In the place where you set `atk.state = STATE_RECOVERING` after miss or parry_deflect, set a combatant field `off_balance_until = game_time + OFF_BALANCE_DURATION`. In passive parry, when the defender has `off_balance_until > game_time`, apply a penalty to their parry.

---

#### 3.6 Defensive stance (choice that trades gauge for parry)

**Idea:** Add an explicit “defensive stance” that combatants can choose instead of attacking: gauge fills more slowly (or doesn’t fill) but passive parry (and maybe dodge) is stronger.

- **How:**  
  - New (optional) action: “assume guard” / “defensive stance.” When chosen, combatant stays in WAITING but sets a flag `defensive_stance: bool = true` and optionally a timer.  
  - While in defensive stance: gauge fill rate × 0.5 (or 0); passive parry capacity × 1.2 and/or reaction_time × 0.9.  
  - Stance ends when they choose attack/parry/medical, or after a duration, or when they’re hit.
- **Effect:** “I’m not attacking this turn, I’m getting ready to block” → better defense, slower offense.
- **Realism:** Matches prioritizing guard and watching the opponent; you’re harder to hit but you don’t press the attack.
- **Implementation:** New action in `get_available_actions` (e.g. “guard” or “defensive_stance”); in `resolve_action` set a combatant field; in gauge fill and passive parry read that field and apply modifiers.

---

#### 3.7 Parry success leaves defender in “ready” state

**Idea:** After a **successful** passive or active parry (full deflect), the defender is in a good position: treat the next moment as “ready” so their next passive parry (or dodge) is slightly better, or their gauge fills a bit faster for one tick.

- **How:** When resolving a full parry (deflect), set a short-lived flag on the defender, e.g. `parry_ready_bonus_until = game_time + 0.3`. While that’s set, their next passive parry capacity × 1.1 or reaction_time × 0.95.
- **Effect:** Successfully parrying rewards you with a brief “in the zone” window instead of only putting the attacker in recovery.
- **Realism:** A clean parry often leaves you in guard and ready for the next action; the attacker is the one off balance.
- **Implementation:** In `_resolve_parry_with_momentum` when `deflected` is true, set a field on the defender (if you have a combatant dict or node that persists); in passive parry (and optionally dodge) check that field and apply a small bonus.

---

#### 3.8 Interruptibility: abort attack early in wind-up

**Idea:** During the first X% of attack wind-up, the attacker can “abort” and go to a short recovery instead of completing the strike (e.g. they see the defender’s parry in place and don’t commit).

- **How:**  
  - Add a notion of “abort window”: e.g. first 15% of `state_duration` in STATE_WIND_UP.  
  - If the player (or AI) chooses “abort” in that window, transition to STATE_RECOVERING with a **short** recovery (e.g. 0.3 s) instead of completing the attack.  
  - No impact, no parry; attacker just recovers.
- **Effect:** Adds a tactical layer: commit or pull back. Defender might feint to force an abort.
- **Realism:** Matches “pulling a strike” when you see the block too early.
- **Implementation:** Only meaningful if the player (or AI) can issue an “abort” command during wind-up; requires UI/input and a check of `state_timer / state_duration < ABORT_FRACTION`.

---

### 4. Summary table

| Option | New state? | Complexity | Realism gain | Best combined with |
|--------|------------|------------|--------------|--------------------|
| **3.1 Guard / readiness** | No (field in WAITING) | Low | High (guard vs no guard) | 3.4 |
| **3.2 Recovery phases** | Optional (early/late) | Low–mid | High (vulnerable after action) | 3.4, 3.5 |
| **3.3 Commitment window** | No | Low | Mid (telegraph) | — |
| **3.4 State-dependent passive parry** | No | Low | High (state = readiness) | 3.1, 3.2 |
| **3.5 Off balance after miss/parry** | No (flag/timer) | Low | High (whiff/deflect cost) | 3.2 |
| **3.6 Defensive stance** | No (action + flag) | Mid | High (trade offense for defense) | 3.1 |
| **3.7 Parry success bonus** | No (flag) | Low | Mid (reward good parry) | — |
| **3.8 Abort attack** | No | Mid (needs input) | Mid (pull strike) | 3.3 |

---

### 5. Recommended order

1. **3.4 State-dependent passive parry** — Use current states (and optionally recovery progress) to scale passive parry. No new states; immediate gain (recovering = worse parry, waiting = full).
2. **3.2 Recovery phases** — Use `state_timer`/`state_duration` in RECOVERING to apply early/late modifiers to passive parry (and later to 3.5).
3. **3.5 Off balance** — After miss or parry_deflect, set a short “off balance” window and penalize the attacker’s defense if they’re hit in that window.
4. **3.1 Guard / readiness** — Add a guard level in WAITING (and optionally in late recovery) and feed it into passive parry and optionally dodge.
5. **3.6 Defensive stance** — Optional action “hold guard” that slows gauge fill and improves parry/dodge.

Implementing 3.4 and 3.2 gives a clear “state machine + parry” realism boost with minimal new machinery; the rest can be added incrementally.

---

<a id="parry-redirection-improvements"></a>

## Source: `PARRY_REDIRECTION_IMPROVEMENTS.md`

## Parry Improvements: Blade Redirection

This document investigates **different ways** redirect can be implemented and how each affects the partial parry and damage systems for realism.

---

### 1. Current System and Data Flow

#### 1.1 Parry resolve

- **Full deflect:** `c_d >= p_a` → attack negated, no damage.
- **Partial parry:** `remaining_momentum = p_a - c_d`, `v_reduced = remaining / m_a`, clamped to `v_min` (lerp 10–20% of intent by remaining_ratio).
- **Output:** `pa["velocity_m_s"] = v_reduced`; attack re-executes with this velocity.

#### 1.2 Damage pipeline

| Step | Input | Output |
|------|-------|--------|
| AttackResolver | `velocity_override` from pa | passed to compute_and_apply_damage |
| AttackInstance | `velocity_m_s = velocity_override` | KE, momentum derived from v |
| WeaponDamageHelper | `get_effective_velocity_m_s`, `compute_kinetic_energy_j` | Thrust: linear **v** from band, `KE = ½ m_strike v²`. Swing: tip **v** with ω–lever, rotational `KE` (capped **I**). Mixed: archetype `kinematic_mixed_blend`. Momentum uses **m_strike × v** (same **v** as intent). |
| pre_cut | KE | ∝ sqrt(KE) ( **`KE`** from `compute_kinetic_energy_j`, delivery-dependent) |
| pre_blunt | momentum | ∝ m·v ∝ v |
| penetration | KE, momentum | ∝ KE^0.6 (sharp), momentum/area (blunt) |

**Key:** The only parry→damage coupling is `velocity_m_s`. Reducing v reduces cut, blunt, and penetration together.

---

### 2. Implementation Points (Where Redirect Can Apply)

| Point | Location | What changes | Affects |
|-------|----------|--------------|---------|
| **A. Parry resolve (velocity)** | AttackResolver partial block | How `v_reduced` is computed | All damage (cut, blunt, pen) via v |
| **B. Damage pre-armor modifier** | compute_and_apply_damage | Multiply pre_cut/pre_blunt by modifier | Damage only; penetration unchanged |
| **C. Damage post-velocity** | WeaponDamageHelper | Adjust v or KE/momentum when from partial parry | Needs flag that v came from parry |
| **D. Contact quality (penetration)** | compute_penetration | Reduce pen for glancing (partial parry) | Penetration; tissue damage unchanged |
| **E. Cut/blunt ratio shift** | get_cut_ratio or compute | Redirected cut → more blunt, less cut | Damage type mix |

---

### 3. Implementation Options (Full Survey)

#### Option A: Redirect at velocity reduction (parry resolve)

**Where:** AttackResolver.gd, partial parry block.

**Mechanism:** Change how `remaining_momentum` and `v_reduced` are computed before writing `pa["velocity_m_s"]`.

**Sub-variants:**

| Variant | Formula | Effect on damage | Realism |
|---------|---------|------------------|---------|
| **A1. Redirect efficiency** | `effective_reduction = c_d * (1 + bonus)`; remaining = p_a - effective | Lower v → lower KE & momentum | ✓ Redirect makes capacity more effective |
| **A2. Glancing curve** | `glancing_factor = remaining_ratio^exp`; v = v_intent * glancing | Near-deflects shed more than linear | ✓ "Glances off" instead of full carry-through |
| **A3. Both** | A1 then A2 on result | Strongest reduction | ✓✓ |
| **A4. Capacity boost for deflect** | Use boosted c_d for deflect threshold too | More full deflects | ⚠ Can over-deflect; redirect is for partials |

**Pros:** Single point of control; damage system untouched; v is the physical quantity so reducing it is coherent.  
**Cons:** All redirect logic in one block.

---

#### Option B: Redirect as damage modifier (post-velocity)

**Where:** `compute_and_apply_damage` or WeaponDamageHelper, after pre_armor is computed.

**Mechanism:** When `velocity_override >= 0` (partial parry), apply `pre_armor *= (1 - redirect_reduction)`.

**Sub-variants:**

| Variant | Formula | Effect | Realism |
|---------|---------|--------|---------|
| **B1. Flat modifier** | `pre_armor *= 0.85` | 15% less damage from partials | ⚠ Abstract; doesn't reflect how much was redirected |
| **B2. Ratio-based** | `mod = 1 - k * (1 - remaining_ratio)` | More reduction when c_d was closer to p_a | ✓ Scales with parry quality |
| **B3. Separate cut/blunt** | Cut * 0.9, blunt * 0.8 | Redirect affects blunt more (glancing) | ✓ Deflected edge bites less |

**Pros:** Clean separation; can tune damage without touching parry math.  
**Cons:** Need to pass parry metadata (remaining_ratio, etc.) into damage; velocity already encodes some of that.

---

#### Option C: Redirect at penetration only

**Where:** `WeaponDamageHelper.compute_penetration` or armor application.

**Mechanism:** Redirected hits land at a worse angle → less penetration. Pass `was_partial_parry` and apply `pen_mult *= 0.7` or similar.

**Effect:** Tissue damage (pre_armor) unchanged; armor/penetration more effective at stopping the blow. Realism: deflected edge doesn't present full point/edge to target.

**Pros:** Models contact geometry; sharp damage can be "turned" so it doesn't penetrate well.  
**Cons:** Pre_armor still high; armor soaks more. May feel like "same hit, armor does more" rather than "redirected hit is weaker."

---

#### Option D: Redirect shifts cut/blunt ratio

**Where:** Before or inside `compute_pre_armor_cut/blunt`; modify cut_ratio when from partial parry.

**Mechanism:** `cut_ratio_effective = cut_ratio * (1 - redirect_blunt_shift)` → more of the hit is blunt (flat/slap), less is sharp.

**Effect:** Redirected cuts deal more blunt, less cut. Matches "flat parry" and edge not biting.

**Implementation:** Pass `parry_remaining_ratio` (or `was_partial_parry`) into `compute_and_apply_damage`. When `velocity_override >= 0`:
```
redirect_shift = PARRY_CUT_TO_BLUNT_SHIFT * (1 - remaining_ratio)  # 0 when full hit, max when near-deflect
cut_ratio_effective = max(0, cut_ratio - redirect_shift)
```
So near-deflects (low remaining_ratio) shift more cut→blunt.

**Pros:** Strong realism (deflected edge = less cutting).  
**Cons:** Requires passing parry metadata into damage path; blunt-heavy weapons get smaller shift.

---

#### Option E: Explicit absorb vs redirect split

**Where:** Parry resolve; split c_d into components.

**Mechanism:**
```
c_absorb = c_d * (1 - redirect_fraction)   # e.g. 0.5
c_redirect = c_d * redirect_fraction
effective_reduction = c_absorb + c_redirect * REDIRECT_EFFICIENCY  # e.g. 1.5
remaining = p_a - effective_reduction
```

**Effect:** Some capacity is "redirect" and counts for more when shedding momentum.

**Pros:** Explicit model of two parry modes.  
**Cons:** More constants; redirect_fraction could be stat-driven (agility) or fixed.

---

#### Option F: Probabilistic glancing

**Where:** Parry resolve or damage.

**Mechanism:** Roll `randf() < redirect_glance_chance`; if success, treat as "glancing" (e.g. 50% damage or use v_min).

**Effect:** RNG adds variance; some partials become much lighter.

**Pros:** Simple.  
**Cons:** Less physics-based; can feel arbitrary.

---

#### Option G: Two-stage residual (momentum + angle)

**Where:** Parry resolve.

**Mechanism:**
```
remaining_momentum = max(0, p_a - c_d)
angle_deflect = f(c_d/p_a)   # more capacity → better angle
effective_remaining = remaining_momentum * (1 - angle_deflect)
v_reduced = effective_remaining / m_a
```

**Effect:** Even when momentum isn't fully absorbed, deflection angle reduces what reaches the target.

**Pros:** Separates "momentum absorbed" from "angle deflected."  
**Cons:** Similar outcome to glancing curve; more complex framing.

---

### 4. How Redirect Should Affect Damage (Realism)

| Damage component | Redirect effect | Rationale |
|------------------|-----------------|-----------|
| **Velocity (KE, momentum)** | ↓ Reduced | Deflected blade carries less energy to target |
| **Cut vs blunt** | More blunt, less cut | Edge deflected → flat or slap; less clean bite |
| **Penetration** | ↓ Reduced | Poor angle → less effective point/edge |
| **Contact area** | ↑ Effective area for blunt | Glancing = broader, softer contact |

**Best realism:** Combine velocity reduction (A) + cut/blunt shift (D) + optional penetration modifier (C). Velocity alone (A) is the minimal, most coherent change.

---

### 5. Research: Redirect vs Stop

#### ARMA / Sword STEM

- **Deflection vs blocking:** "By slightly changing the direction you apply force rather than stopping the blade completely, you can drastically reduce the magnitude of force your opponent can bring to bear."
- **Cutting blades:** Prefer deflection/redirection over edge-on-edge blocking. Receiving on the **flat** deflects and dissipates force.
- **Thrusts:** Often defended by "directing the point offline"—a small lateral force can divert the attack.
- **Most parries:** Mix of magnitude reduction and direction change, not pure stop.

#### Implication

Redirecting should be **more efficient** than head-on absorption. A defender whose c_d falls short of p_a can still achieve better-than-linear reduction by deflecting the blade, so the residual should be smaller than `p_a - c_d` suggests.

---

### 3. Proposed Improvements

#### 3.1 Redirect efficiency (recommended)

**Idea:** When doing a partial parry, treat some of the defender's capacity as "redirect" rather than "absorb." Redirect is more efficient—each unit of redirect capacity sheds more momentum than a unit of straight opposition.

**Mechanic:**
```
effective_reduction = c_d * (1.0 + PARRY_REDIRECT_BONUS)
remaining_momentum = max(0, p_a - effective_reduction)
```

- `PARRY_REDIRECT_BONUS` (e.g. 0.15–0.25): partial parries get 15–25% more effective reduction.
- Full deflect check unchanged: still `c_d >= p_a`.
- Partial parries become noticeably softer when c_d is close to p_a.

**Touchpoints:** `AttackResolver.gd` lines 312–321, where `remaining_momentum` and `v_reduced` are computed.

**Pros:** Simple, one constant. Matches research. No new stats.  
**Cons:** Slightly boosts partial parry effectiveness across the board.

---

#### 3.2 Sub-linear residual ("glancing off")

**Idea:** When c_d is close to p_a (near deflect), the residual should scale sub-linearly. A blade that "almost" stops often glances off rather than delivering full remaining momentum.

**Mechanic:**
```
remaining_ratio = (p_a - c_d) / p_a   # 0 = full deflect, 1 = no parry
# Instead of v_reduced = (remaining/m_a) linearly:
# Use curved residual so near-deflects shed more
glancing_factor = sqrt(remaining_ratio)   # or remaining_ratio^1.5
effective_remaining = p_a * glancing_factor
v_reduced = effective_remaining / m_a
# Still clamp to v_min
```

- `remaining_ratio = 0.01` → `sqrt = 0.1` → 10× less residual than linear.
- `remaining_ratio = 1.0` → full residual (no parry).

**Touchpoints:** Same block in `AttackResolver.gd`.

**Pros:** "Almost deflected" hits feel much softer; matches "glancing off" behavior.  
**Cons:** Extra tuning; changes damage curve for partial parries.

---

#### 3.3 Attack-type–dependent redirect

**Idea:** Thrusts are easier to redirect (point offline); cuts can be shed on the flat. Give thrusts a higher redirect bonus.

**Mechanic:**
```
if attack_type == ATTACK_TYPE_STAB:
    redirect_mult = 1.0 + PARRY_REDIRECT_THRUST_BONUS  # e.g. 0.2
else:
    redirect_mult = 1.0 + PARRY_REDIRECT_BONUS         # e.g. 0.12
effective_reduction = c_d * redirect_mult
```

**Touchpoints:** `AttackResolver.gd`; `attack_type` is in `pa`.

**Pros:** Thrusts and cuts feel different; aligns with "point offline" for thrusts.  
**Cons:** Two constants; may need per-archetype tuning.

---

#### 3.4 Agility / perception redirect bonus

**Idea:** High agility or perception = better blade placement and angle = redirect more effective.

**Mechanic:**
```
redirect_skill = clamp((agi + perception) / 200.0, 0.5, 1.5)
redirect_mult = 1.0 + PARRY_REDIRECT_BONUS * redirect_skill
effective_reduction = c_d * redirect_mult
```

- Skilled defenders get more out of partial parries.

**Touchpoints:** `AttackResolver.gd`; use `tgt.stats.get("agility", 100)` and `tgt.stats.get("perception", 100)`.

**Pros:** Stats matter for redirect quality; rewards skilled defenders.  
**Cons:** Agility/perception already affect many things; risk of stacking.

---

#### 3.5 Combined: redirect + glancing curve

**Idea:** Apply both 3.1 and 3.2. Redirect makes c_d more effective; glancing curve makes near-deflects even softer.

**Mechanic:**
```
effective_reduction = c_d * (1.0 + PARRY_REDIRECT_BONUS)
remaining_momentum = max(0, p_a - effective_reduction)
remaining_ratio = remaining_momentum / p_a if p_a > 0 else 0
glancing_factor = sqrt(clamp(remaining_ratio, 0, 1))
v_reduced = (p_a * glancing_factor) / m_a
v_reduced = max(v_reduced, v_min_eff)  # existing clamp
```

**Pros:** Strongest realism; near-deflects and redirect both matter.  
**Cons:** More moving parts; needs careful tuning.

---

### 6. Option Comparison Summary

| Option | Point | Complexity | What changes | Realism | Notes |
|--------|-------|------------|--------------|---------|-------|
| A1. Redirect efficiency | Parry (v) | Low | v_reduced lower | ✓ | Start here; one constant |
| A2. Glancing curve | Parry (v) | Low | Near-deflects softer | ✓ | sqrt(remaining_ratio) |
| A3. Both A1+A2 | Parry (v) | Low | Strongest v reduction | ✓✓ | Best single-point change |
| B. Damage modifier | Damage | Low | pre_armor *= mod | ⚠ | Abstract; duplicates v signal |
| C. Penetration only | Penetration | Low | Pen reduced for partials | ✓ | Contact angle; pre_armor unchanged |
| D. Cut/blunt shift | Damage | Medium | More blunt, less cut | ✓✓ | Flat parry; deflected edge |
| E. Absorb/redirect split | Parry | Medium | Explicit c_d components | ✓ | More tuning |
| F. Probabilistic | Parry/damage | Trivial | RNG glancing | ⚠ | Less physical |
| G. Two-stage | Parry | Medium | Momentum + angle | ✓ | Similar to A2 |

---

### 7. Suggested Constants

Add to `CombatManager.gd` (or `AttackResolver.gd` if parry logic lives there):

```
const PARRY_REDIRECT_BONUS := 0.18      # 18% more effective reduction on partial parries
const PARRY_REDIRECT_THRUST_BONUS := 0.08   # extra 8% for thrust (if 3.3)
const PARRY_GLANCING_EXPONENT := 0.5    # sqrt for residual curve (if 3.2); 1.0 = linear
```

---

### 8. Code touchpoint (partial parry block)

Current (`AttackResolver.gd` ~306–321):

```gdscript
var remaining_momentum: float = maxf(0.0, parry_p_a - c_d_final)
var v_reduced: float = remaining_momentum / m_a
var remaining_ratio: float = (parry_p_a - c_d_final) / parry_p_a if parry_p_a > 0.0 else 1.0
var v_min_eff: float = v_intent * lerpf(manager.PARRY_V_MIN_NEAR_DEFLECT, manager.PARRY_V_MIN_FRACTION, clampf(remaining_ratio, 0.0, 1.0))
pa["velocity_m_s"] = maxf(v_reduced, v_min_eff)
```

With 3.1 (redirect) + 3.2 (glancing):

```gdscript
var redirect_mult: float = 1.0 + manager.get("PARRY_REDIRECT_BONUS", 0.18)
var effective_reduction: float = c_d_final * redirect_mult
var remaining_momentum: float = maxf(0.0, parry_p_a - effective_reduction)
var remaining_ratio: float = remaining_momentum / parry_p_a if parry_p_a > 0.0 else 0.0
var glancing_factor: float = pow(clampf(remaining_ratio, 0.0, 1.0), manager.get("PARRY_GLANCING_EXPONENT", 0.5))
var v_reduced: float = (parry_p_a * glancing_factor) / m_a
# ... v_min_eff same, pa["velocity_m_s"] = maxf(v_reduced, v_min_eff)
```

---

### 9. Balance notes

- Redirect makes partial parries more common and softer.
- May want to slightly lower base parry success (e.g. `PARRY_DEFLECT_THRESHOLD` 1.0 → 1.05) if full deflects feel too easy.
- Monitor: partial parry rate and damage from "almost deflected" hits. The glancing curve should make those hits noticeably lighter.

---

### 10. Implemented: Attack-type physics + cut-blunt shift (Mar 2025)

**Physics rationale (Sword STEM, ARMA, blunt-weapon research):**

| Attack type | Redirect difficulty | Rationale |
|-------------|---------------------|------------|
| **Stab** | Easiest | Point diverts with small lateral force; "directing the point offline" (ARMA). |
| **Cut** | Medium | Edge-on-flat deflection; when deflected, edge doesn't bite → cut→blunt shift. |
| **Blunt** | Hardest | Momentum-based; angle matters less; deflect is less effective at reducing impact. |

**Implementation:**
- `PARRY_REDIRECT_THRUST_BONUS` (+22%): thrust redirect efficiency
- `PARRY_REDIRECT_BLUNT_PENALTY` (-12%): blunt redirect efficiency
- `PARRY_CUT_TO_BLUNT_SHIFT`: deflected cuts shift cut→blunt per (1 - remaining_ratio)
- Agility boosts parry attempt: `effective_redirect = redirect_attempt * (0.75 + agility_scale * agi/100)`

---

### 11. Implemented: Penetration angle, mass disparity, desperate parry (Mar 2025)

**Penetration angle (separate from velocity):**
- Velocity reduction = momentum absorbed (magnitude) → already flows to KE, pen via v.
- Angle (deflection) = contact geometry. Oblique impact penetrates less (armor research). `pen *= lerp(1, PARRY_PENETRATION_ANGLE_MIN, 1 - remaining_ratio)`.

**Mass disparity (Fiore, HEMA):**
- Light weapons (dagger vs sword) deflect by angle/redirection; they cannot absorb. Redirect capacity bonus when m_d < m_a: `redirect_mult *= 1 + bonus * (1 - m_d/m_a)`.

**Desperate parry:**
- When `dodge_chance < PARRY_DESPERATE_DODGE_THRESHOLD` (e.g. injured legs), defender attempts parry anyway—often partial, but better than guaranteed hit from failed dodge.

---

<a id="combat-parry-miss-research"></a>

## Source: `COMBAT_PARRY_MISS_RESEARCH.md`

## Combat Parry / Miss Rates: Research vs Fallen Paths

Short summary of available research on how often melee attacks were parried or missed (healthy vs injured), and how that compares to the current system.

---

### 1. What the research actually measures

- **Historical medieval sources** do not give quantitative “parry rate” or “miss rate” statistics. Fencing manuals describe technique; casualty records give wound locations (e.g. Visby), not “how many blows were parried.”
- **HEMA** gives the only numeric data, but it measures **contact type** and **exchange outcome**, not “attack attempt → miss/parry/hit” per swing.

So we have to map **research metrics** (blade-blade vs blade-armor, clean/double/afterblow) onto your **game outcomes** (miss, parry, deflected, hit).

---

### 2. HEMA: Blade contact (parry vs hit on target)

Source: [Swords in modern fencing: hits ratio](https://artofswordmaking.com/gallery/swords-in-modern-fencing-hits-ratio) (Maciej Kopciuch, analysis of HEMA finals and tournaments).

**When a blow makes contact**, what does it hit?

| Setup | Blade–blade (parry/block) | Blade–armor / target |
|-------|---------------------------|------------------------|
| Longsword, protective suit (HEMA) | **80%** | 20% |
| Longsword, full armor | **57%** | 43% |
| Sword & buckler, protective suit | **23%** | 77% (buckler/armor) |
| Sword & buckler, full armor | **26%** | 74% |
| Sword & large shield, full armor | **22%** | 78% |

Interpretation:

- **Longsword, no shield:** most *contacts* are blade-on-blade (parry/block). Only **20–43%** of contacts are “blade on body/armor.”
- So in longsword-style fights, **parries dominate** among contacts; “clean hit on target” is the minority of contacts.
- With shield/buckler, the shield soaks most defensive contact, so blade–blade is lower.

Your game (longsword-like, no shield): research suggests that **of all contacts**, something in the **~57–80%** range being “defended” (parry or armor soak) and **~20–43%** being “meaningful hit on target” is in the right ballpark. Your **deflected** (armor absorbed most) + **parry** together are the “defended” side; **hit** is the “meaningful hit” side.

---

### 3. HEMA: Exchange outcomes (doubles, afterblows, clean)

Source: [HEMA Myth: Double Outs](https://swordstem.com/2021/11/11/hema-myth-double-outs-increase-the-rate-of-doubles/) (Sword STEM, 71 longsword events, 42,026 exchanges).

Each **exchange** is classified as:

- **Clean:** one fighter lands a scoring hit without double/afterblow.
- **Afterblow:** one lands, the other hits back within the afterblow window.
- **Double:** both hit “simultaneously” (no single winner).

Typical **double hit %** in longsword:

- Many events: **~7–12%** doubles.
- Some rule sets / cultures: **~20–40%** doubles.

So **~70–90%** of exchanges (depending on event) end with *some* kind of hit (clean or afterblow or both). That does **not** tell us “what % of individual attacks miss” — an exchange can include several attacks; we only see the final outcome. So research does **not** give a direct “miss rate per attack” for healthy fighters.

---

### 4. Injury / fatigue and performance

- **Mental fatigue (soldiers):** marksmanship *decision* errors increased **~48%** vs **~32%** in controls ([Prior Mental Fatigue Impairs Marksmanship Decision Performance](https://www.frontiersin.org/articles/10.3389/fphys.2017.00680/pdf)). So judgment/decision degrades more than raw shot accuracy in that study.
- **Acute fatigue (MMA):** reaction time and **reaction consistency** get worse ([PMC6994193](https://pmc.ncbi.nlm.nih.gov/articles/PMC6994193)).
- **Combined motor + cognitive fatigue:** worse than either alone; anticipatory reaction and military marksmanship suffer.

There is **no** direct study of “melee miss rate when wounded.” The consistent finding is: **fatigue and injury impair reaction time, consistency, and decision-making.** So it is plausible that **wounded fighters miss more and parry less effectively**; your use of a **performance modifier** (pain/consciousness) to reduce hit chance and parry effectiveness is in line with that.

---

### 5. Mapping research to your system

| Your outcome | Meaning in game | Research analogue |
|--------------|-----------------|-------------------|
| **Miss** | Attacker whiffs (no contact). | Not measured in HEMA (they count contacts and exchange winners). Plausible that it’s a small fraction when in measure; your **6% base** is reasonable for “healthy.” |
| **Dodge** | Defender avoids (no contact). | Could be part of “no clean hit” in an exchange. Your **≤8%** (DODGE_CHANCE_AT_FULL_SPEED) is modest. |
| **Parry** | Defender chooses parry; wind-up vs attack; capacity vs momentum; full deflect or partial. | **Blade–blade contact** in HEMA: **57–80%** of *contacts* for longsword. So when the defender *can* parry, parries should be common among contacts. |
| **Deflected** | Contact, but tissue damage &lt; 25% of pre-armor (armor absorbed most). | Part of **blade–armor** contacts where armor does its job (glancing / absorbed). Fits the **20–43%** “blade–armor” that aren’t full parries. |
| **Hit** | Contact, meaningful tissue damage. | The remainder of blade–armor contacts that get through. |

So in research terms:

- **Among contacts:** something like **~57–80%** “defended” (parry or armor-heavy deflected) and **~20–43%** “meaningful hit” is supported for longsword-style.
- **Before contact:** a small **miss** rate (your 6% base) and small **dodge** (≤8%) are plausible; research doesn’t give a precise number.

---

### 6. Healthy vs injured (research vs your system)

| Aspect | Research | Your system |
|--------|----------|-------------|
| **Healthy:** miss rate | No direct melee stat; HEMA suggests most exchanges end in *some* contact. | **6%** base miss, **≤8%** dodge → most attacks “reach” the target in some form. **Reasonable.** |
| **Healthy:** parry share of contacts | Longsword: **57–80%** of contacts are blade–blade. | Depends on **how often defenders choose parry** and **parry success**. If parry is only attempted sometimes, your *resolved* parries can be fewer than 57–80% of attacks; if you want to match research, parry attempts and/or success might need to be high when the defender is able. |
| **Injured:** miss / inaccuracy | Fatigue/injury impairs reaction and consistency; no melee miss %. | **get_hit_chance_performance_modifier()** (head pain) reduces effective hit chance; wounded fighters miss more. **Consistent with research.** |
| **Injured:** parry effectiveness | No direct parry data; reaction/consistency drop. | Parry capacity scaled by **performance modifier** (pain/consciousness). **Consistent.** |

So: **healthy** numbers (low miss, modest dodge) and **injured** handling (performance modifier on hit chance and parry) both align with the limited research. The main lever to “match” HEMA is **how often parries are attempted and succeed** relative to total attacks.

---

### 7. Summary comparison

- **Miss (healthy):** Research doesn’t give a number; your **6%** base is a plausible, low “whiff” rate.
- **Dodge:** Your **≤8%** is modest and plausible.
- **Parry vs hit (among contacts):** Research suggests **~57–80%** of longsword contacts are blade–blade (parry). Your **parry** + **deflected** together represent “defended”; **hit** is “meaningful hit.” Tuning parry **choice weight** and **success** (capacity vs momentum, wind-up timing) will determine whether your “defended” fraction is in that band.
- **Injured:** Research supports **worse accuracy and reaction** when fatigued/injured; your **performance modifier** on hit chance and parry is in line with that.

If you want to push closer to the HEMA band: ensure parry is attempted often when an attack is incoming (e.g. high parry choice weight when available) and that successful parries (full deflect) are a large share of those attempts when the defender is healthy and in time.

---

### 8. Dodge / void in HEMA and historical fencing (realism tuning)

#### What the research says

**Historical sources:** Void (body displacement to avoid an attack) is a valid technique in Meyer, Capo Ferro, and other manuals. Terminology: retreat, girata (turn), inquartata, passes beneath. No manual gives numeric success rates.

**ARMA (parrying essay):** "Voiding, deflecting and flat-of-the-blade parries are always preferable to direct blocking" and "movement and counter-action to void or displace or deflect attacks is superior to direct opposition parrying." They *demonstrate* evasion first to teach that defense is achieved more by effective movement than by meeting blows—but this is pedagogy, not a claim about frequency.

**A Fencer's Ramblings:** Voids require *perfect* timing. Move too early → opponent adjusts and still hits. Move too late → you get hit. "The fencer must wait for the attack to come and only move at the last minute." Evasion is technically demanding and easy to mis-time.

**HEMA contact data (Kopciuch):** Longsword: 57–80% of *contacts* are blade-blade (parry); 20–43% blade–armor/body. This counts *contacts only*. A complete void (no contact) does *not* appear in those stats—we don't know what fraction of attacks never make contact because of evasion.

**Conclusion:** No source gives a quantitative "dodge/void success rate." Parry/blade contact dominates among contacts (57–80%). Void is attested as valid but hard (timing-sensitive). Realism supports a *modest* dodge base—less than parry—rather than making evasion competitive with or superior to parry.

#### Tuning for realism

| Constant | Current | Realism range | Notes |
|----------|---------|---------------|-------|
| DODGE_CHANCE_AT_FULL_SPEED | **0.10** | Implemented | Modest void base per HEMA research. |
| PARRY_PREFER_DODGE_FULL_THRESHOLD | **0.12** | Implemented | "Clean dodge likely" for high-agility defenders. |

**Implemented:** DODGE_CHANCE_AT_FULL_SPEED 0.10, PARRY_PREFER_DODGE_FULL_THRESHOLD 0.12. Partial dodge tiers and expected-damage logic retained.

**Partial parry follow-through:** Defender twisted with the parry attempt; body movement can slip the remainder. `PARRY_FOLLOW_THROUGH_DODGE_EFFICIENCY` (0.5) gives a reduced dodge roll on follow-through. Success = full dodge; failure = damage with parry-reduced velocity. See COMBAT_SYSTEM_ISSUES §3.

---

### 9. Flat-of-blade vs edge parry: is it modeled?

**HEMA / ARMA principle:** Parries with cutting swords are made with the **flat** ("mit der flech"), not the edge. Edge-on-edge contact damages the blade (nicks, gouges) and risks fracture. Receiving on the flat deflects and dissipates force; the attacker's edge doesn't bite.

#### What the game models

| Effect | Implementation | Location |
|--------|-----------------|----------|
| **Cut→blunt shift** | When a cut is partially parried (`parry_remaining_ratio < 1`), `redirect_shift = PARRY_CUT_TO_BLUNT_SHIFT * (1 - remaining_ratio)` reduces `cut_ratio` before damage. Deflected edge presents flat/slap; less sharp bite. | AttackResolver.gd:48–52, PARRY_CUT_TO_BLUNT_SHIFT 0.45 |
| **Oblique penetration** | `pen_sharp` and `pen_blunt` scaled by angle factor `lerp(1, PARRY_PENETRATION_ANGLE_MIN, 1 - remaining_ratio)`. Oblique impact penetrates less. | AttackResolver.gd:65–71 |
| **Velocity reduction** | `parry_remaining_ratio` drives impact velocity (and KE) on follow-through. Partial parry = less energy delivered. | Parry resolution → damage path |

#### What is not modeled

- **Defender blade orientation:** The game does not explicitly track "defender used flat" vs "defender used edge." The *outcome* (reduced cut, more blunt, worse angle) is modeled without that state.
- **Defender weapon durability:** Edge-on-edge parries would damage the defender's blade. No weapon wear/edge damage system exists.

#### Verdict

**The flat-of-blade effect is replicated through outcome, not mechanism.** Deflected cuts already deal more blunt and less cut, with reduced penetration—matching "receive on flat → attacker's edge doesn't bite." Adding explicit flat-vs-edge state would add complexity for little gain: the damage pipeline already encodes the correct result. Modeling defender blade wear from edge parries would require a durability system; impact on defender body damage is negligible (the body-damage outcome is already correct).

---

<a id="parry-rate-analysis"></a>

## Source: `PARRY_RATE_ANALYSIS.md`

## Parry Rate Analysis: % Parried and Unparriable Attacks

This document investigates parry outcomes for general attacks: what fraction gets parried (full deflect), and how many attacks are effectively unparriable at 100% functionality vs after 1–2 wounds.

---

### 1. Key Formulas (from codebase)

#### 1.1 Attack wind-up and effective window

```
wind_up_duration = (WIND_UP_BASE_S + WIND_UP_SCALE_S * intensity) * windup_mult / leg / perf_mod / agility_factor
```
- `WIND_UP_BASE_S = 0.25`, `WIND_UP_SCALE_S = 0.6`
- `intensity` ∈ [0.1, 1.0], typical ~0.5–0.8 from power/follow_through
- `windup_mult` from archetype: 1.0 (slash), 1.15 (overhead), 0.8 (quick_slash), etc.
- `effective_wind_up = wind_up_duration * (1 - COMMITMENT_FRACTION)` with `COMMITMENT_FRACTION = 0.2` → **effective = wind_up × 0.8**

#### 1.2 Defender reaction time

```
reaction_time = PASSIVE_PARRY_BASE_REACTION_S / perception_factor
perception_factor = clamp(perception_norm * consciousness_norm * head_pain_mod, 0.15, 1.0)
```
- `PASSIVE_PARRY_BASE_REACTION_S = 0.24`
- `perception_norm = clamp(perception/100, 0.2, 1.5)`
- `consciousness_norm = clamp(consciousness/100, 0.1, 1.0)`
- `head_pain_mod` from `get_pain_performance_modifier(effective_pain_for_region("head"))`

#### 1.3 Can parry in time

```
can_parry_in_time = (reaction_time < effective_wind_up) AND defender has weapon AND attacker has weapon
```

#### 1.4 Parry choice (parry vs dodge)

```
choose_parry = can_parry_in_time AND (p_a <= c_d * PARRY_DODGE_STRENGTH_RATIO)
PARRY_DODGE_STRENGTH_RATIO = 2.2
```

#### 1.5 Attacker momentum (p_a)

```
p_a = m_a * v_intent * velocity_curve_factor(parry_progress)
parry_progress = 1 - clamp(parry_time_to_react / effective_wind_up, 0, 1)
velocity_curve_factor = progress²
v_intent = WeaponDamageHelper.get_effective_velocity_m_s(weapon, attack_instance)
```
- `velocity_m_s_from_intensity`: factor = 0.5 + 0.5*intensity, scaled by archetype.velocity_factor
- `v_m_s = 6 + (24-6) * factor` → range 6–24 m/s

#### 1.6 Defender parry capacity (c_d)

```
c_d_full = m_d * parry_speed * (s_d/PARRY_STRENGTH_NORM) * agi_mod * def_perf * arm_mod
parry_speed = VELOCITY_MAX_M_S * 0.5 * weapon.parry_speed_factor = 12 * factor (Sword 12, Dagger 14.4, Mace 10.8)
blade_movement_s = PARRY_BLADE_MOVEMENT_S * clamp(m_d*100/s_d, 0.5, 2.0)
effective_parry_time = max(0, parry_time_to_react - blade_movement_s)
parry_capacity_mult = clamp(effective_parry_time / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0, 1)
parry_c_d = c_d_full * parry_capacity_mult * parry_readiness * (off_balance? 0.7 : 1)
```

#### 1.7 Parry outcome

```
deflected = c_d_final >= p_a * PARRY_DEFLECT_THRESHOLD (1.0)
c_d_final = parry_c_d * randf_range(0.9, 1.1)  # PARRY_TECHNIQUE_VARIANCE ±10%
```

---

### 2. Reference Values

#### Species stats

| Species | Str | Agi | Per | Notes |
|---------|-----|-----|-----|-------|
| Human   | 100 | 100 | 100 | reaction ~0.24 s |
| Goblin  | 60  | 115 | 90  | reaction ~0.24 s |

#### Weapons (mass kg, parry_speed_factor)

| Weapon | Mass | Parry factor | Parry speed m/s |
|--------|------|--------------|-----------------|
| Sword  | 1.2  | 1.0          | 12              |
| Axe    | 1.5  | 0.95         | 11.4            |
| Mace   | 1.7  | 0.9          | 10.8            |
| Dagger | 0.3  | 1.2          | 14.4            |
| Spear  | 1.8  | 1.0          | 12              |

#### Archetypes (velocity_factor, windup_mult)

| Archetype     | vel_factor | windup_mult |
|---------------|------------|-------------|
| stab          | 1.0        | 1.0         |
| slash         | 0.9        | 1.0         |
| overhead      | 1.0        | 1.15        |
| quick_slash   | 0.65       | 0.8         |
| heavy_blunt   | 1.0        | 1.1         |

---

### 3. Computed Scenarios

#### 3.1 Wind-up durations (100% attacker, leg=1, perf=1, agi=1)

For intensity 0.5, windup 1.0: `wind_up = (0.25 + 0.3)*1.0 = 0.55 s` → effective = 0.44 s  
For intensity 0.8, windup 1.15 (overhead): `wind_up = (0.25 + 0.48)*1.15 = 0.84 s` → effective = 0.67 s  
For intensity 0.6, windup 0.8 (quick): `wind_up = (0.25 + 0.36)*0.8 = 0.49 s` → effective = 0.39 s  

#### 3.2 Reaction times

**Human 100%:** perception_factor = 1.0 → reaction = 0.24 s  
**Goblin 100%:** perception_norm = 0.9, factor ≈ 0.9 → reaction ≈ 0.24 s  

**Wounded (1–2 moderate wounds):**
- effective_pain ~4–6 (NRS first effect) → pain_mod 0.92 (minor)
- head_pain_mod 0.92 if head wound; consciousness may drop slightly
- Typical: perception_factor ~0.85–0.9 → reaction 0.24–0.26 s

**Wounded (2+ wounds, NRS 6–8):**
- pain_mod 0.8 (moderate)
- reaction_factor ~0.75–0.85 → reaction 0.26–0.29 s

#### 3.3 Can parry in time (reaction < effective_wind_up)

| Attack type     | Effective wind-up | Human 100% | Goblin 100% | Wounded (0.26 s) |
|-----------------|-------------------|------------|-------------|------------------|
| Slash (int 0.5) | 0.44 s            | ✓          | ✓           | ✓                |
| Overhead (0.8)  | 0.67 s            | ✓          | ✓           | ✓                |
| Quick slash     | 0.39 s            | ✓          | ✓           | ✗ (borderline)   |
| Dagger thrust   | ~0.32 s           | ✓          | ✗           | ✗                |

**Conclusion:** At 100%, humans and goblins can parry most sword/axe/mace attacks in time. Very fast attacks (dagger quick thrust/slash, quick_slash) approach or exceed the reaction window, especially for goblins and wounded defenders.

#### 3.4 Unparriable cases

**Case A: Cannot parry in time** — `reaction_time >= effective_wind_up`  
- Dagger quick thrust (~0.3 s effective) vs Goblin (0.24 s) or wounded Human (0.26 s): borderline; some hits unparriable.  
- Wounded defender (0.28 s) vs quick attacks (0.32–0.39 s): **~15–25% of fast attacks unparriable.**

**Case B: Chooses dodge instead** — `p_a > c_d * 2.2` (block not viable)  
- Strong attacker (Human str 100, mace 1.7 kg, v~18 m/s) → p_a ~30  
- Weak defender (Goblin str 60, dagger 0.3 kg) → c_d_full ≈ 0.3*14.4*0.6*1.15*1.0*1.0 = ~3; capacity_mult ~0.5 → c_d ~1.5.  
- 1.5 * 2.2 = 3.3 << 30 → **Goblin always chooses dodge vs Human mace.**  
- Human vs Human (both sword): p_a ~1.2*15*0.8 = 14.4, c_d ~1.2*12*1.0*1.0*0.8 = 11.5 → 14.4 <= 16.1 ✓ choose parry.

**Conclusion:** When the defender is much weaker (Goblin vs Human, wounded vs fresh), they often choose dodge rather than parry. Those attacks are "effectively unparriable" because the defender never attempts parry.

---

### 4. Parry Success Rates (when parry is chosen)

When `choose_parry` is true, outcome depends on `c_d >= p_a` (with ±10% variance).

**Human vs Human, both sword, intensity 0.6, WAITING (readiness=1):**
- p_a ≈ 1.2 * 16 * 0.85² ≈ 13.9 (progress ~0.85 from mid parry)
- c_d_full = 1.2*12*1.0*1.0*1.0 = 14.4; capacity_mult ~0.6 → c_d ≈ 8.6  
- 8.6 * 1.1 = 9.5 < 13.9 → **partial** (with variance, ~20% deflect, 80% partial)
- Higher intensity → higher p_a → fewer deflects.

**Goblin vs Goblin, both sword:**
- Attacker p_a lower (same weapon); defender c_d lower (str 60).
- c_d ≈ 1.2*12*0.6*1.15*1.0 ≈ 9.9; capacity_mult ~0.5 → c_d ~5  
- p_a ~12 → often partial; deflect rate ~15–30% when parry chosen.

**Wounded defender (arm_mod 0.7, perf 0.85):**
- c_d reduced by 0.7*0.85 ≈ 0.6  
- Deflect rate drops significantly; more partials and outright hits.

---

### 5. Summary Tables

#### 5.1 Script-validated results

Run `python3 scripts/parry_analysis.py` to reproduce. Key findings:

| Matchup | can_parry | choose_parry | p_a | c_d | Outcome |
|---------|-----------|---|-----|-----|---------|
| Human vs Human, sword/slash | ✓ | ✓ | 4.6 | 6.5 | Parry, high deflect |
| Human vs Human, sword/overhead | ✓ | ✓ | 2.9 | 14.4 | Parry, full deflect |
| Human attk Goblin, sword | ✓ | ✗ | 5.7 | 0 | Dodge (blade time &gt; react time) |
| Goblin attk Human, sword | ✓ | ✗ | 6.1 | 2.8 | Dodge (fast attack → low capacity) |
| Human vs Human, mace | ✓ | ✓ | 5.0 | 12.3 | Parry |
| Wounded Human def (perf 0.85, arm 0.75) | ✓ | ✗ | 6.0 | 3.0 | Dodge |

Note: Goblin defender vs Human sword has c_d=0 because blade movement time (0.26 s) exceeds parry_time_to_react (0.24 s), so capacity_mult=0.

#### 5.2 % of attacks that get parried (full deflect)

| Defender | Attacker | At 100% | After 1–2 wounds |
|----------|----------|---------|------------------|
| Human | Human (sword/axe) | 40–80%* | 5–15% |
| Goblin | Human | ~0% | ~0% |
| Human | Goblin (fast) | ~0%** | ~0% |
| Goblin | Goblin | 30–60%* | 10–25% |

\* When parry is chosen. \** Goblin’s short wind-up leaves Human with low capacity → dodge chosen.

#### 5.3 Effectively unparriable attacks (% of total)

| Scenario | At 100% | After 1–2 wounds |
|----------|---------|------------------|
| Human vs Human (equal) | 10–25% | 40–60% |
| Goblin vs Human (weak def) | 95–100% | 98–100% |
| Human vs Goblin (fast atk) | 80–95% | 90–98% |
| Wounded Human vs Human | — | 50–70% |

**Unparriable** = (a) cannot parry in time, or (b) chooses dodge (p_a &gt; c_d×2.2).

#### 5.4 Wound impact

- **Reaction time:** +15–30% (0.24 → 0.28–0.31 s) with 1–2 wounds affecting head/consciousness.
- **Parry capacity (c_d):** −30–50% from arm_mod and perf_mod when arm/general wounds present.
- **Net:** Parry attempt rate falls (more "can't parry in time" + more "choose dodge"); when parry is attempted, success rate falls. Combined effect: **parried % roughly halved after 1–2 wounds**, and **unparriable share roughly doubles**.

---

### 6. Recommendations

1. **Fast weapons:** Dagger quick thrust/slash are hardest to parry; wounded defenders often cannot parry them in time.
2. **Strength mismatch:** Weak defenders (Goblin vs Human) almost always dodge; parry is rare. Consider relaxing `PARRY_DODGE_STRENGTH_RATIO` or boosting weak-defender c_d if you want more parry attempts.
3. **Wound scaling:** Head and arm wounds most impact parry; leg wounds affect dodge instead.
4. **State matter:** RECOVERING readiness (0.5–0.85) further reduces c_d; early recovery is especially vulnerable.

---
