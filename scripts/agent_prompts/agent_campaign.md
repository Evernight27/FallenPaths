Stream: **Campaign**. **Exp-3 ☑ 2026-06-08** — economy UX maintain only unless Playtest reports bugs or I ask for **P2** save work. Bundle chat 3 ([`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle)).

**Gate before done:**

```powershell
.\scripts\run_company_state_checks.ps1
.\scripts\run_campaign_ship_audit.ps1
```

Target: **`FP_HARNESS_OK: CompanyStateChecks (406 tests)`** (fast path) or **PHASE0: PASS** + **CAMPAIGN_SHIP_AUDIT: PASS (headless)** (full merge, Combat stream owns Phase 0).

**Own:** `world/*` (`CompanyState.gd`, `CampaignPersistence.gd`, `MapFieldCare.gd`, `MapBleedPolicy.gd`, `CampaignEncounterBridge.gd`, `CombatFlow.gd`, `ContractSpawner.gd`), `main.gd`, `PartyManager.gd`, `ui/PartyMenu.gd`, `ui/SettlementPanel.gd`, `ui/CompanyHud.gd`, `ui/CompanyRunEndPanel.gd`, `scripts/run_company_state_checks.gd` (Campaign rows).

**Read first:** [`docs/AGENTS_ENTRY.md#what-to-do-next`](../../docs/AGENTS_ENTRY.md#what-to-do-next) · [`docs/PLANNING.md#work-streams`](../../docs/PLANNING.md#work-streams) · [`docs/CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22`](../../docs/CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22).

**Do not touch:** `combat/*` (except shared files below), harness tails, new `FEATURE_*`, closed-gate constants (bleed/BMI). **Shared files** (`CampaignEncounterBridge.gd`, `CombatFlow.gd`): coordinate with Combat agent — one at a time. See [`AGENTS.md`](../../AGENTS.md#harness-and-flags) for frozen items policy and gate API.

**Camp-5 ☑ 2026-06-07:** headless `_run_camp_5_ea_log_markers` + human F5 (`human_signoff: READY`). Playtest owns `.f5_soak_in.txt`; Phase 0 restores `.f5_soak_in.f5_backup.txt`. Harness P2 uses `CampaignPersistence.begin_harness_isolated_save()` (does not touch production slot).

**F5 log-shape markers (fix if Playtest reports mismatch):** [`SHIP_PLAN#camp-playtest-acceptance` §8 marker table](../../docs/SHIP_PLAN.md#camp-playtest-acceptance).

**Shipped XCamp-3.1–3.8 + economy UX `format_*` helpers:** [`EXPANSION_PLAN#exp-3-company-depth`](../../docs/EXPANSION_PLAN.md#exp-3-company-depth).

**Human F5 smoke (Playtest lane):** [`agent_playtest.md`](agent_playtest.md).

**Canonical APIs:** `CompanyState.try_advance_day` · `try_camp_heal` · `MapFieldCare.try_field_*` · `_CampaignBridge` · `SettlementPanel.format_settlement_continue_log` · `CompanyRunEndPanel.format_company_run_end_log`.

---

## Session start (copy-paste task line)

> Run company state checks + campaign ship audit. If green, pick **one** task from the list below (or I will name it). Smallest diff in the owning module. Re-run gate before done.

**Pick one task (maintain only):**

<a id="task-economy-ux-copy"></a>
1. **Economy UX copy** — `CompanyState.format_*` · `PartyMenu` / `CompanyHud` / `SettlementPanel` (wages, rations, desertion, burial, deck refresh, hire).

<a id="task-field-care-ux"></a>
2. Map field care UX — `MapFieldCare.gd`, `PartyMenu.gd`.

<a id="task-settlement-ui-strings"></a>
3. Settlement / run-end UI strings only.

<a id="task-p2-save"></a>
4. **P2 save** — only if I explicitly ask ([`docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence`](../../docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence)).

**Do not:** use inline gate stubs (use `CompanyState.gate_*()` — see [`AGENTS.md`](../../AGENTS.md#harness-and-flags)) · add new economy features without user ask · touch combat harness · edit `combat/*` or harness tails.

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Escalation:** if you find an issue in files outside your owning module (especially `combat/*`, `core/*`), report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. Hand off to the appropriate stream owner.

---

## Done checklist

- [ ] CompanyStateChecks PASS at start and end
- [ ] Campaign ship audit PASS (if campaign files touched)
- [ ] One logical fix (or explicit "gate-only" session)
- [ ] No edits outside stream ownership without handoff

**Success:** gate green · campaign ship audit PASS (if touched) · one logical fix delivered.

PR prefix: `campaign:`.