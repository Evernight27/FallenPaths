# Guards Lines Afterblow

Consolidated documentation. Each section keeps its **original filename** in the `Source` line for provenance.

## Contents

1. [LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md](#line-guard-and-afterblow-implementation)
2. [GUARD_LINE_DYNAMICS_INVESTIGATION.md](#guard-line-dynamics-investigation)
3. [GUARD_ANGLE_PHYSICS_INVESTIGATION.md](#guard-angle-physics-investigation)
4. [GUARD_POSITION_WEAPON_BODY_INTERACTION_INVESTIGATION.md](#guard-position-weapon-body-interaction-investigation)
5. [ZONE_SPECIFIC_GUARD_INVESTIGATION.md](#zone-specific-guard-investigation)

---

<a id="line-guard-and-afterblow-implementation"></a>

## Source: `LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md`

# Line-Based Guard & Physically Realistic Afterblow: Implementation Investigation

Investigation into (1) different ways to implement line-based guard, (2) limitations of simulated/abstract systems vs. 3D geometry, and (3) physically realistic afterblow—where a creature hit by an attack can complete a previously planned strike if the blow wasn't intense enough to realistically hinder that action.

---

## Part 1: Line-Based Guard Implementations

### 1.1 Four Lines (Liechtenauer)

**Canonical:** High, low, left, right — weapon positions that cover attack paths. Parry efficacy depends on whether defender's guard line "matches" the attacker's attack line.

| Line | Guards | Typical coverage | Parts in that line |
|------|--------|------------------|-------------------|
| **High** | Ochs, Vom Tag | Attacks from above | head, upper chest |
| **Low** | Alber, Pflug (low) | Rising, low horizontal | legs, lower torso |
| **Left** | Plough left, Nebenhut | Attacks from opponent's right | left_arm, left_leg, left side of chest |
| **Right** | Plough right, etc. | Attacks from opponent's left | right_arm, right_leg, right side of chest |

**Note:** Lines overlap. A diagonal cut (Zornhau) travels high→low and left→right. Guard "high" may partially cover "left" depending on implementation.

---

### 1.2 Implementation Options

#### Option A: Part → Line Lookup (Defender)

**Mechanic:** Defender has `guard_line: String` = "high" | "low" | "left" | "right". Each body part maps to one or more lines. When attack targets part P, check if defender's guard_line covers P's line.

```gdscript
# Part to primary line(s). A part can be on 1–2 lines.
const PART_TO_LINES: Dictionary = {
    "head": ["high"],
    "chest": ["high", "low"],      # center; both lines can cover
    "left_arm": ["left", "high"],  # arm is left + upper
    "right_arm": ["right", "high"],
    "left_leg": ["left", "low"],
    "right_leg": ["right", "low"]
}

# Defender guard_line covers attack if target part's lines include guard_line.
func guard_covers_attack(guard_line: String, target_part: String) -> bool:
    return guard_line in PART_TO_LINES.get(target_part, [])
```

**Parry modifier:** If `guard_covers_attack` → parry_capacity × 1.5 (or similar). Else → normal.

**Pros:** Simple; one field per combatant; clear semantics.  
**Cons:** Parts map to 1–2 lines; diagonal cuts (e.g. Zornhau) hit "high left" — is that covered by "high" or "left"? Ambiguity.

---

#### Option B: Move → Line (Attacker) + Part → Line (Target)

**Mechanic:** Each move has `attack_line: String` or `attack_lines: Array`. Defender has `guard_line`. Match: `defender.guard_line in move.attack_lines` OR `guard_line == primary line of target_part`.

- Oberhau: attack_line = "high"
- Unterhau: "low"
- Zornhau: ["high", "left"] (diagonal)
- Thrust: ["high"] or "center" (point threatens center)

Guard covers if defender's line matches attack line. Part matters for damage, not for guard check—guard is about *blade path*, not *body target*.

**Pros:** Closer to Liechtenauer (Oberhau parries Oberhau = same line). Move geometry drives defense.  
**Cons:** Every move needs attack_line(s). Diagonal cuts need 2 lines; do both need to match for full parry? Partial?

---

#### Option C: Line Match Matrix

**Mechanic:** 4×4 or N×N matrix: `parry_efficacy[attacker_line][defender_line]`. E.g. high vs high = 1.2; high vs low = 0.6; high vs left = 0.8 (partial).

| Def \ Atk | High | Low | Left | Right |
|-----------|---:|---:|---:|---:|
| High | 1.2 | 0.5 | 0.9 | 0.9 |
| Low | 0.5 | 1.2 | 0.9 | 0.9 |
| Left | 0.8 | 0.8 | 1.2 | 0.6 |
| Right | 0.8 | 0.8 | 0.6 | 1.2 |

Same line = strong parry. Orthogonal (high vs low) = weak. Left vs right = moderate (horizontal opposition).

**Pros:** Fine-grained; models "Oberhau parries Oberhau" (same line best) and cross-line partial coverage.  
**Cons:** Tuning; many cells. Need move→line and guard_line.

---

#### Option D: Dual-Line Guard (High/Low + Left/Right)

**Mechanic:** Guard has two components: `guard_vertical: "high"|"low"|"mid"` and `guard_horizontal: "left"|"right"|"center"`. Attack has same. Match vertical AND/OR horizontal.

- Full match: both → parry × 1.5
- One match: × 1.0 (neutral)
- Neither: × 0.7 (wrong line)

**Pros:** Models 2D geometry (vertical + horizontal).  
**Cons:** 3×3 = 9 guard states; more complex.

---

#### Option E: Probabilistic Line Match

**Mechanic:** Instead of binary cover/don't cover, compute `line_match_score` 0–1 from angle between attack path and guard. In abstract system: approximate as `line_match = 1.0 if guard_line == attack_line else lerp(0.5, 0.8, similarity)` where similarity from a small lookup.

**Pros:** Smooth gradient; no hard edges.  
**Cons:** What is "similarity" without angles? Need convention (e.g. high-left is 0.8 similar to high).

---

### 1.3 Part → Line Mapping Conventions

| Part | Primary line | Secondary | Rationale |
|------|--------------|-----------|-----------|
| head | high | — | Above shoulders |
| chest | high or mid | low (abdomen) | Thorax high; abdomen lower |
| left_arm | left | high | Arm on left side; upper body |
| right_arm | right | high | Arm on right side |
| left_leg | left | low | Leg on left; below waist |
| right_leg | right | low | Leg on right |

**Recommended:** Option A or B. A is minimal (part→line, guard_line). B adds move→line for better "cut geometry" feel.

---

## Part 2: Simulated System vs. 3D Geometry — Limitations

### 2.1 What 3D Geometry Provides

| Capability | 3D | Abstract / Simulated |
|------------|----|------------------------|
| **Blade path** | Actual weapon sweep volume (capsule, mesh) over animation | Implicit: move_id implies path. No spatial path. |
| **Guard as spatial volume** | Weapon/arm position in space; plane or cone of coverage | Single `guard_line`; no position |
| **Line intersection** | Ray/plane, sweep vs. defender mesh — actual intersection | Lookup: attack_line vs guard_line |
| **Partial parry** | How much of blade contacts; angle of impact | `parry_remaining_ratio` from capacity vs momentum; no geometry |
| **Cut trajectory vs. guard** | Attack enters guard volume? At what angle? | Binary or tiered match (full/partial/none) |
| **Body part hit** | Raycast or collision on actual mesh | Random or preferred_parts; no spatial hit test |
| **Distance / measure** | Actual distance; bind when blades intersect | Abstract; no distance |
| **Disengage** | Blade leaves engagement volume | Not modeled |

### 2.2 Specific Limitations of Simulated System

#### L1: No True Line Intersection

**3D:** Attack path is a sweep (line/arc) through space. Guard is a plane or volume. Parry = sweep intersects guard volume before reaching body. Angle of impact determines partial vs full.

**Simulated:** We only have `attack_line` and `guard_line`. We assume "same line = blade would have met blade." We cannot resolve:
- Attack from high-left vs guard high — does blade cross? (Maybe; diagonal.)
- Attack from high vs guard high but blade slightly offline — 3D could give partial; we have binary or scalar.

**Mitigation:** Use Option C (matrix) for partial coverage. Accept that we approximate "would the blades have met."

---

#### L2: No Weapon Position Continuity

**3D:** Weapon position is continuous. After a cut, weapon is in Plough. Next move from Plough is faster (already there). Meyer: cuts flow through guards.

**Simulated:** We have discrete states. We could add `last_guard` / `weapon_position` and scale next move's wind-up by transition cost — but that's extra state. Default: no continuity; each attack is independent.

**Mitigation:** Optional `last_guard`; next move's windup_mult × transition_factor(from_guard, to_guard). Defer unless needed.

---

#### L3: Diagonal Cuts

**3D:** Zornhau travels diagonally. It crosses high and left (or right). A guard covering "high" might intercept early; "left" might intercept later. Depends on exact path.

**Simulated:** We must decide: is Zornhau "high" or "left" or both? Option B: `attack_lines: ["high", "left"]`. Guard matches if defender has high OR left? That over-counts (two lines cover one cut). Or: guard must match "primary" line only. Arbitrary.

**Mitigation:** Primary line per cut (high for Zornhau); guard matches primary. Or use matrix (high vs left = 0.8).

---

#### L4: No Measure

**3D:** Distance between combatants. Bind when blades contact. At close measure, different techniques (thrust from bind). At long measure, cuts may fall short.

**Simulated:** No distance. All attacks are "in range" when chosen. Binding and measure-dependent techniques don't exist.

**Mitigation:** Accept. Or add abstract `steps_to_opponent` for measure bands (defer).

---

#### L5: Body Part from Geometry

**3D:** Hit location from actual intersection of blade with character mesh. Chest vs arm vs head from geometry.

**Simulated:** We pick `target_part` from weighted random or preferred_parts. No spatial test. A cut "to the head" that would geometrically hit the arm first (arm in the way) — we don't model that.

**Mitigation:** Accept. Optional: arm/leg "interpose" check (if attacking head, X% chance arm blocks and takes hit instead). Adds complexity.

---

### 2.3 Summary: What We Can and Cannot Do

| Goal | 3D | Simulated (achievable) |
|------|----|------------------------|
| Guard covers one line, exposes others | ✓ Spatial | ✓ Lookup (guard_line vs attack_line) |
| Same-line parry strong, cross-line weak | ✓ Angle | ✓ Matrix or binary match |
| Cut geometry (Oberhau high, Unterhau low) | ✓ Animation | ✓ move→line |
| Weapon position continuity | ✓ Transform | △ Optional last_guard |
| Partial parry from angle | ✓ Impact geometry | ✓ parry_remaining_ratio (existing) |
| Actual blade intersection | ✓ Collision | ✗ Not possible |
| Measure / bind | ✓ Distance | ✗ Not without distance state |
| Hit location from geometry | ✓ Raycast | ✗ Weighted / preferred_parts only |

---

## Part 3: Physically Realistic Afterblow

### 3.1 Design Goal (Not HEMA Ruleset)

**HEMA afterblow:** Tournament rule — if you get hit, you can strike back within a time window; used to discourage suicidal commitment. Rule-based, not physics-based.

**Physical realism:** A creature hit by an attack can complete a **previously planned** attack (one already in wind-up or committed) **if and only if** the blow was not intense enough to realistically hinder the completion of that action.

Factors that would hinder completion:
1. **Damage to the part executing the action** — cut to attacking arm disrupts swing
2. **Damage to support structures** — leg hit affects balance; chest/head affects coordination
3. **Intensity / force of impact** — light graze vs heavy blow; momentum transfer
4. **Shock / neurological** — severe trauma causes flinch, freeze, or collapse
5. **Structural failure** — severed tendon, broken bone = cannot complete

### 3.2 Data Available in Your System

From AttackResolver and damage pipeline:
- `part` — which body part was hit
- `pre_armor`, `final_cut`, `final_blunt`, `final_bone` — damage amounts
- `outcome` — hit, glancing, deflected
- `intensity` — attacker commitment (0.2–1.0)
- `velocity_override` — impact speed
- `parry_remaining_ratio` — if partial parry, how much got through

From target (defender who was hit):
- `pending_attack` — if they have an attack in progress (wind_up targeting someone)
- Which arm they attack with (dominant_hand, get_attacking_arm)
- Part health after hit (body_cutting, body_blunt, bone_health)

### 3.3 Hindrance Model

**Question:** Did the blow realistically hinder the target's ability to complete their pending action?

**Hindrance factors:**

| Factor | Hinders? | Implementation |
|--------|-----------|----------------|
| **Part hit = attacking arm** | Strong | If part in [left_arm, right_arm] AND that arm is used for the pending attack → high hindrance |
| **Part hit = supporting leg** | Medium | Leg hit affects balance; penalty to completion |
| **Part hit = head** | Strong | Head trauma disrupts coordination, vision |
| **Part hit = chest** | Medium | Wind knocked out; structural (ribs) |
| **Severe tissue damage** | Strong | final_cut + final_blunt above threshold → cannot continue |
| **Bone involvement** | Strong | final_bone significant; broken bone = stop |
| **High intensity impact** | Strong | Heavy blow = more momentum transfer, more disruption |
| **Glancing hit** | Weak | Less damage, less hindrance |
| **Deflected** | None | No contact; no hindrance |

### 3.4 Implementation Options

#### Option A: Hindrance Score (0–1)

Compute `hindrance: float` from:
- Part relevance: 1.0 if attacking arm, 0.8 if head, 0.6 if chest, 0.5 if supporting leg, 0.3 if other leg, 0.2 if other arm
- Damage severity: `severity = (final_cut + final_blunt + final_bone) / damage_threshold` (e.g. threshold = 15 or per-part)
- Intensity factor: `intensity` (0.2–1.0) scales effective damage
- Outcome modifier: glancing × 0.6; deflected = 0

```gdscript
func get_afterblow_hindrance(hit_part: String, damage: float, intensity: float, outcome: String, 
                             pending_part_used: String, is_attacking_arm: bool) -> float:
    if outcome == "deflected":
        return 0.0
    var part_relevance: float = 1.0 if is_attacking_arm else PART_HINDRANCE.get(hit_part, 0.5)
    var severity: float = clampf(damage / DAMAGE_HINDER_THRESHOLD, 0.0, 1.5)  # Can exceed 1
    var outcome_mult: float = 0.6 if outcome == "glancing" else 1.0
    return clampf(part_relevance * severity * intensity * outcome_mult, 0.0, 1.0)
```

**Roll:** `randf() < hindrance` → afterblow **blocked** (target cannot complete). Else → afterblow **allowed**.

**Refinement:** Threshold-based. If `hindrance > 0.8` → always blocked. If `hindrance < 0.2` → always allowed. Between → probabilistic.

---

#### Option B: Hard Thresholds (Deterministic)

- Attacking arm hit with damage > X → always blocked
- Head hit with damage > Y → always blocked
- Leg hit: if severity > Z → blocked (fell)
- Else: allowed

Simpler but less nuanced.

---

#### Option C: Per-Part Damage Check

- If `body_cutting[attacking_arm]` or `body_blunt[attacking_arm]` dropped to 0 (or below functional threshold) from this hit → blocked (arm disabled)
- If `bone_health[part]` dropped to 0 → blocked (broken)
- If head/chest took significant damage → roll for shock (consciousness, pain)

Uses your existing part-state. Realistic: severed arm cannot complete swing.

---

#### Option D: Momentum / KE Threshold

Use `pre_armor` or kinetic energy at impact. Above threshold = "heavy enough to disrupt." Below = light tap, can follow through. Single scalar: `KE_at_impact > DISRUPT_KE_THRESHOLD` → blocked.

Combines with part: same KE to arm vs leg — arm more critical for sword strike.

### 3.5 Recommended Model: Hybrid

1. **Immediate disqualifiers:** If hit part is attacking arm AND (tissue destroyed OR bone broken from this hit) → blocked. If head hit and consciousness drops critically → blocked.
2. **Hindrance score** for marginal cases: part relevance × damage severity × intensity × outcome modifier.
3. **Roll:** `hindrance > 0.7` → blocked; `hindrance < 0.3` → allowed; else `randf() < hindrance` → blocked.
4. **Afterblow damage:** If allowed, target's attack resolves. Optionally: reduce damage by `(1 - hindrance)` to reflect "struck while wounded, weaker blow" — or full damage if we assume the blow didn't hinder form.

### 3.6 Flow Integration

**When:** Attacker A's blow hits target B. Before applying recovery, check:
1. Does B have `pending_attack`?
2. Does B's pending attack target A? (Mutual exchange.) Or someone else? (B was attacking C when A hit B.)
3. If B was attacking A: resolve hindrance. If not hindered, resolve B's attack as afterblow (order: A's damage applied first, then B's).
4. If B was attacking C: B's attack is independent; it could still resolve (B's turn) — but did the hit to B delay or cancel it? Same hindrance check; if hindered, B's pending_attack is **cancelled** (or delayed).

**Timing:** B's attack is "in wind-up" — so it hasn't executed yet. The afterblow represents: B was swinging; A's blow landed; did B's swing complete despite the hit? We're asking: at the moment of impact, was B's action far enough along (momentum, commitment) that a non-devastating blow wouldn't stop it? The hindrance model answers that.

**Edge case:** B has no pending_attack but has high gauge. Can B "decide" to strike back? That's counter-window / tempo, not afterblow. Afterblow = only for *previously planned* (already in motion) actions.

---

### 3.7 Data Requirements

For hindrance, need at resolve time:
- `hit_part`
- `final_cut`, `final_blunt`, `final_bone` to hit part
- `outcome` (glancing, hit, deflected)
- `intensity`
- B's `pending_attack` (target_id, move_id) — and which arm B uses
- B's arm (left/right) for the pending attack

BodyPartQuery / get_attacking_arm already exist. Damage is in take_result. Good.

---

## Part 4: Integration Approaches with Probability Approximations

Ways to integrate line-based guard (Part 1) with the simulated system (Part 2), using **probability approximations at appropriate breakpoints** to approximate physics without 3D models. Prioritizes realistic physics feel.

---

### 4.1 Breakpoint Map (Where to Inject Physics Approximations)

The combat resolution pipeline has discrete decision points. Each is a **breakpoint** where we can inject line-based or geometry-approximating logic:

| Breakpoint | Location | Current Behavior | Physics Being Approximated |
|------------|----------|------------------|----------------------------|
| **BP1: Attack line resolution** | Before parry calc | move_id → attack_type | Blade path / sweep direction |
| **BP2: Parry capacity modifier** | parry_c_d calculation | readiness × guard × strength | Guard intercepts attack path |
| **BP3: Parry technique variance** | c_d_final (line 498) | randf_range(1±0.15) | Blade angle, contact point variance |
| **BP4: Deflect vs partial threshold** | full_stop check | c_d >= p_a × 1.08 | Blade-blade impact geometry |
| **BP5: Partial parry remaining** | remaining_ratio | momentum - capacity | How much slips past guard |
| **BP6: Hit part selection** | part = ... | weighted random | First body part blade contacts |
| **BP7: Defense choice (parry vs dodge)** | choose_parry | E_dodge vs E_parry | Expected outcome given geometry |

---

### 4.2 Integration Approaches (Detailed)

#### Approach 1: Line Modifier on Parry Capacity (Deterministic Baseline)

**Breakpoint:** BP2 (parry_c_d).

**Mechanic:** After computing `parry_c_d`, multiply by `line_match_modifier(attack_line, guard_line)`:
- Same line: × 1.35
- Adjacent line (high↔low or left↔right): × 0.95
- Opposite (high vs low, or left vs right): × 0.65

**Pros:** Simple; single lookup; no extra rolls; strong effect.  
**Cons:** Deterministic; no variance from "slightly off" geometry.  
**Physics approximation:** Guard in correct position = blade meets blade; wrong position = blade slips past. Scalar models average outcome.

---

#### Approach 2: Line Modifier + Geometry Variance (Probability at BP3)

**Breakpoints:** BP2 + BP3.

**Mechanic:** 
- BP2: `parry_c_d *= line_modifier` (as Approach 1).
- BP3: Expand variance when lines **don't** match. Current: `c_d_final *= randf_range(0.85, 1.15)` (PARRY_TECHNIQUE_VARIANCE).
  - Same line: variance ±10% (tight — blade where it should be).
  - Wrong line: variance ±25% (wide — contact point unpredictable; sometimes lucky intercept, often miss).

```gdscript
var variance_eff: float = BASE_VARIANCE  # 0.15
if line_match < 0.5:  # Wrong or opposite line
    variance_eff *= 1.5  # Wider: 0.225 → ±22.5%
c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
```

**Pros:** Wrong guard = more outcome variance (realistic: sometimes you get lucky).  
**Cons:** Tuning two knobs (modifier + variance scale).  
**Physics approximation:** In 3D, wrong guard = blade path less predictable; sometimes edge catches, often doesn't. Variance models that uncertainty.

---

#### Approach 3: Line Modifier on Partial Parry Leak (BP5)

**Breakpoint:** BP5 (remaining_ratio).

**Mechanic:** After computing `remaining_ratio` from momentum - capacity:
- Same line: use as-is.
- Wrong line: `remaining_ratio = min(1.0, remaining_ratio + LEAK_FACTOR * (1 - line_match))`. E.g. LEAK_FACTOR = 0.25: wrong line adds up to 25% more "got through."

**Pros:** Wrong guard = partial parry lets more through (blade deflects less effectively).  
**Cons:** Can push ratio over 1; clamp. Interacts with damage pipeline.  
**Physics approximation:** Guard in wrong position = blade slides along instead of full redirect; more momentum reaches target.

---

#### Approach 4: Probabilistic Line Match (Soft Gradient)

**Breakpoint:** BP2.

**Mechanic:** Instead of discrete modifier, compute `line_match: float` 0–1 from a similarity table:
- Same line: 1.0
- Adjacent: 0.6 (high↔left, low↔left, etc.)
- Opposite: 0.2

`parry_c_d *= lerp(0.65, 1.35, line_match)`.

**Pros:** Smooth gradient; no hard edges.  
**Cons:** Need similarity for all 4×4 pairs.  
**Physics approximation:** Continuous "angle" between attack and guard; closer = better intercept.

---

#### Approach 5: Diagonal Cut Primary Line Roll (BP1)

**Breakpoint:** BP1 (before parry).

**Mechanic:** Moves with 2 lines (Zornhau: high + left) — which line does guard check use? Roll at resolution:

```gdscript
var attack_line: String
if move_attack_lines.size() == 1:
    attack_line = move_attack_lines[0]
else:
    # Weight by cut geometry: descending = high dominant
    var weights: Array = move_attack_line_weights  # e.g. [0.7, 0.3] for high, left
    var r: float = randf()
    attack_line = pick_weighted(move_attack_lines, weights)
```

**Pros:** Diagonal cuts not binary; sometimes guard "high" catches, sometimes "left" does.  
**Cons:** Extra roll; need weights per move.  
**Physics approximation:** Blade path crosses multiple lines; which line intersects first varies by exact trajectory.

---

#### Approach 6: Arm Interpose (BP6) — Hit Part from Geometry

**Breakpoint:** BP6 (hit part selection).

**Mechanic:** When attacking head (high line), defender's arms may be "in the way." Roll:
- `P(arm_interpose | target=head, guard=high) = 0.12` (arms raised in high guard)
- `P(arm_interpose | target=head, guard=low) = 0.05` (arms lower, less in the way)
- If interpose: redirect hit to `left_arm` or `right_arm` (based on attack side) instead of head.

```gdscript
const INTERPOSE_BY_GUARD: Dictionary = {
    "high": 0.12,   # Arms up
    "low": 0.05,    # Arms down
    "left": 0.15,   # Left arm forward
    "right": 0.15
}
if target_part == "head" and randf() < INTERPOSE_BY_GUARD.get(guard_line, 0.08):
    part = "left_arm" if attack_from_left else "right_arm"  # Simplified
```

**Pros:** Models "arm blocks head shot" without 3D.  
**Cons:** Need attack_from_left/right (or infer from move). More branching.  
**Physics approximation:** Extended limb intercepts blade path before it reaches torso/head.

---

#### Approach 7: Defense Choice Line Weighting (BP7)

**Breakpoint:** BP7 (parry vs dodge).

**Mechanic:** When choosing parry vs dodge, line match affects expected outcome. Low line_match → parry less attractive (even if capacity is OK, geometry may fail). Modify `E_parry` before comparison:

```gdscript
var E_parry_base: float = ...  # From parry_remaining_est, etc.
var line_adjusted_E: float = E_parry_base * lerp(0.7, 1.0, line_match)
# Defender with wrong guard may prefer dodge (get out of the way) over parry (blade might miss)
```

**Pros:** AI/defender "knows" wrong guard = parry riskier.  
**Cons:** Defenders don't choose in your system (passive parry). May apply only if you add active defense choice.  
**Physics approximation:** Rational defender avoids parry when guard is poorly positioned.

---

#### Approach 8: Combined Pipeline (Recommended)

**Integrate multiple approaches at their breakpoints:**

| Step | Action |
|------|--------|
| BP1 | Resolve attack_line from move (primary, or roll if diagonal). |
| BP2 | `parry_c_d *= line_modifier(attack_line, guard_line)` — Approach 1 or 4. |
| BP3 | `variance_eff *= (1.0 + 0.5 * (1 - line_match))` — Approach 2. |
| BP4 | (No change; uses c_d_final from BP2+3.) |
| BP5 | `remaining_ratio += 0.2 * (1 - line_match)`; clamp to 1.0 — Approach 3. |
| BP6 | Optional: interpose roll if target head — Approach 6. |
| BP7 | Skip (passive parry). |

**Order of operations:** Attack resolves → attack_line determined → parry calc uses line_modifier → variance → threshold check → remaining_ratio (+ leak) → damage to part.

---

### 4.3 Line Similarity / Modifier Tables

For approaches 1, 2, 4, 5 we need numeric mappings. Example:

**Line modifier (BP2):**
```
             atk_high  atk_low  atk_left  atk_right
def_high       1.35     0.60      0.90      0.90
def_low        0.60     1.35      0.90      0.90
def_left       0.90     0.90      1.35      0.60
def_right      0.90     0.90      0.60      1.35
```

**Line similarity (for Approach 4):**
```
             high   low   left  right
high         1.0   0.2    0.6    0.6
low          0.2   1.0    0.6    0.6
left         0.6   0.6    1.0    0.2
right        0.6   0.6    0.2    1.0
```

**Move → primary line (BP1):**
```
oberhau, overhead_chop, scheitelhau → high
unterhau → low
slash, mittelhau, zwerch → left or right (weapon side)
zornhau → high (primary) or [high, left] for diagonal
thrust → high (point threatens center/face)
```

---

### 4.4 Pros/Cons Summary by Approach

| Approach | Breakpoint | Physics Approximated | Pros | Cons |
|----------|------------|---------------------|------|------|
| 1: Line modifier on capacity | BP2 | Guard intercepts path | Simple, strong effect | No variance |
| 2: Variance scales with line | BP3 | Contact point uncertainty | Wrong guard = luck-dependent | Tuning |
| 3: Leak on remaining | BP5 | Blade slips past wrong guard | Direct damage effect | Clamp needed |
| 4: Soft gradient | BP2 | Continuous angle | Smooth | 4×4 table |
| 5: Diagonal line roll | BP1 | Path crosses lines | Diagonal cuts varied | Extra roll per move |
| 6: Arm interpose | BP6 | Limb blocks path | Hit location realism | More branching |
| 7: Defense choice | BP7 | Rational defender | Better AI (if active) | N/A for passive |
| 8: Combined | All | Full pipeline | Best fidelity | Most implementation |

---

### 4.5 Recommendation for Realistic Physics (No 3D)

**Minimum:** Approaches 1 + 2 (line modifier + variance). Two breakpoints, clear effect, approximates "guard position" and "geometry variance."

**Recommended:** Approaches 1 + 2 + 3 (add leak). Three breakpoints; wrong guard reduces capacity, widens variance, and increases partial parry leak.

**Optional:** + Approach 5 (diagonal roll) if you have diagonal moves; + Approach 6 (interpose) for hit location nuance.

**Skip:** Approach 7 unless you add active defense choice.

---

### 4.6 Data Requirements for Integration

| Data | Source | Notes |
|------|--------|------|
| attack_line | move_id → WeaponConstants or move def | Add per move |
| guard_line | combatant dict | Add per combatant; set when entering WAITING or on guard choice |
| line_modifier table | CombatConstants | 4×4 or 4 lines |
| PART_TO_LINES | BodyPartConstants or new | For part→line when attack_line derived from target_part |
| move_attack_lines | WeaponConstants | Array for diagonal moves |
| INTERPOSE_BY_GUARD | CombatConstants | Optional |

---

## Part 4B: Physics-Based Probability — Accurate Derivation

Implementation approaches that derive probability and modifiers from **physical principles** rather than arbitrary tuning. Prioritizes realism.

---

### 4B.1 Physical Principles (Sources)

| Principle | Source | Application |
|-----------|--------|-------------|
| **Force projection** | Sword STEM (Vector Transformations) | Parry applies force perpendicular to attack path for deflection, or direct opposition for stop. Force at angle θ: effective component ∝ cos(θ). |
| **Magnitude vs direction** | Sword STEM | "By slightly changing the direction you apply the force, you can drastically reduce the magnitude they can bring to bear." Misaligned guard = less effective opposition. |
| **Momentum / inertia** | ARMA (Sword Impacts Part 2) | Impact: momentum = inertia × velocity. Parry capacity absorbs momentum. Only the component of defender force that opposes attacker momentum matters. |
| **Contact geometry** | Sword STEM, ARMA | Contact point on blade affects leverage (inertia, pivot). When guard is wrong, contact point is uncertain — outcome more variable. |
| **HEMA calibration** | COMBAT_PARRY_MISS_RESEARCH | Longsword: 57–80% of contacts are blade-on-blade. Parry should remain common when defender can react; line match affects *efficacy*, not binary yes/no. |

---

### 4B.2 Line Match as Angle Proxy

In 3D, the **angle between attack path and guard plane** determines parry efficacy. Without geometry, we approximate:

| Line relationship | Approx. angle (guard to attack) | cos(θ) | Physical meaning |
|-------------------|----------------------------------|--------|------------------|
| Same (high vs high) | 0° | 1.0 | Guard directly opposes attack path; full force effective |
| Adjacent (high vs left) | 45° | 0.707 | Guard at 45°; ~71% of force component opposes attack |
| Opposite (high vs low) | 90° | 0 | Guard perpendicular to attack path; no opposition; blade passes |

**Alignment factor:** `alignment = cos(angle)`. Use line_match as proxy:
- Same line → alignment = 1.0
- Adjacent → alignment = 0.707 (≈ 0.7)
- Opposite → alignment = 0

---

### 4B.3 Physics-Based Implementation Options

#### Option P1: Parry Capacity ∝ cos(θ) (BP2)

**Derivation:** Defender capacity to redirect = `parry_c_d`. Only the component of capacity that opposes the attack is effective. When guard is at angle θ to attack path, effective capacity = `parry_c_d × cos(θ)`.

**Implementation:**
```gdscript
# line_match from table: same=1.0, adjacent=0.707, opposite=0
# alignment is our cos(θ) proxy
var alignment: float = get_line_match_alignment(attack_line, guard_line)  # 0 .. 1
parry_c_d *= alignment
```

**No arbitrary modifier.** Alignment = 0 → parry has no effect (guard doesn't oppose path). Alignment = 1 → full capacity. Directly from force projection.

**Edge case:** alignment = 0 would zero out parry. In reality, a 90° guard might still catch a glancing contact (blade hits side of guard). Use `alignment = max(0.15, line_match)` to floor — "lucky intercept" minimum.

**Pros:** Physically derived; no tuning.  
**Cons:** May make wrong guard too punishing; floor mitigates.

---

#### Option P2: Variance ∝ 1/alignment (BP3)

**Derivation:** When guard aligns well, contact point is predictable (blade meets blade in expected zone). When misaligned, contact point varies — tip? forte? miss? ARMA: impact point affects inertia, leverage. Outcome variance increases.

**Implementation:**
```gdscript
# Uncertainty in contact scales inversely with alignment
# alignment=1: tight variance (±10%)
# alignment=0.5: wider (±20%)
# alignment=0.2: very wide (±35%) — cap
var inv_alignment: float = 1.0 / maxf(0.2, alignment)
var variance_eff: float = PARRY_GEOMETRY_VARIANCE_BASE * clampf(inv_alignment, 1.0, 2.5)
c_d_final *= randf_range(1.0 - variance_eff, 1.0 + variance_eff)
```

**Physical basis:** Contact geometry uncertainty ∝ 1/alignment. When alignment is low, "did we catch it?" varies more.

**Pros:** Variance grounded in contact-point uncertainty.  
**Cons:** Need PARRY_GEOMETRY_VARIANCE_BASE (e.g. 0.08 → ±8% at alignment 1).

---

#### Option P3: Leak ∝ (1 − cos(θ)) (BP5)

**Derivation:** Sword STEM: misaligned force application = less magnitude reduction. The fraction of attacker momentum that is **not** redirected = leak. When guard opposes fully, redirect_fraction = f(capacity); when guard is wrong, we redirect less. Extra leak = (1 − alignment) × (potential redirect).

**Implementation:**
```gdscript
# remaining_ratio from momentum: (p_a - c_d) / p_a
# Geometric leak: when alignment < 1, more slips past
# redirect_effectiveness ∝ alignment; leak ∝ (1 - alignment)
var geometric_leak: float = (1.0 - alignment) * GEOMETRIC_LEAK_MAX  # e.g. 0.35
remaining_ratio = minf(1.0, remaining_ratio + geometric_leak)
```

**Physical basis:** 1 − cos(θ) is the fraction of "force not applied effectively." At θ=0°, leak=0. At θ=90°, leak=1 (full miss — but we floor alignment, so we never hit 90° exactly).

**Pros:** Direct from vector projection.  
**Cons:** GEOMETRIC_LEAK_MAX tuning (0.25–0.4 reasonable).

---

#### Option P4: Line Match from Angle Convention

**Derivation:** Define angles for each line pair. Use cos(angle) directly.

| def \ atk | high | low | left | right |
|-----------|---:|---:|---:|---:|
| high | 0° | 90° | 45° | 45° |
| low | 90° | 0° | 45° | 45° |
| left | 45° | 45° | 0° | 90° |
| right | 45° | 45° | 90° | 0° |

```gdscript
const LINE_ANGLE_DEG: Dictionary = {
    "high": {"high": 0, "low": 90, "left": 45, "right": 45},
    "low": {"high": 90, "low": 0, "left": 45, "right": 45},
    "left": {"high": 45, "low": 45, "left": 0, "right": 90},
    "right": {"high": 45, "low": 45, "left": 90, "right": 0}
}
func get_alignment(attack_line: String, guard_line: String) -> float:
    var deg: float = float(LINE_ANGLE_DEG.get(guard_line, {}).get(attack_line, 90))
    return maxf(0.15, cos(deg * PI / 180.0))  # floor 0.15 for lucky intercept
```

**Pros:** No arbitrary line_match table; angles and cos() are the definition.  
**Cons:** None; uses standard trig.

---

#### Option P5: Diagonal Cut — Trajectory Distribution (BP1)

**Derivation:** Diagonal cut (e.g. Zornhau) crosses high and left. Which line the guard "meets" first depends on exact trajectory. Small variations in cut path → different effective line. Model as probability distribution over lines.

**Implementation:** Weight by cut geometry. Descending diagonal: blade spends more time in "high" phase before crossing to horizontal. Empirically: 60–70% of path is "high," 30–40% "left."
```gdscript
# Zornhau: descending right→left
var line_weights: Dictionary = {"high": 0.65, "left": 0.35}
var r: float = randf()
var attack_line: String = "high" if r < 0.65 else "left"
```

**Physical basis:** Path length or time-in-phase. Descending cut: high component dominates early. Not exact physics but trajectory-weighted.

**Pros:** Diagonal cuts vary per instance.  
**Cons:** Weights per move type; empirical.

---

#### Option P6: Arm interpose — exposure model (BP6) — **not shipped as this roll**

**Repo today:** There is no `INTERPOSE_BASE` / `INTERPOSE_EXPOSURE` in `CombatConstants.gd`. Limb-before-head behavior is modeled with **`ATTACK_PATHS_BY_GUARD`** and related path logic, not a separate `p_interpose` roll. The pseudocode below is **design / calibration reference** only.

**Derivation:** Arm intercepts head strike when arm is in the blade path. Guard determines arm position: high guard = arms raised = more in path of high attack. Exposure = P(arm in path | target, guard).

**Implementation:**
```gdscript
# Exposure factor: how much arm is "in the way" of this attack line
# high attack + high guard: arms up, in path → exposure 1.2
# high attack + low guard: arms down, less in path → exposure 0.4
const INTERPOSE_EXPOSURE: Dictionary = {
    "high": {"high": 1.2, "low": 0.4, "left": 0.9, "right": 0.9},
    "low": {"high": 0.4, "low": 1.2, "left": 0.9, "right": 0.9},
    "left": {"high": 0.8, "low": 0.8, "left": 1.1, "right": 0.5},
    "right": {"high": 0.8, "low": 0.8, "left": 0.5, "right": 1.1}
}
var exposure: float = INTERPOSE_EXPOSURE.get(attack_line, {}).get(guard_line, 0.8)
var p_interpose: float = INTERPOSE_BASE * exposure  # e.g. 0.10 * 1.2 = 0.12 for head/high
if randf() < p_interpose:
    part = redirect_to_arm(attack_line)  # left or right arm
```

**Physical basis:** Limb position varies with guard; exposure = empirical correlate of "arm in path."  
**Pros:** Tied to guard geometry.  
**Cons:** Exposure table is approximate; INTERPOSE_BASE from observation (HEMA: arm hits common in duels).

---

### 4B.4 Calibration Targets (HEMA Research)

| Metric | Research | Target for System |
|--------|----------|-------------------|
| Blade-blade share of contacts | 57–80% (longsword) | When defender parries, deflect + partial should be majority of outcomes |
| Wrong guard = partial, not total fail | — | alignment floor 0.15 prevents "always miss"; variance allows lucky intercept |
| Variance when wrong | — | Outcome spread; no exact number |

---

### 4B.5 Recommended Physics-Based Pipeline

| Step | Formula / Logic | Constant |
|------|-----------------|----------|
| BP1 | attack_line from move; diagonal → weighted roll (Option P5) | line_weights per move |
| BP2 | alignment = max(0.15, cos(angle_deg)) from LINE_ANGLE_DEG (Option P4) | — |
| BP2 | parry_c_d *= alignment (Option P1) | alignment floor 0.15 |
| BP3 | variance_eff = 0.08 × clamp(1/alignment, 1, 2.5) (Option P2) | PARRY_GEOMETRY_VARIANCE_BASE = 0.08 |
| BP3 | c_d_final *= randf_range(1 − v, 1 + v) | — |
| BP5 | remaining_ratio += (1 − alignment) × 0.35; clamp 1 (Option P3) | GEOMETRIC_LEAK_MAX = 0.35 |
| BP6 | Optional design: p_interpose = 0.10 × exposure (Option P6) | **Not in code** — path-by-guard instead |

**Constants derived:**
- **0.15 floor:** Retains ~15% parry effect at 90° (glancing/lucky contact).
- **0.08 variance base:** ±8% at perfect alignment; scales up when wrong.
- **0.35 leak max:** At zero alignment, add up to 35% to remaining ratio (severe but not instant death).
- **0.10 interpose base (Option P6 design only):** Not a live constant; see BP6 row above.

---

### 4B.6 Pros/Cons: Arbitrary vs Physics-Based

| Aspect | Arbitrary (Section 4.2) | Physics-Based (4B) |
|--------|-------------------------|---------------------|
| **Line modifier** | ×1.35 same, ×0.65 opposite | cos(θ); floor 0.15 |
| **Variance** | 1.5× when wrong | ∝ 1/alignment |
| **Leak** | +0.25 × (1 − match) | +0.35 × (1 − cos(θ)) |
| **Constants** | Tune to feel | Derive from cos, 1/align |
| **Calibration** | Manual | HEMA 57–80% as target |
| **Diagonal** | Random or primary | Trajectory weights |
| **Interpose** | Fixed per guard (historical) | Path-by-guard in shipped code |

**Recommendation:** Use physics-based (4B) for BP1–BP5. Constants (floor, leak max, variance base) can still be tuned, but the **form** (cos, 1/align, etc.) is fixed by physics.

---

## Part 5: Summary

### Line-Based Guard

| Option | Complexity | Fidelity | Recommendation |
|--------|------------|----------|----------------|
| A: Part→line lookup | Low | Medium | Start here. |
| B: Move→line + part→line | Medium | High | Add for cut geometry. |
| C: Match matrix | Medium | High | Use if you want partial coverage. |
| D: Dual-line | High | High | Defer. |
| E: Probabilistic | Medium | Medium | Optional polish. |

### Simulated vs 3D

- **Can do:** Line match (lookup), parry modifier, move→line, part→line.
- **Cannot do:** Actual blade intersection, measure, spatial hit location.
- **Can approximate:** Partial parry (existing ratio), diagonal coverage (matrix).

### Integration with Probability Approximations (Part 4)

- **Breakpoints:** Seven decision points (BP1–BP7) where line-based or geometry-approximating logic can be injected.
- **Recommended:** Approaches 1 + 2 + 3 — line modifier on capacity, variance scales with line mismatch, leak on partial parry remaining. All without 3D.
- **Optional:** Diagonal line roll (BP1), arm interpose (BP6).

### Physics-Based Probability (Part 4B)

- **Alignment = cos(θ):** Line match derived from angle between attack path and guard; parry capacity ∝ alignment (Option P1).
- **Variance ∝ 1/alignment:** Contact point uncertainty when misaligned (Option P2).
- **Leak ∝ (1 − alignment):** Momentum not redirected when guard opposes poorly (Option P3).
- **Constants:** Floor 0.15 (lucky intercept), GEOMETRIC_LEAK_MAX 0.35, PARRY_GEOMETRY_VARIANCE_BASE 0.08. Calibrate to HEMA 57–80% blade-blade contact.

### Afterblow (Physical Realism)

- **Model:** Hindrance from part hit, damage severity, intensity, outcome.
- **Rule:** Allow completion if blow wasn't intense enough to realistically stop the action.
- **Implementation:** Hindrance score or thresholds; roll or deterministic for block/allow.
- **Scope:** Only for *previously planned* attacks (pending_attack). Not "get hit then decide to strike."

---

## References

- BodyPartConstants.gd, BodyPartQuery.gd
- AttackResolver.gd, CombatTiming.gd
- CombatManager.gd (pending_attack, recovery flow)
- `docs/HEMA_ROADMAP_AND_SOURCES.md` (HEMA zones / feints section)
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- COMBAT_PARRY_MISS_RESEARCH.md (HEMA 57–80% blade-blade)
- ARMA: "How a Cut Works", "Sword Impacts and Motions Part 2"
- Sword STEM: "Vector Transformations and the Wedge", "Geometry of a Flat Hit"

---

<a id="guard-line-dynamics-investigation"></a>

## Source: `GUARD_LINE_DYNAMICS_INVESTIGATION.md`

## Guard Line Dynamics: Implementation Investigation

Investigation into different ways to implement guard line dynamics—how and when a combatant's `guard_line` changes during combat. Prioritizes **physics-based realism**. Complements the existing 4-line system in LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION and PHYSICS_REALISM_DECISIONS_INVESTIGATION.

---

### 1. Physical Basis (HEMA Sources)

#### 1.1 What Real Fighters Do

| Source | Insight |
|--------|---------|
| **Liechtenauer** | Cuts end in guards. Oberhau ends in Plough (low); Unterhau ends in Ox (high). The *attack path determines* where the blade finishes. |
| **Meyer** | "Guards are transitional, not static." A cut flows through multiple guards; e.g., Oberhau: Tag → Longpoint → Alber. Weapon position is continuous through the motion. |
| **HEMA 101** | Guards are "positions of being in guard, i.e. ready to do something." Choosing a guard = choosing where the blade rests when not attacking. |
| **Physics** | Moving a sword from position A to B costs time and energy. Inertia and angular momentum mean transitions between distant positions are slower than between adjacent ones. |

#### 1.2 Guard Continuity vs. Static Guard

- **Static guard:** Fighter chooses guard independent of prior action. No continuity. Unrealistic: ignores blade physics.
- **Guard continuity:** Blade position after action = starting position for next. Realistic: Meyer and Liechtenauer both describe this.
- **Dynamic choice:** Fighter can *adjust* guard when idle, but starting guard = where last action left the blade. Hybrid: continuity + agency.

---

### 2. Implementation Options (Prioritized by Physics Realism)

#### Option A: Static Default (Current)

**Mechanic:** `guard_line` is always `"high"` (or a fixed default). Never changes.

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ❌ None. Ignores weapon position entirely. |
| **HEMA fidelity** | ❌ Contradicts Liechtenauer and Meyer. |
| **Complexity** | Minimal. |
| **Use case** | Prototype or non-simulation game. |

**Verdict:** Avoid for physics-prioritized design.

---

#### Option B: After-Attack Continuity (Automatic)

**Mechanic:** When a combatant finishes an attack, set `guard_line = attack_line` of that move. "Cut ends in a guard."

```gdscript
# After attacker's recovery completes:
func _on_attack_complete(attacker_id: int) -> void:
    var c: Dictionary = combatants[attacker_id]
    var last_move_id: String = c.get("last_move_id", "")
    if last_move_id.is_empty():
        return  # didn't attack; keep current guard
    var attack_line: String = WeaponConstants.get_attack_line_for_move(last_move_id)
    c["guard_line"] = attack_line if attack_line else c.get("guard_line", "high")
```

**Data:** Need `last_move_id` on combatant; `attack_line` per move (already exists).

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓ High. Directly models "blade ends where cut ends." |
| **HEMA fidelity** | ✓ Liechtenauer: Oberhau → Plough; Unterhau → Ox. Meyer: cuts flow through guards. |
| **Complexity** | Low. One assignment per attack completion. |
| **Edge cases** | Parry-only defender: no last_move → keep prior guard. Medical/idle: no change. |
| **Transition cost** | Not modeled. Next attack from *any* guard has same wind-up. |

**Pros:** Simple, faithful to sources, no UI.  
**Cons:** No transition cost; defender who only parries never changes guard (realistic: parry doesn't move blade to a new "guard" in the same way a cut does).

---

#### Option C: Transition Cost (Wind-Up from Guard Position)

**Mechanic:** Track `guard_line` (as B). When choosing attack, compute `windup_mult = transition_factor(from_guard, to_guard)`. Same guard = 1.0; opposite line = 1.2–1.5; adjacent = 1.05–1.1.

```gdscript
# transition_factor: how much longer wind-up from this guard to that attack line
const GUARD_TRANSITION_MULT: Dictionary = {
    "same": 1.0,      # e.g. high guard → high attack
    "adjacent": 1.08, # high → left/right
    "opposite": 1.35  # high → low
}
func get_windup_transition_mult(current_guard: String, attack_line: String) -> float:
    var align: float = CombatConstants.get_line_alignment(attack_line, current_guard)
    if align >= 0.95: return 1.0
    if align <= 0.2: return 1.35
    return lerpf(1.08, 1.35, 1.0 - (align - 0.2) / 0.75)
```

**Physics basis:** Angular distance. Moving blade 90° (high→low) takes longer than 0° (already there). cos(θ) or similar for smooth scaling.

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓✓ Highest. Models inertia and angular momentum. |
| **HEMA fidelity** | ✓✓ Meyer: "next from Plough is faster than from Alber" (when attack suits Plough). |
| **Complexity** | Medium. Need transition table or alignment-based formula; apply in wind-up calc. |
| **Constants** | Same/adjacent/opposite or smooth curve. Tune to feel. |

**Pros:** Most physically accurate. Rewards flow (cut→guard→cut on same line).  
**Cons:** More tuning; AI must consider transition when picking moves.

---

#### Option D: Explicit Guard Choice (Player/AI)

**Mechanic:** When entering WAITING (or at end of recovery), combatant *chooses* guard_line. No automatic inheritance from last attack.

- **Player:** UI to pick guard (dropdown, buttons, or schematic).
- **AI:** Mental stack scores guards by threat (telegraph, opponent's preferred lines, etc.).

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | △ Partial. Choice reflects *intent*, not blade position. A fighter can't instantly move blade from Alber to Ochs—that takes time. |
| **HEMA fidelity** | ✓ Historical: fighters chose guards. But typically *after* a cut ends, they're already in a guard; "choice" is whether to hold or shift. |
| **Complexity** | Medium–High. UI for player; decision logic for AI. |

**Pros:** Player agency; KCD-style directional block.  
**Cons:** Without transition cost, choice is teleportation—unphysical. Combines best with Option C.

---

#### Option E: Blend — Automatic + Optional Choice

**Mechanic:** Default = Option B (after attack, guard = attack_line). When idle (WAITING for N seconds, or at turn start), combatant *may* choose to shift guard. Shifting costs a fraction of gauge or a short delay.

- After attack: `guard_line = attack_line` (automatic).
- When idle: Can spend 0.1 gauge (or 0.2 s) to set `guard_line = chosen_guard`. If no choice, keep current.

**Physics basis:** Fighter can adjust when not committed. Adjustment takes time/effort (small cost).

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓✓ Good. Continuity from attacks; intentional adjustment when idle. |
| **HEMA fidelity** | ✓✓ Matches "choose where to hold blade" + "cut ends in guard." |
| **Complexity** | High. Two subsystems: auto-update + optional choice. |

**Pros:** Best of B and D.  
**Cons:** Most complex. Defer until core (B or C) is solid.

---

#### Option F: Parry Updates Guard (Defender Continuity)

**Mechanic:** When defender successfully parries (deflect or partial), set `defender.guard_line = attack_line` of the attack they parried.

**Rationale:** Parrying with the blade places the blade in a position. A parry to a high attack often leaves the blade in a high position (or the position that intercepted). Modeling "parry ends in a guard" as well as "cut ends in a guard."

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓ Reasonable. Parry does move the blade; it ends somewhere. |
| **HEMA fidelity** | △ Debatable. Parry *with* Oberhau ends in Plough (because you're cutting). Passive parry (blade blocks) may leave blade in various positions. |
| **Complexity** | Low. One assignment on parry_deflect/parry_partial. |
| **Edge case** | Wrong guard parry (low alignment): blade may deflect to odd angle. Using attack_line is an approximation. |

**Pros:** Defender's guard evolves even when not attacking.  
**Cons:** Parry geometry is messy; "parry ends in attack's line" is approximate. Could use `(attack_line + guard_line) / 2` or weighted blend for misaligned parries.

---

#### Option G: Dual-Line Guard (Vertical + Horizontal)

**Mechanic:** Guard has two components: `guard_vertical: "high"|"low"|"mid"` and `guard_horizontal: "left"|"right"|"center"`. Each can update independently from attacks.

- Oberhau: vertical=high, horizontal=center (or weapon side).
- Zornhau: vertical=high→low, horizontal=left (or right).

**Physics basis:** 2D angular space. Blade position is (vertical angle, horizontal angle). More degrees of freedom = more realism.

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓✓ High. Models 2D blade orientation. |
| **HEMA fidelity** | ✓ Meyer's quarters; Italian inside/outside. |
| **Complexity** | High. 3×3 = 9 guard states; alignment becomes 2D; transition cost is 2D distance. |

**Pros:** Finer granularity.  
**Cons:** Significant scope increase. Defer unless 4-line feels too coarse.

---

#### Option H: Probabilistic / Decaying Guard

**Mechanic:** Guard doesn't snap to attack_line. Instead, `guard_line` has a probability distribution or decays toward a default over time.

- After high attack: 80% high, 10% left, 10% right (blade may not settle perfectly).
- Over 2 s idle: drift 50% toward "high" (default neutral).

**Physics basis:** Real blade position has variance; fighters don't hold perfectly still.

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ✓ Models uncertainty. |
| **HEMA fidelity** | △ Adds randomness; HEMA sources don't emphasize this. |
| **Complexity** | High. Probabilistic resolution; more state. |

**Pros:** Softer, less binary.  
**Cons:** Complexity vs. benefit. Probably overkill for abstract system.

---

### 3. Summary Table (Physics-First)

| Option | Physics Realism | HEMA Fidelity | Complexity | Recommendation |
|--------|-----------------|---------------|------------|----------------|
| A: Static | ❌ None | ❌ | Lowest | Avoid |
| B: After-attack | ✓ High | ✓ | Low | **Start here** |
| C: Transition cost | ✓✓ Highest | ✓✓ | Medium | **Add after B** |
| D: Explicit choice | △ Partial | ✓ | Medium–High | Add if player wants agency |
| E: Blend (B+D) | ✓✓ | ✓✓ | High | Later enhancement |
| F: Parry updates | ✓ | △ | Low | Optional add-on to B |
| G: Dual-line | ✓✓ | ✓ | High | Defer |
| H: Probabilistic | ✓ | △ | High | Defer |

---

### 4. Physics-Based Implementation Details

#### 4.1 Transition Cost Formula (Option C)

**Derivation:** Angular distance determines work to move blade. Use alignment (cos of angle) as inverse proxy: alignment = 1 → no work; alignment = 0 → max work.

```gdscript
# alignment from get_line_alignment(attack_line, guard_line)
# windup_mult = 1 + (1 - alignment) * TRANSITION_COST_SCALE
const GUARD_TRANSITION_COST_SCALE := 0.4  # at alignment 0: +40% wind-up
func get_windup_mult_from_guard(alignment: float) -> float:
    return 1.0 + (1.0 - alignment) * GUARD_TRANSITION_COST_SCALE
```

At alignment 0.15 (floor): mult ≈ 1.34. At 1.0: mult = 1.0. Smooth, no table needed.

#### 4.2 Parry Guard Update (Option F) — Refined

When defender parries with good alignment (e.g. alignment > 0.6): `guard_line = attack_line` (defender's blade met attacker's; blade ends in that line).

When alignment is poor (< 0.6): Keep defender's guard_line unchanged (blade didn't properly oppose; position uncertain).

#### 4.3 Hook Points

| Event | Action (Option B) | Action (Option C) | Action (Option F) |
|-------|------------------|-------------------|------------------|
| Attack recovery complete | Set attacker `guard_line = attack_line` | Same + store for transition | — |
| Wind-up starts | — | `windup_duration *= get_windup_mult_from_guard(alignment)` | — |
| Parry deflect/partial | — | — | Set defender `guard_line = attack_line` if alignment > 0.6 |

---

### 5. Data Requirements

| Data | Source | Notes |
|------|--------|------|
| `last_move_id` | Combatant | Set when attack executes; clear or keep. |
| `attack_line` | WeaponConstants (per move) | Exists. |
| `guard_line` | Combatant | Exists. |
| Transition mult | Formula or CombatConstants | New constant. |

---

### 6. Recommendation (Prioritized)

1. **Implement Option B** (after-attack continuity). Low effort, high physics payoff. Fixes "guard never changes."
2. **Add Option C** (transition cost) once B is stable. Biggest physics gain; rewards flow.
3. **Optional: Option F** (parry updates guard) if defenders feel static. Quick add-on.
4. **Defer:** D, E, G, H until core feels solid. D and E require UI/choice logic; G and H add complexity with diminishing returns.

---

### References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md (4-line system, physics-based alignment)
- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md (§2 Guard Line Dynamics)
- `docs/HEMA_ROADMAP_AND_SOURCES.md` (HEMA zones / feints section) (Meyer: guards transitional)
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- CombatConstants.gd (get_line_alignment)
- WeaponConstants.gd (attack_line per move)

---

<a id="guard-angle-physics-investigation"></a>

## Source: `GUARD_ANGLE_PHYSICS_INVESTIGATION.md`

## Guard Positions, Attack Angles, and 45°/90° Physics Investigation

### Purpose

Verify that the 45° and 90° angles, guard positions, attack lines, and deflection outcomes are **physically consistent** and correctly wired together.

---

### 1. Current Geometry Model

#### 1.1 Four Lines (Attack & Guard)

| Line | Physical Meaning | Liechtenauer Equivalent |
|------|------------------|-------------------------|
| **high** | Blade from above / upward position | Vom Tag, Ochs, Plough (high) |
| **low** | Blade from below / downward position | Alber, Pflug (low), Ox |
| **left** | Blade from left / left-side position | Left Nebenhut, Zwerchau |
| **right** | Blade from right / right-side position | Right Nebenhut |

#### 1.2 Topology: Cross (Vertical + Horizontal Axes)

```
        high
          |
    left--+--right
          |
         low
```

- **Opposite pairs:** high↔low (vertical), left↔right (horizontal)
- **Adjacent pairs:** high↔left, high↔right, low↔left, low↔right

#### 1.3 LINE_ANGLE_DEG (Blade Orientation at Contact)

| Defender \ Attack | high | low | left | right |
|-------------------|------|-----|------|-------|
| high | **0** | 90 | 45 | 45 |
| low | 90 | **0** | 45 | 45 |
| left | 45 | 45 | **0** | 90 |
| right | 45 | 45 | 90 | **0** |

**Physical interpretation:** Angle between blade orientations at contact.
- **0°**: Same line — blades parallel/same plane. Best parry (bind).
- **45°**: Diagonal — defender's blade at 45° to attack. Partial alignment (lateral shed).
- **90°**: Perpendicular — defender's blade orthogonal to attack. Block from opposing axis.

**Alignment:** `cos(θ)` → 1.0 (same), 0.707 (adjacent), 0.0 (opposite)

#### 1.4 LINE_ADJACENTS

```gdscript
{"high": ["left", "right"], "low": ["left", "right"], "left": ["high", "low"], "right": ["high", "low"]}
```

**Consistency check:** high/low share adjacents [left, right]; left/right share adjacents [high, low]. ✓ Matches cross topology.

---

### 2. Deflection Logic

#### 2.1 Discrete deflection cases (reference; shipped code uses angles)

**Runtime:** `CombatConstants.get_deflected_line_from_angles` — the old `get_deflected_line_from_geometry` / `get_deflected_line_with_severity` helpers were removed. The table below is still the **intended** bind / lateral / opposite behavior.

| Condition | Result | Angular Displacement |
|-----------|--------|----------------------|
| attack_line == defender_guard_line | **Bind** (same line) | 0° |
| defender_guard_line in adjacents of attack_line | **Lateral** (other adjacent) | 45° |
| defender_guard_line opposite | **Strong block** (opposite line) | 90° |

#### 2.2 DEFLECTED_GUARD_FROM_ATTACK (Opposite Mapping)

```gdscript
{"high": "low", "low": "high", "left": "right", "right": "left"}
```

**Consistency:** Matches LINE_ADJACENTS topology — high/low and left/right are opposite pairs. ✓

#### 2.3 Lateral Deflection (Adjacent → Other Adjacent)

**Example:** High attack, defender parries from left.
- Defender's blade is on the left (45° to attack).
- Blade gets "shed" away from defender's blade → deflects to **right**.
- Right is the "other adjacent" of high (adjacents = [left, right]). ✓

**Example:** Left attack, defender parries from high.
- Defender's blade is high (45° to attack).
- Shed away from high → deflects to **low** (other adjacent of left). ✓

---

### 3. Physics Verification

#### 3.1 Same-Line (0°) → Bind

**HEMA:** Oberhau parries Oberhau → both end in Plough. Blades in same line.
**Physics:** Blades meet with parallel orientations; force is along the line. No angular deflection. ✓

#### 3.2 Adjacent (45°) → Lateral Deflection (45° displacement)

**HEMA:** "Cut behind the incoming blade" — lateral shed. Force applied across the path.
**Physics:** Defender's blade at 45° applies perpendicular component. Blade diverts to the side. Angular displacement ≈ 45° (to the "other adjacent"). ✓

#### 3.3 Opposite (90°) → Strong Block (90° displacement)

**HEMA:** Strong block from below on Oberhau drives blade down. Head-on impact.
**Physics:** Defender's blade perpendicular to attack. Force drives attacker's blade through to opposite side. ✓

#### 3.4 Why 45° and 90°?

- **cos(0°) = 1** — perfect alignment
- **cos(45°) = 0.707** — partial; reflects "diagonal" contact
- **cos(90°) = 0** — worst; reflects perpendicular blocking

The 45° for "adjacent" is an empirical choice: it gives alignment ≈ 0.7, which models "can parry but not as well as same-line." The exact angle varies in real contact; 45° is a reasonable discretization.

---

### 4. Data Flow Integrity

#### 4.1 Move Definitions → attack_line

| Move | attack_line | Notes |
|------|-------------|-------|
| thrust, oberhau, overhead_chop, pommel_strike | high | Downward/forward |
| unterhau | low | Upward |
| slash, diagonal_chop, quick_slash | left | Horizontal/diagonal |
| side_strike | right | From right |

**Diagonal moves:** oberhau, unterhau, diagonal_chop, slash use DIAGONAL_WEIGHTS to resolve effective_attack_line. The primary attack_line in the move def is the "base" for the roll. ✓

#### 4.2 PART_TO_LINE and LINE_TO_DEFAULT_PART

```gdscript
PART_TO_LINE: head→high, chest→high, left_arm→left, right_arm→right, left_leg→low, right_leg→low
LINE_TO_DEFAULT_PART: high→head, low→left_leg, left→left_arm, right→right_arm
```

**Consistency:** Body parts map to lines; lines map back to default parts. Symmetry: high↔head/chest, low↔legs, left↔left_arm, right↔right_arm. ✓

#### 4.3 ATTACK_PATHS and ATTACK_PATHS_BY_GUARD

Paths use attack_line and guard_line. Both are from {high, low, left, right}. ✓

#### 4.4 DODGE_END_GUARD_FROM_ATTACK

```gdscript
{"high": "low", "low": "high", "left": "right", "right": "left"}
```

Dodge moves defender to "opposite" — e.g. duck high attack → end in low. Same as DEFLECTED_GUARD_FROM_ATTACK. ✓

---

### 5. Potential Issues and Edge Cases

#### 5.1 Diagonal Moves and effective_attack_line

**Oberhau** has attack_line "high" but crosses high+left. DIAGONAL_WEIGHTS rolls for effective_attack_line ∈ {high, low, left, right}. The geometry then uses effective_attack_line. ✓ Correct.

#### 5.2 Angle-based deflection — adjacent choice (historical note)

The removed severity-based discrete helper always picked `adj[0]` for low-severity opposite-defender cases. **`get_deflected_line_from_angles`** uses continuous magnitude; optional future tuning: defender-aware lateral bias (same design question as before).

#### 5.3 slash attack_line = "left"

A horizontal slash can come from either side. Mapping to "left" is arbitrary; the geometry still works. If defender guards "right", we get 90° (opposite). ✓

#### 5.4 Thrust attack_line = "high"

Thrust is forward; we map to "high" (point-forward). Spear thrust same. The 4-line model treats "high" as the forward/vertical axis. ✓

---

### 6. Symmetry and Completeness

#### 6.1 LINE_ANGLE_DEG Symmetry

angle(attack, guard) should equal angle(guard, attack). Check:
- high vs low = 90, low vs high = 90 ✓
- high vs left = 45, left vs high = 45 ✓
- left vs right = 90, right vs left = 90 ✓

All pairs symmetric. ✓

#### 6.2 Adjacency Symmetry

If A is adjacent to B, then B is adjacent to A.
- high adjacent to left → left adjacent to high ✓
- high adjacent to right → right adjacent to high ✓

LINE_ADJACENTS is symmetric. ✓

#### 6.3 Deflection Coverage

For every (attack_line, defender_guard_line):
- Same line → bind (attack_line)
- Adjacent → one of the two adjacents (the "other" one)
- Opposite → DEFLECTED_GUARD_FROM_ATTACK[attack_line]

All cases covered. ✓

---

### 7. Summary: Physics and Wiring

| Component | Status | Notes |
|------------|--------|------|
| LINE_ANGLE_DEG | ✓ Correct | 0/45/90 match alignment cos(θ); symmetric |
| LINE_ADJACENTS | ✓ Correct | Cross topology; symmetric |
| DEFLECTED_GUARD_FROM_ATTACK | ✓ Correct | Opposite pairs consistent |
| get_deflected_line_from_angles | ✓ Shipped | Same→bind, adjacent→lateral, opposite→through (bilateral angles) |
| Move attack_line | ✓ Correct | All moves map to 4 lines |
| PART_TO_LINE / LINE_TO_DEFAULT_PART | ✓ Correct | Body ↔ line consistent |
| DIAGONAL_WEIGHTS | ✓ Correct | Diagonal moves resolve to 4 lines |
| ATTACK_PATHS_BY_GUARD | ✓ Correct | Uses same 4 lines |

#### Recommendations

1. **No changes required** for core geometry — the model is internally consistent and physically grounded.
2. **Optional refinement:** In **`get_deflected_line_from_angles`** / magnitude path, consider defender-aware lateral bias when the guard is adjacent (same asymmetry question as the old discrete helper).
3. **Documentation:** `LINE_ANGLE_DEG` / `LINE_ADJACENTS` in `CombatConstants.gd` — extend comments there if the cross topology needs more context for readers.

---

### References

- PARRY_DEFLECTION_PHYSICS_INVESTIGATION.md
- HEMA 101: Parries, Binds and Winds
- Sword STEM: Vector Transformations
- CombatConstants.gd (LINE_ANGLE_DEG, LINE_ADJACENTS, DEFLECTED_GUARD_FROM_ATTACK)

---

<a id="guard-position-weapon-body-interaction-investigation"></a>

## Source: `GUARD_POSITION_WEAPON_BODY_INTERACTION_INVESTIGATION.md`

## Guard Position & Weapon–Body Interaction: Investigation

Investigation into different ways to track guard position so that weapon positioning and swinging realistically interact with the target's body parts, depending on swing path and the opponent's reactions/positioning—**without 3D geometry**.

---

### 1. Current State

#### 1.1 What We Track

| Data | Location | When Updated | Used For |
|------|----------|--------------|----------|
| **guard_line** | combatant | After attack (recovery complete), after parry (deflect/partial) | Parry alignment, path intercept, transition cost |
| **guard** (scalar 0–1) | combatant | Rises when idle; drops when attacking | Parry capacity (readiness × guard) |
| **attack_line** | move definition | Static | Parry alignment, path selection, transition cost |
| **readiness** | PassiveParryContext | WAITING = guard; RECOVERING = lerp(early, late) | Parry capacity |
| **off_balance_until** | combatant | After miss/parry_deflect | Parry penalty, gauge fill penalty |
| **parry_bonus_until** | combatant | After parry_deflect | Parry capacity bonus |

#### 1.2 What We Don't Track

| Gap | Impact |
|-----|--------|
| **Posture / limb elevation** | Guard line is discrete (high/low/left/right). We don't know *how* high the arms are. High guard with arms at 45° vs 90° affects what's in the path. |
| **Reaction state at contact** | We know WAITING vs RECOVERING, but not "was defender dodging?" or "was defender mid-parry attempt?" at the moment of contact. Partial dodge stores `partial_dodge_part` but not posture shift. |
| **Guard-dependent paths** | Path is fixed per attack_line. When defender has low guard vs high attack, anatomically head is first; we use a path that assumes high guard (arms first). |
| **Intended target** | Attacker doesn't commit to a target before resolution. Swing path is generic; we don't have "aiming at head" vs "aiming at leg" to refine path. |
| **Weight distribution / stance** | Lead leg, leaning, etc. affect what's exposed. Not modeled. |
| **Blade position during swing** | We have attack_line (start/end) but not "blade at 30% of arc" for partial contact. |

---

### 2. Approaches to Improve Guard & Weapon–Body Interaction

#### Approach A: Guard-Dependent Paths (Path Per Attack×Guard)

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

#### Approach B: Posture State (Limb Elevation)

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

#### Approach C: Reaction State at Contact

**Idea:** At the moment of hit resolution, record *what the defender was doing*: WAITING (ready), RECOVERING (committed), DODGING (partial_dodge_part set), PARRY_ATTEMPTING (passive_parry_attempted). Use this to modify hit location.

**Data:** Already have `partial_dodge_part`, `passive_parry_attempted`, `state`. Could add `reaction_at_contact: String` for explicit logging and path modifier.

**Logic:** When defender was dodging (partial), they're moving—hit location might shift (e.g. leg instead of chest). When parry attempted, blade met blade—if we still hit, it's a slip (glancing) or through (wrong line). Path could weight "defender moving" = more limb hits (twisting into the blade).

**Pros:** Uses existing state. No new fields if we pass reaction context into path resolver.  
**Cons:** Need to pass defender state into hit resolution.  
**Realism:** Medium. "Dodging" = body in motion = different contact distribution.

---

#### Approach D: Intended Target + Path Refinement

**Idea:** When attacker chooses action, they optionally commit to `intended_part`. Path is refined: we bias toward that part, but guard/posture can block (path intercept). "I aimed at head, but his arm was in the way" = arm hit.

**Data:** Add `target_part` or `intended_part` to pending_attack (AI/player can specify). Already supported in some flows.

**Logic:** Path = base path for attack_line. Intended part adds weight. If intended part is in path segment, boost its weight. If guard blocks (early intercept), we might hit arm instead—path handles that. Intended target refines, doesn't override.

**Pros:** AI can "aim for the head" when enemy guards low. Feint can use intended ≠ actual.  
**Cons:** AI must choose intended target. More decision logic.  
**Realism:** High. Models "I'm attacking his head" vs "I'm attacking his leg."

---

#### Approach E: Dual-Axis Guard (Vertical + Horizontal)

**Idea:** Guard has two components: `guard_vertical: "high"|"mid"|"low"` and `guard_horizontal: "left"|"center"|"right"`. Attack has same. Path or coverage uses both.

**Data:** 3×3 = 9 guard states. Path or part weights per (attack_vertical, attack_horizontal, guard_vertical, guard_horizontal).

**Logic:** More precise "where is the blade?" Thrust to center + guard center = blade meets blade. Thrust to center + guard left = blade gets through to chest.

**Pros:** Finer positioning. Diagonal attacks (high-left) map cleanly.  
**Cons:** 9 guard states; 81 (attack, guard) pairs for paths. Significant scope.  
**Realism:** Highest. Closer to actual blade orientation.

---

#### Approach F: Stance / Weight Distribution

**Idea:** Add `stance: "neutral"|"forward"|"back"|"wide"`. Affects what's exposed. Forward = lead leg, lead arm more in path. Back = head/chest more exposed.

**Data:** One field per combatant. Updated when? After attack (forward lunge), after dodge (back step), idle (neutral).

**Logic:** Path or intercept modifier. Forward stance = legs/lead arm more likely first contact. Back stance = head/chest.

**Pros:** Models "lunging" vs "retreating."  
**Cons:** When to update? Requires new state and transition logic.  
**Realism:** Medium. Historical: stance matters for target exposure.

---

#### Approach G: Recovery Cause → Posture

**Idea:** Store `recovery_cause: String` when entering RECOVERING ("attack_hit", "attack_miss", "attack_deflect", "medical"). Use it to infer posture. E.g. recovery from deflect = arms were up (parrying). Recovery from hit = arms might be down (staggered).

**Data:** Set in AttackResultApplier when transitioning to RECOVERING.

**Logic:** Posture = f(recovery_cause, recovery_progress). Early in recovery from deflect = arms still high. Late = settling to guard. Use for path lookup.

**Pros:** No explicit posture choice. Derived from what just happened.  
**Cons:** Indirect. Recovery cause might not fully determine posture.  
**Realism:** Medium. Approximates "where did the last action leave the body?"

---

#### Approach H: Path Intercept Uses Both Attack and Guard Path Position

**Idea:** Attacker's blade is "at" some position along their attack path. Defender's guard is "at" some position along their guard's coverage. Contact = where they meet. Model as: attacker_path_index vs defender_guard_coverage_index. First overlap = hit location.

**Data:** Guard "coverage" = which path indices the guard protects. E.g. high guard protects indices 0–2 of high attack path (arms, head). Low guard protects nothing for high attack (or indices 5–6 = legs, irrelevant).

**Logic:** Attacker path = [0,1,2,3,4,5]. Defender guard covers [0,1] (arms). Blade travels; first unprotected index = hit. So we hit index 2 (head) or 3 (chest) if blade gets past 0,1.

**Pros:** Explicit "blade meets guard at X, then continues to Y."  
**Cons:** More abstract indices. Guard coverage per (attack_line, guard_line) = which indices are "blocked."  
**Realism:** High. Models blade–guard intersection then blade–body.

---

### 3. Comparison Table

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

### 4. Recommended Implementation Order

#### Phase 1: Guard-Dependent Paths (Approach A)

**Effort:** Low. Replace `ATTACK_PATHS` with `ATTACK_PATHS_BY_GUARD`. Path lookup becomes `(attack_line, defender.guard_line)`.

**Result:** Anatomically correct paths. High attack vs low guard = head first. High attack vs high guard = arms first. Fixes the current inaccuracy.

#### Phase 2: Reaction at Contact (Approach C)

**Effort:** Low. Pass defender state (partial_dodge_part, passive_parry_attempted, state) into AttackPathResolver. Add optional modifier: when dodging, bias path toward limbs (body twisting). When parry attempted + hit, path already reflects guard (we're past parry).

**Result:** Dodge = different contact distribution. Minor refinement.

#### Phase 3: Intended Target (Approach D)

**Effort:** Medium. AI picks `target_part` when choosing attack. Path resolver boosts weight for intended part when in path segment. Fallback when not in segment.

**Result:** "I aimed at his head" vs "I aimed at his leg." Unguarded head = AI aims head. Guard blocks = arm hit. Tactical depth.

#### Phase 4 (Optional): Recovery Cause (Approach G)

**Effort:** Low. Store `recovery_cause` when entering RECOVERING. Use to infer posture for path lookup (e.g. deflect → arms high; hit → arms down). Refines Approach A when guard_line is "stale" (just updated from attack, but body hasn't settled).

**Result:** Posture reflects "what just happened." Reduces guard_line staleness.

---

### 5. Data Structures for Phase 1 (Guard-Dependent Paths)

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

### 6. Summary

| Goal | Best Approach | Notes |
|------|---------------|-------|
| Anatomically correct paths | **A: Guard-dependent paths** | Path varies by defender guard. Head first when arms down. |
| Reaction affects hit location | **C: Reaction at contact** | Pass state; optional path modifier for dodge. |
| Attacker aims at specific part | **D: Intended target** | AI/player commits; path weights by intent. |
| Posture from last action | **G: Recovery cause** | Infer posture; refine path when guard "stale." |
| Maximum fidelity | **E: Dual-axis guard** | 9 states; highest realism; highest cost. |

**Recommended first step:** Implement **Approach A (guard-dependent paths)**. Low effort, fixes the high-path anatomy issue, and keeps the current intercept logic. Then add C and D as refinements.

---

<a id="zone-specific-guard-investigation"></a>

## Source: `ZONE_SPECIFIC_GUARD_INVESTIGATION.md`

## Zone-Specific Guard: Investigation of Different Approaches

Investigation into ways to implement zone-specific (directional) guard—KCD-style "block in a direction"—for Fallen Paths. Complements the existing 4-line `guard_line` system.

---

### 1. Current System vs Zone-Specific Guard

| Aspect | Current (guard_line) | Zone-specific (guard_zone) |
|--------|----------------------|----------------------------|
| **Granularity** | 4 lines: high, low, left, right (blade path) | 6 parts: head, chest, left_arm, right_arm, left_leg, right_leg |
| **Purpose** | Parry alignment, path intercept, transition cost | Which body zone defender is actively blocking |
| **Effect** | Alignment affects parry capacity, path order | Attack to guarded zone = block/parry easier; unguarded = normal |

**Key distinction:** `guard_line` = where the blade *is* (weapon position). `guard_zone` = which zone the defender *chooses to protect* (defensive intent).

---

### 2. Approach A: Guard Zone as Single Part

**Mechanic:** Each combatant has `guard_zone: String` = one of the 6 body parts.

**When attacking part P:**
- If `defender.guard_zone == P` → parry/block chance × 1.5 (or mandatory block)
- Else → normal resolution

**Pros:**
- Minimal state: one string per combatant
- Clear KCD mapping: "I'm guarding my head"
- No 3D needed: text or 2D icon

**Cons:**
- Binary: either guarding that zone or not
- Only one zone protected; attacker can always target unguarded zones

**Implementation:** Add `guard_zone` to combatant; in AttackResolver, when resolving parry, if `target_part == tgt.guard_zone` multiply parry_c_d by GUARD_ZONE_BONUS (e.g. 1.5).

---

### 3. Approach B: Guard Coverage (Multiple Zones)

**Mechanic:** `guard_zones: Array` = list of zones currently defended (e.g. `["head", "chest"]` for high guard).

**When attacking part P:**
- If P in defender.guard_zones → block/parry easier
- Else → normal

**Pros:**
- More realistic: high guard covers head + chest
- Can map guard_line → guard_zones: high → [head, left_arm, right_arm]

**Cons:**
- More state; need to define coverage per guard_line or per explicit choice
- Overlap with guard_line: guard_line already implies coverage via path

---

### 4. Approach C: Guard Line + Zone Modifier (Unify with Existing)

**Mechanic:** Keep `guard_line`. Add `guard_zone: String` as optional modifier. When attacker targets part P:
- If P == defender.guard_zone → guard applies fully (parry bonus)
- Else → guard × 0.5 (partial) or use guard_line only

**Pros:**
- Minimal change; one extra field
- Reuses guard_line for path/alignment; guard_zone refines "I'm especially protecting X"

**Cons:**
- Two overlapping concepts (line vs zone)
- Need part→line mapping to avoid contradiction (e.g. guard_zone=head but guard_line=low)

---

### 5. Approach D: Derive Guard Zone from Guard Line

**Mechanic:** No new state. Map `guard_line` → primary protected part(s):
- high → head (and arms via path)
- low → legs
- left → left_arm, left_leg
- right → right_arm, right_leg

**When attacking part P:** Check if P is in the "primary coverage" of defender's guard_line. If yes, parry bonus.

**Pros:**
- No new combatant state
- guard_line already updated on parry/attack; coverage derived automatically

**Cons:**
- Less flexible; can't "guard head while in low guard" (e.g. blade low but body positioned to block head)
- May duplicate what path intercept already does (guard_line affects path order)

---

### 6. Approach E: Guard Zone as Explicit Choice (Player/AI)

**Mechanic:** Defender *chooses* guard_zone each turn or when idle. Mental stack layer: "Enemy winding up on me" → if we know target_part (telegraph), set guard_zone = that part.

**Pros:**
- Tactical: "I see him winding up for head → I guard head"
- Telegraph integration: attacker commits target at wind-up; defender reacts

**Cons:**
- Requires telegraph (target_part known before execute) or probabilistic inference
- AI decision: when to switch guard_zone

---

### 7. Approach F: Guard Zone Modulates Parry Capacity (Not Binary)

**Mechanic:** Instead of binary block/easier, use a continuous modifier:
- `zone_match = 1.0 if target_part in coverage(guard_zone) else 0.5`
- `parry_c_d *= zone_match`

So attacking unguarded zone doesn't make parry impossible—just harder.

**Pros:**
- Softer; no "mandatory block" gamey feel
- Works with existing parry capacity math

**Cons:**
- Tuning: 0.5 vs 0.7 vs 0.3 for unguarded

---

### 8. Recommendation Matrix

| Goal | Recommended Approach |
|------|----------------------|
| Minimal KCD feel | A (single guard_zone) |
| Realistic coverage | B (guard_zones array) |
| Least code change | D (derive from guard_line) |
| Tactical depth | E (explicit choice + telegraph) |
| Soft modifier | F (continuous zone_match) |

**Suggested path:** Start with **D** (derive from guard_line)—no new state, uses existing guard_line dynamics. If playtests show "attacker always targets unguarded zone and it feels wrong," add **A** (explicit guard_zone) with Approach **F** (continuous modifier).

---

### 9. Data Structures (If Implementing A or B)

```gdscript
# Approach A
combatant["guard_zone"] = "head"  # or "chest", "left_arm", etc.

# Approach B
combatant["guard_zones"] = ["head", "chest"]  # high guard coverage

# Part-to-line mapping (for Approach D)
const GUARD_LINE_PRIMARY_COVERAGE: Dictionary = {
	"high": ["head", "left_arm", "right_arm"],
	"low": ["left_leg", "right_leg"],
	"left": ["left_arm", "left_leg"],
	"right": ["right_arm", "right_leg"]
}
```

---

### References

- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md
- COMBAT_SYSTEM_ISSUES.md (for open combat items)
- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md
- CombatConstants.gd (guard_line, ATTACK_PATHS_BY_GUARD)

---
