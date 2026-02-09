# Weapon dimensions and contact area per component

Contact area is **per attack** and **per damage component**: each attack uses the **surface that would actually be hitting** for that move.

---

## 1. Surface = what part of the weapon hits (per attack)

- **Sharp component** (cut ratio): penetrates or deflects based on **sharp contact** (edge or point width). Smaller contact → higher pressure → deeper penetration.
- **Blunt component** (1 − cut ratio): penetrates or transmits (BAT) based on **blunt contact** (striking surface). Larger contact → lower pressure → more deflection/BAT.

So for a **cut** (e.g. sword): sharp uses `blade_width` (edge), blunt uses `max(blade_width, BLUNT_CUT_MIN_CONTACT_CM)` (the “slap” of the cut, not the edge).  
For a **blunt** move (e.g. mace): sharp uses `edge_width` (flanges/ridges that can break skin), blunt uses `head_diameter`.

---

## 2. No weapon has 0% cutting

`MIN_CUT_RATIO` (2%) is applied so that even dedicated blunt weapons (mace, pommel, poll) have a small cutting component. Historically, mace flanges and axe poll ridges can break skin; the small cut ratio reflects that and uses `edge_width` (or point fallback) for sharp penetration.

---

## 3. Per-weapon dimensions (cm, kg)

Data-oriented defaults; sources in comments in `WeaponConstants.gd`.

| Weapon  | Mass | Blade | Point | Head | Edge (flange) | Cut ratio (weapon) | Notes |
|---------|------|-------|-------|-----|----------------|---------------------|--------|
| Sword   | 1.2  | 2.0   | 0.5   | —   | —              | 0.75                | Longsword/arming; thrust/cuts/pommel |
| Axe     | 1.5  | 3.0   | 0.8   | —   | —              | 0.6                 | Battle axe; spike/chops/poll (blunt fallback 3 cm) |
| Mace    | 1.7  | —     | —     | 8.0 | 0.5            | 0 (archetype 0.05)  | Flanged mace; sharp component uses edge_width |
| Dagger  | 0.3  | 1.5   | 0.3   | —   | —              | 0.9                 | Rondel; thrust/slash/pommel |
| Spear   | 1.8  | 2.5   | 0.6   | —   | —              | 0.85                | Thrust/slash/pole (blunt fallback 3 cm) |

- **Blade**: edge contact for cuts (sharp component).
- **Point**: tip contact for thrusts (sharp component).
- **Head**: striking diameter for blunt moves (blunt component); 0 → fallback 3 cm (pommel, poll, pole).
- **Edge**: optional; used for **sharp** component on **blunt** moves (mace flanges ~0.4–0.6 cm).

---

## 4. How contact is used in code

- **Pre-armor damage**: one contact per move via `get_contact_width(move_id)` (the primary striking surface for that attack).
- **Sharp penetration**: `get_sharp_contact_cm(move_id)` → stab: point; cut: blade; blunt: edge_width or fallback.
- **Blunt penetration**: `get_blunt_contact_cm(move_id)` → **stab: point** (same as sharp — blunt from stab is through the tip); cut: max(blade, BLUNT_CUT_MIN 5 cm); blunt: head or fallback.

So each **attack** uses the surface that hits; each **component** uses that surface (or the appropriate sub-part for cuts, where the edge cuts and the slap blunts).
