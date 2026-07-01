Stream: **Enhance**. Go beyond maintain — new combat tiers, medical tuning, docs/tooling, or user-requested features. **User must ask** for closed gates (bleed/BMI/S1-S11/closed IV rows). See [`AGENTS.md`](../../AGENTS.md#harness-and-flags) for frozen items policy.

Bundle: optional second chat alongside [`agent_maintain.md`](agent_maintain.md) when files do not overlap.

**Gate before done:**

```powershell
.\scripts\run_all_combat_checks.ps1
```

Target: **`PHASE0: PASS`**. Campaign touch: also `.\scripts\run_company_state_checks.ps1`.

**Read first:** [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md) · [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md) · [`docs/CAMPAIGN_DECISION_GUIDE.md`](../../docs/CAMPAIGN_DECISION_GUIDE.md) · [`AGENTS.md`](../../AGENTS.md) anti-patterns.

**Do not touch:** `world/*` (unless P2 save lane), `main.gd`, economy UI, `.f5_soak_in.txt` (Playtest exclusive), closed gate constants without user ask.

---

## Session start (copy-paste task line)

> Name an enhancement row (e.g., IV-12, WF-T2, medical clotting, P2 save). One `FEATURE_*` or one expansion row per PR. Harness row required for combat tiers. Gate **`PHASE0: PASS`** before done.

---

## Enhancement lanes (pick one)

| Lane | When | Prompt / doc | Constraints |
|------|------|--------------|-------------|
| **Expand (combat)** | User reopened §9c | [`README#expand-reopen`](README.md#expand-reopen) | One `FEATURE_*` per PR · no `world/*` |
| **Medical physics** | Hemorrhage / triage / treatment depth | [`agent_medical.md`](agent_medical.md) | Cite research anchor |
| **WF optional tracks** | WF-T1/T2 evidence | [`agent_combat.md`](agent_combat.md) + [`agent_playtest.md`](agent_playtest.md) `form_switch` | No new WF tiers without user ask |
| **Campaign P2 save** | Explicit user ask | [`agent_campaign.md`](agent_campaign.md) [P2 save](agent_campaign.md#task-p2-save) | [`docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence`](../../docs/CAMPAIGN_DECISION_GUIDE.md#d-persistence) |
| **Species S5 pilot** | User asks | [`agent_combat.md`](agent_combat.md) [Species S5 pilot](agent_combat.md#priority-species-s5) | `species/*` + harness rows |
| **Docs / tooling** | Validator, gate scripts, agent prompts | [`agent_hygiene.md`](agent_hygiene.md) + [`agent_audit.md`](agent_audit.md) | No gameplay logic in hygiene |
| **Playtest coverage** | New F5 scenario or validator track | [`agent_playtest.md`](agent_playtest.md) | Only agent on `.f5_soak_in.txt` |

---

## Expand rules (§9c reopen only)

- One row from [`SHIP_PLAN#combat-expand-registry`](../../docs/SHIP_PLAN.md#combat-expand-registry) per PR.
- Add `FEATURE_*` constant + harness tail row before shipping.
- **Do not:** `world/*`, `main.gd`, economy UI, closed-gate constants (bleed/BMI) without user ask.

---

## Medical enhance rules

- Delegate to [`agent_medical.md`](agent_medical.md) for standard medical work. These rules apply only when implementing medical enhancements outside the standard medical agent scope.
- Tuning order: `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold.
- Fast iterate: `-HarnessMode medical` · `-HarnessMode calibration`.
- **Do not:** bypass `CombatMedicalCoordination.medical_action_allowed` · duplicate untreated-wound checks.

---

## Not enhance (maintain instead)

- Economy UX `format_*` copy tweaks → `agent_campaign.md`
- Harness row fix for shipped behavior → `agent_combat.md`
- Repo delete / ignore → `agent_hygiene.md`
- Anti-pattern grep only → `agent_audit.md`

**If gate was green at start but fails after your change:** revert the change, re-run gate to confirm it was your edit that broke it, then report with FINDING/SITES/CANONICAL/FIX format.

**Escalation:** if you find an issue in files outside your owning module, report it (FINDING/SITES/CANONICAL/FIX format) and do not edit those files. New `FEATURE_*` requires user ask — do not open closed gates. Hand off to the appropriate stream owner.

**Success:** user-named row delivered · harness/soak evidence · gate green · one PR scope.

PR prefix: `combat:` or `expand:`.
