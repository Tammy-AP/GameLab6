extends MeshInstance3D
# Scrolls the texture of the lava / cloud sea so it looks alive.

@export var scroll := Vector2(0.02, 0.012)


func _process(delta: float) -> void:
	var m := material_override as StandardMaterial3D
	if m:
		m.uv1_offset += Vector3(scroll.x * delta, scroll.y * delta, 0.0)
