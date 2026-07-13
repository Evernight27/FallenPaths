# Playtest dispatcher (no Phase 0).
#   .\scripts\run_playtest.ps1 status|merge|revalidate|recover|after-append|full|exp0|rebuild …
param(
	[Parameter(Position = 0, Mandatory = $true)]
	[string]$Command,
	[Parameter(ValueFromRemainingArguments = $true)]
	[object[]]$RestArgs
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")
$Self = $PSCommandPath

function Invoke-Self {
	param([string]$SubCommand, [object[]]$Args = @())
	& $Self $SubCommand @Args
	return $LASTEXITCODE
}

function Require-HumanLog {
	param([string]$Prefix, [int]$ExitCode = 1)
	$log = Get-F5SoakLogPath $Root
	if (-not (Test-Path $log)) {
		Write-Host "$Prefix`: FAIL (missing .f5_soak_in.txt)"
		exit $ExitCode
	}
	if (Test-F5SoakHeadlessCaptureOnly $log) {
		Write-Host "$Prefix`: FAIL (headless D001 capture - run .\scripts\restore_f5_soak_log.ps1)"
		exit $ExitCode
	}
	return $log
}

function Get-Switch {
	param([object[]]$Args, [string]$Name)
	return ($Args | Where-Object { "$_" -eq "-$Name" -or "$_" -eq "-$Name".ToLowerInvariant() }).Count -gt 0
}

function Get-NamedString {
	param([object[]]$Args, [string]$Name)
	for ($i = 0; $i -lt $Args.Count; $i++) {
		if ("$($Args[$i])" -eq "-$Name" -and $i + 1 -lt $Args.Count) {
			return [string]$Args[$i + 1]
		}
	}
	return ""
}

$key = $Command.ToLowerInvariant()

switch ($key) {
	"status" {
		$Refresh = Get-Switch $RestArgs "Refresh"
		$ShowGaps = Get-Switch $RestArgs "ShowGaps"
		$SmokeLabels = Get-Switch $RestArgs "SmokeLabels"
		$Quiet = Get-Switch $RestArgs "Quiet"
		Write-Host "=== Playtest status (no Phase 0) ==="
		Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
		$log = Require-HumanLog "PLAYTEST_STATUS" 2
		$val = Join-Path $Root ".f5_soak_validation.txt"
		if ($Refresh) {
			if (-not (Ensure-F5PlaytestValidatorReport -Root $Root -ForceRefresh)) {
				Write-Host "PLAYTEST_STATUS: FAIL (validate_f5_soak_log)"; exit 1
			}
		} elseif (-not (Ensure-F5PlaytestValidatorReport -Root $Root)) {
			Write-Host "PLAYTEST_STATUS: FAIL (validate_f5_soak_log refresh)"; exit 1
		}
		Write-Host ("human_signoff: " + (Get-F5HumanSignoffStatus $log))
		if ($SmokeLabels -or (-not $Quiet)) {
			Show-F5SmokeAppendSummary -LogPath $log -Quiet:($Quiet -and -not $SmokeLabels)
		}
		if (-not (Test-Path $val)) {
			Write-Host "PLAYTEST_STATUS: FAIL (no .f5_soak_validation.txt - run -Refresh)"; exit 1
		}
		if (-not (Select-String -Path $val -Pattern "^ok=true" -Quiet)) {
			Write-Host "PLAYTEST_STATUS: FAIL (validator ok=false - run -Refresh)"; exit 1
		}
		if (-not $Quiet) {
			$profiles = (Select-String -Path $val -Pattern "^profiles=" | Select-Object -First 1).Line
			if ($profiles) { Write-Host $profiles.Trim() }
		}
		if (-not (Test-F5ValidationFresh $Root)) {
			Write-Host "PLAYTEST_STATUS: FAIL (validation stale - run -Refresh)"; exit 1
		}
		$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
		if ($ShowGaps -or ($plan.Count -gt 0)) {
			if ($plan.Count -eq 0) {
				Write-Host "Merge gaps: none"
			} else {
				Write-Host ("Merge gaps: {0} append(s)" -f $plan.Count)
				foreach ($row in $plan) {
					Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
				}
				if (-not $ShowGaps) {
					Write-Host "Hint: .\scripts\run_playtest.ps1 merge -DryRun"
				}
			}
		}
		if (-not $Quiet) {
			Show-F5HumanCoverageHints -Root $Root -ValPath $val
		} elseif (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
			Write-Host "PLAYTEST_COVERAGE: PASS (A-F + optional validator tracks on human paste)"
		} else {
			Write-Host "PLAYTEST_COVERAGE: GAPS (run .\scripts\run_playtest.ps1 merge -DryRun)"
		}
		if (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
			Write-Host "PLAYTEST_STATUS: PASS"
			if (-not $Quiet) { Show-F5PlaytestWorkflowHints -Root $Root -ValPath $val }
			exit 0
		}
		$labels = Get-F5HumanPasteAppendLabels $log
		if ($labels.Count -gt 0) {
			Write-Host ("Hint: smoke labels in paste ({0}) but coverage incomplete - run -Refresh" -f ($labels -join ", "))
		}
		Show-F5PlaytestWorkflowHints -Root $Root -ValPath $val
		Write-Host "PLAYTEST_STATUS: GAPS"
		exit 1
	}
	{ $_ -in @("merge", "merge-gaps") } {
		$DryRun = Get-Switch $RestArgs "DryRun"
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$SkipRevalidate = Get-Switch $RestArgs "SkipRevalidate"
		Write-Host "=== Playtest merge gaps ==="
		Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
		$log = Require-HumanLog "PLAYTEST_MERGE_GAPS"
		$val = Join-Path $Root ".f5_soak_validation.txt"
		if (-not (Ensure-F5PlaytestValidatorReport -Root $Root)) {
			Write-Host "PLAYTEST_MERGE_GAPS: FAIL (validate_f5_soak_log before merge)"; exit 1
		}
		if ($DryRun -and (Test-F5ValidationFresh $Root)) {
			Write-Host "Validator report: fresh (skipped Godot re-run)"
		}
		$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
		if ($plan.Count -eq 0) {
			Write-Host "PLAYTEST_MERGE_GAPS: no gaps (validator + human coverage complete)"
			if (-not $SkipRevalidate -and -not $DryRun) {
				$rev = @()
				if ($HumanSignOff) { $rev += "-HumanSignOff" }
				exit (Invoke-Self "revalidate" $rev)
			}
			exit 0
		}
		Write-Host ("Gaps found: {0}" -f $plan.Count)
		foreach ($row in $plan) {
			Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
		}
		if ($DryRun) {
			Write-Host "PLAYTEST_MERGE_GAPS: dry-run (no append)"; exit 0
		}
		foreach ($row in $plan) {
			if (-not (Test-Path $row.Path)) {
				Write-Host "PLAYTEST_MERGE_GAPS: FAIL (missing chunk $($row.Path))"; exit 2
			}
			if (Test-F5PlaytestGapMergeRowAlreadySatisfied $row $log) {
				Write-Host ("Skip append [{0}] - already satisfied in paste" -f $row.Label)
				continue
			}
			& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") -AppendFrom $row.Path -Label $row.Label
			if ($LASTEXITCODE -ne 0) {
				Write-Host "PLAYTEST_MERGE_GAPS: FAIL (append $($row.Label))"; exit $LASTEXITCODE
			}
		}
		if ($SkipRevalidate) {
			Write-Host "PLAYTEST_MERGE_GAPS: PASS (appended; skipped revalidate)"; exit 0
		}
		$rev = @()
		if ($HumanSignOff) { $rev += "-HumanSignOff" }
		$code = Invoke-Self "revalidate" $rev
		if ($code -ne 0) {
			Write-Host "PLAYTEST_MERGE_GAPS: FAIL (post-merge revalidate)"; exit $code
		}
		Write-Host "PLAYTEST_MERGE_GAPS: PASS"
		exit 0
	}
	"revalidate" {
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$SkipSmokes = Get-Switch $RestArgs "SkipSmokes"
		$SkipCloseout = Get-Switch $RestArgs "SkipCloseout"
		$Exp0Gate = Get-Switch $RestArgs "Exp0Gate"
		Write-Host "=== Playtest re-validate (no Phase 0) ==="
		Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
		Require-HumanLog "PLAYTEST_REVALIDATE" | Out-Null
		& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -Quiet
		if ($LASTEXITCODE -ne 0) {
			Write-Host "PLAYTEST_REVALIDATE: FAIL (validate_f5_soak_log)"; exit $LASTEXITCODE
		}
		if (-not $SkipSmokes) {
			& (Join-Path $PSScriptRoot "validate_camp_optional_smokes.ps1") -Quiet
			if ($LASTEXITCODE -ne 0) {
				Write-Host "PLAYTEST_REVALIDATE: FAIL (camp optional smokes)"; exit $LASTEXITCODE
			}
			Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
		} elseif (-not (Test-F5ValidationFresh $Root)) {
			Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
		}
		if ($SkipCloseout) {
			Write-Host "PLAYTEST_REVALIDATE: PASS (skipped closeout)"; exit 0
		}
		& (Join-Path $PSScriptRoot "run_camp_f5_closeout.ps1") -SkipRevalidate $(if ($HumanSignOff) { "-HumanSignOff" })
		if ($LASTEXITCODE -ne 0) {
			Write-Host "PLAYTEST_REVALIDATE: FAIL (closeout)"; exit $LASTEXITCODE
		}
		if ($Exp0Gate) {
			$code = Invoke-Self "exp0" @("-SkipCloseout")
			if ($code -ne 0) {
				Write-Host "PLAYTEST_REVALIDATE: FAIL (Exp-0.2 gate smokes)"; exit $code
			}
		}
		Write-Host "PLAYTEST_REVALIDATE: PASS"
		exit 0
	}
	"recover" {
		$DryRun = Get-Switch $RestArgs "DryRun"
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$ForceRestore = Get-Switch $RestArgs "ForceRestore"
		Write-Host "=== Playtest recover (no Phase 0) ==="
		$log = Get-F5SoakLogPath $Root
		$bak = Get-F5SoakBackupPath $Root
		$restored = Restore-F5SoakHumanPasteIfClobbered -Root $Root
		if (-not $restored) {
			if ((Test-Path $log) -and (Test-F5SoakHeadlessCaptureOnly $log) -and (Test-Path $bak)) {
				if ($ForceRestore -or $DryRun) {
					if (-not $DryRun) {
						Restore-F5SoakHumanPaste -Root $Root | Out-Null
					} else {
						Write-Host "Would restore human paste from $bak (headless capture detected)"
					}
				} else {
					Write-Host "PLAYTEST_RECOVER: FAIL (headless capture - re-run with -ForceRestore or .\scripts\restore_f5_soak_log.ps1)"
					exit 2
				}
			}
		}
		Require-HumanLog "PLAYTEST_RECOVER" 2 | Out-Null
		if ($DryRun) {
			Show-F5SmokeAppendSummary -LogPath $log
			$val = Join-Path $Root ".f5_soak_validation.txt"
			if (Ensure-F5PlaytestValidatorReport -Root $Root) {
				if (Test-F5ValidationFresh $Root) {
					Write-Host "Validator report: fresh (skipped Godot re-run)"
				}
			} else {
				Write-Host "WARN: validator report missing or stale after refresh attempt"
			}
			$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
			if ($plan.Count -eq 0) {
				Write-Host "Merge gaps: none"
			} else {
				Write-Host ("Merge gaps: {0} append(s)" -f $plan.Count)
				foreach ($row in $plan) {
					Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
				}
			}
			Show-F5HumanCoverageHints -Root $Root -ValPath $val
			Write-Host "PLAYTEST_RECOVER: dry-run"
			exit 0
		}
		Ensure-F5HumanPasteValidationFresh -Root $Root | Out-Null
		$merge = @()
		if ($HumanSignOff) { $merge += "-HumanSignOff" }
		$code = Invoke-Self "merge" $merge
		if ($code -ne 0) { exit $code }
		exit (Invoke-Self "status" @("-Quiet"))
	}
	{ $_ -in @("after-append", "after_append") } {
		$AppendFrom = ""
		if ($RestArgs.Count -ge 1 -and "$($RestArgs[0])" -notlike "-*") {
			$AppendFrom = [string]$RestArgs[0]
			$RestArgs = @($RestArgs | Select-Object -Skip 1)
		}
		$named = Get-NamedString $RestArgs "AppendFrom"
		if ($named -ne "") { $AppendFrom = $named }
		if ($AppendFrom -eq "") {
			Write-Host "Usage: .\scripts\run_playtest.ps1 after-append <chunk.txt> [-Label name] [-HumanSignOff] [-SkipCloseout]"
			exit 2
		}
		$Label = Get-NamedString $RestArgs "Label"
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$SkipCloseout = Get-Switch $RestArgs "SkipCloseout"
		Write-Host "=== Playtest after append (no Phase 0) ==="
		Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
		$appendArgs = @{ AppendFrom = $AppendFrom }
		if ($Label -ne "") { $appendArgs.Label = $Label }
		& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") @appendArgs
		if ($LASTEXITCODE -ne 0) {
			Write-Host "PLAYTEST_AFTER_APPEND: FAIL (append)"; exit $LASTEXITCODE
		}
		$revalidateArgs = @("-SkipSmokes")
		if ($HumanSignOff) { $revalidateArgs += "-HumanSignOff" }
		if ($SkipCloseout) { $revalidateArgs += "-SkipCloseout" }
		$code = Invoke-Self "revalidate" $revalidateArgs
		if ($code -ne 0) {
			Write-Host "PLAYTEST_AFTER_APPEND: FAIL (revalidate)"; exit $code
		}
		Show-F5SmokeAppendSummary -LogPath (Get-F5SoakLogPath $Root)
		Write-Host "PLAYTEST_AFTER_APPEND: PASS"
		Write-Host "Next: .\scripts\run_playtest.ps1 full -HumanSignOff (optional smokes batch)"
		exit 0
	}
	{ $_ -in @("full", "full-gate") } {
		$DryRun = Get-Switch $RestArgs "DryRun"
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$SkipExp0 = Get-Switch $RestArgs "SkipExp0"
		Write-Host "=== Playtest full gate (no Phase 0) ==="
		$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
		if (-not ((Test-Path $phase0) -and (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
				-and (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet))) {
			Write-Host "PLAYTEST_FULL_GATE: FAIL (headless not green - run .\scripts\run_all_combat_checks.ps1 first)"
			exit 1
		}
		if ($DryRun) {
			Restore-F5SoakHumanPasteIfClobbered -Root $Root | Out-Null
			$val = Join-Path $Root ".f5_soak_validation.txt"
			$log = Get-F5SoakLogPath $Root
			if (Ensure-F5PlaytestValidatorReport -Root $Root) {
				if (Test-F5ValidationFresh $Root) {
					Write-Host "Validator report: fresh (skipped Godot re-run)"
				}
			} else {
				Write-Host "WARN: validator report missing or stale after refresh attempt"
			}
			Show-F5SmokeAppendSummary -LogPath $log
			$plan = Get-F5PlaytestGapMergePlan -Root $Root -ValPath $val
			if ($plan.Count -eq 0) {
				Write-Host "PLAYTEST_FULL_GATE: no merge gaps"
			} else {
				Write-Host ("Merge plan: {0} append(s)" -f $plan.Count)
				foreach ($row in $plan) {
					Write-Host ("  [{0}] {1} <- {2}" -f $row.Reason, $row.Label, $row.Path)
				}
			}
			if (Test-F5HumanCoverageComplete -ValPath $val -LogPath $log) {
				Write-Host "PLAYTEST_COVERAGE: PASS (would run revalidate + Exp-0.2)"
			} else {
				Show-F5HumanCoverageHints -Root $Root -ValPath $val
			}
			exit 0
		}
		$code = Invoke-Self "merge" @("-SkipRevalidate")
		if ($code -ne 0) { exit $code }
		$revalidateArgs = @()
		if ($HumanSignOff) { $revalidateArgs += "-HumanSignOff" }
		if (-not $SkipExp0) { $revalidateArgs += "-Exp0Gate" }
		$code = Invoke-Self "revalidate" $revalidateArgs
		if ($code -ne 0) {
			Write-Host "PLAYTEST_FULL_GATE: FAIL"; exit $code
		}
		Write-Host "PLAYTEST_FULL_GATE: PASS"
		exit 0
	}
	{ $_ -in @("exp0", "exp0-gate") } {
		$SkipCloseout = Get-Switch $RestArgs "SkipCloseout"
		$phase0 = Join-Path $Root ".phase0_combat_checks.txt"
		$phase0Stamp = Join-Path $Root ".phase0_playtest_gate_stamp.txt"
		$phase0Green = (Test-Path $phase0) -and (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
			-and (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet)
		if (-not $phase0Green) {
			Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (headless not green - run .\scripts\run_all_combat_checks.ps1 first)"
			exit 1
		}
		Copy-Item -LiteralPath $phase0 -Destination $phase0Stamp -Force
		Write-Host "=== Exp-0.2 Playtest gate ==="
		& (Join-Path $PSScriptRoot "validate_camp_optional_smokes.ps1")
		if ($LASTEXITCODE -ne 0) {
			Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (optional smokes)"; exit $LASTEXITCODE
		}
		if ($SkipCloseout) {
			Write-Host "EXP_0_2_PLAYTEST_GATE: PASS (smokes only; skipped closeout)"; exit 0
		}
		if ((Test-Path $phase0Stamp) -and (-not (Select-String -Path $phase0 -Pattern "^PHASE0: PASS" -Quiet) `
				-or -not (Select-String -Path $phase0 -Pattern "^CAMPAIGN_SHIP_AUDIT: PASS" -Quiet))) {
			Copy-Item -LiteralPath $phase0Stamp -Destination $phase0 -Force
		}
		& (Join-Path $PSScriptRoot "run_camp_f5_closeout.ps1") -HumanSignOff -SkipRevalidate
		if ($LASTEXITCODE -ne 0) {
			Write-Host "EXP_0_2_PLAYTEST_GATE: FAIL (closeout)"; exit $LASTEXITCODE
		}
		Write-Host "EXP_0_2_PLAYTEST_GATE: PASS"
		exit 0
	}
	"rebuild" {
		$BaselineFrom = "followup.log"
		if ($RestArgs.Count -ge 1 -and "$($RestArgs[0])" -notlike "-*") {
			$BaselineFrom = [string]$RestArgs[0]
			$RestArgs = @($RestArgs | Select-Object -Skip 1)
		}
		$named = Get-NamedString $RestArgs "BaselineFrom"
		if ($named -ne "") { $BaselineFrom = $named }
		$SkipPreflight = Get-Switch $RestArgs "SkipPreflight"
		$HumanSignOff = Get-Switch $RestArgs "HumanSignOff"
		$DryRun = Get-Switch $RestArgs "DryRun"
		$ErrorActionPreference = "Stop"
		$baseline = if ([System.IO.Path]::IsPathRooted($BaselineFrom)) { $BaselineFrom } else { Join-Path $Root $BaselineFrom }
		if (-not (Test-Path $baseline)) {
			Write-Host "REBUILD_F5_MAINTAINED: FAIL (missing baseline $baseline)"; exit 2
		}
		Write-Host "=== Rebuild maintained F5 paste ==="
		Write-Host "Baseline: $baseline"
		if ($DryRun) {
			Write-Host "Append plan (after baseline replace):"
			Write-Host "  [camp5_baseline] <- $baseline"
			foreach ($row in (Get-F5MaintainedPasteAppendPlan)) {
				Write-Host ("  [{0}] <- {1}" -f $row.Label, $row.From)
			}
			Write-Host "REBUILD_F5_MAINTAINED: dry-run (no replace/append)"
			exit 0
		}
		& (Join-Path $PSScriptRoot "preflight_f5_followup.ps1") $BaselineFrom
		if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
		& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -AppendFrom $BaselineFrom -Replace -Label camp5_baseline
		if ($LASTEXITCODE -ne 0) {
			Write-Host "REBUILD_F5_MAINTAINED: FAIL (baseline replace)"; exit $LASTEXITCODE
		}
		foreach ($row in (Get-F5MaintainedPasteAppendPlan)) {
			$from = Join-Path $Root $row.From
			if (-not (Test-Path $from)) {
				Write-Host "REBUILD_F5_MAINTAINED: FAIL (missing $($row.From))"; exit 2
			}
			if (-not $SkipPreflight -and $row.Preflight) {
				$preflight = Join-Path $PSScriptRoot "preflight_f5_followup.ps1"
				switch ($row.Preflight) {
					"Step9Only" { & $preflight $row.From -Step9Only }
					"IiEnvelopOnly" { & $preflight $row.From -IiEnvelopOnly }
					"OptionalTracksOnly" { & $preflight $row.From -OptionalTracksOnly }
					"CyanPresetsOnly" { & $preflight $row.From -CyanPresetsOnly }
				}
				if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
			}
			$appendArgs = @{ AppendFrom = $row.From; Label = $row.Label }
			if ($row.SkipPreflight -or $SkipPreflight) { $appendArgs.SkipPreflight = $true }
			& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") @appendArgs
			if ($LASTEXITCODE -ne 0) {
				Write-Host "REBUILD_F5_MAINTAINED: FAIL (append $($row.Label))"; exit $LASTEXITCODE
			}
		}
		$rev = @()
		if ($HumanSignOff) { $rev += "-HumanSignOff" }
		$code = Invoke-Self "revalidate" $rev
		if ($code -ne 0) {
			Write-Host "REBUILD_F5_MAINTAINED: FAIL (revalidate)"; exit $code
		}
		Write-Host "REBUILD_F5_MAINTAINED: PASS"
		exit 0
	}
	default {
		Write-Error "Unknown command '$Command'. Use: status|merge|revalidate|recover|after-append|full|exp0|rebuild"
		exit 2
	}
}
