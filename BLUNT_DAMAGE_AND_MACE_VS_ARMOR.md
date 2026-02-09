# How Blunt Damage Works, and Mace vs Sword vs Armor

Summary of how your system handles blunt damage and how maces compare to swords against plate and leather.

---

## 1. How blunt damage is handled

### 1.1 Pre-armor damage

- **Same formula for all attacks:** `pre_armor = scale × √(KE) × strength_mod × arm_mod × contact_damage_factor`, clamped to [1, 80].
- **Split by cut ratio:** For each attack, `cut_ratio` (0–1) splits this into sharp vs blunt:
  - **Sword cut:** e.g. `cut_ratio = 0.75` → 75% `pre_cut` (sharp), 25% `pre_blunt` (blunt).
  - **Mace:** `cut_ratio = 0` (blunt-only moves) → 0% sharp, 100% blunt.
- So **pre-armor magnitude** is similar for similar KE; only the sharp/blunt split and penetration differ.

### 1.2 Penetration (what armor is compared against)

**Sharp (mm RHA):**  
`pen_sharp = (KE / J_PER_MM_RHA) × (baseline / contact_width)^0.5`  
- Contact: stab → point_width, cut → blade_width.  
- Used for the **sharp stream** only.

**Blunt (MPa):**  
`pen_blunt = (BLUNT_PRESSURE_SCALE × KE / A_m²) / 1e6`, with `A = π×(d/2)²`, `d` = contact width in m.  
- Contact: from the **move’s** contact type. For blunt moves → `head_diameter`; for cut moves the blunt stream still uses the **same** move, so contact = blade_width.  
- Used for the **blunt stream** and (via RHA_TO_MPA) for deflected sharp→blunt.

So:

- **Mace (blunt move):** contact = `head_diameter` (e.g. 8 cm) → large area → **low pressure** → low `pen_blunt` (e.g. ~12 MPa at typical KE).
- **Sword cut:** sharp stream uses blade_width for sharp pen; blunt stream uses **same** blade_width for blunt pen → small area → **high pressure** → high `pen_blunt` (e.g. ~100+ MPa).

CombatManager passes **one** `pen_sharp` (from the SHARP penetration call) and **one** `pen_blunt` (from the BLUNT penetration call) into `take_damage_split`. So the blunt portion of a **cut** uses the blunt penetration computed with the **cut** move’s contact (blade), not a separate “blunt” contact.

### 1.3 Armor vs blunt — “current flow (sharp first, then one blunt pass)”

**Sharp is checked first.** If sharp deflects, raw deflected blunt is returned and combined with pre_blunt; one blunt armor pass is then run. The two streams are resolved **separately**:

- **Sharp stream:** `apply_damage(pre_cut, SHARP, pen_s, pen_b)` is called. If a layer deflects, that layer turns sharp into blunt (× transmission), and then that **deflected amount** is run through **all layers** (including the one that just deflected) as blunt, **inside the same call**. The value returned is the **final** deflected blunt (already reduced by all layers). CoreEntity adds that to `final_blunt`.
- **Blunt stream:** `apply_damage(pre_blunt, BLUNT, 0, pen_b)` is called **separately**. The result is added to `final_blunt`.

So deflected cutting damage **is** turned into blunt and then checked against blunt armor — but that happens **inside** the sharp `apply_damage` call. The flow there is:

1. Layer i deflects sharp → `damage_remaining = damage × transmission` (e.g. plate: ×0.46). So the deflecting layer has already reduced once.
2. Then the code runs `damage_remaining` through **all** layers (j = 0, 1, 2, …) as blunt. So we call `_process_layer(damage_remaining, BLUNT, …, layers[j])` for **every** j, including j = i. So the **same** layer (e.g. plate) gets to reduce that blunt again. So the deflecting layer effectively applies twice: once when it deflects sharp → blunt (×0.46), and once when the resulting blunt is run through it in the “all layers” pass.

The direct blunt (pre_blunt) is never combined with the deflected amount before armor; the two are applied to armor in **two separate** `apply_damage` calls, and only the **outputs** are added in CoreEntity.

For the **blunt stream** itself (`apply_damage(pre_blunt, BLUNT, …)`):

- For each layer, **blunt** is compared to **blunt_resistance_mpa** (plate 40, leather 14, cloth 16, mail 10).
- **If pen_blunt < layer blunt_res:** same “deflection” path: keep `damage × transmission`, then run that through **all** layers again (so again, the same layer can reduce twice).
- **If pen_blunt ≥ layer blunt_res:** penetration branch: damage reduced by a factor, then continue to next layer.

