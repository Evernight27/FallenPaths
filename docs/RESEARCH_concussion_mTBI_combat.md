# Concussion / mTBI Research for Combat Game Implementation

**Date:** 2026-07-25
**Purpose:** Replace unrealistic concussion system (40% perception reduction for 3-15s, then full recovery) with medically accurate timeline and effects.

---

## 1. Realistic Concussion Timeline and Effects

### 1a. Immediate Aftermath (0-60 seconds)

**What actually happens:**
- Instant confusion and disorientation — the person may not know where they are or what happened
- Impaired balance/vestibular disruption — gait unsteadiness, vertigo sensation
- Visual processing disruption — blurred vision, difficulty tracking moving objects, photophobia onset
- Slowed reaction time — **reaction times increase by 50-150ms** (studies show post-concussion simple reaction time impairment of ~50ms in the acute phase, rising to 100-150ms for complex/choice reactions)
- Possible brief loss of consciousness (<30 seconds in ~10% of concussions; *Wikipedia:Concussion*)
- Post-traumatic amnesia — inability to form new memories (events after the injury)
- Repeating the same questions, vacant stare, slurred or incoherent speech (*CDC/WHO clinical criteria*)

**Perception/cognitive state:** At approximately **60-80% of baseline function immediately post-injury**, meaning a **20-40% effective reduction**. But this is NOT just "perception" — it's a multi-domain impairment including balance, vision, and cognition.

### 1b. Acute Phase (1 minute to ~30 minutes)

**Symptoms present:**
- Continued confusion and disorientation
- Slowed processing speed — **reaction time remains elevated by 50-120ms above baseline** for complex tasks (decision-making, threat recognition, tactical choices)
- Visual tracking impairment — difficulty following a moving target with eyes; this directly affects combat ability to track an opponent's weapon
- Balance issues — unsteady gait, reduced ability to maintain footing during movement or engagement
- Difficulty concentrating and focusing attention (*Wikipedia:Concussion*, *CDC*)
- Headache (the most common symptom, present in majority of cases)
- Nausea/dizziness in 30-50% of cases
- Light/noise sensitivity (*Wikipedia:Concussion*)

**Severity:** Cognitive function at approximately **40-70% of baseline** during this period. For a combat context, this translates to:
- Perception/reaction delay: **+60ms to +120ms** over baseline reaction time
- Decision quality: significantly degraded — poor threat assessment, delayed tactical choices
- Spatial judgment: impaired — misjudging distance to opponent, mistiming strikes by 200-500ms equivalent
- Visual tracking: reduced ability to smoothly track moving opponents/weapons

### 1c. Subacute Phase (30 minutes to several hours)

**Symptoms present:**
- Gradual improvement but symptoms persist
- Residual foggy thinking, difficulty concentrating
- Fatigue and dizziness may linger
- Headache often persists (*Hall et al., Archives of Internal Medicine 2005*)

**Cognitive function:** Approximately **70-90% of baseline**, gradually improving toward normal. Reaction time impairment decreases from +60ms toward +15-30ms above baseline over this period.

### 1d. Typical Recovery Timeline for Mild Concussion

From *Wikipedia:Concussion* and clinical literature:
- **~50% of people:** Symptoms resolve within a few days to several weeks (*Merck Manual*)
- **~75% of adults:** Nearly symptom-free within **3 weeks** (most recover in 7-14 days)
- **Children/adolescents:** Longer — up to 4 weeks (*Mah 2018, CDC*)
- **"Fewer than 10%** of sports-related concussions among children are associated with loss of consciousness" (*Peds 2010 citation in Wikipedia*)

---

## 2. Delayed/Post-Concussive Effects

### 2a. Post-Concussion Syndrome (PCS)

**Definition:** Concussion symptoms persisting beyond the expected recovery period:
- **Adults:** Symptoms lasting >14 days (*Wikipedia:Concussion*, *Marshall 2023*)
- **Children/adolescents:** Symptoms lasting >4 weeks (*Wikipedia:Concussion*)
- **Diagnosis threshold:** ICD-10 requires symptoms persisting for more than **3 months** (*ICD-10 criteria in Wikipedia:PCS*)

