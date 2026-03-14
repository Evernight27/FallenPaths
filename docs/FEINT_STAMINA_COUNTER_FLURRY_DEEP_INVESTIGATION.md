# Feint A vs D, Counter Window & Flurries, Stamina, Recovery System, Diagonal B vs C: Deep Investigation

Supplemental investigation addressing five specific questions: (1) Feint A vs D integration differences, (2) Counter window handling and flurries interaction, (3) Stamina integration with HEMA/medieval realism, (4) Current system behavior and realism of implementations, (5) Diagonal B vs C differences.

---

## 1. Feint: Differences Between Integrating A vs D

### Approach A: Feint as Explicit Two-Phase Commitment

**Mechanic:** Move has `is_feint: bool`. Attacker commits `feint_part` (telegraph) ≠ `target_part` (real). Defender reacts to feint; if they guard/parry toward feint_part, parry penalty when real hit lands.

**Integration requirements:**
- New move flag: `is_feint: true`
- Action structure: `feint_part`, `target_part` (both required for feint moves)
- Wind-up: defender sees `feint_part` as telegraph (or AI infers from telegraph)
- DefenseChoiceResolver: defender's parry/guard choice uses feint_part
- AttackResolver: at execute, use target_part for hit; if defender guarded feint_part, apply parry_c_d × FEINT_PARRY_PENALTY (e.g. 0.5–0.6)
- AI: CombatAIActionPicker must decide when to feint (e.g. when defender has high parry rate); pick feint_part and target_part
- UI: player must choose feint_part and target_part when selecting feint move

**Dependencies:** None. Works with current guard_line. Does NOT require guard_zone.

**Data flow:** `pending_attack = { feint_part: "head", target_part: "chest", move_id: "feint_slash", ... }` → DefenseChoiceResolver uses feint_part for defender's reaction → AttackResolver uses target_part for hit, checks if defender "fell for" feint.

---

### Approach D: Feint as Parry Bait (Guard Zone Only)

**Mechanic:** Requires zone-specific guard (`guard_zone`). Attacker feints → defender moves guard to feint_part. Real attack goes to target_part. Defender's guard_zone is wrong → parry penalty.

**Integration requirements:**
- **Prerequisite:** guard_zone must be implemented (combatant chooses which part to guard)
- Feint = attacker declares feint_part; defender (or AI) "falls for" it by setting guard_zone = feint_part when they see telegraph
- Real attack targets target_part; defender's guard_zone ≠ target_part → parry penalty
- Defender AI must have logic: "when I see attack telegraph to part X, I guard X" — so feint_part baits that behavior

**Dependencies:** **guard_zone** (zone-specific guard). Cannot work without it.

**Data flow:** Attacker commits feint_part. Defender sees telegraph, sets guard_zone = feint_part (or AI does). Attacker hits target_part. Defender's guard_zone (feint_part) ≠ target_part → unguarded → parry_c_d × 0.5 or similar.

---

### Key Differences: A vs D

| Aspect | A (Explicit Two-Phase) | D (Parry Bait / Guard Zone) |
|--------|------------------------|------------------------------|
| **Prerequisite** | None | guard_zone system |
| **Defender state** | Uses existing parry choice; feint affects parry capacity when defender "guarded wrong" | Requires defender to have guard_zone; feint = bait guard to wrong zone |
| **How defender "falls for" feint** | Check if defender's guard_line covers feint_part's line → parry penalty | Defender explicitly sets guard_zone = feint_part when they react to telegraph |
| **Implementation scope** | Add feint moves, feint_part/target_part, parry penalty when "wrong guard" | Must implement guard_zone first; then feint = bait + hit unguarded |
| **Standalone** | Yes — can add feint without other systems | No — blocked on guard_zone |
| **Realism** | High — explicit feint, defender reacts to telegraph | High — but depends on guard_zone realism |
| **AI complexity** | AI must choose feint_part, target_part; decide when to feint | AI must "fall for" feints (guard telegraph); attacker exploits |

**Verdict:** **A** is self-contained and can be added immediately. **D** is cleaner conceptually (feint = bait guard) but requires guard_zone. If you plan to add guard_zone anyway, **D** fits naturally. If not, **A** is the only option. **A** can approximate "wrong guard" using guard_line: if defender's guard_line aligns with feint_part's typical line (e.g. feint head → high line) but real hit is low line, parry penalty.

