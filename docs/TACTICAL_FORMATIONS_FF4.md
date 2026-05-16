# Tactical Formations Ff4

**Plan / code:** Design depth for **`IMPLEMENTATION_ORDER.md`** Tier **2.2**; rank/file/slots **truth** is Tier 1 / `combat/` — not a second execution order.

Consolidated sections; each has **`Source:`** for provenance.

## Contents

1. [FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md](#ff4-abstract-formation-migration-plan)
2. [FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md](#ff4-formation-distance-ambush-breakthrough-investigation)

---

<a id="ff4-abstract-formation-migration-plan"></a>

## Source: `FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md`

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
| Deeper ranks | Rank 1+ (support, rotation, swap; **depth-eligible polearms** may melee through same-file rank 0 — see **`IMPLEMENTATION_ORDER`** Tier **1.9**; not “rank 1 ranged only”) |
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
| **Mid** | Melee whose `melee_range` clears pair `effective_pair_eff_dist` (step-in/lunge), spear, ranged, magic | Anyone at mid or long |
| **Long** | Ranged (reduced), magic | Anyone at long |

**How distance changes during combat:**

- **Closing / reach:** At **mid**, if geometric reach covers the pair (`melee_range >= effective_pair_eff_dist` in `AvailableActionsBuilder`), melee strikes are listed without a prior `attempt_close`. At **long** (or out of reach), `attempt_close` (roll vs evasion) is still used to enter **close** or to close distance when strikes are not yet listed. Native polearm-at-mid **AI** bias still uses `REACH_MID_MIN` in `CombatAIActionPicker` for depth ranks.
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
- Melee at **close** always; at **mid**, melee when reach geometry allows (shipped); ranged from mid/long
- Band transitions: approach (long→mid→close), disengage (close→mid→long)
- Per attacker–defender pair or per formation zone

**Implementation options:**

| Option | Description | Complexity |
|--------|-------------|------------|
| **A: Pair-wise** | Each (attacker, defender) has `distance_band`. Stored in manager or on combatant (`distance_to[target_id]`). Default long. | Low |
| **B: Zone-based** | Distance derived from zone adjacency. Same zone = close; adjacent = mid; else long. Ties to ZoC. | Medium |
| **C: Hybrid** | Pair-wise for unformed/pack; zone-based for formation vs formation. | Medium |

**Close attempt:** When attacker cannot list strikes (typically **long** or **mid** but `melee_range < effective_pair_eff_dist`), `attempt_close` advances engagement (roll vs evasion).

**Expansion — Open space vs shield wall (per user):** Units with lots of space + long-range weapons = easier to avoid engagement/disengage. Shield walls (close proximity, no movement room) = harder to avoid/disengage. Add formation `density` (loose/normal/tight): modulates close attempt (defender evasion) and disengage (defender roll). See `docs/TACTICAL_FORMATIONS_FF4.md` Part 1.

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
- [x] Notes: Control formula: units + adjacent_support - incursion - casualties. Extent shrinks with control. See `docs/TACTICAL_FORMATIONS_FF4.md` for ZoC B vs C clarification (D includes C; no further B vs C choice needed).

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
- [x] Notes: **ZoC D chosen.** Expand formation actions per `docs/TACTICAL_FORMATIONS_FF4.md` (plugging, rank advance, lateral close). Roman/medieval variable system for rotation.

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
- [x] Notes: See `docs/TACTICAL_FORMATIONS_FF4.md` Part 4 and Part 4b. Defense split + awareness_factor(perception) + weapon_position factor (near body vs extended). **Parry choice only when unable to parry both** — run `can_parry_all(incoming, D)` first; if yes, resolve each with parry. If no, `choose_parry_target(incoming)` by threat; resolve chosen first. **Wind-up:** weapon extended after realistic commit point per attack (`state_timer >= wind_up × commit_fraction`); add `commit_fraction` per move (default 0.7). No "full surround" — formation-based.

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
- **Encounter tuning (optional):** world meta **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** — `Dictionary` passed into **`BattleScene.start`** as **`p_encounter`** / read from **`parent_scene`**; seeds **`CombatManager.encounter`** (doctrine, depth polearm AI mults, posture, morale, ambush, …).

**CombatFlow/BattleScene:**
- `battle.start(players, enemies, player_formation_preset, enemy_formation_preset, encounter_preset)`
- **`encounter_preset`:** optional; when empty, **`BattleScene`** may still read **`CombatConstants.WORLD_META_COMBAT_ENCOUNTER`** from **`parent_scene`** (world) if set.
- CombatManager receives formation presets + encounter dict, builds formations, assigns rank/file at **`start()`**
- FormationLayoutBuilder arranges combatant rows in grid by rank/file

---

## Part 5: Implementation Checklist

**For the canonical phase-by-phase checklist and task status, see `docs/COMBAT_ROADMAP_AND_STAMINA.md`.**  
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

### Decision status summary (canonical: `docs/COMBAT_ROADMAP_AND_STAMINA.md` Part 2–3)

| Section | Decision | Status |
|---------|----------|--------|
| **3.2 Distance bands** | Hybrid (C); roll vs evasion; stances | Decided |
| **3.3 ZoC** | Phase 4 | Decided |
| **3.4 Formation actions** | Swap (b+c); Fall back (b+c + drag/step-over); Rotate (b+c) | Decided |
| **3.6 Surround** | Max split divisor **4** (`SURROUND_MAX_SPLIT_DIVISOR`) | Decided (tune in balance) |
| **3.8 Flanking** | Hybrid ZoC + angle; modifiers 0.8/0.7 | Decided (see this bundle, ZoC / engagement sections) |
| **3.9 Event queue** | Agility, then combatant_id | Decided |
| **3.11 Multi-target** | Close slots, AI weighting, defense split max | Deferred to implementation |
| **4.1 Combatant** | weapon_extension | Defer (derive from state per Part 4b) |

---

## Part 7: References

- **`docs/COMBAT_ROADMAP_AND_STAMINA.md`** — Phases, locked decisions, stamina, events (start here).
- **`docs/TACTICAL_FORMATIONS_FF4.md`** — This bundle (FF4 spec + distance/ambush/breakthrough).
- **`docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`** — ZoC, surround, breach migration, formation movement notes.
- `ui/CombatManager.gd` — event-driven combat (`EVENT_ACTION_READY`, queue).
- `combat/AvailableActionsBuilder.gd` — action filtering (distance, formation, breach moves).

---

## Summary

Fill in each **Your decision** section with your chosen option and any constraints. Once complete, this document serves as the spec: implementation follows your choices. Revisit and update as you refine during development.

---

<a id="ff4-formation-distance-ambush-breakthrough-investigation"></a>

## Source: `FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md`

## FF4 Formation: Distance Bands, Ambush, Breakthrough, Surround, Targeting — Investigation

Investigation addressing user decisions for the FF4 Abstract Formation Migration Plan: distance-band expansion (open space vs shield wall), formation shifts (medieval vs Roman), ambush formation impact, surround with perception/awareness and weapon position, breakthrough mechanics, ZoC B vs C given D, and formation-based targeting.

---

### Part 1: Distance Bands Expansion — Open Space vs Shield Wall

**Design goal:** Units with lots of space and long-range weapons should find it easier to avoid engagement and disengage. Units in shield walls (close proximity, limited movement) should find it harder to avoid/disengage.

#### Mechanism: Formation Density + Reach Modifier

Introduce a **formation density** factor that modulates close/disengage difficulty:

| Formation state | Density | Effect on close attempt | Effect on disengage |
|-----------------|---------|--------------------------|---------------------|
| **Open / loose** | Low | Defender evasion × 1.2 (harder to close on them) | Defender disengage × 1.2 (easier for them to break free) |
| **Normal** | Medium | Standard rolls | Standard rolls |
| **Shield wall / tight** | High | Defender evasion × 0.8 (easier to close) | Defender disengage × 0.8 (harder for them to break free) |

**Why it works:**
- **Open space + long reach:** Attacker with spear at mid can keep distance; defender in loose formation has room to sidestep, refuse close, and disengage. High density = low for defender = hard for them.
- **Shield wall:** Units packed; no lateral movement. Attacker finds it easier to close (no dodging room). Defender stuck in striking range; disengage roll penalized (they can't back out without opening a gap).

#### Unit-Level Modifiers

- **Weapon reach:** Long-reach units (spear) at mid get a "keep at bay" bonus: attacker's close attempt has reduced success when defender has spear and is at mid.
- **Armor burden:** Heavy armor in tight formation = even harder to disengage (encumbered, no room to turn).
- **Formation property:** Formation has `density: "loose"|"normal"|"tight"` or 0–1 scale. Derived from: files × ranks, spacing, or explicit template.

#### Data Additions

| Field | Location | Purpose |
|-------|----------|---------|
| `formation.density` | Formation | loose / normal / tight (or 0–1) |
| `formation.reach_modifier` | Formation | Optional: average reach of front rank (spear-heavy vs sword-heavy) |
| `close_evasion_modifier` | Combat resolution | From density; applied to defender evasion in close roll |
| `disengage_modifier` | Combat resolution | From density; applied to defender disengage vs attacker hold |

#### Suggested Implementation

```
# When resolving close attempt:
effective_defender_evasion = defender.evasion * density_modifier(density)
# density_modifier: loose=1.2, normal=1.0, tight=0.8

# When resolving disengage:
effective_defender_disengage = defender.disengage_ability * density_modifier(density)
effective_attacker_hold = attacker.hold_strength / density_modifier(density)  # or inverse
# In tight formation, defender has harder time; attacker's hold is more effective
```

---

### Part 2: Formation Shifts — Medieval vs Roman vs Other Melee

#### Roman System (Maniple / Cohort)

- **Structure:** 10 files × 8 ranks (century); maniple = 2 centuries. Deliberate **gaps between maniples**.
- **Plugging:** Retreating troops fell back *through* gaps; principes advanced into gaps; triarii as final reserve. No lateral shuffle—vertical replacement (rear advances).
- **Rotation:** Hastati → exhausted → fall back through gaps → principes advance → fill line. Rotations were **rank-based**, not file-based.
- **Key:** Gaps were intentional. Death of a front-rank soldier didn't automatically cause incursion—someone behind stepped forward (plugging). Incursion happened when the *whole* unit was pushed back or overrun.

#### Medieval Shield Wall

- **Structure:** Shoulder-to-shoulder; shields overlapping; very tight (0.9–1.2 m per man).
- **Rotation:** Reserved warriors from rear ranks replaced exhausted front through **pre-designated channels** (not random). Footwork synchronized on command.
- **Plugging:** "Striving particularly to prevent a gap being opened." When a man fell, neighbors closed immediately. Gap = catastrophe.
- **Lateral shift:** Some formations had wedge-shaped gaps at 3–4 m for lunging; second rank thrust with shortened spears over shoulders.
- **Key:** Gap management was critical. Rotation was rank-based (reserves advance); file shifts were minimal except when formation curved (convex advance).

#### Common Patterns for a Variable System

| Mechanism | Roman | Medieval | Abstraction |
|-----------|-------|----------|-------------|
| **Death in rank** | Man behind steps up | Neighbors close; reserve fills | Slot: dead stays as ground obstacle (tracked); rank 1 advances over body; footing worse but movement allowed |
| **Plugging** | Principes advance | Immediate lateral close | Roll or automatic: adjacent/reserve fills gap |
| **Rotation** | Exhausted fall back through gaps | Fresh from rear replace front | Rank swap or fall back action |
| **File shift** | Rare (maniples moved as blocks) | Lateral on command for curve | File shift action when formation bends |
| **Incursion** | Enemy pushes whole line | Breach in shield wall | ZoC drops; enemy can occupy |

#### Recommended Variable System for FF4

1. **On unit death in rank 0:** Dead/wounded unit stays tracked in slot as **ground obstacle** (does not block movement). **Plug attempt** (automatic): rank 1 advances into slot, stepping over the body. Footing modifier applies (×1.15–1.25 duration) but movement succeeds.
   - **Roman-style:** Rank 1 (principes) advances into slot. Rotation.
   - **Medieval-style:** Left/right neighbors shift to close gap; reserve fills from rear.
   - **Abstract:** `formation.plug_rule = "rank_advance"|"lateral_close"|"both"`. Default: rank_advance (simplest).
   - **Ground obstacles:** Dead/incapacitated in slot = tracked for awareness (medical, finishing); do NOT block; apply footing modifier when stepping over.

2. **Plugging success:** Not automatic. Roll or threshold:
   - `plug_chance = f(adjacent_units_alive, reserve_units, formation_cohesion)`
   - If plug fails → gap persists → ZoC in that file drops → incursion possible.

3. **Rotation:** Explicit action or triggered by stamina/exhaustion. Rank swap (front ↔ back) or fall back (front → rank 1). Costs action/stamina per plan.

4. **File shift:** For formations that need to "refuse a flank" or curve. Lower priority; add when ZoC + formation actions are solid.

5. **Density:** Formation has `density` affecting distance-band modifiers (Part 1). Tight = shield wall; loose = skirmish.

---

### Part 3: Ambush — Formation Position Impact (Option A Expanded)

**Decision:** Option A (combat start only). Impact on formation position: ambushers spawn in preferred formation; defenders spawn sideways, backwards, or unprepared—with possible exhaustion or other penalties.

#### Implementation

| Ambush state | Ambusher formation | Defender formation | Defender penalties |
|--------------|-------------------|--------------------|--------------------|
| **None** | Normal | Normal | — |
| **Ambush** | Preferred (e.g. deployed, ready) | Misaligned (sideways/backwards) or scrambled | Exhaustion, -evasion, -parry, or skip first N actions |
| **Partial surprise** | Preferred | Some confusion | Lesser penalty (e.g. -parry only) |

#### Formation Orientation

- **Formation facing:** Formation has `facing: "front"|"left"|"right"|"rear"` relative to enemy formation. Normally front.
- **Ambush:** Defender's formation facing = wrong (e.g. rear or flank toward ambushers). So:
  - Rank 0 might be their actual rear rank (weakest in front).
  - Flank files become front files (edge units exposed).
  - ZoC may be computed from wrong direction (rear zone is where enemy is).

#### Data Additions

| Field | Location | Purpose |
|-------|----------|---------|
| `formation.facing` | Formation | front / left / right / rear (relative to enemy) |
| `formation.ambush_penalty` | Encounter | Exhaustion, evasion_mult, parry_mult, or actions_skipped |
| `encounter.ambush_type` | Encounter | none / full / partial |

#### Remove Full Surround

Per user: **Remove plan for full surrounds.** Focus on formation-based combat. Flank/rear access comes from ZoC (when control drops), not from "completely surrounded" as a separate state. Surrounded = multiple zones weak (left + right + rear); treated as ZoC/formation state, not a distinct "surround" mechanic.

---

### Part 4: Surround — Perception/Awareness + Weapon Position

**Decision:** Defense against multiple enemies should use **perception/awareness** stat for debuff. **Weapon position** (extended into opponent's region vs defending personal region) should affect parry. Parries should attempt to meet the weapon at the **defender's zone** so weapon position is accurate.

#### Current System Summary

| Component | Current behavior | Location |
|-----------|------------------|----------|
| **guard_line** | Where defender's blade *is* (high/low/left/right) | Combatant |
| **guard_zone** | Which body part defender protects | Combatant |
| **Parry alignment** | `get_line_alignment(attack_line, guard_line)` — blade meeting geometry | DefenseChoiceResolver |
| **Perception** | Drives `reaction_time` (faster notice = more time to parry) | get_passive_parry_reaction_time |
| **Multi-target** | Not yet implemented; planned defense splitting | STAMINA_SYSTEM |

#### Parry Contact Zone

**Current:** Alignment uses `attack_line` vs `guard_line` (4-line system). The **contact point** is inferred from blade trajectory at `parry_progress` (when defender would meet the blow). `get_arc_angle_at_progress` gives attack angle at contact; `get_guard_angle_deg` gives defender blade angle. These produce an **alignment** (cos θ) for parry capacity.

**"Meet at defender's zone":** The path resolution uses `(attack_line, guard_line)` to get hit path. The parry is resolved as if blades meet in a **shared space**. The defender's `guard_line` already represents "where my blade is" — so the contact is implicitly in the space between them. To make it explicit:
- **Defender's zone:** Blade in personal space (defensive posture) = better parry (full capacity).
- **Extended into opponent's zone:** Blade forward, in their reach = weaker parry (contact happens on weak part, less control).

**Proposed:** Add `weapon_zone: "personal"|"extended"` or a scalar `weapon_extension 0–1`:
- **Personal (0):** Defender's weapon in guard position near body. Parry meets in defender's zone. Full alignment benefit.
- **Extended (1):** Defender's weapon forward (e.g. after attack, or overcommitted). Parry contact in no-man's-land or attacker's zone. Reduce parry capacity (e.g. ×0.85) — weaker control, contact further from strong.

**When is weapon extended?** After attacker's own attack (blade in opponent's reach); or when `guard_line` was set from a thrust that ended forward. Could derive from `last_move_id` and move geometry.

#### Perception/Awareness for Multi-Target

When defender faces **multiple close attackers** (`num_close_threats > 1`):

1. **Defense split:** `parry_capacity /= clamp(num_close_threats, 1, N)` — already in plan.

2. **Awareness modifier:** `effective_parry_capacity *= awareness_factor`
   - `awareness_factor = lerp(0.6, 1.0, perception_norm)` or similar.
   - Low perception = harder to track multiple threats = additional debuff.
   - High perception = better situational awareness = less debuff from multi-target.

3. **Combine:** `parry_capacity = base * (1/num_threats) * awareness_factor * weapon_zone_factor`

#### Data Additions

| Field | Location | Purpose |
|-------|----------|---------|
| `combatant.weapon_extension` | Combatant | 0–1 or "personal"|"extended"; from last action geometry |
| `perception` (existing) | Stats | Used for awareness_factor in multi-target |
| Optional: `awareness` | Stats | If distinct from perception (situational awareness) |

#### Comparison to Current

| Aspect | Current | Proposed |
|--------|---------|----------|
| Parry alignment | attack_line vs guard_line; angle at contact | Same + weapon_zone (personal vs extended) mod |
| Multi-target | Not implemented | Defense split + perception/awareness mod |
| Contact zone | Implicit (between combatants) | Explicit: prefer defender's zone; extended = penalized |
| Perception | Reaction time only | Also awareness_factor when multiple threats |

**Implementation order:** Add defense split first; then awareness mod; then weapon_extension when weapon position tracking is ready.

---

### Part 4b: Weapon State Expansion — Near Body vs Extended + Multi-Attack Parry Choice

**Decision:** Expand weapon position tracking so weapon state (near body vs extended) is driven by combat state. When multiple attacks incoming, defender chooses which to parry, prioritizing more damaging (e.g. overhead sword vs quick dagger slash).

#### Weapon Position by Combat State

| Combat state | Weapon position | Rationale |
|--------------|-----------------|-----------|
| **WAITING** | Near body | Guard; blade in defensive posture |
| **WIND_UP** (early) | Near body | Blade coiling; hasn't committed |
| **WIND_UP** (late, past commit) | Extended | Blade committing toward target; switch at realistic point per attack |
| **RECOVERING** (from attack) | Extended | Blade was swung/thrust; now returning — away from body until recovery done |
| **RECOVERING** (from parry) | Near body | Parry met attack; blade is in place (guard_line set) — near defender's zone |
| **Intercepting** (parrying) | Near body | Defender commits blade to meet attack — blade moves toward contact point |

**Refinement — Wind-up commit point:** During **wind-up**, the weapon is near body until a **realistic commit point** — when the blade would physically leave guard and extend toward target. Each attack type has a commit fraction (e.g. 0.6–0.8 of wind_up): before that, blade near body; after that, extended. So:
- **Extended:** STATE_RECOVERING from own attack; or STATE_WIND_UP with `state_timer >= wind_up_duration × COMMIT_FRACTION` (blade has committed).
- **Near body:** WAITING; WIND_UP before commit; RECOVERING from parry; intercepting.

**Commit fraction per move:** Add `commit_fraction` to move definition (0–1). Default e.g. 0.7 — at 70% of wind-up, blade extends. Thrusts may commit earlier (0.6); heavy swings later (0.8).

#### Derivation (No Redundant Storage)

```gdscript
# is_weapon_near_body(combatant) -> bool
# true = near body (full parry capacity); false = extended (×0.85 or similar)
static func is_weapon_near_body(c: Dictionary) -> bool:
    var state: String = c.get("state", "")
    if state == CombatConstants.STATE_WAITING:
        return true
    if state == CombatConstants.STATE_WIND_UP:
        # Past commit point? Blade has extended toward target.
        var pa: Dictionary = c.get("pending_attack", {})
        if not pa.is_empty():
            var wind_up: float = pa.get("wind_up_duration", 0.5)
            var timer: float = c.get("state_timer", 0.0)
            var commit_frac: float = pa.get("commit_fraction", 0.7)
            if wind_up > 0 and timer >= wind_up * commit_frac:
                return false  # Extended
        return true
    if state == CombatConstants.STATE_RECOVERING:
        # Recovering from parry? Blade was in place — near body.
        if c.get("recovery_cause", "") == "parry_deflect" or c.get("recovery_cause", "") == "parry_partial":
            return true
        # Recovering from own attack (miss, hit, deflect) — blade was extended
        if c.get("last_move_id", ""):  # Had an attack
            var move_def = WeaponConstants.get_move(c.last_move_id)
            if move_def.get("contact_type", "") == WeaponConstants.ATTACK_TYPE_STAB:
                return false  # Thrust ends extended
            return false  # Cuts also end extended during recovery (blade was out)
    return true  # Default: near body
```

#### Multi-Attack Parry Choice

**Parry choice applies only when the defender cannot successfully parry both attacks.** If they have enough capacity and time to parry all incoming attacks in the window, they do so—no choice needed. Choice triggers only when forced to pick.

When **multiple attacks** would land on the same defender in a short window (overlapping wind-ups, simultaneous or near-simultaneous resolve):

1. **Batch identification:** `get_incoming_attacks_on(defender)` — attacks with defender as target whose `resolve_at` is within a small window (e.g. 0.2 s) of each other or of current time.
2. **Can-parry-both check:** Compute whether defender can parry all incoming (capacity split across threats, reaction time for each, weapon near body). If yes → resolve each with parry option; no choice.
3. **If unable to parry both:** Defender selects **which attack to parry** based on **threat priority** (more damaging = higher). Others get dodge or hit. Parry "commits" the blade. If able to parry both → no choice; resolve each with parry.
4. **Resolution:** For chosen attack (when choice applied): resolve parry/dodge as normal. For others: defender uses dodge or takes hit. Resolve chosen first; then others with parry unavailable.

**Threat scoring options:**
- **A: Momentum-based:** `threat = parry_p_a` (attack momentum). Simple; overhead sword >> dagger.
- **B: Expected damage:** `threat = estimated_damage_on_hit` (weapon, intensity, target part). More accurate.
- **C: Combined:** `threat = parry_p_a * damage_weight + (1 - parry_remaining_if_partial)` — prioritize attacks that would hurt most and are hardest to partially deflect.

**Implementation flow:**
- When processing EVENT_MELEE_ATTACK for attacker A on defender D:
  - Check `incoming = get_incoming_attacks_on(D)` (attacks on D with resolve_at within window).
  - If `incoming.size() > 1`: run `can_parry_all(incoming, D)` — capacity split, reaction time, weapon position. If yes → resolve each with parry; no choice.
  - If `incoming.size() > 1` and **cannot** parry all: `choose_parry_target(incoming, D)` by threat score; resolve chosen first with parry; others with parry unavailable.

#### Parry System for Multiple Attacks — Correct Position

- **Weapon must be near body** for full parry capacity. If extended (recovering from own attack), parry gets ×0.85.
- **When multiple incoming:** Defender's weapon can only be in **one** position to intercept. Choosing to parry attack A means the blade is committed to that line. Attack B (from different angle) may require different guard_line — defender cannot be in two places. So:
  - **Defense split** already divides capacity across threats.
  - **Parry choice** means we commit to one. The chosen parry uses full (split) capacity for that one attack; others get dodge or no defense.
  - **Guard line:** When we choose to parry A, we set our intent to meet A's attack_line. So the defender's "effective guard" for this moment is aligned with the chosen parry target. Other attacks see defender's guard as misaligned (worse parry or no parry) — they get dodge/take hit.

#### Data Additions

| Field | Location | Purpose |
|-------|----------|---------|
| `parry_target_attacker_id` | Defender (during resolution) | When multiple incoming: which attacker we chose to parry |
| `incoming_attacks` | Helper | Attacks on defender with resolve_at in window |
| Move def: `ends_extended` | WeaponConstants | true for thrusts; infer for cuts |
| `WEAPON_EXTENDED_PARRY_MULT` | Constants | e.g. 0.85 when weapon extended |

#### Integration Checklist

- [ ] Add `is_weapon_near_body(c)`; call in DefenseChoiceResolver when computing parry_c_d.
- [ ] Add `get_incoming_attacks_on(defender)` using event queue lookahead or pending-attack scan.
- [ ] When multiple incoming: `choose_parry_target(incoming, defender)` by threat score; resolve chosen first.
- [ ] Ensure recovery_cause is set when entering RECOVERING (parry vs attack).
- [ ] Guard line intent: when parry choice made, defender's effective guard aligns with chosen attack's line for that resolution.

---

### Part 5: Breakthrough — Death, ZoC, Strength, Roll

**Decision:** Breakthrough can happen when:
1. Enemy dies, AND
2. Defender's ZoC is low enough, AND
3. Incurring unit is strong enough (e.g. heavily armored).
4. **Not automatic:** Unit must **choose to push** (roll or decision). Strong/overconfident units more likely to push; cautious units may hold. Prevents overextension.

**Plugging:** Enemies try to plug formations when possible. Death does **not** automatically cause incursion—allies plug first. Incursion happens when plug fails AND pusher is strong enough AND pusher decides to push.

#### Flow

1. **Unit in rank 0 dies** → slot opens.
2. **Plug attempt:** Allies (adjacent file or rank 1) attempt to plug. Roll or automatic based on formation state.
3. **If plug succeeds:** Slot filled. No incursion.
4. **If plug fails (gap persists):** Check incursion eligibility.
5. **Incursion eligibility:** Attacker side has unit adjacent to gap. Unit's strength/armor meets threshold. Defender's ZoC in that sector < threshold.
6. **Push decision:** Unit rolls or chooses "push forward." Factors:
   - **Overconfidence:** Trait or morale?
   - **Strength/armor:** Heavy units more likely to push.
   - **Stamina:** Low stamina = less likely (risk of overextension).
   - **Situation:** Allies supporting? ZoC very low? More likely.
7. **Push roll:** Success → unit occupies slot (incursion); ZoC shifts. Failure → unit stays; may take penalty (exposed) or no effect.

#### Data Additions

| Field | Location | Purpose |
|-------|----------|---------|
| `formation.gap_slots` | Formation | (rank, file) slots that are empty (death, no plug) |
| `push_threshold_strength` | Constants | Min strength/armor to be eligible |
| `zoc_incursion_threshold` | Constants | ZoC below this allows incursion |
| `combatant.push_tendency` | Combatant | 0–1 or trait; for push decision roll |

---

### Part 6: ZoC B vs C Given D

**User chose D (Full ZoC).** So the B vs C question is redundant at the top level—D **includes** C-style zone control (and more). 

**Clarification:**
- **B (File weakness only):** No zone control; flank = static file property. Would be a *simplification* or *fallback* if Full ZoC is too complex.
- **C (Zone control strength):** Zones have 0–1 control; flank when below threshold. This is a **core part of D**.
- **D (Full ZoC):** C + extent + formula (units + support - incursion - casualties).

**Conclusion:** With D chosen, you have committed to zone control strength (C) plus extent and full formula. B is not needed unless you later simplify. No further B vs C decision required.

---

### Part 7: Formation-Based Targeting

**Decision:** Targeting should be based on **formation vs enemy formation positioning**. Units can only engage units **realistically near them** and **help allies**. Incursions and lateral movement based on gaps and formation positioning.

#### Engagement Constraints

| Constraint | Rule |
|------------|------|
| **Adjacency** | Unit at (rank R, file F) can only melee targets in **opposing formation** at (rank 0, file F±1) or (rank 0, file F) — i.e. directly opposite or one file over. |
| **Range** | Ranged: can target any enemy in range; may have formation-based modifiers (e.g. front rank blocks line of sight for back rank). |
| **Incursion** | If unit has occupied enemy zone (breakthrough), they can target units in that zone and adjacent. |
| **Helping allies** | Unit can choose to support adjacent ally (e.g. parry for them, or attack their attacker) — requires adjacency in formation. |

#### File/rank mapping

```
Our formation:     Their formation:
  [R1]  [R1]  [R1]    [R1] [R1] [R1]
  [R0]  [R0]  [R0] vs [R0] [R0] [R0]
   F0    F1    F2      F0   F1   F2

Our (R0,F1) can melee: their (R0,F0), (R0,F1), (R0,F2) — opposite and adjacent files.
Our (R1,F1) can: support our (R0,F1); ranged attack any in range; or wait.
```

#### Gaps and Lateral Movement

- **Gap in our formation:** Unit in adjacent file can "shift" to cover (lateral move) — costs action or happens automatically as plug?
- **Gap in their formation:** Our unit can attempt breakthrough (incursion) into that gap.
- **Lateral movement:** Unit in file F can move to F±1 if slot free (formation action).

#### Data Required for Implementation

| Data | Location | Purpose |
|------|----------|---------|
| `combatant.rank` | Combatant | Row |
| `combatant.file` | Combatant | Column |
| `formation.files` | Formation | Width |
| `formation.ranks` | Formation | Depth |
| `formation.slots` | Formation | (rank, file) → combatant_id or null (primary occupant) |
| `formation.slot_obstacles` | Formation | (rank, file) → Array of combatant_ids (dead/incapacitated on ground; tracked, non-blocking) |
| `combatant.occupied_zone_id` | Combatant | If incursion: which enemy zone we occupy |
| `get_engageable_targets(combatant)` | Helper | Returns enemy combatants this unit can legally engage (by file/rank/zone) |
| `get_supportable_allies(combatant)` | Helper | Returns allied combatants this unit can help (adjacent) |
| `formation.gaps` | Formation | Set of (rank, file) that are open (no plug) |

#### AvailableActionsBuilder Changes

- **Before:** `get_available_actions` returns all enemies as potential targets.
- **After:** Filter by `get_engageable_targets(c)`. Only include enemies in valid (file, zone) positions.
- **Melee:** Must be at close AND in engageable file/zone.
- **Ranged:** Must have line of engagement (no blocking allies? or abstract "in arc").

---

### Part 8: Remaining Data Structure Decisions

#### 4.1 Combatant Additions (Concluded)

Given all decisions:

| Field | Add? | Purpose |
|-------|------|---------|
| `rank` | Yes | Row |
| `file` | Yes | Column |
| `formation_id` | Yes | Which formation |
| `distance_to` | Yes | target_id → band (pair-wise or from zone) |
| `engaged_with_id` | Yes | Engagement |
| `engagement_angle` | Yes (if ZoC) | front/flank/rear from zone |
| `zone_id` | Yes (Full ZoC) | Which zone in formation |
| `weapon_extension` | Defer or add | Personal vs extended for parry |
| `occupied_zone_id` | Yes (incursion) | Enemy zone we've broken into |
| `push_tendency` | Optional | For breakthrough decision |

#### 4.2 Formation Structure (Concluded)

| Field | Add? | Purpose |
|-------|------|---------|
| `files` | Yes | Width |
| `ranks` | Yes | Depth |
| `density` | Yes | loose/normal/tight (distance mods) |
| `zone_control` | Yes (ZoC) | Zone → 0–1 |
| `side` | Yes | player/enemy |
| `facing` | Yes (ambush) | front/left/right/rear |
| `slots` | Yes | (rank, file) → combatant_id |
| `slot_obstacles` | Yes | (rank, file) → Array of combatant_ids (dead/incapacitated; non-blocking, footing modifier) |
| `gaps` | Yes (breakthrough) | (rank, file) open slots |
| `plug_rule` | Yes | rank_advance / lateral_close / both |

#### 4.3 Manager Additions (Concluded)

| Field | Add? | Purpose |
|-------|------|---------|
| `event_queue` | Yes | Min-heap |
| `combat_clock` | Yes | float |
| `formations` | Yes | Array of formation dicts |
| `distance_bands` | Optional | If not per combatant |
| `encounter.ambush_type` | Yes | none/full/partial |
| `encounter.ambush_penalty` | Yes | Formation facing + penalties |

---

### Part 9: Addendum — Stats, Plug Contest, Weapon Position, Morale, Targeting

#### 9.1 Distance Bands: Concrete Numbers vs Generic Densities

**Question:** Can we use concrete numbers (stats-based) for distance bands, or stick to generic densities?

**Both are possible.** Tradeoffs:

| Approach | Mechanism | Pros | Cons |
|----------|------------|------|------|
| **Generic density** | loose/normal/tight → ×0.8–1.2 modifiers | Simple; already in plan. Works for close/disengage. | Doesn't model phalanx (0.9m) vs loose (2m) actual reach. |
| **Concrete numbers** | `effective_distance_cm = formation_spacing_m × 100` between slots; weapon.melee_range (m); compare | Phalanx vs loose differentiated; spear vs dagger reach explicit. | Needs formation.spacing_m, slot-to-slot distance formula. |

**Recommendation:** Start with **generic density** for close/disengage modifiers. Add **concrete spacing** when you need loose vs phalanx to affect targeting (see 9.5). Weapons already have `melee_range` (m); formation can add `spacing_m` (e.g. phalanx 0.9, normal 1.2, loose 1.8). Derive effective distance between slot pairs; filter engageable targets by `weapon.melee_range >= effective_distance`.

---

#### 9.2 Plug Rule + Incursion Contest, Historical Balancing

**Decision:** Implement plug rule; opponents can contest with incursions if strong enough. Incursions should **not** be normal.

**Historical context:**
- Roman/maniple: Gaps were plugged by principes advancing. Breaches occurred when whole line was pushed or flanked—rare within single engagement.
- Medieval shield wall: "Striving particularly to prevent a gap being opened." Cohesion loss = catastrophic. Wedge assaults (boar snout) could force breaches at weak points.
- Incursions were **decisive events**, not frequent. Most slot-open events were plugged; incursion = sustained pressure, wedge assault, or morale collapse.

**Balancing targets:**
- **Plug success rate:** 75–90% when reserves/adjacent present and morale ok. Plug fails when: low morale, no reserves, contested by strong pusher.
- **Incursion rate:** Aim for **<15–20%** of gap-open events resulting in incursion. Achieved by: (1) plug attempt first; (2) incursion only when plug fails OR pusher contests plug; (3) pusher must be strong enough; (4) ZoC low enough; (5) push decision roll.

**Contest mechanic:** When slot opens, **both** plug attempt and incursion attempt can occur. Resolution:
- **Plug uncontested:** Allies roll to plug; success → gap filled. No incursion.
- **Plug contested:** Pusher (opponent adjacent to gap) rolls to push. Opposing plug roll vs push roll. Higher wins. If push wins and eligibility met → incursion. If plug wins → gap filled.
- Strong pusher gets bonus to push roll; low defender morale penalizes plug roll. So incursion more likely when formation is battered, but still not common.

---

#### 9.3 Weapon Position: Redundancy and Integration Check

**Question:** Is weapon_extension redundant? Does it integrate correctly?

**Current system:**
- `guard_line` = blade **angle** (high/low/left/right) — which 4-line direction
- `guard_zone` = which body part defender protects
- Alignment = `attack_line` vs `guard_line` (cos θ)
- `guard_line` updates: attack recovery → attack_line; parry → deflect geometry

**weapon_extension (proposed):** Blade **distance** — personal (near body) vs extended (forward). Different dimension from guard_line. guard_line = angle; weapon_extension = radial. Not redundant.

**When is blade extended?**
- After **thrust**: blade ends forward in opponent's reach. `contact_type == "stab"` or move has `ends_extended: true`.
- After **cut that ends forward** (e.g. long slash): rarer; could use `ends_extended` per move.
- When **WAITING** or just parried: blade in guard = personal.
- When **RECOVERING** from thrust: blade was forward = extended until recovery done.

**Integration (avoid redundancy):** Derive `weapon_extension` — do **not** store separately if derivable.
- `is_weapon_extended(combatant) = (state == RECOVERING and last_move.contact_type == "stab") OR (state == RECOVERING and WeaponConstants.get_move(last_move_id).get("ends_extended", false))`
- When recovery completes, `set_guard_from_move` runs — blade returns to guard. So extended only during recovery from thrust (or similar).
- Add `ends_extended` to thrust moves in WeaponConstants (true for thrust, false for cuts by default). No new stored field; compute when needed for parry mod.

**Use point:** In DefenseChoiceResolver, when computing parry_c_d for multi-target: `parry_c_d *= 0.85 if is_weapon_extended(tgt) else 1.0`. Only apply when num_close_threats > 1, or always (both acceptable).

**Double-check:** guard_line and guard_zone are used for alignment and path. weapon_extension is a **multiplier** on parry capacity when blade is forward (weaker control). No overlap. Integration: add one function `is_weapon_extended(c)`; call in defense choice when multi-target or always; no new persistent field needed.

---

#### 9.4 Breakthrough Contests Plugging; Morale

**Decision:** Breakthrough should **contest** plugging (not just happen when plug fails). Morale stat needed for formation and individual to handle dynamic formation positioning and decision making.

**Contest flow (revised):**
1. Unit in rank 0 dies → slot opens.
2. **Plug attempt** by allies (roll based on reserves, adjacent, **morale**).
3. **Incursion attempt** by opponent adjacent to gap (if eligible: strength, ZoC). Roll to push.
4. **Contest:** If both attempt same slot, compare rolls. Plug wins → slot filled. Push wins (and meets thresholds) → incursion.
5. Morale affects: plug success (low morale → worse plug roll), push decision (low morale → less likely to push; high morale/overconfidence → more likely).

**Morale data:**
- `formation.morale` — 0–100 or 0–1. Drops with casualties, failures, time. Affects plug success, possibly rotation willingness.
- Optional: `combatant.morale` — individual. Can differ from formation (rout vs hold). For now, formation-level sufficient; individual can inherit.
- Morale recovers: slowly (rally action, reserves arriving, victory).

**Formation positioning / decision making:**
- Low morale → less likely to plug (wavering), less likely to push (fear), more likely to fall back.
- High morale → better plug, more aggressive push.
- Use morale in: `plug_roll_modifier`, `push_tendency_modifier`, future rotation/fall-back decisions.

---

#### 9.5 Rank/File Targeting: Weapon Reach and Formation Extent

**Question:** Does the proposed system need changes so weapon reach and ZoC extent affect formation targeting for different physical distances (loose vs phalanx)?

**Current proposal:** Unit at (R,F) can melee opposing rank 0, file F±1. No reach or spacing check.

**Gap:** Phalanx spacing ~0.9 m per man. Loose formation ~1.8–2 m. "Opposing file F" in phalanx = ~0.9 m away (in range for dagger 0.8 m, sword 1.5 m, spear 2.5 m). "Opposing file F" in loose = ~2 m away — dagger and sword may be out of range; spear still ok.

**Required changes:**
1. **Formation spacing:** Add `formation.spacing_m` or derive from density (tight=0.9, normal=1.2, loose=1.8). Or `formation.width_m` total / files.
2. **Effective distance between slots:** `effective_distance(us_file, them_file) = |us_file - them_file| * (our_spacing + their_spacing) / 2` or similar. Center-to-center between formations.
3. **Weapon reach check:** `can_engage = file_adjacent AND weapon.melee_range >= effective_distance * REACH_SAFETY_FACTOR`. REACH_SAFETY_FACTOR accounts for body depth, zone extent (e.g. 0.8).
4. **ZoC extent:** When ZoC is strong, zone extent grows — we "reach" further (control more space). When weak, extent shrinks. `effective_distance` could be reduced by `our_zone_extent` or increased when our ZoC is weak (we're pushed back). Formula: `required_reach = effective_distance - our_zone_extent + their_zone_extent` or similar. Start simple: `required_reach = effective_distance`.

**Conclusion:** The proposed system is **not** robust for loose vs phalanx without:
- `formation.spacing_m` (or density → spacing)
- `effective_distance_between_slots(us, them)`
- `weapon.melee_range >= effective_distance` filter in `get_engageable_targets`

Add these. ZoC extent can refine later (strong ZoC = we project further = can engage from slightly further).

---

#### 9.6 Other Changes or Clarifications

| Item | Recommendation |
|------|----------------|
| **Distance bands option** | Still open: pair-wise vs zone-based vs hybrid. Zone-based fits Full ZoC; pair-wise simpler for Phase 2. |
| **Formation actions** | Swap rank, fall back, rotate — expand per Part 2 (Roman/medieval). Morale affects willingness. |
| **Flanking** | Option still open. With ZoC D, ZoC-based (C) or engagement_angle (B) both work. |
| **Event queue tie-break** | Agility, then combatant_id. Document in constants. |
| **Phase ordering** | Phase 4 (ZoC) before Phase 5 (formation actions). Phase 6 tactical features. |

---

### References

- `docs/TACTICAL_FORMATIONS_FF4.md`
- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`
- `docs/COMBAT_ROADMAP_AND_STAMINA.md`
- `combat/DefenseChoiceResolver.gd` — parry, guard_line, guard_zone
- `combat/CombatConstants.gd` — GUARD_ZONE_*, alignment
- `weapon/WeaponConstants.gd` — melee_range, move contact_type
- Historical: Roman maniple tactics; medieval shield wall (Acoup, Phalantry); breach frequency (rare, decisive)

---
