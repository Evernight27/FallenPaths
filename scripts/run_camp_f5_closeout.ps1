# Camp-5 F5 close-out: validate .f5_soak_in.txt (if present) + EA sign-off summary.
# Exit 0 only when headless + wf_m3 + camp_section_8 are all READY.
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
$f5Log = Join-Path $Root ".f5_soak_in.txt"
if (Test-Path $f5Log) {
	& (Join-Path $Root "scripts\validate_f5_soak_log.ps1") | Out-Null
}
& (Join-Path $Root "scripts\print_phase0_status.ps1") | Out-Null
$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
$f5Val = Join-Path $Root ".f5_soak_validation.txt"
$headless = (Test-Path $phase0) -and (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
	-and (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet)
$wfm3 = (Test-Path $f5Val) -and (Select-String -Path $f5Val -Pattern "^ok=true" -Quiet) `
	-and (Select-String -Path $f5Val -Pattern "^\[wf_m3_turn_ready_form\] PASS" -Quiet) `
	-and (Select-String -Path $f5Val -Pattern "^\[wf_m3_grd_before_form\] PASS" -Quiet)
$campSettlement = (Test-Path $f5Val) -and (Select-String -Path $f5Val -Pattern "^\[camp_settlement_continue\] PASS" -Quiet)
$campDay = (Test-Path $f5Val) -and (Select-String -Path $f5Val -Pattern "^\[camp_company_day\] PASS" -Quiet)
$camp = $campSettlement -and $campDay
$mopupOpt = (Test-Path $f5Val) -and (Select-String -Path $f5Val -Pattern "^\[camp_mopup_strike_finish\] PASS" -Quiet)
$soakEnd = (Test-Path $f5Log) -and (Select-String -Path $f5Log -Pattern "soak_fight_end winner=" -Quiet)
$optionalCamp = @(
	@{ Step = "4 field care action"; Id = "camp_field_care_action" },
	@{ Step = "8 paid loss"; Id = "camp_paid_loss" },
	@{ Step = "8 tutorial soft"; Id = "camp_tutorial_soft_loss" },
	@{ Step = "9 wage warn"; Id = "camp_wage_warn" },
	@{ Step = "9 desertion"; Id = "camp_desertion" },
	@{ Step = "3e mop-up"; Id = "camp_mopup_strike_finish" },
	@{ Step = "10 party triage"; Id = "camp_party_triage" },
	@{ Step = "medical exit"; Id = "camp_medical_exit" }
)
function Show-OptionalCampTracks {
	param([string]$ValPath)
	if (-not (Test-Path $ValPath)) { return }
	Write-Host "Camp §8 extended (optional validator tracks):"
	foreach ($row in $optionalCamp) {
		$pat = "^\[$($row.Id)\] PASS"
		if (Select-String -Path $ValPath -Pattern $pat -Quiet) {
			Write-Host ("  [OK] step $($row.Step) [$($row.Id)]")
		} else {
			Write-Host ("  [--] step $($row.Step) [$($row.Id)] - merge separate F5 runs or docs/f5_soak_log.camp_full.example.txt smoke")
		}
	}
	Write-Host "  step 10 Party triage: open Party menu once (grep party_triage_open) or optional [camp_party_triage] PASS"
}
if ($headless -and $wfm3 -and $camp) {
	if (-not $mopupOpt) {
		Write-Host "NOTE: optional camp_mopup_strike_finish not PASS (rout-only wins OK for settlement)"
	}
	Show-OptionalCampTracks $f5Val
	exit 0
}
Write-Host "=== Camp-5 close-out blocked ==="
if (-not $headless) { Write-Host "  headless: run .\scripts\run_all_combat_checks.ps1 -> PHASE0 + CAMPAIGN_SHIP_AUDIT PASS" }
if (-not (Test-Path $f5Log)) { Write-Host "  f5_log: missing .f5_soak_in.txt (paste full F5 Output after Camp playtest)" }
if ((Test-Path $f5Log) -and -not $wfm3) { Write-Host "  wf_m3: run validate_f5_soak_log.ps1; need wf_m3_turn_ready_form + wf_m3_grd_before_form PASS" }
if ((Test-Path $f5Log) -and -not $campSettlement) { Write-Host "  camp: need settlement_continue or contract_victory pay= in log -> [camp_settlement_continue] PASS" }
if ((Test-Path $f5Log) -and $campSettlement -and -not $campDay) { Write-Host "  camp: need company_day_advanced after settlement (end day or camp rest)" }
if ((Test-Path $f5Log) -and -not $soakEnd) { Write-Host "  hint: log missing soak_fight_end (merge combat Output with world markers)" }
if (Test-Path $f5Val) { Show-OptionalCampTracks $f5Val }
exit 1
