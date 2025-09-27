extends CharacterBody2D

@export_group("Core Movement")
@export var max_speed: float = 20000.0
@export var acceleration: float = 2000.0
@export var friction: float = 200.0

@export_group("Movement Feel")
@export var turn_boost: float = 1.5
@export var reverse_boost: float = 0.5
@export var momentum_retention: float = 0.2
@export var speed_ramp_curve: float = 0.0
@export var stop_threshold: float = 5.0

@export_group("Advanced Tuning")
@export var input_responsiveness: float = 0.85
@export var velocity_smoothing: float = 0.25
@export var diagonal_compensation: float = 1.0
@export var max_overspeed: float = 1.2
@export var overspeed_decay: float = 0.95

@export_group("Input Actions")
@export var move_up_action: String = "p2_move_up"
@export var move_down_action: String = "p2_move_down"
@export var move_left_action: String = "p2_move_left"
@export var move_right_action: String = "p2_move_right"

@export_group("Sprites")
@export var happy_texture: Texture2D = preload("res://assets/guy/happy.png")
@export var angry_texture: Texture2D = preload("res://assets/guy/angry.png")
@export var sprite_scale: float = 0.2
@export var happy_face_speed_threshold: float = 80.0
@export var rotation_smoothing: float = 0.5
@export var squash_stretch_intensity: float = 20.0
@export var squash_stretch_smoothing: float = 1.0
@export var acceleration_spike_multiplier: float = 15.0
@export var acceleration_spike_duration: float = 0.2

var current_velocity: Vector2 = Vector2.ZERO
var momentum: Vector2 = Vector2.ZERO
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var previous_velocity: Vector2 = Vector2.ZERO
var acceleration_spike_timer: float = 0.0

func _ready():
	_register_input_actions()
	sprite = $Visual/Sprite2D
	collision_shape = $CollisionShape2D
	collision_shape.scale = Vector2(sprite_scale, sprite_scale)

func _register_input_actions():
	if not InputMap.has_action(move_up_action):
		InputMap.add_action(move_up_action)
		var up_event = InputEventKey.new()
		up_event.keycode = KEY_UP
		InputMap.action_add_event(move_up_action, up_event)

	if not InputMap.has_action(move_down_action):
		InputMap.add_action(move_down_action)
		var down_event = InputEventKey.new()
		down_event.keycode = KEY_DOWN
		InputMap.action_add_event(move_down_action, down_event)

	if not InputMap.has_action(move_left_action):
		InputMap.add_action(move_left_action)
		var left_event = InputEventKey.new()
		left_event.keycode = KEY_LEFT
		InputMap.action_add_event(move_left_action, left_event)

	if not InputMap.has_action(move_right_action):
		InputMap.add_action(move_right_action)
		var right_event = InputEventKey.new()
		right_event.keycode = KEY_RIGHT
		InputMap.action_add_event(move_right_action, right_event)

func _physics_process(delta):
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed(move_up_action):
		input_dir.y -= 1
	if Input.is_action_pressed(move_down_action):
		input_dir.y += 1
	if Input.is_action_pressed(move_left_action):
		input_dir.x -= 1
	if Input.is_action_pressed(move_right_action):
		input_dir.x += 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		if input_dir.x != 0 and input_dir.y != 0:
			input_dir *= diagonal_compensation

	if input_dir != Vector2.ZERO:
		var target_velocity = input_dir * max_speed

		var accel = acceleration

		if current_velocity.length() > 0:
			var dot = current_velocity.normalized().dot(input_dir)
			if dot < -0.5:
				accel *= reverse_boost
			elif dot < 0.7:
				accel *= turn_boost

		if speed_ramp_curve > 0:
			var speed_factor = pow(current_velocity.length() / max_speed, speed_ramp_curve)
			accel *= (1.0 + speed_factor * 0.5)

		current_velocity = current_velocity.lerp(target_velocity, min(1.0, accel * delta / max_speed))

		momentum = momentum.lerp(current_velocity * momentum_retention, velocity_smoothing)

		current_velocity = (current_velocity * input_responsiveness + momentum * (1.0 - input_responsiveness))
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, friction * delta)
		momentum = momentum * 0.9

		if current_velocity.length() < stop_threshold:
			current_velocity = Vector2.ZERO
			momentum = Vector2.ZERO

	if current_velocity.length() > max_speed:
		if current_velocity.length() > max_speed * max_overspeed:
			current_velocity = current_velocity.normalized() * max_speed * max_overspeed
		else:
			current_velocity *= overspeed_decay

	velocity = current_velocity
	move_and_slide()

	var is_decelerating = current_velocity.length() < previous_velocity.length()
	var is_slow = current_velocity.length() < happy_face_speed_threshold

	var was_stopped = previous_velocity.length() <= stop_threshold
	var is_moving = current_velocity.length() > stop_threshold

	var direction_change = 0.0
	if previous_velocity.length() > stop_threshold and current_velocity.length() > stop_threshold:
		direction_change = 1.0 - previous_velocity.normalized().dot(current_velocity.normalized())

	if (was_stopped and is_moving) or (direction_change > 0.5):
		acceleration_spike_timer = acceleration_spike_duration

	if is_decelerating and is_slow:
		sprite.texture = happy_texture
	elif current_velocity.length() > stop_threshold:
		sprite.texture = angry_texture

	if current_velocity.length() > stop_threshold:
		var target_rotation = current_velocity.angle() + PI / 2
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation, rotation_smoothing)

	var speed_ratio = clamp(current_velocity.length() / max_speed, 0.0, 1.0)
	var intensity_multiplier = 1.0

	if acceleration_spike_timer > 0:
		var spike_progress = acceleration_spike_timer / acceleration_spike_duration
		intensity_multiplier = 1.0 + (acceleration_spike_multiplier - 1.0) * spike_progress * spike_progress
		acceleration_spike_timer -= delta

	var stretch = 1.0 + (speed_ratio * squash_stretch_intensity * intensity_multiplier)
	var squash = 1.0 - (speed_ratio * squash_stretch_intensity * 0.5 * intensity_multiplier)
	var target_scale = Vector2(squash * sprite_scale, stretch * sprite_scale)
	sprite.scale = sprite.scale.lerp(target_scale, squash_stretch_smoothing)

	previous_velocity = current_velocity