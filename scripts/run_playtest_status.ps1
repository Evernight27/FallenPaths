# Fast Playtest status (no Phase 0) — reads .f5_soak_validation.txt; optional -Refresh runs Godot validator.
param(
	[switch]$Refresh,
	[switch]$ShowGaps,
	[switch]$SmokeLabels,
	[switch]$Quiet
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest status (no Phase 0) ==="
Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
$log = Get-F5SoakLogPath $Root
$val = Join-Path $Root ".f5_soak_validation.txt"

if (-not (Test-Path $log)) {
	Write-Host "PLAYTEST_STATUS: FAIL (missing .f5_soak_in.txt)"
	exit 2
}
if (Test-F5SoakHeadlessCaptureOnly $log) {
	Write-Host "PLAYTEST_STATUS: FAIL (headless D001 capture - run .\scripts\restore_f5_soak_log.ps1)"
	exit 2
}

if ($Refresh) {
	if (-not (Ensure-F5PlaytestValidatorReport -Root $Root -ForceRefresh)) {
		Write-Host "PLAYTEST_STATUS: FAIL (validate_f5_soak_log)"
		exit 1
	}
} elseif (-not (Ensure-F5PlaytestValidatorReport -Root $Root)) {
	Write-Host "PLAYTEST_STATUS: FAIL (validate_f5_soak_log refresh)"
	exit 1
}

$human = Get-F5HumanSignoffStatus $log
Write-Host ("human_signoff: " + $human)
if ($SmokeLabels -or (-not $Quiet)) {
	Show-F5SmokeAppendSummary -LogPath $log -Quiet:($Quiet -and -not $SmokeLabels)
}
if (-not (Test-Path $val)) {
	Write-Host "PLAYTEST_STATUS: FAIL (no .f5_soak_validation.txt - run -Refresh)"
	exit 1
}
if (-not (Select-String -Path $val -Pattern "^ok=true" -Quiet)) {
	Write-Host "PLAYTEST_STATUS: FAIL (validator ok=false - run -Refresh)"
	exit 1
}
if (-not $Quiet) {
	$profiles = (Select-String -Path $val -Pattern "^profiles=" | Select-Object -First 1).Line
	if ($profiles) { Write-Host $profiles.Trim() }
}

if (-not (Test-F5ValidationFresh $Root)) {
	Write-Host "PLAYTEST_STATUS: FAIL (validation stale - run -Refresh)"
	exit 1
}

$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
if ($ShowGaps -or ($plan.Count -gt 0)) {
	if ($plan.Count -eq 0) {
		Write-Host "Merge gaps: none"
	} else {
		Write-Host ("Merge gaps: {0} append(s)" -f $plan.Count)
		foreach ($row in $plan) {
			Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
		}
		if (-not $ShowGaps) {
			Write-Host "Hint: .\scripts\run_playtest_merge_gaps.ps1 -DryRun"
		}
	}
}

if (-not $Quiet) {
	Show-F5HumanCoverageHints -Root $Root -ValPath $val
} elseif (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
	Write-Host "PLAYTEST_COVERAGE: PASS (A-F + optional validator tracks on human paste)"
} else {
	Write-Host "PLAYTEST_COVERAGE: GAPS (run .\scripts\run_playtest_merge_gaps.ps1 -DryRun)"
}

if (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
	Write-Host "PLAYTEST_STATUS: PASS"
	if (-not $Quiet) {
		Show-F5PlaytestWorkflowHints -Root $Root -ValPath $val
	}
	exit 0
}
$labels = Get-F5HumanPasteAppendLabels $log
if ($labels.Count -gt 0) {
	Write-Host ("Hint: smoke labels in paste ({0}) but coverage incomplete - run -Refresh" -f ($labels -join ", "))
}
Show-F5PlaytestWorkflowHints -Root $Root -ValPath $val
Write-Host "PLAYTEST_STATUS: GAPS"
exit 1
