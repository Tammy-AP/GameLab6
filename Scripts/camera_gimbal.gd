extends Node3D
# Orbit camera: mouse / Q-E to rotate. ESC toggles the mouse cursor.

@export var mouse_sensitivity := 0.003
@export var key_turn_speed := 2.2
@export var min_pitch := -1.25
@export var max_pitch := -0.08

@onready var pitch_node : Node3D = $Pitch
@onready var arm : SpringArm3D = $Pitch/SpringArm3D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		pitch_node.rotation.x = clampf(pitch_node.rotation.x - event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
	if event.is_action_pressed("mouse_visible"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var turn := Input.get_axis("cam_left", "cam_right")
	rotation.y -= turn * key_turn_speed * delta
