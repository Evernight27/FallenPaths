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

**Formula:** `arterial_chance = clamp(ARTERIAL_CHANCE_BY_SEVERITY[severity] * (0.35 if crush else 1.0) * ARTERIAL_BODY_PART_MULTIPLIERS[part], 0, 1)`.

**When a wound is arterial:** We roll once at wound creation. If arterial: `current_bleeding_rate` is multiplied by `ARTERIAL_BLEEDING_MULTIPLIER` (2.0), and clotting is multiplied by `ARTERIAL_CLOTTING_MULTIPLIER` (0.15) so arterial wounds seal very slowly (pressure inhibits clotting).

*Sources: StatPearls Vascular Extremity Trauma (NBK536925); penetrating neck vascular ~25% (PMC5849205, TSACO); soft signs 10% / 25% (Frykberg, WTA/EAST); penetrating 75–80% of peripheral vascular injuries.*

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
| **Arterial chance** | **High** | Probabilistic by severity, type, part; soft-sign / neck vascular rates in plausible range. |
| **Body part multipliers** | **High** | Head &gt; chest &gt; limbs for bleeding and arterial; scalp/trunk more vascular. |
| **Sub-regions** | **High** | Per–body-part sub-regions (scalp/face/neck, thoracic/abdominal, upper_arm/elbow/forearm/hand, thigh/knee/calf/foot) with **individual units** for target weight (within part), bleeding, arterial, severity modifier, and bone threshold/fraction; research-based. See **SUB_REGIONS_MEDICAL_SOURCES.md**. |
| **Body-part targeting** | **High** | Weapon hit part chosen by **weighted random** (BodyPartConstants.BODY_PART_TARGET_WEIGHTS) from body surface area/exposure (NCBI NBK224908); chest and legs more likely than head/arms. |
| **Bandaging** | **Plausible** | Immediate reduction + fast clotting when stabilized; arterial less effective. |
| **Absolute bleeding rates** | **Abstract** | No real "ml/min" calibration; rates are relative and tuned for gameplay. |

**Overall:** The **structure and relative behavior** are medically accurate; **absolute numbers** (e.g. BLEEDING_RATES, BLOOD_LOSS_RATE_MULTIPLIER) are tuned for feel, not calibrated to ml/min. **Sub-regions** provide hit-location variation within each body part (bleeding, arterial chance, severity modifier, bone threshold/fraction per sub-region).

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
