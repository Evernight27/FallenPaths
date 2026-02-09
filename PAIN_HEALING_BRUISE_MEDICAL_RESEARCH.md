# Pain, Healing, and Bruises/Wounds: Medical Research and System Recommendations

Summary of medical literature on how pain relates to wound healing and bruises, and how to replicate this in the fallen-paths wound/pain/healing system in a medically accurate way.

---

## 1. Medical Research Summary

### 1.1 Pain and wound healing (time course)

- **Healing phases:** Wound healing has four overlapping phases: hemostasis (minutes), **inflammatory (1–5 days)**, proliferative (~3–21 days), and maturation/remodeling.
- **When pain is highest:** Pain is typically **highest during the acute inflammatory phase** (first few days). Inflammatory mediators and cellular activity at the site drive acute wound pain.
- **As healing progresses:** As the wound moves into **proliferation and maturation**, acute pain **generally decreases**. Pain resolution follows the same general timeline as tissue repair: more remaining damage and inflammation → more pain; less remaining damage → less pain.
- **Protective role:** Acute nociceptive signals (pain-sensing neurons) support healing (e.g. CGRP, neuro-immune axis). Chronic pain and stress, by contrast, can impair healing (mobility restriction, stress response).

**Takeaway for games:** Pain should **decrease as the wound heals** (as remaining tissue deficit decreases and time since injury increases). A fixed “pain per wound forever” is less accurate than pain that scales with **remaining damage** and/or **time since injury**.

*Sources: StatPearls NBK470443 (Wound Healing Phases); Healogics wound stages; Acute Wound Pain (ASWC); Nature CGRP/nociceptors and healing.*

---

### 1.2 Pain and injury severity

- **Correlation:** Tissue damage severity and pain are **positively correlated** in trauma (e.g. Injury Severity Score predicts enhanced pain; OR ~1.80). More severe injuries tend to cause more pain.
- **Not 1:1:** Pain severity is also influenced by pre-existing pain, age, gender, and psychological factors. So “damage × severity → pain” is a reasonable **simplified** model; your current severity multipliers (minor 0.5, moderate 1.0, severe 1.5, critical 2.0) are in line with “worse wound → more pain.”

**Takeaway:** Keeping pain proportional to **damage × severity** is medically plausible. Adding **reduction** of that contribution as the wound heals (or ages) improves accuracy.

*Sources: Acute Traumatic Pain in the ED (MDPI); Pre-Trauma Pain Predictors (Medicina); Pain across traumatic injury groups (J Trauma).*

---

### 1.3 Bruises (contusions) specifically

- **Definition:** Closed injury (skin intact); blunt force → broken vessels, blood in tissue; pain, swelling, tenderness, color change.
- **Onset:** Symptoms (pain, swelling) begin **immediately** after injury.
- **Duration:** Most bruises last **about 2 weeks**; can range from **days to months** depending on severity and depth (subcutaneous/intramuscular vs bone bruise). Bone bruises are most severe and longest.
- **Pain course:** Pain and tenderness are highest early, then **decrease as the bruise resolves** (reabsorption, color progression). No open wound, so no bleeding after initial hematoma; pain is the main ongoing effect.
- **Vs lacerations:** Contusions are generally **milder** than lacerations (open wounds); lacerations cause immediate pain plus bleeding and often need closure. So in a game: bruises = **pain without (or with minimal) bleeding**; pain duration **shorter or similar** to minor tissue healing (~days to ~2 weeks).

**Takeaway:** Bruises should (1) cause **pain** with **no or minimal bleeding**, (2) have pain that **decreases over time** and ideally **resolve** within a **~2 week** window (or scale by “bruise severity”).

*Sources: MedlinePlus Bruise; Cleveland Clinic Bruises; UMass Memorial Contusions; Healthline Contusion.*

---

### 1.4 Chronic vs acute pain in trauma

- **Acute:** Linked to ongoing tissue damage and inflammation; decreases as healing progresses.
- **Persistent:** Some trauma patients have pain at 1 year, especially with pre-existing pain, high injury severity, and certain body regions (spine, joints). Your system is focused on **acute** combat wounds; modeling persistent/chronic pain is optional.

**Takeaway:** For **acute** wound and bruise pain, tying pain to **remaining damage** and **time since injury** (decay) is the medically accurate approach. Chronic pain can be left for later or ignored for simplicity.

*Sources: JAMA Surgery prevalence of pain 1 year after trauma; Pain Medicine predictors of pain severity.*

---

## 2. Mapping Research to Your System

### 2.1 What you have now

