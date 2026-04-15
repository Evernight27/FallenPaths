# Fallen Paths — agent / IDE notes

Godot **4.x** project. Primary language: **GDScript**.

## Combat

- Orchestrator: `combat/CombatManager.gd` (instantiated by `ui/BattleScene.gd` using `ResourcePaths.COMBAT_MANAGER`).
- Gameplay logic is split across `combat/*.gd` modules (tick, events, formation, engagement, snapshot, medical coordination, etc.); see `.cursor/rules/fallen-paths.mdc` for a fuller map.
- Balance and state names: `combat/CombatConstants.gd` (intentionally large).

## Core / UI

- Entity model: `core/` (e.g. `CoreEntity.gd`, `EntityDamage.gd`, …).
- Battle UI: `ui/BattleScene.gd` and related `ui/*Battle*`, `ui/*Combat*`, `ui/*Formation*`.

When changing combat flow, prefer editing the **focused module** rather than inflating `CombatManager.gd`.

**Combat plan index:** `docs/README.md`. **Execute:** `docs/IMPLEMENTATION_ORDER.md` — **P3 (Tier 1.2) shipped**; **Tier 1.3 (P4)** in progress: **`intrusion_wedge_by_file`** (`combat/CombatIntrusionWedge.gd`), **`lane_offset`**, wedge-aware **`effective_pair_eff_dist`**, lane stress + cohesion consumers. **Tier 1 spec:** `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md` §4–§6. **Code:** `combat/CombatFormationFlow.gd` (intrusion + wedges + vacancy/death plugs + **`reconcile_vacancy_plugs_*`** called from **`CombatManager.notify_formation_changed`** / **`get_available_actions`**), `combat/CombatFormationEngagement.gd`, `combat/TacticalCombat.gd`, `combat/AvailableActionsBuilder.gd`, `combat/CombatIntrusionGeometry.gd`.
