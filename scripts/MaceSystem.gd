extends Node2D

@export var rope_length: float = 60.0
@export var segment_count: int = 5
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
            var velocity = (segment.position - segment.old_position) * 0.9  # Less damping for more responsiveness
            segment.old_position = segment.position
            segment.position += velocity

    # Connect last rope segment to mace with a strong constraint
    var last_rope_index = rope_segments.size() - 1
    var second_last = rope_segments[last_rope_index - 1]
    var segment_length = rope_length / segment_count

    # Calculate where the mace SHOULD be based on rope constraint
    var to_mace = (mace.global_position - second_last.position)
    var current_dist = to_mace.length()

    if current_dist > 0.01:  # Avoid division by zero
        var target_mace_pos = second_last.position + (to_mace.normalized() * segment_length)

        # Apply strong force to pull mace to correct position
        var correction_force = (target_mace_pos - mace.global_position) * 200.0

        # Add damping based on velocity
        var damping = -mace.linear_velocity * 5.0

        # Apply the forces
        mace.apply_force(correction_force + damping)

        # Update the visual end point to match mace
        rope_segments[last_rope_index].position = mace.global_position
    else:
        rope_segments[last_rope_index].position = mace.global_position

    # Constraint solving for rope segments (not including mace)
    var iterations = 6  # More iterations for stiffer rope
    for iteration in range(iterations):
        for i in range(rope_segments.size() - 2):  # Don't constrain the last segment
            var seg1 = rope_segments[i]
            var seg2 = rope_segments[i + 1]

            var distance = seg1.position.distance_to(seg2.position)
            var difference = segment_length - distance

            if abs(difference) > 0.01:  # Tighter tolerance
                var direction = (seg2.position - seg1.position).normalized() if distance > 0 else Vector2.RIGHT
                var offset = direction * difference * 0.5

                if not seg1.pinned:
                    seg1.position -= offset
                if not seg2.pinned:
                    seg2.position += offset

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
