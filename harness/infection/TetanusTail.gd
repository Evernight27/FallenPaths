class_name CombatRegressionHarnessTetanusTail
extends RefCounted
## Phase A+ (plan §10.2): tetanus — delayed spore-borne hazard. Arming, entity-level incubation,
## onset latch, is_dead() fold, the A3 performance tell, and the clean-at-arm counter-play
## (latch + onset-risk reduction).


## Full tetanus suite.
static func run(failures: PackedStringArray) -> void:
    TetanusTests._run_tetanus_clean_wound_not_armed(failures)
    TetanusTests._run_tetanus_contaminated_wound_arms(failures)
    TetanusTests._run_tetanus_incubation_survives_wound_resolution(failures)
    TetanusTests._run_tetanus_onset_sets_flag(failures)
    TetanusTests._run_tetanus_is_dead_fold(failures)
    TetanusTests._run_tetanus_performance_tell(failures)
    TetanusTests._run_tetanus_cleaned_at_arm_latch(failures)
    TetanusTests._run_tetanus_cleaned_at_arm_reduces_onset(failures)
