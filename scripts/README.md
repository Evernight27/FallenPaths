# Combat scripts

Phase 0 (bash-first):

```bash
./scripts/run_all_combat_checks.sh
```

Expect **`PHASE0: PASS`**. Do not pipe stdout to `grep`. Windows: `.\scripts\run_all_combat_checks.ps1`.

Harness: `res://harness/…` (not `combat/`). Production tracer: `combat/CombatF5SoakTrace.gd`.

**F5 paste:** human `.f5_soak_in.txt` backed up to `.f5_soak_in.f5_backup.txt` during D001 and restored after Phase 0. Phase 0 also runs company-state checks + Camp-3.4 ship audit → `CAMPAIGN_SHIP_AUDIT: PASS`. F5 on demand: [`SHIP_PLAN#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance). Footing/WF soak: [`LIVE_PATHS#wf-soak-audit-status`](../docs/LIVE_PATHS.md#wf-soak-audit-status).

<a id="godot-entry"></a>

## Godot entry

Godot **4.x stable** headless. Override with `$GODOT` / `$env:GODOT`.

| Platform | Default (`scripts/_godot.sh` / `Invoke-GodotHeadless.ps1`) |
|----------|------------------------------------------------------------|
| **Linux** | PATH → Steam Godot → Flathub (`godot_via_flatpak.sh`) |
| **Windows** | `E:\Godot_v4.7-stable_win64.exe` |
| **macOS** | `/Applications/Godot.app/Contents/MacOS/Godot` |

`run_all_combat_checks.gd` — **`FP_HARNESS_MODE`**: `all` (default) · `regression` · `d001` · `sanity` · `calibration` · `medical`.

| Bash | PowerShell |
|------|------------|
| `./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1` |
| `FP_HARNESS_MODE=regression ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode regression` |
| `./scripts/run_all_combat_checks.sh --validate-f5` | `.\scripts\run_all_combat_checks.ps1 -ValidateF5` |

Partial modes tee under repo root (`.harness_out.txt`, `.d001_*`, `.calibration_audit.txt`, …). Bash also accepts `./scripts/run_all_combat_checks.sh <mode>`.

## Other runners

**Bash twins** for most gates. **PowerShell-only:** `run_q_audit.ps1`. **Fast Phase 0:** `run_fast_phase0.sh` / `.ps1` (`--full` / **-Full**; **-D001Light** PS1-only). Prompts: [`agent_prompts/README.md`](agent_prompts/README.md).

**F5 Output grep:** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`LIVE_PATHS#f5-combat-diagnostic-tiers`](../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers).

| Script | When |
|--------|------|
| `run_playtest.sh` / `.ps1` | **Playtest dispatcher** (no Phase 0): `status` · `merge` · `revalidate` · `recover` · `after-append` · `full` · `exp0` · `rebuild` |
| `run_camp_f5_closeout.ps1` / `.sh` | F5 + Camp-5 status; **`-HumanSignOff`** blocks on docs example smoke |
| `preflight_f5_followup.ps1` / `.sh` | Grep chunk before append |
| `restore_f5_soak_log.ps1` / `.sh` | Restore `.f5_soak_in.f5_backup.txt` after Phase 0 clobber |
| `append_f5_soak_log.ps1` / `.sh` | Merge chunk into `.f5_soak_in.txt` then validate |
| `validate_f5_soak_log.ps1` / `.sh` | Parse paste (or **`-LogPath`**); **`-Quiet`** for wrappers |
| `validate_camp_optional_smokes.ps1` / `.sh` | Headless `camp_*` smokes; **`EXP_0_2_OPTIONAL: PASS`** when human paste has steps 4/8/9/10 |
| `run_q_audit.ps1` / `run_q_feel.ps1` / `.sh` | Playtest audits / F5 checklists (`-Track Camp`) |
| `run_company_state_checks.ps1` / `.sh` | Camp-1 economy (**406** tests); exit = `FP_HARNESS_OK: CompanyStateChecks` |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 standalone; `-TailOnly` skips company checks |
| `print_phase0_status.ps1` / `.sh` | Summarize Phase 0 / D001 / Camp-5 status |
| `check_doc_links.ps1` / `.sh` | Doc link + tombstone + `res://` audit |
| `run_fast_phase0.sh` / `.ps1` | Fast Phase 0 — doc links + company state + regression; `--full` / **-Full** = full Phase 0; **-D001Light** = PS1 only. CI PRs use the bash twin. |
| `ci_lint.sh` | Shellcheck + gdlint + gdformat --check (matches CI lint jobs) |

## Internals

- `_lib.sh` — bash bootstrap (`_godot.sh` + `f5_soak_log_helpers.sh`)
- `run_playtest.sh` / `.ps1` — playtest subcommand dispatcher
- `Invoke-GodotHeadless.ps1` / `_godot.sh` — Godot resolve
- `F5SoakLogHelpers.ps1` / `f5_soak_log_helpers.sh` — F5 backup, validate, gap merge, preflight
- `check_doc_links.py` — single implementation (`.sh` / `.ps1` wrappers)
- `ci_ensure_godot.sh` — CI Godot download
- `ci_lint.sh` / `requirements-ci.txt` — shellcheck + gdtoolkit (`gdlint` / `gdformat`)
- `scripts/.shellcheckrc` — `shellcheck --rcfile=scripts/.shellcheckrc -x scripts/*.sh`
- `.gdlintrc` / `.gdformatrc` — gdtoolkit configs (YAML; not `*.toml`)

Godot `-s`: `run_all_combat_checks.gd` · `run_company_state_checks.gd` · `run_q_track_audits.gd`. Prefer grep `FP_HARNESS_OK` over Godot exit codes on Windows.
