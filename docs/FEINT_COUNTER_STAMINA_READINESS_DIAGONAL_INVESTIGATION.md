# Feint, Counter Window, Stamina, Recovery→Readiness & Diagonal Line Roll: Integration Investigation

Investigation into different ways to integrate five combat features: feint (telegraph vs real target), counter windows (tempo interrupt), stamina, recovery cause → readiness scaling, and diagonal line roll. Each section explores multiple approaches with pros, cons, and implementation notes.

---

## 1. Feint (Telegraph vs Real Target)

**Current:** No feint. Attack target is the real target. `target_part` is committed at wind-up start and used at resolve.

**HEMA:** Feint = threaten line A to draw parry; disengage; hit line B. Single-tempo action (Giganti: cavazione baits response).

### Approach A: Feint as Explicit Two-Phase Commitment

**Mechanic:** Move has `is_feint: bool`. When true, attacker commits `feint_part` (telegraph) ≠ `target_part` (real). Defender sees telegraph; if they parry/guard toward feint_part, they get parry penalty when real hit lands.

**Flow:**
1. Attacker chooses feint move, feint_part, target_part (e.g. feint head, real chest).
2. Wind-up: defender sees feint_part (or probabilistic inference).
3. Defender chooses parry/dodge based on feint_part (guards wrong zone).
4. Execute: real target_part used for hit resolution. If defender guarded feint_part, parry_c_d × 0.6 (or similar).

**Pros:** Historical. Tactical depth. Mind-games.
**Cons:** Two-phase commitment. Defender needs reaction logic. Feint cost: ~10% wind-up (Fabris). New move type or flag per move. AI must decide when to feint.

**Data:** `pending_attack.feint_part`, `pending_attack.target_part`. Move: `is_feint: true`, `feint_windup_penalty: 0.1`.

---

### Approach B: Feint as Probabilistic Misdirection

**Mechanic:** X% chance actual target ≠ intended. No explicit feint_part. At resolve, roll: if `randf() < FEINT_CHANCE`, swap target_part to a different part in path (or adjacent line).

**Pros:** Simple. Emergent deception. No new UI or commitment flow.
**Cons:** Not intentional feint. Attacker doesn't "threaten then redirect." Feels random, not skillful.

**Data:** `FEINT_CHANCE := 0.08` (or per-move). At resolve, before path lookup, roll for swap.

---

### Approach C: Feint as Telegraph Delay

**Mechanic:** Attacker commits target_part at 50% wind-up (not at start). First half of wind-up: defender sees "attack incoming" but not which part. Second half: telegraph reveals target_part. Defender has less time to react to real target.

**Pros:** Reduces defender reaction window. No feint_part/target_part split.
**Cons:** Doesn't model "bait wrong parry." Just shortens effective reaction time.

**Data:** `COMMITMENT_FRACTION` already exists (0.2). Could add `telegraph_at_progress: 0.5` — defender only gets target_part for parry choice after 50% wind-up.

---

### Approach D: Feint as Parry Bait (Guard Zone Only)

**Mechanic:** Requires zone-specific guard (guard_zone). Attacker feints → defender moves guard to feint_part. Real attack goes to target_part. Defender's guard_zone is wrong → parry penalty.

**Pros:** Clean integration with guard_zone. No new attack types.
**Cons:** Depends on guard_zone implementation. Defender AI must "fall for" feint (guard feint_part when they see telegraph).

---

### Feint Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Full HEMA fidelity | A | High |
| Simple variance | B | Low |
| Shorter reaction | C | Medium |
| With guard_zone | D | Medium (after guard_zone) |

**Suggested path:** **C** (telegraph delay) is lowest effort and improves tempo without new mechanics. **A** if you want explicit feint moves and mind-games.

---

## 2. Counter Window (Tempo / Partial Gauge Interrupt)

**Current:** Act only when gauge = 100. No interrupt during enemy wind-up.

