# Glancing Recovery: Method A vs Method B Investigation

Comparison of two approaches for scaling glancing-hit recovery by physics.

---

## Physical Model

**Glancing hit:** Blade meets armor at an angle; some damage gets through, but the blade doesn't fully "bite." Momentum transfer is partial.

- **More glancing** (less damage through): Blade slides off quickly; less stopping force; attacker retains more momentum → **longer recovery**.
- **Less glancing** (more damage through): Blade connects more; more momentum transferred to target → **shorter recovery**.

**Commitment (intensity):** Heavier swing = more total momentum. When that swing glances, more momentum is retained regardless of how "glancing" it was.

---

## Method A: Linear Commitment Scale

**Formula:** `extra = base + scale × commitment`

**Data used:** Intensity (commitment) only. No damage pipeline coupling.

**Physics:** Commitment correlates with total momentum. Heavier swing → longer recovery when it glances. Single-factor model.

**Pros:**
- Matches deflect/full_stop pattern; consistent with existing code.
- No new parameters from damage pipeline; `_recovery_duration` stays simple.
- Easy to tune; one extra constant.

**Cons:**
- Ignores *how* glancing the hit was. A heavy swing that almost bites (near solid hit) gets the same recovery as one that barely skims.
- Two different glancing hits with same commitment get identical recovery.

---

## Method B: Blended by Impact Severity

**Formula:** `extra = base + (1 - glancing_severity) × commitment_scale`  
where `glancing_severity = tissue_dmg / (pre_armor × GLANCING_DAMAGE_RATIO)` (0–1 within glancing band).

**Data used:** `tissue_dmg`, `pre_armor` from damage pipeline. Requires passing optional `glancing_severity` to `_recovery_duration`.

**Physics:**
- Low severity (almost deflected): Blade barely connected; attacker retains most momentum → longer recovery.
- High severity (borderline hit): Blade connected more; more momentum transferred → shorter recovery.
- Commitment still matters: scale term multiplies by `(1 - severity)`, so high-commitment + low-severity = longest recovery.

**Pros:**
- Uses actual impact outcome; models "how much got through."
- Different glancing hits produce different recoveries.
- More accurate for edge cases (almost-deflect vs almost-hit).

**Cons:**
- Couples recovery to damage pipeline; must pass `glancing_severity`.
- `_recovery_duration` needs optional param; `compute_and_apply_damage` must compute and pass it.
- `tissue_dmg / (pre_armor × 0.25)` can be > 1 if edge cases; needs clamp.
- Slightly more code paths.

---

## Data Flow Comparison

| Step | Method A | Method B |
|------|----------|----------|
| compute_and_apply_damage | Computes outcome ("glancing") | Computes outcome + glancing_severity |
| Call to _recovery_duration | `(intensity, outcome)` | `(intensity, outcome, glancing_severity)` |
| _recovery_duration | `if outcome == "glancing": extra = base + scale*commitment` | `if outcome == "glancing": extra = base + (1-severity)*scale*commitment` |

---

## Accuracy Verdict

| Criterion | Method A | Method B |
|-----------|----------|----------|
| **Momentum retention** | Via commitment only | Via severity + commitment |
| **Impact-specific** | No | Yes |
| **Edge cases** | Same recovery for all glancing at given commitment | Differentiates almost-deflect vs almost-hit |
| **Physical fidelity** | Good (one factor) | Better (two factors) |

**Recommendation:** Method B is more physically accurate because it uses the actual damage outcome (tissue/pre_armor ratio) to model how much momentum was transferred. Method A is simpler and "good enough" if you prefer minimal coupling. For maximum realism, Method B.

**Implemented:** Method B — `glancing_severity` computed in `compute_and_apply_damage`, passed to `_recovery_duration`. Formula: `extra = 0.12 + (1 - severity) * 0.2 * commitment`.

---

## Implementation Notes for Method B

1. In `compute_and_apply_damage`, when `outcome == "glancing"`:
   ```gdscript
   var glancing_severity := clampf(tissue_dmg / (pre_armor * manager.GLANCING_DAMAGE_RATIO), 0.0, 1.0)
   ```

2. Extend `_recovery_duration(intensity, outcome, ...)` with optional `glancing_severity: float = -1.0`. When `outcome == "glancing"` and `glancing_severity >= 0`, use blended formula.

3. Constants: `RECOVERY_EXTRA_GLANCING_BASE_S`, `RECOVERY_GLANCING_SEVERITY_SCALE_S` (or similar). Example: `extra = 0.12 + (1.0 - glancing_severity) * 0.2 * commitment`.
