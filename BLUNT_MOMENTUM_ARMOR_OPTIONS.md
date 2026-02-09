# Blunt Penetration: Momentum-Based Options and Armor Cushioning

Ways to make **blunt** depend on **momentum** (so heavy 2H sword crushes more than thin sword at same KE/contact) and to make **armor cushioning** (padding) matter more for blunt, while **cut** stays “force to pierce/cut” (pressure, KE, effective edge).

---

## Design goals

| Stream | Physics | What should matter |
|--------|--------|---------------------|
| **Cut / sharp** | Force to pierce or cut | Pressure (KE + effective edge contact). Already done. |
| **Blunt** | Crushing, BAT, concussion | **Momentum** (mass × velocity). Damage already momentum-based; penetration vs armor should reflect momentum so heavy weapons “push through” padding more. |
| **Armor vs blunt** | Cushioning vs rigid | **Padding** (gambeson, cloth) absorbs momentum/impulse. **Rigid** (plate) resists local deformation (pressure) but transmits more when it doesn’t pierce. So cushioning should reduce transmitted blunt more than rigid. |

**Target behaviour:** Same KE and same contact area → heavy 2H sword has **higher momentum** (p = √(2·KE·m)) → should crush/blunt better than a thin sword. So blunt penetration (vs armor) should scale with momentum, not just KE.

---

## Option A: Single blunt penetration from momentum/area (minimal change)

**Idea:** Replace blunt pen from KE/area with **impulse per area** (momentum/area). Same compare vs layer `blunt_resistance_mpa`; tune a constant so values stay in the same numeric range.

**Formula:**
- `momentum = mass_kg × velocity_m_s`
- `pen_blunt = K_IMPULSE_MPA × (momentum / A_m²)`  
  Units: (kg·m/s)/m² × K → “effective MPa”. Choose K so typical mace (e.g. 1.7 kg, 12 m/s, head 8 cm) gives pen_blunt in the same band as now (~10–20), and plate ~40 still makes sense.

**Armor:** No change. Layers keep `blunt_resistance_mpa`. Interpretation: “resistance to impulse pressure” (both rigid and cushioning contribute to one number). Your existing **transmission** values already give cushioning: cloth 0.16, plate 0.46 → cloth absorbs more when pen < res.

**Heavy vs thin at same KE and contact:**  
p ∝ √m ⇒ heavy 2H has higher momentum ⇒ higher pen_blunt ⇒ more often penetrates or transmits more. ✓

| Pros | Cons |
|------|------|
| One formula change; no new armor fields | Cushioning only via existing transmission, not an explicit “absorbs momentum” stat |
| Heavy weapons naturally beat light for blunt | Rigid vs padding not distinguished in the resistance number |
| Same armor data and deflection logic | K must be tuned so plate/leather/cloth still feel right |

**Implementation:** In `WeaponDamageHelper.compute_penetration` (BLUNT branch): compute `momentum = mass × velocity`, `A_m²` from blunt contact, `pen_blunt = WeaponConstants.BLUNT_MOMENTUM_TO_MPA × momentum / A_m²`. Tune `BLUNT_MOMENTUM_TO_MPA` so mace vs plate/leather and sword vs plate/leather behave as desired.

---

## Option B: Two-layer blunt model – rigid (pressure) vs cushion (momentum absorption)

**Idea:** Blunt is checked in two ways: (1) **Rigid** layer resists by **pressure** (KE/area). (2) **Cushioning** absorbs **momentum**; transmitted blunt = f(momentum, cushion stat).

**Layer stats:**
- `blunt_rigid_mpa` – pressure (KE/area) needed to “fail” the layer (deform, crack). Plate high, cloth low.
- `blunt_cushion` – 0–1 or resistance: how much momentum the layer absorbs. Cloth/gambeson high, plate low (transmits more).

**Attack:**
- `pen_pressure = BLUNT_PRESSURE_SCALE × KE / A` (unchanged)
- `pen_momentum` = momentum or momentum/area (for comparison with cushion).

**Logic per layer:**
- If `pen_pressure >= blunt_rigid_mpa` → layer fails (penetration path); damage reduction as now.
- If `pen_pressure < blunt_rigid_mpa` → layer holds; **transmitted** = damage × transmission, where transmission depends on **momentum vs cushion**: e.g. `transmission = base_transmission × (1 - cushion_factor × f(pen_momentum))` so more momentum and less cushion → more BAT.

**Heavy 2H vs thin sword:** Same KE and area → same pen_pressure (rigid layer behaves the same). But heavy has more momentum → less absorbed by cushion → more transmitted. ✓

| Pros | Cons |
|------|------|
| Explicit cushioning; padding “soaks” momentum | New stats and logic; more tuning |
| Rigid = “does it break/deform?”, cushion = “how much gets through?” | Two blunt numbers per layer; penetration and transmission both depend on momentum |
| Matches “plate resists pressure, gambeson absorbs impact” | More code in ArmorPiece and constants |

