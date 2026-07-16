# Attention & Salience Research for Fallen Paths

Research on established attention/salience systems in game AI, with implementation patterns relevant to Fallen Paths' `CombatAttention` (telegraph weight 0.45 + peril weight 0.4 + counter weight 0.25 = max additive load 1.1, clamped to 1.0).

---

## 1. F.E.A.R. Alertness System

### Architecture
F.E.A.R.'s AI (Jeff Orkin, Monolith Productions) used a **GOAP** (Goal Oriented Action Planning) architecture with an implicit alertness model rather than explicit "alertness" levels:

- **Three-state FSM** (`GoTo`, `Animate`, `UseSmartObject`) — the FSM is extremely simple; GoAP decides *which* state to enter and *when*.
- **Alert propagation**: When one squad member spots the player, they issue a voice alert ("Contact! Left corridor!") which broadcasts the last-known position to all nearby squad members. Nearby enemies update their `last_known_player_position` and move toward it using A* pathfinding + GOAP replanning.
- **Squad coordination**: The spotting enemy doesn't just run at the player — they use suppressive fire goals while flanking teammates flank. This is emergent from each NPC independently planning against shared goal pools, not a central commander.

### What Makes It Special
- **Re-planning on invalidation**: When a plan step becomes invalid (e.g., target moved), the NPC re-evaluates and either finds alternate means or switches goals entirely. This creates the illusion of real-time threat assessment.
- **No explicit "alertness" counter**: Alertness is implicit in the goal-selection priority. A combatant with cover has a `seek_cover` goal; once safe, that goal de-prioritizes and `flank` or `suppress_fire` goals rise.

### Relevance to Fallen Paths
FP's approach is more explicit: `attention_load` is a scalar state, unlike FEAR's implicit model. FP gains transparency (UI can display it directly) but loses the emergent squad-level behavior that makes FEAR compelling. Consider whether squad members should **share threat observations** — if one combatant sees an incoming telegraph, nearby allies could get a reduced `attention_load` boost even without being targeted.

---

## 2. XCOM Targeting / Threat Assessment

### Enemy Prioritization Logic
XCOM enemies use a **weighted scoring system** for target selection when they have line of sight to multiple units:

```
threat_score = cover_rating * cover_weight
             + health_factor * health_weight  
             + position_factor * position_weight
             + class_threat * class_weight
```

Key mechanics:
- **Cover ratings**: 50% (partial) and 75% (good/full). Enemies prefer attacking targets in worse cover.
- **Prioritization order** (simplified): 
  1. Units with no/low cover take priority over well-coverred units
  2. Among equal cover, lowest HP is targeted first
  3. Grenades target clusters of 2+ units regardless of individual threat
  4. Heavy weapons prioritize highest-HP targets (to overcome armor)

### Implementation Pattern — Threat Bucketing
XCOM doesn't compute a single continuous score. Instead it uses **bucketed prioritization**:
1. Filter to valid targets (in range, in LOS)
2. Sort by cover tier (worst first)
3. Within each tier, sort by HP (lowest first)
4. Apply exception rules (grenades → clusters, heavy weapons → high armor)

### Relevance to Fallen Paths
FP's `attention_load` is a continuous scalar (0–1), not a discrete threat score for target selection. However, FP's **yomi system** (per-attacker memory tracking attack lines, move types, parry/deflect counts) already implements something analogous to XCOM's class-based weighting — just at the micro-combat level rather than squad-level targeting. Consider whether enemy AI should use `attention_load` not just for self-defense but also for **target selection among multiple friendly combatants** (i.e., which ally to focus fire).

---

## 3. Total War Battle Attention

### Scale Problem
Total War manages hundreds of unit entities simultaneously. The attention system uses:

- **Engagement radius**: Each unit has a "combat radius" around its current target. Units outside this radius don't register as threats. Within it, they're "engaged."
- **Attention cone / facing**: Units only attend to enemies within their forward-facing arc (typically 120–180 degrees). Enemies behind are ignored unless the unit turns.
- **Priority tiers**: Officers and standard-bearers have higher attention priority than regular infantry. Killing an officer causes nearby units' "morale" to drop, which cascades into routing behavior.

