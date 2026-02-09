# Balancing Investigation: Medical Accuracy & Physics

Summary of your current numbers vs. research, and concrete changes to make the system more medically accurate and physics-driven.

---

## 1. Physics: Penetration & Armor

### J_PER_MM_RHA (WeaponConstants.gd)

| Current | Research | Recommendation |
|---------|----------|----------------|
| **130** | ~55 J per mm mild steel (common ballpark); 130 makes armor *harder* to penetrate than in reality | **80** – closer to “55 J/mm” realism; armor fails more often for the same KE |

**Effect:** At 160 J (e.g. your Character→Goblin slash), penetration sharp = 160/130 × area_factor ≈ 1.23 × factor. With 80: 160/80 = 2.0 × factor → ~60% more penetration, so armor is more meaningful but less “tanky.”

---

### Velocity range (WeaponConstants.gd)

| Current | Research | Recommendation |
|---------|----------|----------------|
| **6–18 m/s** | Peak strike speeds ~17–24 m/s (rod-like strikes 17.2–23.9 m/s) | **6–20 m/s** – allow near-peak strikes; 18 is already plausible, 20 aligns with high-end research |

**Effect:** Slightly higher max KE (≈ ½ m × 20² vs 18²) and damage cap; more differentiation between light and committed swings.

---

### Blunt pressure (WeaponDamageHelper / WeaponConstants)

- **BLUNT_PRESSURE_SCALE = 500**, **MIN_BLUNT_AREA_M2 = 1e-6**.
- For a **cut** attack, combat uses both sharp and blunt penetration. Blunt uses the same contact width as the attack (e.g. blade 2 cm → area π×(0.01)² ≈ 3.14e-4 m²). Pressure = 500 × KE / A / 1e6 → ~255 MPa for 160 J and 2 cm.
- If contact were very small (e.g. 0.2 cm), area would hit **MIN_BLUNT_AREA_M2 = 1e-6**, giving very high MPa (e.g. 80,000 MPa). So a **floor area** of **1e-4 m² (1 cm²)** is safer: small contacts don’t produce absurd blunt pressure while normal blades are unchanged.

**Recommendation:** Set **MIN_BLUNT_AREA_M2 = 1e-4** so blunt pressure is capped for tiny contacts; no change to normal slash/stab area.

---

## 2. Body part capacity (segment mass)

### Research (de Leva 1996, Plagenhoef 1983)

- Head+neck ~**7%** body mass  
- Trunk ~**43%**  
- Each arm ~**4.7%**  
- Each leg ~**20.4%**  

So **chest > leg > head ≈ arm**.

### Current (SpeciesResource defaults)

- head **12**, chest **28**, arm **12**, leg **28** → head = arm, chest = leg (arm and head too large relative to chest).

### Recommendation

- Default **body_max** proportions: **head 10**, **chest 30**, **arm 10**, **leg 26** so chest is largest, then leg, then head/arm.
- Existing .tres (Human, Goblin) can stay as-is; new species or rebalances can use these defaults. Human currently 15/25/15/15 – you may align to 10/30/10/26 for more “segment mass” consistency if desired.

---

## 3. Blood loss & bleeding (medical)

### Death / critical thresholds (BleedingConstants)

| Constant | Current | Research | Status |
|----------|---------|----------|--------|
| BLOOD_LOSS_DEATH_THRESHOLD | 35% remaining | Class IV >40% loss fatal; ~35–50% remaining lethal | **OK** |
| BLOOD_LOSS_CRITICAL_THRESHOLD | 30% | Class III–IV border | **OK** |

No change needed.

### Time to exsanguination (arterial)

