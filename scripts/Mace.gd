extends RigidBody2D

var rope_segments = []
var segment_length = 10.0
var rope_length = 100.0
var player_ref = null
var owner_player_num = 1  # Which player owns this mace
var spawn_protection_time = 1.0  # 1 second of spawn protection
var can_damage = false

func _ready():
    # Enable collision detection
    set_contact_monitor(true)
    set_max_contacts_reported(10)
    body_entered.connect(_on_body_entered)
    print("Mace ready, collision monitoring enabled")

    # Enable damage after spawn protection period
    await get_tree().create_timer(spawn_protection_time).timeout
    can_damage = true
    print("Mace damage enabled for player ", owner_player_num)

func set_owner_player(player_num: int):
    owner_player_num = player_num
    # Set collision mask to detect opposite player
    if player_num == 1:
        collision_mask = 1 | 4  # Walls (1) + Player 2 (4) = 5
        print("Player 1's mace set to detect layers: ", collision_mask)
    else:
        collision_mask = 1 | 2  # Walls (1) + Player 1 (2) = 3
        print("Player 2's mace set to detect layers: ", collision_mask)

func _on_body_entered(body):
    if not can_damage:
        print("Mace collision ignored - spawn protection active")
        return

    print("Mace collision detected with: ", body.name, " (owner: ", owner_player_num, ")")
    print("Body is on layer: ", body.collision_layer if body.has_method("get_collision_layer") else "unknown")

    # Check if we hit the opposite player
    if body.name == "Player" and owner_player_num == 2:
        print("Player 2's mace hit Player 1!")
        # Player 2's mace hit Player 1
        var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
        if game_manager:
            game_manager.handle_player_death(1, body.global_position)
        else:
            print("GameManager not found!")
    elif body.name == "Player2" and owner_player_num == 1:
        print("Player 1's mace hit Player 2!")
        # Player 1's mace hit Player 2
        var game_manager = get_tree().current_scene.get_node_or_null("GameManager")
        if game_manager:
            game_manager.handle_player_death(2, body.global_position)
        else:
            print("GameManager not found!")

func setup_rope(player):
    player_ref = player
    var num_segments = int(rope_length / segment_length)

    for i in range(num_segments):
        var segment = RigidBody2D.new()
        segment.gravity_scale = 0.0
        segment.linear_damp = 1.0
        segment.mass = 0.1

        var collision = CollisionShape2D.new()
        var shape = CircleShape2D.new()
        shape.radius = 2
        collision.shape = shape
        collision.disabled = true  # Disable collision for rope segments
        segment.add_child(collision)

        get_parent().add_child(segment)
        rope_segments.append(segment)

        if i == 0:
            # Connect first segment to player
            segment.global_position = player.global_position
            var joint = PinJoint2D.new()
            joint.node_a = player.get_path()
            joint.node_b = segment.get_path()
            get_parent().add_child(joint)
        else:
            # Connect to previous segment
            segment.global_position = rope_segments[i-1].global_position + Vector2(0, segment_length)
            var joint = PinJoint2D.new()
            joint.node_a = rope_segments[i-1].get_path()
            joint.node_b = segment.get_path()
            get_parent().add_child(joint)

    # Connect mace to last segment
    if rope_segments.size() > 0:
        global_position = rope_segments[-1].global_position + Vector2(0, segment_length)
        var joint = PinJoint2D.new()
        joint.node_a = rope_segments[-1].get_path()
        joint.node_b = get_path()
        get_parent().add_child(joint)

func get_rope_points():
    var points = PackedVector2Array()
    if player_ref:
        points.append(player_ref.global_position)
    for segment in rope_segments:
        points.append(segment.global_position)
    points.append(global_position)
    return points
