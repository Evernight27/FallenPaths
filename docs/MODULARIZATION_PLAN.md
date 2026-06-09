# Modularization Plan

**Goal:** Improve codebase maintainability by reducing file sizes, breaking circular dependencies, eliminating duplicates, and clarifying module boundaries — without changing runtime behavior.

**Principle:** No new subdirectories until the team agrees on grouping conventions. All changes are refactors within existing folders. Gate: `PHASE0: PASS` before shipping any modularization PR.

---

## Phase 0: Hygiene (zero-risk, no production code changes)

### 0a. Remove duplicate backslash-path files

Windows git artifacts created duplicate files alongside canonical forward-slash paths. These are not tracked in `.gitignore` but exist as untracked duplicates:

| Duplicate | Canonical |
|-----------|-----------|
| `combat\CombatConstants.gd` | `combat/CombatConstants.gd` |
| `combat\MedicalPhaseController.gd` | `combat/MedicalPhaseController.gd` |
| `combat\FeatureFlags.gd` | `combat/FeatureFlags.gd` |
| `combat\MedicalConstants.gd` | `combat/MedicalConstants.gd` |
| `world\CompanyState.gd` | `world/CompanyState.gd` |
| `world\ContractSpawner.gd` | `world/ContractSpawner.gd` |
| `world\CombatFlow.gd` | `world/CombatFlow.gd` |
| `world\PartySetup.gd` | `world/PartySetup.gd` |
| `world\SoakEncounterPresets.gd` | `world/SoakEncounterPresets.gd` |

**Action:** Delete all backslash-path duplicates. Verify Godot editor still resolves imports correctly after removal. This is a one-time cleanup — no functional changes.

### 0b. Move root-level scripts to appropriate folders

| File | Destination | Reason |
|------|-------------|--------|
| `PartyManager.gd` (34 lines) | `world/PartyManager.gd` | Party management belongs with campaign world logic |
| `create_tile_texture.gd` (22 lines) | `tools/create_tile_texture.gd` or remove if editor-only | Utility script, not game code |

### 0c. Inline trivial single-method files

| File | Lines | Action |
|------|-------|--------|
| `core/EntityTimeAdvance.gd` | 26 | Inline `advance()` into callers (`CombatProcessTick`, `MapFieldCare`) — it's a one-method wrapper around `Time.get_ticks_msec()` |

---

## Phase 1: Split monoliths (highest impact)

### 1a. Split `combat/CombatConstants.gd` (2,641 lines → ~5 files)

The file header already declares this intent but the work is incomplete. The current file mixes 7+ unrelated constant groups into one preload that 50+ files depend on.

**Proposed split:**

| New File | Contents | Line estimate |
|----------|----------|---------------|
| `combat/CombatConstants.gd` (keep, reduced) | Attack state machine IDs, damage types, power/follow_through ranges, miss/glancing/chance constants, core tuning | ~600 lines |
| `combat/CombatTiming.gd` (extract from existing CombatTiming.gd + CombatConstants) | All wind-up/recovery timing constants, duration multipliers | ~200 lines |
| `combat/CombatParryConstants.gd` (new) | Parry tables, strong/weak exposure, contact bonuses, passive parry context thresholds | ~300 lines |
| `combat/CombatAfterblowConstants.gd` (new) | Afterblow thresholds and logic constants | ~100 lines |
| `combat/CombatFormationMoveIds.gd` (existing CombatFormationMoveDuration.gd + MOVE_ID_* from CombatConstants) | All `MOVE_ID_*` constants, `is_formation_*()` predicates, formation move kind constants | ~250 lines |

**Migration path:**
1. Create new file(s) with extracted const groups
2. Add forwarding `const` aliases in `CombatConstants.gd` that preload from new files (zero-breaking)
3. Update direct preloads in callers to use new files
4. Remove forwarding aliases after one PR cycle

**Risk:** Low — all changes are constant groupings, no behavior change. Gate: `PHASE0: PASS`.

### 1b. Split `world/CompanyState.gd` (1,840 lines → ~3 files)

CompanyState owns economy formatting (~50 `format_*` functions), gate constants, supply management, camp healing logic, and state machine/persistence — all in one file.

**Proposed split:**

| New File | Contents | Line estimate |
|----------|----------|---------------|
| `world/CompanyState.gd` (keep, reduced) | State machine, persistence, gates, core company data | ~800 lines |
| `world/CompanyEconomy.gd` (new) | All `format_*` functions for economy, wages, provisions, burial costs, HUD copy (~50 helpers) | ~600 lines |
| `world/CompanySupplies.gd` (new) | Medical supplies, food rations, tool management, resupply logic | ~300 lines |