- **Wounds:** Created per hit (cut/crush); stored with damage, severity, bleeding rate. Bleeding wounds are removed when rate → 0 (clotted). Pain-only (0-rate) wounds are never removed.
- **Pain:** `get_total_pain()` = sum over all wounds of `damage × SEVERITY_PAIN_MULTIPLIERS[severity]`. No time decay; no link to remaining tissue health.
- **Healing:** `process_healing(seconds)` restores `body_cutting` / `body_blunt` / `bone_health` / `blood_volume` with exponential decay. Worst wound severity on the part sets tissue heal duration. **Wound list is not pruned** when tissue reaches full.

### 2.2 Gaps vs medical accuracy

| Aspect | Current | Medically accurate direction |
|--------|---------|-----------------------------|
| **Pain vs healing** | Pain is constant until wound is removed; wounds are only removed when bleeding stops. | Pain should **decrease as tissue heals** and/or as **time since injury** increases (inflammatory → proliferative). |
| **Bruises** | Not distinguished; all blunt → crush with positive bleed. | Bruises = **pain, no/minimal bleed**; pain **resolves in ~2 weeks** (or decay). |
| **Pain-only wounds** | Never removed → permanent pain. | Should **resolve** when part is healed and/or after a **time decay** (especially for bruises). |

---

## 3. Medically Accurate Implementation Options

### 3.1 Option A: Pain scaled by remaining tissue deficit (healing-linked)

**Idea:** A wound’s contribution to pain is proportional to **how much of that part is still damaged** (unhealed). When the part is fully healed, that wound contributes 0 (or is removed).

**Formula (per wound on part):**  
`pain_contribution = damage × severity_pain_mult × (1 - healed_fraction)`  
where `healed_fraction = (current_cut + current_blunt) / (2 * body_max)` for that part (or use average of cut and blunt pools). So as tissue restores toward `body_max`, pain from wounds on that part goes down.

**Implementation:**

- In `get_total_pain()`, for each wound you need the **part** and the part’s current `body_cutting`, `body_blunt`, `body_max`. Then:
  - `deficit_cut = 1.0 - (body_cutting[part] / body_max[part])`
  - `deficit_blunt = 1.0 - (body_blunt[part] / body_max[part])`
  - Use e.g. `healed_fraction = 1.0 - (deficit_cut + deficit_blunt) / 2.0` so “fully healed” = 1.
  - `contribution = damage * severity_mult * (1.0 - healed_fraction)` (or `* max(0, 1 - deficit)` so pain goes to 0 when healed).

**Pros:** Directly reflects “pain decreases as wound heals”; no new state (no wound age). **Cons:** One wound on a part with many hits uses the **same** healed_fraction for the whole part (all wounds on that part see the same deficit). That’s acceptable as a simplification.

**Variant:** When `healed_fraction >= 1.0` (part full), **remove** all wounds on that part with `base_bleeding_rate == 0` (cleanup), and optionally treat bleeding wounds that have already clotted as “resolved” and remove them too. Then you don’t need to weight by deficit for those—they’re gone.

---

### 3.2 Option B: Pain decay over time (inflammation → resolution)

**Idea:** Each wound’s pain contribution **decays with time since creation** (mirrors inflammatory phase ~1–5 days, then resolution). No need to track “healing phase” explicitly; a single time-decay is enough.

**Formula (per wound):**  
`pain_contribution = damage × severity_pain_mult × time_decay(age_seconds)`  
e.g. `time_decay(age) = exp(-age / tau)` with **tau** chosen so that after ~3–5 days pain is roughly halved, and after ~2 weeks (bruises) or severity-based duration (deeper wounds) pain is negligible.

**Implementation:**

- When creating a wound, set `injury["created_time"] = Time.get_ticks_msec() / 1000.0` (or pass in a game-world time if you advance time in steps).
- In `get_total_pain()`, `age = now - injury["created_time"]`, then e.g.:
  - `tau = PAIN_DECAY_TAU_SECONDS` (e.g. 3–5 days in seconds for “half-life” of acute pain).
  - `decay = exp(-age / tau)`.
  - `contribution = damage * severity_pain_mult * decay`.
- Optional: **different tau for bruises** (0-rate wounds): shorter tau (e.g. 2 weeks) so bruise pain fades faster than deep wound pain.

**Pros:** Matches “acute pain highest early, then decreases”; works for bruises (~2 weeks). **Cons:** Need to store and advance time; wounds never removed unless you add cleanup (e.g. remove when decay &lt; 0.01).

---

### 3.3 Option C: Hybrid (deficit × time decay)

