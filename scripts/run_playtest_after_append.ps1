# Append F5 chunk then safe re-validate (Playtest stream — no Phase 0).
param(
	[Parameter(Mandatory = $true)]
	[string]$AppendFrom,
	[string]$Label = "",
	[switch]$HumanSignOff,
	[switch]$SkipCloseout
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "=== Playtest after append (no Phase 0) ==="
Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
$appendArgs = @{ AppendFrom = $AppendFrom }
if ($Label -ne "") { $appendArgs.Label = $Label }
& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") @appendArgs
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_AFTER_APPEND: FAIL (append)"
	exit $LASTEXITCODE
}

$revalidateArgs = @("-SkipSmokes")
if ($HumanSignOff) { $revalidateArgs += "-HumanSignOff" }
if ($SkipCloseout) { $revalidateArgs += "-SkipCloseout" }
& (Join-Path $PSScriptRoot "run_playtest_revalidate.ps1") @revalidateArgs
if ($LASTEXITCODE -ne 0) {
	Write-Host "PLAYTEST_AFTER_APPEND: FAIL (revalidate)"
	exit $LASTEXITCODE
}

$log = Get-F5SoakLogPath $Root
Show-F5SmokeAppendSummary -LogPath $log
Write-Host "PLAYTEST_AFTER_APPEND: PASS"
Write-Host "Next: .\scripts\run_playtest_full_gate.ps1 -HumanSignOff (optional smokes batch)"
exit 0
