# Engagement & Stamina System: Alternative Paradigms and Reference Systems

Investigation of implementation approaches you may not have considered, radically different design paradigms, and what detail-focused systems similar to Fallen Paths actually use.

---

## Part 1: Approaches You May Have Missed

### 1.1 Event Queue / Timeline (No Gauge, No Discrete Turns)

**Idea:** Instead of "who is ready to act," all combatants sit on a shared **event queue** or **timeline**. Each action has a duration; when you act, you schedule yourself for `now + action_duration`. The next event is whoever's timestamp comes up.

- **Engagement:** "Engage" is an event. When A's "engage B" fires, it creates a sub-queue: A and B alternate blows until disengagement. Each blow has its own duration (wind-up + recovery).
- **Gate:** No gauge. You're on the queue with a timestamp. When your timestamp is reached, you pick an action (engage, wait, medical) and reschedule.
- **Stamina:** Stamina drains per action. Below threshold → can't engage (only wait/retreat). Refills over real time.

**Pros:** Natural for flurries (both in sub-queue); no artificial "whose turn."  
**Cons:** Scheduling logic; edge cases when multiple events fire "simultaneously" (initiative rules needed).

**Reference:** Iron Storm, Dwarf Fortress (flow-based ticks), Winter's Saga.

---

### 1.2 Simultaneous Declaration (Scripted, Both Reveal)

**Idea:** Both sides declare intentions secretly, then resolve together. No turn order—both "act" in the same moment.

- **Engagement:** A and B both declare: "engage," "attack," "retreat," "parry." Resolution: if both attack → mutual hit or priority by stats; if one retreats and one engages → chase roll; if both parry → standoff.
- **Gate:** No gauge. Declaration happens on a **beat** (every N seconds, or when both have chosen). Stamina gates whether you *can* declare certain actions (e.g. engage requires stamina ≥ X).
- **Flurry:** Once engaged, beats shorten—both declare next blow. Continues until one disengages or stamina fails.

**Pros:** Tense; no "I go, you go" predictability.  
**Cons:** Hard to implement in single-player vs AI (AI must "declare" in code); player experience is "choose blindly."

**Reference:** Riddle of Steel (stance + intent), Burning Wheel Fight! (scripted volleys), Odd ReDuel.

---

### 1.3 Beat / Pulse (Fixed Intervals, Anyone Can Act)

**Idea:** Combat runs on a **global pulse** (e.g. every 0.5 s). On each pulse, *everyone* who meets conditions can act. No turn order—all eligible actors resolve in initiative order (stats) or simultaneously.

- **Engagement:** On pulse N, A has stamina ≥ min → A declares "engage B." B has stamina ≥ min → B declares "attack A" or "retreat." Resolution order: by initiative or by engagement (engaged pair resolves first).
- **Gate:** Pulse + stamina. If stamina below floor, you sit out that pulse.
- **Flurry:** Engaged pair gets a **micro-pulse**—faster beat (0.2 s) until disengage. Only A and B act on micro-pulse; others wait.

**Pros:** Predictable pacing; everyone "acts" on the same clock.  
**Cons:** Many actors = many declarations per pulse; can get busy.

**Reference:** Exanima (physics ticks but similar "everyone evaluates"), Mordhau (real-time but stamina gates actions).

---

### 1.4 Card / Hand-Based Actions

**Idea:** Each combatant has a **hand** of action cards. Playing a card = performing that action. Hand refills from a deck; deck composition = available options (attack types, parry, disengage, etc.).

- **Engagement:** "Engage" card played on target. Target can play "Accept" (engagement forms) or "Retreat" (contest: evade vs pursue). Once engaged, both draw from **exchange deck** (riposte, bind, cut, thrust, etc.)—smaller, faster deck.
- **Gate:** No gauge. You can always play a card if you have one. Stamina: playing cards costs stamina; when deck runs out or stamina low, you get "exhausted" cards (weaker) or must pass.
- **Disengage:** Play "Break" card; contest vs opponent's "Hold" or let them go.

**Pros:** Tactical hand management; variety from deck composition; "flurry" = exchange deck.  
**Cons:** Content-heavy (many cards); randomness can frustrate; different feel from simulation.

**Reference:** BATTLECARDS, Iron Storm, some tactical board games.

---

### 1.5 Priority / Initiative Auction

