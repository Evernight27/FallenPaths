# HEMA Fidelity: System Examination and Improvement Options

Analysis of the combat/parry system against HEMA principles and historical sources, with prioritized improvement options.

---

## 1. What's Already Well-Aligned

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

## 2. Improvement Categories

### A. Blade Geometry (Strong/Weak)

**HEMA principle:** "Catch the weak of their blade on the strong of yours" (Liechtenauer, i.33). Strong = near guard; weak = near tip. Contact point changes leverage.

**Current:** Only mass (m_a, m_d) and strength. No blade geometry.

**Options:**
1. **Simple strong/weak factor:** Add `strong_contact_bonus` when defender "catches weak"—approximate by attack archetype (OVERHEAD = more weak exposed, QUICK_SLASH = less) or add a 0–1 "strong_contact" per move.
2. **Full blade model:** Weapon gets `blade_length_cm`, `strong_fraction` (e.g. 0.3 = 30% strong). Parry capacity multiplied by contact quality. Higher complexity.

**Effort:** Low (archetype modifier) to Medium (blade model).

---

### B. Guard / Readiness

**HEMA principle:** "On guard" vs "blade down" changes how fast you can parry. Guard is a posture, not just "waiting to act."

**Current:** WAITING = uniform. No notion of guard level.

**Options:**
1. **Guard sub-state in WAITING:** `guard: float` (0–1). After attack, guard drops; after parry or no action, guard rises. Parry reaction_time × (1 / guard) or capacity × guard.
2. **Defensive stance action:** Choose "hold guard" instead of attack—gauge fills slowly, parry/dodge improve. STATE_MACHINE_PARRY_REALISM §3.6.

**Effort:** Low–Medium.

---

### C. Attack Selection and Feints

**HEMA principle:** Feints work because reaction+decision takes ~400–600 ms. Attack choice (committed vs probing) matters. Counter-time: attack into their preparation.

**Current:** Attack chosen from available moves; no feint, no abort. COMMITMENT_FRACTION (0.2) gives telegraph but no attacker reaction.

**Options:**
1. **Feint move:** A "feint" has short wind-up, low damage, but triggers defender reaction. If defender parries, feint can convert to real attack (complex) or just wastes their parry.
2. **Abort window:** First 10–15% of wind-up, attacker can abort → short recovery. Defender's early parry could "draw" an abort. STATE_MACHINE_PARRY_REALISM §3.8.
3. **Archetype telegraph:** OVERHEAD (long wind-up) = easier to read; QUICK_SLASH (short) = harder. Already partially there via windup_multiplier. Could add "telegraph_factor" so defender gets more effective_wind_up vs slow attacks.

**Effort:** Medium (needs UI/input for abort); Feint = Medium–High.

---

### D. Multiple Parries and Chained Defense

**HEMA principle:** Exchanges can have multiple parries; "parry-riposte, parry-riposte" in some systems. Double hits when both attack.

**Current:** `passive_parry_attempted` = one parry per incoming attack. No second parry.

**Options:**
1. **Second parry at reduced capacity:** After first partial parry, allow second attempt with e.g. 50% capacity, longer reaction. Represents "rolling" or chained parry.
2. **Explicit parry moves as post-deflect option:** After parry_deflect, defender could choose `parry_thrust` etc. as a riposte. Currently parry moves exist but are never chosen (AI uses non-parry only). Would need combat flow to offer riposte after deflect.

**Effort:** Low (second parry) to Medium (riposte flow).

---

### E. Cutting Direction vs Parry Line

**HEMA principle:** Parries form a "house of safety" relative to 8 cutting directions. Some parries cover certain lines better (e.g. high vs low, left vs right).

**Current:** No cutting direction or parry line. Parry is generic.

**Options:**
1. **Line modifier:** Each move has `cutting_line` (e.g. high_left, low_right). Defender's "effective" parry varies by whether their last action/guard matches the line. E.g. if defender just did a high parry, low attack gets a bonus (defender wrong line).
2. **Simpler:** OVERHEAD attacks slightly harder to parry (commitment from above); horizontal (slash) easier. Archetype-based modifier only.

**Effort:** Medium–High (full line model); Low (archetype modifier).

---

### F. Bind and Blade Contact

**HEMA principle:** After parry, blades can bind. In the bind, structure and blade control matter; heavier blade doesn't automatically win (per sword design research).

**Current:** parry_deflect = full stop; attacker gets off_balance. No explicit bind state.

