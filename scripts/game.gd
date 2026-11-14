extends Node2D

# Enumerations
enum State { CUTSCENE, RUNNING, DEAD, WON }
enum Kind { CARRIAGE, TRASH_CAN, LAMP_POST }
enum Pace { NORMAL, FAST, SLOW }

# Constants
const MENU_SCENE := "res://scenes/menu.tscn"
const SCREEN_WIDTH := 384.0
const GROUND_Y := 184.0
const PLAYER_X := 72.0
const PLAYER_HALF_WIDTH := 6.0
const MIN_LEAD := 3.0
const HOME_DOOR_X := 64.0

# Constants - Preload
const HOME_SCENE := preload("res://assets/home/homeScene.png")
const TIME_WARP := preload("res://assets/cutscene/timeWarp.png")
const WRONG_PLACE := preload("res://assets/cutscene/wrongPlaceBud.png")
const RUN_BUD := preload("res://assets/cutscene/runBud.png")
const LEVELS := [
	preload("res://assets/levels/alley.png"),
	preload("res://assets/levels/market.png"),
	preload("res://assets/levels/street.png"),
]
const OBSTACLES := {
	Kind.CARRIAGE: {
		"texture": preload("res://assets/obstacles/carriage.png"),
		"hit_left": 6.0,
		"hit_right": 58.0,
		"weight": 0.38,
		"z": 1,
	},
	Kind.TRASH_CAN: {
		"texture": preload("res://assets/obstacles/trash_can.png"),
		"hit_left": 2.0,
		"hit_right": 16.0,
		"weight": 0.42,
		"z": 0,
	},
	Kind.LAMP_POST: {
		"texture": preload("res://assets/obstacles/lampPost.png"),
		"hit_left": 0.0,
		"hit_right": 14.0,
		"weight": 0.2,
		"z": 0,
	},
}

# Variables
class Obstacle:
	# Variables - Class
	var kind := 0
	var node: Sprite2D
	var world_x := 0.0
	var hit_left := 0.0
	var hit_right := 0.0
	var top_height := 0.0
	var checked := false
	var lead_ok := false
	var passed := false
# Variables - To Export
@export var base_speed := 120.0
@export var fast_speed := 165.0
@export var slow_speed := 95.0
@export var speed_change_rate := 80.0
@export var min_gap := 170.0
@export var max_gap := 300.0
@export var goal_distance := 6000.0
@export var home_hold := 1.5
@export var flash_count := 5
@export var flash_time := 0.07
@export var frame_hold := 2.0
@export var run_bud_hold := 1.5
@export var slow_tint := Color(0.62, 0.66, 0.85)
@export var fast_tint := Color(1.0, 0.93, 0.82)

# Variables - Regular
var state := State.CUTSCENE
var pace := Pace.NORMAL
var scroll := 0.0
var speed := 0.0
var target_speed := 0.0
var next_spawn_x := 0.0
var bg_sprites: Array[Sprite2D] = []
var bg_first_x := 0.0
var level_bag: Array[int] = []
var last_level := -1
var obstacles: Array[Obstacle] = []
var tint_tween: Tween

# Variables - Load Up
@onready var backgrounds: Node2D = $World/Backgrounds
@onready var home: Sprite2D = $World/Home
@onready var obstacles_root: Node2D = $World/Obstacles
@onready var player: RunnerPlayer = $World/Player
@onready var tint: CanvasModulate = $Tint
@onready var cutscene: CanvasLayer = $Cutscene
@onready var cutscene_image: TextureRect = $Cutscene/Image
@onready var flash: ColorRect = $Cutscene/Flash
@onready var character: TextureRect = $Cutscene/Character
@onready var overlay: CanvasLayer = $Overlay
@onready var death_popup: TextureRect = $Overlay/DeathPopup
@onready var victory_back: TextureButton = $Overlay/VictoryBack

