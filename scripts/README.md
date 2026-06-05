# Combat scripts

Phase 0: `.\scripts\run_all_combat_checks.ps1` (do not pipe stdout to `grep`). Includes **company state** (Camp-1.1–1.8) and **Camp-3.4 tail** (Q track + `[ii7]` + `[ii_envelop]` → `CAMPAIGN_SHIP_AUDIT: PASS` in `.phase0_combat_checks.txt`). **F5 human:** [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance) (`dev_soak_encounter` empty); optional **`ii_envelop`** for III-4 wing feel.

## Godot entry

**`run_all_combat_checks.gd`** — set **`FP_HARNESS_MODE`**:

| Mode | Purpose |
|------|---------|
| `all` (default) | Phase 0 regression + D-001 + calibration |
| `regression` | CombatRegressionHarness only |
| `d001` | Full D-001 soak runner |
| `d001_presets` | ii5 / ii6 subset only (`D001_PRESETS` env) |
| `sanity` | D-001 soak sanity |
| `calibration` | Calibration audit report |
| `medical` | Medical phase fast harness |
| `f5_validate` | F5 paste log validator (optional path after `--`) |
| `q_track` | Q1–Q4 playtest proxies → `.q_track_audits.txt` |

| PowerShell | Bash |
|------------|------|
| `.\scripts\run_all_combat_checks.ps1` | `./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode regression` | `FP_HARNESS_MODE=regression ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode d001` | `FP_HARNESS_MODE=d001 ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode d001_presets` | `D001_PRESETS=ii5 FP_HARNESS_MODE=d001_presets ./scripts/run_all_combat_checks.sh d001_presets` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode sanity` | `FP_HARNESS_MODE=sanity ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode calibration` | `FP_HARNESS_MODE=calibration ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode medical` | `FP_HARNESS_MODE=medical ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode q_track` | `FP_HARNESS_MODE=q_track ./scripts/run_all_combat_checks.sh q_track` |
| `.\scripts\run_all_combat_checks.ps1 -Status` | (PowerShell artifact summary; no bash equivalent) |
| `.\scripts\run_all_combat_checks.ps1 -ValidateF5` | `./scripts/run_all_combat_checks.sh --validate-f5` |

Partial modes tee logs under repo root (`.harness_out.txt`, `.d001_soak_out.txt`, `.ii5_ii6_soak_out.txt`, `.d001_soak_sanity_out.txt`, `.calibration_audit.txt`, `.medical_phase_harness_out.txt`, `.f5_soak_validation.txt`). Bash also accepts `./scripts/run_all_combat_checks.sh <mode>` as the first argument.

## Other runners

**F5 Output grep (canonical):** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers`](../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers) · `main.tscn` `dev_hit_summary` (default on) · `dev_research_feel` · `dev_soak_encounter`.

| Script | When |
|--------|------|
| `validate_f5_soak_log.ps1` / `.sh` | Parse `.f5_soak_in.txt` (smoke: `docs/f5_soak_log.example.txt`; III-4: `docs/f5_soak_log.ii_envelop.example.txt`); `-AppendFrom` merges multi-fight logs |
| `run_q_feel.ps1 -Headless` | Q track alias for `-HarnessMode q_track` |
| `run_q_feel.ps1 -Track Q1\|Q2\|Camp` | Playtest F5 checklists (**Camp** = SHIP_PLAN §8) |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 headless standalone; `-TailOnly` / `--tail-only` skips company checks |
| `run_all_combat_checks.ps1 -Status` | Summarize `.phase0_*` / `.d001_*` / calibration |
| `check_doc_links.ps1` / `.sh` | Doc link + tombstone gate (both delegate to `check_doc_links.py`; also run inside Phase 0) |
| `validate_res_paths.py` | All `res://` paths in `.gd`/`.tscn`/`.tres` exist (Phase 0; allows runtime `tile_texture.png`, `species/` dir) |

## Internals

- `Invoke-GodotHeadless.ps1` — `GODOT` resolve + headless invoke
- `_godot.sh` — bash equivalent (source only)
- `run_company_state_checks.gd` — Camp-1 harness (invoked from Phase 0 / campaign audit)

**Invoke rule:** after `Invoke-FallenPathsGodotScript`, use `exit $LASTEXITCODE` (function does not return a code).
