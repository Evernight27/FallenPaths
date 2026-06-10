# Continue project — parallel agent prompts (2026-06-08)

**Baseline (verify first):**
```powershell
.\scripts\print_phase0_status.ps1
.\scripts\run_playtest_status.ps1
```
Expected: **`PHASE0: PASS`** · **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`** · **`PLAYTEST_COVERAGE: PASS`**.

Copy **one block below** into a **new Cursor chat** per agent. Do not run two agents on the same file (see merge discipline in [`README.md#merge-discipline`](README.md#merge-discipline)).

**Deep prompts:** [`agent_maintain.md`](agent_maintain.md) · [`agent_combat.md`](agent_combat.md) · [`agent_playtest.md`](agent_playtest.md) · [`agent_campaign.md`](agent_campaign.md) · [`agent_medical.md`](agent_medical.md) · [`agent_hygiene.md`](agent_hygiene.md) · [`agent_audit.md`](agent_audit.md).

---

<a id="recommended-parallel-bundle"></a>

## Recommended parallel bundle (gate green)

| Chat | Copy section | Stream | Safe parallel with |
|:----:|--------------|--------|---------------------|
| 1 | [Hygiene — path dupes](#chat-1-hygiene) | Repo cleanup | Playtest, Campaign |
| 2 | [Medical — finish WIP](#chat-2-medical) | Medical physics | Playtest (not Hygiene on same `core/*.gd`) |
| 3 | [Combat — maintain pick](#chat-3-combat) | Combat | Playtest, Campaign |
| 4 | [Playtest — live F5 optional](#chat-4-playtest) | F5 / validator | Combat, Campaign, Hygiene |

**Single agent?** Use [Chat 3 — Combat](#chat-3-combat) only.

---

<a id="chat-1-hygiene"></a>

## Chat 1 — Hygiene (copy all below)

```
Stream: Hygiene — see scripts/cursor/agent_hygiene.md

Task: Resolve Windows path duplicate mirrors (combat\*.gd vs combat/*.gd, scripts\*.ps1 vs scripts/*.ps1). List every deletion before removing. Fix .gitignore gaps for .godot/ and playtest artifacts. Do not edit production logic unless byte-identical dupes.

Gate: .\scripts\run_all_combat_checks.ps1 → PHASE0: PASS

Hand off to Audit if two copies differ. PR prefix: hygiene:
```

---

<a id="chat-2-medical"></a>

## Chat 2 — Medical (copy all below)

```
Stream: Medical Physics — see scripts/cursor/agent_medical.md

Task: Review uncommitted medical WIP (core/EntityMedical.gd, EntityWounds.gd, combat/MedicalPhaseController.gd, CombatMedicalCoordination.gd, CombatMedicalActionListing.gd, medical harness tails). Finish one logical slice: coordination gates, compression-before-dress, or field-care parity. Smallest diff.

Fast gate: .\scripts\run_all_combat_checks.ps1 -HarnessMode medical
Full gate: .\scripts\run_all_combat_checks.ps1 → PHASE0: PASS

Do not: bleed retune without explicit ask · bypass medical_action_allowed · touch formation/WF/IV.

PR prefix: medical:
```

---

<a id="chat-3-combat"></a>

## Chat 3 — Combat (copy all below)

```
Stream: Combat — see scripts/cursor/agent_combat.md

Task: Run Phase 0. If green, pick ONE maintain row:
  1) III-6 line plug (camp_line_plug_pick / swap_rank / rotate_file)
  2) III-4 3e fight-finish / mop-up (ii_envelop_mopup)
  3) Mental stack L0–L4 regression (_run_mental_stack_*)
  4) WF PA / form soak (_run_footwork_* / WeaponFormTail)
  5) BattleUIUpdater medical busy gauge (_run_medical_phase_gauge_*)

Smallest combat/*.gd owner. Read LIVE_PATHS#combat-cognition-pipeline before pick/attention changes.

Gate: .\scripts\run_all_combat_checks.ps1 → PHASE0: PASS

Do not: world/* · new FEATURE_* · bleed retune.

PR prefix: combat:
```

---

<a id="chat-4-playtest"></a>

## Chat 4 — Playtest (copy all below)

```
Stream: Playtest — see scripts/cursor/agent_playtest.md

Task: PLAYTEST_COVERAGE is PASS on smoke-merged paste. Optional maintain:
  A) Replace smoke with live F5: rank-0 swap_rank (line_plug) or dev_soak_encounter=ii_envelop wing fight
  B) Run full gate: .\scripts\run_playtest_full_gate.ps1 -HumanSignOff
  C) Rebuild maintained paste: .\scripts\rebuild_f5_maintained_paste.ps1 -DryRun

ONLY agent on .f5_soak_in.txt this session. Do not edit combat/* or world/* — report failures to Combat/Campaign.

Status: .\scripts\run_playtest_status.ps1
```

---

<a id="chat-5-campaign"></a>

## Chat 5 — Campaign (optional, copy all below)

```
Stream: Campaign — see scripts/cursor/agent_campaign.md

Task: Exp-3 shipped — economy UX maintain only. Pick ONE:
  1) CompanyState.format_* copy in PartyMenu / CompanyHud / SettlementPanel
  2) MapFieldCare UX in PartyMenu (coordinate with Medical if constants change)
  3) Settlement / run-end UI strings

Gate: .\scripts\run_company_state_checks.ps1 → 406 tests
Full merge: PHASE0: PASS + CAMPAIGN_SHIP_AUDIT: PASS (headless)

Do not: combat/* · BleedingConstants · P2 save unless I ask.

PR prefix: campaign:
```

---

<a id="chat-6-audit"></a>

## Chat 6 — Audit (after Hygiene, copy all below)

```
Stream: Audit — see scripts/cursor/agent_audit.md

Task: Run Phase 0 + company checks. Grep AGENTS.md anti-patterns (manager._get_by_id, raw move IDs, get_stance_modifier in production, duplicate entity_has_untreated_wounds). Fix at most one trivial bug; else deliver FINDING/SITES/CANONICAL/FIX report.

Gate: PHASE0: PASS + CompanyStateChecks 406

Do not: .f5_soak_in.txt · bleed retune · pick-pipeline refactor · new FEATURE_*.
```

---

<a id="chat-7-enhance"></a>

## Chat 7 — Enhance (user must name row)

```
Stream: Enhance — see scripts/cursor/agent_enhance.md

Task: I want to enhance: <NAME THE ROW — e.g. IV-12, WF-T2, P2 save, Species S5>.

One FEATURE_* or one §9c Expand row per PR. Harness row required for combat tiers.

Gate: .\scripts\run_all_combat_checks.ps1 → PHASE0: PASS

Do not: closed gates without explicit reopen (see SHIP_PLAN §9c).
```

---

<a id="merge-discipline-reminder"></a>

## Merge discipline

- **Never parallel:** two agents on `.f5_soak_in.txt` · Hygiene + Medical on same `core/*.gd` · two Expand chats · two deleters
- **Shared files (one at a time):** `CampaignEncounterBridge.gd`, `CombatFlow.gd`, `CoreEntity` / bleed constants
- **After parallel merges:** `.\scripts\run_all_combat_checks.ps1` before ship