So:

- **Low blunt pen** (e.g. mace 12 MPa vs plate 40) → deflection path → transmission, then full pass (including the deflecting layer again) → **heavy** reduction.
- **High blunt pen** (e.g. sword cut’s blunt stream 137 MPa vs plate 40) → penetration path → moderate reduction per layer.

---

## 2. Mace vs plate

- **Mace:** 100% blunt, contact = head 8 cm → at e.g. 12 m/s, KE ≈ 122 J → `pen_blunt ≈ 12 MPa`.  
- **Plate:** blunt_res = 40 MPa.  
- 12 < 40 → **deflection path**: damage × 0.46 (plate), then that result run through all layers again (plate 0.46, cloth 0.16) → total factor ≈ 0.46² × 0.16 ≈ **0.034** (about **3.4%** of blunt gets through).

**After the fix:** Blunt uses BLUNT_BAT_TRANSMISSION (0.75) and one pass; mace vs plate ~12% through. So **maces are no longer poor vs plate**; almost all blunt is absorbed because blunt penetration is below plate’s blunt resistance, and the deflection + full-pass logic applies the plate layer twice.

Historically, maces were **good** against plate because they don’t need to pierce; they transmit force through the armor (concussion, broken bones). So the current model is **backwards** for plate: it makes maces worse than they should be.

---

## 3. Sword (cut) vs plate

- **Sword cut:** ~75% sharp, ~25% blunt. Same KE band (e.g. 1.2 kg, 12 m/s → KE ≈ 86 J).
- **Sharp stream:** pen_sharp ≈ 1.08 mm RHA. Plate sharp_res 3.5 → 1.08 < 3.5 → **deflection** → sharp becomes blunt (×0.46), then that runs through all layers → very small remainder (e.g. ~2.5% of the sharp 75%).
- **Blunt stream:** pen_blunt is computed with **BLUNT** formula and the **cut** move’s contact = blade_width 2 cm → small area → **high** pen_blunt (e.g. ~137 MPa). 137 > 40 (plate) and 137 > 16 (cloth) → **penetration** in both layers → only moderate reduction (e.g. ~80% of the 25% blunt gets through).

**After the fix:** The blunt stream for cuts uses **BLUNT_CUT_MIN_CONTACT_CM** (5 cm), so pen_blunt is lower and deflects on plate (BAT). Combined blunt (deflected sharp + 25% direct) runs once: e.g. ~59.5% × 0.75 × 0.16 ≈ **~7%** through. So **maces (~12% through) are now more effective than sword cuts (~7%) vs plate**.

---

## 4. Mace vs leather

- **Leather:** blunt_res = 14 MPa. Mace pen_blunt ≈ 12 MPa → 12 < 14 → **deflection** again → transmission 0.24 (leather), then through cloth 0.16 → very small fraction gets through (e.g. ~4% of blunt).
- So **mace vs leather** is also heavily reduced.

---

## 5. Sword (cut) vs leather

- **Sharp stream:** pen_sharp ≈ 1.08 mm, leather sharp_res 1.0 → 1.08 ≥ 1.0 → **penetration** (e.g. ~50% of sharp gets through leather, then cloth reduces further). A substantial share of the 75% sharp can get through.
- **Blunt stream:** high pen_blunt (blade contact) → penetrates leather and cloth easily.
- So **sword vs leather** does much more damage than **mace vs leather**.

---

## 6. Summary table (after fix)

| Attacker     | Armor   | What happens | Relative outcome |
|-------------|---------|--------------|------------------|
| **Mace**    | Plate   | Blunt pen 12 < 40 → deflection path, layer applied twice → ~3–4% through | **Better** vs plate than sword cut |
| **Mace**    | Leather | Blunt pen 12 < 14 → deflection → ~4% through | **Poor** vs leather |
| **Sword cut** | Plate   | Sharp deflected (tiny); blunt 25% has very high pen → ~80% of that through | **Less** than mace vs plate |
| **Sword cut** | Leather | Sharp penetrates; blunt penetrates | **Much better** than mace vs leather |

So:

- **Maces are now more effective than swords vs plate** (BAT + single pass; cut blunt uses 5 cm contact so it deflects on plate).
- **Maces are worse than swords vs leather** as well, because leather’s blunt_res (14) is above typical mace pen (12), so mace stays in the deflection path.

