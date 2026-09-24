Stream: **Campaign**. Exp-3 ☑ — economy UX maintain; **P2** only if asked. Bundle chat 3: [`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle).

**Gate:** `./tools/ci/run_company_state_checks.sh` → **`FP_HARNESS_OK: CompanyStateChecks (558 tests)`** (fast) or Phase 0 + `./tools/ci/run_campaign_ship_audit.sh`.

**Own:** `world/*`, `scenes/campaign/main.gd`, `PartyManager.gd`, party/settlement/HUD/run-end UI, company harness rows.

**Read first:** [`AGENTS_ENTRY#what-to-do-next`](../../../docs/AGENTS_ENTRY.md#what-to-do-next) · [`CAMPAIGN_DECISION_GUIDE#user-bundle`](../../../docs/CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22).

**Do not touch:** `combat/*` / `harness/*` (except shared bridge with Combat), new `FEATURE_*`, closed gates. Frozen: [`PLANNING#harness-and-flags`](../../../docs/PLANNING.md#harness-and-flags).

**Contract:** [`README#session-contract`](README.md#session-contract).

**APIs:** `CompanyState.try_advance_day` · `try_camp_heal` · `MapFieldCare.try_field_*` · `_CampaignBridge`. Exp-3 UX: [`EXPANSION_PLAN#exp-3-company-depth`](../../../docs/EXPANSION_PLAN.md#exp-3-company-depth).

---

## Session start

> Company checks (+ ship audit if touching campaign). Pick **one** task. Re-gate.

<a id="task-economy-ux-copy"></a>
1. **Economy UX copy** — `CompanyState.format_*` · Party/Hud/Settlement
<a id="task-field-care-ux"></a>
2. Map field care UX — `MapFieldCare` · `PartyMenu`
<a id="task-settlement-ui-strings"></a>
3. Settlement / run-end strings
<a id="task-p2-save"></a>
4. **P2 save** — only if asked ([`#d-persistence`](../../../docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence))

**Do not:** inline gate stubs (`read_stub_*` / `gate_*()`) · new economy features without ask · touch `harness/*`.

PR prefix: `campaign:`.
