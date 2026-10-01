class_name CombatRegressionHarnessScarTail
extends RefCounted
## CAMP-SCAR-1: wound-derived scars + part-specific penalties (§9.5).
## Verifies the scar catalog, the per-part move_speed/grip/perception/stamina_pool penalties,
## part-scoped damage mult, id+part merge/deepen, and the resolved-wound stash seam.


## Full scar suite.
static func run(failures: PackedStringArray) -> void:
    ScarTests._run_scar_part_penalty_empty(failures)
    ScarTests._run_leg_scar_reduces_leg_functionality(failures)
    ScarTests._run_arm_scar_reduces_grip(failures)
    ScarTests._run_head_scar_reduces_perception(failures)
    ScarTests._run_chest_scar_reduces_stamina(failures)
    ScarTests._run_scar_damage_mult_part_scoped(failures)
    ScarTests._run_scar_deepens_on_merge(failures)
    ScarTests._run_scar_heal_deepens_worse(failures)
    ScarSeveranceTests._run_scar_deepen_is_scar_only(failures)
    ScarTests._run_catalog_has_part_keys(failures)
    ScarWoundInfectionTests._run_stash_and_clear_resolved_wounds(failures)
    ScarWoundInfectionTests._run_health_clock_round_trip(failures)
    ScarWoundInfectionTests._run_systemic_infection_round_trip(failures)
    ScarWoundInfectionTests._run_scar_reinjury_severity(failures)
    ScarWoundInfectionTests._run_amputation_mints_scar(failures)
    ScarWoundInfectionTests._run_severed_part_skips_wound_scar(failures)
    ScarWoundInfectionTests._run_closed_injuries_mint_no_wound_scar(failures)
    ScarWoundInfectionTests._run_scarred_part_wound_resolves_slower(failures)
    ScarWoundInfectionTests._run_severed_bone_part_not_bone_crippled(failures)
    ScarAfflictionVolkmannTests._run_affliction_roll_arterial_wins_over_bone(failures)
    ScarAfflictionVolkmannTests._run_affliction_roll_struck_down_wins_over_danger(failures)
    ScarAfflictionVolkmannTests._run_scarred_infection_clear_keeps_slowdown(failures)
    ScarAfflictionVolkmannTests._run_post_sepsis_weakness_only_after_recovery(failures)
    ScarAfflictionVolkmannTests._run_scar_line_effect_suffix_signed(failures)
    ScarAfflictionVolkmannTests._run_bone_afflictions_carry_sited_penalty(failures)
    ScarAfflictionVolkmannTests._run_amputation_prunes_same_part_afflictions(failures)
    ScarAfflictionVolkmannTests._run_amputated_phantom_pain(failures)
    ScarAfflictionVolkmannTests._run_tq_ischemia_latches_volkmann(failures)
    ScarAfflictionVolkmannTests._run_pre_expiry_resolution_mints_no_volkmann(failures)
    ScarAfflictionVolkmannTests._run_osteo_infection_still_mints_volkmann(failures)
    ScarSeveranceTests._run_scar_increases_severance_ease(failures)
    ScarSeveranceTests._run_severance_mint_releases_prior_medical_state(failures)
    ScarAfflictionVolkmannTests._run_dead_member_mints_nothing(failures)
