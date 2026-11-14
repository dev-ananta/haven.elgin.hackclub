extends VScrollBar
@export var target: ScrollContainer

# Variables
var _inner: VScrollBar

# Functions
func _ready() -> void: # Initiation Logic
	_inner = target.get_v_scroll_bar()
	_inner.changed.connect(_sync)
	_inner.value_changed.connect(_on_inner_value_changed)
	value_changed.connect(_on_value_changed)
	_sync.call_deferred()

func _sync() -> void: # Synchronization Logic
	min_value = _inner.min_value
	max_value = _inner.max_value
	page = _inner.page
	set_value_no_signal(_inner.value)

# Functions - Value Changing
func _on_inner_value_changed(new_value: float) -> void:
	set_value_no_signal(new_value)

func _on_value_changed(new_value: float) -> void:
	target.scroll_vertical = int(round(new_value))
