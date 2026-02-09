# Body Part Health, Bone, and Severance

Body part health is split into **tissue** (cutting/blunt) and **bone**. Damage can fracture or break bone; when tissue and bone are both depleted, the part is **severed** (sharp) or **crushed** (blunt). Functionality (e.g. arm use) drops when bone is fractured and is zero when the part is destroyed.

---

## 1. Per-part stats

| Stat | Meaning |
|------|--------|
| **body_cutting** | Remaining tissue capacity vs cutting damage. When 0, soft tissue is "cut through" for that type. |
| **body_blunt** | Remaining tissue capacity vs blunt damage. When 0, soft tissue is "crushed" for that type. |
| **body_max** | Max tissue per type (cutting and blunt each have this max). From species `get_body_part_max(part)`. |
| **bone_health** | Remaining bone capacity. When 0, bone is fractured/broken. |
| **bone_max** | Max bone for that part. From species `get_bone_max(part)`. |

Tissue max can be thought of as "how much force/energy it takes to cut or crush through the soft tissue of that part"; bone max as "how much it takes to fracture or break the bone." Values are in the same abstract scale as damage (game HP).

---

## 2. Damage application (take_damage)

1. **Armor** reduces incoming damage (unchanged).
2. **Split tissue vs bone (per body part / sub-region)** — BodyPartConstants:
   - For the **hit part** (and sub-region when using take_damage_split), use **get_bone_damage_threshold(part, sub_region)** and **get_bone_damage_fraction(part, sub_region)**.
   - If **final damage ≥ threshold**: a **fraction of (damage above threshold)** goes to **bone**, the rest of total damage to **tissue** (minimum 1 to bone when split). E.g. threshold 3, total 10, fraction 0.5 → excess 7, bone = max(1, round(7×0.5)) = 4, tissue = 6.
   - If damage &lt; threshold: **all** damage goes to tissue (cutting or blunt by type).
   - **Per-part values:** head (3, 0.55); chest (8, 0.30); arms (5, 0.38); legs (6, 0.42). Unknown parts use (5, 0.35).
3. **Apply to tissue**: sharp → subtract from `body_cutting`; blunt → subtract from `body_blunt`.
4. **Apply to bone**: subtract bone portion from `bone_health` (same for sharp and blunt).
5. **Death**: if the part is vital (head/chest) and either tissue type is 0, emit `died`.

So each attack's bone vs tissue split depends on **which body part was hit**, not a global percentage.

---

## 3. Severance and crushing

- **Severance (sharp):** `body_cutting[part] <= 0` **and** `bone_health[part] <= 0`. The part is "sliced through" (tissue and bone both gone).
- **Crushed (blunt):** `body_blunt[part] <= 0` **and** `bone_health[part] <= 0`. The part is destroyed by blunt trauma.
- **Part destroyed** = severed or crushed. That part is no longer targetable and (if arm/leg) has no functionality.

---

## 4. Targeting (which part and sub-region is hit)

Attacks stay **random** on which body part they choose; sub-region is then chosen **relative to that part**.

1. **Body part:** Chosen by **weighted random** over targetable parts (BodyPartConstants.get_weighted_random_part). Weights reflect body surface area and exposure (NCBI NBK224908): head/neck ~12%, thorax+abdomen ~27%, arms ~10% each, legs ~20% each. So chest and legs are more likely than head or arms.
2. **Sub-region:** After the part is chosen, a **sub-region** (e.g. scalp/face/neck for head) is chosen by **weighted random over that part's sub-regions only** (BleedingConstants.get_random_sub_region(part), using SUB_REGION_WEIGHTS[part]). So sub-region probabilities are relative to the chance of the body part being hit.

That sub-region drives bone split (threshold/fraction), wound severity (effective depth), bleeding multiplier, and arterial chance. See SUB_REGIONS_MEDICAL_SOURCES.md.

## 5. Targetable parts

A part is **targetable** if it is **not** destroyed and has at least one of cutting or blunt &gt; 0. So:

- `get_targetable_parts()` excludes any part where `_is_part_destroyed(part)` is true.
- A part with tissue still remaining but bone already 0 is still targetable (e.g. bone broken, flesh still there).

---

## 6. Functionality (arms and legs, bone-based)

- **Broken bone** = `bone_health <= 0` (complete fracture). **Fractured** = bone damaged but &gt; 0 (partial/hairline).
- **get_bone_functionality_factor(part)** returns 0.0–1.0 from bone_health/bone_max (research-based tiers):
  - **Broken (0% bone left):** 0% function.
  - **Severe fracture (1–25% bone left):** ~15% (substantial deterioration; research: “most pronounced immediately”).
  - **Fracture (25–50%):** ~40% (significant impairment; e.g. wrist fracture → ~48% increased odds of functional decline).
  - **Mild (50–75%):** ~70%.
  - **Near full (75–100%):** ~92–100%.

