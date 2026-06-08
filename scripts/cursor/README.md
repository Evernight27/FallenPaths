# Cursor agent prompts (copy-paste)

**Post–Camp-5 default:** **Combat** chat first → optional **Playtest** or **Campaign** second chat.

Copy an **`agent_*.md`** file **or** a section below (Hygiene · Audit · Medical · Expand reopen) into a **new Cursor chat**.

**Layout:** `README.md` · **maintain** [`agent_maintain.md`](agent_maintain.md) · **enhance** [`agent_enhance.md`](agent_enhance.md) · **hygiene** [`agent_hygiene.md`](agent_hygiene.md) · **audit** [`agent_audit.md`](agent_audit.md) · `agent_combat.md` (incl. [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug)) · `agent_playtest.md` · `agent_campaign.md`.

**Quick pick:** maintain shipped behavior → [`agent_maintain.md`](agent_maintain.md) · delete cruft → [`agent_hygiene.md`](agent_hygiene.md) · grep/improve → [`agent_audit.md`](agent_audit.md) · new tier/feature → [`agent_enhance.md`](agent_enhance.md).

**Shipped Expand rows:** [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md) · [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md).

---

<a id="project-health-bundle"></a>

## Project health bundle

| Chat | Copy from | Stream |
|:----:|-----------|--------|
| 1 | [`agent_hygiene.md`](agent_hygiene.md) | Delete mirrors · `.gitignore` · artifacts |
| 2 | [`agent_audit.md`](agent_audit.md) | Anti-patterns · dedup report · trivial fixes |
| 3 | [`agent_maintain.md`](agent_maintain.md) | Gate + one shipped maintain row |
| 4 | [`agent_enhance.md`](agent_enhance.md) | Expand · medical depth · user-requested tier |

**Order:** Hygiene → Audit → Maintain (or Enhance if user named a row). **Not parallel:** two deleters · Hygiene + Enhance on same `core/*.gd`.

---

<a id="parallel-medical-quality-bundle"></a>

## Medical quality bundle

| Chat | Copy from | Stream |
|:----:|-----------|--------|
| 1 | [`agent_hygiene.md`](agent_hygiene.md) | Dup files · ignore rules |
| 2 | [`agent_audit.md`](agent_audit.md) | Phase 0 · dedup grep |
| 3 | [§ Medical physics](#medical-physics) below | Bleed · triage · treatment |
| 4 | [`agent_combat.md`](agent_combat.md) or [`agent_playtest.md`](agent_playtest.md) | Combat or F5 traces |

**Order:** Hygiene → Audit → Medical Physics → optional Combat/Playtest. One agent on `BleedingConstants.gd` / `EntityMedical.gd` at a time.

---

<a id="hygiene-cleanup"></a>

## Hygiene

Copy [`agent_hygiene.md`](agent_hygiene.md) into a new chat. Bundle: [project health](#project-health-bundle) chat 1.

---

<a id="audit-dedup"></a>

## Audit

Copy [`agent_audit.md`](agent_audit.md) into a new chat. Bundle: [project health](#project-health-bundle) chat 2.

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

**Also in this file:** [Project health](#project-health-bundle) · [`agent_maintain.md`](agent_maintain.md) · [`agent_enhance.md`](agent_enhance.md) · [Hygiene](#hygiene-cleanup) · [Audit](#audit-dedup) · [Medical physics](#medical-physics) · [Expand reopen](#expand-reopen) · [Merge discipline](#merge-discipline)

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
