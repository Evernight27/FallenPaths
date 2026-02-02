# Systems Audit: Medical Science & Physics vs Abstract/Gamey Numbers

Audit of bone health, bleeding, healing, cutting/blunt flesh, and attack physics against medical and physics research. **✓** = well-grounded; **~** = partially/approximately; **✗** = abstract or gamey with no direct research analogue.

---

## 1. Bone Health

### What’s research-based ✓

- **Severance/crush logic:** Part “destroyed” when tissue (cut or blunt) and bone both reach 0 — consistent with amputation/complete fracture plus tissue loss (StatPearls Vascular Extremity Trauma, mangled extremity).
- **Bone functionality tiers (CoreEntity):** Broken = 0%; severe fracture (~0–25% bone) ≈ 15%; 25–50% ≈ 40%; 50–75% ≈ 70%; 75–100% ≈ 92–95%. Matches literature on hip/lower-limb and arm/wrist strength and mobility loss (e.g. &lt;50% regain pre-fracture mobility).
- **Leg functionality:** Geometric mean of both legs, broken leg ≈ 0.08 mobility — reflects need for both legs in gait.
- **Bone healing:** Single duration (~6 weeks) with part multipliers — aligns with “simple fracture 6–8 weeks” (HealingConstants).

### What’s approximate or abstract ~/✗

- **BodyPartConstants thresholds/fractions:**  
  `_PART_BONE_THRESHOLD` (head 3, chest 8, arms 5, legs 6) and `_PART_BONE_FRACTION` (head 0.55, chest 0.30, limbs 0.38–0.42) are **tuned constants**. Medicine doesn’t give “damage ≥ X sends Y% to bone” per body part; the idea that higher-energy impacts fracture bone and that skull/head take more bone fraction is reasonable, but the exact numbers are **gamey**.
- **SpeciesResource bone_max (e.g. head 10, chest 18, arms 9, legs 12):** **Abstract**. No medical “bone HP” scale; these are game balance. Relative ordering (chest/head &gt; legs &gt; arms) is plausible; values are not derived from literature.

**Summary:** Logic (split to bone, functionality tiers, healing duration) is medically plausible. Per-part bone thresholds/fractions and numeric bone_max are design choices, not research-derived.

---

## 2. Bleeding

### What’s research-based ✓

- **ATLS blood volume classes:** Death/critical thresholds (remaining ≤35%, ≤30%) align with Class IV &gt;40% loss fatal (see BLEEDING_MEDICAL_ACCURACY.md).
- **Cut &gt; crush rates:** Penetrating (cut) more likely vessel involvement than blunt (crush); relative scaling matches trauma literature.
- **Body part multipliers:** Head/scalp and chest more vascular; head 1.5×, chest 1.2× is consistent with clinical descriptions.
- **Arterial chance:** Severity + injury type (cut vs crush) + body part, with penetrating neck ~25% vascular and blunt ~35% of cut chance — from vascular/penetrating-neck literature.
- **Arterial effect:** 2× bleeding rate, much slower clotting (0.15×) — arterial pressure and rapid exsanguination (2–5 min) are standard.
- **Clotting:** Normal wounds 2–7 min to stop; severe/critical clot slower (vessel involvement); arterial clots very slowly.

### What’s approximate or abstract ~/✗

- **BLEEDING_RATES (e.g. moderate cut 1.2 HP/s):** **Abstract**. No standard “ml/min per wound type” in literature; rates are **relative** and tuned for gameplay. Same for `BLOOD_LOSS_RATE_MULTIPLIER` (0.28) — scales “bleeding rate” to “% blood per second” for feel.
- **Bandage 60% immediate reduction:** **Gamey**. Real bandaging/hemostatic agents vary; 60% is a simple design choice.

**Summary:** Structure, thresholds, arterial logic, and relative scaling are medically grounded. Absolute bleeding rates and blood-loss multiplier are tuned, not calibrated to ml/min or clinical studies. **Research-based approximations** (bone thresholds, body_max from segment mass, exponential healing/clotting) are documented in **RESEARCH_BASED_APPROXIMATIONS.md**.

---

## 3. Healing

### What’s research-based ✓