**Options:**
1. **Bind window:** After full deflect, "bind_duration" where next attack from attacker is penalized (they're still in contact). Adds a short vulnerable period.
2. **Revert to current:** Off-balance already models "deflect cost." Bind is implicit.

**Effort:** Low (extend off_balance) to Medium (explicit bind).

---

### G. Timing Tuning

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

### H. Riposte / Parry-Counter Flow

**HEMA principle:** Parry is often followed by immediate counter (riposte). Your moves include parry_thrust, parry_cut, etc., but they're never selected.

**Current:** Parry is passive only. Explicit parry moves exist in weapon data but aren't used in normal flow.

**Options:**
1. **Post-deflect riposte:** After parry_deflect, defender automatically gets a "free" attack (or reduced cost) using a parry-counter move. Or: defender's next action can be a parry move at reduced gauge cost.
2. **AI uses parry moves after deflect:** When defender just deflected, AI could prefer parry_thrust/parry_cut for next action (faster, thematically correct).

**Effort:** Medium (flow change); Low (AI bias).

---

### I. Distance and Measure

**HEMA principle:** Fencing is about measure (distance). At long measure, thrusts and reach matter; at close, cuts and grapples.

**Current:** No explicit distance. All attacks resolve the same way.

**Options:**
1. **Weapon reach:** Weapons have melee_range. Spear > sword > dagger. Could affect hit chance or who can target whom. Large system change.
2. **Defer:** Keep current abstraction; reach already influences via weapon choice (dagger vs spear).

**Effort:** High.

---

## 3. Summary Table

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

## 4. Recommended Implementation Order

1. **Guard/readiness** — Parry capacity or reaction scaled by a guard factor. Highest realism gain for state-machine work already in place.
2. **Strong/weak archetype modifier** — Add `parry_contact_quality` to OVERHEAD, SLASH, etc. OVERHEAD = defender more likely to catch weak.
3. **Post-deflect riposte** — After parry_deflect, give defender a bonus toward using parry_thrust/parry_cut (or reduced gauge cost for next action).
4. **Reaction time** — 0.24 s (implemented).
5. **Second parry at 50% capacity** — Allow one more attempt after partial, with strong penalty.
6. **Feint or abort** — Only if you want a deeper tactical layer and can support the input flow.

---

---

## 5a. Quick Attacks and Goblin Parries (Medieval Combat Research)

### Research Summary

**Fiore de’i Liberi (Flos Duellatorum, c. 1409) – Sword vs Dagger**
- Dagger vs sword: Defender has “significant advantage” if they know the techniques (Boar’s Tusk guard, Narrow Play).
- Key insight: Dagger defender must **deflect**, not absorb. “Beat back” (rebatter) the sword—redirect, don’t block.
- Narrow Play (zogo stretto): Close range, deflect cuts/thrusts with quick arm/hand movement, then strike.
- Arms and hands must move **quickly** to counter attacks.

**Implications for the system:**
1. **Light weapons (dagger) vs heavy:** Already modeled via mass-disparity redirect bonus; light weapon deflects by angle.
2. **Blade movement time:** Light weapon + weak user = slow blade movement (clamp). Light weapon + strong user = fast. **Goblin with dagger** gets 0.5× base movement (0.065 s) vs goblin with sword (0.26 s). So goblins parry better with daggers—matches Fiore.
3. **Most contacts blade-on-blade (COMBAT_PARRY_MISS_RESEARCH):** HEMA longsword: 57–80% of contacts are parry/block. Even when "too late" for a full parry, defender often gets reflexive/partial blade contact. **Late parry** gives minimal capacity (22%) so quick attacks and goblin-vs-human still resolve as partial parries, not full hits.

### Implemented Changes

| Change | Location | Effect |
|--------|----------|--------|
| PARRY_DEFLECT_THRESHOLD 1.08 | CombatManager | Fewer full deflects, more partials |
| PARRY_TECHNIQUE_VARIANCE 0.15 | CombatManager | Noisier parry execution |
| PASSIVE_PARRY_BASE_REACTION_S 0.24 | EntityPainConsciousness | Slightly fewer “in time” parries |
| PARRY_LATE_CAPACITY_FLOOR 0.22 | CombatManager, AttackResolver | When too late for full parry, defender still attempts reflexive parry (usually partial) |

### Further Options (not yet implemented)

- **Goblin weapon preference:** AI could prefer dagger when defending vs larger attackers (Fiore-style deflection).
- **Strong/weak contact:** OVERHEAD exposes more weak of blade; add parry_contact_quality modifier.
- **Guard/readiness:** Post-parry or “on guard” improves next parry capacity.

---

## 6. What to Defer

- **Full cutting-line model** — High complexity; archetype-level approximation is enough.
- **Explicit distance/measure** — Large change; current abstraction is workable.
- **Bind as distinct state** — Off-balance already captures most of the effect.
