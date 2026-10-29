extends Area3D
# Spinning saw blade that patrols back and forth.

@export var travel := Vector3(2.4, 0, 0)
@export var period := 3.2
@export var phase := 0.0
@export var spin_speed := 12.0

var _origin := Vector3.ZERO
var _t := 0.0

@onready var blade : Node3D = $Blade


func _ready() -> void:
	_origin = position
	_t = phase * period
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	var s := 0.5 - 0.5 * cos(TAU * _t / period)
	position = _origin + travel * s


func _process(delta: float) -> void:
	blade.rotate_z(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.hurt()
