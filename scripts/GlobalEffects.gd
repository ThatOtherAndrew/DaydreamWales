extends Node

var crt_overlay: ColorRect
var respawn_transition: ColorRect

signal respawn_transition_finished

func _ready():
	# Create CRT effect layer
	var crt_layer = CanvasLayer.new()
	crt_layer.name = "CRTLayer"
	crt_layer.layer = 5  # Middle layer - above game but below UI
	add_child(crt_layer)

	# Create the CRT overlay node
	crt_overlay = ColorRect.new()
	crt_overlay.name = "CRTOverlay"
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	crt_overlay.set_script(load("res://scripts/CRTOverlay.gd"))
	crt_layer.add_child(crt_overlay)

	# Create transition layer
	var transition_layer = CanvasLayer.new()
	transition_layer.name = "TransitionLayer"
	transition_layer.layer = 10  # High layer to be on top
	add_child(transition_layer)

	# Create the respawn transition node
	respawn_transition = ColorRect.new()
	respawn_transition.name = "RespawnTransition"
	respawn_transition.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block mouse input
	respawn_transition.set_script(load("res://scripts/RespawnTransition.gd"))
	transition_layer.add_child(respawn_transition)

	# Connect respawn transition signal
	respawn_transition.transition_finished.connect(_on_respawn_transition_finished)

func play_respawn_transition():
	if respawn_transition:
		respawn_transition.play_respawn_transition()

func set_crt_enabled(enabled: bool):
	if crt_overlay:
		crt_overlay.crt_enabled = enabled
		crt_overlay.update_shader_params()

func set_crt_strength(strength: float):
	if crt_overlay:
		crt_overlay.crt_effect_strength = strength
		crt_overlay.update_shader_params()

func _on_respawn_transition_finished():
	emit_signal("respawn_transition_finished")