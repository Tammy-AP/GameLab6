extends Area3D
# Coin (required to open the door) or Heart (restores one life).

@export_enum("coin", "heart") var kind := "coin"
@export var spin_speed := 2.6
@export var bob_height := 0.14

var _t := 0.0
var _collected := false

@onready var mesh : Node3D = $Mesh


func _ready() -> void:
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	mesh.rotation.y += spin_speed * delta
	mesh.position.y = sin(_t * 3.0) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	if kind == "heart" and GameManager.hearts >= GameManager.MAX_HEARTS:
		return
	_collected = true
	if kind == "coin":
		GameManager.collect_coin()
		AudioManager.play("coin", randf_range(0.95, 1.1))
	else:
		GameManager.heal()
		GameManager.toast.emit("+1 heart")
		AudioManager.play("heart")
	var tw := create_tween()
	tw.tween_property(mesh, "scale", Vector3.ONE * 1.7, 0.12)
	tw.tween_property(mesh, "scale", Vector3.ZERO, 0.12)
	tw.tween_callback(queue_free)
