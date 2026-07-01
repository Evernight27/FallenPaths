# Fallen Paths

Godot 4.7 (Forward Plus) — tactical combat + mercenary campaign sim.

- Planning & architecture: [`docs/PLANNING.md`](docs/PLANNING.md)
- Agent prompts: [`scripts/agent_prompts/README.md`](scripts/agent_prompts/README.md)
- Shipped combat map: [`docs/LIVE_PATHS.md`](docs/LIVE_PATHS.md)
- Campaign ship plan: [`docs/SHIP_PLAN.md`](docs/SHIP_PLAN.md)

## Quick start

1. Open this project in Godot 4.7+ (Forward Plus).
2. Run `main.tscn` (set as main scene in `project.godot`).
3. Editor F5 launches the campaign; F5 in `BattleScene` starts tactical combat.

## Running headless tests

Scripts live in `scripts/`:

| Script | Purpose |
|--------|---------|
| `run_all_combat_checks.ps1` / `.sh` | Phase 0 gate — headless combat regression suite |
| `run_company_state_checks.sh` | Campaign company state validation |
| `run_q_feel.ps1` | F5 soak feel audit (tracks: Camp, IV, WF) |
| `run_q_audit.ps1` | Q-track soak audit |

CI runs the bash versions on GitHub Actions (`.github/workflows/ci.yml`).

## Code structure

| Folder | Contents |
|--------|----------|
| `combat/` | Tactical combat (~120 scripts, flat). Harness files: `CombatRegressionHarness*.gd`, `CombatD001*`, `CombatF5Soak*` |
| `core/` | Entity sim: wounds, medical, damage, `CoreEntity` |
| `world/` | Campaign: economy, map, encounters, party setup |
| `ui/` | Battle + company UI (`BattleScene`, `PartyMenu`, `SettlementPanel`) |
| `weapon/`, `armor/`, `species/` | Strike, armor, species data resources |
| `scripts/` | Phase 0 harness, Q audits, campaign ship audit, agent prompts |
| `docs/` | Planning, live paths, ship plan |

See [`AGENTS.md#code-homes`](AGENTS.md#code-homes) for the full folder map.

## Coding standards

- **Lint:** `gdlint res://` (config: `gdlint.toml`)
- **Format:** `gdformat res:// --check` (config: `gdformat.toml`, 120 char lines, 4-space indent)
- **No raw `get_node()` in combat** — use `CombatantEntityAccess` or specialist modules
- **No `print()` outside `CombatDebug`** — use `CombatDebug.combat_session()`, `medical_session()`, `flow_log()`
- **Feature flags:** new cross-cutting features gated behind `FEATURE_*` consts in `CombatConstantsFeatureFlags.gd`
- **Module headers:** follow the template in [`AGENTS.md#module-header-template`](AGENTS.md#module-header-template)

## File ownership (summary)

| Stream | Primary paths |
|--------|----------------|
| **Campaign** | `world/*`, `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd` |
| **Combat** | `combat/*`, `ui/BattleUIUpdater.gd`, battle formatters in `ui/` |
| **Shared** | `world/CampaignEncounterBridge.gd`, `world/CombatFlow.gd` (one agent at a time) |

Full ownership table: [`docs/PLANNING.md#file-ownership`](docs/PLANNING.md#file-ownership).
