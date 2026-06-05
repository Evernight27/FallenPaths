# Planning model

How work is organized in Fallen Paths. **Cursor/agents:** [`../AGENTS.md`](../AGENTS.md) · [`CURSOR.md`](CURSOR.md) · [`fallen-paths.mdc`](../.cursor/rules/fallen-paths.mdc). **Campaign milestones:** [`SHIP_PLAN.md`](SHIP_PLAN.md) · **Combat shipped map:** [`LIVE_PATHS.md`](LIVE_PATHS.md).

---

<a id="three-layers"></a>

## Three layers (read top to bottom)

| Layer | What it is | Examples |
|-------|------------|----------|
| **1. Gate** | Before shipping code — not a work stream | Phase 0 · `run_all_combat_checks.sh` · **`PHASE0: PASS`** (skip explain-only) |
| **2. Work stream** | Per agent (see [parallel](#parallel-agents)) | **Campaign** · **Combat** · **Playtest** · **Expand** |
| **3. Milestone ID** | Actionable row inside a plan | `Camp-1.4` · `D-007` · `IV-2` · harness `ii2b` |

**Do not confuse:** work stream **Playtest** (editor/F5 feel) vs script flag **`-Track Q1`** (one soak scenario). **Expand** (work stream) vs backlog item **`IV-2`** (one integration batch).

---

<a id="work-streams"></a>

## Work streams (session pick)

| Stream | Former label | When | Doc | Code homes |
|--------|--------------|------|-----|------------|
| [**Campaign**](#stream-campaign) | ~~S~~ | Until [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) EA checklist | [`SHIP_PLAN.md`](SHIP_PLAN.md) | `world/*`, `ui/PartyMenu.gd`, `main.gd`, `PartyManager.gd` |
| [**Combat**](#stream-combat) | ~~M~~ | In parallel with Campaign until Camp-5; default after ship | [`LIVE_PATHS.md`](LIVE_PATHS.md) · [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) | `combat/*`, harness; shared files per [ownership](#file-ownership) |
| [**Playtest**](#stream-playtest) | ~~Q~~ | Required before EA ([Camp-3.4](SHIP_PLAN.md#camp-34-playtest-ship-gate)); else when validating feel | [`LIVE_PATHS#phase-0`](LIVE_PATHS.md#phase-0-gate) | F5 + `run_q_feel.ps1` |
| [**Expand**](#stream-expand) | ~~F3~~ | After Camp-5, or Campaign row needs map↔battle | [`LIVE_PATHS#phase-4`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) · [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry) | One **III-*** / **IV-*** / **P4** / **MS-L5+** row + harness |

### Session rules (single agent)

1. Run **Gate** (Phase 0).
2. **F5 §8 sign-off** · one **Combat** fix (if not using [parallel](#parallel-agents)).
3. **Playtest** when closing Camp-3.4 or validating UI.
4. **Expand** only after [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) (see SHIP_PLAN §6).

---

<a id="parallel-agents"></a>

## Parallel agents (Campaign + Combat)

**Default for ship work:** run **two agents at once** when useful — **Combat maintain** + **Playtest (F5 §8)** for EA close-out; or **Campaign** for Camp-5 checklist sign-off. Stay in [file ownership](#file-ownership) and [bridge rules](#bridge-rows-camp-2).

| Agent | Stream | Pick | Gate |
|-------|--------|------|------|
| **A — Campaign** | Campaign | [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) sign-off · doc polish | Phase 0 at start/end |
| **B — Combat** | Combat | One LIVE_PATHS maintain / harness fix | Phase 0 at start/end |
| **C — Playtest** | Playtest | F5 [§8](SHIP_PLAN.md#camp-playtest-acceptance) + `run_q_feel.ps1` Q1/Q2 | Headless already in Phase 0 |

**Not parallel with each other:** **Expand** (touches combat + flags), **bleed retune**, new **`FEATURE_*`**, same-file edits.

### Agent brief (copy into each chat)

**Campaign agent:**

> Stream: **Campaign**. **EA close-out:** [`Camp-5` checklist](SHIP_PLAN.md#camp-5-ea-checklist) + [`Camp-3.4` F5](SHIP_PLAN.md#camp-34-playtest-ship-gate) (headless in Phase 0). Closed gates: [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) · [§19](SHIP_PLAN.md#implementation-stubs). Own `world/*`, `main.gd`, economy UI. Do not edit `combat/*` or harness. Do not change `BleedingConstants`. End with `run_all_combat_checks.ps1`.

**Combat agent:**

> Stream: **Combat**. One maintain item from LIVE_PATHS / Combat backlog ([`CURSOR#stream-combat`](CURSOR.md#stream-combat)). Read [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline) before touching pick, attention, or defense. Own `combat/*`, harness tails, `ui/BattleUIUpdater.gd`. Do not edit `world/*`, `main.gd`, or economy. Do not change `BleedingConstants` unless user asked. End with `run_all_combat_checks.ps1`.

**Playtest agent:**

> Stream: **Playtest**. F5 [§8](SHIP_PLAN.md#camp-playtest-acceptance) with `dev_soak_encounter` empty · `run_q_feel.ps1 -Track Q1|Q2` · record in [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist). Headless already in Phase 0 (`CAMPAIGN_SHIP_AUDIT: PASS`). Do not run two agents on `.f5_soak_in.txt`.

<a id="file-ownership"></a>

### File ownership

| Owner | Paths | May read |
|-------|-------|----------|
| **Campaign** | `world/*` (incl. `PartySetup.gd`, `PlayerCompanionSetup.gd`, `SoakEncounterPresets.gd` contract rows only), `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/PartyRowFormatter.gd`, `ui/SettlementPanel.gd`, `ui/CompanyRunEndPanel.gd`, `ui/CompanyHud.gd` | `combat/*`, `core/*` (APIs only) |
| **Combat** | `combat/*`, `combat/CombatRegressionHarness*.gd`, `ui/BattleUIUpdater.gd`, `ui/BattleScene.gd`, `ui/BattleUILayout.gd`, `ui/CombatLogFormatter.gd`, `ui/TurnReadyHandler.gd`, `ui/FormationDiagramBuilder.gd`, `character.gd` (combat hooks only) | `world/*` (read-only unless bridge row) |
| **Combat** (core sim) | `core/EntityMedical.gd`, `core/EntityHealing.gd`, `core/EntityWounds.gd`, `core/BleedingConstants.gd`, `core/CombatResearchAnchors.gd`, `combat/CombatUiHints.gd`, `weapon/*`, `armor/*` | — |
| **Campaign** (scripts) | New `scripts/run_company_*` or harness `_run_company_*` only with Combat review | Do not change `run_all_combat_checks.gd` gate order without sync |
| **Either, one PR** | `character.gd` | Campaign: roster/map hooks · Combat: combat delegate — **not same PR** |

### Shared files (one agent at a time)

| File | Default owner | Other stream |
|------|---------------|--------------|
| `world/CampaignEncounterBridge.gd` | **Campaign** | Combat: read-only, or open PR after Campaign lands |
| `world/CombatFlow.gd` / `world/BattleEndHandler.gd` | **Campaign** (settlement / return-to-map) | Combat: battle-only hooks via existing APIs |
| `ui/BattleScene.gd` | **Combat** | Campaign: avoid battle UI layout changes during EA close-out |
| `core/CoreEntity.gd` | **Combat** | Campaign: call public APIs only — signature changes need both agents + Phase 0 |
| `species/*.tres` | **Combat** (calibration) | Campaign: read-only; contract-facing stats via `encounter_config` only |

<a id="bridge-rows-camp-2"></a>

### Bridge rows (Camp-2) — shipped 2026-05-22

Camp-2 connects sim ↔ map. Table kept for **ownership** when touching bridge files; rows are **done**.

| Row | Lead agent | Why |
|-----|------------|-----|
| Camp-2.1 Map bleed policy | **Campaign** | `main.gd`, `ui/PartyMenu.gd` |
| Camp-2.2 Post-fight snapshot | **Campaign** | `CampaignEncounterBridge`, settlement UI |
| Camp-2.3 Supplies → med efficacy | **Campaign** (calls Combat API) | `CompanyState` + `get_medical_effectiveness()` — Combat implements multiplier in `CoreEntity` if needed |
| Camp-2.4 Campaign afflictions | **Campaign** (data) + **Combat** (apply rules) | Split PRs: affliction dict vs wound application |
| Camp-2.5 Combat stabilize | **Combat** | `CombatMedicalActionListing` |
| Camp-2.6 Fail screens | **Campaign** | `CompanyRunEndPanel` / `CombatFlow` soft defeat |

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
5. **Hotspots:** `world/CampaignEncounterBridge.gd`, `world/CombatFlow.gd`, `ui/PartyMenu.gd`, `core/CoreEntity.gd` — Campaign first on bridge files; Combat rebases.

### What runs in parallel (examples — historical)

| Campaign agent (was) | Combat agent (same week) |
|----------------|---------------------------|
| Camp-1.1 Company HUD | Phase 0 + [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) `_run_mental_stack_*` green |
| Camp-1.4 Contracts on tiles | D-001 harness row / parry maintain (preserve pick order) |
| Camp-1.5 Settlement panel | Phase 0 + mental-stack maintain (Camp-3.3 shipped) |
| Camp-3.2 Party triage | Phase 0 maintain; mental-stack regression if pick path touched |
| **EA close-out** (F5 §8 + [`Camp-5`](SHIP_PLAN.md#camp-5-ea-checklist)) | Phase 0 maintain only |

---

<a id="open-decisions"></a>
<a id="closed-gates"></a>

## Closed gate index (2026-05-22)

Campaign **D-*** gates are **closed** in [`CompanyState`](world/CompanyState.gd) ([§19](SHIP_PLAN.md#implementation-stubs)). **Canonical summary:** [guide user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22). Per-gate research: [guide appendix](CAMPAIGN_DECISION_GUIDE.md#gate-research-appendix). **Open for EA:** F5 sign-off only — **P2** autosave shipped.

| Gate ID | Camp row | Shipped | Guide |
|---------|----------|---------|-------|
| **D-day** | 1.2 | T3 | [d-day](CAMPAIGN_DECISION_GUIDE.md#d-day) |
| **D-encounter** | 1.4 | R3 | [d-encounter](CAMPAIGN_DECISION_GUIDE.md#d-encounter) |
| **D-camp-ui** | 1.6 | H3 (+ day tick) | [d-camp-ui](CAMPAIGN_DECISION_GUIDE.md#d-camp-ui) |
| **D-casualty** | 1.8 | K3 | [d-casualty](CAMPAIGN_DECISION_GUIDE.md#d-casualty) |
| **D-bleed** | 2.1 | B + tutorial block | [d-bleed](CAMPAIGN_DECISION_GUIDE.md#d-bleed) |
| **D-supply-battle** | 2.3 (+ 2.5) | E3 | [d-supply-battle](CAMPAIGN_DECISION_GUIDE.md#d-supply-battle) |
| **D-affliction** | 2.4 | Tier RNG | [d-affliction](CAMPAIGN_DECISION_GUIDE.md#d-affliction) |
| **D-bankrupt** | 2.6 | B3 | [d-bankrupt](CAMPAIGN_DECISION_GUIDE.md#d-bankrupt) |
| **D-persistence** | 5 | P2 | [d-persistence](CAMPAIGN_DECISION_GUIDE.md#d-persistence) |

**No gate:** Camp-1.1, 1.3 (map), 1.5 UI, 1.7, 3.2, 3.3, 4.x — use §12 tuning only.

**Build order:** [`SHIP_PLAN` §3d](SHIP_PLAN.md#camp-1-build-order) · **pitfalls:** [§20](SHIP_PLAN.md#implementation-pitfalls).

---

<a id="milestone-tracking"></a>

## Milestone tracking

- **Campaign:** checkboxes live in [`SHIP_PLAN.md`](SHIP_PLAN.md) (`[ ]` / `[x]` per `Camp-*` row).
- **Combat:** use [`LIVE_PATHS`](LIVE_PATHS.md) + [`CURSOR#stream-combat`](CURSOR.md#stream-combat) backlog; [SHIP §9b](SHIP_PLAN.md#combat-mental-stack-shipped) for mental-stack baseline; one line in decision log per merged fix.
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

**Cognition wiring (read before pick / listing / defense edits):** [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline) — tick → list → mental stack → weighted pick; defense at strike time only. Campaign agents must not fork this ([`SHIP_PLAN` §9](SHIP_PLAN.md#implementation-reference)).

**Backlog:** `BattleUIUpdater` medical busy · D-001 `pack_wound` if wanted · research `warn` only (not `note`). **Mental stack:** maintain L0–L4 + MS-L7 L5 + salience damp ([`tier 4.3`](LIVE_PATHS.md#tier-43-mental-stack--combat-attention)); expand MS-L5–L6 after Camp-5. **Engagement geometry:** [**III-4 Track A ☑**](LIVE_PATHS.md#iii-4--engagement-geometry-audit) (headless `[ii_envelop]`; optional F5 wing feel) · **Track B** IV-9 post–Camp-5. **No** player target picker.

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
| `run_q_feel.ps1 -Headless` / `-Track Q1\|Q2\|Camp` | Q track audit or F5 checklists |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt` |

**Script `Q1` / `Q2`** = soak track names in tooling; work stream name is **Playtest**.

---

<a id="stream-expand"></a>

### Stream: Expand

New combat integration batches **`IV-*`** from POST Phase 4. One **`FEATURE_*`** per PR. **Frozen** until [Camp-5](SHIP_PLAN.md#camp-5-ea-checklist) unless a future Camp row needs map↔battle wiring.

| Bucket | IDs | Doc section |
|--------|-----|-------------|
| **Phase 3** (deepen shipped) | III-1…III-8 (partial/active) | [`LIVE_PATHS` Phase 3 table](LIVE_PATHS.md#integration-depth-phase-3) |
| **P4 playbooks** | p4a–p4h | [`LIVE_PATHS` P4 table](LIVE_PATHS.md#p4-playbooks-expansion) |
| **Phase 4 IV** | Done **IV-2** · Partial **IV-4** · Open **IV-1,3,5–13** · Removed **IV-INTR** | [`LIVE_PATHS` IV table](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) |
| **Mental stack** | MS-L5–L6 · tier-4.4 footwork (**MS-L7** shipped — **p4a** tune) | [`SHIP_PLAN` §9b](SHIP_PLAN.md#combat-mental-stack-shipped) |
| **Wontfix** | Player target UI · IV-INTR · P3b mat expand · bleed/BMI unless asked | [`LIVE_PATHS` research table](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) |

**Summary:** [`SHIP_PLAN` §9c](SHIP_PLAN.md#combat-expand-registry).

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
| [`PLANNING.md`](PLANNING.md) | This file — glossary · [parallel](PLANNING.md#parallel-agents) · [closed gate index](PLANNING.md#closed-gates) |
| [`CURSOR.md`](CURSOR.md) | Agent entry + decision log |
| [`SHIP_PLAN.md`](SHIP_PLAN.md) | Camp rows · [§3d build order](SHIP_PLAN.md#camp-1-build-order) · [§9–20 appendices](SHIP_PLAN.md#implementation-reference) |
| [`CAMPAIGN_DECISION_GUIDE.md`](CAMPAIGN_DECISION_GUIDE.md) | Closed gate bundle + research appendix ([user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22)) |
| [`LIVE_PATHS.md`](LIVE_PATHS.md) | Shipped combat + Phase 0 + IV list |
| [`scripts/README.md`](../scripts/README.md) | Commands |
