# Validate pasted F5 Output for D-001 / II-0 greps (see docs/LIVE_PATHS.md#phase-0-gate).
# Optional: -AppendFrom path merges a log into .f5_soak_in.txt before validate (-Replace overwrites dest).
# -Quiet: no stdout (use for batch wrappers; never pipe this script to Out-Null).
param(
	[string]$LogPath = "",
	[string]$AppendFrom = "",
	[string]$Label = "",
	[switch]$Replace,
	[switch]$Quiet
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
		if (-not $Quiet) { Write-Host "Wrote $InputDefault ($((Get-Item $InputDefault).Length) bytes)" }
	} else {
		$sep = Get-F5SoakAppendSeparator $Label
		Add-Content -LiteralPath $InputDefault -Value "`n$sep`n$chunk" -NoNewline
		if (-not $Quiet) {
			Write-Host "Appended to $InputDefault ($((Get-Item $InputDefault).Length) bytes)"
			if ($Label -ne "") { Write-Host "Append label: $Label" }
		}
	}
	if ($LogPath -eq "") { $LogPath = $InputDefault }
}

if ($LogPath -ne "") {
	$resolved = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }
	if (-not (Test-Path $resolved)) {
		Write-Error "Log file not found: $resolved"
		exit 2
	}
} elseif (-not (Test-Path $InputDefault)) {
	if (-not $Quiet) {
		Write-Host "No log at $InputDefault"
		Write-Host "After F5: copy Output (FP_COMBAT lines) -> save as .f5_soak_in.txt -> re-run this script."
		Write-Host "Smoke (no F5): Copy-Item docs\f5_soak_log.camp_wf.example.txt .f5_soak_in.txt"
		Write-Host "Full optional camp tracks: Copy-Item docs\f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
		Write-Host "Or: .\tools\ci\validate_f5_soak_log.ps1 -LogPath my_fight.log"
		Write-Host "Multi-fight: .\tools\ci\validate_f5_soak_log.ps1 -AppendFrom extra.log"
	}
	exit 2
}

if (-not $Quiet) {
	Write-Host "=== CombatF5SoakLogValidator ==="
}
$envPathSet = $false
if ($LogPath -ne "") {
	$pathToValidate = if ([System.IO.Path]::IsPathRooted($LogPath)) { $LogPath } else { Join-Path $Root $LogPath }
	$resolvedValidate = (Resolve-Path -LiteralPath $pathToValidate).Path
	if (-not $Quiet) { Write-Host "Validating: $resolvedValidate" }
	$env:FP_F5_VALIDATE_LOG = $resolvedValidate
	$envPathSet = $true
} elseif ($LogPath -eq "" -and (Test-Path $InputDefault)) {
	$env:FP_F5_VALIDATE_LOG = (Resolve-Path $InputDefault).Path
	$envPathSet = $true
	if (-not $Quiet) { Write-Host "Validating: $env:FP_F5_VALIDATE_LOG" }
}
$godotExtra = @()
if ($envPathSet) {
	$godotExtra = @("--", $env:FP_F5_VALIDATE_LOG)
}
$reportStamp = Get-F5ValidationReportStamp $ReportPath
try {
	$exitCode = Invoke-F5SoakLogValidateGodot -Root $Root -GodotExtraArgs $godotExtra -SuppressOutput:$Quiet
} finally {
	if ($envPathSet) {
		Remove-Item Env:FP_F5_VALIDATE_LOG -ErrorAction SilentlyContinue
	}
}
if (-not (Wait-F5ValidationReport $ReportPath -NotBeforeUtc $reportStamp)) {
	if (-not $Quiet) { Write-Host "WARN: validation report missing or incomplete after Godot run" }
	$exitCode = 1
}
if (-not $Quiet -and (Test-Path $ReportPath)) {
	Write-Host ""
	Write-Host "--- Report: $ReportPath ---"
	Get-Content $ReportPath
	$profilesLine = Select-String -Path $ReportPath -Pattern "^profiles=" | Select-Object -First 1
	if ($profilesLine -and $profilesLine.Line -match "camp_ea" -and (Test-Path $InputDefault) -and (Test-F5SoakHeadlessCaptureOnly $InputDefault)) {
		Write-Host ""
		Write-Host "NOTE: camp_ea profile on headless-only log - paste F5 Output with FP_WORLD markers or restore_f5_soak_log.ps1"
	}
	if ((Test-Path $InputDefault) -and (Test-F5SoakHasFatalErrors $InputDefault)) {
		Write-Host ""
		Write-Host "NOTE: FP_ERROR or SCRIPT_ERROR in log - fix before F5 validator merge"
	}
	if ((Test-Path $InputDefault) -and (Test-F5SoakIsExampleSmoke $InputDefault)) {
		Write-Host ""
		Write-Host "NOTE: docs example smoke - automated minimum only; Camp-5 human tick needs real F5 paste (run_camp_f5_closeout.ps1 -HumanSignOff)"
	}
	Write-Host ""
	Write-Host "--- Camp / WF-M3 track summary ---"
	Show-F5ValidationTrackSummary $ReportPath
	if (-not (Select-String -Path $ReportPath -Pattern '^\[(camp_|wf_m3_)' -Quiet)) {
		Write-Host "(no camp_ or wf_m3_ tracks - combat-only paste or missing turn_ready_gauge / settlement markers)"
	}
}
exit $exitCode
