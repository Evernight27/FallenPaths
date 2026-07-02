# Weapon, Stance, and Experience Targeting Research

Research-backed tuning spec for **which attacks occur**, **which body parts are aimed**, and **how often aim becomes contact**. Calibrated via harness + F5 soak — **not** gated in `CombatResearchAnchors` (see [`LIVE_PATHS.md#research-audit`](LIVE_PATHS.md#research-audit)).

**Design lock:** No player limb picker. AI picks listed moves; `_add_attack_target_part` assigns `target_part`; contact resolves via path geometry.

**Canonical move defs:** `weapon/WeaponConstants.gd` (`_move_definitions_build`). Per-move rows below mirror that file.

---

## Three layers

| Layer | Question | Owner modules |
|-------|----------|---------------|
| **A — Occurrence** | Which move is chosen? | `CombatAIActionPicker`, `CombatWeaponForm.action_weight_mult`, `CombatTargetScoring` |
| **B — Aim** | Which body part is intended? | `AttackPathResolver.pick_ai_target_part` / `part_weights_for_ai_pick` |
| **C — Effectiveness** | Does the strike land as aimed and hurt? | `AttackPathResolver.resolve_hit_part`, `AttackResolver`, sub-region + armor |

```mermaid
flowchart LR
  Picker[AI move pick] --> TargetPart[target_part]
  TargetPart --> Resolve[resolve_hit_part]
  Resolve --> Damage[damage + sub-region]
```

---

## How targeting numbers are derived

### Anatomy baseline (`BODY_PART_TARGET_WEIGHTS`)

| Part | Weight | Rationale |
|------|--------|-----------|
| chest | 2.7 | Thorax + abdomen ≈ 27% surface area; center of mass — novices default here under stress (Fitts & Posner cognitive stage) |
| left_leg / right_leg | 2.0 each | Large stable targets; low-line cuts (unterhau, Fool) threaten legs per Liechtenauer low openings |
| head | 1.2 | High value but smaller target, usually well covered — Ringeck §13 still mandates head *and* body without neglecting “stingers” (thrusts) |
| arms | 1.0 each | ~10% each; horizontal cuts and parry intercepts raise arm rate in path geometry |

Source: de Leva segment mass informs lethality elsewhere; pick weights use **surface-area + HEMA opening priority**, not damage tables.

### Weapon and contact mults (Layer B)

```
effective_part_mult = BODY_PART_TARGET_WEIGHTS[part]
                    × WEAPON_PART_TARGET_MULT[weapon][part]   # weapon temperament
                    × WEAPON_CONTACT_PART_MULT[weapon][contact][part]  # strike mode
                    × form target_part_bias × move_family_part_bias
                    × proficiency_aim_part_mult (lerp 1.0 → 1.15)
```

**Design rule:** weapon row deltas stay in **±8–32%** per part; contact row adds **±5–18%** for mode-specific emphasis. Product of stacks should not exceed **~1.5×** on a single part vs neutral sword thrust-to-chest before INT/preferred_parts — keeps soak histograms tunable.

**Example (SPEAR `spear_thrust` → chest, stab):**  
`2.7 × 1.25 × 1.15 = 3.88` chest vs head `1.2 × 0.92 = 1.10` → **~3.5:1** chest:head at pick — matches Fiore “encase it in your chest” dominance.

### Occurrence bands (Layer A)

Per-move **occurrence %** = share of that weapon’s **offensive strike picks** (excludes parry-counter moves, which require bind context). Bands are soak **targets**, not hardcoded literals.

Derivation:

1. Start from historical technique frequency in primary treatises (qualitative).
2. Adjust for `move_family_mult` at default weapon form (e.g. SPEAR + plow thrust ↑).
3. Split feint family between `*_feint` move_ids.
4. Veterans gain +5–12 pp on precision families (thrust, feint-to-open) via `proficiency_occurrence_mult` (cap 1.35×).

**Note:** Per-move **Occ %** columns are soak targets for each `move_id`’s share of **offensive strike picks** (parry-counter and bind-only moves use a separate bind-context denominator).

### Contact fidelity (Layer C)

| Factor | Novice effect | Veteran effect | Source |
|--------|---------------|----------------|--------|
| `angle_variance_deg` on move def | Higher ° → more path leak at resolve | Lower effective leak with prof | Biomechanical telegraphing; heavy weapons ↑ variance |
| `intended_part_boost_mult` | ×2.0 on-path | ×2.0–×3.0 | Deliberate point placement after years of weapon-specific practice |
| `feint_target_reveal_at_progress` | Earlier reveal → defender reads true line | Feint families ↑ with PER | Meyer Fool/Alber feint-then-strike |

**aim=part match %** in soak ≈ `f(angle_variance, alignment, prof tier)` — lower for mace (13° variance) than dagger quick_thrust (5°).

---

## Universal HEMA principles

### Primary sources

| Source | What it contributes |
|--------|---------------------|
| [GNM 3227a / Ringeck glosses](https://wiktenauer.com/wiki/User:Christian_Trosclair/Translations/3227a_Longsword) | Core Liechtenauer zettel: openings, initiative, guard discipline |
| [Ringeck 2022 translation](https://wiktenauer.com/wiki/Sigmund_ain_Ringeck/Christian_Trosclair_2022) | “To the head, to the body — do not omit the stingers” (Zedel §13); wrath-cut counter-threats |
| [Vier Leger](https://wiktenauer.com/wiki/Vier_Leger) | Four guards (Ochs, Pflug, Vom Tag, Alber); “he who lies still is dead” |
| [Vier Versetzen](https://wiktenauer.com/wiki/Vier_Versetzen) | Master strikes break guards → counter-line targeting habit |
| [Sword and the Pen — Shooting the Long Point](https://swordandpen.substack.com/p/shooting-the-long-point) | Vorschlag: seize initiative with closest sure opening |
| [Schlachtschule — On Armored Combat](https://www.schlachtschule.org/instruction/OnArmoredCombat.pdf) | Gap targeting against plate — informs sub-region fidelity |

### Principle → game mapping

| Principle | Historical basis | Game expression |
|-----------|------------------|-----------------|
| **Attack the man, not the sword** | Talhoffer: “do not strike at the sword, but always to the openings” ([interpretation](https://truefork.org/DragonPreservationSociety/TalhofferDaggerClass.php)) | Body parts only in weight tables |
| **Closest surest opening (Blößen)** | 3227a §26: “wind into the exposures” | Path segment + off-focus / yomi bias |
| **Head and body when direct** | Zedel §13; Scheitelhau vs Alber | High/thrust → head/chest; low → legs |
| **Vorschlag / initiative** | Long-point threat forces reaction before bind | `ai_melee_focus` on opponent commitment |
| **Novice vs master** | Ringeck: avoid “common” guards; Vier Versetzen counter-lines | Prof channels + PER/INT tiers |

---

## Move catalog — SWORD

**Sources:** [3227a](https://wiktenauer.com/wiki/User:Christian_Trosclair/Translations/3227a_Longsword), [Ringeck](https://wiktenauer.com/wiki/Sigmund_ain_Ringeck/Christian_Trosclair_2022), [Meyer Ch.3](https://wiktenauer.com/wiki/Joachim_Meyer/Garber_Sword_Ch3_2023).  
**Weapon mult:** neutral (`WEAPON_PART_TARGET_MULT.SWORD` = `{}`). Contact refinement only.

| move_id | Line | Contact | `preferred_parts` | HEMA / research basis | Occ % (nov→vet) | Primary aim mult† | Layer C notes |
|---------|------|---------|-------------------|----------------------|-----------------|-------------------|---------------|
| `thrust` | high | stab | chest | Longpoint / nachreisen — point in line threatens center ([Sword and the Pen](https://swordandpen.substack.com/p/shooting-the-long-point)) | 28→38 | chest: 2.7×1.10=**2.97** | σ=7° default stab; Ox plow ↑ occurrence |
| `oberhau` | high_right | cut | head | Scheitelhau / Zornhau family — diagonal down from vom Tag ([Vier Versetzen](https://wiktenauer.com/wiki/Vier_Versetzen)) | 24→28 | head: 1.2×1.08=**1.30** | σ=10°; Wrath `high_cut` 1.18× |
| `oberhau_feint` | high_right | cut | head (bait) | Alber/Fool feint high, strike low — Meyer Fool cannot finish from guard without recovery ([Meyer Ch.3](https://wiktenauer.com/wiki/Joachim_Meyer/Garber_Sword_Ch3_2023)) | 5→12 | true line often leg after reveal | `feint_windup_duration_mult` 1.1; reveal 0.45 |
| `thrust_feint` | high | stab | chest (bait) | Feint thrust line, enter with stab — 3227a “learn thrust within cut” | 3→8 | chest on commit | reveal 0.40 (faster than cut feint) |
| `unterhau` | low_left | cut | legs | Schaitelhaw vs low guard; low opening when opponent high ([Keith Farrell — Alber](https://www.keithfarrell.net/blog/2017/06/thoughts-schaitelhaw-fencing-alber/)) | 12→14 | leg: 2.0×1.08(cut)=**2.16** | Fool `low_cut` part bias 1.12 |
| `slash` | left | cut | arms, chest | Zwerchhau / horizontal — threatens arms across line | 18→22 | arm: 1.0×1.05=**1.05** | Tempest slash family 1.12× |
| `pommel_strike` | high | blunt | head | Mordschlag / pommel in close — Ringeck close techniques | 2→2 | head: 1.2 (no cut row) | Low `impact_station_mean` 0.16 — setup strike |
| `parry_thrust` | high | stab | chest | Nachreisen after bind — thrust to opening ([3227a](https://wiktenauer.com/wiki/User:Christian_Trosclair/Translations/3227a_Longsword)) | bind* | chest: 2.97 | Parry context; not in offensive pool % |
| `parry_cut` | left | cut | arms | Schnitt after Absetzen — cut to arm in bind | bind* | arm: 1.05 | `is_parry: true` |

† Primary aim mult = anatomy × contact row for listed part (SWORD), before form/prof/INT.  
\* Parry-counter moves: **~15–25% of successful strikes** when bind/flurry window active; omitted from offensive-pool occurrence columns.

**SWORD soak contribution:** balanced head/chest/arms/legs mix; feints inflate veteran leg and chest off-bait hits.

---

## Move catalog — AXE

**Sources:** [Le Jeu de la Hache](https://wiktenauer.com/wiki/Le_Jeu_de_la_Hache_(MS_Francais_1996)), [ARMA notes](https://www.thearma.org/spotlight/NotesLEJEUDELAHACHE.htm) (estocq, tour de bras, coup; §22 head feint → knee hook).  
**Weapon mult:** head +22%, arms +12%, chest −5%.

| move_id | Line | Contact | `preferred_parts` | HEMA / research basis | Occ % (nov→vet) | Primary aim mult† | Layer C notes |
|---------|------|---------|-------------------|----------------------|-----------------|-------------------|---------------|
| `overhead_chop` | high | cut | head | Le Jeu §22: “try to hit him on the head” — tour de bras / overhead ([ARMA notes](https://www.thearma.org/spotlight/NotesLEJEUDELAHACHE.htm)) | 22→26 | head: 1.2×1.22×1.10=**1.61** | σ=12°; default axe chop |
| `diagonal_chop` | high_left | cut | arms, chest | Coup diagonal — hooking arm line in poleaxe play | 16→20 | arm: 1.0×1.12×1.08=**1.21** | Tempest-friendly; arm intercept common |
| `spike_thrust` | high | stab | chest | Bec de faucon estocq to face/chest gap ([Le Jeu](https://wiktenauer.com/wiki/Le_Jeu_de_la_Hache_(MS_Francais_1996)) | 10→14 | chest: 2.7×0.95×1.12=**2.88** | Weapon override `["chest"]`; gap thrust |
| `poll_strike` | high | blunt | head | Demi-hache butt / queue push — blunt finish at close ([ARMA notes](https://www.thearma.org/spotlight/NotesLEJEUDELAHACHE.htm)) | 10→12 | head: 1.2×1.22×1.15=**1.68** | `impact_station_mean` 0.22 — short lever |
| `parry_chop` | left | cut | arms | Bind after displacement — chop to arm in contact | bind* | arm: 1.21 | Requires prior bind |

† Includes `WEAPON_PART_TARGET_MULT.AXE` + contact row.

**AXE soak:** head 35–45% driven by `overhead_chop` + `poll_strike`; chest from `spike_thrust`.

---

## Move catalog — MACE

**Sources:** Armored blunt doctrine ([Schlachtschule PDF](https://www.schlachtschule.org/instruction/OnArmoredCombat.pdf)); tournament head strikes; game KE blunt bands in `CombatDesignAnchors`.  
**Weapon mult:** head +32%, chest +10%, limbs 0.88–0.90. All moves `blunt`.

| move_id | Line | Contact | `preferred_parts` | HEMA / research basis | Occ % (nov→vet) | Primary aim mult† | Layer C notes |
|---------|------|---------|-------------------|----------------------|-----------------|-------------------|---------------|
| `overhead_strike` | high | blunt | head | Crown/helm concussion priority — plate deflects glancing limb blows | 30→36 | head: 1.2×1.32×1.14=**1.81** | σ=13° — lowest aim fidelity |
| `side_strike` | right | blunt | arms | Flank strike to break guard arm — secondary to head | 18→22 | arm: 1.0×0.90×(blunt n/a)=**0.90** | Weapon override arms; limb mult penalized |
| `direct_blow` | high | blunt | head, chest | Committed center strike — harness transfer | 14→18 | head: 1.81 / chest: 2.7×1.10×1.08=**3.21** | Override `["head","chest"]` |
| `parry_strike` | high | blunt | head | Riposte after block — short path to head | bind* | head: 1.81 | Post-parry only |

**MACE soak:** head ≥40% of aims — validate `overhead_strike` + `direct_blow` dominate histogram.

---

## Move catalog — DAGGER

**Sources:** [Talhoffer dagger](https://www.thearma.org/talhoffer/talhoffer9.htm), [Talhoffer class notes](https://truefork.org/DragonPreservationSociety/TalhofferDaggerClass.php), [Lignitzer](https://wiktenauer.com/wiki/Andre_Lignitzer/Keith_Farrell_D_2023), Fiore dagger (Getty).  
**Weapon mult:** chest +22%, head +8%, arms −5%. **Range:** 0.8 m — legs deprioritized in soak bands.

| move_id | Line | Contact | `preferred_parts` | HEMA / research basis | Occ % (nov→vet) | Primary aim mult† | Layer C notes |
|---------|------|---------|-------------------|----------------------|-----------------|-------------------|---------------|
| `quick_thrust` | high | stab | chest | Ober stich — “shortest line… to chest” ([Talhoffer notes](https://truefork.org/DragonPreservationSociety/TalhofferDaggerClass.php)) | 32→38 | chest: 2.7×1.22×1.18=**3.89** | σ=5° — highest aim fidelity |
| `committed_thrust` | high | stab | chest | Strong pierce vs armor — rondel through gap | 12→16 | chest: 3.89 | Higher `impact_station_mean` 0.78 |
| `quick_slash` | left | cut | arms | Slice wrist/forearm when thrust bound — secondary | 16→18 | arm: 1.0×0.95×1.08=**1.03** | Close range arm intercept |
| `dagger_pommel` | high | blunt | head | Pommel to face in clinch — Fiore/Talhoffer close plays | 4→4 | head: 1.2×1.08=**1.30** | Low KE setup |
| `parry_thrust_dagger` | high | stab | chest | Displace and thrust — “follow with point to chest” | bind* | chest: 3.89 | Override `["chest"]` |

**DAGGER soak:** chest 40–55%; `quick_thrust` + `committed_thrust` ≥70% of thrust aims.

---

## Move catalog — SPEAR

**Sources:** [Fiore spear](https://wiktenauer.com/wiki/Fiore_de%27i_Liberi/Spear), [Getty MS Ludwig XV 13](https://wiktenauer.com/wiki/Fior_di_Battaglia_(MS_Ludwig_XV_13)), [Selohaar spear PDF](https://www.selohaar.org/CW2010/The_Spear_of_Fiore_dei_Liberi.pdf) (scambiar di punta).  
**Weapon mult:** chest +25%, head −8%, legs +10% (lane open). **Depth:** `CombatDepthPolearm` filters low targets when lane closed.

| move_id | Line | Contact | `preferred_parts` | HEMA / research basis | Occ % (nov→vet) | Primary aim mult† | Layer C notes |
|---------|------|---------|-------------------|----------------------|-----------------|-------------------|---------------|
| `spear_thrust` | high | stab | chest | “Rush forth a great wound” in chest — primary Fiore play | 40→48 | chest: 2.7×1.25×1.15=**3.88** | σ=7°; plow form thrust 1.20× |
| `off_line_thrust` | high (+25° offset) | stab | chest | Scambiar — traverse off line, point to face/chest ([Selohaar PDF](https://www.selohaar.org/CW2010/The_Spear_of_Fiore_dei_Liberi.pdf)) | 10→14 | chest: 3.88 | σ=20° — veteran PER reduces leak |
| `spear_slash` | left | cut | arms | Short edge beat — secondary to thrust | 8→10 | arm: 1.0×1.05(cut n/a)*=**1.0** | *No SPEAR cut contact row |
| `pole_swing` | left | blunt | arms, head | Shaft strike — rompere di punta butt ([Selohaar PDF](https://www.selohaar.org/CW2010/The_Spear_of_Fiore_dei_Liberi.pdf)) | 6→8 | arm/head situational | σ=12° |
| `parry_thrust_spear` | high | stab | chest | Beat aside → thrust chest (Getty spear plays) | bind* | chest: 3.88 | Override `["chest"]` |

**SPEAR soak:** chest ≥50% of thrust aims; legs 10–20% only when depth lane allows (`WEAPON_CONTACT_PART_MULT` leg +8% on stab).

---

## Per-stance (weapon form) doctrine

### Liechtenauer guard mapping

| Game form | HEMA anchor | Home guard | `move_family_mult` (signature) |
|-----------|-------------|------------|--------------------------------|
| **Ox** | Ochs | `high_right` | thrust 1.15; `move_family_part_bias` thrust→chest 1.15 |
| **Plow** | Pflug | `low` | thrust 1.20; feint 0.88 |
| **Wrath** | Vom Tag / wrath cut | `high_left` | high_cut 1.18; head bias 1.18 |
| **Fool** | Alber | `low_left` | feint 1.25; legs 1.15 |
| **Wall** | Schrankhut / defensive | `high` | parry 1.15; feint 0.80 |
| **Tempest** | Secondary flurry | `left` | slash 1.12; arms 1.12 |
| **Balanced** | — | `high` | all 1.0 |

Sources: [Vier Leger](https://wiktenauer.com/wiki/Vier_Leger), [Meyer Ch.3](https://wiktenauer.com/wiki/Joachim_Meyer/Garber_Sword_Ch3_2023), `CombatWeaponForm.FORM_DEFS`.

### Form × move interaction (research rationale)

| Form | Why these moves ↑ | Why these parts ↑ |
|------|-------------------|-------------------|
| Ox | Ochs is point-forward — thrust is natural Vorschlag ([Vier Leger](https://wiktenauer.com/wiki/Vier_Leger)) | Chest/high line threatened by longpoint |
| Plow | Pflug stab family; feints discouraged (methodical pressure) | Chest on guarded transitions |
| Wrath | Ringeck §27 wrath cut threatens with point then cuts | Head/arms on committed oberhau |
| Fool | Meyer Alber feint before true strike | Legs/low after high feint bait |
| Wall | Defensive — parry/wait; fewer commits (`ai_melee_focus` 0.92) | Safe chest shots; head deprioritized |
| Tempest | Volume slashes — AGI over precision | Arms/head in flurry |

`target_part_bias` scales with `form_proficiency_tier` (lerp toward full bias at veteran).

---

## Experience model

### Three channels

| Channel | Storage | Affects |
|---------|---------|---------|
| **Weapon familiarity** | `_weapon_proficiency[weapon_id]` | Occurrence boost (+12% per tier on weapon); aim mult; `intended_part_boost` |
| **Form familiarity** | `_form_proficiency[form_id]` | Signature `move_family_mult` scaling (+8% tier + family coupling) |
| **Cognitive skill** | PER + INT | Off-focus, yomi, `preferred_parts` precision (INT^tier) |

### Progression constants (code)

| Constant | Value | Research mapping |
|----------|-------|------------------|
| `WEAPON_PROF_VETERAN_MAX` | 20.0 | ~20 h weapon-specific deliberate practice → plateau (Ericsson-style order-of-magnitude) |
| `PROF_OCCURRENCE_MULT_MAX` | 1.35× | ±15–25% on signature families — matches plan bands |
| `PROF_INTENDED_PART_BOOST_MIN/MAX` | 2.0 / 3.0 | Novice geometry leak vs veteran point placement |
| `PROF_AIM_MULT_MAX` | 1.15 | Weapon+form aim table strength cap |

### Proficiency gains on hit

| Event | Gain |
|-------|------|
| PER | Off-focus hit; feint drawing wrong guard |
| INT | Hit on move `preferred_parts` |
| Weapon prof | Any hit with weapon id |
| Form prof | Hit using form’s signature move family |

---

## Soak calibration targets

### Methodology

1. Weapon sweep (`__WEAPON_SWEEP__`, 3+ cycles).
2. Tag parse: `part=`, `aim=`, `aim_prof=`, `occ_mult=`, `move_id` (from attack_type).
3. Aggregate per weapon; compare to bands (±10% on n≥50 hits).
4. Retune constants only — see move catalogs for which constant owns each miss.

### Weapon-level histogram bands

| Weapon | Head % | Chest % | Arms % | Legs % | aim=part % | Top move drivers |
|--------|--------|---------|--------|--------|------------|------------------|
| SWORD | 25–35 | 30–40 | 15–25 | 10–20 | 55–70 | `thrust`, `oberhau`, `unterhau` |
| AXE | 35–45 | 15–25 | 20–30 | 5–15 | 50–65 | `overhead_chop`, `diagonal_chop` |
| MACE | 40–55 | 20–30 | 10–20 | 5–15 | 45–60 | `overhead_strike`, `direct_blow` |
| DAGGER | 15–25 | 40–55 | 15–25 | 5–10 | 60–75 | `quick_thrust`, `committed_thrust` |
| SPEAR | 10–20 | 45–60 | 10–20 | 10–20 | 55–70 | `spear_thrust`, `off_line_thrust` |

### Per-move aim=part expectations (Layer C)

| move_id | Expected aim=part % (nov) | Expected (vet) | Dominant leak part |
|---------|---------------------------|----------------|--------------------|
| `quick_thrust` | 65–75 | 75–85 | chest→arm (parry intercept) |
| `spear_thrust` | 60–70 | 70–80 | chest→arm |
| `thrust` | 58–68 | 68–78 | chest→head |
| `oberhau` | 50–62 | 58–70 | head→arm |
| `unterhau` | 48–60 | 55–65 | leg→chest (high guard) |
| `overhead_chop` | 45–58 | 52–65 | head→arm |
| `overhead_strike` | 40–55 | 48–58 | head→chest |
| `oberhau_feint` | 35–50 | 45–60 | bait head → true leg |

Leak parts come from `resolve_hit_part` path intercept when alignment < 1 or guard interpose.

---

## Implementation map

| File | Role |
|------|------|
| `weapon/WeaponConstants.gd` | Move defs: `attack_line`, `preferred_parts`, `angle_variance_deg`, `WEAPON_MOVE_PREFERRED_PARTS` |
| `core/BodyPartConstants.gd` | `BODY_PART_TARGET_WEIGHTS`, `WEAPON_PART_TARGET_MULT`, `WEAPON_CONTACT_PART_MULT` |
| `combat/CombatWeaponForm.gd` | `move_family_mult`, `target_part_bias`, `move_family_part_bias` |
| `combat/AttackPathResolver.gd` | Layer B pick + Layer C `resolve_hit_part` |
| `core/EntityProficiency.gd` | Prof channels, `intended_part_boost_mult`, occurrence mult |
| `combat/AttackResolver.gd` | `aim_prof_tier`, `occ_mult` stamps |
| `combat_tuning/TuningLogFormatter.gd` | `aim=`, `aim_prof=`, `occ_mult=` |

---

## Out of scope

- Player per-part picker (wontfix per `PLANNING.md`)
- New `FEATURE_*` without user ask
- Literature gates in `CombatResearchAnchors` for targeting weights
- Campaign persistence for `_weapon_proficiency` / `_form_proficiency`
