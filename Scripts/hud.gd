extends CanvasLayer
# In-game HUD, built entirely in code: coins, hearts, timer, toast messages, controls hint.

class IconRow extends Control:
	var kind := "heart"
	var count := 3
	var max_count := 3
	var icon_size := 36.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_values(c: int, m: int) -> void:
		count = c
		max_count = m
		custom_minimum_size = Vector2((icon_size + 8.0) * m, icon_size + 4.0)
		queue_redraw()

	func _draw() -> void:
		for i in max_count:
			var center := Vector2(icon_size * 0.5 + i * (icon_size + 8.0), icon_size * 0.5 + 2.0)
			if kind == "heart":
				_draw_heart(center, i < count)
			else:
				_draw_coin(center)

	func _draw_heart(center: Vector2, full: bool) -> void:
		var pts := PackedVector2Array()
		var n := 28
		for k in n:
			var t := TAU * float(k) / float(n)
			var x := 16.0 * pow(sin(t), 3.0)
			var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
			pts.append(center + Vector2(x, y + 1.0) * (icon_size / 38.0))
		var col := Color(1.0, 0.25, 0.38) if full else Color(0.15, 0.15, 0.2, 0.6)
		draw_colored_polygon(pts, col)
		pts.append(pts[0])
		var line_col := Color(1, 1, 1, 0.95) if full else Color(1, 1, 1, 0.3)
		draw_polyline(pts, line_col, 2.0)

	func _draw_coin(center: Vector2) -> void:
		draw_circle(center, icon_size * 0.5, Color(1.0, 0.78, 0.15))
		draw_arc(center, icon_size * 0.5, 0.0, TAU, 24, Color(0.75, 0.45, 0.05), 3.0)
		draw_circle(center, icon_size * 0.28, Color(1.0, 0.9, 0.45))


var _coin_label : Label
var _hearts : IconRow
var _time_label : Label
var _toast : Label
var _title : Label
var _subtitle : Label
var _toast_tween : Tween


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- top-left: coins + hearts
	var box := VBoxContainer.new()
	box.position = Vector2(26, 20)
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)

	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 12)
	coin_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(coin_row)
	var coin_icon := IconRow.new()
	coin_icon.kind = "coin"
	coin_icon.set_values(1, 1)
	coin_row.add_child(coin_icon)
	_coin_label = Label.new()
	_style(_coin_label, 34, Color(1.0, 0.86, 0.3))
	coin_row.add_child(_coin_label)

	_hearts = IconRow.new()
	_hearts.kind = "heart"
	box.add_child(_hearts)

	# --- top-right: timer
	_time_label = Label.new()
	_time_label.anchor_left = 1.0
	_time_label.anchor_right = 1.0
	_time_label.offset_left = -260.0
	_time_label.offset_right = -26.0
	_time_label.offset_top = 20.0
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_style(_time_label, 30, Color(1, 1, 1))
	root.add_child(_time_label)

	# --- centre: level title + toast
	_title = Label.new()
	_title.anchor_right = 1.0
	_title.offset_top = 90.0
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(_title, 72, Color(1, 1, 1))
	_title.modulate.a = 0.0
	root.add_child(_title)

	_subtitle = Label.new()
	_subtitle.anchor_right = 1.0
	_subtitle.offset_top = 180.0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(_subtitle, 30, Color(1.0, 0.9, 0.6))
	_subtitle.modulate.a = 0.0
	root.add_child(_subtitle)

	_toast = Label.new()
	_toast.anchor_right = 1.0
	_toast.anchor_top = 0.72
	_toast.anchor_bottom = 0.72
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(_toast, 34, Color(1.0, 0.95, 0.7))
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	# --- bottom: controls hint
	var hint := Label.new()
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 26.0
	hint.offset_top = -44.0
	hint.text = "WASD move   SPACE jump (press again in the air!)   Q/E or mouse: camera   R restart   ESC mouse"
	_style(hint, 18, Color(1, 1, 1, 0.8))
	root.add_child(hint)

	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	GameManager.toast.connect(show_toast)
	_on_coins_changed(GameManager.coins, GameManager.total_coins)
	_on_hearts_changed(GameManager.hearts)


func _process(_delta: float) -> void:
	var t := GameManager.run_time
	_time_label.text = "%02d:%02d" % [floori(t / 60.0), int(t) % 60]


func _style(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1, 0.9))
	label.add_theme_constant_override("outline_size", 9)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_coins_changed(collected: int, total: int) -> void:
	_coin_label.text = "%d / %d" % [collected, total]


func _on_hearts_changed(hearts: int) -> void:
	_hearts.set_values(hearts, GameManager.MAX_HEARTS)


func show_toast(message: String) -> void:
	_toast.text = message
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func show_title(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_title, "modulate:a", 1.0, 0.5)
	tw.tween_property(_subtitle, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tw.chain().tween_interval(2.4)
	tw.chain().set_parallel(true)
	tw.tween_property(_title, "modulate:a", 0.0, 0.8)
	tw.tween_property(_subtitle, "modulate:a", 0.0, 0.8)
