# Armor Values: Physics and Research Alignment

Investigation of each material’s values (sharp resistance, blunt resistance, deflection transmission, durability loss) and alignment with realistic physics and literature. **Weapon penetration** uses `J_PER_MM_RHA = 80` (WeaponConstants), so energy to penetrate a layer ≈ `sharp_resistance_rha_mm × 80` joules.

---

## 1. Sharp resistance (mm RHA equivalent)

**Meaning:** Penetration (mm RHA) from the weapon is compared to this value. If pen &lt; resistance, the layer stops the sharp (deflection path). If pen ≥ resistance, the layer is penetrated and damage is reduced.

**Real-world basis:** “mm RHA equivalent” encodes material and thickness. Literature often gives **energy to penetrate** (J); with 55–80 J/mm mild steel, resistance in mm = energy / J_per_mm.

| Material | Previous | Research / physics | J to penetrate (at 80 J/mm) | Updated | Notes |
|----------|----------|--------------------|-----------------------------|---------|--------|
| **Cloth** | 0.5 | Thin cloth/gambeson minimal vs point; 30-layer jack withstood ~200 J slash; single-layer ~27–40 J. [ArmStreet, buff-coat tests] | 40 J | **0.5** | Keep. Minimal vs focused penetration. |
| **Leather** | 1.0 | Buff leather “~30 J to penetrate” → ~0.37–0.55 mm at 55 J/mm; boiled/layered better. [Williams, A Commonplace Book] | 55–80 J | **1.0** | Keep. 1.0 mm = 80 J for layered/boiled. |
| **Mail** | 2.0 | **100–120 J** to defeat mail + padding; bodkin + 120 lb bow ~95 J through padding + mail. [Alan Williams, Pope tests] | 100–120 J → 1.25–1.5 mm | **1.5** | Lower from 2.0 so 1.5×80 = 120 J. Matches “mail+padding” band. |
| **Plate** | 3.5 | Medieval plate ~1–4 mm RHA equiv; 2.5 mm good steel ≈ 2.75 mm mild. Strong longbow can puncture thin plate at close range. [Williams, thickness mapping] | 200–320 J | **3.5** | Keep. 3.5×80 = 280 J, in “good plate” range. |

**Summary:** Only **mail** is changed (2.0 → 1.5 mm) so that penetration energy aligns with 100–120 J literature. Cloth, leather, plate unchanged.

---

## 2. Blunt resistance (MPa)

**Meaning:** When damage is blunt (or deflected sharp→blunt), each layer reduces it by comparing blunt penetration (pressure-like, in MPa) to this resistance. **No direct medieval MPa data**; ordering and relative magnitudes are from qualitative literature.

**Real-world basis:** Plate disperses impact over area (best); gambeson/padding cushions (good); mail is poor vs blunt (trauma transmitted); thin cloth minimal.

| Material | Previous | Research / physics | Updated | Notes |
|----------|----------|--------------------|---------|--------|
| **Cloth** | 8 | Gambeson/buff “cushioned blows,” “mitigated behind-armor blunt trauma.” [Buff-coat study, gambeson role] | **16** | Raise so gambeson-style cloth clearly cushions better than mail (mail poor vs blunt). |
| **Leather** | 14 | Between cloth and metal; some absorption. | **14** | Keep. |
| **Mail** | 10 | “Poor vs blunt”; “impact caused bruising and fractures through the mail.” [Williams, mail trauma] | **10** | Keep. Lowest among armors. |
| **Plate** | 40 | Best dispersion; rigid surface spreads load. | **40** | Keep. |

**Summary:** **Cloth** raised 8 → 16 so that cloth (as gambeson) has clearly better blunt absorption than mail, matching “gambeson cushions / mail transmits trauma.”

---

## 3. Deflection transmission (0–1)

**Meaning:** When sharp **fails to penetrate** (deflection), this fraction of the damage at that layer becomes blunt and is then run through all layers’ blunt resistance. Higher = more force transferred to the body (worse for wearer).

