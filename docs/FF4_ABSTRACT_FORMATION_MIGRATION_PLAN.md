# FF4-Style Abstract Formation Migration Plan

A structured plan to migrate the combat system to an **FF4-like abstract row/formation model** — zones, ranks, and formations without x,y coordinates. Each feature is presented as a **decision point**: you choose the implementation approach. The AI builds it correctly once you've decided.

---

## Part 1: Target Model (FF4 Abstraction)

### Core Principles

- **No x,y positions.** Units occupy abstract slots: rank (row), file (column), and zone.
- **Formations** define structure: width (files) × depth (ranks), density, facing.
- **Distance** is derived from zones/bands (close, mid, long), not Euclidean space.
- **Engagement** is slot-based: who can attack whom is determined by rank, file, and zone membership.

### FF4 Reference (Simplified)

| FF4 Concept | Our Abstract Equivalent |
|-------------|--------------------------|
| Front row | Rank 0 (primary melee) |
| Back row | Rank 1 (support: ranged, magic, heals) |
| Row swap | Formation action (swap rank) |
| Formation presets | Formation template (width, depth, density) |
| No positions | Zone ID + rank + file |

### What Stays Abstract

- **Distance bands** (close/mid/long) — per attacker–defender pair or per zone adjacency.
- **Zone of control** — formation's grip on space; weakens with casualties.
- **Flank/rear** — derived from zone or file structure, not angles.
- **Surround** — count of close threats; defense splitting; optional flank access.

---

## Part 2: Migration Order (Suggested Phases)

The plan assumes you implement in phases. You may reorder or combine phases.

| Phase | Focus | Depends On |
|-------|-------|------------|
| **0** | Prep: data structures, constants | — |
| **1** | Event queue (replace gauge) | Phase 0 |
| **2** | Distance bands (close/mid/long) | Phase 0 |
| **3** | Formations (rows + files) | Phase 0, 1 |
| **4** | Zone of control (ZoC) | Phase 3 |
| **5** | Formation actions (swap rank, fall back, rotate) | Phase 3 |
| **6** | Tactical features (ambush, surround, breakthrough, flanking) | Phase 3–4 |

---

## Part 3: Feature Decision Points

For each feature, you will see:
- **Design goals** — what the feature should accomplish
- **Implementation options** — plausible approaches
- **Your decision** — place to record your choice (and any constraints)

---

### 3.1 Formations (Rows + Files)

**Design goals:**
- Represent unit layout as rank (row) and file (column)
- Front rank engages; back rank supports (ranged, magic, heals)
- Formation shape (width × depth) affects defense and targeting

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Per-side formation** | Each side has one formation. All player units in one formation; all enemies in another. Formation has `files` (width) and `ranks` (depth). Units assigned to (rank, file) slots. | Low |
| **B: Per-encounter formation** | Formation is created per encounter. Party formation vs enemy formation. Multiple formations if multi-faction (e.g. 2v2). | Medium |
| **C: Per-unit formation + shared template** | Each unit has `formation_id` and `rank`, `file`. Formation resource defines template (width, depth, density). Units can be in different formations (e.g. split party). | Medium |

**Rank/file assignment at combat start:**
- By spawn order? (first N → rank 0, next M → rank 1)
- By agility? (fastest in front)
- By equipment? (shield in front, spear in back)
- By explicit party setup? (player assigns before combat)

**Your decision — Formations:**

- [x] Option: **A (per-side)**
- [x] Rank/file assignment: **Spawn order for now.** Plan: add logic so heavily armored units in front row, spears favored for second row, less armored/weaker in reserve; front row fills first, then second, reserve only if enough units.
- [ ] Notes: _____

---

### 3.2 Distance Bands (Close / Mid / Long)

**Expanded explanation — Distance bands:**

Distance bands replace x,y positions with abstract ranges that determine what attacks are possible:

| Band | Who can attack | Who can be targeted |
|------|----------------|---------------------|
| **Close** | Melee (sword, axe, mace, dagger), spear | Anyone at close |
| **Mid** | Spear (long reach), ranged, magic | Anyone at mid or long |
| **Long** | Ranged (reduced), magic | Anyone at long |

**How distance changes during combat:**

- **Closing:** Melee at mid/long must succeed at a "close" action (e.g. roll vs defender evasion) to become close. Spear at mid can attack without closing.
- **Disengaging:** At close, defender can attempt disengage (roll vs attacker hold); success → mid or long.
- **Approach:** Some systems have an "approach" step (long→mid) before close; others jump long→close in one roll.

