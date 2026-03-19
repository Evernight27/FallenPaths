# Parry System: Design Paradigms, Speed Options, and Tweaks

Consolidated reference for parry design options, improvement options, and balance tweaks (Goblin parry, dodge floor).

---

## Part 1: Design Paradigms (Active vs Passive)

**Current system:** Active parry — defender in STATE_WAITING chooses parry when someone winds up. Wind-up race; capacity vs momentum. Costs turn.

### Option A: Full Passive Parry
Remove parry as action. Roll parry chance = f(perception, readiness, weapon, pain) at impact. **Pros:** Emergent, HEMA rate without constant choice. **Cons:** No "commit to defend" choice.

### Option B: Hybrid — Active + Passive Reactive Block
Keep active parry. Add passive roll when defender did NOT choose parry (attacked, medical) — weaker effect (partial/deflect cap). **Pros:** Best of both. **Cons:** Two layers.

### Option C: Reactive Parry (Choice Stays, Resolution Perception/State)
Parry remains option but success = perception/state roll at impact, no wind-up race. **Pros:** Perception drives success. **Cons:** Lose race tension.

### Option D: Passive Only When Ready
Passive parry only in STATE_WAITING or early recovery; not when WIND_UP or MEDICAL_WIND_UP. **Pros:** Clear rule. **Cons:** Overlaps with active parry case.

### Option E: Keep Active, Tune Toward "Parry Often"
Increase parry weight, shorten wind-up, boost success. No redesign. **Pros:** Easiest. **Cons:** No perception-based reaction.

**Recommendation:** **B (hybrid)** for tactical + reactive. Or **E** for minimal change.

### Passive Implementation (A1–A6)
- **A1:** Single roll at impact, state-gated.
- **A2:** Add readiness modifier by state.
- **A3:** Opposed roll (attacker vs defender).
- **A4:** Perception gates "reactable" — notice roll, then parry.
- **A4v1–v5:** Reaction time vs wind-up variants for A4.
- **A5:** Parry = damage reduction only (no full deflect).
- **A6:** Reuse dodge formula for second roll.

---

## Part 2: Parry Speed and Improvement Options

**Current:** `c_d = m_d * v_parry * (strength/100) * perf * ...`. `v_parry` global. Attacker `p_a = m_a * v_intent`.

### 2.1 Per-Weapon Parry Speed Factor (recommended)
Defender weapon scales parry speed. Dagger 1.2×, mace 0.85×. **Touchpoints:** WeaponConstants parry_speed_factor, Weapon.gd, CombatManager `_get_parry_speed_m_s()`.

### 2.2 Agility Scaling
`v_parry_effective = v_parry_base * clamp(agility/100, 0.7, 1.3)`. **Pros:** One stat. **Cons:** Agility already strong.

### 2.3 Blade Movement Time (implement existing design)
Use `PARRY_BLADE_MOVEMENT_S`, `PARRY_MOVEMENT_MASS_STRENGTH_MIN/MAX`. `effective_time_to_parry = time_to_react - blade_time`. **Pros:** Matches design. **Cons:** Heavy/weak penalized.

### 2.4 Species Parry Speed Mult
SpeciesResource `parry_speed_mult`. Per-species tuning.

### 2.5 Time-of-Intercept Momentum
Early parry meets less p_a — `v_intent * velocity_curve_factor(progress)`. **Pros:** Rewards fast reaction.

### 2.6 Softer Partial Parry
Near-deflect (c_d close to p_a) → smaller residual velocity. **Pros:** Graduated feel.

### 2.7 Relax PARRY_DODGE_STRENGTH_RATIO
Raise (e.g. 1.8) or per-species grit so weak defenders attempt parry more.

### 2.8 Post-Deflect Bonus
Short parry capacity bonus after full deflect. **Touchpoints:** parry_bonus_until_time.

### 2.9 Agility vs Technique Variance
Scale PARRY_TECHNIQUE_VARIANCE down for high agility.

**Recommended order:** 1.1 (per-weapon) + 2.3 (blade movement) + 2.5 (time-of-intercept).

---

## Part 3: Tweak Options (Goblin Parry, Dodge Floor)

### 3.1 Parry: Let Goblins Parry Sometimes

**Context:** Goblins perception 80 → reaction ~0.35 s. Effective wind-up 0.36 s → edge case. Also: `p_a <= c_d * 2.2` for choice — Goblins vs 150-str party rarely choose parry.

| Option | Touchpoint | Notes |
|--------|------------|-------|
| **A: Raise perception** | goblin.tres → perception 90–95 | No code. Recommended. |
| **A2: Species parry_reaction_mult** | SpeciesResource, CoreEntity | Parry-only, &lt;1 = faster |
| **B: Lower base reaction** | CoreEntity PASSIVE_PARRY_BASE_REACTION_S | Buffs all |
| **C: Commitment window** | Decrease COMMITMENT_FRACTION | More telegraph |
| **D: Guarantee weapon** | _equip_random_equipment fallback | Robustness |

**Recommendation:** **A** (raise perception 90–95). **D** as robustness fix.

### 3.2 Dodge: Add Small Floor

| Option | Touchpoint | Notes |
|--------|------------|-------|
| **A: Constant floor** | CoreEntity DODGE_CHANCE_FLOOR 0.01; clamp min | 1% for all |
| **B: Floor when injured** | Apply floor only when leg/perf &lt; 1 | More realistic |
| **C: Species dodge_floor** | SpeciesResource, e.g. goblin 0.02 | Per-species |

**Recommendation:** **A** (constant 1%) or **B** (injured only).

---

## Summary Table

| Area | Option | Effort |
|------|--------|--------|
| Design | B (hybrid) or E (tune active) | — |
| Speed | 2.1 Per-weapon factor | Low |
| Speed | 2.3 Blade movement time | Low |
| Other | 2.5 Time-of-intercept p_a | Low |
| Other | 2.7 Relax ratio / grit | Trivial |
| Tweak | Parry A (raise perception) | None |
| Tweak | Dodge A (floor 0.01) | Trivial |
