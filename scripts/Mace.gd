extends RigidBody2D

var rope_segments = []
var segment_length = 10.0
var rope_length = 100.0
var player_ref = null

func _ready():
    pass

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
