# Combat scripts

Phase 0: `.\scripts\run_all_combat_checks.ps1` (do not pipe stdout to `grep`). Includes **`run_company_state_checks`** (Camp-1.1–1.8) and **Camp-3.4 tail** (Q track + `[ii7]` + `[ii_envelop]` → `CAMPAIGN_SHIP_AUDIT: PASS` in `.phase0_combat_checks.txt`). **F5 human:** [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance) (`dev_soak_encounter` empty); optional **`ii_envelop`** for III-4 wing feel.

## Godot entry

`run_all_combat_checks.gd` — set **`FP_HARNESS_MODE`** (`all` default · `regression` · `d001` · `sanity` · `calibration` · `medical`).

| PowerShell | Bash |
|------------|------|
| `.\scripts\run_all_combat_checks.ps1` | `./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode regression` | `FP_HARNESS_MODE=regression ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode d001` | `FP_HARNESS_MODE=d001 ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode sanity` | `FP_HARNESS_MODE=sanity ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode calibration` | `FP_HARNESS_MODE=calibration ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -HarnessMode medical` | `FP_HARNESS_MODE=medical ./scripts/run_all_combat_checks.sh` |
| `.\scripts\run_all_combat_checks.ps1 -ValidateF5` | `./scripts/run_all_combat_checks.sh --validate-f5` |

Partial modes tee logs under repo root (`.harness_out.txt`, `.d001_soak_out.txt`, `.d001_soak_sanity_out.txt`, `.calibration_audit.txt`, `.medical_phase_harness_out.txt`). Bash also accepts `./scripts/run_all_combat_checks.sh <mode>` as the first argument.

## Other runners

**F5 Output grep (canonical):** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers`](../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers) · `main.tscn` `dev_hit_summary` (default on) · `dev_research_feel` · `dev_soak_encounter`.

| Script | When |
|--------|------|
| `run_d001_presets.ps1` | ii5 / ii6 subset (`$env:D001_PRESETS`) |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt` (smoke: `docs/f5_soak_log.example.txt`) |
| `append_f5_soak_log.ps1` | Merge extra F5 Output into `.f5_soak_in.txt` |
| `run_q_audit.ps1 -Track Q1\|Q2\|Track` | Playtest stream — headless audits (**Q1/Q2** = soak scenario ids) |
| `run_q_feel.ps1 -Track Q1\|Q2\|Camp` | Playtest — F5 checklists (**Camp** = SHIP_PLAN §8 campaign mode) |
| `run_company_state_checks.ps1` | Camp-1 economy loop (also run inside Phase 0) |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 headless standalone; `-TailOnly` / `--tail-only` skips company checks (Phase 0 already ran) |
| `print_phase0_status.ps1` | Summarize `.phase0_*` / `.d001_*` / calibration |
| `check_doc_links.ps1` | Doc link gate (also run inside Phase 0) |

## Internals

- `Invoke-GodotHeadless.ps1` — `GODOT` resolve + headless invoke
- `_godot.sh` — bash equivalent (source only)

Separate Godot `-s` scripts (not `FP_HARNESS_MODE`): `run_d001_presets.gd`, `run_f5_soak_log_validator.gd`, `run_q1_research_feel_audit.gd`, `run_q2_ii2b_feel_audit.gd`, `run_q_track_audits.gd`.

**Invoke rule:** after `Invoke-FallenPathsGodotScript`, use `exit $LASTEXITCODE` (function does not return a code).
