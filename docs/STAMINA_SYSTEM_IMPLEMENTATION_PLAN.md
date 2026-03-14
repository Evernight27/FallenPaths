# Stamina-Based Combat: Implementation Plan (Distance Bands + Event Queue)

## Design Decision: Chosen Approach

- **Distance:** Abstract distance bands (close / mid / long)
- **Resolution:** State-based event queue (no gauge; events scheduled by timestamp)
- **Gating:** Stamina threshold + engagement cooldown
- **Engagement:** Melee-only; occurs when two combatants are at **close** and exchange blows
- **Future:** Designed for ranged (mid/long) and magic (band by spell)

---

## Part 1: Distance Bands

### Band Definitions

| Band | Melee | Ranged | Magic (future) | Notes |
|------|-------|--------|----------------|-------|
| **Close** | ✓ Full | ✗ No (or disadvantaged) | Touch only | Engagement; bind; flurry |
| **Mid** | Spear only (long reach) | ✓ Effective | Projectile spells | Default for ranged |
| **Long** | ✗ No | ✓ Reduced accuracy | Long-range spells | Out of melee threat |

### Per-Pair State

```gdscript
# Pair (A, B) has:
distance_band: String  # "close", "mid", "long"

# Initial: "long" (combat start)
# Transitions:
#   long → mid:   Ranged closes; or melee "approach" (spends stamina)
#   long → close: Melee "close" action succeeds vs defender evasion
#   mid → close:  Melee "close" succeeds
#   close → mid:  Defender disengages (roll vs hold)
#   close → long: Defender flees (agile/light more likely)
#   mid → long:   Either retreats
```

### Band Transitions (Melee)

- **To close:** Attacker rolls `engagement_pressure` vs `defender.evasion`. Success → close.
  - `evasion = agility * (1 - armor_burden) * stamina_factor`
  - `engagement_pressure = strength * stamina_factor * reach_factor`
- **From close (disengage):** Defender rolls `disengage_ability` vs `attacker.hold_strength`.
  - Success → band becomes mid (agile/light) or mid (heavy). On strong success → long.
  - `disengage_ability = agility * (1 - armor_burden) * stamina_factor`
  - `hold_strength = attacker.strength * weapon_mass_factor`

### Weapon Reach by Band

| Weapon | Close | Mid | Long |
|--------|-------|-----|------|
| Dagger (0.8m) | ✓ | ✗ | ✗ |
| Sword, Axe, Mace (1.5m) | ✓ | ✗ | ✗ |
| Spear (2.5m) | ✓ | ✓ | ✗ |

---

## Part 2: State-Based Event Queue

### Core Idea

Replace **gauge fill → act when 100%** with **event queue**: each action is an event with `resolve_at: float` (game time). The combat loop processes the queue in chronological order. State drives what events can be scheduled.

### Event Types

```gdscript
# Event: { "type": String, "combatant_id": int, "resolve_at": float, "data": Dictionary }

# Types:
EVENT_ACTION_READY     # Combatant can choose action; schedule next event based on choice
EVENT_MELEE_ATTACK     # Wind-up complete; resolve attack
EVENT_MELEE_CLOSE      # Attempt to close distance (melee)
EVENT_DISENGAGE        # Attempt to break engagement
EVENT_RECOVERY_END     # Recovery finished; back to ready
EVENT_FLURRY_BLOW      # Next blow in engaged exchange
EVENT_DEATH_TICK       # Check for bleed-out etc.
EVENT_MEDICAL_*        # Medical phase events (unchanged)
```

### State Machine (Per Combatant)

```gdscript
# States (replaces gauge-based WAITING, WIND_UP, RECOVERING)
STATE_IDLE             # Can schedule action (if stamina, cooldown OK)
STATE_CLOSING          # Attempting to close to target; event will resolve
STATE_WIND_UP          # Melee attack winding up; EVENT_MELEE_ATTACK scheduled
STATE_IN_FLURRY        # Engaged; alternating blows; EVENT_FLURRY_BLOW per blow
STATE_RECOVERING       # Post-action recovery; EVENT_RECOVERY_END scheduled
STATE_DEAD
STATE_COWERING
STATE_MEDICAL_*        # Existing medical states
```

### Queue Processing (Main Loop)

