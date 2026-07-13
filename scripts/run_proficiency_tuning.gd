extends SceneTree

## Headless proficiency tuning runner.
## Usage: godot --script scripts/run_proficiency_tuning.gd
## Prints per-scenario summary reports + per-round details for tuning
## gain constants in EntityProficiency.gd.


func _init() -> void:
    print("=== Proficiency 1v1 Tuning Harness ===")
    print("")
    print("Running 6 scenarios (5 rounds each)...")
    print("")

    var scenarios := {
        "balanced":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_balanced_1v1,
            "desc": "Sword vs Sword, both ~100 stats",
        },
        "str_heavy":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_str_heavy_player,
            "desc": "Player STR 150, AGI 80; enemy balanced",
        },
        "agi_heavy":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_agi_heavy_player,
            "desc": "Player AGI 150, PER 120; enemy balanced",
        },
        "spear_vs_sword":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_spear_vs_sword,
            "desc": "Spear vs Sword, both 100 stats",
        },
        "mace_vs_sword":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_mace_vs_sword,
            "desc": "Mace vs Sword, both 100 stats",
        },
        "low_perception":
        {
            "runner": CombatRegressionHarnessProficiency1v1Tail.run_low_perception_player,
            "desc": "Player PER 60 (more misses/dodges)",
        },
    }

    var all_ok := true
    for name in scenarios:
        var s: Dictionary = scenarios[name]
        print(">>> %s <<<  %s" % [name, s.desc])
        print("")

        var result: Dictionary = s.runner.call()
        var rounds: int = result.get("total_rounds_played", 0)

        if rounds == 0:
            print("  *** NO ROUNDS PLAYED ***")
            all_ok = false
        else:
            print(CombatRegressionHarnessProficiency1v1Tail.format_report(result))
            print("")
            print("Per-round detail:")
            print(CombatRegressionHarnessProficiency1v1Tail.format_round_details(result))

        print("")
        print("---")
        print("")

    if not all_ok:
        print("*** Some scenarios produced no rounds. Check setup.")
        quit(1)

    print("=== Done. Tune GAIN_* constants in core/EntityProficiency.gd and rerun. ===")
    quit(0)
