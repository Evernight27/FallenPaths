# Bleeding Model – Medical Accuracy Reference

Summary of clinical sources and how they map to the game’s bleeding system (injury types, severity, blood volume, clotting, death).

---

## 1. Blood Volume and Lethal Loss

- **Adult blood volume:** ~4.5–5.5 L (we treat 100% = full volume).
- **Hemorrhage classes (ATLS / trauma):**
  - **Class I:** &lt;15% loss – minimal symptoms, normal vitals.
  - **Class II:** 15–30% – tachycardia, slight deviation from normal.
  - **Class III:** 30–40% – tachycardia, hypotension, confusion; transfusion often needed.
  - **Class IV:** &gt;40% – severe shock, altered mental status, often fatal without intervention.
- **Lethal threshold:** &gt;40% loss is “typically fatal without immediate intervention”; ~50% loss is often fatal. So death when **remaining** volume is roughly **35–50%** (i.e. 50–65% lost).
- **Game mapping:** `BLOOD_LOSS_DEATH_THRESHOLD = 35` → death when remaining ≤35% (65% lost), in line with Class IV. `BLOOD_LOSS_CRITICAL_THRESHOLD = 30` → critical state when remaining ≤30% (Class III–IV border).

*Sources: StatPearls Hemorrhage Control (NBK535393), Hypovolemic Shock (NBK513297), Healthline/hematology summaries.*

---

## 2. Bleeding Types (No Exact ml/min in Literature)

Clinical descriptions are qualitative; exact “ml/min by wound type” are not standard.

- **Arterial:** Spurting/pulsatile, bright red, high pressure. Can lead to exsanguination in **2–5 minutes** without control. Leading cause of preventable trauma death.
- **Venous:** Steady flow, dark red, lower pressure than arterial.
- **Capillary:** Oozing, slow, often easiest to control (superficial).

**Game mapping:**

- **Cut (sharp)** → lacerations/punctures → more likely to open arteries/veins → **higher bleeding rates** than crush.
- **Crush (blunt)** → blunt trauma → more capillary/bruising, some venous → **lower bleeding rates** than cut for same severity.

So cut &gt; crush in `BLEEDING_RATES` is medically consistent. Exact numbers are tuned for gameplay; relative scaling (cut &gt; crush, critical &gt; minor) follows medicine.

---

## 3. Wound Depth / Severity

- **Superficial (skin only):** Minimal bleeding, often self-limiting.
- **Deep (fat, muscle, vessels):** Can bleed heavily; vessel involvement matters more than depth alone.
- **Face/scalp:** Dense capillaries → bleed heavily even when relatively superficial.

**Game mapping:** Severity from damage (minor/moderate/severe/critical) approximates “how bad the wound is.” Body-part multipliers (head &gt; chest &gt; limbs) reflect scalp/face and truncal vessel density.

---

## 4. Clotting / Cessation of Bleeding

- **Normal wounds:** Bleeding often stops within **2–7 minutes** (platelet plug + fibrin); small cuts may stop in seconds.
- **Arterial bleeding:** High pressure can **impair clotting**; wounds may not seal without direct pressure or intervention.

**Game mapping:**

- Per-severity clotting rates (`CLOTTING_RATE_BY_SEVERITY`) reduce bleeding rate over time (natural hemostasis): minor fastest, moderate normal, severe/critical slower (vessel involvement).
- **Arterial wounds** use `ARTERIAL_CLOTTING_MULTIPLIER` (0.15×) on top of the severity rate so they clot very slowly.

---

## 5. Arterial vs Regular Bleeding (Chance by Severity, Type, Location)

Literature does not give exact “% arterial per wound,” but we can derive plausible chances:

