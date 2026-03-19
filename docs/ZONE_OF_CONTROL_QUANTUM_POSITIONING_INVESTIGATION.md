# Zone of Control and Quantum-Like Positioning: Investigation

Investigation of a zone system where formations exude **zones of control (ZoC)** that grow and shrink with combat. Units occupy zones (like electrons in orbitals) without exact coordinates—position is defined by zone membership and contribution to control. Flanking becomes possible when ZoC weakens and allows enemy "presence" in previously controlled space.

---

## Part 1: Core Concept

### Quantum Analogy

In quantum mechanics, electrons don't have fixed positions—they occupy **orbitals**: regions where the probability of finding the electron is high. The orbital has a shape, size, and energy; multiple electrons can occupy the same orbital (with spin); the orbital can be excited or ionized (changed).

**Translation to combat:**
- **Unit** = like an electron. No exact (x, y). Unit "occupies" a zone.
- **Zone** = like an orbital. A region of space with extent and "control strength."
- **Zone of control (ZoC)** = the formation's collective control over space. Sum of contributions from units in that zone; shrinks when units fall or incursion occurs.
- **Multiple units in a zone** = allowed. Zone has capacity; units contribute to zone control.
- **Zone boundaries** = fuzzy or discrete. Control strength falls off at edges; or zones have explicit adjacency.

### No Movement Tracking

Units don't "move" in the sense of x,y pathfinding. They:
1. **Occupy** a zone (assigned at engagement start or via action)
2. **Contribute** to that zone's control strength
3. **Shift** zones only when control changes (zone becomes accessible, or we reassign)

Position = zone membership + contribution. Distance = derived from zone adjacency and control (can we engage from this zone to that zone?).

---

## Part 2: Formation Zones and Zones of Control

### Zone Structure

Each formation has zones. Minimal set:
- **Front** — primary engagement; rank 0 dominates
- **Left flank** — leftmost files
- **Right flank** — rightmost files  
- **Rear** — behind the formation

Each zone has:
- **Control strength** (0–1 or 0–100): how much the formation dominates that space
- **Extent** (optional): how far the zone projects (for distance)
- **Capacity**: how many units can meaningfully occupy and contribute
- **Adjacency**: which zones border which (front ↔ left, front ↔ right, left ↔ rear, etc.)

### Control Strength Formula

```
zone_control[Z] = (
    sum(unit_contributions from units in Z)
    + support_from_adjacent_zones(Z)
    - incursion_penalty(Z)
    - casualty_penalty(Z)
) / zone_max
```

