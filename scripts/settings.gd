extends Node

# Constants
const SAVE_PATH := "user://settings.cfg"

# Variables
var fullscreen := false
var sound := true

# Functions
func _ready() -> void: # Load Saved Settings
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		fullscreen = config.get_value("settings", "fullscreen", false)
		sound = config.get_value("settings", "sound", true)
	_apply_fullscreen()
	_apply_sound()

func set_fullscreen(enabled: bool) -> void: # Fullscreen Handler
	fullscreen = enabled
	_apply_fullscreen()
	_save()

func set_sound(enabled: bool) -> void: # Sound Handler
	sound = enabled
	_apply_sound()
	_save()

func _apply_fullscreen() -> void: # Window Mode Logic
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_sound() -> void: # Mute Logic
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not sound)

func _save() -> void: # Save Settings
	var config := ConfigFile.new()
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "sound", sound)
	config.save(SAVE_PATH)
