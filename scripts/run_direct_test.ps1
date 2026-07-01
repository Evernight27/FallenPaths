$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Root = Get-FallenPathsRoot
Write-Host "=== Warmup ==="
Invoke-FallenPathsGodotImportWarmup

$Godot = Get-FallenPathsGodot
$env:FP_HARNESS_MODE = "all"

# Try WITH ForEach-Object (like the working wrapper)
$godotOut = @(& $Godot --headless --path $Root -s 'res://scripts/run_all_combat_checks.gd' 2>&1 | ForEach-Object { "$_" })
$script:LastFallenPathsGodotExitCode = $LASTEXITCODE

Write-Host ("Output lines: " + $godotOut.Count.ToString())
Write-Host ("Exit code: " + $LASTEXITCODE.ToString())
$godotOut | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }
