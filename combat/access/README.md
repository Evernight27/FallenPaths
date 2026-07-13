# access/

Combatant dictionary / entity / manager bridges.

| Module | Role |
|--------|------|
| `CombatantEntityAccess` | Canonical read/write surface for combatants |
| `CombatantRegister` | Initial combatant dict at `CombatManager.register` |
| `CombatantView` | Typed read wrapper over the dict |
| `CombatantFieldRegistry` | Key → owning package map |
| `Combatant*Access` / `CombatantManagerBridge` | Specialist helpers |
| `CombatantStatsSync` / `CombatCombatantsSnapshot` | Stats sync + snapshots |

Do not call `CombatManager._get_by_id` from new code — use EntityAccess.
