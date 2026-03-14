# Melee Simulation Games: Combat Decision-Making Investigation

An investigation into how complex simulation games—especially those with detailed melee weapon simulation or physics-based attacks—handle combat AI decisions.

---

## 1. Game Categories and Their Approaches

### 1.1 Semi-Freeform / Directional Melee (Mount & Blade, Chivalry, Mordhau)

**Mount & Blade 2: Bannerlord** and similar games use **directional attacks** (choose attack direction before release) and **directional blocking** (block must match incoming attack direction).

#### Combat Mechanics

- **Attack:** Player/AI picks direction (left, right, overhead, thrust) and commits. Weapon animates from wind-up to release.
- **Block:** Defender must hold block in the correct direction. Shield users have an easier time (broader coverage).
- **Momentum, angle, weapon weight** influence damage (Bannerlord specifically).
- **Initiative:** Who attacks first matters; blocking or countering shifts advantage.

#### AI Decision-Making (Bannerlord)

- **Three-tier system:** Individual agents make real-time decisions; formation/orders affect aggression, not proficiency.
- **Opponent observation:** AI evaluates whether to attack or defend by watching opponent actions.
- **Directional awareness:**
  - If enemy is blocking → AI blocks incoming attack OR switches its own attack direction to avoid being blocked.
  - If enemy has shield → directional switching is less effective; AI adapts.
- **Skill scaling:** Higher melee skill → better understanding of stun durations, combat timings, enemy equipment. Skilled bots identify openings and switch attack directions.
- **Known issue:** At highest difficulty, AI is accused of reading player *inputs* directly rather than reacting to visual/animation cues—feels unfair.

**Relevance to Fallen Paths:** Bannerlord AI explicitly considers *opponent's block/guard state* when choosing attack direction. Your system has parry and guard; similar logic could weight "attack from unguarded angle" higher. Directional switching = "read defender's guard, pick counter."

---

#### Chivalry / Mordhau

- **Traces:** Weapon uses **trace/cast projected through animation** (line from handle to tip) for hit detection. Frame time turns weapon "on" for damage.
- **Feint, morph, chamber:** Advanced techniques consume stamina; AI would need to decide when to feint vs commit.
- **Initiative:** Blocking/countering shifts who has the next "turn" in the exchange.

**AI pattern:** Proximity-based target selection; behavior trees for move→attack cycles; animation events for damage frames. Less documented on high-level tactical decisions.

---

### 1.2 Physics-Based Melee (Exanima, Hellish Quart, Blade & Sorcery)

#### Exanima

- **Physics-driven:** Characters use active ragdoll; weapons and bodies interact via physics.
- **Balance simulation:** "Dynamic balancer" lets characters maintain balance during combat, recover from falls, trip/slip realistically.
- **Combat loop:** Distance and timing. AI (and player) wait outside range, let opponent attack, dodge during swing, counter during recovery.
- **Companion AI:** Learns over time; gains experience and confidence.
- **Hit location:** Weapon tip deals most damage; reach matters.

**AI decisions:** Distance management, timing windows (recovery), pattern recognition. "Learnable" rather than deep—once you understand patterns, AI isn't complex. Emphasis on *when* to act, not *which* of many options.

---

#### Hellish Quart

- **Physics-driven blade collision:** Blades genuinely clash and block via engine physics, not predetermined animations.
- **Collision modes:** "Stable" vs "Precise" to handle sword interactions (reducing "sticky blade" issues).
- **Motion capture:** Thousands of fencing moves drive active ragdoll.
- **One-hit lethality:** Single well-placed attack can end fight if it penetrates guard.
- **AI tiers:** Multiple difficulty levels; "Fencer AI" tier for advanced opponents.
- **Guards, attack cancellation, positioning** are core.

**AI decisions:** Guard choice, attack selection from motion-captured library, positioning. Physics means AI can't "cheat" timing—must work within same collision constraints as player. Decisions are which guard to hold, which attack to launch, when to cancel.

---

#### Blade & Sorcery (VR)

