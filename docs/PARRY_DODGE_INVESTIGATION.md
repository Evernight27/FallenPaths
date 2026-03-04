# Parry Preference & Partial Dodge: Investigation

**Status: Implemented.** See implementation summary at end.

Investigation of ways to (1) prefer parry unless dodge is drastically more successful, and (2) add physics-based partial dodge (glancing/angled hits).

---

## Part 1: Parry vs Dodge Preference

### Current Logic

```
choose_parry = late_parry or (is_block_parry and block_viable) or (not is_block_parry and redirect_viable)
block_viable = can_parry_in_time and p_a <= c_d * PARRY_DODGE_STRENGTH_RATIO (2.2)
redirect_viable = can_parry_in_time and (p_a <= c_d * effective_redirect OR desperate_parry)
desperate_parry = dodge_chance < 0.06
```

**Effect:** Parry is chosen when block or redirect is "viable" (parry capacity can handle the attack). Otherwise dodge. When dodge is nearly useless (< 6%), parry is attempted anyway (desperate).

**Problem:** Parry is only chosen when it's *viable*. If `p_a > c_d * 2.5` (redirect threshold), we choose dodge—even though parry would still produce a partial (reduced damage). The preference is "parry only when we can do well," not "parry unless dodge is drastically better."

---

### Option A: Flip the Default (Always Parry When Possible)

