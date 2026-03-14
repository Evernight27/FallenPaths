# Soft Deflection and Weapon Position Tracking Investigation

## Goal

Move from **binary outcomes** (always 45° or 90° deflection) to **softer allowances** with more weapon position tracking, so parried blade position reflects partial deflections and transitional states.

---

## Current System: Binary Outcomes

### What We Have

| Outcome | Deflection | guard_line |
|---------|------------|------------|
| Bind (same line) | 0° | attack_line |
| Lateral (adjacent defender) | 45° | other adjacent |
| Strong block (opposite defender) | 90° | opposite line |

**Problem:** A light clash and a heavy clash with the same geometry produce identical blade position. No partial deflection (e.g. 20°, 60°).

---

## Design Constraints

### Consumers of guard_line

| Consumer | Usage | Expects |
|----------|-------|---------|
| `get_line_alignment(attack_line, guard_line)` | cos(θ) for parry capacity, path intercept | Discrete line string |
| `get_attack_path(attack_line, guard_line)` | Body part path lookup | Dict key (attack_line, guard_line) |
| `DIAGONAL_WEIGHTS` | Diagonal move line roll | guard_line as key |
| `LINE_TO_DEFAULT_PART` | guard_zone sync | guard_line as key |
| AttackWindUpStarter | Guard transition cost (align) | Discrete for align calc |
| AttackPathResolver | Intercept segment from alignment | Alignment 0–1 |

**Requirement:** Any extension must either (a) preserve a discrete "effective line" for existing consumers, or (b) extend those consumers to accept soft/blended positions.

---

## Approach 1: Primary Line + Deflection Blend (Additive)

### Model

Store two fields:
- `guard_line` — **primary line** (one of 4). Where the blade "is" for discrete lookups. Resolved from severity/geometry.
- `guard_deflect_blend` — **0.0–1.0**. How far the blade has moved toward a target line.
  - 0 = tight in primary (bind/settled)
  - 1 = fully in target line (full deflect)
  - 0.5 = halfway between
- `guard_deflect_toward` — **target line**. Only set when blend > 0. From geometry (adjacent or opposite).

**Resolving primary + blend from severity:**
```
# Geometry gives: bind_line (same), deflect_target (adjacent or opposite)
# Severity/clash gives: deflect_fraction in [0, 1]
if deflect_fraction < 0.5:
  primary = attack_line  # bind or near-bind
  deflect_toward = deflect_target
  deflect_blend = deflect_fraction * 2  # map 0-0.5 → 0-1
else:
  primary = deflect_target  # blade has crossed to deflect line
  deflect_toward = ""
  deflect_blend = 0  # fully settled in deflect line
```
Or simpler: always set `primary` to resolved line; `deflect_blend` = how "settled" (0 = just arrived, 1 = firm). Then next action uses primary; blend affects recovery or next-attack cost.

### Effective Alignment for Blended Position

For `get_line_alignment` with blend:
```gdscript
static func get_line_alignment_soft(attack_line: String, guard_line: String, deflect_toward: String, deflect_blend: float) -> float:
    var align_primary := get_line_alignment(attack_line, guard_line)
    if deflect_toward.is_empty() or deflect_blend <= 0:
        return align_primary
    var align_toward := get_line_alignment(attack_line, deflect_toward)
    return lerpf(align_primary, align_toward, deflect_blend)
```

### Effective Path for Blended Position

Interpolate intercept: use `intercept_max` from blended alignment. Already continuous via `lerpf(EARLY_MAX, FULL_MAX, 1.0 - alignment)`.

### Pros / Cons

| Pros | Cons |
|------|------|
| Backward compat: primary = guard_line | Two extra fields to propagate |
| Blend allows partial deflection | Consumers need optional blend params |
| Alignment and path can use blended align | Slightly more complex |
| Clear semantics | |

---

## Approach 2: Eight Diagonal Lines (Discrete Extension)

### Model

Add 4 diagonal lines between adjacent cardinal lines:
- `high_left` — between high and left (≈22.5° from each)
- `high_right`
- `low_left`
- `low_right`

**Deflection resolves to nearest of 8:**
- 0° → high, low, left, right (bind)
- ~22° → high_left, etc.
- 45° → high_left, high_right, low_left, low_right (lateral)
- ~67° → blend of diagonal and opposite? Or add more: high_left_low?
- 90° → opposite cardinal

**Severity maps to discrete choice:**
- severity 0–0.25: bind (cardinal)
- 0.25–0.5: diagonal toward adjacent (e.g. high → high_left)
- 0.5–0.75: full adjacent (e.g. high → left)
- 0.75–1.0 (opposite geometry): diagonal toward opposite, then opposite

