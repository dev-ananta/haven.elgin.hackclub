extends Node2D

# Constants
const FRAME_TIME := 0.12

# Variables
var screen_x := 0.0
var frame_timer := 0.0
var step_frame := 0

@onready var members: Array[Node] = get_children()

# Functions
func reset(x: float) -> void: # Reset Mob Position
	frame_timer = 0.0
	step_frame = 0
	place(x)
	_apply_frames()

func place(x: float) -> void: # Mob Position Logic
	screen_x = x
	position.x = round(x)

func animate(delta: float) -> void: # Running Animation
	frame_timer += delta
	if frame_timer >= FRAME_TIME:
		frame_timer -= FRAME_TIME
		step_frame = 1 - step_frame
		_apply_frames()

func _apply_frames() -> void: # Staggered Legs Per Member
	for i in members.size():
		var member := members[i] as Sprite2D
		member.frame = (i % member.vframes) * member.hframes + (step_frame + i) % member.hframes