- **Tissue healing durations (HealingConstants):** Minor ~4 days, moderate ~10 days, severe ~3 weeks, critical ~6 weeks — in line with wound healing phases (inflammatory 2–5 days, proliferation ~3 weeks, severe/critical longer).
- **Part multipliers:** Head/chest slower (1.15–1.25×) — depth and vascularity; limbs 1.0.
- **Bone healing:** 6 weeks base with part multipliers (skull/chest slower) — consistent with “simple fracture 6–8 weeks.”
- **Blood volume recovery:** 24 h to approach 100% when not bleeding — body replenishes over hours–days.
- **Worst wound severity sets tissue duration:** Medically plausible (worst injury drives healing time).

### What’s approximate or abstract ~/✗

- **Exact days (4, 10, 21, 42):** **Approximate**. Literature gives ranges (e.g. 3–5 days, 1–2 weeks, 3–6 weeks, 6+ weeks); chosen values are representative, not from a single study.
- **Linear heal rate `(max - cur) / duration`:** **Simplified**. Real healing is often nonlinear (fast early, plateau); linear is a tractable approximation.

**Summary:** Durations and part multipliers are medically plausible; exact numbers are rounded/representative. Healing model is intentionally simple.

---

## 4. Cutting and Blunt Flesh Health

### What’s research-based ✓

- **Dual pools (body_cutting / body_blunt):** Sharp vs blunt trauma have different mechanisms (laceration vs crush/contusion); separate pools are conceptually sound.
- **Severance (cutting 0 + bone 0) vs crushed (blunt 0 + bone 0):** Matches “part destroyed” by mechanism (amputation vs crush).
- **Vital parts (head, chest):** Death when vital part tissue 0 — standard (CNS, great vessels, heart/lungs).
- **Damage split tissue vs bone:** Above threshold, a fraction goes to bone — reflects “enough force fractures bone and damages soft tissue.”
- **Wounds drive bleeding:** Tissue damage (to_cut, to_blunt) creates injuries with severity — consistent with injury-based hemorrhage.

### What’s approximate or abstract ~/✗

- **body_max per part (SpeciesResource: head 15, chest 25, limbs 15):** **Abstract**. No medical “tissue HP” scale; these are game values. Ordering (chest &gt; head ≈ limbs) is plausible; numbers are not from research.
- **Bone threshold/fraction (BodyPartConstants):** As above — concept is right, numeric constants are tuned.
- **Arm “destroyed” when cutting 0 OR blunt 0:** Simplified; in reality a limb can be non-functional with some tissue remaining (e.g. nerve/vessel damage). Acceptable abstraction for “no longer usable for attack.”

**Summary:** Two-pool and vital-part logic are medically sensible. body_max and bone split constants are game balance, not calibrated to real tissue “capacity.”

---

## 5. Attack Physics

### What’s research-based ✓

- **Kinetic energy:** KE = ½ m v² (WeaponDamageHelper) — standard physics.
- **Strike velocity range (6–18 m/s):** Within reported ranges for melee (e.g. rod-like strikes ~17–24 m/s); your range is slightly conservative, which is reasonable for “effective” impact.
- **Damage scales with sqrt(KE):** Common game approximation for “damage from energy” (diminishing returns with energy); not a direct law of biology but a reasonable monotonic link.
- **Contact area:** Smaller contact (stab) → higher pressure → more penetration and local damage — correct physically.
- **Blunt penetration:** Pressure (MPa) = scale × KE / area — impact pressure is force/area; scaling to MPa for armor comparison is plausible.
- **Sharp penetration (mm RHA):** Common way to compare penetration; J_PER_MM_RHA (130) and layer resistances (0.5–3.5 mm) are in the right ballpark (mild steel, arrow tests ~80–120 J).
- **Parry:** Capacity ∝ defender mass × parry speed × strength; success vs attacker momentum (mass × velocity at progress) — impulse/momentum idea is physically reasonable. V_PARRY_TYPICAL_M_S (8 m/s) is a plausible parry speed.
- **Deflection (armor):** Sharp fails to penetrate → convert to blunt and reduce — reflects “armor stops edge, transmits blunt trauma.”

### What’s approximate or abstract ~/✗

