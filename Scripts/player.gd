# ----------------------------------------------------------------------------------- #
# 3D PLATFORMER CONTROLLER - based on the "3D Platformer Starter Kit" by SD Studios    #
# (CC0). Extended for Exercise 5: hearts, respawn, springs, custom character swap.     #
# ----------------------------------------------------------------------------------- #

extends CharacterBody3D

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 6.5
@export var jump_force : float = 7.5
@export var follow_lerp_factor : float = 6.0
@export var coyote_time : float = 0.12

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)

var is_grounded := false
var can_double_jump := false
var invulnerable := false
var controls_enabled := true

var _coyote := 0.0
var _flip_time := 0.0
var _invul_time := 0.0

@onready var model = $Model
@onready var spring_arm = %Gimbal
@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

# Same trick as the kit: double gravity for a snappier jump.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


# ---------- FUNCTIONS ---------- #

func _ready() -> void:
	add_to_group("player")
	spring_arm.global_position = global_position


func _physics_process(delta: float) -> void:
	is_grounded = is_on_floor()
	if is_grounded:
		_coyote = coyote_time
		can_double_jump = true
	else:
		_coyote -= delta

	if _invul_time > 0.0:
		_invul_time -= delta
		if _invul_time <= 0.0:
			invulnerable = false

	if controls_enabled:
		_handle_move()
		if Input.is_action_just_pressed("jump"):
			if _coyote > 0.0:
				perform_jump()
			elif can_double_jump:
				perform_flip_jump()
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y -= gravity * delta
	velocity.y = maxf(velocity.y, -45.0)
	move_and_slide()


func _process(delta: float) -> void:
	# Smoothly follow the player's position (camera gimbal is top-level)
	spring_arm.position = spring_arm.position.lerp(global_position, clampf(delta * follow_lerp_factor, 0.0, 1.0))

	# Player rotation
	if is_moving():
		var look_angle := atan2(velocity.x, velocity.z)
		model.rotation.y = lerp_angle(model.rotation.y, look_angle, clampf(delta * 12.0, 0.0, 1.0))

	_update_animation(delta)


func _handle_move() -> void:
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("move_left", "move_right")
	move_direction.z = Input.get_axis("move_forward", "move_back")
	# Move relative to the camera
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed


func is_moving() -> bool:
	return Vector2(velocity.x, velocity.z).length() > 0.1


# ---------- Jumping ---------- #

func perform_jump() -> void:
	_coyote = 0.0
	AudioManager.play("jump", 1.12)
	_jump_tween()
	model.play("Jump", 0.05, 1.0, true)
	velocity.y = jump_force


func perform_flip_jump() -> void:
	can_double_jump = false
	AudioManager.play("flip", 0.9)
	model.play("Flip", 0.0, 1.0, true)
	_flip_time = clampf(model.action_length("Flip", 0.55), 0.2, 0.8)
	velocity.y = jump_force


func launch(force: float) -> void:
	# Called by spring pads.
	velocity.y = force
	can_double_jump = true
	_coyote = 0.0
	_flip_time = 0.0
	model.play("Jump", 0.0, 1.0, true)


func _jump_tween() -> void:
	var tween := create_tween()
	tween.tween_property(model, "scale", jumpStretchSize, 0.1)
	tween.tween_property(model, "scale", Vector3.ONE, 0.1)


# ---------- Animations (names match the original kit: Idle / Run / Jump / Flip) ---------- #

func _update_animation(delta: float) -> void:
	particle_trail.emitting = false
	var running := false

	if _flip_time > 0.0:
		_flip_time -= delta
		if _flip_time <= 0.0:
			model.play("Jump", 0.0)

	if is_on_floor():
		if is_moving():
			model.play("Run", 0.2)
			particle_trail.emitting = true
			running = true
		else:
			model.play("Idle", 0.2)
	elif _flip_time <= 0.0:
		model.play("Jump", 0.1)

	if running:
		if not footsteps.playing:
			footsteps.play()
	else:
		footsteps.stop()


# ---------- Damage / respawn ---------- #

func hurt() -> void:
	# Called by spikes, saws, etc.
	if invulnerable or not controls_enabled:
		return
	_lose_heart_and_respawn()


func fall_out() -> void:
	# Called by the DeadZone below the level.
	if not controls_enabled:
		return
	if invulnerable:
		_respawn()
	else:
		_lose_heart_and_respawn()


func _lose_heart_and_respawn() -> void:
	AudioManager.play("hurt")
	var alive := GameManager.lose_heart()
	if alive:
		_respawn()
		invulnerable = true
		_invul_time = 1.6
		model.blink(1.6)
	else:
		controls_enabled = false
		model.blink(1.4)
		GameManager.game_over()


func _respawn() -> void:
	global_position = GameManager.checkpoint_pos
	velocity = Vector3.ZERO
	spring_arm.global_position = global_position
	_flip_time = 0.0
