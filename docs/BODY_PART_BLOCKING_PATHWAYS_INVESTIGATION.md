# Body Part Blocking Attack Pathways: Implementation Options

Investigation into different ways to model body parts blocking attack pathways more realistically **without 3D geometry**, going beyond the simple "sometimes head attacks hit an arm" redirect. Each approach approximates "what would the blade hit first?" using abstract data.

---

## Current Implementation

**Option 6 (Path + Guard Intercept) — IMPLEMENTED**

- **Attack paths:** Per attack_line (high/low/left/right), ordered path of parts blade passes through. E.g. high: [left_arm, right_arm, head, chest, left_leg, right_leg].
- **Intercept:** Guard alignment determines how far along the path the blade gets. High alignment = limbs in path = early contact (indices 0–2). Low alignment = blade gets through = full path.
- **Hit selection:** Sample from path[0..intercept_max] filtered to targetable parts. Fallback to weighted random if path segment is empty.
- **Location:** CombatConstants (ATTACK_PATHS, PATH_INTERCEPT_EARLY_MAX), AttackPathResolver.gd, AttackResolver.gd.

---

## 1. Attack Path as Part Sequence

**Idea:** Each move defines an ordered path—the sequence of body zones the blade passes through. Hit location = first part along the path that is "in the way" or a weighted sample from the path.

**Data:**
```gdscript
# Per move: ordered path (blade travels through these zones)
const ATTACK_PATHS: Dictionary = {
    "oberhau": ["head", "chest", "left_leg", "right_leg"],      # high→low
    "unterhau": ["left_leg", "right_leg", "chest", "head"],     # low→high
    "slash": ["left_arm", "chest", "right_arm"],                # horizontal
    "thrust": ["chest", "head"]                                 # center→high
}
```

**Logic:** Pick contact point along path. Earlier parts = more likely to be "first contact" when guard/defender posture puts limbs in the way. E.g. high guard shifts probability toward head/arms; low guard toward legs.

| Pros | Cons |
|------|------|
| Models blade trajectory. Oberhau naturally goes head→chest→legs. | Path is static; doesn't vary by defender posture. |
| One table per move. Reusable. | Path length varies; need consistent handling. |
| Can weight by guard (early vs late in path). | Still abstract; path is symbolic, not spatial. |

**Realism:** Medium–High. Captures "blade travels through zones" without 3D.

---

## 2. Part Coverage by Guard (Guard→Exposed/Protected)

**Idea:** Guard determines which parts are "in the path" (exposed) vs "protected" (behind other parts). For each (attack_line, guard_line), define which parts can be *first contact*.

**Data:**
```gdscript
# For attack_line × guard_line: which parts are "first contact" candidates, with relative weights.
# High attack + high guard: arms and head both exposed; arms may be first (raised).
# High attack + low guard: head exposed; arms less in path.
const PART_FIRST_CONTACT_WEIGHTS: Dictionary = {
    "high": {
        "high": {"head": 0.3, "left_arm": 0.35, "right_arm": 0.35},   # arms up
        "low":  {"head": 0.7, "left_arm": 0.15, "right_arm": 0.15},
        "left": {"head": 0.4, "left_arm": 0.5, "right_arm": 0.1},
        "right": {"head": 0.4, "right_arm": 0.5, "left_arm": 0.1}
    },
    "low": {
        "high": {"left_leg": 0.5, "right_leg": 0.5},
        "low":  {"left_leg": 0.35, "right_leg": 0.35, "left_arm": 0.15, "right_arm": 0.15},
        # ...
    },
    # ...
}
```

**Logic:** Instead of weighted random from all targetable parts, sample from the (attack_line, guard_line) distribution. Parts not in the distribution = not in path (e.g. back, or protected by another part).

