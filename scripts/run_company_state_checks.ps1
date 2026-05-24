# Camp-1.1–1.8 headless company loop checks (Campaign stream; required in Phase 0).
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
Invoke-FallenPathsGodotScript -Script "res://scripts/run_company_state_checks.gd"
exit $LASTEXITCODE
