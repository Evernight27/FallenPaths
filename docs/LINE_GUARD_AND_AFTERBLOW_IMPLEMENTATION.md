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

#### Option P6: Arm Interpose — Exposure Model (BP6)

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
| BP6 | Optional: p_interpose = 0.10 × exposure (Option P6) | INTERPOSE_BASE = 0.10 |

**Constants derived:**
- **0.15 floor:** Retains ~15% parry effect at 90° (glancing/lucky contact).
- **0.08 variance base:** ±8% at perfect alignment; scales up when wrong.
- **0.35 leak max:** At zero alignment, add up to 35% to remaining ratio (severe but not instant death).
- **0.10 interpose base:** ~10% arm intercept when exposure=1; scales with guard.

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
| **Interpose** | Fixed per guard | Exposure × base |

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
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- COMBAT_PARRY_MISS_RESEARCH.md (HEMA 57–80% blade-blade)
- ARMA: "How a Cut Works", "Sword Impacts and Motions Part 2"
- Sword STEM: "Vector Transformations and the Wedge", "Geometry of a Flat Hit"
