# Severance (Limb Dismemberment): Medical Research and System Comparison

How hard it is to cut through each body part in reality, and how the game models damage-to-severance relative to limb health, wounds, and severity.

---

## 1. Medical Research Summary

### 1.1 Force and tissue type

- **Bone vs soft tissue:** Cutting through bone requires **more force** than soft tissue alone. Blade geometry, angle, and speed affect penetration (PubMed 32162009, biaxial knife/skin studies; PubMed 35278317 knives/multitools on cadaveric limb amputation).
- **No single “Newtons per body part”** appears in the cited literature; studies focus on blade type, skin simulants, and amputation *methods* (reciprocating saw, Gigli, hacksaw, hydraulic) rather than exact force to sever a given limb in one blow.

### 1.2 Traumatic amputation and severity factors

- **Mechanisms:** Traumatic amputation can result from sharp force, blunt/crush, machinery, and combat. Severity depends on mechanism and **extent of pre-existing damage** (MedlinePlus traumatic amputation; limb salvage guidelines).
- **Limb salvage vs amputation:** Scoring systems (e.g. **Mangled Extremity Severity Score, MESS**) use **skeletal/soft-tissue injury severity**, ischemia, shock, and age. **Higher severity and pre-existing severe damage** correlate with amputation (PMC2740356, PMC9702595). So in practice: **already severely injured limbs are more likely to be amputated**—i.e. structurally compromised limbs “give way” more easily to further trauma.
- **Blunt/crush:** Blunt arterial trauma and crush are explicitly listed as factors that worsen outcome and favour amputation (limb salvage reviews). So both **wound burden** and **bone/soft-tissue compromise** matter.

### 1.3 Relative difficulty by body part

- **Arms vs legs:** Upper extremity major amputations are much less common than lower (e.g. ~8% of amputations; arms ~20× less than legs in some series). That reflects **exposure and mechanism** (e.g. industrial/vehicle) more than “arm easier to cut than leg.” Anatomically, **legs have more mass, thicker bone (femur, tibia), and larger soft-tissue envelope** than arms, so in a simplified model **more total damage is needed to sever a leg** than an arm.
- **Neck/wrist vs mid-limb:** Clinically, amputation *level* (e.g. wrist vs mid-forearm) affects function and surgical difficulty; **narrow cross-sections** (wrist, ankle) have less tissue and bone to cut through than mid-thigh or mid-arm. The game does not model “level” within a part; **body_max and bone_max per part** already encode relative size (e.g. arm 12, leg 28 in SpeciesResource), so **legs require more raw damage** than arms to reduce pools to zero.

**Takeaway:** (1) Intact limb = harder to sever; (2) Pre-existing wounds and bone/soft-tissue damage = easier to dismember; (3) Larger parts (legs) need more total damage than smaller (arms) in a proportional sense. The game’s **severance ease factor** and **per-part body_max/bone_max** align with (1)–(3).

---

## 2. Current Game System

### 2.1 When is a part severed?

- **Deterministic:** `body_cutting[part] <= 0` **and** `bone_health[part] <= 0` (cut through).
- **Crushed:** `body_blunt[part] <= 0` and `bone_health[part] <= 0`.
- **Early severance (probabilistic):** When the part is **critically damaged** but not yet at 0—combined remaining (cut + bone) below **18%** of (body_max + bone_max)—and this hit did at least 1 damage, the game **rolls** for immediate severance. Probability = `(threshold - remaining_ratio) / threshold * 0.65`, so the lower the health, the higher the chance (max 65%). This reflects reality: **complete traumatic amputation** can occur from a single blow that cuts through critical structure; you don’t literally need “every HP to 0.” Early sever applies only to **limbs** (arms/legs) by default; head/chest still require exact 0 (death logic unchanged).
- So the amount of damage required is **relative to** body_max/bone_max, current health, severance ease, and (when health is very low) a **chance** that one more blow finishes the part.

### 2.2 Severance ease factor (new)

- **Idea:** The same hit does **more effective damage** when the part is already damaged and wounded, so it’s **harder to chop through a full-health limb** and **easier to dismember a mangled one**.
- **Formula:** `ease = 1.0 + (1 - tissue_ratio)*0.4 + (1 - bone_ratio)*0.3 + wound_factor + severity_bonus`, clamped to **[1.0, 1.8]**.
  - **tissue_ratio** = (body_cutting + body_blunt) / (2 * body_max).
  - **bone_ratio** = bone_health / bone_max.
  - **wound_factor** = min(wound_count × 0.04, 0.25).
  - **severity_bonus** = worst wound on part: minor 0, moderate 0.05, severe 0.12, critical 0.20.
- **Application:** After computing `to_cut`, `to_blunt`, `to_bone` from the hit, multiply each by `ease` (rounded), then cap each by the current pool so we never subtract more than exists. So:
  - **Full health, no wounds:** ease = 1.0 → normal damage.
  - **Low tissue, low bone, many severe wounds:** ease up to 1.8 → up to 80% more effective damage from the same blow → much easier to finish the part off.

### 2.3 Per-part “difficulty” (how much damage to sever)

