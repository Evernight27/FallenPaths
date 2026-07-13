class_name CombatD001SoakSanity
extends RefCounted

## Headless **D-001** plausibility + validator cross-checks (grep needles vs log semantics).
## Called from **`CombatD001SoakRunner._evaluate`**, **`run_all_combat_checks.gd`** (`FP_HARNESS_MODE=sanity` .
## `d001_presets`).

const BattleScene := preload("res://ui/BattleScene.gd")

const II6_PROBE_CUT: float = 22.0
const II6_PROBE_BLUNT: float = 22.0
const II6_PROBE_BV_PCT: float = 58.0

const RUNNER_NAME := "CombatD001SoakSanity"


static func run_all() -> Dictionary:
    var failures: PackedStringArray = PackedStringArray()
    failures.append_array(CombatD001SoakSanityPartA._run_validator_fixture_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_plausibility_fixture_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_profile_detection_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_slice_isolation_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_parry_plausibility_fixtures())
    failures.append_array(CombatD001SoakSanityPartA._run_exhaustion_plausibility_fixtures())
    failures.append_array(CombatD001SoakSanityPartA._run_numeric_formula_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_ii6_wound_probe())
    failures.append_array(CombatD001SoakSanityPartA._run_parry_summary_line_fixture())
    failures.append_array(CombatD001SoakSanityPartA._run_ii6_capture_slice_fixture())
    failures.append_array(CombatD001SoakSanityPartA._run_track_crosswalk_tests())
    failures.append_array(CombatD001SoakSanityPartA._run_f5_soak_trace_fixtures())
    failures.append_array(CombatD001SoakSanityPartA._run_ii5_world_formation_meta_fixture())
    var ok: bool = failures.is_empty()
    if ok:
        var ent: CoreEntity = CombatD001SoakSanityPartA._ii6_probe_entity()
        var pain: float = EntityPainConsciousness.get_effective_pain_for_thresholds(ent)
        var dur: float = PainConsciousnessConstants.get_pain_shock_duration_seconds(pain, 0.0)
        OperationalLog.harness_ok(
            RUNNER_NAME,
            (
                "fixtures+ii6_pain=%.1f+dur=%.1fs+thresh=%.1f"
                % [snapped(pain, 0.1), snapped(dur, 0.1), PainConsciousnessConstants.get_pain_shock_threshold()]
            )
        )
    else:
        OperationalLog.harness_fail(RUNNER_NAME, failures)
    return {"ok": ok, "failures": failures, "harness_ok_emitted": true}


## Per-preset log semantics after grep needle checks pass.


## Per-preset log semantics after grep needle checks pass.
static func plausibility_failures_for_preset(preset_id: String, lines: PackedStringArray) -> PackedStringArray:
    var pid: String = preset_id.strip_edges().to_lower()
    var scoped: PackedStringArray = CombatD001SoakSanityPartB._lines_for_last_fight(lines)
    var failures: PackedStringArray = CombatD001SoakSanityPartB._common_log_plausibility_failures(pid, scoped)
    match pid:
        SoakEncounterPresets.PRESET_II5_COWERING:
            failures.append_array(CombatD001SoakSanityPartB._ii5_plausibility_failures(scoped))
        SoakEncounterPresets.PRESET_II6_AMBIENT_SHOCK:
            failures.append_array(CombatD001SoakSanityPartB._ii6_plausibility_failures(scoped))
        SoakEncounterPresets.PRESET_II3_SURROUND:
            failures.append_array(CombatD001SoakSanityPartB._ii3_plausibility_failures(scoped))
        SoakEncounterPresets.PRESET_II8_FORMATION:
            failures.append_array(CombatD001SoakSanityPartB._ii8_plausibility_failures(scoped))
        SoakEncounterPresets.PRESET_II4D_EXHAUSTION:
            failures.append_array(CombatD001SoakSanityPartB._ii4d_log_plausibility_failures(scoped))
        "7v7":
            failures.append_array(CombatD001SoakSanityPartB._seven_v7_plausibility_failures(lines))
    return failures

# --- run_all unit tests ---
