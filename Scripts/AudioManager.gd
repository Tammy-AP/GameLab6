extends Node
# Autoload: plays all sound effects + background music.
# (Same idea as the kit's AudioManager: AudioManager.jump_sfx still works.)

const SFX_NAMES := ["jump", "flip", "coin", "heart", "hurt", "door_open", "win",
		"checkpoint", "spring", "step", "fall", "locked"]

var jump_sfx : AudioStreamPlayer
var _sfx := {}
var _bgm : AudioStreamPlayer
var _bgm_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX_NAMES:
		var p := AudioStreamPlayer.new()
		p.name = n
		p.stream = load("res://Assets/Audio/%s.wav" % n)
		p.max_polyphony = 4
		p.volume_db = -3.0
		add_child(p)
		_sfx[n] = p
	jump_sfx = _sfx["jump"]

	_bgm = AudioStreamPlayer.new()
	_bgm.name = "Music"
	_bgm.volume_db = -11.0
	_bgm.finished.connect(_on_bgm_finished)
	add_child(_bgm)


func play(sfx_name: String, pitch: float = 1.0) -> void:
	if not _sfx.has(sfx_name):
		return
	var p : AudioStreamPlayer = _sfx[sfx_name]
	p.pitch_scale = pitch
	p.play()


func play_bgm(bgm_name: String) -> void:
	if bgm_name == _bgm_name and _bgm.playing:
		return
	_bgm_name = bgm_name
	_bgm.stream = load("res://Assets/Audio/%s.wav" % bgm_name)
	_bgm.play()


func _on_bgm_finished() -> void:
	if _bgm.stream:
		_bgm.play()
