# Sub-Region Model – Medical Sources and Mapping

Summary of clinical/anatomical sources used to define body-part sub-regions and their bleeding, arterial chance, severity, and bone damage parameters. See BleedingConstants.gd (SUB_REGIONS, SUB_REGION_*), BodyPartConstants.gd (_SUB_REGION_BONE_*), and CoreEntity take_damage_split / _add_wound.

---

## 1. Head: Scalp, Face, Neck

**Sub-regions:** scalp, face, neck

**Sources and rationale:**

- **Scalp:** StatPearls Scalp Laceration (NBK541038), Anatomy Head and Neck Scalp (NBK551565). Scalp has five layers, rich vascular supply (superficial temporal, occipital, etc.), stretched over bone with limited underlying tissue → "bleed profusely to the point of hypotension"; superficial temporal artery most commonly injured in blunt head/neck trauma (~80% in one systematic review). **Game:** highest bleeding multiplier (1.8), elevated arterial (1.2), severity modifier 1.25 (thin tissue = depth reached sooner), bone threshold low (2) and fraction 0.50 (skull 4–23 J).
- **Face:** Facial bones and branches of external carotid; moderate vascularity. **Game:** bleeding 1.4, arterial 1.1, severity 1.1, bone fraction 0.60.
- **Neck:** Penetrating neck trauma – vascular injury in ~25% (carotid, jugular, vertebral); Zone I–III classification (StatPearls, PMC5849205, TSACO). **Game:** bleeding 1.6, arterial 1.5 (highest arterial chance multiplier), severity 1.15, bone threshold 6 and fraction 0.35 (less bony structure).

---

## 2. Chest: Thoracic, Abdominal

**Sub-regions:** thoracic, abdominal

**Sources and rationale:**

- **Thoracic:** Ribs, sternum; diagnosis and management of thoracic vascular injuries (Sage/EAST). **Game:** bleeding 1.15, arterial 1.15, bone threshold 6, fraction 0.35.
- **Abdominal:** Abdominal vascular injury zones (Zone 1–4: midline retroperitoneum, lateral perirenal, pelvic, porta hepatis); major vessels (aorta, IVC, SMA, iliac); eMedicine/ThoracKey/ClinicalPub. **Game:** bleeding 1.25, arterial 1.2, severity 1.1 (softer tissue), bone threshold 10 and fraction 0.22 (less bone than thoracic).

---

## 3. Arm: Upper Arm, Elbow, Forearm, Hand

**Sub-regions:** upper_arm, elbow, forearm, hand

**Sources and rationale:**

- **Upper arm:** Brachial artery; deep brachial in radial groove susceptible in mid-shaft humerus fractures (StatPearls Forearm Arteries NBK545155; AOF vascularization distal humerus). **Game:** bleeding 0.9, arterial 0.95, bone threshold 4, fraction 0.40.
- **Elbow:** Collateral networks (radial/ulnar recurrent, interosseous); supracondylar fractures can compromise perfusion. **Game:** bleeding 1.0, arterial 1.0, severity 1.15 (less tissue over bone), bone threshold 3, fraction 0.45.
- **Forearm:** Forearm vessels are the most frequently injured arterial level in the upper extremity (StatPearls Vascular Extremity Trauma NBK536925; upper extremity vascular injury epidemiology). **Game:** bleeding 1.15, arterial 1.2, bone threshold 5, fraction 0.35 (radius/ulna).
- **Hand:** Radial and ulnar arteries → superficial/deep volar arches; digital arteries; extensive collateral circulation (StatPearls Hand Arteries NBK546583). **Game:** bleeding 1.05, arterial 0.9, bone threshold 4, fraction 0.30.

---

## 4. Leg: Thigh, Knee, Calf, Foot

**Sub-regions:** thigh, knee, calf, foot

**Sources and rationale:**

- **Thigh:** Superficial femoral artery (SFA) most frequently injured in penetrating lower extremity trauma (EAST/Medscape vascular extremity). **Game:** bleeding 1.1, arterial 1.15, bone threshold 5, fraction 0.45 (femur).
- **Knee:** Popliteal artery commonly injured in blunt lower extremity trauma (knee dislocation, fractures); also significant in penetrating. SFA (thigh) is most common in *penetrating* LE trauma. Game uses one arterial mult per sub-region for both cut and crush, so knee and thigh set equal (1.15) to avoid overstating knee for penetrating. **Game:** bleeding 1.2, arterial 1.15, severity 1.1, bone threshold 4, fraction 0.40.
- **Calf:** Anterior/posterior tibial arteries; open tibia fractures Type C (vascular injury) – high bleeding/infection (Wheeless, StatPearls Tibial Artery NBK532871). **Game:** bleeding 1.05, arterial 1.0, bone threshold 6, fraction 0.42.
- **Foot:** Plantar/digital supply; less major-vessel exposure. **Game:** bleeding 0.95, arterial 0.85, severity 1.1, bone threshold 5, fraction 0.35.

