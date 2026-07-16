extends PopupPanel
## Party menu UI: party member display, field care, equipment management.

# Simple party menu that displays member info (body parts: cutting + blunt)
var content_vbox: VBoxContainer
var _end_day_button: Button
var _camp_heal_button: Button
var _hire_button: Button
var _new_company_button: Button
var _autosave_footer_label: Label
var _title_label: Label
var _world: Node2D
var _triage_was_active: bool = false
var _field_care_notice: String = ""


func _ready() -> void:
    min_size = Vector2(420, 440)

    var margin := MarginContainer.new()
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 12)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_right", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    add_child(margin)

    var main_vbox := VBoxContainer.new()
    main_vbox.name = "MainVBox"
    main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(main_vbox)

    _title_label = Label.new()
    _title_label.text = "Party"
    _title_label.add_theme_font_size_override("font_size", 18)
    _title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    main_vbox.add_child(_title_label)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size = Vector2(0, 300)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    main_vbox.add_child(scroll)

    content_vbox = VBoxContainer.new()
    content_vbox.name = "ContentVBox"
    content_vbox.add_theme_constant_override("separation", 8)
    content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(content_vbox)

    _end_day_button = Button.new()
    _end_day_button.text = CompanyState.format_end_day_button_label()
    _end_day_button.visible = false
    _end_day_button.pressed.connect(_on_end_day_pressed)
    content_vbox.add_child(_end_day_button)

    _camp_heal_button = Button.new()
    _camp_heal_button.text = CompanyState.format_camp_rest_button_label(null, true)
    _camp_heal_button.visible = false
    _camp_heal_button.pressed.connect(_on_camp_heal_pressed)
    content_vbox.add_child(_camp_heal_button)

    _hire_button = Button.new()
    _hire_button.text = CompanyState.format_hire_button_label()
    _hire_button.visible = false
    _hire_button.pressed.connect(_on_hire_pressed)
    content_vbox.add_child(_hire_button)

    _new_company_button = Button.new()
    _new_company_button.text = CompanyState.format_new_company_button_label()
    _new_company_button.visible = false
    _new_company_button.pressed.connect(_on_new_company_pressed)
    content_vbox.add_child(_new_company_button)

    _autosave_footer_label = Label.new()
    _autosave_footer_label.visible = false
    PartyRowFormatter.configure_wrapped_label(_autosave_footer_label)
    _autosave_footer_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.88))
    content_vbox.add_child(_autosave_footer_label)


