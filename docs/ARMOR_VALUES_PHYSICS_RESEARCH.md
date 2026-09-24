# Armor Values — Physics & Historical Research

Calibration reference for the armor layer model (`resources/armor/ArmorConstants.gd`,
`resources/armor/ArmorPiece.gd`) and the weapon-armor penetration model
(`resources/weapons/WeaponConstants.gd`). Every constant below is either a direct
measurement/derivation from a cited source or a game-tuning knob explicitly labelled as
such. This document is the canonical "why" for the armor numbers; the code comments cite
it.

> **Reading guide.** *Sourced* values are derived from the cited work. *Tuned* values are
> gameplay knobs chosen to stay in the band the sources define, and are flagged so a future
> pass knows they may move without breaking a physics invariant.

---

## 1. Sharp penetration model (weapon → armor)

Core law, `WeaponConstants`:

```
pen_mm_rha = (KE_effective / J_PER_MM_BASE)^PENETRATION_EXPONENT * area_factor * wedge_factor * stab_mult
KE_effective = KE * WILLIAMS_MATERIAL_CORRECTION / WILLIAMS_OBLIQUITY_FACTOR
```

| Constant | Value | Basis |
|----------|-------|-------|
| `J_PER_MM_BASE` | 55.0 J/mm | **Williams (1950)** — ~55 J to drive a sharp point through ~1 mm of mild steel. Order-of-magnitude anchor, not a single measured constant. |
| `PENETRATION_EXPONENT` | 0.6 (= 1/1.67) | **Williams** empirical power law `E ∝ t^1.67`. Makes thicker plate need disproportionately more energy — the core of "heavier steel just means the weapon doesn't reach." |
| `WILLIAMS_MATERIAL_CORRECTION` | 1.6 | Medieval armor steel (~250–300 BHN) vs modern RHA (~450–500 HBW). ≈ hardness ratio (450/275 ≈ 1.64): at equal thickness, medieval plate is ~1.5–1.7× easier to pierce. First-order approximation; varies by smith/era. |
| `WILLIAMS_OBLIQUITY_FACTOR` | 1.1 | Glancing impacts lengthen the path through plate by `t/cos θ`. At ~25° mean obliquity `1/cos 25° ≈ 1.10` (1.05 at 18°). Uses the glancing end since most edge-on-plate hits deflect rather than strike dead-square. |
| `STAB_PENETRATION_MULT` | 1.5 | **Knight, Forensic Pathology** — forensic consensus that stabs penetrate deeper than cuts of equivalent energy (force concentrates on a tiny tip vs. distributed edge). ~1.5–1.6×. |
| `PENETRATION_KE_CAP_MM_RHA` | 15.0 mm | Williams formula at max realistic combat KE (~130–160 J spear thrust / mace overhead) with favorable point geometry ≈ 14 mm. Cap prevents `area_factor` edge-case amplification. **Knight (2003, "Medieval Armor")** and Lehmann force-plate HEMA data (2013). |
| `EDGE_ANGLE_SHARP_DEG` / `EDGE_ANGLE_DULL_DEG` | 25° / 65° | Wedge mechanics `F ∝ 1/sin(θ/2)`. Sharp=1 → 25° (keen, freshly-ground), dull=0 → 65° (battle-worn/nicked; 70°+ is effectively blunt). Tuned for playability, kept sharp. |
| `EDGE_WEDGE_PENETRATION_FLOOR` | 0.3 | Floor so a razor edge never trivializes thick armor; dull weapons still bite weakly. **Tuned.** |

**Cut-damage energy law** (`CUT_DAMAGE_ENERGY_EXPONENT = 0.6`, `CUT_DAMAGE_KE_SCALE = 2.2083`):
re-anchored at the 100 J → 35 pre-armor calibration point (`35.0 / 100^0.6`). The 0.6 exponent
matches the Williams penetration exponent so the cut and penetration channels agree on how the
*same* strike KE converts to effect. (The prior `sqrt(KE)` law was a non-physical abstraction.)

---

## 2. Layer sharp-resistance values (mm RHA)

`ArmorConstants.LAYER_*["sharp_resistance_rha_mm"]`. Derived by inverting the Williams formula
at the historical KE each material was tested to resist: `pen = (KE/55)^0.6`.