---

## 5. Body-Part Target Weights (Weapon Hit Probability)

**Attacks choose a random body part first**, then the sub-region is chosen relative to that part (see §6).

Which body part is hit is chosen by **weighted random** over targetable parts (BodyPartConstants.BODY_PART_TARGET_WEIGHTS). Based on body surface area and exposure (NCBI NBK224908: head/neck 12%, thorax 16%, abdomen 11%, extremities 61%):

- **Head:** 1.2 (head/neck ~12% surface area; often defended)
- **Chest:** 2.7 (thorax + abdomen ~27%; center mass)
- **Arms:** 1.0 each (~10% of extremities each)
- **Legs:** 2.0 each (~20% each; large, stable target)

CombatManager uses `BodyPartConstants.get_weighted_random_part(targetable)` so weapon hits reflect realistic targeting (chest and legs more likely than head/arms).

---

## 6. Sub-Region Weights (Hit Probability Within a Part)

**After** the body part is chosen (§5), the sub-region is chosen by **weighted random over that part's sub-regions only** (BleedingConstants.SUB_REGION_WEIGHTS[part]). So sub-region chance is relative to the part being hit (e.g. P(scalp) = P(head hit) × P(scalp | head)).

Weights approximate relative surface area / exposure within the part (BleedingConstants.SUB_REGION_WEIGHTS). Below: raw weights and **hit % within that body part** (weight ÷ sum of part’s weights × 100), so you can check against anatomy.

### Sub-region breakdown by body part (weights → hit % within part)

| Body part | Sub-region   | Weight | Hit % (within part) | Rationale (relative size/exposure) |
|-----------|--------------|--------|----------------------|-------------------------------------|
| **Head**  | scalp        | 1.2    | **42.9%**            | Crown/top/sides; larger area than face or neck. |
|           | face         | 1.0    | **35.7%**            | Front; moderate area. |
|           | neck         | 0.6    | **21.4%**            | Smaller exposed band; often guarded. |
|           | *(sum)*      | *2.8*  | *100%*               | |
| **Chest** | thoracic     | 1.0    | **50%**              | Rib cage / sternum. |
|           | abdominal    | 1.0    | **50%**              | Belly; similar frontal exposure. |
|           | *(sum)*      | *2.0*  | *100%*               | |
| **Arm**   | upper_arm    | 1.0    | **31.25%**           | Long segment (humerus). |
|           | elbow        | 0.4    | **12.5%**            | Joint; small area. |
|           | forearm      | 1.0    | **31.25%**           | Long segment (radius/ulna). |
|           | hand         | 0.8    | **25%**              | Smaller than forearm. |
|           | *(sum)*      | *3.2*  | *100%*               | |
| **Leg**   | thigh        | 1.0    | **32.3%**            | Long segment (femur). |
|           | knee         | 0.5    | **16.1%**            | Joint; smaller area. |
|           | calf         | 1.0    | **32.3%**            | Long segment (tibia/fibula). |
|           | foot         | 0.6    | **19.4%**            | Smaller than calf. |
|           | *(sum)*      | *3.1*  | *100%*               | |

**How to read:** When an attack hits “head”, the sub-region is rolled with the above head row (scalp 42.9%, face 35.7%, neck 21.4%). Same for chest (50/50), arm (upper_arm 31.25%, elbow 12.5%, forearm 31.25%, hand 25%), leg (thigh 32.3%, knee 16.1%, calf 32.3%, foot 19.4%). Left/right arm and left/right leg use the same weights as “Arm” and “Leg” above.

---

## 7. Severity Modifiers

Same raw damage maps to different effective “depth” by sub-region (thin tissue / exposed bone = higher effective severity):

- Scalp 1.25, face 1.1, neck 1.15; thoracic 1.0, abdominal 1.1
- Elbow/knee 1.1–1.15; hand/foot 1.1; limb shafts 0.95–1.0

Effective damage for severity = raw_damage × severity_modifier (thin tissue = depth reached sooner).

---

## 8. Bone Damage by Sub-Region

- **Threshold:** Damage above this (per hit) can allocate to bone; lower = bone involved with less total impact (e.g. scalp 2, elbow 3, abdominal 10).
- **Fraction:** Share of damage above threshold that goes to bone (e.g. face 0.60, neck 0.35, abdominal 0.22).