**Migration path:**
1. Create `CompanyEconomy.gd` and `CompanySupplies.gd` with extracted methods
2. Keep forwarding methods in `CompanyState` that delegate to new files
3. Update callers that directly reference internal helpers
4. Remove forwarding wrappers after one PR cycle

**Risk:** Low — pure extraction, no behavior change. Gate: `run_company_state_checks.ps1` (406 tests) must pass.

### 1c. Split `combat/CombatRegressionHarness.gd` (11,989 lines → ~3 files)

The harness is already partially split with tail delegation, but the main harness file itself is enormous and preloads 50+ modules.

**Proposed split:**

| New File | Contents |
|----------|----------|
| `combat/HarnessFixtures.gd` (new) | Shared combat setup fixtures, common initialization patterns, helper methods used by multiple tails |
| `combat/CombatRegressionHarness.gd` (keep, reduced) | Harness orchestration, test runner logic, tail dispatch — thin coordinator |

**Risk:** Low — test harness code only. Gate: Phase 0 harness runs must still pass.

---

## Phase 2: Break circular dependencies (architectural improvement)

### 2a. Resolve combat ↔ core circular preloads

**Current cycle:** `core/EntityMedical` → `combat/CombatConstants`, `combat/CombatantEntityAccess`, `combat/CombatDebug` ← `core/OperationalLog` → `combat/CombatConstants`, `core/EntityPainConsciousness` → `combat/CombatTiming`, `combat/CombatConstants`, `combat/CombatDebug`

**Proposed solution:** Create a thin cross-domain API layer.

| New File | Contents |
|----------|----------|
| `core/EntityAPI.gd` (new) | Clean public interface for combat code to query entity state: health, wounds, bleeding, medical status. Combat code calls this instead of preloading individual core modules. |

**Effect:** `core/` modules no longer need to preload `combat/CombatDebug`. Instead, `CombatDebug` implements the logging interface, and `EntityAPI` accepts a callback or uses a weak reference pattern. This breaks the circular dependency while preserving all functionality.

**Risk:** Medium — requires careful API design. Gate: Phase 0 + company checks.

### 2b. Clarify entity system boundaries (documentation-only)

Create a clear boundary doc (inline comments in `CoreEntity.gd` header + `character.gd` header) describing:

| Component | Role | Lives in |
|-----------|------|----------|
| `CharacterBody2D` (`character.gd`) | Overworld movement, scene root, delegates to CoreEntity | Root |
| `CoreEntity` (Node2D child) | Body part state, wounds, armor, combat stats | Inside character node |
| `CombatantEntityAccess` (static class) | Reads combatant dictionaries in combat sim | `combat/` |
| `PartyMemberSnapshot` (world) | Captures entity state for campaign persistence | `world/` |

**Risk:** Zero — documentation only.

---

## Phase 3: Consolidate scattered concerns

### 3a. Merge physics subsystem files

| Current Files | Lines | Proposal |
|---------------|-------|----------|
| `combat/StrikePhysics.gd` | 54 | Move to `weapon/` or merge into `WeaponSwingPhysics.gd` |
| `weapon/WeaponSwingPhysics.gd` | 128 | Consolidated swing physics |
| `weapon/ImpactVelocityModel.gd` | 152 | Merge with above → `weapon/StrikeKinematics.gd` (~300 lines) |

**Risk:** Low — all in weapon folder, same concern. Gate: Phase 0 (attack resolver uses these).

### 3b. Consolidate wind-up systems

| Current Files | Lines | Proposal |
|---------------|-------|----------|
| `combat/AttackWindUpStarter.gd` | ~150 | Merge into unified `combat/WindUpHandler.gd` with sub-modes for strike vs medical, OR at minimum establish consistent naming (both follow `*WindUpHandler` pattern) |
| `combat/MedicalWindUpHandler.gd` | ~100 | See above |

**Risk:** Low-Medium — affects resolve pipeline. Gate: Phase 0 + F5 soak.

### 3c. Consolidate resolution pipeline files

Three resolver/handler pairs handle different combat resolution phases:

| File | Lines | Phase |
|------|-------|-------|
| `combat/CombatEngagementResolver.gd` | 749 | Engagement setup |
| `combat/DefenseChoiceResolver.gd` | 402 | Strike-time defense pick |
| `combat/DefenseResolutionHandler.gd` | 147 | Defense outcome resolution |

**Recommendation:** Keep as-is for now. The naming is internally consistent and the responsibilities are genuinely distinct phases. Only consolidate if a future refactor makes it natural.

