Stream: **Medical Physics**. Hemorrhage / triage / treatment / pain-shock grounded in research anchors.

**Gate:** `./scripts/run_all_combat_checks.sh` → **`PHASE0: PASS`**. Fast: `FP_HARNESS_MODE=medical|calibration`.

**Own:** `core/EntityMedical.gd`, `core/EntityWounds.gd`, `core/EntityHealing.gd`, `core/EntityDamage.gd`, `core/BleedingConstants.gd`, `core/CombatResearchAnchors.gd`, `combat/MedicalPhaseController.gd` (time-advance slices), `combat/CombatMedicalCoordination.gd`, `combat/CombatMedicalActionListing.gd`, `combat/MedicalActionStarter.gd`, `combat/MedicalWindUpHandler.gd`, `harness/CombatRegressionHarnessMedicalPhaseTail.gd`, `harness/CombatRegressionHarnessMedicalMobilityTail.gd`, `harness/CombatCalibrationAudit.gd`, `ui/BattleUIUpdater.gd` (medical busy gauge).

**Do not:** mental-stack order · formation/WF/IV · economy · new `FEATURE_*` · closed bleed/BMI without ask. One agent on `EntityMedical`/`EntityWounds` at a time.

**Read first:** [`LIVE_PATHS#bleeding-physics`](../../docs/LIVE_PATHS.md#bleeding-physics) · [`#tier-6--medical--flee`](../../docs/LIVE_PATHS.md#tier-6--medical--flee) · [`AGENTS_API`](../../docs/AGENTS_API.md#canonical-apis).

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> Medical harness then Phase 0. Pick **one** row. Never bypass `medical_action_allowed`.

| P | Work |
|:-:|------|
| 1 | Failing medical/calibration row |
| 2 | TTD / triage parity |
| 3 | Clotting / hemostasis |
| 4 | Pain-shock coupling |
| 5 | Treatment coordination |
| 6 | Pack / channel depth |
| 7 | Field care ↔ combat parity |
| 8 | Medical phase UI gauge |
| 9 | Blunt KE rank-order |

**Tune order (when asked):** `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold.

PR prefix: `combat:` or `medical:` · cite research anchor for constants.
