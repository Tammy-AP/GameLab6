extends AnimatableBody3D
# Crumbling platform: shakes when stood on, falls, then comes back.

@export var fall_delay := 0.7
@export var respawn_time := 3.5

enum State { IDLE, SHAKING, FALLING, GONE }

var _state := State.IDLE
var _timer := 0.0
var _fall_speed := 0.0
var _origin := Vector3.ZERO

@onready var trigger : Area3D = $Trigger
@onready var shape : CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	sync_to_physics = true
	_origin = global_position
	trigger.body_entered.connect(_on_trigger)


func _on_trigger(body: Node3D) -> void:
	if _state == State.IDLE and body.is_in_group("player"):
		_state = State.SHAKING
		_timer = fall_delay


func _physics_process(delta: float) -> void:
	match _state:
		State.SHAKING:
			_timer -= delta
			global_position = _origin + Vector3(randf_range(-0.05, 0.05), 0.0, randf_range(-0.05, 0.05))
			if _timer <= 0.0:
				_state = State.FALLING
				_fall_speed = 0.0
		State.FALLING:
			_fall_speed += 28.0 * delta
			global_position.y -= _fall_speed * delta
			if global_position.y < _origin.y - 20.0:
				_state = State.GONE
				_timer = respawn_time
				visible = false
				shape.disabled = true
		State.GONE:
			_timer -= delta
			if _timer <= 0.0:
				global_position = _origin
				visible = true
				shape.disabled = false
				_state = State.IDLE