**Prevalence:**
- About **35%** of concussion patients experience prolonged symptoms 3-6 months after injury (*CENTER-TBI, Wikipedia:PCS*)
- Estimated PCS incidence: ~**10% of mTBI cases** (*Dorsten citation, Wikipedia:PCS*)
- Between **24-84%** at 3 months post-injury (wide range due to different study populations) (*Ryan 2007, Wikipedia:PCS*)

**Typical PCS symptoms:**
- Headaches: 30-90% of patients; 8-32% still report them a year after injury (*Hall et al. 2005*)
- Dizziness: ~50% at diagnosis; up to 25% still present one year later (*Hall et al. 2005*)
- Cognitive problems (concentration, memory): ~25% report memory issues a year after injury (*Olver 2005*)
- Visual symptoms: 14% blurred vision, 10% light/noise sensitivity, 5% taste/smell changes (*Hall et al. 2005*)
- Sleep disturbances, fatigue, mood changes (irritability, anxiety, depression present in ~50%)

### 2b. Recovery Curve

From Wikipedia:Concussion and clinical studies:
- **First 3 days:** Most dramatic improvement; acute confusion resolves
- **Days 3-7:** Significant cognitive recovery for most adults; reaction times approaching baseline
- **Weeks 1-2:** ~75% of adults nearly symptom-free
- **Weeks 2-4:** Remaining cases continue improving
- **Month 1:** About 67% of minor head trauma patients are "nearly symptom-free" (*Wikipedia:Concussion*)
- **Months 3-6:** Most PCS cases resolve; majority within 6 months (*Hall et al. 2005*)
- **If not resolved by 1 year:** Symptoms likely permanent (though improvements can still occur) (*Legome citation, Wikipedia:PCS*)

**Key insight for game implementation:** Recovery is **gradual**, not sudden. There is no "switch" from concussed to normal — it's a curve of progressive improvement. The brain enters an energy crisis state that can persist for up to 4 weeks (*Wikipedia:Concussion* pathophysiology section).

---

## 3. Second Impact Syndrome (SIS)

### 3a. What It Is

Second-impact syndrome occurs when a person sustains a **second concussion before symptoms from an earlier one have resolved**. The second blow causes **catastrophic brain swelling** (diffuse cerebral edema), leading to rapid neurological collapse.

**Key facts from Wikipedia:Second-impact-syndrome:**
- Can occur minutes, days, or weeks after initial concussion
- Even the **mildest grade of concussion** can lead to SIS with a second impact
- The second impact may be very minor — even a blow to the chest that jerks the head is sufficient (*Bowen 2003*)
- Loss of consciousness during the second injury is **not necessary** for SIS to occur

### 3b. Severity and Mechanism

**Pathophysiology:**
- Brain's arterioles lose ability to regulate their diameter, losing control over cerebral blood flow (*Cantu 1998*)
- Vessels dilate massively, causing greatly increased cerebral blood flow
- Progressive cerebral edema causes rapid/severe increase in intracranial pressure
- Results in brain herniation (uncal and cerebellar) — potentially fatal

**Timeline:**
- Pathophysiological changes can begin within **15 seconds** of the second concussion (*Eldorado County EMS brochure*)
- Brain stem failure occurs between **2-5 minutes** after second impact
- Death follows shortly thereafter (*Cantu 1998, LeBlanc et al. 2000*)

### 3c. Vulnerability Window

From Wikipedia:Second-impact-syndrome and clinical literature:
- The brain is vulnerable for the **entire duration of concussion symptoms**
- Most second impacts occur within the **first two weeks** after initial injury (*Wikipedia:ESIDEP*)
- The adolescent brain is **60 times more sensitive** to the metabolic chain reaction after trauma than adult brain
- No minimum severity threshold — even a trivial blow can trigger SIS if the brain hasn't healed

### 3d. Prognosis

From Wikipedia:Second-impact-syndrome:
- **Mortality rate:** Approaches **50%**
- **Disability (morbidity):** Almost **100%** in survivors
- When not fatal, effects resemble severe TBI: persistent muscle spasms, emotional instability, hallucinations, post-traumatic epilepsy, mental disability, paralysis, coma, brain death

### 3e. Historical Accounts

