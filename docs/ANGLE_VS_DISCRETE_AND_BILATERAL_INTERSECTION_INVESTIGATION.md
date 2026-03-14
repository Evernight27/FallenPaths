# Angle vs Discrete + Variance, and Optimal Bilateral Blade Intersection

## Purpose

1. **Tradeoffs:** Reasons to prefer or avoid trajectory-as-angle vs discrete lines with variance.
2. **Optimal implementation:** Angle-based trajectory + part sectors where **both attacker and defender** determine hit location, parry success, and deflection outcome.

---

## 1. Angle vs Discrete Lines + Variance

### 1.1 Reasons to Prefer Continuous Angle

| Advantage | Explanation |
|-----------|-------------|
| **Physical continuity** | No quantization. 23° and 67° are distinct; discrete forces both into "45°" bucket. |
| **Natural deflection direction** | Deflected angle = f(attack_angle, guard_angle). Direction comes from geometry: blade deflects "away from" defender's blade. With discrete, you pick "other adjacent" arbitrarily. |
| **Smooth probability curves** | P(bind), interception depth, etc. vary smoothly with angle. Discrete + variance approximates this with a step + noise. |
| **Single source of truth** | One number (angle) drives parry, deflection, hit part. Discrete requires multiple tables (LINE_ANGLE_DEG, paths, deflection) that must stay consistent. |
| **Extensible** | New weapons or moves add angles; no new table entries. |
| **Animation-ready** | Angle maps directly to orientation for 2D/3D visualization. |

### 1.2 Reasons to Prefer Discrete + Variance

| Advantage | Explanation |
|-----------|-------------|
| **Lower refactor cost** | Existing tables (4×4 or 8×8) work. Add variance to intercept/outcomes without changing geometry. |
| **Easier tuning** | "High vs left = 45°" is a named case. Designers can tweak specific matchups. |
| **Predictable behavior** | Discrete cases are enumerable; angle has infinite cases. |
| **Simpler debugging** | "Guard high, attack left" vs "Guard 12°, attack 87°". |
| **Variance approximates continuous** | `intercept_max += randfn(0, 0.5)` when alignment is mid-range can capture "uncertain" hits without full angle refactor. |

### 1.3 Verdict

**No strong reason to avoid angle** — it's a design and effort choice:

- **Choose angle** if you want true continuity, natural deflection direction, and a unified model. Best long-term.
- **Choose discrete + variance** if you want minimal change and "good enough" statistical behavior. Variance can approximate angle-driven variance for intercept/outcomes, but deflection direction stays coarse.

**Hybrid:** Store angle internally; expose discrete line for legacy consumers. `effective_line = angle_to_nearest_line(angle_deg)`.

---

## 2. Bilateral Model: Attacker + Defender Determine Outcome

The outcome (parried, deflected to where, hit which part) must depend on **both** blades.

### 2.1 Inputs

| Symbol | Meaning |
|--------|---------|
| A | Attacker blade angle (0–360°) |
| G | Defender guard angle (0–360°) |
| θ | Angular distance = min(\|A − G\|, 360 − \|A − G\|) |
| alignment | cos(θ) |

### 2.2 Parry Success

**Bilateral:** P(parry) depends on θ (how well blades align) plus margin, readiness, etc. θ is the joint angle; both A and G matter.

```
alignment = cos(θ)
parry_capacity ∝ alignment
P(full_parry) = f(margin, alignment, readiness, ...)
```

### 2.3 Deflection (When Parry Succeeds)

**Bilateral:** Deflection direction is set by defender. The attacker's blade is pushed away from the defender's blade.

**Geometry:** Defender at G applies force. Attacker blade at A moves in the direction **away from G**. Two choices: clockwise or counterclockwise from A. Pick the one **away from G** (larger angular distance from G).

```gdscript
# Deflection direction: "away from" defender's blade
static func deflected_angle_bilateral(attack_angle: float, guard_angle: float, magnitude_deg: float) -> float:
    var cw := fmod(attack_angle + magnitude_deg + 360, 360)
    var ccw := fmod(attack_angle - magnitude_deg + 360, 360)
    var dist_cw := abs(angle_diff(cw, guard_angle))
    var dist_ccw := abs(angle_diff(ccw, guard_angle))
    # Choose the deflected position farther from guard
    return cw if dist_cw > dist_ccw else ccw
```

**Magnitude:** From severity and alignment. Lower alignment → larger deflection. `magnitude = base_from_geometry(θ) * severity * randf_range(0.9, 1.1)`.

### 2.4 Hit Part (When Parry Fails)

**Bilateral:** Attack angle A sets trajectory; guard angle G sets what is covered and what is exposed.

**Model: Part sectors + Guard coverage**

1. **Part sectors:** Each part has an angular range from attacker's viewpoint (e.g. head: 315°–45°).
2. **Guard coverage:** Guard at G "blocks" a sector around G (e.g. G ± 40°). Parts in that sector are harder to hit.
3. **Weight(part) = overlap(part, A) × exposure(part, G)**

```gdscript
# Part P is in the "line of fire" of attack A if A lies in P's sector
# Part P is "exposed" when guard G doesn't cover P's sector
static func part_weight_bilateral(part: String, attack_angle: float, guard_angle: float) -> float:
    var overlap := sector_contains(part, attack_angle)  # 1 if A in part sector, else 0 or partial
    var guard_blocks := sector_overlap(part_sector(part), guard_sector(guard_angle))
    var exposure := 1.0 - guard_blocks * GUARD_COVERAGE_STRENGTH
    return overlap * exposure
```

