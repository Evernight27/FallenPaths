Stream: **Maintain**. Post–Camp-5 default — keep shipped combat, campaign, and playtest surfaces green. **One logical fix per session.** No new tiers unless user reopens Expand.

**Gate first (every session):**
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`** (+ **`CAMPAIGN_SHIP_AUDIT: PASS (headless)`** when campaign files touched).

**Read first:** [`docs/CURSOR.md#what-to-do-next`](../../docs/CURSOR.md#what-to-do-next) · [`docs/PLANNING.md#work-streams`](../../docs/PLANNING.md#work-streams) · [`AGENTS.md`](../../AGENTS.md) canonical APIs.

---

## Session start (copy-paste task line)

> Run Phase 0. If green, pick **one** maintain row from the table below (or I will name the row). Smallest diff in the owning module. Re-run gate before done. Do not add `FEATURE_*` or bleed retune.

---

## Pick your stream (copy the matching `agent_*.md` into a dedicated chat)

| Area | When | Deep prompt |
|------|------|-------------|
| **Combat** (default) | Harness fail · III-4/III-6 · mental stack · WF · BattleUI medical busy | [`agent_combat.md`](agent_combat.md) |
| **Campaign** | Economy UX copy · field care UX · settlement strings | [`agent_campaign.md`](agent_campaign.md) |
| **Playtest** | F5 validator · Camp §8 smokes · human paste append | [`agent_playtest.md`](agent_playtest.md) |
| **Medical physics** | Bleed/triage/treatment constants (not UX copy) | [README § Medical physics](README.md#medical-physics) |

**Parallel OK:** Combat + Playtest or Combat + Campaign when [file ownership](../../docs/PLANNING.md#file-ownership) does not overlap.

**Not maintain (use Enhance):** new `FEATURE_*` · §9c Expand rows · bleed retune · P2 save (unless asked).

---

## Maintain priority matrix (2026-06-08+)

| P | Row | Owner prompt | Extra gate |
|:-:|-----|--------------|------------|
| 1 | Failing Phase 0 / harness tail | `agent_combat.md` #2 | — |
| 2 | III-6 line plug pick | `agent_combat.md` [line plug](agent_combat.md#specialty-iii-6-line-plug) | `camp_line_plug_pick` |
| 3 | III-4 3e fight-finish / mop-up | `agent_combat.md` [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) | `ii_envelop_mopup: PASS` |
| 4 | Mental stack L0–L4 regression | `agent_combat.md` #3 | `_run_mental_stack_*` |
| 5 | WF PA / form soak | `agent_combat.md` #5 · `agent_playtest.md` WF-M3 | `_run_footwork_*` · `wf_m3_*` |
| 6 | Economy UX `format_*` | `agent_campaign.md` #1 | `CompanyStateChecks` 406 |
| 7 | Camp §8 optional smokes | `agent_playtest.md` #1 | `EXP_0_2_PLAYTEST_GATE` |
| 8 | III-3 deflect/bind calibration | `agent_combat.md` #6 | Playtest **ii2b** maintain |

---

## Done checklist

- [ ] Phase 0 PASS at start and end
- [ ] One logical change (or explicit “gate-only” session)
- [ ] No edits outside stream ownership without handoff
- [ ] PR title uses stream prefix: `combat:` · `campaign:` · `playtest:` · `medical:`