**Pair-wise vs zone-based:**

- **Pair-wise (A):** Each (attacker, defender) has its own band. Stored as `distance_to[target_id] = "close"`. Independent of formation zones. Simple, works for any unit count. No ZoC needed. Downside: 10v10 = 100 pairs; can get verbose.
- **Zone-based (B):** Distance comes from "which zone am I in vs which zone are they in?" Same zone = close; adjacent zone = mid; else long. Requires zones to exist. Ties naturally to ZoC: when our flank zone weakens, enemies "in" that zone are at close. Cleaner for formation-vs-formation. Downside: needs zone structure first.
- **Hybrid (C):** Pair-wise for unformed units (wolves, lone combatants); zone-based when both sides use formations. Best of both; more branching logic.

**Close attempt mechanics:**

- **Roll vs evasion:** Attacker's engagement_pressure vs defender's evasion. Success → close. Fits stamina plan.
- **Fixed success:** E.g. 70% chance. Simpler; less tactical.
- **Cost-based:** Spend stamina or turn; success guaranteed. Predictable; may feel gamey.
- **Opponent can block:** Defender spends reaction to deny close. Adds defender choice.

**Design goals:**
- Melee needs close; spear can attack from mid; ranged from mid/long
- Band transitions: approach (long→mid→close), disengage (close→mid→long)
- Per attacker–defender pair or per formation zone

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Pair-wise** | Each (attacker, defender) has `distance_band`. Stored in manager or on combatant (`distance_to[target_id]`). Default long. | Low |
| **B: Zone-based** | Distance derived from zone adjacency. Same zone = close; adjacent = mid; else long. Ties to ZoC. | Medium |
| **C: Hybrid** | Pair-wise for unformed/pack; zone-based for formation vs formation. | Medium |

**Close attempt:** When attacker at mid/long wants to melee, they must "close" (roll vs evasion? fixed success?).

**Expansion — Open space vs shield wall (per user):** Units with lots of space + long-range weapons = easier to avoid engagement/disengage. Shield walls (close proximity, no movement room) = harder to avoid/disengage. Add formation `density` (loose/normal/tight): modulates close attempt (defender evasion) and disengage (defender roll). See `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` Part 1.

**Your decision — Distance bands:**

- [ ] Option: _____
- [ ] Close attempt mechanic: _____
- [ ] Notes: _____

---

### 3.3 Zone of Control (ZoC)

**Design goals:**
- Formation's control over space grows/shrinks with casualties
- Weak ZoC allows flanking (enemies can occupy our weak zones)
- No pathfinding — "movement" = zone accessibility + assignment

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: No ZoC initially** | Ship without ZoC. Flank = file-based (flank files weaker) or flat surrounded penalty. Add ZoC later. | Minimal |
| **B: File weakness only** | Leftmost/rightmost files have lower defense. Attackers targeting those get flank bonus. No dynamic control. | Low |
| **C: Zone control strength** | Each zone (front, left, right, rear) has control 0–1. Drops with casualties. Below threshold → flank accessible. | Medium |
| **D: Full ZoC** | Control formula: units + adjacent support - incursion - casualties. Extent shrinks with control. | High |

**Expanded explanation — Zone of Control (ZoC):**

ZoC = the formation's "grip on space." Strong ZoC = enemies can't reach your flanks or rear. Weak ZoC = they can occupy those zones and get flank/rear bonuses. ZoC answers: *when can the enemy get beside or behind us?*

**Option A (No ZoC):** Ship without it. Flanking = file-based only: leftmost/rightmost files are "flank files" by definition; attackers there get a bonus. No dynamic control; no zones. *When to use:* Want to ship sooner; flank is a static formation property.

**Option B (File weakness only):** Same as A but explicit: flank files have lower defense (fewer units, or built-in modifier). No control strength; just "flank files exist." *When to use:* Quick flank bonus; no emergence.

**Option C (Zone control strength):** Formation has zones (front, left, right, rear). Each zone has control 0–1. Control = f(units in zone, casualties, adjacent support). When control < threshold (e.g. 0.6), that zone is *accessible*—enemies can be assigned there and get flank/rear bonus. Control drops when units die, incursion occurs, or breach happens. *When to use:* Want flanking to emerge from combat; "we lost the left flank" feels earned.