```
1. Advance combat_clock by delta (or by fixed tick)
2. Pop all events with resolve_at <= combat_clock (in order)
3. For each event:
   a. Update state if needed (e.g. target died)
   b. Run event handler:
      - EVENT_ACTION_READY → get_available_actions; AI/player picks; schedule EVENT_MELEE_CLOSE or EVENT_MELEE_ATTACK or EVENT_RECOVERY_END (pass) etc.
      - EVENT_MELEE_CLOSE → resolve close roll; update distance_band; schedule next (engage→flurry start, or fail→ACTION_READY)
      - EVENT_MELEE_ATTACK → resolve attack (hit/parry/miss); apply result; schedule RECOVERY_END or FLURRY_BLOW
      - EVENT_FLURRY_BLOW → resolve blow; consume stamina; if disengage or stamina low → RECOVERY_END both; else schedule next FLURRY_BLOW
      - EVENT_RECOVERY_END → state = IDLE; schedule EVENT_ACTION_READY at now + engagement_cooldown (or immediately if cooldown 0)
4. Refill stamina for IDLE combatants (over time)
5. Emit turn_ready for player when EVENT_ACTION_READY for player-side combatant and they're IDLE
```

### Event Timing (State-Based)

- **Wind-up duration:** `CombatTiming.wind_up_duration(...)` — unchanged
- **Recovery duration:** `CombatTiming.recovery_duration(...)` — unchanged; multiply by ENGAGED_RECOVERY_MULT when engaged
- **Close attempt:** Fixed duration (e.g. 0.3s) or derived from agility
- **Flurry blow:** Reduced wind-up (e.g. 0.2–0.4s) when engaged
- **Engagement cooldown:** `COOLDOWN_BASE * (100/agility) * (1 + armor_burden * 0.5)`

### State → Event Mapping

| Current State | Transition | Event Scheduled |
|---------------|------------|-----------------|
| IDLE | Choose "close" | EVENT_MELEE_CLOSE at now + close_duration |
| IDLE | Choose "attack" (already close) | EVENT_MELEE_ATTACK at now + wind_up |
| IDLE | Choose "wait" | EVENT_ACTION_READY at now + cooldown |
| CLOSING | Succeed | distance=close; EVENT_MELEE_ATTACK (or flurry start) |
| CLOSING | Fail | EVENT_ACTION_READY at now + short_cooldown |
| WIND_UP | Complete | EVENT_MELEE_ATTACK fires → resolve |
| Post-attack | Engaged | EVENT_FLURRY_BLOW for defender riposte |
| Post-attack | Not engaged | EVENT_RECOVERY_END at now + recovery |
| IN_FLURRY | Blow resolved | Next EVENT_FLURRY_BLOW or EVENT_RECOVERY_END |
| RECOVERING | Complete | EVENT_ACTION_READY at now |

---

## Part 3: Data Structures

### Combatant (Additions)

```gdscript
# Add to combatant dict:
distance_to: Dictionary = {}      # target_id -> "close"|"mid"|"long"
engaged_with_id: int = -1
engagement_cooldown_until: float = -1.0
# Remove: gauge (replaced by event schedule)
# Keep: state, state_timer, state_duration for compatibility during migration
```

### Combat Manager (Additions)

```gdscript
# Event queue (min-heap or sorted list by resolve_at)
event_queue: Array = []  # [{ type, combatant_id, resolve_at, data }, ...]

# Game time (replaces implicit delta accumulation)
combat_clock: float = 0.0

# Process: advance combat_clock, process events
func _process(delta: float) -> void:
    combat_clock += delta
    _process_event_queue()
```

### Pair-Wise Distance

```gdscript
# Option A: Store per combatant
# c.distance_to[other_id] = "close"

# Option B: Store in manager as (id1, id2) -> band
# distance_bands[{min(id1,id2), max(id1,id2)}] = "close"
```

---

## Part 4: Pre-Switch Considerations

### 4.1 Must Address Before Migration

| # | Consideration | Action |
|---|---------------|--------|
| 1 | **UI dependency on gauge** | BattleUI, CombatantRowBuilder, turn_ready all assume gauge. Replace with "next action ready at time X" or event-based readiness indicator. |
| 2 | **Player input flow** | Player currently gets turn_ready when gauge=100. New: emit when EVENT_ACTION_READY for player and state=IDLE. Player chooses → we schedule. |
| 3 | **AI action picking** | AI picks when gauge full. New: AI picks when EVENT_ACTION_READY fires. Same `get_available_actions` + `CombatAIActionPicker.pick`. |
| 4 | **Stamina floor for engagement** | Add STAMINA_ENGAGE_MIN (e.g. 20). Below this: cannot initiate close or attack. Can only wait (recover stamina). |
| 5 | **Armor burden** | Add `armor_burden` per combatant. ArmorPiece/layer needs `mobility_penalty` or `weight`. Used in evasion, disengage, cooldown. |
| 6 | **Multi-target (2v1, 3v2)** | Define: who gets engagement? Rule: engagement = 1v1. If A engages B, C attacking B is "external" — resolves as normal attack (no flurry with C). B's engagement is with A. C's attack may hit B (interrupt flurry?). Need clear rule. |
| 7 | **Medical phase** | Medical phase currently runs after combat. Event queue must support medical events. Likely: combat_ended → medical phase → different event set (simpler, or medical uses same queue with EVENT_MEDICAL_*). |

