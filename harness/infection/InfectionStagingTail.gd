class_name CombatRegressionHarnessInfectionStagingTail
extends RefCounted
## CAMP-INF-1: staged infection (clean -> localized -> septic) + entity-level sepsis.
## Campaign-only day-advance progression, susceptibility, sepsis death/resolve, and A3 combat tells.


## Full staged-infection suite.
static func run(failures: PackedStringArray) -> void:
    InfectionStagingTests._run_infection_stage0_to_1_progression(failures)
    InfectionStagingTests._run_infection_stage1_to_2_sepsis(failures)
    InfectionStagingTests._run_treated_stage1_stalls_sepsis(failures)
    InfectionStagingTests._run_susceptibility_starvation_raises_dose(failures)
    InfectionStagingTests._run_infection_daily_dose_cap(failures)
    InfectionStagingTests._run_sepsis_is_dead_fold(failures)
    InfectionStagingTests._run_sepsis_stamina_mult(failures)
    InfectionStagingTests._run_source_controlled_sepsis_resolves(failures)
    InfectionStagingTests._run_source_controlled_death_risk_lower(failures)
    InfectionStagingTests._run_septic_not_cleared_by_dressing(failures)
    InfectionStagingTests._run_sepsis_performance_tell(failures)
    InfectionStagingTests._run_localized_infection_pain_mult(failures)
    InfectionStagingTests._run_infection_freshness_factor(failures)
    InfectionStagingTests._run_infection_dose_decays_with_age(failures)
    InfectionStagingTests._run_closed_injuries_never_localize(failures)
    InfectionStagingTests._run_legacy_infection_uses_full_dose(failures)
    InfectionStagingTests._run_infection_bleed_mult(failures)
    InfectionStagingTests._run_stump_is_contaminated(failures)
    InfectionStagingTests._run_stump_is_gangrene_candidate(failures)
    InfectionStagingTests._run_debride_reduces_contamination(failures)
    InfectionStagingTests._run_debride_live_wiring(failures)
    InfectionStagingTests._run_fluid_resuscitation_decompensated(failures)
    InfectionStagingTests._run_amputation_as_sepsis_source_control(failures)
    InfectionStagingTests._run_amputation_releases_prior_medical_state(failures)