**Idea:** Each "round" or "beat," combatants **bid** for initiative using stamina (or a resource). Highest bidder acts first; bid is spent. Remaining actors resolve in order of bid.

- **Engagement:** Acting first, you can "engage" a target. They're locked until they spend to disengage or win a roll. Flurry: once engaged, initiative within the pair is by bid or alternating (first attacker, then defender ripostes).
- **Gate:** Must have resource to bid. Low stamina = low bids = often go last.  
**Pros:** Interesting trade-off: bid high to act first, or conserve.  
**Cons:** Can feel gamey; "auction" may not suit simulation tone.

---

### 1.6 Cooldown-Per-Action (No Global Gauge)

**Idea:** Each action type has its own **cooldown**. "Attack" cools for 2 s; "Engage" for 1 s; "Parry" is reactive (no cooldown). You can perform any action whose cooldown has elapsed. Multiple cooldowns run in parallel.

- **Engagement:** "Engage" off cooldown → attempt engagement. Success = both enter flurry (attack cooldowns shorten or bypass for engaged pair). Disengage = "Break" action, cooldown 0.5 s.
- **Gate:** Per-action cooldown. Stamina: each action also costs stamina; below floor, some actions unavailable.
- **Agility/armor:** Agility shortens cooldowns; armor lengthens them.

**Pros:** Granular; different actions have different recovery.  
**Cons:** Many timers to track; UI complexity.

**Reference:** MOBAs (per-ability cooldowns); Mordhau (attack cooldown by weapon).

---

### 1.7 State Machine With Interrupts (Reactive, Not Proactive)

**Idea:** Combatants are always in a state. Transitions happen when **events** fire: "attacked," "parried," "stamina low," "ally down." No one "chooses" to act on a schedule—they **react** when events occur.

- **Engagement:** State = "idle" | "engaged_with_X" | "recovering" | "winding_up." Event "attacked by B" → if idle and stamina OK, transition to "engaged_with_B" and queue riposte. Event "parry_success" → transition to "riposte_window" (can attack in 0.3 s). Event "stamina_below_20" → transition to "exhausted" (can only retreat).
- **Gate:** Event-driven. You act when something happens to you, not when a bar fills.
- **Flurry:** "Engaged" state has substates: blow 1, blow 2, … Each blow triggers "resolved" event → next blow or disengage.

**Pros:** Very reactive; fits "read and respond" HEMA feel.  
**Cons:** Can feel passive ("I'm waiting for something to happen"); needs careful event design to avoid deadlock.

**Reference:** The Last of Us Part II (behaviors with enter/exit conditions), Observer pattern (Dwarf Fortress).

---

## Part 2: Radically Different Paradigms

### 2.1 Inverted Control: Defender Drives the Flow

**Current (and most games):** Attacker initiates. Defender reacts (parry, dodge).

**Inverted:** Defender's state determines when exchanges happen. "I'm open" = attacker gets a window. "I'm guarded" = attacker can't safely engage. Defender chooses when to present an opening (commit to attack, shift guard, etc.).

