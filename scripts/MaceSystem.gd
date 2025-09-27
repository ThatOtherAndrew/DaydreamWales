extends Node2D

@export var rope_length: float = 60.0
@export var segment_count: int = 8
@export var rope_stiffness: float = 50.0
@export var rope_damping: float = 10.0

var player_ref = null
var mace = null
var rope_line = null
var rope_segments = []

class RopeSegment:
    var position: Vector2
    var old_position: Vector2
    var pinned: bool = false

    func _init(pos: Vector2):
        position = pos
        old_position = pos

func _ready():
    mace = $Mace
    rope_line = $RopeLine

    # Wait for parent to be ready
    await get_parent().ready
    player_ref = get_parent()

    initialize_rope()

func initialize_rope():
    rope_segments.clear()

    var segment_length = rope_length / segment_count
    var start_pos = player_ref.global_position if player_ref else global_position

    # Initialize rope horizontally to the right to prevent bobbing
    for i in range(segment_count + 1):
        var pos = start_pos + Vector2(segment_length * i, 0)
        var segment = RopeSegment.new(pos)
        if i == 0:
            segment.pinned = true  # Pin first segment to player
        rope_segments.append(segment)

    # Set mace position to end of rope
    if mace:
        mace.global_position = rope_segments[-1].position
        mace.linear_velocity = Vector2.ZERO  # Start at rest

func _physics_process(delta):
    if not player_ref or not mace:
        return

    # Update first segment to player position
    rope_segments[0].position = player_ref.global_position

    # Apply Verlet integration for middle segments only
    for i in range(1, rope_segments.size() - 1):  # Don't update last segment here
        var segment = rope_segments[i]
        if not segment.pinned:
            # Less damping for more energy preservation and responsiveness
            var velocity = (segment.position - segment.old_position) * 0.995
            segment.old_position = segment.position
            segment.position += velocity

    # Simple distance constraint for mace - no complex velocity manipulation
    var last_rope_index = rope_segments.size() - 1
    var second_last = rope_segments[last_rope_index - 1]
    var segment_length = rope_length / segment_count

    # Calculate distance to mace
    var to_mace = (mace.global_position - second_last.position)
    var current_dist = to_mace.length()

    # Only pull if stretched beyond the segment length
    if current_dist > segment_length:
        var excess = current_dist - segment_length
        var pull_direction = (second_last.position - mace.global_position).normalized()

        # Stronger force for more responsiveness, but still proportional
        var pull_force = pull_direction * excess * 1500.0

        # Very light damping only when needed
        var velocity_along_rope = mace.linear_velocity.dot(pull_direction)
        var damping = Vector2.ZERO
        if velocity_along_rope < -100:  # Only damp if moving away very fast
            damping = pull_direction * velocity_along_rope * 0.5

        mace.apply_force(pull_force + damping)

    # Always update visual endpoint to match mace
    rope_segments[last_rope_index].position = mace.global_position

    # Simple distance constraints - only prevent stretching, allow compression
    var expected_length = rope_length / segment_count

    # More iterations for tighter rope
    for iteration in range(4):
        # Constrain each pair of segments
        for i in range(rope_segments.size() - 1):
            var seg1 = rope_segments[i]
            var seg2 = rope_segments[i + 1]

            var offset = seg2.position - seg1.position
            var distance = offset.length()

            # Only constrain if stretched (not compressed)
            if distance > expected_length * 1.01:  # Small tolerance
                var correction = offset.normalized() * (distance - expected_length) * 0.8  # Stronger correction

                if not seg1.pinned:
                    seg1.position += correction
                if not seg2.pinned:
                    seg2.position -= correction

    update_rope_visual()

func update_rope_visual():
    var points = PackedVector2Array()
    for segment in rope_segments:
        points.append(to_local(segment.position))
    rope_line.points = points

func _process(_delta):
    # Ensure rope visual stays updated
    if rope_line and rope_segments.size() > 0:
        update_rope_visual()
