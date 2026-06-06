# Combat scripts

Phase 0: `.\scripts\run_all_combat_checks.ps1` (do not pipe stdout to `grep`). Includes **`run_company_state_checks`** (Camp-1.1–1.8) and **Camp-3.4 tail** (Q track + `[ii7]` + `[ii_envelop]` + **`ii_envelop_mopup: PASS`** under `[ii_envelop]` → `CAMPAIGN_SHIP_AUDIT: PASS` in `.phase0_combat_checks.txt`). Regression tail includes **`CombatRegressionHarnessWeaponFormTail`** (18 rows) + **`AttentionFootworkTail`** **`_run_footwork_*`** — footing spec: [`#wf-footing-improvement-backlog`](../docs/LIVE_PATHS.md#wf-footing-improvement-backlog) · [`#wf-footing-doc-map`](../docs/LIVE_PATHS.md#wf-footing-doc-map) · Tier 4.4 PA hub [`#wf-tier-44-pa`](../docs/LIVE_PATHS.md#wf-tier-44-pa) · UI compose [`#battle-ui`](../docs/LIVE_PATHS.md#battle-ui) · soak **ii5c/ii8** [`#wf-soak-audit-status`](../docs/LIVE_PATHS.md#wf-soak-audit-status) (incl. **`form_wrath_*`** rows). **F5 human:** [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance) (`dev_soak_encounter` empty); **WF-M3** suffix spot-check; **3e mop-up:** `mop_up=true` + `strikes>0` / `menu=strikes_listed` on combat-phase `engagement_debug turn` (optional **`ii_envelop`** cyan preset).

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
| `run_camp_f5_closeout.ps1` / `.sh` | Validate F5 log (if present) + EA sign-off summary; **exit 0** when headless + **wf_m3** + **camp_section_8** (`settlement_continue` + `company_day_advanced`) — see [§8 close-out bundle](../docs/SHIP_PLAN.md#camp-playtest-acceptance) for full human rows |
| `append_f5_soak_log.ps1` / `.sh` | Merge chunk into `.f5_soak_in.txt` then **`validate_f5_soak_log`** — tutorial + Escort + loss run → one paste |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt`; **WF-M3** + **Camp** + optional **`camp_*`** (steps 4–9, 3e) — smoke: **`docs/f5_soak_log.camp_wf.example.txt`** or **`docs/f5_soak_log.camp_full.example.txt`** |
| `run_q_audit.ps1 -Track Q1\|Q2\|Track` | Playtest stream — headless audits (**Q1/Q2** = soak scenario ids) |
| `run_q_track_audits.gd` (via `run_q_audit.ps1`) | Q4 **ii8** proxies D-001 (`formation_mode`, `turn_ready_gauge`, `tooltip_match_ok`, `diagram_banner`, **`form_*`** suffix content) — see [#wf-soak-audit-status](../docs/LIVE_PATHS.md#wf-soak-audit-status) |
| `run_q_feel.ps1` / `run_q_feel.sh` `-Track Camp` / `Camp` | Playtest — F5 checklists (**Camp** = SHIP_PLAN §8 step 12 **WF-M3** + `.f5_soak_in.txt` scan + **`validate_f5_soak_log`**) |
| `run_company_state_checks.ps1` / `.sh` | Camp-1 economy loop (**174** headless tests; fails on any `SCRIPT_ERROR`; exit = stdout `FP_HARNESS_OK: CompanyStateChecks`, not Godot exit code alone) |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 headless standalone; `-TailOnly` / `--tail-only` skips company checks (Phase 0 already ran) |
| `print_phase0_status.ps1` / `.sh` | Summarize `.phase0_*` / `.d001_*` / calibration + **EA close-out** headless vs human F5 |
| `check_doc_links.ps1` | Doc link gate (also run inside Phase 0) |

## Internals

- `Invoke-GodotHeadless.ps1` — `GODOT` resolve + headless invoke
- `_godot.sh` — bash equivalent (source only)

Separate Godot `-s` scripts (not `FP_HARNESS_MODE`): `run_d001_presets.gd`, `run_f5_soak_log_validator.gd`, `run_q1_research_feel_audit.gd`, `run_q2_ii2b_feel_audit.gd`, `run_q_track_audits.gd` (Q4 ii8 D-001 proxy — extend **ii5c/ii8** per [#wf-soak-audit-status](../docs/LIVE_PATHS.md#wf-soak-audit-status)).

**Invoke rule:** after `Invoke-FallenPathsGodotScript`, prefer `exit (Get-FallenPathsGodotExitCode)` or grep `FP_HARNESS_OK` in captured stdout — Godot `-s` exit codes are unreliable on Windows. **`run_company_state_checks`** always greps harness OK.