### Implementation Pattern — Spatial Partitioning + Priority Queues
```
for each enemy_unit:
    if distance > engagement_radius: continue
    if not in_facing_cone: continue
    
    base_threat = enemy_strength * (1 / max_distance)
    
    if is_officer: base_threat *= 2.0
    if nearby_allies_under_fire: base_threat *= 1.5
    
    add_to_attention_queue(enemy_unit, base_threat)

# Process top-N entries in attention queue
for entry in sorted(attention_queue, reverse=True)[:MAX_ATTENTION_TARGETS]:
    attend_to(entry.unit)
```

### Relevance to Fallen Paths
FP's combat is small-scale (typically 3–7 vs 1–3), so spatial partitioning isn't needed. But the **engagement radius** concept maps well: FP already has `DISTANCE_LONG`, `DISTANCE_MID` bands. Consider adding a hard "attention cutoff" distance below which threats are ignored entirely (e.g., an enemy 20+ meters away shouldn't generate any attention load for a melee-focused combatant).

---

## 4. Cognitive Load in Game AI — Comparison to FP's Design

### Established Approaches
Human factors engineering defines cognitive load using **Kahneman's capacity model**: attention is a finite resource that can be depleted by multiple concurrent tasks, with diminishing returns as load increases.

| Game/System | Model | Capacity Cap | Components |
|---|---|---|---|
| FP (current) | Linear additive | 1.0 | telegraph(0.45) + peril(0.40) + counter(0.25) |
| F.E.A.R. | Implicit/goal-based | N/A | No explicit load model |
| Rainbow Six: Vegas 2 | Scalar alertness | 1.0 | sight(0.6) + sound(0.3) + intel(0.4) — capped at 1.0, **diminishing returns via sqrt()** |
| Alien: Isolation (2014) | Stress meter | 1.0 | proximity_to_xenomorph(0.7) + audio_detection(0.5) + line_of_sight(0.8) — uses **exponential decay** back to idle |
| XCOM 2 | Threat value | N/A | Discrete scoring, not a load model |

### FP's Current Design — Strengths and Weaknesses

**Strength:**
- Clean, transparent, debuggable scalar
- UI can directly display `Load 65%` to the player
- Weights are game-design-tunable constants

**Weaknesses vs. established approaches:**
1. **No diminishing returns**: If telegraph (0.45) + peril (0.40) + counter (0.25) = 1.1, clamped to 1.0, then having all three active is only marginally worse than having two. The system doesn't model the *qualitative* difference between "moderately busy" and "completely overwhelmed."
2. **No decay**: `attention_load` appears to be recomputed each frame from current conditions with no memory of past load. In human factors, cognitive overload has a **recovery curve** — after being at high load for 3 seconds, it takes time to recover even when stimuli stop.
3. **Single scalar for multi-dimensional stress**: Telegraph (future threat), peril (present danger to ally), and counter (opportunity) are qualitatively different types of cognitive demand. A single additive model treats them as interchangeable, but in practice, switching between defensive attention (peril) and offensive opportunity (counter) has a higher "switching cost" than two defensive stresses simultaneously.

### Recommended Improvements Beyond Linear Addition

**A. Non-linear aggregation (square root / power law)**
```gdscript
# Instead of: load = t + p + c
# Use:
load = pow(t, 0.7) + pow(p, 0.7) + pow(c, 0.7)  # sub-additive
load = clamp(load, 0.0, 1.0)
```
This models diminishing returns — the first stressor matters most, additional ones add less. This is closer to how human attention actually works (Kahneman 1973).

**B. Temporal decay / recovery curve**
```gdscript
# After stimuli cease, load decays exponentially:
attention_load = max(0.0, attention_load - decay_rate * delta)
decay_rate = 0.3  # seconds to recover ~63% of load
```

**C. Type-based switching cost**
When `attention_load` transitions from a state dominated by one type (e.g., peril = defending an ally) to another (e.g., counter = offensive opportunity), apply an additional penalty:
```gdscript
if prev_dominant_type != current_dominant_type:
    attention_load += SWITCHING_PENALTY  # e.g., 0.15
```

---

## 5. Threat Assessment Models — Common Formulas

### Base Threat Formula (from military operations research, adapted for games)
```
threat_value = (damage_potential * accuracy) / (distance + constant) * situational_modifier
```

### Simplified Game Version (used in many RTS/TBS games)
```
threat = weapon_damage * (1.0 / max(distance, 1.0)) * hp_factor * recency_bonus
```

Where:
- `hp_factor = remaining_hp / max_hp` (lower HP = higher threat as they're closer to death)
- `recency_bonus` increases if this enemy has acted against you recently

### FP's Existing Threat Model
FP doesn't use a single "threat value" for target selection in the conventional sense. Instead, threat is distributed across:
- **Yomi memory**: Per-attacker tracking of attack patterns, parry/deflect history
- **Attention load**: Per-combatant scalar for self-directed attention allocation
- **Mental stack layers**: Hierarchical decision-making (self-medical > ally medical > counter > incoming > hold_line)

### Recommended Addition — Cross-Combatant Threat Ranking
For AI targeting decisions (which enemy to attack), consider adding a lightweight threat score:
```gdscript
func compute_threat_value(self_id, target_id, manager):
    var dist = get_distance(self_id, target_id)
    var target_hp = get_combatant(target_id).health / max_health
    var yomi_aggression = get_yomi_entry(target_id).line_counts  # aggressive attack patterns
    var recent_dmg = get_recent_damage_dealt_to_me(target_id)
    
    return (recent_dmg * 2.0 + yomi_aggression * 1.5) / max(dist, 1.0) * (1.0 - target_hp * 0.3)
```

This is distinct from `attention_load` — it's for **offensive targeting** while attention load is for **defensive self-management**.

---

## 6. Alertness State Machines — Preventing Alert Spam

### Pattern: Hysteresis with Damping
The standard approach to prevent "alert spam" (rapidly flipping between Idle → Suspicious → Alert → Combat) is **hysteresis** — different thresholds for entering vs. leaving each state:

```
Idle → Suspicious:  sight_quality > 0.3 AND duration > 1.0s
Suspicious → Alert:   sight_quality > 0.7 OR auditory_sight > 0.8
Alert → Combat:       direct_line_of_sight AND hostile_action
Combat → Alert:       lost_LOS for > 2.0s
Alert → Suspicious:   last_known_pos older than 3.0s
Suspicious → Idle:    no stimuli for > 5.0s AND duration_in_state > 1.0s
```

### Pattern: State Duration Minimums
Once entering a state, remain there for a minimum duration regardless of input changes:
```gdscript
if current_state == SUSPICIOUS and time_in_state < SUSPICIOUS_MIN_DURATION:
    return  # ignore higher-intensity stimuli until minimum elapsed
```

### Pattern: Stimulus Decay
Sensory inputs decay over time, so brief flashes don't permanently elevate alertness:
```gdscript
sight_saliency *= exp(-sight_decay * delta)
audio_saliency *= exp(-audio_decay * delta)
overall_alertness = max(sight_saliency, audio_saliency, stored_intel)
```

### FP's Current State Machine
FP uses **mental stack layers** as a kind of alertness FSM:
- `self_medical` (highest priority — immediate self-preservation)
- `medical` (ally in peril)
- `counter` (offensive opportunity)
- `incoming` (defensive reaction to telegraph)
- `hold_line` (baseline posture)

This is a **layered** rather than linear state machine, which is more sophisticated. The layer system naturally prevents alert spam because higher layers *override* lower ones — you can't be in "counter" mode while also being asked to hold line.

### Gap: No State Duration / Transition Damping
FP's mental stack has no concept of minimum time spent in a layer, or decay of "recently experienced" states. If an incoming telegraph appears and disappears within one tick, the combatant still transitions through `incoming` → `hold_line`. Consider adding a **grace period** after high-priority events where lower-priority decisions are suppressed:
```gdscript
if time_since_last_high_priority_event < GRACE_PERIOD:
    if new_event.priority <= last_event.priority:
        return  # ignore, still in grace period
```

---

## 7. Multi-Threat Attention Splitting

### Additive vs. Diminishing Returns

**Additive model** (FP's current approach):
- Each threat adds its weight independently
- Two threats at 0.45 each = 0.90 load
- Problem: doesn't capture the qualitative difference between "distracted" and "overwhelmed"

**Diminishing returns model** (recommended):
```gdscript
# Power law aggregation — models attention as a shared pool
var raw_load = pow(telegraph_w, 0.7) + pow(peril_w, 0.7) + pow(counter_w, 0.7)
attention_load = clamp(raw_load, 0.0, 1.0)
```

With FP's weights:
- Telegraph only: `pow(0.45, 0.7) ≈ 0.586` → load 59%
- Telegraph + Peril: `0.586 + 0.523 = 1.109` → clamped to 100%
- All three: `0.586 + 0.523 + 0.346 = 1.455` → still 100%

The key insight: **two threats should feel like a fundamentally different state than one**, and the power law makes this more pronounced. With linear addition, telegraph(0.45) + peril(0.40) = 0.85, but all three = 1.1 → clamped to 1.0. The system can't distinguish "two things happening" from "three things happening."

**Saturation model** (used in some tactical simulators):
```gdscript
# Each additional threat has a multiplicative reduction
var base_load = telegraph_w + peril_w + counter_w
attention_load = 1.0 - pow(1.0 - base_load, num_active_threats)
```

### Type-Weighted Splitting (Advanced Pattern)
Different threat types should not be equally distributed across attention capacity. In FP's case:

| Threat Type | Cognitive Demand | Recommended Weighting |
|---|---|---|
| Telegraph (anticipating attack) | Predictive — can prepare response | 0.45 (high, because it demands focus commitment) |
| Peril (ally bleeding out) | Reactive — time-critical but well-defined | 0.40 (high, because medical actions are deterministic) |
| Counter (opportunity to strike) | Prospective — requires reading timing | 0.25 (lower, because it's an *option* not a demand) |

This weighting is actually reasonable as-is: telegraph and peril are **demands** (you must respond), while counter is an **opportunity** (you can exploit if load permits). The current design implicitly treats counter as "bonus attention" rather than competing demand, which is correct.

### Recommended: Dominant Threat Identification
Beyond computing total load, identify the **dominant threat type**:
```gdscript
func get_dominant_threat_type(attention_load) -> String:
    if peril_w >= telegraph_w and peril_w >= counter_w:
        return "peril"  # defending ally is primary concern
    elif telegraph_w >= counter_w:
        return "telegraph"  # incoming attack is primary concern
    else:
        return "counter"  # offensive opportunity dominates
```

This enables **context-sensitive behavior**: when dominant threat is "peril," the AI should prefer medical/coordinated actions; when it's "telegraph," prefer defensive focus/guard moves. FP already does something like this via mental stack layer priority, but making the dominant type explicit could improve UI hints and decision transparency.

---

## Summary: Recommended Changes to FP's Attention System

1. **Non-linear aggregation**: Replace linear addition with power-law (`x^0.7`) to create sharper transitions between "manageable" and "overwhelmed" states.

2. **Temporal decay**: Add exponential recovery curve so attention load doesn't instantly vanish when stimuli disappear. This prevents the "blink and you miss it" problem where a single-frame telegraph generates load that clears on the next tick.

3. **State grace periods**: After transitioning to a high-priority mental stack layer, suppress lower-priority decisions for 1–2 ticks even if the triggering condition resolves.

4. **Attention cutoff distance**: Ignore threats beyond engagement range entirely (not just reduced weight). A combatant in melee shouldn't be distracted by distant enemies.

5. **Dominant threat tracking**: Explicitly identify and expose which threat type is primary, not just total load. This improves both AI behavior routing and UI feedback.

6. **Type-switching penalty**: When attention load shifts from one dominant type to another (e.g., peril → counter), apply a small additional penalty to model the cognitive cost of context switching.

7. **Cross-combatant threat sharing**: Allow nearby allies to inherit partial attention load when they observe an event that would have affected the spotting combatant (squad awareness). This bridges FP's individual-level system toward FEAR-style emergent squad behavior.