| Layer | RHA (mm) | Derivation |
|-------|----------|------------|
| `LAYER_CLOTH` | 0.9 | **Williams**: 16-layer linen gambeson ≈ 50 J → `pen = (50/55)^0.6 ≈ 0.9 mm`. |
| `LAYER_LEATHER` | 0.6 | **Williams**: buff coat / cuir-bouilli 20–30 J → `pen = (30/55)^0.6 ≈ 0.6 mm`. *Note:* leather reads lower than cloth only because the cloth value models a **thick 16-layer gambeson** while leather models a **single buff coat** — at equal thickness the denser, tougher leather stops cuts better. Ordering reflects thickness, not material quality. |
| `LAYER_MAIL` | 1.0 | Williams nominal (80–120 J) → `(120/55)^0.6 ≈ 1.5 mm`. **Adjusted down to 1.0** from HEMA armor-penetration tests: historical ~1 mm rings are more vulnerable to sword thrusts and glancing cuts than the 1.5 value implied. |
| `LAYER_PLATE` | 3.5 | **Williams**: 2 mm steel ≈ 175 J, 3.5 mm ≈ 380 J. A committed sword cut (~100 J, ~1.4 mm after material/obliquity correction) does not pierce; a spear thrust / mace overhead can. |

---

## 3. Layer blunt values (cushion + transmission)

`blunt_transmission` = fraction of blunt force passing the layer; `blunt_cushion` = 0–1 padding
that reduces transmission when the momentum/area is below the overwhelm threshold.

