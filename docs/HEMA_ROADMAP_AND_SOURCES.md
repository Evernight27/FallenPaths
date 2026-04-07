# Hema Roadmap And Sources

Consolidated documentation. Each section keeps its **original filename** in the `Source` line for provenance.

## Contents

1. [HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md](#hema-system-changes-implementation-roadmap)
2. [HEMA_FIDELITY_IMPROVEMENTS.md](#hema-fidelity-improvements)
3. [HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md](#hema-zones-feints-flurries-investigation)
4. [HEMA_VS_KCD_SOURCE_ANALYSIS.md](#hema-vs-kcd-source-analysis)
5. [KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md](#kingdom-come-abstract-replication-investigation)

---

<a id="hema-system-changes-implementation-roadmap"></a>

## Source: `HEMA_SYSTEM_CHANGES_IMPLEMENTATION_ROADMAP.md`

# HEMA System Changes: Implementation Roadmap

## Purpose

Identify **what parts of the system need to change** to more accurately reflect HEMA/Liechtenauer fencing, and provide **multiple implementation methods** for each change. Prioritized by HEMA alignment impact.

---

## Part 1: Bind vs Deflect Decision (Contact Quality)

**Gap:** System uses geometry only. HEMA: margin, alignment, late parry, off-balance affect bind vs deflect.

**Files:** DefenseResolutionHandler, AttackResultApplier, GuardLineUpdater, CombatStateHandlers

### Method A: Parry Control Score (Deterministic)

1. Compute `parry_control` in DefenseResolutionHandler from margin, alignment, readiness, late_parry, off_balance.
2. Pass `parry_clash_context` in parry_deflect return; store on attacker; pass to `set_guard_deflected`.
3. In GuardLineUpdater: if `parry_control >= BIND_THRESHOLD` (e.g. 0.65) → bind; else → deflect (use geometry).

**Pros:** Causal, deterministic, uses existing data. **Cons:** New data flow; constants to tune.

### Method B: Simple Margin Threshold

1. Pass only `margin_ratio = c_d / (p_a * threshold)` to deflection logic.
2. If margin_ratio > 1.3 → bind (decisive). Else → deflect.

**Pros:** Minimal; one number. **Cons:** Ignores alignment, late parry, off-balance.

### Method C: Probability Weight (Softer)

1. parry_control → probability of bind. Roll: if randf() < parry_control → bind else deflect.
2. Same data flow as A but outcome is random weighted by control.

**Pros:** Smooth distribution. **Cons:** Violates HEMA causality (same conditions → different outcomes).

**Data note:** `late_parry` and `parry_off_balance` exist in `dc` (DefenseChoiceResolver result) but are **not** currently passed to `_resolve_parry`. Add them to the `resolve()` → `_resolve_parry()` call.

**Recommendation:** **Method A** for optimal HEMA. B as minimal fallback.

---

## Part 2: Deflection Magnitude (Partial vs Full)

**Gap:** Always 45° or 90°. HEMA: light clash → partial; heavy → full.

**Files:** GuardLineUpdater, CombatConstants

### Method A: guard_deflect_blend (Approach 6 from soft-deflection doc)

1. Add `guard_deflect_blend` (0–1) to combatant. Set from clash severity when deflect.
2. Resolve discrete `guard_line` from geometry + severity (e.g. severity < 0.6 → adjacent; ≥ 0.6 → opposite for opposite-defender).
3. Blend affects `get_line_alignment`: `lerp(align_at_attack, align_at_deflect, blend)` when computing effective alignment for next parry/attack.
4. Path lookup stays discrete (guard_line).

**Pros:** Partial deflection; alignment becomes continuous. **Cons:** One extra field; consumers need blend param.

### Method B: Severity → Discrete Choice Only

1. No blend. Severity thresholds: low → bind or adjacent; high → opposite (for opposite geometry).
2. Still binary per outcome, but severity shifts which of the 3 outcomes (bind/adjacent/opposite) we get.

**Pros:** No schema change. **Cons:** No partial; still snaps to 0/45/90°.

### Method C: Eight Diagonal Lines

1. Add high_left, high_right, low_left, low_right. Severity maps to one of 8 positions.
2. E.g. severity 0.2 → high_left (between bind and adjacent). Full tables for paths, angles, parts.

**Pros:** Finer discrete steps. **Cons:** 2× lines; large table expansion.

**Recommendation:** **Method A** for optimal HEMA (matches prior Approach 6). B if minimal.

---

## Part 3: Hard vs Soft Bind (Riposte Advantage)

**Gap:** Bind and deflect both give defender same treatment. HEMA: hard bind = can thrust immediately; deflect = new action, full wind-up.

**Files:** AttackWindUpStarter, CombatConstants, AvailableActionsBuilder (optional)

### Method A: Bind Reduces Riposte Wind-Up

1. After parry_deflect, store `parry_was_bind` (bool) or `bind_hardness` (0–1) on defender.
2. When defender’s next action is attack vs the same attacker who they just parried: if bind, apply wind-up multiplier (e.g. 0.5× or 0.7×).
3. Reset on defender’s next attack or after N seconds.

**Pros:** Hard bind = faster riposte. **Cons:** Need to track “just parried X”; edge cases.

### Method B: Gauge Advantage for Bind

1. On parry_deflect bind: set defender `gauge = 100` immediately (or grant +50 gauge).
2. Defender goes turn_ready sooner than attacker. Deflect: defender keeps current gauge, no bonus.

**Pros:** Simple; explicit riposte priority for bind. **Cons:** May feel strong; gauge burst.

### Method C: Separate “Riposte from Bind” Move

1. Add move_id `riposte_thrust` or similar, available only when defender just achieved bind vs target.
2. Riposte has 0 or minimal wind-up. Normal attack has full wind-up.
3. After using riposte or after timeout, fall back to normal attacks.

**Pros:** Clear mechanical distinction. **Cons:** New move; more UI/complexity.

### Method D: Wind-Up Cost from Guard Alignment (Existing + Bind Tuning)

1. Current: guard transition cost = f(alignment). After bind, defender’s guard = attack line → alignment to thrust in same line = 1 → minimal cost.
2. After deflect, defender’s guard = attack line (contact point). Attacker’s guard = deflected. So defender attacking: their alignment to attacker’s current guard could be good (they’re in line).
3. Difference: after bind, attacker’s blade is still in same line (defender can thrust straight). After deflect, attacker’s blade is elsewhere — defender’s alignment to that guard may vary.
4. Tweak: if bind, defender gets `guard_transition_mult = 0.5` for thrust in same line. If deflect, normal mult.

**Pros:** Uses existing alignment logic. **Cons:** Requires passing bind flag to wind-up.

**Recommendation:** **Method B** (gauge bonus for bind) or **Method A** (wind-up reduction). B is simplest and clearly rewards bind.

---

## Part 4: Attack Type (Thrust vs Blunt vs Cut)

**Gap:** Thrust deflects more easily; blunt deflects harder. Same logic for all.

**Files:** GuardLineUpdater, CombatConstants

### Method A: Per-Type Severity Thresholds

1. For opposite-defender 90° deflect: use `OPPOSITE_SEVERITY_THRESHOLD` by attack_type.
2. Thrust: 0.5 (easier to deflect to opposite). Cut: 0.65. Blunt: 0.8.
3. Below threshold → adjacent (45°); above → opposite (90°).

**Pros:** Matches physics. **Cons:** Need attack_type in clash context.

### Method B: Multiplier on Severity by Type

1. `effective_severity = severity * type_mult`. Thrust 1.2, blunt 0.8, cut 1.0.
2. Use effective_severity for magnitude logic.
3. Same thresholds; type shifts effective value.

**Pros:** Single threshold. **Cons:** Semantics less direct.

**Recommendation:** **Method A**.

---

## Part 5: Riposte Priority (Defender Acts First)

**Current:** Implicit — defender keeps gauge, attacker goes to recovery. Defender often fills first.
**HEMA:** Parry creates tempo to attack; defender should have initiative.

### Method A: Explicit Gauge Bonus for Defender (parry_deflect)

1. On parry_deflect: `tgt.gauge = min(100, tgt.gauge + PARRY_RIPOSTE_GAUGE_BONUS)` (e.g. +30).
2. Defender fills faster; more likely to get turn_ready before attacker finishes recovery.
3. Already have parry_bonus_until for parry_c_d; this is for gauge.

**Pros:** Simple; reinforces riposte. **Cons:** Can stack with existing implicit advantage.

### Method B: Defender Recovery = 0 (Already “Ready”)

1. On parry_deflect: defender went from possible RECOVERING or WAITING to WAITING with no recovery.
2. They don’t enter recovery; they’re immediately ready. Gauge unchanged.
3. Attacker has long recovery (full_stop). So defender already has implicit priority.
4. Option: set defender gauge = 100 if below 100, so they’re immediately turn_ready when possible.
5. Risk: double-turn (defender attacks twice before attacker can act). May need cooldown.

**Pros:** Strong riposte. **Cons:** Balance risk.

### Method C: Turn Order Override

1. After parry_deflect, next `turn_ready` is forced to defender (if they have actions).
2. Skip attacker’s turn_ready until defender has acted (or N seconds).
3. Requires turn-order queue or “riposte_pending” flag.

**Pros:** Guaranteed riposte. **Cons:** Bigger flow change.

**Recommendation:** **Method A** (modest gauge bonus) — current implicit priority is often enough; small bonus is sufficient.

---

## Part 6: Late Parry, Off-Balance, Readiness in Deflection

**Gap:** Not passed to deflection. HEMA: all reduce control → more deflect.

**Files:** DefenseResolutionHandler, AttackResultApplier

### Method A: Include in parry_clash_context (Part 1 Method A)

1. Already in parry_control: timing_factor (late), readiness_factor (off_balance).
2. Pass full context; GuardLineUpdater uses parry_control which incorporates these.

**Pros:** One implementation covers all. **Cons:** None if doing Part 1 Method A.

### Method B: Separate Modifiers

1. `deflect_bias = 1.0`. If late_parry: += 0.3. If off_balance: += 0.2. If readiness < 0.5: += 0.2.
2. Use deflect_bias to shift outcome toward deflect (e.g. lower bind threshold when bias high).

**Pros:** Transparent. **Cons:** More knobs.

**Recommendation:** **Method A** (part of parry_control).

---

## Part 7: Thrust Preferentially Deflects

**Gap:** Thrust parried → same as cut. HEMA: thrust usually deflects (point offline), rarely full stop/bind.

### Method A: Thrust Bias to Deflect in Bind/Deflect Decision

1. When attack_type == stab: `parry_control *= 0.8` (or similar) — harder to achieve bind.
2. Thrust needs higher margin/alignment to bind.
3. Most thrust parries → deflect.

**Pros:** Simple. **Cons:** One more modifier.

### Method B: Thrust Cannot Full-Stop (parry_deflect) Unless Block + Very High c_d

1. For stab, require `c_d >= p_a * 1.3` (stricter) for full_stop. Or: stab always goes parry_partial (redirect) never parry_deflect.
2. That would change DefenseResolutionHandler — stabs rarely or never full stop.

**Pros:** Strong HEMA alignment. **Cons:** Big change; stabs might always “get through” partially.

**Recommendation:** **Method A** — keep parry_deflect possible for thrust, but bias control downward so bind is rarer.

---

## Part 8: Soft vs Hard Bind for Attacker

**Gap:** Attacker in recovery doesn’t “feel” whether they’re soft or hard. HEMA: soft bind = attacker disadvantaged, can work (Wind) or leave; hard = opponent can thrust.

**Note:** We don’t track “who is hard” — both blades in same line. The defender is the one who parried, so they typically have strong-on-weak. Attacker is soft. So attacker’s recovery and next actions could reflect “I was dominated in the bind.”

### Method A: Attacker Recovery Modifier by Bind

1. If bind (guard_line == attack_line): attacker’s recovery `attack_deflect` curve could be slightly longer (blades were in contact, more “stuck”).
2. Or: bind gives attacker worse READINESS early (more stunned from firm contact).
3. Already have READINESS_BY_CAUSE["attack_deflect"]. Could split to attack_deflect_bind vs attack_deflect_deflect.
4. Bind: [0.4, 0.8] (more stunned). Deflect: [0.5, 0.85] (blade knocked away, less control shock).

**Pros:** Attacker feels bind vs deflect. **Cons:** Subtle; may need separate recovery cause.

### Method B: Defer

1. Leave attacker recovery identical for bind and deflect.
2. Focus on defender-side (riposte advantage) first.

**Recommendation:** **Method B** (defer) — defender bind advantage is higher impact. Attacker bind penalty is secondary.

---

## Summary: Implementation Order

| Priority | Part | Methods | Effort |
|----------|------|---------|--------|
| 1 | Bind vs Deflect (contact quality) | A (parry_control), B (margin only) | Medium |
| 2 | Deflection magnitude (partial) | A (blend), B (severity thresholds) | Medium |
| 3 | Hard bind riposte advantage | B (gauge), A (wind-up) | Low–Medium |
| 4 | Attack type modulation | A (thresholds) | Low |
| 5 | Late/off-balance/readiness | A (in parry_control) | Low (if doing 1A) |
| 6 | Riposte priority | A (gauge bonus) | Low |
| 7 | Thrust deflect bias | A (control modifier) | Low |
| 8 | Attacker bind penalty | Defer | — |

---

## Data Flow Summary (Method A for Parts 1–2)

```
DefenseResolutionHandler._resolve_parry (parry_deflect):
  - Compute parry_control, margin_ratio, etc.
  - return { action, target_id, recovery_duration, parry_clash_context }

AttackResultApplier (parry_deflect):
  - Store parry_clash_context on attacker (or merge with defender_guard_line_at_parry)
  - Store parry_was_bind on defender (from parry_control >= threshold) for riposte

CombatStateHandlers.process_recovering:
  - Pass parry_clash_context to set_guard_deflected
  - Erase after use

GuardLineUpdater.set_guard_deflected:
  - Accept clash_context
  - Use parry_control for bind vs deflect
  - Use severity for blend (Part 2) and magnitude (adjacent vs opposite)
  - Set guard_deflect_blend when deflect
  - Set guard_line (discrete)
```

---

## References

- HEMA_DEFLECTION_IMPLEMENTATION_INVESTIGATION.md
- HEMA_VS_SYSTEM_BIND_DEFLECT_COMPARISON.md
- SOFT_DEFLECTION_WEAPON_POSITION_INVESTIGATION.md
- APPROACH_5_VS_6_HEMA_COMPARISON.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md

---

<a id="hema-fidelity-improvements"></a>

## Source: `HEMA_FIDELITY_IMPROVEMENTS.md`

## HEMA Fidelity: System Examination and Improvement Options

Analysis of the combat/parry system against HEMA principles and historical sources, with prioritized improvement options.

---

### 1. What's Already Well-Aligned

| Area | Implementation | HEMA Source |
|------|----------------|-------------|
| **Redirect-first, block as exception** | Block only when m_d≥0.9m_a and s_d≥0.95s_atk; else redirect | ARMA, Sword STEM: cutting blades deflect; blocks for strong/heavy only |
| **Parry speed** | ~50% of max strike (PARRY_V_FRACTION) | Defensive move 40–60% of strike |
| **Strike velocity** | 6–24 m/s | Research 17–24 m/s rod-like strikes |
| **Weapon masses** | Sword 1.2, dagger 0.3, mace 1.7, axe 1.5 kg | Longsword/arming sword, rondel, pollaxe ranges |
| **Thrust easier to redirect** | +22% redirect bonus | Sword STEM: "point directed offline by lateral force" |
| **Blunt harder to deflect** | −12% penalty | Momentum-based; angle matters less |
| **Cut→blunt shift** | Deflected edge presents flat | ARMA edge-on-flat, "smack aside" |
| **Mass disparity** | Light-weapon redirect bonus | Fiore: dagger deflects, doesn't absorb |
| **Velocity curve** | Quadratic (early parry = less momentum) | Blade accelerates into impact |
| **Recovery readiness** | RECOVERING: 0.5→0.85 lerp | Early recovery worse; late nearly ready |
| **Off balance** | After miss/deflect; parry capacity ×0.7 | Whiff/deflect leaves attacker exposed |
| **Parry success bonus** | +10% capacity after deflect | Clean parry leaves defender ready |
| **8 cutting directions** | Oberhau, Unterhau, slash, thrust, etc. | Liechtenauer/KDF structure |
| **Parry-counters** | parry_thrust, parry_cut, parry_chop, etc. | Explicit riposte moves (currently passive-only) |

---

### 2. Improvement Categories

#### A. Blade Geometry (Strong/Weak)

**HEMA principle:** "Catch the weak of their blade on the strong of yours" (Liechtenauer, i.33). Strong = near guard; weak = near tip. Contact point changes leverage.

**Current:** Only mass (m_a, m_d) and strength. No blade geometry.

**Options:**
1. **Simple strong/weak factor:** Add `strong_contact_bonus` when defender "catches weak"—approximate by attack archetype (OVERHEAD = more weak exposed, QUICK_SLASH = less) or add a 0–1 "strong_contact" per move.
2. **Full blade model:** Weapon gets `blade_length_cm`, `strong_fraction` (e.g. 0.3 = 30% strong). Parry capacity multiplied by contact quality. Higher complexity.

**Effort:** Low (archetype modifier) to Medium (blade model).

---

#### B. Guard / Readiness

**HEMA principle:** "On guard" vs "blade down" changes how fast you can parry. Guard is a posture, not just "waiting to act."

**Current:** WAITING = uniform. No notion of guard level.

**Options:**
1. **Guard sub-state in WAITING:** `guard: float` (0–1). After attack, guard drops; after parry or no action, guard rises. Parry reaction_time × (1 / guard) or capacity × guard.
2. **Defensive stance action:** Choose "hold guard" instead of attack—gauge fills slowly, parry/dodge improve. STATE_MACHINE_PARRY_REALISM §3.6.

**Effort:** Low–Medium.

---

#### C. Attack Selection and Feints

**HEMA principle:** Feints work because reaction+decision takes ~400–600 ms. Attack choice (committed vs probing) matters. Counter-time: attack into their preparation.

**Current:** Attack chosen from available moves; no feint, no abort. COMMITMENT_FRACTION (0.2) gives telegraph but no attacker reaction.

**Options:**
1. **Feint move:** A "feint" has short wind-up, low damage, but triggers defender reaction. If defender parries, feint can convert to real attack (complex) or just wastes their parry.
2. **Abort window:** First 10–15% of wind-up, attacker can abort → short recovery. Defender's early parry could "draw" an abort. STATE_MACHINE_PARRY_REALISM §3.8.
3. **Archetype telegraph:** OVERHEAD (long wind-up) = easier to read; QUICK_SLASH (short) = harder. Already partially there via windup_multiplier. Could add "telegraph_factor" so defender gets more effective_wind_up vs slow attacks.

**Effort:** Medium (needs UI/input for abort); Feint = Medium–High.

---

#### D. Multiple Parries and Chained Defense

**HEMA principle:** Exchanges can have multiple parries; "parry-riposte, parry-riposte" in some systems. Double hits when both attack.

**Current:** `passive_parry_attempted` = one parry per incoming attack. No second parry.

**Options:**
1. **Second parry at reduced capacity:** After first partial parry, allow second attempt with e.g. 50% capacity, longer reaction. Represents "rolling" or chained parry.
2. **Explicit parry moves as post-deflect option:** After parry_deflect, defender could choose `parry_thrust` etc. as a riposte. Currently parry moves exist but are never chosen (AI uses non-parry only). Would need combat flow to offer riposte after deflect.

**Effort:** Low (second parry) to Medium (riposte flow).

---

#### E. Cutting Direction vs Parry Line

**HEMA principle:** Parries form a "house of safety" relative to 8 cutting directions. Some parries cover certain lines better (e.g. high vs low, left vs right).

**Current:** No cutting direction or parry line. Parry is generic.

**Options:**
1. **Line modifier:** Each move has `cutting_line` (e.g. high_left, low_right). Defender's "effective" parry varies by whether their last action/guard matches the line. E.g. if defender just did a high parry, low attack gets a bonus (defender wrong line).
2. **Simpler:** OVERHEAD attacks slightly harder to parry (commitment from above); horizontal (slash) easier. Archetype-based modifier only.

**Effort:** Medium–High (full line model); Low (archetype modifier).

---

#### F. Bind and Blade Contact

**HEMA principle:** After parry, blades can bind. In the bind, structure and blade control matter; heavier blade doesn't automatically win (per sword design research).

**Current:** parry_deflect = full stop; attacker gets off_balance. No explicit bind state.

**Options:**
1. **Bind window:** After full deflect, "bind_duration" where next attack from attacker is penalized (they're still in contact). Adds a short vulnerable period.
2. **Revert to current:** Off-balance already models "deflect cost." Bind is implicit.

**Effort:** Low (extend off_balance) to Medium (explicit bind).

---

#### G. Timing Tuning

**Current values vs HEMA research:**

| Parameter | Current | Research | Notes |
|-----------|---------|----------|-------|
| Base reaction | 0.24 s | 200–250 ms simple; 400–600 ms with decision | 0.22 is fast; 0.24–0.26 more conservative |
| Attack execution | 200–300 ms (HEMA) | Your wind-up ~0.4–0.7 s | Wind-up includes telegraph; longer than pure execution |
| Commitment fraction | 0.2 | Telegraph before full commitment | Reasonable; could test 0.15–0.25 |

**Options:**
1. **Reaction:** PASSIVE_PARRY_BASE_REACTION_S 0.24 (implemented).
2. **Wind-up by archetype:** QUICK_SLASH already has windup_mult 0.8. Ensure fast attacks have proportionally shorter telegraph for defender (they're harder to react to).

---

#### H. Riposte / Parry-Counter Flow

**HEMA principle:** Parry is often followed by immediate counter (riposte). Your moves include parry_thrust, parry_cut, etc., but they're never selected.

**Current:** Parry is passive only. Explicit parry moves exist in weapon data but aren't used in normal flow.

**Options:**
1. **Post-deflect riposte:** After parry_deflect, defender automatically gets a "free" attack (or reduced cost) using a parry-counter move. Or: defender's next action can be a parry move at reduced gauge cost.
2. **AI uses parry moves after deflect:** When defender just deflected, AI could prefer parry_thrust/parry_cut for next action (faster, thematically correct).

**Effort:** Medium (flow change); Low (AI bias).

---

#### I. Distance and Measure

**HEMA principle:** Fencing is about measure (distance). At long measure, thrusts and reach matter; at close, cuts and grapples.

**Current:** No explicit distance. All attacks resolve the same way.

**Options:**
1. **Weapon reach:** Weapons have melee_range. Spear > sword > dagger. Could affect hit chance or who can target whom. Large system change.
2. **Defer:** Keep current abstraction; reach already influences via weapon choice (dagger vs spear).

**Effort:** High.

---

### 3. Summary Table

| Improvement | HEMA fidelity gain | Effort | Recomm. |
|-------------|--------------------|--------|---------|
| Strong/weak (archetype modifier) | Medium | Low | ✓ Good next step |
| Guard / readiness | High | Low–Med | ✓ High value |
| Second parry (reduced) | Medium | Low | Optional |
| Post-deflect riposte flow | High | Medium | ✓ Thematic |
| Feint or abort | Medium | Medium | Optional |
| Cutting line / archetype | Low–Med | Low (arch) to High (full) | Archetype only: Low |
| Reaction time 0.24 s | Low | Trivial | Tune if needed |
| Defensive stance action | High | Medium | If adding actions |

---

### 4. Recommended Implementation Order

1. **Guard/readiness** — Parry capacity or reaction scaled by a guard factor. Highest realism gain for state-machine work already in place.
2. **Strong/weak archetype modifier** — Add `parry_contact_quality` to OVERHEAD, SLASH, etc. OVERHEAD = defender more likely to catch weak.
3. **Post-deflect riposte** — After parry_deflect, give defender a bonus toward using parry_thrust/parry_cut (or reduced gauge cost for next action).
4. **Reaction time** — 0.24 s (implemented).
5. **Second parry at 50% capacity** — Allow one more attempt after partial, with strong penalty.
6. **Feint or abort** — Only if you want a deeper tactical layer and can support the input flow.

---

---

### 5a. Quick Attacks and Goblin Parries (Medieval Combat Research)

#### Research Summary

**Fiore de’i Liberi (Flos Duellatorum, c. 1409) – Sword vs Dagger**
- Dagger vs sword: Defender has “significant advantage” if they know the techniques (Boar’s Tusk guard, Narrow Play).
- Key insight: Dagger defender must **deflect**, not absorb. “Beat back” (rebatter) the sword—redirect, don’t block.
- Narrow Play (zogo stretto): Close range, deflect cuts/thrusts with quick arm/hand movement, then strike.
- Arms and hands must move **quickly** to counter attacks.

**Implications for the system:**
1. **Light weapons (dagger) vs heavy:** Already modeled via mass-disparity redirect bonus; light weapon deflects by angle.
2. **Blade movement time:** Light weapon + weak user = slow blade movement (clamp). Light weapon + strong user = fast. **Goblin with dagger** gets 0.5× base movement (0.065 s) vs goblin with sword (0.26 s). So goblins parry better with daggers—matches Fiore.
3. **Most contacts blade-on-blade (COMBAT_PARRY_MISS_RESEARCH):** HEMA longsword: 57–80% of contacts are parry/block. Even when "too late" for a full parry, defender often gets reflexive/partial blade contact. **Late parry** gives minimal capacity (22%) so quick attacks and goblin-vs-human still resolve as partial parries, not full hits.

#### Implemented Changes

| Change | Location | Effect |
|--------|----------|--------|
| PARRY_DEFLECT_THRESHOLD 1.08 | CombatManager | Fewer full deflects, more partials |
| PARRY_TECHNIQUE_VARIANCE 0.15 | CombatManager | Noisier parry execution |
| PASSIVE_PARRY_BASE_REACTION_S 0.24 | EntityPainConsciousness | Slightly fewer “in time” parries |
| PARRY_LATE_CAPACITY_FLOOR 0.22 | CombatManager, AttackResolver | When too late for full parry, defender still attempts reflexive parry (usually partial) |

#### Further Options (not yet implemented)

- **Goblin weapon preference:** AI could prefer dagger when defending vs larger attackers (Fiore-style deflection).
- **Strong/weak contact:** OVERHEAD exposes more weak of blade; add parry_contact_quality modifier.
- **Guard/readiness:** Post-parry or “on guard” improves next parry capacity.

---

### 6. What to Defer

- **Full cutting-line model** — High complexity; archetype-level approximation is enough.
- **Explicit distance/measure** — Large change; current abstraction is workable.
- **Bind as distinct state** — Off-balance already captures most of the effect.

---

<a id="hema-zones-feints-flurries-investigation"></a>

## Source: `HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md`

## HEMA Zones, Attack Paths, Flurries & Feints: Adaptation Investigation

Investigation into how HEMA zone systems, weapon positioning, attack paths, and engagements (flurries, parries, feints) can be adapted for Fallen Paths' abstract combat system.

---

### 1. Your Current System: Quick Reference

| Element | Fallen Paths | Notes |
|--------|--------------|-------|
| **Body parts** | 6: head, chest, left_arm, right_arm, left_leg, right_leg | BodyPartConstants; sub-regions per part |
| **Target selection** | `target_part` optional in actions; weighted random when absent | AI picks (target_id, move_id); target_part from choice or BodyPartConstants.get_weighted_random_part |
| **Guard** | Scalar (0.4 when attacking, rises when idle) | Zone-agnostic; readiness × guard = parry capacity |
| **Attack types** | cut/thrust/blunt; archetypes (oberhau, slash, stab, etc.) | move_id → archetype_id → velocity_factor, recovery_mult |
| **Defense** | Parry (capacity vs momentum), dodge, deflection | Parry_deflect, parry_partial, miss, dodge |
| **Timing** | Wind-up → execute → recovery; gauge-based readiness | Mental stack layers; _is_being_targeted |
| **Engagement** | None (soft engagement in MENTAL_STACK doc) | Could add engaged_with_id |

---

### 2. HEMA Zone Systems: Overview

#### 2.1 Liechtenauer / German Longsword

**Four lines / Vier Leger (four guards):**

- **Ochs** (Ox) — upper thrusting guard; point high
- **Pflug** (Plow) — lower thrusting guard
- **Alber** (Fool) — low, exposed
- **Vom Tag** (Day/Roof) — high, blade above head

Guards cover **high, low, left, right**. Parries use the same strikes (Oberhau, Unterhau) that end in these guards—Oberhau ends in Plough, Unterhau ends in Ox. Attack paths are not arbitrary: cuts flow through guards (e.g., high cut passes Tag → Longpoint → Fool).

#### 2.2 Meyer

**Body divisions:** Four quarters (upper/lower left and right). Head subdivided into **four zones** for precise close-range targeting.

**Guards:** Same four primary (Ochs, Pflug, Tag, Alber) plus secondary (Zornhut, Langort, etc.). Key insight: **guards are transitional, not static**—a cut flows through multiple guards. E.g., Oberhau: Tag → Longpoint → Alber.

**Cuts as attack paths:**
- **Straight cuts:** Oberhau (high), Zornhau (diagonal), Mittelhau (horizontal), Unterhau (low)
- **Inverted cuts:** Schielhau, Krumphau, Zwerch, etc.

Each cut has an implied **path** and **target zone**. Zornhau: shoulder → opponent's left (head/face/chest). Unterhau: from below → opponent's arm/head.

#### 2.3 Italian Rapier / Bolognese

**Lines:** Inside (between fencers), Outside (toward opponent's outside). High/low as well. Directional terms: *dritto* (right), *riverso* (left).

**Feint:** Threaten one line to draw parry, then disengage to hit another. Single-tempo action; feint is a *cavazione* (disengage) that baits a response.

#### 2.4 Kingdom Come: Deliverance (game)

5 zones: head, left upper, right upper, left lower, right lower. Chest merged into upper. Directional block must match attack direction.

---

### 3. Zone Mapping: HEMA → Fallen Paths

#### 3.1 Direct Mapping

| HEMA / Source | Zones | Fallen Paths Equiv | Notes |
|---------------|-------|--------------------|-------|
| Liechtenauer | High, low, left, right (4 lines) | — | Lines, not body parts; map to **attack direction** |
| Meyer | 4 quarters + 4 head zones | 6 parts cover this | quarters ≈ chest + arms + legs; head 4 zones → head |
| KCD | 5 (head, L/R upper, L/R lower) | 6 parts | Add chest; L upper ≈ left_arm (+chest left); R upper ≈ right_arm |
| Italian | Inside / outside | — | More about blade position; less direct body mapping |

#### 3.2 Attack Path as (from_guard, to_part) or (cut_type, target_part)

**Option A: Cut type implies path**
- Oberhau → typically head, maybe chest (high line)
- Unterhau → legs or low arm (rising)
- Zornhau → diagonal: right shoulder → left_head, left_arm, chest
- Mittelhau → horizontal: left_arm, right_arm, chest

You already have move_ids (oberhau, unterhau, slash). Each could have an optional `preferred_parts: Array` or `path_zones: Array` to bias target selection. No new UI—mental stack scores by "cut suits part."

**Option B: Explicit attack path (from_zone, to_zone)**
- Stored as `attack_path: { "from": "high_right", "to": "head" }`
- Defender's guard_zone can counter specific paths. E.g., guard "high_right" defends against attacks from that line.
- More granular but more state.

**Option C: Zone-specific guard (recommended minimum)**
- Per KINGDOM_COME_ABSTRACT_REPLICATION: `guard_zone: String` = one of your 6 parts.
- Attack to guarded part → parry easier (or mandatory). Attack to unguarded → normal resolution.
- Fits Liechtenauer "Oberhau parries Oberhau" — same-line parry; different line = hit. Your "line" = body part.

---

### 4. Adapting Zones for Your System

#### 4.1 Minimal: Target Part + Cut Compatibility

Add to move/archetype data:
```gdscript
# In WeaponConstants or per-move
# preferred_parts: parts this cut naturally targets (optional; for AI scoring)
oberhau: { ..., preferred_parts: ["head", "chest"] }   # high line
unterhau: { ..., preferred_parts: ["left_arm", "right_arm", "left_leg", "right_leg"] }  # rising
slash: { ..., preferred_parts: ["left_arm", "right_arm", "chest"] }  # horizontal
thrust: { ..., preferred_parts: ["head", "chest", "left_arm", "right_arm"] }  # point threatens center
```

Mental stack layer 6 (attack): when scoring (target_id, move_id, target_part), add `cut_match_bonus` if target_part in preferred_parts. No guard yet; just better target selection.

#### 4.2 Low: Zone-Specific Guard

Add `guard_zone: String` per combatant (see KINGDOM_COME_ABSTRACT_REPLICATION §2.2).

- When attacking part P: if defender.guard_zone == P → parry capacity × 1.5 (or block mandatory).
- Else: normal parry.
- Defender chooses guard each "turn" or when entering WAITING. AI: guard the part they expect to be attacked (from telegraph or threat).

#### 4.3 Medium: Guard + Attack Path Modifier

- Guard covers one part. Attack has `path` or `line` (high/low/inside/outside).
- If attack line matches defender's guard "line" (e.g., both high) → parry bonus even if exact part differs. Requires mapping parts to lines:
  - High: head
  - Mid: chest, arms
  - Low: legs

Then: `guard_line: "high"` defends head well, and partially chest. Simpler than 6-part guard.

#### 4.4 High: Full Meyer-Style Flow

- Track `last_guard` or `weapon_position` per combatant. Cuts transition through guards.
- Next attack's wind-up or recovery depends on previous guard. E.g., Oberhau ends in Plough → next move from Plough is faster than from Alber.
- Most complex; probably overkill for abstract system unless you want deep simulation.

**Recommendation:** Start with 4.1 (cut–part compatibility) and 4.2 (zone guard). Gives zone feel without heavy implementation.

---

### 5. HEMA Engagements: Flurries, Parries, Feints

#### 5.1 What the Documents Describe

**Tempo:** Every action commits the fencer for a moment. Reversing requires another action. Exploit commitment windows.

**Parry–riposte chains:** Parry → immediate counter. Liechtenauer: parry with Zornhau, end in Plough, thrust. Sweeping parries deflect diagonally. Absetzen = thrusting parry (counter-attack as parry).

**Feints:** Threaten one target/line to draw parry; disengage; hit the other. Giganti: feint is a cavazione that baits response. Single-tempo effective action.

**Flurries / rapid exchanges:**
- HEMA tournaments: 70–90% of exchanges end in *some* hit (clean, afterblow, or double).
- Double hits: both land ~7–40% depending on ruleset.
- Afterblow: hit after initial strike; discourages suicidal commitment.
- Binding: blades in contact; next action is bind resolution (wind, thrust from bind, etc.).

**Liechtenauer "Before" and "After":** Seize initiative ("Before") or take it back ("After"). Not turn-based—continuous flow.

#### 5.2 Translation to Fallen Paths

Your system is **discrete** (wind-up → execute → recovery, gauge-based). HEMA is **continuous**. Translation = capture the *feel* with state and timing rules.

##### 5.2.1 Parry–Riposte (You Have This)

- Parry_deflect → attacker in recovery, defender in WAITING.
- Perfect block / riposte: on parry_deflect, set `riposte_priority` on defender. Next tick, defender acts first or at reduced cost (see KINGDOM_COME doc).
- Master strike: parry_deflect in early wind-up → auto counter.

##### 5.2.2 Feints

**Feint as "threaten one part, hit another":**
- Commitment: attacker declares `feint_part` and `real_part` (or `feint_part` only; real = unguarded).
- Defender reacts to feint_part (guard or parry choice). If defender guarded feint_part, real_part is unguarded → attack to real_part gets bonus or guaranteed hit chance.
- Cost: feint could add slight wind-up (extra 0.1s) or gauge cost. Reward: bypass guard.

**Implementation options:**
- **A. Feint move type:** New move_id `feint_slash` with `feint_part`, `real_part`. Two-phase: wind-up shows feint, execute hits real. Defender must "read" or guard broadly.
- **B. Feint as target bait:** Attacker commits to target_part at wind-up start (telegraph). Defender can set guard_zone = that part. If attacker has feint: actual target_part ≠ telegraph. Defender guarded wrong part → parry penalty.
- **C. Probabilistic feint:** When choosing attack, X% chance to "feint" (attack different part than defender expects). Defender's reaction uses probabilistic guess. Simplest.

**HEMA consistency:** Feint = threaten line A, hit line B. Your lines = parts. So feint = (telegraph_part, actual_part) with telegraph_part ≠ actual_part.

##### 5.2.3 Flurries

**From MENTAL_STACK_ENGAGEMENT_INVESTIGATION:**

- **Option 1 (Soft Lock):** Engagement = `engaged_with_id`. No mechanical change; AI prefers attacking engaged target.
- **Option 2 (Counter Window):** When A winds up on B, B gets counter window—spend partial gauge for immediate counter.
- **Option 3 (Flurry Sub-Phase):** Multiple blows in quick succession (2–4) before reset.

**HEMA flurry feel:**
- Binding: parry_deflect could start a "bind" state. While bound, only bind-resolution moves (short thrust, push). Your system could add `bound_with_id`, `bound_until`, and restrict actions.
- Tempo exploitation: Enemy in recovery = high-value target. You already have "enemy in recovery" in mental stack. Enhance: recovery = soft "flurry opportunity" (next attack gets initiative bonus).
- Afterblow: When A hits B, B can land "afterblow" if B's action resolves within a short window. Implement: on hit, if B has pending_attack and it resolves before A's recovery ends, B's hit counts (possibly reduced damage). Discourages reckless commitment.

##### 5.2.4 Double Hits

HEMA: 7–40% doubles. Your system: one attack resolves at a time. To approximate:
- When A and B both have pending attacks and are targeting each other: resolve in initiative order. If both "hit" in same exchange, you could apply both damages (double hit) or first hit "wins" and second is cancelled/partial.
- Simpler: keep single-resolution; doubles emerge from rapid back-and-forth (flurry option 3) where both land hits in sequence.

---

### 6. Feint Implementation Sketch

#### 6.1 Data

```gdscript
# Extend action
action = {
  "target_id": 2,
  "move_id": "slash",
  "target_part": "head",        # real target
  "feint_part": "chest"         # optional; telegraph/feint target
}
```

#### 6.2 Flow

1. **Wind-up start:** Attacker commits. Defender sees telegraph: `feint_part` if present, else `target_part`.
2. **Defender reaction:** Chooses parry or guard_zone. If guard_zone == feint_part and target_part != feint_part → defender guarded the wrong part.
3. **Execute:** Parry capacity vs momentum. If defender guarded wrong part (and no universal guard), parry capacity × 0.5 or similar.
4. **Cost:** Feint could use `windup_multiplier` 1.1 (slightly longer) or extra gauge.

#### 6.3 AI: When to Feint

- If defender has high parry_rate or frequently guards our preferred target: feint to draw guard, hit elsewhere.
- Mental stack / yomi: track `defender_guard_tendency`. If they often guard head when we attack head, feint head → hit chest.
- Feint requires `target_part` and `feint_part` to be chosen; adds to action space.

---

### 7. Flurry Implementation Sketch

#### 7.1 Counter Window (Option 2)

- When A enters WIND_UP targeting B, set `B.counter_window_until = now + A.wind_up_duration * 0.8` (or until execute).
- If B's gauge >= 50% during this window and B chooses "counter" (parry or counter-attack): B spends 50% gauge, gets immediate action that resolves *before* A's attack. Order: B's counter resolves first, then A's (if A still alive).
- Creates parry–riposte and "seize tempo" feel.

#### 7.2 Flurry Sub-Phase (Option 3)

- When A attacks B and both survive: enter `STATE_IN_FLURRY` with `flurry_remaining = 3`.
- Resolve A's attack. If B can respond (gauge, alive): B gets instant counter (no full wind-up, reduced wind-up or 0). Resolve B's. If A can respond: A gets instant counter. Repeat until flurry_remaining == 0 or one dies.
- Disengagement: both RECOVERING; flurry ends.

#### 7.3 Afterblow

- On hit: target gets `afterblow_window` until attacker's recovery ends.
- If target has pending attack that would have resolved in that window: allow it to resolve as "afterblow" (maybe 50% damage to reflect desperate counter). Attacker takes damage.
- Reduces "all-in" commitment; matches HEMA ruleset feel.

---

### 8. Summary: Adaptation Priorities

| HEMA Concept | Adaptation | Complexity | Value |
|--------------|------------|------------|-------|
| **Zones / body divisions** | 6 parts already match. Add preferred_parts per cut. | Low | Medium |
| **Zone-specific guard** | guard_zone: String; parry bonus when guarded. | Low | High |
| **Attack path** | preferred_parts per move; optional path modifier. | Low | Low–Medium |
| **Parry–riposte** | riposte_priority on parry_deflect. | Low | High |
| **Master strike** | Early parry_deflect → auto counter. | Low | Medium |
| **Feint** | feint_part ≠ target_part; defender guards wrong part. | Medium | High |
| **Counter window** | Partial gauge for counter during enemy wind-up. | Medium | High |
| **Flurry sub-phase** | Multiple exchanges before reset. | High | Medium |
| **Afterblow** | Hit during attacker recovery = partial counter damage. | Medium | Medium |
| **Binding** | bound state, restricted moves. | High | Low (niche) |

#### Recommended Implementation Order

1. **Zone guard** (guard_zone + parry modifier) — highest impact for zone feel.
2. **Riposte priority** — you've designed it; implement.
3. **Cut–part compatibility** (preferred_parts) — improves AI targeting.
4. **Feint** (telegraph vs real target) — adds mind-games.
5. **Counter window** — enables tempo play.
6. **Afterblow** (optional) — if you want HEMA-ruleset feel.
7. **Flurry sub-phase** (optional) — if you want dramatic exchanges.

---

### 9. Implementation Approaches: Realism & HEMA Accuracy Comparison

A detailed comparison of implementation options for each system, evaluated against historical sources and HEMA practice.

---

#### 9.1 Zone / Guard Systems

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Scalar guard only** | Current: single 0–1 guard value, no zones | Low | Low | Simple; already implemented | Ignores Liechtenauer/Meyer: guards cover specific lines. Historical sources say "Oberhau parries Oberhau" — same line. |
| **B. Single zone guard** | `guard_zone: String` = one of 6 parts; attack to guarded part → parry bonus | **Medium** | **Medium–High** | Matches KCD, Liechtenauer line concept. One part defended = others exposed. Simple. | Crude: real guards cover *lines* (high/low/left/right), not just single body parts. Meyer: guards are transitional. |
| **C. Line-based guard** | `guard_line: "high"|"low"|"inside"|"outside"`; parts mapped to lines; line match → parry | **High** | **High** | Matches Liechtenauer 4 guards, Italian inside/outside. "High" covers head; "low" covers legs. | More abstraction: lines ≠ exact anatomy. Need part→line mapping. |
| **D. Multi-zone guard** | `guard_zones: Array` = 2–3 parts defended (e.g. high guard = head + chest) | **Medium–High** | **Medium** | Reflects that guards cover *regions*. Alber exposes more than Ochs. | More state; balance: too many zones = universal guard. Historical: guards typically cover one "line" well. |
| **E. Guard as weapon position** | Track `last_guard` / `weapon_position`; next move's cost/speed from current position | **Highest** | **Highest** | Meyer: guards are transitional. Cut from Tag → Plough; next from Plough is faster. Full flow. | Complex; requires guard transitions, path-dependent moves. Probably overkill for abstract. |

**Verdict:** **B** or **C** offer best realism/code balance. C is more faithful to Liechtenauer (4 lines); B maps cleanly to your 6 parts. Historical: guards defended *lines*, not single points. **C** slightly more accurate; **B** easier to implement and explain.

---

#### 9.2 Attack Paths & Target Selection

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Weighted random** | Current: target_part from BODY_PART_TARGET_WEIGHTS when unspecified | Low | Low | Simple | Ignores cut geometry. Oberhau naturally goes to head; Unterhau to legs. Archaeological: head 40–92% of wounds; torso often 0–2%; arms low in battle, high in duel. |
| **B. preferred_parts per move** | Each move has `preferred_parts`; AI scores these higher | **Medium** | **Medium** | Cut type implies path. Oberhau → head; thrust → center. No new resolution rules. | Static; doesn't account for defender's guard. Historical: provoke to create opening, then strike. |
| **C. preferred_parts + guard interaction** | preferred_parts + guard_zone; unguarded preferred = bonus | **High** | **High** | Combines geometry and defender state. "Unguarded head" when in high guard = exploit. | Requires zone guard (9.1). |
| **D. Historical target weights** | Override weights by context: duel vs battle. Head heavy; torso thrust>cut; arms high in 1v1 | **High** | **High** | Sword STEM / Matzke: head dominant; torso cuts rare archaeologically; arms sniped in duels (patience, space). | Context flag (duel/battle) or environment. Battlefield: legs (Wisby 65% with shields), head. Duel: arms, head. |

**Verdict:** **C** for tactical play. **D** if you want archaeological/historical nuance (different scenarios). Your BODY_PART_TARGET_WEIGHTS already have head 1.2, chest 2.7 — consider *lowering* torso weight for cuts in duels to match sources (thrust torso, cut head/limbs).

---

#### 9.3 Feints

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No feint** | Only real attacks; no deception | Low | Low | Simple | Italian sources: feint is central. Giganti: *cavazione* baits parry. No mind-games. |
| **B. Feint as telegraph vs real** | `feint_part` ≠ `target_part`; defender sees feint; guards wrong part → parry penalty | **High** | **High** | Matches Giganti/Capo Ferro: threaten line A, disengage to B. Single-tempo action. Defender must read or guard broadly. | Two-phase commitment; defender reaction logic. Cost: feint should have slight wind-up (proportionally smaller than defender's parry motion — Fabris). |
| **C. Probabilistic feint** | X% chance actual target ≠ expected; defender guesses | **Medium** | **Medium** | Simple; no explicit feint_part. Emergent deception. | Not a committed feint — attacker doesn't "threaten" then redirect. Historical: feint is intentional provocation. |
| **D. Feint as provocation** | Feint = small motion to force defender to create tempo; then attack in that tempo | **Highest** | **Highest** | Dall'Agocchie: "Provocations... incite him to strike, so that one can attack him more safely." Your tempo = defender's parry attempt; you attack *during* it. | Complex: provocation phase, tempo window. Requires "attack during opponent's action" — counter window (9.5). |

**Verdict:** **B** is the best balance. **D** is most faithful to Dall'Agocchie but needs counter-window infrastructure. Feint cost: Fabris says your attack must be "proportionally shorter" than defender's response — implement as feint adding ~10% wind-up, but wrong guard = large parry penalty (e.g. ×0.5).

---

#### 9.4 Parry–Riposte & Master Strike

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Parry only** | parry_deflect → attacker recovery; defender stays WAITING | **Medium** | **Medium** | You have this. Defender survives. | Misses riposte. Liechtenauer: parry with Zornhau, end in Plough, thrust. Absetzen = parry *is* counter. |
| **B. Riposte priority** | parry_deflect → `riposte_priority`; defender acts first next tick | **High** | **High** | Matches "after parrying, then it's a tempo to attack" (Dall'Agocchie #5). Low implementation cost. | Slight delay (next tick). Historical: riposte can be same-tempo (dui tempi vs stesso tempo). |
| **C. Master strike (early parry)** | parry_deflect in early wind-up (<30%) → auto counter before attacker executes | **High** | **High** | KCD master strike. Liechtenauer: catch attack early = control. Mechanically: guaranteed counter. | Can feel overpowered; tune early % threshold. |
| **D. Absetzen (thrust-parry)** | Parry with thrust; no separate parry→riposte, attack *is* defense | **Highest** | **Highest** | Liechtenauer: Absetzen from Plough. Single action. | Needs "parry-thrust" as one move. You have parry_thrust; ensure it can trigger on incoming attack. |

**Verdict:** **B** + **C** both worth adding. **D** is already partially there (parry_thrust) — ensure it's selectable when defender is targeted and gets counter-attack resolution. Riposte = initiative; master strike = early-read reward.

---

#### 9.5 Tempo & Counter Windows (Dall'Agocchie's Five Tempi)

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No counter window** | Only act when gauge full; no interrupt | Low | Low | Current behavior. | Ignores "when he raises his sword... strike while his hand is rising" (#3). Or "when he raises his foot" (#5). Opponent committed = your opportunity. |
| **B. Counter window (partial gauge)** | During enemy wind-up, spend 50% gauge → immediate action, resolves first | **High** | **High** | Captures tempo #3 (hand raising), #4 (guard change), #5 (foot lift). "Time employed to make one movement cannot be employed to make any other" (Fabris). | Order of operations: counter resolves before attack. Attacker may "lose" to counter. Balance: cost (50% gauge), only when wind-up active. |
| **C. Counter + feint synergy** | Feint triggers defender parry (tempo); counter window allows attacker to hit during that parry | **Highest** | **Highest** | Dall'Agocchie provocation: feint creates tempo, attack in it. Defender's parry = commitment; you strike during. | Requires both feint (9.3) and counter window. Complex. |
| **D. Five tempi as discrete triggers** | Explicit check: is opponent (a) in wind-up, (b) changing guard, (c) stepping, (d) post-parry, (e) blow passed? Each = opportunity | **Highest** | **Highest** | Most faithful to Dall'Agocchie. | Five conditions to track; guard/step state may not exist. Granular but heavy. |

**Verdict:** **B** captures the core: "opponent committed = your opportunity." **D** is ideal for maximum accuracy but likely overkill. Implement **B**; optionally, *scale* counter cost by which "tempo" applies (e.g. wind-up = 50%, guard change = 40% if you add guard state).

---

#### 9.6 Flurries, Binding, Afterblow

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. Single attack resolution** | Current: one attack → resolve → recovery | **Medium** | **Medium** | Simple. Matches "single decisive blow" in some chronicles. | Misses rapid exchanges. HEMA: 70–90% of exchanges end in *some* hit. Archaeological: multiple wounds common. |
| **B. Soft engagement** | `engaged_with_id`; AI preference only; no mechanical change | Low | Low | Minimal. | No flurry feel. Engagement is cosmetic. |
| **C. Counter window only** | B from 9.5; enables back-and-forth when both have gauge | **High** | **High** | Tempo-driven exchanges. No new phase. Both can counter in sequence. | Emergent flurry from repeated counter windows. May need cap (max 2 counters per "exchange") to avoid infinite. |
| **D. Flurry sub-phase** | 2–4 blows in quick succession; reduced wind-up; then reset | **Medium–High** | **Medium** | Dramatic. Matches "multiple wounds" from archaeology. | Ernst Fechten / Liechtenauer: at *close* measure in krieg, quick successive thrusts from bind. At *wide* measure, flurries fail — opponent counters. Your abstract system has no measure; flurry could feel arbitrary. |
| **E. Afterblow** | On hit, target's pending attack can resolve during attacker recovery (e.g. 50% dmg) | **High** | **High** | HEMA rulesets use this to discourage suicidal commitment. Historical: "strike only to be hit shortly thereafter" = failure (Ernst Fechten). | Implement as: if target has attack in progress when hit, it resolves as afterblow. Tune damage (50%? 100%?). |
| **F. Binding state** | parry_deflect → `bound_with_id`; while bound, only bind-resolution moves (thrust, wind) | **Highest** | **Highest** | Liechtenauer krieg: blades in contact; winden, thrust from bind. Close measure critical (30–45 cm). | New state, restricted move set. Ernst Fechten: at *wrong* measure, bind techniques fail. Your system has no distance. Complex. |

**Verdict:**
- **Flurry:** **C** (counter window) gives emergent exchanges; **D** (sub-phase) is optional for dramatic set-pieces. Historical: flurries work at *close* measure; your abstract model may not support measure, so **D** is a stylistic choice.
- **Afterblow:** **E** — strongly recommended. Aligns with HEMA and historical sentiment ("don't get hit back").
- **Binding:** **F** is most accurate for Liechtenauer krieg but requires measure (distance) and new moves. Skip unless you add spatial measure.

---

#### 9.7 Measure (Distance) — Not Currently Modeled

| Approach | Description | Realism | HEMA Accuracy | Pros | Cons |
|----------|-------------|---------|---------------|------|-----|
| **A. No measure** | Current: abstract; no distance | **Low** | **Low** | Simple. | Historical: measure is *fundamental*. Close/mid/long/out. "Attack in measure if it can land in one tempo." Bind at ~30–40 cm. At wide measure, everything can be countered (Ernst Fechten). |
| **B. Implicit measure** | "In range" = engaged; "out of range" = not targeting | **Low** | **Low** | Binary. | Crude. No "close vs wide" bind. |
| **C. Measure bands** | Close / mid / long; different parry/counter efficacy by band | **High** | **High** | Bind at close = thrust from bind works. Wide = parry easier, counter harder. | Requires distance state. How is it set? Adjacent tiles? Abstract "steps to opponent"? |
| **D. Tempo-as-measure** | "In measure" = can hit in one tempo (one wind-up). "Out" = need to close first | **Medium** | **Medium** | Abstract: no spatial distance. "Closing" = action that enables attack. | Conflates distance and readiness. Possible for abstract system. |

**Verdict:** Your system is abstract (no tiles/physics). **D** (tempo-as-measure) could work: "approach" action that reduces next-attack wind-up, or "out of measure" = must spend a "close" action first. **C** would need a distance abstraction (e.g. steps_to_opponent 0–3). **A** is acceptable if you accept that measure is implicit in "who can act when" (gauge, recovery).

---

#### 9.8 Summary: Realism-Optimized Implementation Path

| Priority | Feature | Best Approach | Realism | Notes |
|----------|---------|---------------|---------|-------|
| 1 | Zone guard | B (single part) or C (line) | High | Line-based slightly more accurate. |
| 2 | Riposte priority | B | High | parry_deflect → next-tick initiative. |
| 3 | Master strike | C | High | Early parry → auto counter. |
| 4 | Target selection | C (preferred_parts + guard) | High | Head priority; cut–part match; unguarded bonus. |
| 5 | Feint | B (telegraph vs real) | High | feint_part, cost ~10% wind-up. |
| 6 | Counter window | B | High | 50% gauge during enemy wind-up. |
| 7 | Afterblow | E | High | Pending attack during hit = resolves at reduced damage. |
| 8 | Historical weights | D (optional) | High | Duel vs battle: head/arms vs head/legs. |
| 9 | Flurry sub-phase | D (optional) | Medium | Stylistic; measure not modeled. |
| 10 | Binding | F (defer) | Highest | Requires measure; new moves. |
| 11 | Measure | D (tempo-as) or C (bands) | High | Only if adding spatial/distance. |

**Trade-off:** Full Liechtenauer fidelity (measure, bind, winden) would require significant new systems. The path above captures the *tactical* and *temporal* essence (tempo, riposte, feint, counter, afterblow, zone guard) without spatial simulation. Archaeological and historical sources support: head focus, thrust-to-torso preference, arm sniping in duels, and "don't get hit back" (afterblow mindset). Your system can approximate all of these with the approaches in this section.

---

### References

- **HEMA_VS_KCD_SOURCE_ANALYSIS.md** — Separates historical longsword sources from KCD game design; use for physical realism prioritization.
- **LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md** — Line-based guard options, simulated vs 3D limitations, physically realistic afterblow model.
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md
- MELEE_SIMULATION_AI_INVESTIGATION.md
- COMBAT_PARRY_MISS_RESEARCH.md
- Meyer's longsword 101 (HEMA 101): Openings, guards, cuts
- Liechtenauer's longsword 101 - Part 5: Parries
- Italian rapier: lines, feints, disengages (Giganti, Capo Ferro)
- HEMA tempo, doubles, afterblows (Sword STEM, Thokk Research)
- BodyPartConstants.gd, CombatManager.gd, AttackResolver.gd

---

<a id="hema-vs-kcd-source-analysis"></a>

## Source: `HEMA_VS_KCD_SOURCE_ANALYSIS.md`

## Historical Longsword vs. KCD Game Design: Source Analysis

Investigation to separate recommendations based on **actual Liechtenauer/Meyer/medieval longsword sources** from those that are **Kingdom Come: Deliverance game design choices**. Purpose: identify which implementations would be more accurate for **physical realism** when simulating historical combat.

---

### 1. Methodology

For each mechanic, we trace:
- **Historical source**: Liechtenauer (Zettel, glosses), Ringeck, Meyer, Fiore, Italian masters (Dall'Agocchie, Giganti, Fabris), archaeological evidence (Matzke), HEMA research (Sword STEM)
- **KCD implementation**: What the game does and how it presents it
- **Verdict**: Historical / KCD hybrid / KCD-only / Neither

---

### 2. Zone Systems & Directional Guard

#### Historical Longsword

**Liechtenauer / Meyer:** Four primary positions (Vier Leger):
- **High** (Vom Tag) — blade above/at shoulder
- **Fool** (Alber) — low, center or side
- **Ox** (Ochs) — point forward, hilt raised
- **Plough** (Pflug) — point forward, hilt at hips

These are **weapon positions that cover lines** (high, low, left, right), not body-part targets. The HEMA 101 Liechtenauer guards article: "They are better described as 'noteworthy positions'... The 'guards' do not guard you in the sense that they block attacks (although they can do!). Think of them as positions of being 'in guard', i.e. ready to do something."

**Key:** Guards are **lines/directions** (high, low, left, right). Parries use the same cuts that end in these positions — "Oberhau parries Oberhau" (like covers like). An Oberhau ends in Plough; an Unterhau ends in Ox. The geometry of the strike determines what it defends against.

**Body targeting:** Meyer divides body into four quarters (upper/lower left and right); head has four sub-zones for close work. Archaeological (Matzke): head 40–92% of wounds; torso 0–40%; arms/legs variable. Sources don't prescribe "5 zones" as attack directions.

#### KCD Implementation

- **5 zones**: Head, left upper, right upper, left lower, right lower
- **Directional block**: Hold block in one of these directions; attack from unblocked direction = hits
- **Design origin**: Controller input (stick or keys for directions), simplified for first-person gameplay

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Directional guard (cover one line, expose others) | **Yes** | No | Liechtenauer: guards cover lines. Same concept. |
| **4 lines** (high/low/left/right) | **Yes** | No | Historical uses 4. |
| **5 body zones** as input directions | **No** | **Yes** | KCD uses 5 for controller ergonomics. Historical: 4 weapon lines, body targeting separate. |
| Guard = block in one direction | Partial | Yes | Historical: guard is *position* from which you parry/counter; parry uses a cut. KCD: static block direction. |

**For physical realism:** Use **line-based guard** (high/low/inside/outside or 4 lines) rather than body-part guard. Line-based maps to Liechtenauer's 4 positions. Body-part guard (6 parts) is acceptable as an abstraction of "which line is defended" if you map parts to lines (head=high, legs=low, etc.).

---

### 3. Combos (Sequential Strikes → Bonus Finisher)

#### Historical Longsword

**Liechtenauer / Meyer:** No evidence of scripted combo sequences (e.g. "head → right upper → left lower → finisher"). The ARMA Mastercuts essay: "Liechtenauer's instruction to make rapid strikes one after the other without pause" — continuous pressure, not prescribed sequences. Meyer's cuts flow through guards (Tag → Longpoint → Alber) but as *mechanics of a single cut*, not "land hit 1, then hit 2, then finisher."

**Archaeological:** Multiple wounds common (Matzke); fighters received several blows. That supports *flurries* and *repeated strikes*, not *scripted combos with bonus damage*.

#### KCD Implementation

- Sequential strikes to specific zones (e.g. head → R.upper → L.lower) → special finisher, bonus damage
- Learned from trainers; each weapon has unique combos
- "Harder to block" when executing combo
- **Source:** Fighting game design (Street Fighter, etc.). Warhorse consulted Fechtbücher but combos are a **gameplay mechanic** for engagement and late-game difficulty scaling.

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Combo sequences (head→arm→leg→finisher) | **No** | **Yes** | No historical source. Fighting game convention. |
| Rapid successive strikes | **Yes** | No | Liechtenauer: "rapid strikes without pause." |
| Bonus damage for sequence | **No** | **Yes** | Game balance. |
| "Harder to block" during combo | **No** | **Yes** | Game mechanic. |

**For physical realism:** **Do not implement combos** as KCD-style sequences. Prefer: (a) rapid exchanges via counter window / tempo, (b) binding → thrust from bind, (c) preferred_parts per cut type. Combo *progress* and *finisher bonus* are KCD, not historical.

---

### 4. Master Strike (Early Block → Automatic Counter)

#### Historical Longsword

**Meisterhau (Mastercuts):** The five *strikes* — Zornhau, Krumphau, Zwerchhau, Schielhau, Scheitelhau. These are techniques that (a) break specific guards, or (b) counter incoming attacks while simultaneously striking. ARMA: "The Mastercuts defensively close off a line of attack from the opponent while **simultaneously** counter-attacking."

**Critical:** "This is **not an issue of perfect timing**, as might be supposed, but rather one of **correct geometry**, put in place by the simple response mechanism of training." You choose the correct Meisterhau for the opponent's guard/attack; the strike *is* the parry. No "block then auto counter" — the attack and defense are one action.

**Absetzen:** Thrust-parry from Plough — parry with a thrust. Same idea: single action that defends and attacks. Not "block at perfect moment, then guaranteed counter."

#### KCD Implementation

- Block at exact moment (green icon) during opponent's swing → automatic, unavoidable counter
- Timing-based: player must react to visual cue
- "Master Strike" named after Meisterhau but **mechanically different**: KCD = timing window + guaranteed damage; historical = geometry + technique choice

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Parry + counter | **Yes** | No | Liechtenauer: parry with Zornhau, end in Plough, thrust. |
| **Timing-based** perfect block | **No** | **Yes** | Historical: geometry, not reaction timing. |
| **Automatic unavoidable** counter | **No** | **Yes** | Game balance; real counters can fail. |
| Early parry = better outcome | Partial | Yes | Catching attack early = control (Liechtenauer). But "auto counter" is KCD. |

**For physical realism:** Prefer **riposte priority** (parry_deflect → defender acts first) over **master strike** (guaranteed auto counter). Historical: successful parry puts you in position to thrust; the counter is not "unavoidable." Early parry could grant *initiative* or *reduced counter cost*, not guarantee. KCD's master strike is a game reward for timing, not physics.

---

### 5. Perfect Block & Riposte

#### Historical Longsword

**Dall'Agocchie (#5):** "Once you've parried your enemy's blow, then it's a tempo to attack." Parry creates opportunity. Riposte (thrust or cut from the parry position) is standard.

**No "perfect" vs "imperfect" block** in historical sources. A parry either works (you deflect, end in good position) or it doesn't. The concept of "block during swing = riposte priority" aligns: good parry → you're set to counter.

#### KCD Implementation

- "Perfect block": Block during opponent's swing (not before) → bullet-time, riposte with priority
- Visual cue (green shield) for timing
- Separates "hold block" from "timed block"

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Parry → counter (riposte) | **Yes** | No | Universal in sources. |
| **Timed** block (during swing) vs hold block | Partial | Yes | Historical: parry is an action (cut into theirs), not "hold block." But "parry during their strike" is correct. |
| Bullet-time / riposte priority | **No** | **Yes** | UX and game feel. |
| Defender gets next action | **Yes** | No | Matches "tempo to attack after parry." |

**For physical realism:** **Riposte priority** (parry_deflect → defender acts first or at reduced cost) is historical. The "perfect" vs "imperfect" distinction is acceptable as parry quality (full deflect vs partial). Avoid bullet-time; keep it as initiative/order of actions.

---

### 6. Feints

#### Historical Longsword

**Italian sources (Giganti, Capo Ferro):** Feint is central. Threaten one line to draw parry; disengage; hit the other. Single-tempo action. Dall'Agocchie: provocations "incite him to strike, so that one can attack him more safely." Fabris: attack tempo must be "proportionally shorter" than defender's response.

**German longsword:** Less explicit feint doctrine than Italian rapier, but Meyer describes cuts that deceive (Change Cut, Short Cut, etc.). The principle of "threaten to open" is shared across traditions.

#### KCD Implementation

- "Feinting": Hold attack, switch direction before release
- Uses the 5-zone input system
- No separate feint mechanic; feint = abort and re-aim

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Feint (threaten one target, hit another) | **Yes** | No | Italian sources, Meyer. |
| Direction switch during wind-up | Partial | Yes | KCD uses zone switch. Historical: disengage to different line. Same idea. |
| Feint as provocation | **Yes** | No | Dall'Agocchie. |

**For physical realism:** **Feint is historical.** Implement as telegraph vs real target (feint_part ≠ target_part). Cost per Fabris: feint should be proportionally shorter than defender's parry — slight wind-up increase acceptable; wrong guard = parry penalty. This is independent of KCD.

---

### 7. Kick

#### Historical Longsword

**Fiore:** Groin kicks, knee stomps in grappling contexts. **But** Fiore warns against striking below the knee in two-handed sword work while standing — leaves you exposed.

**Ringeck / Liechtenauer:** No prominent kick-to-break-guard in core longsword plays. Grappling (ringen am schwert) exists but is distinct. Ernst Fechten (Peters): "It is far better to wound or kill with your sword in krieg than to wrestle."

#### KCD Implementation

- Kick to break guard; staggers opponent
- Used when enemy is blocking
- Simple, reliable anti-block tool

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Kick in sword combat | Partial | No | Fiore has kicks in grappling. |
| Kick to **break guard** | **No** | **Yes** | No clear historical precedent. Likely game design for block-break. |
| Stagger/disrupt | Partial | Yes | Pommel strike, grappling exist. Kick as guard-break is KCD. |

**For physical realism:** **Kick-to-break-guard is KCD**, not well attested in longsword sources. If you add it, treat as game option. Historical alternative: pommel strike, or close to bind (measure) and thrust. Focus on sword techniques first.

---

### 8. Stamina

#### Historical Longsword

No "stamina bar" in sources. But: fatigue, wounds, and exhaustion matter. Ringeck: cut decisively; hesitation yields poor results. Psychological and physical fatigue would reduce effectiveness. Indirectly supported.

#### KCD Implementation

- Stamina depletes with block, attack, sprint, low health
- Low stamina → weak attacks, block breaks, vulnerable to finisher
- Standard action-game resource

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Fatigue affects performance | **Yes** | No | Physically true. |
| Stamina bar / resource pool | **No** | **Yes** | Abstraction for game pacing. |
| Block break when exhausted | Partial | Yes | Plausible; not explicitly in sources. |

**For physical realism:** Fatigue/readiness affecting power and parry is realistic. Your **gauge** or a stamina-like pool is an acceptable abstraction. Not a KCD invention; common in games. Physical basis: yes.

---

### 9. Counter Window (Act During Opponent Wind-Up)

#### Historical Longsword

**Dall'Agochelle's five tempi** (opportunities to strike):
1. After parrying
2. When his blow has passed outside your body
3. **When he raises his sword to harm you — strike while his hand is rising**
4. When he moves injudiciously from one guard to another, before fixed
5. **When he raises his forward foot** to step — he cannot defend while unsettled

**Fabris:** "The time employed to make one movement cannot be employed to make any other." Opponent committed = your opportunity.

#### KCD Implementation

- No explicit "counter window" — you act when your turn/stamina allows
- Perfect block / master strike require opponent to attack first; reaction-based

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Strike during opponent's preparation | **Yes** | No | Dall'Agochelle #3, #4, #5. |
| Partial gauge for immediate counter | **No** | N/A | Abstraction for discrete turn system. |
| "Opponent committed = your chance" | **Yes** | No | Fabris, five tempi. |

**For physical realism:** **Counter window is historical.** Implement as: during enemy wind-up (or guard change, or step if you model it), defender can spend partial gauge for immediate action that resolves first. This aligns with tempo #3, #4, #5. KCD doesn't have this explicitly; it's from historical sources.

---

### 10. Afterblow

#### Historical Longsword

**Ernst Fechten (Peters):** "Mutual kills are unacceptable in this craft; a proper defence protects as it places you into a position of advantage." "It does you little good if you can strike your opponent only to be hit shortly thereafter because you were not covered." The sentiment: don't get hit back. Liechtenauer's techniques from the bind are meant to protect you while you strike.

**HEMA rulesets:** Afterblow (strike back after being hit) exists to discourage suicidal commitment in sport. Historical *ethos*: if you hit and then get hit, you failed.

#### KCD Implementation

- No afterblow in standard combat
- Single resolution per exchange
- Attacker hits → target takes damage; no "target strikes back during attacker recovery"

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| "Don't get hit back" | **Yes** | No | Ernst Fechten, Liechtenauer. |
| Afterblow as ruleset mechanism | **No** | No | HEMA sport invention to penalize recklessness. |
| Model: hit then get hit = failure | **Yes** | No | Historical ethos. |

**For physical realism:** **Afterblow mechanic is realistic** — if you hit someone who has an attack in progress, their attack can resolve during your recovery (at reduced effect). This discourages all-in commitment and matches "don't get hit back." KCD omits it (gameplay simplification). Implement for realism.

---

### 11. Binding (Blades in Contact)

#### Historical Longsword

**Liechtenauer:** Binding (krieg) is central. "A master's fencing is rightfully at the sword." From the bind: winden, thrust, slice. **Measure is critical**: bind at ~30–40 cm; at wide measure, techniques fail. Ernst Fechten: at wrong measure, "nearly everything can be countered."

#### KCD Implementation

- Physics-based blade contact (30+ target zones, 4 armor layers)
- Swords clash and slide
- No discrete "bound" state with restricted moves
- Blades interact continuously via physics

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Binding central to technique | **Yes** | No | Liechtenauer, Ringeck. |
| Bind → thrust/winden only | **Yes** | No | Historical: from bind, specific actions. |
| Physics-based contact | Partial | Yes | KCD uses 3D/physics. You're abstract. |
| Discrete "bound" state | **Yes** | No | Would model krieg phase. |

**For physical realism:** **Binding is historical** and core to Liechtenauer. Implementing it in an abstract system requires: measure (close = bound), restricted move set while bound (thrust, wind, etc.). KCD approximates via physics; you'd need state. High fidelity, high cost. Defer unless adding measure.

---

### 12. Preferred Parts per Cut (Attack Path)

#### Historical Longsword

**ARMA Mastercuts:** "Remember that your target is always your opponent's head or body, never his weapon." Zornhau "hits the opponent in his upper left opening." Zwerchhau "targets include the head, the hands or the body." Cuts have natural trajectories: Oberhau → head; Unterhau → legs/arms; thrust → center (face/chest).

**Archaeological (Matzke):** Head dominant (40–92%); torso cuts rare; arms low in battle, higher in duel (hand sniping). Thrust to torso preferred over cut to torso in sources.

#### KCD Implementation

- 5 zones; player picks direction
- Cut type (slash/stab) affects which zones are natural
- No explicit "preferred parts" per move — player aims

#### Verdict

| Element | Historical? | KCD-Specific? | Notes |
|---------|-------------|---------------|-------|
| Cuts have natural targets | **Yes** | No | Oberhau→head, etc. |
| Head primary target | **Yes** | No | Sources + archaeology. |
| preferred_parts per move | **Yes** | No | Models cut geometry. KCD doesn't encode it explicitly. |

**For physical realism:** **preferred_parts per move is historical.** Oberhau → head, chest; Unterhau → legs, arms; thrust → head, chest, arms. Combine with guard (unguarded preferred = bonus). Independent of KCD.

---

### 13. Summary: Historical vs. KCD

| Mechanic | Historical Source | KCD Design | For Physical Realism |
|----------|-------------------|------------|----------------------|
| **Zone guard** | 4 lines (Liechtenauer) | 5 body zones | Use **line-based** (4) > body-part (6). |
| **Combos** | None (rapid strikes ≠ sequences) | Fighting game | **Skip.** Use tempo, counter, binding instead. |
| **Master strike** | Geometry, not timing; no "unavoidable" | Timing + guaranteed counter | **Skip** guarantee. Use riposte priority; early parry = initiative bonus. |
| **Riposte** | Parry → counter | Timed block → priority | **Implement.** Parry_deflect → defender acts first. |
| **Feint** | Italian, Meyer | Direction switch | **Implement.** feint_part ≠ target_part. Historical. |
| **Kick to break guard** | Not in longsword | Yes | **Skip** or treat as optional. |
| **Stamina** | Fatigue implied | Resource bar | Acceptable abstraction. |
| **Counter window** | Five tempi (Dall'Agochelle) | Not in KCD | **Implement.** Historical. |
| **Afterblow** | "Don't get hit back" | Not in KCD | **Implement.** Historical ethos. |
| **Binding** | Liechtenauer krieg | Physics approximation | **Defer** unless adding measure. |
| **preferred_parts** | Cut geometry, archaeology | Implicit in aiming | **Implement.** Historical. |
| **5 zones** | Not in sources | Controller input | Use **4 lines** or 6 parts with line mapping for realism. |

---

### 14. Revised Realism-Optimized Path

Prioritized by **historical source strength**, not KCD parity:

1. **Line-based guard** (4 lines) — Liechtenauer. Prefer over 5-zone.
2. **Riposte priority** — Dall'Agochelle, universal.
3. **preferred_parts + guard** — Cut geometry, archaeology.
4. **Feint** — Italian, Meyer.
5. **Counter window** — Five tempi.
6. **Afterblow** — Ernst Fechten ethos.
7. **Historical target weights** — Matzke, sources (optional).
8. **Early parry = initiative** (not auto counter) — Liechtenauer.
9. **Binding** — Defer (needs measure).
10. **Skip: combos, master strike guarantee, kick-to-break** — KCD/game design.

---

### References

- ARMA: "The Mastercuts - What They Are and What They Aren't"
- Chicago Swordplay Guild: "Defining Tempo in Italian Swordplay"
- Ernst Fechten: "On Measure in Krieg"
- HEMA 101: Liechtenauer guards, parries, Meyer cuts
- Sword STEM: "Historical Injury vs Modern Tournament Targeting"
- Matzke: "Armed and Educated"
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md

---

<a id="kingdom-come-abstract-replication-investigation"></a>

## Source: `KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md`

## Kingdom Come Combat: Abstract Replication with Mental Stack

An investigation into adapting Kingdom Come: Deliverance's combat system to work with Fallen Paths' mental stack, **without using 3D models**—using abstract data, 2D representation, or text instead.

---

### 1. Kingdom Come Combat: Core Elements

| Element | KCD Implementation | Abstract Equivalent |
|---------|-------------------|---------------------|
| **Attack directions** | 5 zones: head, left upper, right upper, left lower, right lower | Part targeting (head, left_arm, right_arm, left_leg, right_leg) — chest as "center" or merged with upper |
| **Attack types** | Slash, stab, kick | Cut, thrust, blunt (you already have these) |
| **Strong/weak strike** | Left click = slow/strong; right click = fast/weak | Intensity, archetype (overhead vs quick_slash) — you have this |
| **Combos** | Sequential strikes to specific zones → bonus damage, harder to block | Ordered part sequence; mental stack "combo in progress" layer |
| **Block** | Hold direction to block; drains stamina | Zone-specific guard OR scalar guard (you have scalar) |
| **Perfect block** | Block during opponent swing (green icon) → riposte priority | Parry_deflect with high capacity → counter opportunity |
| **Master strike** | Block during early attack phase → automatic counter | Parry_deflect in early wind-up → guaranteed counter |
| **Stamina** | Depletes with block, attacks, low health; affects power and block break | Gauge as stamina; or separate stamina pool |
| **30+ target zones, 4 armor layers** | Granular hit detection | Sub-regions per part (you have this) |

---

### 2. Mapping KCD to Fallen Paths (No 3D)

#### 2.1 Zone Mapping

**KCD 5 directions → Fallen Paths 6 parts:**

| KCD Zone | Fallen Paths Part | Notes |
|----------|-------------------|-------|
| Head | head | Direct match |
| Left upper | left_arm | Upper body left |
| Right upper | right_arm | Upper body right |
| Left lower | left_leg | Lower body left |
| Right lower | right_leg | Lower body right |
| — | chest | KCD merges chest into "upper" (left/right torso). Option: chest = center, or add as 6th zone |

**Simplest mapping:** Use your existing 6 parts. KCD's "left upper" and "right upper" include torso—you can treat chest as "center guard" or allow attacks to chest as a 6th zone. Your `BODY_PARTS` already support this.

#### 2.2 Zone-Specific Guard (Key Addition for KCD Feel)

**Current Fallen Paths:** Guard is a single scalar (0.4 when attacking, rises when idle). Parry capacity uses readiness × guard.

**KCD:** Defender chooses which direction to block. Attack from unblocked direction = hits.

**Abstract replication without 3D:**

**Option A: Guard by zone (directional)**

- Each combatant has `guard_zone: String` = one of "head", "chest", "left_arm", "right_arm", "left_leg", "right_leg".
- When attacking zone X: if defender's `guard_zone == X` → block/parry easier (or mandatory block). Else → normal hit chance.
- **No 3D needed:** Represent as text ("Guarding: Head") or 2D icon showing which zone is defended.
- **Mental stack layer:** "Enemy guarding head → attack chest or limbs."

**Option B: Guard coverage (multiple zones)**

- `guard_zones: Array` = list of zones currently defended (e.g., ["head", "chest"] for high guard).
- Attack to guarded zone = block. Attack to unguarded = hit (subject to dodge/parry).
- More KCD-like but more state.

**Option C: Guard scalar + zone modifier**

- Keep scalar guard. Add `last_guard_zone` or `intended_guard_zone`.
- When attacker targets part P: if P == defender.guard_zone → guard applies fully. Else → guard × 0.5 (partial) or 0 (no block).
- Minimal change; one extra field per combatant.

#### 2.3 Combos

**KCD:** Sequence like [head → right_upper → left_lower]. If all connect in order, combo finisher deals bonus damage.

**Abstract replication:**

- **Combo definition:** `{ "id": "scatter", "sequence": ["head", "right_arm", "left_leg"], "finisher_bonus": 1.5 }`
- **Combatant state:** `combo_progress: Dictionary` = { "combo_id": "scatter", "step": 1 } when first hit landed.
- **Mental stack layer:** "Combo in progress → next action must be next step in combo, target that part."
- **On hit:** If current attack is next step → increment step. If step == len(sequence) → apply finisher bonus, clear progress.
- **On miss/block/parry:** Clear combo progress.
- **No 3D:** Combo is just a list of part names. UI shows "Combo: Head ✓ → R.Arm → L.Leg" or similar.

#### 2.4 Perfect Block & Master Strike

**KCD:**

- **Perfect block:** Block during opponent's swing (not before) → bullet-time, riposte with priority.
- **Master strike:** Block during *early* attack phase → automatic, unavoidable counter.

**Fallen Paths already has:**

- Parry with reaction_time vs effective_wind_up.
- Parry_deflect → no damage, attacker in recovery.
- Parry_partial → reduced damage, possible twist dodge.

**Abstract replication:**

- **Perfect block:** When parry_deflect occurs and defender was in WAITING (not recovering) → set `riposte_priority: true` on defender. Next tick, defender's action gets priority (or reduced cost).
- **Master strike:** When parry_deflect occurs and attack was in *early* wind-up (e.g., first 30% of wind_up_duration) → defender automatically gets a counter attack. Implement as: on parry_deflect, if `wind_up_progress < 0.3`, emit `master_strike_triggered` → resolve defender counter immediately before attacker recovery.

**No 3D:** Both are timing/state rules. Text: "Perfect block! Riposte!" or "Master strike!"

#### 2.5 Stamina

**KCD:** Stamina depletes with block, attack, sprint. Low stamina → weak attacks, block breaks, vulnerable to finisher.

**Fallen Paths:** Gauge = readiness. Could double as stamina, or add separate pool.

**Abstract options:**

- **Gauge as stamina:** Attacks consume gauge beyond 100 (e.g., heavy attack costs 120, leaves you at 0). Block/parry consume some gauge. Low gauge = intensity cap (can't do full power).
- **Separate stamina:** New `stamina: float` 0–100. Block costs 10, attack costs 5–20 by archetype. At 0: can't block (or block fails), weak attacks.
- **Unified:** One pool. "Readiness" when full = can act. "Stamina" = same pool, consumed by actions. Refill rate = agility × rest_factor.

---

### 3. Non-3D Representation Options

#### 3.1 Text-Based

- **Combat log:** "Goblin strikes at your head. You block. Riposte!"
- **Zone labels:** "You guard your head. Enemy attacks your left arm — hit! 12 damage."
- **Combo display:** "Combo: Head → R.Arm (next) → L.Leg"
- **Minimal UI:** Buttons or list for zone selection; no graphics.

#### 3.2 2D Abstract

- **Silhouette:** Simple front-view human outline. Click or highlight zones (head, arms, legs, chest). Color = guarded (green) vs exposed (red).
- **Zone grid:** 2×3 or 3×2 grid. Each cell = zone. Icons for health, guard, last hit.
- **Card-based:** Each zone a card. "Head" card shows guard state, health bar. Attacker plays "Strike: Head" card.
- **Hex or zone diagram:** Abstract shapes for zones; lines connecting combo sequence.

#### 3.3 Schematic / Diagram

- **Riddle of Steel style:** Diagram from your MELEE_SIMULATION doc — hit zones as labeled regions. No character model.
- **Top-down or side-view:** Stick figure or simple shapes. Zones as regions.

#### 3.4 Hybrid

- **Main view:** Text or simple 2D. **Combat log:** Narrative. **Zone selector:** Dropdown or button row for "Target: Head / Chest / L.Arm / R.Arm / L.Leg / R.Leg".

---

### 4. Mental Stack Integration

#### 4.1 New Layers for KCD-Style Combat

| Layer | Condition | Decision |
|-------|-----------|----------|
| 1 | Ally in peril | Medical (unchanged) |
| 2 | Enemy winding up on me | Parry / block (unchanged; now consider guard_zone vs attack target) |
| 3 | **Master strike available** | Execute counter (new: on parry_deflect early → guaranteed counter) |
| 4 | **Riposte priority** | Counter-attack (new: perfect block gave priority) |
| 5 | **Combo in progress** | Next combo step (attack target = sequence[step]) |
| 6 | Engaged / best target | Attack with zone selection (see 4.2) |
| 7 | Default | Attack nearest |

#### 4.2 Zone Selection in Attack Layer

When layer 6 (or 5) fires and the choice is "attack":

**Scoring per (target_id, move_id, target_part):**

- `unguarded_bonus`: If defender's guard_zone != target_part, +50% weight.
- `combo_bonus`: If target_part is next in combo, +100% weight.
- `armor_penalty`: If part has heavy armor and we use cut, -20%. Thrust better vs armor.
- `kill_potential`: Part low health, or head/chest for lethality.
- `last_hit_diversity`: Slight penalty for attacking same zone twice (optional).

**Mental stack picks:** Filter actions by layer; within layer 6, use weighted selection over (target, move, part) with above scores.

#### 4.3 Guard Selection (Defender)

When defender must choose guard (if using directional guard):

- **Threatened zone:** If attacker has pending_attack and we know target_part (e.g., from telegraph or probabilistic), guard that zone.
- **Mental stack:** Layer 2 "enemy winding up on me" — if we have `_is_being_targeted` and know attack target (from telegraph), set guard_zone = that part.
- **Default:** Guard head (most lethal) or chest (largest).

**Telegraph:** Attacker commits to target_part at wind-up start. Defender can react (Observer-like). You already have wind-up duration; defender's reaction_time determines if they see it in time.

---

### 5. Implementation Paths

#### Path A: Minimal KCD Overlay

**Add:**

1. **Zone-specific guard:** `guard_zone: String` per combatant. When attacking part P: if P == defender.guard_zone, parry/block chance × 1.5 (or block mandatory). Else, normal.
2. **Attack target_part:** Extend attack actions to include optional `target_part`. If absent, random as now. Mental stack layer 6 scores by unguarded.
3. **Perfect block → riposte:** On parry_deflect, set defender `riposte_priority`. Next turn, defender acts first or at reduced cost.

**Representation:** Text in combat log. Optional: 2D zone diagram for guard display.

#### Path B: Full KCD-Style

**Add:**

1. Zone guard (as A).
2. **Combos:** Combo definitions per weapon; combo_progress state; mental stack combo layer.
3. **Master strike:** Early parry_deflect → auto counter.
4. **Stamina pool:** Separate or gauge-double-duty. Low stamina = weak attacks, block break.
5. **Kick:** New move type (blunt, low damage, high stagger) — KCD has kick to break guard.

**Representation:** 2D zone selector (silhouette or grid), combo progress UI, stamina bar.

#### Path C: Abstract-Only (No Spatial UI)

**Add:**

1. Zone guard (as A).
2. Attack target_part selection via mental stack scoring.
3. Combos (data only; no special combo UI—just "combo landed" in log).
4. Perfect block / master strike (timing rules; log messages).

**Representation:** Pure text. "You attack his left arm (unguarded). Hit! 14 damage." "Combo: Head → R.Arm → L.Leg. Finisher! 28 damage."

---

### 6. Data Structures (No 3D Dependencies)

```gdscript
# Zone guard (Path A minimum)
combatant["guard_zone"] = "head"  # or "chest", "left_arm", etc.

# Combo (Path B)
const COMBO_SCATTER = { "id": "scatter", "sequence": ["head", "right_arm", "left_leg"], "finisher_mult": 1.5 }
combatant["combo_progress"] = { "combo_id": "scatter", "step": 0 }  # 0 = not started; 1 = first hit; etc.

# Riposte / Master strike (Path A/B)
combatant["riposte_priority"] = true   # after perfect block
# Master strike: resolve in AttackResolver on parry_deflect when wind_up_progress < 0.3

# Attack with target part (extends current)
action = { "target_id": 2, "move_id": "slash", "target_part": "head" }  # target_part optional
```

---

### 7. Summary: What You Need

| KCD Feature | Abstract Implementation | 3D Required? |
|-------------|-------------------------|--------------|
| 5 attack zones | 6 body parts (existing) | No |
| Directional block | guard_zone: String | No |
| Combos | sequence + combo_progress | No |
| Perfect block | parry_deflect → riposte_priority | No |
| Master strike | early parry_deflect → auto counter | No |
| Stamina | gauge or new stamina pool | No |
| Strong/weak | intensity, archetype (existing) | No |
| Kick | new blunt move, stagger | No |

**All KCD combat logic can be represented as state (strings, numbers, arrays) and rules. No 3D models, animations, or spatial representation required.** The "combat" is resolved in code; the representation (text, 2D diagram, cards) is purely for player feedback.

---

### References

- Kingdom Come: Deliverance — Combat (Fandom wiki), Deltia's guides, Steam guides
- Fallen Paths: `docs/AI_ENGAGEMENT_STANCE_AND_FEINTS.md` (mental stack sections)
- BodyPartConstants.gd, BleedingConstants.gd, WeaponConstants.gd
- MELEE_SIMULATION_AI_INVESTIGATION.md (Playtank systemic melee, zone diagrams)

---
