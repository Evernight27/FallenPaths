# Safe Playtest re-validate (no Phase 0) — human paste + optional smokes + closeout.
# Use after F5 append or when Phase 0 is already green on disk.
param(
	[switch]$HumanSignOff,
	[switch]$SkipSmokes,
	[switch]$SkipCloseout,
	[switch]$Exp0Gate
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest re-validate (no Phase 0) ==="
Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null

$log = Get-F5SoakLogPath $Root
if (-not (Test-Path $log)) {
	Write-Host "PLAYTEST_REVALIDATE: FAIL (missing .f5_soak_in.txt)"
	exit 1
}
if (Test-F5SoakHeadlessCaptureOnly $log) {
	Write-Host "PLAYTEST_REVALIDATE: FAIL (headless D001 capture - run .\scripts\restore_f5_soak_log.ps1)"
	exit 1
}

& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -Quiet
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_REVALIDATE: FAIL (validate_f5_soak_log)"
	exit $LASTEXITCODE
}

if (-not $SkipSmokes) {
	& (Join-Path $PSScriptRoot "validate_camp_optional_smokes.ps1") -Quiet
	if ($LASTEXITCODE -ne 0) {
		Write-Host "PLAYTEST_REVALIDATE: FAIL (camp optional smokes)"
		exit $LASTEXITCODE
	}
	Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
} elseif (-not (Test-F5ValidationFresh $Root)) {
	Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
}

if ($SkipCloseout) {
	Write-Host "PLAYTEST_REVALIDATE: PASS (skipped closeout)"
	exit 0
}

& (Join-Path $PSScriptRoot "run_camp_f5_closeout.ps1") -SkipRevalidate $(if ($HumanSignOff) { "-HumanSignOff" })
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_REVALIDATE: FAIL (closeout)"
	exit $LASTEXITCODE
}
if ($Exp0Gate) {
	& (Join-Path $PSScriptRoot "run_exp0_playtest_gate.ps1") -SkipCloseout
	if ($LASTEXITCODE -ne 0) {
		Write-Host "PLAYTEST_REVALIDATE: FAIL (Exp-0.2 gate smokes)"
		exit $LASTEXITCODE
	}
}
Write-Host "PLAYTEST_REVALIDATE: PASS"
exit 0
