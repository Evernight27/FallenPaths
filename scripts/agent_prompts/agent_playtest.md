Stream: **Playtest**. On demand — F5 append, validator, Q audits. Bundle chat 2: [`README#parallel-expansion-bundle`](README.md#parallel-expansion-bundle). **Only agent on `.f5_soak_in.txt`.**

**Gate:** `./scripts/validate_f5_soak_log.sh` · `./scripts/run_camp_f5_closeout.sh --human-signoff` → validator 0 + **`human_signoff: READY`**.

**Read first:** [`LIVE_PATHS#f5-combat-diagnostic-tiers`](../../docs/LIVE_PATHS.md#f5-combat-diagnostic-tiers). Edit validators under `harness/` OK.

**Do not touch:** production `combat/*` / `world/*` (report-only).

**Contract:** [`README#session-contract`](README.md#session-contract).

**F5 setup:** `dev_soak_encounter` empty · `dev_research_feel` false. Grep: `engagement_debug`, `soak_fight_end`, `FP_COMBAT`, `FP_ERROR`, `SCRIPT_ERROR`.

---

## Session start

> Validator + closeout. Pick **one** session. Only agent on `.f5_soak_in.txt`.

<a id="session-camp-steps"></a>
1. **Camp §8 optional smokes** — `validate_camp_optional_smokes` / `./scripts/run_playtest.sh exp0`
<a id="session-line-plug-pick"></a>
2. **`camp_line_plug_pick`** — F5 → grep `line_plug_pick=1` · hand gaps to Combat
<a id="session-form-switch"></a>
3. **`form_switch` soak (WF-T2)** — grep `form_switch id=`
<a id="session-envelop-wing"></a>
4. **ii_envelop wing** — `dev_soak_encounter=ii_envelop`
<a id="session-full-camp-append"></a>
5. **Full Camp append** — new human paste

**Append:** F5 → `preflight_f5_followup` → `append_f5_soak_log` → `./scripts/run_playtest.sh after-append` / `revalidate` / `full` → refresh `.f5_soak_in.f5_backup.txt`.

**WF-M3:** [`LIVE_PATHS#wf-m3-f5-playtest`](../../docs/LIVE_PATHS.md#wf-m3-f5-playtest).

PR prefix: `playtest:`.
