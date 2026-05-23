# Planning model

How work is organized in Fallen Paths. **Entry:** [`CURSOR.md`](CURSOR.md) · **Campaign milestones:** [`SHIP_PLAN.md`](SHIP_PLAN.md) · **Combat shipped map:** [`LIVE_PATHS.md`](LIVE_PATHS.md).

---

<a id="three-layers"></a>

## Three layers (read top to bottom)

| Layer | What it is | Examples |
|-------|------------|----------|
| **1. Gate** | Mandatory every session — not a work stream | Phase 0 · `run_all_combat_checks.ps1` · **`PHASE0: PASS`** |
| **2. Work stream** | Per agent (see [parallel](#parallel-agents)) | **Campaign** · **Combat** · **Playtest** · **Expand** |
| **3. Milestone ID** | Actionable row inside a plan | `Camp-1.4` · `D-007` · `IV-2` · harness `ii2b` |

**Do not confuse:** work stream **Playtest** (editor/F5 feel) vs script flag **`-Track Q1`** (one soak scenario). **Expand** (work stream) vs backlog item **`IV-2`** (one integration batch).

---

<a id="work-streams"></a>

## Work streams (session pick)

| Stream | Former label | When | Doc | Code homes |
|--------|--------------|------|-----|------------|
| [**Campaign**](#stream-campaign) | ~~S~~ | Until [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) EA checklist | [`SHIP_PLAN.md`](SHIP_PLAN.md) | `world/*`, `ui/PartyMenu`, `main.gd` |
| [**Combat**](#stream-combat) | ~~M~~ | In parallel with Campaign until Camp-5; default after ship | [`LIVE_PATHS.md`](LIVE_PATHS.md) | `combat/*`, harness; shared files per [ownership](#file-ownership) |
| [**Playtest**](#stream-playtest) | ~~Q~~ | Required before EA ([Camp-3.4](SHIP_PLAN.md#camp-34-playtest-ship-gate)); else when validating feel | [`LIVE_PATHS#phase-0`](LIVE_PATHS.md#phase-0-gate) | F5 + `run_q_feel.ps1` · `run_q_audit.ps1` |
| [**Expand**](#stream-expand) | ~~F3~~ | After Camp-5, or Campaign row needs IV wiring | [`LIVE_PATHS#phase-4`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) | One **IV-\*** + harness row |

### Session rules (single agent)

1. Run **Gate** (Phase 0).
2. One **Camp-\*** row **or** one Combat fix (if not using [parallel](#parallel-agents)).
3. **Playtest** when closing Camp-3.4 or validating UI.
4. **Expand** only when Campaign ship allows (see SHIP_PLAN §6).

---

<a id="parallel-agents"></a>

## Parallel agents (Campaign + Combat)

**Default for ship work:** run **two agents at once** — one **Campaign**, one **Combat** — as long as they stay in [file ownership](#file-ownership) and respect [bridge rules](#bridge-rows-camp-2).

| Agent | Stream | Pick | Gate |
|-------|--------|------|------|
| **A — Campaign** | Campaign | One `Camp-*` row from [`SHIP_PLAN.md`](SHIP_PLAN.md) | Run Phase 0 at start/end of their slice |
| **B — Combat** | Combat | One `LIVE_PATHS` fix, harness row, or `BattleUIUpdater` item | Run Phase 0 at start/end of their slice |

**Not parallel with each other:** **Expand** (touches combat + flags), **bleed retune**, new **`FEATURE_*`**, same-file edits.

### Agent brief (copy into each chat)

**Campaign agent:**

> Stream: **Campaign**. Milestone: `Camp-X.Y` from SHIP_PLAN. Use `CompanyState` [§19 stubs](SHIP_PLAN.md#implementation-stubs) until that row’s [decision gate](SHIP_PLAN.md#decision-gates-at-implementation); read CAMPAIGN_DECISION_GUIDE only when gate blocks merge. Own `world/*`, `main.gd`, `CompanyState`, `SettlementPanel`, `PartyMenu`. Do not edit `combat/*` or harness. Do not change `BleedingConstants`. End with `run_all_combat_checks.ps1`.

**Combat agent:**

> Stream: **Combat**. One maintain item from LIVE_PATHS / Combat backlog ([`CURSOR#stream-combat`](CURSOR.md#stream-combat)). Own `combat/*`, harness tails, `ui/BattleUIUpdater.gd`. Do not edit `world/*`, `main.gd`, or economy. Do not change `BleedingConstants` unless user asked. Camp-3.3 is Combat-led. Bridge rows Camp-2.*: coordinate with Campaign agent first. End with `run_all_combat_checks.ps1`.

<a id="file-ownership"></a>

### File ownership

| Owner | Paths | May read |
|-------|-------|----------|
| **Campaign** | `world/*`, `main.gd`, `PartyManager.gd`, `PartySetup.gd`, `ui/PartyMenu.gd`, `ui/PartyRowFormatter.gd`, `ui/SettlementPanel.gd` (new), `world/PartyMemberSnapshot.gd`, `world/EncounterSpawner.gd`, `world/PlayerCompanionSetup.gd`, `world/SoakEncounterPresets.gd` (contract/tutorial presets only) | `combat/*`, `core/*` (call APIs only) |
| **Combat** | `combat/*`, `combat/CombatRegressionHarness*.gd`, `ui/BattleUIUpdater.gd`, `ui/BattleScene.gd`, `ui/BattleUILayout.gd`, `ui/CombatLogFormatter.gd`, `ui/TurnReadyHandler.gd`, `ui/FormationDiagramBuilder.gd`, `character.gd` (combat hooks only) | `world/*` (read-only unless bridge row) |
| **Combat** (core sim) | `core/EntityMedical.gd`, `core/EntityHealing.gd`, `core/EntityWounds.gd`, `core/BleedingConstants.gd`, `core/CombatResearchAnchors.gd`, `combat/CombatUiHints.gd`, `weapon/*`, `armor/*` | — |
| **Campaign** (scripts) | New `scripts/run_company_*` or harness `_run_company_*` only with Combat review | Do not change `run_all_combat_checks.gd` gate order without sync |
| **Either, one PR** | `character.gd` | Campaign: roster/map hooks · Combat: combat delegate — **not same PR** |

### Shared files (one agent at a time)

| File | Default owner | Other stream |
|------|---------------|--------------|
| `world/CampaignEncounterBridge.gd` | **Campaign** | Combat: read-only, or open PR after Campaign lands |
| `world/CombatFlow.gd` / `world/BattleEndHandler.gd` | **Campaign** (settlement / return-to-map) | Combat: battle-only hooks via existing APIs |
| `ui/BattleScene.gd` | **Combat** | Campaign: do not change battle UI layout during Camp-1 |
| `core/CoreEntity.gd` | **Combat** | Campaign: call public APIs only — signature changes need both agents + Phase 0 |
| `species/*.tres` | **Combat** (calibration) | Campaign: read-only; contract-facing stats via `encounter_config` only |

<a id="bridge-rows-camp-2"></a>

### Bridge rows (Camp-2)

Camp-2 connects sim ↔ map. **Assign each row to one agent per sprint**; the other reviews.

| Row | Lead agent | Why |
|-----|------------|-----|
| Camp-2.1 Map bleed policy | **Campaign** | `main.gd`, `PartyMenu` |
| Camp-2.2 Post-fight snapshot | **Campaign** | `CampaignEncounterBridge`, settlement UI |
| Camp-2.3 Supplies → med efficacy | **Campaign** (calls Combat API) | `CompanyState` + `get_medical_effectiveness()` — Combat implements multiplier in `CoreEntity` if needed |
| Camp-2.4 Campaign afflictions | **Campaign** (data) + **Combat** (apply rules) | Split PRs: affliction dict vs wound application |
| Camp-2.5 Combat stabilize | **Combat** | `CombatMedicalActionListing` |
| Camp-2.6 Fail screens | **Campaign** | `BattleEndHandler` / new UI |

### Playtest (third lane — not a third code agent by default)

| When | Who | Why |
|------|-----|-----|
| **Camp-3.4** / EA sign-off | You (F5) or one **Playtest**-only session | Needs editor + log files; avoid two headless agents fighting over `.f5_soak_in.txt` |
| After parallel week | Run Playtest checklists once both agents merged | [`Camp-3.4`](SHIP_PLAN.md#camp-34-playtest-ship-gate) |

### Merge / gate discipline

1. **Rebase often** — both agents on the same branch; pull before each new row.
2. **Phase 0** — each agent runs `run_all_combat_checks.ps1` after edits; **merge only when both PASS**. If only Campaign touched `world/*`/`main.gd`, Combat still runs full gate before merge.
3. **Artifact conflicts** — do not commit conflicting `.phase0_combat_checks.txt` / `.d001_*` from two machines; regenerate after merge.
4. **One PR per agent** when possible — label PR `campaign:` / `combat:` in title.
5. **Hotspots:** `CampaignEncounterBridge.gd`, `CombatFlow.gd`, `PartyMenu.gd`, `CoreEntity.gd` — Campaign first on bridge files; Combat rebases.

### What runs in parallel (examples)

| Campaign agent | Combat agent (same week) |
|----------------|---------------------------|
| Camp-1.1 Company HUD | `BattleUIUpdater` medical busy poll |
| Camp-1.4 Contracts on tiles | D-001 harness row / parry maintain |
| Camp-1.5 Settlement panel | `CombatUiHints` medical phase hints (Camp-3.3) |
| Camp-3.2 Party triage | Regression harness tail fix |

---

<a id="open-decisions"></a>

## Decision-at-gate index (do not decide upfront)

Each choice is made when the matching **Camp-\*** row is implemented. See [`SHIP_PLAN` §3b gates](SHIP_PLAN.md#decision-gates-at-implementation) · research [`CAMPAIGN_DECISION_GUIDE.md`](CAMPAIGN_DECISION_GUIDE.md) · code stubs [`SHIP_PLAN` §19](SHIP_PLAN.md#implementation-stubs).

| Gate ID | Resolve at Camp row | Guide |
|---------|---------------------|-------|
| **D-day** | 1.2 | [d-day](CAMPAIGN_DECISION_GUIDE.md#d-day) |
| **D-encounter** | 1.4 | [d-encounter](CAMPAIGN_DECISION_GUIDE.md#d-encounter) |
| **D-camp-ui** | 1.6 | [d-camp-ui](CAMPAIGN_DECISION_GUIDE.md#d-camp-ui) |
| **D-casualty** | 1.8 | [d-casualty](CAMPAIGN_DECISION_GUIDE.md#d-casualty) |
| **D-supply-battle** | 2.3 (+ 2.5) | [d-supply-battle](CAMPAIGN_DECISION_GUIDE.md#d-supply-battle) |
| **D-bleed** | 2.1 | [d-bleed](CAMPAIGN_DECISION_GUIDE.md#d-bleed) |
| **D-affliction** | 2.4 | [d-affliction](CAMPAIGN_DECISION_GUIDE.md#d-affliction) |
| **D-bankrupt** | 2.6 | [d-bankrupt](CAMPAIGN_DECISION_GUIDE.md#d-bankrupt) |
| **D-persistence** | 5 (optional) | [d-persistence](CAMPAIGN_DECISION_GUIDE.md#d-persistence) |

**No gate:** Camp-1.1, 1.3 (map), 1.5 UI, 1.7, 3.2, 3.3, 4.x — use §12 tuning only.

---

<a id="milestone-tracking"></a>

## Milestone tracking

- **Campaign:** checkboxes live in [`SHIP_PLAN.md`](SHIP_PLAN.md) (`[ ]` / `[x]` per `Camp-*` row).
- **Combat:** use [`LIVE_PATHS`](LIVE_PATHS.md) + [`CURSOR#stream-combat`](CURSOR.md#stream-combat) backlog; one line in decision log per merged fix.
- **EA ready:** all [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist) must-ship rows checked.

---

<a id="stream-campaign"></a>

### Stream: Campaign

Mercenary **company loop** → EA (Battle Brothers–style wrapper around existing combat).

**Milestone prefix:** `Camp-*` in [`SHIP_PLAN.md`](SHIP_PLAN.md) only.

| Phase | Name | Was |
|-------|------|-----|
| Camp-0 | Gate (parallel Phase 0) | S0 |
| Camp-1 | Economy + contracts | S1 |
| Camp-2 | Sim ↔ map bridge | S2 |
| Camp-3 | Player-ready UX | S3 |
| Camp-4 | Content (V-1–V-3) | S4 |
| Camp-5 | EA ship checklist | S5 |

---

<a id="stream-combat"></a>

### Stream: Combat

**Maintain** shipped tactical/medical systems. Smallest `combat/*.gd` owner per [`LIVE_PATHS`](LIVE_PATHS.md).

**Other labels (not work streams):**

| Label | Meaning |
|-------|---------|
| **D-001…D-008** | Shipped combat/medical feature tracks (done) |
| **Tier 0–6** | Shipped capability areas in LIVE_PATHS |
| **Phase 0** | Headless + D-001 gate (same as **Gate**) |
| **ii2b, ii7, …** | F5 soak scenario IDs (often used in **Playtest**) |

---

<a id="stream-playtest"></a>

### Stream: Playtest

Human **feel** and optional headless audits — not new mechanics.

| Tool | Purpose |
|------|---------|
| `dev_soak_encounter` / cyan tiles | Editor scenarios |
| `run_q_feel.ps1 -Track Q1\|Q2` | Checklist only (no Godot) |
| `run_q_audit.ps1 -Track Q1\|Q2\|Track` | Headless Q audits |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt` |

**Script `Q1` / `Q2`** = soak track names in tooling; work stream name is **Playtest**.

---

<a id="stream-expand"></a>

### Stream: Expand

New combat integration batches **`IV-*`** from POST Phase 4. One **`FEATURE_*`** per PR. **Frozen** during Campaign ship unless a Camp row needs map↔battle wiring.

| Status | IV IDs |
|--------|--------|
| Done | **IV-2** (close-slot spread) |
| Partial | **IV-4** |
| Open | **IV-1,3,5–13** |
| Removed | IV-INTR (**D-008**) |

---

<a id="harness-and-flags"></a>

## Harness, flags, and tuning

| Kind | Rule |
|------|------|
| **Gate** | `.\scripts\run_all_combat_checks.ps1` — do not pipe to `grep` |
| **`FEATURE_*`** | No new flags unless Expand stream + harness |
| **Bleed retune** | Only [`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain) |
| **F1 BMI** | Deferred unless asked |
| **S1–S11 / P3b** | Closed — maintain only |

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
| POST 3–5 as “next” | **Campaign** (Camp-2–4) or **Expand** per SHIP_PLAN §6 |

---

<a id="doc-map"></a>

## Doc map

| Doc | Role |
|-----|------|
| [`PLANNING.md`](PLANNING.md) | This file — glossary · [parallel](PLANNING.md#parallel-agents) · [open decisions](PLANNING.md#open-decisions) |
| [`CURSOR.md`](CURSOR.md) | Agent entry + decision log |
| [`SHIP_PLAN.md`](SHIP_PLAN.md) | Campaign milestones · [§9–18 reference](SHIP_PLAN.md#implementation-reference) |
| [`CAMPAIGN_DECISION_GUIDE.md`](CAMPAIGN_DECISION_GUIDE.md) | Open decision research + recommended defaults |
| [`LIVE_PATHS.md`](LIVE_PATHS.md) | Shipped combat + Phase 0 + IV list |
| [`scripts/README.md`](../scripts/README.md) | Commands |
