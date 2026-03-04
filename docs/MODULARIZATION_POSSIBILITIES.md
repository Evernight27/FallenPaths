# Modularization Possibilities

Audit of the codebase for extraction opportunities. Ordered by impact and dependency (do lower-numbered items first where dependencies exist).

---

## 1. CoreEntity.gd (~1,426 lines) — Highest impact

`CoreEntity` is a single class handling body state, damage, wounds, bleeding, blood volume, consciousness, pain, armor, weapons, and all medical actions. Below are **logical modules** that can be extracted. CoreEntity would keep the data (or a reference) and delegate to these components.

### 1.1 Medical subsystem → `core/EntityMedical.gd` (or child node)

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

### 1.2 Wounds & bleeding (injury model) → `core/EntityWounds.gd` or `core/EntityBleeding.gd`

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

### 1.3 Damage & severance pipeline → `core/EntityDamage.gd` or keep in CoreEntity with helpers

**Option A — Keep in CoreEntity:** `take_damage_split` is the central integration point (armor, bone/tissue split, severance, wounds, pain shock). It’s large but cohesive; you could leave it in CoreEntity and only extract **helpers** (e.g. severance ease, bone/tissue allocation) into static or `RefCounted` helpers.

**Option B — Extract damage executor:** Move `take_damage_split`, `take_damage`, `_get_severance_ease_factor`, and the bone/tissue/wound-add logic into a `DamageApplicator` that takes `(entity, cut_pre, blunt_pre, part, ...)` and mutates entity’s `body_cutting`, `body_blunt`, `bone_health`, `wounds`, and calls back for `_add_wound` / `_update_consciousness` / `_try_enter_pain_shock_from_hit`. CoreEntity would call `DamageApplicator.apply(entity, ...)`.

**Recommendation:** Start with **1.1 (Medical)** and **1.2 (Wounds/Bleeding)**; then decide whether `take_damage_split` stays in CoreEntity and only small helpers are extracted (Option A) or a full Damage module (Option B).

---

### 1.4 Pain & consciousness → `core/EntityPainConsciousness.gd`

**Move out:** Pain aggregation, effective pain for thresholds, consciousness and pain-shock.

| Responsibility | Functions |
|----------------|-----------|
| Pain | `get_total_pain`, `get_effective_pain_for_thresholds`, `get_effective_pain_for_region`, `_get_pain_contribution_for_wound`, `_get_pain_for_part`, `_get_pain_reference` |
| Consciousness | `_get_blood_consciousness_modifier`, `_mark_consciousness_dirty`, `_update_consciousness`, `_try_enter_pain_shock_from_hit`, `ensure_consciousness_current` |
| Performance | `get_effective_consciousness`, `get_performance_modifier`, `get_action_bar_performance_modifier`, `get_hit_chance_performance_modifier` |

**Data:** `consciousness`, `effective_consciousness`, `_pain_shock_until_time`, `_last_hit_impact`, `_consciousness_dirty`. These can live on CoreEntity and be passed to the component, or the component can own them and expose getters.

**Benefit:** Pain/consciousness tuning and performance modifiers live in one place; damage and medical code only trigger “dirty” or “recalc” instead of inlining formulas.

---

### 1.5 Body parts & targeting (minimal extraction)

**Keep in CoreEntity or extract to `core/BodyPartQuery.gd` (static):**  
`_get_body_part_list`, `_get_vital_parts`, `get_targetable_parts`, `_is_part_severed`, `_is_part_crushed`, `_is_part_destroyed`, `is_part_severed`. These are thin and use `body_cutting` / `body_blunt` / `bone_health` / `species`; moving them to a static helper that takes `(body_cutting, body_blunt, bone_health, body_max, bone_max, species)` would allow reuse (e.g. from CombatManager or UI) without tying CoreEntity to a new node. Optional.

---

### 1.6 Healing (time advance) → `core/EntityHealing.gd`

**Move out:** `process_healing(seconds)`: game time advance, wound resolution, bandage stabilization expiry, tourniquet expiry, tissue/bone/blood recovery. CoreEntity would call e.g. `healing_system.process_healing(entity, seconds)`.

