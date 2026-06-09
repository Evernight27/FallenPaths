# Merge known validator gaps into .f5_soak_in.txt (Playtest stream — no Phase 0).
# Reads .f5_soak_validation.txt and appends smoke/bundle chunks for missing tracks.
param(
	[switch]$DryRun,
	[switch]$HumanSignOff,
	[switch]$SkipRevalidate
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest merge gaps ==="
Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
$log = Get-F5SoakLogPath $Root
if (-not (Test-Path $log)) {
	Write-Host "PLAYTEST_MERGE_GAPS: FAIL (missing .f5_soak_in.txt)"
	exit 1
}
if (Test-F5SoakHeadlessCaptureOnly $log) {
	Write-Host "PLAYTEST_MERGE_GAPS: FAIL (headless D001 capture - run .\scripts\restore_f5_soak_log.ps1)"
	exit 1
}

$val = Join-Path $Root ".f5_soak_validation.txt"
if (-not (Ensure-F5PlaytestValidatorReport -Root $Root)) {
	Write-Host "PLAYTEST_MERGE_GAPS: FAIL (validate_f5_soak_log before merge)"
	exit 1
}
if ($DryRun -and (Test-F5ValidationFresh $Root)) {
	Write-Host "Validator report: fresh (skipped Godot re-run)"
}
$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
if ($plan.Count -eq 0) {
	Write-Host "PLAYTEST_MERGE_GAPS: no gaps (validator + human coverage complete)"
	if (-not $SkipRevalidate -and -not $DryRun) {
		& (Join-Path $PSScriptRoot "run_playtest_revalidate.ps1") $(if ($HumanSignOff) { "-HumanSignOff" })
		exit $LASTEXITCODE
	}
	exit 0
}

Write-Host ("Gaps found: {0}" -f $plan.Count)
foreach ($row in $plan) {
	Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
}
if ($DryRun) {
	Write-Host "PLAYTEST_MERGE_GAPS: dry-run (no append)"
	exit 0
}

foreach ($row in $plan) {
	if (-not (Test-Path $row.Path)) {
		Write-Host "PLAYTEST_MERGE_GAPS: FAIL (missing chunk $($row.Path))"
		exit 2
	}
	if (Test-F5PlaytestGapMergeRowAlreadySatisfied $row $log) {
		Write-Host ("Skip append [{0}] - already satisfied in paste" -f $row.Label)
		continue
	}
	& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") -AppendFrom $row.Path -Label $row.Label
	if ($LASTEXITCODE -ne 0) {
		Write-Host "PLAYTEST_MERGE_GAPS: FAIL (append $($row.Label))"
		exit $LASTEXITCODE
	}
}

if ($SkipRevalidate) {
	Write-Host "PLAYTEST_MERGE_GAPS: PASS (appended; skipped revalidate)"
	exit 0
}

& (Join-Path $PSScriptRoot "run_playtest_revalidate.ps1") $(if ($HumanSignOff) { "-HumanSignOff" })
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_MERGE_GAPS: FAIL (post-merge revalidate)"
	exit $LASTEXITCODE
}
Write-Host "PLAYTEST_MERGE_GAPS: PASS"
exit 0
