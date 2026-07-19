extends Node2D
## Hub.gd
##
## The hub world stands in for a main menu: a chain of small connected
## rooms (one per revision mode, plus an entry room) joined by narrow
## corridors, rather than one open flat area. There's no physics body -
## movement is a plain position update, constrained each frame to stay
## inside whichever room or corridor "cell" currently contains the player.
## That constraint is what makes corridors act like doorways: you have to
## line up with the gap to pass through, same as a real room-to-room
## layout, without needing Godot's physics engine at all.

const SPEED := 220.0
const ROOM_HEIGHT := 400.0
const CORRIDOR_WIDTH := 140.0
const CORRIDOR_HEIGHT := 80.0
const CORRIDOR_Y := (ROOM_HEIGHT - CORRIDOR_HEIGHT) / 2.0

## One entry per room, left to right. Corridors are generated automatically
## in the gaps between rooms below - this is the one place room order,
## names and colours live. Doors/Player/CompanionNPC/JournalObject in
## Hub.tscn are hand-placed at the matching room centres: room 0 centres on
## x=180, then each following room centre is previous centre + 500, except
## the last (boss) room centre which is +520 - see _build_level() below.
const ROOMS := [
	{"width": 360.0, "label": "", "color": Color(0.2, 0.24, 0.22, 1)},
	{"width": 360.0, "label": "Spot It", "color": Color(0.22, 0.28, 0.29, 1)},
	{"width": 360.0, "label": "Explain It", "color": Color(0.2, 0.26, 0.3, 1)},
	{"width": 360.0, "label": "Compare It", "color": Color(0.22, 0.27, 0.24, 1)},
	{"width": 360.0, "label": "Mātāpono Māori", "color": Color(0.28, 0.24, 0.18, 1)},
	{"width": 400.0, "label": "Confusable Pairs", "color": Color(0.3, 0.19, 0.17, 1)},
]

@onready var player: Node2D = $Player
@onready var doors: Node2D = $Doors
@onready var companion: Area2D = $CompanionNPC
@onready var floors: Node2D = $Floors
@onready var interact_hint: Label = $UI/InteractHint
@onready var light_meter: ProgressBar = $UI/LightMeterBox/VBox/LightMeter
@onready var dialogue_box: CanvasLayer = $DialogueBox

var _nearby: Area2D = null
var _cells: Array = [] # Rect2 per room and per corridor; movement is clamped to whichever one contains the player

func _ready() -> void:
	_build_level()
	_refresh_doors()
	_update_light_meter()
	dialogue_box.hide()
	dialogue_box.finished.connect(_on_dialogue_finished)

func _process(delta: float) -> void:
	if dialogue_box.visible:
		return # don't walk around mid-conversation
	_handle_movement(delta)
	_handle_interact()

## Builds the floor visuals and the list of walkable cells (rooms and the
## narrow corridors between them) that movement is constrained to.
func _build_level() -> void:
	var x := 0.0
	for i in ROOMS.size():
		var room: Dictionary = ROOMS[i]
		var room_rect := Rect2(x, 0.0, room["width"], ROOM_HEIGHT)
		_cells.append(room_rect)
		_add_floor(room_rect, room["color"], room["label"])
		x += room["width"]
		if i < ROOMS.size() - 1:
			var corridor_rect := Rect2(x, CORRIDOR_Y, CORRIDOR_WIDTH, CORRIDOR_HEIGHT)
			_cells.append(corridor_rect)
			_add_floor(corridor_rect, Color(0.15, 0.15, 0.14, 1), "")
			x += CORRIDOR_WIDTH

func _add_floor(rect: Rect2, color: Color, label_text: String) -> void:
	var cr := ColorRect.new()
	cr.position = rect.position
	cr.size = rect.size
	cr.color = color
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floors.add_child(cr)
	if label_text != "":
		var l := Label.new()
		l.text = label_text
		l.position = rect.position + Vector2(0.0, 14.0)
		l.size = Vector2(rect.size.x, 24.0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color(0.93, 0.9, 0.8, 0.65))
		l.add_theme_font_size_override("font_size", 13)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floors.add_child(l)

func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length() > 0.0:
		dir = dir.normalized()
	var step := dir * SPEED * delta
	var pos := player.position
	# Move on each axis independently, only if the resulting point still
	# lands inside a room or corridor - this is what makes an unaligned
	# corridor doorway block the player, the same way a wall would.
	var try_x := Vector2(pos.x + step.x, pos.y)
	if _in_any_cell(try_x):
		pos.x = try_x.x
	var try_y := Vector2(pos.x, pos.y + step.y)
	if _in_any_cell(try_y):
		pos.y = try_y.y
	player.position = pos

func _in_any_cell(point: Vector2) -> bool:
	for cell in _cells:
		if cell.has_point(point):
			return true
	return false

func _handle_interact() -> void:
	interact_hint.visible = _nearby != null
	if _nearby and Input.is_action_just_pressed("interact"):
		_trigger(_nearby)

func _on_player_area_entered(area: Area2D) -> void:
	_nearby = area

func _on_player_area_exited(area: Area2D) -> void:
	if _nearby == area:
		_nearby = null

func _trigger(area: Area2D) -> void:
	var kind: String = area.get_meta("kind", "")
	match kind:
		"door":
			var mode_id: String = area.get_meta("mode_id")
			if ProgressTracker.is_mode_unlocked(mode_id):
				get_tree().change_scene_to_file(area.get_meta("scene_path"))
			else:
				dialogue_box.say(companion.get_locked_door_lines())
		"companion":
			dialogue_box.say(companion.get_greeting_lines())
		"journal":
			get_tree().change_scene_to_file("res://scenes/Journal/Journal.tscn")

func _on_dialogue_finished() -> void:
	pass # nothing extra needed once the companion stops talking

func _refresh_doors() -> void:
	for door in doors.get_children():
		var mode_id: String = door.get_meta("mode_id", "")
		var unlocked := ProgressTracker.is_mode_unlocked(mode_id)
		door.get_node("Locked").visible = not unlocked

func _update_light_meter() -> void:
	light_meter.value = ProgressTracker.overall_light_level()
