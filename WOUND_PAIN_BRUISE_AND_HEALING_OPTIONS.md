# Wound System, Pain System, and Options for Bruises & Wound Tracking/Healing

Examination of how wounds and pain work today, plus design options for bruises and for wound lifecycle/healing.

---

## 1. Current Wound System

### 1.1 When wounds are created

- **Entry point:** `CoreEntity.take_damage_split(cut_pre, blunt_pre, part, pen_s, pen_b)` (called from CombatManager after armor and bone split).
- **Flow:** After applying `to_cut` / `to_blunt` to `body_cutting` / `body_blunt` and `to_bone` to `bone_health`, the code calls:
  - `_add_wound(part, INJURY_TYPE_CUT, to_cut, sub_region)` if `to_cut > 0`
  - `_add_wound(part, INJURY_TYPE_CRUSH, to_blunt, sub_region)` if `to_blunt > 0`
- So **one wound per damage type per hit** (one cut wound, one crush wound per strike that dealt that type). Multiple hits create multiple wound entries.

### 1.2 What’s stored per wound

- **Storage:** `wounds: Dictionary` = `part (String) -> Array of Dictionary`.
- **Per-injury dict:**
  - `injury_type`: `"cut"` or `"crush"` (BleedingConstants.INJURY_TYPE_*).
  - `severity`: `"minor"` | `"moderate"` | `"severe"` | `"critical"` from `_severity_from_damage(part, damage, sub_region)` (uses part max, sub_region severity modifier, % and absolute thresholds).
  - `damage`: float (the tissue damage amount that created this wound).
  - `sub_region`: e.g. `"scalp"`, `"thigh"`, `"forearm"`.
  - `base_bleeding_rate`, `current_bleeding_rate`: from `get_bleeding_rate(injury_type, severity, part, sub_region)`; can be 0 (pain-only wound).
  - `is_stabilized`: bool (bandage applied).
  - `is_arterial`: bool (rolled at creation if `base_rate > 0`).
  - Optional: `stabilized_remaining_seconds` (countdown until bandage effect expires).

- **Injury types (BleedingConstants):** Only `cut` and `crush`. Bleeding rates are always positive in the current BLEEDING_RATES table, so under current data every wound bleeds unless you add a 0-rate severity/type. The code **allows** 0-rate wounds (they are kept for pain; see MEDICAL_ACCURACY_RECOMMENDATIONS.md).

### 1.3 Wound lifecycle (current)

| Event | Effect on wound list |
|-------|----------------------|
| **Hit (to_cut / to_blunt > 0)** | New injury dict(s) appended to `wounds[part]`. |
| **process_bleeding(delta)** | Each injury’s `current_bleeding_rate` decays exponentially by severity (and arterial) clotting. **Removal:** only when `rate <= 0` **and** `base_bleeding_rate > 0` (i.e. a formerly bleeding wound has clotted). Pain-only wounds (`base_bleeding_rate == 0`) are **never** removed here. |
| **apply_bandage(part)** | For each wound on part: rate reduced by BANDAGE_*, `is_stabilized = true`, optional timer set. No removal. |
| **process_healing(seconds)** | Restores `body_cutting`, `body_blunt`, `bone_health`, and (if not bleeding) `blood_volume`. **Does not add or remove wound entries.** Worst severity on the part is used only to choose tissue heal duration (tau). |

So today:

- **Bleeding wounds** disappear from the list when they clot (rate → 0).
- **Pain-only wounds** (if you ever create them) stay forever and keep contributing to pain.
- **Tissue/bone healing** is independent of the wound list: pools refill over time; the wound list is not pruned when the part reaches full HP.

---

## 2. Current Pain System

### 2.1 Source of pain

- **Formula:** `get_total_pain()` sums over **all entries in `wounds`**:
  - `total += injury.damage * SEVERITY_PAIN_MULTIPLIERS[severity]`
- **Severity multipliers (PainConsciousnessConstants):** minor 0.5, moderate 1.0, severe 1.5, critical 2.0.
- So pain is **purely wound-driven**: no wound ⇒ no pain from that hit. Blunt that doesn’t create a wound (e.g. if you never call `_add_wound` for it, or only add when bleeding) doesn’t add pain. The recent change allows 0-rate wounds to be added so “crush with 0 bleed” can still be stored and count for pain once you have a 0-rate path (e.g. bruise type).

### 2.2 How pain is used

- **Consciousness:** `_update_consciousness()` uses `get_total_pain()` to apply a **subtractive** pain reduction (0 / 10 / 25 / 50 / 75% by pain tier 20 / 40 / 60 / 80).
- **Pain shock:** When `total_pain > PAIN_SHOCK_THRESHOLD` (50), roll for temporary “shock” (duration scaled by pain); while in shock, `effective_consciousness` is heavily reduced (combat performance), but incapacitation uses **true** consciousness.
- **Performance:** `get_performance_modifier()` = combined pain × consciousness modifier (action bar fill, hit chance), floor 0.35.