- **Arms:** **get_arm_functionality(part)** = tissue factor × bone factor. So broken bone = 0% arm use; fractured bone severely reduces grip/strength even if tissue remains.
- **Legs:** **get_leg_functionality()** uses bone factor for both legs: if either leg is broken → ~8% mobility (e.g. hopping/crutch); otherwise geometric mean of both legs’ bone factors. Research: &lt;50% of hip-fracture patients regain pre-fracture mobility; lower-limb fracture → major gait speed reduction.
- **get_effective_speed()** = base speed × get_leg_functionality(). Used for combat gauge fill so broken/fractured legs slow turn rate (realistic mobility loss).

---

## 7. Species and constants

- **SpeciesResource:** `get_body_part_max(part)` (tissue) and `get_bone_max(part)` (bone). Export bone values per part (e.g. head_bone, chest_bone, right_arm_bone, …).
- **BodyPartConstants:** Per-part **bone_damage_threshold** and **bone_damage_fraction** via `get_bone_damage_threshold(part)` and `get_bone_damage_fraction(part)`; `get_bone_damage_min(part)` for minimum bone damage when split.

---

## 8. Linking health to "force to cut through"

Tissue and bone max values are in the same abstract scale as damage. To align with "force/energy to cut through":

- Set **body_max** (and species part values) from a notion of "energy/HP to cut through that part’s tissue" (e.g. arms lower than chest, head/chest vital).
- Set **bone_max** from a notion of "energy/HP to fracture that bone" (e.g. skull/ribs higher than limbs).  
You can later drive these from real-world estimates (e.g. J to cut/fracture) by scaling J into your game HP scale.

Severance then corresponds to: enough cutting damage to remove all tissue **and** enough damage (from heavy hits) to reduce bone to 0, so the part is fully cut through.

---

## 9. Sub-regions vs health pools: one pool per part or per sub-region?

You already use **sub_regions** for: hit location (weighted random), bone threshold/fraction, wound severity, bleeding/arterial multipliers, and stump level. The question: do you need **separate health pools per sub_region**, or is **one pool per body part** enough?

### Current design: one pool per part

- **Pools:** `body_cutting[part]`, `body_blunt[part]`, `bone_health[part]` for each **part** (head, chest, right_arm, left_arm, right_leg, left_leg). So 6 parts × 3 pool types = 18 values.
- **Sub_region** is chosen per hit (weighted random) and used only for:
  - **Modifiers:** bone threshold/fraction, severity, bleeding, arterial chance.
  - **Metadata:** each wound stores `sub_region`; stump level uses the sub_region of the severing hit.
- All damage to that part goes into the **same** pool. You never have "forearm at 0 but hand at full" — the whole arm is one pool. Severance is "whole part gone"; stump level (sub_region) only affects **how much** the stump bleeds, not which segment is gone.

**You do not need to change this** if:

- You're happy with "arm severed" as a single state (with level affecting stump bleeding and display).
- You don't need gameplay where "hand destroyed, forearm still usable" is a distinct state.
- You want to keep logic and tuning simple (one pool per part, sub_regions for flavor and modifiers).

### Alternative: per–sub_region health pools

- **Pools:** e.g. `body_cutting["right_arm_upper_arm"]`, `body_cutting["right_arm_forearm"]`, … (or a nested structure). Each sub_region has its own cutting, blunt, and (if you split bone by segment) bone pools. Damage is applied to the **specific** sub_region hit.
- **Pros:** Finer granularity: "hand severed at wrist" vs "arm severed at elbow" as different pool states; "forearm crushed, hand OK"; per-segment functionality possible.
- **Cons:** Many more pools and rules: e.g. 6 parts × ~3–4 sub_regions × 3 = 54+ values; you must define when "part" is severed (all sub_regions 0? or first segment 0 = that segment gone?); targeting, UI, armor, and balance all get more complex.

### Recommendation

- **Keep one health pool per body part** and continue using sub_regions for hit location, modifiers, wound metadata, and stump level. That already gives you level-accurate stump bleeding and region-specific wound behavior without per-sub_region pools.
- **Switch to per–sub_region pools** only if you explicitly want distinct damage states per segment (e.g. "hand gone, forearm intact" as a different outcome from "whole arm gone") and are willing to maintain the extra complexity.
