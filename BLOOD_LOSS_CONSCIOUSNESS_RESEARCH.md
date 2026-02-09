# Blood Loss and Consciousness: Medical Research and Scaling

Summary of how blood loss (hemorrhage) affects mental status and consciousness in trauma, and how the game scales the blood–consciousness modifier.

---

## 1. ATLS Hemorrhage Classes and Mental Status

Advanced Trauma Life Support (ATLS) classifies hemorrhagic shock by **percentage of blood volume lost** and associated signs, including **mental status**:

| Class | Blood loss      | Remaining volume | Mental status / neurologic |
|-------|-----------------|------------------|----------------------------|
| **I**   | &lt;15% (&lt;750 mL) | **&gt;85%**        | Normal or slightly anxious; minimal symptoms. |
| **II**  | 15–30%          | **70–85%**        | Mildly anxious, irritable. Tachycardia; compensatory phase. |
| **III** | 30–40%          | **60–70%**        | Anxious, **confused**. Hypotension; often needs transfusion. |
| **IV**  | &gt;40%          | **&lt;60%**         | **Lethargy**, altered mental status; life-threatening without intervention. |

**When effects start:** Mental status changes are described from **Class II** (15–30% lost). Up to **15% loss** (≥85% remaining), healthy adults typically have **no or minimal** clinical symptoms. **Confusion** appears at **Class III** (30–40% lost, 60–70% remaining), and **lethargy** at **Class IV** (&gt;40% lost).

*Sources: ATLS shock classes; StatPearls Hemorrhage Control (NBK535393), Hypovolemic Shock (NBK513297); clinical review Hemorrhagic shock (PMC1065003); FPNotebook hemorrhage classification.*

---

## 2. Implications for Game Scaling

- **Threshold for “no effect”:** Consciousness modifier should remain **1.0** (no penalty) when **remaining blood ≥ 85%** (Class I). So the **effect starts below 85%**, not at 50%.
- **Scaling range:** Ramp from **85% remaining** (no penalty) down to **35% remaining** (death threshold in our system). At 35% we apply the **maximum** blood-related consciousness reduction (e.g. 50% modifier), so that near-death from blood loss matches severe lethargy / impaired consciousness.
- **Curve:** Linear scaling between 85% and 35% is a simple, readable approximation: mild effect in the 70–85% band (Class II), stronger in 60–70% (Class III), and maximum as we approach 35% (Class IV).

---

## 3. Implementation (Constants and Formula)

- **BLOOD_CONSCIOUSNESS_START_THRESHOLD:** `85.0` — Below this (i.e. &lt;85% remaining, ≥15% lost), the blood modifier starts to drop (Class II).
- **BLOOD_CONSCIOUSNESS_FLOOR_THRESHOLD:** `35.0` — At or below this (death threshold), the blood modifier reaches its minimum (max reduction). Aligns with `BLOOD_LOSS_DEATH_THRESHOLD`.
- **BLOOD_CONSCIOUSNESS_REDUCTION_MAX:** `0.5` — At the floor, multiplier = 0.5 (50% of base consciousness from head/blood before pain).

**Formula:**

- If `blood_volume >= START_THRESHOLD` (85): modifier = **1.0**.
- If `blood_volume <= FLOOR_THRESHOLD` (35): modifier = **1.0 - REDUCTION_MAX** = **0.5**.
- Else: **linear** between (85, 1.0) and (35, 0.5):  
  `reduction = (START - blood_volume) / (START - FLOOR) * REDUCTION_MAX`  
  `modifier = 1.0 - reduction`

Examples:

- 100% → 85% blood: modifier = 1.0 (no effect).
- 70% blood: modifier ≈ 0.85 (mild, Class II).
- 60% blood: modifier = 0.75 (moderate, Class III).
- 35% blood: modifier = 0.5 (max, Class IV / death threshold).

---

## 4. Summary

| Item | Old (pre-change) | New (research-based) |
|------|------------------|------------------------|
| When effect starts | Below **50%** remaining | Below **85%** remaining (Class II) |
| When max reduction | At 0% (never reached; death at 35%) | At **35%** (death threshold) |
| Scaling | Linear from 50% down | Linear from **85%** to **35%** |
| Match to ATLS | Effect began too late | Class I no penalty; II–IV progressive impairment |

This keeps blood loss affecting consciousness in line with when mental status changes are described in trauma (Class II and beyond), and ties the maximum effect to the existing death threshold.
