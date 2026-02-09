# Pain and Consciousness: Framework Comparison and Implementation Options

This document summarizes how **FallenFramework** (E:\FallenFramework\fallen-framework) handles pain and consciousness, then compares **three ways** to implement similar behavior in **fallen-paths** (CoreEntity + CombatManager).

---

## 1. How FallenFramework Does It

### 1.1 Data and flow

- **Consciousness** (0–100%): Stored on `CreatureHealth`. Updated in `_update_health_state()` in this order:
  1. **Base consciousness** = brain part functionality × 100 (brain is a dedicated body part).
  2. **Blood modifier**: `BloodLoss.get_consciousness_modifier()` — below 50% blood, consciousness is reduced (max 50% reduction).
  3. **Pain reduction** (subtractive): `BodyPartUtilities._get_pain_consciousness_reduction(total_pain)` — tiered by total pain (0 / 10 / 25 / 50 / 75% reduction for minor → intolerable).
  4. **True consciousness** = result above; used for **incapacitation** (consciousness < 10% ⇒ incapacitated).
  5. **Effective consciousness** = true consciousness × (1 - pain_shock_reduction). Pain shock is temporary (5–10 s), -80% effective consciousness; used for **combat performance**, not incapacitation.

- **Pain**: Per-body-part `BodyPart.pain`, recomputed from all active `BodyPartInjury` via `_update_bleeding_and_pain()`. Each injury’s `get_pain()` = base_pain × damage × nerve_density × severity_multiplier. `CreatureHealth.get_total_pain()` sums all parts (skipping children if parent is destroyed/severed). Pain is marked dirty when injuries change.

- **Incapacitation**: `CreatureHealth.is_incapacitated` is true when **true** consciousness < 10% (`BodyPartHealthConstants.INCAPACITATION_CONSCIOUSNESS_THRESHOLD`). Death is separate (critical parts destroyed / blood threshold).

- **Combat use**: Hit chance and movement use `PerformanceModifierConstants.get_combined_performance_modifier(total_pain, consciousness)` = pain_modifier × consciousness_modifier, with a **35% minimum floor** so combat stays finishable.

- **Constants (framework)**:
  - Pain tiers: 0 / 20 / 40 / 60 / 80 (minor → intolerable).
  - Pain → consciousness reduction: 0 / 10 / 25 / 50 / 75%.
  - Pain → performance: 0 / 5 / 15 / 30 / 50% penalty.
  - Blood: below 50% blood ⇒ consciousness modifier down to 0.5; death at 20% blood.
  - Incapacitation: consciousness < 10%.

---

## 2. Fallen-paths vs framework (relevant differences)

| Aspect | FallenFramework | Fallen-paths |
|--------|-----------------|--------------|
| Body model | Many parts (brain, head, torso, limbs, digits, organs) | 6 parts: head, chest, right_arm, left_arm, left_leg, right_leg |
| “Brain” | Dedicated BRAIN part | No brain; **head** is the only head part (use as consciousness proxy) |
| Wounds | BodyPartInjury per part, pain per injury | `wounds[part]` = array of injury dicts (severity, damage, bleeding_rate, etc.); **no pain field yet** |
| Blood | BloodLoss class; consciousness modifier below 50% | `blood_volume` 0–100; death ≤35%, critical ≤30%; **no consciousness link yet** |
| Death | Critical parts destroyed / blood threshold | Vital (head/chest) cut or blunt → 0, or blood ≤ threshold |
| Combat | Creature + CreatureHealth; `is_incapacitated()` used everywhere | CoreEntity (or wrapper); only `is_dead()` and “no functional arm” |

---

## 3. Implementation options for fallen-paths

### Option A — Minimal: consciousness only, no pain

**Goal:** Combat can end by “knockout” (consciousness → 0) without adding pain math or performance modifiers.

- **CoreEntity:**
  - Add `consciousness: float = 100.0`.
  - After damage and each tick (or when processing blood):
    - **Base:** From head only: e.g. `base = 100.0 * (head_cutting + head_blunt) / (head_max*2)` (head functionality as proxy for “brain”).
    - **Blood:** If `blood_volume < 50` then reduce consciousness (e.g. linear from 50→0 blood giving up to 50% reduction, same idea as framework).
    - Set `consciousness = max(0, base_after_blood)`.
  - Add `is_incapacitated() -> bool`: `return consciousness < 10.0` (or a constant).
  - Optionally emit a `creature_incapacitated` signal when crossing below threshold.

- **CombatManager (and any UI):**
  - Treat `is_incapacitated()` like death for “can’t act” and “defeated”: skip turns, mark alive=false or equivalent when determining winner, end combat when all enemies dead or incapacitated.

- **Pros:** Small change set, no new constants for pain, no hit chance changes. **Cons:** No gradual degradation from pain; only head damage and blood drive consciousness.

---

### Option B — Framework-aligned: consciousness + pain (no pain shock)

**Goal:** Pain and consciousness both matter; performance modifier for hit chance/speed; no separate PainShock state.

