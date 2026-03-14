# Combat Issues: Todo List & Implementation Options

A structured investigation of open combat system issues, with pros and cons for each implementation method so you can choose the optimal approach. Ordered by impact and dependencies.

---

## Todo List (Priority Order)

| # | Issue | Status | Section |
|---|-------|--------|---------|
| 1 | **Arm interpose (BP6)** | **Implemented** | §1 |
| 2 | **Diagonal cut line roll** | Keep primary / Weighted roll | §2 |
| 3 | **Parry variance approach** | Current vs separate geometry | §3 |
| 4 | **Master strike (early parry)** | Skip / Implement | §4 |
| 5 | **Recovery cause & readiness** | Uniform vs cause-based | §5 |
| 6 | **preferred_parts per move** | Weighted random vs cut–part match | §6 |
| 7 | **Feint (telegraph vs real)** | None / Implement | §7 |
| 8 | **Counter window (tempo)** | None / Partial gauge | §8 |
| 9 | **Combos** | None / Implement | §9 |
| 10 | **Measure / distance** | None / Abstract bands | §10 |

---

## §1. Arm Interpose (BP6) — **Implemented**

**Was:** Hit part = weighted random. No "arm blocks head" geometry.

**Implemented:** When `part == "head"` after weighted selection, roll `p_interpose = INTERPOSE_BASE × exposure(attack_line, guard_line)`. If success, redirect to left_arm or right_arm (based on attack_line: left→left_arm, right→right_arm, high/low→50% either).

**Location:** `AttackResolver.gd` (before compute_and_apply_damage); `CombatConstants.gd` (INTERPOSE_BASE, INTERPOSE_EXPOSURE).

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A: Skip** | Keep weighted random. | Simplest. No new logic. | Head hits may feel too common; no arm blocks. |
| **B: Implement** ✓ | When `target_part == "head"`, roll `p_interpose = INTERPOSE_BASE × exposure(attack_line, guard_line)`. If success, redirect to left_arm or right_arm. | Physics: limb intercepts blade path. Head shots less common when arms up. | Needs exposure table (attack_line × guard_line). INTERPOSE_BASE (~0.10) tuning. More branching. |
| **C: Defer** | Do nothing now; revisit after calibration. | Keeps scope small. | Head may feel over-targeted in playtests. |

---

## §2. Diagonal Cut Line Roll (BP1)

**Current:** Diagonal moves (oberhau, diagonal_chop) have single primary `attack_line`.

**Physics:** Zornhau crosses high and left. Which line the guard meets first varies by trajectory.

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **A: Keep primary** | oberhau = "high", diagonal_chop = "left". One line per move. | Simple. No extra roll. | Diagonal parries feel binary. Same outcome every time. |
| **B: Weighted roll** | At resolve, roll: 65% high, 35% left for descending diagonal. Adds variance per exchange. | Physics: path crosses lines; which intersects first varies. More varied outcomes. | Extra roll per diagonal move. Need line_weights per move. Slightly more complex. |

**Recommendation:** **A** for now. **B** if diagonal parries feel too predictable.

---

## §3. Parry Variance Approach

**Current:** Geometry variance scales technique variance: `variance_eff *= clamp(1/alignment, 1, 2.5)`. Agility still affects base technique variance.

**Alternative:** Separate geometry variance `= PARRY_GEOMETRY_VARIANCE_BASE × clamp(1/alignment, 1, 2.5)` instead of scaling technique.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: Keep current** | Technique variance × geometry scale. Agility reduces both. | Simpler. One variance path. Agility improves parry quality across the board. | Geometry and technique conflated. Hard to tune alignment effect independently. |
| **B: Separate geometry** | Add pure geometry variance; technique variance independent. | Clear separation: technique = skill; geometry = guard position. Easier calibration. | Two variance sources. PARRY_GEOMETRY_VARIANCE_BASE (0.08) tuning. |

**Recommendation:** **A**. Only switch to **B** if calibration shows alignment effect is too weak or too strong relative to agility.

