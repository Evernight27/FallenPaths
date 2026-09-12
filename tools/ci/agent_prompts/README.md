# Agent prompts

**Default:** Combat chat → optional Playtest or Campaign. Copy one `agent_*.md` into a new chat.

| Stream | File | Gate |
|--------|------|------|
| Maintain (router) | [`agent_maintain.md`](agent_maintain.md) | `PHASE0: PASS` |
| Combat | [`agent_combat.md`](agent_combat.md) ([3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug)) | `PHASE0: PASS` |
| Enhance | [`agent_enhance.md`](agent_enhance.md) | `PHASE0: PASS` |
| Playtest | [`agent_playtest.md`](agent_playtest.md) | validator + `human_signoff: READY` |
| Campaign | [`agent_campaign.md`](agent_campaign.md) | CompanyStateChecks **406** or Phase 0 + ship audit |
| Hygiene | [`agent_hygiene.md`](agent_hygiene.md) | no production `.gd` |
| Audit | [`agent_audit.md`](agent_audit.md) | Phase 0 + company |
| Medical | [`agent_medical.md`](agent_medical.md) | `PHASE0: PASS` |
| Soak repair | [`agent_soak_stale.md`](agent_soak_stale.md) | regression `FP_HARNESS_OK` + `PHASE0: PASS` |

**Read first (once):** [`AGENTS_ENTRY#what-to-do-next`](../../../docs/AGENTS_ENTRY.md#what-to-do-next) · [`PLANNING#work-streams`](../../../docs/PLANNING.md#work-streams) · APIs on demand: [`AGENTS_API`](../../../docs/AGENTS_API.md). Harness: `harness/`. Expand rows: [`EXPANSION_PLAN`](../../../docs/EXPANSION_PLAN.md) · [`LIVE_PATHS` section-only](../../../docs/LIVE_PATHS.md).

<a id="session-contract"></a>

## Session contract (all streams)

- **Budget:** ≤1 doc section + ≤3 owning `.gd` before first edit.
- **Escalation:** out-of-ownership → report `FINDING` / `SITES` / `CANONICAL` / `FIX` — do not edit.
- **Regression:** if gate was green then red after your change → revert, re-gate, report. Do not chase pre-existing harness fails outside your module.
- **Success:** gate green · one logical change · stream PR prefix.
- **Frozen:** [`PLANNING#harness-and-flags`](../../../docs/PLANNING.md#harness-and-flags) · [`FEATURE_PRESERVATION`](../../../docs/FEATURE_PRESERVATION.md).

<a id="project-health-bundle"></a>

## Bundles

| Bundle | Order |
|--------|-------|
| [Project health](#project-health-bundle) | Hygiene → Audit → Maintain (or Enhance) |
| [Medical quality](#parallel-medical-quality-bundle) | Hygiene → Audit → Medical → optional Combat/Playtest |
| [Expansion parallel](#parallel-expansion-bundle) | Combat · Playtest · Campaign (no file overlap) |

**Not parallel:** two deleters · two on `.f5_soak_in.txt` · Hygiene + Medical/Enhance on same `core/*.gd` · two Expand chats.

| Chat | Health | Medical |
|:----:|--------|---------|
| 1 | [`agent_hygiene.md`](agent_hygiene.md) | [`agent_hygiene.md`](agent_hygiene.md) |
| 2 | [`agent_audit.md`](agent_audit.md) | [`agent_audit.md`](agent_audit.md) |
| 3 | [`agent_maintain.md`](agent_maintain.md) | [`agent_medical.md`](agent_medical.md) |
| 4 | [`agent_enhance.md`](agent_enhance.md) | [`agent_combat.md`](agent_combat.md) / [`agent_playtest.md`](agent_playtest.md) |

<a id="parallel-medical-quality-bundle"></a>
<a id="hygiene-cleanup"></a>
<a id="audit-dedup"></a>
<a id="medical-physics"></a>
<a id="parallel-expansion-bundle"></a>

**Expansion parallel:** chat 1 [`agent_combat.md`](agent_combat.md) · chat 2 [`agent_playtest.md`](agent_playtest.md) (only `.f5_soak_in.txt`) · chat 3 [`agent_campaign.md`](agent_campaign.md) (`world/*` only).

<a id="expand-reopen"></a>

## Expand (§9c reopen)

Use [`agent_enhance.md`](agent_enhance.md) Expand lane. One [`§9c`](../../../docs/SHIP_PLAN.md#combat-expand-registry) row + `FEATURE_*` + harness · `PHASE0: PASS` · no `world/*` / closed gates without ask.

<a id="merge-discipline"></a>

## Merge

[`PLANNING#parallel-agents`](../../../docs/PLANNING.md#parallel-agents) — rebase · Phase 0 · hotspots · artifacts.
