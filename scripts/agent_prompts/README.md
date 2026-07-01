# Agent prompts (copy-paste)

**Post-Camp-5 default:** **Combat** chat first → optional **Playtest** or **Campaign** second chat.

Copy an `agent_*.md` file or a section below (Hygiene · Audit · Medical · Expand reopen) into a new agent chat.

**Layout:** `README.md` ·
**maintain** [`agent_maintain.md`](agent_maintain.md) ·
**enhance** [`agent_enhance.md`](agent_enhance.md) ·
**hygiene** [`agent_hygiene.md`](agent_hygiene.md) ·
**audit** [`agent_audit.md`](agent_audit.md) ·
**medical** [`agent_medical.md`](agent_medical.md) ·
**combat** [`agent_combat.md`](agent_combat.md) (incl. [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug)) ·
**playtest** [`agent_playtest.md`](agent_playtest.md) ·
**campaign** [`agent_campaign.md`](agent_campaign.md).

**Quick pick:**
- maintain shipped behavior → [`agent_maintain.md`](agent_maintain.md)
- delete cruft → [`agent_hygiene.md`](agent_hygiene.md)
- grep/improve → [`agent_audit.md`](agent_audit.md)
- medical depth → [`agent_medical.md`](agent_medical.md)
- new tier/feature → [`agent_enhance.md`](agent_enhance.md)
- combat specialty → [`agent_combat.md`](agent_combat.md)
- F5 playtest → [`agent_playtest.md`](agent_playtest.md)
- campaign maintain → [`agent_campaign.md`](agent_campaign.md).

**Read first:**
- [`docs/AGENTS_ENTRY.md#what-to-do-next`](../../docs/AGENTS_ENTRY.md#what-to-do-next)
- [`docs/PLANNING.md#work-streams`](../../docs/PLANNING.md#work-streams)
- agent prompts index above.

**Shipped Expand rows:** [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md) · [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md).

---

<a id="project-health-bundle"></a>

## Project health bundle

| Chat | Copy from | Stream |
|:----:|-----------|--------|
| 1 | [`agent_hygiene.md`](agent_hygiene.md) | Delete mirrors · `.gitignore` · artifacts |
| 2 | [`agent_audit.md`](agent_audit.md) | Anti-patterns · dedup report · trivial fixes |
| 3 | [`agent_maintain.md`](agent_maintain.md) | Gate + one shipped maintain row |
| 4 | [`agent_enhance.md`](agent_enhance.md) | Expand · medical depth · user-requested tier |

**Order:** Hygiene → Audit → Maintain (or Enhance if user named a row). **Not parallel:** two deleters · Hygiene + Medical on same `core/*.gd` · Hygiene + Enhance on same `core/*.gd`.

---

<a id="parallel-medical-quality-bundle"></a>

## Medical quality bundle

| Chat | Copy from | Stream |
|:----:|-----------|--------|
| 1 | [`agent_hygiene.md`](agent_hygiene.md) | Dup files · ignore rules |
| 2 | [`agent_audit.md`](agent_audit.md) | Phase 0 · dedup grep |
| 3 | [`agent_medical.md`](agent_medical.md) | Bleed · triage · treatment |
| 4 | [`agent_combat.md`](agent_combat.md) or [`agent_playtest.md`](agent_playtest.md) | Combat or F5 traces |

**Order:** Hygiene → Audit → Medical Physics → optional Combat/Playtest. One agent on `BleedingConstants.gd` / `EntityMedical.gd` at a time.

---

<a id="hygiene-cleanup"></a>

## Hygiene

Copy [`agent_hygiene.md`](agent_hygiene.md) into a new chat. Bundle: [project health](#project-health-bundle) chat 1.

---

<a id="audit-dedup"></a>

## Audit

Copy [`agent_audit.md`](agent_audit.md) into a new chat. Bundle: [project health](#project-health-bundle) chat 2.

---

<a id="medical-physics"></a>

## Medical physics (copy-paste this chat)

Copy [`agent_medical.md`](agent_medical.md) into a new chat. Bundle: [medical quality](#parallel-medical-quality-bundle) chat 3.

---

<a id="parallel-expansion-bundle"></a>

## Expansion parallel bundle

Combat-side Expand registry **☑ 2026-06-08**.

| Chat | File | Stream | Overlap |
|:----:|------|--------|---------|
| 1 | [`agent_combat.md`](agent_combat.md) | Combat · Exp-0.1 · [3e](agent_combat.md#specialty-iii-4-3e-fight-finish) · [line plug](agent_combat.md#specialty-iii-6-line-plug) | — |
| 2 | [`agent_playtest.md`](agent_playtest.md) | Playtest · Exp-0.2 · F5 | **Only** chat on `.f5_soak_in.txt` |
| 3 | [`agent_campaign.md`](agent_campaign.md) | Campaign · Exp-3 ☑ 2026-06-08 · economy UX maintain | `world/*` only |

**Also in this file:**
- [Project health](#project-health-bundle)
- [Hygiene](#hygiene-cleanup)
- [Audit](#audit-dedup)
- [Medical physics](#medical-physics)
- [Expand reopen](#expand-reopen)
- [Merge discipline](#merge-discipline)

**Standalone files:** [`agent_maintain.md`](agent_maintain.md) · [`agent_enhance.md`](agent_enhance.md) · [`agent_medical.md`](agent_medical.md) · [`agent_combat.md`](agent_combat.md) · [`agent_playtest.md`](agent_playtest.md) · [`agent_campaign.md`](agent_campaign.md).

---

<a id="expand-reopen"></a>

## Expand (§9c reopen only)

Stream: **Expand**. One row from [`SHIP_PLAN#combat-expand-registry`](../../docs/SHIP_PLAN.md#combat-expand-registry) · one `FEATURE_*` per PR + harness · gate `PHASE0: PASS`. Detail: [`PLANNING#stream-expand`](../../docs/PLANNING.md#stream-expand) · rows: [`EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md).

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
```

Target: **`PHASE0: PASS`**. Campaign touch: also `.\scripts\run_company_state_checks.ps1`.

**Do not touch:** `world/*`, `main.gd`, economy UI, harness logic outside owning module.

**Do not:** add `FEATURE_*` without user ask · open closed gates (S1–S11, BMI) · edit `.f5_soak_in.txt`. See [`AGENTS.md`](../../AGENTS.md#harness-and-flags) for frozen items policy.

**Read first:**
- [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md)
- [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md)
- [`AGENTS.md`](../../AGENTS.md) anti-patterns.

**Escalation:** if you find an issue outside `combat/*`, report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. New `FEATURE_*` requires user ask. Hand off to the appropriate stream owner.

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format. Do not chase harness failures present at session start unless the failing harness is in your owning module.

**Success:** one `FEATURE_*` + harness row delivered · gate green · one PR scope.

PR prefix: `combat:` or `expand:`.

---

<a id="merge-discipline"></a>

## Merge discipline

Full rules: [`PLANNING#parallel-agents`](../../docs/PLANNING.md#parallel-agents) (rebase · Phase 0 · hotspots · artifacts).

**Medical / hygiene bundle only:** bleed edits in [Medical physics](#medical-physics) chat via [`agent_medical.md`](agent_medical.md) · `-HarnessMode calibration` · never parallel: two deleters · two on `.f5_soak_in.txt` · Hygiene + Medical on same `core/*.gd` · **only Playtest** touches `.f5_soak_in.txt` · **one Expand chat** at a time.

Rules: [`docs/PLANNING.md`](../../docs/PLANNING.md)
