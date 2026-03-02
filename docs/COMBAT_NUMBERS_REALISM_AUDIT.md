# Combat Numbers: Realism Audit (Post-Parry Changes)

This document checks that current constants and formulas still align with real-world combat research after the parry/dodge tweaks and parry improvements. References: existing docs (RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md, COMBAT_PARRY_MISS_RESEARCH.md, BodyPartConstants, ArmorConstants), and typical research ranges for reaction time and strike velocity.

---

## 1. Strike and parry velocity (m/s)

| Constant / value | In-game | Research / reality | Verdict |
|------------------|--------|---------------------|--------|
| VELOCITY_MIN_M_S / VELOCITY_MAX_M_S | 6–24 m/s | Rod-like / longsword strikes often cited **17–24 m/s** at impact; slower for telegraphed or weak blows. | **OK.** Min 6 gives weak attacks; max 24 matches upper end of typical strike speeds. |
| Parry base speed | 24 × 0.5 = **12 m/s** | Defensive move is positioning, not full strike; **~40–60% of strike** is common in design notes. | **OK.** 50% of 24 = 12 m/s is within band. |
| Per-weapon parry factor | Dagger 1.2, Mace 0.9, Sword/Axe/Spear 1.0/0.95/1.0 | Lighter blade = quicker defensive move; heavy mace = slower to reposition. | **OK.** Directionally correct; factors are modest (0.9–1.2). |
| PARRY_V_MIN_FRACTION (partial) | 0.2 (20% residual) | Partial parry often leaves a glancing hit; 20% of intent velocity is a reasonable floor. | **OK.** |
| PARRY_V_MIN_NEAR_DEFLECT | 0.1 (10% when c_d ≈ p_a) | “Almost deflected” should leave less energy; 10% floor is more realistic than 20% for near-miss parries. | **OK.** |

---

## 2. Reaction and parry timing (seconds)

| Constant / value | In-game | Research / reality | Verdict |
|------------------|--------|---------------------|--------|
| PASSIVE_PARRY_BASE_REACTION_S (CoreEntity) | **0.22 s** (220 ms) | Simple visual reaction time **~180–250 ms** typical. Base 0.22 s places “notice attack” in the research band. | **OK.** Matches typical visual RT range. |
| PARRY_REACTION_S (CombatManager) | 0.22 s | Currently **unused** in code (only in comment). Matches “cognitive” reaction. | **No change needed.** Leave as comment or future use. |
| PARRY_BLADE_MOVEMENT_S | **0.13 s** | Explosive cut duration in research **250–350 ms**; defensive blade move is a shorter repositioning. 130 ms is plausible for “blade into line.” | **OK.** |
| PASSIVE_PARRY_MIN_TIME_FOR_FULL_S | 0.25 s | Time *after* reaction to achieve full parry capacity. 0.25 s to get full capacity is reasonable. | **OK.** |
| Blade movement mult (mass/strength) | 0.5–2.0× base | Heavy weapon / weak user = slower into position; light / strong = faster. | **OK.** Directionally correct. |

---

## 3. Impulse and parry physics (p_a, c_d)

| Formula / constant | In-game | Research / reality | Verdict |
|--------------------|--------|---------------------|--------|
| p_a = m × v (momentum) | kg·m/s | Standard: impulse = mass × velocity. | **OK.** |
| c_d = m_d × v_parry × (strength/100) | Capacity scales with defender mass, parry speed, strength. | Parry “capacity” as impulse-like (force × time or momentum) is a reasonable abstraction for blade meeting blade. | **OK.** |
| PARRY_DEFLECT_THRESHOLD = 1.0 | Full deflect when c_d ≥ p_a. | “Match” impulse for full stop is a simple, plausible rule. | **OK.** |
| Time-of-intercept p_a (velocity curve) | p_a = m_a × v_intent × progress² (early parry → lower progress → lower p_a). | Blade accelerates into impact; early contact meets less momentum. | **OK.** Aligns with real kinematics. |
| Agility scaling c_d | c_d × clamp(agi/100, 0.7, 1.3). | Faster defenders get blade into position more effectively; no direct citation but consistent with “quicker = better parry.” | **OK.** Modest range. |

---

## 4. Wind-up, recovery, and commitment

| Constant | In-game | Research / reality | Verdict |
|----------|--------|---------------------|--------|
| WIND_UP_BASE_S + scale | ~0.25 + 0.6×intensity → ~0.37–0.85 s | “Standard” cut **600+ ms**; “explosive” **250–350 ms**. Our wind-ups span that range. | **OK.** |
| COMMITMENT_FRACTION | 0.2 | First 20% of wind-up = telegraph before attack “counts” for defender reaction. | **OK.** |
| OFF_BALANCE_DURATION_S | 0.4 s | Short window after miss/deflect; plausible. | **OK.** |
| PARRY_BONUS_AFTER_DEFLECT_S | 2.0 s | Short “ready” bonus after successful deflect; no direct research; gameplay tuning. | **OK.** |

