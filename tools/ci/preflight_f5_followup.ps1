# Grep followup F5 Output chunk before append (Camp-5 optional tracks).
# Usage: .\tools\ci\preflight_f5_followup.ps1 followup.log
#        .\tools\ci\preflight_f5_followup.ps1 step9.log -Step9Only
param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,
    [switch]$Step9Only
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resolved = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }
if (-not (Test-Path $resolved)) {
    Write-Error "Log file not found: $resolved"
    exit 2
}
Write-Host "=== Preflight: $resolved ==="
$result = if ($Step9Only) { Test-F5Step9FollowupLog $resolved } else { Test-F5FollowupLog $resolved }
$patterns = if ($Step9Only) { Get-F5Step9PreflightPatterns } else { Get-F5FollowupPreflightPatterns }
foreach ($row in $patterns) {
    if (Select-String -Path $resolved -Pattern $row.Pattern -Quiet) {
        Write-Host ("  [OK] " + $row.Label)
    } elseif ($row.Required) {
        Write-Host ("  [MISS] " + $row.Label + " (required)")
    } else {
        Write-Host ("  [opt] " + $row.Label + " (optional)")
    }
}
if (Select-String -Path $resolved -Pattern 'soak_coverage camp next' -Quiet) {
    Write-Host "  [hint] chunk contains soak_coverage camp next hints (OK in paste)"
}
if (Test-F5SoakHasFatalErrors $resolved) {
    Write-Host "  [FAIL] FP_ERROR or SCRIPT_ERROR found in chunk"
} else {
    Write-Host "  [OK] no FP_ERROR / SCRIPT_ERROR"
}
Write-Host ""
if ($result.ok) {
    Write-Host "Preflight: PASS - safe to append:"
    if ($Step9Only) {
        Write-Host "  .\tools\ci\append_f5_soak_log.ps1 -AppendFrom $LogPath -Label camp5_step9"
    } else {
        Write-Host "  .\tools\ci\append_f5_soak_log.ps1 -AppendFrom $LogPath -Label camp5_optional"
    }
    exit 0
}
if ($result.fatal_errors) {
    Write-Host "Preflight: FAIL - remove FP_ERROR / SCRIPT_ERROR lines before append"
    exit 1
}
if ($Step9Only) {
    Write-Host "Preflight: FAIL - need at least one step-9 marker (tutorial_failed / company_wages / desertion summary)"
} else {
    Write-Host "Preflight: FAIL - missing required markers (real FP_WORLD lines, not soak_coverage echoes)"
}
exit 1
