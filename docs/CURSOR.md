# Cursor entry (Godot 4.x)

**Planning model:** [`PLANNING.md`](PLANNING.md) (work streams + milestone prefixes) · [`SHIP_PLAN.md`](SHIP_PLAN.md) (Campaign milestones) · [`LIVE_PATHS.md`](LIVE_PATHS.md) (shipped combat)

```powershell
.\scripts\run_all_combat_checks.ps1
.\scripts\print_phase0_status.ps1
```

Smallest `combat/*.gd` owner · thin `CombatManager.gd` · `ZoneOfControl.formation_dict_for_zone_geometry` · no harness piping to `grep`.

Flags: [`LIVE_PATHS#production-flags`](LIVE_PATHS.md#production-flags).

<a id="what-to-do-next"></a>

## What to do next

1. **Gate** — `.\scripts\run_all_combat_checks.ps1` → **`PHASE0: PASS`** (includes company checks + **Camp-3.4** Q/`[ii7]` tail → **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`**)
2. **EA close-out** — [`SHIP_PLAN` §8](SHIP_PLAN.md#camp-playtest-acceptance) F5 playtest · [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) · pitfalls [§20](SHIP_PLAN.md#implementation-pitfalls)
3. **Work stream** — see [single agent](#single-agent) or [**parallel agents (EA close-out)**](PLANNING.md#parallel-agents)
4. **Product choices** — closed in [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22); new gates only → guide appendix + [§19](SHIP_PLAN.md#implementation-stubs)

| Priority | Stream | When |
|:--------:|--------|------|
| 1 | [**Campaign**](PLANNING.md#stream-campaign) | [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) + F5 §8 sign-off |
| 1b | [**Combat**](PLANNING.md#stream-combat) | Phase 0 maintain ([ownership](PLANNING.md#file-ownership)) |
| 2 | [**Playtest**](PLANNING.md#stream-playtest) | F5 [§8](SHIP_PLAN.md#camp-playtest-acceptance) before EA ([`Camp-3.4`](SHIP_PLAN.md#camp-34-playtest-ship-gate)) |
| 3 | [**Expand**](PLANNING.md#stream-expand) | After Camp-5 — **not** parallel with close-out work |

<a id="parallel-agents"></a>

## Parallel agents (EA close-out)

Default: **Combat maintain** + **Playtest (F5 §8)**; **Campaign** only for Camp-5 / optional **P2** save. Full rules: [`PLANNING#parallel-agents`](PLANNING.md#parallel-agents).

| Agent | Milestone / task | Do not touch |
|-------|------------------|--------------|
| Campaign | [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) checklist · optional **P2** save | `combat/*`, harness, bleed constants |
| Combat | One item from [Combat stream](#stream-combat) | `world/*`, `main.gd`, economy UI |
| Playtest | F5 [§8](SHIP_PLAN.md#camp-playtest-acceptance) · `run_q_feel.ps1` Q1/Q2 | Two agents writing `.f5_soak_in.txt` |

Merge when **Phase 0 PASS**. Camp-2 bridge rows (shipped): [ownership table](PLANNING.md#bridge-rows-camp-2).

<a id="single-agent"></a>

## Single agent

If only one agent: **F5 §8 sign-off** · one **Combat** fix · optional **P2** save — not Expand / bleed retune.

**Not next:** new `FEATURE_*` · bleed retune · BMI (**F1**) · closed S1–S11/P3b · audit `note` rows · IV-1,3,5–13 unless [`SHIP_PLAN`](SHIP_PLAN.md) says otherwise.

<a id="every-session"></a>

## Every session

1. Phase 0 gate (above)
2. Lethality drift only via [`LIVE_PATHS` bleeding §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain)

<a id="stream-campaign"></a>

## Campaign stream

Merc company loop → EA. **Shipped (2026-05-22):** Camp-1–4 + headless Camp-3.4. **Remaining:** F5 §8 + [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist). Closed gates: [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) · [§19](SHIP_PLAN.md#implementation-stubs).

**Code:** `world/CompanyState.gd`, `ContractSpawner.gd`, `CampaignEncounterBridge.gd`, `MapBleedPolicy.gd`, `MapFieldCare.gd`, `EncounterNode.gd`, `CombatFlow.gd`, `PartyMemberSnapshot.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `ui/CompanyRunEndPanel.gd`, `ui/CompanyHud.gd`, …

<a id="stream-combat"></a>

## Combat stream

Maintain shipped systems per [`LIVE_PATHS`](LIVE_PATHS.md). Smallest `combat/*.gd` owner.

**Before editing pick / attention / defense:** [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline) · shipped stack [`SHIP_PLAN#combat-mental-stack-shipped`](SHIP_PLAN.md#combat-mental-stack-shipped).

**Shipped mental stack (maintain, do not regress):** L0 `self_medical` · L1 `medical` + coordination · L2 `counter` · L3 `incoming` · L4 `hold_line` · L5 `exhaustion` (**MS-L7**) · salience + exhaustion offense damp · **no player targets**. Harness: `_run_mental_stack_*` in `AttentionFootworkTail`.

**Backlog:** Camp-3.3 shipped (medical-phase hints + busy gauge) · D-001 `pack_wound` if wanted · research `warn` only (not `note`). **III-4 Track A ☑** (mapped opposition · L4+close · Skirmish rotate · **`ii_envelop`** headless) — [`LIVE_PATHS#iii-4`](LIVE_PATHS.md#iii-4--engagement-geometry-audit) · F5 **`dev_soak_encounter=ii_envelop`** for manual sign-off. **Expand (post-Camp-5):** MS-L5–L6 · IV-9 gap-column per [SHIP §9c](SHIP_PLAN.md#combat-expand-registry).

<a id="stream-playtest"></a>

## Playtest stream

Headless Camp ship: **`run_all_combat_checks.ps1`** (includes Camp-3.4 tail) or **`run_campaign_ship_audit.ps1`**. F5 + `run_q_feel.ps1` · `run_q_audit.ps1` (flags **Q1/Q2** = soak scenarios). See [`PLANNING#stream-playtest`](PLANNING.md#stream-playtest) · [`SHIP_PLAN` §8](SHIP_PLAN.md#camp-playtest-acceptance).

<a id="stream-expand"></a>

## Expand stream

Pick **one** row from [`LIVE_PATHS#phase-4`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) (III-*, P4a–h, IV-*, MS-L5+) or [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry). Defer until [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) unless Campaign needs map↔battle.

<a id="decision-log"></a>

## Decision log

- S1–S11/P3b closed · F1 BMI deferred · D-008 · medical winner lock
- **2026-05-22** — [`SHIP_PLAN.md`](SHIP_PLAN.md) merc EA plan
- **2026-05-22** — Planning relabel: ~~S/M/Q/F3~~ → **Campaign / Combat / Playtest / Expand**; milestones **Camp-\*** ([`PLANNING.md`](PLANNING.md))
- **2026-05-22** — **Parallel agents:** Campaign + Combat may run simultaneously ([`PLANNING#parallel-agents`](PLANNING.md#parallel-agents), [`CURSOR#parallel-agents`](#parallel-agents))
- **2026-05-22** — Plan audit: closed gates [`PLANNING#closed-gates`](PLANNING.md#closed-gates); Camp-3.3 Combat-led; Camp-3.4 Playtest lane; ownership expanded
- **2026-05-22** — SHIP_PLAN §9–19: wiring, contracts, gate constants, gates-at-implementation, pre-start checklist
- **2026-05-22** — Camp D-* gates closed; canonical choices in [`CAMPAIGN_DECISION_GUIDE` user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22)
- **2026-05-22** — Plan sweep: §3d Camp-1 build order, §20 pitfalls, §17/§18 renumber, EA requires D-bleed closed
- **2026-05-22** — Tier 4.3 mental stack L0–L4 + salience damp integrated into [`SHIP_PLAN` §9b](SHIP_PLAN.md#combat-mental-stack-shipped) + [`LIVE_PATHS` tier 4.3](LIVE_PATHS.md#tier-43-mental-stack--combat-attention); no player target UI
- **2026-05-22** — D-004 MXm-3 + MS-L7: stamina bar decoupled from counter-tempo; effective max/ratio wiring; L5 exhaustion tunnel — [`LIVE_PATHS` D-004](LIVE_PATHS.md#d-004-exhaustion)
- **2026-05-22** — Camp-3.3: one-shot medical-phase combat-log hints + gauge busy tooltips (`CombatUiHints`, `BattleUIUpdater`, harness `_run_medical_phase_*`)
- **2026-05-22** — Full combat Expand registry: [`LIVE_PATHS` phase 4](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) + [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry) (III-*, P4a–h, IV-*, MS-L5+)
