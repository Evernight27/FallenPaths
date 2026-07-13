# Fallen Paths

[`docs/PLANNING.md`](docs/PLANNING.md) · [`docs/AGENTS_ENTRY.md`](docs/AGENTS_ENTRY.md) · [`docs/AGENTS_API.md`](docs/AGENTS_API.md) · [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md)

**Prompts:** [`scripts/agent_prompts/README.md`](scripts/agent_prompts/README.md) · **Budget:** ≤1 doc section + ≤3 owning `.gd` · **Contract:** [`README#session-contract`](scripts/agent_prompts/README.md#session-contract)

<a id="code-homes"></a>

## Code homes

Top-level streams stay in named roots. Within a stream, prefer **purpose-named modules and subdirs** (not `PartA`/`PartB` size splits). Keep `CombatF5SoakTrace.gd` under `combat/` (production tracer).

| Path | Contents |
|------|----------|
| `combat/` | Tactical combat — subdirs: `constants/`, `access/`, `ai/`, `formation/`, `medical/`, `soak/`, `weapon_form/` |
| `harness/` | Regression / D001 / calibration — subdirs: `regression/`, `d001/`, `attention_footwork/`, `feint_tempo/`, `tier1/`, … |
| `core/` | Entity sim — `research/` for literature/benchmark anchors |
| `world/` | Campaign (+ `PartyManager.gd`) |
| `ui/` | Battle + company UI |
| `weapon/`, `armor/`, `species/` | Data |
| Root | `main.gd`, `main.tscn`, `character.gd` |
| `scripts/` | Phase 0 / audits · `company_checks/` · [`agent_prompts/`](scripts/agent_prompts/README.md) |
| `docs/` | Planning |

Playtest artifacts (gitignored): `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*` — one agent at a time ([`scripts/README.md`](scripts/README.md)).

<a id="checklist"></a>

## Implementing

1. [Ownership](docs/PLANNING.md#file-ownership) · [anti-patterns](docs/AGENTS_API.md#anti-patterns) · [preserve](docs/FEATURE_PRESERVATION.md)
2. Cross-cutting API → [`AGENTS_API`](docs/AGENTS_API.md#canonical-apis)

Streams + gates: [`agent_prompts/README.md`](scripts/agent_prompts/README.md).

## Anti-patterns (short)

| Do not | Do instead |
|--------|------------|
| `manager._get_by_id` | `CombatantEntityAccess` |
| Raw `"pack_wound"` / `in MEDICAL_MOVE_IDS` | `CombatConstants.is_*` / `MOVE_ID_*` |
| Inline gate literals | `CompanyState.read_stub_*` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` |
| Conflate WF / `guard_line` / doctrine / PA | [`LIVE_PATHS#wf-footing-guards-stances`](docs/LIVE_PATHS.md#wf-footing-guards-stances) |
| New `FEATURE_*` without ask | [§9c](docs/SHIP_PLAN.md#combat-expand-registry) |

Full: [`AGENTS_API#anti-patterns`](docs/AGENTS_API.md#anti-patterns) · ownership: [`PLANNING#file-ownership`](docs/PLANNING.md#file-ownership) · flags: [`PLANNING#harness-and-flags`](docs/PLANNING.md#harness-and-flags).
