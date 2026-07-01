Stream: **Combat**. **Default post–Camp-5** — smallest `combat/*.gd` owner per [`docs/PLANNING.md#file-ownership`](../../docs/PLANNING.md#file-ownership). Copy into parallel bundle chat 1 ([`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle)).

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
```

Target: **`PHASE0: PASS`**.

**Own:** `combat/*`, harness tails (`CombatRegressionHarness*`, `CombatD001*`), `ui/BattleUIUpdater.gd`, `ui/FormationDiagramBuilder.gd`, `ui/TurnReadyHandler.gd`, `ui/CombatLogFormatter.gd`, `character.gd` (combat hooks only).

**Do not touch:** `world/*`, `main.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, new `FEATURE_*`, closed-gate constants (bleed/BMI), `CampaignEncounterBridge.gd`, `CombatFlow.gd` (coordinate with Campaign agent — one at a time). **Expand rows** → [`README.md#expand-reopen`](README.md#expand-reopen). See [`AGENTS.md`](../../AGENTS.md#harness-and-flags) for frozen items policy.

**Read first:** [`docs/LIVE_PATHS.md#combat-cognition-pipeline`](../../docs/LIVE_PATHS.md#combat-cognition-pipeline) · [`docs/SHIP_PLAN.md#combat-mental-stack-shipped`](../../docs/SHIP_PLAN.md#combat-mental-stack-shipped).

**Before pick / attention / defense:** pipeline: `AvailableActionsBuilder.build` → `MentalStackDecider.try_pick` → `CombatAIActionPicker.pick_weighted` → `CombatResolveAction.resolve`; defense at strike via `DefenseChoiceResolver`.

---

## Session start (copy-paste task line)

> Run Phase 0. If green, pick **one** priority from the list below (or I will name it). Smallest diff in the owning module. Re-run gate before done. One logical fix per session.

**Current priorities (2026-06-08+, gate green) — pick one:**

1. **III-6 line plug** — rank-0 gap `swap_rank` / Skirmish `rotate_file`; validator `camp_line_plug_pick`. Deep spec: [§ III-6 line plug](#specialty-iii-6-line-plug) below.
2. **Harness row fix** — failing Phase 0 / D001 tail; smallest `*Tail.gd` owner.
3. **Mental stack regression** — `_run_mental_stack_*` in `CombatRegressionHarnessAttentionFootworkTail.gd` (L0–L4, MS-L5 plug, MS-L6 rout, MS-L7 exhaustion + salience damp).
4. **III-4 3e fight-finish** — sparse/mop-up pick stalls. Deep spec: [§ III-4 3e fight-finish](#specialty-iii-4-3e-fight-finish) below.
5. **WF maintain** — PA octant + `WeaponFormTail` / ii5c + `_run_t44_spatial_*` when footing behavior changes (T44 flags default off; WF-M1–M5 ☑; no new tiers).
6. **III-3 deflect/bind** — `DefenseChoiceResolver` calibration if research `warn` surfaces (not `note` rows).
7. **BattleUIUpdater medical busy** — gauge primary label during medical wind-up / receiving care (`_run_medical_phase_gauge_*`).
8. **Species S5 pilot** — `species/SpeciesResource.gd`, `human.tres`, `goblin.tres` + simulation harness rows.

<a id="priority-harness-row-fix"></a>
<a id="priority-mental-stack-regression"></a>
<a id="priority-wf-maintain"></a>
<a id="priority-iii-3-deflect-bind"></a>
<a id="priority-battleui-medical-busy"></a>
<a id="priority-species-s5"></a>

**Mental stack improvements (swordmaster gaps):** 2 of 7 phases shipped (MS-L5 plug, MS-L6 rout). 5 remaining; recommended order: feint resistance → medical escalation → exhaustion gradient → post-strike → positional awareness. Full spec + harness names: [`docs/MENTAL_STACK_IMPROVEMENT_PLAN.md`](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md).

---

<a id="specialty-iii-4-3e-fight-finish"></a>

## Specialty: III-4 3e fight-finish

Post-rout mop-up and post-flee sparse skirmish pick pipeline: rotate suppress, L4b `sparse_fight`, trusted close, listing strip, fight-finish weights. Close audit gaps only — no new features.

**Extra gate:** `ii_envelop_mopup: PASS`.

**Read first:** `CombatDoctrine.gd` (`fight_finish_tail_active`, `sparse_line_prefer_finish_over_shuffle`, `should_suppress_skirmish_rotate_file`) → `MentalStackDecider.gd` (L4b before L4) → `CombatAIActionPicker.gd` → `CombatMeleeListing.gd` → `CombatRegressionHarnessTier1Tail.gd`.

**Own:** above plus `CombatFormationFlow.gd`, `CombatFormationMoveListing.gd`, `CombatPlayerTurnHints.gd`, `CombatEngagementDiagnostics.gd`, `CombatD001SoakRunner.gd`, `CombatD001TrackSpecs.gd`.

**Do not:** edit `world/*`; add `FEATURE_*`; regress rotate on full formation lines (4/5 rank-0 occupied).

**F5 grep:** `sparse_line=true`, `fight_finish=true`, `sparse_prefer_finish=true`, `rotate_suppress=true`; post-flee picks on `layer=sparse_fight`, not rotate ping-pong.

**Harness:** `_run_sparse_skirmish_line_rotate_suppressed_*`, `_run_fight_finish_*`, `_run_mop_up_*`, D001 `ii_envelop_sparse_*`.

---

<a id="specialty-iii-6-line-plug"></a>

## Specialty: III-6 line plug

Rank-0 **line plug** pick pipeline: rear `swap_rank` / Skirmish `rotate_file` when front rank-0 has a gap; incap plug-forward; gauge/hint suffix; sparse-line weight floor.

**Extra gate:** validator fixture `camp_line_plug_pick` green in D001 sanity.

**Read first:** `CombatFormationMoveListing.gd` → `CombatAIActionPicker.gd` → `CombatPlayerTurnHints.gd` → `CombatEngagementDiagnostics.gd` → `CombatRegressionHarnessTier1Tail.gd`.

**Own:** above plus `CombatFormationFlow.gd`, `CombatF5SoakTrace.gd`, `CombatD001SoakRunner.gd`, `CombatD001TrackSpecs.gd`.

**Do not:** regress sparse/mop-up rotate suppress ([§ III-4 3e](#specialty-iii-4-3e-fight-finish)); conflate line plug with MS-L5 Expand layer · edit `world/*`.

**F5 / validator grep:** `line_plug_pick=1`, `pick=swap_rank` or `pick=rotate_file`, `line_plug=false` when `sparse_line=true` + `rotate_suppress=true`.

**Harness:** `_run_swap_rank_line_plug_weight_when_front_hole`, `_run_rotate_file_line_plug_weight_when_front_hole`, `_run_sparse_line_rotate_no_line_plug_weight_floor`, D001 `ii_line_plug` / `ii_skirmish_rotate` probes.

**Escalation:** if you find an issue in files outside your owning module (especially `world/*`, `core/*`), report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. Hand off to the appropriate stream owner.

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Success:** gate green · smallest diff in owning module · one logical fix delivered.

PR prefix: `combat:`.