- **Unit contribution:** Each unit in zone Z adds to control. Dead units contribute 0.
- **Adjacent support:** Strong left zone helps left-flank; strong front helps both flanks.
- **Incursion penalty:** Enemy has pushed into this zone. Reduces control (they're in our space).
- **Casualty penalty:** Units in this zone died. Direct reduction.
- **Zone max:** Normalization so control stays 0–1.

### Control Thresholds

| Control | State | Effect |
|---------|-------|--------|
| **High (0.8–1.0)** | Dominant | We fully control. Enemies cannot "occupy" this zone. They engage from front of adjacent zone only. |
| **Medium (0.5–0.8)** | Contested | Partially controlled. Enemies can "bleed" in—some attackers can occupy zone edge (flanking possible). |
| **Low (0.2–0.5)** | Weak | We've lost control. Enemies can occupy this zone freely. Full flanking; we're surrounded on that side. |
| **Lost (0–0.2)** | Breached | Zone is theirs. Our units here are overrun or routing. |

---

## Part 3: Unit Positioning (Quantum-Like)

### Zone Occupancy

- Unit **U** is "in" zone **Z** of formation **F**.
- No coordinates. U has `zone_id` and `formation_id` (or side).
- Multiple units can be in the same zone (zone has capacity).
- Unit contributes to zone control while alive and in zone.

### Assignment Rules

**Formation units:**
- Rank 0 → Front zone (or front-left, front-center, front-right if subdivided)
- Rank 1 → Support zone (behind front) or same front zone (overlapping with rank 0)
- Rank 2 → Rear zone (reserve)
- File determines left/center/right sub-zone

**Attacking units (enemy):**
- Default: attacking from "front" of our formation = they're in their own front zone, engaging our front zone. No occupancy of our zones.
- **Flanking:** When our Left Flank zone control drops below threshold (e.g. 0.6), enemy units can be **assigned** to "our Left Flank zone." They've occupied it—we lost control. They now attack from inside our zone = flank bonus.
- Assignment: when control drops, `get_available_zones(enemy)` includes our weak zones. Enemy picks target zone + target unit. If they pick our left-flank zone, they're "in" it for that engagement.

### No Movement—Accessibility

Enemies don't "move" into our left flank. The left flank zone's control **dropped** (casualties, incursion), so it became **accessible**. Enemy chooses "engage from left flank" — they're now assigned to that zone for the purpose of the attack. Next engagement, they might still be there (persistent occupancy) or not (depends on design).

**"Movement" = zone accessibility change + assignment.** We don't track path. We track: can enemy occupy zone Z? (Control < threshold.) If yes, they can be assigned there.

---

## Part 4: Formation Size and Variable ZoC

### Formation Size

Formation has:
- **Width:** number of files (N)
- **Depth:** number of ranks (M)
- **Extent:** how much space the ZoC covers

Size is variable:
- **Units fall** → files can collapse (fewer files); ranks can thin (rank 1 becomes new front)
- **Incursion** → our front zone shrinks (enemy has pushed in); their front zone extends into our space
- **Rally / reserves** → we reinforce; ZoC can grow again

### ZoC Growth and Shrinkage

| Event | Effect on our ZoC | Effect on their ZoC |
|--------|-------------------|----------------------|
| **Our unit dies** | Shrink (control lost in that zone) | — |
| **Their unit dies** | — | Shrink |
| **We breach (push in)** | Our front extends; our control in their front zone rises | Their front zone shrinks; control drops |
| **They breach** | Our front zone shrinks; incursion penalty | Their front extends |
| **Reserve advances** | Rear strengthens; can extend flanks | — |
| **Flank collapses** | Left/right zone control drops sharply | Their flank zone extends into ours |

### Extent and Distance

Zones can have **extent** — how far they project:
- Front zone extent = formation width × reach factor (e.g. 1.5 × weapon reach)
- Flank zone extent = depth × factor
- Extent shrinks with control: `effective_extent = base_extent * sqrt(control)`

**Distance between units:** Derived from zone extent and adjacency.
- Same zone: close (can engage)
- Adjacent zones: mid (depends on extent; maybe close if extents overlap)
- Non-adjacent: long (can't engage)

So **formation distances** come from zone extent, not unit coordinates. Unit A in zone Z1, unit B in zone Z2. Distance = f(extent of Z1, extent of Z2, adjacency of Z1–Z2).

---

## Part 5: Flanking When ZoC Allows

### Mechanism

1. **Initial state:** Our left flank zone has high control (0.9). Enemies cannot occupy it. All attacks come from front (enemy front zone vs our front zone).
2. **Combat:** Our left-flank units take casualties. Control drops to 0.55.
3. **Threshold:** Control < FLANK_ACCESS_THRESHOLD (e.g. 0.6). Left flank is now **accessible**.
4. **Enemy action:** Enemy unit E chooses "attack from left flank." E is assigned to our left-flank zone for this engagement. E attacks our unit U (in left flank). E gets flank bonus (parry penalty on U).
5. **Persistent?** E stays "in" our left flank zone until: (a) we rally and control rises; (b) E is killed; (c) E disengages; (d) turn/round ends and we reassess.

### Surrounding

When **multiple** zones become accessible (left and right both weak):
- Enemies can occupy left and right simultaneously.
- Formation is "surrounded"—attacked from front, left, and right.
- Rear can also fall (reserve wiped) — then full encirclement.

Pack of wolves: distribute across zones. Initially all front (our control high). As we take losses, left weakens — 2 wolves shift to left zone. Right weakens — 2 wolves shift to right. We're surrounded. No movement; zone accessibility changed.

---

## Part 6: Implementation Options

### Option A: Pure Zone Control (No Extent)

- Zones have control strength only. No explicit "extent" or distance.
- Distance between units: same zone = close; adjacent = mid; else long.
- Engagement: can A engage B? If A's zone is adjacent to B's zone and control allows, yes.
- **Pros:** Simple. **Cons:** No variable formation "size" in the sense of reach.

### Option B: Zones With Extent

- Each zone has base_extent (meters or abstract units).
- Effective extent = base_extent * sqrt(control) or similar.
- Distance(A, B) = zone_distance(Z_A, Z_B, extent_A, extent_B). If extents overlap, close. If adjacent and within extent, mid.
- **Pros:** Formation "size" varies; range matters. **Cons:** More math.

### Option C: Hierarchical Zones

- Formation has top-level zones: Front, Left, Right, Rear.
- Each subdivides: Front has Front-Left, Front-Center, Front-Right (by file).
- Control propagates: parent zone control = f(children). Child control = f(units in child, sibling support).
- **Pros:** Matches file structure; granular. **Cons:** More zones, more state.

### Option D: Control as Probability (Quantum Closer)

- Unit in zone Z doesn't "hard" occupy. Unit has probability distribution over zones: P(Z1)=0.7, P(Z2)=0.3 (mostly in Z1, some presence in Z2).
- Zone control = sum over units of (contribution × P(unit in zone)).
- Flanking: when our zone control drops, enemy units can have P(our zone) > 0 — they're "partially" in our space.
- **Pros:** Very quantum-like; smooth transitions. **Cons:** Complex; may be overkill for gameplay.

---

## Part 7: Data Structures (Summary)

```gdscript
# Formation
zones: Array = ["front", "left_flank", "right_flank", "rear"]
zone_control: Dictionary = {}  # zone_id -> 0.0..1.0
zone_extent: Dictionary = {}  # zone_id -> base extent (optional)
zone_adjacency: Dictionary = {}  # zone_id -> [adjacent zone_ids]

# Combatant
zone_id: String = "front"       # which zone they're in
formation_id: int = -1          # which formation
contribution: float = 1.0       # unit's contribution to zone control

# On unit death: recalc zone_control for their zone
# On incursion: apply incursion_penalty to zone
# On breach: our control rises in their zone; theirs falls

# Engagement
# Attacker can engage from zone Z_target (defender's zone) if:
#   control(Z_target) < ACCESS_THRESHOLD
# Then attacker is "in" Z_target for that attack; gets flank/rear bonus
```

---

## Part 8: Advantages and Drawbacks

### Advantages

| Benefit | Description |
|---------|-------------|
| **No pathfinding** | Units don't move; zones and control change. Much simpler. |
| **Variable formation size** | ZoC grows/shrinks naturally with casualties and incursions. |
| **Flanking emerges** | Flanking happens when control drops, not from explicit movement. |
| **Quantum metaphor** | Units occupy zones; position is probabilistic/regional. Intuitive for design. |
| **Surround** | When multiple zones weaken, enemies can occupy several—surround. |
| **Formation distances** | Distance from zone extent and adjacency; no x,y. |

### Drawbacks

| Cost | Description |
|------|-------------|
| **Control recalc** | On every casualty, incursion, breach—recalc zone control. Can be costly at scale. |
| **Tuning** | Thresholds (when does zone become accessible?) need tuning. |
| **Edge cases** | Formation breaks apart (rout)—what are zones then? Collapse to individual? |
| **AI** | AI must understand zone accessibility and when to "shift" to flank. |
| **Player clarity** | Player needs to see zone control (colored zones? bars per zone?) to make decisions. |

---

## Part 9: Alternatives

### Alternative 1: Simpler—File Weakness Only

- Don't use zone control. Use file weakness: leftmost and rightmost files have fewer units or lower defense (built-in).
- Attackers targeting those files get flank bonus. No ZoC, no control strength. Just "flank files are weaker."
- **Pros:** Minimal. **Cons:** No dynamic growth/shrink; no incursion effect.

### Alternative 2: Fixed Zones, No ZoC

- Zones exist (front, flank, rear). Units are assigned to zones at start. No control strength.
- Flanking: attackers can always choose flank zone if formation has multiple files (flank files exist).
- **Pros:** Very simple. **Cons:** No emergence; no "zone fell so now they can flank."

### Alternative 3: ZoC as Morale/Cohesion

- Zone control = formation cohesion in that sector. Cohesion drops with casualties, failures, time.
- Low cohesion = flank accessible. Cohesion recovers slowly (rally, reserves).
- **Pros:** Ties to morale; familiar. **Cons:** Another resource (cohesion).

---

## Part 10: Recommendation

| Approach | When to use |
|----------|-------------|
| **Full Zone + ZoC (Part 2–6)** | Want formation size, incursion, and flanking to emerge from combat. |
| **Option B (zones with extent)** | Want formation distance to scale with ZoC (bigger formation = longer reach when strong). |
| **Alternative 1 (file weakness)** | Want quick flank without ZoC; ship sooner. |
| **Alternative 2 (fixed zones)** | Want flank but no dynamic control. |

**Phased implementation:**
1. **Phase 1:** Zones (front, flank, rear) + file assignment. No ZoC. Flank = attacking flank files. Alternative 1 or 2.
2. **Phase 2:** Add zone control. Control = f(units in zone, casualties). Flank accessible when control < threshold.
3. **Phase 3:** Add extent. Formation size varies; distance from zone extent.
4. **Phase 4:** Incursion/breach modify control. Full dynamic ZoC.

---

## References

- `docs/STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md` — formation, rows, files
- `docs/FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md` — surround, flank, approaches
