# Shared Phase 0 helpers for run_all_combat_checks.ps1 and run_fast_phase0.ps1.

# Dot-source: . "$PSScriptRoot\Phase0Helpers.ps1"



## Run a Godot harness with timeout — returns $true if completed within timeout.

function Invoke-Phase0GodotHarnessWithTimeout {

	param(

		[string]$Root,

		[string]$HarnessMode,

		[string]$TeeLog,

		[string]$ExitFile,

		[int]$TimeoutSeconds = 900,

		[string]$F5BackupPath = "",

		[bool]$RestoreF5 = $false

	)

	$Godot = Get-FallenPathsGodot



	if ($RestoreF5 -and (Test-Path $F5BackupPath)) {

		Copy-Item $F5BackupPath (Join-Path $Root ".f5_soak_in.txt") -Force

	}



	$args = @("--headless", "--path", $Root, "-s", "res://tools/ci/run_all_combat_checks.gd")

	$proc = Start-Process -FilePath $Godot -ArgumentList $args -NoNewWindow -PassThru -Wait:$false



	$finished = $proc.WaitForExit($TimeoutSeconds * 1000)

	if (-not $finished) {

		Write-Host "  [HARNESS:$HarnessMode] TIMEOUT after ${TimeoutSeconds}s (PID=$($proc.Id))" -ForegroundColor Red

		Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

		Set-Content -Path $ExitFile -Value "-1" -Encoding utf8

		if ($TeeLog -ne "") {

			@("TIMEOUT after ${TimeoutSeconds}s", "Mode: $HarnessMode") | Set-Content -Path $TeeLog -Encoding utf8

		}

		return $false

	}



	if ($TeeLog -ne "") {

		@("Exit code: $($proc.ExitCode)", "Mode: $HarnessMode", "Duration: ${TimeoutSeconds}s max") | Set-Content -Path $TeeLog -Encoding utf8

	}

	Set-Content -Path $ExitFile -Value $proc.ExitCode -Encoding utf8

	return $true

}



function Invoke-Phase0DocLinkCheck {

	param([string]$Root)

	$script = Join-Path $Root "tools\ci\check_doc_links.ps1"

	if (Test-Path $script) {

		& $script

		return $LASTEXITCODE -eq 0

	}

	Write-Host "  SKIP: no doc link checker found"

	return $true

}



function Invoke-Phase0CompanyState {

	param(

		[string]$Root,

		[string]$SummaryPath,

		[System.Collections.Generic.List[string]]$Lines,

		[bool]$SkipWarmup = $false

	)

	if (-not $SkipWarmup) {

		Write-Host "=== Godot import warmup ==="

		Invoke-FallenPathsGodotImportWarmup -SleepSeconds 0

		Write-Host ""

	} else {

		$env:FP_SKIP_GODOT_WARMUP = "1"

	}



	Write-Host "=== CompanyStateChecks (558 tests) ==="

	$companyOut = @(& (Join-Path $Root "tools\ci\run_company_state_checks.ps1") 2>&1 | ForEach-Object { "$_" })

	$companyOut | ForEach-Object { Write-Host $_ }

	$companyOk = $companyOut | Where-Object { $_ -match "FP_HARNESS_OK:\s+CompanyStateChecks" } | Select-Object -Last 1

	$companyExit = $LASTEXITCODE



	if ($companyExit -ne 0 -or -not $companyOk) {

		$Lines.Add("COMPANY_STATE: FAIL exit=$companyExit")

		return $false

	}

	$Lines.Add("COMPANY_STATE: PASS")

	if ($companyOk) { $Lines.Add([string]$companyOk) }

	Write-Host ""

	return $true

}



function Invoke-Phase0RegressionHarness {

	param(

		[string]$Root,

		[string]$SummaryPath,

		[System.Collections.Generic.List[string]]$Lines,

		[string]$TeeLog = ".phase0_fast_regression.txt"

	)

	Write-Host "=== CombatRegressionHarness (quick smoke) ==="

	$teePath = Join-Path $Root $TeeLog

	$null = Invoke-FallenPathsGodotScript -HarnessMode "regression"

	$exitCode = Get-FallenPathsGodotExitCode



	$harnessReportPath = Join-Path $Root ".harness_out.txt"

	if (Test-Path $harnessReportPath) {

		$out = @(Get-Content -Path $harnessReportPath -Encoding utf8)

		$ok = [bool]($out | Where-Object { $_ -match "ok=true" } | Select-Object -Last 1)
		$nameMatch = [bool]($out | Where-Object { $_ -match "^name=CombatRegressionHarness$" } | Select-Object -Last 1)

		if (-not $ok -or -not $nameMatch) {

			$Lines.Add("REGRESSION: FAIL (harness report invalid)")

			return $false

		}

		$Lines.Add("REGRESSION: PASS")

	} else {

		$Lines.Add("REGRESSION: FAIL (no output)")

		return $false

	}

	Write-Host ""

	return $true

}



function Invoke-Phase0D001LightHarness {

	param(

		[string]$Root,

		[string]$SummaryPath,

		[System.Collections.Generic.List[string]]$Lines,

		[string]$TeeLog = ".phase0_d001_light.txt"

	)

	Write-Host "=== CombatD001SoakRunner (light mode) ==="

	$f5b_path = Join-Path $Root ".f5_soak_in.f5_backup.txt"

	if (Test-Path (Join-Path $Root ".f5_soak_in.txt")) {

		Copy-Item (Join-Path $Root ".f5_soak_in.txt") $f5b_path -Force

	}



	Invoke-FallenPathsGodotScript -HarnessMode "d001_light" -TeeLog $TeeLog *> $null

	$exitCode = Get-FallenPathsGodotExitCode



	if (Test-Path $TeeLog) {

		$out = @(Get-Content -Path $TeeLog -Encoding utf8)

		$out | ForEach-Object { Write-Host $_ }

		$ok = $false

		foreach ($line in $out) {

			if ($line -match "FP_HARNESS_OK:\s+CombatD001Light") {

				$ok = $true

				break

			}

		}

		if (-not $ok) {

			$Lines.Add("D001_LIGHT: FAIL (exit=$exitCode)")

			return $false

		}

		$Lines.Add("D001_LIGHT: PASS")

	} else {

		$Lines.Add("D001_LIGHT: FAIL (no output)")

		return $false

	}



	if (Test-Path $f5b_path) {

		Copy-Item $f5b_path (Join-Path $Root ".f5_soak_in.txt") -Force

	}

	Write-Host ""

	return $true

}

