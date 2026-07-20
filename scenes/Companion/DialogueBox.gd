extends CanvasLayer
class_name DialogueBox
## DialogueBox.gd
##
## Minimal text-box dialogue system, OneShot-style: one line at a time,
## plain text, advance with the same "interact" key used to talk to people.
## No voice acting, no branching - just a warm line or two at a time.

signal finished

@onready var label: RichTextLabel = $Panel/MarginContainer/VBox/Label
@onready var speaker_label: Label = $Panel/MarginContainer/VBox/SpeakerLabel

var _lines: Array = []
var _index: int = 0

func _ready() -> void:
	hide()

func say(lines: Array, speaker: String = "Ono") -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	speaker_label.text = speaker
	show()
	_show_current()

func _show_current() -> void:
	label.text = _lines[_index]

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed):
		_advance()
		get_viewport().set_input_as_handled()

func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		hide()
		finished.emit()
	else:
		_show_current()