- **Penetrating vs blunt:** Penetrating trauma accounts for **64–82%** of extremity vascular injuries; blunt for the remainder. So **cut (penetrating)** has a higher base chance of arterial involvement than **crush (blunt)**; we use `ARTERIAL_CRUSH_MULTIPLIER = 0.35` so blunt arterial chance is ~35% of cut’s.
- **Soft signs:** In penetrating extremity trauma, **one soft sign** has ~**10%** rate of vascular injury; **two or more soft signs** ~**25%**. We map severity to depth/vessel involvement: minor (superficial) very low, moderate low, severe/critical in that 10–25% range.
- **Penetrating neck:** Vascular injury in **~25%** of penetrating neck trauma (carotid, vertebral, jugular). Head/scalp and neck are highly vascular → we use a **body-part multiplier** for arterial chance: head 1.4×, chest 1.2×, limbs 1.0×.
- **Overall incidence:** Vascular injuries are **~1%** of all traumatic injuries to extremities, so most wounds are not arterial; our base chances by severity keep the majority of wounds venous/capillary, with a minority arterial.

**Formula:** `arterial_chance = base_by_severity × (if crush: 0.35 × SUB_REGION_BLUNT_ARTERIAL_MODIFIER[part][sub_region]; else 1.0) × part_mult × sub_region_arterial_mult`, clamped to [0,1]. So **cut vs blunt differentiation is region-specific**: blunt neck/chest much less often arterial than cut; blunt knee (popliteal) relatively more often arterial.

**Cut vs blunt by region (research-based):**
- **Neck:** Penetrating accounts for ~85% of head/neck neurovascular cases requiring treatment; blunt carotid/vertebral rarer → blunt modifier **0.5**.
- **Thoracic/abdominal:** Penetrating predominates for great-vessel and abdominal vascular injury; blunt thoracic aortic &lt;5% of vascular trauma → thoracic **0.5**, abdominal **0.6**.
- **Scalp/face:** Superficial temporal artery is the most frequently injured vessel in *blunt* cephalovascular trauma (~80% in one review), so blunt can still cause arterial injury → scalp **0.9**, face **0.75**.
- **Lower limb:** Popliteal most common in *blunt* LE trauma (knee dislocation); SFA most common in *penetrating* → thigh blunt **0.6**, knee blunt **1.25** (blunt relatively higher at knee). Calf/foot **0.9**.
- **Upper limb:** Forearm vessels “most frequently injured regardless of mechanism” → forearm **1.0**; upper_arm/elbow/hand **0.85–0.9**.

**When a wound is arterial:** We roll once at wound creation. If arterial: `current_bleeding_rate` is multiplied by `ARTERIAL_BLEEDING_MULTIPLIER` (2.0), and clotting is multiplied by `ARTERIAL_CLOTTING_MULTIPLIER` (0.15) so arterial wounds seal very slowly (pressure inhibits clotting).

*Sources: StatPearls Vascular Extremity Trauma (NBK536925); penetrating neck vascular ~25%, penetrating 85% neck neurovascular (TSACO, head/neck neurovascular trauma); blunt vs penetrating thoracic/abdominal (UpToDate, trauma registries); popliteal blunt / SFA penetrating (ClinicalPub, extremity vascular); scalp STA blunt (PubMed 40062961, blunt vascular face/scalp).*

---

## 6. Body Part Multipliers

- **Head/scalp:** Very vascular → heavy bleeding even from small wounds.
- **Chest/trunk:** Major vessels, compressible vs non-compressible matters in reality; we use a single “chest” multiplier.
- **Limbs:** Standard reference (1.0).

**Game mapping:** `BODY_PART_BLEEDING_MULTIPLIERS`: head 1.5, chest 1.2, limbs 1.0.

---

## 7. Recommended Implementation Tweaks

1. **Death threshold:** Set `BLOOD_LOSS_DEATH_THRESHOLD` to **35** (death when remaining ≤35%) to align with Class IV / “&gt;40% loss fatal.”
2. **Critical threshold:** Keep `BLOOD_LOSS_CRITICAL_THRESHOLD` at **30** for UI/effects (critical state when remaining ≤30%).
3. **Slower clotting for severe/critical:** In `process_bleeding()`, apply a **lower effective clotting rate** for severe and critical injuries (e.g. 0.5× or 0.25×) so arterial-like wounds don’t seal as fast.
4. **Keep current structure:** Injury type (cut/crush), severity (minor→critical), body part multipliers, blood % with a single death and critical threshold, and bandaging all remain; only constants and optional clotting-by-severity are refined for medical accuracy.
5. **Arterial chance:** Each wound rolls `get_arterial_chance(severity, injury_type, part)`; if roll succeeds, the wound is arterial (2× bleeding rate, 0.15× clotting).