---

## 7. Why this happens (design points)

1. **Blunt pen vs blunt res uses “deflection” path**  
   When `pen_blunt < blunt_res`, the same “deflection + run through all layers” logic as for sharp is used, and the **deflecting** layer is applied again in the full pass → double penalty. For blunt, you might want a single absorption (e.g. one transmission) without running through the same layer twice.

2. **Blunt penetration uses move contact**  
   The blunt stream’s penetration is computed from the **move’s** contact (e.g. blade_width for a cut). So the “25% blunt” part of a cut gets **sword-blade** pressure (small area, high MPa) and penetrates plate easily. That makes the sword’s blunt component very effective against plate.

3. **Mace head is large**  
   head_diameter 8 cm → large area → low pressure → pen_blunt below plate and leather blunt_res → mace is always in the deflection path and gets the heaviest reduction.

---

## 8. If you want maces better vs plate (and still sensible vs leather)

- **Option A (recommended):** When **damage type is BLUNT** and `pen_blunt < layer blunt_res`, do **not** run the remaining blunt through **all** layers again; only run it through **inner** layers (or apply a single transmission and then one pass through layers). That avoids double-applying the same layer and reduces the over-penalty for maces.
- **Option B:** Give blunt-vs-blunt a different curve: e.g. when pen < res, use a **higher** effective transmission (e.g. 0.6–0.7 for plate) so more force “goes through” as behind-armor trauma, even without penetration.
- **Option C:** Increase mace pressure (e.g. smaller effective head for penetration only, or a blunt-specific scale) so mace pen_blunt can exceed plate’s 40 MPa and use the penetration branch instead of deflection. That makes maces penetrate plate’s blunt resistance in the same way swords’ blunt component does.

---

## 9. Design assessment: is this the best way?

**Yes, for your goals.** The current setup is a good fit: it’s consistent, understandable, and matches the behavior you want (maces better vs plate, contact per attack, no double-penalty).

**What it does well**

- **Single blunt pass:** Deflected sharp is added to pre_blunt and run through armor once. No double-apply of the same layer; one clear “blunt stream.”
- **Sharp-first, then combined blunt:** Armor sees sharp first; only the raw deflected amount is turned into blunt and merged. Logic is easy to follow and tune.
- **BAT for blunt:** When blunt doesn’t penetrate, BLUNT_BAT_TRANSMISSION (0.75) lets maces do meaningful behind-armor trauma vs plate.
- **Contact per attack and per component:** Stab uses the point for both sharp and blunt; cut uses edge for sharp and slap for blunt; blunt moves use head/flanges. Surfaces match what actually hits.
- **Cut blunt vs plate:** BLUNT_CUT_MIN_CONTACT_CM makes the blunt part of a cut deflect on plate (BAT), so maces stay better than sword cuts vs plate.
- **No 0% cutting:** MIN_CUT_RATIO and edge_width give even maces a small cutting component (flanges breaking skin).

**Optional refinements (only if you want more nuance)**

- **Transmission vs pen/res:** Right now transmission is a fixed fraction per layer. You could scale it by (pen/res) so near-penetration transmits more than a clean bounce. Adds a knob, not required for “best.”
- **Separate pre_cut / pre_blunt formulas:** Pre-armor is one value split by cut_ratio. You could derive pre_cut and pre_blunt from different physics (e.g. sharp from edge geometry, blunt from momentum). More parameters and tuning; current split is simple and consistent.
- **Glancing / angle:** Cut ratio could depend on impact angle (e.g. more blunt on flat hits). Would need angle from combat; current fixed ratio is fine unless you add that.

**Verdict:** Keep this system. It’s the right level of detail for “medieval logic, mace vs plate, and per-attack contact.” Change it only if you explicitly want more simulation depth (e.g. transmission curves or angle-based split).

---

## 10. Optional refinements: complexity vs benefits (pros and cons)

Comparison of the three added-detail ideas: implementation complexity, benefits, and pros/cons.

---

### A. Transmission scales with pen/res (near-penetration transmits more)

**Idea:** When an attack does not penetrate (pen < res), the fraction transmitted as BAT scales with how close it was to penetrating. Example: `transmission = base * (0.5 + 0.5 * pen/res)` so a near-miss transmits more than a clean bounce.

