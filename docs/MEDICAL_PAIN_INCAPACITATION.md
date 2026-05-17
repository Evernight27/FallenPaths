# Medical Pain Incapacitation

**Plan / code:** Pain / wounds / flee → [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md#tier-6--medical--pain-extensions) **Tier 6** (avoid blocking formation busy states). Milestone **Status** → [plan milestone summary](IMPLEMENTATION_ORDER.md#milestone-summary) only. **`MedicalPhaseController`**, **`CombatMedicalCoordination`** — see plan [Tier 0](IMPLEMENTATION_ORDER.md#tier-0--baseline-shipped--maintain).

<a id="tier-61-mobility-pain-shock-live-path"></a>

## Tier 6.1 — mobility, cowering retreat, pain-shock susceptibility (live path)

**Reader:** **Cowering** = no functional arms (`is_cowering()`), not immobile. **Unconscious** (`is_unconscious()`) skips combat ticks and action listing. **Mobile cowering** (legs ≥ **`MOBILITY_FLEE_THRESHOLD`**) may **`fall_back`** in formation when **`solo_fall_back_action_legal`** passes (loose discipline, empty same-file rank-1, per-file frontline plug check). **`formation_retreat_only`** in **`AvailableActionsBuilder.build`** lists retreat without stable-line **`allow_fall_back`**; **`CombatEventDispatch.handle_action_ready`** fills gauge for mobile cowering only.

| Layer | Module | Role | Harnesses (grep) |
|-------|--------|------|------------------|
| Mobility gate | `PainConsciousnessConstants.gd`, `CoreEntity.gd` | **`MOBILITY_FLEE_THRESHOLD`** (0.2); **`can_flee_or_fall_back()`**; **`is_unconscious()`** vs **`is_incapacitated()`** | **`_run_medical_mobility_can_flee_leg_and_consciousness`** |
| Combat access | `CombatantEntityAccess.gd` | **`can_flee_or_fall_back`**, **`is_unconscious`**, **`is_cowering`** on combatant dicts | (above) |
| Tick / events | `CombatStateHandlers.gd`, `CombatEventScheduler.gd`, `CombatEventDispatch.gd` | Mobile cowering not skipped in **`process_incapacitation`**; unconscious-only scheduling; **`ACTION_READY`** for mobile cowering | **`_run_medical_mobility_cowering_mobile_not_skipped_in_process_incap`**, **`_run_medical_mobility_cowering_action_ready_fills_gauge_for_mobile`** |
| Formation retreat | `AvailableActionsBuilder.gd`, `CombatFormationFlow.gd`, `CombatResolveAction.gd` | **`formation_retreat_only`** listing; **`solo_fall_back_action_legal`** + per-file plug check; resolve bypasses **`allow_fall_back`** when cowering | **`_run_medical_mobility_cowering_mobile_solo_fall_back_legal`**, **`_run_medical_mobility_cowering_lists_fall_back_in_formation_mode`**, **`_run_medical_mobility_cowering_resolve_solo_fall_back_without_movement_policy`** |
| Player UI | `AvailableActionsBuilder.gd`, `TurnReadyHandler.gd` | **`player_cowering_retreat_hint_if_applicable`** → **`combat_ui_hint`** on player **`turn_ready`** | **`_run_medical_mobility_cowering_player_retreat_ui_hint`** |
| Pain shock | `EntityPainConsciousness.gd` | Hit pain drives chance/duration (Option C); **`get_pain_shock_susceptibility_mult`** (0.8×–1.2× from total effective pain) on chance only | **`_run_medical_pain_shock_susceptibility_mult_from_effective_pain`** |

**Harness (registry):** [`REGRESSION_HARNESS_MAP_TIER19.md`](REGRESSION_HARNESS_MAP_TIER19.md) Tier **6.1** paragraph · grep **`_run_medical_`**.

---

Consolidated sections; each has **`Source:`** for provenance.

## Contents

0. [Tier 6.1 live path](#tier-61-mobility-pain-shock-live-path)
1. [PAIN_SHOCK_INVESTIGATION.md](#pain-shock-investigation)
2. [PAIN_MEDICAL_RESEARCH_SYNTHESIS.md](#pain-medical-research-synthesis)
3. [WOUND_PACKING_MEDIEVAL_RESEARCH.md](#wound-packing-medieval-research)
4. [INCAPACITATION_FLEE_FALLBACK_COWERING_INVESTIGATION.md](#incapacitation-flee-fallback-cowering-investigation)

---

<a id="pain-shock-investigation"></a>

## Source: `PAIN_SHOCK_INVESTIGATION.md`

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

1. **`_get_pain_contribution_for_wound()`** returns raw pain for one wound. In **`apply_damage`**, sum cut/blunt/bone (or stump if severed) into **`pain_from_this_hit_raw`** and call **`_try_enter_pain_shock_from_hit(pain_from_this_hit_raw)`**.
2. **`EntityPainConsciousness.try_enter_pain_shock_from_hit`**: chance and duration use **this hit’s** normalized pain (duration also uses **`_last_hit_impact`**). **Chance** is multiplied by **`get_pain_shock_susceptibility_mult(get_effective_pain_for_thresholds())`** (0.8× at low total pain → 1.2× at high; NRS 4–8 lerp). Total pain does **not** replace hit pain as the trigger.

---

<a id="pain-medical-research-synthesis"></a>

## Source: `PAIN_MEDICAL_RESEARCH_SYNTHESIS.md`

## Pain System: Medical Research Synthesis for Optimal Realism

This document synthesizes medical research on pain scales, functional impairment, and acute trauma to justify the pain constants used in the game.

---

### 1. NRS Thresholds for Functional Impairment

#### Krebs et al. (2007) — J Gen Intern Med

**Study:** 275 primary care patients; NRS vs. BPI interference (pain that interferes with functioning).

**Likelihood ratios for pain interfering with functioning:**
| NRS range | Likelihood ratio | Interpretation |
|-----------|-----------------|----------------|
| 0 | 0.39 | Less likely to have interference |
| 1–3 | 0.99 | Neutral |
| **4–6** | **2.67** | 2.67× more likely to have functional impairment |
| **7–10** | **5.60** | 5.60× more likely |

**Conclusion:** NRS 4 is the lower bound where functional impairment becomes meaningfully more likely. NRS 7+ indicates severe interference.

#### Boonstra et al. (2016) — Frontiers Psychology

**Study:** 2,854 chronic musculoskeletal pain patients; NRS vs. Pain Disability Index.

**Cut-off points (overall):**
- Mild: NRS ≤ 5
- Moderate: NRS 6–7
- Severe: NRS ≥ 8

**Low catastrophizing subgroup:**
- Mild: NRS ≤ 3
- Moderate: NRS 4–6
- Severe: NRS ≥ 7

**Implication:** For low-catastrophizing individuals (e.g. trained fighters), first functional effect may occur at NRS 4. Moderate pain = NRS 4–6.

#### Clinical Consensus

- NRS 4–5 commonly used as lower limit for "moderate" pain with functional impact
- Mild: 1–3; Moderate: 4–6; Severe: 7–10 (standard categorization)

---

### 2. Acute Trauma Pain

#### Emergency Department / Trauma Data

- **57.4%** of trauma patients present with NRS 5–10 (moderate to severe pain)
- **42.6%** present with NRS 0–4 (mild)
- NRS validated for acute pain in ED and trauma settings
- Single significant wound often produces moderate pain (NRS 4–6) immediately

**Implication:** One moderate combat wound can reasonably map to NRS 4–5. First effect after 1–2 moderate hits is medically plausible.

#### Combat Injury Research

- Combat stress can increase pain sensitivity (mechanosensitivity) in some models
- Chronic pain >80% in combat injury survivors
- Acute pain management affects recovery; early intervention important
- Stress and injury create compounded pain responses

---

### 3. Mapping to Game System

#### Current Implementation (Method B)

- `effective_pain = total_pain / pain_reference`
- Thresholds: NRS 4 (first effect), 6 (moderate), 8 (severe), 10 (intolerable)
- Pain shock: NRS 7

#### Pain Reference Divisor

| Divisor | Human ref | Hits to first effect (NRS 4) | Research alignment |
|---------|-----------|------------------------------|--------------------|
| 16 | 6 | ~4 moderate hits | Conservative; underestimates acute trauma impact |
| **32** | **3** | **~2 moderate hits** | **Research-aligned (Krebs 4–6 band; Option A)** |
| 64 | 1.5 | ~1 moderate hit | Maximum realism (57% trauma present NRS 5–10) |

**Recommended:** Divisor **32** — first effect after ~2 moderate hits. Aligns with Krebs (NRS 4–6 = functional impairment), Boonstra low-catastrophizing (moderate starts at 4), and acute trauma data, while avoiding excessive punishment from single hits.

---

### 4. Shock Threshold (NRS 7)

- Boonstra: severe pain ≥ 7–8
- Krebs: NRS 7–10 = 5.60× likelihood of interference
- Acute stress reaction / concussion: severe single impacts cause longer disorientation
- **NRS_SHOCK = 7.0** aligns with transition to severe pain and acute stress

---

### 5. Summary of Research-Aligned Values

| Constant | Value | Research basis |
|----------|-------|----------------|
| NRS_FIRST_EFFECT | 4.0 | Krebs 4–6 band; Boonstra low-catastrophizing; clinical consensus |
| NRS_MODERATE | 6.0 | Boonstra moderate 6–7; Krebs 4–6 upper bound |
| NRS_SEVERE | 8.0 | Boonstra severe ≥8 |
| NRS_INTOLERABLE | 10.0 | Scale maximum |
| NRS_SHOCK | 7.0 | Severe pain threshold; acute stress |
| Pain reference divisor | 32 | ~2 moderate hits to first effect; Krebs/Boonstra aligned |

---

### 6. References

- Krebs EE et al. (2007). Accuracy of the Pain Numeric Rating Scale as a Screening Test in Primary Care. *J Gen Intern Med* 22(10):1453–1458.
- Boonstra AM et al. (2016). Cut-Off Points for Mild, Moderate, and Severe Pain on the NRS. *Frontiers in Psychology* 7:1466.
- Emergency/trauma NRS distribution (SJTREM, EMS pain assessment)
- Pain after combat injury (PMC, UK military Afghanistan)

---

<a id="wound-packing-medieval-research"></a>

## Source: `WOUND_PACKING_MEDIEVAL_RESEARCH.md`

## Wound Packing: Medieval Implementation Research

### Historical Background

#### Ancient and Medieval Practice

- **Hippocrates (5th c. BCE)**: Clean dry linen applied to wounds; wine/vinegar as medicaments. Bandaging to bring wound edges together.
- **Celsus (1st c. CE)**: To stop bleeding—apply dry lint, then a sponge wrung in cold water firmly. If bleeding continues, soak sponge in vinegar. Vessel ligation or cautery as last resort.
- **Albucasis (11th c.)**: Packed wounds with powders (incense, dragon's blood, lime). Also recommended dressings with washed lime and oil of roses.
- **Crusades (12th–13th c.)**: Medieval surgeons used clean linen cloth, wound suturing, arrow removal. Military orders (St. John, Temple) had hospitals with treatment protocols.

#### Principle

Packing = filling the wound cavity with material to apply pressure from within. Surface bandages compress from outside; packing reaches deep bleeding sources. When tourniquets cannot be used (neck, groin, axilla, chest), packing is the alternative.

#### Medieval Materials

- Linen cloth, lint, wool
- Clean dry cloth (when hemostatic agents unavailable)
- Herbal preparations (honey, vinegar, wine)

---

### Modern TCCC Guidelines (for comparison)

- **Indication**: Junctional hemorrhage (neck, groin, axilla) or compressible wounds where tourniquet doesn't apply
- **Technique**: Pack tightly with hemostatic gauze or clean cloth; fill cavity completely; hold direct pressure 3+ minutes
- **Materials**: Combat Gauze (hemostatic) preferred; if unavailable, gauze or clean dry cloth

---

### Implementation Proposal for Medieval System

#### When to Use Wound Packing

| Body Part | Tourniquet | Bandage | Packing |
|-----------|------------|---------|---------|
| Limbs     | ✓ (severe) | ✓       | —       |
| Head      | ✗          | ✓       | ✓ (deep) |
| Chest     | ✗          | ✓       | ✓ (deep) |

**Packing indicated when:**
- Head or chest wound
- Wound is severe or critical (deep cavity)
- Optionally: when bandage has failed or bleeding rate remains high

#### Mechanic Design

1. **New action**: `pack_wound` (or `pack_with_linen`)
2. **Target parts**: head, chest only (junctional/non-compressible areas)
3. **Effect**: Stronger than bandage for deep wounds—e.g. 85% reduction, faster clotting, or higher success rate
4. **Time**: Longer than bandage (packing cavity takes time)—e.g. 8–12 seconds base
5. **Materials**: Abstract "linen" or consumable; or unlimited (like bandage) for simplicity
6. **Success/failure**: Same pattern as bandage—medical skill affects outcome; failure allows retry

#### Medieval Flavor

- **Name**: "Pack wound with linen" / "Stuff wound"
- **Description**: Fill the wound cavity with linen strips to apply pressure from within. Used for deep chest or neck wounds where surface bandages cannot reach.
- **Era-appropriate**: No hemostatic agents (chitosan, kaolin); plain linen/cloth. Effectiveness comes from technique and pressure, not modern chemistry.

#### Integration with Existing System

- **Mutually exclusive with bandage** on same part? Or **stackable**—pack first, then bandage over? Research suggests pack + pressure + bandage wrap. Could allow: pack (fills cavity) + bandage (secures). Or treat pack as "upgraded bandage" for head/chest.
- **Simpler approach**: Packing is an alternative to bandage for head/chest when wound is severe/critical. Same success/failure logic as bandage; better effectiveness constants.

#### Suggested Constants (BleedingConstants.gd)

```gdscript
# Wound packing (head/chest; deep cavity; linen/cloth stuffed into wound)
const PACKING_PARTS: Array = ["head", "chest"]
const PACKING_IMMEDIATE_REDUCTION: float = 0.85  # stronger than bandage for deep wounds
const PACKING_SUCCESS_BASE_CHANCE: float = 0.65  # harder than bandage (technique)
const PACKING_APPLICATION_TIME_SECONDS: float = 10.0
```

---

### Summary

Wound packing fits the medieval setting: linen/cloth packed into deep wounds is historically attested. It adds a head/chest–specific option for severe hemorrhage where tourniquets cannot be used (neck, thoracic, abdominal). Implementation would mirror bandage (success roll, medical skill, failure = retry) with different effectiveness and timing.

---

<a id="incapacitation-flee-fallback-cowering-investigation"></a>

## Source: `INCAPACITATION_FLEE_FALLBACK_COWERING_INVESTIGATION.md`

## Incapacitation: Flee, Fall Back, and Cowering

Investigation of when units can flee or fall back vs when they must cower, and how to model "too injured to move."

---

### Current Model (Codebase)

#### Definitions

| Concept | Location | Logic |
|--------|----------|-------|
| `is_cowering()` | CoreEntity.gd | `get_attacking_arm().is_empty()` — no usable arms to fight |
| `is_incapacitated()` | CoreEntity.gd | `consciousness < 10` OR `is_cowering()` |
| `get_leg_functionality()` | BodyPartQuery.gd | Geometric mean of both legs; 0.08 if either destroyed |
| `get_effective_speed()` | CoreEntity.gd | `agility × leg_functionality` (for mobility) |

#### State Flow

- **STATE_COWERING:** Unit has no functional arms (both severed/crushed or unusable). They can't attack or parry. They stand defensively until arms recover.
- When arm functionality returns → `process_incapacitation` sets `STATE_WAITING` and schedules `EVENT_ACTION_READY`.
- **consciousness < 10:** Unit is effectively unconscious; cannot act at all.

#### Shipped (Tier 6.1 — live path)

See [§6.1 live path](#tier-61-mobility-pain-shock-live-path): **`can_flee_or_fall_back()`**, formation **`fall_back`** for mobile cowering, unconscious vs cowering combat gates. Investigation prose below remains design context.

#### What remains optional / out of scope for 6.1

- **Flee** (full disengage retreat) duration / pressure tuning — see **`TACTICAL_FORMATIONS_FF4.md`** / movement investigations.
- **Wound packing** and other medical-phase extensions — investigations in this bundle only.

---

### Design Question 1: Flee vs Fall Back vs Cowering

**Scenario A:** Unit has no arms (cowering) but functional legs.  
**Scenario B:** Unit has arms but no legs (cannot walk).  
**Scenario C:** Unit has low consciousness (e.g. 15) but can still stand and move.  
**Scenario D:** Unit has both arms and legs but consciousness < 10 (fully incapacitated).

#### Desired Behavior

| Scenario | Can fight? | Can flee? | Can fall back? | State |
|----------|------------|----------|----------------|-------|
| A (no arms, good legs) | No | Yes | Yes | Cowering — but mobile |
| B (arms, no legs) | Yes (in place) | No | No | Not cowering; immobile |
| C (low consciousness, mobile) | Degraded | Yes (if above threshold) | Yes | Not incapacitated |
| D (consciousness < 10) | No | No | No | Incapacitated |

#### Recommendation

1. **Cowering = can't fight (no arms).** Keep current definition. Cowering does *not* mean "can't move."
2. **Immovability = separate concept.** Add `can_move()` or `get_mobility_factor()` based on `get_leg_functionality()`. When legs are destroyed (0.08) or very low, unit cannot flee or fall back.
3. **Incapacitation (consciousness < 10)** = cannot act, cannot move. No flee, no fall back, no fight.
4. **Flee / fall back** (Phase 5 formation actions) require:
   - `consciousness >= INCAPACITATION_CONSCIOUSNESS_THRESHOLD`
   - `get_leg_functionality() >= MOBILITY_THRESHOLD` (e.g. 0.2 or 0.3)
   - Unit is not dead.

---

### Design Question 2: When Should Cowering Take Place?

**Current:** Cowering when `get_attacking_arm().is_empty()` — no usable arms.

**Proposed refinement:**
- **Cowering** = cannot fight (no arms). Already correct.
- **Cowering should NOT require** "too injured to move." A cowering unit *may* be mobile. If they have legs, they can flee or fall back when formation actions exist.
- **If too injured to move** (legs destroyed, consciousness < 10): unit is incapacitated or immobile. They don't "cower" — they collapse or are unable to act. Distinguish:
  - **Cowering (mobile):** No arms, can still walk. Allowed to flee/fall back.
  - **Cowering (immobile):** No arms, no legs. Cannot flee/fall back. Stays in place until healed or dies.
  - **Unconscious:** Consciousness < 10. Cannot do anything.

---

### Implementation Outline (Phase 5+)

When implementing formation actions (flee, fall back):

#### 1. Mobility Check

```gdscript
# CoreEntity or helper
func can_flee_or_fall_back() -> bool:
    if consciousness < _PainConscious.INCAPACITATION_CONSCIOUSNESS_THRESHOLD:
        return false
    var leg: float = get_leg_functionality()
    return leg >= MOBILITY_FLEE_THRESHOLD  # e.g. 0.2
```

#### 2. Formation Action Availability

- **Flee:** Requires `can_flee_or_fall_back()`. Uses disengage + full retreat. Duration scales with leg functionality, armor burden, opponent pressure (see `MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md`).
- **Fall back:** Same requirement. Disengage + move to rear rank/zone.
- **Cowering units** (no arms) can flee/fall back if mobile. They are not forced to stay and die.

#### 3. Constants

| Constant | Suggested | Rationale |
|----------|------------|-----------|
| `MOBILITY_FLEE_THRESHOLD` | 0.2 | Leg functionality below this = cannot walk effectively |
| `INCAPACITATION_CONSCIOUSNESS_THRESHOLD` | 10.0 | (existing) Below = unconscious |

---

### Summary

| Question | Answer |
|----------|--------|
| Can unit flee when cowering (no arms)? | **Yes**, if legs are functional. Cowering = can't fight, not can't move. |
| Can unit fall back when cowering? | **Yes**, same condition. |
| When should cowering take place? | When **no usable arms** (`get_attacking_arm().is_empty()`). Unchanged. |
| When is unit too injured to move? | When `get_leg_functionality() < MOBILITY_FLEE_THRESHOLD` or `consciousness < 10`. |
| Cowering only when too injured to move? | **No.** Cowering = no arms. Immobility is separate; use leg functionality for flee/fall back. |

---

### References

- `core/CoreEntity.gd` — `is_cowering()`, `is_incapacitated()`, `get_leg_functionality()`, `get_effective_speed()`
- `core/BodyPartQuery.gd` — `get_leg_functionality()` (both legs needed; geometric mean)
- `core/PainConsciousnessConstants.gd` — `INCAPACITATION_CONSCIOUSNESS_THRESHOLD`
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — Fall back mechanics, duration, opponent pressure
- `docs/TACTICAL_FORMATIONS_FF4.md` — Phase 5: formation actions (fall back, flee)

---