func show_party(world: Node2D, members: Array) -> void:
    if content_vbox == null:
        return
    _world = world
    if _title_label != null and world != null:
        var renown: int = CompanyState.get_renown(world)
        var renown_bit: String = " Â· renown %d" % renown if renown > 0 else ""
        _title_label.text = (
            "Party â€” %d g Â· %d med Â· %d tools Â· %d food Â· day %d%s%s%s%s%s"
            % [
                CompanyState.get_gold(world),
                CompanyState.get_medical_supplies(world),
                CompanyState.get_tool_supplies(world),
                CompanyState.get_food_supplies(world),
                CompanyState.get_day_index(world),
                renown_bit,
                CompanyState.format_hud_wage_suffix(world),
                CompanyState.format_hud_provisions_suffix(world),
                CompanyState.format_hud_triage_suffix(world),
                CompanyState.format_hud_persistence_suffix(world),
            ]
        )
    for child in content_vbox.get_children():
        if (
            child == _end_day_button
            or child == _camp_heal_button
            or child == _hire_button
            or child == _new_company_button
            or child == _autosave_footer_label
        ):
            continue
        child.queue_free()

    if not _field_care_notice.is_empty():
        var notice_lbl := Label.new()
        notice_lbl.text = _field_care_notice
        PartyRowFormatter.configure_wrapped_label(notice_lbl)
        notice_lbl.add_theme_color_override("font_color", Color(0.95, 0.5, 0.45))
        content_vbox.add_child(notice_lbl)

    var triage_active: bool = world != null and CampaignEncounterBridge.party_has_untreated_wounds(world)
    # One-shot when the last untreated part is dressed (med may still be 0 â€”" copy in complete_line).
    var camp_unlock: bool = _triage_was_active and not triage_active and world != null
    _triage_was_active = triage_active
    if camp_unlock:
        var ready_lbl := Label.new()
        ready_lbl.text = CompanyState.format_field_care_complete_line(world)
        PartyRowFormatter.configure_wrapped_label(ready_lbl)
        ready_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.62))
        content_vbox.add_child(ready_lbl)
    if triage_active:
        var gate_lbl := Label.new()
        gate_lbl.text = CompanyState.format_party_triage_gate_line(world)
        PartyRowFormatter.configure_wrapped_label(gate_lbl)
        gate_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
        content_vbox.add_child(gate_lbl)
        if MapFieldCare.can_treat_next_wound(world, members):
            var treat_btn := Button.new()
            treat_btn.text = MapFieldCare.format_treat_next_wound_button_label(world, members)
            treat_btn.tooltip_text = (
                "One MARCH step on the highest-threat wounded brother "
                + "(same order as the buttons on each row below)."
            )
            treat_btn.pressed.connect(_on_treat_next_wound_pressed)
            content_vbox.add_child(treat_btn)

    var display_members: Array = members
    if triage_active:
        var wounded: Array = []
        var healthy: Array = []
        for raw in members:
            if raw is not Dictionary:
                continue
            var row: Dictionary = raw
            if row.get("has_untreated_wounds", false):
                wounded.append(row)
            else:
                healthy.append(row)
        wounded.sort_custom(
            func(a: Dictionary, b: Dictionary) -> bool:
                return PartyRowFormatter.member_triage_priority(a) < PartyRowFormatter.member_triage_priority(b)
        )
        display_members = wounded
        if not healthy.is_empty():
            var healthy_hdr := Label.new()
            healthy_hdr.text = (
                "%d unwounded â€” no field care needed (camp rest unlocks after everyone is dressed)." % healthy.size()
            )
            PartyRowFormatter.configure_wrapped_label(healthy_hdr)
            healthy_hdr.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
            content_vbox.add_child(healthy_hdr)
            for h in healthy:
                _append_compact_member_row(content_vbox, h)
            if not wounded.is_empty():
                var wounded_hdr := Label.new()
                wounded_hdr.text = "Wounded â€” field care"
                wounded_hdr.add_theme_font_size_override("font_size", 14)
                PartyRowFormatter.configure_wrapped_label(wounded_hdr)
                wounded_hdr.add_theme_color_override("font_color", Color(0.95, 0.72, 0.45))
                content_vbox.add_child(wounded_hdr)

        ## Consolidated repair buttons at top (extracted from member rows).
        if not wounded.is_empty():
            var repair_section := VBoxContainer.new()
            repair_section.add_theme_constant_override("separation", 4)
            var repair_hdr := Label.new()
            repair_hdr.text = "Repair"
            repair_hdr.add_theme_font_size_override("font_size", 13)
            repair_hdr.add_theme_color_override("font_color", Color(0.6, 0.85, 0.7))
            repair_section.add_child(repair_hdr)
            for w in wounded:
                var care_btns := _build_field_care_buttons(_world, w)
                if care_btns.get_child_count() > 0:
                    var name_lbl := Label.new()
                    name_lbl.text = str(w.get("name", "Brother"))
                    name_lbl.add_theme_font_size_override("font_size", 12)
                    name_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
                    repair_section.add_child(name_lbl)
                    repair_section.add_child(care_btns)
            content_vbox.add_child(repair_section)

    var triage_row_index: int = 0
    for m in display_members:
        var triage_row: bool = triage_active and m.get("has_untreated_wounds", false)
        if triage_row:
            if triage_row_index > 0:
                content_vbox.add_child(HSeparator.new())
            triage_row_index += 1
        var v = VBoxContainer.new()
        var name_lbl = Label.new()
        if triage_row:
            name_lbl.text = str(m.get("name", "Unknown")) + PartyRowFormatter.format_party_role_suffix(m)
            name_lbl.add_theme_font_size_override("font_size", 15)
        else:
            name_lbl.text = (
                str(m.get("name", "Unknown"))
                + PartyRowFormatter.format_party_role_suffix(m)
                + "  STR:"
                + str(m.get("strength", CombatConstants.DEFAULT_STAT_VALUE))
                + " AGI:"
                + str(m.get("agility", CombatConstants.DEFAULT_STAT_VALUE))
                + " INT:"
                + str(m.get("intelligence", CombatConstants.DEFAULT_STAT_VALUE))
                + " END:"
                + str(m.get("endurance", CombatConstants.DEFAULT_STAT_VALUE))
                + " PER:"
                + str(m.get("perception", CombatConstants.DEFAULT_STAT_VALUE))
            )
        PartyRowFormatter.configure_wrapped_label(name_lbl)
        v.add_child(name_lbl)
        var bv: float = m.get("blood_volume", 100.0)
        var bleed: float = m.get("total_bleeding_rate", 0.0)
        var blood_lbl = Label.new()
        blood_lbl.text = PartyRowFormatter.format_blood_line(bv, bleed)
        if bleed > 0.0:
            blood_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
        v.add_child(blood_lbl)
        var triage_line: String = PartyRowFormatter.format_triage_line(bv, bleed)
        if not triage_line.is_empty():
            var triage_lbl = Label.new()
            triage_lbl.text = triage_line
            PartyRowFormatter.configure_wrapped_label(triage_lbl)
            if bleed > 0.0 or bv <= PartyRowFormatter.danger_blood_threshold():
                triage_lbl.add_theme_color_override("font_color", Color(0.95, 0.55, 0.35))
            v.add_child(triage_lbl)
        var dressing_gate: String = PartyRowFormatter.format_dressing_gate_line(m)
        if not dressing_gate.is_empty():
            var dress_gate_lbl := Label.new()
            dress_gate_lbl.text = dressing_gate
            PartyRowFormatter.configure_wrapped_label(dress_gate_lbl)
            dress_gate_lbl.add_theme_color_override("font_color", Color(0.85, 0.78, 0.5))
            v.add_child(dress_gate_lbl)
        var status_line: String = PartyRowFormatter.format_vitality_status(m)
        if not status_line.is_empty():
            var status_lbl = Label.new()
            status_lbl.text = status_line
            PartyRowFormatter.configure_wrapped_label(status_lbl)
            if m.get("has_untreated_wounds", false) or m.get("is_unconscious", false):
                status_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.35))
            v.add_child(status_lbl)
        var untreated_parts: Variant = m.get("untreated_parts", [])
        if untreated_parts is PackedStringArray and (untreated_parts as PackedStringArray).size() > 0:
            var wound_lbl = Label.new()
            wound_lbl.text = "Needs dressing: %s" % MapFieldCare.format_part_list(untreated_parts)
            PartyRowFormatter.configure_wrapped_label(wound_lbl)
            wound_lbl.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
            v.add_child(wound_lbl)
        if not triage_row:
            var weapon_name: String = m.get("weapon_name", "")
            if weapon_name != "":
                var weapon_lbl = Label.new()
                weapon_lbl.text = "Weapon: %s" % weapon_name
                v.add_child(weapon_lbl)
            var form_pref: String = str(m.get("stance_preference", "")).strip_edges()
            if not form_pref.is_empty():
                _append_weapon_form_specialty(v, CombatWeaponForm.normalize_form(form_pref))
            var armor_summary: Array = m.get("armor_summary", [])
            if armor_summary.size() > 0:
                var armor_lbl = Label.new()
                armor_lbl.text = "Armor: " + ", ".join(armor_summary)
                v.add_child(armor_lbl)
            var bc: Dictionary = CombatantEntityAccess.nested_dictionary_read(m, "body_cutting")
            var bb: Dictionary = CombatantEntityAccess.nested_dictionary_read(m, "body_blunt")
            var bm: Dictionary = CombatantEntityAccess.nested_dictionary_read(m, "body_max")
            var bone_h: Dictionary = CombatantEntityAccess.nested_dictionary_read(m, "bone_health")
            var bone_m: Dictionary = CombatantEntityAccess.nested_dictionary_read(m, "bone_max")
            for pair in PartyRowFormatter.PART_LINES:
                var h = HBoxContainer.new()
                for part in pair:
                    var line: String = PartyRowFormatter.format_body_part(part, bc, bb, bm, bone_h, bone_m)
                    if not line.is_empty():
                        var lbl = Label.new()
                        lbl.text = line
                        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                        h.add_child(lbl)
                v.add_child(h)
        if _world != null:
            var pressure_line: String = MapFieldCare.format_member_pressure_held_line(m)
            if not pressure_line.is_empty():
                var pressure_lbl := Label.new()
                pressure_lbl.text = pressure_line
                PartyRowFormatter.configure_wrapped_label(pressure_lbl)
                pressure_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.65))
                v.add_child(pressure_lbl)
            var care_hint: String = MapFieldCare.format_member_field_care_hint(m)
            if not care_hint.is_empty():
                var care_note := Label.new()
                care_note.text = care_hint
                PartyRowFormatter.configure_wrapped_label(care_note)
                care_note.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
                v.add_child(care_note)
        var afflictions: Variant = m.get("affliction_labels", [])
        if afflictions is PackedStringArray and (afflictions as PackedStringArray).size() > 0:
            var aff_lbl = Label.new()
            aff_lbl.text = "Afflictions: " + ", ".join(afflictions)
            PartyRowFormatter.configure_wrapped_label(aff_lbl)
            aff_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95))
            v.add_child(aff_lbl)
        var aff_fx: String = PartyRowFormatter.format_affliction_effects_line(m)
        if not aff_fx.is_empty():
            var fx_lbl := Label.new()
            fx_lbl.text = aff_fx
            PartyRowFormatter.configure_wrapped_label(fx_lbl)
            fx_lbl.add_theme_color_override("font_color", Color(0.7, 0.62, 0.88))
            v.add_child(fx_lbl)
        var prof_line: String = PartyRowFormatter.format_proficiency_bonus_line(m)
        if not prof_line.is_empty():
            var prof_lbl := Label.new()
            prof_lbl.text = prof_line
            PartyRowFormatter.configure_wrapped_label(prof_lbl)
            prof_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
            v.add_child(prof_lbl)
        if m.has("company_mood"):
            var mood_val: float = float(m.get("company_mood", CampaignTypes.MOOD_DEFAULT))
            var mood_lbl = Label.new()
            mood_lbl.text = "Mood: %d" % int(roundf(mood_val))
            if mood_val <= CompanyState.MOOD_ANGRY_THRESHOLD:
                mood_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4))
                mood_lbl.text += " â€” desertion risk at day end"
            v.add_child(mood_lbl)
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        content_vbox.add_child(v)

    if _autosave_footer_label != null:
        var menu_footer: String = CompanyState.format_party_menu_footer(world)
        _autosave_footer_label.visible = not menu_footer.is_empty()
        _autosave_footer_label.text = menu_footer
    if _end_day_button != null:
        _end_day_button.visible = CompanyState.can_offer_end_day(world)
        _end_day_button.text = CompanyState.format_end_day_button_label(world)
        _end_day_button.tooltip_text = CompanyState.format_end_day_tooltip(world)
    if _camp_heal_button != null:
        var ready_camp: bool = CompanyState.camp_heal_ready(world, true)
        _camp_heal_button.visible = CompanyState.should_show_party_camp_rest_button(world)
        _camp_heal_button.disabled = not ready_camp
        if ready_camp:
            _camp_heal_button.text = CompanyState.format_camp_rest_button_label(world, true)
        else:
            _camp_heal_button.text = CompanyState.format_camp_heal_block_reason(world, true)
        _camp_heal_button.tooltip_text = CompanyState.format_camp_rest_tooltip(world)
    if _hire_button != null:
        var ready_hire: bool = CompanyState.can_offer_hire(world, true)
        _hire_button.visible = CompanyState.should_show_party_hire_button(world)
        _hire_button.disabled = not ready_hire
        if ready_hire:
            _hire_button.text = CompanyState.format_hire_button_label(world)
        else:
            _hire_button.text = CompanyState.format_hire_block_reason(world, true)
        _hire_button.tooltip_text = CompanyState.format_hire_tooltip(world, true)
    if _new_company_button != null:
        _new_company_button.visible = CompanyState.can_offer_new_campaign_from_menu()
    var opening: bool = not visible
    popup_centered()
    self.grab_focus()
    if opening and OperationalLog.is_play_session_active():
        var untreated: int = 0
        var bleeding: int = 0
        for m in members:
            if m.get("has_untreated_wounds", false):
                untreated += 1
            if m.get("total_bleeding_rate", 0.0) > 0.0:
                bleeding += 1
        var parts_need: int = CampaignEncounterBridge.party_untreated_part_count(world)
        var budget: Dictionary = CompanyState.triage_med_budget(world)
        (
            OperationalLog
            . play_world(
                (
                    (
                        "party_triage_open living=%d untreated=%d bleeding=%d parts_need_dressing=%d "
                        + "med_left=%d bandage_med_est=%d camp_med=%d total_med_est=%d med_shortfall=%d"
                    )
                    % [
                        members.size(),
                        untreated,
                        bleeding,
                        parts_need,
                        CompanyState.get_medical_supplies(world),
                        budget.get("field_bandage_med_est", 0),
                        budget.get("camp_med", 0),
                        budget.get("total_worst_case", 0),
                        budget.get("med_shortfall", 0),
                    ]
                )
            )
        )


