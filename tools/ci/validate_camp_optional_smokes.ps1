# Headless validator regression for docs/camp_optional_step_smokes/*.txt (Playtest stream).
# One Godot session validates all smokes + human paste (.f5_soak_validation.txt).
param(
    [switch]$Quiet
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$SmokeDir = Join-Path $Root "docs\camp_optional_step_smokes"
$ValPath = Join-Path $Root ".f5_soak_validation.txt"
$BatchPath = Get-F5CampSmokesBatchPath $Root
$HumanLog = Get-F5SoakLogPath $Root

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
if (-not (Invoke-F5CampSmokesBatchGodot -Root $Root -Quiet:$Quiet)) {
    Write-Host "CAMP_OPTIONAL_SMOKES: FAIL (batch report timeout)"
    exit 2
}

$failures = New-Object System.Collections.Generic.List[string]
$passed = 0
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
    $line = Select-String -Path $BatchPath -Pattern "^\[$([regex]::Escape($row.File))\]" | Select-Object -Last 1
    if ($line -and -not $Quiet) {
        Write-Host ("  " + $line.Line.Trim())
    }
    if ($line -and $line.Line -match ' PASS$') {
        $passed++
        if (-not $Quiet) { Write-Host "  [OK] $($row.File) [$($row.Track)]" }
    } else {
        $detail = if ($line) { $line.Line.Trim() } else { "missing batch row" }
        $failures.Add("$($row.File): $detail")
        if (-not $Quiet) { Write-Host "  [FAIL] $($row.File) ($detail)" }
    }
}

if (Test-Path $HumanLog) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "--- human paste validation (.f5_soak_in.txt) ---"
    }
    if (-not (Test-Path $ValPath)) {
        Write-Host "WARN: human paste validation report missing after batch"
    } elseif (-not (Select-String -Path $ValPath -Pattern "^ok=true" -Quiet)) {
        Write-Host "WARN: human paste re-validation ok=false - run .\tools\ci\validate_f5_soak_log.ps1"
    } elseif ((Get-F5ValidatorTrackStatus $ValPath "camp_settlement_continue") -ne "pass") {
        Write-Host "WARN: human paste camp_settlement_continue not PASS after smoke batch"
    } elseif (-not $Quiet) {
        Show-F5ValidationTrackSummary $ValPath -IncludeMeta | Select-Object -Last 8 | ForEach-Object { Write-Host $_ }
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
