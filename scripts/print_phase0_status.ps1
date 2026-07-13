# Print Phase 0 / D-001 gate artifacts (no Godot).
param(
	[switch]$Quiet
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

Write-Host "Docs: docs/AGENTS_ENTRY.md | docs/SHIP_PLAN.md#camp-playtest-acceptance (F5 section 8) | docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers | scripts/README.md"
Write-Host "Streams: Combat (Phase 0 + Camp-3.4 tail) | Playtest F5 section 8 / Q1/Q2 | Expand after Camp-5"
if (-not $Quiet) {
	Write-Host "Q headless (no F5): .\scripts\run_q_audit.ps1 -Track Track  (+ -Track Q1)"
	Write-Host "Q feel (F5): .\scripts\run_q_feel.ps1 -Track Camp|Q1|Q2"
	Write-Host "Fast harness: .\scripts\run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical"
	Write-Host ""
}

function Test-Phase0Green {
	param([string]$Phase0Path, [string]$CampaignAuditPath)
	$phase0Ok = (Test-Path $Phase0Path) -and (Select-String -Path $Phase0Path -Pattern "^PHASE0: PASS" -Quiet)
	$campaignOk = $false
	if (Test-Path $CampaignAuditPath) {
		$campaignOk = Select-String -Path $CampaignAuditPath -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet
	}
	if (-not $campaignOk -and $phase0Ok) {
		$campaignOk = Select-String -Path $Phase0Path -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet
	}
	return @{ Phase0 = $phase0Ok; CampaignShip = $campaignOk }
}

function Show-File($Path, $Label) {
	if (-not (Test-Path $Path)) {
		Write-Host "[$Label] (missing) $Path"
		return
	}
	Write-Host "=== $Label ==="
	Get-Content $Path | Select-Object -First 30
	Write-Host ""
}

if (-not $Quiet) {
Show-File (Join-Path $Root ".phase0_combat_checks.txt") "phase0"
$phase0Path = Join-Path $Root ".phase0_combat_checks.txt"
if ((Test-Path $phase0Path) -and -not (Select-String -Path $phase0Path -Pattern "^COMPANY_STATE: PASS" -Quiet)) {
	Write-Host "WARN: phase0 summary missing COMPANY_STATE: PASS - re-run run_all_combat_checks.ps1"
	Write-Host ""
}
$harnessOut = Join-Path $Root ".harness_out.txt"
if (Test-Path $harnessOut) {
	$companyOk = Select-String -Path $harnessOut -Pattern "FP_HARNESS_OK: CompanyStateChecks" | Select-Object -Last 1
	if ($companyOk) {
		Write-Host "=== company_state_checks (last harness) ==="
		Write-Host $companyOk.Line
		Write-Host ""
	}
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
	Write-Host "=== d001_soak (grep ok / ii2b / ii5c / ii7) ==="
	Select-String -Path $soak -Pattern "^ok=|^\[ii2b\]|^\[ii4d\]|^\[ii5c\]|^\[ii7\]|^\[ii_envelop\]|^\[formation_move_f5\]|ii2b_plausibility|ii4d_plausibility|exhaustion_stats|parry_stats|form_wrath_" | ForEach-Object { $_.Line }
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

} # end -not $Quiet

$soak = Join-Path $Root ".d001_soak_out.txt"
Write-Host "=== Post-Camp-5 status (Camp-5 EA ☑ 2026-06-07) ==="
$phase0File = Join-Path $Root ".phase0_combat_checks.txt"
$campaignFile = Join-Path $Root ".campaign_ship_audit.txt"
$gates = Test-Phase0Green -Phase0Path $phase0File -CampaignAuditPath $campaignFile
if ((Test-Path $soak)) {
	$ii7Ok = Select-String -Path $soak -Pattern '\[ii7\] pass=true' -Quiet
	$iiEnvelopOk = Select-String -Path $soak -Pattern '\[ii_envelop\] pass=true' -Quiet
	$ii5cOk = Select-String -Path $soak -Pattern '\[ii5c\] pass=true' -Quiet
	$wrathGaugeOk = Select-String -Path $soak -Pattern 'form_wrath_gauge: PASS' -Quiet
	if ($ii7Ok -and $iiEnvelopOk) {
		Write-Host "D-001: [ii7] + [ii_envelop] pass=true (headless)"
	} elseif ($gates.Phase0) {
		Write-Host "WARN: D-001 soak missing ii7/ii_envelop pass - re-run run_all_combat_checks.ps1"
	}
	if ($ii5cOk -and $wrathGaugeOk) {
		Write-Host "D-001: [ii5c] + form_wrath_gauge PASS (headless WF footing)"
	} elseif ($gates.Phase0 -and -not $ii5cOk) {
		Write-Host "WARN: D-001 soak missing [ii5c] pass=true - re-run run_all_combat_checks.ps1"
	}
}
if ($gates.Phase0 -and $gates.CampaignShip) {
	Write-Host "Headless: GREEN (PHASE0 + CAMPAIGN_SHIP_AUDIT)"
} else {
	if (-not $gates.Phase0) { Write-Host "Headless: PHASE0 not PASS - run .\scripts\run_all_combat_checks.ps1" }
	if (-not $gates.CampaignShip) { Write-Host "Headless: CAMPAIGN_SHIP_AUDIT not PASS - run .\scripts\run_campaign_ship_audit.ps1" }
}
$f5Log = Join-Path $Root ".f5_soak_in.txt"
$f5Val = Join-Path $Root ".f5_soak_validation.txt"
	if (Test-Path $f5Log) {
	Write-Host ""
	Write-Host "=== F5 paste (.f5_soak_in.txt) ==="
	if (Test-F5SoakHeadlessCaptureOnly $f5Log) {
		Write-Host "NOTE: headless D001 capture only (Phase 0 overwrites .f5_soak_in.txt); paste F5 Output or: .\scripts\restore_f5_soak_log.ps1"
	} elseif (Test-F5SoakIsExampleSmoke $f5Log) {
		Write-Host "NOTE: docs example smoke - not Camp-5 human sign-off (paste real F5 Output)"
	}
	$bakPath = Get-F5SoakBackupPath $Root
	if ((Test-Path $bakPath) -and (Test-F5SoakHeadlessCaptureOnly $f5Log)) {
		Write-Host "Hint: .\scripts\restore_f5_soak_log.ps1"
	}
	if (Test-F5ValidationStale $Root) {
		Write-Host "WARN: .f5_soak_validation.txt stale - run .\scripts\validate_f5_soak_log.ps1"
	}
	if (-not (Test-Path $f5Val)) {
		Write-Host "WARN: no .f5_soak_validation.txt - run .\scripts\validate_f5_soak_log.ps1"
	} else {
		$valOk = Select-String -Path $f5Val -Pattern "^ok=true" -Quiet
		$wfForm = Select-String -Path $f5Val -Pattern "^\[wf_m3_turn_ready_form\] PASS" -Quiet
		$wfOrder = Select-String -Path $f5Val -Pattern "^\[wf_m3_grd_before_form\] PASS" -Quiet
		$wfLeak = Select-String -Path $f5Val -Pattern "^\[wf_m3_idle_step_leak\] PASS" -Quiet
		if ($valOk -and $wfForm -and $wfOrder) {
			Write-Host "WF-M3 validator: GREEN (wf_m3_turn_ready_form + wf_m3_grd_before_form PASS)"
			if ($wfLeak) {
				Write-Host "WF-M3 idle Step leak: none detected (wf_m3_idle_step_leak PASS)"
			} else {
				Write-Host "WF-M3 idle Step leak: check [wf_m3_idle_step_leak] in .f5_soak_validation.txt (optional track)"
			}
		} elseif ($valOk) {
			Write-Host "F5 validator: ok=true (WF-M3 tracks missing or fail - re-validate after combat fights)"
		} else {
			Write-Host "WARN: F5 validator not ok=true - run .\scripts\validate_f5_soak_log.ps1"
		}
		$campHits = @(
			@{ Label = "settlement_continue"; TrackId = "camp_settlement_continue" },
			@{ Label = "company_day_advanced"; TrackId = "camp_company_day" },
			@{ Label = "field_care hint"; TrackId = "camp_field_care" },
			@{ Label = "field_care action (step 4)"; TrackId = "camp_field_care_action" },
			@{ Label = "paid loss (step 8)"; TrackId = "camp_paid_loss" },
			@{ Label = "tutorial soft loss (step 8)"; TrackId = "camp_tutorial_soft_loss" },
			@{ Label = "wage warn (step 9)"; TrackId = "camp_wage_warn" },
			@{ Label = "desertion (step 9)"; TrackId = "camp_desertion" },
			@{ Label = "company_run_end (any)"; TrackId = "camp_run_end" },
			@{ Label = "mopup_strike_finish (optional 3e)"; TrackId = "camp_mopup_strike_finish" },
			@{ Label = "party triage (step 10)"; TrackId = "camp_party_triage" }
		)
		$campAny = Test-F5CampWorldMarkersInLog $f5Log
		if ($campAny) {
			Write-Host "Camp section 8 markers in log:"
			foreach ($c in $campHits) {
				$status = Get-F5ValidatorTrackStatus $f5Val $c.TrackId
				switch ($status) {
					"pass" { Write-Host ("  [OK] " + $c.Label + " (validator)") }
					"optional_miss" { Write-Host ("  [opt] " + $c.Label + " (OPTIONAL_MISS - not Camp-5 blocker)") }
					default { Write-Host ("  [--] " + $c.Label + " (not in validation report)") }
				}
			}
			if (-not (Select-String -Path $f5Log -Pattern "soak_fight_end winner=" -Quiet)) {
				Write-Host "  [hint] log missing soak_fight_end - merge combat Output with world markers (append_f5_soak_log.ps1)"
			}
		} else {
			Write-Host "Camp section 8: no campaign markers in log yet (combat-only paste ok for WF-M3)"
		}
	}
} else {
	Write-Host "F5 paste: .f5_soak_in.txt missing (optional until Camp section 8 playtest)"
}
if (-not $Quiet) {
	Write-Host "Human F5: main.tscn dev_soak_encounter empty -> .\scripts\run_q_feel.ps1 -Track Camp"
	Write-Host "WF footing: headless ii5c green; WF-M3 validator on F5 paste -> docs/LIVE_PATHS.md#wf-m3-f5-playtest"
	Write-Host "Camp-5 check 2026-06-07 - F5 on demand; prompts: scripts/agent_prompts/README.md"
	Write-Host ""
}
Write-Host "=== F5 / Camp status summary ==="
$eaHeadless = $gates.Phase0 -and $gates.CampaignShip
$eaWfM3 = $false
$eaCamp = $false
if (Test-Path $f5Val) {
	$eaWfM3 = (Select-String -Path $f5Val -Pattern "^ok=true" -Quiet) `
		-and (Select-String -Path $f5Val -Pattern "^\[wf_m3_turn_ready_form\] PASS" -Quiet) `
		-and (Select-String -Path $f5Val -Pattern "^\[wf_m3_grd_before_form\] PASS" -Quiet)
	if (Select-String -Path $f5Val -Pattern "^\[camp_settlement_continue\] PASS" -Quiet) {
		$eaCamp = (Select-String -Path $f5Val -Pattern "^\[camp_company_day\] PASS" -Quiet)
	}
}
Write-Host ("headless: " + $(if ($eaHeadless) { "READY" } else { "NOT READY" }))
Write-Host ("wf_m3_f5_paste: " + $(if ($eaWfM3) { "READY (validator)" } elseif (Test-Path $f5Log) { "re-run validate_f5_soak_log.ps1" } else { "no .f5_soak_in.txt" }))
Write-Host ("camp_section_8: " + $(if ($eaCamp) { "READY (settlement + day markers)" } elseif (Test-Path $f5Log) { "NOT READY - need full Camp loop in log" } else { "NOT READY - F5 Camp playtest" }))
if (Test-Path $f5Val) {
	$exp02 = Test-F5Exp02OptionalTracksPass $f5Val
	Write-Host ("exp_0_2_optional: " + $(if ($exp02) { "PASS (steps 4, 8 paid, 9, 10)" } else { "incomplete - run .\scripts\run_playtest.ps1 exp0" }))
}
$f5HumanStatus = "NOT READY"
if (Test-Path $f5Log) {
	$f5HumanStatus = Get-F5HumanSignoffStatus $f5Log
}
Write-Host ("human_f5_paste: " + $(switch ($f5HumanStatus) {
	"READY" { "READY (Camp-5 baseline - re-run -HumanSignOff after new F5 append)" }
	"SMOKE ONLY" { "SMOKE ONLY (docs example - paste real F5 Output)" }
	"NOT READY (headless capture)" { "NOT READY (headless capture - restore_f5_soak_log.ps1)" }
	default { "NOT READY" }
}))
$bakPath = Get-F5SoakBackupPath $Root
if ((Test-Path $bakPath) -and $f5HumanStatus -ne "READY") {
	Write-Host "Hint: human backup at .f5_soak_in.f5_backup.txt - .\scripts\restore_f5_soak_log.ps1"
}
if ($eaHeadless -and $eaWfM3 -and $eaCamp -and ($f5HumanStatus -eq "READY")) {
	Write-Host "overall: GREEN (headless + human F5 baseline)"
} elseif ($eaHeadless -and $eaWfM3 -and $eaCamp -and ($f5HumanStatus -eq "SMOKE ONLY")) {
	Write-Host "overall: SMOKE ONLY (docs example - restore backup or paste real F5)"
} else {
	Write-Host "overall: check rows above (Phase 0 gate is primary)"
}
if (-not $Quiet) {
	Write-Host "Smoke: Copy-Item docs\f5_soak_log.camp_wf.example.txt .f5_soak_in.txt; .\scripts\validate_f5_soak_log.ps1"
	Write-Host "Full optional tracks smoke: Copy-Item docs\f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
}
Write-Host ""