So: **wound list → total_pain → consciousness, shock, performance.** No separate “bruise pain” or “immediate impact pain”;
everything goes through the wound list and severity multipliers.

---

## 3. Current Healing (Tissue / Bone / Blood)

- **process_healing(seconds)** (called from main.gd on time advance):
  1. **Bandage timer:** Decrements `stabilized_remaining_seconds`; when it hits 0, `is_stabilized` is cleared.
  2. **Per part:** Tissue heal duration = `get_tissue_heal_duration_seconds(part, severity)` where **severity = worst severity among current wounds on that part.** So more severe wounds slow tissue healing for the whole part.
  3. **Tissue:** Exponential healing toward `body_max` (cut and blunt pools); τ = tissue_duration / 3.
  4. **Bone:** Exponential healing toward `bone_max`; τ = bone_duration / 3 (e.g. 6 weeks).
  5. **Blood:** If `get_total_bleeding_rate() <= 0`, blood volume recovers exponentially toward 100% over ~24 h.

- **Wound list:** Not modified. Clotted wounds were already removed in `process_bleeding`. Pain-only wounds are never removed, so they can accumulate and keep pain high even after tissue is full.

---

## 4. Options for Handling Bruises

Bruises = blunt trauma that causes pain (and possibly minor swelling/discomfort) but little or no bleeding. Right now, every blunt hit that deals tissue damage creates a **crush** wound with a **positive** bleeding rate, so bruises aren’t distinguished.

### Option A: Bruise as 0-rate crush (minimal change)

- **Idea:** For **low-severity** and/or **low-damage** blunt, treat as “no bleed” but still add a wound (so it still gives pain).
- **Implementation:**
  - In BleedingConstants, add a **bruise** entry to BLEEDING_RATES for crush, e.g. `SEVERITY_MINOR` crush → `0` (or a new severity `"bruise"` with rate 0).
  - Or: in `get_bleeding_rate()`, return 0 when `injury_type == crush` and `severity == minor` (and optionally damage below a threshold).
- **Wound:** Same structure; `base_bleeding_rate == 0`, so it’s never removed by clotting. Pain is counted.
- **Pros:** Small change; reuses existing wound + pain pipeline. **Cons:** Pain-only wounds currently never disappear (see §5 for cleanup options).

### Option B: Separate injury type `"bruise"`

- **Idea:** Add `INJURY_TYPE_BRUISE`. Bruises are created when blunt damage is below a threshold (e.g. damage &lt; 2 or severity stays minor) or when armor deflects most of the force (e.g. high deflection → create bruise instead of crush).
- **Implementation:**
  - BleedingConstants: `INJURY_TYPE_BRUISE`, and in BLEEDING_RATES set all severities for `bruise` to `0`.
  - In `take_damage_split`, when applying blunt: if `to_blunt > 0` and (e.g. `to_blunt < BRUISE_THRESHOLD` or “deflected hit”), call `_add_wound(part, INJURY_TYPE_BRUISE, to_blunt, sub_region)` instead of or in addition to crush (e.g. small blunt → bruise only; large blunt → crush + optional bruise).
- **Pros:** Clear semantics (bruise vs crush); UI can show “Bruise” vs “Crush”. **Cons:** Need a rule for when to create bruise vs crush (threshold or deflection).

### Option C: Bruise = separate “pain pool” (no wound entry)

- **Idea:** Don’t add bruises to `wounds`. Instead maintain e.g. `bruise_pain_per_part[part]` or a single `bruise_pain_total`, which decays over time. `get_total_pain()` = wound pain + bruise pain.
- **Implementation:** New vars; in `take_damage_split` add to bruise pain when blunt is small or deflected; in `process_healing` or `process_bleeding` decay bruise pain. No wound list bloat.
- **Pros:** No permanent wound entries; pain fades when you want. **Cons:** Two sources of pain to maintain; wounds and bruises behave differently (no bandage for bruise pain, no per-wound severity in list).

### Option D: Merge small blunt into one “contusion” per part (or per sub-region)

- **Idea:** Instead of one wound per hit, keep a **single contusion/bruise object per part** (or per sub_region): when blunt is applied, **add damage to** that contusion (and maybe bump severity from worst of merged). Bleeding rate for contusion = 0 or very low.
- **Implementation:** Either a separate structure `contusions[part] = { damage, severity, sub_region?, ... }` or a single wound per part of type “contusion” that you **update** instead of appending. Pain = sum over wounds + sum over contusions (with same severity multipliers).
- **Pros:** Bounded list size; “bruised thigh” is one thing. **Cons:** Loses per-strike detail; merge rules and severity updates need to be defined.

**Recommendation:** **A** or **B** fit the current design best (single wound list, one pain formula). Use **B** if you want explicit “Bruise” in UI and data; use **A** if you’re fine with “minor crush with 0 bleed.” Then add **wound cleanup** for pain-only entries (§5) so bruises don’t cause permanent pain.

---

## 5. Options for Wound Tracking and Healing

### 5.1 Remove pain-only wounds when part is fully healed

