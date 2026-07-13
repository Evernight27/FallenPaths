class_name CombatF5SoakTrace
extends RefCounted

## Editor F5 **D-001** traces  -  mirror on-screen battle UI in **`FP_COMBAT`** Output (grep, no human glance).
## **`turn_ready_gauge`**: full label via **`BattleUIUpdater`**  -  suffix order **Step -> Grd/Atk -> Form** when
## present; content asserts **open**  -  LIVE_PATHS **`#wf-soak-audit-status`** . **`#battle-ui`** .
## **`#wf-footing-doc-map`**.
## Call sites: **`TurnReadyHandler`**, **`BattleScene`**, **`CombatResolveAction`**.
## **`ingest_trace_line`** (via **`OperationalLog.play_combat`**) feeds **`soak_coverage`** at fight end.
## **`ingest_world_trace_line`** (via **`OperationalLog.play_world`**) appends Camp S8 markers for post-medical
## supplement.

static var _player_turn_hints_cache: Variant = null


## Inspector snapshot at F5 start (grep **`soak_session_plan`**).
static func log_session_plan(dev_soak_encounter: String, dev_research_feel: bool) -> void:
    if not OS.has_feature("editor"):
        return
    var soak: String = dev_soak_encounter.strip_edges().to_lower()
    _OperationalLog.play_combat(
        (
            "soak_session_plan dev_soak_encounter=%s dev_research_feel=%s"
            % [soak if not soak.is_empty() else "(empty)", str(dev_research_feel).to_lower()]
        )
    )
    if soak.is_empty():
        _OperationalLog.play_combat(
            (
                "soak_session_plan fight=walk red 7v7 tile  -  covers formation gauge medical parry exhaustion flee (no"
                + "t ii5 cowering / ii6 shock / ii2b bind-only)"
            )
        )
    else:
        _OperationalLog.play_combat(
            "soak_session_plan fight=walk cyan marker preset=%s  -  grep soak= on encounter_begin" % soak
        )
    if dev_research_feel:
        _OperationalLog.play_combat(
            "soak_session_plan Q1=on  -  expect research_feel per hit; best with dev_soak_encounter=ii2b"
        )
    else:
        _OperationalLog.play_combat(
            "soak_session_plan Q1=off  -  enable main dev_research_feel for per-hit research_feel lines"
        )
    _OperationalLog.play_combat(
        (
            "soak_session_plan after fight grep hit_resolve reason= strike_avoided reason= diagram_banner player: engag"
            + "ement_transition hit_outcome_stats parry_stats soak_fight_end soak_coverage  -  paste full Output"
        )
    )


static func set_fight_profile(profile_id: String) -> void:
    _fight_profile = profile_id.strip_edges().to_lower()


## Clear Camp S8 **`FP_WORLD`** lines accumulated since F5 session start (call once from **`main.gd`**).


## Clear Camp S8 **`FP_WORLD`** lines accumulated since F5 session start (call once from **`main.gd`**).
static func reset_session_camp_trace() -> void:
    _session_camp_trace_lines = PackedStringArray()
    _session_camp_combat_trace_lines = PackedStringArray()
    _last_camp_supplement_key = ""


## Headless D-001 runs one log line per simulated fight (not only **`CombatManager`** phase_end).
## New fight: archive prior fight camp combat needles, then reset per-fight trace
## (Camp **`FP_WORLD`** kept in **`_session_camp_trace_lines`** until session reset).


## Headless D-001 runs one log line per simulated fight (not only **`CombatManager`** phase_end).
## New fight: archive prior fight camp combat needles, then reset per-fight trace
## (Camp **`FP_WORLD`** kept in **`_session_camp_trace_lines`** until session reset).
static func prepare_fight_end_log() -> void:
    CombatF5SoakTracePartA._archive_fight_camp_combat_lines()
    reset_fight_trace_buffer()
    _EngagementDiag.reset_session()
    _last_diagram_banner_line = ""
    _last_diagram_banner_enemy_line = ""
    _session_counts = {
        "turn_ready": 0,
        "tooltip_ok": 0,
        "tooltip_mismatch": 0,
        "tooltip_counter": 0,
        "tooltip_medical": 0,
        "tooltip_hold_line": 0,
        "tooltip_melee_only": 0,
        "tooltip_wind_up": 0,
        "tooltip_recovering": 0,
        "tooltip_partial": 0,
        "tooltip_na": 0,
        "diagram_banner": 0,
        "medical_pack_listed": 0,
        "medical_action_pick": 0,
        "medical_pack_pick": 0,
        "engagement_transition": 0,
        "research_feel": 0,
        "hit_resolve": 0,
        "hit_outcome_hit": 0,
        "hit_outcome_glancing": 0,
        "hit_outcome_negligible": 0,
        "hit_outcome_deflected": 0,
        "hit_outcome_other": 0,
        "strike_avoided": 0,
        "strike_avoided_miss": 0,
        "strike_avoided_dodge": 0,
    }


