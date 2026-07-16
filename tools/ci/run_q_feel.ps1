# F5 feel checklist (no Godot). -Track Q1 | Q2 | Camp
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet("Q1", "Q2", "Camp")]
	[string]$Track
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $Root "tools\ci\F5SoakLogHelpers.ps1")

if ($Track -eq "Camp") {
	$logPath = Join-Path $Root ".f5_soak_in.txt"
	$valPath = Join-Path $Root ".f5_soak_validation.txt"
	if (Test-Path $logPath) {
		& (Join-Path $Root "tools\ci\validate_f5_soak_log.ps1") -LogPath $logPath -Quiet
		if (-not (Wait-F5ValidationReport $valPath)) {
			Write-Host "WARN: F5 validation report incomplete - re-run .\tools\ci\validate_f5_soak_log.ps1"
		}
	}
	& (Join-Path $Root "tools\ci\print_phase0_status.ps1")
	Write-Host ""
	Write-Host "=== Track Camp: EA campaign F5 (SHIP_PLAN section 8) ==="
	Write-Host ""
	Write-Host "Prereq: headless GREEN above (or run .\tools\ci\run_all_combat_checks.ps1)"
	Write-Host ""
	Write-Host "1. scenes/campaign/main.tscn Inspector: dev_soak_encounter EMPTY (campaign mode, no cyan soak tile)"
	Write-Host "2. F5 -> note HUD gold / med / tools / roster"
	Write-Host "3. Green tutorial tile -> win -> settlement pay + wounds -> Continue (grep settlement_continue in Output)"
	Write-Host "4. Untreated bleed: tutorial blocks move until first win; Party field pressure (free) then bandage (-1 med)"
	Write-Host "5. Camp rest (Party, all dressed): -1 med, 600s x3 heal, +1 day + wages; or End day on tile 0,0 (wages only)"
	Write-Host "6. Hybrid day: 5 overworld steps also tick wages if you skipped camp rest"
	Write-Host "7. Second paid contract -> renown scales pay"
	Write-Host "8. Lose PAID contract -> CompanyRunEndPanel + scenes/campaign/main.tscn reload (grep company_run_end reason=contract_failed reload=true)"
	Write-Host "   Lose tutorial -> soft resume (grep company_run_end reason=tutorial_failed reload=false) + marker respawn"
	Write-Host "9. Low gold -> wage warn, low mood -> desertion risk at day end"
	Write-Host "10. Party menu -> triage lines match last fight"
	Write-Host "11. Medical-phase fight -> Stack medical / self_medical on gauge (optional feel)"
	Write-Host "12. WF-M3 footing: during sword fights grep turn_ready_gauge - Step -> Grd/Atk -> Form suffix order; diagram [HiR]/[Wrath] guard before form (docs/LIVE_PATHS.md#wf-m3-f5-playtest)"
	Write-Host "13. Optional III-4: dev_soak_encounter=ii_envelop -> Skirmish 7v3 through last enemy; grep engagement_debug mop_up=true rotate_suppress=true pick=attempt_close; validate_f5_soak_log.ps1"
	Write-Host "14. Paste F5 Output -> .f5_soak_in.txt (or .\tools\ci\append_f5_soak_log.ps1) - re-run this script to scan markers"
	Write-Host ""
	$logPath = Join-Path $Root ".f5_soak_in.txt"
	if (Test-Path $logPath) {
		Write-Host "=== .f5_soak_in.txt (Camp section 8 markers) ==="
		$campMarkers = @(
			@{ Label = "settlement_continue (step 3)"; Pattern = "^FP_WORLD: settlement_continue" },
			@{ Label = "field_care hint (step 4)"; Pattern = "^FP_WORLD: field_care:" },
			@{ Label = "field_care bandage (step 4 action)"; Pattern = "^FP_WORLD: field_care bandage part=" },
			@{ Label = "company_day_advanced (step 5-6)"; Pattern = "^FP_WORLD: company_day_advanced" },
			@{ Label = "paid loss reload (step 8)"; Pattern = "^FP_WORLD: company_run_end reason=contract_failed" },
			@{ Label = "tutorial soft resume (step 8)"; Pattern = "^FP_WORLD: company_run_end reason=tutorial_failed" },
			@{ Label = "wage warn (step 9)"; Pattern = "^FP_WORLD: company_wages: gold=" },
			@{ Label = "desertion (step 9)"; Pattern = "^FP_WORLD: desertion summary=" },
			@{ Label = "party triage open (step 10)"; Pattern = "^FP_WORLD: party_triage_open living=" },
			@{ Label = "turn_ready_gauge (WF-M3 step 12)"; Pattern = "^FP_COMBAT: turn_ready_gauge" },
			@{ Label = "form suffix on gauge (WF-M3)"; Pattern = " Form " },
			@{ Label = "form_switch AI auto-switch (optional WF-M3)"; Pattern = "^FP_COMBAT: form_switch id=" }
		)
		$gaugeLines = Select-String -Path $logPath -Pattern "turn_ready_gauge" | Select-Object -First 3
		if ($gaugeLines) {
			Write-Host ""
			Write-Host "=== turn_ready_gauge samples (WF-M3 - check Step -> Grd/Atk -> Form) ==="
			$gaugeLines | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) }
		}
		foreach ($m in $campMarkers) {
			$hit = Select-String -Path $logPath -Pattern $m.Pattern | Select-Object -First 1
			if ($hit) {
				Write-Host ("  [OK] " + $m.Label)
				Write-Host ("        " + $hit.Line.Trim())
			} else {
				Write-Host ("  [--] " + $m.Label + " (not in log yet)")
			}
		}
		$campOk = Get-F5CampCoreMarkerScore $logPath
		Write-Host ""
		Write-Host ("Camp core markers: $campOk / 2 (settlement or victory + day advance for Camp §8 F5)")
		Show-F5SoakStatusHint $Root
		$humanStatus = Get-F5HumanSignoffStatus $logPath
		switch ($humanStatus) {
			"READY" { Write-Host "Human sign-off: READY (Camp-5 baseline - re-run -HumanSignOff after new F5 append)" }
			"SMOKE ONLY" { Write-Host "Human sign-off: SMOKE ONLY (docs example - paste real F5 Output)" }
			"NOT READY (headless capture)" { Write-Host "Human sign-off: NOT READY (headless capture - restore_f5_soak_log.ps1)" }
			default { Write-Host "Human sign-off: NOT READY" }
		}
		Write-Host ""
		$report = Join-Path $Root ".f5_soak_validation.txt"
		if (Test-Path $report) {
			Write-Host "=== WF-M3 / Camp F5 validator (CombatF5SoakLogValidator) ==="
			Show-F5ValidationTrackSummary $report -IncludeMeta
			Write-Host ""
		}
	} else {
		Write-Host '.f5_soak_in.txt missing - paste F5 Output after playtest to auto-scan markers'
		Write-Host ""
	}
	Write-Host "Sign-off: tick Camp-3.4 human + Camp-5 in docs/SHIP_PLAN.md (WF-M3 step 12 + sign-off line in LIVE_PATHS#wf-m3-f5-playtest)"
	Write-Host "Docs: docs/SHIP_PLAN.md#camp-playtest-acceptance"
}
elseif ($Track -eq "Q1") {
	Write-Host "=== Track Q1: research_feel duel ==="
	Write-Host ""
	Write-Host "1. PHASE0 green: .\tools\ci\run_all_combat_checks.ps1"
	Write-Host "2. scenes/campaign/main.tscn Inspector: dev_soak_encounter=ii2b, dev_research_feel=ON"
	Write-Host "3. F5 -> cyan marker -> fight (>=3 hits)"
	Write-Host "4. Output grep: research_feel, hit_resolve reason=, strike_avoided reason=, soak_fight_end"
	Write-Host "5. Copy Output -> .f5_soak_in.txt -> .\tools\ci\validate_f5_soak_log.ps1"
	Write-Host ""
	Write-Host "Docs: docs/LIVE_PATHS.md#track-q1--research-feel-duel"
	Write-Host "Headless: .\tools\ci\run_q_audit.ps1 -Track Q1 -> .q1_research_feel_audit.txt"
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
		Write-Host '.f5_soak_in.txt missing'
	}
}
else {
	Write-Host "=== Track Q2: ii2b bind / riposte / flurry feel ==="
	Write-Host ""
	Write-Host "Headless: .\tools\ci\run_q_audit.ps1 -Track Q2 -> .q2_ii2b_feel_audit.txt"
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
		Write-Host '.f5_soak_in.txt missing'
	}
	$q2 = Join-Path $Root ".q2_ii2b_feel_audit.txt"
	if (Test-Path $q2) {
		Write-Host ""
		Write-Host "=== .q2_ii2b_feel_audit.txt (last 12 lines) ==="
		Get-Content $q2 | Select-Object -Last 12
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