---

## §4. Master Strike (Early Parry → Auto Counter)

**Current:** parry_deflect → attacker recovery, defender WAITING. Tempo penalty gives defender gauge advantage. No guaranteed counter.

**KCD / HEMA:** Block during early attack phase → automatic, unavoidable counter.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: Skip** | Rely on tempo penalty + guard dynamics. Riposte emerges from gauge advantage. | Physics-based. No "unavoidable" mechanic. Matches HEMA realism (no guaranteed counter). | No explicit "master strike" reward. Early parry feels same as late parry. |
| **B: Implement** | parry_deflect in early wind-up (e.g. first 30%) → defender gets automatic counter before attacker executes. | KCD-style reward. "Catch attack early = control." Satisfying for skilled play. | Gamey: guaranteed hit. HEMA: counter can still be parried. Overpowered if tuned wrong. |
| **C: Partial** | Early parry → defender gets gauge boost (e.g. +30) instead of guaranteed counter. | Rewards timing without "unavoidable." Still physics-ish. | Less dramatic than full master strike. |

**Recommendation:** **A** for physics focus. **C** if you want a timing reward without guaranteeing a hit. **B** only for strong KCD clone feel.

---

## §5. Recovery Cause & Readiness Scaling

**Current:** Readiness (parry capacity when recovering) uses same lerp(0.5, 0.85) for all recoveries. No `recovery_cause`.

**Question:** Should readiness differ by *why* they're recovering (hit vs miss vs parried) or by *incoming attack type*?

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: Uniform** | Same readiness curve for any recovery. | Simple. No extra state. | "Recovering from hit" may deserve worse parry than "recovering from whiff." |
| **B: Cause-based** | Store `recovery_cause` ("hit", "miss", "deflect", "medical"). Different readiness curve per cause. | Hit → more stunned → lower readiness. Miss → off-balance but less stunned. | New state. Tuning per cause. More branching. |
| **C: Attack-type on readiness** | Incoming thrust → lower readiness (harder to react). Cut → same or higher. | Thrust is faster, less telegraph. Cut has more visible arc. | Pass attack_type into parry calc. More parameters. |

**Recommendation:** **A** unless playtests show recovering defenders parry too well. **B** is the next step if needed.

---

## §6. preferred_parts per Move (Cut–Part Compatibility)

**Current:** target_part from BODY_PART_TARGET_WEIGHTS when unspecified. Cut type doesn't bias target.

**Physics:** Oberhau → head; Unterhau → legs; thrust → center. Cut geometry implies path.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: Weighted random only** | Keep current. All parts from global weights. | Simple. | Ignores cut geometry. AI may thrust to legs, overhead to chest. |
| **B: preferred_parts** | Each move has `preferred_parts: Array`. AI scores these higher when selecting target. | Cut type implies path. Oberhau → head. Thrust → chest. No resolution change. | Static. Doesn't account for defender guard. Need to add per move. |
| **C: preferred_parts + guard** | B + unguarded preferred part gets bonus. "Attack exposed head when they guard low." | Tactical. Combines geometry and defender state. | Requires guard already affects parry (done). More AI scoring logic. |

**Recommendation:** **B** minimum. **C** if you want tactical target selection. Low effort; high realism payoff.

---

## §7. Feint (Telegraph vs Real Target)

**Current:** No feint. Attack target is the real target.

**HEMA:** Feint = threaten line A to draw parry; disengage; hit line B. Single-tempo action.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: None** | Only real attacks. | Simple. | No mind-games. Italian sources: feint is central. |
| **B: Feint as telegraph** | `feint_part` ≠ `target_part`. Defender sees feint (or infers); guards wrong part → parry penalty. | Historical. Giganti: cavazione baits response. Tactical depth. | Two-phase commitment. Defender needs reaction logic. Feint cost: ~10% wind-up (Fabris). |
| **C: Probabilistic** | X% chance actual target ≠ expected. | Simple. Emergent deception. | Not intentional feint. Attacker doesn't "threaten then redirect." |

