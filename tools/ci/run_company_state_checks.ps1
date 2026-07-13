# Camp-1 + XCamp-3.x headless company loop checks (406 tests; isolated harness save slot).
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Godot = Get-FallenPathsGodot
$Root = Get-FallenPathsRoot
Invoke-FallenPathsGodotImportWarmup
$out = @(& $Godot --headless --path $Root -s "res://tools/ci/run_company_state_checks.gd" 2>&1 | ForEach-Object { "$_" })
$out | Write-Output
if ($out -match "FP_HARNESS_OK:\s+CompanyStateChecks") {
	exit 0
}
exit 1
