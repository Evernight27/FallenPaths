# FF4 Formation + Stamina System — Consolidated Implementation Outline

Master implementation guide for the combat system migration. Consolidates decisions from the FF4 checklist, migration plan, stamina plan, and investigation docs.

---

## Part 1: Implementation Order

| Phase | Focus | Depends On | Key Deliverables |
|-------|-------|------------|------------------|
| **0** | Prep: data structures, constants | — | Combatant fields, formation structure, event queue |
| **1** | Event queue (replace gauge) | Phase 0 | Min-heap, EVENT_ACTION_READY, stamina UI |
| **2** | Distance bands | Phase 0 | Close/mid/long, roll vs evasion to close |
| **3** | Formations | Phase 0, 1 | Rank/file, targeting filter, swap rank, plug on death |
| **4** | Zone of control (ZoC) | Phase 3 | Zone control, flank access, engagement angle |
| **5** | Formation actions | Phase 3 | Fall back, rotate, drag back, step over; swap rank lane_clarity + pressure_mod |
| **6** | Tactical features | Phase 3–4 | Ambush, surround, breakthrough, flanking |

---

## Part 2: Locked Decisions Summary

### Distance Bands
- **Model:** Hybrid (C) — pair-wise for unformed, zone-based for formations
- **Close attempt:** Roll vs evasion (engagement_pressure vs defender evasion). Tie in stats. **Stances** modify close, damage, parry, disengage. See `docs/COMBAT_STANCE_STATES_INVESTIGATION.md`.

### Stance System (Phase 0 Data, Phase 2 Effects)
- **Four stances:** Defensive, Balanced, Aggressive, Controlling.
- **Driven by:** Stamina (gates), personality/trait (preference), weapon/skill, situation.
- **Effects:** Parry ×1.2/×0.8, evasion ×1.15/×0.85, damage ×0.85/×1.2, close attempt ×0.9/×1.1. **Controlling** makes opponent's disengage/close harder (×0.85, ×0.9).
- **Stamina gates:** Aggressive min 20–30; Controlling min 15–25. Below min → revert to balanced/defensive.

### ZoC
- **Phase:** 4 (after formations)
- **Type:** Full ZoC (D) — control = units + adjacent_support - incursion - casualties

### Formation Actions (Movement — Time-Based)
- **Swap rank / Fall back:** Time-based, **no stamina cost**. Duration = base × lane_modifier × pressure_modifier. See `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md`.
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
- [x] Add combatant fields: rank, file, formation_id, distance_to, engaged_with_id, engagement_angle, zone_id, occupied_zone_id, stance, stance_preference
- [x] Add formation structure (inline dict): files, ranks, density, zone_control, facing, slots, gaps, plug_rule
- [x] Add event_queue (array → min-heap in Phase 1), combat_clock to CombatManager
- [x] Add encounter dict (ambush_type, ambush_penalty)

### Phase 1: Event Queue
- [x] Implement min-heap event queue processing
- [x] EVENT_ACTION_READY → turn_ready / AI pick
- [x] Replace gauge-driven ready with event-driven
- [x] Update UI: stamina instead of gauge
- [x] **Hybrid event model:** Signals (formation_changed, turn_resolved) drive scheduling; _schedule_action_ready centralizes ACTION_READY with cancel-before-schedule to avoid duplicates. See `docs/BACK_RANK_WAIT_EVENT_LISTENER_VS_FIXED_COOLDOWN_INVESTIGATION.md`.

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
- [x] Add swap rank action (time-based event delay; fixed lane_mod=1.0, pressure_mod=1.0 for now; dynamic in Phase 5)
- [x] **Formation UI:** Visual rank×file grid with unit spacing (tight/normal/loose); FormationLayoutBuilder + FormationDiagramBuilder (compact diagram updates on formation_changed)
- [x] **Plug on death (rank advance):** When rank 0 unit dies, rank 1 in same file automatically advances to rank 0. Prevents units from being stuck unable to melee. Required before Phase 4 for accurate testing. See `docs/FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md` §2 (plug_rule: rank_advance).
- [x] **Dead/wounded in slots (tracked, non-blocking):** Dead or incapacitated units remain tracked in their slot as ground obstacles (`slot_obstacles`). They do NOT block movement—allies can step over them. Footing modifier (×1.15–1.25) when moving through slot with bodies → Phase 5 (Step over fallen).

### Phase 4: ZoC
- [ ] Zone control calculation per zone (front, left, right, rear)
- [ ] Flank access when control < threshold
- [ ] Engagement angle assignment (from zone occupancy or pack approach)
- [ ] Zone-based distance for formation vs formation (hybrid)