# Functions
func _ready() -> void: # Initialization
	get_tree().paused = false
	$Overlay/DeathPopup/RestartButton.pressed.connect(_on_restart_pressed)
	$Overlay/DeathPopup/BackButton.pressed.connect(_on_back_pressed)
	victory_back.pressed.connect(_on_back_pressed)
	_hide_overlay()
	_reset_run()
	_play_intro()

func _physics_process(delta: float) -> void: # Newton's Process
	if state != State.RUNNING:
		return
	speed = move_toward(speed, target_speed, speed_change_rate * delta)
	scroll += speed * delta
	player.step(delta, scroll)
	_update_backgrounds()
	_spawn_obstacles()
	_update_obstacles()
	if state == State.RUNNING:
		_update_home()

func _play_intro() -> void: # Intro Sequence
	state = State.CUTSCENE
	cutscene.visible = true
	flash.visible = false
	character.visible = false
	cutscene_image.texture = HOME_SCENE
	await _wait(home_hold)
	character.visible = true
	for _i in flash_count:
		flash.visible = true
		await _wait(flash_time)
		flash.visible = false
		await _wait(flash_time)
	character.visible = false
	cutscene_image.texture = TIME_WARP
	await _wait(frame_hold)
	cutscene_image.texture = WRONG_PLACE
	await _wait(frame_hold)
	await _play_run_bud()

func _play_run_bud() -> void: # Beginning Sequence
	state = State.CUTSCENE
	cutscene.visible = true
	flash.visible = false
	character.visible = false
	cutscene_image.texture = RUN_BUD
	await _wait(run_bud_hold)
	cutscene.visible = false
	state = State.RUNNING

func _wait(seconds: float) -> void: # Cease
	await get_tree().create_timer(seconds).timeout

func _reset_run() -> void: # Reset Run Handler
	for o in obstacles:
		o.node.queue_free()
	obstacles.clear()
	for s in bg_sprites:
		s.queue_free()
	bg_sprites.clear()
	bg_first_x = 0.0
	level_bag.clear()
	last_level = -1
	scroll = 0.0
	speed = base_speed
	target_speed = base_speed
	pace = Pace.NORMAL
	if tint_tween:
		tint_tween.kill()
	tint.color = Color.WHITE
	next_spawn_x = SCREEN_WIDTH + 120.0
	player.reset()
	_update_backgrounds()
	_update_home()

func _next_level_texture() -> Texture2D: # Next Segment Texture Logic
	if level_bag.is_empty():
		level_bag = [0, 1, 2]
		level_bag.shuffle()
		if level_bag[0] == last_level:
			level_bag.push_back(level_bag.pop_front())
	last_level = level_bag.pop_front()
	return LEVELS[last_level]

func _update_backgrounds() -> void: # Update Background
	while not bg_sprites.is_empty() and bg_first_x + SCREEN_WIDTH <= scroll:
		bg_sprites.pop_front().queue_free()
		bg_first_x += SCREEN_WIDTH
	while bg_first_x + bg_sprites.size() * SCREEN_WIDTH < scroll + SCREEN_WIDTH * 2.0:
		var sprite := Sprite2D.new()
		sprite.texture = _next_level_texture()
		sprite.centered = false
		backgrounds.add_child(sprite)
		bg_sprites.append(sprite)
	for i in bg_sprites.size():
		bg_sprites[i].position = Vector2(round(bg_first_x + i * SCREEN_WIDTH - scroll), 0.0)

func _spawn_obstacles() -> void: # Spawn Obstacle
	while next_spawn_x < scroll + SCREEN_WIDTH + 16.0 and next_spawn_x < goal_distance - 200.0:
		var kind := _pick_kind()
		var obstacle := _create_obstacle(kind, next_spawn_x)
		next_spawn_x += obstacle.node.texture.get_width() + randf_range(min_gap, max_gap)

func _pick_kind() -> Kind: # Pick Kind of Obstacle
	var roll := randf()
	var total := 0.0
	for kind: Kind in OBSTACLES:
		total += OBSTACLES[kind]["weight"]
		if roll <= total:
			return kind
	return Kind.TRASH_CAN

