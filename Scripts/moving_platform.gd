extends AnimatableBody3D
# Platform that glides back and forth between its start and start + travel.

@export var travel := Vector3(0, 0, 6)
@export var period := 5.0
@export var phase := 0.0

var _origin := Vector3.ZERO
var _t := 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = global_position
	_t = phase * period


func _physics_process(delta: float) -> void:
	_t += delta
	var s := 0.5 - 0.5 * cos(TAU * _t / period)
	global_position = _origin + travel * s
