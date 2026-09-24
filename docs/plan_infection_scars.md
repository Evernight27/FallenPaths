# Infection & Scar Plan (Staged Infection / Sepsis + Wound-Derived Scars)

**Date:** 2026-09-21
**Status:** PROPOSAL — design agreed (staged transient infection + systemic sepsis; permanent wound-derived scars with per-part combat effects). Pending implementation.

## Concept

Two complementary, medically-anchored upgrades to the health system, both building on systems that **already exist**:

1. **Infection** — extend the current single-stage, per-wound, campaign-only infection (a 0→1 `infection_progress` dose that only slows healing) into a **staged** condition (localized → septic) with **systemic** consequences (stamina drain, a distinct sepsis death path) and **susceptibility** modelling (starvation, fatigue, concussion raise the risk).
2. **Scars** — promote the current `campaign_afflictions` system from a *battle-end RNG roll on aggregate state* into a **wound-derived, per-part permanent condition**, minted *when a wound resolves*, whose stored `part` actually feeds that part's damage/bleeding/healing.

Design in one line: **infection = transient per-wound condition (extend the existing 0→1 dose into localized→septic with systemic effects)**; **scar = permanent per-part condition minted when a wound resolves (make the stored `part` actually matter in combat).**

Research basis: [`wound_infection_data.md`](wound_infection_data.md) (sepsis mortality, untreated-wound infection rates, "laudable pus" history, treatment-level outcomes).

---

## Part 1 — Staged Infection + Sepsis

### 1.1 State

Extend the wound dict (owned by `CoreEntity.wounds`, mutated via `EntityWounds` / `DataKeys`):

- Keep `infection_progress` (0→1) and `is_infected` (boolean).
- Add `infection_stage: int` — `0` clean · `1` localized (what `is_infected` represents today) · `2` septic.
- Add `sepsis_progress: float` (0→1) — accrues only while `stage == 1` on an untreated part.