func _append_compact_member_row(parent: VBoxContainer, m: Dictionary) -> void:
    var row := HBoxContainer.new()
    var name_lbl := Label.new()
    name_lbl.text = "%s%s â€” OK" % [str(m.get("name", "Unknown")), PartyRowFormatter.format_party_role_suffix(m)]
    name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    PartyRowFormatter.configure_wrapped_label(name_lbl)
    row.add_child(name_lbl)
    var bv: float = m.get("blood_volume", 100.0)
    var bleed: float = m.get("total_bleeding_rate", 0.0)
    var blood_lbl := Label.new()
    blood_lbl.text = PartyRowFormatter.format_blood_line(bv, bleed)
    row.add_child(blood_lbl)
    parent.add_child(row)


func _party_members() -> Array:
    if _world == null:
        return []
    var pm: Variant = _world.get_meta("party_manager") if _world.has_meta("party_manager") else null
    if pm != null and pm.has_method("get_members"):
        return pm.get_members()
    return []


func _run_field_care_step(step: Callable, action: String) -> void:
    if step.call():
        _field_care_notice = ""
    else:
        _field_care_notice = MapFieldCare.format_field_care_retry_hint(action)
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world(_field_care_notice)
    _refresh_party_view()


func _on_treat_next_wound_pressed() -> void:
    if _world == null:
        return
    if MapFieldCare.try_treat_next_wound(_world, _party_members()):
        _field_care_notice = ""
    else:
        _field_care_notice = ("Field care step failed â€” retry. Treat next wound or use a brother's buttons below.")
        if OperationalLog.is_play_session_active():
            OperationalLog.play_world(_field_care_notice)
    _refresh_party_view()


