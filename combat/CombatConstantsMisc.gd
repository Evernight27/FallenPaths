class_name CombatConstantsMisc
extends RefCounted

const DEFAULT_STAT_VALUE := 100

const MEDICAL_ITEM_TOURNIQUET := "tourniquet"
const PATH_MAIN_SCENE := "res://main.tscn"
const PATH_COUNTER_TEMPO := "res://combat/CounterTempo.gd"

const SIDE_PLAYER := "player"
const SIDE_ENEMY := "enemy"


static func clamp_prob(v: float) -> float:
    return clampf(v, 0.0, 1.0)


static func companion_path(index: int) -> String:
    return "res://world/companion_%d.tscn" % index
