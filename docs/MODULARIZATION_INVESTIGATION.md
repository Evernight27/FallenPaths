# Modularization Investigation

Additional modularization opportunities beyond what's in MODULARIZATION_POSSIBILITIES.md. Current state as of recent extractions (CombatTiming, CombatAIActionPicker, CombatantRowBuilder, BattleUIConstants progress bar style).

---

## Bug (fixed)

~~**BattleScene.gd line 368** still calls `manager.pick_weighted_action(actions, combatant_id)`~~ **Done:** TurnReadyHandler and CombatStateHandlers use `CombatAIActionPicker.pick()`.

---

## 1. CombatManager (957 lines) — Still largest file

### 1.1 Medical wind-up completion → `combat/MedicalWindUpHandler.gd`

**Lines 534–609**: The `STATE_MEDICAL_WIND_UP` timer-done block is ~75 lines of repetitive logic (bandage/packing/tourniquet outcome handling with nearly identical branches). Extract to a static handler that:
- Takes (manager, combatant, pending_medical, tgt_c)
- Applies the target method, emits action_resolved, tracks retry
- Returns recovery_duration

**Interface:** `MedicalWindUpHandler.complete(manager, c, pm, tgt_c) -> float` (returns med_rec_dur).

**Benefit:** Reduces CombatManager `_process` by ~70 lines; medical outcome handling lives in one place.

---

### 1.2 `_start_medical_action` → `combat/MedicalActionStarter.gd`

**Lines 668–759**: ~90 lines for medical action setup (direct pressure during wind-up, instant direct_pressure path, bandage/tourniquet/pack wind-up duration calculation). Could be extracted so CombatManager only calls `MedicalActionStarter.start(manager, combatant_id, target_combatant_id, medical_id, target_part)`.

**Benefit:** Medical setup logic isolated; CombatManager becomes thinner orchestrator.

---

### 1.3 Combat state machine (optional, lower priority)

**Lines 454–626**: The `_process` loop handles DEAD, RECEIVING_MEDICAL_ATTENTION, WAITING, WIND_UP, MEDICAL_WIND_UP, RECOVERING. Per the original doc, a `CombatStateMachine` could receive (combatants, delta) and return events. The remaining ~170 lines of state handling could be split into smaller handlers per state.

**Recommendation:** Do 1.1 and 1.2 first; the remaining `_process` may be readable enough. Revisit if it grows.

---

## 2. AttackResolver (566 lines) — Second largest

### 2.1 Parry/dodge choice logic → `combat/DefenseChoiceResolver.gd`

**Lines 242–410**: ~170 lines for passive parry setup, parry capacity, defense choice (parry vs dodge), and partial parry follow-through. This is a distinct sub-flow: “given attack params and defender state, choose parry or dodge and compute parry capacity/timing.”

**Interface:** `DefenseChoiceResolver.choose_defense(manager, atk, tgt, targetable, attack_type, intensity, …) -> Dictionary` returning `{ "defense": "parry"|"dodge", "parry_p_a": float, "parry_c_d": float, "can_parry_in_time": bool, "late_parry": bool, … }`.

**Benefit:** AttackResolver shrinks by ~150 lines; parry/dodge tuning isolated.

---

### 2.2 Damage computation (pre-armor, penetration) → keep in AttackResolver

`compute_and_apply_damage` is already a static method. The damage formulas and weapon physics are cohesive. Further splitting (e.g. a `DamageComputer` that only does pre-armor math) adds indirection without clear benefit unless you need to reuse that math elsewhere.

---

## 3. BattleScene (460 lines)

### 3.1 `_update_ui` gauge/state label logic → `ui/BattleUIUpdater.gd`

**Lines 239–316**: ~80 lines that map combatant state to gauge value, gauge_label text, blood/bleeding labels, consciousness, and body bars. Extract to e.g.:
`BattleUIUpdater.update_combatant_row(ctrl, c)`.

**Benefit:** BattleScene `_update_ui` becomes a short loop over combatants calling the updater; label-formatting logic centralized.

---

### 3.2 `_create_ui` layout → `ui/BattleUILayout.gd`

**Lines 94–217**: The programmatic UI creation (canvas layer, overlay, panels, scroll, combat log) is ~125 lines. Could be moved to `BattleUILayout.create(scene: Node) -> Dictionary` returning `{ "canvas_layer": …, "content_vbox": …, "combat_log": …, "main_hbox": … }` so BattleScene only wires nodes and stores references.

**Trade-off:** Layout is inherently coupled to BattleScene’s structure; extraction may not simplify unless you plan to support alternate layouts (e.g. a “minimal” combat UI).