### 7a. Fine-tunes applied (implementation)

- **CLOTTING_SEVERITY_MULTIPLIERS:** Minor 1.5× (faster clot, "stop in seconds"), moderate 1.0×, severe 0.5×, critical 0.25×. Used in `process_bleeding()` via `get_clotting_multiplier(sev)` so minor wounds clot faster and severe/critical slower (MINOR_WOUND_BLEEDING_METHODS Method 1, §7 item 3).
- **BLEEDING_RATE_EPSILON (0.001):** Wounds are removed when `rate <= epsilon` (not only when rate hits 0), so clotted wounds are reliably removed without relying on float underflow (MINOR_WOUND_BLEEDING_METHODS Method 4).
- **Bandage on arterial:** `BANDAGE_ARTERIAL_EFFECTIVENESS_MULT` set to **0.5** (50% of reduction) so simple bandages are less effective on arterial wounds; when bandaged and arterial, clotting uses `CLOTTING_RATE_STABILIZED * ARTERIAL_CLOTTING_MULTIPLIER` so arterial wounds still clot slower even with pressure.
- **Bleeding rate variance:** At wound creation, `base_rate *= randf_range(BLEEDING_RATE_VARIANCE_MIN, BLEEDING_RATE_VARIANCE_MAX)` (default 0.9–1.1) to simulate hit in a more/less vascular spot (§10).

---

## 8. Sources (short)

- StatPearls: Hemorrhage Control (NBK535393) – types, ATLS classes, management.
- StatPearls: Hypovolemic Shock (NBK513297) – volume loss, classes, physiology.
- StatPearls: Hemorrhagic Shock (NBK470382) – shock stages.
- Truerescue / CPR Care: arterial bleed-out 2–5 min, volume thresholds.
- Cleveland Clinic / Hopkins: hemostasis 2–7 min, wound healing.
- European trauma guidelines (Crit Care): massive hemorrhage definitions, classes.
- StatPearls: Vascular Extremity Trauma (NBK536925) – penetrating vs blunt, extremity vascular 1%, soft signs.
- Penetrating neck trauma (PMC5849205, TSACO): vascular injury ~25%; carotid, vertebral, jugular.

Literature does **not** provide exact “ml/min per wound type” or “% arterial per wound”; the game uses **relative** scaling (cut &gt; crush, critical &gt; minor, head &gt; chest &gt; limbs), **class-based** blood volume thresholds (Class I–IV), and **research-based** arterial chance by severity, injury type, and body part for a medically plausible model.

---

## 9. Accuracy Summary (With Per-Severity Clotting)

With the current implementation (per-severity clotting rates, arterial roll, body-part multipliers, bandaging):

| Aspect | Accuracy | Notes |
|--------|----------|--------|
| **Blood volume & death** | **High** | ATLS Class I–IV; death ≤35% remaining (65% lost) matches "typically fatal &gt;40% loss." |
| **Cut vs crush** | **High** | Cut &gt; crush rates and cut &gt; crush arterial chance; matches penetrating vs blunt. |
| **Severity → depth** | **High** | Minor/moderate/severe/critical from damage; maps to superficial → deep/vessel. |
| **Clotting by severity** | **High** | Minor ~1.2 min, moderate ~4 min, severe ~8 min, critical ~15 min; arterial ~25 min. Matches "small cuts stop in seconds," "normal 2–7 min," "arterial needs intervention." |
| **Arterial chance** | **High** | Probabilistic by severity, type, part, sub-region; soft-sign / neck vascular rates in plausible range. |
| **Cut vs blunt by region** | **High** | SUB_REGION_BLUNT_ARTERIAL_MODIFIERS: neck/chest blunt 0.5–0.6; knee blunt 1.25 (popliteal); thigh blunt 0.6 (SFA penetrating); scalp/forearm moderate. Research-based. |
| **Body part multipliers** | **High** | Head &gt; chest &gt; limbs for bleeding and arterial; scalp/trunk more vascular. |
| **Sub-regions** | **High** | Per–body-part sub-regions (scalp/face/neck, thoracic/abdominal, upper_arm/elbow/forearm/hand, thigh/knee/calf/foot) with **individual units** for target weight (within part), bleeding, arterial, severity modifier, and bone threshold/fraction; research-based. See **SUB_REGIONS_MEDICAL_SOURCES.md**. |
| **Body-part targeting** | **High** | Weapon hit part chosen by **weighted random** (BodyPartConstants.BODY_PART_TARGET_WEIGHTS) from body surface area/exposure (NCBI NBK224908); chest and legs more likely than head/arms. |
| **Bandaging** | **Plausible** | Immediate reduction + fast clotting when stabilized; arterial less effective. |
| **Absolute bleeding rates** | **Abstract** | No real "ml/min" calibration; rates are relative and tuned for gameplay. |

