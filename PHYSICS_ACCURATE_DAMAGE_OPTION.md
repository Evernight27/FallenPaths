# Most Physics-Accurate Damage: Edge (Sharp) vs Mass/Momentum (Blunt)

Recommendation for implementing **cutting edge** for slash and **mass/momentum** for blunt in a way that matches real mechanics and keeps your deflection system unchanged.

---

## 1. Sharp / cutting: “edge” = effective contact width

**Physics:** Cutting and piercing are dominated by **pressure** (force per unit area). A sharper edge has a smaller effective contact area, so the same force produces higher pressure → deeper penetration and more severe cutting. So “sharpness” is best modeled as **effective contact width**, not a separate damage multiplier.

**Implementation:**

- Add per-weapon **effective edge width** (or a **sharpness** 0–1 that maps to it).
- Define **effective sharp contact** (cm) as:
  - Sharp blade: effective width ≤ geometric blade/point width (e.g. `effective_cm = geometric_cm / (0.2 + 0.8 * sharpness)` so sharpness 1 → geometric, sharpness 0 → 5× geometric).
  - Use a floor so effective width never goes below a minimum (e.g. `MIN_CONTACT_WIDTH_CM`).
- Use **effective sharp contact** everywhere the sharp component is evaluated:
  1. **Sharp penetration:** Already uses contact in `(baseline / contact)^α`. Use **effective** sharp contact instead of raw blade/point width. Sharper → smaller effective contact → higher pen_sharp → fewer deflects, deeper cuts.
  2. **Pre-armor cut damage:** Either:
     - **Option A (minimal):** Keep current single `pre_armor` and cut_ratio; add a **sharp damage factor** from effective contact: e.g. `pre_cut = pre_armor * cut_ratio * (baseline / effective_sharp_cm)^β` (capped), so sharper blades do more cut damage per Joule.
     - **Option B (fully physical):** Compute sharp and blunt pre-armor separately: `pre_cut` from KE and **effective sharp contact** (same style of contact factor as now); `pre_blunt` from **momentum** (see below). Then no single `pre_armor`; you split at the source.

**Deflection:** No change. You still pass `pen_sharp` and `pre_cut`; armor still compares `pen_sharp` to `sharp_resistance_rha_mm`. Dull blade → larger effective contact → lower `pen_sharp` → more deflects.

**Optional:** “Sharpness” can be a stat that degrades with use (durability), increasing effective edge width over time.

---

## 2. Blunt: momentum for damage, pressure for armor

**Physics:** Blunt trauma (contusion, fracture, behind-armor trauma) is driven by **momentum transfer** and **force** (F = Δp/Δt). Damage correlates better with **impulse/momentum** than with KE: a heavy, slow mace and a light, fast stick can have similar KE but the mace transfers more momentum and causes more concussion. So:

- **Pre-armor blunt damage** should scale with **momentum** (mass × velocity), not √(KE).
- **Armor “does it penetrate?”** is about **pressure** (force/area). So keeping blunt penetration as a pressure-like quantity (e.g. proportional to KE/area or to force/area) keeps armor resistance in MPa physically meaningful and avoids retuning every layer.

**Implementation:**

- **Pre-armor blunt (physics-accurate):**
  - `momentum = mass_kg * velocity_m_s`
  - `pre_blunt = DAMAGE_MOMENTUM_SCALE * momentum * strength_mod * arm_mod * contact_factor_blunt`
  - `contact_factor_blunt` can be 1.0 or a mild function of blunt contact (e.g. larger area → slightly less local concentration). Tune `DAMAGE_MOMENTUM_SCALE` so typical mace vs unarmored is in the same ballpark as now.
- **Blunt penetration (armor check):** Keep current **pressure** model:
  - `pen_blunt = BLUNT_PRESSURE_SCALE * KE / A_m²` (MPa), same as now.
  - So “does this blow penetrate or deflect?” stays pressure-based; armor `blunt_resistance_mpa` unchanged.
