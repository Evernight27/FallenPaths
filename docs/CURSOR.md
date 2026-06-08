# Cursor entry (Godot 4.x)

**Planning model:** [`PLANNING.md`](PLANNING.md) (work streams + milestone prefixes) · [`SHIP_PLAN.md`](SHIP_PLAN.md) (Campaign · Camp-5 ☑) · [`EXPANSION_PLAN.md`](EXPANSION_PLAN.md) (post-EA combat + campaign phases) · [`LIVE_PATHS.md`](LIVE_PATHS.md) (shipped combat) · **Agent prompts:** [`scripts/cursor/README.md`](../scripts/cursor/README.md)

```powershell
.\scripts\run_all_combat_checks.ps1
.\scripts\print_phase0_status.ps1
.\scripts\run_q_feel.ps1 -Track Camp   # on-demand F5 §8 validator checklist
```

Bash: `./scripts/run_all_combat_checks.sh` · `./scripts/print_phase0_status.sh` · `./scripts/run_q_feel.sh Camp`

Smallest `combat/*.gd` owner · thin `CombatManager.gd` · `ZoneOfControl.formation_dict_for_zone_geometry` · no harness piping to `grep`.

Flags: [`LIVE_PATHS#production-flags`](LIVE_PATHS.md#production-flags).

<a id="what-to-do-next"></a>

## What to do next

1. **Gate** — `.\scripts\run_all_combat_checks.ps1` → **`PHASE0: PASS`** (includes company checks + **Camp-3.4** Q/`[ii7]` tail → **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`**)
2. **Post–Camp-5 (2026-06-07 ☑)** — [`README#parallel-expansion-bundle`](../scripts/cursor/README.md#parallel-expansion-bundle) · [`EXPANSION_PLAN.md`](EXPANSION_PLAN.md) · [parallel agents](PLANNING.md#parallel-agents) · [single agent](#single-agent)
3. **Product choices** — closed in [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22); new gates only → guide appendix + [§19](SHIP_PLAN.md#implementation-stubs)

Stream pick + parallel rules: [`PLANNING#work-streams`](PLANNING.md#work-streams) · [`PLANNING#parallel-agents`](PLANNING.md#parallel-agents). **Project health:** [`agent_maintain.md`](../scripts/cursor/agent_maintain.md) · [`agent_hygiene.md`](../scripts/cursor/agent_hygiene.md) · [`agent_audit.md`](../scripts/cursor/agent_audit.md) · [`agent_enhance.md`](../scripts/cursor/agent_enhance.md).

<a id="single-agent"></a>

## Single agent

If only one agent: one **Combat** maintain fix · optional **Expand** ([`README#expand-reopen`](../scripts/cursor/README.md#expand-reopen)) · optional F5 append — not bleed retune.

**Not next:** bleed retune · BMI (**F1**) · closed S1–S11/P3b · audit `note` rows · closed IV-1,3,5–13 (Expand picks open rows per [§9c](SHIP_PLAN.md#combat-expand-registry) only).

<a id="every-session"></a>

## Every session

1. Phase 0 gate (above)
2. Lethality drift only via [`LIVE_PATHS` bleeding §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain)

<a id="stream-combat"></a>

## Combat stream

Prompt: [`agent_combat.md`](../scripts/cursor/agent_combat.md) · detail: [`PLANNING#stream-combat`](PLANNING.md#stream-combat) · III-4 **3e:** [`agent_combat.md#specialty-iii-4-3e-fight-finish`](../scripts/cursor/agent_combat.md#specialty-iii-4-3e-fight-finish).

<a id="stream-expand"></a>

## Expand stream

Prompt: [`README#expand-reopen`](../scripts/cursor/README.md#expand-reopen) · detail: [`PLANNING#stream-expand`](PLANNING.md#stream-expand).

<a id="stream-playtest"></a>

## Playtest stream

Prompt: [`agent_playtest.md`](../scripts/cursor/agent_playtest.md) · detail: [`PLANNING#stream-playtest`](PLANNING.md#stream-playtest).

<a id="stream-campaign"></a>

## Campaign stream

Prompt: [`agent_campaign.md`](../scripts/cursor/agent_campaign.md) · detail: [`PLANNING#stream-campaign`](PLANNING.md#stream-campaign).

<a id="decision-log"></a>

## Decision log

- S1–S11/P3b closed · F1 BMI deferred · D-008 · medical winner lock
- **2026-05-22** — [`SHIP_PLAN.md`](SHIP_PLAN.md) merc EA plan
- **2026-05-22** — Planning relabel: ~~S/M/Q/F3~~ → **Campaign / Combat / Playtest / Expand**; milestones **Camp-\*** ([`PLANNING.md`](PLANNING.md))
- **2026-05-22** — **Parallel agents:** Campaign + Combat may run simultaneously (historical pre-ship; post–Camp-5 default: Combat + optional Expand/Playtest — [`PLANNING#parallel-agents`](PLANNING.md#parallel-agents))
- **2026-05-22** — Plan audit: closed gates [`PLANNING#closed-gates`](PLANNING.md#closed-gates); Camp-3.3 Combat-led; Camp-3.4 Playtest lane; ownership expanded
- **2026-05-22** — SHIP_PLAN §9–19: wiring, contracts, gate constants, gates-at-implementation, pre-start checklist
- **2026-05-22** — Camp D-* gates closed; canonical choices in [`CAMPAIGN_DECISION_GUIDE` user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22)
- **2026-05-22** — Plan sweep: §3d Camp-1 build order, §20 pitfalls, §17/§18 renumber, EA requires D-bleed closed
- **2026-05-22** — Tier 4.3 mental stack L0–L4 + salience damp integrated into [`SHIP_PLAN` §9b](SHIP_PLAN.md#combat-mental-stack-shipped) + [`LIVE_PATHS` tier 4.3](LIVE_PATHS.md#tier-43-mental-stack--combat-attention); no player target UI
- **2026-05-22** — D-004 MXm-3 + MS-L7: stamina bar decoupled from counter-tempo; effective max/ratio wiring; L5 exhaustion tunnel — [`LIVE_PATHS` D-004](LIVE_PATHS.md#d-004-exhaustion)
- **2026-05-22** — Camp-3.3: one-shot medical-phase combat-log hints + gauge busy tooltips (`CombatUiHints`, `BattleUIUpdater`, harness `_run_medical_phase_*`)
- **2026-05-22** — Full combat Expand registry: [`LIVE_PATHS` phase 4](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) + [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry) (III-*, P4a–h, IV-*, MS-L5+)
- **2026-06-06** — Footing/stances: research boundary + Camp-5 maintain backlog [**WF-M1…M5**](LIVE_PATHS.md#wf-footing-improvement-backlog); PA/form not in `CombatResearchAnchors`
- **2026-06-06** — Footing pass 9: harness **form_health_bar** use-after-free fix; **`run_camp_f5_closeout`** script; **`fixture_camp_wf_smoke`** — [`#wf-m3-f5-playtest`](LIVE_PATHS.md#wf-m3-f5-playtest)
- **2026-06-06** — Footing pass 8: **`append_f5_soak_log`**; **`f5_soak_log.camp_wf.example.txt`**; EA sign-off summary in **`print_phase0_status`** — [`#wf-m3-f5-playtest`](LIVE_PATHS.md#wf-m3-f5-playtest)
- **2026-06-06** — Footing pass 7: **`wf_m3_idle_step_leak`** optional F5 track; **`camp_ea`** synthetic markers — [`#wf-m3-f5-playtest`](LIVE_PATHS.md#wf-m3-f5-playtest)
- **2026-06-06** — Footing pass 6: D-001 sanity **`wf_m3_*`** / **`camp_ea`** validator fixtures — [`#wf-footing-improvement-backlog`](LIVE_PATHS.md#wf-footing-improvement-backlog)
- **2026-06-07** — **WF-T1 ☑** octant PA soak tune + **`_run_footwork_wf_t1_octant_suite`** — [`#wf-footing-improvement-backlog`](LIVE_PATHS.md#wf-footing-improvement-backlog)
- **2026-06-08** — **Medical physics (pass 5)** — TQ-indicated limb: **`can_apply_bandage`/`can_apply_stabilize`** blocked; **`MapFieldCare`** MARCH reordered (pressure → TQ → stabilize → pack → bandage) — [`#bleeding-physics`](LIVE_PATHS.md#bleeding-physics) · **`_run_field_care_tourniquet_before_bandage_parity`**
- **2026-06-08** — **Medical physics (pass 4)** — field **tourniquet** applies before procedure sim advance (not 2 min open limb bleed); **`can_apply_stabilize`** requires intrinsic active bleed (not arterial label after local clot) — [`#bleeding-physics`](LIVE_PATHS.md#bleeding-physics) · **`_run_field_tourniquet_applies_before_procedure_advance`** · **`_run_stabilize_requires_intrinsic_active_bleed`**
- **2026-06-08** — **Medical physics** — clotting/hemostasis + TCCC dress gates: **`EntityMedical`** compression required on active bleed for bandage/pack; stabilize trim-only; field pack/bandage parity — [`#bleeding-physics`](LIVE_PATHS.md#bleeding-physics) · **`_run_entity_medical_dressing_*`** · **`_run_field_care_pressure_before_*`**
- **2026-06-08** — **III-8 ☑** recovery-cause table parity — **`parry_partial`** alias · **`_run_iii8_recovery_cause_table_parity`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **p4e ☑** — feint listing ↔ reveal progress parity — **`_run_feint_move_listing_reveal_progress_dampens_early_wind_up`** — [`#tier-42-feint-d-telegraph-ai`](LIVE_PATHS.md#tier-42-feint-d-telegraph-ai)
- **2026-06-08** — **p4f ☑** — dedicated flee formation UX + AI archived — **`CombatRegressionHarnessFleeTail`** · [`#tier-62-dedicated-flee-formation-action`](LIVE_PATHS.md#tier-62-dedicated-flee-formation-action)
- **2026-06-08** — **IV-6 ☑** — **`FEATURE_IV6_ATTACK_PATH_OCTANT`** · zone-first diagonal path merge in **`get_attack_path`** · **`_run_iv6_attack_path_octant_suite`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **IV-12/IV-13 improve** — co-located pile-on **`IV12_AI_COLOCATED_TARGET_BIAS_MULT`** · **`CombatDistanceBands`** ZoC reach parity · **`mat_joule_prod`** stable sub-region seed
- **2026-06-08** — **IV-11 ☑** — leader formation commands slices 1–10 (hold/probe/pinch · player + enemy commander · pinch outnumber AI · F5 **`leader_order=`** / validator **`iv11_leader_order`**) — **`FEATURE_LEADER_FORMATION_COMMAND`** · **`_run_iv11_*`**
- **2026-06-08** — **IV-1 ☑ archived wontfix** — plug vs incursion contest review closed — **`iv1_plug_incursion_doc_sync_line`** · **`_run_iv1_plug_incursion_review_suite`**
- **2026-06-08** — **IV-12 ☑** — **`FEATURE_IV12_SLOT_DISTRACTION`** surround pad + **`iv12_offense_weight_mult`** — **`_run_iv12_slot_distraction_*`**
- **2026-06-08** — **IV-13 ☑** — **`FEATURE_IV13_WEAPON_REACH_ZOC`** virtual reach at weak front — **`weapon_reach_zoc_bonus_m`** · **`_run_iv13_weapon_reach_zoc_*`**
- **2026-06-08** — **IV-10 ☑** — **`FEATURE_SUBREGION_COMBAT_MULT`** scales post-armor mechanical damage by sub-region — **`_run_iv10_subregion_combat_mult_*`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **IV-9 slice 5** — **`refresh_gap_column_topology`** on swap_rank / fall_back / vacancy reconcile — **`_run_iv9_gap_column_topology_refresh_after_formation_moves`**
- **2026-06-08** — **IV-9 slice 1–4 ☑** — gap-column topology (**`FEATURE_GAP_COLUMN_TOPOLOGY`** default off) — slots/arc/diagram/dual-mode harness + **`_run_iv9_gap_column_*`** — [`#iii-4--engagement-geometry-audit`](LIVE_PATHS.md#iii-4--engagement-geometry-audit)
- **2026-06-08** — **IV-8 ☑** — **`FEATURE_INITIATIVE_ORDER`** staggers combat-start **`EVENT_ACTION_READY`** by **`initiative_score_for_combatant`** (agi+perc, rank, armor burden) — **`_run_iv8_initiative_order_*`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **IV-7 ☑** — **`FEATURE_ARMOR_BURDEN`** scales **`action_ready_cooldown`** + passive parry readiness by equipped armor mass — **`_run_iv7_armor_burden_*`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **III-6 ☑** — depth recheck on wind-up **start/abort** + lane skip — **`_run_windup_start_same_file_depth_recheck`** · **`_run_windup_abort_rank1_same_file_depth_recheck`** — [`#integration-depth-phase-3`](LIVE_PATHS.md#integration-depth-phase-3)
- **2026-06-08** — **III-1 harness** — **`iii1_parry_tie`** syncs **`pending_attack`** + strength so sector tie-break row is order-stable
- **2026-06-08** — **IV-4 ☑** guard matrix — flank path + **`guard_zone_part_for_line`** · **`_run_iv4_guard_matrix_suite`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **MS-L6 ☑** rout mental-stack layer (**`FEATURE_MS_L6_ROUT`**) — cohesion/casualty pressure picks **`flee`** / **`fall_back`** before salience utility; **`_run_mental_stack_rout_*`** — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **IV-5 ☑** arm interpose (**`FEATURE_ARM_INTERPOSE`**) — misaligned guard + attack-side arm on path boosts parry alignment + hit weight; **`_run_iv5_arm_interpose_suite`**; F5 grep **`arm_interpose_arm=`** / **`arm_interpose_boost=`** on parry lines — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-08** — **WF-T2 ☑** form mod/counter/auto-switch soak tune + **`_run_weapon_form_wf_t2_suite`** — duel wall recovery pad **0.12**; counter cap **1.15** locked — [`#wf-footing-improvement-backlog`](LIVE_PATHS.md#wf-footing-improvement-backlog)
- **2026-06-08** — **IV-4 partial** — diagonal guard **`guard_cardinal_for_attack_path`** (flank intercept paths); duel **counter_read** before **duel_read**; inferred **ox** → **fool** — superseded by **IV-4 ☑** guard matrix closeout — [`#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks)
- **2026-06-06** — Footing pass 3: **WF-M5** harness alias policy; ii5c **`form_wrath_diagram`**; octant wind-up harness — [`#wf-footing-improvement-backlog`](LIVE_PATHS.md#wf-footing-improvement-backlog)
- **2026-06-08** — **Exp-3 ☑** — XCamp-3.1–3.8 shipped + economy UX maintain (`CompanyState.format_*` · HUD/settlement/party surfaces) · **`CompanyStateChecks` (406 tests)** · harness P2 **`begin_harness_isolated_save`** — [`EXPANSION_PLAN#exp-3`](EXPANSION_PLAN.md#exp-3-company-depth)
- **2026-06-07** — **Camp-5 EA human sign-off** — post–Camp-5 agent entry: Combat default · Expand unfrozen ([§9c](SHIP_PLAN.md#combat-expand-registry)) · separate Expand chat ([`README#expand-reopen`](../scripts/cursor/README.md#expand-reopen)) · Campaign economy UX / **P2** only
