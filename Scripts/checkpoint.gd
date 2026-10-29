extends Area3D
# Flag that saves the respawn position.

var _active := false

@onready var flag : MeshInstance3D = $Flag


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if _active or not body.is_in_group("player"):
		return
	_active = true
	GameManager.checkpoint_pos = global_position + Vector3(0, 0.3, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.25, 1.0, 0.45)
	m.emission_enabled = true
	m.emission = Color(0.2, 1.0, 0.4)
	m.emission_energy_multiplier = 1.2
	flag.material_override = m
	AudioManager.play("checkpoint")
	GameManager.toast.emit("Checkpoint!")
	var tw := create_tween()
	tw.tween_property(flag, "position:y", flag.position.y + 0.25, 0.25)
