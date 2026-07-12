# Planning model

How work is organized in Fallen Paths. **Entry:** [`AGENTS_ENTRY.md`](AGENTS_ENTRY.md) · **Agent prompts:** [`scripts/agent_prompts/README.md`](../scripts/agent_prompts/README.md) · **Campaign (Camp-5 ☑):** [`SHIP_PLAN.md#camp-playtest-acceptance`](SHIP_PLAN.md#camp-playtest-acceptance) · **Post-EA roadmap:** [`EXPANSION_PLAN.md`](EXPANSION_PLAN.md) · **Combat shipped map (section-only):** [`LIVE_PATHS.md#phase-0-gate`](LIVE_PATHS.md#phase-0-gate).

---

<a id="three-layers"></a>

## Three layers (read top to bottom)

| Layer | What it is | Examples |
|-------|------------|----------|
| **1. Gate** | Mandatory every session — not a work stream | Phase 0 · `./scripts/run_all_combat_checks.sh` · **`PHASE0: PASS`** |
| **2. Work stream** | Per agent (see [parallel](#parallel-agents)) — priority order | **Combat** · **Expand** · **Playtest** · **Campaign** |
| **3. Milestone ID** | Actionable row inside a plan | `Camp-1.4` · `D-007` · `IV-2` · harness `ii2b` |

**Do not confuse:** work stream **Playtest** (editor/F5 feel) vs script flag **`-Track Q1`** (one soak scenario). **Expand** (work stream) vs backlog item **`IV-2`** (one integration batch).

---

<a id="work-streams"></a>

## Work streams (session pick)

| Stream | Former label | When | Doc | Code homes |
|--------|--------------|------|-----|------------|
| [**Combat**](#stream-combat) | ~~M~~ | **Default** post–Camp-5 — LIVE_PATHS maintain | [`LIVE_PATHS.md`](LIVE_PATHS.md) · [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) | `combat/*`, harness; shared files per [ownership](#file-ownership) |
| [**Expand**](#stream-expand) | ~~F3~~ | Optional second chat — unfrozen per [§9c](SHIP_PLAN.md#combat-expand-registry) | [`LIVE_PATHS#phase-4`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) · [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry) | One **III-*** / **IV-*** / **P4** / **MS-L5+** row + harness |
| [**Playtest**](#stream-playtest) | ~~Q~~ | On demand when validating feel | [`LIVE_PATHS#phase-0`](LIVE_PATHS.md#phase-0-gate) | F5 + `run_q_feel.ps1` · `run_q_audit.ps1` |
| [**Campaign**](#stream-campaign) | ~~S~~ | Economy UX or explicit **P2** save only (post–Camp-5 ☑ 2026-06-07) | [`SHIP_PLAN.md`](SHIP_PLAN.md) | `world/*`, `ui/PartyMenu`, `main.gd` |

### Session rules (single agent)

1. Run **Gate** (Phase 0).
2. One **Combat** maintain fix (if not using [parallel](#parallel-agents)).
3. Optional **Expand** via [`scripts/agent_prompts/README.md#expand-reopen`](../scripts/agent_prompts/README.md#expand-reopen) *(user must reopen §9c)*.
4. **Playtest** on demand — F5 append, validator, Q audits.
5. **Campaign** only for economy UX bugs or explicit **P2** save.

---

<a id="parallel-agents"></a>

## Parallel agents (post–Camp-5)

**Default:** **Combat** chat + optional second chat (**Expand** or **Playtest**); **Campaign** only for economy UX or **P2** save. Prompts: [`scripts/agent_prompts/README.md`](../scripts/agent_prompts/README.md). Stay in [file ownership](#file-ownership) and [bridge rules](#bridge-rows-camp-2).

| Agent | Stream | Pick | Prompt | Gate |
|-------|--------|------|--------|------|
| **A** | Combat | One LIVE_PATHS maintain / harness fix | [`agent_combat.md`](../scripts/agent_prompts/agent_combat.md) | Phase 0 at start/end |
| **B** *(optional)* | Expand | One [§9c](SHIP_PLAN.md#combat-expand-registry) row | [`README#expand-reopen`](../scripts/agent_prompts/README.md#expand-reopen) | Phase 0 at start/end |
| **C** *(optional)* | Playtest | F5 append / `run_q_feel.ps1` — on demand | [`agent_playtest.md`](../scripts/agent_prompts/agent_playtest.md) | Headless in Phase 0 |
| **D** *(on demand)* | Campaign | Economy UX · optional **P2** save | [`agent_campaign.md`](../scripts/agent_prompts/agent_campaign.md) | Phase 0 or company checks |

**Not parallel:** two **Expand** agents · bleed retune · same-file edits. (Combat maintain + one Expand PR is OK when files do not overlap.)

**WF maintain (shipped):** WF-1a–1c + WF-2/3/4 + soak tail — [`#wf-implementation-status`](LIVE_PATHS.md#wf-implementation-status). No new WF tiers without user ask.

<a id="file-ownership"></a>

### File ownership

| Owner | Paths | May read |
|-------|-------|----------|
| **Campaign** | `world/CompanyState.gd`, `world/ContractSpawner.gd`, `world/MapBleedPolicy.gd`, `world/MapFieldCare.gd`, `world/*`, `main.gd`, `PartyManager.gd`, `PartySetup.gd`, `ui/PartyMenu.gd`, `ui/PartyRowFormatter.gd`, `ui/SettlementPanel.gd`, `ui/CompanyRunEndPanel.gd`, `ui/CompanyHud.gd`, `world/PartyMemberSnapshot.gd`, `world/EncounterSpawner.gd`, `PlayerCompanionSetup.gd`, `SoakEncounterPresets.gd` (contract rows only) | `combat/*`, `core/*` (APIs only) |
| **Combat** | `combat/*`, `harness/*` (regression/soak), `ui/BattleUIUpdater.gd`, `ui/BattleScene.gd`, `ui/BattleUILayout.gd`, `ui/CombatLogFormatter.gd`, `ui/TurnReadyHandler.gd`, `ui/FormationDiagramBuilder.gd`, `character.gd` (combat hooks only) | `world/*` (read-only unless bridge row) |
| **Combat** (Expand WF) | `combat/CombatWeaponForm.gd`, `harness/CombatRegressionHarnessWeaponFormTail.gd`, `weapon/WeaponConstants.gd`, `combat/CombatUiHints.gd`, `ui/BattleUIUpdater.gd`, `ui/FormationDiagramBuilder.gd` — **WF-1…4 shipped** — maintain per [#wf-footing-improvement-backlog](LIVE_PATHS.md#wf-footing-improvement-backlog) | One maintain row per PR |
| **Combat** (Tier 4.4 PA maintain) | `combat/CombatFootwork.gd`, `combat/CombatGuardLines.gd`, `combat/GuardLineUpdater.gd`, `combat/DefenseChoiceResolver.gd` — hub [`#wf-tier-44-pa`](LIVE_PATHS.md#wf-tier-44-pa) · octant lookup **shipped** [`#wf-form-guard-pa-matrix`](LIVE_PATHS.md#wf-form-guard-pa-matrix) | **`AttentionFootworkTail._run_footwork_*`** (under `harness/`) |
| **Combat** (core sim) | `core/EntityMedical.gd`, `core/EntityHealing.gd`, `core/EntityWounds.gd`, `core/BleedingConstants.gd`, `core/CombatResearchAnchors.gd`, `combat/CombatUiHints.gd`, `weapon/*`, `armor/*` | — |
| **Campaign** (scripts) | New `scripts/run_company_*` or harness `_run_company_*` only with Combat review | Do not change `run_all_combat_checks.gd` gate order without sync |
| **Either, one PR** | `character.gd` | Campaign: roster/map hooks · Combat: combat delegate — **not same PR** |

### Shared files (one agent at a time)

| File | Default owner | Other stream |
|------|---------------|--------------|
| `world/CampaignEncounterBridge.gd` | **Campaign** | Combat: read-only, or open PR after Campaign lands |
| `world/CombatFlow.gd` / `world/BattleEndHandler.gd` | **Campaign** (settlement / return-to-map) | Combat: battle-only hooks via existing APIs |
| `ui/BattleScene.gd` | **Combat** | Campaign: avoid battle UI layout changes unless coordinated |
| `core/CoreEntity.gd` | **Combat** | Campaign: call public APIs only — signature changes need both agents + Phase 0 |
| `species/*.tres` | **Combat** (calibration) | Campaign: read-only; contract-facing stats via `encounter_config` only |

<a id="bridge-rows-camp-2"></a>

### Bridge rows (Camp-2) — shipped 2026-05-22

Camp-2 connects sim ↔ map. Table kept for **ownership** when touching bridge files; rows are **done**.

| Row | Lead agent | Why |
|-----|------------|-----|
| Camp-2.1 Map bleed policy | **Campaign** | `main.gd`, `PartyMenu` |
| Camp-2.2 Post-fight snapshot | **Campaign** | `CampaignEncounterBridge`, settlement UI |
| Camp-2.3 Supplies → med efficacy | **Campaign** (calls Combat API) | `CompanyState` + `get_medical_effectiveness()` — Combat implements multiplier in `CoreEntity` if needed |
| Camp-2.4 Campaign afflictions | **Campaign** (data) + **Combat** (apply rules) | Split PRs: affliction dict vs wound application |
| Camp-2.5 Combat stabilize | **Combat** | `CombatMedicalActionListing` |
| Camp-2.6 Fail screens | **Campaign** | `CompanyRunEndPanel` / `CombatFlow` soft defeat |

### Playtest (third lane — not a third code agent by default)

| When | Who | Why |
|------|-----|-----|
| Feel / validator regression | You (F5) or one **Playtest**-only session | Needs editor + log files; avoid two agents fighting over `.f5_soak_in.txt` |
| After parallel week | Run Playtest checklists once both agents merged | [`Camp-3.4`](SHIP_PLAN.md#camp-34-playtest-ship-gate) (headless ☑) |

### Merge / gate discipline

1. **Rebase often** — both agents on the same branch; pull before each new row.
2. **Phase 0** — each agent runs `run_all_combat_checks.ps1` after edits; **merge only when both PASS**. If only Campaign touched `world/*`/`main.gd`, Combat still runs full gate before merge.
3. **Artifact conflicts** — do not commit conflicting `.phase0_combat_checks.txt` / `.d001_*` from two machines; regenerate after merge.
4. **One PR per agent** when possible — label PR `campaign:` / `combat:` in title.
5. **Hotspots:** `CampaignEncounterBridge.gd`, `CombatFlow.gd`, `PartyMenu.gd`, `CoreEntity.gd` — Campaign first on bridge files; Combat rebases.

### What runs in parallel (examples — historical)

| Campaign agent (was) | Combat agent (same week) |
|----------------|---------------------------|
| Camp-1.1 Company HUD | Phase 0 + [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) `_run_mental_stack_*` green |
| Camp-1.4 Contracts on tiles | D-001 harness row / parry maintain (preserve pick order) |
| Camp-1.5 Settlement panel | Phase 0 + mental-stack maintain (Camp-3.3 shipped) |
| Camp-3.2 Party triage | Phase 0 maintain; mental-stack regression if pick path touched |
| **Camp-5 ☑ (2026-06-07)** — economy UX only | Phase 0 maintain + optional Expand |

---

<a id="open-decisions"></a>
<a id="closed-gates"></a>

## Closed gate index (2026-05-22)

Campaign **D-*** gates are **closed** in [`CompanyState`](world/CompanyState.gd) ([§19](SHIP_PLAN.md#implementation-stubs)). **Canonical summary:** [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22). Per-gate research: [guide appendix](CAMPAIGN_DECISION_GUIDE.md#gate-research-appendix). **Optional post–Camp-5:** [**D-persistence P2**](CAMPAIGN_DECISION_GUIDE.md#d-persistence) save only if explicitly asked.

| Gate ID | Camp row | Shipped | Guide |
|---------|----------|---------|-------|
| **D-day** | 1.2 | T3 | [d-day](CAMPAIGN_DECISION_GUIDE.md#d-day) |
| **D-encounter** | 1.4 | R3 | [d-encounter](CAMPAIGN_DECISION_GUIDE.md#d-encounter) |
| **D-camp-ui** | 1.6 | H3 | [d-camp-ui](CAMPAIGN_DECISION_GUIDE.md#d-camp-ui) |
| **D-casualty** | 1.8 | K3 | [d-casualty](CAMPAIGN_DECISION_GUIDE.md#d-casualty) |
| **D-bleed** | 2.1 | B + tutorial block | [d-bleed](CAMPAIGN_DECISION_GUIDE.md#d-bleed) |
| **D-supply-battle** | 2.3 (+ 2.5) | E3 | [d-supply-battle](CAMPAIGN_DECISION_GUIDE.md#d-supply-battle) |
| **D-affliction** | 2.4 | Tier RNG | [d-affliction](CAMPAIGN_DECISION_GUIDE.md#d-affliction) |
| **D-bankrupt** | 2.6 | B3 | [d-bankrupt](CAMPAIGN_DECISION_GUIDE.md#d-bankrupt) |
| **D-persistence** | 5 | P1 EA | [d-persistence](CAMPAIGN_DECISION_GUIDE.md#d-persistence) |

**No gate:** Camp-1.1, 1.3 (map), 1.5 UI, 1.7, 3.2, 3.3, 4.x — use §12 tuning only.

**Build order:** [`SHIP_PLAN` §3d](SHIP_PLAN.md#camp-1-build-order) · **pitfalls:** [§20](SHIP_PLAN.md#implementation-pitfalls).

---

<a id="milestone-tracking"></a>

## Milestone tracking

- **Combat:** [`LIVE_PATHS`](LIVE_PATHS.md) + [`PLANNING#stream-combat`](#stream-combat) backlog; [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) mental-stack baseline; one decision-log line per merged fix.
- **Expand:** one [§9c](SHIP_PLAN.md#combat-expand-registry) row per PR; track in decision log when shipped.
- **EA shipped (2026-06-07):** [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) ☑ — Campaign checkboxes in [`SHIP_PLAN.md`](SHIP_PLAN.md) are maintain-only reference.
- **Post-EA phases:** [`EXPANSION_PLAN.md`](EXPANSION_PLAN.md) — **Exp-0…5**, **`XCamp-*`**, combat queue with dependencies.

---

<a id="stream-combat"></a>

### Stream: Combat

Maintain shipped systems — [`agent_combat.md`](../scripts/agent_prompts/agent_combat.md). Cognition: [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline). Labels **D-001…**, **Tier 0–6**, **ii\*** = shipped tracks / soak IDs (not work streams). Player target picker locked.

<a id="stream-expand"></a>

### Stream: Expand

One **`FEATURE_*`** / §9c row per PR on user reopen — [`README#expand-reopen`](../scripts/agent_prompts/README.md#expand-reopen) · buckets: [`LIVE_PATHS` Phase 4](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) · [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry) · open queue [`EXPANSION_PLAN`](EXPANSION_PLAN.md).

<a id="stream-playtest"></a>

### Stream: Playtest

On demand — [`agent_playtest.md`](../scripts/agent_prompts/agent_playtest.md). Tools: `validate_f5_soak_log` · `run_q_feel` / `run_q_audit` · `run_camp_f5_closeout` · `append_f5_soak_log` ([`scripts/README.md`](../scripts/README.md)). Script tracks `Q1`/`Q2` ≠ stream name.

<a id="stream-campaign"></a>

### Stream: Campaign

EA shipped — economy UX maintain; optional **P2** — [`agent_campaign.md`](../scripts/agent_prompts/agent_campaign.md). Milestones `Camp-0…5` in [`SHIP_PLAN`](SHIP_PLAN.md) (was Track S).

---

<a id="harness-and-flags"></a>

## Harness, flags, and tuning

| Kind | Rule |
|------|------|
| **Gate** | `.\scripts\run_all_combat_checks.ps1` — do not pipe to `grep` |
| **`FEATURE_*`** | No new flags unless Expand stream + harness |
| **Bleed retune** | Only [`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain) |
| **F1 BMI** | Deferred unless asked |
| **S1–S11 / P3b** | Shipped — maintain only |

---

<a id="legacy-labels"></a>

## Legacy labels (do not use in new docs)

| Old | Use instead |
|-----|-------------|
| Track **S** | **Campaign** stream · `Camp-*` milestones |
| Track **M** | **Combat** stream |
| Track **Q** | **Playtest** stream (`Q1`/`Q2` OK in scripts) |
| Track **F3** | **Expand** stream |
| **S0–S5** | **Camp-0–Camp-5** |
| POST 3–5 as “next” | **Combat** maintain or **Expand** per [§9c](SHIP_PLAN.md#combat-expand-registry) |

---

<a id="doc-map"></a>

## Doc map

| Doc | Role |
|-----|------|
| [`PLANNING.md`](PLANNING.md) | This file — glossary · parallel · ownership · closed gates |
| [`AGENTS_ENTRY.md`](AGENTS_ENTRY.md) | Agent session entry |
| [`AGENTS_API.md`](AGENTS_API.md) | On-demand APIs / anti-patterns |
| [`SHIP_PLAN.md`](SHIP_PLAN.md) | Camp rows · §9b mental stack · §9c Expand |
| [`CAMPAIGN_DECISION_GUIDE.md`](CAMPAIGN_DECISION_GUIDE.md) | Closed campaign gate bundle |
| [`LIVE_PATHS.md`](LIVE_PATHS.md) | Shipped combat + Phase 0 + IV list |
| [`EXPANSION_PLAN.md`](EXPANSION_PLAN.md) | Post-EA phases |
| [`COMPOSURE_PLAN.md`](COMPOSURE_PLAN.md) | Composure design |
| [`FEATURE_PRESERVATION.md`](FEATURE_PRESERVATION.md) | Deletion / flag-collapse rules |
| [`archive/`](archive/README.md) | Historical plans/audits (not entry) |
| [`scripts/README.md`](../scripts/README.md) | Commands |
| [`scripts/agent_prompts/README.md`](../scripts/agent_prompts/README.md) | Copy-paste prompts |
