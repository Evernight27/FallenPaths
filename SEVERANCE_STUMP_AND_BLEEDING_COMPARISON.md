# Severance, Stump, and Bleeding: FallenFramework vs Fallen-Paths

This document summarizes how **FallenFramework** handles severance with stumps and bleeding, then compares **options** for handling stump and bleeding in **fallen-paths**.

---

## 1. FallenFramework: Severance and Stump System

### 1.1 Severed vs destroyed

- **Severed:** Sharp weapons (cut, pierce) that reduce cutting + bone to 0 → part is **cut off** (traumatic amputation). Part emits `part_severed`; then **converted to stub**.
- **Destroyed (not severed):** Blunt weapons (bruise, crush) that reduce health to 0 → part is **destroyed** (crushed), not amputated. No stub; part is just gone for functionality.

So Framework has the same idea as fallen-paths: sharp → severed (part gone), blunt → destroyed/crushed (part gone but mechanism different). Framework then adds a **stub** only for severed parts.

### 1.2 Two-phase bleeding for severed parts

1. **Severed, not yet stub**  
   When cutting + bone hit 0 from a sharp hit, the part is `is_severed = true` but `is_stub = false`. In `_update_bleeding_and_pain()`:
   - **Bleeding:** Uses `destruction_injury_type` (e.g. cut) to get base bleeding rate, then multiplies by **`SEVERED_PART_BLEEDING_MULTIPLIER` (2.0)**. So severed parts bleed at **2× base rate** even though the part’s normal injuries were not yet converted.
   - **Pain:** 0 (part is gone).

2. **Stub (after `convert_to_stub()`)**  
   `CreatureHealth._on_part_severed(part)` calls `part.convert_to_stub(self)`:
   - **Old injuries** on that part (and children) are **discarded** (marked healed, cleared).
   - **Stub health:** `stub_max_health = max_hp * 0.3`, `stub_health = max(0, cutting_health * 0.3)` (or 50% of stub max if 0). Represents remaining tissue at amputation site.
   - **New stump wound:** A new wound is created; a **stump injury** is added (cut, severity critical, damage = `stub_max_health - stub_health`). This injury is the only source of bleeding/pain for that “part” from then on.
   - **Bleeding/pain:** Stub’s `_update_bleeding_and_pain()` sums bleeding and pain from **stump wound injuries** only. So bleeding comes from the synthetic stump wound, can clot, and can be bandaged/healed like any other wound.
   - **Healing:** Stubs heal **stub_health** (and thus the stump wound’s damage). When fully healed, bleeding stops but the part **remains a stub** (no regrowth).

So in Framework: **severed = part gone → immediately heavy bleeding (2× base); then stub = one critical wound at amputation site that bleeds and can be treated/healed.**

### 1.3 Summary table (FallenFramework)

| State              | Bleeding source                    | Pain   | Healing                          |
|--------------------|------------------------------------|--------|----------------------------------|
| Severed (pre-stub) | 2× base rate from destruction type  | 0      | None (converted to stub quickly) |
| Stub               | Stump wound injuries (can clot)    | From stump wound | Heal stub_health → wound closes |
| Destroyed (blunt)  | From injuries before destruction   | —      | Part gone, no stub               |

---

## 2. Fallen-Paths: Current Behavior

- **Severed:** `body_cutting[part] <= 0` and `bone_health[part] <= 0`. We **erase `wounds[part]`** when this happens. So:
  - **Bleeding:** Severed parts are **excluded** from `get_total_bleeding_rate()` (we skip severed parts when summing). There is **no** separate stump wound or stump bleeding. **Net effect: amputation site does not bleed at all.**
  - **Pain:** Severed parts are excluded from `get_total_pain()` (we skip severed parts). So no pain from the missing part (correct).
- **Crushed/mangled:** Part still attached (blunt 0, bone 0). Wounds stay; they still contribute to bleeding and pain; tissue/bone can heal (limb salvage).

So the main gap vs reality: **in fallen-paths, a severed limb causes no bleeding from the stump.** Medically, the amputation site does bleed (arterial/venous) until controlled (tourniquet, packing, surgery).

---

## 3. Options for Stump and Bleeding in Fallen-Paths

### Option A: No stump (current)

- **Behavior:** Severed → wounds removed, part skipped in bleeding/pain totals. Stump has no wound and does not bleed.
- **Pros:** Simple; no new data or logic; no risk of double-counting.
- **Cons:** Unrealistic: amputation sites bleed and need treatment; no bandaging/tourniquet gameplay for amputations.

### Option B: Stump as a single synthetic wound (Framework-style)

