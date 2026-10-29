extends Node
# Autoload: game state (coins, hearts, current level) + scene transitions.

signal coins_changed(collected: int, total: int)
signal hearts_changed(hearts: int)
signal all_coins_collected
signal toast(message: String)

const LEVELS : Array[String] = [
	"res://Scenes/Levels/level_01.tscn",
	"res://Scenes/Levels/level_02.tscn",
]
const MENU_SCENE := "res://Scenes/Menu/main_menu.tscn"
const WIN_SCENE := "res://Scenes/Menu/win_screen.tscn"
const MAX_HEARTS := 3

var level_index := 0
var coins := 0
var total_coins := 0
var hearts := MAX_HEARTS
var deaths := 0
var run_time := 0.0
var total_collected := 0
var checkpoint_pos := Vector3.ZERO
var playing := false
var transitioning := false

var _fade : ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.04, 0.04, 0.09, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _process(delta: float) -> void:
	if playing:
		run_time += delta


# ---------- Run control ----------

func start_game() -> void:
	level_index = 0
	deaths = 0
	run_time = 0.0
	total_collected = 0
	change_scene(LEVELS[0])


func go_to_menu() -> void:
	playing = false
	change_scene(MENU_SCENE)


func restart_level() -> void:
	change_scene(LEVELS[level_index])


func complete_level() -> void:
	playing = false
	if level_index + 1 < LEVELS.size():
		level_index += 1
		change_scene(LEVELS[level_index])
	else:
		AudioManager.play("win")
		change_scene(WIN_SCENE)


# ---------- Level state ----------

func register_level(total: int, spawn_pos: Vector3) -> void:
	coins = 0
	total_coins = total
	hearts = MAX_HEARTS
	checkpoint_pos = spawn_pos
	playing = true
	coins_changed.emit(coins, total_coins)
	hearts_changed.emit(hearts)


func collect_coin() -> void:
	coins += 1
	total_collected += 1
	coins_changed.emit(coins, total_coins)
	if coins >= total_coins:
		AudioManager.play("door_open")
		all_coins_collected.emit()
		toast.emit("All coins collected - the door is open!")


func heal() -> void:
	hearts = mini(hearts + 1, MAX_HEARTS)
	hearts_changed.emit(hearts)


# Returns true if the player is still alive.
func lose_heart() -> bool:
	hearts -= 1
	deaths += 1
	hearts_changed.emit(hearts)
	return hearts > 0


func game_over() -> void:
	playing = false
	toast.emit("Out of hearts! Restarting the level...")
	await get_tree().create_timer(1.6).timeout
	restart_level()


func is_door_open() -> bool:
	return coins >= total_coins


# ---------- Scene change with fade ----------

func change_scene(path: String) -> void:
	if transitioning:
		return
	transitioning = true
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.45)
	await tw2.finished
	transitioning = false
