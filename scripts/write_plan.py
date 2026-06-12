import os

content = []
content.append("# Mental Stack Improvement Plan - Swordmaster Gap Analysis")
content.append("")
content.append("## Overview")
content.append("")
content.append("This plan addresses 7 identified gaps in the Mental Stack AI cognition pipeline, organized into phases small enough for individual agents to execute. Each phase is self-contained with clear validation criteria.")
content.append("")
content.append("**Baseline:** Every phase must pass `./scripts/run_all_combat_checks.ps1` (PHASE0: PASS + ii_envelop_mopup: PASS).")
content.append("")
content.append("## Swordmaster Rationale (Summary)")
content.append("")
content.append("A swordmaster teaches combat through layered decision-making, not just technique. The current system already implements many of these principles well (triage priority, counter-tempo, yomi/habit tracking, weapon-form counters, exhaustion awareness, formation discipline). These gaps are where a master would push further:")

with open(os.path.join(os.path.dirname(__file__), "..", "docs", "MENTAL_STACK_IMPROVEMENT_PLAN.md"), "w") as f:
    f.write("\n".join(content))

print("Done writing header")