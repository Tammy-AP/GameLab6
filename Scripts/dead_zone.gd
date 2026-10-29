extends Area3D
# Big invisible box under the level: falling into it costs a heart and respawns you.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		AudioManager.play("fall")
		body.fall_out()
