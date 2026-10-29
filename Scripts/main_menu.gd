extends Control
# Title screen, built in code.

class Scenery extends Control:
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# sun
		draw_circle(Vector2(w * 0.78, h * 0.3), h * 0.16, Color(1.0, 0.93, 0.6, 0.35))
		draw_circle(Vector2(w * 0.78, h * 0.3), h * 0.11, Color(1.0, 0.95, 0.7))
		# clouds
		for i in 4:
			var cx := fmod(w * (0.1 + 0.27 * i) + _t * (14.0 + 4.0 * i), w + 300.0) - 150.0
			var cy := h * (0.16 + 0.09 * (i % 3))
			for k in 4:
				draw_circle(Vector2(cx + k * 38.0, cy + (k % 2) * -12.0), 34.0 - k * 3.0, Color(1, 1, 1, 0.85))
		# hills
		var far := PackedVector2Array([Vector2(0, h), Vector2(0, h * 0.72), Vector2(w * 0.25, h * 0.62), Vector2(w * 0.5, h * 0.74), Vector2(w * 0.75, h * 0.6), Vector2(w, h * 0.7), Vector2(w, h)])
		draw_colored_polygon(far, Color(0.55, 0.85, 0.5))
		var near := PackedVector2Array([Vector2(0, h), Vector2(0, h * 0.85), Vector2(w * 0.3, h * 0.78), Vector2(w * 0.6, h * 0.88), Vector2(w, h * 0.8), Vector2(w, h)])
		draw_colored_polygon(near, Color(0.35, 0.72, 0.38))

const DEMO_SCENE := "res://Scenes/Demo/character_demo.tscn"

var _prompt : Label
var _t := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_bgm("bgm_sky")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.3, 0.6, 0.98), Color(1.0, 0.82, 0.72)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scenery := Scenery.new()
	scenery.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scenery)

	var title := _label("SKYBOUND BOT", 110, Color(1, 1, 1), 0.16)
	add_child(title)
	var sub := _label("Exercise 6  -  First 3D Character (Mixamo rig + Godot animation libraries)", 30, Color(1.0, 0.95, 0.7), 0.34)
	add_child(sub)
	var demo_btn := Button.new()
	demo_btn.text = "  Character Demo  (C)  "
	demo_btn.focus_mode = Control.FOCUS_NONE
	demo_btn.add_theme_font_size_override("font_size", 26)
	demo_btn.anchor_left = 0.5
	demo_btn.anchor_right = 0.5
	demo_btn.anchor_top = 0.8
	demo_btn.anchor_bottom = 0.8
	demo_btn.offset_left = -170
	demo_btn.offset_right = 170
	demo_btn.offset_bottom = 52
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.42, 0.36)
	sb.set_corner_radius_all(14)
	var sb_hover := sb.duplicate()
	sb_hover.bg_color = Color(1.0, 0.55, 0.45)
	demo_btn.add_theme_stylebox_override("normal", sb)
	demo_btn.add_theme_stylebox_override("hover", sb_hover)
	demo_btn.add_theme_stylebox_override("pressed", sb_hover)
	demo_btn.pressed.connect(_open_demo)
	add_child(demo_btn)
	_prompt = _label("Press ENTER or SPACE to start", 40, Color(1, 1, 1), 0.52)
	add_child(_prompt)
	var help := _label("WASD move  |  SPACE jump (twice for a flip)  |  Q / E camera  |  R restart\nCollect every coin, dodge the traps, then step through the door!", 24, Color(0.1, 0.12, 0.25), 0.64)
	help.add_theme_constant_override("outline_size", 0)
	add_child(help)
	var credit := _label("Based on 3D Platformer Starter Kit by Silver Demon Studios (CC0)", 18, Color(0.1, 0.12, 0.25, 0.85), 0.95)
	credit.add_theme_constant_override("outline_size", 0)
	add_child(credit)


func _label(text: String, size: int, color: Color, y_anchor: float) -> Label:
	var l := Label.new()
	l.text = text
	l.anchor_right = 1.0
	l.anchor_top = y_anchor
	l.anchor_bottom = y_anchor
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.15, 0.4, 0.9))
	l.add_theme_constant_override("outline_size", 14)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_t += delta
	_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		GameManager.start_game()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		get_viewport().set_input_as_handled()
		_open_demo()


func _open_demo() -> void:
	GameManager.change_scene(DEMO_SCENE)
