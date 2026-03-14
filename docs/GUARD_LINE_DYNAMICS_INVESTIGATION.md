# Guard Line Dynamics: Implementation Investigation

Investigation into different ways to implement guard line dynamics—how and when a combatant's `guard_line` changes during combat. Prioritizes **physics-based realism**. Complements the existing 4-line system in LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION and PHYSICS_REALISM_DECISIONS_INVESTIGATION.

---

## 1. Physical Basis (HEMA Sources)

### 1.1 What Real Fighters Do

| Source | Insight |
|--------|---------|
| **Liechtenauer** | Cuts end in guards. Oberhau ends in Plough (low); Unterhau ends in Ox (high). The *attack path determines* where the blade finishes. |
| **Meyer** | "Guards are transitional, not static." A cut flows through multiple guards; e.g., Oberhau: Tag → Longpoint → Alber. Weapon position is continuous through the motion. |
| **HEMA 101** | Guards are "positions of being in guard, i.e. ready to do something." Choosing a guard = choosing where the blade rests when not attacking. |
| **Physics** | Moving a sword from position A to B costs time and energy. Inertia and angular momentum mean transitions between distant positions are slower than between adjacent ones. |

### 1.2 Guard Continuity vs. Static Guard

- **Static guard:** Fighter chooses guard independent of prior action. No continuity. Unrealistic: ignores blade physics.
- **Guard continuity:** Blade position after action = starting position for next. Realistic: Meyer and Liechtenauer both describe this.
- **Dynamic choice:** Fighter can *adjust* guard when idle, but starting guard = where last action left the blade. Hybrid: continuity + agency.

---

## 2. Implementation Options (Prioritized by Physics Realism)

### Option A: Static Default (Current)

**Mechanic:** `guard_line` is always `"high"` (or a fixed default). Never changes.

| Aspect | Assessment |
|--------|------------|
| **Physics realism** | ❌ None. Ignores weapon position entirely. |
| **HEMA fidelity** | ❌ Contradicts Liechtenauer and Meyer. |
| **Complexity** | Minimal. |
| **Use case** | Prototype or non-simulation game. |

**Verdict:** Avoid for physics-prioritized design.

---

### Option B: After-Attack Continuity (Automatic)

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

### Option C: Transition Cost (Wind-Up from Guard Position)

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

### Option D: Explicit Guard Choice (Player/AI)

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

### Option E: Blend — Automatic + Optional Choice

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

### Option F: Parry Updates Guard (Defender Continuity)

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

### Option G: Dual-Line Guard (Vertical + Horizontal)

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

### Option H: Probabilistic / Decaying Guard

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

## 3. Summary Table (Physics-First)

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

## 4. Physics-Based Implementation Details

### 4.1 Transition Cost Formula (Option C)

**Derivation:** Angular distance determines work to move blade. Use alignment (cos of angle) as inverse proxy: alignment = 1 → no work; alignment = 0 → max work.

```gdscript
# alignment from get_line_alignment(attack_line, guard_line)
# windup_mult = 1 + (1 - alignment) * TRANSITION_COST_SCALE
const GUARD_TRANSITION_COST_SCALE := 0.4  # at alignment 0: +40% wind-up
func get_windup_mult_from_guard(alignment: float) -> float:
    return 1.0 + (1.0 - alignment) * GUARD_TRANSITION_COST_SCALE
```

At alignment 0.15 (floor): mult ≈ 1.34. At 1.0: mult = 1.0. Smooth, no table needed.

### 4.2 Parry Guard Update (Option F) — Refined

When defender parries with good alignment (e.g. alignment > 0.6): `guard_line = attack_line` (defender's blade met attacker's; blade ends in that line).

When alignment is poor (< 0.6): Keep defender's guard_line unchanged (blade didn't properly oppose; position uncertain).

### 4.3 Hook Points

| Event | Action (Option B) | Action (Option C) | Action (Option F) |
|-------|------------------|-------------------|------------------|
| Attack recovery complete | Set attacker `guard_line = attack_line` | Same + store for transition | — |
| Wind-up starts | — | `windup_duration *= get_windup_mult_from_guard(alignment)` | — |
| Parry deflect/partial | — | — | Set defender `guard_line = attack_line` if alignment > 0.6 |

---

## 5. Data Requirements

| Data | Source | Notes |
|------|--------|------|
| `last_move_id` | Combatant | Set when attack executes; clear or keep. |
| `attack_line` | WeaponConstants (per move) | Exists. |
| `guard_line` | Combatant | Exists. |
| Transition mult | Formula or CombatConstants | New constant. |

---

## 6. Recommendation (Prioritized)

1. **Implement Option B** (after-attack continuity). Low effort, high physics payoff. Fixes "guard never changes."
2. **Add Option C** (transition cost) once B is stable. Biggest physics gain; rewards flow.
3. **Optional: Option F** (parry updates guard) if defenders feel static. Quick add-on.
4. **Defer:** D, E, G, H until core feels solid. D and E require UI/choice logic; G and H add complexity with diminishing returns.

---

## References

- LINE_GUARD_AND_AFTERBLOW_IMPLEMENTATION.md (4-line system, physics-based alignment)
- PHYSICS_REALISM_DECISIONS_INVESTIGATION.md (§2 Guard Line Dynamics)
- HEMA_ZONES_FEINTS_FLURRIES_INVESTIGATION.md (Meyer: guards transitional)
- HEMA_VS_KCD_SOURCE_ANALYSIS.md
- CombatConstants.gd (get_line_alignment)
- WeaponConstants.gd (attack_line per move)