From Wikipedia:Second-impact-syndrome history section:
- **1984:** R.L. Saunders described a football player who died after a second, unremarkable concussion (*Saunders RL citation*)
- **1980-1993:** 35 American football cases recorded; 17 confirmed by autopsy/surgery/MRI as SIS, 18 "probably SIS-related" (*Cantu 1998*)
- **2005:** Preston Plevretes (LaSalle University) — diagnosed with concussion at practice, told he was allowed to resume play 2 days later, sustained another concussion 3 games later, developed SIS, still struggling with daily activities 5 years post-injury (*Plevretes citation*)
- **2006:** Zachary Lystedt (age 13) — shrugged off hit, went back in game a few plays later, collapsed at end of game from SIS, required bilateral craniectomy, spent months in hospital, still has trouble with physical tasks (*Lystedt citation*)
- **Rowan Stringer** (Canadian high school athlete): Three blows to the head over one week; showed only mild headache after first two impacts; lost consciousness and never regained it after third; SIS confirmed by medical examiner

### 3f. Controversy Note

Some professionals question whether SIS is over-diagnosed (*McCrory & Berkovic, Neurology 1998*; *MacReady 2004*). Critics argue that only 5 of 17 previously identified cases met strict diagnostic criteria (*McCrory98*), and some cases may be diffuse cerebral swelling rather than true SIS. However, the prevailing medical consensus maintains SIS as a real (if rare) catastrophic risk, particularly in young athletes.

---

## 4. Combat-Specific Impairment Data

### 4a. Reaction Time Degradation

**Research basis:** While direct combat concussion reaction time studies are limited, sports concussion research provides strong proxies:

- **Simple reaction time impairment:** Post-concussion studies show **~50ms increase** in simple reaction times (visual stimulus -> response)
- **Complex/choice reaction time impairment:** **80-150ms increase** for tasks requiring decision-making (e.g., selecting appropriate defensive response to a specific threat)
- In fighting contexts specifically: A punch fighter has roughly **200-400ms** total engagement window. An 80ms delay represents a **20-40% degradation** in available reaction time — potentially the difference between successfully parrying and being hit

**Combat-relevant breakdown:**
| Task | Baseline Reaction | Post-Concussion (Acute) | Delay Added | Combat Impact |
|------|-------------------|------------------------|-------------|---------------|
| Parry recognition (simple) | ~150ms | 200-250ms | +50-100ms | Noticeable lag in block timing |
| Threat assessment (complex) | ~300ms | 400-500ms | +100-200ms | Misses attack cues entirely |
| Strike selection (decision) | ~400ms | 550-700ms | +150-300ms | Wrong defensive response |
| Dodge initiation | ~200ms | 300-450ms | +100-250ms | Movement too late |

### 4b. Spatial Judgment Impairment

Concussion affects the vestibular system and visual processing:
- **Depth perception:** Studies show post-concussion impairment in judging distances (relevant to melee range)
- **Timing of movements:** Vestibular disruption causes mis-timed actions — strikes land early/late by 200-500ms equivalent
- **Balance/movement coordination:** Gait disturbance, reduced ability to maintain stable fighting stance

### 4c. Decision-Making Degradation

Concussion specifically impairs:
- **Executive function:** Prefrontal cortex disruption affects tactical decision-making
- **Working memory:** Inability to hold multiple considerations in mind (e.g., "opponent is left-handed, my right arm is injured, flank opening")
- **Risk assessment:** Impaired ability to evaluate when to engage/disengage
- **Attention shifting:** Difficulty rapidly switching focus between threats

In combat terms: A concussed fighter makes **significantly more poor tactical choices** — engages when should disengage, fails to recognize openings, cannot adapt strategy.

### 4d. Visual Tracking Impairment

Post-concussion visual symptoms directly impact combat:
- **Smooth pursuit impairment:** Difficulty following moving targets smoothly (*Wikipedia:Concussion* — blurred vision, light sensitivity)
- **Saccadic dysfunction:** Poor ability to rapidly shift gaze between multiple targets
- **Convergence insufficiency:** Trouble focusing on near objects (relevant at close melee range)
- **Visual processing delay:** Information from eyes takes longer to reach and be processed by cortex

**Combat impact:** A concussed fighter cannot smoothly track an opponent's weapon, leading to:
- Late recognition of incoming strikes
- Inability to read feints (rapid directional changes in attack)
- Difficulty maintaining visual contact during fast exchanges

---

## 5. Historical/Military Accounts

### 5a. Medieval Through Early Modern Period

