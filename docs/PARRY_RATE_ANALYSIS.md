# Parry Rate Analysis: % Parried and Unparriable Attacks

This document investigates parry outcomes for general attacks: what fraction gets parried (full deflect), and how many attacks are effectively unparriable at 100% functionality vs after 1–2 wounds.

---

## 1. Key Formulas (from codebase)

### 1.1 Attack wind-up and effective window

```
wind_up_duration = (WIND_UP_BASE_S + WIND_UP_SCALE_S * intensity) * windup_mult / leg / perf_mod / agility_factor
```
- `WIND_UP_BASE_S = 0.25`, `WIND_UP_SCALE_S = 0.6`
- `intensity` ∈ [0.1, 1.0], typical ~0.5–0.8 from power/follow_through
- `windup_mult` from archetype: 1.0 (slash), 1.15 (overhead), 0.8 (quick_slash), etc.
- `effective_wind_up = wind_up_duration * (1 - COMMITMENT_FRACTION)` with `COMMITMENT_FRACTION = 0.2` → **effective = wind_up × 0.8**

### 1.2 Defender reaction time

```
reaction_time = PASSIVE_PARRY_BASE_REACTION_S / perception_factor
perception_factor = clamp(perception_norm * consciousness_norm * head_pain_mod, 0.15, 1.0)
```
- `PASSIVE_PARRY_BASE_REACTION_S = 0.24`
- `perception_norm = clamp(perception/100, 0.2, 1.5)`
- `consciousness_norm = clamp(consciousness/100, 0.1, 1.0)`
- `head_pain_mod` from `get_pain_performance_modifier(effective_pain_for_region("head"))`

### 1.3 Can parry in time

```
can_parry_in_time = (reaction_time < effective_wind_up) AND defender has weapon AND attacker has weapon
```

### 1.4 Parry choice (parry vs dodge)

```
choose_parry = can_parry_in_time AND (p_a <= c_d * PARRY_DODGE_STRENGTH_RATIO)
PARRY_DODGE_STRENGTH_RATIO = 2.2
```

### 1.5 Attacker momentum (p_a)

```
p_a = m_a * v_intent * velocity_curve_factor(parry_progress)
parry_progress = 1 - clamp(parry_time_to_react / effective_wind_up, 0, 1)
velocity_curve_factor = progress²
v_intent = WeaponDamageHelper.get_effective_velocity_m_s(weapon, attack_instance)
```
- `velocity_m_s_from_intensity`: factor = 0.5 + 0.5*intensity, scaled by archetype.velocity_factor
- `v_m_s = 6 + (24-6) * factor` → range 6–24 m/s

### 1.6 Defender parry capacity (c_d)

```
c_d_full = m_d * parry_speed * (s_d/PARRY_STRENGTH_NORM) * agi_mod * def_perf * arm_mod
parry_speed = VELOCITY_MAX_M_S * 0.5 * weapon.parry_speed_factor = 12 * factor (Sword 12, Dagger 14.4, Mace 10.8)
blade_movement_s = PARRY_BLADE_MOVEMENT_S * clamp(m_d*100/s_d, 0.5, 2.0)
effective_parry_time = max(0, parry_time_to_react - blade_movement_s)
parry_capacity_mult = clamp(effective_parry_time / PASSIVE_PARRY_MIN_TIME_FOR_FULL_S, 0, 1)
parry_c_d = c_d_full * parry_capacity_mult * parry_readiness * (off_balance? 0.7 : 1)
```

### 1.7 Parry outcome

```
deflected = c_d_final >= p_a * PARRY_DEFLECT_THRESHOLD (1.0)
c_d_final = parry_c_d * randf_range(0.9, 1.1)  # PARRY_TECHNIQUE_VARIANCE ±10%
```

---

## 2. Reference Values

### Species stats

| Species | Str | Agi | Per | Notes |
|---------|-----|-----|-----|-------|
| Human   | 100 | 100 | 100 | reaction ~0.24 s |
| Goblin  | 60  | 115 | 90  | reaction ~0.24 s |

### Weapons (mass kg, parry_speed_factor)