**Overall:** The **structure and relative behavior** are medically accurate; **absolute numbers** (e.g. BLEEDING_RATES, BLOOD_LOSS_RATE_MULTIPLIER) are tuned for feel, not calibrated to ml/min. **Sub-regions** provide hit-location variation within each body part (bleeding, arterial chance, severity modifier, bone threshold/fraction per sub-region).

---

## 9a. Medical number audit (double-check)

Each key number checked against literature; **OK** = consistent, **Tuned** = no exact clinical value, relative scaling correct.

| Constant | Value | Medical check |
|----------|--------|----------------|
| **BLOOD_LOSS_DEATH_THRESHOLD** | 35 (remaining %) | **OK.** ATLS Class IV &gt;40% loss = life-threatening/fatal; ~50% loss = significantly elevated mortality. Death at 35% remaining = 65% lost is in fatal range (StatPearls NBK535393, NBK513297). |
| **BLOOD_LOSS_CRITICAL_THRESHOLD** | 30 (remaining %) | **OK.** Class III–IV border; critical state when remaining ≤30%. |
| **ARTERIAL_CRUSH_MULTIPLIER** | 0.35 | **OK.** Blunt arterial chance = 35% of cut’s. Literature: penetrating 64–82% of extremity vascular injuries, blunt 18–36% (StatPearls NBK536925). 0.35 in range; per-region blunt modifiers refine by body part. |
| **ARTERIAL_CHANCE_BY_SEVERITY** | 0.01, 0.06, 0.14, 0.26 | **OK.** Minor low (superficial); moderate 6%; severe 14% (soft-sign 10–25%); critical 26% (penetrating neck vascular ~25%, 2+ soft signs ~25%). |
| **ARTERIAL_BLEEDING_MULTIPLIER** | 2.0 | **Tuned.** Arterial bleeds much faster; no exact “×2” in literature; relative &gt;1 correct. |
| **ARTERIAL_CLOTTING_MULTIPLIER** | 0.15 | **Tuned.** Pressure impairs clotting; “very slow” modeled as 0.15× severity rate. |
| **CLOTTING_RATE_BY_SEVERITY** | 0.05, 0.02, 0.01, 0.005 | **OK.** Minor half-life ~14 s (“small cuts stop in seconds”); moderate ~35 s (~4 min to ~1% rate); normal wound 2–7 min (Cleveland Clinic hemostasis). Severe/critical slower (vessel involvement). |
| **CLOTTING_RATE_STABILIZED** | 0.15 | **Tuned.** Bandaged = fast clotting; value for gameplay. |
| **BODY_PART_BLEEDING_MULTIPLIERS** | head 1.5, chest 1.2, limbs 1.0 | **OK.** Head/trunk more vascular than limbs (qualitative). |
| **SEVERITY_PERCENTAGE_*** | 0.25, 0.5, 0.75 | **Tuned.** Depth tiers; no exact % in literature; ordering correct. |
| **SEVERITY_ABSOLUTE_*** | 2, 5, 10 | **Tuned.** Ensures small parts can reach severe/critical from absolute damage. |
| **BANDAGE_*** | 0.6, 0.5, 300 | **Tuned.** Immediate reduction 60%; arterial effectiveness 50% (simple bandage less effective on arterial). |
| **BODY_PART_TARGET_WEIGHTS** | head 1.2, chest 2.7, arms 1, legs 2 | **OK.** NCBI NBK224908: head/neck 12%, thorax 16%, abdomen 11%, extremities 61%. Chest 2.7 ≈ 27%, legs 2 each ≈ 20%, head 1.2 ≈ 12%, arms 1 ≈ 10%. |
| **Bone thresholds/fractions** | BodyPartConstants | **OK.** Skull 4–23 J (low threshold); femur ~35 J, tibia ~25 J (RESEARCH_BASED_APPROXIMATIONS.md). Ordering and sub-region split consistent. |
| **SUB_REGION_*** (bleeding, arterial, blunt mod) | Various | **OK.** Relative scaling from anatomy/vascular literature; no exact per–sub-region numbers in studies. See SUB_REGIONS_MEDICAL_SOURCES.md. |

