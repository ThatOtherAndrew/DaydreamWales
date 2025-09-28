extends ColorRect

var vhs_material: ShaderMaterial
var transition_active: bool = false
var white_flash_overlay: ColorRect

signal transition_finished

func _ready():
    # Create and setup the VHS shader material
    vhs_material = ShaderMaterial.new()
    vhs_material.shader = load("res://shaders/vhs_rewind.gdshader")

    # Set initial shader parameters (effect off)
    vhs_material.set_shader_parameter("strength", 0.0)
    vhs_material.set_shader_parameter("time_scale", 3.0)
    vhs_material.set_shader_parameter("distortion_amount", 0.15)
    vhs_material.set_shader_parameter("noise_amount", 0.4)
    vhs_material.set_shader_parameter("scanline_intensity", 0.6)
    vhs_material.set_shader_parameter("chromatic_aberration", 0.03)
    vhs_material.set_shader_parameter("tracking_offset", 0.0)

    # Apply material to this ColorRect
    material = vhs_material

    # Make sure it covers the entire screen
    anchor_left = 0
    anchor_top = 0
    anchor_right = 1
    anchor_bottom = 1

    # Start transparent
    color = Color(1, 1, 1, 0)

    # Make sure we're on top
    z_index = 100

    # Create white flash overlay
    white_flash_overlay = ColorRect.new()
    white_flash_overlay.anchor_left = 0
    white_flash_overlay.anchor_top = 0
    white_flash_overlay.anchor_right = 1
    white_flash_overlay.anchor_bottom = 1
    white_flash_overlay.color = Color(1, 1, 1, 0)  # Start transparent white
    white_flash_overlay.z_index = 101  # Above the VHS effect
    add_child(white_flash_overlay)

func play_respawn_transition(duration: float = 0.25):
    if transition_active:
        return

    transition_active = true

    # Adjusted timing for 0.25 second total duration (half of original)
    var tween = get_tree().create_tween()
    tween.set_parallel(false)

    # Phase 1: Quickly ramp up the VHS effect (0.05 seconds)
    tween.tween_method(_update_effect_strength, 0.0, 1.0, 0.05)

    # Phase 2: Hold the intense effect with fluctuations (0.1 seconds)
    tween.tween_callback(_fluctuate_effect).set_delay(0.0)
    tween.tween_interval(0.1)

    # Start white flash before VHS ends (overlapping last 0.1 seconds)
    tween.tween_callback(_play_white_flash)

    # Phase 3: Continue VHS fade out while flash is playing
    tween.tween_method(_update_effect_strength, 1.0, 0.0, 0.1)

    # Cleanup
    tween.tween_callback(_on_transition_complete)

func _update_effect_strength(value: float):
    vhs_material.set_shader_parameter("strength", value)

    # Also adjust tracking offset for more dramatic effect
    var tracking = sin(Time.get_ticks_msec() * 0.01) * 0.2 * value
    vhs_material.set_shader_parameter("tracking_offset", tracking)

    # Slight color tint during transition
    color = Color(1, 1, 1, value * 0.3)

func _fluctuate_effect():
    if not transition_active:
        return

    # Create random fluctuations in the effect
    var fluctuation_tween = get_tree().create_tween()
    fluctuation_tween.set_loops(2)  # Even fewer loops for shorter 0.25s duration

    # Random distortion spikes with shorter delays
    fluctuation_tween.tween_callback(func():
        if transition_active:
            var spike = randf_range(0.1, 0.3)
            vhs_material.set_shader_parameter("distortion_amount", spike)
            vhs_material.set_shader_parameter("tracking_offset", randf_range(-0.3, 0.3))
    ).set_delay(0.05)  # Faster fluctuations

func _on_transition_complete():
    transition_active = false
    vhs_material.set_shader_parameter("strength", 0.0)
    vhs_material.set_shader_parameter("tracking_offset", 0.0)
    color = Color(1, 1, 1, 0)
    emit_signal("transition_finished")

func _play_white_flash():
    # Longer white flash effect that overlaps with VHS ending
    var flash_tween = get_tree().create_tween()

    # Flash to white quickly
    flash_tween.tween_property(white_flash_overlay, "color:a", 0.8, 0.08)

    # Hold the flash briefly
    flash_tween.tween_interval(0.05)

    # Fade out the white flash more slowly
    flash_tween.tween_property(white_flash_overlay, "color:a", 0.0, 0.25)