# Weapon Part Length and Parry Contact Investigation

Investigation into integrating weapon part lengths so parries interact with the correct part of each weapon—e.g., spear parries with shaft (not the small blade), mace blocks with shaft (not the head), and sword parries with blade. Ensures the system properly differentiates which weapon part makes contact during parries.

---

## 1. Summary of Findings

**Current state:** The system has no weapon part lengths. Parry capacity and attack momentum use whole-weapon properties (mass, parry_speed_factor). Parries are assumed blade-on-blade for all weapons, which is incorrect for spear, mace, and axe.

**Recommendation:** Add explicit `parry_contact_part` and optional part lengths per weapon. Apply part-specific modifiers to parry capacity and (optionally) attack momentum. Start with a minimal "parry contact type" per weapon; expand to full part-length modeling if needed.

---

## 2. Current Weapon Structure

### 2.1 What Exists (Weapon.gd, WeaponConstants.gd)

| Property | Purpose | Used for Parry? |
|---------|---------|-----------------|
| `mass` | Damage, momentum | ✓ Both parry_p_a and parry_c_d |
| `parry_speed_factor` | Parry blade speed (dagger 1.2, mace 0.9) | ✓ parry_c_d via get_parry_speed_m_s |
| `blade_width` | Contact for cuts | Damage only |
| `point_width` | Contact for thrusts | Damage only |
| `thrust_head_width` | Blunt area behind point | Damage only |
| `head_diameter` | Blunt strike head | Damage only |
| `edge_width` | Sharp component (flanges) | Damage only |
| `melee_range` | Abstract range | Targeting, not parry |
| `blade_cut_ratio`, `sharpness` | Damage split | Damage only |

### 2.2 What Is Missing

- **No part lengths:** `blade_length_cm`, `shaft_length_cm`, `handle_length_cm`, `total_length_cm`
- **No parry contact part:** The defender's weapon is treated as having a single "parry surface."
- **No attacker contact part:** Attack momentum uses full mass; no notion of which part (blade tip, mace head, spear point) would hit the parry.

---

## 3. How Parries Work Today

### 3.1 Parry Resolution Flow

1. **Defender parry capacity** (`parry_c_d`): `mass × parry_speed × (strength/100) × agility × readiness × alignment × ...`
   - Assumes defender's weapon moves a "blade" into position.
   - `parry_speed` = base × `parry_speed_factor` (dagger faster, mace slower).

2. **Attack momentum** (`parry_p_a`): `mass × velocity × velocity_curve_factor(parry_progress)`
   - Uses full weapon mass.
   - No distinction between thrust (point carries momentum) vs overhead (head carries momentum).

3. **Resolution:** Full deflect if `c_d >= p_a × threshold`; else partial parry with `remaining_ratio`.

### 3.2 Implicit Assumptions

- **Defender:** All weapons parry with "blade-like" surface—movement speed scales with parry_speed_factor.
- **Attacker:** Full mass in motion regardless of attack type.
- **Contact:** Blade-on-blade for longsword-style fights. HEMA research (57–80% blade-blade for longsword) supports this for sword vs sword.

---

## 4. Realistic Parry Contact by Weapon Type

### 4.1 Sword

- **Parries with:** Blade (strong or weak).
- **Reality:** Defender catches attacker's weak on defender's strong (Liechtenauer, i.33). Flat parries preferred (ARMA).
- **Current fit:** ✓ Reasonable. Mass and parry_speed_factor work. Strong/weak is approximated by `PARRY_STRONG_CONTACT_BY_ARCH` (overhead 1.12, slash 1.0).
- **Gap:** No blade length → cannot compute strong vs weak fraction. Archetype modifier is a stand-in.

### 4.2 Spear

- **Parries with:** **Shaft**, not the blade.
- **Reality:** Spear blade is small (10–25 cm, ~2.5 cm wide). Parrying with the blade is dangerous and hard to time. Polearms are blocked with the shaft—the long wooden portion intercepts the attack. Fiore, Talhoffer, and historical polearm use all emphasize shaft blocks.
- **Current fit:** ✗ Wrong. Spear uses same parry logic as sword. Mass 1.8 kg is mostly shaft; parry_speed_factor 1.0 treats it like a sword. The *effective* parry surface (shaft cross-section, leverage) is not modeled.

