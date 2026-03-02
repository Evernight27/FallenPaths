# Pain shock: implementation vs medical reality

## Current implementation

### What the game uses

- **Trigger**: Only when a weapon attack hits (`_try_enter_pain_shock_from_hit()` called from `apply_damage()`). No ambient pain roll.
- **Roll for shock**:
  - **Pain value**: `get_effective_pain_for_thresholds()` → **total pain** (all wounds, summed and normalized by species pain reference). So the *chance* to enter shock depends on **cumulative pain from every injury**, not just the hit that just landed.
  - **Threshold**: NRS 7.0 (normalized) + endurance modifier. Risk = `(pain - threshold) * 0.15` per point above threshold.
- **Duration**: `PAIN_SHOCK_DURATION_BASE * (pain_value / shock_thresh) * impact_mult`
  - **pain_value**: again **total pain** (same as above).
  - **impact_mult**: from **this hit only** — `1.0 + min(triggering_hit_damage / 10.0, 1.0)` (cap 2.0×).

So in code:

- **Whether** you roll and **how likely** shock is → driven by **total pain** (all wounds).
- **How long** shock lasts → driven by **total pain** (ratio) and **this hit’s damage** (impact multiplier).

There is no separate “pain from this weapon hit” — the new hit’s wounds are already in `wounds` when we call `get_total_pain()`, so total pain includes the new injury but is not broken out as “this hit only.”

---

## How the body actually handles shock (medical)

### 1. Hemorrhagic / hypovolemic shock (blood loss)

- **Trigger**: Loss of circulating volume → inadequate perfusion.
- **Effect**: Progressive drop in consciousness, organ failure; can be fatal.
- **In game**: Handled separately via **blood_volume** → consciousness modifier and death threshold. Not “pain shock.”

### 2. Vasovagal syncope (pain / emotional trigger)

- **Trigger**: **Acute** stimulus — sudden pain, emotional upset, or injury. The **new** event triggers the reflex.
- **Mechanism**: Vagal response → bradycardia, vasodilation → brief drop in cerebral perfusion → transient loss or clouding of consciousness.
- **Relevance**: The **insult** (the new hit) is what triggers the reaction, not “how much you already hurt.” Severity of the **current** stimulus matters.

### 3. Neurogenic shock (spinal / nervous system)

- **Trigger**: Spinal cord injury → loss of sympathetic tone.
- **Not** the same as “pain shock” in game; different mechanism.

### 4. Acute stress reaction (psychological / trauma response)

- **Trigger**: Experiencing or witnessing a traumatic **event**; can occur even without severe physical injury.
- **Symptoms**: Daze, narrowing of attention, reduced consciousness, disorientation, agitation, autonomic arousal.
- **Note**: Literature often states there is **no correlation between severity of physical injury and likelihood** of acute stress reaction — individual vulnerability and the nature of the event matter more than injury magnitude. So “total body pain” is not the main driver.

### Summary (medical)

- **Hemorrhagic shock**: Blood loss → already modeled via blood/consciousness.
- **Vasovagal / “pain faint”**: Driven by the **acute** pain/injury (the new hit), not by cumulative pain.
- **Acute stress (disorientation/daze)**: Tied to the **traumatic event** and individual factors; physical injury severity is not the primary predictor.

So for a “pain shock” that represents brief disorientation/grogginess from a hit:

- Medically, the **new blow** (magnitude, suddenness) is the main trigger.
- **Total pain** (all wounds) is a better fit for ongoing **performance** (hit chance, action bar, parry) than for “did this single hit put you in shock.”

---

## Tension: total pain vs “this hit”

| Aspect              | Current game                         | Medical angle (vasovagal / acute stress)   |
|---------------------|--------------------------------------|--------------------------------------------|
| Trigger for shock   | Roll only on weapon hit (good)       | Trigger = **acute** event (this hit)       |
| Chance to enter     | Total pain vs threshold               | **This hit’s** severity / pain              |
| Duration            | Total pain ratio + this hit impact   | Duration more tied to **insult** magnitude  |

So: shock is **triggered** by a hit (correct), but **chance and duration** are driven mainly by **total pain**, which does not match the idea that “this blow” is what causes the reaction.

---

## Options for alignment

### A. Drive shock from “this hit” only (impact + optional “pain from this hit”)

- **Chance**: Base risk on **this hit’s damage** (and optionally a one-off “pain from this hit” if we compute it). No total pain in the roll (or use it only as a small modifier, e.g. “already in pain → slightly more likely”).
- **Duration**: Scale with **this hit’s damage** (and optionally “pain from this hit”). Total pain not used for duration, or only as a minor modifier.
- **Implementation**: Add a helper that computes “pain contribution of a single hit” (same formula as `_get_pain_for_part` but for one wound: damage × severity × part × type × sub_region × (1 - 0) and normalize). Pass that into the shock roll/duration instead of (or in addition to) total pain. Keep using `_last_hit_impact` for impact scaling.
- **Pro**: Matches vasovagal / “this blow caused the reaction.”  
- **Con**: Someone with many small wounds but one big new hit would have shock driven by the big hit; someone with one huge old wound and a small new hit would have shock driven by the small hit (more realistic for “reaction to this event”).

### B. Impact as primary; total pain as susceptibility modifier

- **Chance**: Base risk on **impact** (e.g. damage of this hit vs a reference). Multiply by a **susceptibility** factor from total pain (e.g. high total pain = 1.2×, low = 0.8×) so cumulative state matters but the hit is the trigger.
- **Duration**: Primarily **impact** (current impact_mult already does this). Optionally add a small total-pain factor (e.g. “already stressed → slightly longer recovery”).
- **Pro**: Single formula; no need to compute “pain from this hit.”  
- **Con**: Still doesn’t use “pain from this hit” explicitly (e.g. a 15 damage cut to forearm vs 15 damage bruise could differ in pain but not in raw impact).

### C. Hybrid: “Pain from this hit” for chance; impact for duration

- **Chance**: Compute **pain from this hit** (same formula as wound pain, for the wounds just added, healing = 0). Roll when “pain from this hit” (normalized) exceeds threshold. Optionally add a small total-pain modifier for susceptibility.
- **Duration**: Keep current: scale with **impact** (this hit’s damage) and optionally total pain or “pain from this hit.”
- **Pro**: Medically plausible (acute triggers; severity of insult drives duration).  
- **Con**: Requires computing pain for the hit we just applied (we have damage, part, sub_region, severity, injury_type from `_add_wound` calls).

---

## Recommendation

- **Short term**: Document the current behavior (total pain for chance + duration; impact for duration only) and the medical mismatch (trigger = hit is good; driver should be “this hit” more than total pain).
- **Design change**: Prefer **Option A or C** so that:
  - **Chance** to enter pain shock is driven mainly by **this hit** (impact and/or “pain from this hit”), with total pain only as an optional susceptibility modifier.
  - **Duration** is driven mainly by **this hit’s** magnitude (impact and/or “pain from this hit”), with total pain optional.

**Option C (implemented):**

1. _get_pain_contribution_for_wound() returns raw pain for one wound. In apply_damage we sum that for cut/blunt/bone (or stump if severed) into pain_from_this_hit_raw and call _try_enter_pain_shock_from_hit(pain_from_this_hit_raw). “pain from this hit”2. `_try_enter_pain_shock_from_hit(pain_from_this_hit_raw)` normalizes with `_get_pain_reference()`; chance and duration use this hit's pain only (duration also uses `_last_hit_impact`). Total pain is no longer used for shock.