**Recommendation:** **A** unless you want feint system. **B** is highest fidelity but adds telegraph/commitment flow. Medium effort.

---

## §8. Counter Window (Tempo / Partial Gauge)

**Current:** Act only when gauge = 100. No interrupt.

**HEMA:** "When he raises his sword... strike while his hand is rising." Opponent committed = your opportunity.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: None** | Current. Gauge must be full. | Simple. | Misses tempo play. Opponent in wind-up = no response. |
| **B: Partial gauge counter** | During enemy wind-up, spend 50% gauge → immediate action; resolves before attack. | Captures Dall'Agocchie tempo. "Time for one movement cannot be used for another." | Order: counter resolves first. Attacker may "lose" to counter. Balance: 50% cost, only when wind-up active. New decision for player/AI. |
| **C: Stricter** | 60% gauge, or only when wind-up > 50% progress. | Reduces counter spam. | More tuning. May feel restrictive. |

**Recommendation:** **A** to keep scope small. **B** for tempo-driven play. High impact, medium effort. Requires UI for "counter" option.

---

## §9. Combos (KCD / KDF Style)

**Current:** No combo system. Each attack independent.

**KCD:** Sequence [head → right_upper → left_lower]. All connect in order → finisher bonus damage.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: None** | Keep current. | Simple. | No combo flow. Less KCD feel. |
| **B: Implement** | Combo definition: `{ "id": "scatter", "sequence": ["head", "right_arm", "left_leg"], "finisher_mult": 1.5 }`. State: `combo_progress`. Mental stack: "combo in progress → next step." On hit: increment or apply finisher. On miss/parry: clear. | KCD-style. Satisfying chains. AI can exploit openings. | New state. Combo definitions per weapon. Mental stack layer. UI for progress. |
| **C: Data only** | Add combo defs; no special UI. Log "Combo finisher!" when triggered. | Lower effort. Core logic only. | Less visible feedback. |

**Recommendation:** **A** unless KCD feel is a goal. **C** if you want combos without UI overhead.

---

## §10. Measure / Distance

**Current:** No distance. All attacks "in range."

**Physics:** Bind at close (~30–40 cm). At long measure, cuts may fall short. Different techniques at different ranges.

| Option | Description | Pros | Cons |
|--------|-------------|------|-----|
| **A: No measure** | Keep abstract. | Simple. | Historical: measure is fundamental. |
| **B: Measure bands** | Close / mid / long. Parry/counter efficacy by band. | High realism. Bind at close. | Needs distance state. How set? Tiles? Abstract steps? Significant scope. |
| **C: Tempo-as-measure** | "In measure" = can hit in one tempo. "Out" = must "close" first (action). | Abstract. No spatial distance. | Conflates distance and readiness. Possible for abstract system. |

**Recommendation:** **A**. **B** and **C** are large features. Defer unless you add spatial/distance abstraction.

---

## Summary: Suggested Choices

| Issue | Suggested Option | Rationale |
|-------|------------------|-----------|
| 1. Arm interpose | B (implemented) | Head→arm redirect when guard exposes arms in path |
| 2. Diagonal line roll | A (keep primary) | Add weighted roll if diagonal parries feel binary |
| 3. Parry variance | A (keep current) | Change only if calibration demands it |
| 4. Master strike | A (skip) or C (partial) | Physics-first: avoid guaranteed counter |
| 5. Recovery cause | A (uniform) | Add cause-based only if needed |
| 6. preferred_parts | B (add) | Low effort, high realism |
| 7. Feint | A (none) | Add B if you want mind-games |
| 8. Counter window | A (none) | Add B for tempo play; medium effort |
| 9. Combos | A (none) or C (data) | Add if KCD feel is priority |
| 10. Measure | A (none) | Defer; large scope |

---

## References

- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- COMBAT_SYSTEM_ISSUES.md
- IMPORTANT_IMPROVEMENTS_IMPLEMENTATION_ROADMAP.md
