# Formation Combat + Surround / Multi-Angle Attack: Investigation

Investigation of how to combine row/file formation combat with surround tactics—packs of animals, split groups attacking from multiple angles—and the tradeoffs vs alternatives.

---

## Part 1: The Tension

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

## Part 2: Approaches to Combine Formation + Surround

### Approach A: Formation Has Sides (Front, Flank, Rear)

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

### Approach B: Formation + "Unformed" as Combat Modes

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

### Approach C: Explicit Approach Vector (Attack From X)

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

### Approach D: Formation Perimeter "Slots" by Angle

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

### Approach E: Keep Formation, Add "Angle" as Simple Modifier

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

## Part 3: Bonuses and Drawbacks of Multi-Angle / Surround

### Bonuses of Implementing

| Benefit | Description |
|---------|-------------|
| **Pack combat** | Wolves, bandits, creatures can surround. Feels natural for animals. |
| **Tactical depth** | Small group can flank instead of suicidal head-on charge. |
| **Formation vulnerability** | Formations have flanks and rear. Historically accurate. |
| **Variety** | Different enemy types (formation vs pack) play differently. |
| **Exploitable weaknesses** | Player can flank a shield wall; enemies can flank player formation. |

### Drawbacks / Costs

| Cost | Description |
|------|-------------|
| **Position state** | Need to track "which side" or angle for each attacker. More state, more logic. |
| **AI complexity** | Pack AI must distribute across sides. Formation AI must respond to flank threats (wheel? refuse flank?). |
| **Ambiguity** | When formations breach, mix, or rout—who has which angle? Needs clear rules. |
| **Balance** | Flank/rear bonuses can be too strong. Must tune. |
| **Player communication** | Player needs to understand "flank" option and when it's available. |

---

## Part 4: Alternatives to Full Multi-Angle

### Alternative 1: Flank as Formation-Only (No Surround)

- Only formation vs formation. Flank occurs when one formation's files extend past the other's (e.g. we have 6 files, they have 4—our left and right files hit their flanks).
- No pack surround. Packs use distance bands only; all attacks count as "front" (or apply a flat "outnumbered" penalty to formation).
- **Pros:** Simpler. No per-attacker angle. **Cons:** Packs can't surround; less tactical for pack fights.

---

### Alternative 2: Surrounded = Defense Penalty (No Angles)

- Don't model angles. Model "surrounded" as a count: if defender has N attackers at close and N ≥ SURROUND_THRESHOLD (e.g. 3), apply flat parry penalty (e.g. × 0.6).
- Works for packs. No need to know "front vs flank." Just: more attackers = more overwhelmed.
- **Pros:** Already in plan (defense splitting). No new positioning. **Cons:** No flank/rear distinction; formation has no vulnerable sides.

---

### Alternative 3: Formation Flanks as Weak Files

- Formation's leftmost and rightmost files are "flank files." They have fewer ranks (exposed) or lower defense (can't support each other well).
- Attackers that target flank files get a bonus—not because of angle, but because the target is in a weak file.
- Pack "surrounds" by having some attackers target left file, some right, some center. No explicit angles—target choice does it.
- **Pros:** Reuses file structure. No new angle state. **Cons:** Only works when formation has multiple files; 1-file "column" has no flanks.

---

### Alternative 4: Defer Multi-Angle Entirely

- Ship formation combat without flank/rear. Add "surrounded" defense penalty only (Alternative 2).
- Revisit multi-angle in a later update if pack combat feels flat.
- **Pros:** Faster to ship. **Cons:** Packs less interesting; no flank tactics.

---

## Part 5: Recommendation Summary

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

## Part 6: Integration With Spear Lane Targeting (Deferred)

The spear lane design (over-shoulder vs open lanes, target restrictions) applies to **formation** combat—rank 0 density, rank 1 density, shield type. It does not directly apply to **surround** combat, because:

- Surround: attackers are at close from multiple angles. No "rank 1 spears behind rank 0." The formation is being attacked from the side or rear—rank 1 may not have clear lanes at all (they're facing the wrong way).
- When formation is flanked/rear: rank 1 spears might need to *turn* to face. That's a different scenario—reserves facing backward. Lane design would apply there only if you model "rear rank" as having its own lanes.

For implementation order: complete formation + lanes first. Multi-angle (flank/rear) can layer on afterward; rear attacks may ignore lane targeting (full body available) since there's no friendly rank 0 in the way.

---

## References

- `docs/STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md` — formation, spear lanes, multi-actor
- `docs/STAMINA_ENGAGEMENT_GATE_AND_DISTANCE_OPTIONS.md` — distance and gating
