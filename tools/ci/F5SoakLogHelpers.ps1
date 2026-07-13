# Shared helpers for Playtest F5 paste (.f5_soak_in.txt) backup and camp marker grep.
# Dot-source: . "$PSScriptRoot\F5SoakLogHelpers.ps1"

function Get-F5SoakLogPath {
	param([string]$Root)
	Join-Path $Root ".f5_soak_in.txt"
}

function Get-F5SoakBackupPath {
	param([string]$Root)
	Join-Path $Root ".f5_soak_in.f5_backup.txt"
}

function Test-F5SoakLineIsFatalErrorHint {
	param([string]$Line)
	$s = $Line.Trim()
	if ($s -match '^(FP_COMBAT:\s*)?soak_guide ') { return $true }
	if ($s -match '^(FP_COMBAT:\s*)?soak_session_plan ') { return $true }
	if ($s -match '^(FP_COMBAT:\s*)?soak_validate_hint ') { return $true }
	if ($s -match '^(FP_COMBAT:\s*)?soak_coverage ') { return $true }
	if ($s -match 'grep (FP_ERROR|SCRIPT)') { return $true }
	if ($s -match '^FP_SESSION_BEGIN:' -or $s -match '^FP_SESSION_END:') { return $true }
	return $false
}

function Test-F5SoakLineIsRealFatalError {
	param([string]$Line)
	if ([string]::IsNullOrWhiteSpace($Line)) { return $false }
	if (Test-F5SoakLineIsFatalErrorHint $Line) { return $false }
	$s = $Line.Trim()
	if ($s -match '^FP_ERROR:') { return $true }
	if ($s -match '^SCRIPT ERROR:') { return $true }
	if ($s -match '^ERROR:') { return $true }
	if ($s -match '^SHADER ERROR:') { return $true }
	return $false
}

function Test-F5SoakHasFatalErrors {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	foreach ($line in Get-Content -LiteralPath $LogPath -Encoding UTF8 -ErrorAction SilentlyContinue) {
		if (Test-F5SoakLineIsRealFatalError $line) { return $true }
	}
	return $false
}

function Get-F5HumanSignoffStatus {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return "NOT READY" }
	if (Test-F5SoakLooksHumanPaste $LogPath) { return "READY" }
	if (Test-F5SoakIsExampleSmoke $LogPath) { return "SMOKE ONLY" }
	if (Test-F5SoakHeadlessCaptureOnly $LogPath) { return "NOT READY (headless capture)" }
	return "NOT READY"
}

function Test-F5SoakShouldPreserve {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	if (Test-F5SoakIsExampleSmoke $LogPath) { return $false }
	if (Test-F5SoakHeadlessCaptureOnly $LogPath) { return $false }
	if (Select-String -Path $LogPath -Pattern '^FP_WORLD:' -Quiet) { return $true }
	if (Select-String -Path $LogPath -Pattern '^--- f5_soak_append' -Quiet) { return $true }
	if (Test-F5SoakLooksHumanPaste $LogPath) { return $true }
	return $false
}

function Test-F5SoakHeadlessCaptureOnly {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	if (Select-String -Path $LogPath -Pattern '^FP_WORLD:' -Quiet) { return $false }
	if (Select-String -Path $LogPath -Pattern '^--- f5_soak_append' -Quiet) { return $false }
	return (Select-String -Path $LogPath -Pattern '^FP_SESSION_BEGIN: headless d001 capture' -Quiet)
}

function Test-F5SoakHasStep9Append {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	return (Select-String -Path $LogPath -Pattern '^--- f5_soak_append: camp5_step9' -Quiet)
}

function Backup-F5SoakHumanPaste {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	$bak = Get-F5SoakBackupPath $Root
	if (-not (Test-F5SoakShouldPreserve $log)) { return $false }
	if ((Test-Path $bak) -and (Test-F5SoakIsExampleSmoke $log)) { return $false }
	if ((Test-Path $bak) -and (Test-F5SoakShouldPreserve $bak)) {
		$srcLen = (Get-Item $log).Length
		$bakLen = (Get-Item $bak).Length
		if ((Test-F5SoakHasStep9Append $bak) -and -not (Test-F5SoakHasStep9Append $log) -and $srcLen -le $bakLen) {
			Write-Host "Keeping step-9 backup ($bakLen bytes) - current paste ($srcLen bytes) missing camp5_step9 append"
			return $true
		}
	}
	Copy-Item -LiteralPath $log -Destination $bak -Force
	Write-Host "Backed up F5 paste -> $bak (Phase 0 overwrites .f5_soak_in.txt with headless D001 capture)"
	return $true
}

