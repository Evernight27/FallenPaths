# Validate pasted F5 Output for D-001 / II-0 greps (see docs/LIVE_PATHS.md#phase-0-gate).

param(

	[string]$LogPath = ""

)

$ErrorActionPreference = "Continue"

. "$PSScriptRoot\Invoke-GodotHeadless.ps1"

$Root = Get-FallenPathsRoot

$InputDefault = Join-Path $Root ".f5_soak_in.txt"

$ReportPath = Join-Path $Root ".f5_soak_validation.txt"

$extra = @()

if ($LogPath -ne "") {

	$resolved = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }

	if (-not (Test-Path $resolved)) {

		Write-Error "Log file not found: $resolved"

		exit 2

	}

	$extra = @("--", $resolved)

} elseif (-not (Test-Path $InputDefault)) {

	Write-Host "No log at $InputDefault"

	Write-Host "After F5: copy Output (FP_COMBAT lines) -> save as .f5_soak_in.txt -> re-run this script."

	Write-Host "Smoke (no F5): Copy-Item docs\f5_soak_log.example.txt .f5_soak_in.txt"

	Write-Host "Or: .\scripts\validate_f5_soak_log.ps1 -LogPath my_fight.log"

	exit 2

}

Write-Host "=== CombatF5SoakLogValidator ==="

Invoke-FallenPathsGodotScript -Script "res://scripts/run_f5_soak_log_validator.gd" -GodotExtraArgs $extra | Out-Null

if (Test-Path $ReportPath) {
	Write-Host ""
	Write-Host "--- Report: $ReportPath ---"
	Get-Content $ReportPath
}

exit $LASTEXITCODE


