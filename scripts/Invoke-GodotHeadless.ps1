# Shared Godot 4 headless launcher for scripts/*.ps1 wrappers.
# Returns exit code only — do not pipe this function (use TeeLog for log capture).
function Get-FallenPathsGodot {
	if ($env:GODOT) { return $env:GODOT }
	$default = "e:\Godot_v4.6-stable_win64.exe"
	if (Test-Path $default) { return $default }
	throw "Set GODOT to your Godot 4 binary (or install at $default)"
}

function Get-FallenPathsRoot {
	return (Split-Path -Parent $PSScriptRoot)
}

function Invoke-FallenPathsGodotScript {
	param(
		[string]$Script = "res://scripts/run_all_combat_checks.gd",
		[string]$HarnessMode = "",
		[string[]]$GodotExtraArgs = @(),
		[string]$TeeLog = ""
	)
	$Godot = Get-FallenPathsGodot
	$Root = Get-FallenPathsRoot
	$hadMode = $false
	if ($HarnessMode -ne "") {
		$env:FP_HARNESS_MODE = $HarnessMode
		$hadMode = $true
	}
	$godotInvokeArgs = @("--headless", "--path", $Root, "-s", $Script) + $GodotExtraArgs
	if ($TeeLog -ne "") {
		& $Godot @godotInvokeArgs 2>&1 | Tee-Object -FilePath $TeeLog
	} else {
		& $Godot @godotInvokeArgs 2>&1
	}
	$script:LastFallenPathsGodotExitCode = $LASTEXITCODE
	if ($hadMode) {
		Remove-Item Env:FP_HARNESS_MODE -ErrorAction SilentlyContinue
	}
	# Do not `return $code` — PowerShell would emit it on the success stream and break `2>&1 | ForEach-Object` capture.
}

function Get-FallenPathsGodotExitCode {
	if ($null -ne $script:LastFallenPathsGodotExitCode) {
		return [int]$script:LastFallenPathsGodotExitCode
	}
	return [int]$LASTEXITCODE
}

## Headless `--import` so global class cache is warm before `-s` harness scripts (avoids cold-start parse flakes).
function Invoke-FallenPathsGodotImportWarmup {
	param([int]$SleepSeconds = 2)
	$Godot = Get-FallenPathsGodot
	$Root = Get-FallenPathsRoot
	& $Godot --headless --path $Root --import 2>&1 | Out-Null
	if ($SleepSeconds -gt 0) {
		Start-Sleep -Seconds $SleepSeconds
	}
}