function Restore-F5SoakHumanPaste {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	$bak = Get-F5SoakBackupPath $Root
	if (-not (Test-Path $bak)) { return $false }
	Copy-Item -LiteralPath $bak -Destination $log -Force
	Write-Host "Restored F5 paste from $bak"
	return $true
}

function Get-F5SoakAppendSeparator {
	param([string]$Label = "")
	if ($Label -ne "") {
		return "--- f5_soak_append: $Label ---"
	}
	return "--- f5_soak_append ---"
}

function Test-F5CampWorldMarkersInLog {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	return (Select-String -Path $LogPath -Pattern '^FP_WORLD: (settlement_continue|contract_victory pay=|company_day_advanced|field_care:|company_run_end reason=)' -Quiet)
}

function Test-F5ValidationStale {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	$val = Join-Path $Root ".f5_soak_validation.txt"
	if (-not ((Test-Path $log) -and (Test-Path $val))) { return $false }
	return (Get-Item $log).LastWriteTime -gt (Get-Item $val).LastWriteTime
}

function Show-F5SoakStatusHint {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	if (-not (Test-Path $log)) { return }
	if (Test-F5SoakIsExampleSmoke $log) {
		Write-Host "NOTE: .f5_soak_in.txt is docs example smoke - not Camp-5 human sign-off (paste real F5 Output)"
	} elseif (Test-F5SoakHeadlessCaptureOnly $log) {
		Write-Host "NOTE: .f5_soak_in.txt is headless D001 capture - paste F5 Output or: .\tools\ci\restore_f5_soak_log.ps1"
	} elseif (Test-F5ValidationStale $Root) {
		Write-Host "NOTE: .f5_soak_in.txt newer than .f5_soak_validation.txt - run .\tools\ci\validate_f5_soak_log.ps1"
	}
}

function Test-F5SoakIsExampleSmoke {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	$head = Get-Content -LiteralPath $LogPath -TotalCount 8 -ErrorAction SilentlyContinue
	foreach ($line in $head) {
		if ($line -match '^#\s*(Merged Camp|Minimal Camp).*sample') { return $true }
		if ($line -match 'not one real session') { return $true }
		if ($line -match 'Copy smoke:') { return $true }
	}
	return $false
}

function Test-F5SoakLooksHumanPaste {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return $false }
	if (Test-F5SoakIsExampleSmoke $LogPath) { return $false }
	if (Test-F5SoakHeadlessCaptureOnly $LogPath) { return $false }
	if ((Get-Item $LogPath).Length -gt 50000) { return $true }
	$gaugeCount = @(Select-String -Path $LogPath -Pattern '(^FP_COMBAT: )?turn_ready_gauge ').Count
	if ($gaugeCount -ge 10) { return $true }
	if ((Select-String -Path $LogPath -Pattern '^FP_WORLD:' -Quiet) `
			-and (Select-String -Path $LogPath -Pattern '^FP_SESSION_BEGIN:' -Quiet) `
			-and -not (Select-String -Path $LogPath -Pattern '^FP_SESSION_BEGIN: headless d001 capture' -Quiet)) {
		return $true
	}
	if ((Select-String -Path $LogPath -Pattern '^--- f5_soak_append' -Quiet) `
			-and (Select-String -Path $LogPath -Pattern '^FP_WORLD:' -Quiet) `
			-and $gaugeCount -ge 1) {
		return $true
	}
	return $false
}

function Get-F5Exp02OptionalTrackIds {
	return @(
		"camp_field_care_action",
		"camp_paid_loss",
		"camp_wage_warn",
		"camp_desertion",
		"camp_party_triage"
	)
}