**Note:** Impact size already scales with penetration in the current system: a bigger hit does more damage through earlier layers and thus more damage *reaches* a given layer, so transmitted amount (damage × transmission) is already larger for stronger hits. What A adds is: *same* damage at the layer, but near-penetration (high pen/res) → higher *fraction* transmitted. If that extra nuance is not needed, skip A.

---

### B. Separate pre_cut and pre_blunt formulas (different physics per component)

**Idea:** Compute pre_cut and pre_blunt independently: e.g. sharp from KE and edge geometry, blunt from momentum (mass × velocity) or KE and contact area. Each stream has its own scaling and caps.

| Aspect | Detail |
|--------|--------|
| **Complexity** | **Medium–high.** Two formulas and constant sets. Sharp e.g. `scale_sharp * sqrt(KE) * edge_factor`; blunt e.g. `scale_blunt * mass * v` or contact-based. Define caps, balance relative magnitudes, re-tune armor/wounds. |
| **Benefits** | Sharp reflects cutting ability (edge, speed), blunt reflects concussive (mass, momentum). Heavier weapons more blunt; lighter/faster more sharp. Stronger weapon identity from physics. |
| **Pros** | Closer to real mechanics; mace vs sword differ by formula, not only cut_ratio; armor already handles two streams. |
| **Cons** | More constants and a full balance pass; risk one stream dominates; pre_armor is two numbers for UI/debug. |

**Summary:** Best when you want weapon identity from separate sharp/blunt physics. Expect a non-trivial balance pass.

---

### C. Glancing / impact angle (cut ratio or damage depends on angle)

**Idea:** Impact angle (blade-to-surface) affects outcome: flat-on hit = more blunt (slap); edge-on = more sharp. So cut_ratio or damage is modified by angle, e.g. `effective_cut_ratio = cut_ratio * (0.3 + 0.7 * edge_alignment)`.

| Aspect | Detail |
|--------|--------|
| **Complexity** | **High.** Requires **angle or alignment from combat** (hit normal, weapon direction, or a glancing scalar). Implies raycast/collision, animation, or a proxy. Then policy: angle affects cut_ratio, penetration, and/or transmission. Multiple hooks. |
| **Benefits** | Glancing (flat) = less cut, more slap; clean edge = more cut. Same move can "bite" or "slap" by angle; positioning/angle matters. |
| **Pros** | Intuitive; explains hit-to-hit variation; armor shape could affect effective angle. |
| **Cons** | **Depends on combat providing angle.** Without it you fake it (e.g. random), which can feel arbitrary. Integration with hit detection and animations is the main cost. Damage can feel inconsistent if angle is noisy. |

**Summary:** Highest payoff for realism/feel, but only if you have or will add angle from combat. Not worth a full combat refactor just for this.

---

### Comparison at a glance

| Refinement | Complexity | Benefit | Best when |
|------------|------------|---------|-----------|
| **A. Transmission vs pen/res** | Low–medium | Smoother bounce→penetration; plausible BAT | You want one extra knob, no new combat data. |
| **B. Separate pre_cut / pre_blunt** | Medium–high | Distinct sharp vs blunt physics; weapon identity | You want mace vs sword to differ by formula. |
| **C. Glancing / angle** | High (needs angle) | Angle matters; flat = slap, edge = cut | You have or will add hit/impact angle. |

---

## 11. Implementation plan: B and C (for a new agent)

Use this section to implement **B** (separate pre_cut / pre_blunt formulas) and **C** (glancing / impact angle) in a follow-up session or with a new agent.

---

### B. Separate pre_cut and pre_blunt formulas

**Goal:** Compute pre_cut and pre_blunt from different physics so sharp reflects cutting (edge, speed) and blunt reflects concussive (mass, momentum). Weapon identity (mace vs sword) comes from formulas, not only cut_ratio.

**Current flow (to replace):**

- `WeaponDamageHelper.compute_pre_armor_damage(weapon, attack_instance, strength, arm_mod)` returns one value.
- `CombatManager`: `pre_armor = compute_pre_armor_damage(...)`; `cut_ratio = get_cut_ratio(...)`; `pre_cut = pre_armor * cut_ratio`; `pre_blunt = pre_armor * (1.0 - cut_ratio)`.

**Target flow:**

- Add `compute_pre_cut(...)` and `compute_pre_blunt(...)` that return separate values.
- CombatManager calls both and uses them as pre_cut and pre_blunt (no longer derive from one pre_armor and cut_ratio).
- Optionally keep `compute_pre_armor_damage` for UI/display as `pre_cut + pre_blunt` or deprecate and use sum where needed.

