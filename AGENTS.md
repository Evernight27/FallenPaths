# Fallen Paths

[`docs/PLANNING.md`](docs/PLANNING.md) · [`docs/AGENTS_ENTRY.md`](docs/AGENTS_ENTRY.md) · [`docs/AGENTS_API.md`](docs/AGENTS_API.md) · [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md) · [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/BRIDGE_CONTRACT.md`](docs/BRIDGE_CONTRACT.md)

**Prompts:** [`tools/ci/agent_prompts/README.md`](tools/ci/agent_prompts/README.md) · **Budget:** ≤1 production code path (doc section) — research/realism docs exempt (code-motion splits exempt — one module/pass) · **Contract:** [`README#session-contract`](tools/ci/agent_prompts/README.md#session-contract)

<a id="code-homes"></a>

## Code homes

Godot presentation layer uses role folders (`scenes/`, `assets/`, `resources/`). Domain streams stay purpose-named. F5 soak tracer: `combat/soak/`.

| Path | Contents |
|------|----------|
| `scenes/` | Campaign main, actors, battle packed scenes |
| `assets/` | Tiles, branding |
| `resources/` | Weapons, armor, species |
| `combat/` | Tactical hubs + packages — [`combat/README.md`](combat/README.md) |
| `harness/` | Regression / D001 / calibration |
| `core/` | Entity sim facade `CoreEntity` + `Entity*` |
| `world/` | Campaign; bridge: [`docs/BRIDGE_CONTRACT.md`](docs/BRIDGE_CONTRACT.md) |
| `ui/battle/` `ui/company/` | Battle + company UI scripts |
| `tools/ci/` | Phase 0 / audits / agent prompts |
| `tools/combat_tuning/` | Tuning UI only (not an agent stream) |
| `addons/` | Third-party plugins (reserved) |
| `docs/` | Planning · architecture · bridge |

Playtest artifacts (gitignored): `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*` — one agent at a time ([`tools/ci/README.md`](tools/ci/README.md)).

<a id="checklist"></a>

## Implementing

1. [Ownership](docs/PLANNING.md#file-ownership) · [anti-patterns](docs/AGENTS_API.md#anti-patterns) · [preserve](docs/FEATURE_PRESERVATION.md) · [architecture](docs/ARCHITECTURE.md)
2. Cross-cutting API → [`AGENTS_API`](docs/AGENTS_API.md#canonical-apis)

Streams + gates: [`tools/ci/agent_prompts/README.md`](tools/ci/agent_prompts/README.md).

## Anti-patterns (short)

| Do not | Do instead |
|--------|------------|
| `manager._get_by_id` | `CombatantEntityAccess` |
| Raw `"pack_wound"` / `in MEDICAL_MOVE_IDS` | `CombatConstants.is_*` / `MOVE_ID_*` |
| Inline gate literals | `CompanyState.read_stub_*` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` |
| Conflate WF / `guard_line` / doctrine / PA | [`LIVE_PATHS#wf-footing-guards-stances`](docs/LIVE_PATHS.md#wf-footing-guards-stances) |
| New `FEATURE_*` without ask | [§9c](docs/SHIP_PLAN.md#combat-expand-registry) |
| Autoload CombatManager / CompanyState | Scene ownership + `class_name` ([ARCHITECTURE](docs/ARCHITECTURE.md)) |
| Production preload of `tools/combat_tuning/` | Keep tooling quarantined |

Full: [`AGENTS_API#anti-patterns`](docs/AGENTS_API.md#anti-patterns) · ownership: [`PLANNING#file-ownership`](docs/PLANNING.md#file-ownership) · flags: [`PLANNING#harness-and-flags`](docs/PLANNING.md#harness-and-flags).