---

## 2. Counter Window Handling & Flurries of Blows

### Current Counter Window (Proposed, Not Implemented)

**Mechanic:** When enemy is in WIND_UP targeting me, I can spend 50% gauge → immediate action. My action resolves *before* the enemy's attack. If I kill/incapacitate them, their attack is cancelled.

**Flow:**
1. Enemy A enters WIND_UP targeting me (B). `A.state == WIND_UP`, `A.pending_attack.target_id == B.id`
2. My gauge ≥ 50. `get_available_actions` adds "counter" action.
3. I choose counter. Spend 50 gauge. My attack (or other action) resolves immediately.
4. Resolution order: counter resolves first. Then, if A still alive and targeting B, A's attack executes.

**Handling:** Requires `_is_enemy_winding_up_on_me(c)` — true when any opponent has state WIND_UP and pending_attack.target_id == c.id. Counter action: spend 50, trigger immediate resolve (bypass normal turn order).

---

### Flurries of Blows: What They Are

**HEMA:** Rapid successive attacks in quick succession. 70–90% of exchanges end in *some* hit. Double hits 7–40%. Binding at close measure enables quick thrusts from the bind.

**Fallen Paths current:** Discrete. One attack → resolve → recovery. No flurry phase. Gauge fills; next actor acts. Turn-based feel.

---

### Ways to Integrate Flurries

#### Flurry Option 1: Emergent from Counter Window

**Mechanic:** Counter window enables back-and-forth. A attacks B → B counters (50% gauge) → B's attack resolves → A is now in recovery. No explicit "flurry" state.

**Interaction with counter:** Counter creates a *single* extra exchange: B interrupts A's wind-up, lands hit. A's attack may still execute (if B missed or targeted someone else). Flurry = when both sides have gauge and keep countering. Risk: infinite loop (A winds up, B counters, A winds up, B counters...).

**Mitigation:** Cap counters per "exchange" (e.g. max 1 counter per attacker wind-up). Or: counter costs 50% gauge, so B can't counter again until gauge refills — natural limit.

**Pros:** No new state. Emergent. Counter window does the work.
**Cons:** Flurry feel depends on gauge refill rate. May not feel "flurry" if gauge is slow.

---

#### Flurry Option 2: Flurry Sub-Phase (Explicit)

**Mechanic:** When A attacks B and both survive, enter `STATE_IN_FLURRY` with `flurry_remaining = 3`. Resolve A's attack. B gets instant counter (reduced/zero wind-up) if B can respond. Resolve B's. A gets instant counter. Repeat until flurry_remaining == 0 or one dies.

**Interaction with counter:** Counter window and flurry sub-phase are *different*. Counter = interrupt during wind-up. Flurry = after attack resolves, rapid back-and-forth. Could combine: counter triggers flurry? E.g. B counters A → both enter flurry phase with 2 remaining blows each.

**Pros:** Dramatic. Explicit "we're in a flurry."
**Cons:** New state. Resolution order complex. "Instant" counter = no wind-up? Unrealistic for heavy weapons.

---

#### Flurry Option 3: Reduced Wind-Up After Parry (Riposte Chain)

**Mechanic:** After parry_deflect, defender's next attack has 50% wind-up (riposte bonus). If defender attacks immediately and hits, attacker is in recovery. Creates chain without explicit flurry state.

**Interaction with counter:** Counter = during wind-up. Riposte chain = after parry. Both create "rapid exchange" feel. Counter interrupts; riposte follows parry. Complementary.

---

#### Flurry Option 4: Binding State (Advanced)

**Mechanic:** parry_deflect → `bound_with_id`. While bound, only bind-resolution moves (short thrust, wind). Multiple quick actions in bind. Disengage = exit bind.

**Interaction with counter:** Counter happens *before* bind (during wind-up). Bind happens *after* parry. Different phases. Counter could prevent bind (counter kills attacker before they land).

---

### Counter Window + Flurry Summary

