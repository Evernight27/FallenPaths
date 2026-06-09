# Full Playtest closeout (no Phase 0): merge gaps + revalidate + optional Exp-0.2 smokes gate.
param(
	[switch]$DryRun,
	[switch]$HumanSignOff,
	[switch]$SkipExp0
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest full gate (no Phase 0) ==="
$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
if (-not ((Test-Path $phase0) -and (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
		-and (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet))) {
	Write-Host "PLAYTEST_FULL_GATE: FAIL (headless not green - run .\scripts\run_all_combat_checks.ps1 first)"
	exit 1
}

if ($DryRun) {
	Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
	$val = Join-Path $Root ".f5_soak_validation.txt"
	$log = Get-F5SoakLogPath $Root
	if (Ensure-F5PlaytestValidatorReport -Root $Root) {
		if (Test-F5ValidationFresh $Root) {
			Write-Host "Validator report: fresh (skipped Godot re-run)"
		}
	} else {
		Write-Host "WARN: validator report missing or stale after refresh attempt"
	}
	Show-F5SmokeAppendSummary -LogPath $log
	$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
	if ($plan.Count -eq 0) {
		Write-Host "PLAYTEST_FULL_GATE: no merge gaps"
	} else {
		Write-Host ("Merge plan: {0} append(s)" -f $plan.Count)
		foreach ($row in $plan) {
			Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
		}
	}
	if (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
		Write-Host "PLAYTEST_COVERAGE: PASS (would run revalidate + Exp-0.2)"
	} else {
		Show-F5HumanCoverageHints -Root $Root -ValPath $val
	}
	exit 0
}

& (Join-Path $PSScriptRoot "run_playtest_merge_gaps.ps1") -SkipRevalidate
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$revalidateArgs = @()
if ($HumanSignOff) { $revalidateArgs += "-HumanSignOff" }
if (-not $SkipExp0) { $revalidateArgs += "-Exp0Gate" }
& (Join-Path $PSScriptRoot "run_playtest_revalidate.ps1") @revalidateArgs
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_FULL_GATE: FAIL"
	exit $LASTEXITCODE
}
Write-Host "PLAYTEST_FULL_GATE: PASS"
exit 0
