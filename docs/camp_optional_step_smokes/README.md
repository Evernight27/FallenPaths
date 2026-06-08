# Camp §8 optional step validator smokes

Per-step **`FP_WORLD` / `FP_COMBAT`** chunks for **`CombatF5SoakLogValidator`** optional `[camp_*]` tracks. Not one real F5 session — use to re-check needles after validator or log-shape changes.

Or bundle all optional tracks: **`docs/f5_soak_log.camp_full.example.txt`**. Step 8–9 append only: **`docs/f5_soak_log.camp_step9_optional.example.txt`** + `preflight_f5_followup.ps1 -Step9Only` + `append_f5_soak_log.ps1 -Label camp5_step9`.

Batch headless regression (all per-step smokes):

```powershell
.\scripts\validate_camp_optional_smokes.ps1
```

```bash
./scripts/validate_camp_optional_smokes.sh
```

Validator normalizes Windows CRLF (`CombatF5SoakLogValidator._decode_f5_log_text`) — refresh backup after merge: `Copy-Item .f5_soak_in.txt .f5_soak_in.f5_backup.txt`.

| File | Validator track |
|------|-----------------|
| `step8_tutorial_soft.txt` | `camp_tutorial_soft_loss` |
| `step8_paid_loss.txt` | `camp_paid_loss` |
| `step9_wage_warn.txt` | `camp_wage_warn` |
| `step9_desertion.txt` | `camp_desertion` |
| `step4_field_care_action.txt` | `camp_field_care_action` |
| `step3e_mopup.txt` | `camp_mopup_strike_finish` |
| `step10_party_triage.txt` | `camp_party_triage` |
| `medical_exit.txt` | `camp_medical_exit` |

Human minimum paste: repo-root **`followup.log`** (gitignored) → `.f5_soak_in.txt` · `run_camp_f5_closeout.ps1 -HumanSignOff`.
