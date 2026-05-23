# Phase 0 gate (default) or partial harness via -HarnessMode.
#   .\scripts\run_all_combat_checks.ps1
#   .\scripts\run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical
#   .\scripts\run_all_combat_checks.ps1 -ValidateF5 [-F5LogPath path]
param(
	[ValidateSet("all", "regression", "d001", "sanity", "calibration", "medical")]
	[string]$HarnessMode = "all",
	[switch]$ValidateF5,
	[string]$F5LogPath = ""
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
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
	Invoke-FallenPathsGodotScript -HarnessMode $HarnessMode -TeeLog $tee | Out-Null
	if (Test-Path $tee) {
		if (Select-String -Path $tee -Pattern $partialOkPatterns[$HarnessMode] -Quiet) {
			exit 0
		}
	}
	exit $LASTEXITCODE
}

$SummaryPath = Join-Path $Root ".phase0_combat_checks.txt"
$lines = New-Object System.Collections.Generic.List[string]

Write-Host "=== Doc link check ==="
& (Join-Path $Root "scripts\check_doc_links.ps1")
if ($LASTEXITCODE -ne 0) {
	$lines.Add("DOC_LINKS: FAIL")
	$lines | Set-Content -Path $SummaryPath -Encoding utf8
	exit $LASTEXITCODE
}
Write-Host ""

Write-Host "=== AllCombatChecks (regression + D-001 + calibration) ==="
$Godot = Get-FallenPathsGodot
$env:FP_HARNESS_MODE = "all"
try {
	$out = @(& $Godot --headless --path $Root -s "res://scripts/run_all_combat_checks.gd" 2>&1 | ForEach-Object { "$_" })
} finally {
	Remove-Item Env:FP_HARNESS_MODE -ErrorAction SilentlyContinue
}
$exitCode = $LASTEXITCODE
$out | ForEach-Object { Write-Host $_ }
$summary = $out | Where-Object { $_ -match "^FP_HARNESS_(OK|SUMMARY|FAIL):" }
foreach ($s in $summary) { $lines.Add($s) }
if ($exitCode -ne 0) {
	$lines.Add("EXIT=$exitCode")
	$lines | Set-Content -Path $SummaryPath -Encoding utf8
	exit $exitCode
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
	$artifactsGreen = ($exitCode -eq 0) `
		-and (Test-Path $d001Report) -and (Select-String -Path $d001Report -Pattern "^ok=true" -Quiet) `
		-and (Test-Path $signoffPath) -and (Select-String -Path $signoffPath -Pattern "^ok=true" -Quiet) `
		-and (Test-Path $calPath) -and (Select-String -Path $calPath -Pattern "^ok=true" -Quiet)
	if (-not $artifactsGreen) {
		$artifactFail.Add("missing FP_HARNESS_OK: AllCombatChecks in stdout")
	} else {
		$lines.Add("FP_HARNESS_NOTE: AllCombatChecks ok via artifacts (stdout tag missing)")
	}
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
	$lines | Set-Content -Path $SummaryPath -Encoding utf8
	Write-Host ""
	Write-Host "=== PHASE0 FAIL (artifact check) ==="
	$artifactFail | ForEach-Object { Write-Host "  $_" }
	exit 1
}
$lines.Add("PHASE0: PASS")
$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines | Set-Content -Path $SummaryPath -Encoding utf8
Write-Host ""
Write-Host "=== PHASE0 PASS ==="
Write-Host "Summary: $SummaryPath"
Write-Host "Reports:"
Write-Host "  .d001_soak_out.txt       (per-preset pass/fail)"
Write-Host "  .f5_soak_validation.txt  (grep validator on headless capture)"
Write-Host "  .f5_soak_in.txt          (headless FP_COMBAT paste shape)"
Write-Host "  .ii2b_worksheet_prefill.txt (III-3 Sword row counts; not feel sign-off)"
Write-Host ""
Write-Host "  .d001_headless_signoff.txt (II-2b + II-5a/b/c mandatory, no F5)"
Write-Host '  .calibration_audit.txt     (physics/medical + [research_benchmarks] verdict summary)'
Write-Host '  docs/CURSOR.md (hub) | docs/LIVE_PATHS.md#research-audit (35 _run_research_* gates)'
Write-Host "Optional F5: ii2b/ii5/ii8 feel spot-check only; gate does not require editor."
Write-Host "Optional Q audits (headless): .\scripts\run_q_audit.ps1 -Track Track"
Write-Host "Artifact summary: .\scripts\print_phase0_status.ps1"
Write-Host "Fast paths: -HarnessMode regression|d001|sanity|calibration|medical"
if ($ValidateF5 -or $F5LogPath -ne "") {
	Write-Host ""
	Write-Host "=== F5 log validation ==="
	$val = Join-Path $Root "scripts\validate_f5_soak_log.ps1"
	if ($F5LogPath -ne "") {
		& powershell -NoProfile -ExecutionPolicy Bypass -File $val -LogPath $F5LogPath
	} else {
		& powershell -NoProfile -ExecutionPolicy Bypass -File $val
	}
	exit $LASTEXITCODE
}
exit 0
