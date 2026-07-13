class_name CompanyUxCopy
extends RefCounted

## Company HUD / menu button labels and tooltips that are not owned by Economy / Camp / Mood.
## `CompanyState` re-exports these for the stable API.


static func format_end_day_tooltip(world: Node2D) -> String:
    if world == null:
        return "Pay wages and consume daily rations."
    var tips: PackedStringArray = PackedStringArray(
        [
            "Pay wages and consume daily rations for each living brother.",
        ]
    )
    for hint in CompanyEconomy.format_hud_economy_hint_lines(
        CompanyState.get_state(world), CompanyState.count_living_roster(world), world
    ):
        tips.append(hint)
    var desertion_hint: String = CompanyState.format_party_desertion_risk_footer(world)
    if not desertion_hint.is_empty():
        tips.append(desertion_hint)
    return " ".join(tips)


static func format_camp_rest_tooltip(world: Node2D) -> String:
    if world == null:
        return "Heal wounds, advance the day, and boost mood."
    var tips: PackedStringArray = PackedStringArray(
        [
            "Heal all dressed brothers, advance the day, and grant +1 mood (tavern rest).",
        ]
    )
    for hint in CompanyEconomy.format_hud_economy_hint_lines(
        CompanyState.get_state(world), CompanyState.count_living_roster(world), world
    ):
        tips.append(hint)
    return " ".join(tips)


static func format_new_company_button_label() -> String:
    return "Start new company (testing)"


static func format_end_day_button_label(world: Node2D = null) -> String:
    var base: String = "End day"
    if CompanyState.persistence_uses_disk_autosave():
        base = "End day (saves progress)"
    return (
        base
        + format_wage_day_tick_suffix(world)
        + format_provisions_day_tick_suffix(world)
    )


static func format_wage_day_tick_suffix(world: Node2D) -> String:
    if world == null:
        return ""
    var bill: int = CompanyState.compute_next_wage_bill(world)
    var gold: int = CompanyState.get_gold(world)
    if gold >= bill:
        return ""
    if gold < 0:
        return " -- wage debt (desertion risk)"
    return " -- wages short (mood hit if unpaid)"


static func format_provisions_day_tick_suffix(world: Node2D) -> String:
    if world == null or not CompanyState.read_stub_provisions_enabled():
        return ""
    var need: int = CompanyState.count_living_roster(world) * CompanyState.FOOD_PER_MEMBER_PER_DAY
    if need <= 0:
        return ""
    if CompanyState.get_food_supplies(world) >= need:
        return ""
    return " -- rations short (mood -1)"


static func format_hud_provisions_suffix(world: Node2D) -> String:
    if not CompanyState.should_show_next_provisions_hint(world):
        return ""
    return " /  rations short"


static func format_company_debt_log(gold: int) -> String:
    return "Company is in debt (%dg). Low-mood brothers may desert at the next day end." % gold