### Data Additions

- `LINE_ANGLE_DEG`: add rows/cols for high_left, high_right, low_left, low_right
- `ATTACK_PATHS_BY_GUARD`: add paths for diagonals (e.g. average of high and left paths)
- `LINE_TO_DEFAULT_PART`: map diagonals to a part (e.g. high_left → head or left_arm)
- `LINE_ADJACENTS` / `LINE_ANGLE_DEG`: define adjacency for 8 lines

### Pros / Cons

| Pros | Cons |
|------|------|
| No API changes for consumers | 2× line count, more tables |
| Still discrete, easy to reason about | Diagonals are coarse (22°, 45°, 67°) |
| Natural "halfway" positions | Need path/angle entries for 4 new lines |
| | Guard transition cost needs 8-line angles |

---

## Approach 3: Continuous Deflection Angle

### Model

Store:
- `guard_line` — **resolved cardinal** (for legacy).
- `guard_deflection_deg` — **0–90**. Angular displacement from attack line.
- `guard_deflection_direction` — which cardinal we're deflected toward (or derive from geometry).

**Computation:**
```
deflection_deg = severity × geometry_max_deg
# geometry_max: same=0, adjacent=45, opposite=90
```

Then **effective line** for consumers:
- Map angle to nearest cardinal (or diagonal) for path/alignment.
- Or: compute effective alignment from actual angle:
  ```
  # attack from high (0°), deflected 30° toward left
  # effective guard angle = 30° from high toward left
  # alignment to "low" attack = cos(90 - 30) or similar
  ```

**Angle → effective alignment for any attack_line:**
- Define attack_line angles: high=0°, right=90°, low=180°, left=270° (or NSEW).
- guard_angle = attack_angle + deflection_deg * direction_sign.
- alignment(guard, attack) = cos(guard_angle - attack_angle).

### Pros / Cons

| Pros | Cons |
|------|------|
| Truly continuous deflection | Requires angle-based alignment formula |
| Physically intuitive | Refactor of get_line_alignment |
| Can drive animation/visuals | guard_line derivation from angle |
| | Path lookup: angle → line mapping needed |

---

## Approach 4: Deflection Severity as State (Minimal)

### Model

Keep **guard_line** as current (discrete resolve from geometry + severity).
Add **deflection state** only for downstream effects:

- `guard_deflection_severity` — 0.0–1.0. How "fully" deflected the blade is.
  - 0 = bind (blade settled in line)
  - 0.5 = partial (blade between)
  - 1 = full deflect (blade in new line)

**Usage:** Modulate recovery, riposte, or next attack cost. Does **not** change guard_line for path/alignment. Blade position stays discrete; "softness" is only in timing/readiness.

**Computation:** From clash severity, control, geometry. Same inputs as Approach 1 but we don't store deflect_toward — only a 0–1 severity that affects other systems (e.g. `recovery_duration *= 1.0 + 0.2 * deflection_severity`).

### Pros / Cons

| Pros | Cons |
|------|------|
| Very small change | Blade position still binary |
| Adds "soft" feel to mechanics | No finer weapon tracking |
| No consumer changes | Partial deflect not visible in guard |
| | |

---

## Approach 5: Probabilistic Resolve (Softer Without New Fields)

### Model

Instead of deterministic 0 / 45 / 90°, use **weighted random** over outcomes:
- severity low: 70% bind, 25% adjacent, 5% opposite
- severity mid: 25% bind, 55% adjacent, 20% opposite
- severity high: 5% bind, 35% adjacent, 60% opposite

(Respect geometry cap: adjacent defender never gives opposite.)

**Result:** Same `guard_line` (discrete), but distribution of outcomes is softer across many parries. No new fields. Individual outcomes still binary; aggregate behavior is smoother.

### Pros / Cons

| Pros | Cons |
|------|------|
| No new fields or consumer changes | Still binary per event |
| Softer distribution over time | Randomness may feel arbitrary |
| Easy to implement | No "partial" in a single clash |
| | |

---

## Approach 6: Hybrid — Blend for Alignment, Discrete for Path

### Model

1. **guard_line** — Resolved discrete line (as now).
2. **guard_deflect_blend** — 0–1, how far toward that line from attack line.
   - Only meaningful when guard_line ≠ attack_line (we deflected).
   - 0.3 = blade 30% of the way to deflect line (partial).
