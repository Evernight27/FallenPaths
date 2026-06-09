# Recover human F5 paste after Phase 0 clobber + merge validator gaps (Playtest stream, no Phase 0).
param(
	[switch]$DryRun,
	[switch]$HumanSignOff,
	[switch]$ForceRestore
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest recover (no Phase 0) ==="
$log = Get-F5SoakLogPath $Root
$bak = Get-F5SoakBackupPath $Root
$restored = Restore-F5SoakHumanPasteIfClobbered -Root $Root
if (-not $restored) {
	if ((Test-Path $log) -and (Test-F5SoakHeadlessCaptureOnly $log) -and (Test-Path $bak)) {
		if ($ForceRestore -or $DryRun) {
			if (-not $DryRun) {
				Restore-F5SoakHumanPaste -Root $Root | Out-Null
			} else {
				Write-Host "Would restore human paste from $bak (headless capture detected)"
			}
		} else {
			Write-Host "PLAYTEST_RECOVER: FAIL (headless capture - re-run with -ForceRestore or .\scripts\restore_f5_soak_log.ps1)"
			exit 2
		}
	}
}
if (-not (Test-Path $log)) {
	Write-Host "PLAYTEST_RECOVER: FAIL (missing .f5_soak_in.txt)"
	exit 2
}
if (Test-F5SoakHeadlessCaptureOnly $log) {
	Write-Host "PLAYTEST_RECOVER: FAIL (still headless capture - no human backup?)"
	exit 2
}

if ($DryRun) {
	Show-F5SmokeAppendSummary -LogPath $log
	$val = Join-Path $Root ".f5_soak_validation.txt"
	if (Ensure-F5PlaytestValidatorReport -Root $Root) {
		if (Test-F5ValidationFresh $Root) {
			Write-Host "Validator report: fresh (skipped Godot re-run)"
		}
	} else {
		Write-Host "WARN: validator report missing or stale after refresh attempt"
	}
	$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
	if ($plan.Count -eq 0) {
		Write-Host "Merge gaps: none"
	} else {
		Write-Host ("Merge gaps: {0} append(s)" -f $plan.Count)
		foreach ($row in $plan) {
			Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
		}
	}
	Show-F5HumanCoverageHints -Root $Root -ValPath $val
	Write-Host "PLAYTEST_RECOVER: dry-run"
	exit 0
}

Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
& (Join-Path $PSScriptRoot "run_playtest_merge_gaps.ps1") $(if ($HumanSignOff) { "-HumanSignOff" })
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& (Join-Path $PSScriptRoot "run_playtest_status.ps1") -Quiet
exit $LASTEXITCODE
