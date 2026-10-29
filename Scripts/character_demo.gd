extends Node3D
# Exercise 6 - Character Demo scene.
# Shows our own character (Assets/Characters/player.glb, Mixamo-style skeleton retargeted with
# "Mixamo BoneMap.tres") playing animations from Godot4-OpenAnimationLibraries:
# MeleeLib.res and ShooterLib.res. Weapons are attached to the hand bones with BoneAttachment3D.

const CHARACTER := "res://Assets/Characters/player.glb"
const LIBRARIES := ["res://Assets/AnimLibs/MeleeLib.res", "res://Assets/AnimLibs/ShooterLib.res"]
const PIVOT_Y := 0.9

# [tab, button text, animation(s), prop, extra]
#  - several animations are chained with ">" ; "Anim:0.7" holds a looping step for 0.7 s
#  - extra: "arc" = hop into the air, "flip" = hop + somersault
const ENTRIES := [
	["Basic", "Idle", "ShooterLib/idle", "", ""],
	["Basic", "Walk", "ShooterLib/walk", "", ""],
	["Basic", "Run", "ShooterLib/run_067", "", ""],
	["Basic", "Sprint", "MeleeLib/Sprint", "", ""],
	["Basic", "Jump", "MeleeLib/Jump>MeleeLib/LightFalling:0.62>MeleeLib/LandHard", "", "arc"],
	["Basic", "Front Flip", "MeleeLib/Jump>MeleeLib/LightFalling:0.85>MeleeLib/LandHard", "", "flip"],
	["Basic", "Falling", "MeleeLib/LightFalling", "", ""],
	["Basic", "Roll", "MeleeLib/Roll", "", ""],
	["Basic", "Strafe", "ShooterLib/strafe-l", "", ""],
	["Basic", "Crouch", "ShooterLib/crouch-idle", "", ""],
	["Basic", "Crouch Walk", "ShooterLib/crouch-walk", "", ""],
	["Basic", "Sneak", "ShooterLib/sneak-walk", "", ""],
	["Basic", "Crawl", "ShooterLib/prone-crawl", "", ""],
	["Basic", "Vault", "ShooterLib/vault-1m", "", ""],
	["Basic", "Climb", "MeleeLib/LadderClimbing", "", ""],
	["Basic", "Punch", "ShooterLib/punch1", "", ""],
	["Basic", "Kick", "ShooterLib/kick1", "", ""],
	["Basic", "Knock Down", "ShooterLib/knockdown>ShooterLib/ko-idle:0.8>ShooterLib/ko-getup", "", ""],
	["Melee", "Sword Idle", "MeleeLib/LightIdle", "sword", ""],
	["Melee", "Sword Run", "MeleeLib/LightRunning", "sword", ""],
	["Melee", "Slash 1", "MeleeLib/Slash1", "sword", ""],
	["Melee", "Slash 2", "MeleeLib/Slash2", "sword", ""],
	["Melee", "Slash 3", "MeleeLib/Slash3", "sword", ""],
	["Melee", "Combo x3", "MeleeLib/Slash1>MeleeLib/Slash2>MeleeLib/Slash3", "sword", ""],
	["Melee", "Stab", "MeleeLib/Stab1", "sword", ""],
	["Melee", "Uppercut", "MeleeLib/SlashUppercut", "sword", ""],
	["Melee", "Jump Attack", "MeleeLib/LightJumpAttack", "sword", ""],
	["Melee", "Block", "MeleeLib/Guarding", "sword_shield", ""],
	["Melee", "Parry", "MeleeLib/GuardParry", "sword_shield", ""],
	["Melee", "Shield Bash", "MeleeLib/ShieldBash", "sword_shield", ""],
	["Melee", "Heavy Idle", "MeleeLib/HeavyIdle", "greatsword", ""],
	["Melee", "Heavy Attack", "MeleeLib/Heavy1", "greatsword", ""],
	["Melee", "Heavy Attack 2", "MeleeLib/Heavy2", "greatsword", ""],
	["Melee", "Spin Attack", "MeleeLib/HeavySpin", "greatsword", ""],
	["Melee", "Heavy Uppercut", "MeleeLib/HeavyUppercut", "greatsword", ""],
	["Melee", "Hurt", "MeleeLib/Hurt1", "sword", ""],
	["Melee", "Die", "MeleeLib/Die1", "sword", ""],
	["Shooter", "Rifle Idle", "ShooterLib/idle-rifle", "rifle", ""],
	["Shooter", "Rifle Aim", "ShooterLib/aim-rifle", "rifle", ""],
	["Shooter", "Rifle Shoot", "ShooterLib/shoot-rifle-light>ShooterLib/shoot-rifle-light>ShooterLib/shoot-rifle-light", "rifle", ""],
	["Shooter", "Rifle Reload", "ShooterLib/reload-rifle", "rifle", ""],
	["Shooter", "Pistol Idle", "ShooterLib/idle-pistol", "pistol", ""],
	["Shooter", "Pistol Aim", "ShooterLib/aim-pistol", "pistol", ""],
	["Shooter", "Pistol Shoot", "ShooterLib/shoot-pistol>ShooterLib/shoot-pistol>ShooterLib/shoot-pistol", "pistol", ""],
	["Shooter", "Pistol Reload", "ShooterLib/reload-pistol", "pistol", ""],
	["Shooter", "Throw Grenade", "ShooterLib/throw-grenade-", "grenade", ""],
	["Shooter", "Crouch Run", "ShooterLib/crouch-run", "", ""],
	["Shooter", "Prone", "ShooterLib/prone-idle", "", ""],
	["Shooter", "Hurt", "ShooterLib/hurt1", "", ""],
	["Shooter", "Die", "ShooterLib/die1", "", ""],
	["Fun", "Shrug", "ShooterLib/search-shrug", "", ""],
	["Fun", "Surprised", "ShooterLib/search-surprise>ShooterLib/idle:0.6", "", ""],
	["Fun", "Look Around", "ShooterLib/search-curious", "", ""],
	["Fun", "Hands Up", "ShooterLib/handsup-idle", "", ""],
	["Fun", "Press Button", "ShooterLib/interact-button", "", ""],
	["Fun", "Pick Up", "ShooterLib/pickup_item", "", ""],
	["Fun", "Open Chest", "MeleeLib/OpenChest", "", ""],
	["Fun", "Open Door", "MeleeLib/OpenDoor", "", ""],
	["Fun", "Drink Potion", "MeleeLib/UsePotion", "potion", ""],
	["Fun", "Radio Call", "ShooterLib/radio-standing", "", ""],
	["Fun", "Spawn", "MeleeLib/Spawn", "", ""],
]
const TABS := ["Basic", "Melee", "Shooter", "Fun"]
const PROP_IDLE := {
	"": "ShooterLib/idle", "sword": "MeleeLib/LightIdle", "sword_shield": "MeleeLib/LightIdle",
	"greatsword": "MeleeLib/HeavyIdle", "rifle": "ShooterLib/idle-rifle", "pistol": "ShooterLib/idle-pistol",
	"grenade": "ShooterLib/idle", "potion": "ShooterLib/idle",
}