func _refresh_party_view() -> void:
    if _world == null:
        return
    var members: Array = _party_members()
    if not members.is_empty():
        show_party(_world, members)
    CompanyState.refresh_hud(_world)


func _on_end_day_pressed() -> void:
    if _world == null:
        return
    if CompanyState.request_end_day(_world):
        CompanyState.refresh_hud(_world)
        hide()
    elif OperationalLog.is_play_session_active():
        var block_hint: String = CompanyState.format_party_end_day_unavailable_hint(_world)
        if block_hint.is_empty():
            block_hint = "End day unavailable (check camp tile or day-tick mode)."
        OperationalLog.play_world("End day blocked â€” " + str(block_hint))


func _on_camp_heal_pressed() -> void:
    if _world == null:
        return
    if CompanyState.try_camp_heal(_world, true):
        CompanyState.refresh_hud(_world)
        hide()
    elif OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            (
                "Camp rest blocked â€” %s"
                % CompanyState.format_camp_heal_block_reason(_world, true).trim_prefix("Camp rest ")
            )
        )


func _on_hire_pressed() -> void:
    if _world == null:
        return
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    if CompanyState.try_hire_rookie(_world, rng, true):
        _refresh_party_view()
    elif OperationalLog.is_play_session_active():
        OperationalLog.play_world(
            "Hire blocked -- %s" % CompanyState.format_hire_block_reason(_world, true).trim_prefix("Hire ")
        )


