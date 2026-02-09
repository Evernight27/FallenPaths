# Medical Actions: Bandages, Tourniquets, and Accuracy

Summary of how in-game medical actions map to real-world hemorrhage control, and what’s implemented vs optional.

---

## 1. Bandages – Are They Medically Accurate?

**Real-world:**  
- **Direct pressure** is first-line for most bleeding: it reduces flow so clotting can occur.  
- A **bandage** (dressing + pressure) is the standard first-aid step: apply pressure, hold, then secure.  
- **Venous/capillary** bleeding usually responds well to pressure and bandaging.  
- **Arterial** bleeding often needs **sustained direct pressure** or a **tourniquet** (on limbs); a simple bandage alone is often insufficient because arterial pressure keeps the wound open.

**In-game implementation:**

| Aspect | Implementation | Accuracy |
|--------|----------------|----------|
| Immediate reduction | 60% for venous/capillary (BANDAGE_IMMEDIATE_REDUCTION) | **Plausible.** Pressure reduces flow; exact % is tuned. |
| Arterial | 50% effectiveness (BANDAGE_ARTERIAL_EFFECTIVENESS_MULT) → 30% reduction | **Accurate.** Bandage less effective on arterial; needs more than a simple bandage. |
| Clotting when bandaged | Fast clotting (CLOTTING_RATE_STABILIZED); arterial still slower | **Accurate.** Pressure helps clot form; arterial pressure still inhibits. |
| Stabilization duration | Optional 300 s (5 min) then effect can expire | **Tuned.** Represents need to reapply or upgrade care. |
| Application time | **BANDAGE_APPLICATION_TIME_SECONDS** (e.g. 4 s) | Action system should delay applying the bandage effect until this duration has passed. |

**Verdict:** Bandages are **medically plausible**: good effect on non-arterial bleeding, reduced effect on arterial, and faster clotting when stabilized. No change required for basic accuracy.

---

## 2. Direct pressure (Implemented)

**Real-world:** First-line hemorrhage control is **direct pressure** with the hands: press firmly on the wound to reduce flow so clotting can occur. It uses the rescuer’s (or casualty’s) arms and is more effective than a dressing alone when applied correctly.

**In-game:**

- **Requires a functional arm:** Uses the same logic as attacking: `get_attacking_arm()` must be non-empty (at least one arm not destroyed and with some tissue/bone function). If both arms are destroyed or unusable, direct pressure cannot be applied.
- **Target:** Any body part that has wounds (head, chest, arm, leg). The character uses their hand/arm to apply pressure to that site.
- **Effect:** Stronger than bandage:
  - **80%** immediate reduction (vs bandage 60%) for venous/capillary.
  - **70%** effectiveness on arterial (so 56% reduction on arterial) — better than bandage (50%) but arterial still harder to control.
- Same **stabilization** as bandage (fast clotting, optional duration); uses `BANDAGE_STABILIZATION_DURATION`.
- **Duration:** Direct pressure lasts until **the next time the entity takes any action** (attack, bandage, tourniquet, move, etc.) or **bleeding on that part stops** (rate ≤ epsilon). While holding pressure, the entity is “busy” (use `is_applying_direct_pressure()` / `get_direct_pressure_part()`). The action system must call `clear_direct_pressure()` when the entity performs another action.

**API:** `can_apply_direct_pressure(target_part)`, `apply_direct_pressure(part)`, `is_applying_direct_pressure()`, `get_direct_pressure_part()`, `clear_direct_pressure()`. Character forwards these from CoreEntity.

---

## 3. Tourniquet (Implemented)

**Real-world (CoTCCC, TCCC, ATLS):**  
- For **life-threatening limb hemorrhage** when direct pressure/bandage isn’t working or isn’t possible (e.g. amputation, multiple wounds).  
- Applied **proximal** to the wound, **tight enough** to stop arterial flow.  
- **Limb-only:** not for neck, chest, or junctional (groin, axilla).  
- When applied correctly, bleeding from that limb **stops**.  
- Risk of limb ischemia if left on too long (e.g. ~2 h); guidelines say document time and reassess.

**In-game:**

