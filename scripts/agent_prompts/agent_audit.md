Stream: **Audit**. Improve code health — find errors, duplication, anti-patterns. Fix **clear bugs only**; report structural duplication for Combat / Medical / Campaign agents.

Bundle: [project health `#project-health-bundle`](README.md#project-health-bundle) chat 2. Run **after** Hygiene when both are scheduled.

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
.\scripts\run_company_state_checks.ps1
```

Targets: **`PHASE0: PASS`** + **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`** (or **`FP_HARNESS_OK: CompanyStateChecks (406 tests)`**).

**Own:** grep audits, harness failures, calibration audit, minimal fixes (typos, dead imports, wrong API call sites).

**Do not touch:** `.f5_soak_in.txt` · closed-gate constants (bleed/BMI) · pick-pipeline refactor · new `FEATURE_*` · economy gate constants.

**Read first:** [`AGENTS.md`](../../AGENTS.md) anti-patterns · [`docs/LIVE_PATHS.md#harness-prefixes`](../../docs/LIVE_PATHS.md#harness-prefixes) · [`docs/PLANNING.md#file-ownership`](../../docs/PLANNING.md#file-ownership).

---

## Session start (copy-paste task line)

> Run Phase 0 and company checks. Grep for anti-patterns in `AGENTS.md`. Fix at most one trivial bug if found; otherwise deliver a duplication report (`FINDING` / `SITES` / `CANONICAL` / `FIX`). Gate green before done.

---

## Priority audits

| P | Audit | Commands / grep |
|:-:|-------|-----------------|
| 1 | Phase 0 / harness | `.\scripts\run_all_combat_checks.ps1` |
| 2 | Calibration | `.\scripts\run_all_combat_checks.ps1 -HarnessMode calibration` |
| 3 | Medical duplication | `rg entity_has_untreated_wounds` · raw `pack_wound` / `MOVE_ID_*` outside `CombatConstants` |
| 4 | Combatant access | `rg 'manager\._get_by_id'` → use `CombatantEntityAccess` |
| 5 | Bridge duplication | `rg '_tile_coords'` · duplicate wound helpers in `world/` |
| 6 | Debug leakage | `rg 'print\("\[Combat\]'` outside `CombatDebug` |
| 7 | WF conflation | `rg get_stance_modifier` at production call sites → `CombatWeaponForm.mod` |
| 8 | Doc / res:// gate | `python3 scripts/check_doc_links.py` (links + tombstones + `res://` paths) |
| 9 | Medical harness | `.\scripts\run_all_combat_checks.ps1 -HarnessMode medical` |
| 10 | Move ID literals | `rg '"swap_rank"|"rotate_file"|"pack_wound"'` in production `combat/*.gd` (not harness tails) |

---

## Report format (defer structural fixes)

```
FINDING: <one sentence>
SITES: <file:line list>
CANONICAL: <AGENTS.md API or owner module>
FIX: fixed | defer → <Combat|Medical|Campaign>
```
**Hand off defer rows** to the stream owner — do not refactor pick pipeline or bleed constants in Audit.

**Do not:** add new features · change closed-gate constants without user ask · refactor MentalStackDecider layer order · touch `.f5_soak_in.txt`.

**Escalation:** if you find an issue in files outside your owning module, report it (FINDING/SITES/CANONICAL/FIX format — see [`agent_audit.md`](#report-format) for template) and do not edit those files. Hand off to the appropriate stream owner.

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Success:** gate green · duplication report delivered · ≤1 logical fix unless trivial typos.

PR prefix: `audit:` or `chore:`.
