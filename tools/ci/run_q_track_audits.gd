extends SceneTree

## Headless Q1–Q4 track proxies vs `.d001_soak_out.txt` → `.q_track_audits.txt`.
## Run: `./tools/ci/run_q_audit.sh Track` or `.\\tools\\ci\\run_q_audit.ps1 -Track Track` or `FP_HARNESS_MODE=q_track` via `run_all_combat_checks.gd`.

func _init() -> void:
    quit(CombatQTrackAudits.run_headless())
