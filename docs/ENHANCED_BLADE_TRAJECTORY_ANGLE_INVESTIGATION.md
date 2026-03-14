# Enhanced Blade Trajectory & Angle Physics — Investigation

## Purpose

Improve blade physics beyond 4 cardinal directions: better trajectory and blade intersection representation, with **statistical/probability outcomes** based on angles — **without** 3D body modeling. Stay abstract; use angle-derived probability distributions for all outcomes.

---

## 1. Design Constraints

- **No 3D body modeling** — no vertex/ray intersection, no skeletal positions
- **Statistical outcomes** — hit part, bind vs deflect, deflection magnitude resolved via probability (rolls, weighted sampling)
- **Angle-driven** — trajectory and intersection expressed as angles; outcomes derive from angle difference and probability curves
- **Backward compatibility** — optional: preserve 4-line facade for consumers that expect discrete lines

---

## 2. Current Abstraction (Baseline)

| Concept | Current | Body Modeling? |
|---------|---------|----------------|
| Attack trajectory | 4 lines (high/low/left/right) | No — line = direction |
| Guard position | 4 lines | No |
| Blade intersection | angle between lines → alignment (cos θ) | No |
| Hit part | path[0..intercept_max] → weighted random | No — path is ordered list of part names |
| Deflection outcome | Same/adjacent/opposite → deterministic line | No |

**Key:** Body is already abstract — `ATTACK_PATHS_BY_GUARD` is a lookup: (attack_line, guard_line) → ordered list of part names. No 3D. "Intercept" = how far along that list the blade travels (statistical via alignment).

---

## 3. Improvement Approaches

### Approach A: Continuous Angle (Single Float)

**Model:** Store blade orientation as `angle_deg: float` (0–360). All geometry becomes angle arithmetic.

| Data | Meaning |
|------|---------|
| `attack_angle` | 0°=high, 90°=right, 180°=low, 270°=left (or custom mapping) |
| `guard_angle` | Same scheme |
| `alignment` | `cos((attack_angle - guard_angle) * PI / 180)` |

**Angle → outcome (all statistical):**
1. **Parry capacity:** alignment (existing)
2. **Bind vs deflect:** P(bind) = curve(alignment) — e.g. alignment ≥ 0.95 → 90% bind; alignment 0.7 → 50% bind; alignment 0.5 → 10% bind. Roll.
3. **Deflection magnitude:** If deflect, `magnitude_deg = lerp(22.5, 90, 1 - alignment) * severity`. Statistical variation: `magnitude_deg *= randf_range(0.8, 1.2)`.
4. **Deflection direction:** `deflected_angle = attack_angle + magnitude_deg * sign(guard_angle - attack_angle)` (or probabilistic left/right).
5. **Hit part:** Map angle to probability weights per part. E.g. part "head" gets weight for angles 330°–30°; "chest" for 30°–150°, etc. Weighted random.

**Angle → part weights (no 3D):**
```gdscript
# Part sectors: each part has an angular "sector" from attacker's view
# head: upper arc (315°-45°), chest: center (45°-135°, 225°-315°), arms: sides, legs: lower
const PART_ANGLE_WEIGHTS: Dictionary = {
  "head": {"center_deg": 0, "width_deg": 90, "weight_scale": 1.0},
  "chest": {"center_deg": 0, "width_deg": 120, "weight_scale": 0.9},
  ...
}
# weight(part, attack_angle, guard_angle) = alignment_factor * sector_overlap(part, effective_angle)
```

**Pros:** Truly continuous; one number (angle) drives everything. Physically intuitive.  
**Cons:** Refactor of get_line_alignment, path lookup, deflection. Need angle↔line mapping for legacy.

---

### Approach B: 8 Directions (Discrete Extension)

**Model:** Add diagonals: `high_left`, `high_right`, `low_left`, `low_right`. Total 8 directions at 45° spacing.

| Angle | Line |
|-------|------|
| 0° | high |
| 45° | high_right |
| 90° | right |
| 135° | low_right |
| 180° | low |
| 225° | low_left |
| 270° | left |
| 315° | high_left |

**Angle between any two:** `min(|a - b|, 360 - |a - b|)` (or from lookup table).  
**Alignment:** `cos(angle_between)`.

