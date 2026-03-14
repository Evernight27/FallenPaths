# Guard Positions, Attack Angles, and 45°/90° Physics Investigation

## Purpose

Verify that the 45° and 90° angles, guard positions, attack lines, and deflection outcomes are **physically consistent** and correctly wired together.

---

## 1. Current Geometry Model

### 1.1 Four Lines (Attack & Guard)

| Line | Physical Meaning | Liechtenauer Equivalent |
|------|------------------|-------------------------|
| **high** | Blade from above / upward position | Vom Tag, Ochs, Plough (high) |
| **low** | Blade from below / downward position | Alber, Pflug (low), Ox |
| **left** | Blade from left / left-side position | Left Nebenhut, Zwerchau |
| **right** | Blade from right / right-side position | Right Nebenhut |

### 1.2 Topology: Cross (Vertical + Horizontal Axes)

```
        high
          |
    left--+--right
          |
         low
```

- **Opposite pairs:** high↔low (vertical), left↔right (horizontal)
- **Adjacent pairs:** high↔left, high↔right, low↔left, low↔right

### 1.3 LINE_ANGLE_DEG (Blade Orientation at Contact)

| Defender \ Attack | high | low | left | right |
|-------------------|------|-----|------|-------|
| high | **0** | 90 | 45 | 45 |
| low | 90 | **0** | 45 | 45 |
| left | 45 | 45 | **0** | 90 |
| right | 45 | 45 | 90 | **0** |

**Physical interpretation:** Angle between blade orientations at contact.
- **0°**: Same line — blades parallel/same plane. Best parry (bind).
- **45°**: Diagonal — defender's blade at 45° to attack. Partial alignment (lateral shed).
- **90°**: Perpendicular — defender's blade orthogonal to attack. Block from opposing axis.

**Alignment:** `cos(θ)` → 1.0 (same), 0.707 (adjacent), 0.0 (opposite)

### 1.4 LINE_ADJACENTS

```gdscript
{"high": ["left", "right"], "low": ["left", "right"], "left": ["high", "low"], "right": ["high", "low"]}
```

**Consistency check:** high/low share adjacents [left, right]; left/right share adjacents [high, low]. ✓ Matches cross topology.

---

## 2. Deflection Logic

### 2.1 get_deflected_line_from_geometry(attack_line, defender_guard_line)

| Condition | Result | Angular Displacement |
|-----------|--------|----------------------|
| attack_line == defender_guard_line | **Bind** (same line) | 0° |
| defender_guard_line in adjacents of attack_line | **Lateral** (other adjacent) | 45° |
| defender_guard_line opposite | **Strong block** (opposite line) | 90° |

### 2.2 DEFLECTED_GUARD_FROM_ATTACK (Opposite Mapping)

```gdscript
{"high": "low", "low": "high", "left": "right", "right": "left"}
```

**Consistency:** Matches LINE_ADJACENTS topology — high/low and left/right are opposite pairs. ✓

### 2.3 Lateral Deflection (Adjacent → Other Adjacent)

**Example:** High attack, defender parries from left.
- Defender's blade is on the left (45° to attack).
- Blade gets "shed" away from defender's blade → deflects to **right**.
- Right is the "other adjacent" of high (adjacents = [left, right]). ✓

**Example:** Left attack, defender parries from high.
- Defender's blade is high (45° to attack).
- Shed away from high → deflects to **low** (other adjacent of left). ✓

---

## 3. Physics Verification

### 3.1 Same-Line (0°) → Bind

**HEMA:** Oberhau parries Oberhau → both end in Plough. Blades in same line.
**Physics:** Blades meet with parallel orientations; force is along the line. No angular deflection. ✓

### 3.2 Adjacent (45°) → Lateral Deflection (45° displacement)

**HEMA:** "Cut behind the incoming blade" — lateral shed. Force applied across the path.
**Physics:** Defender's blade at 45° applies perpendicular component. Blade diverts to the side. Angular displacement ≈ 45° (to the "other adjacent"). ✓

### 3.3 Opposite (90°) → Strong Block (90° displacement)

**HEMA:** Strong block from below on Oberhau drives blade down. Head-on impact.
**Physics:** Defender's blade perpendicular to attack. Force drives attacker's blade through to opposite side. ✓

### 3.4 Why 45° and 90°?

- **cos(0°) = 1** — perfect alignment
- **cos(45°) = 0.707** — partial; reflects "diagonal" contact
- **cos(90°) = 0** — worst; reflects perpendicular blocking

The 45° for "adjacent" is an empirical choice: it gives alignment ≈ 0.7, which models "can parry but not as well as same-line." The exact angle varies in real contact; 45° is a reasonable discretization.

---

## 4. Data Flow Integrity

### 4.1 Move Definitions → attack_line

| Move | attack_line | Notes |
|------|-------------|-------|
| thrust, oberhau, overhead_chop, pommel_strike | high | Downward/forward |
| unterhau | low | Upward |
| slash, diagonal_chop, quick_slash | left | Horizontal/diagonal |
| side_strike | right | From right |

