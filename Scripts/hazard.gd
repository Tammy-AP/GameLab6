extends Area3D
# Anything that hurts the player on touch (spikes, ...).


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.hurt()
