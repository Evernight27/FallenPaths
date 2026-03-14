# Attacking, Binding, and Attack Angle — Improvement & Consistency Investigation

## Purpose

Investigate how attacking, binding, and attack angle can be improved, eliminate duplication, and ensure the angle-based systems are properly used across the combat system.

---

## 1. Current Architecture Summary

### 1.1 Alignment Flow

| Call Site | Function Used | Angle Context? | Purpose |
|-----------|---------------|---------------|---------|
| AttackResolver (hit) | `get_line_alignment_with_deflect` | ✓ align_ctx with atk_angle, guard_angle | Hit alignment for damage |
| AttackPathResolver | `get_line_alignment_with_deflect` | ✓ alignment_context passed | Path intercept, hit part |
| DefenseResolutionHandler | `get_line_alignment_with_deflect` | ✓ _align_ctx from arc + guard | Parry capacity |
| DefenseChoiceResolver | `get_line_alignment_with_deflect` (via _get_line_alignment) | ✓ align_ctx when available | Parry choice |
| AttackWindUpStarter | `get_line_alignment_with_deflect` | ✓ align_ctx (intended line vs guard) | Guard transition cost |
| AttackResultApplier (parry_partial) | `get_line_alignment_with_deflect` | ✓ when attack_angle_deg present | Partial parry guard update |
| CombatAIActionPicker | `get_line_alignment_with_deflect` | ✗ no alignment_context | Path segment for target_part |

### 1.2 Deflection/Bind Flow

| Component | Uses | Notes |
|-----------|------|-------|
| GuardLineUpdater.set_guard_deflected | `get_deflected_line_from_angles` when clash_context present | Angle-based, bilateral |
| GuardLineUpdater.set_guard_deflected | `DEFLECTED_GUARD_FROM_ATTACK` when no def_guard | Fallback: opposite line |
| get_deflected_line_from_geometry | **Never called** | Dead code |
| get_deflected_line_with_severity | **Never called** | Dead code |

### 1.3 Angle Propagation

- **AttackResolver**: Rolls `attack_angle_deg` with variance (stamina, off_balance, mass), stores `arc_start_deg`, `arc_end_deg`, `arc_span_deg`.
- **DefenseResolutionHandler**: Uses `get_arc_angle_at_progress(arc_start, arc_end, parry_progress)` for blade position at contact.
- **parry_clash_context**: Contains `attack_angle_deg`, `alignment`, `defender_guard_line`, `severity`, `parry_control` — but **not** `guard_angle_deg`.

---

## 2. Findings: Duplication & Inconsistency

### 2.1 Dead Code in CombatConstants

**`get_deflected_line_from_geometry`** and **`get_deflected_line_with_severity`** are never invoked. GuardLineUpdater uses:

1. `get_deflected_line_from_angles` when `clash_context` has data (angle-based)
2. `DEFLECTED_GUARD_FROM_ATTACK` in the fallback branch when `defender_guard_line` is empty

**Recommendation:** Remove or deprecate these functions. They duplicate logic now handled by `get_deflected_line_from_angles`, which uses continuous angles and severity correctly.

### 2.2 GuardLineUpdater Alignment Source

When `clash_context` has `attack_angle_deg`:

```gdscript
var alignment: float = clash_context.get("alignment", CombatConstants.get_line_alignment(atk_line, def_guard))
```

- `alignment` from clash_context is **angle-based** (from DefenseResolutionHandler).
- Fallback `get_line_alignment(atk_line, def_guard)` is **discrete** (LINE_ANGLE_DEG).
- For deflection, `guard_angle` is derived as `line_to_angle(def_guard)` — discrete mapping.

**Issue:** parry_clash_context does not include `guard_angle_deg`. The exact angle used at parry (including wobble) is not passed. GuardLineUpdater reconstructs it from the defender's line. This is acceptable but could be made consistent by passing the same angles used in parry resolution.

### 2.3 CombatAIActionPicker Alignment

```gdscript
var alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt)
```

No `alignment_context` is passed. This means:

- Falls back to `get_line_alignment(attack_line, guard_line)` when no deflect blend
- Or uses deflect blend from `guard_deflect_blend` when defender recently deflected

**Issue:** AI uses discrete alignment. It could pass `alignment_context` with `guard_angle_deg` from `get_guard_angle_deg(tgt)` and `attack_angle_deg` from `line_to_angle(attack_line)` to get angle-based alignment for path segment selection. Effort: low.

### 2.4 Bind vs Deflect: Current vs Potential