**Idea:** Combine both: pain = `damage × severity_mult × (1 - healed_fraction) × time_decay(age)`. So pain drops both because the part is healing and because time has passed (inflammatory phase ending).

**Pros:** Most aligned with literature (healing + time course). **Cons:** More parameters; may over-dampen pain if both factors are strong.

---

### 3.4 Bruises: 0-rate wound + shorter duration or faster decay

**Creation:** As in WOUND_PAIN_BRUISE_AND_HEALING_OPTIONS.md: either (A) set minor crush bleeding rate to 0, or (B) add `INJURY_TYPE_BRUISE` with rate 0 and create it for small/deflected blunt.

**Resolution (medically accurate):**

- **Option 1 (cleanup):** When the **part** is fully healed (tissue full), remove all wounds with `base_bleeding_rate == 0` on that part. Bruises then contribute 0 once the area is “healed” (and you can justify: no open wound, so “healing” = tissue recovery + time).
- **Option 2 (time):** Give bruises (0-rate wounds) a **shorter pain half-life** (e.g. 7–14 days). In Option B (time decay), use `injury_type == "bruise"` or `base_bleeding_rate == 0` to select a smaller `tau` so their pain fades in ~2 weeks.
- **Option 3 (both):** Remove 0-rate wounds when part is full **and** apply time decay so their contribution is small after ~2 weeks even if not yet removed.

---

## 4. Recommended Implementation (medically accurate)

**Tier 1 (minimal, high impact):**

1. **Pain from remaining deficit (Option A)**  
   In `get_total_pain()`, weight each wound’s contribution by the part’s **unhealed fraction** (e.g. `1 - healed_fraction` where healed_fraction uses average of cut/blunt pools vs body_max). So pain goes to 0 as the part heals.

2. **Cleanup when part is fully healed**  
   In `process_healing()`, after updating tissue for a part, if `body_cutting[part] >= body_max[part]` and `body_blunt[part] >= body_max[part]`, **remove** all wounds on that part with `base_bleeding_rate == 0`. This prevents permanent bruise pain and keeps the list bounded.

3. **Bruises**  
   Use 0-rate crush (minor) or `INJURY_TYPE_BRUISE` with rate 0 so blunt can create pain-only wounds. They will then (a) contribute less and less as tissue heals (deficit weighting) and (b) disappear when the part is full (cleanup).

**Tier 2 (more nuance):**

4. **Time decay (Option B)**  
   Store `created_time` on each wound; in `get_total_pain()` multiply each contribution by `exp(-age / tau)`. Use one tau (e.g. 5 days) for all wounds, or a **shorter tau for 0-rate wounds** (e.g. 10 days) so bruise pain resolves in ~2 weeks even if the part isn’t yet full.

5. **Optional:** Remove wounds whose pain contribution would be below a threshold (e.g. `decay < 0.01`) to avoid an unbounded list of “ghost” wounds.

---

## 5. Constants to Add or Tweak

| Constant | Suggested value | Purpose |
|----------|-----------------|---------|
| **Pain deficit weighting** | Use `(body_cutting[part] + body_blunt[part]) / (2 * body_max[part])` as healed fraction; contribution `*= max(0, healed_fraction)` or `*= (1 - deficit)`. | Pain decreases as tissue heals. |
| **PAIN_DECAY_TAU_SECONDS** (optional) | e.g. `4.0 * SECONDS_PER_DAY` (4 days) for half-life of acute pain. | Time decay of wound pain. |
| **PAIN_DECAY_TAU_BRUISE_SECONDS** (optional) | e.g. `10.0 * SECONDS_PER_DAY` (~1.5 weeks) for 0-rate wounds. | Bruise pain resolves ~2 weeks. |
| **Cleanup rule** | When part tissue full, remove injuries with `base_bleeding_rate == 0`. | Medically: “healed area → no ongoing bruise pain.” |

---

## 6. Summary

- **Medical facts:** Pain is highest in the inflammatory phase (1–5 days) and **decreases as the wound heals** and with **time**. Bruises cause **pain without significant bleeding** and typically **resolve in ~2 weeks**. Injury severity correlates with pain level.
- **Your system:** Already has damage × severity → pain and exponential tissue healing. It does **not** yet link pain to healing or time, and does not remove pain-only wounds when the part is healed.
- **Medically accurate replication:** (1) **Weight wound pain by remaining tissue deficit** so pain drops as the part heals. (2) **Remove pain-only wounds when the part is fully healed.** (3) **Add bruises** (0-rate wounds) for blunt. (4) Optionally add **time decay** (and shorter decay for bruises) so pain also decreases with time since injury. This aligns pain with healing and bruise resolution without overcomplicating the model.