---

## 4. CoreEntity (469 lines) — Already well modularized

CoreEntity delegates to EntityMedical, EntityWounds, EntityPainConsciousness, EntityHealing, EntityDamage, BodyPartQuery. Remaining code is thin glue (data, signals, delegating calls). No obvious further extraction.

---

## 5. character.gd (294 lines)

Mostly delegation to CombatBody (CoreEntity). The movement logic (`_physics_process`, target_position, is_moving) is ~50 lines. If movement grows, consider `CharacterMovement` or `CharacterController`, but current size is fine.

---

## 6. main.gd (~111 lines)

Already orchestration-only. Party setup, encounter spawner, tileset, combat flow are extracted. No further modularization needed.

---

## 7. Cross-cutting

### 7.1 ResourcePaths

Add `core/ResourcePaths.gd` or `ResourcePaths.gd` with constants like `SCENE_BATTLE := "res://scenes/battle.tscn"`, weapon paths, etc. Reduces string literals scattered in main, CombatFlow, EncounterSpawner.

### 7.2 BleedingConstants (321 lines)

Mostly data (rates, multipliers, sub-regions). Some helper functions (e.g. severity lookup) could stay. No urgent extraction.

---

## 8. Summary table

| Extraction                    | Source          | Est. lines moved | Priority | Status   |
|-----------------------------|-----------------|-----------------|----------|----------|
| Fix BattleScene pick_weighted | BattleScene     | 1               | **Urgent** | Done     |
| MedicalWindUpHandler       | CombatManager   | ~70             | High     | **Done** |
| MedicalActionStarter        | CombatManager   | ~90             | High     | **Done** |
| DefenseChoiceResolver       | AttackResolver  | ~150            | Medium   | Skipped* |
| BattleUIUpdater             | BattleScene     | ~80             | Medium   | **Done** |
| BattleUILayout              | BattleScene     | ~125            | Low      | **Done** |
| ResourcePaths               | New             | ~20 (new file)  | Low      | **Done** |

\*DefenseChoiceResolver: Tight coupling and interleaved logic make extraction add complexity without clear benefit.

---

## Suggested order (remaining)

All listed extractions have been completed. Future opportunities: DefenseChoiceResolver (if refactored to reduce coupling), further CombatManager state-machine extraction.

---

## 9. Current state & additional opportunities (post-modularization audit)

**Line counts (as of audit):**

| File               | Lines | Notes                                      |
|--------------------|-------|--------------------------------------------|
| CombatManager.gd  | 793   | Still largest; state machine + stats sync  |
| AttackResolver.gd  | 566   | Parry/dodge block ~170 lines               |
| CoreEntity.gd      | 469   | Well modularized; thin glue               |
| character.gd       | 294   | Facade; movement ~50 lines                 |
| BattleScene.gd     | 272   | Slimmed via BattleUILayout/Updater         |
| PartyManager.gd    | 152   | Single responsibility                      |
| main.gd            | 110   | Orchestration-only                         |

### 9.1 CombatantStatsSync — Unify stats refresh (high value, low risk)

**Problem:** `_refresh_combatant_stats(c)` (lines 60–96) and `get_combatants()` (lines 206–231) duplicate the same entity→stats copy logic (body_cutting, body_blunt, bone_health, blood_volume, total_bleeding_rate, effective_consciousness, performance_modifier, total_pain, strength, agility, perception).

**Extract:** `combat/CombatantStatsSync.gd` (static class):

```gdscript
static func sync_from_entity(entity: Node, stats: Dictionary, ensure_consciousness: bool = true) -> void
```

- Centralizes the entity read logic.
- `_refresh_combatant_stats` calls `CombatantStatsSync.sync_from_entity(entity, c.stats)`.
- `get_combatants` calls `ensure_consciousness_current` then `sync_from_entity` into a temp stats dict before building the output.

**Benefit:** ~35 lines removed from CombatManager; single source of truth for stats sync; easier to add/change stats fields.

---

### 9.2 Passive parry / off-balance helpers → `combat/PassiveParryContext.gd`

**Problem:** `_get_parry_config`, `_get_passive_parry_readiness`, `_is_off_balance` live in CombatManager but are used by AttackResolver via `manager._get_passive_parry_readiness(tgt)` etc. This coupling makes DefenseChoiceResolver extraction harder.

**Extract:** `combat/PassiveParryContext.gd` (static class):

- `get_parry_config() -> Dictionary` — returns CombatConstants-based config.
- `get_passive_parry_readiness(c: Dictionary) -> float` — pure function given combatant dict.
- `is_off_balance(c: Dictionary) -> bool` — pure function.

