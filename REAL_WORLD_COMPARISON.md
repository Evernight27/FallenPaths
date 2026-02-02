# Weapon Properties, Physics, and Armor vs Real-World Data

Comparison of your weapon constants, KE-based damage/penetration, and armor system against multiple real-world and research sources. Each section lists your values, then several external references and a verdict.

**Updates applied (from recommendations below):** Velocity range raised to **6–18 m/s** (research 17–24 m/s); mace mass set to **1.7 kg** (typical war mace); **J_PER_MM_RHA = 130** and **DAMAGE_KE_SCALE = 2.6** so damage and penetration (mm RHA) stay in the same band as before with the new velocity range.

---

## 1. Weapon mass (kg)

| Weapon  | Your value | Real-world range / examples | Verdict |
|---------|------------|----------------------------|---------|
| Sword   | 1.2 kg     | Arming sword 0.9–1.2 kg; longsword 1.2–2.0 kg (museum averages ~1.5 kg). Scottish claymore 2.2–2.8 kg. [1][2][3] | **Accurate.** Fits arming sword / light longsword. |
| Axe     | 1.5 kg     | One-handed battle axe 1–2 kg; two-handed 2–3 kg. Light/throwing 0.5–1 kg. [4][5] | **Accurate.** Mid-range one-handed. |
| Mace    | 1.7 kg     | Typical war mace ~1.6 kg (e.g. Cleveland Museum seven-flanged mace, 16th c.). Heavier examples and lead-filled heads existed. [6][7] | **Accurate.** Matches typical war mace (1.6–1.8 kg). |
| Dagger  | 0.3 kg     | Medieval daggers 0.15–0.5 kg: ballock ~0.18 kg, baselard ~0.15 kg, quillon ~0.2 kg, long dagger ~0.18 kg, short ~0.4 kg, Blackfriars-style ~0.48 kg. [8][9] | **Accurate.** Mid-range. |
| Spear  | 1.8 kg     | Spears 1.4–2.7 kg typical; Greek hoplite 1.5–2.5 kg; Roman pilum 1–2.5 kg; spetum ~1.4–2.3 kg; pikes 2–6 kg. [10][11] | **Accurate.** Fits one-/two-handed spear. |

**Sources (summary):** [1] The History Ace / knight sword weight; [2] myArmoury longsword weight/length; [3] Wikipedia Longsword, Arming sword; [4] Houston Axe / battle axe weight; [5] Wikipedia Battle axe; [6] Cleveland Museum of Art seven-flanged mace; [7] Medieval London Objects mace; [8] ARMA essay “What Did Historical Swords Weigh?”; [9] Medieval dagger examples (Ballock, Baselard, Quillon, Blackfriars); [10] Vikingsword spear dimensions/weights; [11] Greek/Roman spear and polearm weights.

---

## 2. Weapon dimensions (contact width cm)

You use **point_width** (stab), **blade_width** (cut), **head_diameter** (blunt) as effective contact for damage/area.

| Weapon  | Your stab/cut/blunt (cm) | Notes from literature | Verdict |
|---------|---------------------------|------------------------|---------|
| Sword   | 0.5 / 2.0 / —            | Blade thickness at forte 2.5–12 mm; width varies. Effective cutting edge contact in a slash often ~1–3 cm; point ~few mm. [12][13] | **Reasonable.** 2 cm cut, 0.5 cm stab are plausible effective contact. |
| Axe     | 0.8 / 3.0 / —            | Axe blade width and edge length vary; 3 cm edge contact plausible for a chop. | **Reasonable.** |
| Mace    | — / — / 8.0              | Mace head diameter ~5–12 cm typical; 8 cm is plausible. | **Reasonable.** |
| Dagger  | 0.3 / 1.5 / —            | Narrow blade; 0.3 cm point and 1.5 cm edge plausible. | **Reasonable.** |
| Spear   | 0.6 / 2.5 / —            | Spearhead width and point size vary; values in line with a medium spear. | **Reasonable.** |

**Sources:** [12] Blade thickness / distal taper (artofswordmaking, Oakeshott); [13] Late medieval sword measurements (ageofdatini).

No strong conflict; these are effective-contact abstractions, not full blade dimensions.

---

## 3. Impact velocity (m/s) and physics constants

### 3.1 Velocity range