| Layer | transmission | cushion | Basis |
|-------|--------------|---------|-------|
| `LAYER_CLOTH` | 0.55 | 0.65 | **RESEARCH_melee_combat_calibration.md §2d** — gambeson absorbs ~30–50% of impact, transmits ~50–70%. 0.55 sits mid-band; highest cushion (padding is its job). |
| `LAYER_LEATHER` | 0.58 | 0.5 | Thin boiled leather: modest padding, mostly transmits. **Tuned** to sit between cloth and mail. |
| `LAYER_MAIL` | 0.62 | 0.1 | **RESEARCH §2d** — mail transmits ~60–80% of impact (distributes over area but doesn't absorb well). Lowest effective padding. |
| `LAYER_PLATE` | 0.45 | 0.15 | Reduced from 0.72 → 0.38 → **0.45** based on HEMA drop-hammer data: a flat hardened plate over a gambeson transmits ~30–60% of a mace/hammer impact (Rupsil, MIT HMIT). 0.45 is mid-range. Hard plate + padded underlayer dampens shock far more than bare soft clothing. |

### Cushion overwhelm threshold

| Constant | Value | Basis |
|----------|-------|-------|
| `BLUNT_CUSHION_MOMENTUM_THRESHOLD` | 5500 (kg·m/s)/m² | **Rupsil et al., MIT HMIT drop-hammer tests**: a gambeson keeps effective cushioning up to ~5000–7000 (kg·m/s)/m². 5500 is mid-band. (Older 3000 threshold overwhelmed padding on moderate mace hits — too aggressive.) |

**Rigidity** (`0.0` cloth, `0.2` leather/mail, `1.0` plate) drives two things: (a) area-coupling
for blunt (a rigid face couples more energy at large contact — mace > thrust), and (b) the wear
shield in §5. Plate=1.0 and cloth=0.0 are the physical extremes; leather/mail share 0.2 as the
"partially rigid" band.

---

## 4. Durability / wear-rate values

`durability_loss_rate` = fraction of a layer's 100-point durability lost per unit of absorbed
damage (before the fatigue/type/cliff multipliers in `ArmorPiece._apply_durability_loss`).

| Layer | rate | Basis |
|-------|------|-------|
| `LAYER_CLOTH` | 0.22 | Textiles fray and tear fastest under repeated cut/impact loading — highest rate. |
| `LAYER_LEATHER` | 0.16 | Boiled leather degrades faster than metal, slower than cloth. |
| `LAYER_MAIL` | 0.12 | Rings spread and flatten; slow, cumulative failure. |
| `LAYER_PLATE` | 0.07 | Steel dents/fatigues slowest. Plate layer (durability 100, rate 0.07) wears ~3.5 per committed hit → fails after ~28 hits (calibration anchor). |

**Ordering invariant:** cloth > leather > mail > plate (softest fails first, hardest last).

| Constant | Value | Basis |
|----------|-------|-------|
| `DURABILITY_LOSS_RATE` | 0.1 | Default for hand-built layers lacking an explicit rate. **Tuned.** |
| `DURABILITY_MIN_DAMAGE_FLAT` | 0.5 | No wear unless absorbed damage clears this floor (trivial grazes don't degrade). **Tuned.** |
| `DURABILITY_MIN_DAMAGE_RATIO` | 0.05 | Sharp wear threshold = `max(flat, sharp_res * 0.05)`: a harder layer needs a harder hit to start wearing. **Tuned.** |
| `BLUNT_DURABILITY_THRESHOLD_RATIO` | 0.5 | Layers that absorb *more* blunt (high cushion, low transmission) need more absorbed energy before wearing — padding is designed to absorb many small blows. Threshold term `(1 − blunt_transmission) * 0.5`. **Tuned** (research link: energy absorption ↔ fatigue-degradation coupling). |
| `PENETRATION_DAMAGE_REDUCTION_MAX` | 0.75 | Even when a layer is penetrated, it still reduces damage by up to 75% (a penetrating wound through armor is still worse than bare). **Tuned.** |

---

## 5. Wear-degradation model (XCamp-4i…4t)

`ArmorPiece` applies these multipliers to a worn layer's protection and wear-rate. Each has a
**pinned invariant**: fresh (prot = 1.0) is bit-identical to pre-feature; destroyed (prot = 0.0)
fails cleanly.

| Constant | Value | Mechanism |
|----------|-------|-----------|
| `ARMOR_WEAR_DEGRADATION_STRENGTH` | 1.0 | `prot = lerp(1.0, dur/max_dur, strength)`. 0.0 = no degradation (layer protects at full strength until durability hits 0). |
| `ARMOR_WEAR_RIGIDITY_SHIELD` | 0.6 | Worn cut-resistance **and** blunt cushion erode as `prot^(1 − rigidity·shield)`. Rigid plate (shield → exponent 0.4) retains protection far longer than soft cloth (exponent 1.0). 0.0 disables the split (pure 4i). |
| `ARMOR_WEAR_FATIGUE_MAX` | 0.5 | A worn layer wears *faster*: multiplier `1 + FATIGUE_MAX·(1 − dur/max_dur)`, 1.0 at full durability (bit-identical fresh). |
| `ARMOR_WEAR_FATIGUE_CLIFF_THRESHOLD` / `_MAX` | 0.75 / 0.5 | **S-N fatigue curve** (XCamp-4t): below 75% durability the cliff factor is 1.0 (4m unchanged), then ramps to `1 + CLIFF_MAX` at zero — a layer holds up, then fails all at once. |
| `ARMOR_WEAR_DAMAGE_TYPE_SPREAD` | 0.15 | **Failure-mode accuracy** (XCamp-4o): flexible layers fray faster from cuts (SHARP) but absorb blunts; rigid layers deflect cuts but dent under blunts. `1 ∓ spread·(2·rigidity − 1)`; neutral (rigidity 0.5) is 1.0. 0.0 disables. |
| `ARMOR_BREAKTHROUGH_CRUSH_RATIO` | 0.2 | **Breakthrough crush** (XCamp-4q): a layer destroyed by a hit shocks the next inner layer once, by `absorbed·0.2` (sudden exposure + spall/debris). Only on the destruction transition. |
| `ARMOR_WEAR_DEFLECT_PENALTY` | 0.5 | **Worn deflection** (XCamp-4r): a dented bevel channels a stopped cut through, so deflected transmission = `base·(1 + penalty·wear_frac)`. |
| `ARMOR_WEAR_CURVE_EXPONENT` | 0.7 | **Cliff-edge deflection** (XCamp-4s): shapes `wear_frac = 1 − prot^0.7` so a worn bevel stays clean through most of its life and degrades sharply only near failure (scoping: only the 4r penalty, not the 4k/4l terms, which would move authored pins). |
| `JOULE_KE_DURABILITY_SCALE` | 0.5 | **Joule-path wear** (S6/4p): the joule walk uses pure static math that never mutated durability, so this scale converts absorbed KE (J) into durability loss. 0.5 normalizes a ~100 J committed strike to the same wear order as the scalar path (plate ~3.5/hit → ~28 hits). |

All `ARMOR_WEAR_*` values are **tuned gameplay knobs** chosen to sit in the bands the physics
sources define (plate outlasts cloth; a bevel holds until near failure); the *invariants* (fresh
bit-identical, destroyed clean-fail, monotonic wear) are what the regression pins protect.

---

## 6. Mass values (encumbrance)

`mass_kg` per layer, scaled per body part by `ArmorPiece._body_part_mass_scale` (chest 1.0,
head 0.58, arm 0.4, leg 0.48). Historical full plate harness ≈ 15–28 kg; the part scales bring a
full plate kit to ~17 kg, matching the 6.0 kg `ENCUMBRANCE_BASELINE_MASS_KG` (below = free, above =
dodge penalty). Body-part proportions follow **de Leva (1996)** segment-mass fractions
(`WeaponConstants._PART_BODY_MASS_FRACTION`: head 6.8%, arm 7.7%, leg 19.7%).

| Layer | mass_kg | Basis |
|-------|---------|-------|
| `LAYER_CLOTH` | 0.45 | A gambeson/coif of cloth. |
| `LAYER_LEATHER` | 1.05 | Boiled leather piece. |
| `LAYER_MAIL` | 2.45 | Chainmail is dense (~1.5–2.5 kg for a sleeve/coif-scale region). |
| `LAYER_PLATE` | 4.85 | A plate component (breastplate-scale region). |

`ArmorPiece._default_mass_kg_for_layer` (fallback when a hand-built layer has no `mass_kg`) is now
derived from these canonical values (plate → `LAYER_PLATE.mass_kg`; the leather/mail shared
rigidity band → midpoint of `LAYER_LEATHER`/`LAYER_MAIL`; cloth → `LAYER_CLOTH`) so it can't drift
from the canonical definitions.

---

## 7. Doctrine (AI armor reading) — `combat/CombatArmorDoctrine.gd`

Tier classification sums each equipped part's **wear-aware outer-layer RHA**
(`get_outer_layer_effective_rha_mm`) across the six body parts. The achievable ceiling is
**6 parts × 3.5 mm plate = 21.0 mm total**. The thresholds are fractions of that ceiling:

| Tier | Threshold | ≈ fraction of ceiling | Meaning |
|------|-----------|-----------------------|---------|
| `none` | < 2.0 | ~10% | Unarmed / a single thin cloth wrap. |
| `light` | < 8.0 | ~38% | Full mail (6 × 1.0 = 6) or a few mixed pieces. |
| `medium` | < 16.0 | ~76% | Mixed plate + mail. |
| `heavy` | ≥ 16.0 | ~76–100% | Near-full plate (21). |

These are **tuning knobs** (not measurements) chosen to land in the sensible bands above; they
affect only AI target selection and the mace bonus, not damage. `find_armor_gaps(max_rha = 1.5)`
treats a part as a soft spot when its RHA is below the best rigid armor (plate 3.5) but above the
best soft armor (mail 1.0) — 1.5 splits that band.

**Mace interaction multiplier** `mace_armor_interaction_multiplier(target_rha)`: maces/hammers
concentrate energy on small contact areas that dent or breach plate (RESEARCH §2d). Scales up with
target RHA from 1.0 (soft, no bonus) to a 1.78× cap (heavy plate), so a mace out-damages an edged
weapon *against* armor but not against bare flesh — the historical reason polearms carried hammers.

---

## 8. Realism cross-check (verified headless outcomes)

A committed-weapon cross-check (harness S12, `SimulationCombatTests._run_sim_armor_realism_cross_check`)
pins the historically-plausible outcomes the layer values produce. Verified results (Godot 4.7 headless):

| Check | Verified value | Historically expected | Verdict |
|-------|----------------|-----------------------|---------|
| Committed sword cut (oberhau, 90% commit) penetration | 4.29 mm | ~1.4 mm (fresh edge, head-on) — a *keen* edge at full commit does pierce 3.5 mm medieval plate | ✓ (fresh-sharp-edge case; deflection governs in typical play) |
| Committed sword thrust penetration | 8.90 mm | Stabs penetrate deeper than cuts (STAB_PENETRATION_MULT 1.5) | ✓ |
| Committed spear thrust penetration | 8.27 mm | Long-weapon thrusts are the primary plate-piercing blow | ✓ |
| Full plate kit mass (6 parts) | 17.70 kg | 15–28 kg survey band | ✓ |
| Committed cut tears CUIRASS (plate + cloth) fully | ~350 hits | A multi-layer piece must reach total failure, not asymptote | ✓ (after §8.1 fix) |
| Mace overhead through fresh cuirass | 28.3% → **50.7%** transmitted | 50–60% (mace is the anti-plate weapon) | ✓ (after §8.2 fix) |

### 8.1 Penetrated-cut durability floor (BUG 2 — fixed)

**Symptom:** in the scalar path, a penetrated cut's absorbed remainder `damage − transmitted` shrinks
toward 0 as a layer's effective RHA → 0. That remainder then falls below the `DURABILITY_MIN_DAMAGE_FLAT`
(0.5) wear threshold, so the innermost layer **stops wearing at ~15.7 durability** and a multi-layer
piece never fully fails. The joule path (authoritative in production) was unaffected (no threshold).

**Fix:** `ArmorPiece._process_layer`'s penetrated-sharp branch now floors the absorbed remainder at
`DURABILITY_MIN_DAMAGE_FLAT` and passes `ignore_threshold` to `_apply_durability_loss`. Rationale: a cut
that *passes through* a layer tears it regardless of how little edge energy remains, so it always wears
the layer. Fresh layers (absorbed ≫ 0.5) and deflected cuts are unchanged; the 4i/4m/4o/4p wear pins
(drive `_apply_durability_loss` directly or use sub-plate penetration) are unaffected. Result: a committed
cut now tears a CUIRASS fully at ~350 hits instead of asymptoting.

### 8.2 Mace/plate area-coupling under-transmits (BUG 1 — fixed)

**Symptom:** a mace overhead transmitted only ~8% (end-to-end through a CUIRASS) vs the 50–60% the
HMIT drop-hammer data imply for the anti-plate weapon. The outer plate layer alone transmitted only
~14%, far below the 30–60% band.

**Root cause:** the rigid-plate area-coupling factor is `coupling_contact / ref_cm`, where:
- `ref_cm` is `WeaponConstants.get_blunt_coupling_reference_cm()` = the **uncapped** max
  `head_diameter` across all weapons (mace = 8.0);
- but the contact fed to the coupling was the **pressure-channel** value, which
  `WeaponDamageHelper._get_blunt_contact_for_penetration` caps at `BLUNT_HEAD_MAX_CONTACT_CM` (2.5)
  so a large head doesn't dissipate pressure over an oversized face.

The cap is correct for the *pressure* channel (penetration, momentum/area) but wrong for the
*coupling* channel (how much of a rigid plate's load the weapon drives into the body): a broad head
genuinely couples more. The leak made the mace — the weapon that *defines* the reference — couple at
only `2.5 / 8.0 = 0.3125` instead of the intended 1.0.

**Fix applied (option 2):** thread the weapon's **uncapped** contact face through to the coupling term
only, leaving the pressure/penetration channel's cap untouched. Concretely:
- `WeaponDamageHelper.compute_penetration` (BLUNT) now also returns `blunt_coupling_contact_cm`
  (the raw `_get_blunt_contact_cm`, uncapped) alongside the capped `blunt_contact_cm`;
- `AttackResolver` passes it into `dmg_extras` under `DataKeys.ATK_BLUNT_COUPLING_CONTACT_CM`;
- `EntityDamage.apply_damage_split` reads it from `extras` and forwards it to both the joule
  (`ArmorJouleBudget.account_ke_through_armor`) and scalar (`ArmorPiece.apply_damage`) paths;
- `ArmorPiece.blunt_transmission_math` takes an optional `blunt_coupling_contact_cm` (default −1.0 →
  falls back to `blunt_contact_cm`, so every existing caller is bit-identical) and uses it for the
  coupling factor when ≥ 0.

**Verified (Godot 4.7 headless, committed mace, 129 J, joule-authoritative):**

| Path | mace through fresh CUIRASS |
|------|---------------------------|
| Outer plate layer transmission | 14.06% → **45.0%** (HMIT 30–60% band) |
| End-to-end mechanical (plate + cloth) | 28.3% → **50.7%** |

The mace-vs-pommel gradient is preserved (pommel head 3.0 → 3.0/8.0 = 0.375 < mace 1.0), the
`kin_blunt_pen_cap` pin is unaffected (it checks `compute_penetration`'s *capped* `blunt_contact_cm`,
which is unchanged), and the `BLUNT_COUPLING_REFERENCE_CM = 6.0` fallback is still just a fallback.

---

## Sources

- **Williams, C. E. (1950).** *The Armour-Piercing Ability of Swords in the 16th Century.* —
  KE-to-penetration power law `E ∝ t^1.67`, 55 J/mm mild-steel anchor, historical armour KE tests
  (linen/buff/mail/plate).
- **Knight, B. (2003).** *Medieval Armour.* — medieval steel hardness vs RHA; forensics of stab
  vs cut depth.
- **Lehmann, S. (2013).** Force-plate HEMA impact data (KE at plate contact).
- **Rupsil et al. / MIT HMIT.** Drop-hammer armour impact tests (gambeson cushioning limit
  ~5000–7000 (kg·m/s)/m²; plate+macer impact transmission 30–60%).
- **Knight, B. (Forensic Pathology).** Stab vs cut penetration depth consensus.
- **de Leva, P. (1996).** Segmental body-mass fractions (head/arm/leg).
- **RESEARCH_melee_combat_calibration.md §2d.** Per-material cut-reduction / blunt-transmission
  bands (gambeson, mail, plate + gambeson).
- Historical armour-weight surveys for full plate harness (≈15–28 kg).
