# Attack Path & Defender Body Positioning: Integration Investigation

Investigation into ways to better integrate attack path and defender body positioning so that attacks interact with the target more realistically based on their current state and reactions—**without 3D geometry**.

---

## Implementation Status

| Phase | Approach | Status |
|-------|----------|--------|
| **1** | Guard-dependent paths | **Implemented** — `ATTACK_PATHS_BY_GUARD` in CombatConstants; AttackPathResolver uses `get_attack_path(attack_line, guard_line)` |
| 2 | Reaction state at contact | Not started |
| 3 | Intended target | Not started |
| 4 | Recovery cause | Not started |

---

## 1. Current State Summary

### 1.1 What Exists

| Component | Location | Behavior |
|-----------|----------|----------|
| **Attack paths** | `CombatConstants.ATTACK_PATHS` | One path per `attack_line` (high/low/left/right). Ordered sequence of parts blade passes through. E.g. high: `[left_arm, right_arm, head, chest, left_leg, right_leg]`. |
| **Path intercept** | `AttackPathResolver.resolve_hit_part()` | Guard alignment (0–1) determines how far along the path the blade gets. High alignment → early intercept (indices 0–2); low → full path. |
| **Guard line** | `combatant.guard_line` | "high" \| "low" \| "left" \| "right". Updated after attack recovery, after parry deflect. Used for parry alignment and path intercept. |
| **Line alignment** | `CombatConstants.get_line_alignment()` | cos(θ) from angle between attack_line and guard_line. Same line = 1.0; opposite = 0; adjacent ≈ 0.7. |
| **Partial dodge** | `pa.partial_dodge_part` | When defender partially dodges, hit part is fixed to `dodge_eval_part` (or weighted random). Path resolver is bypassed. |

### 1.2 Hit Resolution Flow (AttackResolver)

```
1. Defense choice (parry vs dodge)
2. If parry_deflect → done
3. If parry_partial → attacker continues, velocity reduced
4. If dodge_full → done
5. If dodge_partial → pa["partial_dodge_part"] = dodge_eval_part; fall through to hit
6. If hit:
   - If partial_dodge_part set → use that part
   - Else → AttackPathResolver.resolve_hit_part(atk_line, guard_line, targetable)
   - Fallback: BodyPartConstants.get_weighted_random_part(targetable)
```

### 1.3 What the Path Resolver Receives

| Input | Source | Used For |
|------|--------|----------|
| `attack_line` | Move definition (from attack_type) | Path lookup |
| `guard_line` | `tgt.guard_line` | Path lookup, alignment → intercept_max |
| `targetable` | `tgt.node.get_targetable_parts()` | Filter path to valid parts |

**Not passed:** defender state, recovery_cause, intended_part, posture, passive_parry_attempted, dodge_eval_part (when not partial dodge).

---

## 2. Identified Gaps

### 2.1 Anatomical Inaccuracy

**Problem:** Paths are fixed per attack_line, not per defender posture. When defender has **low guard** vs a **high attack**, anatomically the head is exposed first (arms down). Current high path puts arms first regardless: `[left_arm, right_arm, head, chest, ...]`. That assumes defender has arms up.

**Impact:** High attack vs low guard should hit head more often; current system can still hit arms early in path when they're not in the way.

### 2.2 No Reaction State at Contact

**Problem:** Path resolver doesn't know *what the defender was doing* at contact:
- **WAITING** (ready, guard up) vs **RECOVERING** (committed, arms in motion)
- **Dodging** (partial) → body twisting; contact distribution should favor limbs
- **Parry attempted** (passive_parry_attempted) → blade met blade; if hit, it's a slip/glancing

**Impact:** Same path used whether defender was standing still or mid-dodge. No "twisting into the blade" effect.

### 2.3 No Intended Target

**Problem:** Attacker never commits to a target part. Actions are `{ target_id, move_id }` only. Path resolver samples from path segment; no "I aimed at his head, but his arm was in the way" semantics.

**Impact:** AI can't tactically target unguarded zones. No intent-vs-outcome for feints or tactical play.

### 2.4 Guard Line Staleness

**Problem:** `guard_line` is set when recovery completes or after parry. During RECOVERING, body posture may not match guard_line (e.g. just finished low cut → arms low, but guard_line might not yet reflect that).

**Impact:** Path assumes guard_line = current limb position. Can be wrong during/just after recovery.

### 2.5 Partial Dodge Uses Random Part

**Problem:** `dodge_eval_part` is chosen by DefenseChoiceResolver via `get_weighted_random_part(targetable)` for dodge evaluation. When partial dodge occurs, that part becomes the hit. But it's not "defender twisted and exposed this part"—it's the part we evaluated for dodge chance.

