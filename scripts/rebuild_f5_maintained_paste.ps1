# Rebuild maintained human F5 paste from followup.log + standard append plan (Playtest stream).
param(
	[string]$BaselineFrom = "followup.log",
	[switch]$SkipPreflight,
	[switch]$HumanSignOff,
	[switch]$DryRun
)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "F5SoakLogHelpers.ps1")

$baseline = if ([System.IO.Path]::IsPathRooted($BaselineFrom)) { $BaselineFrom } else { Join-Path $Root $BaselineFrom }
if (-not (Test-Path $baseline)) {
	Write-Host "REBUILD_F5_MAINTAINED: FAIL (missing baseline $baseline)"
	exit 2
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
	Write-Host "REBUILD_F5_MAINTAINED: FAIL (baseline replace)"
	exit $LASTEXITCODE
}

foreach ($row in (Get-F5MaintainedPasteAppendPlan)) {
	$from = Join-Path $Root $row.From
	if (-not (Test-Path $from)) {
		Write-Host "REBUILD_F5_MAINTAINED: FAIL (missing $($row.From))"
		exit 2
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
	$appendArgs = @{
		AppendFrom = $row.From
		Label = $row.Label
	}
	if ($row.SkipPreflight -or $SkipPreflight) { $appendArgs.SkipPreflight = $true }
	& (Join-Path $PSScriptRoot "append_f5_soak_log.ps1") @appendArgs
	if ($LASTEXITCODE -ne 0) {
		Write-Host "REBUILD_F5_MAINTAINED: FAIL (append $($row.Label))"
		exit $LASTEXITCODE
	}
}

& (Join-Path $PSScriptRoot "run_playtest_revalidate.ps1") $(if ($HumanSignOff) { "-HumanSignOff" })
if ($LASTEXITCODE -ne 0) {
	Write-Host "REBUILD_F5_MAINTAINED: FAIL (revalidate)"
	exit $LASTEXITCODE
}
Write-Host "REBUILD_F5_MAINTAINED: PASS"
exit 0