- **Application time:** The action takes **`TOURNIQUET_APPLICATION_TIME_SECONDS`** (e.g. 18 s) before the effect is applied. The action/combat system should delay calling `apply_tourniquet(part)` until that duration has passed (wind-up style).
- **`apply_tourniquet(part)`** – Only for **limbs** (`right_arm`, `left_arm`, `right_leg`, `left_leg`). That part’s wounds **no longer contribute** to `get_total_bleeding_rate()`, so no blood loss from that limb while the tourniquet is on.
- **`remove_tourniquet(part)`** – Stops the effect; bleeding from that limb’s wounds counts again (wound rates unchanged).
- **`can_apply_tourniquet(part)`** – True only for limb parts. Head/chest return false.
- **Optional expiry:** `TOURNIQUET_MAX_DURATION_SECONDS` (default 0 = no expiry). If set (e.g. 7200 = 2 h), `process_healing()` automatically clears the tourniquet after that game time so bleeding can resume (limb ischemia risk).

Wounds on the limb **remain in the list** (still painful, still heal over time); only their contribution to **blood loss** is suppressed while the tourniquet is applied.

---

## 4. Other Medical Actions You Could Add

| Action | Real-world | Suggested in-game effect |
|--------|------------|--------------------------|
| **Direct pressure** | Hands-on pressure; strongest first step | Option A: Same as bandage with higher effectiveness (e.g. 0.9). Option B: Separate action that gives higher immediate reduction (e.g. 80%) and/or faster clotting while “held.” |
| **Pressure bandage** | Bandage applied with enough pressure to maintain compression | Could be a bandage with effectiveness &gt; 1.0 (e.g. 1.2) or a separate constant (e.g. PRESSURE_BANDAGE_REDUCTION 0.8). |
| **Hemostatic gauze / packing** | For deep or junctional wounds (neck, groin, axilla); promotes clotting | For **non-limb** parts (head, chest) or severe/critical wounds: add `apply_packing(part)` that sets a “packed” flag and applies a strong clotting multiplier or sets rate to 0 after a short delay. |
| **Tourniquet conversion** | In hospital, TQ may be converted to pressure dressing if bleeding controlled | Already supported by `remove_tourniquet(part)` then `apply_bandage(part)`; no new action needed. |
| **Cautery** | Stops small-vessel bleeding; not for major vessels | Optional: one-time action that sets a wound’s `current_bleeding_rate` to 0 (and maybe marks it “cauterized”) for minor/moderate only; no effect or reduced effect on severe/critical/arterial. |

---

## 5. Quick Reference: What Works Where

| Body part | Bandage | Direct pressure | Tourniquet | Packing (if added) |
|-----------|---------|-----------------|------------|---------------------|
| Head (scalp/face/neck) | Yes | Yes (if arm functional) | No (not a limb) | Yes (junctional neck) |
| Chest (thoracic/abdominal) | Yes | Yes (if arm functional) | No | Yes (truncal) |
| Arms, legs | Yes | Yes (if other arm functional) | Yes (limb only) | Optional (limb packing) |

**Direct pressure** requires at least one functional arm (same as attacking); if both arms are destroyed, only bandage/tourniquet (limbs) remain.

---

## 6. Constants (BleedingConstants.gd)

- **Bandage:** `BANDAGE_IMMEDIATE_REDUCTION`, `BANDAGE_ARTERIAL_EFFECTIVENESS_MULT`, `BANDAGE_STABILIZATION_DURATION`, **`BANDAGE_APPLICATION_TIME_SECONDS`** (e.g. 4 s).  
- **Direct pressure:** `DIRECT_PRESSURE_IMMEDIATE_REDUCTION` (0.8), `DIRECT_PRESSURE_ARTERIAL_EFFECTIVENESS_MULT` (0.7). Uses arm functionality (`get_attacking_arm()`). Lasts until next action or bleeding stops; `clear_direct_pressure()` when entity takes another action.  
- **Tourniquet:** `LIMB_PARTS`, `TOURNIQUET_APPLICATION_TIME_SECONDS` (e.g. 18 s), `TOURNIQUET_MAX_DURATION_SECONDS` (0 = no expiry).

Core logic: **CoreEntity** `get_bandage_application_time_seconds()`, `get_tourniquet_application_time_seconds()`, `apply_bandage`, `can_apply_direct_pressure`, `apply_direct_pressure`, `is_applying_direct_pressure`, `get_direct_pressure_part`, `clear_direct_pressure`, `apply_tourniquet`, `remove_tourniquet`, `get_total_bleeding_rate` (skips parts with tourniquet), `get_bleeding_rate_for_part`, `process_bleeding` (clears direct pressure when that part’s bleeding stops), `process_healing` (optional tourniquet expiry). **Character** forwards these so UI or items can call them.
