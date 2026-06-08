# Restore human F5 paste from .f5_soak_in.f5_backup.txt (written by run_all_combat_checks during Phase 0).
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent $PSScriptRoot
$bak = Get-F5SoakBackupPath $Root
if (-not (Test-Path $bak)) {
	Write-Host "No backup at $bak"
	Write-Host "Backup is created when Phase 0 runs while .f5_soak_in.txt has FP_WORLD: lines or append chunks."
	exit 1
}
if (Test-F5SoakIsExampleSmoke $bak) {
	Write-Host "WARN: backup is docs example smoke, not a real F5 paste"
}
if (Restore-F5SoakHumanPaste $Root) {
	& (Join-Path $Root "scripts\validate_f5_soak_log.ps1")
	$val = Join-Path $Root ".f5_soak_validation.txt"
	if (Test-Path $val) {
		Write-Host ""
		Write-Host "--- Step 8-9 optional tracks ---"
		foreach ($id in @("camp_tutorial_soft_loss", "camp_wage_warn", "camp_desertion")) {
			$st = Get-F5ValidatorTrackStatus $val $id
			Write-Host ("  [{0}] {1}" -f $(if ($st -eq "pass") { "OK" } else { $st }), $id)
		}
	}
	exit $LASTEXITCODE
}
exit 1
