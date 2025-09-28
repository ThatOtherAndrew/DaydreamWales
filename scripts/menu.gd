extends Node

var tween: Tween
var lowpass_filter: AudioEffectLowPassFilter
var fade_overlay: ColorRect

func _ready():
	# Get the lowpass filter from the Soundtrack bus
	var bus_idx = AudioServer.get_bus_index("Soundtrack")
	if bus_idx != -1:
		lowpass_filter = AudioServer.get_bus_effect(bus_idx, 1) as AudioEffectLowPassFilter

	# Create fade overlay
	create_fade_overlay()

func create_fade_overlay():
	# Create a CanvasLayer to ensure the overlay is on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to be on top
	add_child(canvas_layer)

	# Create the black overlay
	fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)  # Start transparent
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fade_overlay)

func _on_button_pressed() -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)  # Make tweens run in parallel

	# Tween the lowpass filter cutoff frequency to max
	if lowpass_filter:
		tween.tween_property(lowpass_filter, "cutoff_hz", 20500.0, 0.4)

	# Fade to black at the same time
	if fade_overlay:
		tween.tween_property(fade_overlay, "color:a", 1.0, 0.4)

	# Wait for tweens to complete before changing scene
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/BrickLevel.tscn")