- **DAMAGE_KE_SCALE (2.6), DAMAGE_KE_MIN/MAX (1–80):** **Tuned**. No biological “damage = f(KE)” formula; scaling and caps are for gameplay.
- **J_PER_MM_RHA = 130:** **Approximate**. “1 mm mild steel ≈ 55 J” is cited in comments; 130 is a different scaling choice (e.g. velocity range, balance). Not wrong, but not a single research number.
- **Wind-up / recovery times (e.g. WIND_UP_BASE_S 0.25, RECOVERY_BASE_S 0.2):** **Gamey**. Real strike times vary (weapon, technique); these are short for responsive combat. No direct “medical” or “physics” source for exact seconds.
- **INTENSITY_STRENGTH_SCALE (0.5), INTENSITY_STRENGTH_NORM (12):** **Abstract**. Strength affecting “commitment” and thus velocity is plausible; 0.5 and 12 are tuning.
- **MISS_CHANCE_BASE (0.06):** **Abstract**. Represents “no contact”; 6% is a design choice.
- **DEFLECTED_DAMAGE_RATIO (0.25):** **Gamey**. “Deflected = most damage absorbed” is right; 25% through is a balance constant.
- **PARRY_MOMENTUM_FACTOR (0.5):** **Tuned**. Success when capacity ≥ momentum × 0.5 is a simple rule, not from a single study.
- **RHA_TO_MPA (0.6):** **Conversion choice**. Relates sharp penetration (mm RHA) to blunt (MPa) for deflection; approximate, not a standard conversion in literature.
- **Armor layer numbers (sharp_resistance_rha_mm, blunt_resistance_mpa):** Ordering (cloth &lt; leather &lt; mail &lt; plate) and rough magnitudes are plausible; exact values are **tuned** (e.g. arrow vs mail ~80–120 J mentioned in ArmorConstants).

**Summary:** Core physics (KE, velocity range, pressure/area, parry momentum vs capacity) are sound. Damage scaling, timing constants, miss/deflect/parry factors, and armor numbers are gameplay and balance choices.

---

## 6. Overall Table

| System              | Research-based / plausible                    | Abstract / gamey                                      |
|---------------------|-----------------------------------------------|-------------------------------------------------------|
| Bone health         | Severance/crush, functionality tiers, 6 wk heal | Per-part threshold/fraction, bone_max values         |
| Bleeding            | ATLS thresholds, cut&gt;crush, arterial %, clotting | Absolute BLEEDING_RATES, BLOOD_LOSS_RATE_MULTIPLIER  |
| Healing             | Tissue/bone durations, part mults, blood 24 h | Exact days, linear heal curve                         |
| Cutting/blunt flesh | Two pools, vitals, tissue/bone split, wounds  | body_max, bone split constants                       |
| Attack physics      | KE = ½mv², velocity range, pressure/area, parry | DAMAGE_KE_*, timing, miss/deflect/parry factors, armor values |

---

## 7. Recommendations (optional tightening)

1. **Bone:** Add short comments in BodyPartConstants citing “bone fraction by part” as a design choice (no clinical “X% to bone” per part). Optionally cross-link to fracture literature (e.g. “simple fracture 6–8 weeks”) in HealingConstants if not already.
2. **Bleeding:** Already documented in BLEEDING_MEDICAL_ACCURACY.md. No change needed unless you want to calibrate BLOOD_LOSS_RATE_MULTIPLIER to a target “% per minute” for a reference wound.
3. **Healing:** Add one-line references in HealingConstants (e.g. “wound healing phases; fracture 6–8 weeks”) so future readers see the intent.
4. **Species body_max/bone_max:** In SpeciesResource or a design doc, state that these are abstract “capacity” values for gameplay, not from tissue/bone strength studies.
5. **Attack physics:** In WeaponConstants/CombatManager, add brief comments that DAMAGE_KE_SCALE, timing constants, MISS_CHANCE_BASE, DEFLECTED_DAMAGE_RATIO, and PARRY_MOMENTUM_FACTOR are tuned for gameplay; core model is KE + contact area + parry momentum.

If you want, the next step can be adding these comments and references in the actual script files (BodyPartConstants, HealingConstants, SpeciesResource, WeaponConstants, CombatManager) and a one-line “see SYSTEMS_MEDICAL_AND_PHYSICS_AUDIT.md” in each.
