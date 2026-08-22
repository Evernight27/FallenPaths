# Fast Phase 0: quick validation before committing (no full soak / calibration).

#   .\tools\ci\run_fast_phase0.ps1          # regression + company state (~2-4 min)

#   .\tools\ci\run_fast_phase0.ps1 -Full    # same as run_all_combat_checks.ps1 (full, ~8-12 min)

#   .\tools\ci\run_fast_phase0.ps1 -D001Light # regression + company state + D001 light (~4-6 min)

#

# What fast mode checks:

#   1. Doc link integrity (fast, no Godot)

#   2. CompanyStateChecks (406 unit tests, ~30-60s)

#   3. CombatRegressionHarness (core combat logic, ~60-120s)

#

# What it SKIPS (use -Full or run separately):

#   - CombatD001SoakRunner (full soak, multi-minute)

#   - CombatCalibrationAudit (physics/medical calibration)

#   - Campaign ship audit tail (reads D001 artifacts)



param(

	[switch]$Full,

	[switch]$D001Light

)

$ErrorActionPreference = "Continue"

. "$PSScriptRoot\Invoke-GodotHeadless.ps1"

. "$PSScriptRoot\F5SoakLogHelpers.ps1"

. "$PSScriptRoot\Phase0Helpers.ps1"

$Root = Get-FallenPathsRoot



if ($Full) {

	Write-Host "=== Fast mode disabled: running full Phase 0 ==="

	& (Join-Path $Root "tools\ci\run_all_combat_checks.ps1")

	exit $LASTEXITCODE

}



# D001 Light mode: regression + company state + D001 light (~4-6 min).

if ($D001Light) {

	Write-Host "=== Fast Phase 0 + D001 Light (regression + company state + D001 presets+unit) ==="

	Write-Host ""

	$SummaryPath = Join-Path $Root ".phase0_fast_d001_light.txt"

	$lines = New-Object System.Collections.Generic.List[string]

	$fail = 0



	# Step 1: Doc link check

	Write-Host "=== Doc link check ==="

	if (-not (Invoke-Phase0DocLinkCheck $Root)) {

		$lines.Add("DOC_LINKS: FAIL")

		$fail = 1

	} else {

		$lines.Add("DOC_LINKS: PASS")

	}

	Write-Host ""



	if ($fail -eq 0) {

		# Step 2-3: CompanyStateChecks (with warmup)

		if (-not (Invoke-Phase0CompanyState $Root $SummaryPath $lines)) {

			$fail = 1

		}

	}



	# Step 4: Regression harness

	if ($fail -eq 0) {

		if (-not (Invoke-Phase0RegressionHarness $Root $SummaryPath $lines ".phase0_fast_d001_light_regression.txt")) {

			$fail = 1

		}

	}



	# Step 5: D001 Light

	if ($fail -eq 0) {

		if (-not (Invoke-Phase0D001LightHarness $Root $SummaryPath $lines ".phase0_fast_d001_light.txt.d001")) {

			$fail = 1

		}

	}



	# Summary

	if ($fail -ne 0) {

		$lines.Add("FAST_PHASE0_D001_LIGHT: FAIL")

		$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

		$lines | Set-Content -Path $SummaryPath -Encoding utf8

		Write-Host "=== FAST_PHASE0_D001_LIGHT: FAIL ==="

		exit 1

	}



	$lines.Add("FAST_PHASE0_D001_LIGHT: PASS")

	$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

	$lines | Set-Content -Path $SummaryPath -Encoding utf8



	Write-Host "=== FAST_PHASE0_D001_LIGHT: PASS ==="

	Write-Host ""

	Write-Host "Fast Phase 0 + D001 Light covers regression + company state + D001 presets+unit checks."

	Write-Host "For full PHASE0 (regression + D001 soak + calibration + campaign audit):"

	Write-Host "  .\tools\ci\run_all_combat_checks.ps1"

	Write-Host ""

	Write-Host "Reports:"

	Write-Host "  .phase0_fast_d001_light.txt          (this summary)"

	Write-Host "  .phase0_fast_d001_light_regression.txt (regression output)"

	Write-Host "  .phase0_fast_d001_light.txt.d001     (D001 light output)"

	exit 0

}



$SummaryPath = Join-Path $Root ".phase0_fast.txt"

$lines = New-Object System.Collections.Generic.List[string]

$fail = 0



Write-Host "=== Fast Phase 0 (regression + company state) ==="

Write-Host ""



# Step 1: Doc link check

Write-Host "=== Doc link check ==="

if (-not (Invoke-Phase0DocLinkCheck $Root)) {

	$lines.Add("DOC_LINKS: FAIL")

	$fail = 1

} else {

	$lines.Add("DOC_LINKS: PASS")

}

Write-Host ""



# Step 2-3: CompanyStateChecks (with warmup)

if ($fail -eq 0) {

	if (-not (Invoke-Phase0CompanyState $Root $SummaryPath $lines)) {

		$fail = 1

	}

}



# Step 4: Regression harness only (skip D001 soak + calibration for speed)

if ($fail -eq 0) {

	if (-not (Invoke-Phase0RegressionHarness $Root $SummaryPath $lines ".phase0_fast_regression_out.txt")) {

		$fail = 1

	}

}



# Summary

if ($fail -ne 0) {

	$lines.Add("FAST_PHASE0: FAIL")

	$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

	$lines | Set-Content -Path $SummaryPath -Encoding utf8

	Write-Host "=== FAST_PHASE0: FAIL ==="

	exit 1

}



$lines.Add("FAST_PHASE0: PASS")

$lines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

$lines | Set-Content -Path $SummaryPath -Encoding utf8



Write-Host "=== FAST_PHASE0: PASS ==="

Write-Host ""

Write-Host "Fast Phase 0 covers regression + company state."

Write-Host "For full PHASE0 (regression + D001 soak + calibration + campaign audit):"

Write-Host "  .\tools\ci\run_all_combat_checks.ps1"

Write-Host ""

Write-Host "Reports:"

Write-Host "  .phase0_fast.txt              (this run)"

Write-Host "  .phase0_fast_regression.txt   (regression harness output)"

Write-Host "  .phase0_combat_checks.txt     (full PHASE0 summary)"

exit 0