**Summary:** Blood volume thresholds, ATLS alignment, arterial severity/crush proportions, clotting half-lives, and body-part/target weights match or are consistent with cited sources. Bleeding rates, bandaging, and severity bands are **tuned** (relative scaling correct; no ml/min or exact % calibration).

---

## 9b. Scaling: % vs ml/min

**Current system (percentage):** Blood volume is 0–100%. Bleeding rates are **abstract** (unitless); `loss = total_bleeding_rate × BLOOD_LOSS_RATE_MULTIPLIER × delta` gives % lost per second. Death at ≤35% remaining. Pros: simple, no need to fix total volume; cons: rates are not directly comparable to literature.

**Would ml/min be more accurate?** Only in a **limited** sense:

- **What literature gives:** Life-threatening hemorrhage is defined as blood loss **&gt;150 ml/min** sustained (e.g. 20+ min). ATLS classes are also given in **ml** (Class I ≤750 ml, II 750–1500, III 1500–2000, IV &gt;2000). So we have **one clear anchor** (150 ml/min ≈ life-threatening) and **volume bands** in ml (750 / 1500 / 2000 for a ~5 L adult).
- **What literature does not give:** Exact “ml/min per wound type” or “ml/min by severity.” Venous and capillary rates are described qualitatively (slow, oozing), not as standard ml/min values. So we could not fully “calibrate” every severity/type to a published number.

**If you switched to ml/min:**

1. **Store volume in ml** (e.g. `blood_volume_ml = 5000`; adult ~4.5–5.5 L).
2. **Define bleeding rates in ml/min** per wound (e.g. minor 5–15, moderate 20–50, severe 50–120, critical 100–200; arterial ×2; crush ~0.5× cut), with 150 ml/min as the “life-threatening” reference for severe/critical arterial.
3. **Apply loss:** `blood_volume_ml -= (total_bleeding_rate_ml_per_min / 60.0) * delta_seconds`.
4. **Death/critical:** Same logic as now: death at 35% of 5000 = **1750 ml** remaining; critical at 30% = **1500 ml**. Clotting would still decay each wound’s rate (same math, in ml/min).

**Accuracy:** You’d gain (1) real units, (2) a direct link to “&gt;150 ml/min = life-threatening” and ATLS ml bands, and (3) easier comparison to any future sources that do give ml/min. You would **not** get “evidence-based ml/min” for every severity/type, because those numbers are not standard in the literature. So **relative** scaling (cut &gt; crush, severe &gt; minor, arterial worst) would still be chosen by you; only the **scale** would be in ml/min.

**Recommendation:** Keeping **%** is medically fine (death/critical at 35%/30% are correct; relative rates are consistent with anatomy). Switching to **ml/min** is optional for clarity and one-to-one mapping to 150 ml/min and ATLS ml classes; it would require refactoring storage and constants but would not add new evidence for every number.

---

## 9c. ml/min system: lower-intensity rates and blunt (crush) damage

**Research findings**