**Interface change:** AttackResolver calls `PassiveParryContext.get_passive_parry_readiness(tgt)` instead of `manager._get_passive_parry_readiness(tgt)`. CombatManager can remove these methods or delegate to PassiveParryContext.

**Benefit:** Decouples AttackResolver from CombatManager; sets groundwork for DefenseChoiceResolver extraction later.

---

### 9.3 Combat state machine per-state handlers (low priority)

**Location:** CombatManager `_process`, ~170 lines (lines 398–555).

**Option:** Split into small handlers, e.g.:

- `CombatStateHandlers.process_dead(...)`
- `CombatStateHandlers.process_receiving_medical(...)`
- `CombatStateHandlers.process_waiting(...)`
- `CombatStateHandlers.process_wind_up(...)`
- `CombatStateHandlers.process_medical_wind_up(...)`
- `CombatStateHandlers.process_recovering(...)`

**Recommendation:** Only if `_process` grows again or becomes hard to follow. Current structure is acceptable.

---

### 9.4 PartyMenu / party display (optional)

**PartyMenu.gd** (82 lines) builds party rows with body part labels, blood, weapon, armor. `CombatantRowBuilder` and `BattleUIUpdater` handle similar body-part display in combat.

**Opportunity:** Share a `PartyRowFormatter` or use `BodyPartConstants` / `BattleUIConstants` for consistent labels and layout. Low impact unless party UI expands.

---

### 9.5 DefenseChoiceResolver re-evaluation

**Original assessment:** "Tight coupling and interleaved logic make extraction add complexity without clear benefit."

**If 9.2 (PassiveParryContext) is done first:** AttackResolver would no longer call `manager._get_parry_config`, `manager._get_passive_parry_readiness`, or `manager._is_off_balance`. The parry/dodge block (lines 242–410) could then be moved to `DefenseChoiceResolver.choose_defense(...)` with a cleaner interface.

**Revised recommendation:** Do 9.2 first; then reassess DefenseChoiceResolver. If extraction still feels brittle, leave as-is.

---

## 10. Summary of remaining opportunities

| Optimization           | Source          | Est. lines moved | Priority | Complexity | Status |
|------------------------|-----------------|------------------|----------|------------|--------|
| CombatantStatsSync     | CombatManager   | ~35              | High     | Low        | **Done** |
| PassiveParryContext    | CombatManager   | ~25              | Medium   | Low        | **Done** |
| DefenseChoiceResolver | AttackResolver  | ~170             | Low*     | Medium     | **Done** |
| State machine handlers| CombatManager   | ~170 split       | Low      | Medium     | **Done** |
| PartyRowFormatter     | PartyMenu       | ~20 shared       | Low      | Low        | **Done** |
| AttackResultApplier  | CombatManager   | ~95              | Medium   | Low        | **Done** |
| AvailableActionsBuilder | CombatManager | ~80              | Medium   | Low        | **Done** |

\*DefenseChoiceResolver becomes viable after PassiveParryContext.

---

## 11. Additional modularization opportunities (post-comprehensive refactor)

Current line counts (largest files): CombatManager 449, CoreEntity 469, AttackResolver 440, BleedingConstants 321, WeaponConstants 303, EntityMedical 297, character 294, BattleScene 272.

### 11.1 CombatManager: Attack wind-up setup → `combat/AttackWindUpStarter.gd`

**Location:** `_begin_attack_with_target` (lines 347–406), ~60 lines.

**Logic:** Power/follow-through roll, intensity calc, weapon/attack_type selection, wind-up duration (CombatTiming, leg, pain, agility), pending_attack setup.

**Interface:** `AttackWindUpStarter.start(manager, attacker_id, target_id, move_id) -> void`

**Benefit:** CombatManager shrinks further; attack initiation lives in one place.

**Complexity:** Low. Manager passes self; starter calls `manager._get_by_id`, mutates combatant, sets state.

---

### 11.2 AttackResolver: Partial parry follow-through + dodge resolution

**Location:** Lines 272–350 (~80 lines): `already_used_defense` (twist dodge from partial parry) and `defense_choice == "dodge"` (full/partial dodge roll).

**Option:** Move to `DefenseResolutionHandler` or extend `DefenseChoiceResolver` with `resolve_defense_outcome(...)` that takes the choice and performs the roll/mutation. DefenseChoiceResolver currently only *chooses*; resolution (roll, pa mutation, return) stays in AttackResolver.

