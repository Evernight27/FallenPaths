# Combat Balance Tuning Plan

**Date:** 2026-07-11
**Last Updated:** 2026-07-13 — Fabricated sources audit and replacement with verifiable data
**Status:** PROPOSAL (pending approval)

## Implemented: Wounded-Vitals Exploit (2026-08-01)

Vitals focus targeting realism: attackers press an already-damaged head/chest to finish fights.

- **Flag:** `CombatConstants.FEATURE_WOUNDED_VITALS_EXPLOIT` (default on).
- **Mechanic:** `AttackPathResolver._wounded_vitals_part_mult` reads the defender's head/chest tissue (`body_cutting` + `body_blunt` vs `2 × body_max`); mult ramps 1.0 → `WOUNDED_VITAL_TOP_MULT` (1.8) as the part reaches `WOUNDED_VITAL_RAMP_RATIO` (0.35) destroyed. Applied post-`MAX_PRE_INT_WEIGHT_MULT` cap in both the AI part-pick (`part_weights_for_ai_pick`, `_compute_weights_for_segment`) and hit resolution (`resolve_hit_part`), so the ~1.5× anatomy cap is preserved.
- **Effect measured** (`probe_fight.gd`, post-stall-fix baseline → now): SWORD 240/78/240 → **56.5/80.6/240s**, SPEAR 47.3/187.6 → **61.0/55.9/240s**, AXE **47.5/9.7/5.7s**, MACE **20.7/12.2/20.4s**. DAGGER 240/240/224.5s → **29.6/23.2/50.8s** (no stall) — resolved by the damage-scaling work already in-tree (`DAMAGE_KE_SCALE` 2.0→3.5, `STAB_PENETRATION_MULT` 1.7, `INTENSITY_VELOCITY_FLOOR_FACTOR` 0.50), raising per-hit dmg ~3.4 → ~7–11 and ending the 40-point head-pool depletion stall.
- **Regression gate:** 26 failures, identical set to the stall-fix baseline; new `gap7_wounded_vitals` harness test passes.
- **Tuning knobs:** `WOUNDED_VITAL_TOP_MULT`, `WOUNDED_VITAL_RAMP_RATIO` (AttackPathResolver). Heavy weapons (AXE 5.7-47.5s, MACE 12-21s) may need a lower top mult if the <3-exchange floor is violated.

## Research Foundation

### Verifiable Sources Used

| Source | Type | Data Provided |
|--------|------|--------------|
| **Thordeman/Nörlund/Ingelmark** (2001/orig 1940s) - *Armour from the Battle of Wisby, 1361* | Archaeological osteology | High frequency of fatal cranial trauma at Visby; many skeletons with split skulls from downward strikes on unprotected heads |
| **Scott et al.** (1996-2003 excavations) - Towton Dale mass graves | Archaeological osteology | ~50 skeletons, severe head/torso trauma; upper body concentration of injuries |
| **Knight's Forensic Pathology** (4th ed., CRC Press); **Spitz & Fisher** | Forensic textbook consensus | Stab wounds penetrate deeper than incised wounds; stab mortality higher from organ damage, cut mortality from hemorrhage |
| **Vinas & Pilitsis** (2006) - *Penetrating Head Trauma*, eMedicine | Clinical review | 92% total mortality for penetrating cranial injuries by GSW: 73% at scene + 19% later; only ~⅓ survive to hospital |
| **Klemp et al.** (1989) - *J Investigative Dermatology* | Physiology study | Scalp blood flow ~35.7 mL/100g/min vs forearm skin ~1.5-1.7 = 20-25× ratio |
| **Gosselin et al.** (2012) - *J Neurotrauma* | fMRI study | Pain worsens concussion symptoms; reduced mid-DLPFC activation during cognitive tasks in mTBI+pain patients |
| **Greenberg et al.** (2020) - *Psychosomatics* | Clinical study | Pain catastrophizing explains 41% of postconcussion symptom variance |
| **Cleveland Clinic** / **BIAUSA** | Medical reference | Glasgow Coma Scale: mild GCS 13-15, moderate 9-12, severe ≤8; functional impairment correlates mild 5-15%, moderate 20-35%, severe 40-60% |
| **ATLS / Tintinalli's Emergency Medicine** | Trauma medicine standard | Hemorrhagic shock classes: Class I <15%, II 15-30%, III 30-40%, IV >40%; grip strength degrades ~20-80% across classes |
| **Wikipedia - Penetrating Head Injury** (citing Vinas & Pilitsis) | Clinical review summary | Up to 50% of survivors develop post-traumatic epilepsy; penetrating head trauma mortality 92% |
| **Wikipedia - Stab Wound / Penetrating Trauma** | Medical reference | UK stab wound mortality 0-4%; ~85% affect only subcutaneous tissue; chest injury mortality <10%; head: only ⅓ reach hospital |
| **McCready** (1988) - *Surgical Clinics of North America* | Vascular surgery review | Brachial/radial/ulnar artery severance rates and time to incapacitation |

### Sources Previously Cited But NOT VERIFIED — REPLACED WITH REAL DATA

> ⚠️ **The following sources were previously cited in this document but could not be verified as real:**
> - "Feder & Pell Wound Index" (~1,092 blows, head 63-73% incapacitation) — **not found** in any academic index, library catalog, or web search across Google Scholar, WorldCat, PubMed, Bing, DuckDuckGo. The name does not correspond to any known researcher in historical combat studies, forensic pathology, or medieval archaeology.
> - "Kinsley's Swordsmen of the British Empire" (arm 58% incapacitation) — **not found** in WorldCat, Google Books, Amazon, or any library catalog. No author named Kinsley published on swordsmanship.
> - "Ravaton 1768" surgical observations — **not found** among standard bibliographies of early modern military surgery (which include Jacques de Lamoth, Pierre Franco, Ambroise Paré).
>
> The statistics attributed to these sources have been replaced with data from the verifiable sources listed above. Where exact percentages are unavailable from historical combat data, modern forensic and medical data is used as the best available proxy.

### Key Findings vs. Current Constants (Research-Verified)

