Stream: **Soak repair** (one-shot). Pre-existing `.f5_soak_in.txt` staleness gate. **Only agent on `.f5_soak_in.txt`** (playtest owns it otherwise).

**Gate:** `FP_SKIP_IMPORT_WARMUP=1 bash tools/ci/run_all_combat_checks.sh regression` → **`FP_HARNESS_OK: CombatRegressionHarness`**. Full: `./tools/ci/run_all_combat_checks.sh` → **`PHASE0: PASS`**.

**Read first:** [`tools/ci/README#combat-scripts`](../README.md) · [`LIVE_PATHS#f5-combat-diagnostic-tiers`](../../../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers) · `tools/ci/f5_soak_log_helpers.sh`.

**Do not touch:** production `combat/*` / `world/*` (report-only). Do NOT change `PARRY_BIND_CONTROL_THRESHOLD`, do NOT loosen the audit silently.

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## FINDING (pre-investigated)

- `CombatRegressionHarness` fails on the **soak log parry-ctrl audit**:
  `mat_production audit: soak_log: 1 parry ctrl lines disagree with bind threshold 0.48`
- Audit site: `harness/calibration/CalibrationImpactKeTests.gd:28-111` (`_append_soak_parry_section`), read inline by `SimulationMaterialTests._run_mat_production_calibration_anchors_locked` and cross-checked by `CombatCalibrationAudit.gd:37`. Rule: a row tagged `parry_deflect` must have `ctrl < PARRY_BIND_CONTROL_THRESHOLD + BIND_CTRL_AUDIT_EPS` (0.48 + 0.001).
- Offender: `.f5_soak_in.txt` **line 1096** — `FP_COMBAT: parry_deflect  vs Companion3 ctrl=0.508 reason=full parry (no follow-through)`.
- Root cause: `.f5_soak_in.txt` (human F5 paste) mtime **Aug 13 2026**. Commit `59183d1` (Sep 12, "fixed feint and parry angles") rewrote `parry_control_for_bind_deflect` and the deflect band (`combat/constants/CombatConstantsParry.gd` ~99 lines). Under current physics a full-stop deflect with `ctrl >= 0.481` is not produced (`parry_bind_control_reached` binds at 0.48); the paste is stale relative to current anchors.

## SITES

- `harness/calibration/CalibrationImpactKeTests.gd:28-111` — the audit + `_parse_ctrl`.
- `combat/constants/CombatConstantsParry.gd:143,454-455,529-589` — threshold (0.48) + `parry_control_for_bind_deflect` (current formula: alignment^1.2, margin band ≤2.0, bind_friction_mult, clamp [0,1]).
- `core/OperationalLog.gd:532-553` — `write_f5_soak_capture` (D001 writes headless capture into `.f5_soak_in.txt`).
- `tools/ci/f5_soak_log_helpers.sh:71-107` — `f5_backup_human_paste` / `f5_restore_human_paste` (backup is ALSO the stale Aug-13 paste).
- `tools/ci/run_all_combat_checks.gd:120-129` + `tools/ci/run_all_combat_checks.sh:86-93` — `all` mode runs D001 **before** regression specifically so a stale soak doesn't spuriously fail.

## CANONICAL

The audit requires the parsed soak to reflect **current** parry physics so the deflect/bind band check is meaningful. `.f5_soak_in.txt` is regenerated on every full Phase 0 run by `CombatD001SoakRunner` (via `write_f5_soak_capture`), then the human paste is restored — so regression-*only* mode validates against whatever paste is persisted. The persisted Aug-13 paste predates the parry formula and must be refreshed to current-physics data.

## FIX (verify before editing)

1. Reproduce: `FP_SKIP_IMPORT_WARMUP=1 bash tools/ci/run_all_combat_checks.sh regression` → confirm the failure. Confirm staleness: `ls -la .f5_soak_in.txt`, `git log --oneline -5 combat/constants/CombatConstantsParry.gd`, `git show 59183d1 -- combat/constants/CombatConstantsParry.gd`, and that `parry_control_for_bind_deflect` cannot emit ctrl≥0.481 for a deflect.
2. **Primary fix (no production code change):** refresh `.f5_soak_in.txt` from current physics and persist it:
   - `FP_HARNESS_MODE=d001 bash tools/ci/run_all_combat_checks.sh` regenerates the capture; or run full Phase 0 (`./tools/ci/run_all_combat_checks.sh`) and **keep the D001 capture** instead of restoring the stale paste.
   - Refresh the backup so future restores aren't stale: `cp .f5_soak_in.txt .f5_soak_in.f5_backup.txt` (matches `append_f5_soak_log.sh:42` behavior).
   - `bash tools/ci/validate_f5_soak_log.sh` → clean.
3. Re-gate: `FP_SKIP_IMPORT_WARMUP=1 bash tools/ci/run_all_combat_checks.sh regression` → **`FP_HARNESS_OK`**; full Phase 0 → **`PHASE0: PASS`**.
4. **Only-if branch:** if the fresh capture STILL contains a `parry_deflect` row with `ctrl >= 0.481`, that is a genuine formula/classification disagreement (not staleness). Then, with justification citing the formula inputs that produce it, adjust the audit's deflect-band expectation (`CalibrationImpactKeTests.BIND_CTRL_AUDIT_EPS` / band comment) — never the 0.48 threshold, and never report-only. Hand any production-parry suspicion to Combat as `FINDING`/`SITES`/`CANONICAL`/`FIX` instead of editing `combat/*`.
5. Do not spawn a parallel chat touching `.f5_soak_in.txt`.

**Grep:** `parry_deflect`, `parry_bind`, `ctrl=`, `PARRY_BIND_CONTROL_THRESHOLD`, `BIND_CTRL_AUDIT_EPS`, `FP_SESSION_BEGIN: headless d001 capture`.

PR prefix: `soak:`.