**Trade-off:** Defense flow would be: choose → resolve. Extracting resolution would centralize dodge/parry-follow logic but adds another hop. Current structure is still readable.

**Recommendation:** Low priority; revisit if AttackResolver grows.

---

### 11.3 AttackResolver: Pre-armor damage / penetration block

**Location:** `compute_and_apply_damage` lines 37–80 (weapon branch) and 71–79 (unarmed fallback). ~45 lines of pre_armor, cut_ratio, penetration.

**Doc note:** "Damage computation — keep in AttackResolver. Further splitting adds indirection without clear benefit unless you need to reuse that math elsewhere."

**Recommendation:** Leave as-is unless you add a dedicated damage preview or armor tooltip that needs the same formulas.

---

### 11.4 CoreEntity: Armor/weapon helpers

**Location:** `get_armor_for_part`, `get_armor_sharp_resistance_for_part`, `get_armor_slots`, `equip_armor`, `get_weapon`, `equip_weapon`, `get_attacking_arm`, `get_attack_damage_modifier` — ~50 lines.

**Option:** Extract to `core/EntityEquipment.gd` (armor + weapon + attacking arm logic). CoreEntity would delegate.

**Benefit:** Equipment logic isolated; CoreEntity becomes thinner.

**Complexity:** Low. EntityEquipment would need `armor_slots`, `weapon`, `dominant_hand`, `offhand_functionality` and call into BodyPartQuery / EntityPainConsciousness for arm functionality.

**Recommendation:** Optional; CoreEntity is already well split.

---

### 11.5 character.gd: Movement logic

**Location:** `_physics_process`, `target_position`, `is_moving` — ~50 lines (pathfinding, tile targeting).

**Doc note:** "If movement grows, consider CharacterMovement or CharacterController."

**Recommendation:** Keep as-is at 294 lines; extraction only if movement becomes more complex.

---

### 11.6 PartyManager: Member snapshot / get_members

**Location:** `get_members` (lines 74–146), ~73 lines. Reads `node_ref` and builds dict with body_cutting, body_blunt, weapon_name, armor_summary, blood_volume, etc.

**Overlap:** Similar to `CombatantStatsSync` and `PartyRowFormatter` — copying entity state for display.

**Option:** `PartyMemberSnapshot.snapshot_from_node(node) -> Dictionary` or reuse/extend `CombatantStatsSync` for party snapshot. PartyManager would call it per member.

**Benefit:** Single place for "node → display dict"; PartyManager shrinks.

**Recommendation:** Medium priority; reduces duplication with combat stats sync.

---

### 11.7 BattleScene: Turn-ready / action dispatch

**Location:** `_on_turn_ready` (lines 155–184), ~30 lines. Finds combatant, branches on side, empty-actions fallback, CombatAIActionPicker.pick, resolve_action.

**Option:** `PlayerTurnHandler.handle_turn_ready(scene, manager, combatant_id)` — encapsulates "player side: choose or auto-attack; AI: pick and resolve."

**Benefit:** BattleScene stays focused on UI lifecycle; turn logic isolated.

**Complexity:** Low. Scene passes manager and combatant_id; handler uses existing APIs.

---

### 11.8 BattleScene: Combat log + scroll + end-button flow

**Location:** `_append_combat_log`, `_scroll_combat_log_to_bottom` (and deferred variants), `_show_end_battle_button`, `_on_end_battle_button_pressed` — ~45 lines total.

**Option:** `BattleSceneHelpers` or keep inline. The scroll-defer pattern is a bit intricate; extracting might obscure it unless you add multiple log consumers.

**Recommendation:** Low priority.

---

### 11.9 BleedingConstants (321 lines)

**Content:** Rates, multipliers, sub-regions, helper lookups. Mostly data.

**Recommendation:** No extraction unless helpers grow. Splitting data from helpers adds files without much gain.

---

### 11.10 Summary of new opportunities

| Opportunity            | Source        | Est. lines | Priority | Complexity |
|-------------------------|---------------|------------|----------|------------|
| AttackWindUpStarter     | CombatManager | ~60        | Medium   | Low        | **Done** |
| PartyMemberSnapshot     | PartyManager  | ~70        | Medium   | Low        | **Done** |
| PlayerTurnHandler       | BattleScene   | ~30        | Low      | Low        | **Done** (TurnReadyHandler) |
| EntityEquipment         | CoreEntity    | ~50        | Low      | Low        |
| Defense resolution      | AttackResolver| ~80        | Low      | Medium     |

Suggested order if continuing: **AttackWindUpStarter** (clear win), then **PartyMemberSnapshot** (reduces duplication with combat/party display).

