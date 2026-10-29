@tool
extends Node3D
# Character rig. Works in two modes:
#  1) If res://Assets/Characters/player.glb exists it is loaded. For Exercise 6 this is
#     our own character (Tools/build_character.py) with a Mixamo-style skeleton. On import
#     it is retargeted with "Mixamo BoneMap.tres", so the Godot4-OpenAnimationLibraries
#     (MeleeLib / ShooterLib) can be added to its AnimationPlayer and played on it.
#  2) Otherwise a built-in low-poly placeholder robot is built, with its own animations.
# The Player script only ever calls play("Idle"|"Run"|"Jump"|"Flip").

@export_group("Custom Character (.glb)")
@export var custom_model_path := "res://Assets/Characters/player.glb"
@export var custom_model_scale := 1.0
@export var custom_model_offset := Vector3.ZERO
@export_range(-180.0, 180.0) var custom_model_yaw := 0.0
## Animation libraries added to the character's AnimationPlayer.
## Each library is named after its file, e.g. "MeleeLib/Sprint".
@export var animation_library_paths := PackedStringArray([
	"res://Assets/AnimLibs/MeleeLib.res",
	"res://Assets/AnimLibs/ShooterLib.res",
])

@export_group("Animation Names (blank = auto-detect)")
@export var anim_idle := ""
@export var anim_run := ""
@export var anim_jump := ""
## Looping air pose played after the jump animation ends.
@export var anim_fall := ""
@export var anim_flip := ""
## Spin the whole model 360 degrees during the Flip (double jump).
@export var flip_spin := true
@export var flip_duration := 0.55

const BODY_Y := 0.5
const PIVOT_Y := 0.9

var anim_player : AnimationPlayer
var _names := {}
var _current := ""
var _blink_tween : Tween
var _flip_tween : Tween
var _pivot : Node3D
var _custom := false


func _ready() -> void:
	# A model placed by hand under this node (drag a .glb in the editor) is used as-is.
	if get_child_count() > 0:
		anim_player = _find_anim_player(self)
		_add_libraries()
		_resolve_custom_animations()
		return
	var loaded := false
	if custom_model_path != "" and ResourceLoader.exists(custom_model_path):
		var res = load(custom_model_path)
		if res is PackedScene:
			# The pivot sits at the middle of the body so the flip spins around the belly.
			_pivot = Node3D.new()
			_pivot.name = "FlipPivot"
			_pivot.position = Vector3(0, PIVOT_Y, 0)
			add_child(_pivot)
			var inst : Node3D = res.instantiate()
			inst.name = "CustomCharacter"
			inst.scale = Vector3.ONE * custom_model_scale
			inst.position = custom_model_offset - Vector3(0, PIVOT_Y, 0)
			inst.rotation_degrees.y = custom_model_yaw
			_pivot.add_child(inst)
			anim_player = _find_anim_player(inst)
			_add_libraries()
			_resolve_custom_animations()
			_custom = true
			loaded = true
	if not loaded:
		_build_placeholder()


# ---------------------------------------------------------------- public API

func play(action: String, blend: float = 0.2, speed: float = 1.0, restart: bool = false) -> void:
	if anim_player == null:
		return
	if not restart and action == _current:
		return
	var n : String = _names.get(action, "")
	if n == "":
		return
	var from_flip := _current == "Flip" and action != "Flip"
	if from_flip and not _custom:
		blend = 0.0
	_current = action
	if _custom:
		if action == "Flip":
			_start_flip_spin()
			blend = 0.08
		elif from_flip:
			_end_flip_spin()
			if action == "Jump" and _names.get("Fall", "") != "":
				# coming out of the flip we are already in the air: go straight to the fall loop
				anim_player.play(_names["Fall"], 0.15)
				return
	if restart:
		anim_player.stop()
	anim_player.play(n, blend, speed)


func action_length(action: String, fallback: float) -> float:
	if anim_player == null:
		return fallback
	if action == "Flip" and _custom and flip_spin:
		return flip_duration
	var n : String = _names.get(action, "")
	if n == "" or not anim_player.has_animation(n):
		return fallback
	return anim_player.get_animation(n).length


