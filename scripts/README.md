# Combat scripts

Phase 0: `.\scripts\run_all_combat_checks.ps1` (do not pipe stdout to `grep`). **F5 paste:** human `.f5_soak_in.txt` is auto-backed up to `.f5_soak_in.f5_backup.txt` during D001 capture and restored after Phase 0; backup is not downgraded when the live paste lacks `camp5_step9` append. **`append_f5_soak_log.ps1 -Label camp5_*`** updates the backup on success. Includes **`run_company_state_checks`** (Camp-1.1–1.8) and **Camp-3.4 tail** (Q track + `[ii7]` + `[ii_envelop]` + **`ii_envelop_mopup: PASS`** under `[ii_envelop]` → `CAMPAIGN_SHIP_AUDIT: PASS` in `.phase0_combat_checks.txt`). Regression tail includes **`CombatRegressionHarnessWeaponFormTail`** (18 rows) + **`AttentionFootworkTail`** **`_run_footwork_*`** — footing spec: [`#wf-footing-improvement-backlog`](../docs/LIVE_PATHS.md#wf-footing-improvement-backlog) · [`#wf-footing-doc-map`](../docs/LIVE_PATHS.md#wf-footing-doc-map) · Tier 4.4 PA hub [`#wf-tier-44-pa`](../docs/LIVE_PATHS.md#wf-tier-44-pa) · UI compose [`#battle-ui`](../docs/LIVE_PATHS.md#battle-ui) · soak **ii5c/ii8** [`#wf-soak-audit-status`](../docs/LIVE_PATHS.md#wf-soak-audit-status) (incl. **`form_wrath_*`** rows). **F5 on demand (Camp-5 ☑):** [`docs/SHIP_PLAN.md#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance) (`dev_soak_encounter` empty); **WF-M3** suffix spot-check; **3e mop-up:** `mop_up=true` + `strikes>0` / `menu=strikes_listed` on combat-phase `engagement_debug turn` (optional **`ii_envelop`** cyan preset).

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

Partial modes tee logs under repo root (`.harness_out.txt`, `.d001_soak_out.txt`, `.d001_soak_sanity_out.txt`, `.calibration_audit.txt`, `.medical_phase_harness_out.txt`). Audit lane scratch: `.audit_*.txt`. Full pattern list: repo-root `.gitignore` (mirror `.cursorignore`). Bash also accepts `./scripts/run_all_combat_checks.sh <mode>` as the first argument.

## Other runners

**Bash:** every `*.ps1` gate runner above has a `*.sh` twin (same flags where applicable); `run_q_audit.ps1` is PowerShell-only.

**Parallel Cursor chats (post–Camp-5 default):** [`cursor/README.md`](cursor/README.md) — expansion bundle [`#parallel-expansion-bundle`](cursor/README.md#parallel-expansion-bundle) · medical quality [`#parallel-medical-quality-bundle`](cursor/README.md#parallel-medical-quality-bundle).

**F5 Output grep (canonical):** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers`](../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers) · `main.tscn` `dev_hit_summary` (default on) · `dev_research_feel` · `dev_soak_encounter`.

| Script | When |
|--------|------|
| `run_camp_f5_closeout.ps1` / `.sh` | Validate F5 log + Camp-5 status summary; **exit 0** on automated minimum (headless + **wf_m3** + **camp_section_8**); **`-HumanSignOff`** / **`--human-signoff`** blocks on docs example smoke |
| `preflight_f5_followup.ps1` / `.sh` | Grep chunk before append; **`-Step9Only`** / **`--step9-only`** for tutorial soft loss + wage + desertion only |
| `restore_f5_soak_log.ps1` / `.sh` | Restore `.f5_soak_in.f5_backup.txt` after Phase 0 clobber + re-validate |
| `append_f5_soak_log.ps1` / `.sh` | Merge chunk into `.f5_soak_in.txt` then **`validate_f5_soak_log`** — **`-Label camp5_*`** auto-runs preflight; **`-Preflight`** / **`--preflight`** explicit |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt` (or **`-LogPath`**); **`-Quiet`** for wrappers (do not pipe script to `Out-Null` on Windows). Normalizes Windows CRLF before grep; **WF-M3** + **Camp** + optional **`camp_*`** — smoke: **`docs/f5_soak_log.camp_wf.example.txt`** · **`docs/f5_soak_log.camp_full.example.txt`** · per-step: **`docs/camp_optional_step_smokes/`** · step-9 append: **`docs/f5_soak_log.camp_step9_optional.example.txt`** |
| `validate_camp_optional_smokes.ps1` / `.sh` | Playtest — headless **`camp_*`** regression on all **`docs/camp_optional_step_smokes/*.txt`**; restores **`.f5_soak_in.txt`** validation when present; prints **`EXP_0_2_OPTIONAL: PASS`** when human paste has steps 4, 8 paid, 9, 10 |
| `run_exp0_playtest_gate.ps1` / `.sh` | **Exp-0.2** — optional smokes + **`-HumanSignOff`** closeout (prereq: Phase 0 green); **`--skip-closeout`** smokes only |
| `run_q_audit.ps1 -Track Q1\|Q2\|Track` | Playtest stream — headless audits (**Q1/Q2** = soak scenario ids) |
| `run_q_track_audits.gd` (via `run_q_audit.ps1`) | Q4 **ii8** proxies D-001 (`formation_mode`, `turn_ready_gauge`, `tooltip_match_ok`, `diagram_banner`, **`form_*`** suffix content) — see [#wf-soak-audit-status](../docs/LIVE_PATHS.md#wf-soak-audit-status) |
| `run_q_feel.ps1` / `run_q_feel.sh` `-Track Camp` / `Camp` | Playtest — F5 checklists (**Camp** = SHIP_PLAN §8 step 12 **WF-M3** + `.f5_soak_in.txt` scan + **`validate_f5_soak_log`**) |
| `run_company_state_checks.ps1` / `.sh` | Camp-1 economy loop (**406** headless tests incl. XCamp-3.x + P2 persistence + isolated harness save slot; fails on any `SCRIPT_ERROR`; exit = stdout `FP_HARNESS_OK: CompanyStateChecks`). Harness uses `CampaignPersistence.begin_harness_isolated_save()` — safe alongside open Godot editor. |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 headless standalone; `-TailOnly` / `--tail-only` skips company checks (Phase 0 already ran) |
| `print_phase0_status.ps1` / `.sh` | Summarize `.phase0_*` / `.d001_*` / calibration + Camp-5 headless vs human F5 status |
| `check_doc_links.ps1` | Doc link + tombstone gate + `res://` path audit (also run inside Phase 0) |

## Internals

- `Invoke-GodotHeadless.ps1` — `GODOT` resolve + headless invoke
- `_godot.sh` — bash equivalent (source only)
- `check_doc_links.ps1` / `.sh` / `.py` — doc link + tombstone + `res://` path gate
- `F5SoakLogHelpers.ps1` / `f5_soak_log_helpers.sh` — shared F5 log path, backup, CRLF decode (dot-source from Phase 0 / validator / append / restore runners)

Godot `-s` entry points: **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE`: `all` · `regression` · `d001` · `sanity` · `calibration` · `medical` · **`f5_validate`** via `validate_f5_soak_log.ps1` / `.sh`) · **`run_company_state_checks.gd`** · **`run_q_track_audits.gd`** (Q1/Q2 sections via `run_q_audit.ps1`; Q4 ii8 D-001 proxy — extend **ii5c/ii8** per [#wf-soak-audit-status](../docs/LIVE_PATHS.md#wf-soak-audit-status)).

**Invoke rule:** after `Invoke-FallenPathsGodotScript`, prefer `exit (Get-FallenPathsGodotExitCode)` or grep `FP_HARNESS_OK` in captured stdout — Godot `-s` exit codes are unreliable on Windows. **`run_company_state_checks`** always greps harness OK.
