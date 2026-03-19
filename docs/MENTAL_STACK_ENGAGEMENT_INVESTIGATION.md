# Mental Stack AI & Engagement System Investigation

An investigation into (1) fighting-game-style mental stack decision-making for AI, and (2) an engagement/flurry system where units become locked in exchanges before returning to neutral.

---

## Part 1: Mental Stack AI Decision-Making

### What Is "Mental Stack" (Fighting Games)

The **mental stack** is the cognitive load a player must manage during a match—all the options, threats, and decisions that must be tracked simultaneously. Pro players (e.g., Daigo, Tokido, Fuudo) describe it as:

- **Prioritization:** Focus on the most critical threats and opportunities, not everything at once
- **Automation:** Fundamentals (anti-air, basic punishes) become automatic, freeing mental capacity for higher-level decisions
- **Matchup knowledge:** Knowing opponent options narrows what to consider
- **Stress response:** Tournament pressure or unfamiliar situations can cause mental overwhelm ("mind went blank")
- **Defense vs offense:** Stronger defense lowers mental stack; oppressive offense (e.g., Street Fighter 5) increases it

For AI, this translates to: **model which options matter most at any moment, and let lower-priority decisions be cheap or automatic.**

---

### Implementation Approaches

#### A. Layered Priority Stack (Explicit Mental Stack)

**Idea:** Maintain an ordered stack of "what I'm thinking about right now." Top of stack = highest priority decision. Lower items are only considered when higher ones are satisfied or irrelevant.

```
Stack (top = highest priority):
  1. "Ally in immediate peril" → must treat or hold pressure
  2. "I'm being targeted by wind-up" → parry/defend vs counter
  3. "Engaged opponent attacking me" → respond in exchange
  4. "Threatened ally" → peel or finish enemy
  5. "Best target to attack" → pick from available enemies
  6. "Default" → attack nearest / first available
```

**Implementation:**

- Each layer has a **condition** (when it applies) and a **decision function** (what to do)
- When it's the unit's turn, scan from top to bottom; first satisfied condition drives the choice
- Layers can "consume" mental capacity (e.g., "engaging" uses 2 of 3 stack slots)

**Pros:** Directly models pro-player prioritization; easy to debug (inspect stack); tunable depth  
**Cons:** Needs good condition design; can feel rigid if layers are too coarse

---

#### B. Threat-Weighted Option Filtering

**Idea:** Don't use an explicit stack. Instead, assign a **threat score** and **opportunity score** to each option. Options below a threshold are pruned before decision-making.

```
For each potential action:
  threat_urgency = f(who_is_attacking_me, ally_bleeding, who_i_am_attacking)
  opportunity_value = f(kill_potential, part_exposure, weapon_matchup)
  if threat_urgency > THRESHOLD: consider defensive/medical first
  else: pick from options weighted by opportunity_value
```

**Implementation:**

- `get_available_actions` returns all options; a new `filter_and_rank_actions(actions, combatant_id)` applies threat/opportunity scoring
- Medical urgency already exists; extend to "I am being wind-up targeted" (high threat) and "enemy in recovery" (high opportunity)
- Prune bottom 50% of options by combined score before `pick_weighted_action`

**Pros:** Fits current `pick_weighted_action` pipeline; continuous rather than discrete layers  
**Cons:** Threshold tuning; less explicit "mental stack" semantics

---

#### C. Finite State Machine with Context

**Idea:** FSM states map to "what mode is my mind in." Each state has different decision logic. Transitions are driven by game state (e.g., "ally hurt" → MEDICAL_PRIORITY, "enemy winding up on me" → DEFENSIVE_PRIORITY).

States (examples):

- `NEUTRAL` — pick best attack target, or medical if urgent
- `DEFENSIVE` — parry-weighted when someone winding up on me
- `MEDICAL_PRIORITY` — self or ally in peril
- `ENGAGED` — in flurry; respond to exchange (see Part 2)
- `PRESSURING` — I just hit; consider follow-up vs reset

**Implementation:**

- Add `mental_state` (or `ai_mode`) to combatant dict
- Each state has its own `get_actions_for_state` / `pick_action_for_state`
- Transition logic in `_process` or when `action_resolved` fires

**Pros:** Familiar pattern; integrates cleanly with engagement (ENGAGED state)  
**Cons:** State explosion if too many modes; transitions can feel abrupt

---

#### D. Yomi Layers (Read/Counter-Read)

**Idea:** Fighting game "yomi" = reading what the opponent will do and choosing counters. Model this as explicit layers: "I think they will X, so I do Y."

