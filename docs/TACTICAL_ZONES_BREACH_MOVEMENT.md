# Tactical Zones Breach Movement

Consolidated documentation. Each section keeps its **original filename** in the `Source` line for provenance.

## Contents

1. [ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md](#zone-of-control-quantum-positioning-investigation)
2. [FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md](#formation-surround-multi-angle-investigation)
3. [ENGAGEMENT_ANGLE_VS_ZOC_FLANKING_INVESTIGATION.md](#engagement-angle-vs-zoc-flanking-investigation)
4. [FORMATION_FILE_DENSITY_SURVIVABILITY_INVESTIGATION.md](#formation-file-density-survivability-investigation)
5. [MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md](#medieval-formation-movement-switching-investigation)
6. [INCURSION_BREACH_MIGRATION_PLAN.md](#incursion-breach-migration-plan)

---

<a id="zone-of-control-quantum-positioning-investigation"></a>

## Source: `ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md`

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

- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — formation, rows, files
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — surround, flank, approaches

---

<a id="formation-surround-multi-angle-investigation"></a>

## Source: `FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md`

## Formation Combat + Surround / Multi-Angle Attack: Investigation

Investigation of how to combine row/file formation combat with surround tactics—packs of animals, split groups attacking from multiple angles—and the tradeoffs vs alternatives.

---

### Part 1: The Tension

**Formation combat (rows + files):**
- Assumes two formations facing each other in lines
- Combat is front-on; rank 0 vs rank 0, spears from rank 1
- Works for shield walls, phalanx-style engagement

**Surround / multi-angle:**
- Packs (wolves, bandits) attack from multiple sides
- Small groups split to flank instead of meeting head-on
- No formation—attackers are a mob, not a line

**Goal:** Support both. Formation vs formation when appropriate; pack vs formation (or pack vs pack) when appropriate. Allow small groups to flank a formation.

---

### Part 2: Approaches to Combine Formation + Surround

#### Approach A: Formation Has Sides (Front, Flank, Rear)

**Idea:** Each formation has a facing. Attackers are categorized by which "side" of the formation they're engaging.

| Side | Who engages | Defense modifier | Shield coverage |
|------|-------------|------------------|-----------------|
| **Front** | Normal row/file | Full | Shield blocks |
| **Left flank** | Attackers to formation's left | Parry × 0.7 (shield less effective) | Partial |
| **Right flank** | Attackers to formation's right | Parry × 0.7 | Partial |
| **Rear** | Attackers behind formation | Parry × 0.4 (surprise, no shield) | None |

**Positioning:** Each attacker (or attacker group) has an abstract "angle" or "side" relative to the formation center. No 2D grid—derive from: spawn position, movement choice, or AI behavior.

**Surround:** Pack spreads around formation. Wolves in front = front; wolves that "flank" = left/right; wolves that "circle behind" = rear. Each wolf gets a side based on its logical position.

**Pros:**
- Formation structure preserved
- Flank/rear bonuses feel right
- Works with abstract positioning

**Cons:**
- Need to assign "side" to each attacker. How? Spawn: 60% front, 20% left, 20% right? Or: formation has N "slots" per side; attackers fill them.
- Ambiguous when formations interpenetrate (breach)

---

#### Approach B: Formation + "Unformed" as Combat Modes

**Idea:** Units belong to a formation OR are "unformed" (loose). Formation units use row/file. Unformed units use distance bands only (no rank)—they can approach from any angle.

| Unit type | Positioning | Engagement |
|-----------|-------------|------------|
| **Formation** | rank, file, density | Row/file rules; front/flank/rear by attacker side |
| **Unformed (pack, skirmisher)** | distance to target(s) only | Can engage from any side; no rank |

**Pack vs formation:** Pack units are unformed. When they engage formation targets, they get a "side" based on which file they're attacking: leftmost file = they're on left flank; center = front; rightmost = right flank. So the formation's structure defines "angle" even without 2D positions.

**Small group flanking:** 3 units split—1 goes "left", 1 "right", 1 "front". Assign sides at combat start or when they commit to target. Units that chose "flank" get flank bonuses when they engage.

**Pros:**
- Clear split: formation vs unformed
- Packs and skirmishers naturally unformed
- Formation logic unchanged for formation vs formation

**Cons:**
- Need rules for "which side is this attacker on?"—possibly from formation geometry (which file they're attacking) or from explicit "approach vector" choice

---

#### Approach C: Explicit Approach Vector (Attack From X)

**Idea:** When attacker chooses target, they also choose (or AI assigns) approach: front, left_flank, right_flank, rear.

- **Front:** Normal engagement. Row/file applies.
- **Flank:** Attacker gets parry penalty on defender; defender's formation may not support that file well.
- **Rear:** Maximum penalty; reserve or rear rank must turn to face.

**Cost of flank/rear:** May require movement or "maneuver" action—can't always go rear immediately. Or: front is default; flank/rear require higher stamina, or success roll, or one extra "maneuver" event.

**Pack behavior:** Pack AI distributes approach vectors—some front, some flank. Surround = many attackers with diverse vectors.

**Pros:**
- Explicit; no need for 2D positions
- Clear bonuses/penalties per vector

**Cons:**
- How do you GET to flank/rear? Need "maneuver" or "flank" action. Formation might block (can't flank if formation is square and you're outnumbered).
- Adds another decision dimension

---

#### Approach D: Formation Perimeter "Slots" by Angle

**Idea:** Formation has a perimeter with slots at different angles. Front rank has slots 0°–180° (facing forward). Flank slots at 90° and 270°. Rear slots at 180°.

Attackers "occupy" perimeter slots. Pack surrounds = fills front, left, right, rear slots. Formation defends each slot. Slots at flank/rear have fewer defenders or defenders with penalty.

**Mechanic:** Formation has `perimeter_slots: Array` — e.g. 8 slots: 2 front, 2 left, 2 right, 2 rear. Each slot can be engaged by attackers. Defense strength per slot: front full, flank 0.8, rear 0.5. Or: front has rank 0; flank/rear have rank 1 (reserve) who are less prepared.

**Pros:**
- Natural "surround" — pack fills all slots
- Per-slot defense models formation vulnerability

**Cons:**
- More state; slot assignment logic
- Formation shape (line vs square vs column) changes slot count—more complexity

---

#### Approach E: Keep Formation, Add "Angle" as Simple Modifier

**Idea:** Minimal change. Formation combat unchanged. Add one field: `engagement_angle: String` = "front" | "flank" | "rear" for each attacker–defender pair.

- Default: front (when formation vs formation, or attacker in front)
- Pack: distribute angles. 50% front, 25% left flank, 25% right flank. Or based on pack size—more = can afford to send some to flank.
- Small group: player/AI chooses "attack front" or "flank left" or "flank right" when committing. Flank costs more (stamina or time) but grants bonus.

**Defense modifier:** front = 1.0, flank = 0.75, rear = 0.5. Multiply parry/dodge by this.

**Pros:**
- Small addition
- Works with existing formation and distance-band logic

**Cons:**
- "How do I get to flank?" — needs rule. Maybe: only unformed units can choose flank/rear; formation units always front. Or: flank requires target formation to have weak flanks (e.g. files ≥ 3, so leftmost/rightmost are flanks).

---

### Part 3: Bonuses and Drawbacks of Multi-Angle / Surround

#### Bonuses of Implementing

| Benefit | Description |
|---------|-------------|
| **Pack combat** | Wolves, bandits, creatures can surround. Feels natural for animals. |
| **Tactical depth** | Small group can flank instead of suicidal head-on charge. |
| **Formation vulnerability** | Formations have flanks and rear. Historically accurate. |
| **Variety** | Different enemy types (formation vs pack) play differently. |
| **Exploitable weaknesses** | Player can flank a shield wall; enemies can flank player formation. |

#### Drawbacks / Costs

| Cost | Description |
|------|-------------|
| **Position state** | Need to track "which side" or angle for each attacker. More state, more logic. |
| **AI complexity** | Pack AI must distribute across sides. Formation AI must respond to flank threats (wheel? refuse flank?). |
| **Ambiguity** | When formations breach, mix, or rout—who has which angle? Needs clear rules. |
| **Balance** | Flank/rear bonuses can be too strong. Must tune. |
| **Player communication** | Player needs to understand "flank" option and when it's available. |

---

### Part 4: Alternatives to Full Multi-Angle

#### Alternative 1: Flank as Formation-Only (No Surround)

- Only formation vs formation. Flank occurs when one formation's files extend past the other's (e.g. we have 6 files, they have 4—our left and right files hit their flanks).
- No pack surround. Packs use distance bands only; all attacks count as "front" (or apply a flat "outnumbered" penalty to formation).
- **Pros:** Simpler. No per-attacker angle. **Cons:** Packs can't surround; less tactical for pack fights.

---

#### Alternative 2: Surrounded = Defense Penalty (No Angles)

- Don't model angles. Model "surrounded" as a count: if defender has N attackers at close and N ≥ SURROUND_THRESHOLD (e.g. 3), apply flat parry penalty (e.g. × 0.6).
- Works for packs. No need to know "front vs flank." Just: more attackers = more overwhelmed.
- **Pros:** Already in plan (defense splitting). No new positioning. **Cons:** No flank/rear distinction; formation has no vulnerable sides.

---

#### Alternative 3: Formation Flanks as Weak Files

- Formation's leftmost and rightmost files are "flank files." They have fewer ranks (exposed) or lower defense (can't support each other well).
- Attackers that target flank files get a bonus—not because of angle, but because the target is in a weak file.
- Pack "surrounds" by having some attackers target left file, some right, some center. No explicit angles—target choice does it.
- **Pros:** Reuses file structure. No new angle state. **Cons:** Only works when formation has multiple files; 1-file "column" has no flanks.

---

#### Alternative 4: Defer Multi-Angle Entirely

- Ship formation combat without flank/rear. Add "surrounded" defense penalty only (Alternative 2).
- Revisit multi-angle in a later update if pack combat feels flat.
- **Pros:** Faster to ship. **Cons:** Packs less interesting; no flank tactics.

---

### Part 5: Recommendation Summary

| Option | Use when | Complexity |
|--------|----------|------------|
| **Approach E (angle as modifier)** | You want pack surround and flank tactics with minimal new state | Low |
| **Approach B (formation + unformed)** | You want clear separation of formation vs loose units | Medium |
| **Alternative 2 (surrounded only)** | You want to ship soon; packs just need "overwhelmed" feel | Minimal |
| **Alternative 3 (flank files)** | You want flank tactics without explicit angles | Low–Medium |
| **Approach D (perimeter slots)** | You want detailed surround simulation | High |

**Suggested path:**
1. **Phase 1:** Implement formation (rows/files) with no multi-angle. Use defense splitting (surrounded penalty) for packs. Alternative 2.
2. **Phase 2:** If pack combat needs more depth, add Approach E—engagement_angle (front/flank/rear) with modifiers. Unformed units can select flank when attacking formation; formation units always front.
3. **Phase 3 (optional):** Add Approach B (formation vs unformed) if you want distinct formation AI and pack AI.

---

### Part 6: Integration With Spear Lane Targeting (Deferred)

The spear lane design (over-shoulder vs open lanes, target restrictions) applies to **formation** combat—rank 0 density, rank 1 density, shield type. It does not directly apply to **surround** combat, because:

- Surround: attackers are at close from multiple angles. No "rank 1 spears behind rank 0." The formation is being attacked from the side or rear—rank 1 may not have clear lanes at all (they're facing the wrong way).
- When formation is flanked/rear: rank 1 spears might need to *turn* to face. That's a different scenario—reserves facing backward. Lane design would apply there only if you model "rear rank" as having its own lanes.

For implementation order: complete formation + lanes first. Multi-angle (flank/rear) can layer on afterward; rear attacks may ignore lane targeting (full body available) since there's no friendly rank 0 in the way.

---

### References

- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — formation, spear lanes, multi-actor
- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — distance and gating

---

<a id="engagement-angle-vs-zoc-flanking-investigation"></a>

## Source: `ENGAGEMENT_ANGLE_VS_ZOC_FLANKING_INVESTIGATION.md`

## Engagement Angle vs ZoC-Based Flanking: Investigation

Investigation for the FF4 formation system: which approach is most accurate for determining flank/rear bonuses—**engagement angle** (per attacker–defender pair) or **ZoC-based** (enemy occupies weak zones)?

---

### Part 1: Summary of Approaches

#### Option B: Engagement Angle

| Aspect | Description |
|--------|-------------|
| **What it is** | Each attacker–defender pair has `engagement_angle`: front / left_flank / right_flank / rear |
| **Derivation** | Computed from: formation geometry (which file attacked), explicit approach vector, or spawn position |
| **State** | Stored per pair; independent of zone control strength |
| **When flank/rear applies** | When attacker is assigned to flank/rear based on formation structure (e.g. targeting flank files, or coming from unformed approach vector) |

**Pros:**
- Works **without ZoC** — can add flanking before Phase 4
- Explicit, deterministic: "I'm attacking your left flank" = flank bonus
- Simpler to reason about for packs vs formation (unformed units choose approach)
- Per-pair granularity — same formation can have some front, some flank engagements

**Cons:**
- Flank/rear can feel static: "flank files" always exist; doesn't emerge from combat state
- Doesn't reflect *why* you're on the flank — did we earn it (ZoC dropped) or is it formation geometry?
- May over-grant flank when formation is strong (we haven't weakened their control)

#### Option C: ZoC-Based

| Aspect | Description |
|--------|-------------|
| **What it is** | Flank/rear = when our zone control drops below threshold; enemy can *occupy* that zone |
| **Derivation** | Zone control strength (0–1) per zone; threshold (e.g. 0.6) gates accessibility |
| **State** | `zone_control[front|left|right|rear]`; occupancy when control < threshold |
| **When flank/rear applies** | Only when we've lost control of that zone — casualties, incursion, breach |

**Pros:**
- **Emergent** — flanking is earned, not assumed. "We've lost the left flank" = enemy can occupy it
- Ties to Full ZoC (Option D) — control formula already exists
- Historically accurate: flanks weakened when formations thinned, broke, or were outflanked
- Single source of truth: zone control drives both "can they get there" and "what bonus do they get"

**Cons:**
- Requires ZoC (Phase 4+)
- Early combat: all zones strong → no flank access until something happens
- Pack vs formation: packs may never "occupy" zones if ZoC stays high; need fallback for unformed

---

### Part 2: Fit for Fallen Paths

#### System Constraints

| Constraint | Implication |
|------------|-------------|
| **Full ZoC (D) chosen** | Zone control already calculated. ZoC-based naturally extends it. |
| **Phase 4 = ZoC** | ZoC comes after formations (Phase 3). Flanking in Phase 6 (tactical features). |
| **Formation vs formation + pack vs formation** | Need both: formed units in zones; unformed units (packs) without zone structure |
| **Quantum positioning** | No x,y; position = zone + rank + file. ZoC zones are the spatial model |

#### When Each Works Best

| Scenario | Engagement angle | ZoC-based |
|----------|------------------|-----------|
| Formation vs formation, both strong | Flank = leftmost/rightmost files (static) | No flank until control drops |
| Formation vs formation, one side battered | Angle can stay front if geometry unchanged | Control dropped → flank accessible ✓ |
| Pack vs formation | Pack chooses approach (front/flank/rear) | Pack has no zones; need rule: can they access flank? |
| Incursion (enemy in our zone) | Angle = rear (they're behind us) | ZoC dropped → they occupy rear ✓ |

#### Pack vs Formation: The Gap

**Engagement angle:** Unformed units explicitly choose approach. "Flank left" = flank bonus. No need for zone control—they're not in a formation, so they get to pick.

**ZoC-based:** Unformed units don't occupy zones. How do they get flank/rear? Options:
1. **Hybrid:** ZoC gates formation-vs-formation. For pack vs formation, use engagement angle (pack chooses approach; formation files/flanks define geometry).
2. **ZoC proxy for packs:** Pack "occupies" flank zone when formation's flank control is low—same threshold, but pack doesn't add to control. They just exploit weakness.
3. **ZoC only:** Pack can never flank until they've reduced formation's control (by killing front rank, etc.). More restrictive.

---

### Part 3: Recommendation

#### For Fallen Paths: **Hybrid — ZoC Primary, Angle Fallback**

1. **Formation vs formation:** Use **ZoC-based** for flank/rear.
   - Enemy occupies our flank/rear zone only when control < threshold.
   - When occupied: `engagement_angle` = flank or rear (for modifier application).
   - Single source: ZoC determines access; angle is the resolved state for that engagement.

2. **Pack vs formation:** Use **engagement angle** as fallback.
   - Pack units are unformed; they don't contribute to or reduce ZoC.
   - Pack chooses approach at engagement: front (default), left_flank, right_flank, rear.
   - Flank/rear may cost more (stamina, maneuver) or be constrained by formation width (can't rear a deep formation from front).
   - Modifier same as ZoC case: flank 0.8, rear 0.7 (placeholders).

3. **Incursion:** When enemy unit occupies our zone (incursion success), they automatically have rear or flank angle vs defenders in that zone.

**Data flow:**
- Formation vs formation: `zone_control[zone] < threshold` → enemy can be assigned to zone → `engagement_angle` = zone_to_angle(zone)
- Pack vs formation: Pack unit chooses `approach` (front/flank/rear) → `engagement_angle` = approach
- Both: Apply modifier from `engagement_angle` (front 1.0, flank 0.8, rear 0.7)

#### Why Not Pure ZoC or Pure Angle?

| Pure approach | Problem |
|---------------|---------|
| **Pure ZoC** | Pack vs formation has no way to flank (pack has no zones). Need extra rule. |
| **Pure angle** | Formation vs formation flank feels unearned—flank files are always vulnerable even when formation is strong. |

Hybrid uses ZoC when it applies (formation structure, control state) and angle when ZoC doesn't (unformed attackers).

---

### Part 4: Implementation Notes

1. **`engagement_angle`** — Keep as combatant or pair field. Filled by:
   - ZoC: when enemy occupies our weak zone
   - Pack: when unformed attacker chooses approach

2. **Modifiers** — Use same table for both paths: front 1.0, flank 0.8, rear 0.7 (tune later).

3. **Phase 6** — Implement flanking when ZoC exists. Pack fallback can ship with or after.

4. **Investigate further** — Per user: "investigate more accurate numbers" for flank/rear modifiers. Historical sources, playtesting.

---

### References

- `docs/TACTICAL_FORMATIONS_FF4.md` — Section 3.8 Flanking
- `docs/TACTICAL_FORMATIONS_FF4.md` — ZoC, breakthrough
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — Zone structure
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — Approach E, angle as modifier

---

<a id="formation-file-density-survivability-investigation"></a>

## Source: `FORMATION_FILE_DENSITY_SURVIVABILITY_INVESTIGATION.md`

## Formation File/Density + Survivability-Gated Push: Investigation

Investigation of how the formation system can support:
1. **Explicit control** over front-line count vs reserve depth
2. **Density choice** (tight vs loose) and its tradeoffs: engagement capacity, fall-back/rotation ease, and fight-to-death tendency
3. **Survivability-gated push and flank** so most units stay in flag protection; only durable units attempt incursion

---

### Part 1: Front Line vs Back Line — File/Rank Assignment

#### Current State

- **FormationPreset:** `{ files, ranks, density }`. Default: 2 files, ceil(count/2) ranks.
- **Assignment:** Spawn order. Plan: heavy armor front, spears second row, weaker in reserve.
- **Constraint:** Formation shape is derived from count and density; no explicit "I want 4 in front, 6 in reserve."

#### Design Goal: Explicit Front-Line Choice

Player/encounter should be able to choose:
- **Front-line count:** How many units in rank 0 (primary melee)
- **Reserve depth:** How many ranks behind (rank 1+ for support, ranged, rotation)

#### Option A: Files × Ranks with Explicit Fill

Preset: `{ files: 4, ranks: 3, density: "normal" }` → 12 slots. Fill front first; spill to rank 1, then rank 2.
- **Front = files × 1** = 4 in rank 0.
- Control: set `files` and `ranks` so `files` = desired front count. For 6 in front: `files: 6, ranks: ceil(total/6)`.

**Pros:** Reuses existing structure. `files` directly = front-line count when single rank in front.
**Cons:** Deeper formations (2+ in rank 0) require different mapping.

#### Option B: Explicit Front-Count in Preset

Preset: `{ front_count: 4, reserve_ranks: 2, density: "normal" }`.
- **front_count:** Slots in rank 0. Can exceed `files` if you want overlapping (e.g. shield wall with 6 in front, 4 files → 1.5 per file).
- **reserve_ranks:** Ranks 1..N for support. Units per reserve rank = `front_count` or `front_count - 1` (narrower reserve).

**Derivation:** `files = front_count` (simple); `ranks = 1 + reserve_ranks`. Or: `files` from width preference, `front_count` slots in rank 0 (some files have 2? or extra rank 0 slots).

#### Option C: Slot Template (Most Flexible)

Preset defines **slot layout** explicitly:
```
slots: [
  { rank: 0, file: 0 }, { rank: 0, file: 1 }, { rank: 0, file: 2 }, { rank: 0, file: 3 },  # 4 front
  { rank: 1, file: 0 }, { rank: 1, file: 1 }, { rank: 1, file: 2 }, { rank: 1, file: 3 },  # 4 support
  { rank: 2, file: 1 }, { rank: 2, file: 2 }   # 2 reserve (narrower)
]
```
- Fill in order. First 4 → rank 0. Next 4 → rank 1. Last 2 → rank 2.
- Allows wedge, convex, refuse-flank shapes.

**Recommendation:** Start with **Option A** — use `files` as front-line count and `ranks` for depth. Add **Option B** fields (`front_count`, `reserve_ranks`) as optional overrides if you want "4 in front, 2 ranks behind" without caring about file width. Option C later for exotic shapes.

**Integrated:** Option A implemented. FormationPreset: `files` = front count; `for_front_count(count, front_count)` helper; preset supports optional `front_count` override. CombatManager fills rank 0 first by spawn order.

---

### Part 2: Density and Its Tradeoffs

#### Density Effects (Recap from Existing Docs)

| Density | spacing_m | Close attempt | Disengage | Physical width |
|---------|-----------|---------------|-----------|----------------|
| **Tight** | 0.9 | Easier to close (×0.8 evasion) | Harder to disengage (×0.8) | Narrow frontage per file |
| **Normal** | 1.2 | Standard | Standard | Default |
| **Loose** | 1.8 | Harder to close (×1.2 evasion) | Easier to disengage (×1.2) | Wide frontage per file |

#### Engagement Capacity: How Many Can Engage Each Unit?

**Tight formation:**
- Units packed shoulder-to-shoulder. Many attackers can get "close" to the same defender (bunching).
- **High attackers per defender** → defense split (parry_capacity / num_close_threats) hits harder.
- Fall back: **hard** — no room to slip through; lane blocked. Medieval: "pre-designated channels" required.
- Tendency: **fight to death** — can't rotate easily; you hold or die.

**Loose formation:**
- Units spread out. Each defender faces fewer close attackers (enemy also spread).
- **Lower attackers per defender** → defense split less severe.
- Fall back: **easier** — space to slip through; channels exist. Roman: gaps between maniples.
- Tendency: **rotate out** — exhausted can fall back; reserves replace.

#### Tradeoff Matrix

| Formation | Attackers per defender | Fall-back difficulty | Rotation | Typical outcome |
|-----------|------------------------|----------------------|----------|-----------------|
| **Tight (shield wall)** | High (3–4) | Hard (×1.3–1.6 duration) | Rare | Fight to death, plug or die |
| **Normal** | Medium (2) | Normal | Possible | Mix of hold and rotate |
| **Loose** | Low (1–2) | Easier (×0.9) | Common | Rotate when tired |

#### Implementation Hooks

1. **Close slots per target:** Already planned. Tight formation could allow more (e.g. 4 close per defender); loose fewer (2). Or: derive from density: `max_close_per_defender = 2 + (tight ? 2 : 0)`.
2. **Fall-back duration:** Already: `lane_modifier × pressure_modifier`. Density affects `lane_modifier`: tight = blocked/crowded more often; loose = clear more often.
3. **Fight-to-death tendency:** When lane is blocked and pressure high, fall-back may fail → unit stays in rank 0. Morale + formation state could drive "attempt fall back" vs "hold position" AI decision.

---

### Part 3: Survivability-Gated Push and Flank (Flag Protection)

#### Lore: Magic Flags and Protection Circles

- **Flag:** Creates magic-neutralization / protection circle. Units inside = protected.
- **Outside:** No protection; high risk. Only survivable units (heavy armor, high endurance) can operate there.
- **Norm:** Most units stay in circle. Shield walls engage front-on. Durable units may push into enemy lines.

#### Mechanical Translation

| Behavior | Normal unit | Survivable unit (heavy armor, high endurance) |
|----------|-------------|-----------------------------------------------|
| **Flank attempt** | Never (stay in circle) | Could, but flag design disables flank for all |
| **Push / incursion** | Never | Yes, when gap opens and conditions met |
| **Fall back** | Prefer (rotate out when hurt) | May hold (can absorb hits) |

#### Survivability Score

Derive a **survivability** value from existing stats:

```
survivability = f(armor, endurance, wounds, consciousness)
```

**Proposed formula:**
- **Armor:** Sum or max of armor resistance (RHA/mm) for vital parts. Normalized 0–1.
- **Endurance:** 0–1 from current/max.
- **Wounds:** Penalty for critical wounds, low health. 0–1.
- **Consciousness:** From EntityPainConsciousness. 0–1.

Example: `survivability = 0.4 * armor_norm + 0.3 * endurance_norm + 0.2 * (1 - wound_penalty) + 0.1 * consciousness_norm`

Or simpler: `survivability = armor_norm` (armor is the main differentiator for "can I survive outside the circle").

#### Push Decision Gate

**Current plan:** Incursion eligibility uses strength, ZoC, plug contest. Add **survivability threshold**:

| Step | Gate |
|------|------|
| 1. Slot opens | Plug attempt, incursion attempt (contest) |
| 2. Incursion eligibility | `survivability >= PUSH_SURVIVABILITY_THRESHOLD` (e.g. 0.6) |
| 3. Push decision roll | Only if eligible. Roll factors: push_tendency, morale, stamina. |

**Effect:** Unarmored, wounded, or low-endurance units never pass step 2. They never attempt incursion. They stay in formation, in flag protection.

#### Flank Attempt Gate (When Flank Exists)

If using ZoC-based flank (flank zone accessible when control < threshold):

| Step | Gate |
|------|------|
| 1. Flank zone accessible | Control < threshold |
| 2. Unit considers flank | `survivability >= FLANK_SURVIVABILITY_THRESHOLD` |
| 3. Flank attempt | Only if 2 passes |

**With flag lore:** Set `FLANK_ACCESS_THRESHOLD = 1.0` (never) so flank is never accessible. Then no unit can flank — all stay in circle. No survivability gate needed for flank.

**Alternative:** Keep flank logic but add encounter/formation flag `protection_circle_active`. When true:
- `get_available_zones()` never returns flank/rear.
- `engagement_angle` always "front".
- AI never considers flank. Survivability gate is redundant for flank (flank disabled globally).

#### Summary: Survivability Gates

| Action | Gate | Result |
|--------|------|--------|
| **Incursion (push)** | `survivability >= 0.6` (tune) | Only armored/durable units push |
| **Flank** | `protection_circle_active` → never | All stay in front; no flank |
| **Fall back** | None (all can try) | Normal units prefer; survivable may hold |

---

### Part 4: Implementation Outline

#### 4.1 Formation Preset Extensions

```gdscript
# FormationPreset - optional explicit front count
{
  "files": 4,           # Front-line width (default)
  "ranks": 3,           # Depth
  "density": "tight",   # tight | normal | loose
  "front_count": 4,     # Optional: override files for front; or files = front_count
  "reserve_ranks": 2    # Optional: explicit reserve depth
}
```

Assignment: Fill rank 0 first with `min(count, files)` units. Then rank 1, etc. Heavy armor favored for rank 0 when assignment logic exists.

#### 4.2 Density → Engagement and Fall-Back

| Constant / Formula | Value / Logic |
|-------------------|---------------|
| `max_close_per_defender` | `2 + (1 if density == "tight" else 0)` — tight allows more bunched attackers |
| `lane_clarity_base` | Loose: more often "clear"; tight: more often "crowded" or "blocked" |
| `fall_back_duration` | Already: `BASE × lane_mod × pressure_mod`. Tight → higher lane_mod on average |

#### 4.3 Survivability Computation

```gdscript
# Combatant or Entity
static func get_survivability(combatant: Dictionary, entity: Node) -> float:
    var armor_norm := _armor_score(entity)  # 0-1 from armor coverage/resistance
    var endurance_norm := entity.endurance / entity.endurance_max if entity.get("endurance") else 1.0
    var wound_penalty := _wound_severity_factor(entity)  # 0 = fine, 1 = critical
    return 0.5 * armor_norm + 0.3 * endurance_norm + 0.2 * (1.0 - wound_penalty)
```

Add `PUSH_SURVIVABILITY_THRESHOLD` (e.g. 0.5–0.6) to CombatConstants.

#### 4.4 Incursion Eligibility (Revised)

When slot opens:
1. Plug attempt (allies).
2. Incursion attempt: **only if** `get_survivability(pusher) >= PUSH_SURVIVABILITY_THRESHOLD`.
3. If eligible: contest plug vs push (existing roll logic).
4. Push decision: existing push_tendency, morale, stamina.

#### 4.5 Protection Circle (Flag) Flag

```gdscript
# Encounter or Formation
protection_circle_active: bool = true  # When true: no flank/rear access
```

When true:
- `get_available_zones()` returns only front (or front zone).
- `engagement_angle` always "front".
- AI target picker excludes flank/rear options.

---

### Part 5: Decision Summary

| Decision | Recommendation |
|----------|----------------|
| **Front-line control** | Use `files` = front count; optional `front_count` override. Fill rank 0 first. |
| **Density tradeoff** | Tight = more attackers/defender, harder fall back, fight to death. Loose = fewer attackers, easier rotation. |
| **Survivability gate** | Add `get_survivability(c)` from armor, endurance, wounds. Gate incursion: `survivability >= threshold`. |
| **Flank** | With flag: `protection_circle_active` → disable flank entirely. No survivability gate needed for flank. |
| **Push** | Incursion eligibility requires survivability threshold. Only durable units attempt. |

---

### Part 6: References

- `docs/TACTICAL_FORMATIONS_FF4.md` — breakthrough flow, plug vs incursion, fall-back duration
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — lane clarity, pressure, density
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — ZoC, flank access
- `docs/TACTICAL_FORMATIONS_FF4.md` — formation structure, targeting
- `combat/FormationPreset.gd` — current preset structure

---

<a id="medieval-formation-movement-switching-investigation"></a>

## Source: `MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md`

## Medieval Formation Movement & Rank Switching: Investigation

Investigation of how medieval (and Roman) formation movement—rank swap, fall back, retreat—actually worked, and how to model it realistically: **time and effort** vs stamina cost; **clear lane vs crowded**; **aggressive enemy vs defensive enemy**.

---

### Part 1: Historical Movement Mechanics

#### 1.1 Roman System (Maniple / Cohort)

| Aspect | How it worked |
|--------|----------------|
| **Gaps** | Deliberate gaps between maniples. Retreating troops fell back *through* gaps. |
| **Fall back** | Exhausted hastati withdrew through gaps; principes advanced into those gaps to fill the line. |
| **Cost** | **Time** — the withdrawal and advance took real seconds. **Coordination** — had to happen on command, in sync. **Risk** — during the moment of swap, the line was momentarily thinner. |
| **Stamina** | Exhaustion triggered rotation, but the *act* of falling back was not "spending energy" — it was *relief*. The effort was in holding the line until the moment to withdraw. |

**Key insight:** Falling back was **escape from exertion**, not exertion itself. The cost was **tactical** (temporary weakness, coordination) and **temporal** (took time).

---

#### 1.2 Medieval Shield Wall

| Aspect | How it worked |
|--------|----------------|
| **Channels** | Pre-designated channels for rotation. Reserved warriors from rear replaced exhausted front. |
| **Footwork** | Synchronized on vocal command. Small increments—no chaotic running. |
| **Plugging** | When a man fell, neighbors closed immediately. Gap = catastrophe. Fall back had to preserve the line. |
| **Structure** | 6–8 ranks deep (sometimes 16). Rear ranks reinforced; could advance when needed. |

**Key insight:** Rotation required (1) **clear path** — someone had to step aside or you went through a channel; (2) **time** — synchronized footwork took seconds; (3) **no panic** — controlled retreat. If you were **hard pressed** (enemy actively attacking), you couldn't safely withdraw—you'd be cut down or create a gap.

---

#### 1.3 What Made Fall Back Harder vs Easier

| Factor | Harder to fall back | Easier to fall back |
|--------|---------------------|----------------------|
| **Enemy pressure** | Aggressive enemy pressing the attack | Defensive enemy, low stamina, holding back |
| **Lane** | Rank 1 advancing into your slot (moving forward) or crowded | Clear channel; reserve holding position |
| **Formation density** | Tight shield wall (no room to step aside) | Loose formation (space to slip through) |
| **Exhaustion** | You're exhausted (slow, can't move quickly) | You're fresh (can move fast) |
| **Coordination** | Formation scattered, no command | Formation cohesive, synchronized |

**Your intuition is correct:** Stamina cost is wrong. The difficulty is **time** (how long the move takes) and **situational** (clear lane vs blocked, aggressive vs defensive opponent).

---

### Part 2: Recommended Model — Time + Situational Modifiers

#### 2.1 No Stamina Cost for Fall Back / Swap

**Rationale:** Historically, fall back was *escape* from exertion. Adding stamina cost would double-penalize the exhausted (they need to leave because low stamina, but leaving costs more stamina). The *reason* you fall back is often low stamina—the action itself shouldn't spend it.

**Implementation:** Fall back and swap rank do **not** consume stamina. They take **time** (event delay) and are **blocked or slowed** by situational factors.

---

#### 2.2 Time (Event Delay)

**Mechanic:** Fall back / swap rank is an event that resolves after a **duration**. Duration depends on:

| Factor | Effect on duration |
|--------|---------------------|
| **Base duration** | e.g. 0.5–1.5 s (agility, armor burden) |
| **Lane clarity** | Clear lane = base. Blocked/crowded = ×1.5 or ×2. |
| **Opponent pressure** | Aggressive opponent = ×1.3–1.5. Defensive/low stamina = ×1.0 or ×0.9. |
| **Formation density** | Tight = ×1.2. Loose = ×0.9. |

During this time, the unit is **vulnerable** — they're disengaging or moving. Opponent can attack them; if they're hit during the move, the move can be interrupted or they take penalty.

---

#### 2.3 Lane Clarity — People in the Way

**Clear lane:** Rank 1 is holding position or has space. Unit can slip through. Normal duration.

**Blocked / crowded:** 
- Rank 1 is **advancing** (plugging, filling a gap) — they're moving *into* the slot. Unit has to squeeze past or wait. **Slower**.
- Multiple units in same area (drag-back, step-over) — reduced footing, distraction. **Slower** and possibly **higher risk** (distraction deficit).

**Implementation:**
- `lane_clarity: "clear"|"crowded"|"blocked"` derived from formation state.
- `blocked` = rank 1 advancing into that file, or slot has multiple units (drag-back in progress).
- `crowded` = adjacent files shifting, or formation density tight.
- Duration multiplier: clear 1.0, crowded 1.3, blocked 1.6 (or roll to see if move succeeds at all when blocked).

---

#### 2.4 Opponent Pressure — Aggressive vs Defensive

**Aggressive opponent:** High stamina, actively attacking, pressing the engagement. Unit trying to fall back is "hard pressed" — they can't safely turn their back or step away. The opponent gets opportunities to strike during the move.

**Mechanic:**
- When unit attempts fall back, check opponent state: `opponent.stamina > 50` and `opponent.state in [WIND_UP, IN_FLURRY]` or `opponent.recent_action == "attack"` → **aggressive**.
- Aggressive: fall back duration ×1.3; or roll `disengage_hold` vs `opponent.hold_strength` — if fail, fall back delayed or cancelled.
- **Defensive opponent:** Low stamina, holding ground, not attacking. Unit can withdraw more easily. Duration ×1.0 or ×0.9.

**Alternative:** Use the existing **disengage roll** (defender rolls vs attacker hold). Fall back *includes* disengage. If opponent is aggressive (high hold, actively engaged), disengage is harder. If opponent is defensive (low stamina, not engaged), disengage is easier. So the **time** for fall back could scale with disengage difficulty — multiple attempts, or longer single attempt.

---

#### 2.5 Summary: Movement Cost Model

| Cost type | Fall back / Swap rank |
|-----------|------------------------|
| **Stamina** | None |
| **Time** | Yes — event delay 0.5–1.5 s base × situational modifiers |
| **Lane** | Clear = normal. Crowded = ×1.3. Blocked = ×1.6 or require coordination |
| **Opponent** | Aggressive = ×1.3 or harder disengage. Defensive = normal or easier |

**Formula (suggested):**
```
fall_back_duration = BASE_FALL_BACK_S * agility_factor * armor_burden_factor
                   × lane_modifier(lane_clarity)   # 1.0, 1.3, 1.6
                   × pressure_modifier(opponent)   # 0.9 defensive, 1.0 neutral, 1.3 aggressive
```

---

### Part 3: Implementation Notes

#### 3.1 Event Structure

Fall back and swap rank are **events** with `resolve_at = now + duration`. During the duration:
- Unit is in `STATE_FALLING_BACK` or `STATE_SWAP_RANK`.
- Opponent can target them (vulnerable).
- If unit is hit, optional: interrupt move, or apply penalty (distraction deficit when they arrive).

#### 3.2 Lane Clarity Calculation

- `get_lane_clarity(formation, rank, file)`:
  - If rank 1 at same file is advancing (plugging) → `blocked`.
  - If formation density tight and adjacent files shifting → `crowded`.
  - Else → `clear`.

#### 3.3 Aggressive vs Defensive Opponent

- `get_opponent_pressure(opponent)`:
  - If `opponent.stamina < 30` and not in WIND_UP → `defensive` (0.9× duration).
  - If `opponent.stamina > 60` and recently attacked or in flurry → `aggressive` (1.3× duration, or require disengage roll).
  - Else → `neutral` (1.0×).

#### 3.4 Integration with Disengage

Fall back *requires* disengage when at close. The disengage roll can be:
- **Easier** when opponent defensive (they're not holding you).
- **Harder** when opponent aggressive (they're pressing, holding).
- On success: unit transitions to mid/long, then executes the spatial move (fall back to rank 1 or rear zone).
- The **time** for the whole action = disengage attempt time + movement time.

---

### Part 4: Recommendation Summary

1. **No stamina cost** for fall back or swap rank.
2. **Time-based** — both take event delay; duration scales with lane clarity and opponent pressure.
3. **Lane clarity** — clear lane = fast; people in the way or advancing into your slot = slow or blocked.
4. **Opponent pressure** — aggressive enemy = harder (longer, or disengage roll); defensive/tired enemy = easier.
5. **Vulnerability** — during the move, unit can be targeted; hit may interrupt or penalize.

---

### References

- `docs/TACTICAL_FORMATIONS_FF4.md` — Roman vs medieval rotation, plugging
- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — Event queue, disengage
- Medieval shield wall rotation (Wikipedia, Medievalists.net): pre-designated channels, synchronized footwork

---

<a id="incursion-breach-migration-plan"></a>

## Source: `INCURSION_BREACH_MIGRATION_PLAN.md`

## Incursion & Breach Migration Plan

Plan to evolve the tactical layer from **aggregate pressure + lane stress** toward a **physically interpretable** breach model: spear-wall vs heavy fighter, **rank penetration**, **flank/rear exposure**, and **surround cost**—while **keeping** abstract formation state (`rank`, `file`, `distance_to`, `zone_id`, no continuous `(x,y)`).

**Related docs:** `docs/COMBAT_ROADMAP_AND_STAMINA.md` (Phase 4–6, Part 2 cross-cutting notes), `docs/TACTICAL_FORMATIONS_FF4.md`.

---

### 1. Goals

| Goal | Success criteria |
|------|------------------|
| **Tactical breach** | A unit can **enter a “deep” state** or **mark a file/edge breached** from **reach + spacing + local ZoC**, not only front-rank headcount. |
| **Rank breaking** | **Penetration depth** (e.g. `0 = front line`, `1 = past first rank`) is explicit and affects **engagement angle**, **surround load**, and optionally **targets**. |
| **Physics-flavored inputs** | Core levers are **meters** (reach, spacing), **time** (wind-up, reaction), **mass** (where already used)—constants are **tunable proxies** with documented meaning. |
| **No position tracking** | Still **no** continuous positions; only **coarse** grid + bands + optional **enum/depth** flags. |
| **Avoid double-count** | **Bodies** stay in `obs_pen`; **global** incursion and **local** breach use **headroom** or **separate terms** (see current `ZoneOfControl._raw_zone_strength`). |

---

### 2. Current Baseline (snapshot)

- **`TacticalCombat.recompute_incursion_pressure`**: global `delta = opp_front − our_front` → `incursion_pressure`; **`lane_stress_by_file`** from dual living + density.
- **`ZoneOfControl._raw_zone_strength`**: merges **global + lane** with **headroom**; **zone exposure** (front > flank > rear); **`obs_pen`** separate.
- **`TacticalCombat.count_engaging_threats` / `surround_defense_multiplier`**: count + `1/min(n,4)` × perception.
- **`ZoneOfControl.get_engagement_parry_multiplier`**: ZoC threshold + edge file → discrete flank/rear mods; pack `|Δfile| >= 2` fallback.
- **`AttackResolver`**: `surround_threat_count`, `zone_engagement_parry_mult`, `engagement_angle` inferred from mult vs constants.

---

### 3. Target Architecture (layers)

```
[ Coarse state: rank, file, zone_id, distance_to, weapon reach/mass ]
        ↓
[ Breach / hold contest ] → penetration_depth, breached_file/edge flags
        ↓
[ Threat load: sector-weighted surround ] → replaces plain count+split where desired
        ↓
[ ZoC raw strength ] ← global + lane + (optional) local breach stress
        ↓
[ Engagement parry mult ] ← continuous ZoC + explicit angle from zone/files
        ↓
[ DefenseChoiceResolver ] ← dodge/parry with sector-aware multipliers (optional phase)
```

---

### 4. Prerequisites (decide or document before / alongside implementation)

These items are **not** afterthoughts—they constrain **Phase A** (gate) and how **B–H** connect to the rest of the codebase. Review this section when executing the **master checklist (§9)**.

#### 4.1 Interacting systems

| Topic | Requirement |
|--------|----------------|
| **Multi-target / parry choice** (deferred in `COMBAT_ROADMAP_AND_STAMINA.md`) | If **threat load** replaces **threat count**, decide whether **multi-target** will **reuse** the same **load** model—avoid two unrelated “threat” definitions. Prefer **one** model or **documented** layering (ties to **§4.5** and roadmap Part 5). |
| **Medical phase** | **`penetration_depth` / breach flags** must **clear** or **freeze** when entering medical phase so **deep** does not keep flank/surround mods during triage. |
| **Formation moves** (swap / fall back / rotate) | Rules when **`penetration_depth > 0`** or **`breached_files`** active: e.g. **abort** breach on **reform**, **block** moves until cleared—lock in **Phase A**. |
| **Ranged (future)** | If rear ranks gain **ranged** later, define **deep** front-liners as archer targets or **melee-only** for surround—**one sentence** until ranged exists. |

#### 4.2 Gameplay rules (Phase A gate)

| Decision | Options to pick |
|----------|-----------------|
| **Who can go deep** | Rank **0** only vs **any** rank (relief into deep?). |
| **Symmetry** | Enemy uses **same** breach rules as player (recommended). |
| **Encounter flags** | **`protection_circle_active`:** **§10.2 A3** — discourage **wide flank/surround** across open ground between circles; **allow** **frontal** breach/crash into the opponent’s circle. |
| **Close vs breach** | **§10.2 A4** — **`attempt_close`** and **`crash`** are **separate** (engage vs break through). |
| **Stamina / tempo** | **§10.2 A5** — crash: stamina + cooldown; **no** extra deep tax—**surround** carries pressure while deep. |
| **Skirmish / interposition** | **§10.2 A6** — crash/breach **allowed** for **interposing** / disrupting between enemies, not only full formations. |
| **Breach exit** | **§10.2 A8** — breach lasts until **incap** or **no longer in enemy formation**; **§10.2 A7** — clear on **combat end** for post-combat medical. |

**Deliverable for Phase A:** Short **design note** (states, transitions, double-count rules with **obs_pen**, **incursion headroom**, **geometric reach**).

#### 4.3 API, naming & MOVE taxonomy

| Item | Requirement |
|------|-------------|
| **Tactical vs armor “penetration”** | Codebase uses **penetration** for **armor/sharp** (`WeaponDamageHelper`, `ArmorPiece`). Prefer **`tactical_penetration_depth`**, **`line_depth`**, or **`line_position`** in tactical API/docs—avoid confusion with **mm RHA**. |
| **`pa` / resolver keys** | Plan rename or parallel key: **`surround_threat_count`** → **`surround_load`** (or **count** = floor of load)—document for **AttackResolver** / **`DefenseChoiceResolver`**. |
| **`MOVE_ID` groups** | **`FORMATION_MOVEMENT_MOVE_IDS`** vs melee—**crash** belongs in a **separate** group (e.g. **`BREACH_MOVE_IDS`**) unless it truly shares the **formation pair** state machine. |
| **`get_combatants()`** | `CombatManager.get_combatants()` feeds **Battle UI** rows; add **`penetration_depth` / `line_position`** (and formation breach flags if surfaced) when those fields exist. |
| **Actions before AI** | **`CombatAIActionPicker`** only chooses among moves **`AvailableActionsBuilder.get_available_actions`** returns—**crash** (and any breach move) must be **implemented there** before Phase G utility tuning is meaningful. |

#### 4.4 Lifecycle, persistence & consistency

| Item | Requirement |
|------|-------------|
| **Combat start/stop** | **`start()`** rebuilds formations—reset **`breached_files`**, **`lane_stress_by_file`**, and new tactical fields as needed. **`_end_combat_phase`** may not clear all dicts; **`stop()`** + next **`start()`** does—document if **mid-battle reload** ever appears. |
| **Save/load** | If combat state is **persisted**, new fields go through **serialize** or are explicitly **non-persisted** (reset on load). |
| **Afterblow / riposte** | Secondary hits use the same **`AttackResolver`** path—**surround** / **zone** keys stay **per swing** if **`pa`** is rebuilt (verify when adding fields). |

#### 4.5 Surround math: count, split divisor, and load

| Item | Requirement |
|------|-------------|
| **`SURROUND_MAX_SPLIT_DIVISOR`** | Today **`surround_defense_multiplier`** uses **integer** `n` and **`mini(n, SURROUND_MAX_SPLIT_DIVISOR)`**. When Phase D introduces **float load**, define **one** rule: map load → effective **n**, **replace** split with the load curve only, or **cap**—avoid **two conflicting** surround semantics. |
| **FF4 checklist §9 (parry threat scoring)** | Still open; when **multi-target** lands, align **parry threat score** (momentum vs damage) with **surround load** per **§4.1**. |

#### 4.6 Tooling, events & validation

| Item | Requirement |
|------|-------------|
| **Feature toggle** | **Name** the flag in code + doc: **legacy surround count** vs **sector threat load** (Phase D). |
| **Telemetry / debug** | At least one line or overlay: `inc_g`, `lane_z`, `breach_stress`, `surround_load` (per tick or per attack). |
| **`CombatDebug`** | **`CombatDebug.flow_log`** / **`COMBAT_DEBUG`** branches for **breach/crash** outcomes, consistent with **attack** / **formation** logs. |
| **Event queue** | New **`EVENT_*`** for crash/breach must respect **FF4 §6** ordering (agility, then **`combatant_id`**) and avoid starving **`EVENT_ACTION_READY`**. |
| **Automated tests** | No in-tree `*test*.gd` harness today—Phase H: **manual** scenarios or **add** minimal GUT/headless before claiming **regression**. |

#### 4.7 Optional (post–v1)

- **Reform / rally** to clear **`breached_files`** without winning the fight.  
- **Morale**: cohesion when an ally stays **deep** too long.  
- **Plug vs breach on death** (outline deferred)—explicit **later**.

---

### 5. Phases

Each phase lists **tasks**. **§4** holds cross-cutting requirements; phases should not contradict them.

#### Phase A — Design locks (short)

- [ ] Define **`penetration_depth`** enum or `0..N` (max ≈ `formation.ranks - 1` or cap at 2).
- [ ] Define **enter/exit**: **Crash** action, successful breach contest, **disengage**, **death**, **rout** (see **§4.2**).
- [ ] Define **surround “price”** while deep: min floor, sector weights, or **attention load** (units: normalized 0..1).
- [ ] Confirm **double-counting** with **obs_pen**, **incursion headroom**, **geometric reach**.

**Deliverable:** Design note (append to this doc or appendix).

---

#### Phase B — Data on combatants & formations

- [ ] Add **`combatant["penetration_depth"]`** or **`line_position`** (see **§4.3** naming).
- [ ] Optional: **`formation["breached_files"]`** / **`edge_breach`** with **TTL** or until **reform**.
- [ ] Optional: **`combatant["breach_until_clock"]`** for timed disorder.
- [ ] **`CombatManager`**: defaults on **register**; respect **§4.4** lifecycle and save/load.

**Files:** `ui/CombatManager.gd`; persistence paths if any.

---

#### Phase C — Breach / hold resolver (core)

- [ ] Module **`combat/BreachResolver.gd`** (or `TacticalCombat` methods): **hold** vs **drive** strength using existing reach/spacing/ZoC inputs—**no** new coordinates.
- [ ] Output: success / fail / partial; set **`penetration_depth`** and/or **`breached_files`**.
- [ ] Integration: **`CombatManager.resolve_action`** for **`MOVE_ID_CRASH`** or tagged **close**—prefer **event-driven** (see **§4.6** events).
- [ ] **`MOVE_ID`**: use **`BREACH_MOVE_IDS`** (or equivalent) per **§4.3**.

**Files:** `BreachResolver.gd`, `CombatConstants.gd`, `AvailableActionsBuilder.gd`, `CombatManager.gd`.

---

#### Phase D — Surround: threat load (replace or parallel)

- [ ] **Sector-weighted load** from **`can_melee_threaten`**, **`zone_id`**, **`Δfile`**, reach at **`distance_to`**.
- [ ] **`surround_defense_multiplier`**: e.g. **`1/(1+k·load)`** + perception; reconcile with **`SURROUND_MAX_SPLIT_DIVISOR`** per **§4.5**.
- [ ] **`penetration_depth > 0`**: min load floor or rear-sector weight (**§4.2** surround price).
- [ ] **`pa`** keys and **feature toggle** per **§4.3** and **§4.6**.

**Files:** `TacticalCombat.gd`, `AttackResolver.gd`, `DefenseChoiceResolver.gd` as needed.

**Migration:** Legacy **count** behind toggle until tuning stabilizes.

---

#### Phase E — Flank / engagement: continuous + explicit

- [ ] **`get_engagement_parry_multiplier`**: smooth ZoC + file + optional **`breached_files`**.
- [ ] **`AttackResolver`**: **`engagement_angle`** from explicit rules, not only **`zone_mult`** vs **FLANK/REAR** constants.

**Files:** `ZoneOfControl.gd`, `AttackResolver.gd`, `CombatConstants.gd`.

---

#### Phase F — Incursion stack alignment

- [ ] Choose: tactical breach **replaces** part of **`incursion_pressure`** vs **adds** **`local_breach_stress[file]`** into **`_raw_zone_strength`**.
- [ ] Preserve **headroom** merge; third term only if non-duplicative (**§4.1** multi-target alignment).

**Files:** `TacticalCombat.gd`, `ZoneOfControl.gd`.

---

#### Phase G — AI & UI

- [ ] **`AvailableActionsBuilder`**: expose **crash** before **`CombatAIActionPicker`** can weight it (**§4.3**).
- [ ] **CombatAIActionPicker**: crash when local ZoC weak + reach favorable; avoid deep when load/stamina high; **cooldown** on crash (**§6**).
- [ ] **`get_combatants()`** + rows / diagram / **`CombatLogFormatter`**: Deep, breached file, optional load (**§4.3**).

**Files:** `AvailableActionsBuilder.gd`, `CombatAIActionPicker.gd`, `CombatLogFormatter.gd`, `FormationDiagramBuilder.gd`, `CombatManager.gd`.

---

#### Phase H — Validation & tuning

- [ ] Scenarios: 1 vs 3 same file; weak center; tight vs loose density; deep surround spike.
- [ ] Regression: ZoC, surround, formation moves, incursion headroom—per **§4.6** test strategy.

---

### 6. Risk register

| Risk | Mitigation |
|------|------------|
| Over-stacking debuffs | **Caps** on **inc_pen + breach + surround**; **document** each term. |
| AI always/never crashes | **Utility thresholds** + **cooldown** on crash. |
| Performance | **Breach** on **action**, not every frame; threat load **O(n²)** same order as current surround count. |

---

### 7. Suggested order of implementation

0. **Phase A** (**gate**) — satisfies **§4.2**; blocks **B**.  
1. **Phase B** + **Phase E** — data + explicit **`engagement_angle`** / smooth flank (lower risk).  
2. **Phase D** — threat load; use **toggle** (**§4.6**).  
3. **Phase C** — `BreachResolver` + **MOVE_ID** / hooks.  
4. **Phase F** — incursion alignment.  
5. **Phase G** — AI/UI (**§4.3** surfaces).  
6. **Phase H** — scenarios + validation (**§4.6**).

---

### 8. Out of scope (later)

- Full **Shardplate** / **blade** fantasy systems (separate **durability** layer).  
- **3D** positioning or **navmesh**.  
- **Cavalry charge** as separate physics integrator.

---

### 9. Master checklist

Use this as the **single** execution list; detailed rules live in **§4** and phase sections in **§5**.

- [ ] **§4** prerequisites reviewed (interacting systems, gameplay, API, lifecycle, surround math, tooling).  
- [ ] **Phase A** complete (**gate**).  
- [ ] **Phase B**: combatant/formation fields.  
- [ ] **Phase C**: `BreachResolver` + integration.  
- [ ] **Phase D**: sector-weighted surround + **§4.5** reconciliation.  
- [ ] **Phase E**: smooth ZoC flank + explicit **`engagement_angle`**.  
- [ ] **Phase F**: incursion / breach / lane coherence.  
- [ ] **Phase G**: AI + UI + **`get_combatants`**.  
- [ ] **Phase H**: scenarios + regression strategy.

---

### 10. Phase A — Design locks (gate for Phase B+)

**Status:** **Gameplay locks (§10.2) are decided** (see below). **§10.3** systems alignment still needs confirmation before Phase D/F polish; Phase B may proceed per §10.5.

#### 10.1 Already constrained (do not contradict)

| Topic | Lock |
|--------|------|
| Distance / close attempt | FF4 §1: hybrid model; **attempt_close** = roll vs evasion (engagement_pressure vs defender evasion), stances apply. |
| Flank / rear vs protection circle | FF4 §5: ZoC-based flank/rear. **`protection_circle_active`:** **discourage wide flanking** (leaving the friendly circle to cross **open ground between** circles and **surround** the enemy). **Do not** treat frontal **line break** the same: units **may** push **straight forward** into the opponent’s circle and **crash through** the line. Implementation: forbid or penalize **lateral / encirclement** paths; **allow** **frontal breach** and **crash** (see **§10.2 A3**). |
| Event ordering | FF4 §6: agility, then `combatant_id`. |
| Surround split cap | FF4 §4: `SURROUND_MAX_SPLIT_DIVISOR` = **4** (tune later). |
| Spacing / effective distance | FF7–8: density-derived spacing; `|Δfile| × avg_spacing`; `REACH_SAFETY_FACTOR` = 0.8. |
| Multi-target / parry threat | FF4 §8–9 still **open** globally; incursion plan §4.1 says **one** threat model when surround load lands—**align when those checklist items are filled**. |
| Tactical vs armor “penetration” | §4.3: use **`tactical_penetration_depth`** (int 0..N) in combatant/formation API—not armor RHA “penetration”. |

#### 10.2 Gameplay — **locked**

| # | Decision | **Locked resolution** |
|---|----------|------------------------|
| **A1** | Who can go deep; rank vs relief | **Front rank (rank 0)** is the **line** that holds breach; when a unit **pushes forward** into the enemy formation, **others step up and fill** rank 0 (normal relief). **Deep / breach** tracks **who is actually forward in the contest**, not a separate “any rank” deep state without this fiction. |
| **A2** | Symmetry | **Same rules** for player and enemy. |
| **A3** | `protection_circle_active` | **Do not** disable frontal breach or crash. Circles **discourage flanking by surrounding** (leaving the circle, crossing **open** space between circles to get to the enemy **flank**). They **do not** discourage **breaking through** the **front** of the enemy line **straight ahead** into the opponent’s circle. (ZoC flank/rear tuning for “inside circle” may still apply; **frontal** push is allowed.) |
| **A4** | `attempt_close` vs `crash` | **Separate features.** **Close** = get into **engagement** (distance / facing the fight). **Crash** = **break past** the opponent’s guard to **move through** / **disrupt** the line—not merely “in position to engage.” |
| **A5** | Stamina / tempo | **Crash** uses **stamina** and a **cooldown** (charge-through-the-line attempt). **No** extra “deep stamina tax” or artificial debuff: pressure while deep comes from **being surrounded** (many threats) and existing **surround** / defense math—not a separate exhaustion rule. |
| **A6** | Skirmish / loose fights | **Still available** where it makes sense: a unit can **push forward** and **interpose** between enemies to **throw them off**, not only in perfect multi-file lines. (Implementation: allow **crash / breach** when the action is **tactically meaningful**—e.g. interposition / disrupt—even if not both full formations.) |
| **A7** | When breach clears (medical / post-combat) | **Clear breach when combat ends** so the unit can **return to friendly lines** and **post-combat medical** care is unblocked. (Mid-fight **medical_phase** behavior can follow the same “clear when fight segment ends” pattern if needed—wire in **CombatManager.stop** / end-of-combat cleanup.) |
| **A8** | How long breach lasts | **Persist** until the **breaching unit** is **incapacitated** **or** **no longer in the enemy formation** (retreated, left the contested formation / forward position). **Not** “friendly formation move clears everyone” by default—**reform does not** wipe breach unless it **removes** the breacher from the enemy formation (see exit conditions). |

**Supersedes** earlier A8a/A8b (reform-wide clear): those options are **not** adopted.

#### 10.3 Systems alignment — still open (confirm before Phase D / F / save hooks)

| # | Decision | Proposed default (v1) |
|---|----------|------------------------|
| B1 | **Phase F:** incursion stack | **Add** `local_breach_stress[file]` (or per-side dict) into ZoC merge **without** removing `incursion_pressure` until tuned; preserve headroom merge. |
| B2 | **§4.5 Surround:** float load vs integer `n` | **Toggle:** legacy **count** path default **on**; when `FEATURE_SECTOR_SURROUND_LOAD` (name TBD) is on, use **load →** `1/(1+k·load)` and **stop** using integer split for that path (document single rule—no double semantics). |
| B3 | **Save/load** | New tactical fields **non-persisted** until you add serialize hooks (reset on load). |

#### 10.4 Double-count / stacking (deliverable summary)

- **`obs_pen`:** slot obstacles / bodies stay **only** in ZoC casualty term (`ZOC_CASUALTY_PER_BODY` path)—not folded into lane stress or global incursion.  
- **Global incursion:** front-rank delta → `incursion_pressure` (existing).  
- **Lane stress:** dual living + density per file (existing); merged with global via **headroom** (`INCURSION_LANE_HEADROOM_FACTOR`).  
- **Breach (future):** third term only as **`local_breach_stress`** or penetration-driven modifier **after** verifying it does not duplicate incursion or lane terms; **caps** on combined penalties per §6 risk register.

#### 10.5 Phase A completion checklist

- [x] **§10.2** gameplay locks recorded (**A1–A8**).  
- [x] **A8a/A8b** — **N/A** (replaced by **A8 persistence** rule).  
- [ ] **§10.3** B1–B3 confirmed (before Phase D/F and persistence work).  
- [ ] §10.4 reviewed (no objection).  
→ **Phase B** (data on combatants/formations) may proceed under **§10.2**.  

---

*Last updated: §10.2 gameplay decisions locked; protection circle clarified (frontal breach vs wide flank); A8 persistence replaces reform-clear options.*

---