- **Constants (new script or BleedingConstants):**
  - Pain tiers: e.g. 0, 20, 40, 60, 80 (same as framework).
  - Pain → consciousness reduction: 0, 10, 25, 50, 75%.
  - Pain → performance: 0, 5, 15, 30, 50% penalty (and consciousness = direct scale 0–1), with e.g. 35% floor.
  - Blood consciousness: e.g. below 50% blood ⇒ modifier to consciousness (max 50% reduction).
  - Incapacitation: consciousness < 10%.

- **CoreEntity:**
  - **Pain:** Either (i) per-part `pain` float updated when wounds change, or (ii) derive total pain from existing `wounds` (e.g. sum over `damage * severity_multiplier` per injury, no nerve density for now). Option (ii) avoids new fields. Provide `get_total_pain() -> float`.
  - **Consciousness:** Same as Option A, but **also** subtract pain-based reduction (using the same tiered table as framework). So: base from head, × blood modifier, − pain_reduction → true consciousness.
  - `is_incapacitated()` = consciousness < 10.
  - Add `get_effective_consciousness() -> float` if you want to reserve for future pain shock; for now can equal consciousness.

- **CombatManager:**
  - When resolving attacks: get `total_pain` and `consciousness` from the entity (or wrapper). Apply `combined_performance_modifier = max(0.35, pain_modifier * (consciousness/100))` to hit chance (and optionally to gauge fill or recovery). Treat incapacitated as in Option A.

- **Pain source:** In `_add_wound()` (or after `take_damage_split`), you don’t need to store pain on each wound if you compute total pain from current wounds (severity + damage). Alternatively add a `pain` field per injury and sum in `get_total_pain()`.

- **Pros:** Closer to framework behavior; pain from wounds and head/blood all matter; combat effectiveness drops before knockout. **Cons:** More constants and a few more call sites.

---

### Option C — Full: add pain shock (optional)

**Goal:** Match framework’s pain shock: temporary severe effectiveness drop without immediate incapacitation.

- Everything from Option B, plus:
  - A small **PainShock** (or equivalent) state: triggered when total_pain > threshold (e.g. 50), with a random roll; duration 5–10 s; while active, `effective_consciousness = true_consciousness * (1 - 0.80)`.
  - Use **effective_consciousness** (after shock) for hit chance / performance; use **true consciousness** (before shock) for `is_incapacitated()`.
  - Optionally willpower/endurance modifiers on threshold (skip if you have no stats).

- **Pros:** Matches framework’s “shock” feel. **Cons:** More state and timing; may be unnecessary for your current design.

---

## 4. Recommendation and integration points

- **Recommendation:** Start with **Option B** (consciousness + pain, no shock). It reuses the framework’s logic and constants, fits your 6-part + wounds model, and solves “limbs destroyed but enemy still fighting until chest zeroed” by letting consciousness (and blood loss) drop first. Add Option C only if you want the temporary shock effect.

- **Where to hook in CoreEntity:**
  - **Consciousness:** Recompute after `take_damage_split` (especially when `part == "head"`) and inside `process_blood_loss` (or a shared “update_health_state” called from both and from a tick).
  - **Pain:** Compute `get_total_pain()` from `wounds` (or from per-wound pain if you add it). Call after adding wounds in `take_damage_split` and when applying bandages/healing.
  - **Incapacitation:** Check `is_incapacitated()` wherever you currently check `is_dead()` for “can this unit act?” and “is combat over?”.

- **CombatManager:** In `_execute_attack`, before resolving hit: if attacker `is_incapacitated()`, skip attack (similar to “no functional arm”). When choosing targets or evaluating victory, treat incapacitated like dead for “defeated” and end combat when all enemies are dead or incapacitated. Apply performance modifier to hit chance (and optionally speed) using `get_total_pain()` and consciousness.

- **Combat flow:** Same as framework: **alive** = not dead; **can_fight** = alive and not incapacitated and (optional) has functional arm. So you get: incapacitated = out of fight (combat ends for them), dead = vital zero or blood loss.

---

## 5. Constants to copy or adapt (from framework)

- **Incapacitation:** `INCAPACITATION_CONSCIOUSNESS_THRESHOLD = 10.0`
- **Blood → consciousness:** threshold 50%, max reduction 0.5 (50%)
- **Pain tiers (for reduction and performance):** 20 / 40 / 60 / 80
- **Pain → consciousness reduction:** 0 / 10 / 25 / 50 / 75%
- **Pain → performance:** 0 / 5 / 15 / 30 / 50% penalty
- **Performance floor:** 0.35

These can live in `BleedingConstants.gd` or a new `PainConsciousnessConstants.gd` (or similar) so one place matches the framework and your docs.

---

## 6. Summary table

| Option | Consciousness | Pain | Performance modifier | Pain shock | Complexity |
|--------|----------------|------|----------------------|------------|------------|
| A — Minimal | Yes (head + blood) | No | No | No | Low |
| B — Framework-aligned | Yes (head + blood + pain) | Yes (from wounds) | Yes (pain × consciousness, floor 35%) | No | Medium |
| C — Full | Yes | Yes | Yes (effective = with shock) | Yes | Higher |

Use Option B unless you want the absolute minimum change (A) or the full shock behavior (C).
