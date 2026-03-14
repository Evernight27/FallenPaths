# Guard Position & Weapon–Body Interaction: Investigation

Investigation into different ways to track guard position so that weapon positioning and swinging realistically interact with the target's body parts, depending on swing path and the opponent's reactions/positioning—**without 3D geometry**.

---

## 1. Current State

### 1.1 What We Track

| Data | Location | When Updated | Used For |
|------|----------|--------------|----------|
| **guard_line** | combatant | After attack (recovery complete), after parry (deflect/partial) | Parry alignment, path intercept, transition cost |
| **guard** (scalar 0–1) | combatant | Rises when idle; drops when attacking | Parry capacity (readiness × guard) |
| **attack_line** | move definition | Static | Parry alignment, path selection, transition cost |
| **readiness** | PassiveParryContext | WAITING = guard; RECOVERING = lerp(early, late) | Parry capacity |
| **off_balance_until** | combatant | After miss/parry_deflect | Parry penalty, gauge fill penalty |
| **parry_bonus_until** | combatant | After parry_deflect | Parry capacity bonus |

### 1.2 What We Don't Track

| Gap | Impact |
|-----|--------|
| **Posture / limb elevation** | Guard line is discrete (high/low/left/right). We don't know *how* high the arms are. High guard with arms at 45° vs 90° affects what's in the path. |
| **Reaction state at contact** | We know WAITING vs RECOVERING, but not "was defender dodging?" or "was defender mid-parry attempt?" at the moment of contact. Partial dodge stores `partial_dodge_part` but not posture shift. |
| **Guard-dependent paths** | Path is fixed per attack_line. When defender has low guard vs high attack, anatomically head is first; we use a path that assumes high guard (arms first). |
| **Intended target** | Attacker doesn't commit to a target before resolution. Swing path is generic; we don't have "aiming at head" vs "aiming at leg" to refine path. |
| **Weight distribution / stance** | Lead leg, leaning, etc. affect what's exposed. Not modeled. |
| **Blade position during swing** | We have attack_line (start/end) but not "blade at 30% of arc" for partial contact. |

---

## 2. Approaches to Improve Guard & Weapon–Body Interaction

### Approach A: Guard-Dependent Paths (Path Per Attack×Guard)

**Idea:** Instead of one path per attack_line, define path per (attack_line, guard_line). When defender has high guard, high attack path = [arms, head, ...]. When defender has low guard, high attack path = [head, chest, arms, ...] (anatomical).

**Data:**
```gdscript
# Path varies by defender's guard — reflects "what's in the blade path given defender posture"
const ATTACK_PATHS_BY_GUARD: Dictionary = {
    "high": {  # attack from high
        "high": ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"],  # arms up
        "low":  ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"],  # arms down, head exposed
        "left": ["left_arm", "head", "chest", "right_arm", "left_leg", "right_leg"],
        "right": ["right_arm", "head", "chest", "left_arm", "left_leg", "right_leg"]
    },
    "low": { ... },
    "left": { ... },
    "right": { ... }
}
```

**Logic:** Look up path from (attack_line, defender.guard_line). Intercept still uses alignment (or could be simplified—path already encodes guard).

**Pros:** Anatomically accurate per posture. High attack vs low guard = head first. High attack vs high guard = arms first.  
**Cons:** 4×4×6 = 96 path entries (or 4×4 paths of length 6). More data to tune.  
**Realism:** High. Guard directly determines "what's in the way."

---

### Approach B: Posture State (Limb Elevation)

**Idea:** Add `posture: String` or `limb_elevation: float` alongside guard_line. "Arms high" vs "arms mid" vs "arms low" refines what's in the path.

**Data:**
```gdscript
# posture: "high" | "mid" | "low" — where are the arms/weapon?
# Derived from guard_line + state: RECOVERING from high attack = arms might still be high
# Explicit: set when guard updates
```

**Logic:** Path or intercept modifier uses (attack_line, guard_line, posture). E.g. high attack + defender posture "low" = head exposed even if guard_line is "high" (stale).