Research: skull 4–23 J (PubMed 20803457); femoral ~35 J, tibial ~25 J (SciDirect long bone); distal radius/ulna most common UE fractures; humerus proximal > shaft > distal (Swedish Fracture Register); open tibia Type C vascular (Wheeless). See RESEARCH_BASED_APPROXIMATIONS.md, BodyPartConstants.gd.

---

## 9. Per-Sub-Region Summary (All Inputs)

Each sub-region has **individual units** for:

| Input | Constant / Helper | Notes |
|-------|-------------------|--------|
| **Target weight (within part)** | SUB_REGION_WEIGHTS | Relative chance to be hit when that part is struck |
| **Bleeding** | SUB_REGION_BLEEDING_MULTIPLIERS | Part base × sub-region mult in get_bleeding_rate() |
| **Arterial chance** | SUB_REGION_ARTERIAL_MULTIPLIERS | Part base × sub-region mult in get_arterial_chance() |
| **Blunt arterial (cut vs crush)** | SUB_REGION_BLUNT_ARTERIAL_MODIFIERS | When crush: base crush mult (0.35) × this per sub-region; &lt;1 = blunt less often arterial, &gt;1 = blunt relatively more (e.g. knee 1.25). |
| **Severity (effective depth)** | SUB_REGION_SEVERITY_MODIFIERS | effective_damage = damage × mult for severity tier |
| **Bone threshold** | BodyPartConstants._SUB_REGION_BONE_THRESHOLD | Damage above this can allocate to bone |
| **Bone fraction** | BodyPartConstants._SUB_REGION_BONE_FRACTION | Fraction of damage (above threshold) to bone |

**Targeting order:** (1) Random body part (BodyPartConstants.get_weighted_random_part). (2) Random sub-region given that part (BleedingConstants.get_random_sub_region(part), using SUB_REGION_WEIGHTS[part]). So each sub-region's chance is relative to its body part being hit.

---

## 9a. Arterial chance: cut vs blunt by sub-region (research-based)

**Logic:** Cut (penetrating) has base arterial chance; crush (blunt) uses `ARTERIAL_CRUSH_MULTIPLIER` (0.35) × **SUB_REGION_BLUNT_ARTERIAL_MODIFIERS[part][sub_region]** so differentiation is region-specific. 1.0 = same as default blunt; &lt;1 = blunt less often arterial than cut; &gt;1 = blunt relatively more (e.g. knee/popliteal).

**Research summary:**
- **Neck:** Penetrating ~85% of head/neck neurovascular cases; blunt carotid/vertebral rarer → **0.5**.
- **Thoracic/abdominal:** Penetrating predominates; blunt thoracic vascular &lt;5% of vascular trauma → thoracic **0.5**, abdominal **0.6**.
- **Scalp/face:** STA most frequently injured in *blunt* cephalovascular trauma (~80%) → scalp **0.9**, face **0.75**.
- **Lower limb:** Popliteal most common in *blunt* LE trauma; SFA most common in *penetrating* → thigh **0.6**, knee **1.25**, calf/foot **0.9**.
- **Upper limb:** Forearm vessels “most frequently injured regardless of mechanism” → forearm **1.0**; upper_arm/elbow/hand **0.85–0.9**.

| Part  | Sub-region | Blunt arterial modifier | Rationale |
|-------|------------|-------------------------|------------|
| head  | scalp      | 0.9                     | STA commonly injured in blunt cephalovascular. |
| head  | face       | 0.75                    | Blunt vascular face less common than penetrating. |
| head  | neck       | 0.5                     | Penetrating >> blunt for neck vascular. |
| chest | thoracic   | 0.5                     | Penetrating predominates (great vessels). |
| chest | abdominal  | 0.6                     | Penetrating 2× blunt for vessel injury in laparotomy. |
| arm   | upper_arm  | 0.85                    | Penetrating more common. |
| arm   | elbow      | 0.9                     | Mixed. |
| arm   | forearm    | 1.0                     | “Most frequently injured regardless of mechanism.” |
| arm   | hand       | 0.9                     | Slightly penetrating-favoured. |
| leg   | thigh      | 0.6                     | SFA most common in *penetrating* LE trauma. |
| leg   | knee       | 1.25                    | Popliteal most common in *blunt* LE trauma (knee dislocation). |
| leg   | calf       | 0.9                     | Mixed. |
| leg   | foot       | 0.9                     | Mixed. |

---

## 10. Medical Weights per Sub-Region (and Realism)

