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
- **Knee:** Popliteal artery most frequently injured in blunt lower extremity trauma; associated with fractures/dislocations. **Game:** bleeding 1.2, arterial 1.25, severity 1.1, bone threshold 4, fraction 0.40.
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

Weights approximate relative surface area / exposure within the part (BleedingConstants.SUB_REGION_WEIGHTS):

- **Head:** scalp 1.2, face 1.0, neck 0.6
- **Chest:** thoracic 1.0, abdominal 1.0
- **Arm:** upper_arm 1.0, elbow 0.4, forearm 1.0, hand 0.8
- **Leg:** thigh 1.0, knee 0.5, calf 1.0, foot 0.6

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
| **Severity (effective depth)** | SUB_REGION_SEVERITY_MODIFIERS | effective_damage = damage × mult for severity tier |
| **Bone threshold** | BodyPartConstants._SUB_REGION_BONE_THRESHOLD | Damage above this can allocate to bone |
| **Bone fraction** | BodyPartConstants._SUB_REGION_BONE_FRACTION | Fraction of damage (above threshold) to bone |

**Targeting order:** (1) Random body part (BodyPartConstants.get_weighted_random_part). (2) Random sub-region given that part (BleedingConstants.get_random_sub_region(part), using SUB_REGION_WEIGHTS[part]). So each sub-region's chance is relative to its body part being hit.

---

## 10. Sources (Short)

- StatPearls: Scalp Laceration (NBK541038), Anatomy Head and Neck Scalp (NBK551565), Vascular Extremity Trauma (NBK536925), Forearm Arteries (NBK545155), Hand Arteries (NBK546583), Tibial Artery (NBK532871).
- Penetrating neck trauma, Zone I–III, vascular ~25%: PMC5849205, TSACO, eMedicine.
- Thoracic/abdominal vascular injury: Sage/EAST, eMedicine 1984639, ThoracKey, ClinicalPub.
- Upper/lower extremity vascular injury: Medscape 1287360, PMC11155511, EAST penetrating lower extremity.
- Scalp/face blunt vascular: PubMed 40062961, Journal of Craniofacial Surgery.
- Fracture epidemiology: Swedish Fracture Register (humerus), J Orthop Trauma (upper extremity), Wheeless (open tibia Type C).
- AOF: Vascularization of the distal humerus.

Literature does not provide exact “bleeding multiplier per sub-region”; the game uses **relative** scaling from anatomy (vascular density, commonly injured vessels) and epidemiology (forearm most injured in UE, popliteal blunt, SFA penetrating, neck ~25% vascular) for a medically plausible sub-region model.