- **Freeform melee:** Player controls limbs directly; weapon follows hand.
- **Physics:** Grab opponent or their weapon; distance judgment from VR.
- **No traditional AI decision model** for combat—enemies use animation-driven attacks; player's physical input drives response. Highlights the gap: when combat is *physics-based*, animation-driven AI is a poor fit.

---

### 1.3 Realistic / HEMA-Inspired (Kingdom Come: Deliverance)

- **30+ target zones** per character; **4 armor layers**.
- **Physics reactions:** Swords clash and slide along armor; hits generate proper physical reactions.
- **Attack types:** Slash, stab, kick — directed at 5 body areas (head, left/right upper, left/right lower).
- **Combo system:** Fighting-game style chains; particular strikes chain to special finishers.
- **Stamina:** Depletes with actions; low stamina weakens attacks, breaks blocks, enables finishing moves.
- **Variables:** Armor, stamina, balance, fighting style, health, bleeding, fatigue, hunger.
- **Weapon authenticity:** Axes/maces vs armor; swords all-purpose; shields and reach matter.
- **Striking from unexpected angles** is more effective.

**AI decisions:** Not well documented publicly. Likely considers armor coverage, stamina state, exposed angles. Combo selection would need to chain valid follow-ups based on last hit.

**Relevance:** Your system has body parts, armor, bleeding—similar granularity. Kingdom Come's "unexpected angles" = target selection by armor exposure and guard gaps.

---

### 1.4 Read-React / Fighting-Game Adjacent (For Honor)

- **Directional parry:** Parry in direction of incoming attack; tight timing window.
- **Reading:** Success depends on reading attack patterns and animations.
- **Visual cues:** Dark-red dial flashes when attack about to connect.
- **Character-specific timing:** Faster opponents (Orochi) parry shortly after swing; slower (Shugoki) wait until animation finishes.
- **Unblockables:** Can't block; can parry or dodge. Must read "on instinct" (no flash cue).
- **Post-parry:** Guard break → heavy damage; AI would need to know this sequence.

**AI decisions:** React to attack direction and timing; choose parry direction; choose follow-up (guard break, light, heavy). Timing windows are character-specific—AI needs lookup or learned data per matchup.

---

### 1.5 Content-Driven with Polish (The Last of Us Part II)

- **Melee attack data:** Animations for attacker and defender; **starting and ending conditions** (range, facing, line of motion). If conditions not met, melee doesn't start.
- **Timeline events:** Hit frames, target tracking, invincibility windows—tags on animation timeline.
- **Melee behaviors:** One per NPC at a time. Each behavior has:
  - **Attack list** — which attacks can be started from this behavior
  - **Destination** — run to target, stay at distance, etc.
  - **Motion types** — run, walk, sprint within behavior
  - **Enter/exit conditions**
- **Design shift from Uncharted 4:** Longer attack tells, obvious telegraphing, dodge option. "Bear equal weight and complexity to gun combat."
- **Modular AI systems** for melee; emphasis on telegraphing so skilled players can react.

**AI decisions:** Behavior selects from attack list based on conditions. Attacks have prerequisites (range, facing). Exit conditions drive transitions. Highly content-driven but structured—behavior = mode, attack list = options.

**Relevance:** Your mental stack layers map to "behaviors" in a lighter form. Layer = behavior mode; options = attack list. TLOU2 uses explicit conditions per attack—you use `get_available_actions` similarly.

---

### 1.6 Procedural / Simulation-Heavy (Dwarf Fortress)

- **Body part model:** Creatures = hierarchy of parts (limbs, organs, bones, tissue layers). Each part has states: healthy, bruised, torn, mangled, nonfunctional, broken, missing.
- **Damage types:** Slashing (cuts through tissue, severs); blunt (bruises, shatters bone); piercing (penetrates, high chance to hit organs).
- **Material properties:** Contact area, momentum, elasticity affect outcomes.
- **Defense:** Block (shield skill), Dodge (Dodger skill), Observer (anticipate attacks, reduce surprise).
- **Flow-based:** Attacks take ~6 ticks; red arrow warns defender. Block/dodge rolls determine outcome.
- **Adventure mode:** High Observer reveals *which limb or weapon* opponent will use next—explicit read of incoming attack.