**Statistical outcomes:**
1. **Bind vs deflect:** P(bind) = f(alignment). Roll at parry resolution.
2. **Deflection target:** Instead of deterministic "other adjacent," roll: 70% to other adjacent, 30% to opposite (when adjacent defender). Or use alignment to weight.
3. **Hit part:** Path per (attack_line, guard_line) — extend to 8×8. Intercept still from alignment. Add variance: `intercept_max += randi_range(-1, 1)` when alignment is in mid-range (0.4–0.8) to reflect "uncertain" intersection.

**Pros:** 2× resolution; discrete; tables extend naturally.  
**Cons:** 8×8 path table; more data. Still coarse (45° steps).

---

### Approach C: 4 Lines + Continuous Angle Offset

**Model:** Keep 4 base lines. Add `angle_offset_deg: float` (-45 to +45) — where the blade sits within the "sector" of that line.

- `guard_line = "high"`, `angle_offset = 15` → blade is 15° toward right from pure high.
- Effective angle = `base_angle(guard_line) + angle_offset`.
- Alignment = `cos(attack_angle - effective_angle)`.

**Outcome resolution:**
- Resolve to **effective line** for path lookup: `effective_line = nearest_of_4(effective_angle)`.
- Or interpolate path weights between two nearest lines.
- Bind/deflect: use continuous alignment for P(bind) curve.

**Pros:** Minimal schema change; 4 lines preserved; offset adds precision.  
**Cons:** Offset propagation; need base_angle per line.

---

### Approach D: Trajectory as Angle Range (Arc)

**Model:** Attack has `angle_center` and `angle_width`. Blade travels through an arc.

- Oberhau: center 0° (high), width 60° (sweeps through high-right and high-left).
- Intersection: guard_angle vs trajectory. "Overlap" = how much of the trajectory is "blocked" by defender's position.
- `overlap = 1 - min(|guard_angle - angle_center|, angle_width/2) / (angle_width/2)`.
- P(intercept) = f(overlap); P(hit) = 1 - P(intercept) (when overlap low, blade gets through).

**Hit part:** Probability distribution along trajectory. Contact "position" = random within trajectory arc, weighted by guard. Map to part weights.

**Pros:** Models arc of cut; more realistic trajectory.  
**Cons:** Two params per attack (center, width); more complex intersection.

---

### Approach E: Probability Curves from Alignment (Minimal Change)

**Model:** Keep 4 lines. Add **probability curves** for outcomes. Alignment (0–1) drives rolls.

| Outcome | Current | Improved |
|---------|---------|----------|
| Bind vs deflect | Determined by parry_control threshold | P(bind) = sigmoid(alignment, threshold, steepness). Roll. |
| Deflection magnitude | 0°, 45°, or 90° deterministic | `mag = lerp(0, 90, 1 - alignment) * severity`; add ±10% random. Resolve to nearest discrete for downstream. |
| Hit part | path[0..intercept_max] → weighted random | intercept_max has variance: `intercept_max += round(randfn(0, 0.5))` when alignment is 0.3–0.8 (uncertain range). |
| Glancing vs solid hit | From alignment | P(solid) = alignment²; P(glancing) = 1 - P(solid). Roll. |

**Pros:** Small change; all outcomes become statistical; no new geometry.  
**Cons:** Still 4 directions; trajectory not more defined.

---

### Approach F: Angle-Based Part Sectors (Statistical Body)

**Model:** Define each body part as an **angular sector** from attacker's viewpoint (no 3D). Blade angle → which sectors it can hit.

```gdscript
# From attacker POV, 0° = high/forward. Parts occupy arcs.
const PART_SECTORS_DEG: Dictionary = {
  "head": {"start": 315, "end": 45},      # upper arc
  "chest": {"start": 45, "end": 135},      # right side
  "left_arm": {"start": 225, "end": 315},
  "right_arm": {"start": 135, "end": 225},
  "left_leg": {"start": 200, "end": 270},
  "right_leg": {"start": 90, "end": 160},
}
# Overlap(attack_angle, guard_angle, part) = how much of part's sector is "in path" given guard blocks some.
# Weight(part) = sector_overlap(part, attack_angle, guard_angle) * guard_block_factor(guard_angle)
```

Blade trajectory = attack_angle (or range). Guard blocks a sector. Remaining sectors weighted by overlap. Weighted random for hit part. **No 3D** — purely angular sectors.

