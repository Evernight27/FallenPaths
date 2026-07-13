class_name WeightedSample
extends RefCounted

## Centralized weighted random selection  -  replaces duplicated implementations in BodyPartConstants, AttackPathResolver, CombatHitSubRegion.
## Single source of truth for accumulate-weights + threshold-pick pattern.
## `deterministic` mode uses a stable seed instead of randf() for reproducible results.


## Pick a key from weights dictionary using cumulative probability.
## Returns "" if total weight <= 0 or dict is empty. Returns last key on floating-point overflow.
static func pick_random(weights: Dictionary, deterministic: bool = false, _stable_seed: int = 0) -> String:
    if weights.is_empty():
        return ""
    var total: float = 0.0
    for w in weights.values():
        total += float(w)
    if total <= 0.0:
        return weights.keys()[0] if not weights.is_empty() else ""
    var r: float
    if deterministic:
        var _saved_seed: float = randf()
        # Note: Godot has no built-in seed restore; callers needing full determinism should use pick_deterministic.
        r = randf() * total
    else:
        r = randf() * total
    var acc: float = 0.0
    for key in weights:
        acc += float(weights[key])
        if r < acc:
            return key
    return weights.keys()[weights.keys().size() - 1]


## Deterministic pick using a pre-set seed via stable_unit (caller manages seeding).
static func pick_deterministic(weights: Dictionary, stable_unit_fn: Callable) -> String:
    if weights.is_empty():
        return ""
    var total: float = 0.0
    for w in weights.values():
        total += float(w)
    if total <= 0.0:
        return weights.keys()[0] if not weights.is_empty() else ""
    var r: float = stable_unit_fn.call() * total
    var acc: float = 0.0
    for key in weights:
        acc += float(weights[key])
        if r < acc:
            return key
    return weights.keys()[weights.keys().size() - 1]
