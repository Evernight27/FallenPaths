# Exp-0.2 Playtest gate — optional Camp §8 smokes + human paste closeout (no full Phase 0 re-run).
# Prereq: run_all_combat_checks.ps1 already green this session.
param(
	[switch]$SkipCloseout
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
$phase0Stamp = Join-Path $Root ".phase0_playtest_gate_stamp.txt"
$phase0Green = (Test-Path $phase0) -and (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
	-and (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet)
if (-not $phase0Green) {
	Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (headless not green - run .\scripts\run_all_combat_checks.ps1 first)"
	exit 1
}
Copy-Item -LiteralPath $phase0 -Destination $phase0Stamp -Force

Write-Host "=== Exp-0.2 Playtest gate ==="
& (Join-Path $PSScriptRoot "validate_camp_optional_smokes.ps1")
if ($LASTEXITCODE -ne 0) {
	Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"
	exit $LASTEXITCODE
}

if ($SkipCloseout) {
	Write-Host "EXP_0_2_PLAYTEST_GATE: PASS (smokes only; skipped closeout)"
	exit 0
}

# Restore stamped Phase 0 summary if a concurrent harness run clobbered it during smokes.
if ((Test-Path $phase0Stamp) -and (-not (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
		-or -not (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet))) {
	Copy-Item -LiteralPath $phase0Stamp -Destination $phase0 -Force
}

& (Join-Path $PSScriptRoot "run_camp_f5_closeout.ps1") -HumanSignOff -SkipRevalidate
if ($LASTEXITCODE -ne 0) {
	Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"
	exit $LASTEXITCODE
}
Write-Host "EXP_0_2_PLAYTEST_GATE: PASS"
exit 0
