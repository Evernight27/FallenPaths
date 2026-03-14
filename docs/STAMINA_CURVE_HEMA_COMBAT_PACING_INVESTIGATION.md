# Stamina Curve, HEMA/Medieval Combat Pacing & System Balance Investigation

## Purpose

1. Ensure all stamina-dependent systems use a **non-linear fatigue curve** for physics-based realism.
2. Compare **HEMA combat** and **medieval warfare** pacing (combat length, time between blows, engagements) with the current system.
3. Propose balanced constants and structural changes.

---

## 1. HEMA & Medieval Combat Research Summary

### 1.1 Time Between Blows / Technique Duration

| Context | Duration | Source |
|---------|----------|--------|
| **Explosive cut** (as fast as possible, minimal telegraph) | 250–350 ms | Science & Fiction: Medieval Swordfighting |
| **Standard cut** (synchronized with footwork, telegraphed) | 600 ms or longer | Same |
| **Human reaction time** | ~250 ms | General |
| **Implication** | Explosive cuts land before defender can react; standard cuts give ample warning | |

**Fallen Paths comparison:** Wind-up = 0.25 + 0.6×intensity ≈ 0.5–0.85 s (before leg/perf/agi). Closer to "standard cut" pace than explosive. Effective wind-up (×0.8) for parry reaction = 0.4–0.68 s — defender has time to react when using standard attacks.

### 1.2 Combat Length & Fatigue

| Context | Duration / Pattern | Source |
|---------|-------------------|--------|
| **High-intensity sword fighting** (max pace) | No one sustains > ~5 min; exhaustion in <1 min possible | Quora / medieval combat research |
| **Medieval duel reality** | Slow, positional movement; rare intense bursts of 2–3 strikes | Same |
| **Limiting factor** | Often mental endurance (concentration to avoid decisive strike) over pure physical stamina | Same |
| **Armored combat** | Higher pace (comparable to boxing) until exhaustion; armor enables aggression | Same |
| **Army-level** | ~20 min active combat before soldiers need rotation | myArmoury / battle duration |
| **Weapon weight** | 1–1.5 kg sword ≈ halves fighting duration; 2–3 kg axe / 3–4 kg halberd → rapid fatigue | Same |

**Key insight:** Real combat is *punctuated* — slow, cautious phases with occasional explosive flurries. Sustained high pace depletes stamina quickly.

### 1.3 Engagement Rules (HEMA Tournaments)

- **Immediate stop** after hit (sport fencing style).
- **Afterblow rule:** One parting blow within 1–3 steps of receiving a hit.
- **No predetermined stop:** Continuous until fall or disarm.

Ruleset drastically affects how long exchanges last and how many blows occur per "engagement."

---

## 2. Current Fallen Paths System

### 2.1 Timing Chain (Per Combatant)

| Phase | Typical Duration | Formula / Notes |
|-------|------------------|-----------------|
| **Wind-up** | 0.4–0.8 s | (0.25 + 0.6×intensity) × windup_mult / leg / perf / agility |
| **Recovery** | 0.4–1.5 s | Base + commitment + outcome extra (hit/deflect/miss) / perf / agility |
| **Gauge fill** | 1–4 s | 100 / (agility × 0.5) ≈ 2 s @ 100 agi |
| **Cycle** | ~2.5–6 s | wind_up + recovery + gauge per attack |

**Time between blows (single combatant):** ~3 s typical. In 2v2, both sides act in parallel, so *engagement* pace can feel ~1.5–3 s per exchange (when alternating).

### 2.2 Stamina Flow

| Constant | Value | Notes |
|----------|-------|-------|
| STAMINA_MAX | 100 | |
| STAMINA_REFILL_RATE | 12/s | When WAITING |
| STAMINA_ATTACK_COST_BASE | 8 | Per attack |
| STAMINA_PARRY_COST | 10 | Per parry (defender) |

**Net over a 3 s cycle (attack only):** Spend 8, regain 12×3 = 36 → **+28**. Stamina *increases* in normal pacing.

