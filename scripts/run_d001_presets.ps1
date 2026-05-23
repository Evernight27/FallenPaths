# Headless ii5 + ii6 D-001 presets — report: .ii5_ii6_soak_out.txt
# Optional: $env:D001_PRESETS = "ii5"  or  "ii6"  or  "ii5,ii6"
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Root = Get-FallenPathsRoot
$Log = Join-Path $Root ".ii5_ii6_soak_out.txt"
Invoke-FallenPathsGodotScript -Script "res://scripts/run_d001_presets.gd" -TeeLog $Log | Out-Null
if (Select-String -Path $Log -Pattern "FP_HARNESS_OK: D001PresetsIi5Ii6" -Quiet) { exit 0 }
exit $LASTEXITCODE