**Knockout/CONCUSSION IN COMBAT SPORTS:**
From Wikipedia:Concussion and knockout literature:
- **Combat sports knockouts:** Stunned/dazed state lasts **3-8 seconds** after a significant blow; flash KO <3s unconscious; full KO 10-20s unconscious (*Wikipedia - Knockout article*)
- Fighters who "fight on" after taking a hard hit are typically in a profoundly impaired state — they may continue moving but lack reaction speed, coordination, and judgment

**Historical military medicine:**
- Medieval surgeons recognized that head blows could cause temporary or permanent impairment even without fatal wounds
- Renaissance-era surgeons (Ambroise Pare) documented "commotion of the brain" causing confusion, memory loss, and behavioral changes
- Battle accounts from medieval through Napoleonic wars frequently describe soldiers who took head blows continuing to fight but in a confused, disoriented state — making poor tactical decisions, wandering from formation, responding slowly to commands

### 5b. WWI/Trench Warfare (Shell Shock Era)

WWI provided the first large-scale observation of blast/concussive brain injury:
- **"Commotion du cerveau"** (brain commotion) was a recognized French military diagnosis for shell-induced concussion
- Soldiers exposed to artillery blasts without direct shrapnel wounds presented with: headache, dizziness, confusion, memory loss, irritability, sleep disturbance, and "nervous exhaustion"
- Many were initially dismissed as cowardly or hysterical; modern understanding recognizes this as blast-related TBI/concussion
- Recovery timelines varied: some recovered in days, others had symptoms for months/years (early recognition of PCS)

### 5c. Boxing/Martial Arts Historical Accounts

**Boxing history is rich with concussion accounts:**
- Fighters routinely "fought on" after being rocked by body blows or clips to the head — but were visibly impaired: slower reactions, poor footwork, confused defense
- Ring doctors and trainers recognized the "dazed" state as a genuine impairment requiring removal from competition (even before formal concussion protocols existed)
- Historical accounts describe boxers who took a hard shot continuing on "on instinct" but with dramatically reduced defensive capability — they could still throw punches but couldn't effectively parry or dodge

**Key historical pattern:** Fighters who continue after significant head trauma are **not functioning normally**. They may appear to be "fighting," but their performance is severely degraded. This matches the medical evidence: concussion impairs function across multiple domains simultaneously, not just one stat.

---

## 6. Specific Data for Game Implementation

### 6a. Current System Analysis

**Current implementation** (`EntityPainConsciousness.gd`, lines 14-20):
```gdscript
const CONCUSSION_DURATION_MIN_S: float = 3.0    # too short
const CONCUSSION_DURATION_MAX_S: float = 15.0    # max still too short for recovery
const CONCUSSION_PERCEPTION_PENALTY_MULT: float = 0.4  # perception reduced to 40% — then full recovery
```

**Problems:**
1. **Duration too short:** 3-15 seconds doesn't reflect the hours/days of impairment that real concussions cause
2. **Single effect dimension:** Only affects perception; ignores balance, decision quality, visual tracking
3. **Abrupt recovery:** No gradual improvement curve — instant switch from impaired to normal
4. **No pain interaction:** Research shows pain WORSENS concussion symptoms (Gosselin et al., J Neurotrauma 2012)
5. **No second-impact syndrome mechanism:** Current re-impact logic just extends duration by a small amount

### 6b. Recommended New System Architecture

**Phase-based concussion model with gradual recovery:**

| Phase | Time Window | Severity (Perception) | Additional Effects |
|-------|-------------|----------------------|-------------------|
| **CRITICAL (immediate)** | 0-90 seconds post-injury | 25-40% of normal (60-75% reduction) | Severe balance impairment (-50% movement control), visual tracking failure, reaction delay +100-150ms, decision quality at 30% |
| **ACUTE** | 90 seconds - 8 minutes | 40-60% of normal (40-60% reduction) | Balance impairment (-30%), visual tracking reduced (-40%), reaction delay +60-100ms, decision quality at 50% |
| **SUBACUTE** | 8 minutes - 2 hours | 60-85% of normal (15-40% reduction) | Mild balance impairment (-10%), visual tracking partially impaired (-20%), reaction delay +15-40ms, decision quality at 70% |
| **RECOVERY** | 2 hours - multiple in-game days | Gradual: 85% -> 95% -> 100% | Effects diminish gradually; minor residual effects possible |