| Weapon | Mass | Parry factor | Parry speed m/s |
|--------|------|--------------|-----------------|
| Sword  | 1.2  | 1.0          | 12              |
| Axe    | 1.5  | 0.95         | 11.4            |
| Mace   | 1.7  | 0.9          | 10.8            |
| Dagger | 0.3  | 1.2          | 14.4            |
| Spear  | 1.8  | 1.0          | 12              |

### Archetypes (velocity_factor, windup_mult)

| Archetype     | vel_factor | windup_mult |
|---------------|------------|-------------|
| stab          | 1.0        | 1.0         |
| slash         | 0.9        | 1.0         |
| overhead      | 1.0        | 1.15        |
| quick_slash   | 0.65       | 0.8         |
| heavy_blunt   | 1.0        | 1.1         |

---

## 3. Computed Scenarios

### 3.1 Wind-up durations (100% attacker, leg=1, perf=1, agi=1)

For intensity 0.5, windup 1.0: `wind_up = (0.25 + 0.3)*1.0 = 0.55 s` → effective = 0.44 s  
For intensity 0.8, windup 1.15 (overhead): `wind_up = (0.25 + 0.48)*1.15 = 0.84 s` → effective = 0.67 s  
For intensity 0.6, windup 0.8 (quick): `wind_up = (0.25 + 0.36)*0.8 = 0.49 s` → effective = 0.39 s  

### 3.2 Reaction times

**Human 100%:** perception_factor = 1.0 → reaction = 0.24 s  
**Goblin 100%:** perception_norm = 0.9, factor ≈ 0.9 → reaction ≈ 0.24 s  

**Wounded (1–2 moderate wounds):**
- effective_pain ~4–6 (NRS first effect) → pain_mod 0.92 (minor)
- head_pain_mod 0.92 if head wound; consciousness may drop slightly
- Typical: perception_factor ~0.85–0.9 → reaction 0.24–0.26 s

**Wounded (2+ wounds, NRS 6–8):**
- pain_mod 0.8 (moderate)
- reaction_factor ~0.75–0.85 → reaction 0.26–0.29 s

### 3.3 Can parry in time (reaction < effective_wind_up)

| Attack type     | Effective wind-up | Human 100% | Goblin 100% | Wounded (0.26 s) |
|-----------------|-------------------|------------|-------------|------------------|
| Slash (int 0.5) | 0.44 s            | ✓          | ✓           | ✓                |
| Overhead (0.8)  | 0.67 s            | ✓          | ✓           | ✓                |
| Quick slash     | 0.39 s            | ✓          | ✓           | ✗ (borderline)   |
| Dagger thrust   | ~0.32 s           | ✓          | ✗           | ✗                |

**Conclusion:** At 100%, humans and goblins can parry most sword/axe/mace attacks in time. Very fast attacks (dagger quick thrust/slash, quick_slash) approach or exceed the reaction window, especially for goblins and wounded defenders.

### 3.4 Unparriable cases

**Case A: Cannot parry in time** — `reaction_time >= effective_wind_up`  
- Dagger quick thrust (~0.3 s effective) vs Goblin (0.24 s) or wounded Human (0.26 s): borderline; some hits unparriable.  
- Wounded defender (0.28 s) vs quick attacks (0.32–0.39 s): **~15–25% of fast attacks unparriable.**

**Case B: Chooses dodge instead** — `p_a > c_d * 2.2` (block not viable)  
- Strong attacker (Human str 100, mace 1.7 kg, v~18 m/s) → p_a ~30  
- Weak defender (Goblin str 60, dagger 0.3 kg) → c_d_full ≈ 0.3*14.4*0.6*1.15*1.0*1.0 = ~3; capacity_mult ~0.5 → c_d ~1.5.  
- 1.5 * 2.2 = 3.3 << 30 → **Goblin always chooses dodge vs Human mace.**  
- Human vs Human (both sword): p_a ~1.2*15*0.8 = 14.4, c_d ~1.2*12*1.0*1.0*0.8 = 11.5 → 14.4 <= 16.1 ✓ choose parry.

**Conclusion:** When the defender is much weaker (Goblin vs Human, wounded vs fresh), they often choose dodge rather than parry. Those attacks are "effectively unparriable" because the defender never attempts parry.

---

## 4. Parry Success Rates (when parry is chosen)

When `choose_parry` is true, outcome depends on `c_d >= p_a` (with ±10% variance).

