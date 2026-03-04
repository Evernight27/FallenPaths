# Balance Trace: Average Performance vs HEMA Expectations

Traces concrete numbers through the combat flow to compute typical outcome rates and compare to HEMA.

---

## 1. Constants Summary

| Constant | Value | Notes |
|----------|-------|------|
| MISS_CHANCE_BASE | 0.06 | 6% miss |
| effective_hit | 0.94 | 94% proceed to defense |
| Reaction (perception 100) | 0.24 s | PASSIVE_PARRY_BASE / 1.0 |
| COMMITMENT_FRACTION | 0.2 | 80% of wind-up = telegraph |
| PARRY_STRENGTH_NORM | 100 | str/100 for capacity |
| Parry speed | 12 m/s | 24 * 0.5 (50% of max) |
| PARRY_BLADE_MOVEMENT_S | 0.13 | Base time to move blade |
| PASSIVE_PARRY_MIN_TIME_FOR_FULL_S | 0.25 | Full capacity needs 0.25s |
| DODGE_CHANCE_AT_FULL_SPEED | 0.10 | ~10% at agi+perc=200 |
| Velocity curve | p² | Quadratic (progress²) |

---

## 2. Scenario A: Human vs Human, Sword vs Sword, Defender WAITING

**Setup:** Both stats 100, sword 1.2 kg, slash (windup 1.0), intensity 0.6.

### Step 1: Miss
- miss_chance = 0.06 → **6% miss, 94% to defense**

### Step 2: Wind-up and timing
- wind_up = (0.25 + 0.6*0.6) * 1.0 = **0.61 s**
- effective_wind_up = 0.61 * 0.8 = **0.49 s**
- reaction = 0.24 s
- can_parry_in_time: 0.24 < 0.49 → **yes**
- parry_time_to_react = 0.49 - 0.24 = **0.25 s**

### Step 3: Parry momentum (p_a)
- parry_progress = 1 - (0.27/0.49) = **0.45** (defender reacts when attack 45% through)
- velocity_curve_factor(0.45) = 0.45² = **0.20**
- v_intent (slash, intensity 0.6, vel_factor 0.9): factor 0.8*0.9=0.72, v = 6 + 18*0.72 = **18.96 m/s**
- p_a = 1.2 * 18.96 * 0.20 = **4.55 kg·m/s**

### Step 4: Parry capacity (c_d)
- blade_movement_s = 0.13 * clamp(1.2*100/100, 0.5, 2) = 0.13 * 1.2 = **0.156 s**
- effective_parry_time = 0.27 - 0.156 = **0.114 s**
- parry_capacity_mult = 0.114 / 0.25 = **0.456**
- c_d_full = 1.2 * 12 * 1.0 * 1.0 * 1.0 * 1.0 = **14.4**
- readiness (WAITING) = 1.0
- parry_c_d = 14.4 * 0.456 * 1.0 = **6.6**

### Step 5: Defense choice
- is_block_parry: m_d 1.2 ≥ m_a 1.2*0.9, s_d 100 ≥ s_atk 100*0.95 → **block path**
- block_viable: p_a 4.55 ≤ c_d 6.6 * 2.2 = 14.5 → **yes**
- choose_parry = **true**

### Step 6: Parry resolution
- c_d_final with variance: 6.6 * rand(0.9, 1.1) → **5.9 to 7.3**
- full_stop: is_block_parry and c_d_final ≥ p_a * 1.0. 5.9 ≥ 4.55 → **yes**
- Outcome: **parry_deflect (full block)** in almost all cases

### Scenario A summary
| Outcome | Rate |
|---------|------|
| Miss | 6% |
| Parry attempted | 94% (when can_parry_in_time) |
| Parry success (full deflect) | ~95%+ of parry attempts |
| Dodge chosen | ~0% (parry always preferred when viable) |
| Hit | ~0% when defender WAITING, sword, can parry |

**Effective:** Human vs human, defender ready → **~94% parry success, ~6% miss**. Almost no clean hits.

---

## 3. Scenario B: Defender in early RECOVERING

- readiness = 0.5
- parry_c_d = 6.6 * 0.5 = **3.3**
- block_viable: p_a 4.55 ≤ 3.3 * 2.2 = 7.26 → **barely yes** (close)
- full_stop: 3.3 ≥ 4.55 → **no** (partial parry)
- Outcome: **parry_partial** → reduced damage

---

## 4. Scenario C: Quick attack (QUICK_SLASH, windup 0.8)

- wind_up = (0.25 + 0.36) * 0.8 = **0.49 s**
- effective_wind_up = 0.39 s
- parry_time_to_react = 0.39 - 0.24 = **0.15 s**
- parry_progress = 1 - 0.44 = **0.56**
- velocity_curve = 0.56² = **0.31**
- v_intent (velocity_factor 0.65): lower v ~14 m/s
- p_a = 1.2 * 14 * 0.31 = **5.2**
- effective_parry_time = 0.17 - 0.156 = **0.014 s**
- capacity_mult = 0.014/0.25 = **0.056**
- parry_c_d = 14.4 * 0.056 = **0.8**
- block_viable: 5.2 ≤ 0.8 * 2.2? **No**. redirect_viable: 5.2 ≤ 0.8 * 3.5*1.25? **No**
- Defense: **dodge** (parry not viable)
- dodge_chance = 8% → **92% hit, 8% dodge**

