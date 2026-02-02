# Bleeding System Comparison and Recommendation

This document compares the FallenFramework bleeding system with other game approaches and recommends a bleeding design that fits the current fallen-paths setup (body-part cut/blunt pools, armor, no wound list, real-time combat gauge).

---

## 1. FallenFramework (E:\FallenFramework\fallen-framework)

### Model
- **Injury-driven**: Each hit creates a `BodyPartInjury` (type, severity, damage, body_part). Injuries live on body parts and have:
  - `base_bleeding_rate` / `current_bleeding_rate` (HP/sec)
  - Severity from damage and part size (minor/moderate/severe/critical)
  - Stabilization (bandage/tourniquet), clotting over time, stabilization expiry
- **Bleeding constants** (`BleedingConstants`):
  - Per injury type (cut, scratch, bite, fracture, crush) and severity: base rate (e.g. cut critical 3.0 HP/sec).
  - Body part multipliers (torso 1.2, head 1.5, heart 3.0).
  - Severity multipliers; severed-part multiplier 2.0.
- **Blood volume**: 0–100%. Drains at `total_bleeding_rate × 0.1`. Death below 20%; consciousness reduced below 50%.
- **Clotting**: Natural rate + treatment-enhanced; stabilization gives immediate reduction + duration; when stabilization expires, bleeding “resumes” with a clotting benefit retained.
- **Tick**: `MedicalUpdateManager` + `BloodLoss.process_blood_loss(tick_delta)`; blood loss drains volume; death/consciousness from volume.
- **Medical**: Field care (bandages, tourniquets, cauterization), field hospital, treatment effectiveness, infection.

### Fit for fallen-paths
- **Heavy**: Requires full injury/wound list per body part, many body part types, blood volume, medical system, and a global tick (MedicalUpdateManager). Your project has no wound list and no blood volume.
- **Reusable ideas**: Per-part bleeding rate; rate from “cut” severity and body part; clotting over time; optional “stabilization” later.

---

## 2. Other Games (summary)

| Game / system      | Bleeding model | Stacking / duration | Counterplay |
|--------------------|----------------|--------------------|------------|
| **Elden Ring**     | Buildup meter → one burst = % max HP | N/A (one shot) | Cure items, resistances |
| **Pathfinder**     | X damage per round, roll each round  | Same type: take worst; Wounding stacks | Heal, treat |
| **Darkest Dungeon**| DoT strength per turn, 3–5 turns      | Stacks extend duration | Heal, cure, resist |
| **Cyber Knights** | 20 HP/turn, movement/AP penalty      | Single effect | Any healing removes |

Takeaways: DoT per turn/round is common; stacking is either “take worst”, “extend duration”, or “add damage”; counterplay is healing/cure/resist.

---

## 3. Your Current Setup (fallen-paths)

- **Health**: Per-part `body_cutting`, `body_blunt`, `bone_health` (head, chest, arms, legs). No injury list, no blood volume.
- **Damage**: `take_damage_split(cut_pre, blunt_pre, part, pen_sharp, pen_blunt)` → final cut/blunt applied to tissue/bone; death when head or chest has cutting ≤ 0 or blunt ≤ 0.
- **Combat**: Real-time gauge, wind-up, recovery; damage resolved in `CombatManager._execute_attack` after `take_damage_split`.
- **Body parts**: 6 (head, chest, right_arm, left_arm, left_leg, right_leg); `BodyPartConstants` for bone thresholds.

---

## 4. Recommended Bleeding System for Your Setup

Goal: Add meaningful “cut wounds bleed over time” without introducing a full wound/medical/blood-volume system. Two levels:

### Option A – Minimal (best first step)

**Idea**: Only **cutting** damage can cause bleeding. When `take_damage_split` applies `final_cut > 0` to a part, add a **per-part bleeding rate** that drains **body_cutting** (and optionally a tiny bit of blunt) over time until it clots.

- **Storage**: On `CoreEntity`, e.g. `var bleeding_rate: Dictionary = {}` (part → float HP per second). Or a small `BleedingState` resource: `{ part: rate }`.
- **When to add**: In `CombatManager` after `take_damage_split`, if `final_cut > 0`: compute a rate for that part (see below) and add it to existing rate for that part (stacking = sum rates, like multiple cuts).
- **Rate formula** (Framework-inspired, simplified):
  - Base rate from `final_cut`: e.g. `rate = clamp(final_cut * BLEEDING_PER_CUT_HP_PER_SEC, 0, MAX_RATE_PER_PART)`.
  - Multiply by body-part factor (e.g. head/chest 1.2–1.5, limbs 1.0) so vitals bleed a bit more.
