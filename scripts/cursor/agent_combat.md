Stream: **Combat**. **Default post–Camp-5** — smallest `combat/*.gd` owner per `docs/PLANNING.md#file-ownership`. Copy into parallel bundle chat 1 ([`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle)).

**Gate before done:** `.\scripts\run_all_combat_checks.ps1` → **`PHASE0: PASS`**.

**Own:** `combat/*`, harness tails (`CombatRegressionHarness*`, `CombatD001*`), `ui/BattleUIUpdater.gd`, `ui/FormationDiagramBuilder.gd`, `ui/TurnReadyHandler.gd`, `ui/CombatLogFormatter.gd`, `character.gd` (combat hooks only).

**Do not touch:** `world/*`, `main.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `BleedingConstants.gd` (unless I ask), new `FEATURE_*`, bleed retune. **Expand rows** → [`README.md#expand-reopen`](README.md#expand-reopen).

**Before pick / attention / defense:** read `docs/LIVE_PATHS.md#combat-cognition-pipeline` and `docs/SHIP_PLAN.md#combat-mental-stack-shipped`. Pipeline: `AvailableActionsBuilder.build` → `MentalStackDecider.try_pick` → `CombatAIActionPicker.pick_weighted` → `CombatResolveAction.resolve`; defense at strike via `DefenseChoiceResolver`.

**Round 2 priorities (2026-06-07+, gate green) — pick one:**

1. **III-6 line plug** — rank-0 gap `swap_rank` / Skirmish `rotate_file`; validator `camp_line_plug_pick`. Deep spec: [§ III-6 line plug](#specialty-iii-6-line-plug) below.
2. **Harness row fix** — failing Phase 0 / D001 tail; smallest `*Tail.gd` owner.
3. **Mental stack regression** — `_run_mental_stack_*` in `CombatRegressionHarnessAttentionFootworkTail.gd` (L0–L4, MS-L5 plug, MS-L6 rout, MS-L7 exhaustion + salience damp).
4. **III-4 3e fight-finish** — sparse/mop-up pick stalls. Deep spec: [§ III-4 3e fight-finish](#specialty-iii-4-3e-fight-finish) below.
5. **WF maintain** — PA octant + `WeaponFormTail` / ii5c + **`_run_t44_spatial_*`** when footing behavior changes (T44 flags default off; WF-M1–M5 ☑; no new tiers).
6. **III-3 deflect/bind** — `DefenseChoiceResolver` calibration if research `warn` surfaces (not `note` rows).
7. **BattleUIUpdater medical busy** — gauge primary label during medical wind-up / receiving care (`_run_medical_phase_gauge_*`).
8. **Species S5 pilot** — `species/SpeciesResource.gd`, `human.tres`, `goblin.tres` + simulation harness rows.

**Mental stack improvements (swordmaster gaps):** 2 of 7 phases shipped (MS-L5 plug, MS-L6 rout). 5 remaining: [feint resistance](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md#phase-2-feint-resistance-gate-counter-tempo-integration) · [post-strike momentum](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md#phase-3-post-strike-momentum-layer-ms-l8) · [exhaustion gradient](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md#phase-5-exhaustion-gradient-replace-binary-tunnel-with-gradual-descent) · [positional awareness](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md#phase-6-positional-awareness-surrounded-combatant-disengage-trigger) · [medical escalation](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md#phase-7-medical-escalation-ladder-tccc-progression-on-repeated-failure). Full spec + validation + harness names: [`docs/MENTAL_STACK_IMPROVEMENT_PLAN.md`](../../docs/MENTAL_STACK_IMPROVEMENT_PLAN.md). Recommended order: feint resistance → medical escalation → exhaustion gradient → post-strike → positional awareness.

Minimal diff. One logical fix. PR title prefix: `combat:`.

---

<a id="specialty-iii-4-3e-fight-finish"></a>

## Specialty: III-4 3e fight-finish

Post-rout mop-up and post-flee sparse skirmish pick pipeline: rotate suppress, L4b `sparse_fight`, trusted close, listing strip, fight-finish weights. Close audit gaps only — no new features.

**Extra gate:** **`ii_envelop_mopup: PASS`**.

**Read first:** `CombatDoctrine.gd` (`fight_finish_tail_active`, `sparse_line_prefer_finish_over_shuffle`, `should_suppress_skirmish_rotate_file`) → `MentalStackDecider.gd` (L4b before L4) → `CombatAIActionPicker.gd` → `CombatMeleeListing.gd` → `CombatRegressionHarnessTier1Tail.gd`.

**Own:** above plus `CombatFormationFlow.gd`, `CombatFormationMoveListing.gd`, `CombatPlayerTurnHints.gd`, `CombatEngagementDiagnostics.gd`, `CombatD001SoakRunner.gd`, `CombatD001TrackSpecs.gd`.

**Do not:** edit `world/*`; add `FEATURE_*`; regress rotate on full formation lines (4/5 rank-0 occupied).

**F5 grep:** `sparse_line=true`, `fight_finish=true`, `sparse_prefer_finish=true`, `rotate_suppress=true`; post-flee picks on `layer=sparse_fight`, not rotate ping-pong.

**Harness:** `_run_sparse_skirmish_line_rotate_suppressed_*`, `_run_fight_finish_*`, `_run_mop_up_*`, D001 `ii_envelop_sparse_*`.

---

<a id="specialty-iii-6-line-plug"></a>

## Specialty: III-6 line plug

Rank-0 **line plug** pick pipeline: rear `swap_rank` / Skirmish `rotate_file` when front rank-0 has a gap; incap plug-forward; gauge/hint suffix; sparse-line weight floor.

**Extra gate:** validator fixture **`camp_line_plug_pick`** green in D001 sanity.

**Read first:** `CombatFormationMoveListing.gd` → `CombatAIActionPicker.gd` → `CombatPlayerTurnHints.gd` → `CombatEngagementDiagnostics.gd` → `CombatRegressionHarnessTier1Tail.gd`.

**Own:** above plus `CombatFormationFlow.gd`, `CombatF5SoakTrace.gd`, `CombatD001SoakRunner.gd`, `CombatD001TrackSpecs.gd`.

**Do not:** regress sparse/mop-up rotate suppress ([§ III-4 3e](#specialty-iii-4-3e-fight-finish)); conflate line plug with MS-L5 Expand layer.

**F5 / validator grep:** `line_plug_pick=1`, `pick=swap_rank` or `pick=rotate_file`, `line_plug=false` when `sparse_line=true` + `rotate_suppress=true`.

**Harness:** `_run_swap_rank_line_plug_weight_when_front_hole`, `_run_rotate_file_line_plug_weight_when_front_hole`, `_run_sparse_line_rotate_no_line_plug_weight_floor`, D001 `ii_line_plug` / `ii_skirmish_rotate` probes.