- **Single rate anchor:** Life-threatening hemorrhage = blood loss **&gt;150 ml/min** sustained (e.g. 20+ min). So critical/arterial can be calibrated to the 100–200 ml/min range; everything else is scaled below that.
- **Volume bands (no rate):** ATLS/European guidelines give **total loss** per class (Class I &lt;750 ml, II 750–1500, III 1500–2000, IV &gt;2000 ml for ~5 L adult), not “ml/min per severity.” So we have no published “minor = X ml/min” or “venous = Y ml/min.”
- **Lower-intensity (minor/moderate):** Literature describes capillary as “trickling,” venous as “steady but slower than arterial,” and arterial as “spurting.” No standard ml/min for minor or venous wounds. So **lower-intensity rates must be derived** from (1) the 150 ml/min anchor at the top and (2) plausible time-to-reach Class I/II loss (e.g. minor wound shouldn’t reach 750 ml in a few minutes; moderate might over 15–30 min).
- **Blunt vs penetrating:** Penetrating trauma is associated with **higher rates of major hemorrhage** (e.g. 4.54× more likely massive transfusion in one study) than blunt; blunt can still cause major hemorrhage (e.g. 58% of massive transfusion was blunt in another series) but **per incident** penetrating has higher hemorrhage rate. So in an ml/min model, **blunt (crush) should use the same severity tiers but with a lower rate**—i.e. a **crush multiplier** (e.g. 0.5–0.55) applied to the cut rate for that severity. That matches your current design (cut &gt; crush) and works in ml/min: same ml/min table for “cut,” and “crush” = cut × crush_multiplier.

**Derived ml/min bands (for implementation)**

No study gives exact ml/min per severity; the following is **derived** from the 150 ml/min anchor and Class I–IV volumes so that times to loss are plausible:

| Severity   | Cut (ml/min) range | Rationale |
|------------|----------------------|-----------|
| Minor      | 5–15                 | Capillary/venous “trickle”; &lt;750 ml (Class I) in 30–60+ min if untreated. |
| Moderate   | 20–50                | Venous/small vessel; 750 ml in ~15–35 min. |
| Severe     | 50–120               | Deeper vessel involvement; approaches life-threatening; 1500 ml in ~12–30 min. |
| Critical   | 100–200              | Life-threatening &gt;150 ml/min; 2000 ml in ~10–20 min. |
| Arterial (any) | 2× above         | Same as now: arterial doubles the rate for that wound. |

**Crush (blunt):** Use the **same table**, but multiply the rate by a **crush multiplier** (e.g. **0.5–0.55**). So e.g. “moderate crush” = 20–50 × 0.55 ≈ 11–28 ml/min. That keeps cut &gt; crush, matches “penetrating higher hemorrhage rate per case,” and works with the same clotting/severity logic. Body-part and sub-region multipliers (head/scalp, etc.) then apply on top of this base rate in ml/min, same as they do now in abstract units.

**Does ml/min work with blunt?** Yes. Blunt damage is handled by (1) assigning the same severity (minor/moderate/severe/critical) from damage and (2) applying a **crush multiplier** to the cut ml/min rate so that blunt bleeds less per wound than cut at the same severity. No separate “blunt ml/min table” is needed; one table (cut) + one multiplier (crush) is consistent with the literature and your current design.

*Sources: Life-threatening &gt;150 ml/min (critical bleeding guidelines); ATLS/European Class I–IV by volume (Crit Care, cc12685); penetrating 4.54× more likely major hemorrhage (J Trauma); capillary/venous qualitative (Healthline, StatPearls).*

---

## 9d. Multiple enemy types: varying blood volumes and bleeding rates — % vs ml/min

**If you plan multiple enemy types** (e.g. goblin, human, ogre) with **different total blood volumes** and optionally **different bleeding susceptibility per body part or species**, **ml/min is the better method.**

**Why:**

1. **One wound severity, one rate**  
   “Moderate cut” = e.g. 35 ml/min for any species. You define the rate table once (cut/crush by severity, arterial ×2, body-part/sub-region multipliers on top). No per-species base rates.

2. **Species differ by volume (and optional multipliers)**  
   - Each type has **max_blood_ml** (e.g. human 5000, goblin 2500, ogre 8000).  
   - Death/critical at 35% / 30% of **that** entity’s max: e.g. goblin dies at 875 ml remaining, human at 1750 ml.  
   - The **same wound** (same ml/min) then automatically **drains small creatures faster**: 40 ml/min removes 1.6% of goblin blood per minute vs 0.8% of human. No extra “goblin bleeds faster” tuning—it falls out of the math.