**AI decisions:** DF doesn't have tactical AI in the same sense—creatures act on instincts/needs. But the *resolution* model is rich: body parts, materials, skills. Observer skill = "I know what's coming" — relevant for parry/defend weighting in your system.

---

### 1.7 Systemic vs Content-Driven (Playtank Framework)

The [Playtank "Building Systemic Melee"](https://playtank.io/2024/08/12/building-systemic-melee/) article distinguishes:

| Type | Description | Player Activities |
|------|--------------|-------------------|
| **Feature-Rich** | God of War, Ghost of Tsushima. Content-driven; cues and timing. | Wait for animations; retry; look for hints. |
| **Content-Based** | Soulsborne, Street Fighter. Learn attack sequences, reach, frames. | Learn content; anticipate opponent. |
| **Semi-Freeform** | Chivalry, Mount & Blade. Directional input; weapon guidance. | Judge distance; guide direction; positioning. |
| **Ragdoll/Physics** | Exanima, Hellish Quart, Gang Beasts. Simulation-driven. | Wait for simulation; learn simulation rules. |
| **Systemic** | Stim/response; weapon "injects" state into hit object. Result depends on what's hit. | Modular; object-rich. |

**Hit detection options:**

1. **Frame time** — weapon "on" for damage during specific animation frames
2. **Trace/cast** — line or sweep from handle to tip; intersection = hit
3. **Collision volume** — physics collider; compound (crossguard, blade, pommel) or single mesh
4. **Attack direction** — angle from centerpoint (navel) to determine zone hit

**Defense options:** Guards/stances, parry, block, interrupt, riposte, dodge.

**Footwork:** Push/pull, circling, positioning. Loop: Circling → Push/Pull → Positioning → Attack.

---

## 2. Decision-Making Patterns Across Games

### 2.1 Observation → Response

| Game | What AI Observes | What AI Decides |
|------|------------------|-----------------|
| **Bannerlord** | Opponent block direction, shield presence | Attack direction, block direction |
| **For Honor** | Attack direction, animation phase | Parry direction, dodge, follow-up |
| **Exanima** | Opponent range, swing state, recovery | When to step in, when to strike |
| **Hellish Quart** | Guard, blade position (physics) | Guard choice, attack from library |
| **Kingdom Come** | Armor coverage, stamina, angle | Target zone, attack type |
| **TLOU2** | Range, facing, conditions | Which behavior, which attack from list |
| **Dwarf Fortress** | (Instinct-driven) | Block/dodge rolls; Observer reveals incoming |

### 2.2 Common Decision Axes

1. **Target selection** — Who to attack (Bannerlord: first available; many games: closest or most damaged)
2. **Attack direction/type** — Which strike (Bannerlord: counter block; For Honor: mix-up; KC: exposed angle)
3. **Defense choice** — Block, parry, dodge (Bannerlord: match direction; For Honor: match direction + timing; Exanima: move out of the way)
4. **Timing** — When to act (Exanima: recovery windows; For Honor: parry window; TLOU2: attack tells)
5. **Positioning** — Distance, angle (Exanima: stay outside range; Chivalry: weapon reach; KC: unexpected angle)
6. **Stamina/resources** — (Mordhau, KC: stamina; TLOU2: behavior constraints)

### 2.3 Physics vs Animation

- **Animation-driven:** Decisions trigger animations; hit detection tied to frame events. Easier to balance; predictable.
- **Physics-driven:** Decisions affect rigidbodies/constraints; outcomes emerge from simulation. Harder to tune; can feel unfair if physics is chaotic.
- **Hybrid:** Some games use animation for "when" and physics for "where" (e.g., trace along animated weapon path). Chivalry traces through animation.

---

## 3. Implications for Fallen Paths

### 3.1 Your Current System (from codebase)

- **Gauge-based readiness** — who can act when
- **Wind-up → execute** — commitment before resolution
- **Defense:** Passive dodge (perception/agility), passive parry (readiness/capacity vs momentum)
- **Body parts,** armor, bleeding, damage types
- **Attack types:** Cut, thrust, blunt; archetypes (quick_slash, overhead, etc.)
- **No directional guard** — guard is a scalar (0.4 when attacking, rises when idle)
- **No explicit "attack direction"** — attack_type and part selection, not left/right/overhead

### 3.2 Patterns You Could Adopt

| Pattern | Game Source | Implementation Idea |
|---------|-------------|----------------------|
| **Counter block/guard** | Bannerlord | If defender has high guard on a part, weight attacking a different part or a thrust (harder to block uniformly) |
| **Recovery window** | Exanima | Enemy in RECOVERING = high-priority target; short opportunity window |
| **Exposed angle** | Kingdom Come | Score target parts by armor coverage, current guard; "unexpected" = unguarded |
| **Observer/read** | Dwarf Fortress | Perceive "enemy winding up" → weight parry. (You have `_is_being_targeted`.) |
| **Behavior + attack list** | TLOU2 | Mental stack layer = behavior; `get_available_actions` = attack list; conditions filter |
| **Stamina-like** | Mordhau, KC | Gauge already acts like stamina; intensity/commitment affects recovery. Could add "heavy attack = more gauge cost" for trade-off |
| **Timing windows** | For Honor | Parry has reaction window; your passive parry uses reaction_time vs effective_wind_up. Could expose "parry difficulty" per attack type. |

### 3.3 What Doesn't Map Directly

- **Directional blocking:** You don't have left/right/overhead guard. Adding it would be a large change. Without it, "switch attack direction" from Bannerlord doesn't apply literally—but "attack unguarded part" does (body part targeting).
- **Physics blade collision:** Hellish Quart/Exanima-level physics would require a different engine/approach. Your system uses resolved outcomes (hit/parry/miss) not continuous physics.
- **Combo chains:** Kingdom Come combos are scripted sequences. You could add "last attack type" and weight follow-ups (e.g., thrust after cut), but it's new content.

---

## 4. Summary: Decision-Making Priorities in Simulation Melee

Complex melee simulation games tend to prioritize:

1. **Observe opponent state** — block direction, guard, recovery, stamina, exposed parts
2. **Choose action that counters or exploits** — attack unguarded, parry incoming, wait for recovery
3. **Respect timing** — act in valid windows; don't commit when opponent can punish
4. **Manage resources** — stamina, gauge, initiative
5. **Use positioning** — distance, angle (when the system supports it)

For **physics-based** games, decisions are often simpler (Exanima: "when to strike") because the simulation handles the rest. For **animation-driven** games with directional combat (Bannerlord, Mordhau), AI needs to track opponent guard and pick counter-directions. For **content-driven** games (TLOU2), behaviors and attack lists with conditions structure choices.

**Fallen Paths** sits between: animation-driven resolution (wind-up, execute) but with body parts, armor, and defense rolls. The mental stack + opportunity scoring (enemy in recovery, low health, unguarded part) aligns with Bannerlord and Kingdom Come patterns. Observer-style "enemy winding up on me" → parry fits Dwarf Fortress and your `_is_being_targeted` design. You don't need directional guard to benefit—**body part targeting** and **attack type** (thrust vs cut) can serve the same role as "angle" in other games.

---

## References

- Mount & Blade 2: Bannerlord AI overhaul, Steam discussions, AltChar
- Exanima: Steam, store page, community guides
- Kingdom Come: Deliverance: Gaming Nexus, forum posts, combat system
- Chivalry, Mordhau: GamePressure, Toolify, Playtank
- Hellish Quart: Wikipedia, Rock Paper Shotgun, The Gamer
- For Honor: Inverse, VG247, Oreate AI
- The Last of Us Part II: Game Developer (GDC 2021)
- Dwarf Fortress: Wiki (body parts, combat skill, dodging)
- Playtank: "Building Systemic Melee" (2024)
- ACM: "Development of Tactical Level AI for Melee and Range Combat" (2020)
- Fallen Paths: COMBAT_ATTACK_PARRY_DODGE_FLOW.md, CombatManager.gd