function Test-F5Exp02OptionalTracksPass {
	param([string]$ValPath)
	if (-not (Test-Path $ValPath)) { return $false }
	foreach ($id in (Get-F5Exp02OptionalTrackIds)) {
		if ((Get-F5ValidatorTrackStatus $ValPath $id) -ne "pass") { return $false }
	}
	return $true
}

function Get-F5FollowupPreflightPatterns {
	return @(
		@{ Label = "field care action"; Pattern = 'FP_WORLD: field_care (bandage|pressure) part='; Required = $true },
		@{ Label = "party triage"; Pattern = 'FP_WORLD: party_triage_open living='; Required = $true },
		@{ Label = "paid loss"; Pattern = 'company_run_end reason=contract_failed.*reload=true'; Required = $true },
		@{ Label = "desertion or wage"; Pattern = 'desertion summary=|FP_WORLD: company_wages: gold='; Required = $false }
	)
}

function Test-F5FollowupLog {
	param([string]$LogPath)
	$missing = New-Object System.Collections.Generic.List[string]
	$optionalMiss = New-Object System.Collections.Generic.List[string]
	foreach ($row in (Get-F5FollowupPreflightPatterns)) {
		if (Select-String -Path $LogPath -Pattern $row.Pattern -Quiet) { continue }
		if ($row.Required) { $missing.Add($row.Label) } else { $optionalMiss.Add($row.Label) }
	}
	$fatal = Test-F5SoakHasFatalErrors $LogPath
	return @{
		ok = ($missing.Count -eq 0) -and (-not $fatal)
		missing = $missing
		optional_miss = $optionalMiss
		fatal_errors = $fatal
	}
}

function Get-F5CampCoreMarkerScore {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return 0 }
	$score = 0
	if ((Select-String -Path $LogPath -Pattern '^FP_WORLD: settlement_continue' -Quiet) `
			-or (Select-String -Path $LogPath -Pattern '^FP_WORLD: contract_victory pay=' -Quiet)) {
		$score++
	}
	if (Select-String -Path $LogPath -Pattern '^FP_WORLD: company_day_advanced' -Quiet) {
		$score++
	}
	return $score
}

## Returns pass | optional_miss | fail | skipped | missing for one validator track row.
function Get-F5ValidatorTrackStatus {
	param(
		[string]$ValPath,
		[string]$TrackId
	)
	if (-not (Test-Path $ValPath)) { return "missing" }
	$pat = "^\[$([regex]::Escape($TrackId))\] "
	$match = Select-String -Path $ValPath -Pattern $pat | Select-Object -Last 1
	if (-not $match) { return "missing" }
	$line = $match.Line
	if ($line -match '\] PASS') { return "pass" }
	if ($line -match '\] OPTIONAL_MISS') { return "optional_miss" }
	if ($line -match '\] FAIL') { return "fail" }
	return "missing"
}

function Get-F5ValidationReportStamp {
	param([string]$ValPath)
	if (-not (Test-Path $ValPath)) { return [datetime]::MinValue }
	return (Get-Item $ValPath).LastWriteTimeUtc
}

function Get-F5CampSmokesBatchPath {
	param([string]$Root)
	return Join-Path $Root ".f5_camp_smokes_batch.txt"
}

function Test-F5ValidationFresh {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	$val = Join-Path $Root ".f5_soak_validation.txt"
	if (-not ((Test-Path $log) -and (Test-Path $val))) { return $false }
	if (-not (Select-String -Path $val -Pattern '^ok=true' -Quiet)) { return $false }
	if (-not (Select-String -Path $val -Pattern '^--- END FP_F5_SOAK_VALIDATION ---' -Quiet)) { return $false }
	return (Get-Item $val).LastWriteTime -ge (Get-Item $log).LastWriteTime
}

function Wait-F5CampSmokesBatchReport {
	param(
		[string]$BatchPath,
		[int]$TimeoutMs = 90000,
		[datetime]$NotBeforeUtc = [datetime]::MinValue
	)
	$deadline = [datetime]::UtcNow.AddMilliseconds($TimeoutMs)
	while ([datetime]::UtcNow -lt $deadline) {
		if (-not (Test-Path $BatchPath)) {
			Start-Sleep -Milliseconds 50
			continue
		}
		if ((Get-Item $BatchPath).LastWriteTimeUtc -le $NotBeforeUtc) {
			Start-Sleep -Milliseconds 50
			continue
		}
		if (Select-String -Path $BatchPath -Pattern '^--- END FP_F5_CAMP_SMOKES_BATCH ---' -Quiet) {
			return $true
		}
		Start-Sleep -Milliseconds 50
	}
	return $false
}

function Invoke-F5CampSmokesBatchGodot {
	param(
		[string]$Root,
		[switch]$Quiet
	)
	. (Join-Path $PSScriptRoot "Invoke-GodotHeadless.ps1")
	$batchPath = Get-F5CampSmokesBatchPath $Root
	if (Test-Path $batchPath) { Remove-Item -LiteralPath $batchPath -Force }
	if (-not $Quiet) {
		Write-Host "=== Camp optional smokes batch (one Godot) ==="
	}
	Invoke-FallenPathsGodotImportWarmup
	$outLog = Join-Path $env:TEMP "fp_camp_smokes_batch_$PID.log"
	$errLog = "$outLog.err"
	$Godot = Get-FallenPathsGodot
	$env:FP_HARNESS_MODE = "f5_validate_camp_smokes"
	$godotArgs = @("--headless", "--path", $Root, "-s", "res://tools/ci/run_all_combat_checks.gd")
	$p = Start-Process -FilePath $Godot -ArgumentList $godotArgs -Wait -PassThru -NoNewWindow `
		-RedirectStandardOutput $outLog -RedirectStandardError $errLog
	Remove-Item Env:FP_HARNESS_MODE -ErrorAction SilentlyContinue
	if (-not $Quiet -and (Test-Path $outLog)) {
		Get-Content $outLog | ForEach-Object { Write-Host $_ }
	}
	Remove-Item $outLog, $errLog -ErrorAction SilentlyContinue
	if ((Test-Path $batchPath) -and (Select-String -Path $batchPath -Pattern '^--- END FP_F5_CAMP_SMOKES_BATCH ---' -Quiet)) {
		return $true
	}
	if (-not $Quiet) {
		Write-Host "Camp smokes batch: Godot exit=$($p.ExitCode) (missing batch report - import warmup or parse error)"
	}
	Stop-F5StuckGodotProcesses
	return $false
}

