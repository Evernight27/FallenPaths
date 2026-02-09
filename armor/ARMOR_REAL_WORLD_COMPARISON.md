# Armor Constants vs Real-World Comparison

Summary of real-world data and how your **ArmorConstants** values compare. Your game uses **sharp resistance (mm RHA equivalent)** and **blunt resistance (MPa)** plus **durability loss rate**; real life doesn’t use these units directly, so the comparison is approximate.

---

## 1. Real-World Data (Summary)

### Plate thickness and RHA equivalence

- **Physical thickness (medieval plate):**
  - Breastplates: ~**2.5–4.5 mm** typical (infantry ~2.5 mm, cavalry ~3.8 mm).
  - Limb/helmet: often **0.5–2 mm**, good pieces up to ~3 mm.
  - So plate was **thin** by modern standards (not 5–20 mm; that’s a common myth).

- **Quality vs “RHA equivalent”:**
  - Medieval steel varied a lot. *The Knight and the Blast Furnace* (Williams) gives effectiveness as **% of modern mild steel**: wrought iron ~**50%**, low steel ~**75%**, good armor steel (e.g. Milanese) ~**110%**, best hardened ~**150%**.
  - So **2.5 mm good steel** ≈ **2.75 mm “mild steel equivalent”** (2.5 × 1.1); **2 mm poor iron** ≈ **1 mm** equivalent.
  - Realistic **sharp resistance in “mm RHA equivalent”** for typical plate is roughly **~1–4 mm** (thickness × quality factor), not 8–12 mm.

- **What actually penetrated:**
  - Swords/spears: **did not** penetrate sound plate; blades could not cut through.
  - Arrows: strong longbow (e.g. 140 lb) could **dent** plate; at close range (e.g. 65 ft) bodkins could puncture **thin** plate in tests; at 260 ft only denting.
  - So “penetration” in game terms should be **low** vs good plate (1–4 mm RHA equivalent fits “hard to pierce with period weapons”).

### Mail (chainmail)

- **Vs cutting:** Very good; slashing generally did **not** cut through riveted mail.
- **Vs piercing:** Bodkins could penetrate depending on ring type, riveting, and padding; even then, padding often limited depth.
- **Vs blunt:** Poor; impact still caused **bruising and fractures** through the mail. So mail is “good sharp, bad blunt” in real life too.

### Gambeson / padding

- **Construction:** Often **15–30 layers** of cloth (linen/wool/cotton), quilted; sometimes stuffed with cloth/horsehair.
- **Role:** Cushioned blows, reduced behind-armor trauma, helped deflect arrows at range; worn alone by poorer troops or under mail/plate.
- **Vs projectiles:** Buff-coat–style tests gave **V50 ~102 m/s**—meaningful protection only at lower velocities / longer range.
- **Vs blunt:** Described as softening impact and distributing force; no standard “MPa” number in literature—your **25 MPa** is a game scaling choice and is fine as “good blunt absorption” relative to mail.

### Durability and maintenance (real life)

- Armor suffered **wear and tear** (rust, leather drying, rivets loosening, dents); **maintenance** (cleaning, oiling, conditioning) was important.
- Well-maintained plate could last **generations**; combat caused “extreme wear and tear” but not “one hit = 10% gone.”
- So real “durability” is **long-term degradation and maintenance**, not a literal HP bar. Your **durability_loss_rate** is an **abstraction**: each hit that is absorbed chips away at the armor. Making **cloth/leather lose durability faster than plate** (your 0.2 vs 0.08) matches the idea that fabric tears and leather degrades faster than metal.

---

## 2. Your Values vs Real Life