- **Behavior:** When a part becomes severed, **do not** erase wounds for that part. Instead:
  1. **Replace** that part’s wound list with a **single “stump” wound** (e.g. cut, critical, damage/rate from constants).
  2. That stump wound participates in `get_total_bleeding_rate()`, `process_bleeding()` (clotting), `apply_bandage()`, and healing like any other wound. Optionally use a **severed-stump multiplier** (e.g. 2×) on the stump’s base rate to reflect arterial/venous bleed.
  3. **Pain:** Either 0 (part gone) or a small fixed pain for “stump pain” (your choice).
- **Implementation sketch:** In `take_damage_split()`, when `_is_part_severed(part)`:
  - Set `wounds[part] = [ _create_stump_wound(part) ]` instead of `wounds.erase(part)`.
  - `_create_stump_wound(part)` returns one injury dict (injury_type cut, severity critical, base_bleeding_rate from constants × optional multiplier, damage e.g. from body_max).
  - In `get_total_pain()` you can either include stump (small pain) or keep excluding severed parts for pain (stump pain = 0).
- **Pros:** Amputation site bleeds and can be bandaged/healed; aligns with Framework and with medical reality.
- **Cons:** Need to define stump rate/duration and ensure UI shows “stump” or “amputation” clearly so it’s not confused with a normal wound.

### Option C: Severed part contributes a fixed bleeding rate (no wound)

- **Behavior:** Severed parts do **not** have wounds (current erase). Add a **separate** contribution to total bleeding: e.g. `get_total_bleeding_rate()` = sum of wound rates **plus** a fixed rate per severed part (e.g. from `BleedingConstants.STUMP_BLEEDING_RATE` or per-part constant). This rate could decay over time (simple curve) or stay until “treated” (e.g. a flag `stump_stabilized[part]` set by bandage/tourniquet).
- **Pros:** Stump bleeds without introducing a wound object; easy to tune one number per part or global.
- **Cons:** Stump bleeding is not a first-class wound (no clotting curve, no per-wound healing progress unless you add a parallel system). More special-case logic.

### Option D: Hybrid (stump wound + optional multiplier)

- Same as Option B, but with an explicit **severed-stump multiplier** in `BleedingConstants` (e.g. `SEVERED_STUMP_BLEEDING_MULTIPLIER = 2.0`) applied to the stump wound’s base rate. Makes it easy to tune “amputation bleeds more than a normal critical cut” and to document the medical intent.

---

## 4. How level-accurate stump bleeding works (fallen-paths)

### 4.1 What “level” means

**Level** = where on the body part the amputation occurred, expressed as the **sub_region** of the hit that caused severance (e.g. `upper_arm`, `forearm`, `hand` for an arm). Proximal (closer to torso) = larger vessels and more tissue cross-section → stump bleeds more. Distal (hand, foot) = smaller vessels → stump bleeds less. So the same “severed arm” bleeds differently if cut at the shoulder vs at the wrist.

### 4.2 Formula

Stump base bleeding rate (before arterial roll and random variation) is:

1. **Part + sub_region base:** `get_bleeding_rate("cut", "critical", part, sub_region)`  
   = `BLEEDING_RATES[cut][critical]` × `BODY_PART_BLEEDING_MULTIPLIERS[part]` × `SUB_REGION_BLEEDING_MULTIPLIERS[part][sub_region]`.
2. **Level multiplier:** × `STUMP_LEVEL_MULTIPLIERS[part][sub_region]`.  
   Proximal sub_regions (e.g. upper_arm, thigh) have mult &gt; 1; distal (hand, foot) have mult &lt; 1; mid (forearm, calf) ≈ 1.
3. **Random variation (CoreEntity):** × (0.92 + randf()×0.16) → 0.92–1.08 per stump.
4. **Arterial (optional):** If arterial roll succeeds (critical cut arterial chance × `STUMP_ARTERIAL_CHANCE_MULTIPLIER`), rate × `ARTERIAL_BLEEDING_MULTIPLIER` (2.0).

So: **stump_rate = part_sub_region_critical_cut_rate × level_mult × variation [× 2.0 if arterial].**

### 4.3 How sub_region is decided

**Sub_region is not passed in from the caller.** Combat (and any other caller) only chooses the **body part** (e.g. `right_arm`). The sub_region is chosen **inside** `CoreEntity.take_damage_split()`:

1. At the start of damage application (after armor), the game calls  
   `sub_region = _Bleeding.get_random_sub_region(part)`.
