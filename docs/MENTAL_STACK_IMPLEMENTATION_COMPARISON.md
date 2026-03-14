# Mental Stack Implementation: Approaches vs. Industry Systems

A detailed comparison of proposed mental stack approaches against how real games and AI systems handle layered/priority-based decision-making, with recommendations for Fallen Paths.

---

## 1. Summary of Proposed Approaches (from MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md)

| Approach | Core Idea | Decision Flow |
|----------|-----------|---------------|
| **A. Layered Priority Stack** | Ordered stack; first satisfied condition wins | Scan top→bottom; first layer that applies drives choice |
| **B. Threat-Weighted Filtering** | Score options by threat/opportunity; prune low scorers | Continuous scoring; filter then weighted random |
| **C. FSM with Context** | Discrete mental states (NEUTRAL, DEFENSIVE, etc.) | State machine; each state has its own pick logic |
| **D. Yomi Layers** | Read opponent tendencies; counter-read | Adapt weights based on opponent history |
| **E. Heuristic Decision Tree** | Single if/else tree | Hard-coded condition→action branches |

---

## 2. Industry Systems: How Real Games Do It

### 2.1 Halo 2 / Bungie (GDC 2005)

**Architecture:** Hierarchical finite state machine / behavior DAG (~50 behaviors).

**Decision model:** **Prioritized-list** — march down a prioritized list of children; the first one that *can* run does. Higher-priority siblings can **interrupt** the current behavior on every tick.

**Relevancy:** **Binary** (can run / cannot run), not analog scores. Damian Isla noted that "tweaking floats to get a specific set of priorities is feasible when there are two or three choices, but when there are twenty or more it is almost impossible."

**Behavior impulses:** Free-floating triggers that reference full behaviors. Used when priority depends on context—e.g., "fight normally, *unless* player is in vehicle, then get in vehicle." Separates the *condition* from the *behavior*, placed at a specific point in the priority list.

**Key quote:** *"We think first of the best thing to do, but failing that we will consider the second best, the third best and so on. Whichever we choose, when a better option opens up, we immediately switch to it."*

**Design principles:** Explicitness over implicitness; hackability (impulses can run arbitrary code); take something that works and vary from it.

**Mapping to our approaches:**  
- **A (Layered Stack)** ≈ Halo's prioritized-list. Same idea: ordered list, first applicable wins, higher can interrupt.  
- **E (Heuristic Tree)** ≈ simplified version of Halo's tree without the DAG structure.

---

### 2.2 Guild Wars 2 / Infinite Axis Utility System (IAUS)

**Architecture:** Utility-based action selection. Each action has a **Decision Score** = geometric mean of consideration scores × weight.

**Flow:**
1. **Inputs** normalized to [0–1] (health 25/100 → 0.25, ammo 15/30 → 0.5, etc.)
2. **Considerations (axis):** Each action has 1+ considerations. Same input can mean different things per action (e.g., ammo=0 → Shoot scores 0, Reload scores 1)
3. **Response curves:** Logistic (threshold), Gaussian (sweet spot), Linear, Quadratic, Logit
4. **Combination:** Geometric mean (not naive multiply — avoids penalizing actions with many considerations)
5. **Weights:** 5 = emergency, 2–3 = important, 1 = normal. Emergency can override even when GM is lower.

**Example:** Retreat GM=0.4, Weight=5 → 2.0; Reload GM=0.9, Weight=1 → 0.9. Retreat wins despite lower GM.

**Design goals:** Data-driven; designers configure curves/weights without code; scales to hundreds of NPCs (MMO combat).

**Mapping to our approaches:**  
- **B (Threat-Weighted Filtering)** ≈ utility-lite. Scoring options, pruning, weighted choice. Full IAUS would add curves, geometric mean, and explicit weights.  
- Medical urgency in Fallen Paths already resembles a single consideration with an urgency curve.

---

### 2.3 The Sims (Needs-Based / Marginal Utility)

**Architecture:** Needs increment over time; each need has a **non-linear impact** on happiness. Pick action that yields the *greatest happiness increase* if taken.

**Flow:**
1. Needs: sleep, eat, social, etc. Each has a formula (e.g., `-eat_need²` for hunger impact)
2. For each possible action: compare current happiness impact vs. impact *after* doing the action
3. Choose action with largest marginal utility

