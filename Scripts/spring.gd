extends Area3D
# Bounce pad: launches the player upward.

@export var launch_force := 15.0

@onready var pad : Node3D = $Pad
var _pad_y := 0.0


func _ready() -> void:
	_pad_y = pad.position.y
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	body.launch(launch_force)
	AudioManager.play("spring")
	var tw := create_tween()
	tw.tween_property(pad, "scale", Vector3(1.25, 0.4, 1.25), 0.06)
	tw.tween_property(pad, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
