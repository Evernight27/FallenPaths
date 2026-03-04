# Parry Improvements: Blade Redirection

This document investigates **different ways** redirect can be implemented and how each affects the partial parry and damage systems for realism.

---

## 1. Current System and Data Flow

### 1.1 Parry resolve

- **Full deflect:** `c_d >= p_a` → attack negated, no damage.
- **Partial parry:** `remaining_momentum = p_a - c_d`, `v_reduced = remaining / m_a`, clamped to `v_min` (lerp 10–20% of intent by remaining_ratio).
- **Output:** `pa["velocity_m_s"] = v_reduced`; attack re-executes with this velocity.

### 1.2 Damage pipeline

| Step | Input | Output |
|------|-------|--------|
| AttackResolver | `velocity_override` from pa | passed to compute_and_apply_damage |
| AttackInstance | `velocity_m_s = velocity_override` | KE, momentum derived from v |
| WeaponDamageHelper | `get_effective_velocity_m_s` | `KE = ½ m v²`, momentum = m·v |
| pre_cut | KE | ∝ sqrt(KE) ∝ v |
| pre_blunt | momentum | ∝ m·v ∝ v |
| penetration | KE, momentum | ∝ KE^0.6 (sharp), momentum/area (blunt) |

**Key:** The only parry→damage coupling is `velocity_m_s`. Reducing v reduces cut, blunt, and penetration together.

---

## 2. Implementation Points (Where Redirect Can Apply)

| Point | Location | What changes | Affects |
|-------|----------|--------------|---------|
| **A. Parry resolve (velocity)** | AttackResolver partial block | How `v_reduced` is computed | All damage (cut, blunt, pen) via v |
| **B. Damage pre-armor modifier** | compute_and_apply_damage | Multiply pre_cut/pre_blunt by modifier | Damage only; penetration unchanged |
| **C. Damage post-velocity** | WeaponDamageHelper | Adjust v or KE/momentum when from partial parry | Needs flag that v came from parry |
| **D. Contact quality (penetration)** | compute_penetration | Reduce pen for glancing (partial parry) | Penetration; tissue damage unchanged |
| **E. Cut/blunt ratio shift** | get_cut_ratio or compute | Redirected cut → more blunt, less cut | Damage type mix |

---

## 3. Implementation Options (Full Survey)

### Option A: Redirect at velocity reduction (parry resolve)

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

### Option B: Redirect as damage modifier (post-velocity)

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

### Option C: Redirect at penetration only

**Where:** `WeaponDamageHelper.compute_penetration` or armor application.

**Mechanism:** Redirected hits land at a worse angle → less penetration. Pass `was_partial_parry` and apply `pen_mult *= 0.7` or similar.

**Effect:** Tissue damage (pre_armor) unchanged; armor/penetration more effective at stopping the blow. Realism: deflected edge doesn't present full point/edge to target.

**Pros:** Models contact geometry; sharp damage can be "turned" so it doesn't penetrate well.  
**Cons:** Pre_armor still high; armor soaks more. May feel like "same hit, armor does more" rather than "redirected hit is weaker."

---

### Option D: Redirect shifts cut/blunt ratio

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

### Option E: Explicit absorb vs redirect split

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

### Option F: Probabilistic glancing

**Where:** Parry resolve or damage.

**Mechanism:** Roll `randf() < redirect_glance_chance`; if success, treat as "glancing" (e.g. 50% damage or use v_min).

**Effect:** RNG adds variance; some partials become much lighter.

**Pros:** Simple.  
**Cons:** Less physics-based; can feel arbitrary.

---

### Option G: Two-stage residual (momentum + angle)

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

## 4. How Redirect Should Affect Damage (Realism)

| Damage component | Redirect effect | Rationale |
|------------------|-----------------|-----------|
| **Velocity (KE, momentum)** | ↓ Reduced | Deflected blade carries less energy to target |
| **Cut vs blunt** | More blunt, less cut | Edge deflected → flat or slap; less clean bite |
| **Penetration** | ↓ Reduced | Poor angle → less effective point/edge |
| **Contact area** | ↑ Effective area for blunt | Glancing = broader, softer contact |

**Best realism:** Combine velocity reduction (A) + cut/blunt shift (D) + optional penetration modifier (C). Velocity alone (A) is the minimal, most coherent change.

---

## 5. Research: Redirect vs Stop

### ARMA / Sword STEM

- **Deflection vs blocking:** "By slightly changing the direction you apply force rather than stopping the blade completely, you can drastically reduce the magnitude of force your opponent can bring to bear."
- **Cutting blades:** Prefer deflection/redirection over edge-on-edge blocking. Receiving on the **flat** deflects and dissipates force.
- **Thrusts:** Often defended by "directing the point offline"—a small lateral force can divert the attack.
- **Most parries:** Mix of magnitude reduction and direction change, not pure stop.

### Implication

Redirecting should be **more efficient** than head-on absorption. A defender whose c_d falls short of p_a can still achieve better-than-linear reduction by deflecting the blade, so the residual should be smaller than `p_a - c_d` suggests.

---

## 3. Proposed Improvements

### 3.1 Redirect efficiency (recommended)

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

### 3.2 Sub-linear residual ("glancing off")

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

### 3.3 Attack-type–dependent redirect

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

### 3.4 Agility / perception redirect bonus

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

### 3.5 Combined: redirect + glancing curve

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

## 6. Option Comparison Summary

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

## 7. Suggested Constants

Add to `CombatManager.gd` (or `AttackResolver.gd` if parry logic lives there):

```
const PARRY_REDIRECT_BONUS := 0.18      # 18% more effective reduction on partial parries
const PARRY_REDIRECT_THRUST_BONUS := 0.08   # extra 8% for thrust (if 3.3)
const PARRY_GLANCING_EXPONENT := 0.5    # sqrt for residual curve (if 3.2); 1.0 = linear
```

---

## 8. Code touchpoint (partial parry block)

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

## 9. Balance notes

- Redirect makes partial parries more common and softer.
- May want to slightly lower base parry success (e.g. `PARRY_DEFLECT_THRESHOLD` 1.0 → 1.05) if full deflects feel too easy.
- Monitor: partial parry rate and damage from "almost deflected" hits. The glancing curve should make those hits noticeably lighter.

---

## 10. Implemented: Attack-type physics + cut-blunt shift (Mar 2025)

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

## 11. Implemented: Penetration angle, mass disparity, desperate parry (Mar 2025)

**Penetration angle (separate from velocity):**
- Velocity reduction = momentum absorbed (magnitude) → already flows to KE, pen via v.
- Angle (deflection) = contact geometry. Oblique impact penetrates less (armor research). `pen *= lerp(1, PARRY_PENETRATION_ANGLE_MIN, 1 - remaining_ratio)`.

**Mass disparity (Fiore, HEMA):**
- Light weapons (dagger vs sword) deflect by angle/redirection; they cannot absorb. Redirect capacity bonus when m_d < m_a: `redirect_mult *= 1 + bonus * (1 - m_d/m_a)`.

**Desperate parry:**
- When `dodge_chance < PARRY_DESPERATE_DODGE_THRESHOLD` (e.g. injured legs), defender attempts parry anyway—often partial, but better than guaranteed hit from failed dodge.