- **Layer 0:** Default (attack, or defend if obvious threat)
- **Layer 1:** "They often parry when I attack" → feint / change target / delay
- **Layer 2:** "They expect my feint" → commit to real attack

**Implementation:**

- Store per-opponent or per-matchup **tendency** (e.g., `opponent_parry_rate`, `opponent_target_preference`)
- When choosing attack: if `opponent_parry_rate > 0.6`, weight feint or secondary target higher
- Simple memory: last N actions per opponent; Bayesian-style update of tendencies

**Pros:** Captures mind-games; makes AI feel adaptive  
**Cons:** Needs enough data per opponent; can feel random if tendencies are noisy

---

#### E. Heuristic Decision Tree (Fast, No Learning)

**Idea:** Single decision tree with clear branches. Each node checks a condition and either picks an action or recurses.

```
if ally_in_immediate_peril and can_help: → medical
else if enemy_winding_up_on_me and gauge_full: → parry or counter
else if engaged_with_opponent: → exchange_action
else if enemy_in_recovery: → attack_that_enemy
else: → pick_from(attack_targets)
```

**Implementation:**

- Refactor `pick_weighted_action` into a `decide_action(combatant_id)` that returns a single action
- Inner logic uses existing `_is_in_immediate_peril`, `get_available_actions`, and new helpers like `_is_being_targeted(combatant_id)`, `_is_engaged(combatant_id)`

**Pros:** Simple, fast, debuggable; matches "narrow to what matters"  
**Cons:** Can feel predictable; no adaptation

---

### Recommendation for Fallen Paths

**Short term:** Combine **A (Layered Stack)** with **E (Heuristic Tree)**. Implement a small stack (3–5 layers) with conditions that map to current systems:

1. Medical peril (existing urgency)
2. "Enemy winding up on me" (parry weighting—already have parry as action)
3. Engagement response (when engagement exists—Part 2)
4. Best attack target (threat/opportunity scoring)
5. Default (current behavior)

**Medium term:** Add **D (Yomi)** by tracking opponent action history and tuning weights (e.g., parry more vs opponents who attack predictably).

---

## Part 2: Engagement & Flurry System

### Concept

When a unit **attacks** someone, they become **engaged** with that target. While engaged:

- Attacks can be exchanged in a **flurry** — multiple blows in quick succession
- The exchange continues until a **disengagement condition** (one side retreats, both recover, hit/miss/parry creates reset)
- After disengagement, both return to **neutral** (normal gauge, normal turns)

This mirrors HEMA "binding" or "corps-à-corps" — close-quarters exchange where both parties are committed.

---

### Design Options

#### Option 1: Engagement = Soft Lock (Target Preference Only)

**Idea:** "Engagement" is just a flag: `engaged_with_id`. No mechanical change. AI and display treat engaged pair as "in a duel." Flurry is cosmetic (animations suggest exchange) but mechanically it's the same 1-attack-per-wind-up.

- On attack → `attacker.engaged_with_id = target_id`, `target.engaged_with_id = attacker_id`
- Clear when: target dies, attacker chooses new target, or after N seconds
- `pick_weighted_action` weights attacking engaged target higher (or lower, for "break off" behavior)

**Pros:** Minimal code; easy to add  
**Cons:** No actual flurry; engagement is flavor only

---

#### Option 2: Engagement Enables Counter Window

**Idea:** When A attacks B, B gets a **counter window** — if B's gauge is ready (or partially ready) during A's wind-up or recovery, B can immediately counter with a reduced-cost or guaranteed-order attack.

