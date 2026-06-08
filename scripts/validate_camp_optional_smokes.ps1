# Headless validator regression for docs/camp_optional_step_smokes/*.txt (Playtest stream).
# Does not touch .f5_soak_in.txt; re-validates human paste at end when present.
param(
	[switch]$Quiet
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent $PSScriptRoot
$SmokeDir = Join-Path $Root "docs\camp_optional_step_smokes"
$ValPath = Join-Path $Root ".f5_soak_validation.txt"
$HumanLog = Get-F5SoakLogPath $Root
$ValidateScript = Join-Path $PSScriptRoot "validate_f5_soak_log.ps1"

$smokes = @(
	@{ File = "step3e_mopup.txt"; Track = "camp_mopup_strike_finish" },
	@{ File = "step4_field_care_action.txt"; Track = "camp_field_care_action" },
	@{ File = "step8_paid_loss.txt"; Track = "camp_paid_loss" },
	@{ File = "step8_tutorial_soft.txt"; Track = "camp_tutorial_soft_loss" },
	@{ File = "step9_wage_warn.txt"; Track = "camp_wage_warn" },
	@{ File = "step9_desertion.txt"; Track = "camp_desertion" },
	@{ File = "step10_party_triage.txt"; Track = "camp_party_triage" },
	@{ File = "medical_exit.txt"; Track = "camp_medical_exit" }
)

if (-not (Test-Path $SmokeDir)) {
	Write-Error "Smoke dir missing: $SmokeDir"
	exit 2
}

Write-Host "=== Camp optional step smokes (CombatF5SoakLogValidator) ==="
$failures = New-Object System.Collections.Generic.List[string]
$passed = 0

function Test-F5SmokeValidationOk {
	param(
		[string]$SmokePath,
		[string]$ValPath,
		[string]$TrackId,
		[ref]$ExitCode
	)
	$stamp = Get-F5ValidationReportStamp $ValPath
	& $ValidateScript -LogPath $SmokePath -Quiet
	$ExitCode.Value = $LASTEXITCODE
	if (Wait-F5ValidationReport $ValPath -NotBeforeUtc $stamp) {
		return $true
	}
	Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 1
	$retryStamp = Get-F5ValidationReportStamp $ValPath
	& $ValidateScript -LogPath $SmokePath -Quiet
	$ExitCode.Value = $LASTEXITCODE
	return (Wait-F5ValidationReport $ValPath -NotBeforeUtc $retryStamp)
}

foreach ($row in $smokes) {
	$path = Join-Path $SmokeDir $row.File
	if (-not (Test-Path $path)) {
		$failures.Add("$($row.File): missing file")
		if (-not $Quiet) { Write-Host "  [FAIL] $($row.File) - file not found" }
		continue
	}
	if (-not $Quiet) {
		Write-Host ""
		Write-Host "--- $($row.File) -> [$($row.Track)] ---"
	}
	$exitCode = 0
	if (-not (Test-F5SmokeValidationOk -SmokePath $path -ValPath $ValPath -TrackId $row.Track -ExitCode ([ref]$exitCode))) {
		$failures.Add("$($row.File): validation report timeout")
		if (-not $Quiet) { Write-Host "  [FAIL] $($row.File) (validation report timeout)" }
		continue
	}
	if (-not $Quiet) {
		$trackLine = Select-String -Path $ValPath -Pattern "^\[$([regex]::Escape($row.Track))\] " | Select-Object -Last 1
		if ($trackLine) { Write-Host ("  " + $trackLine.Line.Trim()) }
	}
	$okLine = Select-String -Path $ValPath -Pattern "^ok=true" -Quiet
	$trackStatus = Get-F5ValidatorTrackStatus $ValPath $row.Track
	if ($okLine -and $trackStatus -eq "pass") {
		$passed++
		if (-not $Quiet) { Write-Host "  [OK] $($row.File) [$($row.Track)]" }
	} else {
		$detail = "exit=$exitCode ok=$okLine track=$trackStatus"
		$failures.Add("$($row.File): $detail")
		if (-not $Quiet) { Write-Host "  [FAIL] $($row.File) ($detail)" }
	}
}

if (Test-Path $HumanLog) {
	$humanStamp = Get-F5ValidationReportStamp $ValPath
	if ($Quiet) {
		& $ValidateScript -LogPath $HumanLog -Quiet
	} else {
		Write-Host ""
		Write-Host "--- restore human paste validation (.f5_soak_in.txt) ---"
		& $ValidateScript -LogPath $HumanLog -Quiet
	}
	if (-not (Wait-F5ValidationReport $ValPath -NotBeforeUtc $humanStamp)) {
		Write-Host "WARN: human paste re-validation report timeout"
	} elseif (-not (Select-String -Path $ValPath -Pattern "^ok=true" -Quiet)) {
		Write-Host "WARN: human paste re-validation ok=false - run .\scripts\validate_f5_soak_log.ps1"
	} elseif ((Get-F5ValidatorTrackStatus $ValPath "camp_settlement_continue") -ne "pass") {
		Write-Host "WARN: human paste camp_settlement_continue not PASS after smoke batch"
	} else {
		if (-not $Quiet) {
			Show-F5ValidationTrackSummary $ValPath -IncludeMeta | Select-Object -Last 8 | ForEach-Object { Write-Host $_ }
		}
	}
	if ((Test-Path $ValPath) -and (Select-String -Path $ValPath -Pattern "^ok=true" -Quiet)) {
		if (Test-F5Exp02OptionalTracksPass $ValPath) {
			Write-Host "EXP_0_2_OPTIONAL: PASS (steps 4, 8 paid loss, 9 wage/desertion, 10 triage)"
		} else {
			Write-Host "EXP_0_2_OPTIONAL: FAIL (human paste missing one or more Exp-0.2 optional tracks)"
			$failures.Add("human paste: Exp-0.2 optional tracks incomplete")
		}
	}
}

Write-Host ""
Write-Host "=== Camp optional smokes summary ==="
Write-Host ("passed: $passed / $($smokes.Count)")
if ($failures.Count -gt 0) {
	foreach ($f in $failures) { Write-Host ("  FAIL: " + $f) }
	exit 1
}
Write-Host "CAMP_OPTIONAL_SMOKES: PASS"
exit 0
