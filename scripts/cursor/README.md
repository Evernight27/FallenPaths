# Cursor agent prompts (copy-paste)

**Post–Camp-5 default:** **Combat** chat first → optional **Playtest** or **Campaign** second chat.

Copy an **`agent_*.md`** file **or** a section below (Hygiene · Audit · Medical · Expand reopen) into a **new Cursor chat**.

**Layout (4 files):** `README.md` · `agent_combat.md` (incl. [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug)) · `agent_playtest.md` · `agent_campaign.md`.

**Shipped Expand rows:** [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md) · [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md).

---

<a id="parallel-medical-quality-bundle"></a>

## Medical quality bundle

| Chat | Copy from | Stream |
|:----:|-----------|--------|
| 1 | [§ Hygiene](#hygiene-cleanup) below | Dup files · ignore rules |
| 2 | [§ Audit](#audit-dedup) below | Phase 0 · dedup grep |
| 3 | [§ Medical physics](#medical-physics) below | Bleed · triage · treatment |
| 4 | [`agent_combat.md`](agent_combat.md) or [`agent_playtest.md`](agent_playtest.md) | Combat or F5 traces |

**Order:** Hygiene → Audit → Medical Physics → optional Combat/Playtest. One agent on `BleedingConstants.gd` / `EntityMedical.gd` at a time.

---

<a id="hygiene-cleanup"></a>

## Hygiene (copy-paste this chat)

Stream: **Hygiene**. Repo cleanup — remove unnecessary files, fix `.gitignore`, resolve Windows path duplicates. **No gameplay logic changes** unless a duplicate file is the only copy of real code (escalate to Combat).

**Gate before done:** after deletions, run or hand off:
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`**. Docs-only pass: confirm `git status` has no accidental deletions.

**Own:** `.gitignore`, `.cursorignore`, untracked duplicates, editor artifacts.

**Do not touch:** `combat/*`, `world/*`, `core/*` production `.gd` (except proven byte-identical dupes after diff). **Do not** commit `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, or `.godot/` cache.

| Priority | Task | How |
|:--------:|------|-----|
| 1 | **Windows path duplicates** | `combat/Foo.gd` (M) + `combat\Foo.gd` (??) — keep tracked path, remove mirror |
| 2 | **Godot / IDE artifacts** | `.godot/`, `.import/`, `*.tmp` in `.gitignore`; delete untracked `.godot` |
| 3 | **Playtest artifacts** | Confirm `.f5_soak_in.txt`, `.phase0_*`, `.d001_*` gitignored |
| 4 | **Cursor rules dupes** | One `.cursor/rules/fallen-paths.mdc` |
| 5 | **VS Code dupes** | Single `.vscode/settings.json` / `tasks.json` |
| 6 | **Stale script inventory** | `scripts/README.md` rows match on-disk `scripts/*` (removed: `run_d001_presets*`, `_print_phase0_status.ps1`, `validate_res_paths.py`) |
| 7 | **res:// path audit** | `python3 scripts/check_doc_links.py --res-paths-only` (included in Phase 0 via `check_doc_links.ps1`) |
| 8 | **Prompt/doc dedup** | One copy-paste home: `scripts/cursor/README.md` + `agent_*.md`; link stubs in `AGENTS.md` / `PLANNING.md` / `EXPANSION_PLAN.md` / `CURSOR.md` |
| 9 | **Track untracked scripts** | Legitimate `?? scripts/*` (F5 helpers, `cursor/`) → `git add`, not delete |

**Safety:** never `git clean -fd` repo-wide · list every deletion · if two copies differ, stop and report to Audit.

**Success:** no spurious `?? combat\*.gd` mirrors · artifacts gitignored · Phase 0 PASS (or hand off to Audit).

---

<a id="audit-dedup"></a>

## Audit (copy-paste this chat)

Stream: **Audit**. Find errors, duplication, anti-patterns — fix **clear bugs only**; report structural duplication for Combat/Medical agents.

**Gate before done:**
```powershell
.\scripts\run_all_combat_checks.ps1
.\scripts\run_company_state_checks.ps1
```
Targets: **`PHASE0: PASS`** + **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`** (or **`FP_HARNESS_OK: CompanyStateChecks (406 tests)`**).

**Own:** grep audits, harness failures, calibration audit, minimal fixes (typos, dead imports).

**Do not touch:** `.f5_soak_in.txt` · bleed retune · pick pipeline refactor · new `FEATURE_*`.

**Read first:** [`AGENTS.md`](../../AGENTS.md) anti-patterns · [`docs/LIVE_PATHS.md#harness-prefixes`](../../docs/LIVE_PATHS.md#harness-prefixes) · [`docs/PLANNING.md#file-ownership`](../../docs/PLANNING.md#file-ownership).

| Priority | Audit | Commands |
|:--------:|-------|----------|
| 1 | Phase 0 / harness | `.\scripts\run_all_combat_checks.ps1` |
| 2 | Calibration | `-HarnessMode calibration` |
| 3 | Medical duplication | grep `entity_has_untreated_wounds`, raw `pack_wound` / `MOVE_ID_*` |
| 4 | Combatant access | grep `manager._get_by_id` → use `CombatantEntityAccess` |
| 5 | Bridge duplication | grep local `_tile_coords`, duplicate wound helpers |
| 6 | Debug leakage | grep `print("[Combat]"` outside `CombatDebug` |
| 7 | WF conflation | grep `get_stance_modifier` at new call sites |
| 8 | Doc / res:// gate | `python3 scripts/check_doc_links.py` (doc links + tombstones + `res://` paths) |
| 9 | Medical harness | `-HarnessMode medical` |

**Report format:** `FINDING` / `SITES` / `CANONICAL` / `FIX` (fixed | defer).

**Success:** gate green · duplication report delivered · ≤1 logical fix unless trivial typos.

---

<a id="medical-physics"></a>

## Medical physics (copy-paste this chat)

Stream: **Combat · Medical Physics**. Medically sound hemorrhage, triage, treatment, pain/shock sim grounded in research anchors. **No organ surgery / cardiac chains** (Exp-5 wontfix).

**Gate before done:**
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`**. Fast iterate: `-HarnessMode medical` · `-HarnessMode calibration`.

**Own:** `core/EntityMedical.gd`, `EntityWounds.gd`, `EntityHealing.gd`, `EntityDamage.gd`, `BleedingConstants.gd`, `CombatResearchAnchors.gd`, `combat/MedicalPhaseController.gd`, `CombatMedicalCoordination.gd`, `CombatMedicalActionListing.gd`, `MedicalActionStarter.gd`, `MedicalWindUpHandler.gd`, `CombatRegressionHarnessMedicalPhaseTail.gd`, `CombatCalibrationAudit.gd`, `ui/BattleUIUpdater.gd` (medical busy gauge only).

**Read-only unless bridge row:** `world/MapFieldCare.gd` (field-care constants must match combat — coordinate Campaign if API changes).

**Do not touch:** `MentalStackDecider` layer order · formation / WF / IV · `world/CompanyState` economy · new `FEATURE_*`.

**Read first:** [`LIVE_PATHS#bleeding-physics`](../../docs/LIVE_PATHS.md#bleeding-physics) · [`LIVE_PATHS#tier-6--medical--flee`](../../docs/LIVE_PATHS.md#tier-6--medical--flee) · `AGENTS.md` medical APIs.

**Tuning order** (constants): `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold — then calibration harness + PR citation.

| Priority | Work | Harness |
|:--------:|------|---------|
| 1 | Failing medical/calibration row | `MedicalPhaseTail` · `CombatCalibrationAudit` |
| 2 | TTD / triage parity | `_run_medical_phase_full_blood_loss_rate` |
| 3 | Clotting / hemostasis | pressure vs definitive bandage |
| 4 | Pain-shock coupling | `_run_ambient_pain_shock_*` |
| 5 | Treatment overlap | `_run_medical_coordination_*` |
| 6 | Pack / channel depth | `_run_iii5_packing_channel_success_depth` |
| 7 | Field care ↔ combat parity | `MapFieldCare` + `EntityMedical` constants |
| 8 | Medical phase UI | `_run_medical_phase_gauge_*` |
| 9 | Blunt KE rank-order | harness before production mult change |

**Do not:** bypass `CombatMedicalCoordination.medical_action_allowed` · duplicate untreated-wound checks · import `CompanyState` in `combat/*`.

**PR prefix:** `combat:` or `medical:` · cite research anchor when changing a constant.

---

<a id="parallel-expansion-bundle"></a>

## Expansion parallel bundle

Combat-side Expand registry **complete (2026-06-08)**.

| Chat | File | Stream | Overlap |
|:----:|------|--------|---------|
| 1 | [`agent_combat.md`](agent_combat.md) | Combat · Exp-0.1 · [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug) | — |
| 2 | [`agent_playtest.md`](agent_playtest.md) | Playtest · Exp-0.2 · F5 | **Only** chat on `.f5_soak_in.txt` |
| 3 | [`agent_campaign.md`](agent_campaign.md) | Campaign · Exp-3 ☑ | `world/*` only |

**Also in this file:** [Hygiene](#hygiene-cleanup) · [Audit](#audit-dedup) · [Medical physics](#medical-physics) · [Expand reopen](#expand-reopen) · [Merge discipline](#merge-discipline)

---

<a id="expand-reopen"></a>

## Expand (§9c reopen only)

Stream: **Expand**. One row from [`SHIP_PLAN#combat-expand-registry`](../../docs/SHIP_PLAN.md#combat-expand-registry) · one **`FEATURE_*`** per PR + harness · gate **`PHASE0: PASS`**. Detail: [`PLANNING#stream-expand`](../../docs/PLANNING.md#stream-expand) · rows: [`EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md).

**Do not touch:** `world/*`, `main.gd`, economy UI, `BleedingConstants.gd`, bleed retune. PR prefix: `combat:` or `expand:`.

---

<a id="merge-discipline"></a>

## Merge discipline

Full rules: [`PLANNING#parallel-agents`](../../docs/PLANNING.md#parallel-agents) (rebase · Phase 0 · hotspots · artifacts).

**Medical / hygiene bundle only:** bleed edits in [Medical physics](#medical-physics) chat · `-HarnessMode calibration` · never parallel: two deleters · two on `.f5_soak_in.txt` · Hygiene + Medical Physics on same `core/*.gd` · **only Playtest** touches `.f5_soak_in.txt` · **one Expand chat** at a time.

Rules: [`docs/CURSOR.md`](../../docs/CURSOR.md)