## Headless **`_simulate_fight`**: clear trace only  -  keep **`_session_counts`** from setup / early probes.


## Headless **`_simulate_fight`**: clear trace only  -  keep **`_session_counts`** from setup / early probes.
static func reset_fight_trace_buffer() -> void:
    _fight_end_logged = false
    _defer_soak_coverage_for_medical = false
    _soak_coverage_logged = false
    _medical_phase_intro_logged = false
    _research_validate_hint_logged = false
    _soak_validate_hint_logged = false
    _soak_coverage_deferred_note_logged = false
    _last_camp_supplement_key = ""
    _fight_trace_lines = PackedStringArray()
    _last_turn_ready_formation_fp_line = ""
    _last_gauge_tooltip_formation_fp_line = ""
    _last_turn_ready_gauge_sig = ""
    _last_engagement_transition_line = ""
    _last_strike_avoided_line = ""
    _last_hit_resolve_line = ""
    _last_formation_move_pick_line = ""
    _last_medical_pack_listed_line = ""
    _last_research_feel_line = ""
    _last_cowering_fall_back_listed_line = ""
    _last_fall_back_pick_line = ""
    _last_medical_action_pick_line = ""
    _last_cowering_fall_back_executed_line = ""
    _last_fled_line = ""
    _last_ambient_pain_shock_line = ""
    _last_death_tick_line = ""
    _last_exhaustion_crossing_line = ""
    _OperationalLog.reset_fight_fp_channel_dedupe()


## Append fight log for **`CombatF5SoakLogValidator`** (skip startup **`soak_guide`** grep examples).


## Append fight log for **`CombatF5SoakLogValidator`** (skip startup **`soak_guide`** grep examples).
static func ingest_trace_line(message: String) -> void:
    var s: String = message.strip_edges()
    if s.is_empty():
        return
    if s.begins_with("soak_guide ") or s.begins_with("soak_guide:"):
        return
    if s.begins_with("soak_session_plan "):
        return
    if s.begins_with("soak_coverage "):
        return
    # Fight-end rollups  -  do not re-ingest (avoids inflating parry/grep stats if trace is re-parsed).
    if (
        s.begins_with("parry_stats ")
        or s.begins_with("hit_outcome_stats ")
        or s.begins_with("hit_coverage_hint ")
        or s.begins_with("q2_validate_hint ")
        or s.begins_with("q3_validate_hint ")
        or s.begins_with("q3_ii5_stats ")
        or s.begins_with("q4_ii8_stats ")
        or s.begins_with("q4_validate_hint ")
        or s.begins_with("exhaustion_stats ")
        or s.begins_with("soak_fight_end ")
        or s.begins_with("soak_validate_hint ")
        or s.begins_with("research_validate_hint ")
    ):
        return
    if _fight_trace_lines.size() > 0 and _fight_trace_lines[_fight_trace_lines.size() - 1] == s:
        return
    _fight_trace_lines.append(s)
    if _fight_trace_lines.size() > MAX_FIGHT_TRACE_LINES:
        _fight_trace_lines.remove_at(0)
    if _soak_coverage_logged and "campaign_medical_exit" in s:
        refresh_camp_supplement_after_medical_exit()


## Rollup lines are emitted via **`play_combat`** but excluded from **`ingest_trace_line`**  -  append directly.