var character : Node3D
var anim : AnimationPlayer
var skeleton : Skeleton3D
var pivot : Node3D
var camera : Camera3D

var _props := {}          # name -> Node3D (attached to a bone)
var _entry := -1
var _queue : Array = []
var _hold := -1.0
var _step_time := 0.0
var _entry_time := 0.0
var _wait := -1.0
var _speed := 1.0
var _buttons : Array[Button] = []
var _arc_tween : Tween

# camera orbit
var _yaw := 0.35
var _pitch := -0.12
var _dist := 4.4
var _target := Vector3(0, 0.95, 0)
var _cam_pos := Vector3.ZERO

# UI
var _title : Label
var _info : Label
var _auto : CheckButton
var _loop : CheckBox
var _turntable : CheckBox
var _speed_label : Label
var _tabs : TabContainer


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_bgm("bgm_sky")
	_build_world()
	_build_character()
	_build_props()
	_build_ui()
	_play_entry(0)


# ======================================================================= world

func _build_world() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.52, 0.95)
	sky_mat.sky_horizon_color = Color(1, 0.86, 0.76)
	sky_mat.ground_horizon_color = Color(1, 0.86, 0.76)
	sky_mat.ground_bottom_color = Color(0.85, 0.8, 0.9)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(1, 0.88, 0.82)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.4
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.85, 0.55, 0)
	sun.light_color = Color(1, 0.95, 0.85)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

	# floating island stage (same look as the levels)
	var grass := load("res://Assets/Materials/grass.tres")
	var dirt := load("res://Assets/Materials/dirt.tres")
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 3.4
	tm.bottom_radius = 3.4
	tm.height = 0.3
	tm.radial_segments = 28
	tm.material = grass
	top.mesh = tm
	top.position.y = -0.15
	add_child(top)
	var under := MeshInstance3D.new()
	var um := CylinderMesh.new()
	um.top_radius = 3.3
	um.bottom_radius = 1.1
	um.height = 3.2
	um.radial_segments = 14
	um.material = dirt
	under.mesh = um
	under.position.y = -1.9
	add_child(under)
	# a soft spotlight ring under the character
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.95
	rm.bottom_radius = 0.95
	rm.height = 0.02
	rm.radial_segments = 32
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.95, 0.75)
	ring_mat.roughness = 1.0
	rm.material = ring_mat
	ring.mesh = rm
	ring.position.y = 0.005
	add_child(ring)

	var deco := [
		["treeblossom", Vector3(2.3, 0, -1.9), 0.9, 0.4],
		["treeround", Vector3(-2.5, 0, -1.6), 0.85, 1.2],
		["treepine", Vector3(-0.6, 0, -2.9), 0.8, 0.0],
		["mushroom", Vector3(-2.7, 0, 0.9), 0.9, 0.7],
		["rock", Vector3(2.8, 0, -0.2), 0.8, 2.0],
		["flowerpink", Vector3(-2.0, 0, -2.4), 0.9, 0.0],
		["floweryellow", Vector3(-1.2, 0, 2.0), 0.8, 1.0],
		["flowerblue", Vector3(2.5, 0, -1.0), 0.9, 0.5],
		["flowerpink", Vector3(-3.0, 0, -0.4), 0.9, 2.2],
		["floweryellow", Vector3(1.0, 0, -2.6), 0.9, 0.3],
	]
	for d in deco:
		var path := "res://Scenes/Props/%s.tscn" % d[0]
		if ResourceLoader.exists(path):
			var n : Node3D = load(path).instantiate()
			n.position = d[1]
			n.scale = Vector3.ONE * d[2]
			n.rotation.y = d[3]
			add_child(n)
	for d in [[Vector3(-16, -6, -22), 0.9], [Vector3(18, -9, -26), 1.2], [Vector3(-24, -12, 6), 1.0], [Vector3(22, -7, 10), 0.7]]:
		var isl : Node3D = load("res://Scenes/Props/deco_island.tscn").instantiate()
		isl.position = d[0]
		isl.scale = Vector3.ONE * d[1]
		add_child(isl)
	for d in [Vector3(-8, 5, -14), Vector3(9, 7, -18), Vector3(0, 9, -24), Vector3(14, 4, -6)]:
		var cl : Node3D = load("res://Scenes/Props/cloud.tscn").instantiate()
		cl.position = d
		add_child(cl)

	camera = Camera3D.new()
	camera.fov = 45.0
	camera.current = true
	add_child(camera)
	_cam_pos = _orbit_position()
	camera.position = _cam_pos
	camera.look_at(_target)


