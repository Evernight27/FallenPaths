class_name CombatantRowBuilder
extends RefCounted

## Builds the UI row for a combatant: name, gauge, blood/bleeding, consciousness, equipment, body part bars.
## Caller adds the row to the appropriate list and stores the returned controls.


static func create_row(id: int, node: Node, list: Control, id_to_controls: Dictionary) -> void:
    # Row: name, gauge, equipment (weapon + armor), then 6 body part bars
    var row = VBoxContainer.new()
    row.name = "combat_row_%d" % id
    var top_row = HBoxContainer.new()
    var name_lbl = Label.new()
    name_lbl.text = str(node.name) if node != null else "Entity"
    name_lbl.custom_minimum_size = Vector2(60, 0)
    name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
    top_row.add_child(name_lbl)
    # Gauge block expands to fill the row (to the left) so the bar never moves; label area gets all extra space
    var gauge_block = HBoxContainer.new()
    gauge_block.custom_minimum_size = Vector2(
        BattleUIConstants.GAUGE_WIDTH + BattleUIConstants.GAUGE_LABEL_MIN_WIDTH, 14
    )
    gauge_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    gauge_block.add_theme_constant_override("separation", 4)
    var gauge = ProgressBar.new()
    gauge.min_value = 0.0
    gauge.max_value = 100.0  # Stamina 0-100 (Phase 1: bar shows stamina)
    gauge.value = 0.0
    gauge.custom_minimum_size = Vector2(BattleUIConstants.GAUGE_WIDTH, 14)
    gauge.size_flags_horizontal = Control.SIZE_SHRINK_END
    gauge.add_theme_stylebox_override("background", BattleUIConstants.progress_bar_background_style())
    gauge_block.add_child(gauge)
    var gauge_lbl_wrapper = Control.new()
    gauge_lbl_wrapper.custom_minimum_size = Vector2(BattleUIConstants.GAUGE_LABEL_MIN_WIDTH, 0)
    gauge_lbl_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var gauge_lbl = Label.new()
    gauge_lbl.name = "GaugeLabel"
    gauge_lbl.text = "0%"
    gauge_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
    gauge_lbl.offset_left = 0
    gauge_lbl.offset_top = 0
    gauge_lbl.offset_right = 0
    gauge_lbl.offset_bottom = 14
    gauge_lbl.clip_text = true
    gauge_lbl_wrapper.add_child(gauge_lbl)
    gauge_block.add_child(gauge_lbl_wrapper)
    top_row.add_child(gauge_block)
    row.add_child(top_row)
    var last_hit_lbl = Label.new()
    last_hit_lbl.name = "LastHitLabel"
    last_hit_lbl.text = ""
    last_hit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    last_hit_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    last_hit_lbl.add_theme_font_size_override("font_size", 11)
    last_hit_lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
    row.add_child(last_hit_lbl)
    # Blood volume and bleeding (medical realism)
    var blood_row = HBoxContainer.new()
    blood_row.name = "BloodRow"
    var blood_lbl = Label.new()
    blood_lbl.name = "BloodLabel"
    blood_lbl.text = PartyRowFormatter.format_blood_only(100.0)
    blood_lbl.add_theme_font_size_override("font_size", 11)
    blood_lbl.custom_minimum_size = Vector2(70, 0)
    blood_row.add_child(blood_lbl)
    var blood_bar = ProgressBar.new()
    blood_bar.name = "BloodBar"
    blood_bar.min_value = 0.0
    blood_bar.max_value = 100.0
    blood_bar.value = 100.0
    blood_bar.custom_minimum_size = Vector2(60, 10)
    blood_bar.show_percentage = false
    blood_bar.add_theme_stylebox_override("background", BattleUIConstants.progress_bar_background_style())
    blood_row.add_child(blood_bar)
    var bleeding_lbl = Label.new()
    bleeding_lbl.name = "BleedingLabel"
    bleeding_lbl.text = ""
    bleeding_lbl.add_theme_font_size_override("font_size", 11)
    bleeding_lbl.add_theme_color_override("font_color", Color(0.9, 0.35, 0.35))
    blood_row.add_child(bleeding_lbl)
    row.add_child(blood_row)
    # Consciousness and performance (pain/consciousness modifier for gauge fill, hit chance, etc.)
    var consc_row = HBoxContainer.new()
    consc_row.name = "ConsciousnessRow"
    var consc_lbl = Label.new()
    consc_lbl.name = "ConsciousnessLabel"
    consc_lbl.text = "Pain: 0 | Consc: 100% | Perf: 100%"
    consc_lbl.add_theme_font_size_override("font_size", 10)
    consc_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.9))
    consc_row.add_child(consc_lbl)
    row.add_child(consc_row)
    var equip_parts: Array = []
    var weapon_name: String = CombatantEntityAccess.get_weapon_display_name_from_node(node)
    if not weapon_name.is_empty():
        equip_parts.append("Weapon: %s" % weapon_name)
    var armor_names: Array = CombatantEntityAccess.get_armor_summary_from_node(node)
    if armor_names.size() > 0:
        equip_parts.append("Armor: " + ", ".join(armor_names))
    if equip_parts.size() > 0:
        var equip_lbl = Label.new()
        equip_lbl.name = "EquipLabel"
        equip_lbl.text = "  ".join(equip_parts)
        PartyRowFormatter.configure_wrapped_label(equip_lbl)
        equip_lbl.custom_minimum_size = Vector2(0, 0)
        row.add_child(equip_lbl)
    var bars_hbox = HBoxContainer.new()
    bars_hbox.add_theme_constant_override("separation", 8)
    var body_bars := {}
    var body_labels := {}
    for column_parts in BodyPartConstants.BODY_BAR_COLUMNS:
        var col_vbox = VBoxContainer.new()
        col_vbox.add_theme_constant_override("separation", 2)
        for part in column_parts:
            var cell = VBoxContainer.new()
            cell.custom_minimum_size = Vector2(BattleUIConstants.BODY_BAR_CELL_WIDTH, 0)
            var lbl = Label.new()
            lbl.name = "lbl_%s" % part
            lbl.text = BodyPartConstants.BODY_LABELS.get(part, part) + " 0/0"
            lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            cell.add_child(lbl)
            body_labels[part] = lbl
            var bar = ProgressBar.new()
            bar.min_value = 0.0
            bar.max_value = 1.0
            bar.value = 1.0
            bar.custom_minimum_size = Vector2(BattleUIConstants.BODY_BAR_CELL_WIDTH, BattleUIConstants.BODY_BAR_HEIGHT)
            bar.show_percentage = false
            bar.add_theme_stylebox_override("background", BattleUIConstants.progress_bar_background_style())
            cell.add_child(bar)
            body_bars[part] = bar
            col_vbox.add_child(cell)
        bars_hbox.add_child(col_vbox)
    row.add_child(bars_hbox)
    if list != null:
        list.add_child(row)
    id_to_controls[id] = {
        "row": row,
        "name": name_lbl,
        "body_bars": body_bars,
        "body_labels": body_labels,
        "gauge": gauge,
        "gauge_label": gauge_lbl,
        "last_hit_label": last_hit_lbl,
        "blood_label": blood_lbl,
        "blood_bar": blood_bar,
        "bleeding_label": bleeding_lbl,
        "consciousness_label": consc_lbl,
        "node": node
    }
