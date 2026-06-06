# Print Phase 0 / D-001 gate artifacts (no Godot).
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host "Docs: docs/CURSOR.md | docs/SHIP_PLAN.md#camp-playtest-acceptance (F5 section 8) | docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers | scripts/README.md"
Write-Host "Streams: Combat (Phase 0 + Camp-3.4 tail) | Playtest F5 section 8 / Q1/Q2 | Expand after Camp-5"
Write-Host "Q headless (no F5): .\scripts\run_q_audit.ps1 -Track Track  (+ -Track Q1)"
Write-Host "Q feel (F5): .\scripts\run_q_feel.ps1 -Track Camp|Q1|Q2"
Write-Host "Fast harness: .\scripts\run_all_combat_checks.ps1 -HarnessMode regression|d001|sanity|calibration|medical"
Write-Host ""

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

Write-Host "=== EA close-out (Camp-5) ==="
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
			@{ Label = "settlement_continue"; Pattern = "^\[camp_settlement_continue\] PASS" },
			@{ Label = "company_day_advanced"; Pattern = "^\[camp_company_day\] PASS" },
			@{ Label = "field_care hint"; Pattern = "^\[camp_field_care\] PASS" },
			@{ Label = "field_care action (step 4)"; Pattern = "^\[camp_field_care_action\] PASS" },
			@{ Label = "paid loss (step 8)"; Pattern = "^\[camp_paid_loss\] PASS" },
			@{ Label = "tutorial soft loss (step 8)"; Pattern = "^\[camp_tutorial_soft_loss\] PASS" },
			@{ Label = "wage warn (step 9)"; Pattern = "^\[camp_wage_warn\] PASS" },
			@{ Label = "desertion (step 9)"; Pattern = "^\[camp_desertion\] PASS" },
			@{ Label = "company_run_end (any)"; Pattern = "^\[camp_run_end\] PASS" },
			@{ Label = "mopup_strike_finish (optional 3e)"; Pattern = "^\[camp_mopup_strike_finish\] PASS" },
			@{ Label = "party triage (step 10)"; Pattern = "^\[camp_party_triage\] PASS" }
		)
		$campAny = Select-String -Path $f5Log -Pattern "settlement_continue|contract_victory pay=|company_day_advanced|field_care:|company_run_end reason=" -Quiet
		if ($campAny) {
			Write-Host "Camp section 8 markers in log:"
			foreach ($c in $campHits) {
				if (Select-String -Path $f5Val -Pattern $c.Pattern -Quiet) {
					Write-Host ("  [OK] " + $c.Label + " (validator)")
				} else {
					Write-Host ("  [--] " + $c.Label + " (not in validation report)")
				}
			}
			if (-not (Select-String -Path $f5Log -Pattern "soak_fight_end winner=" -Quiet)) {
				Write-Host "  [hint] log missing soak_fight_end — merge combat Output with world markers (append_f5_soak_log.ps1)"
			}
		} else {
			Write-Host "Camp section 8: no campaign markers in log yet (combat-only paste ok for WF-M3)"
		}
	}
} else {
	Write-Host "F5 paste: .f5_soak_in.txt missing (optional until Camp section 8 playtest)"
}
Write-Host "Human F5: main.tscn dev_soak_encounter empty -> .\scripts\run_q_feel.ps1 -Track Camp"
Write-Host "WF footing: headless ii5c green; WF-M3 validator on F5 paste -> docs/LIVE_PATHS.md#wf-m3-f5-playtest"
Write-Host "Sign-off rows: docs/SHIP_PLAN.md Camp-3.4 human + Camp-5 EA checklist"
Write-Host ""
Write-Host "=== EA sign-off summary ==="
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
if ($eaHeadless -and $eaWfM3 -and $eaCamp) {
	Write-Host "overall_ea: READY for Camp-5 tick (human glance + SHIP_PLAN sign-off)"
} else {
	Write-Host "overall_ea: blocked - see rows above"
}
Write-Host "Smoke: Copy-Item docs\f5_soak_log.camp_wf.example.txt .f5_soak_in.txt; .\scripts\validate_f5_soak_log.ps1"
Write-Host "Full optional tracks smoke: Copy-Item docs\f5_soak_log.camp_full.example.txt .f5_soak_in.txt"
Write-Host ""
