# F5 feel checklist (no Godot). -Track Q1 | Q2
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet("Q1", "Q2")]
	[string]$Track
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot

if ($Track -eq "Q1") {
	Write-Host "=== Track Q1: research_feel duel ==="
	Write-Host ""
	Write-Host "1. PHASE0 green: .\scripts\run_all_combat_checks.ps1"
	Write-Host "2. main.tscn Inspector: dev_soak_encounter=ii2b, dev_research_feel=ON"
	Write-Host "3. F5 -> cyan marker -> fight (>=3 hits)"
	Write-Host "4. Output grep: research_feel | research_validate_hint | soak_fight_end"
	Write-Host "5. Copy Output -> .f5_soak_in.txt -> .\scripts\validate_f5_soak_log.ps1"
	Write-Host ""
	Write-Host "Docs: docs/LIVE_PATHS.md#track-q1--research-feel-duel"
	Write-Host "      docs/LIVE_PATHS.md#enable-per-hit-research_feel-lines"
	Write-Host ""
	Write-Host "Headless: .\scripts\run_q_audit.ps1 -Track Q1 -> .q1_research_feel_audit.txt"
	$logPath = Join-Path $Root ".f5_soak_in.txt"
	if (Test-Path $logPath) {
		Write-Host ""
		Write-Host "=== .f5_soak_in.txt (research_feel) ==="
		$lines = Select-String -Path $logPath -Pattern "research_feel|research_validate_hint"
		if ($lines) {
			$lines | ForEach-Object { Write-Host $_.Line }
		} else {
			Write-Host "(no research_feel lines — run F5 with dev_research_feel=true first)"
		}
		$count = (Select-String -Path $logPath -Pattern "research_feel part=").Count
		Write-Host ""
		Write-Host "research_feel hit lines: $count"
	} else {
		Write-Host "[.f5_soak_in.txt] missing — paste F5 Output or copy docs/f5_soak_log.example.txt"
	}
} else {
	Write-Host "=== Track Q2: ii2b bind / riposte / flurry feel ==="
	Write-Host ""
	Write-Host "Headless: .\scripts\run_q_audit.ps1 -Track Q2 -> .q2_ii2b_feel_audit.txt"
	Write-Host ""
	Write-Host "F5: dev_soak_encounter=ii2b -> grep parry_deflect | parry_bind | riposte_chain | flurry_bind"
	Write-Host "Docs: docs/LIVE_PATHS.md#track-q2--ii2b-bind-riposte-feel · docs/LIVE_PATHS.md#iii-3--deflect--bind-calibration-loop-m3c"
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
		Write-Host "[.f5_soak_in.txt] missing — paste F5 Output after ii2b duel."
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
	$pass = Select-String -Path $phase0 -Pattern "^PHASE0:" | Select-Object -Last 1
	if ($pass) { Write-Host ""; Write-Host "Latest $pass" }
}