3. **Varying bleeding rates per body part (or per species)**  
   You can still add:
   - **Species bleeding multiplier** (e.g. 0.8× “thick skin,” 1.2× “fragile vessels”) applied to the base ml/min.  
   - **Per–body part (or per species × body part)** overrides on top of the existing body-part/sub-region multipliers.  
   Same idea as now; the base is just in ml/min instead of abstract units.

4. **Easier to add and tune new types**  
   You only set **max_blood_ml** (and optional species mult). Real units make it easy to reason (“goblin ~2.5 L” → 2500) and to compare to any future ml/min sources.

**With the current % system** you can still support varying blood volumes by giving each type a different **max_blood_volume** (e.g. 100 human, 50 goblin) and applying the same loss (in “points” per second) so smaller max = faster time to 35% remaining. So % can work, but you lose (1) a single, intuitive scale for “this wound = X ml/min” and (2) automatic “same wound, smaller creature dies sooner” without thinking in points.

**Recommendation:** For **multiple enemy types with varying blood volumes** (and optional per-species or per–body part bleeding variation), **prefer ml/min**: one base rate table, per-type `max_blood_ml`, optional species (and body-part) multipliers; same wound severity is consistent across types and scaling is straightforward.

---

## 9e. Per-creature blood loss thresholds (percentage system)

**Does the % system allow different creatures to have different thresholds for how blood loss affects them (death / critical)?**

**Yes, after a small extension.** By default, every entity uses the global `BLOOD_LOSS_DEATH_THRESHOLD` (35) and `BLOOD_LOSS_CRITICAL_THRESHOLD` (30). To support variation:

- **SpeciesResource** can define optional overrides: `blood_loss_death_threshold` and `blood_loss_critical_threshold` (0–100 remaining %). If set to a value ≥ 0, that species uses it instead of the global constant; if left at −1 (default), the global value is used.
- **CoreEntity** uses `_get_blood_loss_death_threshold()` and `_get_blood_loss_critical_threshold()` so `is_dead()`, `process_blood_loss()`, and `is_blood_critical()` all respect the entity’s (species) thresholds.

Examples: a species that dies sooner from blood loss might use death threshold 40; a more resilient one might use 28. Critical threshold can similarly vary (e.g. 25 vs 35) for when the UI or mechanics treat the entity as “critical” from bleeding.

---

## 10. Randomization: Simulating Hit Location Within a Body Part

**Do you need it?** Not for medical accuracy—your model is already plausible. Randomization helps **simulate variation**: same damage to "right_arm" can hit superficial skin, muscle, or near the brachial artery; in reality that varies by exact strike location, which the game doesn't model.

**What you already have:** Arterial is already randomized (`randf() < get_arterial_chance(...)`), so "did this hit nick a vessel?" varies per wound. That's the biggest source of real-world variation.

**Optional additions (by impact):**

1. **Bleeding rate variance (recommended if any)**  
   At wound creation: `base_rate *= randf_range(0.85, 1.15)` (or store a multiplier on the injury). Same severity/part sometimes bleeds a bit more or less—simulates hit landing in a more/less vascular spot. Keeps math simple; one constant to tune (e.g. 0.9–1.1 for subtler variation).

2. **Clotting rate variance**  
   At wound creation: store `clotting_mult: float = randf_range(0.9, 1.1)` on the injury; in `process_bleeding` multiply the severity clotting rate by it. Simulates individual/tissue variation in hemostasis. Small effect; only add if you want extra variation.

3. **Sub-regions per part**  
   Split e.g. "right_arm" into "right_arm_upper", "right_arm_forearm" with different BODY_PART_BLEEDING_MULTIPLIERS and/or arterial weights. Most realistic but requires hit location or random sub-part choice and more data; only if you want distinct "where on the limb" fidelity.

4. **Severity wobble near thresholds**  
   When damage is close to a severity boundary (e.g. 24–26% of part max for moderate/severe), randomly nudge severity up or down with a small probability. Simulates "same force, different spot = different depth." Can feel unfair if not tuned carefully; optional.

**Recommendation:** Your system is already accurate enough. If you want more "same hit, different outcome" feel without changing structure, add **(1) bleeding rate variance** (e.g. ±10–15%) at wound creation. Keep arterial as the main random factor; add (2) only if you want extra subtle variation. Skip (3)–(4) unless you're explicitly going for sub-region or threshold simulation.