| Pros | Cons |
|------|------|
| Guard directly shapes hit distribution. | 4×4×6 = many cells; large table. |
| "Arms block head" emerges when head has low weight in high guard. | Tuning intensive. |
| Can exclude impossible hits (e.g. thrust to leg from high). | Doesn't model path order—just probabilities. |

**Realism:** Medium–High. Reflects guard posture without geometry.

---

## 3. Layered Blocking (Explicit Interpose Pairs)

**Idea:** Define which parts can block which. Not just head→arm; also chest→arm (arm covers chest), leg→leg (lead leg blocks opposite leg), etc.

**Data:**
```gdscript
# blocking_part can intercept attacks intended for blocked_part when guard/geometry allows
const BLOCKING_PAIRS: Array = [
    {"blocker": "left_arm",  "blocked": "head",   "guard_exposure": {"high": 1.2, "left": 1.1, "low": 0.3, "right": 0.5}},
    {"blocker": "right_arm", "blocked": "head",   "guard_exposure": {"high": 1.2, "right": 1.1, "low": 0.3, "left": 0.5}},
    {"blocker": "left_arm",  "blocked": "chest",  "guard_exposure": {"left": 1.0, "high": 0.6, ...}},
    {"blocker": "left_leg",  "blocked": "right_leg", ...},  # lead leg in front
]
```

**Logic:** When part P is selected, for each blocking pair where blocked=P, roll interpose with `exposure(attack_line, guard_line)`. First success wins; redirect to blocker. If multiple blockers possible, weight by exposure.

| Pros | Cons |
|------|------|
| Extensible: add new pairs (chest→arm, leg→leg). | Many pairs; each needs tuning. |
| Generalizes current head→arm. | Order of checks matters if multiple block. |
| Guard-specific per pair. | Still binary "block or not" per pair. |

**Realism:** Medium. More coverage than head-only, but same mechanism.

---

## 4. Angular Sector Model (Geometry Proxy)

**Idea:** Body parts occupy abstract "angular sectors" (e.g. head 60°–120°, arms 0°–90° when raised). Attack has a direction angle. First part whose sector contains that angle (or overlaps) is hit. Overlap = probability blend.

**Data:**
```gdscript
# Part sector: [min_angle, max_angle] degrees. 0=top, 90=right, 180=bottom, 270=left.
# Guard shifts arm sectors: high guard = arms in 0-90; low = arms in 90-180
const PART_SECTORS_BY_GUARD: Dictionary = {
    "high": {
        "head": [60, 120],
        "left_arm": [0, 90],
        "right_arm": [90, 180],
        # ...
    },
    "low": { ... }
}
# Attack direction: oberhau = 0 (vertical down), slash = 90 or 270, etc.
```

**Logic:** Attack direction + part sectors → which part(s) overlap. Weight hit by overlap fraction or first intersection.

| Pros | Cons |
|------|------|
| Geometric feel without 3D. Angles = direction. | Angles are abstract; no clear mapping to moves. |
| Natural overlap: arm sector covers head sector when raised. | Sector definitions per guard are subjective. |
| Can derive blocking from overlap math. | Complex to tune. |

**Realism:** High (conceptually). Implementation is highly abstract.

---

## 5. First-Contact Distribution (Statistical)

**Idea:** Use empirical or historical data: for each (attack_type, guard_line), a probability distribution over "first part struck." E.g. HEMA/archaeological: in duels, head 40%, arms 30%, chest 10%, legs 20% for certain exchanges. Guard modifies: high guard → more arm, less head.

**Data:**
```gdscript
# Base distribution per attack line; guard multiplies
const FIRST_CONTACT_BASE: Dictionary = {
    "high": {"head": 0.45, "left_arm": 0.2, "right_arm": 0.2, "chest": 0.15},
    "low":  {"left_leg": 0.4, "right_leg": 0.4, "chest": 0.1, "left_arm": 0.05, "right_arm": 0.05},
    "left": {"left_arm": 0.4, "chest": 0.3, "left_leg": 0.15, "right_arm": 0.15},
    "right": { ... }
}
# Guard modifier: high guard + high attack → head ×0.6, left_arm ×1.5, right_arm ×1.5
const GUARD_MODIFIER: Dictionary = { ... }
```

