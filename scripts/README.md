# Combat scripts

Phase 0 (bash-first):

```bash
./scripts/run_all_combat_checks.sh
```

Do not pipe stdout to `grep`. Expect **`PHASE0: PASS`**. Windows: `.\scripts\run_all_combat_checks.ps1`.

Harness sources: `res://harness/…` (not `combat/`). Production tracer: `combat/CombatF5SoakTrace.gd`.

**F5 paste:** human `.f5_soak_in.txt` is auto-backed up to `.f5_soak_in.f5_backup.txt` during D001 capture and restored after Phase 0; backup is not downgraded when the live paste lacks `camp5_step9` append. **`append_f5_soak_log.sh`** / `.ps1` with camp5 labels updates the backup on success. Includes **`run_company_state_checks`** (Camp-1.1–1.8) and **Camp-3.4 tail** (Q track + `[ii7]` + `[ii_envelop]` + **`ii_envelop_mopup: PASS`** under `[ii_envelop]` → `CAMPAIGN_SHIP_AUDIT: PASS` in `.phase0_combat_checks.txt`). Regression tail includes **`CombatRegressionHarnessWeaponFormTail`** (18 rows) + **`AttentionFootworkTail`** **`_run_footwork_*`** — footing: [`#wf-footing-improvement-backlog`](../docs/LIVE_PATHS.md#wf-footing-improvement-backlog) · [`#wf-footing-doc-map`](../docs/LIVE_PATHS.md#wf-footing-doc-map) · Tier 4.4 PA [`#wf-tier-44-pa`](../docs/LIVE_PATHS.md#wf-tier-44-pa) · UI [`#battle-ui`](../docs/LIVE_PATHS.md#battle-ui) · soak **ii5c/ii8** [`#wf-soak-audit-status`](../docs/LIVE_PATHS.md#wf-soak-audit-status). **F5 on demand (Camp-5 ☑):** [`SHIP_PLAN#camp-playtest-acceptance`](../docs/SHIP_PLAN.md#camp-playtest-acceptance).

<a id="godot-entry"></a>

## Godot entry

Godot **4.x stable** headless. Override anytime with `$GODOT` / `$env:GODOT`.

| Platform | Default resolution (`scripts/_godot.sh` / `Invoke-GodotHeadless.ps1`) |
|----------|-----------------------------------------------------------------------|
| **Linux** | PATH (`godot4`/`godot`) → Steam `…/steamapps/common/Godot*` → Flathub `org.godotengine.Godot` (`godot_via_flatpak.sh`) |
| **Windows** | `E:\Godot_v4.7-stable_win64.exe` |
| **macOS** | `/Applications/Godot.app/Contents/MacOS/Godot` |

`run_all_combat_checks.gd` — set **`FP_HARNESS_MODE`** (`all` default · `regression` · `d001` · `sanity` · `calibration` · `medical`).

| Bash | PowerShell |
|------|------------|
| `./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1` |
| `FP_HARNESS_MODE=regression ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode regression` |
| `FP_HARNESS_MODE=d001 ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode d001` |
| `FP_HARNESS_MODE=sanity ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode sanity` |
| `FP_HARNESS_MODE=calibration ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode calibration` |
| `FP_HARNESS_MODE=medical ./scripts/run_all_combat_checks.sh` | `.\scripts\run_all_combat_checks.ps1 -HarnessMode medical` |
| `./scripts/run_all_combat_checks.sh --validate-f5` | `.\scripts\run_all_combat_checks.ps1 -ValidateF5` |

Partial modes tee logs under repo root (`.harness_out.txt`, `.d001_soak_out.txt`, `.d001_soak_sanity_out.txt`, `.calibration_audit.txt`, `.medical_phase_harness_out.txt`). Audit lane scratch: `.audit_*.txt`. Full pattern list: repo-root `.gitignore`. Bash also accepts `./scripts/run_all_combat_checks.sh <mode>` as the first argument.

## Other runners

**Bash twins:** most `*.ps1` gate runners have a `*.sh` twin. **PowerShell-only:** `run_q_audit.ps1`. **Fast Phase 0:** `run_fast_phase0.ps1` only (no `.sh` twin) — doc links + company state + regression harness; **-Full** = full Phase 0; **-D001Light** adds D001 light.

**Parallel agent chats (post–Camp-5 default):** [`agent_prompts/README.md`](agent_prompts/README.md).

**F5 Output grep (canonical):** `hit_resolve reason=` · `strike_avoided reason=` · `parry_partial rem=` · `diagram_banner player:` · `engagement_transition` · `encounter_context` · `soak_fight_end`. [`docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers`](../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers).

| Script | When |
|--------|------|
| `run_camp_f5_closeout.ps1` / `.sh` | Validate F5 log + Camp-5 status summary; **exit 0** on automated minimum (headless + **wf_m3** + **camp_section_8**); **`-HumanSignOff`** / **`--human-signoff`** blocks on docs example smoke |
| `preflight_f5_followup.ps1` / `.sh` | Grep chunk before append; **`-Step9Only`** / **`--step9-only`** for tutorial soft loss + wage + desertion only |
| `restore_f5_soak_log.ps1` / `.sh` | Restore `.f5_soak_in.f5_backup.txt` after Phase 0 clobber + re-validate |
| `append_f5_soak_log.ps1` / `.sh` | Merge chunk into `.f5_soak_in.txt` then **`validate_f5_soak_log`** — **`-Label camp5_*`** auto-runs preflight; **`-Preflight`** / **`--preflight`** explicit |
| `validate_f5_soak_log.ps1` | Parse `.f5_soak_in.txt` (or **`-LogPath`**); **`-Quiet`** for wrappers (do not pipe script to `Out-Null` on Windows). Normalizes Windows CRLF before grep; **WF-M3** + **Camp** + optional **`camp_*`** — smoke: **`docs/f5_soak_log.camp_wf.example.txt`** · **`docs/f5_soak_log.camp_full.example.txt`** · per-step: **`docs/camp_optional_step_smokes/`** · step-9 append: **`docs/f5_soak_log.camp_step9_optional.example.txt`** |
| `validate_camp_optional_smokes.ps1` / `.sh` | Playtest — headless **`camp_*`** regression on all **`docs/camp_optional_step_smokes/*.txt`**; restores **`.f5_soak_in.txt`** validation when present; prints **`EXP_0_2_OPTIONAL: PASS`** when human paste has steps 4, 8 paid, 9, 10 |
| `run_playtest.sh exp0` (wrapper: `run_exp0_playtest_gate`) | **Exp-0.2** optional smokes + closeout; `--skip-closeout` smokes only |
| `run_q_audit.ps1 -Track Q1\|Q2\|Track` | Playtest stream — headless audits (**Q1/Q2** = soak scenario ids) |
| `run_q_track_audits.gd` (via `run_q_audit.ps1`) | Q4 **ii8** proxies D-001 (`formation_mode`, `turn_ready_gauge`, `tooltip_match_ok`, `diagram_banner`, **`form_*`** suffix content) — see [#wf-soak-audit-status](../docs/LIVE_PATHS.md#wf-soak-audit-status) |
| `run_q_feel.ps1` / `run_q_feel.sh` `-Track Camp` / `Camp` | Playtest — F5 checklists (**Camp** = SHIP_PLAN §8 step 12 **WF-M3** + `.f5_soak_in.txt` scan + **`validate_f5_soak_log`**) |
| `run_company_state_checks.ps1` / `.sh` | Camp-1 economy loop (**406** headless tests incl. XCamp-3.x + P2 persistence + isolated harness save slot; fails on any `SCRIPT_ERROR`; exit = stdout `FP_HARNESS_OK: CompanyStateChecks`). Harness uses `CampaignPersistence.begin_harness_isolated_save()` — safe alongside open Godot editor. |
| `run_campaign_ship_audit.ps1` / `.sh` | Camp-3.4/5 headless standalone; `-TailOnly` / `--tail-only` skips company checks (Phase 0 already ran) |
| `print_phase0_status.ps1` / `.sh` | Summarize `.phase0_*` / `.d001_*` / calibration + Camp-5 headless vs human F5 status |
| `check_doc_links.ps1` | Doc link + tombstone gate + `res://` path audit (also run inside Phase 0) |
| `run_fast_phase0.ps1` | Fast Phase 0 — doc links + company state + regression harness only (no D001 soak / calibration); **-Full** = same as `run_all_combat_checks`, **-D001Light** = adds D001 light (~2-4 min vs ~8-12 min). No `.sh` twin. |
| `run_playtest.sh` / `.ps1` | **Playtest dispatcher** (no Phase 0): `status` · `merge` · `revalidate` · `recover` · `after-append` · `full` · `exp0` · `rebuild`. Thin `run_playtest_*.sh` / `run_exp0_*` / `rebuild_f5_*` wrappers remain for old paths. |

## Internals

- `_lib.sh` — bash bootstrap (`_godot.sh` + `f5_soak_log_helpers.sh`)
- `run_playtest.sh` / `.ps1` — playtest subcommand dispatcher
- `Invoke-GodotHeadless.ps1` / `_godot.sh` — Godot resolve
- `F5SoakLogHelpers.ps1` / `f5_soak_log_helpers.sh` — F5 backup, validate, gap merge, preflight
- `check_doc_links.py` — single implementation (`.sh` / `.ps1` wrappers)
- `ci_ensure_godot.sh` — CI Godot download
- `.shellcheckrc` — `shellcheck -x scripts/*.sh` (source-path=SCRIPTDIR)

Godot `-s`: `run_all_combat_checks.gd` · `run_company_state_checks.gd` · `run_q_track_audits.gd`. Prefer grep `FP_HARNESS_OK` over Godot exit codes on Windows.