---

## Phase 4: Address god classes

### 4a. Reduce `combat/CombatantEntityAccess.gd` (1,161 lines)

This is the star topology hub — preloaded by 30+ files. It owns combatant dict lookups, health access, identity checks, wounds, weapon info, side detection, vitals, and manager hooks.

**Proposed split:**

| New File | Contents |
|----------|----------|
| `combat/CombatantEntityAccess.gd` (keep) | Core lookup: `manager_get_combatant`, health entity access, identity checks, wound state |
| `combat/CombatantVitals.gd` (new) | Vital calculations: body health ratio, functionality, bleeding status, pain/consciousness |
| `combat/CombatantEquipment.gd` (new) | Weapon/form info, armor slot queries, equipment-derived stats |

**Migration path:** Same as Phase 1 — forwarding methods first, then direct preloads.

**Risk:** Medium — every preload of CombatantEntityAccess needs review. Gate: Phase 0 mandatory.

### 4b. Reduce `ui/BattleScene.gd` (708 lines)

BattleScene directly manages UI controls, combat state, and medical phase logic in one Node.

**Proposed split:**

| Action | Target |
|--------|--------|
| Move gauge/row update delegation | `ui/BattleUIUpdater.gd` (already partially done) |
| Extract medical phase orchestration | Keep in BattleScene but delegate to `MedicalPhaseController` (already the case — verify completeness) |

**Risk:** Low — UI wiring changes only. Gate: Headless + visual smoke test.

---

## Phase 5: Long-term considerations (defer, not actionable now)

### 5a. Subdirectory structure for combat/

With 186 files in a flat folder, subdirectories could improve navigability:

```
combat/
  constants/     (CombatConstants, MedicalConstants, FeatureFlags)
  resolve/       (AttackResolver, AttackResultApplier, DefenseChoiceResolver, DefenseResolutionHandler)
  formation/     (FormationSetup, FormationFlow, FormationSlots, etc.)
  medical/       (MedicalPhaseController, MedicalActionStarter, MedicalCoordination, MedicalListing)
  ai/            (MentalStackDecider, AIActionPicker, CombatAttention)
  doctrine/      (CombatDoctrine, EngagementMode, MoraleCohesion)
  harness/       (CombatRegressionHarness*, CombatD001*, CombatF5Soak*)
```

**Status:** Deferred. Requires team agreement on grouping conventions and a coordinated file move across all preloads. Not worth the PR churn until the monolith splits reduce file count first.

### 5b. Godot autoload adoption

The project uses `class_name` static classes exclusively (zero Godot autoloads). Some candidates for autoload:
- `OperationalLog` — centralized logging singleton pattern
- `CompanyState` — persistent company data accessed from many places

**Status:** Deferred. No behavior change benefit; only reduces preload boilerplate.

---

## Execution order and PR strategy

| Order | Phase | Effort | Risk | Gate |
|-------|-------|--------|------|------|
| 1 | 0a (duplicate removal) | 30 min | Zero | None |
| 2 | 0b-0c (move root scripts, inline EntityTimeAdvance) | 30 min | Zero | Phase 0 |
| 3 | 1a (split CombatConstants) | 2 hours | Low | Phase 0 |
| 4 | 1b (split CompanyState) | 3 hours | Low | Company checks + Phase 0 |
| 5 | 1c (split Harness) | 1 hour | Zero | Phase 0 harness runs |
| 6 | 2a (break circular deps) | 4 hours | Medium | Phase 0 + company checks |
| 7 | 3a (physics consolidation) | 1 hour | Low | Phase 0 |
| 8 | 3b (wind-up consolidation) | 2 hours | Medium | Phase 0 + F5 soak |
| 9 | 4a (split CombatantEntityAccess) | 3 hours | Medium | Phase 0 |
| 10 | 4b (BattleScene cleanup) | 1 hour | Low | Headless smoke test |

**Total estimated effort:** ~18 hours of focused refactoring work, spread across ~9 PRs.

**Parallelism:** Phases 0a-0c can be done by any agent. Phase 1a and 1b are independent and could be done in parallel by different agents (combat vs campaign stream). All later phases must be sequential due to shared file dependencies.

---

## What NOT to touch

Per `.cursor/rules/fallen-paths.mdc`:
- **No new subdirectories** until team agrees on conventions
- **No new `FEATURE_*` flags** — this is a refactoring effort, not feature work
- **No behavioral changes** — every PR must be a zero-diff refactor (same output, same test results)
- **No combat logic changes** disguised as modularization — keep the focus on structure