**When does stamina deplete?**
- Attacking every ~3 s: net positive. Never runs out in typical 1v1.
- Parrying frequently: defender spends 10 per parry; if parried every 2 s, 5 parries ≈ 50 stamina in 10 s, refill 120 → still net positive.
- **Depletion scenario:** Very fast succession (e.g. parry_partial chains, multiple opponents, or artificially short recovery). Or if costs were higher / refill lower.

**Conclusion:** Current constants make stamina a **rarely hit** constraint. It mainly matters at 0 (parry ×0.5, damage ×0.6, variance ×1.5).

### 2.3 Stamina-Dependent Systems (Current)

| System | At 100% | At 0% | Curve |
|--------|---------|-------|-------|
| **Angle variance** | mult 1.0 | mult 1.5 | Linear lerp(1, 1.5, 1 − stamina_ratio) |
| **Parry capacity** | 1.0 | ×0.5 | Binary: stamina ≤ 0 → mult |
| **Damage** | 1.0 | ×0.6 | Binary: stamina ≤ 0 → mult |

**Gap:** All use **linear or binary** mapping. No non-linear "suddenly sloppy when exhausted" feel.

---

## 3. Non-Linear Fatigue Curve (Exercise Science)

Research indicates:
- **Power output** decreases in a **second-order polynomial** (curved) pattern during prolonged exercise.
- **Critical power** concept: below a threshold, exercise can continue; above it, fatigue accumulates and duration is limited.
- **Sharp decline:** Performance drops more rapidly below ~25% capacity; 5% power loss correlates with time-to-failure.

**Recommended curve shapes:**
1. **sqrt(ratio)** — gentle until low; then steep. `effective = sqrt(stamina_ratio)` for a modifier that ramps down.
2. **Power curve** — `effective = stamina_ratio^0.7` — similar effect; below 0.5, drops faster.
3. **Threshold + steep** — Above 30%: nearly flat. Below 30%: steep ramp (e.g. mult = 1 + 2×(1 − ratio) when ratio < 0.3).

---

## 4. Proposed Non-Linear Stamina System

### 4.1 Unified Stamina Factor

Introduce a single `stamina_factor(stamina_ratio: float) -> float` used everywhere:

```gdscript
# Option A: sqrt — variance/deficit ramps more below 50%
static func stamina_factor(ratio: float) -> float:
    return sqrt(clampf(ratio, 0.0, 1.0))

# Option B: Power curve — sharper drop below 25%
static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), 0.6)

# Option C: Threshold — flat until 30%, then steep
static func stamina_factor(ratio: float) -> float:
    if ratio >= 0.3:
        return 1.0
    return ratio / 0.3  # linear 0→1 as ratio 0→0.3
```

**Recommendation:** **Option B** (power 0.6) — matches "fatigue accelerates" below ~30% without extreme cliff at 0.

### 4.2 Apply to All Stamina-Dependent Systems

| System | Current | Proposed |
|--------|---------|----------|
| **Angle variance mult** | lerp(1, 1.5, 1−ratio) | `1.0 + 0.5 * (1.0 - stamina_factor(ratio))` so at ratio=0, mult=1.5; curve from sqrt/power |
| **Parry capacity** | 0.5 if stamina≤0 else 1 | `lerp(0.5, 1.0, stamina_factor(ratio))` — gradual decline, not binary |
| **Damage** | 0.6 if stamina≤0 else 1 | `lerp(0.6, 1.0, stamina_factor(ratio))` — gradual |
| **Gauge fill** (optional) | 1.0 | `stamina_factor(ratio)` — exhausted combatants fill gauge slower |

### 4.3 Balance Stamina Economics for HEMA-Like Pacing

To make stamina a *felt* constraint without making combat tedious:

| Goal | Change |
|------|--------|
| **Depletion in ~2–3 min of intense combat** | Increase costs or reduce refill. If cycle ≈ 3 s and we want net −2 to −3 per cycle when "active": cost 14–15, refill 36 → net +21 still. Need cost ~20+ per attack to net negative. Or: refill only when truly idle (not in RECOVERING). |
| **Refill only when idle** | Only refill in WAITING. RECOVERING = no refill. Extends time to recover between engagements. |
| **Cost scales with intensity** | `stamina_cost = BASE + intensity * SCALE` (e.g. 5 + 15×intensity → 6.5 @ 0.1, 20 @ 1.0). Heavy strikes cost more. |
| **Parry cost when actually parrying** | Already 10. Defender in bind/deflect pays; could scale by parry quality. |

