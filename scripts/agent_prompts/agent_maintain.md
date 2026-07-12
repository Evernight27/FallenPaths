Stream: **Maintain**. Post–Camp-5 default — keep shipped combat, campaign, and playtest surfaces green. No new tiers unless user reopens Expand.

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
```

Target: **`PHASE0: PASS`**. When a maintain row references campaign (`agent_campaign.md` [economy UX copy](agent_campaign.md#task-economy-ux-copy)), also run `.\scripts\run_company_state_checks.ps1` + `.\scripts\run_campaign_ship_audit.ps1`.

**Read first (section-only; ≤3 owning `.gd` files):** [`docs/AGENTS_ENTRY.md#what-to-do-next`](../../docs/AGENTS_ENTRY.md#what-to-do-next) · [`docs/PLANNING.md#work-streams`](../../docs/PLANNING.md#work-streams) · APIs on demand: [`docs/AGENTS_API.md#canonical-apis`](../../docs/AGENTS_API.md#canonical-apis).

---

## Session start (copy-paste task line)

> Run Phase 0. If green, pick **one** maintain row from the table below (or I will name the row). Smallest diff in the owning module. Re-run gate before done. No `FEATURE_*` or closed-gate changes.

---

## Pick your stream (copy the matching `agent_*.md` into a dedicated chat)

| Area | When | Deep prompt |
|------|------|-------------|
| **Combat** (default) | Harness fail · III-4/III-6 · mental stack · WF · BattleUI medical busy | [`agent_combat.md`](agent_combat.md) |
| **Campaign** | Economy UX copy · field care UX · settlement strings | [`agent_campaign.md`](agent_campaign.md) |
| **Playtest** | F5 validator · Camp §8 smokes · human paste append | [`agent_playtest.md`](agent_playtest.md) |
| **Medical physics** | Bleed/triage/treatment constants (not UX copy) | [`agent_medical.md`](agent_medical.md) |

**Parallel OK:** Combat + Playtest or Combat + Campaign when [file ownership](../../docs/PLANNING.md#file-ownership) does not overlap.

**Not maintain (use Enhance):** new `FEATURE_*` · §9c Expand rows · closed-gate changes (bleed/BMI) · P2 save (unless asked).

## Maintain priority matrix (2026-06-08+)

| P | Row | Owner prompt | Extra gate |
|:-:|-----|--------------|------------|
| 1 | Failing Phase 0 / harness tail | `agent_combat.md` [harness row fix](agent_combat.md#priority-harness-row-fix) | — |
| 2 | III-6 line plug pick | `agent_combat.md` [line plug](agent_combat.md#specialty-iii-6-line-plug) | `camp_line_plug_pick` |
| 3 | III-4 3e fight-finish / mop-up | `agent_combat.md` [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) | `ii_envelop_mopup: PASS` |
| 4 | Mental stack L0–L4 regression | `agent_combat.md` [mental stack regression](agent_combat.md#priority-mental-stack-regression) | `_run_mental_stack_*` |
| 5 | WF PA / form soak | `agent_combat.md` [WF maintain](agent_combat.md#priority-wf-maintain) · `agent_playtest.md` WF-M3 | `_run_footwork_*` · `wf_m3_*` |
| 6 | Economy UX `format_*` | `agent_campaign.md` [economy UX copy](agent_campaign.md#task-economy-ux-copy) | `CompanyStateChecks` 406 |
| 7 | Camp §8 optional smokes | `agent_playtest.md` [camp §8 steps](agent_playtest.md#session-camp-steps) | `EXP_0_2_PLAYTEST_GATE` |
| 8 | III-3 deflect/bind calibration | `agent_combat.md` [III-3 deflect/bind](agent_combat.md#priority-iii-3-deflect-bind) | Playtest **ii2b** maintain |

---

## Done checklist

- [ ] Phase 0 PASS at start and end
- [ ] One logical fix (or explicit "gate-only" session)
- [ ] No edits outside stream ownership without handoff

**Do not touch:** `world/*` (economy UI, CampaignPersistence), `main.gd`, closed gate constants, economy `read_stub_*` wiring. For shared files (`CampaignEncounterBridge.gd`, `CombatFlow.gd`) coordinate with Campaign agent — one at a time.

**Do not:** add new `FEATURE_*` · change closed-gate constants without user ask · edit harness logic outside owning module · change campaign gate constants inline. See [`PLANNING#harness-and-flags`](../../docs/PLANNING.md#harness-and-flags) for frozen items policy.

**Escalation:** if you find an issue in files outside your owning module, report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. Hand off to the appropriate stream owner.

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Success:** gate green · smallest diff in owning module · one logical fix delivered.

PR prefix: use whichever sub-agent you're working with (combat / campaign / playtest / medical).