### 4.3 Mace

- **Parries with:** **Shaft**, not the head.
- **Reality:** You do not "catch a sword edge with the mace head." That would damage the mace, risk the sword biting the handle, and be awkward. Mace blocks use the shaft/handle. The head is for striking.
- **Current fit:** ✗ Wrong. Mace has `blade_width=0`, `point_width=0`, `head_diameter=8`—all for attack damage. Parry uses mass 1.7 kg and parry_speed_factor 0.9. No notion that the defender is blocking with shaft, not head.

### 4.4 Axe

- **Parries with:** **Haft** (handle) or blade, depending on technique.
- **Reality:** Le Jeu de la Hache: haft parries are common. The blade can parry chops, but the handle is frequently used to intercept. Axe has blade for cuts and spike for thrusts; haft for blocking.
- **Current fit:** △ Partial. Axe has blade_width 3, parry_speed_factor 0.95. Treated more like a sword. No haft vs blade distinction for parrying.

### 4.5 Dagger

- **Parries with:** Blade.
- **Reality:** Small blade; quick, nimble parries. Fiore emphasizes dagger defense with the blade.
- **Current fit:** ✓ Good. parry_speed_factor 1.2 reflects speed. Mass 0.3 kg is appropriate.

---

## 5. Attacker's Weapon: Which Part Hits the Parry?

When the defender parries, what part of the **attacker's** weapon makes contact?

| Attack Type | Contact Part | Momentum Distribution |
|-------------|--------------|----------------------|
| **Thrust** | Point / tip | Most mass in shaft behind point; point leads. Momentum ≈ full mass × velocity (whole weapon moves). |
| **Cut/slash** | Edge (strong or weak) | Blade carries motion; handle follows. Momentum ≈ full mass × velocity. Strong vs weak affects leverage (defender advantage if catching weak). |
| **Blunt overhead** | Head | Head carries most momentum; shaft follows. Could model as "effective mass" = fraction in head. |
| **Spear thrust** | Point | Point leads; shaft behind. Same as thrust. |
| **Mace overhead** | Head | Head is heavy; most momentum in head. Shaft contributes less. |

**Current:** `parry_p_a = mass × velocity` uses full mass. For most attacks this is acceptable—the whole weapon is in motion. For mace/pollaxe overhead, the *striking* part (head) carries disproportionate momentum, but modeling that requires mass distribution per part.

---

## 6. Implementation Options

### Option A: Parry Contact Type (Minimal)

**Idea:** Each weapon defines `parry_contact_part: "blade" | "shaft" | "haft"`. No lengths. Modifiers only.

**Data:**
```gdscript
# In weapon definition
"SWORD": { ..., "parry_contact_part": "blade" },
"SPEAR": { ..., "parry_contact_part": "shaft" },
"MACE": { ..., "parry_contact_part": "shaft" },
"AXE": { ..., "parry_contact_part": "haft" },   # or "blade" for blade parries
"DAGGER": { ..., "parry_contact_part": "blade" },
```

**Modifiers (DefenseChoiceResolver / PassiveParryContext):**

| parry_contact_part | Parry capacity effect | Rationale |
|--------------------|-----------------------|-----------|
| blade | ×1.0 (baseline) | Sword/dagger parry with blade. |
| shaft | ×0.85 | Shaft is longer lever, good for deflection, but less "bite" than blade. Slightly lower effective capacity. |
| haft | ×0.9 | Similar to shaft; axe haft blocks well. |

**Attacker consideration:** When attacker uses mace/spear thrust vs defender with blade—does defender's blade "catch" the point or shaft? Optionally: when attacker attack_type is STAB and attacker weapon has `parry_contact_part == "shaft"` (spear), treat thrust as slightly harder to parry (point slips past blade) → `parry_p_a *= 1.05` or similar. Kept minimal.

**Effort:** Low. Add one enum field, one lookup, one multiplier at parry capacity.

---

### Option B: Part Lengths + Parry Surface

**Idea:** Add `blade_length_cm`, `shaft_length_cm` (or `handle_length_cm`), `total_length_cm`. Compute parry-relevant properties.

