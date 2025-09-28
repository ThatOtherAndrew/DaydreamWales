extends Node

var player1_deaths = 0
var player2_deaths = 0
var ui_canvas_layer: CanvasLayer
var is_resetting = false

signal player_died(player_num: int)
signal level_reset()

func _ready():
	# Check if CRT overlay already exists in the scene
	var existing_crt = get_tree().current_scene.get_node_or_null("CRTLayer/CRTOverlay")
	if existing_crt:
		crt_overlay = existing_crt
	else:
		# Create CRT effect overlay if it doesn't exist
		create_crt_overlay()

	# Create UI overlay for death counter
	create_death_ui()
	# Create respawn transition overlay
	create_respawn_transition()

func create_death_ui():
	ui_canvas_layer = CanvasLayer.new()
	ui_canvas_layer.layer = 1  # Above game elements but below effects
	add_child(ui_canvas_layer)

	# Player 1 UI (top-left)
	var p1_container = create_player_death_ui(1, Vector2(20, 20))
	ui_canvas_layer.add_child(p1_container)

	# Player 2 UI (top-right) 
	var p2_container = create_player_death_ui(2, Vector2(-20, 20))
	p2_container.anchors_preset = Control.PRESET_TOP_RIGHT
	p2_container.anchor_left = 1.0
	p2_container.anchor_right = 1.0
	ui_canvas_layer.add_child(p2_container)

func create_player_death_ui(player_num: int, pos: Vector2) -> Label:
	var death_label = Label.new()
	death_label.position = pos
	death_label.text = "0"
	death_label.add_theme_font_size_override("font_size", 32)
	death_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	death_label.add_theme_constant_override("shadow_offset_x", 2)
	death_label.add_theme_constant_override("shadow_offset_y", 2)
	death_label.name = "Player%dDeathUI" % player_num
	
	# Set player colors
	if player_num == 1:
		death_label.add_theme_color_override("font_color", Color.CYAN)
	else:
		death_label.add_theme_color_override("font_color", Color.ORANGE)
	
	return death_label

func update_death_ui():
	if ui_canvas_layer:
		# Update Player 1 death count
		var p1_label = ui_canvas_layer.get_node("Player1DeathUI")
		if p1_label:
			p1_label.text = str(player1_deaths)
		
		# Update Player 2 death count
		var p2_label = ui_canvas_layer.get_node("Player2DeathUI")
		if p2_label:
			p2_label.text = str(player2_deaths)

func create_crt_overlay():
	# Create a new canvas layer for the CRT effect
	var crt_layer = CanvasLayer.new()
	crt_layer.layer = 5  # Middle layer - above game but below UI
	add_child(crt_layer)

	# Create the CRT overlay node
	crt_overlay = ColorRect.new()
	crt_overlay.set_script(load("res://scripts/CRTOverlay.gd"))
	crt_layer.add_child(crt_overlay)

func create_respawn_transition():
	# Create a new canvas layer for the transition effect
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 10  # High layer to be on top
	add_child(transition_layer)

	# Create the respawn transition node
	respawn_transition = ColorRect.new()
	respawn_transition.set_script(load("res://scripts/RespawnTransition.gd"))
	transition_layer.add_child(respawn_transition)

func handle_player_death(player_num: int, death_position: Vector2):
	if is_resetting:
		return

	# Update death count
	if player_num == 1:
		player1_deaths += 1
	else:
		player2_deaths += 1

	# Update UI
	update_death_ui()

	# Create explosion at death position
	create_explosion(death_position)

	# Hide the dead player
	emit_signal("player_died", player_num)

	# Start VHS rewind transition and wait for reset
	is_resetting = true

	# Wait 1.75 seconds, then start the VHS effect for the last 0.25 seconds
	await get_tree().create_timer(1.75).timeout

	await get_tree().create_timer(0.25).timeout
	reset_level()

func create_explosion(pos: Vector2):
	var explosion = GPUParticles2D.new()
	get_tree().current_scene.add_child(explosion)
	explosion.position = pos
	explosion.emitting = true
	explosion.amount = 50
	explosion.lifetime = 1.0
	explosion.one_shot = true
	explosion.speed_scale = 2.0

	# Create process material
	var process_mat = ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0, 0, 0)  # Direction is Vector3 in Godot 4
	process_mat.initial_velocity_min = 100.0
	process_mat.initial_velocity_max = 300.0
	process_mat.angular_velocity_min = -360.0
	process_mat.angular_velocity_max = 360.0
	process_mat.gravity = Vector3(0, 0, 0)  # No gravity for top-down - Vector3 in Godot 4
	process_mat.scale_min = 0.15  # 3x smaller
	process_mat.scale_max = 0.5   # 3x smaller
	process_mat.color = Color(1, 0.5, 0.2, 1)

	# Create and set gradient for color over lifetime
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0, 1))  # Yellow
	gradient.add_point(0.3, Color(1, 0.5, 0, 1))  # Orange
	gradient.add_point(0.6, Color(1, 0, 0, 1))  # Red
	gradient.add_point(1.0, Color(0.5, 0, 0, 0))  # Dark red, transparent

	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	process_mat.color_ramp = gradient_texture

	explosion.process_material = process_mat
	explosion.texture = preload("res://assets/mace.png")  # Use mace texture as particle

	# Clean up after explosion
	await explosion.finished
	explosion.queue_free()

func reset_level():
	emit_signal("level_reset")
	is_resetting = false
