# Adrenaline Surge Under Hemorrhage: Research-Backed Data for Game Implementation

**Compiled for:** Fallen Paths tactical combat game
**Purpose:** Fix the physiological model of the blood-loss-triggered adrenaline (catecholamine) dump — the surge that remedies the fight-or-flight response when a fighter is bleeding out.

The surgical summary used to be a **discrete on/off pulse**: a 60–120 s surge followed by a 2 min refractory cooldown, regardless of whether the fighter was still bleeding. That reproduces an absent "adrenaline wears off while you are still bleeding out" state. This doc records why that model was wrong and how the sustained model is grounded.

---

## 1. WHAT THE SURGE IS

### 1a. Catecholamine response is a *sustained stress state*, not a single brief spike

The fight-or-flight response is governed by the sympathetic nervous system and the adrenal medulla, releasing **epinephrine** (adrenaline) and **norepinephrine** (noradrenaline).

| Property | Value / Basis |
|----------|---------------|
| Onset | Near-instantaneous; peak plasma catecholamines within ~2–3 min of the stressor |
| Epinephrine plasma half-life | ~2–3 min |
| Norepinephrine half-life | Slightly longer; reuptake-driven clearance |
| *Functional* sympathetic elevation | Persists **10–30+ min** while the stressor remains (Norepinephrine-driven "sustained arousal") |
| HPA / cortisol axis (separate system) | Peaks ~15–30 min; not the acute surge we model |

Key point: the **peak epinephrine spike is brief**, but the **performance-relevant sympathetic elevation is sustained for minutes while the threat persists**. The game's older 60–120 s window sat below *both* interpretations for an on-going stressor.

### 1b. A hemorrhage is a *persistent* stressor

In a bleeding fighter, the blood loss is an ongoing threat. The sympathetic drive is maintained by baroreceptor detection of falling blood volume and continued tissue trauma. There is no "off" switch while the bleed continues — the fighter does not return to a calm baseline mid-bleed only to re-surge two minutes later.

**Clinical consequence:** adrenaline effects should **sustain while the fighter is actively bleeding**, and only **resolve once the bleeding is controlled** (tourniquet, pressure, healing) — or collapse with decompensated shock at Class IV.

---

## 2. WHAT THE RESEARCH SAYS ON IMPAIRMENT VS. BOOST

### 2a. Yerkes–Dodson: arousal is task-graded

- **Gross motor / speed / power (fight):** moderate-to-high arousal *improves* raw force and reaction.
- **Fine motor precision (surgery, archery, shooting):** overarousal causes **tremor, reduced manual dexterity, impaired fine motor sequencing**.
- Moderate arousal can *improve* some manual dexterity (testosterone-linked), but *maximal* sympathetic activation degrades it.

Game impact: the surge gives a modest **gross-motor boost** (`ADRENALINE_PERFORMANCE_BASELINE_MULT = 1.05`) plus **fine-motor penalty** (`ADRENALINE_FINE_MOTOR_PENALTY = 0.70`, i.e. −30% precision) and **pain suppression** (−50%). These are consistent with the clinical picture: strong, fast movement kept sharp; precision/tremor degraded.

### 2b. Shock overwhelms the receptors (the "wired but collapsing" fighter)

At Class III+ hemorrhage, catecholamines are *sky-high* but peripheral vasoconstriction and tissue hypoxia downregulate β-adrenergic receptors. The patient looks wired but is functionally collapsing. This is already modeled by `ADRENALINE_NEUTRALIZATION_ATLS_CLASS_III_MIN` and `ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE`, which progressively negate the surge's benefits at deep shock. This logic is preserved.

---

## 3. GAME CONSTANTS (AFTER THIS CHANGE)

### 3a. Trigger (unchanged)

| Constant | Value | Clinical basis |
|----------|-------|----------------|
| `ADRENALINE_TRIGGER_RAMP_MAX_REMAINING` | 82% blood | Class II onset (70–85% remaining) |
| `ADRENALINE_TRIGGER_RAMP_MIN_REMAINING` | 70% blood | Class III boundary (60–70% remaining) |
| `ADRENALINE_TRIGGER_MIN_ABS_REMAINING` | 60% = Class III floor | Below Class III→IV, baroreceptor failure |

### 3b. Surge effect magnitudes (unchanged)

| Constant | Value | Clinical basis |
|----------|-------|----------------|
| `ADRENALINE_PERFORMANCE_BASELINE_MULT` | 1.05 | modest gross-motor boost (Yerkes–Dodson high-arousal zone for fight) |
| `ADRENALINE_FINE_MOTOR_PENALTY` | 0.70 | −30% fine precision; tremor/dexterity loss at maximal arousal |
| `ADRENALINE_PAIN_SUPPRESSION` | 0.50 | −50% pain perception (epinephrine analgesia) |
| `ADRENALINE_NEUTRALIZATION_ATLS_CLASS_III_MIN` | 3 | benefit-negation begins at Class III |
| `ADRENALINE_PERFORMANCE_NEUTRALIZATION_RATE` | 0.5 | fraction of performance lost per Class above threshold |

### 3c. Duration / sustain (CHANGED — this is the fix)

Old (wrong): duration 60–120 s, then forced "return to baseline", plus a 120 s refractory cooldown that created an on/off pulse while the fighter was still bleeding.

New (clinically grounded):

| Behavior | Basis |
|----------|-------|
| **Sustain while bleeding** | The hemorrhage is a persistent stressor; sympathetic arousal continues while the bleed continues. A surge in progress is extended, not faded and re-triggered. |
| **Resolve when bleeding is controlled** | Sympathetic drive withdraws once the stressor (bleeding) is resolved. The 60–120 s timer governs the *post-control* decay to baseline (residual norepinephrine clearance). |
| **Class IV decompensation** | At <60% blood the baroreceptor response collapses; the surviving dump is fully neutralized by §2b so no gameplay benefit remains. |

---

## 4. IMPLEMENTATION SUMMARY

- `try_enter_adrenaline_dump`: while the entity is **actively bleeding**, an in-progress dump is **extended** (no cooldown gap) instead of returning; a new dump's refractory cooldown is only enforced when the entity is **not** bleeding (true neuro-refractory period, not an artifact).
- `tick_adrenaline_dump`: while **actively bleeding**, the surge is kept armed (sustained), NOT expired on the wall-clock; it only expires when bleeding has stopped.

Active bleeding is detected via the entity's total bleeding rate above `BLEEDING_RATE_EPSILON` (the canonical sign that blood is still leaving the body).

---

*Sources: acute stress/sympathetic nervous system reviews (Frontiers in Psychology 2019, "Performance Under Pressure" reviews); Yerkes–Dodson arousal literature; police/gunfight sympathetic-activation surveys (85% report auditory exclusion, tremor, fine-motor degradation under high arousal); sympatho-adrenal catecholamine kinetics (epinephrine half-life ~2–3 min; norepinephrine-sustained arousal ~10–30 min).*
