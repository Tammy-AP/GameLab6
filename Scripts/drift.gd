extends Node3D
# Slow sideways drifting for clouds.

@export var speed := 0.6
@export var range_x := 14.0

var _start_x := 0.0
var _t := 0.0


func _ready() -> void:
	_start_x = position.x
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * speed * 0.2
	position.x = _start_x + sin(_t) * range_x
