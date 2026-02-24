# Pain System: Medical Research Synthesis for Optimal Realism

This document synthesizes medical research on pain scales, functional impairment, and acute trauma to justify the pain constants used in the game.

---

## 1. NRS Thresholds for Functional Impairment

### Krebs et al. (2007) — J Gen Intern Med

**Study:** 275 primary care patients; NRS vs. BPI interference (pain that interferes with functioning).

**Likelihood ratios for pain interfering with functioning:**
| NRS range | Likelihood ratio | Interpretation |
|-----------|-----------------|----------------|
| 0 | 0.39 | Less likely to have interference |
| 1–3 | 0.99 | Neutral |
| **4–6** | **2.67** | 2.67× more likely to have functional impairment |
| **7–10** | **5.60** | 5.60× more likely |

**Conclusion:** NRS 4 is the lower bound where functional impairment becomes meaningfully more likely. NRS 7+ indicates severe interference.

### Boonstra et al. (2016) — Frontiers Psychology

**Study:** 2,854 chronic musculoskeletal pain patients; NRS vs. Pain Disability Index.

**Cut-off points (overall):**
- Mild: NRS ≤ 5
- Moderate: NRS 6–7
- Severe: NRS ≥ 8

**Low catastrophizing subgroup:**
- Mild: NRS ≤ 3
- Moderate: NRS 4–6
- Severe: NRS ≥ 7

**Implication:** For low-catastrophizing individuals (e.g. trained fighters), first functional effect may occur at NRS 4. Moderate pain = NRS 4–6.

### Clinical Consensus

- NRS 4–5 commonly used as lower limit for "moderate" pain with functional impact
- Mild: 1–3; Moderate: 4–6; Severe: 7–10 (standard categorization)

---

## 2. Acute Trauma Pain

### Emergency Department / Trauma Data

- **57.4%** of trauma patients present with NRS 5–10 (moderate to severe pain)
- **42.6%** present with NRS 0–4 (mild)
- NRS validated for acute pain in ED and trauma settings
- Single significant wound often produces moderate pain (NRS 4–6) immediately

**Implication:** One moderate combat wound can reasonably map to NRS 4–5. First effect after 1–2 moderate hits is medically plausible.

### Combat Injury Research

- Combat stress can increase pain sensitivity (mechanosensitivity) in some models
- Chronic pain >80% in combat injury survivors
- Acute pain management affects recovery; early intervention important
- Stress and injury create compounded pain responses

---

## 3. Mapping to Game System

### Current Implementation (Method B)

- `effective_pain = total_pain / pain_reference`
- Thresholds: NRS 4 (first effect), 6 (moderate), 8 (severe), 10 (intolerable)
- Pain shock: NRS 7

### Pain Reference Divisor

| Divisor | Human ref | Hits to first effect (NRS 4) | Research alignment |
|---------|-----------|------------------------------|--------------------|
| 16 | 6 | ~4 moderate hits | Conservative; underestimates acute trauma impact |
| **32** | **3** | **~2 moderate hits** | **Research-aligned (Krebs 4–6 band; Option A)** |
| 64 | 1.5 | ~1 moderate hit | Maximum realism (57% trauma present NRS 5–10) |

**Recommended:** Divisor **32** — first effect after ~2 moderate hits. Aligns with Krebs (NRS 4–6 = functional impairment), Boonstra low-catastrophizing (moderate starts at 4), and acute trauma data, while avoiding excessive punishment from single hits.

---

## 4. Shock Threshold (NRS 7)

- Boonstra: severe pain ≥ 7–8
- Krebs: NRS 7–10 = 5.60× likelihood of interference
- Acute stress reaction / concussion: severe single impacts cause longer disorientation
- **NRS_SHOCK = 7.0** aligns with transition to severe pain and acute stress

---

## 5. Summary of Research-Aligned Values

| Constant | Value | Research basis |
|----------|-------|----------------|
| NRS_FIRST_EFFECT | 4.0 | Krebs 4–6 band; Boonstra low-catastrophizing; clinical consensus |
| NRS_MODERATE | 6.0 | Boonstra moderate 6–7; Krebs 4–6 upper bound |
| NRS_SEVERE | 8.0 | Boonstra severe ≥8 |
| NRS_INTOLERABLE | 10.0 | Scale maximum |
| NRS_SHOCK | 7.0 | Severe pain threshold; acute stress |
| Pain reference divisor | 32 | ~2 moderate hits to first effect; Krebs/Boonstra aligned |

---

## 6. References

- Krebs EE et al. (2007). Accuracy of the Pain Numeric Rating Scale as a Screening Test in Primary Care. *J Gen Intern Med* 22(10):1453–1458.
- Boonstra AM et al. (2016). Cut-Off Points for Mild, Moderate, and Severe Pain on the NRS. *Frontiers in Psychology* 7:1466.
- Emergency/trauma NRS distribution (SJTREM, EMS pain assessment)
- Pain after combat injury (PMC, UK military Afghanistan)