func _on_new_company_pressed() -> void:
    if _world == null:
        return
    hide()
    CompanyState.request_new_campaign(_world)


## Append a compact weapon-form specialty readout to a member row.
static func _append_weapon_form_specialty(v: VBoxContainer, form: String) -> void:
    if form.is_empty():
        return
    var pressure: String = CombatWeaponForm.pressure_class(form)
    var display: String = CombatWeaponForm.display_name(form)
    if pressure.is_empty() or pressure == "neutral":
        pressure = ""
    var sig_lines: PackedStringArray = _get_weapon_form_signature_lines(form)
    var mod_lines: PackedStringArray = _get_weapon_form_strength_lines(form)
    var header := Label.new()
    header.text = "Form â€” %s" % display
    if not pressure.is_empty():
        header.text += " (%s)" % pressure.capitalize()
    header.add_theme_font_size_override("font_size", 11)
    header.add_theme_color_override("font_color", Color(0.7, 0.82, 0.9))
    v.add_child(header)
    for line in sig_lines:
        var lbl = Label.new()
        lbl.text = "  %s" % line
        lbl.add_theme_font_size_override("font_size", 10)
        lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
        v.add_child(lbl)
    for line in mod_lines:
        var lbl = Label.new()
        lbl.text = "  %s" % line
        lbl.add_theme_font_size_override("font_size", 10)
        lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
        v.add_child(lbl)


