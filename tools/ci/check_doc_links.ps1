# Doc link + tombstone + res:// path gate — delegates to check_doc_links.py (single implementation).
$ErrorActionPreference = "Stop"
$pyScript = Join-Path $PSScriptRoot "check_doc_links.py"
if (-not (Get-Command python3 -ErrorAction SilentlyContinue)) {
	Write-Error "python3 required for check_doc_links.ps1"
	exit 127
}
& python3 $pyScript
exit $LASTEXITCODE