**Logic:** Sample from modified distribution. No explicit "blocking"—just a better hit distribution that reflects geometry.

| Pros | Cons |
|------|------|
| Can calibrate to HEMA/archaeological data. | Not mechanistic; doesn't explain *why*. |
| Single sampling step. Simpler than interpose chains. | Guard modifier table is large. |
| Naturally captures "arms in way" when arm weights go up. | Feels statistical, not causal. |

**Realism:** Medium. Empirically grounded but not physics-derived.

---

## 6. Path Order + Guard Intercept Point

**Idea:** Combine (1) and (2). Move has a path. Guard determines where along the path the "first plausible contact" is. E.g. high attack path = [head, arms, chest, legs]. High guard = intercept early (arms/head). Low guard = blade reaches chest/legs before defender's blade is in position.

**Logic:**
1. Get path for move: `path = ATTACK_PATHS[move_id]`
2. Guard determines "intercept index": high guard vs high attack → index 0–1 (head/arms). Low guard → index 2–3 (chest/legs).
3. Sample part from path segment [0, intercept_index] or add noise. Earlier path = more likely when guard is good.

| Pros | Cons |
|------|------|
| Path + intercept = blade meets guard at some point. | Intercept index is a new concept to tune. |
| Good guard = contact earlier (arms). Bad guard = contact later (torso/legs). | Path and intercept both need definition. |

**Realism:** High. Models "where does the blade get stopped or make contact."

---

## 7. Attacker Intent vs. Actual Contact

**Idea:** Separate *intended* target (from AI or player choice) from *actual* contact. Intended = "I'm cutting at your head." Actual = first part in the way. Use path or coverage to compute actual from intended.

**Logic:**
1. Attacker chooses intended_part (e.g. head).
2. Given attack path and defender guard, compute P(actual_part | intended_part, attack_line, guard_line).
3. Sample actual_part. May differ from intended when arm/leg is in the way.

| Pros | Cons |
|------|------|
| Clear semantics: intent vs. outcome. | Requires intended target from AI. |
| Feints could use intended≠actual. | Two-stage resolution. |
| Tactical: "I aimed head, hit arm" = they guarded well. | More data flow. |

**Realism:** High. Matches real combat (intent vs. outcome).

---

## Summary Comparison

| Approach | Realism | Complexity | Data Size | Mechanistic? |
|----------|---------|------------|-----------|--------------|
| 1. Path as sequence | Med–High | Low | Small (path per move) | Yes |
| 2. Part coverage by guard | Med–High | Medium | Large (4×4×6) | Partial |
| 3. Layered blocking pairs | Medium | Medium | Medium (pairs) | Yes |
| 4. Angular sectors | High | High | Large | Yes |
| 5. First-contact distribution | Medium | Low | Medium | No (empirical) |
| 6. Path + intercept | High | Medium | Medium | Yes |
| 7. Intent vs. actual | High | Medium | Medium | Yes |

---

## Recommendation

- **Quick upgrade:** **Approach 3** (Layered blocking)—generalize head→arm to chest→arm, leg→leg, etc. Reuse current exposure mechanic.
- **Best balance:** **Approach 6** (Path + intercept)—path gives trajectory, intercept gives "where did the guard/body stop it." Physically intuitive.
- **Simplest meaningful step:** **Approach 1** (Path as sequence)—add path per move, sample from path weighted by guard. No new redirect logic, just better hit distribution.
- **Maximum abstraction fidelity:** **Approach 4** (Angular sectors)—true geometry proxy, but tuning-heavy.

---

## References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md (L5: Body part from geometry)
- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md (Arm interpose)
- BodyPartConstants.gd
- WeaponConstants.gd (attack_line per move)
