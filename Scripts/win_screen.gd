extends Control
# End screen with run statistics.

var _prompt : Label
var _t := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.25)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	add_child(_label("YOU DID IT!", 110, Color(1.0, 0.88, 0.35), 0.14))
	add_child(_label("Every door opened, every trap beaten.", 32, Color(1, 1, 1), 0.33))

	var t := GameManager.run_time
	var stats := "Time  %02d:%02d\nCoins collected  %d\nHearts lost  %d" % [floori(t / 60.0), int(t) % 60, GameManager.total_collected, GameManager.deaths]
	add_child(_label(stats, 40, Color(0.7, 1.0, 0.9), 0.46))

	_prompt = _label("Press ENTER to go back to the title screen", 34, Color(1, 1, 1), 0.78)
	add_child(_prompt)


func _label(text: String, size: int, color: Color, y_anchor: float) -> Label:
	var l := Label.new()
	l.text = text
	l.anchor_right = 1.0
	l.anchor_top = y_anchor
	l.anchor_bottom = y_anchor
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_t += delta
	_prompt.modulate.a = 0.55 + 0.45 * sin(_t * 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		GameManager.go_to_menu()
