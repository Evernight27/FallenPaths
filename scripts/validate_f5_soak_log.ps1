# Validate pasted F5 Output for D-001 / II-0 greps (see docs/LIVE_PATHS.md#phase-0-gate).
# Optional: -AppendFrom path merges a log into .f5_soak_in.txt before validate (-Replace overwrites dest).
param(
	[string]$LogPath = "",
	[string]$AppendFrom = "",
	[switch]$Replace
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Root = Get-FallenPathsRoot
$InputDefault = Join-Path $Root ".f5_soak_in.txt"
$ReportPath = Join-Path $Root ".f5_soak_validation.txt"
$exitCode = 0

if ($AppendFrom -ne "") {
	$resolved = if ([System.IO.Path]::IsPathRooted($AppendFrom)) { $AppendFrom } else { Join-Path $Root $AppendFrom }
	if (-not (Test-Path $resolved)) {
		Write-Error "Source log not found: $resolved"
		exit 2
	}
	$chunk = Get-Content -LiteralPath $resolved -Raw
	if (-not $chunk.EndsWith("`n")) { $chunk += "`n" }
	if ($Replace -or -not (Test-Path $InputDefault)) {
		Set-Content -LiteralPath $InputDefault -Value $chunk -NoNewline
		Write-Host "Wrote $InputDefault ($((Get-Item $InputDefault).Length) bytes)"
	} else {
		Add-Content -LiteralPath $InputDefault -Value "`n--- f5_soak_append ---`n$chunk" -NoNewline
		Write-Host "Appended to $InputDefault ($((Get-Item $InputDefault).Length) bytes)"
	}
	if ($LogPath -eq "") { $LogPath = $InputDefault }
}

$extra = @()
if ($LogPath -ne "") {
	$resolved = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }
	if (-not (Test-Path $resolved)) {
		Write-Error "Log file not found: $resolved"
		exit 2
	}
	$extra = @("--", $resolved)
} elseif (-not (Test-Path $InputDefault)) {
	Write-Host "No log at $InputDefault"
	Write-Host "After F5: copy Output (FP_COMBAT lines) -> save as .f5_soak_in.txt -> re-run this script."
	Write-Host "Smoke (no F5): Copy-Item docs\f5_soak_log.camp_wf.example.txt .f5_soak_in.txt"
	Write-Host "Full optional camp tracks: Copy-Item docs\f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
	Write-Host "Or: .\scripts\validate_f5_soak_log.ps1 -LogPath my_fight.log"
	Write-Host "Multi-fight: .\scripts\validate_f5_soak_log.ps1 -AppendFrom extra.log"
	exit 2
}

Write-Host "=== CombatF5SoakLogValidator ==="
$envPathSet = $false
if ($LogPath -ne "") {
	$resolvedValidate = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }
	Write-Host "Validating: $resolvedValidate"
	$env:FP_F5_VALIDATE_LOG = $resolvedValidate
	$envPathSet = $true
} elseif ($LogPath -eq "" -and (Test-Path $InputDefault)) {
	$env:FP_F5_VALIDATE_LOG = $InputDefault
	$envPathSet = $true
}
try {
	Invoke-FallenPathsGodotScript -HarnessMode f5_validate -GodotExtraArgs $extra | Out-Null
	$exitCode = Get-FallenPathsGodotExitCode
} finally {
	if ($envPathSet) {
		Remove-Item Env:FP_F5_VALIDATE_LOG -ErrorAction SilentlyContinue
	}
}
if (Test-Path $ReportPath) {
	Write-Host ""
	Write-Host "--- Report: $ReportPath ---"
	Get-Content $ReportPath
	Write-Host ""
	Write-Host "--- Camp / WF-M3 track summary ---"
	Select-String -Path $ReportPath -Pattern "^\[(camp_|wf_m3_)" | ForEach-Object { Write-Host $_.Line }
	if (-not (Select-String -Path $ReportPath -Pattern "^\[(camp_|wf_m3_)" -Quiet)) {
		Write-Host "(no camp_ or wf_m3_ tracks - combat-only paste or missing turn_ready_gauge / settlement markers)"
	}
}
exit $exitCode
