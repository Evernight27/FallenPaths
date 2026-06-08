Stream: **Enhance**. Go beyond maintain — new combat tiers, medical tuning, docs/tooling, or user-requested features. **User must ask** for closed gates (bleed retune, BMI, S1–S11, closed IV rows).

Bundle: optional second chat alongside [`agent_maintain.md`](agent_maintain.md) when files do not overlap.

**Gate before done:**
```powershell
.\scripts\run_all_combat_checks.ps1
```
Target: **`PHASE0: PASS`**. Campaign touch: also `.\scripts\run_company_state_checks.ps1`.

**Read first:** [`docs/EXPANSION_PLAN.md`](../../docs/EXPANSION_PLAN.md) · [`docs/SHIP_PLAN.md#combat-expand-registry`](../../docs/SHIP_PLAN.md#combat-expand-registry) · [`docs/LIVE_PATHS.md`](../../docs/LIVE_PATHS.md) · [`docs/CAMPAIGN_DECISION_GUIDE.md`](../../docs/CAMPAIGN_DECISION_GUIDE.md).

---

## Session start (copy-paste task line)

> I want to enhance: **<name the row — e.g. IV-12, WF-T2, medical clotting, P2 save>**. One `FEATURE_*` or one expansion row per PR. Harness row required for combat tiers. Gate **`PHASE0: PASS`** before done.

---

## Enhancement lanes (pick one)

| Lane | When | Prompt / doc | Constraints |
|------|------|--------------|-------------|
| **Expand (combat)** | User reopened §9c | [README § Expand reopen](README.md#expand-reopen) | One `FEATURE_*` per PR · no `world/*` |
| **Medical physics** | Hemorrhage / triage / treatment depth | [README § Medical physics](README.md#medical-physics) | No organ surgery · cite research anchor |
| **WF optional tracks** | WF-T1/T2 evidence | `agent_combat.md` + `agent_playtest.md` `form_switch` | No new WF tiers without user ask |
| **Campaign P2 save** | Explicit user ask | `agent_campaign.md` #4 | [`CAMPAIGN_DECISION_GUIDE#d-persistence`](../../docs/CAMPAIGN_DECISION_GUIDE.md) |
| **Species S5 pilot** | User asks | `agent_combat.md` #8 | `species/*` + harness rows |
| **Docs / tooling** | Validator, gate scripts, agent prompts | `agent_hygiene.md` + `agent_audit.md` | No gameplay logic in hygiene |
| **Playtest coverage** | New F5 scenario or validator track | `agent_playtest.md` | Only agent on `.f5_soak_in.txt` |

---

## Expand rules (§9c reopen only)

- One row from [`SHIP_PLAN#combat-expand-registry`](../../docs/SHIP_PLAN.md#combat-expand-registry) per PR.
- Add `FEATURE_*` constant + harness tail row before shipping.
- **Do not touch:** `world/*`, `main.gd`, economy UI, `BleedingConstants.gd` bleed retune.
- PR prefix: `combat:` or `expand:`.

---

## Medical enhance rules

- Tuning order: `BLEEDING_RATES` → `REFERENCE_UNCONTROLLED_BLEED_RATE` → `BLOOD_LOSS_RATE_MULTIPLIER` → part mults → death threshold.
- Fast iterate: `-HarnessMode medical` · `-HarnessMode calibration`.
- **Do not:** bypass `CombatMedicalCoordination.medical_action_allowed` · duplicate untreated-wound checks.

---

## Not enhance (maintain instead)

- Economy UX `format_*` copy tweaks → `agent_campaign.md`
- Harness row fix for shipped behavior → `agent_combat.md`
- Repo delete / ignore → `agent_hygiene.md`
- Anti-pattern grep only → `agent_audit.md`

**Success:** user-named row delivered · harness/soak evidence · gate green · one PR scope.
