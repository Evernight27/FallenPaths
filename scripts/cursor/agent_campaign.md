Stream: **Campaign**. **Exp-3 ☑ (2026-06-08)** — economy UX maintain only unless Playtest reports bugs or I ask for **P2** save work. Bundle chat 3 ([`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle)).

**Gate before done:**
```powershell
.\scripts\run_company_state_checks.ps1
.\scripts\run_campaign_ship_audit.ps1
```
Campaign-only fast path: **`FP_HARNESS_OK: CompanyStateChecks (404 tests)`**. Full merge gate: **`PHASE0: PASS`** + **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`** (Combat stream owns Phase 0).
**Own:** `world/*` (`CompanyState.gd`, `CampaignPersistence.gd`, `MapFieldCare.gd`, `MapBleedPolicy.gd`, `CampaignEncounterBridge.gd`, `CombatFlow.gd`, `ContractSpawner.gd`), `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `ui/CompanyHud.gd`, `ui/CompanyRunEndPanel.gd`, `scripts/run_company_state_checks.gd` (Campaign rows).

**Do not touch:** `combat/*`, harness tails, `BleedingConstants.gd`, new `FEATURE_*`, bleed retune. Closed gates: `docs/CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22` · use `CompanyState.gate_*()` not inline stubs.

**Canonical APIs:** economy UX row in `AGENTS.md` · `CompanyState.try_advance_day` · `try_camp_heal` · `MapFieldCare.try_field_*` · `_CampaignBridge` · `SettlementPanel.format_settlement_continue_log` · `CompanyRunEndPanel.format_company_run_end_log`.

**Camp-5 ☑ (2026-06-07):** headless `_run_camp_5_ea_log_markers` + human F5 (`human_signoff: READY`). Playtest owns `.f5_soak_in.txt`; Phase 0 restores `.f5_soak_in.f5_backup.txt`. Harness P2 uses `CampaignPersistence.begin_harness_isolated_save()` (does not touch production slot).

**F5 log-shape markers (fix if Playtest reports mismatch):** [`SHIP_PLAN#camp-playtest-acceptance` §8 marker table](../../docs/SHIP_PLAN.md#camp-playtest-acceptance).

**Shipped XCamp-3.1–3.8 + economy UX `format_*` helpers:** [`EXPANSION_PLAN#exp-3-company-depth`](../../docs/EXPANSION_PLAN.md#exp-3-company-depth).

**Human F5 smoke (Playtest lane):** [`agent_playtest.md`](agent_playtest.md).

**Pick one task (maintain only):**
1. **Economy UX copy** — `CompanyState.format_*` · `PartyMenu` / `CompanyHud` / `SettlementPanel` (wages, rations, desertion, burial, deck refresh, hire).
2. Map field care UX — `MapFieldCare.gd`, `PartyMenu.gd`.
3. Settlement / run-end UI strings only.
4. **P2 save** — only if I explicitly ask (`docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence`).

**Shared files (one agent at a time):** lead on `CampaignEncounterBridge.gd` and `CombatFlow.gd`.

Minimal diff. PR prefix: `campaign:`.