**Key insight:** Marginal utility — first bites of food have high value, then diminishing returns. Same for sleep, toilet, etc. Non-linear curves prevent "eat constantly" or "never eat."

**Mapping to our approaches:**  
- **B (Threat-Weighted)** — same family. Continuous scoring; non-linear escalation. Sims uses "happiness deltas" rather than raw scores.  
- Medical urgency in Fallen Paths is analogous: bleeding urgency escalates non-linearly; pending_retry adds a spike.

---

### 2.4 Subsumption Architecture (Brooks, Robotics)

**Architecture:** Layered reactive control. **Higher layers subsume (suppress) lower layers** without stopping them. Bottom-up: obstacle avoidance runs always; wander runs when nothing else inhibits it; explore runs on top.

**Flow:** Parallel processes; each layer competes for control. External sensor input mediates priority. Lower layers = reflexes; higher = task-oriented.

**Mapping to our approaches:**  
- **A (Layered Stack)** — similar priority idea but inverted: subsumption = "higher inhibits lower"; our stack = "higher preempts lower." Same outcome: high-priority things win.  
- **C (FSM)** — subsumption is more parallel/reactive; FSM is sequential state transitions. Different philosophy.

---

### 2.5 Behavior Trees vs. FSM (General)

**Behavior Trees:**
- Modular; implicit transitions via parent control nodes
- Adding behaviors = add subtree; no need to rework transitions
- Depth-first traversal; naturally responsive to state changes
- Parallel nodes for concurrent tasks
- Scale better than FSM for complex combat (many states, many transitions)

**FSM:**
- Explicit transitions; risk of "spaghetti" and lock-in
- State explosion when many conditions affect many states
- Good for small, clear mode sets (e.g., 3–5 mental states)

**When to use which:** BTs for large, evolving behavior sets; FSM for a small number of distinct "modes" (e.g., NEUTRAL, DEFENSIVE, MEDICAL_PRIORITY).

**Mapping to our approaches:**  
- **C (FSM with Context)** — classic FSM. Viable if we keep states to ~5.  
- **A (Layered Stack)** — can be implemented *inside* a BT as a prioritized selector, or standalone.

---

## 3. Comparative Analysis

| Criterion | A. Layered Stack | B. Threat-Weighted | C. FSM | D. Yomi | E. Heuristic Tree |
|-----------|------------------|--------------------|--------|---------|---------------------|
| **Industry precedent** | Halo 2 (prioritized-list), subsumption | GW2 (IAUS), Sims (marginal utility) | Halo (HFSM), many games | Fighting games, MCTS/planning | Common in smaller games |
| **Fits Fallen Paths pipeline** | High — drop-in before pick_weighted | High — extends current weights | Medium — new state vars, transitions | Low — needs opponent memory | High — refactor of pick logic |
| **Tunability** | Add/remove/reorder layers | Add considerations, tune curves | Add states, transition rules | Add tendency trackers | Add branches |
| **Data-driven potential** | Low (order is code) | High (scores/curves configurable) | Medium (states configurable) | Medium (tendency params) | Low (code-bound) |
| **Debugging** | Easy (inspect stack, which layer fired) | Medium (inspect scores) | Easy (current state visible) | Hard (why did tendency change?) | Easy (trace branches) |
| **Gray-area handling** | Poor — binary layer match | Excellent — continuous scores | Medium — state boundaries | Good — gradual adaptation | Poor — binary branches |
| **Scalability** | Good — O(layers) | Good — O(actions × considerations) | Risky — state explosion | Medium — memory per opponent | Good for small trees |
| **Interrupt semantics** | Natural (higher wins) | Via score (emergency weight) | Via transition | N/A | Via condition order |

---

## 4. Fit for Fallen Paths

### Current System (CombatManager)

- **get_available_actions:** Returns flat list of {target_id, move_id, target_part}
- **pick_weighted_action:** Medical actions get urgency-based weight; attacks get weight 1.0. Weighted random selection.
- **Combat phase:** No parry as explicit action in combat phase (parry is when someone winds up on you — see PARRY_DESIGN_OPTIONS)
- **Medical phase:** Urgency, pending_retry, bleeding rate already drive weights