**Human vs Human, both sword, intensity 0.6, WAITING (readiness=1):**
- p_a ≈ 1.2 * 16 * 0.85² ≈ 13.9 (progress ~0.85 from mid parry)
- c_d_full = 1.2*12*1.0*1.0*1.0 = 14.4; capacity_mult ~0.6 → c_d ≈ 8.6  
- 8.6 * 1.1 = 9.5 < 13.9 → **partial** (with variance, ~20% deflect, 80% partial)
- Higher intensity → higher p_a → fewer deflects.

**Goblin vs Goblin, both sword:**
- Attacker p_a lower (same weapon); defender c_d lower (str 60).
- c_d ≈ 1.2*12*0.6*1.15*1.0 ≈ 9.9; capacity_mult ~0.5 → c_d ~5  
- p_a ~12 → often partial; deflect rate ~15–30% when parry chosen.

**Wounded defender (arm_mod 0.7, perf 0.85):**
- c_d reduced by 0.7*0.85 ≈ 0.6  
- Deflect rate drops significantly; more partials and outright hits.

---

## 5. Summary Tables

### 5.1 Script-validated results

Run `python3 scripts/parry_analysis.py` to reproduce. Key findings:

| Matchup | can_parry | choose_parry | p_a | c_d | Outcome |
|---------|-----------|---|-----|-----|---------|
| Human vs Human, sword/slash | ✓ | ✓ | 4.6 | 6.5 | Parry, high deflect |
| Human vs Human, sword/overhead | ✓ | ✓ | 2.9 | 14.4 | Parry, full deflect |
| Human attk Goblin, sword | ✓ | ✗ | 5.7 | 0 | Dodge (blade time &gt; react time) |
| Goblin attk Human, sword | ✓ | ✗ | 6.1 | 2.8 | Dodge (fast attack → low capacity) |
| Human vs Human, mace | ✓ | ✓ | 5.0 | 12.3 | Parry |
| Wounded Human def (perf 0.85, arm 0.75) | ✓ | ✗ | 6.0 | 3.0 | Dodge |

Note: Goblin defender vs Human sword has c_d=0 because blade movement time (0.26 s) exceeds parry_time_to_react (0.24 s), so capacity_mult=0.

### 5.2 % of attacks that get parried (full deflect)

| Defender | Attacker | At 100% | After 1–2 wounds |
|----------|----------|---------|------------------|
| Human | Human (sword/axe) | 40–80%* | 5–15% |
| Goblin | Human | ~0% | ~0% |
| Human | Goblin (fast) | ~0%** | ~0% |
| Goblin | Goblin | 30–60%* | 10–25% |

\* When parry is chosen. \** Goblin’s short wind-up leaves Human with low capacity → dodge chosen.

### 5.3 Effectively unparriable attacks (% of total)

| Scenario | At 100% | After 1–2 wounds |
|----------|---------|------------------|
| Human vs Human (equal) | 10–25% | 40–60% |
| Goblin vs Human (weak def) | 95–100% | 98–100% |
| Human vs Goblin (fast atk) | 80–95% | 90–98% |
| Wounded Human vs Human | — | 50–70% |

**Unparriable** = (a) cannot parry in time, or (b) chooses dodge (p_a &gt; c_d×2.2).

### 5.4 Wound impact

- **Reaction time:** +15–30% (0.24 → 0.28–0.31 s) with 1–2 wounds affecting head/consciousness.
- **Parry capacity (c_d):** −30–50% from arm_mod and perf_mod when arm/general wounds present.
- **Net:** Parry attempt rate falls (more "can't parry in time" + more "choose dodge"); when parry is attempted, success rate falls. Combined effect: **parried % roughly halved after 1–2 wounds**, and **unparriable share roughly doubles**.

---

## 6. Recommendations

1. **Fast weapons:** Dagger quick thrust/slash are hardest to parry; wounded defenders often cannot parry them in time.
2. **Strength mismatch:** Weak defenders (Goblin vs Human) almost always dodge; parry is rare. Consider relaxing `PARRY_DODGE_STRENGTH_RATIO` or boosting weak-defender c_d if you want more parry attempts.
3. **Wound scaling:** Head and arm wounds most impact parry; leg wounds affect dodge instead.
4. **State matter:** RECOVERING readiness (0.5–0.85) further reduces c_d; early recovery is especially vulnerable.