# ======================================================================= character

func _build_character() -> void:
	pivot = Node3D.new()
	pivot.name = "Pivot"
	pivot.position.y = PIVOT_Y
	add_child(pivot)
	character = load(CHARACTER).instantiate()
	character.position.y = -PIVOT_Y
	pivot.add_child(character)
	anim = character.find_children("*", "AnimationPlayer", true, false)[0]
	skeleton = character.find_children("*", "Skeleton3D", true, false)[0]
	for path in LIBRARIES:
		anim.add_animation_library(path.get_file().get_basename(), load(path))
	anim.animation_finished.connect(_on_anim_finished)


## Attach a prop to a bone. The prop is placed by where it should sit in the T-pose
## (skeleton space), so it does not depend on how the bone axes were rotated on import.
func _attach(prop_name: String, bone: String, node: Node3D, rest_frame: Transform3D) -> void:
	var idx := skeleton.find_bone(bone)
	if idx < 0:
		return
	var att := BoneAttachment3D.new()
	att.name = prop_name.capitalize() + "Attachment"
	att.bone_name = bone
	skeleton.add_child(att)
	node.transform = skeleton.get_bone_global_rest(idx).affine_inverse() * rest_frame
	att.add_child(node)
	node.visible = false
	_props[prop_name] = node


