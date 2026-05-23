# Shipped combat live paths

<a id="milestone-summary"></a>

**Read:** [`PLANNING.md`](PLANNING.md) · [`CURSOR#what-to-do-next`](CURSOR.md#what-to-do-next) · [`SHIP_PLAN`](SHIP_PLAN.md) · scripts [`../scripts/README.md`](../scripts/README.md). Tombstones: [#redirects-tombstones](#redirects-tombstones).

<a id="tier-1-spec"></a>

## Tier 0–1 — formation / range

| Area | Modules | Harness |
|------|---------|---------|
| Plugs / flow | `CombatFormationFlow`, `CombatFormationVacancyPlugs` | `_run_vacancy_*`, `_run_plug_*` |
| Cohesion / mode | `CombatFormationEngagement`, `CombatEngagementMode` | `_run_posture_*`, `_run_engagement_*` |
| Lanes / ZoC | `CombatPairGeometry`, `CombatDistanceBands`, `TacticalCombat`, `ZoneOfControl` | `_run_lane_offset_*`, `_run_depth_polearm_*`, `_run_surround_*`, `_run_sector_surround_*` |
| Close | `CombatMeleeListing`, `CombatEngagementResolver` | `_run_attempt_close_*`, `_run_close_slot_cap_*` |

<a id="development-gate-line-crash--intrusions-removed"></a>
<a id="d-005-surround"></a>
<a id="d-005--surround-arc-occupancy--shipped"></a>

`attempt_close` at LONG (max 3 CLOSE) · **D-008** no line crash · **D-005** `CombatSurroundArcOccupancy` / `FEATURE_SURROUND_ARC_OCCUPANCY` (±38°, blocked ×0.35; sector load when `is_feature_sector_surround_load()`).

<a id="tier-3--parry--bind--guards"></a>
<a id="tier-0--formation--parry-choice"></a>
<a id="d-006-guard-lines"></a>
<a id="d-006--hema-eight-guard-lines--shipped"></a>
<a id="d-007--parry-telegraph--shipped"></a>

## Tier 3 — parry / bind / guards

`DefenseChoiceResolver`, `CombatIncomingParryChoice` (**D-007**), `CombatGuardLines` (**D-006**) · `PARRY_DEFLECT_THRESHOLD` **1.08**, `PARRY_BIND_CONTROL_THRESHOLD` **0.65** · `_run_parry_*`, `_run_bind_*`, `_run_*guard*`.

<a id="tier-4--ai--footwork--flurry"></a>

## Tier 4 — AI / footwork / flurry

`CombatTargetScoring`, `CombatAIActionPicker`, `CombatFootwork`, `CounterTempo`, `CombatAttention`, `CombatFlurryBind` · tails: `Tier1Tail`, `FeintTempoTail`, `AttentionFootworkTail`.

<a id="tier-5--kinematic-delivery"></a>
<a id="closed-simulation-s11"></a>
<a id="closed-material-p3b"></a>

## Tier 5 — kinematic + simulation (maintain only)

Kinematic: `ImpactVelocityModel`, `WeaponSwingPhysics`, `AttackResolver` — `_run_kinematic_delivery_*`. Sim/P3b: `_run_sim_*`, `_run_mat_*`, `_run_mat_production_*` (`CombatRegressionHarnessSimulation.gd`). Gate: `p3b_full_including_energy_pool_joule_armor_and_literal_blood_ml` · lethality [#12-tuning-order](#12-tuning-order-keep-research-chain).

<a id="research-audit"></a>
<a id="every-session-step-0"></a>
<a id="enable-per-hit-research_feel-lines"></a>
<a id="f5-optional-crosswalk-feel-vs-headless"></a>

**Research audit:** `.calibration_audit.txt` · `CombatResearchAnchors.gd` · `_run_research_*` (`RESEARCH_HARNESS_GATE_IDS`, 35 gates). Fail → fix constants/anchors + [`CURSOR` decision log](CURSOR.md#decision-log). **`note`** rows: ignore (`cut_bone_pen_gate_mm`, `forearm_blunt_fracture_anchor_J`, `layer_rupture_subcut_bleed_mult`, `blunt_fracture_scaling`, `human_head_tissue_pct`). F5: [#playtest-q1](#playtest-q1-research-feel-duel) · `dev_research_feel`+ii2b · [#enable-per-hit-research_feel-lines](#enable-per-hit-research_feel-lines). **§1/§6/§10:** [#bleeding-physics](#bleeding-physics). **Edit:** `BleedingConstants` · `CombatResearchAnchors` · `species/*.tres` · `CombatCalibrationAudit` · [#production-flags](#production-flags). One `FEATURE_*` per PR.

<a id="tier-6--medical--flee"></a>
<a id="bleeding-units"></a>
<a id="d-003--medical-pack-bc--shipped"></a>

## Tier 6 — medical / flee

`EntityMedical`, `MedicalPhaseController`, `CombatMedicalCoordination`, `CombatFormationFlee` · `_run_medical_*`, `_run_pack_wound_*`, `_run_flee_*`, `_run_ambient_pain_shock_*` · `MedicalPhaseTail`.

**Bleeding (D-003):** `BleedingConstants.gd` — [#bleeding-physics](#bleeding-physics).

**Medical phase:** `medical_phase_winner` locks end-combat side; party wipe does not flip winner. Post-victory: losers `[]`; winner medical-only; losers blocked via `MedicalPhaseController.POST_VICTORY_BLOCKED_EVENT_TYPES`. Harness: `_run_medical_phase_winner_*`, `_run_medical_phase_winner_listing_medical_only`. Fast iteration (12 tests): `.\scripts\run_all_combat_checks.ps1 -HarnessMode medical`.

<a id="bleeding-physics"></a>

### Bleeding physics and units

`BleedingConstants.gd` · `CombatResearchAnchors.gd` · `.calibration_audit.txt` `[research_benchmarks]`.

| Quantity | Unit | Notes |
|----------|------|--------|
| `blood_volume` | **%** (0–100) | UI, ATLS class, death threshold |
| `blood_volume_ml` | **mL** | Pool when `FEATURE_LITERAL_BLOOD_ML` on |
| Wound `bleeding_rate` | **abstract HP/s** | Severity × part × sub-region × arterial |
| `BLOOD_LOSS_RATE_MULTIPLIER` | **dimensionless** | HP/s → % blood lost per second |

<a id="1-hemorrhage-and-atls-blood-volume-ttd"></a>

**ATLS (remaining blood %):** I ≥85 · II ≥70 · III ≥60 · IV death at **35%** remaining.

**Reference uncontrolled bleed:** `BLEEDING_RATES[cut][critical] × head × arterial` = **13.5 HP/s**.

**TTD:** `(blood_volume − threshold) / (rate × BLOOD_LOSS_RATE_MULTIPLIER × loss_mult)` → default **~48 s**; tune mult for **30–120 s** band. Direct pressure `loss_mult = 0.5` → ~2× TTD.

<a id="5-literal-blood-volume-ml"></a>

**Literal mL:** human **75 kg → 5250 mL** · goblin **38 kg → 2660 mL** (`species/*.tres`, `CombatDesignAnchors`).

<a id="6-gaps-and-recommended-follow-ups"></a>

**Arterial chance (cut):** critical **0.26** → severe **0.14** → moderate **0.06** → minor **0.01**; crush ×0.35. Triage **90 s** / **45 s** vs ref TTD **~48 s**.

<a id="10-blunt-fracture-j-vs-nm-biomechanics-note"></a>

**Clotting** `exp(-k×Δt)` · **pain** human ref **~3.0** / **~2** hits → NRS 4 · **blunt KE** oberhau **~137 J**, arm **22 J** (rank-order only).

<a id="12-tuning-order-keep-research-chain"></a>

**Tuning order:** (1) `BLEEDING_RATES` (2) `REFERENCE_UNCONTROLLED_BLEED_RATE` (3) `BLOOD_LOSS_RATE_MULTIPLIER` (4) part mults (5) death threshold + ATLS doc · then `run_all_combat_checks.ps1`.

<a id="d-004-exhaustion"></a>
<a id="d-004--exhaustion-index--shipped-mxm"></a>
<a id="mxm--exhaustion-index-d-004-m7a"></a>
<a id="mxm--exhaustion-index-d-004-m7a-extension"></a>
<a id="ii-4d--stamina-and-exhaustion-feel"></a>

**D-004:** `CombatExhaustion` · gauge **`Exh N%`** · F5 **ii4d** (3–5 min duel).

<a id="battle-ui"></a>

## Battle UI

`BattleUIUpdater` · `CombatUiHints` · `CombatPlayerTurnHints` · **`Stm N% · Ready · Exh · Grd`** · F5: `turn_ready_gauge`, `tooltip_match=`, `diagram_banner` — `_run_battle_ui_gauge_label_*`.

<a id="species-calibration"></a>

**Species:** `human.tres` **75 kg** · `goblin.tres` **38 kg** · `feature_derived_limb_capacity` — [#5-literal-blood-volume-ml](#5-literal-blood-volume-ml) · [#research-audit](#research-audit).

<a id="harness-prefixes"></a>

## Harness `_run_*` prefixes

**Run:** `.\scripts\run_all_combat_checks.ps1` (full gate) · fast paths: `-HarnessMode regression|d001|sanity|calibration|medical` ([`scripts/README`](../scripts/README.md)).

`grep '_run_' combat/CombatRegressionHarness.gd` (+ tails, `CombatRegressionHarnessSimulation.gd`). **No** `_run_crash_*` / `_run_intrusion_*`.

| Area | Prefixes |
|------|----------|
| 0–1 | `_run_formation_*`, `_run_vacancy_*`, `_run_engagement_*`, `_run_surround_*`, `_run_depth_polearm_*` |
| 3–4 | `_run_parry_*`, `_run_bind_*`, `_run_guard_*`, `_run_feint_*`, `_run_flurry_*`, `_run_battle_ui_*` |
| 5 | `_run_kinematic_*`, `_run_sim_*`, `_run_mat_*` |
| 6–7 | `_run_medical_*`, `_run_flee_*`, `_run_research_*`, `_run_f5_headless_*`, `_run_exhaustion_*` |

<a id="phase-0-gate"></a>
<a id="calibration-audit"></a>
<a id="headless-gate-authoritative"></a>
<a id="ii-0--baseline-soak-plan-p1"></a>
<a id="f5-d-001-preset-sweep"></a>
<a id="playtest-q1-research-feel-duel"></a>
<a id="playtest-q2-ii2b-bind-riposte-feel"></a>
<a id="d-001-mandatory-tracks-after-ii-0-scenarios"></a>
<a id="d-001--ii-2b--deflect--bind-calibration"></a>
<a id="d-001--ii-5a--formation-action-menu-labels"></a>
<a id="d-001--ii-5c--gauge-suffixes"></a>
<a id="d-001--ii-5b--combat-log-copy"></a>

## Phase 0 (D-001) · II-0 soak

Headless authoritative: `.d001_headless_signoff.txt` `ok=true`. F5 optional: [`Playtest` stream](PLANNING.md#stream-playtest).

`.\scripts\run_all_combat_checks.ps1` → `FP_HARNESS_OK: AllCombatChecks`. Outputs: `.d001_soak_out.txt`, `.f5_soak_validation.txt`, `.calibration_audit.txt`, `.d001_soak_sanity_out.txt`. `CombatD001SoakRunner` (incl. **ii7** pack-wound + **formation_move_f5** `rotate_file@` greps), `CombatD001SoakSanity`, `CombatF5SoakLogValidator`. Fast paths: `run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical` ([`scripts/README.md`](../scripts/README.md)). Summary: `print_phase0_status.ps1`. No harness piping to `grep`.

| # | Headless | F5 glance |
|---|----------|-----------|
| 1 | **ii2b** ×3 | duel feel |
| 3 | **ii3** + 7v7 | Arc overlap |
| 4 | **ii5a**/**ii8** | tooltips |
| 5 | **ii5** fall_back | cyan tile |
| 6 | **ii6** pain shock | wait |
| 7 | **ii7** medical | pack |
| 8 | **ii1e**/**ii8** | diagram |
| — | **ii4d** Exh | 3–5 min |

F5 workflow: optional `dev_soak_encounter` → `.f5_soak_in.txt` → `validate_f5_soak_log.ps1` (multi-fight: `append_f5_soak_log.ps1`). Validator smoke (no F5): copy `docs/f5_soak_log.example.txt` → `.f5_soak_in.txt`. Q helpers: `run_q_feel.ps1 -Track Q1|Q2` · `run_q_audit.ps1 -Track Track`. Mandatory II-2b/5a/5b/5c/4d: headless ☑.

<a id="integration-archive"></a>
<a id="run-this-plan-cursor"></a>
<a id="integration-wiring-index"></a>
<a id="phase-3--integration-depth-shipped--deeper-wiring"></a>
<a id="production-flags"></a>
<a id="tier-5-simulation-flags-2026-05"></a>
<a id="iii-3--deflect--bind-calibration-loop-m3c"></a>
<a id="phase-4--new-systems-formal-tracks"></a>
<a id="before-you-add-a-new-combat-tier"></a>

## Integration

POST **0–2** done · **3–5** / **IV-\*** → [`Expand` stream](PLANNING.md#stream-expand). **Flags** (`CombatConstants.gd`): `is_feature_sector_surround_load`, `FEATURE_SURROUND_ARC_OCCUPANCY`, `FEATURE_HEMA_EIGHT_GUARD_LINES`, `FEATURE_FLURRY_BIND_EXCHANGE`, `FEATURE_INCOMING_PARRY_CHOICE`, `FEATURE_AMBIENT_PAIN_SHOCK`, position-angle footwork, `FEATURE_FIGHT_EXHAUSTION_INDEX`. **D-tracks:** D-001 ☑ · D-003–007 shipped · D-008 removed. II-0/III-3: [#phase-0-gate](#phase-0-gate) · [#iii-3](#iii-3--deflect--bind-calibration-loop-m3c). **IV-\*:** open **1,3,5–13** · done **2** · partial **4** · **7b** archived (D-004).

New tier: harness row + one line in tier table — see [#redirects-tombstones](#redirects-tombstones) for deleted plan prose.

<a id="legacy-anchors"></a>

## Legacy anchors (redirect targets)

<a id="development-gate-sector-surround-load-temporary"></a>
<a id="phase-a--sector-surround-enable-tier-31"></a>
<a id="dependency-chain-execution-logic"></a>
<a id="dependency-chain-shipped-build-order"></a>
<a id="dependency-chain-remaining-enablement"></a>
<a id="next-implementation-phase"></a>
<a id="tier-01-formation-move-duration-ui"></a>
<a id="tier-02-formation-hit-reaction-incoming-parry"></a>
<a id="tier-1--engagement-geometry-shipped--maintain--gated-intrusion"></a>
<a id="tier-1--engagement-geometry-active-track"></a>
<a id="all-tiers-at-a-glance"></a>
<a id="next-coding-step"></a>
<a id="p1-editor-soak-checklist"></a>
<a id="expansion-backlog-p4-playbooks"></a>
<a id="p4a--tier-72-stamina-depletion-pacing"></a>
<a id="p4b--tier-01-formation-move-duration-ui"></a>
<a id="p4c--tier-110-automatic-doctrine-pilot"></a>
<a id="p4d--tier-32-parry-bind-doc-sync"></a>
<a id="p4e--tier-42b-feint-listing-reveal-parity"></a>
<a id="p4f--tier-62-flee-formation-action"></a>
<a id="p4g--tier-45-flurry-pilot"></a>
<a id="p4h--tier-32-bind-riposte-balance-soak"></a>
<a id="tier-110-automatic-doctrine-pilot"></a>
<a id="tier-45-flurry-bind-exchange-deferred"></a>
<a id="tier-62-dedicated-flee-formation-action"></a>
<a id="tier-7--research--fidelity-non-blocking"></a>
<a id="tier-63-medical-phase-coordination"></a>
<a id="implementation-phase-gate"></a>
<a id="tier-13-gate-p4"></a>
<a id="tier-2--tactical-docs--zoc-narrative-sync"></a>
<a id="tier-31-strike-measure-stamped-geometry"></a>
<a id="tier-32-parry-bind-deflect"></a>
<a id="tier-33-guard-line-afterblow"></a>
<a id="tier-4--ai--stance"></a>
<a id="tier-41-posture--stance-weights-ai-listing"></a>
<a id="tier-42-feint-d-telegraph-ai"></a>
<a id="tier-43-mental-stack--combat-attention"></a>
<a id="tier-44-spatial-footwork-deferred"></a>
<a id="tier-5--damage--physics-polish"></a>
<a id="tier-51-angles-damage-flow-audits"></a>
<a id="tier-61-mobility-pain-shock-extensions"></a>
<a id="tier-19--p10-depth-rank-polearm-reach--spear-lanes"></a>
<a id="tier-7-live-path"></a>
<a id="tier-expansion-audit-2026-05-17"></a>
<a id="post-expansion-backlog"></a>

Status for shipped tiers → sections above · forward work → [`CURSOR#what-to-do-next`](CURSOR.md#what-to-do-next).

<a id="redirects-tombstones"></a>

## Redirects (deleted `docs/*.md`)

**Policy:** Do not recreate files in this table — Phase 0 fails `check_doc_links.ps1` if they exist. **Canonical (4):** [`PLANNING.md`](PLANNING.md) · [`CURSOR.md`](CURSOR.md) · [`SHIP_PLAN.md`](SHIP_PLAN.md) · this file. Scripts: [`../scripts/README.md`](../scripts/README.md). Restore prose: `git log -- docs/<file>.md`.

| File | Anchor |
|------|--------|
| `BLEEDING_PHYSICS_AND_UNITS.md` | [bleeding-physics](LIVE_PATHS.md#bleeding-physics) · [§12 tuning](LIVE_PATHS.md#12-tuning-order-keep-research-chain) |
| `REDIRECTS.md` | [redirects-tombstones](LIVE_PATHS.md#redirects-tombstones) |
| `NEXT_DEVELOPMENT_PLAN.md` | [PLANNING](PLANNING.md) · [what-to-do-next](CURSOR.md#what-to-do-next) · [SHIP_PLAN](SHIP_PLAN.md) |
| `RESEARCH_AUDIT_CHECKLIST.md` | [research-audit](LIVE_PATHS.md#research-audit) · [enable-per-hit-research_feel-lines](LIVE_PATHS.md#enable-per-hit-research_feel-lines) |
| `README.md` (docs) | [scripts/README.md](../scripts/README.md) |
| `ENGAGEMENT_LINE_COHESION_PLAN.md` | [tier-1-spec](LIVE_PATHS.md#tier-1-spec) |
| `BATTLE_UI_DATA_FLOW.md` | [battle-ui](LIVE_PATHS.md#battle-ui) |
| `STAMINA_EXHAUSTION_INTEGRATION.md` | [d-004](LIVE_PATHS.md#d-004-exhaustion) |
| `SURROUND_GEOMETRY_INVESTIGATION.md` | [d-005](LIVE_PATHS.md#d-005-surround) |
| `HEMA_EIGHT_GUARD_LINES.md` | [d-006](LIVE_PATHS.md#d-006-guard-lines) |
| `D001_AUTOMATION_PLAN.md` | [phase-0](LIVE_PATHS.md#phase-0-gate) |
| `II_0_SOAK_RUNBOOK.md` | [phase-0 / II-0](LIVE_PATHS.md#headless-gate-authoritative) · [#playtest-q1](LIVE_PATHS.md#playtest-q1-research-feel-duel) |
| `IMPLEMENTATION_ORDER.md` | [legacy-anchors](LIVE_PATHS.md#legacy-anchors) |
| `REGRESSION_HARNESS_MAP_TIER19.md` | [harness-prefixes](LIVE_PATHS.md#harness-prefixes) |
| `SIMULATION_REALISM_*.md` | [closed-simulation-s11](LIVE_PATHS.md#closed-simulation-s11) |
| `MATERIAL_FAILURE_*.md` | [closed-material-p3b](LIVE_PATHS.md#closed-material-p3b) |
| `POST_MILESTONE_*.md` | [integration-archive](LIVE_PATHS.md#integration-archive) · IV [#phase-4](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) |
| `COMBAT_PHYSICS_MEDICAL_*.md` | [research-audit](LIVE_PATHS.md#research-audit) |
| `PARRY_*` / `GUARDS_*` / `COMBAT_ROADMAP_*` | [tier-3](LIVE_PATHS.md#tier-3--parry--bind--guards) or [integration](LIVE_PATHS.md#integration-archive) |
