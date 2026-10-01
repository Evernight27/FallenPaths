# Camp ship audit: headless proxies for SHIP_PLAN section 8 + Camp-3.4 / Camp-5 gates.
# Does not replace F5 campaign playtest (dev_soak_encounter empty).
#   .\tools\ci\run_campaign_ship_audit.ps1           # full (company + Q + ii7 + PHASE0)
#   .\tools\ci\run_campaign_ship_audit.ps1 -TailOnly # Q + ii7 only (after run_all_combat_checks)
param(
    [switch]$TailOnly
)
$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fail = 0
$auditLines = New-Object System.Collections.Generic.List[string]
$Scope = $env:FP_HARNESS_SCOPE
if ([string]::IsNullOrWhiteSpace($Scope)) { $Scope = "1v1" }
$IsFullScope = ($Scope -eq "full")

Write-Host "=== Campaign ship audit (headless) ==="
Write-Host ""

if (-not $TailOnly) {
    Write-Host "=== CompanyStateChecks (SHIP_PLAN section 8 steps 1-10 proxies) ==="
    & (Join-Path $Root "tools\ci\run_company_state_checks.ps1")
    if ($LASTEXITCODE -ne 0) { $fail = 1; $auditLines.Add("COMPANY_STATE: FAIL") } else { $auditLines.Add("COMPANY_STATE: PASS") }
    Write-Host ""
} else {
    $auditLines.Add("COMPANY_STATE: SKIP (Phase 0 already ran)")
}

Write-Host "=== Q track audits (Camp-3.4 ii7 + Q1/Q2 proxies) ==="
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools\ci\run_q_audit.ps1") -Track Track
if ($LASTEXITCODE -ne 0) {
    $fail = 1
    $auditLines.Add("Q_TRACK: FAIL")
} else {
    $auditLines.Add("Q_TRACK: PASS")
}
Write-Host ""

$soak = Join-Path $Root ".d001_soak_out.txt"
$soakText = ""
$ii7 = $false
$iiEnvelop = $false
if (Test-Path $soak) {
    $soakText = Get-Content -Path $soak -Raw -Encoding utf8
    $ii7 = $soakText -match '\[ii7\] pass=true'
    $iiEnvelop = $soakText -match '\[ii_envelop\] pass=true'
    $iiEnvelopMopup = $soakText -match 'ii_envelop_mopup: PASS'
}
if (-not $ii7) {
    Write-Host 'FAIL: [ii7] pass=true missing in .d001_soak_out.txt - run .\tools\ci\run_all_combat_checks.ps1'
    $fail = 1
    $auditLines.Add("II7_MEDICAL: FAIL")
} else {
    Write-Host "PASS: [ii7] medical smoke (headless)"
    $auditLines.Add("II7_MEDICAL: PASS")
}
if (-not $IsFullScope) {
    Write-Host "SKIP: [ii_envelop] 7v3 wing smoke disabled in FP_HARNESS_SCOPE=$Scope (1v1 gladiator focus)"
    $auditLines.Add("II_ENVELOP: SKIP (FP_HARNESS_SCOPE=$Scope)")
    $auditLines.Add("II_ENVELOP_MOPUP: SKIP (FP_HARNESS_SCOPE=$Scope)")
} elseif (-not $iiEnvelop) {
    Write-Host 'FAIL: [ii_envelop] pass=true missing in .d001_soak_out.txt - run .\tools\ci\run_all_combat_checks.ps1'
    $fail = 1
    $auditLines.Add("II_ENVELOP: FAIL")
} else {
    Write-Host "PASS: [ii_envelop] 7v3 wing engagement smoke (headless)"
    $auditLines.Add("II_ENVELOP: PASS")
}
if ($IsFullScope -and $iiEnvelop -and -not $iiEnvelopMopup) {
    Write-Host 'FAIL: ii_envelop_mopup: PASS missing under [ii_envelop] in .d001_soak_out.txt - run .\tools\ci\run_all_combat_checks.ps1'
    $fail = 1
    $auditLines.Add("II_ENVELOP_MOPUP: FAIL")
} elseif ($iiEnvelopMopup) {
    Write-Host "PASS: ii_envelop_mopup check under [ii_envelop] (3e attrition smoke)"
    $auditLines.Add("II_ENVELOP_MOPUP: PASS")
}

if (-not $TailOnly) {
    $phase0 = Join-Path $Root ".phase0_combat_checks.txt"
    if (-not (Test-Path $phase0)) {
        Write-Host 'WARN: .phase0_combat_checks.txt missing - run .\tools\ci\run_all_combat_checks.ps1 for full PHASE0'
    } elseif (-not (Select-String -Path $phase0 -Pattern '^PHASE0: PASS' -Quiet)) {
        Write-Host "WARN: PHASE0 not PASS in .phase0_combat_checks.txt"
        $fail = 1
        $auditLines.Add("PHASE0: FAIL")
    } else {
        Write-Host "PASS: PHASE0 summary on disk"
        $auditLines.Add("PHASE0: PASS")
    }
} else {
    $auditLines.Add("PHASE0: SKIP (caller verified)")
}

Write-Host ""
Write-Host "=== Human F5 (on demand; Camp-5 EA ☑ 2026-06-07) ==="
Write-Host '  Status: .\tools\ci\print_phase0_status.ps1 (headless green vs human F5 reminder)'
Write-Host '  F5 scenes/campaign/main.tscn: dev_soak_encounter empty - tutorial + paid contracts; post-fight Party pressure -> bandage -> Camp rest (+1 day)'
Write-Host '  F5 status: .\tools\ci\run_camp_f5_closeout.ps1 (headless + wf_m3 + camp settlement/day minimum)'
Write-Host '  Optional III-4 F5: dev_soak_encounter=ii_envelop -> validate_f5_soak_log.ps1 (wing + mop-up tail: mop_up=true rotate_suppress=true)'
Write-Host '  Optional feel: .\tools\ci\run_q_feel.ps1 -Track Camp | Q1 | Q2'
Write-Host "  Medical phase Stack labels: spot-check once in F5 after a fight with medical phase"
Write-Host ""

$auditPath = Join-Path $Root ".campaign_ship_audit.txt"
if ($fail -ne 0) {
    $auditLines.Add("CAMPAIGN_SHIP_AUDIT: FAIL")
    $auditLines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $auditLines | Set-Content -Path $auditPath -Encoding utf8
    Write-Host "=== CAMPAIGN_SHIP_AUDIT: FAIL ==="
    exit 1
}
$auditLines.Add("CAMPAIGN_SHIP_AUDIT: PASS (headless)")
$auditLines.Add("ran_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$auditLines | Set-Content -Path $auditPath -Encoding utf8
Write-Host "=== CAMPAIGN_SHIP_AUDIT: PASS (headless) ==="
exit 0