**Real-world basis:** Behind-armor blunt trauma (BAT): rigid plate transmits more; soft padding absorbs more. Ordering: plate &gt; mail &gt; leather &gt; cloth.

| Material | Previous | Research / physics | Updated | Notes |
|----------|----------|--------------------|---------|--------|
| **Cloth** | 0.18 | Multi-layer cloth/gambeson “mitigated behind-armor blunt trauma”; best absorption. | **0.16** | Slightly lower: more energy absorbed when cloth stops the blade. |
| **Leather** | 0.25 | Softer than metal; absorbs more than plate/mail. | **0.24** | Keep. |
| **Mail** | 0.35 | Spreads load but metal still transmits; between plate and padding. | **0.36** | Keep. |
| **Plate** | 0.45 | Rigid; well-documented BAT with hard plates. High transmission. | **0.46** | Slightly higher: rigid plate transmits more. |

**Summary:** Small tweaks for consistency: cloth 0.18→0.16, plate 0.45→0.46. Ordering and realism (plate worst, cloth best for wearer) unchanged.

---

## 4. Durability loss rate (per damage absorbed)

**Meaning:** When a layer absorbs damage above the minimum threshold, its durability decreases by `damage_absorbed × durability_loss_rate`. Real life: fabric tears and degrades fastest; leather dries/cracks; mail links and rivets wear; plate dents but lasts.

| Material | Previous | Research / physics | Updated | Notes |
|----------|----------|--------------------|---------|--------|
| **Cloth** | 0.20 | Tears, cuts, abrasion; fastest wear. | **0.22** | Slightly higher: fabric fails soonest. |
| **Leather** | 0.15 | Dries, cracks, cuts; between cloth and metal. | **0.16** | Slight increase. |
| **Mail** | 0.12 | Links can break or pop; rivets loosen; “extreme wear” in combat. | **0.12** | Keep. |
| **Plate** | 0.08 | Dents, scratches; “could last generations” with maintenance. | **0.07** | Slightly lower: metal most durable. |

**Summary:** Cloth 0.20→0.22, leather 0.15→0.16, plate 0.08→0.07. Mail unchanged. Ordering cloth &gt; leather &gt; mail &gt; plate preserved.

---

## 5. Per–armor piece consistency

All pieces use the same four layer types (cloth, leather, mail, plate). No piece-specific overrides are applied; realism is via layer choice and order:

- **Plate + cloth** (cuirass, helm, vambraces, greaves): outer plate stops sharp/blunt first; inner cloth cushions deflected blunt. Matches historical layering.
- **Mail + cloth** (hauberk): mail stops slash; cloth cushions. Mail’s low blunt resistance (10) reflects “trauma through mail.”
- **Cloth only** (gambeson, coif, wraps): single layer; cloth’s raised blunt (16) and low transmission (0.16) reflect gambeson’s cushioning role.
- **Leather only** (cap, bracers, greaves): single layer; leather values unchanged except durability.

No changes to piece definitions (which layers they use); only the shared layer constants are updated.

---

## 6. Summary of value changes

| Layer   | Sharp (mm) | Blunt (MPa) | Deflection trans. | Durability rate |
|---------|------------|------------|-------------------|------------------|
| Cloth   | 0.5 (keep) | 8 → **16**  | 0.18 → **0.16**   | 0.20 → **0.22**  |
| Leather | 1.0 (keep) | 14 (keep)  | 0.25 → **0.24**   | 0.15 → **0.16**  |
| Mail    | 2.0 → **1.5** | 10 (keep) | 0.35 → **0.36**   | 0.12 (keep)      |
| Plate   | 3.5 (keep) | 40 (keep)  | 0.45 → **0.46**   | 0.08 → **0.07**  |

These keep the same gameplay ordering (plate best vs sharp and blunt, cloth worst vs sharp but good vs blunt) while aligning numbers with penetration energy (mail 100–120 J), cushioning (cloth/gambeson), and BAT/durability literature.