static func _get_weapon_form_signature_lines(form: String) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    var d: Dictionary = {}
    match form:
        CombatWeaponForm.FORM_OX:
            d = {"move_ids": "thrust, spear_thrust", "contact_types": "stab-heavy", "lines": "high_right, high"}
        CombatWeaponForm.FORM_PLOW:
            d = {"move_ids": "thrust, spear_thrust", "contact_types": "stab-heavy", "lines": "low, high"}
        CombatWeaponForm.FORM_WRATH:
            d = {
                "move_ids": "oberhau, slash, unterhau, quick_slash",
                "contact_types": "cut-heavy",
                "lines": "high_left, high_right"
            }
        CombatWeaponForm.FORM_FOOL:
            d = {
                "move_ids": "feints (oberhau_feint, thrust_feint, unterhau_feint)",
                "contact_types": "low focus",
                "lines": "low_left, low"
            }
        CombatWeaponForm.FORM_WALL:
            d = {
                "move_ids": "thrust, oberhau",
                "contact_types": "stab/cut balance",
                "lines": "high, high_right, high_left"
            }
        CombatWeaponForm.FORM_TEMPEST:
            d = {"move_ids": "slash, quick_slash, oberhau", "contact_types": "cut-heavy", "lines": "left, right, high"}
        _:
            d = {"move_ids": "no signature", "contact_types": "none", "lines": "high"}
    for key in d.keys():
        if not out.is_empty():
            out.append(", ")
        out.append("%s: %s" % [key, str(d[key])])
    return out


