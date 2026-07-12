# Fallen Paths

Godot 4.7 (Forward Plus) — tactical combat + mercenary campaign sim.

- Agents: [`AGENTS.md`](AGENTS.md) · prompts: [`scripts/agent_prompts/README.md`](scripts/agent_prompts/README.md)
- Planning: [`docs/PLANNING.md`](docs/PLANNING.md)
- Combat map (section-only): [`docs/LIVE_PATHS.md#phase-0-gate`](docs/LIVE_PATHS.md#phase-0-gate)
- Campaign ship (section-only): [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](docs/SHIP_PLAN.md#camp-playtest-acceptance)

## Quick start

1. Open this project in Godot 4.7+ (Forward Plus).
2. Run `main.tscn` (set as main scene in `project.godot`).
3. Editor F5 launches the campaign; F5 in `BattleScene` starts tactical combat.

## Running headless tests

Scripts live in `scripts/`. Godot resolve: [`scripts/README.md#godot-entry`](scripts/README.md#godot-entry).

| Script | Purpose |
|--------|---------|
| `run_all_combat_checks.sh` / `.ps1` | Phase 0 gate — expect `PHASE0: PASS` |
| `run_company_state_checks.sh` / `.ps1` | Campaign company state validation |
| `run_q_feel.sh` / `.ps1` | F5 soak feel audit (tracks: Camp, IV, WF) |
| `run_q_audit.ps1` | Q-track soak audit (PowerShell-only) |

```bash
./scripts/run_all_combat_checks.sh
```

CI runs the bash versions on GitHub Actions (`.github/workflows/ci.yml`).

## Code structure

| Folder | Contents |
|--------|----------|
| `combat/` | Tactical combat (production). Tracer: `CombatF5SoakTrace.gd` |
| `harness/` | Regression, D001, F5 validators, calibration (not production resolvers) |
| `core/` | Entity sim: wounds, medical, damage, `CoreEntity` |
| `world/` | Campaign: economy, map, encounters, party setup |
| `ui/` | Battle + company UI (`BattleScene`, `PartyMenu`, `SettlementPanel`) |
| `weapon/`, `armor/`, `species/` | Strike, armor, species data resources |
| `combat_tuning/` | Local tuning UI only — not production combat / not agent streams |
| `scripts/` | Phase 0, audits, agent prompts |
| `docs/` | Planning |

See [`AGENTS.md#code-homes`](AGENTS.md#code-homes).

## Coding standards

- **Lint:** `gdlint res://` (config: `gdlint.toml`)
- **Format:** `gdformat res:// --check` (config: `gdformat.toml`, 120 char lines, 4-space indent)
- **No raw `get_node()` in combat** — use `CombatantEntityAccess` or specialist modules
- **No `print()` outside `CombatDebug`** — use `CombatDebug.combat_session()`, `medical_session()`, `flow_log()`
- **Feature flags:** new cross-cutting features gated behind `FEATURE_*` in `CombatConstantsFeatureFlags.gd`
- **Module headers:** [`AGENTS.md#checklist`](AGENTS.md#checklist)

## File ownership

Canonical table: [`docs/PLANNING.md#file-ownership`](docs/PLANNING.md#file-ownership). Summary: Campaign → `world/*` + company UI; Combat → `combat/*` + `harness/*` + battle UI; Shared → `CampaignEncounterBridge` / `CombatFlow` (one agent).
