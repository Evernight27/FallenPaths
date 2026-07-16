class_name CombatConstantsDebug
extends RefCounted

const COMBAT_DEV_VERBOSE := false
const COMBAT_DEBUG := false
const COMBAT_DEBUG_CALIBRATION := false
const COMBAT_EVENT_DEBUG := false
const COMBAT_EVENT_DEBUG_VERBOSE := false
const COMBAT_FLOW_LOG_SUPPRESS_REPEATED := true
const COMBAT_VACANCY_RECONCILE_DIRTY_ONLY := true
const COMBAT_VACANCY_DIRTY_SAFETY_EVERY_N_FRAMES := 0
const COMBAT_FORMATION_INVARIANT_DEBUG := false
static var _combat_dev_verbose_override: int = -1
static var _headless_harness_quiet: bool = false
static var _play_session_diagnostic: bool = false
static var _combat_hit_summary_override: int = -1


static func set_headless_harness_quiet(on: bool) -> void:
    _headless_harness_quiet = on


static func is_headless_harness_quiet() -> bool:
    return _headless_harness_quiet


static func set_play_session_diagnostic(on: bool) -> void:
    _play_session_diagnostic = on


static func play_session_diagnostic_active() -> bool:
    return _play_session_diagnostic and not _headless_harness_quiet


static func set_combat_hit_summary_override(on: bool) -> void:
    _combat_hit_summary_override = 1 if on else 0


static func clear_combat_hit_summary_override() -> void:
    _combat_hit_summary_override = -1


static func combat_hit_summary_active() -> bool:
    if _combat_hit_summary_override >= 0:
        return _combat_hit_summary_override != 0
    if _headless_harness_quiet:
        return false
    return play_session_diagnostic_active()


static func set_combat_dev_verbose_override(on: bool) -> void:
    _combat_dev_verbose_override = 1 if on else 0


static func clear_combat_dev_verbose_override() -> void:
    _combat_dev_verbose_override = -1


static func combat_dev_verbose_active() -> bool:
    if _headless_harness_quiet:
        return false
    if _combat_dev_verbose_override >= 0:
        return _combat_dev_verbose_override != 0
    return COMBAT_DEV_VERBOSE


static func combat_debug_active() -> bool:
    return (COMBAT_DEBUG or combat_dev_verbose_active()) and not _headless_harness_quiet


static func combat_event_debug_active() -> bool:
    return (
        (COMBAT_EVENT_DEBUG or combat_dev_verbose_active() or _play_session_diagnostic) and not _headless_harness_quiet
    )


static func combat_event_debug_verbose_active() -> bool:
    return combat_event_debug_active() and (COMBAT_EVENT_DEBUG_VERBOSE or combat_dev_verbose_active())
