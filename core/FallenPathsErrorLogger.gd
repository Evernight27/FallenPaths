class_name FallenPathsErrorLogger
extends Logger

## Mirrors Godot script/runtime/shader errors to **`FP_ERROR`** during editor play (grep with `SCRIPT_ERROR`).
## Skips Godot warnings and operational **`FP_WARN`** lines — those stay on stdout only.
## Registered from **`OperationalLog.begin_play_session`**; do not **`print`** / **`push_error`** here (recursion).

# Runtime preload ' circular dependency (OperationalLog preloads FallenPathsErrorLogger).
static var _operational_log_cache: Variant = null
static var _script_error_count: int = 0

var _mutex: Mutex = Mutex.new()


static func _get_operational_log() -> GDScript:
    if _operational_log_cache == null:
        _operational_log_cache = load("res://core/OperationalLog.gd")
    return _operational_log_cache


static func reset_script_error_count() -> void:
    _script_error_count = 0


static func get_script_error_count() -> int:
    return _script_error_count


func _log_error(
    function: String,
    file: String,
    line: int,
    code: String,
    rationale: String,
    _editor_notify: bool,
    error_type: int,
    _script_backtraces: Array
) -> void:
    if error_type == Logger.ERROR_TYPE_WARNING:
        return
    _mutex.lock()
    var kind: String = "SCRIPT_ERROR"
    match error_type:
        Logger.ERROR_TYPE_SHADER:
            kind = "SHADER_ERROR"
        Logger.ERROR_TYPE_ERROR:
            kind = "ERROR"
        Logger.ERROR_TYPE_SCRIPT:
            kind = "SCRIPT_ERROR"
    var where: String = "%s:%d" % [file, line]
    if not function.is_empty():
        where = "%s in %s()" % [where, function]
    var msg: String = "%s %s  -  %s" % [kind, where, code]
    if not rationale.is_empty():
        msg += " (%s)" % rationale
    if not _script_backtraces.is_empty():
        var bt0: Variant = _script_backtraces[0]
        if bt0 is String and not (bt0 as String).is_empty():
            msg += " | %s" % bt0
    _script_error_count += 1
    printerr("[FP_ERR_LOGGER] %s" % msg)
    _get_operational_log().emit(_get_operational_log().TAG_ERROR, msg)
    _mutex.unlock()


func _log_message(message: String, error: bool) -> void:
    if not error:
        return
    var body: String = message.strip_edges()
    if body.begins_with("FP_"):
        return
    _mutex.lock()
    _get_operational_log().emit(_get_operational_log().TAG_ERROR, "RUNTIME %s" % body)
    _mutex.unlock()