**Pros:** Angle-driven; statistical; no body geometry.  
**Cons:** Sector definitions; overlap math.

---

## 4. Comparison Table

| Approach | Trajectory Precision | Statistical Outcomes | Schema Change | Effort |
|----------|---------------------|----------------------|---------------|--------|
| A: Continuous angle | Highest | Full | High | High |
| B: 8 directions | High | Full | Medium | Medium |
| C: 4 + offset | Medium | Partial | Low | Low |
| D: Trajectory arc | High | Full | Medium | Medium |
| E: Probability curves | Same (4) | Full | Minimal | Low |
| F: Part sectors | Medium | Full | Medium | Medium |

---

## 5. Recommended Phasing

### Phase 1 (Low effort): Probability Curves (Approach E)

- Add P(bind) curve from alignment + parry_control.
- Add variance to intercept_max for uncertain alignment.
- Add deflection magnitude as `lerp(0, 90, 1-alignment) * severity` with ±random, then map to discrete for storage.
- **Outcome:** All resolution becomes statistical. No new angles.

### Phase 2 (Medium): 8 Directions (Approach B)

- Add 4 diagonal lines.
- Extend LINE_ANGLE_DEG, paths, deflection tables.
- Move to angle-between = `min_dist` on 45° circle.
- **Outcome:** 2× angular resolution; better trajectory.

### Phase 3 (Higher): Continuous Angle or Part Sectors

- Store `angle_deg`; derive alignment, deflection, hit part from it.
- Or implement part sectors (Approach F) for angle→part weights.
- **Outcome:** Smooth trajectory; fully angle-driven.

---

## 6. Statistical Outcome Formulas (Angle-Based)

### P(bind) from alignment and parry_control

```gdscript
# alignment from cos(θ); parry_control from margin, readiness, etc.
var bind_chance := clampf(alignment * parry_control * 1.2, 0.0, 1.0)
if randf() < bind_chance:
  outcome = "bind"
else:
  outcome = "deflect"
```

### Deflection magnitude (continuous)

```gdscript
# angle_diff = angle between attack and guard
# magnitude_deg = base deflection from geometry (0, 45, or 90) scaled by severity
var base := 90.0 if opposite else (45.0 if adjacent else 0.0)
var mag := base * severity * randf_range(0.85, 1.15)
# Resolve to discrete for storage, or keep continuous
```

### Hit part from alignment (existing + variance)

```gdscript
var align_var := 0.0
if alignment > 0.25 and alignment < 0.85:
  align_var = randfn(0.0, 0.08)  # uncertain intercept in mid-range
var effective_align = clampf(alignment + align_var, 0.0, 1.0)
var intercept_max = int(lerpf(EARLY, FULL, 1.0 - effective_align))
# ... path segment, weighted random
```

### Part weights from angle (Approach F)

```gdscript
static func sector_overlap(part_sector: Dictionary, angle_deg: float) -> float:
  var start = part_sector.start
  var end = part_sector.end
  # normalize angle to 0-360
  var a = fmod(angle_deg + 360, 360)
  # overlap of point with sector
  if start <= end:
    return 1.0 if a >= start and a <= end else 0.0
  else:
    return 1.0 if a >= start or a <= end else 0.0
# Weight = overlap * modifier for guard blocking
```

---

## 7. Summary

| Goal | Best Approach | Notes |
|------|---------------|-------|
| More defined trajectory than 4 | B (8 dir) or A (continuous) | 8 discrete or float angle |
| Better blade intersection | A, B, or D | Angle difference drives overlap |
| Statistical outcomes | E (minimal) or A/B | Probability curves, variance |
| No 3D body | All | Body = path list or angle sectors |
| Low effort | E | Curves + variance only |
| High fidelity | A or B + F | Continuous angle or 8 dir + sectors |

**Suggested path:** Start with **Approach E** (probability curves, intercept variance) for immediate statistical outcomes with minimal change. Then add **Approach B** (8 directions) for better trajectory. **Approach F** (part sectors) can follow if you want angle-driven hit distribution without path tables.

---

## References

- GUARD_ANGLE_PHYSICS_INVESTIGATION.md
- SOFT_DEFLECTION_WEAPON_POSITION_INVESTIGATION.md
- AttackPathResolver (path + intercept)
- CombatConstants (LINE_ANGLE_DEG, ATTACK_PATHS_BY_GUARD)