### Gaps

1. **Attacks are equal weight (1.0)** — no targeting intelligence (who to attack, which move)
2. **No "I'm being targeted" awareness** — defender doesn't weigh parry/defend differently
3. **No engagement awareness** — when engagement exists, no preference for engaged target
4. **Medical works well** — urgency and pending_retry already implement a form of prioritization

### What We Need

- A way to **prioritize** medical > defend (when targeted) > attack best target > default
- **Binary or near-binary** for hard overrides (e.g., "ally in peril → must help")
- **Scoring** for gray areas (e.g., which enemy to attack when several are valid)
- **Minimal refactor** — avoid rewriting get_available_actions or resolve_action

---

## 5. Option-by-Option Assessment

### A. Layered Priority Stack

**Verdict:** **Best fit** for Fallen Paths.

**Why:**
- Matches Halo 2's prioritized-list — industry-proven for combat
- Binary relevancy per layer avoids float tweaking (Halo's lesson)
- Natural interrupt: medical peril always beats attack; "being targeted" beats "pick target"
- Fits existing pipeline: layers can **filter** actions (e.g., layer 1 returns only medical) or **override** (e.g., layer 2 says "do parry")
- Easy to debug: log which layer fired

**Implementation sketch:**
```
Layers (order = priority):
  1. Ally in immediate peril + can help → restrict to medical, pick by urgency (existing)
  2. Enemy winding up on me + parry available → prefer parry (or restrict to parry+attack)
  3. Engaged + engagement actions available → prefer engaged target
  4. Attack options → score by opportunity (enemy in recovery, low health, etc.)
  5. Default → current equal-weight attack
```

**Risk:** Can feel rigid if layers are too coarse. Mitigate by allowing layer 4 to use continuous scoring (threat-weighted) for attack target selection.

---

### B. Threat-Weighted Option Filtering

**Verdict:** **Strong complement** to A, or alternative if you prefer full utility.

**Why:**
- Guild Wars 2 proves it scales; Sims proves marginal utility works
- Handles gray areas (which enemy? which move?) that layers treat clumsily
- Natural extension of current medical weighting — same pattern for attacks

**Drawback for Fallen Paths:**
- Need to design considerations for attacks: distance (N/A in turn-based?), enemy health, enemy state (recovering?), weapon matchup, engaged status
- Threshold tuning can be brittle ("why did it pick X when Y was clearly better?")
- Less explicit than layers for hard overrides — emergency weight 5 works but is less clear than "layer 1 always wins"

**Best use:** Implement **inside** layer 4 of the stacked approach — use utility scoring for "best attack target" while layers 1–3 handle overrides.

---

### C. FSM with Context

**Verdict:** **Viable but heavier** than stacked layers.

**Why:**
- Clean mental model: "I'm in DEFENSIVE mode, so I parry more"
- Integrates with engagement (ENGAGED state)

**Drawbacks:**
- Requires transition logic: when does DEFENSIVE → NEUTRAL? When wind-up ends? Tick delay?
- State explosion: NEUTRAL, DEFENSIVE, MEDICAL, ENGAGED, PRESSURING = 5 states. Add "ally threatened" and you need MEDICAL vs THREATENED_ALLY vs both?
- Transitions can feel abrupt ("I was attacking, now I'm defending" — need hysteresis?)
- More code than layers: each state has its own pick logic; transitions need maintenance

**When to use:** If you later add complex modes (e.g., "berserker" vs "cautious" personality) that affect many decisions, FSM is a good container. For initial mental stack, layers are simpler.

---

### D. Yomi Layers

**Verdict:** **Later phase**, not first implementation.

**Why:**
- Adds adaptation and mind-games
- Requires opponent action history and tendency estimates
- Current system has no feint/secondary-target mechanics — yomi would need something to "read" and "counter"

**When to add:** After layers (and optionally engagement) are in place. Use for: "opponent parries 60% of the time → weight feint higher" or "opponent targets my head → guard head." Needs data structures (per-opponent history) and possibly new actions (feint).

---

### E. Heuristic Decision Tree

**Verdict:** **Equivalent to A** with different expression.

**Why:**
- Same logic: if peril → medical; else if targeted → parry; else if engaged → X; else attack
- Tree = flattened stack. Stack = ordered list of (condition, action).
- Tree is more verbose (nested if/else); stack is more declarative (list of layers)

**When to use:** If you prefer a single function with explicit branches and don't want a layer registry. Functionally identical to A.

---

## 6. Recommended Implementation Path

### Phase 1: Layered Priority Stack (Approach A)

1. **Define layer registry** (array of `{condition: Callable, decision: Callable}`)
2. **Conditions:**
   - `ally_in_peril_and_can_help(combatant_id)` — existing `_is_in_immediate_peril` + can perform medical
   - `enemy_winding_up_on_me_and_can_parry(combatant_id)` — new `_is_being_targeted` + parry in actions
   - `engaged_and_has_engaged_actions(combatant_id)` — when engagement exists
   - `has_attack_options(combatant_id)` — always true in combat if can attack
3. **Decisions:**
   - Layer 1: restrict to medical, use existing `pick_weighted_action` on subset
   - Layer 2: prefer parry (or restrict to parry + attacks, weight parry high)
   - Layer 3: prefer attacking engaged target (when engagement added)
   - Layer 4: use threat/opportunity scoring for attacks (optionally B-style)
   - Layer 5: current equal-weight `pick_weighted_action`
4. **Entry point:** Replace direct `pick_weighted_action(actions, id)` with `decide_action_via_stack(actions, id)` that iterates layers and returns first match

**Effort:** ~1–2 days. New helpers: `_is_being_targeted`, `_get_mental_stack_layers`. Minimal changes to `_process` and `BattleScene`.

---

### Phase 2: Threat/Opportunity Scoring for Attack Selection (Approach B, inside Layer 4)

1. For each attack action, compute:
   - `enemy_in_recovery` → bonus
   - `enemy_low_health` → bonus (kill potential)
   - `enemy_engaged_with_me` → bonus or penalty (commit vs peel)
   - `pending_retry` / threatened ally → bonus to attack that enemy
2. Multiply into weight; use in weighted random
3. Add response curves if desired (e.g., logistic for "low health urgency")

**Effort:** ~1 day. Extends layer 4; no new architecture.

---

### Phase 3 (Optional): Yomi (Approach D)

1. Per-combatant or per-opponent-pair: store last N actions
2. Compute simple tendencies: parry_rate, target_preference (head vs body)
3. When picking attack: adjust weights by tendency (e.g., if parry_rate > 0.6, weight feint or secondary target)
4. Requires feint or equivalent action to be meaningful

**Effort:** ~2–3 days. New data structures, tuning.

---

## 7. Final Recommendation

**Implement Approach A (Layered Priority Stack) first**, with Layer 4 using Approach B (Threat-Weighted) for attack target selection.

**Rationale:**
- Halo 2's prioritized-list directly validates the layered approach for combat AI
- Binary layer conditions give clear overrides (medical > defend > attack) without float tuning
- Layer 4 can use Guild Wars 2–style considerations for "which enemy" without converting the whole system to full IAUS
- Fits Fallen Paths' existing pipeline: `get_available_actions` unchanged; `pick_weighted_action` becomes the fallback used by layers 4–5
- Debuggable and maintainable: add/remove/reorder layers without touching core resolution

**Avoid for now:** Full FSM (C) — more overhead than benefit at current scope. Full IAUS (B alone) — overkill when hard overrides (medical, parry) are better expressed as layers. Yomi (D) — add after core stack works and engagement exists.

---

## References

- GDC 2005: Damian Isla, "Handling Complexity in the Halo 2 AI"
- Game AI Pro 3, Ch. 13: "Choosing Effective Utility-Based Considerations" (Mike Lewis)
- Guild Wars 2 / IAUS: [Tono Game Consultants](https://tonogameconsultants.com/infinite-axis-utility-systems/)
- The Sims AI: [Itinerant Games](https://itinerantgames.tumblr.com/post/95195640138/decision-making-ai-in-the-sims)
- Subsumption: Brooks, "A Robust Layered Control System for a Mobile Robot"
- Behavior Trees vs FSM: Opsive, PeerDH, GameDev.net comparisons
- MENTAL_STACK_ENGAGEMENT_INVESTIGATION.md (this project)
