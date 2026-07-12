Stream: **Combat**. Default post–Camp-5 — smallest `combat/*.gd` owner per [`PLANNING#file-ownership`](../../docs/PLANNING.md#file-ownership). Bundle chat 1: [`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle).

**Gate:** `./scripts/run_all_combat_checks.sh` → **`PHASE0: PASS`**.

**Own:** `combat/*`, `harness/*`, battle UI formatters (`BattleUIUpdater`, `FormationDiagramBuilder`, `TurnReadyHandler`, `CombatLogFormatter`), `character.gd` (combat hooks).

**Do not touch:** `world/*`, `main.gd`, party/settlement UI, new `FEATURE_*`, closed gates, bridge files without Campaign coord. Expand → [`README#expand-reopen`](README.md#expand-reopen). Frozen: [`PLANNING#harness-and-flags`](../../docs/PLANNING.md#harness-and-flags).

**Read first:** [`LIVE_PATHS#combat-cognition-pipeline`](../../docs/LIVE_PATHS.md#combat-cognition-pipeline) · [`SHIP_PLAN` §9b](../../docs/SHIP_PLAN.md#combat-mental-stack-shipped).

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> Run Phase 0. Pick **one** priority. Smallest owning-module diff. Re-gate.

1. **III-6 line plug** — [§](#specialty-iii-6-line-plug) · `camp_line_plug_pick`
2. **Harness row fix** — failing Phase 0 / D001 `*Tail.gd`
3. **Mental stack** — `_run_mental_stack_*` in `AttentionFootworkTail`
4. **III-4 3e fight-finish** — [§](#specialty-iii-4-3e-fight-finish) · `ii_envelop_mopup: PASS`
5. **WF maintain** — WeaponFormTail / ii5c / `_run_t44_spatial_*` (no new tiers)
6. **III-3 deflect/bind** — research `warn` only
7. **BattleUI medical busy** — `_run_medical_phase_gauge_*`
8. **Species S5** — `species/*` + harness

<a id="priority-harness-row-fix"></a>
<a id="priority-mental-stack-regression"></a>
<a id="priority-wf-maintain"></a>
<a id="priority-iii-3-deflect-bind"></a>
<a id="priority-battleui-medical-busy"></a>
<a id="priority-species-s5"></a>

Mental stack map: [`SHIP_PLAN` §9b](../../docs/SHIP_PLAN.md#combat-mental-stack-shipped) · archive [`MENTAL_STACK_IMPROVEMENT_PLAN`](../../docs/archive/MENTAL_STACK_IMPROVEMENT_PLAN.md).

---

<a id="specialty-iii-4-3e-fight-finish"></a>

## Specialty: III-4 3e fight-finish

Post-rout mop-up / sparse skirmish: rotate suppress, L4b `sparse_fight`, fight-finish weights. Close audit gaps only.

**Extra gate:** `ii_envelop_mopup: PASS`.

**Read:** `CombatDoctrine` → `MentalStackDecider` (L4b) → `CombatAIActionPicker` → `CombatMeleeListing` → `harness/CombatRegressionHarnessTier1Tail.gd`.

**Do not:** `world/*` · new `FEATURE_*` · regress rotate on full lines.

**Grep:** `sparse_line=true`, `fight_finish=true`, `rotate_suppress=true`. Harness: `_run_sparse_skirmish_*`, `_run_fight_finish_*`, `_run_mop_up_*`, D001 `ii_envelop_sparse_*`.

---

<a id="specialty-iii-6-line-plug"></a>

## Specialty: III-6 line plug

Rank-0 gap → rear `swap_rank` / Skirmish `rotate_file`; incap plug-forward; sparse-line weight floor.

**Extra gate:** `camp_line_plug_pick` in D001.

**Read:** `CombatFormationMoveListing` → `CombatAIActionPicker` → `CombatPlayerTurnHints` → `Tier1Tail`.

**Do not:** regress 3e rotate suppress · conflate with MS-L5 · edit `world/*`.

**Grep:** `line_plug_pick=1`. Harness: `_run_swap_rank_line_plug_*`, `_run_rotate_file_line_plug_*`, D001 `ii_line_plug`.

PR prefix: `combat:`.