**Steps:**

1. **WeaponConstants.gd**
   - Add constants for sharp pre-damage: e.g. `DAMAGE_KE_SCALE_SHARP`, `SHARP_CONTACT_EXPONENT`, `PRE_CUT_MIN`, `PRE_CUT_MAX` (or reuse/rename existing if you keep one formula as base).
   - Add constants for blunt pre-damage: e.g. `DAMAGE_MOMENTUM_SCALE` (or KE-based with different exponent), `BLUNT_CONTACT_EXPONENT`, `PRE_BLUNT_MIN`, `PRE_BLUNT_MAX`. Example blunt formula: `scale_blunt * (mass_kg * velocity_m_s)` or `scale_blunt * sqrt(KE) * contact_factor_blunt`.
   - Tune so combined pre_cut + pre_blunt is in a similar range to current pre_armor for typical weapons (or document intended scale change).

2. **WeaponDamageHelper.gd**
   - Add `static func compute_pre_cut(weapon, attack_instance, strength, arm_mod) -> float` using KE (and optionally edge/sharp contact), strength_mod, arm_mod, sharp-specific scale and caps.
   - Add `static func compute_pre_blunt(weapon, attack_instance, strength, arm_mod) -> float` using mass×velocity or KE with blunt contact factor, and blunt-specific scale and caps.
   - Ensure both use the same strength/arm_mod so modifiers apply consistently. Use `get_effective_velocity_m_s` and weapon mass in both where appropriate.
   - Optionally keep `compute_pre_armor_damage` as `return compute_pre_cut(...) + compute_pre_blunt(...)` for callers that expect one number, or remove and update all callers.

3. **CombatManager.gd**
   - Replace the block that sets `pre_armor`, `pre_cut`, `pre_blunt` from `compute_pre_armor_damage` and `get_cut_ratio` with:
     - `pre_cut = WeaponDamageHelper.compute_pre_cut(weapon, attack_instance, atk.stats.strength, arm_mod)`
     - `pre_blunt = WeaponDamageHelper.compute_pre_blunt(weapon, attack_instance, atk.stats.strength, arm_mod)`
   - For display and for `DEFLECTED_DAMAGE_RATIO` (and any log that uses pre_armor), use `pre_armor = pre_cut + pre_blunt` so "total pre-armor" is still defined.
   - Update the print statement to show pre_cut, pre_blunt, and optionally pre_armor (sum).

4. **Cut ratio**
   - Decide whether to keep `get_cut_ratio` for anything (e.g. wound type or UI). If B fully replaces ratio with two formulas, you may only use cut_ratio for downstream logic that needs a ratio (e.g. bruise vs crush); in that case compute ratio as `pre_cut / (pre_cut + pre_blunt)` when needed, guarding for zero.

5. **Balance and docs**
   - Tune constants so mace has high pre_blunt and low pre_cut, sword has both moderate, dagger has high pre_cut and low pre_blunt, etc.
   - Update BLUNT_DAMAGE_AND_MACE_VS_ARMOR.md or WEAPON_DIMENSIONS_AND_CONTACT.md to describe the two formulas and constants.

**Files touched:** `weapon/WeaponConstants.gd`, `weapon/WeaponDamageHelper.gd`, `ui/CombatManager.gd`; optionally docs.

**Acceptance:** Pre_cut and pre_blunt are computed independently; mace has clearly higher blunt than cut, sword balanced, dagger higher cut; armor and take_damage_split unchanged and still receive pre_cut, pre_blunt, pen_sharp, pen_blunt.

---

### C. Glancing / impact angle (cut ratio or damage depends on angle)

**Goal:** Impact angle (blade-to-surface or edge alignment) affects how much of the hit is cutting vs blunt: flat hit → more blunt (slap), edge-on → more sharp (cut). Same move can "bite" or "slap" depending on angle.

**Prerequisite:** A source of angle or alignment per hit. Options: (a) Combat/Hit detection provides `impact_angle_rad` or `edge_alignment` (0–1) from raycast/collision; (b) Animation or attack state provides a scalar; (c) Stub with random for testing, then replace with real data later.

**Current flow:**

- `get_cut_ratio(weapon, attack_type, archetype)` returns a fixed ratio per move/weapon.
- CombatManager uses that ratio to split pre_armor into pre_cut and pre_blunt (or, after B, angle could scale pre_cut/pre_blunt).

**Target flow (option 1 – angle modifies cut_ratio):**

