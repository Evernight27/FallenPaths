# Fallen Paths

Godot 4.7 (Forward Plus) — tactical combat + mercenary campaign sim.

- Agents: [`AGENTS.md`](AGENTS.md) · prompts: [`tools/ci/agent_prompts/README.md`](tools/ci/agent_prompts/README.md)
- Planning: [`docs/PLANNING.md`](docs/PLANNING.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · bridge: [`docs/BRIDGE_CONTRACT.md`](docs/BRIDGE_CONTRACT.md)
- Combat map (section-only): [`docs/LIVE_PATHS.md#phase-0-gate`](docs/LIVE_PATHS.md#phase-0-gate)
- Campaign ship (section-only): [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](docs/SHIP_PLAN.md#camp-playtest-acceptance)

## Quick start

1. Open this project in Godot 4.7+ (Forward Plus).
2. F5 runs the **campaign** (`scenes/campaign/main.tscn` — set as main scene in `project.godot`).
3. Optional tuning UI: run with `--tuning` or open `tools/combat_tuning/combat_tuning.tscn` (not the default main scene).

## Running headless tests

Scripts live in `tools/ci/`. Godot resolve: [`tools/ci/README.md#godot-entry`](tools/ci/README.md#godot-entry).

| Script | Purpose |
|--------|---------|
| `run_all_combat_checks.sh` / `.ps1` | Phase 0 gate — expect `PHASE0: PASS` |
| `run_fast_phase0.sh` / `.ps1` | Fast gate — docs + company + regression (CI PRs) |
| `run_company_state_checks.sh` / `.ps1` | Campaign company state validation |
| `run_q_feel.sh` / `.ps1` | F5 soak feel audit (tracks: Camp, IV, WF) |
| `run_q_audit.sh` / `.ps1` | Q-track soak audit |

```bash
./tools/ci/run_all_combat_checks.sh
```

CI (`.github/workflows/ci.yml`):

| Job | When |
|-----|------|
| Doc links | always |
| Shellcheck | always (`tools/ci/*.sh`) |
| GDScript lint | always (`gdlint` + `gdformat --check`) |
| Harness (company + regression) | PRs — unit/regression suite |
| Phase 0 (full harness) | `main`/`master` push + `workflow_dispatch` |

Local lint: `./tools/ci/ci_lint.sh` (needs `shellcheck` + `pip install -r requirements-ci.txt`).

## Code structure

| Folder | Contents |
|--------|----------|
| `scenes/` | Campaign / actors / battle entry scenes |
| `assets/` | Tiles, branding |
| `resources/` | Weapons, armor, species data |
| `combat/` | Tactical hubs + packages ([`combat/README.md`](combat/README.md)) |
| `world/` | Campaign systems + bridge |
| `core/` | Entity sim facade + `Entity*` |
| `ui/battle/` `ui/company/` | Battle + company UI scripts |
| `harness/` | Regression / D001 / F5 validators |
| `tools/ci/` | Phase 0, audits, agent prompts |
| `tools/combat_tuning/` | Local tuning only — not production |
| `addons/` | Reserved for third-party plugins |
| `docs/` | Planning · architecture · bridge |

See [`AGENTS.md#code-homes`](AGENTS.md#code-homes) · [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Coding standards

- **Lint:** `gdlint .` — `.gdlintrc` holds overrides only
- **Format:** `gdformat --check .`
- **Shell:** `shellcheck --rcfile=tools/ci/.shellcheckrc -x tools/ci/*.sh`
- **One-shot:** `./tools/ci/ci_lint.sh`
- **No raw `get_node()` in combat** — use `CombatantEntityAccess`
- **No `print()` outside `CombatDebug`**
- **Feature flags:** `FEATURE_*` in `CombatConstantsFeatureFlags.gd`
- **Autoloads:** none for combat/campaign — see ARCHITECTURE

## File ownership

Canonical table: [`docs/PLANNING.md#file-ownership`](docs/PLANNING.md#file-ownership).
