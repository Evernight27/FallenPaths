Stream: **Medical Physics**. Medically sound hemorrhage, triage, treatment, pain/shock sim grounded in research anchors. Organ surgery / cardiac chains are post-EA scope.

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
```

Target: **`PHASE0: PASS`**. Fast iterate: `-HarnessMode medical` · `-HarnessMode calibration`.

**Own:** `core/EntityMedical.gd`, `EntityWounds.gd`, `EntityHealing.gd`, `EntityDamage.gd`, `EntityTimeAdvance.gd`, `BleedingConstants.gd`, `CombatResearchAnchors.gd`, `combat/MedicalPhaseController.gd`, `CombatMedicalCoordination.gd`, `CombatMedicalActionListing.gd`, `MedicalActionStarter.gd`, `MedicalWindUpHandler.gd`, `CombatRegressionHarnessMedicalPhaseTail.gd`, `CombatRegressionHarnessMedicalMobilityTail.gd`, `CombatCalibrationAudit.gd`, `ui/BattleUIUpdater.gd` (medical busy gauge only).

**Read-only unless bridge row:** `world/MapFieldCare.gd` (field-care constants must match combat — coordinate Campaign if API changes).

**Do not touch:** `MentalStackDecider` layer order · formation / WF / IV · `world/CompanyState` economy · new `FEATURE_*` · closed-gate constants (bleed/BMI) unless I explicitly ask. Parallel: one agent on `core/EntityMedical.gd` / `EntityWounds.gd` at a time. Not parallel with Hygiene on same `core/*.gd`.

**Read first:** [`LIVE_PATHS#bleeding-physics`](../../docs/LIVE_PATHS.md#bleeding-physics) · [`LIVE_PATHS#tier-6--medical--flee`](../../docs/LIVE_PATHS.md#tier-6--medical--flee) · medical APIs: [`docs/AGENTS_API.md#canonical-apis`](../../docs/AGENTS_API.md#canonical-apis).

---

## Session start (copy-paste task line)

> Run `-HarnessMode medical` then full Phase 0. Pick **one** medical row from the table below (or I will name it). Smallest diff in the owning module. Re-run gate before done. Do not bypass `CombatMedicalCoordination.medical_action_allowed`.

---

## Priority table (2026-06-08+)

| P | Work | Harness / gate |
|:-:|------|----------------|
| 1 | Failing medical/calibration row | `MedicalPhaseTail` · `CombatCalibrationAudit` |
| 2 | TTD / triage parity | `_run_medical_phase_full_blood_loss_rate` |
| 3 | Clotting / hemostasis | pressure vs definitive bandage |
| 4 | Pain-shock coupling | `_run_ambient_pain_shock_*` |
| 5 | Treatment overlap / coordination | `_run_medical_coordination_*` |
| 6 | Pack / channel depth | `_run_iii5_packing_channel_success_depth` |
| 7 | Field care ↔ combat parity | `MapFieldCare` + `EntityMedical` constants |
| 8 | Medical phase UI gauge | `_run_medical_phase_gauge_*` |
| 9 | Blunt KE rank-order | harness before production mult change |

**Tuning order** (constants only when asked): `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold — then calibration harness + PR citation.

**Do not:** bypass `CombatMedicalCoordination.medical_action_allowed` · duplicate untreated-wound checks · import `CompanyState` in `combat/*`.

---

## Done checklist

- [ ] Phase 0 PASS at start and end
- [ ] One logical fix (or explicit "gate-only" session)
- [ ] No edits outside stream ownership without handoff

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Escalation:** if you find an issue in files outside your owning module (especially `combat/` non-medical, `world/*`), report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. Hand off to the appropriate stream owner.

**Success:** gate green · smallest diff in owning module · research anchor cited for constant changes.

PR prefix: `combat:` or `medical:` · cite research anchor when changing a constant.
