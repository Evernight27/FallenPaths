# Merge F5 Output into .f5_soak_in.txt and re-run CombatF5SoakLogValidator.
# Usage: .\tools\ci\append_f5_soak_log.ps1 -AppendFrom path\to\chunk.txt [-Label camp5_optional] [-Replace] [-Preflight]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppendFrom,
    [string]$Label = "",
    [switch]$Replace,
    [switch]$Preflight,
    [switch]$SkipPreflight
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resolved = if ([System.IO.Path]::IsPathRooted($AppendFrom)) { $AppendFrom } else { Join-Path $Root $AppendFrom }
$doPreflight = $Preflight -or ((-not $SkipPreflight) -and $Label -match 'camp5|camp_section')
if ($doPreflight) {
    $step9Only = $Label -match 'camp5_step9'
    $result = if ($step9Only) { Test-F5Step9FollowupLog $resolved } else { Test-F5FollowupLog $resolved }
    if (-not $result.ok) {
        if ($result.fatal_errors) {
            Write-Host "Preflight FAIL - FP_ERROR or SCRIPT_ERROR in $resolved"
        } elseif ($step9Only) {
            Write-Host "Preflight FAIL - need at least one step-9 marker in $resolved"
        } else {
            Write-Host "Preflight FAIL - missing required markers in $resolved :"
            foreach ($miss in $result.missing) { Write-Host "  [MISS] $miss" }
        }
        $pf = if ($step9Only) { ".\tools\ci\preflight_f5_followup.ps1 $AppendFrom -Step9Only" } else { ".\tools\ci\preflight_f5_followup.ps1 $AppendFrom" }
        Write-Host "Run: $pf"
        exit 1
    }
    Write-Host "Preflight: PASS ($resolved)"
}
& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -AppendFrom $AppendFrom -Label $Label -Replace:$Replace
$code = $LASTEXITCODE
if ($code -eq 0 -and $Label -ne "") {
    $bak = Get-F5SoakBackupPath $Root
    $log = Get-F5SoakLogPath $Root
    if (Test-F5SoakShouldPreserve $log) {
        Copy-Item -LiteralPath $log -Destination $bak -Force
        Write-Host "Updated backup -> $bak ($((Get-Item $bak).Length) bytes)"
    }
}
exit $code
