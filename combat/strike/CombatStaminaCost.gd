class_name CombatStaminaCost
extends RefCounted

## Stamina cost accounting for combat actions, extracted from **`AttackResultApplier`**.
## Pure functions over combatant dicts + manager. State carried on the combatant via
## `DataKeys` / `CombatConstantsStamina` keys. External deps are class_name references
## (no circular preload). `_pending_attack_read` stays on `AttackResultApplier` and is
## referenced by class_name.


static func _consume_stamina(manager: Node, c: Dictionary, amount: float) -> void:
    if c == null:
        return
    var s: float = CombatantEntityAccess.stamina_float(c)
    c[DataKeys.COMBATANT_STAMINA] = maxf(0.0, s - amount)
    CombatExhaustion.apply_exertion_from_stamina_spend(manager, c, amount)


## Stance stamina cost: a braced defensive stance absorbs actions cheaper; a committed aggressive
## stance costs more per action. Reads the combatant's live weapon form (WF) — distinct from the
## consecutive/flurry multipliers already applied by callers.
static func _form_stamina_cost_mult(c: Dictionary) -> float:
    if c.is_empty():
        return 1.0
    return CombatWeaponForm.stamina_cost_mult(CombatantEntityAccess.form_str(c), CombatantEntityAccess.get_weapon(c))


static func _stamina_parry_cost_for_defender(
    atk: Dictionary, incoming_intensity: float = -1.0, consecutive_parry_count: int = 1, def: Dictionary = {}
) -> float:
    var i: float = incoming_intensity
    if i < 0.0:
        i = 0.5
        if not atk.is_empty():
            i = AttackResultApplier._pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
    var base_cost: float = CombatConstants.stamina_parry_cost_from_intensity(i)
    # Consecutive parry fatigue: repeated parrying without full recovery compounds stamina drain.
    if consecutive_parry_count > 1:
        base_cost *= CombatConstants.consecutive_parry_stamina_mult(consecutive_parry_count)
    base_cost *= _form_stamina_cost_mult(def)
    return base_cost


static func _stamina_dodge_cost_for_defender(atk: Dictionary, intensity: float = -1.0, def: Dictionary = {}) -> float:
    var i: float = intensity
    if i < 0.0:
        i = 0.5
        if not atk.is_empty():
            i = AttackResultApplier._pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 0.5)
    return CombatConstants.stamina_dodge_cost_from_intensity(i) * _form_stamina_cost_mult(def)


static func _stamina_attack_cost_for_attacker(manager: Node, atk: Dictionary, target_id: int) -> float:
    if atk.is_empty():
        return CombatConstants.stamina_attack_cost_from_intensity(1.0)
    var cost: float = CombatConstants.stamina_attack_cost_from_intensity(
        AttackResultApplier._pending_attack_read(atk).get(DataKeys.ATTACK_INTENSITY, 1.0)
    )
    if manager != null and target_id >= 0:
        var clk: float = CombatantEntityAccess.combat_clock_float(manager)
        cost *= CombatFlurryBind.stamina_attack_cost_mult(atk, target_id, clk)
    cost *= _consecutive_action_stamina_mult_for_combatant(atk)
    cost *= _form_stamina_cost_mult(atk)
    # Technique economy (TOPIC 8c): a green fighter spends more metabolic energy (and accrues more exhaustion)
    # per nominal-intensity swing than a veteran would. Untracked fighters / sim-off return economy 1.0.
    var swing_tier: float = EntityProficiency.swing_proficiency_tier(
        CombatantEntityAccess.scene_entity(atk),
        CombatantEntityAccess.weapon_type_id(atk),
        CombatantEntityAccess.form_str(atk)
    )
    cost *= EntityProficiency.swing_stamina_economy(swing_tier)
    # Sepsis (CAMP-INF-1): a septic member burns stamina faster per action (tachycardia/shock).
    var atk_scene: Node = CombatantEntityAccess.scene_entity(atk)
    if atk_scene != null and "is_septic" in atk_scene and bool(atk_scene.get("is_septic")):
        cost *= BleedingConstants.SEPSIS_COMBAT_STAMINA_DRAIN_MULT
    return cost


static func _consecutive_action_stamina_mult_for_combatant(c: Dictionary) -> float:
    var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0)
    return CombatConstantsStamina.consecutive_action_stamina_mult(count)


static func _track_consecutive_action_start(c: Dictionary) -> void:
    if c.is_empty():
        return
    var state: String = c.get(DataKeys.COMBATANT_STATE, "")
    if state == CombatConstants.STATE_RECOVERING:
        c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = 1
        return
    var count: int = c.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS, 0) + 1
    c[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_ACTIONS] = count


static func _track_consecutive_parry_for_defender(tgt: Dictionary, manager: Node = null) -> int:
    if tgt.is_empty():
        return 1
    var state: String = tgt.get(DataKeys.COMBATANT_STATE, "")
    # If defender is in recovery, parry streak resets.
    if state == CombatConstants.STATE_RECOVERING:
        tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = 1
        _stamp_last_parry_clock(tgt, manager)
        return 1
    # HEMA: parry fatigue decays with rest. If the gap since the last parry exceeds the reset window,
    # the defender has recovered enough that the streak resets — the fatigue compounds only for
    # back-to-back parries, not for parries separated by a long rest.
    var count: int = 1
    if manager != null:
        var now: float = CombatantEntityAccess.combat_clock_float(manager)
        var last: float = float(tgt.get(DataKeys.PA_LAST_PARRY_CLOCK, -1.0))
        if last >= 0.0 and (now - last) <= CombatConstants.PARRY_FATIGUE_RESET_S:
            count = int(tgt.get(CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES, 0)) + 1
    tgt[CombatConstantsStamina.COMBATANT_KEY_CONSECUTIVE_PARRIES] = count
    _stamp_last_parry_clock(tgt, manager)
    return count


static func _stamp_last_parry_clock(tgt: Dictionary, manager: Node) -> void:
    if tgt.is_empty() or manager == null:
        return
    tgt[DataKeys.PA_LAST_PARRY_CLOCK] = CombatantEntityAccess.combat_clock_float(manager)