**Data (example):**
```gdscript
"SWORD": {
    "blade_length_cm": 90,
    "handle_length_cm": 30,
    "total_length_cm": 120,
    "parry_contact_part": "blade"
},
"SPEAR": {
    "blade_length_cm": 25,      # small head
    "shaft_length_cm": 200,
    "total_length_cm": 225,
    "parry_contact_part": "shaft"
},
"MACE": {
    "head_length_cm": 15,       # effective striking length
    "shaft_length_cm": 60,
    "parry_contact_part": "shaft"
},
```

**Use:**

1. **Strong vs weak (blade weapons):** `strong_fraction = handle_length / total_length` (or fixed 0.3). Parry capacity × `(1 + 0.2 * strong_contact_quality)` when defender catches weak (archetype OVERHEAD = more weak exposed).
2. **Shaft parry surface:** Shaft diameter (or assume ~3 cm) gives effective contact width. Parry capacity could scale with `sqrt(shaft_length)` for leverage, capped.
3. **Mace/spear vs blade parry:** When defender has blade and attacker has thrust (spear point): defender's small blade vs attacker's long shaft → attacker's point can slip past. Modifier when `(atk_weapon.parry_contact_part == "shaft" or "point") and atk_move.contact_type == STAB` → `parry_p_a *= 1.05`.

**Effort:** Medium. Requires new weapon fields, research for lengths, formula tuning.

---

### Option C: Full Part Model (Mass Distribution)

**Idea:** Each part has length, mass fraction, and role. Parry uses the part that actually contacts.