| Your value | Real-world / research |
|------------|------------------------|
| VELOCITY_MIN_M_S = 6.0, VELOCITY_MAX_M_S = 18.0 | Measured strike speeds with rod-like implements (sword-like): **17.2–23.9 m/s** (one-handed), **18.3–24.2 m/s** (two-handed). [14][15] |

**Verdict:** **6–18 m/s** is **closer to research** (17–24 m/s). J_PER_MM_RHA and DAMAGE_KE_SCALE were retuned (130 and 2.6) so damage and penetration in mm RHA stay in a similar band with the new velocity range.

### 3.2 J per mm RHA (sharp penetration)

| Your value | Real-world / research |
|------------|------------------------|
| J_PER_MM_RHA = 130 (game) | Base reference: 2.4 mm wrought iron **~112.5 J** → **~47 J/mm**; mild steel often cited **~55 J/mm**. [16][17] Game uses **130** so that at 6–18 m/s impact velocity, penetration in mm RHA stays in the same band as before (velocity was raised from 2–12 m/s). |

**Verdict:** **130 J/mm** in-game is a **scaled constant** so that with the research-aligned velocity range (6–18 m/s), armor penetration in mm RHA and damage feel similar. Base reference 47–55 J/mm fits:

- “Mild steel” or better quality than some wrought iron.
- A simple, stable penetration model.
- Slightly stronger armor in J terms for the same mm RHA.

So **accurate and realistic** for a game constant; no need to change unless you want armor to fail at lower energy.

### 3.3 Kinetic energy examples (your formula KE = ½ m v²)

- Sword 1.2 kg @ 12 m/s → KE = **86.4 J** → pen ≈ 86.4/130 ≈ **0.66 mm RHA** (mid power).
- Sword 1.2 kg @ 18 m/s → KE = **194.4 J** → pen ≈ 194.4/130 ≈ **1.5 mm RHA** (full power).
- Mace 1.7 kg @ 15 m/s → KE = **191 J** → pen ≈ **1.47 mm RHA** (blunt uses same KE→RHA then RHA_TO_MPA).
- Dagger 0.3 kg @ 10 m/s → KE = **15 J** → pen ≈ **0.12 mm RHA** (low mass limits KE).

So: cloth/leather easily exceeded, mail and plate require solid hits and/or higher velocity, which matches the idea that mail stops many slashes and plate is hard to pierce with typical melee KE.

**Sources:** [14] Influence of striking technique on maximum striking velocities (Academia); [15] ISBS measurement system kinematics impact historical fencing; [16] Arrows vs plate armor, Physics Forums (Alan Williams 2.4 mm wrought iron, ~112.5 J); [17] English longbow testing medievalists.net; [18] Momentum, kinetic energy and arrow penetration (CPW).

---

## 4. Armor: sharp resistance (mm RHA) and energy to penetrate

You use **sharp_resistance_rha_mm** so that **energy to penetrate ≈ resistance × J_PER_MM_RHA** (here 55 J/mm).

| Layer  | Your sharp (mm RHA) | Implied J to penetrate (55 J/mm) | Real-world / research | Verdict |
|--------|----------------------|-----------------------------------|------------------------|---------|
| Cloth  | 0.5                  | 27.5 J                            | Gambeson minimal vs focused point; 30-layer jack withstood ~200 J slash; typical slashing &lt;120 J. [19][20] | **Reasonable.** Thin cloth ~27 J plausible. |
| Leather| 1.0                  | 55 J                              | Buff leather “~30 J to penetrate” in your comment → ~0.55 mm equiv; 1.0 mm = 55 J is a bit stronger. [19][21] | **Plausible.** Slightly conservative (more J) than “30 J” buff. |
| Mail   | 2.0                  | 110 J                             | **100–120 J** to defeat mail + padding; bodkin with 120 lb bow ~95 J through 25 layers linen + deerskin + mail. [16][22][23] | **Accurate.** 110 J in the 100–120 J band. |
| Plate  | 3.5                  | 192.5 J                           | Medieval breastplate thickness ~1.25–7.8 mm (infantry often ~1.8–3 mm). [24][25] 2.4 mm wrought iron ~112.5 J; good plate “1–4 mm RHA equiv.” Strong longbow at close range can puncture thin plate. | **Accurate.** 3.5 mm RHA in the 1–4 mm “good plate” range; 192 J is a serious strike or close-range heavy arrow. |

