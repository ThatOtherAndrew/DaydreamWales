extends CharacterBody2D

@export var move_speed: float = 200.0

@export_group("Input Actions")
@export var move_up_action: String = "move_up"
@export var move_down_action: String = "move_down"
@export var move_left_action: String = "move_left"
@export var move_right_action: String = "move_right"

func _ready():
	_register_input_actions()

func _register_input_actions():
	if not InputMap.has_action(move_up_action):
		InputMap.add_action(move_up_action)
		var up_event = InputEventKey.new()
		up_event.keycode = KEY_W
		InputMap.action_add_event(move_up_action, up_event)

	if not InputMap.has_action(move_down_action):
		InputMap.add_action(move_down_action)
		var down_event = InputEventKey.new()
		down_event.keycode = KEY_S
		InputMap.action_add_event(move_down_action, down_event)

	if not InputMap.has_action(move_left_action):
		InputMap.add_action(move_left_action)
		var left_event = InputEventKey.new()
		left_event.keycode = KEY_A
		InputMap.action_add_event(move_left_action, left_event)

	if not InputMap.has_action(move_right_action):
		InputMap.add_action(move_right_action)
		var right_event = InputEventKey.new()
		right_event.keycode = KEY_D
		InputMap.action_add_event(move_right_action, right_event)

func _physics_process(_delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed(move_up_action):
		input_vector.y -= 1
	if Input.is_action_pressed(move_down_action):
		input_vector.y += 1
	if Input.is_action_pressed(move_left_action):
		input_vector.x -= 1
	if Input.is_action_pressed(move_right_action):
		input_vector.x += 1

	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()