- **Idea:** In `process_healing`, after updating tissue for a part, if `body_cutting[part] == body_max[part]` and `body_blunt[part] == body_max[part]`, remove all wounds on that part with `base_bleeding_rate == 0`.
- **Effect:** Bruises (and any other 0-rate wounds) stop contributing to pain once the part has fully refilled. Bleeding wounds were already removed when they clotted.
- **Pros:** Simple; matches “tissue healed ⇒ no more pain from that area’s bruises.” **Cons:** All-or-nothing (full HP); no gradual “bruise fading.”

### 5.2 Wound decay over time (pain and/or severity)

- **Idea:** Each wound has an optional `created_at` (or you infer age by a decay step). Each tick or on time advance, reduce each wound’s **contribution to pain** (e.g. `effective_damage = damage * decay_factor(age)`) or reduce `damage` in place. Optionally downgrade `severity` over time so tissue heal duration and pain both taper.
- **Implementation:** Add `created_time` (e.g. `Time.get_ticks_msec()`) when creating wound. In `get_total_pain()` use `injury.damage * pain_decay(age)` or in a separate step multiply each injury’s effective damage by a decay (e.g. half-life 1 day for bruises). Or in `process_healing` reduce `injury["damage"]` for 0-rate wounds by a small amount per second.
- **Pros:** Gradual pain decrease; feels natural for bruises. **Cons:** More state and tuning (decay curve, half-life).

### 5.3 Explicit wound lifecycle (created → bleeding → clotted → healing → resolved)

- **Idea:** Give each wound a **state**: e.g. `"bleeding"` | `"clotted"` | `"healing"` | `"resolved"`. Bleeding wounds clot (current logic). Clotted or healing wounds still contribute to pain but at a reduced rate or with a time limit; after a “healing” duration, mark `resolved` and remove from list (or set contribution to 0).
- **Implementation:** Add `state` and optionally `resolved_at` or `healing_until`. In `process_bleeding`, when rate → 0 set state to `clotted` instead of removing (for bleeding wounds). In `process_healing`, advance state (e.g. clotted → healing after 1 day; healing → resolved after severity-based duration). Remove when state == resolved. Pain = sum over wounds with weight by state (e.g. bleeding 1.0, clotted 0.8, healing 0.5).
- **Pros:** Clear model for UI (“Healing cut on thigh”); can show progress. **Cons:** More fields and state machine; need to define durations per state.

### 5.4 Cap or decay pain from old wounds

- **Idea:** Don’t remove wounds; cap total pain from wounds older than X, or use a global “pain half-life” so old wounds contribute less.
- **Implementation:** In `get_total_pain()`, sum `damage * severity_mult * time_decay(age)` with e.g. `time_decay(age) = exp(-age / tau)`. Or cap total_pain at e.g. 100 so many small wounds don’t stack infinitely.
- **Pros:** Prevents pain from growing without bound; no need to remove entries. **Cons:** Pain-only wounds still accumulate in the list (memory); cap can feel arbitrary.

---

## 6. Summary Table

| Topic | Current behavior | Suggested direction |
|-------|------------------|---------------------|
| **Wound creation** | One cut + one crush per hit (if to_cut/to_blunt > 0). | Keep; add bruise path (Option A or B) for low/deflected blunt. |
| **Pain source** | Sum of (damage × severity_mult) over all wounds. | Keep; bruises contribute once 0-rate wounds exist. |
| **Wound removal** | Only when bleeding rate → 0 and was bleeding. Pain-only never removed. | Add cleanup: remove 0-rate wounds when part fully healed (5.1) and/or decay pain (5.2). |
| **Healing** | Tissue/bone/blood exponential; wound list not pruned. | Optional: prune pain-only when part full (5.1); optional lifecycle (5.3) for richer UI. |
| **Bruises** | Not distinguished (all blunt → crush with positive rate). | Option A (0-rate minor crush) or B (INJURY_TYPE_BRUISE); then cleanup or decay so pain doesn’t last forever. |

---

## 7. Minimal implementation sketch (bruise + cleanup)

1. **Bruise:** In BleedingConstants, set `BLEEDING_RATES[INJURY_TYPE_CRUSH][SEVERITY_MINOR] = 0.0` (or add a `"bruise"` severity with 0 everywhere). Then minor blunt creates a 0-rate wound → pain, no bleed.
2. **Cleanup:** In `process_healing`, after the per-part tissue heal block, for each part where `body_cutting[part] >= body_max[part]` and `body_blunt[part] >= body_max[part]`, remove from `wounds[part]` all injuries with `injury.get("base_bleeding_rate", 0.0) == 0.0`.
3. **Optional:** When creating a crush wound, if severity is minor and you want only bruises to be 0-rate, keep current BLEEDING_RATES but in `get_bleeding_rate()` return 0 for crush+minor (so only minor crush becomes pain-only; moderate+ still bleed).

This gives you bruises (pain, no bleed), uses the existing wound/pain pipeline, and stops pain from 0-rate wounds once the part is fully healed.