- **Engagement:** Attacker can only engage when defender has an "opening." Defender creates openings by attacking (commits) or by design (feint to draw). Stamina: defender with low stamina creates more openings (can't hold guard); attacker with low stamina can't exploit.
- **Gate:** No gauge. Flow is "defender presents opening → attacker may engage."  
**Pros:** Puts defender in narrative driver seat; reward for patience.  
**Cons:** Counterintuitive; attacker may feel passive.

**Reference:** Some fencing theory (invitation, second intention); less common in games.

---

### 2.2 Narrative Beats (Story Points, Not Simulation)

**Idea:** Combat is structured as **narrative beats**: Setup, Complication, Crisis, Climax, Resolution. Each beat has different rules. "Engagement" is a beat; "flurry" is a sub-beat.

- **Gate:** Story progression. "Can I engage?" = "Are we in the Engagement beat?" Beats advance by events (hit, parry, stamina threshold, round count).
- **Stamina:** Consumed per beat; when depleted, forced to Resolution beat (disengage, flee, or collapse).

**Pros:** Cinematic; easy to tune "how long should a fight feel."  
**Cons:** Less simulation; may not fit your physics-focused design.

---

### 2.3 Probabilistic State (Markov / Outcomes)

**Idea:** No explicit "I choose to engage." Each tick, the system rolls transitions: P(idle → engaged | stamina, proximity, agi, …). Outcomes emerge from probability, not player/AI choice.

- **Engagement:** P(engage | A.stamina, B.stamina, A.agi, B.armor, …). If roll succeeds, engagement forms. Flurry length = sample from distribution based on stamina, weapon speed.
- **Gate:** Implicit in transition probabilities.  
**Pros:** Emergent; can feel organic.  
**Cons:** Less agency; hard to tune; may feel random.

---

### 2.4 "Measure" as Primary Resource

**Idea:** HEMA "measure" (distance) isn't derived from stats—it **is** the resource. You spend measure to attack (close); you gain measure by deflecting or retreating. Combat is a tug-of-war over measure.

- **Engagement:** "In measure" = you can hit. Measure is a shared float per pair: 0 = blades touching, 1 = out of range. Attacker spends measure to close; defender spends to open. Stamina gates how much you can "spend" per action.
- **Gate:** Measure. Can't attack if measure > weapon_reach.  
**Pros:** Very HEMA-authentic; distance is first-class.  
**Cons:** New primary abstraction; significant refactor.

**Reference:** HEMA treatises (close/mid/long measure); Codex Martialis.

---

## Part 3: What Similar Systems Actually Use

### 3.1 Kingdom Come: Deliverance

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Stamina bar. Low stamina = weak attacks, block breaks, vulnerable to finishers. No separate "action bar"—stamina gates both readiness and effectiveness. |
| **Engagement** | Implicit. You're "in combat" when in range; no explicit engagement state. |
| **Distance** | Real 3D; weapon reach and positioning matter. No abstract bands. |
| **Flurry** | Combos: scripted sequences (head→right_upper→left_lower) for bonus damage. Not stamina-driven exchange—combo system. |
| **Disengage** | Player can back away; no mechanical "disengage roll." |

**Takeaway:** Stamina as dual gate (readiness + effectiveness). No gauge. Combos are content, not emergent flurry. Distance is spatial.

---

### 3.2 Mordhau

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Stamina. Each attack, parry, feint costs stamina. At 0: can't parry well, attacks are weak, vulnerable to kick/stagger. |
| **Engagement** | None explicit. Real-time; you're "in" when in range. |
| **Distance** | Physics/spatial. Weapon traces; reach matters. |
| **Flurry** | Emergent from stamina and attack cooldowns. Fast weapons (dagger) = more hits before stamina depletes. |
| **Disengage** | Movement. Walk away. No roll. |

**Takeaway:** Stamina-only gate. Weapon-dependent "flurry length" via attack cost and speed.

---

### 3.3 Exanima

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Physics + timing. You act when your character can (balance, recovery from last action). No visible gauge. |
| **Engagement** | Implicit—you're close or you're not. Physics governs. |
| **Distance** | Critical. Stay outside range, step in on recovery. AI explicitly uses distance. |
| **Flurry** | Emergent from physics. Can't chain if off-balance or recovering. |
| **Disengage** | Move away. Physics—if they're faster, they catch you. |

**Takeaway:** No traditional gate. Physics and positioning are the gate. Distance is first-class.

---

### 3.4 Dwarf Fortress (Adventure Mode)

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Turn-based. Move or attack per turn. |
| **Engagement** | Implicit. Adjacent = in range. |
| **Distance** | Grid. Steps matter. Don't move toward enemies—let them come (moving costs your turn). |
| **Flurry** | None. One action per turn. |
| **Disengage** | Move away. Costs turn. |

**Takeaway:** Pure turn-based. Distance = grid. No stamina-like gate; turn structure is the gate.

---

### 3.5 Mount & Blade / Bannerlord

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Real-time. Cooldowns per weapon (attack speed). Stamina in some mods. |
| **Engagement** | None explicit. Directional block/attack in real-time. |
| **Distance** | Spatial. Reach, positioning. |
| **Flurry** | Emergent. Fast weapons chain; directional match determines block. |
| **Disengage** | Movement. |

**Takeaway:** Real-time + cooldowns. Directional combat (guard vs attack direction). No engagement abstraction.

---

### 3.6 Burning Wheel Fight!

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Scripted volleys. Reflexes = actions per exchange. No gauge. |
| **Engagement** | Exchanges are the unit. Three volleys per exchange. |
| **Distance** | Abstract (scripted actions include "close" or "strike"). |
| **Flurry** | Scripted. You write your next 3 actions; they resolve in order. |
| **Disengage** | Script "Avoid" or "Flee" as an action. |

**Takeaway:** **Pre-scripted** actions. No reactive gauge—you declare intent for the whole exchange. Radically different from real-time or gauge.

---

### 3.7 The Riddle of Steel

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Secret declaration. No gauge or stamina in initiative. |
| **Engagement** | Simultaneous stance + intent declaration. Both reveal; resolve. |
| **Distance** | Abstract. Stance affects reach and coverage. |
| **Flurry** | Exchanges resolved by dice pool; wound charts. |
| **Disengage** | Declare defense/retreat; resolve. |

**Takeaway:** **Simultaneous declaration**—neither side has "turn." Spiritual Attributes add dice when narratively relevant. Very tabletop; would need adaptation for digital.

---

### 3.8 Hellish Quart

| Aspect | Implementation |
|--------|----------------|
| **Gate** | Physics. Blades collide; no stamina. |
| **Engagement** | Implicit—blades in contact = bind. |
| **Distance** | Physics. Hitboxes, reach. |
| **Flurry** | Emergent. Quick attacks chain if physics allows. |
| **Disengage** | Step back. Physics. |

**Takeaway:** Physics-only. No stamina or gauge. Collision = gate.

---

## Part 4: Synthesis and Recommendations

### Paradigms You Haven't Fully Explored

1. **Event queue / timeline** — Natural fit for flurries; both in same "sub-queue." Replaces gauge with "when does my next action resolve?"
2. **Simultaneous declaration** — Highest tension; Riddle of Steel / Burning Wheel. Hard for single-player AI.
3. **Beat / pulse** — Simple "everyone acts on the beat" with stamina gate. Clean.
4. **Defender-driven openings** — Inverted control; unusual but HEMA-aligned.
5. **Measure as resource** — Most HEMA-authentic; biggest refactor.

### What Similar Games Use (Summary)

| Game | Gate | Engagement | Flurry |
|------|------|------------|--------|
| **KCD** | Stamina | Implicit | Combos (scripted) |
| **Mordhau** | Stamina | Implicit | Emergent (weapon speed) |
| **Exanima** | Physics/timing | Implicit | Emergent |
| **DF** | Turn | Implicit | None |
| **Bannerlord** | Cooldown | Implicit | Emergent |
| **Burning Wheel** | Scripted volleys | Exchange | Scripted |
| **Riddle of Steel** | Simultaneous declare | Stance+intent | Dice pool |
| **Hellish Quart** | Physics | Implicit | Emergent |

**Common pattern:** Most digital games use **implicit engagement** (you're in or you're not; spatial). **Explicit engagement** (Fallen Paths' design) is rare—closest is Burning Wheel's "exchange" and Riddle of Steel's stance declaration.

**Gate:** Digital games split between **stamina** (KCD, Mordhau) and **physics/cooldown** (Exanima, Bannerlord). **Gauge** (your current system) is a form of stamina-like readiness; replacing it with pure stamina aligns you with KCD/Mordhau.

### Suggested Investigation Priorities

1. **Event queue** — If you want flurries to feel natural (both acting in quick succession), a timeline/queue avoids "whose turn" awkwardness.
2. **Measure as resource** — If HEMA authenticity is paramount, consider measure as the primary abstraction; stamina gates how much you can "spend."
3. **Beat + stamina** — Simplest replacement: global beat, stamina gate, engagement forms when both meet conditions. Easiest to implement.
4. **Burning Wheel–style scripted volleys** — If you want pre-commitment tension, have both sides script 2–3 actions; resolve. Very different feel.

---

## References

- MELEE_SIMULATION_AI_INVESTIGATION.md — Bannerlord, Exanima, KCD, Mordhau, For Honor, TLOU2, DF
- KINGDOM_COME_ABSTRACT_REPLICATION_INVESTIGATION.md — KCD mapping
- STAMINA_ENGAGEMENT_GATE_AND_DISTANCE_OPTIONS.md — gating and distance
- ENGAGEMENT_FLURRY_IMPLEMENTATION_OPTIONS.md — flurry approaches
- HEMA_VS_KCD_SOURCE_ANALYSIS.md — Liechtenauer vs KCD
- Riddle of Steel (Wikipedia, Grailrunner), Burning Wheel Fight! (wiki), Dwarf Fortress Adventure Mode (wiki)
- Simultaneous Combat System (Foundry VTT), Winter's Saga, Odd ReDuel