- **Cut ratio split:** You need a single “pre-armor” magnitude only for the sharp side if you keep one combined pre_armor for the sharp stream. So:
  - Either: keep `pre_armor = scale * sqrt(KE) * ...` for the **sharp** stream and split by cut_ratio to get `pre_cut`; then compute `pre_blunt` **separately** from momentum (so total pre-armor is no longer a single number; you have pre_cut and pre_blunt from two formulas).
  - Or: compute `pre_armor_total` for UI/deflection threshold only, but damage pools use `pre_cut` (KE + effective edge) and `pre_blunt` (momentum).

**Deflection:** No change. You still pass one `pen_blunt` (MPa) and one `pre_blunt`; armor still compares `pen_blunt` to `blunt_resistance_mpa` and applies transmission. Only the **source** of `pre_blunt` (momentum instead of KE split) changes.

---

## 3. Summary: most physics-accurate setup

| Quantity              | Current              | Most physics-accurate                          |
|-----------------------|----------------------|-----------------------------------------------|
| **Sharp contact**     | Geometric blade/point width | **Effective edge width** (from sharpness)     |
| **Sharp penetration** | KE + geometric contact | KE + **effective** sharp contact             |
| **Pre-armor cut**     | pre_armor × cut_ratio | KE × contact_factor(**effective** sharp) or sharpness factor |
| **Pre-armor blunt**   | pre_armor × (1 − cut_ratio) | **Momentum** × scale × strength × arm × contact_factor |
| **Blunt penetration** | KE / area (MPa)      | **Unchanged** (KE/area = pressure)            |
| **Deflection logic**  | pen vs res → transmit | **Unchanged**                                 |

So:

1. **Sharp:** Model edge as **effective contact width** (sharpness); use it for sharp penetration and for pre-armor cut magnitude. No change to deflection rules.
2. **Blunt:** Use **momentum** for pre-armor blunt damage; keep **pressure (KE/area)** for blunt penetration and existing deflection.

---

## 4. Optional: momentum-based blunt penetration

If you want blunt **penetration** to also reflect momentum (e.g. heavy mace “punches through” plate more in principle), you can define an effective pressure from impulse:

- `impulse_per_area = (mass_kg * velocity_m_s) / A_m²` in (kg·m/s)/m².
- Define `pen_blunt_mpa = K_IMPULSE_TO_MPA * impulse_per_area` and tune `K_IMPULSE_TO_MPA` so that:
  - Typical mace (e.g. 1.7 kg, 12 m/s, head 8 cm) gives a pen_blunt on the same order as now (e.g. ~10–15 MPa range), and
  - Armor `blunt_resistance_mpa` values still give the desired deflect/penetrate behavior.

Then armor resistance stays in MPa; only the **definition** of `pen_blunt` changes from “KE/area” to “momentum/area” with a constant. Deflection logic (compare pen to res, apply transmission) is unchanged.

---

## 5. Implementation order

1. **Effective sharp contact:** Add weapon sharpness (or effective_edge_width_cm). In `WeaponDamageHelper`, use it in `_get_sharp_contact_cm` (or a new helper) so sharp penetration and, if desired, pre-armor cut use it.
2. **Pre-armor blunt from momentum:** Add `compute_pre_armor_blunt(weapon, attack_instance, strength, arm_mod)` using `momentum = mass * velocity` and a new constant; in CombatManager, compute `pre_blunt` from this and `pre_cut` from existing (or adjusted) KE-based formula so cut_ratio only splits the **sharp** side, or compute both streams independently.
3. **Constants:** Add `DAMAGE_MOMENTUM_SCALE`, and optionally `K_IMPULSE_TO_MPA` if you switch blunt penetration to momentum/area. Tune so mace vs plate and mace vs leather feel right relative to swords.

This gives you the most physics-accurate method without changing how deflection works.
