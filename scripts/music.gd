extends Node

# Constants
const TRACK_PATH := "res://assets/audio/music.ogg"
const VOLUME_DB := -8.0

# Variables
var player: AudioStreamPlayer

# Functions
func _ready() -> void: # Start Looping Music
	process_mode = Node.PROCESS_MODE_ALWAYS
	var track: AudioStreamOggVorbis = load(TRACK_PATH)
	track.loop = true
	player = AudioStreamPlayer.new()
	player.stream = track
	player.volume_db = VOLUME_DB
	add_child(player)
	player.play()
