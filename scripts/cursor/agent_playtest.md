Stream: **Playtest**. **On demand** — F5 append, validator regression, Q audits. Bundle chat 2 ([`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle)). **Only agent on `.f5_soak_in.txt` this session.**

**Do not edit** `combat/*` or `world/*` production code — report failures to Combat/Campaign agents.

**Baseline (2026-06-07 ☑):** `followup.log` + `.f5_soak_in.f5_backup.txt` · `validate_f5_soak_log.ps1` **`ok=true`** · all `[camp_*]` PASS · `run_camp_f5_closeout.ps1 -HumanSignOff` → **`human_signoff: READY`**. Phase 0 auto-restores backup after D001; manual: `restore_f5_soak_log.ps1`.

**Headless checks:**
```powershell
.\scripts\run_q_audit.ps1 -Track Q1
.\scripts\run_q_audit.ps1 -Track Q2
.\scripts\run_campaign_ship_audit.ps1
```

**F5 setup (`main.tscn`):** `dev_soak_encounter` empty · `dev_research_feel` false. Grep Output: `engagement_debug`, `soak_fight_end`, `FP_COMBAT`, `FP_ERROR`, `SCRIPT_ERROR`. See `docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers`.

**Exp-0.2 ☑ (2026-06-08):** optional §8 steps 4, 8–10 PASS on human paste · `.\scripts\run_exp0_playtest_gate.ps1` → **`EXP_0_2_PLAYTEST_GATE: PASS`**.

**Round 2 — on-demand sessions (pick one):**

1. **Camp §8 optional steps (maintain)** — after validator edits: `.\scripts\validate_camp_optional_smokes.ps1` or `.\scripts\run_exp0_playtest_gate.ps1` · smokes: `docs/camp_optional_step_smokes/*.txt`
2. **`camp_line_plug_pick` human coverage** — F5 fight with rank-0 casualty → grep `line_plug_pick=1` · `pick=swap_rank` or `pick=rotate_file`. Report gaps to Combat ([`agent_combat.md#specialty-iii-6-line-plug`](agent_combat.md#specialty-iii-6-line-plug)).
3. **`form_switch` soak for WF-T2** — 2+ sword fights, grep `form_switch id=` for Expand evidence.
4. **ii_envelop wing feel** — `dev_soak_encounter=ii_envelop` · sparse post-flee `fight_finish` traces.
5. **Full Camp append** — §8 bundle when validating a new human paste.

**When appending a new paste:**

1. Run F5 scenario (§8 bundle or targeted cyan preset).
2. `.\scripts\preflight_f5_followup.ps1 followup.log` · `.\scripts\append_f5_soak_log.ps1 -AppendFrom chunk.txt -Label "camp_append"`
3. `.\scripts\validate_f5_soak_log.ps1` · `.\scripts\run_q_feel.ps1 -Track Camp` · `.\scripts\run_camp_f5_closeout.ps1 -HumanSignOff`
4. Refresh backup: `Copy-Item .f5_soak_in.txt .f5_soak_in.f5_backup.txt`

**Smoke vs human:** docs `camp_* .example.txt` passes validator but closeout prints `human_signoff: SMOKE ONLY`.

**WF-M3:** validator `wf_m3_*` on paste; glance Form suffix on gauge when touching footing UI. `docs/LIVE_PATHS.md#wf-m3-f5-playtest`.

**Success:** no `FP_ERROR` / `SCRIPT_ERROR` in paste; validator exit 0; closeout **`human_signoff: READY`** on human paste.
