@tool
extends ColorRect

@export_group("Screen Curvature")
@export_range(0.0, 0.5) var curvature_x: float = 0.1
@export_range(0.0, 0.5) var curvature_y: float = 0.1

@export_group("Scanlines")
@export_range(0.0, 1.0) var scanline_intensity: float = 0.4
@export_range(100.0, 1000.0) var scanline_frequency: float = 400.0
@export_range(0.0, 10.0) var scanline_speed: float = 1.0

@export_group("Vignette")
@export_range(0.0, 1.0) var vignette_intensity: float = 0.3
@export_range(0.1, 2.0) var vignette_smoothness: float = 0.5

@export_group("Chromatic Aberration")
@export_range(0.0, 0.01) var aberration_amount: float = 0.003

@export_group("Phosphor Glow")
@export_range(0.0, 1.0) var glow_intensity: float = 0.1
@export var phosphor_color: Color = Color(1.0, 1.0, 0.95)

@export_group("Noise and Flicker")
@export_range(0.0, 0.5) var noise_intensity: float = 0.05
@export_range(0.0, 0.2) var flicker_intensity: float = 0.02
@export_range(0.1, 20.0) var flicker_speed: float = 10.0

@export_group("Screen Adjustments")
@export_range(0.5, 1.5) var brightness: float = 1.0
@export_range(0.5, 2.0) var contrast: float = 1.1
@export_range(0.0, 2.0) var saturation: float = 0.95

@export_group("Pixel Grid")
@export_range(0.0, 1.0) var pixel_grid_intensity: float = 0.1
@export var pixel_grid_size: Vector2 = Vector2(640, 480)

@export_group("Master Controls")
@export var crt_enabled: bool = true
@export_range(0.0, 1.0) var crt_effect_strength: float = 1.0

var crt_material: ShaderMaterial

func _ready():
    setup_crt_effect()
    update_shader_params()

func setup_crt_effect():
    # Create and setup the CRT shader material
    crt_material = ShaderMaterial.new()
    crt_material.shader = load("res://shaders/crt_monitor.gdshader")

    # Apply material to this ColorRect
    material = crt_material

    # Make sure it covers the entire screen
    anchor_left = 0
    anchor_top = 0
    anchor_right = 1
    anchor_bottom = 1

    # Set proper color
    color = Color.WHITE

    # Ensure we're on top but below UI
    z_index = 50

func update_shader_params():
    if not crt_material:
        return

    var strength = crt_effect_strength if crt_enabled else 0.0

    # Apply all parameters with strength modifier
    crt_material.set_shader_parameter("curvature_x", curvature_x * strength)
    crt_material.set_shader_parameter("curvature_y", curvature_y * strength)
    crt_material.set_shader_parameter("scanline_intensity", scanline_intensity * strength)
    crt_material.set_shader_parameter("scanline_frequency", scanline_frequency)
    crt_material.set_shader_parameter("scanline_speed", scanline_speed)
    crt_material.set_shader_parameter("vignette_intensity", vignette_intensity * strength)
    crt_material.set_shader_parameter("vignette_smoothness", vignette_smoothness)
    crt_material.set_shader_parameter("aberration_amount", aberration_amount * strength)
    crt_material.set_shader_parameter("glow_intensity", glow_intensity * strength)
    crt_material.set_shader_parameter("phosphor_color", phosphor_color)
    crt_material.set_shader_parameter("noise_intensity", noise_intensity * strength)
    crt_material.set_shader_parameter("flicker_intensity", flicker_intensity * strength)
    crt_material.set_shader_parameter("flicker_speed", flicker_speed)

    # These affect overall look, so we handle them differently
    var adjusted_brightness = lerp(1.0, brightness, strength)
    var adjusted_contrast = lerp(1.0, contrast, strength)
    var adjusted_saturation = lerp(1.0, saturation, strength)

    crt_material.set_shader_parameter("brightness", adjusted_brightness)
    crt_material.set_shader_parameter("contrast", adjusted_contrast)
    crt_material.set_shader_parameter("saturation", adjusted_saturation)

    crt_material.set_shader_parameter("pixel_grid_intensity", pixel_grid_intensity * strength)
    crt_material.set_shader_parameter("pixel_grid_size", pixel_grid_size)

# Update in editor
func _validate_property(_property):
    if Engine.is_editor_hint():
        update_shader_params()

func _set(_property, _value):
    if Engine.is_editor_hint():
        call_deferred("update_shader_params")
    return false
