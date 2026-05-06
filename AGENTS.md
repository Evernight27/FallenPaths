# Fallen Paths — agent / IDE notes

Godot **4.x** project. Primary language: **GDScript**.

## Combat

- Orchestrator: `combat/CombatManager.gd` (instantiated by `ui/BattleScene.gd` using `ResourcePaths.COMBAT_MANAGER`).
- **Health / wounds node:** `CombatManager.get_health_entity(node)` — combat subsystems should use `CombatantEntityAccess.get_health_entity_from_node(manager, node)` or `get_entity_from_manager(manager, combatant)` (not `_get_entity` from outside the manager).
- **Formation dict keys (file index as int or string):** `CombatFileKeyedDict.get_value` and `FormationBreachRules.breached_file_severity` where relevant.
- Gameplay logic is split across `combat/*.gd` modules (tick, events, formation, engagement, snapshot, medical coordination, etc.); see `.cursor/rules/fallen-paths.mdc` for a fuller map.
- Balance and state names: `combat/CombatConstants.gd` (intentionally large).

## Core / UI

- Entity model: `core/` (e.g. `CoreEntity.gd`, `EntityDamage.gd`, …).
- Battle UI: `ui/BattleScene.gd` and related `ui/*Battle*`, `ui/*Combat*`, `ui/*Formation*`.

When changing combat flow, prefer editing the **focused module** rather than inflating `CombatManager.gd`.

Debug: `COMBAT_EVENT_DEBUG` enables turn-summary `[Combat.Flow]` lines; add `COMBAT_EVENT_DEBUG_VERBOSE` for per-action lists and formation/incursion spam (`CombatConstants.gd`). Player lead is flagged on `Character` via `is_party_leader` (scene + `PlayerCompanionSetup`); combatants carry `is_party_leader` from `CombatManager.register`.

**Combat plan index:** `docs/README.md`. **Execute:** `docs/IMPLEMENTATION_ORDER.md` — **P3–P6 shipped** (1.4 posture + **1.5** `CombatMoraleCohesion` / encounter + combatant `morale_cohesion`). **`FEATURE_LINE_CRASH_INTRUSION`** (in `CombatConstants.gd`) defaults **`false`** — no new line-crash intrusions until enabled; see plan **Development gate**. **Intruder host formation id** for ZoC + pair geometry: **`ZoneOfControl.formation_id_for_zone_geometry(manager, c)`** (also used by **`AvailableActionsBuilder`**). Optional **2.1** tactical doc prose. **Spec:** `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` §4–§6. **Code:** `combat/CombatFormationFlow.gd`, `combat/CombatFormationEngagement.gd`, `combat/ZoneOfControl.gd`, `combat/TacticalCombat.gd`, `combat/AvailableActionsBuilder.gd`, `combat/CombatIntrusionWedge.gd`, `combat/CombatIntrusionGeometry.gd`.