### 4.2 Should Address

| # | Consideration | Action |
|---|---------------|--------|
| 8 | **Afterblow integration** | Afterblow already exists. In event queue: afterblow = additional EVENT_MELEE_ATTACK or EVENT_FLURRY_BLOW? Need to slot into queue. |
| 9 | **Passive parry** | Parry is reactive during attack resolution. Unchanged—AttackResolver still runs DefenseChoiceResolver. |
| 10 | **Death/incapacitation tick** | Currently in process loop. Becomes EVENT_DEATH_TICK scheduled periodically, or on each EVENT_ACTION_READY check. |
| 11 | **Guard, guard_line, guard_zone** | Keep. Still used for parry/defense. |

### 4.3 Nice to Have Before Switch

| # | Consideration | Action |
|---|---------------|--------|
| 12 | **Ranged/magic placeholders** | Define EVENT_RANGED_ATTACK, EVENT_CAST_SPELL. Implement later; structure supports. |
| 13 | **External interrupt (ranged hits engaged pair)** | Rule: ranged can target anyone. Hit on engaged combatant: apply damage; optionally break engagement. |
| 14 | **Combat log** | Ensure CombatLogFormatter receives same action_resolved signals. Event handlers must emit. |

### 4.4 Additional Considerations

| # | Consideration | Action |
|---|---------------|--------|
| 15 | **Combat start: who acts first?** | Schedule initial EVENT_ACTION_READY for all combatants at `combat_clock + initiative_delay`. Initiative delay = f(agility, armor_burden) — faster/ lighter goes first. Or roll; lowest delay acts first. |
| 16 | **resolve_action / _execute_attack** | Current: resolve_action → picks move/target → AttackWindUpStarter → _execute_attack. New: resolve_action schedules EVENT_MELEE_CLOSE or EVENT_MELEE_ATTACK. _execute_attack becomes the handler for EVENT_MELEE_ATTACK. Same AttackResolver, AttackResultApplier. |
| 17 | **Simultaneous events** | When multiple events have same resolve_at, order by: (a) initiative/agility, (b) combatant_id for tie-break. Ensures deterministic resolution. |
| 18 | **Player "wait" or pass** | Player must be able to pass (recover stamina, let enemies act). Action "wait" schedules EVENT_ACTION_READY at now + WAIT_DURATION (e.g. 0.5s) without spending stamina on attack. |

### 4.5 Migration Order (Suggested)

1. **Phase 0: Prep**
   - Add armor_burden to armor/combatant
   - Add distance_band state (default "long" for all pairs)
   - Add event_queue, combat_clock to CombatManager
   - Add new states (IDLE, CLOSING, etc.) to CombatConstants

2. **Phase 1: Event Queue Skeleton**
   - Implement _process_event_queue; process only EVENT_ACTION_READY initially
   - EVENT_ACTION_READY: emit turn_ready (player) or AI pick; schedule "attack" as EVENT_MELEE_ATTACK at now + wind_up
   - Keep existing AttackResolver, AttackResultApplier; call from event handler
   - Disable gauge fill; use event-driven "ready" instead

3. **Phase 2: Distance Bands**
   - Add close/mid/long transition logic
   - EVENT_MELEE_CLOSE for "approach" when not close
   - Only allow EVENT_MELEE_ATTACK when distance band permits (close for melee)

4. **Phase 3: Engagement & Flurry**
   - On successful melee hit/parry when close: form engagement
   - EVENT_FLURRY_BLOW for riposte/counter
   - Disengage on stamina low, max blows, or disengage roll

5. **Phase 4: Cleanup**
   - Remove gauge from combatant, UI
   - Remove STATE_WAITING, STATE_WIND_UP, STATE_RECOVERING (or map to new names)
   - Tune constants

---

## Part 5: Constants to Add