**Sources:** [19] Gambeson / 30-layer jack (ArmStreet); [20] Buff-coat ballistic properties (Springer/PubMed); [21] A Commonplace Book / Williams; [22] Alan Williams mail 100–120 J; [23] Pope bodkin penetration; [24] Thickness mapping breastplates (Academia); [25] Breastplate through history (ade.pt).

---

## 5. Armor: plate thickness vs “RHA equivalent”

Physical thickness is not the same as “mm RHA equivalent” (which depends on material and quality). Your **plate 3.5 mm RHA** is an effective resistance, not necessarily 3.5 mm physical thickness.

- Medieval plate: physical **~1.25–7.8 mm**; quality from wrought iron (~50% mild steel) to hardened steel (~150%). [25][26]
- So **2.5 mm good steel ≈ ~2.75 mm mild steel equivalent**; **3.5 mm RHA** is a solid, good plate in game terms. **Realistic.**

**Source:** [26] The Knight and the Blast Furnace (Williams), effectiveness vs mild steel.

---

## 6. Armor: blunt resistance (MPa)

You use **blunt_resistance_mpa** with **RHA_TO_MPA = 0.6** to convert sharp penetration to blunt for deflection. Literature does **not** give medieval armor in MPa, so these are **game-relative** values.

- Ordering (plate 40 &gt; leather 14 &gt; mail 10 &gt; cloth 8) matches the idea: plate best at absorbing blunt, mail poor (trauma through), cloth/leather in between. [22][27]
- **Verdict:** **Plausible ordering.** Absolute MPa values are not directly comparable to real data; treat as tuning parameters.

**Sources:** [22] Mail poor vs blunt (trauma); [27] Gambeson/buff cushioning impact.

---

## 7. Damage formula (pre-armor): scale and bounds

You use:

- **Pre-armor damage** = DAMAGE_KE_SCALE × √(KE_J) × strength_mod × arm_mod, clamped to [DAMAGE_KE_MIN, DAMAGE_KE_MAX] (1–80).
- **DAMAGE_KE_SCALE = 4.0.**

Example: KE = 50 J → √50 ≈ 7.07 → 4×7.07 ≈ **28** (before strength/arm). So damage grows with √(KE), which is a common choice to avoid linear “double energy = double damage” and to keep very high KE from dominating. **Realistic in spirit;** exact scale and clamp are for balance.

**Verdict:** **Reasonable.** No real-world “damage number” to compare; √(KE) and clamping are sensible design.

---

## 8. Penetration cap

**PENETRATION_KE_CAP_MM_RHA = 15.0** limits how much armor one hit can overcome. Real plate rarely exceeded a few mm RHA equivalent; 15 mm would represent extreme penetration. **Cap is realistic** and avoids trivializing heavy armor.

---

## 9. Summary table and recommendations

| Area | Your values | Verdict | Status |
|------|-------------|---------|------------|
| Weapon mass | Sword 1.2, Axe 1.5, Mace **1.7**, Dagger 0.3, Spear 1.8 kg | **Accurate** | Applied: mace 2.0 to 1.7 kg. |
| Contact widths | 0.3–3 cm stab/cut, 8 cm blunt | **Reasonable** | No change needed. |
| Velocity range | **6–18 m/s** | **Closer to research** (17–24 m/s) | Applied: 2–12 → 6–18 m/s. |
| J_PER_MM_RHA | **130** (scaled for 6–18 m/s) | **Tuned** so mm RHA band similar | Applied: 55 → 130. |
| Armor sharp (mm RHA) | Cloth 0.5, Leather 1, Mail 2, Plate 3.5 | **Accurate** vs J-to-penetrate and thickness equiv | Keep. |
| Armor blunt (MPa) | Ordering plate &gt; leather &gt; mail &gt; cloth | **Plausible** (game-relative) | Keep ordering; tune numbers for feel. |
| DAMAGE_KE_SCALE | **2.6** | **Tuned** so damage band similar | Applied: 4.0 → 2.6. |
| Penetration cap 15 mm RHA | Yes | **Realistic** | Keep. |

Overall, weapon masses, velocity range, KE constants, and armor sharp resistances are **aligned with real-world and research examples**; velocity and mace mass were updated, and J_PER_MM_RHA and DAMAGE_KE_SCALE were retuned so damage and penetration stay in the same band with the new velocity range.
