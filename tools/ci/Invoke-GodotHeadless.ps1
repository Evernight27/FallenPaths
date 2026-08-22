# Shared Godot 4 headless launcher for tools/ci/*.ps1 wrappers.
# Returns exit code only — do not pipe this function (use TeeLog for log capture).
#
# Resolution: $env:GODOT, then E:\Godot_v4.7-stable_win64.exe (Windows teammates).
# Linux/macOS: use tools/ci/_godot.sh (Steam / Flatpak / PATH).
function Get-FallenPathsGodot {
	if ($env:GODOT) { return $env:GODOT }
	$default = "E:\Godot_v4.7-stable_win64.exe"
	if (Test-Path $default) { return $default }
	throw "Set GODOT to your Godot 4 binary (or install at $default). Linux: tools/ci/_godot.sh"
}

function Get-FallenPathsRoot {
	# tools/ci → repo root (parent of tools)
	$tools = Split-Path -Parent $PSScriptRoot
	$root = Split-Path -Parent $tools
	if (Test-Path (Join-Path $root "project.godot")) {
		return $root
	}
	return (Split-Path -Parent $PSScriptRoot)
}

function Invoke-FallenPathsGodotScript {
	param(
		[string]$Script = "res://tools/ci/run_all_combat_checks.gd",
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
	# No downstream pipe — $LASTEXITCODE after `| Tee-Object` / `ForEach-Object` is not Godot's.
	# Note: capturing Godot's output via 2>&1 into an array can interfere with GDScript file I/O
	# (Godot's internal logging interacts poorly with active pipeline consumers on Windows).
	# Use --log-file for log capture instead of stdout redirection.
	if ($TeeLog -ne "") {
		$godotInvokeArgs += @("--log-file", $TeeLog)
	}
	& $Godot @godotInvokeArgs 2>&1 | Out-Null
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
