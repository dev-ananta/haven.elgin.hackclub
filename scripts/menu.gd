extends Control

# Constants
const GAME_SCENE := "res://scenes/game.tscn"

# Variables
@onready var title_logo: TextureRect = $TitleLogo
@onready var main_buttons: VBoxContainer = $MainButtons
@onready var settings_view: Control = $SettingsView
@onready var credits_view: Control = $CreditsView
@onready var fullscreen_toggle: TextureButton = $SettingsView/Panel/Scroll/Content/FullscreenRow/FullscreenToggle

# Functions
func _ready() -> void:
	get_tree().paused = false
	$MainButtons/PlayButton.pressed.connect(_on_play_pressed)
	$MainButtons/SettingsButton.pressed.connect(_show_view.bind(settings_view))
	$MainButtons/CreditsButton.pressed.connect(_show_view.bind(credits_view))
	$SettingsView/BackButton.pressed.connect(_show_main)
	$CreditsView/BackButton.pressed.connect(_show_main)
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_show_main()

func _show_main() -> void: # Menu
	title_logo.visible = true
	main_buttons.visible = true
	settings_view.visible = false
	credits_view.visible = false

func _show_view(view: Control) -> void: # Settings + Credits Handler
	title_logo.visible = false
	main_buttons.visible = false
	settings_view.visible = view == settings_view
	credits_view.visible = view == credits_view
	var scroll: ScrollContainer = view.get_node("Panel/Scroll")
	scroll.scroll_vertical = 0

func _on_play_pressed() -> void: # Play Game
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_fullscreen_toggled(enabled: bool) -> void: # Fullscreen Handler
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