- **Where to drain**: In `CombatManager._process(delta)`, for each combatant with `bleeding_rate` non-empty: for each part, subtract `rate * delta` from `body_cutting[part]` (and optionally 10–20% from `body_blunt[part]` for “trauma”). Clamp to ≥ 0. Re-check `is_dead()` after changes.
- **Clotting**: Each tick, reduce `bleeding_rate[part]` by `CLOTTING_RATE * delta` (e.g. 0.05–0.1/sec). Remove part from dict when rate ≤ 0.
- **Constants**: e.g. in `BleedingConstants.gd`: `BLEEDING_PER_CUT_HP_PER_SEC`, `MAX_RATE_PER_PART`, `BODY_PART_BLEEDING_MULTIPLIERS` (head, chest, limbs), `CLOTTING_RATE`.

Result: Cuts cause ongoing drain on the same pools you already have; no new “blood” pool; death still from head/chest cut or blunt to 0; combat stays as-is with one extra loop in `_process`.

### Option B – Slightly richer (if you want “bleed stacks” like Darkest Dungeon)

- When `final_cut > 0`, push a **bleed instance**: `{ part, rate, duration_sec }`.
- Each tick: apply `rate * delta` to `body_cutting[part]`; decrease `duration_sec` by delta; remove when duration ≤ 0.
- Stacking: new cut on same part adds another instance (or you cap instances per part and merge rate/duration).
- No clotting constant; “bleed” just expires after duration. Optionally cure via item/skill that clears instances.

This fits a turn-based or “per turn” feel if you run the tick every “combat turn” instead of every frame; for real-time gauge combat, Option A is simpler and consistent with FallenFramework’s “rate + clotting” idea.

---

## 5. Integration Points in Your Code

1. **Constants**  
   New script e.g. `BleedingConstants.gd` (or a section in an existing constants file):
   - `BLEEDING_PER_CUT_HP_PER_SEC`, `MAX_RATE_PER_PART`, `CLOTTING_RATE`, `BODY_PART_BLEEDING_MULTIPLIERS` (map part string → float).

2. **CoreEntity**  
   - Add `var bleeding_rate: Dictionary = {}` (part → float).
   - Optional: `func add_bleeding(part: String, rate: float)` that adds to `bleeding_rate[part]` and clamps per-part max.
   - Optional: `func process_bleeding(delta: float)` that drains `body_cutting`/`body_blunt` and applies clotting; call from combat or a small updater.

3. **CombatManager**  
   - After `take_result = tgt.node.take_damage_split(...)` and you have `final_cut`, `part`:
     - If `final_cut > 0` and target has `add_bleeding`: compute rate from `final_cut` and part, call `tgt.node.add_bleeding(part, rate)`.
   - In `_process(delta)`:
     - For each combatant, if node has `process_bleeding(delta)`, call it; then re-check `is_dead()` so bleeding-out can end the fight.

4. **Character**  
   - Forward `add_bleeding` / `process_bleeding` to `_combat_body` (CoreEntity) if you keep combat stats there.

5. **UI**  
   - If you show part health, you can show a “bleeding” indicator when `bleeding_rate.get(part, 0) > 0`.

---

## 6. Summary

- **FallenFramework**: Full injury/wound + blood volume + medical; too heavy for your current design, but its **per-part bleeding rate**, **body-part multipliers**, and **clotting** are the right ideas to reuse.
- **Other games**: DoT per turn/round and simple stacking (sum or take worst) are good references; you don’t need buildup meters or % max HP.
- **Best fit here**: **Option A** — per-part bleeding rate driven by cutting damage, drain `body_cutting` (and optionally a bit of blunt) each tick, clotting to reduce rate over time, no blood volume, no wound list. Implement via `BleedingConstants`, `CoreEntity.bleeding_rate` + `add_bleeding` + `process_bleeding`, and CombatManager applying bleeding on hit and each frame. Option B is an alternative if you prefer time-limited “bleed stacks” instead of clotting.

This keeps your systems intact and adds a realistic, Framework-inspired bleeding layer that fits your existing body-part and damage model.
