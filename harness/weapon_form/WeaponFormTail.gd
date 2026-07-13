class_name CombatRegressionHarnessWeaponFormTail
extends RefCounted
## Expand WF: weapon form spawn, mods, picker weights, pressure class, UI suffix parity.
## Footing rows: home guard on **`assign_form`** . gauge/diagram **` . Form`** / **`[Ox]`**  -  not PA step. LIVE_PATHS
## **`#harness-row-catalog-combatregressionharnessweaponformtailgd`** . soak open scope **`#wf-soak-audit-status`** .
## compose **`#battle-ui`**.


static func run(failures: PackedStringArray) -> void:
    WeaponFormAssignTests._run_weapon_form_spawn_default_guard(failures)
    WeaponFormAssignTests._run_weapon_form_allowed_forms_clamp(failures)
    WeaponFormAssignTests._run_weapon_form_normalize_stance_alias(failures)
    WeaponFormAssignTests._run_weapon_form_mod_parity_stance_alias(failures)
    WeaponFormAssignTests._run_weapon_form_move_weight_distribution(failures)
    WeaponFormAssignTests._run_weapon_form_axe_chop_weight_bias(failures)
    WeaponFormAssignTests._run_weapon_form_pressure_class_zoc(failures)
    WeaponFormAssignTests._run_weapon_form_close_controlling_evasion(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_disengage_pressure(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_disengage_listing_weight(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_close_listing_weight(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_close_turn_hint(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_close_list_stamp(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_close_listed_turn_detail(failures)
    WeaponFormAssignTests._run_weapon_form_close_failed_log_controlling_note(failures)
    WeaponFormAssignTests._run_weapon_form_close_resolve_contest_note(failures)
    WeaponFormAssignTests._run_weapon_form_controlling_pressure_stamina_gate(failures)
    WeaponFormAssignTests._run_weapon_form_turn_ready_listing_close_controlling(failures)
    WeaponFormAssignTests._run_weapon_form_harness_assign_form_home_guard(failures)
    WeaponFormAssignTests._run_weapon_form_octant_attack_path_cardinal_lookup(failures)
    WeaponFormAssignTests._run_weapon_form_wait_weight_wall(failures)
    WeaponFormAssignTests._run_weapon_form_wind_up_native_line(failures)
    WeaponFormAssignTests._run_weapon_form_auto_switch_duel(failures)
    WeaponFormAssignTests._run_weapon_form_auto_switch_duel_yomi(failures)
    WeaponFormAssignTests._run_weapon_form_auto_switch_duel_yomi_ox_to_fool(failures)
    WeaponFormAssignTests._run_weapon_form_auto_switch_surround(failures)
    WeaponFormAssignTests._run_weapon_form_auto_switch_envelop_block(failures)
    WeaponFormAssignTests._run_weapon_form_preference_spawn(failures)
    WeaponFormAssignTests._run_weapon_form_yomi_inference(failures)
    WeaponFormAssignTests._run_weapon_form_counter_pick(failures)
    WeaponFormGaugeTests._run_weapon_form_ui_suffix(failures)
    WeaponFormGaugeTests._run_weapon_form_wf_t2_suite(failures)