- If B is not implemented: CombatManager gets an `edge_alignment` (0–1) per hit. Effective cut_ratio = `base_cut_ratio * (min_cut + (1 - min_cut) * edge_alignment)`. So alignment 0 → more blunt; 1 → full cut ratio.
- If B is implemented: angle can scale the two pre values instead: e.g. `pre_cut *= (min_cut + (1 - min_cut) * edge_alignment)`, `pre_blunt *= (min_blunt + (1 - min_blunt) * (1 - edge_alignment))`, or similar, so flat hit reduces cut and increases blunt.

**Target flow (option 2 – angle modifies damage after split):**

- Keep pre_cut/pre_blunt as is; apply angle as a multiplier to final damage or to the values passed to armor. E.g. `effective_pre_cut = pre_cut * edge_alignment`, `effective_pre_blunt = pre_blunt * (1 - 0.5 * edge_alignment)` so flat hits reduce cut more. Same idea, different place.

**Steps:**

1. **Define angle source**
   - Add a way for the damage path to receive angle. Options:
     - **AttackInstance:** add property `edge_alignment: float` (0–1) or `impact_angle_rad: float`; set by CombatManager from hit result or stub.
     - **CombatManager:** when resolving a hit, get `edge_alignment` from hit detection, animation, or `randf()` for testing; pass into damage computation.
   - Document where the value comes from (e.g. "HitResult.edge_alignment" or "stub: random 0.2–0.8").

2. **WeaponConstants.gd**
   - Add `GLANCE_CUT_MIN: float = 0.2` (minimum cut fraction when fully flat) and `EDGE_ALIGNMENT_CUT_EXPONENT: float = 1.0` (or similar) so effective_cut_ratio = cut_ratio * (GLANCE_CUT_MIN + (1 - GLANCE_CUT_MIN) * edge_alignment).

3. **WeaponDamageHelper.gd**
   - Add `static func get_effective_cut_ratio(weapon, attack_type, archetype_dict, edge_alignment: float) -> float`: compute base ratio with `get_cut_ratio`, then return `base_ratio * (WeaponConstants.GLANCE_CUT_MIN + (1.0 - WeaponConstants.GLANCE_CUT_MIN) * clampf(edge_alignment, 0.0, 1.0))`. Or apply angle in CombatManager after get_cut_ratio.

4. **CombatManager.gd**
   - When building damage for a hit, obtain `edge_alignment` (from hit result, or stub: `randf_range(0.3, 0.9)`).
   - If using ratio-based split: call `get_effective_cut_ratio(..., edge_alignment)` instead of `get_cut_ratio(...)` when computing pre_cut/pre_blunt.
   - If B is implemented: after computing pre_cut and pre_blunt, multiply by angle factors (e.g. pre_cut *= angle_factor_cut, pre_blunt *= angle_factor_blunt) before passing to take_damage_split.
   - Pass edge_alignment into AttackInstance if downstream code needs it (e.g. UI "glancing hit").

5. **Hit detection / combat (if real angle is desired)**
   - Where hits are detected (raycast, collision, or animation event), compute angle between weapon direction or blade normal and impact normal; map to 0–1 (0 = flat, 1 = edge-on). Feed that into the damage path as edge_alignment. If not available yet, keep stub.

6. **Docs and tuning**
   - Document in this file or WEAPON_DIMENSIONS: how edge_alignment is defined, where it comes from, and how it scales cut vs blunt.
   - Tune GLANCE_CUT_MIN so flat hits feel noticeably more blunt without making edge hits feel weak.

**Files touched:** `weapon/WeaponConstants.gd`, `weapon/WeaponDamageHelper.gd` (optional new helper), `ui/CombatManager.gd`, `weapon/AttackInstance.gd` (optional property); hit detection if adding real angle.

**Acceptance:** When edge_alignment is 0 (flat), effective cut is reduced (more blunt); when 1 (edge-on), full cut ratio (or full pre_cut after B). Stub with random produces visible variation; replacing stub with real angle produces angle-consistent behavior.

---

### Order of implementation

- **B first, then C:** Implement B so pre_cut/pre_blunt are independent; then add C by applying edge_alignment to those two values (or to the ratio used for wound logic). This keeps angle affecting the same numbers that armor sees.
- **C first (without B):** Implement C by modifying effective cut_ratio with angle; pre_cut/pre_blunt still derived from one pre_armor and that effective ratio. Simpler but less flexible than B+C together.