| Aspect | Current | Potential (from BIND_TEMPO doc) |
|--------|---------|----------------------------------|
| Bind outcome | `guard_line = attack_line` (blade stays) | Bind angle blend: `lerp(attack_angle, guard_angle, 0.5)` |
| parry_control | ≥0.65 → bind | Same; could add P(bind) curve |
| Riposte from bind | Implicit (guard = attack line) | Method A: wind-up mult; Method D: guard transition mult |

---

## 3. Recommendations

### 3.1 High Priority: Eliminate Duplication

**Remove dead deflection functions** (or mark deprecated):

- `get_deflected_line_from_geometry` — superseded by `get_deflected_line_from_angles`
- `get_deflected_line_with_severity` — severity logic is in `get_deflected_line_from_angles` via `get_deflection_magnitude_deg`

If removal is desired, verify no external/callers; grep shows only docs reference them.

### 3.2 Medium Priority: Consistency

**A. Add `guard_angle_deg` to parry_clash_context**

In DefenseResolutionHandler, when building `parry_clash_context`, add:

```gdscript
"guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt, _wobble)
```

GuardLineUpdater can then use it for `get_deflected_line_from_angles` instead of `line_to_angle(def_guard)`, ensuring the same angle (including wobble) used at parry resolution.

**B. CombatAIActionPicker angle-based alignment**

When picking target_part, pass alignment_context:

```gdscript
var align_ctx: Dictionary = {}
if tgt.get("guard_line", "").length() > 0:
    align_ctx = {
        "attack_angle_deg": CombatConstants.line_to_angle(atk_line),
        "guard_angle_deg": CombatConstants.get_guard_angle_deg(tgt)
    }
var alignment: float = CombatConstants.get_line_alignment_with_deflect(atk_line, tgt, align_ctx)
```

This gives AI the same angle-based path segment logic as AttackPathResolver.

### 3.3 Lower Priority: Bind & Angle Improvements

**C. Bind angle blend** (BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md)

When `parry_control >= PARRY_BIND_CONTROL_THRESHOLD`, instead of `line = atk_line` (discrete), compute:

```gdscript
var bind_angle: float = lerpf(atk_angle, guard_angle, 0.4 + 0.3 * parry_control)
line = CombatConstants.angle_to_nearest_line(bind_angle)
```

Requires `guard_angle_deg` in clash_context (recommendation A).

**D. P(bind) probability curve** (ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION Approach E)

Replace threshold with roll:

```gdscript
var bind_chance := clampf(alignment * parry_control * 1.2, 0.0, 1.0)
if randf() < bind_chance:
    outcome = "bind"
```

Currently: deterministic. Would add variance.

**E. Intercept variance** (Approach E)

In AttackPathResolver, when alignment is mid-range (0.3–0.8):

```gdscript
if alignment > 0.25 and alignment < 0.85:
    intercept_max += roundi(randfn(0.0, 0.5))
```

---

## 4. Verification Checklist

| Check | Status |
|-------|--------|
| AttackResolver uses angle-based align_ctx for hit | ✓ |
| AttackPathResolver receives alignment_context with angles | ✓ |
| DefenseResolutionHandler uses arc angle at contact | ✓ |
| GuardLineUpdater uses get_deflected_line_from_angles when clash has data | ✓ |
| parry_clash_context includes guard_angle_deg | ✗ — add |
| CombatAIActionPicker uses angle-based alignment | ✗ — add |
| get_deflected_line_from_geometry used | ✗ — dead |
| get_deflected_line_with_severity used | ✗ — dead |

---

## 5. Summary

1. **Angle system is integrated** in AttackResolver, AttackPathResolver, DefenseResolutionHandler, AttackWindUpStarter, and AttackResultApplier. Alignment and deflection use continuous angles when context is available.

2. **Duplication:** Two deflection functions (`get_deflected_line_from_geometry`, `get_deflected_line_with_severity`) are dead; remove or deprecate.

3. **Gaps:** parry_clash_context should include `guard_angle_deg`. CombatAIActionPicker could use alignment_context for angle-based path selection.

4. **Bind improvements:** Bind angle blend and P(bind) curve are optional next steps per existing investigation docs.

---

## References

- ENHANCED_BLADE_TRAJECTORY_ANGLE_INVESTIGATION.md
- BIND_TEMPO_WEAPON_POSITIONING_INVESTIGATION.md
- ANGLE_SYSTEM_INTEGRATION_STATUS.md
- PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md
