# Camp-1.1–1.8 headless company loop checks (Campaign stream; required in Phase 0).
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Godot = Get-FallenPathsGodot
$Root = Get-FallenPathsRoot
$out = @(& $Godot --headless --path $Root -s "res://scripts/run_company_state_checks.gd" 2>&1 | ForEach-Object { "$_" })
$out | Write-Output
if ($out -match "FP_HARNESS_OK:\s+CompanyStateChecks") {
	exit 0
}
exit 1