```gdscript
# CombatConstants.gd
const STAMINA_ENGAGE_MIN := 20.0
const ENGAGEMENT_COOLDOWN_BASE := 0.5
const ARMOR_BURDEN_FACTOR := 0.5
const ENGAGED_RECOVERY_MULT := 0.75
const ENGAGED_WINDUP_MULT := 0.85
const CLOSE_ATTEMPT_DURATION := 0.3
const FLURRY_BLOW_WINDUP := 0.25
const FLURRY_MAX_BLOWS := 4
const FLURRY_STAMINA_FLOOR := 15.0

# Distance band thresholds (for weapon reach)
const REACH_CLOSE_MAX := 1.2   # Dagger, sword, axe, mace
const REACH_MID_MIN := 1.2     # Spear at mid
const REACH_MID_MAX := 2.5
const REACH_LONG_MIN := 2.5    # Out of melee
```

---

## Part 6: Multi-Actor Scaling (15+ Creatures)

When many combatants fight at once, distance bands and engagement need rules to prevent bunching, distribute threats, and preserve physics-based accuracy.

### 6.1 Slot Limit Per Target (Prevent Bunching)

**Problem:** Without limits, all 15 could try to close on one target.

**Solution: Close-slot cap per defender**

```gdscript
# Per defender: max N attackers can be "close" at once
const CLOSE_SLOTS_PER_TARGET := 3  # Realistic: 2–3 can surround one

# When attacker attempts close:
#   - Count current close attackers: num_close = count(opponents where distance_to[defender] == "close")
#   - If num_close >= CLOSE_SLOTS_PER_TARGET: close fails → attacker stays at mid (or long)
#   - If slot free: resolve close roll as normal
#   - Slot priority: first-come (who closed first) or initiative (agility) — define tie-break
```

**Slot release:** When a close attacker dies, disengages, or is knocked back → slot opens. Next attacker attempting close can fill it.

**Alternative: Queue at mid**
- Excess attackers at "mid" (threatening, can attack with spear, or wait for slot). Dagger/sword at mid cannot melee; must wait or pick different target.
- AI: if preferred target has full slots, pick next-best target or "wait for slot."

---

### 6.2 Target Distribution (Positioning Abstraction)

**Problem:** AI and players need to spread out; no explicit positions.

**Option A: Implicit via slot limit**
- Slot limit naturally distributes: once target has 3 close, others must pick someone else.
- `get_available_actions` filters: "close on B" only valid if B has free slot.
- Works without any position data.

**Option B: Threat score / target weighting**
- Weight targets by "how many allies already on them": `weight *= 1.0 / (1 + num_allies_close_to_target)`
- Strongly prefer underutilized targets. Reduces bunching without slots.

**Option C: Formation rank (simple)**
- Each combatant has `rank: int` (0 = front, 1 = second, 2 = back).
- Only rank 0 can be "close" to enemy rank 0. Rank 1 can be close if rank 0 ahead is dead.
- Spear at rank 1 can attack from "mid" (reach over ally).
- Requires assigning ranks at combat start (by side, by agility, or by spawn order).

**Recommendation:** Start with **A** (slot limit). Add **B** (target weighting) to AI for smoother distribution. Defer **C** unless formation matters for gameplay.

---

### 6.3 Defense Splitting (Physics: Surrounded Defenders)

**Problem:** Defender facing 3 attackers has limited attention; parry capacity should reflect that.

**Solution: Parry capacity divided by imminent threats**

```gdscript
# When resolving defense for defender D against attacker A:
#   num_close_threats = count(opponents at "close" to D who have pending attack OR are in flurry with D)
#   Include A in count.

# Effective parry capacity:
#   parry_c_d_effective = parry_c_d_base / clamp(num_close_threats, 1, DEFENSE_SPLIT_MAX)
#   DEFENSE_SPLIT_MAX := 4  # Cap so 5+ doesn't trivialize
```

**Alternative: Sequential resolution with decay**
- First attack vs D: full parry capacity.
- Second attack in same "wave" (events within 0.2s): capacity × 0.6.
- Third: × 0.4.
- Reflects "already committed to first parry."

**Riposte / flurry:** Flurry remains 1v1. Only the primary engagement gets flurry. Other close attackers make "normal" attacks (no flurry, resolved in event order) — defender's capacity is split across them.

---

### 6.4 Pair-Wise Distance Scaling

**Storage:** For N combatants, pairs = N×(N-1)/2.  
- N=15 → 105 pairs. Store as `distance_bands[Vector2i(min_id, max_id)]` or `(id_a, id_b) -> band`.  
- N=50 → 1225 pairs. Still manageable.

**Update rules:** Only update pairs when:
- Someone closes (A–B: long→close)
- Someone disengages (A–B: close→mid)
- Someone dies (remove all pairs involving them)

**Sparse storage:** Many pairs stay "long" entire fight. Lazy init: assume "long" if not in dict; only store close/mid pairs. Reduces memory for large fights.

