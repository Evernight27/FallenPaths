# Combat Roadmap And Stamina

Consolidated documentation. Each section keeps its **original filename** in the `Source` line for provenance.

## Contents

1. [IMPLEMENTATION_OUTLINE.md](#implementation-outline)
2. [STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md](#stamina-system-implementation-plan)
3. [STAMINA_CURVE_HEMA_COMBAT_PACING_INVESTIGATION.md](#stamina-curve-hema-combat-pacing-investigation)
4. [STAMINA_VS_FITNESS_FORMATION_INTEGRATION_INVESTIGATION.md](#stamina-vs-fitness-formation-integration-investigation)
5. [BACK_RANK_WAIT_EVENT_LISTENER_VS_FIXED_COOLDOWN_INVESTIGATION.md](#back-rank-wait-event-listener-vs-fixed-cooldown-investigation)
6. [MODULARIZATION_POSSIBILITIES.md](#modularization-possibilities)
7. [COMBAT_SYSTEM_ISSUES.md](#combat-system-issues)
8. [ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md](ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md) — line cohesion, posture (LINE/OPEN/DUEL), intrusion geometry, crash neighbor hold

---

## Master implementation order

**Use [`IMPLEMENTATION_ORDER.md`](IMPLEMENTATION_ORDER.md)** for the **cross-plan sequence** (Tier 0 → 7): engagement geometry (P3+), tactical doc sync, parry stack, AI, physics, medical, research.

This file’s **Part 1** table is the **historical phase map** (0–6) embedded in the consolidated roadmap; **active** formation/breach/cohesion work follows **Tier 1** in `IMPLEMENTATION_ORDER.md` and detail in `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`.

**Plans vs repo:** Tier tables and engagement checklists were **reconciled with the codebase on 2026-04-07**. Part 3 checklist below was **aligned to shipped code** in the same pass (formation dict, incursion, hybrid gauge). Historical **stamina migration** prose farther down may still describe an alternate design — see **Current architecture snapshot** and the **Archived** banner on the stamina plan section.

---

## Current architecture snapshot (shipped, 2026)

Use this as the **source of truth** for what the repo does today. For **what to build next**, use `docs/IMPLEMENTATION_ORDER.md` and `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`.

| Layer | Behavior |
|-------|----------|
| **Time / turns** | `CombatManager`: `combat_clock`, min-heap **`event_queue`**, **`CombatEventScheduler`** / **`CombatProcessTick`**. Per-combatant **`gauge`** fills toward **`EVENT_ACTION_READY`** (hybrid model — gauge was **not** removed). |
| **Combatant** | `STATE_WAITING` (and wind-up / medical / formation-move states as applicable), `rank` / `file` / `formation_id`, `distance_to`, stances, stamina, **`tactical_penetration_depth`**, **`crash_cooldown_until`**, **`engagement_role`**, **`intrusion_host_fid`**, **`intrusion_anchor_file`**. |
| **Formations** | `formations[fid]`: `files`, `ranks`, `density`, `slots`, `slot_obstacles`, `zone_control`, `breached_files`, **`incursion_pressure`** (recomputed), **`line_cohesion`**, **`engagement_posture`**, **`morale_cohesion_factor`**. |
| **ZoC & incursion** | **`ZoneOfControl.recompute_all`**; **`TacticalCombat.recompute_incursion_pressure`** (rank-0 imbalance) feeds **`incursion_pressure`** into raw zone strength. |
| **Crash / breach** | **`BreachResolver.contest_crash`**, **`CombatEngagementResolver.resolve_crash_attempt`**; defender **`breached_files`**; **`CombatIntrusionGeometry.crash_neighbor_hold_support`** on hold. |
| **Skirmish / clog** | **`FormationBreachRules`**: `breach_blocks_open_lane_moves` + **`FEATURE_SKIRMISH_UNCLOG_BREACH_MOVES`**. |
| **Engagement UI** | **`CombatFormationEngagement.recompute_all`**; **`CombatManager.engagement_state_changed`**; **`BattleScene`** formation labels. |
| **Medical** | Medical phase + coordination modules unchanged in scope here. |

---

**Doc map:** `IMPLEMENTATION_ORDER.md` · `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` · `PHYSICS_DAMAGE_AND_FLOW.md` · `TACTICAL_FORMATIONS_FF4.md` · `TACTICAL_ZONES_BREACH_MOVEMENT.md` · `PARRY_BIND_AND_WEAPON_GEOMETRY.md` · `PARRY_DEFLECT_AND_CALIBRATION.md` · `GUARDS_LINES_AFTERBLOW.md` · `AI_ENGAGEMENT_STANCE_AND_FEINTS.md` · `HEMA_ROADMAP_AND_SOURCES.md` · `MEDICAL_PAIN_INCAPACITATION.md`

<a id="implementation-outline"></a>

## Source: `IMPLEMENTATION_OUTLINE.md`

# FF4 Formation + Stamina System — Consolidated Implementation Outline

Master implementation guide for the combat system migration. Consolidates decisions from the FF4 checklist, migration plan, stamina plan, and investigation docs.

---

## Part 1: Implementation Order

| Phase | Focus | Depends On | Key Deliverables |
|-------|-------|------------|------------------|
| **0** | Prep: data structures, constants | — | Combatant fields, formation structure, event queue |
| **1** | Event queue + action ready | Phase 0 | Min-heap, `EVENT_ACTION_READY`, **gauge** hybrid, stamina UI |
| **2** | Distance bands | Phase 0 | Close/mid/long, roll vs evasion to close |
| **3** | Formations | Phase 0, 1 | Rank/file, targeting filter, swap rank, plug on death |
| **4** | Zone of control (ZoC) | Phase 3 | Zone control, flank access, engagement angle |
| **5** | Formation actions | Phase 3 | Fall back, rotate, drag back, step over; swap rank lane_clarity + pressure_mod |
| **6** | Tactical features | Phase 3–4 | Ambush, surround, incursion pressure, flanking (ZoC) |
| **7** | Engagement geometry (ongoing) | Phase 3–6 | Line cohesion, posture, crash neighbor hold, intrusion slots/distance — `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`, `docs/IMPLEMENTATION_ORDER.md` Tier 1 |

---

## Part 2: Locked Decisions Summary

### Distance Bands
- **Model:** Hybrid (C) — pair-wise for unformed, zone-based for formations
- **Close attempt:** Roll vs evasion (engagement_pressure vs defender evasion). Tie in stats. **Stances** modify close, damage, parry, disengage. See `docs/AI_ENGAGEMENT_STANCE_AND_FEINTS.md`.

### Stance System (Phase 0 Data, Phase 2 Effects)
- **Four stances:** Defensive, Balanced, Aggressive, Controlling.
- **Driven by:** Stamina (gates), personality/trait (preference), weapon/skill, situation.
- **Effects:** Parry ×1.2/×0.8, evasion ×1.15/×0.85, damage ×0.85/×1.2, close attempt ×0.9/×1.1. **Controlling** makes opponent's disengage/close harder (×0.85, ×0.9).
- **Stamina gates:** Aggressive min 20–30; Controlling min 15–25. Below min → revert to balanced/defensive.

### ZoC
- **Phase:** 4 (after formations)
- **Type:** Full ZoC (D) — control = units + adjacent_support − **incursion** (rank-0 imbalance) − casualties / lane stress / breach local stress (`ZoneOfControl` + `TacticalCombat.recompute_incursion_pressure`)

### Formation Actions (Movement — Time-Based)
- **Swap rank / Fall back:** Time-based, **no stamina cost**. Duration = base × lane_modifier × pressure_modifier. See `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`.
  - **Lane clarity:** clear=1.0×, crowded=1.3×, blocked=1.6× (or roll to succeed when blocked).
  - **Opponent pressure:** defensive=0.9×, neutral=1.0×, aggressive=1.3×. Aggressive = high stamina + actively attacking.
  - **Formula:** `duration_s = BASE_FALL_BACK_S × agility_factor × armor_factor × lane_mod × pressure_mod`
  - During move: unit in STATE_FALLING_BACK / STATE_SWAP_RANK; vulnerable to attacks; hit may interrupt.
- **Fall back:** (b)+(c) plus drag back, step over, multi-unit same slot with deficits
- **Rotate:** Rank shift primary; both file and rank shift; leader abilities deferred
- **Disengagement:** Logic based on health, morale, formation structure (investigate fall back vs fight to death vs rout)

### Formation Targeting
- **spacing_m:** (b) Derive from density — tight=0.9, normal=1.2, loose=1.8
- **effective_distance:** `|Δfile| × avg_spacing` (simple; refine later)
- **REACH_SAFETY_FACTOR:** 0.8
- **Engagement restriction:** Formation position + weapon range; parry deficit to awareness later

### Flanking
- **Approach:** ZoC-based for formation vs formation; engagement angle fallback for pack vs formation (see investigation)
- **Modifiers:** Front 1.0, Flank 0.8, Rear 0.7 (placeholders)

### Event Queue
- **Tie-break:** Agility, then combatant_id

### Weapon State
- **commit_fraction:** Per move (default 0.7; thrusts 0.6; heavy swings 0.8)

### Formation UI & Presets (Phase 3)
- **Visual representation:** Battle UI shows formations as rank×file grids; unit spacing reflects density (tight/normal/loose). FormationLayoutBuilder arranges combatant rows in grid; FormationDiagramBuilder provides compact diagram (Front/Back) that updates on formation_changed. Spacing constants: `SPACING_TIGHT`→compact, `SPACING_NORMAL`→default, `SPACING_LOOSE`→wide.
- **Formation preset:** `{ files: int, ranks: int, density: "tight"|"normal"|"loose" }`. Defines layout before combat.
- **Party formation:** Set on party (PartyManager or world meta). Default: 2×ceil(n/2), normal density.
- **Enemy formation:** Set per encounter or derived from count. Default: 2×ceil(n/2), normal density.
- **CombatFlow/BattleScene:** Pass `player_formation` and `enemy_formation` presets to `manager.start()` or `battle.start()`; CombatManager builds `formations` and assigns rank/file to combatants.

---

## Part 3: Phase Tasks (Checklist)

### Phase 0: Prep
- [x] Add formation/rank/file constants to CombatConstants (spacing, REACH_SAFETY_FACTOR, stances, movement duration)
- [x] Add combatant fields: rank, file, formation_id, distance_to, engaged_with_id, engagement_angle, zone_id, occupied_zone_id, stance, stance_preference; plus breach/incursion **`tactical_penetration_depth`**, **`crash_cooldown_until`**, **`engagement_role`**, **`intrusion_host_fid`**, **`intrusion_anchor_file`**
- [x] Add formation structure (inline dict): `files`, `ranks`, `density`, `slots`, `slot_obstacles`, `zone_control`, `breached_files`, `line_cohesion`, `engagement_posture`, `morale_cohesion_factor`; **`incursion_pressure`** set at runtime by `TacticalCombat.recompute_incursion_pressure` (see `CombatFormationSetup.gd`)
- [x] Add event_queue (array → min-heap in Phase 1), combat_clock to CombatManager
- [x] Add encounter dict (ambush_type, ambush_penalty)

### Phase 1: Event Queue
- [x] Implement min-heap event queue processing
- [x] `EVENT_ACTION_READY` → turn_ready / AI pick
- [x] **Hybrid ready path:** combatant **`gauge`** fills to 100 → `EVENT_ACTION_READY` scheduled (not a pure “remove gauge” migration); wind-up / medical / formation-move states still use timing labels on the same bar row (`BattleUIUpdater`)
- [x] **UI:** Progress bar shows **stamina** (0–100) on the legacy `gauge` widget; text label shows ready vs wind-up / medical / swap / fall back
- [x] **Hybrid event model:** Signals (`formation_changed`, `turn_resolved`, …) drive scheduling; `_schedule_action_ready` centralizes ACTION_READY with cancel-before-schedule to avoid duplicates (`CombatManager`)

### Phase 2: Distance Bands
- [x] Add distance_to[target_id] or distance_bands storage
- [x] Implement close/mid/long transitions (pair-wise for unformed)
- [x] Close action: roll engagement_pressure vs defender evasion; apply density modifier
- [x] Filter AvailableActionsBuilder by distance
- [x] Add stance modifiers: parry, evasion, damage, close attempt, disengage (controlling ↑opponent difficulty)

### Phase 3: Formations
- [x] Assign rank/file at combat start (spawn order; Option A: files = front count, rank 0 first)
- [x] Build formations from presets (party + enemy) at combat start
- [x] Filter targeting: rank 0 melee; rank 1 ranged/support
- [x] Formation targeting: weapon.melee_range >= effective_distance (|Δfile| × spacing_m × REACH_SAFETY_FACTOR)
- [x] Add swap rank action (time-based event delay; lane × footing × opponent pressure from `ZoneOfControl`; see Phase 5)
- [x] **Formation UI:** Visual rank×file grid with unit spacing (tight/normal/loose); FormationLayoutBuilder + FormationDiagramBuilder (compact diagram updates on formation_changed)
- [x] **Plug on death (rank advance):** When rank 0 unit dies, rank 1 in same file automatically advances to rank 0. Prevents units from being stuck unable to melee. Required before Phase 4 for accurate testing. See `docs/TACTICAL_FORMATIONS_FF4.md` §2 (plug_rule: rank_advance).
- [x] **Dead/wounded in slots (tracked, non-blocking):** `slot_obstacles`; non-blocking. **Footing:** `ZoneOfControl.get_footing_duration_multiplier` (Phase 5) scales formation-move duration when bodies present in column.

### Phase 4: ZoC
- [x] Zone control calculation per zone (front, left, right, rear) — `ZoneOfControl.recompute_zone_control`, cross-zone support
- [x] Flank access when control < threshold — `ZOC_ACCESS_THRESHOLD` in `get_engagement_parry_multiplier` / `_engagement_parry_mult_zoc`
- [x] Engagement angle assignment — `AttackResolver` sets defender `engagement_angle` from zone parry mult; pack fallback when not ZoC pair
- [x] Zone-based distance for formation vs formation (hybrid) — pair-wise `distance_to` + `mid_reach_files` when both lines wide and front ZoC weak
- [x] Optional encounter flag `protection_circle_active` — disables ZoC flank/rear and mid-reach widening (`CombatConstants.ENCOUNTER_PROTECTION_CIRCLE_ACTIVE`)
- [x] Formation diagram shows ZoC summary line (`FormationDiagramBuilder` + `ZoneOfControl.format_zone_control_line`)
- [x] **Incursion in zone strength** — `formation.incursion_pressure` from front-rank imbalance, blended in `_raw_zone_strength` (`ZoneOfControl` + `TacticalCombat.recompute_incursion_pressure`). Casualties: `slot_obstacles` + `ZOC_CASUALTY_PER_BODY`. **Optional / not modeled:** separate zone **extent** scaling distance (investigation-only).

### Phase 5: Formation Actions
- [x] Fall back — `_start_fall_back_solo` (empty rank-1 slot) and `fall_back_pair` via `_start_formation_pair_move`; `EVENT_FALL_BACK_SOLO_RESOLVE` / `_handle_fall_back_solo_resolve`
- [x] **Lane clarity** — `ZoneOfControl.get_swap_lane_duration_multiplier` (clear / crowded / blocked + density tweak), composed with footing via `get_lane_and_footing_duration_multiplier`
- [x] **Opponent pressure** — `ZoneOfControl.get_opponent_pressure_duration_multiplier` (defensive / neutral / aggressive)
- [ ] **Swap / move UI (optional):** Show duration or lane/pressure reason (e.g. “1.2s (crowded)”) on formation diagram or row
- [x] Drag back — `move_kind == "drag_back"` in `_start_formation_pair_move`; `DRAG_BACK_DURATION_MULT`; builder + AI offer `MOVE_ID_DRAG_BACK`
- [x] Step over fallen — `get_footing_duration_multiplier` (bodies in `slot_obstacles`); tracked non-blocking bodies from Phase 3 plug
- [ ] **Multi-unit same slot with deficits** — not implemented (design-only; no dual occupancy + distraction stat)
- [x] Rotate — `_start_rotate_file` (adjacent files, rank 0); `EVENT_ROTATE_FILE_RESOLVE`
- [ ] **Duration model vs outline:** Part 2 lists `armor_factor` in movement duration — **not** applied in `CombatManager` (only agility × lane × pressure × kind_mult). **Hit interrupt** during `STATE_SWAP_RANK` / `STATE_FALLING_BACK` — **not** wired (moves complete unless partner dies / resolve aborts).

### Phase 6: Tactical Features
- [x] **Ambush** — `encounter.ambush_type` / `ambush_penalty` / `ambushed_side`; `TacticalCombat.ambush_defense_multiplier` on defender parry/dodge and close-attempt evasion (`CombatManager._resolve_close_attempt`)
- [x] **Surround** — `TacticalCombat.count_engaging_threats` + split ÷ min(threats, `SURROUND_MAX_SPLIT_DIVISOR`) × perception awareness on parry and dodge (`DefenseChoiceResolver`)
- [x] **Incursion pressure** — `TacticalCombat.recompute_incursion_pressure` from front-rank count imbalance; reduces raw zone strength (`ZoneOfControl._raw_zone_strength`). **Deferred:** explicit **plug vs incursion contest** roll on failed plug (design-only).
- [x] **Crash / breach v1** — `BreachResolver`, `CombatEngagementResolver`; neighbor hold (`CombatIntrusionGeometry`); skirmish-aware breach move clog (`FormationBreachRules`).
- [x] **Line cohesion & posture** — `CombatFormationEngagement`, `CombatManager.engagement_state_changed`, UI labels (`BattleScene`). **Next:** intrusion slots + vacancy plug + intruder distance bands (`ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` P3–P4).
- [x] **Flanking** — implemented in Phase 4 (`ZoneOfControl.get_engagement_parry_multiplier`, pack fallback); Phase 6 checklist satisfied by that + surround/ambush layering

---

## Part 4: Phase Order — Critical for Testing

**Plug on death (rank advance)** — **shipped** (`CombatFormationFlow.on_combatant_died`). Rank 0 dies → obstacle recorded → rank 1 in same file promotes to rank 0 → `formation_changed`.

**Vacancy plug** (empty rank-0 without death, e.g. intruder leaves home slot) — **not shipped**; see `ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` P3.

**Phase 5** formation actions — **shipped** for core moves (see Part 3 Phase 5 checklist). Optional UI / armor duration / hit-interrupt items remain.

### Part 4.5: Dead/Wounded in Slots — Tracked but Non-Blocking

**Design:** Dead or incapacitated (wounded on ground) units stay tracked in their formation slot. They occupy space for awareness (medical, finishing, line of sight) but do **not** block movement.

| Aspect | Behavior |
|--------|----------|
| **Tracking** | `formation.slot_obstacles[(rank, file)]` = Array of combatant_ids (dead or incapacitated) in that slot. Or: combatant keeps rank/file until removed; `alive`/`incapacitated` flags determine if they block. |
| **Blocking** | Dead/wounded do NOT block. Lane clarity "blocked" = living unit in the way only. Rank 1 can advance over dead rank 0. |
| **Footing** | When moving through/over a slot with bodies: apply footing modifier (e.g. swap/fall-back duration ×1.15–1.25). "Step over fallen" — reduced footing, but movement still possible. |
| **Active actions** | Dead/wounded take no actions (no attacks, no swap). They are passive occupants. |
| **Plug on death** | Rank 0 dies → becomes ground obstacle in slot. Rank 1 advances into slot (standing over/near body). Slot now has primary occupant (rank 1) + obstacles ([dead]). |

**Data:** Add `formation.slot_obstacles` or equivalent; when unit dies/incapacitated, add to obstacles at (rank, file). When computing lane clarity and movement duration, check for obstacles and apply footing modifier. See **Part 2 — Formation Actions** (drag back, step over fallen).

---

## Part 5: Deferred Items

| Item | When |
|------|------|
| **Intrusion slots + vacancy plug + intruder distance** | `IMPLEMENTATION_ORDER.md` Tier 1.2–1.4 |
| Multi-target (close slots, AI weighting, defense split max) | After stable targeting |
| Parry choice (threat scoring) | Multi-target phase |
| Disengagement investigation (health/morale/rout) | Posture / morale (Tier 1.4–1.6) |
| ZoC extent modifier on reach | Investigation / optional |
| Leader abilities (formation flexibility) | Later |
| **Explicit plug vs incursion contest roll** | Design-only; not in code |

---

## Part 6: Source Documents

| Document | Role |
|----------|------|
| **`docs/IMPLEMENTATION_ORDER.md`** | **Canonical build order** (Tier 0–7) |
| **`docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`** | Line cohesion, posture, intrusion roadmap (Tier 1) |
| **COMBAT_ROADMAP_AND_STAMINA.md** (this bundle) | Historical phases + locked decisions + stamina investigations |
| **TACTICAL_FORMATIONS_FF4.md** | FF4 spec, distance, ambush, breakthrough |
| **TACTICAL_ZONES_BREACH_MOVEMENT.md** | ZoC, surround, flanking, breach narrative (sync with engagement plan Tier 2) |
| **AI_ENGAGEMENT_STANCE_AND_FEINTS.md** | Stances, footwork, melee AI, mental stack |

---

## Part 7: Quick Reference — Key Constants

| Constant | Value |
|----------|-------|
| spacing_m (tight) | 0.9 |
| spacing_m (normal) | 1.2 |
| spacing_m (loose) | 1.8 |
| REACH_SAFETY_FACTOR | 0.8 |
| Flank parry modifier | 0.8 |
| Rear parry modifier | 0.7 |
| commit_fraction (default) | 0.7 |
| commit_fraction (thrust) | 0.6 |
| commit_fraction (heavy) | 0.8 |
| BASE_FALL_BACK_S | 0.5–1.5 (tune) |
| Lane: clear | 1.0 |
| Lane: crowded | 1.3 |
| Lane: blocked | 1.6 |
| Pressure: defensive | 0.9 |
| Pressure: aggressive | 1.3 |
| Footing (slot has dead/wounded) | 1.15–1.25 (duration multiplier when stepping over) |
| SURROUND_MAX_SPLIT_DIVISOR | 4 (`CombatConstants`) |
| Stance min stamina: aggressive | 25 |
| Stance min stamina: controlling | 20 |

---

<a id="stamina-system-implementation-plan"></a>

## Source: `STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md`

## Stamina-Based Combat: Implementation Plan (Distance Bands + Event Queue)

> **Archived vs shipped (2026):** The sections below were written as a **migration plan** (e.g. remove gauge, `STATE_IDLE`, flurry state machine). The **shipped** game uses **`STATE_WAITING`**, **`gauge`** + **`EVENT_ACTION_READY`**, and the modules listed in **Current architecture snapshot**. Use this stamina document for **curve / pacing / investigation** and for historical context — **not** as a literal description of the current main loop unless cross-checked with `combat/CombatManager.gd`.

### Design Decision: Chosen Approach

- **Distance:** Abstract distance bands (close / mid / long)
- **Resolution:** State-based event queue (no gauge; events scheduled by timestamp)
- **Gating:** Stamina threshold + engagement cooldown
- **Engagement:** Melee-only; occurs when two combatants are at **close** and exchange blows
- **Future:** Designed for ranged (mid/long) and magic (band by spell)

---

### Part 1: Distance Bands

#### Band Definitions

| Band | Melee | Ranged | Magic (future) | Notes |
|------|-------|--------|----------------|-------|
| **Close** | ✓ Full | ✗ No (or disadvantaged) | Touch only | Engagement; bind; flurry |
| **Mid** | Spear only (long reach) | ✓ Effective | Projectile spells | Default for ranged |
| **Long** | ✗ No | ✓ Reduced accuracy | Long-range spells | Out of melee threat |

#### Per-Pair State

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

#### Band Transitions (Melee)

- **To close:** Attacker rolls `engagement_pressure` vs `defender.evasion`. Success → close.
  - `evasion = agility * (1 - armor_burden) * stamina_factor`
  - `engagement_pressure = strength * stamina_factor * reach_factor`
- **From close (disengage):** Defender rolls `disengage_ability` vs `attacker.hold_strength`.
  - Success → band becomes mid (agile/light) or mid (heavy). On strong success → long.
  - `disengage_ability = agility * (1 - armor_burden) * stamina_factor`
  - `hold_strength = attacker.strength * weapon_mass_factor`

#### Weapon Reach by Band

| Weapon | Close | Mid | Long |
|--------|-------|-----|------|
| Dagger (0.8m) | ✓ | ✗ | ✗ |
| Sword, Axe, Mace (1.5m) | ✓ | ✗ | ✗ |
| Spear (2.5m) | ✓ | ✓ | ✗ |

---

### Part 2: State-Based Event Queue

#### Core Idea

Replace **gauge fill → act when 100%** with **event queue**: each action is an event with `resolve_at: float` (game time). The combat loop processes the queue in chronological order. State drives what events can be scheduled.

#### Event Types

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

#### State Machine (Per Combatant)

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

#### Queue Processing (Main Loop)

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

#### Event Timing (State-Based)

- **Wind-up duration:** `CombatTiming.wind_up_duration(...)` — unchanged
- **Recovery duration:** `CombatTiming.recovery_duration(...)` — unchanged; multiply by ENGAGED_RECOVERY_MULT when engaged
- **Close attempt:** Fixed duration (e.g. 0.3s) or derived from agility
- **Flurry blow:** Reduced wind-up (e.g. 0.2–0.4s) when engaged
- **Engagement cooldown:** `COOLDOWN_BASE * (100/agility) * (1 + armor_burden * 0.5)`

#### State → Event Mapping

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

### Part 3: Data Structures

#### Combatant (Additions)

```gdscript
# Add to combatant dict:
distance_to: Dictionary = {}      # target_id -> "close"|"mid"|"long"
engaged_with_id: int = -1
engagement_cooldown_until: float = -1.0
# Remove: gauge (replaced by event schedule)
# Keep: state, state_timer, state_duration for compatibility during migration
```

#### Combat Manager (Additions)

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

#### Pair-Wise Distance

```gdscript
# Option A: Store per combatant
# c.distance_to[other_id] = "close"

# Option B: Store in manager as (id1, id2) -> band
# distance_bands[{min(id1,id2), max(id1,id2)}] = "close"
```

---

### Part 4: Pre-Switch Considerations

#### 4.1 Must Address Before Migration

| # | Consideration | Action |
|---|---------------|--------|
| 1 | **UI dependency on gauge** | BattleUI, CombatantRowBuilder, turn_ready all assume gauge. Replace with "next action ready at time X" or event-based readiness indicator. |
| 2 | **Player input flow** | Player currently gets turn_ready when gauge=100. New: emit when EVENT_ACTION_READY for player and state=IDLE. Player chooses → we schedule. |
| 3 | **AI action picking** | AI picks when gauge full. New: AI picks when EVENT_ACTION_READY fires. Same `get_available_actions` + `CombatAIActionPicker.pick`. |
| 4 | **Stamina floor for engagement** | Add STAMINA_ENGAGE_MIN (e.g. 20). Below this: cannot initiate close or attack. Can only wait (recover stamina). |
| 5 | **Armor burden** | Add `armor_burden` per combatant. ArmorPiece/layer needs `mobility_penalty` or `weight`. Used in evasion, disengage, cooldown. |
| 6 | **Multi-target (2v1, 3v2)** | Define: who gets engagement? Rule: engagement = 1v1. If A engages B, C attacking B is "external" — resolves as normal attack (no flurry with C). B's engagement is with A. C's attack may hit B (interrupt flurry?). Need clear rule. |
| 7 | **Medical phase** | Medical phase currently runs after combat. Event queue must support medical events. Likely: combat_ended → medical phase → different event set (simpler, or medical uses same queue with EVENT_MEDICAL_*). |

#### 4.2 Should Address

| # | Consideration | Action |
|---|---------------|--------|
| 8 | **Afterblow integration** | Afterblow already exists. In event queue: afterblow = additional EVENT_MELEE_ATTACK or EVENT_FLURRY_BLOW? Need to slot into queue. |
| 9 | **Passive parry** | Parry is reactive during attack resolution. Unchanged—AttackResolver still runs DefenseChoiceResolver. |
| 10 | **Death/incapacitation tick** | Currently in process loop. Becomes EVENT_DEATH_TICK scheduled periodically, or on each EVENT_ACTION_READY check. |
| 11 | **Guard, guard_line, guard_zone** | Keep. Still used for parry/defense. |

#### 4.3 Nice to Have Before Switch

| # | Consideration | Action |
|---|---------------|--------|
| 12 | **Ranged/magic placeholders** | Define EVENT_RANGED_ATTACK, EVENT_CAST_SPELL. Implement later; structure supports. |
| 13 | **External interrupt (ranged hits engaged pair)** | Rule: ranged can target anyone. Hit on engaged combatant: apply damage; optionally break engagement. |
| 14 | **Combat log** | Ensure CombatLogFormatter receives same action_resolved signals. Event handlers must emit. |

#### 4.4 Additional Considerations

| # | Consideration | Action |
|---|---------------|--------|
| 15 | **Combat start: who acts first?** | Schedule initial EVENT_ACTION_READY for all combatants at `combat_clock + initiative_delay`. Initiative delay = f(agility, armor_burden) — faster/ lighter goes first. Or roll; lowest delay acts first. |
| 16 | **resolve_action / _execute_attack** | Current: resolve_action → picks move/target → AttackWindUpStarter → _execute_attack. New: resolve_action schedules EVENT_MELEE_CLOSE or EVENT_MELEE_ATTACK. _execute_attack becomes the handler for EVENT_MELEE_ATTACK. Same AttackResolver, AttackResultApplier. |
| 17 | **Simultaneous events** | When multiple events have same resolve_at, order by: (a) initiative/agility, (b) combatant_id for tie-break. Ensures deterministic resolution. |
| 18 | **Player "wait" or pass** | Player must be able to pass (recover stamina, let enemies act). Action "wait" schedules EVENT_ACTION_READY at now + WAIT_DURATION (e.g. 0.5s) without spending stamina on attack. |

#### 4.5 Migration Order (Suggested)

> **Not executed as-written:** items such as “Disable gauge fill” and “Phase 4: Cleanup — remove `STATE_WAITING` / gauge” describe an alternate end state. The repo kept the hybrid model in **Current architecture snapshot**.

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

### Part 5: Constants to Add

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

### Part 6: Multi-Actor Scaling (15+ Creatures)

When many combatants fight at once, distance bands and engagement need rules to prevent bunching, distribute threats, and preserve physics-based accuracy.

#### 6.1 Slot Limit Per Target (Prevent Bunching)

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

#### 6.2 Target Distribution (Positioning Abstraction)

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

#### 6.3 Defense Splitting (Physics: Surrounded Defenders)

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

#### 6.4 Pair-Wise Distance Scaling

**Storage:** For N combatants, pairs = N×(N-1)/2.  
- N=15 → 105 pairs. Store as `distance_bands[Vector2i(min_id, max_id)]` or `(id_a, id_b) -> band`.  
- N=50 → 1225 pairs. Still manageable.

**Update rules:** Only update pairs when:
- Someone closes (A–B: long→close)
- Someone disengages (A–B: close→mid)
- Someone dies (remove all pairs involving them)

**Sparse storage:** Many pairs stay "long" entire fight. Lazy init: assume "long" if not in dict; only store close/mid pairs. Reduces memory for large fights.

---

#### 6.5 Physics-Based Accuracy With Many Actors

**Hit resolution:** Unchanged. AttackResolver still computes hit/parry/miss per attack. Each attack is resolved individually. What changes:

| Factor | Single target | Multi-target |
|--------|---------------|---------------|
| **Parry capacity** | Full | Divided by num_close_threats (see 6.3) |
| **Dodge** | Full | Could also split, or dodge is "move out of way" — less split than parry. Optional: dodge_chance /= sqrt(num_threats) |
| **Hit part** | Path + alignment | Same. AttackPathResolver unchanged. |
| **Friendly fire** | N/A | See 6.6 |

**Order of resolution:** Events resolve in timestamp order. If A and B both attack C in same tick, resolve first by event order (initiative tie-break). Each resolution uses current defender state (hp, stamina, guard) *before* the other hit lands. Or: resolve simultaneously (both hits apply) — your current design prefers sequential.

---

#### 6.6 Obstruction and Friendly Fire (Optional)

**Obstruction (melee):** In real combat, ally between you and target can block your strike. Without 2D positions, approximate:

- **Rule:** If A attacks B, and C (same side as A) is also "close" to B, then P(obstructed) = f(num_allies_close_to_B). E.g. 1 ally: 5%; 2 allies: 15%. Roll: if obstructed, attack hits ally C instead (or misses).
- **Defer:** Adds complexity. Start without; add if melee clusters feel wrong.

**Ranged friendly fire (future):** When ranged exists, "between" check: if ally is on "line" from shooter to target, chance to hit ally. Requires topology (who is between whom). Abstract: if same side has multiple close to target, ranged hit has X% to hit ally. Defer until ranged implemented.

---

#### 6.7 Summary: Multi-Actor Additions

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

### Part 7: Spear Lane Targeting (Deferred — Design Note)

**Implement later.** Different shields and formations should define which lanes spears can attack through. Lane type constrains which body parts the spear can target.

#### Lane Types (Shield/Formation Design)

| Lane Type | Physical Path | Target Parts |
|-----------|---------------|--------------|
| **Over-shoulder** | Spear thrusts over rank 0's shoulder; path is high | Head, chest, arms only — **not legs** (blocked by bodies/shields) |
| **Open lane** | Gap between rank 0 soldiers; clear path through | **Full target access** — head, chest, arms, legs |

#### Design Implications

- **Tight shield wall** (few gaps): Mostly over-shoulder lanes. Spear attacks restricted to upper body.
- **Open formation** (gaps between units): Open lanes. Spears can target anywhere — including low thrusts at legs.
- **Shield shape/size:** Large center-grip shields (round, kite) vs small bucklers affect gap size and thus lane type.
- **Formation presets:** E.g. "phalanx" = over-shoulder dominant; "loose skirmish" = open lanes dominant.

#### Implementation Note

- `AttackPathResolver` / hit-part selection would receive `lane_type` or `allowed_parts` from the formation when resolving spear thrusts from rank 1.
- Defer until rows+files formation system is in place.

---

### Part 8: Formation + Surround / Multi-Angle (Investigation)

For row/file formation combat *and* units that surround or attack from multiple angles (packs, flanking groups), see:

**`docs/TACTICAL_ZONES_BREACH_MOVEMENT.md`**

Covers: combining formation combat with surround/flanking, pack behavior, implementation tradeoffs, and alternatives.

---

### Part 9: References

- `docs/TACTICAL_ZONES_BREACH_MOVEMENT.md` — formation + surround, flanking, pack behavior
- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — distance and gating options
- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — flurry approaches
- `docs/COMBAT_ROADMAP_AND_STAMINA.md` — event queue, paradigms
- `combat/CombatManager.gd` — current gauge-based flow
- `combat/CombatStateHandlers.gd` — process_waiting, process_wind_up, process_recovering

---

<a id="stamina-curve-hema-combat-pacing-investigation"></a>

## Source: `STAMINA_CURVE_HEMA_COMBAT_PACING_INVESTIGATION.md`

## Stamina Curve, HEMA/Medieval Combat Pacing & System Balance Investigation

### Purpose

1. Ensure all stamina-dependent systems use a **non-linear fatigue curve** for physics-based realism.
2. Compare **HEMA combat** and **medieval warfare** pacing (combat length, time between blows, engagements) with the current system.
3. Propose balanced constants and structural changes.

---

### 1. HEMA & Medieval Combat Research Summary

#### 1.1 Time Between Blows / Technique Duration

| Context | Duration | Source |
|---------|----------|--------|
| **Explosive cut** (as fast as possible, minimal telegraph) | 250–350 ms | Science & Fiction: Medieval Swordfighting |
| **Standard cut** (synchronized with footwork, telegraphed) | 600 ms or longer | Same |
| **Human reaction time** | ~250 ms | General |
| **Implication** | Explosive cuts land before defender can react; standard cuts give ample warning | |

**Fallen Paths comparison:** Wind-up = 0.25 + 0.6×intensity ≈ 0.5–0.85 s (before leg/perf/agi). Closer to "standard cut" pace than explosive. Effective wind-up (×0.8) for parry reaction = 0.4–0.68 s — defender has time to react when using standard attacks.

#### 1.2 Combat Length & Fatigue

| Context | Duration / Pattern | Source |
|---------|-------------------|--------|
| **High-intensity sword fighting** (max pace) | No one sustains > ~5 min; exhaustion in <1 min possible | Quora / medieval combat research |
| **Medieval duel reality** | Slow, positional movement; rare intense bursts of 2–3 strikes | Same |
| **Limiting factor** | Often mental endurance (concentration to avoid decisive strike) over pure physical stamina | Same |
| **Armored combat** | Higher pace (comparable to boxing) until exhaustion; armor enables aggression | Same |
| **Army-level** | ~20 min active combat before soldiers need rotation | myArmoury / battle duration |
| **Weapon weight** | 1–1.5 kg sword ≈ halves fighting duration; 2–3 kg axe / 3–4 kg halberd → rapid fatigue | Same |

**Key insight:** Real combat is *punctuated* — slow, cautious phases with occasional explosive flurries. Sustained high pace depletes stamina quickly.

#### 1.3 Engagement Rules (HEMA Tournaments)

- **Immediate stop** after hit (sport fencing style).
- **Afterblow rule:** One parting blow within 1–3 steps of receiving a hit.
- **No predetermined stop:** Continuous until fall or disarm.

Ruleset drastically affects how long exchanges last and how many blows occur per "engagement."

---

### 2. Current Fallen Paths System

#### 2.1 Timing Chain (Per Combatant)

| Phase | Typical Duration | Formula / Notes |
|-------|------------------|-----------------|
| **Wind-up** | 0.4–0.8 s | (0.25 + 0.6×intensity) × windup_mult / leg / perf / agility |
| **Recovery** | 0.4–1.5 s | Base + commitment + outcome extra (hit/deflect/miss) / perf / agility |
| **Gauge fill** | 1–4 s | 100 / (agility × 0.5) ≈ 2 s @ 100 agi |
| **Cycle** | ~2.5–6 s | wind_up + recovery + gauge per attack |

**Time between blows (single combatant):** ~3 s typical. In 2v2, both sides act in parallel, so *engagement* pace can feel ~1.5–3 s per exchange (when alternating).

#### 2.2 Stamina Flow

| Constant | Value | Notes |
|----------|-------|-------|
| STAMINA_MAX | 100 | |
| STAMINA_REFILL_RATE | 12/s | When WAITING |
| STAMINA_ATTACK_COST_BASE | 8 | Per attack |
| STAMINA_PARRY_COST | 10 | Per parry (defender) |

**Net over a 3 s cycle (attack only):** Spend 8, regain 12×3 = 36 → **+28**. Stamina *increases* in normal pacing.

**When does stamina deplete?**
- Attacking every ~3 s: net positive. Never runs out in typical 1v1.
- Parrying frequently: defender spends 10 per parry; if parried every 2 s, 5 parries ≈ 50 stamina in 10 s, refill 120 → still net positive.
- **Depletion scenario:** Very fast succession (e.g. parry_partial chains, multiple opponents, or artificially short recovery). Or if costs were higher / refill lower.

**Conclusion:** Current constants make stamina a **rarely hit** constraint. It mainly matters at 0 (parry ×0.5, damage ×0.6, variance ×1.5).

#### 2.3 Stamina-Dependent Systems (Current)

| System | At 100% | At 0% | Curve |
|--------|---------|-------|-------|
| **Angle variance** | mult 1.0 | mult 1.5 | Linear lerp(1, 1.5, 1 − stamina_ratio) |
| **Parry capacity** | 1.0 | ×0.5 | Binary: stamina ≤ 0 → mult |
| **Damage** | 1.0 | ×0.6 | Binary: stamina ≤ 0 → mult |

**Gap:** All use **linear or binary** mapping. No non-linear "suddenly sloppy when exhausted" feel.

---

### 3. Non-Linear Fatigue Curve (Exercise Science)

Research indicates:
- **Power output** decreases in a **second-order polynomial** (curved) pattern during prolonged exercise.
- **Critical power** concept: below a threshold, exercise can continue; above it, fatigue accumulates and duration is limited.
- **Sharp decline:** Performance drops more rapidly below ~25% capacity; 5% power loss correlates with time-to-failure.

**Recommended curve shapes:**
1. **sqrt(ratio)** — gentle until low; then steep. `effective = sqrt(stamina_ratio)` for a modifier that ramps down.
2. **Power curve** — `effective = stamina_ratio^0.7` — similar effect; below 0.5, drops faster.
3. **Threshold + steep** — Above 30%: nearly flat. Below 30%: steep ramp (e.g. mult = 1 + 2×(1 − ratio) when ratio < 0.3).

---

### 4. Proposed Non-Linear Stamina System

#### 4.1 Unified Stamina Factor

Introduce a single `stamina_factor(stamina_ratio: float) -> float` used everywhere:

```gdscript
# Option A: sqrt — variance/deficit ramps more below 50%
static func stamina_factor(ratio: float) -> float:
    return sqrt(clampf(ratio, 0.0, 1.0))

# Option B: Power curve — sharper drop below 25%
static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), 0.6)

# Option C: Threshold — flat until 30%, then steep
static func stamina_factor(ratio: float) -> float:
    if ratio >= 0.3:
        return 1.0
    return ratio / 0.3  # linear 0→1 as ratio 0→0.3
```

**Recommendation:** **Option B** (power 0.6) — matches "fatigue accelerates" below ~30% without extreme cliff at 0.

#### 4.2 Apply to All Stamina-Dependent Systems

| System | Current | Proposed |
|--------|---------|----------|
| **Angle variance mult** | lerp(1, 1.5, 1−ratio) | `1.0 + 0.5 * (1.0 - stamina_factor(ratio))` so at ratio=0, mult=1.5; curve from sqrt/power |
| **Parry capacity** | 0.5 if stamina≤0 else 1 | `lerp(0.5, 1.0, stamina_factor(ratio))` — gradual decline, not binary |
| **Damage** | 0.6 if stamina≤0 else 1 | `lerp(0.6, 1.0, stamina_factor(ratio))` — gradual |
| **Gauge fill** (optional) | 1.0 | `stamina_factor(ratio)` — exhausted combatants fill gauge slower |

#### 4.3 Balance Stamina Economics for HEMA-Like Pacing

To make stamina a *felt* constraint without making combat tedious:

| Goal | Change |
|------|--------|
| **Depletion in ~2–3 min of intense combat** | Increase costs or reduce refill. If cycle ≈ 3 s and we want net −2 to −3 per cycle when "active": cost 14–15, refill 36 → net +21 still. Need cost ~20+ per attack to net negative. Or: refill only when truly idle (not in RECOVERING). |
| **Refill only when idle** | Only refill in WAITING. RECOVERING = no refill. Extends time to recover between engagements. |
| **Cost scales with intensity** | `stamina_cost = BASE + intensity * SCALE` (e.g. 5 + 15×intensity → 6.5 @ 0.1, 20 @ 1.0). Heavy strikes cost more. |
| **Parry cost when actually parrying** | Already 10. Defender in bind/deflect pays; could scale by parry quality. |

**Suggested constants (tuned for ~2 min to deplete at high pace):**
- STAMINA_ATTACK_COST: 12 + 8×intensity (light 12, heavy 20)
- STAMINA_REFILL_RATE: 8/s (slower)
- Refill only in WAITING (not RECOVERING)
- With 3 s cycle (1 s wind+recovery, 2 s waiting): spend 16 avg, regain 16 → break-even. Faster attacks (less waiting) → depletion.

---

### 5. HEMA/Medieval Pacing vs Fallen Paths

| Metric | HEMA / Medieval | Fallen Paths | Notes |
|--------|-----------------|--------------|-------|
| **Single cut duration** | 0.25–0.6 s | Wind-up 0.5–0.8 s | FP slightly slower (telegraphed). |
| **Time between blows** | Rules-dependent; 1–3 steps for afterblow | ~3 s per combatant | FP has explicit "wait for gauge" — more measured. |
| **Burst capacity** | 2–3 intense strikes, then pause | Gauge gates; no explicit burst | Could add "flurry" with stamina cost. |
| **High-intensity limit** | <1 to ~5 min | Stamina rarely depletes | Need rebalance so depletion is reachable. |
| **Exhaustion effect** | Sudden drop in control/power | Linear/binary | Non-linear curve recommended. |

**Conclusion:** Fallen Paths is already in the right *ballpark* for blow timing. Main adjustments: (1) non-linear stamina curve for realism, (2) stamina economics so exhaustion is achievable in intense fights, (3) optional refill-only-when-idle.

---

### 6. Implementation Checklist

#### Phase 1: Non-Linear Stamina Factor
- [ ] Add `CombatConstants.stamina_factor(ratio: float) -> float` using power curve.
- [ ] Replace `lerpf(1, mult, 1−ratio)` in `get_attack_angle_deg` with `1 + (mult-1) * (1 - stamina_factor(ratio))`.
- [ ] Replace binary stamina≤0 checks in DefenseChoiceResolver (parry) and AttackResolver (damage) with `lerp(min, 1, stamina_factor(ratio))`.

#### Phase 2: Balance Stamina Economics (Optional)
- [ ] Intensity-scaled attack cost: `STAMINA_ATTACK_BASE + STAMINA_ATTACK_SCALE * intensity`.
- [ ] Refill only in WAITING (remove refill during RECOVERING).
- [ ] Tune so ~2 min of high-intensity combat approaches 0 stamina.

#### Phase 3: Consistency
- [ ] Use `stamina_factor` anywhere stamina affects outcome (variance, parry, damage, gauge fill).
- [ ] Document curve choice and tuning rationale.

---

### 7. Recommended Constants (Draft)

```gdscript
# Stamina curve: power 0.6 — sharp drop below 25%
const STAMINA_FACTOR_POWER := 0.6
static func stamina_factor(ratio: float) -> float:
    return pow(clampf(ratio, 0.0, 1.0), STAMINA_FACTOR_POWER)

# Economics (optional rebalance)
const STAMINA_ATTACK_COST_BASE := 10.0
const STAMINA_ATTACK_COST_SCALE := 10.0   # cost = BASE + SCALE * intensity
const STAMINA_PARRY_COST := 10.0
const STAMINA_REFILL_RATE := 10.0         # per second when WAITING only
# Refill in RECOVERING: 0 (implement by only refilling when state==WAITING)
```

---

### References

- CombatConstants.gd (STAMINA_*, get_attack_angle_deg)
- AttackResolver.gd (damage mult at stamina 0)
- DefenseChoiceResolver.gd (parry mult at stamina 0)
- CombatStateHandlers.gd (refill, gauge fill)
- Science & Fiction: Medieval Swordfighting
- Battle Durations and Fatigue (myArmoury)
- Critical Power / power-duration (exercise physiology)
- PHYSICS_SYSTEMS_OPTIMAL_STRUCTURE_INVESTIGATION.md

---

<a id="stamina-vs-fitness-formation-integration-investigation"></a>

## Source: `STAMINA_VS_FITNESS_FORMATION_INTEGRATION_INVESTIGATION.md`

## Stamina vs Fitness — Formation Integration Investigation

**Principle:** Formation positioning (swap rank, plugging) should use **performance + health (fitness)** only. Engagement actions (attack, attempt_close) should use **stamina**.

---

### Decision Summary

| Action Type | Use | Rationale |
|-------------|-----|------------|
| **Attack** | Stamina | Exhausted units hit weaker, parry worse; AI should be less likely to attack when very low stamina |
| **Attempt close** | Stamina | Engaging the enemy; exhausted units less likely to succeed (pressure roll) and less likely to choose |
| **Swap rank** | Fitness only (perf × blood) | Formation positioning; injured/wounded should retreat to back regardless of stamina |

---

### Integration Points Audited

#### ✅ CombatAIActionPicker (fixed)

- **Swap rank:** Uses `_get_positioning_fitness()` (performance × blood). No stamina. Prevents ping-pong when fitness similar.
- **Attack / attempt_close:** Uses stamina_ratio; weight 0.85 when stamina < 20%, else 1.0.

#### ✅ CombatManager

- **`_start_swap_rank`:** Time-based duration from agility + lane/pressure mods. No stamina cost or check.
- **`resolve_action` for swap:** Routes to `_start_swap_rank`; never touches AttackResultApplier. Swap does **not** consume stamina.
- **`_resolve_close_attempt`:** Uses `stamina_factor(atk)` and `stamina_factor(def)` for pressure vs evasion roll. Correct — engagement.
- **`_reschedule_back_rank_turns`:** Fixed delay (0.2s). No stamina.
- **Plug on death:** Promotes rank 1 → 0, schedules `READY_DELAY_AFTER_PROMOTION_S`. No stamina.

#### ✅ AvailableActionsBuilder

- **Swap rank availability:** Gated only by formation rules (we_are_front, partner_incapacitated, same file, adjacent rank). No stamina check. Correct — offer when formation allows; AI weights by fitness.
- **Attack / attempt_close:** No stamina gating for offering. Correct.

#### ✅ AttackResultApplier

- **Swap rank:** Never reaches this path. Swap returns early in `resolve_action`. No stamina consumed for swap.
- **Attack outcomes:** All consume stamina (attack cost, parry cost). Correct.

#### ✅ TurnReadyHandler (player companions)

- Uses `CombatAIActionPicker.pick()`. Fix applies.

#### ✅ CombatStateHandlers (enemy AI)

- Uses `CombatAIActionPicker.pick()` for action choice. Fix applies.

#### ✅ Stance System (CombatConstants)

- `STANCE_MIN_STAMINA_AGGRESSIVE`, `STANCE_MIN_STAMINA_CONTROLLING`: Gates stance on stamina. Affects close_attempt, evasion, parry. All engagement-related. Correct.

#### ✅ AttackResolver / DefenseChoiceResolver

- Use stamina for damage scaling, parry capacity, variance. All engagement. Correct.

---

### No Changes Needed

- **CombatConstants:** "Swap rank / fall back: time-based, no stamina" — already correct.
- **Documentation (this bundle, Part 2 — Formation Actions):** Swap rank / fall back are time-based (not stamina) — matches.
- **Human player:** Can choose swap_rank when available. No stamina gate. Correct — formation actions remain available regardless of exhaustion.

---

### Future (Phase 5+)

When implementing **fall back**, **drag back**, **step over fallen**: use fitness for positioning decisions, no stamina. Duration may scale with lane clarity / pressure (time-based), not stamina cost.

---

<a id="back-rank-wait-event-listener-vs-fixed-cooldown-investigation"></a>

## Source: `BACK_RANK_WAIT_EVENT_LISTENER_VS_FIXED_COOLDOWN_INVESTIGATION.md`

## Back Rank Wait: Event Listener vs Fixed Cooldown — Investigation

**Question:** Should the back row use an event listener instead of a fixed 2-second wait when they have no actions?

---

### Current System: Fixed 2s Cooldown

When a back-rank (rank 1+) unit skips (no actions), we schedule `EVENT_ACTION_READY` at `combat_clock + 2.0`.

| Pros | Cons |
|------|------|
| Simple, predictable | Wastes events: back rank gets turn every 2s even when nothing changed |
| No extra logic | Feels arbitrary (why 2s?) |
| Works without formation_changed | Event queue can accumulate many skip events in long battles |
| Promoted units already get 0.15s wake on plug | Back rank may "miss" a plug if their 2s fires before the plug and they skip again |

---

### Alternative A: formation_changed Event Listener

**Mechanism:** When `formation_changed` fires (plug, swap), schedule `EVENT_ACTION_READY` at +0.2s for all back-rank units in WAITING on that formation. When back rank skips, do **not** schedule—they wait until the next formation change.

| Pros | Cons |
|------|------|
| Back rank wakes only when something relevant happens | **Stuck forever:** If formation never changes (front healthy, won't swap), back rank never acts |
| Reduces event spam | Need safety: max wait (e.g. 4s) to avoid permanent freeze |
| Semantically correct: "wait for your moment" | formation_changed can fire often (swap)—every swap would wake back rank, who'd skip again |
| Responsive to plug (0.2s vs possibly waiting for old 2s) | More complex: cancel pending, schedule on signal |

---

### Alternative B: Hybrid — formation_changed Wake + Fallback Cooldown

**Mechanism:**
1. On `formation_changed`: Cancel any pending `EVENT_ACTION_READY` for back-rank units in that formation; schedule at +0.2s.
2. When back rank skips: Schedule at 2.5s (fallback). If formation_changed fires before that, the 0.2s event replaces the need for the 2.5s one (both would fire—first wins; second finds them already acted or in different state).

**Problem:** Duplicate events. If we schedule 0.2s on formation_changed and they already have 2.5s pending, we'd have two events. When 0.2s fires, they skip and schedule another 2.5s. The old 2.5s would still fire later—waste. We need to **cancel** pending when formation_changed fires.

| Pros | Cons |
|------|------|
| Back rank wakes quickly when plug/swap happens | Requires `_cancel_pending_action_ready(combatant_id)` |
| Fallback ensures they never wait forever | Slightly more code |
| Best of both worlds | |

---

### Alternative C: formation_changed Wake + No Fallback

Back rank never schedules on skip. They only wake on formation_changed. **Risk:** If front rank never dies and never swaps (e.g. long standoff), back rank is permanently stuck. **Mitigation:** Add a "max wait" timer: if a back-rank unit has been WAITING for >4s with no formation_changed, schedule one. That's equivalent to a 4s fallback.

---

### Recommendation

**Hybrid (B)** with cancel support:

1. Add `_cancel_pending_action_ready(combatant_id)` to remove matching events from the queue.
2. On `formation_changed(fid)`: For each combatant in that formation with rank > 0 and state WAITING, cancel their pending ACTION_READY and schedule at +0.2s.
3. When back rank skips: Schedule at 2.5s (fallback).

Result: Plug/swap → back rank acts in 0.2s. Nothing changes → back rank checks every 2.5s. No duplicate turns.

---

### Implementation (done)

**Hybrid event model** (see CombatManager, event queue):

- **Signals drive scheduling:** `formation_changed` → `_reschedule_back_rank_turns(fid)` reschedules back-rank ACTION_READY at `READY_DELAY_FORMATION_RECHECK_S` (0.2s). `turn_resolved(combatant_id)` emitted when a combatant commits their action.
- **Centralized scheduling:** `_schedule_action_ready(combatant_id, delay_s)` always cancels pending first, then schedules. Avoids duplicate turns.
- **Constants:** `READY_DELAY_*` in CombatConstants (SKIP_DEFAULT, SKIP_BACK_RANK, FORMATION_RECHECK, AFTER_PROMOTION, PARRY_RIPOSTE, CLOSE_ATTEMPT).
- **Heap-compatible:** Events remain time-ordered; signals trigger insertions. Phase 1 min-heap will key by `resolve_at`.

---

<a id="modularization-possibilities"></a>

## Source: `MODULARIZATION_POSSIBILITIES.md`

## Modularization Possibilities

Audit of the codebase for extraction opportunities. Ordered by impact and dependency (do lower-numbered items first where dependencies exist).

---

### 1. CoreEntity.gd (~1,426 lines) — Highest impact

`CoreEntity` is a single class handling body state, damage, wounds, bleeding, blood volume, consciousness, pain, armor, weapons, and all medical actions. Below are **logical modules** that can be extracted. CoreEntity would keep the data (or a reference) and delegate to these components.

#### 1.1 Medical subsystem → `core/EntityMedical.gd` (or child node)

**Move out:** All medical application and queries; CoreEntity keeps the data and calls the module.

| Responsibility | Functions / data to move or delegate |
|----------------|--------------------------------------|
| Bandage | `can_apply_bandage`, `apply_bandage`, `get_bandage_application_time_seconds`, `get_bandage_application_time_seconds_for_part` |
| Packing | `can_apply_packing`, `apply_packing`, `get_packing_application_time_seconds_for_part` |
| Direct pressure | `can_apply_direct_pressure`, `apply_direct_pressure`, `apply_direct_pressure_from_ally`, `is_applying_direct_pressure`, `has_direct_pressure_on_part`, `get_direct_pressure_part`, `clear_direct_pressure` |
| Tourniquet | `is_tourniquet_indicated_for_part`, `can_apply_tourniquet`, `is_tourniquet_applied`, `apply_tourniquet`, `remove_tourniquet` |
| Medical effectiveness | `get_medical_effectiveness` (or keep on CoreEntity and pass in) |
| Medical entity | `get_medical_entity` (stays as “return self” or return component owner) |

**Data that stays on CoreEntity but is used by Medical:** `wounds`, `tourniquet_applied`, `bandaged_parts`, `packed_parts`, `direct_pressure_*`, `_game_time_seconds`, and entity state (e.g. `get_attacking_arm`, `get_bleeding_rate_for_part`). The medical module can take `(entity: Node)` and call back for these, or receive them as parameters.

**Interface:** e.g. `EntityMedical.apply_bandage(entity, part, effectiveness)` where `entity` is the CoreEntity (or a small interface with `wounds`, `bandaged_parts`, etc.). Alternatively, a child node `MedicalComponent` that holds no state but gets passed the entity and part.

**Benefit:** Isolates all bandage/packing/direct pressure/tourniquet logic; easier to test and tune without touching damage/consciousness.

---

#### 1.2 Wounds & bleeding (injury model) → `core/EntityWounds.gd` or `core/EntityBleeding.gd`

**Move out:** Wound list management, bleeding rates, clotting, and blood loss from wounds. CoreEntity keeps `wounds` and `blood_volume` (or the module holds them and exposes getters).

| Responsibility | Functions |
|----------------|-----------|
| Wound creation | `_add_wound`, `_create_stump_wound`, `_severity_from_damage`, `_severity_from_bone_damage` |
| Bleeding rates | `get_total_bleeding_rate`, `get_permanent_bleeding_rate`, `get_bleeding_rate_for_part` |
| Bleeding process | `process_bleeding` (clotting, rate decay, direct-pressure auto-clear) |
| Blood loss | `process_blood_loss` |
| Wound queries | `get_wounded_parts`, `get_wounds`, `get_wound_healing_progress` / `_get_wound_healing_progress` |
| Pain from wounds | `_get_pain_contribution_for_wound`, `_get_pain_for_part` (or keep pain in a separate small module; see 1.4) |

**Shared constants:** Already in `BleedingConstants`; module can preload that. CoreEntity’s `process(delta)` would call e.g. `wound_system.process_bleeding(delta)` and `wound_system.process_blood_loss(delta)` (or one call that does both).

**Benefit:** Single place for “how wounds and bleeding work”; damage pipeline only needs to add wounds and advance time.

---

#### 1.3 Damage & severance pipeline → `core/EntityDamage.gd` or keep in CoreEntity with helpers

**Option A — Keep in CoreEntity:** `take_damage_split` is the central integration point (armor, bone/tissue split, severance, wounds, pain shock). It’s large but cohesive; you could leave it in CoreEntity and only extract **helpers** (e.g. severance ease, bone/tissue allocation) into static or `RefCounted` helpers.

**Option B — Extract damage executor:** Move `take_damage_split`, `take_damage`, `_get_severance_ease_factor`, and the bone/tissue/wound-add logic into a `DamageApplicator` that takes `(entity, cut_pre, blunt_pre, part, ...)` and mutates entity’s `body_cutting`, `body_blunt`, `bone_health`, `wounds`, and calls back for `_add_wound` / `_update_consciousness` / `_try_enter_pain_shock_from_hit`. CoreEntity would call `DamageApplicator.apply(entity, ...)`.

**Recommendation:** Start with **1.1 (Medical)** and **1.2 (Wounds/Bleeding)**; then decide whether `take_damage_split` stays in CoreEntity and only small helpers are extracted (Option A) or a full Damage module (Option B).

---

#### 1.4 Pain & consciousness → `core/EntityPainConsciousness.gd`

**Move out:** Pain aggregation, effective pain for thresholds, consciousness and pain-shock.

| Responsibility | Functions |
|----------------|-----------|
| Pain | `get_total_pain`, `get_effective_pain_for_thresholds`, `get_effective_pain_for_region`, `_get_pain_contribution_for_wound`, `_get_pain_for_part`, `_get_pain_reference` |
| Consciousness | `_get_blood_consciousness_modifier`, `_mark_consciousness_dirty`, `_update_consciousness`, `_try_enter_pain_shock_from_hit`, `ensure_consciousness_current` |
| Performance | `get_effective_consciousness`, `get_performance_modifier`, `get_action_bar_performance_modifier`, `get_hit_chance_performance_modifier` |

**Data:** `consciousness`, `effective_consciousness`, `_pain_shock_until_time`, `_last_hit_impact`, `_consciousness_dirty`. These can live on CoreEntity and be passed to the component, or the component can own them and expose getters.

**Benefit:** Pain/consciousness tuning and performance modifiers live in one place; damage and medical code only trigger “dirty” or “recalc” instead of inlining formulas.

---

#### 1.5 Body parts & targeting (minimal extraction)

**Keep in CoreEntity or extract to `core/BodyPartQuery.gd` (static):**  
`_get_body_part_list`, `_get_vital_parts`, `get_targetable_parts`, `_is_part_severed`, `_is_part_crushed`, `_is_part_destroyed`, `is_part_severed`. These are thin and use `body_cutting` / `body_blunt` / `bone_health` / `species`; moving them to a static helper that takes `(body_cutting, body_blunt, bone_health, body_max, bone_max, species)` would allow reuse (e.g. from CombatManager or UI) without tying CoreEntity to a new node. Optional.

---

#### 1.6 Healing (time advance) → `core/EntityHealing.gd`

**Move out:** `process_healing(seconds)`: game time advance, wound resolution, bandage stabilization expiry, tourniquet expiry, tissue/bone/blood recovery. CoreEntity would call e.g. `healing_system.process_healing(entity, seconds)`.

**Data:** `_game_time_seconds`, and read/write to `wounds`, `body_cutting`, `body_blunt`, `bone_health`, `blood_volume`, `bandaged_parts`, `packed_parts`, `tourniquet_applied`. Either pass entity reference or a small “HealingState” struct that the component mutates.

**Benefit:** All “time passes” logic in one module; out-of-combat or rest systems can call the same logic.

---

#### Suggested order for CoreEntity

1. **EntityMedical** (1.1) — done.
2. **EntityWounds/Bleeding** (1.2) — done. “bleeding rate” API.
3. **EntityPainConsciousness** (1.4) — used everywhere; isolate so damage/medical don’t need to know formulas.
4. **EntityHealing** (1.6) — done.
5. **BodyPartQuery** (1.5) — done: `core/BodyPartQuery.gd` (body part list, vital parts, targetable parts, part state, arm/leg functionality).
6. **Damage** (1.3) — Option B done: `core/EntityDamage.gd` has `apply_damage_split(entity, ...)` (armor, bone/tissue, wounds, early severance, stump, pain shock). Option A (severance ease) was done earlier.

---

### 2. CombatManager.gd (~1,550+ lines) — High impact

CombatManager handles: combatant registration, state machine, gauge fill, available actions (attack + medical), AI weighting, attack wind-up/execute, parry/dodge resolution, damage application, medical wind-up completion, and winner/medical phase.

#### 2.1 Attack resolution (miss / dodge / parry / damage) → `combat/AttackResolver.gd` — done

**Moved out:** The entire “given an attacker and target, resolve one attack” flow: miss roll, defense choice (parry vs dodge), parry resolution, damage calculation (WeaponDamageHelper, part choice), `take_damage_split`, outcome (deflected/glancing/hit), recovery duration.

**Current location:** Most of `_execute_attack` (from “No functional arm” through “Recovery (hit)”).

**Interface (example):**  
`AttackResolver.resolve(combat_manager, attacker_id, target_id) -> Dictionary`  
Returns e.g. `{ "outcome": "hit"|"miss"|"dodge"|"deflected"|"glancing", "result_dict": {...}, "recovery_duration": float }`. CombatManager then applies state (STATE_RECOVERING, STATE_DEAD), emits `action_resolved`, and checks winner.

**Also move:**  
- `_get_parry_speed_m_s`, `_resolve_parry_with_momentum`  
- Helpers used only in execute: e.g. `_velocity_curve_factor` (if not used elsewhere), parry momentum math

**CombatManager keeps:** Combatant list, state machine (`_process`: gauge fill, STATE_WIND_UP → call AttackResolver when timer done), `resolve_action` (dispatch to attack vs medical), medical phase and winner logic.

**Benefit:** `_execute_attack` shrinks to a short “get pending attack → call AttackResolver → apply result”; parry/dodge/damage tuning lives in one file.

---

#### 2.2 Medical phase logic → `combat/MedicalPhaseController.gd` — done

**Moved out:**  
- “Can we end medical phase?”: `can_end_medical_phase`, `_has_untreated_wounds`, `_is_in_medical_danger`, `_is_in_immediate_peril`, `_has_left_immediate_peril_permanently`, `_get_medical_urgency`  
- “What medical actions are available?” for allies: `_get_ally_medical_actions`, `_get_parts_being_treated_on`, `_count_others_who_can_perform_medical_on_target`  
- Retry tracking: `_track_medical_failure_and_maybe_retry`

**CombatManager keeps:** Registration, `get_available_actions` (which calls into MedicalPhaseController for medical options), and `resolve_action` dispatching to `_start_medical_action` / attack.

**Interface (example):**  
- `MedicalPhaseController.can_end_medical_phase(combatants, medical_phase_winner) -> bool`  
- `MedicalPhaseController.get_medical_actions_for_ally(performer_entity, target_entity, ...) -> Array`  
- `MedicalPhaseController.is_in_medical_danger(entity) -> bool`  
- etc.

**Benefit:** Medical phase rules and urgency are in one place; CombatManager stays as “orchestrator” only.

---

#### 2.3 Combat state machine (optional)

**Option:** Extract the `_process` state transitions (WAITING → gauge fill / turn_ready; WIND_UP → execute attack; MEDICAL_WIND_UP → complete medical; RECOVERING → WAITING/COWERING; RECEIVING_MEDICAL_ATTENTION) into a small `CombatStateMachine` that receives `(combatants, delta)` and returns “events” (e.g. `turn_ready(id)`, `execute_attack(id)`, …). CombatManager would drive the state machine and react to events.  
**Recommendation:** Lower priority; do 2.1 and 2.2 first so the remaining `_process` is easier to read.

---

### 3. Other files

#### 3.1 character.gd

**Current role:** Thin wrapper around a child `CoreEntity` (CombatBody): exposes stats, movement, and combat/medical delegates. No need to split further; it’s already a facade. If you add more movement or overworld logic, consider a `CharacterMovement` or `CharacterController` script that only handles movement and input; `character.gd` stays as the node that composes CombatBody + movement.

#### 3.2 PartyManager.gd

Single responsibility (party list and sync). No modularization needed unless you add inventory, formation, or persistence; then you could extract e.g. `PartyPersistence` or `PartyFormation`.

#### 3.3 BattleScene.gd

**Current role:** Creates UI, instantiates CombatManager, registers combatants, connects signals, updates UI from combat events. Fits “scene controller” well. If it grows, consider:  
- Extracting **UI layout constants** (BODY_PARTS, BODY_LABELS, bar sizes) to a `BattleUIConstants.gd` or `BattleSceneConfig.gd`.  
- Extracting **log formatting** (e.g. “X -> Y hit/miss/dodge”) into a small `CombatLogFormatter` so BattleScene only appends formatted strings.

#### 3.4 weapon/WeaponDamageHelper.gd

Already a static/RefCounted helper; no change needed. Keep damage constants in `WeaponConstants.gd`.

---

### 4. Cross-cutting: constants and autoloads

- **BleedingConstants, HealingConstants, PainConsciousnessConstants, BodyPartConstants:** Already separate; keep them. Any new “entity” module can preload these.
- **CombatManager as autoload:** Currently created by BattleScene. If you extract AttackResolver or MedicalPhaseController, they can be either standalone `RefCounted`/Node classes instantiated by CombatManager or autoloaded services; prefer “instantiated by CombatManager” to avoid global state.

---

### 5. Summary table

| Module | Source | Priority | Dependencies |
|--------|--------|----------|--------------|
| EntityMedical | CoreEntity | 1 | BleedingConstants, entity wounds/state |
| EntityWounds/Bleeding | CoreEntity | 2 | BleedingConstants (includes process_blood_loss since modularization) |
| EntityPainConsciousness | CoreEntity | 3 | PainConsciousnessConstants, species |
| EntityHealing | CoreEntity | 4 | HealingConstants, BleedingConstants, wounds |
| AttackResolver | CombatManager | 5 | WeaponDamageHelper, BodyPartConstants, CoreEntity |
| MedicalPhaseController | CombatManager | 6 | Entity medical/wounds (or CoreEntity API) |
| DamageApplicator (optional) | CoreEntity | 7 | Armor, BodyPartConstants, BleedingConstants |

Doing **1.1 (EntityMedical)** and **2.1 (AttackResolver)** first gives the largest readability and maintainability gain with clear boundaries.

---

<a id="combat-system-issues"></a>

## Source: `COMBAT_SYSTEM_ISSUES.md`

## Combat System Issues (from log analysis)

Identified from a full combat log (2v2 vs Goblins). Fixes applied where noted.

---

### 1. Crippled attackers still queue attacks (FIXED)

**Problem:** When a combatant lost both arms (e.g. Goblin), they kept entering wind-up and then at execute we printed "has no functional arm; skips attack" with a long recovery (1.5–1.8s). So they wasted full wind-up time every turn for no effect.

**Cause:** Attack commitment is made when gauge hits 100%; arm state is only checked at `_execute_attack`. AI was still given attack options and could commit, then arm was gone by execute (or was already gone when gauge filled).

**Fix applied:**
- `get_available_actions`: In combat phase, do not add attack options if `get_attacking_arm().is_empty()`.
- When AI has no actions but has an opponent, check `get_attacking_arm()` before calling `_begin_attack_with_target`. If no functional arm, put combatant in short recovery (0.8s) and clear gauge instead of starting wind-up.

Result: Combatants with no usable arm no longer do a full wind-up then skip; they take a short "skip turn" recovery.

---

### 2. "Deflected" outcome (FIXED)

**Was:** Deflected was used when tissue_dmg < pre_armor*0.25 but damage was still applied, which was misleading.

**Fix applied:**
- **Deflected** = all damage avoided (actual_dmg <= 0). Armor/angle fully prevented any tissue damage. Attacker gets short recovery (RECOVERY_EXTRA_DEFLECTED_S).
- **Glancing** = armor absorbed most but some got through (tissue_dmg < pre_armor * GLANCING_DAMAGE_RATIO). Damage is applied; outcome and recovery use RECOVERY_EXTRA_GLANCING_S.
- UI/logs distinguish both; BattleScene shows "(deflected — all avoided)" vs "(glancing)".

---

### 3. Partial parry follow-through: twist dodge (IMPLEMENTED)

**Problem:** After a partial parry, the attack continues with reduced velocity. The defender's body has already moved (twist, step) with the parry attempt. Should they get a second avoid chance?

**Implemented:** Twist dodge modeled on time and mobility at **start** of parry attempt (not after). Stored: `parry_twist_time_to_react`, `parry_twist_readiness`. `twist_capacity = time_factor × mobility × readiness`. Also: parry-quality scale (better parry → more twist benefit), attack-type mods (thrust −12%, cut +5%), part-specific modifier. Late parry gets 15% time floor for reflexive movement.

**Alternatives considered:**
- **No second roll:** Proceed straight to damage. Simpler; partial parry is the only mitigation.
- **Partial tier on twist:** Full dodge / partial twist (further reduce remaining_ratio) / hit. More granular but complex.
- **Scale by parry quality:** Better parry (lower remaining_ratio) → more residual slip. Plausible but adds parameters.

---

### 4. Goblin2 hit chance drop (perf_mod=0.35)

**Observation:** `Goblin2 -> Companion | perf_mod=0.92` later became `perf_mod=0.35 effective_hit=0.33 miss_chance=0.67 roll=0.007 => miss`. So the same attacker’s hit chance dropped sharply.

**Cause:** `get_hit_chance_performance_modifier()` uses pain/consciousness and head pain. Goblin2 took a lot of damage (head, chest, legs, etc.), so performance dropped. This is working as designed: injured fighters miss more.

No change needed unless you want to tune how fast hit chance degrades with injury.

---

### 5. Medical action wording (bandage_self on ally)

**Observation:** Log shows "Character chose medical bandage_self on part=left_leg (target_combatant_id=1)" and "Character starting bandage_self on part=left_leg" / "applying direct pressure on ally's left_leg". So the *move_id* is `bandage_self` but the *target* is an ally (Companion).

**Cause:** Same move_id is used for self and ally bandage; the target is distinguished by `target_combatant_id`. The name is confusing when target ≠ self.

**Recommendation:** In logs/UI, when target_combatant_id != performer, show something like "bandage (ally)" or use a separate move_id for ally bandage so it’s clear. Optional UX/clarity improvement only.

---

### 6. No functional arms → cowering / incapacitated (FIXED)

**Fix applied:**
- **is_cowering()** (CoreEntity): returns true when `get_attacking_arm().is_empty()` (both arms destroyed).
- **is_incapacitated()** now includes cowering: true when consciousness < threshold OR is_cowering(). So a unit with no usable arms counts as incapacitated for the fight (no gauge fill, not standing for victory).
- **STATE_COWERING**: When a combatant finishes recovery and has no functional arms, they enter STATE_COWERING instead of STATE_WAITING. Log: "[Combat] X is cowering (no functional arms)."
- When arm functionality returns (e.g. after medical/healing), if they have `is_cowering()` false, they leave cowering: state = STATE_WAITING, log "[Combat] X no longer cowering (arm functionality returned)."
- INCAPACITATED log shows "(cowering — no functional arms)" when applicable.

---

### 7. Recovery vs readiness (investigation)

**Question:** Should recovery or readiness be scaled differently for different attacks?

#### Recovery tracking (attacker only)

- **Who enters recovery:** The **attacker** (or medical performer). The defender never enters RECOVERING from parry or dodge; they go to WAITING immediately (parry_deflect gives `parry_bonus_until`).
- **Recovery duration** (`_recovery_duration`):
  - **Outcome:** hit (+0s). Deflected: base 0.1s + 0.15×intensity. Full_stop: base 0.5s + 0.35×intensity. Glancing (Method B): base 0.12s + (1−severity)×0.2×intensity; severity = tissue/(pre_armor×0.25). Miss/dodge: base 0.35s + 0.9×intensity.
  - **Archetype:** `recovery_multiplier` per move (stab/slash 1.0, overhead 1.2, quick_slash 0.85, pommel 0.9, heavy_blunt 1.15)
  - **Intensity** (commitment) scales base+extra; **agility** shortens; **perf_mod** (pain/consciousness) slows
  - **Attack type** (cut/thrust/blunt): does **not** affect recovery duration directly; only via archetype (chosen by move_id)

#### Readiness (defender’s parry capacity when attacked)

- **Definition:** `_get_passive_parry_readiness(c)` → WAITING = 1.0; RECOVERING = lerp(0.5, 0.85, progress) where `progress = state_timer / state_duration`.
- **When it applies:** When the **defender** is in RECOVERING (e.g. just attacked or did medical) and someone attacks them.
- **Uniform:** Same lerp(0.5, 0.85) for all recoveries. No stored “cause” (hit vs miss vs medical) and no incoming attack type.
- **Attack type:** Cut/thrust/blunt affects parry redirect efficiency and twist dodge (thrust −12%, cut +5%), but **not** the readiness multiplier itself.

#### Gaps for scaling

| Dimension | Current | Possible extension |
|----------|---------|--------------------|
| **Outcome-based readiness** | Same curve for any recovery cause | Different curves for “recovering from hit” vs “recovering from miss” (stunned vs off-balance) |
| **Incoming attack type** | No effect on readiness | Thrust incoming → harder to react (lower readiness); cut → same or easier (more telegraph) |
| **Recovery cause** | Not stored | Store `recovery_cause` (“attack_hit”, “attack_miss”, “attack_deflect”, “medical”) to drive readiness shape |
| **Archetype vs attack type** | Recovery uses archetype only | Explicit thrust/cut/blunt scaling for recovery or readiness if desired |

#### Verdict

- **Recovery duration** already scales by outcome and archetype; no per-attack-type scaling currently.
- **Readiness** is uniform and independent of incoming attack type. To scale by attack type you would:
  1. Pass the incoming `attack_type` (cut/thrust/blunt) into `_get_passive_parry_readiness` or the parry capacity calc.
  2. Optionally store `recovery_cause` when entering RECOVERING and use it to shape the readiness curve (early hit vs early miss could differ).

No code changes required unless you want attack-type or cause-dependent readiness.

**Implemented:** Guard/readiness — when in WAITING, parry capacity × guard. Guard drops to 0.4 when attacking or doing medical; rises at 0.6/s when idle.

---

### Summary

| Issue | Severity | Status |
|-------|----------|--------|
| Crippled attackers wind-up then skip | High | **Fixed** (no arm → no attack options; skip turn with short recovery) |
| "Deflected" vs "glancing" | Medium | **Fixed** (deflected = all avoided; glancing = some got through) |
| No arms → cowering/incapacitated | High | **Fixed** (STATE_COWERING; is_incapacitated includes cowering; clear when arms return) |
| Partial parry follow-through dodge | Design | **Implemented** (50% efficiency twist dodge) |
| Goblin2 perf drop | Working | No change |
| Medical move_id vs target | Low | **Fixed** (Bandaging ally, etc. in UI/logs) |

---