func _build_props() -> void:
	# T-pose: right hand is at -X, palm down, thumb/index side towards +Z.
	var grip := Vector3(-0.70, 1.283, -0.005)
	var blade_frame := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0)), grip)
	var gun_frame := Transform3D(Basis(Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)), grip)
	_attach("sword", "RightHand", _make_sword(1.0), blade_frame)
	_attach("greatsword", "RightHand", _make_sword(1.45), blade_frame)
	_attach("rifle", "RightHand", _make_rifle(), gun_frame)
	_attach("pistol", "RightHand", _make_pistol(), gun_frame)
	_attach("grenade", "RightHand", _make_grenade(), blade_frame)
	_attach("potion", "RightHand", _make_potion(), blade_frame)
	# shield strapped to the left forearm; its face (local +Y) points to -Z in the T-pose,
	# which faces forward in the Guarding / Parry / ShieldBash poses
	var shield_frame := Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(0.54, 1.31, -0.07))
	_attach("shield", "LeftLowerArm", _make_shield(), shield_frame)


func _set_prop(prop: String) -> void:
	for k in _props:
		_props[k].visible = false
	if prop == "sword_shield":
		_props["sword"].visible = true
		_props["shield"].visible = true
	elif _props.has(prop):
		_props[prop].visible = true


# ---------------------------------------------------------------- prop meshes (low-poly)

