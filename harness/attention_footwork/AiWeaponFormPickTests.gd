class_name AttentionFootworkAiWeaponFormPickTests
extends CombatRegressionHarnessCore
const Bp := preload("res://core/BodyPartConstants.gd")
const WeaponForm := preload("res://combat/CombatWeaponForm.gd")
const PathResolver := preload("res://combat/AttackPathResolver.gd")
const CompanyState := preload("res://world/CompanyState.gd")
const Proficiency := preload("res://core/EntityProficiency.gd")

## Tier 4.2 - 4.4 attention / mental stack / footwork / battle UI hint tests (compile split).
## Footing harness: **`_run_footwork_*`** (Tier 4.4 PA) . **`_run_focus_line_*`** / **`_run_guard_*`** (L3 guard) .
## **`_run_mental_stack_*`** (MS-L4/L5 boundary). Catalog: LIVE_PATHS **`#harness-footwork-catalog`** . PA hub
## **`#wf-tier-44-pa`**.


static func _run_ai_pick_weapon_form_stat_part_weights(failures: PackedStringArray) -> void:
    if Bp.weapon_part_target_mult("MACE", "head") <= Bp.weapon_part_target_mult("MACE", "left_leg"):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_pick_part_weights: mace should prefer head over leg got head=%s leg=%s"
                % [str(Bp.weapon_part_target_mult("MACE", "head")), str(Bp.weapon_part_target_mult("MACE", "left_leg"))]
            )
        )
    if (
        WeaponForm.target_part_weight_mult(WeaponForm.FORM_WRATH, "head")
        <= WeaponForm.target_part_weight_mult(WeaponForm.FORM_FOOL, "head")
    ):
        CombatRegressionHarness._fail(failures, "ai_pick_part_weights: wrath should bias head above fool")
    if WeaponForm.target_part_weight_mult(WeaponForm.FORM_FOOL, "left_leg") <= 1.0:
        CombatRegressionHarness._fail(failures, "ai_pick_part_weights: fool should bias low-line legs")
    var segment: Array = ["head", "chest"]
    var move_def: Dictionary = {"preferred_parts": ["head"], "attack_line": "high"}
    var defender: Dictionary = {CombatConstants.COMBATANT_KEY_FOCUS_PART: "head"}
    var novice: Dictionary = {
        "weapon_form": WeaponForm.FORM_BALANCED,
        "stats": {"perception": 70, "intelligence": 70},
    }
    var veteran: Dictionary = {
        "weapon_form": WeaponForm.FORM_BALANCED,
        "stats": {"perception": 130, "intelligence": 130},
    }
    var w_novice: Dictionary = PathResolver.part_weights_for_ai_pick(segment, "high", move_def, novice, defender, 2)
    var w_vet: Dictionary = PathResolver.part_weights_for_ai_pick(segment, "high", move_def, veteran, defender, 2)
    if float(w_vet.get("chest", 0.0)) <= float(w_novice.get("chest", 0.0)):
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_pick_part_weights: veteran perception should weight off-focus chest higher got novice=%s veteran=%s"
                % [str(w_novice.get("chest", "")), str(w_vet.get("chest", ""))]
            )
        )
    var mace_head_blunt: float = Bp.weapon_part_target_mult("MACE", "head", "blunt")
    var mace_leg_blunt: float = Bp.weapon_part_target_mult("MACE", "left_leg", "blunt")
    if mace_head_blunt <= mace_leg_blunt:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_pick_part_weights: mace blunt head should exceed leg got head=%.3f leg=%.3f"
                % [mace_head_blunt, mace_leg_blunt]
            )
        )
    var spear_pref: Array = WeaponConstants.preferred_parts_for_weapon_move("SPEAR", "spear_thrust")
    if spear_pref != ["chest"]:
        CombatRegressionHarness._fail(
            failures, "ai_pick_part_weights: spear_thrust preferred want [chest] got %s" % str(spear_pref)
        )
    var dagger_pref: Array = WeaponConstants.preferred_parts_for_weapon_move("DAGGER", "quick_thrust")
    if dagger_pref != ["chest"]:
        CombatRegressionHarness._fail(
            failures, "ai_pick_part_weights: dagger quick_thrust preferred want [chest] got %s" % str(dagger_pref)
        )
    if WeaponForm.move_family_part_weight_mult(WeaponForm.FORM_OX, "thrust", "chest") <= 1.0:
        CombatRegressionHarness._fail(failures, "ai_pick_part_weights: ox thrust should bias chest")
    var old_stub: bool = CompanyState.read_stub_proficiency_enabled()
    CompanyState.proficiency_enabled = true
    var ent: Node = CombatRegressionHarness._new_entity("SWORD")
    Proficiency.award_weapon_proficiency(ent, "SWORD", 20.0)
    if Proficiency.weapon_proficiency_tier(ent, "SWORD") < 0.95:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_pick_part_weights: weapon prof tier want ~1.0 got %.2f"
                % Proficiency.weapon_proficiency_tier(ent, "SWORD")
            )
        )
    Proficiency.award_form_proficiency(ent, WeaponForm.FORM_WRATH, 20.0)
    if Proficiency.form_proficiency_tier(ent, WeaponForm.FORM_WRATH) < 0.95:
        CombatRegressionHarness._fail(failures, "ai_pick_part_weights: form prof tier want ~1.0")
    var occ_novice: float = Proficiency.proficiency_occurrence_mult(ent, "SWORD", WeaponForm.FORM_BALANCED, "thrust")
    var occ_vet: float = Proficiency.proficiency_occurrence_mult(ent, "SWORD", WeaponForm.FORM_WRATH, "thrust")
    if occ_vet <= occ_novice:
        CombatRegressionHarness._fail(
            failures,
            (
                "ai_pick_part_weights: wrath+prof occurrence should exceed balanced novice got %.3f vs %.3f"
                % [occ_vet, occ_novice]
            )
        )
    CompanyState.proficiency_enabled = old_stub
    CombatRegressionHarness._free_harness_node(ent)

## Tier 4.3.8: attention UI hint shows last mental-stack layer stamp.
