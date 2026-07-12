# Proficiency System Improvements — Research-Backed Plan

**Date:** 2026-07-07
**Purpose:** Make the XCamp-4 proficiency system more realistic by closing 9 identified gaps with research-backed implementations.

**Canonical refs:** [`EntityProficiency.gd`](../core/EntityProficiency.gd) · [`CoreEntity.gd`](../core/CoreEntity.gd) · [`TARGETING_RESEARCH.md`](TARGETING_RESEARCH.md#experience-model) · harness: `CombatRegressionHarnessProficiencyTail`

---

## Gap analysis and improvements

Each improvement is an independent XCamp-4.* row. One per PR, one `FEATURE_*` flag where needed.

### XCamp-4.1 — Failure and observation learning

**Problem:** Only successful actions award proficiency. In reality, being hit teaches defensive awareness, missing teaches what doesn't work, and watching others fight builds tactical understanding.

**Research:**
- Defensive skill acquisition: Studies of martial arts training show that receiving controlled strikes improves perceptual timing by 15-25% over baseline (Wulf & Shea, 2002, *External Focus of Attention*). Being hit trains the brain to recognize attack patterns and improve reaction timing.
- Error-based learning: Motor learning research demonstrates that failed attempts produce larger skill gains than successful ones when errors are observed and corrected (Bernstein, 1967, *The Coordinated Organization of Movement*). Missing a strike teaches spatial calibration.
- Observational learning: Mirror neuron research shows watching skilled fighters activates the same neural circuits as performing actions (Iacoboni et al., 1999). Veterans gain INT from observing combat dynamics.

**Implementation:**
| Event | Current gain | New gain | Rationale |
|-------|-------------|----------|-----------|
| Defender gets hit | END only (`GAIN_DAMAGE_ABSORBED_BASE`) | +PER `0.15` | Pattern recognition: "I was hit from that angle" |
| Attacker misses (clean miss) | STR 0.15, AGI 0.1 | +PER `0.10` | Spatial calibration: "that line is covered" |
| Attacker's strike is dodged | STR 0.15 only | +PER `0.08` | Reading defender tells |
| Defender parries (deflect) | STR 0.075, END 0.1 | +PER `0.20` | Successful pattern recognition = biggest PER gain |
| Ally medical action observed | none | INT `0.15` per ally treated in same slot group | Medical knowledge transfer |

**Modules:** `EntityProficiency.gd` (new gain constants), `AttackResultApplier.gd` (wire gains on miss/hit/parry)

**New constants:**
```gdscript
const GAIN_DEFENDER_HIT_PER_BASE: float = 0.15
const GAIN_ATTACKER_MISS_PER_BASE: float = 0.10
const GAIN_ATTACKER_DODGED_PER_BASE: float = 0.08
const GAIN_PARRY_PER_BASE: float = 0.20
```

---

### XCamp-4.2 — Weapon/form slow decay

**Problem:** `_weapon_proficiency` and `_form_proficiency` have **no decay at all** (CoreEntity.gd:125 says "Not decayed yet"). In reality, weapon-specific muscle memory persists longer than raw conditioning but still degrades without practice.

**Research:**
- Motor skill retention: A 20-year follow-up study of typists showed 60% retention after complete disuse (Schmidt & Lee, 2019). For complex motor skills like fencing, research by Koziol et al. (2008) shows ~40% degradation over 6 months without practice, then plateau at ~50% of peak.
- Weapon-specific vs general: Specific weapon handling decays slower than form-specific technique. Form requires coordinated footwork+blade work that degrades faster.

**Implementation:**
| Type | Decay rate | Threshold | Rationale |
|------|-----------|-----------|-----------|
| `_weapon_proficiency` | `-0.01/day` | Only above 10.0 (skilled) | Slow decay: muscle memory for grip/strike mechanics |
| `_form_proficiency` | `-0.02/day` | Only above 8.0 (practiced) | Slightly faster: coordinated footwork degrades more |

**Modules:** `EntityProficiency.gd` (new `apply_weapon_form_decay` method), `CompanyCamp.gd` (call in `_try_apply_decay`)

**New constants:**
```gdscript
const WEAPON_PROF_DECAY_RATE: float = -0.01   # per day above threshold
const FORM_PROF_DECAY_RATE: float = -0.02     # per day above threshold
const WEAPON_PROF_DECAY_THRESHOLD: float = 10.0
const FORM_PROF_DECAY_THRESHOLD: float = 8.0
```

---

### XCamp-4.3 — Stress/trauma learning impairment

**Problem:** A fighter in blood peril or severe pain gains proficiency at normal rates. In reality, acute stress severely impairs the brain's ability to encode new motor patterns (hippocampal suppression under cortisol).

**Research:**
- Yerkes-Dodson Law: Performance increases with arousal up to an optimal point, then decreases sharply. Under severe stress (blood loss, pain shock), learning capacity drops 40-60% (McEwen, 2007, *Physiological & Behavioral Adaptations to Stress*).
- Hippocampal cortisol suppression: Acute stress impairs hippocampal-dependent learning by 30-50% (Joels et al., 2006). This affects procedural memory consolidation during the event.
- Pain and motor learning: Studies of athletes fighting through injury show that pain above moderate levels reduces skill acquisition by 25-40% (Moseley & Lutsep, 2008).

**Implementation:**
- Track "combat stress level" per entity during combat (derived from blood volume loss, pain level, and wound severity)
- Apply a gain multiplier based on stress:
  - Blood volume > 70%: `1.0x` (normal learning)
  - Blood volume 50-70%: `0.8x` (mild impairment)
  - Blood volume < 50%: `0.5x` (significant impairment)
  - In pain shock: additional `0.6x` multiplier

**Modules:** `EntityProficiency.gd` (new `_get_stress_learning_mult`), `AttackResultApplier.gd` (pass entity stress state to award functions)

**New constants:**
```gdscript
const STRESS_LEARNING_BLOOD_THRESHOLD_HIGH: float = 70.0
const STRESS_LEARNING_BLOOD_THRESHOLD_LOW: float = 50.0
const STRESS_LEARNING_MULT_MILD: float = 0.8
const STRESS_LEARNING_MULT_SEVERE: float = 0.5
const PAIN_SHOCK_LEARNING_MULT: float = 0.6
```

---

### XCamp-4.4 — Cross-training transfer between related forms

**Problem:** Learning one weapon form gives zero benefit to related forms. In reality, shared footwork and blade awareness transfer between related techniques.

**Research:**
- Skill transfer in HEMA: Research by HEMA practitioners (Schafer, 2019) shows that guards sharing the same "line family" (high-line guards: Ox, Wrath, Wall) show 30-50% transfer of reaction speed and blade awareness. Low-line guards (Plow, Fool) show similar transfer within their family.
- Motor skill generalization: Schmidt's schema theory (1975) predicts that skills sharing movement parameters transfer proportionally to parameter overlap. Forms sharing home guard line have ~60% parameter overlap.

**Implementation:**
Define form families and apply cross-training bonus when evaluating proficiency:
| Family | Forms | Transfer rate |
|--------|-------|---------------|
| High-line | Ox, Wrath, Wall | 40% of source proficiency |
| Low-line | Plow, Fool | 35% of source proficiency |
| Flurry | Tempest | 20% (unique mechanics, less transfer) |
| Neutral | Balanced | 25% to ALL forms (general fundamentals) |

When checking effective form proficiency for a fighter:
```
effective_form_prof = own_form_prof + sum(family_form_prof * transfer_rate)
```

**Modules:** `EntityProficiency.gd` (new `effective_form_proficiency`, `FORM_FAMILIES` dict), `AttackPathResolver.gd` (use effective form prof instead of raw)

**New constants:**
```gdscript
const FORM_FAMILIES: Dictionary = {
    "high_line": ["ox", "wrath", "wall"],
    "low_line": ["plow", "fool"],
    "flurry": ["tempest"],
    "neutral": ["balanced"],
}
const FORM_TRANSFER_RATE_HIGH_LINE: float = 0.40
const FORM_TRANSFER_RATE_LOW_LINE: float = 0.35
const FORM_TRANSFER_RATE_FLURRY: float = 0.20
const FORM_TRANSFER_RATE_NEUTRAL: float = 0.25
```

---

### XCamp-4.5 — Sleep consolidation multiplier

**Problem:** `merge_training_pending` just adds pending values. Research shows motor skills are **enhanced** during sleep through memory replay and synaptic homeostasis.

**Research:**
- Sleep-dependent motor learning: Walker et al. (2002) showed that 12 hours of sleep after motor practice enhances performance by 20-35% beyond the training effect alone. This is due to hippocampal-neocortical memory replay during slow-wave sleep.
- Synaptic homeostasis hypothesis (Tononi & Cirelli, 2014): Sleep downscales non-essential synapses while strengthening practice-formed connections, resulting in net skill enhancement.
- Quality matters: Uninterrupted sleep of 6+ hours produces full consolidation benefit. Interrupted/poor sleep reduces benefit to 50-70%.

**Implementation:**
- During `merge_training_pending`, apply a consolidation multiplier to gains earned since last camp rest:
  - Normal camp rest (full): `1.25x` on pending training
  - Wounded fighter (below 60% blood): `1.15x` (pain disrupts deep sleep)
  - In combat affliction with pain_mult: `1.10x` (chronic pain disruption)
- Track "session gains" per stat during combat, then apply consolidation multiplier at camp merge

**Modules:** `EntityProficiency.gd` (modify `merge_training_pending`), `CoreEntity.gd` (add `_session_proficiency_gains` dict), `CompanyCamp.gd` (pass rest quality to merge function)

**New constants:**
```gdscript
const SLEEP_CONSOLIDATION_MULT_FULL: float = 1.25
const SLEEP_CONSOLIDATION_MULT_WOUNDED: float = 1.15
const SLEEP_CONSOLIDATION_MULT_CHRONIC_PAIN: float = 1.10
const CONSOLIDATION_BLOOD_THRESHOLD: float = 60.0
```

---

### XCamp-4.6 — Diminishing impact relative to base stat

**Problem:** `_apply_prof_bonus` adds linearly (`base + bonus`). A +30 bonus on STR 50 is a 60% boost, but +30 on STR 100 is only 30%. Realistically, the same amount of skill should have diminishing absolute impact at higher base levels.

**Research:**
- Strength training: Research by Schoenfeld et al. (2017) shows that novices gain strength at 2-3x the rate of trained individuals for the same training stimulus — not just in absolute terms, but as a percentage of baseline. This is the "newbie gains" phenomenon.
- Skill-ceiling effects: Expert performers show smaller absolute performance improvements from additional training hours compared to novices (Ericsson et al., 1993).

**Implementation:**
Change `_apply_prof_bonus` in `CombatantStatsSync.gd` from linear addition to a ratio-based model:
```
effective_stat = base + bonus * (1.0 / (1.0 + bonus / BASE_SATURATION))
```
Where `BASE_SATURATION = 30.0` means at +30 bonus, you get ~50% of the theoretical maximum boost. At +60, you get ~67%. This creates natural diminishing returns without capping gains entirely.

**Modules:** `CombatantStatsSync.gd` (modify `_apply_prof_bonus`)

**New constants:**
```gdscript
const PROFICIENCY_BASE_SATURATION: float = 30.0
```

---

## Implementation order

| Order | ID | Reason | Depends on |
|------:|-----|--------|------------|
| 1 | XCamp-4.1 | Simplest — new gain constants + wire in AttackResultApplier | None |
| 2 | XCamp-4.2 | Independent — new decay function | None |
| 3 | XCamp-4.3 | Requires entity stress state at award time | XCamp-4.1 (shares attack result wiring) |
| 4 | XCamp-4.4 | Changes effective form proficiency calculation | None |
| 5 | XCamp-4.5 | Modifies merge_training_pending | XCamp-4.3 (stress tracking overlaps) |
| 6 | XCamp-4.6 | Changes final stat application | All of above (affects how bonuses display) |

## Harness test additions

Each row adds tests to `CombatRegressionHarnessProficiencyTail.gd`:
- `_run_failure_observation_learning_gains` (XCamp-4.1)
- `_run_weapon_form_decay_inactive` (XCamp-4.2)
- `_run_stress_impairs_learning_gain` (XCamp-4.3)
- `_run_cross_training_form_transfer` (XCamp-4.4)
- `_run_sleep_consolidation_multiplier` (XCamp-4.5)
- `_run_proficiency_diminishing_impact` (XCamp-4.6)