| Layer            | Your sharp (mm RHA) | Your blunt (MPa) | Your durability loss | Real-world comparison |
|------------------|----------------------|------------------|----------------------|------------------------|
| **Steel plate**  | 12                   | 45               | 0.08                 | **Sharp too high.** Real plate ~1–4 mm RHA equivalent. 12 mm makes plate almost impenetrable by period weapons. Blunt 45 MPa is a reasonable “very good” for plate. |
| **Iron plate**   | 8                    | 35               | 0.10                 | **Sharp high.** Real wrought/iron plate ~0.5–2× mild steel, so more like ~2–5 mm equivalent. 8 mm is still strong. |
| **Mail**         | 5                    | 15               | 0.12                 | **Reasonable.** Good vs cut (5 mm), poor vs blunt (15) matches “stops slash, blunt goes through.” |
| **Gambeson**     | 2                    | 25               | 0.15                 | **Reasonable.** Low sharp (2) fits “cloth doesn’t stop focused points well”; high blunt (25) fits “good cushioning.” |
| **Padding**      | 1                    | 18               | 0.18                 | **Reasonable.** Softer than gambeson, degrades faster. |
| **Cloth**        | 0.5                  | 5                | 0.20                 | **Reasonable.** Minimal protection, fastest wear. |

**Summary:**  
- **Sharp (mm RHA):** Your **plate values (8–12 mm)** are **above** real-life equivalence (roughly 1–4 mm). Mail/gambeson/padding/cloth are in a plausible range.  
- **Blunt (MPa):** Ordering (plate > gambeson > padding > mail > cloth) and relative sizes look fine; no direct real-world MPa data to match.  
- **Durability loss:** Steel < iron < mail < gambeson < padding < cloth is **realistic** (metal lasts, cloth wears fast).

---

## 3. Optional Tuning for “More Realistic” Plate

If you want plate to sit closer to historical penetration data (swords/spears don’t pierce, but strong arrows at close range can):

- **Steel plate:** e.g. **sharp_resistance_rha_mm** **3–5** (instead of 12). Keeps plate strong vs typical melee, allows very high penetration (e.g. strong bows, polearms) to matter.
- **Iron plate:** e.g. **2–4** (instead of 8).

Then keep **default weapon penetration** (e.g. 5 mm sharp) so that:
- Unarmored / cloth: easily wounded.
- Mail: good protection vs slash, weak vs blunt.
- Plate: strong vs most attacks; only high-penetration or repeated hits get through.

Your **blunt** and **durability_loss_rate** values can stay as they are; they already match the idea that plate is tough, cloth tears, and mail is in between.

---

## 4. References (high level)

- Medieval plate thickness: ~0.5–4.5 mm by piece; breastplates 2.5–4.5 mm typical.  
- RHA / “mild steel equivalent”: *The Knight and the Blast Furnace* (Williams); effectiveness ~50–150% of mild steel by quality.  
- Arrow vs plate: e.g. longbow tests (denting at 260 ft, puncture at 65 ft on thin plate); energy figures ~55–175 J for 1–2 mm mild steel.  
- Mail: good vs slashing; bodkins can penetrate; blunt trauma through mail (bruising/fractures).  
- Gambeson: 15–30 layers, cushioning, V50 ~102 m/s for buff-coat–style tests.  
- Durability: real armor = maintenance and long-term wear, not per-strike HP; your rates are a reasonable abstraction.

---

## 5. Generic Layers (Current: cloth, leather, mail, plate only)

Armor uses **four generic layers** with physics- and research-aligned values. See **ARMOR_VALUES_PHYSICS_RESEARCH.md** for full rationale and sources.

| Layer   | Sharp (mm RHA) | Blunt (MPa) | Deflection trans. | Durability loss | Notes |
|---------|----------------|-------------|-------------------|-----------------|--------|
| **Cloth**   | 0.5 | 16 | 0.16 | 0.22 | Minimal vs sharp; gambeson cushions well (BAT); tears fastest. |
| **Leather** | 1.0 | 14 | 0.24 | 0.16 | Buff ~30 J, layered ~80 J; good blunt absorption. |
| **Mail**    | 1.5 | 10 | 0.36 | 0.12 | 100–120 J with padding (1.5×80 J); poor vs blunt (trauma). |
| **Plate**   | 3.5 | 40 | 0.46 | 0.07 | ~1–4 mm RHA; rigid → higher BAT; best blunt dispersion. |

Piece IDs use these layers only: e.g. `CUIRASS` = plate + cloth, `HAUBERK` = mail + cloth, `GAMBESON` = cloth, `LEATHER_BRACERS` = leather.