---

## 5. Miss, dodge, and hit chance

| Constant | In-game | Research (COMBAT_PARRY_MISS_RESEARCH.md) | Verdict |
|----------|--------|-------------------------------------------|--------|
| MISS_CHANCE_BASE | 0.06 (6%) | No direct melee “miss %”; HEMA suggests most exchanges end in *some* contact. Low miss is plausible. | **OK.** |
| DODGE_CHANCE_AT_FULL_SPEED | 0.08 (8%) | “Modest” dodge; research doesn’t give a number. | **OK.** |
| Dodge floor (if added) | Optional 1–2% | Small floor for “flinch” avoids 0% when badly injured; realism trade-off. | **Design choice.** |

---

## 6. Damage, penetration, and armor

| Constant / system | In-game | Research / reality | Verdict |
|-------------------|--------|---------------------|--------|
| J_PER_MM_BASE (55) | Williams-style: ~55 J per 1 mm mild steel equivalent. | Williams (Knight & Blast Furnace) and similar penetration models use this order of magnitude for armor steel. | **OK.** (Citation in WeaponConstants/ArmorConstants.) |
| PENETRATION_EXPONENT | 0.6 (≈ 1/1.67) | Thicker armor needs disproportionately more energy. | **OK.** |
| DAMAGE_KE_SCALE | 2.0 | Tuned so ~100 J arm, ~200 J leg for severance (RESEARCHED_NUMBERS, SpeciesResource). | **OK.** |
| MIN_DAMAGE_TO_SEVER | 10 | Blocks trivial severance; ~25 J floor. | **OK.** |
| Body part weights (targeting) | BodyPartConstants | Based on surface area / exposure (e.g. NCBI). | **OK.** |
| Bone thresholds | BodyPartConstants | Skull/femoral/tibial fracture energy ranges cited in comments. | **OK.** |
| BLUNT_CUSHION_MOMENTUM_THRESHOLD | 3000 (kg·m/s)/m² | Example: mace 1.7 kg, 12 m/s, 8 cm → p/A ≈ 4080; above threshold. | **OK.** |

---

## 7. Technique variance and post-deflect bonus

| Change | In-game | Realism note | Verdict |
|--------|--------|--------------|--------|
| PARRY_TECHNIQUE_VARIANCE | ±10% on c_d | Timing/placement vary; ±10% is modest. | **OK.** |
| Agility reduces variance | High agility → lower variance (down to ±5%). | Skilled fighters more consistent; plausible. | **OK.** |
| Post-deflect +10% capacity, 2 s | Defender “ready” after full deflect. | Readiness after successful parry is attested in fencing; 2 s and 10% are tuning. | **OK.** |

---

## 8. Summary: values still align with real-life combat

- **Velocity:** 6–24 m/s and parry at ~50% of max (with per-weapon 0.9–1.2) match typical strike/parry speed ranges and “defensive move slower than strike” idea.
- **Reaction:** 0.22 s (220 ms) “notice attack” is in the typical visual RT band (180–250 ms). Blade movement 0.13 s and mass/strength scaling are plausible.
- **Impulse/parry:** p_a and c_d use standard momentum; time-of-intercept (progress²) and full-deflect threshold 1.0 are consistent with real kinematics and HEMA-style blade-blade outcomes.
- **Damage/armor:** Existing research-backed numbers (55 J/mm, bone thresholds, KE scale, severance) are unchanged and still coherent.
- **Miss/dodge:** Low base miss (6%) and modest dodge (8%) remain in line with COMBAT_PARRY_MISS_RESEARCH.md and HEMA “most contacts are defended or blade-blade” (57–80% defended for longsword).

No constant changes are **required** for realism. Optional tuning only:

- If you want parry to sit more in the **57–80% defended** band (HEMA), the main levers are how often defenders **choose** parry and **succeed** (e.g. reaction window, PARRY_DODGE_STRENGTH_RATIO, or species perception/strength), not the raw velocity/reaction numbers above.
- If you add a **dodge floor** (e.g. 1%), it slightly diverges from “pure” realism for badly injured defenders but improves feel; document as a design choice.

---

## 9. References in codebase

- RESEARCHED_NUMBERS_HEALTH_SYSTEM_COHERENCE.md — tissue/bone/severance/pain coherence.
- COMBAT_PARRY_MISS_RESEARCH.md — HEMA blade-blade %, miss/dodge plausibility.
- BodyPartConstants.gd — bone thresholds (skull 4–23 J, femoral ~35 J, etc.).
- WeaponConstants.gd — “Research: rod-like strikes 17.2–24.2 m/s”; Williams 55 J/mm.
- ArmorConstants.gd — Williams 50 J for 16 layers linen; blunt cushion threshold.
- CoreEntity.gd — PASSIVE_PARRY_BASE_REACTION_S 0.22 (220 ms, research band 180–250 ms); DODGE_CHANCE_AT_FULL_SPEED 0.08.
