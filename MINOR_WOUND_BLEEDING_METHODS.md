# Minor Wound Bleeding: Method Comparison

Goal: make minor wounds clot faster so they align with real life (“small cuts may stop in seconds”) while keeping the existing exponential clotting model and severity ladder.

---

## Current Behavior

- **Minor** and **moderate** both use clotting multiplier **1.0** (same as base).
- Base clotting: `k = 0.02` → half-life ~35 s, time to ~1% rate ~4 min.
- So minor wounds currently take ~4 min to “effectively stop,” same as moderate.

---

## Method 1: Clotting multiplier > 1 for minor (recommended)

**Idea:** Add a **minor** entry in `CLOTTING_SEVERITY_MULTIPLIERS` with value **> 1** so minor wounds use a higher effective k.

| Multiplier | Effective k | Half-life | Time to ~1% rate |
|------------|-------------|-----------|------------------|
| 1.5        | 0.03        | ~23 s     | ~2.5 min         |
| 2.0        | 0.04        | ~17 s     | ~2 min           |
| 2.5        | 0.05        | ~14 s     | ~1.5 min         |
| 3.0        | 0.06        | ~12 s     | ~1.2 min         |

**Implementation:**

- In `BleedingConstants.gd`: set `SEVERITY_MINOR: 1.5` (or 2.0) in `CLOTTING_SEVERITY_MULTIPLIERS`.
- In `CoreEntity.gd` `process_bleeding`: use `clotting *= _Bleeding.get_clotting_multiplier(sev)` for all severities instead of hardcoding critical/severe only.

**Pros:** One place to tune (constants); same exponential model; minor/moderate/severe/critical stay on one ladder; medically plausible (superficial = faster hemostasis).  
**Cons:** None significant.

---

## Method 2: Lower initial bleeding rate only (no clotting change)

**Idea:** Minor already has lower `BLEEDING_RATES` (e.g. cut minor 0.35 vs moderate 1.2). Leave clotting at 1.0; optionally reduce minor base rates further so total blood lost before “stop” is smaller.

**Effect:** Time to reach 1% of *initial* rate is unchanged (~4 min). Only the *magnitude* of bleeding (and thus blood loss over that period) is lower. “Stop in seconds” is not achieved.

**Pros:** No clotting logic change; minor wounds already bleed less.  
**Cons:** Does not address “small cuts stop in seconds”; minor still takes ~4 min to clot.

**Verdict:** Good for “minor hurts less” but not for “minor stops faster.” Use only if you explicitly do **not** want faster clotting for minor.

---

## Method 3: Fixed “stop after X seconds” for minor

**Idea:** If severity is minor and wound has been bleeding for at least **T** seconds (e.g. 30–60), set `current_bleeding_rate = 0` and remove the wound (or force rate to 0 next tick).

**Implementation:** Store `created_at` or `bleeding_duration_seconds` per injury; in `process_bleeding`, if minor and duration >= T, set rate to 0 (or remove).

**Pros:** Predictable “minor always stops by T”; easy to tune T (e.g. 45 s).  
**Cons:** Abrupt stop (not smooth decay); adds per-wound state; doesn’t scale with arterial (minor arterial would still need special handling); more gamey than physiological.

**Verdict:** Use if you want a hard cap on minor bleed duration; otherwise Method 1 is cleaner.

---

## Method 4: Negligible-rate threshold (remove wound when rate tiny)

**Idea:** Wounds are only removed when `rate <= 0.0` today; with exponential decay rate never hits 0. Add a threshold: if `rate < BLEEDING_RATE_EPSILON` (e.g. 0.001), treat as 0 and remove wound.

**Effect:** All severities “stop” sooner in practice (when rate drops below epsilon). Minor wounds, having the smallest initial rate, will cross the threshold soonest. No explicit “minor only” logic.

**Pros:** Simple; no new constants for severity; fixes possible “wounds never removed” if float never underflows.  
**Cons:** Does not specifically speed up minor; minor still clots at same k, so time to epsilon is still ~4 min unless initial rate is very small (then minor might disappear in 1–2 min because rate starts low).

**Verdict:** Good as a **complement** to Method 1 (use epsilon so wounds are reliably removed). Alone it does not make “minor stop in seconds” unless minor rates are very low.

---

## Method 5: Two-phase clotting (fast then normal) for minor

**Idea:** For minor only, use a higher k for the first **T** seconds (e.g. 0.08 for 30 s), then switch to base k (0.02). Simulates “quick platelet plug, then slower fibrin.”

**Implementation:** Per injury: `fast_phase_remaining_seconds` (e.g. 30 for minor, 0 for others). Each tick, if fast phase > 0, use high k and decrement; else use normal k.

**Pros:** Can match “stops in seconds” (first phase) then slow tail if needed.  
**Cons:** More state and branching; two time constants to tune; likely overkill vs Method 1.

**Verdict:** Only consider if you want an explicit “fast initial, then slow” curve for minor; otherwise Method 1 is simpler and close enough.

---

## Method 6: Severity-specific base clotting constant

**Idea:** Instead of one `CLOTTING_RATE_BASE` and severity *multipliers*, define a separate clotting rate per severity, e.g. `CLOTTING_RATE_MINOR = 0.05`, `CLOTTING_RATE_MODERATE = 0.02`, etc.

**Pros:** Maximum flexibility per severity.  
**Cons:** More constants; same behavior as Method 1 can be achieved with multipliers (e.g. minor 2.5× base); current multiplier design already supports “minor > 1” without changing the base.

**Verdict:** Method 1 (multiplier for minor) is equivalent and keeps a single base rate; prefer Method 1 unless you want different *absolute* rates per severity rather than ratios.

---

## Summary

| Method | Makes minor stop faster? | Complexity | Fits current model? | Recommendation |
|--------|---------------------------|------------|----------------------|-----------------|
| 1. Clotting mult > 1 for minor | Yes | Low | Yes | **Recommended** |
| 2. Lower rate only | No (same time to stop) | None | Yes | Only if you don’t want faster clotting |
| 3. Fixed stop after T s | Yes | Medium | Partial (new state) | Optional; Method 1 is smoother |
| 4. Negligible-rate threshold | Slightly (indirect) | Low | Yes | **Use with Method 1** for clean removal |
| 5. Two-phase for minor | Yes | High | Yes but more code | Overkill vs Method 1 |
| 6. Per-severity k | Yes | Low | Yes | Same idea as Method 1, more constants |

**Practical choice:** Implement **Method 1** (e.g. `SEVERITY_MINOR: 1.5` or `2.0` in `CLOTTING_SEVERITY_MULTIPLIERS` and use `get_clotting_multiplier(sev)` in `process_bleeding`). Optionally add **Method 4** (e.g. `BLEEDING_RATE_EPSILON = 0.001`) so wounds are removed once rate is negligible instead of relying on underflow.
