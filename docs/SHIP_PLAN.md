# Ship plan — merc company loop (EA)

**Section-only.**

Entry: [`AGENTS_ENTRY`](AGENTS_ENTRY.md) · gates: [`CAMPAIGN_DECISION_GUIDE`](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) · combat: [`LIVE_PATHS`](LIVE_PATHS.md) (section-only) · Expand queue: [`EXPANSION_PLAN`](EXPANSION_PLAN.md).

<a id="target-definition"></a>

## 1. Target

EA: playable merc loop (contracts → fight → settlement → wages) with Phase 0 green. Deferred: large map, P2 save, bleed retune, new `FEATURE_*` without ask.

<a id="current-state"></a>

## 2. Current state

Camp-0…5 **shipped** (human F5 ☑ 2026-06-07).

<a id="dependency-overview"></a>

## 3. Dependencies

Shipped dependency order complete — Camp-0 gate first, then company loop.

<a id="decision-gates-at-implementation"></a>

## 3b. Decision gates

Closed 2026-05-22 → [`CAMPAIGN_DECISION_GUIDE#user-bundle-2026-05-22`](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) · consts [#implementation-stubs](#implementation-stubs).

<a id="pre-start-checklist"></a>

## 3c. Pre-start checklist

Shipped.

<a id="camp-1-build-order"></a>

## 3d. Camp-1 build order

Shipped.

<a id="camp-0-release-gate"></a>

## Camp-0 — Release gate

```bash
./scripts/run_all_combat_checks.sh
```
Expect **`PHASE0: PASS`**. Always-on.

<a id="camp-1-company-loop"></a>

## Camp-1 — Company loop

☑ Shipped. Shipped.

<a id="camp-2-sim-campaign-bridge"></a>

## Camp-2 — Sim ↔ campaign

☑ Shipped. Shipped.

<a id="camp-3-player-ready"></a>

## Camp-3 — Player-ready UX

☑ Shipped. Playtest gate → [#camp-34-playtest-ship-gate](#camp-34-playtest-ship-gate).

<a id="camp-34-playtest-ship-gate"></a>

## Camp-3.4 — Playtest ship gate

Headless ship audit + [#camp-playtest-acceptance](#camp-playtest-acceptance) F5.

<a id="camp-4-content"></a>

## Camp-4 — Content

☑ Shipped contract presets. Shipped.

<a id="camp-5-ea-checklist"></a>

## Camp-5 — EA checklist

**EA ☑ 2026-06-07** — Phase 0 + `CAMPAIGN_SHIP_AUDIT` + F5 `human_signoff: READY`. Gates: [user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22).

| Must | Gate |
|------|------|
| Phase 0 | `./scripts/run_all_combat_checks.sh` → `PHASE0: PASS` |
| Company loop | `CompanyStateChecks` 406 |
| F5 §8 | [#camp-playtest-acceptance](#camp-playtest-acceptance) |
| Mental stack / WF / III-4 Track A | Phase 0 harness + Live Paths |

**Defer:** [§9c](#combat-expand-registry) · P2 save · bleed/BMI without ask.

<a id="work-streams-during-campaign"></a>

## 6. Work streams (post–Camp-5)

| Pri | Stream | Default |
|:---:|--------|---------|
| 1 | Combat | Phase 0 maintain |
| 2 | Expand | One [§9c](#combat-expand-registry) row |
| 3 | Playtest | F5 / validator on demand |
| 4 | Campaign | Economy UX · optional P2 |

Prompts: [`agent_prompts/README`](../scripts/agent_prompts/README.md).

<a id="camp-7-session-order"></a>

## 7. Session order

Historical greenfield weeks — shipped; use [#camp-playtest-acceptance](#camp-playtest-acceptance).

<a id="camp-playtest-acceptance"></a>

## 8. Playtest acceptance

```bash
./scripts/run_campaign_ship_audit.sh
./scripts/run_q_feel.sh Camp   # or: run_q_feel.ps1 -Track Camp
./scripts/validate_f5_soak_log.sh
./scripts/run_camp_f5_closeout.sh --human-signoff
```

F5: `dev_soak_encounter` empty. Paste Output → `.f5_soak_in.txt`. Smoke: `docs/f5_soak_log.camp_wf.example.txt`.

| Step | Check |
|-----:|-------|
| 1–3 | Start → contract → win → `settlement_continue` |
| 4–5 | Bleed warn / field care · camp rest / End day |
| 6–7 | Day tick wages · renown |
| 8–9 | Paid loss run-end · wage/desertion |
| 10–11 | Party triage · medical phase Stack hints |
| 12 | WF-M3: `Step` → `Grd`/`Atk` → `Form` — [`LIVE_PATHS#wf-m3-f5-playtest`](LIVE_PATHS.md#wf-m3-f5-playtest) |
| 13 | Optional `ii_envelop` / mop-up `engagement_debug` |

Close-out: automated minimum = Phase 0 + ship audit + `wf_m3_*` + camp settlement/day markers. Human sign-off needs steps 4, 8–10 on paste.

<a id="implementation-reference"></a>

## 9. Implementation reference

Boot/overworld/battle-end: `main.gd` · `CombatFlow` · `CampaignEncounterBridge`. Cognition: [`LIVE_PATHS#combat-cognition-pipeline`](LIVE_PATHS.md#combat-cognition-pipeline).

<a id="combat-mental-stack-shipped"></a>

### §9b — Mental stack (shipped)

Canonical: [`LIVE_PATHS#tier-43-mental-stack--combat-attention`](LIVE_PATHS.md#tier-43-mental-stack--combat-attention).

**Lock:** no player per-target picker. `CombatAIActionPicker.pick` → `MentalStackDecider` L0→L5 → `pick_weighted`.

| Layer | Stamp |
|-------|-------|
| L0–L1 | `self_medical` / `medical` |
| L2–L3 | `counter` / `incoming` |
| L4 | `hold_line` (+ close / rotate exits) |
| L5 | `exhaustion` (MS-L7) |

Campaign: read-only. Expand layers: [§9c](#combat-expand-registry).

<a id="combat-expand-registry"></a>

### §9c — Expand registry

Canonical status tables: [`LIVE_PATHS#phase-4--new-systems-formal-tracks`](LIVE_PATHS.md#phase-4--new-systems-formal-tracks) · open queue: [`EXPANSION_PLAN`](EXPANSION_PLAN.md).

**Rule:** one §9c row per Expand PR + harness + optional `FEATURE_*`. No bleed/BMI / closed IV reopen without ask. WF-1…4 + MS-L5–L7 + most IV **shipped** — maintain.

<a id="data-contracts"></a>

## 10. Data contracts

`encounter_config` keys via bridge / `CompanyState` — see [`AGENTS_API`](AGENTS_API.md).

<a id="encounter-lifecycle"></a>

## 11. Encounter lifecycle

**R3 shipped:** marker consumed on entry; paid loss ends run — [D-encounter](CAMPAIGN_DECISION_GUIDE.md#d-encounter).

<a id="ea-tuning-defaults"></a>

## 12. EA tuning

Economy defaults in `CompanyState.init_from_defaults()` — [guide §12](CAMPAIGN_DECISION_GUIDE.md#ea-tuning).

<a id="persistence-scope"></a>

## 13. Persistence

**P1** EA (session-only). **P2** post-ship — [D-persistence](CAMPAIGN_DECISION_GUIDE.md#d-persistence).

<a id="roster-casualties"></a>

## 14. Roster / casualties

**K3** memorial + kill recap — [D-casualty](CAMPAIGN_DECISION_GUIDE.md#d-casualty).

<a id="dev-vs-campaign-mode"></a>

## 15. Dev vs campaign

Normal play: `dev_soak_encounter` empty. Cyan presets = F5 soak only.

<a id="battle-supply-consumption"></a>

## 17. Battle supply

**E3** hybrid — [D-supply-battle](CAMPAIGN_DECISION_GUIDE.md#d-supply-battle).

<a id="camp-4-config-examples"></a>

## 18. Camp-4 config

Shipped contract presets.

## 19. Gate constants (`CompanyState.gd`)


<a id="implementation-stubs"></a>

<a id="implementation-gate-constants"></a>

Single source for closed gates. Summary: [user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22).

```gdscript
const DAY_TICK_MODE := "hybrid"
const STEPS_PER_DAY := 5
const ENCOUNTER_LIFECYCLE := "r3_loss_ends_run"
const CAMP_HEAL_ENTRY := "both"
const CAMP_HEAL_SECONDS := 600.0
const CAMP_HEAL_MULTIPLIER := 3.0
const CASUALTY_ON_SETTLEMENT := "memorial_then_remove"
const MAP_BLEED_POLICY := "warn_eta"
const MED_BATTLE_MODE := "hybrid"
const SUPPLY_FACTOR_AT_ZERO_MED := 0.5
const AFFLICTIONS_ENABLED := true
const BANKRUPT_MODE := "desertion"
const PERSISTENCE_MODE := "P1"
```

Branch via `read_stub_*()`. New gates: const + reader + [decision log](#decision-log) line.

<a id="implementation-pitfalls"></a>

## 20. Pitfalls (campaign)

| Pitfall | Mitigation |
|---------|------------|
| Expect marker retry after paid loss | R3 consumes marker; run ends |
| Wages on same hook as 60s bleed | Separate day tick from map minute |
| Parallel edits on bridge / `CompanyState` | One owner; Campaign leads |
| Bleed retune for easier campaign | Tutorial/encounter mult — not `BleedingConstants` |
| Player target UI | Forbidden — [§9b](#combat-mental-stack-shipped) |
| Confuse WF / PA / formation footing | [`LIVE_PATHS#wf-layer-labels`](LIVE_PATHS.md#wf-layer-labels) |

Combat/WF pitfalls → [`LIVE_PATHS`](LIVE_PATHS.md).

<a id="campaign"></a>

## Campaign stream note

Economy UX / optional P2 — [`agent_campaign.md`](../scripts/agent_prompts/agent_campaign.md).

<a id="decision-log"></a>

## Decision log

Closed D-* gates: [user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22) + [#implementation-stubs](#implementation-stubs). Append one line per **new** gate only.

```markdown
- YYYY-MM-DD — D-* (Camp-x.y) → choice — rationale
```

Closed D-* lines are in the 2026-05-22 user bundle; append new gates only.

<a id="external-comparables-index"></a>

## External comparables

Do not block ship on full tissue sim.

<a id="camp-33-battle-medical-phase-hints-combat-led"></a>

See [#camp-3-player-ready](#camp-3-player-ready).