3. **Alignment:** Use blended alignment when blend is provided:
   ```
   effective_align = lerp(align(attack, attack_line), align(attack, guard_line), deflect_blend)
   ```
   - Partial deflect (blend=0.3): alignment is 30% toward deflected position.
4. **Path:** Keep discrete guard_line for path lookup (no path for "30% high 70% left").
5. **guard_zone:** From guard_line (primary). Blend doesn't change zone.

**Resolving deflect_blend from severity:**
- For opposite geometry: severity 0.5 → blend 0.5 (partial to adjacent), severity 1.0 → blend 1.0 (full opposite).
- For adjacent geometry: severity directly = blend (max 45° is always "full" for that geometry).

### Pros / Cons

| Pros | Cons |
|------|------|
| Alignment becomes softer | Path stays discrete |
| Partial deflection affects parry/riposte math | One extra field |
| Path/zone logic unchanged | Blend only for deflect case |
| Clean separation of concerns | |

---

## Consumer Impact Summary

| Consumer | Approach 1 | Approach 2 | Approach 3 | Approach 4 | Approach 5 | Approach 6 |
|----------|------------|------------|------------|------------|------------|------------|
| get_line_alignment | New overload/params | 8-line table | Angle-based | None | None | Blended align |
| get_attack_path | None (use primary) | 8 paths | Angle→line | None | None | None |
| DIAGONAL_WEIGHTS | None | 8-line keys | Angle→line | None | None | None |
| LINE_TO_DEFAULT_PART | None | 4 new entries | Angle→line | None | None | None |
| AttackWindUpStarter | Optional blend align | As-is | As-is | Severity mod | As-is | Optional blend align |
| AttackPathResolver | Optional blend align | As-is | As-is | None | As-is | Optional blend align |
| GuardLineUpdater | Set blend fields | Set 8-line | Set angle | Set severity | As-is | Set blend |

---

## Recommendation

**Preferred: Approach 6 (Hybrid)**

1. Minimal surface area: one new field `guard_deflect_blend`.
2. Keeps path/zone/legacy logic on discrete `guard_line`.
3. Makes alignment continuous via blend for deflect cases.
4. Partial deflections (e.g. 30°, 60°) map to blend values and change parry capacity, intercept, wind-up cost.
5. Easy to extend later with Approach 1’s `deflect_toward` if needed.

**Fallback: Approach 5 (Probabilistic)** if you want no new fields and are okay with binary outcomes per clash but softer distributions over time.

**Future: Approach 3 (Continuous Angle)** for full weapon tracking and animation; would need a dedicated angle-based alignment and path model.

---

## Implementation Sketch: Approach 6

### 1. CombatConstants

```gdscript
# Deflection blend: 0 = bind/settled in attack line, 1 = fully in deflect line.
# When guard_line != attack_line, blend indicates how far blade moved (partial vs full).
const PARRY_DEFLECT_BLEND_SEVERITY_SCALE := 1.0  # severity → blend mapping
```

### 2. GuardLineUpdater.set_guard_deflected

- Accept `clash_context` with `severity` or `deflect_blend`.
- Resolve `guard_line` (discrete) from geometry + severity (as in prior investigations).
- Set `guard_deflect_blend`:
  - If bind (guard_line == attack_line): 0.
  - If deflect: `blend = clamp(severity, 0, 1)` or from `parry_control` inverse.

### 3. get_line_alignment (optional soft overload)

```gdscript
static func get_line_alignment(attack_line: String, guard_line: String, deflect_blend: float = 0.0, deflect_from_line: String = "") -> float:
    var align := _get_line_alignment_inner(attack_line, guard_line)
    if deflect_blend <= 0 or deflect_from_line.is_empty():
        return align
    var align_from := _get_line_alignment_inner(attack_line, deflect_from_line)
    return lerpf(align_from, align, deflect_blend)
```

(When deflect_blend=1, we're in guard_line; when 0, we're in deflect_from_line. Adjust lerp direction to match your convention.)

### 4. Combatant schema

```gdscript
# Existing
"guard_line": "high"

# New (optional)
"guard_deflect_blend": 0.0   # 0–1, only set after parry_deflect
"guard_deflect_from": ""     # attack line we came from (for blend)
```

### 5. Consumers

- `get_line_alignment`: Add optional `deflect_blend` and `deflect_from` from combatant when present.
- AttackWindUpStarter, AttackPathResolver, DefenseChoiceResolver: Pass blend when reading defender guard.
- Reset `guard_deflect_blend` to 0 when blade is "settled" (e.g. after recovery, or after next action).

---

## References

- DEFLECTION_PHYSICS_SEVERITY_INVESTIGATION.md
- HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md
- HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md
