# Afterblow Implementation: Approaches and Tradeoffs

Investigation of different ways to implement physically realistic afterblow — where a creature hit mid-swing can complete a *previously planned* attack **iff** the blow wasn't intense enough to hinder that action. Weighs pros and cons for each approach.

---

## IMPLEMENTED (as of implementation)

| Choice | Selected | Location |
|--------|----------|----------|
| **Flow** | C: Dedicated AfterblowHandler | `combat/AfterblowHandler.gd` |
| **Hindrance model** | 5: Hybrid | Immediate disqualifiers + score + threshold bands |
| **Supporting leg** | B: Stance | Inferred from dominant_hand (same side: right_arm → right_leg) |
| **Target defense** | A: Full resolution | `_execute_attack(B)` → full miss/dodge/parry/hit |
| **Damage** | Reduce by hindrance | `damage *= (1 - hindrance)`; floor 0.2 |
| **Scope** | B: B→A and B→C | Both mutual and third-party |
| **Intensity** | A: Add to result dict | `result["intensity"]` in resolve_attack |
| **Consciousness** | A: Existing threshold | `is_incapacitated()` / INCAPACITATION_CONSCIOUSNESS_THRESHOLD |

---

## 1. Design Goal (Physical Realism)

**Not HEMA ruleset:** Tournament afterblow is a time-window rule. We want **physics-based**: did the hit realistically disrupt the target's ability to finish their swing?

**Factors that hinder completion:**
- Damage to attacking arm (cut/blunt/bone)
- Damage to support structures (leg → balance, chest → wind, head → coordination)
- Intensity / momentum transfer
- Shock, structural failure (severed tendon, broken bone)

---

## 2. Flow Integration: Where to Hook

### Current Flow

1. A (attacker) executes → `_execute_attack(A)` → `resolve_attack(manager, A)` → returns `{ action: "hit", result_dict, ... }`
2. Damage already applied via `compute_and_apply_damage` (inside resolve_attack, before return)
3. `_handle_action_result` receives result; for "hit" it sets A to RECOVERING, emits signal

**Target B** can be in `STATE_WIND_UP` with `pending_attack` when A executes (simultaneous wind-ups; A finished first).

### Hook Options

| Option | Location | When |
|--------|----------|------|
| **A: CombatManager after hit** | In `_handle_action_result`, when `action == "hit"`, before setting A to RECOVERING | After damage applied; B's state unchanged |
| **B: AttackResolver before return** | In `resolve_attack`, after `compute_and_apply_damage`, before `atk.pending_attack = {}` | Before result returns; but resolver shouldn't trigger nested combat flow |
| **C: Dedicated AfterblowHandler** | New module; called from CombatManager with (manager, attacker_id, target_id, result_dict) | Clean separation; manager orchestrates |

**Recommendation: Option A or C.** CombatManager owns combat flow; afterblow is a follow-up to a hit. Option B keeps resolver as pure resolution logic; manager stays orchestrator. **Option C** is cleanest: `AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict) → bool` (returns true if afterblow occurred; manager then handles that result).

**Data at hook:** `result_dict` has `part`, `final_cut`, `final_blunt`, `final_bone`, `outcome` (hit/glancing/deflected), `died`. `pa` (A's pending_attack) is cleared before damage; `tgt` (B) still has `pending_attack` and `state == STATE_WIND_UP`. Intensity in B's pending_attack; hit intensity not in result_dict — need to pass or store. Check: `resolve_attack` has `intensity` from `pa.intensity`; result_dict doesn't include it. **Gap:** We need A's attack intensity at afterblow check. Options: (a) add `intensity` to result_dict, (b) store in a transient, (c) use B's pending_attack intensity (wrong — we need A's blow intensity). **Recommendation:** Add `intensity` to result_dict when building it in resolve_attack (or pass through from pa).

---

## 3. Hindrance Model Options

### Option 1: Hindrance Score (0–1) + Probabilistic Roll

**Mechanic:** Compute `hindrance = part_relevance × severity × intensity × outcome_mult`. `randf() < hindrance` → blocked.