**Diagonal moves:** oberhau, unterhau, diagonal_chop, slash use DIAGONAL_WEIGHTS to resolve effective_attack_line. The primary attack_line in the move def is the "base" for the roll. ✓

### 4.2 PART_TO_LINE and LINE_TO_DEFAULT_PART

```gdscript
PART_TO_LINE: head→high, chest→high, left_arm→left, right_arm→right, left_leg→low, right_leg→low
LINE_TO_DEFAULT_PART: high→head, low→left_leg, left→left_arm, right→right_arm
```

**Consistency:** Body parts map to lines; lines map back to default parts. Symmetry: high↔head/chest, low↔legs, left↔left_arm, right↔right_arm. ✓

### 4.3 ATTACK_PATHS and ATTACK_PATHS_BY_GUARD

Paths use attack_line and guard_line. Both are from {high, low, left, right}. ✓

### 4.4 DODGE_END_GUARD_FROM_ATTACK

```gdscript
{"high": "low", "low": "high", "left": "right", "right": "left"}
```

Dodge moves defender to "opposite" — e.g. duck high attack → end in low. Same as DEFLECTED_GUARD_FROM_ATTACK. ✓

---

## 5. Potential Issues and Edge Cases

### 5.1 Diagonal Moves and effective_attack_line

**Oberhau** has attack_line "high" but crosses high+left. DIAGONAL_WEIGHTS rolls for effective_attack_line ∈ {high, low, left, right}. The geometry then uses effective_attack_line. ✓ Correct.

### 5.2 get_deflected_line_with_severity — Adjacent Choice

When opposite-defender and low severity, we return `adj[0]` (first adjacent). For high attack, adjacents = [left, right]. We always pick left. **Asymmetry:** Should we pick based on defender's side? E.g. defender left → deflect to right (away). Currently we pick deterministically. **Minor:** Could add defender-aware choice for slightly more realism.

### 5.3 slash attack_line = "left"

A horizontal slash can come from either side. Mapping to "left" is arbitrary; the geometry still works. If defender guards "right", we get 90° (opposite). ✓

### 5.4 Thrust attack_line = "high"

Thrust is forward; we map to "high" (point-forward). Spear thrust same. The 4-line model treats "high" as the forward/vertical axis. ✓

---

## 6. Symmetry and Completeness

### 6.1 LINE_ANGLE_DEG Symmetry

angle(attack, guard) should equal angle(guard, attack). Check:
- high vs low = 90, low vs high = 90 ✓
- high vs left = 45, left vs high = 45 ✓
- left vs right = 90, right vs left = 90 ✓

All pairs symmetric. ✓

### 6.2 Adjacency Symmetry

If A is adjacent to B, then B is adjacent to A.
- high adjacent to left → left adjacent to high ✓
- high adjacent to right → right adjacent to high ✓

LINE_ADJACENTS is symmetric. ✓

### 6.3 Deflection Coverage

For every (attack_line, defender_guard_line):
- Same line → bind (attack_line)
- Adjacent → one of the two adjacents (the "other" one)
- Opposite → DEFLECTED_GUARD_FROM_ATTACK[attack_line]

All cases covered. ✓

---

## 7. Summary: Physics and Wiring

| Component | Status | Notes |
|------------|--------|------|
| LINE_ANGLE_DEG | ✓ Correct | 0/45/90 match alignment cos(θ); symmetric |
| LINE_ADJACENTS | ✓ Correct | Cross topology; symmetric |
| DEFLECTED_GUARD_FROM_ATTACK | ✓ Correct | Opposite pairs consistent |
| get_deflected_line_from_geometry | ✓ Correct | Same→bind, adjacent→lateral, opposite→through |
| Move attack_line | ✓ Correct | All moves map to 4 lines |
| PART_TO_LINE / LINE_TO_DEFAULT_PART | ✓ Correct | Body ↔ line consistent |
| DIAGONAL_WEIGHTS | ✓ Correct | Diagonal moves resolve to 4 lines |
| ATTACK_PATHS_BY_GUARD | ✓ Correct | Uses same 4 lines |

### Recommendations

1. **No changes required** for core geometry — the model is internally consistent and physically grounded.
2. **Optional refinement:** In `get_deflected_line_with_severity`, when returning adjacent for low-severity opposite-defender case, consider deflecting "away from defender" (e.g. defender left → deflect to right) instead of always `adj[0]`. Would require passing defender_guard_line into the adjacent choice.
3. **Documentation:** Add a comment in CombatConstants above LINE_ANGLE_DEG and LINE_ADJACENTS explaining the cross topology and the physical interpretation (blade orientation at contact).

---

## References

- PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md
- HEMA 101: Parries, Binds and Winds
- Sword STEM: Vector Transformations
- CombatConstants.gd (LINE_ANGLE_DEG, LINE_ADJACENTS, DEFLECTED_GUARD_FROM_ATTACK)
