# Print Phase 0 / D-001 gate artifacts (no Godot).
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "Docs: docs/CURSOR.md | docs/SHIP_PLAN.md#camp-playtest-acceptance (F5 §8) | docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers | scripts/README.md"
Write-Host "Streams: Combat (Phase 0 + Camp-3.4 tail) | Playtest F5 §8 / Q1/Q2 | Expand after Camp-5"
Write-Host "Q headless (no F5): .\scripts\run_q_audit.ps1 -Track Track  (+ -Track Q1)"
Write-Host "Q feel (F5): .\scripts\run_q_feel.ps1 -Track Camp|Q1|Q2"
Write-Host "Fast harness: .\scripts\run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical"
Write-Host ""

function Show-File($Path, $Label) {
	if (-not (Test-Path $Path)) {
		Write-Host "[$Label] (missing) $Path"
		return
	}
	Write-Host "=== $Label ==="
	Get-Content $Path | Select-Object -First 30
	Write-Host ""
}

Show-File (Join-Path $Root ".phase0_combat_checks.txt") "phase0"
$phase0Path = Join-Path $Root ".phase0_combat_checks.txt"
if ((Test-Path $phase0Path) -and -not (Select-String -Path $phase0Path -Pattern "^COMPANY_STATE: PASS" -Quiet)) {
	Write-Host "WARN: phase0 summary missing COMPANY_STATE: PASS - re-run run_all_combat_checks.ps1"
	Write-Host ""
}
$campaignAuditPath = Join-Path $Root ".campaign_ship_audit.txt"
if (Test-Path $campaignAuditPath) {
	Show-File $campaignAuditPath "campaign_ship_audit"
} elseif ((Test-Path $phase0Path) -and (Select-String -Path $phase0Path -Pattern "^PHASE0: PASS" -Quiet)) {
	if (-not (Select-String -Path $phase0Path -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet)) {
		Write-Host "WARN: PHASE0 PASS but no CAMPAIGN_SHIP_AUDIT - re-run run_all_combat_checks.ps1 (Camp-3.4 tail)"
		Write-Host ""
	}
}
$signoffPath = Join-Path $Root ".d001_headless_signoff.txt"
if ((Test-Path $phase0Path) -and (Select-String -Path $phase0Path -Pattern "^PHASE0: PASS" -Quiet)) {
	if ((Test-Path $signoffPath) -and -not (Select-String -Path $signoffPath -Pattern "^ok=true" -Quiet)) {
		Write-Host "WARN: .phase0_combat_checks.txt says PASS but .d001_headless_signoff.txt is not ok=true - re-run run_all_combat_checks.ps1"
		Write-Host ""
	}
	$calWarn = Join-Path $Root ".calibration_audit.txt"
	if ((Test-Path $calWarn) -and -not (Select-String -Path $calWarn -Pattern "^ok=true" -Quiet)) {
		Write-Host "WARN: .phase0_combat_checks.txt says PASS but .calibration_audit.txt is not ok=true - re-run run_all_combat_checks.ps1"
		Write-Host ""
	}
}
$medicalLog = Join-Path $Root ".medical_phase_harness_out.txt"
if (Test-Path $medicalLog) {
	Write-Host "=== medical fast harness (last FP_HARNESS lines) ==="
	Select-String -Path $medicalLog -Pattern "^FP_HARNESS_" | Select-Object -Last 5 | ForEach-Object { $_.Line }
	Write-Host ""
}
Show-File $signoffPath "headless_signoff"
$soak = Join-Path $Root ".d001_soak_out.txt"
	if (Test-Path $soak) {
	Write-Host "=== d001_soak (grep ok / ii4d / ii2b) ==="
	Select-String -Path $soak -Pattern "^ok=|^\[ii2b\]|^\[ii4d\]|^\[ii7\]|^\[ii_envelop\]|^\[formation_move_f5\]|ii2b_plausibility|ii4d_plausibility|exhaustion_stats|parry_stats" | ForEach-Object { $_.Line }
	Write-Host ""
}
$qTrack = Join-Path $Root ".q_track_audits.txt"
if (Test-Path $qTrack) {
	Write-Host "=== q_track_audits (summary) ==="
	Select-String -Path $qTrack -Pattern "^\[Q|plausibility=pass|BOUNDARY_FAIL|f5_only=" | ForEach-Object { $_.Line }
	Write-Host ""
}
$q2 = Join-Path $Root ".q2_ii2b_feel_audit.txt"
if (Test-Path $q2) {
	Write-Host "=== q2_ii2b_feel_audit (last 8 lines) ==="
	Get-Content $q2 | Select-Object -Last 8
	Write-Host ""
}
$calPath = Join-Path $Root ".calibration_audit.txt"
if (Test-Path $calPath) {
	Show-File $calPath "calibration_audit (first 30 lines)"
	Write-Host "=== calibration_audit (species grep) ==="
	Select-String -Path $calPath -Pattern 'species_|human_|goblin_|pain_reference' | ForEach-Object { $_.Line }
	Write-Host ""
	Write-Host '=== calibration_audit ([research_benchmarks] summary) ==='
	$inResearch = $false
	foreach ($line in Get-Content $calPath) {
		if ($line -eq "[research_benchmarks]") { $inResearch = $true; continue }
		if ($inResearch -and $line -match '^\[') { break }
		if ($inResearch -and ($line -match '^research_|^production_headless|^medical_triage_danger|^ATLS_TTD|^research_verdict')) {
			Write-Host $line
		}
	}
	Write-Host ""
	Write-Host "=== calibration_audit (f5 headless) ==="
	Select-String -Path $calPath -Pattern '^\[f5_scenario|forearm_graze|armored_chest|mace_elbow|F5_editor' | ForEach-Object { $_.Line }
	Write-Host ""
} else {
	Show-File $calPath "calibration_audit"
}