| Factor | Weight | Notes |
|--------|--------|-------|
| Part relevance | 1.0 (attacking arm), 0.8 (head), 0.6 (chest), 0.5 (supporting leg), 0.3 (other leg), 0.2 (other arm) | From LINE_GUARD doc |
| Severity | (final_cut + final_blunt + final_bone) / threshold | Per-part or global threshold (e.g. 15) |
| Intensity | A's attack commitment 0.2–1.0 | Heavy blow = more disruption |
| Outcome | 0.6 if glancing, 1.0 if hit, 0 if deflected | Deflected = no contact |

**Pros:** Smooth gradient; captures nuance; tunable constants.  
**Cons:** Many knobs; severity threshold arbitrary; "supporting leg" requires knowing which leg supports the attack (stance model we don't have).  
**Simplification:** Use 0.5 for both legs (unknown which is support).

---

### Option 2: Hard Thresholds (Deterministic)

**Mechanic:**
- Attacking arm hit + (tissue destroyed OR bone broken) → always blocked
- Head hit + damage > Y → blocked
- Leg hit + severity > Z → blocked (fell)
- Else → allowed

**Pros:** Simple; predictable; easy to reason about.  
**Cons:** Binary; no "marginal" cases; light tap to head might not realistically stop a committed swing.  
**Physics fidelity:** Low — real response is probabilistic.

---

### Option 3: Per-Part Damage Check (State-Based)

**Mechanic:** Use existing part state:
- `body_cutting[arm] <= 0` or `body_blunt[arm] <= 0` or `bone_health[arm] <= 0` → arm disabled → blocked
- `bone_health[part] <= 0` (any hit part) → broken → blocked
- Consciousness / pain below threshold → blocked (shock)

**Pros:** Uses existing systems; no new thresholds; "severed arm cannot swing" is direct.  
**Cons:** Only catches structural failure; doesn't model "heavy blow to chest = wind knocked out but arm fine."  
**Physics fidelity:** Good for structural failure; weak for soft disruption.

---

### Option 4: Momentum / KE Threshold

**Mechanic:** `KE_at_impact > DISRUPT_KE_THRESHOLD` → blocked. Combines with part relevance (same KE to arm vs leg — arm more critical).

**Pros:** Physically grounded (momentum transfer).  
**Cons:** KE not in result_dict; would need to pass from damage pipeline (`WeaponDamageHelper.compute_kinetic_energy_j`). Single scalar ignores part.  
**Physics fidelity:** Medium; good for "heavy enough to disrupt" but coarse.

---

### Option 5: Hybrid (Recommended in LINE_GUARD Doc)

**Mechanic:**
1. **Immediate disqualifiers:** Attacking arm hit AND (tissue destroyed OR bone broken) → blocked. Head hit AND consciousness critical → blocked.
2. **Hindrance score** for rest: part_relevance × severity × intensity × outcome.
3. **Roll bands:** hindrance > 0.7 → blocked; hindrance < 0.3 → allowed; else `randf() < hindrance` → blocked.

**Pros:** Structural failure handled deterministically; marginal cases probabilistic; reduces extreme outcomes.  
**Cons:** More logic; thresholds to tune.  
**Physics fidelity:** High; combines state-based and continuous factors.

---

### Comparison Matrix

| Model | Complexity | Physics | Predictability | Tuning |
|-------|------------|---------|----------------|--------|
| **1: Score + roll** | Medium | High | Probabilistic | Many |
| **2: Hard thresholds** | Low | Low | Deterministic | Few |
| **3: Per-part state** | Low | Medium | Deterministic | None |
| **4: KE threshold** | Low | Medium | Deterministic | One |
| **5: Hybrid** | Medium | High | Mixed | Moderate |

---

## 4. B Attacks A vs B Attacks C

| Scenario | B's pending_attack targets | Action if hindered | Action if not hindered |
|----------|---------------------------|--------------------|-------------------------|
| **Mutual exchange** | A | B's attack cancelled | Resolve B→A (afterblow) |
| **B attacking third party** | C | B's pending_attack cancelled | B's attack still executes (B's turn) — but when? |

**Mutual exchange (B→A):** Straightforward. Afterblow = B hits A back in the same exchange. Resolution order: A's damage to B applied first, then B's damage to A.

**B attacking C:** B was winding up on C when A hit B. If hindered: cancel B's pending_attack (B never completes). If not hindered: B's attack should still go off — but the current flow has B in STATE_WIND_UP waiting for `state_timer >= state_duration`. B never reaches that because we're in the middle of A's resolution. Options:
- **A:** Only implement afterblow for mutual (B→A). When B→C and not hindered, leave B's pending_attack as-is; B will complete wind-up on next frame/tick and then execute. Problem: B's wind-up duration already elapsed? No — B was still in wind-up when A struck. So B's state_timer is mid-count. We'd need to either (a) let B continue (wind-up resumes next frame), or (b) immediately resolve B→C if not hindered (treat as "B's swing completed in same moment"). (b) is cleaner: "B was swinging at C; A hit B; B wasn't hindered, so B's blow lands on C now."
- **B:** Defer B→C case. Only implement B→A (mutual). B→C: if hindered, cancel; if not hindered, do nothing (B's attack effectively delayed — we don't resolve it now; B stays in wind-up and will execute when timer fires). But that could cause double-resolution if B's timer also fires this frame. Need to cancel B's state and not re-enter wind-up.
- **C:** If not hindered for B→C, immediately call resolve for B→C (same as afterblow for B→A). Keeps logic uniform. Order: A hits B → damage applied → check B.pending_attack → if targets A, resolve B→A; if targets C, resolve B→C. In both cases, "not hindered" = resolve now.

**Recommendation:** Implement both B→A and B→C. "Not hindered" = resolve B's attack immediately (whether target is A or C). "Hindered" = cancel B's pending_attack, set B to RECOVERING (or WAITING) so B doesn't double-execute. Ensures one code path for "can B complete their swing?"

---

## 5. Afterblow Damage Modification

**Question:** If B completes afterblow, is B's blow at full strength?

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **Full damage** | No modifier | Simple; "blow didn't hinder form" | Unrealistic for high hindrance that barely allowed |
| **Reduce by hindrance** | damage × (1 - hindrance) | Wounded striker = weaker | Hindrance was used for block/allow; reusing for damage is consistent |
| **Reduce by severity** | damage × (1 - severity_factor) | Part-based | Extra factor |
| **No reduction** | Full damage | Simplest | Best when hindrance bands (0.3/0.7) ensure only clearly non-hindering cases allow |

**Recommendation:** Start with **full damage**. If afterblow feels too strong when hindrance was marginal (0.3–0.5), add `damage *= lerp(1.0, 0.5, hindrance)` or similar for the probabilistic band.

---

## 6. Execution Flow: Nested Resolution

**When afterblow allowed (B→A or B→C):**

1. B has pending_attack; B is in STATE_WIND_UP.
2. We need to resolve B's attack. Options:
   - **Call `resolve_attack(manager, B.id)`** — but B's pending_attack is for B as attacker. resolve_attack expects attacker_id and reads that combatant's pending_attack. So we'd call it with B as attacker. Problem: resolve_attack clears `atk.pending_attack` at the start of the hit path. We're past that — A's resolution already completed. B's pending_attack is intact. So we can call `resolve_attack(manager, B.id)`. B will be attacker, B's target from pending_attack will be A or C. **This works.**
   - **Or** a lighter "resolve afterblow" that only does the hit path (no miss/dodge/parry for the afterblow target — the target is caught flat-footed). LINE_GUARD doc: "A's damage applied first, then B's." So B's attack resolves against A (or C). Should A (or C) get to defend? Realism: A just struck; A might be in recovery or commitment. Giving A a defense roll could be realistic. Simpler: afterblow = B's attack always hits (no defense). Or: give A reduced parry/dodge (A is committed). **Design choice.**

**Recommendation:** Use **full `resolve_attack(manager, B.id)`**. B's attack goes through normal resolution — miss, dodge, parry, hit. More realistic: even an afterblow can be parried or dodged if the target reacts. Simpler: reuse existing pipeline. Downside: afterblow might "miss" or be parried, which could feel odd ("I hit you, you hit back, but you missed?"). Alternative: add `force_hit: true` for afterblow context to skip defense. **Recommendation:** Full resolution; if playtests show afterblows rarely landing, consider reduced defense or force_hit for afterblow.

---

## 7. State Management

**Before afterblow resolution:**
- A: in RECOVERING (from _handle_action_result's hit branch) — or not yet, if we do afterblow before that
- B: STATE_WIND_UP, pending_attack set
- B's target (A or C): unchanged

**When we resolve B's attack:** We call `resolve_attack(manager, B.id)`. That will:
1. Read B's pending_attack
2. Potentially clear it (in hit path)
3. Set B to RECOVERING
4. Apply damage to A or C
5. Return

**Critical:** We must **not** have already set A to RECOVERING before doing afterblow. So the hook order in _handle_action_result should be:
1. If action == "hit", get result_dict, tgt (B)
2. Check B.pending_attack, B.state == WIND_UP
3. If present, run afterblow check
4. If afterblow allowed: resolve B's attack (which will set B to RECOVERING, possibly kill A, etc.)
5. Then apply A's recovery (set A to RECOVERING) — A might be dead, so check
6. Emit signals, check winner

**Conflict:** _handle_action_result for "hit" currently sets A to RECOVERING, emits, returns. If afterblow kills A, we need to handle death before setting A to RECOVERING. So: run afterblow first; if B→A and B kills A, the nested resolve will return death; we need to handle that. The nested `resolve_attack(B)` returns; we don't call _handle_action_result for it — we'd need to. So the flow is:
- `_execute_attack(A)` returns result
- `_handle_action_result(result)` for hit:
  - Do afterblow check
  - If afterblow: call `_execute_attack(B)` or equivalent. That will call `resolve_attack(B)` and then... `_handle_action_result` is tied to `_execute_attack`. So `_execute_attack` does resolve + handle. So we'd call `_execute_attack(B)`. That triggers `_handle_action_result` for B's result. So we get recursive handling. Need to ensure no infinite loop: B's target is A or C; neither has pending_attack targeting B. Good.
  - After afterblow (if any), continue with A's hit handling (recovery, emit).

**Cleaner:** Extract "handle one attack result" into a function. For hit: apply A's recovery; optionally, before that, if afterblow: call `_execute_attack(B)` which will recursively handle B's result. So we have:
```
if action == "hit":
  if tgt.pending_attack and tgt.state == WIND_UP:
    try afterblow
    if afterblow triggered:
      _execute_attack(tgt.id)  # B executes; handles its own result
  # Now continue with A
  atk.state = RECOVERING
  emit_signal(...)
```

B's execution will emit its own action_resolved. So we get two emissions for one "exchange" — A's hit, then B's afterblow. UI/timeline may need to show both. Good.

---

## 8. Summary: Recommended Approach

| Decision | Recommendation |
|----------|----------------|
| **Hook** | CombatManager, in _handle_action_result when action=="hit", before A's recovery |
| **Hindrance model** | Hybrid (Option 5): immediate disqualifiers + score + threshold bands |
| **B→A vs B→C** | Both: if not hindered, resolve B's attack immediately (target A or C) |
| **Damage** | Full damage for afterblow; optional reduction in marginal band later |
| **Resolution** | Full resolve_attack(B) — B's attack gets normal miss/dodge/parry/hit |
| **Intensity** | Add A's intensity to result_dict for hindrance |
| **Module** | Optional: AfterblowHandler.try_afterblow(manager, attacker_id, target_id, result_dict) |

---

## 9. Open Questions

1. **Supporting leg:** Use 0.5 for both legs or add stance?
2. **Afterblow parry:** Allow target to parry afterblow, or force hit for speed?
3. **Multi-combatant:** If B→C and C dies from afterblow, combat end check in nested handle?
4. **UI:** How to present "A hit B, then B hit A" in one exchange? Single "exchange" event or two sequential?

---

## References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md Part 3
- CombatManager.gd _execute_attack, _handle_action_result
- AttackResolver.gd resolve_attack, compute_and_apply_damage
- BodyPartQuery.gd, CoreEntity.get_attacking_arm
- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md
