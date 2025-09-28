extends Node

var player1_deaths = 0
var player2_deaths = 0
var death_label: Label
var is_resetting = false

signal player_died(player_num: int)
signal level_reset()

func _ready():
    # Create UI overlay for death counter
    create_death_ui()

func create_death_ui():
    var canvas_layer = CanvasLayer.new()
    add_child(canvas_layer)

    death_label = Label.new()
    death_label.add_theme_font_size_override("font_size", 24)
    death_label.position = Vector2(20, 20)
    death_label.text = "Player 1 Deaths: 0 | Player 2 Deaths: 0"
    canvas_layer.add_child(death_label)

func handle_player_death(player_num: int, death_position: Vector2):
    if is_resetting:
        return

    # Update death count
    if player_num == 1:
        player1_deaths += 1
    else:
        player2_deaths += 1

    # Update UI
    death_label.text = "Player 1 Deaths: %d | Player 2 Deaths: %d" % [player1_deaths, player2_deaths]

    # Create explosion at death position
    create_explosion(death_position)

    # Hide the dead player
    emit_signal("player_died", player_num)

    # Wait 2 seconds then reset
    is_resetting = true
    await get_tree().create_timer(2.0).timeout
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