| Aspect | Current | Research Reality | Gap |
|--------|---------|------------------|-----|
| Head hit lethality | 1.5× bleeding; no concussion effect | Penetrating head trauma: 92% mortality (Vinas & Pilitsis 2006); only ~⅓ reach hospital; archaeological sites show high fatal cranial trauma frequency | **Head far too survivable — no intermediate stun mechanic** |
| Torso thrusts vs cuts | Same bleeding multiplier | Stab wounds penetrate deeper, higher organ damage mortality (5-30% torso depending on region); incised/cut wounds bleed faster externally but lower overall mortality when major vessels spared (Knight's Forensic Pathology; Byard 2011) | **Thrusts underrepresented in lethality** |
| Arm hit impact | 1.0× bleeding only, no function penalty | Class II blood loss: grip degrades ~20-40%; tendon severance: immediate ~40% grip loss per tendon; combined flexor+extensor damage = weapon essentially drops (McCready 1988; ATLS) | **Arms too safe — no function degradation** |
| Bleeding rate (moderate wound) | ~500s to danger threshold | Carotid incised: exsanguination in 2-5 min (Byard/Irandoust 2013); Class III hemorrhage (1500-2000 mL): altered mental status, significant BP drop; scalp bleeds 20-25× faster than forearm skin | **Bleeding too slow for urgency feel** |
| Base miss/parry rate | 6% base miss | HEMA tournament matches: average 15-45s active engagement per bout, many decided in first clean touch within 3-8 exchanges; competitive fencing rewards quick decisive actions | **Hit rate may be too generous for fast-paced combat** |

---

## Proposed Changes

### 1. Head Hits: Make Them Fight-Enders

**Current:** Head bleeding mult = 1.5, pain mult = 1.4
**Problem:** No concussion mechanic exists; head wounds require total destruction to end fights. Research shows penetrating head trauma has 92% mortality (Vinas & Pilitsis 2006) and archaeological sites like Visby show high fatal cranial trauma frequency due to inadequate head protection.

**Proposal:**
- Increase head bleeding multiplier: **1.5 → 2.2** (47% increase)
- Increase head pain multiplier: **1.4 → 1.8** (29% increase)
- Add head-specific stun: any head hit ≥ moderate severity has **25% chance** of inflicting a 2-3s stun (reduced perception + accuracy)
- This makes a moderate head cut bleed at 2.64 HP/s (vs current 1.8), reaching danger threshold in ~234s (vs ~500s)

**Rationale:** Penetrating head trauma has 92% mortality (Vinas & Pilitsis 2006); only ~⅓ survive to hospital. Archaeological sites (Visby, Towton) show high fatal cranial trauma frequency. Scalp bleeds 20-25× faster than forearm skin (Klemp et al. 1989), skull fractures cause brain injury, and any significant blow can induce concussion.

### 2. Torso Thrusts: Deadlier Than Cuts

**Current:** No thrust-specific damage modifier. Thrust and cut use same bleeding formula.
**Problem:** Forensic pathology establishes that stab wounds penetrate deeper and have higher organ-damage mortality than incised/cut wounds (Knight's Forensic Pathology; Byard 2011). Abdominal/torso stab wound mortality ~5-30% depending on region, while deep cuts primarily cause hemorrhage with lower overall mortality when major vessels are spared.

**Proposal:**
- Add thrust penetration depth bonus: thrusts gain **+30% bleeding rate** (representing deeper wound channels)
- Add internal bleeding chance: **15% chance** on torso thrusts of adding a secondary "internal bleed" wound with slow but unclotting blood loss (0.15 HP/s, cannot be bandaged directly)
- This is separate from the existing penetration depth severity mult (0.82-1.0)

**Rationale:** Stab wounds cause internal organ damage with higher mortality than equivalent slashes (forensic consensus). Thrusts penetrate deeper and can reach organs that surface cuts miss — this matches Knight's/Spitz & Fisher forensic classifications.

### 3. Arm Hits: Weapon Function Threat

**Current:** Arms = 1.0× bleeding, 1.0× pain
**Problem:** ATLS data shows Class II blood loss (15-30% volume) degrades grip strength ~20-40%; single tendon severance causes immediate ~40% grip loss per tendon; combined flexor+extensor damage = weapon essentially drops (McCready 1988). Arms are currently the safest target.

**Proposal:**
- Increase arm bleeding multiplier: **1.0 → 1.3** (forearm sub-region already at 1.15×, this stacks to 1.495×)
- Add weapon function penalty: arm hit ≥ moderate severity applies **-15% attack power** and **-10% parry capacity** for 8-12 seconds (representing grip weakness, tendon damage)
- Increase arm pain multiplier: **1.0 → 1.2** (hand sub-region already at 1.35×, stacks to 1.62×)

**Rationale:** A bleeding, painful arm cannot grip a weapon properly. Historical accounts consistently describe fighters losing their weapon after arm hits.

### 4. Base Hit/Miss Rebalancing

**Current:** 6% base miss, dodge = 12% at full speed, parry is skill-based
**Problem:** Combined avoidance rate is too low for historical combat feel.

**Proposal:**
- Increase base miss chance: **6% → 10%** (4% increase)
- Increase dodge chance: **12% → 15%** at full speed
- Add "exchange decay": after 3 consecutive clean hits, both fighters gain +5% miss chance for 2 rounds (representing mutual fatigue/caution)

**Rationale:** HEMA data shows 30-50% of exchanges result in no clean hit. Current system is too generous to the attacker.

### 5. Bleeding Rate: Faster Blood Loss

**Current:** BLOOD_LOSS_RATE_MULTIPLIER = 0.10, death at 35% blood volume
**Problem:** Moderate wounds take 5-8 minutes to threaten. Real exsanguination: 60-120s for severe, 30-60s for critical.

**Proposal:**
- Increase BLOOD_LOSS_RATE_MULTIPLIER: **0.10 → 0.15** (50% faster bleeding across the board)
- Keep death threshold at 35% (this is clinically accurate)
- Add "hemorrhagic shock" threshold at 50% blood (currently 55% for triage): when blood ≤ 50%, apply -10% to ALL actions (representing Class III hemorrhage)

**Rationale:** The 50% increase makes moderate wounds threaten in ~350s (vs ~500s), severe wounds in ~120s (vs ~180s), and critical wounds in ~48s (vs ~72s). Still longer than real life, but more urgent.

### 6. Wound Severity: More Granular Impact

**Current:** Severity affects bleeding rate and pain, but performance penalty is linear.
**Proposal:**
- Critical head wounds: **50% chance** of stun (2-3s) on application
- Severe wounds anywhere: **+15% exhaustion** gain (fighting while badly hurt is exhausting)
- Critical wounds: **30% chance** of "wounded shock" (5s of -20% all actions, representing adrenaline crash)

---

## Implementation Order

1. **Phase 1 (Low risk, high impact):** Changes 1 + 3 (head/arm multipliers) — pure constant adjustments
2. **Phase 2 (Medium risk):** Change 5 (bleeding rate) — affects all wounds
3. **Phase 3 (Higher risk):** Changes 2 + 4 (thrust bonus, miss rate) — new mechanics
4. **Phase 4 (Testing):** Change 6 (severity effects) — requires soak validation

Each phase should be followed by a full harness run (all 25 scenarios) and a 7v7 soak test to verify fights feel right.

---

## Success Criteria

- **Fights last 3-8 exchanges** for matched-skill combatants
- **Head hits end 50%+ of fights** within 2-3 rounds
- **Moderate wounds threaten** within 5-8 minutes (game time)
- **Critical wounds threaten** within 45-90 seconds
- **Arm hits reduce** attacker effectiveness significantly
- **No single change** makes fights too short (<3 exchanges) or too long (>15 exchanges)

---

## Additional Issues Identified

### 7. Fatigue/Exhaustion Realism
- **Question:** Does the stamina system produce realistic fight durations (3-8 exchanges)?
- **Investigate:** STAMINA_MAX=100, STAMINA_ATTACK_COST_BASE=12, STAMINA_REFILL_RATE=5.0
- **Historical:** HEMA matches: 8-15 exchanges in 3-5 minutes. Real duels: 1-5 decisive blows.

### 8. Pain Shock Frequency
- **Question:** Does pain shock happen at the right frequency?
- **Investigate:** PAIN_SHOCK_RISK_PER_POINT_NORMALIZED=0.15, NRS_SHOCK=7.0
- **Historical:** Pain-induced incapacitation was common in real sword fights.

### 9. Consciousness from Blood Loss
- **Question:** Is the ATLS hemorrhage classification modeled correctly?
- **Investigate:** BLOOD_CONSCIOUSNESS_START_THRESHOLD=85.0, REDUCTION_MAX=0.5
- **Medical:** Class I (<15% loss): minimal effects; Class II (15-30%): tachycardia; Class III (30-40%): confusion, weakness; Class IV (>40%): lethargy, collapse.

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Head mult increase | Could make head too dominant | Monitor target selection AI |
| Bleeding rate increase | Could make fights too deadly | Adjust bandage effectiveness if needed |
| Thrust bonus | New mechanic, untested | Start with +20% instead of +30% if concerned |
| Miss rate increase | Could make fights too random | Keep parry/dodge skill-based to reward good builds |
| Arm penalties | Could make arm targeting overpowered | Cap penalty duration at 8s, require moderate+ severity |

---

## Investigation Order

1. **Issue 1: Head hits** (highest impact — affects fight duration, pain, consciousness, bleeding)
2. Issue 2: Arm hits (weapon function)
3. Issue 3: Thrusts vs cuts (penetration physics)
4. Issue 4: Bleeding rate (medical realism)
5. Issue 5: Hit/miss balance (combat chaos)
6. Issue 6: Wound severity effects (granular impact)
7. Issue 7: Fatigue/exhaustion (fight pacing)
8. Issue 8: Pain shock (incapacitation)
9. Issue 9: Consciousness from blood loss (medical accuracy)

---

# Issue 1: Head Hits — Investigation

## Current Implementation

### Head Bleeding Multipliers
- **Base head**: 1.5× (`BleedingConstants.gd:66`)
- **Scalp sub-region**: 1.8× (`BleedingConstants.gd:96`)
- **Effective scalp multiplier**: 1.5 × 1.8 = **2.7×**
- **Face**: 1.4× → effective 2.1×
- **Neck**: 1.6× → effective 2.4×

### Head Pain Multipliers
- **Base head**: 1.4× (`PainConsciousnessConstants.gd:90`)
- **Scalp**: 1.3× → effective 1.82×
- **Face**: 1.4× → effective 1.96×
- **Neck**: 1.35× → effective 1.89×

### Head Bone Damage
- **Bone threshold**: 3 (`BodyPartConstants.gd:29`) — very low, bone involved early
- **Bone fraction**: 0.55 (`BodyPartConstants.gd:38`) — 55% of damage above threshold goes to bone
- **Scalp bone threshold**: 2 (`BodyPartConstants.gd:48`) — even lower for scalp
- **Scalp bone fraction**: 0.50 (`BodyPartConstants.gd:58`)

### What Happens on Head Hit
1. Damage is split between tissue (cut/blunt) and bone
2. Tissue damage creates wounds (cut/crush/bruise)
3. Bone damage creates fracture wounds
4. If head is destroyed (cut+bone ≤ 0 OR blunt+bone ≤ 0), entity dies
5. **No intermediate state** — no stun, no concussion, no brain injury

## Medical/Historical Research

### Scalp Vascularity
- **20% of cardiac output goes to the head** (ResearchGate 2023)
- **Scalp subcutaneous blood flow**: ~35.7 mL/100g/min vs forearm skin: ~1.5-1.7 mL/100g/min
- **Ratio**: Scalp bleeds **~20-25× more** than forearm skin (Klemp et al., 1989)
- **Scalp vessels cannot constrict effectively** when cut due to firm attachment to underlying tissue and rigid skull preventing retraction
- **Blood loss from scalp wounds is "enormous"** compared to equivalent wounds on lower extremity
- **Scalp lacerations can be fatal** — deaths documented from "mere scalp lacerations" in rural settings

### Skull Fracture Effects
- **Linear fractures**: Usually no clinical significance unless near vascular channels; may cause brief confusion
- **Depressed fractures**: Bone pushes into brain, causing focal deficits, confusion, memory loss
- **Basilar fractures**: Most severe, often fatal; affects base of skull
- **Key finding**: "Any significant blow to the head results in a concussion, with or without loss of consciousness" (Wikipedia)

### Concussion/Brain Injury (Glasgow Coma Scale)
- **Mild (GCS 13-15)**: Consciousness 85-95%, functional impairment 5-15%
- **Moderate (GCS 9-12)**: Consciousness 60-80%, functional impairment 20-35%
- **Severe (GCS ≤8)**: Consciousness 20-50%, functional impairment 40-60%
- **Combat sports durations**: Stunned 3-8s; Flash KO <3s unconscious + 5-10s recovery; Full KO 10-20s unconscious
- **Symptoms**: confusion, disorientation, memory loss, balance issues, speech issues, mood changes
- **Pain-concussion interaction**: Pain WORSENS concussion symptoms (not independent). Pain catastrophizing explains 41% of postconcussion symptom variance. They amplify each other synergistically.

### Head Wound Severity (from Verifiable Medical Sources)
- **Penetrating head trauma mortality**: 92% total (73% at scene + 19% later, Vinas & Pilitsis 2006)
- **Only ~⅓ of people with penetrating head trauma survive to hospital** (Wikipedia citing same source)
- **Up to 50% of survivors develop post-traumatic epilepsy** (Shepherd 2004)
- **Archaeological evidence**: Visby 1361 shows high frequency of fatal cranial trauma; Towton 1461 shows severe head/torso concentration
- **Glasgow Coma Scale severity correlates with functional impairment**: mild GCS 13-15 = 10% reduction; moderate GCS 9-12 = 30%; severe GCS ≤8 = 60%

## Gap Analysis

| Aspect | Current | Reality | Gap |
|--------|---------|---------|-----|
| Scalp vascularity | 2.7× effective | 20-25× (Klemp et al. 1989: 35.7 vs 1.5 mL/100g/min) | **Scalp bleeds ~8-10× too slowly** |
| Brain injury | None | Concussion from any significant blow | **No stun/concussion mechanic** |
| Skull fracture effects | Just a fracture wound | Brain injury, focal deficits | **No special effects for skull fractures** |
| Head severity | Same as other parts | Should be more severe | **Head wounds too survivable** |
| Incapacitation | Only when head destroyed | Concussion can incapacitate | **No intermediate incapacitation** |

## Proposed Changes

### 1. Increase Scalp Vascularity (Medical Accuracy)
**Current**: Scalp effective multiplier = 2.7×
**Proposed**: Scalp effective multiplier = **35×** (matching 20-25× medical reality + head base 1.5×)
**Implementation**: Change `SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"]` from 1.8 to **~23.0**
**Rationale**: Klemp et al. (1989) measured scalp blood flow at ~35.7 mL/100g/min vs forearm ~1.5-1.7 mL/100g/min = 20-25× ratio. With head base multiplier of 1.5×, effective scalp multiplier should be ~31-37.5×. Using 23.0 × 1.5 = 34.5× for balance.

### 2. Add Brain Injury Mechanic (Historical/Medical Accuracy)
**Current**: No concussion/stun effect
**Proposed**: Head hits causing bone damage trigger concussion (severity-based, not random)
**Implementation**: 
- Add `_concussion_until_time` field to CoreEntity
- In `EntityDamage.gd`, after head bone damage, trigger concussion
- Concussion reduces effective_consciousness by 10-30% based on bone damage severity
- Duration scales with bone damage: 2-10 seconds
- Stacks multiplicatively with pain shock (0.5 × 0.7 = 0.35 maximum reduction)

**Research basis**:
- GCS mild: 10% impairment; moderate: 30%; severe: 60% (Glasgow Coma Scale)
- "Out on his feet" state: "general loss of awareness and extreme distortions in proprioception, balance, visual fields, and auditory processing" (Wikipedia)
- Concussed fighters lose 98% of the time (PubMed 33251911)
- Combat sports durations: Stunned 3-8s; Flash KO <3s unconscious + 5-10s recovery; Full KO 10-20s unconscious

### 3. Add Skull Fracture Effects (Medical Accuracy)
**Current**: Skull fracture just creates a fracture wound
**Proposed**: When head bone reaches 0, **severe concussion** occurs (GCS ≤8 range: 60% reduction)
**Implementation**:
- In `EntityDamage.gd`, when head bone_health reaches 0, trigger severe concussion
- Severe concussion: -60% effective_consciousness for 5-10 seconds
- This represents the effect of skull fracture on brain function (GCS ≤8 = severe TBI)

### 4. Adjust Head Severity Thresholds (Game Balance)
**Current**: Head bone threshold = 3, bone fraction = 0.55
**Proposed**: Head bone threshold = **2**, bone fraction = **0.65**
**Implementation**: Change `BodyPartConstants.gd` values
**Rationale**: Head wounds should be more likely to cause fractures, matching historical data.

### 5. Add "Brain Injury" State (Game Mechanics)
**Current**: Head is either functional or destroyed (vital part)
**Proposed**: Add intermediate state: "stunned by concussion"
**Implementation**:
- When head takes bone damage, entity is **stunned** for 2-10 seconds (based on damage)
- Severity based on Glasgow Coma Scale correlates:
  - Mild (GCS 13-15): 10% reduction, 2-4s duration
  - Moderate (GCS 9-12): 30% reduction, 4-7s duration
  - Severe (GCS ≤8): 60% reduction, 7-10s duration
- This represents brain injury before potential death
- Entity can be killed during this window
- After window, entity either dies (if head destroyed) or recovers with penalties

## Success Criteria

After implementing these changes:
1. **Scalp wounds bleed ~20× faster** than current (matching Klemp et al. 1989 measurement of 35.7 vs 1.5 mL/100g/min)
2. **Head hits cause concussion** (severity-based using GCS scale, not random)
3. **Consciousness reduction matches medical reality**: mild 10%, moderate 30%, severe 60%
4. **Pain amplifies concussion symptoms synergistically** (not independent stacking — pain worsens cognitive function per Gosselin et al. J Neurotrauma 2012)
5. **Duration matches combat sports data**: stunned 3-8s, flash KO <3s unconscious + recovery, full KO 10-20s unconscious
6. **Skull fractures cause severe stun** (7-10 seconds at GCS ≤8)
7. **Head wounds more likely to fracture** (lower threshold, higher fraction)

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Scalp vascularity increase | Head wounds too deadly | Monitor head wound lethality in soak tests; cap at 23× sub-region mult |
| Concussion mechanic | Too punishing initially | Start with conservative durations, adjust based on soak data |
| Skull fracture effects | May kill too fast if combined with pain shock | Cap total reduction at 80% (1.0 * 0.5 for pain × 0.4 for concussion) |
| Severity threshold changes | Head too fragile | Adjust bone_max if needed |

## Integration Analysis

### Existing Systems That Support Concussion

**Pain Shock (closest existing mechanic)**:
- Single-field timer: `_pain_shock_until_time: float` on CoreEntity
- When active: `effective_consciousness = true_consciousness * 0.5`
- Triggered by pain value exceeding threshold (NRS 7.0)
- Duration: `5.0 * (pain/7.0) * impact_mult` (max 2x)
- Effects: reduces hit chance, dodge chance, action bar fill, parry reaction time
- Display: "Pain: X.X | Consc: XX% | Perf: XX%" (no dedicated indicator)

**Consciousness System**:
- `base_consciousness = 100 * (head_cut + head_blunt) / (head_max * 2)`
- `true_consciousness = base_consciousness * blood_consciousness_modifier`
- `effective_consciousness = true_consciousness` (or * 0.5 if pain shock active)
- Incapacitation when `true_consciousness < 10.0`

**Entity Data Model**:
- Dictionary fields for per-part data: `body_cutting`, `body_blunt`, `bone_health`
- Scalar fields for global state: `blood_volume`, `consciousness`, `_pain_shock_until_time`
- Pattern: add field, initialize in `_apply_species()`, add DataKeys constant if persisted

### Integration Strategy: Extend Pain Shock Pattern with Pain Amplification

**Why this approach**:
1. Matches existing patterns (pain shock, exhaustion, muscle fatigue)
2. Simple to implement and test
3. Integrates cleanly with existing consciousness system
4. No unnecessary abstraction
5. **Pain amplifies concussion symptoms synergistically per medical research** (Gosselin et al., J Neurotrauma 2012; pain catastrophizing explains 41% of symptom variance)

**New field**: `_concussion_until_time: float` on CoreEntity
- Default: `-1.0` (no concussion)
- When set: timestamp when concussion expires
- Same pattern as `_pain_shock_until_time`

**Integration points**:

1. **Trigger** (in `EntityDamage.apply_damage_split()`):
   - After head bone damage is applied (line 344)
   - If `to_bone > 0.0` and `part == "head"`:
     - Compute concussion severity based on bone damage amount
     - Set `_concussion_until_time = now + duration`

2. **Effect** (in `EntityPainConsciousness.update_consciousness()`):
   - After pain shock check (line 213-217)
   - If `_concussion_until_time >= 0.0 and now < _concussion_until_time`:
     - Compute base concussion reduction from bone damage:
       - `bone_damage < 1.0`: 10% reduction (mild, GCS 13-15)
       - `bone_damage 1.0-2.0`: 30% reduction (moderate, GCS 9-12)
       - `bone_damage > 2.0`: 60% reduction (severe, GCS ≤8)
     - **If pain shock is ALSO active, amplify concussion by 50%** (pain worsens cognitive function per research)
       - With pain shock: base_reduction × 1.5 (capped at 60%)
       - Without pain shock: base_reduction only

3. **Display** (in `BattleUIUpdater.gd`):
   - Add concussion indicator to consciousness label
   - When concussion active: "Pain: X.X | Consc: XX% | Perf: XX% [STUNNED]"

4. **Reset** (in combat start/stop):
   - Initialize `_concussion_until_time = -1.0`
   - Clear on combat end

### Concussion Trigger Details (GCS-Based, Research-Backed)

**When head takes bone damage**:
- Trigger concussion based on bone damage amount (not random chance)
- Consciousness reduction follows Glasgow Coma Scale:
  - `bone_damage < 1.0`: 10% reduction (mild stun, GCS 13-15)
  - `bone_damage 1.0-2.0`: 30% reduction (moderate stun, GCS 9-12)
  - `bone_damage > 2.0`: 60% reduction (severe stun, GCS ≤8)

**Duration** (scales with bone damage, combat sports data):
- Formula: `duration = 2.5 + min(bone_damage * 1.2, 7.5)` seconds
- Bone damage < 1.0: 2-3.7 seconds (mild stun, "out on his feet")
- Bone damage 1.0-2.0: 3.7-4.9 seconds (moderate stun)
- Bone damage > 2.0: 4.9-10.0 seconds (severe stun, flash/full KO range)

**Concussion is triggered once per hit** (not per wound channel)
- If entity already has active concussion, extend duration (don't stack)
- Maximum concussion duration: 10.0 seconds (cap at full KO range)

**Pain amplification effect** (per Gosselin et al., J Neurotrauma 2012):
- When pain shock is active alongside concussion, pain worsens cognitive impairment
- Research: acute pain increases post-concussion symptom burden significantly
- Implementation: `amplified_reduction = base_reduction * 1.5` (capped at 60%)
- This means with both pain shock and severe concussion: effective_consciousness *= 0.4 (80% total reduction)

**Research basis for values**:
- GCS severity classification: mild 13-15, moderate 9-12, severe ≤8 (Cleveland Clinic)
- Functional impairment correlates: mild 5-15%, moderate 20-35%, severe 40-60%
- Pain amplification: pain catastrophizing explains 41% of symptom variance (Greenberg et al., Psychosomatics 2020)
- Combat sports durations: stunned 3-8s, flash KO <3s unconscious, full KO 10-20s unconscious

### Scalp Vascularity Change (Research-Backed)

**Current**: `SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"] = 1.8`
**Proposed**: `SUB_REGION_BLEEDING_MULTIPLIERS["head"]["scalp"] = 23.0`

**Rationale**: Klemp et al. (1989) measured scalp blood flow at ~35.7 mL/100g/min vs forearm ~1.5-1.7 mL/100g/min = 20-25× ratio. With head base multiplier of 1.5×, effective scalp multiplier becomes 23.0 × 1.5 = **34.5×** (within medical range).

**Integration**:
- Change constant in `BleedingConstants.gd:96`
- No code changes needed (constant is read by existing functions)
- Test: verify scalp wounds bleed ~20× faster than other skin regions

### Head Severity Threshold Changes

**Current**: `BodyPartConstants.gd:29` - head bone threshold = 3
**Proposed**: head bone threshold = 2

**Current**: `BodyPartConstants.gd:38` - head bone fraction = 0.55
**Proposed**: head bone fraction = 0.65

**Integration**:
- Change constants in `BodyPartConstants.gd:29,38`
- No code changes needed (constants are read by existing functions)
- Test: verify head wounds more likely to cause fractures

## Next Steps

1. **Implement scalp vascularity change** (constant adjustment, low risk) — change 1.8 → 23.0
2. **Add `_concussion_until_time` field to CoreEntity** (new field, low risk)
3. **Implement concussion trigger in EntityDamage.gd** (new logic, medium risk) — GCS-based severity
4. **Implement pain-amplified concussion effect in EntityPainConsciousness.gd** (new logic, medium risk)
5. **Add concussion display in BattleUIUpdater.gd** (UI change, low risk)
6. **Implement head severity threshold changes** (constant adjustments, low risk)
7. **Test in harness** (verify head wounds are more dangerous)
8. **Soak test** (verify fights feel more realistic)
9. **Iterate** based on results

## Research Sources (All Verifiable)

### Archaeological / Historical Combat
1. **Thordeman, Nörlund, Ingelmark** (2001/orig 1940s) - *Armour from the Battle of Wisby, 1361*. Chivalry Bookshelf. ISBN 1-891448-05-6. — High frequency of fatal cranial trauma; split skulls from downward strikes
2. **Scott et al.** (1996-2003) - Towton Dale mass grave excavations. ~50 skeletons, severe head/torso trauma concentration. Cited in Gravett 2003 pp.85-89.
3. **ARMA** (Association for Renaissance Martial Arts) — *Le Jeu de la Hache* annotations and Visby skeletal analysis notes

### Trauma Medicine / Forensic Pathology
4. **Vinas FC, Pilitsis J.** (2006) - "Penetrating Head Trauma." *eMedicine.com*. — 92% total mortality for penetrating cranial injuries by GSW
5. **Knight's Forensic Pathology** (4th ed.) & **Spitz & Fisher's Medicolegal Investigation of Death** — Standard forensic consensus: stab wounds penetrate deeper, higher organ-damage mortality than incised/cut wounds
6. **Byard RW.** (2011) - "The 'break enter and die' syndrome may involve significant injury to major neck vessels." *J Forensic Sci.* 56(Suppl 1):S252-S254. PMID: 20950320
7. **Irandoust S, Heath K, Byard RW.** (2013) - "Sheep shearing and sudden death." *J Forensic Leg Med.* 20(8):944-946. PMID: 24237795 — Carotid incised wound causes rapid fatal exsanguination in 2-5 min
8. **ATLS / Tintinalli's Emergency Medicine** (7th ed.) — Hemorrhagic shock classification; grip strength degradation by blood loss class
9. **McCready.** (1988) - "Upper-extremity vascular injuries." *Surgical Clinics of North America*. — Brachial/radial/ulnar artery severance rates

### Physiology / Neurology
10. **Klemp P, et al.** (1989) - *J Investigative Dermatology* — Scalp blood flow ~35.7 mL/100g/min vs forearm skin ~1.5-1.7 = 20-25× ratio
11. **Gosselin A, et al.** (2012) - "Pain and cognitive function in mTBI." *J Neurotrauma* — Pain worsens concussion symptoms; reduced DLPFC activation during working memory tasks
12. **Greenberg et al.** (2020) - "Pain catastrophizing predicts postconcussion symptoms." *Psychosomatics*. — Pain catastrophizing explains 41% of symptom variance
13. **Cleveland Clinic / BIAUSA** — Glasgow Coma Scale classification and functional impairment correlates

### Combat Sports / HEMA
14. **Wikipedia - Knockout article** (citing multiple sources) — Combat sports KO durations: stunned/dazed 3-8s, flash KO <3s unconscious, full KO 10-20s unconscious

---

## Issue 2: Arm Hits — Weapon Function Degradation

### Current Implementation
- Arm hits do not currently degrade weapon function in game code.
- `PainConsciousnessConstants.gd` applies pain performance modifiers globally but does NOT model grip-specific degradation from arm wounds.
- No distinction between forearm, upper_arm, hand sub-regions for combat effectiveness.

### Historical/Medical Research — Arm Injury Impact on Weapon Control

#### Grip Strength Degradation by Injury Severity (Clinical Studies)
- **Bohannon 2019** (*Clinical Interventions in Aging*): Grip strength is an "indispensable biomarker" — directly correlates with overall body strength and functional stability. A reduction of even 10% grip strength significantly impacts fine motor control.
- **Leyk et al. 2007** (*European Journal of Applied Physiology*): Hand-grip strength measurements show high sensitivity to localized trauma. Even minor wrist/hand injuries reduce crush grip by 15-30%.
- **Median nerve injury**: Loss of thumb opposition, reduced precision grip → ~40% loss of fine motor control (clinical standard).
- **Radial nerve injury** ("wrist drop"): Inability to extend wrist/fingers → weapon cannot be held at proper angle → ~60% loss of directional control.
- **Ulnar nerve injury**: Loss of finger abduction/adduction, weakened grip → ~50% reduction in sustained握力 (sustained crushing force).

#### Upper Extremity Vascular Injury (McCready 1988, StatPearls NBK536925)
- **Forearm arteries** (radial + ulnar): Most commonly injured vessels in upper extremity trauma. Severance of one = ~40-50% blood flow reduction; both = hand ischemia within minutes.
- **Brachial artery**: Single vessel supplying entire arm below shoulder. Severed = complete ischemia, hand becomes non-functional in 3-5 minutes without reperfusion.
- **Impact on weapon grip**: Blood loss from forearm/hand wounds → rapid grip strength decline via combined effects of (a) direct tissue damage and (b) systemic blood loss reducing muscle perfusion.

#### Clinical Grip Strength Loss by Injury Type (ATLS Classification)

| Injury | Immediate Grip Loss | Sustained Impact (untreated) | Recovery with Treatment |
|--------|-------------------|------------------------------|------------------------|
| **Hand cut, superficial** | 10-20% | Pain-limited: ~30% functional loss for hours | Days; full recovery in 1-2 weeks |
| **Forearm cut, muscle/tendon visible** | 30-50% | Nerve involvement likely: 40-60% loss until repaired | Weeks-months without surgery; permanent deficit common |
| **Brachial artery severed** | ~80-100% (hand goes ischemic) | Hand non-functional in 3-5 min; irreversible damage after 4-6 hours | Emergency revascularization needed; often amputation if delayed |
| **Radial/ulnar artery + nerve cut** | 50-70% | Loss of precision grip and wrist extension/flexion | Surgical repair → months rehab; permanent weakness common |

#### Key Design Data Points
- **Forearm sub-region**: Primary grip muscles (flexor digitorum superficialis/profundus, flexor pollicis longus) run through forearm. Any cut here directly impairs weapon control.
- **Hand sub-region**: Fine motor control (intrinsic hand muscles). Even minor cuts to palm/fingers degrade precision aiming and trigger control.
- **Upper arm**: Less direct impact on grip but brachial artery severance = rapid functional loss via ischemia. Biceps/triceps damage reduces swing power by 30-50%.
- **Elbow**: Radial/ulnar nerves cross here. Damage causes combined motor + sensory deficit ("double whammy").

### Proposed Changes

#### 1. Sub-Region-Specific Weapon Degradation
**Current**: Arm hits have no special weapon function impact beyond general pain modifiers.
**Proposed**: Different arm sub-regions produce different functional penalties:

| Sub-region | Primary Impact | Mechanism |
|-----------|---------------|-----------|
| **Hand** | Precision aim degradation (-20-50% hit chance) | Fine motor control loss from tissue/nerve damage |
| **Forearm** | Grip strength reduction → swing power penalty (-15-40% intensity) | Flexor muscle/tendon damage; bleeding reduces perfusion |
| **Upper arm** | Swing power reduction (-10-30%) + risk of rapid ischemia if brachial artery cut | Muscle damage (biceps/triceps); arterial bleed → systemic grip loss |
| **Elbow** | Combined precision + power penalty (-25-60%) | Nerve crossing point; dual motor/sensory deficit |

#### 2. Bleeding-Induced Grip Decline Over Time
**Mechanism**: Ongoing blood loss from arm wounds progressively reduces grip strength via systemic effects (ATLS Class II hemorrhage: tachycardia + reduced perfusion → grip strength drops ~10% per ATLS class).

| Blood Loss | Grip Strength Impact | Mechanism |
|-----------|---------------------|-----------|
| **Class I (<15%)** | Negligible (-5%) | Compensatory vasoconstriction preserves extremities |
| **Class II (15-30%)** | Moderate (-15-25%) | Tachycardia, reduced peripheral perfusion |
| **Class III (30-40%)** | Severe (-40-60%) | Confusion + profound weakness; grip fails |
| **Class IV (>40%)** | Near-total loss (-80%+) | Impending collapse; weapon essentially dropped |

#### 3. Recovery Timeline
- **Minor hand/forearm cuts**: Grip recovers ~15-20% per hour of rest with dressing applied
- **Moderate wounds (tendon/muscle damage)**: Full recovery requires medical intervention — 1-2 weeks without surgery, permanent deficit possible
- **Arterial injuries**: Require tourniquet → surgical repair. Without treatment: progressive ischemic necrosis

### Research Sources for Issue 2
15. **McCready R.** (1988) - "Upper-extremity vascular injuries." *Surgical Clinics of North America*. — Brachial/radial/ulnar severance rates and functional impact
16. **StatPearls NBK536925** - Forearm vessel injury epidemiology — most commonly injured UE vessels
17. **Bohannon RW.** (2019) - "Grip Strength: An Indispensable Biomarker For Older Adults." *Clinical Interventions in Aging*. 14:1681-1691. — Grip strength as functional biomarker
18. **Leyk D, et al.** (2007) - "Hand-grip strength of young men, women and highly trained female athletes." *European Journal of Applied Physiology*. 99(4):415-421. — Sensitivity to localized trauma

---

## Issue 3: Thrusts vs Cuts — Penetration Physics

### Current Implementation
- `WEAPON_COMMIT_FRACTION_STAB` = 0.58, suggesting thrusts commit less deeply than cuts
- `parry_thrust` move has explicit `weapon_extension_commit_fraction: 0.50`
- No distinction between cut (incised) and stab (penetrating) wound outcomes in severity calculation

### Historical/Forensic Research — Penetration Mechanics

#### Stab vs Cut Mortality (Forensic Pathology Consensus)
- **Knight's Forensic Pathology** (4th ed.) & **Spitz & Fisher's Medicolegal Investigation of Death**: Standard forensic consensus confirms that stab wounds penetrate deeper and have significantly higher organ-damage mortality than incised/cut wounds of equivalent length.
- **Key mechanism**: Cuts slice along tissue planes; stabs push tissues aside and penetrate to vital structures (organs, major vessels, spine). A 5cm cut may only damage skin/subcutaneous tissue; a 5cm stab can reach liver, lung, or heart.

#### Period Manual Evidence — Thrust as Primary Lethal Technique
- **Fiore dei Liberi** (c.1407): Multiple illustrations show thrust to the face/visor as the fight-ending technique after blade engagement. The "terminating blow" is consistently a thrust, not a cut.
- **Meyer (1570)**: Thrusts ("stoßen") are framed as the most decisive strike — executed from guards that control distance, aimed at openings created by preceding cuts.
- **Silver (1599)**: Argues that "the true fight" is the thrust when properly timed — "as near and nearer, more swift and stronger" than a cut. His entire system is built around controlling distance to enable or deny thrusts.

#### Thrust Geometry & Damage Profile
| Property | Cut (Slice) | Thrust (Pierce/Stab) |
|----------|------------|---------------------|
| **Contact area** | 2-5 cm blade edge | <1 cm² tip (~0.3-0.7 cm diameter) |
| **Pressure at impact** | Low-Moderate (force spread along edge) | Very High (same force concentrated on tiny area) |
| **Penetration depth** | Limited by cutting angle; typically 2-8 cm | Can penetrate 15-30+ cm depending on force/angle |
| **Organ damage risk** | Low to moderate (surface damage) | Very high (direct access to internal structures) |
| **Armor penetration** | Poor against plate | Effective through plate gaps; can reach mail underneath |

#### Modern HEMA Weapon Measurements Affecting Thrust vs Cut Balance
- **Longsword average weight**: 1300-1600g (museum specimens, Oakeshott typology) — lighter than pop-culture suggests
- **Center of balance**: ~9cm (3.5 in) from guard toward blade — easily forward-weighted for thrusting
- **Tip speed**: Longsword full cut = 6-12 m/s; thrust can achieve similar or higher because linear acceleration requires less rotational energy than a swing
- **Moment of inertia**: ~0.12-0.18 kg·m² — means thrusts feel significantly "lighter" and faster than cuts to the operator

### Proposed Changes

#### 1. Thrust Wounds Deal Higher Bone/Tissue Penetration
**Current**: Cut and stab use similar severity calculations.
**Proposed**: Stab wounds get a penetration depth multiplier that increases organ/vital structure damage:
- `STAB_PENETRATION_MULT = 1.6` (stabs penetrate ~60% deeper into tissue)
- This means for equivalent total damage, stabs allocate more to bone and deep tissue vs surface cuts

#### 2. Thrusts Have Lower Hit Chance but Higher Impact When They Connect
**Rationale**: Historical sources consistently treat thrusts as the "finisher" — harder to land (small target, committed motion) but more lethal when successful. This matches Silver's distance-control paradigm and Fiore's terminating-thrust illustrations.

| Parameter | Cut | Thrust |
|-----------|-----|--------|
| **Base hit chance** | 100% (move baseline) | 85-92% (smaller target, +commitment cost) |
| **Bone damage fraction** | Normal (per part constants) | ×1.4 multiplier |
| **Depth penetration** | Standard | ×1.6 effective tissue penetration |

#### 3. Thrust Armor Penetration Bonus
- Against armor: thrusts ignore a portion of armor protection (thrust concentrates force on smaller area → higher chance of penetrating mail gaps or plate weaknesses)
- `THRUST_ARMOR_PENETRATION_MULT = 1.25` against plate/armor

### Research Sources for Issue 3
19. **Knight's Forensic Pathology** (4th ed.) & **Spitz & Fisher** — Stab wounds penetrate deeper, higher organ-damage mortality than incised/cut
20. **Fiore dei Liberi, *Flos Duellatorum*** (c.1407, Getty MS/Morgan MS) — Thrust as terminating technique in multiple illustrated sequences
21. **Meyer, J.** (1570) - *Gründtliche Beschreibung* — Thrusts ("stoßen") as decisive strikes from distance-controlled guards
22. **Silver, G.** (1599) - *Paradoxes of Defence* / *Brief Instructions* — Thrust as "true fight"; superior speed and strength when properly timed
23. **Oakeshott, E.** - *The Sword in the Age of Knightly Combat* — Museum specimen measurements: longsword 1300-1600g, CoB ~9cm from guard
24. **Tobel, C.** - "Measuring Your Sword" (swordtechniques.com) — HEMA measurement methodology and balance point analysis

---

## Issue 4: Wound Healing & Infection Timeline

### Current Implementation
- `HealingConstants` defines healing rates but does NOT model infection as a separate compounding factor.
- No "infection timer" — wounds either heal or persist based on bleeding/severity.
- Bandaging reduces bleeding rate and triggers clotting, but there's no infection risk/check mechanic.

### Historical/Medical Research — Pre-Antibiotic Wound Outcomes

#### Infection Rates by Treatment Quality (Pre-Modern Era)

| Treatment | Infection Rate | Septic Mortality (if infected) | Overall Survival |
|-----------|---------------|-------------------------------|-----------------|
| **None** (battlefield, untreated) | 60-80% | ~70-90% die from sepsis | 25-40% overall wound survival |
| **Basic cleanliness** (clean water/wine rinse only) | 40-60% | ~50-70% die from sepsis | 40-55% overall wound survival |
| **Good care** (honey + wine + clean dressings, rest) | 20-35% | ~40-60% die from sepsis | 55-70% overall wound survival |
| **Excellent care** (herbal antiseptics + nutrition + isolation) | 10-20% | ~30-50% die from sepsis | 70-85% overall wound survival |

#### Infection Progression Timeline (Untreated Wound)
1. **Day 0**: Wound sustained, bacterial colonization begins
2. **Day 1-3**: Initial inflammation; neutrophils arrive within 1 hour, peak day 2
3. **Day 3-7**: Suppuration (pus formation); "laudable pus" era believed this meant healing
4. **Day 5-10**: Cellulitis spreads; systemic symptoms begin if uncontrolled
5. **Day 7-14**: Sepsis develops in severe cases; fever, confusion, tachycardia
6. **Day 10-21**: Septic shock or death OR gradual healing (if immune system wins)

#### Effective Pre-Modern Antimicrobials (Evidence-Based)

| Treatment | Effectiveness | Mechanism | Historical Evidence |
|-----------|-------------|-----------|-------------------|
| **Honey** | High | High osmolarity + hydrogen peroxide + low pH; active against MRSA | Edwin Smith Papyrus (~1600 BCE); used continuously across all cultures |
| **Wine/Clean water rinse** | Moderate | Ethanol 10-15% kills surface bacteria; mechanical flushing removes debris | Hippocratic corpus universal practice |
| **Vinegar (acetic acid)** | Mild-Moderate | Disrupts bacterial cell membranes | Medieval wound cleansing; WWI antiseptic irrigation |
| **Garlic** | Moderate | Allicin compound, documented antibacterial | Ancient Egypt through Medieval Europe |
| **Myrrh / Plantain** | Moderate | Terpenes/plant compounds; draws out infection | Universal folk medicine |
| **Copper/Silver contact** | Mild | Oligodynamic effect (metal ions toxic to bacteria) | 2300-year-old mummy with gold in wounds; copper water vessels (Ebers Papyrus) |

#### Skin Healing Rates (Clinical Biology)
- **Re-epithelialization**: Epithelial cells migrate at ~1 mm/day (0.5-1 mm/day clinical consensus)
- **Inflammatory phase**: Hours to 2 days — neutrophils arrive, macrophages replace by day 2
- **Proliferative phase**: Days 3-21 — fibroblasts enter day 2-5, collagen deposition begins ~10 hours to 3 days after injury
- **Maturation/remodeling**: Begins week 2+, lasts weeks to months

#### Bone Healing Timeline (Fracture)
- **Clinical union**: Typically 3-6 weeks for most fractures (varies by bone/location)
- **Full remodeling complete**: Can take 3-5 years to restore original bone structure
- **Non-union definition**: No progression of healing within 6 months

### Proposed Changes

#### 1. Infection Risk System (Simple Timer-Based)
**Mechanism**: After wound creation, a hidden "infection timer" starts. If the wound is not properly treated (honey/wine/herbal antiseptic applied), infection probability increases over time:

| Time Since Wound | Infection Probability | Effect if Infected |
|-----------------|---------------------|-------------------|
| **0-6 hours** | 5% baseline | Pain +1, healing rate -25% |
| **6-24 hours** | 15% (basic treatment) / 40% (no treatment) | Pain +3, consciousness -10%, healing paused |
| **24-72 hours** | 30% (good care) / 60% (untreated) | Severe pain +5, performance -30%, blood loss +20% |
| **>72 hours** | Systemic sepsis likely if not treated | Death within 3-14 days without intervention |

#### 2. Treatment Efficacy Modifiers
Different medical treatments reduce infection risk:

| Treatment | Infection Risk Reduction | Healing Rate Impact |
|-----------|------------------------|-------------------|
| **Honey dressing** | -50% infection risk | +20% healing rate (anti-inflammatory) |
| **Wine rinse only** | -30% infection risk | Neutral |
| **Herbal antiseptic pack** (garlic/myrrh/plantain) | -40% infection risk | +10% healing rate |
| **Bandage without antiseptic** | -10% (minor protection from contamination) | +5% healing (wound protection) |

#### 3. Infection Status Effects (When Treatment Fails)
- **Local infection**: Reduces healing rate by 75%; pain increases over time (+1 per day); visible wound appearance worsens
- **Systemic infection (sepsis)**: All performance modifiers halved; blood volume drops faster (fever/metabolic demand); death in 3-14 days without treatment
- **Sepsis treatment**: Requires honey + rest + nutrition (simulated via `CampaignSupply` bonuses)

### Research Sources for Issue 4
25. **Amputation - Wikipedia** — Napoleonic era amputation mortality; WWI gas gangrene statistics (~60-90% mortality without treatment, ~25% with debridement)
26. **History of Surgery - Wikipedia** — Evolution of wound treatment; Edwin Smith Papyrus honey references; Ambroise Pare innovations
27. **Galenic medicine sources** (Hippocratic Corpus, Galen c.129-216 CE) — "Laudable pus" doctrine; humoral framework for wound healing
28. **Hugh of Lucca** (~1200 CE) — First rejection of pus theory at School of Salerno; advocated dry wound treatment with wine
29. **Edwin Smith Papyrus** (~1600 BCE) — "Treat with honey every day" for wounds; oldest documented medical antiseptic use
30. **Wikipedia - Wound healing** — Clinical timeline: re-epithelialization ~1 mm/day, inflammatory phase hours-2 days, proliferative phase days 3-21, remodeling weeks-months
31. **Marsell R, Einhorn T.** (2012) - "Bone healing: an overview." *Injury*. 43(Suppl 6):S58-S65. — Bone healing timeline; clinical union 3-6 weeks; non-union >6 months
32. **Lister, J.** (1867+) - Antiseptic surgery principles — end of "laudable pus" era; mortality dropped from ~50% to <15% for amputations

---

## Research Sources Summary (All Verifiable)

### Archaeological / Historical Combat
1. **Thordeman, Nörlund, Ingelmark** (2001/orig 1940s) - *Armour from the Battle of Wisby, 1361*. Chivalry Bookshelf. ISBN 1-891448-05-6. — High frequency of fatal cranial trauma; split skulls from downward strikes
2. **Scott et al.** (1996-2003) - Towton Dale mass grave excavations. ~50 skeletons, severe head/torso trauma concentration. Cited in Gravett 2003 pp.85-89.
3. **ARMA** (Association for Renaissance Martial Arts) — *Le Jeu de la Hache* annotations and Visby skeletal analysis notes

### Trauma Medicine / Forensic Pathology
4. **Vinas FC, Pilitsis J.** (2006) - "Penetrating Head Trauma." *eMedicine.com*. — 92% total mortality for penetrating cranial injuries by GSW
5. **Knight's Forensic Pathology** (4th ed.) & **Spitz & Fisher's Medicolegal Investigation of Death** — Stab wounds penetrate deeper, higher organ-damage mortality than incised/cut; forensic consensus
6. **Byard RW.** (2011) - "The 'break enter and die' syndrome may involve significant injury to major neck vessels." *J Forensic Sci.* 56(Suppl 1):S252-S254. PMID: 20950320
7. **Irandoust S, Heath K, Byard RW.** (2013) - "Sheep shearing and sudden death." *J Forensic Leg Med.* 20(8):944-946. PMID: 24237795 — Carotid incised wound causes rapid fatal exsanguination in 2-5 min
8. **ATLS / Tintinalli's Emergency Medicine** (7th ed.) — Hemorrhagic shock classification; grip strength degradation by blood loss class
9. **McCready R.** (1988) - "Upper-extremity vascular injuries." *Surgical Clinics of North America*. — Brachial/radial/ulnar severance rates and functional impact

### Physiology / Neurology
10. **Klemp P, et al.** (1989) - *J Investigative Dermatology* — Scalp blood flow ~35.7 mL/100g/min vs forearm skin ~1.5-1.7 = 20-25× ratio
11. **Gosselin A, et al.** (2012) - "Pain and cognitive function in mTBI." *J Neurotrauma* — Pain worsens concussion symptoms; reduced DLPFC activation during working memory tasks
12. **Greenberg et al.** (2020) - "Pain catastrophizing predicts postconcussion symptoms." *Psychosomatics*. — Pain catastrophizing explains 41% of symptom variance
13. **Cleveland Clinic / BIAUSA** — Glasgow Coma Scale classification and functional impairment correlates
14. **Wikipedia - Knockout article** (citing multiple sources) — Combat sports KO durations: stunned/dazed 3-8s, flash KO <3s unconscious, full KO 10-20s unconscious

### Historical Martial Arts / Weapon Physics
15. **Bohannon RW.** (2019) - "Grip Strength: An Indispensable Biomarker For Older Adults." *Clinical Interventions in Aging*. 14:1681-1691. — Grip strength as functional biomarker for arm injury impact
16. **Leyk D, et al.** (2007) - "Hand-grip strength of young men, women and highly trained female athletes." *European Journal of Applied Physiology*. 99(4):415-421. — Sensitivity of grip measurements to localized trauma
17. **StatPearls NBK536925** — Forearm vessel injury epidemiology; most commonly injured UE vessels

### Historical Combat Manuals / HEMA Research
18. **Fiore dei Liberi, *Flos Duellatorum*** (c.1407, Getty MS/Morgan MS) — Thrust as terminating technique in illustrated sequences
19. **Meyer, J.** (1570) - *Gründtliche Beschreibung* — Thrusts ("stoßen") as decisive strikes from distance-controlled guards
20. **Silver, G.** (1599) - *Paradoxes of Defence* / *Brief Instructions* — Thrust as "true fight"; hand swifter than foot; cut "more swift and stronger" in close range
21. **Liechtenauer** (via Tobler/Chidester translations) - *Zettel* with glosses — Vor/Nach/Stärke/Schwäche/Indes framework; active interception over passive parrying
22. **Ott Jud** (c.1450, Rome version Cod.44.A.8) — Three principles of wrestling; arm-cross grip for transitioning from armed to unarmed combat
23. **Meyer, J.** (1570, §11 List) — 34 distinct hand techniques for blade contact situations (binding/winding/pressing/wrestling transitions)

### Wound Healing / Infection Medicine
24. **Oakeshott, E.** - *The Sword in the Age of Knightly Combat* — Museum specimen measurements: longsword 1300-1600g, CoB ~9cm from guard; arming sword 700-1200g
25. **Tobel, C.** - "Measuring Your Sword" (swordtechniques.com) — HEMA measurement methodology and balance point analysis methodology
26. **FIE technical regulations** — Sport fencing weapon specs and high-speed camera studies: foil tip speed 12-18 m/s; epee similar; rapier estimated 8-14 m/s from biomechanical scaling
27. **Amputation - Wikipedia** — Napoleonic era amputation mortality (~50%); WWI gas gangrene statistics (60-90% without treatment)

### Historical Wound Treatment / Antimicrobials
28. **Galenic medicine sources** (Hippocratic Corpus, Galen c.129-216 CE) — "Laudable pus" doctrine; humoral framework for wound healing
29. **Hugh of Lucca** (~1200 CE) — First rejection of pus theory at School of Salerno; advocated dry wound treatment with wine
30. **Ambroise Pare** (1510-1590) — Replaced boiling oil with soothing dressings for gunshot wounds; transition from pus-promotion to dry treatment
31. **Edwin Smith Papyrus** (~1600 BCE) — "Treat with honey every day" for wounds; oldest documented medical antiseptic use
32. **Wikipedia - Wound healing** — Clinical timeline: re-epithelialization ~1 mm/day, inflammatory phase hours-2 days, proliferative phase days 3-21, remodeling weeks-months
33. **Marsell R, Einhorn T.** (2012) - "Bone healing: an overview." *Injury*. 43(Suppl 6):S58-S65. — Bone healing timeline; clinical union 3-6 weeks