Entity-level (`core/CoreEntity.gd`) — **sepsis is a systemic entity state, not a per-wound property** (the wound's `infection_stage` drives *progression into* sepsis; these drive its *systemic consequences* — see §11):

- `is_septic: bool` — the **systemic** sepsis state; set when any wound reaches `infection_stage == 2`, persists until resolved. Source of truth for all systemic effects + the death/resolve rolls.
- `sepsis_resolve_progress: float` (0→1) — accrues only while source-controlled; at 1.0 → `is_septic = false` (recovered).
- `_sepsis_dead: bool` — death flag (mirrors the vital-part-destruction flag pattern); **fold into `is_dead()`** (`CoreEntity.gd:517`).
- `resolved_wounds_this_advance: Array[Dictionary]` — transient, stashed by `EntityHealing`, consumed by the world scar layer (Part 2). Cleared after minting.

### 1.2 New & consolidated constants (`core/BleedingConstants.gd`) — *authoritative values*

The existing severity-driven base risk (minor 0.08 → critical 0.50/day, compound ×2.0, arterial ×1.5, treated ×0.15) **already encodes open-fracture infection rates** (consistent with `wound_infection_data.md` §6: deep/contaminated wounds 40–60%, untreated 60–80%). Keep it. The constants below **multiply** the per-day dose or drive the new stages. **This section is the single source of truth for infection constants**; §9.2/§9.3 and §10 record the research rationale + before→after history only. **Phase**: `A` = in-scope (Phase A), `A+` = near-term, `deferred`.

**Infection needs an open tract**: the per-day dose applies only to wounds with an entry portal (`BleedingConstants.injury_has_open_entry`, the same closed-wound boundary CAMP-SCAR-1 uses for scar minting). A contusion (bruise) and a clean (non-compound) fracture have no portal — intact or internally contained tissue — so their dose is zero and they never localize, septic, or seed tetanus/gangrene. `compound_fracture` is open (exposed bone); cut/stab/crush breach tissue; internal_bleed keeps the boundary; legacy descriptors missing `injury_type` keep the old rule. The gate is entry-only: a wound already infected (legacy save) keeps its sepsis track.

**Staging / sepsis**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY` | `0.40` | A | Untreated soft-tissue infection progresses to bacteremia/SIRS within ~24–72 h. 0.4/day ≈ 2.5 days untreated. [`wound_infection_data.md` §2]. |
| `SEPSIS_DEATH_RISK_PER_DAY` | `0.35` | A | Pre-antibiotic severe-sepsis mortality 70–90%+; modern ICU 25–50%. 0.35/day ≈ "near-fatal without care". [`wound_infection_data.md` §1]. |
| `SEPSIS_STAMINA_MULT` | `0.70` | A | **Corrected from 0.65** (§9.2). Systemic catabolism + CIP/CIM weakness: "**about half of patients recover fully**" over weeks–months → a significant but survivable deficit, not collapse. 30% cap loss is the defensible midpoint. |
| `SEPSIS_HEAL_SPEED_MULT` | `0.25` | A | Septic parts heal even slower than infected (existing `WOUND_INFECTION_HEAL_SPEED_MULT = 0.5` covers stage 1). |
| `SEPSIS_HEAL_DURATION_MULT` | `1.50` | A | Stacked on the stage-1 extension (§10.4): septic tissue is devitalized; compounds the wall-clock resolution delay. |

**Susceptibility (multiplies the per-day dose, capped by `INFECTION_DAILY_DOSE_CAP`)**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `INFECTION_RISK_STARVATION_MULT` | `1.5` | A | Malnutrition (hypoalbuminemia <3.0 g/dL) is an independent wound-infection risk factor; impairs neutrophil chemotaxis/phagocytosis. Lerp 1.0 (well-fed) → 1.5 (starving) on `nutrition_level`. [`wound_infection_data.md` §6]. |
| `INFECTION_RISK_FATIGUE_MAX_MULT` | `1.25` | A | Psychoneuroimmunology: chronic stress/exhaustion → elevated cortisol → immune suppression. Lerp 1.0 → 1.25 on `campaign_fatigue`. |
| `INFECTION_RISK_CONCUSSION_MULT` | `1.2` | A | TBI induces a documented state of immunocompromise. Applied while `EntityPainConsciousness.get_concussion_phase_info` reports the acute phase. |
| `INFECTION_DAILY_DOSE_CAP` | `0.90` | A | After all multipliers, cap the per-day infection dose at 0.9 so even a worst-case stack needs ~2 days to infect, never 1. Keeps the treatment window open (promotes the §7 risk mitigation to a real constant). |

**Sepsis as a playable systemic state**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `SEPSIS_COMBAT_PERCEPTION_MULT` | `0.80` | A | Septic **confusion** is a core symptom (CNS/altered mental status). Model sepsis as a *playable* state: a septic member thinks slower — fold into `EntityPainConsciousness` perception at battle start, cleared when sepsis resolves. |
| `SEPSIS_COMBAT_STAMINA_DRAIN_MULT` | `1.30` | A | Sepsis = distributive shock + catabolism; a septic member burns stamina faster in combat (tachycardia, low perfusion). 30% higher stamina drain per action while `stage==2`. |
| `INFECTION_LOCALIZED_PAIN_MULT` | `1.10` | A | Stage-1 localized infection (cellulitis: warmth, swelling, pain) → +10% pain on the affected part while `stage==1`, via the existing per-part pain contribution. Low-stakes, recoverable window. |

**Treatment / source control**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `INFECTION_DRESSING_CLEAR_STAGE1` | `0.40` | A | **Corrected from 0.65** (§9.2). Even "good care" (honey + wine + clean dressings, rest) only cuts infection 60–80% → 20–35%; a *single* dressing attempt is weaker than sustained care, so per-attempt must sit below the sustained-care benefit. **Repeatable** (re-dress each day) → cumulative care climbs toward the 20–35% residual. INT-scaled upward. |
| `SEPSIS_RESOLVE_PER_DAY_TREATED` | `0.25` | A | Septic infection needs **source control** (§10.5): accrues only while the septic focus has definitive hemostasis **or** is a stump/amputated; otherwise `sepsis_resolve_progress` stays 0. Historically mostly fatal → even treated only ~25%/day. |
| `SEPSIS_DEATH_RISK_SOURCE_CONTROLLED` | `0.12` | A (proposed) | Once the septic focus is source-controlled (treated/amputated), bacterial load is removed and mortality drops sharply; the per-day death roll falls from 0.35 → 0.12 while `sepsis_resolve_progress` accrues. This is the "source control saves lives" lever (§11.3). |

**Contamination / debris**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `WOUND_INFECTION_CONTAMINATED_MULT` | `1.75` | A | Dirty/debrised/foreign-body wounds are markedly more infection-prone than clean wounds (pre-antibiotic wound-infection literature). Multiplies the per-day dose in `wound_infection_daily_risk`; auto-flagged by penetration depth. Feeds §10.1/§10.2 candidacy. |
| `CONTAMINATION_PENETRATION_MM` | `5.0` | A | Cuts/stabs penetrating to the "deep/full" band auto-flag `is_contaminated`. Set to `PENETRATION_DEPTH_SEVERITY_FULL_MM` (5.0), the codebase's existing "deep enough to matter" threshold. (Max achievable cut pen ≈ 11mm via `cut_tissue_ultimate_pen_mm`, so an earlier 12.0 would never have fired.) |

**Heal-duration extension (track a — wall-clock resolution)**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `INFECTION_HEAL_DURATION_MULT` | `1.75` | A | Infected wounds close slower (enzymatic tissue destruction + delayed epithelialization); extends the wall-clock **resolution** duration ~75% one-way at the stage-0→1 flip (§10.4). Distinct from the `heal_speed` multiplier (track b). |

**Gas gangrene / necrotizing variant**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `GAS_GANGRENE_PROGRESS_MULT` | `2.0` | A+ | Clostridial myonecrosis progresses faster than ordinary sepsis (onset can begin ~12 h vs multi-day). Multiplies `sepsis_progress` accrual while the wound is `is_gas_gangrene`. |
| `GAS_GANGRENE_DEATH_RISK_PER_DAY` | `0.50` | A+ | StatPearls: **~100% fatal untreated**; 20–30% even with debridement/amputation + antibiotics. 0.50/day → ~75% dead by day 2: near-fatal until source control (amputation) removes the focus. Higher per-day roll than ordinary sepsis (0.35). |
| `GAS_GANGRENE_CANDIDATE_BASE_RISK` | `0.50` | A+ | Fraction of qualifying stage-2 wounds (crush / compound / deep-penetration / low-perfusion) that become gangrenous, severity-scaled up. |

**Tetanus — delayed spore-borne channel**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `TETANUS_INCUBATION_MIN_DAYS` | `3.0` | A+ | Documented 3–21 day incubation (short end). Spore-borne, toxin-mediated; manifests *after* the wound can fully heal. |
| `TETANUS_INCUBATION_MAX_DAYS` | `21.0` | A+ | Documented long end. |
| `TETANUS_ONSET_RISK` | `0.30` | A+ | Base fraction of contaminated deep punctures that germinate + manifest (pre-antibiotic, no prophylaxis). A high-quality wound clean at the moment of injury reduces this (debridement removes spores before germination) — the player's counter-play. |
| `TETANUS_SYMPTOMATIC_DAYS` | `7.0` | A+ | In-game length of the symptomatic spasm window (a compression of the real multi-week course). Bounds the per-day death roll so cumulative mortality stays realistic. |
| `TETANUS_DEATH_RISK_PER_DAY` | `0.12` | A+ | Over the 7-day window, cumulative = 1−(1−0.12)^7 ≈ 57% — a pre-antibiotic generalized-tetanus figure (modern CFR is only ~6–10% *with* TIG + ventilation; untreated historical is far higher). Shorter real-world incubation → worse prognosis; this is the knob to make a fast-onset case deadlier. |
| `TETANUS_PERCEPTION_MULT` | `0.85` | A+ | Tetanospasmin → rigidity/spasm impairs aim/handling; a playable systemic tell (whole-body, not `part`-scoped). |

**Osteomyelitis — infected compound fracture → chronic bone**

| Constant | Value | Phase | Research anchor |
|---|---|---|---|
| `OSTEOMYELITIS_BONE_HEAL_MULT` | `0.50` | A+ | Chronic osteomyelitis markedly prolongs bone healing; halves effective bone-heal rate while the sequestered nidus is present. |

### 1.3 Flow (`core/EntityHealing.gd`, campaign day-advance only)

Infection advances only inside `_process_healing` (day-scale), never mid-battle — preserve that.

1. **Clean → localized**: per-day dose = `wound_infection_daily_risk(injury, treated)` × contamination (`WOUND_INFECTION_CONTAMINATED_MULT` if `is_contaminated`) × susceptibility (nutrition, fatigue, concussion), capped at `INFECTION_DAILY_DOSE_CAP`. At ≥1 → `stage=1`, `is_infected=true`, and **extend resolution duration**: `healing_duration_seconds *= INFECTION_HEAL_DURATION_MULT` (one-way; recompute from stored pre-infection base on clear — §10.4).
2. **Localized → septic**: while `stage==1` and the part is untreated, `sepsis_progress += per_day * SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY * (is_gas_gangrene ? GAS_GANGRENE_PROGRESS_MULT : 1.0)`; at ≥1 → `stage=2` **and set the entity `is_septic = true`** (the systemic state). If the wound is gangrene-eligible (§10.1), set `is_gas_gangrene=true` at transition.
3. **Sepsis death / recovery (entity-level, §11.3)**: while `is_septic`: roll death at `SEPSIS_DEATH_RISK_SOURCE_CONTROLLED` (0.12) if source-controlled else `SEPSIS_DEATH_RISK_PER_DAY` (0.35; use `GAS_GANGRENE_DEATH_RISK_PER_DAY` if the focus is gangrene) → on hit set `_sepsis_dead`, clamp `blood_volume`, call `emit_death_once`, `_get_death_reason()` → `"sepsis"`. If source-controlled, `sepsis_resolve_progress += per_day * SEPSIS_RESOLVE_PER_DAY_TREATED`; at ≥1 → `is_septic = false` (recovered). This is keyed to the **entity** `is_septic`, not to a single wound, so healing a septic wound cannot silently stop the sepsis (fixes the §1 loophole).
4. **Heal speed & duration**: infected → `WOUND_INFECTION_HEAL_SPEED_MULT` (0.5); septic → `SEPSIS_HEAL_SPEED_MULT` (0.25); osteomyelitic bone → `OSTEOMYELITIS_BONE_HEAL_MULT` (0.50) applied to bone-heal track. Track (a) resolution duration already extended at infection (§10.4).
5. **Tetanus channel (§10.2)**: for tetanus-candidate wounds, decrement `tetanus_incubation_days -= per_day`; at ≤0 roll `TETANUS_ONSET_RISK` → apply systemic rigidity affliction (perception ×`TETANUS_PERCEPTION_MULT`, per-day death ×`TETANUS_DEATH_RISK_PER_DAY`). Resolved only by day-scale passage (wound care does not abort once germinated).
6. **Stash resolved wounds** into `resolved_wounds_this_advance` (part, severity, type, was_infected, had_ischemia, `is_osteomyelitis`, was_septic) for the world scar layer (Part 2).

### 1.4 Sepsis systemic effects (`core/CoreEntity.gd`)

Sepsis is a **playable systemic state**, not just a death roll. All gated on the **entity** `is_septic` (set when any wound is `stage==2`, cleared only on recovery/death — see §11):

- **Stamina cap ×`SEPSIS_STAMINA_MULT` (0.70)** — add `_get_sepsis_stamina_mult()`, fold into `_get_campaign_stamina_mult()` (`CoreEntity.gd:723`). `CombatManager.gd:184-185` already reads it at battle start.
- **Perception ×`SEPSIS_COMBAT_PERCEPTION_MULT` (0.80)** — septic confusion; applied at battle start via `EntityPainConsciousness`, cleared when sepsis resolves.
- **Stamina drain ×`SEPSIS_COMBAT_STAMINA_DRAIN_MULT` (1.30)** — tachycardia/shock; fold into stamina-cost path.
- **Stage 1 stays low-stakes**: heal 0.5× + `INFECTION_LOCALIZED_PAIN_MULT` (1.10) + an "infected" UI marker. No systemic combat penalties until `stage==2`.

### 1.5 Treatment & source control (`core/EntityMedical.gd`)

- **Stage 1 (localized)**: a definitive dressing clears it with probability `INFECTION_DRESSING_CLEAR_STAGE1` (**0.40**, INT-scaled up, **repeatable** per day so sustained care climbs toward the 20–35% residual — §9.2). On failure, reset `infection_progress` to 0.5 and log via `CombatDebug` / `log_medical_session`. On a **clear**, recompute the wound's resolution duration from its stored pre-infection base so a cured wound does not stay artificially prolonged (§10.4).
- **Stage 2 (septic) — source control (§10.5)**: a dressing no longer clears it. `SEPSIS_RESOLVE_PER_DAY_TREATED` accrues **only** while the septic part has definitive hemostasis **or** is a stump (reuses `get_stump_bleeding_rate`/stump path + `part_has_definitive_hemostasis`); otherwise the resolution rate is 0 and only the death roll advances. **Amputation is the last-resort lever**: amputating the septic part clears its stage 2 and stops its death roll (source removed). This makes "get it before it goes systemic" the core decision.

---

## Part 2 — Wound-Derived Scars (per-part)

### 2.1 Minting trigger

Scars are minted **when a wound resolves** (right at `EntityHealing.gd:24` where `list.remove_at(i)` happens), not at battle end. Rationale: scars form *during* healing (remodeling phase), so "what this wound left behind" is the realistic trigger. The resolved-wound descriptors are stashed by `EntityHealing` (`resolved_wounds_this_advance`) and minted by the **world layer** to keep the core↔world boundary clean.

This **coexists with** the existing `CampaignAfflictions.apply_after_victory` roll (aggregate-state, `AFFLICTIONS_ENABLED` gate): the RNG roll remains the "you almost died" scar (low blood, untreated arterials, worst bone, unconscious), and the new mint adds the "this specific wound left this mark" scars. Both use the same `campaign_afflictions` array + `_add_campaign_affliction` (id-deduped, `CoreEntity.gd:790`).

### 2.2 Catalog — authoritative (`world/CampaignAfflictions.gd`), each carries `part` + effect fields

Universal multipliers below are the **per-scar floor**; **part-aware extra effects** are additive on top (§2.4). Values are the single source of truth (the §9.2 correction to `post_sepsis_weakness` is applied here).

| id | Label | `stamina_mult` | `pain_mult` | `damage_mult` | `bleed_mult` | `heal_mult` | Phase | Research anchor |
|---|---|---|---|---|---|---|---|---|
| `scarred_tissue` | Scarred {part} | 1.0 | 1.03 | 1.10 | 1.05 | 0.85 | A | Scar tissue is hypovascular, less elastic, ~70–80% of normal tensile strength at 1 yr (remodeling phase) → re-injures + bleeds a touch easier, heals slower. |
| `malunited_bone` | Malunited {part} | 0.95 | 1.05 | 1.15 | 1.0 | 0.85 | A | 5–15% of fractures malunion without reduction/fixation; a healed-but-misaligned limb takes more damage + heals slower. |
| `ischemic_contracture` | Contracted {part} (Volkmann) | 0.82 | 1.0 | 1.15 | 1.0 | 0.80 | A | Volkmann ischemic contracture: missed compartment syndrome / tourniquet ischemia → permanent flexion contracture (**arm-only**, §9.1). Tied to `EntityMedical.apply_tourniquet_ischemia_damage`. |
| `post_sepsis_weakness` | Post-sepsis weakness | **0.80** | 1.05 | 1.0 | 1.0 | 0.90 | A | **Corrected from 0.85** (§9.2). Post-sepsis / ICU-acquired weakness: 68–100% develop it, ~half recover fully → the *survivors who don't* carry a lasting deficit. Whole-body (diffuse/symmetric, no `part`). |
| `osteomyelitic_bone` | Infected bone {part} | 1.0 | 1.05 | 1.10 | 1.0 | 0.75 | A+ | Chronic osteomyelitis leaves a sequestered bone defect that heals markedly slower (worst `heal_mult` in catalog). Mints when an infected compound fracture resolves (§10.3). |
| `amputated_limb` | Amputated {part} | 0.85 | **1.06** | 1.0 | 1.0 | 1.0 | B+ | Chronic systemic cost of being an amputee (severance blood-loss residue + altered gait / one-handed bracing). The severed part already reads ~0 in combat, so the levers are the whole-body `stamina_mult` and a modest whole-body `pain_mult` for phantom limb pain — persistent phantom sensation/pain follows ~50–80% of amputations (Bosmans et al. 2010 systematic review), worse with a rough medieval stump. damage/bleed/heal stay neutral (a severed part takes no weapon damage; its stump is handled by the stump path). A modest chronic gait/grip adaptation penalty rides on top for robustness. Mints idempotently while a limb stays severed and supersedes the part's prior per-part scars/afflictions (§2.3). |

**Re-injury:** `SCAR_REINJURY_MULT` (`1.15`, `BleedingConstants` home) — a wound landing on an already-scarred part starts one severity band higher / +15% severity score; read in `EntityWounds.severity_from_damage` (§9.3).
**Severance ease:** `SCAR_SEVERANCE_EASE_BONUS` (`0.10`) — a part carrying any wound-derived scar severs more easily (scar tissue shears at ~70–80% tensile strength, same anchor as re-injury); one additive term in `EntityDamage.get_severance_ease_factor`, capped by `SEVERANCE_EASE_MAX`. A severed part never reaches this (it returns early), so its `amputated_limb` scar does not self-feed.
**Stacking (§9.6 Q1 lean: yes):** keep id-dedup for the RNG-roll entries; for wound-derived scars, id-merge on `id+part` — a second severe wound on a scarred part *deepens* it (multiply the existing `damage_mult` by ~`1.05` and the `heal_mult` by ~`0.95` — a deepened scar also heals worse, inverse direction) instead of no-op-ing.

### 2.3 Mint rules (`CampaignAfflictions.mint_from_resolved_wounds(world, rng)`)

For each resolved wound descriptor (part, severity, type, was_infected, had_ischemia, `is_osteomyelitis`, was_septic):

- compound fracture resolved → `malunited_bone` (deterministic on the descriptor — no roll)
- `is_osteomyelitis` (infected compound fracture that resolved) → `osteomyelitic_bone` (takes precedence over `malunited_bone`; §10.3)
- tourniquet ischemia occurred on an **arm** → `ischemic_contracture` (arm-only, §9.1)
- was infected on resolution → `scarred_tissue` — only for **open soft-tissue wounds** (compound fracture, cut, stab, crush, internal bleed; legacy descriptors missing `injury_type` keep the old rule). A **closed** injury never mints it: a contusion (bruise) resorbs wholly and a clean (non-compound) fracture heals with internal bone callus — its malunion/osteo mints are keyed on the exposed-bone `is_compound_fracture` flag, so nothing else to mint. Gated on `injury_type`, not on severity.
- severity severe/critical (clean) → `scarred_tissue` (deterministic — same mint as the infected case above; no lower-roll threshold), same open-wound `injury_type` gate — a severe bruise or a clean severe fracture does not remodel into soft-tissue scar.
- entity was `is_septic` and is now recovered (not `_sepsis_dead`) → `post_sepsis_weakness` (whole-body). Keyed to the entity-level sepsis state (§11), not to an individual wound.
- a **limb is severed** (`BodyPartQuery.is_part_severed`, `body_cutting=0` + `bone_health=0`) → `amputated_limb` for that part. State-based and idempotent per part (not tied to a resolved wound), so it mints on the first advance after a severance and never re-mints; the chronic gait/grip penalty is a modest residual on top of the acute destroyed-part state. A resolved-wound descriptor on a **severed** part is skipped in the per-wound loop (no `scarred_tissue` / `malunited_bone` / `osteomyelitic_bone` for a part that no longer bears damage), **and minting the amputation prunes any earlier same-part scars / bone afflictions** — the limb is gone, their multipliers are moot (the severed part reads ~0) and their labels would double-list beside "Amputated {part}". Whole-body afflictions (part "") are untouched. `amputated_limb` is thus the sole chronic record for that part.

- **Closure on a scarred part is slower (§9.3 interplay):** `EntityWounds.add_wound` scales a **new** wound's resolution duration by `1 / _get_scar_heal_mult(part)` when the part already carries a wound-derived scar (hypovascular scar tissue lengthens the remodeling phase — the same anchor as `SCAR_REINJURY_MULT`; a 0.85 heal ≈ ×1.18 closure time, the deepest deepen 0.1 → ×10). Separated from the tissue-cure heal slowdown (track-b) and applied at wound *creation*, so re-injuring a scarred limb both lands a severity band higher *and* stays in the hospital longer. Pinned by `_run_scarred_part_wound_resolves_slower`. A severed part keeps the canonical duration (its amputation scar prunes the part's scars).

Mint via the existing `entity._add_campaign_affliction(def)` (`CoreEntity.gd:790`) + `_get_company_state().adjust_member_mood(...)` — reusing the proven `apply_after_victory` path (`CampaignAfflictions.gd:57-60`). **Dedup/merge (§9.6 Q1 lean: yes):** keep id-dedup for the RNG-roll entries; for wound-derived scars, id-merge on `id+part` — a second severe wound on a scarred part *deepens* it (multiply the existing `damage_mult` by ~`1.05` and the `heal_mult` by ~`0.95`, so a deepened scar heals worse) instead of no-op-ing.

### 2.4 Part effects (make the stored `part` actually matter)

Add three accessors in `core/CoreEntity.gd` that scan `campaign_afflictions` for entries whose `part` matches:

- `_get_scar_damage_mult(part)` → product of matching `damage_mult`
- `_get_scar_bleed_mult(part)` → product of matching `bleed_mult`
- `_get_scar_heal_mult(part)` → product of matching `heal_mult`

Then read them in:

- `core/EntityDamage.gd` — multiply the scarred part's incoming damage by `_get_scar_damage_mult(part)` before pool allocation.
- `core/EntityWounds.gd` — `get_bleeding_rate_for_part` × `_get_scar_bleed_mult(part)`.
- `core/EntityHealing.gd` — tissue/bone `tau` for the part ÷ `_get_scar_heal_mult(part)` (slower heal).

This closes the gap where `part` was stored but never read by any damage/bleed/heal query.

**Additive part-specific penalties (§9.5).** Beyond the universal multipliers, a scarred part carries a tissue/location-specific penalty (scars "form differently based on … the location … and severity"). Extend the accessors (or add `_get_scar_part_penalty(part) -> Dictionary`) to emit, read at the existing part-functionality seams:

| Scarred part | Extra effect | Read seam |
|---|---|---|
| leg/foot | reduced move speed + higher move stamina cost | `BodyPartQuery.get_leg_functionality` |
| arm/hand | reduced grip / weapon handling (damage dealt −) | `BodyPartQuery.get_arm_tissue_factor` |
| head | small chronic perception penalty | `EntityPainConsciousness` perception path |
| chest | reduced stamina pool (cardiopulmonary) | existing `partly_collapsed_lung` intent |

Keep the universal `damage_mult`/`bleed_mult`/`heal_mult` as the floor; part effects are additive on top.

---

## 3. Feature registry (proposed §9c rows)

Two rows, one per phase, added with each implementation PR per [`SHIP_PLAN §9c`](SHIP_PLAN.md#combat-expand-registry). Both are **Campaign-owned** (heal/scar time-advance + afflictions) with Core reads; gate via `CompanyState.read_stub_*`.

| ID | Status | Intent |
|----|--------|--------|
| CAMP-INF-1 | **Proposed** — staged infection (localized→septic) + systemic sepsis (stamina drain + death path) + susceptibility (nutrition/fatigue/concussion) + probabilistic stage-1 dressing clear. Gate `read_stub_infection_staging_enabled`. |
| CAMP-SCAR-1 | **Proposed** — wound-derived scars minted on wound resolution; new catalog entries (`scarred_tissue`/`malunited_bone`/`ischemic_contracture`/`post_sepsis_weakness`); per-part `damage_mult`/`bleed_mult`/`heal_mult` read in `EntityDamage`/`EntityWounds`/`EntityHealing`. Gate `read_stub_wound_scars_enabled` (coexists with `AFFLICTIONS_ENABLED`). |

Requires: harness tails (new `harness/infection/` + `harness/scar/`), `PHASE0: PASS`, no `world/*` edits without Campaign coordination.

### New gate constants (`world/CompanyState.gd`)

Per [`SHIP_PLAN §19`](SHIP_PLAN.md#implementation-gate-constants): const + reader + decision-log line.

```gdscript
const INFECTION_STAGING_ENABLED := true
const WOUND_SCARS_ENABLED := true
```

Readers: `read_stub_infection_staging_enabled()`, `read_stub_wound_scars_enabled()`. The existing `AFFLICTIONS_ENABLED := true` / `read_stub_afflictions_enabled()` (`CompanyState.gd:50,133`) continues to gate the aggregate post-victory roll and `count_scarred_brothers`.

---

## 4. File ownership

| Change | Owner |
|--------|-------|
| `core/BleedingConstants.gd` (staging + sepsis + susceptibility + scar constants; `sepsis_progression_per_day` + susceptibility helper) | Core |
| `core/EntityHealing.gd` (staged progression, sepsis death roll, septic heal-slow, stash `resolved_wounds_this_advance`, apply `heal_mult`) | Core |
| `core/EntityMedical.gd` (probabilistic stage-1 clear, treated+fed stage-2 resolution, INT scaling) | Core |
| `core/CoreEntity.gd` (`_sepsis_dead`, `resolved_wounds_this_advance`, `_get_sepsis_stamina_mult`, `_get_death_reason` → "sepsis", three `_get_scar_*_mult(part)` accessors) | Core |
| `core/EntityDamage.gd` (apply `_get_scar_damage_mult(part)`) | Core |
| `core/EntityWounds.gd` (apply `_get_scar_bleed_mult(part)` in `get_bleeding_rate_for_part`) | Core |
| `world/CampaignAfflictions.gd` (4 new catalog entries + `mint_from_resolved_wounds(world, rng)` + post-sepsis trigger) | Campaign |
| `world/CampaignEncounterBridge.gd` + `world/CompanyCamp.gd` (call `mint_from_resolved_wounds` after `_process_healing`, then clear `resolved_wounds_this_advance`) | Campaign (Shared) |
| `world/CompanyState.gd` (two new gate constants + readers) | Campaign |
| `harness/infection/` (new), `harness/scar/` (new) | Harness |

Session budget: ≤1 doc section + ≤3 owning `.gd` per edit pass — implementation is phased (§5).

---

## 5. Implementation order

- **Phase A — Infection / sepsis (files: BleedingConstants, EntityHealing, EntityMedical, CoreEntity):**
  - A0 — registry + doc: add §9c row `CAMP-INF-1`, `INFECTION_STAGING_ENABLED` + reader, `infection_stage` / `sepsis_progress` **and entity-level `is_septic` / `sepsis_resolve_progress` / `_sepsis_dead`** data keys, harness tail skeleton. Gate `PHASE0: PASS`.
  - A1 — staged progression + susceptibility + **entity-level sepsis (§11)**: clean→localized (×susceptibility, capped `INFECTION_DAILY_DOSE_CAP`), localized→septic sets `is_septic`, entity-keyed death roll (`SEPSIS_DEATH_RISK_PER_DAY` vs `SEPSIS_DEATH_RISK_SOURCE_CONTROLLED` when source-controlled), `is_dead()` fold + `_get_death_reason()` → "sepsis", septic heal-slow + track-(a) duration extension. Harness: progression, susceptibility, death reason, `is_dead()`, heal-speed/duration.
  - A2 — treatment + **source control**: probabilistic stage-1 clear (INT-scaled, repeatable), source-controlled `sepsis_resolve_progress` accrual (definitive hemostasis / stump / amputation → focus removed), amputation cures the septic focus. Harness: clear/fail, source-control gate, resolve→recovered.
  - A3 — playable septic state: `SEPSIS_STAMINA_MULT` cap + `SEPSIS_COMBAT_PERCEPTION_MULT` + `SEPSIS_COMBAT_STAMINA_DRAIN_MULT` gated on `is_septic`; `INFECTION_LOCALIZED_PAIN_MULT` on stage-1 parts. Harness: next-battle weakened, no UI change needed.
- **Phase B — Wound-derived scars + per-part effects (files: CoreEntity scar accessors, CampaignAfflictions, CampaignEncounterBridge, CompanyCamp, EntityDamage, EntityWounds, CompanyState):**
  - B0 — registry + doc: add §9c row `CAMP-SCAR-1`, `WOUND_SCARS_ENABLED` + reader, 4 catalog entries, `resolved_wounds_this_advance` stash, harness tail skeleton. Gate `PHASE0: PASS`.
  - B1 — minting: `mint_from_resolved_wounds`, world calls it after `_process_healing`, clear stash. Harness: mint rules, id-dedup, mood.
  - B2 — per-part effects: `_get_scar_*_mult(part)` accessors + read in `EntityDamage`/`EntityWounds`/`EntityHealing`. Harness: damage/bleed/heal multipliers per scarred part.

Each phase is a shippable unit (flag can ship independently). Phase B depends on Phase A's `resolved_wounds_this_advance` stash + the entity-level `is_septic`/`_sepsis_dead` state for the `post_sepsis_weakness` trigger (§2.3, §11).

---

## 6. Success criteria

- An untreated severe wound on a starving, fatigued, concussed member infects faster than the same wound on a healthy, fed one (susceptibility multipliers observable in soak).
- A localized infection left alone progresses to septic and can kill (`_get_death_reason()` == "sepsis"); a septic member's next-battle stamina cap is reduced by `SEPSIS_STAMINA_MULT`.
- A clean definitive dressing clears a stage-1 infection with probability ~`INFECTION_DRESSING_CLEAR_STAGE1` (INT-scaled); stage 2 is not dressing-clearable.
- Resolving a compound fracture / ischemic / infected / severe wound mints the matching scar (id-deduped, mood −1.35); the existing aggregate post-victory roll still works.
- A scarred part takes `damage_mult` more damage, bleeds at `bleed_mult`, and heals at `heal_mult` (observable via `EntityDamage`/`EntityWounds`/`EntityHealing`).
- No new `FEATURE_*` without a harness; all constants research-backed (§1.2, §2.2, [`wound_infection_data.md`](wound_infection_data.md)).
- `PHASE0: PASS`; no regression in existing infection (single-stage), affliction, or healing tails.

---

## 7. Risks / mitigations

| Risk | Mitigation |
|------|-----------|
| Sepsis makes untreated wounds too lethal (feel unfair) | `SEPSIS_DEATH_RISK_PER_DAY = 0.35` is a *per-day* roll only while septic; stage 1→2 takes ~2.5 days, so there's a clear multi-day treatment window. Tuning knob, research-backed. |
| Susceptibility multipliers stack to extreme infection rates | Each is ≤1.5 and multiplies a *per-day dose* (not a one-shot chance); cap effective daily dose at a max (e.g. 0.9) so a single day can't instantly infect regardless of state. |
| Wound-derived scars + RNG roll double-scar the same part | `_add_campaign_affliction` id-dedupes; a part gets one `scarred_tissue` even if two wounds on it resolve. Severity stacking is a separate follow-up (see §8 open question). |
| Core↔world boundary bleed (scars minted in world but state stashed in core) | `resolved_wounds_this_advance` is a transient, clearly-named field consumed by exactly one world call; cleared after minting. Mirrors the existing `apply_after_victory` world-reads-core-state pattern. |
| Ownership overlap on `CoreEntity` (Core) + `CampaignAfflictions` (Campaign) | Core owns the entity state + scar accessors; Campaign owns the catalog + minting. Shared file edits coordinated per [`PLANNING#file-ownership`](PLANNING.md#file-ownership). |
| Gate drift (two new gates + existing `AFFLICTIONS_ENABLED`) | Both new gates default `true` (shipped per §9c precedent), mirroring `AFFLICTIONS_ENABLED`; harness gates off by toggling the stub reader (pattern: `read_stub_proficiency_enabled`). |

---

## 8. Open questions (resolve before Phase B2)

1. **Scar severity stacking.** Currently id-deduped (one entry per id). Should a *second* severe wound on the same part deepen the existing scar (worse `damage_mult`) rather than no-op? If so, change `_add_campaign_affliction` from id-dedup to id-merge for wound-derived scars (keep id-dedup for the RNG roll).
2. **Scar long-term recovery.** Scars are permanent. Should extended camp rest / proper care *reduce* (not clear) a scar's effect over time? This would need a per-scar `recovery_progress` advanced in `CompanyCamp`.
3. **Infection on the overworld map.** `MapFieldCare.gd` advances bleeding/blood-loss on the map but not healing/infection. Should infection progress on march days on the map (it currently only advances inside `_process_healing`, which is camp + campaign-bridge)? Realism says yes; scope says it's a follow-up.
4. **Sepsis in combat.** Sepsis death currently rolls on day-advance. A septic member who enters a battle — should the sepsis death path also arm during combat (like vital-part destruction grace)? Currently combat death is blood/vital-only.

---

## 9. Research findings & refinements (2026-09-21)

Sources verified against live search this date. This section **confirms the §1–§8 design, corrects three weakly-anchored constants, and fleshes out two under-specified mechanics** (sepsis as a playable systemic state; part-aware scar effects). **The corrected/new values are consolidated into the §1.2 and §2.2 master tables, which are the single source of truth; what follows here is the research provenance and rationale only.**

### 9.1 What the research confirms

- **Staging timeline is right.** Sepsis "usual onset … prolonged (several days)" and SIRS→sepsis progression over ~24–72 h (*Wikipedia:Sepsis*). `SEPSIS_LOCALIZED_TO_SEPTIC_PER_DAY = 0.40` (≈2.5 days localized→septic) sits in the correct window — not hours (which would make it unavoidable), not weeks (too forgiving).
- **Mortality anchor is right.** Pre-antibiotic severe-sepsis/shock mortality 70–90% / ~80%; modern ~30/50/80 (*Wikipedia:Sepsis* Prognosis; `wound_infection_data.md` §1). `SEPSIS_DEATH_RISK_PER_DAY = 0.35` → ~50% survival over 2 untreated days. Matches "near-fatal but not instant."
- **Susceptibility factors are real & independent.** *Wikipedia:Critical illness polyneuropathy* §Epidemiology names **low serum albumin** (malnutrition) and **immobility** as independent CIP/CIM risk factors; *Wikipedia:Sepsis* names **major trauma** as a sepsis risk factor. These map 1:1 onto the existing `nutrition_level`, `campaign_fatigue`, and concussion state — validating the three susceptibility multipliers as a *different*, well-grounded input than the existing severity/arterial/compound base risk.
- **Wound-derived scarring timing is right.** Adult wounds heal by repair, not regeneration; scarring is the *maturation/remodeling* outcome and "an injury does not become a scar until the wound has completely healed" — a process taking **weeks to months** (*Wikipedia:Scar* Pathophysiology; *Wikipedia:Wound healing* Maturation). The game's heal durations (severe ≈3 wk, critical ≈6 wk) overlap the documented **4–8 week hypertrophic-scar window** (*Wikipedia:Scar* — "occur within 4 to 8 weeks following wound closure"). Minting a scar *at wound resolution* therefore models the scar actually forming as the wound closes.
- **Volkmann's is the strongest single scar anchor.** *Wikipedia:Volkmann's contracture*: acute ischemia → flexor-muscle necrosis → "the muscles become fibrotic and shortened" → **permanent** flexion contracture; caused by "improper use of a tourniquet … or compartment syndrome." This is *exactly* the existing `apply_tourniquet_ischemia_damage` path, and it confirms (a) the cause, (b) permanence, (c) that it is a **forearm/hand** (arm-only) effect — so `ischemic_contracture` should be gated to arm parts.

### 9.2 Constant corrections

| Constant | Before | After | Why (research) |
|---|---|---|---|
| `SEPSIS_STAMINA_MULT` | `0.65` | **`0.70`** | 0.65 under-anchored: 35% stamina loss implies near-paralysis. CIP/CIM is diffuse flaccid weakness where "**about half of patients recover fully**" over weeks–months (*Wikipedia:Critical illness polyneuropathy* Prognosis) — i.e. a *significant but survivable* deficit, not collapse. 30% loss (0.70) is the defensible midpoint; keep 0.65 only if playtest says sepsis should feel more debilitating. |
| `INFECTION_DRESSING_CLEAR_STAGE1` | `0.65` | **`0.40`** | 0.65 was optimistic. `wound_infection_data.md` §6: even **"good care" (honey + wine + clean dressings, rest) only cuts infection 60–80% → 20–35%**. A *single* dressing attempt is weaker than sustained "good care," so the per-attempt clear rate must be below the sustained-care benefit. 0.40 per attempt, INT-scaled upward, and **repeatable** (re-dress each day) → cumulative "good care" climbs toward the 20–35% residual. This also makes the §1.5 "failure → reset progress to 0.5 + retry" loop meaningful. |
| `post_sepsis_weakness.stamina_mult` | `0.85` | **`0.80`** (permanent) | CIP/CIM: "**68–100%**" of sepsis/SIRS patients develop neuromuscular weakness, ~half recover fully (*Wikipedia:Critical illness polyneuropathy*). "Half recover fully" → the *survivors who don't* carry a lasting deficit. A 20% permanent stamina floor for a sepsis survivor is consistent with "didn't fully recover." Whole-body (no `part`), matching the documented **diffuse, symmetric** presentation. |

All other §1.2 / §2.2 values hold.

### 9.3 New constants (values now in §1.2)

Each constant below is consolidated into the §1.2 master table; this shows the research rationale for each.

| Constant | Value | Research anchor |
|---|---|---|
| `SEPSIS_COMBAT_PERCEPTION_MULT` | `0.80` | Septic **confusion** is a core symptom (*Wikipedia:Sepsis* Signs: "confusion," "altered mental status" from CNS damage). Model sepsis as a *playable* systemic state: a septic member thinks slower — fold into the existing perception/pain pipeline (`EntityPainConsciousness`) at battle start, cleared when sepsis resolves. 20% perception drop. |
| `SEPSIS_COMBAT_STAMINA_DRAIN_MULT` | `1.30` | Sepsis = distributive shock + catabolism; a septic member burns stamina faster in combat (tachycardia, low perfusion). 30% higher stamina drain per action while `stage==2`. |
| `INFECTION_LOCALIZED_PAIN_MULT` | `1.10` | Localized infection (stage 1) is painful (cellulitis: warmth, swelling, pain — *Wikipedia:Scar* / wound-infection). Modest +10% pain on the affected part while stage 1, via the existing per-part pain contribution. |
| `INFECTION_DAILY_DOSE_CAP` | `0.90` | Promotes the §7 risk mitigation to a real constant: after all multipliers, cap the per-day infection dose at 0.9 so even a worst-case stack (starving + fatigued + concussed + critical wound) needs ~2 days to infect, never 1. Keeps the treatment window open. |
| `SCAR_REINJURY_MULT` | `1.15` | "Scars … tend to **shear easier** than normal tissue" via lost rete pegs; **mechanical stress stimulates scarring** (*Wikipedia:Scar* Mechanical stress, 2011/2021). A fresh/old scar is more vulnerable to re-injury: a wound landing on an already-scarred part starts one severity band higher (or +15% severity score). Read in `EntityWounds.severity_from_damage`. |

### 9.4 Fleshing out sepsis as a playable state (not just a death roll)

Current design: sepsis = stamina cap ×0.65 + per-day death roll. That's realistic but **invisible in combat** — a member just "dies from sepsis" with no on-field tell. Real sepsis has systemic, observable symptoms. Add, all gated on any wound `stage==2`:

- **Perception ×`SEPSIS_COMBAT_PERCEPTION_MULT`** (confusion) — via `EntityPainConsciousness`, applied at battle start like the existing concussion `healing_mult`/perception path.
- **Stamina drain ×`SEPSIS_COMBAT_STAMINA_DRAIN_MULT`** (tachycardia/shock) — fold into the stamina-cost path.
- **Death roll only on day-advance** (see open Q4) — combat keeps the existing blood/vital-only death model for now; the septic state's *combat* cost is the perception + drain above, not an in-battle death.
- **Stage 1** stays low-stakes (heal 0.5× + `INFECTION_LOCALIZED_PAIN_MULT` + a UI "infected" marker) so the player has a clear, recoverable window before systemic effects bite. This preserves the "get it before it goes septic" decision the design centers on.

### 9.5 Fleshing out scars: part-aware effects

Current design: flat `damage_mult`/`bleed_mult`/`heal_mult` per scar. Real scarring is **part- and tissue-specific** ("scars form differently based on … the location of the injury … and the severity" — *Wikipedia:Scar*). The existing catalog already labels scars by part (`Limping leg`, `Shaky grip`, `Cracked ribs`), so make the *effects* part-aware too, alongside (not replacing) the flat multipliers:

| Scarred part | Extra effect | Research anchor |
|---|---|---|
| leg/foot | reduced move speed + higher move stamina cost | Malunion: "trouble placing weight … on the malunion" (*Wikipedia:Malunion*); a misaligned or contracted leg can't drive. Read in the existing leg-functionality path (`BodyPartQuery.get_leg_functionality`). |
| arm/hand | reduced grip / weapon handling (damage dealt on that arm −) + `SCAR_REINJURY_MULT` | Scar loss of elasticity + shear (*Wikipedia:Scar*); Volkmann's is specifically a **hand/forearm** flexion contracture (*Wikipedia:Volkmann's contracture*). Read in the arm-functionality path (`BodyPartQuery.get_arm_tissue_factor`). |
| head | reduced perception (chronic) | Concussion/TBI already models acute head effects; a *scarred* head is the chronic residue — small permanent perception penalty. |
| chest | reduced stamina pool (cardiopulmonary) | A partially-collapsed lung / scarred thorax limits sustained output — matches existing `partly_collapsed_lung` intent. |

Implementation: the three `_get_scar_*_mult(part)` accessors (§2.4) already isolate part-scoped lookups; extend them (or add `_get_scar_part_penalty(part) -> Dictionary`) to emit the part-specific penalty, read at the existing part-functionality seams (`BodyPartQuery`, `EntityPainConsciousness`). Keep the flat `damage_mult`/`bleed_mult`/`heal_mult` as the universal floor; part effects are additive on top.

### 9.6 Refined open questions

1. **Scar severity stacking** (open Q1) — *lean: yes, id-merge for wound-derived scars.* A second severe wound on an already-scarred part should deepen it (worse `damage_mult`). Research: repeated mechanical stress on scarred tissue worsens it (*Wikipedia:Scar*). Implement as "if id+part already present, multiply the existing `damage_mult` by a `SCAR_STACK_MULT ≈ 1.05`" rather than a fresh entry; keep the RNG-roll entries id-deduped.
2. **Scar long-term recovery** (open Q2) — *lean: no, scars are permanent.* "A scar … takes many months, or years" to fully mature, and remodeling **improves** scar quality but does not erase it (*Wikipedia:Scar*). A small cosmetic reduction is plausible; a gameplay recovery is not. Drop the `recovery_progress` idea.
3. **Infection on the overworld map** (open Q3) — *lean: yes, advance it.* March days are day-scale just like camp rest; untreated wounds should fester while marching. Route map-day-advance through the same infection block of `_process_healing` (or a shared helper) so marching a wounded company is a real risk. Low added cost once the infection block is factored out.
4. **Sepsis in combat** (open Q4) — *resolve: keep day-advance-only for now.* Combat already has two death models (blood + vital); adding a third (sepsis) mid-battle muddies the death-reason UI and the `CombatTuningMain` cause-token mapping (`_get_death_reason` → token). The §9.4 perception/drain effects give sepsis an in-combat *presence* without a new death path. Revisit only if playtest shows septic members surviving absurdly long battles.

---

## 10. Research pass 2 — realism depth (2026-09-21)

Second, deeper pass. Scope discipline up front: the base system (Part 1 / Part 2) ships first; this section adds **bounded, research-anchored refinements**, each tagged **in-scope (Phase A)** / **near-term (Phase A+)** / **deferred**. Nothing here changes the Phase A file set (§4) — it only sharpens constants and adds wound-dict fields on seams that already exist. **All §10 constant values are consolidated into the §1.2 (infection) master table, the single source of truth; the value tables below are research rationale only.**

### 10.0 Verified code seams (corrections to assumptions)

- **Healing is two independent tracks.** (a) **Wound resolution** — a pure wall-clock-age function: `_get_wound_healing_progress = 1 - exp(-age/tau)`, `tau = healing_duration_seconds / EXPONENTIAL_HEAL_TAU_DIVISOR` (`EntityWounds.gd:25`); the wound is removed when this ≥ `WOUND_RESOLVED_THRESHOLD` (`EntityHealing.gd:23`). (b) **Tissue/bone recovery** — a `heal_speed` multiplier applied to the damage-deficit decay (`EntityHealing.gd:104-120`, already multiplied by endurance, concussion `healing_mult`, nutrition). **The existing infection only slows track (b); it never extends track (a).** So "infection extends healing duration" is a real, currently-missing lever (§10.4) — and it is the track that gates scar minting (Part 2 mints on track (a) resolution).
- **Wound creation seam.** `EntityWounds.add_wound` (`EntityWounds.gd:184`) already accepts `extra_flags: Dictionary` and an `injury_type`/`penetration_to_tissue_mm`; the wound dict is built at `EntityWounds.gd:234-247`. Contamination, gangrene, and tetanus candidacy all ride on `extra_flags` → stored on the wound dict. No signature change needed.
- **Compound-fracture cascade.** `_try_escalate_compound_fracture` (`EntityWounds.gd:256`) sets `INJURY_TYPE_COMPOUND_FRACTURE` + `is_compound_fracture` when ≥2 fractures land on one limb — this is the osteomyelitis route (§10.3) and already doubles the §556 infection base via `WOUND_INFECTION_COMPOUND_FRACTURE_MULT`.
- **Thermoregulation is doc-only.** Grep for `core_temp|thermoregul|body_temperature|heat_load` across `core/*.gd` returns **no hits**; only `docs/THERMOREGULATION_RESEARCH.md` exists. Sepsis fever is therefore a **deferred** host, not an in-Phase-A seam (§10.6).
- **Stump/amputation already modeled.** `get_stump_bleeding_rate` (`BleedingConstants.gd:824-827`) + stump constants (~:130) + traumatic amputation in `EntityDamage` (~:16-32) — the source-control lever (§10.5) reuses this.
- **Infection block.** `EntityHealing.gd:51-71` is the single campaign-day infection site (per-day dose, `is_infected` flip at ≥1.0). All staged/septic/gangrene/tetanus/osteomyelitis progression lands in or beside this block.

### 10.1 Gas gangrene / necrotizing variant — *near-term (Phase A+)*

Clostridial myonecrosis (*C. perfringens*, anaerobic) thrives in **deep, crushed, devitalized, low-perfusion** tissue; it is **faster and deadlier** than ordinary sepsis. Untreated it is ~100% fatal; even with debridement/amputation + antibiotics ~20–30% die (StatPearls); onset can be as fast as ~12 h vs the multi-day ordinary course. Model it as an **aggressive stage-2 variant**, not a new stage:

- Wound-dict flag `is_gas_gangrene: bool`. Set at the stage-1→2 transition **only** for gangrene-prone wounds: `INJURY_TYPE_CRUSH`, `INJURY_TYPE_COMPOUND_FRACTURE`, `INJURY_TYPE_STAB`/`CUT` with deep `penetration_to_tissue_mm`, a part currently in tourniquet-ischemia / low perfusion, **or a traumatic amputation stump** (`is_stump` — devitalized + open, the historical leading cause of amputation mortality) (a roll scaled by severity, not a certainty).
- While gangrene-flagged, `sepsis_progress` accrues at `GAS_GANGRENE_PROGRESS_MULT` × the ordinary rate and the daily death roll uses `GAS_GANGRENE_DEATH_RISK_PER_DAY` (higher than `SEPSIS_DEATH_RISK_PER_DAY`). Source control (§10.5) is *more* decisive here — debridement/amputation is the historical treatment.

| Constant | Value | Anchor |
|---|---|---|
| `GAS_GANGRENE_PROGRESS_MULT` | `2.0` | Faster-than-ordinary progression (onset can begin ~12 h vs days). |
| `GAS_GANGRENE_DEATH_RISK_PER_DAY` | `0.50` | StatPearls: **~100% fatal untreated**; 20–30% even with debridement/amputation + antibiotics. 0.50/day → ~75% dead by day 2. |
| `GAS_GANGRENE_CANDIDATE_BASE_RISK` | `0.50` | Fraction of qualifying stage-2 wounds that become gangrenous (severity-scaled up). |

### 10.2 Tetanus — delayed spore-borne channel — *near-term (Phase A+)*

*Clostridium tetani* is **spore-borne and toxin-mediated**, not a local wound infection: the spore enters a deep/puncture/contaminated wound, germinates, and releases tetanospasmin → **systemic** muscle rigidity/spasm. The wound can **fully heal** first, then the member manifests **3–21 days later** (avg ~8); shorter incubation = worse prognosis. Modern CFR is only ~6–10% *with* TIG + ventilation, so pre-antibiotic/untreated mortality is far higher. Because it is delayed and toxin (not focus)-driven, it is a **separate hazard channel**, distinct from the local→systemic wound-infection stages:

- Wound-dict field `tetanus_incubation_days: float` (−1 = not a candidate). Arm to a candidate on deep/puncture/contaminated wounds (cut/stab with high `penetration_to_tissue_mm` or `extra_flags.contaminated`), **including a traumatic amputation stump** (`is_wound_contaminated` treats a stump as always-contaminated — a raw devitalized stump is a classic tetanus entry). Draw the incubation once per wound in `[TETANUS_INCUBATION_MIN_DAYS, _MAX_DAYS]`.
- In the day-advance block, decrement `tetanus_incubation_days`; at ≤0, roll `TETANUS_ONSET_RISK`. On onset, apply a **systemic rigidity affliction** (whole-body, not `part`-scoped — consistent with §9.5's "diffuse/symmetric" note) carrying a per-day death roll `TETANUS_DEATH_RISK_PER_DAY` and a perception/mobility penalty, until resolved by day-scale care.
- **Wound care does not abort it once incubation starts** (unlike ordinary infection): a dressing treats the *wound*, not the already-germinated spore — the only resolution is the day-scale timer. This is the single biggest behavioural difference from the §1 infection and is worth an explicit harness assertion.
- **Counter-play (clean-at-arm):** at the moment the spore load is seeded, latch `tetanus_cleaned_at_arm` (entity field) from `part_has_definitive_hemostasis(part)`. A wound that was cleanly dressed / debrided at arm time rolls onset at `TETANUS_ONSET_RISK * TETANUS_ONSET_RISK_TREATED_MULT` (debridement removes spores before germination); an undressed wound rolls the full `TETANUS_ONSET_RISK`. The latch is one-way at arm time — a later dressing does not reach back to remove spores already seeded.

| Constant | Value | Anchor |
|---|---|---|
| `TETANUS_INCUBATION_MIN_DAYS` | `3.0` | Documented 3–21 day incubation (short end). |
| `TETANUS_INCUBATION_MAX_DAYS` | `21.0` | Documented long end. |
| `TETANUS_ONSET_RISK` | `0.30` | Base fraction of contaminated deep punctures that manifest (pre-antibiotic, no prophylaxis); a high-quality clean/debridement at the wound reduces it (removes spores before germination) — the player's counter-play. |
| `TETANUS_SYMPTOMATIC_DAYS` | `7.0` | In-game symptomatic spasm window (compresses the real multi-week course); bounds the per-day death roll. |
| `TETANUS_DEATH_RISK_PER_DAY` | `0.12` | Cumulative over the 7-day window = 1−(1−0.12)^7 ≈ 57% — a pre-antibiotic generalized-tetanus figure (modern CFR only ~6–10% with TIG+ventilation; untreated historical higher). |
| `TETANUS_PERCEPTION_MULT` | `0.85` | Tetanospasmin → rigidity/spasm impairs aim/handling; a playable systemic tell. |
| `TETANUS_ONSET_RISK_TREATED_MULT` | `0.50` | A wound cleanly dressed / debrided at the moment the spores were seeded (latched `tetanus_cleaned_at_arm`) germinates less often — debridement removes spores before germination; halves `TETANUS_ONSET_RISK`. |

### 10.3 Osteomyelitis — infected compound fracture → chronic bone — *near-term (Phase A+)*

Bone infection, prime pre-antibiotic route = **open/compound fracture** (exposed bone). If the exposed bone stays infected, healing turns **chronic**: prolonged, poor-quality, and it sequesters a nidus that sustains infection. Model as a wound-dict flag `is_osteomyelitis: bool`, set when an `is_compound_fracture` wound reaches stage ≥1 and is not cleared:

- While present: the part's **bone-heal** rate is cut by `OSTEOMYELITIS_BONE_HEAL_MULT` (chronic, slow bone closure) and the wound keeps contributing a small infection/sepsis dose (the sequestered focus) even at low stage.
- On resolution it **biases the scar mint** (Part 2) toward `malunited_bone` (raise its roll weight) or a new `osteomyelitic_bone` scar with a worse `heal_mult` than `malunited_bone`.

| Constant | Value | Anchor |
|---|---|---|
| `OSTEOMYELITIS_BONE_HEAL_MULT` | `0.50` | Chronic osteomyelitis markedly prolongs bone healing; halves effective bone-heal rate. |

### 10.4 Infection extends healing duration, not just slows it — *in-scope (Phase A)*

The single most important correction to the current model. Infection enzymatically destroys tissue, so the wound physically **stays open longer** — but the current system only slows track (b) (the `heal_speed` multiplier, `EntityHealing.gd:114-120`). Track (a) — the wall-clock **resolution** that both closes the wound *and* triggers scar minting (Part 2) — is untouched. Consequence today: an infected wound resolves (and mints its scar) on the same wall-clock schedule as a clean one, only with slower damage-deficit closure.

Fix: at the stage-0→1 flip, **lengthen the resolution duration** one-way: set `injury["healing_duration_seconds"] *= INFECTION_HEAL_DURATION_MULT`. Because resolution is age-based, this is done by *increasing the stored duration at the moment of infection* (never shortening; on a stage-1 dressing-clear, recompute via `EntityWounds.scaled_healing_duration_seconds(entity, part, severity, injury_type)` — part/severity/type are already stored on the wound, so no separate base field is needed — so a cured wound does not stay artificially prolonged). The recompute baseline is **CAMP-SCAR-1 scar-aware** (only seam for both `add_wound` and the clear): it includes the part's scar heal slow-down, so curing an infection on a scarred part restores the scar-scaled duration and never lets a cured scarred wound out-heal the identical never-infected scarred wound. Septic / gangrene parts get a further multiplier.

| Constant | Value | Anchor |
|---|---|---|
| `INFECTION_HEAL_DURATION_MULT` | `1.75` | Infected wounds close slower (enzymatic tissue destruction + delayed epithelialization); extends track (a) resolution ~75%. |
| `SEPSIS_HEAL_DURATION_MULT` | `1.50` | Stacked on top while stage 2 (septic tissue is devitalized; compounds the stage-1 extension). |

### 10.5 Sepsis source-control — must be treated or amputated — *in-scope (Phase A)*

Sepsis does not clear by "resting"; it needs **source control** — the infected focus controlled (definitive treatment) or the limb removed. Sharpen §1.5: `SEPSIS_RESOLVE_PER_DAY_TREATED` accrues **only** while the septic wound's part has definitive hemostasis **or** is a stump (reuse the `get_stump_bleeding_rate`/stump path). If the septic focus is still untreated, the resolution rate → `0` and only the death roll advances — making amputation the real last-resort lever. **Amputating the septic part cures that focus**: clear stage 2 on the part and stop its death roll (source removed). This reuses `EntityWounds.part_has_definitive_hemostasis` (`EntityHealing.gd:56`) + the stump constants — no new query.

**Deliberate field amputation (implemented).** A septic (stage-2) or gas-gangrene focus on a limb can now be amputated as an on-map field-care action, not only via emergent combat severance. `EntityMedical.amputate_part(entity, part, sub_region)` zeroes `body_cutting`/`bone_health` (and the `tissue_energy_remaining_j` pool when present) so `BodyPartQuery.is_part_severed` reads true, then calls `EntityWounds.ensure_stump_wound` to mint the single amputation-stump wound. `MapFieldCare` exposes `can_offer_field_amputate` / `try_field_amputate` / `format_field_amputate_button_label` (gated to a limb that still carries a stage-2 focus) and `PartyMenu` renders the button in `_build_field_care_buttons`. It is deterministic (a committed decision, no success roll) and carries no medical-supply cost — the permanent limb loss *is* the cost. It is not auto-chained into `try_treat_next_wound`; it is the player's explicit last resort. Post-amputation, `_all_septic_foci_source_controlled` becomes true, so `sepsis_resolve_progress` accrues and `is_septic` clears over time; the severed part's `amputated_limb` scar mints idempotently on the next advance.

### 10.6 Sepsis fever → thermoregulation — *deferred (host is doc-only)*

Sepsis drives fever (cytokine-mediated hypothalamic reset). `docs/THERMOREGULATION_RESEARCH.md` (~700 W combat load, ~280 kJ/°C heat capacity) is the natural host for a septic fever load — **but grep confirms thermoregulation is not yet in code** (no `core_temp`/`heat_load` in `core/*.gd`). **Defer**: when that system lands, septic members accrue a fever load (a `fever_delta` feeding the core-temperature model), raising heat-stress/dehydration. Until then, the §9.4 playable septic state (perception/stamina drain) carries the in-combat cost. Record only — no Phase A work.

### 10.7 Wound contamination / debris → infection multiplier — *in-scope (Phase A)*

Contaminated wounds (dirt, soil, foreign debris) carry higher infection risk — a **per-wound input** distinct from severity/arterial/compound. This is the cheapest, highest-leverage addition and it feeds §10.1 (gangrene) and §10.2 (tetanus) candidacy:

- Pass `extra_flags["contaminated"]` (bool) into `add_wound` → store `injury["is_contaminated"]`. Auto-flag contamination on cuts/stabs whose `penetration_to_tissue_mm` exceeds a depth (deeper = more devitalized/contaminated tissue).
- Multiply the per-day dose by `WOUND_INFECTION_CONTAMINATED_MULT` inside `wound_infection_daily_risk` (`BleedingConstants.gd:596`), alongside the existing compound/arterial/treated multipliers.

| Constant | Value | Anchor |
|---|---|---|
| `WOUND_INFECTION_CONTAMINATED_MULT` | `1.75` | Dirty/debrised/foreign-body wounds are markedly more infection-prone than clean wounds (pre-antibiotic wound-infection literature). |
| `CONTAMINATION_PENETRATION_MM` | `5.0` | Cuts/stabs penetrating to the "deep/full" band auto-flag `is_contaminated`. Set to `PENETRATION_DEPTH_SEVERITY_FULL_MM` (5.0), the codebase's existing "deep enough to matter" threshold (max achievable cut pen ≈ 11mm, so an earlier 12.0 never fired). |

**Debridement counter-play (clean-at-dressing).** Contamination is not permanent: a successful clean dressing (bandage/pack via `EntityMedical._apply_stabilizing_treatment`) *debrides* the wound — it removes devitalized tissue + debris, latching `injury["debrided"] = true` on the wound dict. `is_wound_contaminated` then returns false for that wound, so the `WOUND_INFECTION_CONTAMINATED_MULT` dose boost and the tetanus/gangrene candidacy both stop. This is the player's counter-play: treat a deep cut promptly and its elevated infection risk drops to a clean wound's. Rules: (a) a **stump** stays contaminated regardless (a raw amputation surface is still a historical infection/tetanus hazard even once cleaned — the `is_stump` check short-circuits before the debride flag); (b) re-dressing an already-debrided wound is a no-op (`is_wound_contaminated` returns false once `debrided`); (c) the latch rides the *successful* dressing branch, so a failed bandage does not debride. No new constant — debridement fully clears the depth-derived contamination (a properly debrided wound is clean), so no `DEBRIDEMENT_CONTAMINATION_REDUCTION` fraction is needed.

### 10.8 Scope roll-up

| Tag | Items | Why |
|---|---|---|
| **in-scope (Phase A)** | §10.4 extend-heal, §10.5 source-control, §10.7 contamination | Extend the existing infection block + `EntityMedical`/stump path; small, no new file set, highest realism-per-line. |
| **near-term (Phase A+)** | §10.1 gangrene, §10.2 tetanus, §10.3 osteomyelitis | Each is bounded (one wound-dict flag + a few constants + a block in the day-advance) but richer; land after the Phase A soak is green. |
| **deferred** | §10.6 fever | Host system (thermoregulation) not yet in code. |

All §10 values are **defaults pending soak**; the constants table is the tuning surface, the seams (§10.0) are the implementation surface.

---

## 11. Design refinements (pass 3) — sepsis as an entity-level state

One structural flaw in §1: sepsis is modeled as a **per-wound** property (`infection_stage == 2` on a wound) and the death roll, perception, and stamina effects all key to "any wound `stage==2`". But sepsis is **systemic** — once bacteria enter the blood, healing the local wound does not clear it. The concrete loophole: if a `stage==2` wound happens to heal (track-a resolution removes it from `wounds`), no wound is left to roll the death against, so sepsis **silently stops killing** — a septic member recovers for free just because the wound closed. §11 fixes this by promoting sepsis to an entity-level state.

### 11.1 Entity-level sepsis state (`CoreEntity.gd`)

- `is_septic: bool` — the **systemic** state. Set true the moment any wound reaches `infection_stage == 2`; persists until resolved. Single source of truth for all systemic effects + the death/resolve rolls. (The wound's `infection_stage` still drives *progression into* sepsis; `is_septic` drives the systemic consequences.)
- `sepsis_resolve_progress: float` (0→1) — accrues **only while source-controlled** (no untreated `stage==2` focus). At 1.0 → `is_septic = false` (recovered); if alive, flag for the `post_sepsis_weakness` mint (§2.3).
- `_sepsis_dead: bool` — death flag; **fold into `is_dead()`**.

### 11.2 Confirmed death wiring (no new signal path needed)

The campaign does **not** use the `died` signal for roster reconciliation — it **polls `is_dead()`** at day-advance (`CompanyDayCycle.gd:208`, `CompanyRoster.gd:363`, `CompanyMood.gd:49` → `remove_member_by_name`). The `died` signal is combat-UI/harness only (`character.gd:377`). So a sepsis death in `_process_healing` is already picked up by the campaign **as long as `is_dead()` returns true**. Concrete wiring:

- `is_dead()` (`CoreEntity.gd:517`): add `if _sepsis_dead: return true`.
- `_get_death_reason()` (`CoreEntity.gd:593`): return `"sepsis"` — ordered **after** vital-part destruction (more definitive) and **before** `blood_loss` (a sepsis death clamps `blood_volume` via `emit_death_once`, so a blood check first would mislabel it). Mirrors the existing vital-vs-blood ordering.
- `emit_death_once` (`EntityWounds.gd:665`) still fires so the combat UI + harness stay consistent.

### 11.3 Reframed sepsis day-advance (`EntityHealing.gd`)

Replaces §1.3 steps 2–3 with an entity-level loop:

1. Any wound reaching `stage==2` sets the entity `is_septic = true` (idempotent).
2. While `is_septic`: roll death. Risk = `SEPSIS_DEATH_RISK_SOURCE_CONTROLLED` (0.12) if **source-controlled** (every `stage==2` focus is definitively treated or a stump/amputated — reuses `part_has_definitive_hemostasis` + `has_stump_wound`), else `SEPSIS_DEATH_RISK_PER_DAY` (0.35). This is the "source control saves lives" lever: untreated sepsis is near-certain death; source-controlled sepsis is a survivable-but-dangerous recovery race.
3. While `is_septic` **and** source-controlled: `sepsis_resolve_progress += per_day * SEPSIS_RESOLVE_PER_DAY_TREATED`; at ≥1 → `is_septic = false` (recovered).
4. Amputating a septic part removes that focus (its `stage` clears) but the entity stays `is_septic` until the resolve accrual completes — amputation stops *new* load, not the residual systemic infection.
5. Gangrene focus: the death roll uses `GAS_GANGRENE_DEATH_RISK_PER_DAY` in place of the sepsis figure (still entity-keyed).

### 11.4 Side effects to preserve (don't "fix" them away)

- **Pain duration.** Track-(a) extension (×`INFECTION_HEAL_DURATION_MULT` on `healing_duration_seconds`) also lengthens pain, because `_get_wound_healing_progress` (`EntityWounds.gd:25`) drives both resolution *and* pain decay. That is **correct** — an infected wound stays painful longer. If a future PR splits resolution from pain, it must preserve this.
- **Wound merge.** `_try_merge_wound_into_channel` (`EntityWounds.gd:139-178`) only sets `healing_duration_seconds` when it is 0 (line 175-176), so an infection-extended duration is **preserved** on merge; the merge does not reset `created_at_game_time`, so the clock continues. Noted so the interaction isn't misread as a bug.

### 11.5 Budget

§11 changes no file set vs §4 — it is `CoreEntity.gd` (new `is_septic` / `sepsis_resolve_progress` + `is_dead()` / `_get_death_reason()` wiring) and `EntityHealing.gd` (reframed day-advance). Still **Phase A**, still within ≤3 owning `.gd` per pass.

---

## 12. Pass 4 — Healing model realism audit (2026-09-21)

Audit (not an edit) of every `core/HealingConstants.gd` value against the fetched clinical anchors (Wikipedia: **Bone fracture**, **Wound healing**, **Bruise**/contusion, **Red blood cell**). This is the **existing in-production** healing model — per `FEATURE_PRESERVATION` we **preserve** it, so this pass confirms the numbers are defensible and flags the one weak citation. It also fixes the mental model the §10.4 infection extension rests on: **track (a) vs track (b)**.

