# FF4 Formation + Stamina System — Consolidated Implementation Outline

Master implementation guide for the combat system migration. Consolidates decisions from the FF4 checklist, migration plan, stamina plan, and investigation docs.

---

## Part 1: Implementation Order

| Phase | Focus | Depends On | Key Deliverables |
|-------|-------|------------|------------------|
| **0** | Prep: data structures, constants | — | Combatant fields, formation structure, event queue |
| **1** | Event queue (replace gauge) | Phase 0 | Min-heap, EVENT_ACTION_READY, stamina UI |
| **2** | Distance bands | Phase 0 | Close/mid/long, roll vs evasion to close |
| **3** | Formations | Phase 0, 1 | Rank/file, targeting filter, swap rank |
| **4** | Zone of control (ZoC) | Phase 3 | Zone control, flank access, engagement angle |
| **5** | Formation actions | Phase 3 | Fall back, rotate, drag back, step over |
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
- **Visual representation:** Battle UI shows formations as rank×file grids; unit spacing reflects density (tight/normal/loose). Spacing constants: `SPACING_TIGHT`→compact, `SPACING_NORMAL`→default, `SPACING_LOOSE`→wide.
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
- [x] Add swap rank action (time-based event delay; lane + pressure modifiers; no stamina cost)
- [x] **Formation UI:** Visual rank×file grid with unit spacing (tight/normal/loose); see Part 2.5

### Phase 4: ZoC
- [ ] Zone control calculation per zone (front, left, right, rear)
- [ ] Flank access when control < threshold
- [ ] Engagement angle assignment (from zone occupancy or pack approach)
- [ ] Zone-based distance for formation vs formation (hybrid)

### Phase 5: Formation Actions
- [ ] Fall back: disengage + move to rear zone or full retreat; duration per movement model
- [ ] Swap rank: time-based; lane_clarity (clear/crowded/blocked), opponent_pressure (defensive/neutral/aggressive)
- [ ] Drag back: rear ranks pull wounded from front (distraction deficit)
- [ ] Step over fallen (reduced footing, quicker)
- [ ] Multi-unit same slot with deficits
- [ ] Rotate: rank shift, file shift (advanced)

### Phase 6: Tactical Features
- [ ] Ambush: formation facing, penalties (per plan)
- [ ] Surround: defense splitting, awareness factor
- [ ] Breakthrough: plug vs incursion contest (per plan)
- [ ] Flanking: ZoC-based + pack fallback; apply modifiers

---

## Part 4: Deferred Items

| Item | When |
|------|------|
| Multi-target (close slots, AI weighting, defense split max) | Implementation |
| Parry choice (threat scoring) | Multi-target phase |
| Surround max split divisor | Phase 6 |
| Disengagement investigation (health/morale/rout) | Phase 5 |
| ZoC extent modifier on reach | Phase 4+ |
| Leader abilities (formation flexibility) | Later |

---

## Part 5: Source Documents

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

## Part 6: Quick Reference — Key Constants

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
| Stance min stamina: aggressive | 25 |
| Stance min stamina: controlling | 20 |