function Stop-F5StuckGodotProcesses {
	Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Invoke-F5LogValidationWithRetry {
	param(
		[string]$ValidateScript,
		[string]$LogPath,
		[string]$ValPath,
		[ref]$ExitCode
	)
	$stamp = Get-F5ValidationReportStamp $ValPath
	& $ValidateScript -LogPath $LogPath -Quiet
	$ExitCode.Value = $LASTEXITCODE
	if (Wait-F5ValidationReport $ValPath -NotBeforeUtc $stamp) {
		return $true
	}
	Stop-F5StuckGodotProcesses
	Start-Sleep -Seconds 1
	$retryStamp = Get-F5ValidationReportStamp $ValPath
	& $ValidateScript -LogPath $LogPath -Quiet
	$ExitCode.Value = $LASTEXITCODE
	return (Wait-F5ValidationReport $ValPath -NotBeforeUtc $retryStamp)
}

function Write-Phase0SummaryCommit {
	param(
		[string]$Root,
		[System.Collections.Generic.List[string]]$Lines
	)
	$final = Join-Path $Root ".phase0_combat_checks.txt"
	$tmp = "$final.tmp"
	$Lines | Set-Content -LiteralPath $tmp -Encoding utf8
	Move-Item -LiteralPath $tmp -Destination $final -Force
}

function Wait-F5ValidationReport {
	param(
		[string]$ValPath,
		[int]$TimeoutMs = 45000,
		[datetime]$NotBeforeUtc = [datetime]::MinValue
	)
	$deadline = [datetime]::UtcNow.AddMilliseconds($TimeoutMs)
	while ([datetime]::UtcNow -lt $deadline) {
		if (-not (Test-Path $ValPath)) {
			Start-Sleep -Milliseconds 50
			continue
		}
		if ((Get-Item $ValPath).LastWriteTimeUtc -le $NotBeforeUtc) {
			Start-Sleep -Milliseconds 50
			continue
		}
		if (Select-String -Path $ValPath -Pattern '^--- END FP_F5_SOAK_VALIDATION ---' -Quiet) {
			return $true
		}
		Start-Sleep -Milliseconds 50
	}
	return $false
}

## Headless F5 validator (Windows). Start-Process -Wait avoids async Godot when validate is piped.
function Invoke-F5SoakLogValidateGodot {
	param(
		[string]$Root,
		[string[]]$GodotExtraArgs = @(),
		[switch]$SuppressOutput
	)
	if (-not (Get-Command Get-FallenPathsGodot -ErrorAction SilentlyContinue)) {
		. (Join-Path $PSScriptRoot "Invoke-GodotHeadless.ps1")
	}
	$outLog = Join-Path $env:TEMP "fp_f5_validate_$PID.log"
	$errLog = "$outLog.err"
	$Godot = Get-FallenPathsGodot
	$env:FP_HARNESS_MODE = "f5_validate"
	$godotArgs = @("--headless", "--path", $Root, "-s", "res://tools/ci/run_all_combat_checks.gd") + $GodotExtraArgs
	$p = Start-Process -FilePath $Godot -ArgumentList $godotArgs -Wait -PassThru -NoNewWindow `
		-RedirectStandardOutput $outLog -RedirectStandardError $errLog
	$code = $p.ExitCode
	if (-not $SuppressOutput -and (Test-Path $outLog)) {
		Get-Content $outLog | ForEach-Object { Write-Host $_ }
	}
	Remove-Item $outLog, $errLog -ErrorAction SilentlyContinue
	Remove-Item Env:FP_HARNESS_MODE -ErrorAction SilentlyContinue
	return $code
}

function Show-F5ValidationTrackSummary {
	param(
		[string]$ValPath,
		[switch]$IncludeMeta
	)
	if (-not (Test-Path $ValPath)) { return }
	if ($IncludeMeta) {
		Select-String -Path $ValPath -Pattern '^(ok=|profiles=)' | ForEach-Object { $_.Line }
	}
	Select-String -Path $ValPath -Pattern '^\[(camp_|wf_m3_)' | ForEach-Object { $_.Line }
}

function Get-F5Step9PreflightPatterns {
	return @(
		@{ Label = "tutorial soft loss"; Pattern = 'company_run_end reason=tutorial_failed.*reload=false'; Required = $false },
		@{ Label = "wage warn"; Pattern = 'FP_WORLD: company_wages: gold='; Required = $false },
		@{ Label = "desertion"; Pattern = 'desertion summary='; Required = $false }
	)
}

function Test-F5Step9FollowupLog {
	param([string]$LogPath)
	$hits = 0
	$fatal = Test-F5SoakHasFatalErrors $LogPath
	foreach ($row in (Get-F5Step9PreflightPatterns)) {
		if (Select-String -Path $LogPath -Pattern $row.Pattern -Quiet) {
			$hits++
		}
	}
	return @{
		ok = ($hits -ge 1) -and (-not $fatal)
		hits = $hits
		fatal_errors = $fatal
	}
}

function Restore-F5SoakHumanPasteIfClobbered {
	param([string]$Root)
	$log = Get-F5SoakLogPath $Root
	$bak = Get-F5SoakBackupPath $Root
	if (-not ((Test-Path $log) -and (Test-F5SoakHeadlessCaptureOnly $log) -and (Test-Path $bak))) { return $false }
	if (Test-F5SoakIsExampleSmoke $bak) { return $false }
	return (Restore-F5SoakHumanPaste -Root $Root)
}

function Ensure-F5HumanPasteValidationFresh {
	param([string]$Root, [switch]$ForceRefresh)
	if (-not $ForceRefresh -and (Test-F5ValidationFresh $Root)) { return $true }
	& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -Quiet
	return (Test-F5ValidationFresh $Root)
}

function Ensure-F5PlaytestValidatorReport {
	param([string]$Root, [switch]$ForceRefresh)
	return (Ensure-F5HumanPasteValidationFresh -Root $Root -ForceRefresh:$ForceRefresh)
}

function Get-F5PlaytestGapMergePlan {
	param([string]$Root, [string]$ValPath)
	$rows = @(
		@{ Track = "camp_mopup_strike_finish"; Label = "camp_mopup_smoke"; Rel = "docs/camp_optional_step_smokes/step3e_mopup.txt" },
		@{ Track = "camp_field_care_action"; Label = "camp_field_care_smoke"; Rel = "docs/camp_optional_step_smokes/step4_field_care_action.txt" },
		@{ Track = "camp_paid_loss"; Label = "camp_paid_loss_smoke"; Rel = "docs/camp_optional_step_smokes/step8_paid_loss.txt" },
		@{ Track = "camp_tutorial_soft_loss"; Label = "camp_tutorial_soft_smoke"; Rel = "docs/camp_optional_step_smokes/step8_tutorial_soft.txt" },
		@{ Track = "camp_wage_warn"; Label = "camp_wage_warn_smoke"; Rel = "docs/camp_optional_step_smokes/step9_wage_warn.txt" },
		@{ Track = "camp_desertion"; Label = "camp_desertion_smoke"; Rel = "docs/camp_optional_step_smokes/step9_desertion.txt" },
		@{ Track = "camp_party_triage"; Label = "camp_party_triage_smoke"; Rel = "docs/camp_optional_step_smokes/step10_party_triage.txt" },
		@{ Track = "camp_medical_exit"; Label = "camp_medical_exit_smoke"; Rel = "docs/camp_optional_step_smokes/medical_exit.txt" }
	)
	$plan = @()
	foreach ($row in $rows) {
		$st = Get-F5ValidatorTrackStatus -ValPath $ValPath -TrackId $row.Track
		if ($st -eq "pass") { continue }
		$plan += @{
			Reason = $row.Track
			Label = $row.Label
			Path = (Join-Path $Root $row.Rel)
		}
	}
	return $plan
}

function Test-F5PlaytestGapMergeRowAlreadySatisfied {
	param($Row, [string]$LogPath)
	return $false
}

function Get-F5MaintainedPasteAppendPlan {
	# Baseline replace is handled by rebuild script; gap fill via merge plan.
	return @()
}

function Show-F5SmokeAppendSummary {
	param([string]$LogPath, [switch]$Quiet)
	if ($Quiet -or -not (Test-Path $LogPath)) { return }
	$labels = Select-String -Path $LogPath -Pattern '^--- f5_soak_append: (.+) ---' | ForEach-Object { $_.Matches.Groups[1].Value }
	if ($labels.Count -eq 0) { Write-Host "Smoke append labels: (none)"; return }
	Write-Host ("Smoke append labels: {0}" -f ($labels -join ", "))
}

function Test-F5HumanCoverageComplete {
	param([string]$ValPath, [string]$LogPath)
	$plan = Get-F5PlaytestGapMergePlan -Root (Split-Path -Parent $ValPath) -ValPath $ValPath
	return ($plan.Count -eq 0)
}

function Show-F5HumanCoverageHints {
	param([string]$Root, [string]$ValPath)
	$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $ValPath
	if ($plan.Count -eq 0) {
		Write-Host "PLAYTEST_COVERAGE: PASS"
		return
	}
	Write-Host "PLAYTEST_COVERAGE: GAPS"
	foreach ($row in $plan) {
		Write-Host ("  [{0}] {1}" -f $row.Reason, $row.Label)
	}
}

function Show-F5PlaytestWorkflowHints {
	param([string]$Root, [string]$ValPath)
	Write-Host "Next: .\tools\ci\run_playtest.ps1 merge -DryRun"
}

function Get-F5HumanPasteAppendLabels {
	param([string]$LogPath)
	if (-not (Test-Path $LogPath)) { return @() }
	return @(Select-String -Path $LogPath -Pattern '^--- f5_soak_append: (.+) ---' | ForEach-Object { $_.Matches.Groups[1].Value })
}