**Impact:** Partial dodge hit location is somewhat arbitrary; doesn't model "dodging left exposed right arm."

---

## 3. Proposed Approaches (Prioritized)

### Approach A: Guard-Dependent Paths (High Priority, Low Effort)

**Idea:** Path varies by `(attack_line, defender.guard_line)`. When defender has high guard, high attack path = arms first. When low guard, high attack path = head first (anatomical).

**Data:**
```gdscript
# CombatConstants: path per (attack_line, defender_guard_line)
const ATTACK_PATHS_BY_GUARD: Dictionary = {
    "high": {
        "high": ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"],
        "low":  ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"],
        "left": ["left_arm", "head", "chest", "right_arm", "left_leg", "right_leg"],
        "right": ["right_arm", "head", "chest", "left_arm", "left_leg", "right_leg"]
    },
    "low": { "high": [...], "low": [...], "left": [...], "right": [...] },
    "left": { ... },
    "right": { ... }
}
```

**Logic:** `path = ATTACK_PATHS_BY_GUARD[attack_line][guard_line]`. Intercept unchanged. Path now reflects "what's in the blade's way given defender posture."

**Effort:** Low. Replace `ATTACK_PATHS` lookup in AttackPathResolver. Add 4×4 path table.

**Realism:** High. Fixes anatomical inaccuracy.

---

### Approach B: Reaction State at Contact (Medium Priority, Low Effort)

**Idea:** Pass defender state into AttackPathResolver. Use it to modify path weights or intercept.

**Data:** Already available: `tgt.state`, `pa.partial_dodge_part`, `pa.passive_parry_attempted`.