### Phase 5: Formation Actions
- [ ] Fall back: disengage + move to rear zone or full retreat; duration per movement model
- [ ] **Swap rank — lane clarity:** Replace fixed lane_mod with dynamic `get_lane_clarity(formation, rank, file)`. Clear=1.0×, crowded=1.3×, blocked=1.6×. See `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md` §2.3.
- [ ] **Swap rank — pressure modifier:** Replace fixed pressure_mod with dynamic `get_opponent_pressure(opponent)`. Defensive=0.9×, neutral=1.0×, aggressive=1.3×. See `docs/MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md` §2.4.
- [ ] **Swap rank — UI (optional):** Show swap duration or reason (e.g. "1.2s (crowded)") when lane/pressure are dynamic.
- [ ] Drag back: rear ranks pull wounded from front (distraction deficit)
- [ ] Step over fallen: footing modifier when moving through slot with dead/wounded (×1.15–1.25 duration). Bodies tracked, non-blocking. See Part 4.5.
- [ ] Multi-unit same slot with deficits
- [ ] Rotate: rank shift, file shift (advanced)

### Phase 6: Tactical Features
- [ ] Ambush: formation facing, penalties (per plan)
- [ ] Surround: defense splitting, awareness factor
- [ ] Breakthrough: plug vs incursion contest (incursion when plug fails; requires ZoC). Basic plug on death is Phase 3.
- [ ] Flanking: ZoC-based + pack fallback; apply modifiers

---

## Part 4: Phase Order — Critical for Testing

**Plug on death (rank advance)** is a Phase 3 item that must be completed before Phase 4. Without it, when a rank 0 unit dies, the rank 1 unit in that file cannot advance and is stuck unable to melee—breaking formation combat. Implement when rank 0 dies: remove dead unit from slots; promote rank 1 in same file to rank 0; emit formation_changed. Simple automatic plug (no roll); full plug vs incursion contest is Phase 6.

**Phase 5 features** (lane clarity, pressure modifier, fall back, drag back, rotate) can wait until after Phase 4. They refine formation behavior but do not block basic testing.

### Part 4.5: Dead/Wounded in Slots — Tracked but Non-Blocking

**Design:** Dead or incapacitated (wounded on ground) units stay tracked in their formation slot. They occupy space for awareness (medical, finishing, line of sight) but do **not** block movement.

| Aspect | Behavior |
|--------|----------|
| **Tracking** | `formation.slot_obstacles[(rank, file)]` = Array of combatant_ids (dead or incapacitated) in that slot. Or: combatant keeps rank/file until removed; `alive`/`incapacitated` flags determine if they block. |
| **Blocking** | Dead/wounded do NOT block. Lane clarity "blocked" = living unit in the way only. Rank 1 can advance over dead rank 0. |
| **Footing** | When moving through/over a slot with bodies: apply footing modifier (e.g. swap/fall-back duration ×1.15–1.25). "Step over fallen" — reduced footing, but movement still possible. |
| **Active actions** | Dead/wounded take no actions (no attacks, no swap). They are passive occupants. |
| **Plug on death** | Rank 0 dies → becomes ground obstacle in slot. Rank 1 advances into slot (standing over/near body). Slot now has primary occupant (rank 1) + obstacles ([dead]). |

**Data:** Add `formation.slot_obstacles` or equivalent; when unit dies/incapacitated, add to obstacles at (rank, file). When computing lane clarity and movement duration, check for obstacles and apply footing modifier. See `docs/FF4_REMAINING_DECISIONS_CHECKLIST.md` §3 (Step over fallen).

---

## Part 5: Deferred Items

| Item | When |
|------|------|
| Multi-target (close slots, AI weighting, defense split max) | Implementation |
| Parry choice (threat scoring) | Multi-target phase |
| Surround max split divisor | Phase 6 |
| Disengagement investigation (health/morale/rout) | Phase 5 |
| ZoC extent modifier on reach | Phase 4+ |
| Leader abilities (formation flexibility) | Later |

---

## Part 6: Source Documents

| Document | Role |
|----------|------|
| **FF4_REMAINING_DECISIONS_CHECKLIST.md** | All decisions; final choices |
| **FF4_ABSTRACT_FORMATION_MIGRATION_PLAN.md** | Full design, options, data structures |
| **STAMINA_SYSTEM_IMPLEMENTATION_PLAN.md** | Event queue, distance bands, stamina, engagement |
| **FF4_FORMATION_DISTANCE_AMBUSH_BREAKTHROUGH_INVESTIGATION.md** | Distance expansion, breakthrough, targeting |
| **ENGAGEMENT_ANGLE_VS_ZOC_FLANKING_INVESTIGATION.md** | Flanking approach (hybrid) |
| **ZONE_OF_CONTROL_QUANTUM_POSITIONING_INVESTIGATION.md** | ZoC structure |
| **FORMATION_SURROUND_MULTI_ANGLE_INVESTIGATION.md** | Surround, pack behavior |
| **COMBAT_STANCE_STATES_INVESTIGATION.md** | Four stances, modifiers, stamina gates |
| **MEDIEVAL_FORMATION_MOVEMENT_SWITCHING_INVESTIGATION.md** | Swap/fall back: time-based, lane, pressure |

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
| Stance min stamina: aggressive | 25 |
| Stance min stamina: controlling | 20 |