static func _get_weapon_form_strength_lines(form: String) -> PackedStringArray:
    var out: PackedStringArray = PackedStringArray()
    var mod_effects: Array[String] = ["parry", "evasion", "damage", "close_attempt", "feint_readthrough"]
    var best_effects: Array = []
    var worst_effects: Array = []
    for eff in mod_effects:
        var val: float = CombatWeaponForm.mod(form, eff)
        if val >= 1.08:
            best_effects.append({"eff": eff, "val": val})
        elif val <= 0.92:
            worst_effects.append({"eff": eff, "val": val})
    if not best_effects.is_empty():
        var bits: PackedStringArray = PackedStringArray()
        for b in best_effects:
            bits.append("%s +%.0f%%" % [b["eff"], (b["val"] - 1.0) * 100.0])
        out.append("Strengths: " + ", ".join(bits))
    if not worst_effects.is_empty():
        var bits: PackedStringArray = PackedStringArray()
        for w in worst_effects:
            bits.append("%s â†’%.0f%%" % [w["eff"], (1.0 - w["val"]) * 100.0])
        out.append("Weaker: " + ", ".join(bits))
    return out


## Build an HBox of field-care repair buttons for one member (used in the top-level repair section).
func _build_field_care_buttons(world: Node2D, m: Dictionary) -> HBoxContainer:
    var care_btns := HBoxContainer.new()
    care_btns.add_theme_constant_override("separation", 4)
    if MapFieldCare.can_offer_field_pressure(world, m):
        var btn_p := Button.new()
        btn_p.text = MapFieldCare.format_field_pressure_button_label(world, m)
        var member_copy: Dictionary = m.duplicate(true)
        btn_p.pressed.connect(
            func() -> void:
                _run_field_care_step(
                    func() -> bool: return MapFieldCare.try_field_pressure(world, member_copy), "pressure"
                )
        )
        care_btns.add_child(btn_p)
    if MapFieldCare.can_offer_field_bandage(world, m):
        var btn_b := Button.new()
        btn_b.text = MapFieldCare.format_field_bandage_button_label(world, m)
        var member_copy_b: Dictionary = m.duplicate(true)
        btn_b.pressed.connect(
            func() -> void:
                _run_field_care_step(
                    func() -> bool: return MapFieldCare.try_field_bandage(world, member_copy_b), "bandage"
                )
        )
        care_btns.add_child(btn_b)
    elif MapFieldCare.field_bandage_needs_pressure_first(m):
        var btn_b_wait := Button.new()
        btn_b_wait.text = MapFieldCare.format_field_bandage_waiting_label(m)
        btn_b_wait.disabled = true
        care_btns.add_child(btn_b_wait)
    if MapFieldCare.can_offer_field_pack(world, m):
        var btn_pk := Button.new()
        btn_pk.text = MapFieldCare.format_field_pack_button_label(world, m)
        var member_copy_pk: Dictionary = m.duplicate(true)
        btn_pk.pressed.connect(
            func() -> void:
                _run_field_care_step(func() -> bool: return MapFieldCare.try_field_pack(world, member_copy_pk), "pack")
        )
        care_btns.add_child(btn_pk)
    if MapFieldCare.can_offer_field_tourniquet(world, m):
        var btn_tq := Button.new()
        btn_tq.text = MapFieldCare.format_field_tourniquet_button_label(world, m)
        var member_copy_tq: Dictionary = m.duplicate(true)
        btn_tq.pressed.connect(
            func() -> void:
                _run_field_care_step(
                    func() -> bool: return MapFieldCare.try_field_tourniquet(world, member_copy_tq), "tourniquet"
                )
        )
        care_btns.add_child(btn_tq)
    if MapFieldCare.can_offer_field_stabilize(world, m):
        var btn_s := Button.new()
        btn_s.text = MapFieldCare.format_field_stabilize_button_label(world, m)
        var member_copy_s: Dictionary = m.duplicate(true)
        btn_s.pressed.connect(
            func() -> void:
                _run_field_care_step(
                    func() -> bool: return MapFieldCare.try_field_stabilize(world, member_copy_s), "stabilize"
                )
        )
        care_btns.add_child(btn_s)
    return care_btns