**Suggested constants (tuned for ~2 min to deplete at high pace):**
- STAMINA_ATTACK_COST: 12 + 8×intensity (light 12, heavy 20)
- STAMINA_REFILL_RATE: 8/s (slower)
- Refill only in WAITING (not RECOVERING)
- With 3 s cycle (1 s wind+recovery, 2 s waiting): spend 16 avg, regain 16 → break-even. Faster attacks (less waiting) → depletion.

---

## 5. HEMA/Medieval Pacing vs Fallen Paths

| Metric | HEMA / Medieval | Fallen Paths | Notes |
|--------|-----------------|--------------|-------|
| **Single cut duration** | 0.25–0.6 s | Wind-up 0.5–0.8 s | FP slightly slower (telegraphed). |
| **Time between blows** | Rules-dependent; 1–3 steps for afterblow | ~3 s per combatant | FP has explicit "wait for gauge" — more measured. |
| **Burst capacity** | 2–3 intense strikes, then pause | Gauge gates; no explicit burst | Could add "flurry" with stamina cost. |
| **High-intensity limit** | <1 to ~5 min | Stamina rarely depletes | Need rebalance so depletion is reachable. |
| **Exhaustion effect** | Sudden drop in control/power | Linear/binary | Non-linear curve recommended. |

**Conclusion:** Fallen Paths is already in the right *ballpark* for blow timing. Main adjustments: (1) non-linear stamina curve for realism, (2) stamina economics so exhaustion is achievable in intense fights, (3) optional refill-only-when-idle.

---

## 6. Implementation Checklist

### Phase 1: Non-Linear Stamina Factor
- [ ] Add `CombatConstants.stamina_factor(ratio: float) -> float` using power curve.
- [ ] Replace `lerpf(1, mult, 1−ratio)` in `get_attack_angle_deg` with `1 + (mult-1) * (1 - stamina_factor(ratio))`.
- [ ] Replace binary stamina≤0 checks in DefenseChoiceResolver (parry) and AttackResolver (damage) with `lerp(min, 1, stamina_factor(ratio))`.

### Phase 2: Balance Stamina Economics (Optional)
- [ ] Intensity-scaled attack cost: `STAMINA_ATTACK_BASE + STAMINA_ATTACK_SCALE * intensity`.
- [ ] Refill only in WAITING (remove refill during RECOVERING).
- [ ] Tune so ~2 min of high-intensity combat approaches 0 stamina.

### Phase 3: Consistency
- [ ] Use `stamina_factor` anywhere stamina affects outcome (variance, parry, damage, gauge fill).
- [ ] Document curve choice and tuning rationale.

---

## 7. Recommended Constants (Draft)

```gdscript
# Stamina curve: power 0.6 — sharp drop below 25%
const STAMINA_FACTOR_POWER := 0.6
static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)

# Economics (optional rebalance)
const STAMINA_ATTACK_COST_BASE := 10.0
const STAMINA_ATTACK_COST_SCALE := 10.0   # cost = BASE + SCALE * intensity
const STAMINA_PARRY_COST := 10.0
const STAMINA_REFILL_RATE := 10.0         # per second when WAITING only
# Refill in RECOVERING: 0 (implement by only refilling when state==WAITING)
```

---

## References

- CombatConstants.gd (STAMINA_*, get_attack_angle_deg)
- AttackResolver.gd (damage mult at stamina 0)
- DefenseChoiceResolver.gd (parry mult at stamina 0)
- CombatStateHandlers.gd (refill, gauge fill)
- Science & Fiction: Medieval Swordfighting
- Battle Durations and Fatigue (myArmoury)
- Critical Power / power-duration (exercise physiology)
- PHYSICS_SYSTEMS_OPTIMAL_STRUCTURE_INVESTIGATION.md