**Intercept depth (how far the blade travels):** alignment. High alignment → guard blocks early → blade hits "front" parts (arms). Low alignment → blade gets through → "deeper" parts (chest, legs).

```
intercept_depth = lerp(FULL, EARLY, alignment)
# Parts are ordered by "depth" (arms first when guard high, head first when guard low)
# Hit part = weighted sample from parts up to intercept_depth, with weights from part_weight_bilateral
```

**Path order from guard:** Guard determines which parts are "first" in the blade's path. High guard → arms first. Low guard → head/chest first. So the **order** of parts comes from G; the **intercept depth** (how many of those parts are reachable) comes from alignment (A and G together).

---

## 3. Optimal Implementation: Angle + Bilateral Part Sectors

### 3.1 Data Structures

```gdscript
# Part sectors: angular range from attacker POV (0° = high/forward)
const PART_SECTORS: Dictionary = {
    "head": {"center": 0, "width": 60},      # upper arc
    "chest": {"center": 0, "width": 80},     # center, broader
    "left_arm": {"center": 315, "width": 50},
    "right_arm": {"center": 45, "width": 50},
    "left_leg": {"center": 270, "width": 40},
    "right_leg": {"center": 90, "width": 40},
}

# Guard coverage: guard at G blocks sector G ± COVERAGE_HALF
const GUARD_COVERAGE_HALF := 45
const GUARD_COVERAGE_STRENGTH := 0.8  # 0–1 how much guard reduces hit chance
```

### 3.2 Part Order by Guard (What's "First" in the Path)

Guard determines which parts are in front. When guard is high (0°), arms are up → arms first. When guard is low (180°), legs/center first.

```gdscript
# Precomputed or computed: path = ordered parts by "encounter order" when blade travels from attack angle
# with defender's guard at G. Parts "behind" guard are later in path.
static func get_path_order(attack_angle: float, guard_angle: float) -> Array:
    var parts := []
    for part in PART_SECTORS:
        var depth := angular_distance_to_guard(part, guard_angle)
        parts.append({"part": part, "depth": depth})
    parts.sort_custom(func(a,b): return a.depth < b.depth)
    return parts.map(func(x): return x.part)
```

**Simpler:** Keep ATTACK_PATHS_BY_GUARD-style table. Key by `(quantize(attack_angle), quantize(guard_angle))`. For angle-based, `quantize` = nearest of 4 or 8 lines. Path order still comes from guard (and optionally attack).

### 3.3 Hit Part (Bilateral)

```gdscript
static func resolve_hit_part_bilateral(attack_angle: float, guard_angle: float, targetable: Array) -> String:
    var theta := angle_diff(attack_angle, guard_angle)
    var alignment := cos(theta * PI / 180.0)
    
    var path := get_path_order(attack_angle, guard_angle)
    var intercept_max := int(lerpf(PATH_FULL, PATH_EARLY, 1.0 - alignment))
    intercept_max = clampi(intercept_max, 0, path.size() - 1)
    
    var segment := path.slice(0, intercept_max + 1).filter(func(p): return p in targetable)
    if segment.is_empty():
        return weighted_random_from_targetable(targetable)
    
    var weights := {}
    for p in segment:
        var w := part_weight_bilateral(p, attack_angle, guard_angle)
        weights[p] = maxf(0.1, w)
    
    return weighted_sample(weights)
```

### 3.4 Deflection (Bilateral)

```gdscript
static func resolve_deflection_bilateral(attack_angle: float, guard_angle: float, severity: float, alignment: float) -> float:
    var magnitude := (1.0 - alignment) * 90.0 * severity * randf_range(0.9, 1.1)
    return deflected_angle_bilateral(attack_angle, guard_angle, magnitude)
```

### 3.5 Angle Convention

Use a consistent mapping:

- 0° = high (forward-up)
- 90° = right
- 180° = low (down-back)
- 270° = left

Moves and guards store `angle_deg` or derive from `angle_deg = line_to_angle(line)`.

---

## 4. Summary: Angle vs Discrete

| Question | Answer |
|----------|--------|
| Avoid angle? | No. Angle is better for continuity and deflection direction. Use it if refactor is acceptable. |
| Avoid discrete + variance? | No. Discrete + variance is a valid low-effort option. Variance can mimic angle-driven randomness for many outcomes. |
| When to use angle | When you want true continuity, bilateral deflection direction, and a single angle-driven model. |
| When to use discrete | When you want minimal change and are fine with coarser geometry. |

---

## 5. Summary: Optimal Bilateral Model

| Outcome | Attacker Role | Defender Role | Bilateral Formula |
|---------|---------------|---------------|-------------------|
| Parry success | A (trajectory) | G (guard position) | alignment = cos(\|A−G\|); P(parry) ∝ alignment × margin × … |
| Deflection direction | A (initial angle) | G (pushes blade away) | deflected = A ± magnitude, choice of ± to maximize distance from G |
| Deflection magnitude | — | — | magnitude ∝ (1−alignment) × severity |
| Hit part | A (line of fire) | G (what's covered, path order) | path = f(G); intercept_depth = f(alignment); weight(P) = overlap(P,A) × exposure(P,G) |

**Core idea:** Attacker sets trajectory (A). Defender sets coverage and deflection (G). The pair (A, G) determines all outcomes. No 3D; only angles and sector overlap.

---

## References

- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- GUARD_ANGLE_PHYSICS_INVESTIGATION.md
- AttackPathResolver, ATTACK_PATHS_BY_GUARD
