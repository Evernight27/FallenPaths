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

1. **Gate** — `.\scripts\run_all_combat_checks.ps1` → **`PHASE0: PASS`**
2. **Pre-start** — [`SHIP_PLAN` §3c](SHIP_PLAN.md#pre-start-checklist) (Camp-1.1 needs **no** product decisions)
3. **Work stream** — see [single agent](#single-agent) or [**parallel Campaign + Combat**](PLANNING.md#parallel-agents) (default for ship)
4. **Product choices** — only at [`SHIP_PLAN` decision gates](SHIP_PLAN.md#decision-gates-at-implementation); read [`CAMPAIGN_DECISION_GUIDE`](CAMPAIGN_DECISION_GUIDE.md) when a gate blocks merge

| Priority | Stream | When |
|:--------:|--------|------|
| 1 | [**Campaign**](PLANNING.md#stream-campaign) | Until [`Camp-5` EA checklist](SHIP_PLAN.md#camp-5-ea-checklist) |
| 1b | [**Combat**](PLANNING.md#stream-combat) | **In parallel** with Campaign ([ownership](PLANNING.md#file-ownership)) |
| 3 | [**Playtest**](PLANNING.md#stream-playtest) | Before EA ([`Camp-3.4`](SHIP_PLAN.md#camp-34-playtest-ship-gate)); else when validating feel |
| 4 | [**Expand**](PLANNING.md#stream-expand) | After Camp-5, or Campaign needs IV wiring — **not** parallel with Campaign+Combat |

<a id="parallel-agents"></a>

## Parallel agents (default for ship)

Run **two agents** at once: **Campaign** (`Camp-*`) + **Combat** (maintain). Full rules: [`PLANNING#parallel-agents`](PLANNING.md#parallel-agents).

| Agent | Milestone / task | Do not touch |
|-------|------------------|--------------|
| Campaign | One `Camp-*` from [`SHIP_PLAN`](SHIP_PLAN.md) | `combat/*`, harness, bleed constants |
| Combat | One item from [Combat stream](#stream-combat) | `world/*`, `main.gd`, economy UI |

Merge when **both** Phase 0 PASS. Camp-2 bridge rows: [lead agent table](PLANNING.md#bridge-rows-camp-2).

<a id="single-agent"></a>

## Single agent

If only one agent: one **Camp-\*** row **or** one Combat fix (not Expand / bleed retune).

**Not next:** new `FEATURE_*` · bleed retune · BMI (**F1**) · closed S1–S11/P3b · audit `note` rows · IV-1,3,5–13 unless [`SHIP_PLAN`](SHIP_PLAN.md) says otherwise.

<a id="every-session"></a>

## Every session

1. Phase 0 gate (above)
2. Lethality drift only via [`LIVE_PATHS` bleeding §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain)

<a id="stream-campaign"></a>

## Campaign stream

Merc company loop → EA. Pick one **`Camp-*`** row from [`SHIP_PLAN.md`](SHIP_PLAN.md) in order; use [`CompanyState` stubs](SHIP_PLAN.md#implementation-stubs) until that row’s gate is resolved.

**Code:** `world/CompanyState.gd` (stubs + economy), `CampaignEncounterBridge.gd`, `EncounterNode.gd`, `CombatFlow.gd`, `PartyMemberSnapshot.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, …

<a id="stream-combat"></a>

## Combat stream

Maintain shipped systems per [`LIVE_PATHS`](LIVE_PATHS.md). Smallest `combat/*.gd` owner.

**Backlog:** `BattleUIUpdater` medical busy · D-001 `pack_wound` preset if wanted · research `warn` only (not `note`).

<a id="stream-playtest"></a>

## Playtest stream

F5 + `run_q_feel.ps1` · `run_q_audit.ps1` (script flags **Q1/Q2** = soak scenarios, not stream names). See [`PLANNING#stream-playtest`](PLANNING.md#stream-playtest).

<a id="stream-expand"></a>

## Expand stream

One **IV-\*** per PR from [`LIVE_PATHS#phase-4`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks). Defer until [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) unless Campaign needs map↔battle.

<a id="decision-log"></a>

## Decision log

- S1–S11/P3b closed · F1 BMI deferred · D-008 · medical winner lock
- **2026-05-22** — [`SHIP_PLAN.md`](SHIP_PLAN.md) merc EA plan
- **2026-05-22** — Planning relabel: ~~S/M/Q/F3~~ → **Campaign / Combat / Playtest / Expand**; milestones **Camp-\*** ([`PLANNING.md`](PLANNING.md))
- **2026-05-22** — **Parallel agents:** Campaign + Combat may run simultaneously ([`PLANNING#parallel-agents`](PLANNING.md#parallel-agents), [`CURSOR#parallel-agents`](#parallel-agents))
- **2026-05-22** — Plan audit: open decisions [`PLANNING#open-decisions`](PLANNING.md#open-decisions); Camp-3.3 Combat-led; Camp-3.4 Playtest lane; ownership expanded
- **2026-05-22** — SHIP_PLAN §9–19: wiring, contracts, stubs, gates-at-implementation, pre-start checklist
- **2026-05-22** — Decisions deferred to Camp-row gates + `CAMPAIGN_DECISION_GUIDE` (not upfront)
