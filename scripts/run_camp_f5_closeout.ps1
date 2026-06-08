# F5 Camp status (Camp-5 EA ☑ 2026-06-07): validate .f5_soak_in.txt (if present) + status summary.
# Exit 0 when headless + wf_m3 + camp_section_8 validator minimum are READY.
# -HumanSignOff requires a real F5 paste (not docs example smoke) for re-validation after new appends.
param(
	[switch]$HumanSignOff
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")
$f5Log = Join-Path $Root ".f5_soak_in.txt"
if (Test-Path $f5Log) {
	& (Join-Path $Root "scripts\validate_f5_soak_log.ps1") -Quiet
	Show-F5SoakStatusHint $Root
}
	& (Join-Path $Root "scripts\print_phase0_status.ps1") -Quiet
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
	@{ Step = "4 field care action"; Id = "camp_field_care_action"; Hint = "map Party -> bandage/pressure (FP_WORLD field_care bandage part=)" },
	@{ Step = "8 paid loss"; Id = "camp_paid_loss"; Hint = "lose paid contract -> company_run_end reason=contract_failed reload=true" },
	@{ Step = "8 tutorial soft"; Id = "camp_tutorial_soft_loss"; Hint = "lose tutorial 2v2 -> reason=tutorial_failed reload=false" },
	@{ Step = "9 wage warn"; Id = "camp_wage_warn"; Hint = "End day with low gold -> company_wages: gold=" },
	@{ Step = "9 desertion"; Id = "camp_desertion"; Hint = "keep End day while broke -> desertion summary=" },
	@{ Step = "3e mop-up"; Id = "camp_mopup_strike_finish"; Hint = "win via rout mop-up strikes (Escort/Border)" },
	@{ Step = "10 party triage"; Id = "camp_party_triage"; Hint = "open Party on map -> party_triage_open living=" },
	@{ Step = "medical exit"; Id = "camp_medical_exit"; Hint = "Finish medical treatment on tutorial or messy fight" }
)
function Show-OptionalCampTracks {
	param([string]$ValPath)
	if (-not (Test-Path $ValPath)) { return }
	Write-Host "Camp section 8 extended (optional validator tracks):"
	foreach ($row in $optionalCamp) {
		$status = Get-F5ValidatorTrackStatus $ValPath $row.Id
		switch ($status) {
			"pass" { Write-Host ("  [OK] step $($row.Step) [$($row.Id)]") }
			"optional_miss" {
				Write-Host ("  [opt] step $($row.Step) [$($row.Id)] (OPTIONAL_MISS in validator)")
				if ($row.Hint) { Write-Host ("       -> $($row.Hint)") }
			}
			default {
				Write-Host ("  [--] step $($row.Step) [$($row.Id)]")
				if ($row.Hint) { Write-Host ("       -> $($row.Hint)") }
			}
		}
	}
}
if ($headless -and $wfm3 -and $camp) {
	$humanStatus = Get-F5HumanSignoffStatus $f5Log
	if (-not $mopupOpt) {
		Write-Host "NOTE: optional camp_mopup_strike_finish not PASS (rout-only wins OK for settlement)"
	}
	Show-OptionalCampTracks $f5Val
	if (Test-F5Exp02OptionalTracksPass $f5Val) {
		Write-Host "Exp-0.2 optional tracks (steps 4, 8 paid, 9, 10): PASS"
	} elseif (Test-Path $f5Log) {
		Write-Host "Exp-0.2 optional tracks: incomplete (see optional table above)"
	}
	Write-Host ""
	Write-Host "=== Close-out summary ==="
	Write-Host "automated_minimum: PASS (headless + wf_m3 + camp settlement/day)"
	switch ($humanStatus) {
		"READY" { Write-Host "human_signoff: READY (real F5 paste - tick SHIP_PLAN after glance)" }
		"SMOKE ONLY" { Write-Host "human_signoff: SMOKE ONLY (docs example - paste real F5 Output for Camp-5)" }
		default { Write-Host "human_signoff: NOT READY (need F5 editor Output merged into .f5_soak_in.txt)" }
	}
	if ($HumanSignOff -and $humanStatus -ne "READY") {
		Write-Host ""
		Write-Host "=== Camp-5 human sign-off blocked ==="
		if ($humanStatus -eq "SMOKE ONLY") {
			Write-Host "  f5_log: docs example smoke - run F5 playtest and append followup.log"
		} elseif ($humanStatus -eq "NOT READY (headless capture)") {
			Write-Host "  f5_log: headless D001 capture - restore .\scripts\restore_f5_soak_log.ps1 or paste F5 Output"
		} else {
			Write-Host "  f5_log: paste full Godot Output or append with .\scripts\append_f5_soak_log.ps1"
		}
		Write-Host "  preflight: .\scripts\preflight_f5_followup.ps1 followup.log"
		exit 1
	}
	exit 0
}
Write-Host "=== F5 Camp status: not ready ==="
if (-not $headless) { Write-Host "  headless: run .\scripts\run_all_combat_checks.ps1 -> PHASE0 + CAMPAIGN_SHIP_AUDIT PASS" }
if (-not (Test-Path $f5Log)) { Write-Host "  f5_log: missing .f5_soak_in.txt (paste full F5 Output after Camp playtest)" }
if ((Test-Path $f5Log) -and -not $wfm3) { Write-Host "  wf_m3: run validate_f5_soak_log.ps1; need wf_m3_turn_ready_form + wf_m3_grd_before_form PASS" }
if ((Test-Path $f5Log) -and -not $campSettlement) {
	if (Test-F5SoakHeadlessCaptureOnly $f5Log) {
		Write-Host "  f5_log: headless capture only - restore .\scripts\restore_f5_soak_log.ps1 or paste F5 Output with FP_WORLD settlement_continue"
	} else {
		Write-Host "  camp: need settlement_continue or contract_victory pay= in log -> [camp_settlement_continue] PASS"
	}
}
if ((Test-Path $f5Log) -and $campSettlement -and -not $campDay) { Write-Host "  camp: need company_day_advanced after settlement (end day or camp rest)" }
if ((Test-Path $f5Log) -and -not $soakEnd) { Write-Host "  hint: log missing soak_fight_end (merge combat Output with world markers)" }
if (Test-Path $f5Val) { Show-OptionalCampTracks $f5Val }
exit 1