**Implementation:** Add `blunt_rigid_mpa` and `blunt_cushion` (or reuse/rename). In `_process_layer` for BLUNT: compare pressure to rigid; if not penetrated, compute transmission from momentum and cushion. Sharp unchanged.

---

## Option C: Single pen_blunt from momentum/area + per-layer “cushion” modifier on transmission

**Idea:** Blunt penetration is **momentum/area** only (Option A). Keep one `blunt_resistance_mpa` per layer, but add an optional **cushion** modifier that scales **transmission** when blunt deflects: high cushion → lower transmission (more absorption).

**Formula:**
- `pen_blunt = K × (momentum / A)` (as in A).
- When `pen_blunt < blunt_res`: transmitted = damage × transmission × (1 - cushion_factor) or transmission = base × cushion_mult. So cloth has high cushion_mult (e.g. 0.5) → effective transmission lower; plate low cushion_mult (1.0) → full BAT transmission.

**Armor:** Add one number per layer, e.g. `blunt_cushion`: 0 = no extra absorption, 1 = max absorption. So cloth 0.8, plate 0.0, leather 0.5, mail 0.2. Transmission when deflected = `BLUNT_BAT_TRANSMISSION × (1 - blunt_cushion × k)`.

**Heavy vs thin:** Same as A: heavy has higher pen_blunt; if both deflect, heavy still does more damage (pre_blunt is momentum-based). Cushion then reduces that transmitted amount more on padded layers. ✓

| Pros | Cons |
|------|------|
| One new formula (momentum pen) + one new layer field | Cushion only affects “when deflected”, not a separate “momentum resistance” |
| Cushioning clearly matters for blunt | Slightly more constants and layer data |
| Same deflection flow; minimal armour logic change | |

**Implementation:** Option A’s pen_blunt change + in ArmorConstants add `blunt_cushion` per layer; in `_process_layer` for BLUNT deflection use `transmission = BLUNT_BAT_TRANSMISSION * (1.0 - layer.blunt_cushion * CUSHION_FACTOR)`.

---

## Option D: Hybrid blunt pen = pressure + momentum (one number)

**Idea:** One `pen_blunt` for comparison with `blunt_resistance_mpa`, but it is a **mix** of pressure and momentum so both matter:

- `pen_blunt = α × (KE/A) + β × (momentum/A)`  
  or  
- `pen_blunt = (KE/A)^a × (momentum/A)^b` (multiplicative).

Tune α, β (or a, b) so that at equal KE and area, heavier weapon has higher pen_blunt. E.g. α = 0.3, β = 0.7 so momentum dominates but KE still matters a bit (faster hit = slightly more “punch”). Armor stays one number; cushioning only via transmission as now.

**Heavy vs thin:** Same KE and area ⇒ same KE/A; 2H has higher momentum/A ⇒ higher pen_blunt. ✓

| Pros | Cons |
|------|------|
| Single pen, single res; no new layer fields | Cushioning not explicit; same as current transmission only |
| Both KE and momentum affect blunt vs armor | Two constants to tune (α, β or exponents) |
| Easy to implement in one formula | |

**Implementation:** In BLUNT branch: compute both `pressure_term = KE/A`, `momentum_term = momentum/A`; `pen_blunt = BLUNT_PEN_ALPHA * pressure_term + BLUNT_PEN_BETA * momentum_term`, with scale so result is in MPa-like range. Or use multiplicative form and one scale constant.

---

## Comparison summary

| Option | Blunt pen from | Cushioning | New armour fields | Complexity |
|--------|-----------------|------------|-------------------|------------|
| **A** | Momentum/area only | Via existing transmission | None | Low |
| **B** | Pressure + momentum (two checks) | Explicit cushion stat; transmission = f(momentum, cushion) | rigid_mpa, cushion | High |
| **C** | Momentum/area | New cushion modifier on transmission | One per layer (cushion) | Medium |
| **D** | α×pressure + β×momentum | Via existing transmission | None | Low |

---

## Recommendation

- **Fastest and enough for “heavy crushes more”:** **Option A** – blunt penetration = K × (momentum / area). Cushioning already partly there via deflection_transmission (cloth 0.16, plate 0.46).
- **If you want cushioning to clearly “absorb blunt”:** **Option C** – same as A, plus one `blunt_cushion` per layer that reduces transmission when blunt deflects.
- **If you want rigid vs cushion as separate physics:** **Option B** – rigid resists pressure, cushion absorbs momentum; more work and tuning.

Cut stays as-is: force to pierce/cut = sharp penetration (KE + effective edge) and sharp damage; crushing and momentum are fully on the blunt side with any of these options.
