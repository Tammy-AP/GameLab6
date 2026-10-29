extends Node3D
# Goal door. Locked (red) until every coin is collected, then glows and loads the next level.

var _open := false
var _used := false
var _t := 0.0
var _mat : StandardMaterial3D

@onready var portal : MeshInstance3D = $Portal
@onready var orbit : Node3D = $Orbit
@onready var light : OmniLight3D = $Light
@onready var trigger : Area3D = $Trigger


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(0.85, 0.12, 0.2, 0.55)
	portal.material_override = _mat
	trigger.body_entered.connect(_on_body_entered)
	GameManager.all_coins_collected.connect(_open_door)


func _open_door() -> void:
	_open = true
	light.light_energy = 3.0
	light.light_color = Color(0.4, 1.0, 0.85)


func _process(delta: float) -> void:
	_t += delta
	if _open:
		orbit.rotate_z(delta * 2.6)
		var c := Color(0.3, 1.0, 0.8).lerp(Color(1.0, 0.95, 0.5), 0.5 + 0.5 * sin(_t * 3.0))
		c.a = 0.85
		_mat.albedo_color = c
	else:
		orbit.rotate_z(delta * 0.5)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _used:
		return
	if _open:
		_used = true
		body.controls_enabled = false
		GameManager.complete_level()
	else:
		AudioManager.play("locked")
		var left := GameManager.total_coins - GameManager.coins
		GameManager.toast.emit("The door is locked - %d coin(s) left!" % left)