- **Already in the game:** `body_max` and `bone_max` differ by part (e.g. head 12/8, chest 28/20, arm 12/8, leg 28/20 in SpeciesResource). So:
  - **Arms** have less total “health” than **legs** → less raw damage needed to reduce pools to zero.
  - **Head** has less than **chest** or **leg**.
- This matches the idea that **larger/more massive parts** (legs, chest) require more damage to sever than smaller ones (arms, head), consistent with anatomy and the relative rarity of arm vs leg amputation in epidemiological terms (when interpreted as “legs get more total trauma before amputation” in many mechanisms).

---

## 3. Comparison: Medical vs Game

| Aspect | Medical | Game |
|--------|---------|------|
| **Bone vs soft tissue** | Bone requires more force to cut than soft tissue. | Bone and tissue are separate pools; damage is split by threshold/fraction (bone only takes a fraction of excess damage). |
| **Pre-existing damage** | Severely injured limbs more likely to be amputated; MESS/limb salvage use injury severity. | **Severance ease**: low tissue/bone ratio + wound count + worst severity → ease 1.0–1.8 → same hit does more damage to mangled parts. |
| **Relative part size** | Legs larger than arms; more mass/bone to cut through. | **body_max / bone_max** larger for legs than arms → more damage needed to zero pools. |
| **Single-blow severance** | No standard “force in N per part” in literature. | One hit can sever by (1) reducing both pools to 0, or (2) early sever: when combined remaining &lt; 18%, roll (up to 65% chance) to sever on any hit that does damage. |
| **Wound severity** | Critical/severe soft-tissue and skeletal injury drive amputation decisions. | Worst wound severity on part adds to ease (critical +0.20, severe +0.12, etc.), making the next hit more effective. |

---

## 4. Summary

- **Medical:** Severance depends on tissue type (bone harder than soft tissue), extent of **pre-existing damage** (mangled extremity → easier to amputate), and **part size/mass** (leg > arm in terms of structure to cut through). No exact force-per-part values are used here.
- **Game:** (1) **Damage required to sever** is relative to **body_max** and **bone_max** per part (arms easier than legs in raw “HP” terms). (2) **Severance ease** makes the **same hit** do up to **1.8× effective damage** when the part is already wounded and damaged, so full-health limbs are hard to chop through and mangled/bone-damaged limbs are much easier to dismember. (3) **Wound count and severity** directly increase ease, in line with clinical severity/limb salvage concepts.

Sources: PubMed 32162009, 35278317; MedlinePlus traumatic amputation; PMC2740356, PMC9702595 (MESS, limb salvage); NCBI limb amputation overviews.

---

## 5. Severed vs Crushed/Mangled: Wounds, Bleeding, Pain, and Healing

### 5.1 Attached vs not attached

- **Severed:** `body_cutting <= 0` and `bone_health <= 0` — the part is **no longer attached** (traumatic amputation). It cannot contribute to the body’s bleeding or pain; its wounds are removed from the entity.
- **Crushed / mangled:** `body_blunt <= 0` and `bone_health <= 0` — the part is **still attached** but destroyed (crush injury, pulp). The limb is salvageable in principle; pain and bleeding from that part still affect the body.

So only **severed** parts have wounds removed and are excluded from total bleeding rate and total pain. **Crushed** parts keep their wounds and continue to contribute to bleeding and pain until healed or stabilized.

### 5.2 Medical basis: limb salvage and healing of mangled-but-attached limbs

- **Limb salvage vs amputation:** For mangled extremities that remain attached, the choice is salvage (multiple surgeries, reconstruction) vs amputation. “Life before limb” applies when the patient is unstable; otherwise salvage is attempted when feasible (PMC9702595, limb salvage reviews).
- **Healing when salvaged:** Reconstruction typically starts within days (e.g. mean ~4 days to first reconstruction). Initial care involves debridement; then soft-tissue reconstruction (flaps, grafts) and, when needed, bone transport (e.g. Ilizarov) for large bone defects. Wound healing often within weeks; bone and full function can take many months (e.g. 8+ months bone transport, ~26 months in complex cases with infection and large defects). So **mangled-but-attached limbs can heal** with time and intervention; **severed limbs do not reattach** in the game’s model.
- **Pain and bleeding:** An attached mangled limb continues to cause pain and can bleed (and become infected) until treated; a severed part is gone and no longer contributes.

### 5.3 Game implementation

| Aspect | Severed (part gone) | Crushed / mangled (still attached) |
|--------|---------------------|------------------------------------|
| **Wounds** | Removed when part is severed; not counted. | Kept; still in `wounds[part]`. |
| **Bleeding** | Excluded from `get_total_bleeding_rate()`. | Included; part still contributes. |
| **Pain** | Excluded from `get_total_pain()`. | Included; part still contributes. |
| **Healing (tissue/bone)** | Skipped in `process_healing()` — part cannot “regrow.” | **Not** skipped; tissue and bone can heal from 0 over time (limb salvage). |

So crushed/mangled parts use the same healing curves as other damaged parts (exponential deficit decay); recovery from 0 is slow and represents reconstruction and rehabilitation rather than reattachment of a lost part.