**Logic:**
- **RECOVERING:** Defender's limbs may be in motion. Option: use `recovery_cause` (if stored) to infer posture; or treat as "less predictable" → slightly expand path segment.
- **Partial dodge (partial_dodge_part set):** Already bypasses path—we use that part. Could refine: when partial dodge, defender was moving; bias toward limbs (twisting into blade). Current: part is dodge_eval_part. Could add limb bias when sampling if we ever used path for partial dodge (we don't).
- **Parry attempted + hit:** Blade met blade first; hit is "through" or "slip." Path could weight limbs (defender's arms in the way) more. Optional refinement.

**Effort:** Low. Extend `resolve_hit_part(atk_line, guard_line, targetable, defender_context: Dictionary)` with optional modifier.

**Realism:** Medium. Refines contact distribution for edge cases.

---

### Approach C: Intended Target (Medium Priority, Medium Effort)

**Idea:** Attacker commits to `target_part` (intended) when choosing action. Path resolver biases toward intended part when in path segment; guard/posture can still block (arm in the way).

**Data:**
- Extend actions: `{ target_id, move_id, target_part? }`
- `AvailableActionsBuilder`: For attacks, optionally add target_part per (target_id, move_id). Could be from AI scoring (unguarded bonus) or player choice.
- `pending_attack`: Add `target_part` or `intended_part` from action choice.

**Logic:**
1. Path resolver receives `intended_part` (optional).
2. If intended_part in path_segment → boost weight (e.g. 2×) when sampling.
3. If intended_part not in path_segment → use path as normal (guard blocked it).
4. Result: "I aimed head, hit arm" when guard puts arm in path; "I aimed head, hit head" when unguarded.

**Effort:** Medium. Requires:
- AvailableActionsBuilder to emit target_part for attacks (or AI picks it)
- CombatStateHandlers / TurnReadyHandler to pass target_part into pending_attack
- AttackPathResolver to accept and use intended_part
- CombatAIActionPicker to score by target_part (unguarded bonus)

**Realism:** High. Matches real combat (intent vs. outcome).

---

### Approach D: Recovery Cause → Posture (Lower Priority, Low Effort)

**Idea:** Store `recovery_cause` when entering RECOVERING. Use to infer posture when guard_line might be stale.

**Data:** `combatant.recovery_cause = "attack_hit" | "attack_miss" | "attack_deflect" | "parry_partial" | "medical"`. Set in AttackResultApplier / CombatStateHandlers.

**Logic:** When resolving hit, if defender is RECOVERING: `recovery_cause == "attack_deflect"` → arms were high (parrying). `recovery_cause == "attack_hit"` → arms might be down (staggered). Use to pick path or modify intercept. E.g. deflect → use guard_line. Hit → use "low" or "mid" for path even if guard_line is "high."

**Effort:** Low. One field, set at transition. Path resolver uses when defender is RECOVERING.

**Realism:** Medium. Reduces guard_line staleness.

---

### Approach E: Path Index Overlap (Guard Coverage) (Lower Priority, Medium Effort)

**Idea:** Guard "covers" specific path indices. Blade travels; first unprotected index = hit.

**Data:** `GUARD_COVERAGE[attack_line][guard_line] = [indices]` e.g. high guard vs high attack = [0,1] (arms, head). Low guard vs high = [] (nothing).

**Logic:** Blade travels path. Indices 0..N. Guard blocks indices in coverage. First index not in coverage = hit. More explicit than intercept.

**Effort:** Medium. New table. Different resolution model.

**Realism:** High. Explicit blade–guard intersection.

---

## 4. Implementation Roadmap

### Phase 1: Guard-Dependent Paths (Approach A)

1. Add `ATTACK_PATHS_BY_GUARD` to CombatConstants (4×4 paths).
2. In AttackPathResolver, change lookup: `path = ATTACK_PATHS_BY_GUARD.get(attack_line, {}).get(guard_line, ATTACK_PATHS.get(attack_line, []))`.
3. Keep intercept logic unchanged.
4. **Result:** Anatomically correct paths. High attack vs low guard = head first.

### Phase 2: Reaction State (Approach B)

1. Extend `resolve_hit_part(attack_line, guard_line, targetable, defender_ctx: Dictionary)`.
2. `defender_ctx` = `{ "state": tgt.state, "passive_parry_attempted": pa.get("passive_parry_attempted", false), "recovery_cause": tgt.get("recovery_cause", "") }`.
3. When RECOVERING + recovery_cause == "attack_hit": optionally bias path toward center mass (staggered posture).
4. When passive_parry_attempted + hit: optionally boost limb weights (arms in the way).
5. **Result:** Contact distribution reflects defender reaction.

### Phase 3: Intended Target (Approach C)

1. AvailableActionsBuilder: For each attack action, add `target_part` from AI or expand to (target_id, move_id, target_part) with target_part from weighted choice (unguarded bonus).
2. CombatStateHandlers: When starting attack wind-up, copy `target_part` into `pending_attack`.
3. AttackPathResolver: Accept optional `intended_part`. When in path_segment, use weighted sampling with boost for intended_part.
4. CombatAIActionPicker: Score actions by target_part (unguarded_bonus when guard doesn't cover part).
5. **Result:** "I aimed at his head" semantics; tactical target selection.

### Phase 4 (Optional): Recovery Cause (Approach D)

1. AttackResultApplier / CombatStateHandlers: Set `recovery_cause` when transitioning to RECOVERING.
2. AttackPathResolver: When defender RECOVERING, use recovery_cause to refine path or intercept.
3. **Result:** Posture reflects "what just happened."

---

## 5. Data Flow Changes

### Current

```
Action: { target_id, move_id }
  → pending_attack: { target_id, attack_type, intensity, ... }
  → Hit: AttackPathResolver.resolve_hit_part(atk_line, guard_line, targetable)
  → part
```

### After Phase 1

```
Same, but path = f(attack_line, guard_line) from ATTACK_PATHS_BY_GUARD
```

### After Phase 2

```
AttackPathResolver.resolve_hit_part(atk_line, guard_line, targetable, defender_ctx)
defender_ctx = { state, passive_parry_attempted, recovery_cause }
```

### After Phase 3

```
Action: { target_id, move_id, target_part? }
  → pending_attack: { target_id, attack_type, intensity, target_part?, ... }
  → Hit: AttackPathResolver.resolve_hit_part(..., intended_part=pa.get("target_part",""))
  → part (biased by intended when in path)
```

---

## 6. Summary

| Goal | Approach | Effort | Realism Gain |
|------|----------|--------|--------------|
| Anatomically correct paths | A: Guard-dependent paths | Low | High |
| Reaction affects contact | B: Reaction state | Low | Medium |
| Attacker aims at part | C: Intended target | Medium | High |
| Posture from last action | D: Recovery cause | Low | Medium |
| Explicit guard coverage | E: Path index overlap | Medium | High |

**Recommended first step:** **Approach A (guard-dependent paths)**. Single table change, fixes the main anatomical inaccuracy. Then B and C as refinements. D and E are optional enhancements.

---

## References

- GUARD_POSITION_WEAPON_BODY_INTERACTION_INVESTIGATION.md
- BODY_PART_BLOCKING_PATHWAYS_INVESTIGATION.md
- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md
- AttackPathResolver.gd, AttackResolver.gd, CombatConstants.gd
- DefenseChoiceResolver.gd, PassiveParryContext.gd