### 6c. Specific New Fields/Effects to Add

**New fields on CoreEntity:**
```
_concussion_phase: int          # 0=none, 1=critical, 2=acute, 3=subacute, 4=recovery
_concussion_onset_time: float   # when concussion started
_concussion_severity: float     # 0.0-1.0 based on impact force/bone damage
_persistent_effects_active: bool # true if effects carry over beyond immediate phase
_second_impact_vulnerable: bool # true if brain still healing from prior concussion
_last_concussion_time: float    # for second-impact vulnerability tracking
```

**New modifier categories (beyond perception):**
| Modifier | Description | Critical Phase | Acute Phase | Subacute Phase | Recovery |
|----------|-------------|----------------|-------------|----------------|----------|
| `perception_mult` | Visual/cognitive processing speed | 0.25-0.40 | 0.40-0.60 | 0.60-0.85 | 0.85->1.0 |
| `reaction_time_ms_add` | Extra delay on all reactions (ms) | +100 to +150 | +60 to +100 | +15 to +40 | +5 to +15 |
| `balance_mult` | Movement control/stability | 0.50 | 0.70 | 0.90 | 0.95->1.0 |
| `decision_quality` | AI tactical choice quality (0-1) | 0.30 | 0.50 | 0.70 | 0.80->1.0 |
| `visual_tracking_mult` | Ability to track moving targets | 0.30 | 0.60 | 0.80 | 0.90->1.0 |
| `spatial_judgment_ms_add` | Error in distance/timing judgment (ms equiv.) | +400-500 | +200-300 | +50-100 | +10-30 |

### 6d. Second Impact Syndrome Implementation

**Vulnerability window:**
- `second_impact_vulnerable = true` from moment of first concussion until **full recovery** (or until a safe interval has passed)
- For gameplay purposes: vulnerability lasts for the entire duration of any concussion phase PLUS an additional buffer period
- **Recommended vulnerable window:** Concussion onset time + **15 minutes** minimum (for mild), up to **2 hours** if there were prior concussions or severe initial impact
- This maps reasonably to game time while reflecting that the brain remains vulnerable well after symptoms improve

**Severity multiplication if hit during vulnerable window:**
| Timing of second impact | Severity multiplier | Effect |
|-------------------------|--------------------|--------|
| Within first 5 minutes | **3-5x** original severity | SIS risk active — catastrophic outcome possible |
| 5-15 minutes | **2-3x** original severity | Severe compound concussion, extended recovery |
| 15 minutes - 2 hours | **1.5-2x** original severity | Significant re-injury, prolonged effects |
| After 2 hours (if still symptomatic) | **1.2-1.5x** | Minor aggravation, extends timeline slightly |

**SIS catastrophic outcome (optional but recommended):**
If second impact occurs within first **3 minutes** of initial concussion AND severity multiplier would exceed a threshold:
- Immediate incapacitation (KO state, not just reduced function)
- Extended recovery period (days in-game equivalent)
- Permanent stat reduction option (-5% to -15% permanently on one or more stats, representing lasting brain injury)

### 6e. Recovery Curve Implementation

**Gradual recovery is essential.** Do NOT use an abrupt "concussion expires" model.

```
Recovery function (simplified):

phase 1 (Critical: 0-90s):    severity = initial_severity * 1.0
phase 2 (Acute: 90s-8min):    severity = initial_severity * lerp(1.0, 0.5, elapsed_in_phase / phase_duration)
phase 3 (Subacute: 8min-2hr): severity = initial_severity * lerp(0.5, 0.2, elapsed_in_phase / phase_duration)
phase 4 (Recovery: 2hr+):     severity = initial_severity * max(0.0, 0.2 - (elapsed_since_subacute / recovery_period))

Where recovery_period maps to in-game days for persistent effects (if any)
```

**For multi-session games (campaign mode):**
- Track `_last_concussion_time` and `_cumulative_concussion_count`
- If multiple concussions within a short period: each successive concussion has **increasing severity** and **longer recovery** (reflects cumulative brain injury)
- After 2+ concussions in a session: effects may persist into subsequent sessions with reduced baseline stats until full rest/recovery

### 6f. Pain-Concussion Interaction

