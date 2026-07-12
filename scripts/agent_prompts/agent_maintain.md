Stream: **Maintain**. Post–Camp-5 default — keep shipped surfaces green. No new tiers unless Expand reopens.

**Gate:** `./scripts/run_all_combat_checks.sh` → **`PHASE0: PASS`**. Campaign → separate [`agent_campaign.md`](agent_campaign.md) chat.

**Read first:** [`AGENTS_ENTRY#what-to-do-next`](../../docs/AGENTS_ENTRY.md#what-to-do-next) · [`PLANNING#work-streams`](../../docs/PLANNING.md#work-streams) · APIs: [`AGENTS_API`](../../docs/AGENTS_API.md#canonical-apis).

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> Run Phase 0. If green, pick **one** maintain row. Smallest owning-module diff. Re-gate. No `FEATURE_*` / closed-gate changes.

| Area | Deep prompt |
|------|-------------|
| Combat (default) | [`agent_combat.md`](agent_combat.md) |
| Campaign | [`agent_campaign.md`](agent_campaign.md) |
| Playtest | [`agent_playtest.md`](agent_playtest.md) |
| Medical | [`agent_medical.md`](agent_medical.md) |

**Not maintain:** new `FEATURE_*` · §9c · closed gates · P2 unless asked → [`agent_enhance.md`](agent_enhance.md).

## Priority matrix

| P | Row | Prompt |
|:-:|-----|--------|
| 1 | Failing Phase 0 / harness | [harness](agent_combat.md#priority-harness-row-fix) |
| 2 | III-6 line plug | [line plug](agent_combat.md#specialty-iii-6-line-plug) |
| 3 | III-4 3e fight-finish | [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) |
| 4 | Mental stack L0–L4 | [mental stack](agent_combat.md#priority-mental-stack-regression) |
| 5 | WF PA / form soak | [WF](agent_combat.md#priority-wf-maintain) |
| 6 | Economy UX `format_*` | [economy](agent_campaign.md#task-economy-ux-copy) |
| 7 | Camp §8 smokes | [camp §8](agent_playtest.md#session-camp-steps) |
| 8 | III-3 deflect/bind | [III-3](agent_combat.md#priority-iii-3-deflect-bind) |

**Do not (Combat Maintain):** `world/*`, `main.gd`, closed gates, economy `read_stub_*` — hand to Campaign. Shared bridge: one agent.

PR prefix: sub-stream (`combat:` / `campaign:` / `playtest:` / `medical:`).
