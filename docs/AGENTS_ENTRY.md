# Agent entry (Godot 4.x)

[`PLANNING`](PLANNING.md) · [`AGENTS_API`](AGENTS_API.md) · [`ARCHITECTURE`](ARCHITECTURE.md) · [`BRIDGE_CONTRACT`](BRIDGE_CONTRACT.md) · [`LIVE_PATHS`](LIVE_PATHS.md) (section-only) · [`agent_prompts`](../tools/ci/agent_prompts/README.md)

```bash
./tools/ci/run_all_combat_checks.sh && ./tools/ci/print_phase0_status.sh
```

Windows: `.\tools\ci\run_all_combat_checks.ps1` · Godot: [`tools/ci/README#godot-entry`](../tools/ci/README.md#godot-entry).

<a id="what-to-do-next"></a>

## What to do next

1. Gate → **`PHASE0: PASS`**
2. Stream → [`agent_prompts/README`](../tools/ci/agent_prompts/README.md) · [parallel](PLANNING.md#parallel-agents)
3. Product gates → [user bundle](CAMPAIGN_DECISION_GUIDE.md#user-bundle-2026-05-22); new gates → [§19](SHIP_PLAN.md#implementation-stubs)

Lethality: [`LIVE_PATHS` §12](LIVE_PATHS.md#12-tuning-order-keep-research-chain) only. No closed-gate / `FEATURE_*` without ask.

<a id="single-agent"></a>
<a id="every-session"></a>
<a id="decision-log"></a>
