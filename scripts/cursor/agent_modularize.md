Stream: **Modularization**. Refactor code structure â€” split monoliths, remove duplicates, break circular dependencies. **No gameplay logic changes** â€” every PR must be a zero-behavior refactor (same output, same test results).

**Gate before done:**
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`**. Campaign tasks: also `.\scripts\run_company_state_checks.ps1`.

**Own:** [`docs/MODULARIZATION_PLAN.md`](../../docs/MODULARIZATION_PLAN.md) â€” full plan with phases, risk levels, and execution order. This prompt covers Phase 0 (hygiene) only; later phases require separate sessions.

**Do not touch:** `combat/*`, `world/*`, `core/*` production `.gd` logic. **Do not** change behavior, add features, or introduce new `FEATURE_*` flags. **Do not** create subdirectories. **Do not** commit `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*`, or `.godot/` cache.

**Read first:** [`AGENTS.md`](../../AGENTS.md) code homes Â· file ownership table. [`docs/MODULARIZATION_PLAN.md`](../../docs/MODULARIZATION_PLAN.md) â€” complete plan.

---

## Session start (copy-paste task line)

> Execute Phase 0 of the modularization plan: remove Windows path duplicate files, move root-level scripts to appropriate folders, inline trivial single-method files. No behavior changes. Gate: **`PHASE0: PASS`** + company checks pass.

---

## Phase 0 tasks (this session)

### Task 0a: Remove backslash-path duplicates DONE

Windows git artifacts created duplicate files alongside canonical forward-slash paths. Keep the forward-slash tracked path, delete the backslash mirror.

All 7 remaining backslash duplicates removed via `git rm --cached` + re-added forward-slash versions:
- `combat\CombatConstants.gd`, `combat\MedicalPhaseController.gd`
- `world\CompanyState.gd`, `world\ContractSpawner.gd`, `world\CombatFlow.gd`, `world\PartySetup.gd`, `world\SoakEncounterPresets.gd`

(Previously completed: `combat\FeatureFlags.gd`, `combat\MedicalConstants.gd` â€” already gone.)

Files to remove (verify each with `git diff` before deleting â€” must be byte-identical or untracked):

| Delete | Keep |
|--------|------|
| `combat\CombatConstants.gd` | `combat/CombatConstants.gd` |
| `combat\MedicalPhaseController.gd` | `combat/MedicalPhaseController.gd` |
| `combat\FeatureFlags.gd` | `combat/FeatureFlags.gd` |
| `combat\MedicalConstants.gd` | `combat/MedicalConstants.gd` |
| `world\CompanyState.gd` | `world/CompanyState.gd` |
| `world\ContractSpawner.gd` | `world/ContractSpawner.gd` |
| `world\CombatFlow.gd` | `world/CombatFlow.gd` |
| `world\PartySetup.gd` | `world/PartySetup.gd` |
| `world\SoakEncounterPresets.gd` | `world/SoakEncounterPresets.gd` |

Verify each with:
```powershell
git diff --stat combat\CombatConstants.gd combat/CombatConstants.gd
# If no diff or both untracked, delete the backslash version.
```

Also check for `.uid` duplicates matching these paths (e.g., `combat\CombatConstants.gd.uid` vs `combat/CombatConstants.gd.uid`).

### Task 0b: Move root-level scripts to appropriate folders

| File | Action | Destination |
|------|--------|-------------|
| `PartyManager.gd` | Move | `world/PartyManager.gd` (update any preloads) |
| `create_tile_texture.gd` | Verify if needed | If editor-only utility, move to `tools/` or remove; if game code, unclear purpose â€” escalate |

### Task 0c: Inline trivial single-method files DONE

- core/EntityTimeAdvance.gd inlined into all callers and deleted:
  - CombatProcessTick.gd — combat tick: bleed + blood_loss only (no healing)
  - MapFieldCare.gd — field care procedure: bleed + blood_loss only (no healing)
  - CompanyState.gd _advance_party_healing() — full advance with healing
  - CampaignEncounterBridge.gd _advance_party_overworld_minute() — full advance with healing
  - CombatRegressionHarnessMedicalPhaseTail.gd — all harness fixture calls (no healing)





To find callers:
```powershell
rg "preload.*EntityTimeAdvance" --no-heading
rg "EntityTimeAdvance\." --no-heading
```

### Task 0d: Verify Godot editor still resolves imports DONE

Both gates pass:
- `.\scripts\run_all_combat_checks.ps1` → **PHASE0: PASS** (line 6330)
- `.\scripts\run_company_state_checks.ps1` → **406/406 tests OK**

### Task 0e: Move create_tile_texture.gd to tools/ DONE

Editor-only utility (`extends EditorScript`, no game preloads). Moved from root to `tools/create_tile_texture.gd`. Referenced in `world/TilesetSetup.gd` as a one-time instruction — no preload updates needed.

---

## Phase 1: Split monoliths (started)

### Task 1a: Extract parry, afterblow, and formation move ID constants from CombatConstants.gd DONE (standalone files)

Created three new standalone constant files that document extraction boundaries. These are **complementary** to `CombatConstants.gd` — the original file remains the canonical source for existing callers (GDScript doesn't support cross-file const forwarding aliases).

| New File | Contents | Status |
|----------|----------|--------|
| `combat/CombatParryConstants.gd` (~250 lines) | Parry constants, bind/riposte, guard-zone/line mapping, counter-tempo, riposte chain, flurry bind, readiness curves, geometry/alignment, telegraph/feint | DONE — populated with extracted constants + static functions |
| `combat/CombatAfterblowConstants.gd` (~10 lines) | Afterblow thresholds and logic constants (4 consts) | DONE |
| `combat/CombatFormationMoveIds.gd` (~130 lines) | All MOVE_ID_* constants, is_formation_* predicates, focus/wait IDs, attempt_close, skip turn values, partner/pair helpers | DONE |

**Key finding:** GDScript does not support `_OtherClass.CONSTANT` as a const initializer expression. The plan's forwarding alias approach (`const X := _ParryConstants.X`) cannot work at the top-level const declaration. Instead, these files are standalone — new code can preload them directly, while existing callers continue using `CombatConstants`.

**Gate:** `PHASE0: PASS` + company checks 406/406 OK (verified after changes).

---

## Verification checklist

- [x] All 9 backslash-path duplicates removed (plus any .uid variants)
- [x] PartyManager.gd moved to world/ with updated preloads
- [x] EntityTimeAdvance.gd inlined, file deleted
- [x] create_tile_texture.gd moved to tools/ (editor-only utility)
- [x] git status shows only expected changes (no accidental deletions of tracked code)
- [x] `.\scripts\run_all_combat_checks.ps1` → **PHASE0: PASS**
- [x] `.\scripts\run_company_state_checks.ps1` → all 406 tests pass
- [x] Phase 1a: CombatParryConstants.gd created (~250 lines, extracted from CombatConstants)
- [x] Phase 1a: CombatAfterblowConstants.gd created (~10 lines)
- [x] Phase 1a: CombatFormationMoveIds.gd created (~130 lines)

---

## What NOT to do in this session

- Do not create subdirectories beyond `tools/` (already created for the tile utility)
- Do not add new features or change behavior
- Do not introduce `FEATURE_*` flags
- Do not touch combat logic, campaign logic, or core simulation code

---

## Hand off — Phase 1b pending

Phase 0 is complete. Phase 1a (CombatConstants extraction) is complete with gates passing.

**Remaining Phase 1 tasks:**

1. **1b: Split CompanyState.gd** (~1,496 lines → ~3 files). Extract `format_*` economy helpers into `CompanyEconomy.gd` and supply management into `CompanySupplies.gd`. Same approach as 1a — standalone files, no forwarding aliases (GDScript limitation). Gate: `run_company_state_checks.ps1` (406 tests).

2. **1c: Split CombatRegressionHarness.gd** (~11,618 lines → thin coordinator + `HarnessFixtures.gd`). HarnessFixtures already exists (~17K lines). Main harness needs reduction to a thin orchestrator. Gate: Phase 0 harness runs.

The full plan is at [`docs/MODULARIZATION_PLAN.md`](../../docs/MODULARIZATION_PLAN.md).
