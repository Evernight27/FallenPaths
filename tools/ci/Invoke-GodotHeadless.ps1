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

function Get-FallenPathsTimeout {
    # $FP_TIMEOUT_SECONDS overrides; 0 disables the cap entirely (manual long soaks only).
    $raw = $env:FP_TIMEOUT_SECONDS
    if ([string]::IsNullOrWhiteSpace($raw)) { return 180 }
    $n = 0
    if ([int]::TryParse($raw, [ref]$n) -and $n -ge 0) { return $n }
    return 180
}

function Stop-FallenPathsProcessTree {
    param([System.Diagnostics.Process]$Proc)
    # Godot spawns no child harness processes, but a killed parent can orphan a
    # lingering editor lock; taskkill /T is the reliable tree teardown on Windows.
    try {
        & taskkill.exe /PID $Proc.Id /T /F 2>&1 | Out-Null
    } catch {
        try { $Proc.Kill() } catch { }
    }
}

function Test-FallenPathsGodotTimedOut {
    return [bool]$script:LastFallenPathsGodotTimedOut
}

function Invoke-FallenPathsGodotScript {
    param(
        [string]$Script = "res://tools/ci/run_all_combat_checks.gd",
        [string]$HarnessMode = "",
        [string[]]$GodotExtraArgs = @(),
        [string]$TeeLog = "",
        [int]$TimeoutSeconds = 0
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
    if ($TimeoutSeconds -le 0) {
        $TimeoutSeconds = Get-FallenPathsTimeout
    }
    # Hard wall-clock cap: a hung headless run must not spin forever under an agent.
    $proc = Start-Process -FilePath $Godot -ArgumentList $godotInvokeArgs -PassThru -NoNewWindow
    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        Write-Host "TIMEOUT: Godot exceeded ${TimeoutSeconds}s - killing pid $($proc.Id) ($Script $HarnessMode)" -ForegroundColor Yellow
        Stop-FallenPathsProcessTree $proc
        $script:LastFallenPathsGodotExitCode = 124
        $script:LastFallenPathsGodotTimedOut = $true
        if ($hadMode) {
            Remove-Item Env:FP_HARNESS_MODE -ErrorAction SilentlyContinue
        }
        return
    }
    $script:LastFallenPathsGodotExitCode = $proc.ExitCode
    $script:LastFallenPathsGodotTimedOut = $false
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
    $timeout = Get-FallenPathsTimeout
    if ($timeout -gt 0) {
        # Import is normally ~7s; cap it well below the harness budget so a stuck
        # import surfaces immediately instead of consuming the whole run.
        $timeout = [Math]::Min($timeout, 120)
        $proc = Start-Process -FilePath $Godot -ArgumentList @("--headless", "--path", $Root, "--import") -PassThru -NoNewWindow
        if (-not $proc.WaitForExit($timeout * 1000)) {
            Write-Host "TIMEOUT: Godot --import exceeded ${timeout}s - killing pid $($proc.Id)" -ForegroundColor Yellow
            Stop-FallenPathsProcessTree $proc
        }
    } else {
        & $Godot --headless --path $Root --import 2>&1 | Out-Null
    }
    if ($SleepSeconds -gt 0) {
        Start-Sleep -Seconds $SleepSeconds
    }
}
