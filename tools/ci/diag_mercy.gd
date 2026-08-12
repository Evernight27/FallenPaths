extends SceneTree


func _init() -> void:
    var failures: PackedStringArray = []
    var MercyTail := preload("res://harness/mercy/MercyExecuteTail.gd")
    MercyTail.run(failures)
    if failures.is_empty():
        print("DIAG_MERCY: OK (%d assertions clean)" % failures.size())
        quit(0)
    for f in failures:
        print("DIAG_MERCY_FAIL: %s" % f)
    quit(1)
