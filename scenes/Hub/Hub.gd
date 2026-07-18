extends Node2D
## Hub.gd
##
## The hub world stands in for a main menu. The student walks their
## character between a handful of "doors" (one per revision mode), a
## companion NPC, and a journal object, and presses "interact" (E) to use
## whichever one they're standing near. Nothing here scores anything - it
## just gets the student to the right mini-game scene calmly, instead of a
## list of menu buttons.

const SPEED := 220.0
const BOUNDS := Rect2(40, 40, 1200, 640)

@onready var player: Node2D = $Player
@onready var doors: Node2D = $Doors
@onready var companion: Area2D = $CompanionNPC
@onready var interact_hint: Label = $UI/InteractHint
@onready var light_meter: ProgressBar = $UI/LightMeterBox/VBox/LightMeter
@onready var dialogue_box: CanvasLayer = $DialogueBox

var _nearby: Area2D = null

func _ready() -> void:
	_refresh_doors()
	_update_light_meter()
	dialogue_box.hide()
	dialogue_box.finished.connect(_on_dialogue_finished)

func _process(delta: float) -> void:
	if dialogue_box.visible:
		return # don't walk around mid-conversation
	_handle_movement(delta)
	_handle_interact()

func _handle_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if dir.length() > 0.0:
		dir = dir.normalized()
	player.position += dir * SPEED * delta
	player.position.x = clamp(player.position.x, BOUNDS.position.x, BOUNDS.end.x)
	player.position.y = clamp(player.position.y, BOUNDS.position.y, BOUNDS.end.y)

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
		door.get_node("Label").modulate.a = 1.0 if unlocked else 0.5

func _update_light_meter() -> void:
	light_meter.value = ProgressTracker.overall_light_level()
