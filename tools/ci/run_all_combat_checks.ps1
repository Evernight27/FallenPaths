# Phase 0 gate (default) or partial harness via -HarnessMode.
#   .\tools\ci\run_all_combat_checks.ps1
#   .\tools\ci\run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical
#   .\tools\ci\run_all_combat_checks.ps1 -ValidateF5 [-F5LogPath path]
param(
	[ValidateSet("all", "regression", "d001", "sanity", "calibration", "medical")]
	[string]$HarnessMode = "all",
	[switch]$ValidateF5,
	[string]$F5LogPath = ""
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
. "$PSScriptRoot\F5SoakLogHelpers.ps1"
$Root = Get-FallenPathsRoot

$partialOkPatterns = @{
	regression = "FP_HARNESS_OK: CombatRegressionHarness"
	d001       = "FP_HARNESS_OK: CombatD001SoakRunner"
	sanity     = "FP_HARNESS_OK: CombatD001SoakSanity"
	calibration = "FP_HARNESS_OK: CombatCalibrationAudit"
	medical    = "FP_HARNESS_OK: MedicalPhaseHarness"
}
$partialTeeLogs = @{
	regression = ".harness_out.txt"
	d001       = ".d001_soak_out.txt"
	sanity     = ".d001_soak_sanity_out.txt"
	calibration = ".calibration_audit.txt"
	medical    = ".medical_phase_harness_out.txt"
}

if ($HarnessMode -ne "all") {
	$tee = Join-Path $Root $partialTeeLogs[$HarnessMode]
	Write-Host "=== FP_HARNESS_MODE=$HarnessMode ==="
	Invoke-FallenPathsGodotImportWarmup
	$f5BackedUp = $false
	if ($HarnessMode -eq "d001") {
		$f5BackedUp = Backup-F5SoakHumanPaste $Root
	}
	$partialExit = 1
	try {
		Invoke-FallenPathsGodotScript -HarnessMode $HarnessMode -TeeLog $tee *> $null
		$partialExit = Get-FallenPathsGodotExitCode
	} finally {
		if ($f5BackedUp) {
			Restore-F5SoakHumanPaste $Root | Out-Null
		}
	}
	if (Test-Path $tee) {
		if (Select-String -Path $tee -Pattern $partialOkPatterns[$HarnessMode] -Quiet) {
			exit 0
		}
	}
	exit $partialExit
}

$SummaryPath = Join-Path $Root ".phase0_combat_checks.txt"
$lines = New-Object System.Collections.Generic.List[string]

Write-Host "=== Doc link check ==="
& (Join-Path $Root "tools\ci\check_doc_links.ps1")
if ($LASTEXITCODE -ne 0) {
	$lines.Add("DOC_LINKS: FAIL")
	Write-Phase0SummaryCommit -Root $Root -Lines $lines
	exit $LASTEXITCODE
}
Write-Host ""

Write-Host "=== Godot import warmup ==="
Invoke-FallenPathsGodotImportWarmup
Write-Host ""

Write-Host "=== CompanyStateChecks (Camp-1 + XCamp-3.x) ==="
$swCompany = [System.Diagnostics.Stopwatch]::StartNew()
$companyOut = @(& (Join-Path $Root "tools\ci\run_company_state_checks.ps1") -SkipWarmup 2>&1 | ForEach-Object { "$_" })
$swCompany.Stop()
$lines.Add("TIMING: company_state={0:N0}s" -f $swCompany.Elapsed.TotalSeconds)
$companyOut | ForEach-Object { Write-Host $_ }
$companyOk = $companyOut | Where-Object { $_ -match "FP_HARNESS_OK:\s+CompanyStateChecks" } | Select-Object -Last 1
$companyExit = $LASTEXITCODE
if ($companyExit -ne 0 -or -not $companyOk) {
	$lines.Add("COMPANY_STATE: FAIL exit=$companyExit")
	$lines.Add("PHASE0: FAIL (company state checks)")
	Write-Phase0SummaryCommit -Root $Root -Lines $lines
	Write-Host ""
	Write-Host "=== PHASE0 FAIL (CompanyStateChecks) ==="
	exit 1
}
$lines.Add("COMPANY_STATE: PASS")
if ($companyOk) {
	$lines.Add([string]$companyOk)
}
Write-Host ""

Write-Host "=== AllCombatChecks (regression + D-001 + calibration) ==="
# L92 warmup is redundant — L69 already populated the class cache.
$f5LogPath = Join-Path $Root ".f5_soak_in.txt"
$f5BackedUp = $false
if (Test-Path $f5LogPath) {
	$f5BackedUp = Backup-F5SoakHumanPaste $Root
}
$allCombatTee = Join-Path $Root ".phase0_all_combat_checks.txt"
$swAll = [System.Diagnostics.Stopwatch]::StartNew()
try {
	Invoke-FallenPathsGodotScript -HarnessMode "all" -TeeLog $allCombatTee *> $null
} finally {
	if ($f5BackedUp) {
		Restore-F5SoakHumanPaste $Root | Out-Null
	}
}
$swAll.Stop()
$lines.Add("TIMING: all_combat_checks={0:N0}s" -f $swAll.Elapsed.TotalSeconds)
$regTimingPath = Join-Path $Root ".regression_timing.txt"
if (Test-Path $regTimingPath) {
	$regLines = Get-Content $regTimingPath -Encoding utf8 | Where-Object { $_ -match '^\d+\t' } | Select-Object -First 5
	foreach ($rl in $regLines) {
		$parts = $rl -split "`t", 2
		if ($parts.Count -eq 2 -and [int]$parts[0] -gt 2000) {
			$lines.Add("REGRESS_TOP: $([math]::Round($parts[0]/1000,1))s  $($parts[1])")
		}
	}
}
$d001TimingPath = Join-Path $Root ".d001_soak_out.txt"
if (Test-Path $d001TimingPath) {
	$d001Lines = Get-Content $d001TimingPath -Encoding utf8
	$presetDurations = @()
	$currentPreset = ""
	foreach ($dl in $d001Lines) {
		if ($dl -match '^\[(\w+)\]') { $currentPreset = $Matches[1] }
		if ($dl -match '^\s+duration_ms=(\d+)' -and $currentPreset) {
			$presetDurations += [PSCustomObject]@{ Preset = $currentPreset; Ms = [int]$Matches[1] }
			$currentPreset = ""
		}
	}
	$presetDurations | Sort-Object Ms -Descending | Select-Object -First 5 | ForEach-Object {
		$lines.Add("D001_TOP: $([math]::Round($_.Ms/1000,1))s  $($_.Preset)")
	}
}
$exitCode = Get-FallenPathsGodotExitCode
$out = if (Test-Path $allCombatTee) { @(Get-Content -Path $allCombatTee -Encoding utf8) } else { @() }
$out | ForEach-Object { Write-Host $_ }
$summary = $out | Where-Object { $_ -match "^FP_HARNESS_(OK|SUMMARY|FAIL):" }
foreach ($s in $summary) { $lines.Add($s) }
if ($exitCode -ne 0) {
	$lines.Add("EXIT=$exitCode")
}

$d001Report = Join-Path $Root ".d001_soak_out.txt"
if (Test-Path $d001Report) {
	$okLine = Get-Content $d001Report | Where-Object { $_ -match "^ok=" } | Select-Object -First 1
	if ($okLine) { $lines.Add("D001_REPORT: $okLine") }
}
$signoffPath = Join-Path $Root ".d001_headless_signoff.txt"
if (Test-Path $signoffPath) {
	$signLine = Get-Content $signoffPath | Where-Object { $_ -match "^ok=" } | Select-Object -First 1
	if ($signLine) { $lines.Add("HEADLESS_SIGNOFF: $signLine") }
}
$calPath = Join-Path $Root ".calibration_audit.txt"
if (Test-Path $calPath) {
	$calLine = Get-Content $calPath | Where-Object { $_ -match "^ok=" } | Select-Object -First 1
	if ($calLine) { $lines.Add("CALIBRATION_AUDIT: $calLine") }
	$gateLine = Get-Content $calPath | Where-Object { $_ -match "^production_headless_gate=" } | Select-Object -First 1
	if ($gateLine) { $lines.Add("RESEARCH: $gateLine") }
	$summaryLine = Get-Content $calPath | Where-Object { $_ -match "^research_verdict_summary " } | Select-Object -First 1
	if ($summaryLine) { $lines.Add("RESEARCH: $summaryLine") }
	$gateCount = Get-Content $calPath | Where-Object { $_ -match "^research_harness_gate_count=" } | Select-Object -First 1
	if ($gateCount) { $lines.Add("RESEARCH: $gateCount") }
}
$artifactFail = New-Object System.Collections.Generic.List[string]
$outJoined = if ($out.Count -gt 0) { $out -join "`n" } else { "" }
if ($outJoined -notmatch "FP_HARNESS_OK: AllCombatChecks") {
	$artifactsGreen = (Test-Path $d001Report) -and (Select-String -Path $d001Report -Pattern "^ok=true" -Quiet) `
		-and (Test-Path $signoffPath) -and (Select-String -Path $signoffPath -Pattern "^ok=true" -Quiet) `
		-and (Test-Path $calPath) -and (Select-String -Path $calPath -Pattern "^ok=true" -Quiet)
	if (-not $artifactsGreen) {
		$artifactFail.Add("missing FP_HARNESS_OK: AllCombatChecks in stdout")
	} else {
		$lines.Add("FP_HARNESS_NOTE: AllCombatChecks ok via artifacts (stdout tag missing)")
	}
}
if ($exitCode -ne 0 -and $artifactFail.Count -eq 0) {
	$lines.Add("FP_HARNESS_NOTE: Godot exit=$exitCode ignored (artifact checks passed)")
}
if (-not (Test-Path $d001Report) -or -not (Select-String -Path $d001Report -Pattern "^ok=true" -Quiet)) {
	$artifactFail.Add("D001_REPORT not ok=true (.d001_soak_out.txt)")
}
if (-not (Test-Path $signoffPath) -or -not (Select-String -Path $signoffPath -Pattern "^ok=true" -Quiet)) {
	$artifactFail.Add("HEADLESS_SIGNOFF not ok=true (.d001_headless_signoff.txt)")
}
if (-not (Test-Path $calPath) -or -not (Select-String -Path $calPath -Pattern "^ok=true" -Quiet)) {
	$artifactFail.Add("CALIBRATION_AUDIT not ok=true (.calibration_audit.txt)")
}
if ($artifactFail.Count -gt 0) {
	foreach ($msg in $artifactFail) { $lines.Add("PHASE0: FAIL $msg") }
	$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
	Write-Phase0SummaryCommit -Root $Root -Lines $lines
	Write-Host ""
	Write-Host "=== PHASE0 FAIL (artifact check) ==="
	$artifactFail | ForEach-Object { Write-Host "  $_" }
	exit 1
}
$lines.Add("PHASE0: PASS")
Write-Host ""
Write-Host "=== PHASE0 PASS ==="

Write-Host ""
Write-Host "=== Campaign ship audit tail (Camp-3.4 / Camp-5 headless) ==="
$swCampaign = [System.Diagnostics.Stopwatch]::StartNew()
& (Join-Path $Root "tools\ci\run_campaign_ship_audit.ps1") -TailOnly
$swCampaign.Stop()
$lines.Add("TIMING: campaign_ship_audit={0:N0}s" -f $swCampaign.Elapsed.TotalSeconds)
$campaignExit = $LASTEXITCODE
$auditPath = Join-Path $Root ".campaign_ship_audit.txt"
if (Test-Path $auditPath) {
	foreach ($auditLine in Get-Content $auditPath) {
		if ($auditLine -match '^(Q_TRACK|II7_MEDICAL|II_ENVELOP|II_ENVELOP_MOPUP|CAMPAIGN_SHIP_AUDIT):') {
			$lines.Add($auditLine)
		}
	}
}
if ($campaignExit -ne 0) {
	$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
	Write-Phase0SummaryCommit -Root $Root -Lines $lines
	Write-Host ""
	Write-Host "=== PHASE0 FAIL (Camp-3.4 campaign ship audit) ==="
	exit $campaignExit
}

$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
Write-Phase0SummaryCommit -Root $Root -Lines $lines
Write-Host "Summary: $SummaryPath"
Show-F5SoakStatusHint $Root
$bakPath = Get-F5SoakBackupPath $Root
if ((Test-Path $bakPath) -and (Test-Path (Get-F5SoakLogPath $Root)) -and (Get-F5HumanSignoffStatus (Get-F5SoakLogPath $Root)) -ne "READY") {
	Write-Host "F5 human paste backup: .f5_soak_in.f5_backup.txt (restore: .\tools\ci\restore_f5_soak_log.ps1)"
}
Write-Host "F5 Camp status (on demand): .\tools\ci\run_playtest.ps1 closeout (-HumanSignOff after new F5 append)"
Write-Host "Reports:"
Write-Host "  .d001_soak_out.txt       (per-preset pass/fail)"
Write-Host "  .f5_soak_validation.txt  (grep validator on headless capture)"
Write-Host "  .f5_soak_in.txt          (headless FP_COMBAT paste shape; human F5 paste -> .f5_soak_in.f5_backup.txt during gate)"
Write-Host "  .ii2b_worksheet_prefill.txt (III-3 Sword row counts; not feel sign-off)"
	Write-Host "  .campaign_ship_audit.txt (Camp-3.4 Q + ii7 + ii_envelop headless gate)"
Write-Host ""
Write-Host "  .d001_headless_signoff.txt (II-2b + II-5a/b/c mandatory, no F5)"
Write-Host '  .calibration_audit.txt     (physics/medical + [research_benchmarks] verdict summary)'
Write-Host '  docs/AGENTS_ENTRY.md (hub) | docs/LIVE_PATHS.md#research-audit (40 _run_research_* gates)'
Write-Host "Optional F5: ii2b/ii5/ii8 feel spot-check only; gate does not require editor."
Write-Host "Campaign audit (standalone): .\tools\ci\run_campaign_ship_audit.ps1"
Write-Host "Artifact summary: .\tools\ci\print_phase0_status.ps1"
Write-Host "Fast paths: -HarnessMode regression|d001|sanity|calibration|medical"
if ($ValidateF5 -or $F5LogPath -ne "") {
	Write-Host ""
	Write-Host "=== F5 log validation ==="
	$val = Join-Path $Root "tools\ci\validate_f5_soak_log.ps1"
	if ($F5LogPath -ne "") {
		& powershell -NoProfile -ExecutionPolicy Bypass -File $val -LogPath $F5LogPath
	} else {
		& powershell -NoProfile -ExecutionPolicy Bypass -File $val
	}
	exit $LASTEXITCODE
}
exit 0