2. **`get_random_sub_region(part)`** (BleedingConstants) does a **weighted random** over that part’s sub_regions using **SUB_REGION_WEIGHTS[part]**:
   - For each sub_region (e.g. `upper_arm`, `elbow`, `forearm`, `hand` for an arm), the weight is the relative hit probability (surface area / exposure).
   - One sub_region is picked at random with probability proportional to that weight.
   - Example (right_arm): weights 1.0, 0.4, 1.0, 0.8 → elbow and hand less likely than upper_arm/forearm.

So **each hit** gets one random sub_region for the chosen part. That same sub_region is then used for: bone threshold/fraction, wound creation (and thus bleeding/severity), and—if the part severs—for the **stump level** (passed to `_create_stump_wound(part, sub_region)`).

- **Normal severance:** The sub_region of the hit that reduced cutting and bone to 0 is exactly the one used for the stump (amputation level).
- **Early severance (probabilistic):** Severance happens in the same call that applied damage, so the same sub_region from that hit is still used. If you ever had a code path that severed without a hit (e.g. save/load), `_create_stump_wound` would receive empty sub_region and then call `get_random_sub_region(part)` itself.

### 4.4 Constants (BleedingConstants.gd)

| Constant | Role |
|----------|------|
| `STUMP_LEVEL_MULTIPLIERS[part][sub_region]` | Amputation-level modifier. Proximal &gt; 1, distal &lt; 1. |
| `STUMP_ARTERIAL_CHANCE_MULTIPLIER` (1.4) | Stump arterial chance = critical cut arterial chance × this (clamped to 1). |
| `get_stump_bleeding_rate(part, sub_region)` | Returns (critical cut rate for part+sub_region) × level mult. |

**STUMP_LEVEL_MULTIPLIERS (examples):**

| Part | Sub_region | Mult | Rationale |
|------|------------|------|-----------|
| right_arm / left_arm | upper_arm | 1.22 | Proximal; brachial / major branches. |
| | elbow | 1.08 | |
| | forearm | 1.0 | Baseline. |
| | hand | 0.88 | Distal; smaller vessels. |
| right_leg / left_leg | thigh | 1.2 | Proximal; femoral / SFA. |
| | knee | 1.1 | Popliteal region. |
| | calf | 1.0 | Baseline. |
| | foot | 0.88 | Distal. |
| head | scalp | 1.15 | Highly vascular. |
| | face | 1.0 | |
| | neck | 1.25 | Carotid/jugular region. |
| chest | thoracic | 1.08 | |
| | abdominal | 1.12 | |

### 4.5 Flow in code

1. **Severance** (CoreEntity `take_damage_split`): When `_is_part_severed(part)`, set `wounds[part] = _create_stump_wound(part, sub_region)` (sub_region from the hit, or empty for early sever).
2. **`_create_stump_wound(part, sub_region)`:** If sub_region empty, `sub_region = _Bleeding.get_random_sub_region(part)`. Then base_rate = `_Bleeding.get_stump_bleeding_rate(part, sub_region)` × (0.92–1.08). Arterial roll; if hit, base_rate × 2. Build single wound dict with `is_stump: true`, same clotting/bandage/healing as other wounds.
3. **Bleeding total:** `get_total_bleeding_rate()` sums all wounds (including stump); severed parts are no longer skipped.
4. **Pain:** Severed parts are still skipped in `get_total_pain()` (stump pain = 0).
5. **Clotting / bandage / healing:** Stump wound is processed like any other wound; when resolved, it is removed and the part has no wounds again (stump closed).

---

## 5. Recommendation (Option B implemented)

- **Implemented:** Option B with **body-part- and level-accurate** stump bleeding and slight random variation.
- **BleedingConstants:** `get_stump_bleeding_rate(part, sub_region)` uses critical-cut rate × body part × sub_region bleeding mult × **STUMP_LEVEL_MULTIPLIERS** (proximal = higher, e.g. upper_arm 1.22, hand 0.88). `STUMP_ARTERIAL_CHANCE_MULTIPLIER` (1.4) for arterial roll. Slight variation (0.92–1.08) applied in CoreEntity.
- **CoreEntity:** On severance, `wounds[part] = _create_stump_wound(part, sub_region)` (sub_region = hit that severed; if empty, random per part). Stump wound participates in `get_total_bleeding_rate()`, `process_bleeding()`, `apply_bandage()`, `process_healing()`. Severed parts still excluded from `get_total_pain()` (stump pain = 0). Tissue/bone pool healing still skipped for severed parts (no regrowth).
- **UI:** Wound dict includes `"is_stump": true` for display (e.g. “Stump (upper_arm)”).
