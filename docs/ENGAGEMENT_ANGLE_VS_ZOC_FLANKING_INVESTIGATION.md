# Engagement Angle vs ZoC-Based Flanking: Investigation

Investigation for the FF4 formation system: which approach is most accurate for determining flank/rear bonuses—**engagement angle** (per attacker–defender pair) or **ZoC-based** (enemy occupies weak zones)?

---

## Part 1: Summary of Approaches

### Option B: Engagement Angle

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

### Option C: ZoC-Based

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

## Part 2: Fit for Fallen Paths

### System Constraints

| Constraint | Implication |
|------------|-------------|
| **Full ZoC (D) chosen** | Zone control already calculated. ZoC-based naturally extends it. |
| **Phase 4 = ZoC** | ZoC comes after formations (Phase 3). Flanking in Phase 6 (tactical features). |
| **Formation vs formation + pack vs formation** | Need both: formed units in zones; unformed units (packs) without zone structure |
| **Quantum positioning** | No x,y; position = zone + rank + file. ZoC zones are the spatial model |

### When Each Works Best

| Scenario | Engagement angle | ZoC-based |
|----------|------------------|-----------|
| Formation vs formation, both strong | Flank = leftmost/rightmost files (static) | No flank until control drops |
| Formation vs formation, one side battered | Angle can stay front if geometry unchanged | Control dropped → flank accessible ✓ |
| Pack vs formation | Pack chooses approach (front/flank/rear) | Pack has no zones; need rule: can they access flank? |
| Incursion (enemy in our zone) | Angle = rear (they're behind us) | ZoC dropped → they occupy rear ✓ |

### Pack vs Formation: The Gap

**Engagement angle:** Unformed units explicitly choose approach. "Flank left" = flank bonus. No need for zone control—they're not in a formation, so they get to pick.

**ZoC-based:** Unformed units don't occupy zones. How do they get flank/rear? Options:
1. **Hybrid:** ZoC gates formation-vs-formation. For pack vs formation, use engagement angle (pack chooses approach; formation files/flanks define geometry).
2. **ZoC proxy for packs:** Pack "occupies" flank zone when formation's flank control is low—same threshold, but pack doesn't add to control. They just exploit weakness.
3. **ZoC only:** Pack can never flank until they've reduced formation's control (by killing front rank, etc.). More restrictive.

---

## Part 3: Recommendation

### For Fallen Paths: **Hybrid — ZoC Primary, Angle Fallback**

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

### Why Not Pure ZoC or Pure Angle?

| Pure approach | Problem |
|---------------|---------|
| **Pure ZoC** | Pack vs formation has no way to flank (pack has no zones). Need extra rule. |
| **Pure angle** | Formation vs formation flank feels unearned—flank files are always vulnerable even when formation is strong. |

Hybrid uses ZoC when it applies (formation structure, control state) and angle when ZoC doesn't (unformed attackers).

---

## Part 4: Implementation Notes

1. **`engagement_angle`** — Keep as combatant or pair field. Filled by:
   - ZoC: when enemy occupies our weak zone
   - Pack: when unformed attacker chooses approach

2. **Modifiers** — Use same table for both paths: front 1.0, flank 0.8, rear 0.7 (tune later).

3. **Phase 6** — Implement flanking when ZoC exists. Pack fallback can ship with or after.

4. **Investigate further** — Per user: "investigate more accurate numbers" for flank/rear modifiers. Historical sources, playtesting.

---

## References

- `docs/FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md` — Section 3.8 Flanking
- `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` — ZoC, breakthrough
- `docs/ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md` — Zone structure
- `docs/FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md` — Approach E, angle as modifier