**Idea:** Parry whenever `can_parry_in_time` and defender has weapon. Dodge only when parry is *not possible* (can't react in time).

```
choose_parry = can_parry_in_time
choose_dodge = not can_parry_in_time
```

**Effect:** All "in time" defense goes through parry. Quick attacks, goblins with late parry, etc. still use parry (partial at worst). Dodge only when we never computed parry (reaction too slow, no weapon).

**Pros:** Simple. Matches "blade contact is primary" (HEMA 57–80%).  
**Cons:** Removes tactical choice; dodge becomes fallback-only. No "dodge is better here" decision.

---

### Option B: Parry Unless Dodge Is Drastically Better (Threshold)

**Idea:** Prefer parry unless `dodge_chance` exceeds a high threshold (e.g. 0.5 or 0.6). Dodge is only "drastically better" when success is very likely.

```
dodge_drastically_better = dodge_chance >= DODGE_PREFER_THRESHOLD  # e.g. 0.5
choose_parry = can_parry_in_time and (not dodge_drastically_better or not block_viable)
# Refined: parry unless BOTH (dodge >> parry success) AND (parry would fail badly)
choose_parry = can_parry_in_time and not (dodge_chance >= 0.5 and p_a > c_d * 3.0)
```

**Effect:** At typical dodge_chance ~8%, parry is almost always preferred. Only very agile defenders in favorable conditions would ever choose dodge over parry.

**Pros:** Clear "drastically better" bar.  
**Cons:** With current dodge_chance (≤15% max), threshold of 0.5 means dodge is never preferred. Would need to tune both.

---

### Option C: Expected-Outcome Comparison

**Idea:** Compare expected damage from parry vs dodge. Prefer parry unless dodge's expected outcome is much better.

```
# Parry: always attempt when can; outcome = full deflect, partial, or (worst) partial with high remaining
# Dodge: P(dodge) * 0 + (1 - P(dodge)) * full_damage
E_dodge = (1 - dodge_chance) * full_damage

# Parry: we don't know damage until we resolve; use proxy.
# E_parry ~ estimated from p_a vs c_d (partial → some reduction)
parry_success_est = clamp((c_d * redirect_mult - p_a) / p_a, 0, 1)  # negative = partial
E_parry = (1 - parry_success_est) * partial_damage_est  # rough

choose_parry = E_parry < E_dodge * PARRY_PREFERENCE_FACTOR  # e.g. 1.2 = prefer parry unless dodge 20% better
```

**Effect:** Numerical comparison. Parry preferred when its expected damage is not much worse than dodge's.

**Pros:** Theoretically optimal.  
**Cons:** Complex. Requires estimating partial damage before resolution. Several new constants.

---

### Option D: Raise Parry Viability Thresholds

**Idea:** Keep current structure but make "prefer dodge" much harder. Right now we prefer dodge when `p_a > c_d * 1.4` (block) or `p_a > c_d * 2.5` (redirect). Raise these so parry is attempted more often.

```
PARRY_DODGE_STRENGTH_RATIO: 1.4 → 2.5   # was "prefer dodge when badly outmatched"
PARRY_REDIRECT_ATTEMPT_RATIO: 2.5 → 4.0  # redirect attempted even when very outmatched
```

**Effect:** Parry chosen in more cases. Dodge only when parry is *extremely* inadequate.

**Pros:** Minimal code change. Uses existing knobs.  
**Cons:** Parry will be attempted in very unfavorable situations (often heavy partials); may feel like "why parry when you know you'll get hit?" Balance-wise, partial > full hit.

---

### Option E: Desperate Parry Expansion

**Idea:** Expand "desperate parry" to mean "prefer parry whenever dodge isn't clearly superior." Treat "dodge drastically better" as the narrow case.

```
desperate_parry = dodge_chance < PARRY_DESPERATE_DODGE_THRESHOLD  # current 0.06
# Add: also prefer parry when dodge chance is below a "parry preference" threshold
parry_preferred = dodge_chance < PARRY_PREFER_DODGE_THRESHOLD  # e.g. 0.25
choose_parry = can_parry_in_time and (parry_preferred or block_viable or redirect_viable)
```

So: parry when dodge is < 25% OR when parry is viable. Dodge only when dodge ≥ 25% AND parry not viable.

**Pros:** Single new constant. Clear meaning.  
**Cons:** At 8% dodge, parry almost always wins. Need to tune threshold if dodge_chance distribution changes.

---

### Recommendation (Parry Preference)

**Option D + E combined:**  
1. Raise `PARRY_DODGE_STRENGTH_RATIO` to 2.0–2.5 and `PARRY_REDIRECT_ATTEMPT_RATIO` to 3.5–4.0.  
2. Add `PARRY_PREFER_DODGE_THRESHOLD := 0.3` and treat parry as preferred when `dodge_chance < 0.3`.

This yields: parry preferred unless (a) dodge is ≥ 30% and (b) parry is not viable. With current dodge values (≤15%), parry will be chosen almost always when `can_parry_in_time`.

---

## Part 2: Partial Dodge (Physics-Based)

### Current Dodge

- Binary: `roll < dodge_chance` → full avoid. Else → full hit.
- `dodge_chance` from agility, perception, leg functionality, performance, leg pain.
- No partial outcome; no damage modulation.

### Physics Basis for Partial Dodge

**HEMA / martial arts:**
- **Void / tai sabaki:** Body movement out of the line of attack. Full void = no contact. Partial void = displacement changes impact geometry.
- **Grazing / glancing:** Incomplete void → strike hits at an angle or with reduced contact.
- **Oblique impact (armor research):** Angled hits penetrate less. Steel armor can require ~60% more effective thickness vs oblique vs normal. Angle directly reduces penetration.

**Reuse from parry system:**
- Partial parry uses `parry_remaining_ratio` to: reduce velocity, shift cut→blunt, reduce penetration (oblique angle).
- Partial dodge can use an analogous `dodge_remaining_ratio`: how much of the attack "got through" after partial body movement.

---

### Option A: Dodge Roll Tiers (Continuous Roll)

**Idea:** Use the dodge roll to define degree of success, not just pass/fail.

```
dodge_roll = randf()
dodge_chance = get_dodge_chance()  # e.g. 0.08

if dodge_roll < dodge_chance * DODGE_FULL_THRESHOLD:  # e.g. 0.5 → roll < 0.04
    → full dodge (no contact)
elif dodge_roll < dodge_chance:
    → partial dodge (glancing)
else:
    → full hit
```

**Partial dodge physics:** Roll in `[dodge_chance*0.5, dodge_chance)` = "moved some but not enough."
- `dodge_remaining_ratio = 1.0 - (dodge_roll - dodge_chance*0.5) / (dodge_chance*0.5)` → 0 = best partial, 1 = worst partial.
- Or simpler: `dodge_remaining_ratio = lerp(0.5, 1.0, (dodge_roll - dodge_chance*0.5) / (dodge_chance*0.5))` so partial band gives 0.5–1.0.

**Effect:** When you "almost dodged," the strike still hits but with reduced impact (velocity, angle, cut→blunt). Reuse `compute_and_apply_damage` with `parry_remaining_ratio` replaced by `dodge_remaining_ratio` for partial dodge.

**Pros:** Simple. Reuses parry damage path. Roll directly maps to outcome tier.  
**Cons:** Arbitrary band (e.g. 0.5). "Full dodge" band shrinks as partial band grows.

---

### Option B: Physics-Based Dodge Quality (Time × Agility)

**Idea:** Model how far the defender could move in the available time. Compare to "attack width" to get overlap.

```
# Time available to move: same as parry—effective_wind_up - reaction_time
dodge_time_available = effective_wind_up - reaction_time

# Distance moved ∝ agility * sqrt(time) (simplified kinematics; short burst)
# Or: dodge_distance = agility_factor * DODGE_SPEED_M_S * dodge_time_available
dodge_distance = (agi/100) * 2.0 * max(0, dodge_time_available)  # meters

# Attack "width" or "tracking"—how much target movement is needed to fully avoid
# Simplification: attack has effective radius ~ weapon_reach * sin(arc)
# Or use intensity: harder attack = more committed = less tracking
attack_width = 0.3 * (1.0 + 0.5 * (1.0 - intensity))  # placeholder; tune

# Overlap = how much of the attack "landed"
# full_avoid if dodge_distance >= attack_width
overlap_ratio = max(0, 1.0 - dodge_distance / attack_width)
dodge_remaining_ratio = clamp(overlap_ratio, 0.0, 1.0)
```

- `dodge_remaining_ratio = 0` → full dodge.
- `dodge_remaining_ratio = 1` → no movement, full hit.
- In between → partial; apply same damage modifiers as parry (velocity, angle, cut→blunt).

**Pros:** Physics-grounded. Uses reaction time and agility.  
**Cons:** More parameters. Needs calibration. Deterministic unless we add variance.

---

### Option C: Hybrid—Deterministic Base + Roll Variance

**Idea:** Compute a base "dodge quality" from physics (time, agility, legs), then add variance from a roll.

```
dodge_quality_base = f(agility, dodge_time_available, leg_functionality)
dodge_roll = randf()
dodge_quality = dodge_quality_base * (0.8 + 0.4 * dodge_roll)  # ±20% variance

if dodge_quality >= 1.0:
    → full dodge
elif dodge_quality >= 0.0:
    → partial dodge, dodge_remaining_ratio = 1.0 - dodge_quality
else:
    → full hit
```

**Pros:** Physics base + randomness.  
**Cons:** Need to define `f` and scale so `dodge_quality` matches desired success rates.

---

### Option D: Angle-Focused Partial Dodge

**Idea:** Partial dodge mainly changes impact angle. Full dodge = no contact. Partial = contact at oblique angle.

- Oblique impact reduces penetration (existing `PARRY_PENETRATION_ANGLE_MIN` logic).
- Could also reduce effective velocity (shorter contact, glancing trajectory).

```
# dodge_angle_factor: 1.0 = normal impact, 0.7 = 30° off, 0.5 = 45° off
# From dodge roll: worse roll = less favorable angle
dodge_angle_factor = lerp(PENETRATION_ANGLE_MIN, 1.0, dodge_roll / dodge_chance)  # when partial
```

Use `dodge_angle_factor` to scale penetration (and optionally pre-armor damage) for partial dodges.

**Pros:** Directly uses armor/penetration research. Minimal new structure.  
**Cons:** Doesn't model velocity reduction as explicitly. Partial dodge is "bad angle" only.

---

### Recommendation (Partial Dodge)

**Option A (roll tiers) + Option D (angle):**

1. **Tiers:**  
   - `roll < dodge_chance * 0.4` → full dodge  
   - `roll < dodge_chance` → partial dodge  
   - else → full hit  

2. **Partial dodge ratio:**  
   - `dodge_remaining_ratio = lerp(0.4, 1.0, (roll - dodge_chance*0.4) / (dodge_chance*0.6))`  
   - Best partial: 0.4 (40% damage potential). Worst partial: 1.0 (full hit).

3. **Damage path:** Pass `dodge_remaining_ratio` into the same pipeline as `parry_remaining_ratio`:
   - Reduce velocity (or scale pre-armor) by `1 - dodge_remaining_ratio`
   - Apply cut→blunt shift
   - Apply penetration angle factor (oblique impact)

This stays physics-aligned (oblique = less penetration, glancing = less edge bite) and reuses the existing parry damage logic with minimal duplication.

---

## Part 3: Implementation Sketch

### Parry Preference Changes

**CombatManager.gd:**
```
const PARRY_DODGE_STRENGTH_RATIO := 2.2       # was 1.4; prefer parry unless badly outmatched
const PARRY_REDIRECT_ATTEMPT_RATIO := 3.5     # was 2.5
const PARRY_PREFER_DODGE_THRESHOLD := 0.3     # NEW: dodge ≥ 30% to prefer over parry when both possible
```

**AttackResolver.gd:**
```
parry_preferred_over_dodge = dodge_chance < manager.PARRY_PREFER_DODGE_THRESHOLD
choose_parry = can_parry_in_time and (parry_preferred_over_dodge or (is_block_parry and block_viable) or (not is_block_parry and redirect_viable))
```

### Partial Dodge Changes

**CombatManager.gd:**
```
const DODGE_FULL_THRESHOLD := 0.4     # roll < dodge_chance * this => full dodge
const DODGE_PARTIAL_RATIO_MIN := 0.4  # best partial: 40% through
```

**AttackResolver.gd (dodge block):**
```
var dodge_roll := randf()
if dodge_chance > 0.0:
    if dodge_roll < dodge_chance * manager.DODGE_FULL_THRESHOLD:
        → return dodge (full)
    elif dodge_roll < dodge_chance:
        → partial dodge: dodge_remaining_ratio = lerp(DODGE_PARTIAL_RATIO_MIN, 1.0, (dodge_roll - dodge_chance*0.4)/(dodge_chance*0.6))
        → set pa["dodge_remaining_ratio"] = dodge_remaining_ratio
        → DON'T return; fall through to hit resolution with velocity_override and dodge_remaining_ratio
```

**Damage path:** In `compute_and_apply_damage`, accept `defense_remaining_ratio` (parry or dodge). Use it for velocity, cut→blunt, penetration angle. Parry sets `parry_remaining_ratio`; dodge sets `dodge_remaining_ratio`; unify as one parameter for damage.

---

## Summary Table

| Change | Effort | Effect |
|--------|--------|--------|
| Parry: raise PARRY_DODGE_STRENGTH_RATIO | Trivial | Parry chosen more often |
| Parry: add PARRY_PREFER_DODGE_THRESHOLD | Low | Parry default unless dodge very good |
| Dodge: roll tiers (full / partial / hit) | Low | Partial dodges produce reduced damage |
| Dodge: reuse parry damage modifiers | Low | Angle, cut→blunt, velocity for partial |
| Dodge: physics-based quality (Option B) | Medium | More realistic, more tuning |

---

## Implementation Summary (completed)

- **Unarmed:** Defender with no weapon always dodges; cannot parry.
- **Parry vs dodge:** Expected-damage comparison. Parry when E_parry ≤ E_dodge and parry viable. Dodge when (1) E_dodge < E_parry, or (2) full_dodge_prob ≥ PARRY_PREFER_DODGE_FULL_THRESHOLD (0.12).
- **Dodge chance:** DODGE_CHANCE_AT_FULL_SPEED 0.10 so high agility can reach ~15% (1.5×0.10); PARRY_PREFER_DODGE_FULL_THRESHOLD 0.12 for "clean dodge likely."
- **Partial dodge:** DODGE_FULL_THRESHOLD 0.4, DODGE_PARTIAL_RATIO_MIN 0.4. Roll tiers: full dodge, partial (glancing), full hit.
- **Part-specific modifier:** BodyPartQuery.get_part_dodge_modifier(part) — legs, arms, head, chest functionality modulate effective dodge chance.
- **Damage path:** Partial dodge reuses parry path: velocity reduction (glancing exponent), parry_remaining_ratio for cut→blunt and penetration angle.
