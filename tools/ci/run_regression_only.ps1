param(
	[string]$HarnessMode = "regression"
)
$ErrorActionPreference = "Continue"
& "$PSScriptRoot\run_all_combat_checks.ps1" -HarnessMode $HarnessMode 2>&1 | Tee-Object -FilePath "..\.harness_reg_run.txt"