func _start_flip_spin() -> void:
	if not flip_spin or _pivot == null:
		return
	if _flip_tween:
		_flip_tween.kill()
	_pivot.rotation.x = 0.0
	_flip_tween = create_tween()
	_flip_tween.tween_property(_pivot, "rotation:x", TAU, flip_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _end_flip_spin() -> void:
	if _pivot == null:
		return
	if _flip_tween:
		_flip_tween.kill()
	_flip_tween = null
	_pivot.rotation.x = 0.0


func _on_animation_finished(anim_name: StringName) -> void:
	# Jump (take-off) flows into the looping fall pose.
	if _current == "Jump" and String(anim_name) == _names.get("Jump", "") and _names.get("Fall", "") != "":
		anim_player.play(_names["Fall"], 0.15)


func blink(duration: float) -> void:
	if _blink_tween:
		_blink_tween.kill()
	_blink_tween = create_tween()
	var count := int(duration / 0.12)
	for i in count:
		_blink_tween.tween_callback(_toggle_visible)
		_blink_tween.tween_interval(0.06)
	_blink_tween.tween_callback(_show_again)


func _toggle_visible() -> void:
	visible = not visible


func _show_again() -> void:
	visible = true


# ---------------------------------------------------------------- custom model

func _find_anim_player(root: Node) -> AnimationPlayer:
	var found := root.find_children("*", "AnimationPlayer", true, false)
	if found.size() > 0:
		return found[0] as AnimationPlayer
	return null


func _add_libraries() -> void:
	if anim_player == null:
		return
	for path in animation_library_paths:
		var lib_name := path.get_file().get_basename()
		if anim_player.has_animation_library(lib_name) or not ResourceLoader.exists(path):
			continue
		var lib = load(path)
		if lib is AnimationLibrary:
			anim_player.add_animation_library(lib_name, lib)


func _resolve_custom_animations() -> void:
	if anim_player == null:
		push_warning("Custom character has no AnimationPlayer - it will not animate.")
		return
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	var list := anim_player.get_animation_list()
	_names["Idle"] = _pick(list, anim_idle, ["idle", "stand", "breath"])
	_names["Run"] = _pick(list, anim_run, ["run", "sprint", "jog", "walk"])
	_names["Jump"] = _pick(list, anim_jump, ["jump", "fall", "air"])
	_names["Fall"] = _pick(list, anim_fall, []) if anim_fall != "" else ""
	_names["Flip"] = _pick(list, anim_flip, ["flip", "roll", "spin", "somersault"])
	if _names["Run"] == "":
		_names["Run"] = _names["Idle"]
	if _names["Jump"] == "":
		_names["Jump"] = _names["Idle"]
	if _names["Flip"] == "":
		_names["Flip"] = _names["Jump"]
	for key in ["Idle", "Run"]:
		var n : String = _names[key]
		if n != "":
			anim_player.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	print("Character animations -> ", _names)


func _pick(list: PackedStringArray, forced: String, keywords: Array) -> String:
	if forced != "" and list.has(forced):
		return forced
	for kw in keywords:
		var best := ""
		for n in list:
			var s := String(n)
			if s.to_lower().contains(kw):
				if best == "" or s.length() < best.length():
					best = s
		if best != "":
			return best
	return ""


# ---------------------------------------------------------------- placeholder robot

func _mat(c: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _add_sphere(parent: Node3D, node_name: String, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _add_limb(parent: Node3D, node_name: String, pivot_pos: Vector3, size: Vector3, mat: Material, tip_mat: Material, tip_size: Vector3, tip_offset: Vector3) -> void:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pivot_pos
	parent.add_child(pivot)
	_add_box(pivot, "Mesh", size, Vector3(0, -size.y * 0.5, 0), mat)
	_add_box(pivot, "Tip", tip_size, tip_offset, tip_mat)


func _build_placeholder() -> void:
	var teal := _mat(Color(0.18, 0.72, 0.74))
	var cream := _mat(Color(0.98, 0.93, 0.82))
	var coral := _mat(Color(1.0, 0.42, 0.36))
	var dark := _mat(Color(0.12, 0.13, 0.18))
	var pink := _mat(Color(1.0, 0.5, 0.78), 1.5)

	var body := Node3D.new()
	body.name = "Body"
	body.position = Vector3(0, BODY_Y, 0)
	add_child(body)

	_add_box(body, "Torso", Vector3(0.5, 0.55, 0.34), Vector3(0, 0.3, 0), teal)
	_add_box(body, "Belt", Vector3(0.52, 0.1, 0.36), Vector3(0, 0.08, 0), dark)
	_add_box(body, "Scarf", Vector3(0.58, 0.12, 0.42), Vector3(0, 0.62, 0), coral)
	_add_box(body, "ScarfTail", Vector3(0.14, 0.42, 0.06), Vector3(-0.18, 0.4, -0.24), coral)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.98, 0)
	body.add_child(head)
	_add_sphere(head, "HeadMesh", 0.32, Vector3.ZERO, cream)
	_add_box(head, "EyeL", Vector3(0.09, 0.12, 0.05), Vector3(0.12, 0.03, 0.29), dark)
	_add_box(head, "EyeR", Vector3(0.09, 0.12, 0.05), Vector3(-0.12, 0.03, 0.29), dark)
	_add_box(head, "Stalk", Vector3(0.04, 0.2, 0.04), Vector3(0, 0.4, 0), dark)
	_add_sphere(head, "Bulb", 0.08, Vector3(0, 0.54, 0), pink)

	_add_limb(body, "ArmL", Vector3(0.36, 0.52, 0), Vector3(0.16, 0.42, 0.16), teal, cream, Vector3(0.19, 0.12, 0.19), Vector3(0, -0.42, 0))
	_add_limb(body, "ArmR", Vector3(-0.36, 0.52, 0), Vector3(0.16, 0.42, 0.16), teal, cream, Vector3(0.19, 0.12, 0.19), Vector3(0, -0.42, 0))
	_add_limb(body, "LegL", Vector3(0.14, 0.0, 0), Vector3(0.2, 0.5, 0.22), dark, coral, Vector3(0.22, 0.1, 0.32), Vector3(0, -0.45, 0.05))
	_add_limb(body, "LegR", Vector3(-0.14, 0.0, 0), Vector3(0.2, 0.5, 0.22), dark, coral, Vector3(0.22, 0.1, 0.32), Vector3(0, -0.45, 0.05))

	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)
	var lib := AnimationLibrary.new()
	lib.add_animation("Idle", _anim_idle())
	lib.add_animation("Run", _anim_run())
	lib.add_animation("Jump", _anim_jump())
	lib.add_animation("Flip", _anim_flip())
	anim_player.add_animation_library("", lib)
	_names = {"Idle": "Idle", "Run": "Run", "Jump": "Jump", "Flip": "Flip"}


# keys: Array of [time, value]
func _sample(length: float, steps: int, fn: Callable) -> Array:
	var keys := []
	for i in steps + 1:
		var p := float(i) / float(steps)
		keys.append([p * length, fn.call(p)])
	return keys


func _const(length: float, v: Vector3) -> Array:
	return [[0.0, v], [length, v]]


func _make_anim(length: float, loop: bool, tracks: Dictionary) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for path in tracks:
		var t := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(t, NodePath(path))
		if loop:
			a.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
		for k in tracks[path]:
			a.track_insert_key(t, k[0], k[1])
	return a


func _anim_idle() -> Animation:
	var T := 2.0
	return _make_anim(T, true, {
		"Body:position": _sample(T, 8, func(p): return Vector3(0, BODY_Y + 0.025 * sin(TAU * p), 0)),
		"Body:rotation": _const(T, Vector3.ZERO),
		"Body/ArmL:rotation": _sample(T, 8, func(p): return Vector3(0, 0, 0.1 + 0.03 * sin(TAU * p))),
		"Body/ArmR:rotation": _sample(T, 8, func(p): return Vector3(0, 0, -0.1 - 0.03 * sin(TAU * p))),
		"Body/LegL:rotation": _const(T, Vector3.ZERO),
		"Body/LegR:rotation": _const(T, Vector3.ZERO),
	})


func _anim_run() -> Animation:
	var T := 0.5
	return _make_anim(T, true, {
		"Body:position": _sample(T, 8, func(p): return Vector3(0, BODY_Y + 0.07 * absf(sin(TAU * p)), 0)),
		"Body:rotation": _const(T, Vector3(0.2, 0, 0)),
		"Body/ArmL:rotation": _sample(T, 8, func(p): return Vector3(-0.95 * sin(TAU * p), 0, 0.1)),
		"Body/ArmR:rotation": _sample(T, 8, func(p): return Vector3(0.95 * sin(TAU * p), 0, -0.1)),
		"Body/LegL:rotation": _sample(T, 8, func(p): return Vector3(0.95 * sin(TAU * p), 0, 0)),
		"Body/LegR:rotation": _sample(T, 8, func(p): return Vector3(-0.95 * sin(TAU * p), 0, 0)),
	})


func _anim_jump() -> Animation:
	var T := 0.3
	var y := Vector3(0, BODY_Y, 0)
	return _make_anim(T, false, {
		"Body:position": _const(T, y),
		"Body:rotation": _const(T, Vector3.ZERO),
		"Body/ArmL:rotation": [[0.0, Vector3(0, 0, 0.1)], [0.15, Vector3(-2.6, 0, 0.4)]],
		"Body/ArmR:rotation": [[0.0, Vector3(0, 0, -0.1)], [0.15, Vector3(-2.6, 0, -0.4)]],
		"Body/LegL:rotation": [[0.0, Vector3.ZERO], [0.15, Vector3(-0.6, 0, 0)]],
		"Body/LegR:rotation": [[0.0, Vector3.ZERO], [0.15, Vector3(0.5, 0, 0)]],
	})


func _anim_flip() -> Animation:
	var T := 0.55
	var y := BODY_Y
	return _make_anim(T, false, {
		"Body:position": [[0.0, Vector3(0, y, 0)], [T * 0.5, Vector3(0, y + 0.12, 0)], [T, Vector3(0, y, 0)]],
		"Body:rotation": [[0.0, Vector3.ZERO], [T, Vector3(TAU, 0, 0)]],
		"Body/ArmL:rotation": _const(T, Vector3(-1.4, 0, 0.3)),
		"Body/ArmR:rotation": _const(T, Vector3(-1.4, 0, -0.3)),
		"Body/LegL:rotation": _const(T, Vector3(-1.3, 0, 0)),
		"Body/LegR:rotation": _const(T, Vector3(-1.3, 0, 0)),
	})
