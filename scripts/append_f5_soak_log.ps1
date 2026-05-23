# Append a saved Godot Output file to .f5_soak_in.txt (multi-fight D-001 paste).
# -Replace: overwrite .f5_soak_in.txt (one-shot import of a single log file).
param(
	[Parameter(Mandatory = $true)]
	[string]$SourcePath,
	[switch]$Replace
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$resolved = if ([System.IO.Path]::IsPathRooted($SourcePath)) { $SourcePath } else { Join-Path $Root $SourcePath }
if (-not (Test-Path $resolved)) {
	Write-Error "Source log not found: $resolved"
	exit 2
}
$dest = Join-Path $Root ".f5_soak_in.txt"
$chunk = Get-Content -LiteralPath $resolved -Raw
if (-not $chunk.EndsWith("`n")) { $chunk += "`n" }
if ($Replace -or -not (Test-Path $dest)) {
	Set-Content -LiteralPath $dest -Value $chunk -NoNewline
	Write-Host "Wrote $dest ($((Get-Item $dest).Length) bytes)"
} else {
	Add-Content -LiteralPath $dest -Value "`n--- f5_soak_append ---`n$chunk" -NoNewline
	Write-Host "Appended to $dest ($((Get-Item $dest).Length) bytes)"
}
Write-Host "Run: .\scripts\validate_f5_soak_log.ps1"