**Data (conceptual):**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
    {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
],
"parry_part": "blade"
```

For mace:
```gdscript
"parts": [
    {"id": "head", "length_cm": 15, "mass_fraction": 0.7, "parry_eligible": false},
    {"id": "shaft", "length_cm": 60, "mass_fraction": 0.3, "parry_eligible": true}
],
"parry_part": "shaft"
```

**Parry capacity:** Use mass of parry part only? Or total mass with part-specific speed? E.g. `parry_c_d = parry_part_mass × parry_speed × leverage_factor`.

**Attack momentum:** For blunt overhead, `p_a = head_mass_fraction × total_mass × velocity` (head carries the blow).

**Effort:** High. Significant weapon schema change, balance pass, many edge cases.

---

## 7. Recommended Implementation Path

### Phase 1: Parry Contact Type (Option A)

1. Add `parry_contact_part` to weapon definitions: `"blade"`, `"shaft"`, `"haft"`.
2. In `_compute_parry_c_d` or `DefenseChoiceResolver`, multiply `parry_c_d` by `get_parry_contact_modifier(def_weapon.parry_contact_part)`.
3. Optional: When attacker has thrust (spear/point) and defender has blade, apply small `parry_p_a` bonus (point harder to catch).
4. Document: Spear and mace parry with shaft; axe with haft. Sword and dagger with blade.

**Files:** Weapon.gd, WeaponConstants.gd, DefenseChoiceResolver.gd, CombatConstants.gd.

### Phase 2: Part Lengths (Option B, Optional)

1. Add `blade_length_cm`, `shaft_length_cm`, `handle_length_cm`, `total_length_cm` where relevant.
2. Use for strong/weak (blade) and shaft leverage.
3. Calibrate with HEMA ranges (longsword blade ~90 cm, spear head ~15–25 cm, etc.).

### Phase 3: Mass Distribution (Option C, Deferred)

Only if Phase 1–2 prove insufficient. Adds complexity; reserve for deep simulation needs.

---

## 8. Validation Checklist

| Weapon | Parries With | Current | After Option A |
|--------|--------------|---------|----------------|
| Sword | Blade | Implicit blade | Explicit blade, ×1.0 |
| Dagger | Blade | Implicit blade | Explicit blade, ×1.0 |
| Spear | Shaft | Treated as blade | Shaft, ×0.85 (or tuned) |
| Mace | Shaft | Treated as blade | Shaft, ×0.85 |
| Axe | Haft or blade | Treated as blade | Haft, ×0.9 |

---

## 9. Parry Behavior by Weapon Type: Detailed Interaction Matrix

Different parry behaviors emerge from the combination of **defender weapon** and **attacker attack type**. The system already has attack-type modifiers (redirect_thrust_bonus +22%, redirect_blunt_penalty −12%, strong_contact_by_arch); weapon-type differentiation adds a second axis.

### 9.1 Defender Weapon × Attack Type Interaction

| Defender \ Attacker | Thrust | Cut/Slash | Blunt |
|--------------------|--------|-----------|-------|
| **Sword** | Blade deflects point; flat preferred. Good. | Blade-on-blade; strong catches weak. Best case. | Edge can chip; redirect works. Current −12% blunt. |
| **Dagger** | Small blade; point can slip past. Risky. | Quick redirect; blade adequate. Good. | Bad: mass disparity; prefer dodge. |
| **Spear** | Shaft intercepts; long lever deflects well. | Shaft blocks cut; less "bite" than blade. | Shaft absorbs; pole can take it. |
| **Mace** | Shaft blocks; head stays out of way. | Shaft vs edge; shaft can take impact. | Shaft vs head; heavy impact. Block-heavy. |
| **Axe** | Haft or blade; haft common. | Blade or haft; blade can bind. | Haft absorbs; poll can counter. |

### 9.2 Behavioral Dimensions (What Varies by Weapon)

1. **Contact part:** blade (sword, dagger) vs shaft (spear, mace) vs haft (axe)
2. **Redirect vs block preference:** Dagger/sword redirect; mace/axe more block-capable when mass/str sufficient
3. **Effectiveness vs thrust:** Blade intercepts point; shaft has more surface—different geometry
4. **Effectiveness vs blunt:** Shaft/haft absorb better; blade edge risks damage (already −12% redirect)
5. **Point-slip risk:** Defender blade vs attacker thrust (spear point)—point can slip past small blade

### 9.3 Current System Coverage

| Dimension | Already modeled? | How |
|-----------|------------------|-----|
| Attack type (thrust/cut/blunt) | ✓ | redirect_thrust_bonus, redirect_blunt_penalty, strong_contact_by_arch |
| Mass disparity | ✓ | mass_disparity_bonus, block thresholds |
| Defender weapon speed | ✓ | parry_speed_factor |
| Guard alignment | ✓ | get_line_alignment_with_deflect, BP2 |
| Contact part (blade vs shaft) | ✗ | All treated as blade |
| Weapon-type vs attack-type | △ | Via archetype only; no defender-weapon-specific |

---

## 10. Differentiation Levels: How Many Lengths / How Much Granularity?

### Level 0: No Differentiation (Current)

- **Data:** mass, parry_speed_factor only.
- **Parry capacity:** Same formula for all weapons.
- **Lengths:** None.
- **Effort:** 0. Already in place.
- **Gaps:** Spear, mace, axe parry behavior wrong.

### Level 1: Parry Contact Part Only (3 categories)

- **Data:** `parry_contact_part: "blade" | "shaft" | "haft"` per weapon. No lengths.
- **Differentiation count:** 3 contact types × 5 weapons = 5 assignments (each weapon gets one).
- **Parry capacity:** `c_d *= get_parry_contact_modifier(part)` — single scalar per defender.
- **Lengths:** 0.
- **Effort:** Low (1 enum, 1 lookup table, 1 multiply).
- **Covers:** Correct contact part; shaft/haft vs blade differentiation.

### Level 2: Contact Part + Defender×Attacker Modifiers

- **Data:** Level 1 + optional `parry_vs_attack_modifiers: { "thrust": 1.05, "cut": 1.0, "blunt": 0.9 }` per weapon (or def_weapon × atk_attack_type matrix).
- **Differentiation count:** 5 weapons × 3 attack types = 15 modifiers (or 5×5×3 for weapon×weapon×attack).
- **Parry capacity:** `c_d *= contact_mod * defender_vs_attack_mod(def_weapon, attack_type)`.
- **Lengths:** 0.
- **Effort:** Low–Medium. Can start with 5×3 (weapon × attack_type) — e.g. spear vs thrust = 1.0 (shaft good), dagger vs thrust = 0.9 (point slip risk).
- **Covers:** Contact part + weapon-specific efficacy vs thrust/cut/blunt.

### Level 3: Part Lengths (2–3 Lengths per Weapon)

- **Data:** `blade_length_cm`, `shaft_length_cm`, `handle_length_cm`, `total_length_cm` where applicable.
- **Differentiation count:** 2–4 lengths × 5 weapons ≈ 10–15 values.
- **Use:** Strong vs weak (blade_length/total); shaft leverage (sqrt(shaft_length)); reach (melee_range already exists).
- **Effort:** Medium. Research, data entry, formula design.
- **Covers:** Strong/weak contact quality; leverage; reach-based edge cases.

### Level 4: Full Part Model (Mass Distribution)

- **Data:** Per-part length, mass_fraction, parry_eligible.
- **Differentiation count:** ~3–4 parts × 5 weapons × 3–4 properties = 45–80 values.
- **Effort:** High. Schema change, balance pass.
- **Covers:** Attack momentum from striking part (mace head); parry capacity from parrying part mass.

---

## 11. Optimal Representation for This System

### Recommendation: **Level 1 + Selective Level 2**

**Level 1 (required):** Add `parry_contact_part` to all 5 weapons. Apply a single modifier in `_compute_parry_c_d`:

- blade: 1.0 (baseline)
- shaft: 0.88 (spear, mace — good surface, less "bite" than blade)
- haft: 0.92 (axe — between blade and shaft)

**Selective Level 2 (optional, high-value pairs only):** Add defender×attack_type modifiers only where the interaction is physically distinct:

| Defender | Attacker Attack | Modifier | Rationale |
|----------|-----------------|----------|-----------|
| Dagger | Thrust | 0.9 | Point-slip risk; small blade vs thrust |
| Spear | Thrust | 1.0 | Shaft intercepts thrust well; no change |
| Spear | Cut | 0.95 | Shaft blocks; slightly less effective than blade bind |
| Mace | Blunt | 1.05 | Shaft absorbs blunt impact well |

Limit to 4–6 such overrides. Avoid a full 5×3 matrix unless calibration demands it.

### Length Differentiations: **Zero for Minimum; One or Two for Polish**

- **Minimum viable:** Level 1 only. **Zero** explicit length fields. `parry_contact_part` captures the essential distinction (blade vs shaft vs haft) without lengths.
- **Polish:** Add `blade_length_cm` and `total_length_cm` only for **blade weapons** (sword, dagger) to refine strong/weak (replace or augment PARRY_STRONG_CONTACT_BY_ARCH). Spear/mace/axe get `shaft_length_cm` only if you later add leverage or reach logic — not required for initial correctness.

### Why Not More?

1. **Abstract combat:** No 3D geometry. Length drives leverage/strong-weak indirectly; a single contact-part modifier achieves 80% of the effect.
2. **Five weapons:** Full part model (Level 4) is overkill. Mass distribution matters most for mace vs sword; current mass values already differ (1.7 vs 1.2).
3. **Existing calibration:** redirect_thrust, redirect_blunt, strong_contact_by_arch already tune attack-type behavior. Weapon-type adds orthogonal axis without duplicating.

### Summary Table

| Level | Lengths | Contact Parts | Defender×Attack | Effort | Fidelity Gain |
|-------|---------|---------------|-----------------|--------|---------------|
| 0 (current) | 0 | 0 (implicit blade) | Via archetype only | 0 | — |
| 1 | 0 | 3 (blade/shaft/haft) | No | Low | High (fixes spear/mace/axe) |
| 1 + selective 2 | 0 | 3 | 4–6 overrides | Low | Higher (dagger vs thrust, etc.) |
| 3 | 2–4 per weapon | 3 | Optional | Medium | Strong/weak, leverage |
| 4 | Full part model | Per-part | Yes | High | Diminishing returns |

**Optimal:** Level 1 with optional 4–6 Level 2 overrides. Zero length fields for minimum; 1–2 length fields per blade weapon only if strong/weak refinement is desired.

---

## 12. References

- **PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md:** Strong vs weak; contact point; deflection direction.
- **COMBAT_PARRY_MISS_RESEARCH.md:** 57–80% blade-blade for longsword; flat parries.
- **HEMA_FIDELITY_IMPROVEMENTS.md:** Blade geometry (strong/weak); PARRY_STRONG_CONTACT_BY_ARCH.
- **Weapon.gd, WeaponConstants.gd:** Current weapon structure.
- **DefenseChoiceResolver.gd:** Parry capacity computation (`_compute_parry_c_d`).
- **PassiveParryContext.gd:** Parry speed, strong_contact_by_arch.
- **Fiore, Talhoffer, Le Jeu de la Hache:** Historical sources for polearm and mace defense with shaft/haft.