**HEMA:** "When he raises his sword... strike while his hand is rising." (Dall'Agocchie) Opponent committed = your opportunity.

### Approach A: Partial Gauge Counter (Spend 50% → Act Now)

**Mechanic:** When enemy is in WIND_UP and my gauge ≥ 50, I can spend 50 gauge → immediate action. My action resolves *before* the enemy's attack. If my action defeats/kills them, their attack never executes.

**Flow:**
1. Enemy enters WIND_UP. My gauge = 60.
2. I choose "Counter" (new action). Spend 50 gauge → gauge = 10.
3. I immediately resolve my attack (or other action). Order: counter resolves first.
4. If enemy dies or is incapacitated, their wind-up is cancelled. Else, their attack still executes (they were winding up on me; I countered someone else, or missed).

**Pros:** Captures tempo. "Strike while his hand is rising." High impact.
**Cons:** Order of resolution: counter first. Attacker may "lose" to counter. Balance: 50% cost. New decision for player/AI. UI: "Counter" button when eligible.

**Data:** `get_available_actions` adds "counter" when `gauge >= 50` and `_is_enemy_winding_up_on_me(c)`. Counter action spends 50, triggers immediate resolve.

---

### Approach B: Stricter Counter (60% Gauge or Wind-Up > 50%)

**Mechanic:** Same as A but: (1) require 60% gauge, or (2) only when enemy wind-up progress > 50% (they're committed, can't abort).

**Pros:** Reduces counter spam. More committed = more vulnerable.
**Cons:** More tuning. May feel restrictive.

---

### Approach C: Counter as Gauge Advantage (No Interrupt)

**Mechanic:** When enemy is in WIND_UP, my gauge fills 20% faster. I don't interrupt; I just get to act sooner after their attack resolves.

**Pros:** No resolution order complexity. Simpler.
**Cons:** Doesn't capture "strike during their wind-up." Less dramatic.

---

### Approach D: Counter Window as Reaction Action

**Mechanic:** During enemy wind-up, defender gets a one-time "counter" option that costs 40 gauge. If taken, defender's action is queued to resolve *before* attacker's. Not an attack—a defensive counter (parry-thrust, etc.) that happens "early."

**Pros:** Defensive flavor. Fits "catch them in the middle of the cut."
**Cons:** Only defender can counter. Attacker can't counter defender's wind-up (asymmetric).

---

### Counter Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Full tempo interrupt | A | Medium |
| Reduce spam | B | Low (tweak A) |
| Simpler | C | Low |
| Defensive only | D | Medium |

**Suggested path:** **A** for full tempo play. **B** if counters feel too frequent. Requires: `_is_enemy_winding_up_on_me`, counter action in available_actions, resolution order (counter first).

---

## 3. Stamina

**Current:** Gauge = readiness (0–100). Fills when idle. Must be 100 to act. No consumption beyond "spend 100 to act."

**KCD:** Stamina depletes with block, attack, sprint. Low stamina → weak attacks, block breaks, vulnerable.

### Approach A: Gauge as Stamina (Over-Spend)

**Mechanic:** Attacks cost gauge by intensity/archetype. Heavy attack costs 120 → leaves gauge at 0 (or negative, clamped). Light attack costs 60. Block/parry costs 15. Gauge refills at agility × rate. When gauge < 100, can't act. When gauge < 50, intensity cap 0.5 (weak attacks only).

**Pros:** One pool. Readiness = stamina. Low gauge = vulnerable.
**Cons:** Changes gauge semantics. "Full" used to mean 100; now "can act" might be 100 but "strong attack" needs 120. Tuning: cost per move.

**Data:** Move: `stamina_cost: float` (e.g. 80–120). Parry: `PARRY_STAMINA_COST := 15`. `process_waiting`: gauge += fill_rate. When acting: gauge -= cost; clamp 0.

---

### Approach B: Separate Stamina Pool

**Mechanic:** New `stamina: float` 0–100 per combatant. Gauge = readiness (unchanged). Stamina consumed by: attack (5–20 by archetype), parry (10), block (15). Refill: stamina += rate when idle. At stamina 0: can't parry (or parry fails), attacks deal 50% damage, or can't heavy attack.

**Pros:** Clear separation. Gauge = "can I act"; stamina = "how well can I fight."
**Cons:** Two pools. More UI. More state.

**Data:** `combatant["stamina"] = 100`. `STAMINA_ATTACK_COST`, `STAMINA_PARRY_COST`. Refill in process_waiting.

---

### Approach C: Unified Pool (Gauge = Stamina = Readiness)

**Mechanic:** One pool. "Readiness" when full = can act. Same pool consumed by actions. Refill rate = agility × rest_factor. Attacking costs 100 (to act) + overflow cost. E.g. heavy attack: need 100 to queue, then consume 20 more → gauge drops to 80. Next fill to 100 before next act.

**Pros:** Single number. Simple mental model.
**Cons:** Gauge semantics shift. "100" = ready; acting drops it. Already partially true (gauge = 0 after acting). Main change: parry/block also consume.

---

### Approach D: Stamina as Intensity Cap Only

**Mechanic:** No stamina pool. Instead: "fatigue" or "exertion" from recent actions. After N attacks in a row, intensity cap drops (e.g. 0.7 max). Recovers over time. Simpler: no new pool, just a debuff.

**Pros:** Minimal. No stamina UI. Emergent "tired" state.
**Cons:** Less granular. No "block costs stamina" or "parry costs stamina."

---

### Stamina Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| KCD-style | A or B | Medium |
| Simplest | C | Low–Medium |
| Minimal | D | Low |

**Suggested path:** **D** (intensity cap from exertion) for minimal change. **A** if you want explicit stamina costs. **B** if you want clear separation of readiness vs stamina.

---

## 4. Recovery Cause → Readiness Scaling

**Current:** `recovery_cause` is set when entering RECOVERING: "skip", "attack_miss", "attack_deflect", "attack_hit". Used by AttackPathResolver (staggered → chest bias). Readiness uses uniform lerp(0.5, 0.85) for all recoveries.

**Question:** Should parry capacity (readiness) differ by *why* they're recovering?

### Approach A: Cause-Based Readiness Curves

**Mechanic:** Different readiness multiplier per recovery_cause:
- `attack_hit` → lerp(0.3, 0.6, progress) — more stunned, worse parry
- `attack_miss` → lerp(0.45, 0.8, progress) — off-balance but less stunned
- `attack_deflect` → lerp(0.5, 0.85, progress) — blade deflected, similar to current
- `skip` / `medical` → lerp(0.5, 0.85, progress) — unchanged

**Pros:** Hit → more vulnerable. Miss → less so. Realistic.
**Cons:** New constants per cause. Tuning.

**Data:** `READINESS_BY_CAUSE: Dictionary` with early/late per cause. `PassiveParryContext.get_passive_parry_readiness(c)` reads `c.recovery_cause` and picks curve.

---

### Approach B: Cause as Readiness Modifier (Single Curve)

**Mechanic:** Keep single lerp(0.5, 0.85). Multiply by cause modifier:
- attack_hit: ×0.7
- attack_miss: ×0.95
- attack_deflect: ×1.0
- skip/medical: ×1.0

**Pros:** Simpler. One curve, one multiplier.
**Cons:** Less granular than full curves.

---

### Approach C: Incoming Attack Type on Readiness

**Mechanic:** Pass incoming `attack_type` (cut/thrust/blunt) into readiness. Thrust → lower readiness (harder to react). Cut → same or higher (more telegraph).

**Pros:** Thrust is faster, less telegraph. Cut has visible arc.
**Cons:** Pass attack_type into parry calc. More parameters. Complicates DefenseChoiceResolver.

---

### Approach D: Keep Uniform (No Change)

**Mechanic:** Same lerp for all. recovery_cause only used for path resolver (staggered bias).

**Pros:** Simplest. No new tuning.
**Cons:** "Recovering from hit" parries same as "recovering from whiff."

---

### Recovery→Readiness Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| Realistic cause effect | A | Low |
| Simple modifier | B | Low |
| Attack-type aware | C | Medium |
| No change | D | None |

**Suggested path:** **B** (cause modifier) — low effort, clear effect. **A** if you want finer control. recovery_cause already exists; just use it in `get_passive_parry_readiness`.

---

## 5. Diagonal Line Roll

**Current:** Diagonal moves (oberhau, diagonal_chop) have single primary `attack_line`. Oberhau = "high", diagonal_chop = "left". Parry resolution uses that line exclusively.

**Physics:** Zornhau (descending diagonal) crosses high and left. Which line the guard meets first varies by trajectory and defender position.

### Approach A: Keep Primary (No Change)

**Mechanic:** One line per move. oberhau = high, diagonal_chop = left.

**Pros:** Simple. No extra roll.
**Cons:** Diagonal parries feel binary. Same outcome every time.

---

### Approach B: Weighted Roll at Resolve

**Mechanic:** Diagonal moves have `attack_lines: Array` with weights. E.g. oberhau: `[{"high": 0.65}, {"left": 0.35}]`. At resolve, roll to pick which line is "primary" for this exchange. Use that for alignment, path, parry.

**Pros:** Physics: path crosses lines; which intersects first varies. More varied outcomes.
**Cons:** Extra roll per diagonal move. Need line_weights per move. Slightly more complex.

**Data:** Move: `attack_lines: [{"line": "high", "weight": 0.65}, {"line": "left", "weight": 0.35}]`. At AttackResolver start, if move has attack_lines, roll to pick effective attack_line for this resolve.

---

### Approach C: Alignment-Weighted Roll

**Mechanic:** Roll weighted by defender's guard_line. If defender has high guard, 70% high / 30% left. If low guard, 50/50. Reflects "which line would my guard meet first given their position."

**Pros:** Tactical. Defender posture affects which line "wins."
**Cons:** More logic. Need weight table per (guard_line, diagonal_move).

---

### Approach D: Secondary Line as Fallback

**Mechanic:** Diagonal move has `primary_line` and `secondary_line`. If parry would fail on primary (e.g. alignment 0), use secondary for a "lucky" intercept roll. Not full weighted—just fallback.

**Pros:** Occasional variance. Simple.
**Cons:** Binary: primary or secondary. Less smooth than weighted.

---

### Diagonal Recommendation Matrix

| Goal | Approach | Effort |
|------|----------|--------|
| No change | A | None |
| Physics variance | B | Low |
| Tactical | C | Medium |
| Occasional variance | D | Low |

**Suggested path:** **B** (weighted roll) — low effort, good payoff. Add `attack_lines` only to diagonal moves (oberhau, unterhau, diagonal_chop, maybe slash). Others keep single `attack_line`.

---

## 6. Implementation Order & Dependencies

```
1. Recovery cause → readiness (B: modifier)
   └── recovery_cause exists; PassiveParryContext change only

2. Diagonal line roll (B: weighted)
   └── WeaponConstants + AttackResolver; no new state

3. Stamina (D: intensity cap) or (A: gauge over-spend)
   └── Independent. D = minimal. A = more changes.

4. Counter window (A: 50% gauge)
   └── Requires: _is_enemy_winding_up_on_me, counter action, resolution order

5. Feint (C: telegraph delay) or (A: explicit feint)
   └── C = COMMITMENT_FRACTION tweak. A = new move type, defender logic.
```

---

## 7. Summary: Suggested Choices

| Feature | Suggested Approach | Rationale |
|---------|---------------------|-----------|
| **Feint** | C (telegraph delay) or A (explicit) | C = low effort. A = full fidelity. |
| **Counter window** | A (50% gauge interrupt) | Captures tempo. Medium effort. |
| **Stamina** | D (intensity cap) or A (gauge over-spend) | D = minimal. A = KCD-style. |
| **Recovery→Readiness** | B (cause modifier) | recovery_cause exists; one multiplier. |
| **Diagonal line roll** | B (weighted roll) | Physics variance. Low effort. |

---

## References

- COMBAT_ISSUES_TODO_INVESTIGATION.md (§2, §5, §7, §8)
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- PassiveParryContext.gd (get_passive_parry_readiness)
- AttackResolver.gd, DefenseChoiceResolver.gd
- WeaponConstants.gd (attack_line, move definitions)
