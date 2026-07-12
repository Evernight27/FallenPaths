# Playtest dispatcher — maps to existing run_playtest_*.ps1 / rebuild / exp0 scripts.
#   .\scripts\run_playtest.ps1 status|merge|revalidate|recover|after-append|full|exp0|rebuild …
param(
	[Parameter(Position = 0, Mandatory = $true)]
	[string]$Command,
	[Parameter(ValueFromRemainingArguments = $true)]
	[object[]]$RestArgs
)
$ErrorActionPreference = "Stop"
$map = @{
	"status" = "run_playtest_status.ps1"
	"merge" = "run_playtest_merge_gaps.ps1"
	"merge-gaps" = "run_playtest_merge_gaps.ps1"
	"revalidate" = "run_playtest_revalidate.ps1"
	"recover" = "run_playtest_recover.ps1"
	"after-append" = "run_playtest_after_append.ps1"
	"after_append" = "run_playtest_after_append.ps1"
	"full" = "run_playtest_full_gate.ps1"
	"full-gate" = "run_playtest_full_gate.ps1"
	"exp0" = "run_exp0_playtest_gate.ps1"
	"exp0-gate" = "run_exp0_playtest_gate.ps1"
	"rebuild" = "rebuild_f5_maintained_paste.ps1"
}
$key = $Command.ToLowerInvariant()
if (-not $map.ContainsKey($key)) {
	Write-Error "Unknown command '$Command'. Use: $($map.Keys -join ', ')"
	exit 2
}
$script = Join-Path $PSScriptRoot $map[$key]
# after-append / rebuild: first remaining arg is often a path (-AppendFrom / -BaselineFrom).
if ($key -in @("after-append", "after_append") -and $RestArgs.Count -ge 1 -and $RestArgs[0] -notlike "-*") {
	$path = $RestArgs[0]
	$RestArgs = @("-AppendFrom", $path) + @($RestArgs | Select-Object -Skip 1)
}
if ($key -eq "rebuild" -and $RestArgs.Count -ge 1 -and $RestArgs[0] -notlike "-*") {
	$path = $RestArgs[0]
	$RestArgs = @("-BaselineFrom", $path) + @($RestArgs | Select-Object -Skip 1)
}
& $script @RestArgs
exit $LASTEXITCODE