## Camp S8 markers (**`FP_WORLD`**) land after medical  -  extend trace for in-editor camp supplement.
static func ingest_world_trace_line(message: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var s: String = message.strip_edges()
    if s.is_empty():
        return
    if not _TrackSpecs.is_camp_ea_world_trace_line(s):
        return
    CombatF5SoakTracePartA._append_fight_trace_line_direct(s)
    if _session_camp_trace_lines.is_empty() or _session_camp_trace_lines[_session_camp_trace_lines.size() - 1] != s:
        _session_camp_trace_lines.append(s)
    if _fight_end_logged and _soak_coverage_logged and CombatF5SoakTracePartB._should_refresh_camp_supplement(s):
        CombatF5SoakTracePartB._log_soak_coverage_camp_supplement()


## End-of-fight rollup for pasted-log validation (grep **`soak_fight_end`**).


## End-of-fight rollup for pasted-log validation (grep **`soak_fight_end`**).
static func log_fight_end_summary(winner: String, entering_medical_phase: bool) -> void:
    if _fight_end_logged or not _OperationalLog.is_play_session_active():
        return
    CombatF5SoakTracePartA._reconcile_session_hit_counts_from_fight_trace()
    _fight_end_logged = true
    var parts: PackedStringArray = PackedStringArray()
    parts.append("winner=%s" % winner.strip_edges())
    parts.append("medical_phase=%s" % str(entering_medical_phase).to_lower())
    parts.append("fight_profile=%s" % (_fight_profile if not _fight_profile.is_empty() else "7v7"))
    for key in _session_counts.keys():
        parts.append("%s=%d" % [key, int(_session_counts[key])])
    var end_line: String = "soak_fight_end %s" % " ".join(parts)
    _OperationalLog.play_combat(end_line)
    CombatF5SoakTracePartA._append_fight_trace_line_direct(end_line)
    if entering_medical_phase:
        _defer_soak_coverage_for_medical = true
    else:
        CombatF5SoakTracePartA._log_soak_coverage()
    if not _soak_validate_hint_logged:
        _soak_validate_hint_logged = true
        _OperationalLog.play_combat(
            "soak_validate_hint copy full Godot Output to .f5_soak_in.txt then scripts/validate_f5_soak_log.ps1"
        )
    if not _research_validate_hint_logged:
        _research_validate_hint_logged = true
        if int(_session_counts.get("research_feel", 0)) > 0:
            _OperationalLog.play_combat(
                (
                    "research_validate_hint %d research_feel lines  -  compare to docs/LIVE_PATHS.md#f5-optional-cr"
                    + "osswalk-feel-vs-headless" % int(_session_counts["research_feel"])
                )
            )
        elif _combat_constants.combat_event_debug_verbose_active():
            _OperationalLog.play_combat(
                "research_validate_hint 0 research_feel lines  -  enable main dev_research_feel or land hits in combat"
            )
    CombatF5SoakTracePartA._log_parry_rollup()
    CombatF5SoakTracePartA._log_hit_outcome_rollup()
    CombatF5SoakTracePartA._log_hit_coverage_hint()
    if _fight_profile in [_SoakPresets.PRESET_II2B_SWORD_DUEL, _SoakPresets.PRESET_II4D_EXHAUSTION]:
        CombatF5SoakTracePartA._log_q2_parry_rollup()
    if _fight_profile == _SoakPresets.PRESET_II5_COWERING:
        CombatF5SoakTracePartA._log_q3_ii5_rollup()
    if _fight_profile == _SoakPresets.PRESET_II4D_EXHAUSTION:
        CombatF5SoakTracePartA._log_q3_ii4d_rollup()
    if _fight_profile == _SoakPresets.PRESET_II8_FORMATION:
        CombatF5SoakTracePartA._log_q4_ii8_rollup()


## F5: miss / dodge (grep **`strike_avoided`**).
static func note_strike_avoided(
    attacker_id: int, target_id: int, atk: Dictionary, tgt: Dictionary, outcome: String, part: String = ""
) -> void:
    if not _combat_constants.combat_hit_summary_active():
        return
    if not _OperationalLog.is_play_session_active():
        return
    var oc: String = outcome.strip_edges().to_lower()
    if oc.is_empty():
        return
    var atk_n: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
    var tgt_n: String = CombatantEntityAccess.get_display_name(tgt, target_id)
    var part_s: String = part if not part.is_empty() else "-"
    var avoid_reason: String = CombatLogFormatter.strike_avoided_reason(oc)
    var line: String = "strike_avoided %s->%s %s outcome=%s reason=%s" % [atk_n, tgt_n, part_s, oc, avoid_reason]
    if line == _last_strike_avoided_line:
        return
    _last_strike_avoided_line = line
    CombatF5SoakTracePartB._bump("strike_avoided")
    var sub_key: String = "strike_avoided_%s" % oc
    if _session_counts.has(sub_key):
        CombatF5SoakTracePartB._bump(sub_key)
    _OperationalLog.play_combat(line)


## F5 / play session: one line per resolved strike (grep **`hit_resolve reason=`**). Default on when play-session
## diagnostic is on.
static func note_hit_resolve(
    attacker_id: int, target_id: int, atk: Dictionary, tgt: Dictionary, result_dict: Dictionary
) -> void:
    if not _combat_constants.combat_hit_summary_active():
        return
    if not _OperationalLog.is_play_session_active():
        return
    var outcome: String = str(result_dict.get("outcome", "hit")).strip_edges()
    if outcome.is_empty():
        outcome = "hit"
    var atk_n: String = CombatantEntityAccess.get_display_name(atk, attacker_id)
    var tgt_n: String = CombatantEntityAccess.get_display_name(tgt, target_id)
    var part: String = str(result_dict.get("part", ""))
    var phys: float = float(result_dict.get("total_physical", -1.0))
    if phys < 0.0:
        phys = float(result_dict.get("dmg", 0))
    var dmg_int: int = int(result_dict.get("dmg", int(roundf(phys))))
    var reason: String = str(result_dict.get("damage_resolve_note", "")).strip_edges()
    if reason.is_empty():
        reason = CombatLogFormatter.damage_resolve_note(result_dict)
    if reason.is_empty():
        reason = "counted_damage"
    var line: String = (
        "hit_resolve %s->%s %s outcome=%s phys=%.3f dmg_int=%d reason=%s"
        % [atk_n, tgt_n, part if not part.is_empty() else "-", outcome, phys, dmg_int, reason]
    )
    if line == _last_hit_resolve_line:
        return
    _last_hit_resolve_line = line
    CombatF5SoakTracePartB._bump("hit_resolve")
    var bump_key: String = "hit_outcome_%s" % outcome
    if _session_counts.has(bump_key):
        CombatF5SoakTracePartB._bump(bump_key)
    else:
        CombatF5SoakTracePartB._bump("hit_outcome_other")
    _OperationalLog.play_combat(line)


## F5 optional: per-hit damage outcome when **`COMBAT_DEV_VERBOSE`** (grep **`research_feel`**).


## F5 optional: per-hit damage outcome when **`COMBAT_DEV_VERBOSE`** (grep **`research_feel`**).
static func note_research_damage_outcome(part: String, result: Dictionary, extras: Dictionary) -> void:
    if not _combat_constants.combat_event_debug_verbose_active():
        return
    if not _OperationalLog.is_play_session_active():
        return
    var sub: String = str(extras.get("hit_sub_region", ""))
    var pen: float = float(result.get("penetration_to_tissue_mm", extras.get("penetration_to_tissue_mm", -1.0)))
    var ke_frac: float = float(result.get("transmitted_ke_fraction", 1.0))
    var line: String = (
        "research_feel part=%s sub=%s cut=%.1f blunt=%.1f bone=%.1f pen_mm=%.1f ke_frac=%.2f"
        % [
            part,
            sub if not sub.is_empty() else "-",
            float(result.get("final_cut", 0.0)),
            float(result.get("final_blunt", 0.0)),
            float(result.get("final_bone", 0.0)),
            pen,
            ke_frac,
        ]
    )
    if line == _last_research_feel_line:
        return
    _last_research_feel_line = line
    CombatF5SoakTracePartB._bump("research_feel")
    _OperationalLog.play_combat(line)


static func note_engagement_transition(from_mode: String, to_mode: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "engagement_transition %s -> %s" % [from_mode, to_mode]
    if line == _last_engagement_transition_line:
        return
    _last_engagement_transition_line = line
    CombatF5SoakTracePartB._bump("engagement_transition")
    _OperationalLog.play_combat(line)


static func note_fall_back_pick(tag: String, who: String, target_id: int) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "%s pick %s target_id=%d" % [tag.strip_edges(), who.strip_edges(), target_id]
    if line == _last_fall_back_pick_line:
        return
    _last_fall_back_pick_line = line
    _OperationalLog.play_combat(line)


static func note_cowering_fall_back_executed(who: String, file: int) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "cowering_fall_back executed %s rank 0->1 file %d" % [who.strip_edges(), file]
    if line == _last_cowering_fall_back_executed_line:
        return
    _last_cowering_fall_back_executed_line = line
    _OperationalLog.play_combat(line)


## F5 soak (**II-6**): grep **`ambient_pain_shock`**.


## F5 soak (**II-6**): grep **`ambient_pain_shock`**.
static func note_death_tick(who: String, death_reason: String) -> void:
    if not _OperationalLog.play_session_is_editor_f5():
        return
    var line: String = "DEATH (tick) %s  -  %s" % [who.strip_edges(), death_reason.strip_edges()]
    if line == _last_death_tick_line:
        return
    _last_death_tick_line = line
    _OperationalLog.play_combat(line)


static func note_exhaustion_crossing(who: String, band_pct: int, index_pct: float, perf_pct: int) -> void:
    if not _OperationalLog.play_session_is_editor_f5():
        return
    var line: String = (
        "exhaustion %s crossed %d%% (index %.0f%% perf %d%%)" % [who.strip_edges(), band_pct, index_pct, perf_pct]
    )
    if line == _last_exhaustion_crossing_line:
        return
    _last_exhaustion_crossing_line = line
    _OperationalLog.play_combat(line)


static func note_ambient_pain_shock(who: String, effective_pain: float, duration_s: float) -> void:
    if not _OperationalLog.play_session_is_editor_f5():
        return
    var line: String = (
        "ambient_pain_shock %s effective_pain=%.1f duration=%.1fs" % [who.strip_edges(), effective_pain, duration_s]
    )
    if line == _last_ambient_pain_shock_line:
        return
    _last_ambient_pain_shock_line = line
    _OperationalLog.play_combat(line)


static func note_fled(
    combatant_id: int, who: String, cohesion: float, casualties_pct: float, holding_field: bool
) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = (
        "fled id=%d %s cohesion=%.2f casualties=%.0f%% holding_field=%s"
        % [combatant_id, who.strip_edges(), cohesion, casualties_pct, str(holding_field).to_lower()]
    )
    if line == _last_fled_line:
        return
    _last_fled_line = line
    _OperationalLog.play_combat(line)


static func note_cowering_fall_back_listed(who: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "cowering_fall_back listed for %s" % who.strip_edges()
    if line == _last_cowering_fall_back_listed_line:
        return
    _last_cowering_fall_back_listed_line = line
    _OperationalLog.play_combat(line)


static func note_controlling_close_listed(c: Dictionary, hint: String) -> void:
    if not _OperationalLog.is_play_session_active() or c.is_empty():
        return
    var text: String = hint.strip_edges()
    if text.is_empty():
        return
    CombatF5SoakTracePartB._bump("controlling_close_hint")
    _OperationalLog.play_combat(
        (
            "controlling_close_list id=%d %s hint=%s"
            % [CombatantEntityAccess.id_int(c), CombatantEntityAccess.get_display_name(c), text]
        )
    )


static func note_mopup_hold_line_listed(c: Dictionary, hint: String) -> void:
    if not _OperationalLog.is_play_session_active() or c.is_empty():
        return
    var text: String = hint.strip_edges()
    if text.is_empty() or not CombatF5SoakTracePartB._fight_finish_hold_line_hint_text(text):
        return
    CombatF5SoakTracePartB._bump("mopup_gauge_hint")
    _OperationalLog.play_combat(
        (
            "mopup_hold_line_list id=%d %s hint=%s"
            % [CombatantEntityAccess.id_int(c), CombatantEntityAccess.get_display_name(c), text]
        )
    )


static func note_formation_move_pick(move_id: String, _initiator_id: int, partner_id: int) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "%s@%d" % [move_id.strip_edges(), partner_id]
    if line == _last_formation_move_pick_line:
        return
    _last_formation_move_pick_line = line
    _OperationalLog.play_combat(line)


## IV-11: grep **`leader_order=`** on F5 paste when **`FEATURE_LEADER_FORMATION_COMMAND`** on.


## IV-11: grep **`leader_order=`** on F5 paste when **`FEATURE_LEADER_FORMATION_COMMAND`** on.
static func note_leader_formation_command_pick(
    who: String, move_id: String, formation_id: String, side: String
) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    _OperationalLog.play_combat(
        (
            "leader_order=%s side=%s formation=%s who=%s"
            % [move_id.strip_edges(), side.strip_edges(), formation_id.strip_edges(), who.strip_edges()]
        )
    )


## Once per fight when player enters post-victory medical phase (grep **`medical_phase`**).


## Once per fight when player enters post-victory medical phase (grep **`medical_phase`**).
static func note_medical_phase_intro() -> void:
    if not _OperationalLog.is_play_session_active():
        return
    if _medical_phase_intro_logged:
        return
    _medical_phase_intro_logged = true
    # Grep **`medical_phase`**  -  not `medical_session` (would emit `medical medical_phase:`).
    _OperationalLog.play_combat(
        "medical_phase: full hemorrhage rates until TCCC control (pressure/TQ/pack/bandage); no passive blood recovery"
    )


static func note_medical_pack_listed(who: String, part: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var line: String = "medical_pack_wound listed for %s part=%s" % [who, part]
    if line == _last_medical_pack_listed_line:
        return
    _last_medical_pack_listed_line = line
    CombatF5SoakTracePartB._bump("medical_pack_listed")
    _OperationalLog.play_combat(line)
    CombatF5SoakTracePartB._maybe_flush_deferred_soak_coverage()


static func note_medical_action_pick(who: String, move_id: String, part: String, tgt_desc: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var pick_line: String = "medical_action pick %s move=%s part=%s (%s)" % [who, move_id, part, tgt_desc]
    if pick_line == _last_medical_action_pick_line:
        return
    _last_medical_action_pick_line = pick_line
    CombatF5SoakTracePartB._bump("medical_action_pick")
    _OperationalLog.play_combat(pick_line)
    if move_id == CombatConstants.MOVE_ID_PACK_WOUND:
        CombatF5SoakTracePartB._bump("medical_pack_pick")
        var pack_line: String = "medical_pack_wound pick %s part=%s (%s)" % [who, part, tgt_desc]
        _OperationalLog.play_combat(pack_line)
    CombatF5SoakTracePartB._maybe_flush_deferred_soak_coverage()


## Call when post-victory medical phase ends (early exit or End battle)  -  not only on medical picks.


## Call when post-victory medical phase ends (early exit or End battle)  -  not only on medical picks.
static func flush_deferred_soak_coverage() -> void:
    CombatF5SoakTracePartB._maybe_flush_deferred_soak_coverage()


## Re-validate Camp S8 optional tracks when **`campaign_medical_exit`** lands after an earlier medical flush.


## Re-validate Camp S8 optional tracks when **`campaign_medical_exit`** lands after an earlier medical flush.
static func refresh_camp_supplement_after_medical_exit() -> void:
    if not _OperationalLog.is_play_session_active() or not _soak_coverage_logged:
        return
    CombatF5SoakTracePartB._log_soak_coverage_camp_supplement()


## Player **`turn_ready`**: row gauge label + formation tooltip vs turn-ready formation line (**II-5a / II-5c**).
static func log_turn_ready_player_ui(manager: Node, c: Dictionary, actions: Array) -> void:
    if not _OperationalLog.is_play_session_active() or c.is_empty():
        return
    if not CombatantEntityAccess.is_player_side(c):
        return
    var cid: int = CombatantEntityAccess.id_int(c)
    var who: String = CombatantEntityAccess.get_display_name(c, cid)
    var label: String = BattleUIUpdater.gauge_label_text_for_combatant(c, manager)
    var stamp: String = CombatF5SoakTracePartB._formation_stamp_on_combatant(c)
    var hold: String = str(c.get(_combat_constants.COMBATANT_KEY_HOLD_LINE_FOCUS_ONLY_HINT, "")).strip_edges()
    var fp_line: String = (
        CombatF5SoakTracePartA
        . _get_player_turn_hints()
        . formation_and_rout_turn_ready_hint(manager, c, actions)
        . strip_edges()
    )
    var ctx: String = CombatF5SoakTracePartB._turn_ui_match_context(manager, c, actions, label, fp_line, hold)
    var formation_tip: String = ""
    var match_s: String = ctx
    if ctx.is_empty():
        formation_tip = (
            stamp if not stamp.is_empty() else CombatF5SoakTracePartB._formation_line_from_tooltip(c, manager)
        )
        if formation_tip.is_empty() and not hold.is_empty():
            formation_tip = hold
        match_s = CombatF5SoakTracePartB._tooltip_formation_match_label(formation_tip, fp_line, hold)
    else:
        # Counter / medical / melee-only  -  avoid stale formation stamp in gauge_tooltip_formation.
        if not fp_line.is_empty():
            formation_tip = fp_line
        elif ctx == "hold_line" and not hold.is_empty():
            formation_tip = hold
    CombatF5SoakTracePartB._bump("turn_ready")
    CombatF5SoakTracePartB._bump(CombatF5SoakTracePartB._tooltip_match_counter_key(match_s))
    var gauge_sig: String = "%d|%s|%s" % [cid, label, match_s]
    var skip_gauge_line: bool = gauge_sig == _last_turn_ready_gauge_sig
    _last_turn_ready_gauge_sig = gauge_sig
    if not skip_gauge_line:
        _OperationalLog.play_combat("turn_ready_gauge id=%d %s label=%s tooltip_match=%s" % [cid, who, label, match_s])
    if not formation_tip.is_empty() and formation_tip != fp_line:
        if formation_tip != _last_gauge_tooltip_formation_fp_line:
            _last_gauge_tooltip_formation_fp_line = formation_tip
            _OperationalLog.play_combat("gauge_tooltip_formation id=%d %s line=%s" % [cid, who, formation_tip])
    CombatF5SoakTracePartB._emit_turn_ready_formation_fp(cid, who, fp_line)


## Auto / manual weapon form change (**WF-1c / WF-3** soak grep). Production path: **`CombatWeaponForm.assign_form`**.


## Auto / manual weapon form change (**WF-1c / WF-3** soak grep). Production path: **`CombatWeaponForm.assign_form`**.
static func log_form_switch(_manager: Node, c: Dictionary, old_form: String, new_form: String, reason: String) -> void:
    if not _OperationalLog.is_play_session_active() or c.is_empty():
        return
    var cid: int = CombatantEntityAccess.id_int(c)
    var who: String = CombatantEntityAccess.get_display_name(c, cid)
    _OperationalLog.play_combat(
        (
            "form_switch id=%d %s %s->%s reason=%s"
            % [cid, who, old_form.strip_edges(), new_form.strip_edges(), reason.strip_edges()]
        )
    )


## Party diagram header above player rows (**#8**  -  grep **`diagram_banner player:`**).
static func log_diagram_banner_player(line: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var text: String = line.strip_edges()
    if text.is_empty() or text == " - ":
        return
    if text == _last_diagram_banner_line:
        return
    _last_diagram_banner_line = text
    CombatF5SoakTracePartB._bump("diagram_banner")
    _OperationalLog.play_combat("diagram_banner player: %s" % text)


## Enemy-side diagram (**II-8** symmetry  -  grep **`diagram_banner enemy:`**).


## Enemy-side diagram (**II-8** symmetry  -  grep **`diagram_banner enemy:`**).
static func log_diagram_banner_enemy(line: String) -> void:
    if not _OperationalLog.is_play_session_active():
        return
    var text: String = line.strip_edges()
    if text.is_empty() or text == " - ":
        return
    if text == _last_diagram_banner_enemy_line:
        return
    # UI may refresh before doctrine suffix is known (e.g. Pinch Center)  -  skip duplicate row.
    if not _last_diagram_banner_enemy_line.is_empty() and text.begins_with(_last_diagram_banner_enemy_line):
        _last_diagram_banner_enemy_line = text
        return
    _last_diagram_banner_enemy_line = text
    CombatF5SoakTracePartB._bump("diagram_banner_enemy")
    _OperationalLog.play_combat("diagram_banner enemy: %s" % text)
