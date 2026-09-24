# Combat scripts

## Primary

```bash
./tools/ci/run_all_combat_checks.sh
```

Expect **`PHASE0: PASS`**. Do not pipe stdout to `grep`. Windows: `.\tools\ci\run_all_combat_checks.ps1`.

| Script | When |
|--------|------|
| `run_all_combat_checks.sh` / `.ps1` | Full Phase 0 gate |
| `run_fast_phase0.sh` / `.ps1` | Fast gate (docs + company + regression); CI PRs. `--full` / **-Full** = full Phase 0; **-D001Light** PS1-only |
| `run_company_state_checks.sh` / `.ps1` | Camp-1 economy (**558** tests); exit = `FP_HARNESS_OK: CompanyStateChecks` |
| `run_campaign_ship_audit.sh` / `.ps1` | Camp-3.4/5 standalone; `-TailOnly` skips company checks |
| `run_playtest.sh` / `.ps1` | Playtest dispatcher (F5 / Camp closeout) — see below |
| `run_q_feel.sh` / `.ps1` | F5 feel checklist (`Camp` \| `Q1` \| `Q2`) |
| `run_q_audit.sh` / `.ps1` | Headless Q-track audit (`Track` \| `Q1` \| `Q2`) |
| `check_doc_links.py` (+ `.sh` / `.ps1`) | Doc link + tombstone + `res://` + constants-parity audit |
| `ci_lint.sh` | Shellcheck + gdlint + gdformat --check |
| `print_phase0_status.sh` / `.ps1` | Optional Phase 0 / D001 / Camp-5 summary |

Harness: `res://harness/…` (not `combat/`). Production tracer: `combat/soak/CombatF5SoakTrace.gd`.

**F5 paste:** human `.f5_soak_in.txt` backed up to `.f5_soak_in.f5_backup.txt` during D001 and restored after Phase 0. Phase 0 also runs company-state checks + Camp-3.4 ship audit → `CAMPAIGN_SHIP_AUDIT: PASS`. F5 on demand: [`SHIP_PLAN#camp-playtest-acceptance`](../../docs/SHIP_PLAN.md#camp-playtest-acceptance). Footing/WF soak: [`LIVE_PATHS#wf-soak-audit-status`](../../docs/LIVE_PATHS.md#wf-soak-audit-status).

<a id="godot-entry"></a>

## Godot entry

Godot **4.x stable** headless. Override with `$GODOT` / `$env:GODOT`.

| Platform | Default (`tools/ci/_godot.sh` / `Invoke-GodotHeadless.ps1`) |
|----------|------------------------------------------------------------|
| **Linux** | PATH → Steam Godot → Flathub (`godot_via_flatpak.sh`) |
| **Windows** | `E:\Godot_v4.7-stable_win64.exe` |
| **macOS** | `/Applications/Godot.app/Contents/MacOS/Godot` |

`run_all_combat_checks.gd` — **`FP_HARNESS_MODE`**: `all` (default) · `regression` · `d001` · `sanity` · `calibration` · `medical` · `q_track` · `f5_validate`.

| Bash | PowerShell |
|------|------------|
| `./tools/ci/run_all_combat_checks.sh` | `.\tools\ci\run_all_combat_checks.ps1` |
| `FP_HARNESS_MODE=regression ./tools/ci/run_all_combat_checks.sh` | `.\tools\ci\run_all_combat_checks.ps1 -HarnessMode regression` |
| `./tools/ci/run_all_combat_checks.sh --validate-f5` | `.\tools\ci\run_all_combat_checks.ps1 -ValidateF5` |

Partial modes tee under repo root (`.harness_out.txt`, `.d001_*`, `.calibration_audit.txt`, …). Bash also accepts `./tools/ci/run_all_combat_checks.sh <mode>`.

Prompts: [`agent_prompts/README.md`](agent_prompts/README.md).

## Playtest (`run_playtest`)

**Prefer this dispatcher** for F5 work. Subcommands:

| Command | Purpose |
|---------|---------|
| `status` · `merge` · `revalidate` · `recover` · `after-append` · `full` · `exp0` · `rebuild` | Playtest workflows |
| `validate` · `append` · `preflight` · `closeout` · `restore` | Thin aliases of the standalone F5 CLIs below |

```bash
./tools/ci/run_playtest.sh validate
./tools/ci/run_playtest.sh closeout --human-signoff
./tools/ci/run_playtest.sh full --human-signoff
./tools/ci/run_playtest.sh exp0
```

Standalone twins still work (`validate_f5_soak_log`, `append_f5_soak_log`, `preflight_f5_followup`, `restore_f5_soak_log`, `run_camp_f5_closeout`, `validate_camp_optional_smokes`) — use them only if a tool or habit already points there.

**F5 Output grep:** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`LIVE_PATHS#f5-combat-diagnostic-tiers`](../../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers).

## Internals

- `_lib.sh` — bash bootstrap (`_godot.sh` + `f5_soak_log_helpers.sh`)
- `Invoke-GodotHeadless.ps1` / `_godot.sh` — Godot resolve
- `F5SoakLogHelpers.ps1` / `f5_soak_log_helpers.sh` — F5 backup, validate, gap merge, preflight
- `Phase0Helpers.ps1` — shared by `run_fast_phase0.ps1`
- `check_doc_links.py` — single implementation (`.sh` / `.ps1` wrappers)
- `ci_ensure_godot.sh` — CI Godot download
- `ci_lint.sh` / `requirements-ci.txt` — shellcheck + gdtoolkit (`gdlint` / `gdformat`)
- `tools/ci/.shellcheckrc` — `shellcheck --rcfile=tools/ci/.shellcheckrc -x tools/ci/*.sh`
- `.gdlintrc` / `.gdformatrc` — gdtoolkit configs (YAML; not `*.toml`)
- `company_checks/` · `_harness_*.gd` — company-state harness helpers

Godot `-s`: `run_all_combat_checks.gd` · `run_company_state_checks.gd` · `run_q_track_audits.gd`. Prefer grep `FP_HARNESS_OK` over Godot exit codes on Windows.