- **Research:** Uncontrolled arterial bleed can lead to exsanguination in **2–5 minutes**.
- **Current:** BLOOD_LOSS_RATE_MULTIPLIER = **0.28**. So 1 “rate point” = 0.28% blood per second. A single critical cut (e.g. base rate 4.5, ×2 arterial = 9, × part mult) can give e.g. total rate ~5–10. At rate 9: 9×0.28 = 2.52%/s → 65% loss in ~26 s (faster than 2–5 min).
- **Recommendation:** If you want **2–5 min** to death from one severe arterial wound, **lower BLOOD_LOSS_RATE_MULTIPLIER**. Example: **0.10** → at rate 9, 0.9%/s → 65% in ~72 s; at rate 5, 0.5%/s → 65% in ~130 s (≈2 min). So **0.08–0.12** bands arterial exsanguination in the 2–5 min range. Keep **0.28** if you prefer faster, more lethal combat.

---

### Clotting & severity (BleedingConstants)

- **CLOTTING_SEVERITY_MULTIPLIERS:** minor 1.5×, moderate 1.0×, severe 0.5×, critical 0.25× – already aligned with “minor stops in seconds, severe/critical slower.”
- **Cut > crush**, **arterial chance** by severity/part/sub-region – already research-based per BLEEDING_MEDICAL_ACCURACY.md.

No change needed for medical consistency.

---

## 4. Healing (HealingConstants)

- Tissue durations: minor ~4 d, moderate ~10 d, severe ~3 wk, critical ~6 wk – **OK**.
- Bone: ~6 weeks – **OK**.
- Blood recovery: 24 h when not bleeding – **OK**.
- Exponential healing (τ = duration/3) – **OK** per RESEARCH_BASED_APPROXIMATIONS.md.

No change needed.

---

## 5. Bone & tissue (BodyPartConstants, species)

- **Bone thresholds:** Skull low (2–3), abdomen high (10), limbs mid (4–6) – matches skull 4–23 J, femur ~35 J, tibia ~25 J. **OK.**
- **Bone fractions:** Head 0.55, chest 0.30, limbs 0.38–0.42 – **OK.**

Only optional tweak is **body_max** proportions (see §2).

---

## 6. Damage vs energy (WeaponDamageHelper)

- **Pre-armor ∝ √(KE)** – sublinear injury–energy link (CIREN/NHTSA). **OK.**
- **DAMAGE_KE_SCALE = 2.6**, **DAMAGE_KE_MIN/MAX = 1–80** – tuned; form is physics-consistent.
- **Contact damage factor:** (baseline/contact_width)^0.3, cap 2.0 – stab concentrates damage. **OK.**

No change needed.

---

## 7. Summary of recommended code changes

| Item | File | Current | New | Reason |
|------|------|---------|-----|--------|
| J_PER_MM_RHA | WeaponConstants.gd | 130 | **80** | Closer to 55 J/mm; armor more physics-driven |
| VELOCITY_MAX_M_S | WeaponConstants.gd | 18 | **20** | Near-peak strike speeds (17–24 m/s) |
| MIN_BLUNT_AREA_M2 | WeaponConstants.gd | 1e-6 | **1e-4** | Avoid huge blunt MPa from tiny contacts |
| body_max defaults | SpeciesResource.gd | 12/28/12/28 | **10/30/10/26** | Segment mass: chest > leg > head = arm |
| BLOOD_LOSS_RATE_MULTIPLIER | BleedingConstants.gd | 0.28 | **0.10** (applied) | 2–5 min to exsanguination for arterial; revert to 0.28 for faster lethality |

---

## 8. Optional only (document, don’t change)

- **BLOOD_LOSS_RATE_MULTIPLIER:** 0.10 is now applied for 2–5 min arterial exsanguination; set back to **0.28** in BleedingConstants.gd if you prefer faster, more lethal bleeding.
- **Human/Goblin .tres:** Adjust body_max to 10/30/10/26 (and bone to taste) if you want all species to follow segment-mass proportions.
- **VELOCITY_MIN_M_S:** 6 is fine; literature supports low-end combat speeds in that range.

---

## 9. What not to change

- ATLS blood thresholds (35% death, 30% critical).
- Cut > crush, arterial chance, clotting severity multipliers.
- Bone threshold/fraction ordering.
- Damage ∝ √(KE), contact factor, exponential clotting/healing.
- RHA_TO_MPA, BLUNT_PENETRATION_REDUCTION, DEFLECTION_* – ordering matters; exact values are tuned.
