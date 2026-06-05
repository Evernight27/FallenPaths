# F5 feel checklist or headless Q audit. -Headless | -Track Q1 | Q2 | Camp
param(
	[switch]$Headless,
	[ValidateSet("Q1", "Q2", "Camp")]
	[string]$Track = ""
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot

function Show-QTrackSection {
	param(
		[string]$Path,
		[string]$StartPattern,
		[string]$EndPattern = ""
	)
	$inSection = $false
	foreach ($line in Get-Content $Path) {
		if ($line -match $StartPattern) { $inSection = $true; Write-Host $line; continue }
		if ($inSection -and $EndPattern -and $line -match $EndPattern) { break }
		if ($inSection) { Write-Host $line }
	}
}

if ($Headless) {
	. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
	Invoke-FallenPathsGodotScript -HarnessMode q_track | Out-Null
	exit $LASTEXITCODE
}

if ($Track -eq "") {
	Write-Error "Use -Headless for Q track audit, or -Track Q1|Q2|Camp for F5 checklist."
	exit 2
}

if ($Track -eq "Camp") {
	Write-Host "=== Track Camp: EA campaign F5 (SHIP_PLAN section 8) ==="
	Write-Host ""
	Write-Host "Prereq: .\scripts\run_all_combat_checks.ps1 -> PHASE0: PASS + CAMPAIGN_SHIP_AUDIT: PASS (headless)"
	Write-Host ""
	Write-Host "1. main.tscn Inspector: dev_soak_encounter EMPTY (campaign mode, no cyan soak tile)"
	Write-Host "2. F5 -> note HUD gold / med / tools / roster"
	Write-Host "3. Green tutorial tile -> win -> settlement pay + wounds -> Continue"
	Write-Host "4. Untreated bleed: tutorial blocks move until first win, then Party warn_eta + field care"
	Write-Host "5. Camp rest (Party menu): -1 med, 600s x3 heal, day advances + wages deduct"
	Write-Host "6. End day at camp (0,0) without med OR 5 map steps -> wages deduct (no heal burst)"
	Write-Host "7. Second paid contract -> renown scales pay"
	Write-Host "8. Lose PAID contract -> CompanyRunEndPanel + main.tscn reload"
	Write-Host "   Lose tutorial/practice -> soft resume + marker respawn"
	Write-Host "9. Low gold -> wage warn, low mood -> desertion risk at day end"
	Write-Host "10. Party menu -> triage lines match last fight"
	Write-Host "11. Medical-phase fight -> Stack medical / self_medical on gauge (optional feel)"
	Write-Host "12. Optional III-4: dev_soak_encounter=ii_envelop -> Skirmish 7v3; grep rotate_file@, Stack hold_line, attempt_close@; validate_f5_soak_log.ps1"
	Write-Host ""
	Write-Host "Sign-off: tick Camp-3.4 human + Camp-5 in docs/SHIP_PLAN.md"
	Write-Host "Docs: docs/SHIP_PLAN.md#camp-playtest-acceptance"
}
elseif ($Track -eq "Q1") {
	Write-Host "=== Track Q1: research_feel duel ==="
	Write-Host ""
	Write-Host "1. PHASE0 green: .\scripts\run_all_combat_checks.ps1"
	Write-Host "2. main.tscn Inspector: dev_soak_encounter=ii2b, dev_research_feel=ON"
	Write-Host "3. F5 -> cyan marker -> fight (>=3 hits)"
	Write-Host "4. Output grep: research_feel, hit_resolve reason=, strike_avoided reason=, soak_fight_end"
	Write-Host "5. Copy Output -> .f5_soak_in.txt -> .\scripts\validate_f5_soak_log.ps1"
	Write-Host ""
	Write-Host "Docs: docs/LIVE_PATHS.md#track-q1--research-feel-duel"
	Write-Host "Headless: .\scripts\run_all_combat_checks.ps1 -HarnessMode q_track -> .q_track_audits.txt ([Q1 research_feel] section)"
	$logPath = Join-Path $Root ".f5_soak_in.txt"
	if (Test-Path $logPath) {
		Write-Host ""
		Write-Host "=== .f5_soak_in.txt (research_feel) ==="
		$lines = Select-String -Path $logPath -Pattern "research_feel|research_validate_hint"
		if ($lines) {
			$lines | ForEach-Object { Write-Host $_.Line }
		} else {
			Write-Host "(no research_feel lines yet)"
		}
		$count = (Select-String -Path $logPath -Pattern "research_feel part=").Count
		Write-Host ""
		Write-Host "research_feel hit lines: $count"
	} else {
		Write-Host "[.f5_soak_in.txt] missing"
	}
	$qTrack = Join-Path $Root ".q_track_audits.txt"
	if (Test-Path $qTrack) {
		Write-Host ""
		Write-Host "=== .q_track_audits.txt ([Q1 research_feel]) ==="
		Show-QTrackSection -Path $qTrack -StartPattern '^\[Q1 research_feel\]'
	}
}
else {
	Write-Host "=== Track Q2: ii2b bind / riposte / flurry feel ==="
	Write-Host ""
	Write-Host "Headless: .\scripts\run_all_combat_checks.ps1 -HarnessMode q_track -> .q_track_audits.txt ([Q2 ii2b] section)"
	Write-Host "F5: dev_soak_encounter=ii2b, grep parry_partial, parry_stats, hit_resolve reason="
	$logPath = Join-Path $Root ".f5_soak_in.txt"
	if (Test-Path $logPath) {
		Write-Host ""
		Write-Host "=== .f5_soak_in.txt (parry / bind / riposte) ==="
		foreach ($pat in @("parry_deflect", "parry_bind", "riposte_chain", "flurry_bind", "parry_stats", "q2_validate_hint")) {
			$hits = Select-String -Path $logPath -Pattern $pat -SimpleMatch
			if ($hits) {
				Write-Host "--- $pat ---"
				$hits | Select-Object -First 6 | ForEach-Object { Write-Host $_.Line }
			}
		}
	} else {
		Write-Host "[.f5_soak_in.txt] missing"
	}
	$qTrack = Join-Path $Root ".q_track_audits.txt"
	if (Test-Path $qTrack) {
		Write-Host ""
		Write-Host "=== .q_track_audits.txt ([Q2 ii2b]) ==="
		Show-QTrackSection -Path $qTrack -StartPattern '^\[Q2 ii2b\]' -EndPattern '^\[Q3 '
	}
}

$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
if (Test-Path $phase0) {
	$passLine = Select-String -Path $phase0 -Pattern "^PHASE0:" | Select-Object -Last 1
	if ($passLine) {
		Write-Host ""
		Write-Host ("Latest " + $passLine.Line)
	}
	$auditLine = Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT:" | Select-Object -Last 1
	if ($auditLine) {
		Write-Host ("Latest " + $auditLine.Line)
	}
}
