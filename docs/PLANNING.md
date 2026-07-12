# Planning model

**Entry:** [`AGENTS_ENTRY`](AGENTS_ENTRY.md) · **Prompts:** [`agent_prompts/README`](../scripts/agent_prompts/README.md) · **Camp:** [`SHIP_PLAN#camp-playtest-acceptance`](SHIP_PLAN.md#camp-playtest-acceptance) · **Expand queue:** [`EXPANSION_PLAN`](EXPANSION_PLAN.md) · **Combat map (section-only):** [`LIVE_PATHS#phase-0-gate`](LIVE_PATHS.md#phase-0-gate).

<a id="three-layers"></a>

## Three layers

| Layer | What | Examples |
|-------|------|----------|
| **1. Gate** | Every session | `./scripts/run_all_combat_checks.sh` → `PHASE0: PASS` |
| **2. Stream** | Per agent | Combat · Expand · Playtest · Campaign |
| **3. Milestone** | One row | `Camp-1.4` · `IV-2` · harness `ii2b` |

Playtest stream ≠ script `-Track Q1`. Expand stream ≠ backlog id `IV-2`.

<a id="work-streams"></a>

## Work streams

| Stream | When | Homes |
|--------|------|-------|
| [Combat](#stream-combat) | Default maintain | `combat/*`, `harness/*` |
| [Expand](#stream-expand) | User reopens §9c | One FEATURE/row + harness |
| [Playtest](#stream-playtest) | F5 / validator | `.f5_soak_in.txt` exclusive |
| [Campaign](#stream-campaign) | Economy UX / P2 | `world/*`, company UI |

Session: Gate → one Combat fix → optional Expand/Playtest → Campaign on demand.

<a id="parallel-agents"></a>

## Parallel agents

Default: Combat + optional Expand or Playtest. Not parallel: two Expand · same-file · bleed retune. Prompts: [`agent_prompts/README`](../scripts/agent_prompts/README.md).

| Agent | Stream | Gate |
|-------|--------|------|
| A | Combat | Phase 0 |
| B | Expand (optional) | Phase 0 |
| C | Playtest (optional) | F5 validator |
| D | Campaign (on demand) | Company 406 or Phase 0 |

<a id="file-ownership"></a>

### File ownership

| Owner | Paths |
|-------|-------|
| **Campaign** | `world/*`, `main.gd`, `PartyManager.gd`, party/settlement/HUD UI |
| **Combat** | `combat/*`, `harness/*`, battle UI formatters, `character.gd` (combat hooks) |
| **Combat (WF / PA)** | `CombatWeaponForm`, `CombatFootwork`, `CombatGuardLines`, related UI — maintain only |
| **Combat (core sim)** | `core/EntityMedical|Wounds|Healing`, `BleedingConstants`, `weapon/*`, `armor/*` |

Shared (one agent): `CampaignEncounterBridge`, `CombatFlow` / `BattleEndHandler`, `CoreEntity` signatures, `species/*.tres`.

<a id="bridge-rows-camp-2"></a>

Camp-2 bridge ☑ — Campaign leads map↔sim; Combat on stabilize listing. Merge: rebase · Phase 0 · PR prefixes `campaign:` / `combat:`.

<a id="open-decisions"></a>
<a id="closed-gates"></a>

## Closed gates

[User bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) · [§19](SHIP_PLAN.md#implementation-stubs). Optional [P2](CAMPAIGN_DECISION_GUIDE.md#d-persistence).

<a id="milestone-tracking"></a>

Combat/Expand: [`LIVE_PATHS`](LIVE_PATHS.md) · [§9b](SHIP_PLAN.md#combat-mental-stack-shipped) · [§9c](SHIP_PLAN.md#combat-expand-registry). EA: [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist). Open: [`EXPANSION_PLAN`](EXPANSION_PLAN.md).

<a id="stream-combat"></a>

**Combat:** [`agent_combat.md`](../scripts/agent_prompts/agent_combat.md) · [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline). No player target picker.

<a id="stream-expand"></a>

**Expand:** one §9c row — [`README#expand-reopen`](../scripts/agent_prompts/README.md#expand-reopen).

<a id="stream-playtest"></a>

**Playtest:** [`agent_playtest.md`](../scripts/agent_prompts/agent_playtest.md) · [`scripts/README`](../scripts/README.md).

<a id="stream-campaign"></a>

**Campaign:** [`agent_campaign.md`](../scripts/agent_prompts/agent_campaign.md).

<a id="harness-and-flags"></a>

## Harness / flags / tuning

| Kind | Rule |
|------|------|
| Gate | `./scripts/run_all_combat_checks.sh` — do not pipe to `grep` |
| `FEATURE_*` | Expand only + harness |
| Bleed retune | [`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain) only |
| S1–S11 / P3b / BMI | Shipped / deferred unless asked |

<a id="legacy-labels"></a>

| Old | Use |
|-----|-----|
| Track S / M / Q / F3 | Campaign / Combat / Playtest / Expand |
| S0–S5 | Camp-0–Camp-5 |

<a id="doc-map"></a>

[`AGENTS_ENTRY`](AGENTS_ENTRY.md) · [`AGENTS_API`](AGENTS_API.md) · [`SHIP_PLAN`](SHIP_PLAN.md) · [`CAMPAIGN_DECISION_GUIDE`](CAMPAIGN_DECISION_GUIDE.md) · [`LIVE_PATHS`](LIVE_PATHS.md) (section-only) · [`EXPANSION_PLAN`](EXPANSION_PLAN.md) · [`COMPOSURE_PLAN`](COMPOSURE_PLAN.md) · [`FEATURE_PRESERVATION`](FEATURE_PRESERVATION.md) · [`archive/`](archive/README.md) · [`scripts/README`](../scripts/README.md) · [`agent_prompts`](../scripts/agent_prompts/README.md).