Below are the **differing medical weights** for each sub-region: bleeding multiplier, arterial chance multiplier, severity modifier, bone threshold, and bone fraction. Baseline for comparison: limb shaft ≈ 1.0 bleeding/arterial, 1.0 severity, with bone threshold/fraction varying by anatomy.

### Head

| Sub-region | Bleeding mult | Arterial mult | Severity mod | Bone threshold | Bone fraction | Realistic? |
|------------|----------------|---------------|--------------|----------------|---------------|------------|
| scalp      | 1.8            | 1.2           | 1.25         | 2              | 0.50          | **Yes.** Scalp very vascular, thin over skull → bleeds heavily (StatPearls); low threshold/fraction for skull (4–23 J). |
| face       | 1.4            | 1.1           | 1.1          | 3              | 0.60          | **Yes.** Facial bones, moderate vessels; bone fraction high (facial fractures). |
| neck       | 1.6            | 1.5           | 1.15         | 6              | 0.35          | **Yes.** ~25% vascular in penetrating neck trauma (carotid/jugular/vertebral); less bone → high threshold, low fraction. |

### Chest

| Sub-region | Bleeding mult | Arterial mult | Severity mod | Bone threshold | Bone fraction | Realistic? |
|------------|----------------|---------------|--------------|----------------|---------------|------------|
| thoracic   | 1.15           | 1.15          | 1.0          | 6              | 0.35          | **Yes.** Ribs/sternum; thoracic vascular injury literature (Sage/EAST). |
| abdominal  | 1.25           | 1.2           | 1.1          | 10             | 0.22          | **Yes.** Major vessels (aorta, IVC, etc.); soft tissue → higher threshold, lower bone fraction. |

### Arm (same for left/right)

| Sub-region  | Bleeding mult | Arterial mult | Severity mod | Bone threshold | Bone fraction | Realistic? |
|-------------|----------------|---------------|--------------|----------------|---------------|------------|
| upper_arm   | 0.9            | 0.95          | 0.95         | 4              | 0.40          | **Yes.** Brachial/deep brachial; humerus shaft. |
| elbow       | 1.0            | 1.0           | 1.15         | 3              | 0.45          | **Yes.** Less tissue over bone (supracondylar); collateral vessels. |
| forearm     | 1.15           | 1.2           | 1.0          | 5              | 0.35          | **Yes.** Forearm = most frequently injured arterial level in UE (StatPearls NBK536925). |
| hand        | 1.05           | 0.9           | 1.1          | 4              | 0.30          | **Yes.** Volar arches, digital arteries; good collateral → slightly lower arterial. |

### Leg (same for left/right)

| Sub-region | Bleeding mult | Arterial mult | Severity mod | Bone threshold | Bone fraction | Realistic? |
|------------|----------------|---------------|--------------|----------------|---------------|------------|
| thigh      | 1.1            | 1.15          | 0.95         | 5              | 0.45          | **Yes.** SFA most injured in penetrating lower limb (EAST/Medscape); femur. |
| knee       | 1.2            | 1.15          | 1.1          | 4              | 0.40          | **Yes.** Popliteal (blunt) and SFA/thigh (penetrating) both high-risk; knee = thigh (1.15) so we don’t overstate knee for cuts. |
| calf       | 1.05           | 1.0           | 1.0          | 6              | 0.42          | **Yes.** Tibial arteries; open tibia Type C vascular (Wheeless). |
| foot       | 0.95           | 0.85          | 1.1          | 5              | 0.35          | **Yes.** Plantar/digital; less major-vessel exposure. |

### Summary

- **Bleeding:** Scalp/neck/face highest (vascular density); abdomen/forearm/knee elevated; hand/foot/upper_arm slightly below 1.0. Matches “where vessels are” and clinical descriptions.
- **Arterial:** Neck highest (carotid/jugular zone); thigh/knee/forearm/abdominal elevated (SFA, popliteal, forearm vessels); hand/foot lower (collateral, smaller named arteries). Thigh and knee equal (1.15): one mult per sub-region for both cut and crush, so knee isn’t overstated for penetrating.
- **Severity:** Scalp/elbow/knee/hand/foot/neck/abdominal > 1.0 (thin tissue or small cross-section → same force = deeper effective wound); thigh/upper_arm/forearm ≤ 1.0 (more bulk). Realistic.
- **Bone:** Low threshold + moderate fraction where bone is close (scalp, elbow, face); high threshold + low fraction where soft (abdomen, neck). Research: skull 4–23 J, femur ~35 J, tibia ~25 J; values are in abstract game units but ordering is consistent.

