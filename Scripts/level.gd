extends Node3D
# Root script of every level scene.

@export var level_title := "Level"
@export var level_subtitle := ""
@export var bgm_name := "bgm_sky"


func _ready() -> void:
	var spawn : Marker3D = $SpawnPoint
	var total := get_tree().get_nodes_in_group("coin").size()
	GameManager.register_level(total, spawn.global_position)
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn.global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioManager.play_bgm(bgm_name)
	$HUD.show_title(level_title, level_subtitle)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameManager.restart_level()