---

## 12. March 2025 Implementation (Completed)

The following modularization improvements were implemented:

### 12.1 Stats sync unification
- **CombatantStatsSync.sync_from_entity_for_register(entity)** — Returns initial stats dict for combatant registration. Single source of truth for entity→stats copy.
- **CombatManager** — Replaced `_read_stats_from` with `_StatsSync.sync_from_entity_for_register()`.
- **AttackResolver.compute_and_apply_damage** — Replaced manual stats copy (body_cutting, body_blunt, total_pain, etc.) with `_StatsSync.sync_from_entity()`.

### 12.2 EntityEquipment extraction
- **core/EntityEquipment.gd** — New static class for armor/weapon logic. Methods: `get_armor_for_part`, `get_armor_sharp_resistance_for_part`, `get_armor_slots`, `equip_armor`, `get_weapon`, `equip_weapon`, `get_attacking_arm`, `get_attack_damage_modifier`.
- **CoreEntity** — Delegates all equipment methods to `_EntityEquipment`.

### 12.3 CombatantEntityAccess helper
- **combat/CombatantEntityAccess.gd** — Centralized access for `get_weapon(combatant)`, `has_weapon(combatant)`, `get_entity_from_manager(manager, combatant)`, `get_weapon_from_node(node)`, `get_armor_slots_from_node(node)`.
- **AttackResolver** — Uses `_EntityAccess.get_weapon(atk)` and `_EntityAccess.has_weapon(tgt)`.
- **DefenseChoiceResolver** — Uses `_EntityAccess.get_weapon()`, `_EntityAccess.has_weapon()` for all weapon checks.
- **AttackWindUpStarter** — Uses `_EntityAccess.get_weapon(atk)`.
- **AvailableActionsBuilder** — Uses `_EntityAccess.get_weapon(c)`.
- **CombatantRowBuilder** — Uses `_EntityAccess.get_weapon_from_node(node)`, `get_armor_slots_from_node(node)`.
- **PartyMemberSnapshot** — Uses `_EntityAccess.get_weapon_from_node(node_ref)`, `get_armor_slots_from_node(node_ref)`.

### 12.4 CombatStateHandlers process helpers
- **process_death_tick(manager, c)** — Checks if combatant died (e.g. bled out), mutates c, emits action_resolved, returns victor.
- **process_incapacitation(manager, c)** — Handles cowering recovery when arm returns; returns true if skip.
- **process_medical_wind_up_cancel(manager, c)** — Cancels medical wind-up if target died; returns true if cancelled.
- **CombatManager._process** — Refactored to use these handlers; ~75 lines of inline logic moved to CombatStateHandlers.

### 12.5 Defense resolution (Completed March 2025)
- **combat/DefenseResolutionHandler.gd** — Extracted partial parry follow-through (twist dodge), full/partial dodge, and parry deflect/partial resolution from AttackResolver. `resolve()` returns a result dict or null to fall through to hit. AttackResolver reduced from ~480 to ~343 lines.

### 12.6 Additional extractions (March 2025)
- **BattleUIUpdater** — Uses `PartyRowFormatter.format_body_part()` for body labels instead of duplicated format string.
- **EntityMedical** — `_apply_stabilizing_treatment()` shared helper for bandage and packing wound treatment. Removes ~50 lines of duplication between apply_bandage and apply_packing.

### 12.7 Entity access helpers (March 2025)
- **CombatantEntityAccess** — Added `get_medical_effectiveness_from_node(node)`, `get_permanent_bleeding_rate_from_node(node, fallback)`. Eliminates repeated `has_method` + call pattern in EntityMedical, MedicalActionStarter, MedicalWindUpHandler, MedicalPhaseController.
- **BattleUIUpdater** — Extracted blood_volume to local var to avoid duplicate stats.get().

### 12.8 Additional modularization (March 2025)

- **CombatAIActionPicker** — Extracted `_get_action_weight()` to eliminate duplicated medical weight calculation (urgency, direct pressure bleed rate, pending retry) from both loops.
- **core/EntityTimeAdvance.gd** — New static class for entity time advancement: `advance(entity, delta_or_seconds, include_healing)`. Used by CombatManager (delta, no healing) and main._advance_time_one_minute (seconds, with healing). Single source for process_bleeding, process_blood_loss, process_healing calls.
- **CombatantEntityAccess** — Added `get_weapon_display_name_from_node(node)` and `get_armor_summary_from_node(node)` for UI display. CombatantRowBuilder and PartyMemberSnapshot use these instead of duplicating weapon/armor name extraction.