---

### 6.5 Physics-Based Accuracy With Many Actors

**Hit resolution:** Unchanged. AttackResolver still computes hit/parry/miss per attack. Each attack is resolved individually. What changes:

| Factor | Single target | Multi-target |
|--------|---------------|---------------|
| **Parry capacity** | Full | Divided by num_close_threats (see 6.3) |
| **Dodge** | Full | Could also split, or dodge is "move out of way" — less split than parry. Optional: dodge_chance /= sqrt(num_threats) |
| **Hit part** | Path + alignment | Same. AttackPathResolver unchanged. |
| **Friendly fire** | N/A | See 6.6 |

**Order of resolution:** Events resolve in timestamp order. If A and B both attack C in same tick, resolve first by event order (initiative tie-break). Each resolution uses current defender state (hp, stamina, guard) *before* the other hit lands. Or: resolve simultaneously (both hits apply) — your current design prefers sequential.

---

### 6.6 Obstruction and Friendly Fire (Optional)

**Obstruction (melee):** In real combat, ally between you and target can block your strike. Without 2D positions, approximate:

- **Rule:** If A attacks B, and C (same side as A) is also "close" to B, then P(obstructed) = f(num_allies_close_to_B). E.g. 1 ally: 5%; 2 allies: 15%. Roll: if obstructed, attack hits ally C instead (or misses).
- **Defer:** Adds complexity. Start without; add if melee clusters feel wrong.

**Ranged friendly fire (future):** When ranged exists, "between" check: if ally is on "line" from shooter to target, chance to hit ally. Requires topology (who is between whom). Abstract: if same side has multiple close to target, ranged hit has X% to hit ally. Defer until ranged implemented.

---

### 6.7 Summary: Multi-Actor Additions

| Addition | Purpose |
|----------|---------|
| **CLOSE_SLOTS_PER_TARGET (3)** | Prevent 15-on-1 bunching |
| **Slot check in close attempt** | Block close if target slots full |
| **get_available_actions filter** | Exclude "close on X" if X has no free slot |
| **AI target weighting** | Prefer targets with fewer allies |
| **parry_c_d / num_close_threats** | Surrounded defenders are overwhelmed |
| **Sparse distance storage** | Assume long if not stored; scale to 50+ |
| **Obstruction (defer)** | Optional friendly fire when allies in way |

---

## Part 7: Spear Lane Targeting (Deferred — Design Note)

**Implement later.** Different shields and formations should define which lanes spears can attack through. Lane type constrains which body parts the spear can target.

### Lane Types (Shield/Formation Design)

| Lane Type | Physical Path | Target Parts |
|-----------|---------------|--------------|
| **Over-shoulder** | Spear thrusts over rank 0's shoulder; path is high | Head, chest, arms only — **not legs** (blocked by bodies/shields) |
| **Open lane** | Gap between rank 0 soldiers; clear path through | **Full target access** — head, chest, arms, legs |

### Design Implications

- **Tight shield wall** (few gaps): Mostly over-shoulder lanes. Spear attacks restricted to upper body.
- **Open formation** (gaps between units): Open lanes. Spears can target anywhere — including low thrusts at legs.
- **Shield shape/size:** Large center-grip shields (round, kite) vs small bucklers affect gap size and thus lane type.
- **Formation presets:** E.g. "phalanx" = over-shoulder dominant; "loose skirmish" = open lanes dominant.

### Implementation Note

- `AttackPathResolver` / hit-part selection would receive `lane_type` or `allowed_parts` from the formation when resolving spear thrusts from rank 1.
- Defer until rows+files formation system is in place.

---

## Part 8: Formation + Surround / Multi-Angle (Investigation)

For row/file formation combat *and* units that surround or attack from multiple angles (packs, flanking groups), see:

**`docs/FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md`**

Covers: combining formation combat with surround/flanking, pack behavior, implementation tradeoffs, and alternatives.

---

## Part 9: References

- `docs/FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md` — formation + surround, flanking, pack behavior
- `docs/STAMINA_ENGAGEMENT_GATE_AND_DISTANCE_OPTIONS.md` — distance and gating options
- `docs/ENGAGEMENT_FLURRY_IMPLEMENTATION_OPTIONS.md` — flurry approaches
- `docs/ENGAGEMENT_ALTERNATIVE_PARADIGMS_AND_REFERENCE_SYSTEMS.md` — event queue, paradigms
- `combat/CombatManager.gd` — current gauge-based flow
- `combat/CombatStateHandlers.gd` — process_waiting, process_wind_up, process_recovering