| Flurry approach | Counter window interaction | Effort |
|-----------------|----------------------------|--------|
| **1. Emergent** | Counter enables one extra exchange per wind-up. Natural limit from gauge cost. | Low (counter only) |
| **2. Sub-phase** | Counter could trigger flurry entry. Or separate. | High |
| **3. Riposte chain** | Counter and riposte are separate. Both add tempo. | Medium |
| **4. Binding** | Counter precedes bind. Bind = post-parry. | High |

**Suggested:** Implement **counter window** first. Flurries emerge from repeated counter opportunities (Option 1). Add **riposte chain** (reduced wind-up after parry) for more flow. Defer explicit flurry sub-phase and binding.

---

## 3. Stamina: HEMA & Medieval Combat Integration

### Real-Life Stamina in HEMA / Medieval Combat

**Sources (HEMA, reenactment, historical):**
- **Duration:** Armored combat exhausts in minutes. Unarmored duels can last longer but still fatigue.
- **Actions that cost energy:** Striking (especially heavy blows), blocking/parrying (absorbing impact), moving (footwork), holding guard.
- **Low stamina effects:** Slower strikes, weaker parries (can't hold against strong blows), reduced mobility, vulnerable to finishers.
- **Recovery:** Rest. Breathing. Not acting. In combat, brief pauses (bind, measure) allow partial recovery.

**KCD / games:** Stamina bar. Block drains it. Attack drains it. Sprint drains it. At 0: weak attacks, block breaks.

---

### Integration Approaches

#### Approach A: Gauge as Stamina (Over-Spend)

**Mechanic:** Attacks cost 80–120 by intensity. Parry costs 15. Gauge refills when idle. Below 100 = can't act. Below 50 = intensity cap 0.5.

**HEMA alignment:** Block/parry consumes energy ✓. Heavy strikes consume more ✓. Low stamina = weak ✓. Refill when idle ✓.

**Gap:** Gauge semantics shift: both "can I act" and "how much energy do I have."

---

#### Approach B: Separate Stamina Pool

**Mechanic:** New `stamina` 0–100. Gauge unchanged. Stamina consumed by attack (5–20), parry (10), block (15). At 0: can't parry, or attacks deal 50% damage.

**HEMA alignment:** Clear separation: readiness vs energy. Parry costs stamina ✓. Attack costs ✓. Block costs ✓.

**Gap:** Two numbers. More UI. But most accurate.

---

#### Approach C: Unified Pool (Gauge = Stamina = Readiness)

**Mechanic:** One pool. Acting consumes it. Refill when idle. Parry/block also consume gauge.

**HEMA alignment:** Simple. Parry consumes ✓. Defender could be "too tired to parry" (gauge 0).

**Gap:** Already partially true. Main add: parry/block consume. On parry, defender loses 15 gauge.

---

#### Approach D: Intensity Cap Only (No Pool)

**Mechanic:** "Exertion" debuff after N attacks. Intensity cap drops (e.g. 0.7 max). Recovers over time.

**HEMA alignment:** Weak. No "parry costs energy." Only "repeated attacks tire you." Partial.

---

### Realism Ranking

| Approach | HEMA realism | Medieval realism | Notes |
|----------|--------------|------------------|-------|
| **B (Separate)** | Highest | Highest | Parry, block, attack all cost. Historical: blocking heavy blows is exhausting. |
| **A (Gauge over-spend)** | High | High | Same idea, one pool. |
| **C (Unified)** | Medium–High | Medium–High | Parry consumes gauge. Defender "too tired to parry." |
| **D (Intensity cap)** | Low | Low | No defensive cost. Only attack fatigue. |

**Verdict:** **B** is most realistic for HEMA/medieval. **A** is good if you want one pool. **D** misses "blocking is exhausting."

---

## 4. Current System & Realism of Implementations

### How the System Currently Works

**Gauge:** 0–100. Fills at `agility × 0.5 × delta` when WAITING. Must be 100 to act. Drops to 0 when acting (wind-up start). No consumption for parry/block.

**States:** WAITING (gauge fills) → WIND_UP (gauge 0, wind-up timer) → execute attack → RECOVERING (gauge 0, recovery timer) → WAITING.

**Defense:** When attacked, defender is in WAITING or RECOVERING. DefenseChoiceResolver picks parry vs dodge. Parry uses capacity (momentum vs parry_c_d). No defender "spend" — parry is free.

**Recovery cause:** Set when entering RECOVERING: "skip", "attack_miss", "attack_deflect", "attack_hit". Used by AttackPathResolver (staggered → chest bias). **Not** used by readiness — readiness is uniform lerp(0.5, 0.85) for all recoveries.

**Readiness:** `get_passive_parry_readiness(c)` — WAITING = guard (0–1). RECOVERING = lerp(0.5, 0.85, progress). Same for all causes.

---

### Which Implementations Would Be More Realistic?

| Feature | Current | More realistic implementation |
|---------|---------|-------------------------------|
| **Recovery cause → readiness** | Uniform | **B (cause modifier):** attack_hit ×0.7, attack_miss ×0.95. Hit = more stunned. |
| **Stamina** | None | **B (separate pool)** or **A (gauge over-spend):** parry/block cost energy. |
| **Counter window** | None | **A (50% gauge):** "strike while his hand is rising." Historical tempo. |
| **Feint** | None | **A (explicit):** feint_part ≠ target_part. Historical. |
| **Diagonal line** | Single primary | **B (weighted roll):** physics variance. Zornhau crosses lines. |

**Summary:** Recovery cause modifier (B), stamina (B or A), counter window (A), feint (A), diagonal (B) all increase realism. Current system is abstract and doesn't model stamina, tempo interrupt, or cause-based readiness.

---

## 5. Diagonal Line Roll: Differences Between B and C

### Approach B: Weighted Roll at Resolve

**Mechanic:** Diagonal moves have `attack_lines: [{line, weight}, ...]`. E.g. oberhau: `[{"line": "high", "weight": 0.65}, {"line": "left", "weight": 0.35}]`. At resolve, roll once to pick effective attack_line. Use that for alignment, path, parry.

**Key:** Roll is **independent of defender**. Same probabilities every time. 65% high, 35% left for oberhau, regardless of defender's guard.

**Physics interpretation:** "Which line does the blade intersect first?" — varies by trajectory, blade angle. Random variation per exchange. Defender's position doesn't affect the roll.

---

### Approach C: Alignment-Weighted Roll

**Mechanic:** Roll weighted by defender's guard_line. If defender has high guard, 70% high / 30% left. If low guard, 50/50. Reflects "which line would my guard meet first given their position."

**Key:** Roll **depends on defender**. Defender with high guard → more likely "high" wins (their guard is there). Defender with low guard → 50/50 (guard not in the way of either).

**Physics interpretation:** "Which line would the defender's guard intersect first?" — depends on defender posture. High guard = blade meets high line first (defender's arms are up). Low guard = blade could meet either (defender's guard isn't predisposed).

---

### B vs C: Side-by-Side

| Aspect | B (Fixed Weighted) | C (Alignment-Weighted) |
|--------|---------------------|-------------------------|
| **Roll input** | Move only | Move + defender guard_line |
| **Probabilities** | Constant per move | Vary by defender |
| **Defender agency** | None — defender doesn't affect which line "wins" | High — defender's guard influences outcome |
| **Realism** | "Blade path varies" | "Blade meets defender's guard where it is" |
| **Tactical depth** | Low | High — guard high to bias high-line parry |
| **Implementation** | `attack_lines` on move; roll at resolve | Weight table: `DIAGONAL_WEIGHTS[move_id][guard_line]` |
| **Tuning** | One table per diagonal move | Table per (move, guard_line) — 4× more cells |

**Example:** Oberhau vs defender with high guard.
- **B:** Roll. 65% high, 35% left. Defender's guard irrelevant.
- **C:** Defender high guard → 70% high, 30% left. Defender's guard in high line makes "high" more likely to be the intersecting line.

**Verdict:** **B** is simpler and adds variance. **C** is more tactical and realistic (defender posture matters). **C** requires more data and tuning. If you want "defender's guard affects diagonal outcome," use **C**. If you want "diagonal parries aren't binary" with minimal change, use **B**.

---

## References

- FEINT_COUNTER_STAMINA_READINESS_DIAGONAL_INVESTIGATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- COMBAT_ISSUES_TODO_INVESTIGATION.md
- PassiveParryContext.gd
- AttackResolver.gd, CombatStateHandlers.gd
