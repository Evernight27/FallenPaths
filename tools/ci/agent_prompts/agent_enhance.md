Stream: **Enhance**. New tiers / medical depth / tooling — **user must ask** for closed gates. Frozen: [`PLANNING#harness-and-flags`](../../../docs/PLANNING.md#harness-and-flags).

**Gate:** `./tools/ci/run_all_combat_checks.sh` → **`PHASE0: PASS`**. Campaign touch: also company state checks.

**Read first:** [`EXPANSION_PLAN`](../../../docs/EXPANSION_PLAN.md) · [`SHIP_PLAN` §9c](../../../docs/SHIP_PLAN.md#combat-expand-registry) · named LIVE_PATHS row · [`AGENTS_API#anti-patterns`](../../../docs/AGENTS_API.md#anti-patterns).

**Do not touch:** `world/*` (unless P2), `scenes/campaign/main.gd`, economy UI, `.f5_soak_in.txt`, closed gates without ask.

**Contract:** [`README#session-contract`](README.md#session-contract).

---

## Session start

> Name one enhancement row. One `FEATURE_*` or expansion row per PR. Harness for combat tiers. Gate green.

| Lane | Prompt / doc |
|------|--------------|
| Expand (§9c) | One registry row + `FEATURE_*` + harness · no `world/*` |
| Medical | [`agent_medical.md`](agent_medical.md) · cite research anchor |
| WF-T1/T2 | [`agent_combat.md`](agent_combat.md) + [`agent_playtest.md`](agent_playtest.md) |
| P2 save | [`agent_campaign.md#task-p2-save`](agent_campaign.md#task-p2-save) |
| Species S5 | [`agent_combat.md#priority-species-s5`](agent_combat.md#priority-species-s5) |
| Docs / tooling | [`agent_hygiene.md`](agent_hygiene.md) · [`agent_audit.md`](agent_audit.md) |
| Playtest coverage | [`agent_playtest.md`](agent_playtest.md) |

**Medical enhance (outside medical agent):** tune order `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold · `-HarnessMode medical|calibration` · never bypass `medical_action_allowed`.

**Not enhance:** economy `format_*` → Campaign · harness fix → Combat · delete/ignore → Hygiene · grep-only → Audit.

PR prefix: `combat:` or `expand:`.