func _mat(c: Color, metal := 0.0, rough := 0.8, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	m.material = mat
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, rot := Vector3.ZERO, seg := 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bot
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	m.material = mat
	mi.mesh = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


func _ball(parent: Node3D, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 6
	m.material = mat
	mi.mesh = m
	mi.position = pos
	parent.add_child(mi)
	return mi


func _make_sword(s: float) -> Node3D:
	# grip at the origin, blade along +Y, blade width along X
	var n := Node3D.new()
	var steel := _mat(Color(0.86, 0.9, 0.95), 0.7, 0.25)
	var gold := _mat(Color(1.0, 0.78, 0.25), 0.6, 0.35)
	var leather := _mat(Color(0.35, 0.2, 0.16))
	_cyl(n, 0.017, 0.017, 0.13, Vector3(0, -0.005, 0), leather)
	_ball(n, 0.026, Vector3(0, -0.085, 0), gold)
	_box(n, Vector3(0.17 * s, 0.026, 0.04), Vector3(0, 0.07, 0), gold)
	var blade_len := 0.6 * s
	_box(n, Vector3(0.052 * s, blade_len, 0.012), Vector3(0, 0.083 + blade_len * 0.5, 0), steel)
	_box(n, Vector3(0.012, blade_len * 0.8, 0.014), Vector3(0, 0.083 + blade_len * 0.45, 0), _mat(Color(0.55, 0.62, 0.7), 0.7, 0.3))
	var tip := _cyl(n, 0.0, 0.037 * s, 0.09 * s, Vector3(0, 0.083 + blade_len + 0.045 * s, 0), steel, Vector3.ZERO, 4)
	tip.rotation.y = PI / 4
	tip.scale = Vector3(1, 1, 0.24)
	return n


func _make_shield() -> Node3D:
	# round shield, face normal = +Y
	var n := Node3D.new()
	_cyl(n, 0.27, 0.27, 0.03, Vector3.ZERO, _mat(Color(1.0, 0.42, 0.36)), Vector3.ZERO, 18)
	_cyl(n, 0.225, 0.225, 0.045, Vector3(0, 0.005, 0), _mat(Color(0.18, 0.72, 0.74)), Vector3.ZERO, 18)
	_ball(n, 0.06, Vector3(0, 0.03, 0), _mat(Color(1.0, 0.78, 0.25), 0.6, 0.35))
	return n


func _make_rifle() -> Node3D:
	# grip at the origin, top of the gun = +Y, barrel points -Z
	var n := Node3D.new()
	var dark := _mat(Color(0.16, 0.17, 0.2), 0.4, 0.5)
	var wood := _mat(Color(0.55, 0.36, 0.22))
	var teal := _mat(Color(0.18, 0.72, 0.74))
	_box(n, Vector3(0.032, 0.11, 0.05), Vector3(0, -0.03, 0.015), dark, Vector3(-0.25, 0, 0))
	_box(n, Vector3(0.05, 0.085, 0.42), Vector3(0, 0.055, -0.07), dark)
	_box(n, Vector3(0.056, 0.06, 0.2), Vector3(0, 0.05, -0.33), teal)
	_cyl(n, 0.013, 0.013, 0.3, Vector3(0, 0.07, -0.55), dark, Vector3(PI / 2, 0, 0))
	_box(n, Vector3(0.036, 0.13, 0.055), Vector3(0, -0.04, -0.15), dark, Vector3(0.25, 0, 0))
	_box(n, Vector3(0.046, 0.1, 0.25), Vector3(0, 0.03, 0.25), wood, Vector3(0.08, 0, 0))
	_cyl(n, 0.022, 0.022, 0.15, Vector3(0, 0.125, -0.08), dark, Vector3(PI / 2, 0, 0))
	return n


func _make_pistol() -> Node3D:
	var n := Node3D.new()
	var dark := _mat(Color(0.16, 0.17, 0.2), 0.4, 0.5)
	_box(n, Vector3(0.03, 0.1, 0.045), Vector3(0, -0.03, 0.01), dark, Vector3(-0.25, 0, 0))
	_box(n, Vector3(0.034, 0.048, 0.19), Vector3(0, 0.045, -0.045), _mat(Color(0.18, 0.72, 0.74), 0.3, 0.5))
	_cyl(n, 0.009, 0.009, 0.03, Vector3(0, 0.05, -0.15), dark, Vector3(PI / 2, 0, 0))
	return n


func _make_grenade() -> Node3D:
	var n := Node3D.new()
	_ball(n, 0.038, Vector3(0, 0.0, -0.01), _mat(Color(0.35, 0.45, 0.25)))
	_cyl(n, 0.014, 0.014, 0.03, Vector3(0, 0.045, -0.01), _mat(Color(0.7, 0.7, 0.72), 0.6, 0.3))
	return n


func _make_potion() -> Node3D:
	var n := Node3D.new()
	_ball(n, 0.042, Vector3(0, 0.02, -0.01), _mat(Color(1.0, 0.35, 0.6, 1), 0.0, 0.2, 0.6))
	_cyl(n, 0.014, 0.016, 0.05, Vector3(0, 0.08, -0.01), _mat(Color(0.8, 0.95, 1.0), 0.0, 0.1))
	_cyl(n, 0.017, 0.017, 0.02, Vector3(0, 0.11, -0.01), _mat(Color(0.6, 0.4, 0.25)))
	return n


# ======================================================================= playback

func _play_entry(i: int) -> void:
	_entry = clampi(i, 0, ENTRIES.size() - 1)
	var e : Array = ENTRIES[_entry]
	_set_prop(e[3])
	_queue.clear()
	for step in String(e[2]).split(">"):
		var p := step.split(":")
		_queue.append([p[0], float(p[1]) if p.size() > 1 else -1.0])
	_entry_time = 0.0
	_wait = -1.0
	_reset_pivot()
	match e[4]:
		"arc":
			_hop(1.1, false)
			_sfx("jump")
		"flip":
			_hop(1.15, true)
			_sfx("flip")
	_next_step(true)
	_update_labels()
	for b in _buttons:
		b.set_pressed_no_signal(b.get_meta("entry") == _entry)


func _next_step(first := false) -> void:
	if _queue.is_empty():
		_on_entry_done()
		return
	var step : Array = _queue.pop_front()
	_hold = step[1]
	_step_time = 0.0
	if not anim.has_animation(step[0]):
		push_warning("Missing animation " + step[0])
		_next_step()
		return
	if not first and anim.assigned_animation == step[0]:
		anim.stop()  # replay the same clip (e.g. shoot x3)
		anim.play(step[0], 0.0)
	else:
		anim.play(step[0], 0.18)
	_update_labels(step[0])


func _on_anim_finished(_name: StringName) -> void:
	if _wait >= 0.0:
		return
	_next_step()


func _on_entry_done() -> void:
	_wait = 0.7


func _process(delta: float) -> void:
	_entry_time += delta * _speed
	if _hold > 0.0:
		_step_time += delta * _speed
		if _step_time >= _hold:
			_hold = -1.0
			_next_step()
	var looping := _hold < 0.0 and _queue.is_empty() and _wait < 0.0 and anim.current_animation != "" \
		and anim.get_animation(anim.current_animation).loop_mode != Animation.LOOP_NONE
	if _auto and _auto.button_pressed and looping and _entry_time > 3.5:
		_play_entry((_entry + 1) % ENTRIES.size())
	if _wait >= 0.0:
		_wait -= delta
		if _wait < 0.0:
			if _auto and _auto.button_pressed:
				_play_entry((_entry + 1) % ENTRIES.size())
			elif _loop and _loop.button_pressed:
				_play_entry(_entry)
			else:
				var idle : String = PROP_IDLE.get(ENTRIES[_entry][3], "ShooterLib/idle")
				anim.play(idle, 0.35)
				_wait = -1.0
				_hold = -1.0

	# camera
	if _turntable and _turntable.button_pressed:
		_yaw += delta * 0.3
	_cam_pos = _cam_pos.lerp(_orbit_position(), clampf(delta * 10.0, 0.0, 1.0))
	camera.position = _cam_pos
	camera.look_at(_target)


func _hop(height: float, flip: bool) -> void:
	if _arc_tween:
		_arc_tween.kill()
	_arc_tween = create_tween()
	_arc_tween.tween_interval(0.12)
	_arc_tween.tween_property(pivot, "position:y", PIVOT_Y + height, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_arc_tween.tween_property(pivot, "position:y", PIVOT_Y, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if flip:
		var spin := create_tween()
		spin.tween_interval(0.16)
		spin.tween_property(pivot, "rotation:x", TAU, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _reset_pivot() -> void:
	if _arc_tween:
		_arc_tween.kill()
	pivot.position.y = PIVOT_Y
	pivot.rotation = Vector3.ZERO


func _sfx(n: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play(n)


# ======================================================================= camera input

func _orbit_position() -> Vector3:
	return _target + Vector3(sin(_yaw) * cos(_pitch), -sin(_pitch), cos(_yaw) * cos(_pitch)) * _dist


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT)):
		_yaw -= event.relative.x * 0.008
		_pitch = clampf(_pitch - event.relative.y * 0.006, -1.2, 0.35)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = maxf(_dist - 0.35, 1.6)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = minf(_dist + 0.35, 9.0)
	elif event.is_action_pressed("ui_cancel"):
		_back_to_menu()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_play_entry((_entry + 1) % ENTRIES.size())
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_play_entry((_entry - 1 + ENTRIES.size()) % ENTRIES.size())
		elif event.keycode == KEY_SPACE:
			_play_entry(_entry)


func _back_to_menu() -> void:
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").go_to_menu()


# ======================================================================= UI

func _flat(c: Color, radius := 8, margin := 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.6
	sb.content_margin_bottom = margin * 0.6
	return sb


func _make_theme() -> Theme:
	var th := Theme.new()
	th.default_font_size = 16
	th.set_stylebox("panel", "PanelContainer", _flat(Color(0.07, 0.09, 0.2, 0.8), 14, 14.0))
	th.set_stylebox("normal", "Button", _flat(Color(1, 1, 1, 0.1)))
	th.set_stylebox("hover", "Button", _flat(Color(0.18, 0.72, 0.74, 0.55)))
	th.set_stylebox("pressed", "Button", _flat(Color(1.0, 0.42, 0.36, 0.95)))
	th.set_stylebox("hover_pressed", "Button", _flat(Color(1.0, 0.5, 0.42, 1.0)))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		th.set_color(c, "Button", Color.WHITE)
		th.set_color(c, "CheckBox", Color.WHITE)
		th.set_color(c, "CheckButton", Color.WHITE)
	th.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	th.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	th.set_stylebox("panel", "TabContainer", _flat(Color(0, 0, 0, 0.18), 10, 8.0))
	th.set_stylebox("tab_selected", "TabContainer", _flat(Color(0.18, 0.72, 0.74, 0.9), 8, 10.0))
	th.set_stylebox("tab_unselected", "TabContainer", _flat(Color(1, 1, 1, 0.08), 8, 10.0))
	th.set_stylebox("tab_hovered", "TabContainer", _flat(Color(1, 1, 1, 0.2), 8, 10.0))
	th.set_color("font_selected_color", "TabContainer", Color.WHITE)
	th.set_color("font_unselected_color", "TabContainer", Color(0.85, 0.88, 0.95))
	th.set_color("font_hovered_color", "TabContainer", Color.WHITE)
	th.set_color("font_color", "Label", Color.WHITE)
	return th


func _label(text: String, size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _make_theme()
	layer.add_child(root)

	# ---- left panel
	var panel := PanelContainer.new()
	panel.anchor_bottom = 1.0
	panel.offset_left = 16
	panel.offset_top = 16
	panel.offset_right = 366
	panel.offset_bottom = -16
	root.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	vb.add_child(_label("CHARACTER DEMO", 28))
	var sub := _label("Exercise 6  -  our character + Mixamo rig\nMeleeLib & ShooterLib animations", 14, Color(1.0, 0.92, 0.7))
	vb.add_child(sub)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_tabs)
	var group := ButtonGroup.new()
	group.allow_unpress = true
	for tab in TABS:
		var scroll := ScrollContainer.new()
		scroll.name = tab
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_tabs.add_child(scroll)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		scroll.add_child(grid)
		for i in ENTRIES.size():
			if ENTRIES[i][0] != tab:
				continue
			var b := Button.new()
			b.text = ENTRIES[i][1]
			b.toggle_mode = true
			b.button_group = group
			b.focus_mode = Control.FOCUS_NONE
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 34)
			b.set_meta("entry", i)
			b.pressed.connect(_play_entry.bind(i))
			grid.add_child(b)
			_buttons.append(b)

	var row1 := HBoxContainer.new()
	vb.add_child(row1)
	_auto = CheckButton.new()
	_auto.text = "Auto Play"
	_auto.focus_mode = Control.FOCUS_NONE
	row1.add_child(_auto)
	_loop = CheckBox.new()
	_loop.text = "Loop"
	_loop.focus_mode = Control.FOCUS_NONE
	row1.add_child(_loop)
	_turntable = CheckBox.new()
	_turntable.text = "Turntable"
	_turntable.focus_mode = Control.FOCUS_NONE
	row1.add_child(_turntable)

	var row2 := HBoxContainer.new()
	vb.add_child(row2)
	row2.add_child(_label("Speed", 16))
	var slider := HSlider.new()
	slider.min_value = 0.25
	slider.max_value = 2.0
	slider.step = 0.05
	slider.value = 1.0
	slider.focus_mode = Control.FOCUS_NONE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_speed)
	row2.add_child(slider)
	_speed_label = _label("1.00x", 16)
	_speed_label.custom_minimum_size = Vector2(48, 0)
	row2.add_child(_speed_label)

	var back := Button.new()
	back.text = "Back to Menu  (Esc)"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(0, 36)
	back.pressed.connect(_back_to_menu)
	vb.add_child(back)

	# ---- current animation title (top centre of the 3D view)
	var top := VBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.offset_left = 380
	top.offset_top = 18
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(top)
	_title = _label("", 38)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.4, 0.9))
	_title.add_theme_constant_override("outline_size", 12)
	top.add_child(_title)
	_info = _label("", 17, Color(1, 1, 1))
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.4, 0.9))
	_info.add_theme_constant_override("outline_size", 8)
	top.add_child(_info)

	# ---- help + credits (bottom right)
	var help := _label("Drag: rotate camera   Wheel: zoom   A / D: prev / next   Space: replay   Esc: menu", 15)
	help.anchor_left = 0.0
	help.anchor_right = 1.0
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.offset_left = 380
	help.offset_right = -16
	help.offset_top = -54
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.4, 0.9))
	help.add_theme_constant_override("outline_size", 8)
	root.add_child(help)
	var credit := _label("Animations: Godot4-OpenAnimationLibraries (catprisbrey)  |  Bone map: Mixamo BoneMap.tres", 13, Color(1, 1, 1, 0.85))
	credit.anchor_left = 0.0
	credit.anchor_right = 1.0
	credit.anchor_top = 1.0
	credit.anchor_bottom = 1.0
	credit.offset_left = 380
	credit.offset_right = -16
	credit.offset_top = -30
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credit.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.4, 0.9))
	credit.add_theme_constant_override("outline_size", 6)
	root.add_child(credit)


func _on_speed(v: float) -> void:
	_speed = v
	anim.speed_scale = v
	_speed_label.text = "%.2fx" % v


func _update_labels(clip := "") -> void:
	if _title == null or _entry < 0:
		return
	var e : Array = ENTRIES[_entry]
	_title.text = e[1]
	if clip == "":
		clip = String(e[2]).split(">")[0].split(":")[0]
	var lib := clip.get_slice("/", 0)
	var nm := clip.get_slice("/", 1)
	var length := anim.get_animation(clip).length if anim.has_animation(clip) else 0.0
	_info.text = "%s  /  %s   (%.2f s)   [%d / %d]" % [lib, nm, length, _entry + 1, ENTRIES.size()]
	if _tabs:
		_tabs.current_tab = TABS.find(e[0])
