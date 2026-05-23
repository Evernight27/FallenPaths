# Optional Q headless audits (no F5). -Track Q1 | Q2 | Track
param(
	[Parameter(Mandatory = $true)]
	[ValidateSet("Q1", "Q2", "Track")]
	[string]$Track
)
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\Invoke-GodotHeadless.ps1"
$gd = switch ($Track) {
	"Q1" { "res://scripts/run_q1_research_feel_audit.gd" }
	"Q2" { "res://scripts/run_q2_ii2b_feel_audit.gd" }
	"Track" { "res://scripts/run_q_track_audits.gd" }
}
Invoke-FallenPathsGodotScript -Script $gd | Out-Null
exit $LASTEXITCODE
