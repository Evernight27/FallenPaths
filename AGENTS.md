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

**Implementation order (all combat plans):** `docs/IMPLEMENTATION_ORDER.md` (last verified vs repo: 2026-04-07). **Engagement / line cohesion:** `combat/CombatFormationEngagement.gd` (`CombatManager.engagement_state_changed`). **Gap / crash neighbors / intruder geometry:** `combat/CombatIntrusionGeometry.gd`. Detail: `docs/ENGAGEMENT_LINE_COHESION_INTRUSION_PLAN.md`.