func _create_obstacle(kind: Kind, world_x: float) -> Obstacle: # Create Obstacle
	var def: Dictionary = OBSTACLES[kind]
	var texture: Texture2D = def["texture"]
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.z_index = def["z"]
	sprite.position = Vector2(round(world_x - scroll), GROUND_Y - texture.get_height())
	obstacles_root.add_child(sprite)
	var obstacle := Obstacle.new()
	obstacle.kind = kind
	obstacle.node = sprite
	obstacle.world_x = world_x
	obstacle.hit_left = def["hit_left"]
	obstacle.hit_right = def["hit_right"]
	obstacle.top_height = texture.get_height()
	obstacles.append(obstacle)
	return obstacle

func _update_obstacles() -> void: # Update Obstacles
	var front := PLAYER_X + PLAYER_HALF_WIDTH
	var back := PLAYER_X - PLAYER_HALF_WIDTH
	for i in range(obstacles.size() - 1, -1, -1):
		var o := obstacles[i]
		var screen_x := o.world_x - scroll
		o.node.position.x = round(screen_x)
		if screen_x + o.node.texture.get_width() < -16.0:
			o.node.queue_free()
			obstacles.remove_at(i)
			continue
		if o.kind == Kind.LAMP_POST:
			if not o.passed and screen_x + o.hit_right < back:
				o.passed = true
				_switch_pace()
			continue
		var overlapping := screen_x + o.hit_left < front and screen_x + o.hit_right > back
		if not overlapping:
			continue
		if not o.checked:
			o.checked = true
			o.lead_ok = _lead_ok(o, front)
		if not _survives(o):
			_die()
			return

func _lead_ok(o: Obstacle, front: float) -> bool: # Obstacle Survival Minimums
	var obstacle_left := o.world_x + o.hit_left
	match o.kind:
		Kind.CARRIAGE:
			return player.sliding and obstacle_left - (player.slide_start_scroll + front) >= MIN_LEAD
		Kind.TRASH_CAN:
			return not player.is_on_ground() and obstacle_left - (player.jump_start_scroll + front) >= MIN_LEAD
	return true

func _survives(o: Obstacle) -> bool: # Obstacle Survival Logic
	match o.kind:
		Kind.CARRIAGE:
			return o.lead_ok and player.sliding
		Kind.TRASH_CAN:
			return o.lead_ok and player.height >= o.top_height - 0.5
	return true

func _switch_pace() -> void: # Lamp Post Sequence
	if pace == Pace.NORMAL:
		pace = Pace.FAST if randf() < 0.5 else Pace.SLOW
	elif pace == Pace.FAST:
		pace = Pace.SLOW
	else:
		pace = Pace.FAST
	target_speed = fast_speed if pace == Pace.FAST else slow_speed
	if tint_tween:
		tint_tween.kill()
	tint_tween = create_tween()
	tint_tween.tween_property(tint, "color", fast_tint if pace == Pace.FAST else slow_tint, 0.6)

func _update_home() -> void: # Update Home
	var screen_x := goal_distance - scroll
	home.position.x = round(screen_x)
	if state == State.RUNNING and screen_x + HOME_DOOR_X <= PLAYER_X:
		_win()

func _die() -> void: # Death
	state = State.DEAD
	get_tree().paused = true
	overlay.visible = true
	death_popup.visible = true
	victory_back.visible = false

func _win() -> void: # Win
	state = State.WON
	get_tree().paused = true
	overlay.visible = true
	death_popup.visible = false
	victory_back.visible = true

func _hide_overlay() -> void: # Hide Overlay
	overlay.visible = false
	death_popup.visible = false
	victory_back.visible = false

func _on_restart_pressed() -> void: # Restart Game
	_hide_overlay()
	get_tree().paused = false
	_reset_run()
	_play_run_bud()

func _on_back_pressed() -> void: # Back to Menu
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
