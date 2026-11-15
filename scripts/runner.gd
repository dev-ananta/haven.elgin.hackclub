extends Node2D

# Constants
const GRAVITY := 700.0
const FAST_FALL_GRAVITY := 1800.0
const JUMP_VELOCITY := 240.0
const STAND_SCALE := Vector2(1.0, 1.0)
const SLIDE_SCALE := Vector2(1.4, 0.4)

# Variables
var height := 0.0
var velocity_y := 0.0
var sliding := false
var jump_start_scroll := 0.0
var slide_start_scroll := 0.0
var ground_y := 0.0
var base_scale := Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D

# Functions
func _ready() -> void: # Initiaion Logic
	ground_y = position.y
	base_scale = sprite.scale

func reset() -> void: # Reset Position of MC Logic
	height = 0.0
	velocity_y = 0.0
	sliding = false
	jump_start_scroll = 0.0
	slide_start_scroll = 0.0
	_apply_pose()

func is_on_ground() -> bool: # MC Location Status Check
	return height <= 0.0

func step(delta: float, scroll: float) -> void: # Movement Logic
	var slide_held := Input.is_action_pressed("slide")

	if is_on_ground() and Input.is_action_just_pressed("jump"): # Jump Logic
		sliding = false
		velocity_y = JUMP_VELOCITY
		height = 0.01
		jump_start_scroll = scroll

	if not is_on_ground(): # "Landing Gears" Logic
		var gravity := FAST_FALL_GRAVITY if slide_held else GRAVITY
		velocity_y -= gravity * delta
		height += velocity_y * delta
		if height <= 0.0:
			height = 0.0
			velocity_y = 0.0

	if is_on_ground() and slide_held: # Slide Logic
		if not sliding:
			sliding = true
			slide_start_scroll = scroll
	else:
		sliding = false

	_apply_pose()

func _apply_pose() -> void: # Standard MC <-> Sliding MC
	position.y = round(ground_y - height)
	sprite.scale = base_scale * (SLIDE_SCALE if sliding else STAND_SCALE)