**Option D (Full ZoC):** Rich formula: `control = units + adjacent_support - incursion - casualties`, normalized. Extent (how far the zone projects) shrinks with control. Distance derives from zone extent. *When to use:* Want formation "size" to matter; big formation = long reach when strong; shrinks when battered.

**Interplay with formation actions:** Fall back, rotate, and breakthrough all *affect* ZoC. Fall back = unit leaves front zone → control drops. Rotate = reserves fill gap → control recovers. Breakthrough = we push into their zone → their control drops, ours rises. So ZoC decision constrains what formation actions can do.

**Your decision — ZoC:**

- [x] Option: **D (Full ZoC)**
- [ ] When to add (phase): _____
- [x] Notes: Control formula: units + adjacent_support - incursion - casualties. Extent shrinks with control. See `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` for ZoC B vs C clarification (D includes C; no further B vs C choice needed).

---

### 3.4 Formation Actions (Swap Rank, Fall Back, Rotate)

**Design goals:**
- Swap rank: front ↔ back (like FF4 row change)
- Fall back: unit retreats (disengage, move to rear)
- Rotate: formation shifts (e.g. reserves move to front)

**Implementation options:**

| Action | Options | Your choice |
|--------|---------|-------------|
| **Swap rank** | (a) Instant; (b) Costs action/turn; (c) Costs stamina + short delay | _____ |
| **Fall back** | (a) Disengage + move to rank 1; (b) Disengage + move to rear zone; (c) Full retreat (out of combat) | _____ |
| **Rotate** | (a) File shift (left↔right); (b) Rank shift (reserves advance); (c) Both as separate actions | _____ |

**Your decision — Formation actions:**

- [ ] Swap rank: _____
- [ ] Fall back: _____
- [ ] Rotate: _____
- [x] Notes: **ZoC D chosen.** Expand formation actions per `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` (plugging, rank advance, lateral close). Roman/medieval variable system for rotation.

---

### 3.5 Ambush