Overall, the weights are **medically plausible** and aligned with the cited sources; exact numbers are tuned for gameplay rather than calibrated to real units (e.g. ml/min or J).

---

## 10a. Double-check: Bone health and arterial hit chance per sub-region

**How they’re used in code**

- **Bone (BodyPartConstants + CoreEntity):** For the hit `part` and chosen `sub_region`, `get_bone_damage_threshold(part, sub_region)` and `get_bone_damage_fraction(part, sub_region)` are used. If `sub_region` is non-empty and present in the dict, the sub-region value is used; otherwise the part-level value, then default (5, 0.35). In `take_damage_split`: when total damage ≥ threshold, `excess = total - threshold`, `to_bone = max(BONE_DAMAGE_MIN, round(excess * fraction))`, rest to tissue.
- **Arterial (BleedingConstants):** `get_arterial_chance(...)` = base by severity × (if crush: `ARTERIAL_CRUSH_MULTIPLIER` × `SUB_REGION_BLUNT_ARTERIAL_MODIFIERS[part][sub_region]`) × part mult × sub-region arterial mult, clamped to [0, 1]. One roll per wound at creation.

**Single reference table (bone + arterial only)**

Every sub-region in SUB_REGIONS has an entry in both bone dicts and in SUB_REGION_ARTERIAL_MULTIPLIERS; lookups are consistent.

| Part      | Sub-region  | Bone threshold | Bone fraction | Arterial mult |
|-----------|-------------|----------------|----------------|----------------|
| head      | scalp       | 2              | 0.50           | 1.2            |
| head      | face        | 3              | 0.60           | 1.1            |
| head      | neck        | 6              | 0.35           | 1.5            |
| chest     | thoracic    | 6              | 0.35           | 1.15           |
| chest     | abdominal   | 10             | 0.22           | 1.2            |
| arm       | upper_arm   | 4              | 0.40           | 0.95           |
| arm       | elbow       | 3              | 0.45           | 1.0            |
| arm       | forearm     | 5              | 0.35           | 1.2            |
| arm       | hand        | 4              | 0.30           | 0.9            |
| leg       | thigh       | 5              | 0.45           | 1.15           |
| leg       | knee        | 4              | 0.40           | 1.15           |
| leg       | calf        | 6              | 0.42           | 1.0            |
| leg       | foot        | 5              | 0.35           | 0.85           |

**Reality check**

- **Bone threshold:** Lower where bone is close (scalp 2, elbow 3, face 3); higher where soft (neck 6, abdominal 10). Matches “damage above this can involve bone.”
- **Bone fraction:** Higher where impact goes to bone (face 0.60, elbow 0.45, thigh 0.45); lower where soft (neck 0.35, abdominal 0.22, hand 0.30). Matches research (skull vs femur vs tibia).
- **Arterial mult:** Highest neck (1.5); then thigh/knee/forearm/abdominal (1.15–1.2), scalp/face/thoracic (1.1–1.2); lower hand (0.9), foot (0.85). Thigh and knee equal (1.15): SFA most common in penetrating LE trauma, popliteal in blunt; one mult per sub-region so we don’t overstate knee for cuts.

**Verified:** BodyPartConstants and BleedingConstants match the table; CoreEntity uses `part` + `sub_region` for both bone and wound creation (arterial roll uses same `sub_region`).

---

## 11. Sources (Short)

- StatPearls: Scalp Laceration (NBK541038), Anatomy Head and Neck Scalp (NBK551565), Vascular Extremity Trauma (NBK536925), Forearm Arteries (NBK545155), Hand Arteries (NBK546583), Tibial Artery (NBK532871).
- Penetrating neck trauma, Zone I–III, vascular ~25%: PMC5849205, TSACO, eMedicine.
- Thoracic/abdominal vascular injury: Sage/EAST, eMedicine 1984639, ThoracKey, ClinicalPub.
- Upper/lower extremity vascular injury: Medscape 1287360, PMC11155511, EAST penetrating lower extremity.
- Scalp/face blunt vascular: PubMed 40062961, Journal of Craniofacial Surgery.
- Fracture epidemiology: Swedish Fracture Register (humerus), J Orthop Trauma (upper extremity), Wheeless (open tibia Type C).
- AOF: Vascularization of the distal humerus.

Literature does not provide exact “bleeding multiplier per sub-region”; the game uses **relative** scaling from anatomy (vascular density, commonly injured vessels) and epidemiology (forearm most injured in UE, popliteal blunt, SFA penetrating, neck ~25% vascular) for a medically plausible sub-region model.