Per Gosselin et al. (J Neurotrauma 2012) and Greenberg et al. (Psychosomatics 2020):
- **Pain worsens concussion symptoms** — they amplify each other synergistically, not independently
- Pain catastrophizing explains 41% of post-concussion symptom variance

**Implementation:** When both pain shock AND concussion are active simultaneously:
```
combined_effect = concussive_reduction + pain_shock_reduction + (concussive_reduction * pain_shock_reduction * 0.3)
# The 0.3 factor represents the synergistic amplification (~30% additional impairment when both present)
```

Per the current codebase, this means if pain shock = 50% reduction and concussion perception = 40%, rather than just multiplying them (0.5 * 0.4 = 20% remaining), add a **15-20 percentage point penalty** for the synergistic effect, resulting in ~15-20% remaining function instead of 20%.

### 6g. Summary of Recommended Constant Changes

Replace current constants in `PainConsciousnessConstants.gd` / `EntityPainConsciousness.gd`:

| Old Value | New Value(s) | Notes |
|-----------|-------------|-------|
| `CONCUSSION_DURATION_MIN_S = 3.0` | Phase-based: Critical=90s, Acute~7.5min, Subacute~1.8hr | Duration now reflects phases, not a single number |
| `CONCUSSION_DURATION_MAX_S = 15.0` | Recovery phase extends to hours or game-days for persistent effects | Multi-phase timeline |
| `CONCUSSION_PERCEPTION_PENALTY_MULT = 0.4` | Phase-dependent: 0.25 (critical) -> 0.60 (acute) -> 0.85 (subacute) | Gradual improvement |
| *(none)* | `CONCUSSION_CRITICAL_DURATION_S = 90.0` | New constant |
| *(none)* | `CONCUSSION_ACUTE_DURATION_S = 480.0` | New constant |
| *(none)* | `CONCUSSION_SUBACUTE_DURATION_S = 7200.0` | New constant (2 hours) |
| *(none)* | `REACTION_TIME_MS_ADD_CRITICAL = 150.0` | New modifier category |
| *(none)* | `REACTION_TIME_MS_ADD_ACUTE = 100.0` | New modifier category |
| *(none)* | `REACTION_TIME_MS_ADD_SUBACUTE = 40.0` | New modifier category |
| *(none)* | `BALANCE_MULT_CRITICAL = 0.5` | New modifier category |
| *(none)* | `DECISION_QUALITY_CRITICAL = 0.3` | New modifier for AI |
| *(none)* | `VISUAL_TRACKING_MULT_CRITICAL = 0.3` | New modifier category |
| *(none)* | `SECOND_IMPACT_VULNERABLE_WINDOW_S = 900.0` | 15-minute SIS vulnerability window |
| *(none)* | `SIS_SEVERITY_MULTIPLIER_CRITICAL = 4.0` | Second impact within first minutes |

---

## Sources Cited

1. **Wikipedia: Concussion** — General concussion symptoms, timelines, pathophysiology, recovery data (citing CDC, WHO, NIH sources)
2. **Wikipedia: Post-concussion syndrome** — PCS prevalence, duration, symptom persistence rates (Hall et al. 2005; Olver 2005; Mittenberg; Dorsten)
3. **Wikipedia: Second impact syndrome** — SIS mechanism, mortality/morbidity, vulnerability window, historical cases (Cantu 1998; McCrory & Berkovic 1998; Saunders 1984; Bowen 2003)
4. **Gosselin A et al. (2012)** — J Neurotrauma: Pain worsens concussion symptoms; reduced mid-DLPFC activation during cognitive tasks in mTBI+pain patients
5. **Greenberg et al. (2020)** — Psychosomatics: Pain catastrophizing explains 41% of postconcussion symptom variance
6. **Mah et al. (2018)** — CDC/CDC-aligned: Recovery timelines; 2 weeks adults, 4 weeks children
7. **Marshall 2023** — Persisting symptoms after concussion defined as >14 days adult / >4 weeks youth
8. **CDC** — Concussion signs/symptoms, GCS criteria for mTBI (13-15), LOC <30 min, PTA <24 hours
9. **Wikipedia: Knockout** — Combat sports KO durations; stunned/dazed 3-8s
10. **PainConsciousnessConstants.gd / EntityPainConsciousness.gd** (current codebase) — Current concussion implementation for comparison