- Engagement formed when A begins wind-up on B
- During A's wind-up or early recovery, B gets `can_counter = true`
- Counter consumes less gauge (e.g., 50%) or uses a "counter" action type
- After counter (or if B doesn't counter), both enter recovery; engagement ends

**Pros:** Adds real tactical depth; rewards reading the opponent  
**Cons:** Order of operations (who counters whom) needs careful design; can favor defender

---

#### Option 3: Flurry Sub-Phase (Multiple Exchanges)

**Idea:** When A attacks B, instead of one attack→result→recovery, enter a **flurry phase**. Both A and B exchange blows in quick succession (e.g., 2–4 attacks total) before returning to normal turns.

**Flow:**

1. A attacks B → engagement starts
2. Flurry phase begins:
   - Resolve A's attack (hit/parry/miss/dodge)
   - If B alive and can respond: B gets **instant** counter (or at reduced wind-up)
   - Resolve B's counter
   - If A alive and can respond: A gets instant counter
   - … repeat until max flurry length (e.g., 4) or disengagement condition
3. Disengagement: both go to recovery; gauge reset as normal

**Disengagement conditions:**

- One combatant dies
- One combatant is "broken" or stunned (e.g., hard hit, parry break)
- Max flurry length reached
- One side "retreats" (new action: break engagement, costs gauge or adds recovery)

**Pros:** Dramatic "clash" feel; rewards commitment  
**Cons:** Complex ordering; can make combat feel bursty; need rules for 2v1 (who gets countered)

---

#### Option 4: Binding / Corps-à-Corps (HEMA-Inspired)

**Idea:** Weapons "bind" on parry or deflected hit. While bound, both are in close range; next action is a **bind resolution** (push, cut, thrust from bind) rather than a full swing.

- On parry_deflect or certain deflected outcomes → `bound_with_id`, `bound_until` timestamp
- While bound: only "bind resolution" moves available (short thrust, push, disarm attempt)
- Bind resolution has different damage/risk profile
- After resolution or timeout: back to normal

**Pros:** Very HEMA-flavored; distinct mechanical phase  
**Cons:** Requires new move types and UI; may slow pace

---

#### Option 5: Engagement as "Combat Pair" With Shared Timeline

**Idea:** Engaged pairs share a **micro-timeline**. Instead of global gauge fill, the pair has a shared "exchange meter" that fills during the flurry. When it maxes, both disengage and return to global turn order.

- Engagement: (A, B) pair
- Each blow in the flurry adds to exchange_meter
- Exchange resolves as in Option 3, but disengagement is driven by meter + conditions
- Non-engaged units continue normal gauge fill; they can "interrupt" by attacking someone in a flurry (target gets hit, flurry ends?)

**Pros:** Clear phase boundaries; allows external interruption  
**Cons:** Two overlapping time systems (global gauge + exchange meter)

---

### Recommendation for Fallen Paths

**Phase 1:** Implement **Option 1 (Soft Lock)** to add engagement tracking and AI preference. Low risk, immediate value for "who is dueling whom" display and AI.

**Phase 2:** Add **Option 2 (Counter Window)**. When B is engaged and A is in wind-up, B can spend partial gauge for a counter. This creates real engagement payoff without full flurry complexity.

**Phase 3 (if desired):** Experiment with **Option 3 (Flurry Sub-Phase)** for a single engagement type (e.g., when both have full gauge and one attacks). Cap at 2–3 exchanges initially to avoid runaway chains.

---

## Integration With Current System

### Current State (from codebase)

- **CombatManager:** Gauge-based readiness; states `WAITING`, `WIND_UP`, `RECOVERING`, etc.
- **pick_weighted_action:** Medical by urgency; attacks equal weight (1.0)
- **get_available_actions:** Attack options = (move_id, target_id) for each weapon move and each enemy
- **Parry:** Active choice when someone winding up (or passive per PARRY_SYSTEM_OPTIONS)

### Hooks for Mental Stack

1. **`_is_being_targeted(combatant_id)`** — check if any enemy has `pending_attack.target_id == combatant_id`
2. **`_get_mental_stack(combatant_id)`** — return ordered list of (condition, decision_fn) for current state
3. **Refactor `pick_weighted_action`** — first run stack; if a layer returns an action, use it; else fall through to current weighted pick

### Hooks for Engagement

1. **Combatant dict:** Add `engaged_with_id: int = -1`
2. **`_begin_attack_with_target`** — set `attacker.engaged_with_id = target_id`, `target.engaged_with_id = attacker_id`
3. **After `action_resolved`** — optionally clear engagement (e.g., on miss, dodge, or deflected) or maintain for counter window
4. **`get_available_actions`** — when engaged, could add "break engagement" or prioritize engaged target
5. **Flurry (Option 3):** New state `STATE_IN_FLURRY`; `_process` handles flurry sequence instead of single attack resolution

---

## References

- Daigo, Tokido, Fuudo on mental stack: [EventHubs](https://www.eventhubs.com/news/2021/apr/11/daigo-tokido-mental-information/)
- Fighting game AI (heuristics, FSM): [William Thyer](https://williamthyer.github.io/posts/2022/1/heuristic_ai/)
- Killer Instinct Shadow AI: [Game Developer](https://www.gamedeveloper.com/programming/the-killer-groove-the-shadow-ai-of-killer-instinct)
- Fire Emblem Engage Break: weapon triangle, counter prevention
- NWN2 Flurry: 2-second combat units, attacks per flurry
- Yomi: [Smogon "Yomi and You"](https://www.smogon.com/forums/threads/yomi-and-you.11746/) (read/counter-read)
- Current code: `CombatManager.gd`, `AttackResolver.gd`, `BattleScene.gd`, `PARRY_SYSTEM_OPTIONS.md`