**Design goals:**
- Surprise: attacker gets advantage (first strike, bonus damage, or target can't react)
- Can be formation-based (they didn't see us) or tactical (we flanked silently)

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Combat start only** | Ambush = encounter type. If ambushed: defender side skips first N actions or gets penalty. | Low |
| **B: Formation state** | "Ambush" = formation state. When we engage from unrevealed zone, first round bonus. | Medium |
| **C: Tactical ambush** | When attacker engages from rear/flank zone (ZoC was weak), first strike bonus. Ties to ZoC. | Medium |

**Your decision — Ambush:**

- [x] Option: **A (Combat start only)**
- [x] Bonus type: **Formation position impact.** Ambushers spawn in preferred formation; defenders spawn sideways, backwards, or unprepared (exhaustion or other penalties).
- [x] Notes: **Remove full surround.** Focus on formation-based combat. Flank/rear from ZoC, not distinct "surround" mechanic. See investigation doc.

---

### 3.6 Surround

**Design goals:**
- Defender facing multiple close attackers is overwhelmed
- Defense (parry/dodge) is split across threats
- Feels different from 1v1

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Defense splitting only** | `parry_capacity /= clamp(num_close_threats, 1, N)`. Already in STAMINA_SYSTEM_IMPLEMENTATION_PLAN. | Low |
| **B: Split + flat penalty** | Split + if num_threats ≥ 3, extra ×0.8 to defense. | Low |
| **C: Split + angle** | Split + attackers from flank/rear get bonus (ties to ZoC or engagement_angle). | Medium |

**Your decision — Surround:**

- [x] Option: **Perception/awareness + weapon position + parry choice.** Units have deficits when defending against multiple enemies; **perception/awareness** stat takes the debuff. **Weapon position** (near body vs extended) driven by combat state: near body when WAITING, WIND_UP, intercepting, or recovering from parry; extended when RECOVERING from own attack (swinging/recovering). Parries meet weapon at defender's zone. **Parry choice:** Only when defender cannot parry both attacks in the window (capacity/time insufficient). If able to parry all, no choice. When forced: prioritize more damaging (overhead sword > quick dagger slash). **Wind-up extended:** Weapon switches to extended after realistic commit point per attack (e.g. commit_fraction 0.7 — at 70% of wind-up). See investigation doc Part 4b.
- [ ] Max split divisor: _____
- [x] Notes: See `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` Part 4 and Part 4b. Defense split + awareness_factor(perception) + weapon_position factor (near body vs extended). **Parry choice only when unable to parry both** — run `can_parry_all(incoming, D)` first; if yes, resolve each with parry. If no, `choose_parry_target(incoming)` by threat; resolve chosen first. **Wind-up:** weapon extended after realistic commit point per attack (`state_timer >= wind_up × commit_fraction`); add `commit_fraction` per move (default 0.7). No "full surround" — formation-based.

---

### 3.7 Breakthrough

**Design goals:**
- Attacker pushes through defender's position (formation breach)
- Defender's rank/file is compromised; we advance
- Often costs momentum/stamina

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Defeat = breakthrough** | When defender in rank 0 dies, rank 1 advances. No separate action. | Low |
| **B: Breakthrough action** | Dedicated action: roll vs defender hold. Success → we occupy their slot; they pushed back. | Medium |
| **C: ZoC breach** | On successful "push" (attack + high commitment?), our ZoC extends into their zone; theirs shrinks. | Medium |

**Your decision — Breakthrough:**

- [x] Option: **Death + ZoC + strength + roll.** Breakthrough **contests** plugging (not sequential). Slot opens → plug attempt AND incursion attempt can both occur; stronger wins. Enemies try to plug; opponents can contest with incursion if strong enough. Incursions should **not** be normal (<20% of gap events). Add **morale** stat for formation/individual to handle dynamic positioning and decision making.
- [x] When available: When slot opens (death); contest: plug vs incursion. Morale affects plug success; push tendency affects incursion attempt.
- [x] Notes: See investigation doc Part 9 (9.2, 9.4). Historical: breaches rare, decisive; plug success 75–90%; aim incursion <15–20%.

---

### 3.8 Flanking

**Design goals:**
- Attacker from flank/rear gets bonus (defender can't defend as well)
- Shield less effective from side/rear
- Derived from formation structure or ZoC

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: File-based** | Flank = leftmost/rightmost files. Attacker targeting those files gets ×0.75 parry. | Low |
| **B: Engagement angle** | Each attacker–defender has `engagement_angle`: front / left_flank / right_flank / rear. Modifier per angle. | Medium |
| **C: ZoC-based** | When our zone control < threshold, enemy can occupy that zone. Occupying = flank/rear. | Medium |

**Your decision — Flanking:**

- [ ] Option: _____
- [ ] Modifier values (front=1.0, flank=?, rear=?): _____
- [ ] Notes: _____

---

### 3.9 Event Queue (Replace Gauge)

**Design goals:**
- Replace gauge fill with scheduled events
- Actions resolve at `resolve_at` timestamps
- Supports variable timing (wind-up, recovery, close attempt, flurry)

**Implementation options:**

| Aspect | Options | Your choice |
|--------|---------|-------------|
| **Queue structure** | (a) Sorted array; (b) Min-heap by resolve_at | _____ |
| **Turn readiness** | Emit `turn_ready` when EVENT_ACTION_READY for player and state=IDLE | (same as plan) |
| **Simultaneous events** | Tie-break: agility, then combatant_id | _____ |
| **Combat clock** | `combat_clock += delta` each frame | _____ |

**Your decision — Event queue:**

- [x] Queue structure: **Min-heap** (by resolve_at). O(log n) insert; O(1) peek at next event. No meaningful drawbacks for combat scale (<100 events).
- [x] Keep gauge UI during migration? (yes/no): **No** — change UI to stamina instead of gauge.
- [x] Notes: _____

---

### 3.10 Engagement & Flurry

**Design goals:**
- When melee hits/parries at close, combatants may enter engagement
- Engaged: alternating blows (flurry); reduced wind-up
- Disengage: stamina low, max blows, or disengage roll

**Implementation options:**

| Aspect | Options | Your choice |
|--------|---------|-------------|
| **Engagement formation** | (a) 1v1 only; (b) 1v1 primary, others make normal attacks (no flurry) | _____ |
| **Flurry max blows** | Fixed (e.g. 4) or stamina-based | _____ |
| **Disengage** | Defender rolls vs attacker hold; or automatic when stamina < X | _____ |

**Your decision — Engagement:**

- [x] Engagement: **1v1 primary + others normal.** Primary engaged pair can flurry; others make normal attacks (no flurry).
- [x] Flurry: **Stamina + decision-based, no fixed max blows.** Flurry continues until: stamina too low, or either combatant decides to stop (e.g. to retreat, reposition, or save stamina).
- [x] Disengage: **Two triggers: (1) Both units fall below stamina threshold** → automatic disengage; **(2) Either decides to attempt** → roll to influence disengage value vs opponent. Opponent may try to keep them engaged or allow disengage based on their stamina and situation.
- [x] Notes: _____

---

### 3.11 Multi-Target Scaling (Slot Limit, Target Distribution)

**Design goals:**
- Prevent 15-on-1 bunching
- Spread attackers across targets
- Defense splitting for surrounded defenders

**Implementation options:**

| Option | Description | Your choice |
|--------|-------------|-------------|
| **Close slots per target** | Max N attackers can be "close" to one defender. N = _____ | _____ |
| **AI target weighting** | Prefer targets with fewer allies? (yes/no) | _____ |
| **Defense split max** | Cap divisor so 5+ doesn't trivialize. Value = _____ | _____ |

**Your decision — Multi-target:**

- [ ] Close slots: _____
- [ ] AI weighting: _____
- [ ] Notes: **Numbers deferred to implementation.** Will pick close slots per target, AI weighting, and defense split max when implementing.

---

### 3.12 Formation-Based Targeting

**Design goals:**
- Units can only engage enemies realistically near them (by formation position)
- Units can help adjacent allies
- Incursions and lateral movement based on gaps and formation positioning

**Your decision — Targeting:**

- [x] Option: **Formation vs formation positioning.** Units at (rank R, file F) can only melee targets in opposing formation at rank 0, file F±1 or F. **Add:** `formation.spacing_m` (or from density: tight=0.9, normal=1.2, loose=1.8). **Filter:** `weapon.melee_range >= effective_distance(our_slot, their_slot)` — loose vs phalanx have different reach. ZoC extent can modify reach when control high. Ranged: any in range. Incursion: target in occupied zone. Support: adjacent allies.
- [x] Notes: See investigation doc Part 7 and Part 9.5. Need `effective_distance` between slots; `spacing_m`; reach filter. Without these, loose vs phalanx not robust.

---

## Part 4: Data Structure Decisions

Before implementation, decide the shape of the data.

### 4.1 Combatant Additions

| Field | Purpose | Your choice |
|-------|---------|-------------|
| `rank` | Row (0=front) | Yes |
| `file` | Column (0..N-1) | Yes |
| `formation_id` | Which formation | Yes |
| `distance_to` | target_id → "close"\|"mid"\|"long" | Yes |
| `engaged_with_id` | -1 or opponent id | Yes |
| `engagement_angle` | "front"\|"left_flank"\|"right_flank"\|"rear" (if ZoC) | Yes |
| `zone_id` | Which zone in formation (Full ZoC) | Yes |
| `occupied_zone_id` | Enemy zone we've broken into (incursion) | Yes |
| `weapon_extension` | Personal vs extended for parry | Defer or add |
| `push_tendency` | For breakthrough decision | Optional |

**Your decision:**

- [x] Add: rank, file, formation_id, distance_to, engaged_with_id, engagement_angle, zone_id, occupied_zone_id
- [x] Defer: weapon_extension (when weapon position ready)
- [ ] Notes: See investigation doc Part 8.

---

### 4.2 Formation Structure

| Field | Purpose | Your choice |
|-------|---------|-------------|
| `files` | Width (number of columns) | Yes |
| `ranks` | Depth (number of rows) | Yes |
| `density` | loose/normal/tight (distance mods) | Yes |
| `zone_control` | Zone → 0..1 (Full ZoC) | Yes |
| `side` | "player" / "enemy" | Yes |
| `facing` | front/left/right/rear (ambush) | Yes |
| `slots` | (rank, file) → combatant_id | Yes |
| `gaps` | (rank, file) open slots | Yes |
| `plug_rule` | rank_advance / lateral_close / both | Yes |

**Your decision:**

- [x] Formation resource or inline dict: Inline dict per encounter; formation template optional.
- [x] Notes: See investigation doc Part 2 (formation shifts), Part 8.

---

### 4.3 Manager Additions

| Field | Purpose | Your choice |
|-------|---------|-------------|
| `event_queue` | Min-heap of events | Yes |
| `combat_clock` | float | Yes |
| `formations` | Array of formation dicts | Yes |
| `distance_bands` | (id1, id2) → band (if not per combatant) | Optional |
| `encounter.ambush_type` | none/full/partial | Yes |
| `encounter.ambush_penalty` | Formation facing + penalties | Yes |

**Your decision:**

- [x] Add: event_queue, combat_clock, formations, encounter.ambush_type, encounter.ambush_penalty
- [x] Notes: See investigation doc Part 8.

---

## Part 4.5: Formation UI & Scene Setup

**Design goals:**
- Visual representation of player and enemy formations as rank×file grids
- Unit spacing reflects formation density (tight/normal/loose)
- Party and enemy formations configurable via presets
- Scene setup: party formation from PartyManager/world meta; enemy formation from encounter or derived from count

**Formation preset structure:**
```gdscript
{ "files": int, "ranks": int, "density": "tight"|"normal"|"loose" }
```

**UI layout (implemented):**
- Replace vertical lists with GridContainers when formations exist (FormationLayoutBuilder)
- Compact formation diagram (FormationDiagramBuilder): rank×file overview with Front/Back labels; updates on formation_changed (e.g. swap rank)
- Columns = files; rows = ranks (rank 0 = front)
- Slot spacing: tight=8px, normal=16px, loose=24px (or scale from CombatConstants.SPACING_*)
- Empty slots: placeholder Control to preserve grid structure
- Combatant rows positioned by (rank, file)

**Preset sources:**
- **Party:** PartyManager.formation_preset or world meta "party_formation". Default: 2×ceil(n/2), normal density.
- **Enemy:** Encounter formation or derived: 2×ceil(n/2), normal density. Future: per-encounter preset.

**CombatFlow/BattleScene:**
- `battle.start(players, enemies, player_formation_preset, enemy_formation_preset)`
- CombatManager receives presets, builds formations, assigns rank/file at start
- FormationLayoutBuilder arranges combatant rows in grid by rank/file

---

## Part 5: Implementation Checklist

**For the canonical phase-by-phase checklist and task status, see `docs/IMPLEMENTATION_OUTLINE.md`.**  
This document records design decisions; the implementation outline is the source of truth for what’s done and what’s next.

---

## Part 6: Remaining Decisions Summary

### Point 8: Formation-Based Targeting + Weapon Reach (Decided)

| Decision | Choice | Notes |
|----------|--------|-------|
| **spacing_m source** | **(b)** Derive from density | tight=0.9, normal=1.2, loose=1.8 |
| **effective_distance formula** | **`\|Δfile\| × avg_spacing`** (simple) | Refine with rank depth/diagonal if needed |
| **REACH_SAFETY_FACTOR** | **0.8** (placeholder) | Investigate more accurate; dagger can't reach loose 2m opposite |
| **ZoC extent modifier** | **Defer** to Phase 4+ | Start without ZoC extent on reach |

### Decision Status Summary (from FF4_REMAINING_DECISIONS_CHECKLIST)

| Section | Decision | Status |
|---------|----------|--------|
| **3.2 Distance bands** | Hybrid (C); roll vs evasion; stances | Decided |
| **3.3 ZoC** | Phase 4 | Decided |
| **3.4 Formation actions** | Swap (b+c); Fall back (b+c + drag/step-over); Rotate (b+c) | Decided |
| **3.6 Surround** | Max split divisor | Open (pick at implementation) |
| **3.8 Flanking** | Hybrid ZoC + angle; modifiers 0.8/0.7 | Decided (see ENGAGEMENT_ANGLE_VS_ZOC_FLANKING) |
| **3.9 Event queue** | Agility, then combatant_id | Decided |
| **3.11 Multi-target** | Close slots, AI weighting, defense split max | Deferred to implementation |
| **4.1 Combatant** | weapon_extension | Defer (derive from state per Part 4b) |

---

## Part 7: References

- **`docs/IMPLEMENTATION_OUTLINE.md`** — Master implementation guide; start here.
- `docs/FF4_REMAINING_DECISIONS_CHECKLIST.md` — All final decisions
- `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` — distance expansion (open vs shield wall), formation shifts (Roman/medieval), ambush formation impact, surround perception/weapon position, breakthrough, targeting, data structures
- `docs/STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md` — distance bands, event queue, multi-actor
- `docs/FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md` — formation + surround approaches
- `docs/ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md` — ZoC, zone structure
- `ui/CombatManager.gd` — current gauge-based flow
- `combat/AvailableActionsBuilder.gd` — action filtering (will add distance/formation filters)

---

## Summary

Fill in each **Your decision** section with your chosen option and any constraints. Once complete, this document serves as the spec: implementation follows your choices. Revisit and update as you refine during development.
