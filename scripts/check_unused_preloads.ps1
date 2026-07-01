$dirs = @('combat','core','world','ui','weapon','armor','species')
$excludes = 'RegressionHarness|Tail\.gd|SoakRunner\.gd|CalibrationAudit|ResearchAnchors|HarnessFixtures|run_company_state_checks|D001TrackSpecs|D001SoakSanity|F5SoakLogValidator|F5SoakTrace'
$results = @()

foreach($d in $dirs) {
    $base = "E:\FallenPaths\fallen-paths\$d"
    if(!(Test-Path $base)){ continue }
    
    Get-ChildItem $base -Filter *.gd | Where-Object { $_.Name -notmatch $excludes } | ForEach-Object {
        $file = $_
        $lines = Get-Content $file.FullName
        
        for($i=0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if($line -match '^\s*const\s+_(\w+)\s*:=\s*preload\("([^"]+)"\)') {
                $name = $matches[1]
                $preload_path = $matches[2]
                
                # Count non-declaration usages of "_$name." excluding comment lines
                $usageCount = 0
                for($j=0; $j -lt $lines.Count; $j++) {
                    if($j -eq $i) { continue }
                    $otherLine = $lines[$j]
                    # Skip lines where the match is only in a comment
                    $codePart = ($otherLine -split '//')[0]
                    if($codePart -match "_${name}\.") {
                        $usageCount++
                    }
                }
                
                $declLineNum = $i + 1
                $results += [PSCustomObject]@{
                    File = $file.FullName
                    DeclLine = $declLineNum
                    Name = $name
                    Preload = $preload_path
                    UsageCount = $usageCount
                }
            }
        }
    }
}

# Output unused preloads (UsageCount == 0)
$unused = $results | Where-Object { $_.UsageCount -eq 0 }
Write-Host "=== UNUSED PRELOADS ==="
if($unused.Count -eq 0) {
    Write-Host "(none found)"
} else {
    $unused | Format-Table -AutoSize
}

# Also output summary of ALL preloads and their usage counts for context
Write-Host ""
Write-Host "=== ALL PRELOADS ==="
$results | Sort-Object File, DeclLine | Format-Table -AutoSize
