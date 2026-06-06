# Headless Q track audits (Camp-3.4 proxies; no F5 sign-off).
#   .\scripts\run_q_audit.ps1 -Track Track
#   .\scripts\run_q_audit.ps1 -Track Q1
#   .\scripts\run_q_audit.ps1 -Track Q2
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet("Q1", "Q2", "Track")]
	[string]$Track
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$Root = Get-FallenPathsRoot

Write-Host "=== Q track audit ($Track) ==="
Invoke-FallenPathsGodotScript -Script "res://scripts/run_q_track_audits.gd"
$godotExit = $LASTEXITCODE
if ($godotExit -ne 0) {
	exit $godotExit
}

$qTrackPath = Join-Path $Root ".q_track_audits.txt"
if (-not (Test-Path $qTrackPath)) {
	Write-Error "Missing .q_track_audits.txt after Q track run"
	exit 1
}

function Get-QTrackSection {
	param([string]$Path, [string]$HeaderPattern)
	$lines = Get-Content -LiteralPath $Path -Encoding utf8
	$out = New-Object System.Collections.Generic.List[string]
	$inSection = $false
	foreach ($line in $lines) {
		if ($line -match $HeaderPattern) {
			$inSection = $true
			$out.Add($line)
			continue
		}
		if ($inSection -and $line -match '^\[Q') {
			break
		}
		if ($inSection) {
			$out.Add($line)
		}
	}
	return ,$out
}

function Test-SectionBoundaryFail {
	param([System.Collections.Generic.List[string]]$SectionLines)
	foreach ($line in $SectionLines) {
		if ($line -match 'BOUNDARY_FAIL') {
			return $true
		}
	}
	return $false
}

switch ($Track) {
	"Track" {
		Get-Content -LiteralPath $qTrackPath -Encoding utf8 | Write-Host
		if (Select-String -LiteralPath $qTrackPath -Pattern "BOUNDARY_FAIL" -Quiet) {
			exit 1
		}
		exit 0
	}
	"Q1" {
		$section = Get-QTrackSection -Path $qTrackPath -HeaderPattern '^\[Q1 '
		$outPath = Join-Path $Root ".q1_research_feel_audit.txt"
		$section | Set-Content -LiteralPath $outPath -Encoding utf8
		$section | ForEach-Object { Write-Host $_ }
		if ($section.Count -eq 0) {
			Write-Error "Q1 section missing in .q_track_audits.txt"
			exit 1
		}
		if (Test-SectionBoundaryFail -SectionLines $section) {
			exit 1
		}
		exit 0
	}
	"Q2" {
		$section = Get-QTrackSection -Path $qTrackPath -HeaderPattern '^\[Q2 '
		$outPath = Join-Path $Root ".q2_ii2b_feel_audit.txt"
		$section | Set-Content -LiteralPath $outPath -Encoding utf8
		$section | ForEach-Object { Write-Host $_ }
		if ($section.Count -eq 0) {
			Write-Error "Q2 section missing in .q_track_audits.txt"
			exit 1
		}
		if (Test-SectionBoundaryFail -SectionLines $section) {
			exit 1
		}
		exit 0
	}
}
