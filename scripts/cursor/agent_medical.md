Stream: **Medical Physics**. Medically sound hemorrhage, triage, treatment, pain/shock sim grounded in research anchors. **No organ surgery / cardiac chains** (Exp-5 wontfix).

**Gate before done:**
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`**. Fast iterate: `-HarnessMode medical` · `-HarnessMode calibration`.

**Own:** `core/EntityMedical.gd`, `EntityWounds.gd`, `EntityHealing.gd`, `EntityDamage.gd`, `EntityTimeAdvance.gd`, `BleedingConstants.gd`, `CombatResearchAnchors.gd`, `combat/MedicalPhaseController.gd`, `CombatMedicalCoordination.gd`, `CombatMedicalActionListing.gd`, `MedicalActionStarter.gd`, `MedicalWindUpHandler.gd`, `CombatRegressionHarnessMedicalPhaseTail.gd`, `CombatRegressionHarnessMedicalMobilityTail.gd`, `CombatCalibrationAudit.gd`, `ui/BattleUIUpdater.gd` (medical busy gauge only).

**Read-only unless bridge row:** `world/MapFieldCare.gd` (field-care constants must match combat — coordinate Campaign if API changes).

**Do not touch:** `MentalStackDecider` layer order · formation / WF / IV · `world/CompanyState` economy · new `FEATURE_*` · bleed retune unless I explicitly ask.

**Read first:** [`LIVE_PATHS#bleeding-physics`](../../docs/LIVE_PATHS.md#bleeding-physics) · [`LIVE_PATHS#tier-6--medical--flee`](../../docs/LIVE_PATHS.md#tier-6--medical--flee) · `AGENTS.md` medical APIs.

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

**PR prefix:** `combat:` or `medical:` · cite research anchor when changing a constant.

**Parallel:** one agent on `core/EntityMedical.gd` / `EntityWounds.gd` at a time. Not parallel with Hygiene on same `core/*.gd`.
