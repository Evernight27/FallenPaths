# Parry Bind And Weapon Geometry

**Plan / code:** **Status** → plan [milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary) only. **Live paths** below · investigations have **`Source:`** provenance.

| Step | Live path |
|------|-----------|
| **3.1** | [Strike measure](#tier-31-strike-measure-live-path) |
| **3.2** | [Parry / bind](#tier-32-parry-bind-live-path) |

---

<a id="tier-31-strike-measure-live-path"></a>

## Tier 3.1 — strike measure (live path)

| Layer | Module | Role |
|-------|--------|------|
| Pair geometry | `AvailableActionsBuilder` | `stamp_attack_pair_geometry_on_dict`, `strike_measure_ratio_for_attack_pair` |
| Wind-up | `AttackWindUpStarter` | stamps on pending attack |
| Spacing | `CombatDistanceBands`, `CombatConstants` | `STRIKE_MEASURE_*`, `distance_to` |
| Surround (flag off) | `TacticalCombat` | sector surround when `is_feature_sector_surround_load` |

**Harness (grep):** `_run_windup_pending_attack_pair_geometry`, `_run_strike_measure_constants_sanity`, `_run_surround_`, `_run_depth_polearm_`, `_run_stamp_attack_pair_geometry_depth` · registry [`REGRESSION_HARNESS_MAP_TIER19.md`](REGRESSION_HARNESS_MAP_TIER19.md).

---

<a id="tier-32-parry-bind-live-path"></a>

## Tier 3.2 — parry / bind / deflect (live path)

| Layer | Module | Role |
|-------|--------|------|
| Clash context | `DefenseResolutionHandler` | `parry_clash_context` keys (`PARRY_CLASH_CONTEXT_KEYS_FULL_STOP` in harness) |
| Passive defense | `DefenseChoiceResolver` | `choose_defense`, spacing, feint telegraph |
| Guard deflect | `GuardLineUpdater` | `set_guard_deflected` severity |
| Weapon parts | `Weapon.gd`, `WeaponConstants` | part mass / parry contact |

**Harness (grep):** `_run_parry_`, `_run_bind_riposte_`, `_run_weapon_part_mass_model_normalized` · deflect detail → [`PARRY_DEFLECT_AND_CALIBRATION.md`](PARRY_DEFLECT_AND_CALIBRATION.md).

---

## Contents (investigations)

---

1. [WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md](#weapon-part-length-parry-contact-investigation)
2. [WEAPON_PART_MODEL_IMPLEMENTATION_PLAN.md](#weapon-part-model-implementation-plan)
3. [BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION.md](#bind-riposte-weapon-type-investigation)
4. [BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION.md](#bind-riposte-windup-physics-investigation)
5. [PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md](#part-3-hard-bind-riposte-implementation-investigation)
6. [HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md](#hema-vs-system-bind-deflect-comparison)

---

<a id="weapon-part-length-parry-contact-investigation"></a>

## Source: `WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md`

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

---

<a id="weapon-part-model-implementation-plan"></a>

## Source: `WEAPON_PART_MODEL_IMPLEMENTATION_PLAN.md`

## Weapon Part Model (Level 4) Implementation Plan

Full integration plan for the weapon part length and mass distribution system. Use this document as the starting prompt for a fresh agent to implement Option 4 / Level 4 from `WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md`.

---

### Prompt for Fresh Agent

**Instructions:** Implement the full weapon part model (Level 4) as described in this plan. Read `docs/PARRY_BIND_AND_WEAPON_GEOMETRY.md` first for context. Then follow the phases in order (§4). Key files: `weapon/Weapon.gd`, `weapon/WeaponConstants.gd`, `combat/DefenseChoiceResolver.gd`, `combat/DefenseResolutionHandler.gd`, `combat/CombatConstants.gd`. Preserve backward compatibility: weapons without `parts` must behave exactly as today. Test with legacy mode (no parts) and with parts enabled.

---

### 1. Context and Goal

**Current state:** Weapons have flat properties (mass, parry_speed_factor, blade_width, etc.). Parry capacity uses whole-weapon mass; attack momentum uses whole-weapon mass. Spear, mace, and axe are incorrectly treated as blade-parrying weapons.

**Goal:** Implement the **full part model (Level 4)** with:
- Per-part length, mass fraction, parry eligibility
- Parry capacity from parrying part mass + leverage
- Attack momentum from striking part mass (for blunt/head-heavy attacks)
- Defender×attack-type modifiers for physically distinct interactions
- Extensible schema for future weapons (pollaxe, halberd, falchion, etc.)

**Reference doc:** `docs/PARRY_BIND_AND_WEAPON_GEOMETRY.md` — read §4 (weapon-specific parry contact), §5 (attacker contact part), §6 Option C, §9 (interaction matrix), §10 (differentiation levels).

---

### 2. Schema Definition

#### 2.1 Part Structure

Each weapon can have an optional `parts` array. If absent, weapon uses **legacy mode** (current behavior: whole-weapon mass for parry and attack).

```gdscript
# Single part: id, length_cm, mass_fraction (0–1, must sum to 1.0 across parts), parry_eligible (bool)
# striking_for: optional Array of contact_type ("stab"|"cut"|"blunt") — if set, this part is the striking part for those moves
"parts": [
    {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
    {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
],
"parry_part_id": "blade"  # Which part is used for parrying. Must match a part with parry_eligible true.
```

#### 2.2 Move → Striking Part Mapping

Each move has a `contact_type` (stab/cut/blunt). The striking part is resolved by:
1. Find part with `striking_for` containing that contact_type; else
2. Use part with matching id: stab→point/blade, cut→blade, blunt→head; else
3. Use first part (or whole weapon in legacy mode).

For simplicity, **infer from contact_type** unless a part explicitly has `striking_for`. Convention:
- **stab** → point or blade (spear: point part; sword: blade)
- **cut** → blade
- **blunt** → head (mace, poll, pommel) or shaft (pole_swing)

#### 2.3 Backward Compatibility

- If weapon has no `parts`: use `mass` for parry and attack (current behavior).
- If weapon has `parts` but no `parry_part_id`: infer from first `parry_eligible` part, or fall back to legacy.
- All existing weapon consumers (WeaponDamageHelper, AttackResolver) must continue to work; add new getters that use part model when available.

---

### 3. Weapon Data Migration (WeaponConstants.gd)

#### 3.1 Part Definitions per Weapon

**SWORD:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 90, "mass_fraction": 0.6, "parry_eligible": true},
    {"id": "handle", "length_cm": 30, "mass_fraction": 0.4, "parry_eligible": false}
],
"parry_part_id": "blade"
```

**DAGGER:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 20, "mass_fraction": 0.55, "parry_eligible": true},
    {"id": "handle", "length_cm": 12, "mass_fraction": 0.45, "parry_eligible": false}
],
"parry_part_id": "blade"
```

**SPEAR:**
```gdscript
"parts": [
    {"id": "head", "length_cm": 25, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab", "cut"]},
    {"id": "shaft", "length_cm": 200, "mass_fraction": 0.85, "parry_eligible": true, "striking_for": ["blunt"]}
],
"parry_part_id": "shaft"
```

**MACE:**
```gdscript
"parts": [
    {"id": "head", "length_cm": 15, "mass_fraction": 0.7, "parry_eligible": false, "striking_for": ["blunt"]},
    {"id": "shaft", "length_cm": 55, "mass_fraction": 0.3, "parry_eligible": true}
],
"parry_part_id": "shaft"
```

**AXE:**
```gdscript
"parts": [
    {"id": "blade", "length_cm": 25, "mass_fraction": 0.4, "parry_eligible": true, "striking_for": ["cut"]},
    {"id": "spike", "length_cm": 8, "mass_fraction": 0.15, "parry_eligible": false, "striking_for": ["stab"]},
    {"id": "haft", "length_cm": 90, "mass_fraction": 0.45, "parry_eligible": true, "striking_for": ["blunt"]}
],
"parry_part_id": "haft"  # Le Jeu: haft parries common
```

#### 3.2 Retention of Existing Fields

Keep `mass`, `parry_speed_factor`, `blade_width`, etc. `mass` = total mass; used for damage and as fallback when parts absent. Parts add detail for parry/attack momentum only.

---

### 4. Implementation Phases

#### Phase 1: Schema and Weapon.gd Extensions

**Files:** `weapon/Weapon.gd`, `weapon/WeaponConstants.gd`

1. Add to Weapon class:
   - `parts: Array` (array of dicts: id, length_cm, mass_fraction, parry_eligible, striking_for)
   - `parry_part_id: String` (default "")
   - `parry_contact_part: String` (derived: "blade"|"shaft"|"haft" from parry_part_id for modifier lookup)

2. In `create_from_definition`, load `parts` and `parry_part_id` from def. If def has no parts, leave parts empty and parry_part_id empty (legacy).

3. Add getters:
   - `get_parry_part_mass_kg() -> float` — mass of parry_part_id; else total mass
   - `get_parry_part_length_cm() -> float` — length of parry part; else 0
   - `get_striking_part_mass_kg(contact_type: String) -> float` — mass of part used for that contact_type; else total mass
   - `has_parts() -> bool`
   - `get_parry_contact_type() -> String` — "blade"|"shaft"|"haft" for modifier lookup; default "blade" if legacy or unknown

4. Add `PARRY_CONTACT_TYPE_BY_PART_ID` in WeaponConstants or CombatConstants: `{"blade"=>"blade", "handle"=>"blade", "shaft"=>"shaft", "haft"=>"haft", "head"=>""}` (head never parries).

---

#### Phase 2: Parry Capacity (Defender) — DefenseChoiceResolver

**Files:** `combat/DefenseChoiceResolver.gd`, `combat/CombatConstants.gd`

1. In `_compute_parry_c_d(def_weapon, tgt)`:
   - Replace `m_d = def_weapon.mass` with:
     ```gdscript
     var m_d: float = def_weapon.get_parry_part_mass_kg() if def_weapon.has_parts() else float(def_weapon.mass)
     ```
   - After base `c_d_full`, multiply by parry contact modifier:
     ```gdscript
     var contact_type: String = def_weapon.get_parry_contact_type() if def_weapon.has_parts() else "blade"
     c_d_full *= CombatConstants.PARRY_CONTACT_MODIFIERS.get(contact_type, 1.0)
     ```

2. Add to CombatConstants:
   ```gdscript
   const PARRY_CONTACT_MODIFIERS: Dictionary = {
       "blade": 1.0,
       "shaft": 0.88,
       "haft": 0.92
   }
   ```

3. Optional leverage factor for shaft/haft: `c_d_full *= leverage_factor(parry_part_length_cm)` — e.g. `min(1.1, 0.95 + sqrt(length_cm) / 100)` or similar. Defer to calibration.

4. Defender×attack_type modifiers (selective Level 2):
   - Add `PARRY_DEFENDER_VS_ATTACK_MODIFIERS: Dictionary` keyed by `defender_weapon_type + "_vs_" + attack_type` or nested dict.
   - Example keys: `DAGGER_vs_stab: 0.9`, `MACE_vs_blunt: 1.05`
   - Apply after contact modifier: `c_d_full *= get_defender_vs_attack_mod(def_weapon.weapon_type, attack_type)`

---

#### Phase 3: Attack Momentum (parry_p_a) — DefenseChoiceResolver and DefenseResolutionHandler

**Files:** `combat/DefenseChoiceResolver.gd`, `combat/DefenseResolutionHandler.gd`

1. **parry_p_a computation** (DefenseChoiceResolver):
   - Use striking part mass when weapon has parts and move contact_type is BLUNT (head-heavy attacks):
     ```gdscript
     var m_a_striking: float = atk_weapon.get_striking_part_mass_kg(contact_type) if atk_weapon.has_parts() else float(atk_weapon.mass)
     parry_p_a = m_a_striking * v_intent * CombatTiming.velocity_curve_factor(parry_progress)
     ```
   - For thrust/cut, keep `m_a = atk_weapon.mass` (whole weapon moves together; striking part = blade/point, mass fraction already in total).
   - **Simpler option:** Use striking part mass for ALL attack types when parts exist. Thrust uses point/blade mass; cut uses blade; blunt uses head. Consistent treatment.

2. **Block check** (`m_a_parry`, `m_d_parry`):
   - Keep as **total mass** for both. Block = "can you physically stop the weapon" — total vs total.
   - No change to how these are set.

3. **Partial parry velocity** (DefenseResolutionHandler):
   - Current: `v_reduced = (parry_p_a * glancing_factor) / m_a`
   - When `parry_p_a` uses striking mass, remaining momentum = parry_p_a - c_d is "striking part momentum." For rigid weapon, v_striking = v_whole. So `v_reduced = remaining_momentum / m_striking`.
   - **Change:** Pass `m_a_velocity` in the defense choice result: use striking mass when weapon has parts and parry_p_a used striking mass; else total mass.
   - In DefenseResolutionHandler, use `m_a_velocity` (not m_a_parry) for the v_reduced denominator when computing partial parry.
   - Add to choose_defense result: `m_a_velocity: float` = `atk_weapon.get_striking_part_mass_kg(contact_type)` when parts else `atk_weapon.mass`.
   - DefenseResolutionHandler receives dc and uses `dc.m_a_velocity` for v_reduced when present; else `dc.m_a_parry` (backward compat).

**Summary:** parry_p_a and v_reduced both use striking mass when weapon has parts; block check uses total mass.

---

#### Phase 4: Weapon.get_striking_part_mass_kg Logic

**File:** `weapon/Weapon.gd`

Implement `get_striking_part_mass_kg(contact_type: String)`:
1. If no parts, return `mass`.
2. Find part with `striking_for` containing contact_type.
3. Else infer: contact_type "stab" → part id "point" or "blade" or "spike"; "cut" → "blade"; "blunt" → "head" or "haft".
4. Return that part's `mass_fraction * mass`.
5. If no matching part, return `mass`.

Add `get_parry_part_mass_kg()`: return part with parry_part_id; else mass.

---

#### Phase 5: Defender×Attack Modifiers (Selective)

**File:** `combat/CombatConstants.gd` or `combat/DefenseChoiceResolver.gd`

Add lookup:
```gdscript
# def_weapon_type, attack_type -> multiplier
const PARRY_DEF_VS_ATK_MOD: Dictionary = {
    "DAGGER": {"stab": 0.9},
    "MACE": {"blunt": 1.05},
    "SPEAR": {"cut": 0.95}
}
```

In DefenseChoiceResolver, after computing parry_c_d, multiply by `PARRY_DEF_VS_ATK_MOD.get(def_weapon.weapon_type, {}).get(attack_type, 1.0)`.

---

#### Phase 6: Strong/Weak (Blade Weapons) — Optional Enhancement

For blade parrying parts, strong_fraction = handle_length / total_length. When attacker archetype is OVERHEAD (exposes weak), multiply parry_c_d by `(1 + STRONG_CONTACT_BONUS)` — replace or augment PARRY_STRONG_CONTACT_BY_ARCH. Defer to calibration; can be Phase 7.

---

### 5. Defense Choice Result Additions

Add to the dict returned by `DefenseChoiceResolver.choose_defense`:
- `m_a_velocity: float` — mass to use for v_reduced in partial parry. When atk_weapon has parts: `get_striking_part_mass_kg(contact_type)`. Else: `atk_weapon.mass`. Same as m_a_parry when no parts.

---

### 6. File Change Summary

| File | Changes |
|------|---------|
| `weapon/Weapon.gd` | Load parts, parry_part_id; add get_parry_part_mass_kg, get_striking_part_mass_kg, get_parry_contact_type, has_parts, get_parry_part_length_cm |
| `weapon/WeaponConstants.gd` | Add parts and parry_part_id to each weapon definition (§3.1) |
| `combat/CombatConstants.gd` | PARRY_CONTACT_MODIFIERS, PARRY_DEF_VS_ATK_MOD |
| `combat/DefenseChoiceResolver.gd` | _compute_parry_c_d uses parry part mass + contact mod; parry_p_a uses striking part mass; def_vs_atk mod |
| `combat/DefenseResolutionHandler.gd` | Use dc.m_a_velocity (striking mass) for v_reduced when partial parry; fallback to m_a_parry |
| `combat/PassiveParryContext.gd` | No structural change; get_parry_speed_m_s unchanged |
| `combat/CombatantEntityAccess.gd` | Verify get_weapon returns Weapon with new getters |

---

### 7. Move contact_type Resolution

DefenseChoiceResolver receives `attack_type` (move_id). Resolve contact_type via:
```gdscript
var move_def = WeaponConstants.get_move(attack_type)
var contact_type = move_def.get("contact_type", WeaponConstants.ATTACK_TYPE_CUT)
```

Use `contact_type` for get_striking_part_mass_kg and for PARRY_DEF_VS_ATK_MOD lookup.

---

### 8. Testing and Validation

1. **Legacy mode:** Disable parts (comment out in weapon defs) — parry and attack behavior should match current.
2. **Sword vs sword:** Parry capacity similar; blade part used.
3. **Spear defender:** Parry capacity uses shaft mass (~0.85 * 1.8 = 1.53 kg); ×0.88 contact mod.
4. **Mace defender vs blunt:** Parry capacity uses shaft mass; ×1.05 def_vs_atk for MACE+blunt.
5. **Mace attacker (overhead):** parry_p_a uses head mass (0.7 * 1.7 = 1.19 kg × v) — lower than current 1.7×v; tune if needed.
6. **Calibration:** Run combat logs; compare parry rate to HEMA 57–80% blade-blade. Adjust PARRY_CONTACT_MODIFIERS and PARRY_DEF_VS_ATK_MOD.

---

### 9. Order of Execution for Agent

1. Read `WEAPON_PART_LENGTH_PARRY_CONTACT_INVESTIGATION.md` (full doc).
2. Phase 1: Extend Weapon.gd and WeaponConstants.gd (schema + data).
3. Phase 2: Parry capacity in DefenseChoiceResolver + CombatConstants.
4. Phase 3: Attack momentum (parry_p_a) in DefenseChoiceResolver.
5. Phase 4: Implement get_striking_part_mass_kg and get_parry_part_mass_kg in Weapon.gd.
6. Phase 5: Defender×attack modifiers.
7. Phase 6 (optional): Strong/weak.
8. Test and calibrate.

---

### 10. Edge Cases

- **Weapon without parts:** All getters return total mass / default values.
- **Part mass_fraction not summing to 1.0:** Normalize or warn; document.
- **parry_part_id missing but parts present:** Use first parry_eligible part.
- **No parry_eligible part:** Fall back to largest mass part or legacy.
- **New weapons:** Add parts array and parry_part_id; follow same schema.

---

<a id="bind-riposte-weapon-type-investigation"></a>

## Source: `BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION.md`

## Bind Riposte: Weapon-Type Robustness Investigation

### Purpose

Make the bind riposte bonus **historically accurate** and **robust across weapon types** (sword, axe, mace, dagger, spear, future additions). An axe or mace does not thrust from bind; each weapon has its own natural follow-up.

---

### 1. Historical Context by Weapon

| Weapon | Natural Follow-Up from Bind | Source | Contact Type |
|--------|-----------------------------|--------|--------------|
| **Longsword** | Thrust (primary), cut (Wind) | Liechtenauer: Plough → thrust; Vier Versetzen | stab, cut |
| **Axe / Poleaxe** | Chop/cut, spike thrust (Le Jeu) | Le Jeu de la Hache: cuts, thrusts with spike | cut, stab |
| **Mace** | Strike (blunt) | No explicit treatise; percussion combat | blunt |
| **Dagger** | Thrust | Fiore, Talhoffer | stab |
| **Spear** | Thrust | Fiore | stab |

**Conclusion:** Each weapon has different "bind-favored" contact types. A single rule (e.g. "thrust only") fails for axe and mace.

---

### 2. Current System: What We Already Have

#### 2.1 Parry-Counter Moves (is_parry: true)

The move definitions already encode weapon-appropriate ripostes:

| Weapon | Parry Moves | Contact Type |
|--------|-------------|--------------|
| Sword | parry_thrust, parry_cut | stab, cut |
| Axe | parry_chop | cut |
| Mace | parry_strike | blunt |
| Dagger | parry_thrust_dagger | stab |
| Spear | parry_thrust_spear | stab |

These are the **explicit** "parry and counter" techniques. They are the natural follow-ups.

#### 2.2 Available Data at Riposte Time

- `atk` (defender): has `parry_was_bind`, `parry_against_id`
- `tgt` (target): the attacker who was parried
- `move_id` / `attack_type`: the chosen move (e.g. "parry_thrust", "oberhau", "parry_chop")
- Weapon: from `_EntityAccess.get_weapon(atk)` — has `get_contact_type(move_id)`, `get_available_attack_types()`
- Move definition: `WeaponConstants.get_move(move_id)` — has `contact_type`, `is_parry`

---

### 3. Implementation Approaches

#### Approach A: Move-Level Flag `bind_riposte_eligible`

Add `bind_riposte_eligible: true` to moves that are valid follow-ups from bind.

**Move definitions:**
```gdscript
"parry_thrust": { ..., "bind_riposte_eligible": true },
"parry_cut": { ..., "bind_riposte_eligible": true },
"thrust": { ..., "bind_riposte_eligible": true },
"parry_chop": { ..., "bind_riposte_eligible": true },
"overhead_chop": { ..., "bind_riposte_eligible": true },
"parry_strike": { ..., "bind_riposte_eligible": true },
"overhead_strike": { ..., "bind_riposte_eligible": true },
# etc.
```

**Logic:** Bonus applies when `WeaponConstants.get_move(move_id).get("bind_riposte_eligible", false)`.

**Pros:** Explicit per move; new weapons add flag to appropriate moves.  
**Cons:** Must remember to add flag when adding moves; some redundancy with is_parry.

---

#### Approach B: Infer from `is_parry` Moves (Weapon-Derived)

**Rule:** Bind riposte bonus applies when the chosen move's `contact_type` matches **any** of the defender's weapon's `is_parry` moves' contact types.

Example:
- Sword has parry_thrust (stab), parry_cut (cut) → both stab and cut get bonus
- Axe has parry_chop (cut) → only cut gets bonus
- Mace has parry_strike (blunt) → only blunt gets bonus

**Logic:**
```gdscript
static func _weapon_bind_riposte_contact_types(weapon, atk) -> Array:
    var contact_types := []
    if weapon == null or not weapon.has_method("get_available_attack_types"):
        return contact_types
    for move_id in weapon.get_available_attack_types():
        if WeaponConstants.is_parry_move(move_id):
            var ct = weapon.get_contact_type(move_id)
            if ct not in contact_types:
                contact_types.append(ct)
    return contact_types

# In AttackWindUpStarter:
var allowed = _weapon_bind_riposte_contact_types(weapon, atk)
if atk.get("parry_was_bind") and atk.get("parry_against_id") == target_id:
    if weapon.get_contact_type(attack_type) in allowed:
        wind_up_s *= PARRY_BIND_RIPOSTE_WINDUP_MULT
```

**Pros:** Fully data-driven; no new move fields. Adding a weapon with parry_chop automatically gives cut bonus.  
**Cons:** Relies on parry moves existing; weapon with no parry moves gets no bonus (correct).

---

#### Approach C: Weapon-Level Config `bind_riposte_contact_types`

Add to weapon definition:

```gdscript
"SWORD": { ..., "bind_riposte_contact_types": ["stab", "cut"] },
"AXE": { ..., "bind_riposte_contact_types": ["cut", "stab"] },
"MACE": { ..., "bind_riposte_contact_types": ["blunt"] },
"DAGGER": { ..., "bind_riposte_contact_types": ["stab"] },
"SPEAR": { ..., "bind_riposte_contact_types": ["stab"] },
```

**Logic:** Bonus when `weapon_def.get("bind_riposte_contact_types", []).has(contact_type)`.

**Pros:** Explicit per weapon; one place per weapon.  
**Cons:** New field; must maintain when adding weapons; duplicates info from parry moves.

---

#### Approach D: Move-Level `bind_riposte_mult` (Optional Override)

Moves can optionally specify a multiplier. Default: use Approach B when eligible, else no bonus.

```gdscript
"parry_thrust": { ..., "bind_riposte_mult": 0.6 },
"parry_chop": { ..., "bind_riposte_mult": 0.65 },
```

If present, use it; else fall back to Approach B with default constant.

**Pros:** Fine-grained tuning per move; e.g. parry_thrust gets stronger bonus than normal thrust.  
**Cons:** More fields; usually default is enough.

---

### 4. Recommendation: Approach B (Weapon-Derived from Parry Moves)

**Primary choice: Approach B.**

1. **Historically accurate:** Each weapon's parry moves already encode the correct follow-up (thrust for sword/dagger/spear, chop for axe, strike for mace).
2. **Robust for new weapons:** Add a weapon with `parry_slash` → slash gets bonus. No extra config.
3. **No schema bloat:** No new fields in weapon or move definitions.
4. **Fallback:** Weapon with no parry moves (e.g. improvised) gets no bonus — correct.

**Edge cases:**
- **Axe spike thrust:** Axe has `spike_thrust` but no `parry_spike`. So spike wouldn't get bonus by B. Le Jeu does have thrust from bind. Option: add `parry_spike` to axe, or add `bind_riposte_contact_types: ["cut", "stab"]` for axe only (hybrid with C for that weapon).
- **Sword normal thrust vs parry_thrust:** Both have contact_type stab; parry_thrust is is_parry. Sword has parry_thrust → stab is in allowed set. So normal thrust gets bonus too. Historically fine: thrust from bind is the action, whether you call it parry_thrust or thrust.

---

### 5. Hybrid for Edge Cases

Use B as default. For weapons with multiple valid follow-ups not all represented by parry moves (e.g. axe spike from bind), add optional weapon override:

```gdscript
# In weapon def, optional:
"bind_riposte_contact_types": ["cut", "stab"]  # overrides inferred from parry moves
```

Logic: if weapon has `bind_riposte_contact_types`, use it; else infer from is_parry moves. New weapons can use either.

---

### 6. Implementation Checklist

1. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6` to CombatConstants.
2. Add helper `_get_bind_riposte_contact_types(weapon)` that:
   - Returns `weapon_def["bind_riposte_contact_types"]` if present
   - Else builds from weapon's is_parry moves' contact_type
3. In AttackWindUpStarter, after computing wind_up_s:
   - If `atk.get("parry_was_bind")` and `atk.get("parry_against_id") == target_id`:
     - Get `contact_type` from weapon for chosen move_id
     - If contact_type in allowed set: apply multiplier
4. Clear parry_was_bind/parry_against_id on action (already done).

---

### 7. Summary Table

| Approach | Historical Accuracy | Robustness | Schema Change | Best For |
|----------|---------------------|------------|---------------|----------|
| A: Move flag | High | Manual per move | Move def | Explicit control |
| **B: Infer from parry** | **High** | **Automatic** | **None** | **Default** |
| C: Weapon config | High | Manual per weapon | Weapon def | Override when needed |
| D: Move mult | High | Per-move tuning | Move def | Fine-tuning |
| **B + C hybrid** | **High** | **Flexible** | **Optional** | **Production** |

---

### References

- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md
- Le Jeu de la Hache (Wiktenauer, ARMA)
- WeaponConstants.gd (move definitions, is_parry)

---

<a id="bind-riposte-windup-physics-investigation"></a>

## Source: `BIND_RIPOSTE_WINDUP_PHYSICS_INVESTIGATION.md`

## Bind Riposte Wind-Up: Physics-Based Implementation Investigation

### Purpose

Explore how bind riposte wind-up reduction should be implemented, with focus on **what is physically possible** for each weapon from a bind position. Different parry parts (blade, shaft, haft) and different attack types (thrust, cut, blunt) have fundamentally different mechanics.

---

### 1. Physics of the Bind by Parry Part

#### 1.1 Blade-on-Blade Bind (Sword, Dagger)

**Parry part:** Blade. **Bind geometry:** Both blades in contact; defender's forte controls attacker's foible.

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Thrust** | Extension — point already in line; blade slides forward along/off opponent's blade | **Minimal** — no swing, just extend. Liechtenauer: "thrust from Plough." |
| **Cut (wind)** | Roll blade along opponent's blade (Vier Versetzen, Winden) | **Moderate** — blade rotation, but opponent's blade guides. Faster than cut from idle. |
| **Cut (disengage)** | Disengage, then cut from new angle | **Full** — must break contact and swing. Same as normal cut. |

**Sources:** Liechtenauer Part 5 (Binds), HEMA 101 (Vier Versetzen, thrust from bind).

---

#### 1.2 Shaft-on-Blade Bind (Spear, Mace)

**Parry part:** Shaft. **Bind geometry:** Defender's shaft met attacker's blade. Contact is shaft, not blade.

##### Spear (shaft parries)

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Thrust** | Point is forward; extend arms. Shaft is already in line. | **Minimal** — same as sword thrust from bind. Fiore: spear thrust after parry. |
| **Slash** | Spearhead must swing — blade is at tip, shaft was in contact | **Moderate** — rotate shaft to bring head to target. |
| **Pole swing** | Heavier motion; blunt strike with shaft | **Significant** — full swing. |

##### Mace (shaft parries)

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Strike (overhead/side/direct)** | Head is at end of shaft. Shaft was in contact; head was not. | **Significant** — must swing the head into the opponent. Heavy mass at end of lever. |
| **Thrust with poll** | Some maces have back spike; extend | **Minimal** — if weapon has thrust option. *Current mace has no thrust move.* |

**Conclusion:** Spear thrust from bind = fast. Mace strike from bind = slow (must swing head into position). A single "bind riposte mult" fails to capture this.

---

#### 1.3 Haft-on-Blade Bind (Axe)

**Parry part:** Haft. **Bind geometry:** Defender's haft met attacker's blade. Axe blade and spike are at the ends.

| Follow-up | Physical Motion | Wind-up Required |
|-----------|-----------------|------------------|
| **Spike thrust** | Spike is forward; extend like spear | **Minimal** — Le Jeu de la Hache: thrust with spike from bind. |
| **Chop (overhead/diagonal)** | Blade at end; must swing head into target | **Moderate** — rotate axe to bring blade to target. Faster than from idle (weapon already moving, opponent's blade gives reference). |
| **Poll strike** | Back of head; similar to chop | **Moderate** — swing required. |

**Conclusion:** Axe spike thrust = fast. Axe chop = moderate benefit (less than thrust, more than mace strike).

---

### 2. Summary: Physics-Derived Wind-Up Multipliers

| Parry Part | Contact Type | Motion from Bind | Suggested Mult | Rationale |
|------------|--------------|------------------|----------------|-----------|
| Blade | stab | Extend | **0.50–0.55** | Minimal — point in line |
| Blade | cut | Wind along blade | **0.70–0.80** | Moderate — roll, not full swing |
| Shaft (spear) | stab | Extend | **0.50–0.55** | Same as blade thrust |
| Shaft (spear) | cut | Rotate shaft | **0.75–0.85** | Moderate |
| Shaft (mace) | blunt | Swing head | **0.85–0.95** | Significant — head must travel |
| Haft (axe) | stab | Extend spike | **0.50–0.55** | Same as thrust |
| Haft (axe) | cut | Swing blade | **0.75–0.85** | Moderate — blade at end |

**Key insight:** The multiplier should depend on **contact_type** (stab/cut/blunt), not just weapon. Stab = extend = fast. Cut = wind or short swing = moderate. Blunt = full swing of mass = slow.

---

### 3. Implementation Approaches

#### Approach A: Uniform Multiplier (Simplest)

**Rule:** Bind riposte always gets `wind_up_s *= 0.6` when attacking parry_against_id.

**Pros:** Trivial; one constant.  
**Cons:** Mace strike gets same bonus as sword thrust — physically wrong. Dagger (fastest) and mace (slowest) treated identically.

---

#### Approach B: Contact-Type Multipliers

**Rule:** Multiplier depends on the chosen move's `contact_type`:

```gdscript
const PARRY_BIND_RIPOSTE_MULT_BY_CONTACT: Dictionary = {
    "stab": 0.55,   # Extend — minimal wind-up
    "cut": 0.78,    # Wind or moderate swing
    "blunt": 0.90   # Full swing of mass
}
```

**Eligibility:** Only when move's contact_type is in weapon's bind-riposte-eligible set (from parry moves, or weapon override for axe spike).

**Pros:** Physically grounded. Stab fast, blunt slow. One table.  
**Cons:** Spear slash vs axe chop both "cut" — spear might deserve slightly better (lighter). Mace 0.9 is still a benefit; some may argue mace gets 1.0 (no bonus).

---

#### Approach C: Contact-Type + Weapon-Type Overrides

**Base:** Approach B. **Override:** Per-weapon constants for edge cases.

```gdscript
# Base by contact_type
const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55
const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78
const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90

# Optional weapon overrides (weapon_id -> mult override when in bind)
# Mace: shaft bind, blunt only — weakest benefit
const PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE: Dictionary = {
    "MACE": 0.92,   # Heavier swing from shaft bind
    "DAGGER": 0.50  # Lightest weapon, thrust dominant — slightly faster
}
```

**Pros:** Fine-grained. Dagger can be fastest; mace slowest.  
**Cons:** More constants; must maintain per weapon.

---

#### Approach D: Parry-Part + Contact-Type Matrix

**Rule:** Multiplier from `(parry_part_id, contact_type)`:

|            | stab | cut | blunt |
|------------|------|-----|-------|
| blade      | 0.52 | 0.75| —     |
| shaft      | 0.54 | 0.80| 0.90  |
| haft       | 0.53 | 0.78| —     |

*Blade/haft don't have blunt as primary bind follow-up; those weapons use cut or stab.*

**Pros:** Most physically detailed.  
**Cons:** Sparse matrix; most cells unused. Overkill for 5 weapons.

---

#### Approach E: Archetype-Based (Wind/Strike Characteristics)

**Rule:** Use archetype's existing `windup_multiplier` as base; bind applies an additional scale.

- **stab** archetype: already quick wind-up (1.0). Bind makes it 0.55× effective.
- **slash** archetype: bind makes it 0.78×.
- **heavy_blunt** archetype: bind makes it 0.90×.

Same as B, but keyed by archetype instead of contact_type. For our weapons, contact_type and archetype align (stab→stab, cut→slash/overhead, blunt→heavy_blunt/pommel).

**Pros:** Reuses existing archetype data.  
**Cons:** Archetype ≠ contact_type for all moves (e.g. slash could be ARCHETYPE_SLASH or ARCHETYPE_OVERHEAD). contact_type is more direct.

---

#### Approach F: Move-Level `bind_riposte_mult` (Optional Override)

**Rule:** Moves can specify `bind_riposte_mult: 0.5`. If present, use it; else use Approach B from contact_type.

```gdscript
"parry_thrust": { ..., "bind_riposte_mult": 0.52 },
"parry_chop": { ..., "bind_riposte_mult": 0.78 },
"parry_strike": { ..., "bind_riposte_mult": 0.90 },
"thrust": { ..., "bind_riposte_mult": 0.52 },  # Normal thrust from bind
```

**Pros:** Maximum tuning per move. parry_thrust can differ from thrust if desired.  
**Cons:** Schema bloat; many moves need the field; redundancy with contact_type.

---

#### Approach G: Physics Formula (Mass + Contact Type)

**Rule:** Base mult from contact_type; scale by weapon mass (lighter = faster from bind).

```gdscript
var base: float = PARRY_BIND_RIPOSTE_MULT_BY_CONTACT[contact_type]
var mass_kg: float = weapon.mass
var mass_factor: float = lerpf(1.05, 0.95, (mass_kg - 0.3) / (1.8 - 0.3))  # Dagger 1.05, Spear 0.95
wind_up_s *= base * mass_factor
```

**Pros:** Dagger naturally fastest; spear/mace slowest.  
**Cons:** Mass already affects wind-up via archetype; risk of double-counting. Added complexity.

---

### 4. Eligibility: Which Moves Get the Bonus?

From BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION: use parry moves to infer eligible contact types per weapon.

| Weapon | Parry Moves | Eligible Contact Types |
|--------|-------------|------------------------|
| Sword  | parry_thrust (stab), parry_cut (cut) | stab, cut |
| Axe    | parry_chop (cut) | cut. *Add stab for spike_thrust — Le Jeu has thrust from bind.* |
| Mace   | parry_strike (blunt) | blunt |
| Dagger | parry_thrust_dagger (stab) | stab |
| Spear  | parry_thrust_spear (stab) | stab. *Add cut for spear_slash if desired.* |

**Axe edge case:** Axe has spike_thrust but no parry_spike. Add optional `bind_riposte_contact_types: ["cut", "stab"]` to axe weapon def to include spike.

---

### 5. Recommendation

#### Primary: **Approach B (Contact-Type Multipliers)** + **Approach C (Weapon Overrides for Edge Cases)**

1. **Constants:**
   ```gdscript
   const PARRY_BIND_RIPOSTE_MULT_STAB := 0.55    # Extend — minimal
   const PARRY_BIND_RIPOSTE_MULT_CUT := 0.78     # Wind or moderate swing
   const PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90   # Full swing
   # Optional: PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE for MACE 0.92, DAGGER 0.50
   ```

2. **Eligibility:** Infer from weapon's parry moves (Approach B from BIND_RIPOSTE doc). Axe: add `bind_riposte_contact_types: ["cut", "stab"]` in weapon def for spike.

3. **Logic in AttackWindUpStarter:**
   - If `atk.get("parry_was_bind")` and `atk.get("parry_against_id") == target_id`:
     - Get `contact_type` from weapon for chosen move_id.
     - If contact_type in weapon's eligible set:
       - mult = weapon_override if present, else contact_type mult.
       - wind_up_s *= mult.

#### Variant: **Approach B Only** (No weapon overrides)

Use 0.55 / 0.78 / 0.90 for stab / cut / blunt. Simpler; physically sound. Add weapon overrides only if tuning demands it.

---

### 6. Implementation Checklist

1. **CombatConstants.gd:**
   - `PARRY_BIND_RIPOSTE_MULT_STAB := 0.55`
   - `PARRY_BIND_RIPOSTE_MULT_CUT := 0.78`
   - `PARRY_BIND_RIPOSTE_MULT_BLUNT := 0.90`
   - Optional: `PARRY_BIND_RIPOSTE_MULT_BY_CONTACT` dict or `PARRY_BIND_RIPOSTE_WEAPON_OVERRIDE`

2. **Helper** `_get_bind_riposte_mult(weapon, move_id, contact_type) -> float`:
   - If weapon override present, return it.
   - Else return contact_type mult (stab/cut/blunt).

3. **Helper** `_get_bind_riposte_contact_types(weapon) -> Array`:
   - From weapon def `bind_riposte_contact_types` if present.
   - Else from weapon's is_parry moves' contact_type.

4. **AttackWindUpStarter.start:**
   - After `wind_up_s *= trans_mult`, before leg/perf/agility:
   - If bind conditions met and contact_type eligible: `wind_up_s *= bind_mult`.

5. **WeaponConstants / Weapon def (optional):** Axe: `"bind_riposte_contact_types": ["cut", "stab"]`.

---

### 7. Comparison Table

| Approach | Physical Accuracy | Effort | Schema Change | Best For |
|----------|-------------------|--------|---------------|----------|
| A: Uniform | Low | Minimal | None | Quick prototype |
| **B: Contact-type** | **High** | **Low** | **None** | **Default** |
| C: + Weapon override | Very High | Low | Optional weapon field | Fine-tuning |
| D: Matrix | Very High | Medium | None | Max accuracy |
| E: Archetype | High | Low | None | Alternative to B |
| F: Move-level | Very High | High | Move def | Per-move control |
| G: Mass formula | High | Medium | None | Mass-aware |

---

### References

- PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md
- BIND_RIPOSTE_WEAPON_TYPE_INVESTIGATION.md
- WeaponConstants.gd (moves, parry_part_id, contact types)
- Liechtenauer (Binds, thrust from bind)
- Le Jeu de la Hache (spike thrust from haft contact)
- Fiore (spear thrust after parry)

---

<a id="part-3-hard-bind-riposte-implementation-investigation"></a>

## Source: `PART_3_HARD_BIND_RIPOSTE_IMPLEMENTATION_INVESTIGATION.md`

## Part 3: Hard Bind Riposte — Implementation Investigation

### Purpose

Investigate **multiple implementation methods** for giving the defender a riposte advantage when they achieve a **hard bind** (parry_control ≥ threshold) vs a **deflect** (blades separate). HEMA: hard bind = blades in contact, defender controls = can thrust immediately; deflect = new action, full wind-up.

**Prerequisites:** Part 1 and 2 implemented. Defender has `parry_was_bind` and `parry_against_id` after parry_deflect.

---

### 1. Current State

| Data | Where | When Cleared |
|------|-------|--------------|
| `parry_was_bind` | tgt (defender) | AttackWindUpStarter.start (when defender acts) |
| `parry_against_id` | tgt | AttackWindUpStarter.start |

Defender state after parry_deflect:
- `state = WAITING`, gauge unchanged
- `guard_line` = attack line (contact point)
- Attacker: `state = RECOVERING`, gauge = 0

Implicit riposte priority: defender keeps gauge; attacker recovers from 0. Defender often reaches turn_ready first.

---

### 2. Method A: Bind Reduces Riposte Wind-Up

#### Concept

When defender’s next action is an attack vs `parry_against_id` and `parry_was_bind` is true, apply a wind-up multiplier (e.g. 0.5× or 0.7×).

#### Hook Point

**AttackWindUpStarter.start** — after computing `wind_up_s`, before applying `trans_mult`:

```gdscript
# After: wind_up_s *= trans_mult
# Add:
if tgt != null and tgt.get("parry_was_bind", false) and tgt.get("parry_against_id", -1) == target_id:
    wind_up_s *= CombatConstants.PARRY_BIND_RIPOSTE_WINDUP_MULT  # e.g. 0.6
```

#### Files

- `AttackWindUpStarter.gd`
- `CombatConstants.gd` (new constant)

#### Pros

- Mechanically clear: bind → faster riposte
- Fits HEMA “thrust from bind”
- Small code change

#### Cons

- Reduces wind-up for any attack, not just thrust
- Need to pick multiplier (0.5 = half time; 0.7 = 30% reduction)
- If defender attacks someone else, no bonus (correct)

#### Variant A1: Only for Thrust

Check `attack_type == ATTACK_TYPE_STAB` before applying. More HEMA-accurate (thrust from bind).

#### Variant A2: Scale by parry_control

Store `parry_control` on defender; use `lerp(1.0, 0.5, (parry_control - threshold) / (1.0 - threshold))` for mult.

---

### 3. Method B: Gauge Bonus for Bind

#### Concept

On parry_deflect with bind, set defender gauge to 100 (or add a fixed bonus). Defender goes turn_ready immediately; attacker still in recovery.

#### Hook Point

**AttackResultApplier** (parry_deflect branch):

```gdscript
if tgt != null:
    ...
    if tgt.get("parry_was_bind", false):
        tgt.gauge = 100.0
        # Or: tgt.gauge = min(100, tgt.gauge + 50)
```

#### Files

- `AttackResultApplier.gd`

#### Pros

- Seamless: defender acts first
- No changes to wind-up logic
- Strongly rewards bind

#### Cons

- Defender may get multiple turns in a row if attacker is slow
- Balance: bind could dominate exchanges
- Needs optional cooldown (e.g. can’t get bind bonus again for N seconds)

#### Variant B1: Partial Gauge Bonus

`tgt.gauge = min(100, tgt.gauge + 40)` — softens double-turn risk.

#### Variant B2: Gauge Bonus Only When Below Threshold

If `tgt.gauge >= 80`, no bonus. Prevents stacking with already-high gauge.

---

### 4. Method C: Separate “Riposte from Bind” Move

#### Concept

Add `riposte_thrust` (or similar) to weapons, available only when defender has `parry_was_bind` and `parry_against_id == target_id`. Move has 0 or minimal wind-up.

#### Hook Points

1. **AvailableActionsBuilder** — add riposte action when bind conditions met
2. **WeaponConstants** — add move definition with `is_riposte: true`, `wind_up_s: 0.1`
3. **AttackWindUpStarter** — treat riposte moves with reduced/minimal wind-up

#### Files

- `AvailableActionsBuilder.gd`
- `WeaponConstants.gd`
- `AttackWindUpStarter.gd`
- UI (if riposte shows differently)

#### Pros

- Clear distinction between normal attack and riposte
- Matches HEMA “thrust from bind” as a dedicated technique
- Tuning isolated to riposte move

#### Cons

- New move, weapon config, and UI
- Must handle “no thrust weapon” (e.g. blunt-only) — fallback to cut or no riposte?
- More branching in action building

#### Variant C1: Riposte Uses Existing Thrust

Don’t add a new move. When bind + target_id match + weapon has thrust, treat the chosen thrust move as having 0 wind-up. Implement via a flag in `options` passed to `resolve_action`.

---

### 5. Method D: Guard Transition Multiplier (Existing Logic + Bind)

#### Concept

Guard transition cost = `1 + (1 - alignment) * GUARD_TRANSITION_COST_SCALE`. After bind, defender’s guard = attack line; thrust in same line has alignment 1 → minimal cost. The difference from deflect: after deflect, attacker’s blade is elsewhere; defender’s alignment to attacker’s guard is lower. So bind already gives better effective alignment.

**Tweak:** When bind + target match, apply extra `guard_transition_mult = 0.5` (or similar) so wind-up is halved for that transition.

#### Hook Point

**AttackWindUpStarter** — when computing `trans_mult`:

```gdscript
var bind_bonus: float = 1.0
if tgt.get("parry_was_bind", false) and tgt.get("parry_against_id", -1) == target_id:
    bind_bonus = CombatConstants.PARRY_BIND_GUARD_TRANSITION_MULT  # 0.5
trans_mult = (1.0 + (1.0 - align) * CombatConstants.GUARD_TRANSITION_COST_SCALE) * bind_bonus
```

#### Files

- `AttackWindUpStarter.gd`
- `CombatConstants.gd`

#### Pros

- Uses existing alignment/transition model
- Small change
- Bind advantage is “you’re already in line”

#### Cons

- Effect depends on alignment; if defender was already well-aligned, bonus is small
- Less obviously “riposte from bind” than Methods A/B

---

### 6. Method E: Turn Order Override

#### Concept

After parry_deflect with bind, next `turn_ready` is forced to defender (if they have actions). Attacker’s turn_ready is skipped until defender acts or a timeout.

#### Hook Points

1. **CombatStateHandlers** — `process_waiting` / `process_recovering` — queue or flag “defender acts next”
2. **CombatManager** / **BattleScene** — `turn_ready` handling — respect “riposte pending” before giving attacker a turn

#### Files

- `CombatStateHandlers.gd`
- `CombatManager.gd` or `BattleScene.gd`
- Possibly `TurnReadyHandler.gd`

#### Pros

- Guarantees defender acts first after bind
- Matches HEMA tempo strongly

#### Cons

- Larger flow change
- Turn ordering logic more complex
- Need to handle “defender has no valid actions”

---

### 7. Comparison Table

| Method | Effort | HEMA Accuracy | Balance Risk | Clearest Mechanic |
|-------|--------|---------------|--------------|-------------------|
| A: Wind-up mult | Low | High | Low | Yes |
| B: Gauge bonus | Low | High | Medium | Yes |
| C: Riposte move | High | Very High | Low | Yes |
| D: Guard transition | Low | Medium | Low | Partial |
| E: Turn override | High | Very High | Medium | Yes |

---

### 8. Recommended Order

1. **Method A** — Minimal change, clear effect. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6`.
2. **Method A1** (thrust only) — If thrust-specific behavior is desired.
3. **Method B** (with variant B1) — If gauge-based advantage is preferred and double-turn is acceptable or mitigated.
4. **Method C** — If a dedicated riposte move is worth the extra complexity.

---

### 9. Implementation Checklist (Method A)

1. Add `PARRY_BIND_RIPOSTE_WINDUP_MULT := 0.6` to CombatConstants.
2. In AttackWindUpStarter.start, after `wind_up_s *= trans_mult`:
   - If `atk.get("parry_was_bind") and atk.get("parry_against_id") == target_id`: multiply wind_up_s by constant.
3. Confirm `parry_was_bind` and `parry_against_id` are set in AttackResultApplier (already done).
4. Confirm they are cleared when defender acts (already done in AttackWindUpStarter).

---

### References

- HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md (Part 3)
- HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md (riposte priority)

---

<a id="hema-vs-system-bind-deflect-comparison"></a>

## Source: `HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md`

## HEMA vs System: Bind vs Deflect Comparative Analysis

### Purpose

Compare **HEMA blade clash mechanics and outcomes** (Liechtenauer, HEMA 101, Sword STEM) to **this system's implementation**, identifying alignments and gaps in how bind vs deflection work.

---

### 1. HEMA Blade Clash Mechanics

#### 1.1 Contact Quality (HEMA 101: Binds and Winds)

| Aspect | HEMA Concept | Outcome |
|--------|--------------|---------|
| **Good parry** | Defender catches attacker's weak on defender's strong; Overbind; Vier Versetzen (same cut parries same cut) | **Hard bind** — blade stays in line, defender controls |
| **Bad parry** | Blades meet "dead centre" or poorly; defender couldn't establish strong-on-weak | **Soft bind** or **deflection** — blade sheds, no control |
| **Decisive parry** | Defender had plenty of capacity; proper setup; good geometry | **Bind** — blade held in line |
| **Marginal parry** | Defender barely stopped it; late or poorly positioned | **Deflect** — blade knocked aside |
| **Blocking parry** | Point held high/side (Liechtenauer discourages); can still form strong contact | Can bind but geometry less ideal |

#### 1.2 Geometry (HEMA 101: Parries, Vier Versetzen)

| Geometry | HEMA Outcome | Blade Position |
|----------|--------------|----------------|
| **Same line** (Oberhau vs Oberhau) | Both end in Plough | **Bind** — blades in same line |
| **Same line** (Unterhau vs Unterhau) | Both end in Ox | **Bind** — blades in same line |
| **Adjacent** (e.g. high attack, left parry) | Lateral shed — cut "behind" incoming blade | **Deflect** — blade goes to other adjacent (~45°) |
| **Opposite** (e.g. high attack, low block) | Strong block can drive blade through | **Deflect** — blade to opposite (~90°) or partial |
| **Thrust** | Almost always deflected (point directed offline) | **Deflect** — rarely full stop/bind |

#### 1.3 Factors Affecting Bind vs Deflect (HEMA)

| Factor | Effect on bind vs deflect |
|--------|---------------------------|
| **Strong-on-weak contact** | Good = bind; poor = deflect |
| **Margin (defender capacity vs attack)** | High margin = control = bind; low = deflect |
| **Alignment** | Good alignment ≈ proper contact = bind |
| **Setup time** | More time = better parry = bind; late = deflect |
| **Off-balance** | Poor positioning = worse contact = deflect |
| **Attack type** | Thrust deflects more; cut can bind |
| **Mass** | Heavy vs light affects who controls (Fiore) |

---

### 2. System Mechanics (Current Implementation)

#### 2.1 Parry Outcomes

| Outcome | Condition | Where |
|---------|-----------|-------|
| **parry_deflect** | `is_block_parry` AND `c_d_final >= parry_p_a * 1.08` | DefenseResolutionHandler |
| **parry_partial** | Parry chosen but not full stop | DefenseResolutionHandler |
| **parry_deflect** → attacker blade position | Recovery completes; `set_guard_deflected` called | CombatStateHandlers → GuardLineUpdater |

#### 2.2 Blade Position After parry_deflect (GuardLineUpdater)

| Condition | System outcome |
|-----------|----------------|
| `attack_line == defender_guard_line` | **Bind** — blade stays in attack line |
| Defender adjacent (45°) | **Lateral** — deflect to other adjacent (45°) |
| Defender opposite (90°) | **Strong block** — deflect to opposite (90°) |
| No `defender_guard_line` | Fallback: opposite line |

#### 2.3 Data Used for Deflection Decision

| Data | Used? | Where |
|------|-------|-------|
| `defender_guard_line` | ✓ Yes | Stored at parry, passed to `set_guard_deflected` |
| `effective_attack_line` | ✓ Yes | From diagonal roll |
| `parry_p_a`, `parry_c_d` | ✗ No | Computed but not passed |
| `alignment` | ✗ No | Used for parry capacity, not deflection |
| `parry_readiness` | ✗ No | Not passed |
| `parry_off_balance` | ✗ No | Not passed |
| `late_parry` | ✗ No | Not passed |
| `attack_type` | ✗ No | Not passed |
| `is_block_parry` | ✗ No | Only determines full_stop path, not deflection outcome |

---

### 3. Comparative Tables

#### 3.1 Bind vs Deflect Decision

| Criterion | HEMA | System | Match? |
|-----------|------|--------|--------|
| **Same line → bind** | Oberhau vs Oberhau → Plough (bind) | Same line → bind | ✓ Yes |
| **Geometry determines direction** | Adjacent shed → lateral; opposite block → through | Adjacent → 45°; opposite → 90° | ✓ Yes |
| **Contact quality affects bind/deflect** | Good parry → bind; bad → deflect | **Not modeled** — geometry only | ✗ No |
| **Margin (decisive vs marginal)** | High margin → bind; low → deflect | **Not modeled** | ✗ No |
| **Alignment affects outcome** | Good alignment ≈ strong-on-weak → bind | Affects parry capacity only; not deflection | ⚠ Partial |
| **Late parry** | Less setup → worse contact → deflect | **Not passed** to deflection | ✗ No |
| **Off-balance** | Poor positioning → deflect | **Not passed** to deflection | ✗ No |
| **Thrust vs cut** | Thrust deflects more; cut can bind | **Not distinguished** in deflection | ✗ No |

#### 3.2 Deflection Magnitude (45° vs 90°)

| Criterion | HEMA | System | Match? |
|-----------|------|--------|--------|
| **Adjacent geometry max 45°** | Lateral shed can't drive blade 90° | Adjacent defender → never opposite | ✓ Yes |
| **Severity affects magnitude** | Strong clash → more displacement | **Not modeled** — always full geometry outcome | ✗ No |
| **Thrust deflects easier** | Point diverts with lateral force | **Not modeled** in deflection | ✗ No |
| **Blunt deflects harder** | Momentum-based | **Not modeled** in deflection | ✗ No |

#### 3.3 Parry Resolution Path

| Aspect | HEMA | System | Match? |
|--------|------|--------|--------|
| **Full stop requires block** | Block (head-on) can fully stop; redirect sheds | `parry_deflect` only when `is_block_parry` | ✓ Yes |
| **Redirect = partial** | Redirect parry typically sheds (deflect) or partial | `parry_partial` when not block or c_d insufficient | ✓ Yes |
| **Same cut parries same cut** | Oberhau parries Oberhau | Same line (alignment 1) → bind | ✓ Yes |
| **Strong-on-weak** | Defender strong on attacker weak | Alignment (cos θ) as proxy; affects parry_c_d | ⚠ Partial |

#### 3.4 Defender Blade Position

| Aspect | HEMA | System | Match? |
|--------|------|--------|--------|
| **Defender ends where contact was** | Blade meets attack in line of contact | `set_guard_from_move(tgt, move_id, eff_line)` | ✓ Yes |
| **Defender in attack line after parry** | Both blades in contact line | tgt ends in `eff_line` (attack line) | ✓ Yes |

---

### 4. Gap Summary

#### Aligned with HEMA ✓

1. **Same-line → bind** — Oberhau vs Oberhau, blade stays in line.
2. **Geometry-based direction** — Adjacent → lateral (45°); opposite → strong block (90°).
3. **Geometry cap** — Adjacent defender never produces 90° deflection.
4. **Block vs redirect** — Only block parries can full-stop (parry_deflect).
5. **Defender blade** — Ends in attack line where contact occurred.
6. **4-line model** — Maps to Liechtenauer high/low/left/right.

#### Not Aligned / Gaps ✗

1. **Contact quality** — System does not distinguish good vs bad parry for bind/deflect.
2. **Margin vs decisiveness** — A marginal full-stop (c_d ≈ 1.08 × p_a) is treated identically to a decisive one (c_d >> p_a).
3. **Late parry** — Reflexive parries are not more likely to deflect.
4. **Off-balance** — Defender off-balance does not increase deflection likelihood.
5. **Parry readiness** — Defender readiness does not affect blade outcome.
6. **Severity/magnitude** — Deflection is always full (45° or 90°); no partial deflection by clash strength.
7. **Attack type** — Thrust vs blunt vs cut do not modulate deflection in guard update.
8. **Soft vs hard bind** — Both result in same line; system does not model control quality for follow-up (e.g. riposte priority).

#### Partially Aligned ⚠

1. **Alignment** — Used for parry capacity (parry_c_d × alignment) but not for bind/deflect outcome.
2. **Strong-on-weak** — Alignment as proxy; no explicit blade contact-point model.

---

### 5. Outcome Comparison by Scenario

#### Scenario A: Oberhau vs Oberhau (same line), decisive parry

| | HEMA | System |
|---|------|--------|
| **Outcome** | Hard bind; blades in Plough | Bind; blade stays in high |
| **Match** | ✓ |

#### Scenario B: Oberhau vs Oberhau (same line), marginal parry

| | HEMA | System |
|---|------|--------|
| **Outcome** | Soft bind or deflect (blade may shed) | Bind; blade stays in high |
| **Match** | ✗ — System always binds for same-line regardless of margin |

#### Scenario C: High attack, left parry (adjacent), decisive

| | HEMA | System |
|---|------|--------|
| **Outcome** | Lateral shed to right (or controlled deflection) | Deflect to right (45°) |
| **Match** | ✓ |

#### Scenario D: High attack, left parry (adjacent), marginal

| | HEMA | System |
|---|------|--------|
| **Outcome** | Might deflect more (uncontrolled) or less (weak contact) | Deflect to right (45°) |
| **Match** | ⚠ — System always full 45°; HEMA allows variation |

#### Scenario E: High attack, low block (opposite), decisive

| | HEMA | System |
|---|------|--------|
| **Outcome** | Strong block; blade driven to low (90°) | Deflect to low (90°) |
| **Match** | ✓ |

#### Scenario F: High attack, low block (opposite), marginal

| | HEMA | System |
|---|------|--------|
| **Outcome** | Might only partially deflect (45° to side) or full 90° | Deflect to low (90°) |
| **Match** | ✗ — System always full 90° for opposite; no partial |

#### Scenario G: Thrust parried

| | HEMA | System |
|---|------|--------|
| **Outcome** | Usually deflected (point offline); rarely full stop | parry_deflect only if block; geometry applies |
| **Match** | ⚠ — Thrust gets same deflection logic as cut |

#### Scenario H: Late parry, same line

| | HEMA | System |
|---|------|--------|
| **Outcome** | Reflexive; poorer contact; more likely deflect | Bind (same as timely parry) |
| **Match** | ✗ — Late parry not distinguished |

---

### 6. Recommendations for Better HEMA Alignment

#### Priority 1: Margin/Control for Bind vs Deflect

- Pass `parry_control` (or components) from parry resolution to `set_guard_deflected`.
- When `parry_control` high: bind (blade stays in line) even for different-line geometry.
- When low: use geometry for deflect (current behavior).
- **Closes gap:** Scenarios B, H.

#### Priority 2: Severity for Deflection Magnitude

- For opposite-defender case: use clash severity to choose adjacent (45°) vs opposite (90°).
- Light clash → adjacent; heavy → opposite.
- **Closes gap:** Scenario F.

#### Priority 3: Late Parry, Off-Balance, Readiness

- Include in `parry_control` or as separate modifiers.
- Late parry / off-balance / low readiness → lower control → more deflect.
- **Closes gap:** Scenario H; improves B, D.

#### Priority 4: Attack Type Modulation

- Thrust: easier to deflect (lower threshold for 90° when opposite).
- Blunt: harder (higher threshold).
- **Closes gap:** Scenario G.

---

### 7. Summary Table

| Mechanic | HEMA | System | Gap |
|----------|------|--------|-----|
| Same-line bind | ✓ | ✓ | None |
| Geometry direction (adjacent/opposite) | ✓ | ✓ | None |
| Geometry cap (adjacent ≠ opposite) | ✓ | ✓ | None |
| Contact quality → bind/deflect | ✓ | ✗ | **High** |
| Margin → bind/deflect | ✓ | ✗ | **High** |
| Late/off-balance/readiness | ✓ | ✗ | Medium |
| Severity → magnitude | ✓ | ✗ | Medium |
| Attack type (thrust/blunt) | ✓ | ✗ | Low |
| Defender position | ✓ | ✓ | None |

---

### References

- HEMA 101: Liechtenauer Part 5 (Parries), Part 9 (Binds and Winds)
- Sword STEM: Vector transformations
- Project: PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md, HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md, HEMA_VS_KCD_SOURCE_ANALYSIS.md

---
