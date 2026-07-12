# Fallen Paths

[`docs/PLANNING.md`](docs/PLANNING.md) · [`docs/AGENTS_ENTRY.md`](docs/AGENTS_ENTRY.md) · [`docs/AGENTS_API.md`](docs/AGENTS_API.md) · [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md)

**Prompts:** [`scripts/agent_prompts/README.md`](scripts/agent_prompts/README.md) · **Budget:** ≤1 doc section + ≤3 owning `.gd` before first edit.

<a id="code-homes"></a>

## Code homes

Flat folders by name prefix. Production: `combat/`. Regression/soak: `harness/` (not production resolvers). Keep `CombatF5SoakTrace.gd` in `combat/` (production tracer).

| Path | Contents |
|------|----------|
| `combat/` | Tactical combat (production) |
| `harness/` | Regression, D001, F5 validators, calibration |
| `core/` | Entity sim |
| `world/` | Campaign |
| `ui/` | Battle + company UI |
| `weapon/`, `armor/`, `species/` | Data |
| Root | `main.gd`, `main.tscn`, `character.gd`, `PartyManager.gd` |
| `scripts/` | Phase 0 / audits · [`agent_prompts/`](scripts/agent_prompts/README.md) |
| `docs/` | Planning |

Playtest artifacts (gitignored): `.f5_soak_in.txt`, `.phase0_combat_checks.txt`, `.d001_*` — one agent at a time ([`scripts/README.md`](scripts/README.md)).

## Implementing

1. [Ownership](docs/PLANNING.md#file-ownership) · [anti-patterns](docs/AGENTS_API.md#anti-patterns)
2. New cross-cutting API → row in [`AGENTS_API`](docs/AGENTS_API.md#canonical-apis)

## Streams

Index + gates: [`scripts/agent_prompts/README.md`](scripts/agent_prompts/README.md).

| Stream | Prompt | Gate |
|--------|--------|------|
| **Maintain** | [`agent_maintain.md`](scripts/agent_prompts/agent_maintain.md) | `PHASE0: PASS` |
| **Combat** | [`agent_combat.md`](scripts/agent_prompts/agent_combat.md) | `PHASE0: PASS` |
| **Enhance** | [`agent_enhance.md`](scripts/agent_prompts/agent_enhance.md) | `PHASE0: PASS` |
| **Playtest** | [`agent_playtest.md`](scripts/agent_prompts/agent_playtest.md) | one agent on `.f5_soak_in.txt` |
| **Campaign** | [`agent_campaign.md`](scripts/agent_prompts/agent_campaign.md) | company **406** or Phase 0 + ship audit |
| **Hygiene · Audit** | [`agent_hygiene.md`](scripts/agent_prompts/agent_hygiene.md) · [`agent_audit.md`](scripts/agent_prompts/agent_audit.md) | Hygiene: no production `.gd` |
| **Medical** | [`agent_medical.md`](scripts/agent_prompts/agent_medical.md) | `PHASE0: PASS` |

## Anti-patterns (short)

| Do not | Do instead |
|--------|------------|
| `manager._get_by_id` | `CombatantEntityAccess` |
| Raw `"pack_wound"` / `in MEDICAL_MOVE_IDS` | `CombatConstants.is_*` / `MOVE_ID_*` |
| Inline gate literals | `CompanyState.read_stub_*` |
| `print("[Combat]")` outside `CombatDebug` | `CombatDebug.combat_session` |
| Conflate WF / `guard_line` / doctrine / PA | [`LIVE_PATHS#wf-footing-guards-stances`](docs/LIVE_PATHS.md#wf-footing-guards-stances) |
| New `FEATURE_*` without ask | [§9c](docs/SHIP_PLAN.md#combat-expand-registry) |

Full: [`AGENTS_API#anti-patterns`](docs/AGENTS_API.md#anti-patterns) · flags: [`PLANNING#harness-and-flags`](docs/PLANNING.md#harness-and-flags) · preserve: [`FEATURE_PRESERVATION`](docs/FEATURE_PRESERVATION.md)

## Checklist

- [ ] Owner in [PLANNING](docs/PLANNING.md#file-ownership)? Smallest module?
- [ ] Cross-cutting API → [`AGENTS_API`](docs/AGENTS_API.md#canonical-apis)?

```gdscript
## <One line: what this file owns.>
## Canonical: <API or docs/AGENTS_API.md>.
```

## Ownership

Full: [`PLANNING#file-ownership`](docs/PLANNING.md#file-ownership)

| Stream | Paths |
|--------|-------|
| **Campaign** | `world/*`, `main.gd`, party/settlement/HUD UI, `CompanyState.gd` |
| **Combat** | `combat/*`, `harness/*`, battle UI formatters |
| **Shared** | `CampaignEncounterBridge.gd`, `CombatFlow.gd` (one agent) |