**Effective:** Fast attack → parry rarely in time → dodge path → 8% dodge, 92% hit.

---

## 5. Scenario D: Goblin (str 60, agi 115, perc 90) vs Human (100), both swords

**Defender Goblin:**
- reaction = 0.24 / (0.9 * 1.0) = **0.267 s**
- effective_wind_up (human attacking, intensity 0.6) = 0.49 s
- can_parry: 0.244 < 0.49 → **yes**
- parry_time_to_react = **0.246 s**
- parry_progress = 0.5, curve = 0.25, p_a = **4.5**
- blade_movement = 0.13 * clamp(1.2*100/60, 0.5, 2) = 0.13 * 2 = **0.26 s**
- effective_parry_time = 0.246 - 0.26 = **-0.014 → 0**
- capacity_mult = **0** → parry_c_d = **0**
- redirect_viable: no. block_viable: no.
- desperate_parry: dodge_chance = (115+90)/200 * 0.10 = **10.25%** → > 0.06, not desperate
- Defense: **dodge**, dodge 8.2% → **~92% hit, 8% dodge**

**Effective:** Goblin vs human sword → **parry rarely viable** (blade movement eats time); dodge path; 8% dodge.

---

## 6. Outcome Rate Summary (Estimated)

| Matchup | Defender state | Parry chosen | Parry full | Parry partial | Dodge chosen | Dodge success | Clean hit |
|---------|----------------|--------------|------------|---------------|--------------|---------------|-----------|
| Human vs Human (sword) | WAITING | ~94% | ~90% | ~4% | ~6% (when can't parry) | 8% of those | ~5% |
| Human vs Human | RECOVERING early | ~90% | ~20% | ~70% | ~10% | 8% | ~15% |
| Human vs Human | Quick attack | 0% | - | - | 100% | 8% | 92% |
| Goblin vs Human | WAITING | 0% | - | - | 100% | 8% | 92% |

**Overall human vs human (mixed states, mixed attacks):** Roughly **50–70% parry** (full + partial), **20–30% hit**, **5–10% miss**, **5–10% dodge**.

---

## 7. HEMA Comparison

| Metric | Your system (est.) | HEMA expectation |
|--------|--------------------|------------------|
| **Parry as primary defense** | Yes – parry chosen when viable | ✓ Parry is primary |
| **Parry success when attempted** | High (~90%+ full deflect when block path) | Mixed; many deflections, some partials |
| **Full deflect rate** | High when defender ready, equal weapons | ARMA: "deflection/evasion," not constant blocks |
| **Fast attacks hard to parry** | Yes – quick slash → dodge path | ✓ Explosive cuts harder to react to |
| **Weaker defender (goblin)** | Usually dodge path, low parry | ✓ Light/weak rely on evasion/redirect |
| **Dodge rate** | 8% when dodge chosen | Voiding secondary; no clear target |
| **Hit rate when defender ready** | Low (~5–10%) | Exchanges often end in parry or mutual engagement |

---

## 8. Findings

### What matches HEMA
- Parry preferred when viable; dodge as fallback
- Fast attacks hard to parry
- Weak/small defenders (goblins) mostly dodge
- Recovery reduces parry quality (partials)
- Full deflects when defender ready and equal weapons

### Possible mismatch
1. **Full deflect rate high** – Human vs human, defender WAITING, often ~90%+ full deflect. HEMA has more partial deflections and "almost" parries.
2. **Clean hit rate low when ready** – Defender ready → few clean hits. HEMA bouts still see plenty of hits.
3. **Dodge 8%** – No HEMA benchmark, but 8% when forced to dodge is plausible.

### Levers to shift balance
- **More partial parries:** Raise PARRY_DEFLECT_THRESHOLD (e.g. 1.0 → 1.1) so c_d must exceed p_a by 10% for full stop.
- **More hits when parry attempted:** Increase PARRY_TECHNIQUE_VARIANCE so parry success is noisier.
- **Tighter "in time" window:** Slightly longer reaction (e.g. 0.24 s) so more attacks push defender to dodge.
- **Blade movement:** Slightly longer blade_movement_s so capacity is lower and partials more common.

---

## 9. Recommendation (implemented)

For closer HEMA feel:

1. **PARRY_DEFLECT_THRESHOLD 1.0 → 1.08** ✓ – More partial parries, fewer full deflects.
2. **PARRY_TECHNIQUE_VARIANCE 0.1 → 0.15** ✓ – More variation in parry execution.
3. **PASSIVE_PARRY_BASE_REACTION_S 0.22 → 0.24** ✓ – Slightly less "in time" parries.
4. **Late parry (PARRY_LATE_CAPACITY_FLOOR 0.22)** ✓ – When reaction_time ≥ effective_wind_up, defender still attempts parry with 22% capacity (HEMA: 57–80% of contacts blade-on-blade).

These keep the physics while nudging outcome distribution toward more partials and hits, closer to typical HEMA exchanges.
