extends AudioStreamPlayer

var game_manager: Node
var tween: Tween
var normal_pitch = 1.0
var slow_pitch = 0.5
var tape_stop_duration = 0.5
var reverb_effect: AudioEffectReverb
var max_wet = 0.7

func _ready():
    # Add to group for easy access
    add_to_group("soundtrack_player")

    game_manager = get_node("/root/BrickLevel/GameManager")
    if game_manager:
        game_manager.player_died.connect(_on_player_died)
        game_manager.level_reset.connect(_on_level_reset)

    pitch_scale = normal_pitch

    var bus_idx = AudioServer.get_bus_index("Soundtrack")
    if bus_idx != -1:
        reverb_effect = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectReverb
        if reverb_effect:
            reverb_effect.wet = 0.0

func _on_player_died(_player_num: int):
    if tween:
        tween.kill()

    tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_parallel(true)
    tween.tween_property(self, "pitch_scale", slow_pitch, tape_stop_duration)
    if reverb_effect:
        tween.tween_property(reverb_effect, "wet", max_wet, tape_stop_duration)

func _on_level_reset():
    if tween:
        tween.kill()

    pitch_scale = normal_pitch
    if reverb_effect:
        reverb_effect.wet = 0.0
