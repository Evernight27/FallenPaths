# Verify docs/*.md links resolve; tombstone filenames in LIVE_PATHS#redirects-tombstones must not exist.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$DocsDir = Join-Path $Root "docs"
$Pattern = '\[[^\]]*\]\(([^)#]+\.md)(?:#[^)]+)?\)'
$Canonical = @("CURSOR.md", "LIVE_PATHS.md")
$LivePathsPath = Join-Path $DocsDir "LIVE_PATHS.md"

$broken = @()
Get-ChildItem $DocsDir -Filter "*.md" | ForEach-Object {
	$from = $_.Name
	$text = Get-Content $_.FullName -Raw
	foreach ($m in [regex]::Matches($text, $Pattern)) {
		$target = $m.Groups[1].Value
		if ($target -match '^https?://') { continue }
		$baseDir = $_.DirectoryName
		$resolved = if ($target -match '^\.?\.?/') {
			Join-Path $baseDir ($target -replace '/', '\')
		} else {
			Join-Path $DocsDir $target
		}
		$resolved = [System.IO.Path]::GetFullPath($resolved)
		if (-not (Test-Path $resolved)) {
			$broken += "broken link: ${from} -> ${target}"
		}
	}
}

$tombstones = @()
if (Test-Path $LivePathsPath) {
	$redirectText = Get-Content $LivePathsPath -Raw
	foreach ($m in [regex]::Matches($redirectText, '\|\s*`([^`]+)`\s*\|')) {
		$raw = $m.Groups[1].Value.Trim()
		if ($raw -match '\*') {
			$prefix = $raw -replace '\*.*$', ''
			Get-ChildItem $DocsDir -Filter ($prefix + "*.md") -ErrorAction SilentlyContinue | ForEach-Object {
				$tombstones += $_.Name
			}
		} else {
			if ($raw -match ' \(') { $raw = ($raw -split ' \(')[0].Trim() }
			$tombstones += $raw
		}
	}
}
$tombstones = $tombstones | Sort-Object -Unique
foreach ($name in $tombstones) {
	if ($Canonical -contains $name) { continue }
	$path = Join-Path $DocsDir $name
	if (Test-Path $path) {
		$broken += "tombstone file still on disk (delete or merge into LIVE_PATHS): docs/$name"
	}
}

$mdCount = (Get-ChildItem $DocsDir -Filter "*.md").Count
if ($broken.Count -eq 0) {
	Write-Host "DOC_LINKS: PASS ($mdCount files, $($tombstones.Count) tombstones checked)"
	exit 0
}
Write-Host "DOC_LINKS: FAIL ($($broken.Count) issues)"
$broken | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
exit 1
