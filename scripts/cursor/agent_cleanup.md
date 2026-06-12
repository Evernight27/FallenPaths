Stream: Hygiene — production code cleanup (second pass)

**Baseline:** Verify PHASE0 is green before starting.
```powershell
.\scripts\run_all_combat_checks.ps1
```
Expected: **`PHASE0: PASS`** + **`ii_envelop_mopup: PASS`**.

---

## Task: Second-pass production code cleanup

Remove dead code, unguarded debug output, and stale helpers from the project. Focus on production `.gd` files (not harness, not `scripts/`, not `docs/`).

### 1. Remove dead `_print_node_tree` function in main.gd

`main.gd` lines 277–282 define a `_print_node_tree()` helper that is never called anywhere. Remove the entire function.

```
func _print_node_tree(node: Node, indent: String = "") -> void:
	if node == null:
		return
	print(indent, node.name, "<", node.get_class(), ">")
	for child in node.get_children():
		_print_node_tree(child, indent + "  ")
```

### 2. Replace unguarded print with CombatDebug in BattleScene.gd

`ui/BattleScene.gd` line 107:
```gdscript
print("CombatManager missing")
```
Replace with `CombatDebug.operational_error("CombatManager preload failed")`. Preload the CombatConstants module if needed to check `combat_debug_active()`. This is a fatal error path but should use the centralized debug system.

### 3. Remove stale comments referencing old milestone labels

Search production `.gd` files for any remaining references to old milestone naming patterns:
- `S[0-9]\.[0-9]` (e.g., S2.0, S3.1) — campaign stream labels (deprecated in favor of Camp-N)
- `M[0-9]\.[0-9]` (e.g., M3.0) — combat stream labels (deprecated in favor of Combat maintain/Enhance)
- `F3`, `F4` — expand stream labels (deprecated in favor of Expand stream)

These should have been cleaned already, but do a final sweep. Only remove them from **code comments**, never from production logic. If you find any, replace with current terminology (Camp-N, Combat, Expand).

### 4. Add delegating comment to CampaignEncounterBridge.gd wrapper

`world/CampaignEncounterBridge.gd` has `entity_has_untreated_wounds(entity)` which delegates to `EntityWounds.entity_has_untreated_wounds(entity)`. Add a one-line comment above it noting the delegation to prevent future confusion:
```gdscript
## Delegates to EntityWounds.entity_has_untreated_wounds (canonical source).
```

---

## Gate

After all changes, run:
```powershell
.\scripts\run_all_combat_checks.ps1
```
Must return **`PHASE0: PASS`** + **`ii_envelop_mopup: PASS`**.

## Do not

- Edit production combat logic or resolvers
- Touch harness files (`*Tail.gd`, `CombatRegressionHarness.gd`)
- Add new `FEATURE_*` flags
- Modify `.uid` files
- Delete any file that is called from another module (verify with grep before removing)

## PR prefix: hygiene:
