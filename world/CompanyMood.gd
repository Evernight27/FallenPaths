class_name CompanyMood
extends RefCounted

## CompanyMood -- mood management, stance preferences, desertion risk.
## Extracted from CompanyState.gd (B3 / XCamp-3.8).

const MOOD_DEFAULT: float = 50.0
const MOOD_ANGRY_THRESHOLD: float = 15.0
const MOOD_DESERTION_CHANCE: float = 0.05
const MOOD_BATTLE_LOST_DELTA: float = -0.45
const MOOD_DEATH_WITNESS_DELTA: float = -0.25
const MOOD_CAMP_REST_DELTA: float = 1.0
const MOOD_NOT_FED_DELTA: float = -1.0
const MOOD_BATTLE_WON_DELTA: float = 0.35
const MOOD_STANCE_WALL_THRESHOLD: float = 25.0
const MOOD_STANCE_WRATH_THRESHOLD: float = 70.0

# Runtime preload -- circular dependency (CompanyState preloads CompanyMood).
static var _company_state: Variant = null


static func _get_state() -> GDScript:
    if CompanyMood._company_state == null:
        CompanyMood._company_state = load("res://world/CompanyState.gd")
    return CompanyMood._company_state


static func adjust_member_mood(world: Node, member_name: String, delta: float) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if m is Dictionary and m.get("name", "") == member_name:
            var cur: float = float(m.get("company_mood", MOOD_DEFAULT))
            m["company_mood"] = clampf(cur + delta, 0.0, 100.0)
            return


static func apply_camp_rest_mood(world: Node) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        var name_s: String = str(m.get("name", (node_ref as Node).name))
        adjust_member_mood(world, name_s, MOOD_CAMP_REST_DELTA)


static func stance_preference_for_campaign_mood(mood: float) -> String:
    if mood <= MOOD_STANCE_WALL_THRESHOLD:
        return CombatWeaponForm.FORM_WALL
    if mood >= MOOD_STANCE_WRATH_THRESHOLD:
        return CombatWeaponForm.FORM_WRATH
    return CombatWeaponForm.FORM_BALANCED


static func _apply_not_fed_mood(world: Node) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        var name_s: String = str(m.get("name", (node_ref as Node).name))
        adjust_member_mood(world, name_s, MOOD_NOT_FED_DELTA)


static func apply_battle_lost_mood(world: Node) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        var name_s: String = str(m.get("name", (node_ref as Node).name))
        adjust_member_mood(world, name_s, MOOD_BATTLE_LOST_DELTA)


static func apply_battle_death_witness_mood(world: Node, death_count: int) -> void:
    if death_count <= 0:
        return
    var delta: float = MOOD_DEATH_WITNESS_DELTA * float(death_count)
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        var name_s: String = str(m.get("name", (node_ref as Node).name))
        adjust_member_mood(world, name_s, delta)


static func _apply_unpaid_wage_mood(world: Node) -> void:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        var cur: float = float(m.get("company_mood", MOOD_DEFAULT))
        m["company_mood"] = clampf(cur - 1.0, 0.0, 100.0)


static func count_desertion_risk_roster(world: Node) -> int:
    var pm: Node = _get_state()._resolve_party_manager(world)
    if pm == null:
        return 0
    var at_risk: int = 0
    for m in pm.members:
        if not m is Dictionary:
            continue
        var node_ref: Variant = m.get("node_ref")
        if not is_instance_valid(node_ref) or not (node_ref is Node):
            continue
        if (node_ref as Node).has_method("is_dead") and (node_ref as Node).is_dead():
            continue
        if (node_ref as Node).get("is_party_leader") == true:
            continue
        if float(m.get("company_mood", MOOD_DEFAULT)) <= MOOD_ANGRY_THRESHOLD:
            at_risk += 1
    return at_risk


static func format_party_desertion_risk_footer(world: Node2D) -> String:
    var at_risk: int = count_desertion_risk_roster(world)
    if at_risk <= 0:
        return ""
    return (
        "%d brother(s) at desertion risk (mood <=%d) -- 5%% roll each at day end."
        % [at_risk, int(MOOD_ANGRY_THRESHOLD)]
    )