**Data:** `_game_time_seconds`, and read/write to `wounds`, `body_cutting`, `body_blunt`, `bone_health`, `blood_volume`, `bandaged_parts`, `packed_parts`, `tourniquet_applied`. Either pass entity reference or a small “HealingState” struct that the component mutates.

**Benefit:** All “time passes” logic in one module; out-of-combat or rest systems can call the same logic.

---

### Suggested order for CoreEntity

1. **EntityMedical** (1.1) — done.
2. **EntityWounds/Bleeding** (1.2) — done. “bleeding rate” API.
3. **EntityPainConsciousness** (1.4) — used everywhere; isolate so damage/medical don’t need to know formulas.
4. **EntityHealing** (1.6) — done.
5. **BodyPartQuery** (1.5) — done: `core/BodyPartQuery.gd` (body part list, vital parts, targetable parts, part state, arm/leg functionality).
6. **Damage** (1.3) — Option B done: `core/EntityDamage.gd` has `apply_damage_split(entity, ...)` (armor, bone/tissue, wounds, early severance, stump, pain shock). Option A (severance ease) was done earlier.

---

## 2. CombatManager.gd (~1,550+ lines) — High impact

CombatManager handles: combatant registration, state machine, gauge fill, available actions (attack + medical), AI weighting, attack wind-up/execute, parry/dodge resolution, damage application, medical wind-up completion, and winner/medical phase.

### 2.1 Attack resolution (miss / dodge / parry / damage) → `combat/AttackResolver.gd` — done

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

### 2.2 Medical phase logic → `combat/MedicalPhaseController.gd` — done

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

### 2.3 Combat state machine (optional)

**Option:** Extract the `_process` state transitions (WAITING → gauge fill / turn_ready; WIND_UP → execute attack; MEDICAL_WIND_UP → complete medical; RECOVERING → WAITING/COWERING; RECEIVING_MEDICAL_ATTENTION) into a small `CombatStateMachine` that receives `(combatants, delta)` and returns “events” (e.g. `turn_ready(id)`, `execute_attack(id)`, …). CombatManager would drive the state machine and react to events.  
**Recommendation:** Lower priority; do 2.1 and 2.2 first so the remaining `_process` is easier to read.

---

## 3. Other files

### 3.1 character.gd

**Current role:** Thin wrapper around a child `CoreEntity` (CombatBody): exposes stats, movement, and combat/medical delegates. No need to split further; it’s already a facade. If you add more movement or overworld logic, consider a `CharacterMovement` or `CharacterController` script that only handles movement and input; `character.gd` stays as the node that composes CombatBody + movement.

### 3.2 PartyManager.gd

Single responsibility (party list and sync). No modularization needed unless you add inventory, formation, or persistence; then you could extract e.g. `PartyPersistence` or `PartyFormation`.

### 3.3 BattleScene.gd

**Current role:** Creates UI, instantiates CombatManager, registers combatants, connects signals, updates UI from combat events. Fits “scene controller” well. If it grows, consider:  
- Extracting **UI layout constants** (BODY_PARTS, BODY_LABELS, bar sizes) to a `BattleUIConstants.gd` or `BattleSceneConfig.gd`.  
- Extracting **log formatting** (e.g. “X -> Y hit/miss/dodge”) into a small `CombatLogFormatter` so BattleScene only appends formatted strings.

### 3.4 weapon/WeaponDamageHelper.gd

Already a static/RefCounted helper; no change needed. Keep damage constants in `WeaponConstants.gd`.

---

## 4. Cross-cutting: constants and autoloads

- **BleedingConstants, HealingConstants, PainConsciousnessConstants, BodyPartConstants:** Already separate; keep them. Any new “entity” module can preload these.
- **CombatManager as autoload:** Currently created by BattleScene. If you extract AttackResolver or MedicalPhaseController, they can be either standalone `RefCounted`/Node classes instantiated by CombatManager or autoloaded services; prefer “instantiated by CombatManager” to avoid global state.

---

## 5. Summary table

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
