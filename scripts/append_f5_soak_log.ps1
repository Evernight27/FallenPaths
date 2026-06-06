# Merge F5 Output into .f5_soak_in.txt and re-run CombatF5SoakLogValidator.
# Usage: .\scripts\append_f5_soak_log.ps1 -AppendFrom path\to\chunk.txt [-Replace]
param(
	[Parameter(Mandatory = $true)]
	[string]$AppendFrom,
	[switch]$Replace
)
$ErrorActionPreference = "Continue"
& (Join-Path $PSScriptRoot "validate_f5_soak_log.ps1") -AppendFrom $AppendFrom -Replace:$Replace
exit $LASTEXITCODE