**Pros:** Finer granularity. Separates "guard line" (which line we're defending) from "posture" (where limbs actually are).  
**Cons:** When does posture update? After every action? Risk of state explosion.  
**Realism:** Medium–High. Captures "arms down after a low cut" vs "arms up in high guard."

---

### Approach C: Reaction State at Contact

**Idea:** At the moment of hit resolution, record *what the defender was doing*: WAITING (ready), RECOVERING (committed), DODGING (partial_dodge_part set), PARRY_ATTEMPTING (passive_parry_attempted). Use this to modify hit location.

**Data:** Already have `partial_dodge_part`, `passive_parry_attempted`, `state`. Could add `reaction_at_contact: String` for explicit logging and path modifier.

**Logic:** When defender was dodging (partial), they're moving—hit location might shift (e.g. leg instead of chest). When parry attempted, blade met blade—if we still hit, it's a slip (glancing) or through (wrong line). Path could weight "defender moving" = more limb hits (twisting into the blade).

**Pros:** Uses existing state. No new fields if we pass reaction context into path resolver.  
**Cons:** Need to pass defender state into hit resolution.  
**Realism:** Medium. "Dodging" = body in motion = different contact distribution.

---

### Approach D: Intended Target + Path Refinement

**Idea:** When attacker chooses action, they optionally commit to `intended_part`. Path is refined: we bias toward that part, but guard/posture can block (path intercept). "I aimed at head, but his arm was in the way" = arm hit.

**Data:** Add `target_part` or `intended_part` to pending_attack (AI/player can specify). Already supported in some flows.

**Logic:** Path = base path for attack_line. Intended part adds weight. If intended part is in path segment, boost its weight. If guard blocks (early intercept), we might hit arm instead—path handles that. Intended target refines, doesn't override.

**Pros:** AI can "aim for the head" when enemy guards low. Feint can use intended ≠ actual.  
**Cons:** AI must choose intended target. More decision logic.  
**Realism:** High. Models "I'm attacking his head" vs "I'm attacking his leg."

---

### Approach E: Dual-Axis Guard (Vertical + Horizontal)

**Idea:** Guard has two components: `guard_vertical: "high"|"mid"|"low"` and `guard_horizontal: "left"|"center"|"right"`. Attack has same. Path or coverage uses both.

**Data:** 3×3 = 9 guard states. Path or part weights per (attack_vertical, attack_horizontal, guard_vertical, guard_horizontal).

**Logic:** More precise "where is the blade?" Thrust to center + guard center = blade meets blade. Thrust to center + guard left = blade gets through to chest.

**Pros:** Finer positioning. Diagonal attacks (high-left) map cleanly.  
**Cons:** 9 guard states; 81 (attack, guard) pairs for paths. Significant scope.  
**Realism:** Highest. Closer to actual blade orientation.

---

### Approach F: Stance / Weight Distribution

**Idea:** Add `stance: "neutral"|"forward"|"back"|"wide"`. Affects what's exposed. Forward = lead leg, lead arm more in path. Back = head/chest more exposed.

**Data:** One field per combatant. Updated when? After attack (forward lunge), after dodge (back step), idle (neutral).

**Logic:** Path or intercept modifier. Forward stance = legs/lead arm more likely first contact. Back stance = head/chest.

**Pros:** Models "lunging" vs "retreating."  
**Cons:** When to update? Requires new state and transition logic.  
**Realism:** Medium. Historical: stance matters for target exposure.

---

### Approach G: Recovery Cause → Posture

**Idea:** Store `recovery_cause: String` when entering RECOVERING ("attack_hit", "attack_miss", "attack_deflect", "medical"). Use it to infer posture. E.g. recovery from deflect = arms were up (parrying). Recovery from hit = arms might be down (staggered).

**Data:** Set in AttackResultApplier when transitioning to RECOVERING.

**Logic:** Posture = f(recovery_cause, recovery_progress). Early in recovery from deflect = arms still high. Late = settling to guard. Use for path lookup.

**Pros:** No explicit posture choice. Derived from what just happened.  
**Cons:** Indirect. Recovery cause might not fully determine posture.  
**Realism:** Medium. Approximates "where did the last action leave the body?"

---

### Approach H: Path Intercept Uses Both Attack and Guard Path Position

**Idea:** Attacker's blade is "at" some position along their attack path. Defender's guard is "at" some position along their guard's coverage. Contact = where they meet. Model as: attacker_path_index vs defender_guard_coverage_index. First overlap = hit location.

**Data:** Guard "coverage" = which path indices the guard protects. E.g. high guard protects indices 0–2 of high attack path (arms, head). Low guard protects nothing for high attack (or indices 5–6 = legs, irrelevant).

**Logic:** Attacker path = [0,1,2,3,4,5]. Defender guard covers [0,1] (arms). Blade travels; first unprotected index = hit. So we hit index 2 (head) or 3 (chest) if blade gets past 0,1.

**Pros:** Explicit "blade meets guard at X, then continues to Y."  
**Cons:** More abstract indices. Guard coverage per (attack_line, guard_line) = which indices are "blocked."  
**Realism:** High. Models blade–guard intersection then blade–body.

---

## 3. Comparison Table

| Approach | Complexity | Data Size | Realism | Integrates With |
|----------|------------|-----------|---------|-----------------|
| **A: Guard-dependent paths** | Low | 4×4 paths | High | Current path resolver |
| **B: Posture state** | Medium | 1 field | Medium–High | Path, intercept |
| **C: Reaction at contact** | Low | Use existing | Medium | Path weights |
| **D: Intended target** | Medium | 1 field in pa | High | Path weights, AI |
| **E: Dual-axis guard** | High | 9 states | Highest | Full system |
| **F: Stance** | Medium | 1 field | Medium | Path modifier |
| **G: Recovery cause** | Low | 1 field | Medium | Posture inference |
| **H: Path index overlap** | Medium | Coverage table | High | Path resolver |

---

## 4. Recommended Implementation Order

### Phase 1: Guard-Dependent Paths (Approach A)

**Effort:** Low. Replace `ATTACK_PATHS` with `ATTACK_PATHS_BY_GUARD`. Path lookup becomes `(attack_line, defender.guard_line)`.

**Result:** Anatomically correct paths. High attack vs low guard = head first. High attack vs high guard = arms first. Fixes the current inaccuracy.

### Phase 2: Reaction at Contact (Approach C)

**Effort:** Low. Pass defender state (partial_dodge_part, passive_parry_attempted, state) into AttackPathResolver. Add optional modifier: when dodging, bias path toward limbs (body twisting). When parry attempted + hit, path already reflects guard (we're past parry).

**Result:** Dodge = different contact distribution. Minor refinement.

### Phase 3: Intended Target (Approach D)

**Effort:** Medium. AI picks `target_part` when choosing attack. Path resolver boosts weight for intended part when in path segment. Fallback when not in segment.

**Result:** "I aimed at his head" vs "I aimed at his leg." Unguarded head = AI aims head. Guard blocks = arm hit. Tactical depth.

### Phase 4 (Optional): Recovery Cause (Approach G)

**Effort:** Low. Store `recovery_cause` when entering RECOVERING. Use to infer posture for path lookup (e.g. deflect → arms high; hit → arms down). Refines Approach A when guard_line is "stale" (just updated from attack, but body hasn't settled).

**Result:** Posture reflects "what just happened." Reduces guard_line staleness.

---

## 5. Data Structures for Phase 1 (Guard-Dependent Paths)

```gdscript
# CombatConstants.gd
# Path per (attack_line, defender_guard_line). Order = blade travel; first contact = early in list.
const ATTACK_PATHS_BY_GUARD: Dictionary = {
    "high": {
        "high": ["left_arm", "right_arm", "head", "chest", "left_leg", "right_leg"],  # arms up
        "low":  ["head", "chest", "left_arm", "right_arm", "left_leg", "right_leg"],  # arms down
        "left": ["left_arm", "head", "chest", "right_arm", "left_leg", "right_leg"],
        "right": ["right_arm", "head", "chest", "left_arm", "left_leg", "right_leg"]
    },
    "low": {
        "high": ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
        "low":  ["left_leg", "right_leg", "left_arm", "right_arm", "chest", "head"],
        "left": ["left_leg", "left_arm", "right_leg", "chest", "right_arm", "head"],
        "right": ["right_leg", "right_arm", "left_leg", "chest", "left_arm", "head"]
    },
    "left": {
        "high": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "low":  ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "left": ["left_arm", "left_leg", "chest", "head", "right_arm", "right_leg"],
        "right": ["left_arm", "chest", "left_leg", "head", "right_arm", "right_leg"]
    },
    "right": {
        "high": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
        "low":  ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"],
        "left": ["right_arm", "chest", "right_leg", "head", "left_arm", "left_leg"],
        "right": ["right_arm", "right_leg", "chest", "head", "left_arm", "left_leg"]
    }
}
```

**Intercept logic:** Unchanged. Alignment still determines intercept_max. Path is now guard-aware, so early intercept with high guard = arms (they're first in path). Early intercept with low guard = head (it's first in path). Same mechanic, better anatomy.

---

## 6. Summary

| Goal | Best Approach | Notes |
|------|---------------|-------|
| Anatomically correct paths | **A: Guard-dependent paths** | Path varies by defender guard. Head first when arms down. |
| Reaction affects hit location | **C: Reaction at contact** | Pass state; optional path modifier for dodge. |
| Attacker aims at specific part | **D: Intended target** | AI/player commits; path weights by intent. |
| Posture from last action | **G: Recovery cause** | Infer posture; refine path when guard "stale." |
| Maximum fidelity | **E: Dual-axis guard** | 9 states; highest realism; highest cost. |

**Recommended first step:** Implement **Approach A (guard-dependent paths)**. Low effort, fixes the high-path anatomy issue, and keeps the current intercept logic. Then add C and D as refinements.