### 12.0 Track (a) vs track (b) — what the §10.4 infection extension actually touches

- **Track (a) — wound resolution** (wall-clock age): `_get_wound_healing_progress = 1 − exp(−age/tau)`, `tau = healing_duration_seconds / EXPONENTIAL_HEAL_TAU_DIVISOR (3.0)` → at `t = duration`, progress = 1 − e⁻³ ≈ **0.95** = `WOUND_RESOLVED_THRESHOLD`. This clock removes the wound, drives pain decay, and **gates scar minting** (Part 2).
- **Track (b) — tissue/bone deficit recovery**: a `heal_speed` multiplier (nutrition, endurance, concussion `healing_mult`, and the *existing* infection 0.5×) applied to the damage-deficit decay (`EntityHealing.gd:138-160`).
- Today infection touches only **(b)**. §10.4 adds the **(a)** extension (×`INFECTION_HEAL_DURATION_MULT` on `healing_duration_seconds`). They are independent tracks; after §10.4, infection is correct on both.

### 12.1 Per-constant audit

| Constant | Value | Fetched clinical anchor | Verdict |
|---|---|---|---|
| `TISSUE_HEAL_DURATION_SECONDS` (minor/mod/severe/critical) | 4 / 10 / 21 / 42 d | *Wound healing*: proliferative phase ~3 wk; secondary-intention closure — simple cuts days, larger wounds weeks (matches the code's own 3–5 d / 1–2 wk / 3–6 wk / 6+ wk bands). | **CONFIRMED** |
| `TISSUE_PART_DURATION_MULTIPLIERS` (head 1.15 / chest 1.25) | +15% / +25% | Deeper/structural tissue + constant motion (respiration) slows thoracic closure; conservative bump. | **CONFIRMED** |
| `BONE_HEAL_DURATION_SECONDS` + part mults (base 42 d; skull ×1.2, ribs ×1.3, legs ×1.1) | 6 wk base → skull 8.4 wk, ribs 7.8 wk, legs 6.6 wk | *Bone fracture*: typical **6–8 wk**; ribs are notoriously slow (constant respiratory motion). Base sits in-range; multipliers only lengthen the slow parts. | **CONFIRMED** |
| `BLOOD_VOLUME_RECOVERY_DURATION_SECONDS` | 24 h | *Red blood cell*: an acute volume deficit is restored over ~24–48 h via interstitial fluid shift (thirst/intake). RBC *mass* turnover is far slower (~120 d lifespan), but the game models **volume/pressure**, so 24 h is the correct anchor. | **CONFIRMED** (for the volume model) |
| `BRUISE_HEAL_DURATION_BY_SEVERITY` (minor/mod/severe/critical) | 4 / 8 / 14 / 21 d | *Bruise* (contusion): typical resolution **~2 weeks**; deep/large contusions 3–4 wk. `severe = 14 d` ("typical contusion") is exactly the anchor. | **CONFIRMED** |
| `BRUISE_PART_DURATION_MULTIPLIERS` (head 1.2 / chest 1.1) | +20% / +10% | Facial/scalp and trunk contusions can linger (deep subcutaneous plexus, low elasticity). | **CONFIRMED** |
| `EXPONENTIAL_HEAL_TAU_DIVISOR` + `WOUND_RESOLVED_THRESHOLD` | 3.0 / 0.95 | Internally self-consistent (1 − e⁻³ = 0.9502). Exponential *shape* = defensible approximation of the decelerating proliferative→remodeling deficit closure. | **CONFIRMED** (shape); see **12.2** for the citation caveat |
| `NUTRITION_HEAL_STARVATION_MULT` | 0.6× | Malnutrition (protein/energy/zinc/vitamin-C) is a documented wound-healing impairment. Direction + a 40% floor magnitude is defensible; exact value is a tuning knob. | **CONFIRMED** |

**Net: no `HealingConstants` corrections required.** Every duration sits within the fetched clinical ranges; the model is preserved, not changed.

### 12.2 One weak citation — "BMC Dermatol 9:2 — 72% / 35% vs 21%"

The `HealingConstants.gd:8-9` comment justifies the exponential model with "72% of wounds fit exponential; 35% vs 21% closure (BMC Dermatol 9:2)." **Softened to:**

- The **shape** (exponential decay of the healing deficit toward full closure, ~95% at `duration`) is a defensible *engineering approximation* of the documented decelerating proliferative→remodeling closure — **not** a claim the primary literature finds wound healing literally exponential.
- The specific figures (**72% fit; 35% vs 21%**) could **not be re-verified against the primary source this pass** and should be treated as a *citation to re-pull*, not a hard anchor. If the statistics are to be quoted elsewhere, pull the primary paper first; otherwise the code comment should read "exponential closure model (engineering approximation of deficit decay)" rather than the precise statistics.
- This does **not** gate the infection/scar work: the exponential model is the **existing in-production** healing shape (preserve per `FEATURE_PRESERVATION`), and §10.4 extends its *duration input*, not its shape.

### 12.3 The §10.4 infection extension sits on the correct track

Reconfirmed: the ×`INFECTION_HEAL_DURATION_MULT` (1.75) / ×`SEPSIS_HEAL_DURATION_MULT` (1.50) multipliers lengthen `healing_duration_seconds` — the **track-(a)** wall-clock resolution clock — which (i) keeps the wound physically open longer, (ii) keeps it painful longer (pain decay shares track (a), §11.4), and (iii) pushes scar minting (Part 2) later. The existing `WOUND_INFECTION_HEAL_SPEED_MULT` (0.5) / `SEPSIS_HEAL_SPEED_MULT` (0.25) operate on **track (b)** (deficit decay). Independent tracks; both now correct for infection.

### 12.4 Net

- All healing durations **confirmed** against the Bone fracture / Wound healing / Bruise / RBC clinical ranges.
- One citation (BMC Dermatol 9:2 72%/35%/21%) **softened to "re-verify primary source"**; the model shape is preserved and defensible.
- **Zero `HealingConstants` edits** — this pass is an audit, not a change. Phase A is unchanged.
